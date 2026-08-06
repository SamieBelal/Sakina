import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/features/paywall/widgets/paywall_gate_page.dart';
import 'package:sakina/services/purchase_service.dart';

/// The condensed `soft_inapp` surface — the destination every cap-sheet and
/// warm-up-sheet upgrade CTA lands on.
///
/// The "Just N minutes a day to become your best self" headline this file used
/// to pin is gone: the W5 gate replaced it, and the condensed surface leads
/// with "Choose how you continue." plus a value line. Nothing derived from
/// `dailyCommitmentMinutes` renders on a purchase surface any more.
class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  @override
  Future<List<Package>> getOfferings() async => [
        Package(
          'annual',
          PackageType.annual,
          StoreProduct(
            'sakina_sub_annual',
            'Test description',
            'Test title',
            49.99,
            '\$49.99',
            'USD',
          ),
          const PresentedOfferingContext('default', null, null),
        ),
        Package(
          'weekly',
          PackageType.weekly,
          StoreProduct(
            'sakina_sub_weekly',
            'Test description',
            'Test title',
            4.99,
            '\$4.99',
            'USD',
          ),
          const PresentedOfferingContext('default', null, null),
        ),
      ];

  @override
  Future<Map<String, IntroEligibilityStatus>> getIntroEligibility(
    List<String> productIds,
  ) async =>
      const {};
}

void main() {
  setUp(() {
    // REQUIRED, even though these tests read no prefs directly. Under
    // `flutter_test` a `SharedPreferences.getInstance()` with no mock store
    // HANGS rather than throwing, so a try/catch cannot rescue it and the
    // widget awaiting it silently renders nothing. The dismiss path here does
    // await prefs, so without this line adding one ✕ test to this file would
    // hang instead of fail — which reads as a logic bug, not a harness gap.
    SharedPreferences.setMockInitialValues({});
    PurchaseService.debugSetOverride(_FakePurchaseService());
    debugDisablePaywallAnimations = true;
  });

  tearDown(() {
    PurchaseService.debugClearOverride();
    debugDisablePaywallAnimations = false;
  });

  /// The smallest common iPhone logical frame — the one this surface has to
  /// survive, since it arrives mid-task rather than at a ceremony.
  const iphoneFrame = Size(390, 844);

  Future<void> pumpCondensed(
    WidgetTester tester,
    ProviderContainer container, {
    String? softValueLine,
    VoidCallback? onComplete,
  }) async {
    tester.view.physicalSize = iphoneFrame;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PaywallScreen(
            onComplete: onComplete ?? () {},
            placement: PaywallPlacement.softInApp,
            softValueLine: softValueLine,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('soft_inapp renders the condensed screen, not the ceremony',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpCondensed(tester, container);

    expect(find.text(AppStrings.paywallPlanSelectHeadline), findsOneWidget);
    expect(find.text(AppStrings.paywallSoftGateDefaultLine), findsOneWidget);
    // No ceremony pages: the value-depth subline and the trial timeline belong
    // to onboarding only. A user interrupted mid-task gets one screen.
    expect(find.text(AppStrings.paywallValueDepthSubline), findsNothing);
    expect(
      find.text(AppStrings.paywallTrialTimelineTodayHeading),
      findsNothing,
    );
    // One screen means no step rail — there is no ceremony to track.
    expect(find.byType(PaywallStepDots), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the cap-sheet trigger line fits and reads as the destination',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // The real shape W5 Wave D will pass once the weekly pool is authoritative.
    const triggerLine =
        'Your reflections for this week are used — Premium is unlimited.';
    await pumpCondensed(tester, container, softValueLine: triggerLine);

    expect(find.text(triggerLine), findsOneWidget);
    expect(find.text(AppStrings.paywallSoftGateDefaultLine), findsNothing);
    expect(tester.takeException(), isNull,
        reason:
            'a two-line trigger sentence must not overflow the 390pt frame');

    // Everything the decision needs is still on screen with it.
    expect(find.text(AppStrings.paywallPremiumBenefit1), findsOneWidget);
    for (final label in [
      AppStrings.paywallRestore,
      AppStrings.paywallTerms,
      AppStrings.paywallPrivacy,
    ]) {
      final rect = tester.getRect(find.text(label));
      expect(
        (Offset.zero & iphoneFrame).contains(rect.bottomRight),
        isTrue,
        reason: '$label must be reachable without scrolling',
      );
    }
  });

  testWidgets(
      'dismissing the condensed surface goes through the free-tier '
      'card and home', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var completed = false;

    await pumpCondensed(tester, container, onComplete: () => completed = true);

    await tester.tap(find.byType(PaywallCloseButton));
    await tester.pumpAndSettle();

    // The condensed surface shows the plans, annual is selected, the weekly
    // package is loaded and nothing is in flight — every condition of
    // `_eligibleForExitOffer` — so the downsell ALWAYS comes first here.
    // Asserting that rather than tolerating its absence: an `if` here would
    // keep this test green on the day the sheet silently stops firing, which
    // is exactly the regression worth catching.
    expect(
      find.text(AppStrings.paywallExitOfferDecline),
      findsOneWidget,
      reason: 'the ✕ on a priced surface offers weekly before it lets go',
    );
    await tester.tap(find.text(AppStrings.paywallExitOfferDecline));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.paywallAlwaysFreeCardBody), findsOneWidget);
    expect(completed, isFalse);

    await tester.tap(
        find.widgetWithText(OutlinedButton, AppStrings.paywallGateContinue));
    // `pump`, not `pumpAndSettle`: the hand-off shows an indeterminate loader
    // (so the tap has immediate feedback) which by definition never settles.
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('does not render MOST POPULAR badge', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpCondensed(tester, container);

    expect(find.text('MOST POPULAR'), findsNothing);
  });
}
