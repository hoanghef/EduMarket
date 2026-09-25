# EduMarket database

EduMarket uses PostgreSQL through Prisma. The authoritative schema is backend/prisma/schema.prisma, migration history is in backend/prisma/migrations, and the repeatable development seed is backend/prisma/seed.js. Monetary values use Decimal(12,2).

## Setup

From backend:

~~~powershell
npm run db:generate
npx prisma migrate dev
npm run db:seed
~~~

Use Prisma Studio only for local development:

~~~powershell
npx prisma studio
~~~

Set DATABASE_URL in backend/.env. Do not commit connection strings, dumps, or real user data.

## Main entities

- User, Cart and CartItem: customer/admin accounts, password hashes, cart ownership, login lockout/session state.
- Category, Course, Lesson and CourseFile: hierarchical catalog and private learning content.
- Order, OrderItem and Payment: immutable transaction snapshots and payment state.
- CourseEntitlement, CourseProgress and DownloadToken: active/revoked access, idempotent lesson completion, and one-use expiring download tokens.
- Certificate: one completion certificate per user/course and its public verification code.
- Review, Wishlist, Coupon and CouponUsage: advanced e-commerce features and moderation/redemption constraints.
- AuditLog: security and business-event traceability.

## Important integrity rules

- Unique constraints protect email, category/course slugs, order number, certificate code, coupon code, storage key, token hash, payment transaction ID, cart/course, order/course, user/course entitlement, review, wishlist, certificate, and user/lesson progress.
- Category hierarchy uses parentId. Course/lesson/file content cascades appropriately; transaction history uses restrictive relationships where a historical record must remain traceable.
- Catalog, orders, payments, entitlements, downloads, reviews, coupons and audit logs have indexes used by their primary filtering paths.
- DownloadToken stores only SHA-256 tokenHash, expiry, counter and maximum download count. The raw token exists only while a temporary URL is issued and is never stored in the database.

## Seed data

The idempotent seed creates one ADMIN and five CUSTOMER demonstration accounts, four parent categories with children, 20 Vietnamese courses with lessons, active coupons, and carts. It uses bcrypt cost 12.

| Role | Email | Demo password |
| --- | --- | --- |
| Admin | admin@edumarket.local | EduMarket@2026 |
| Customer | an.nguyen@edumarket.local and four additional seeded customers | EduMarket@2026 |

These values are for local demonstrations only. They are not production credentials.

## Final verification

The Prompt 19 regression ran:

~~~powershell
npx prisma validate
npx prisma migrate status
~~~

The schema validated and all three migrations were reported as applied/up to date. The database was not reset.
