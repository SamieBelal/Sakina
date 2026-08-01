import 'dart:async';

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

class _RecordedEvent {
  _RecordedEvent(this.name, this.props);
  final String name;
  final Map<String, Object?> props;
}

class _RecordingAnalytics extends AnalyticsService {
  final List<_RecordedEvent> events = [];

  /// Event names that throw synchronously when tracked.
  Set<String> throwOn = const {};

  /// Deliberately SYNCHRONOUS, matching `AnalyticsService.track`. An `async`
  /// override would turn a throw into a rejected future, which no `try` at the
  /// call site can catch — the spy would then be unable to reproduce the very
  /// failure shape being tested.
  @override
  void track(String name, {Map<String, dynamic>? properties}) {
    if (throwOn.contains(name)) {
      throw StateError('analytics down: $name');
    }
    events.add(_RecordedEvent(name, properties ?? const {}));
  }

  List<_RecordedEvent> all(String name) =>
      events.where((e) => e.name == name).toList();

  _RecordedEvent? first(String name) =>
      events.where((e) => e.name == name).firstOrNull;

  int count(String name) => all(name).length;
}

class _ThrowingSyncService extends FakeSupabaseSyncService {
  _ThrowingSyncService() : super(userId: 'user-1');

  @override
  String scopedKey(String baseKey) =>
      throw StateError('Supabase client is not initialized');
}

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];
  Map<String, IntroEligibilityStatus> eligibility = const {};
  Completer<Map<String, IntroEligibilityStatus>>? eligibilityGate;
  PackageType? lastPurchasedPackageType;
  bool purchaseSucceeds = true;
  bool restoreSucceeds = false;

  @override
  Future<List<Package>> getOfferings() async => offerings;

  @override
  Future<Map<String, IntroEligibilityStatus>> getIntroEligibility(
    List<String> productIds,
  ) {
    final gate = eligibilityGate;
    if (gate != null) return gate.future;
    return Future.value(eligibility);
  }

  @override
  Future<bool> purchaseSubscription(Package package) async {
    lastPurchasedPackageType = package.packageType;
    return purchaseSucceeds;
  }

  @override
  Future<bool> restorePurchases() async => restoreSucceeds;

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
  int trialDays = 7,
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
        introductoryPrice: IntroductoryPrice(
          0,
          'Free',
          'P${trialDays}D',
          1,
          PeriodUnit.day,
          trialDays,
        ),
      ),
      const PresentedOfferingContext('default', null, null),
    );

const _iphone13Mini = Size(390, 844);
const _iphone17ProMax = Size(440, 956);

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
  late bool completed;

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
    completed = false;
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

  Future<void> pumpGate(
    WidgetTester tester, {
    PaywallPlacement placement = PaywallPlacement.softInApp,
    Size size = _iphone13Mini,
    bool hardGate = false,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PaywallScreen(
            placement: placement,
            hardGate: hardGate,
            inOnboardingFlow: !hardGate,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

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

  // ───────────────── P1: origin stickiness ─────────────────

  testWidgets('P1 — a CTA purchase after an abandoned exit offer is NOT '
      'credited to the exit offer', (tester) async {
    purchaseService.purchaseSucceeds = false;
    await pumpGate(tester);

    // ✕ → exit offer → accept → StoreKit abandons.
    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallExitOfferSheet), findsOneWidget);
    await tester.tap(find.text('Start 7 days free trial'));
    await settlePurchase(tester);
    expect(analytics.count(AnalyticsEvents.paywallCtaTapped), 1);

    // The user is back on the gate. They now tap the gate's OWN CTA.
    purchaseService.purchaseSucceeds = true;
    final cta = find.textContaining('Start my 7 days free');
    expect(cta, findsOneWidget);
    await tester.tap(cta);
    await settlePurchase(tester);

    final taps = analytics.all(AnalyticsEvents.paywallCtaTapped);
    expect(taps.length, 2);
    expect(
      taps[1].props[AnalyticsEvents.propOrigin],
      AnalyticsEvents.originPaywall,
      reason: 'the second attempt started from the gate CTA, not the sheet',
    );
    final started = analytics.first(AnalyticsEvents.trialStarted);
    expect(started, isNotNull);
    expect(
      started!.props[AnalyticsEvents.propOrigin],
      AnalyticsEvents.originPaywall,
      reason: 'crediting this conversion to the exit offer inflates exactly '
          'the number D11 kept the sheet to measure',
    );
  });

  // ───────────────── P2: late eligibility page shuffle ─────────────────

  testWidgets('P2 — eligibility resolving late does not shove the user off '
      'the plan page', (tester) async {
    final gate = Completer<Map<String, IntroEligibilityStatus>>();
    purchaseService.eligibilityGate = gate;

    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    // Unresolved → non-trial copy → a two-page ceremony.
    expect(find.text(AppStrings.paywallValueDepthSubline), findsOneWidget);
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);

    // The store answers now.
    gate.complete(const {
      _annualId: IntroEligibilityStatus.introEligibilityStatusEligible,
      _weeklyId: IntroEligibilityStatus.introEligibilityStatusEligible,
    });
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.paywallTrialTimelineTodayHeading),
      findsNothing,
      reason: 'the user chose to advance to the plan page; a page appearing '
          'behind them must not pull them backwards onto it',
    );
    expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
    expect(
      analytics
          .all(AnalyticsEvents.paywallPageViewed)
          .where((e) =>
              e.props[AnalyticsEvents.propPageId] ==
              AnalyticsEvents.paywallPagePlanSelect)
          .length,
      1,
      reason: 'a page view counted twice corrupts the ceremony drop-off read',
    );
  });

  // ───────────────── P3/P4: the ✕ cannot be trapped ─────────────────

  testWidgets('P3 — ✕ still lets the user out when scopedKey throws',
      (tester) async {
    SupabaseSyncService.debugSetInstance(_ThrowingSyncService());
    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    await tester.tap(
      find.widgetWithText(OutlinedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('P4 — ✕ still lets the user out when analytics throws',
      (tester) async {
    analytics.throwOn = {AnalyticsEvents.paywallClosed};
    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'the escape hatch must not share a failure path with its own '
            'bookkeeping');
    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
  });

  // ───────────────── P5: exits after failure ─────────────────

  testWidgets('P5 — a restore that finds nothing leaves the ✕ working',
      (tester) async {
    purchaseService.restoreSucceeds = false;
    await pumpGate(tester);

    await tester.tap(find.text(AppStrings.paywallRestore));
    await tester.pumpAndSettle();
    expect(find.textContaining('No active premium subscription'),
        findsOneWidget);

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();
    // Weekly SKU is loaded and annual is selected → the exit offer intercepts;
    // decline it and the dismissal must finish.
    if (find.byType(PaywallExitOfferSheet).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.paywallExitOfferDecline));
      await tester.pumpAndSettle();
    }
    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('P5b — a failed purchase leaves the ✕ working', (tester) async {
    purchaseService.purchaseSucceeds = false;
    await pumpGate(tester);

    await tester.tap(find.textContaining('Start my 7 days free'));
    await settlePurchase(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();
    if (find.byType(PaywallExitOfferSheet).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.paywallExitOfferDecline));
      await tester.pumpAndSettle();
    }
    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
  });

  // ───────────────── P6: layout ─────────────────

  for (final size in [_iphone13Mini, _iphone17ProMax]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('P6 $label — condensed surface with an error line does not '
        'overflow and keeps Restore in the viewport', (tester) async {
      purchaseService.offerings = const [];
      await pumpGate(tester, size: size);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Unable to load subscription options'),
          findsOneWidget);
      final viewport = Offset.zero & size;
      final rect = tester.getRect(find.text(AppStrings.paywallRestore));
      expect(viewport.contains(rect.topLeft), isTrue);
      expect(viewport.contains(rect.bottomRight), isTrue);
    });

    testWidgets('P6 $label — the hard gate safety valve fits', (tester) async {
      purchaseService.offerings = const [];
      await pumpGate(
        tester,
        size: size,
        placement: PaywallPlacement.hardWall,
        hardGate: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PaywallCloseButton), findsNothing);
      final valve = find.widgetWithText(
        TextButton,
        AppStrings.paywallGateContinue,
      );
      expect(valve, findsOneWidget);
      final viewport = Offset.zero & size;
      final rect = tester.getRect(valve);
      expect(viewport.contains(rect.topLeft), isTrue);
      expect(viewport.contains(rect.bottomRight), isTrue);
    });

    testWidgets('P6 $label — the always-free card fits', (tester) async {
      await pumpGate(tester, placement: PaywallPlacement.onboarding, size: size);
      await tester.tap(find.byType(PaywallCloseButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    });

    testWidgets('P6 $label — the exit-offer sheet fits', (tester) async {
      await pumpGate(tester, size: size);
      await tester.tap(find.byType(PaywallCloseButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(PaywallExitOfferSheet), findsOneWidget);
    });

    testWidgets('P6 $label — a long trial label and long prices still fit',
        (tester) async {
      // A 1-month intro on a high-price storefront: the longest strings the
      // templates can produce.
      purchaseService.offerings = const [
        Package(
          'annual',
          PackageType.annual,
          StoreProduct(
            _annualId,
            'desc',
            'title',
            18900.0,
            '¥18,900',
            'JPY',
            introductoryPrice: IntroductoryPrice(
              0,
              'Free',
              'P30D',
              1,
              PeriodUnit.day,
              30,
            ),
          ),
          PresentedOfferingContext('default', null, null),
        ),
        Package(
          'weekly',
          PackageType.weekly,
          StoreProduct(
            _weeklyId,
            'desc',
            'title',
            980.0,
            '¥980',
            'JPY',
            introductoryPrice: IntroductoryPrice(
              0,
              'Free',
              'P30D',
              1,
              PeriodUnit.day,
              30,
            ),
          ),
          PresentedOfferingContext('default', null, null),
        ),
      ];
      await pumpGate(tester, size: size, placement: PaywallPlacement.onboarding);
      for (var i = 0; i < 3; i++) {
        final cont =
            find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue);
        if (cont.evaluate().isEmpty) break;
        await tester.tap(cont);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
    });
  }
}
