import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/download_helper.dart';
import '../../certificates/providers/certificate_provider.dart';

class CompletionCelebrationDialog extends ConsumerStatefulWidget {
  const CompletionCelebrationDialog({
    super.key,
    required this.courseTitle,
    this.certificateCode,
  });

  final String courseTitle;
  final String? certificateCode;

  static Future<void> show(
    BuildContext context, {
    required String courseTitle,
    String? certificateCode,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionCelebrationDialog(
        courseTitle: courseTitle,
        certificateCode: certificateCode,
      ),
    );
  }

  @override
  ConsumerState<CompletionCelebrationDialog> createState() =>
      _CompletionCelebrationDialogState();
}

class _CompletionCelebrationDialogState
    extends ConsumerState<CompletionCelebrationDialog> {
  bool _isDownloadingPdf = false;
  bool _copied = false;

  Future<void> _downloadPdf() async {
    final code = widget.certificateCode;
    if (code == null) return;
    setState(() => _isDownloadingPdf = true);
    try {
      final bytes = await ref
          .read(certificateRepositoryProvider)
          .downloadCertificatePdf(code);
      saveFileBytes(bytes, 'certificate-$code.pdf', 'application/pdf');
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
            content: Text('Không thể tải chứng chỉ: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  void _copyCode() {
    final code = widget.certificateCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.certificateCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Badge Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                '🎉 Chúc Mừng Hoàn Thành!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle with course title
              Text(
                'Bạn đã hoàn thành xuất sắc toàn bộ khóa học "${widget.courseTitle}". Chứng chỉ hoàn thành đã được cấp tự động.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Certificate Code box if available
              if (code != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFCD34D), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified,
                          color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MÃ CHỨNG CHỈ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              code,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _copied ? 'Đã sao chép!' : 'Sao chép mã',
                        icon: Icon(
                          _copied ? Icons.check : Icons.copy_rounded,
                          size: 18,
                          color: const Color(0xFFB45309),
                        ),
                        onPressed: _copyCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (code != null) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/certificates/$code');
                      },
                      icon: const Icon(Icons.card_membership_outlined,
                          size: 20),
                      label: const Text('Xem chi tiết chứng chỉ',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isDownloadingPdf ? null : _downloadPdf,
                      icon: _isDownloadingPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      label: Text(
                        _isDownloadingPdf
                            ? 'Đang tải PDF...'
                            : 'Tải chứng chỉ (PDF)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/certificates');
                      },
                      icon: const Icon(Icons.workspace_premium_outlined,
                          size: 20),
                      label: const Text('Đến danh sách chứng chỉ',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
