'use strict';

const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');
const { BusinessError, clientIp } = require('./order-service');
const { requireActiveEntitlement } = require('./entitlement-service');

function validRating(value) { return Number.isInteger(value) && value >= 1 && value <= 5; }
function validComment(value) {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string') return undefined;
  const comment = value.trim();
  return comment.length <= 2000 ? (comment || null) : undefined;
}

async function submitReview({ userId, courseId, rating, comment, req }) {
  if (typeof courseId !== 'string' || !courseId.trim() || !validRating(rating) || comment === undefined) throw new BusinessError(400, 'VALIDATION_ERROR', 'Course, rating, or comment is invalid.');
  return prisma.$transaction(async (tx) => {
    const course = await tx.course.findUnique({ where: { id: courseId }, select: { id: true } });
    if (!course) throw new BusinessError(404, 'COURSE_NOT_FOUND', 'Course not found.');
    await requireActiveEntitlement(userId, courseId, tx);
    const review = await tx.review.create({ data: { userId, courseId, rating, comment, status: 'PENDING' } });
    await tx.auditLog.create({ data: { userId, action: 'REVIEW_SUBMITTED', entityType: 'Review', entityId: review.id, ipAddress: clientIp(req), metadata: { courseId, rating } } });
    return review;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

async function moderateReview({ reviewId, status, adminId, req }) {
  if (!['APPROVED', 'REJECTED'].includes(status)) throw new BusinessError(400, 'VALIDATION_ERROR', 'Review moderation status is invalid.');
  return prisma.$transaction(async (tx) => {
    const review = await tx.review.findUnique({ where: { id: reviewId } });
    if (!review) throw new BusinessError(404, 'REVIEW_NOT_FOUND', 'Review not found.');
    if (review.status !== 'PENDING') throw new BusinessError(409, 'REVIEW_NOT_PENDING', 'Only pending reviews can be moderated.');
    const moderated = await tx.review.update({ where: { id: review.id }, data: { status, moderatedAt: new Date(), moderatedById: adminId } });
    if (status === 'APPROVED') {
      const ratings = await tx.review.aggregate({ where: { courseId: review.courseId, status: 'APPROVED' }, _avg: { rating: true }, _count: { id: true } });
      await tx.course.update({ where: { id: review.courseId }, data: { ratingAverage: new Prisma.Decimal(ratings._avg.rating || 0), ratingCount: ratings._count.id } });
    }
    await tx.auditLog.create({ data: { userId: adminId, action: `REVIEW_${status}`, entityType: 'Review', entityId: review.id, ipAddress: clientIp(req), metadata: { courseId: review.courseId, reviewUserId: review.userId } } });
    return moderated;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

module.exports = { moderateReview, submitReview, validComment };
