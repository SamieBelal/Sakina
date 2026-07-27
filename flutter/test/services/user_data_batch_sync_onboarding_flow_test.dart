import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// One Ship W2-C3 — the batch sync's `onboarding_flow` mirror.
///
/// Cross-device backfill only: the reel flow latches its own value locally at
/// completion (Wave F), so what matters here is that the server value REACHES
/// the session, and that an absent value stays absent rather than being
/// defaulted into `legacy` — which would suppress the tour for a legacy user on
/// their second device.
class _FakeNotificationService extends NotificationService {
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late List<OnboardingProfileSnapshot> snapshots;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    snapshots = [];
    UserProfileSyncHooks.onOnboardingProfileHydrated = snapshots.add;
  });

  tearDown(() {
    UserProfileSyncHooks.onOnboardingProfileHydrated = null;
    SupabaseSyncService.debugReset();
  });

  void respondWithProfile(Map<String, dynamic>? profile) {
    fakeSync.rpcHandlers['sync_all_user_data'] = (_) async => {
          if (profile != null) 'profile': profile,
        };
  }

  AppSessionNotifier buildSession() => AppSessionNotifier(
        initialOnboarded: true,
        authStateChanges: const Stream.empty(),
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'user-1',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        isPremiumReader: () async => false,
        hardPaywallFlowReader: () async => false,
        notificationService: _FakeNotificationService(),
      );

  test('a reel_v1 profile reaches the hook with the promise flagged present',
      () async {
    respondWithProfile({
      'onboarding_flow': 'reel_v1',
      'acquisition_promise': {'contract': 'problem', 'hook_type': 'chip'},
    });

    await hydrateUserDataFromBatchRpc();

    expect(snapshots, hasLength(1));
    expect(snapshots.single.onboardingFlow, 'reel_v1');
    expect(snapshots.single.hasAcquisitionPromise, isTrue);
  });

  test('a pre-W1 profile mirrors null, never a guessed "legacy"', () async {
    respondWithProfile({'selected_title': 'Seeker'});

    await hydrateUserDataFromBatchRpc();

    expect(snapshots, hasLength(1));
    expect(snapshots.single.onboardingFlow, isNull);
    expect(snapshots.single.hasAcquisitionPromise, isFalse);
  });

  test('no profile section → the hook does not fire at all', () async {
    respondWithProfile(null);

    await hydrateUserDataFromBatchRpc();

    expect(snapshots, isEmpty);
  });

  group('the session mirror', () {
    test('holds the server value and notifies the router', () async {
      final session = buildSession();
      addTearDown(session.dispose);
      var notifications = 0;
      session.addListener(() => notifications++);

      expect(session.onboardingFlow, isNull,
          reason: 'unhydrated is not "legacy"');

      session.setOnboardingFlow(AppSessionNotifier.onboardingFlowReelV1);

      expect(session.onboardingFlow, 'reel_v1');
      expect(notifications, 1);

      // Idempotent: a repeat hydrate must not churn the redirect.
      session.setOnboardingFlow('reel_v1');
      expect(notifications, 1);
    });

    test('is wired end-to-end from the batch payload', () async {
      final session = buildSession();
      addTearDown(session.dispose);
      UserProfileSyncHooks.onOnboardingProfileHydrated =
          (s) => session.setOnboardingFlow(s.onboardingFlow);
      respondWithProfile({'onboarding_flow': 'reel_v1'});

      await hydrateUserDataFromBatchRpc();

      expect(session.onboardingFlow, 'reel_v1');
    });
  });
}
