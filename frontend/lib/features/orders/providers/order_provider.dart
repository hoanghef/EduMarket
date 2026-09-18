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

  Future<OrderModel> checkoutCod() async {
    final response = await _dio.post('/api/checkout', data: {'method': 'COD'});
    return OrderModel.fromJson(response.data['data']['order']);
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

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).getOrders();
});

final orderDetailProvider = FutureProvider.autoDispose.family<OrderModel, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrderDetail(id);
});
