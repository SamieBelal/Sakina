import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Pins the Blinkist-style honest-billing footer behavior introduced by the
/// 2026-05-14 paywall rebuild:
///
///   - Annual selected + intro price == 0 → footer reads
///     "Day 7: \$X/year unless cancelled" with the live storefront price.
///   - Weekly selected + intro price == 0 → footer reads
///     "Day 3: \$X/week unless cancelled" with the live storefront price.
///   - No introductory offer (storefront edge case) → no "Day N:" footer
///     line at all; `_planHasTrial` gates the entire block so the paywall
///     never promises a trial StoreKit won't grant.

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];

  @override
  Future<List<Package>> getOfferings() async => offerings;

  @override
  Future<bool> isPremium() async => false;
}

Package _packageWithPrice({
  required PackageType type,
  required String productId,
  required double price,
  required String priceString,
  required bool withTrial,
}) {
  return Package(
    type.name,
    type,
    StoreProduct(
      productId,
      'Test description',
      'Test title',
      price,
      priceString,
      'USD',
      introductoryPrice: withTrial
          ? const IntroductoryPrice(
              0,
              'Free',
              'P7D',
              1,
              PeriodUnit.day,
              7,
            )
          : null,
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
  late _FakePurchaseService purchaseService;
  late AppSessionNotifier appSession;

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        analyticsProvider.overrideWithValue(AnalyticsService()),
      ],
      child: MaterialApp(
        home: PaywallScreen(onComplete: () {}),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    purchaseService = _FakePurchaseService();
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
    // Disable breathing CTA + shimmer animations — they never stop, so
    // pumpAndSettle would hang. The compile-time Env flag drives prod
    // behavior independently.
    debugDisablePaywallAnimations = true;

    // Expand the test viewport so the footer (which sits below the CTA at
    // the bottom of the screen) lands within the rendered frame instead of
    // requiring a scroll-into-view dance. The pre-rebuild paywall_screen
    // tests use 800x600 + ensureVisible; the honest-billing assertions live
    // far enough down that a taller viewport is cleaner.
    addTearDown(() => fakeSync = FakeSupabaseSyncService(userId: 'user-1'));
  });

  tearDown(() {
    appSession.dispose();
    debugResetPremiumGrantService();
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
    debugDisablePaywallAnimations = false;
  });

  testWidgets(
      'Annual selected: footer reads "Day 7: \$59.99/year unless cancelled" '
      'using the live storefront priceString from the package', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    purchaseService.offerings = [
      _packageWithPrice(
        type: PackageType.annual,
        productId: 'sakina_annual',
        price: 59.99,
        priceString: '\$59.99',
        withTrial: true,
      ),
      _packageWithPrice(
        type: PackageType.weekly,
        productId: 'sakina_weekly',
        price: 9.99,
        priceString: '\$9.99',
        withTrial: true,
      ),
    ];

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('3 days free, then \$59.99/year'),
      findsOneWidget,
      reason:
          'Annual default-selected: the billing line must surface the live '
          'priceString — \$59.99 — and the right period.',
    );
    // The screen states the terms ONCE now. Two more copies used to sit under
    // the CTA and are what pushed it past a single viewport.
    expect(
      find.textContaining('unless cancelled'),
      findsNothing,
      reason: 'the honest-billing paragraph was removed from the paywall on '
          '2026-07-29; the microcopy above the CTA carries the terms',
    );
    expect(
      find.textContaining('Day 7'),
      findsNothing,
      reason: 'there has never been a 7-day trial — App Store Connect has the '
          'annual intro offer at THREE_DAYS. This assertion used to require '
          'the wrong number.',
    );
  });

  testWidgets(
      'Weekly selected: footer flips to "Day 3: \$9.99/week unless cancelled"',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    purchaseService.offerings = [
      _packageWithPrice(
        type: PackageType.annual,
        productId: 'sakina_annual',
        price: 59.99,
        priceString: '\$59.99',
        withTrial: true,
      ),
      _packageWithPrice(
        type: PackageType.weekly,
        productId: 'sakina_weekly',
        price: 9.99,
        priceString: '\$9.99',
        withTrial: true,
      ),
    ];

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Tap weekly card to switch selection.
    await tester.ensureVisible(find.text(AppStrings.paywallWeeklyLabel));
    await tester.tap(find.text(AppStrings.paywallWeeklyLabel));
    await tester.pumpAndSettle();

    // THE regression this file exists to catch. Until 2026-07-29 the microcopy
    // hardcoded the annual package and the literal "/year", so a user who
    // selected Weekly read "3 days free, then $59.99/year" beside a $9.99/week
    // card. It was masked by the plan-aware paragraph underneath; removing that
    // duplicate made this line the only billing statement on the screen, so it
    // now has to follow the selection itself.
    expect(
      find.textContaining('3 days free, then \$9.99/week'),
      findsOneWidget,
      reason: 'Weekly selected: the billing line must flip to the weekly price '
          'AND the weekly period.',
    );
    expect(
      find.textContaining('/year'),
      findsNothing,
      reason: 'with weekly selected, no annual period may still be claimed '
          'anywhere in the billing copy',
    );
  });

  testWidgets(
      'No introductory offer on either package: footer is fully hidden — '
      '_planHasTrial gates the entire footer so the paywall never promises '
      'a trial StoreKit will not grant', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    purchaseService.offerings = [
      _packageWithPrice(
        type: PackageType.annual,
        productId: 'sakina_annual',
        price: 59.99,
        priceString: '\$59.99',
        withTrial: false,
      ),
      _packageWithPrice(
        type: PackageType.weekly,
        productId: 'sakina_weekly',
        price: 9.99,
        priceString: '\$9.99',
        withTrial: false,
      ),
    ];

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Day 7:'),
      findsNothing,
      reason: 'No intro offer → no "Day 7" footer line.',
    );
    expect(
      find.textContaining('Day 3:'),
      findsNothing,
      reason: 'No intro offer → no "Day 3" footer line either.',
    );
    expect(
      find.textContaining('unless cancelled'),
      findsNothing,
      reason:
          'No intro offer → the entire honest-billing footer block is gated '
          'off.',
    );
  });
}
