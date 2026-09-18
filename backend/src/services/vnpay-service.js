'use strict';

const crypto = require('crypto');
const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');
const { BusinessError, clientIp, completePaidOrder, orderInclude } = require('./order-service');

function config() {
  const tmnCode = process.env.VNPAY_TMN_CODE?.trim();
  const hashSecret = process.env.VNPAY_HASH_SECRET?.trim();
  const url = process.env.VNPAY_URL?.trim();
  const returnUrl = process.env.VNPAY_RETURN_URL?.trim();
  if (!tmnCode || !hashSecret || !url || !returnUrl || tmnCode === 'CHANGEME' || hashSecret === 'CHANGEME') {
    throw new BusinessError(503, 'VNPAY_NOT_CONFIGURED', 'VNPay Sandbox is not configured.');
  }
  return { tmnCode, hashSecret, url, returnUrl };
}

function encode(value) {
  return encodeURIComponent(String(value)).replace(/%20/g, '+');
}

function canonical(params) {
  return Object.keys(params).sort().map((key) => `${encode(key)}=${encode(params[key])}`).join('&');
}

function sign(params, hashSecret) {
  return crypto.createHmac('sha512', hashSecret).update(canonical(params), 'utf8').digest('hex');
}

function callbackParams(query) {
  const params = {};
  for (const [key, value] of Object.entries(query)) {
    if (!key.startsWith('vnp_') || key === 'vnp_SecureHash' || key === 'vnp_SecureHashType') continue;
    if (typeof value !== 'string' || !value) throw new BusinessError(400, 'VNPAY_INVALID_CALLBACK', 'VNPay callback parameters are invalid.');
    params[key] = value;
  }
  return params;
}

function verifyCallback(query, hashSecret) {
  const signature = typeof query.vnp_SecureHash === 'string' ? query.vnp_SecureHash : '';
  if (!signature || !/^[a-f0-9]{128}$/i.test(signature)) throw new BusinessError(400, 'VNPAY_INVALID_SIGNATURE', 'VNPay signature is invalid.');
  const expected = sign(callbackParams(query), hashSecret);
  const actualBuffer = Buffer.from(signature, 'hex');
  const expectedBuffer = Buffer.from(expected, 'hex');
  if (actualBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(actualBuffer, expectedBuffer)) {
    throw new BusinessError(400, 'VNPAY_INVALID_SIGNATURE', 'VNPay signature is invalid.');
  }
  return callbackParams(query);
}

function timestamp(date = new Date()) {
  const pad = (value) => String(value).padStart(2, '0');
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

function createPaymentUrl(order, requestIp) {
  const settings = config();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 15 * 60 * 1000);
  const amount = new Prisma.Decimal(order.totalAmount).mul(100).toFixed(0);
  const params = {
    vnp_Amount: amount,
    vnp_Command: 'pay',
    vnp_CreateDate: timestamp(now),
    vnp_CurrCode: 'VND',
    vnp_ExpireDate: timestamp(expiresAt),
    vnp_IpAddr: requestIp || '127.0.0.1',
    vnp_Locale: 'vn',
    vnp_OrderInfo: `Thanh toan don hang ${order.orderNumber}`,
    vnp_OrderType: 'other',
    vnp_ReturnUrl: settings.returnUrl,
    vnp_TmnCode: settings.tmnCode,
    vnp_TxnRef: order.orderNumber,
    vnp_Version: '2.1.0',
  };
  const url = new URL(settings.url);
  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);
  url.searchParams.set('vnp_SecureHash', sign(params, settings.hashSecret));
  return { paymentUrl: url.toString(), params };
}

function providerPayload(params) {
  return {
    responseCode: params.vnp_ResponseCode,
    transactionStatus: params.vnp_TransactionStatus || null,
    transactionNo: params.vnp_TransactionNo || null,
    bankCode: params.vnp_BankCode || null,
    bankTranNo: params.vnp_BankTranNo || null,
    payDate: params.vnp_PayDate || null,
    txnRef: params.vnp_TxnRef,
  };
}

async function markVnpayFailed(order, params, req) {
  return prisma.$transaction(async (tx) => {
    const current = await tx.order.findUnique({ where: { id: order.id }, include: { payment: true } });
    if (current.status !== 'PENDING_PAYMENT' || current.payment?.status !== 'PENDING') return { order: current, idempotent: true };
    const now = new Date();
    await tx.order.update({ where: { id: current.id }, data: { status: 'CANCELLED' } });
    await tx.payment.update({ where: { id: current.payment.id }, data: { status: 'FAILED', providerPayload: providerPayload(params), paidAt: null } });
    await tx.auditLog.create({ data: { userId: current.userId, action: 'PAYMENT_FAILED', entityType: 'Order', entityId: current.id, ipAddress: clientIp(req), metadata: { method: 'VNPAY', responseCode: params.vnp_ResponseCode, transactionStatus: params.vnp_TransactionStatus || null } } });
    return { order: await tx.order.findUnique({ where: { id: current.id }, include: orderInclude }), idempotent: false };
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

async function processCallback(query, req) {
  const settings = config();
  const params = verifyCallback(query, settings.hashSecret);
  if (!params.vnp_TxnRef || !params.vnp_Amount || !params.vnp_ResponseCode) {
    throw new BusinessError(400, 'VNPAY_INVALID_CALLBACK', 'VNPay callback is missing required payment fields.');
  }
  const order = await prisma.order.findUnique({ where: { orderNumber: params.vnp_TxnRef }, include: { payment: true } });
  if (!order || !order.payment || order.payment.method !== 'VNPAY') throw new BusinessError(404, 'VNPAY_ORDER_NOT_FOUND', 'VNPay order reference was not found.');

  const expectedAmount = new Prisma.Decimal(order.totalAmount).mul(100).toFixed(0);
  if (params.vnp_Amount !== expectedAmount) throw new BusinessError(400, 'VNPAY_AMOUNT_MISMATCH', 'VNPay amount does not match the order.');

  const successful = params.vnp_ResponseCode === '00' && (!params.vnp_TransactionStatus || params.vnp_TransactionStatus === '00');
  if (!successful) return markVnpayFailed(order, params, req);
  if (!params.vnp_TransactionNo) throw new BusinessError(400, 'VNPAY_INVALID_CALLBACK', 'VNPay success callback is missing its transaction reference.');

  const result = await completePaidOrder(order.id, 'VNPAY', { userId: order.userId, action: 'PAYMENT_SUCCESS', metadata: { transactionNo: params.vnp_TransactionNo || null, responseCode: params.vnp_ResponseCode } }, req, {
    transactionId: params.vnp_TransactionNo || null,
    providerPayload: providerPayload(params),
  });
  return result;
}

module.exports = { config, createPaymentUrl, processCallback, sign, verifyCallback };
