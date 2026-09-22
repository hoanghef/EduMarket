import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:edumarket/core/router/app_router.dart';
import 'package:edumarket/core/theme/app_theme.dart';
import 'package:edumarket/core/api/health_repository.dart';
import 'package:edumarket/core/widgets/app_shell.dart';
import 'package:edumarket/features/home/home_screen.dart';
import 'package:edumarket/features/auth/models/user_model.dart';
import 'package:edumarket/features/auth/providers/auth_provider.dart';
import 'package:edumarket/features/auth/login_screen.dart';
import 'package:edumarket/features/auth/register_screen.dart';
import 'package:edumarket/features/courses/providers/catalog_provider.dart';
import 'package:edumarket/features/courses/models/catalog_models.dart';
import 'package:edumarket/features/cart/providers/cart_provider.dart';
import 'package:edumarket/features/cart/models/cart_models.dart';
import 'package:edumarket/features/cart/cart_screen.dart';
import 'package:edumarket/features/checkout/checkout_screen.dart';
import 'package:edumarket/features/orders/providers/order_provider.dart';
import 'package:edumarket/features/orders/models/order_models.dart';
import 'package:dio/dio.dart';
import 'package:edumarket/features/orders/order_history_screen.dart';
import 'package:edumarket/features/certificates/models/certificate_models.dart';
import 'package:edumarket/features/certificates/providers/certificate_provider.dart';
import 'package:edumarket/features/certificates/certificate_list_screen.dart';
import 'package:edumarket/features/certificates/certificate_verification_screen.dart';

import 'package:edumarket/features/wishlist/models/wishlist_model.dart';
import 'package:edumarket/features/wishlist/providers/wishlist_provider.dart';
import 'package:edumarket/features/wishlist/wishlist_screen.dart';
import 'package:edumarket/features/reviews/models/review_models.dart';
import 'package:edumarket/features/reviews/providers/review_provider.dart';
import 'package:edumarket/features/reviews/widgets/course_reviews_section.dart';
import 'package:edumarket/features/cart/models/coupon_model.dart';
import 'package:edumarket/features/cart/providers/coupon_provider.dart';
import 'package:edumarket/features/cart/widgets/coupon_input_card.dart';
import 'package:edumarket/features/admin/models/admin_models.dart';
import 'package:edumarket/features/admin/providers/admin_provider.dart';

// ── Fake Repositories ────────────────────────────────────────────────────────

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialUser});
  final UserModel? initialUser;
  UserModel? currentUser;

  @override
  Future<String> getCsrfToken() async => 'test-csrf-token';

  @override
  Future<UserModel> login(String email, String password) async {
    if (email == 'fail@example.com') {
      throw Exception('Invalid credentials');
    }
    currentUser = UserModel(
      id: 'test-user-id',
      email: email,
      fullName: 'Test Customer',
      role: 'CUSTOMER',
    );
    return currentUser!;
  }

  @override
  Future<UserModel> register(
    String email,
    String fullName,
    String password,
  ) async {
    currentUser = UserModel(
      id: 'new-user-id',
      email: email,
      fullName: fullName,
      role: 'CUSTOMER',
    );
    return currentUser!;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async => currentUser ?? initialUser;
}

class FakeCatalogRepository implements CatalogRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<CoursePage> getCourses(CatalogFilter filter) async {
    return const CoursePage(
      items: [],
      pagination: PaginationMeta(total: 0, page: 1, limit: 10, totalPages: 1),
    );
  }

  @override
  Future<CourseModel> getCourseBySlug(String slug) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CourseModel>> getRecommendations(String courseId) async => [];
}

class FakeCartRepository implements CartRepository {
  @override
  Future<CartModel> getCart() async {
    return CartModel(id: 'cart-1', userId: 'user-1', items: []);
  }

  @override
  Future<void> addToCart(String courseId) async {}

  @override
  Future<void> removeFromCart(String itemId) async {}
}

class FakeOrderRepository implements OrderRepository {
  @override
  Future<OrderModel> checkoutCod({String? couponCode}) async {
    return OrderModel(
      id: 'ord-123',
      orderNumber: 'ORD-123',
      subtotal: 0,
      discountAmount: 0,
      totalAmount: 0,
      status: 'PENDING',
      createdAt: DateTime.now(),
      items: [],
    );
  }

  @override
  Future<List<OrderModel>> getOrders() async => [];

  @override
  Future<OrderModel> getOrderDetail(String id) async {
    return OrderModel(
      id: id,
      orderNumber: 'ORD-$id',
      subtotal: 0,
      discountAmount: 0,
      totalAmount: 0,
      status: 'PENDING',
      createdAt: DateTime.now(),
      items: [],
    );
  }
}

class FakeCertificateRepository implements CertificateRepository {
  FakeCertificateRepository({this.certificates = const []});
  final List<CertificateItem> certificates;

  @override
  Future<List<CertificateItem>> getMyCertificates() async => certificates;

  @override
  Future<CertificateVerificationResult> verifyCertificate(String code) async {
    if (code == 'EDU-2026-F98B237DAABBCCDD11223344') {
      return CertificateVerificationResult(
        verified: true,
        certificateCode: code,
        studentName: 'Vũ Hoàng',
        courseName: 'Node.js và Express cho người mới',
        issuedAt: DateTime(2026, 9, 21),
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/api/certificates/$code/verify'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/certificates/$code/verify'),
        statusCode: 404,
        data: {'code': 'CERTIFICATE_NOT_FOUND', 'message': 'Not found'},
      ),
    );
  }

  @override
  Future<List<int>> downloadCertificatePdf(String code) async =>
      [37, 80, 68, 70, 45]; // %PDF-
}

class FakeWishlistRepository implements WishlistRepository {
  FakeWishlistRepository({List<WishlistItemModel>? initialItems})
      : items = List.of(initialItems ?? []);
  final List<WishlistItemModel> items;

  @override
  Future<List<WishlistItemModel>> getWishlist() async => List.of(items);

  @override
  Future<WishlistItemModel> addToWishlist(String courseId) async {
    final newItem = WishlistItemModel(
      id: 'fav-$courseId',
      userId: 'test-user-id',
      courseId: courseId,
      createdAt: DateTime.now(),
      course: CourseModel(
        id: courseId,
        title: 'Khóa học $courseId',
        slug: 'khoa-hoc-$courseId',
        instructorName: 'Giảng viên Test',
        price: 299000,
        salePrice: 199000,
        ratingAverage: 4.8,
        ratingCount: 10,
        enrollmentCount: 50,
        level: 'ALL_LEVELS',
        shortDescription: 'Mô tả khóa học kiểm thử',
        category: const CategoryModel(id: 'cat-1', name: 'Lập trình', slug: 'lap-trinh'),
      ),
    );
    items.add(newItem);
    return newItem;
  }

  @override
  Future<void> removeFromWishlist(String courseId) async {
    items.removeWhere((it) => it.courseId == courseId || it.course.id == courseId);
  }
}

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({
    this.reviews = const [],
    this.myReview,
  });
  final List<ReviewItemModel> reviews;
  MyReviewModel? myReview;

  @override
  Future<List<ReviewItemModel>> getCourseReviews(String courseId) async => reviews;

  @override
  Future<MyReviewModel?> getMyReview(String courseId) async => myReview;

  @override
  Future<MyReviewModel> submitReview({
    required String courseId,
    required int rating,
    String? comment,
  }) async {
    final submitted = MyReviewModel(
      id: 'rev-new',
      rating: rating,
      comment: comment,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
    myReview = submitted;
    return submitted;
  }
}

class FakeCouponRepository implements CouponRepository {
  @override
  Future<ValidatedCouponModel> validateCoupon(String couponCode) async {
    if (couponCode.toUpperCase() == 'GIAM10') {
      return const ValidatedCouponModel(
        code: 'GIAM10',
        discountType: 'PERCENTAGE',
        subtotal: 500000,
        discountAmount: 50000,
        totalAmount: 450000,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/api/coupons/validate'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/coupons/validate'),
        statusCode: 400,
        data: {'message': 'Mã giảm giá không hợp lệ hoặc đã hết hạn.'},
      ),
    );
  }
}

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({this.dashboardMetrics});
  final AdminDashboardMetrics? dashboardMetrics;

  @override
  Future<AdminDashboardMetrics> getDashboard() async {
    return dashboardMetrics ??
        const AdminDashboardMetrics(
          totalRevenue: 15000000,
          orderCount: 42,
          customerCount: 15,
          courseCount: 6,
          recentOrders: [],
          bestSellingCourses: [],
          monthlyRevenue: [],
        );
  }

  @override
  Future<AdminRevenueReportModel> getRevenueReport() async {
    return const AdminRevenueReportModel(
      totalRevenue: 15000000,
      totalDiscount: 500000,
      totalSubtotal: 15500000,
      paidOrdersCount: 42,
      codRevenue: 5000000,
      codCount: 15,
      vnpayRevenue: 10000000,
      vnpayCount: 27,
    );
  }

  @override
  Future<List<AdminOrderModel>> getOrders({String? status}) async => [];

  @override
  Future<void> confirmCodOrder(String orderId) async {}

  @override
  Future<List<AdminUserModel>> getUsers({String? role, String? q}) async => [];

  @override
  Future<List<AdminReviewModel>> getReviews({String? status}) async => [];

  @override
  Future<void> moderateReview(String reviewId, String status) async {}

  @override
  Future<List<AdminCouponModel>> getCoupons() async => [];

  @override
  Future<AdminCouponModel> createCoupon(Map<String, dynamic> data) async {
    return AdminCouponModel(
      id: 'cpn-1',
      code: data['code'] as String? ?? 'TEST',
      discountType: data['discountType'] as String? ?? 'PERCENTAGE',
      discountValue: 10,
      usageCount: 0,
      perUserLimit: 1,
      startsAt: DateTime.now(),
      endsAt: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    );
  }

  @override
  Future<void> toggleCouponActive(String id, bool isActive) async {}

  @override
  Future<List<AdminEntitlementModel>> getEntitlements({String? status}) async => [];

  @override
  Future<void> revokeEntitlement(String id, String reason) async {}

  @override
  Future<void> grantEntitlement({
    required String userId,
    required String courseId,
    required String orderId,
  }) async {}

  @override
  Future<List<CategoryModel>> getCategories() async => [];

  @override
  Future<void> createCategory(Map<String, dynamic> data) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<List<CourseModel>> getCourses() async => [];

  @override
  Future<void> updateCourseStatus(String courseId, String status) async {}

  @override
  Future<void> deleteCourse(String courseId) async {}
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  ProviderContainer createContainer({
    UserModel? loggedInUser,
    List<CertificateItem> certificates = const [],
    List<WishlistItemModel> wishlistItems = const [],
    List<ReviewItemModel> courseReviews = const [],
    MyReviewModel? myReview,
    AdminDashboardMetrics? adminDashboard,
  }) {
    return ProviderContainer(
      overrides: [
        healthProvider.overrideWith(
          (ref) async => const HealthStatus(
            status: 'ok',
            service: 'EduMarket API',
            version: '0.1.0',
            environment: 'test',
            timestamp: '2026-01-01T00:00:00.000Z',
          ),
        ),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUser: loggedInUser),
        ),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
        certificateRepositoryProvider.overrideWithValue(
          FakeCertificateRepository(certificates: certificates),
        ),
        wishlistRepositoryProvider.overrideWithValue(
          FakeWishlistRepository(initialItems: wishlistItems),
        ),
        reviewRepositoryProvider.overrideWithValue(
          FakeReviewRepository(reviews: courseReviews, myReview: myReview),
        ),
        couponRepositoryProvider.overrideWithValue(FakeCouponRepository()),
        adminRepositoryProvider.overrideWithValue(
          FakeAdminRepository(dashboardMetrics: adminDashboard),
        ),
      ],
    );
  }

  void setupDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget createTestApp(String initialLocation, ProviderContainer container) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
        GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
        GoRoute(path: '/account/orders', builder: (c, s) => const OrderHistoryScreen()),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpUntilResolved(WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('App renders EduMarket branding and Home Screen (empty state)', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(createTestApp('/', container));
    await pumpUntilResolved(tester);

    expect(find.text('EduMarket'), findsWidgets);
    expect(find.text('Chưa có khóa học'), findsWidgets);
    expect(find.text('Chưa có danh mục'), findsWidgets);
  });

  testWidgets('CartScreen renders empty cart state', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(createTestApp('/cart', container));
    await pumpUntilResolved(tester);

    expect(find.text('Giỏ hàng trống'), findsWidgets);
  });

  testWidgets('CheckoutScreen renders empty state when cart is empty', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(createTestApp('/checkout', container));
    await pumpUntilResolved(tester);

    expect(find.text('Giỏ hàng trống, không thể thanh toán'), findsWidgets);
    expect(find.text('Quay lại mua sắm'), findsWidgets);
  });

  testWidgets('OrderHistoryScreen renders empty state', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(createTestApp('/account/orders', container));
    await pumpUntilResolved(tester);

    expect(find.text('Bạn chưa có đơn hàng nào'), findsWidgets);
    expect(find.text('Khám phá khóa học'), findsWidgets);
  });

  testWidgets('LoginScreen renders form fields, validation, and links to Register', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(createTestApp('/login', container));
    await pumpUntilResolved(tester);

    expect(find.text('Đăng nhập EduMarket'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng ký ngay'), findsOneWidget);

    // Tap submit button with empty fields
    final loginBtn = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders fields, validates password mismatch', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(createTestApp('/register', container));
    await pumpUntilResolved(tester);

    expect(find.text('Đăng ký tài khoản EduMarket'), findsOneWidget);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);

    // Enter name, email, password, and mismatching confirm password
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Nguyễn Văn Test');
    await tester.enterText(textFields.at(1), 'test@example.com');
    await tester.enterText(textFields.at(2), 'Password123!');
    await tester.enterText(textFields.at(3), 'DifferentPassword123!');

    final registerBtn = find.widgetWithText(FilledButton, 'Đăng ký tài khoản');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
  });

  testWidgets('Navbar displays logged out state when unauthenticated', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(child: SizedBox()),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng ký'), findsWidgets);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
  });

  testWidgets('Navbar displays user greeting, Orders, and Logout when authenticated', (WidgetTester tester) async {
    const user = UserModel(
      id: 'usr-1',
      email: 'customer@example.com',
      fullName: 'Vũ Hoàng',
      role: 'CUSTOMER',
    );
    final container = createContainer(loggedInUser: user);
    addTearDown(container.dispose);
    // Use a wider viewport to accommodate Library + Orders + Logout buttons
    tester.view.physicalSize = const Size(1440, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(child: SizedBox()),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Vũ Hoàng'), findsWidgets);
    expect(find.text('Thư viện'), findsWidgets);
    expect(find.text('Đơn hàng'), findsWidgets);
    expect(find.text('Đăng xuất'), findsWidgets);
  });

  testWidgets('Protected route /checkout redirects unauthenticated user to Login', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    );
    container.read(routerProvider).go('/checkout');
    await pumpUntilResolved(tester);

    expect(find.text('Đăng nhập EduMarket'), findsOneWidget);
  });

  testWidgets('CertificateListScreen renders empty state when user has no certificates', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CertificateListScreen(),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Chứng chỉ của tôi'), findsWidgets);
    expect(find.text('Chưa có chứng chỉ nào'), findsOneWidget);
    expect(find.text('Đến thư viện học tập'), findsOneWidget);
  });

  testWidgets('CertificateListScreen renders certificate card when user has certificates', (WidgetTester tester) async {
    final sampleCertificate = CertificateItem(
      certificateCode: 'EDU-2026-F98B237DAABBCCDD11223344',
      courseTitle: 'Node.js và Express cho người mới',
      issuedAt: DateTime(2026, 9, 21),
      verificationUrl: '/api/certificates/EDU-2026-F98B237DAABBCCDD11223344/verify',
    );
    final container = createContainer(certificates: [sampleCertificate]);
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CertificateListScreen(),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Node.js và Express cho người mới'), findsOneWidget);
    expect(find.text('EDU-2026-F98B237DAABBCCDD11223344'), findsOneWidget);
    expect(find.text('Tải PDF'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsOneWidget);
  });

  testWidgets('CertificateVerificationScreen renders search input and verifies valid code', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CertificateVerificationScreen(),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Xác Thực Chứng Chỉ Trực Tuyến'), findsOneWidget);
    expect(find.text('Tra cứu'), findsOneWidget);

    final inputFinder = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText?.contains('EDU-') == true,
    );
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, 'EDU-2026-F98B237DAABBCCDD11223344');
    await tester.tap(find.text('Tra cứu'));
    await pumpUntilResolved(tester);

    expect(find.text('CHỨNG CHỈ HỢP LỆ VÀ CHÍNH THỨC'), findsOneWidget);
    expect(find.text('Vũ Hoàng'), findsOneWidget);
    expect(find.text('Node.js và Express cho người mới'), findsOneWidget);
  });

  testWidgets('WishlistScreen renders empty state when wishlist is empty', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WishlistScreen(),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Danh sách yêu thích trống'), findsOneWidget);
    expect(find.text('Khám phá khóa học ngay'), findsOneWidget);
  });

  testWidgets('WishlistScreen renders items and allows removing course from wishlist', (WidgetTester tester) async {
    final sampleItem = WishlistItemModel(
      id: 'wish-1',
      userId: 'test-user-id',
      courseId: 'course-1',
      createdAt: DateTime.now(),
      course: const CourseModel(
        id: 'course-1',
        title: 'Khóa học Flutter Masterclass',
        slug: 'khoa-hoc-flutter-masterclass',
        instructorName: 'Nguyễn Văn Flutter',
        price: 299000,
        salePrice: 199000,
        ratingAverage: 4.9,
        ratingCount: 25,
        enrollmentCount: 120,
        level: 'ALL_LEVELS',
        shortDescription: 'Khóa học lập trình Flutter đỉnh cao',
        category: CategoryModel(id: 'cat-1', name: 'Lập trình', slug: 'lap-trinh'),
      ),
    );
    final container = createContainer(wishlistItems: [sampleItem]);
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WishlistScreen(),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Khóa học Flutter Masterclass'), findsWidgets);
    final removeBtn = find.byTooltip('Bỏ khỏi yêu thích');
    expect(removeBtn, findsOneWidget);

    // Tap delete button to remove
    await tester.tap(removeBtn);
    await pumpUntilResolved(tester);

    expect(find.text('Danh sách yêu thích trống'), findsOneWidget);
  });

  testWidgets('CourseReviewsSection displays review status and rating summary', (WidgetTester tester) async {
    const customer = UserModel(
      id: 'c1',
      email: 'customer@example.com',
      fullName: 'Vũ Hoàng',
      role: 'CUSTOMER',
    );
    final pendingReview = MyReviewModel(
      id: 'rev-1',
      rating: 5,
      comment: 'Khóa học rất hay và chi tiết!',
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
    final container = createContainer(
      loggedInUser: customer,
      myReview: pendingReview,
    );
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CourseReviewsSection(
                courseId: 'course-1',
                ratingAverage: 5.0,
                ratingCount: 1,
              ),
            ),
          ),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Đánh giá từ học viên'), findsOneWidget);
    expect(find.text('Đang chờ kiểm duyệt'), findsOneWidget);
    expect(find.text('Đánh giá của bạn'), findsOneWidget);
    expect(find.text('Khóa học rất hay và chi tiết!'), findsOneWidget);
  });

  testWidgets('CouponInputCard validates coupon and displays discount', (WidgetTester tester) async {
    final container = createContainer();
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: CouponInputCard(),
            ),
          ),
        ),
      ),
    );
    await pumpUntilResolved(tester);

    expect(find.text('Nhập mã giảm giá'), findsOneWidget);
    expect(find.text('Áp dụng'), findsOneWidget);

    final inputFinder = find.byType(TextField);
    await tester.enterText(inputFinder, 'GIAM10');
    await tester.tap(find.text('Áp dụng'));
    await pumpUntilResolved(tester);

    expect(find.text('Mã giảm giá: GIAM10'), findsOneWidget);
    expect(find.text('Giảm 50.000₫'), findsOneWidget);

    // Tap remove button
    final removeBtn = find.byTooltip('Gỡ bỏ mã');
    expect(removeBtn, findsOneWidget);
    await tester.tap(removeBtn);
    await pumpUntilResolved(tester);

    expect(find.text('Nhập mã giảm giá'), findsOneWidget);
  });

  testWidgets('Admin route /admin redirects CUSTOMER role to /admin/forbidden', (WidgetTester tester) async {
    const customer = UserModel(
      id: 'c1',
      email: 'customer@example.com',
      fullName: 'Vũ Hoàng',
      role: 'CUSTOMER',
    );
    final container = createContainer(loggedInUser: customer);
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    );
    await pumpUntilResolved(tester);

    container.read(routerProvider).go('/admin');
    await pumpUntilResolved(tester);

    expect(find.text('403 - Quyền truy cập bị từ chối'), findsOneWidget);
  });

  testWidgets('Admin route /admin renders AdminDashboardScreen for ADMIN role', (WidgetTester tester) async {
    const admin = UserModel(
      id: 'a1',
      email: 'admin@example.com',
      fullName: 'Quản Trị Viên',
      role: 'ADMIN',
    );
    final container = createContainer(loggedInUser: admin);
    addTearDown(container.dispose);
    setupDesktopViewport(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    );
    await pumpUntilResolved(tester);

    container.read(routerProvider).go('/admin');
    await pumpUntilResolved(tester);

    expect(find.text('Bảng điều khiển quản trị'), findsOneWidget);
    expect(find.text('Tổng doanh thu'), findsOneWidget);
  });
}
