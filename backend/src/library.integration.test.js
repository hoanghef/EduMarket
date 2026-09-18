'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');

let server; let baseUrl; let courseId; let lessonId; let fileId;
let paidOrderId; let revokedOrderId; let paidEntitlementId; let revokedEntitlementId;
const userIds = [];

function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function register(prefix) {
  const csrfData = await csrf();
  const result = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: `${prefix}-${Date.now()}@example.test`, fullName: 'Library Test Customer', password: 'CorrectPassword1!' }) });
  assert.equal(result.response.status, 201); userIds.push(result.body.data.user.id);
  return { id: result.body.data.user.id, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
async function loginAdmin() {
  const csrfData = await csrf();
  const result = await request('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: 'admin@edumarket.local', password: 'EduMarket@2026' }) });
  assert.equal(result.response.status, 200); return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
function headers(session) { return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie }; }
async function createPaidOrder(userId, suffix) {
  return prisma.order.create({ data: { orderNumber: `LIBRARY-${suffix}-${Date.now()}`, userId, status: 'PAID', subtotal: 100000, totalAmount: 100000, paidAt: new Date(), items: { create: { courseId, courseTitleSnapshot: 'Library test course', courseSlugSnapshot: `library-test-${suffix}`, unitPrice: 100000, discountedUnitPrice: 100000 } } } });
}

test.before(async () => {
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } });
  const suffix = Date.now().toString();
  const course = await prisma.course.create({ data: { categoryId: category.id, title: `Library test course ${suffix}`, slug: `library-test-${suffix}`, description: 'Protected library test course.', instructorName: 'Test Instructor', price: 100000, status: 'PUBLISHED', publishedAt: new Date(), lessons: { create: { title: 'Protected lesson', content: 'Only entitled customers can read this.', position: 1, durationSec: 60 } } } , include: { lessons: true } });
  courseId = course.id; lessonId = course.lessons[0].id;
  fileId = (await prisma.courseFile.create({ data: { courseId, lessonId, originalName: 'protected.pdf', storageKey: `private/library-test-${suffix}.pdf`, mimeType: 'application/pdf', sizeBytes: 1024 } })).id;
});

test.after(async () => {
  await prisma.courseProgress.deleteMany({ where: { courseId } });
  await prisma.courseEntitlement.deleteMany({ where: { courseId } });
  for (const orderId of [paidOrderId, revokedOrderId].filter(Boolean)) { await prisma.auditLog.deleteMany({ where: { entityId: orderId } }); await prisma.order.delete({ where: { id: orderId } }); }
  if (courseId) await prisma.course.delete({ where: { id: courseId } });
  for (const userId of userIds) { await prisma.auditLog.deleteMany({ where: { userId } }); await prisma.user.delete({ where: { id: userId } }); }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

test('library access is restricted to ACTIVE entitlements and lesson completion is idempotent', async () => {
  const paid = await register('library-paid');
  const unentitled = await register('library-unentitled');
  const revoked = await register('library-revoked');
  const paidOrder = await createPaidOrder(paid.id, 'paid'); paidOrderId = paidOrder.id;
  const revokedOrder = await createPaidOrder(revoked.id, 'revoked'); revokedOrderId = revokedOrder.id;
  paidEntitlementId = (await prisma.courseEntitlement.create({ data: { userId: paid.id, courseId, orderId: paidOrder.id, status: 'ACTIVE' } })).id;
  revokedEntitlementId = (await prisma.courseEntitlement.create({ data: { userId: revoked.id, courseId, orderId: revokedOrder.id, status: 'REVOKED', revokedAt: new Date(), revokeReason: 'Initial test revocation' } })).id;

  const list = await request('/api/library', { headers: { Cookie: paid.cookie } });
  assert.equal(list.response.status, 200); assert.equal(list.body.data.items.length, 1); assert.equal(list.body.data.items[0].course.id, courseId);
  const course = await request(`/api/library/courses/${courseId}`, { headers: { Cookie: paid.cookie } });
  assert.equal(course.response.status, 200); assert.equal(course.body.data.course.lessons[0].content, 'Only entitled customers can read this.');
  const lesson = await request(`/api/library/lessons/${lessonId}`, { headers: { Cookie: paid.cookie } });
  assert.equal(lesson.response.status, 200);
  const file = await request(`/api/library/files/${fileId}`, { headers: { Cookie: paid.cookie } });
  assert.equal(file.response.status, 200); assert.equal(Object.hasOwn(file.body.data.file, 'storageKey'), false);
  const firstComplete = await request(`/api/library/lessons/${lessonId}/complete`, { method: 'POST', headers: headers(paid) });
  const duplicateComplete = await request(`/api/library/lessons/${lessonId}/complete`, { method: 'POST', headers: headers(paid) });
  assert.equal(firstComplete.response.status, 201); assert.equal(firstComplete.body.data.created, true); assert.equal(duplicateComplete.response.status, 200); assert.equal(duplicateComplete.body.data.created, false);
  assert.equal(await prisma.courseProgress.count({ where: { userId: paid.id, lessonId } }), 1);

  for (const path of [`/api/library/courses/${courseId}`, `/api/library/lessons/${lessonId}`, `/api/library/files/${fileId}`]) {
    const result = await request(path, { headers: { Cookie: unentitled.cookie } });
    assert.equal(result.response.status, 403); assert.equal(result.body.code, 'COURSE_ACCESS_DENIED');
  }
  for (const path of [`/api/library/courses/${courseId}`, `/api/library/lessons/${lessonId}`, `/api/library/files/${fileId}`]) {
    const result = await request(path, { headers: { Cookie: revoked.cookie } });
    assert.equal(result.response.status, 403); assert.equal(result.body.code, 'COURSE_ACCESS_REVOKED');
  }
});

test('admin revoke and grant actions are audited and immediately change library access', async () => {
  const paidUserId = userIds[0];
  const paid = await loginAdmin();
  const customerCsrf = await csrf();
  const paidLogin = await request('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': customerCsrf.token, Cookie: customerCsrf.cookie }, body: JSON.stringify({ email: (await prisma.user.findUnique({ where: { id: paidUserId } })).email, password: 'CorrectPassword1!' }) });
  const paidSession = { csrfData: customerCsrf, cookie: `${customerCsrf.cookie}; ${cookies(paidLogin.response)}` };
  const revoke = await request(`/api/admin/entitlements/${paidEntitlementId}/revoke`, { method: 'PATCH', headers: headers(paid), body: JSON.stringify({ reason: 'Manual compliance review' }) });
  assert.equal(revoke.response.status, 200); assert.equal(revoke.body.data.entitlement.status, 'REVOKED');
  const denied = await request(`/api/library/courses/${courseId}`, { headers: { Cookie: paidSession.cookie } });
  assert.equal(denied.response.status, 403); assert.equal(denied.body.code, 'COURSE_ACCESS_REVOKED');
  assert.equal(await prisma.auditLog.count({ where: { userId: paidUserId, action: 'COURSE_ACCESS_REVOKED', entityId: paidEntitlementId } }), 1);

  const grant = await request('/api/admin/entitlements/grant', { method: 'POST', headers: headers(paid), body: JSON.stringify({ userId: paidUserId, courseId, orderId: paidOrderId }) });
  assert.equal(grant.response.status, 201); assert.equal(grant.body.data.entitlement.status, 'ACTIVE');
  const restored = await request(`/api/library/courses/${courseId}`, { headers: { Cookie: paidSession.cookie } });
  assert.equal(restored.response.status, 200);
  assert.equal(await prisma.auditLog.count({ where: { userId: paidUserId, action: 'COURSE_ACCESS_RESTORED', entityId: paidEntitlementId } }), 1);
});
