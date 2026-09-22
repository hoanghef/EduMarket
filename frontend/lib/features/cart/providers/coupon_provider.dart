import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/coupon_model.dart';

class CouponRepository {
  const CouponRepository(this._dio);
  final Dio _dio;

  Future<ValidatedCouponModel> validateCoupon(String couponCode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/coupons/validate',
      data: {'couponCode': couponCode.trim().toUpperCase()},
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return ValidatedCouponModel.fromJson(data);
  }
}

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository(ref.watch(dioProvider));
});

class CouponState {
  const CouponState({
    this.coupon,
    this.isValidating = false,
    this.errorMessage,
    this.successMessage,
  });

  final ValidatedCouponModel? coupon;
  final bool isValidating;
  final String? errorMessage;
  final String? successMessage;

  CouponState copyWith({
    ValidatedCouponModel? coupon,
    bool? isValidating,
    String? errorMessage,
    String? successMessage,
    bool clearCoupon = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CouponState(
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      isValidating: isValidating ?? this.isValidating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class CouponNotifier extends StateNotifier<CouponState> {
  CouponNotifier(this._repository) : super(const CouponState());
  final CouponRepository _repository;

  Future<bool> applyCoupon(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng nhập mã giảm giá.',
        clearSuccess: true,
      );
      return false;
    }

    state = state.copyWith(
      isValidating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final result = await _repository.validateCoupon(trimmed);
      state = state.copyWith(
        coupon: result,
        isValidating: false,
        successMessage: 'Áp dụng mã giảm giá $trimmed thành công!',
        clearError: true,
      );
      return true;
    } on DioException catch (e) {
      String msg = 'Mã giảm giá không hợp lệ.';
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      state = state.copyWith(
        isValidating: false,
        errorMessage: msg,
        clearSuccess: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isValidating: false,
        errorMessage: 'Lỗi kiểm tra mã: $e',
        clearSuccess: true,
      );
      return false;
    }
  }

  void removeCoupon() {
    state = const CouponState();
  }
}

final couponProvider =
    StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier(ref.watch(couponRepositoryProvider));
});
