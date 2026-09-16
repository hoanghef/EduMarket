import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class HealthStatus {
  const HealthStatus({
    required this.status,
    required this.service,
    required this.version,
    required this.environment,
    required this.timestamp,
  });

  final String status;
  final String service;
  final String version;
  final String environment;
  final String timestamp;

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        status: json['status'] as String? ?? 'unknown',
        service: json['service'] as String? ?? '',
        version: json['version'] as String? ?? '',
        environment: json['environment'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
      );
}

// ── Repository ────────────────────────────────────────────────────────────────

class HealthRepository {
  const HealthRepository(this._dio);

  final Dio _dio;

  /// Calls GET /api/health and returns a [HealthStatus].
  Future<HealthStatus> getHealth() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/health');
    final body = response.data!;
    final apiResp = ApiResponse.fromJson(
      body,
      (d) => HealthStatus.fromJson(d as Map<String, dynamic>),
    );
    if (!apiResp.success || apiResp.data == null) {
      throw Exception(apiResp.message ?? 'Health check failed');
    }
    return apiResp.data!;
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(ref.watch(dioProvider)),
);

/// AsyncNotifier that fetches health status once and caches it.
final healthProvider = FutureProvider<HealthStatus>((ref) {
  return ref.watch(healthRepositoryProvider).getHealth();
});
