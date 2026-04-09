import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('syncDailyRewardsCacheFromSupabase hydrates freeze ownership', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_daily_rewards': jsonEncode({
        'currentDay': 3,
        'lastClaimDate': '2026-04-09',
        'streakFreezeOwned': false,
      }),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    fakeSync.rows['user_daily_rewards:user-1'] = {'streak_freeze_owned': true};
    SupabaseSyncService.debugSetInstance(fakeSync);

    await syncDailyRewardsCacheFromSupabase();

    final state = await getDailyRewards();
    expect(state.currentDay, 3);
    expect(state.streakFreezeOwned, isTrue);
  });

  test('grantStreakFreeze updates local cache and remote row', () async {
    await grantStreakFreeze();

    final state = await getDailyRewards();
    expect(state.streakFreezeOwned, isTrue);
    expect(fakeSync.rows['user_daily_rewards:user-1']?['streak_freeze_owned'], isTrue);
  });

  test('consumeStreakFreeze clears remote-backed freeze', () async {
    fakeSync.rows['user_daily_rewards:user-1'] = {'streak_freeze_owned': true};

    final consumed = await consumeStreakFreeze();

    expect(consumed, isTrue);
    expect(fakeSync.rows['user_daily_rewards:user-1']?['streak_freeze_owned'], isFalse);
    expect((await getDailyRewards()).streakFreezeOwned, isFalse);
  });

  test('consumeStreakFreeze returns false when none is owned', () async {
    fakeSync.rows['user_daily_rewards:user-1'] = {'streak_freeze_owned': false};

    final consumed = await consumeStreakFreeze();

    expect(consumed, isFalse);
  });
}
