# EduMarket security checklist

Scope: Express/Prisma backend and Flutter Web integration for the course project. This is implementation and test evidence for a demo system, not production security certification.

| Area | Implementation / evidence | Status |
| --- | --- | --- |
| Passwords and login | bcrypt cost 12, five-failure 15-minute lockout, login rate limit, LOGIN_SUCCESS and LOGIN_FAILED audits; auth integration tests | PASS |
| Session and logout | Signed HttpOnly cookie, SameSite configuration, Secure forced in production, sessionVersion invalidation; auth tests | PASS |
| CSRF and CORS | Double-submit CSRF for unsafe methods; credentials restricted to CORS allow-list; production requires CORS_ORIGINS | PASS |
| RBAC and IDOR | requireAuth/requireCustomer/requireAdmin plus ownership and entitlement queries; checkout/certificate/download/library tests | PASS |
| Security headers | Helmet CSP, frame-ancestors none, frame deny, no-sniff and referrer policy; security integration assertions | PASS |
| Input validation / SQL injection | Bounded route validation and Prisma parameterization; coupon locking uses tagged SELECT FOR UPDATE | PASS |
| Private uploads/files | No public upload mount; random storage keys, containment checks, MIME/extension/signature validation | PASS |
| Download tokens | 32-byte random token, SHA-256 hash only, 10-minute expiry, one-use, entitlement and owner checks, no-store | PASS |
| Payment and coupon integrity | Server-recalculated totals, VNPay HMAC/amount/reference checks, callback idempotency, coupon locking | PASS |
| Audit trail | Auth, orders, payment/COD, entitlements, certificate, course-file and download actions are logged | PASS |
| Secrets and repository | .env/private storage/dumps ignored; .env.example has placeholders; final audit removed a tracked cookie artifact | PASS |
| Backup and restore | Scripts are parser-checked and require explicit Force for restore; live archive/restore drill needs PostgreSQL client tools | NEEDS REVIEW |
| Legal/policy content | Public seller, terms, refund and privacy API/page content exists; production legal review remains necessary | NEEDS REVIEW |

## Production considerations

- Use a long random SESSION_SECRET, HTTPS, explicit production CORS origins, least-privilege database credentials, and trusted proxy configuration only when applicable.
- Store secrets in a managed secret service, centralize/redact logs, use a shared monitored rate-limit store, scan uploads, and conduct regular disposable-database restore drills.
- A real VNPay Sandbox callback requires valid merchant credentials and a public HTTPS endpoint. Local signed fixtures are deterministic backend coverage, not a live payment certification.

See docs/final-requirement-audit.md for the complete Prompt 19 audit and its remaining payment-related blockers.
