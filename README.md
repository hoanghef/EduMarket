# EduMarket

EduMarket is a university B2C e-commerce project for selling online courses and protected digital learning materials. It demonstrates the complete digital-goods flow: discovery, cart, server-calculated checkout, payment confirmation, entitlement-based learning access, protected downloads, progress, and completion certificates.

## Project Overview

The system has two roles:

- **Customer** — registers and signs in, browses/searches/filter courses, manages a cart and wishlist, applies coupons, checks out, views orders and a purchased-course library, learns, downloads protected files, reviews purchased courses, and verifies certificates.
- **Admin** — manages courses, categories, orders and COD confirmation, users, reviews, coupons, entitlements, and revenue reports.

COD is a controlled simulation for this digital-goods assignment. VNPay is implemented as a Sandbox backend integration with signed callbacks and idempotent completion.

## Technology Stack

- Flutter Web, Dart, go_router, Riverpod, Dio
- Node.js, Express, Prisma ORM
- PostgreSQL
- bcrypt, HttpOnly cookie sessions, CSRF protection, Helmet, rate limiting
- Multer for controlled private-file uploads and PDFKit for certificates
- VNPay Sandbox (no production payment processing)

## Project Structure

~~~text
EduMarket/
├── backend/                 Express API, Prisma schema/migrations/seed, integration tests
├── frontend/                Flutter Web application and widget tests
├── docs/                    Database, security, SEO, payment, backup, audit, submission docs
├── testing/                 75 documented QA cases and execution summary
├── PROJECT_CONTEXT.md       Assignment requirements and constraints
└── TODO.md                  Verified delivery and final-review status
~~~

## Prerequisites

| Tool | Required version |
| --- | --- |
| Node.js | 18 or newer (Node 22 used for verification) |
| npm | 9 or newer |
| PostgreSQL | 14 or newer |
| Flutter | 3.38.4 or compatible, with Web enabled |
| Chrome or Edge | Recommended for Flutter Web development |

## Environment Setup

Copy the backend template and replace only its placeholders:

~~~powershell
Copy-Item backend/.env.example backend/.env
~~~

Required configuration is documented in [backend/.env.example](backend/.env.example), including PORT, NODE_ENV, APP_URL, DATABASE_URL, CORS_ORIGINS, SESSION_SECRET, cookie settings, private storage, certificate font, and VNPay Sandbox settings. Never commit backend/.env, merchant credentials, or production secrets.

The frontend takes its API origin from a compile-time define. Its local default is http://localhost:4000; set it for a deployment with --dart-define=API_BASE_URL=https://api.example.edu.

## Database Setup

Start PostgreSQL and configure DATABASE_URL in backend/.env, then run:

~~~powershell
cd backend
npm install
npx prisma generate
npx prisma migrate dev
npm run db:seed
~~~

For a non-destructive schema check, use npx prisma validate and npx prisma migrate status. See [docs/database.md](docs/database.md) for schema and seed details.

## Backend Run

~~~powershell
cd backend
npm install
npm run dev
~~~

The API starts at http://localhost:4000. Confirm it with GET http://localhost:4000/api/health.

## Flutter Run

~~~powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
~~~

To produce a web bundle:

~~~powershell
flutter build web --dart-define=API_BASE_URL=https://api.example.edu
~~~

## Default Local URLs

| Service | URL |
| --- | --- |
| Flutter Web frontend | http://localhost:3000 |
| Express API | http://localhost:4000 |
| Health check | http://localhost:4000/api/health |
| Sitemap | http://localhost:4000/sitemap.xml |
| Robots | http://localhost:4000/robots.txt |

## Test Accounts

npm run db:seed creates demonstration-only accounts on a local database. These are not production credentials.

| Role | Email | Password |
| --- | --- | --- |
| Admin | admin@edumarket.local | EduMarket@2026 |
| Customer | Seeded customer accounts | EduMarket@2026 |

## Major Features

- Authentication, cookie sessions, CSRF, login lockout, RBAC, ownership checks, and audit logs
- Public catalog with categories, search, filters, sorting, pagination, detail pages, and recommendations
- Cart, server-side pricing/coupons, COD checkout, orders, and a backend VNPay Sandbox flow
- Entitlements, protected library/learning pages, expiring one-use downloads, progress, and certificates
- Wishlist, entitlement-gated moderated reviews, and coupon limits
- Admin dashboard plus content, order, user, review, coupon, entitlement, and revenue management
- Path-based URLs, dynamic titles/meta/canonical/OpenGraph/JSON-LD, sitemap, and robots rules

## Testing

The final QA record is in [testing/test-cases.md](testing/test-cases.md) and [testing/test-summary.md](testing/test-summary.md).

| QA result | Count |
| --- | ---: |
| Documented cases | 75 |
| PASS | 74 |
| FAIL | 0 |
| BLOCKED | 1 |
| NOT RUN | 0 |

Backend integration tests, the purchase-to-certificate E2E test, Prisma checks, Flutter analysis/widget tests/web build, live API checks, browser flow checks, and security/SEO coverage are recorded there. The sole QA block is a real VNPay Sandbox payment: a public HTTPS return/IPN callback endpoint is not available locally. Signed deterministic VNPay integration tests pass, but they are not a substitute for that live Sandbox test.

## Security

See [docs/security-checklist.md](docs/security-checklist.md). Security-sensitive decisions remain server-side: price, payment state, role, ownership, entitlement, and certificate eligibility are never trusted from Flutter.

## Backup/Restore

See [docs/backup-restore.md](docs/backup-restore.md). Use the supplied scripts only with PostgreSQL client tools and restore only to a disposable or backed-up database.

## SEO

See [docs/seo.md](docs/seo.md) for path URLs, metadata, JSON-LD, sitemap/robots behavior, SPA refresh configuration, and CSR limitations.

## Known Limitations

- Flutter Web is a client-side-rendered SPA; it has no SSR. JavaScript-capable crawlers can render runtime metadata, while non-JS social preview crawlers may not.
- A real VNPay Sandbox callback/IPN test remains blocked until valid Sandbox credentials and a public HTTPS callback endpoint are available.
- The Flutter checkout currently exposes COD only. The backend VNPay Sandbox create/callback/IPN flow is implemented and deterministically tested, but enabling its customer UI is a functional follow-up outside this final-review scope.
- Production deployment needs HTTPS, explicit CORS origins, a long random session secret, managed secret storage, monitored rate-limit storage, database least privilege, and a verified backup restore drill.

## License

University assignment — not for commercial distribution.
