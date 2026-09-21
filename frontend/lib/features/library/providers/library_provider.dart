import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/library_models.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class LibraryRepository {
  LibraryRepository(this._dio);

  final Dio _dio;

  /// GET /api/library  – returns all ACTIVE entitlements
  Future<List<EntitlementModel>> getLibrary() async {
    final response = await _dio.get('/api/library');
    final items = response.data['data']['items'] as List<dynamic>;
    return items
        .map((e) => EntitlementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/library/courses/:courseId  – protected course detail
  Future<LibraryCourseDetail> getCourseDetail(String courseId) async {
    final response = await _dio.get('/api/library/courses/$courseId');
    return LibraryCourseDetail.fromJson(
        response.data['data']['course'] as Map<String, dynamic>);
  }

  /// GET /api/library/lessons/:lessonId  – protected lesson detail
  Future<LibraryLesson> getLessonDetail(String lessonId) async {
    final response = await _dio.get('/api/library/lessons/$lessonId');
    return LibraryLesson.fromJson(
        response.data['data']['lesson'] as Map<String, dynamic>);
  }

  /// POST /api/library/lessons/:lessonId/complete  – idempotent completion
  Future<LessonCompletionResult> completeLesson(String lessonId) async {
    final response = await _dio.post('/api/library/lessons/$lessonId/complete');
    return LessonCompletionResult.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/files/:fileId/download-token  – generate short-lived download token
  Future<DownloadTokenResponse> requestDownloadToken(String fileId) async {
    final response = await _dio.post('/api/files/$fileId/download-token');
    return DownloadTokenResponse.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/download/:token  – stream file via short-lived token
  Future<List<int>> downloadFile(String downloadUrl) async {
    final response = await _dio.get<List<int>>(
      downloadUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(dioProvider));
});

/// All ACTIVE entitlements for the current user.
final libraryProvider =
    FutureProvider.autoDispose<List<EntitlementModel>>((ref) {
  return ref.watch(libraryRepositoryProvider).getLibrary();
});

/// Protected course detail (lessons + files).
final libraryCourseDetailProvider =
    FutureProvider.autoDispose.family<LibraryCourseDetail, String>(
  (ref, courseId) =>
      ref.watch(libraryRepositoryProvider).getCourseDetail(courseId),
);

// ── Progress state notifier ───────────────────────────────────────────────────

class CourseProgressNotifier
    extends AutoDisposeFamilyNotifier<CourseProgressSummary, String> {
  @override
  CourseProgressSummary build(String courseId) {
    // Will be populated when the course detail is loaded.
    return const CourseProgressSummary(
      totalLessons: 0,
      completedLessons: 0,
      completedLessonIds: {},
    );
  }

  void initFromCourse(LibraryCourseDetail course, Set<String> completedIds) {
    state = CourseProgressSummary(
      totalLessons: course.lessons.length,
      completedLessons: completedIds.length,
      completedLessonIds: completedIds,
    );
  }

  Future<LessonCompletionResult?> complete(String lessonId) async {
    if (state.completedLessonIds.contains(lessonId)) return null;
    final result =
        await ref.read(libraryRepositoryProvider).completeLesson(lessonId);
    state = state.markLesson(lessonId);
    return result;
  }
}

final courseProgressProvider =
    NotifierProvider.autoDispose.family<CourseProgressNotifier, CourseProgressSummary, String>(
  CourseProgressNotifier.new,
);
