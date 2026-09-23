# EduMarket Prompt 18 Test Summary

Execution date: 2026-09-23 (browser verification: 2026-09-23)

| Metric | Result |
|---|---:|
| Documented test cases | 75 |
| PASS | 74 |
| FAIL | 0 |
| BLOCKED | 1 |
| NOT RUN | 0 |

## Automated execution evidence

- Backend: `npm.cmd test` — PASS, 27/27 tests; 0 failed; duration 15.601 s on the final regression rerun.
- Focused critical E2E: `node --test --test-concurrency=1 src/purchase-to-certificate.e2e.test.js` — PASS, 1/1; duration 1.360 s.
- Prisma validation: `npx.cmd prisma validate` — PASS; schema valid.
- Prisma migrations: `npx.cmd prisma migrate status` — PASS; 3 migrations found and database schema up to date.
- Dependency audit: `npm.cmd audit` — PASS; 0 vulnerabilities.
- `git diff --check` — PASS; no whitespace errors reported.
- Flutter environment fix: PASS. The SDK cache was owned by the interactive Admin account, while the sandbox account could not write its Flutter AppData state or SDK cache lock/stamp files. The sandbox account was granted Modify access only to `C:\flutter\bin\cache`; command-local `APPDATA` was redirected to a workspace temporary directory and Git safe-directory configuration was scoped to `C:/flutter`. Stale Dart children from the Windows batch launcher were stopped before each direct Flutter-tool run.
- Flutter doctor: completed. Flutter 3.38.4, Chrome, Android toolchain, connected devices, and network resources are healthy. It warns only that Visual Studio lacks the Windows desktop C++ workload; this is unrelated to Flutter Web.
- Flutter analyze: PASS — `No issues found!` (1.3 s on the final regression rerun).
- Flutter test: PASS — 18 widget tests passed.
- Flutter build web: PASS — `Built build\\web`; Wasm dry run succeeded (32.1 s compilation on the final regression rerun).

## Live local service verification

- Backend `http://localhost:4000/api/health` returned 200.
- Frontend `http://localhost:3000/`, `/khoa-hoc`, and a direct course path returned 200. The two direct paths contained `flutter_bootstrap`.
- Live `/api/categories` succeeded with 4 categories. Live catalog sorting/pagination (`sort=price_asc&page=1&limit=2`) returned 2 items with page metadata; a combined filter request returned 5 items.
- Live `/sitemap.xml` returned 200 and valid `urlset` XML, included 20 course URLs, and contained 0 private-route URLs. Live `/robots.txt` returned 200, did not globally disallow the site, and referenced the sitemap.
- Live authorization drill: anonymous library, orders, and admin API requests each returned 401; a temporary real customer received 403 from `/api/admin/dashboard`. The test user and audit records were removed afterward.

## Major flow assessment

- Critical purchase-to-certificate flow: PASS through real backend HTTP routes and PostgreSQL: registration, login, browse/search, cart, forged-price rejection, COD checkout, admin payment confirmation, PAID entitlement, library, lesson completion, one certificate, and public verification.
- Admin service flow: PASS at API and browser UI level. Browser session 2026-09-23 confirmed admin login, dashboard stats (690,000₫ revenue, 5 orders, 9 customers, 20 courses), full sidebar navigation (Khóa học, Danh mục, Đơn hàng, Người dùng, Đánh giá, Mã giảm giá, Quyền truy cập, Báo cáo doanh thu), and no runtime errors (QA-62, QA-68 PASS).
- Security flow: PASS at API and router-code level. Anonymous protected API requests return 401 (library, orders, admin). Customer admin API request returns 403. Flutter router (`app_router.dart` L69-80) confirmed: unauthenticated → redirect to `/login?redirect=<target>`; non-admin customer → redirect to `/admin/forbidden` (QA-69 PASS).
- SEO DOM verification (QA-66): PASS. Real browser DOM queries on course detail page (`/khoa-hoc/nodejs-express-cho-nguoi-moi`) verified `document.title` ("Node.js và Express cho người mới | EduMarket"), `meta[name="description"]` ("Khóa học Node.js và Express cho người mới bằng tiếng Việt."), `link[rel="canonical"]` ("http://localhost:3000/khoa-hoc/nodejs-express-cho-nguoi-moi"), `meta[property="og:title"]`, `meta[property="og:description"]`, `meta[property="og:url"]`, and `script[type="application/ld+json"]` (Schema.org Course, Product price 690,000 VND, and BreadcrumbList). Private routes (`/cart`) confirmed with `meta[name="robots"]`: "noindex, nofollow". Zero console/JS errors.
- Full customer browser flow (QA-67): PASS. Real browser walkthrough confirmed customer login (`Customer Test`), catalog search and category filters, course detail layout with sticky pricing/action card, wishlist navigation and empty-state view, add-to-cart toast, cart page with promo code input, checkout with COD payment, order confirmation (`EDU-1790176570320-CD48C505`), order history, student library, learning screen with lessons and attachments, certificate list, public certificate verification badge ("CHỨNG CHỈ HỢP LỆ VÀ CHÍNH THỨC" for code `EDU-2026-DA16F3DE27EF48EC066D3893`), 5-star review submission/approval, and protected download token authorization.
- Responsive layout verification (QA-70): PASS. Tested across 3 standard viewports: Desktop (1440x900), Tablet (768x1024), and Mobile (375x667) across 5 core representative pages (Home, Course Detail, Cart, Checkout, Library). Zero horizontal scroll across all 15 configurations (`hasHorizontalScroll: false`), clean responsive adaptations (desktop full navbar and sidebars, tablet adaptive header with search and hamburger menu, mobile full-width card stacking and hamburger navigation drawer). Zero RenderFlex overflow errors, zero unhandled exceptions, zero Flutter red-screen crashes.

## Known limitations and unresolved defects

1. VNPay live Sandbox (QA-75) remains the single BLOCKED test case. A real VNPay Sandbox card/payment session was not performed because the configured return URL is `localhost`, not a public HTTPS callback accessible to VNPay servers. Signed deterministic fixtures fully cover create, signature verification, amount verification, cancellation, idempotency, and entitlement behavior.

## Release-readiness assessment

74 of 75 test cases PASS (0 FAIL, 1 BLOCKED, 0 NOT RUN). Backend, database, audit, critical E2E, Flutter analysis/test/build, service-level coverage, live SEO endpoints, admin UI, security routing, SEO DOM inspection, full customer browser flow, and responsive layout all pass. The only remaining blocked test case is QA-75 VNPay live Sandbox due to external public HTTPS callback dependency. All non-external Prompt 18 requirements are now fully complete.
