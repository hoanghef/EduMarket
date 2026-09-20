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
import 'package:edumarket/features/orders/order_history_screen.dart';

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

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  ProviderContainer createContainer({UserModel? loggedInUser}) {
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
}
