import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// Pins the `discoverName` queue seam (W3 plan §3b, §6a, §12 "The seam").
///
/// Every instant is a literal pinned UTC value. The reference "now" is
/// 2026-08-04T03:00Z, which is 2026-08-03 20:00 America/Los_Angeles.
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
  late List<String> queueCalls;
  late List<Map<String, dynamic>> queueRows;
  late dynamic unsealResult;
  late Object? unsealError;
  late Object? selectError;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => nowUtc;
    queueCalls = [];
    queueRows = [];
    unsealResult = null;
    unsealError = null;
    selectError = null;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    debugLastPickExclude = null;
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  NameQueueService buildQueue() => NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async {
          queueCalls.add('select');
          if (selectError != null) throw selectError!;
          return queueRows;
        },
        callRpc: (fn, params) async {
          queueCalls.add('rpc:$fn');
          if (unsealError != null) throw unsealError!;
          return unsealResult;
        },
      );

  DailyLoopNotifier makeNotifier() =>
      DailyLoopNotifier(nameQueueService: buildQueue());

  Map<String, dynamic> serverRow(int position, int nameId, {DateTime? unsealedAt}) =>
      {
        'position': position,
        'name_id': nameId,
        'unsealed_at': unsealedAt?.toIso8601String(),
      };

  /// Let the fire-and-forget deeper-reflection prefetch settle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  group('QueueUnseal', () {
    test('engages the RPC\'s name_id, not pickNextCard\'s', () async {
      queueRows = [
        serverRow(1, 11, unsealedAt: DateTime.utc(2026, 8, 1, 15)),
        serverRow(2, 22),
        serverRow(3, 33),
      ];
      unsealResult = [serverRow(2, 22, unsealedAt: nowUtc)];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.error, isNull);
      expect(notifier.state.engagedCard!.id, 22);
      expect(notifier.state.revealSource, revealSourceQueue);
      expect(notifier.state.revealQueuePosition, 2);
      // Wave 3 fills this; it must be null here so the AI prefetch still runs.
      expect(notifier.state.revealDeck, isNull);
      expect(queueCalls, ['select', 'rpc:${NameQueueService.unsealRpcName}']);
      expect(debugLastPickExclude, isNull,
          reason: 'a resolved queue row must not consult pickNextCard at all');
    });

    test('the unseal RPC runs BEFORE engageCard', () async {
      queueRows = [serverRow(1, 11), serverRow(2, 22)];
      final order = <String>[];
      CardCollectionAnalytics.onAnalyticsEvent = (e, _) => order.add('engage:$e');
      addTearDown(() => CardCollectionAnalytics.onAnalyticsEvent = null);
      unsealResult = [serverRow(1, 11, unsealedAt: nowUtc)];

      final notifier = DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => queueRows,
          callRpc: (fn, _) async {
            order.add('rpc:$fn');
            return unsealResult;
          },
        ),
      );
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(order.first, 'rpc:${NameQueueService.unsealRpcName}');
      expect(order.any((e) => e.startsWith('engage:')), isTrue);
    });

    test('sealed remaining counts down past the position just unsealed',
        () async {
      queueRows = [
        serverRow(1, 11, unsealedAt: DateTime.utc(2026, 8, 1, 15)),
        serverRow(2, 22),
        serverRow(3, 33),
        serverRow(4, 44),
      ];
      unsealResult = [serverRow(2, 22, unsealedAt: nowUtc)];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.queueSealedRemaining, 2);
    });

    test('a null RPC result degrades to an ordinary pull, not an error',
        () async {
      // Another device drained the queue between the advisory read and the call.
      queueRows = [serverRow(1, 11), serverRow(2, 22)];
      unsealResult = null;

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.error, isNull);
      expect(notifier.state.checkinDone, isTrue);
      expect(notifier.state.revealSource, revealSourceGacha);
      expect(notifier.state.revealQueuePosition, isNull);
      expect(debugLastPickExclude, {11, 22},
          reason: 'the still-sealed positions stay excluded from the fallback');
    });
  });

  group('QueueResume', () {
    test('re-presents an unsealed-but-unmet row without calling the RPC',
        () async {
      // Unsealed 2026-08-04T01:00Z = 2026-08-03 18:00 LA, i.e. the user's today,
      // and never met — they closed the app before the card landed.
      queueRows = [
        serverRow(1, 11, unsealedAt: DateTime.utc(2026, 7, 30, 15)),
        serverRow(2, 22, unsealedAt: DateTime.utc(2026, 8, 4, 1)),
        serverRow(3, 33),
      ];
      await engageCard(11); // position 1 was met

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.engagedCard!.id, 22);
      expect(notifier.state.revealQueuePosition, 2);
      expect(queueCalls, ['select'],
          reason: 'resume must not spend an unseal — the position is already '
              'consumed and the RPC would skip the Name forever');
    });
  });

  group('QueueHold', () {
    test('never calls unsealNext() and pulls with the sealed set excluded',
        () async {
      // Position 2 unsealed 2h ago and already met: inside the 20h floor.
      queueRows = [
        serverRow(1, 11, unsealedAt: DateTime.utc(2026, 7, 30, 15)),
        serverRow(2, 22, unsealedAt: DateTime.utc(2026, 8, 4, 1)),
        serverRow(3, 33),
        serverRow(4, 44),
      ];
      await engageCard(11);
      await engageCard(22);

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(queueCalls, ['select'],
          reason: 'the RPC cannot advance inside the floor — do not ask it');
      expect(notifier.state.error, isNull);
      expect(notifier.state.revealSource, revealSourceGacha);
      expect(debugLastPickExclude, {33, 44});
      expect({33, 44}.contains(notifier.state.engagedCard!.id), isFalse);
    });
  });

  group('QueueExhausted', () {
    test('pulls normally with an empty exclude once all seven are unsealed',
        () async {
      queueRows = [
        for (var i = 1; i <= 7; i++)
          serverRow(i, i * 10, unsealedAt: DateTime.utc(2026, 7, 20 + i, 5)),
      ];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(queueCalls, ['select']);
      expect(notifier.state.revealSource, revealSourceGacha);
      expect(debugLastPickExclude, isEmpty,
          reason: 'nothing is sealed, so the exclusion set is empty by '
              'definition — no copy change, no ceremony');
    });
  });

  group('QueueAbsent — the legacy gate', () {
    test('a legacy reveal calls pickNextCard with an EMPTY exclude', () async {
      queueRows = const [];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(queueCalls, ['select'], reason: 'no unseal RPC for a legacy user');
      expect(debugLastPickExclude, isEmpty);
      expect(notifier.state.checkinDone, isTrue);
      expect(notifier.state.revealSource, revealSourceGacha);
      expect(notifier.state.revealQueuePosition, isNull);
      expect(notifier.state.queueSealedRemaining, 0);
    });

    test('an unauthenticated session is QueueAbsent, not an error', () async {
      fakeSync.userId = null;
      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.error, isNull);
      expect(notifier.state.checkinDone, isTrue);
      expect(debugLastPickExclude, isEmpty);
    });
  });

  group('surviving structure', () {
    test('saveCheckinRecord still writes q1:discover with empty q2-q4',
        () async {
      queueRows = [serverRow(1, 11), serverRow(2, 22)];
      unsealResult = [serverRow(1, 11, unsealedAt: nowUtc)];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      final inserts = fakeSync.insertCalls
          .where((c) => c['table'] == 'user_checkin_history')
          .toList();
      expect(inserts, hasLength(1));
      final data = inserts.single['data'] as Map<String, dynamic>;
      expect(data['q1'], 'discover');
      expect(data['q2'], '');
      expect(data['q3'], '');
      // toSupabaseRow maps an empty q4 to null — unchanged by W3.
      expect(data['q4'], isNull);
    });

    test('a throwing analytics hook does not error a completed queue reveal',
        () async {
      // The bypass-refund invariant: the wrappers read state.error to decide
      // commit-vs-cancel, so telemetry must never flip a finished reveal.
      queueRows = [serverRow(1, 11), serverRow(2, 22)];
      unsealResult = [serverRow(1, 11, unsealedAt: nowUtc)];
      DailyLoopNotifier.onAnalyticsEvent = (_, __) => throw StateError('boom');

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.checkinDone, isTrue);
      expect(notifier.state.error, isNull);
      expect(notifier.state.revealSource, revealSourceQueue);
    });

    test('a second same-day gacha reveal clears the stale queue position',
        () async {
      // Premium 30/day fair-use: reveal 1 is queue-driven, reveal 2 lands in the
      // 20h floor. Without the copyWith reset, reveal 2 would still report
      // queue_position 1.
      queueRows = [serverRow(1, 11), serverRow(2, 22), serverRow(3, 33)];
      unsealResult = [serverRow(1, 11, unsealedAt: nowUtc)];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();
      expect(notifier.state.revealQueuePosition, 1);

      // Now the cached view shows position 1 unsealed 0h ago and met → QueueHold.
      queueRows = [
        serverRow(1, 11, unsealedAt: nowUtc),
        serverRow(2, 22),
        serverRow(3, 33),
      ];
      await notifier.discoverName();
      await settle();

      expect(notifier.state.revealSource, revealSourceGacha);
      expect(notifier.state.revealQueuePosition, isNull);
    });
  });
}
