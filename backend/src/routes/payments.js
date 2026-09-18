'use strict';

const { Router } = require('express');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { createCheckout } = require('../services/order-service');
const { config, createPaymentUrl, processCallback } = require('../services/vnpay-service');

const router = Router();

router.post('/vnpay/create', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    config();
    const order = await createCheckout(req.user.id, 'VNPAY', req);
    const payment = createPaymentUrl(order, req.ip || req.socket?.remoteAddress);
    return res.status(201).json({ success: true, data: { order, paymentUrl: payment.paymentUrl } });
  } catch (error) { return next(error); }
});

async function callback(req, res, next, isIpn) {
  try {
    const result = await processCallback(req.query, req);
    if (isIpn) {
      return res.json({ RspCode: result.idempotent ? '02' : '00', Message: result.idempotent ? 'Order already confirmed' : 'Confirm Success' });
    }
    return res.json({ success: true, data: { order: result.order, idempotent: result.idempotent } });
  } catch (error) {
    if (isIpn) {
      const rspCode = error.code === 'VNPAY_INVALID_SIGNATURE' ? '97' : error.code === 'VNPAY_ORDER_NOT_FOUND' ? '01' : error.code === 'VNPAY_AMOUNT_MISMATCH' ? '04' : '99';
      return res.status(200).json({ RspCode: rspCode, Message: error.message });
    }
    return next(error);
  }
}

router.get('/vnpay/return', (req, res, next) => callback(req, res, next, false));
router.get('/vnpay/ipn', (req, res, next) => callback(req, res, next, true));

module.exports = router;
