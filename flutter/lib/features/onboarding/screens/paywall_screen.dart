import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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

  String get _planName => _selectedPlan == _PlanType.annual ? 'annual' : 'weekly';

  static const _benefits = [
    AppStrings.paywallBenefit1,
    AppStrings.paywallBenefit2,
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

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await PurchaseService().getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
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

  void _handleClose() {
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallClosed);
    widget.onComplete();
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

      final premiumActive = await PurchaseService().purchase(selectedPackage);
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
                      // Close button
                      Align(
                        alignment: Alignment.centerRight,
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

                      // Headline
                      Text(
                        AppStrings.paywallTitle,
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Subtitle
                      Text(
                        AppStrings.paywallSubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 2),

                      // 4 compact benefit rows
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

                      // Social proof
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.streakAmber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.paywallSocialProof,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Pricing cards — stacked, yearly first
                      _PricingCard(
                        label: AppStrings.paywallAnnualLabel,
                        mainPrice: _annualPackage?.storeProduct.priceString ??
                            AppStrings.paywallAnnualPerWeek,
                        mainPriceLabel: 'per year',
                        subPrice: AppStrings.paywallAnnualBadge,
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
                      const SizedBox(height: AppSpacing.sm),

                      // Trial terms — updates based on selected plan
                      Text(
                        _selectedPlan == _PlanType.annual
                            ? AppStrings.paywallTrialTermsAnnual
                            : AppStrings.paywallTrialTermsWeekly,
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
                                  AppStrings.paywallCta,
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
                          const _LegalLink(label: AppStrings.paywallTerms),
                          _dot(),
                          const _LegalLink(label: AppStrings.paywallPrivacy),
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
    this.subPrice,
  });

  final String label;
  final String mainPrice;
  final String mainPriceLabel;
  final String? badge;
  final String? subPrice;
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
                if (subPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subPrice!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
