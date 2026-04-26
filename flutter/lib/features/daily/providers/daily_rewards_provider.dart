import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/purchase_service.dart';

class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier() : super(const DailyRewardsState()) {
    reload();
  }

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
}

final dailyRewardsProvider =
    StateNotifierProvider<DailyRewardsNotifier, DailyRewardsState>(
  (ref) => DailyRewardsNotifier(),
);

/// Whether the current user has an active premium entitlement. Used by the
/// daily reward UI to render scaled token / scroll labels. Refreshed via
/// `ref.invalidate(isPremiumProvider)` after a purchase or restore.
final isPremiumProvider = FutureProvider<bool>((ref) async {
  return PurchaseService().isPremium();
});
