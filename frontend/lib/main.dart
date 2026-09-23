import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    // Wrap in ProviderScope so all Riverpod providers are available.
    const ProviderScope(
      child: EduMarketApp(),
    ),
  );
}

/// Root application widget.
class EduMarketApp extends ConsumerWidget {
  const EduMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EduMarket – Online Course Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
