import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/courses/category_courses_screen.dart';
import '../../features/courses/course_catalog_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/payment_result_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/library/course_learning_screen.dart';
import '../../features/library/lesson_player_screen.dart';
import '../../features/certificates/certificate_list_screen.dart';
import '../../features/certificates/certificate_detail_screen.dart';
import '../../features/certificates/certificate_verification_screen.dart';
import '../../features/policies/policy_screen.dart';
import '../../features/promotions/promotions_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/admin_courses_screen.dart';
import '../../features/admin/admin_categories_screen.dart';
import '../../features/admin/admin_orders_screen.dart';
import '../../features/admin/admin_users_screen.dart';
import '../../features/admin/admin_reviews_screen.dart';
import '../../features/admin/admin_coupons_screen.dart';
import '../../features/admin/admin_entitlements_screen.dart';
import '../../features/admin/admin_reports_screen.dart';
import '../widgets/forbidden_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final location = state.matchedLocation;

    final isProtected =
        location.startsWith('/cart') ||
        location.startsWith('/checkout') ||
        location.startsWith('/account') ||
        location.startsWith('/library') ||
        location == '/certificates' ||
        location.startsWith('/wishlist');

    final isAdminRoute =
        location.startsWith('/admin') && location != '/admin/forbidden';

    final isAuthRoute = location == '/login' || location == '/register';

    // While still in initial session check, do not redirect prematurely
    if (authState.status == AuthStatus.initial) {
      return null;
    }

    // Unauthenticated user attempting to access a protected customer or admin route
    if (authState.status == AuthStatus.unauthenticated &&
        (isProtected || isAdminRoute)) {
      final target = state.uri.toString();
      return '/login?redirect=${Uri.encodeComponent(target)}';
    }

    // Authenticated non-admin attempting to access admin route
    if (authState.status == AuthStatus.authenticated && isAdminRoute) {
      if (authState.user?.role != 'ADMIN') {
        return '/admin/forbidden';
      }
    }

    // Authenticated user attempting to access login or register
    if (authState.status == AuthStatus.authenticated && isAuthRoute) {
      final redirectParam = state.uri.queryParameters['redirect'];
      if (redirectParam != null && redirectParam.isNotEmpty) {
        return redirectParam;
      }
      return AppConstants.routeHome;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppConstants.routeHome,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Home ────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeHome,
        name: 'home',
        builder: (context, _) => const HomeScreen(),
      ),

      // ── Course catalog (/khoa-hoc) ───────────────────────────────────────────
      GoRoute(
        path: AppConstants.routeCourses,
        name: 'courses',
        builder: (_, state) => CourseCatalogScreen(
          initialQ: state.uri.queryParameters['q'],
          initialCategory: state.uri.queryParameters['category'],
          initialSort: state.uri.queryParameters['sort'],
        ),
      ),

      // ── Course detail (/khoa-hoc/:slug) ─────────────────────────────────────
      GoRoute(
        path: AppConstants.routeCourseDetail,
        name: 'courseDetail',
        builder: (_, state) =>
            CourseDetailScreen(slug: state.pathParameters['slug']!),
      ),

      // ── Category courses (/danh-muc/:slug) ──────────────────────────────────
      GoRoute(
        path: AppConstants.routeCategory,
        name: 'category',
        builder: (_, state) =>
            CategoryCoursesScreen(slug: state.pathParameters['slug']!),
      ),

      // ── Auth screens ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) =>
            LoginScreen(redirectUrl: state.uri.queryParameters['redirect']),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) =>
            RegisterScreen(redirectUrl: state.uri.queryParameters['redirect']),
      ),
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, _) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/library/courses/:courseId',
        name: 'courseLearning',
        builder: (context, state) =>
            CourseLearningScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/library/courses/:courseId/lessons/:lessonId',
        name: 'lessonPlayer',
        builder: (context, state) => LessonPlayerScreen(
          courseId: state.pathParameters['courseId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, _) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/checkout/result',
        name: 'checkoutResult',
        builder: (context, state) => PaymentResultScreen(
          orderId: state.uri.queryParameters['orderId'],
          queryParams: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        path: '/account/orders',
        name: 'orders',
        builder: (context, _) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/account/orders/:id',
        name: 'orderDetail',
        builder: (context, state) =>
            OrderDetailScreen(id: state.pathParameters['id']!),
      ),
      // ── Certificates ────────────────────────────────────────────────────────
      GoRoute(
        path: '/certificates',
        name: 'certificates',
        builder: (context, _) => const CertificateListScreen(),
      ),
      GoRoute(
        path: '/certificates/verify',
        name: 'certificateVerify',
        builder: (context, state) => CertificateVerificationScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/certificates/verify/:code',
        name: 'certificateVerifyWithCode',
        builder: (context, state) => CertificateVerificationScreen(
          initialCode: state.pathParameters['code'],
        ),
      ),
      GoRoute(
        path: '/certificates/:code',
        name: 'certificateDetail',
        builder: (context, state) =>
            CertificateDetailScreen(code: state.pathParameters['code']!),
      ),
      // ── Wishlist ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/wishlist',
        name: 'wishlist',
        builder: (context, _) => const WishlistScreen(),
      ),

      // ── Policy & Seller routes ──────────────────────────────────────────────
      GoRoute(
        path: '/chinh-sach',
        redirect: (_, state) => '/chinh-sach/business',
      ),
      GoRoute(
        path: '/chinh-sach/:slug',
        name: 'policy',
        builder: (context, state) =>
            PolicyScreen(slug: state.pathParameters['slug'] ?? 'business'),
      ),

      // ── Marketing & Promotions ──────────────────────────────────────────────
      GoRoute(
        path: '/khuyen-mai',
        name: 'promotions',
        builder: (context, _) => const PromotionsScreen(),
      ),

      // ── Admin routes ────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, _) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/courses',
        name: 'adminCourses',
        builder: (context, _) => const AdminCoursesScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        name: 'adminCategories',
        builder: (context, _) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        name: 'adminOrders',
        builder: (context, _) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'adminUsers',
        builder: (context, _) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/reviews',
        name: 'adminReviews',
        builder: (context, _) => const AdminReviewsScreen(),
      ),
      GoRoute(
        path: '/admin/coupons',
        name: 'adminCoupons',
        builder: (context, _) => const AdminCouponsScreen(),
      ),
      GoRoute(
        path: '/admin/entitlements',
        name: 'adminEntitlements',
        builder: (context, _) => const AdminEntitlementsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'adminReports',
        builder: (context, _) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/forbidden',
        name: 'adminForbidden',
        builder: (context, _) => const ForbiddenScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy trang',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown error'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppConstants.routeHome),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
});
