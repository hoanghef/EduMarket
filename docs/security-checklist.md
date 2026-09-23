# Security checklist – Prompt 16

Phạm vi: backend Express/Prisma và tích hợp Flutter Web hiện có. Kết quả bên dưới là bằng chứng triển khai/test của dự án demo, không phải chứng nhận bảo mật hoặc tuân thủ pháp lý production.

| Hạng mục audited | Triển khai/evidence | Test/verification | Trạng thái |
| --- | --- | --- | --- |
| Mật khẩu và đăng nhập | `bcrypt` 12 rounds; 5 lần sai khóa 15 phút; login limiter; audit `LOGIN_SUCCESS`/`LOGIN_FAILED` | `auth.integration.test.js` | PASS |
| Phiên/cookie/logout | Cookie ký HMAC, HttpOnly, SameSite hợp lệ; `Secure` bắt buộc khi production; `sessionVersion` vô hiệu hóa mọi cookie cũ lúc logout | Replay cookie sau logout trong `auth.integration.test.js`; production cookie test | PASS |
| CSRF/CORS | Double-submit CSRF cho unsafe methods; CORS credentials chỉ cho allow-list; production yêu cầu `CORS_ORIGINS` | Auth CSRF test; CORS allow/reject test | PASS |
| RBAC và IDOR | `requireAuth`, `requireCustomer`, `requireAdmin`; ownership query cho cart/order/certificate/wishlist; entitlement cho library/tệp | Auth, checkout, certificates, library, downloads tests | PASS |
| Headers browser | Helmet CSP, `frame-ancestors 'none'`, frame deny, no-sniff, referrer policy | `security.integration.test.js` header assertions | PASS |
| Validation/SQL injection | Bounded validation tại routes; Prisma parameterization; raw SQL duy nhất là tagged `SELECT … FOR UPDATE` cho coupon | Static source audit; catalog/promotions tests | PASS |
| Upload/tệp riêng | Không mount static uploads; private storage; random key; path containment; allow-list MIME/extension và file signature | `downloads.integration.test.js` valid/disguised upload; traversal unit assertion | PASS |
| Download token | 32-byte random token, SHA-256 hash only, 10 phút, one use, ownership/entitlement check, cache no-store | Downloads test: unauthorized, expired, reused, revoked, valid | PASS |
| Payments/coupon | Server recomputes totals; VNPay HMAC + amount/reference validation; callbacks idempotent; coupon row lock and atomic usage | Checkout/promotions/VNPay integration tests | PASS |
| Audit trail | Login, order, payment/COD, entitlement, certificate, course-file and download-token actions audited | Service/route source audit plus integration tests | PASS |
| Secrets/repository | `.env` ignored; `.env.example` placeholders only; private files/backups ignored; no production secrets intentionally printed | `git ls-files`/pattern audit | PASS |
| Backup/restore | PowerShell scripts use `DATABASE_URL`, no password literals; destructive restore requires `-Force`; archive dry-run uses `pg_restore --list` | PowerShell parser passed for all three scripts. `pg_dump`/`pg_restore` are not installed in this workspace, so a real archive/restore drill could not safely run. | NEEDS REVIEW: run the documented disposable-database drill before production. |
| Legal content | Public seller, terms, refund and privacy content available at `/api/policies` | Policy route test | Implementation present; production legal review required. |

## Production considerations

- Configure a long random `SESSION_SECRET`, explicit HTTPS origin(s) in `CORS_ORIGINS`, `NODE_ENV=production`, and HTTPS termination before deployment. Set `TRUST_PROXY=true` only for one known reverse proxy.
- `npm audit` was rerun after upgrading runtime `multer` to 2.4.0 and `bcrypt` to 6.0.0; it reported 0 vulnerabilities.
- Use managed secret storage, central logging with redaction, monitored rate-limit storage (not in-memory), TLS, database least privilege, malware scanning, object storage controls and regular restore drills.
- Cookie/session invalidation is database-backed; consider a dedicated session table or identity provider if per-device session management is required.
- Policy text is demo content. Implementation present; production legal review required.
