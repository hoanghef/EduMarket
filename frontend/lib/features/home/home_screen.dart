import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/health_repository.dart';
import '../../core/theme/app_theme.dart';

/// Temporary home screen shown during initial setup.
/// Calls GET /api/health to verify backend connectivity.
/// Will be replaced with the real home page (Section 6 of TODO).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EduMarket',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ────────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4F46E5), // primary
                    Color(0xFF7C3AED), // violet
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🎓  CSE703102 – E-commerce  •  Topic 12',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Learn Anything,\nAnywhere with\nEduMarket',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The complete digital course marketplace.\nExplore courses, purchase securely, and start learning today.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 18),
                        ),
                        child: const Text(
                          'Browse Courses',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 18),
                        ),
                        child: const Text('Learn More'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Backend Status Card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(32),
              child: _BackendStatusCard(healthAsync: healthAsync),
            ),

            // ── Coming soon ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
              child: Column(
                children: [
                  Text(
                    'Features Coming Soon',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: const [
                      _FeatureChip(icon: Icons.search, label: 'Search & Filter'),
                      _FeatureChip(icon: Icons.shopping_cart_outlined, label: 'Shopping Cart'),
                      _FeatureChip(icon: Icons.payment, label: 'VNPay / COD'),
                      _FeatureChip(icon: Icons.library_books_outlined, label: 'My Library'),
                      _FeatureChip(icon: Icons.download_outlined, label: 'Secure Downloads'),
                      _FeatureChip(icon: Icons.workspace_premium_outlined, label: 'Certificates'),
                    ],
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

// ── Backend status widget ────────────────────────────────────────────────────

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({required this.healthAsync});

  final AsyncValue<HealthStatus> healthAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.api, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Backend Connectivity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            healthAsync.when(
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Connecting to backend…'),
                ],
              ),
              error: (err, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Backend not reachable',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $err',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.error),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start the backend with: cd backend && npm run dev',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              data: (health) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Backend connected',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(label: 'Service', value: health.service),
                  _StatusRow(label: 'Version', value: health.version),
                  _StatusRow(label: 'Environment', value: health.environment),
                  _StatusRow(label: 'Server time', value: health.timestamp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppTheme.surfaceVariant,
      side: BorderSide.none,
    );
  }
}
