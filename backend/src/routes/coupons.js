'use strict';

const { Prisma } = require('../generated/prisma');
const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { validateCouponForSubtotal } = require('../services/coupon-service');

function effectivePrice(course) { return course.salePrice && course.salePrice.lessThan(course.price) ? course.salePrice : course.price; }
const router = Router();

router.post('/validate', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    const cart = await prisma.cart.findUnique({ where: { userId: req.user.id }, include: { items: { include: { course: { select: { price: true, salePrice: true, status: true } } } } } });
    if (!cart?.items.length) return res.status(409).json({ success: false, code: 'CART_EMPTY', message: 'Your cart is empty.' });
    if (cart.items.some((item) => item.course.status !== 'PUBLISHED')) return res.status(409).json({ success: false, code: 'COURSE_NOT_AVAILABLE', message: 'One or more courses are no longer available.' });
    const subtotal = cart.items.reduce((total, item) => total.plus(effectivePrice(item.course)), new Prisma.Decimal(0));
    const result = await validateCouponForSubtotal({ userId: req.user.id, code: req.body?.couponCode, subtotal, client: prisma });
    return res.json({ success: true, data: { coupon: { code: result.coupon.code, discountType: result.coupon.discountType }, subtotal, discountAmount: result.discountAmount, totalAmount: subtotal.minus(result.discountAmount) } });
  } catch (error) { return next(error); }
});

module.exports = router;
