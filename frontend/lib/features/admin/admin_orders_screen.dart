import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _selectedStatus;

  String _fmtMoney(double amount) {
    final n = amount.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(adminOrdersProvider(_selectedStatus));

    final filterStatuses = [
      (label: 'Tất cả', value: null),
      (label: 'Chờ xác nhận COD', value: 'WAITING_CONFIRMATION'),
      (label: 'Đã thanh toán', value: 'PAID'),
      (label: 'Hoàn thành', value: 'COMPLETED'),
      (label: 'Đã hủy', value: 'CANCELLED'),
    ];

    return AdminShell(
      currentRoute: '/admin/orders',
      title: 'Quản lý đơn hàng',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminOrdersProvider(_selectedStatus)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterStatuses.map((item) {
                final isSelected = _selectedStatus == item.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(item.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = item.value);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          asyncOrders.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Lỗi tải đơn hàng: $err',
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Text('Không có đơn hàng nào.'),
                  ),
                );
              }

              return Card(
                elevation: 1,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Mã đơn hàng')),
                      DataColumn(label: Text('Khách hàng')),
                      DataColumn(label: Text('Phương thức')),
                      DataColumn(label: Text('Số lượng')),
                      DataColumn(label: Text('Tổng thanh toán')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Ngày đặt')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: orders.map((ord) {
                      Color statusColor = Colors.grey;
                      if (ord.status == 'PAID' || ord.status == 'COMPLETED') {
                        statusColor = AppTheme.success;
                      } else if (ord.status == 'WAITING_CONFIRMATION') {
                        statusColor = Colors.orange;
                      }

                      final canConfirmCod = ord.status == 'WAITING_CONFIRMATION' &&
                          ord.paymentMethod == 'COD';

                      return DataRow(
                        cells: [
                          DataCell(Text(ord.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(ord.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(ord.customerEmail,
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          DataCell(Text(ord.paymentMethod)),
                          DataCell(Text('${ord.itemCount} khóa học')),
                          DataCell(Text('${_fmtMoney(ord.totalAmount)}₫',
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ord.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(
                              '${ord.createdAt.day}/${ord.createdAt.month}/${ord.createdAt.year}')),
                          DataCell(
                            canConfirmCod
                                ? FilledButton.tonal(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(adminRepositoryProvider)
                                            .confirmCodOrder(ord.id);
                                        ref.invalidate(adminOrdersProvider(_selectedStatus));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Đã xác nhận thanh toán COD đơn ${ord.orderNumber}!'),
                                              backgroundColor: AppTheme.success,
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
                                    child: const Text('Xác nhận COD', style: TextStyle(fontSize: 12)),
                                  )
                                : const Text('—', style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
