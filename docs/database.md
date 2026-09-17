# Cơ sở dữ liệu EduMarket

## Tổng quan

EduMarket dùng PostgreSQL và Prisma ORM. Schema nguồn nằm tại `backend/prisma/schema.prisma`; migration đầu tiên nằm trong `backend/prisma/migrations/`. Tất cả giá tiền dùng `Decimal(12,2)` để tránh sai số số thực.

Không ghi thông tin kết nối thật vào tài liệu hoặc Git. Sao chép `backend/.env.example` thành `backend/.env`, sau đó đặt `DATABASE_URL` cho PostgreSQL cục bộ.

## Khởi tạo

Chạy các lệnh từ thư mục `backend`:

```powershell
npm.cmd run db:generate
npx.cmd prisma migrate dev --name init_database
npm.cmd run db:seed
```

Để xem dữ liệu trực quan trong môi trường phát triển, có thể chạy `npx.cmd prisma studio`.

## Mô hình dữ liệu

- `User`: tài khoản khách hàng hoặc quản trị viên; có mật khẩu băm, trạng thái khóa đăng nhập và quan hệ với đơn hàng, quyền học, tiến độ, đánh giá, yêu thích, mã giảm giá và nhật ký.
- `Category`: danh mục đa cấp qua `parentId`; một danh mục có thể có nhiều danh mục con và khóa học.
- `Course`, `Lesson`, `CourseFile`: nội dung bán; bài học có vị trí duy nhất trong khóa học. Tệp dùng `storageKey` riêng tư, không có URL công khai.
- `Cart`, `CartItem`: mỗi người dùng có tối đa một giỏ; một khóa học chỉ xuất hiện một lần trong giỏ.
- `Order`, `OrderItem`, `Payment`: dữ liệu giao dịch. `OrderItem` giữ tiêu đề, slug và giá tại thời điểm mua để bảo toàn lịch sử.
- `CourseEntitlement`: quyền truy cập theo người dùng/khóa học, có thể `ACTIVE` hoặc `REVOKED`.
- `CourseProgress`: một bản ghi hoàn thành cho mỗi cặp người dùng/bài học; ràng buộc duy nhất làm thao tác hoàn thành có tính idempotent.
- `DownloadToken`: chỉ lưu `tokenHash`, thời hạn, số lượt tải và giới hạn lượt tải. Token thuần chỉ được tạo trong bộ nhớ khi endpoint tải xuống được xây dựng ở giai đoạn sau.
- `Certificate`: một chứng chỉ duy nhất cho mỗi người dùng/khóa học.
- `Review`, `Wishlist`: mỗi người dùng chỉ có một đánh giá và một mục yêu thích trên mỗi khóa học.
- `Coupon`, `CouponUsage`: hỗ trợ phần trăm/giảm cố định, thời gian hiệu lực, giá trị đơn tối thiểu, giảm tối đa, giới hạn tổng và giới hạn từng người dùng.
- `AuditLog`: lưu hành động nhạy cảm cùng người dùng, đối tượng, IP, metadata JSON và thời gian.

## Enum chính

`Role` gồm `CUSTOMER`, `ADMIN`. Các enum nghiệp vụ còn lại là `CourseStatus`, `CourseLevel`, `OrderStatus`, `PaymentStatus`, `PaymentMethod`, `EntitlementStatus`, `ReviewStatus` và `DiscountType`.

## Ràng buộc và chỉ mục quan trọng

- Email, slug danh mục/khóa học, mã đơn, mã chứng chỉ, mã coupon, `storageKey`, `tokenHash` và mã giao dịch thanh toán là duy nhất.
- Các tổ hợp duy nhất ngăn dữ liệu trùng: giỏ/khóa học, đơn/khóa học, người dùng/khóa học cho quyền học, đánh giá, yêu thích và chứng chỉ, cùng người dùng/bài học cho tiến độ.
- Có chỉ mục cho truy vấn catalog (trạng thái, danh mục, cấp độ, giá, đánh giá, độ phổ biến), danh mục cha, đơn hàng, thanh toán, quyền học, token hết hạn, đánh giá, coupon và audit log.
- Các quan hệ xóa được chọn theo nghiệp vụ: dữ liệu nội dung phụ thuộc được xóa cùng khóa học; đơn hàng, thanh toán, quyền học và lịch sử liên quan dùng `Restrict` khi cần giữ dấu vết giao dịch.

## Dữ liệu mẫu

Seed có tính lặp lại an toàn (upsert và `skipDuplicates`) và tạo:

- 1 quản trị viên và 5 khách hàng;
- 4 danh mục cha, mỗi danh mục có 2 danh mục con;
- 20 khóa học tiếng Việt, mỗi khóa có 3 bài học;
- 3 coupon còn hiệu lực và giỏ hàng trống cho mỗi khách hàng.

Tất cả tài khoản mẫu dùng mật khẩu `EduMarket@2026`, được băm bằng bcrypt với cost 12 trước khi ghi xuống cơ sở dữ liệu. Không có mật khẩu thuần trong bản ghi `User`.

Tài khoản quản trị: `admin@edumarket.local`.

## Truy vấn kiểm tra mẫu

```javascript
await prisma.course.count({ where: { status: "PUBLISHED" } });
await prisma.category.findMany({ where: { parentId: null }, include: { children: true } });
await prisma.course.findMany({ take: 3, include: { lessons: true } });
await prisma.coupon.findMany({ where: { isActive: true } });
```

Khi triển khai API, việc tạo download token phải sinh chuỗi ngẫu nhiên, băm bằng SHA-256 hoặc thuật toán phù hợp trước khi lưu vào `DownloadToken.tokenHash`, và chỉ trả token thuần một lần trong URL tạm thời.
