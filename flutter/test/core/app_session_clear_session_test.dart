import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
  });

  test('clearSession removes onboarding_state and resets launch gate memory',
      () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_state': '{"step":2}',
      'onboarding_completed': true,
    });
    final controller = StreamController<AuthState>.broadcast();
    final fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await markDailyLaunchShown();

    final session = AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => true,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
    );

    await session.clearSession(userId: 'user-A');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('onboarding_state'), isNull);
    expect(prefs.getBool('onboarding_completed'), isNull);
    expect(prefs.getString('sakina_launch_gate:user-A'), isNull);

    fakeSync.userId = 'user-B';
    expect(await shouldShowDailyLaunch(), isTrue);

    await controller.close();
    session.dispose();
  });
}
