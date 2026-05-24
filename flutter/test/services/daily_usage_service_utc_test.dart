import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_usage_service.dart' as dus;
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });
  tearDown(() {
    dus.debugDailyUsageClock = null;
    SupabaseSyncService.debugReset();
  });

  test('REGRESSION P0-3: writes use UTC date, not local-time date', () async {
    // Pin clock to 23:30 EDT on 2026-06-15 = 03:30 UTC on 2026-06-16.
    // Locally still "yesterday", in UTC it's "today".
    dus.debugDailyUsageClock = () => DateTime.utc(2026, 6, 16, 3, 30);

    await dus.incrementReflectUsage();
    final today = await dus.getReflectUsageToday();
    expect(today, 1, reason: 'should write to UTC date bucket');

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().toList();
    expect(
      allKeys.any((k) => k.contains('2026-06-16')),
      isTrue,
      reason: 'must include the UTC date in the prefs key',
    );
    expect(
      allKeys.any((k) => k.contains('2026-06-15')),
      isFalse,
      reason: 'must NOT include the local-time date in the prefs key',
    );
  });

  test('REGRESSION P0-3: bypass counter keys also use UTC', () async {
    dus.debugDailyUsageClock = () => DateTime.utc(2026, 6, 16, 3, 30);
    await dus.incrementReflectBypassUsage();
    expect(await dus.getReflectBypassesUsedToday(), 1);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().any((k) =>
          k.contains('daily_bypass') && k.contains('2026-06-16')),
      isTrue,
    );
  });

  test('production path (no debug clock) returns SOME UTC date', () async {
    dus.debugDailyUsageClock = null;
    await dus.incrementReflectUsage();
    expect(await dus.getReflectUsageToday(), 1);
    // Don't assert specific date — just that it doesn't crash.
  });
}
