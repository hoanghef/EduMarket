import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/courses/models/catalog_models.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../theme/app_theme.dart';
import 'star_rating.dart';

/// Responsive course card. On desktop displays as a vertical card,
/// on list mode renders a horizontal layout.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.horizontal = false,
  });

  final CourseModel course;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return horizontal ? _HorizontalCard(course: course) : _VerticalCard(course: course);
  }
}

// ── Vertical grid card ────────────────────────────────────────────────────────

class _VerticalCard extends StatefulWidget {
  const _VerticalCard({required this.course});
  final CourseModel course;

  @override
  State<_VerticalCard> createState() => _VerticalCardState();
}

class _VerticalCardState extends State<_VerticalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovered
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? AppTheme.primary.withValues(alpha: 0.3)
                : AppTheme.divider,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: InkWell(
          onTap: () => context.go('/khoa-hoc/${course.slug}'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ───────────────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _CourseThumbnail(
                        url: course.thumbnailUrl,
                        title: course.title,
                        category: course.category?.name,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final isFav = ref
                            .watch(wishlistProvider)
                            .containsCourse(course.id);
                        return Material(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () async {
                              try {
                                await ref
                                    .read(wishlistProvider.notifier)
                                    .toggleWishlist(course.id);
                              } catch (_) {}
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: AnimatedScale(
                                scale: isFav ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? AppTheme.error : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // ── Body ─────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    if (course.category != null)
                      _SmallChip(label: course.category!.name),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.25,
                          ),
                    ),
                    const SizedBox(height: 3),
                    // Instructor
                    Text(
                      course.instructorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    // Rating
                    StarRating(
                      rating: course.ratingAverage,
                      count: course.ratingCount,
                    ),
                    const SizedBox(height: 6),
                    // Price
                    _PriceRow(course: course),
                    const SizedBox(height: 4),
                    // Level badge
                    _LevelBadge(level: course.level),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Horizontal list card ──────────────────────────────────────────────────────

class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/khoa-hoc/${course.slug}'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              width: 160,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _CourseThumbnail(
                        url: course.thumbnailUrl,
                        title: course.title,
                        category: course.category?.name,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final isFav = ref.watch(wishlistProvider).containsCourse(course.id);
                        return Material(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () async {
                              try {
                                await ref.read(wishlistProvider.notifier).toggleWishlist(course.id);
                              } catch (_) {}
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? AppTheme.error : Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.instructorName,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    StarRating(rating: course.ratingAverage, count: course.ratingCount),
                    const SizedBox(height: 6),
                    _PriceRow(course: course),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared subwidgets ─────────────────────────────────────────────────────────

class _CourseThumbnail extends StatelessWidget {
  const _CourseThumbnail({required this.url, required this.title, this.category});
  final String? url;
  final String title;
  final String? category;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (context, e, _) =>
            _Placeholder(title: title, category: category),
      );
    }
    return _Placeholder(title: title, category: category);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, this.category});
  final String title;
  final String? category;

  /// Returns gradient colors based on category name
  List<Color> get _gradientColors {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('lập trình') || cat.contains('phát triển')) {
      return [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];
    } else if (cat.contains('thiết kế')) {
      return [const Color(0xFFEC4899), const Color(0xFFF59E0B)];
    } else if (cat.contains('kinh doanh') || cat.contains('marketing')) {
      return [const Color(0xFF059669), const Color(0xFF0891B2)];
    } else if (cat.contains('dữ liệu') || cat.contains('khoa học')) {
      return [const Color(0xFF0EA5E9), const Color(0xFF6366F1)];
    } else if (cat.contains('di động') || cat.contains('mobile')) {
      return [const Color(0xFFF97316), const Color(0xFFEF4444)];
    }
    return [const Color(0xFF4F46E5), const Color(0xFF06B6D4)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    if (course.isFree) {
      return const Text(
        'Miễn phí',
        style: TextStyle(
          color: AppTheme.success,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatPrice(course.effectivePrice),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (course.isOnSale) ...[
            const SizedBox(width: 6),
            Text(
              _formatPrice(course.price),
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            _SaleBadge(
              discount: (((course.price - course.salePrice!) / course.price) * 100).round(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final n = price.toInt();
    final s = n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return '$s₫';
  }
}

class _SaleBadge extends StatelessWidget {
  const _SaleBadge({required this.discount});
  final int discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '-$discount%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final String level;

  static const _labels = {
    'BEGINNER': 'Cơ bản',
    'INTERMEDIATE': 'Trung cấp',
    'ADVANCED': 'Nâng cao',
  };

  static const _colors = {
    'BEGINNER': Color(0xFF10B981),
    'INTERMEDIATE': Color(0xFFF59E0B),
    'ADVANCED': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level] ?? AppTheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _labels[level] ?? level,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
