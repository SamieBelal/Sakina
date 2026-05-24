import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/daily/providers/daily_rewards_provider.dart';
import '../services/analytics_events.dart';
import '../services/analytics_provider.dart';
import '../services/gating_service.dart';
import '../services/purchase_service.dart';
import 'achievement_toast.dart' show rootNavigatorKey;

/// Snapshot of everything the IAP→sub upsell banner needs to render: whether
/// it should appear, the lifetime bypass count (for the "$X spent" copy), and
/// the locale-priced weekly subscription string (from RevenueCat).
class IapToSubBannerState {
  final bool visible;
  final int lifetimeBypassesPurchased;
  final String? weeklyPriceString;

  const IapToSubBannerState({
    required this.visible,
    required this.lifetimeBypassesPurchased,
    required this.weeklyPriceString,
  });

  static const hidden = IapToSubBannerState(
    visible: false,
    lifetimeBypassesPurchased: 0,
    weeklyPriceString: null,
  );
}

/// Single source of truth for the IAP→sub banner's render decision. Combines:
///
///   * `GatingService.iapToSubBannerEligible()` — server-hydrated state +
///     premium check + 7-day-since-signup floor + 14-day dismissal window.
///   * `PurchaseService.getOfferings()` — weekly package price string.
///
/// The eligibility check naturally excludes premium users, so this banner is
/// mutually exclusive with `BillingIssueBanner` (which only renders for
/// premium users) without explicit suppression logic.
final iapToSubBannerStateProvider =
    FutureProvider.autoDispose<IapToSubBannerState>((ref) async {
  // Watch the premium state so a fresh purchase / restore / billing-issue
  // surfaces immediately re-evaluates the banner.
  ref.watch(premiumStateProvider);

  final gating = GatingService();
  final eligible = await gating.iapToSubBannerEligible();
  if (!eligible) return IapToSubBannerState.hidden;

  final lifetime = await gating.lifetimeBypassesPurchased();

  String? weeklyPrice;
  try {
    final packages = await PurchaseService().getOfferings();
    final weekly = packages.cast<Package?>().firstWhere(
          (p) => p?.packageType == PackageType.weekly,
          orElse: () => null,
        );
    weeklyPrice = weekly?.storeProduct.priceString;
  } catch (_) {
    // RC not configured / network down — render the banner without the
    // headline price. The destination paywall will show real numbers.
    weeklyPrice = null;
  }

  return IapToSubBannerState(
    visible: true,
    lifetimeBypassesPurchased: lifetime,
    weeklyPriceString: weeklyPrice,
  );
});

/// Routes where the banner must NOT render. Showing the upsell ON the
/// paywall (the destination it routes to) would be redundant; showing it
/// during onboarding / sign-in interrupts a high-intent flow. All other
/// routes (5 bottom-nav tabs + deep links) get the banner when eligible.
///
/// Match is `startsWith` so nested routes under these paths also hide.
/// Exposed for test pinning.
@visibleForTesting
const hiddenBannerRoutes = <String>{
  '/paywall',
  '/onboarding',
  '/welcome',
  '/signin',
};

/// Sticky upsell banner shown to free users who have committed 6+ paid
/// bypasses lifetime. Surfaces a soft "you're already spending — sub gives
/// you unlimited" nudge before the natural sub-vs-IAP arithmetic clicks.
///
/// Visual pattern mirrors `lib/widgets/billing_issue_banner.dart` so the user
/// learns a single top-banner shape, not two competing surfaces. Gold tint
/// instead of red — this is opportunity copy, not an alert.
///
/// Naturally mutually exclusive with BillingIssueBanner: that banner requires
/// `isPremium == true && billingIssueAt != null`; this one requires
/// `isPremium == false`. Both can sit in the same Column safely.
///
/// Stateful because it subscribes to `GoRouter.routerDelegate` (a
/// `ChangeNotifier`) to hide on routes in [hiddenBannerRoutes]. The
/// MaterialApp.builder context doesn't have GoRouter scope, so route
/// awareness has to be plumbed manually via the global `rootNavigatorKey`.
class IapToSubUpsellBanner extends ConsumerStatefulWidget {
  const IapToSubUpsellBanner({super.key});

  @override
  ConsumerState<IapToSubUpsellBanner> createState() =>
      _IapToSubUpsellBannerState();
}

class _IapToSubUpsellBannerState extends ConsumerState<IapToSubUpsellBanner> {
  GoRouter? _router;
  String _currentPath = '/';
  bool _shownEventFired = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame so GoRouter has mounted under the navigator
    // key. Reading it synchronously from initState races with router setup.
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachRouter());
  }

  void _attachRouter() {
    if (!mounted) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    _router = GoRouter.maybeOf(ctx);
    final router = _router;
    if (router == null) return;
    // Listen to BOTH:
    //   * routeInformationProvider — fires on push/go and gives us the
    //     current pushed URI in its .value (routerDelegate.currentConfiguration
    //     would stay at the base route for an imperative push).
    //   * routerDelegate (ChangeNotifier) — fires on pop in cases where
    //     routeInformationProvider does NOT re-emit (simulator-verified:
    //     popping back from a `.push('/paywall')` kept the banner hidden
    //     until the user tapped a bottom-nav tab).
    // Both callbacks read the path off routeInformationProvider.value, which
    // is the authoritative current URI in both cases.
    router.routeInformationProvider.addListener(_onRouteChanged);
    router.routerDelegate.addListener(_onRouteChanged);
    _onRouteChanged();
  }

  void _onRouteChanged() {
    final router = _router;
    if (router == null || !mounted) return;
    final path = router.routeInformationProvider.value.uri.path;
    if (path != _currentPath) {
      setState(() => _currentPath = path);
    }
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  bool _hiddenForCurrentRoute() {
    return hiddenBannerRoutes.any((r) => _currentPath.startsWith(r));
  }

  @override
  Widget build(BuildContext context) {
    if (_hiddenForCurrentRoute()) return const SizedBox.shrink();

    final stateAsync = ref.watch(iapToSubBannerStateProvider);
    final state = stateAsync.maybeWhen(
      data: (s) => s,
      orElse: () => IapToSubBannerState.hidden,
    );

    if (!state.visible) return const SizedBox.shrink();

    // P0-5: fire shown event once per visible mount. Sticky boolean so
    // rebuilds (route changes, theme changes, parent invalidations) don't
    // re-emit. Post-frame so we don't emit during layout. Mounted guard
    // for the dispose-mid-frame edge case.
    if (!_shownEventFired) {
      _shownEventFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(analyticsProvider).track(
          AnalyticsEvents.iapToSubBannerShown,
          properties: {
            'lifetime_bypasses_purchased': state.lifetimeBypassesPurchased,
          },
        );
      });
    }

    // $X spent: compute from lifetime count × $0.50 (the lowest token-pack
    // unit price — bypass = 25 tokens ≈ $0.50 at the smallest pack). Rounded
    // down per plan. This is illustrative, not a financial figure.
    final dollarsSpent = (state.lifetimeBypassesPurchased * 0.5).floor();
    final headline = "You've spent \$$dollarsSpent on bypasses";
    // Drop the price entirely on RC fallback. A hardcoded fallback ($9.99)
    // would drift from the real RC value ($4.99 today) and surface a wrong
    // figure in the upsell copy — worse than no figure.
    final weeklyPrice = state.weeklyPriceString;
    final subline = weeklyPrice == null
        ? 'Weekly sub unlocks unlimited reflections, duas, and discoveries.'
        : 'Weekly sub at $weeklyPrice unlocks unlimited reflections, duas, and discoveries.';

    return Material(
      // Solid pale-gold from the palette (designed tint) instead of a
      // translucent gold. Translucency over the system status-bar area
      // composites to near-black on the iPhone 17 simulator — see PR 5
      // simulator verification screenshots.
      color: AppColors.secondaryLight,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: InkWell(
            onTap: _onBannerTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Plain InkWell + Icon instead of IconButton: this banner
                  // sits in MaterialApp.builder, above the Navigator/Overlay,
                  // and IconButton's built-in Tooltip throws "No Overlay
                  // widget found" when there's no ancestor Overlay.
                  Semantics(
                    button: true,
                    label: 'Dismiss',
                    child: InkWell(
                      onTap: _onDismissTap,
                      borderRadius: BorderRadius.circular(22),
                      child: const SizedBox(
                        // 44pt is Apple HIG's minimum tap target. The
                        // visible icon stays at 16pt; the extra padding
                        // gives the tap area room to breathe.
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onBannerTap() {
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.iapToSubBannerTapped);
    analytics.track(
      AnalyticsEvents.paywallViewed,
      properties: {'trigger': AnalyticsEvents.paywallTriggerIapToSubUpsell},
    );
    // The banner is mounted in MaterialApp.router's `builder`, which sits
    // ABOVE the GoRouter's Navigator. `context.push` from this context can't
    // see GoRouter's scope. Prefer the global rootNavigatorKey's context
    // (which IS a descendant of GoRouter). Fall back to the local context
    // for tests that wire a router directly above the banner.
    final navContext = rootNavigatorKey.currentContext ?? context;
    navContext.push('/paywall');
  }

  Future<void> _onDismissTap() async {
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.iapToSubBannerDismissed);
    final ok = await GatingService().dismissIapToSubBanner();
    if (ok && mounted) {
      // Invalidate so the banner re-evaluates and hides itself immediately
      // (the local cache was updated by `dismissIapToSubBanner`).
      ref.invalidate(iapToSubBannerStateProvider);
    }
  }
}
