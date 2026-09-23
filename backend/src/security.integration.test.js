'use strict';

const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const test = require('node:test');
const app = require('./app');
const { cookieOptions } = require('./lib/auth');
const { privateFilePath } = require('./services/file-storage-service');

let server;
let baseUrl;

test.before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
});

test('production cookies are always Secure and restrict SameSite to supported values', () => {
  const previousEnvironment = process.env.NODE_ENV;
  const previousSecure = process.env.COOKIE_SECURE;
  const previousSameSite = process.env.COOKIE_SAME_SITE;
  try {
    process.env.NODE_ENV = 'production';
    process.env.COOKIE_SECURE = 'false';
    process.env.COOKIE_SAME_SITE = 'unsupported-value';
    const options = cookieOptions(true);
    assert.equal(options.secure, true);
    assert.equal(options.sameSite, 'lax');
  } finally {
    process.env.NODE_ENV = previousEnvironment;
    process.env.COOKIE_SECURE = previousSecure;
    process.env.COOKIE_SAME_SITE = previousSameSite;
  }
});

test('production startup requires an explicit CORS allow-list', () => {
  assert.throws(() => execFileSync(process.execPath, ['-e', 'require("./app")'], {
    cwd: __dirname,
    env: { ...process.env, NODE_ENV: 'production', CORS_ORIGINS: '' },
    stdio: 'pipe',
  }), /CORS_ORIGINS must be configured in production/);
});

test('policy content is public, read-only, and marked for production legal review', async () => {
  const list = await fetch(`${baseUrl}/api/policies`);
  assert.equal(list.status, 200);
  const listBody = await list.json();
  assert.equal(listBody.success, true);
  assert.ok(listBody.data.items.some((item) => item.slug === 'privacy'));
  const privacy = await fetch(`${baseUrl}/api/policies/privacy`);
  const privacyBody = await privacy.json();
  assert.equal(privacy.status, 200);
  assert.equal(privacyBody.data.legalNotice, 'Implementation present; production legal review required.');
  const unknown = await fetch(`${baseUrl}/api/policies/unknown`);
  assert.equal(unknown.status, 404);
});

test('browser security headers, CORS allow-list, and private path traversal defenses are active', async () => {
  const allowed = await fetch(`${baseUrl}/api/health`, { headers: { Origin: 'http://localhost:3000' } });
  assert.equal(allowed.headers.get('access-control-allow-origin'), 'http://localhost:3000');
  assert.match(allowed.headers.get('content-security-policy') || '', /frame-ancestors 'none'/);
  assert.equal(allowed.headers.get('x-frame-options'), 'DENY');
  assert.equal(allowed.headers.get('x-content-type-options'), 'nosniff');
  assert.ok(allowed.headers.get('referrer-policy'));

  const rejected = await fetch(`${baseUrl}/api/health`, { headers: { Origin: 'https://attacker.invalid' } });
  assert.equal(rejected.headers.get('access-control-allow-origin'), null);
  assert.throws(() => privateFilePath('../outside-private-storage'), { code: 'FILE_NOT_FOUND' });
});
