# Tài liệu Kỹ thuật SEO & Metadata — EduMarket

Tài liệu này mô tả chi tiết chiến lược SEO (Search Engine Optimization), quản lý metadata, structured data (JSON-LD), sitemap, robots.txt, và các lưu ý triển khai cho ứng dụng EduMarket (Flutter Web & Node.js/Express Backend).

---

## 1. Kiến trúc Định tuyến (URL / Routing Strategy)

EduMarket sử dụng chiến lược URL không chứa dấu băm (**non-hash path URL strategy**):
- **Cấu hình Flutter Web**: Sử dụng `usePathUrlStrategy()` từ `package:flutter_web_plugins/url_strategy.dart` khởi tạo tại `lib/main.dart`.
- **Cấu trúc URL công khai thân thiện (SEO-friendly slugs)**:
  - Trang chủ: `/`
  - Danh mục khóa học: `/khoa-hoc`
  - Chi tiết khóa học: `/khoa-hoc/:slug` (ví dụ: `/khoa-hoc/nodejs-express-cho-nguoi-moi`)
  - Khóa học theo danh mục: `/danh-muc/:slug` (ví dụ: `/danh-muc/phat-trien-web`)
  - Xác thực chứng chỉ: `/certificates/verify` và `/certificates/verify/:code`
  - Trang chính sách & điều khoản: `/chinh-sach/:slug` (`business`, `terms`, `refunds`, `privacy`)
  - Trang ưu đãi & khuyến mại: `/khuyen-mai`

---

## 2. Chiến lược Tiêu đề & Mô tả (Page Titles & Meta Descriptions)

Metadata được cập nhật động trong runtime Flutter Web thông qua lớp trừu tượng `SeoHelper` (`lib/core/seo/seo_helper.dart`) và mô hình dữ liệu `SeoData` (`lib/core/seo/seo_data.dart`).

### Nguyên tắc tiêu đề (Title):
- Luôn gắn liền tên nội dung với nhận diện thương hiệu `| EduMarket`.
- Trang chủ: `EduMarket — Nền tảng Khóa học Trực tuyến & Tài liệu Lập trình`
- Khóa học: `[Tên khóa học] | EduMarket`
- Danh mục: `Khóa học [Tên danh mục] | EduMarket`
- Khuyến mại: `Ưu đãi & Khuyến mại Khóa học | EduMarket`
- Chính sách: `[Tên chính sách] | EduMarket`
- Đồng bộ tiêu đề ứng dụng thông qua cả `SystemChrome.setApplicationSwitcherDescription` (cho tab/switcher OS) và trực tiếp vào `document.title` của DOM trình duyệt.

### Nguyên tắc mô tả (Description):
- Tối đa 160 ký tự, trích xuất từ dữ liệu thực tế (`shortDescription`, `description` hoặc nội dung chính thức).
- Không để lộ thông tin riêng tư của người dùng hoặc các thông tin bảo mật nội bộ.
- Khóa học: Sử dụng trực tiếp `course.shortDescription` từ API backend.

---

## 3. Canonical URLs

Để tránh lỗi trùng lặp chỉ mục (duplicate content indexing) khi người dùng truy cập qua query parameters (như phân trang `?page=2`, tìm kiếm `?q=...`, bộ lọc giá `?sort=...`):
- Thẻ `<link rel="canonical" href="...">` được tự động tạo và gán vào thẻ `<head>` của DOM.
- URL Canonical luôn chuẩn hóa về đường dẫn gốc không chứa query lọc tạm thời.
- Ví dụ: Bất kể query bộ lọc trên `/khoa-hoc?category=1&sort=price_asc`, canonical URL luôn trả về `http://localhost:3000/khoa-hoc` (hoặc domain production thực tế).

---

## 4. OpenGraph Metadata (Chia sẻ Mạng xã hội)

Mỗi trang công khai được trang bị các thẻ OpenGraph cơ bản phục vụ hiển thị preview trên Facebook, Zalo, LinkedIn, Twitter/X:
- `og:title`: Khớp với tiêu đề trang SEO.
- `og:description`: Khớp với meta description.
- `og:type`: `website` cho trang danh mục/thông tin chung, hoặc `article` cho chi tiết khóa học.
- `og:url`: URL canonical của trang hiện tại.
- `og:image`: Đối với khóa học, chỉ chèn thẻ `og:image` khi `thumbnailUrl` là đường dẫn hợp lệ; tuyệt đối không tạo link ảnh giả định hoặc link hỏng.

---

## 5. Dữ liệu có cấu trúc (Structured Data / JSON-LD)

Được nhúng trực tiếp qua thẻ `<script type="application/ld+json">` trong DOM trình duyệt (`lib/core/seo/seo_dom_web.dart`).

### Chi tiết khóa học (`Course` & `Product`):
- **`@type: "Course"`**: Khai báo `@context`, `name`, `description`, `provider` (EduMarket), `offers`.
- **`@type: "Product"`**: Khai báo giá bán thực tế (`price`), đơn vị tiền tệ (`VND`), tình trạng còn hàng (`InStock`).
- **Đánh giá & Xếp hạng (`aggregateRating`)**: **Chỉ xuất hiện khi khóa học có đánh giá thực tế** (`ratingCount > 0`). Nếu khóa học chưa có lượt đánh giá nào, schema tuyệt đối không bịa đặt số sao hay số lượng đánh giá ảo để đảm bảo tính trung thực và tuân thủ Google Rich Results Guidelines.
- **BreadcrumbList**: Cung cấp cấu trúc điều hướng phân cấp (Trang chủ > Khóa học > [Tên khóa học]).

---

## 6. Sitemap (sitemap.xml)

Backend cung cấp endpoint động:
```http
GET /sitemap.xml
Content-Type: application/xml; charset=utf-8
```
- **Triển khai**: `backend/src/routes/seo.js` kết nối trực tiếp Prisma Client để lấy toàn bộ khóa học có trạng thái `PUBLISHED` và các danh mục đang hoạt động (`isActive: true`).
- **URL công khai được lập chỉ mục**:
  - Trang chủ (`priority: 1.0`, `changefreq: daily`)
  - Danh mục khóa học (`/khoa-hoc`)
  - Trang ưu đãi (`/khuyen-mai`)
  - Trang tra cứu chứng chỉ (`/certificates/verify`)
  - Các trang chính sách người bán & pháp lý (`/chinh-sach/business`, `terms`, `refunds`, `privacy`)
  - Từng danh mục sản phẩm công khai (`/danh-muc/:slug`)
  - Từng khóa học đã xuất bản (`/khoa-hoc/:slug`) với ngày cập nhật `lastmod` lấy từ `updatedAt`.
- **Các trang bị loại trừ khỏi sitemap**:
  - Các trang xác thực: `/login`, `/register`
  - Các trang giao dịch: `/cart`, `/checkout`
  - Các trang tài khoản cá nhân: `/account`, `/account/*`, `/account/orders`
  - Thư viện học tập: `/library`, `/library/*`
  - Trang quản trị: `/admin`, `/admin/*`
  - Các endpoint tải tài liệu bảo mật và API nội bộ: `/api/*`

---

## 7. Quy tắc Robots (robots.txt)

Được phục vụ từ 2 nguồn:
1. Backend: `GET /robots.txt` (định tuyến `backend/src/routes/seo.js`).
2. Frontend Web tĩnh: `frontend/web/robots.txt` (dành cho CDN/Web server phục vụ trực tiếp thư mục `build/web`).

Nội dung cấu hình chuẩn:
```txt
User-agent: *
Allow: /
Allow: /khoa-hoc
Allow: /khoa-hoc/*
Allow: /danh-muc/*
Allow: /certificates/verify
Allow: /certificates/verify/*
Allow: /chinh-sach/*
Allow: /khuyen-mai

# Disallow private and authenticated user routes
Disallow: /admin
Disallow: /admin/*
Disallow: /account
Disallow: /account/*
Disallow: /cart
Disallow: /checkout
Disallow: /library
Disallow: /library/*
Disallow: /login
Disallow: /register
Disallow: /api/

Sitemap: http://localhost:4000/sitemap.xml
```

---

## 8. Bảo vệ Chỉ mục Trang Riêng tư (Indexing Safety)

Mọi trang riêng tư và xác thực đều gọi:
```dart
SeoHelper.apply(SeoData.private(title: '... | EduMarket'));
```
- Tự động thiết lập thẻ:
  ```html
  <meta name="robots" content="noindex, nofollow">
  ```
- Đồng thời gỡ bỏ thẻ canonical và OpenGraph tương ứng để ngăn chặn bot tìm kiếm lập chỉ mục các trang giỏ hàng, thanh toán, tài khoản và admin dashboard.

---

## 9. Cấu hình Máy chủ Web phục vụ SPA Direct Route Refresh

Do Flutter Web sử dụng HTML5 History API (`PathUrlStrategy`), khi người dùng truy cập trực tiếp hoặc bấm F5 tải lại một trang con (ví dụ: `https://edumarket.vn/khoa-hoc/nodejs-express-cho-nguoi-moi`), máy chủ HTTP phải chuyển hướng yêu cầu đó về file `index.html` thay vì trả về lỗi 404 Not Found.

### Môi trường Cục bộ / Node.js Serve:
Sử dụng cờ `-s` (single-page rewrite):
```bash
npx serve -s build/web -l 3000 --no-clipboard
```

### Môi trường Production Nginx:
Thêm cấu hình `try_files` trong block server:
```nginx
server {
    listen 80;
    server_name edumarket.vn;
    root /var/www/edumarket/build/web;
    index index.html;

    # Hỗ trợ direct refresh cho Flutter Web Path URLs
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Phục vụ robots.txt và favicon
    location = /robots.txt {
        log_not_found off;
        access_log off;
    }

    # Proxy API và sitemap sang Node.js Backend
    location /api/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location = /sitemap.xml {
        proxy_pass http://127.0.0.1:4000/sitemap.xml;
    }
}
```

### Môi trường Firebase Hosting:
Cấu hình trong `firebase.json`:
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## 10. Các Giới hạn SEO đã biết của Flutter Web (Known Limitations)

- **Không có SSR (Server-Side Rendering)**: Hệ thống hiện tại **KHÔNG** sử dụng SSR. Ứng dụng là Client-Side Rendered (CSR) Single-Page Application (SPA) trên Flutter Web engine (HTML/CanvasKit/Wasm).
- **Thu thập dữ liệu của Web Crawler**: Các bot tìm kiếm hiện đại hỗ trợ JavaScript (như Googlebot) có thể thực thi JavaScript và thu thập DOM động sau khi Flutter Web hoàn tất khởi tạo. Tuy nhiên, các bot cũ hoặc trình xem trước mạng xã hội không hỗ trợ render JS đầy đủ (ví dụ một số crawler của chat client cũ) có thể chỉ nhận được thẻ HTML cơ bản trong `index.html`.
- **Giải pháp tối ưu hóa tương lai**: Nếu cần tương thích tuyệt đối 100% với crawler mạng xã hội cũ không chạy JS, có thể triển khai thêm giải pháp Pre-rendering hoặc dynamic reverse proxy (như Rendertron hoặc Prerender.io) tại lớp Nginx/Cloudflare phía trước.
