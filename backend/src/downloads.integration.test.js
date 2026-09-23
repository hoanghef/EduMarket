'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');
const { privateFilePath, removeStoredFile } = require('./services/file-storage-service');
const { tokenHash } = require('./services/download-service');

let server; let baseUrl; let courseId; let fileId; let orderId; let entitlementId; let uploadedStorageKey;
const users = [];
let directStorageKey;

function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(pathname, options = {}) { const response = await fetch(baseUrl + pathname, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function register(prefix) {
  const csrfData = await csrf();
  const result = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: `${prefix}-${Date.now()}@example.test`, fullName: 'Download Test Customer', password: 'CorrectPassword1!' }) });
  assert.equal(result.response.status, 201); users.push(result.body.data.user.id);
  return { id: result.body.data.user.id, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
async function adminLogin() {
  const csrfData = await csrf();
  const result = await request('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: 'admin@edumarket.local', password: 'EduMarket@2026' }) });
  assert.equal(result.response.status, 200); return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
function headers(session) { return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie }; }
async function createToken(session) {
  const result = await request(`/api/files/${fileId}/download-token`, { method: 'POST', headers: headers(session) });
  assert.equal(result.response.status, 201); return result.body.data;
}

test.before(async () => {
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } });
  const suffix = Date.now().toString();
  const course = await prisma.course.create({ data: { categoryId: category.id, title: `Download test course ${suffix}`, slug: `download-test-${suffix}`, description: 'Secure download test course.', instructorName: 'Test Instructor', price: 100000, status: 'PUBLISHED', publishedAt: new Date() } });
  courseId = course.id;
  directStorageKey = path.join('tests', `download-${suffix}.pdf`);
  const diskPath = privateFilePath(directStorageKey); fs.mkdirSync(path.dirname(diskPath), { recursive: true }); fs.writeFileSync(diskPath, 'private download fixture');
  fileId = (await prisma.courseFile.create({ data: { courseId, originalName: 'download-fixture.pdf', storageKey: directStorageKey, mimeType: 'application/pdf', sizeBytes: Buffer.byteLength('private download fixture') } })).id;
});

test.after(async () => {
  removeStoredFile(directStorageKey); if (uploadedStorageKey) removeStoredFile(uploadedStorageKey);
  await prisma.downloadToken.deleteMany({ where: { courseFileId: fileId } });
  await prisma.courseEntitlement.deleteMany({ where: { courseId } });
  if (orderId) await prisma.order.delete({ where: { id: orderId } });
  if (courseId) await prisma.course.delete({ where: { id: courseId } });
  for (const userId of users) { await prisma.auditLog.deleteMany({ where: { userId } }); await prisma.user.delete({ where: { id: userId } }); }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

test('download tokens are authenticated, hashed, valid once, and expire with 410', async () => {
  const entitled = await register('download-entitled');
  const other = await register('download-other');
  orderId = (await prisma.order.create({ data: { orderNumber: `DOWNLOAD-${Date.now()}`, userId: entitled.id, status: 'PAID', subtotal: 100000, totalAmount: 100000, paidAt: new Date(), items: { create: { courseId, courseTitleSnapshot: 'Download test course', courseSlugSnapshot: 'download-test', unitPrice: 100000, discountedUnitPrice: 100000 } } } })).id;
  entitlementId = (await prisma.courseEntitlement.create({ data: { userId: entitled.id, courseId, orderId, status: 'ACTIVE' } })).id;

  const csrfData = await csrf();
  const unauthenticated = await request(`/api/files/${fileId}/download-token`, { method: 'POST', headers: { 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie } });
  assert.equal(unauthenticated.response.status, 401);

  const created = await createToken(entitled);
  const rawToken = created.downloadUrl.split('/').pop();
  const stored = await prisma.downloadToken.findUnique({ where: { tokenHash: tokenHash(rawToken) } });
  assert.ok(stored); assert.notEqual(stored.tokenHash, rawToken); assert.equal(stored.tokenHash.length, 64); assert.equal(stored.maxDownloads, 1);
  assert.ok(new Date(stored.expiresAt).getTime() - Date.now() <= 10 * 60 * 1000);

  const forbiddenUser = await fetch(baseUrl + created.downloadUrl, { headers: { Cookie: other.cookie } });
  assert.equal(forbiddenUser.status, 403);
  const valid = await fetch(baseUrl + created.downloadUrl, { headers: { Cookie: entitled.cookie } });
  assert.equal(valid.status, 200); assert.equal(await valid.text(), 'private download fixture');
  const reused = await request(created.downloadUrl, { headers: { Cookie: entitled.cookie } });
  assert.equal(reused.response.status, 410); assert.equal(reused.body.code, 'DOWNLOAD_TOKEN_EXHAUSTED');
  assert.equal(await prisma.auditLog.count({ where: { userId: entitled.id, action: 'FILE_DOWNLOADED', entityId: fileId } }), 1);

  const expired = await createToken(entitled); const expiredToken = expired.downloadUrl.split('/').pop();
  await prisma.downloadToken.update({ where: { tokenHash: tokenHash(expiredToken) }, data: { expiresAt: new Date(Date.now() - 1000) } });
  const expiredResult = await request(expired.downloadUrl, { headers: { Cookie: entitled.cookie } });
  assert.equal(expiredResult.response.status, 410); assert.equal(expiredResult.body.code, 'DOWNLOAD_TOKEN_EXPIRED');

  const revoked = await createToken(entitled);
  await prisma.courseEntitlement.update({ where: { id: entitlementId }, data: { status: 'REVOKED', revokedAt: new Date(), revokeReason: 'Download test revocation' } });
  const revokedResult = await request(revoked.downloadUrl, { headers: { Cookie: entitled.cookie } });
  assert.equal(revokedResult.response.status, 403); assert.equal(revokedResult.body.code, 'COURSE_ACCESS_REVOKED');
});

test('admin uploads only allowlisted private files with server-generated storage keys', async () => {
  const admin = await adminLogin();
  const form = new FormData(); form.append('file', new Blob(['%PDF-1.4\nPDF fixture'], { type: 'application/pdf' }), 'lesson.pdf');
  const validUpload = await fetch(`${baseUrl}/api/admin/courses/${courseId}/files`, { method: 'POST', headers: { 'X-CSRF-Token': admin.csrfData.token, Cookie: admin.cookie }, body: form });
  const validBody = await validUpload.json(); assert.equal(validUpload.status, 201); uploadedStorageKey = validBody.data.file.storageKey;
  assert.equal(fs.existsSync(privateFilePath(uploadedStorageKey)), true); assert.notEqual(uploadedStorageKey, 'lesson.pdf');

  const invalidForm = new FormData(); invalidForm.append('file', new Blob(['not allowed'], { type: 'application/octet-stream' }), 'malware.exe');
  const invalidUpload = await fetch(`${baseUrl}/api/admin/courses/${courseId}/files`, { method: 'POST', headers: { 'X-CSRF-Token': admin.csrfData.token, Cookie: admin.cookie }, body: invalidForm });
  assert.equal(invalidUpload.status, 400);

  const disguisedForm = new FormData(); disguisedForm.append('file', new Blob(['not a PDF'], { type: 'application/pdf' }), 'disguised.pdf');
  const disguisedUpload = await fetch(`${baseUrl}/api/admin/courses/${courseId}/files`, { method: 'POST', headers: { 'X-CSRF-Token': admin.csrfData.token, Cookie: admin.cookie }, body: disguisedForm });
  assert.equal(disguisedUpload.status, 400);
  assert.equal((await disguisedUpload.json()).code, 'INVALID_FILE_CONTENT');
});
