import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(adminUsersProvider);

    return AdminShell(
      currentRoute: '/admin/users',
      title: 'Quản lý người dùng',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminUsersProvider),
        ),
      ],
      child: asyncUsers.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('Lỗi tải người dùng: $err',
                style: const TextStyle(color: AppTheme.error)),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Text('Không tìm thấy người dùng nào.'),
              ),
            );
          }

          return Card(
            elevation: 1,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Họ và tên')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Vai trò')),
                  DataColumn(label: Text('Đơn hàng')),
                  DataColumn(label: Text('Khóa học sở hữu')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Ngày tạo')),
                ],
                rows: users.map((u) {
                  final isAdmin = u.role == 'ADMIN';
                  return DataRow(
                    cells: [
                      DataCell(Text(u.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(u.email)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.amber.shade100
                                : AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            u.role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? Colors.brown : AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${u.orderCount}')),
                      DataCell(Text('${u.entitlementCount}')),
                      DataCell(
                        Icon(
                          u.isActive ? Icons.check_circle : Icons.cancel,
                          color: u.isActive ? AppTheme.success : AppTheme.error,
                          size: 18,
                        ),
                      ),
                      DataCell(Text(
                          '${u.createdAt.day}/${u.createdAt.month}/${u.createdAt.year}')),
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
