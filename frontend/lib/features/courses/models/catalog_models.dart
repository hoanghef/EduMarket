/// Domain models for the catalog feature.
library;

// ── Category ──────────────────────────────────────────────────────────────────

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.courseCount = 0,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final int courseCount;
  final List<CategoryModel> children;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String?,
        iconUrl: json['iconUrl'] as String?,
        courseCount: json['courseCount'] as int? ?? 0,
        children: (json['children'] as List<dynamic>? ?? [])
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Course ────────────────────────────────────────────────────────────────────

class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.instructorName,
    required this.price,
    required this.ratingAverage,
    required this.ratingCount,
    required this.enrollmentCount,
    required this.level,
    this.shortDescription,
    this.description,
    this.thumbnailUrl,
    this.salePrice,
    this.category,
    this.lessons = const [],
    this.publishedAt,
    this.durationSec,
  });

  final String id;
  final String title;
  final String slug;
  final String instructorName;
  final double price;
  final double ratingAverage;
  final int ratingCount;
  final int enrollmentCount;
  final String level;
  final String? shortDescription;
  final String? description;
  final String? thumbnailUrl;
  final double? salePrice;
  final CategoryModel? category;
  final List<LessonSummary> lessons;
  final String? publishedAt;
  final int? durationSec;

  bool get isOnSale => salePrice != null && salePrice! < price;
  double get effectivePrice => salePrice != null && salePrice! < price ? salePrice! : price;
  bool get isFree => price == 0;

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        instructorName: json['instructorName'] as String? ?? '',
        price: _toDouble(json['price']),
        ratingAverage: _toDouble(json['ratingAverage']),
        ratingCount: json['ratingCount'] as int? ?? 0,
        enrollmentCount: json['enrollmentCount'] as int? ?? 0,
        level: json['level'] as String? ?? 'BEGINNER',
        shortDescription: json['shortDescription'] as String?,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        salePrice: json['salePrice'] != null ? _toDouble(json['salePrice']) : null,
        category: json['category'] != null
            ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((e) => LessonSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        publishedAt: json['publishedAt'] as String?,
        durationSec: json['durationSec'] as int?,
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

// ── Lesson summary ────────────────────────────────────────────────────────────

class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.title,
    required this.position,
    this.durationSec,
    this.isPreview = false,
    this.isRequired = true,
  });

  final String id;
  final String title;
  final int position;
  final int? durationSec;
  final bool isPreview;
  final bool isRequired;

  factory LessonSummary.fromJson(Map<String, dynamic> json) => LessonSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        position: json['position'] as int? ?? 0,
        durationSec: json['durationSec'] as int?,
        isPreview: json['isPreview'] as bool? ?? false,
        isRequired: json['isRequired'] as bool? ?? true,
      );
}

// ── Pagination ─────────────────────────────────────────────────────────────────

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        page: json['page'] as int? ?? 1,
        limit: json['limit'] as int? ?? 12,
        total: json['total'] as int? ?? 0,
        totalPages: json['totalPages'] as int? ?? 0,
      );
}

class CoursePage {
  const CoursePage({required this.items, required this.pagination});

  final List<CourseModel> items;
  final PaginationMeta pagination;
}
