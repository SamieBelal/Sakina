import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/daily/providers/daily_loop_provider.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/app_config_service.dart';
import '../../../services/gating_service.dart';
import '../models/onboarding_tour_step.dart';

/// Tour state machine status.
enum TourStatus { idle, active, completed, skipped }

class OnboardingTourState {
  const OnboardingTourState({
    required this.index,
    required this.status,
    this.userName,
  });

  /// Step index into [kOnboardingTourSteps]. `-1` when idle.
  final int index;

  final TourStatus status;

  /// Resolved display name, used to personalize step copy (`{name}`). Resolved
  /// once at tour start/replay; null until then (copy falls back to no name).
  final String? userName;

  bool get isActive => status == TourStatus.active;

  /// Returns the current step def, or null if idle/finished.
  OnboardingTourStepDef? get currentStep {
    if (!isActive) return null;
    if (index < 0 || index >= kOnboardingTourSteps.length) return null;
    return kOnboardingTourSteps[index];
  }

  OnboardingTourState copyWith({int? index, TourStatus? status, String? userName}) =>
      OnboardingTourState(
        index: index ?? this.index,
        status: status ?? this.status,
        userName: userName ?? this.userName,
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

  /// Attempts to start the tour. No-op when:
  ///   - no auth user
  ///   - tour already seen (per-user SharedPreferences flag)
  ///   - daily loop never loaded (cold-offline) — does NOT mark seen, retries
  ///   - user has already checked in today (would route step 1 to the gated
  ///     25-token "Seek Another Name" CTA instead of "Begin Muḥāsabah").
  ///     Marks seen so we don't retry every launch.
  Future<void> start() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (state.status != TourStatus.idle) return;

    final prefs = await SharedPreferences.getInstance();
    final flag = onboardingTourSeenFlag(userId);
    if (prefs.getBool(flag) ?? false) return;

    // Wait briefly for dailyLoopProvider to load. Avoids reading the initial
    // empty state at cold launch (where checkinDone is falsely false and
    // we'd fire the tour for a user who actually already checked in).
    for (var i = 0; i < 20; i++) {
      if (_ref.read(dailyLoopProvider).loaded) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final daily = _ref.read(dailyLoopProvider);
    if (!daily.loaded) {
      // Never loaded — cold-offline. Skip this launch, do NOT mark seen.
      return;
    }

    if (daily.checkinDone) {
      await prefs.setBool(flag, true);
      return;
    }

    // Server kill switch. Read AFTER the daily-loop gate so a disabled tour
    // never short-circuits the cold-offline retry. We do NOT mark the tour
    // seen here — if the flag is flipped back on, the tour should still fire
    // for users who never saw it. Falls back to enabled (fail-open) to match
    // `onboarding_trim_enabled`'s posture in AppConfigService.
    final tourEnabled = await _ref
        .read(appConfigServiceProvider)
        .getBool('guided_tour_enabled', fallback: true);
    if (!tourEnabled) {
      _track(AnalyticsEvents.tourStartSkipped, const {'reason': 'disabled'});
      return;
    }

    state = OnboardingTourState(
      index: 0,
      status: TourStatus.active,
      userName: await _resolveUserName(),
    );
    _track(AnalyticsEvents.tourStarted, const {});
    _trackStepViewed();
  }

  /// Resolves the display name for personalized copy. `GatingService` already
  /// falls back to "Friend" when no name is saved, so this is non-empty in
  /// practice; null only on an unexpected failure.
  Future<String?> _resolveUserName() async {
    try {
      final name = (await GatingService().displayName()).trim();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Advances to the next step, or marks the tour completed if at the last.
  /// `via` is recorded in analytics: 'target_tap' | 'continue' | 'back_gesture'
  /// | 'anchor_timeout'.
  Future<void> advance({required String via}) async {
    if (state.status != TourStatus.active) return;
    final currentId = state.currentStep?.id ?? 'unknown';
    _track(AnalyticsEvents.tourStepAdvanced, {
      'step_id': currentId,
      'via': via,
    });

    final next = state.index + 1;
    if (next >= kOnboardingTourSteps.length) {
      await _markSeen();
      state = state.copyWith(index: next, status: TourStatus.completed);
      _track(AnalyticsEvents.tourCompleted, const {});
      return;
    }
    state = state.copyWith(index: next, status: TourStatus.active);
    _trackStepViewed();
  }

  /// Ends the tour mid-flight. Marks seen so it doesn't re-fire.
  Future<void> skip() async {
    if (state.status != TourStatus.active) return;
    final atStep = state.currentStep?.id ?? 'unknown';
    await _markSeen();
    state = state.copyWith(status: TourStatus.skipped);
    _track(AnalyticsEvents.tourSkipped, {'at_step_id': atStep});
    _setUserProperties({
      'tour_home_skipped_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Reset + restart at step 1. Called from Settings "Replay app tour".
  /// Caller MUST clear the seen flag before calling this so a subsequent
  /// natural launch doesn't re-fire on top of the replay.
  void replay() {
    // Set active synchronously (callers don't await; tests assert immediately)
    // reusing any name already resolved, then refresh the name in the
    // background so the first banner can interpolate it.
    state = OnboardingTourState(
      index: 0,
      status: TourStatus.active,
      userName: state.userName,
    );
    _track(AnalyticsEvents.tourStarted, const {'via': 'replay'});
    _trackStepViewed();
    _resolveUserName().then((name) {
      if (name != null && state.isActive && state.index == 0) {
        state = state.copyWith(userName: name);
      }
    });
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
