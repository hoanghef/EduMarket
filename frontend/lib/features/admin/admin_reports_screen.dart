import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  String _fmtMoney(double amount) {
    final n = amount.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReport = ref.watch(adminRevenueReportProvider);

    return AdminShell(
      currentRoute: '/admin/reports',
      title: 'Báo cáo doanh thu & phương thức thanh toán',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminRevenueReportProvider),
        ),
      ],
      child: asyncReport.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('Lỗi tải báo cáo: $err',
                style: const TextStyle(color: AppTheme.error)),
          ),
        ),
        data: (report) {
          final isMobile = Breakpoint.isMobile(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary KPI
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng quan doanh thu thực tế',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Doanh thu thực thu (sau giảm giá):',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(
                            '${_fmtMoney(report.totalRevenue)}₫',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng tiền gốc (tạm tính):',
                              style: TextStyle(color: AppTheme.onSurfaceVariant)),
                          Text('${_fmtMoney(report.totalSubtotal)}₫',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng khuyến mãi đã giảm:',
                              style: TextStyle(color: AppTheme.onSurfaceVariant)),
                          Text('-${_fmtMoney(report.totalDiscount)}₫',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, color: AppTheme.error)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số đơn hàng đã thanh toán thành công:',
                              style: TextStyle(color: AppTheme.onSurfaceVariant)),
                          Text('${report.paidOrdersCount} đơn',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods Comparison
              const Text(
                'Phân tích theo cổng thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (isMobile)
                Column(
                  children: [
                    _buildPaymentCard(
                      title: 'COD (Thanh toán khi xác nhận)',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.orange,
                      revenue: report.codRevenue,
                      count: report.codCount,
                      totalRev: report.totalRevenue,
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentCard(
                      title: 'VNPay Sandbox (Cổng trực tuyến)',
                      icon: Icons.credit_card_outlined,
                      color: Colors.blue,
                      revenue: report.vnpayRevenue,
                      count: report.vnpayCount,
                      totalRev: report.totalRevenue,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentCard(
                        title: 'COD (Thanh toán khi xác nhận)',
                        icon: Icons.local_shipping_outlined,
                        color: Colors.orange,
                        revenue: report.codRevenue,
                        count: report.codCount,
                        totalRev: report.totalRevenue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPaymentCard(
                        title: 'VNPay Sandbox (Cổng trực tuyến)',
                        icon: Icons.credit_card_outlined,
                        color: Colors.blue,
                        revenue: report.vnpayRevenue,
                        count: report.vnpayCount,
                        totalRev: report.totalRevenue,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard({
    required String title,
    required IconData icon,
    required Color color,
    required double revenue,
    required int count,
    required double totalRev,
  }) {
    final pct = totalRev > 0 ? ((revenue / totalRev) * 100).toStringAsFixed(1) : '0';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_fmtMoney(revenue)}₫',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count giao dịch thành công ($pct% tổng doanh thu)',
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
