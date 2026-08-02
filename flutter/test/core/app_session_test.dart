import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/reveal_entry_source.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fake_supabase_sync_service.dart';

// app_session calls `Purchases.getCustomerInfo()` after `setUserId` to
// baseline the consumable-grants credited set. Stub the channel to return
// an empty customerInfo so the baseline succeeds quickly without making
// real platform calls.
const MethodChannel _purchasesChannel = MethodChannel('purchases_flutter');

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

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, (call) async {
      if (call.method == 'getCustomerInfo') {
        return <String, dynamic>{
          'originalAppUserId': 'test-user',
          'entitlements': <String, dynamic>{
            'all': <String, dynamic>{},
            'active': <String, dynamic>{},
            'verification': 'NOT_REQUESTED',
          },
          'activeSubscriptions': <String>[],
          'latestExpirationDate': null,
          'allExpirationDates': <String, dynamic>{},
          'allPurchasedProductIdentifiers': <String>[],
          'firstSeen': '2026-04-01T12:00:00.000Z',
          'requestDate': '2026-04-26T12:00:00.000Z',
          'allPurchaseDates': <String, dynamic>{},
          'originalApplicationVersion': '1.0.0',
          'nonSubscriptionTransactions': <dynamic>[],
        };
      }
      return null;
    });
  });

  tearDown(() {
    PurchaseService.debugClearOverride();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, null);
  });

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

  test('signedOut fires the analytics-reset hook (D2 identity hygiene)',
      () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final controller = StreamController<AuthState>.broadcast();
    const isAuthenticated = true;
    var resetCalls = 0;
    AppSessionNotifier.onAnalyticsReset = () => resetCalls += 1;
    addTearDown(() => AppSessionNotifier.onAnalyticsReset = null);

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

    expect(resetCalls, 1,
        reason: 'sign-out must reset Mixpanel identity exactly once');

    await controller.close();
    session.dispose();
  });

  test('a null analytics-reset hook is a safe no-op on signedOut', () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final controller = StreamController<AuthState>.broadcast();
    const isAuthenticated = true;
    AppSessionNotifier.onAnalyticsReset = null;

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
    // No throw, and normal sign-out side effects still apply.
    expect(session.hasOnboarded, isFalse);

    await controller.close();
    session.dispose();
  });

  // Cross-user leak (P2, review): the widget/push reveal-source stamp is
  // process-global with a ~10-minute TTL and nothing cleared it on sign-out —
  // so on this project's shared QA device, a DIFFERENT user signing in within
  // the TTL inherited the outgoing user's stamp and had their
  // `second_name_unsealed` misattributed to a push/widget they never touched.
  // signedOut is the ONE place that runs for every sign-out, including an
  // *implicit* one (an expired/revoked refresh token emits a bare `signedOut`
  // with no `signOut()` call, so caller-side cleanup never runs).
  test(
      'signedOut fires the reveal-entry-source-reset hook and the stamp is '
      'gone', () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final controller = StreamController<AuthState>.broadcast();
    const isAuthenticated = true;
    stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);
    AppSessionNotifier.onRevealEntrySourceReset = clearRevealEntrySource;
    addTearDown(() {
      AppSessionNotifier.onRevealEntrySourceReset = null;
      debugResetRevealEntrySource();
    });

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

    expect(
      consumeRevealEntrySource(),
      AnalyticsEvents.revealSourceOrganic,
      reason: 'a stamp left by the outgoing user must not survive to '
          'attribute the NEXT user\'s reveal to a push/widget they never '
          'touched',
    );

    await controller.close();
    session.dispose();
  });

  test('a THROWING reveal-entry-source-reset hook cannot break sign-out',
      () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final controller = StreamController<AuthState>.broadcast();
    const isAuthenticated = true;
    AppSessionNotifier.onRevealEntrySourceReset =
        () => throw StateError('reveal entry source reset boom');
    addTearDown(() => AppSessionNotifier.onRevealEntrySourceReset = null);

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

    // Normal sign-out side effects still ran despite the throwing hook.
    expect(session.hasOnboarded, isFalse);

    await controller.close();
    session.dispose();
  });

  test('a null reveal-entry-source-reset hook is a safe no-op on signedOut',
      () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final controller = StreamController<AuthState>.broadcast();
    const isAuthenticated = true;
    AppSessionNotifier.onRevealEntrySourceReset = null;

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
