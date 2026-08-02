import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/gating_service.dart';
import '../models/onboarding_tour_step.dart';

/// Tour state machine status.
enum TourStatus { idle, active, completed, skipped }

class OnboardingTourState {
  const OnboardingTourState({
    required this.index,
    required this.status,
    this.userName,
    this.variant = TourVariant.slim,
  });

  /// Step index into [steps]. `-1` when idle.
  final int index;

  final TourStatus status;

  /// Resolved display name, used to personalize step copy (`{name}`). Resolved
  /// once at tour start/replay; null until then (copy falls back to no name).
  final String? userName;

  /// Which variant this run is showing. Always slim since the slim-vs-full A/B
  /// concluded (its config key was deleted 2026-07-25); defaults to slim for
  /// idle/synthetic states. The full-variant machinery dies with the tour
  /// post-keep (conversion-refactor deletion ledger).
  final TourVariant variant;

  bool get isActive => status == TourStatus.active;

  /// The active variant's step list.
  List<OnboardingTourStepDef> get steps => tourStepsForVariant(variant);

  /// Returns the current step def, or null if idle/finished.
  OnboardingTourStepDef? get currentStep {
    if (!isActive) return null;
    final variantSteps = steps;
    if (index < 0 || index >= variantSteps.length) return null;
    return variantSteps[index];
  }

  OnboardingTourState copyWith({
    int? index,
    TourStatus? status,
    String? userName,
    TourVariant? variant,
  }) =>
      OnboardingTourState(
        index: index ?? this.index,
        status: status ?? this.status,
        userName: userName ?? this.userName,
        variant: variant ?? this.variant,
      );
}

/// SharedPreferences key prefix for the unified tour-seen flag.
/// Bump the version number to re-trigger the tour for ALL users.
const String _seenFlagPrefix = 'onboarding_tour_v1_seen_';

String onboardingTourSeenFlag(String userId) => '$_seenFlagPrefix$userId';

class OnboardingTourController extends StateNotifier<OnboardingTourState> {
  OnboardingTourController(this._ref)
      : super(const OnboardingTourState(
          index: -1,
          status: TourStatus.idle,
        ));

  final Ref _ref;

  // ---------------------------------------------------------------------------
  // DELETED 2026-07-28 — One Ship W2, plan §F1a.
  //
  // `start()` (the opportunistic launch trigger, called from progress_screen)
  // and `resumeForGate()` (the mandatory-gate trigger, resuming at the persisted
  // step) both lived here. The guided tour cost ~48% of signups and has been
  // removed for everyone, so there is no longer ANY path into
  // `TourStatus.active` from a launch or from the router. `OnboardingStage` has
  // no `tour` branch either, which is what makes the stranding bug class in §F0
  // impossible by construction rather than by guard.
  //
  // `replay()` below survives as a NO-OP. Both of its callers were removed in
  // the same wave (the Settings "Replay app tour" row, and the E5 win-back
  // deep-link action), but the method itself must stay safe-when-called: E5
  // pushes carrying `sakina://settings?action=replay_tour` may already be
  // scheduled in OneSignal automations we cannot retract. See its doc comment.
  // ---------------------------------------------------------------------------

  // `_resolveVariant` / `_recordVariant` went with `start()` + `resumeForGate()`
  // (§F1a): the slim-vs-full A/B concluded long before, and with no way to begin
  // a tour there is no arm left to resolve or stamp onto the `tour_variant`
  // super property. `OnboardingTourState` still defaults to `TourVariant.slim`.

  /// Advances to the next step, or marks the tour completed if at the last.
  /// `via` is recorded in analytics: 'target_tap' | 'continue' | 'back_gesture'
  /// | 'anchor_timeout'.
  Future<void> advance({required String via}) async {
    if (state.status != TourStatus.active) return;
    final currentId = state.currentStep?.id ?? 'unknown';
    _track(AnalyticsEvents.tourStepAdvanced, {
      'step_id': currentId,
      'via': via,
      AnalyticsEvents.propVariant: state.variant.name,
    });

    final next = state.index + 1;
    if (next >= state.steps.length) {
      // Capture the final-step id BEFORE mutating state: once `index` advances
      // to `next` (out of range) `currentStep` is null, so `currentId` (the
      // step the user just completed from) is the true final step.
      final finalStepId = currentId;
      final stepCount = state.steps.length;
      final variantName = state.variant.name;
      // Update state FIRST (synchronously) so listeners/tests observe the new
      // status without waiting on the persistence I/O below.
      state = state.copyWith(index: next, status: TourStatus.completed);
      _track(AnalyticsEvents.tourCompleted, {
        AnalyticsEvents.propVariant: variantName,
        'step_count': stepCount,
        'final_step_id': finalStepId,
      });
      await _markSeen();
      return;
    }
    // The resume cursor (`OnboardingGateService.tourStepIndex`) used to be
    // persisted on every advance so a force-kill mid-tour reopened at the
    // abandoned step. Nothing resumes a tour any more (§F1a deleted
    // `resumeForGate`), so the write and the cursor itself are gone.
    state = state.copyWith(index: next, status: TourStatus.active);
    _trackStepViewed();
  }

  /// Ends the tour mid-flight. Marks seen so it doesn't re-fire.
  Future<void> skip() async {
    if (state.status != TourStatus.active) return;
    final atStep = state.currentStep?.id ?? 'unknown';
    final atIndex = state.index;
    final variantName = state.variant.name;
    await _markSeen();
    state = state.copyWith(status: TourStatus.skipped);
    _track(AnalyticsEvents.tourSkipped, {
      'at_step_id': atStep,
      'step_index': atIndex,
      AnalyticsEvents.propVariant: variantName,
    });
    _setUserProperties({
      'tour_home_skipped_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// **Deliberately inert since F1a (the tour was deleted).**
  ///
  /// This used to set [TourStatus.active] and restart at step 1. With
  /// `OnboardingTourOverlayHost` unmounted there is nothing to render an active
  /// tour — and an active-but-invisible tour is not merely useless, it is
  /// harmful: `shouldDeferCelebrations` keys off `isActive`, and
  /// `app_shell._maybeDrainDeferredCelebrations` bails while it is true. So a
  /// replay would silently swallow every rank-up, quest, achievement and First
  /// Steps celebration for the rest of the session, with no way to clear it
  /// (nothing can advance, skip or complete a tour that has no overlay).
  ///
  /// The Settings row that called this is gone. **This method still cannot be
  /// deleted**, because the E5 win-back deep link
  /// `sakina://settings?action=replay_tour` may already be scheduled inside
  /// OneSignal automations we cannot retract — so the entry point has to be
  /// safe when it fires, not merely unreachable from our own UI.
  ///
  /// Pinned by `onboarding_tour_replay_inert_test.dart`.
  void replay() {
    // Intentionally does nothing. Do not restore an `isActive` state here
    // without first re-mounting an overlay AND re-checking the celebration
    // drain path above.
  }

  Future<void> _markSeen() async {
    // Wrapped in try/catch because Supabase.instance throws if not yet
    // initialized (e.g. in unit tests without a live Supabase client).
    // Marking seen is best-effort; failing here must not break the tour.
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingTourSeenFlag(userId), true);
    } catch (_) {
      // Supabase not initialized or other transient failure. Skip.
    }
  }

  void _trackStepViewed() {
    final step = state.currentStep;
    if (step == null) return;
    _track(AnalyticsEvents.tourStepViewed, {
      'step_id': step.id,
      'step_index': state.index,
      AnalyticsEvents.propVariant: state.variant.name,
    });
  }

  void _track(String event, Map<String, dynamic> props) {
    try {
      final analytics = _ref.read(analyticsProvider);
      analytics.track(event, properties: props.isEmpty ? null : props);
    } catch (_) {
      // Analytics is best-effort. A failure here must not break the tour.
    }
  }

  void _setUserProperties(Map<String, dynamic> props) {
    try {
      _ref.read(analyticsProvider).setUserProperties(props);
    } catch (_) {
      // Analytics is best-effort. A failure here must not break the tour.
    }
  }
}

final onboardingTourControllerProvider =
    StateNotifierProvider<OnboardingTourController, OnboardingTourState>(
  OnboardingTourController.new,
);

/// When `true`, the guided-tour overlay is suppressed: the coachmark is hidden
/// and the anchor-timeout is NOT armed (so the current step cannot auto-skip).
///
/// The app's current top-level route path (`/`, `/collection`, `/duas`, …),
/// published by `AppShell` from `GoRouterState.of(context).uri.path` on every
/// build. The overlay host watches this to advance `navigate`-trigger steps
/// (the bottom-nav tab steps) the instant the user reaches the destination,
/// instead of relying on a pointer `Listener` over the tapped tab icon — which
/// is disposed mid-gesture when the icon swaps to its active variant (Bug 1).
///
/// Null until `AppShell` first builds. Only tab routes (which live under the
/// shell) need to be tracked, because those are the only `navigate` steps.
final tourActiveRouteProvider = StateProvider<String?>((_) => null);

/// Owned by screens that host a multi-screen *inline* flow the tour must wait
/// behind before the next anchor becomes reachable. The Duas "Build a Dua"
/// flow sets this while the loader + the four reader beats are on screen: the
/// `firstRelatedHeart` anchor (tour step 10) only mounts on the final result
/// view (`buildCurrentSection == 4`), which a reading user reaches well after
/// the 60s anchor-timeout would otherwise fire and skip the step. Suppressing
/// keeps step 10 pending until the result view (and its heart) appears, and
/// stops step 11 (the Journal tab beat) from firing while the user is still
/// mid-build. Reset to `false` when the build flow leaves the screen.
final tourSuppressedProvider = StateProvider<bool>((_) => false);
