import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/purchase_service.dart';

class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier() : super(const DailyRewardsState()) {
    reload();
    // Refresh when the freeze-count cache is mutated out-of-band (the monthly
    // premium top-up writes straight to the cache), so the freeze badge isn't
    // stale until relaunch. A plain cache re-read is enough — the writer
    // already reconciled with the server. Whichever order the grant and this
    // notifier's construction happen in, the state converges: if the event
    // fires before we subscribe, construction reload() reads the fresh cache;
    // if after, this listener catches it.
    _econSub = EconomyEvents.stream.listen((e) async {
      if (e is StreakFreezeChanged) {
        state = await getDailyRewards();
      }
    });
  }

  /// No-op constructor for tests — skips the real [reload] that hits
  /// SharedPreferences and Supabase. Only call from `@visibleForTesting` paths.
  @visibleForTesting
  DailyRewardsNotifier.testOnly() : super(const DailyRewardsState());

  StreamSubscription<EconomyEvent>? _econSub;

  Future<void> reload() async {
    // Reconcile local SharedPrefs cache from server before reading state.
    // Without this, server-side resets (admin wipes user_daily_rewards, or
    // multi-device claims happening on Device A) never reach the local
    // overlay gate — see F1/F5 in docs/qa/findings/2026-04-22-*.
    await reconcileDailyRewardsFromServer();
    state = await getDailyRewards();
  }

  Future<DailyRewardClaimResult> claim() async {
    final result = await claimDailyReward();
    state = await getDailyRewards();
    return result;
  }

  @override
  void dispose() {
    _econSub?.cancel();
    super.dispose();
  }
}

final dailyRewardsProvider =
    StateNotifierProvider<DailyRewardsNotifier, DailyRewardsState>(
  (ref) => DailyRewardsNotifier(),
);

/// Atomic snapshot of the user's premium status. Combines the active
/// entitlement check with the billing-issue timestamp into a single
/// `AsyncValue` so the Settings premium card never sees an inconsistent
/// intermediate state (one provider resolved, the other still loading).
///
/// Short-circuits the billing-issue fetch when the user isn't premium —
/// no point asking RevenueCat about a billing issue on a non-subscriber.
///
/// Refreshed via `ref.invalidate(premiumStateProvider)` after purchase,
/// restore, sign-out, account deletion, or on `AppLifecycleState.resumed`.
typedef PremiumState = ({bool isPremium, String? billingIssueAt});

final premiumStateProvider = FutureProvider<PremiumState>((ref) async {
  final service = PurchaseService();
  final isPremium = await service.isPremium();
  final billingIssueAt =
      isPremium ? await service.getBillingIssueDetectedAt() : null;
  return (isPremium: isPremium, billingIssueAt: billingIssueAt);
});
