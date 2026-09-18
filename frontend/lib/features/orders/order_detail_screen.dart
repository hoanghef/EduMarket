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
              Text('Không thể tải chi tiết đơn hàng', style: Theme.of(context).textTheme.headlineSmall),
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
              padding: EdgeInsets.symmetric(horizontal: Breakpoint.pagePadding(context), vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/account/orders'),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back, size: 16, color: AppTheme.onSurfaceVariant),
                            SizedBox(width: 8),
                            Text('Quay lại danh sách', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Chi tiết đơn hàng', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OrderInfoCard(order: order, df: df),
                            const SizedBox(height: 24),
                            _OrderItemsCard(order: order),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _OrderItemsCard(order: order),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 1,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            _InfoRow(label: 'Mã đơn hàng', value: order.orderNumber),
            const SizedBox(height: 12),
            _InfoRow(label: 'Ngày đặt', value: df.format(order.createdAt)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trạng thái', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                _OrderStatusLabel(status: order.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            const Text('Thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _InfoRow(label: 'Phương thức', value: order.payment?.method ?? 'N/A'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Tạm tính', value: '${order.subtotal.toInt()}₫'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Giảm giá', value: '${order.discountAmount.toInt()}₫'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${order.totalAmount.toInt()}₫', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppTheme.primary)),
              ],
            ),
            if (order.status == 'WAITING_CONFIRMATION' && order.payment?.method == 'COD') ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vui lòng chuyển khoản theo hướng dẫn của CSKH. Đơn hàng sẽ được duyệt sau khi nhận được thanh toán.',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
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
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sản phẩm đã mua', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                leading: const Icon(Icons.school_outlined, size: 32, color: AppTheme.onSurfaceVariant),
                title: Text(item.courseTitleSnapshot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('ID: ${item.courseId}', style: const TextStyle(fontSize: 12)),
                trailing: Text('${item.discountedUnitPrice.toInt()}₫', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
    Color color;
    String label;

    switch (status) {
      case 'WAITING_CONFIRMATION':
      case 'PENDING_PAYMENT':
        color = Colors.orange.shade800;
        label = status == 'WAITING_CONFIRMATION' ? 'Chờ xác nhận' : 'Chờ thanh toán';
        break;
      case 'PAID':
      case 'COMPLETED':
        color = AppTheme.success;
        label = status == 'PAID' ? 'Đã thanh toán' : 'Hoàn thành';
        break;
      case 'CANCELLED':
      case 'REFUNDED':
        color = AppTheme.error;
        label = status == 'CANCELLED' ? 'Đã hủy' : 'Đã hoàn tiền';
        break;
      default:
        color = AppTheme.onSurfaceVariant;
        label = status;
    }

    return Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700));
  }
}
