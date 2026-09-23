'use strict';

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

if (process.env.TRUST_PROXY === 'true') {
  // Required only when HTTPS is terminated by one trusted reverse proxy.
  app.set('trust proxy', 1);
}

// ── Security middleware ──────────────────────────────────────────────────────
app.use(
  helmet({
    frameguard: { action: 'deny' },
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        baseUri: ["'self'"],
        frameAncestors: ["'none'"],
        objectSrc: ["'none'"],
      },
    },
  })
);

// CORS – Flutter Web will be served from a different origin in dev
const configuredOrigins = process.env.CORS_ORIGINS;
if (process.env.NODE_ENV === 'production' && !configuredOrigins) {
  throw new Error('CORS_ORIGINS must be configured in production.');
}
const allowedOrigins = (configuredOrigins || 'http://localhost:3000')
  .split(',')
  .map((o) => o.trim());

app.use(
  cors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'X-CSRF-Token'],
  })
);

// Global rate limiter (will be overridden on sensitive routes)
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 500 : 2000,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, code: 'RATE_LIMIT', message: 'Too many requests' },
});
app.use(globalLimiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Routes ───────────────────────────────────────────────────────────────────
const healthRouter = require('./routes/health');
const authRouter = require('./routes/auth');
const catalogRouter = require('./routes/catalog');
const cartRouter = require('./routes/cart');
const checkoutRouter = require('./routes/checkout');
const ordersRouter = require('./routes/orders');
const paymentsRouter = require('./routes/payments');
const libraryRouter = require('./routes/library');
const { downloadRouter, filesRouter } = require('./routes/downloads');
const certificatesRouter = require('./routes/certificates');
const policiesRouter = require('./routes/policies');
const wishlistRouter = require('./routes/wishlist');
const reviewsRouter = require('./routes/reviews');
const couponsRouter = require('./routes/coupons');
const adminRouter = require('./routes/admin');
const seoRouter = require('./routes/seo');
const { csrfProtection } = require('./lib/auth');

// Public SEO files (sitemap.xml, robots.txt)
app.use('/', seoRouter);

app.use('/api', healthRouter);
app.use('/api', csrfProtection);
app.use('/api/auth', authRouter);
app.use('/api', catalogRouter);
app.use('/api/cart', cartRouter);
app.use('/api/checkout', checkoutRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/library', libraryRouter);
app.use('/api/files', filesRouter);
app.use('/api/download', downloadRouter);
app.use('/api/certificates', certificatesRouter);
app.use('/api/policies', policiesRouter);
app.use('/api/wishlist', wishlistRouter);
app.use('/api', reviewsRouter);
app.use('/api/coupons', couponsRouter);
app.use('/api/admin', adminRouter);

// ── 404 handler ──────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, code: 'NOT_FOUND', message: 'Route not found' });
});

// ── Central error handler ────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  const status = err.statusCode || err.status || 500;
  const code = err.code || 'INTERNAL_ERROR';
  console.error(`[ERROR] ${code}:`, err.message);
  if (process.env.NODE_ENV !== 'production') {
    console.error(err.stack);
  }
  res.status(status).json({
    success: false,
    code,
    message: err.message || 'Internal server error',
  });
});

module.exports = app;
