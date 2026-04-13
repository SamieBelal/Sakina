import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(SupabaseSyncService.debugReset);

  test(
      'clearSession with explicit userId removes scoped keys even after auth is gone',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tokens:user-A': 100,
      'sakina_xp:user-A': 42,
      'sakina_launch_gate:user-A': '2026-04-12',
      'onboarding_completed': true,
    });

    final fakeSync = FakeSupabaseSyncService(userId: null);
    SupabaseSyncService.debugSetInstance(fakeSync);

    final session = AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: const Stream.empty(),
      isAuthenticatedProvider: () => false,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );

    await session.clearSession(userId: 'user-A');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('sakina_tokens:user-A'), isNull);
    expect(prefs.getInt('sakina_xp:user-A'), isNull);
    expect(prefs.getString('sakina_launch_gate:user-A'), isNull);

    session.dispose();
  });

  test(
      'clearSession without userId and without an auth user skips scoped cleanup',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tokens:user-A': 100,
    });

    final fakeSync = FakeSupabaseSyncService(userId: null);
    SupabaseSyncService.debugSetInstance(fakeSync);

    final session = AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: const Stream.empty(),
      isAuthenticatedProvider: () => false,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );

    await session.clearSession();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('sakina_tokens:user-A'), 100);

    session.dispose();
  });
}
