import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_lifecycle_observer.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'resumed lifecycle event invalidates isPremiumProvider '
      '(triggers a fresh read)', (tester) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWith((ref) async {
            invocationCount += 1;
            return false;
          }),
        ],
        child: AppLifecycleObserver(
          child: Consumer(
            builder: (context, ref, _) {
              // Force the provider to materialize.
              ref.watch(isPremiumProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    // First read happens during initial build.
    expect(invocationCount, 1);

    // Simulate backgrounding + resume.
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      invocationCount,
      2,
      reason: 'resume should invalidate the provider, forcing a re-fetch',
    );
  });

  testWidgets('non-resume lifecycle events do not invalidate the provider',
      (tester) async {
    var invocationCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWith((ref) async {
            invocationCount += 1;
            return false;
          }),
        ],
        child: AppLifecycleObserver(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(isPremiumProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(invocationCount, 1);

    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();

    expect(
      invocationCount,
      1,
      reason: 'only resume should trigger invalidation',
    );
  });

  testWidgets('disposes cleanly (removes its WidgetsBindingObserver)',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppLifecycleObserver(child: SizedBox()),
      ),
    );

    // Unmount the observer.
    await tester.pumpWidget(const SizedBox());

    // Firing lifecycle changes after dispose must not throw.
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  testWidgets('auth state transition invalidates isPremiumProvider',
      (tester) async {
    var invocationCount = 0;
    var authed = false;
    final controller = StreamController<AuthState>.broadcast();
    addTearDown(controller.close);

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => authed,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
      notificationService: _NoopNotificationService(),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionProvider.overrideWithValue(session),
          isPremiumProvider.overrideWith((ref) async {
            invocationCount += 1;
            return false;
          }),
        ],
        child: AppLifecycleObserver(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(isPremiumProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(invocationCount, 1);

    // Fire a signedIn event. AppSessionNotifier updates its internal state
    // and calls notifyListeners, which our observer listens for.
    authed = true;
    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await tester.pumpAndSettle();

    expect(
      invocationCount,
      2,
      reason:
          'auth transition (signed out -> signed in) must invalidate isPremiumProvider',
    );
  });
}

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}
