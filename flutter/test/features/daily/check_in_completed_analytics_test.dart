import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Pins the `check_in_completed` core-loop DAU event on the live discover path
/// (PR #33). The questionnaire path is currently dormant (`answerCheckin` is
/// unwired), so the discover path is what production actually emits.
class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late List<(String, Map<String, dynamic>)> events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    events = [];
    DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));
  });

  tearDown(() {
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  Iterable<(String, Map<String, dynamic>)> checkIns() =>
      events.where((e) => e.$1 == AnalyticsEvents.checkInCompleted);

  test('discoverName emits exactly one check_in_completed{path:discover}',
      () async {
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    // Let the fire-and-forget deeper-reflection prefetch settle.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final ci = checkIns().toList();
    expect(ci, hasLength(1));
    final props = ci.single.$2;
    expect(props['path'], 'discover');
    expect(props['name'], isNotEmpty);
    // A first-ever discovery is a new card → tier changed, not a duplicate.
    expect(props['tier_changed'], isTrue);
    expect(props['is_duplicate'], isFalse);
  });

  test('a telemetry hook that throws does NOT corrupt a successful check-in',
      () async {
    // F3 regression: the emit is wrapped in try/catch so an analytics throw
    // can't flip checkinDone→error (which the bypass wrapper reads to decide
    // commit-vs-cancel).
    DailyLoopNotifier.onAnalyticsEvent = (_, __) => throw StateError('boom');
    final notifier = DailyLoopNotifier();
    addTearDown(notifier.dispose);

    await notifier.discoverName();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(notifier.state.checkinDone, isTrue,
        reason: 'check-in succeeded — a telemetry throw must not error it');
    expect(notifier.state.error, isNull);
  });
}
