'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAdmin, requireAuth } = require('../middleware/auth');
const { confirmCodOrder } = require('../services/order-service');
const { grantEntitlement, revokeEntitlement } = require('../services/entitlement-service');
const { removeStoredFile, uploadSingleFile, validateStoredFileContent } = require('../services/file-storage-service');
const { moderateReview } = require('../services/review-service');

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

router.post('/courses/:courseId/files', uploadSingleFile, async (req, res, next) => { try { if (!req.file) return fail(res); if (!validateStoredFileContent(req.file.path, req.file.originalname)) { removeStoredFile(req.file.filename); return res.status(400).json({ success: false, code: 'INVALID_FILE_CONTENT', message: 'File content does not match its declared type.' }); } if (!await prisma.course.findUnique({ where: { id: req.params.courseId } })) { removeStoredFile(req.file.filename); return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' }); } if (req.body.lessonId && !await prisma.lesson.findFirst({ where: { id: req.body.lessonId, courseId: req.params.courseId } })) { removeStoredFile(req.file.filename); return fail(res); } const file = await prisma.courseFile.create({ data: { courseId: req.params.courseId, lessonId: req.body.lessonId || null, originalName: req.file.originalname, storageKey: req.file.filename, mimeType: req.file.mimetype, sizeBytes: req.file.size } }); await audit(req, 'COURSE_FILE_CREATED', 'CourseFile', file.id); return res.status(201).json({ success: true, data: { file } }); } catch (e) { if (req.file) removeStoredFile(req.file.filename); next(e); } });
router.patch('/files/:id', async (req, res, next) => { try { const data = {}; for (const [key, max] of [['originalName', 255], ['mimeType', 150]]) if (req.body[key] !== undefined) { const value = text(req.body[key], max, true); if (!value) return fail(res); data[key] = value; } if (req.body.sizeBytes !== undefined) { const value = positiveInt(req.body.sizeBytes, true); if (value === null) return fail(res); data.sizeBytes = value; } const file = await prisma.courseFile.update({ where: { id: req.params.id }, data }); await audit(req, 'COURSE_FILE_UPDATED', 'CourseFile', file.id); return res.json({ success: true, data: { file } }); } catch (e) { next(e); } });
router.delete('/files/:id', async (req, res, next) => { try { const file = await prisma.courseFile.delete({ where: { id: req.params.id } }); removeStoredFile(file.storageKey); await audit(req, 'COURSE_FILE_DELETED', 'CourseFile', req.params.id); return res.status(204).end(); } catch (e) { next(e); } });

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

router.patch('/reviews/:id/moderate', async (req, res, next) => {
  try {
    const review = await moderateReview({ reviewId: req.params.id, status: req.body?.status, adminId: req.user.id, req });
    return res.json({ success: true, data: { review } });
  } catch (error) { return next(error); }
});

router.get('/dashboard', async (_req, res, next) => {
  try {
    const [totalRevResult, orderCount, customerCount, courseCount, recentOrders, bestSellingCourses] = await Promise.all([
      prisma.order.aggregate({
        where: { status: { in: ['PAID', 'COMPLETED'] } },
        _sum: { totalAmount: true },
      }),
      prisma.order.count(),
      prisma.user.count({ where: { role: 'CUSTOMER' } }),
      prisma.course.count(),
      prisma.order.findMany({
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { fullName: true, email: true } },
          payment: { select: { method: true, status: true } },
        },
      }),
      prisma.course.findMany({
        take: 5,
        orderBy: [{ enrollmentCount: 'desc' }, { ratingAverage: 'desc' }],
        select: {
          id: true,
          title: true,
          enrollmentCount: true,
          price: true,
          ratingAverage: true,
        },
      }),
    ]);

    const totalRevenue = totalRevResult._sum.totalAmount ? Number(totalRevResult._sum.totalAmount) : 0;

    const paidOrders = await prisma.order.findMany({
      where: { status: { in: ['PAID', 'COMPLETED'] } },
      select: { totalAmount: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    });
    const monthlyMap = {};
    for (const ord of paidOrders) {
      const monthKey = ord.createdAt.toISOString().slice(0, 7);
      monthlyMap[monthKey] = (monthlyMap[monthKey] || 0) + Number(ord.totalAmount);
    }
    const monthlyRevenue = Object.entries(monthlyMap).map(([month, revenue]) => ({ month, revenue }));

    return res.json({
      success: true,
      data: {
        totalRevenue,
        orderCount,
        customerCount,
        courseCount,
        recentOrders,
        bestSellingCourses,
        monthlyRevenue,
      },
    });
  } catch (error) { return next(error); }
});

router.get('/reports/revenue', async (_req, res, next) => {
  try {
    const [totalPaid, codRevenue, vnpayRevenue] = await Promise.all([
      prisma.order.aggregate({
        where: { status: { in: ['PAID', 'COMPLETED'] } },
        _sum: { totalAmount: true, discountAmount: true, subtotal: true },
        _count: { id: true },
      }),
      prisma.payment.aggregate({
        where: { method: 'COD', status: 'SUCCESS' },
        _sum: { amount: true },
        _count: { id: true },
      }),
      prisma.payment.aggregate({
        where: { method: 'VNPAY', status: 'SUCCESS' },
        _sum: { amount: true },
        _count: { id: true },
      }),
    ]);

    return res.json({
      success: true,
      data: {
        totalRevenue: totalPaid._sum.totalAmount ? Number(totalPaid._sum.totalAmount) : 0,
        totalDiscount: totalPaid._sum.discountAmount ? Number(totalPaid._sum.discountAmount) : 0,
        totalSubtotal: totalPaid._sum.subtotal ? Number(totalPaid._sum.subtotal) : 0,
        paidOrdersCount: totalPaid._count.id,
        cod: {
          revenue: codRevenue._sum.amount ? Number(codRevenue._sum.amount) : 0,
          count: codRevenue._count.id,
        },
        vnpay: {
          revenue: vnpayRevenue._sum.amount ? Number(vnpayRevenue._sum.amount) : 0,
          count: vnpayRevenue._count.id,
        },
      },
    });
  } catch (error) { return next(error); }
});

router.get('/orders', async (req, res, next) => {
  try {
    const where = {};
    if (req.query.status) where.status = req.query.status;
    const orders = await prisma.order.findMany({
      where,
      include: {
        user: { select: { id: true, fullName: true, email: true } },
        payment: true,
        items: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return res.json({ success: true, data: { items: orders } });
  } catch (error) { return next(error); }
});

router.get('/users', async (req, res, next) => {
  try {
    const where = {};
    if (req.query.role) where.role = req.query.role;
    if (req.query.q) {
      const q = String(req.query.q).trim();
      where.OR = [
        { fullName: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
      ];
    }
    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        role: true,
        isActive: true,
        createdAt: true,
        _count: { select: { orders: true, entitlements: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return res.json({ success: true, data: { items: users } });
  } catch (error) { return next(error); }
});

router.get('/reviews', async (req, res, next) => {
  try {
    const where = {};
    if (req.query.status) where.status = req.query.status;
    const reviews = await prisma.review.findMany({
      where,
      include: {
        user: { select: { id: true, fullName: true, email: true } },
        course: { select: { id: true, title: true, slug: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return res.json({ success: true, data: { items: reviews } });
  } catch (error) { return next(error); }
});

router.get('/coupons', async (_req, res, next) => {
  try {
    const coupons = await prisma.coupon.findMany({
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { orders: true, usages: true } } },
    });
    return res.json({ success: true, data: { items: coupons } });
  } catch (error) { return next(error); }
});

router.post('/coupons', async (req, res, next) => {
  try {
    const code = text(req.body.code, 64, true)?.toUpperCase();
    const discountType = req.body.discountType;
    const discountValue = money(req.body.discountValue, true);
    if (!code || !/^[A-Z0-9][A-Z0-9_-]{1,63}$/.test(code) || !['PERCENTAGE', 'FIXED'].includes(discountType) || !discountValue) {
      return fail(res);
    }
    const startsAt = req.body.startsAt ? new Date(req.body.startsAt) : new Date();
    const endsAt = req.body.endsAt ? new Date(req.body.endsAt) : new Date(Date.now() + 30 * 86400000);
    if (isNaN(startsAt.getTime()) || isNaN(endsAt.getTime()) || startsAt >= endsAt) {
      return fail(res);
    }
    const coupon = await prisma.coupon.create({
      data: {
        code,
        description: text(req.body.description, 500),
        discountType,
        discountValue,
        minimumOrderAmount: money(req.body.minimumOrderAmount),
        maximumDiscountAmount: money(req.body.maximumDiscountAmount),
        usageLimit: positiveInt(req.body.usageLimit),
        perUserLimit: positiveInt(req.body.perUserLimit) ?? 1,
        startsAt,
        endsAt,
        isActive: req.body.isActive !== false,
      },
    });
    await audit(req, 'COUPON_CREATED', 'Coupon', coupon.id);
    return res.status(201).json({ success: true, data: { coupon } });
  } catch (error) {
    if (error.code === 'P2002') return res.status(409).json({ success: false, code: 'DUPLICATE_COUPON', message: 'Coupon code already exists.' });
    return next(error);
  }
});

router.patch('/coupons/:id', async (req, res, next) => {
  try {
    const data = {};
    if (req.body.isActive !== undefined) {
      if (typeof req.body.isActive !== 'boolean') return fail(res);
      data.isActive = req.body.isActive;
    }
    if (req.body.description !== undefined) {
      data.description = text(req.body.description, 500);
    }
    if (req.body.usageLimit !== undefined) {
      data.usageLimit = positiveInt(req.body.usageLimit);
    }
    const coupon = await prisma.coupon.update({ where: { id: req.params.id }, data });
    await audit(req, 'COUPON_UPDATED', 'Coupon', coupon.id);
    return res.json({ success: true, data: { coupon } });
  } catch (error) {
    if (error.code === 'P2025') return res.status(404).json({ success: false, code: 'COUPON_NOT_FOUND', message: 'Coupon not found.' });
    return next(error);
  }
});

router.get('/entitlements', async (req, res, next) => {
  try {
    const where = {};
    if (req.query.status) where.status = req.query.status;
    const items = await prisma.courseEntitlement.findMany({
      where,
      include: {
        user: { select: { id: true, fullName: true, email: true } },
        course: { select: { id: true, title: true, slug: true } },
        order: { select: { id: true, orderNumber: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return res.json({ success: true, data: { items } });
  } catch (error) { return next(error); }
});

module.exports = router;
