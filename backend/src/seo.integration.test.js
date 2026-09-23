'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');

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

test('GET /robots.txt returns 200, valid text format, disallows private routes and references sitemap', async () => {
  const res = await fetch(`${baseUrl}/robots.txt`);
  assert.equal(res.status, 200);
  assert.ok(res.headers.get('content-type').includes('text/plain'));
  const text = await res.text();

  assert.ok(text.includes('User-agent: *'));
  assert.ok(text.includes('Allow: /'));
  assert.ok(text.includes('Allow: /khoa-hoc'));
  assert.ok(text.includes('Allow: /chinh-sach/*'));
  assert.ok(text.includes('Allow: /khuyen-mai'));
  assert.ok(text.includes('Disallow: /admin'));
  assert.ok(text.includes('Disallow: /checkout'));
  assert.ok(text.includes('Disallow: /cart'));
  assert.ok(text.includes('Disallow: /library'));
  assert.ok(text.includes('Disallow: /api/'));
  assert.ok(text.includes('Sitemap: '));
  assert.ok(text.includes('/sitemap.xml'));
});

test('GET /sitemap.xml returns 200, valid XML, includes published courses and excludes private routes', async () => {
  const res = await fetch(`${baseUrl}/sitemap.xml`);
  assert.equal(res.status, 200);
  assert.ok(res.headers.get('content-type').includes('application/xml'));
  const xml = await res.text();

  assert.ok(xml.startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
  assert.ok(xml.includes('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'));
  assert.ok(xml.includes('</urlset>'));

  // Includes home, catalog, promotions, policies, verify
  assert.ok(xml.includes('/khoa-hoc</loc>'));
  assert.ok(xml.includes('/khuyen-mai</loc>'));
  assert.ok(xml.includes('/certificates/verify</loc>'));
  assert.ok(xml.includes('/chinh-sach/business</loc>'));
  assert.ok(xml.includes('/chinh-sach/privacy</loc>'));

  // Excludes sensitive / authenticated routes
  assert.ok(!xml.includes('/admin'));
  assert.ok(!xml.includes('/cart'));
  assert.ok(!xml.includes('/checkout'));
  assert.ok(!xml.includes('/account'));
  assert.ok(!xml.includes('/library'));
  assert.ok(!xml.includes('/api/'));
});
