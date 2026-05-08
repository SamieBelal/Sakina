import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/app_session.dart';
import '../../../features/daily/providers/daily_rewards_provider.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/purchase_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/premium_celebration_overlay.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    required this.onComplete,
    this.inOnboardingFlow = true,
    super.key,
  });

  final VoidCallback onComplete;

  /// When `true` (the default, onboarding use case), completing a purchase or
  /// restore fires `completeOnboarding` which removes the onboarding prefs,
  /// resets the daily-launch gate, and marks onboarding as finished.
  ///
  /// When `false`, this side-effect chain is skipped — use this when the
  /// paywall is surfaced to an already-onboarded user (e.g. via the
  /// journal-save upgrade sheet). Only `onComplete` fires in that case.
  final bool inOnboardingFlow;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

enum _PlanType { annual, weekly }

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

  _PlanType _selectedPlan = _PlanType.annual;
  bool _purchasing = false;
  bool _restoring = false;
  String? _errorMessage;
  List<Package>? _offerings;

  // Delayed close-button enable. The X fades in (and becomes tappable) after
  // 3s so the user takes a real look at the offer before dismissing — a
  // well-established paywall best practice that lifts conversion without
  // hiding the dismiss path entirely (App Review requires a clear close).
  bool _canClose = false;
  Timer? _closeButtonTimer;
  static const _closeButtonRevealDelay = Duration(seconds: 3);

  // Exit offer shown at most once per session. If the user declines weekly
  // and taps X again, we close immediately — no second nag.
  bool _exitOfferShown = false;

  String get _planName => _selectedPlan == _PlanType.annual ? 'annual' : 'weekly';

  // Trimmed to 3. Audio recitation (benefit2) is secondary to the core
  // emotion → Name → verse loop, so it's the cut. Cal AI / Hallow / Calm
  // all show 3 short benefits max.
  static const _benefits = [
    AppStrings.paywallBenefit1,
    AppStrings.paywallBenefit3,
    AppStrings.paywallBenefit4,
  ];

  PackageType get _selectedPackageType => _selectedPlan == _PlanType.annual
      ? PackageType.annual
      : PackageType.weekly;

  Package? get _annualPackage => _offerings?.cast<Package?>().firstWhere(
        (p) => p!.packageType == PackageType.annual,
        orElse: () => null,
      );

  Package? get _weeklyPackage => _offerings?.cast<Package?>().firstWhere(
        (p) => p!.packageType == PackageType.weekly,
        orElse: () => null,
      );

  /// Locale-aware "was X" anchor price for the annual card. Computed as
  /// 2x the actual annual price in the user's storefront currency, rounded
  /// to a clean .99 ending (or whole units for 0-decimal currencies like
  /// JPY/KRW). Returns null when offerings haven't loaded — the card hides
  /// the strikethrough rather than showing a USD anchor next to a non-USD
  /// price, which would look broken.
  ///
  /// Examples (post-format):
  ///   US  $49.99/yr → "$99.99"
  ///   UK  £39.99/yr → "£79.99"
  ///   JP  ¥7,800/yr → "¥15,600"
  ///   IN  ₹3,499/yr → "₹6,999"
  ///
  /// This is the canonical pattern: doubling the live price keeps the
  /// 50% off framing identical across every storefront, so the SAVE 50%
  /// badge stays mathematically consistent with the strikethrough no
  /// matter where the user is.
  String? get _annualAnchorPrice {
    final pkg = _annualPackage;
    if (pkg == null) return null;
    final price = pkg.storeProduct.price;
    final code = pkg.storeProduct.currencyCode;
    if (price <= 0 || code.isEmpty) return null;
    try {
      final locale = PlatformDispatcher.instance.locale.toLanguageTag();
      final fmt = NumberFormat.simpleCurrency(locale: locale, name: code);
      final decimals = fmt.decimalDigits ?? 2;
      // For 2-decimal currencies, force a .99 psychological ending. For
      // 0-decimal currencies (JPY, KRW, IDR…) the doubled value is already
      // an integer.
      final anchor = decimals > 0
          ? (price * 2).floorToDouble() + 0.99
          : (price * 2).roundToDouble();
      return fmt.format(anchor);
    } catch (_) {
      // Unknown currency code or formatter init failure — hide the
      // strikethrough rather than risk showing a wrong-currency string.
      return null;
    }
  }

  /// Locale-aware "Save $X" amount paired with [_annualAnchorPrice].
  /// Always equals `anchor - price` so the math is internally consistent
  /// across every storefront. Rounded to whole units for clean reading
  /// ("Save $50", "Save £40", "Save ¥7,800"). Returns null when offerings
  /// haven't loaded — UI hides the savings tag rather than guessing.
  String? get _annualSavingsAmount {
    final pkg = _annualPackage;
    if (pkg == null) return null;
    final price = pkg.storeProduct.price;
    final code = pkg.storeProduct.currencyCode;
    if (price <= 0 || code.isEmpty) return null;
    try {
      final locale = PlatformDispatcher.instance.locale.toLanguageTag();
      final fmt = NumberFormat.simpleCurrency(locale: locale, name: code);
      final decimals = fmt.decimalDigits ?? 2;
      final anchor = decimals > 0
          ? (price * 2).floorToDouble() + 0.99
          : (price * 2).roundToDouble();
      // Round to clean whole units — "Save $50.00" reads worse than
      // "Save $50". Use a 0-decimal formatter for the savings string.
      final savings = (anchor - price).roundToDouble();
      final wholeFmt = NumberFormat.simpleCurrency(
        locale: locale,
        name: code,
        decimalDigits: 0,
      );
      return wholeFmt.format(savings);
    } catch (_) {
      return null;
    }
  }

  /// True when the StoreKit/RevenueCat product for [plan] has a free
  /// introductory offer (price == 0). When false, StoreKit will charge
  /// immediately on tap, so we hide the trial timeline and switch the CTA
  /// from "Start Free Trial" to "Subscribe" — the paywall must not promise
  /// a trial the OS won't grant. Configure introductory offers in App Store
  /// Connect (Subscriptions → product → Introductory Offers) and Google
  /// Play Console for this to flip true in production.
  bool _planHasTrial(_PlanType plan) {
    final pkg = plan == _PlanType.annual ? _annualPackage : _weeklyPackage;
    final intro = pkg?.storeProduct.introductoryPrice;
    return intro != null && intro.price == 0;
  }

  @override
  void initState() {
    super.initState();
    _closeButtonTimer = Timer(_closeButtonRevealDelay, () {
      if (mounted) setState(() => _canClose = true);
    });
    _loadOfferings();
  }

  @override
  void dispose() {
    _closeButtonTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await PurchaseService().getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          // An empty list means the current offering is misconfigured or the
          // cold cache returned nothing. Surface the error up front so the
          // user doesn't tap a CTA that looks priced (via the static fallback
          // strings) only to see an error afterwards.
          if (offerings.isEmpty) {
            _errorMessage = _offeringsErrorMessage;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _offeringsErrorMessage;
        });
      }
    }
  }

  Future<void> _handleComplete() async {
    if (widget.inOnboardingFlow) {
      final notifier = ref.read(onboardingProvider.notifier);
      try {
        await notifier.completeOnboarding(ref.read(appSessionProvider));
      } catch (_) {}
    }
    widget.onComplete();
  }

  Future<void> _handleClose() async {
    // Eligible for the exit offer: never shown this session, currently
    // looking at annual, weekly SKU is loaded, and we're not mid-flight.
    final eligibleForExitOffer = !_exitOfferShown &&
        _selectedPlan == _PlanType.annual &&
        _weeklyPackage != null &&
        !_purchasing &&
        !_restoring;
    if (eligibleForExitOffer) {
      await _showExitOffer();
      return;
    }
    _doClose();
  }

  void _doClose() {
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallClosed);
    widget.onComplete();
  }

  Future<void> _showExitOffer() async {
    setState(() => _exitOfferShown = true);
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallExitOfferShown);
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ExitOfferSheet(
        weeklyPrice: _weeklyPackage?.storeProduct.priceString ??
            AppStrings.paywallWeeklyPrice,
        weeklyHasTrial: _planHasTrial(_PlanType.weekly),
      ),
    );
    if (!mounted) return;
    if (accepted == true) {
      ref
          .read(analyticsProvider)
          .track(AnalyticsEvents.paywallExitOfferAccepted);
      setState(() => _selectedPlan = _PlanType.weekly);
      await _handlePurchase();
    } else if (accepted == false) {
      _doClose();
    }
  }

  String _personalizedHeadline() {
    final s = ref.read(onboardingProvider);
    final aspiration =
        switch (s.aspirations.isNotEmpty ? s.aspirations.first : '') {
      'morePatient' => 'more patient',
      'moreGrateful' => 'more grateful',
      'closerToAllah' => 'closer to Allah',
      'morePresent' => 'more present',
      'strongerFaith' => 'stronger in faith',
      'moreConsistent' => 'more consistent',
      // Shorter fallback so the headline still wraps to 2 lines (not 3).
      // "the person you want to be" was the longest variant and the only
      // one that pushed the layout off-screen.
      _ => 'your best self',
    };
    final mins = s.dailyCommitmentMinutes ?? 3;
    final minLabel = mins == 1 ? '1 minute' : '$mins minutes';
    // Reframe so the time is the commitment, not the deadline. The old
    // shape ("Become X in 3 min a day") read as if the user becomes X
    // *within* 3 minutes — wrong scope. New shape leads with the daily
    // promise: "$mins minutes a day to become X."
    return 'Just $minLabel a day to become $aspiration.';
  }

  Package? _findSelectedPackage(List<Package> offerings) {
    for (final package in offerings) {
      if (package.packageType == _selectedPackageType) {
        return package;
      }
    }
    return null;
  }

  Future<void> _completePurchaseFlow() async {
    ref.invalidate(isPremiumProvider);
    if (!mounted) return;

    // Show the "Welcome to Premium" reveal (blocks until tapped).
    // If the user kills the app mid-overlay, isPremiumProvider already returns
    // true on next launch from RevenueCat's cache, so premium UI renders
    // correctly without the reveal.
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
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallCtaTapped, properties: {'plan': _planName});
    HapticFeedback.mediumImpact();
    setState(() {
      _purchasing = true;
      _errorMessage = null;
    });

    try {
      final offerings = _offerings;
      if (offerings == null || offerings.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = _offeringsErrorMessage;
          });
        }
        return;
      }

      final selectedPackage = _findSelectedPackage(offerings);
      if (selectedPackage == null) {
        if (mounted) {
          setState(() {
            _errorMessage = _offeringsErrorMessage;
          });
        }
        return;
      }

      final premiumActive =
          await PurchaseService().purchaseSubscription(selectedPackage);
      if (!premiumActive) {
        if (mounted) {
          setState(() {
            _errorMessage = _missingPremiumMessage;
          });
        }
        return;
      }

      if (!mounted) return;
      await _completePurchaseFlow();
    } on PlatformException catch (error) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError && mounted) {
        setState(() {
          _errorMessage = _purchaseFailedMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _purchaseFailedMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
        });
      }
    }
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the page. Try again.')),
      );
    }
  }

  Future<void> _handleRestore() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _errorMessage = null;
    });

    try {
      final premiumActive = await PurchaseService().restorePurchases();
      if (!premiumActive) {
        if (mounted) {
          setState(() {
            _errorMessage = _missingRestoreEntitlementMessage;
          });
        }
        return;
      }

      if (!mounted) return;
      await _completePurchaseFlow();
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = _restoreFailedMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTrial = _planHasTrial(_selectedPlan);
    final mediaQueryPadding = MediaQuery.of(context).padding;
    return Scaffold(
      // Match the image's warm-cream top so any 1px banding between the
      // status-bar area and the hero is invisible. The page background
      // is the same cream — both blend.
      backgroundColor: AppColors.backgroundLight,
      // No SafeArea wrapper at the top — the hero image bleeds into the
      // status-bar region for that "edge-to-edge" treatment Cal AI / Hallow
      // use. Top safe-area padding is re-added below where it matters
      // (close X position) instead of as a global child constraint.
      body: Stack(
          children: [
            // Main scrollable content. The hero block bleeds full-width past
            // the page padding for visual impact; everything else respects
            // the standard horizontal page padding via inner wrappers.
            //
            // LayoutBuilder + ConstrainedBox(minHeight) + IntrinsicHeight
            // gives the inner Column bounded vertical space equal to at
            // least the viewport height, which lets the Spacer below the
            // pricing cards push the CTA + legal block down so it sits
            // vertically centered in the remaining cream space.
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                  const _PaywallHero(),

                  // Breathing room between the hero's faded tail and the
                  // headline. Without this the body content reads as
                  // jammed against the image instead of as a separate
                  // section that flows naturally below it.
                  const SizedBox(height: AppSpacing.sm),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Small gold all-caps line above the aspiration headline.
                        // Personalized with the user's first name when available
                        // (post 2026-05-05 redesign).
                        Text(
                          AppStrings.paywallPersonalizedHeaderTemplate.replaceAll(
                            '{name}',
                            () {
                              final n = ref.read(onboardingProvider).signUpName;
                              return (n != null && n.isNotEmpty) ? n : 'friend';
                            }(),
                          ),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Personalized headline — DM Serif Display.
                        Text(
                          _personalizedHeadline(),
                          style: AppTypography.displaySmall.copyWith(
                            color: AppColors.textPrimaryLight,
                            height: 1.12,
                            fontSize: 26,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 3 benefit rows — staggered fade/slide on first
                        // paint so the eye lands here after the hero.
                        ...List.generate(_benefits.length, (i) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryLight,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: Text(
                                    _benefits[i],
                                    style:
                                        AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimaryLight,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 90 * i + 120),
                                duration: 380.ms,
                              )
                              .slideX(
                                begin: -0.04,
                                end: 0,
                                delay: Duration(milliseconds: 90 * i + 120),
                                duration: 380.ms,
                              );
                        }),
                        const SizedBox(height: AppSpacing.md),

                        // Honest trial timeline — only when the selected
                        // plan actually has a free intro on its StoreKit
                        // product. Otherwise the timeline would lie about
                        // a "Day 3 charged" event that won't happen.
                        if (hasTrial) ...[
                          _TrialTimelineStrip(
                            chargeOnDay3:
                                _selectedPlan == _PlanType.annual
                                    ? (_annualPackage
                                            ?.storeProduct.priceString ??
                                        AppStrings.paywallAnnualPrice)
                                    : (_weeklyPackage
                                            ?.storeProduct.priceString ??
                                        AppStrings.paywallWeeklyPrice),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Side-by-side pricing — Cal AI pattern. Annual on
                        // the left (default-selected, "best value"), weekly
                        // on the right.
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _PricingCard(
                                  label: AppStrings.paywallAnnualLabel,
                                  mainPrice: _annualPackage
                                          ?.storeProduct.priceString ??
                                      AppStrings.paywallAnnualPrice,
                                  mainPriceLabel: 'per year',
                                  // Locale-aware marketing anchor: 2x the
                                  // live storefront price, formatted in the
                                  // user's currency (e.g. $99.99, £79.99,
                                  // ¥15,600). Pairs 1:1 with SAVE 50% badge
                                  // in every storefront. Null until the
                                  // package loads — strikethrough hides
                                  // rather than showing a wrong-currency
                                  // fallback.
                                  strikethroughPrice: _annualAnchorPrice,
                                  // Inline "Save $X" callout next to the
                                  // strike. Computed alongside the anchor
                                  // so the math always agrees. Hidden when
                                  // the package isn't loaded.
                                  savingsAmount: _annualSavingsAmount,
                                  // Per-week breakdown — Cal AI's value
                                  // framing. Makes annual feel cheap
                                  // relative to weekly.
                                  footerLine:
                                      'Only ${AppStrings.paywallAnnualPerWeek} / week',
                                  footerHighlight: true,
                                  badge: AppStrings.paywallAnnualBadge,
                                  selected:
                                      _selectedPlan == _PlanType.annual,
                                  onTap: () {
                                    setState(() => _selectedPlan =
                                        _PlanType.annual);
                                    ref.read(analyticsProvider).track(
                                        AnalyticsEvents
                                            .paywallPlanSelected,
                                        properties: {'plan': _planName});
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 4),
                              Expanded(
                                child: _PricingCard(
                                  label: AppStrings.paywallWeeklyLabel,
                                  mainPrice: _weeklyPackage
                                          ?.storeProduct.priceString ??
                                      AppStrings.paywallWeeklyPrice,
                                  mainPriceLabel: 'per week',
                                  footerLine: 'Cancel anytime',
                                  footerHighlight: false,
                                  selected:
                                      _selectedPlan == _PlanType.weekly,
                                  onTap: () {
                                    setState(() => _selectedPlan =
                                        _PlanType.weekly);
                                    ref.read(analyticsProvider).track(
                                        AnalyticsEvents
                                            .paywallPlanSelected,
                                        properties: {'plan': _planName});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm + 2),
                        Text(
                          hasTrial
                              ? AppStrings.paywallTrialMicrocopyTemplate.replaceAll(
                                  '{price}',
                                  _annualPackage?.storeProduct.priceString ??
                                      AppStrings.paywallAnnualPrice,
                                )
                              : AppStrings.paywallNoTrialNote,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiaryLight,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Flexible gap above the CTA group. Pairs 1:1 with the
                  // matching Spacer below the legal links so the CTA +
                  // legal block sits at the true vertical center of the
                  // cream space between the pricing cards and the screen
                  // bottom. The home indicator floats over the same cream,
                  // so no fixed bottom inset is needed for visual balance.
                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // CTA — full-width pill, dynamic copy.
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_purchasing || _restoring)
                                ? null
                                : _handlePurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: _purchasing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  )
                                : Text(
                                    hasTrial
                                        ? AppStrings.paywallCtaTrial
                                        : AppStrings.paywallCtaSubscribeRevised,
                                    style:
                                        AppTypography.labelLarge.copyWith(
                                      color: AppColors.textOnPrimary,
                                      fontSize: 16,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                        if (hasTrial) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.paywallNoPaymentTodayLine,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiaryLight,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm + 4),

                        // Legal links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegalLink(
                              label: _restoring
                                  ? 'Restoring...'
                                  : AppStrings.paywallRestore,
                              onPressed: (_purchasing || _restoring)
                                  ? null
                                  : _handleRestore,
                            ),
                            _dot(),
                            _LegalLink(
                              label: AppStrings.paywallTerms,
                              onPressed: () => _openLegalUrl(
                                  AppStrings.termsOfServiceUrl),
                            ),
                            _dot(),
                            _LegalLink(
                              label: AppStrings.paywallPrivacy,
                              onPressed: () => _openLegalUrl(
                                  AppStrings.privacyPolicyUrl),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Mirrors the top Spacer (1:1) for true vertical
                  // centering of the CTA + legal block in the cream
                  // space below the pricing cards.
                  const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Close X — positioned over the hero. Fades in after 3s so the
            // user is forced to take a real look at the offer before they
            // can dismiss. App Review still sees a visible (greyed) X
            // immediately, satisfying Apple's "clear close path" rule.
            // `top` sits the icon flush at the safe-area edge so it reads
            // as floating on the hero, not as a chip pushed inward. No
            // surface background — the icon blends directly into the
            // illustration via its dark stroke.
            Positioned(
              top: mediaQueryPadding.top,
              right: AppSpacing.sm,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _canClose ? 1.0 : 0.35,
                child: IgnorePointer(
                  ignoring: !_canClose,
                  child: IconButton(
                    onPressed:
                        (_purchasing || _restoring) ? null : _handleClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimaryLight,
                      size: 26,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _dot() {
    return Text(
      ' \u00B7 ',
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textTertiaryLight,
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
  }
}

/// Side-by-side compact pricing card. Vertical layout — label up top,
/// price stack in the middle, value line at the bottom — so the whole
/// card feels filled instead of having dead cream space below the price.
/// Selected state uses an emerald border + tinted background; unselected
/// is white with a soft warm border. Cal AI / Hallow / Calm all pair the
/// price with a per-period value line ("Only $X/week", "Cancel anytime")
/// to give the card more reason to exist.
class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.label,
    required this.mainPrice,
    required this.mainPriceLabel,
    required this.footerLine,
    required this.footerHighlight,
    required this.selected,
    required this.onTap,
    this.badge,
    this.strikethroughPrice,
    this.savingsAmount,
  });

  final String label;
  final String mainPrice;
  final String mainPriceLabel;

  /// Optional anchor price displayed above [mainPrice] with a line-through.
  /// Used on the annual card to visualize the savings vs. paying weekly for
  /// 52 weeks. Must be a real, justifiable comparison price — never a
  /// fabricated "list price" (deceptive under Apple guideline 3.1.1).
  final String? strikethroughPrice;

  /// Optional inline "Save $X" callout rendered next to [strikethroughPrice].
  /// Pre-formatted in the user's locale ("$50", "£40", "¥7,800"). Must always
  /// equal [strikethroughPrice] minus [mainPrice] — caller is responsible
  /// for keeping the math consistent.
  final String? savingsAmount;

  /// Bottom line that fills empty space and adds value framing.
  /// Yearly: "Only $0.96 / week" (highlight=true → primary color).
  /// Weekly: "Cancel anytime" (highlight=false → secondary color).
  final String footerLine;
  final bool footerHighlight;

  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Outer Stack sits OUTSIDE the AnimatedContainer so floating elements
    // (selected check, SAVE badge) can escape the card's padded interior.
    // Putting them inside the container's child Stack — even with
    // clipBehavior: Clip.none — places them in coordinate space relative to
    // the padded inner area, so a small negative offset still falls inside
    // the visible card.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderLight,
                width: selected ? 2 : 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Anchor price (struck-through) + inline savings callout.
                // Aggressive variant — Cal AI / Speechify / Lensa pattern:
                //   • Strike text stays full-strength dark so it's
                //     readable; the line-through is RED so the eye
                //     immediately reads "discount" not "secondary info".
                //   • Inline "Save $X" tag in red bold next to the strike
                //     gives a concrete dollar amount the % badge can't.
                //   • Both pieces are computed dynamically from the live
                //     storefront price, so they're correct in every
                //     country (£40, ¥7,800, ₹3,500, etc.).
                if (strikethroughPrice != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          strikethroughPrice!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.error,
                            decorationThickness: 2.8,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (savingsAmount != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Save $savingsAmount',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Big price
                Text(
                  mainPrice,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontSize: 30,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainPriceLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),

                // Spacer absorbs leftover height when IntrinsicHeight makes
                // both cards match the taller one. Keeps the footer line
                // pinned to the card bottom regardless of which card is
                // taller, so the two cards visually rhyme.
                const SizedBox(height: 14),

                // Thin divider above the footer.
                Container(
                  height: 1,
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.dividerLight,
                ),
                const SizedBox(height: 8),

                // Footer line — fills the dead space and adds value
                // framing. Highlighted (primary color) for Yearly's
                // per-week breakdown, muted for Weekly's "Cancel anytime".
                Text(
                  footerLine,
                  style: AppTypography.bodySmall.copyWith(
                    color: footerHighlight
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                    fontWeight: footerHighlight
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // SAVE 81% badge — floats above the card's top-left edge. Gold
          // against either white or emerald-tinted card; harmonizes with
          // the warm cream page background.
          if (badge != null)
            Positioned(
              top: -11,
              left: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),

          // No floating selected indicator. The 2px emerald border + the
          // primaryLight bg tint + the soft drop shadow are unambiguous;
          // a corner check disc only added visual noise and read as
          // floating-in-the-gap because it sat at the card's right edge.
        ],
      ),
    );
  }
}

/// Hero block — the visual centerpiece at the top of the paywall. Renders
/// a glowing gold medallion with a featured Name of Allah ("Ar-Rahman") at
/// its core, surrounded by a soft 8-point Islamic geometric pattern and a
/// radial cream → warm-gold gradient. The bottom edge fades into the page
/// background so content below feels continuous.
///
/// Composition is fully Flutter-native (no asset dependency) so it works
/// today; a generated illustration can be swapped into the Stack as a new
/// layer later without restructuring.
class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Shrunk from 0.32 → 0.28 (post 2026-05-05 paywall flow redesign) to free
    // vertical space for the new pre-pricing personalized header line + the
    // existing aspiration headline. The image's `Alignment(0, -0.45)` anchor
    // pushes the medallion below the Dynamic Island so the calligraphy is
    // fully visible despite the smaller hero box.
    final heroHeight = (size.height * 0.28).clamp(220.0, 280.0);

    return ClipRRect(
      // Rounded bottom corners give the hero a "card" shape, framing the
      // image without a hard horizontal edge. Top corners stay square so
      // the image sits flush against the screen edge above the status bar.
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          children: [
          // Soft warm-gold radial backdrop. Visible behind the image's
          // transparent edges and, more importantly, sits beneath the
          // ShaderMask so the faded-out bottom of the image dissolves into
          // it cleanly instead of into stark page cream.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 0.95,
                  colors: [
                    Color(0xFFF5EBD9),
                    AppColors.backgroundLight,
                  ],
                ),
              ),
            ),
          ),

          // Hero illustration. ShaderMask fades the bottom ~35% of the
          // image to transparent so the medallion dissolves smoothly into
          // the cream page — no visible hard horizontal edge where the
          // PNG ends. BlendMode.dstIn means: keep the image where the
          // shader is opaque, hide it where the shader is transparent.
          Positioned.fill(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.55, 1.0],
              ).createShader(rect),
              child: Image.asset(
                'assets/illustrations/paywall_hero.png',
                fit: BoxFit.cover,
                // Bias the visible window upward in the source image, which
                // visually shifts the medallion DOWN inside the hero box.
                // Result: the calligraphy sits below the Dynamic Island /
                // status bar instead of being clipped by it.
                alignment: const Alignment(0, -0.45),
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scaleXY(
                  begin: 0.96,
                  end: 1.0,
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                ),
          ),

          // Final blend — a thin gradient layer that nudges any remaining
          // edge into pure background cream. ShaderMask handles the heavy
          // lifting; this is a polish pass.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: heroHeight * 0.35,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundLight.withValues(alpha: 0.0),
                      AppColors.backgroundLight,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}


/// "Honest paywall" trial timeline. Three small cards: Today (full access),
/// Day 2 (reminder), Day 3 (charged or cancel). Lifts trust and conversion
/// over the tiny gray legal-line approach.
class _TrialTimelineStrip extends StatelessWidget {
  const _TrialTimelineStrip({required this.chargeOnDay3});

  /// Localized price string for the selected plan ("$49.99", "$4.99", etc.).
  final String chargeOnDay3;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: _TimelineStep(
            icon: Icons.lock_open_rounded,
            iconColor: AppColors.primary,
            heading: AppStrings.paywallTimelineTodayHeading,
            label: AppStrings.paywallTimelineTodayLabel,
          ),
        ),
        const Expanded(
          child: _TimelineStep(
            icon: Icons.notifications_active_rounded,
            iconColor: AppColors.streakAmber,
            heading: AppStrings.paywallTimelineDay2Heading,
            label: AppStrings.paywallTimelineDay2Label,
          ),
        ),
        Expanded(
          child: _TimelineStep(
            icon: Icons.payments_rounded,
            iconColor: AppColors.textSecondaryLight,
            heading: AppStrings.paywallTimelineDay3Heading,
            label: '$chargeOnDay3 ${AppStrings.paywallTimelineDay3Label}',
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.iconColor,
    required this.heading,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String heading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          heading,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiaryLight,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Bottom sheet shown when the user taps X with annual selected. Offers the
/// weekly plan (a price alternative, NOT a different product) so we stay
/// inside Apple guideline 5.6 — no second full paywall, no bait-and-switch.
class _ExitOfferSheet extends StatelessWidget {
  const _ExitOfferSheet({
    required this.weeklyPrice,
    required this.weeklyHasTrial,
  });

  final String weeklyPrice;
  final bool weeklyHasTrial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.paywallExitOfferTitle,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              weeklyHasTrial
                  ? AppStrings.paywallExitOfferBody
                  : 'Not ready for a year? Try the weekly plan — '
                      '$weeklyPrice/week, cancel anytime.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (weeklyHasTrial) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$weeklyPrice / week after trial',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  weeklyHasTrial
                      ? AppStrings.paywallExitOfferAccept
                      : 'Try weekly',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppStrings.paywallExitOfferDecline,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
