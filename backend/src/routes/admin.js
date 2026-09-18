'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAdmin, requireAuth } = require('../middleware/auth');
const { confirmCodOrder } = require('../services/order-service');
const { grantEntitlement, revokeEntitlement } = require('../services/entitlement-service');

const router = Router();
const levels = new Set(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']);
const statuses = new Set(['DRAFT', 'PUBLISHED', 'ARCHIVED']);

router.use(requireAuth, requireAdmin);

function text(value, max, required = false) {
  if (value === undefined && !required) return undefined;
  if (typeof value !== 'string') return null;
  const result = value.trim();
  return (!required || result.length > 0) && result.length <= max ? result : null;
}
function positiveInt(value, required = false) {
  if (value === undefined && !required) return undefined;
  const result = Number(value);
  return Number.isInteger(result) && result >= 0 ? result : null;
}
function money(value, required = false) {
  if (value === undefined && !required) return undefined;
  const result = Number(value);
  return Number.isFinite(result) && result >= 0 && result <= 9999999999 ? result.toFixed(2) : null;
}
function fail(res) { return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Invalid request data.' }); }
async function audit(req, action, entityType, entityId) {
  await prisma.auditLog.create({ data: { userId: req.user.id, action, entityType, entityId, ipAddress: req.ip || null } });
}

router.get('/categories', async (_req, res, next) => { try { res.json({ success: true, data: { items: await prisma.category.findMany({ orderBy: [{ parentId: 'asc' }, { sortOrder: 'asc' }] }) } }); } catch (e) { next(e); } });
router.post('/categories', async (req, res, next) => {
  try {
    const name = text(req.body.name, 120, true), slug = text(req.body.slug, 140, true);
    if (!name || !slug || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug) || (req.body.parentId !== undefined && typeof req.body.parentId !== 'string')) return fail(res);
    if (req.body.parentId && !await prisma.category.findUnique({ where: { id: req.body.parentId } })) return fail(res);
    const category = await prisma.category.create({ data: { name, slug, parentId: req.body.parentId || null, description: text(req.body.description, 1000), imageUrl: text(req.body.imageUrl, 500), sortOrder: positiveInt(req.body.sortOrder) ?? 0, isActive: req.body.isActive !== false } });
    await audit(req, 'CATEGORY_CREATED', 'Category', category.id); return res.status(201).json({ success: true, data: { category } });
  } catch (e) { if (e.code === 'P2002') return res.status(409).json({ success: false, code: 'DUPLICATE_CATEGORY', message: 'Category already exists.' }); next(e); }
});
router.patch('/categories/:id', async (req, res, next) => {
  try {
    const data = {};
    for (const [key, max] of [['name', 120], ['slug', 140], ['description', 1000], ['imageUrl', 500]]) if (req.body[key] !== undefined) { const value = text(req.body[key], max, key === 'name' || key === 'slug'); if (!value) return fail(res); data[key] = value; }
    if (data.slug && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(data.slug)) return fail(res);
    if (req.body.sortOrder !== undefined) { const value = positiveInt(req.body.sortOrder); if (value === null) return fail(res); data.sortOrder = value; }
    if (req.body.isActive !== undefined) { if (typeof req.body.isActive !== 'boolean') return fail(res); data.isActive = req.body.isActive; }
    const category = await prisma.category.update({ where: { id: req.params.id }, data }); await audit(req, 'CATEGORY_UPDATED', 'Category', category.id); return res.json({ success: true, data: { category } });
  } catch (e) { if (e.code === 'P2025') return res.status(404).json({ success: false, code: 'CATEGORY_NOT_FOUND', message: 'Category not found.' }); next(e); }
});
router.delete('/categories/:id', async (req, res, next) => { try { const [children, courses] = await Promise.all([prisma.category.count({ where: { parentId: req.params.id } }), prisma.course.count({ where: { categoryId: req.params.id } })]); if (children || courses) return res.status(409).json({ success: false, code: 'CATEGORY_IN_USE', message: 'Category has children or courses.' }); await prisma.category.delete({ where: { id: req.params.id } }); await audit(req, 'CATEGORY_DELETED', 'Category', req.params.id); return res.status(204).end(); } catch (e) { next(e); } });

async function courseData(body, creating) {
  const title = text(body.title, 220, creating), slug = text(body.slug, 240, creating), description = text(body.description, 10000, creating), instructorName = text(body.instructorName, 160, creating), price = money(body.price, creating);
  if ([title, slug, description, instructorName, price].some((value) => value === null) || (slug && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) || (body.categoryId !== undefined && typeof body.categoryId !== 'string') || (creating && !body.categoryId)) return null;
  if (body.categoryId && !await prisma.category.findUnique({ where: { id: body.categoryId } })) return null;
  if (body.salePrice !== undefined && money(body.salePrice) === null) return null;
  if (body.level !== undefined && !levels.has(body.level)) return null;
  if (body.status !== undefined && !statuses.has(body.status)) return null;
  const data = { ...(title !== undefined ? { title } : {}), ...(slug !== undefined ? { slug } : {}), ...(description !== undefined ? { description } : {}), ...(instructorName !== undefined ? { instructorName } : {}), ...(price !== undefined ? { price } : {}), ...(body.categoryId !== undefined ? { categoryId: body.categoryId } : {}), ...(body.salePrice !== undefined ? { salePrice: money(body.salePrice) } : {}), ...(body.level !== undefined ? { level: body.level } : {}), ...(body.status !== undefined ? { status: body.status } : {}), ...(body.shortDescription !== undefined ? { shortDescription: text(body.shortDescription, 500) } : {}), ...(body.thumbnailUrl !== undefined ? { thumbnailUrl: text(body.thumbnailUrl, 500) } : {}) };
  if (data.status === 'PUBLISHED') data.publishedAt = new Date();
  return data;
}
router.get('/courses', async (_req, res, next) => { try { res.json({ success: true, data: { items: await prisma.course.findMany({ include: { category: true }, orderBy: { updatedAt: 'desc' } }) } }); } catch (e) { next(e); } });
router.post('/courses', async (req, res, next) => { try { const data = await courseData(req.body, true); if (!data) return fail(res); const course = await prisma.course.create({ data }); await audit(req, 'COURSE_CREATED', 'Course', course.id); return res.status(201).json({ success: true, data: { course } }); } catch (e) { if (e.code === 'P2002') return res.status(409).json({ success: false, code: 'DUPLICATE_COURSE', message: 'Course slug already exists.' }); next(e); } });
router.patch('/courses/:id', async (req, res, next) => { try { const data = await courseData(req.body, false); if (!data || !Object.keys(data).length) return fail(res); const course = await prisma.course.update({ where: { id: req.params.id }, data }); await audit(req, 'COURSE_UPDATED', 'Course', course.id); return res.json({ success: true, data: { course } }); } catch (e) { if (e.code === 'P2025') return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' }); next(e); } });
router.delete('/courses/:id', async (req, res, next) => { try { await prisma.course.delete({ where: { id: req.params.id } }); await audit(req, 'COURSE_DELETED', 'Course', req.params.id); return res.status(204).end(); } catch (e) { if (e.code === 'P2025') return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' }); next(e); } });

router.post('/courses/:courseId/lessons', async (req, res, next) => { try { const title = text(req.body.title, 220, true), position = positiveInt(req.body.position, true), durationSec = positiveInt(req.body.durationSec) ?? 0; if (!title || position === null || durationSec === null) return fail(res); const lesson = await prisma.lesson.create({ data: { courseId: req.params.courseId, title, position, durationSec, content: text(req.body.content, 20000), videoUrl: text(req.body.videoUrl, 500), isPreview: req.body.isPreview === true, isRequired: req.body.isRequired !== false } }); await audit(req, 'LESSON_CREATED', 'Lesson', lesson.id); return res.status(201).json({ success: true, data: { lesson } }); } catch (e) { next(e); } });
router.patch('/lessons/:id', async (req, res, next) => { try { const data = {}; if (req.body.title !== undefined) { const value = text(req.body.title, 220, true); if (!value) return fail(res); data.title = value; } if (req.body.position !== undefined) { const value = positiveInt(req.body.position, true); if (value === null) return fail(res); data.position = value; } if (req.body.durationSec !== undefined) { const value = positiveInt(req.body.durationSec); if (value === null) return fail(res); data.durationSec = value; } for (const key of ['isPreview', 'isRequired']) if (req.body[key] !== undefined) { if (typeof req.body[key] !== 'boolean') return fail(res); data[key] = req.body[key]; } const lesson = await prisma.lesson.update({ where: { id: req.params.id }, data }); await audit(req, 'LESSON_UPDATED', 'Lesson', lesson.id); return res.json({ success: true, data: { lesson } }); } catch (e) { next(e); } });
router.delete('/lessons/:id', async (req, res, next) => { try { await prisma.lesson.delete({ where: { id: req.params.id } }); await audit(req, 'LESSON_DELETED', 'Lesson', req.params.id); return res.status(204).end(); } catch (e) { next(e); } });

router.post('/courses/:courseId/files', async (req, res, next) => { try { const originalName = text(req.body.originalName, 255, true), storageKey = text(req.body.storageKey, 500, true), mimeType = text(req.body.mimeType, 150, true), sizeBytes = positiveInt(req.body.sizeBytes, true); if (!originalName || !storageKey || !mimeType || sizeBytes === null || !/^private\/[A-Za-z0-9/_-]+$/.test(storageKey)) return fail(res); if (req.body.lessonId && !await prisma.lesson.findFirst({ where: { id: req.body.lessonId, courseId: req.params.courseId } })) return fail(res); const file = await prisma.courseFile.create({ data: { courseId: req.params.courseId, lessonId: req.body.lessonId || null, originalName, storageKey, mimeType, sizeBytes } }); await audit(req, 'COURSE_FILE_CREATED', 'CourseFile', file.id); return res.status(201).json({ success: true, data: { file } }); } catch (e) { next(e); } });
router.patch('/files/:id', async (req, res, next) => { try { const data = {}; for (const [key, max] of [['originalName', 255], ['storageKey', 500], ['mimeType', 150]]) if (req.body[key] !== undefined) { const value = text(req.body[key], max, true); if (!value || (key === 'storageKey' && !/^private\/[A-Za-z0-9/_-]+$/.test(value))) return fail(res); data[key] = value; } if (req.body.sizeBytes !== undefined) { const value = positiveInt(req.body.sizeBytes, true); if (value === null) return fail(res); data.sizeBytes = value; } const file = await prisma.courseFile.update({ where: { id: req.params.id }, data }); await audit(req, 'COURSE_FILE_UPDATED', 'CourseFile', file.id); return res.json({ success: true, data: { file } }); } catch (e) { next(e); } });
router.delete('/files/:id', async (req, res, next) => { try { await prisma.courseFile.delete({ where: { id: req.params.id } }); await audit(req, 'COURSE_FILE_DELETED', 'CourseFile', req.params.id); return res.status(204).end(); } catch (e) { next(e); } });

router.patch('/orders/:id/cod-confirm', async (req, res, next) => {
  try {
    const order = await confirmCodOrder(req.params.id, req.user.id, req);
    return res.json({ success: true, data: { order } });
  } catch (error) { return next(error); }
});

router.post('/entitlements/grant', async (req, res, next) => {
  try {
    const { userId, courseId, orderId } = req.body || {};
    if (![userId, courseId, orderId].every((value) => typeof value === 'string' && value.trim())) return fail(res);
    const entitlement = await grantEntitlement({ userId, courseId, orderId, adminId: req.user.id, req });
    return res.status(201).json({ success: true, data: { entitlement } });
  } catch (error) { return next(error); }
});

router.patch('/entitlements/:id/revoke', async (req, res, next) => {
  try {
    const entitlement = await revokeEntitlement({ entitlementId: req.params.id, reason: req.body?.reason, adminId: req.user.id, req });
    return res.json({ success: true, data: { entitlement } });
  } catch (error) { return next(error); }
});

module.exports = router;
