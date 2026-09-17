'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { orderInclude } = require('../services/order-service');

const router = Router();
router.use(requireAuth, requireCustomer);

router.get('/', async (req, res, next) => {
  try {
    const orders = await prisma.order.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      include: orderInclude,
    });
    return res.json({ success: true, data: { orders } });
  } catch (error) { return next(error); }
});

router.get('/:id/status', async (req, res, next) => {
  try {
    const order = await prisma.order.findFirst({ where: { id: req.params.id, userId: req.user.id }, select: { id: true, orderNumber: true, status: true, createdAt: true, paidAt: true, payment: { select: { method: true, status: true, paidAt: true } } } });
    if (!order) return res.status(404).json({ success: false, code: 'ORDER_NOT_FOUND', message: 'Order not found.' });
    return res.json({ success: true, data: { order } });
  } catch (error) { return next(error); }
});

router.get('/:id', async (req, res, next) => {
  try {
    const order = await prisma.order.findFirst({ where: { id: req.params.id, userId: req.user.id }, include: orderInclude });
    if (!order) return res.status(404).json({ success: false, code: 'ORDER_NOT_FOUND', message: 'Order not found.' });
    return res.json({ success: true, data: { order } });
  } catch (error) { return next(error); }
});

module.exports = router;
