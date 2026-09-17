import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/catalog_models.dart';

// ── Filter params ─────────────────────────────────────────────────────────────

class CatalogFilter {
  const CatalogFilter({
    this.q,
    this.category,
    this.level,
    this.minPrice,
    this.maxPrice,
    this.sort = 'newest',
    this.page = 1,
    this.limit = 12,
  });

  final String? q;
  final String? category; // slug or id
  final String? level;    // BEGINNER | INTERMEDIATE | ADVANCED
  final double? minPrice;
  final double? maxPrice;
  final String sort;      // newest | price_asc | price_desc | rating | popularity
  final int page;
  final int limit;

  CatalogFilter copyWith({
    String? q,
    String? category,
    String? level,
    double? minPrice,
    double? maxPrice,
    String? sort,
    int? page,
    int? limit,
    bool clearQ = false,
    bool clearCategory = false,
    bool clearLevel = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return CatalogFilter(
      q: clearQ ? null : (q ?? this.q),
      category: clearCategory ? null : (category ?? this.category),
      level: clearLevel ? null : (level ?? this.level),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (category != null) params['category'] = category;
    if (level != null) params['level'] = level;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    return params;
  }

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter &&
      other.q == q &&
      other.category == category &&
      other.level == level &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.sort == sort &&
      other.page == page &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(q, category, level, minPrice, maxPrice, sort, page, limit);
}

// ── Repository ────────────────────────────────────────────────────────────────

class CatalogRepository {
  const CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/categories');
    final data = res.data!['data'] as Map<String, dynamic>;
    return (data['categories'] as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CoursePage> getCourses(CatalogFilter filter) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/courses',
      queryParameters: filter.toQueryParams(),
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    return CoursePage(
      items: (data['items'] as List<dynamic>)
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(
          data['pagination'] as Map<String, dynamic>),
    );
  }

  Future<CourseModel> getCourseBySlug(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/courses/$slug');
    final data = res.data!['data'] as Map<String, dynamic>;
    return CourseModel.fromJson(data['course'] as Map<String, dynamic>);
  }

  Future<List<CourseModel>> getRecommendations(String courseId) async {
    final res = await _dio.get<Map<String, dynamic>>(
        '/api/courses/$courseId/recommendations');
    final data = res.data!['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(dioProvider)),
);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

final catalogFilterProvider =
    StateProvider<CatalogFilter>((ref) => const CatalogFilter());

final coursesProvider = FutureProvider.autoDispose<CoursePage>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref.watch(catalogRepositoryProvider).getCourses(filter);
});

final courseDetailProvider =
    FutureProvider.autoDispose.family<CourseModel, String>((ref, slug) {
  return ref.watch(catalogRepositoryProvider).getCourseBySlug(slug);
});

final recommendationsProvider =
    FutureProvider.autoDispose.family<List<CourseModel>, String>((ref, courseId) {
  return ref.watch(catalogRepositoryProvider).getRecommendations(courseId);
});
