# EduMarket submission checklist

Review date: 2026-09-24. This checklist records the state of the repository after the Prompt 19 review; it does not create a ZIP, commit, or push.

| Item | Status | Evidence / action |
| --- | --- | --- |
| Source code present | PASS | backend/, frontend/, Prisma schema, migrations, seed, and tests are present. |
| README complete | PASS | Root README covers architecture, setup, URLs, demo accounts, features, testing, security, backup, SEO, and limitations. |
| Environment template complete | PASS | backend/.env.example documents runtime, database, CORS, cookie, storage, certificate and VNPay variables. |
| Migrations and seed available | PASS | Three migrations in backend/prisma/migrations/ and backend/prisma/seed.js. |
| Backend automated tests pass | PASS | npm test: 27/27 passed in final regression. |
| Dependency audit passes | PASS | npm audit: 0 vulnerabilities. |
| Prisma checks pass | PASS | prisma validate passed; migrate status reports database schema up to date. |
| Flutter quality and build pass | PASS | flutter analyze clean; flutter test 25/25; flutter build web succeeded. |
| Health endpoint passes | PASS | GET /api/health returned HTTP 200. |
| QA documentation present | PASS | testing/test-cases.md and testing/test-summary.md record 75 cases: 74 PASS, 0 FAIL, 1 BLOCKED, 0 NOT RUN. |
| Security/SEO/database/backup docs present | PASS | docs/security-checklist.md, docs/seo.md, docs/database.md, and docs/backup-restore.md are present. |
| No active secrets or temporary artifacts in the submission working tree | PASS | .env/private storage/backups/build outputs are ignored; tracked admin_cookie.txt was removed and its historical session value returned 401 when checked locally. |
| Ignore rules suitable for submission | PASS | node_modules, build/.dart_tool, private storage, dumps, logs, cookies, HAR/test artifacts and local Flutter AppData are ignored; migration SQL is explicitly trackable. |
| Git diff whitespace check | PASS | git diff --check completed without whitespace errors. |
| Working tree reviewed | PASS | Only intentional Prompt 19 documentation/cleanup changes remain uncommitted; automatic commit/push is prohibited. |
| Live VNPay Sandbox payment | BLOCKED | Requires valid Sandbox credentials plus a public HTTPS return/IPN endpoint; signed local fixtures are not a live substitute. |
| Customer VNPay checkout UI | PASS | Flutter checkout UI supports selectable COD and VNPay, initiates backend create-payment, redirects to VNPay URL, and handles return at /checkout/result using authoritative backend status. Verified by 25/25 Flutter tests and real browser flow. |

## Include in a submission

- Source code, Prisma schema/migrations, seed script, .env.example, documentation, automated tests, and QA evidence.

## Exclude from a submission

- node_modules, frontend/build, .dart_tool, IDE caches, backend/.env, real credentials, database dumps, private storage files, session/cookie files, debug logs, HAR files, browser test reports, and temporary Flutter AppData.

## Pre-submission action

All functional requirements and customer checkout flows are implemented and verified. The only remaining BLOCKED item is QA-75 live VNPay Sandbox due strictly to external public HTTPS callback / live merchant credentials limitation. Application is READY FOR SUBMISSION.
