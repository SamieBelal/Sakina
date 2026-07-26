// The reward half of the fail-closed milestone contract.
//
// `streak_service_test.dart` pins that a refused `claim_streak_milestone`
// returns no `StreakMilestoneResult`. This pins what that BUYS: the notifier
// loop that turns those results into real economy writes — `award_xp`,
// `earn_scrolls`, the 'Consistent' title (derived from the claimed streak) and
// the celebration overlay — must do nothing when the server said no.
//
// The bug this guards: a day-old account running
// `update user_streaks set current_streak = 7` had its Noor correctly denied
// server-side while the client still granted 100 XP + 2 tier-up scrolls + the
// title + the celebration, because `callRpc` mapped the server's RAISE to the
// same `null` as "phone is offline" and the offline-tolerant default treated
// it as success.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  Iterable<Map<String, dynamic>> callsTo(String fn) =>
      fakeSync.rpcCalls.where((c) => c['fn'] == fn);

  test(
      'refused claim → no award_xp, no earn_scrolls, no celebration '
      '(the forged-streak repro)', () async {
    fakeSync.rpcStatuses['claim_streak_milestone'] = RpcStatus.refused;

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.debugHandleStreakMilestones(7);

    expect(callsTo('claim_streak_milestone'), hasLength(1),
        reason: 'the claim is still attempted — it is the server that says no');
    expect(callsTo('award_xp'), isEmpty,
        reason: 'a refused milestone must not pay out its 100 XP');
    expect(callsTo('earn_scrolls'), isEmpty,
        reason: 'a refused milestone must not pay out its 2 tier-up scrolls');
    expect(notifier.state.streakMilestoneReached, isFalse,
        reason: 'no celebration for a milestone the server denied');
    expect(notifier.state.streakMilestoneXp, isNull);
    expect(notifier.state.streakMilestoneScrolls, isNull);

    // The title is derived from the CLAIMED set on read, so leaving day 7
    // unclaimed is what withholds 'Consistent'.
    expect(await getClaimedMilestones(), isEmpty);
  });

  test('unreachable server while authenticated → also pays out nothing',
      () async {
    fakeSync.rpcStatuses['claim_streak_milestone'] = RpcStatus.unavailable;

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.debugHandleStreakMilestones(30);

    expect(callsTo('award_xp'), isEmpty);
    expect(callsTo('earn_scrolls'), isEmpty);
    expect(notifier.state.streakMilestoneReached, isFalse);
  });

  test('server confirms the claim → the rewards DO fire', () async {
    // The control: the same loop still pays out when the server says yes, so
    // the tests above are proving fail-closed rather than a dead code path.
    fakeSync.rpcHandlers['claim_streak_milestone'] =
        (_) async => {'newly_claimed': true, 'noor_awarded': 0};
    fakeSync.rpcHandlers['award_xp'] =
        (_) async => {'total_xp': 100, 'level': 2};
    fakeSync.rpcHandlers['earn_scrolls'] = (_) async => 2;

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.debugHandleStreakMilestones(7);

    expect(callsTo('award_xp'), hasLength(1));
    expect(callsTo('earn_scrolls'), hasLength(1));
    expect(notifier.state.streakMilestoneReached, isTrue);
    expect(notifier.state.streakMilestoneCount, 7);
    expect(notifier.state.streakMilestoneXp, 100);
    expect(notifier.state.streakMilestoneScrolls, 2);
  });
}
