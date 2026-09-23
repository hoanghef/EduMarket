'use strict';

const { Router } = require('express');
const prisma = require('../lib/prisma');

const router = Router();

// Base URL for canonical links in sitemap. Defaults to frontend address.
function getBaseUrl(req) {
  if (process.env.APP_URL) return process.env.APP_URL.replace(/\/+$/, '');
  const proto = req.get('x-forwarded-proto') || req.protocol || 'http';
  const host = req.get('host') || 'localhost:3000';
  return `${proto}://${host}`;
}

// ── GET /robots.txt ─────────────────────────────────────────────────────────
router.get('/robots.txt', (req, res) => {
  const baseUrl = getBaseUrl(req);
  const content = [
    'User-agent: *',
    'Allow: /',
    'Allow: /khoa-hoc',
    'Allow: /khoa-hoc/*',
    'Allow: /danh-muc/*',
    'Allow: /certificates/verify',
    'Allow: /certificates/verify/*',
    'Allow: /chinh-sach/*',
    'Allow: /khuyen-mai',
    '',
    '# Disallow private and authenticated user routes',
    'Disallow: /admin',
    'Disallow: /admin/*',
    'Disallow: /account',
    'Disallow: /account/*',
    'Disallow: /cart',
    'Disallow: /checkout',
    'Disallow: /library',
    'Disallow: /library/*',
    'Disallow: /login',
    'Disallow: /register',
    'Disallow: /api/',
    '',
    `Sitemap: ${baseUrl}/sitemap.xml`,
    '',
  ].join('\n');

  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  return res.status(200).send(content);
});

// ── GET /sitemap.xml ────────────────────────────────────────────────────────
router.get('/sitemap.xml', async (req, res, next) => {
  try {
    const baseUrl = getBaseUrl(req);
    const now = new Date().toISOString().split('T')[0];

    // Static public routes that are indexable
    const staticRoutes = [
      { path: '', priority: '1.0', changefreq: 'daily' },
      { path: '/khoa-hoc', priority: '0.9', changefreq: 'daily' },
      { path: '/khuyen-mai', priority: '0.8', changefreq: 'weekly' },
      { path: '/certificates/verify', priority: '0.7', changefreq: 'monthly' },
      { path: '/chinh-sach/business', priority: '0.5', changefreq: 'monthly' },
      { path: '/chinh-sach/terms', priority: '0.5', changefreq: 'monthly' },
      { path: '/chinh-sach/refunds', priority: '0.5', changefreq: 'monthly' },
      { path: '/chinh-sach/privacy', priority: '0.5', changefreq: 'monthly' },
    ];

    // Fetch published courses only (no DRAFT, ARCHIVED, or deleted)
    const courses = await prisma.course.findMany({
      where: { status: 'PUBLISHED' },
      select: { slug: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    });

    // Fetch active categories
    const categories = await prisma.category.findMany({
      where: { isActive: true },
      select: { slug: true, updatedAt: true },
      orderBy: { sortOrder: 'asc' },
    });

    const urls = [];

    // Add static indexable URLs
    for (const route of staticRoutes) {
      urls.push(`  <url>
    <loc>${baseUrl}${route.path}</loc>
    <lastmod>${now}</lastmod>
    <changefreq>${route.changefreq}</changefreq>
    <priority>${route.priority}</priority>
  </url>`);
    }

    // Add public categories
    for (const cat of categories) {
      const lastmod = cat.updatedAt ? cat.updatedAt.toISOString().split('T')[0] : now;
      urls.push(`  <url>
    <loc>${baseUrl}/danh-muc/${encodeURIComponent(cat.slug)}</loc>
    <lastmod>${lastmod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>`);
    }

    // Add published courses
    for (const course of courses) {
      const lastmod = course.updatedAt ? course.updatedAt.toISOString().split('T')[0] : now;
      urls.push(`  <url>
    <loc>${baseUrl}/khoa-hoc/${encodeURIComponent(course.slug)}</loc>
    <lastmod>${lastmod}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>`);
    }

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.join('\n')}
</urlset>
`;

    res.setHeader('Content-Type', 'application/xml; charset=utf-8');
    return res.status(200).send(xml);
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
