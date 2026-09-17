'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');

const router = Router();

const courseSelect = {
  id: true,
  title: true,
  slug: true,
  shortDescription: true,
  thumbnailUrl: true,
  instructorName: true,
  price: true,
  salePrice: true,
  level: true,
  ratingAverage: true,
  ratingCount: true,
  enrollmentCount: true,
  category: { select: { id: true, name: true, slug: true } },
};

const cartInclude = {
  items: {
    orderBy: { createdAt: 'desc' },
    include: { course: { select: courseSelect } },
  },
};

async function findCart(userId) {
  return prisma.cart.upsert({
    where: { userId },
    update: {},
    create: { userId },
    include: cartInclude,
  });
}

router.use(requireAuth, requireCustomer);

router.get('/', async (req, res, next) => {
  try {
    const cart = await findCart(req.user.id);
    return res.json({ success: true, data: { cart } });
  } catch (error) {
    return next(error);
  }
});

router.post('/items', async (req, res, next) => {
  try {
    const courseId = typeof req.body?.courseId === 'string' ? req.body.courseId.trim() : '';
    if (!courseId) {
      return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'courseId is required.' });
    }

    const course = await prisma.course.findFirst({
      where: { id: courseId, status: 'PUBLISHED' },
      select: { id: true },
    });
    if (!course) {
      return res.status(404).json({ success: false, code: 'COURSE_NOT_AVAILABLE', message: 'The course is not available.' });
    }

    const owned = await prisma.courseEntitlement.findFirst({
      where: { userId: req.user.id, courseId, status: 'ACTIVE' },
      select: { id: true },
    });
    if (owned) {
      return res.status(409).json({ success: false, code: 'COURSE_ALREADY_OWNED', message: 'You already have access to this course.' });
    }

    const cart = await findCart(req.user.id);
    const duplicate = await prisma.cartItem.findUnique({
      where: { cartId_courseId: { cartId: cart.id, courseId } },
      select: { id: true },
    });
    if (duplicate) {
      return res.status(409).json({ success: false, code: 'CART_ITEM_EXISTS', message: 'This course is already in your cart.' });
    }

    const item = await prisma.cartItem.create({
      data: { cartId: cart.id, courseId },
      include: { course: { select: courseSelect } },
    });
    return res.status(201).json({ success: true, data: { item } });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(409).json({ success: false, code: 'CART_ITEM_EXISTS', message: 'This course is already in your cart.' });
    }
    return next(error);
  }
});

router.delete('/items/:id', async (req, res, next) => {
  try {
    const deleted = await prisma.cartItem.deleteMany({
      where: { id: req.params.id, cart: { userId: req.user.id } },
    });
    if (!deleted.count) {
      return res.status(404).json({ success: false, code: 'CART_ITEM_NOT_FOUND', message: 'Cart item was not found.' });
    }
    return res.status(204).send();
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
