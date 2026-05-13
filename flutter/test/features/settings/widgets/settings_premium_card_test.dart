import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/settings/widgets/settings_premium_card.dart';

/// Render assertions per visual state of the SettingsPremiumCard. Asserts
/// the State 1/2/3 + loading + error → State 1 fallback matrix from the
/// spec's "State resolution" table.

GoRouter _testRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: SettingsPremiumCard()),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
}

Widget _pumpCard({
  required Override premiumOverride,
}) {
  return ProviderScope(
    overrides: [premiumOverride],
    child: MaterialApp.router(routerConfig: _testRouter()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'State 1 (free) renders gold card with "Sakina Premium" + '
      'Weekly & Annual subtitle', (tester) async {
    await tester.pumpWidget(_pumpCard(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: false, billingIssueAt: null),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sakina Premium'), findsOneWidget);
    expect(
      find.textContaining('Weekly & Annual'),
      findsOneWidget,
    );
    // State 1 chevron is gold; the row uses the workspace_premium icon.
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets(
      'State 2 (premium · active) renders "Active · Manage subscription" '
      'subtitle with emerald icon', (tester) async {
    await tester.pumpWidget(_pumpCard(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: true, billingIssueAt: null),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sakina Premium'), findsOneWidget);
    expect(find.textContaining('Active'), findsOneWidget);
    expect(find.textContaining('Manage subscription'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets(
      'State 3 (premium · billing issue) renders amber "Payment issue" '
      '+ warning icon', (tester) async {
    await tester.pumpWidget(_pumpCard(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (
          isPremium: true,
          billingIssueAt: '2026-05-13T12:00:00.000Z',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Payment issue'), findsOneWidget);
    expect(find.text('Tap to update payment'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets(
      'loading state renders a neutral skeleton at the same '
      'icon-title-subtitle shape (no page jump)', (tester) async {
    final completer = Completer<PremiumState>();
    await tester.pumpWidget(_pumpCard(
      premiumOverride:
          premiumStateProvider.overrideWith((ref) => completer.future),
    ));
    // Pump once — provider still loading.
    await tester.pump();

    // Title placeholder is still 'Sakina Premium' so the page does not jump
    // when the provider resolves.
    expect(find.text('Sakina Premium'), findsOneWidget);
    // No State 1 gold-card subtitle yet (skeleton uses NBSP).
    expect(find.textContaining('Weekly & Annual'), findsNothing);
    expect(find.textContaining('Active'), findsNothing);
    expect(find.text('Payment issue'), findsNothing);

    completer.complete((isPremium: false, billingIssueAt: null));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'error state falls back to State 1 — App Review fix is preserved '
      'on RevenueCat outages', (tester) async {
    await tester.pumpWidget(_pumpCard(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => throw StateError('RC down'),
      ),
    ));
    await tester.pumpAndSettle();

    // Spec says error → State 1 (free) so the upgrade affordance is never
    // hidden from a free user. Card renders the State 1 subtitle.
    expect(find.text('Sakina Premium'), findsOneWidget);
    expect(find.textContaining('Weekly & Annual'), findsOneWidget);
  });
}
