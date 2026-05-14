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
      find.textContaining('Day 7: \$59.99/year unless cancelled'),
      findsOneWidget,
      reason:
          'Annual default-selected: honest-billing footer must surface the '
          'live priceString — \$59.99 — and the literal Apple-reminder copy.',
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

    expect(
      find.textContaining('Day 3: \$9.99/week unless cancelled'),
      findsOneWidget,
      reason:
          'Weekly selected: footer must flip to the 3-day-trial copy with '
          'the live weekly priceString.',
    );
    expect(
      find.textContaining('Day 7:'),
      findsNothing,
      reason:
          'When weekly is selected the annual "Day 7" line must not also '
          'render — only one footer at a time.',
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
