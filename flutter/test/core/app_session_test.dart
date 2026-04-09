import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth events trigger economy hydration', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    var hydrateCalls = 0;
    var isAuthenticated = false;

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      hydrateEconomyCache: () async {
        hydrateCalls += 1;
      },
      hasCompletedOnboarding: () async => false,
    );

    isAuthenticated = true;
    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);

    expect(hydrateCalls, 1);
    await controller.close();
    session.dispose();
  });

  test('signedOut resets onboarding state before a later sign-in', () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final controller = StreamController<AuthState>.broadcast();
    const isAuthenticated = true;

    final session = AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
    );

    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(session.hasOnboarded, isFalse);

    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);
    expect(session.hasOnboarded, isTrue);

    await controller.close();
    session.dispose();
  });
}
