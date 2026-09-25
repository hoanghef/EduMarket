import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'models/order_models.dart';
import 'providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderDetailProvider(id));

    return AppShell(
      child: asyncOrder.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Không thể tải chi tiết đơn hàng',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(e.toString()),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(id)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (order) {
          final df = DateFormat('dd/MM/yyyy HH:mm');
          final isMobile = Breakpoint.isMobile(context);

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoint.pagePadding(context),
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: Breakpoint.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back navigation
                      InkWell(
                        onTap: () => context.go('/account/orders'),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back,
                                  size: 16, color: AppTheme.onSurfaceVariant),
                              SizedBox(width: 6),
                              Text(
                                'Quay lại danh sách đơn hàng',
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header with Title and Order Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết đơn hàng',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mã đơn: #${order.orderNumber}',
                                style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          _OrderStatusLabel(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OrderInfoCard(order: order, df: df),
                            const SizedBox(height: 16),
                            _OrderItemsCard(order: order),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _OrderItemsCard(order: order),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _OrderInfoCard(order: order, df: df),
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

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order, required this.df});
  final OrderModel order;
  final DateFormat df;

  String _fmtPrice(double p) {
    final n = p.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_outlined,
                    size: 18, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Thông tin đơn hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'Mã đơn hàng', value: order.orderNumber),
            const SizedBox(height: 10),
            _InfoRow(label: 'Ngày đặt', value: df.format(order.createdAt)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trạng thái',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 13)),
                _OrderStatusLabel(status: order.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            const Text(
              'Thanh toán',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Phương thức',
              value: order.payment?.method == 'VNPAY'
                  ? 'VNPay Sandbox'
                  : (order.payment?.method ?? 'COD'),
            ),
            const SizedBox(height: 10),
            _InfoRow(
                label: 'Tạm tính', value: '${_fmtPrice(order.subtotal)}₫'),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Giảm giá',
              value: order.discountAmount > 0
                  ? '-${_fmtPrice(order.discountAmount)}₫'
                  : '0₫',
              isDiscount: order.discountAmount > 0,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  '${_fmtPrice(order.totalAmount)}₫',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            if (order.status == 'WAITING_CONFIRMATION' &&
                order.payment?.method == 'COD') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vui lòng chuyển khoản theo hướng dẫn của CSKH. Đơn hàng sẽ được duyệt sau khi nhận được thanh toán.',
                        style: TextStyle(
                            color: Color(0xFF1E40AF), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (order.status == 'PAID' || order.status == 'COMPLETED') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/library'),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Đến thư viện học ngay'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDiscount ? AppTheme.success : null,
          ),
        ),
      ],
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});
  final OrderModel order;

  String _fmtPrice(double p) {
    final n = p.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sản phẩm đã mua',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '${order.items.length} khóa học',
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.divider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 22,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(
                  item.courseTitleSnapshot,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Mã khóa học: ${item.courseId}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.onSurfaceVariant),
                  ),
                ),
                trailing: Text(
                  '${_fmtPrice(item.discountedUnitPrice)}₫',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderStatusLabel extends StatelessWidget {
  const _OrderStatusLabel({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'WAITING_CONFIRMATION':
        bgColor = Colors.amber.withValues(alpha: 0.12);
        textColor = Colors.amber.shade900;
        icon = Icons.hourglass_top_rounded;
        label = 'Chờ xác nhận';
        break;
      case 'PENDING_PAYMENT':
        bgColor = Colors.orange.withValues(alpha: 0.12);
        textColor = Colors.orange.shade800;
        icon = Icons.schedule_rounded;
        label = 'Chờ thanh toán';
        break;
      case 'PAID':
        bgColor = AppTheme.success.withValues(alpha: 0.12);
        textColor = AppTheme.success;
        icon = Icons.check_circle_outline;
        label = 'Đã thanh toán';
        break;
      case 'COMPLETED':
        bgColor = AppTheme.success.withValues(alpha: 0.12);
        textColor = AppTheme.success;
        icon = Icons.verified_outlined;
        label = 'Hoàn thành';
        break;
      case 'CANCELLED':
        bgColor = AppTheme.error.withValues(alpha: 0.12);
        textColor = AppTheme.error;
        icon = Icons.cancel_outlined;
        label = 'Đã hủy';
        break;
      case 'REFUNDED':
        bgColor = Colors.purple.withValues(alpha: 0.12);
        textColor = Colors.purple.shade700;
        icon = Icons.replay_rounded;
        label = 'Đã hoàn tiền';
        break;
      default:
        bgColor = AppTheme.surfaceVariant;
        textColor = AppTheme.onSurfaceVariant;
        icon = Icons.info_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
