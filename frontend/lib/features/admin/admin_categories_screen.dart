import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/admin_provider.dart';
import 'widgets/admin_shell.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm danh mục mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên danh mục *'),
                onChanged: (val) {
                  // Auto-generate slug
                  slugCtrl.text = val
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^\w\s-]'), '')
                      .replaceAll(RegExp(r'\s+'), '-');
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: slugCtrl,
                decoration: const InputDecoration(labelText: 'Slug (URL) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả (tùy chọn)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final slug = slugCtrl.text.trim();
              if (name.isEmpty || slug.isEmpty) return;
              try {
                await ref.read(adminRepositoryProvider).createCategory({
                  'name': name,
                  'slug': slug,
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                });
                ref.invalidate(adminCategoriesProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Lỗi tạo danh mục: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(adminCategoriesProvider);

    return AdminShell(
      currentRoute: '/admin/categories',
      title: 'Quản lý danh mục',
      actions: [
        FilledButton.icon(
          onPressed: () => _showCreateDialog(context, ref),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Thêm danh mục'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(adminCategoriesProvider),
        ),
      ],
      child: asyncCategories.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('Lỗi tải danh mục: $err',
                style: const TextStyle(color: AppTheme.error)),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Text('Chưa có danh mục nào.'),
              ),
            );
          }

          return Card(
            elevation: 1,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final cat = categories[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.category, color: AppTheme.primary, size: 18),
                  ),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('/danh-muc/${cat.slug}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Xóa danh mục',
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: Text('Bạn có chắc muốn xóa danh mục "${cat.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(adminRepositoryProvider).deleteCategory(cat.id);
                              ref.invalidate(adminCategoriesProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
