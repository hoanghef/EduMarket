'use strict';

const crypto = require('crypto');
const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');

class BusinessError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function effectivePrice(course) {
  return course.salePrice && course.salePrice.lessThan(course.price)
    ? course.salePrice
    : course.price;
}

function orderNumber() {
  return `COD-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
}

function clientIp(req) {
  return req.ip || req.socket?.remoteAddress || null;
}

const orderInclude = {
  items: { orderBy: { createdAt: 'asc' } },
  payment: { select: { id: true, method: true, status: true, amount: true, paidAt: true } },
};

async function createCodCheckout(userId, req) {
  return prisma.$transaction(async (tx) => {
    const cart = await tx.cart.findUnique({
      where: { userId },
      include: {
        items: {
          include: {
            course: {
              select: { id: true, title: true, slug: true, price: true, salePrice: true, status: true },
            },
          },
        },
      },
    });
    if (!cart?.items.length) {
      throw new BusinessError(409, 'CART_EMPTY', 'Your cart is empty.');
    }

    const courseIds = cart.items.map((item) => item.courseId);
    if (cart.items.some((item) => item.course.status !== 'PUBLISHED')) {
      throw new BusinessError(409, 'COURSE_NOT_AVAILABLE', 'One or more courses are no longer available.');
    }
    const ownedCount = await tx.courseEntitlement.count({
      where: { userId, courseId: { in: courseIds }, status: 'ACTIVE' },
    });
    if (ownedCount) {
      throw new BusinessError(409, 'COURSE_ALREADY_OWNED', 'One or more courses are already owned.');
    }

    const subtotal = cart.items.reduce(
      (total, item) => total.plus(effectivePrice(item.course)),
      new Prisma.Decimal(0),
    );
    const order = await tx.order.create({
      data: {
        orderNumber: orderNumber(),
        userId,
        status: 'WAITING_CONFIRMATION',
        subtotal,
        discountAmount: new Prisma.Decimal(0),
        totalAmount: subtotal,
        items: {
          create: cart.items.map((item) => ({
            courseId: item.course.id,
            courseTitleSnapshot: item.course.title,
            courseSlugSnapshot: item.course.slug,
            unitPrice: item.course.price,
            discountedUnitPrice: effectivePrice(item.course),
          })),
        },
        payment: { create: { method: 'COD', status: 'PENDING', amount: subtotal } },
      },
      include: orderInclude,
    });

    await tx.cartItem.deleteMany({ where: { cartId: cart.id } });
    await tx.auditLog.create({
      data: {
        userId,
        action: 'ORDER_CREATED',
        entityType: 'Order',
        entityId: order.id,
        ipAddress: clientIp(req),
        metadata: { method: 'COD', totalAmount: subtotal.toFixed(2), itemCount: cart.items.length },
      },
    });
    return order;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

async function confirmCodOrder(orderId, adminId, req) {
  return prisma.$transaction(async (tx) => {
    const order = await tx.order.findUnique({
      where: { id: orderId },
      include: { items: true, payment: true },
    });
    if (!order) throw new BusinessError(404, 'ORDER_NOT_FOUND', 'Order not found.');
    if (order.status !== 'WAITING_CONFIRMATION' || !order.payment || order.payment.method !== 'COD' || order.payment.status !== 'PENDING') {
      throw new BusinessError(409, 'ORDER_NOT_AWAITING_CONFIRMATION', 'This COD order cannot be confirmed.');
    }

    const now = new Date();
    const claimed = await tx.order.updateMany({
      where: { id: order.id, status: 'WAITING_CONFIRMATION' },
      data: { status: 'PAID', paidAt: now },
    });
    if (claimed.count !== 1) {
      throw new BusinessError(409, 'ORDER_NOT_AWAITING_CONFIRMATION', 'This COD order cannot be confirmed.');
    }
    await tx.payment.update({ where: { id: order.payment.id }, data: { status: 'SUCCESS', paidAt: now } });

    for (const item of order.items) {
      const current = await tx.courseEntitlement.findUnique({
        where: { userId_courseId: { userId: order.userId, courseId: item.courseId } },
      });
      if (!current) {
        const entitlement = await tx.courseEntitlement.create({
          data: { userId: order.userId, courseId: item.courseId, orderId: order.id, status: 'ACTIVE', grantedAt: now },
        });
        await tx.course.update({ where: { id: item.courseId }, data: { enrollmentCount: { increment: 1 } } });
        await tx.auditLog.create({
          data: { userId: order.userId, action: 'COURSE_ACCESS_GRANTED', entityType: 'CourseEntitlement', entityId: entitlement.id, ipAddress: clientIp(req), metadata: { courseId: item.courseId, orderId: order.id } },
        });
      } else if (current.status !== 'ACTIVE') {
        await tx.courseEntitlement.update({
          where: { id: current.id },
          data: { status: 'ACTIVE', orderId: order.id, grantedAt: now, revokedAt: null, revokeReason: null },
        });
        await tx.auditLog.create({
          data: { userId: order.userId, action: 'COURSE_ACCESS_GRANTED', entityType: 'CourseEntitlement', entityId: current.id, ipAddress: clientIp(req), metadata: { courseId: item.courseId, orderId: order.id, restored: true } },
        });
      }
    }
    await tx.auditLog.create({
      data: { userId: adminId, action: 'COD_CONFIRMED', entityType: 'Order', entityId: order.id, ipAddress: clientIp(req), metadata: { paymentId: order.payment.id } },
    });
    return tx.order.findUnique({ where: { id: order.id }, include: orderInclude });
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

module.exports = { BusinessError, confirmCodOrder, createCodCheckout, orderInclude };
