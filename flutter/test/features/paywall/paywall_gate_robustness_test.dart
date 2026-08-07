import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/constants/app_spacing.dart';
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
import 'package:sakina/widgets/sakina_loader.dart';
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

  /// Held open to reproduce a store call that never answers — the shape that
  /// used to strand the hard gate in a loading state with no way out. Distinct
  /// from a throwing call: neither future ever completes, so only the
  /// screen's own timeout can end it.
  Completer<List<Package>>? offeringsGate;
  PackageType? lastPurchasedPackageType;
  bool purchaseSucceeds = true;
  bool restoreSucceeds = false;

  @override
  Future<List<Package>> getOfferings() {
    final gate = offeringsGate;
    if (gate != null) return gate.future;
    return Future.value(offerings);
  }

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

  testWidgets(
      'P1 — a CTA purchase after an abandoned exit offer is NOT '
      'credited to the exit offer', (tester) async {
    purchaseService.purchaseSucceeds = false;
    await pumpGate(tester);

    // ✕ → exit offer → accept → StoreKit abandons.
    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallExitOfferSheet), findsOneWidget);
    await tester.tap(find.text('Start 7-day free trial'));
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

  // ───────────────── P2: the page list moves under the user ─────────────────

  testWidgets(
      'P2 — the ceremony renders nothing sellable until eligibility resolves',
      (tester) async {
    final gate = Completer<Map<String, IntroEligibilityStatus>>();
    purchaseService.eligibilityGate = gate;

    await pumpGate(
      tester,
      placement: PaywallPlacement.onboarding,
      settle: false,
    );
    await tester.pump();

    // While eligibility is unresolved, the gate is explicitly loading rather
    // than rendering no-trial pricing or a partially valid ceremony.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text(AppStrings.paywallPlanSelectHeadline), findsNothing);

    // The store answers now.
    gate.complete(const {
      _annualId: IntroEligibilityStatus.introEligibilityStatusEligible,
      _weeklyId: IntroEligibilityStatus.introEligibilityStatusEligible,
    });
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.paywallValueDepthSubline), findsOneWidget);
    expect(
      tester.widget<PaywallStepDots>(find.byType(PaywallStepDots)).count,
      3,
    );
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.paywallTrialTimelineTodayHeading),
      findsOneWidget,
      reason: 'the late eligibility response should add the timeline only '
          'after the loading state resolves',
    );
    expect(
      analytics
          .all(AnalyticsEvents.paywallPageViewed)
          .where((e) =>
              e.props[AnalyticsEvents.propPageId] ==
              AnalyticsEvents.paywallPageValueDepth)
          .length,
      1,
      reason: 'the first page view is counted once after the offer becomes '
          'available',
    );
  });

  testWidgets(
      'P2b — a page list that GROWS under the user leaves them on plan_select',
      (tester) async {
    // The list is derived from the SELECTED plan's trial, so choosing a plan
    // can insert `trial_timeline` BEHIND a user who is already on
    // `plan_select`. Index-based tracking would slide them backwards onto the
    // page that just appeared; the screen tracks the page by IDENTITY
    // (`pages.indexOf(_currentPage)`) precisely so it cannot.
    //
    // Annual ineligible + weekly eligible is the shape that produces it: the
    // ceremony opens two pages long and becomes three the moment weekly is
    // picked.
    purchaseService.eligibility = const {
      _annualId: IntroEligibilityStatus.introEligibilityStatusIneligible,
      _weeklyId: IntroEligibilityStatus.introEligibilityStatusEligible,
    };
    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    expect(
      tester.widget<PaywallStepDots>(find.byType(PaywallStepDots)).count,
      2,
      reason: 'no trial on the default (annual) plan → no timeline page',
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);

    // `ensureVisible` first: the plan body scrolls under a pinned footer, and at
    // this viewport the weekly tile's centre sits beneath it. A bare `tap`
    // dispatches at those coordinates anyway and silently hits Restore — every
    // assertion below would then be measuring the wrong interaction.
    final weeklyTile = find.textContaining('Weekly —');
    await tester.ensureVisible(weeklyTile);
    await tester.pumpAndSettle();
    await tester.tap(weeklyTile);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Start my'),
      findsOneWidget,
      reason: 'the tap has to actually select weekly — a CTA still reading '
          '"Subscribe" means it landed somewhere else',
    );
    expect(
      tester.widget<PaywallStepDots>(find.byType(PaywallStepDots)).count,
      3,
      reason: 'the timeline page joined the list',
    );
    expect(
      find.text(AppStrings.paywallPlanSelectHeadline),
      findsOneWidget,
      reason: 'a page appearing behind them must not pull them backwards onto '
          'it — they chose to advance past that point',
    );
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
    // `pump`, not `pumpAndSettle`: the hand-off puts an indeterminate loader on
    // screen, which never settles. In the app the router replaces this screen a
    // moment later; here `onComplete` only flips a bool, so the loader would
    // spin until the timeout.
    await tester.pump();
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
    expect(
        find.textContaining('No active premium subscription'), findsOneWidget);

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

  // ───────────────── P5c: restore survives an offerings failure ─────────────

  /// Restore does not read the offerings — `restorePurchases()` asks StoreKit
  /// about THIS Apple ID's receipts. So an offerings outage must not take the
  /// restore path down with it: on the hard gate this screen is the only
  /// surface an existing subscriber can reach (no ✕, Settings still walled),
  /// and the safety valve grants a session-only bypass, never the entitlement.
  testWidgets('P5c — the hard gate keeps Restore when offerings fail to load',
      (tester) async {
    purchaseService.offerings = const [];
    purchaseService.restoreSucceeds = true;
    await pumpGate(
      tester,
      placement: PaywallPlacement.hardWall,
      hardGate: true,
    );

    expect(find.text(AppStrings.paywallOffersUnavailable), findsOneWidget);
    expect(
      find.text(AppStrings.paywallRestore),
      findsOneWidget,
      reason: 'an existing subscriber must still be able to restore when the '
          'storefront cannot price the offer',
    );

    await tester.tap(find.text(AppStrings.paywallRestore));
    await settlePurchase(tester);
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets(
      'P5c — the unavailable surface offers Restore but stays non-sellable',
      (tester) async {
    purchaseService.offerings = const [];
    purchaseService.restoreSucceeds = false;
    await pumpGate(tester);

    expect(find.text(AppStrings.paywallRestore), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text(AppStrings.paywallTerms), findsNothing);
    expect(find.text(AppStrings.paywallPrivacy), findsNothing);
    expect(find.textContaining('\$'), findsNothing);

    await tester.tap(find.text(AppStrings.paywallRestore));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('No active premium subscription'), findsOneWidget);
    expect(completed, isFalse);

    expect(
      find.text(AppStrings.paywallOffersUnavailable),
      findsOneWidget,
      reason: 'a failed Restore adds a fact to this surface; it must not '
          'overwrite the only sentence explaining why there is nothing to buy',
    );
  });

  // ───────────────── P5g: the headline clears the chrome ─────────────────

  testWidgets('P5g — the headline never starts against the chrome row',
      (tester) async {
    // The back button and the ✕ sit in a 44pt row directly above the body. With
    // no gap the display headline butts right up under them, which reads as a
    // rendering fault and puts tappable chrome a couple of points from text.
    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    void expectClearance(Finder headline, String label) {
      final chrome = find.byType(PaywallCloseButton).evaluate().isNotEmpty
          ? find.byType(PaywallCloseButton)
          : find.byType(PaywallBackButton);
      final chromeBottom = tester.getRect(chrome).bottom;
      final headlineTop = tester.getRect(headline).top;
      expect(
        headlineTop - chromeBottom,
        greaterThanOrEqualTo(AppSpacing.lg),
        reason:
            '$label starts ${headlineTop - chromeBottom}pt under the chrome '
            'row; the frame owes every page at least ${AppSpacing.lg}pt',
      );
    }

    expectClearance(
      find.text(AppStrings.paywallValueDepthHeadlineFallback),
      'the value-depth headline',
    );

    final forward = find.widgetWithText(
      ElevatedButton,
      AppStrings.paywallGateContinue,
    );
    await tester.tap(forward);
    await tester.pumpAndSettle();
    expectClearance(
      find.textContaining('Try everything free'),
      'the trial-timeline headline',
    );

    await tester.tap(forward);
    await tester.pumpAndSettle();
    expectClearance(
      find.text(AppStrings.paywallPlanSelectHeadline),
      'the plan-select headline',
    );
  });

  // ───────────────── P5f: the ceremony walks backwards ─────────────────

  testWidgets('P5f — page one has no back, later pages do', (tester) async {
    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    expect(
      find.byType(PaywallBackButton),
      findsNothing,
      reason: 'nowhere to go back TO from the first page; the ✕ is the exit',
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaywallBackButton), findsOneWidget);
  });

  testWidgets('P5f — back returns to the previous page', (tester) async {
    await pumpGate(tester, placement: PaywallPlacement.onboarding);
    expect(find.text(AppStrings.paywallValueDepthSubline), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paywallValueDepthSubline), findsNothing);

    await tester.tap(find.byType(PaywallBackButton));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.paywallValueDepthSubline),
      findsOneWidget,
      reason: 'back steps one page, it does not exit the gate',
    );
    expect(completed, isFalse);
  });

  testWidgets('P5f — walking back and forth does not re-count a page view',
      (tester) async {
    await pumpGate(tester, placement: PaywallPlacement.onboarding);

    final forward = find.widgetWithText(
      ElevatedButton,
      AppStrings.paywallGateContinue,
    );
    await tester.tap(forward);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PaywallBackButton));
    await tester.pumpAndSettle();
    await tester.tap(forward);
    await tester.pumpAndSettle();

    for (final pageId in [
      AnalyticsEvents.paywallPageValueDepth,
      AnalyticsEvents.paywallPageTrialTimeline,
    ]) {
      expect(
        analytics
            .all(AnalyticsEvents.paywallPageViewed)
            .where((e) => e.props[AnalyticsEvents.propPageId] == pageId)
            .length,
        1,
        reason: '$pageId was browsed twice but entered once — counting the '
            'revisit inflates the ceremony drop-off denominator',
      );
    }
  });

  testWidgets('P5f — a hard-gated ceremony still walks back, with no ✕',
      (tester) async {
    // Back moves WITHIN the ceremony, so it is not an escape and must not be
    // gated on the hard-wall contract. This pairing is SYNTHETIC — the screen
    // asserts `!(hardGate && inOnboardingFlow)` and only the onboarding
    // placement runs a ceremony, so the two cannot meet in the app today. The
    // test pins the independence so a future surface that does pair them
    // inherits the right behaviour rather than a forward-only ceremony.
    await pumpGate(
      tester,
      placement: PaywallPlacement.onboarding,
      hardGate: true,
    );
    await tester.tap(
      find.widgetWithText(ElevatedButton, AppStrings.paywallGateContinue),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaywallBackButton), findsOneWidget);
    expect(
      find.byType(PaywallCloseButton),
      findsNothing,
      reason: 'back is not an exit, so it must not smuggle one in',
    );
  });

  testWidgets('P5f — no back on the single-page surfaces', (tester) async {
    await pumpGate(tester);
    expect(
      find.byType(PaywallBackButton),
      findsNothing,
      reason: 'the condensed surface is one page',
    );
  });

  // ───────────────── P5e: leaving is not instant ─────────────────
  //
  // `onComplete` runs an analytics flush and a Supabase write before the router
  // moves, and `_doClose` writes two prefs first. All of it used to happen with
  // the paywall still fully rendered and the ✕ still live.

  testWidgets('P5e — the safety valve hands off behind a loader',
      (tester) async {
    purchaseService.offerings = const [];
    await pumpGate(
      tester,
      placement: PaywallPlacement.hardWall,
      hardGate: true,
    );

    await tester
        .tap(find.widgetWithText(TextButton, AppStrings.paywallGateContinue));
    await tester.pump();

    expect(completed, isTrue);
    expect(
      find.byType(SakinaLoader),
      findsOneWidget,
      reason: 'the hand-off is in flight; the user must see that, not a live '
          'paywall they can keep tapping',
    );
    expect(find.text(AppStrings.paywallGateContinue), findsNothing);
    expect(find.text(AppStrings.paywallRestore), findsNothing);
  });

  testWidgets('P5e — a second tap during the hand-off is swallowed',
      (tester) async {
    purchaseService.offerings = const [];
    await pumpGate(
      tester,
      placement: PaywallPlacement.hardWall,
      hardGate: true,
    );

    final valve =
        find.widgetWithText(TextButton, AppStrings.paywallGateContinue);
    await tester.tap(valve);
    // No pump between the taps: the second lands on the stale tree, which is
    // exactly what a real double-tap does. Only the synchronous flag can catch
    // it — a guard that waited for the rebuild would not.
    await tester.tap(valve, warnIfMissed: false);
    await tester.pump();

    expect(
      analytics.count(AnalyticsEvents.paywallSafetyValveUsed),
      1,
      reason: 'the hand-off is in flight; a second tap must not re-enter it',
    );
  });

  // ───────────────── P5d: the store never answers ─────────────────
  //
  // Both store calls are made once from initState with no retry, and the gate
  // renders no ✕, no Restore and no valve while it is loading. An unbounded
  // await is therefore not a slow paywall but a permanently bricked one, so
  // each of these pins the timeout that ends it.

  testWidgets(
      'P5d — a hung offerings call resolves to the escapable failure state',
      (tester) async {
    purchaseService.offeringsGate = Completer<List<Package>>();
    await pumpGate(
      tester,
      placement: PaywallPlacement.hardWall,
      hardGate: true,
      settle: false,
    );
    await tester.pump();

    // Nothing to buy, nothing to tap: the state this timeout exists to end.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PaywallCloseButton), findsNothing);
    expect(find.text(AppStrings.paywallRestore), findsNothing);
    expect(
      find.widgetWithText(TextButton, AppStrings.paywallGateContinue),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.paywallOffersUnavailable), findsOneWidget);
    expect(
      find.text(AppStrings.paywallRestore),
      findsOneWidget,
      reason: 'a reinstalling subscriber reaches this screen and no other',
    );
    expect(
      find.widgetWithText(TextButton, AppStrings.paywallGateContinue),
      findsOneWidget,
      reason: 'without the valve the hard gate is a dead end for a user whose '
          'store call never answered',
    );
    expect(
      analytics.count(AnalyticsEvents.paywallOfferingsLoadFailed),
      1,
      reason: 'a timeout is an offerings failure and must be as visible as a '
          'thrown one',
    );
  });

  testWidgets(
      'P5d — a hung eligibility call resolves to a sellable offer at the '
      'live price', (tester) async {
    purchaseService.eligibilityGate =
        Completer<Map<String, IntroEligibilityStatus>>();
    await pumpGate(tester, settle: false);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);

    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    // An unanswered eligibility lookup is not a reason to withhold the offer:
    // the price came from the offerings call, which DID answer. The screen
    // becomes sellable at that live price and the trial resolver falls back to
    // the product-level signal (`TrialOffer.resolve`), which is why this
    // asserts sellability rather than a specific CTA label — the label is
    // platform-dependent and Android, the test platform, keeps trial copy.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ElevatedButton), findsWidgets);
    expect(find.textContaining('\$49.99'), findsWidgets);
  });

  testWidgets('P5c — Restore is not offered while offerings are still loading',
      (tester) async {
    final gate = Completer<Map<String, IntroEligibilityStatus>>();
    purchaseService.eligibilityGate = gate;
    await pumpGate(tester, settle: false);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text(AppStrings.paywallRestore),
      findsNothing,
      reason: 'the loading state resolves on its own; a Restore link there '
          'invites a redundant store round-trip',
    );

    gate.complete(const {
      _annualId: IntroEligibilityStatus.introEligibilityStatusEligible,
      _weeklyId: IntroEligibilityStatus.introEligibilityStatusEligible,
    });
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paywallRestore), findsOneWidget);
  });

  // ───────────────── P6: layout ─────────────────

  for (final size in [_iphone13Mini, _iphone17ProMax]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('P6 $label — unavailable surface has no sellable controls',
        (tester) async {
      purchaseService.offerings = const [];
      await pumpGate(tester, size: size);

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.paywallOffersUnavailable), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text(AppStrings.paywallTerms), findsNothing);
      expect(find.textContaining('\$'), findsNothing);

      // On the hard gate this is the only surface a reinstalling subscriber
      // can reach, so Restore being merely PRESENT is not enough.
      final viewport = Offset.zero & size;
      final rect = tester.getRect(find.text(AppStrings.paywallRestore));
      expect(viewport.contains(rect.topLeft), isTrue);
      expect(viewport.contains(rect.bottomRight), isTrue);
    });

    testWidgets('P6 $label — an error line keeps Restore in the viewport',
        (tester) async {
      // The tallest the purchase footer ever gets: a failed purchase adds an
      // error line above a CTA, a legal row and the terms copy. A Restore
      // button pushed below the fold is an App Store review risk.
      //
      // A purchase that completes without granting the entitlement reports
      // `paywallPremiumNotActive` — the longest of the footer's error strings,
      // so it is also the worst case for this measurement.
      purchaseService.purchaseSucceeds = false;
      await pumpGate(tester, size: size);

      await tester.tap(find.textContaining('Start my 7 days free'));
      await settlePurchase(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.paywallPremiumNotActive), findsOneWidget);

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
      await pumpGate(tester,
          placement: PaywallPlacement.onboarding, size: size);
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
      await pumpGate(tester,
          size: size, placement: PaywallPlacement.onboarding);
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
