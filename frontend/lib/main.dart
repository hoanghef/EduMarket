import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Use path-based URL strategy (no hash in URLs, required by PROJECT_CONTEXT §22).
  // For Flutter Web, this is done via the web/index.html base href
  // and go_router's default path strategy.
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
      routerConfig: appRouter,
    );
  }
}
