import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'models/library_models.dart';
import 'providers/library_provider.dart';

/// Lesson detail / player screen.
///
/// Displays lesson content (text / video URL).
/// Allows user to mark the lesson as complete and navigate prev/next.
class LessonPlayerScreen extends ConsumerStatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen> {
  bool _isLoading = true;
  bool _accessDenied = false;
  String? _error;
  LibraryLesson? _lesson;
  LibraryCourseDetail? _course;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _accessDenied = false;
    });
    try {
      final repo = ref.read(libraryRepositoryProvider);
      // Load lesson + course in parallel
      final results = await Future.wait([
        repo.getLessonDetail(widget.lessonId),
        repo.getCourseDetail(widget.courseId),
      ]);
      setState(() {
        _lesson = results[0] as LibraryLesson;
        _course = results[1] as LibraryCourseDetail;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        setState(() {
          _accessDenied = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải bài học. ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markComplete() async {
    setState(() => _completing = true);
    try {
      await ref
          .read(courseProgressProvider(widget.courseId).notifier)
          .complete(widget.lessonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bài học đã được đánh dấu hoàn thành!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đánh dấu hoàn thành: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _navigateLesson(int delta) {
    final course = _course;
    if (course == null) return;
    final currentIndex =
        course.lessons.indexWhere((l) => l.id == widget.lessonId);
    if (currentIndex < 0) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= course.lessons.length) return;
    final nextLesson = course.lessons[nextIndex];
    context.go(
        '/library/courses/${widget.courseId}/lessons/${nextLesson.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(
          child: const Center(child: CircularProgressIndicator()));
    }

    if (_accessDenied) {
      return AppShell(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text('Truy cập bị từ chối',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Bạn không có quyền truy cập bài học này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.go('/library/courses/${widget.courseId}'),
                  child: const Text('Quay lại khóa học'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return AppShell(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadLesson,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final lesson = _lesson!;
    final course = _course!;
    final progress = ref.watch(courseProgressProvider(widget.courseId));
    final isDone = progress.completedLessonIds.contains(lesson.id);

    final currentIndex =
        course.lessons.indexWhere((l) => l.id == lesson.id);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < course.lessons.length - 1;

    return AppShell(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Breakpoint.pagePadding(context),
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Breakpoint.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Breadcrumb ───────────────────────────────────────────
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: Size.zero, padding: EdgeInsets.zero),
                        onPressed: () => context.go('/library'),
                        child: const Text('Thư viện',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const Text('/',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: Size.zero, padding: EdgeInsets.zero),
                        onPressed: () => context
                            .go('/library/courses/${widget.courseId}'),
                        child: Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Text('/',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 13)),
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Lesson title ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (isDone)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: AppTheme.success),
                              SizedBox(width: 4),
                              Text(
                                'Đã hoàn thành',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (lesson.durationSec != null && lesson.durationSec! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '⏱ ${_formatDuration(lesson.durationSec!)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Video placeholder / URL ───────────────────────────────
                  if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
                    _VideoSection(videoUrl: lesson.videoUrl!),

                  // ── Content ──────────────────────────────────────────────
                  if (lesson.content != null && lesson.content!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Text(
                        lesson.content!,
                        style: const TextStyle(
                            fontSize: 15, height: 1.7),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Complete + navigation ────────────────────────────────
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      // Prev
                      OutlinedButton.icon(
                        onPressed: hasPrev ? () => _navigateLesson(-1) : null,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Bài trước'),
                      ),

                      // Mark done
                      if (!isDone)
                        FilledButton.icon(
                          onPressed: _completing ? null : _markComplete,
                          icon: _completing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline,
                                  size: 18),
                          label: Text(_completing
                              ? 'Đang lưu...'
                              : 'Đánh dấu hoàn thành'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppTheme.success.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.success,
                              disabledBackgroundColor:
                                  AppTheme.success.withValues(alpha: 0.1),
                              disabledForegroundColor: AppTheme.success),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Đã hoàn thành'),
                        ),

                      // Next
                      FilledButton.icon(
                        onPressed:
                            hasNext ? () => _navigateLesson(1) : null,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Bài tiếp theo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    return '$m phút${s > 0 ? ' ${s}s' : ''}';
  }
}

// ── Video section ─────────────────────────────────────────────────────────────

class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.videoUrl});
  final String videoUrl;

  bool _isYouTube(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: Icon(Icons.play_circle_filled,
                    size: 80, color: Colors.white38),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video bài học',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isYouTube(videoUrl)
                          ? '▶ YouTube: $videoUrl'
                          : '▶ $videoUrl',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Overlay note (video player integration is a Phase 13 concern)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Trình phát video sẽ được tích hợp trong giai đoạn tiếp theo',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
