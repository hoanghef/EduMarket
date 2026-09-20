# EduMarket Project TODO

## Current Status
- Current phase: Customer Library UI implemented
- Current task: Flutter Library screen, Course Learning screen, and Lesson Player screen implemented and statically verified
- Last completed task: Library screen (entitlement list, empty/error states), CourseLearningScreen (lesson list, progress bar, mark-complete, revoked-access denial, file attachments), LessonPlayerScreen (breadcrumb, content, mark-complete, prev/next navigation). flutter analyze: 0 issues. flutter test: 9/9 PASS. flutter build web: √ success. Backend library integration: 15/15 pass.
- Blocking issues: Browser manual verification pending (browser automation unavailable).
- Next recommended task: Manual browser test of Library UI flow, then proceed to Prompt 11 (Secure Downloads).

## Progress Summary
| Phase | Status | Notes |
| :--- | :--- | :--- |
| 1. Project Setup | DONE | Backend on :4000, Flutter Web on :3000, health API live, git committed |
| 2. Database | DONE | PostgreSQL verified; full Prisma schema, 2 migrations, seed data and queries verified |
| 3. Authentication and Security Foundation | DONE | Auth API, cookies, CSRF, CORS, lockout, Flutter Login/Register UI, Riverpod state & route guards verified |
| 4. Course Catalog Backend | DONE | Public category/catalog/recommendation APIs and admin content CRUD verified by integration tests |
| 5. Flutter Core UI | DONE | AppShell, responsive breakpoints, theming, navigation, and core states built |
| 6. Flutter Course Catalog | DONE | Home, catalog, detail pages built with real API data and responsive layouts |
| 7. Cart | DONE | Backend Cart API and Flutter Cart page complete; add to cart and cart sync verified |
| 8. Coupons | NOT STARTED | |
| 9. Checkout and Orders | IN PROGRESS | COD checkout and customer order APIs/UI verified; VNPay backend is verified while Flutter payment UI remains pending |
| 10. VNPay Sandbox | DONE | Signed Sandbox create, return, IPN, amount/reference/signature checks, idempotency, audit logs, docs, and tests verified |
| 11. Digital Course Entitlement | DONE | COD/VNPay grants, admin grant/revoke/restore, ACTIVE/REVOKED enforcement, protected APIs, audit logs, and tests verified |
| 12. Customer Library | DONE (pending browser test) | Backend list, protected course/lesson/file metadata access, idempotent lesson completion; Flutter LibraryScreen, CourseLearningScreen, LessonPlayerScreen, progress bar, revoked-access denial implemented & statically verified |
| 13. Secure Downloads | NOT STARTED | |
| 14. Course Progress | NOT STARTED | |
| 15. Certificates | NOT STARTED | |
| 16. Wishlist | NOT STARTED | |
| 17. Reviews | NOT STARTED | |
| 18. Admin Panel | NOT STARTED | |
| 19. Security Audit | NOT STARTED | |
| 20. SEO | NOT STARTED | |
| 21. Testing | NOT STARTED | |
| 22. Final Browser Verification | NOT STARTED | |
| 23. Documentation and Submission | NOT STARTED | |
| 24. Final Requirement Audit | NOT STARTED | |

## 1. Project Setup
- [x] repository structure (`/frontend`, `/backend`, `/docs`, `/testing`, `/database`)
- [x] Flutter Web frontend setup (Flutter 3.38.4, go_router, Riverpod, Dio – `flutter pub get` ✓)
- [x] Node.js + Express backend setup (Node 22, Express 4.x, Helmet, CORS, rate limiting)
- [x] PostgreSQL (service running locally; migration and queries verified)
- [x] Prisma (installed v6.12.0, schema.prisma initialized, prisma.js singleton created)
- [x] environment configuration (`backend/.env` + `backend/.env.example`)
- [x] health API (`GET /api/health` → 200 OK verified via PowerShell and browser)
- [x] Flutter API connection (Dio client + healthRepository + healthProvider created; flutter test 1/1 PASS)
- [x] Git initialization/checkpoint (initial commit b6b4b6d, 34 files)

## 2. Database
- [x] Prisma schema
- [x] enums
- [x] User
- [x] Category
- [x] Course
- [x] Lesson
- [x] CourseFile
- [x] Cart
- [x] CartItem
- [x] Order
- [x] OrderItem
- [x] Payment
- [x] CourseEntitlement
- [x] CourseProgress
- [x] DownloadToken
- [x] Certificate
- [x] Review
- [x] Wishlist
- [x] Coupon
- [x] CouponUsage
- [x] AuditLog
- [x] migrations
- [x] seed data
- [x] database documentation
- [x] database verification

## 3. Authentication and Security Foundation
- [x] register
- [x] login
- [x] logout
- [x] current user
- [x] bcrypt
- [x] HttpOnly cookies
- [x] SameSite
- [x] Secure cookie production config
- [x] CSRF
- [x] CORS
- [x] role authorization
- [x] login rate limiting
- [x] 5 failed login lockout
- [x] audit login
- [x] auth automated tests
- [x] Flutter Login page
- [x] Flutter Register page
- [x] Flutter auth state integration (Riverpod, Dio credentials, CSRF)
- [x] Flutter session restoration (GET /api/auth/me)
- [x] Flutter route protection & redirection guards
- [x] Flutter authenticated AppShell & Navbar

## 4. Course Catalog Backend
- [x] category API
- [x] course listing
- [x] search
- [x] filters
- [x] sorting
- [x] pagination
- [x] course detail
- [x] recommendations
- [x] admin course CRUD
- [x] admin category CRUD
- [x] API tests

## 5. Flutter Core UI
- [x] app theme
- [x] responsive breakpoints
- [x] router
- [x] AppShell
- [x] navbar
- [x] footer
- [x] loading state
- [x] empty state
- [x] error state
- [x] desktop
- [x] tablet
- [x] mobile

## 6. Flutter Course Catalog
- [x] home page
- [x] featured categories
- [x] best sellers
- [x] new courses
- [x] top rated courses
- [x] course listing
- [x] filters
- [x] search
- [x] sort
- [x] pagination
- [x] course detail
- [x] recommendation section
- [x] real API integration
- [x] browser verification

## 7. Cart
- [x] backend cart API
- [x] add course
- [x] remove course
- [x] duplicate prevention
- [x] already-owned course prevention
- [x] Flutter cart page
- [x] cart tests

## 8. Coupons
- [ ] percentage coupon
- [ ] fixed coupon
- [ ] expiry
- [ ] minimum order
- [ ] maximum discount
- [ ] usage limit
- [ ] per-user restriction
- [ ] Flutter coupon UI
- [ ] tests

## 9. Checkout and Orders
- [x] checkout transaction
- [x] server-side price calculation
- [x] immutable order items
- [x] COD option
- [ ] VNPay option
- [x] order history
- [x] order detail
- [x] order status
- [x] Flutter checkout
- [x] Flutter order pages
- [x] tests

## 10. VNPay Sandbox
- [x] create payment
- [x] return URL
- [x] IPN
- [x] signature verification
- [x] amount verification
- [x] idempotency
- [x] payment update
- [x] order update
- [x] audit logs
- [x] duplicate callback prevention
- [x] Sandbox documentation
- [x] integration tests

## 11. Digital Course Entitlement
- [x] grantOrderEntitlements
- [x] grantCourseAccess
- [x] revokeCourseAccess
- [x] restoreCourseAccess
- [x] ACTIVE entitlement
- [x] REVOKED entitlement
- [x] protected course API
- [x] COD grant flow
- [x] VNPay grant flow
- [x] admin entitlement APIs
- [x] tests

## 12. Customer Library
- [x] library API
- [x] purchased course list
- [x] protected course detail
- [x] Flutter library page
- [x] continue learning
- [x] revoked access state
- [ ] browser tests

## 13. Secure Downloads
- [ ] private storage
- [ ] generate secure random token
- [ ] hash token
- [ ] 10 minute expiry
- [ ] max download count
- [ ] temporary download URL
- [ ] file streaming
- [ ] expired token handling
- [ ] revoked entitlement handling
- [ ] audit log
- [ ] tests

## 14. Course Progress
- [x] lesson completion
- [x] idempotent completion
- [ ] progress calculation
- [ ] progress API
- [ ] Flutter progress UI
- [x] tests

## 15. Certificates
- [ ] unique certificate code
- [ ] automatic certificate creation
- [ ] PDF generation
- [ ] public verification
- [ ] certificate list
- [ ] certificate download
- [ ] Flutter certificate page
- [ ] duplicate prevention
- [ ] tests

## 16. Wishlist
- [ ] add wishlist
- [ ] remove wishlist
- [ ] duplicate prevention
- [ ] wishlist page
- [ ] tests

## 17. Reviews
- [ ] entitlement required
- [ ] one review per user/course
- [ ] rating 1–5
- [ ] PENDING
- [ ] APPROVED
- [ ] REJECTED
- [ ] admin moderation
- [ ] approved rating aggregation
- [ ] Flutter review UI
- [ ] tests

## 18. Admin Panel
- [ ] admin shell
- [ ] dashboard
- [ ] course management
- [ ] category management
- [ ] order management
- [ ] user management
- [ ] COD confirmation
- [ ] review moderation
- [ ] coupon management
- [ ] entitlement management
- [ ] revenue report
- [ ] recent orders
- [ ] best-selling courses
- [ ] monthly revenue
- [ ] responsive admin UI
- [ ] browser tests

## 19. Security Audit
- [ ] authentication review
- [ ] authorization review
- [ ] IDOR
- [ ] SQL injection
- [ ] XSS
- [ ] CSRF
- [ ] rate limiting
- [ ] upload validation
- [ ] secret management
- [ ] price manipulation
- [ ] VNPay verification
- [ ] entitlement bypass
- [ ] download security
- [ ] audit logging
- [ ] database backup
- [ ] regression tests
- [ ] security checklist documentation

## 20. SEO
- [ ] path-based URLs
- [ ] course slug
- [ ] title
- [ ] meta description
- [ ] canonical
- [ ] OpenGraph
- [ ] Course structured data
- [ ] Product structured data
- [ ] BreadcrumbList
- [ ] sitemap.xml
- [ ] robots.txt
- [ ] excluded private routes
- [ ] SEO documentation
- [ ] verification

## 21. Testing
- [ ] minimum 35 documented test cases
- [ ] authentication tests
- [ ] catalog tests
- [ ] cart tests
- [ ] checkout tests
- [ ] COD tests
- [ ] VNPay tests
- [ ] entitlement tests
- [ ] download tests
- [ ] progress tests
- [ ] certificate tests
- [ ] wishlist tests
- [ ] review tests
- [ ] admin tests
- [ ] security tests
- [ ] Actual Result
- [ ] Status
- [ ] Evidence
- [ ] automated backend tests
- [x] Flutter analyze
- [x] Flutter test
- [x] Flutter build web

## 22. Final Browser Verification
Include customer end-to-end flow:
- [ ] home
- [ ] catalog
- [ ] search
- [ ] filter
- [ ] login
- [ ] cart
- [ ] coupon
- [ ] checkout
- [ ] payment
- [ ] library
- [ ] learning
- [ ] download
- [ ] progress
- [ ] certificate

Include admin end-to-end flow:
- [ ] dashboard
- [ ] course CRUD
- [ ] orders
- [ ] COD confirmation
- [ ] reviews
- [ ] coupons
- [ ] revoke access
- [ ] restore access
- [ ] reports

Include responsive verification:
- [ ] desktop
- [ ] tablet
- [ ] mobile

## 23. Documentation and Submission
- [x] README
- [ ] INSTALL guide
- [x] .env.example
- [ ] database export
- [ ] testing files
- [ ] security checklist
- [ ] screenshots
- [ ] demo video
- [ ] report
- [ ] meeting minutes
- [ ] contribution table
- [ ] AI usage declaration
- [ ] final ZIP structure

## 24. Final Requirement Audit
- [ ] all basic e-commerce requirements checked
- [ ] all advanced requirements checked
- [ ] both payment methods checked
- [ ] Topic 12 mandatory requirements checked
- [ ] security requirements checked
- [ ] SEO requirements checked
- [ ] 30+ test requirement checked
- [ ] build verification
- [ ] deployment verification
- [ ] final demo verification
