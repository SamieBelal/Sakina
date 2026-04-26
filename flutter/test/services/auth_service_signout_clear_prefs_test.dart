// Regression test for finding 2026-04-26-signout-no-cache-clear (F3).
// Sign-out must clear all SharedPreferences keys scoped to the
// signing-out user so re-login does not load stale local state. We
// test the extracted helper directly to avoid mocking the Supabase
// auth singleton.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uidA = 'a55cc84f-c916-496f-8623-ef24cc89eca4';
  const uidB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      // Scoped to user A — should be cleared.
      'sakina_tokens:$uidA': '1333',
      'sakina_total_xp:$uidA': '450',
      'saved_reflections:$uidA': '[]',
      'daily_loop_2026-04-26:$uidA': '{}',
      'daily_usage_reflect_2026-04-26:$uidA': '0',
      // Scoped to user B — must survive.
      'sakina_tokens:$uidB': '999',
      'saved_reflections:$uidB': '[]',
      // Unscoped global keys — must survive.
      'app_first_launch_seen': true,
      'public_catalog_version': 17,
    });
  });

  test('removes only keys ending with :<uidA>, preserves uidB and globals',
      () async {
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().length, 9);

    final removed = await clearScopedPreferencesForUser(prefs, uidA);

    expect(removed, 5,
        reason: 'all five user-A scoped keys should have been removed');

    final remaining = prefs.getKeys();
    expect(remaining, contains('sakina_tokens:$uidB'),
        reason: 'user B scoped data must NOT be touched');
    expect(remaining, contains('saved_reflections:$uidB'));
    expect(remaining, contains('app_first_launch_seen'),
        reason: 'global unscoped keys must survive sign-out');
    expect(remaining, contains('public_catalog_version'));
    expect(remaining.length, 4);

    expect(prefs.getKeys().any((k) => k.endsWith(':$uidA')), isFalse,
        reason: 'no key ending in :$uidA should remain');
  });

  test('returns 0 and is a no-op when uid is empty', () async {
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getKeys().length;

    final removed = await clearScopedPreferencesForUser(prefs, '');

    expect(removed, 0);
    expect(prefs.getKeys().length, before);
  });

  test('returns 0 when no scoped keys exist for the given uid', () async {
    final prefs = await SharedPreferences.getInstance();

    final removed = await clearScopedPreferencesForUser(
        prefs, 'cccccccc-cccc-cccc-cccc-cccccccccccc');

    expect(removed, 0);
    expect(prefs.getKeys().length, 9);
  });
}
