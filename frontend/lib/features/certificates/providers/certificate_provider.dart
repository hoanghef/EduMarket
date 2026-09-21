import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/certificate_models.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class CertificateRepository {
  CertificateRepository(this._dio);

  final Dio _dio;

  /// GET /api/certificates  – returns all certificates owned by current customer
  Future<List<CertificateItem>> getMyCertificates() async {
    final response = await _dio.get('/api/certificates');
    final items = response.data['data']['items'] as List<dynamic>;
    return items
        .map((e) => CertificateItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/certificates/:code/verify  – public verification
  Future<CertificateVerificationResult> verifyCertificate(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final response = await _dio.get('/api/certificates/$cleanCode/verify');
    return CertificateVerificationResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/certificates/:code/pdf  – download certificate PDF
  Future<List<int>> downloadCertificatePdf(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final response = await _dio.get<List<int>>(
      '/api/certificates/$cleanCode/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository(ref.watch(dioProvider));
});

/// List of all certificates earned by the authenticated user.
final myCertificatesProvider =
    FutureProvider.autoDispose<List<CertificateItem>>((ref) {
  return ref.watch(certificateRepositoryProvider).getMyCertificates();
});

/// Verification result for a given certificate code.
final certificateVerificationProvider = FutureProvider.autoDispose
    .family<CertificateVerificationResult, String>((ref, code) {
  return ref.watch(certificateRepositoryProvider).verifyCertificate(code);
});
