import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hydration failure sets hydrationFailed and retry can recover',
      () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    var callCount = 0;

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => true,
      hydrateEconomyCache: () async {
        callCount += 1;
        if (callCount == 1) {
          throw Exception('Network error');
        }
      },
      hasCompletedOnboarding: () async => false,
    );

    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(session.economyHydrated, isFalse);
    expect(session.hydrationFailed, isTrue);

    await session.retryHydration();
    await Future<void>.delayed(Duration.zero);

    expect(session.economyHydrated, isTrue);
    expect(session.hydrationFailed, isFalse);
    expect(callCount, 2);

    await controller.close();
    session.dispose();
  });

  test('hydration timeout marks the session as failed', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    final hangCompleter = Completer<void>();

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => true,
      hydrateEconomyCache: () => hangCompleter.future,
      hasCompletedOnboarding: () async => false,
      hydrationTimeout: const Duration(milliseconds: 50),
    );

    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(session.hydrationFailed, isTrue);
    expect(session.economyHydrated, isFalse);

    await controller.close();
    session.dispose();
  });

  test('signedOut resets hydration failure state', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => true,
      hydrateEconomyCache: () async => throw Exception('fail'),
      hasCompletedOnboarding: () async => false,
    );

    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(session.hydrationFailed, isTrue);

    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    expect(session.hydrationFailed, isFalse);

    await controller.close();
    session.dispose();
  });
}
