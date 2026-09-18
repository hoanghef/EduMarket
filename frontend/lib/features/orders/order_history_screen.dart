import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'providers/order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(ordersProvider);

    return AppShell(
      child: asyncOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Lỗi khi tải lịch sử đơn hàng', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(e.toString()),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 80, color: AppTheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Bạn chưa có đơn hàng nào', style: Theme.of(context).textTheme.headlineSmall),
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
              padding: EdgeInsets.symmetric(horizontal: Breakpoint.pagePadding(context), vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lịch sử đơn hàng', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orders.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final df = DateFormat('dd/MM/yyyy HH:mm');
                          return Card(
                            child: InkWell(
                              onTap: () => context.go('/account/orders/${order.id}'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Đơn hàng: ${order.orderNumber}',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                        _OrderStatusChip(status: order.status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ngày đặt: ${df.format(order.createdAt)}',
                                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${order.items.length} sản phẩm',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Tổng: ${order.totalAmount.toInt()}₫',
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'WAITING_CONFIRMATION':
      case 'PENDING_PAYMENT':
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade800;
        label = status == 'WAITING_CONFIRMATION' ? 'Chờ xác nhận' : 'Chờ thanh toán';
        break;
      case 'PAID':
      case 'COMPLETED':
        bgColor = AppTheme.success.withValues(alpha: 0.1);
        textColor = AppTheme.success;
        label = status == 'PAID' ? 'Đã thanh toán' : 'Hoàn thành';
        break;
      case 'CANCELLED':
      case 'REFUNDED':
        bgColor = AppTheme.error.withValues(alpha: 0.1);
        textColor = AppTheme.error;
        label = status == 'CANCELLED' ? 'Đã hủy' : 'Đã hoàn tiền';
        break;
      default:
        bgColor = AppTheme.surface;
        textColor = AppTheme.onSurfaceVariant;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
