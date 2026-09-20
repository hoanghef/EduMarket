import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'models/library_models.dart';
import 'providers/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLibrary = ref.watch(libraryProvider);

    return AppShell(
      child: asyncLibrary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(libraryProvider),
        ),
        data: (entitlements) {
          if (entitlements.isEmpty) {
            return _EmptyLibrary();
          }
          return _LibraryList(entitlements: entitlements);
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_books_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Thư viện trống',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa có khóa học nào.\nHãy khám phá và mua khóa học để bắt đầu học!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/khoa-hoc'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Khám phá khóa học'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thư viện',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Library list ──────────────────────────────────────────────────────────────

class _LibraryList extends StatelessWidget {
  const _LibraryList({required this.entitlements});
  final List<EntitlementModel> entitlements;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoint.pagePadding(context),
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.library_books_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thư viện của tôi',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${entitlements.length} khóa học đã mua',
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Course grid ───────────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = Breakpoint.gridColumns(context).clamp(1, 3);
                    final spacing = 16.0;
                    final itemWidth =
                        (constraints.maxWidth - spacing * (cols - 1)) / cols;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: entitlements
                          .map((e) => SizedBox(
                                width: itemWidth,
                                child: _LibraryCard(entitlement: e),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Library card ──────────────────────────────────────────────────────────────

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.entitlement});
  final EntitlementModel entitlement;

  @override
  Widget build(BuildContext context) {
    final course = entitlement.course;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/library/courses/${course.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: course.thumbnailUrl != null
                  ? Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _ThumbnailPlaceholder(),
                    )
                  : _ThumbnailPlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  if (course.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        course.category!.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Title
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Instructor
                  Text(
                    course.instructorName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Continue learning button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.go('/library/courses/${course.id}'),
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Tiếp tục học'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.school_outlined, size: 48, color: AppTheme.primary),
      ),
    );
  }
}
