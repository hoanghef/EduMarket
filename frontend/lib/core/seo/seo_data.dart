import '../../features/courses/models/catalog_models.dart';

/// Data model representing SEO metadata for an EduMarket page.
class SeoData {
  final String title;
  final String description;
  final String? canonicalUrl;
  final String ogType; // 'website', 'article', 'product', 'course'
  final String? ogImage;
  final bool noIndex;
  final Map<String, dynamic>? jsonLd;

  const SeoData({
    required this.title,
    required this.description,
    this.canonicalUrl,
    this.ogType = 'website',
    this.ogImage,
    this.noIndex = false,
    this.jsonLd,
  });

  /// Factory helper for standard Home page SEO
  factory SeoData.home({String baseUrl = 'http://localhost:3000'}) {
    return SeoData(
      title: 'EduMarket – Nền tảng học trực tuyến & Khóa học số chất lượng',
      description:
          'Khám phá hàng chục khóa học trực tuyến thực chiến về lập trình, dữ liệu, thiết kế và quản trị. Học linh hoạt, nhận chứng chỉ số uy tín.',
      canonicalUrl: '$baseUrl/',
      ogType: 'website',
      jsonLd: {
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        'name': 'EduMarket',
        'url': baseUrl,
        'description':
            'Sàn thương mại điện tử chuyên cung cấp khóa học và nội dung giáo dục số.',
        'potentialAction': {
          '@type': 'SearchAction',
          'target': '$baseUrl/khoa-hoc?q={search_term_string}',
          'query-input': 'required name=search_term_string',
        },
      },
    );
  }

  /// Factory helper for Course Catalog page
  factory SeoData.catalog({
    String? query,
    String? categoryName,
    String? sort,
    String baseUrl = 'http://localhost:3000',
  }) {
    final title = categoryName != null
        ? 'Khóa học $categoryName | EduMarket'
        : (query != null && query.isNotEmpty
            ? 'Tìm kiếm "$query" | EduMarket'
            : 'Tất cả khóa học | EduMarket');
    final desc = categoryName != null
        ? 'Tổng hợp các khóa học $categoryName chọn lọc, bài giảng chất lượng và lộ trình học bài bản tại EduMarket.'
        : 'Khám phá danh mục toàn bộ khóa học lập trình, thiết kế, dữ liệu và kinh doanh tại EduMarket.';
    return SeoData(
      title: title,
      description: desc,
      // Canonical URL points to clean catalog without duplicate query parameters
      canonicalUrl: '$baseUrl/khoa-hoc',
      ogType: 'website',
    );
  }

  /// Factory helper for Category page
  factory SeoData.category({
    required String name,
    required String slug,
    String baseUrl = 'http://localhost:3000',
  }) {
    return SeoData(
      title: 'Khóa học $name | EduMarket',
      description:
          'Khám phá danh mục các khóa học $name chất lượng, bài giảng thực chiến và lộ trình chuẩn hóa tại EduMarket.',
      canonicalUrl: '$baseUrl/danh-muc/$slug',
      ogType: 'website',
      jsonLd: {
        '@context': 'https://schema.org',
        '@type': 'BreadcrumbList',
        'itemListElement': [
          {
            '@type': 'ListItem',
            'position': 1,
            'name': 'Trang chủ',
            'item': '$baseUrl/',
          },
          {
            '@type': 'ListItem',
            'position': 2,
            'name': 'Khóa học',
            'item': '$baseUrl/khoa-hoc',
          },
          {
            '@type': 'ListItem',
            'position': 3,
            'name': name,
            'item': '$baseUrl/danh-muc/$slug',
          },
        ],
      },
    );
  }

  /// Factory helper for Course Detail page using real course data
  factory SeoData.course({
    required CourseModel course,
    String baseUrl = 'http://localhost:3000',
  }) {
    final safeDesc = (course.shortDescription != null && course.shortDescription!.trim().isNotEmpty)
        ? course.shortDescription!.trim()
        : (course.description != null && course.description!.trim().isNotEmpty
            ? (course.description!.length > 160
                ? '${course.description!.substring(0, 157)}...'
                : course.description!)
            : 'Khóa học trực tuyến ${course.title} trên nền tảng EduMarket.');

    final image = (course.thumbnailUrl != null && course.thumbnailUrl!.trim().isNotEmpty)
        ? course.thumbnailUrl!.trim()
        : null;

    final breadcrumbs = <Map<String, dynamic>>[
      {
        '@type': 'ListItem',
        'position': 1,
        'name': 'Trang chủ',
        'item': '$baseUrl/',
      },
      {
        '@type': 'ListItem',
        'position': 2,
        'name': 'Khóa học',
        'item': '$baseUrl/khoa-hoc',
      },
    ];

    if (course.category != null) {
      breadcrumbs.add({
        '@type': 'ListItem',
        'position': 3,
        'name': course.category!.name,
        'item': '$baseUrl/danh-muc/${course.category!.slug}',
      });
      breadcrumbs.add({
        '@type': 'ListItem',
        'position': 4,
        'name': course.title,
        'item': '$baseUrl/khoa-hoc/${course.slug}',
      });
    } else {
      breadcrumbs.add({
        '@type': 'ListItem',
        'position': 3,
        'name': course.title,
        'item': '$baseUrl/khoa-hoc/${course.slug}',
      });
    }

    final graph = <Map<String, dynamic>>[
      {
        '@type': 'Course',
        'name': course.title,
        'description': safeDesc,
        'provider': {
          '@type': 'Organization',
          'name': 'EduMarket',
          'sameAs': baseUrl,
        },
        'instructor': {
          '@type': 'Person',
          'name': course.instructorName,
        },
        'educationalLevel': course.level,
        if (course.ratingCount > 0)
          'aggregateRating': {
            '@type': 'AggregateRating',
            'ratingValue': course.ratingAverage,
            'reviewCount': course.ratingCount,
          },
      },
      {
        '@type': 'Product',
        'name': course.title,
        'description': safeDesc,
        'image': ?image,
        'offers': {
          '@type': 'Offer',
          'price': course.effectivePrice,
          'priceCurrency': 'VND',
          'availability': 'https://schema.org/InStock',
          'url': '$baseUrl/khoa-hoc/${course.slug}',
        },
        if (course.ratingCount > 0)
          'aggregateRating': {
            '@type': 'AggregateRating',
            'ratingValue': course.ratingAverage,
            'reviewCount': course.ratingCount,
          },
      },
      {
        '@type': 'BreadcrumbList',
        'itemListElement': breadcrumbs,
      },
    ];

    return SeoData(
      title: '${course.title} | EduMarket',
      description: safeDesc,
      canonicalUrl: '$baseUrl/khoa-hoc/${course.slug}',
      ogType: 'website',
      ogImage: image,
      jsonLd: {
        '@context': 'https://schema.org',
        '@graph': graph,
      },
    );
  }

  /// Factory helper for Certificate Verification page
  factory SeoData.certificateVerification({
    String? code,
    String baseUrl = 'http://localhost:3000',
  }) {
    final title = code != null && code.isNotEmpty
        ? 'Xác thực chứng chỉ $code | EduMarket'
        : 'Xác thực chứng chỉ số | EduMarket';
    return SeoData(
      title: title,
      description:
          'Tra cứu và xác thực tính hợp lệ của chứng chỉ hoàn thành khóa học được cấp bởi EduMarket.',
      canonicalUrl: '$baseUrl/certificates/verify',
      ogType: 'website',
    );
  }

  /// Factory helper for Promotions / Marketing page
  factory SeoData.promotions({String baseUrl = 'http://localhost:3000'}) {
    return SeoData(
      title: 'Chương trình ưu đãi & Mã giảm giá | EduMarket',
      description:
          'Tổng hợp danh sách các mã giảm giá, khuyến mãi khóa học và quyền lợi học tập độc quyền tại EduMarket.',
      canonicalUrl: '$baseUrl/khuyen-mai',
      ogType: 'website',
    );
  }

  /// Factory helper for Seller / Policy pages
  factory SeoData.policy({
    required String title,
    required String slug,
    required String summary,
    String baseUrl = 'http://localhost:3000',
  }) {
    return SeoData(
      title: '$title | EduMarket',
      description: summary,
      canonicalUrl: '$baseUrl/chinh-sach/$slug',
      ogType: 'article',
    );
  }

  /// Factory helper for Private / Authenticated pages (noindex)
  factory SeoData.private({required String title}) {
    return SeoData(
      title: '$title | EduMarket',
      description: 'Khu vực quản lý thông tin nội bộ của EduMarket.',
      noIndex: true,
    );
  }
}
