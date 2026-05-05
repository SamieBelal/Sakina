import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/starter_name_cache.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Regression tests for the starter Name SharedPreferences cache.
///
/// Bug history (2026-05-04): the home greeting (`DailyLaunchOverlay`) read
/// the user's starter Name from a `FutureProvider` that hit Supabase on
/// every overlay mount. Loading state returned null → fallback to
/// `getTodaysName()` → user saw a wrong Name flash on day 0. This cache
/// primes the value synchronously so the provider can return immediately.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(SupabaseSyncService.debugReset);

  test('readCachedStarterNameId returns null when no user is signed in',
      () async {
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: null));

    expect(await readCachedStarterNameId(), isNull);
  });

  test('writeCachedStarterNameId is a no-op when no user is signed in',
      () async {
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: null));

    await writeCachedStarterNameId(28);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith(starterNamePrefBaseKey)),
        isEmpty,
        reason:
            'no user → no scope → must not write any starter Name pref keys');
  });

  test('round-trip: write 28 under user-A, read returns 28', () async {
    SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-A'));

    await writeCachedStarterNameId(28);

    expect(await readCachedStarterNameId(), 28);
  });

  test(
      'scoping: writing under user-A does not leak into user-B reads — '
      'the bug we suspected with the deleted-account/new-account flow',
      () async {
    final fake = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fake);
    await writeCachedStarterNameId(28);

    fake.userId = 'user-B';
    expect(await readCachedStarterNameId(), isNull,
        reason: 'user-B must NOT see user-A\'s starter Name');

    // Sanity: switching back to user-A still returns the value.
    fake.userId = 'user-A';
    expect(await readCachedStarterNameId(), 28);
  });

  test('write overwrites existing value for same user', () async {
    SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-A'));

    await writeCachedStarterNameId(28);
    await writeCachedStarterNameId(9);

    expect(await readCachedStarterNameId(), 9);
  });

  test('scoped key uses the documented base + uid suffix shape', () async {
    SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-A'));

    await writeCachedStarterNameId(28);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('$starterNamePrefBaseKey:user-A'), 28,
        reason: 'must use the `<baseKey>:<uid>` convention so the existing '
            'clearScopedPreferencesForUser sweeper picks it up on sign-out');
  });

  test(
      'race: signOut completing during the getInstance() await must not '
      'write an unscoped or wrong-uid key',
      () async {
    final fake = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fake);

    // Kick off the write but flip the auth user mid-flight, simulating a
    // signOut that lands between `currentUserId` resolution and the prefs
    // write. Without the post-await re-check, the write would land at the
    // unscoped base key OR under user-A even though they're no longer the
    // current user.
    final writeFuture = writeCachedStarterNameId(28);
    fake.userId = null;
    await writeFuture;

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(starterNamePrefBaseKey), isNull,
        reason: 'must not write the unscoped base key');
    expect(prefs.getInt('$starterNamePrefBaseKey:user-A'), isNull,
        reason: 'must abort the write when the user changed mid-await');
  });
}
