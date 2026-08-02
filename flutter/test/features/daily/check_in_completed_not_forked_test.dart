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

/// W6 Wave B binding rule (W3/W4): `check_in_completed` EXTENDS with
/// `name_source` / `queue_position`, it does NOT fork. `path` stays
/// `'discover'` on a queue reveal exactly as it does on a legacy one — a new
/// value would break every D1/D7/D30 comparison built on this event, the
/// retention spine CLAUDE.md documents as `'discover'`-only.
///
/// **MUTATION THAT MUST FAIL THIS TEST:** change `'path': 'discover'` to
/// `'path': 'queue'` (or anything else) in the `check_in_completed` emit
/// inside `DailyLoopNotifier.discoverName`. Verified by hand: with `path`
/// changed, the `props['path']` assertion below fails.
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

  Map<String, dynamic> checkIn() => events
      .singleWhere((e) => e.$1 == AnalyticsEvents.checkInCompleted)
      .$2;

  test('a queue-driven reveal still reports path:discover, plus name_source '
      'and queue_position riding alongside', () async {
    queueRows = [serverRow(1, 11), serverRow(2, 22), serverRow(3, 33)];
    unsealResult = [serverRow(2, 22, unsealedAt: nowUtc)];

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    final props = checkIn();
    expect(props['path'], 'discover');
    expect(props[AnalyticsEvents.propNameSource], AnalyticsEvents.nameSourceQueue);
    expect(props[AnalyticsEvents.propQueuePosition], 2);
  });

  test('a legacy gacha reveal reports path:discover with name_source:gacha '
      'and no queue_position key', () async {
    queueRows = const [];

    final notifier = makeNotifier();
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    final props = checkIn();
    expect(props['path'], 'discover');
    expect(props[AnalyticsEvents.propNameSource], AnalyticsEvents.nameSourceGacha);
    expect(props.containsKey(AnalyticsEvents.propQueuePosition), isFalse,
        reason: 'omit rather than emit a null property');
  });
}
