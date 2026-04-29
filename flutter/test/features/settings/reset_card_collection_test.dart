import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/settings/screens/settings_screen.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Regression test for the "Clear Card Collection" Danger Zone button.
///
/// Bug: `_resetCardCollection` only wiped local card prefs + local daily-loop
/// state. It did NOT call `resetDailyRewardsOnServer`, so the server's
/// `user_daily_rewards` row still marked today as claimed. The next reconcile
/// re-hydrated that stale state and the launch overlay refused to re-fire,
/// even though the snackbar promised "Every check-in will now discover a new
/// card."
///
/// The fix routes the danger-zone button through
/// `performCardCollectionDangerReset`, which wipes server + local + launch
/// gate together (mirroring `_resetDailyLoop`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(SupabaseSyncService.debugReset);

  group('performCardCollectionDangerReset', () {
    test(
        'wipes user_daily_rewards on the server so the launch overlay can re-fire',
        () async {
      SharedPreferences.setMockInitialValues({});
      final fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      var resetDailyLoopCalled = false;
      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {
          resetDailyLoopCalled = true;
        },
      );

      // The bug was the absence of this upsert. Pin it explicitly.
      final dailyRewardsResets = fakeSync.upsertCalls
          .where((c) => c['table'] == 'user_daily_rewards')
          .toList();
      expect(dailyRewardsResets, hasLength(1),
          reason: 'must reset user_daily_rewards exactly once');
      expect(dailyRewardsResets.single['userId'], 'user-1');
      expect(dailyRewardsResets.single['data'], {
        'current_day': 0,
        'last_claim_date': null,
      });
      expect(resetDailyLoopCalled, isTrue,
          reason: 'must reset local daily-loop state');
    });

    test('wipes the local card collection cache', () async {
      SharedPreferences.setMockInitialValues({
        'sakina_card_collection:user-1': jsonEncode({
          'ids': [1, 2, 3],
          'dates': {'1': '2026-04-26'},
          'tiers': {'1': 1},
          'tierUpDates': <String, String>{},
        }),
      });
      final fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {},
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sakina_card_collection:user-1');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['ids'], isEmpty);
    });

    test('deletes the user_card_collection row on the server', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {},
      );

      final cardDeletes = fakeSync.deleteCalls
          .where((c) => c['table'] == 'user_card_collection')
          .toList();
      expect(cardDeletes, hasLength(1));
      expect(cardDeletes.single['column'], 'user_id');
      expect(cardDeletes.single['value'], 'user-1');
    });

    test('clears the local launch-gate key so the overlay can re-fire',
        () async {
      SharedPreferences.setMockInitialValues({
        'sakina_launch_gate:user-1': '2026-04-28',
      });
      final fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {},
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sakina_launch_gate:user-1'), isNull);
    });

    test(
        'order matters: clears collection BEFORE resetting daily-loop state '
        'so the local-state reload sees an empty collection',
        () async {
      SharedPreferences.setMockInitialValues({});
      final fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      final order = <String>[];

      // Snapshot delete-call count when the daily-loop reset runs — if the
      // collection delete fired first, the count will already be 1.
      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {
          final cardDeleteCount = fakeSync.deleteCalls
              .where((c) => c['table'] == 'user_card_collection')
              .length;
          final dailyRewardsResetCount = fakeSync.upsertCalls
              .where((c) => c['table'] == 'user_daily_rewards')
              .length;
          order.add('daily_loop_state '
              'cardDeletes=$cardDeleteCount '
              'rewardsResets=$dailyRewardsResetCount');
        },
      );

      expect(order, [
        'daily_loop_state cardDeletes=1 rewardsResets=1',
      ]);
    });

    test('skips server writes when no user is signed in', () async {
      SharedPreferences.setMockInitialValues({
        'sakina_card_collection': jsonEncode({
          'ids': [1],
          'dates': <String, String>{},
          'tiers': <String, int>{},
          'tierUpDates': <String, String>{},
        }),
        'sakina_launch_gate': '2026-04-28',
      });
      final fakeSync = FakeSupabaseSyncService(userId: null);
      SupabaseSyncService.debugSetInstance(fakeSync);

      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {},
      );

      // Local prefs still wiped.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sakina_card_collection');
      expect(raw, isNotNull);
      expect((jsonDecode(raw!) as Map)['ids'], isEmpty);
      expect(prefs.getString('sakina_launch_gate'), isNull);

      // No server writes attempted — auth-less callers shouldn't 401.
      expect(fakeSync.upsertCalls, isEmpty);
      expect(fakeSync.deleteCalls, isEmpty);
    });
  });
}
