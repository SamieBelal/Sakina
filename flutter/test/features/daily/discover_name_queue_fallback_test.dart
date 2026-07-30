import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/name_queue_cache.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// Degradation paths for the queue seam (W3 plan §5, §6b).
///
/// The rule these pin: **an unseal failure is an error the user retries, never a
/// silent substitution.** The day's cap was already consumed at the CTA, so
/// quietly handing over a random Name spends the D1 promise on a network blip and
/// there is no second chance that day.
class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => nowUtc;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    debugLastPickExclude = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  Map<String, dynamic> serverRow(int position, int nameId,
          {DateTime? unsealedAt}) =>
      {
        'position': position,
        'name_id': nameId,
        'unsealed_at': unsealedAt?.toIso8601String(),
      };

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  /// Lets the constructor's `_initialize()` land before the reveal runs.
  ///
  /// Necessary because `copyWith` clears `error` unconditionally (it is how the
  /// bypass wrappers get a clean read), so a late-resolving `_initialize` would
  /// wipe the error these tests are asserting. Pre-existing behaviour; production
  /// never races it because `_initialize` is kicked off at construction, long
  /// before a user taps the CTA.
  Future<void> warmUp(DailyLoopNotifier notifier) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifier.state.loaded, isTrue);
  }

  test('an unseal RPC throw leaves state.error and engages NOTHING', () async {
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [serverRow(1, 11), serverRow(2, 22)],
        callRpc: (_, __) async => throw StateError('offline'),
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(notifier.state.error, isNotNull);
    expect(notifier.state.checkinDone, isFalse);
    expect(notifier.state.checkinLoading, isFalse);
    expect(notifier.state.engagedCard, isNull);
    expect(debugLastPickExclude, isNull,
        reason: 'no automatic degrade to an off-queue pull — the cap was already '
            'spent at the CTA, so a blip must not consume the D1 promise');
    // Nothing was granted: no card row was written.
    expect(
      fakeSync.upsertCalls.where((c) => c['table'] == 'user_card_collection'),
      isEmpty,
    );
    expect((await getCardCollection()).discoveredIds, isEmpty);
  });

  test('a queue row pointing at an unknown name_id fails rather than '
      'substituting a random Name', () async {
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [serverRow(1, 999_999), serverRow(2, 22)],
        callRpc: (_, __) async => [serverRow(1, 999_999, unsealedAt: nowUtc)],
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(notifier.state.error, isNotNull);
    expect(notifier.state.engagedCard, isNull);
    expect(debugLastPickExclude, isNull);
  });

  test('a failed RLS select falls back to the advisory cache', () async {
    await writeCachedNameQueue([
      const NameQueueRow(position: 1, nameId: 11),
      const NameQueueRow(position: 2, nameId: 22),
    ]);

    var unsealCalls = 0;
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => throw StateError('no network'),
        callRpc: (_, __) async {
          unsealCalls++;
          return [serverRow(1, 11, unsealedAt: nowUtc)];
        },
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(unsealCalls, 1,
        reason: 'the cache may say a sealed row exists; only the RPC unseals');
    expect(notifier.state.engagedCard!.id, 11);
    expect(notifier.state.revealSource, revealSourceQueue);
  });

  test('offline with NO cache is QueueAbsent — today\'s exact path', () async {
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => throw StateError('no network'),
        callRpc: (_, __) async => throw StateError('unreachable'),
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    expect(notifier.state.error, isNull);
    expect(notifier.state.checkinDone, isTrue);
    expect(notifier.state.revealSource, revealSourceGacha);
    expect(debugLastPickExclude, isEmpty);
  });

  test('a successful select refreshes the mirror', () async {
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [
          serverRow(1, 11, unsealedAt: DateTime.utc(2026, 8, 1, 15)),
          serverRow(2, 22),
        ],
        callRpc: (_, __) async => [serverRow(2, 22, unsealedAt: nowUtc)],
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();

    final cached = await readCachedNameQueue();
    expect(cached.map((r) => r.position), [1, 2]);
    expect(cached[1].unsealedAt, isNotNull,
        reason: 'the freshly unsealed row is merged into the mirror, so the '
            'cohort probe and the next plan both see it');
  });

  test('a retry after a failed unseal re-enters cleanly and returns the SAME '
      'row (RPC idempotence)', () async {
    var attempts = 0;
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => [serverRow(1, 11), serverRow(2, 22)],
        callRpc: (_, __) async {
          attempts++;
          if (attempts == 1) throw StateError('timeout');
          return [serverRow(1, 11, unsealedAt: nowUtc)];
        },
      ),
    );
    addTearDown(notifier.dispose);
    await warmUp(notifier);

    await notifier.discoverName();
    await settle();
    expect(notifier.state.error, isNotNull);

    await notifier.discoverName();
    await settle();

    expect(notifier.state.error, isNull);
    expect(notifier.state.engagedCard!.id, 11);
    expect(notifier.state.revealQueuePosition, 1);
    expect(attempts, 2, reason: 'exactly one RPC per attempt — no position burnt');
  });
}
