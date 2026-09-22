import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/wishlist_model.dart';

class WishlistRepository {
  const WishlistRepository(this._dio);
  final Dio _dio;

  Future<List<WishlistItemModel>> getWishlist() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/wishlist');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => WishlistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WishlistItemModel> addToWishlist(String courseId) async {
    final response =
        await _dio.post<Map<String, dynamic>>('/api/wishlist/$courseId');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final item = data?['item'] as Map<String, dynamic>? ?? {};
    return WishlistItemModel.fromJson(item);
  }

  Future<void> removeFromWishlist(String courseId) async {
    await _dio.delete<void>('/api/wishlist/$courseId');
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(dioProvider));
});

class WishlistState {
  const WishlistState({
    required this.items,
    required this.isLoading,
    this.errorMessage,
  });

  final List<WishlistItemModel> items;
  final bool isLoading;
  final String? errorMessage;

  bool containsCourse(String courseId) =>
      items.any((item) => item.courseId == courseId || item.course.id == courseId);

  WishlistState copyWith({
    List<WishlistItemModel>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier(this._repository)
      : super(const WishlistState(items: [], isLoading: false)) {
    loadWishlist();
  }

  final WishlistRepository _repository;

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getWishlist();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách yêu thích',
      );
    }
  }

  Future<bool> toggleWishlist(String courseId) async {
    final isFav = state.containsCourse(courseId);
    try {
      if (isFav) {
        await _repository.removeFromWishlist(courseId);
        final updated =
            state.items.where((it) => it.courseId != courseId && it.course.id != courseId).toList();
        state = state.copyWith(items: updated);
        return false;
      } else {
        final added = await _repository.addToWishlist(courseId);
        state = state.copyWith(items: [added, ...state.items]);
        return true;
      }
    } catch (e) {
      rethrow;
    }
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
});
