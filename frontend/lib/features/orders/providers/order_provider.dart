import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/order_models.dart';

final orderRepositoryProvider = Provider((ref) {
  return OrderRepository(ref.watch(dioProvider));
});

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  Future<OrderModel> checkoutCod({String? couponCode}) async {
    final data = <String, dynamic>{'method': 'COD'};
    if (couponCode != null && couponCode.trim().isNotEmpty) {
      data['couponCode'] = couponCode.trim().toUpperCase();
    }
    final response = await _dio.post('/api/checkout', data: data);
    return OrderModel.fromJson(response.data['data']['order']);
  }

  Future<VnpayPaymentResult> createVnpayPayment({String? couponCode}) async {
    final data = <String, dynamic>{};
    if (couponCode != null && couponCode.trim().isNotEmpty) {
      data['couponCode'] = couponCode.trim().toUpperCase();
    }
    final response = await _dio.post('/api/payments/vnpay/create', data: data);
    final resData = response.data['data'] as Map<String, dynamic>;
    final order = OrderModel.fromJson(resData['order']);
    final paymentUrl = resData['paymentUrl'] as String?;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw Exception('Không nhận được đường dẫn thanh toán từ hệ thống VNPay.');
    }
    return VnpayPaymentResult(order: order, paymentUrl: paymentUrl);
  }

  Future<OrderModel> processVnpayReturn(Map<String, dynamic> queryParams) async {
    final response = await _dio.get('/api/payments/vnpay/return', queryParameters: queryParams);
    final resData = response.data['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(resData['order']);
  }

  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get('/api/orders');
    return (response.data['data']['orders'] as List)
        .map((e) => OrderModel.fromJson(e))
        .toList();
  }

  Future<OrderModel> getOrderDetail(String id) async {
    final response = await _dio.get('/api/orders/$id');
    return OrderModel.fromJson(response.data['data']['order']);
  }
}

class VnpayPaymentResult {
  const VnpayPaymentResult({required this.order, required this.paymentUrl});
  final OrderModel order;
  final String paymentUrl;
}

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).getOrders();
});

final orderDetailProvider = FutureProvider.autoDispose.family<OrderModel, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrderDetail(id);
});
