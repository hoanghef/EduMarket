'use strict';

const { Prisma } = require('../generated/prisma');

function normalizeCouponCode(value) {
  const code = typeof value === 'string' ? value.trim().toUpperCase() : '';
  return /^[A-Z0-9][A-Z0-9_-]{1,63}$/.test(code) ? code : null;
}

function couponError(code, message) {
  const error = new Error(message);
  error.status = 409;
  error.code = code;
  throw error;
}

function calculateDiscount(coupon, subtotal) {
  let discount = coupon.discountType === 'PERCENTAGE'
    ? subtotal.mul(coupon.discountValue).div(100)
    : new Prisma.Decimal(coupon.discountValue);
  if (coupon.maximumDiscountAmount && discount.greaterThan(coupon.maximumDiscountAmount)) discount = new Prisma.Decimal(coupon.maximumDiscountAmount);
  return discount.greaterThan(subtotal) ? subtotal : discount;
}

async function validateCouponForSubtotal({ userId, code, subtotal, client }) {
  const couponCode = normalizeCouponCode(code);
  if (!couponCode) couponError('COUPON_INVALID', 'Coupon code is invalid.');
  const coupon = await client.coupon.findUnique({ where: { code: couponCode } });
  if (!coupon) couponError('COUPON_INVALID', 'Coupon code is invalid.');
  if (coupon.discountValue.lessThanOrEqualTo(0) || (coupon.discountType === 'PERCENTAGE' && coupon.discountValue.greaterThan(100)) || coupon.perUserLimit < 1 || coupon.startsAt >= coupon.endsAt) couponError('COUPON_INVALID', 'Coupon configuration is invalid.');
  const now = new Date();
  if (!coupon.isActive) couponError('COUPON_INACTIVE', 'Coupon is inactive.');
  if (coupon.startsAt > now) couponError('COUPON_NOT_STARTED', 'Coupon is not active yet.');
  if (coupon.endsAt <= now) couponError('COUPON_EXPIRED', 'Coupon has expired.');
  if (coupon.minimumOrderAmount && subtotal.lessThan(coupon.minimumOrderAmount)) couponError('COUPON_MINIMUM_NOT_MET', 'Order does not meet the coupon minimum.');
  if (coupon.usageLimit !== null && coupon.usageCount >= coupon.usageLimit) couponError('COUPON_USAGE_LIMIT_REACHED', 'Coupon usage limit has been reached.');
  const userUsageCount = await client.couponUsage.count({ where: { couponId: coupon.id, userId } });
  if (userUsageCount >= coupon.perUserLimit) couponError('COUPON_USER_LIMIT_REACHED', 'You have reached the coupon usage limit.');
  return { coupon, couponCode, discountAmount: calculateDiscount(coupon, subtotal) };
}

async function lockAndValidateCouponForCheckout({ userId, code, subtotal, tx }) {
  const couponCode = normalizeCouponCode(code);
  if (!couponCode) couponError('COUPON_INVALID', 'Coupon code is invalid.');
  const locked = await tx.$queryRaw`SELECT "id" FROM "Coupon" WHERE "code" = ${couponCode} FOR UPDATE`;
  if (!locked.length) couponError('COUPON_INVALID', 'Coupon code is invalid.');
  return validateCouponForSubtotal({ userId, code: couponCode, subtotal, client: tx });
}

module.exports = { lockAndValidateCouponForCheckout, normalizeCouponCode, validateCouponForSubtotal };
