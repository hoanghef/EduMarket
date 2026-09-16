# EduMarket Project TODO

## Current Status
- Current phase: 1. Project Setup
- Current task: Initialize repository structure and backend/frontend scaffolding
- Last completed task: None (Project initialized)
- Blocking issues: None
- Next recommended task: Set up repository structure, backend Node.js + Express, and Flutter Web frontend

## Progress Summary
| Phase | Status | Notes |
| :--- | :--- | :--- |
| 1. Project Setup | NOT STARTED | |
| 2. Database | NOT STARTED | |
| 3. Authentication and Security Foundation | NOT STARTED | |
| 4. Course Catalog Backend | NOT STARTED | |
| 5. Flutter Core UI | NOT STARTED | |
| 6. Flutter Course Catalog | NOT STARTED | |
| 7. Cart | NOT STARTED | |
| 8. Coupons | NOT STARTED | |
| 9. Checkout and Orders | NOT STARTED | |
| 10. VNPay Sandbox | NOT STARTED | |
| 11. Digital Course Entitlement | NOT STARTED | |
| 12. Customer Library | NOT STARTED | |
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
- [ ] repository structure
- [ ] Flutter Web frontend setup
- [ ] Node.js + Express backend setup
- [ ] PostgreSQL
- [ ] Prisma
- [ ] environment configuration
- [ ] health API
- [ ] Flutter API connection
- [ ] Git initialization/checkpoint

## 2. Database
- [ ] Prisma schema
- [ ] enums
- [ ] User
- [ ] Category
- [ ] Course
- [ ] Lesson
- [ ] CourseFile
- [ ] Cart
- [ ] CartItem
- [ ] Order
- [ ] OrderItem
- [ ] Payment
- [ ] CourseEntitlement
- [ ] CourseProgress
- [ ] DownloadToken
- [ ] Certificate
- [ ] Review
- [ ] Wishlist
- [ ] Coupon
- [ ] CouponUsage
- [ ] AuditLog
- [ ] migrations
- [ ] seed data
- [ ] database documentation
- [ ] database verification

## 3. Authentication and Security Foundation
- [ ] register
- [ ] login
- [ ] logout
- [ ] current user
- [ ] bcrypt
- [ ] HttpOnly cookies
- [ ] SameSite
- [ ] Secure cookie production config
- [ ] CSRF
- [ ] CORS
- [ ] role authorization
- [ ] login rate limiting
- [ ] 5 failed login lockout
- [ ] audit login
- [ ] auth automated tests

## 4. Course Catalog Backend
- [ ] category API
- [ ] course listing
- [ ] search
- [ ] filters
- [ ] sorting
- [ ] pagination
- [ ] course detail
- [ ] recommendations
- [ ] admin course CRUD
- [ ] admin category CRUD
- [ ] API tests

## 5. Flutter Core UI
- [ ] app theme
- [ ] responsive breakpoints
- [ ] router
- [ ] AppShell
- [ ] navbar
- [ ] footer
- [ ] loading state
- [ ] empty state
- [ ] error state
- [ ] desktop
- [ ] tablet
- [ ] mobile

## 6. Flutter Course Catalog
- [ ] home page
- [ ] featured categories
- [ ] best sellers
- [ ] new courses
- [ ] top rated courses
- [ ] course listing
- [ ] filters
- [ ] search
- [ ] sort
- [ ] pagination
- [ ] course detail
- [ ] recommendation section
- [ ] real API integration
- [ ] browser verification

## 7. Cart
- [ ] backend cart API
- [ ] add course
- [ ] remove course
- [ ] duplicate prevention
- [ ] already-owned course prevention
- [ ] Flutter cart page
- [ ] cart tests

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
- [ ] checkout transaction
- [ ] server-side price calculation
- [ ] immutable order items
- [ ] COD option
- [ ] VNPay option
- [ ] order history
- [ ] order detail
- [ ] order status
- [ ] Flutter checkout
- [ ] Flutter order pages
- [ ] tests

## 10. VNPay Sandbox
- [ ] create payment
- [ ] return URL
- [ ] IPN
- [ ] signature verification
- [ ] amount verification
- [ ] idempotency
- [ ] payment update
- [ ] order update
- [ ] audit logs
- [ ] duplicate callback prevention
- [ ] Sandbox documentation
- [ ] integration tests

## 11. Digital Course Entitlement
- [ ] grantOrderEntitlements
- [ ] grantCourseAccess
- [ ] revokeCourseAccess
- [ ] restoreCourseAccess
- [ ] ACTIVE entitlement
- [ ] REVOKED entitlement
- [ ] protected course API
- [ ] COD grant flow
- [ ] VNPay grant flow
- [ ] admin entitlement APIs
- [ ] tests

## 12. Customer Library
- [ ] library API
- [ ] purchased course list
- [ ] protected course detail
- [ ] Flutter library page
- [ ] continue learning
- [ ] revoked access state
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
- [ ] lesson completion
- [ ] idempotent completion
- [ ] progress calculation
- [ ] progress API
- [ ] Flutter progress UI
- [ ] tests

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
- [ ] Flutter analyze
- [ ] Flutter test
- [ ] Flutter build web

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
- [ ] README
- [ ] INSTALL guide
- [ ] .env.example
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
