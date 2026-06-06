import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDisablePaywallAnimations = true;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });
  tearDown(() {
    debugDisablePaywallAnimations = false;
    SupabaseSyncService.debugReset();
  });

  AppSessionNotifier buildSession() => AppSessionNotifier(
        initialOnboarded: true,
        authStateChanges: const Stream.empty(),
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'u1',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        isPremiumReader: () async => false,
        hardPaywallFlowReader: () async => true,
        notificationService: _FakeNotif(),
      );

  Widget harness({
    required bool hardGate,
    required VoidCallback onComplete,
    AppSessionNotifier? session,
  }) {
    final container = ProviderContainer(
      overrides: [
        if (session != null) appSessionProvider.overrideWithValue(session),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PaywallScreen(
          onComplete: onComplete,
          inOnboardingFlow: false,
          hardGate: hardGate,
        ),
      ),
    );
  }

  testWidgets('hard gate renders NO close X (even after the 3s reveal delay)',
      (tester) async {
    await tester.pumpWidget(harness(hardGate: true, onComplete: () {}));
    await tester.pump(const Duration(seconds: 4));
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('soft mode DOES reveal the close X after the delay',
      (tester) async {
    await tester.pumpWidget(harness(hardGate: false, onComplete: () {}));
    await tester.pump(const Duration(seconds: 4));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('offerings-fail safety valve shows "Continue" in hard gate',
      (tester) async {
    // PurchaseService is uninitialized in tests → getOfferings() returns [],
    // which trips the offerings-fail path.
    await tester.pumpWidget(harness(hardGate: true, onComplete: () {}));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Continue'), findsOneWidget);
  });

  testWidgets('soft mode does NOT show the Continue valve on offerings-fail',
      (tester) async {
    await tester.pumpWidget(harness(hardGate: false, onComplete: () {}));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Continue'), findsNothing);
  });

  testWidgets('tapping the valve grants a session bypass + fires onComplete',
      (tester) async {
    final session = buildSession();
    addTearDown(session.dispose);
    var completed = false;

    await tester.pumpWidget(harness(
      hardGate: true,
      onComplete: () => completed = true,
      session: session,
    ));
    await tester.pumpAndSettle();

    final valve = find.widgetWithText(TextButton, 'Continue');
    await tester.ensureVisible(valve);
    await tester.pump();
    await tester.tap(valve);
    await tester.pump();

    expect(completed, true);
    expect(session.gateValveBypass, true);
  });
}

class _FakeNotif extends NotificationService {
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}
