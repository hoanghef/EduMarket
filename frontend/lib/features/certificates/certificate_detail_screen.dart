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

class CertificateDetailScreen extends ConsumerStatefulWidget {
  const CertificateDetailScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState
    extends ConsumerState<CertificateDetailScreen> {
  bool _downloadingPdf = false;
  bool _copiedLink = false;

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final bytes = await ref
          .read(certificateRepositoryProvider)
          .downloadCertificatePdf(widget.code);
      saveFileBytes(
        bytes,
        'certificate-${widget.code}.pdf',
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

  void _copyShareLink() {
    final url =
        '${Uri.base.origin}/#/certificates/verify?code=${widget.code}';
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _copiedLink = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã sao chép liên kết xác thực vào bộ nhớ tạm!'),
        backgroundColor: AppTheme.success,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedLink = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final verificationAsync =
        ref.watch(certificateVerificationProvider(widget.code));

    return AppShell(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoint.isMobile(context) ? 16.0 : 24.0,
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back Button ──────────────────────────────────────────
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/certificates'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Danh sách chứng chỉ'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _copyShareLink,
                      icon: Icon(
                        _copiedLink ? Icons.check : Icons.share_outlined,
                        size: 16,
                      ),
                      label: Text(_copiedLink ? 'Đã sao chép' : 'Chia sẻ'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                      ),
                      onPressed: _downloadingPdf ? null : _downloadPdf,
                      icon: _downloadingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: Text(_downloadingPdf ? 'Đang tải...' : 'Tải bản PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Certificate View ─────────────────────────────────────
                verificationAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
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
                            'Không thể tải thông tin chứng chỉ: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.error),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => ref.refresh(
                                certificateVerificationProvider(widget.code)),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (data) => _CertificatePaper(data: data),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Certificate Paper Design ──────────────────────────────────────────────────

class _CertificatePaper extends StatelessWidget {
  const _CertificatePaper({required this.data});
  final CertificateVerificationResult data;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(data.issuedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        ),
        child: Column(
          children: [
            // EduMarket Branding & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'EDUMARKET ACADEMY',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Certificate Title
            const Text(
              'GIẤY CHỨNG NHẬN HOÀN THÀNH',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'CERTIFICATE OF COMPLETION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Recipient
            const Text(
              'Chứng nhận trao cho:',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.studentName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 2,
              color: const Color(0xFFD97706),
            ),
            const SizedBox(height: 20),

            // Course Info
            const Text(
              'đã hoàn thành xuất sắc toàn bộ chương trình và bài tập khóa học',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.courseName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 36),

            // Verification & Signature Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Issue Date & Certificate Code
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày cấp: $dateFormatted',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã số: ${data.certificateCode}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Seal / Verification Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Color(0xFF059669), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'ĐÃ XÁC THỰC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
