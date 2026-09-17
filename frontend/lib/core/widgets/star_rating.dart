import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Star rating display with numeric count.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 13.0,
    this.showCount = true,
  });

  final double rating;
  final int count;
  final double size;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Numeric rating
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 3),
        // Stars
        ...List.generate(5, (i) {
          if (rating >= i + 1) {
            return Icon(Icons.star_rounded, size: size + 1, color: AppTheme.accent);
          } else if (rating > i) {
            return Icon(Icons.star_half_rounded, size: size + 1, color: AppTheme.accent);
          } else {
            return Icon(Icons.star_outline_rounded,
                size: size + 1, color: AppTheme.accent.withValues(alpha: 0.4));
          }
        }),
        if (showCount && count > 0) ...[
          const SizedBox(width: 3),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size - 1,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
