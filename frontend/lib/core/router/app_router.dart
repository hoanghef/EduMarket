import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/courses/category_courses_screen.dart';
import '../../features/courses/course_catalog_screen.dart';
import '../../features/courses/course_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Application router using go_router with path-based URL strategy.
final appRouter = GoRouter(
  initialLocation: AppConstants.routeHome,
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

    // ── Auth placeholders (Phase 7) ──────────────────────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, _) => const _ComingSoon(title: 'Đăng nhập'),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, _) => const _ComingSoon(title: 'Đăng ký'),
    ),
    GoRoute(
      path: '/library',
      name: 'library',
      builder: (context, _) => const _ComingSoon(title: 'Thư viện của tôi'),
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, _) => const _ComingSoon(title: 'Giỏ hàng'),
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
            const Icon(Icons.construction_outlined, size: 64, color: AppTheme.primary),
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
