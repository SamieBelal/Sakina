import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_supabase_sync_service.dart';

class TrackingPurchaseService extends PurchaseService {
  TrackingPurchaseService() : super.test();

  final List<String> identifiedUserIds = [];

  @override
  Future<void> setUserId(String userId) async {
    identifiedUserIds.add(userId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(PurchaseService.debugClearOverride);

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
      notificationService: _FakeNotificationService(),
    );

    isAuthenticated = true;
    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);

    expect(hydrateCalls, 1);
    await controller.close();
    session.dispose();
  });

  test('signed in session identifies notifications before hydration', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    final calls = <String>[];
    var isAuthenticated = false;
    final notificationService = _FakeNotificationService(
      onIdentifyUser: (userId) async {
        calls.add('identify:$userId');
      },
    );

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      hydrateEconomyCache: () async {
        calls.add('hydrate');
      },
      hasCompletedOnboarding: () async => false,
      notificationService: notificationService,
    );

    isAuthenticated = true;
    controller.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: '',
          tokenType: '',
          user: const User(
            id: 'user-1',
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

    expect(calls, <String>['identify:user-1', 'hydrate']);
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
      notificationService: _FakeNotificationService(),
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

  test('default sign-in hydration uses batch RPC once for Wave 1-2', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    final fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    var isAuthenticated = false;

    fakeSync.rpcHandlers['sync_all_user_data'] = (params) async => {
          'xp': {'total_xp': 42},
          'tokens': {
            'balance': 145,
            'total_spent': 30,
            'tier_up_scrolls': 8,
          },
          'streak': {
            'current_streak': 4,
            'longest_streak': 10,
            'last_active': '2026-04-09',
          },
          'daily_rewards': {
            'current_day': 3,
            'last_claim_date': '2026-04-09',
            'streak_freeze_owned': true,
          },
          'checkin_history': <Map<String, dynamic>>[],
          'reflections': <Map<String, dynamic>>[],
          'built_duas': <Map<String, dynamic>>[],
          'card_collection': <Map<String, dynamic>>[],
          'profile': {
            'selected_title': null,
            'is_auto_title': true,
            'created_at': '2026-04-10T00:00:00Z',
          },
          'quest_progress': <Map<String, dynamic>>[],
        };

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      hasCompletedOnboarding: () async => false,
    );

    isAuthenticated = true;
    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      fakeSync.rpcCalls.where((call) => call['fn'] == 'sync_all_user_data'),
      hasLength(1),
    );
    expect((await getXp()).totalXp, 42);
    expect((await getTierUpScrolls()).balance, 8);

    await controller.close();
    session.dispose();
    SupabaseSyncService.debugReset();
  });

  test('signedIn identifies the current RevenueCat user once', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    final purchaseService = TrackingPurchaseService();
    PurchaseService.debugSetOverride(purchaseService);
    var isAuthenticated = false;

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      currentUserIdProvider: () => 'user-signed-in',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
      notificationService: _FakeNotificationService(),
    );

    isAuthenticated = true;
    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(purchaseService.identifiedUserIds, ['user-signed-in']);

    await controller.close();
    session.dispose();
  });

  test('initialSession identifies the existing RevenueCat user', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    final purchaseService = TrackingPurchaseService();
    PurchaseService.debugSetOverride(purchaseService);
    const isAuthenticated = true;

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      currentUserIdProvider: () => 'user-initial-session',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
      notificationService: _FakeNotificationService(),
    );

    controller.add(const AuthState(AuthChangeEvent.initialSession, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(purchaseService.identifiedUserIds, ['user-initial-session']);

    await controller.close();
    session.dispose();
  });

  test('signedOut does not attempt a RevenueCat logout path', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StreamController<AuthState>.broadcast();
    final purchaseService = TrackingPurchaseService();
    PurchaseService.debugSetOverride(purchaseService);
    var isAuthenticated = false;
    String? currentUserId = 'user-before-signout';

    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: controller.stream,
      isAuthenticatedProvider: () => isAuthenticated,
      currentUserIdProvider: () => currentUserId,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
      notificationService: _FakeNotificationService(),
    );

    isAuthenticated = true;
    controller.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    isAuthenticated = false;
    currentUserId = null;
    controller.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    expect(purchaseService.identifiedUserIds, ['user-before-signout']);

    await controller.close();
    session.dispose();
  });
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({
    this.onIdentifyUser,
  });

  final Future<void> Function(String userId)? onIdentifyUser;

  @override
  Future<void> identifyUser(String userId) async {
    await onIdentifyUser?.call(userId);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> syncTimezone() async {}

  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}
