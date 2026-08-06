import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Pins the live-package billing disclosure behavior of the W5 paywall:
///
///   - Annual and weekly selection update the terms line from the live
///     localized price and the selected plan's period.
///   - No introductory offer (storefront edge case) → the CTA is "Subscribe"
///     and no trial wording appears, while plain cancellation terms remain.

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
        home: PaywallScreen(
          onComplete: () {},
          placement: PaywallPlacement.softInApp,
        ),
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

  testWidgets('Annual selected: terms use the live storefront priceString',
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

    expect(
      find.textContaining('Free for 7 days, then \$59.99/year'),
      findsOneWidget,
      reason: 'Annual default-selected: the billing line must surface the live '
          'priceString — \$59.99 — and the right period. "7 days" is DERIVED '
          'from this fixture package (P7D / periodNumberOfUnits 7), never from '
          'a Dart constant — change the fixture and the copy follows.',
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

  testWidgets('Weekly selected: terms follow the selected plan',
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

    // Tap the weekly row to switch selection. It is a de-emphasized text row
    // now, not a peer card, so it is matched by its price line.
    final weeklyRow = find.textContaining('Weekly \u2014');
    await tester.ensureVisible(weeklyRow);
    await tester.tap(weeklyRow);
    await tester.pumpAndSettle();

    // THE regression this file exists to catch. Until 2026-07-29 the microcopy
    // hardcoded the annual package and the literal "/year", so a user who
    // selected Weekly read "3 days free, then $59.99/year" beside a $9.99/week
    // card. It was masked by the plan-aware paragraph underneath; removing that
    // duplicate made this line the only billing statement on the screen, so it
    // now has to follow the selection itself.
    expect(
      find.textContaining('Free for 7 days, then \$9.99/week'),
      findsOneWidget,
      reason: 'Weekly selected: the billing line must flip to the weekly price '
          'AND the weekly period.',
    );
    // Scoped to the BILLING line. The annual plan card still legitimately
    // prints "\$59.99/year" as its own price — the bug this pins is the TERMS
    // line claiming the annual period while weekly is selected.
    expect(
      find.textContaining('then \$59.99/year'),
      findsNothing,
      reason: 'with weekly selected, no annual period may still be claimed '
          'in the billing terms',
    );
  });

  testWidgets('No introductory offer: Subscribe has no trial promise',
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

    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.textContaining('Free for '), findsNothing);
    expect(
      find.textContaining('unless cancelled'),
      findsNothing,
      reason: 'W5 uses plain cancellation terms, not the old Day N footer.',
    );
  });
}
