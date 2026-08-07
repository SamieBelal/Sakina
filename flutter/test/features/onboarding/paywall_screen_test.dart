import 'dart:async';

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
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Records every tracked event so the restore-purchases analytics (W6 Wave C
/// #5) can be asserted without a live Mixpanel.
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
}

class FakePurchaseService extends PurchaseService {
  FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];
  Completer<List<Package>>? offeringsGate;
  Object? offeringsError;
  CustomerInfo? purchaseResult;
  Object? purchaseError;
  CustomerInfo? restoreResult;
  Object? restoreError;
  PackageType? lastPurchasedPackageType;

  @override
  Future<List<Package>> getOfferings() async {
    final gate = offeringsGate;
    if (gate != null) return gate.future;
    if (offeringsError != null) throw offeringsError!;
    return offerings;
  }

  @override
  Future<bool> purchaseSubscription(Package package) async {
    lastPurchasedPackageType = package.packageType;
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult!.entitlements.active.containsKey('premium');
  }

  @override
  Future<CustomerInfo> purchaseConsumable(Package package) async {
    // Matches prod's contract: trust RC's throw-on-failure / return-on-success.
    // Returns the seeded `purchaseResult` (or a minimal stand-in) — the
    // paywall screen does not exercise this path, but the override must
    // remain in shape with PurchaseService's signature.
    lastPurchasedPackageType = package.packageType;
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

  int completeCalls = 0;

  @override
  Future<void> completeOnboarding(AppSessionNotifier appSession) async {
    completeCalls += 1;
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

Package buildPackage({
  required PackageType type,
  required String productId,
  double price = 4.99,
  String? priceString,
}) {
  return Package(
    type.name,
    type,
    StoreProduct(
      productId,
      'Test description',
      'Test title',
      price,
      priceString ?? '\$4.99',
      'USD',
      introductoryPrice: const IntroductoryPrice(
        0,
        'Free',
        'P3D',
        1,
        PeriodUnit.day,
        3,
      ),
    ),
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
  late bool completed;
  late RecordingAnalyticsService analytics;

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        onboardingProvider.overrideWith((ref) => onboardingNotifier),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        home: PaywallScreen(
          placement: PaywallPlacement.softInApp,
          onComplete: () {
            completed = true;
          },
        ),
      ),
    );
  }

  // The CTA's duration is DERIVED from the fixture package's introductory
  // offer (P3D above), so the label follows the store rather than a constant.
  // Change `buildPackage`'s IntroductoryPrice and this string must change
  // with it — that is the property Wave B.4 exists to guarantee.
  const ctaTrial = 'Start my 3 days free';

  // The weekly plan is a de-emphasized text row now, not a peer card, so it is
  // matched by its price line rather than by a bare "Weekly" label.
  final weeklyRow = find.textContaining('Weekly \u2014');

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  // Advance through the PremiumCelebrationOverlay's three-phase reveal
  // (1200ms + 400ms + 1200ms of scripted delays, plus animate-in time) and
  // tap "Begin" to dismiss. Uses fixed pumps because the overlay has
  // continuous shimmer animations that would make pumpAndSettle hang.
  Future<void> dismissPremiumReveal(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Begin'), findsOneWidget);
    await tester.tap(find.text('Begin'));
    // The overlay fade-out + Navigator pop takes ~400ms.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    purchaseService = FakePurchaseService();
    onboardingNotifier = FakeOnboardingNotifier();
    analytics = RecordingAnalyticsService();
    // Repeating breathing-CTA + SAVE-badge shimmer animations introduced
    // by the 2026-05-14 paywall rebuild would make pumpAndSettle hang
    // forever. The seam flips them off for tests; the compile-time Env
    // flag still drives prod behavior.
    debugDisablePaywallAnimations = true;
    appSession = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: const Stream<AuthState>.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );
    completed = false;

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

  testWidgets('Annual purchase success completes onboarding', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(ctaTrial));
    await tester.pump();
    await tester.pump();
    await dismissPremiumReveal(tester);

    expect(completed, isTrue);
    expect(onboardingNotifier.completeCalls, 1);
    expect(purchaseService.lastPurchasedPackageType, PackageType.annual);
  });

  testWidgets('Weekly purchase success completes onboarding', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Weekly card sits below the fold on the 800x600 test viewport once the
    // honest-trial timeline and richer social-proof block are in place. Real
    // users scroll; mirror that here.
    await tapVisible(tester, weeklyRow);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(ctaTrial));
    await tester.pump();
    await tester.pump();
    await dismissPremiumReveal(tester);

    expect(completed, isTrue);
    expect(onboardingNotifier.completeCalls, 1);
    expect(purchaseService.lastPurchasedPackageType, PackageType.weekly);
  });

  testWidgets('Purchase cancel keeps the user on the paywall', (tester) async {
    purchaseService.purchaseError = PlatformException(
      code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
      message: 'cancelled',
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(ctaTrial));
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    // Headline is dynamic (personalized from quiz answers), so assert the
    // still-on-paywall signal via the CTA and a static benefit row — both
    // remain visible only while the PaywallScreen is mounted.
    expect(find.text(ctaTrial), findsOneWidget);
    expect(find.text(AppStrings.paywallPremiumBenefit1), findsOneWidget);
  });

  testWidgets('Restore success completes onboarding', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallRestore));
    await tester.pump();
    await tester.pump();
    await dismissPremiumReveal(tester);

    expect(completed, isTrue);
    expect(onboardingNotifier.completeCalls, 1);

    // W6 Wave C #5 — this surface had ZERO analytics before.
    expect(analytics.withName(AnalyticsEvents.restoreStarted), hasLength(1));
    final restored = analytics.withName(AnalyticsEvents.restoreCompleted);
    expect(restored, hasLength(1));
    expect(restored.single.props[AnalyticsEvents.propPremiumActive], true);
    expect(analytics.withName(AnalyticsEvents.restoreFailed), isEmpty);
  });

  testWidgets('Premium reveal overlay blocks onComplete until dismissed',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(ctaTrial));
    await tester.pump();
    await tester.pump();

    // Advance enough to run purchase + start reveal, but stop BEFORE tapping
    // Begin. onComplete must not have fired yet.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(completed, isFalse);

    // Now dismiss and confirm completion lands.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Begin'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, isTrue);
  });

  testWidgets('Restore with no active entitlement shows error', (tester) async {
    purchaseService.restoreResult = buildCustomerInfo(
      premiumActive: false,
      productId: 'sakina_sub_weekly',
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallRestore));
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(
      find.text('No active premium subscription was found to restore.'),
      findsOneWidget,
    );

    // A restore that succeeds and finds NO entitlement is a genuinely
    // different outcome from one that finds a subscription — it completes,
    // it does not fail.
    expect(analytics.withName(AnalyticsEvents.restoreStarted), hasLength(1));
    final restored = analytics.withName(AnalyticsEvents.restoreCompleted);
    expect(restored, hasLength(1));
    expect(restored.single.props[AnalyticsEvents.propPremiumActive], false);
    expect(analytics.withName(AnalyticsEvents.restoreFailed), isEmpty);
  });

  testWidgets(
      'Restore that throws emits restore_failed{reason: unknown} — mutation: '
      'dropping the catch-block emit would break this', (tester) async {
    purchaseService.restoreError = StateError('boom');

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallRestore));
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(analytics.withName(AnalyticsEvents.restoreStarted), hasLength(1));
    final failed = analytics.withName(AnalyticsEvents.restoreFailed);
    expect(failed, hasLength(1));
    expect(
      failed.single.props[AnalyticsEvents.propReason],
      AnalyticsEvents.storePurchaseFailedReasonUnknown,
    );
    expect(analytics.withName(AnalyticsEvents.restoreCompleted), isEmpty);
  });

  testWidgets('Failed offerings load shows error', (tester) async {
    purchaseService.offeringsError = StateError('boom');

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(find.text(AppStrings.paywallOffersUnavailable), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing,
        reason: 'an offerings failure must never expose a purchase CTA');
    expect(find.text(AppStrings.paywallTerms), findsNothing,
        reason: 'an unavailable offer must not expose billing terms');
  });

  testWidgets(
      'Empty offerings list surfaces the error on first pump — B6 regression',
      (tester) async {
    purchaseService.offerings = <Package>[];

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // The user must see the error BEFORE tapping the CTA; that's the point
    // of B6. We don't tap anything in this test.
    expect(find.text(AppStrings.paywallOffersUnavailable), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text(AppStrings.paywallTerms), findsNothing);
    expect(completed, isFalse);
  });

  testWidgets('offerings loading never renders a sellable surface',
      (tester) async {
    final gate = Completer<List<Package>>();
    purchaseService.offeringsGate = gate;

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(AppStrings.paywallOffersLoading), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text(AppStrings.paywallTerms), findsNothing);
    expect(find.textContaining('\$'), findsNothing);

    gate.complete(purchaseService.offerings);
    await tester.pumpAndSettle();
    expect(find.text(ctaTrial), findsOneWidget);
  });

  final unavailableOfferCases = <({
    String name,
    void Function(FakePurchaseService service) configure,
  })>[
    (
      name: 'thrown offerings',
      configure: (service) => service.offeringsError = StateError('boom'),
    ),
    (
      name: 'empty offerings',
      configure: (service) => service.offerings = <Package>[],
    ),
    (
      name: 'incomplete offerings',
      configure: (service) => service.offerings = [
            buildPackage(
              type: PackageType.annual,
              productId: 'sakina_sub_annual',
            ),
          ],
    ),
    (
      name: 'price-less offerings',
      configure: (service) => service.offerings = [
            buildPackage(
              type: PackageType.annual,
              productId: 'sakina_sub_annual',
              price: 0,
              priceString: '',
            ),
            buildPackage(
              type: PackageType.weekly,
              productId: 'sakina_sub_weekly',
              price: 0,
              priceString: '',
            ),
          ],
    ),
  ];

  for (final testCase in unavailableOfferCases) {
    testWidgets('${testCase.name} has no fabricated purchase UI',
        (tester) async {
      testCase.configure(purchaseService);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallOffersUnavailable), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text(AppStrings.paywallTerms), findsNothing);
      expect(find.textContaining('\$'), findsNothing);
      expect(completed, isFalse);
    });
  }
}
