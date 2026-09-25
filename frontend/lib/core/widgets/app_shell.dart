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
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(AppShell old) {
    super.didUpdateWidget(old);
    if (old.child != widget.child) {
      _fadeCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          const _Navbar(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: widget.child,
            ),
          ),
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
                  const SizedBox(width: 12),
                  _NavLink(label: 'Trang chủ', path: '/'),
                  _NavLink(label: 'Khóa học', path: '/khoa-hoc'),
                  const Spacer(),
                  if (showSearchBar) ...[
                    const SizedBox(width: 180, child: _NavSearchBar()),
                    const SizedBox(width: 8),
                  ],
                  // Wishlist button
                  IconButton(
                    icon: const Icon(Icons.favorite_border, size: 20),
                    tooltip: 'Yêu thích',
                    onPressed: () => context.go('/wishlist'),
                  ),
                  // Cart button
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    tooltip: 'Giỏ hàng',
                    onPressed: () => context.go('/cart'),
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(width: 2),
                    TextButton.icon(
                      onPressed: () => context.go('/library'),
                      icon: const Icon(Icons.library_books_outlined, size: 16),
                      label: const Text('Thư viện',
                          style: TextStyle(fontSize: 13)),
                    ),
                    IconButton(
                      tooltip: 'Chứng chỉ',
                      icon: const Icon(Icons.workspace_premium_outlined, size: 20),
                      onPressed: () => context.go('/certificates'),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/account/orders'),
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: const Text('Đơn hàng',
                          style: TextStyle(fontSize: 13)),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 2),
                      FilledButton.tonal(
                        onPressed: () => context.go('/admin'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 14),
                            SizedBox(width: 3),
                            Text('Admin', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    _UserAvatarChip(name: user.fullName),
                    const SizedBox(width: 4),
                    OutlinedButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Đăng xuất',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ] else ...[
                    const SizedBox(width: 4),
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
                  _MobileNavLink(
                    label: 'Trang chủ',
                    path: '/',
                    icon: Icons.home_outlined,
                  ),
                  _MobileNavLink(
                    label: 'Khóa học',
                    path: '/khoa-hoc',
                    icon: Icons.school_outlined,
                  ),
                  _MobileNavLink(
                    label: 'Yêu thích',
                    path: '/wishlist',
                    icon: Icons.favorite_border,
                  ),
                  _MobileNavLink(
                    label: 'Giỏ hàng',
                    path: '/cart',
                    icon: Icons.shopping_cart_outlined,
                  ),
                  if (isLoggedIn) ...[
                    _MobileNavLink(
                      label: 'Thư viện của tôi',
                      path: '/library',
                      icon: Icons.library_books_outlined,
                    ),
                    _MobileNavLink(
                      label: 'Chứng chỉ của tôi',
                      path: '/certificates',
                      icon: Icons.workspace_premium_outlined,
                    ),
                    _MobileNavLink(
                      label: 'Đơn hàng của tôi',
                      path: '/account/orders',
                      icon: Icons.receipt_long_outlined,
                    ),
                    if (user.isAdmin)
                      _MobileNavLink(
                        label: 'Khu vực quản trị (Admin)',
                        path: '/admin',
                        icon: Icons.shield_outlined,
                      ),
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
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.1)
                : (_hovered ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive
                  ? FontWeight.w700
                  : (_hovered ? FontWeight.w600 : FontWeight.w500),
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
  const _MobileNavLink({required this.label, required this.path, this.icon});
  final String label;
  final String path;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    String location = '';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {}
    final isActive =
        location == path || (path != '/' && location.startsWith(path));

    return ListTile(
      leading: icon != null
          ? Icon(icon,
              size: 20,
              color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant)
          : null,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppTheme.primary : AppTheme.onSurface,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

// ── User Avatar Chip ──────────────────────────────────────────────────────────

class _UserAvatarChip extends StatelessWidget {
  const _UserAvatarChip({required this.name});
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
        vertical: 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
          child: Breakpoint.isMobile(context)
              ? const _FooterMobile()
              : const _FooterDesktop(),
        ),
      ),
    );
  }
}

class _FooterDesktop extends StatelessWidget {
  const _FooterDesktop();

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
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EduMarket',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nền tảng học trực tuyến hàng đầu\ncho người học Việt Nam.',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const Expanded(
              child: _FooterColumn(
                title: 'Khám phá',
                links: [
                  ('Tất cả khóa học', '/khoa-hoc'),
                  ('Lập trình', '/danh-muc/lap-trinh'),
                  ('Thiết kế', '/danh-muc/thiet-ke'),
                  ('Ưu đãi & Khuyến mãi', '/khuyen-mai'),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const Expanded(
              child: _FooterColumn(
                title: 'Chính sách & Quy định',
                links: [
                  ('Thông tin người bán', '/chinh-sach/business'),
                  ('Điều khoản giao dịch', '/chinh-sach/terms'),
                  ('Chính sách hoàn tiền', '/chinh-sach/refunds'),
                  ('Bảo vệ dữ liệu cá nhân', '/chinh-sach/privacy'),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const Expanded(
              child: _FooterColumn(
                title: 'Tài khoản',
                links: [
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
        const SizedBox(height: 12),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2026 EduMarket – CSE703102 E-commerce Capstone Project',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
            Text(
              'Học tập mọi lúc, nâng tầm tương lai',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterMobile extends StatelessWidget {
  const _FooterMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 13),
            ),
            const SizedBox(width: 6),
            const Text(
              'EduMarket',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Nền tảng học trực tuyến hàng đầu cho người học Việt Nam',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _FooterMobileLink(label: 'Khóa học', path: '/khoa-hoc'),
            _FooterMobileLink(label: 'Khuyến mãi', path: '/khuyen-mai'),
            _FooterMobileLink(label: 'Người bán', path: '/chinh-sach/business'),
            _FooterMobileLink(label: 'Điều khoản', path: '/chinh-sach/terms'),
            _FooterMobileLink(label: 'Hoàn tiền', path: '/chinh-sach/refunds'),
            _FooterMobileLink(label: 'Bảo mật', path: '/chinh-sach/privacy'),
            _FooterMobileLink(
                label: 'Xác thực chứng chỉ', path: '/certificates/verify'),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 8),
        const Text(
          '© 2026 EduMarket',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ],
    );
  }
}

class _FooterMobileLink extends StatelessWidget {
  const _FooterMobileLink({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF64748B),
        ),
      ),
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
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        ...links.map((l) => _FooterLinkItem(label: l.$1, path: l.$2)),
      ],
    );
  }
}

class _FooterLinkItem extends StatefulWidget {
  const _FooterLinkItem({required this.label, required this.path});
  final String label;
  final String path;

  @override
  State<_FooterLinkItem> createState() => _FooterLinkItemState();
}

class _FooterLinkItemState extends State<_FooterLinkItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.path),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: _hovered ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
