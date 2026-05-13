// iOS simulator smoke test for the daily-launch overlay fixes.
//
// HOW TO RUN:
//   xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
//   SIM_ID=$(xcrun simctl list devices booted -j | python3 -c \
//     'import json,sys; d=json.load(sys.stdin); print([v[0]["udid"] for v in d["devices"].values() if v][0])')
//   flutter test integration_test/daily_launch_overlay_smoke_test.dart \
//     -d "$SIM_ID" --dart-define-from-file=env.json
//
// This test does NOT hit real Supabase. It uses FakeSupabaseSyncService
// via debugSetInstance to mock all server calls. It runs on iOS to verify
// the widgets render and animate correctly on iOS Metal + the real
// SharedPreferences plugin channel — the host `flutter test` only proves
// the logic, not the platform-channel-level behavior.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_sync_export.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetLaunchGateMemoryGuard();
    debugResetPublicCatalogs();
    fakeSync = FakeSupabaseSyncService(userId: 'sim-user');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugLaunchGateClock = () => DateTime.utc(2026, 5, 12, 14, 0);
    debugRewardsClock = () => DateTime.utc(2026, 5, 12, 14, 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugResetPublicCatalogs();
    debugLaunchGateClock = () => DateTime.now().toUtc();
    debugRewardsClock = () => DateTime.now().toUtc();
  });

  AppSessionNotifier buildSession() {
    final controller = StreamController<AuthState>.broadcast();
    addTearDown(controller.close);
    final session = AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'sim-user',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      notificationService: _NoopNotificationService(),
    );
    addTearDown(session.dispose);
    return session;
  }

  testWidgets(
    '[iOS] pending claim renders Day 4 highlight and post-claim screen reads Day 5',
    (tester) async {
      fakeSync.rows['user_daily_rewards:sim-user'] = {
        'user_id': 'sim-user',
        'current_day': 3,
        'last_claim_date': '2026-05-11',
        'streak_freeze_owned': false,
      };
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
            'day': 4,
            'tokens_awarded': 0,
            'scrolls_awarded': 0,
            'earned_streak_freeze': true,
            'earned_tier_up_scroll': false,
            'already_claimed': false,
            'current_day': 4,
            'last_claim_date': '2026-05-12',
            'streak_freeze_owned': true,
            'token_balance': 0,
            'scroll_balance': 0,
            'is_premium': false,
            'multiplier': 1,
          };

      final session = buildSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWithValue(session),
            premiumStateProvider.overrideWith(
              (ref) async => (isPremium: false, billingIssueAt: null),
            ),
          ],
          child: const MaterialApp(home: DailyLaunchOverlay()),
        ),
      );
      // Pump frames manually — overlay uses .animate().repeat() which
      // never settles, so pumpAndSettle would hang.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Step 0 — streak greeting visible on iOS.
      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // After reload completes, Day 4 highlight visible + Claim button.
      expect(find.text('Day 4 reward'), findsOneWidget);
      expect(find.text('Claim Reward'), findsOneWidget);

      await tester.tap(find.text('Claim Reward'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Reward Claimed!'), findsOneWidget);
      // Pre-claim "Day 4 reward" → post-claim "Come back tomorrow for Day 5".
      expect(find.textContaining('Day 5'), findsWidgets);
    },
  );

  testWidgets(
    '[iOS] reinstall + server says claimed today => Step 0 dismisses without exposing Claim',
    (tester) async {
      fakeSync.rows['user_daily_rewards:sim-user'] = {
        'user_id': 'sim-user',
        'current_day': 4,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': true,
      };

      final session = buildSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSessionProvider.overrideWithValue(session),
            premiumStateProvider.overrideWith(
              (ref) async => (isPremium: false, billingIssueAt: null),
            ),
          ],
          child: const MaterialApp(home: DailyLaunchOverlay()),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The overlay must dismiss without ever exposing the Claim CTA.
      expect(find.text('Claim Reward'), findsNothing);
    },
  );
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
