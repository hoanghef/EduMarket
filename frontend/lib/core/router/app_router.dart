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
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final location = state.matchedLocation;

    final isProtected = location.startsWith('/cart') ||
        location.startsWith('/checkout') ||
        location.startsWith('/account');

    final isAuthRoute = location == '/login' || location == '/register';

    // While still in initial session check, do not redirect prematurely
    if (authState.status == AuthStatus.initial) {
      return null;
    }

    // Unauthenticated user attempting to access a protected route
    if (authState.status == AuthStatus.unauthenticated && isProtected) {
      final target = state.uri.toString();
      return '/login?redirect=${Uri.encodeComponent(target)}';
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
        builder: (context, state) => LoginScreen(
          redirectUrl: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterScreen(
          redirectUrl: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, _) => const _ComingSoon(title: 'Thư viện của tôi'),
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

/// Fallback router instance for static references.
final appRouter = GoRouter(
  initialLocation: AppConstants.routeHome,
  routes: [
    GoRoute(path: '/', builder: (c, _) => const HomeScreen()),
    GoRoute(path: '/login', builder: (c, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, _) => const RegisterScreen()),
    GoRoute(path: '/cart', builder: (c, _) => const CartScreen()),
    GoRoute(path: '/checkout', builder: (c, _) => const CheckoutScreen()),
    GoRoute(path: '/account/orders', builder: (c, _) => const OrderHistoryScreen()),
  ],
);

/// Placeholder screen for routes not yet implemented.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_outlined,
                size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Tính năng này đang được phát triển.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
