'use strict';

const { Router } = require('express');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { createCodCheckout } = require('../services/order-service');

const router = Router();

router.post('/', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    if (req.body?.method !== 'COD') {
      return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Only COD is available for this checkout.' });
    }
    const order = await createCodCheckout(req.user.id, req);
    return res.status(201).json({ success: true, data: { order } });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
