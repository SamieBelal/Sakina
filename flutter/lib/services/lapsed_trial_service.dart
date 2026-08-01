import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Lapsed Trial Service
//
// Decides whether the LapsedTrialSheet should fire on a given app launch
// and computes the activity stats it shows ("In your trial, you showed up
// X times across Y days..."). The "moments" tally is an activity-agnostic
// sum of reflects + built-duas + discovered-names — any spiritual action
// the user took during their trial counts.
//
// The trial's LENGTH is deliberately absent from both the copy and this
// computation. It is a store-side value that App Store Connect can change
// without a release, so anything that hardcodes it is a promise waiting to
// go stale (W5 Wave B.4).
//
// Trigger conditions (all must be true):
//   1. RevenueCat history shows the user had a trial (`hadTrial() == true`)
//   2. The user is NOT currently premium (`isPremium() == false`)
//      → trial has lapsed
//   3. We haven't already shown the sheet to this user
//      (one-shot SharedPreferences flag)
// ---------------------------------------------------------------------------

const String _shownFlagBaseKey = 'lapsed_trial_sheet_shown';

class LapsedTrialActivity {
  /// Total spiritual actions the user took during their trial window —
  /// sum of reflects + built duas + discovered names. Named generically
  /// because the displayed copy ("you showed up N times") is action-agnostic.
  final int momentsDuringTrial;
  final int daysActiveDuringTrial;

  const LapsedTrialActivity({
    required this.momentsDuringTrial,
    required this.daysActiveDuringTrial,
  });
}

/// Returns the activity stats AND a function to mark the sheet as shown,
/// or null if the sheet should not fire on this launch.
class LapsedTrialDecision {
  final LapsedTrialActivity activity;
  final Future<void> Function() markShown;

  const LapsedTrialDecision({
    required this.activity,
    required this.markShown,
  });
}

Future<LapsedTrialDecision?> resolveLapsedTrialDecision() async {
  final purchase = PurchaseService();
  final isPremium = await purchase.isPremium();
  if (isPremium) return null;

  final hadTrial = await purchase.hadTrial();
  if (!hadTrial) return null;

  final prefs = await SharedPreferences.getInstance();
  final shownKey = supabaseSyncService.scopedKey(_shownFlagBaseKey);
  final alreadyShown = prefs.getBool(shownKey) ?? false;
  if (alreadyShown) return null;

  // Stats: TODAY's usage only — see `_resolveActivity`, which reads the
  // local daily counters and nothing else. This comment previously claimed a
  // 3-day window that the code has never implemented. If we can't resolve any
  // usage, the sheet renders its fallback copy ("You've explored what Premium
  // feels like..."), so returning zeros is safe.
  final activity = await _resolveActivity();

  return LapsedTrialDecision(
    activity: activity,
    markShown: () async {
      final p = await SharedPreferences.getInstance();
      await p.setBool(shownKey, true);
    },
  );
}

Future<LapsedTrialActivity> _resolveActivity() async {
  // Local SharedPreferences only carries today's daily counters via
  // daily_usage_service. For trial-window stats we'd need to pull recent
  // user_daily_usage rows from Supabase. Today's row alone is a reasonable
  // floor — it captures any usage from the just-lapsed-trial day.
  //
  // Consequence, stated plainly because the copy renders it: `daysActive` is
  // therefore only ever 0 or 1, so a user who showed up every day of a 7-day
  // trial still reads "across 1 day". That UNDERSTATES their own engagement
  // on a conversion surface. Widening it to the real window means a Supabase
  // read of `user_daily_usage`; tracked rather than done here because it is a
  // data change, not a copy one.
  final reflects = await getReflectUsageToday();
  final builtDuas = await getBuiltDuaUsageToday();
  final discoverNames = await getDiscoverNameUsageToday();

  final total = reflects + builtDuas + discoverNames;
  final daysActive = total > 0 ? 1 : 0;
  return LapsedTrialActivity(
    momentsDuringTrial: total,
    daysActiveDuringTrial: daysActive,
  );
}
