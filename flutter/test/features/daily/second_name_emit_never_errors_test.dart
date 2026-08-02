import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// A throwing analytics hook must never flip a completed reveal into
/// `state.error` — `discoverNameWithBypass` reads `state.error` to decide
/// commit-versus-refund, so a telemetry hiccup on the Second-Name emits would
/// otherwise discard a real reveal and refund a bypass that was already well
/// spent (same reasoning as `GatingService._emitTasteConsumed`).
///
/// **MUTATION THAT MUST FAIL THIS TEST:** remove either `catch (_) {}` inside
/// `DailyLoopNotifier._emitSecondNameLifecycle` (the availability emit's or
/// the unsealed emit's). Verified by hand: with either guard removed, the
/// throwing-hook test below reports `state.error` non-null (and, on a
/// second run, the availability-guard removal surfaces as an uncaught
/// exception from `discoverName` itself).
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
    DailyLoopNotifier.onAnalyticsEvent = null;
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

  DailyLoopNotifier makeNotifier({
    required List<Map<String, dynamic>> queueRows,
    required dynamic unsealResult,
  }) =>
      DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => queueRows,
          callRpc: (_, __) async => unsealResult,
        ),
      );

  test(
      'a throwing hook on a position-2 unseal (fires BOTH second_name events) '
      'does not error the reveal', () async {
    DailyLoopNotifier.onAnalyticsEvent = (_, __) => throw StateError('boom');

    final notifier = makeNotifier(
      queueRows: [
        serverRow(1, 11),
        serverRow(2, 22),
        serverRow(3, 33),
      ],
      unsealResult: [serverRow(2, 22, unsealedAt: nowUtc)],
    );
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    expect(notifier.state.checkinDone, isTrue);
    expect(notifier.state.error, isNull);
    expect(notifier.state.revealQueuePosition, 2);
  });

  test('a throwing hook on an availability-only call (no unseal) does not '
      'error the reveal', () async {
    DailyLoopNotifier.onAnalyticsEvent = (_, __) => throw StateError('boom');

    final notifier = makeNotifier(
      queueRows: [serverRow(1, 11), serverRow(2, 22)],
      unsealResult: null, // drained elsewhere: availability fires, unseal doesn't
    );
    addTearDown(notifier.dispose);
    await notifier.discoverName();
    await settle();

    expect(notifier.state.checkinDone, isTrue);
    expect(notifier.state.error, isNull);
  });
}
