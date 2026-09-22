import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminCouponsScreen extends ConsumerWidget {
  const AdminCouponsScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String discountType = 'PERCENTAGE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tạo mã khuyến mãi mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Mã giảm giá (VD: SALE20) *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                  items: const [
                    DropdownMenuItem(value: 'PERCENTAGE', child: Text('Phần trăm (%)')),
                    DropdownMenuItem(value: 'FIXED', child: Text('Số tiền cố định (₫)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => discountType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: discountType == 'PERCENTAGE'
                        ? 'Giá trị giảm (%) *'
                        : 'Giá trị giảm (VNĐ) *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đơn hàng tối thiểu (VNĐ, tùy chọn)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượt sử dụng tối đa (tùy chọn)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeCtrl.text.trim().toUpperCase();
                final val = double.tryParse(valueCtrl.text.trim());
                if (code.isEmpty || val == null || val <= 0) return;

                final data = <String, dynamic>{
                  'code': code,
                  'discountType': discountType,
                  'discountValue': val,
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                  if (minOrderCtrl.text.trim().isNotEmpty)
                    'minimumOrderAmount': double.tryParse(minOrderCtrl.text.trim()),
                  if (limitCtrl.text.trim().isNotEmpty)
                    'usageLimit': int.tryParse(limitCtrl.text.trim()),
                };

                try {
                  await ref.read(adminRepositoryProvider).createCoupon(data);
                  ref.invalidate(adminCouponsProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Lỗi tạo mã: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Tạo mã'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtMoney(double amount) {
    final n = amount.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCoupons = ref.watch(adminCouponsProvider);

    return AdminShell(
      currentRoute: '/admin/coupons',
      title: 'Quản lý mã khuyến mãi',
      actions: [
        FilledButton.icon(
          onPressed: () => _showCreateDialog(context, ref),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tạo mã mới'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminCouponsProvider),
        ),
      ],
      child: asyncCoupons.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('Lỗi tải mã giảm giá: $err',
                style: const TextStyle(color: AppTheme.error)),
          ),
        ),
        data: (coupons) {
          if (coupons.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Text('Chưa có mã khuyến mãi nào.'),
              ),
            );
          }

          return Card(
            elevation: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Mã code')),
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Mức giảm')),
                  DataColumn(label: Text('Đơn tối thiểu')),
                  DataColumn(label: Text('Đã dùng / Giới hạn')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Bật / Tắt')),
                ],
                rows: coupons.map((c) {
                  final isPercentage = c.discountType == 'PERCENTAGE';
                  final discountText = isPercentage
                      ? '${c.discountValue.toInt()}%'
                      : '${_fmtMoney(c.discountValue)}₫';
                  final minOrderText = c.minimumOrderAmount != null
                      ? '${_fmtMoney(c.minimumOrderAmount!)}₫'
                      : 'Không';
                  final usageText =
                      '${c.usageCount} / ${c.usageLimit ?? '∞'}';

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(isPercentage ? 'Phần trăm' : 'Cố định')),
                      DataCell(Text(discountText,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(minOrderText)),
                      DataCell(Text(usageText)),
                      DataCell(
                        Text(
                          c.isActive ? 'Đang kích hoạt' : 'Tạm dừng',
                          style: TextStyle(
                            color: c.isActive ? AppTheme.success : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Switch(
                          value: c.isActive,
                          onChanged: (val) async {
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .toggleCouponActive(c.id, val);
                              ref.invalidate(adminCouponsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
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
    );
  }
}
