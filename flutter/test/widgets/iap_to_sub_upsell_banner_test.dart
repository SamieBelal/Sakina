import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/achievement_toast.dart' show rootNavigatorKey;
import 'package:sakina/widgets/iap_to_sub_upsell_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

Widget _wrap({
  required ProviderContainer container,
  required Widget child,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
      GoRoute(
        path: '/paywall',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('PAYWALL'))),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;
  late _TrackingSpy analytics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
    GatingService.debugSetOverride(gating);
    analytics = _TrackingSpy();
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.debugClearOverride();
    GatingService.debugNowUtc = null;
  });

  group('IapToSubUpsellBanner', () {
    testWidgets('renders nothing when ineligible (clean install)',
        (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => IapToSubBannerState.hidden,
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      expect(find.byType(IapToSubUpsellBanner), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsNothing,
          reason: 'Hidden state must collapse to SizedBox.shrink');
    });

    testWidgets('renders count-based headline and weekly price when eligible',
        (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 10,
            weeklyPriceString: r'$9.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      expect(find.text("You've used 10 bypasses"), findsOneWidget);
      expect(
        find.textContaining(r'Weekly sub at $9.99 unlocks unlimited'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('drops the price entirely when RC returns no price',
        (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 6,
            weeklyPriceString: null,
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      expect(find.text("You've used 6 bypasses"), findsOneWidget);
      expect(
        find.text(
            'Weekly sub unlocks unlimited reflections, duas, and discoveries.'),
        findsOneWidget,
        reason: 'No price in the copy when RC fallback fires — better than '
            'showing a hardcoded figure that drifts from the real product '
            r'pricing (e.g. $9.99 vs the actual $4.99 weekly).',
      );
      expect(
        find.textContaining(r'$9.99'),
        findsNothing,
        reason: r'The old hardcoded $9.99 fallback must NOT appear — that '
            'figure drifted from the real RC weekly price.',
      );
    });

    testWidgets('banner tap fires iap_to_sub_banner_tapped + paywall_viewed '
        'with trigger, then routes to /paywall', (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 6,
            weeklyPriceString: r'$9.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Filter out the P0-5 shown event (fires once on first visible render)
      // so the tap-flow assertion remains focused on tap + paywall_viewed.
      final tapFlow = analytics.tracked
          .where((e) => e.$1 != AnalyticsEvents.iapToSubBannerShown)
          .toList();
      expect(tapFlow.length, 2);
      expect(tapFlow[0].$1, AnalyticsEvents.iapToSubBannerTapped);
      expect(tapFlow[1].$1, AnalyticsEvents.paywallViewed);
      expect(tapFlow[1].$2, {
        'trigger': AnalyticsEvents.paywallTriggerIapToSubUpsell,
      });

      expect(find.text('PAYWALL'), findsOneWidget,
          reason: 'Banner tap must route to /paywall');
    });

    testWidgets('P2-2: banner headline shows bypass count, not dollar figure',
        (tester) async {
      // 2026-05-25: the fabricated "$X spent" headline (computed as
      // lifetimeBypasses * $0.50) was replaced with a count-based one to
      // close an Apple 3.1.1 / FTC endorsement risk. See
      // docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md.
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 6,
            weeklyPriceString: r'$4.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      expect(find.text("You've used 6 bypasses"), findsOneWidget);
      // The synthesized "$X on bypasses" copy must be gone — its presence
      // would reintroduce the FTC risk.
      expect(
        find.textContaining("You've spent"),
        findsNothing,
        reason: 'Fabricated dollar headline must not render anywhere',
      );
      expect(
        find.textContaining(r'$3 on bypasses'),
        findsNothing,
        reason: r'Old "6 × $0.50 = $3" headline must not render',
      );
    });

    testWidgets('P2-2: banner headline pluralization at count=1',
        (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 1,
            weeklyPriceString: r'$4.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      expect(find.text("You've used 1 bypass"), findsOneWidget,
          reason: 'Singular noun at count=1');
      expect(find.text("You've used 1 bypasses"), findsNothing,
          reason: 'Plural form must not render at count=1');
    });

    testWidgets('P2-2: banner does not render at count=0', (tester) async {
      // REVIEW Finding 2 (2026-05-25): the widget now has a defense-in-depth
      // gate that returns SizedBox.shrink() when lifetimeBypassesPurchased
      // < 1, even if state.visible=true. Production's
      // iap_to_sub_banner_eligible RPC already requires count >= 6 to flip
      // visible=true, so this is purely defensive against a future
      // server-side refactor that loosens that threshold.
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 0,
            weeklyPriceString: r'$4.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      // Headline must NOT render at count=0.
      expect(find.text("You've used 0 bypasses"), findsNothing,
          reason: 'Widget-level gate should suppress headline at count=0');
    });

    testWidgets('P2-4: analytics fires only after server confirms dismissal',
        (tester) async {
      // 2026-05-25: previously the dismissed event fired BEFORE the RPC
      // await; on RPC failure (network / auth / server) the funnel saw a
      // success event with no actual dismissal. New order: await RPC, then
      // emit success-or-failed event.
      await gating.hydrateFromProfile({
        'created_at': '2026-05-10T12:00:00Z',
        'lifetime_bypasses_purchased': 6,
      });
      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] = (_) async => {
            'ok': true,
            'dismissed_at': '2026-05-25T12:00:00Z',
          };

      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 6,
            weeklyPriceString: r'$4.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Pin event ordering against the RPC call so a future regression that
      // re-fires the event BEFORE the await would be caught by this test
      // (analytics.tracked recorded before fakeSync.rpcCalls would prove
      // the bug). We assert by checking both fired AND that the RPC was
      // called.
      final dismissedFired = analytics.tracked.any(
        (e) => e.$1 == AnalyticsEvents.iapToSubBannerDismissed,
      );
      expect(dismissedFired, isTrue,
          reason: 'Dismissed event must fire when server returns ok==true');
      expect(
        analytics.tracked
            .any((e) => e.$1 == AnalyticsEvents.iapToSubBannerDismissFailed),
        isFalse,
        reason: 'Failed event must NOT fire on successful dismiss',
      );
      expect(fakeSync.rpcCalls.last['fn'], 'dismiss_iap_upsell_banner');
    });

    testWidgets('P2-4: failed-dismiss fires the paired event instead',
        (tester) async {
      // Server returns ok==false (e.g. auth failed, network glitch, RPC
      // rejection). The dismissed event must NOT fire — that would bias the
      // funnel. The paired iapToSubBannerDismissFailed event must fire so
      // the dashboard can model retry behavior.
      await gating.hydrateFromProfile({
        'created_at': '2026-05-10T12:00:00Z',
        'lifetime_bypasses_purchased': 6,
      });
      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] = (_) async => {
            'ok': false,
          };

      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 6,
            weeklyPriceString: r'$4.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        analytics.tracked
            .any((e) => e.$1 == AnalyticsEvents.iapToSubBannerDismissed),
        isFalse,
        reason: 'Dismissed event must NOT fire when server returns ok==false',
      );
      expect(
        analytics.tracked
            .any((e) => e.$1 == AnalyticsEvents.iapToSubBannerDismissFailed),
        isTrue,
        reason: 'Paired failed event must fire when RPC fails',
      );
      expect(fakeSync.rpcCalls.last['fn'], 'dismiss_iap_upsell_banner');
    });

    testWidgets('close-icon tap fires iap_to_sub_banner_dismissed + RPC',
        (tester) async {
      // Prime the gating service so dismissIapToSubBanner reaches the RPC.
      await gating.hydrateFromProfile({
        'created_at': '2026-05-10T12:00:00Z',
        'lifetime_bypasses_purchased': 6,
      });
      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] = (_) async => {
            'ok': true,
            'dismissed_at': '2026-05-25T12:00:00Z',
          };

      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 6,
            weeklyPriceString: r'$9.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(analytics.tracked.any(
        (e) => e.$1 == AnalyticsEvents.iapToSubBannerDismissed,
      ), isTrue);
      expect(fakeSync.rpcCalls.last['fn'], 'dismiss_iap_upsell_banner');
    });
  });

  group('IapToSubUpsellBanner — route hiding (PR 5 review fix)', () {
    // The banner mounts at MaterialApp.builder level (above the Navigator).
    // It listens to GoRouter via the global `rootNavigatorKey` to hide on
    // routes where the banner would be redundant or annoying — see
    // `hiddenBannerRoutes` for the list. These tests use the production
    // mount pattern (builder + rootNavigatorKey) to verify the gate.
    Widget productionWrap({
      required ProviderContainer container,
      required String initialLocation,
    }) {
      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('HOME'))),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('PAYWALL'))),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('ONBOARDING'))),
          ),
          GoRoute(
            path: '/welcome',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('WELCOME'))),
          ),
          GoRoute(
            path: '/signin',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('SIGNIN'))),
          ),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          // Match production: banner mounted in builder, above the
          // Navigator. This is the only place rootNavigatorKey is the
          // GoRouter's navigatorKey (vs. inside-a-route mounting which
          // tests above use).
          builder: (context, child) => Column(
            children: [
              const IapToSubUpsellBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    ProviderContainer eligibleContainer() => ProviderContainer(overrides: [
          analyticsProvider.overrideWithValue(analytics),
          iapToSubBannerStateProvider.overrideWith(
            (ref) async => const IapToSubBannerState(
              visible: true,
              lifetimeBypassesPurchased: 6,
              weeklyPriceString: r'$4.99',
            ),
          ),
        ]);

    testWidgets('hiddenBannerRoutes contains the 4 expected routes',
        (tester) async {
      // Pin the contract so future contributors don't silently drop one.
      expect(
        hiddenBannerRoutes,
        equals({'/paywall', '/onboarding', '/welcome', '/signin'}),
      );
    });

    testWidgets('renders on / (home) when eligible', (tester) async {
      final container = eligibleContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        productionWrap(container: container, initialLocation: '/'),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.workspace_premium), findsOneWidget,
          reason: 'Banner must render on the home route');
      expect(find.text('HOME'), findsOneWidget);
    });

    for (final hiddenRoute in const ['/paywall', '/onboarding', '/welcome', '/signin']) {
      testWidgets('hides on $hiddenRoute even when eligible', (tester) async {
        final container = eligibleContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          productionWrap(container: container, initialLocation: hiddenRoute),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.workspace_premium), findsNothing,
            reason: 'Banner must NOT render on $hiddenRoute');
      });
    }

    testWidgets('hides after dynamic navigation from / to /paywall',
        (tester) async {
      // Pin the reactive listener — banner must react to route changes,
      // not just initial mount. The reverse (pop → re-appear) is covered
      // by the simulator verification screenshots in the PR description.
      final container = eligibleContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        productionWrap(container: container, initialLocation: '/'),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);

      await tester.tap(find.byIcon(Icons.workspace_premium));
      await tester.pumpAndSettle();
      expect(find.text('PAYWALL'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsNothing,
          reason: 'Banner must vanish on /paywall destination');
    });
  });

  group('IapToSubUpsellBanner — shown event (P0-5)', () {
    testWidgets(
        'REGRESSION P0-5: iap_to_sub_banner_shown fires once when banner becomes visible',
        (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => const IapToSubBannerState(
            visible: true,
            lifetimeBypassesPurchased: 8,
            weeklyPriceString: r'$4.99',
          ),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();

      final shownCalls = analytics.tracked
          .where((e) => e.$1 == AnalyticsEvents.iapToSubBannerShown)
          .toList();
      expect(shownCalls.length, 1,
          reason: 'should fire exactly once on first visible render');
      expect(shownCalls.single.$2?['lifetime_bypasses_purchased'], 8,
          reason: 'event includes the lifetime count for funnel segmentation');

      await tester.pump();
      await tester.pump();
      expect(
        analytics.tracked
            .where((e) => e.$1 == AnalyticsEvents.iapToSubBannerShown)
            .length,
        1,
        reason: 'sticky guard prevents re-fire on rebuild',
      );
    });

    testWidgets(
        'REGRESSION P0-5: iap_to_sub_banner_shown does NOT fire when banner is hidden',
        (tester) async {
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(analytics),
        iapToSubBannerStateProvider.overrideWith(
          (ref) async => IapToSubBannerState.hidden,
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrap(container: container, child: const IapToSubUpsellBanner()),
      );
      await tester.pump();
      await tester.pump();

      expect(
        analytics.tracked
            .any((e) => e.$1 == AnalyticsEvents.iapToSubBannerShown),
        isFalse,
      );
    });

    // Structural test — catches the next event-without-producer.
    test('iapToSubBannerShown has at least one producer in lib/', () async {
      final dir = Directory('lib/');
      final hits = <String>[];
      await for (final f in dir.list(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          final content = await f.readAsString();
          if (content.contains('AnalyticsEvents.iapToSubBannerShown')) {
            hits.add(f.path);
          }
        }
      }
      expect(hits, isNotEmpty,
          reason: 'event must have a producer (P0-5 regression pin)');
    });
  });
}
