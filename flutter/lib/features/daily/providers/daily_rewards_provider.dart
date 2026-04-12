import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/purchase_service.dart';

class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier() : super(const DailyRewardsState()) {
    reload();
  }

  Future<void> reload() async {
    state = await getDailyRewards();
  }

  Future<DailyRewardClaimResult> claim() async {
    final isPremium = await PurchaseService().isPremium();
    final result = await claimDailyReward(isPremium: isPremium);
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
