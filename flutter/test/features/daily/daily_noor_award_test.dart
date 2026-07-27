// The daily-muḥāsabah Noor faucet (spec §3: completing the daily grants
// +10 Noor).
//
// `awardDailyNoor()` existed with ZERO production call sites — so with
// milestone Noor as the only other source, a user could not earn Noor by using
// the app at all, while the wardrobe shipped a full spend surface. This pins
// the faucet to the live completion path ("Ameen" → `completeDeeper`).
//
// The server is authoritative and idempotent: `award_daily_noor()` verifies a
// `user_checkin_history` row for ITS OWN UTC date and dedupes on
// `daily:<server date>`, returning 0 on a replay. The client mirrors what the
// server reports and mints nothing.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/cosmetics_service.dart';
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

  Iterable<Map<String, dynamic>> awardCalls() =>
      fakeSync.rpcCalls.where((c) => c['fn'] == 'award_daily_noor');

  test('completing the daily awards the Noor exactly once', () async {
    fakeSync.rpcHandlers['award_daily_noor'] = (_) async => 10;

    final events = <(String, Map<String, dynamic>)>[];
    CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
    addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.completeDeeper();

    expect(notifier.state.currentStep, DailyLoopStep.completed);
    expect(awardCalls(), hasLength(1),
        reason: 'the daily faucet must fire on the live completion path');
    expect((await getCosmeticsState()).noorBalance, 10);
    expect(events.map((e) => e.$1), ['noor_earned']);
    expect(events.single.$2, {'amount': 10, 'reason': 'daily'});
  });

  test('a second completeDeeper in the same cycle does not re-award', () async {
    fakeSync.rpcHandlers['award_daily_noor'] = (_) async => 10;

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.completeDeeper();
    await notifier.completeDeeper();

    expect(awardCalls(), hasLength(1),
        reason: 'completeDeeper early-returns once the step is completed, so '
            'the faucet cannot fire twice per completion');
    expect((await getCosmeticsState()).noorBalance, 10);
  });

  test('a second completion the same day credits nothing extra (server dedupe)',
      () async {
    // First completion: the server mints.
    fakeSync.rpcHandlers['award_daily_noor'] = (_) async => 10;
    final first = DailyLoopNotifier(skipInitForTests: true);
    await first.completeDeeper();
    first.dispose();

    expect((await getCosmeticsState()).noorBalance, 10);

    // Second muḥāsabah the same day (reset → complete again). The server
    // recognises the `daily:<date>` dedupe key and mints nothing.
    fakeSync.rpcHandlers['award_daily_noor'] = (_) async => 0;

    final events = <(String, Map<String, dynamic>)>[];
    CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
    addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

    final second = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(second.dispose);
    await second.completeDeeper();

    expect((await getCosmeticsState()).noorBalance, 10,
        reason: 'the client mirrors the server — a 0 must not credit');
    expect(events, isEmpty,
        reason: 'a deduped replay must not emit a second noor_earned');
  });

  test('a refused / unreachable award never breaks the completion', () async {
    // No handler → the RPC yields nothing. Completion is the user-visible
    // contract; the faucet is best-effort on top of it.
    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.completeDeeper();

    expect(notifier.state.currentStep, DailyLoopStep.completed);
    expect((await getCosmeticsState()).noorBalance, 0);
  });
}
