# EduMarket final requirement audit

Audit date: 2026-09-24  
Scope: Prompt 19 final engineering review. This audit compares PROJECT_CONTEXT.md, source code, schema/migrations, routes, frontend routing, QA evidence, and the final regression commands. A BLOCKED status is not treated as a pass.

## Implemented and verified requirements

| Requirement | Implementation location | Verification evidence | Status | Notes |
| --- | --- | --- | --- | --- |
| Required architecture: Flutter Web, Express REST API, PostgreSQL, Prisma | frontend/, backend/src/, backend/prisma/ | Final Flutter build; Prisma validate/migrate status; health 200 | PASS | Visible application remains Flutter Web. |
| Authentication, session cookies, logout, CSRF, lockout, CORS, rate limits, RBAC and audit logging | backend/src/lib/auth.js, middleware/auth.js, routes/auth.js, app.js | npm test 27/27; QA-01 to QA-10; customer admin API smoke returned 403 | PASS | Cookie sessions are HttpOnly and production forces Secure. |
| Public catalog, hierarchy, search, filters, sorting, pagination, detail and recommendations | routes/catalog.js, frontend/lib/features/courses/ | QA-11 to QA-17; final catalog smoke returned success | PASS | Published-only queries are enforced server-side. |
| Cart and server-authoritative pricing | routes/cart.js, services/order-service.js, frontend cart/ | QA-18 to QA-21; purchase-to-certificate E2E | PASS | Duplicate and owned-course guards use API/database constraints. |
| COD checkout, immutable orders, history/detail, and admin COD confirmation | routes/checkout.js, routes/orders.js, routes/admin.js, services/order-service.js | QA-22 to QA-25; E2E; final customer order and admin dashboard smoke | PASS | COD completion uses the shared paid-order service. |
| VNPay Sandbox server integration: create, signed return/IPN, amount/ref checks, cancellation and idempotency | routes/payments.js, services/vnpay-service.js | QA-26 to QA-30; npm test includes vnpay.integration.test.js | PASS | Deterministic signed fixtures cover the backend flow. |
| Real VNPay Sandbox callback/IPN payment | backend/.env runtime configuration and public callback deployment | QA-75 | BLOCKED | Local callback is localhost and there is no public HTTPS endpoint/verified live merchant callback. Fixtures are not presented as a live test. |
| Customer-facing VNPay checkout selection and redirect | frontend/lib/features/checkout/checkout_screen.dart, payment_result_screen.dart | flutter test 25/25; browser subagent verified selection, redirect attempt to sandbox.vnpayment.vn, and backend-authoritative result screen | PASS | Fully implemented: selectable COD/VNPay, backend-authoritative status checking, client never determines price or PAID state. |
| Payment-completion entitlements; revoke/restore enforcement | services/order-service.js, services/entitlement-service.js, routes/library.js, routes/admin.js | QA-31 to QA-36 and QA-61; E2E | PASS | Payment and entitlement decisions are server-side. |
| Learning progress and one-time certificates with public verification/PDF | services/progress-service.js, certificate-pdf-service.js, routes/certificates.js, frontend library/certificates/ | QA-41 to QA-48; purchase-to-certificate E2E | PASS | Required lessons determine completion; unique constraints prevent duplicate certificates. |
| Protected private downloads | services/download-service.js, file-storage-service.js, routes/downloads.js | QA-37 to QA-40 | PASS | Token hash only, ten-minute expiry, one-use consumption, ownership and entitlement checks. |
| Wishlist, moderated reviews, and coupon rules | routes/wishlist.js, routes/reviews.js, routes/coupons.js, services/review-service.js, coupon-service.js | QA-49 to QA-59 | PASS | Review moderation and coupon locking are covered by integration tests. |
| Admin dashboard and management areas | routes/admin.js, frontend/lib/features/admin/ | QA-60 to QA-62 and QA-68; final admin login/dashboard API smoke | PASS | Customer access is independently rejected by the API. |
| Public policy content | routes/policies.js, frontend/lib/features/policies/ | QA-67 browser evidence; final direct policy route returned 200 | PASS | Content is demo policy material and needs legal review for production. |
| SEO paths, runtime metadata, canonical/OG/JSON-LD, sitemap and robots | frontend/core/seo/, backend/routes/seo.js, frontend/web/robots.txt | QA-63 to QA-66; final direct-route, sitemap and robots smoke | PASS | Private routes are excluded/noindexed. |
| Flutter guards, real API use, core loading/empty/error states, responsive UI | frontend/lib/core/router/, core/widgets/, features/ | flutter analyze; flutter test 18/18; QA-67 and QA-70 browser evidence | PASS | Unused fallback router/placeholder and debug API logging were removed in this review. |
| Schema, migrations, unique constraints, relations, indexes and seed | backend/prisma/schema.prisma, migrations/, seed.js | npx prisma validate; npx prisma migrate status; source/schema review | PASS | Three migrations are present and database is up to date. |
| QA documentation and critical customer purchase-to-certificate path | testing/test-cases.md, testing/test-summary.md, backend/src/purchase-to-certificate.e2e.test.js | 75 documented cases; 74 PASS, 0 FAIL, 1 external BLOCKED; focused E2E PASS | PASS | The final regression also passed backend and Flutter suites. |

## Explicitly out of scope

| Requirement | Implementation location | Verification evidence | Status | Notes |
| --- | --- | --- | --- | --- |
| Instructor marketplace/dashboard, multi-vendor model | Not implemented by design | PROJECT_CONTEXT.md section 35; role/schema review | OUT OF SCOPE | Only CUSTOMER and ADMIN roles are required. |
| Livestream, Zoom, real-time chat, forum, advanced quizzes, AI tools, microservices and Kubernetes | Not implemented by design | PROJECT_CONTEXT.md section 35; repository review | OUT OF SCOPE | Excluded to keep the assignment focused on a complete digital-goods store. |
| Production legal certification, managed operations, and production backup restore drill | Deployment responsibility | docs/security-checklist.md and docs/backup-restore.md | OUT OF SCOPE | Documentation is supplied; production deployment requires its own legal/operations review. |

## Review findings

1. No dead backend route mount or duplicate API route was found in backend/src/app.js. API success/error payloads follow the success/data/code/message convention, except VNPay IPN uses VNPay-required RspCode/Message responses.
2. No repository-tracked .env file, private key, database dump, private storage file, or generated frontend build artifact was found. A tracked session-cookie artifact was removed; a local GET using its historical value returned 401, and ignore rules now cover cookie, HAR, test-report and local Flutter-AppData artifacts.
3. The root README, frontend README, environment template, database/security documentation, and final submission documentation were updated and reconciled with the reviewed source.
4. The customer-facing VNPay option has been fully implemented in the Flutter checkout, verified via 25/25 automated tests and live browser execution (selection, redirect attempt to sandbox.vnpayment.vn, and backend-authoritative status checking at /checkout/result). The only remaining BLOCKED item is the external live VNPay Sandbox callback (QA-75) due solely to missing public HTTPS callback and live merchant credentials.
