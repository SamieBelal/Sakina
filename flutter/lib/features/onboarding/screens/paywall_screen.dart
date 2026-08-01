import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/daily/providers/daily_rewards_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/card_collection_service.dart';
import '../../../services/onboarding_gate_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/supabase_sync_service.dart';
import '../../paywall/paywall_offer_view.dart';
import '../../paywall/paywall_placement.dart';
import '../../paywall/trial_offer.dart';
import '../../paywall/widgets/paywall_always_free_card.dart';
import '../../paywall/widgets/paywall_condensed_page.dart';
import '../../paywall/widgets/paywall_exit_offer_sheet.dart';
import '../../paywall/widgets/paywall_gate_page.dart';
import '../../paywall/widgets/paywall_plan_select_page.dart';
import '../../paywall/widgets/paywall_purchase_footer.dart';
import '../../paywall/widgets/paywall_trial_timeline_page.dart';
import '../../paywall/widgets/paywall_value_depth_page.dart';
import '../content/problem_chips.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/premium_celebration_overlay.dart';

/// The gate. One widget, parameterized by [PaywallScreen.placement]:
///
///   * [PaywallPlacement.onboarding] — the approved three-page ceremony,
///     `value_depth` → `trial_timeline` → `plan_select`, front-loaded at the
///     emotional peak right after the reveal.
///   * everything else — a condensed single screen (value line, plans, plain
///     terms). A user interrupted mid-task is not arriving, and making them tap
///     through a ceremony to get back to work is how you teach people to
///     dismiss a gate on sight.
///
/// [PaywallScreen.hardGate] is orthogonal to layout: it removes the ✕ and
/// blocks back, and adds the offerings-failure safety valve.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    required this.onComplete,
    required this.placement,
    this.inOnboardingFlow = true,
    this.hardGate = false,
    this.softValueLine,
    super.key,
  }) : assert(
            !(hardGate && inOnboardingFlow),
            'hardGate is post-onboarding; it must not also run the '
            'completeOnboarding side-effect chain (set inOnboardingFlow: false)');

  final VoidCallback onComplete;

  /// Which paywall surface this instance represents. Its
  /// [PaywallPlacement.analyticsValue] is the `placement` property on every
  /// analytics event the screen emits, so the paywall→purchase funnel is
  /// segmentable per surface.
  ///
  /// REQUIRED with no default (W5 Wave C.1): a new entry point that forgets to
  /// name its surface must fail to compile, not silently report itself as an
  /// in-app upsell. Wave C.2 branches the LAYOUT on it too. Navigate to the
  /// `/paywall` route with `pushPaywall(context, placement: ...)`.
  final PaywallPlacement placement;

  /// When `true`, this is the post-tour HARD ENTRY WALL (decision C4): no close
  /// X, back is blocked, and a successful trial start sets the durable
  /// `onboarding_paywall_cleared` latch so the router lets the user through.
  /// When offerings fail to load, a "Continue" safety valve grants a
  /// session-only bypass (no latch) so a StoreKit outage can't brick a new
  /// user.
  final bool hardGate;

  /// When `true` (the default, onboarding use case), completing a purchase or
  /// restore fires `completeOnboarding` which removes the onboarding prefs,
  /// resets the daily-launch gate, and marks onboarding as finished.
  ///
  /// When `false`, this side-effect chain is skipped — use this when the
  /// paywall is surfaced to an already-onboarded user. Only `onComplete` fires.
  final bool inOnboardingFlow;

  /// Base SharedPreferences key for the dismiss counter. User-scoped via
  /// [SupabaseSyncService.scopedKey] so a shared device doesn't bleed dismiss
  /// state across accounts.
  ///
  /// **Nothing reads this today** (founder, 2026-07-29). It is kept because it
  /// is the exact input a winback surface needs and is already accumulating.
  static const String paywallDismissCountPrefsBaseKey = 'paywall_dismiss_count';

  /// Base key for the once-ever "always free" card. Scoped the same way.
  static const String alwaysFreeCardShownPrefsBaseKey =
      'paywall_always_free_card_shown';

  /// The condensed surface's trigger-specific value line ("Your reflections for
  /// this week are used — Premium is unlimited.").
  ///
  /// Left `null` by every caller today, which renders a line that makes no
  /// claim about the reset period. This is the seam for W5 Wave D: the cap and
  /// warm-up sheets know which feature ran out and under which cohort's reset,
  /// and only they can state it truthfully.
  final String? softValueLine;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

/// The pages the gate can show. The id is the analytics `page_id` — segment by
/// it, never by index: an ineligible user has no `trial_timeline`, so index 1
/// means different pages to different users while the id never does.
enum _GatePage {
  valueDepth(AnalyticsEvents.paywallPageValueDepth),
  trialTimeline(AnalyticsEvents.paywallPageTrialTimeline),
  planSelect(AnalyticsEvents.paywallPagePlanSelect),
  condensed(AnalyticsEvents.paywallPageCondensed);

  const _GatePage(this.pageId);

  final String pageId;
}

/// Test-only seam: disables the gate's entry motion so `pumpAndSettle`
/// returns. Production never sets this.
///
/// A proxy onto [debugDisablePaywallGateMotion], which is what the page
/// widgets read. Kept under the old name because every existing paywall test
/// flips it in `setUp`.
bool get debugDisablePaywallAnimations => debugDisablePaywallGateMotion;

set debugDisablePaywallAnimations(bool value) =>
    debugDisablePaywallGateMotion = value;

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  static const _offeringsErrorMessage =
      'Unable to load subscription options right now. Please try again.';
  static const _purchaseFailedMessage =
      'We couldn\'t complete your purchase. Please try again.';
  static const _restoreFailedMessage =
      'We couldn\'t restore your purchase. Please try again.';
  static const _missingPremiumMessage =
      'Premium access is not active yet. Please try restoring your purchase.';
  static const _missingRestoreEntitlementMessage =
      'No active premium subscription was found to restore.';

  PaywallPlanType _selectedPlan = PaywallPlanType.annual;
  bool _purchasing = false;
  bool _restoring = false;
  String? _errorMessage;
  List<Package>? _offerings;

  /// Per-user intro-offer eligibility keyed by product id. `null` until the
  /// store answers — and `null` renders NON-trial copy, so the window between
  /// mount and answer can never flash a promise we might have to retract.
  Map<String, IntroEligibilityStatus>? _introEligibility;

  /// True once the offerings fetch has failed (empty or threw). Drives the
  /// hard-gate "Continue" safety valve so a load failure can't brick the user.
  bool _offeringsLoadFailed = false;

  /// The page on screen, tracked by IDENTITY rather than by index.
  ///
  /// The page LIST is derived per build from trial eligibility, which resolves
  /// after mount — so it can both shrink and GROW under the user's feet. An
  /// index survives neither: a `trial_timeline` that appears late would slide
  /// in underneath a user already reading `plan_select` and pull them backwards
  /// onto it (and double-count the `plan_select` page view on the way back).
  /// A page that is no longer in the list falls forward to the last one, never
  /// backwards past the decision.
  _GatePage _currentPage = _GatePage.valueDepth;
  String? _lastTrackedPageId;

  /// The exit offer is shown at most once per session. If the user declines
  /// weekly and taps ✕ again, the gate closes — no second nag.
  bool _exitOfferShown = false;

  /// What started the in-flight purchase attempt. Tags the EXISTING
  /// `paywall_cta_tapped` / `purchase_sheet_*` / `trial_started` chain so an
  /// exit-offer conversion is separable from a CTA one without forking the
  /// funnel into parallel events.
  String _purchaseOrigin = AnalyticsEvents.originPaywall;

  /// The one-time "always free" card is on screen; the gate underneath is gone.
  bool _showAlwaysFreeCard = false;

  String get _planName =>
      _selectedPlan == PaywallPlanType.annual ? 'annual' : 'weekly';

  Package? get _annualPackage => _offerings?.cast<Package?>().firstWhere(
        (p) => p!.packageType == PackageType.annual,
        orElse: () => null,
      );

  Package? get _weeklyPackage => _offerings?.cast<Package?>().firstWhere(
        (p) => p!.packageType == PackageType.weekly,
        orElse: () => null,
      );

  Package? get _selectedPackage =>
      _selectedPlan == PaywallPlanType.annual ? _annualPackage : _weeklyPackage;

  bool get _isCeremony => widget.placement == PaywallPlacement.onboarding;

  // ───────────────────────── offer resolution ─────────────────────────

  /// The trial [plan] will ACTUALLY be granted — product offer ∧ this user's
  /// eligibility. `null` means the gate makes no trial promise for that plan.
  TrialOffer? _trialFor(PaywallPlanType plan) {
    final pkg =
        plan == PaywallPlanType.annual ? _annualPackage : _weeklyPackage;
    final product = pkg?.storeProduct;
    if (product == null) return null;
    final offer = TrialOffer.fromProduct(product);
    final eligibility = resolveTrialEligibility(
      productId: product.identifier,
      productHasFreeTrial: offer != null,
      statuses: _introEligibility,
    );
    return eligibility == TrialEligibility.eligible ? offer : null;
  }

  /// Live storefront price for [pkg], falling back to the shipped USD constant
  /// only when offerings have not loaded (test stubs, cold-cache misses).
  String _priceString(Package? pkg, String fallback) =>
      pkg?.storeProduct.priceString ?? fallback;

  /// The annual plan's per-week equivalent in the user's own currency —
  /// `price / 52`, formatted locally. Falls back to the shipped `$0.96`.
  String get _annualPerWeekString {
    final pkg = _annualPackage;
    final price = pkg?.storeProduct.price;
    final code = pkg?.storeProduct.currencyCode;
    if (price == null || price <= 0 || code == null || code.isEmpty) {
      return AppStrings.paywallAnnualPerWeek;
    }
    try {
      final locale = PlatformDispatcher.instance.locale.toLanguageTag();
      final fmt = NumberFormat.simpleCurrency(locale: locale, name: code);
      return fmt.format(price / 52);
    } catch (_) {
      return AppStrings.paywallAnnualPerWeek;
    }
  }

  /// The annual saving against 52× the weekly SKU, or `null` when it cannot be
  /// proved from the live packages.
  ///
  /// Deliberately mirrors [_annualPerWeekString]'s shape but NOT its fallback:
  /// a per-week figure that is stale is merely imprecise, whereas a saving that
  /// is stale is a false claim printed directly above the two numbers it is
  /// derived from. So every failure path returns null and the sticker vanishes.
  ///
  /// Floors rather than rounds. 80.7% renders as "80%", which both preserves
  /// the shipped US string exactly and guarantees the error only ever runs in
  /// the user's favour — we never overstate a discount.
  String? get _annualSavingsLabel {
    final annual = _annualPackage?.storeProduct;
    final weekly = _weeklyPackage?.storeProduct;
    if (annual == null || weekly == null) return null;

    // Comparing across storefront currencies would be arithmetic on unlike
    // units. In practice both packages come from one storefront, so this only
    // ever fires if that assumption breaks — which is exactly when a savings
    // claim must not be made.
    if (annual.currencyCode != weekly.currencyCode) return null;

    final annualPrice = annual.price;
    final weeklyPrice = weekly.price;
    if (annualPrice <= 0 || weeklyPrice <= 0) return null;

    // `toInt`/`floor` THROW on a non-finite double, and this getter runs inside
    // `build()` — an exception here white-screens the gate rather than dropping
    // a sticker. A denormal weekly price whose ×52 underflows to zero is the
    // only way to get there, but the guard costs one line and the failure it
    // prevents is total.
    final ratio = annualPrice / (weeklyPrice * 52);
    if (!ratio.isFinite) return null;

    final percent = ((1 - ratio) * 100).floor();
    // Annual not actually cheaper (a price change, a misconfigured SKU): say
    // nothing rather than "Save 0%" or a negative saving.
    if (percent < 1) return null;

    return AppStrings.paywallPlanAnnualSavingsTemplate
        .replaceAll('{percent}', '$percent');
  }

  PaywallOfferView _buildOffer() {
    final annualPrice =
        _priceString(_annualPackage, AppStrings.paywallAnnualPrice);
    final weeklyPrice =
        _priceString(_weeklyPackage, AppStrings.paywallWeeklyPrice);
    final selectedTrial = _trialFor(_selectedPlan);

    // The terms line follows the SELECTION — it is the only billing statement
    // on the screen, so it may never assume annual.
    final selectedPriceWithPeriod = _selectedPlan == PaywallPlanType.annual
        ? '$annualPrice${AppStrings.paywallAnnualPeriod}'
        : '$weeklyPrice${AppStrings.paywallWeeklyPeriod}';

    return PaywallOfferView(
      annualPriceLine: AppStrings.paywallPlanAnnualPriceTemplate
          .replaceAll('{price}', annualPrice)
          .replaceAll('{perWeek}', _annualPerWeekString),
      annualSavingsLabel: _annualSavingsLabel,
      // The weekly tile names its price and nothing else. It used to append
      // "· {trial} free first", which repeated the CTA directly beneath it and
      // the terms line beneath that — the same promise three times inside one
      // viewport (founder, 2026-08-01).
      weeklyRowLabel: AppStrings.paywallPlanWeeklyRowTemplate
          .replaceAll('{price}', weeklyPrice),
      termsLine: selectedTrial == null
          ? AppStrings.paywallGateTermsNoTrialTemplate
              .replaceAll('{price}', selectedPriceWithPeriod)
          : AppStrings.paywallGateTermsTrialTemplate
              .replaceAll('{trial}', selectedTrial.label)
              .replaceAll('{price}', selectedPriceWithPeriod),
      ctaLabel: selectedTrial == null
          ? AppStrings.paywallCtaSubscribe
          : AppStrings.paywallGateCtaTrialTemplate
              .replaceAll('{trial}', selectedTrial.label),
      trialLabel: selectedTrial?.label,
      trialDays: selectedTrial?.days,
    );
  }

  /// The ceremony drops `trial_timeline` entirely when there is no trial to be
  /// transparent about — an ineligible user must not be walked through a
  /// timeline for something they will not get.
  List<_GatePage> _pagesFor(PaywallOfferView offer) {
    if (!_isCeremony) return const [_GatePage.condensed];
    final days = offer.trialDays;
    return [
      _GatePage.valueDepth,
      if (offer.hasTrial && days != null && days >= 2) _GatePage.trialTimeline,
      _GatePage.planSelect,
    ];
  }

  // ───────────────────────── page-1 content ─────────────────────────

  /// The Name the reveal actually awarded, resolved from the catalog so page 1
  /// can render the SAME card widget the user watched land.
  ///
  /// `revealedPairNameIds` is the source of truth (the reveal falls back to the
  /// comfort pair whenever a deck is missing, and the paywall must echo what
  /// was shown, not what was resolved). `pairNameIds` and `starterNameId` are
  /// the older signals, kept as fallbacks. No match → no card, no Name clause.
  CollectibleName? get _revealedCard {
    final s = ref.read(onboardingProvider);
    final id = s.revealedPairNameIds.isNotEmpty
        ? s.revealedPairNameIds.first
        : (s.pairNameIds.isNotEmpty ? s.pairNameIds.first : s.starterNameId);
    if (id == null) return null;
    for (final card in allCollectibleNames) {
      if (card.id == id) return card;
    }
    return null;
  }

  bool get _isSignContract =>
      ref.read(onboardingProvider).contract == HookContract.sign;

  // ───────────────────────── lifecycle ─────────────────────────

  @override
  void initState() {
    super.initState();
    // Single source of truth for paywall_viewed across ALL surfaces.
    try {
      ref.read(analyticsProvider).track(
        AnalyticsEvents.paywallViewed,
        properties: {
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
          'hard_gate': widget.hardGate,
        },
      );
    } catch (_) {}
    if (widget.placement == PaywallPlacement.postTrialSoft) {
      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.trialPaywallSurfaced,
          properties: {
            AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
            AnalyticsEvents.propArm: ref.read(appSessionProvider).paywallArm,
            AnalyticsEvents.propHardGate: false,
          },
        );
      } catch (_) {}
    }
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    List<Package> offerings;
    try {
      offerings = await PurchaseService().getOfferings();
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _offeringsErrorMessage;
          _markOfferingsFailed();
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      // An empty list means the current offering is misconfigured or the cold
      // cache returned nothing. Surface the error up front so the user doesn't
      // tap a CTA that looks priced only to see an error afterwards.
      if (offerings.isEmpty) {
        _errorMessage = _offeringsErrorMessage;
        _markOfferingsFailed();
      }
    });

    // Per-USER eligibility, second: it needs the product ids, and it is the
    // difference between "this product has a trial" and "you get one".
    final productIds = offerings
        .map((p) => p.storeProduct.identifier)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (productIds.isEmpty) {
      if (mounted) setState(() => _introEligibility = const {});
      return;
    }
    final statuses = await PurchaseService().getIntroEligibility(productIds);
    if (!mounted) return;
    setState(() => _introEligibility = statuses);
  }

  /// Records that the offerings fetch failed so the hard-gate safety valve can
  /// render. Fires [AnalyticsEvents.paywallOfferingsLoadFailed] exactly once.
  /// Call inside a `setState`.
  void _markOfferingsFailed() {
    if (_offeringsLoadFailed) return;
    _offeringsLoadFailed = true;
    if (widget.hardGate) {
      ref
          .read(analyticsProvider)
          .track(AnalyticsEvents.paywallOfferingsLoadFailed);
    }
  }

  void _trackPageViewed(_GatePage page) {
    if (_lastTrackedPageId == page.pageId) return;
    _lastTrackedPageId = page.pageId;
    try {
      ref.read(analyticsProvider).track(
        AnalyticsEvents.paywallPageViewed,
        properties: {
          AnalyticsEvents.propPageId: page.pageId,
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
        },
      );
    } catch (_) {}
  }

  /// Hard-gate offerings-fail safety valve: grant a SESSION-ONLY bypass (no
  /// durable latch) so a StoreKit/Apple outage can't brick a brand-new user.
  void _continueViaValve() {
    try {
      ref.read(analyticsProvider).track(
        AnalyticsEvents.paywallSafetyValveUsed,
        properties: {
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue
        },
      );
    } catch (_) {}
    ref.read(appSessionProvider).bypassGateForSession();
    widget.onComplete();
  }

  Future<void> _handleComplete() async {
    if (widget.inOnboardingFlow) {
      final notifier = ref.read(onboardingProvider.notifier);
      try {
        await notifier.completeOnboarding(ref.read(appSessionProvider));
      } catch (_) {}
    }
    if (widget.hardGate) {
      try {
        await OnboardingGateService().setPaywallCleared(true);
      } catch (_) {}
      try {
        ref.read(appSessionProvider).markPaywallCleared();
      } catch (_) {}
    }
    widget.onComplete();
  }

  // ───────────────────────── dismissal ─────────────────────────

  /// Whether this paywall instance is the post-tour soft gate (either arm's
  /// surface). Drives the `soft_gate_dismissed` emission on X / dismiss.
  bool get _isPostTourSoftGate => widget.placement.isPostTourSoftGate;

  /// Whether tapping ✕ right now should offer weekly first.
  ///
  /// Reproduces the pre-W5 gate exactly: never shown twice in a session,
  /// annual currently selected, the weekly SKU loaded, nothing in flight.
  ///
  /// The one addition is [_plansAreVisible], and it is a faithfulness
  /// condition rather than a new restriction. Before W5 the ✕ only ever
  /// existed on a screen that was showing the plan cards, so a weekly
  /// downsell always answered a price the user had just seen. The ceremony's
  /// first two pages show no prices at all — firing it there would put the
  /// offer somewhere it has never been, which is expanding its reach, not
  /// preserving it.
  bool get _eligibleForExitOffer =>
      !_exitOfferShown &&
      _plansAreVisible &&
      _selectedPlan == PaywallPlanType.annual &&
      _weeklyPackage != null &&
      !_purchasing &&
      !_restoring;

  /// True when the page on screen is showing the plan chooser — `plan_select`
  /// on the ceremony, or the condensed single screen.
  bool _plansAreVisible = false;

  /// ✕ → the exit offer (once per session, on the plan page) → the one-time
  /// "always free" card → home.
  ///
  /// KNOWN DIVERGENCE from the approved draft, taken deliberately by the
  /// founder on 2026-07-31: the draft says "✕ → home directly" and its
  /// firewall self-check says "scarcity: none (no offers in v1)". The sheet is
  /// kept anyway because it has been shipping unmeasured, and deleting an
  /// unmeasured conversion mechanic is a revenue decision made blind. It is now
  /// instrumented end to end (shown / accepted / declined, plus
  /// [AnalyticsEvents.propOrigin] through the purchase chain) so the next call
  /// on it is made with data.
  Future<void> _handleClose() async {
    if (_eligibleForExitOffer) {
      await _showExitOffer();
      return;
    }
    await _doClose();
  }

  Future<void> _showExitOffer() async {
    setState(() => _exitOfferShown = true);
    _trackExitOffer(AnalyticsEvents.paywallExitOfferShown);

    final outcome = await showModalBottomSheet<PaywallExitOfferOutcome>(
      context: context,
      isScrollControlled: false,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PaywallExitOfferSheet(
        weeklyPrice: _priceString(_weeklyPackage, AppStrings.paywallWeeklyPrice),
        // `labelAdjective`, not `label` — this sheet's two strings pre-date the
        // approved draft and have ADJECTIVE slots ("Start {trial} free trial"),
        // where the noun form renders "Start 3 days free trial". Every approved
        // string has a noun slot and correctly uses `label`.
        trialLabel: _trialFor(PaywallPlanType.weekly)?.labelAdjective,
      ),
      // A scrim tap and a back gesture both pop with no value. Mapping that to
      // `dismissed` here — rather than letting it fall through as null — is what
      // guarantees every route out of the sheet emits a decline. A decline path
      // that misses an exit understates declines and flatters the mechanic.
    ) ??
        PaywallExitOfferOutcome.dismissed;

    if (!mounted) return;

    switch (outcome) {
      case PaywallExitOfferOutcome.accepted:
        _trackExitOffer(AnalyticsEvents.paywallExitOfferAccepted);
        setState(() {
          _selectedPlan = PaywallPlanType.weekly;
          // Accepting only means the CTA was tapped. Tagging the origin here
          // means the EXISTING purchase chain carries it all the way to
          // `trial_started`, so an exit offer that is accepted and then
          // abandoned at the StoreKit sheet cannot look like it earned money.
          _purchaseOrigin = AnalyticsEvents.originExitOffer;
        });
        await _handlePurchase();
      case PaywallExitOfferOutcome.declinedByButton:
        _trackExitOffer(
          AnalyticsEvents.paywallExitOfferDeclined,
          route: AnalyticsEvents.dismissRouteButton,
        );
        await _doClose();
      case PaywallExitOfferOutcome.dismissed:
        // Still a decline for measurement, but the user goes back to the
        // paywall rather than out of it — unchanged pre-W5 behaviour.
        _trackExitOffer(
          AnalyticsEvents.paywallExitOfferDeclined,
          route: AnalyticsEvents.dismissRouteDismissed,
        );
    }
  }

  void _trackExitOffer(String event, {String? route}) {
    try {
      ref.read(analyticsProvider).track(
        event,
        properties: {
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
          if (route != null) AnalyticsEvents.propDismissRoute: route,
        },
      );
    } catch (_) {}
  }

  Future<void> _doClose() async {
    // Wrapped like every other emission on this path. `_doClose` is reached
    // from an UNAWAITED tap handler, so a throw anywhere in it aborts the
    // dismissal silently — the same shape as the `scopedKey` bug below, and
    // the reason no bookkeeping on the escape hatch may be left bare.
    try {
      // `placement` is NOT optional here. This is the only dismissal event that
      // fires from every placement — `soft_gate_dismissed` below is gated on
      // `_isPostTourSoftGate`, so onboarding / hard_wall / soft_inapp /
      // post_trial_soft closes are visible ONLY through this event. Without the
      // property every one of them collapses into a single unattributable
      // bucket, and it cannot be backfilled: Mixpanel only populates a property
      // from the release that started sending it.
      ref.read(analyticsProvider).track(
        AnalyticsEvents.paywallClosed,
        properties: {
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
        },
      );
    } catch (_) {}

    if (_isPostTourSoftGate) {
      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.softGateDismissed,
          properties: {
            AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
            AnalyticsEvents.propArm: ref.read(appSessionProvider).paywallArm,
          },
        );
      } catch (_) {}
    }

    // BOOKKEEPING MUST NEVER TRAP THE USER. Everything below is a counter and
    // a once-ever flag; none of it is the reason the ✕ exists. `scopedKey`
    // reads `Supabase.instance`, which throws if the client is not up yet, and
    // a throw here would abort the dismiss silently — the user taps ✕ and
    // nothing happens, on the one screen where being stuck is unforgivable.
    // So a failure degrades to "show the card" rather than to "do nothing".
    var alreadyShown = false;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final countKey = supabaseSyncService
          .scopedKey(PaywallScreen.paywallDismissCountPrefsBaseKey);
      await prefs.setInt(countKey, (prefs.getInt(countKey) ?? 0) + 1);
      alreadyShown = prefs.getBool(
            supabaseSyncService
                .scopedKey(PaywallScreen.alwaysFreeCardShownPrefsBaseKey),
          ) ??
          false;
    } catch (_) {}

    if (alreadyShown) {
      widget.onComplete();
      return;
    }
    try {
      await prefs?.setBool(
        supabaseSyncService
            .scopedKey(PaywallScreen.alwaysFreeCardShownPrefsBaseKey),
        true,
      );
    } catch (_) {}
    try {
      ref.read(analyticsProvider).track(
        AnalyticsEvents.freeTierEntered,
        properties: {
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
        },
      );
    } catch (_) {}
    if (!mounted) {
      widget.onComplete();
      return;
    }
    setState(() => _showAlwaysFreeCard = true);
  }

  // ───────────────────────── purchase ─────────────────────────

  Future<void> _completePurchaseFlow() async {
    ref.invalidate(premiumStateProvider);

    // Premium retro-bump: promote any Gold cards to Emerald in this session.
    // Fire-and-forget — must never block or fail the purchase flow.
    unawaited(reconcilePremiumEmeralds().catchError((_) => 0));

    // HARD GATE: persist the durable entry latch NOW, BEFORE the (blocking,
    // dismissable) celebration overlay, so an unmount mid-overlay can't leave
    // a just-paid user re-walled. Idempotent with the `_handleComplete` set.
    if (widget.hardGate) {
      try {
        await OnboardingGateService().setPaywallCleared(true);
      } catch (_) {}
      try {
        ref.read(appSessionProvider).markPaywallCleared();
      } catch (_) {}
    }

    if (!mounted) return;

    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const PremiumCelebrationOverlay(
          userName: '',
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    if (!mounted) return;
    await _handleComplete();
  }

  Future<void> _handlePurchase() async {
    if (_purchasing) return;
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.paywallCtaTapped, properties: {
      'plan': _planName,
      AnalyticsEvents.propOrigin: _purchaseOrigin,
      AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
    });
    HapticFeedback.mediumImpact();
    setState(() {
      _purchasing = true;
      _errorMessage = null;
    });

    try {
      final offerings = _offerings;
      if (offerings == null || offerings.isEmpty) {
        if (mounted) setState(() => _errorMessage = _offeringsErrorMessage);
        return;
      }

      final selectedPackage = _selectedPackage;
      if (selectedPackage == null) {
        if (mounted) setState(() => _errorMessage = _offeringsErrorMessage);
        return;
      }

      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.purchaseSheetPresented,
          properties: {
            AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
            'plan': _planName,
            AnalyticsEvents.propOrigin: _purchaseOrigin,
          },
        );
      } catch (_) {}

      final premiumActive =
          await PurchaseService().purchaseSubscription(selectedPackage);
      if (!premiumActive) {
        // Sheet completed but entitlement is not active — treat as a failure so
        // the CTA→trial funnel reconciles.
        try {
          ref.read(analyticsProvider).track(
            AnalyticsEvents.purchaseSheetFailed,
            properties: {
              AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
              'plan': _planName,
              AnalyticsEvents.propOrigin: _purchaseOrigin,
              'reason': 'entitlement_inactive',
            },
          );
        } catch (_) {}
        if (mounted) setState(() => _errorMessage = _missingPremiumMessage);
        return;
      }

      // Which event this is depends on whether a trial was actually granted.
      // `_trialFor` is the same resolution the CTA renders from, so the event
      // and the button the user pressed can never disagree: someone who saw
      // "Subscribe" and was charged immediately is not a trial start. Firing
      // `trial_started` for them inflated trial-start rate, deflated
      // trial-to-paid conversion, and mis-attributed the exit offer — the
      // three numbers the W5 keep decision reads.
      final grantedTrial = _trialFor(_selectedPlan) != null;
      ref.read(analyticsProvider).track(
        grantedTrial
            ? AnalyticsEvents.trialStarted
            : AnalyticsEvents.subscriptionStartedNoTrial,
        properties: {
          'plan': _planName,
          AnalyticsEvents.propOrigin: _purchaseOrigin,
          'hard_gate': widget.hardGate,
          AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
        },
      );

      if (!mounted) return;
      await _completePurchaseFlow();
    } on PlatformException catch (error) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        try {
          ref.read(analyticsProvider).track(
            AnalyticsEvents.purchaseSheetCancelled,
            properties: {
              AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
              'plan': _planName,
              AnalyticsEvents.propOrigin: _purchaseOrigin,
            },
          );
        } catch (_) {}
      } else {
        try {
          ref.read(analyticsProvider).track(
            AnalyticsEvents.purchaseSheetFailed,
            properties: {
              AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
              'plan': _planName,
              AnalyticsEvents.propOrigin: _purchaseOrigin,
              'reason': errorCode.toString(),
            },
          );
        } catch (_) {}
        if (mounted) setState(() => _errorMessage = _purchaseFailedMessage);
      }
    } catch (e) {
      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.purchaseSheetFailed,
          properties: {
            AnalyticsEvents.propPlacement: widget.placement.analyticsValue,
            'plan': _planName,
            AnalyticsEvents.propOrigin: _purchaseOrigin,
            'reason': e.runtimeType.toString(),
          },
        );
      } catch (_) {}
      if (mounted) setState(() => _errorMessage = _purchaseFailedMessage);
    } finally {
      // The origin belongs to ONE attempt. Leaving it latched would credit the
      // exit offer with the next purchase the user starts from the gate's own
      // CTA — inflating precisely the number D11 kept the sheet in order to
      // measure. Whoever starts an attempt sets it; every attempt resets it.
      _purchaseOrigin = AnalyticsEvents.originPaywall;
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _handleRestore() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _errorMessage = null;
    });

    // W6 Wave C #5 — this surface had ZERO analytics. A silently-failing
    // restore was indistinguishable from nobody tapping it, on a path that is
    // both a churn risk and a support burden. Wrapped like every other
    // emission on this screen — a throw here must never abort the restore.
    try {
      ref.read(analyticsProvider).track(AnalyticsEvents.restoreStarted);
    } catch (_) {}

    try {
      final premiumActive = await PurchaseService().restorePurchases();
      // Completed either way — a restore that finds NO entitlement is a
      // genuinely different outcome from one that finds a subscription, and
      // must not collapse into the same signal as a thrown error below.
      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.restoreCompleted,
          properties: {AnalyticsEvents.propPremiumActive: premiumActive},
        );
      } catch (_) {}
      if (!premiumActive) {
        if (mounted) {
          setState(() => _errorMessage = _missingRestoreEntitlementMessage);
        }
        return;
      }
      if (!mounted) return;
      await _completePurchaseFlow();
    } catch (_) {
      try {
        ref.read(analyticsProvider).track(
          AnalyticsEvents.restoreFailed,
          properties: {
            AnalyticsEvents.propReason:
                AnalyticsEvents.storePurchaseFailedReasonUnknown,
          },
        );
      } catch (_) {}
      if (mounted) setState(() => _errorMessage = _restoreFailedMessage);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: kSnackBarDuration,
          content: Text('Could not open the page. Try again.'),
        ),
      );
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final offer = _buildOffer();
    final pages = _pagesFor(offer);
    // Eligibility resolving late can lengthen OR shorten the list under the
    // user's feet; resolve by identity so neither moves them.
    final found = pages.indexOf(_currentPage);
    final index = found >= 0 ? found : pages.length - 1;
    final page = pages[index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_showAlwaysFreeCard) _trackPageViewed(page);
    });

    final busy = _purchasing || _restoring;
    final isLastPage = index == pages.length - 1;
    // The plan chooser and the purchase footer live on the same (last) page,
    // so this is also "the user can see a price right now" — the condition the
    // exit offer has always implicitly had. Assigned during build rather than
    // derived in the handler so it cannot drift from what is actually drawn.
    _plansAreVisible = isLastPage;

    return PopScope(
      // HARD GATE: block the system back gesture / Android back button so the
      // user can't escape the entry wall without converting or using the valve.
      canPop: !widget.hardGate,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: _showAlwaysFreeCard
            ? PaywallAlwaysFreeCard(onContinue: widget.onComplete)
            : PaywallGatePage(
                stepCount: pages.length > 1 ? pages.length : 0,
                stepIndex: index,
                onClose: widget.hardGate || busy ? null : _handleClose,
                body: switch (page) {
                  _GatePage.valueDepth => PaywallValueDepthPage(
                      nameTransliteration: _revealedCard?.transliteration,
                      isSignContract: _isSignContract,
                      card: _revealedCard,
                    ),
                  _GatePage.trialTimeline => PaywallTrialTimelinePage(
                      trialLabel: offer.trialLabel!,
                      trialDays: offer.trialDays!,
                    ),
                  _GatePage.planSelect => PaywallPlanSelectPage(
                      offer: offer,
                      selectedPlan: _selectedPlan,
                      onSelectPlan: _selectPlan,
                    ),
                  _GatePage.condensed => PaywallCondensedPage(
                      offer: offer,
                      selectedPlan: _selectedPlan,
                      onSelectPlan: _selectPlan,
                      valueLine: widget.softValueLine,
                    ),
                },
                footer: isLastPage
                    ? PaywallPurchaseFooter(
                        ctaLabel: offer.ctaLabel,
                        termsLine: offer.termsLine,
                        onPurchase: _handlePurchase,
                        onRestore: busy ? null : _handleRestore,
                        onOpenTerms: () =>
                            _openLegalUrl(AppStrings.termsOfServiceUrl),
                        onOpenPrivacy: () =>
                            _openLegalUrl(AppStrings.privacyPolicyUrl),
                        busy: busy,
                        restoring: _restoring,
                        errorMessage: _errorMessage,
                        extra: widget.hardGate && _offeringsLoadFailed
                            ? TextButton(
                                onPressed: busy ? null : _continueViaValve,
                                child: const Text(
                                  AppStrings.paywallGateContinue,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              )
                            : null,
                      )
                    : _CeremonyFooter(
                        footnote: page == _GatePage.trialTimeline
                            ? AppStrings.paywallTrialTimelineFootnote
                            : null,
                        onContinue: () =>
                            setState(() => _currentPage = pages[index + 1]),
                      ),
              ),
      ),
    );
  }

  void _selectPlan(PaywallPlanType plan) {
    setState(() => _selectedPlan = plan);
    ref.read(analyticsProvider).track(
      AnalyticsEvents.paywallPlanSelected,
      properties: {'plan': _planName},
    );
  }
}

/// The footer on the ceremony's non-final pages: an optional reassurance line
/// (which belongs beside the action, not floating in the page's dead middle)
/// and Continue.
class _CeremonyFooter extends StatelessWidget {
  const _CeremonyFooter({required this.onContinue, this.footnote});

  final VoidCallback onContinue;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              footnote!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              AppStrings.paywallGateContinue,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.17,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
