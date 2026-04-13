import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(SupabaseSyncService.debugReset);

  test('daily loop keys are scoped and removable by clearSession cleanup',
      () async {
    SharedPreferences.setMockInitialValues({});
    final fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final prefs = await SharedPreferences.getInstance();
    final scopedKey = fakeSync.scopedKey('daily_loop_2026-04-12');
    await prefs.setString(scopedKey, '{"checkedIn":true}');

    expect(prefs.getString(scopedKey), isNotNull);

    for (final key in prefs.getKeys().toList()) {
      if (key.endsWith(':user-A')) {
        await prefs.remove(key);
      }
    }

    expect(prefs.getString(scopedKey), isNull);
  });
}
