import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String? _selectedStatus = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final asyncReviews = ref.watch(adminReviewsProvider(_selectedStatus));

    final filterStatuses = [
      (label: 'Chờ duyệt', value: 'PENDING'),
      (label: 'Đã duyệt', value: 'APPROVED'),
      (label: 'Bị từ chối', value: 'REJECTED'),
      (label: 'Tất cả', value: null),
    ];

    return AdminShell(
      currentRoute: '/admin/reviews',
      title: 'Kiểm duyệt đánh giá',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.invalidate(adminReviewsProvider(_selectedStatus)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: filterStatuses.map((item) {
              final isSelected = _selectedStatus == item.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(item.label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedStatus = item.value);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          asyncReviews.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Lỗi tải đánh giá: $err',
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Text('Không có đánh giá nào trong danh mục này.'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final review = reviews[i];

                  Color statusColor = Colors.amber;
                  if (review.status == 'APPROVED') {
                    statusColor = AppTheme.success;
                  } else if (review.status == 'REJECTED') {
                    statusColor = AppTheme.error;
                  }

                  return Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.courseTitle,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Người gửi: ${review.customerName} (${review.customerEmail})',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  review.status,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (s) => Icon(
                                  s < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          if (review.comment != null &&
                              review.comment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              review.comment!,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                          if (review.status == 'PENDING') ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(adminRepositoryProvider)
                                          .moderateReview(
                                              review.id, 'REJECTED');
                                      ref.invalidate(adminReviewsProvider(
                                          _selectedStatus));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Đã từ chối đánh giá.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Lỗi: $e'),
                                              backgroundColor:
                                                  AppTheme.error),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.close,
                                      size: 16, color: AppTheme.error),
                                  label: const Text('Từ chối',
                                      style: TextStyle(color: AppTheme.error)),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(adminRepositoryProvider)
                                          .moderateReview(
                                              review.id, 'APPROVED');
                                      ref.invalidate(adminReviewsProvider(
                                          _selectedStatus));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Đã phê duyệt đánh giá công khai.'),
                                            backgroundColor:
                                                AppTheme.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Lỗi: $e'),
                                              backgroundColor:
                                                  AppTheme.error),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Phê duyệt'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
