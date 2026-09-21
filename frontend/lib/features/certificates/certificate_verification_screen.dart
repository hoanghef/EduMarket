import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'models/certificate_models.dart';
import 'providers/certificate_provider.dart';

class CertificateVerificationScreen extends ConsumerStatefulWidget {
  const CertificateVerificationScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<CertificateVerificationScreen> createState() =>
      _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState
    extends ConsumerState<CertificateVerificationScreen> {
  late final TextEditingController _codeController;
  bool _isLoading = false;
  String? _errorMessage;
  CertificateVerificationResult? _result;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    if (_codeController.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyCode(_codeController.text.trim());
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã chứng chỉ cần xác thực.';
        _result = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await ref
          .read(certificateRepositoryProvider)
          .verifyCertificate(code);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        String message;
        final responseData = e.response?.data;
        final errorCode = responseData is Map ? responseData['code'] : null;

        if (e.response?.statusCode == 404 ||
            errorCode == 'CERTIFICATE_NOT_FOUND') {
          message =
              'Không tìm thấy chứng chỉ với mã "$code". Vui lòng kiểm tra lại tính chính xác của mã.';
        } else if (e.response?.statusCode == 400 ||
            errorCode == 'INVALID_CERTIFICATE_CODE') {
          message =
              'Định dạng mã chứng chỉ không hợp lệ. Định dạng chuẩn: EDU-YYYY-XXXXXXXXXXXXXXXXXXXXXXXX';
        } else {
          message = 'Đã xảy ra lỗi khi xác thực: ${e.message}';
        }

        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi không xác định: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoint.isMobile(context) ? 16.0 : 24.0,
          vertical: 40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 40,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Xác Thực Chứng Chỉ Trực Tuyến',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kiểm tra tính xác thực và nguồn gốc chứng chỉ hoàn thành khóa học được cấp bởi EduMarket.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Search Input Card ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nhập mã chứng chỉ (Certificate Code):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ví dụ: EDU-2026-F98B237D...',
                                prefixIcon: const Icon(Icons.qr_code_scanner),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onSubmitted: _verifyCode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _verifyCode(_codeController.text),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Tra cứu',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Result Section ───────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined,
                            color: AppTheme.error, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xác thực không thành công',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_result != null) ...[
                  _VerificationResultCard(result: _result!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result Card ───────────────────────────────────────────────────────────────

class _VerificationResultCard extends StatelessWidget {
  const _VerificationResultCard({required this.result});
  final CertificateVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(result.issuedAt);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified Status Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF059669), size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHỨNG CHỈ HỢP LỆ VÀ CHÍNH THỨC',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF047857),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Hồ sơ được xác thực an toàn trên hệ thống EduMarket',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Detail rows
          _DetailRow(
            label: 'Học viên được cấp',
            value: result.studentName,
            isHighlight: true,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Khóa học hoàn thành',
            value: result.courseName,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Ngày cấp chứng chỉ',
            value: dateFormatted,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Mã chứng chỉ duy nhất',
            value: result.certificateCode,
            isMonospace: true,
          ),
          const SizedBox(height: 24),

          // Action: View Detail / Share
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/certificates/${result.certificateCode}'),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Xem bản chứng chỉ đầy đủ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
              color: isHighlight
                  ? const Color(0xFF0F172A)
                  : AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
