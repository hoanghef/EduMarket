'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');

const router = Router();
const courseSelect = { id: true, title: true, slug: true, shortDescription: true, thumbnailUrl: true, instructorName: true, price: true, salePrice: true, level: true, ratingAverage: true, ratingCount: true };
router.use(requireAuth, requireCustomer);

router.get('/', async (req, res, next) => {
  try {
    const items = await prisma.wishlist.findMany({ where: { userId: req.user.id }, orderBy: { createdAt: 'desc' }, include: { course: { select: courseSelect } } });
    return res.json({ success: true, data: { items } });
  } catch (error) { return next(error); }
});

router.post('/:courseId', async (req, res, next) => {
  try {
    const course = await prisma.course.findFirst({ where: { id: req.params.courseId, status: 'PUBLISHED' }, select: { id: true } });
    if (!course) return res.status(404).json({ success: false, code: 'COURSE_NOT_AVAILABLE', message: 'Course is not available.' });
    const item = await prisma.wishlist.create({ data: { userId: req.user.id, courseId: course.id }, include: { course: { select: courseSelect } } });
    return res.status(201).json({ success: true, data: { item } });
  } catch (error) {
    if (error.code === 'P2002') return res.status(409).json({ success: false, code: 'WISHLIST_ITEM_EXISTS', message: 'Course is already in your wishlist.' });
    return next(error);
  }
});

router.delete('/:courseId', async (req, res, next) => {
  try {
    const deleted = await prisma.wishlist.deleteMany({ where: { userId: req.user.id, courseId: req.params.courseId } });
    if (!deleted.count) return res.status(404).json({ success: false, code: 'WISHLIST_ITEM_NOT_FOUND', message: 'Wishlist item was not found.' });
    return res.status(204).end();
  } catch (error) { return next(error); }
});

module.exports = router;
