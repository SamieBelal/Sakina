import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// `second_name_unseal_available` is deduped on the USER-LOCAL date, not per
/// call: a user who opens the app four times before revealing (or whose
/// unseal keeps losing the race to another device) must not make the unseal
/// rate (unsealed ÷ available) read four times worse than it is.
///
/// **MUTATION THAT MUST FAIL THIS TEST:** drop the SharedPreferences date
/// latch in `DailyLoopNotifier._emitSecondNameLifecycle` (the
/// `prefs.getBool(latchKey) != true` guard / the `prefs.setBool` write).
/// Verified by hand: with the latch removed, the "four opens" test below
/// counts 4 `second_name_unseal_available` events instead of 1.
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
  late List<(String, Map<String, dynamic>)> events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => nowUtc;
    // Position 2 stays sealed across every call: the unseal RPC keeps losing
    // its race to another device (a null result), so the plan resolves to
    // QueueUnseal — and thus "available" — on every single call, unless the
    // day-keyed latch stops it.
    queueRows = [
      {'position': 1, 'name_id': 11, 'unsealed_at': '2026-08-01T03:00:00Z'},
      {'position': 2, 'name_id': 22, 'unsealed_at': null},
      {'position': 3, 'name_id': 33, 'unsealed_at': null},
    ];
    events = [];
    DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  DailyLoopNotifier makeNotifier() => DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => queueRows,
          callRpc: (_, __) async => null, // never actually advances
        ),
      );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('four opens in one local day emit availability exactly once',
      () async {
    for (var i = 0; i < 4; i++) {
      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();
    }

    final available = events
        .where((e) => e.$1 == AnalyticsEvents.secondNameUnsealAvailable)
        .toList();
    expect(available, hasLength(1));
    expect(available.single.$2[AnalyticsEvents.propNameId], 22);
  });

  test('a NEW local day re-arms the latch', () async {
    final notifier1 = makeNotifier();
    addTearDown(notifier1.dispose);
    await notifier1.discoverName();
    await settle();

    // Next local day: 24h later.
    debugDailyLoopClock = () => nowUtc.add(const Duration(hours: 24));

    final notifier2 = makeNotifier();
    addTearDown(notifier2.dispose);
    await notifier2.discoverName();
    await settle();

    final available = events
        .where((e) => e.$1 == AnalyticsEvents.secondNameUnsealAvailable)
        .toList();
    expect(available, hasLength(2));
  });
}
