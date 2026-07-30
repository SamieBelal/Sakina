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

/// The dignity floor on the first seven reveals (W3 plan §8, OQ-2 approved).
///
/// Without it, D1 lands Bronze immediately after D0 landed Silver — a visible
/// downgrade at the single most important comeback moment, and the exact defect
/// §V6.8.A9 exists to fix.
///
/// Also re-checks the W1 binding rule from the adversarial list: `floorTier` is a
/// client-side argument to the existing `engageCard` economy path, never a value
/// the unseal RPC returns, and no non-queue caller can reach it.
class _Purchases extends PurchaseService {
  _Purchases(this.premium) : super.test();
  final bool premium;
  @override
  Future<bool> isPremium() async => premium;
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
    PurchaseService.debugSetOverride(_Purchases(false));
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

  DailyLoopNotifier queueNotifier({
    required List<Map<String, dynamic>> rows,
    required Map<String, dynamic> unsealed,
  }) =>
      DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => rows,
          callRpc: (_, __) async => [unsealed],
        ),
      );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('a queue-driven first discovery persists SILVER', () async {
    final notifier = queueNotifier(
      rows: [serverRow(1, 11), serverRow(2, 22)],
      unsealed: serverRow(1, 11, unsealedAt: nowUtc),
    );
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await settle();

    expect((await getCardCollection()).tierFor(11), 2);
    final upsert = fakeSync.upsertCalls
        .lastWhere((c) => c['table'] == 'user_card_collection');
    expect((upsert['data'] as Map<String, dynamic>)['tier'], 'silver');
  });

  test('a legacy first discovery still persists BRONZE', () async {
    final notifier = DailyLoopNotifier(
      nameQueueService: NameQueueService(
        currentUserId: () => fakeSync.userId,
        selectRows: (_) async => const [],
        callRpc: (_, __) async => null,
      ),
    );
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await settle();

    final revealed = notifier.state.engagedCard!.id;
    expect((await getCardCollection()).tierFor(revealed), 1);
  });

  test('a re-encounter of an already-Gold queue Name does NOT step down',
      () async {
    // Free ceiling is Gold, so an owned Gold card is a duplicate engagement.
    await engageCard(11); // bronze
    await engageCard(11); // silver
    await engageCard(11); // gold
    expect((await getCardCollection()).tierFor(11), 3);

    final notifier = queueNotifier(
      rows: [serverRow(1, 11), serverRow(2, 22)],
      unsealed: serverRow(1, 11, unsealedAt: nowUtc),
    );
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await settle();

    expect((await getCardCollection()).tierFor(11), 3,
        reason: 'the floor applies to a first discovery only — tier never falls');
    expect(notifier.state.cardEngageResult, isNull,
        reason: 'at the ceiling this is a duplicate, not a tier change');
  });

  test('a re-encounter of a Bronze queue Name tiers up to Silver, not to the '
      'floor', () async {
    await engageCard(11);
    expect((await getCardCollection()).tierFor(11), 1);

    final notifier = queueNotifier(
      rows: [serverRow(1, 11), serverRow(2, 22)],
      unsealed: serverRow(1, 11, unsealedAt: nowUtc),
    );
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await settle();

    expect((await getCardCollection()).tierFor(11), 2,
        reason: 're-encounter logic is untouched: currentTier + 1');
  });

  group('engageCard floorTier directly', () {
    test('the default is Bronze — every existing call site is bit-identical',
        () async {
      await engageCard(11);
      expect((await getCardCollection()).tierFor(11), 1);
    });

    test('a floor above the free ceiling is clamped to it', () async {
      await engageCard(11, maxTier: 3, floorTier: 9);
      expect((await getCardCollection()).tierFor(11), 3,
          reason: 'a free user must never exceed Gold');
    });

    test('a floor below 1 is clamped up to Bronze', () async {
      await engageCard(11, floorTier: 0);
      expect((await getCardCollection()).tierFor(11), 1);
    });

    test('the emitted card_revealed tier matches the floored tier', () async {
      final events = <(String, Map<String, dynamic>)>[];
      CardCollectionAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CardCollectionAnalytics.onAnalyticsEvent = null);

      await engageCard(11, floorTier: 2);

      final revealed = events.where((e) => e.$1 == 'card_revealed').single;
      expect(revealed.$2['tier'], 'silver');
      expect(revealed.$2['is_new'], isTrue);
    });
  });

  test('a free user\'s queue reveal never exceeds Gold', () async {
    await engageCard(11);
    await engageCard(11); // silver

    final notifier = queueNotifier(
      rows: [serverRow(1, 11), serverRow(2, 22)],
      unsealed: serverRow(1, 11, unsealedAt: nowUtc),
    );
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await settle();

    expect((await getCardCollection()).tierFor(11), lessThanOrEqualTo(3));
  });

  test('a premium queue reveal still starts at Silver, not Emerald', () async {
    PurchaseService.debugSetOverride(_Purchases(true));
    final notifier = queueNotifier(
      rows: [serverRow(1, 11), serverRow(2, 22)],
      unsealed: serverRow(1, 11, unsealedAt: nowUtc),
    );
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await settle();

    expect((await getCardCollection()).tierFor(11), 2,
        reason: 'the floor is Silver; the premium Emerald ceiling only raises '
            'the top of the ladder, not its first rung');
  });
}
