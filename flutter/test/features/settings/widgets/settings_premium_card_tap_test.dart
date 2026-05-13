import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/settings/widgets/settings_premium_card.dart';
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
        builder: (_, __) => const Scaffold(body: SettingsPremiumCard()),
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

  // `RevenueCatUI.presentCustomerCenter()` falls through to a platform-channel
  // call on the `purchases_ui_flutter` channel. We mock-handle it so the test
  // doesn't actually try to present a native sheet, and we can verify the
  // method WAS invoked (vs. falling through to the snackbar path).
  const customerCenterChannel = MethodChannel('purchases_ui_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerCenterChannel, (call) async {
      if (call.method == 'presentCustomerCenter') return null;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerCenterChannel, null);
  });

  testWidgets(
      'State 1 tap pushes /paywall and fires settings_premium_cta_tapped',
      (tester) async {
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: false, billingIssueAt: null),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sakina Premium'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.settingsPremiumCtaTapped),
    );
    expect(find.text('PAYWALL'), findsOneWidget);
  });

  testWidgets(
      'State 2 tap fires settings_premium_manage_tapped and invokes the '
      'Customer Center', (tester) async {
    final analytics = _RecordingAnalytics();
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerCenterChannel, (call) async {
      calls.add(call.method);
      return null;
    });

    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: true, billingIssueAt: null),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.settingsPremiumManageTapped),
    );
    expect(
      calls,
      contains('presentCustomerCenter'),
      reason: 'expected Customer Center to be invoked: $calls',
    );
  });

  testWidgets(
      'State 3 tap fires settings_premium_billing_issue_tapped and invokes '
      'the Customer Center', (tester) async {
    final analytics = _RecordingAnalytics();
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerCenterChannel, (call) async {
      calls.add(call.method);
      return null;
    });

    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (
          isPremium: true,
          billingIssueAt: '2026-05-13T12:00:00.000Z',
        ),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Payment issue'));
    await tester.pumpAndSettle();

    expect(
      analytics.events,
      contains(AnalyticsEvents.settingsPremiumBillingIssueTapped),
    );
    expect(
      calls,
      contains('presentCustomerCenter'),
      reason: 'expected Customer Center to be invoked: $calls',
    );
  });

  testWidgets(
      'Customer Center failure surfaces the snackbar and does NOT crash',
      (tester) async {
    final analytics = _RecordingAnalytics();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(customerCenterChannel, (call) async {
      if (call.method == 'presentCustomerCenter') {
        throw PlatformException(code: 'ERROR', message: 'broken');
      }
      return null;
    });

    await tester.pumpWidget(_pump(
      premiumOverride: premiumStateProvider.overrideWith(
        (ref) async => (isPremium: true, billingIssueAt: null),
      ),
      analytics: analytics,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not open subscription management'),
      findsOneWidget,
    );
  });
}
