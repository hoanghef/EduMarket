'use strict';

const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const express = require('express');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');
const { requireAdmin, requireAuth } = require('./middleware/auth');

let server;
let baseUrl;
const createdUserIds = [];

function cookieJar(response) {
  return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; ');
}

async function jsonRequest(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, options);
  return { response, body: await response.json() };
}

async function csrf() {
  const { response, body } = await jsonRequest('/api/auth/csrf');
  assert.equal(response.status, 200);
  return { token: body.data.csrfToken, cookies: cookieJar(response) };
}

async function createUser(email, role = 'CUSTOMER') {
  const user = await prisma.user.create({
    data: { email, fullName: 'Integration Test User', role, passwordHash: await bcrypt.hash('CorrectPassword1!', 12) },
  });
  createdUserIds.push(user.id);
  return user;
}

test.before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  await prisma.auditLog.deleteMany({ where: { userId: { in: createdUserIds } } });
  await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } });
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  await prisma.$disconnect();
});

test('register succeeds, issues HttpOnly session, and me/logout enforce the session', async () => {
  const identifier = `register-${Date.now()}@example.test`;
  const csrfData = await csrf();
  const { response, body } = await jsonRequest('/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookies },
    body: JSON.stringify({ email: identifier, fullName: 'Registered User', password: 'CorrectPassword1!' }),
  });
  assert.equal(response.status, 201);
  assert.equal(body.data.user.role, 'CUSTOMER');
  const sessionCookie = response.headers.getSetCookie().find((cookie) => cookie.startsWith('edumarket_session='));
  assert.match(sessionCookie, /HttpOnly/);
  assert.match(sessionCookie, /SameSite=Lax/i);
  const authCookies = `${csrfData.cookies}; ${cookieJar(response)}`;
  const user = await prisma.user.findUnique({ where: { email: identifier } });
  createdUserIds.push(user.id);
  assert.equal(await bcrypt.compare('CorrectPassword1!', user.passwordHash), true);

  const me = await jsonRequest('/api/auth/me', { headers: { Cookie: authCookies } });
  assert.equal(me.response.status, 200);
  assert.equal(me.body.data.user.email, identifier);

  const logout = await jsonRequest('/api/auth/logout', { method: 'POST', headers: { 'X-CSRF-Token': csrfData.token, Cookie: authCookies } });
  assert.equal(logout.response.status, 200);
  const afterLogout = await jsonRequest('/api/auth/me', { headers: { Cookie: csrfData.cookies } });
  assert.equal(afterLogout.response.status, 401);
});

test('wrong password is rejected and logged', async () => {
  const user = await createUser(`wrong-password-${Date.now()}@example.test`);
  const csrfData = await csrf();
  const result = await jsonRequest('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookies },
    body: JSON.stringify({ email: user.email, password: 'WrongPassword1!' }),
  });
  assert.equal(result.response.status, 401);
  assert.equal(result.body.code, 'INVALID_CREDENTIALS');
  const updated = await prisma.user.findUnique({ where: { id: user.id } });
  assert.equal(updated.failedLoginAttempts, 1);
  assert.equal(await prisma.auditLog.count({ where: { userId: user.id, action: 'LOGIN_FAILED' } }), 1);
});

test('account locks after five failed login attempts', async () => {
  const user = await createUser(`lockout-${Date.now()}@example.test`);
  const csrfData = await csrf();
  let result;
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    result = await jsonRequest('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookies },
      body: JSON.stringify({ email: user.email, password: 'WrongPassword1!' }),
    });
    assert.equal(result.response.status, attempt === 5 ? 423 : 401);
  }
  assert.equal(result.body.code, 'ACCOUNT_LOCKED');
  const updated = await prisma.user.findUnique({ where: { id: user.id } });
  assert.equal(updated.failedLoginAttempts, 5);
  assert.ok(updated.lockedUntil > new Date());
});

test('customer session is denied by administrator middleware', async () => {
  const user = await createUser(`role-denial-${Date.now()}@example.test`);
  const csrfData = await csrf();
  const login = await jsonRequest('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookies },
    body: JSON.stringify({ email: user.email, password: 'CorrectPassword1!' }),
  });
  assert.equal(login.response.status, 200);

  const guardApp = express();
  guardApp.get('/admin-only', requireAuth, requireAdmin, (_req, res) => res.json({ success: true }));
  const guardServer = guardApp.listen(0);
  await new Promise((resolve) => guardServer.once('listening', resolve));
  try {
    const guardResponse = await fetch(`http://127.0.0.1:${guardServer.address().port}/admin-only`, {
      headers: { Cookie: `${csrfData.cookies}; ${cookieJar(login.response)}` },
    });
    const guardBody = await guardResponse.json();
    assert.equal(guardResponse.status, 403);
    assert.equal(guardBody.code, 'FORBIDDEN');
  } finally {
    await new Promise((resolve, reject) => guardServer.close((error) => (error ? reject(error) : resolve())));
  }
});

test('state-changing auth endpoint rejects a missing CSRF token', async () => {
  const result = await jsonRequest('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@edumarket.local', password: 'EduMarket@2026' }),
  });
  assert.equal(result.response.status, 403);
  assert.equal(result.body.code, 'CSRF_TOKEN_MISSING');
});
