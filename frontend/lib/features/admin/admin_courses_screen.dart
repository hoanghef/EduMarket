import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminCoursesScreen extends ConsumerStatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  ConsumerState<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends ConsumerState<AdminCoursesScreen> {
  String _searchQuery = '';

  String _fmtMoney(double amount) {
    final n = amount.toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final asyncCourses = ref.watch(adminCoursesProvider);

    return AdminShell(
      currentRoute: '/admin/courses',
      title: 'Quản lý khóa học',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminCoursesProvider),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm theo tên khóa học hoặc giảng viên...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          asyncCourses.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Lỗi tải danh sách: $err',
                    style: const TextStyle(color: AppTheme.error)),
              ),
            ),
            data: (courses) {
              final filtered = courses.where((c) {
                if (_searchQuery.isEmpty) return true;
                return c.title.toLowerCase().contains(_searchQuery) ||
                    c.instructorName.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Text('Không tìm thấy khóa học nào phù hợp.'),
                  ),
                );
              }

              return Card(
                elevation: 1,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Khóa học')),
                      DataColumn(label: Text('Giảng viên')),
                      DataColumn(label: Text('Giá bán')),
                      DataColumn(label: Text('Học viên')),
                      DataColumn(label: Text('Đánh giá')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: filtered.map((course) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                if (course.thumbnailUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      course.thumbnailUrl!,
                                      width: 48,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(width: 48, height: 32, color: Colors.grey.shade200),
                                    ),
                                  )
                                else
                                  Container(width: 48, height: 32, color: Colors.grey.shade200),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    course.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(course.instructorName)),
                          DataCell(Text('${_fmtMoney(course.effectivePrice)}₫')),
                          DataCell(Text('${course.enrollmentCount}')),
                          DataCell(
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(course.ratingAverage.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PUBLISHED',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Xem trang công khai',
                                  icon: const Icon(Icons.visibility_outlined, size: 18),
                                  onPressed: () => context.go('/khoa-hoc/${course.slug}'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
