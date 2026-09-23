'use strict';

const crypto = require('crypto');

const AUTH_COOKIE_NAME = 'edumarket_session';
const CSRF_COOKIE_NAME = 'edumarket_csrf';
const SESSION_TTL_MS = 8 * 60 * 60 * 1000;

function cookieOptions(httpOnly) {
  const configuredSameSite = (process.env.COOKIE_SAME_SITE || 'Lax').toLowerCase();
  const sameSite = ['lax', 'strict', 'none'].includes(configuredSameSite) ? configuredSameSite : 'lax';
  return {
    httpOnly,
    // Production cookies must never be sent over plaintext HTTP. COOKIE_SECURE
    // can additionally enable this in a staging environment.
    secure: process.env.NODE_ENV === 'production' || process.env.COOKIE_SECURE === 'true',
    sameSite,
    path: '/',
  };
}

function getSessionSecret() {
  const secret = process.env.SESSION_SECRET;
  if (!secret || secret.startsWith('CHANGE_ME')) {
    throw new Error('SESSION_SECRET must be configured before authentication can be used.');
  }
  return secret;
}

function sign(value) {
  return crypto.createHmac('sha256', getSessionSecret()).update(value).digest('base64url');
}

function createSessionValue(userId, sessionVersion = 0) {
  const payload = Buffer.from(JSON.stringify({ userId, sessionVersion, exp: Date.now() + SESSION_TTL_MS })).toString('base64url');
  return `${payload}.${sign(payload)}`;
}

function parseCookies(header = '') {
  return header.split(';').reduce((cookies, part) => {
    const index = part.indexOf('=');
    if (index === -1) return cookies;
    try {
      cookies[part.slice(0, index).trim()] = decodeURIComponent(part.slice(index + 1).trim());
    } catch {
      // A malformed Cookie header is treated as absent authentication rather
      // than allowing a bad percent-encoding to reach the error handler.
    }
    return cookies;
  }, {});
}

function verifySessionValue(value) {
  if (!value || !value.includes('.')) return null;
  const [payload, signature] = value.split('.');
  const expected = sign(payload);
  const actualBuffer = Buffer.from(signature);
  const expectedBuffer = Buffer.from(expected);
  if (actualBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(actualBuffer, expectedBuffer)) return null;

  try {
    const session = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    return typeof session.userId === 'string' && Number.isInteger(session.sessionVersion) && Number.isFinite(session.exp) && session.exp > Date.now() ? session : null;
  } catch {
    return null;
  }
}

function issueSessionCookie(res, userId, sessionVersion = 0) {
  res.cookie(AUTH_COOKIE_NAME, createSessionValue(userId, sessionVersion), {
    ...cookieOptions(true),
    maxAge: SESSION_TTL_MS,
  });
}

function clearSessionCookie(res) {
  res.clearCookie(AUTH_COOKIE_NAME, cookieOptions(true));
}

function issueCsrfToken(res) {
  const token = crypto.randomBytes(32).toString('base64url');
  res.cookie(CSRF_COOKIE_NAME, token, {
    ...cookieOptions(false),
    maxAge: SESSION_TTL_MS,
  });
  return token;
}

function csrfProtection(req, res, next) {
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) return next();
  const cookies = parseCookies(req.headers.cookie);
  const token = req.get('X-CSRF-Token');
  const cookieToken = cookies[CSRF_COOKIE_NAME];
  if (!token || !cookieToken) {
    return res.status(403).json({ success: false, code: 'CSRF_TOKEN_MISSING', message: 'CSRF token is required.' });
  }
  const tokenBuffer = Buffer.from(token);
  const cookieBuffer = Buffer.from(cookieToken);
  if (tokenBuffer.length !== cookieBuffer.length || !crypto.timingSafeEqual(tokenBuffer, cookieBuffer)) {
    return res.status(403).json({ success: false, code: 'CSRF_TOKEN_INVALID', message: 'CSRF token is invalid.' });
  }
  return next();
}

module.exports = {
  AUTH_COOKIE_NAME,
  CSRF_COOKIE_NAME,
  cookieOptions,
  clearSessionCookie,
  csrfProtection,
  issueCsrfToken,
  issueSessionCookie,
  parseCookies,
  verifySessionValue,
};
