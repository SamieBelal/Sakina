import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/settings/widgets/settings_premium_card.dart';

/// Lifecycle hook: returning from the StoreKit / Play Store sheet
/// (foreground resume) must invalidate `premiumStateProvider` so the
/// card reflects updated entitlement state without manual refresh.
/// Also verifies that the observer is removed on dispose — no
/// post-unmount invalidations.

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'AppLifecycleState.resumed invalidates premiumStateProvider — '
      'returns from manage-subscription sheet trigger fresh fetch',
      (tester) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStateProvider.overrideWith((ref) async {
            invocationCount += 1;
            return (isPremium: false, billingIssueAt: null);
          }),
        ],
        child: MaterialApp.router(routerConfig: _testRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(invocationCount, 1, reason: 'initial build fetches once');

    // Simulate background → foreground (returning from App Store).
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      invocationCount,
      2,
      reason: 'resume must invalidate the provider, forcing a re-fetch',
    );
  });

  testWidgets(
      'non-resume lifecycle events do NOT invalidate '
      '(paused / inactive / hidden are no-ops)', (tester) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStateProvider.overrideWith((ref) async {
            invocationCount += 1;
            return (isPremium: false, billingIssueAt: null);
          }),
        ],
        child: MaterialApp.router(routerConfig: _testRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(invocationCount, 1);

    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();

    expect(invocationCount, 1, reason: 'only resume triggers invalidation');
  });

  testWidgets(
      'unmount removes the lifecycle observer — no invalidation after dispose',
      (tester) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStateProvider.overrideWith((ref) async {
            invocationCount += 1;
            return (isPremium: false, billingIssueAt: null);
          }),
        ],
        child: MaterialApp.router(routerConfig: _testRouter()),
      ),
    );
    await tester.pumpAndSettle();
    expect(invocationCount, 1);

    // Unmount the card by swapping the entire app for an empty widget.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    // Fire resume — should NOT throw and must NOT trigger another fetch
    // (the card's observer was removed in dispose).
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      invocationCount,
      1,
      reason: 'dispose() must remove the WidgetsBindingObserver',
    );
  });
}
