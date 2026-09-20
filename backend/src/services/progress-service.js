'use strict';

const crypto = require('crypto');
const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');
const { BusinessError, clientIp } = require('./order-service');
const { requireActiveEntitlement } = require('./entitlement-service');
const { generateCertificatePdf } = require('./certificate-pdf-service');
const { removeStoredFile } = require('./file-storage-service');

function createCertificateCode() {
  return `EDU-${new Date().getUTCFullYear()}-${crypto.randomBytes(12).toString('hex').toUpperCase()}`;
}

async function calculateCourseProgress(userId, courseId, client = prisma) {
  const requiredLessons = await client.lesson.findMany({ where: { courseId, isRequired: true }, select: { id: true } });
  const totalRequiredLessons = requiredLessons.length;
  if (totalRequiredLessons === 0) return { totalRequiredLessons: 0, completedRequiredLessons: 0, percentage: 0, isComplete: false };
  const completedRequiredLessons = await client.courseProgress.count({ where: { userId, courseId, lessonId: { in: requiredLessons.map((lesson) => lesson.id) } } });
  const percentage = Math.floor((completedRequiredLessons / totalRequiredLessons) * 100);
  return { totalRequiredLessons, completedRequiredLessons, percentage, isComplete: completedRequiredLessons === totalRequiredLessons };
}

async function ensureCompletionCertificate({ userId, courseId, req, client }) {
  const existing = await client.certificate.findUnique({ where: { userId_courseId: { userId, courseId } } });
  if (existing) return { certificate: existing, created: false };

  const [user, course] = await Promise.all([
    client.user.findUnique({ where: { id: userId }, select: { id: true, fullName: true } }),
    client.course.findUnique({ where: { id: courseId }, select: { id: true, title: true } }),
  ]);
  if (!user || !course) throw new BusinessError(404, 'COURSE_NOT_FOUND', 'Course not found.');

  const certificateCode = createCertificateCode();
  const issuedAt = new Date();
  let pdfStorageKey;
  try {
    pdfStorageKey = await generateCertificatePdf({ certificateCode, studentName: user.fullName, courseName: course.title, issuedAt });
    const certificate = await client.certificate.create({ data: { certificateCode, userId, courseId, issuedAt, pdfStorageKey } });
    await client.auditLog.create({ data: { userId, action: 'CERTIFICATE_ISSUED', entityType: 'Certificate', entityId: certificate.id, ipAddress: clientIp(req), metadata: { courseId, certificateCode } } });
    return { certificate, created: true };
  } catch (error) {
    if (pdfStorageKey) removeStoredFile(pdfStorageKey);
    throw error;
  }
}

async function completeLessonAndCalculateProgress({ userId, lessonId, req }) {
  return prisma.$transaction(async (tx) => {
    const lesson = await tx.lesson.findUnique({ where: { id: lessonId }, select: { id: true, courseId: true } });
    if (!lesson) throw new BusinessError(404, 'LESSON_NOT_FOUND', 'Lesson not found.');
    await requireActiveEntitlement(userId, lesson.courseId, tx);
    const existing = await tx.courseProgress.findUnique({ where: { userId_lessonId: { userId, lessonId: lesson.id } } });
    const progressRecord = existing || await tx.courseProgress.create({ data: { userId, courseId: lesson.courseId, lessonId: lesson.id } });
    if (!existing) await tx.auditLog.create({ data: { userId, action: 'LESSON_COMPLETED', entityType: 'CourseProgress', entityId: progressRecord.id, ipAddress: clientIp(req), metadata: { courseId: lesson.courseId, lessonId: lesson.id } } });
    const progress = await calculateCourseProgress(userId, lesson.courseId, tx);
    const certificateResult = progress.isComplete
      ? await ensureCompletionCertificate({ userId, courseId: lesson.courseId, req, client: tx })
      : { certificate: null, created: false };
    return { completion: progressRecord, created: !existing, progress, certificate: certificateResult.certificate, certificateCreated: certificateResult.created };
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

module.exports = { calculateCourseProgress, completeLessonAndCalculateProgress, createCertificateCode };
