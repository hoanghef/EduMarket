'use strict';

const prisma = require('../lib/prisma');
const { AUTH_COOKIE_NAME, parseCookies, verifySessionValue } = require('../lib/auth');

async function requireAuth(req, res, next) {
  try {
    const session = verifySessionValue(parseCookies(req.headers.cookie)[AUTH_COOKIE_NAME]);
    if (!session) return res.status(401).json({ success: false, code: 'UNAUTHENTICATED', message: 'Authentication is required.' });

    const user = await prisma.user.findUnique({
      where: { id: session.userId },
      select: { id: true, email: true, fullName: true, role: true, isActive: true },
    });
    if (!user || !user.isActive) return res.status(401).json({ success: false, code: 'UNAUTHENTICATED', message: 'Authentication is required.' });

    req.user = user;
    return next();
  } catch (error) {
    return next(error);
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== 'ADMIN') {
    return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Administrator access is required.' });
  }
  return next();
}

function requireCustomer(req, res, next) {
  if (req.user?.role !== 'CUSTOMER') {
    return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Customer access is required.' });
  }
  return next();
}

module.exports = { requireAdmin, requireAuth, requireCustomer };
