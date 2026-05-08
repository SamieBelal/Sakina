// §12 case 2: when XP crosses a level threshold, awardXp publishes an
// XpGranted event with leveledUp=true so the AppShell can push the overlay.
//
// Previously _handleXpAward wrote celebration fields into DailyLoopState.
// As of Task 7 the overlay trigger moved to AppShell via EconomyEvents.stream,
// so we now assert on the published event rather than on DailyLoopState fields.
//
// Task 9: DailyLoopState.leveledUp and related fields dropped entirely.
// clearLevelUp() and debugSetLeveledUpForTest() also removed.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    await EconomyEvents.resetForTest();
  });

  test(
      'XP crossing level 1 → level 2 threshold publishes XpGranted with '
      'leveledUp=true and correct rewards (EconomyEvents contract)',
      () async {
    // Pre-seed cached XP just below the L2 threshold. Level 2 starts at
    // 75 XP per `xp_service.dart:98`.
    await hydrateXpCache(totalXp: 70);

    fakeSync.rpcHandlers['award_xp'] = (params) async => {
          'total_xp': 100,
          'token_balance': 5,
          'scroll_balance': 0,
        };
    fakeSync.rpcHandlers['earn_tokens'] = (_) async => 5;

    // Collect published events before driving the notifier.
    final events = <XpGranted>[];
    final sub = EconomyEvents.stream
        .where((e) => e is XpGranted)
        .cast<XpGranted>()
        .listen(events.add);

    final notifier = DailyLoopNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await notifier.debugHandleXpAward(30);
    // Let the event loop process stream deliveries (broadcast streams deliver
    // asynchronously — we need one event-loop turn after the RPC resolves).
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();

    // Filter out any XpGranted events that came from _initialize (which reads
    // current cached XP and may emit during boot). We want the one triggered
    // by debugHandleXpAward — it will have leveledUp=true.
    final levelUpEvents = events.where((e) => e.leveledUp).toList();
    expect(levelUpEvents, isNotEmpty,
        reason: 'crossing 75 XP must publish XpGranted{leveledUp: true}');

    final evt = levelUpEvents.first;
    expect(evt.newState.level, 2,
        reason: 'new level number must be 2');
    expect(evt.newState.title, 'Listener',
        reason: 'L2 title (per xp_service xpLevels[1]) must propagate');
    expect(evt.newState.titleArabic, 'مُسْتَمِع');
    expect(evt.newTotal, 100);
    expect(evt.rewards, isNotNull,
        reason: 'rewards struct must be populated so the overlay can render');
    // L2 token reward is 5 (xp_service.dart:99), scrollReward 0.
    expect(evt.rewards!.tokensAwarded, 5);
    expect(evt.rewards!.scrollsAwarded, 0);
    expect(evt.rewards!.levelsGained, 1);
    expect(evt.source, EconomyEventSource.streak,
        reason: '_handleXpAward must tag streak as the source');

    notifier.dispose();
  });

  test(
      'XP grant that does NOT cross a threshold publishes XpGranted with '
      'leveledUp=false', () async {
    await hydrateXpCache(totalXp: 10);

    fakeSync.rpcHandlers['award_xp'] = (_) async => {
          'total_xp': 30,
          'token_balance': null,
          'scroll_balance': null,
        };

    final events = <XpGranted>[];
    final sub = EconomyEvents.stream
        .where((e) => e is XpGranted)
        .cast<XpGranted>()
        .listen(events.add);

    final notifier = DailyLoopNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await notifier.debugHandleXpAward(20);
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();

    final nonLevelUp = events.where((e) => !e.leveledUp).toList();
    expect(nonLevelUp, isNotEmpty,
        reason: '30 XP is still below L2 threshold (75) — '
            'XpGranted must fire but leveledUp must be false');
    expect(events.where((e) => e.leveledUp), isEmpty,
        reason: 'no level-up event should be published');

    notifier.dispose();
  });

}
