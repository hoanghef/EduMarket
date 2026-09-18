import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../cart/models/cart_models.dart';
import '../cart/providers/cart_provider.dart';
import '../orders/providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;
  String _paymentMethod = 'COD';

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.checkoutCod();
      // Clear cart state via invalidation or refresh, but typically successful checkout clears it on server.
      ref.invalidate(cartProvider);
      if (mounted) {
        context.go('/account/orders/${order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đặt hàng: ${e.toString()}'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCart = ref.watch(cartProvider);

    return AppShell(
      child: asyncCart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (cart) {
          final isMobile = Breakpoint.isMobile(context);

          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Giỏ hàng trống, không thể thanh toán', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/khoa-hoc'),
                    child: const Text('Quay lại mua sắm'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Breakpoint.pagePadding(context), vertical: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thanh toán', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 24),
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PaymentMethodSelection(
                                  selectedMethod: _paymentMethod,
                                  onMethodChanged: (val) => setState(() => _paymentMethod = val!),
                                ),
                                const SizedBox(height: 32),
                                _OrderSummaryDetails(cart: cart),
                                const SizedBox(height: 32),
                                _CheckoutAction(
                                  cart: cart,
                                  onPlaceOrder: _placeOrder,
                                ),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _PaymentMethodSelection(
                                        selectedMethod: _paymentMethod,
                                        onMethodChanged: (val) => setState(() => _paymentMethod = val!),
                                      ),
                                      const SizedBox(height: 32),
                                      _OrderSummaryDetails(cart: cart),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 1,
                                  child: _CheckoutAction(
                                    cart: cart,
                                    onPlaceOrder: _placeOrder,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang xử lý đơn hàng...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentMethodSelection extends StatelessWidget {
  const _PaymentMethodSelection({required this.selectedMethod, required this.onMethodChanged});
  final String selectedMethod;
  final ValueChanged<String?> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: RadioGroup<String>(
            groupValue: selectedMethod,
            onChanged: (val) {
              if (val != 'VNPAY') {
                onMethodChanged(val);
              }
            },
            child: Column(
              children: [
                RadioListTile(
                  value: 'COD',
                  title: const Text('Thanh toán chuyển khoản (COD mô phỏng)'),
                  subtitle: const Text('Admin sẽ xác nhận thanh toán thủ công'),
                  secondary: const Icon(Icons.account_balance, color: AppTheme.primary),
                ),
                const Divider(height: 1),
                Opacity(
                  opacity: 0.5,
                  child: IgnorePointer(
                    child: RadioListTile(
                      value: 'VNPAY',
                      title: const Text('VNPay (Đang phát triển)'),
                      secondary: const Icon(Icons.payment, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryDetails extends StatelessWidget {
  const _OrderSummaryDetails({required this.cart});
  final CartModel cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chi tiết đơn hàng (${cart.items.length} khóa học)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.items.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final course = cart.items[index].course;
              return ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text('${course.effectivePrice.toInt()}₫', style: const TextStyle(fontWeight: FontWeight.w700)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CheckoutAction extends StatelessWidget {
  const _CheckoutAction({required this.cart, required this.onPlaceOrder});
  final CartModel cart;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tổng thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                Text('${cart.subtotal.toInt()}₫', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giảm giá:', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                Text('0₫', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${cart.subtotal.toInt()}₫', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPlaceOrder,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Xác nhận đặt hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 16),
            const Text('Bằng việc xác nhận, bạn đồng ý với Điều khoản dịch vụ của chúng tôi.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
