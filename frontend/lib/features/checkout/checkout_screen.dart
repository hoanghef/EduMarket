import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/seo/seo_data.dart';
import '../../core/seo/seo_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/widgets/app_shell.dart';
import '../cart/models/cart_models.dart';
import '../cart/providers/cart_provider.dart';
import '../cart/providers/coupon_provider.dart';
import '../cart/widgets/coupon_input_card.dart';
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
      final appliedCoupon = ref.read(couponProvider).coupon;
      final couponCode = appliedCoupon?.code;

      if (_paymentMethod == 'VNPAY') {
        final paymentResult = await repo.createVnpayPayment(couponCode: couponCode);
        if (paymentResult.paymentUrl.trim().isEmpty) {
          throw Exception('Không nhận được đường dẫn thanh toán từ hệ thống VNPay.');
        }
        ref.read(couponProvider.notifier).removeCoupon();
        ref.invalidate(cartProvider);
        if (mounted) {
          redirectToUrl(paymentResult.paymentUrl);
        }
      } else {
        final order = await repo.checkoutCod(couponCode: couponCode);
        ref.read(couponProvider.notifier).removeCoupon();
        ref.invalidate(cartProvider);
        if (mounted) {
          context.go('/account/orders/${order.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        } else if (e is Exception) {
          message = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đặt hàng: $message'),
            backgroundColor: AppTheme.error,
          ),
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
    SeoHelper.apply(SeoData.private(title: 'Thanh toán đơn hàng'));

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
                                  paymentMethod: _paymentMethod,
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
                                    paymentMethod: _paymentMethod,
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
            onChanged: onMethodChanged,
            child: Column(
              children: [
                RadioListTile<String>(
                  key: const Key('payment_method_cod'),
                  value: 'COD',
                  title: const Text('Thanh toán chuyển khoản (COD mô phỏng)'),
                  subtitle: const Text('Admin sẽ xác nhận thanh toán thủ công'),
                  secondary: const Icon(Icons.account_balance, color: AppTheme.primary),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  key: const Key('payment_method_vnpay'),
                  value: 'VNPAY',
                  title: const Text('Cổng thanh toán VNPay Sandbox'),
                  subtitle: const Text('Thanh toán qua thẻ ATM, QR Code hoặc thẻ quốc tế'),
                  secondary: const Icon(Icons.payment, color: AppTheme.primary),
                ),
                if (selectedMethod == 'VNPAY') ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bạn sẽ được chuyển hướng sang cổng thanh toán VNPay Sandbox an toàn để hoàn tất giao dịch.',
                            style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

class _CheckoutAction extends ConsumerWidget {
  const _CheckoutAction({
    required this.cart,
    required this.onPlaceOrder,
    this.paymentMethod = 'COD',
  });

  final CartModel cart;
  final VoidCallback onPlaceOrder;
  final String paymentMethod;

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

    final isVnpay = paymentMethod == 'VNPAY';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tổng thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const CouponInputCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                Text('${_fmtPrice(subtotal)}₫', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giảm giá:', style: TextStyle(color: AppTheme.onSurfaceVariant)),
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
                const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${_fmtPrice(total)}₫', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('place_order_button'),
              onPressed: onPlaceOrder,
              icon: Icon(isVnpay ? Icons.payment : Icons.check_circle_outline),
              label: Text(
                isVnpay ? 'Thanh toán qua VNPay' : 'Xác nhận đặt hàng',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 16),
            const Text('Bằng việc xác nhận, bạn đồng ý với Điều khoản dịch vụ của chúng tôi.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
