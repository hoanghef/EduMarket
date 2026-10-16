'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');

const router = Router();
const levels = new Set(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']);
const sorts = {
  newest: { publishedAt: 'desc' },
  price_asc: { price: 'asc' },
  price_desc: { price: 'desc' },
  rating: { ratingAverage: 'desc' },
  popularity: { enrollmentCount: 'desc' },
};

function courseEffectivePrice(course) {
  const price = Number(course.price);
  const salePrice = course.salePrice === null ? null : Number(course.salePrice);
  return salePrice !== null && salePrice < price ? salePrice : price;
}

function sortCourses(items, sort) {
  const direction = sort === 'price_asc' ? 1 : -1;
  if (sort === 'price_asc' || sort === 'price_desc') {
    return items.sort((a, b) => {
      const difference = courseEffectivePrice(a) - courseEffectivePrice(b);
      return difference === 0 ? a.id.localeCompare(b.id) : difference * direction;
    });
  }
  return items;
}

function number(value, fallback, min = 0) {
  if (value === undefined) return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= min ? parsed : null;
}

router.get('/categories', async (_req, res, next) => {
  try {
    const categories = await prisma.category.findMany({
      where: { parentId: null, isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: { children: { where: { isActive: true }, orderBy: { sortOrder: 'asc' } } },
    });
    res.json({ success: true, data: { categories } });
  } catch (error) { next(error); }
});

router.get('/courses', async (req, res, next) => {
  try {
    const page = number(req.query.page, 1, 1);
    const limit = number(req.query.limit, 12, 1);
    const minPrice = number(req.query.minPrice, undefined);
    const maxPrice = number(req.query.maxPrice, undefined);
    const minRating = number(req.query.rating, undefined);
    if (!page || !limit || limit > 50 || minPrice === null || maxPrice === null || minRating === null || (minPrice !== undefined && maxPrice !== undefined && minPrice > maxPrice) || (req.query.level && !levels.has(req.query.level)) || (req.query.sort && !sorts[req.query.sort])) {
      return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Invalid catalog query.' });
    }

    const where = { status: 'PUBLISHED' };
    if (req.query.q) {
      const q = String(req.query.q).trim();
      if (q.length > 100) return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Search keyword is too long.' });
      if (q) where.OR = [{ title: { contains: q, mode: 'insensitive' } }, { shortDescription: { contains: q, mode: 'insensitive' } }, { instructorName: { contains: q, mode: 'insensitive' } }];
    }
    if (req.query.category) {
      const category = await prisma.category.findFirst({ where: { OR: [{ id: String(req.query.category) }, { slug: String(req.query.category) }], isActive: true }, select: { id: true } });
      if (!category) return res.json({ success: true, data: { items: [], pagination: { page, limit, total: 0, totalPages: 0 } } });
      // Include every active descendant, not just direct children, when the
      // user filters by a parent category.
      const categoryIds = [category.id];
      let parentIds = [category.id];
      while (parentIds.length) {
        const children = await prisma.category.findMany({
          where: { parentId: { in: parentIds }, isActive: true },
          select: { id: true },
        });
        parentIds = children.map((child) => child.id);
        categoryIds.push(...parentIds);
      }
      where.categoryId = { in: categoryIds };
    }
    if (req.query.level) where.level = req.query.level;
    if (minRating !== undefined) where.ratingAverage = { gte: minRating };
    if (req.query.instructor) where.instructorName = { contains: String(req.query.instructor).trim(), mode: 'insensitive' };

    const sort = req.query.sort || 'newest';
    const needsEffectivePriceEvaluation = minPrice !== undefined || maxPrice !== undefined || req.query.free === 'true' || sort === 'price_asc' || sort === 'price_desc';
    let total;
    let items;
    if (needsEffectivePriceEvaluation) {
      // Prisma cannot express `salePrice ?? price` as a portable field
      // comparison. Evaluate the same price rule used by checkout/UI before
      // slicing the result set, so filter, sort and pagination stay aligned.
      let matches = await prisma.course.findMany({
        where,
        orderBy: [sorts[sort], { id: 'asc' }],
        include: { category: { select: { id: true, name: true, slug: true } } },
      });
      matches = matches.filter((course) => {
        const price = courseEffectivePrice(course);
        if (req.query.free === 'true') return price === 0;
        return (minPrice === undefined || price >= minPrice) &&
          (maxPrice === undefined || price <= maxPrice);
      });
      sortCourses(matches, sort);
      total = matches.length;
      items = matches.slice((page - 1) * limit, page * limit);
    } else {
      [total, items] = await prisma.$transaction([
        prisma.course.count({ where }),
        prisma.course.findMany({
          where,
          orderBy: [sorts[sort], { id: 'asc' }],
          skip: (page - 1) * limit,
          take: limit,
          include: { category: { select: { id: true, name: true, slug: true } } },
        }),
      ]);
    }
    return res.json({ success: true, data: { items, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } } });
  } catch (error) { return next(error); }
});

router.get('/courses/:slug', async (req, res, next) => {
  try {
    const course = await prisma.course.findFirst({
      where: { slug: req.params.slug, status: 'PUBLISHED' },
      include: {
        category: { select: { id: true, name: true, slug: true } },
        lessons: { orderBy: { position: 'asc' }, select: { id: true, title: true, durationSec: true, position: true, isPreview: true, isRequired: true } },
      },
    });
    if (!course) return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' });
    return res.json({ success: true, data: { course } });
  } catch (error) { return next(error); }
});

router.get('/courses/:id/recommendations', async (req, res, next) => {
  try {
    const source = await prisma.course.findFirst({ where: { id: req.params.id, status: 'PUBLISHED' }, select: { id: true, categoryId: true, level: true } });
    if (!source) return res.status(404).json({ success: false, code: 'COURSE_NOT_FOUND', message: 'Course not found.' });
    const items = await prisma.course.findMany({
      where: { id: { not: source.id }, status: 'PUBLISHED', OR: [{ categoryId: source.categoryId }, { level: source.level }] },
      orderBy: [{ ratingAverage: 'desc' }, { enrollmentCount: 'desc' }, { publishedAt: 'desc' }],
      take: 6,
      include: { category: { select: { id: true, name: true, slug: true } } },
    });
    return res.json({ success: true, data: { items } });
  } catch (error) { return next(error); }
});

module.exports = router;
