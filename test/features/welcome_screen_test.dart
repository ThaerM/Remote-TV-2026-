import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_tv_2026/app/routing/app_router.dart';
import 'package:remote_tv_2026/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv_2026/features/onboarding/presentation/welcome_screen.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

void main() {
  testWidgets('WelcomeScreen shows the product name and a CTA to discovery', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.welcome,
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.discovery,
          builder: (context, state) => const DiscoveryScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        // Only the fake provider here - this test is about navigation,
        // not discovery, and the real AndroidTvProvider's discovery
        // hits real mDNS/network I/O that has no place in a widget test.
        overrides: [
          tvProviderRegistryProvider.overrideWith(
            (ref) => TvProviderRegistry([ref.watch(fakeTvProviderProvider)]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.text('Remote TV 2026'), findsOneWidget);
    expect(find.text('Find my TV'), findsOneWidget);

    await tester.ensureVisible(find.text('Find my TV'));
    await tester.tap(find.text('Find my TV'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(DiscoveryScreen), findsOneWidget);
  });
}
