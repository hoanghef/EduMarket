import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/seo/seo_data.dart';
import '../../core/seo/seo_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import 'providers/policy_provider.dart';

class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key, required this.slug});

  final String slug;

  static const _availablePolicies = [
    ('business', 'Thông tin người bán', Icons.storefront_outlined),
    ('terms', 'Điều khoản giao dịch', Icons.gavel_outlined),
    ('refunds', 'Chính sách đổi trả / hoàn tiền', Icons.assignment_return_outlined),
    ('privacy', 'Chính sách dữ liệu cá nhân', Icons.shield_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(policyDetailProvider(slug));

    return AppShell(
      child: Container(
        color: AppTheme.surface,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Breakpoint.pagePadding(context),
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Breadcrumb ──────────────────────────────────────────────
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/'),
                      child: const Text('Trang chủ',
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    ),
                    const Text(' / ',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    const Text('Chính sách & Quy định',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Policy navigation tabs ─────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availablePolicies.map((p) {
                      final isSelected = p.$1 == slug;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(p.$3,
                              size: 16,
                              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant),
                          label: Text(p.$2),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val && !isSelected) {
                              context.go('/chinh-sach/${p.$1}');
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Policy Content Body ─────────────────────────────────────
                policyAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text('Không thể tải chính sách: $error'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.refresh(policyDetailProvider(slug)),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                  data: (policy) {
                    // Update SEO metadata
                    final summary = policy.sections.isNotEmpty
                        ? policy.sections.first.body
                        : 'Chính sách và quy định tại EduMarket.';
                    SeoHelper.apply(
                      SeoData.policy(
                        title: policy.title,
                        slug: policy.slug,
                        summary: summary,
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Updated date
                        Text(
                          policy.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cập nhật lần cuối: ${policy.updatedAt}',
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Academic project notice
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF475569), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  policy.legalNotice ??
                                      'Lưu ý học thuật: Nội dung chính sách phục vụ đồ án CSE703102 – E-commerce; hệ thống thực tế cần rà soát và tư vấn pháp lý chuyên nghiệp.',
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Policy sections
                        ...policy.sections.map((sec) => Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sec.heading,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        sec.body,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.onSurfaceVariant,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
