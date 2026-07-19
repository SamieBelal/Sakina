import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/home/widgets/home_premium_strip.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

class _RecordingAnalytics extends AnalyticsService {
  final List<String> events = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    events.add(event);
  }
}

class _TestRouterShell extends StatefulWidget {
  const _TestRouterShell();
  @override
  State<_TestRouterShell> createState() => _TestRouterShellState();
}

class _TestRouterShellState extends State<_TestRouterShell> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: HomePremiumStrip()),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const Scaffold(body: Text('PAYWALL')),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}

Widget _pump({
  required Override premiumOverride,
  required _RecordingAnalytics analytics,
}) {
  return ProviderScope(
    overrides: [
      premiumOverride,
      analyticsProvider.overrideWithValue(analytics),
    ],
    child: const _TestRouterShell(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('premium user renders nothing', (tester) async {
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: true, billingIssueAt: null),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Try Sakina Premium →'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('free user renders the strip and its copy', (tester) async {
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: false, billingIssueAt: null),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Try Sakina Premium →'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets(
      'tap fires home_premium_strip_tapped and navigates to /paywall',
      (tester) async {
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: false, billingIssueAt: null),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Try Sakina Premium →'));
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.homePremiumStripTapped),
    );
    expect(find.text('PAYWALL'), findsOneWidget);
  });
}
