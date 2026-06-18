import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/router.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_experiment.dart';
import 'package:sakina/features/paywall/reverse_trial_onboarding.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// G7 — E2E reverse-trial TREATMENT journey (the largest coherent slice that is
/// reliable without a live Supabase / RevenueCat / GoTrue stack).
///
/// Walks the whole lifecycle a treatment-arm user experiences, through the REAL
/// production seams (no behaviour re-implemented in the test):
///
///   1. onboarding-complete: `resolveAndApplyPaywallExperiment` (experiment ON,
///      treatment arm, `activate_trial(3)` mocked) — fires `experiment_assigned`
///      + `trial_activated` and calls the RPC exactly once.
///   2. trial ACTIVE: the trial window manifests as `isPremium:true` (that is
///      the ONLY way the trial reaches routing — PurchaseService.isPremium()
///      OR's the trial window in). The gate hydrates → routing = `app`, no wall.
///   3. expiry: flip the premium reader to `false` and re-hydrate → the soft
///      post-tour gate now surfaces (`softPaywall` / kOnboardingSoftPaywallPath).
///   4. dismiss: tapping the soft paywall's close X → `markPaywallCleared()` →
///      stage flips to `app` → the user lands on the free tier, never re-walled.
///
/// The arm bucketing, the experiment driver, the stage resolver, and the router
/// redirect are all the live code; only the three external boundaries
/// (Supabase RPC, RevenueCat channel, premium reader) are faked.
const MethodChannel _purchasesChannel = MethodChannel('purchases_flutter');

class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];
  final superProps = <String, dynamic>{};
  final userProps = <String, dynamic>{};

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));
  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superProps.addAll(props);
  @override
  void setUserProperties(Map<String, dynamic> props) => userProps.addAll(props);
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

/// A user id that deterministically buckets into the treatment arm.
String _treatmentId() {
  for (var i = 0;; i++) {
    final id = 'trt-$i';
    if (assignPaywallArm(id) == PaywallArm.treatmentReverseTrial) return id;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _SpyAnalytics analytics;
  late String userId;

  setUp(() {
    debugDisablePaywallAnimations = true;
    SharedPreferences.setMockInitialValues({});
    userId = _treatmentId();
    fakeSync = FakeSupabaseSyncService(userId: userId);
    fakeSync.rpcHandlers['activate_trial'] = (_) async => {
          'activated': true,
          'trial_premium_until':
              DateTime.now().toUtc().add(const Duration(days: 3)).toIso8601String(),
        };
    SupabaseSyncService.debugSetInstance(fakeSync);
    analytics = _SpyAnalytics();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, (_) async => null);
  });

  tearDown(() {
    debugDisablePaywallAnimations = false;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, null);
  });

  /// Builds a soft-mode session whose premium status is driven by a mutable
  /// flag, so the test can flip active→expired and re-hydrate the gate — exactly
  /// what PurchaseService.isPremium() does when the trial window lapses.
  AppSessionNotifier softSession({required ValueGetter<bool> premium}) {
    return AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: const Stream.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => userId,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      isPremiumReader: () async => premium(),
      postTourPaywallModeReader: () async => PostTourPaywallMode.soft,
      // Mirror production's `_defaultPaywallArm` but bound to the test's known
      // uid (the default reader resolves the uid from a live Supabase client,
      // which isn't initialised here). Resolves to the real arm ONLY once the
      // experiment driver has set the one-shot assigned flag — exactly the
      // re-hydration the fix relies on.
      paywallArmReader: () async {
        final prefs = await SharedPreferences.getInstance();
        final assigned = prefs.getBool(supabaseSyncService
                .scopedKey(paywallExperimentAssignedBaseKey)) ??
            false;
        if (!assigned) return null;
        return assignPaywallArm(userId);
      },
      notificationService: _FakeNotif(),
    );
  }

  String? redirect(String path, AppSessionNotifier s) =>
      onboardingGateRedirect(currentPath: path, appSession: s);

  test(
      'full treatment journey: onboarding-complete activates trial → active '
      'routes to app → expiry surfaces the soft gate (pure-seam walk)',
      () async {
    // ---- 1. onboarding-complete: run the REAL experiment driver --------------
    await resolveAndApplyPaywallExperiment(
      experimentEnabled: true,
      userId: userId,
      analytics: analytics,
    );

    // Arm recorded + experiment_assigned + trial_activated all fired once.
    expect(analytics.superProps[AnalyticsEvents.paywallExpArm],
        'treatment_reverse_trial');
    final assigned = analytics.events
        .where((e) => e.event == AnalyticsEvents.experimentAssigned);
    expect(assigned, hasLength(1));
    final trialEvents = analytics.events
        .where((e) => e.event == AnalyticsEvents.trialActivated)
        .toList();
    expect(trialEvents, hasLength(1),
        reason: 'treatment fires trial_activated exactly once');
    expect(trialEvents.single.props?[AnalyticsEvents.propDays], 3);

    // activate_trial(3) called exactly once.
    final rpc =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'activate_trial').toList();
    expect(rpc, hasLength(1));
    expect((rpc.single['params'] as Map)['p_days'], 3);

    // ---- 2. trial ACTIVE → routing = app (no wall) ---------------------------
    // The forced tour is now done: persist the tour-seen flag exactly as
    // onboarding_tour_controller does at completion, so every gate re-hydration
    // reads tour=true from server-of-truth prefs (not a brittle in-memory flag).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingTourSeenFlag(userId), true);

    var trialActive = true;
    final session = softSession(premium: () => trialActive);
    await session.enterOnboardingGate(); // new user enters the gate (latch=false)
    await session.hydrateOnboardingGate(); // tour=true (prefs) + live trial→premium

    expect(session.postTourPaywallMode, PostTourPaywallMode.soft);
    expect(session.isPremiumCached, isTrue,
        reason: 'the active trial window manifests as premium in routing');
    expect(redirect('/', session), isNull,
        reason: 'an active trial clears the soft gate — straight into the app');
    expect(redirect('/duas', session), isNull,
        reason: 'no wall at the real slim-tour-exit route either');

    // ---- 3. EXPIRY: flip the trial off, re-hydrate → soft gate surfaces ------
    trialActive = false;
    await session.hydrateOnboardingGate();
    expect(session.isPremiumCached, isFalse,
        reason: 'expired trial → premium drops');
    expect(redirect('/', session), kOnboardingSoftPaywallPath,
        reason: 'post-expiry the dismissible soft paywall is presented');
    expect(redirect('/duas', session), kOnboardingSoftPaywallPath);
    // While sitting on the soft paywall itself the redirect leaves you put
    // (dismiss is the exit, not lenient routing).
    expect(redirect(kOnboardingSoftPaywallPath, session), isNull);

    session.dispose();
  });

  test(
      'REGRESSION (device 2026-06-17): a treatment trial-holder is routed into '
      'the app — NOT the post-tour soft paywall — because onboarding-complete '
      're-hydrates the gate once the trial activates', () async {
    // Premium reflects the real trial window: false until activate_trial runs,
    // true once it has (exactly how PurchaseService.isPremium() OR's the trial
    // window in). This is the ONLY channel through which the trial reaches the
    // router gate.
    var trialActiveServerSide = false;
    fakeSync.rpcHandlers['activate_trial'] = (_) async {
      trialActiveServerSide = true;
      return {
        'activated': true,
        'trial_premium_until': DateTime.now()
            .toUtc()
            .add(const Duration(days: 3))
            .toIso8601String(),
      };
    };

    // The forced tour is done (server-of-truth prefs flag, as the tour
    // controller persists at completion).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingTourSeenFlag(userId), true);

    // A brand-new treatment user sitting in the gate, PRE-trial: premium reads
    // false, so the soft gate would wall them. This is the exact on-device
    // state at the moment onboarding completes.
    final session = softSession(premium: () => trialActiveServerSide);
    await session.enterOnboardingGate(); // latch=false, new user in the gate
    await session.hydrateOnboardingGate(); // premium=false (trial not yet run)
    expect(session.isPremiumCached, isFalse);
    expect(redirect('/', session), kOnboardingSoftPaywallPath,
        reason: 'pre-trial the gate walls — the BUG is staying walled AFTER the '
            'trial activates');

    // ---- onboarding-complete: the REAL experiment driver -------------------
    // It activates the 3-day trial AND must refresh the gate (onArmApplied) so
    // the now-active trial is reflected BEFORE the router evaluates the gate.
    await resolveAndApplyPaywallExperiment(
      experimentEnabled: true,
      userId: userId,
      analytics: analytics,
      onArmApplied: session.hydrateOnboardingGate,
    );

    expect(trialActiveServerSide, isTrue, reason: 'activate_trial(3) ran');
    expect(session.isPremiumCached, isTrue,
        reason: 'the gate must see the freshly-activated trial as premium');
    expect(redirect('/', session), isNull,
        reason: 'BUG REPRO: a treatment trial-holder lands in the app, never '
            'the post-tour soft paywall');
    expect(redirect('/duas', session), isNull,
        reason: 'no wall at the slim-tour-exit route either');
    // The arm-aware soft-gate tagging now reflects the real arm (was the stale
    // "unassigned" on-device because the gate was never re-hydrated).
    expect(session.paywallArm, 'treatment_reverse_trial');

    session.dispose();
  });

  testWidgets(
      'post-expiry: the router renders a DISMISSIBLE soft paywall and the X '
      'dismiss drops the user to the free tier (app)', (tester) async {
    // Start already past the tour with an EXPIRED trial (premium false), soft
    // mode — i.e. step 3 of the journey, rendered through the real router.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingTourSeenFlag(userId), true);

    final session = softSession(premium: () => false);
    await session.enterOnboardingGate();
    await session.hydrateOnboardingGate(); // tour=true (prefs), premium=false
    addTearDown(session.dispose);

    // Sanity: the resolver agrees we are at the soft gate.
    expect(redirect('/', session), kOnboardingSoftPaywallPath);

    final router = buildRouter(appSession: session);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [appSessionProvider.overrideWithValue(session)],
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // reveal the close X

    expect(find.byType(PaywallScreen), findsOneWidget,
        reason: 'the expired-trial user is stood up on the soft paywall');
    expect(find.byIcon(Icons.close_rounded), findsOneWidget,
        reason: 'soft paywall must be dismissible (has the X)');

    // Dismiss → onComplete marks cleared + routes home. Bounded pumps (the home
    // shell never settles — repeating loaders).
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(session.paywallCleared, isTrue,
        reason: 'dismiss clears the latch → free tier');
    expect(redirect('/', session), isNull,
        reason: 'cleared → app; the user is never re-walled');
    expect(find.byType(PaywallScreen), findsNothing,
        reason: 'after dismiss the user is routed off the paywall into the app');

    // ---- RELAUNCH: a fresh session hydrating from persisted state must NOT
    // re-wall. The soft-paywall X-dismiss has to DURABLY clear the gate (via
    // OnboardingGateService), not just flip the in-memory latch — otherwise a
    // control user hits the soft paywall on EVERY cold launch instead of
    // landing home (device repro 2026-06-18, a@c.com / control). ----
    final relaunch = softSession(premium: () => false);
    addTearDown(relaunch.dispose);
    await relaunch.hydrateOnboardingGate();
    expect(relaunch.paywallCleared, isTrue,
        reason: 'soft-paywall dismiss must persist the cleared latch across '
            'launches');
    expect(redirect('/', relaunch), isNull,
        reason: 'BUG REPRO: control user re-walled every launch — the dismiss '
            'did not durably persist the cleared latch');
  });
}
