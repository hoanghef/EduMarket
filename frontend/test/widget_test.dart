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
  Future<OrderModel> checkoutCod() async {
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

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  ProviderContainer createContainer({
    UserModel? loggedInUser,
    List<CertificateItem> certificates = const [],
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
      ],
    );
  }

  void setupDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 800);
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
}
