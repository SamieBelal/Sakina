import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Regression guard for the onboarding refactor: notification permission is
/// now requested *before* sign-up (at screen ~17 of the new quiz flow), so
/// when the OneSignal subscription is created it is anonymous. Once the user
/// signs up (at screen #25), the OneSignal external-user-id binding MUST fire
/// so that future push notifications target the correct Supabase user id.
///
/// The binding lives in [AppSessionNotifier._handleAuthenticatedChange] and is
/// triggered by a `signedIn` event from the Supabase auth stream. If this
/// wiring is ever removed or reordered, this test fails loudly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'OneSignal external-user-id binding fires on post-sign-up auth event '
      '(new-flow regression guard)', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = StreamController<AuthState>.broadcast();
    final identifyCalls = <String>[];
    var isAuthenticated = false;

    final fakeNotifications = _FakeOneSignalNotificationService(
      onIdentifyUser: (userId) async {
        identifyCalls.add(userId);
      },
    );

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      notificationService: fakeNotifications,
    );

    // Simulate the user finishing the sign-up screen (#25) — Supabase fires
    // a signedIn event with the freshly minted user id.
    isAuthenticated = true;
    controller.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: '',
          tokenType: '',
          user: const User(
            id: 'post-signup-user-id',
            appMetadata: <String, dynamic>{},
            userMetadata: <String, dynamic>{},
            aud: '',
            createdAt: '',
          ),
        ),
      ),
    );
    // Let the async _handleAuthenticatedChange microtasks drain.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      identifyCalls,
      <String>['post-signup-user-id'],
      reason:
          'OneSignal.login(userId) must be invoked after sign-up so the '
          'anonymous subscriber created during the pre-auth notification '
          'permission step is re-bound to the authenticated user.',
    );

    await controller.close();
    session.dispose();
  });

  test(
      'sign-out followed by a new sign-up re-identifies OneSignal with the '
      'new user id', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = StreamController<AuthState>.broadcast();
    final identifyCalls = <String>[];
    var logoutCalls = 0;
    var isAuthenticated = false;

    final fakeNotifications = _FakeOneSignalNotificationService(
      onIdentifyUser: (userId) async {
        identifyCalls.add(userId);
      },
      onLogout: () async {
        logoutCalls += 1;
      },
    );

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      notificationService: fakeNotifications,
    );

    // First sign-up.
    isAuthenticated = true;
    controller.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: '',
          tokenType: '',
          user: const User(
            id: 'user-a',
            appMetadata: <String, dynamic>{},
            userMetadata: <String, dynamic>{},
            aud: '',
            createdAt: '',
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // Sign-out (e.g. account deletion flow).
    isAuthenticated = false;
    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    // Second sign-up with a different user.
    isAuthenticated = true;
    controller.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: '',
          tokenType: '',
          user: const User(
            id: 'user-b',
            appMetadata: <String, dynamic>{},
            userMetadata: <String, dynamic>{},
            aud: '',
            createdAt: '',
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(identifyCalls, <String>['user-a', 'user-b']);
    expect(logoutCalls, 1);

    await controller.close();
    session.dispose();
  });
}

/// Hand-rolled fake — no mock framework. Extends the real service so any
/// future required-overrides show up at compile time.
class _FakeOneSignalNotificationService extends NotificationService {
  _FakeOneSignalNotificationService({
    this.onIdentifyUser,
    this.onLogout,
  });

  final Future<void> Function(String userId)? onIdentifyUser;
  final Future<void> Function()? onLogout;

  @override
  Future<void> identifyUser(String userId) async {
    await onIdentifyUser?.call(userId);
  }

  @override
  Future<void> logout() async {
    await onLogout?.call();
  }

  @override
  Future<void> syncTimezone() async {}

  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}
