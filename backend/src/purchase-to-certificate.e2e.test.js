'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');
const { privateFilePath, removeStoredFile } = require('./services/file-storage-service');

let server;
let baseUrl;
let courseId;
let orderId;
let customerId;

function cookies(response) {
  return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; ');
}

async function request(path, options = {}) {
  const response = await fetch(baseUrl + path, options);
  return { response, body: response.status === 204 ? null : await response.json() };
}

async function csrf() {
  const result = await request('/api/auth/csrf');
  return { token: result.body.data.csrfToken, cookie: cookies(result.response) };
}

function headers(session) {
  return {
    'Content-Type': 'application/json',
    'X-CSRF-Token': session.csrfData.token,
    Cookie: session.cookie,
  };
}

async function registerCustomer() {
  const csrfData = await csrf();
  const email = `e2e-customer-${Date.now()}-${Math.random().toString(16).slice(2)}@example.test`;
  const result = await request('/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie },
    body: JSON.stringify({
      email,
      fullName: 'E2E Purchase Student',
      password: 'CorrectPassword1!',
    }),
  });
  assert.equal(result.response.status, 201);
  customerId = result.body.data.user.id;
  return { email, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}

async function loginCustomer(email) {
  const csrfData = await csrf();
  const result = await request('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie },
    body: JSON.stringify({ email, password: 'CorrectPassword1!' }),
  });
  assert.equal(result.response.status, 200);
  return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}

async function loginAdmin() {
  const csrfData = await csrf();
  const result = await request('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie },
    body: JSON.stringify({ email: 'admin@edumarket.local', password: 'EduMarket@2026' }),
  });
  assert.equal(result.response.status, 200);
  return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}

test.before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;

  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } });
  assert.ok(category, 'seeded active category is required for this E2E test');
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const course = await prisma.course.create({
    data: {
      categoryId: category.id,
      title: `E2E purchase course ${suffix}`,
      slug: `e2e-purchase-${suffix}`,
      description: 'Course used only by the purchase-to-certificate end-to-end test.',
      instructorName: 'E2E Instructor',
      price: 120000,
      salePrice: 90000,
      status: 'PUBLISHED',
      publishedAt: new Date(),
      lessons: {
        create: [
          { title: 'Required lesson one', position: 1, durationSec: 60, isRequired: true },
          { title: 'Required lesson two', position: 2, durationSec: 60, isRequired: true },
        ],
      },
    },
    include: { lessons: { orderBy: { position: 'asc' } } },
  });
  courseId = course.id;
});

test.after(async () => {
  const certificates = courseId
    ? await prisma.certificate.findMany({ where: { courseId }, select: { pdfStorageKey: true } })
    : [];
  if (courseId) await prisma.courseProgress.deleteMany({ where: { courseId } });
  if (courseId) await prisma.certificate.deleteMany({ where: { courseId } });
  for (const certificate of certificates) if (certificate.pdfStorageKey) removeStoredFile(certificate.pdfStorageKey);
  if (courseId) await prisma.courseEntitlement.deleteMany({ where: { courseId } });
  if (orderId) await prisma.auditLog.deleteMany({ where: { entityId: orderId } });
  if (orderId) await prisma.order.delete({ where: { id: orderId } });
  if (courseId) await prisma.course.delete({ where: { id: courseId } });
  if (customerId) {
    await prisma.auditLog.deleteMany({ where: { userId: customerId } });
    await prisma.user.delete({ where: { id: customerId } });
  }
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  await prisma.$disconnect();
});

test('customer purchase-to-certificate journey works end to end through real HTTP routes', async () => {
  const registeredCustomer = await registerCustomer();
  const customer = await loginCustomer(registeredCustomer.email);

  const catalog = await request('/api/courses?search=E2E%20purchase');
  assert.equal(catalog.response.status, 200);
  assert.equal(catalog.body.data.items.some((course) => course.id === courseId), true);
  const course = catalog.body.data.items.find((item) => item.id === courseId);
  const detail = await request(`/api/courses/${course.slug}`);
  assert.equal(detail.response.status, 200);
  assert.equal(detail.body.data.course.id, courseId);

  const addToCart = await request('/api/cart/items', {
    method: 'POST', headers: headers(customer), body: JSON.stringify({ courseId }),
  });
  assert.equal(addToCart.response.status, 201);

  const checkout = await request('/api/checkout', {
    method: 'POST',
    headers: headers(customer),
    body: JSON.stringify({ method: 'COD', totalAmount: 1, discountAmount: 999999 }),
  });
  assert.equal(checkout.response.status, 201);
  orderId = checkout.body.data.order.id;
  assert.equal(checkout.body.data.order.status, 'WAITING_CONFIRMATION');
  assert.equal(String(checkout.body.data.order.totalAmount), '90000');
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customerId, courseId } }), 0);

  const admin = await loginAdmin();
  const confirmation = await request(`/api/admin/orders/${orderId}/cod-confirm`, {
    method: 'PATCH', headers: headers(admin),
  });
  assert.equal(confirmation.response.status, 200);
  assert.equal(confirmation.body.data.order.status, 'PAID');
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customerId, courseId, status: 'ACTIVE' } }), 1);

  const library = await request('/api/library', { headers: { Cookie: customer.cookie } });
  assert.equal(library.response.status, 200);
  assert.equal(library.body.data.items.some((item) => item.course.id === courseId), true);
  const libraryCourse = await request(`/api/library/courses/${courseId}`, { headers: { Cookie: customer.cookie } });
  assert.equal(libraryCourse.response.status, 200);
  assert.equal(libraryCourse.body.data.course.lessons.length, 2);

  const [firstLesson, secondLesson] = libraryCourse.body.data.course.lessons;
  const firstCompletion = await request(`/api/library/lessons/${firstLesson.id}/complete`, {
    method: 'POST', headers: headers(customer),
  });
  assert.equal(firstCompletion.response.status, 201);
  assert.equal(firstCompletion.body.data.progress.percentage, 50);
  assert.equal(firstCompletion.body.data.certificate, null);

  const secondCompletion = await request(`/api/library/lessons/${secondLesson.id}/complete`, {
    method: 'POST', headers: headers(customer),
  });
  assert.equal(secondCompletion.response.status, 201);
  assert.equal(secondCompletion.body.data.progress.percentage, 100);
  assert.equal(secondCompletion.body.data.certificateCreated, true);
  const certificateCode = secondCompletion.body.data.certificate.certificateCode;
  assert.match(certificateCode, /^EDU-\d{4}-[A-F0-9]{24}$/);

  const verification = await request(`/api/certificates/${certificateCode}/verify`);
  assert.equal(verification.response.status, 200);
  assert.deepEqual(Object.keys(verification.body.data).sort(), ['certificateCode', 'courseName', 'issuedAt', 'studentName', 'verified']);
  assert.equal(verification.body.data.verified, true);
});
