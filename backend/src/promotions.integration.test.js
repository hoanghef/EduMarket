'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const app = require('./app');
const prisma = require('./lib/prisma');

let server; let baseUrl; let courseId; let unavailableCourseId;
const users = []; const orderIds = []; const couponIds = [];

function cookies(response) { return response.headers.getSetCookie().map((cookie) => cookie.split(';')[0]).join('; '); }
async function request(path, options = {}) { const response = await fetch(baseUrl + path, options); return { response, body: response.status === 204 ? null : await response.json() }; }
async function csrf() { const result = await request('/api/auth/csrf'); return { token: result.body.data.csrfToken, cookie: cookies(result.response) }; }
async function register(prefix, fullName = 'Promotion Test Customer') {
  const csrfData = await csrf();
  const result = await request('/api/auth/register', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}@example.test`, fullName, password: 'CorrectPassword1!' }) });
  assert.equal(result.response.status, 201); const session = { id: result.body.data.user.id, csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` }; users.push(session); return session;
}
async function loginAdmin() {
  const csrfData = await csrf();
  const result = await request('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfData.token, Cookie: csrfData.cookie }, body: JSON.stringify({ email: 'admin@edumarket.local', password: 'EduMarket@2026' }) });
  assert.equal(result.response.status, 200); return { csrfData, cookie: `${csrfData.cookie}; ${cookies(result.response)}` };
}
function headers(session) { return { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrfData.token, Cookie: session.cookie }; }
async function addToCart(session) { const result = await request('/api/cart/items', { method: 'POST', headers: headers(session), body: JSON.stringify({ courseId }) }); assert.equal(result.response.status, 201); }
async function checkout(session, body) { const result = await request('/api/checkout', { method: 'POST', headers: headers(session), body: JSON.stringify({ method: 'COD', ...body }) }); if (result.response.status === 201) orderIds.push(result.body.data.order.id); return result; }
async function createCoupon(code, fields = {}) {
  const coupon = await prisma.coupon.create({ data: { code, discountType: 'PERCENTAGE', discountValue: 10, startsAt: new Date(Date.now() - 60_000), endsAt: new Date(Date.now() + 3_600_000), ...fields } });
  couponIds.push(coupon.id); return coupon;
}
async function grantEntitlement(session, suffix) {
  const order = await prisma.order.create({ data: { orderNumber: `PROMO-PAID-${suffix}-${Date.now()}-${Math.random().toString(16).slice(2)}`, userId: session.id, status: 'PAID', subtotal: 1000, totalAmount: 1000, paidAt: new Date(), items: { create: { courseId, courseTitleSnapshot: 'Promotion test course', courseSlugSnapshot: `promotion-test-${suffix}`, unitPrice: 1000, discountedUnitPrice: 1000 } } } });
  orderIds.push(order.id); await prisma.courseEntitlement.create({ data: { userId: session.id, courseId, orderId: order.id, status: 'ACTIVE' } });
}

test.before(async () => {
  server = app.listen(0); await new Promise((resolve) => server.once('listening', resolve)); baseUrl = `http://127.0.0.1:${server.address().port}`;
  const category = await prisma.category.findFirst({ where: { isActive: true }, select: { id: true } }); const suffix = Date.now().toString();
  const course = await prisma.course.create({ data: { categoryId: category.id, title: `Promotion test course ${suffix}`, slug: `promotion-test-${suffix}`, description: 'Promotion test course.', instructorName: 'Test Instructor', price: 1000, status: 'PUBLISHED', publishedAt: new Date() } }); courseId = course.id;
  const unavailable = await prisma.course.create({ data: { categoryId: category.id, title: `Unavailable promotion course ${suffix}`, slug: `unavailable-promotion-${suffix}`, description: 'Unavailable course.', instructorName: 'Test Instructor', price: 1000, status: 'DRAFT' } }); unavailableCourseId = unavailable.id;
});

test.after(async () => {
  await prisma.wishlist.deleteMany({ where: { courseId: { in: [courseId, unavailableCourseId] } } });
  await prisma.review.deleteMany({ where: { courseId } });
  await prisma.courseProgress.deleteMany({ where: { courseId } });
  await prisma.courseEntitlement.deleteMany({ where: { courseId } });
  if (couponIds.length) await prisma.couponUsage.deleteMany({ where: { couponId: { in: couponIds } } });
  for (const orderId of orderIds) { await prisma.auditLog.deleteMany({ where: { entityId: orderId } }); await prisma.order.deleteMany({ where: { id: orderId } }); }
  if (couponIds.length) await prisma.coupon.deleteMany({ where: { id: { in: couponIds } } });
  await prisma.course.deleteMany({ where: { id: { in: [courseId, unavailableCourseId] } } });
  for (const user of users) { await prisma.auditLog.deleteMany({ where: { userId: user.id } }); await prisma.user.deleteMany({ where: { id: user.id } }); }
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve())); await prisma.$disconnect();
});

test('wishlist, reviews, moderation, and server-authoritative coupon checkout rules', async () => {
  const buyer = await register('promo-buyer', 'Buyer One'); const other = await register('promo-other', 'Buyer Two');
  const unauthenticatedWishlist = await request('/api/wishlist'); assert.equal(unauthenticatedWishlist.response.status, 401);
  const addWishlist = await request(`/api/wishlist/${courseId}`, { method: 'POST', headers: headers(buyer) }); assert.equal(addWishlist.response.status, 201);
  const duplicateWishlist = await request(`/api/wishlist/${courseId}`, { method: 'POST', headers: headers(buyer) }); assert.equal(duplicateWishlist.response.status, 409); assert.equal(duplicateWishlist.body.code, 'WISHLIST_ITEM_EXISTS');
  const unavailableWishlist = await request(`/api/wishlist/${unavailableCourseId}`, { method: 'POST', headers: headers(buyer) }); assert.equal(unavailableWishlist.response.status, 404);
  const wishlist = await request('/api/wishlist', { headers: { Cookie: buyer.cookie } }); assert.equal(wishlist.response.status, 200); assert.equal(wishlist.body.data.items.length, 1);
  const removeWishlist = await request(`/api/wishlist/${courseId}`, { method: 'DELETE', headers: headers(buyer) }); assert.equal(removeWishlist.response.status, 204);

  const deniedReview = await request('/api/reviews', { method: 'POST', headers: headers(other), body: JSON.stringify({ courseId, rating: 5 }) }); assert.equal(deniedReview.response.status, 403);
  await grantEntitlement(buyer, 'buyer');
  const invalidRating = await request('/api/reviews', { method: 'POST', headers: headers(buyer), body: JSON.stringify({ courseId, rating: 6 }) }); assert.equal(invalidRating.response.status, 400);
  const submitted = await request('/api/reviews', { method: 'POST', headers: headers(buyer), body: JSON.stringify({ courseId, rating: 4, comment: 'Useful course.' }) }); assert.equal(submitted.response.status, 201); assert.equal(submitted.body.data.review.status, 'PENDING'); const reviewId = submitted.body.data.review.id;
  const duplicateReview = await request('/api/reviews', { method: 'POST', headers: headers(buyer), body: JSON.stringify({ courseId, rating: 4 }) }); assert.equal(duplicateReview.response.status, 409);
  const beforeApproval = await request(`/api/courses/${courseId}/reviews`); assert.equal(beforeApproval.response.status, 200); assert.equal(beforeApproval.body.data.items.length, 0);
  const customerModeration = await request(`/api/admin/reviews/${reviewId}/moderate`, { method: 'PATCH', headers: headers(buyer), body: JSON.stringify({ status: 'APPROVED' }) }); assert.equal(customerModeration.response.status, 403);
  const admin = await loginAdmin();
  const approved = await request(`/api/admin/reviews/${reviewId}/moderate`, { method: 'PATCH', headers: headers(admin), body: JSON.stringify({ status: 'APPROVED' }) }); assert.equal(approved.response.status, 200); assert.equal(approved.body.data.review.status, 'APPROVED');
  const approvedPublic = await request(`/api/courses/${courseId}/reviews`); assert.equal(approvedPublic.body.data.items.length, 1); assert.equal(approvedPublic.body.data.items[0].rating, 4); const ratedCourse = await prisma.course.findUnique({ where: { id: courseId } }); assert.equal(String(ratedCourse.ratingAverage), '4'); assert.equal(ratedCourse.ratingCount, 1);
  await grantEntitlement(other, 'other');
  const secondReview = await request('/api/reviews', { method: 'POST', headers: headers(other), body: JSON.stringify({ courseId, rating: 1, comment: 'Rejected.' }) }); assert.equal(secondReview.response.status, 201);
  const rejected = await request(`/api/admin/reviews/${secondReview.body.data.review.id}/moderate`, { method: 'PATCH', headers: headers(admin), body: JSON.stringify({ status: 'REJECTED' }) }); assert.equal(rejected.response.status, 200); const afterRejection = await request(`/api/courses/${courseId}/reviews`); assert.equal(afterRejection.body.data.items.length, 1);

  const shopper = await register('promo-shopper'); const shopperOther = await register('promo-shopper-other');
  const percent = await createCoupon('PERCENTCAP', { discountValue: 50, maximumDiscountAmount: 150, perUserLimit: 3 });
  await addToCart(shopper); const preview = await request('/api/coupons/validate', { method: 'POST', headers: headers(shopper), body: JSON.stringify({ couponCode: percent.code, totalAmount: 1 }) }); assert.equal(preview.response.status, 200); assert.equal(String(preview.body.data.discountAmount), '150'); assert.equal(String(preview.body.data.totalAmount), '850');
  const percentCheckout = await checkout(shopper, { couponCode: percent.code, totalAmount: 1, discountAmount: 999 }); assert.equal(percentCheckout.response.status, 201); assert.equal(String(percentCheckout.body.data.order.discountAmount), '150'); assert.equal(String(percentCheckout.body.data.order.totalAmount), '850');
  const fixed = await createCoupon('FIXED100', { discountType: 'FIXED', discountValue: 100 }); await addToCart(shopper); const fixedCheckout = await checkout(shopper, { couponCode: fixed.code, totalAmount: 1 }); assert.equal(fixedCheckout.response.status, 201); assert.equal(String(fixedCheckout.body.data.order.discountAmount), '100'); assert.equal(String(fixedCheckout.body.data.order.totalAmount), '900');
  const expired = await createCoupon('EXPIRED10', { endsAt: new Date(Date.now() - 1000) }); const future = await createCoupon('FUTURE10', { startsAt: new Date(Date.now() + 3_600_000) }); const inactive = await createCoupon('INACTIVE10', { isActive: false }); const minimum = await createCoupon('MINIMUM10', { minimumOrderAmount: 2000 });
  for (const coupon of [expired, future, inactive, minimum]) { await addToCart(shopper); const result = await checkout(shopper, { couponCode: coupon.code }); assert.equal(result.response.status, 409); assert.equal((await request('/api/cart', { headers: { Cookie: shopper.cookie } })).body.data.cart.items.length, 1); const cart = (await request('/api/cart', { headers: { Cookie: shopper.cookie } })).body.data.cart; await request(`/api/cart/items/${cart.items[0].id}`, { method: 'DELETE', headers: headers(shopper) }); }
  const global = await createCoupon('GLOBALONE', { usageLimit: 1, perUserLimit: 5 }); await addToCart(shopper); assert.equal((await checkout(shopper, { couponCode: global.code })).response.status, 201); await addToCart(shopperOther); const globalDenied = await checkout(shopperOther, { couponCode: global.code }); assert.equal(globalDenied.response.status, 409); assert.equal(globalDenied.body.code, 'COUPON_USAGE_LIMIT_REACHED'); const globalCart = (await request('/api/cart', { headers: { Cookie: shopperOther.cookie } })).body.data.cart; await request(`/api/cart/items/${globalCart.items[0].id}`, { method: 'DELETE', headers: headers(shopperOther) });
  const perUser = await createCoupon('PERUSERONE', { usageLimit: 10, perUserLimit: 1 }); await addToCart(shopperOther); assert.equal((await checkout(shopperOther, { couponCode: perUser.code })).response.status, 201); await addToCart(shopperOther); const perUserDenied = await checkout(shopperOther, { couponCode: perUser.code }); assert.equal(perUserDenied.response.status, 409); assert.equal(perUserDenied.body.code, 'COUPON_USER_LIMIT_REACHED');
  const racerA = await register('promo-race-a'); const racerB = await register('promo-race-b'); const race = await createCoupon('RACEONE', { usageLimit: 1, perUserLimit: 5 }); await addToCart(racerA); await addToCart(racerB); const raceResults = await Promise.all([checkout(racerA, { couponCode: race.code }), checkout(racerB, { couponCode: race.code })]); assert.deepEqual(raceResults.map((result) => result.response.status).sort(), [201, 409]); assert.equal(await prisma.couponUsage.count({ where: { couponId: race.id } }), 1); assert.equal((await prisma.coupon.findUnique({ where: { id: race.id } })).usageCount, 1);
});
