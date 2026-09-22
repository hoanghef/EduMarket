import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/review_models.dart';
import '../providers/review_provider.dart';

class CourseReviewsSection extends ConsumerStatefulWidget {
  const CourseReviewsSection({
    super.key,
    required this.courseId,
    required this.ratingAverage,
    required this.ratingCount,
  });

  final String courseId;
  final double ratingAverage;
  final int ratingCount;

  @override
  ConsumerState<CourseReviewsSection> createState() =>
      _CourseReviewsSectionState();
}

class _CourseReviewsSectionState extends ConsumerState<CourseReviewsSection> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.submitReview(
        courseId: widget.courseId,
        rating: _selectedRating,
        comment: _commentController.text,
      );

      setState(() {
        _successMessage =
            'Đánh giá của bạn đã được gửi thành công và đang chờ kiểm duyệt!';
        _commentController.clear();
      });

      ref.invalidate(myCourseReviewProvider(widget.courseId));
      ref.invalidate(courseReviewsProvider(widget.courseId));
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Không thể gửi đánh giá.';
      if (data is Map<String, dynamic>) {
        if (data['code'] == 'COURSE_ACCESS_DENIED') {
          msg = 'Bạn cần mua và sở hữu khóa học này để có thể gửi đánh giá.';
        } else if (data['code'] == 'REVIEW_ALREADY_EXISTS') {
          msg = 'Bạn đã gửi đánh giá cho khóa học này rồi.';
        } else if (data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi không xác định: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final asyncReviews = ref.watch(courseReviewsProvider(widget.courseId));
    final asyncMyReview = isAuthenticated
        ? ref.watch(myCourseReviewProvider(widget.courseId))
        : const AsyncValue.data(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá từ học viên',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),

        // Rating Overview Box
        _RatingSummaryCard(
          ratingAverage: widget.ratingAverage,
          ratingCount: widget.ratingCount,
        ),
        const SizedBox(height: 24),

        // User Review Form or Status
        if (!isAuthenticated)
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đăng nhập sau khi mua khóa học để chia sẻ đánh giá của bạn.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => context.go('/login'),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ),
          )
        else
          asyncMyReview.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
            data: (myReview) {
              if (myReview != null) {
                return _MyReviewStatusCard(review: myReview);
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Viết đánh giá của bạn',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Đánh giá: ',
                              style: TextStyle(fontSize: 14)),
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              icon: Icon(
                                star <= _selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 28,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedRating = star),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '$_selectedRating sao',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          hintText:
                              'Chia sẻ trải nghiệm học tập, chất lượng bài giảng và kiến thức thu được...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13),
                        ),
                      ],
                      if (_successMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _successMessage!,
                          style: const TextStyle(
                              color: AppTheme.success, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submitReview,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, size: 16),
                          label: const Text('Gửi đánh giá'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),

        // Public Approved Reviews List
        asyncReviews.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Text(
            'Lỗi khi tải đánh giá: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có đánh giá nào cho khóa học này. Hãy là người đầu tiên đánh giá!',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _ReviewItemTile(review: review);
              },
            );
          },
        ),
      ],
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.ratingAverage,
    required this.ratingCount,
  });

  final double ratingAverage;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  ratingAverage.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < ratingAverage.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ratingCount đánh giá',
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đánh giá được kiểm duyệt công khai',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tất cả nhận xét hiển thị đều từ học viên thực tế đã sở hữu và hoàn thành bài giảng.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReviewStatusCard extends StatelessWidget {
  const _MyReviewStatusCard({required this.review});
  final MyReviewModel review;

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.amber;
    String statusLabel = 'Đang chờ kiểm duyệt';
    IconData statusIcon = Icons.hourglass_top;

    if (review.isApproved) {
      statusColor = AppTheme.success;
      statusLabel = 'Đã được duyệt (Công khai)';
      statusIcon = Icons.check_circle_outline;
    } else if (review.isRejected) {
      statusColor = AppTheme.error;
      statusLabel = 'Không được duyệt';
      statusIcon = Icons.cancel_outlined;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đánh giá của bạn',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewItemTile extends StatelessWidget {
  const _ReviewItemTile({required this.review});
  final ReviewItemModel review;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : 'H',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.reviewerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
