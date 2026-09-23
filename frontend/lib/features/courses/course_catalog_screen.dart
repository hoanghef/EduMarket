import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/seo/seo_data.dart';
import '../../core/seo/seo_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/course_card.dart';
import '../courses/models/catalog_models.dart';
import '../courses/providers/catalog_provider.dart';

/// `/khoa-hoc` – Full catalog with search, filter and sort.
class CourseCatalogScreen extends ConsumerStatefulWidget {
  const CourseCatalogScreen({
    super.key,
    this.initialQ,
    this.initialCategory,
    this.initialSort,
  });

  final String? initialQ;
  final String? initialCategory;
  final String? initialSort;

  @override
  ConsumerState<CourseCatalogScreen> createState() =>
      _CourseCatalogScreenState();
}

class _CourseCatalogScreenState
    extends ConsumerState<CourseCatalogScreen> {
  late final TextEditingController _searchCtrl;
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl =
        TextEditingController(text: widget.initialQ ?? '');

    // Initialise filter from URL params (once, on first build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogFilterProvider.notifier).state = CatalogFilter(
        q: widget.initialQ,
        category: widget.initialCategory,
        sort: widget.initialSort ?? 'newest',
        page: 1,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(catalogFilterProvider);
    final asyncCourses = ref.watch(coursesProvider);

    SeoHelper.apply(
      SeoData.catalog(
        query: filter.q,
        categoryName: filter.category,
        sort: filter.sort,
      ),
    );
    final asyncCats = ref.watch(categoriesProvider);
    final isMobile = Breakpoint.isMobile(context);
    final cols = Breakpoint.gridColumns(context);

    return AppShell(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Breakpoint.pagePadding(context),
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────────────────
                  Text('Tất cả khóa học',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  asyncCourses.maybeWhen(
                    data: (p) => Text(
                      '${p.pagination.total} khóa học',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── Search + Controls bar ──────────────────────────────────
                  _SearchBar(
                    controller: _searchCtrl,
                    onSearch: (q) => _applyFilter(filter.copyWith(q: q, clearQ: q.isEmpty, page: 1)),
                    onToggleFilters: isMobile
                        ? () => setState(() => _filtersOpen = !_filtersOpen)
                        : null,
                    filtersOpen: _filtersOpen,
                    filter: filter,
                    onSortChanged: (s) =>
                        _applyFilter(filter.copyWith(sort: s, page: 1)),
                  ),
                  const SizedBox(height: 16),

                  // ── Layout: sidebar + grid (desktop) / stack (mobile) ─────
                  if (!isMobile)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar filters
                        SizedBox(
                          width: 220,
                          child: _FilterSidebar(
                            categories: asyncCats.maybeWhen(
                                data: (c) => c, orElse: () => []),
                            filter: filter,
                            onFilterChanged: (f) => _applyFilter(f),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Course grid
                        Expanded(
                          child: _CourseGrid(
                            asyncCourses: asyncCourses,
                            crossAxisCount: cols - 1,
                            filter: filter,
                            onPageChanged: (p) =>
                                _applyFilter(filter.copyWith(page: p)),
                            onRetry: () => ref.invalidate(coursesProvider),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Mobile: filters in collapsible panel
                    if (_filtersOpen)
                      _FilterSidebar(
                        categories: asyncCats.maybeWhen(
                            data: (c) => c, orElse: () => []),
                        filter: filter,
                        onFilterChanged: (f) {
                          _applyFilter(f);
                          setState(() => _filtersOpen = false);
                        },
                      ),
                    _CourseGrid(
                      asyncCourses: asyncCourses,
                      crossAxisCount: cols,
                      filter: filter,
                      onPageChanged: (p) =>
                          _applyFilter(filter.copyWith(page: p)),
                      onRetry: () => ref.invalidate(coursesProvider),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyFilter(CatalogFilter f) {
    ref.read(catalogFilterProvider.notifier).state = f;
    // Update URL to reflect current filters
    final params = <String, String>{};
    if (f.q != null && f.q!.isNotEmpty) params['q'] = f.q!;
    if (f.category != null) params['category'] = f.category!;
    if (f.level != null) params['level'] = f.level!;
    if (f.sort != 'newest') params['sort'] = f.sort;
    if (f.page > 1) params['page'] = '${f.page}';
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.go('/khoa-hoc${query.isEmpty ? '' : '?$query'}');
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.filter,
    required this.onSortChanged,
    this.onToggleFilters,
    this.filtersOpen = false,
  });

  final TextEditingController controller;
  final void Function(String) onSearch;
  final void Function(String) onSortChanged;
  final VoidCallback? onToggleFilters;
  final bool filtersOpen;
  final CatalogFilter filter;

  static const _sorts = [
    ('newest', 'Mới nhất'),
    ('popularity', 'Phổ biến nhất'),
    ('rating', 'Đánh giá cao'),
    ('price_asc', 'Giá: Thấp → Cao'),
    ('price_desc', 'Giá: Cao → Thấp'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onToggleFilters != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: onToggleFilters,
              icon: Icon(filtersOpen ? Icons.filter_list_off : Icons.filter_list),
              label: const Text('Lọc'),
            ),
          ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Tìm khóa học, giảng viên...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: onSearch,
          ),
        ),
        const SizedBox(width: 12),
        // Sort dropdown
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: filter.sort,
            borderRadius: BorderRadius.circular(8),
            items: _sorts
                .map((s) => DropdownMenuItem(
                      value: s.$1,
                      child: Text(s.$2,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => onSortChanged(v ?? 'newest'),
          ),
        ),
      ],
    );
  }
}

// ── Filter sidebar ────────────────────────────────────────────────────────────

class _FilterSidebar extends StatefulWidget {
  const _FilterSidebar({
    required this.categories,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<CategoryModel> categories;
  final CatalogFilter filter;
  final void Function(CatalogFilter) onFilterChanged;

  @override
  State<_FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<_FilterSidebar> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.filter.minPrice?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(
        text: widget.filter.maxPrice?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filter;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reset
            Row(
              children: [
                const Text('Bộ lọc',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                TextButton(
                  onPressed: () => widget.onFilterChanged(
                      const CatalogFilter(page: 1)),
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const Divider(),
            // ── Category ─────────────────────────────────────────────────────
            const Text('Danh mục',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ...widget.categories.map((c) => _FilterRadio(
                  label: c.name,
                  selected: f.category == c.slug,
                  onTap: () => widget.onFilterChanged(f.copyWith(
                    category: c.slug,
                    clearCategory: f.category == c.slug,
                    page: 1,
                  )),
                )),
            const Divider(),
            // ── Level ─────────────────────────────────────────────────────────
            const Text('Trình độ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ...const [
              ('BEGINNER', 'Cơ bản'),
              ('INTERMEDIATE', 'Trung cấp'),
              ('ADVANCED', 'Nâng cao'),
            ].map((l) => _FilterRadio(
                  label: l.$2,
                  selected: f.level == l.$1,
                  onTap: () => widget.onFilterChanged(f.copyWith(
                    level: l.$1,
                    clearLevel: f.level == l.$1,
                    page: 1,
                  )),
                )),
            const Divider(),
            // ── Price ─────────────────────────────────────────────────────────
            const Text('Giá (₫)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Từ', contentPadding: EdgeInsets.all(8)),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('–'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Đến', contentPadding: EdgeInsets.all(8)),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final min = double.tryParse(_minCtrl.text);
                  final max = double.tryParse(_maxCtrl.text);
                  widget.onFilterChanged(f.copyWith(
                    minPrice: min,
                    maxPrice: max,
                    clearMinPrice: min == null,
                    clearMaxPrice: max == null,
                    page: 1,
                  ));
                },
                child: const Text('Áp dụng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRadio extends StatelessWidget {
  const _FilterRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppTheme.primary : AppTheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Course grid ────────────────────────────────────────────────────────────────

class _CourseGrid extends StatelessWidget {
  const _CourseGrid({
    required this.asyncCourses,
    required this.crossAxisCount,
    required this.filter,
    required this.onPageChanged,
    required this.onRetry,
  });

  final AsyncValue<CoursePage> asyncCourses;
  final int crossAxisCount;
  final CatalogFilter filter;
  final void Function(int) onPageChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return asyncCourses.when(
      loading: () => LoadingGrid(
          itemCount: 12,
          crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: onRetry),
      data: (page) {
        if (page.items.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'Không tìm thấy khóa học',
            subtitle: 'Thử thay đổi từ khóa hoặc điều kiện lọc.',
            action: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Xóa bộ lọc'),
            ),
          );
        }
        final c = crossAxisCount > 0 ? crossAxisCount : 1;
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: c,
                childAspectRatio: 0.72,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: page.items.length,
              itemBuilder: (_, i) => CourseCard(course: page.items[i]),
            ),
            const SizedBox(height: 24),
            _Pagination(meta: page.pagination, onPage: onPageChanged),
          ],
        );
      },
    );
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  const _Pagination({required this.meta, required this.onPage});
  final PaginationMeta meta;
  final void Function(int) onPage;

  @override
  Widget build(BuildContext context) {
    if (meta.totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: meta.hasPrev ? () => onPage(meta.page - 1) : null,
        ),
        ...List.generate(meta.totalPages.clamp(0, 7), (i) {
          final p = i + 1;
          final isActive = p == meta.page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              width: 36,
              height: 36,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isActive ? AppTheme.primary : Colors.transparent,
                  foregroundColor:
                      isActive ? Colors.white : AppTheme.onSurface,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => onPage(p),
                child: Text('$p'),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: meta.hasNext ? () => onPage(meta.page + 1) : null,
        ),
      ],
    );
  }
}
