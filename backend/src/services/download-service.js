'use strict';

const crypto = require('crypto');
const fs = require('fs');
const { Prisma } = require('../generated/prisma');
const prisma = require('../lib/prisma');
const { BusinessError, clientIp } = require('./order-service');
const { requireActiveEntitlement } = require('./entitlement-service');
const { privateFilePath } = require('./file-storage-service');

const TOKEN_TTL_MS = 10 * 60 * 1000;
const DEFAULT_MAX_DOWNLOADS = 1;

function tokenHash(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function createDownloadToken(userId, fileId, req) {
  const file = await prisma.courseFile.findUnique({ where: { id: fileId }, select: { id: true, courseId: true } });
  if (!file) throw new BusinessError(404, 'FILE_NOT_FOUND', 'File not found.');
  await requireActiveEntitlement(userId, file.courseId);
  const token = crypto.randomBytes(32).toString('base64url');
  const expiresAt = new Date(Date.now() + TOKEN_TTL_MS);
  const record = await prisma.downloadToken.create({ data: { tokenHash: tokenHash(token), userId, courseFileId: file.id, expiresAt, maxDownloads: DEFAULT_MAX_DOWNLOADS } });
  await prisma.auditLog.create({ data: { userId, action: 'DOWNLOAD_TOKEN_ISSUED', entityType: 'DownloadToken', entityId: record.id, ipAddress: clientIp(req), metadata: { courseFileId: file.id, expiresAt } } });
  return { token, expiresAt };
}

async function consumeDownloadToken(rawToken, userId, req) {
  if (typeof rawToken !== 'string' || rawToken.length < 32 || rawToken.length > 200) throw new BusinessError(404, 'DOWNLOAD_TOKEN_NOT_FOUND', 'Download token not found.');
  const hash = tokenHash(rawToken);
  return prisma.$transaction(async (tx) => {
    const record = await tx.downloadToken.findUnique({ where: { tokenHash: hash }, include: { courseFile: true } });
    if (!record) throw new BusinessError(404, 'DOWNLOAD_TOKEN_NOT_FOUND', 'Download token not found.');
    if (record.userId !== userId) throw new BusinessError(403, 'DOWNLOAD_TOKEN_FORBIDDEN', 'This download token belongs to another user.');
    if (record.expiresAt <= new Date()) throw new BusinessError(410, 'DOWNLOAD_TOKEN_EXPIRED', 'Download token has expired.');
    if (record.downloadCount >= record.maxDownloads) throw new BusinessError(410, 'DOWNLOAD_TOKEN_EXHAUSTED', 'Download token has already been used.');
    await requireActiveEntitlement(userId, record.courseFile.courseId, tx);
    const filePath = privateFilePath(record.courseFile.storageKey);
    if (!fs.existsSync(filePath)) throw new BusinessError(404, 'FILE_NOT_FOUND', 'File content is not available.');
    const claimed = await tx.downloadToken.updateMany({ where: { id: record.id, downloadCount: { lt: record.maxDownloads } }, data: { downloadCount: { increment: 1 }, lastUsedAt: new Date() } });
    if (claimed.count !== 1) throw new BusinessError(410, 'DOWNLOAD_TOKEN_EXHAUSTED', 'Download token has already been used.');
    await tx.auditLog.create({ data: { userId, action: 'FILE_DOWNLOADED', entityType: 'CourseFile', entityId: record.courseFile.id, ipAddress: clientIp(req), metadata: { downloadTokenId: record.id } } });
    return { file: record.courseFile, filePath };
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

module.exports = { TOKEN_TTL_MS, consumeDownloadToken, createDownloadToken, tokenHash };
