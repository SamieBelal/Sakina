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
    required String placement,
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
      buildSubject(placement: AnalyticsEvents.placementHardWall, hardGate: true,
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
      buildSubject(placement: AnalyticsEvents.placementOnboarding),
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
      buildSubject(placement: AnalyticsEvents.placementOnboarding),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCtaTrial));
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

  testWidgets('user cancel emits purchase_sheet_cancelled with placement',
      (tester) async {
    purchaseService.purchaseError = PlatformException(
      code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
      message: 'cancelled',
    );

    await tester.pumpWidget(
      buildSubject(placement: AnalyticsEvents.placementSoftInApp),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCtaTrial));
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
      buildSubject(placement: AnalyticsEvents.placementSoftInApp),
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCtaTrial));
    await tester.pumpAndSettle();

    final failed = analytics.firstOrNull(AnalyticsEvents.purchaseSheetFailed);
    expect(failed, isNotNull);
    expect(failed!.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementSoftInApp);
    expect(failed.props['reason'], isNotNull);
    expect(analytics.firstOrNull(AnalyticsEvents.trialStarted), isNull);
  });

  testWidgets('safety valve emits paywall_safety_valve_used with placement',
      (tester) async {
    purchaseService.offeringsError = StateError('boom');

    await tester.pumpWidget(
      buildSubject(
        placement: AnalyticsEvents.placementHardWall,
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
