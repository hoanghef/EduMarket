'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');

let server;
let baseUrl;
let customerId;
let otherCustomerId;
let courseId;
let orderId;

function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function register(emailPrefix) {
  const csrfData = await csrf();
  const result = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: `${emailPrefix}-${Date.now()}@example.test`, fullName: 'Checkout Test Customer', password: 'CorrectPassword1!' }) });
  assert.equal(result.response.status, 201);
  return { id: result.body.data.user.id, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
async function login(email, password) {
  const csrfData = await csrf();
  const result = await request('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email, password }) });
  assert.equal(result.response.status, 200);
  return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
function headers(session) { return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie }; }

test.before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } });
  const suffix = Date.now().toString();
  const course = await prisma.course.create({ data: { categoryId: category.id, title: `Checkout test course ${suffix}`, slug: `checkout-test-${suffix}`, description: 'Transaction test course.', instructorName: 'Test Instructor', price: 100000, salePrice: 80000, status: 'PUBLISHED', publishedAt: new Date() } });
  courseId = course.id;
});

test.after(async () => {
  if (orderId) await prisma.courseEntitlement.deleteMany({ where: { orderId } });
  if (orderId) await prisma.auditLog.deleteMany({ where: { entityId: orderId } });
  if (orderId) await prisma.order.delete({ where: { id: orderId } });
  if (courseId) await prisma.course.delete({ where: { id: courseId } });
  for (const userId of [customerId, otherCustomerId].filter(Boolean)) {
    await prisma.auditLog.deleteMany({ where: { userId } });
    await prisma.user.delete({ where: { id: userId } });
  }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

test('COD checkout snapshots server prices, rolls back invalid checkout, and confirmation grants access once', async () => {
  const customer = await register('checkout-customer');
  customerId = customer.id;
  const other = await register('checkout-other');
  otherCustomerId = other.id;

  const add = await request('/api/cart/items', { method: 'POST', headers: headers(customer), body: JSON.stringify({ courseId }) });
  assert.equal(add.response.status, 201);

  await prisma.course.update({ where: { id: courseId }, data: { status: 'DRAFT' } });
  const rejected = await request('/api/checkout', { method: 'POST', headers: headers(customer), body: JSON.stringify({ method: 'COD', totalAmount: 1 }) });
  assert.equal(rejected.response.status, 409);
  assert.equal(rejected.body.code, 'COURSE_NOT_AVAILABLE');
  const retainedCart = await request('/api/cart', { headers: { Cookie: customer.cookie } });
  assert.equal(retainedCart.body.data.cart.items.length, 1);

  await prisma.course.update({ where: { id: courseId }, data: { status: 'PUBLISHED', salePrice: 65000 } });
  const checkout = await request('/api/checkout', { method: 'POST', headers: headers(customer), body: JSON.stringify({ method: 'COD', totalAmount: 1, price: 1 }) });
  assert.equal(checkout.response.status, 201);
  const order = checkout.body.data.order;
  orderId = order.id;
  assert.equal(order.status, 'WAITING_CONFIRMATION');
  assert.equal(order.payment.method, 'COD');
  assert.equal(order.payment.status, 'PENDING');
  assert.equal(String(order.totalAmount), '65000');
  assert.equal(order.items.length, 1);
  assert.equal(order.items[0].courseTitleSnapshot.startsWith('Checkout test course'), true);
  assert.equal(String(order.items[0].unitPrice), '100000');
  assert.equal(String(order.items[0].discountedUnitPrice), '65000');
  const clearedCart = await request('/api/cart', { headers: { Cookie: customer.cookie } });
  assert.equal(clearedCart.body.data.cart.items.length, 0);
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customerId, courseId } }), 0);
  assert.equal(await prisma.auditLog.count({ where: { userId: customerId, action: 'ORDER_CREATED', entityId: orderId } }), 1);

  const history = await request('/api/orders', { headers: { Cookie: customer.cookie } });
  assert.equal(history.response.status, 200);
  assert.equal(history.body.data.orders.some((item) => item.id === orderId), true);
  const detail = await request(`/api/orders/${orderId}`, { headers: { Cookie: customer.cookie } });
  assert.equal(detail.response.status, 200);
  const status = await request(`/api/orders/${orderId}/status`, { headers: { Cookie: customer.cookie } });
  assert.equal(status.response.status, 200);
  assert.equal(status.body.data.order.status, 'WAITING_CONFIRMATION');
  const forbiddenDetail = await request(`/api/orders/${orderId}`, { headers: { Cookie: other.cookie } });
  assert.equal(forbiddenDetail.response.status, 404);
  const customerConfirm = await request(`/api/admin/orders/${orderId}/cod-confirm`, { method: 'PATCH', headers: headers(customer) });
  assert.equal(customerConfirm.response.status, 403);

  const admin = await login('admin@edumarket.local', 'EduMarket@2026');
  const confirmed = await request(`/api/admin/orders/${orderId}/cod-confirm`, { method: 'PATCH', headers: headers(admin) });
  assert.equal(confirmed.response.status, 200);
  assert.equal(confirmed.body.data.order.status, 'PAID');
  assert.equal(confirmed.body.data.order.payment.status, 'SUCCESS');
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customerId, courseId, status: 'ACTIVE' } }), 1);
  assert.equal(await prisma.auditLog.count({ where: { action: 'COD_CONFIRMED', entityId: orderId } }), 1);
  assert.equal(await prisma.auditLog.count({ where: { userId: customerId, action: 'COURSE_ACCESS_GRANTED' } }), 1);

  const duplicateConfirmation = await request(`/api/admin/orders/${orderId}/cod-confirm`, { method: 'PATCH', headers: headers(admin) });
  assert.equal(duplicateConfirmation.response.status, 409);
  assert.equal(duplicateConfirmation.body.code, 'ORDER_NOT_AWAITING_CONFIRMATION');
  assert.equal(await prisma.courseEntitlement.count({ where: { userId: customerId, courseId, status: 'ACTIVE' } }), 1);
});
