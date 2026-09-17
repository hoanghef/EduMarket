'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');

let server;
let baseUrl;
let userId;
let ownedOrderId;

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

async function registerCustomer() {
  const csrfData = await csrf();
  const email = `cart-test-${Date.now()}@example.test`;
  const result = await request('/api/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie },
    body: JSON.stringify({ email, fullName: 'Cart Test Customer', password: 'CorrectPassword1!' }),
  });
  assert.equal(result.response.status, 201);
  userId = result.body.data.user.id;
  return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}

function writeHeaders(session) {
  return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie };
}

test.before(async () => {
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  if (ownedOrderId) await prisma.courseEntitlement.deleteMany({ where: { orderId: ownedOrderId } });
  if (ownedOrderId) await prisma.order.delete({ where: { id: ownedOrderId } });
  if (userId) {
    await prisma.auditLog.deleteMany({ where: { userId } });
    await prisma.user.delete({ where: { id: userId } });
  }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

test('cart requires an authenticated customer', async () => {
  const unauthenticated = await request('/api/cart');
  assert.equal(unauthenticated.response.status, 401);
  assert.equal(unauthenticated.body.code, 'UNAUTHENTICATED');

  const csrfData = await csrf();
  const adminLogin = await request('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie },
    body: JSON.stringify({ email: 'admin@edumarket.local', password: 'EduMarket@2026' }),
  });
  const adminCart = await request('/api/cart', { headers: { Cookie: `${csrfData.cookie}; ${cookies(adminLogin.response)}` } });
  assert.equal(adminCart.response.status, 403);
  assert.equal(adminCart.body.code, 'FORBIDDEN');
});

test('customer can get, add to, and remove their own cart; duplicate and unavailable courses are rejected', async () => {
  const session = await registerCustomer();
  const courses = await prisma.course.findMany({ where: { status: 'PUBLISHED' }, take: 2, orderBy: { createdAt: 'asc' }, select: { id: true } });
  assert.equal(courses.length, 2);

  const emptyCart = await request('/api/cart', { headers: { Cookie: session.cookie } });
  assert.equal(emptyCart.response.status, 200);
  assert.equal(emptyCart.body.data.cart.items.length, 0);

  const added = await request('/api/cart/items', { method: 'POST', headers: writeHeaders(session), body: JSON.stringify({ courseId: courses[0].id }) });
  assert.equal(added.response.status, 201);
  assert.equal(added.body.data.item.course.id, courses[0].id);

  const duplicate = await request('/api/cart/items', { method: 'POST', headers: writeHeaders(session), body: JSON.stringify({ courseId: courses[0].id }) });
  assert.equal(duplicate.response.status, 409);
  assert.equal(duplicate.body.code, 'CART_ITEM_EXISTS');

  const unavailable = await request('/api/cart/items', { method: 'POST', headers: writeHeaders(session), body: JSON.stringify({ courseId: 'missing-course-id' }) });
  assert.equal(unavailable.response.status, 404);
  assert.equal(unavailable.body.code, 'COURSE_NOT_AVAILABLE');

  const removed = await request(`/api/cart/items/${added.body.data.item.id}`, { method: 'DELETE', headers: writeHeaders(session) });
  assert.equal(removed.response.status, 204);
  const emptyAgain = await request('/api/cart', { headers: { Cookie: session.cookie } });
  assert.equal(emptyAgain.body.data.cart.items.length, 0);

  const order = await prisma.order.create({
    data: { orderNumber: `CART-OWNED-${Date.now()}`, userId, status: 'PAID', subtotal: 1, totalAmount: 1 },
  });
  ownedOrderId = order.id;
  await prisma.courseEntitlement.create({ data: { userId, courseId: courses[1].id, orderId: order.id, status: 'ACTIVE' } });
  const owned = await request('/api/cart/items', { method: 'POST', headers: writeHeaders(session), body: JSON.stringify({ courseId: courses[1].id }) });
  assert.equal(owned.response.status, 409);
  assert.equal(owned.body.code, 'COURSE_ALREADY_OWNED');
});
