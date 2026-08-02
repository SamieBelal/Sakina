import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/paywall/widgets/paywall_exit_offer_sheet.dart';
import 'package:sakina/features/paywall/widgets/paywall_gate_page.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// The ✕-interception weekly downsell, and the instrumentation that has to
/// answer "does it earn anything".
///
/// `shown` and `accepted` alone cannot: accepted means the CTA was tapped, not
/// that money moved, and without `declined` you cannot tell "nobody saw it"
/// from "everybody saw it and refused". So these tests pin the whole funnel —
/// shown → accepted → purchase started → purchase completed — and pin that a
/// decline fires on **every** route out of the sheet.
class _RecordedEvent {
  _RecordedEvent(this.name, this.props);
  final String name;
  final Map<String, Object?> props;
}

class _RecordingAnalytics extends AnalyticsService {
  final List<_RecordedEvent> events = [];

  @override
  Future<void> track(String name, {Map<String, Object?>? properties}) async {
    events.add(_RecordedEvent(name, properties ?? const {}));
  }

  List<_RecordedEvent> all(String name) =>
      events.where((e) => e.name == name).toList();

  _RecordedEvent? first(String name) =>
      events.where((e) => e.name == name).firstOrNull;

  int count(String name) => all(name).length;
}

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];
  Map<String, IntroEligibilityStatus> eligibility = const {};
  PackageType? lastPurchasedPackageType;
  bool purchaseSucceeds = true;

  @override
  Future<List<Package>> getOfferings() async => offerings;

  @override
  Future<Map<String, IntroEligibilityStatus>> getIntroEligibility(
    List<String> productIds,
  ) async =>
      eligibility;

  @override
  Future<bool> purchaseSubscription(Package package) async {
    lastPurchasedPackageType = package.packageType;
    return purchaseSucceeds;
  }

  @override
  Future<bool> isPremium() async => false;
}

const _annualId = 'sakina_sub_annual';
const _weeklyId = 'sakina_sub_weekly';

Package _package({
  required PackageType type,
  required String productId,
  required String priceString,
  required double price,
}) =>
    Package(
      type.name,
      type,
      StoreProduct(
        productId,
        'desc',
        'title',
        price,
        priceString,
        'USD',
        introductoryPrice: const IntroductoryPrice(
          0,
          'Free',
          'P7D',
          1,
          PeriodUnit.day,
          7,
        ),
      ),
      const PresentedOfferingContext('default', null, null),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
      );
    }
  });

  late _FakePurchaseService purchaseService;
  late _RecordingAnalytics analytics;
  late AppSessionNotifier appSession;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-1'),
    );
    analytics = _RecordingAnalytics();
    purchaseService = _FakePurchaseService()
      ..offerings = [
        _package(
          type: PackageType.annual,
          productId: _annualId,
          priceString: '\$49.99',
          price: 49.99,
        ),
        _package(
          type: PackageType.weekly,
          productId: _weeklyId,
          priceString: '\$4.99',
          price: 4.99,
        ),
      ]
      ..eligibility = const {
        _annualId: IntroEligibilityStatus.introEligibilityStatusEligible,
        _weeklyId: IntroEligibilityStatus.introEligibilityStatusEligible,
      };
    PurchaseService.debugSetOverride(purchaseService);
    debugSetPremiumGrantPurchaseService(purchaseService);
    debugDisablePaywallAnimations = true;
    appSession = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: const Stream<AuthState>.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );
    container = ProviderContainer(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    appSession.dispose();
    debugResetPremiumGrantService();
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
    debugDisablePaywallAnimations = false;
  });

  var mountCount = 0;

  Future<void> pumpGate(
    WidgetTester tester, {
    PaywallPlacement placement = PaywallPlacement.softInApp,
    VoidCallback? onComplete,
  }) async {
    // A unique key per mount. Without it a re-pump at the same tree position
    // reuses the State — and with it the once-per-session exit-offer latch —
    // so a test that mounts twice would silently test nothing the second time.
    final key = ValueKey('paywall-${mountCount++}');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PaywallScreen(
            key: key,
            placement: placement,
            onComplete: onComplete ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Advance through the purchase + the PremiumCelebrationOverlay's scripted
  /// reveal and dismiss it. Fixed pumps, not `pumpAndSettle`: the overlay has
  /// continuous shimmer animations that never settle.
  Future<void> settlePurchase(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));
    if (find.text('Begin').evaluate().isNotEmpty) {
      await tester.tap(find.text('Begin'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> tapClose(WidgetTester tester) async {
    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();
  }

  group('shown', () {
    testWidgets('✕ with annual selected opens the sheet and emits shown',
        (tester) async {
      await pumpGate(tester);
      await tapClose(tester);

      expect(find.byType(PaywallExitOfferSheet), findsOneWidget);
      final shown = analytics.first(AnalyticsEvents.paywallExitOfferShown);
      expect(shown, isNotNull);
      expect(shown!.props[AnalyticsEvents.propPlacement],
          AnalyticsEvents.placementSoftInApp);
    });

    testWidgets('the duration in the sheet is store-derived, not a constant',
        (tester) async {
      await pumpGate(tester);
      await tapClose(tester);

      // The fixture package carries P7D, so the sheet must say 7 — the old
      // hardcoded "3-day free trial" copy is now a {trial} template.
      expect(
        find.textContaining('weekly plan and your 7-day free trial'),
        findsOneWidget,
      );
      expect(find.text('Start 7-day free trial'), findsOneWidget);
      expect(find.textContaining('3-day'), findsNothing);
      expect(find.textContaining('3 days'), findsNothing);
    });

    testWidgets('an ineligible user gets no trial promise in the sheet either',
        (tester) async {
      purchaseService.eligibility = const {
        _annualId: IntroEligibilityStatus.introEligibilityStatusIneligible,
        _weeklyId: IntroEligibilityStatus.introEligibilityStatusIneligible,
      };
      await pumpGate(tester);
      await tapClose(tester);

      expect(find.byType(PaywallExitOfferSheet), findsOneWidget);
      expect(find.text('Try weekly'), findsOneWidget);
      expect(find.textContaining('free trial'), findsNothing);
      expect(find.textContaining('7 days'), findsNothing);
    });

    testWidgets('it is shown at most once per session — no second nag',
        (tester) async {
      await pumpGate(tester);
      await tapClose(tester);
      // Decline it.
      await tester.tap(find.text(AppStrings.paywallExitOfferDecline));
      await tester.pumpAndSettle();

      expect(analytics.count(AnalyticsEvents.paywallExitOfferShown), 1);
      // The always-free card is now up; the gate is behind it. The offer is
      // spent for the session either way.
      expect(find.byType(PaywallExitOfferSheet), findsNothing);
    });

    testWidgets('it does NOT fire on a ceremony page with no prices on screen',
        (tester) async {
      // Pre-W5 the ✕ only ever existed on a screen showing the plan cards, so
      // a weekly downsell always answered a price the user had just seen.
      // Firing it on value_depth would put the offer somewhere it has never
      // been.
      await pumpGate(tester, placement: PaywallPlacement.onboarding);
      expect(find.text(AppStrings.paywallValueDepthSubline), findsOneWidget);

      await tapClose(tester);

      expect(find.byType(PaywallExitOfferSheet), findsNothing);
      expect(analytics.count(AnalyticsEvents.paywallExitOfferShown), 0);
      expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    });

    testWidgets('it DOES fire from the ceremony plan page', (tester) async {
      await pumpGate(tester, placement: PaywallPlacement.onboarding);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.widgetWithText(
            ElevatedButton, AppStrings.paywallGateContinue));
        await tester.pumpAndSettle();
      }
      expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);

      await tapClose(tester);

      expect(find.byType(PaywallExitOfferSheet), findsOneWidget);
      expect(
        analytics
            .first(AnalyticsEvents.paywallExitOfferShown)!
            .props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementOnboarding,
      );
    });
  });

  group('declined — every route out of the sheet', () {
    testWidgets('the "No thanks" button', (tester) async {
      await pumpGate(tester);
      await tapClose(tester);
      await tester.tap(find.text(AppStrings.paywallExitOfferDecline));
      await tester.pumpAndSettle();

      final declined =
          analytics.first(AnalyticsEvents.paywallExitOfferDeclined);
      expect(declined, isNotNull);
      expect(declined!.props[AnalyticsEvents.propDismissRoute],
          AnalyticsEvents.dismissRouteButton);
      expect(declined.props[AnalyticsEvents.propPlacement],
          AnalyticsEvents.placementSoftInApp);
      // An explicit decline continues the dismissal the ✕ started.
      expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    });

    testWidgets('a scrim tap', (tester) async {
      await pumpGate(tester);
      await tapClose(tester);

      // Tap the barrier well above the sheet.
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      final declined =
          analytics.first(AnalyticsEvents.paywallExitOfferDeclined);
      expect(declined, isNotNull, reason: 'a scrim tap is still a decline');
      expect(declined!.props[AnalyticsEvents.propDismissRoute],
          AnalyticsEvents.dismissRouteDismissed);
      // Unchanged pre-W5 behaviour: back to the paywall, not out of it.
      expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
      expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsNothing);
    });

    testWidgets('the back gesture', (tester) async {
      await pumpGate(tester);
      await tapClose(tester);

      final NavigatorState nav =
          tester.state(find.byType(Navigator).first);
      nav.maybePop();
      await tester.pumpAndSettle();

      final declined =
          analytics.first(AnalyticsEvents.paywallExitOfferDeclined);
      expect(declined, isNotNull, reason: 'a back gesture is still a decline');
      expect(declined!.props[AnalyticsEvents.propDismissRoute],
          AnalyticsEvents.dismissRouteDismissed);
      expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
    });

    testWidgets('no route out of the sheet is silent', (tester) async {
      // The guard against the failure mode that flatters the mechanic: every
      // non-accept exit must produce exactly one decline event.
      for (final route in ['button', 'scrim', 'back']) {
        analytics.events.clear();
        await pumpGate(tester);
        await tapClose(tester);
        switch (route) {
          case 'button':
            await tester.tap(find.text(AppStrings.paywallExitOfferDecline));
          case 'scrim':
            await tester.tapAt(const Offset(195, 40));
          case 'back':
            (tester.state(find.byType(Navigator).first) as NavigatorState)
                .maybePop();
        }
        await tester.pumpAndSettle();
        expect(
          analytics.count(AnalyticsEvents.paywallExitOfferDeclined),
          1,
          reason: 'exiting via $route must emit exactly one decline',
        );
      }
    });
  });

  group('accepted → the existing purchase chain', () {
    testWidgets('accept emits accepted and buys WEEKLY', (tester) async {
      await pumpGate(tester);
      await tapClose(tester);
      await tester.tap(find.text('Start 7-day free trial'));
      await settlePurchase(tester);

      final accepted =
          analytics.first(AnalyticsEvents.paywallExitOfferAccepted);
      expect(accepted, isNotNull);
      expect(accepted!.props[AnalyticsEvents.propPlacement],
          AnalyticsEvents.placementSoftInApp);
      expect(purchaseService.lastPurchasedPackageType, PackageType.weekly);
    });

    testWidgets('the whole chain is tagged origin=exit_offer, on the EXISTING '
        'events', (tester) async {
      await pumpGate(tester);
      await tapClose(tester);
      await tester.tap(find.text('Start 7-day free trial'));
      await settlePurchase(tester);

      // shown → accepted → purchase started → purchase completed. No parallel
      // purchase event is minted; the origin rides the live funnel so it stays
      // one funnel, segmentable.
      for (final event in [
        AnalyticsEvents.paywallCtaTapped,
        AnalyticsEvents.purchaseSheetPresented,
        AnalyticsEvents.trialStarted,
      ]) {
        final e = analytics.first(event);
        expect(e, isNotNull, reason: '$event must still fire');
        expect(
          e!.props[AnalyticsEvents.propOrigin],
          AnalyticsEvents.originExitOffer,
          reason: '$event must carry the exit-offer origin',
        );
        expect(e.props['plan'], 'weekly');
      }
    });

    testWidgets('an accept that is then abandoned at StoreKit does NOT look '
        'like revenue', (tester) async {
      // The failure this instrumentation exists to make visible: "accepted"
      // only means the CTA was tapped.
      purchaseService.purchaseSucceeds = false;
      await pumpGate(tester);
      await tapClose(tester);
      await tester.tap(find.text('Start 7-day free trial'));
      await settlePurchase(tester);

      expect(analytics.first(AnalyticsEvents.paywallExitOfferAccepted),
          isNotNull);
      expect(analytics.first(AnalyticsEvents.trialStarted), isNull,
          reason: 'no entitlement → no conversion event');
      final failed = analytics.first(AnalyticsEvents.purchaseSheetFailed);
      expect(failed, isNotNull);
      expect(failed!.props[AnalyticsEvents.propOrigin],
          AnalyticsEvents.originExitOffer,
          reason: 'the abandoned attempt is attributable to the exit offer');
    });

    testWidgets('a plain CTA purchase is tagged origin=paywall', (tester) async {
      await pumpGate(tester);
      await tester.tap(find.text('Start my 7 days free'));
      await settlePurchase(tester);

      expect(
        analytics
            .first(AnalyticsEvents.paywallCtaTapped)!
            .props[AnalyticsEvents.propOrigin],
        AnalyticsEvents.originPaywall,
      );
      expect(purchaseService.lastPurchasedPackageType, PackageType.annual);
    });
  });
}
