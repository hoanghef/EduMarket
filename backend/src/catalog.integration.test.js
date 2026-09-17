'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');

let server; let baseUrl; let categoryId; let courseId;
function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function login(email, password) { const csrfData = await csrf(); const result = await request('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email, password }) }); return { csrfData, cookie: csrfData.cookie + '; ' + cookies(result.response), result }; }

test.before(async () => { server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = 'http://127.0.0.1:' + server.address().port; });
test.after(async () => { if (courseId) await prisma.course.delete({ where: { id: courseId } }); if (categoryId) await prisma.category.delete({ where: { id: categoryId } }); await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve())); await prisma.$disconnect(); });

test('admin can create catalog content and public filters return the published course', async () => {
  const admin = await login('admin@edumarket.local', 'EduMarket@2026'); assert.equal(admin.result.response.status, 200);
  const suffix = Date.now().toString();
  const category = await request('/api/admin/categories', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': admin.csrfData.token, Cookie: admin.cookie }, body: JSON.stringify({ name: 'API Test ' + suffix, slug: 'api-test-' + suffix }) });
  assert.equal(category.response.status, 201); categoryId = category.body.data.category.id;
  const course = await request('/api/admin/courses', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': admin.csrfData.token, Cookie: admin.cookie }, body: JSON.stringify({ title: 'Catalog Filter ' + suffix, slug: 'catalog-filter-' + suffix, categoryId, description: 'Course created for catalog integration testing.', instructorName: 'API Instructor', price: 100000, salePrice: 50000, level: 'BEGINNER', status: 'PUBLISHED', ratingAverage: 0, enrollmentCount: 99999 }) });
  assert.equal(course.response.status, 201); courseId = course.body.data.course.id; assert.equal(course.body.data.course.enrollmentCount, 0);
  const filtered = await request('/api/courses?q=Catalog%20Filter%20' + suffix + '&category=api-test-' + suffix + '&minPrice=90000&maxPrice=110000&level=BEGINNER&rating=0&instructor=API%20Instructor&sort=popularity&page=1&limit=5');
  assert.equal(filtered.response.status, 200); assert.equal(filtered.body.data.items.some((item) => item.id === courseId), true);
  const recommendations = await request('/api/courses/' + courseId + '/recommendations'); assert.equal(recommendations.response.status, 200);
});
test('unknown published-course slug returns 404', async () => { const result = await request('/api/courses/does-not-exist'); assert.equal(result.response.status, 404); assert.equal(result.body.code, 'COURSE_NOT_FOUND'); });
test('customer is denied admin category creation', async () => {
  const csrfData = await csrf(); const email = 'catalog-customer-' + Date.now() + '@example.test';
  const register = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email, fullName: 'Catalog Customer', password: 'CorrectPassword1!' }) });
  const denied = await request('/api/admin/categories', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie + '; ' + cookies(register.response) }, body: JSON.stringify({ name: 'Denied', slug: 'denied-' + Date.now() }) });
  assert.equal(denied.response.status, 403); assert.equal(denied.body.code, 'FORBIDDEN');
  const user = await prisma.user.findUnique({ where: { email } }); await prisma.auditLog.deleteMany({ where: { userId: user.id } }); await prisma.user.delete({ where: { id: user.id } });
});
