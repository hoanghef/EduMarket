import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edumarket/core/api/health_repository.dart';
import 'package:edumarket/main.dart';

void main() {
  testWidgets('App renders EduMarket branding', (WidgetTester tester) async {
    // Override the health provider so no real HTTP call is made during tests.
    final container = ProviderContainer(
      overrides: [
        healthProvider.overrideWith(
          (ref) async => const HealthStatus(
            status: 'ok',
            service: 'EduMarket API',
            version: '0.1.0',
            environment: 'test',
            timestamp: '2026-01-01T00:00:00.000Z',
          ),
        ),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const EduMarketApp(),
      ),
    );

    // Let the async provider resolve.
    await tester.pumpAndSettle();

    // Verify EduMarket branding appears.
    expect(find.text('EduMarket'), findsWidgets);

    // Verify the backend status card shows connected state.
    expect(find.text('Backend connected'), findsOneWidget);
  });
}
