import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/course_card.dart';
import 'models/wishlist_model.dart';
import 'providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return AppShell(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khóa học yêu thích',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${wishlistState.items.length} khóa học đã lưu',
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.read(wishlistProvider.notifier).loadWishlist(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (wishlistState.isLoading && wishlistState.items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (wishlistState.errorMessage != null &&
                  wishlistState.items.isEmpty)
                _WishlistError(
                  message: wishlistState.errorMessage!,
                  onRetry: () =>
                      ref.read(wishlistProvider.notifier).loadWishlist(),
                )
              else if (wishlistState.items.isEmpty)
                const _EmptyWishlist()
              else
                _WishlistGrid(items: wishlistState.items),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Danh sách yêu thích trống',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khám phá hàng trăm khóa học hấp dẫn và lưu lại các khóa học bạn muốn học sau!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppConstants.routeCourses),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Khám phá khóa học ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistError extends StatelessWidget {
  const _WishlistError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistGrid extends ConsumerWidget {
  const _WishlistGrid({required this.items});
  final List<WishlistItemModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > Breakpoint.desktop
        ? 4
        : width > Breakpoint.tablet
            ? 3
            : width > 500
                ? 2
                : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 2.5 : 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Stack(
          children: [
            Positioned.fill(
              child: CourseCard(
                course: item.course,
                horizontal: crossAxisCount == 1,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Bỏ khỏi yêu thích',
                  icon: const Icon(Icons.favorite, color: AppTheme.error, size: 20),
                  onPressed: () async {
                    try {
                      await ref
                          .read(wishlistProvider.notifier)
                          .toggleWishlist(item.course.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa khỏi danh sách yêu thích'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
