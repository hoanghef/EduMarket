import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/download_helper.dart';
import '../../core/widgets/app_shell.dart';
import 'models/library_models.dart';
import 'providers/library_provider.dart';

/// Screen showing the full course detail with lesson list + progress bar.
/// Handles ACTIVE access and REVOKED (403) access denial gracefully.
class CourseLearningScreen extends ConsumerStatefulWidget {
  const CourseLearningScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseLearningScreen> createState() =>
      _CourseLearningScreenState();
}

class _CourseLearningScreenState extends ConsumerState<CourseLearningScreen> {
  bool _accessDenied = false;
  String? _accessDeniedMessage;
  LibraryCourseDetail? _course;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _accessDenied = false;
    });
    try {
      final course = await ref
          .read(libraryRepositoryProvider)
          .getCourseDetail(widget.courseId);
      setState(() {
        _course = course;
        _isLoading = false;
      });
      // Init progress with empty completed set (no separate progress API yet;
      // progress is tracked locally after user marks lessons complete).
      ref
          .read(courseProgressProvider(widget.courseId).notifier)
          .initFromCourse(course, {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final code =
            e.response?.data?['code'] as String? ?? 'ENTITLEMENT_REQUIRED';
        setState(() {
          _accessDenied = true;
          _accessDeniedMessage = code == 'ENTITLEMENT_REVOKED'
              ? 'Quyền truy cập khóa học của bạn đã bị thu hồi.'
              : 'Bạn không có quyền truy cập khóa học này.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không thể tải khóa học. ${e.message}';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_accessDenied) {
      return _AccessDeniedScreen(
        message: _accessDeniedMessage ??
            'Bạn không có quyền truy cập khóa học này.',
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
              Text(
                'Lỗi khi tải khóa học',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadCourse,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final course = _course!;
    final progress = ref.watch(courseProgressProvider(widget.courseId));

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
                  // ── Back button ──────────────────────────────────────────
                  TextButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Thư viện của tôi'),
                  ),
                  const SizedBox(height: 16),

                  // ── Course header ────────────────────────────────────────
                  _CourseHeader(course: course),
                  const SizedBox(height: 24),

                  // ── Progress bar ─────────────────────────────────────────
                  _ProgressBar(progress: progress),
                  if (progress.isComplete) ...[
                    const SizedBox(height: 20),
                    _CompletionCelebrationBanner(courseTitle: course.title),
                  ],
                  const SizedBox(height: 32),

                  // ── Layout: lesson list + files ──────────────────────────
                  Breakpoint.isDesktop(context)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _LessonList(
                                course: course,
                                progress: progress,
                                courseId: widget.courseId,
                              ),
                            ),
                            const SizedBox(width: 24),
                            if (course.files.isNotEmpty)
                              SizedBox(
                                width: 280,
                                child: _FilesSection(files: course.files),
                              ),
                          ],
                        )
                      : Column(
                          children: [
                            _LessonList(
                              course: course,
                              progress: progress,
                              courseId: widget.courseId,
                            ),
                            if (course.files.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _FilesSection(files: course.files),
                            ],
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
}

// ── Access denied screen ──────────────────────────────────────────────────────

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 24),
              Text(
                'Truy cập bị từ chối',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nếu bạn cho rằng đây là lỗi, vui lòng liên hệ hỗ trợ.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/library'),
                    icon: const Icon(Icons.library_books_outlined, size: 18),
                    label: const Text('Thư viện'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.go('/khoa-hoc'),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: const Text('Khám phá khóa học'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Course header ─────────────────────────────────────────────────────────────

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course});
  final LibraryCourseDetail course;

  @override
  Widget build(BuildContext context) {
    return Breakpoint.isDesktop(context)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 240,
                  height: 135,
                  child: course.thumbnailUrl != null
                      ? Image.network(course.thumbnailUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _ThumbnailPlaceholderSmall())
                      : _ThumbnailPlaceholderSmall(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _CourseHeaderText(course: course)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (course.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(course.thumbnailUrl!,
                        fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 16),
              _CourseHeaderText(course: course),
            ],
          );
  }
}

class _CourseHeaderText extends StatelessWidget {
  const _CourseHeaderText({required this.course});
  final LibraryCourseDetail course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (course.category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              course.category!.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          course.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Giảng viên: ${course.instructorName}',
          style: const TextStyle(
              color: AppTheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 4),
        _LevelBadge(level: course.level),
      ],
    );
  }
}

class _ThumbnailPlaceholderSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.school_outlined, size: 40, color: AppTheme.primary),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      'BEGINNER' => ('Cơ bản', const Color(0xFF10B981)),
      'INTERMEDIATE' => ('Trung cấp', const Color(0xFFF59E0B)),
      'ADVANCED' => ('Nâng cao', const Color(0xFFEF4444)),
      _ => ('Mọi cấp độ', AppTheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final CourseProgressSummary progress;

  @override
  Widget build(BuildContext context) {
    final pct = progress.percent;
    final pctInt = (pct * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.isComplete
                    ? '🎉 Đã hoàn thành khóa học!'
                    : 'Tiến độ học tập',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pct == 1.0
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pctInt%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: pct == 1.0 ? AppTheme.success : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation(
                  pct == 1.0 ? AppTheme.success : AppTheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.completedLessons}/${progress.totalLessons} bài học đã hoàn thành',
            style: const TextStyle(
                fontSize: 13, color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Lesson list ───────────────────────────────────────────────────────────────

class _LessonList extends ConsumerWidget {
  const _LessonList({
    required this.course,
    required this.progress,
    required this.courseId,
  });
  final LibraryCourseDetail course;
  final CourseProgressSummary progress;
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Danh sách bài học (${course.lessons.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          ...course.lessons.asMap().entries.map((entry) {
            final index = entry.key;
            final lesson = entry.value;
            final isDone =
                progress.completedLessonIds.contains(lesson.id);
            return _LessonTile(
              lesson: lesson,
              index: index,
              isDone: isDone,
              courseId: courseId,
              onMarkDone: () async {
                try {
                  await ref
                      .read(courseProgressProvider(courseId).notifier)
                      .complete(lesson.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Không thể đánh dấu hoàn thành: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.isDone,
    required this.courseId,
    required this.onMarkDone,
  });

  final LibraryLesson lesson;
  final int index;
  final bool isDone;
  final String courseId;
  final VoidCallback onMarkDone;

  String _formatDuration(int? secs) {
    if (secs == null || secs == 0) return '';
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    return '${m}m${s > 0 ? ' ${s}s' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () =>
              context.go('/library/courses/$courseId/lessons/${lesson.id}'),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Index / check mark
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 16, color: AppTheme.success)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDone
                              ? AppTheme.onSurfaceVariant
                              : AppTheme.onSurface,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (lesson.durationSec != null &&
                          lesson.durationSec! > 0)
                        Text(
                          _formatDuration(lesson.durationSec),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),

                // Mark done button
                if (!isDone)
                  Tooltip(
                    message: 'Đánh dấu hoàn thành',
                    child: IconButton(
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      color: AppTheme.primary,
                      onPressed: onMarkDone,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.check_circle,
                        size: 20, color: AppTheme.success),
                  ),

                // Play icon
                const Icon(Icons.chevron_right,
                    color: AppTheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 64),
      ],
    );
  }
}

// ── Files section ─────────────────────────────────────────────────────────────

class _FilesSection extends StatelessWidget {
  const _FilesSection({required this.files});
  final List<CourseFileModel> files;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Tài liệu đính kèm',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          ...files.map((file) => _FileTile(file: file)),
        ],
      ),
    );
  }
}

class _CompletionCelebrationBanner extends StatelessWidget {
  const _CompletionCelebrationBanner({required this.courseTitle});
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 Chúc mừng bạn đã hoàn thành 100% khóa học!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chứng chỉ hoàn thành cho khóa học "$courseTitle" đã sẵn sàng để tải xuống và xác thực.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                ),
                onPressed: () => context.go('/certificates'),
                icon: const Icon(Icons.card_membership, size: 18),
                label: const Text('Xem chứng chỉ của tôi'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFD97706)),
                ),
                onPressed: () => context.go('/certificates/verify'),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Tra cứu xác thực công khai'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileTile extends ConsumerStatefulWidget {
  const _FileTile({required this.file});
  final CourseFileModel file;

  @override
  ConsumerState<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends ConsumerState<_FileTile> {
  bool _isDownloading = false;

  IconData _iconForMime(String mime) {
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('video')) return Icons.videocam_outlined;
    if (mime.contains('image')) return Icons.image_outlined;
    if (mime.contains('zip') || mime.contains('rar')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.attach_file_outlined;
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⏳ Đang yêu cầu tải xuống an toàn... (Token bảo mật 10 phút, tối đa 1 lượt tải)',
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      // 1. Request short-lived download token
      final tokenResponse = await ref
          .read(libraryRepositoryProvider)
          .requestDownloadToken(widget.file.id);

      // 2. Download file stream via the temporary URL
      final bytes = await ref
          .read(libraryRepositoryProvider)
          .downloadFile(tokenResponse.downloadUrl);

      // 3. Save bytes to client browser
      saveFileBytes(bytes, widget.file.originalName, widget.file.mimeType);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tải xuống "${widget.file.originalName}" thành công!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String errorMsg = 'Không thể tải tập tin.';
        final responseData = e.response?.data;
        final code = responseData is Map ? responseData['code'] : null;

        if (e.response?.statusCode == 410 || code == 'DOWNLOAD_TOKEN_EXPIRED') {
          errorMsg =
              'Liên kết tải xuống đã hết hạn (10 phút). Vui lòng nhấn nút tải lại để tạo liên kết mới.';
        } else if (e.response?.statusCode == 410 ||
            code == 'DOWNLOAD_TOKEN_EXHAUSTED') {
          errorMsg =
              'Liên kết tải xuống đã đạt số lượt tải tối đa (1 lần). Vui lòng nhấn nút tải lại.';
        } else if (e.response?.statusCode == 403 ||
            code == 'COURSE_ACCESS_REVOKED') {
          errorMsg =
              'Quyền truy cập khóa học đã bị thu hồi. Không thể tải tài liệu.';
        } else if (e.response?.statusCode == 403 ||
            code == 'COURSE_ACCESS_DENIED') {
          errorMsg =
              'Bạn chưa sở hữu khóa học này để tải tài liệu đính kèm.';
        } else if (responseData is Map && responseData['message'] != null) {
          errorMsg = responseData['message'] as String;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải tập tin: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconForMime(file.mimeType),
                size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.originalName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  file.formattedSize,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Tải xuống an toàn (Token 10 phút, 1 lần tải)',
            child: IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
              color: AppTheme.primary,
              onPressed: _isDownloading ? null : _handleDownload,
            ),
          ),
        ],
      ),
    );
  }
}
