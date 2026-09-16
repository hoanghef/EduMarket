import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../constants/app_constants.dart';

/// Application router using go_router with path-based URL strategy.
final appRouter = GoRouter(
  initialLocation: AppConstants.routeHome,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppConstants.routeHome,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Future routes will be added here as features are implemented.
    // /khoa-hoc, /login, /register, /cart, /checkout, /account, etc.
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(state.error?.message ?? 'Unknown error'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(AppConstants.routeHome),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
