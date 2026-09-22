import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/review_models.dart';

class ReviewRepository {
  const ReviewRepository(this._dio);
  final Dio _dio;

  Future<List<ReviewItemModel>> getCourseReviews(String courseId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/courses/$courseId/reviews');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ReviewItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MyReviewModel?> getMyReview(String courseId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>('/api/courses/$courseId/my-review');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data?['review'] != null) {
        return MyReviewModel.fromJson(data!['review'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<MyReviewModel> submitReview({
    required String courseId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/reviews',
      data: {
        'courseId': courseId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return MyReviewModel.fromJson(data!['review'] as Map<String, dynamic>);
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(dioProvider));
});

final courseReviewsProvider =
    FutureProvider.autoDispose.family<List<ReviewItemModel>, String>(
  (ref, courseId) =>
      ref.watch(reviewRepositoryProvider).getCourseReviews(courseId),
);

final myCourseReviewProvider =
    FutureProvider.autoDispose.family<MyReviewModel?, String>(
  (ref, courseId) =>
      ref.watch(reviewRepositoryProvider).getMyReview(courseId),
);
