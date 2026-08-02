import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/reveal_entry_source.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// Pins `second_name_unseal_available` / `second_name_unsealed` — the two
/// halves of the Second-Name lifecycle that live in `DailyLoopNotifier` (the
/// tease is screen-only; see `second_name_teased_test.dart`). W6 Wave B / W3
/// §9: this is the only measurement of whether the seven-day queue actually
/// runs.
///
/// Mirrors `discover_name_queue_test.dart`'s harness exactly (same fake
/// `NameQueueService`, same pinned clock).
class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0); // 2026-08-03 20:00 LA

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
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => nowUtc;
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
      'a fresh position-2 unseal fires availability AND unsealed, once each, '
      'with their props', () async {
    // Position 1 seeded 3 days ago (the tease), position 2 sealed.
    queueRows = [
      serverRow(1, 11, unsealedAt: DateTime.utc(2026, 8, 1, 3)),
      serverRow(2, 22),
      serverRow(3, 33),
    ];
    unsealResult = [serverRow(2, 22, unsealedAt: nowUtc)];

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    expect(notifier.state.revealQueuePosition, 2);

    final available = named(AnalyticsEvents.secondNameUnsealAvailable).toList();
    expect(available, hasLength(1));
    expect(available.single.$2[AnalyticsEvents.propNameId], 22);
    expect(available.single.$2[AnalyticsEvents.propDaysSinceTease], 3);

    final unsealed = named(AnalyticsEvents.secondNameUnsealed).toList();
    expect(unsealed, hasLength(1));
    expect(unsealed.single.$2[AnalyticsEvents.propNameId], 22);
    expect(unsealed.single.$2[AnalyticsEvents.propDaysSinceTease], 3);
    expect(unsealed.single.$2[AnalyticsEvents.propSource],
        AnalyticsEvents.revealSourceOrganic);
  });

  test('a widget-stamped source rides second_name_unsealed', () async {
    queueRows = [serverRow(1, 11), serverRow(2, 22)];
    unsealResult = [serverRow(2, 22, unsealedAt: nowUtc)];
    debugRevealEntrySourceClock = () => nowUtc;
    stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    final unsealed = named(AnalyticsEvents.secondNameUnsealed).single;
    expect(unsealed.$2[AnalyticsEvents.propSource],
        AnalyticsEvents.revealSourceWidget);
  });

  test(
      // MUTATION: emit `second_name_unsealed` for position 3 as well —
      // this must fail once the guard is `queueRow.position == 2` only.
      'position 3 (and beyond) fires NEITHER event — ordinary discovery, not '
      'the queue keeping its promise', () async {
    queueRows = [
      serverRow(1, 11, unsealedAt: DateTime.utc(2026, 7, 30, 3)),
      serverRow(2, 22, unsealedAt: DateTime.utc(2026, 8, 1, 3)),
      serverRow(3, 33),
    ];
    unsealResult = [serverRow(3, 33, unsealedAt: nowUtc)];

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    expect(notifier.state.revealQueuePosition, 3);
    expect(named(AnalyticsEvents.secondNameUnsealed), isEmpty);
    // Position 2 is already unsealed (not sealed) in the pre-call view, so
    // availability (which only fires for a currently-SEALED position 2)
    // must not fire either.
    expect(named(AnalyticsEvents.secondNameUnsealAvailable), isEmpty);
  });

  test('a legacy (queue-absent) reveal fires neither event', () async {
    queueRows = const [];

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    expect(named(AnalyticsEvents.secondNameUnsealAvailable), isEmpty);
    expect(named(AnalyticsEvents.secondNameUnsealed), isEmpty);
  });

  test('a null RPC result (drained by another device) still reports '
      'availability but not unsealed', () async {
    queueRows = [serverRow(1, 11), serverRow(2, 22)];
    unsealResult = null;

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    expect(notifier.state.revealSource, revealSourceGacha);
    expect(named(AnalyticsEvents.secondNameUnsealAvailable), hasLength(1));
    expect(named(AnalyticsEvents.secondNameUnsealed), isEmpty);
  });
}
