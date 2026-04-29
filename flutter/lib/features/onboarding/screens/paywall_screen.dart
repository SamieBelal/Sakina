import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // TEMP diagnostic: log what RC is actually handing us so we can tell
      // whether `introductoryPrice` is missing because of (a) App Store
      // Connect not yet propagated to RC, (b) the local SDK still serving
      // stale cache, or (c) a sandbox / simulator quirk. Remove once the
      // trial UI is verified end-to-end on TestFlight.
      for (final pkg in offerings) {
        final intro = pkg.storeProduct.introductoryPrice;
        debugPrint(
          '[paywall] ${pkg.identifier} '
          '(${pkg.storeProduct.identifier}) '
          'intro=${intro == null ? 'null' : '${intro.priceString} '
              'for ${intro.periodNumberOfUnits} ${intro.periodUnit.name} '
              '(cycles=${intro.cycles})'}',
        );
      }
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
    } else {
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
      _ => 'the person you want to be',
    };
    final mins = s.dailyCommitmentMinutes ?? 3;
    return 'Become $aspiration in $mins min a day.';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Close button — fades in after 3s. App Review still
                      // sees a visible (greyed) X immediately, but users get
                      // forced exposure to the offer before they can dismiss.
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: _canClose ? 1.0 : 0.25,
                          child: IgnorePointer(
                            ignoring: !_canClose,
                            child: IconButton(
                              onPressed: (_purchasing || _restoring)
                                  ? null
                                  : _handleClose,
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Decorative Arabic calligraphy
                      Text(
                        '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650',
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.secondary.withAlpha(191),
                          fontFamily: 'Amiri',
                          fontSize: 28,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Headline — personalized from quiz answers
                      Text(
                        _personalizedHeadline(),
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3 compact benefit rows
                      ...List.generate(_benefits.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _benefits[i],
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 80 * i),
                              duration: 400.ms,
                            )
                            .slideX(
                              begin: -0.05,
                              end: 0,
                              delay: Duration(milliseconds: 80 * i),
                              duration: 400.ms,
                            );
                      }),
                      const SizedBox(height: AppSpacing.sm),

                      // Social proof — single inline line with stars and
                      // review count. Cal AI / Hallow / Calm all keep this
                      // to one line; a paragraph testimonial here doubled
                      // the vertical real estate without earning it.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            5,
                            (_) => const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1),
                              child: Icon(
                                Icons.star_rounded,
                                color: AppColors.streakAmber,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${AppStrings.paywallStarsLabel} \u00B7 '
                            '${AppStrings.paywallReviewsCount}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Honest trial timeline — Today / Day 2 / Day 3.
                      // Only render when the selected plan actually has a
                      // free trial configured on the underlying StoreKit
                      // product. Otherwise the strip would lie to the user
                      // about being charged "Day 3" when the OS will charge
                      // them today.
                      if (_planHasTrial(_selectedPlan)) ...[
                        _TrialTimelineStrip(
                          chargeOnDay3:
                              _selectedPlan == _PlanType.annual
                                  ? (_annualPackage?.storeProduct.priceString ??
                                      AppStrings.paywallAnnualPrice)
                                  : (_weeklyPackage?.storeProduct.priceString ??
                                      AppStrings.paywallWeeklyPrice),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Pricing cards — stacked, yearly first
                      _PricingCard(
                        label: AppStrings.paywallAnnualLabel,
                        mainPrice: _annualPackage?.storeProduct.priceString ??
                            AppStrings.paywallAnnualPerWeek,
                        mainPriceLabel: 'per year',
                        // Drop the subPrice — the SAVE 81% badge under the
                        // label already carries this. Rendering it twice
                        // (left and right side of the same card) reads as
                        // clutter, not emphasis.
                        badge: AppStrings.paywallAnnualBadge,
                        selected: _selectedPlan == _PlanType.annual,
                        onTap: () {
                          setState(() => _selectedPlan = _PlanType.annual);
                          ref.read(analyticsProvider).track(AnalyticsEvents.paywallPlanSelected, properties: {'plan': _planName});
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PricingCard(
                        label: AppStrings.paywallWeeklyLabel,
                        mainPrice: _weeklyPackage?.storeProduct.priceString ??
                            AppStrings.paywallWeeklyPrice,
                        mainPriceLabel: 'per week',
                        selected: _selectedPlan == _PlanType.weekly,
                        onTap: () {
                          setState(() => _selectedPlan = _PlanType.weekly);
                          ref.read(analyticsProvider).track(AnalyticsEvents.paywallPlanSelected, properties: {'plan': _planName});
                        },
                      ),
                      // No-trial billing note. Only renders when the selected
                      // plan has no introductory free offer — keeps the
                      // paywall honest about immediate billing in that case.
                      if (!_planHasTrial(_selectedPlan)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppStrings.paywallNoTrialNote,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiaryLight,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const Spacer(flex: 3),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                                  _planHasTrial(_selectedPlan)
                                      ? AppStrings.paywallCta
                                      : AppStrings.paywallCtaSubscribe,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

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
                            onPressed: () =>
                                _openLegalUrl(AppStrings.termsOfServiceUrl),
                          ),
                          _dot(),
                          _LegalLink(
                            label: AppStrings.paywallPrivacy,
                            onPressed: () =>
                                _openLegalUrl(AppStrings.privacyPolicyUrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.label,
    required this.mainPrice,
    required this.mainPriceLabel,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String mainPrice;
  final String mainPriceLabel;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textTertiaryLight,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Label + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price column — right-aligned
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mainPrice,
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(
                  mainPriceLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
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
