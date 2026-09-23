import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../seo/seo_data.dart';
import '../seo/seo_helper.dart';
import '../theme/app_theme.dart';

class ForbiddenScreen extends ConsumerWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SeoHelper.apply(SeoData.private(title: 'Truy cập bị từ chối (403)'));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_bad_outlined,
                    size: 64, color: AppTheme.error),
              ),
              const SizedBox(height: 24),
              Text(
                '403 - Quyền truy cập bị từ chối',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tài khoản của bạn không có quyền truy cập vào khu vực quản trị viên (ADMIN).\nChỉ những người dùng được phân quyền ADMIN mới có thể vào khu vực này.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Đổi tài khoản'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home, size: 16),
                    label: const Text('Về trang chủ'),
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
