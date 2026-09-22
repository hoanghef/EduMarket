import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../courses/models/catalog_models.dart';
import '../models/admin_models.dart';

class AdminRepository {
  const AdminRepository(this._dio);
  final Dio _dio;

  Future<AdminDashboardMetrics> getDashboard() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/admin/dashboard');
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return AdminDashboardMetrics.fromJson(data);
  }

  Future<List<AdminOrderModel>> getOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/admin/orders',
      queryParameters: params,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AdminOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmCodOrder(String orderId) async {
    await _dio.patch<Map<String, dynamic>>('/api/admin/orders/$orderId/cod-confirm');
  }

  Future<List<AdminUserModel>> getUsers({String? role, String? q}) async {
    final params = <String, dynamic>{};
    if (role != null && role.isNotEmpty) params['role'] = role;
    if (q != null && q.isNotEmpty) params['q'] = q;
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/admin/users',
      queryParameters: params,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminReviewModel>> getReviews({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/admin/reviews',
      queryParameters: params,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AdminReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> moderateReview(String reviewId, String status) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/admin/reviews/$reviewId/moderate',
      data: {'status': status},
    );
  }

  Future<List<AdminCouponModel>> getCoupons() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/admin/coupons');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AdminCouponModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminCouponModel> createCoupon(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/admin/coupons',
      data: data,
    );
    final resData = response.data?['data'] as Map<String, dynamic>? ?? {};
    return AdminCouponModel.fromJson(
        resData['coupon'] as Map<String, dynamic>? ?? {});
  }

  Future<void> toggleCouponActive(String id, bool isActive) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/admin/coupons/$id',
      data: {'isActive': isActive},
    );
  }

  Future<List<AdminEntitlementModel>> getEntitlements({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/admin/entitlements',
      queryParameters: params,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AdminEntitlementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeEntitlement(String id, String reason) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/admin/entitlements/$id/revoke',
      data: {'reason': reason},
    );
  }

  Future<void> grantEntitlement({
    required String userId,
    required String courseId,
    required String orderId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/admin/entitlements/grant',
      data: {
        'userId': userId,
        'courseId': courseId,
        'orderId': orderId,
      },
    );
  }

  Future<List<CategoryModel>> getCategories() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/admin/categories');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _dio.post<Map<String, dynamic>>('/api/admin/categories', data: data);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete<void>('/api/admin/categories/$id');
  }

  Future<List<CourseModel>> getCourses() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/admin/courses');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateCourseStatus(String courseId, String status) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/admin/courses/$courseId',
      data: {'status': status},
    );
  }

  Future<void> deleteCourse(String courseId) async {
    await _dio.delete<void>('/api/admin/courses/$courseId');
  }

  Future<AdminRevenueReportModel> getRevenueReport() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/admin/reports/revenue');
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return AdminRevenueReportModel.fromJson(data);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardMetrics>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboard();
});

final adminOrdersProvider =
    FutureProvider.autoDispose.family<List<AdminOrderModel>, String?>(
  (ref, status) =>
      ref.watch(adminRepositoryProvider).getOrders(status: status),
);

final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminUserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getUsers();
});

final adminReviewsProvider =
    FutureProvider.autoDispose.family<List<AdminReviewModel>, String?>(
  (ref, status) =>
      ref.watch(adminRepositoryProvider).getReviews(status: status),
);

final adminCouponsProvider =
    FutureProvider.autoDispose<List<AdminCouponModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getCoupons();
});

final adminEntitlementsProvider =
    FutureProvider.autoDispose.family<List<AdminEntitlementModel>, String?>(
  (ref, status) =>
      ref.watch(adminRepositoryProvider).getEntitlements(status: status),
);

final adminRevenueReportProvider =
    FutureProvider.autoDispose<AdminRevenueReportModel>((ref) {
  return ref.watch(adminRepositoryProvider).getRevenueReport();
});

final adminCoursesProvider =
    FutureProvider.autoDispose<List<CourseModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getCourses();
});

final adminCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getCategories();
});
