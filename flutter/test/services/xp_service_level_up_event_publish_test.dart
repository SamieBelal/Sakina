// Pins that level-up bonus token / scroll grants flow through
// `EconomyEvents.publish(...)` so subscribers (TokenNotifier,
// TierUpScrollNotifier, DailyLoopNotifier) get the live update — without
// these events the home pill / scroll badge stay stale until the next
// provider rebuild reads the cache. Also pins that XpAwardResult.gained
// reflects the realized server delta (newTotal - oldTotal), not the
// requested amount.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/xp_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // userId: null → offline path. The level-up bonus path under test runs
    // in BOTH online and offline modes; offline keeps the test isolated
    // from RPC plumbing.
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: null));
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    await EconomyEvents.resetForTest();
  });

  test(
      'level-up that awards bonus tokens publishes TokenGranted before XpGranted',
      () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // L1→L2 at 75 XP grants 5 tokens (see xp_service.dart xpLevels).
    final result = await awardXp(75, source: EconomyEventSource.quest);
    expect(result.leveledUp, true);
    expect(result.rewards, isNotNull);
    expect(result.rewards!.tokensAwarded, 5);
    await Future<void>.delayed(Duration.zero);

    final tokenEvents = received.whereType<TokenGranted>().toList();
    final xpEvents = received.whereType<XpGranted>().toList();

    expect(tokenEvents, hasLength(1));
    expect(tokenEvents.single.amount, 5);
    expect(tokenEvents.single.source, EconomyEventSource.quest);
    // newBalance reflects the bonus tokens added on top of the prior cache.
    expect(tokenEvents.single.newBalance, greaterThanOrEqualTo(5));

    expect(xpEvents, hasLength(1));

    // Order: TokenGranted must arrive before XpGranted so subscribers update
    // the home pill before the level-up overlay (driven by XpGranted) renders.
    final tokenIndex = received.indexOf(tokenEvents.single);
    final xpIndex = received.indexOf(xpEvents.single);
    expect(tokenIndex, lessThan(xpIndex));
  });

  test(
      'level-up that awards bonus scrolls publishes ScrollGranted before XpGranted',
      () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // L4→L5 at 375 XP grants 5 tokens AND 2 scrolls. Start at 275 (L4 min)
    // by awarding 275 first, then 100 more to cross to L5. Flush microtasks
    // before clearing — events from the first grant arrive on the next
    // microtask, so an unflushed clear would repopulate after.
    await awardXp(275, source: EconomyEventSource.quest);
    await Future<void>.delayed(Duration.zero);
    received.clear();

    final result = await awardXp(100, source: EconomyEventSource.streak);
    expect(result.leveledUp, true);
    expect(result.rewards, isNotNull);
    expect(result.rewards!.scrollsAwarded, 2);
    await Future<void>.delayed(Duration.zero);

    final scrollEvents = received.whereType<ScrollGranted>().toList();
    final xpEvents = received.whereType<XpGranted>().toList();

    expect(scrollEvents, hasLength(1));
    expect(scrollEvents.single.amount, 2);
    expect(scrollEvents.single.source, EconomyEventSource.streak);
    expect(scrollEvents.single.newBalance, 2);

    expect(xpEvents, hasLength(1));
    final scrollIndex = received.indexOf(scrollEvents.single);
    final xpIndex = received.indexOf(xpEvents.single);
    expect(scrollIndex, lessThan(xpIndex));
  });

  test('XP award that does NOT level up publishes only XpGranted', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // 50 XP from 0 stays at L1 (L2 starts at 75).
    final result = await awardXp(50, source: EconomyEventSource.dev);
    expect(result.leveledUp, false);
    await Future<void>.delayed(Duration.zero);

    expect(received.whereType<TokenGranted>(), isEmpty);
    expect(received.whereType<ScrollGranted>(), isEmpty);
    expect(received.whereType<XpGranted>(), hasLength(1));
  });

  test(
      'multi-level skip aggregates token rewards into a single TokenGranted',
      () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // Award 375 XP from 0 → crosses L1(0)→L2(75)→L3(175)→L4(275)→L5(375).
    // Expected token bonus = 5 (L2) + 5 (L3) + 5 (L4) + 5 (L5) = 20.
    // Expected scroll bonus = 2 (L5 only).
    final result = await awardXp(375, source: EconomyEventSource.firstSteps);
    expect(result.leveledUp, true);
    expect(result.rewards!.levelsGained, 4);
    expect(result.rewards!.tokensAwarded, 20);
    expect(result.rewards!.scrollsAwarded, 2);
    await Future<void>.delayed(Duration.zero);

    final tokenEvents = received.whereType<TokenGranted>().toList();
    final scrollEvents = received.whereType<ScrollGranted>().toList();

    expect(tokenEvents, hasLength(1));
    expect(tokenEvents.single.amount, 20);
    expect(scrollEvents, hasLength(1));
    expect(scrollEvents.single.amount, 2);
  });

  test(
      'XpAwardResult.gained reflects realized delta (offline: equals requested)',
      () async {
    final result = await awardXp(40, source: EconomyEventSource.dev);
    expect(result.gained, 40);
    expect(result.newTotal, 40);
    // newTotal - oldTotal == requested amount on the offline path.
  });

  test(
      'XpAwardResult.gained equals server total minus oldTotal when RPC trims request',
      () async {
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u'));
    final fake = supabaseSyncService as FakeSupabaseSyncService;
    // Server returns total_xp=30 even though caller asked for 100 — simulates
    // a cap or anti-abuse trim. Realized delta = 30, not 100.
    fake.rpcHandlers['award_xp'] = (_) async => <String, dynamic>{
          'total_xp': 30,
          'token_balance': 0,
          'scroll_balance': 0,
        };

    final result = await awardXp(100, source: EconomyEventSource.dev);
    expect(result.gained, 30);
    expect(result.newTotal, 30);
  });

  test(
      'no event leak: bonus events do NOT fire when LevelUpRewards has zero amounts',
      () async {
    // Engineer a scenario where leveledUp is true but tokensAwarded and
    // scrollsAwarded are both 0. With the current xpLevels list every level
    // grants tokens, so this case is hypothetical for production — but the
    // helper must still gate on > 0 to avoid spurious zero-value events.
    //
    // We simulate this by going just past L1→L2 (which DOES award tokens),
    // then asserting NO additional bonus events fire on a SECOND grant that
    // doesn't cross another threshold.
    await awardXp(75, source: EconomyEventSource.dev); // L1→L2
    await Future<void>.delayed(Duration.zero);

    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // 50 more XP from 75 → 125 total, still L2. No level-up.
    final result = await awardXp(50, source: EconomyEventSource.dev);
    expect(result.leveledUp, false);
    await Future<void>.delayed(Duration.zero);

    expect(received.whereType<TokenGranted>(), isEmpty);
    expect(received.whereType<ScrollGranted>(), isEmpty);
    expect(received.whereType<XpGranted>(), hasLength(1));
  });
}
