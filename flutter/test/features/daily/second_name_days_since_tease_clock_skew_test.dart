// Defect 2 (P2) — `days_since_tease` must never go negative.
//
// `daysSinceTease` in `_emitSecondNameLifecycle` computes
// `at.difference(seedAt).inDays`, where `at` is the DEVICE wall clock
// (`debugDailyLoopClock`) and `seedAt` is the SERVER's `now()` captured when
// `seed_name_queue` unsealed position 1 (the tease). Nothing clamped
// `at >= seedAt`, so a device clock behind the server's — a misconfigured
// phone, or a QA tester winding it back (this codebase documents doing
// exactly that via `GiftService.debugGiftClock`) — produced a NEGATIVE
// `days_since_tease`.
//
// That property answers "did the queue keep its promise on schedule", so a
// negative value is not noise: it silently corrupts the read. The fix floors
// it at 0 — a tease cannot have happened in the future relative to the
// instant measuring it, so a negative reading is always a clock problem.
//
// Harness mirrors `second_name_analytics_test.dart` exactly (same fake
// `NameQueueService`, same event-capture hook) — this suite only varies the
// clock relative to the seed timestamp.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/reveal_entry_source.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;
  late List<Map<String, dynamic>> queueRows;
  late dynamic unsealResult;
  late List<(String, Map<String, dynamic>)> events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugResetRevealEntrySource();
    debugUserTimeZoneOverride = 'UTC';
    queueRows = [];
    unsealResult = null;
    events = [];
    DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    debugResetRevealEntrySource();
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  DailyLoopNotifier makeNotifier() => DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => queueRows,
          callRpc: (_, __) async => unsealResult,
        ),
      );

  Map<String, dynamic> serverRow(int position, int nameId,
          {DateTime? unsealedAt}) =>
      {
        'position': position,
        'name_id': nameId,
        'unsealed_at': unsealedAt?.toIso8601String(),
      };

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Iterable<(String, Map<String, dynamic>)> named(String event) =>
      events.where((e) => e.$1 == event);

  test(
      'a device clock BEHIND the server (seedAt) yields 0, never negative',
      () async {
    // Position 1 (the tease) was seeded by the SERVER at Aug 4 — but the
    // DEVICE clock driving this call thinks it is still Aug 1 (3 days
    // behind). Without the clamp, `at.difference(seedAt).inDays` is -3.
    //
    // MUTATION THAT MUST FAIL THIS TEST: remove the `diff < 0 ? 0 : diff`
    // clamp in `_emitSecondNameLifecycle`'s `daysSinceTease` (revert to the
    // bare `at.difference(seedAt).inDays`) — this assertion then reads -3.
    final seedAt = DateTime.utc(2026, 8, 4, 3);
    final deviceNow = DateTime.utc(2026, 8, 1, 3);
    debugDailyLoopClock = () => deviceNow;

    queueRows = [
      serverRow(1, 11, unsealedAt: seedAt),
      serverRow(2, 22),
      serverRow(3, 33),
    ];
    unsealResult = [serverRow(2, 22, unsealedAt: deviceNow)];
    // Position 1's Name was already met (onboarding's own reveal). Needed
    // here only because `seedAt` sits AFTER `deviceNow` — the planner's rule
    // 2 (`name_queue_planner.dart`) treats an unsealed row as "recent" purely
    // by `unsealedAt.isAfter(floorEdge)`, and with the device this far
    // behind, `floorEdge` sits behind position 1's stamp regardless of how it
    // compares to position 2. Marking position 1 discovered keeps the plan on
    // rule 5 (QueueUnseal), which is the branch this test's defect lives in;
    // without it the plan would resolve to QueueResume(position 1) and no
    // `second_name_unseal_available`/`second_name_unsealed` would fire at
    // all — a planner-rule interaction that is not what this suite is
    // pinning.
    await engageCard(11);

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    final available = named(AnalyticsEvents.secondNameUnsealAvailable).toList();
    expect(available, hasLength(1));
    expect(available.single.$2[AnalyticsEvents.propDaysSinceTease], 0,
        reason: 'a tease cannot have happened in the future relative to the '
            'device clock measuring it — a negative reading is always a '
            'clock problem, never a real one');

    final unsealed = named(AnalyticsEvents.secondNameUnsealed).toList();
    expect(unsealed, hasLength(1));
    expect(unsealed.single.$2[AnalyticsEvents.propDaysSinceTease], 0);
  });

  test('an ordinary forward difference is unchanged by the clamp', () async {
    final seedAt = DateTime.utc(2026, 8, 1, 3);
    final deviceNow = DateTime.utc(2026, 8, 4, 3);
    debugDailyLoopClock = () => deviceNow;

    queueRows = [
      serverRow(1, 11, unsealedAt: seedAt),
      serverRow(2, 22),
      serverRow(3, 33),
    ];
    unsealResult = [serverRow(2, 22, unsealedAt: deviceNow)];

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    final unsealed = named(AnalyticsEvents.secondNameUnsealed).toList();
    expect(unsealed, hasLength(1));
    expect(unsealed.single.$2[AnalyticsEvents.propDaysSinceTease], 3,
        reason: 'the clamp must not touch a real, non-negative reading');
  });

  test('the same instant yields 0, not null and not negative', () async {
    final sameInstant = DateTime.utc(2026, 8, 2, 9);
    debugDailyLoopClock = () => sameInstant;

    queueRows = [
      serverRow(1, 11, unsealedAt: sameInstant),
      serverRow(2, 22),
      serverRow(3, 33),
    ];
    unsealResult = [serverRow(2, 22, unsealedAt: sameInstant)];
    // See the comment in the "behind the server" test above — position 1
    // must already be met or the planner's rule 2 resumes it instead of
    // reaching rule 5 (QueueUnseal).
    await engageCard(11);

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    final unsealed = named(AnalyticsEvents.secondNameUnsealed).toList();
    expect(unsealed, hasLength(1));
    expect(unsealed.single.$2[AnalyticsEvents.propDaysSinceTease], 0);
  });
}
