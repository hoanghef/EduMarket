import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/course_card.dart';
import '../courses/models/catalog_models.dart';
import '../courses/providers/catalog_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────────────
            _HeroSection(),
            const SizedBox(height: 48),
            // ── Categories ────────────────────────────────────────────────────
            _CategoriesSection(ref: ref),
            const SizedBox(height: 48),
            // ── Best Sellers ──────────────────────────────────────────────────
            _CourseSection(
              ref: ref,
              title: '🔥 Bán chạy nhất',
              filter: const CatalogFilter(sort: 'popularity', limit: 8),
            ),
            const SizedBox(height: 48),
            // ── New Courses ───────────────────────────────────────────────────
            _CourseSection(
              ref: ref,
              title: '🆕 Mới nhất',
              filter: const CatalogFilter(sort: 'newest', limit: 8),
            ),
            const SizedBox(height: 48),
            // ── Top Rated ────────────────────────────────────────────────────
            _CourseSection(
              ref: ref,
              title: '⭐ Đánh giá cao nhất',
              filter: const CatalogFilter(sort: 'rating', limit: 8),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatefulWidget {
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoint.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Breakpoint.pagePadding(context),
        vertical: isMobile ? 48 : 80,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎓  CSE703102 – E-commerce  •  Topic 12',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              // Headline
              Text(
                isMobile
                    ? 'Học bất cứ thứ gì,\nbất cứ nơi đâu'
                    : 'Học bất cứ thứ gì,\nbất cứ nơi đâu\nvới EduMarket',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 36 : 52,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Khám phá hàng trăm khóa học từ chuyên gia hàng đầu.\nMua một lần, học mãi mãi.',
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 32),
              // Search bar
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm khóa học...',
                          prefixIcon: const Icon(Icons.search),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onSubmitted: _search,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _search(_controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tìm kiếm',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Lập trình',
                  'Thiết kế',
                  'Marketing',
                  'Kinh doanh',
                  'Ngoại ngữ',
                ].map((tag) => GestureDetector(
                      onTap: () => context.go(
                          '/khoa-hoc?q=${Uri.encodeComponent(tag)}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _search(String q) {
    final trimmed = q.trim();
    if (trimmed.isNotEmpty) {
      context.go('/khoa-hoc?q=${Uri.encodeComponent(trimmed)}');
    }
  }
}

// ── Categories section ────────────────────────────────────────────────────────

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final asyncCats = ref.watch(categoriesProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Breakpoint.pagePadding(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: '📚 Danh mục phổ biến',
                onViewAll: () => context.go('/khoa-hoc'),
              ),
              const SizedBox(height: 16),
              asyncCats.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
                data: (cats) => cats.isEmpty
                    ? const EmptyState(
                        icon: Icons.category_outlined,
                        title: 'Chưa có danh mục',
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: cats
                            .map((c) => _CategoryChip(category: c))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({required this.category});
  final CategoryModel category;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/danh-muc/${widget.category.slug}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? AppTheme.primary : AppTheme.divider,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: _hovered ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.category.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable course section ───────────────────────────────────────────────────

class _CourseSection extends ConsumerWidget {
  const _CourseSection({
    required this.ref,
    required this.title,
    required this.filter,
  });

  final WidgetRef ref;
  final String title;
  final CatalogFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourses = ref.watch(
      FutureProvider.autoDispose<CoursePage>((r) =>
          r.watch(catalogRepositoryProvider).getCourses(filter)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Breakpoint.pagePadding(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: title,
                onViewAll: () => context.go(
                  '/khoa-hoc?sort=${filter.sort}',
                ),
              ),
              const SizedBox(height: 16),
              asyncCourses.when(
                loading: () => const LoadingRow(itemCount: 4),
                error: (e, _) => ErrorState(message: e.toString()),
                data: (page) {
                  if (page.items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'Chưa có khóa học',
                    );
                  }
                  return SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: page.items.length,
                      separatorBuilder: (context, _) => const SizedBox(width: 16),
                      itemBuilder: (context, i) => SizedBox(
                        width: 220,
                        child: CourseCard(course: page.items[i]),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});
  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Row(
              children: [
                Text('Xem tất cả'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}
