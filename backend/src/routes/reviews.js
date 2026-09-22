'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { submitReview, validComment } = require('../services/review-service');

const router = Router();

router.post('/reviews', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    const comment = validComment(req.body?.comment);
    const review = await submitReview({ userId: req.user.id, courseId: req.body?.courseId, rating: req.body?.rating, comment, req });
    return res.status(201).json({ success: true, data: { review } });
  } catch (error) {
    if (error.code === 'P2002') return res.status(409).json({ success: false, code: 'REVIEW_ALREADY_EXISTS', message: 'You have already reviewed this course.' });
    return next(error);
  }
});

router.get('/courses/:courseId/reviews', async (req, res, next) => {
  try {
    const course = await prisma.course.findFirst({ where: { id: req.params.courseId, status: 'PUBLISHED' }, select: { id: true } });
    if (!course) return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' });
    const items = await prisma.review.findMany({ where: { courseId: course.id, status: 'APPROVED' }, orderBy: { createdAt: 'desc' }, select: { id: true, rating: true, comment: true, createdAt: true, user: { select: { fullName: true } } } });
    return res.json({ success: true, data: { items: items.map((item) => ({ id: item.id, rating: item.rating, comment: item.comment, createdAt: item.createdAt, reviewerName: item.user.fullName })) } });
  } catch (error) { return next(error); }
});

router.get('/courses/:courseId/my-review', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    const review = await prisma.review.findUnique({
      where: { userId_courseId: { userId: req.user.id, courseId: req.params.courseId } },
      select: { id: true, rating: true, comment: true, status: true, moderatedAt: true, createdAt: true },
    });
    return res.json({ success: true, data: { review } });
  } catch (error) { return next(error); }
});

module.exports = router;
