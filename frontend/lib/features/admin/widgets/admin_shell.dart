import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../auth/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
    this.actions,
  });

  final String currentRoute;
  final String title;
  final Widget child;
  final List<Widget>? actions;

  static const _navItems = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Tổng quan', route: '/admin'),
    (icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Khóa học', route: '/admin/courses'),
    (icon: Icons.category_outlined, activeIcon: Icons.category, label: 'Danh mục', route: '/admin/categories'),
    (icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Đơn hàng', route: '/admin/orders'),
    (icon: Icons.people_outline, activeIcon: Icons.people, label: 'Người dùng', route: '/admin/users'),
    (icon: Icons.rate_review_outlined, activeIcon: Icons.rate_review, label: 'Đánh giá', route: '/admin/reviews'),
    (icon: Icons.discount_outlined, activeIcon: Icons.discount, label: 'Mã giảm giá', route: '/admin/coupons'),
    (icon: Icons.vpn_key_outlined, activeIcon: Icons.vpn_key, label: 'Quyền truy cập', route: '/admin/entitlements'),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Báo cáo doanh thu', route: '/admin/reports'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= Breakpoint.desktop;
    final authUser = ref.watch(authProvider).user;

    final navDrawer = Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EduMarket',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _navItems.map((item) {
                  final isSelected = currentRoute == item.route;
                  return ListTile(
                    leading: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
                    onTap: () {
                      if (!isDesktop) Navigator.of(context).pop();
                      context.go(item.route);
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Về trang cửa hàng', style: TextStyle(fontSize: 14)),
              onTap: () => context.go('/'),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          if (actions != null) ...actions!,
          OutlinedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined, size: 16),
            label: const Text('Trang chủ', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, size: 14, color: Colors.brown),
                const SizedBox(width: 4),
                Text(
                  authUser?.fullName ?? 'ADMIN',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isDesktop ? null : navDrawer,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SizedBox(
              width: 240,
              child: Material(
                elevation: 1,
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    ..._navItems.map((item) {
                      final isSelected = currentRoute == item.route;
                      return ListTile(
                        leading: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                          size: 20,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
                        onTap: () => context.go(item.route),
                      );
                    }),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined, size: 20),
                      title: const Text('Về cửa hàng', style: TextStyle(fontSize: 14)),
                      onTap: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
