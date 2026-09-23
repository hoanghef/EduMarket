'use strict';

const bcrypt = require('bcrypt');
const rateLimit = require('express-rate-limit');
const { Router } = require('express');
const prisma = require('../lib/prisma');
const { clearSessionCookie, issueCsrfToken, issueSessionCookie } = require('../lib/auth');
const { requireAuth } = require('../middleware/auth');

const router = Router();
const LOCKOUT_MS = 15 * 60 * 1000;
const PASSWORD_ROUNDS = 12;

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, code: 'LOGIN_RATE_LIMIT', message: 'Too many login attempts. Please try again later.' },
});

function getClientIp(req) {
  return req.ip || req.socket.remoteAddress || null;
}

function publicUser(user) {
  return { id: user.id, email: user.email, fullName: user.fullName, role: user.role };
}

function validateCredentials(body, requireName = false) {
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : '';
  const password = typeof body?.password === 'string' ? body.password : '';
  const fullName = typeof body?.fullName === 'string' ? body.fullName.trim() : '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 8 || password.length > 128 || (requireName && (fullName.length < 2 || fullName.length > 120))) {
    return null;
  }
  return { email, password, fullName };
}

async function audit(userId, action, req, metadata = {}) {
  await prisma.auditLog.create({
    data: { userId, action, entityType: 'User', entityId: userId || null, ipAddress: getClientIp(req), metadata },
  });
}

router.get('/csrf', (_req, res) => {
  const csrfToken = issueCsrfToken(res);
  res.json({ success: true, data: { csrfToken } });
});

router.post('/register', async (req, res, next) => {
  try {
    const credentials = validateCredentials(req.body, true);
    if (!credentials) return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Invalid registration data.' });

    const existing = await prisma.user.findUnique({ where: { email: credentials.email }, select: { id: true } });
    if (existing) return res.status(409).json({ success: false, code: 'EMAIL_IN_USE', message: 'Email is already registered.' });

    const passwordHash = await bcrypt.hash(credentials.password, PASSWORD_ROUNDS);
    const user = await prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: { email: credentials.email, fullName: credentials.fullName, passwordHash },
      });
      await tx.cart.create({ data: { userId: createdUser.id } });
      await tx.auditLog.create({
        data: { userId: createdUser.id, action: 'REGISTER', entityType: 'User', entityId: createdUser.id, ipAddress: getClientIp(req) },
      });
      return createdUser;
    });

    issueSessionCookie(res, user.id, user.sessionVersion);
    return res.status(201).json({ success: true, data: { user: publicUser(user) } });
  } catch (error) {
    if (error.code === 'P2002') return res.status(409).json({ success: false, code: 'EMAIL_IN_USE', message: 'Email is already registered.' });
    return next(error);
  }
});

router.post('/login', loginLimiter, async (req, res, next) => {
  try {
    const credentials = validateCredentials(req.body);
    if (!credentials) return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Invalid email or password.' });

    const user = await prisma.user.findUnique({ where: { email: credentials.email } });
    if (!user) {
      await audit(null, 'LOGIN_FAILED', req, { email: credentials.email, reason: 'INVALID_CREDENTIALS' });
      return res.status(401).json({ success: false, code: 'INVALID_CREDENTIALS', message: 'Invalid email or password.' });
    }
    if (!user.isActive) {
      await audit(user.id, 'LOGIN_FAILED', req, { reason: 'ACCOUNT_DISABLED' });
      return res.status(403).json({ success: false, code: 'ACCOUNT_DISABLED', message: 'Account is disabled.' });
    }
    if (user.lockedUntil && user.lockedUntil > new Date()) {
      await audit(user.id, 'LOGIN_FAILED', req, { reason: 'ACCOUNT_LOCKED' });
      return res.status(423).json({ success: false, code: 'ACCOUNT_LOCKED', message: 'Account is temporarily locked.' });
    }

    const passwordMatches = await bcrypt.compare(credentials.password, user.passwordHash);
    if (!passwordMatches) {
      const failedLoginAttempts = user.failedLoginAttempts + 1;
      const lockedUntil = failedLoginAttempts >= 5 ? new Date(Date.now() + LOCKOUT_MS) : null;
      await prisma.user.update({ where: { id: user.id }, data: { failedLoginAttempts, lockedUntil } });
      await audit(user.id, 'LOGIN_FAILED', req, { reason: 'INVALID_CREDENTIALS', failedLoginAttempts });
      const status = lockedUntil ? 423 : 401;
      return res.status(status).json({ success: false, code: lockedUntil ? 'ACCOUNT_LOCKED' : 'INVALID_CREDENTIALS', message: lockedUntil ? 'Account is temporarily locked.' : 'Invalid email or password.' });
    }

    const authenticatedUser = await prisma.user.update({
      where: { id: user.id },
      data: { failedLoginAttempts: 0, lockedUntil: null },
    });
    await audit(user.id, 'LOGIN_SUCCESS', req);
    issueSessionCookie(res, user.id, authenticatedUser.sessionVersion);
    return res.json({ success: true, data: { user: publicUser(authenticatedUser) } });
  } catch (error) {
    return next(error);
  }
});

router.post('/logout', requireAuth, async (req, res, next) => {
  try {
    await prisma.user.update({ where: { id: req.user.id }, data: { sessionVersion: { increment: 1 } } });
    await audit(req.user.id, 'LOGOUT', req, { allSessionsInvalidated: true });
    clearSessionCookie(res);
    return res.json({ success: true, data: { message: 'Logged out.' } });
  } catch (error) {
    return next(error);
  }
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ success: true, data: { user: publicUser(req.user) } });
});

module.exports = router;
