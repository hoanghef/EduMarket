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

/// `/danh-muc/:slug` – Courses filtered by category.
class CategoryCoursesScreen extends ConsumerWidget {
  const CategoryCoursesScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch categories to get name from slug
    final asyncCats = ref.watch(categoriesProvider);
    final category = asyncCats.maybeWhen(
      data: (cats) {
        for (final c in cats) {
          if (c.slug == slug) return c;
          for (final sub in c.children) {
            if (sub.slug == slug) return sub;
          }
        }
        return null;
      },
      orElse: () => null,
    );

    if (category != null) {
      SeoHelper.apply(SeoData.category(name: category.name, slug: category.slug));
    } else {
      SeoHelper.apply(SeoData.catalog(categoryName: slug));
    }

    // Set catalog filter for this category
    final filter = CatalogFilter(category: slug, page: 1);
    final asyncCourses = ref.watch(
      FutureProvider.autoDispose<CoursePage>(
          (r) => r.watch(catalogRepositoryProvider).getCourses(filter)),
    );

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
                  // ── Breadcrumb ──────────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: const Text('Trang chủ',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('/',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/khoa-hoc'),
                        child: const Text('Khóa học',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('/',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      ),
                      Text(
                        category?.name ?? slug,
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Header ──────────────────────────────────────────────────
                  Text(
                    category?.name ?? 'Danh mục',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
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

                  // ── Subcategories ─────────────────────────────────────────
                  if (category != null && category.children.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: category.children.map((sub) {
                        return ActionChip(
                          label: Text(sub.name),
                          onPressed: () =>
                              context.go('/danh-muc/${sub.slug}'),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Grid ─────────────────────────────────────────────────
                  asyncCourses.when(
                    loading: () => LoadingGrid(
                        itemCount: 12,
                        crossAxisCount: cols > 0 ? cols : 1),
                    error: (e, _) => ErrorState(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(categoriesProvider),
                    ),
                    data: (page) {
                      if (page.items.isEmpty) {
                        return EmptyState(
                          icon: Icons.school_outlined,
                          title: 'Chưa có khóa học',
                          subtitle:
                              'Danh mục này chưa có khóa học nào. Hãy quay lại sau.',
                          action: OutlinedButton(
                            onPressed: () => context.go('/khoa-hoc'),
                            child: const Text('Xem tất cả khóa học'),
                          ),
                        );
                      }
                      final c = cols > 0 ? cols : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: c,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: page.items.length,
                        itemBuilder: (_, i) =>
                            CourseCard(course: page.items[i]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
