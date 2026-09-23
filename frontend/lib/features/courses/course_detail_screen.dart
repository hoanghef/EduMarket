import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/seo/seo_data.dart';
import '../../core/seo/seo_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/course_card.dart';
import '../../core/widgets/star_rating.dart';
import '../courses/models/catalog_models.dart';
import '../courses/providers/catalog_provider.dart';
import '../cart/providers/cart_provider.dart';
import '../reviews/widgets/course_reviews_section.dart';
import '../wishlist/providers/wishlist_provider.dart';

/// `/khoa-hoc/:slug`
class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourse = ref.watch(courseDetailProvider(slug));
    return AppShell(
      child: asyncCourse.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy khóa học',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.refresh(courseDetailProvider(slug)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (course) => _CourseDetailBody(course: course),
      ),
    );
  }
}

class _CourseDetailBody extends ConsumerWidget {
  const _CourseDetailBody({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SeoHelper.apply(SeoData.course(course: course));
    final asyncRecs = ref.watch(recommendationsProvider(course.id));
    final isMobile = Breakpoint.isMobile(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header banner ──────────────────────────────────────────────────
          _CourseHero(course: course),

          // ── Content ───────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Breakpoint.pagePadding(context),
              vertical: 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: Breakpoint.maxContentWidth),
                child: isMobile
                    ? _MobileLayout(course: course, asyncRecs: asyncRecs)
                    : _DesktopLayout(course: course, asyncRecs: asyncRecs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoint.isMobile(context);
    return Container(
      width: double.infinity,
      color: AppTheme.onSurface,
      padding: EdgeInsets.symmetric(
        horizontal: Breakpoint.pagePadding(context),
        vertical: isMobile ? 24 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/khoa-hoc'),
                          child: const Text('Khóa học',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13)),
                        ),
                        if (course.category != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('/',
                                style: TextStyle(
                                    color: Color(0xFF64748B))),
                          ),
                          GestureDetector(
                            onTap: () => context
                                .go('/danh-muc/${course.category!.slug}'),
                            child: Text(
                              course.category!.name,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      course.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 32,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (course.shortDescription != null)
                      Text(
                        course.shortDescription!,
                        style: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 15, height: 1.5),
                      ),
                    const SizedBox(height: 16),
                    // Rating + enrollment
                    Row(
                      children: [
                        StarRating(rating: course.ratingAverage, count: course.ratingCount),
                        const SizedBox(width: 16),
                        const Icon(Icons.people_outline, size: 15, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          '${course.enrollmentCount} học viên',
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Instructor
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 15, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          course.instructorName,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        _LevelPill(level: course.level),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 32),
                // Sticky buy card (desktop)
                SizedBox(
                  width: 300,
                  child: _BuyCard(course: course),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop layout ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.course, required this.asyncRecs});
  final CourseModel course;
  final AsyncValue<List<CourseModel>> asyncRecs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _CourseContent(course: course, asyncRecs: asyncRecs),
        ),
        const SizedBox(width: 32),
        const SizedBox(width: 300), // spacer matching buy card above
      ],
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.course, required this.asyncRecs});
  final CourseModel course;
  final AsyncValue<List<CourseModel>> asyncRecs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuyCard(course: course),
        const SizedBox(height: 24),
        _CourseContent(course: course, asyncRecs: asyncRecs),
      ],
    );
  }
}

// ── Course content (description, lessons, recommendations) ────────────────────

class _CourseContent extends StatelessWidget {
  const _CourseContent({required this.course, required this.asyncRecs});
  final CourseModel course;
  final AsyncValue<List<CourseModel>> asyncRecs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Description ──────────────────────────────────────────────────────
        if (course.description != null && course.description!.isNotEmpty) ...[
          Text('Mô tả', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            course.description!,
            style: const TextStyle(height: 1.7, fontSize: 14),
          ),
          const SizedBox(height: 32),
        ],

        // ── Lesson list ───────────────────────────────────────────────────────
        if (course.lessons.isNotEmpty) ...[
          Text(
            'Nội dung khóa học (${course.lessons.length} bài học)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: course.lessons.length,
              separatorBuilder: (context, _) =>
                  const Divider(height: 0, indent: 16, endIndent: 16),
              itemBuilder: (context, i) => _LessonTile(lesson: course.lessons[i]),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // ── Reviews Section ───────────────────────────────────────────────────
        CourseReviewsSection(
          courseId: course.id,
          ratingAverage: course.ratingAverage,
          ratingCount: course.ratingCount,
        ),
        const SizedBox(height: 32),

        // ── Recommendations ───────────────────────────────────────────────────
        asyncRecs.when(
          loading: () => const LoadingRow(itemCount: 4),
          error: (e, _) => const SizedBox.shrink(),
          data: (recs) {
            if (recs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Khóa học liên quan',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recs.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 16),
                    itemBuilder: (context, i) =>
                        SizedBox(width: 220, child: CourseCard(course: recs[i])),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});
  final LessonSummary lesson;

  String _fmtDuration(int? sec) {
    if (sec == null) return '';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: lesson.isPreview
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Text(
            '${lesson.position}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: lesson.isPreview ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(lesson.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lesson.isPreview)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Xem thử',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 8),
          if (lesson.durationSec != null)
            Text(_fmtDuration(lesson.durationSec),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Buy card ──────────────────────────────────────────────────────────────────

class _BuyCard extends ConsumerWidget {
  const _BuyCard({required this.course});
  final CourseModel course;

  String _fmtPrice(double p) {
    final n = p.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(cartProvider.notifier).addToCart(course.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã thêm khóa học vào giỏ hàng!'),
            action: SnackBarAction(
              label: 'Xem giỏ hàng',
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm vào giỏ hàng: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price
            if (course.isFree)
              const Text('Miễn phí',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.success))
            else ...[
              Text(
                '${_fmtPrice(course.effectivePrice)}₫',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary),
              ),
              if (course.isOnSale)
                Row(
                  children: [
                    Text(
                      '${_fmtPrice(course.price)}₫',
                      style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${(((course.price - course.salePrice!) / course.price) * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 16),
            // CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _addToCart(context, ref),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Thêm vào giỏ hàng',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isInWishlist =
                    ref.watch(wishlistProvider).containsCourse(course.id);
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final added = await ref
                            .read(wishlistProvider.notifier)
                            .toggleWishlist(course.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(added
                                  ? 'Đã thêm khóa học vào danh sách yêu thích!'
                                  : 'Đã xóa khóa học khỏi danh sách yêu thích!'),
                              action: SnackBarAction(
                                label: 'Xem yêu thích',
                                onPressed: () => context.go('/wishlist'),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? AppTheme.error : null,
                      size: 18,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    label: Text(isInWishlist ? 'Đã lưu yêu thích' : 'Thêm vào yêu thích'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Stats
            _StatRow(icon: Icons.book_outlined, label: '${course.lessons.length} bài học'),
            if (course.durationSec != null)
              _StatRow(
                  icon: Icons.access_time,
                  label: '${(course.durationSec! ~/ 3600)}h ${(course.durationSec! % 3600 ~/ 60)}m'),
            _StatRow(icon: Icons.workspace_premium_outlined, label: 'Chứng chỉ hoàn thành'),
            _StatRow(icon: Icons.download_outlined, label: 'Tài liệu tải về'),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.onSurface)),
        ],
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final String level;

  static const _map = {
    'BEGINNER': 'Cơ bản',
    'INTERMEDIATE': 'Trung cấp',
    'ADVANCED': 'Nâng cao',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _map[level] ?? level,
        style: const TextStyle(
            color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
