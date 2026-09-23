import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/seo/seo_data.dart';
import '../../core/seo/seo_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  static const _activeCoupons = [
    (
      code: 'WELCOME10',
      title: 'Chào mừng học viên mới',
      discount: 'Giảm 10%',
      minOrder: 'Đơn hàng từ 300.000đ',
      maxDiscount: 'Giảm tối đa 200.000đ',
      description: 'Dành cho tất cả khách hàng đăng ký khóa học lần đầu tại EduMarket.',
    ),
    (
      code: 'HOC500K',
      title: 'Học tập bứt phá',
      discount: 'Giảm 50.000đ',
      minOrder: 'Đơn hàng từ 500.000đ',
      maxDiscount: 'Trừ trực tiếp vào tổng tiền',
      description: 'Áp dụng cho mọi khóa học công nghệ, dữ liệu và thiết kế.',
    ),
    (
      code: 'STUDENT20',
      title: 'Ưu đãi học viên chăm chỉ',
      discount: 'Giảm 20%',
      minOrder: 'Đơn hàng từ 600.000đ',
      maxDiscount: 'Giảm tối đa 300.000đ',
      description: 'Hỗ trợ chi phí học tập chuyên sâu cho sinh viên và người chuyển ngành.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    SeoHelper.apply(SeoData.promotions());

    final isMobile = Breakpoint.isMobile(context);

    return AppShell(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Banner ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoint.pagePadding(context),
                vertical: isMobile ? 40 : 64,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Ưu Đãi Đặc Quyền',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chương Trình Khuyến Mãi & Mã Giảm Giá',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nâng cao kỹ năng số với mức học phí tối ưu nhất. Lưu mã giảm giá và áp dụng ngay tại bước thanh toán.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Coupon Cards Section ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoint.pagePadding(context),
                vertical: 48,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎟️ Các mã giảm giá đang kích hoạt',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nhấn "Sao chép mã" để sử dụng tại trang giỏ hàng hoặc thanh toán.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 700;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _activeCoupons.map((c) {
                            final cardWidth = isNarrow
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 32) / 3;
                            return SizedBox(
                              width: cardWidth,
                              child: _CouponCard(coupon: c),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Why EduMarket Section ───────────────────────────────────────
            Container(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoint.pagePadding(context),
                vertical: 56,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
                  child: Column(
                    children: [
                      const Text(
                        '⭐ Giá trị học tập vượt trội tại EduMarket',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Được thiết kế chuyên biệt cho việc học và thực hành nội dung số.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 40),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 700;
                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: [
                              _BenefitCard(
                                width: isNarrow
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 48) / 3,
                                icon: Icons.cloud_download_outlined,
                                title: 'Tài liệu tải về an toàn',
                                description:
                                    'Toàn bộ tài nguyên, mã nguồn mẫu và tài liệu khóa học được bảo vệ qua liên kết tải có thời hạn, chống giả mạo.',
                              ),
                              _BenefitCard(
                                width: isNarrow
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 48) / 3,
                                icon: Icons.verified_outlined,
                                title: 'Chứng chỉ số uy tín',
                                description:
                                    'Hoàn thành 100% lộ trình bài học để nhận chứng chỉ PDF chính thức kèm mã xác thực công khai tra cứu tức thì.',
                              ),
                              _BenefitCard(
                                width: isNarrow
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 48) / 3,
                                icon: Icons.rate_review_outlined,
                                title: 'Đánh giá 100% thực tế',
                                description:
                                    'Chỉ những học viên đã sở hữu và hoàn thành các phần học mới được phép gửi đánh giá, đảm bảo minh bạch tuyệt đối.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── How to Apply Coupon Steps ───────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoint.pagePadding(context),
                vertical: 56,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    const Text(
                      '💡 Hướng dẫn áp dụng mã giảm giá',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    _StepItem(
                      step: '1',
                      title: 'Chọn khóa học',
                      desc: 'Khám phá danh mục và thêm khóa học bạn muốn vào Giỏ hàng.',
                    ),
                    const SizedBox(height: 20),
                    _StepItem(
                      step: '2',
                      title: 'Nhập mã giảm giá',
                      desc: 'Tại trang Giỏ hàng hoặc Thanh toán, điền mã coupon vào ô "Mã giảm giá".',
                    ),
                    const SizedBox(height: 20),
                    _StepItem(
                      step: '3',
                      title: 'Nhận ưu đãi tức thì',
                      desc: 'Nhấn "Áp dụng", hệ thống máy chủ sẽ tự động tính toán và khấu trừ tiền thanh toán ngay lập tức.',
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () => context.go('/khoa-hoc'),
                      icon: const Icon(Icons.school_outlined),
                      label: const Text('Khám phá tất cả khóa học ngay'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});
  final ({
    String code,
    String title,
    String discount,
    String minOrder,
    String maxDiscount,
    String description,
  }) coupon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    coupon.discount,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  coupon.minOrder,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              coupon.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              coupon.description,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Text(
                      coupon.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Sao chép mã',
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: coupon.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép mã "${coupon.code}" vào bộ nhớ tạm!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });
  final double width;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.step,
    required this.title,
    required this.desc,
  });
  final String step;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primary,
          child: Text(
            step,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
