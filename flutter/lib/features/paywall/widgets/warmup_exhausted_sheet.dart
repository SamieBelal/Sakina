import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sakina/services/gating_service.dart'
    show GatedFeature, GatingService;
import 'package:sakina/services/purchase_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

export 'package:sakina/services/gating_service.dart' show GatedFeature;

/// Resolves the free-tier cohort for a sheet that is about to be presented.
///
/// Shared by both cap sheets. Wraps [GatingService.isNewCohort] in a
/// try/catch that answers `false`, for two reasons:
///
///  1. **Never turn a gate into a dead end.** These sheets are the ONLY thing
///     standing between a capped user and a blank screen. If the cohort read
///     throws — a corrupted store, an unscoped key before sign-in — an
///     uncaught error would abandon `showModalBottomSheet` and the user would
///     tap their CTA and get nothing at all.
///  2. **`false` is the generous answer.** It selects the legacy copy AND
///     leaves the token bypass in place, matching `isNewCohort`'s own
///     documented fail-to-false posture: never hand someone the tighter tier
///     on a guess.
///
/// **Testing note.** [GatingService.isNewCohort] reads SharedPreferences, and
/// `SharedPreferences.getInstance()` never completes under `flutter_test`
/// unless a mock store is installed — it hangs rather than throwing, so the
/// try/catch above cannot rescue it and `show` would silently present
/// nothing. Any widget test that drives either sheet's `show` must call
/// `SharedPreferences.setMockInitialValues({})` first. On device this cannot
/// happen: the plugin is always registered, and by the time a cap sheet is
/// reached the gate that produced the `GateResult` has already awaited this
/// same cached read, so the value is warm.
/// Resolves premium for a sheet about to be presented, failing to `false`.
///
/// `false` shows the sheet, which is the pre-existing behaviour — so a read
/// that cannot complete degrades to exactly what shipped before this veto
/// existed rather than silently suppressing a free user's sheet.
Future<bool> _resolvePremiumForSheet() async {
  try {
    return await PurchaseService().isPremium();
  } catch (_) {
    return false;
  }
}

Future<bool> resolveNewCohortForSheet() async {
  try {
    return await GatingService().isNewCohort();
  } catch (_) {
    return false;
  }
}

/// Bottom sheet shown the first time a free user exhausts a feature's
/// lifetime warm-up budget.
///
/// Copy is parameterized per [GatedFeature] **and per free-tier cohort**.
/// Primary CTA opens the paywall; secondary dismisses and lets the user fall
/// through to whatever their cohort's steady-state allowance is — and that
/// allowance is exactly what the body copy has to name, because the two
/// cohorts fall through to different things:
///
///  * **legacy** (`isNewCohort == false`) — a 1/day cap, so "from tomorrow
///    you'll get one a day" is true and stays shipped verbatim.
///  * **`reel_v1`** (`isNewCohort == true`) — Reflect and Build-a-Duʿā fall
///    through to a *combined weekly pool* that resets on the local Monday
///    (`consume_weekly_allowance`), and `discoverName` falls through to the
///    permanently-free once-a-day reveal. Neither is "one a day" for the
///    feature in hand, so the legacy line becomes false the moment the pool
///    ships (plan D10③).
class WarmupExhaustedSheet extends StatelessWidget {
  final GatedFeature feature;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  /// Which free-tier the copy must describe. Defaults to `false` (legacy) so
  /// a caller that has not been taught about cohorts renders the generous,
  /// still-true copy rather than promising a Monday reset to someone whose
  /// allowance actually resets tomorrow. [show] resolves the real value.
  ///
  /// **Why this sheet uses the cohort where `DailyCapSheet` prefers the gate
  /// reason.** There is no `GateReason` to prefer: this sheet fires on a
  /// *successful* use — the one that decremented warmup from 1 to 0, signalled
  /// by `UsageOutcome.warmupJustExhausted` — not on a gate rejection. Nothing
  /// was refused, so `canUse` produced no reason to explain. The cohort is not
  /// a second-best proxy here, it is the only thing that distinguishes what
  /// the user is about to fall through to.
  final bool isNewCohort;

  const WarmupExhaustedSheet({
    super.key,
    required this.feature,
    required this.onUpgrade,
    required this.onDismiss,
    this.isNewCohort = false,
    this.isPremium = false,
  });

  /// Defence-in-depth premium veto. A payer has no warm-up budget and no free
  /// tier, so **no** copy on this sheet is true for them.
  ///
  /// Today this is unreachable through the happy path — `markUsed`
  /// short-circuits premium and returns `ok`, so `warmupJustExhausted` never
  /// gets set for a payer. But that is safety by *reachability*, not by
  /// construction, and there is a live race that defeats it:
  /// `muhasabah_screen.dart` reads the flag at MOUNT off a non-autoDispose
  /// provider, so a user who subscribes while a `markUsed` is in flight and
  /// then returns to `/muhasabah` reads a flag set moments before their
  /// entitlement landed. Two reviewers found that from opposite directions.
  ///
  /// So the veto lives here rather than in the callers: correctness becomes a
  /// property of this widget instead of a property of who happens to call it.
  final bool isPremium;

  static Future<void> show(
    BuildContext context, {
    required GatedFeature feature,
    required VoidCallback onUpgrade,
  }) async {
    // Resolved here rather than inside the widget so the sheet renders its
    // final copy on frame zero. A FutureBuilder would flash the legacy line
    // and then swap it — on a purchase surface, showing the user one promise
    // and replacing it a frame later is worse than the wait, and the read is
    // a SharedPreferences hit with no network in it.
    final newCohort = await resolveNewCohortForSheet();
    final premium = await _resolvePremiumForSheet();
    if (!context.mounted) return;

    // A payer gets NO sheet. Unlike DailyCapSheet — which is shown because the
    // user was blocked and therefore needs an explanation — this one fires on
    // a SUCCESSFUL use, so a premium user reaching it is neither blocked nor
    // out of anything. Every line available here ("your free reflections",
    // "from tomorrow you'll get one a day", the weekly-pool line) is false for
    // them, and there is no true replacement to write: the event this sheet
    // announces simply does not apply to a subscriber. Presenting nothing is
    // the only honest option.
    //
    // The returned future still completes, so the caller's
    // `.whenComplete(dismissWarmupExhausted)` still clears the pending flag
    // and the sheet cannot re-fire on the next visit to the route.
    if (premium) return;

    return showModalBottomSheet<void>(
      context: context,
      // Push on the ROOT navigator with a named route so the singleton
      // `tourRouteObserver` (wired into the root GoRouter) registers this
      // route's `WarmupExhaustedSheet` name and the tour overlay suppresses
      // itself while the sheet is up. Without this the sheet pushes on the
      // nested shell navigator, the root observer never sees it, and an
      // in-flight guided tour overlaps the sheet AND intercepts its buttons.
      // Mirrors the LapsedTrialSheet fix.
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: 'WarmupExhaustedSheet'),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return WarmupExhaustedSheet(
          feature: feature,
          isNewCohort: newCohort,
          isPremium: premium,
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  /// Cohort-neutral: the headline reports what the user just finished, which
  /// is true either way. Only the body makes a claim about what happens next,
  /// so only the body branches.
  String get _headline {
    switch (feature) {
      case GatedFeature.reflect:
        return "You've completed your free reflections";
      case GatedFeature.builtDua:
        return "You've built your free duʿās";
      case GatedFeature.discoverName:
        return "You've discovered your free Names";
    }
  }

  /// `!isPremium` leads for the same reason it does in
  /// `DailyCapSheet.describesNewTier`: `free_tier_cohort` is stamped at signup
  /// and never cleared when the account subscribes, so a payer created after
  /// the flip reports `isNewCohort == true` forever. Without this veto the
  /// mount race described on [isPremium] renders them the weekly-pool line.
  String get _body =>
      !isPremium && isNewCohort ? _newCohortBody : _legacyBody;

  /// LEGACY tier — a genuine 1/day cap, so this stays exactly as shipped.
  /// Identical across features per spec.
  String get _legacyBody =>
      "From tomorrow you'll get one a day. Or unlock unlimited now.";

  /// `reel_v1` tier. Unlike legacy, this one has to branch by feature,
  /// because the two fall-throughs are different mechanics:
  ///
  ///  * Reflect / Build-a-Duʿā drop into the **combined** weekly pool. Both
  ///    features are named, and "together" states that they share one pool —
  ///    a user told only "your reflections come back Monday" who then finds
  ///    Build-a-Duʿā also closed has been misled by omission, which is the
  ///    same broken promise D10③ exists to prevent. Both the naming and the
  ///    word "together" are pinned by test; neither survives a reword by
  ///    accident.
  ///  * `discoverName` is never pooled. Its once-a-day reveal consults no
  ///    gate at all and is free permanently; only a *second* Name in a day
  ///    is premium.
  ///
  /// **Stays forward-looking, unlike `DailyCapSheet`'s line.** This sheet
  /// fires the instant warmup ends, when the weekly pool is still completely
  /// UNSPENT — the user is not blocked and nothing needs to come back yet.
  /// The cap sheet's "your free reflections and duʿās return on Monday" is
  /// exactly right there and would be a fresh false claim here, so this one
  /// says "from here … return each Monday": the same words in the founder's
  /// register (2026-07-31, "allowance" dropped), describing the new steady
  /// state rather than asserting the pool is already gone.
  ///
  /// Deliberately number-free. The pool size is the `weekly_pool_size` server
  /// dial, and quoting a dial the client never reads is exactly the trap
  /// documented at `GatingService.bypassTokenCost` — tune the dial and the
  /// copy starts lying again. "Return each Monday" is true at any size.
  String get _newCohortBody {
    switch (feature) {
      case GatedFeature.reflect:
      case GatedFeature.builtDua:
        return 'From here, your free reflections and duʿās return together '
            'each Monday. Or unlock unlimited now.';
      case GatedFeature.discoverName:
        return 'Your Name for each day stays free, always. '
            'Or unlock unlimited now.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PaywallSheetScaffold(
      icon: Icons.auto_awesome,
      headline: _headline,
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
    );
  }
}

/// Shared scaffold so all three paywall sheets render with the same visual
/// language (drag handle, icon, headline, body, primary + optional middle +
/// secondary CTAs).
///
/// The middle CTA is the AI-bypass slot (plan 2026-05-23). When [middleLabel]
/// is non-null it renders as a 48dp outlined button between the primary fill
/// CTA and the tertiary text CTA. When [middleEnabled] is false the button
/// renders dimmed and ignores taps, and [middleDisabledHint] (when supplied)
/// appears as 12dp secondary-text underneath explaining why.
class _PaywallSheetScaffold extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String body;

  /// Null renders NO primary button — not a disabled one, not a no-op one.
  /// The premium fair-use variant has nothing to sell, so it has no CTA.
  final String? primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onSecondary;
  final String? middleLabel;
  final VoidCallback? onMiddle;
  final bool middleEnabled;
  final String? middleDisabledHint;
  final Color? primaryColor;

  const _PaywallSheetScaffold({
    required this.icon,
    required this.headline,
    required this.body,
    required this.secondaryLabel,
    required this.onSecondary,
    this.primaryLabel,
    this.onPrimary,
    this.middleLabel,
    this.onMiddle,
    this.middleEnabled = true,
    this.middleDisabledHint,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Headline (DM Serif Display feel — using Outfit at high weight
              // since Outfit is the project's display font; spec calls for
              // serif but the project standardised on Outfit).
              Text(
                headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              // Body
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Primary CTA — absent entirely when [primaryLabel] is null.
              if (primaryLabel != null)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor ?? AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    child: Text(
                      primaryLabel!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              if (middleLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                // Middle outlined CTA (AI-bypass slot). 48dp height vs.
                // primary's 52dp — the visual hierarchy keeps "Unlock
                // unlimited" as the unambiguous primary action.
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: middleEnabled ? onMiddle : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor:
                          AppColors.textTertiaryLight,
                      side: BorderSide(
                        color: middleEnabled
                            ? AppColors.primary
                            : AppColors.borderLight,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      middleLabel!,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: middleEnabled
                            ? AppColors.primary
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ),
                if (!middleEnabled && middleDisabledHint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    middleDisabledHint!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.sm),
              // Secondary text-only CTA
              TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  secondaryLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Re-export the shared scaffold so sibling widgets in this folder can use it
// without each one redefining the chrome. Keeping this private file-local but
// exposing via package-private import in the sibling files using `part` would
// require build_runner; instead, we duplicate intentionally-minimal code in
// the sibling sheets that all delegate to PaywallSheetScaffold defined below.
//
// To avoid duplication AND avoid `part`, we expose a public scaffold widget
// here that the other two sheets import. The leading underscore on
// `_PaywallSheetScaffold` would prevent that, so we also expose an alias.
class PaywallSheetScaffold extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String body;

  /// Null renders NO primary button. See [_PaywallSheetScaffold.primaryLabel].
  final String? primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback onSecondary;

  /// Optional outlined middle CTA. Used by DailyCapSheet to render the
  /// AI-bypass "Use 25 tokens for one more" button. Omit for sheets that
  /// only need primary + secondary (e.g. WarmupExhaustedSheet).
  final String? middleLabel;
  final VoidCallback? onMiddle;
  final bool middleEnabled;
  final String? middleDisabledHint;

  /// Optional override for the primary CTA fill color. Defaults to
  /// `AppColors.primary` (deep emerald). DailyCapSheet STATE D (Day-1
  /// freebie variant) passes `AppColors.secondary` (warm matte gold) to
  /// visually distinguish the "one free, on us" moment from the
  /// monetization-oriented green Unlock-unlimited CTA.
  final Color? primaryColor;

  const PaywallSheetScaffold({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    required this.secondaryLabel,
    required this.onSecondary,
    this.primaryLabel,
    this.onPrimary,
    this.middleLabel,
    this.onMiddle,
    this.middleEnabled = true,
    this.middleDisabledHint,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return _PaywallSheetScaffold(
      icon: icon,
      headline: headline,
      body: body,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      middleLabel: middleLabel,
      onMiddle: onMiddle,
      middleEnabled: middleEnabled,
      middleDisabledHint: middleDisabledHint,
      primaryColor: primaryColor,
    );
  }
}
