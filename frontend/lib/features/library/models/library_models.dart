/// Domain models for the Customer Library feature.
library;

// ── Category summary ──────────────────────────────────────────────────────────

class LibraryCategoryModel {
  const LibraryCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory LibraryCategoryModel.fromJson(Map<String, dynamic> json) =>
      LibraryCategoryModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}

// ── Library lesson ────────────────────────────────────────────────────────────

class LibraryLesson {
  const LibraryLesson({
    required this.id,
    required this.title,
    required this.position,
    this.content,
    this.videoUrl,
    this.durationSec,
    this.isPreview = false,
    this.isRequired = true,
  });

  final String id;
  final String title;
  final int position;
  final String? content;
  final String? videoUrl;
  final int? durationSec;
  final bool isPreview;
  final bool isRequired;

  factory LibraryLesson.fromJson(Map<String, dynamic> json) => LibraryLesson(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        position: json['position'] as int? ?? 0,
        content: json['content'] as String?,
        videoUrl: json['videoUrl'] as String?,
        durationSec: json['durationSec'] as int?,
        isPreview: json['isPreview'] as bool? ?? false,
        isRequired: json['isRequired'] as bool? ?? true,
      );
}

// ── Course file ───────────────────────────────────────────────────────────────

class CourseFileModel {
  const CourseFileModel({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    this.lessonId,
  });

  final String id;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final String createdAt;
  final String? lessonId;

  factory CourseFileModel.fromJson(Map<String, dynamic> json) =>
      CourseFileModel(
        id: json['id'] as String? ?? '',
        originalName: json['originalName'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] as String? ?? '',
        lessonId: json['lessonId'] as String?,
      );

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Library course (full detail with lessons + files) ─────────────────────────

class LibraryCourseDetail {
  const LibraryCourseDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.instructorName,
    required this.level,
    this.shortDescription,
    this.description,
    this.thumbnailUrl,
    this.category,
    this.lessons = const [],
    this.files = const [],
  });

  final String id;
  final String title;
  final String slug;
  final String instructorName;
  final String level;
  final String? shortDescription;
  final String? description;
  final String? thumbnailUrl;
  final LibraryCategoryModel? category;
  final List<LibraryLesson> lessons;
  final List<CourseFileModel> files;

  factory LibraryCourseDetail.fromJson(Map<String, dynamic> json) =>
      LibraryCourseDetail(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        instructorName: json['instructorName'] as String? ?? '',
        level: json['level'] as String? ?? 'BEGINNER',
        shortDescription: json['shortDescription'] as String?,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        category: json['category'] != null
            ? LibraryCategoryModel.fromJson(
                json['category'] as Map<String, dynamic>)
            : null,
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((e) => LibraryLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
        files: (json['files'] as List<dynamic>? ?? [])
            .map((e) => CourseFileModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get totalDurationSec =>
      lessons.fold(0, (sum, l) => sum + (l.durationSec ?? 0));
}

// ── Library course summary (for list view) ────────────────────────────────────

class LibraryCourseSummary {
  const LibraryCourseSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.instructorName,
    required this.level,
    this.shortDescription,
    this.thumbnailUrl,
    this.category,
  });

  final String id;
  final String title;
  final String slug;
  final String instructorName;
  final String level;
  final String? shortDescription;
  final String? thumbnailUrl;
  final LibraryCategoryModel? category;

  factory LibraryCourseSummary.fromJson(Map<String, dynamic> json) =>
      LibraryCourseSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        instructorName: json['instructorName'] as String? ?? '',
        level: json['level'] as String? ?? 'BEGINNER',
        shortDescription: json['shortDescription'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        category: json['category'] != null
            ? LibraryCategoryModel.fromJson(
                json['category'] as Map<String, dynamic>)
            : null,
      );
}

// ── Entitlement ───────────────────────────────────────────────────────────────

class EntitlementModel {
  const EntitlementModel({
    required this.id,
    required this.courseId,
    required this.status,
    required this.grantedAt,
    required this.course,
    this.revokedAt,
    this.revokeReason,
  });

  final String id;
  final String courseId;
  final String status; // ACTIVE | REVOKED
  final String grantedAt;
  final String? revokedAt;
  final String? revokeReason;
  final LibraryCourseSummary course;

  bool get isActive => status == 'ACTIVE';
  bool get isRevoked => status == 'REVOKED';

  factory EntitlementModel.fromJson(Map<String, dynamic> json) =>
      EntitlementModel(
        id: json['id'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        grantedAt: json['grantedAt'] as String? ?? '',
        revokedAt: json['revokedAt'] as String?,
        revokeReason: json['revokeReason'] as String?,
        course: LibraryCourseSummary.fromJson(
            json['course'] as Map<String, dynamic>? ?? {}),
      );
}

// ── Progress ──────────────────────────────────────────────────────────────────

class LessonProgressModel {
  const LessonProgressModel({
    required this.id,
    required this.lessonId,
    required this.completedAt,
  });

  final String id;
  final String lessonId;
  final String completedAt;

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) =>
      LessonProgressModel(
        id: json['id'] as String? ?? '',
        lessonId: json['lessonId'] as String? ?? '',
        completedAt: json['completedAt'] as String? ?? '',
      );
}

class CourseProgressSummary {
  const CourseProgressSummary({
    required this.totalLessons,
    required this.completedLessons,
    required this.completedLessonIds,
  });

  final int totalLessons;
  final int completedLessons;
  final Set<String> completedLessonIds;

  double get percent =>
      totalLessons == 0 ? 0.0 : completedLessons / totalLessons;
  bool get isComplete => totalLessons > 0 && completedLessons >= totalLessons;

  CourseProgressSummary markLesson(String lessonId) {
    final ids = {...completedLessonIds, lessonId};
    return CourseProgressSummary(
      totalLessons: totalLessons,
      completedLessons: ids.length,
      completedLessonIds: ids,
    );
  }
}

// ── Secure Downloads ──────────────────────────────────────────────────────────

class DownloadTokenResponse {
  const DownloadTokenResponse({
    required this.downloadUrl,
    required this.expiresAt,
    required this.maxDownloads,
  });

  final String downloadUrl;
  final DateTime expiresAt;
  final int maxDownloads;

  factory DownloadTokenResponse.fromJson(Map<String, dynamic> json) =>
      DownloadTokenResponse(
        downloadUrl: json['downloadUrl'] as String? ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(minutes: 10)),
        maxDownloads: (json['maxDownloads'] as num?)?.toInt() ?? 1,
      );
}

// ── Lesson Completion Result ──────────────────────────────────────────────────

class LessonCompletionResult {
  const LessonCompletionResult({
    required this.created,
    required this.percentage,
    required this.isComplete,
    this.certificateCode,
    this.certificateCreated = false,
  });

  final bool created;
  final int percentage;
  final bool isComplete;
  final String? certificateCode;
  final bool certificateCreated;

  factory LessonCompletionResult.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    final cert = json['certificate'] as Map<String, dynamic>?;
    return LessonCompletionResult(
      created: json['created'] as bool? ?? false,
      percentage: (progress['percentage'] as num?)?.toInt() ?? 0,
      isComplete: progress['isComplete'] as bool? ?? false,
      certificateCode: cert?['certificateCode'] as String?,
      certificateCreated: json['certificateCreated'] as bool? ?? false,
    );
  }
}

