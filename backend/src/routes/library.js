'use strict';

const { Router } = require('express');
const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { BusinessError, clientIp } = require('../services/order-service');
const { requireActiveEntitlement } = require('../services/entitlement-service');

const router = Router();
router.use(requireAuth, requireCustomer);

const courseSummary = { id: true, title: true, slug: true, shortDescription: true, thumbnailUrl: true, instructorName: true, level: true, category: { select: { id: true, name: true, slug: true } } };
const safeFile = { id: true, lessonId: true, originalName: true, mimeType: true, sizeBytes: true, createdAt: true };

router.get('/', async (req, res, next) => {
  try {
    const entitlements = await prisma.courseEntitlement.findMany({
      where: { userId: req.user.id, status: 'ACTIVE' }, orderBy: { grantedAt: 'desc' },
      include: { course: { select: courseSummary } },
    });
    return res.json({ success: true, data: { items: entitlements } });
  } catch (error) { return next(error); }
});

router.get('/courses/:courseId', async (req, res, next) => {
  try {
    await requireActiveEntitlement(req.user.id, req.params.courseId);
    const course = await prisma.course.findUnique({ where: { id: req.params.courseId }, select: { ...courseSummary, description: true, lessons: { orderBy: { position: 'asc' }, select: { id: true, title: true, content: true, videoUrl: true, durationSec: true, position: true, isPreview: true, isRequired: true } }, files: { orderBy: { createdAt: 'asc' }, select: safeFile } } });
    if (!course) return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' });
    return res.json({ success: true, data: { course } });
  } catch (error) { return next(error); }
});

router.get('/lessons/:lessonId', async (req, res, next) => {
  try {
    const lesson = await prisma.lesson.findUnique({ where: { id: req.params.lessonId }, select: { id: true, courseId: true, title: true, content: true, videoUrl: true, durationSec: true, position: true, isRequired: true } });
    if (!lesson) return res.status(404).json({ success: false, code: 'LESSON_NOT_FOUND', message: 'Lesson not found.' });
    await requireActiveEntitlement(req.user.id, lesson.courseId);
    return res.json({ success: true, data: { lesson } });
  } catch (error) { return next(error); }
});

router.post('/lessons/:lessonId/complete', async (req, res, next) => {
  try {
    const result = await prisma.$transaction(async (tx) => {
      const lesson = await tx.lesson.findUnique({ where: { id: req.params.lessonId }, select: { id: true, courseId: true } });
      if (!lesson) throw new BusinessError(404, 'LESSON_NOT_FOUND', 'Lesson not found.');
      await requireActiveEntitlement(req.user.id, lesson.courseId, tx);
      const existing = await tx.courseProgress.findUnique({ where: { userId_lessonId: { userId: req.user.id, lessonId: lesson.id } } });
      if (existing) return { progress: existing, created: false };
      const progress = await tx.courseProgress.create({ data: { userId: req.user.id, courseId: lesson.courseId, lessonId: lesson.id } });
      await tx.auditLog.create({ data: { userId: req.user.id, action: 'LESSON_COMPLETED', entityType: 'CourseProgress', entityId: progress.id, ipAddress: clientIp(req), metadata: { courseId: lesson.courseId, lessonId: lesson.id } } });
      return { progress, created: true };
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
    return res.status(result.created ? 201 : 200).json({ success: true, data: result });
  } catch (error) {
    if (error.code === 'P2002') return res.status(200).json({ success: true, data: { created: false } });
    return next(error);
  }
});

router.get('/files/:fileId', async (req, res, next) => {
  try {
    const file = await prisma.courseFile.findUnique({ where: { id: req.params.fileId }, select: { ...safeFile, courseId: true } });
    if (!file) return res.status(404).json({ success: false, code: 'FILE_NOT_FOUND', message: 'File not found.' });
    await requireActiveEntitlement(req.user.id, file.courseId);
    const { courseId, ...safeMetadata } = file;
    return res.json({ success: true, data: { file: safeMetadata } });
  } catch (error) { return next(error); }
});

module.exports = router;
