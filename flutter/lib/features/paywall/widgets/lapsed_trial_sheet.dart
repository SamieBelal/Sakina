import 'package:flutter/material.dart';

import 'warmup_exhausted_sheet.dart'
    show PaywallSheetScaffold, resolveNewCohortForSheet;

/// Bottom sheet shown on the first app open after a RevenueCat trial has
/// lapsed without conversion. References the user's actual trial-period
/// activity to make the upgrade prompt feel earned, not punitive.
///
/// Falls back to generic copy if [momentsDuringTrial] is 0 (we couldn't
/// resolve trial activity) so the sheet always renders sensible copy.
///
/// **This sheet outlives the reverse-trial experiment.** It fires off
/// RevenueCat's `hadTrial()` — a real store trial — not the app-granted
/// `trial_premium_until`, so W5 Wave A's deletion of the reverse-trial
/// machinery leaves it standing. Once the store trial flips 3 days → 7 days
/// this becomes the standard post-trial surface for every lapsed trialer.
///
/// **Invariant (plan 2026-05-23 line 307):** the lapsed-trialer Day-1 moment
/// is the strongest sub-upsell window in the entire app. It intentionally
/// does NOT offer the AI-bypass CTA — token spend would compete with the
/// subscription ask and dilute conversion. Days 2+ for lapsed trialers
/// fall through to DailyCapSheet (States A/B/C) where the bypass IS shown.
class LapsedTrialSheet extends StatelessWidget {
  /// Total spiritual actions the user took during their trial — reflects,
  /// built duas, and discovered names summed together. The rendered copy
  /// ("you showed up N times") is intentionally action-agnostic so the
  /// number stays honest regardless of which features the user used.
  final int momentsDuringTrial;
  final int daysActiveDuringTrial;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  /// Which free tier the user drops back into when the trial ends — the only
  /// thing this sheet's copy actually promises, and the two cohorts drop into
  /// different things:
  ///
  ///  * **legacy** (`false`) — a genuine 1/day reflection cap, so "One
  ///    reflection a day is yours forever" is true and ships verbatim.
  ///  * **`reel_v1`** (`true`) — reflections and duʿās share a 3-per-week pool
  ///    that resets on the local Monday; only the Name discovery is daily.
  ///    The legacy line promises a daily reflection this user will not get.
  ///
  /// Defaults to `false` for the same reason the cap sheets do: a caller that
  /// has not been taught about cohorts renders the generous, still-true copy
  /// rather than naming a Monday reset to someone who resets tomorrow.
  /// [show] resolves the real value.
  final bool isNewCohort;

  const LapsedTrialSheet({
    super.key,
    required this.momentsDuringTrial,
    required this.daysActiveDuringTrial,
    required this.onUpgrade,
    required this.onDismiss,
    this.isNewCohort = false,
  });

  /// **Testing note.** [resolveNewCohortForSheet] reads SharedPreferences, and
  /// `SharedPreferences.getInstance()` never completes under `flutter_test`
  /// unless a mock store is installed — it hangs rather than throwing, so the
  /// helper's own try/catch cannot rescue it and this method would never reach
  /// `showModalBottomSheet`. Any widget test driving `show` must call
  /// `SharedPreferences.setMockInitialValues({})` first.
  static Future<void> show(
    BuildContext context, {
    required int momentsDuringTrial,
    required int daysActiveDuringTrial,
    required VoidCallback onUpgrade,
    VoidCallback? onDismiss,
  }) async {
    final isNewCohort = await resolveNewCohortForSheet();
    if (!context.mounted) return;
    // Track how the sheet was closed so `onDismiss` fires EXACTLY ONCE on any
    // dismissal that isn't an explicit upgrade. A showModalBottomSheet can be
    // closed three ways the buttons don't cover — barrier tap, swipe-down, and
    // Android back — all of which pop the route without invoking the secondary
    // button. Firing `onDismiss` only from the button left soft_gate_dismissed
    // undercounting against the already-fired impression. We resolve the
    // outcome from the closure and reconcile it when the route future
    // completes. `dismissFired` guards against the button path and the future
    // both firing.
    var upgraded = false;
    var dismissFired = false;
    void fireDismissOnce() {
      if (upgraded || dismissFired) return;
      dismissFired = true;
      onDismiss?.call();
    }

    return showModalBottomSheet<void>(
      context: context,
      // Push on the ROOT navigator so the singleton `tourRouteObserver`
      // (wired into the root GoRouter, router.dart) registers this route's
      // `LapsedTrialSheet` name and the tour overlay suppresses itself while
      // the sheet is up. Without this the sheet pushes on the nested shell
      // navigator, the root observer never sees it, and an in-flight guided
      // tour overlaps the sheet AND intercepts its buttons (its gesture layer
      // sits over the modal). See docs/qa/findings/2026-06-17-reverse-trial-e2e-sim.md.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      routeSettings: const RouteSettings(name: 'LapsedTrialSheet'),
      builder: (sheetContext) {
        return LapsedTrialSheet(
          momentsDuringTrial: momentsDuringTrial,
          daysActiveDuringTrial: daysActiveDuringTrial,
          isNewCohort: isNewCohort,
          onUpgrade: () {
            upgraded = true;
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          // The secondary button just pops — `onDismiss` is fired by the
          // route-completion reconciliation below so the button, the barrier,
          // the swipe, and Android back all funnel through one code path
          // (which is also where the once-only guard lives).
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    ).then((_) {
      // Route popped — whether by the secondary button, the barrier, a
      // swipe-down, or Android back. If the user didn't take the upgrade path,
      // this is a dismissal. Fires at most once.
      fireDismissOnce();
    });
  }

  /// The headline names what stays free. On `reel_v1` that is the daily Name
  /// discovery — "one a day" is still true, but of the Name, not of the
  /// reflection the legacy headline means.
  ///
  /// Reworded 2026-08-01: the first attempt, "Welcome back to your daily
  /// Name", scanned as returning *to* a Name and made "your daily" carry
  /// possessive and adjective duty at once. This phrasing reuses the exact
  /// vocabulary already approved on the cap sheet ("One Name a day stays
  /// free, always"), so the two surfaces describe the free tier in the same
  /// words instead of two near-synonyms.
  String get _headline => isNewCohort
      ? 'One Name a day is still yours'
      : 'Welcome back to one a day';

  String get _body {
    // Fallback: zero moments means we couldn't resolve trial activity (or
    // the user really did nothing during their trial — either way, generic
    // copy reads better than "you showed up 0 times across 0 days").
    if (momentsDuringTrial <= 0) {
      return isNewCohort
          ? "You've explored what Premium feels like. One Name a day stays "
                'free, and your free reflections and duʿās return together '
                'each Monday — or unlock unlimited again.'
          : "You've explored what Premium feels like. One reflection a day "
                'is yours forever — or unlock unlimited again.';
    }
    final timesWord = momentsDuringTrial == 1 ? 'time' : 'times';
    final daysWord = daysActiveDuringTrial == 1 ? 'day' : 'days';
    // No trial LENGTH here, deliberately. This string is rendered after the
    // store's trial has already run, so naming its duration means hardcoding
    // a number App Store Connect can change underneath us — the same failure
    // `TrialOffer` exists to prevent on the paywall (W5 Wave B.4). "In your
    // trial" is true at 3 days, at 7, and at whatever it becomes next.
    return 'In your trial, you showed up $momentsDuringTrial $timesWord '
        'across $daysActiveDuringTrial $daysWord. Premium keeps that pace going.';
  }

  @override
  Widget build(BuildContext context) {
    return PaywallSheetScaffold(
      icon: Icons.local_fire_department_outlined,
      headline: _headline,
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
    );
  }
}
