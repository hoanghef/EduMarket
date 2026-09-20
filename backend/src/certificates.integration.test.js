'use strict';

const assert = require('node:assert/strict');
const fs = require('fs');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');
const { privateFilePath, removeStoredFile } = require('./services/file-storage-service');

let server; let baseUrl; let courseId; let optionalLessonId; let requiredLessonOneId; let requiredLessonTwoId;
const userIds = []; const orderIds = [];

function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function download(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: Buffer.from(await response.arrayBuffer()) }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function register(prefix, fullName) {
  const csrfData = await csrf();
  const result = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}@example.test`, fullName, password: 'CorrectPassword1!' }) });
  assert.equal(result.response.status, 201); userIds.push(result.body.data.user.id);
  return { id: result.body.data.user.id, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
function headers(session) { return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie }; }
async function grantPaidAccess(userId, suffix) {
  const order = await prisma.order.create({ data: { orderNumber: `CERT-${suffix}-${Date.now()}-${Math.random().toString(16).slice(2)}`, userId, status: 'PAID', subtotal: 100000, totalAmount: 100000, paidAt: new Date(), items: { create: { courseId, courseTitleSnapshot: 'Certificate test course', courseSlugSnapshot: `certificate-test-${suffix}`, unitPrice: 100000, discountedUnitPrice: 100000 } } } });
  orderIds.push(order.id);
  await prisma.courseEntitlement.create({ data: { userId, courseId, orderId: order.id, status: 'ACTIVE' } });
}

test.before(async () => {
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } });
  const suffix = Date.now().toString();
  const course = await prisma.course.create({ data: { categoryId: category.id, title: `Certificate test course ${suffix}`, slug: `certificate-test-${suffix}`, description: 'Certificate progress test course.', instructorName: 'Test Instructor', price: 100000, status: 'PUBLISHED', publishedAt: new Date(), lessons: { create: [
    { title: 'Optional lesson', position: 1, durationSec: 60, isRequired: false },
    { title: 'Required lesson one', position: 2, durationSec: 60, isRequired: true },
    { title: 'Required lesson two', position: 3, durationSec: 60, isRequired: true },
  ] } }, include: { lessons: { orderBy: { position: 'asc' } } } });
  courseId = course.id; [optionalLessonId, requiredLessonOneId, requiredLessonTwoId] = course.lessons.map((lesson) => lesson.id);
});

test.after(async () => {
  const certificates = await prisma.certificate.findMany({ where: { courseId }, select: { pdfStorageKey: true } });
  await prisma.courseProgress.deleteMany({ where: { courseId } });
  await prisma.certificate.deleteMany({ where: { courseId } });
  for (const certificate of certificates) if (certificate.pdfStorageKey) removeStoredFile(certificate.pdfStorageKey);
  await prisma.courseEntitlement.deleteMany({ where: { courseId } });
  for (const orderId of orderIds) { await prisma.auditLog.deleteMany({ where: { entityId: orderId } }); await prisma.order.delete({ where: { id: orderId } }); }
  if (courseId) await prisma.course.delete({ where: { id: courseId } });
  for (const userId of userIds) { await prisma.auditLog.deleteMany({ where: { userId } }); await prisma.user.delete({ where: { id: userId } }); }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

test('required-lesson progress creates one valid certificate and public verification exposes only safe data', async () => {
  const anonymousCsrf = await csrf();
  const unauthenticated = await request(`/api/library/lessons/${requiredLessonOneId}/complete`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': anonymousCsrf.token, Cookie: anonymousCsrf.cookie } });
  assert.equal(unauthenticated.response.status, 401);

  const student = await register('certificate-primary', 'Nguyễn Văn Chứng Nhận');
  await grantPaidAccess(student.id, 'primary');
  const optional = await request(`/api/library/lessons/${optionalLessonId}/complete`, { method: 'POST', headers: headers(student) });
  assert.equal(optional.response.status, 201); assert.deepEqual(optional.body.data.progress, { totalRequiredLessons: 2, completedRequiredLessons: 0, percentage: 0, isComplete: false }); assert.equal(optional.body.data.certificate, null);

  const halfway = await request(`/api/library/lessons/${requiredLessonOneId}/complete`, { method: 'POST', headers: headers(student) });
  assert.equal(halfway.response.status, 201); assert.deepEqual(halfway.body.data.progress, { totalRequiredLessons: 2, completedRequiredLessons: 1, percentage: 50, isComplete: false });
  assert.equal(await prisma.certificate.count({ where: { userId: student.id, courseId } }), 0);

  const complete = await request(`/api/library/lessons/${requiredLessonTwoId}/complete`, { method: 'POST', headers: headers(student) });
  assert.equal(complete.response.status, 201); assert.deepEqual(complete.body.data.progress, { totalRequiredLessons: 2, completedRequiredLessons: 2, percentage: 100, isComplete: true }); assert.equal(complete.body.data.certificateCreated, true);
  const certificate = complete.body.data.certificate;
  assert.match(certificate.certificateCode, /^EDU-\d{4}-[A-F0-9]{24}$/);
  assert.ok(certificate.pdfStorageKey);
  const pdf = fs.readFileSync(privateFilePath(certificate.pdfStorageKey));
  assert.equal(pdf.subarray(0, 5).toString('ascii'), '%PDF-'); assert.ok(pdf.length > 500);
  assert.equal(await prisma.certificate.count({ where: { userId: student.id, courseId } }), 1);

  const ownerList = await request('/api/certificates', { headers: { Cookie: student.cookie } });
  assert.equal(ownerList.response.status, 200); assert.equal(ownerList.body.data.items.length, 1);
  assert.deepEqual(Object.keys(ownerList.body.data.items[0]).sort(), ['certificateCode', 'courseTitle', 'issuedAt', 'verification']);
  assert.equal(ownerList.body.data.items[0].certificateCode, certificate.certificateCode); assert.equal(Object.hasOwn(ownerList.body.data.items[0], 'pdfStorageKey'), false);
  const ownerPdf = await download(`/api/certificates/${certificate.certificateCode}/pdf`, { headers: { Cookie: student.cookie } });
  assert.equal(ownerPdf.response.status, 200); assert.match(ownerPdf.response.headers.get('content-type'), /^application\/pdf/); assert.equal(ownerPdf.body.subarray(0, 5).toString('ascii'), '%PDF-');
  const unauthenticatedPdf = await request(`/api/certificates/${certificate.certificateCode}/pdf`);
  assert.equal(unauthenticatedPdf.response.status, 401);

  const duplicate = await request(`/api/library/lessons/${requiredLessonTwoId}/complete`, { method: 'POST', headers: headers(student) });
  assert.equal(duplicate.response.status, 200); assert.equal(duplicate.body.data.created, false); assert.equal(duplicate.body.data.certificateCreated, false); assert.equal(duplicate.body.data.certificate.certificateCode, certificate.certificateCode);
  assert.equal(await prisma.certificate.count({ where: { userId: student.id, courseId } }), 1);

  const verification = await request(`/api/certificates/${certificate.certificateCode}/verify`);
  assert.equal(verification.response.status, 200); assert.deepEqual(Object.keys(verification.body.data).sort(), ['certificateCode', 'courseName', 'issuedAt', 'studentName', 'verified']); assert.equal(verification.body.data.verified, true); assert.equal(verification.body.data.certificateCode, certificate.certificateCode); assert.equal(verification.body.data.studentName, 'Nguyễn Văn Chứng Nhận');
  const malformed = await request('/api/certificates/not-a-certificate/verify');
  assert.equal(malformed.response.status, 400); assert.equal(malformed.body.code, 'INVALID_CERTIFICATE_CODE');
  const unknown = await request('/api/certificates/EDU-2026-AAAAAAAAAAAAAAAAAAAAAAAA/verify');
  assert.equal(unknown.response.status, 404); assert.equal(unknown.body.code, 'CERTIFICATE_NOT_FOUND');

  const secondStudent = await register('certificate-secondary', 'Trần Thị Hoàn Thành');
  await grantPaidAccess(secondStudent.id, 'secondary');
  await request(`/api/library/lessons/${requiredLessonOneId}/complete`, { method: 'POST', headers: headers(secondStudent) });
  const secondComplete = await request(`/api/library/lessons/${requiredLessonTwoId}/complete`, { method: 'POST', headers: headers(secondStudent) });
  assert.equal(secondComplete.response.status, 201); assert.notEqual(secondComplete.body.data.certificate.certificateCode, certificate.certificateCode);
  assert.equal(await prisma.certificate.count({ where: { courseId } }), 2);
  const secondList = await request('/api/certificates', { headers: { Cookie: secondStudent.cookie } });
  assert.equal(secondList.response.status, 200); assert.equal(secondList.body.data.items.length, 1); assert.equal(secondList.body.data.items[0].certificateCode, secondComplete.body.data.certificate.certificateCode);
  const idor = await request(`/api/certificates/${certificate.certificateCode}/pdf`, { headers: { Cookie: secondStudent.cookie } });
  assert.equal(idor.response.status, 404); assert.equal(idor.body.code, 'CERTIFICATE_NOT_FOUND');
  const missingPdf = await request('/api/certificates/EDU-2026-AAAAAAAAAAAAAAAAAAAAAAAA/pdf', { headers: { Cookie: student.cookie } });
  assert.equal(missingPdf.response.status, 404); assert.equal(missingPdf.body.code, 'CERTIFICATE_NOT_FOUND');
});
