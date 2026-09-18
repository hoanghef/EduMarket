import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/user_model.dart';

// ── Repository ───────────────────────────────────────────────────────────────

abstract class AuthRepository {
  Future<String> getCsrfToken();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String fullName, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<String> getCsrfToken() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/auth/csrf');
    final data = res.data?['data'] as Map<String, dynamic>?;
    final token = data?['csrfToken'] as String? ?? '';
    if (token.isNotEmpty) {
      setCsrfToken(token);
    }
    return token;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    // Ensure CSRF token is available before mutating request
    if (getClientCsrfToken() == null || getClientCsrfToken()!.isEmpty) {
      await getCsrfToken();
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data?['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> register(
    String email,
    String fullName,
    String password,
  ) async {
    if (getClientCsrfToken() == null || getClientCsrfToken()!.isEmpty) {
      await getCsrfToken();
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'email': email,
        'fullName': fullName,
        'password': password,
      },
    );
    final data = res.data?['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    if (getClientCsrfToken() == null || getClientCsrfToken()!.isEmpty) {
      await getCsrfToken();
    }
    await _dio.post<Map<String, dynamic>>('/api/auth/logout');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/auth/me');
      final data = res.data?['data'] as Map<String, dynamic>?;
      if (data != null && data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(dioProvider));
});

// ── State ────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => restoreSession());
    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> restoreSession() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      try {
        final token = await repo.getCsrfToken();
        setCsrfToken(token);
      } catch (_) {}

      final user = await repo.getCurrentUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email.trim().toLowerCase(), password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapDioError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register(
    String email,
    String fullName,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(
        email.trim().toLowerCase(),
        fullName.trim(),
        password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapDioError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
    } catch (_) {
      // Clear state regardless of server logout response
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final code = data['code'] as String?;
      final msg = data['message'] as String?;

      switch (code) {
        case 'INVALID_CREDENTIALS':
          return 'Email hoặc mật khẩu không chính xác.';
        case 'ACCOUNT_LOCKED':
          return 'Tài khoản đã bị tạm khóa do đăng nhập sai nhiều lần. Vui lòng thử lại sau 15 phút.';
        case 'LOGIN_RATE_LIMIT':
          return 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau.';
        case 'ACCOUNT_DISABLED':
          return 'Tài khoản đã bị vô hiệu hóa.';
        case 'EMAIL_IN_USE':
          return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
        case 'VALIDATION_ERROR':
          return msg ?? 'Dữ liệu không hợp lệ.';
        case 'CSRF_TOKEN_MISSING':
        case 'CSRF_TOKEN_INVALID':
          return 'Phiên làm việc hết hạn. Vui lòng làm mới trang và thử lại.';
        default:
          return msg ?? 'Đã xảy ra lỗi (${e.response?.statusCode}).';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối máy chủ quá hạn. Vui lòng thử lại.';
    }
    return 'Không thể kết nối đến máy chủ.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
