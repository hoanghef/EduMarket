import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Breakpoints for responsive layout.
abstract final class Breakpoint {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1280;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Returns the number of grid columns appropriate for the viewport.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktop) return 4;
    if (w >= tablet) return 3;
    if (w >= mobile) return 2;
    return 1;
  }

  /// Max content width.
  static const double maxContentWidth = 1280;

  /// Horizontal page padding.
  static double pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktop) return 48;
    if (w >= tablet) return 32;
    return 16;
  }
}

/// Wraps every page with the site navbar and footer.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          const _Navbar(),
          Expanded(child: child),
          const _Footer(),
        ],
      ),
    );
  }
}

// ── Navbar ────────────────────────────────────────────────────────────────────

class _Navbar extends ConsumerStatefulWidget {
  const _Navbar();

  @override
  ConsumerState<_Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<_Navbar> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoggedIn = authState.isAuthenticated && user != null;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < Breakpoint.tablet;
    final showSearchBar =
        !isLoggedIn ? screenWidth >= 1200 : screenWidth >= 1500;

    return Material(
      color: Colors.white,
      elevation: 0,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
                horizontal: Breakpoint.pagePadding(context)),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                // Logo
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EduMarket',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Desktop: nav links + search + cart + auth
                if (!isCompact) ...[
                  const SizedBox(width: 16),
                  _NavLink(label: 'Trang chủ', path: '/'),
                  _NavLink(label: 'Khóa học', path: '/khoa-hoc'),
                  const Spacer(),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showSearchBar) ...[
                            const SizedBox(width: 180, child: _NavSearchBar()),
                            const SizedBox(width: 8),
                          ],
                          // Wishlist button
                          IconButton(
                            icon: const Icon(Icons.favorite_border, size: 22),
                            tooltip: 'Yêu thích',
                            onPressed: () => context.go('/wishlist'),
                          ),
                          const SizedBox(width: 4),
                          // Cart button
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                            tooltip: 'Giỏ hàng',
                            onPressed: () => context.go('/cart'),
                          ),
                          const SizedBox(width: 4),
                          if (isLoggedIn) ...[
                            TextButton.icon(
                              onPressed: () => context.go('/library'),
                              icon: const Icon(Icons.library_books_outlined, size: 18),
                              label: const Text('Thư viện'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Chứng chỉ của tôi',
                              icon: const Icon(Icons.workspace_premium_outlined, size: 22),
                              onPressed: () => context.go('/certificates'),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => context.go('/account/orders'),
                              icon: const Icon(Icons.receipt_long_outlined, size: 18),
                              label: const Text('Đơn hàng'),
                            ),
                            if (user.isAdmin) ...[
                              const SizedBox(width: 4),
                              FilledButton.tonal(
                                onPressed: () => context.go('/admin'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_outlined, size: 15),
                                    SizedBox(width: 4),
                                    Text('Quản trị', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 110),
                                    child: Text(
                                      user.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              onPressed: () => ref.read(authProvider.notifier).logout(),
                              child: const Text('Đăng xuất'),
                            ),
                          ] else ...[
                            OutlinedButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Đăng nhập'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => context.go('/register'),
                              child: const Text('Đăng ký'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 22),
                    tooltip: 'Yêu thích',
                    onPressed: () => context.go('/wishlist'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                    tooltip: 'Giỏ hàng',
                    onPressed: () => context.go('/cart'),
                  ),
                  IconButton(
                    icon: Icon(_menuOpen ? Icons.close : Icons.menu),
                    onPressed: () => setState(() => _menuOpen = !_menuOpen),
                  ),
                ],
              ],
            ),
          ),

          // Mobile dropdown menu
          if (isCompact && _menuOpen)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _MobileNavLink(label: 'Trang chủ', path: '/'),
                  _MobileNavLink(label: 'Khóa học', path: '/khoa-hoc'),
                  _MobileNavLink(label: 'Yêu thích', path: '/wishlist'),
                  _MobileNavLink(label: 'Giỏ hàng', path: '/cart'),
                  if (isLoggedIn) ...[
                    _MobileNavLink(
                        label: 'Thư viện của tôi', path: '/library'),
                    _MobileNavLink(
                        label: 'Chứng chỉ của tôi', path: '/certificates'),
                    _MobileNavLink(
                        label: 'Đơn hàng của tôi', path: '/account/orders'),
                    if (user.isAdmin)
                      _MobileNavLink(
                          label: 'Khu vực quản trị (Admin)', path: '/admin'),
                    const SizedBox(height: 8),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.account_circle,
                          color: AppTheme.primary),
                      title: Text(user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle:
                          Text(user.email, style: const TextStyle(fontSize: 12)),
                      dense: true,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _menuOpen = false);
                          ref.read(authProvider.notifier).logout();
                        },
                        child: const Text('Đăng xuất'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _menuOpen = false);
                              context.go('/login');
                            },
                            child: const Text('Đăng nhập'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() => _menuOpen = false);
                              context.go('/register');
                            },
                            child: const Text('Đăng ký'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.path});
  final String label;
  final String path;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    String location = '';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {}
    final isActive = location == widget.path ||
        (widget.path != '/' && location.startsWith(widget.path));
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive || _hovered ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? AppTheme.primary
                  : (_hovered ? AppTheme.primary : AppTheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavLink extends StatelessWidget {
  const _MobileNavLink({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      onTap: () => context.go(path),
      dense: true,
    );
  }
}

class _NavSearchBar extends StatelessWidget {
  const _NavSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      height: 38,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm khóa học...',
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
          filled: true,
          fillColor: AppTheme.surface,
        ),
        onSubmitted: (q) {
          if (q.trim().isNotEmpty) {
            context.go('/khoa-hoc?q=${Uri.encodeComponent(q.trim())}');
          }
        },
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.onSurface,
      padding: EdgeInsets.symmetric(
        horizontal: Breakpoint.pagePadding(context),
        vertical: 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
          child: Breakpoint.isMobile(context)
              ? _FooterMobile()
              : _FooterDesktop(),
        ),
      ),
    );
  }
}

class _FooterDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EduMarket',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nền tảng học trực tuyến hàng đầu\ncho người học Việt Nam.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Khám phá',
                links: const [
                  ('Tất cả khóa học', '/khoa-hoc'),
                  ('Lập trình', '/danh-muc/lap-trinh'),
                  ('Thiết kế', '/danh-muc/thiet-ke'),
                  ('Ưu đãi & Khuyến mãi', '/khuyen-mai'),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Chính sách & Quy định',
                links: const [
                  ('Thông tin người bán', '/chinh-sach/business'),
                  ('Điều khoản giao dịch', '/chinh-sach/terms'),
                  ('Chính sách hoàn tiền', '/chinh-sach/refunds'),
                  ('Bảo vệ dữ liệu cá nhân', '/chinh-sach/privacy'),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _FooterColumn(
                title: 'Tài khoản',
                links: const [
                  ('Đăng nhập', '/login'),
                  ('Đăng ký', '/register'),
                  ('Thư viện của tôi', '/library'),
                  ('Chứng chỉ của tôi', '/certificates'),
                  ('Xác thực chứng chỉ', '/certificates/verify'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFF334155)),
        const SizedBox(height: 16),
        const Text(
          '© 2026 EduMarket – CSE703102 E-commerce Capstone Project',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    );
  }
}

class _FooterMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'EduMarket',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nền tảng học trực tuyến hàng đầu\ncho người học Việt Nam.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.go('/khoa-hoc'),
              child: const Text('Khóa học', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => context.go('/khuyen-mai'),
              child: const Text('Khuyến mãi', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => context.go('/chinh-sach/business'),
              child: const Text('Người bán', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => context.go('/chinh-sach/terms'),
              child: const Text('Điều khoản', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => context.go('/chinh-sach/refunds'),
              child: const Text('Hoàn tiền', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => context.go('/chinh-sach/privacy'),
              child: const Text('Bảo mật', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => context.go('/certificates/verify'),
              child: const Text('Xác thực chứng chỉ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFF334155)),
        const SizedBox(height: 12),
        const Text(
          '© 2026 EduMarket',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});
  final String title;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ...links.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => context.go(l.$2),
                child: Text(
                  l.$1,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF94A3B8)),
                ),
              ),
            )),
      ],
    );
  }
}
