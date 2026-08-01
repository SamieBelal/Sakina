import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/collection/widgets/silver_card_preview.dart';
import 'package:sakina/features/paywall/widgets/paywall_gate_page.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

/// W5 Wave C.2 / B.3 — the three-page gate.
///
/// The properties pinned here are the ones that cost money or trust if they
/// regress: the ✕ is present from frame zero (the 3-second hidden close button
/// is deleted, not moved), Restore / Terms / Privacy are inside the viewport on
/// the smallest and largest supported frames, and a user who is not eligible
/// for the introductory offer is never shown a trial promise.
class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  List<Package> offerings = <Package>[];
  Map<String, IntroEligibilityStatus> eligibility = const {};

  @override
  Future<List<Package>> getOfferings() async => offerings;

  @override
  Future<Map<String, IntroEligibilityStatus>> getIntroEligibility(
    List<String> productIds,
  ) async =>
      eligibility;

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
  int? trialDays,
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
      introductoryPrice: trialDays == null
          ? null
          : IntroductoryPrice(
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
}

/// The two frames the plan calls out: the smallest common iPhone logical size
/// and the largest.
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
  late AppSessionNotifier appSession;
  late ProviderContainer container;
  late bool completed;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-1'),
    );
    purchaseService = _FakePurchaseService()
      ..offerings = [
        _package(
          type: PackageType.annual,
          productId: _annualId,
          priceString: '\$49.99',
          price: 49.99,
          trialDays: 7,
        ),
        _package(
          type: PackageType.weekly,
          productId: _weeklyId,
          priceString: '\$4.99',
          price: 4.99,
          trialDays: 7,
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
        analyticsProvider.overrideWithValue(AnalyticsService()),
      ],
    );
    completed = false;
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
    Size size = _iphone13Mini,
    PaywallPlacement placement = PaywallPlacement.onboarding,
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
            onComplete: () => completed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Walks the ceremony forward by tapping Continue until the purchase footer
  /// (the last page) is on screen.
  Future<void> advanceToPlanSelect(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      final cont = find.widgetWithText(
        ElevatedButton,
        AppStrings.paywallGateContinue,
      );
      if (cont.evaluate().isEmpty) return;
      await tester.tap(cont);
      await tester.pumpAndSettle();
    }
  }

  for (final size in [_iphone13Mini, _iphone17ProMax]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('$label — every ceremony page renders', (tester) async {
      await pumpGate(tester, size: size);

      // Page 1 — value_depth.
      expect(find.text(AppStrings.paywallValueDepthSubline), findsOneWidget);
      expect(find.text(AppStrings.paywallValueDepthBullet3), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Page 2 — trial_timeline. "7 days" is derived from the P7D fixture.
      await tester.tap(find.widgetWithText(
          ElevatedButton, AppStrings.paywallGateContinue));
      await tester.pumpAndSettle();
      expect(find.text('Try everything free for 7 days.'), findsOneWidget);
      expect(find.text('Day 6'), findsOneWidget);
      expect(find.text('Day 7'), findsOneWidget);
      expect(
        find.text(AppStrings.paywallTrialTimelineFootnote),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Page 3 — plan_select.
      await tester.tap(find.widgetWithText(
          ElevatedButton, AppStrings.paywallGateContinue));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
      expect(find.text(AppStrings.paywallPremiumBenefit1), findsOneWidget);
      expect(find.text(AppStrings.paywallPremiumBenefit5), findsOneWidget);
      expect(find.text('Start my 7 days free'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$label — Restore / Terms / Privacy are inside the viewport',
        (tester) async {
      await pumpGate(tester, size: size);
      await advanceToPlanSelect(tester);

      final viewport = Offset.zero & size;
      for (final label in [
        AppStrings.paywallRestore,
        AppStrings.paywallTerms,
        AppStrings.paywallPrivacy,
      ]) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: '$label must be rendered');
        final rect = tester.getRect(finder);
        expect(
          viewport.contains(rect.topLeft) && viewport.contains(rect.bottomRight),
          isTrue,
          reason: '$label must sit inside the frame without scrolling — a '
              'Restore button below the fold is an App Store review risk',
        );
      }
    });
  }

  testWidgets('the ✕ is present and tappable on page one from frame zero',
      (tester) async {
    tester.view.physicalSize = _iphone13Mini;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PaywallScreen(
            placement: PaywallPlacement.onboarding,
            onComplete: () => completed = true,
          ),
        ),
      ),
    );
    // ONE pump — no settle, no timer advance. The 3-second reveal delay this
    // replaced is deleted, so the button must already be here and already be
    // hit-testable.
    await tester.pump();

    final close = find.byType(PaywallCloseButton);
    expect(close, findsOneWidget);
    expect(tester.getSize(close).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(close).height, greaterThanOrEqualTo(44));
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
      reason: 'the ✕ must be enabled immediately, not after a delay',
    );
  });

  testWidgets('dismissing shows the always-free card, whose Continue goes home',
      (tester) async {
    await pumpGate(tester);

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();

    expect(completed, isFalse, reason: 'the card holds before home');
    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    // It asks for nothing: no second offer, no referral chain, no "are you
    // sure". One way out, and it goes home.
    expect(find.byType(ElevatedButton), findsNothing);

    await tester.tap(find.widgetWithText(
        OutlinedButton, AppStrings.paywallGateContinue));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('the always-free card is once-ever: a later dismiss goes '
      'straight home', (tester) async {
    SharedPreferences.setMockInitialValues({
      '${PaywallScreen.alwaysFreeCardShownPrefsBaseKey}:user-1': true,
    });

    await pumpGate(tester);
    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsNothing);
  });

  group('a user who is not eligible for the intro offer', () {
    setUp(() {
      purchaseService.eligibility = const {
        _annualId: IntroEligibilityStatus.introEligibilityStatusIneligible,
        _weeklyId: IntroEligibilityStatus.introEligibilityStatusIneligible,
      };
    });

    testWidgets('sees "Subscribe" and never a trial promise', (tester) async {
      await pumpGate(tester);
      await advanceToPlanSelect(tester);

      expect(find.text(AppStrings.paywallCtaSubscribe), findsOneWidget);
      expect(
        find.text('\$49.99/year. Cancel anytime in Settings.'),
        findsOneWidget,
      );
      // The products still carry a P7D offer, but THIS Apple ID has already
      // used its one-per-group grant. Every trial PROMISE must be gone, or
      // they tap "free" and are charged instantly. (The free-forever honesty
      // line legitimately still says "free" — it is about the free tier, not
      // about a trial, which is why this asserts on the promise shapes.)
      expect(find.textContaining('7 days'), findsNothing);
      expect(find.textContaining('free first'), findsNothing);
      expect(find.textContaining('Free for'), findsNothing);
      expect(find.textContaining('Start my'), findsNothing);
    });

    testWidgets('skips the trial_timeline page entirely', (tester) async {
      await pumpGate(tester);

      // Two pages, not three: there is no trial to be transparent about.
      expect(find.byType(PaywallStepDots), findsOneWidget);
      expect(
        tester.widget<PaywallStepDots>(find.byType(PaywallStepDots)).count,
        2,
      );
      await tester.tap(find.widgetWithText(
          ElevatedButton, AppStrings.paywallGateContinue));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
      expect(
        find.text(AppStrings.paywallTrialTimelineTodayHeading),
        findsNothing,
      );
    });

    testWidgets('an UNKNOWN status is treated the same as ineligible on iOS',
        (tester) async {
      // RevenueCat's own guidance: when it cannot compute eligibility, show
      // non-intro pricing. The failure mode is a lost trial start, never a
      // user charged after being told they would not be.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      purchaseService.eligibility = const {
        _annualId: IntroEligibilityStatus.introEligibilityStatusUnknown,
        _weeklyId: IntroEligibilityStatus.introEligibilityStatusUnknown,
      };
      try {
        await pumpGate(tester);
        await advanceToPlanSelect(tester);

        expect(find.text(AppStrings.paywallCtaSubscribe), findsOneWidget);
        expect(find.textContaining('7 days'), findsNothing);
      } finally {
        // Must be reset INSIDE the test body — the binding asserts that no
        // foundation debug variable outlives it.
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  testWidgets('page one renders the ACTUAL card the reveal awarded',
      (tester) async {
    // The onboarding reveal awards a deterministic Silver tier and draws it
    // with `revealCardTile`. If the paywall drew its own approximation, the
    // screen asking for trust would contradict the screen that earned it
    // thirty seconds earlier — so this pins the WIDGET, not a look-alike.
    final card = allCollectibleNames.first;
    container.read(onboardingProvider.notifier).state = container
        .read(onboardingProvider)
        .copyWith(revealedPairNameIds: [card.id]);

    await pumpGate(tester);

    expect(find.byType(SilverOrnateTile), findsOneWidget);
    expect(
      tester.widget<SilverOrnateTile>(find.byType(SilverOrnateTile)).card.id,
      card.id,
    );
    expect(
      find.text("You've met ${card.transliteration}."),
      findsOneWidget,
      reason: 'the headline names the same Name the card shows, in '
          'transliteration — Arabic in an English sentence would bleed RTL '
          'into the rest of the line',
    );
  });

  testWidgets('the onboarding contract keys page one\'s copy', (tester) async {
    container.read(onboardingProvider.notifier).state = container
        .read(onboardingProvider)
        .copyWith(contract: 'sign');

    await pumpGate(tester);

    expect(find.text(AppStrings.paywallValueDepthSublineSign), findsOneWidget);
    expect(find.text(AppStrings.paywallValueDepthBullet1Sign), findsOneWidget);
    expect(find.text(AppStrings.paywallValueDepthSubline), findsNothing);
  });
}
