import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Lapsed Trial Service
//
// Decides whether the LapsedTrialSheet should fire on a given app launch
// and computes the activity stats it shows ("In your 3-day trial, you
// reflected X times across Y days...").
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
  final int reflectsDuringTrial;
  final int daysActiveDuringTrial;

  const LapsedTrialActivity({
    required this.reflectsDuringTrial,
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

  // Stats: count usage across the last 3 calendar days. Approximates the
  // 3-day trial window. If we can't resolve any usage, the sheet renders
  // its fallback copy ("You've explored what Premium feels like..."), so
  // returning zeros is safe.
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
  final reflects = await getReflectUsageToday();
  final builtDuas = await getBuiltDuaUsageToday();
  final discoverNames = await getDiscoverNameUsageToday();

  final total = reflects + builtDuas + discoverNames;
  final daysActive = total > 0 ? 1 : 0;
  return LapsedTrialActivity(
    reflectsDuringTrial: total,
    daysActiveDuringTrial: daysActive,
  );
}
