import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/paywall/widgets/paywall_gate_page.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Records every tracked event so placement-tagged paywall instrumentation
/// (Phase 2: paywall→purchase funnel) can be asserted without a live Mixpanel.
class RecordingAnalyticsService extends AnalyticsService {
  final List<({String event, Map<String, dynamic> props})> events = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    events.add((event: event, props: properties ?? const {}));
  }

  @override
  void timeEvent(String event) {}

  Iterable<({String event, Map<String, dynamic> props})> withName(
    String name,
  ) =>
      events.where((e) => e.event == name);

  ({String event, Map<String, dynamic> props})? firstOrNull(String name) {
    final matches = withName(name);
    return matches.isEmpty ? null : matches.first;
  }
}

class FakePurchaseService extends PurchaseService {
  FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];
  Object? offeringsError;
  CustomerInfo? purchaseResult;
  Object? purchaseError;
  CustomerInfo? restoreResult;
  Object? restoreError;

  @override
  Future<List<Package>> getOfferings() async {
    if (offeringsError != null) throw offeringsError!;
    return offerings;
  }

  @override
  Future<bool> purchaseSubscription(Package package) async {
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult!.entitlements.active.containsKey('premium');
  }

  @override
  Future<CustomerInfo> purchaseConsumable(Package package) async {
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult ?? buildCustomerInfo(premiumActive: false);
  }

  @override
  Future<bool> restorePurchases() async {
    if (restoreError != null) throw restoreError!;
    return restoreResult!.entitlements.active.containsKey('premium');
  }

  @override
  Future<bool> isPremium() async {
    return purchaseResult?.entitlements.active.containsKey('premium') ?? false;
  }

  /// Per-product intro-offer eligibility. `null` leaves the real code path's
  /// own fallback in place (an empty map, which on the test platform resolves
  /// to eligible); set it to drive the previously-trialed user.
  Map<String, IntroEligibilityStatus>? introEligibility;

  @override
  Future<Map<String, IntroEligibilityStatus>> getIntroEligibility(
    List<String> productIds,
  ) async {
    return introEligibility ?? const {};
  }
}

class FakeOnboardingNotifier extends OnboardingNotifier {
  FakeOnboardingNotifier() : super();

  @override
  Future<void> completeOnboarding(AppSessionNotifier appSession) async {
    await appSession.markOnboarded();
  }
}

CustomerInfo buildCustomerInfo({
  required bool premiumActive,
  String productId = 'sakina_sub_annual',
}) {
  final entitlement = EntitlementInfo(
    'premium',
    premiumActive,
    premiumActive,
    '2026-04-13T12:00:00.000Z',
    '2026-04-13T12:00:00.000Z',
    productId,
    false,
    expirationDate:
        premiumActive ? '2026-05-13T12:00:00.000Z' : '2026-04-12T12:00:00.000Z',
  );

  return CustomerInfo(
    EntitlementInfos(
      {'premium': entitlement},
      premiumActive ? {'premium': entitlement} : const {},
    ),
    {productId: '2026-04-13T12:00:00.000Z'},
    premiumActive ? [productId] : const [],
    [productId],
    const [],
    '2026-04-13T12:00:00.000Z',
    'user-1',
    {
      productId: premiumActive
          ? '2026-05-13T12:00:00.000Z'
          : '2026-04-12T12:00:00.000Z',
    },
    '2026-04-13T12:00:00.000Z',
  );
}

StoreProduct buildStoreProduct(String productId, {bool withTrial = true}) {
  return StoreProduct(
    productId,
    'Test description',
    'Test title',
    4.99,
    '\$4.99',
    'USD',
    introductoryPrice: withTrial
        ? const IntroductoryPrice(0, 'Free', 'P3D', 1, PeriodUnit.day, 3)
        : null,
  );
}

Package buildPackage({
  required PackageType type,
  required String productId,
}) {
  return Package(
    type.name,
    type,
    buildStoreProduct(productId),
    const PresentedOfferingContext('default', null, null),
  );
}

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

  late FakeSupabaseSyncService fakeSync;
  late FakePurchaseService purchaseService;
  late FakeOnboardingNotifier onboardingNotifier;
  late AppSessionNotifier appSession;
  late RecordingAnalyticsService analytics;

  Widget buildSubject({
    required PaywallPlacement placement,
    bool hardGate = false,
    bool inOnboardingFlow = true,
  }) {
    return ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        onboardingProvider.overrideWith((ref) => onboardingNotifier),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        home: PaywallScreen(
          placement: placement,
          hardGate: hardGate,
          inOnboardingFlow: inOnboardingFlow,
          onComplete: () {},
        ),
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    purchaseService = FakePurchaseService();
    onboardingNotifier = FakeOnboardingNotifier();
    analytics = RecordingAnalyticsService();
    debugDisablePaywallAnimations = true;
    appSession = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: const Stream<AuthState>.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );

    PurchaseService.debugSetOverride(purchaseService);
    debugSetPremiumGrantPurchaseService(purchaseService);

    purchaseService.offerings = [
      buildPackage(type: PackageType.annual, productId: 'sakina_sub_annual'),
      buildPackage(type: PackageType.weekly, productId: 'sakina_sub_weekly'),
    ];
    purchaseService.purchaseResult = buildCustomerInfo(premiumActive: true);
    purchaseService.restoreResult = buildCustomerInfo(premiumActive: true);
  });

  tearDown(() {
    appSession.dispose();
    debugResetPremiumGrantService();
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
    debugDisablePaywallAnimations = false;
  });

  testWidgets('initState emits paywall_viewed with placement + hard_gate',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.hardWall, hardGate: true,
          inOnboardingFlow: false),
    );
    await tester.pumpAndSettle();

    final viewed = analytics.firstOrNull(AnalyticsEvents.paywallViewed);
    expect(viewed, isNotNull);
    expect(viewed!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementHardWall);
    expect(viewed.props['hard_gate'], true);
  });

  testWidgets('paywall_viewed fires exactly once for the onboarding surface',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.onboarding),
    );
    await tester.pumpAndSettle();

    expect(
      analytics.withName(AnalyticsEvents.paywallViewed).length,
      1,
    );
    expect(
      analytics
          .firstOrNull(AnalyticsEvents.paywallViewed)!
          .props[AnalyticsEvents.propPlacement],
      AnalyticsEvents.placementOnboarding,
    );
  });

  testWidgets(
      'CTA tap emits cta_tapped + sheet_presented + trial_started, all tagged',
      (tester) async {
    // Uses the onboarding placement so the success path shows the dismissable
    // premium-reveal overlay (the only success UI with a clean teardown). The
    // placement tagging under test is independent of inOnboardingFlow. Keeps the
    // setUp's debugDisablePaywallAnimations=true (so the screen's perpetual
    // shimmer doesn't hang pumpAndSettle) and dismisses the reveal exactly like
    // paywall_screen_test.dart::dismissPremiumReveal.
    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.onboarding),
    );
    await tester.pumpAndSettle();

    // The onboarding placement is the 3-page ceremony; the CTA lives on the
    // last page. Walk there first.
    for (var i = 0; i < 2; i++) {
      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
      );
      await tester.pumpAndSettle();
    }

    await tapVisible(tester, find.text('Start my 3 days free'));
    await tester.pump();
    await tester.pump();
    // Drive + dismiss the premium-reveal overlay so no animation Timer is left
    // pending at teardown.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Begin'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final cta = analytics.firstOrNull(AnalyticsEvents.paywallCtaTapped);
    expect(cta, isNotNull);
    expect(cta!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementOnboarding);

    final presented =
        analytics.firstOrNull(AnalyticsEvents.purchaseSheetPresented);
    expect(presented, isNotNull);
    expect(presented!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementOnboarding);
    expect(presented.props['plan'], 'annual');

    final trial = analytics.firstOrNull(AnalyticsEvents.trialStarted);
    expect(trial, isNotNull);
    expect(trial!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementOnboarding);
    expect(trial.props['hard_gate'], false);
  });

  testWidgets(
      'a trial-INELIGIBLE user who pays immediately is NOT recorded as a '
      'trial start', (tester) async {
    // Apple grants one intro offer per Apple ID per subscription group, ever.
    // A previously-trialed user is correctly shown "Subscribe" and is charged
    // the moment they tap — no trial exists. Emitting `trial_started` anyway
    // inflates trial-start rate, deflates trial-to-paid conversion, and
    // mis-attributes the exit offer: precisely the measurements the W5 keep
    // decision runs on.
    purchaseService.introEligibility = {
      'sakina_sub_annual':
          IntroEligibilityStatus.introEligibilityStatusIneligible,
      'sakina_sub_weekly':
          IntroEligibilityStatus.introEligibilityStatusIneligible,
    };

    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.softInApp, inOnboardingFlow: false),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCtaSubscribe));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(analytics.firstOrNull(AnalyticsEvents.trialStarted), isNull,
        reason: 'no trial was granted, so no trial started');

    // The conversion itself must still be counted — the fix is to record it
    // truthfully, not to drop it.
    final paid =
        analytics.firstOrNull(AnalyticsEvents.subscriptionStartedNoTrial);
    expect(paid, isNotNull);
    expect(paid!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementSoftInApp);
  });

  testWidgets('an ELIGIBLE user still emits trial_started, not the paid event',
      (tester) async {
    purchaseService.introEligibility = {
      'sakina_sub_annual':
          IntroEligibilityStatus.introEligibilityStatusEligible,
      'sakina_sub_weekly':
          IntroEligibilityStatus.introEligibilityStatusEligible,
    };

    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.softInApp, inOnboardingFlow: false),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Start my 3 days free'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(analytics.firstOrNull(AnalyticsEvents.trialStarted), isNotNull);
    expect(analytics.firstOrNull(AnalyticsEvents.subscriptionStartedNoTrial),
        isNull);
  });

  testWidgets('user cancel emits purchase_sheet_cancelled with placement',
      (tester) async {
    purchaseService.purchaseError = PlatformException(
      code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
      message: 'cancelled',
    );

    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.softInApp),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Start my 3 days free'));
    await tester.pumpAndSettle();

    final cancelled =
        analytics.firstOrNull(AnalyticsEvents.purchaseSheetCancelled);
    expect(cancelled, isNotNull);
    expect(cancelled!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementSoftInApp);
    // Cancel must NOT be counted as a conversion.
    expect(analytics.firstOrNull(AnalyticsEvents.trialStarted), isNull);
  });

  testWidgets('non-cancel failure emits purchase_sheet_failed with reason',
      (tester) async {
    purchaseService.purchaseError = PlatformException(
      code: PurchasesErrorCode.storeProblemError.index.toString(),
      message: 'boom',
    );

    await tester.pumpWidget(
      buildSubject(placement: PaywallPlacement.softInApp),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Start my 3 days free'));
    await tester.pumpAndSettle();

    final failed = analytics.firstOrNull(AnalyticsEvents.purchaseSheetFailed);
    expect(failed, isNotNull);
    expect(failed!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementSoftInApp);
    expect(failed.props['reason'], isNotNull);
    expect(analytics.firstOrNull(AnalyticsEvents.trialStarted), isNull);
  });

  // --- The post-onboarding soft gate ---------------------------------------
  //
  // These three tests were arm-parameterized until the reverse-trial close-out
  // (W5 Wave A, 2026-08-01): they pinned `post_trial_soft` +
  // `treatment_reverse_trial` for a lapsed treatment trialer against
  // `post_tour_soft` + `control_no_trial` for control. Both inputs are gone —
  // the session's placement and arm are frozen constants — so what is left to
  // pin is that the ONE surviving surface still tags itself correctly.

  AppSessionNotifier softGateSession() {
    return AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: const Stream<AuthState>.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      isPremiumReader: () async => false,
    );
  }

  Widget buildSoftSubject(AppSessionNotifier session) {
    return ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(session),
        onboardingProvider.overrideWith((ref) => onboardingNotifier),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        // The router resolves the placement off the session — mirror that here.
        home: PaywallScreen(
          placement: session.softPaywallPlacement,
          hardGate: false,
          inOnboardingFlow: false,
          onComplete: () {},
        ),
      ),
    );
  }

  testWidgets(
      'the soft gate is post_tour_soft{unassigned}, and surfaces no post-trial gate',
      (tester) async {
    final session = softGateSession();
    await session.hydrateOnboardingGate();
    addTearDown(session.dispose);

    await tester.pumpWidget(buildSoftSubject(session));
    await tester.pumpAndSettle();

    expect(analytics.firstOrNull(AnalyticsEvents.trialPaywallSurfaced), isNull,
        reason: 'trial_paywall_surfaced was the app-granted Day-3 gate; retired '
            'with the reverse trial, and nothing can reach post_trial_soft');
    final viewed = analytics.firstOrNull(AnalyticsEvents.paywallViewed);
    expect(viewed, isNotNull);
    expect(viewed!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementPostTourSoft);
  });

  testWidgets('dismiss (X) of the soft gate → soft_gate_dismissed{placement,arm}',
      (tester) async {
    final session = softGateSession();
    await session.hydrateOnboardingGate();
    addTearDown(session.dispose);

    await tester.pumpWidget(buildSoftSubject(session));
    await tester.pumpAndSettle();
    // Select Weekly so the annual→weekly exit-offer sheet is NOT eligible and
    // the ✕ goes straight to _doClose (the dismiss path under test). The
    // weekly plan is a de-emphasized text row now, not a peer card.
    //
    // The ✕ itself is tappable from frame zero — the 3-second reveal delay was
    // deleted with W5 Wave C, so there is no timer to pump past.
    await tapVisible(tester, find.textContaining('Weekly \u2014'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pump();

    final dismissed = analytics.firstOrNull(AnalyticsEvents.softGateDismissed);
    expect(dismissed, isNotNull,
        reason: 'dismissing the soft gate emits soft_gate_dismissed');
    expect(dismissed!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementPostTourSoft);
    expect(dismissed.props[AnalyticsEvents.propArm],
        AnalyticsEvents.armUnassigned);
  });

  testWidgets('safety valve emits paywall_safety_valve_used with placement',
      (tester) async {
    purchaseService.offeringsError = StateError('boom');

    await tester.pumpWidget(
      buildSubject(
        placement: PaywallPlacement.hardWall,
        hardGate: true,
        inOnboardingFlow: false,
      ),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Continue'));
    await tester.pump();

    final valve = analytics.firstOrNull(AnalyticsEvents.paywallSafetyValveUsed);
    expect(valve, isNotNull);
    expect(valve!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementHardWall);
  });
}
