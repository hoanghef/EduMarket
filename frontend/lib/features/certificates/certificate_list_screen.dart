import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/download_helper.dart';
import '../../core/widgets/app_shell.dart';
import 'models/certificate_models.dart';
import 'providers/certificate_provider.dart';

class CertificateListScreen extends ConsumerWidget {
  const CertificateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificatesAsync = ref.watch(myCertificatesProvider);

    return AppShell(
      child: RefreshIndicator(
        onRefresh: () async => ref.refresh(myCertificatesProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Breakpoint.isMobile(context) ? 16.0 : 24.0,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Breadcrumb & Navigation ──────────────────────────────
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.go('/library'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Thư viện'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/certificates/verify'),
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: const Text('Tra cứu xác thực công khai'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Page Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.workspace_premium,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chứng chỉ của tôi',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Chứng chỉ hoàn thành chính thức được cấp khi bạn học xong 100% bài học.',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Content ──────────────────────────────────────────────
                  certificatesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppTheme.error),
                            const SizedBox(height: 16),
                            Text(
                              'Không thể tải danh sách chứng chỉ: $err',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  ref.refresh(myCertificatesProvider),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const _EmptyCertificatesState();
                      }
                      return _CertificateGrid(items: items);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyCertificatesState extends StatelessWidget {
  const _EmptyCertificatesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_membership_outlined,
              size: 40,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có chứng chỉ nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const Text(
              'Hãy hoàn thành 100% tất cả các bài học trong một khóa học tại Thư viện để nhận Giấy chứng nhận hoàn thành.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/library'),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Đến thư viện học tập'),
          ),
        ],
      ),
    );
  }
}

// ── Grid of Certificates ──────────────────────────────────────────────────────

class _CertificateGrid extends StatelessWidget {
  const _CertificateGrid({required this.items});
  final List<CertificateItem> items;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoint.isDesktop(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: items.map((item) {
            final cardWidth = isDesktop
                ? (constraints.maxWidth - 20) / 2
                : constraints.maxWidth;
            return SizedBox(
              width: cardWidth,
              child: _CertificateCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CertificateCard extends ConsumerStatefulWidget {
  const _CertificateCard({required this.item});
  final CertificateItem item;

  @override
  ConsumerState<_CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends ConsumerState<_CertificateCard> {
  bool _downloadingPdf = false;
  bool _copied = false;

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final bytes = await ref
          .read(certificateRepositoryProvider)
          .downloadCertificatePdf(widget.item.certificateCode);
      saveFileBytes(
        bytes,
        'certificate-${widget.item.certificateCode}.pdf',
        'application/pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tải chứng chỉ PDF thành công!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.item.certificateCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dateFormatted = DateFormat('dd/MM/yyyy').format(item.issuedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'CHỨNG CHỈ HOÀN THÀNH CHÍNH THỨC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF92400E),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormatted,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Title
                Text(
                  item.courseTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Certificate Code Box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_outlined,
                          size: 16, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.certificateCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: _copyCode,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _copied ? Icons.check : Icons.copy_rounded,
                            size: 16,
                            color: _copied
                                ? AppTheme.success
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.go('/certificates/${item.certificateCode}'),
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            size: 16),
                        label: const Text('Xem chi tiết'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                        onPressed: _downloadingPdf ? null : _downloadPdf,
                        icon: _downloadingPdf
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined,
                                size: 16),
                        label: Text(_downloadingPdf ? 'Đang tải...' : 'Tải PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
