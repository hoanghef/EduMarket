import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

import 'package:flutter/foundation.dart';

/// Global in-memory CSRF token shared across requests.
String? _csrfToken;

void setCsrfToken(String? token) {
  _csrfToken = token;
}

String? getClientCsrfToken() => _csrfToken;

/// Singleton Dio HTTP client configured for the EduMarket backend.
///
/// - Sends cookies with every request (`withCredentials = true` for CORS).
/// - Attaches the CSRF token header when present (set by auth layer).
/// - All responses are JSON.
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Flutter Web: cookies are managed by the browser, not Dio.
      // The `withCredentials` flag is handled at the fetch level via
      // the browser's XHR/Fetch API which Dio delegates to on Web.
      extra: {'withCredentials': true},
    ),
  );

  if (kIsWeb) {
    try {
      (dio.httpClientAdapter as dynamic).withCredentials = true;
    } catch (_) {}
  }

  // ── Request interceptor ──────────────────────────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['withCredentials'] = true;
        if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method.toUpperCase())) {
          if (_csrfToken != null && _csrfToken!.isNotEmpty) {
            options.headers['X-CSRF-Token'] = _csrfToken;
          }
        }
        handler.next(options);
      },
      onError: (DioException e, handler) {
        // Centralised error logging; screens handle state transitions.
        // ignore: avoid_print
        print('[API ERROR] ${e.requestOptions.method} '
            '${e.requestOptions.path} → '
            '${e.response?.statusCode} ${e.message}');
        handler.next(e);
      },
    ),
  );

  return dio;
}

/// Riverpod provider that exposes the configured [Dio] instance.
final dioProvider = Provider<Dio>((ref) => createDioClient());

/// Typed response model returned by all API calls.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.code,
    this.message,
  });

  final bool success;
  final T? data;
  final String? code;
  final String? message;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
      code: json['code'] as String?,
      message: json['message'] as String?,
    );
  }
}
