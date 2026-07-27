import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart'
    show onboardingTourSeenFlag;
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/services/card_collection_service.dart' show CardTier;
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/onboarding_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// One Ship W2-E1 / plan §F1 — which post-onboarding gate a finished user gets.
///
/// The blocker this pins: naively "just don't call `enterOnboardingGate` for
/// reel users" strands them in stage `tour` forever. The stage machine only
/// reaches the paywall stages after `tourCompleted`, and the router lets
/// tour-stage users roam — so they would meet no paywall anywhere. The reel
/// branch therefore latches BOTH flags, and it branches on the flow the user
/// actually RAN, not on the current flag state: a kill-switch revert has to
/// restore the tour for legacy users without re-gating the reel users who
/// already skipped it.
class _StubAuthService extends AuthService {
  _StubAuthService([this.log]);

  /// Shared step log, when the test cares about ORDER.
  final List<String>? log;

  @override
  bool get isSignedIn => true;

  @override
  Future<void> saveOnboardingData({
    String? displayName,
    String? intention,
    String? familiarity,
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    int? starterNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool commitmentAccepted = false,
    Map<String, dynamic>? acquisitionPromise,
    String? firstProblemText,
    String? onboardingFlow,
  }) async {}

  @override
  Future<void> seedStarterCard(
    int nameId, {
    CardTier tier = CardTier.bronze,
  }) async {}

  @override
  Future<void> markOnboardingCompleted() async => log?.add('markCompleted');
}

/// Records WHEN each gate write happens relative to the rest of completion.
class _RecordingSession extends AppSessionNotifier {
  _RecordingSession(this.log, {required super.hardPaywallFlowReader})
      : super(
          initialOnboarded: false,
          authStateChanges: const Stream.empty(),
          isAuthenticatedProvider: _yes,
          currentUserIdProvider: _uid,
          hydrateEconomyCache: _noop,
          hasCompletedOnboarding: _yesAsync,
          isPremiumReader: _noAsync,
          notificationService: _FakeNotificationService(),
        );

  static bool _yes() => true;
  static String? _uid() => 'user-1';
  static Future<void> _noop() async {}
  static Future<bool> _yesAsync() async => true;
  static Future<bool> _noAsync() async => false;

  final List<String> log;

  @override
  Future<void> skipOnboardingGateForReelFlow() async {
    log.add('gate');
    await super.skipOnboardingGateForReelFlow();
  }

  @override
  Future<void> enterOnboardingGate() async {
    log.add('gate');
    await super.enterOnboardingGate();
  }

  @override
  Future<void> markOnboarded() async {
    log.add('markOnboarded');
    await super.markOnboarded();
  }
}

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> logout() async {}
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'user-1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: userId),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  /// A session with the hard-paywall gate ACTIVE — the state a new user
  /// finishes onboarding in today.
  Future<AppSessionNotifier> buildSession({bool hardPaywall = true}) async {
    final session = AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: const Stream.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => userId,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      isPremiumReader: () async => false,
      hardPaywallFlowReader: () async => hardPaywall,
      notificationService: _FakeNotificationService(),
    );
    // `hardPaywallFlowEnabled` is only populated by a hydrate; without it the
    // legacy branch would read the ungated default and skip the gate for the
    // wrong reason.
    await session.hydrateOnboardingGate();
    return session;
  }

  OnboardingNotifier notifierFor(String flow) {
    final notifier = OnboardingNotifier(authService: _StubAuthService());
    notifier.setOnboardingFlow(flow);
    return notifier;
  }

  Future<bool?> storedTourSeen() async =>
      (await SharedPreferences.getInstance())
          .getBool(onboardingTourSeenFlag(userId));

  group('reel flow', () {
    test('latches BOTH gate flags instead of entering the tour gate',
        () async {
      final session = await buildSession();
      addTearDown(session.dispose);
      expect(session.tourCompleted, isFalse,
          reason: 'precondition: a fresh user hydrates with no tour-seen flag');

      await notifierFor(onboardingFlowReel).completeOnboarding(session);

      expect(session.tourCompleted, isTrue);
      expect(session.paywallCleared, isTrue);
    });

    test('mirrors the flow into the session synchronously', () async {
      // The router's redirect reads this during a build; a value that only
      // landed after the batch-sync hydrate would lose the day-0 race.
      final session = await buildSession();
      addTearDown(session.dispose);

      await notifierFor(onboardingFlowReel).completeOnboarding(session);

      expect(session.onboardingFlow, AppSessionNotifier.onboardingFlowReelV1);
      expect(session.onboardingFlow, onboardingFlowReel,
          reason: 'the session copy and the provider copy must not drift — a '
              'drift suppresses the tour for nobody while marking every '
              'profile reel_v1');
    });

    test('persists both latches so the NEXT cold launch is not re-gated',
        () async {
      // hydrateOnboardingGate reads the tour-seen flag as `false` when absent,
      // so an in-memory-only latch would park the user in stage `tour` on
      // launch two.
      final session = await buildSession();
      addTearDown(session.dispose);

      await notifierFor(onboardingFlowReel).completeOnboarding(session);

      expect(await storedTourSeen(), isTrue);
      expect(await OnboardingGateService().isPaywallCleared(), isTrue);

      final relaunched = await buildSession();
      addTearDown(relaunched.dispose);
      expect(relaunched.tourCompleted, isTrue);
      expect(relaunched.paywallCleared, isTrue);
    });
  });

  group('when the gate is latched', () {
    Future<List<String>> runOrdered(String flow) async {
      final log = <String>[];
      final session = _RecordingSession(log, hardPaywallFlowReader: () async => true);
      addTearDown(session.dispose);
      await session.hydrateOnboardingGate();

      final notifier = OnboardingNotifier(authService: _StubAuthService(log));
      notifier.setOnboardingFlow(flow);
      await notifier.completeOnboarding(session);
      return log;
    }

    test('the reel latch lands right after the completion flag, ahead of the '
        'network tail', () async {
      // Run at the END of completion, the gate write sat behind the first-steps
      // sync, the referral confirm and two premium-cache refreshes — seconds of
      // day-0 network. An app kill inside that window left the server thinking
      // the user was onboarded while no tour-seen flag existed locally, so the
      // next launch handed a reel user the legacy opportunistic tour.
      final log = await runOrdered(onboardingFlowReel);

      expect(log.indexOf('gate'), greaterThan(log.indexOf('markCompleted')),
          reason: 'the gate describes a FINISHED onboarding');
      expect(log.indexOf('gate'), lessThan(log.indexOf('markOnboarded')),
          reason: 'markOnboarded closes the tail the hoist skips ahead of');
    });

    test('the legacy branch is hoisted with it', () async {
      final log = await runOrdered(onboardingFlowLegacy);

      expect(log.indexOf('gate'), greaterThan(log.indexOf('markCompleted')));
      expect(log.indexOf('gate'), lessThan(log.indexOf('markOnboarded')),
          reason: 'the same kill window strands a legacy user OUTSIDE the '
              'hard-paywall gate they were meant to enter');
    });
  });

  group('kill-switch flows', () {
    test('legacy still enters the onboarding gate when the flag is ON',
        () async {
      final session = await buildSession();
      addTearDown(session.dispose);

      await notifierFor(onboardingFlowLegacy).completeOnboarding(session);

      expect(session.tourCompleted, isFalse);
      expect(session.paywallCleared, isFalse);
      expect(await OnboardingGateService().isPaywallCleared(), isFalse);
      expect(await storedTourSeen(), isNull,
          reason: 'a legacy user has NOT seen the tour — the flag must stay '
              'unwritten so the forced tour still runs');
    });

    test('legacy stays grandfathered when the hard-paywall flag is OFF',
        () async {
      final session = await buildSession(hardPaywall: false);
      addTearDown(session.dispose);

      await notifierFor(onboardingFlowLegacy).completeOnboarding(session);

      // Neither gated nor reel-latched: the pre-existing behaviour, untouched.
      expect(session.paywallCleared, isTrue,
          reason: 'the ungated default — no latch was written either way');
      expect(await storedTourSeen(), isNull);
    });

    test('an unset flow is treated as legacy, never as reel', () async {
      // Null means "we do not know", and guessing reel would silently skip the
      // tour AND the wall for a user who ran neither reel screen.
      final session = await buildSession();
      addTearDown(session.dispose);

      await OnboardingNotifier(authService: _StubAuthService())
          .completeOnboarding(session);

      expect(session.tourCompleted, isFalse);
      expect(session.paywallCleared, isFalse);
    });
  });
}
