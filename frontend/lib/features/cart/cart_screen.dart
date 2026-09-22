import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'models/cart_models.dart';
import 'providers/cart_provider.dart';
import 'providers/coupon_provider.dart';
import 'widgets/coupon_input_card.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCart = ref.watch(cartProvider);

    return AppShell(
      child: asyncCart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Lỗi khi tải giỏ hàng',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(e.toString()),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(cartProvider.notifier).refreshCart(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (cart) {
          final isMobile = Breakpoint.isMobile(context);

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Giỏ hàng trống',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/khoa-hoc'),
                    child: const Text('Khám phá khóa học'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Breakpoint.pagePadding(context), vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: Breakpoint.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giỏ hàng của bạn',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CartItemsList(cart: cart),
                            const SizedBox(height: 32),
                            _CartSummary(cart: cart),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _CartItemsList(cart: cart),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 1,
                              child: _CartSummary(cart: cart),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartItemsList extends ConsumerWidget {
  const _CartItemsList({required this.cart});
  final CartModel cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cart.items.length,
        separatorBuilder: (context, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = cart.items[index];
          final course = item.course;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      course.thumbnailUrl!,
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 80,
                        color: AppTheme.surface,
                        child: const Icon(Icons.image_not_supported, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: AppTheme.onSurfaceVariant),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(course.instructorName,
                          style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).removeFromCart(item.id);
                        },
                        child: const Text('Xóa',
                            style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${course.effectivePrice.toInt()}₫',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 16),
                    ),
                    if (course.isOnSale)
                      Text(
                        '${course.price.toInt()}₫',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.cart});
  final CartModel cart;

  String _fmtPrice(double p) {
    final n = p.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponState = ref.watch(couponProvider);
    final applied = couponState.coupon;

    final subtotal = applied != null ? applied.subtotal : cart.subtotal;
    final discount = applied != null ? applied.discountAmount : 0.0;
    final total = applied != null ? applied.totalAmount : cart.subtotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tóm tắt đơn hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const CouponInputCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:',
                    style: TextStyle(color: AppTheme.onSurfaceVariant)),
                Text('${_fmtPrice(subtotal)}₫',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giảm giá:',
                    style: TextStyle(color: AppTheme.onSurfaceVariant)),
                Text(
                  discount > 0 ? '-${_fmtPrice(discount)}₫' : '0₫',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: discount > 0 ? AppTheme.success : null,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  '${_fmtPrice(total)}₫',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/checkout'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
