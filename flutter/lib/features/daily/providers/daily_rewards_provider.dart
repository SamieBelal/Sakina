import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/daily_rewards_service.dart';

class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier() : super(const DailyRewardsState()) {
    reload();
  }

  Future<void> reload() async {
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
