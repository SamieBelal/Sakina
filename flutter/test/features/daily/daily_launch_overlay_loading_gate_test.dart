import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ControllableFakeSync fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = _ControllableFakeSync(userId: 'user-A');
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

  AppSessionNotifier _buildSession() {
    final controller = StreamController<AuthState>.broadcast();
    addTearDown(controller.close);
    final session = AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'user-A',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      notificationService: _NoopNotificationService(),
    );
    addTearDown(session.dispose);
    return session;
  }

  testWidgets(
    'reward claim step shows loader (not strip) until reload completes, then Day matches server',
    (tester) async {
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 3,
        'last_claim_date': '2026-05-11',
        'streak_freeze_owned': false,
      };
      // Hold the server-side fetch open so we can verify the overlay
      // shows the loader (and NOT the strip / Claim button) while the
      // reconcile is still in flight. We complete it after asserting.
      final fetchGate = Completer<void>();
      fakeSync.holdFetchUntil = fetchGate.future;
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async {
        return {
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
      };

      final session = _buildSession();

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
      await tester.pump();
      // Step 0 (streak greeting) renders first. Tap Begin to advance.
      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      await tester.pump();

      // Before reload resolves, Step 1 MUST show the loader, not the strip,
      // and the Claim button MUST be absent. Prevents claiming with stale state.
      expect(find.byType(SakinaLoader), findsWidgets,
          reason: 'loader must render until rewards reload completes');
      expect(find.text('Claim Reward'), findsNothing,
          reason: 'Claim button must not appear before reload completes');

      // Release the in-flight server fetch. Then drive the frame pump
      // loop manually — pumpAndSettle would hang on the overlay's infinite
      // `.repeat()` animations (streak flame / strip pulse).
      fetchGate.complete();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Claim Reward'), findsOneWidget);
      expect(find.text('Day 4 reward'), findsOneWidget);

      // Now tap Claim and assert post-claim screen says Day 5
      // (current_day=4 after claim → Come back tomorrow for Day 5).
      await tester.tap(find.text('Claim Reward'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Reward Claimed!'), findsOneWidget);
      expect(find.textContaining('Day 5'), findsWidgets,
          reason: 'success screen Day must match what the RPC awarded');
    },
  );

  testWidgets(
    'reward claim step skips the claim flow when server says claimedToday=true',
    (tester) async {
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 4,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': true,
      };

      final session = _buildSession();

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
      // Drain rewards reload + animations without using pumpAndSettle
      // (overlay has infinite `.repeat()` animations on the streak flame).
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Claim Reward'), findsNothing);
    },
  );
}

/// Fake that lets the test pause server-side fetches mid-flight so we can
/// assert the loader is rendered before reconcile resolves. Without this
/// the in-memory `rows[]` lookup completes in a single microtask and the
/// loader is never visible.
class _ControllableFakeSync extends FakeSupabaseSyncService {
  _ControllableFakeSync({super.userId});

  Future<void>? holdFetchUntil;

  @override
  Future<Map<String, dynamic>?> fetchRow(
    String table,
    String userId, {
    String columns = '*',
  }) async {
    if (holdFetchUntil != null) {
      await holdFetchUntil;
      holdFetchUntil = null;
    }
    return super.fetchRow(table, userId, columns: columns);
  }
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
