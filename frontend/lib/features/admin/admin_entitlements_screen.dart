import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'models/admin_models.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminEntitlementsScreen extends ConsumerStatefulWidget {
  const AdminEntitlementsScreen({super.key});

  @override
  ConsumerState<AdminEntitlementsScreen> createState() =>
      _AdminEntitlementsScreenState();
}

class _AdminEntitlementsScreenState
    extends ConsumerState<AdminEntitlementsScreen> {
  String? _selectedStatus;

  void _showRevokeDialog(AdminEntitlementModel ent) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thu hồi quyền truy cập - ${ent.customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Khóa học: ${ent.courseTitle}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Lý do thu hồi quyền *',
                hintText: 'VD: Hoàn tiền, vi phạm điều khoản dịch vụ...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.length < 2) return;
              try {
                await ref
                    .read(adminRepositoryProvider)
                    .revokeEntitlement(ent.id, reason);
                ref.invalidate(adminEntitlementsProvider(_selectedStatus));
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thu hồi quyền truy cập khóa học.'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Xác nhận thu hồi'),
          ),
        ],
      ),
    );
  }

  void _restoreAccess(AdminEntitlementModel ent) async {
    try {
      await ref.read(adminRepositoryProvider).grantEntitlement(
            userId: ent.userId,
            courseId: ent.courseId,
            orderId: ent.orderId,
          );
      ref.invalidate(adminEntitlementsProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã khôi phục quyền truy cập khóa học thành công!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khôi phục: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncEntitlements =
        ref.watch(adminEntitlementsProvider(_selectedStatus));

    final filterOptions = [
      (label: 'Tất cả', value: null),
      (label: 'Đang hoạt động', value: 'ACTIVE'),
      (label: 'Bị thu hồi', value: 'REVOKED'),
    ];

    return AdminShell(
      currentRoute: '/admin/entitlements',
      title: 'Quản lý quyền truy cập khóa học',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.invalidate(adminEntitlementsProvider(_selectedStatus)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: filterOptions.map((item) {
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
          const SizedBox(height: 16),
          asyncEntitlements.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Lỗi tải quyền truy cập: $err',
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Text('Không tìm thấy quyền truy cập nào.'),
                  ),
                );
              }

              return Card(
                elevation: 1,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Khách hàng')),
                      DataColumn(label: Text('Khóa học')),
                      DataColumn(label: Text('Mã đơn')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Ngày cấp')),
                      DataColumn(label: Text('Lý do thu hồi')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: items.map((ent) {
                      final isActive = ent.status == 'ACTIVE';

                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(ent.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(ent.customerEmail,
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          DataCell(Text(ent.courseTitle)),
                          DataCell(Text(ent.orderNumber)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isActive ? AppTheme.success : AppTheme.error)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ent.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppTheme.success : AppTheme.error,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(
                              '${ent.grantedAt.day}/${ent.grantedAt.month}/${ent.grantedAt.year}')),
                          DataCell(Text(ent.revokeReason ?? '—')),
                          DataCell(
                            isActive
                                ? OutlinedButton.icon(
                                    onPressed: () => _showRevokeDialog(ent),
                                    icon: const Icon(Icons.block, size: 14, color: AppTheme.error),
                                    label: const Text('Thu hồi',
                                        style: TextStyle(color: AppTheme.error, fontSize: 12)),
                                  )
                                : FilledButton.tonalIcon(
                                    onPressed: () => _restoreAccess(ent),
                                    icon: const Icon(Icons.restore, size: 14),
                                    label: const Text('Khôi phục', style: TextStyle(fontSize: 12)),
                                  ),
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
