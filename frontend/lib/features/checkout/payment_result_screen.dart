import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/seo/seo_data.dart';
import '../../core/seo/seo_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../orders/models/order_models.dart';
import '../orders/providers/order_provider.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({
    super.key,
    this.orderId,
    this.queryParams,
  });

  final String? orderId;
  final Map<String, dynamic>? queryParams;

  @override
  ConsumerState<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBackendStatus();
  }

  Future<void> _fetchBackendStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(orderRepositoryProvider);
      final params = widget.queryParams ?? {};

      // If VNPay redirected directly with callback parameters (e.g. vnp_TxnRef),
      // process callback through backend to verify signature and update DB.
      if (params.containsKey('vnp_TxnRef') && params.containsKey('vnp_SecureHash')) {
        final verifiedOrder = await repo.processVnpayReturn(params);
        if (mounted) {
          setState(() {
            _order = verifiedOrder;
            _isLoading = false;
          });
        }
        return;
      }

      // If error message is provided in return query without order
      if (params.containsKey('error') && (widget.orderId == null || widget.orderId!.isEmpty)) {
        if (mounted) {
          setState(() {
            _errorMessage = params['error']?.toString() ?? 'Giao dịch không thành công';
            _isLoading = false;
          });
        }
        return;
      }

      // If orderId is available, fetch authoritative order status from backend
      final targetOrderId = widget.orderId;
      if (targetOrderId != null && targetOrderId.isNotEmpty) {
        final order = await repo.getOrderDetail(targetOrderId);
        if (mounted) {
          setState(() {
            _order = order;
            _isLoading = false;
          });
        }
        return;
      }

      // If no valid order identifier is provided
      if (mounted) {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin đơn hàng để xác thực thanh toán.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi xác thực thanh toán từ máy chủ: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _fmtPrice(double p) {
    final n = p.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    SeoHelper.apply(SeoData.private(title: 'Kết quả thanh toán'));

    return AppShell(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Breakpoint.pagePadding(context),
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.divider),
        ),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Đang kiểm tra trạng thái thanh toán từ máy chủ...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Vui lòng chờ trong giây lát, hệ thống đang đồng bộ dữ liệu giao dịch.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildResultCard(
        context: context,
        icon: Icons.error_outline_rounded,
        iconColor: AppTheme.error,
        title: 'Không thể xác thực giao dịch',
        subtitle: _errorMessage!,
        statusBadgeText: 'LỖI XÁC THỰC',
        statusBadgeColor: AppTheme.error,
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/account/orders'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Xem đơn hàng của tôi'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('Về trang chủ'),
          ),
        ],
      );
    }

    final order = _order!;
    final isPaid = order.status == 'PAID' || order.payment?.status == 'SUCCESS';
    final isCancelled = order.status == 'CANCELLED' || order.payment?.status == 'FAILED';
    final isPending = order.status == 'PENDING_PAYMENT' || order.payment?.status == 'PENDING';

    if (isPaid) {
      return _buildResultCard(
        context: context,
        icon: Icons.check_circle_rounded,
        iconColor: AppTheme.success,
        title: 'Thanh toán thành công!',
        subtitle: 'Khóa học đã được kích hoạt và thêm vào thư viện của bạn.',
        statusBadgeText: 'ĐÃ THANH TOÁN (PAID)',
        statusBadgeColor: AppTheme.success,
        orderDetails: order,
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/library'),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Vào thư viện học ngay'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/account/orders/${order.id}'),
            icon: const Icon(Icons.receipt_outlined),
            label: const Text('Xem chi tiết đơn hàng'),
          ),
        ],
      );
    }

    if (isPending) {
      return _buildResultCard(
        context: context,
        icon: Icons.schedule_rounded,
        iconColor: Colors.orange,
        title: 'Đang chờ xử lý thanh toán',
        subtitle: 'Đơn hàng đang chờ phản hồi xác thực cuối cùng từ cổng thanh toán VNPay.',
        statusBadgeText: 'ĐANG CHỜ (PENDING)',
        statusBadgeColor: Colors.orange,
        orderDetails: order,
        actions: [
          FilledButton.icon(
            onPressed: _fetchBackendStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Kiểm tra lại trạng thái'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/account/orders/${order.id}'),
            child: const Text('Chi tiết đơn hàng'),
          ),
        ],
      );
    }

    if (isCancelled) {
      return _buildResultCard(
        context: context,
        icon: Icons.cancel_rounded,
        iconColor: AppTheme.error,
        title: 'Thanh toán không thành công',
        subtitle: 'Giao dịch qua VNPay đã bị hủy hoặc không thể hoàn tất.',
        statusBadgeText: 'ĐÃ HỦY (CANCELLED)',
        statusBadgeColor: AppTheme.error,
        orderDetails: order,
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Thử lại thanh toán'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/account/orders'),
            child: const Text('Lịch sử đơn hàng'),
          ),
        ],
      );
    }

    // Default fallback
    return _buildResultCard(
      context: context,
      icon: Icons.info_outline_rounded,
      iconColor: AppTheme.primary,
      title: 'Thông tin đơn hàng',
      subtitle: 'Trạng thái đơn hàng: ${order.status}',
      statusBadgeText: order.status,
      statusBadgeColor: AppTheme.primary,
      orderDetails: order,
      actions: [
        FilledButton(
          onPressed: () => context.go('/account/orders/${order.id}'),
          child: const Text('Chi tiết đơn hàng'),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusBadgeText,
    required Color statusBadgeColor,
    OrderModel? orderDetails,
    required List<Widget> actions,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: iconColor),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBadgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusBadgeText,
                  style: TextStyle(
                    color: statusBadgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (orderDetails != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Mã đơn hàng:', orderDetails.orderNumber),
              const SizedBox(height: 10),
              _buildDetailRow('Phương thức:', orderDetails.payment?.method ?? 'VNPAY'),
              const SizedBox(height: 10),
              _buildDetailRow('Tổng thanh toán:', '${_fmtPrice(orderDetails.totalAmount)}₫', isEmphasized: true),
              if (orderDetails.payment?.transactionId != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow('Mã giao dịch VNPay:', orderDetails.payment!.transactionId!),
              ],
              const SizedBox(height: 16),
              const Divider(),
            ],
            const SizedBox(height: 24),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isEmphasized = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w600,
            fontSize: isEmphasized ? 16 : 13,
            color: isEmphasized ? AppTheme.primary : AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}
