import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import 'models/admin_models.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  String _fmtMoney(double amount) {
    final n = amount.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboard = ref.watch(adminDashboardProvider);

    return AdminShell(
      currentRoute: '/admin',
      title: 'Bảng điều khiển quản trị',
      actions: [
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminDashboardProvider),
        ),
      ],
      child: asyncDashboard.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(64.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text('Không thể tải số liệu quản trị: $err'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(adminDashboardProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (metrics) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Stat Cards Grid
            _buildStatGrid(context, metrics),
            const SizedBox(height: 24),

            // Quick Navigation Hub
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Revenue and Best-Sellers Row
            _buildInsightsRow(context, metrics),
            const SizedBox(height: 24),

            // Recent Orders Card
            _buildRecentOrdersCard(context, metrics.recentOrders),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, AdminDashboardMetrics metrics) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > Breakpoint.desktop
        ? 4
        : width > Breakpoint.tablet
            ? 2
            : 1;

    final stats = [
      (
        title: 'Tổng doanh thu',
        value: '${_fmtMoney(metrics.totalRevenue)}₫',
        icon: Icons.monetization_on_outlined,
        color: Colors.green,
      ),
      (
        title: 'Tổng đơn hàng',
        value: '${metrics.orderCount}',
        icon: Icons.receipt_long_outlined,
        color: AppTheme.primary,
      ),
      (
        title: 'Khách hàng',
        value: '${metrics.customerCount}',
        icon: Icons.people_outline,
        color: Colors.purple,
      ),
      (
        title: 'Khóa học',
        value: '${metrics.courseCount}',
        icon: Icons.school_outlined,
        color: Colors.blue,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.9,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          stat.value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (label: 'Khóa học', icon: Icons.school, route: '/admin/courses'),
      (label: 'Danh mục', icon: Icons.category, route: '/admin/categories'),
      (label: 'Đơn hàng', icon: Icons.receipt_long, route: '/admin/orders'),
      (label: 'Người dùng', icon: Icons.people, route: '/admin/users'),
      (label: 'Duyệt đánh giá', icon: Icons.rate_review, route: '/admin/reviews'),
      (label: 'Mã giảm giá', icon: Icons.discount, route: '/admin/coupons'),
      (label: 'Quyền truy cập', icon: Icons.vpn_key, route: '/admin/entitlements'),
      (label: 'Báo cáo', icon: Icons.bar_chart, route: '/admin/reports'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Truy cập nhanh',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((act) {
                return ActionChip(
                  avatar: Icon(act.icon, size: 16, color: AppTheme.primary),
                  label: Text(act.label),
                  onPressed: () => context.go(act.route),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsRow(
      BuildContext context, AdminDashboardMetrics metrics) {
    final isMobile = Breakpoint.isMobile(context);

    final monthlyCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doanh thu theo tháng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (metrics.monthlyRevenue.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Chưa có dữ liệu doanh thu tháng.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.monthlyRevenue.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = metrics.monthlyRevenue[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tháng ${item.month}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${_fmtMoney(item.revenue)}₫',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    final bestSellersCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khóa học bán chạy nhất',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (metrics.bestSellingCourses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Chưa có khóa học nào được mua.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.bestSellingCourses.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final course = metrics.bestSellingCourses[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            course.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.enrollmentCount} học viên',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          monthlyCard,
          const SizedBox(height: 16),
          bestSellersCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: monthlyCard),
        const SizedBox(width: 16),
        Expanded(child: bestSellersCard),
      ],
    );
  }

  Widget _buildRecentOrdersCard(
      BuildContext context, List<AdminRecentOrder> orders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đơn hàng gần đây',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/admin/orders'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Chưa có đơn hàng nào.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant)),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Mã đơn')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Phương thức')),
                    DataColumn(label: Text('Tổng tiền')),
                    DataColumn(label: Text('Trạng thái')),
                    DataColumn(label: Text('Ngày tạo')),
                  ],
                  rows: orders.map((ord) {
                    Color statusColor = Colors.grey;
                    if (ord.status == 'PAID' || ord.status == 'COMPLETED') {
                      statusColor = AppTheme.success;
                    } else if (ord.status == 'WAITING_CONFIRMATION') {
                      statusColor = Colors.orange;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(ord.orderNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(ord.customerName)),
                        DataCell(Text(ord.paymentMethod)),
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
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
