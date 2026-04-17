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
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

class FakePurchaseService extends PurchaseService {
  FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];
  Object? offeringsError;
  CustomerInfo? purchaseResult;
  Object? purchaseError;
  CustomerInfo? restoreResult;
  Object? restoreError;
  PackageType? lastPurchasedPackageType;

  @override
  Future<List<Package>> getOfferings() async {
    if (offeringsError != null) throw offeringsError!;
    return offerings;
  }

  @override
  Future<bool> purchase(Package package) async {
    lastPurchasedPackageType = package.packageType;
    if (purchaseError != null) throw purchaseError!;
    return purchaseResult!.entitlements.active.containsKey('premium');
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

StoreProduct buildStoreProduct(String productId) {
  return StoreProduct(
    productId,
    'Test description',
    'Test title',
    4.99,
    '\$4.99',
    'USD',
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
  late bool completed;

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        appSessionProvider.overrideWithValue(appSession),
        onboardingProvider.overrideWith((ref) => onboardingNotifier),
        analyticsProvider.overrideWithValue(AnalyticsService()),
      ],
      child: MaterialApp(
        home: PaywallScreen(
          onComplete: () {
            completed = true;
          },
        ),
      ),
    );
  }

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
  });

  testWidgets('Annual purchase success completes onboarding', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCta));
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

    await tester.tap(find.text(AppStrings.paywallWeeklyLabel));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(AppStrings.paywallCta));
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

    await tapVisible(tester, find.text(AppStrings.paywallCta));
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(find.text(AppStrings.paywallTitle), findsOneWidget);
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
  });

  testWidgets('Premium reveal overlay blocks onComplete until dismissed',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCta));
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
  });

  testWidgets('Failed offerings load shows error', (tester) async {
    purchaseService.offeringsError = StateError('boom');

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(AppStrings.paywallCta));
    await tester.pumpAndSettle();

    expect(completed, isFalse);
    expect(
      find.text(
        'Unable to load subscription options right now. Please try again.',
      ),
      findsOneWidget,
    );
  });
}
