import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/sakina_loader.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/app_config_service.dart';
import '../../../services/reel_deep_link_service.dart';
import '../../paywall/paywall_placement.dart';
import '../content/problem_chips.dart';
import '../providers/onboarding_provider.dart';
import 'age_range_screen.dart';
import 'aspirations_screen.dart';
import 'attribution_screen.dart';
import 'carrying_duration_screen.dart';
import 'daily_time_screen.dart';
import 'commitment_pact_screen.dart';
import 'common_emotions_screen.dart';
import 'daily_commitment_screen.dart';
import 'dua_topics_screen.dart';
import 'encouragement_screen.dart';
import 'familiarity_screen.dart';
import 'first_checkin_screen.dart';
import 'generating_screen.dart';
import 'heaviest_time_screen.dart';
import 'help_chips_screen.dart';
import 'hook_problem_screen.dart';
import 'intake_note_screen.dart';
import 'intention_screen.dart';
import 'name_input_screen.dart';
import 'names_known_screen.dart';
import 'notification_screen.dart';
import 'onboarding_reveal_screen.dart';
import 'paywall_screen.dart';
import 'personalized_plan_screen.dart';
import 'prayer_frequency_screen.dart';
import 'queue_plan_screen.dart';
import 'quran_connection_screen.dart';
import 'rating_gate_screen.dart';
import 'reminder_time_screen.dart';
import 'save_progress_screen.dart';
import 'sign_up_email_screen.dart';
import 'sign_up_password_screen.dart';
import 'social_proof_screen.dart';
import 'told_anyone_screen.dart';
import 'source_question_screen.dart';
import 'struggle_support_interstitial_screen.dart';
import 'value_prop_screen.dart';
import 'widget_offer_screen.dart';
import 'your_journey_screen.dart';

/// Returns true when [resumedAt] is more than 24 hours after [pausedAt].
/// Extracted as a top-level helper so the abandonment threshold logic is
/// directly unit-testable (see test/features/onboarding/abandonment_telemetry_test.dart).
@visibleForTesting
bool shouldFireAbandonment({
  required DateTime pausedAt,
  required DateTime resumedAt,
}) {
  return resumedAt.difference(pausedAt) > const Duration(hours: 24);
}

/// The WHOLE `onboarding_abandoned_at_page` predicate, exactly as
/// [_OnboardingScreenState.didChangeAppLifecycleState] applies it — not just
/// the 24h threshold. Top-level and pure so the test drives the shipping rule
/// instead of a re-declared copy of it that can silently drift.
///
/// Suppressed when:
///   * nothing was recorded at pause time ([pausedPage] / [pausedAt] null);
///   * the pause was on the ACTIVE flow's paywall (the funnel's end — they
///     reached it and didn't buy, which `paywall_viewed` already says);
///   * completion is in flight ([completing]) — otherwise a backgrounded
///     post-paywall round-trip logs both "completed" and "abandoned".
@visibleForTesting
bool shouldEmitAbandonment({
  required int? pausedPage,
  required DateTime? pausedAt,
  required DateTime resumedAt,
  required OnboardingFlowKind flow,
  required bool completing,
}) {
  if (pausedPage == null || pausedAt == null) return false;
  if (pausedPage == activeOnboardingLastPageIndex(flow)) return false;
  if (completing) return false;
  return shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt);
}

/// How long [resolveOnboardingFlow] will wait for a FIRST fresh read of the
/// reel kill switch. Long enough for a normal round-trip, short enough that a
/// dead network costs a first-install user a beat, not a blank screen.
const Duration reelFlagFreshReadTimeout = Duration(seconds: 2);

/// Picks between the three page orders (W2-E1, plan review 4).
///
/// `reel_first_onboarding_enabled` is checked FIRST and short-circuits: the
/// reel flow is its own page order, not a trim of the legacy one. With it OFF,
/// the existing `onboarding_trim_enabled` decision runs unchanged — the kill
/// switch has to reproduce the CURRENT prod experience, which is the trimmed
/// flow, not the 27-page one.
///
/// On a FIRST install there is no cached value for the reel flag, and
/// [AppConfigService.getBool] answers cache-or-fallback immediately — so a
/// reverted kill switch would not take effect on the one launch where the
/// revert matters. This waits (bounded by [freshReadTimeout]) for a single
/// fresh read of that ONE key before deciding. Launches WITH a cached value
/// skip the wait entirely, so the normal cold launch is not slowed.
///
/// Never throws: the caller's whole entry sequence — the flow field, the
/// `onboarding_flow` write and the funnel-entry events — hangs off this future,
/// so an error would leave the screen rendering the optimistic default with no
/// telemetry at all. A failed read means the same thing the flag's own
/// `fallback: true` does: reel, the shipping experience.
///
/// Top-level so the timeout behaviour is unit-testable without a PageView.
@visibleForTesting
/// Which page a resumed session should open on, given the page it saved and the
/// flow it saved it under.
///
/// **A page index only means something inside the flow that recorded it.** The
/// flows are hand-ordered and of similar length, so a saved index is almost
/// always *in bounds* for the other flow and *semantically wrong* — the
/// existing out-of-bounds clamp cannot see that. A user paused on reel page 12
/// (WidgetOfferScreen, mid-intake, pre-signup) who resumes after a kill-switch
/// flip would land on trimmed page 12 (SocialProofScreen, one page before
/// sign-up), skipping twelve required questions and arriving at signup with all
/// of them empty, while their reel answers sit stranded and unread.
///
/// Nothing invalid gets persisted and nothing crashes, which is exactly why it
/// would go unnoticed — and the kill switch is the ROLLBACK path, so this fires
/// at the one moment a second failure is least affordable.
///
/// Restarting costs the user their answers so far. That is chosen deliberately
/// over the two alternatives: reinterpreting the index skips required questions
/// silently, and maintaining an index-mapping table between two hand-ordered
/// flows is a thing nobody will keep correct. During a rollback,
/// coherent-and-annoying beats broken-and-quiet.
///
/// An UNKNOWN saved flow (a pre-W2 install, or a corrupted blob) resumes
/// normally: absence of evidence is not evidence of a mismatch, and restarting
/// those users would punish everyone who installed before the field existed to
/// guard against a flip that may never happen.
///
/// Pure and top-level so the shipping predicate and the tested one are the same
/// code — the same shape as [shouldEmitAbandonment] below.
@visibleForTesting
int resolveResumePage({
  required int savedPage,
  required String? savedFlow,
  required OnboardingFlowKind resolved,
}) {
  if (savedPage <= 0) return 0;
  if (savedFlow == null || savedFlow.isEmpty) return savedPage;
  // trimmed and legacy share one persisted value: a trim-flag change reorders
  // nothing, so it is not a flow change.
  final resolvedValue = onboardingFlowValueFor(resolved);
  if (savedFlow != onboardingFlowReel && savedFlow != onboardingFlowLegacy) {
    return savedPage; // unrecognised — treat as unknown, not as a mismatch
  }
  return savedFlow == resolvedValue ? savedPage : 0;
}

Future<OnboardingFlowKind> resolveOnboardingFlow(
  AppConfigService config, {
  Duration freshReadTimeout = reelFlagFreshReadTimeout,
}) async {
  try {
    if (!await config.hasCachedValue(reelFirstOnboardingFlag)) {
      await config
          .primeCache(const [reelFirstOnboardingFlag])
          .timeout(freshReadTimeout, onTimeout: () {});
    }
  } catch (_) {
    // The probe is an optimisation on top of the read below. If prefs or the
    // network misbehaves, degrade to the plain cache-or-fallback read.
  }
  try {
    final reel = await config.getBool(reelFirstOnboardingFlag, fallback: true);
    if (reel) return OnboardingFlowKind.reel;
    final trimmed =
        await config.getBool('onboarding_trim_enabled', fallback: true);
    return trimmed ? OnboardingFlowKind.trimmed : OnboardingFlowKind.legacy;
  } catch (error, stack) {
    debugPrint('OnboardingScreen: flow flag read failed — $error\n$stack');
    return OnboardingFlowKind.reel;
  }
}

/// Last valid page index for the active onboarding flow: reel ends at
/// [onboardingReelLastPageIndex] (18), trimmed at [onboardingLastPageIndex]
/// (19), legacy at [onboardingLegacyLastPageIndex] (26). Pure top-level fn so
/// the three-flow bound (used by `_next`, the paywall-event triggers, and the
/// abandonment paywall gate) is directly unit-testable without driving the full
/// PageView. See test/features/onboarding/onboarding_tri_flow_test.dart.
@visibleForTesting
int activeOnboardingLastPageIndex(OnboardingFlowKind flow) =>
    lastPageIndexForFlow(flow);

/// Whether a move from [from] to [to] is permitted in [flow].
///
/// The one rule: in the reel flow, nothing at or past
/// [onboardingReelNoBackBeforeIndex] may go back to the hook or the reveal.
/// The reveal awards a card and burns its once-per-run latch on "Ameen", so a
/// re-entry lands the user on a deck whose Ameen does nothing, and re-answering
/// the hook resolves a pair that contradicts the card they already own.
/// `OnboardingRevealLatch` guards the double-award; this guards the dead end.
///
/// Pure and top-level so the rule is testable without a PageView.
@visibleForTesting
bool canNavigateOnboarding({
  required OnboardingFlowKind flow,
  required int from,
  required int to,
}) {
  if (flow != OnboardingFlowKind.reel) return true;
  return !(from >= onboardingReelNoBackBeforeIndex &&
      to < onboardingReelNoBackBeforeIndex);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late final Future<OnboardingFlowKind> _flowFuture;
  // Resolved flow: reel (default, 13 pages) vs the two kill-switch fallbacks,
  // trimmed (20) and legacy (27). Starts optimistic-reel to match the
  // FutureBuilder default, then corrected once `_flowFuture` resolves. Used by
  // `_next`, the abandonment gate, the nav guard, and the paywall-event
  // triggers so they all reference the ACTIVE flow.
  OnboardingFlowKind _flow = OnboardingFlowKind.reel;
  bool get _isReel => _flow == OnboardingFlowKind.reel;
  bool get _trimmed => _flow == OnboardingFlowKind.trimmed;
  bool _navigating = false;

  /// One latch per onboarding RUN, handed to the reveal screen so a PageView
  /// rebuild or a re-mount can neither award a second card nor re-emit the
  /// deck telemetry. Lives here, not in the reveal's own State, by that
  /// screen's contract.
  final OnboardingRevealLatch _revealLatch = OnboardingRevealLatch();

  /// Drained from a `sakina://feel/<emotion>` link — pre-selects a hook card.
  ///
  /// A State field is right for THIS one: it is a pre-selection on a screen the
  /// user is looking at, and a kill before they answer costs nothing but the
  /// highlight. The reel link's pair override is different — it changes what
  /// the reveal shows — so it lives in `OnboardingState` instead.
  String? _pendingFeelChipKey;

  final Set<int> _viewedEmitted = <int>{};
  final Set<int> _completedEmitted = <int>{};
  final Set<int> _dropoffEmitted = <int>{};

  // Abandonment telemetry (Task A10): when the app is backgrounded mid-
  // onboarding for 24h+, fire `onboarding_abandoned_at_page` on resume so
  // the funnel can attribute drop-offs to specific pages.
  DateTime? _pausedAt;
  int? _pausedAtPage;
  // Set as soon as _completeOnboarding starts so a backgrounding during the
  // post-paywall Supabase round-trip doesn't log abandonment-at-last-page.
  bool _completing = false;

  /// Last valid page index for the ACTIVE flow. Used to drive `_next`'s upper
  /// bound, the paywall-event triggers, and the abandonment paywall gate so
  /// they all track the flow the user is actually in.
  int get _activeLastPageIndex => activeOnboardingLastPageIndex(_flow);

  Map<int, String> get _stepNames =>
      AnalyticsEvents.stepNamesFor(trimmed: _trimmed, reel: _isReel);

  void _emitStepViewedOnce(int index) {
    if (!_viewedEmitted.add(index)) return;
    ref
        .read(analyticsProvider)
        .trackStepViewed(index, trimmed: _trimmed, reel: _isReel);
    _emitPaywallFlowShown(index);
  }

  void _emitStepCompletedOnce(int index) {
    if (!_completedEmitted.add(index)) return;
    ref
        .read(analyticsProvider)
        .trackStepCompleted(index, trimmed: _trimmed, reel: _isReel);
    _emitPaywallFlowContinued(index);
  }

  // NOTE: `paywall_viewed` (and the legacy hardcoded `paywall_plan_selected`
  // {plan:'annual'}) are NO LONGER emitted from this screen. `PaywallScreen`
  // now fires `paywall_viewed` from its own `initState` for ALL three surfaces
  // (onboarding, post-tour hard wall, soft in-app) with a `placement` property,
  // making it the single source of truth. The legacy-flow special-case
  // suppression that lived here is therefore obsolete: when the soft onboarding
  // PaywallScreen renders (flag OFF), its initState emits the view event with
  // `placement: onboarding`; when the new flow is on (flag ON), no soft paywall
  // renders here at all, so there is nothing to suppress.

  // Granular paywall-flow funnel (F-08): the loader→plan→journey pages (22-24
  // legacy / 16-17 trimmed) had no dedicated instrumentation. Keyed on
  // `step_name` so both dual-flow index sets resolve correctly (trimmed has no
  // journey page). Fired from the deduped step hooks below, so once per page.
  void _emitPaywallFlowShown(int index) {
    final name = _stepNames[index];
    final analytics = ref.read(analyticsProvider);
    if (name == 'paywall_flow_loader') {
      analytics.track(AnalyticsEvents.paywallFlowLoaderShown);
    } else if (name == 'paywall_flow_plan') {
      analytics.track(AnalyticsEvents.paywallFlowPlanShown);
    } else if (name == 'paywall_flow_journey') {
      analytics.track(AnalyticsEvents.paywallFlowJourneyShown);
    }
  }

  void _emitPaywallFlowContinued(int index) {
    final name = _stepNames[index];
    final analytics = ref.read(analyticsProvider);
    if (name == 'paywall_flow_loader') {
      analytics.track(AnalyticsEvents.paywallFlowLoaderAdvanced);
    } else if (name == 'paywall_flow_plan') {
      analytics.track(AnalyticsEvents.paywallFlowPlanContinued);
    } else if (name == 'paywall_flow_journey') {
      analytics.track(AnalyticsEvents.paywallFlowJourneyContinued);
    }
  }

  // Backward navigation OUT of a paywall-flow page = the user didn't continue
  // forward through the funnel. Complements the derivable funnel drop (a
  // *_shown without the next step) with an explicit signal.
  void _emitPaywallFlowDropoffIfLeaving(int fromIndex, int toIndex) {
    final names = _stepNames;
    final name = names[fromIndex];
    if (name == null || !name.startsWith('paywall_flow_')) return;
    // The loader (GeneratingScreen) auto-advances forward, so backing INTO it
    // isn't a real exit — the user is bounced straight back into the funnel.
    // Counting that as a dropoff is a phantom.
    if (names[toIndex] == 'paywall_flow_loader') return;
    // Once per page per session — crossing the boundary back-and-forth must not
    // inflate the dropoff count (it complements the once-per-session *_shown).
    if (!_dropoffEmitted.add(fromIndex)) return;
    ref.read(analyticsProvider).track(
      AnalyticsEvents.paywallFlowDropoff,
      properties: {'from': name},
    );
  }

  @override
  void initState() {
    super.initState();
    // Started FIRST so the flag read overlaps the rest of initState; the
    // continuation is attached below, once `initialPage` exists to hand it.
    _flowFuture = _resolveFlow();
    WidgetsBinding.instance.addObserver(this);
    final restoredPage = ref.read(onboardingProvider).currentPage;
    // Clamp against the LARGEST of the three maxes, because the flow decision
    // is async — clamping against a shorter flow's index prematurely would
    // strand a returner (e.g. saved currentPage=24, YourJourney) at some other
    // flow's paywall. The FutureBuilder + PageView re-correct the bounds once
    // the flow resolves (and that re-clamp waits for `hasData` for the same
    // reason). Legacy is the longest of the three, so nobody is affected.
    const maxInitial =
        onboardingLegacyLastPageIndex > onboardingLastPageIndex
            ? onboardingLegacyLastPageIndex
            : onboardingLastPageIndex;
    final initialPage = restoredPage.clamp(0, maxInitial);
    _pageController = PageController(initialPage: initialPage);
    if (initialPage != restoredPage) {
      Future(() => ref.read(onboardingProvider.notifier).setPage(initialPage));
    }
    // Mirror the resolved flow into a field so `_next`, the abandonment gate,
    // the nav guard, and the paywall triggers (all outside `build`) can read
    // it. The FutureBuilder in `build` remains the authoritative source for
    // rendering.
    _flowFuture.then((kind) {
      if (!mounted) return;
      if (kind != _flow) setState(() => _flow = kind);
      // A saved page only means something inside the flow that recorded it. If
      // the kill switch flipped between launches, the index is in bounds for
      // the new flow and points at a completely different screen — see
      // [resolveResumePage]. Done BEFORE `setOnboardingFlow` below, which
      // overwrites the recorded flow with the resolved one and would erase the
      // evidence of the mismatch.
      final state = ref.read(onboardingProvider);
      final safePage = resolveResumePage(
        savedPage: state.currentPage,
        savedFlow: state.onboardingFlow,
        resolved: kind,
      );
      if (safePage != state.currentPage) {
        ref.read(onboardingProvider.notifier).setPage(safePage);
        if (_pageController.hasClients) _pageController.jumpToPage(safePage);
      }
      // Record which EXPERIENCE this user ran, at entry rather than at
      // completion: it rides every `saveOnboardingData` persist (including the
      // final one that the freeze trigger locks), and `completeOnboarding`
      // branches on it to decide the post-onboarding gate.
      ref
          .read(onboardingProvider.notifier)
          .setOnboardingFlow(onboardingFlowValueFor(kind));
      // W6 Wave A — registered BEFORE _emitEntryFunnelEvents so the funnel's
      // widest event (onboarding_started) carries them; Mixpanel never
      // backfills a property registered after the event it should have ridden.
      // `unknown`, not omitted, for the reel-hook pair — an absent property
      // reads as organic traffic, `unknown` reads as "we don't know yet".
      // Direct `setSuperProperties`, not `AppSessionNotifier.setOnboardingFlow`
      // (that hook is the RETURNING-user path via server hydration; a new user
      // has no session flow yet, and double-registering through it would run
      // it through `cacheDeviceSuperProperties`, which is boot-only).
      ref.read(analyticsProvider).setSuperProperties({
        AnalyticsEvents.propOnboardingFlow: onboardingFlowValueFor(kind),
        AnalyticsEvents.propReelHookSource: AnalyticsEvents.reelHookSourceUnknown,
        AnalyticsEvents.propReelHook: AnalyticsEvents.reelHookSourceUnknown,
      });
      _emitEntryFunnelEvents(initialPage);
      if (kind == OnboardingFlowKind.reel) unawaited(_drainReelDeepLinks());
    });
  }

  /// Funnel entry (2026-06-15 audit, D3): `onboarding_started` once per
  /// onboarding start — this OnboardingScreen instance is created when the
  /// router enters onboarding, so a single fire == one start. It's the
  /// denominator the rest of the onboarding funnel divides into. Carries
  /// `entry_page` so a resumed mid-flow start (restored currentPage != 0) is
  /// separable from a true first-page start.
  ///
  /// Fired from the `_flowFuture` continuation, NOT from an initState
  /// post-frame callback: `_flow` is optimistically `reel` until the flag
  /// resolves, and the post-frame callback always won that race — so a
  /// kill-switch user's very first `onboarding_step_viewed` carried a REEL step
  /// name for a page they were never shown, mis-segmenting the funnel at its
  /// widest point. One await later the flow is known and the names are right.
  ///
  /// `paywall_viewed` for the final page is emitted by PaywallScreen's own
  /// initState (single source of truth) — no per-page fire here.
  void _emitEntryFunnelEvents(int initialPage) {
    final analytics = ref.read(analyticsProvider);
    analytics.track(
      AnalyticsEvents.onboardingStarted,
      properties: {'entry_page': initialPage},
    );
    _emitStepViewedOnce(initialPage);
    if (initialPage == 0) {
      analytics.timeEvent(AnalyticsEvents.onboardingCompleted);
    }
  }

  Future<OnboardingFlowKind> _resolveFlow() =>
      resolveOnboardingFlow(ref.read(appConfigServiceProvider));

  /// Drains whatever `sakina://reel/…` / `sakina://feel/…` left in prefs at
  /// launch (W2-E4). Only in the reel flow: the kill-switch flows have no hook
  /// screen to pre-select and no `reel_id` to stamp, and consuming the keys
  /// there would throw the arrival away for good.
  Future<void> _drainReelDeepLinks() async {
    final arrival = await consumePendingReelArrival();
    final chip = await consumePendingFeelChip();
    if (!mounted) return;
    if (arrival != null) {
      ref.read(onboardingProvider.notifier).setReelArrival(
            reelId: arrival.reelId,
            nameIds: arrival.nameIds,
          );
      // W6 Wave A (D2): upgrade `reel_hook` from `unknown` to the confirmed
      // deep-link id, together with `reel_hook_source` — the two properties
      // must always move as a pair, or a breakdown would read a confirmed id
      // against an `unknown` provenance.
      ref.read(analyticsProvider).setSuperProperties({
        AnalyticsEvents.propReelHook: arrival.reelId,
        AnalyticsEvents.propReelHookSource:
            AnalyticsEvents.reelHookSourceDeepLink,
      });
    }
    if (chip == null) return;
    setState(() => _pendingFeelChipKey = chip);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _pausedAtPage = ref.read(onboardingProvider).currentPage;
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final resumedAt = DateTime.now();
      // The suppression rules live in `shouldEmitAbandonment` (top-level, pure,
      // directly tested) so the shipping predicate and the tested one are the
      // same code.
      if (shouldEmitAbandonment(
        pausedPage: _pausedAtPage,
        pausedAt: _pausedAt,
        resumedAt: resumedAt,
        flow: _flow,
        completing: _completing,
      )) {
        final gone = resumedAt.difference(_pausedAt!);
        ref.read(analyticsProvider).track(
          AnalyticsEvents.onboardingAbandonedAtPage,
          properties: {
            'page': _pausedAtPage,
            'gone_hours': gone.inHours,
          },
        );
      }
      _pausedAt = null;
      _pausedAtPage = null;
    }
  }

  void _goToPage(int page) {
    if (_navigating) return;

    final current = ref.read(onboardingProvider).currentPage;
    // Checked BEFORE the `_navigating` latch is taken: a refused move must
    // leave the screen navigable, not wedge it behind a guard nothing clears.
    if (!canNavigateOnboarding(flow: _flow, from: current, to: page)) return;
    _navigating = true;

    FocusManager.instance.primaryFocus?.unfocus();

    ref.read(onboardingProvider.notifier).setPage(page);

    // Only fire step_completed on forward navigation — back navigation is abandonment, not completion
    if (page > current) {
      _emitStepCompletedOnce(current);
    } else if (page < current) {
      _emitPaywallFlowDropoffIfLeaving(current, page);
    }
    _emitStepViewedOnce(page);
    // paywall_viewed for the final paywall page is emitted by PaywallScreen's
    // own initState (single source of truth) — no per-page fire here.

    if ((page - current).abs() > 1) {
      _pageController.jumpToPage(page);
      _navigating = false;
    } else {
      _pageController
          .animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _navigating = false);
    }
  }

  void _next() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < _activeLastPageIndex) _goToPage(current + 1);
  }

  /// Trimmed-flow social-auth landing: jump to Generating (16).
  void _skipToPostSignup() => _goToPage(onboardingPostSignupPageIndex);

  /// Reel-flow social-auth landing (W2-E2): jump to the final gate (12).
  /// Nothing is left to show an already-authenticated user — the reveal and the
  /// plan both ran before signup — so the page after the trio IS the gate.
  void _skipToReelPostSignup() =>
      _goToPage(onboardingReelPostSignupPageIndex);

  /// Legacy-flow social-auth landing: jump to Encouragement (21).
  /// Kept while the dual-flow kill switch is live; PR-2b will delete the
  /// legacy children + this helper after 7 days stable in prod.
  void _skipToEncouragement() =>
      _goToPage(onboardingLegacyEncouragementPageIndex);

  void _back() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) {
      _goToPage(current - 1);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _completeOnboarding() async {
    // Re-entry guard: the new-flow final gate fires this from a post-frame
    // callback that can run on multiple rebuilds, and a double-tap on the soft
    // paywall could also re-enter. Either way, complete exactly once.
    if (_completing) return;
    _completing = true;
    final analytics = ref.read(analyticsProvider);
    analytics.track(AnalyticsEvents.onboardingCompleted);
    analytics.setSuperProperties({'onboarding_completed': true});

    final state = ref.read(onboardingProvider);
    final profileProps = <String, dynamic>{};
    if (state.intention != null) profileProps['intention'] = state.intention;
    if (state.familiarity != null) {
      profileProps['familiarity'] = state.familiarity;
    }
    if (state.attribution.isNotEmpty) {
      profileProps['attribution'] = state.attribution.toList();
    }
    if (state.ageRange != null) profileProps['age_range'] = state.ageRange;
    if (state.prayerFrequency != null) {
      profileProps['prayer_frequency'] = state.prayerFrequency;
    }
    if (state.starterNameId != null) {
      profileProps['starter_name_id'] = state.starterNameId;
    }
    if (state.duaTopics.isNotEmpty) {
      profileProps['dua_topics'] = state.duaTopics.toList();
    }
    // `dua_topics_other` is NOT a profile property. It is free text, and a
    // People property is durable and queryable forever — one bad write outlives
    // every session that produced it. The boolean equivalent is emitted as an
    // event from dua_topics_screen.dart.
    if (state.duaTopicsOther != null) {
      profileProps['dua_topics_other_provided'] =
          state.duaTopicsOther!.trim().isNotEmpty;
    }
    if (state.dailyCommitmentMinutes != null) {
      profileProps['daily_commitment_minutes'] = state.dailyCommitmentMinutes;
    }
    if (state.reminderTime != null) {
      profileProps['reminder_time'] = state.reminderTime;
    }
    profileProps['commitment_accepted'] = state.commitmentAccepted;
    if (profileProps.isNotEmpty) analytics.setUserProperties(profileProps);

    analytics.flush();

    try {
      await ref
          .read(onboardingProvider.notifier)
          .completeOnboarding(ref.read(appSessionProvider));
    } catch (_) {}

    // The reverse-trial 2-arm experiment hook used to run here: it read
    // `reverse_trial_experiment_enabled`, bucketed the user, and — for the
    // treatment arm — called `activate_trial(3)` before re-hydrating the gate.
    // Retired 2026-08-01 (W5 Wave A); every user now takes what was the control
    // path, straight to the soft gate and the free tier.

    if (mounted) context.go('/');
  }

  /// The hook screen's tap, committed (W2-B2 → B3).
  ///
  /// A `sakina://reel/<id>?name_ids=…` link replaces the pair here and nowhere
  /// else: this is the single place the promise is written, so the override
  /// cannot land half-applied, and everything else about the answer — what the
  /// user said, and how — is carried through untouched.
  void _onHookCommitted(ChipSelection selection) {
    // Read from STATE, not a field on this object: the link was drained at
    // launch and persisted with the rest of the arrival, so an app kill between
    // the link and this tap still reveals the Names the reel named.
    final override = ref.read(onboardingProvider).reelPairOverride;
    ref.read(onboardingProvider.notifier).applyHookSelection(
          override.isEmpty ? selection : selection.withPairNameIds(override),
        );
    // W6 Wave A: `contract` / `acquisition_problem_category`, stamped at the
    // moment the promise resolves — this is the primary reel-of-origin
    // dimension (D3), with near-total coverage (every reel user picks a chip
    // or types, and typed input always resolves to HookContract.problem).
    ref.read(analyticsProvider).setSuperProperties({
      AnalyticsEvents.propContract: selection.contract,
      AnalyticsEvents.propAcquisitionProblemCategory: selection.problemCategory,
    });
    _next();
  }

  /// The reveal finished (deck → Silver card → sealed Name₂).
  ///
  /// The pair goes to the NOTIFIER, not a field on this State: the plan screen
  /// renders it, and `completeOnboarding` resolves the starter card and the
  /// queue head against it, so a local copy would leave the server-side half of
  /// the promise still reading the hook's pair.
  void _onRevealDone(OnboardingRevealResult result) {
    ref.read(onboardingProvider.notifier).setRevealedPair([
      result.name1Id,
      if (result.name2Id != null) result.name2Id!,
    ]);
    _next();
  }

  /// Reel 13-screen flow (One Ship W2). Default-on behind
  /// [reelFirstOnboardingFlag]; see the index constants in
  /// `onboarding_provider.dart` for the canonical order.
  ///
  /// Pages 0, 1 and 12 render NO progress bar (hook: spec ③ bans a step
  /// counter on screen one; reveal: full-screen sacred canvas; paywall: its own
  /// visual identity). Page 7 (the plan) is a payoff, not a step, and carries
  /// its own header. The remaining nine fill segments 0-8 of a
  /// [onboardingReelTotalSegments]-long bar, so it COMPLETES on the password
  /// screen.
  List<Widget> _reelChildren(
    List<int> pairNameIds,
    List<int> revealedPairNameIds,
  ) {
    return [
      // 0 — Hook: "What's weighing on you right now?" No back (first page).
      HookProblemScreen(
        initialChipKey: _pendingFeelChipKey,
        onCommitted: _onHookCommitted,
      ),
      // 1 — Reveal: Name₁'s deck → Silver card → Name₂ sealed.
      OnboardingRevealScreen(
        pairNameIds: pairNameIds,
        latch: _revealLatch,
        // W6 Wave B: rides `second_name_teased` alongside Name₂'s id/deck.
        // Read from state (not a field), same reasoning as `_onHookCommitted`
        // above — survives an app kill between the hook and this page.
        contract: ref.read(onboardingProvider).contract,
        // Deck personalisation Wave 5: which bridge/reflection sentence the
        // reveal shows. Read from state the same way `contract` is, so it
        // survives an app kill between the hook and this page.
        //
        // ⚠️ `problemCategory`, NOT `chipKey`. The state carries both and they
        // are different vocabularies (`far_from_allah` vs `far-from-allah`);
        // the authored variant ids follow the category, and the selector
        // refuses a chip key rather than half-matching it. Pinned by
        // `test/features/onboarding/onboarding_reveal_variant_test.dart`.
        problemCategory: ref.read(onboardingProvider).problemCategory,
        onBack: _back,
        onDone: _onRevealDone,
      ),
      // — Everything below is past the reveal: back-nav to 0/1 is refused. —
      // — Wave H: the INTAKE block. Seven questions about the user, each with
      //   a visible consequence on the plan screen (spec §2 — a question whose
      //   answer never surfaces is extractive, and a longer extractive form is
      //   worse than the three we had). Asks come AFTER the payoff, below. —
      // 2 — How long have you been carrying this? (no back: nowhere to go)
      CarryingDurationScreen(
        onNext: _next,
        progressSegment: 0,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 3 — When is it heaviest? DERIVES the reminder time, which is why the
      // reel order has no reminder-time page.
      HeaviestTimeScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 1,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 4 — Have you been able to tell anyone?
      ToldAnyoneScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 2,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 5 — How many Names could you name? The projection baseline.
      NamesKnownScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 3,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 6 — What would help most? Multi-select chips, cap 3 → queue rows 3-7.
      // Replaces the aspiration screen (whose "again"/"when I slip" wording
      // presupposed lapse — wrong for an ICP defined by hardship, not by
      // practice level).
      HelpChipsScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 4,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 7 — How much time feels right? NOT a commitment device (founder call).
      DailyTimeScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 5,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 8 — Anything to add? Skippable free text; AI context, and the place a
      // Day-0 depth-diver (who is who converts) can go deep.
      IntakeNoteScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 6,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 9 — THE PAYOFF: the real 7-Name queue + the 8-stamp journey track.
      // Everything above earns this screen; everything below is an ask.
      //
      // It DOES carry a bar — segment `onboardingReelPlanSegment` (founder,
      // 2026-07-29). The screen owns that internally rather than taking it as a
      // parameter, so the one number cannot drift between here and there. It
      // used to be excluded as "a payoff, not a step", which left a single page
      // mid-flow with no bar and a bare chevron instead of the back circle.
      QueuePlanScreen(
        onNext: _next,
        onBack: _back,
        revealedPairNameIds: revealedPairNameIds,
      ),
      // 10 — Rating gate (kept in onboarding, founder call 2026-07-28), placed
      // AFTER the plan so it lands on the payoff rather than before it. No bar
      // — it is a gate, not a step.
      RatingGateScreen(onNext: _next, onBack: _back),
      // 11 — Notifications permission. Wave G swaps the generic bell for the
      // lantern in its `pendingUnlit` — literally "waiting to be lit" — state,
      // plus a preview of the system dialog about to appear.
      NotificationScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 8,
        totalSegments: onboardingReelTotalSegments,
        lanternVariant: true,
      ),
      // 12 — Widget offer (Wave G), moved behind the payoff by Wave H.
      // iOS cannot add a widget programmatically, so the CTA instructs and
      // installs nothing.
      WidgetOfferScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 9,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 13 — Where did you find us? Moved off the emotional peak by Wave H: it
      // used to sit immediately after Ameen, asking the user to do market
      // research for us at the moment they were most open. It cannot be
      // deleted (reel-source capture is the plan's biggest measurement hole),
      // so it sits at the flow's lowest-emotion point instead.
      SourceQuestionScreen(
        onNext: _next,
        onBack: _back,
        progressSegment: 10,
        totalSegments: onboardingReelTotalSegments,
      ),
      // — Deferred signup (W2-E2): value first, account last. —
      // 14 — Name
      NameInputScreen(
        onNext: _next,
        onBack: _back,
        pageIndex: onboardingReelNamePageIndex,
        progressSegment: 11,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 15 — Save progress (sign-up choice)
      SaveProgressScreen(
        onNext: _next,
        onBack: _back,
        onSocialAuthComplete: _skipToReelPostSignup,
        progressSegment: 12,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 16 — Sign-up email
      SignUpEmailScreen(
        onNext: _next,
        onBack: _back,
        pageIndex: onboardingReelEmailPageIndex,
        progressSegment: 13,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 17 — Sign-up password
      SignUpPasswordScreen(
        onNext: _next,
        onBack: _back,
        pageIndex: onboardingReelPasswordPageIndex,
        progressSegment: 14,
        totalSegments: onboardingReelTotalSegments,
      ),
      // 18 — Paywall. ALWAYS the soft onboarding-placement one for this flow
      // (plan §F1.2): a reel user never sees the post-tour hard wall, because
      // they never take the tour, so the hard-flag's empty branch would leave
      // them with no paywall surface at all. W4 replaces this page's contents;
      // its position is already correct.
      OnboardingFinalGate(
        onComplete: _completeOnboarding,
        alwaysShowPaywall: true,
      ),
    ];
  }

  /// Trimmed 20-screen flow (Phase A target, 2026-05-25 trim).
  List<Widget> _trimmedChildren() {
    return [
      // 0 — First check-in hook (gacha overlay fires here, not a separate page).
      FirstCheckinScreen(onNext: _next, onBack: _back),
      // 1 — Name input
      NameInputScreen(onNext: _next, onBack: _back),
      // 2 — Age range
      AgeRangeScreen(onNext: _next, onBack: _back),
      // 3 — Intention
      IntentionScreen(onNext: _next, onBack: _back),
      // 4 — Prayer frequency
      PrayerFrequencyScreen(onNext: _next, onBack: _back),
      // 5 — Familiarity with the 99 Names
      FamiliarityScreen(onNext: _next, onBack: _back),
      // 6 — Dua topics
      DuaTopicsScreen(onNext: _next, onBack: _back),
      // 7 — Daily commitment minutes
      DailyCommitmentScreen(onNext: _next, onBack: _back),
      // 8 — Attribution
      AttributionScreen(onNext: _next, onBack: _back),
      // 9 — Reminder time
      ReminderTimeScreen(onNext: _next, onBack: _back),
      // 10 — Notifications permission
      NotificationScreen(onNext: _next, onBack: _back),
      // 11 — Commitment pact
      CommitmentPactScreen(onNext: _next, onBack: _back),
      // 12 — Social proof (pre-signup)
      SocialProofScreen(onNext: _next, onBack: _back),
      // 13 — Save progress (sign-up choice)
      SaveProgressScreen(
        onNext: _next,
        onBack: _back,
        onSocialAuthComplete: _skipToPostSignup,
      ),
      // 14 — Sign-up email
      SignUpEmailScreen(onNext: _next, onBack: _back),
      // 15 — Sign-up password
      SignUpPasswordScreen(onNext: _next, onBack: _back),
      // — Paywall flow begins. Progress bar hidden on these. —
      // 16 — Generating (loader)
      GeneratingScreen(onNext: _next),
      // 17 — Personalized plan
      PersonalizedPlanScreen(onNext: _next, onBack: _back),
      // 18 — Rating gate
      RatingGateScreen(onNext: _next, onBack: _back),
      // 19 — Paywall
      OnboardingFinalGate(onComplete: _completeOnboarding),
    ];
  }

  /// Legacy 27-screen flow. Retained behind the
  /// `onboarding_trim_enabled=false` app_config flag so we can kill-switch
  /// back without a redeploy. PR-2b will delete this method + the seven
  /// referenced screen files after 7 days stable in prod.
  List<Widget> _legacyChildren() {
    return [
      // 0 — First check-in hook (gacha overlay fires here, not a separate page).
      FirstCheckinScreen(onNext: _next, onBack: _back),
      // 1 — Name input
      NameInputScreen(onNext: _next, onBack: _back),
      // 2 — Age range
      AgeRangeScreen(onNext: _next, onBack: _back),
      // 3 — Intention
      IntentionScreen(onNext: _next, onBack: _back),
      // 4 — Prayer frequency
      PrayerFrequencyScreen(onNext: _next, onBack: _back),
      // 5 — Quran connection
      QuranConnectionScreen(onNext: _next, onBack: _back),
      // 6 — Familiarity with the 99 Names
      FamiliarityScreen(onNext: _next, onBack: _back),
      // 7 — Dua topics
      DuaTopicsScreen(onNext: _next, onBack: _back),
      // 8 — Common emotions
      CommonEmotionsScreen(onNext: _next, onBack: _back),
      // 9 — Aspirations
      AspirationsScreen(onNext: _next, onBack: _back),
      // 10 — Daily commitment minutes
      DailyCommitmentScreen(onNext: _next, onBack: _back),
      // 11 — Attribution
      AttributionScreen(onNext: _next, onBack: _back),
      // 12 — "You're not alone" support interstitial
      StruggleSupportInterstitialScreen(onNext: _next, onBack: _back),
      // 13 — Reminder time
      ReminderTimeScreen(onNext: _next, onBack: _back),
      // 14 — Notifications permission
      NotificationScreen(onNext: _next, onBack: _back),
      // 15 — Commitment pact
      CommitmentPactScreen(onNext: _next, onBack: _back),
      // 16 — Value prop
      ValuePropScreen(onNext: _next, onBack: _back),
      // 17 — Social proof (pre-signup)
      SocialProofScreen(onNext: _next, onBack: _back),
      // 18 — Save progress (sign-up choice)
      SaveProgressScreen(
        onNext: _next,
        onBack: _back,
        onSocialAuthComplete: _skipToEncouragement,
      ),
      // 19 — Sign-up email. The explicit indices fix a latent bug the reel
      // flow's `pageIndex` param exposed: these two compared against the
      // TRIMMED constants (14/15), so neither field ever autofocused in the
      // legacy flow.
      SignUpEmailScreen(
        onNext: _next,
        onBack: _back,
        pageIndex: onboardingLegacyEmailPageIndex,
      ),
      // 20 — Sign-up password
      SignUpPasswordScreen(
        onNext: _next,
        onBack: _back,
        pageIndex: onboardingLegacyPasswordPageIndex,
      ),
      // 21 — Encouragement #2 (social-auth users land here)
      EncouragementScreen(onNext: _next, onBack: _back),
      // — Paywall flow begins. Progress bar hidden on these. —
      // 22 — Generating (loader)
      GeneratingScreen(onNext: _next),
      // 23 — Personalized plan
      PersonalizedPlanScreen(onNext: _next, onBack: _back),
      // 24 — Your Journey
      YourJourneyScreen(onNext: _next, onBack: _back),
      // 25 — Rating gate
      RatingGateScreen(onNext: _next, onBack: _back),
      // 26 — Paywall
      OnboardingFinalGate(onComplete: _completeOnboarding),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(
      onboardingProvider.select((state) => state.currentPage),
    );
    // Watched, not read: the reveal renders whatever the hook resolved, and the
    // hook's commit is what changes it.
    final pairNameIds = ref.watch(
      onboardingProvider.select((state) => state.pairNameIds),
    );
    // …and what the reveal ended up showing, which the plan screen renders.
    final revealedPairNameIds = ref.watch(
      onboardingProvider.select((state) => state.revealedPairNameIds),
    );

    return FutureBuilder<OnboardingFlowKind>(
      future: _flowFuture,
      builder: (context, snapshot) {
        // Optimistic default — reel is the new shipping flow, matching the
        // flag's own `fallback: true`. Cached value resolves synchronously on
        // subsequent launches via AppConfigService.
        final flow = snapshot.data ?? OnboardingFlowKind.reel;
        // Belt-and-braces: keep the field in lockstep with the rendered flow
        // so `_next`/abandonment/nav-guard/paywall triggers (which read `_flow`
        // outside build) never lag the FutureBuilder. Plain assignment — no
        // setState; build is already running.
        _flow = flow;
        final children = switch (flow) {
          OnboardingFlowKind.reel =>
            _reelChildren(pairNameIds, revealedPairNameIds),
          OnboardingFlowKind.trimmed => _trimmedChildren(),
          OnboardingFlowKind.legacy => _legacyChildren(),
        };

        // Re-clamp once the flow resolves: if the user's restored page is
        // past the end of the chosen flow's children, snap them to the last
        // valid page. Defer to the next frame so we don't setState during
        // build. Idempotent — no-op when currentPage is already in bounds.
        //
        // `hasData` is load-bearing. The optimistic default is the REEL flow,
        // which has the SHORTEST page list (13), so clamping on the first
        // unresolved frame would drag a kill-switch returner restored at, say,
        // trimmed page 13 down to 12 — permanently, since the clamp persists —
        // before the flag ever said which flow they are in. This is the same
        // hazard `initState` guards by clamping against the LARGEST max; the
        // difference is that here the answer is one frame away, so we simply
        // wait for it.
        final maxIdx = children.length - 1;
        if (snapshot.hasData && currentPage > maxIdx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(onboardingProvider.notifier).setPage(maxIdx);
            if (_pageController.hasClients) {
              _pageController.jumpToPage(maxIdx);
            }
          });
        }

        // Pages that should NOT resize for keyboard:
        //   trimmed: 0 (first check-in) and 6 (dua topics)
        //   legacy:  0 (first check-in) and 7 (dua topics)
        //   reel:    none — the hook's free-text box has to clear the keyboard,
        //            and every other text-entry page there wants the resize.
        final keepBottomInset = switch (flow) {
          OnboardingFlowKind.reel => true,
          OnboardingFlowKind.trimmed =>
            currentPage != 0 && currentPage != 6,
          OnboardingFlowKind.legacy =>
            currentPage != 0 && currentPage != 7,
        };

        return Scaffold(
          resizeToAvoidBottomInset: keepBottomInset,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: children,
          ),
        );
      },
    );
  }
}

/// The final onboarding page. Its content depends on the hard-paywall-after-tour
/// kill switch, read live from [AppSessionNotifier] (hydrated at sign-up, which
/// happens several pages earlier, so it is resolved by the time the user gets
/// here — and the [ListenableBuilder] re-evaluates if it hydrates late):
///
///   * Flag OFF (rollback / legacy): render the soft [PaywallScreen] exactly as
///     before — this IS the onboarding paywall.
///   * Flag ON (new flow): show NO paywall. Complete onboarding immediately so
///     the router gate takes over (forced tour → hard wall). This is what keeps
///     the new flow from showing TWO paywalls.
///
/// Keeping the decision at the leaf (rather than restructuring the page list)
/// leaves every test-pinned page index untouched.
/// The reel flow (W2-E1) always takes the first branch: see [alwaysShowPaywall].
@visibleForTesting
class OnboardingFinalGate extends ConsumerWidget {
  const OnboardingFinalGate({
    required this.onComplete,
    this.alwaysShowPaywall = false,
    super.key,
  });

  /// `_OnboardingScreenState._completeOnboarding` — idempotent (re-entry
  /// guarded), so the post-frame callback firing on rebuilds is safe.
  final Future<void> Function() onComplete;

  /// Forces the soft onboarding-placement paywall regardless of the
  /// hard-paywall-after-tour flag. Set by the REEL flow, whose users never take
  /// the tour: the flag-ON branch below hands off to a router gate that would
  /// route them straight past every paywall surface, so "no paywall here"
  /// would mean no paywall anywhere. Plan §F1.2 — W4 replaces the contents of
  /// this page, not its position.
  final bool alwaysShowPaywall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        if (alwaysShowPaywall || !session.hardPaywallFlowEnabled) {
          return PaywallScreen(
            placement: PaywallPlacement.onboarding,
            onComplete: onComplete,
          );
        }
        // New flow: skip the soft paywall, hand off to the router gate.
        WidgetsBinding.instance.addPostFrameCallback((_) => onComplete());
        return const ColoredBox(
          color: AppColors.backgroundLight,
          child: Center(child: SakinaLoader()),
        );
      },
    );
  }
}
