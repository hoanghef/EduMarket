'use strict';

const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');
const { BusinessError, clientIp } = require('./order-service');

async function requireActiveEntitlement(userId, courseId, client = prisma) {
  const entitlement = await client.courseEntitlement.findUnique({ where: { userId_courseId: { userId, courseId } } });
  if (!entitlement) throw new BusinessError(403, 'COURSE_ACCESS_DENIED', 'You do not have access to this course.');
  if (entitlement.status !== 'ACTIVE') throw new BusinessError(403, 'COURSE_ACCESS_REVOKED', 'Course access has been revoked.');
  return entitlement;
}

function requiredReason(reason) {
  return typeof reason === 'string' && reason.trim().length >= 2 && reason.trim().length <= 1000 ? reason.trim() : null;
}

async function grantEntitlement({ userId, courseId, orderId, adminId, req }) {
  return prisma.$transaction(async (tx) => {
    const [user, course, order] = await Promise.all([
      tx.user.findUnique({ where: { id: userId }, select: { id: true } }),
      tx.course.findUnique({ where: { id: courseId }, select: { id: true } }),
      tx.order.findUnique({ where: { id: orderId }, include: { items: { where: { courseId }, select: { id: true } } } }),
    ]);
    if (!user || !course || !order || order.userId !== userId || order.status !== 'PAID' || !order.items.length) {
      throw new BusinessError(400, 'INVALID_ENTITLEMENT_GRANT', 'A paid order for this user and course is required.');
    }
    const existing = await tx.courseEntitlement.findUnique({ where: { userId_courseId: { userId, courseId } } });
    if (existing?.status === 'ACTIVE') throw new BusinessError(409, 'ENTITLEMENT_ALREADY_ACTIVE', 'Course access is already active.');

    const now = new Date();
    const entitlement = existing
      ? await tx.courseEntitlement.update({ where: { id: existing.id }, data: { status: 'ACTIVE', orderId, grantedAt: now, revokedAt: null, revokeReason: null } })
      : await tx.courseEntitlement.create({ data: { userId, courseId, orderId, status: 'ACTIVE', grantedAt: now } });
    if (!existing) await tx.course.update({ where: { id: courseId }, data: { enrollmentCount: { increment: 1 } } });
    await tx.auditLog.create({ data: { userId, action: existing ? 'COURSE_ACCESS_RESTORED' : 'COURSE_ACCESS_GRANTED', entityType: 'CourseEntitlement', entityId: entitlement.id, ipAddress: clientIp(req), metadata: { courseId, orderId, grantedByAdminId: adminId } } });
    await tx.auditLog.create({ data: { userId: adminId, action: 'ADMIN_ENTITLEMENT_GRANTED', entityType: 'CourseEntitlement', entityId: entitlement.id, ipAddress: clientIp(req), metadata: { targetUserId: userId, courseId, orderId, restored: Boolean(existing) } } });
    return entitlement;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

async function revokeEntitlement({ entitlementId, reason, adminId, req }) {
  const revokeReason = requiredReason(reason);
  if (!revokeReason) throw new BusinessError(400, 'VALIDATION_ERROR', 'A revoke reason between 2 and 1000 characters is required.');
  return prisma.$transaction(async (tx) => {
    const entitlement = await tx.courseEntitlement.findUnique({ where: { id: entitlementId } });
    if (!entitlement) throw new BusinessError(404, 'ENTITLEMENT_NOT_FOUND', 'Entitlement not found.');
    if (entitlement.status !== 'ACTIVE') throw new BusinessError(409, 'ENTITLEMENT_NOT_ACTIVE', 'Course access is not active.');
    const revoked = await tx.courseEntitlement.update({ where: { id: entitlement.id }, data: { status: 'REVOKED', revokedAt: new Date(), revokeReason } });
    await tx.auditLog.create({ data: { userId: entitlement.userId, action: 'COURSE_ACCESS_REVOKED', entityType: 'CourseEntitlement', entityId: entitlement.id, ipAddress: clientIp(req), metadata: { courseId: entitlement.courseId, reason: revokeReason, revokedByAdminId: adminId } } });
    await tx.auditLog.create({ data: { userId: adminId, action: 'ADMIN_ENTITLEMENT_REVOKED', entityType: 'CourseEntitlement', entityId: entitlement.id, ipAddress: clientIp(req), metadata: { targetUserId: entitlement.userId, courseId: entitlement.courseId, reason: revokeReason } } });
    return revoked;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

module.exports = { grantEntitlement, requireActiveEntitlement, revokeEntitlement };
