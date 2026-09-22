import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/coupon_provider.dart';

class CouponInputCard extends ConsumerStatefulWidget {
  const CouponInputCard({super.key});

  @override
  ConsumerState<CouponInputCard> createState() => _CouponInputCardState();
}

class _CouponInputCardState extends ConsumerState<CouponInputCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim();
    if (code.isNotEmpty) {
      ref.read(couponProvider.notifier).applyCoupon(code);
    }
  }

  String _fmtPrice(double p) {
    final n = p.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final couponState = ref.watch(couponProvider);
    final applied = couponState.coupon;

    if (applied != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã giảm giá: ${applied.code}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Giảm ${_fmtPrice(applied.discountAmount)}₫',
                    style: const TextStyle(fontSize: 12, color: AppTheme.onSurface),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Gỡ bỏ mã',
              icon: const Icon(Icons.close, size: 18, color: AppTheme.onSurfaceVariant),
              onPressed: () {
                ref.read(couponProvider.notifier).removeCoupon();
                _controller.clear();
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Nhập mã giảm giá',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: couponState.isValidating ? null : _apply,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: couponState.isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Áp dụng', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (couponState.errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            couponState.errorMessage!,
            style: const TextStyle(color: AppTheme.error, fontSize: 12),
          ),
        ],
        if (couponState.successMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            couponState.successMessage!,
            style: const TextStyle(color: AppTheme.success, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
