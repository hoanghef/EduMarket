'use strict';

process.env.VNPAY_TMN_CODE = 'TESTCODE';
process.env.VNPAY_HASH_SECRET = 'TEST_VNPAY_HASH_SECRET_2026';
process.env.VNPAY_URL = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
process.env.VNPAY_RETURN_URL = 'http://localhost:4000/api/payments/vnpay/return';

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');

let server; let baseUrl; let courseId;
const users = []; const orderIds = [];

function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function register(prefix) {
  const csrfData = await csrf();
  const result = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: `${prefix}-${Date.now()}@example.test`, fullName: 'VNPay Test Customer', password: 'CorrectPassword1!' }) });
  assert.equal(result.response.status, 201);
  users.push(result.body.data.user.id);
  return { id: result.body.data.user.id, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
function headers(session) { return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie }; }
function fixtureSignature(params) {
  const encode = (value) => encodeURIComponent(String(value)).replace(/%20/g, '+');
  const payload = Object.keys(params).sort().map((key) => `${encode(key)}=${encode(params[key])}`).join('&');
  return crypto.createHmac('sha512', process.env.VNPAY_HASH_SECRET).update(payload, 'utf8').digest('hex');
}
function signedCallback(order, amount, responseCode = '00') {
  const params = {
    vnp_Amount: amount,
    vnp_BankCode: 'NCB',
    vnp_BankTranNo: 'BANK-TEST-001',
    vnp_PayDate: '20260918090000',
    vnp_ResponseCode: responseCode,
    vnp_TmnCode: process.env.VNPAY_TMN_CODE,
    vnp_TransactionNo: `VNP-${Date.now()}-${responseCode}`,
    vnp_TransactionStatus: responseCode === '00' ? '00' : '02',
    vnp_TxnRef: order.orderNumber,
  };
  return { ...params, vnp_SecureHash: fixtureSignature(params) };
}
function query(params) { return new URLSearchParams(params).toString(); }

test.before(async () => {
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } });
  const suffix = Date.now().toString();
  courseId = (await prisma.course.create({ data: { categoryId: category.id, title: `VNPay test course ${suffix}`, slug: `vnpay-test-${suffix}`, description: 'VNPay callback test course.', instructorName: 'Test Instructor', price: 100000, status: 'PUBLISHED', publishedAt: new Date() } })).id;
});

test.after(async () => {
  for (const orderId of orderIds) {
    await prisma.courseEntitlement.deleteMany({ where: { orderId } });
    await prisma.auditLog.deleteMany({ where: { entityId: orderId } });
    await prisma.order.delete({ where: { id: orderId } });
  }
  if (courseId) await prisma.course.delete({ where: { id: courseId } });
  for (const userId of users) { await prisma.auditLog.deleteMany({ where: { userId } }); await prisma.user.delete({ where: { id: userId } }); }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

test('VNPay signed success callback is amount-checked, idempotent, and grants access once', async () => {
  const customer = await register('vnpay-success');
  const add = await request('/api/cart/items', { method: 'POST', headers: headers(customer), body: JSON.stringify({ courseId }) });
  assert.equal(add.response.status, 201);
  const created = await request('/api/payments/vnpay/create', { method: 'POST', headers: headers(customer) });
  assert.equal(created.response.status, 201);
  const order = created.body.data.order; orderIds.push(order.id);
  assert.equal(order.status, 'PENDING_PAYMENT'); assert.equal(order.payment.method, 'VNPAY'); assert.equal(order.payment.status, 'PENDING');
  const paymentUrl = new URL(created.body.data.paymentUrl);
  assert.equal(paymentUrl.searchParams.get('vnp_TxnRef'), order.orderNumber);
  assert.equal(paymentUrl.searchParams.get('vnp_Amount'), '10000000');
  assert.equal(paymentUrl.searchParams.get('vnp_SecureHash')?.length, 128);

  const successFixture = signedCallback(order, '10000000');
  const returned = await request(`/api/payments/vnpay/return?${query(successFixture)}`);
  assert.equal(returned.response.status, 200); assert.equal(returned.body.data.order.status, 'PAID'); assert.equal(returned.body.data.order.payment.status, 'SUCCESS');
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customer.id, courseId, status: 'ACTIVE' } }), 1);
  assert.equal(await prisma.auditLog.count({ where: { userId: customer.id, action: 'PAYMENT_SUCCESS', entityId: order.id } }), 1);

  const replay = await request(`/api/payments/vnpay/ipn?${query(successFixture)}`);
  assert.equal(replay.response.status, 200); assert.equal(replay.body.RspCode, '02');
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customer.id, courseId, status: 'ACTIVE' } }), 1);
});

test('VNPay rejects bad signatures and amounts, then records a signed cancellation', async () => {
  const customer = await register('vnpay-failure');
  await request('/api/cart/items', { method: 'POST', headers: headers(customer), body: JSON.stringify({ courseId }) });
  const created = await request('/api/payments/vnpay/create', { method: 'POST', headers: headers(customer) });
  assert.equal(created.response.status, 201);
  const order = created.body.data.order; orderIds.push(order.id);

  const tampered = signedCallback(order, '10000000'); tampered.vnp_Amount = '1';
  const invalidSignature = await request(`/api/payments/vnpay/ipn?${query(tampered)}`);
  assert.equal(invalidSignature.body.RspCode, '97');

  const wrongAmount = signedCallback(order, '1');
  const amountMismatch = await request(`/api/payments/vnpay/ipn?${query(wrongAmount)}`);
  assert.equal(amountMismatch.body.RspCode, '04');
  assert.equal((await prisma.order.findUnique({ where: { id: order.id } })).status, 'PENDING_PAYMENT');

  const cancelled = signedCallback(order, '10000000', '24');
  const cancellation = await request(`/api/payments/vnpay/ipn?${query(cancelled)}`);
  assert.equal(cancellation.body.RspCode, '00');
  const stored = await prisma.order.findUnique({ where: { id: order.id }, include: { payment: true } });
  assert.equal(stored.status, 'CANCELLED'); assert.equal(stored.payment.status, 'FAILED');
  assert.equal(await prisma.auditLog.count({ where: { userId: customer.id, action: 'PAYMENT_FAILED', entityId: order.id } }), 1);
});
