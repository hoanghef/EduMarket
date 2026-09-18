import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/cart_models.dart';

final cartRepositoryProvider = Provider((ref) {
  return CartRepository(ref.watch(dioProvider));
});

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  Future<CartModel> getCart() async {
    final response = await _dio.get('/api/cart');
    return CartModel.fromJson(response.data['data']['cart']);
  }

  Future<void> addToCart(String courseId) async {
    await _dio.post('/api/cart/items', data: {'courseId': courseId});
  }

  Future<void> removeFromCart(String itemId) async {
    await _dio.delete('/api/cart/items/$itemId');
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, CartModel>(CartNotifier.new);

class CartNotifier extends AsyncNotifier<CartModel> {
  @override
  Future<CartModel> build() async {
    return _fetchCart();
  }

  Future<CartModel> _fetchCart() async {
    final repo = ref.read(cartRepositoryProvider);
    return await repo.getCart();
  }

  Future<void> refreshCart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchCart());
  }

  Future<void> addToCart(String courseId) async {
    try {
      await ref.read(cartRepositoryProvider).addToCart(courseId);
      await refreshCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      // Optimistic update could be done here, but let's refresh for simplicity
      await ref.read(cartRepositoryProvider).removeFromCart(itemId);
      await refreshCart();
    } catch (e) {
      rethrow;
    }
  }
}
