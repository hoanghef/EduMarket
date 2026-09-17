const bcrypt = require("bcrypt");
const { PrismaClient, CourseLevel, CourseStatus, DiscountType, Role } = require("../src/generated/prisma");

const prisma = new PrismaClient();
const SEED_PASSWORD = "EduMarket@2026";

const categoryTree = [
  { name: "Lập trình", slug: "lap-trinh", children: [["Phát triển Web", "phat-trien-web"], ["Phát triển Di động", "phat-trien-di-dong"]] },
  { name: "Dữ liệu", slug: "du-lieu", children: [["Cơ sở dữ liệu", "co-so-du-lieu"], ["Phân tích dữ liệu", "phan-tich-du-lieu"]] },
  { name: "Thiết kế", slug: "thiet-ke", children: [["UI/UX", "ui-ux"], ["Thiết kế đồ họa", "thiet-ke-do-hoa"]] },
  { name: "Kinh doanh", slug: "kinh-doanh", children: [["Marketing số", "marketing-so"], ["Quản lý dự án", "quan-ly-du-an"]] },
];

const courseData = [
  ["Flutter Web từ cơ bản đến thực hành", "flutter-web-tu-co-ban-den-thuc-hanh", "phat-trien-di-dong", "Nguyễn Minh Anh", "BEGINNER", "790000", "590000"],
  ["Node.js và Express cho người mới", "nodejs-express-cho-nguoi-moi", "phat-trien-web", "Trần Quốc Bảo", "BEGINNER", "690000", null],
  ["React hiện đại với TypeScript", "react-hien-dai-voi-typescript", "phat-trien-web", "Lê Hoàng Nam", "INTERMEDIATE", "890000", "690000"],
  ["Xây dựng REST API an toàn", "xay-dung-rest-api-an-toan", "phat-trien-web", "Phạm Gia Huy", "INTERMEDIATE", "850000", null],
  ["Python nhập môn", "python-nhap-mon", "phan-tich-du-lieu", "Vũ Thanh Hà", "BEGINNER", "550000", "390000"],
  ["SQL và PostgreSQL thực chiến", "sql-va-postgresql-thuc-chien", "co-so-du-lieu", "Đỗ Minh Tuấn", "INTERMEDIATE", "750000", "590000"],
  ["Thiết kế cơ sở dữ liệu chuẩn hóa", "thiet-ke-co-so-du-lieu-chuan-hoa", "co-so-du-lieu", "Đỗ Minh Tuấn", "INTERMEDIATE", "680000", null],
  ["Power BI cho phân tích kinh doanh", "power-bi-cho-phan-tich-kinh-doanh", "phan-tich-du-lieu", "Ngô Khánh Linh", "BEGINNER", "720000", "520000"],
  ["Figma UI/UX từ nền tảng", "figma-ui-ux-tu-nen-tang", "ui-ux", "Mai Thu Trang", "BEGINNER", "620000", "450000"],
  ["Thiết kế trải nghiệm người dùng", "thiet-ke-trai-nghiem-nguoi-dung", "ui-ux", "Mai Thu Trang", "INTERMEDIATE", "780000", null],
  ["Adobe Photoshop cơ bản", "adobe-photoshop-co-ban", "thiet-ke-do-hoa", "Bùi Ngọc Anh", "BEGINNER", "500000", "350000"],
  ["Nhận diện thương hiệu chuyên nghiệp", "nhan-dien-thuong-hieu-chuyen-nghiep", "thiet-ke-do-hoa", "Lương Hải Yến", "ADVANCED", "950000", "750000"],
  ["Digital Marketing toàn diện", "digital-marketing-toan-dien", "marketing-so", "Hoàng Đức Long", "BEGINNER", "800000", "600000"],
  ["SEO thực hành cho website", "seo-thuc-hanh-cho-website", "marketing-so", "Trịnh Quang Vinh", "INTERMEDIATE", "650000", null],
  ["Content Marketing hiệu quả", "content-marketing-hieu-qua", "marketing-so", "Hoàng Đức Long", "BEGINNER", "580000", "430000"],
  ["Quản lý dự án với Agile", "quan-ly-du-an-voi-agile", "quan-ly-du-an", "Nguyễn Thùy Dương", "INTERMEDIATE", "760000", null],
  ["Scrum Master nền tảng", "scrum-master-nen-tang", "quan-ly-du-an", "Nguyễn Thùy Dương", "BEGINNER", "680000", "510000"],
  ["Dart chuyên sâu", "dart-chuyen-sau", "phat-trien-di-dong", "Nguyễn Minh Anh", "ADVANCED", "840000", null],
  ["Docker cho lập trình viên", "docker-cho-lap-trinh-vien", "phat-trien-web", "Phạm Gia Huy", "INTERMEDIATE", "700000", "540000"],
  ["Excel phân tích dữ liệu", "excel-phan-tich-du-lieu", "phan-tich-du-lieu", "Vũ Thanh Hà", "BEGINNER", "480000", "320000"],
];

async function main() {
  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 12);
  const accounts = [
    ["admin@edumarket.local", "Quản trị viên EduMarket", Role.ADMIN],
    ["an.nguyen@edumarket.local", "Nguyễn Ngọc An", Role.CUSTOMER],
    ["binh.tran@edumarket.local", "Trần Gia Bình", Role.CUSTOMER],
    ["chi.le@edumarket.local", "Lê Mỹ Chi", Role.CUSTOMER],
    ["dung.pham@edumarket.local", "Phạm Quốc Dũng", Role.CUSTOMER],
    ["han.vu@edumarket.local", "Vũ Thu Hân", Role.CUSTOMER],
  ];

  for (const [email, fullName, role] of accounts) {
    await prisma.user.upsert({
      where: { email },
      update: { fullName, role, passwordHash, isActive: true },
      create: { email, fullName, role, passwordHash },
    });
  }

  for (const [parentIndex, item] of categoryTree.entries()) {
    const parent = await prisma.category.upsert({
      where: { slug: item.slug },
      update: { name: item.name, sortOrder: parentIndex + 1, isActive: true },
      create: { name: item.name, slug: item.slug, sortOrder: parentIndex + 1 },
    });
    for (const [childIndex, [name, slug]] of item.children.entries()) {
      await prisma.category.upsert({
        where: { slug },
        update: { name, parentId: parent.id, sortOrder: childIndex + 1, isActive: true },
        create: { name, slug, parentId: parent.id, sortOrder: childIndex + 1 },
      });
    }
  }

  const categories = await prisma.category.findMany({ select: { id: true, slug: true } });
  const categoryIds = new Map(categories.map((category) => [category.slug, category.id]));
  for (const [index, [title, slug, categorySlug, instructorName, level, price, salePrice]] of courseData.entries()) {
    const course = await prisma.course.upsert({
      where: { slug },
      update: { title, categoryId: categoryIds.get(categorySlug), instructorName, level, price, salePrice, status: CourseStatus.PUBLISHED },
      create: {
        title,
        slug,
        categoryId: categoryIds.get(categorySlug),
        instructorName,
        shortDescription: `Khóa học ${title} bằng tiếng Việt.`,
        description: `Nội dung thực hành giúp học viên nắm vững ${title}.`,
        level,
        price,
        salePrice,
        status: CourseStatus.PUBLISHED,
        publishedAt: new Date(),
        ratingAverage: (4 + (index % 10) / 10).toFixed(2),
        ratingCount: 10 + index,
        enrollmentCount: 30 + index * 7,
      },
    });
    await prisma.lesson.createMany({
      data: [
        { courseId: course.id, title: "Giới thiệu khóa học", position: 1, durationSec: 300, isPreview: true },
        { courseId: course.id, title: "Kiến thức nền tảng", position: 2, durationSec: 900 },
        { courseId: course.id, title: "Bài thực hành", position: 3, durationSec: 1200 },
      ],
      skipDuplicates: true,
    });
  }

  const customers = await prisma.user.findMany({ where: { role: Role.CUSTOMER }, select: { id: true } });
  for (const customer of customers) {
    await prisma.cart.upsert({ where: { userId: customer.id }, update: {}, create: { userId: customer.id } });
  }

  const now = new Date();
  const endsAt = new Date(now);
  endsAt.setMonth(endsAt.getMonth() + 3);
  const coupons = [
    ["WELCOME10", "Giảm 10% cho đơn hàng đầu tiên", DiscountType.PERCENTAGE, "10", "300000", "100000", 500, 1],
    ["HOC500K", "Giảm 50.000đ cho đơn từ 500.000đ", DiscountType.FIXED, "50000", "500000", null, 300, 1],
    ["STUDENT20", "Ưu đãi sinh viên giảm 20%", DiscountType.PERCENTAGE, "20", "600000", "150000", 100, 1],
  ];
  for (const [code, description, discountType, discountValue, minimumOrderAmount, maximumDiscountAmount, usageLimit, perUserLimit] of coupons) {
    await prisma.coupon.upsert({
      where: { code },
      update: { description, discountType, discountValue, minimumOrderAmount, maximumDiscountAmount, usageLimit, perUserLimit, startsAt: now, endsAt, isActive: true },
      create: { code, description, discountType, discountValue, minimumOrderAmount, maximumDiscountAmount, usageLimit, perUserLimit, startsAt: now, endsAt },
    });
  }

  console.log(`Seed hoàn tất: ${accounts.length} tài khoản, ${categoryTree.length} danh mục cha, ${courseData.length} khóa học, ${coupons.length} mã giảm giá.`);
  console.log(`Mật khẩu mẫu (đã băm bcrypt): ${SEED_PASSWORD}`);
}

main()
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
