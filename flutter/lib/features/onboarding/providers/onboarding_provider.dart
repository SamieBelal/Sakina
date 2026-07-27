import 'dart:async';
import 'dart:convert';
import 'dart:ui' show VoidCallback;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_session.dart';
import '../content/aspirations.dart';
import '../content/problem_chips.dart';
import '../../../services/auth_service.dart';
import '../../../services/card_collection_service.dart' show CardTier;
import '../../../services/launch_gate_service.dart';
import '../../../services/name_queue_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/referral_service.dart';
import '../../../services/user_data_batch_sync_service.dart';
import '../../quests/providers/quests_provider.dart';

/// `OnboardingState.onboardingFlow` for the reel flow — also the tour
/// suppression key (Wave F) and the `user_profiles.onboarding_flow` value.
///
/// Aliases [OnboardingFlow], which is where [OnboardingNotifier.setOnboardingFlow]
/// validates from. `AppSessionNotifier` (which the router reads, and which
/// cannot import this direction) keeps its own copy; the two are pinned equal by
/// `test/features/onboarding/complete_onboarding_queue_seed_test.dart` — a drift
/// would suppress the tour for nobody while silently marking every profile
/// `reel_v1`.
const String onboardingFlowReel = OnboardingFlow.reelV1;

/// …and for both fallback flows behind the kill switch.
const String onboardingFlowLegacy = OnboardingFlow.legacy;

const _prefsKey = 'onboarding_state';

/// Last index in [OnboardingScreen]'s trimmed PageView. The legacy 27-screen
/// flow lives behind the `onboarding_trim_enabled` app_config flag (Option α
/// dual-flow strategy from 2026-05-25 eng review).
///   * Trimmed flow: 20 children (0..19), paywall at 19 (when rating gate on).
///   * Legacy flow: 27 children (0..26), paywall at 26 (preserved for rollback).
///
/// Trimmed flow indices:
///   0 First check-in, 1 Name, 2 Age, 3 Intention, 4 Prayer,
///   5 Familiarity, 6 Dua topics, 7 Daily commitment, 8 Attribution,
///   9 Reminder time, 10 Notifications, 11 Commitment pact, 12 Social proof,
///   13 Save progress, 14 Email, 15 Password, 16 Generating,
///   17 Personalized plan, 18 Rating gate, 19 Paywall.
const int onboardingLastPageIndex = 19;

/// Legacy 27-screen flow last index. Used when `onboarding_trim_enabled=false`.
const int onboardingLegacyLastPageIndex = 26;

/// Trimmed-flow sign-up email page index.
const int onboardingEmailPageIndex = 14;

/// Trimmed-flow sign-up password page index.
const int onboardingPasswordPageIndex = 15;

/// Where social-auth (Apple/Google) users land after OAuth succeeds in the
/// trimmed flow. Replaces the old `onboardingEncouragementPageIndex` — the
/// Encouragement interstitial was removed; users go straight to Generating.
const int onboardingPostSignupPageIndex = 16;

/// Legacy flow constants (kept for backwards-compat while dual-flow is live).
const int onboardingLegacyEmailPageIndex = 19;
const int onboardingLegacyPasswordPageIndex = 20;
const int onboardingLegacyEncouragementPageIndex = 21;

class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.intention,
    this.notificationPermissionGranted = false,
    this.demoFeelingInput,
    this.demoCheckinCompleted = false,
    this.isLoadingDemoResult = false,
    this.familiarity,
    this.attribution = const {},
    this.generateProgress = 0.0,
    this.isSignedUp = false,
    this.authError,
    this.signUpName,
    this.signUpEmail,
    // New in v3:
    this.ageRange,
    this.prayerFrequency,
    this.starterNameId,
    this.duaTopics = const {},
    this.duaTopicsOther,
    this.dailyCommitmentMinutes,
    this.reminderTime,
    this.commitmentAccepted = false,
    this.referralApplyFailedReason,
    // New in v8 (One Ship W2 — the reel flow):
    this.contract,
    this.problemCategory,
    this.chipKey,
    this.problemTextRaw,
    this.pairNameIds = const [],
    this.aspiration,
    this.carryingDuration,
    this.reelSource,
    this.reelId,
    this.hookType,
    this.onboardingFlow,
  });

  final int currentPage;
  final String? intention;
  final bool notificationPermissionGranted;
  final String? demoFeelingInput;
  final bool demoCheckinCompleted;
  final bool isLoadingDemoResult;
  final String? familiarity;
  final Set<String> attribution;
  final double generateProgress;
  final bool isSignedUp;
  final String? authError;
  final String? signUpName;
  final String? signUpEmail;
  final String? ageRange;
  final String? prayerFrequency;
  final int? starterNameId;
  final Set<String> duaTopics;
  final String? duaTopicsOther;
  final int? dailyCommitmentMinutes;
  final String? reminderTime; // "HH:mm" 24h
  final bool commitmentAccepted;

  /// One-shot signal set by sign-up callers (Apple/Google in
  /// SaveProgressScreen, email in SignUpPasswordScreen) when `apply_referral`
  /// returns `ok:false` with reason `invalid` or `self_referral`. The
  /// EncouragementScreen drains it on mount and shows a recovery snackbar
  /// pointing the user at Settings → Redeem. Intentionally NOT persisted to
  /// prefs — it's a transient UI signal. The cold-launch defensive retry in
  /// `app_session.dart` does NOT write this flag, so a stale invalid code
  /// can never surface as a snackbar days after onboarding.
  final String? referralApplyFailedReason;

  // ---- v8: the reel flow's hook + arrival record -------------------------
  // All of these are written pre-auth and must survive an app kill mid-flow,
  // so every one of them round-trips through prefs (deferred signup, W2-E2).

  /// [HookContract.problem] or [HookContract.sign] — what the hook promised.
  final String? contract;

  /// Stable snake_case category behind the chosen chip, or `unmatched`.
  final String? problemCategory;

  /// The taxonomy chip key (`anxiety`, `far-from-allah`, …). Null when free
  /// text matched nothing — the comfort pair still reveals, but no chip is
  /// claimed on the user's behalf.
  final String? chipKey;

  /// Verbatim free text → `user_profiles.first_problem_text`.
  final String? problemTextRaw;

  /// `[name₁, name₂]` resolved from the approved decks at hook time. Persisted
  /// so an app kill after the reveal resumes with the SAME Names.
  final List<int> pairNameIds;

  /// Wave D's aspiration answer (drives queue rows 3-7 in W2-C2).
  final String? aspiration;

  /// "How long have you been carrying this?" — pacing + AI context.
  final String? carryingDuration;

  /// Post-reveal "Where did you find us?" answer.
  final String? reelSource;

  /// Reel id captured from a `sakina://reel/<id>` deep link.
  final String? reelId;

  /// [HookType.chip], [HookType.freeText] or [HookType.reel].
  final String? hookType;

  /// `reel_v1` | `legacy` — which onboarding EXPERIENCE ran. Set at flow entry
  /// (W2-E1) and mirrored into `user_profiles.onboarding_flow`; also the tour
  /// suppression key.
  final String? onboardingFlow;

  /// The `acquisition_promise` jsonb payload, or null when the hook has not
  /// been answered yet.
  ///
  /// `contract` is mandatory — the column carries a check constraint requiring
  /// it. `contract` and `hookType` are always written together by
  /// [OnboardingNotifier.applyHookSelection]; if either is somehow missing we
  /// emit nothing rather than guess an arrival story.
  Map<String, dynamic>? get acquisitionPromise {
    final c = contract;
    final h = hookType;
    if (c == null || h == null) return null;
    return {
      if (reelId != null) 'reel_id': reelId,
      'hook_type': h,
      'contract': c,
      if (problemCategory != null) 'problem_category': problemCategory,
    };
  }

  OnboardingState copyWith({
    int? currentPage,
    String? intention,
    bool? notificationPermissionGranted,
    String? demoFeelingInput,
    bool? demoCheckinCompleted,
    bool? isLoadingDemoResult,
    String? familiarity,
    Set<String>? attribution,
    double? generateProgress,
    bool? isSignedUp,
    String? authError,
    bool clearAuthError = false,
    String? signUpName,
    bool clearSignUpName = false,
    String? signUpEmail,
    bool clearSignUpEmail = false,
    String? ageRange,
    String? prayerFrequency,
    int? starterNameId,
    Set<String>? duaTopics,
    String? duaTopicsOther,
    bool clearDuaTopicsOther = false,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool? commitmentAccepted,
    String? referralApplyFailedReason,
    bool clearReferralApplyFailedReason = false,
    String? contract,
    String? problemCategory,
    String? chipKey,
    bool clearChipKey = false,
    String? problemTextRaw,
    bool clearProblemTextRaw = false,
    List<int>? pairNameIds,
    String? aspiration,
    String? carryingDuration,
    String? reelSource,
    String? reelId,
    String? hookType,
    String? onboardingFlow,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      intention: intention ?? this.intention,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      demoFeelingInput: demoFeelingInput ?? this.demoFeelingInput,
      demoCheckinCompleted: demoCheckinCompleted ?? this.demoCheckinCompleted,
      isLoadingDemoResult: isLoadingDemoResult ?? this.isLoadingDemoResult,
      familiarity: familiarity ?? this.familiarity,
      attribution: attribution ?? this.attribution,
      generateProgress: generateProgress ?? this.generateProgress,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      authError: clearAuthError ? null : (authError ?? this.authError),
      signUpName: clearSignUpName ? null : (signUpName ?? this.signUpName),
      signUpEmail: clearSignUpEmail ? null : (signUpEmail ?? this.signUpEmail),
      ageRange: ageRange ?? this.ageRange,
      prayerFrequency: prayerFrequency ?? this.prayerFrequency,
      starterNameId: starterNameId ?? this.starterNameId,
      duaTopics: duaTopics ?? this.duaTopics,
      duaTopicsOther:
          clearDuaTopicsOther ? null : (duaTopicsOther ?? this.duaTopicsOther),
      dailyCommitmentMinutes:
          dailyCommitmentMinutes ?? this.dailyCommitmentMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      commitmentAccepted: commitmentAccepted ?? this.commitmentAccepted,
      referralApplyFailedReason: clearReferralApplyFailedReason
          ? null
          : (referralApplyFailedReason ?? this.referralApplyFailedReason),
      contract: contract ?? this.contract,
      problemCategory: problemCategory ?? this.problemCategory,
      // Explicit clears: re-answering the hook with unmatched free text must
      // be able to erase a chip key / typed sentence from an earlier answer.
      chipKey: clearChipKey ? null : (chipKey ?? this.chipKey),
      problemTextRaw:
          clearProblemTextRaw ? null : (problemTextRaw ?? this.problemTextRaw),
      pairNameIds: pairNameIds ?? this.pairNameIds,
      aspiration: aspiration ?? this.aspiration,
      carryingDuration: carryingDuration ?? this.carryingDuration,
      reelSource: reelSource ?? this.reelSource,
      reelId: reelId ?? this.reelId,
      hookType: hookType ?? this.hookType,
      onboardingFlow: onboardingFlow ?? this.onboardingFlow,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 8,
        'currentPage': currentPage,
        'intention': intention,
        'notificationPermissionGranted': notificationPermissionGranted,
        'demoCheckinCompleted': demoCheckinCompleted,
        'familiarity': familiarity,
        'attribution': attribution.toList(),
        'signUpName': signUpName,
        'signUpEmail': signUpEmail,
        'ageRange': ageRange,
        'prayerFrequency': prayerFrequency,
        'starterNameId': starterNameId,
        'duaTopics': duaTopics.toList(),
        'duaTopicsOther': duaTopicsOther,
        'dailyCommitmentMinutes': dailyCommitmentMinutes,
        'reminderTime': reminderTime,
        'commitmentAccepted': commitmentAccepted,
        'contract': contract,
        'problemCategory': problemCategory,
        'chipKey': chipKey,
        'problemTextRaw': problemTextRaw,
        'pairNameIds': pairNameIds,
        'aspiration': aspiration,
        'carryingDuration': carryingDuration,
        'reelSource': reelSource,
        'reelId': reelId,
        'hookType': hookType,
        'onboardingFlow': onboardingFlow,
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    // Bumped to 8 with the One Ship reel flow (W2): the page order changed
    // again and the hook fields are new. A v7 blob describes a flow whose page
    // indices no longer mean the same thing, so it is discarded and the user
    // starts fresh — intended, and the same call the trim refactor made when
    // it bumped 6 → 7.
    final version = json['version'] as int? ?? 0;
    if (version < 8) return const OnboardingState();

    var currentPage = json['currentPage'] as int? ?? 0;
    // Preserve rollback-path pages until OnboardingScreen resolves the
    // server-driven flow flag. Trimmed mode re-clamps after resolution.
    currentPage = currentPage.clamp(0, onboardingLegacyLastPageIndex);

    Set<String> readSet(dynamic raw) =>
        (raw as List<dynamic>?)?.map((e) => e as String).toSet() ?? const {};

    return OnboardingState(
      currentPage: currentPage,
      intention: json['intention'] as String?,
      notificationPermissionGranted:
          json['notificationPermissionGranted'] as bool? ?? false,
      demoCheckinCompleted: json['demoCheckinCompleted'] as bool? ?? false,
      familiarity: json['familiarity'] as String?,
      attribution: readSet(json['attribution']),
      signUpName: json['signUpName'] as String?,
      signUpEmail: json['signUpEmail'] as String?,
      ageRange: json['ageRange'] as String?,
      prayerFrequency: json['prayerFrequency'] as String?,
      starterNameId: (json['starterNameId'] as num?)?.toInt(),
      duaTopics: readSet(json['duaTopics']),
      duaTopicsOther: json['duaTopicsOther'] as String?,
      dailyCommitmentMinutes: json['dailyCommitmentMinutes'] as int?,
      reminderTime: json['reminderTime'] as String?,
      commitmentAccepted: json['commitmentAccepted'] as bool? ?? false,
      contract: json['contract'] as String?,
      problemCategory: json['problemCategory'] as String?,
      chipKey: json['chipKey'] as String?,
      problemTextRaw: json['problemTextRaw'] as String?,
      pairNameIds: (json['pairNameIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const [],
      aspiration: json['aspiration'] as String?,
      carryingDuration: json['carryingDuration'] as String?,
      reelSource: json['reelSource'] as String?,
      reelId: json['reelId'] as String?,
      hookType: json['hookType'] as String?,
      onboardingFlow: json['onboardingFlow'] as String?,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    OnboardingState? restored,
    AuthService? authService,
    NameQueueService? nameQueueService,
    ProblemChipResolver? chipResolver,
  })  : _authServiceOverride = authService,
        _nameQueueOverride = nameQueueService,
        _chipResolverOverride = chipResolver,
        super(restored ?? const OnboardingState());

  final AuthService? _authServiceOverride;
  AuthService? _authServiceCached;
  AuthService get _authService =>
      _authServiceOverride ?? (_authServiceCached ??= AuthService());

  final NameQueueService? _nameQueueOverride;
  NameQueueService? _nameQueueCached;
  NameQueueService get _nameQueue =>
      _nameQueueOverride ?? (_nameQueueCached ??= NameQueueService());

  final ProblemChipResolver? _chipResolverOverride;
  ProblemChipResolver? _chipResolverCached;
  ProblemChipResolver get _chipResolver =>
      _chipResolverOverride ?? (_chipResolverCached ??= ProblemChipResolver());

  Timer? _generateTimer;

  @override
  void dispose() {
    _generateTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  static Future<OnboardingState?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    try {
      return OnboardingState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    _saveToPrefs();
  }

  void setIntention(String intention) {
    state = state.copyWith(intention: intention);
    _saveToPrefs();
  }

  void setNotificationPermission(bool granted) {
    state = state.copyWith(notificationPermissionGranted: granted);
    _saveToPrefs();
  }

  void setDemoFeelingInput(String input) {
    state = state.copyWith(demoFeelingInput: input);
    _saveToPrefs();
  }

  Future<void> completeDemoCheckin() async {
    state = state.copyWith(isLoadingDemoResult: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isLoadingDemoResult: false,
      demoCheckinCompleted: true,
    );
    _saveToPrefs();
  }

  void setFamiliarity(String familiarity) {
    state = state.copyWith(familiarity: familiarity);
    _saveToPrefs();
  }

  void toggleAttribution(String source) {
    final updated = Set<String>.from(state.attribution);
    if (updated.contains(source)) {
      updated.remove(source);
    } else {
      updated.add(source);
    }
    state = state.copyWith(attribution: updated);
    _saveToPrefs();
  }

  void setAgeRange(String value) {
    state = state.copyWith(ageRange: value);
    _saveToPrefs();
  }

  void setPrayerFrequency(String value) {
    state = state.copyWith(prayerFrequency: value);
    _saveToPrefs();
  }

  void setStarterName(int catalogId) {
    state = state.copyWith(starterNameId: catalogId);
    _saveToPrefs();
  }

  /// Commit the hook screen's answer (W2-B2 → B3).
  ///
  /// One write for the whole promise so `contract`, `hookType` and the pair can
  /// never be persisted half-applied — [OnboardingState.acquisitionPromise]
  /// depends on that invariant.
  ///
  /// `hook_type` records ARRIVAL ORIGIN, so an existing [HookType.reel] survives
  /// this call: a reel visitor answers the hook screen like everyone else, and
  /// overwriting them as `chip` would make [HookType.reel] unreachable in the
  /// data and erase the only marker that the reel sent them.
  void applyHookSelection(ChipSelection selection) {
    final origin =
        state.hookType == HookType.reel ? HookType.reel : selection.hookType;
    state = state.copyWith(
      contract: selection.contract,
      problemCategory: selection.problemCategory,
      hookType: origin,
      pairNameIds: selection.pairNameIds,
      chipKey: selection.chipKey,
      clearChipKey: selection.chipKey == null,
      problemTextRaw: selection.problemTextRaw,
      clearProblemTextRaw: selection.problemTextRaw == null,
    );
    _saveToPrefs();
  }

  void setCarryingDuration(String value) {
    state = state.copyWith(carryingDuration: value);
    _saveToPrefs();
  }

  void setAspiration(String value) {
    state = state.copyWith(aspiration: value);
    _saveToPrefs();
  }

  void setReelSource(String value) {
    state = state.copyWith(reelSource: value);
    _saveToPrefs();
  }

  /// Stamped from a `sakina://reel/<id>` deep link before the hook renders.
  void setReelArrival({required String reelId}) {
    state = state.copyWith(reelId: reelId, hookType: HookType.reel);
    _saveToPrefs();
  }

  /// `reel_v1` | `legacy`, decided at flow entry (W2-E1).
  ///
  /// Throws rather than asserts on an unknown value: the column is the tour
  /// suppression key and the flow dimension every W2 readout segments on, so a
  /// typo that only fails in debug would ship as silently mis-segmented data.
  void setOnboardingFlow(String flow) {
    if (!OnboardingFlow.values.contains(flow)) {
      throw ArgumentError.value(
        flow,
        'flow',
        'not an onboarding flow (${OnboardingFlow.values.join(' | ')})',
      );
    }
    state = state.copyWith(onboardingFlow: flow);
    _saveToPrefs();
  }

  Set<String> _toggled(Set<String> src, String v) =>
      src.contains(v) ? (Set.of(src)..remove(v)) : (Set.of(src)..add(v));

  void toggleDuaTopic(String topic) {
    state = state.copyWith(duaTopics: _toggled(state.duaTopics, topic));
    _saveToPrefs();
  }

  void setDuaTopicsOther(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      state = state.copyWith(clearDuaTopicsOther: true);
    } else {
      // Spec §5: 280-grapheme cap on free text (use user-perceived characters
      // so emoji and Arabic ligatures aren't split mid-code-unit).
      final chars = trimmed.characters;
      state = state.copyWith(
        duaTopicsOther:
            chars.length > 280 ? chars.take(280).toString() : trimmed,
      );
    }
    _saveToPrefs();
  }

  void setDailyCommitmentMinutes(int minutes) {
    state = state.copyWith(dailyCommitmentMinutes: minutes);
    _saveToPrefs();
  }

  void setReminderTime(String hhmm) {
    state = state.copyWith(reminderTime: hhmm);
    _saveToPrefs();
  }

  void setCommitmentAccepted(bool accepted) {
    state = state.copyWith(commitmentAccepted: accepted);
    _saveToPrefs();
  }

  void runGeneratingTheater(VoidCallback onComplete) {
    state = state.copyWith(generateProgress: 0.0);
    // 3.5s total — gives the 4th step (threshold 0.70) room to render its active
    // state for ~30% of the timeline before auto-advance.
    const totalDuration = Duration(milliseconds: 3500);
    const tickInterval = Duration(milliseconds: 50);
    final totalTicks =
        totalDuration.inMilliseconds ~/ tickInterval.inMilliseconds;
    var currentTick = 0;

    _generateTimer?.cancel();
    _generateTimer = Timer.periodic(tickInterval, (timer) {
      currentTick++;
      final progress = currentTick / totalTicks;
      state = state.copyWith(generateProgress: progress.clamp(0.0, 1.0));

      if (currentTick >= totalTicks) {
        timer.cancel();
        _generateTimer = null;
        onComplete();
      }
    });
  }

  /// Reset all onboarding state back to defaults (page 0, no selections).
  /// Call this on sign-out or account deletion so a returning user starts fresh.
  void reset() {
    _generateTimer?.cancel();
    _generateTimer = null;
    state = const OnboardingState();
    _saveToPrefs();
  }

  void setSignedUp(bool value) {
    state = state.copyWith(isSignedUp: value);
  }

  void setAuthError(String? error) {
    if (error == null) {
      state = state.copyWith(clearAuthError: true);
    } else {
      state = state.copyWith(authError: error);
    }
  }

  void clearAuthError() {
    state = state.copyWith(clearAuthError: true);
  }

  /// Set when the post-signup `apply_referral` call returns `ok:false` with
  /// reason `invalid` or `self_referral`. Read once by EncouragementScreen
  /// and cleared via [clearReferralApplyFailedReason] so re-mounts don't
  /// double-fire the snackbar.
  void setReferralApplyFailedReason(String reason) {
    state = state.copyWith(referralApplyFailedReason: reason);
  }

  void clearReferralApplyFailedReason() {
    state = state.copyWith(clearReferralApplyFailedReason: true);
  }

  void setSignUpName(String name) {
    state = state.copyWith(signUpName: name);
    _saveToPrefs();
  }

  void setSignUpEmail(String email) {
    state = state.copyWith(signUpEmail: email);
    _saveToPrefs();
  }

  Future<void> persistOnboardingToSupabase() async {
    // Asked through the service (which owns the Supabase handle) rather than
    // reading `Supabase.instance` here, so the completion chain can be driven
    // in a unit test without a live client.
    if (!_authService.isSignedIn) return;
    await _persistQuizAnswers();
  }

  /// Test-only.
  @visibleForTesting
  Future<void> debugPersistOnboardingForTest() => _persistQuizAnswers();

  Future<void> _persistQuizAnswers() async {
    try {
      await _authService.saveOnboardingData(
        displayName: state.signUpName,
        intention: state.intention,
        familiarity: state.familiarity,
        attribution: state.attribution.toList(),
        ageRange: state.ageRange,
        prayerFrequency: state.prayerFrequency,
        starterNameId: state.starterNameId,
        duaTopics: state.duaTopics.toList(),
        duaTopicsOther: state.duaTopicsOther,
        dailyCommitmentMinutes: state.dailyCommitmentMinutes,
        reminderTime: state.reminderTime,
        commitmentAccepted: state.commitmentAccepted,
        // W1 columns — they ride EVERY persist, including the final one, so
        // they are already written when `onboarding_completed` freezes them.
        acquisitionPromise: state.acquisitionPromise,
        firstProblemText: state.problemTextRaw,
        onboardingFlow: state.onboardingFlow,
      );
    } catch (e, stack) {
      // Best-effort — don't block onboarding completion on DB failure, but
      // make the failure audible so the analytics/UX cost is visible.
      debugPrint('[Onboarding] persist quiz answers failed: $e\n$stack');
    }
  }

  /// The 7 ids `seed_name_queue` is called with: the hook's pair at positions
  /// 1-2, then the aspiration answer's five at 3-7.
  ///
  /// Empty for anything but the reel flow — the queue IS the reel flow's
  /// acquisition promise, and a kill-switch user who never saw a hook screen
  /// must not be handed one. Within the reel flow it falls back to the comfort
  /// pair when the state carries no resolved pair (the same fallback the hook
  /// screen uses), and to a two-row queue when the aspiration is unanswered —
  /// the RPC accepts 2-7 ids, and inventing an ordering would ship unreviewed
  /// content. Empty means "don't seed", never "seed junk".
  @visibleForTesting
  Future<List<int>> buildQueueNameIds() async {
    if (state.onboardingFlow != onboardingFlowReel) return const [];
    var pair = state.pairNameIds;
    if (pair.length != 2) {
      pair = await _chipResolver.pairNameIdsForChip(comfortChipKey);
    }
    if (pair.length != 2) return const [];
    return [...pair, ...aspirationQueueNameIds(state.aspiration)];
  }

  Future<void> completeOnboarding(AppSessionNotifier appSession) async {
    // Reset the daily launch gate so the new user always sees the day-0
    // DailyLaunchOverlay when they land on the home screen.
    await resetDailyLaunchGate();

    await persistOnboardingToSupabase();

    // Seed the user's first collection card with the Name they met. The reel
    // flow's reveal SHOWS a Silver card (W2-C1, deterministic), so it persists
    // Silver; every other flow keeps the legacy Bronze. Idempotent on
    // (user_id, name_id) — a re-run clamps rather than increments.
    final starterId = state.starterNameId ??
        (state.pairNameIds.isNotEmpty ? state.pairNameIds.first : null);
    if (starterId != null) {
      try {
        await _authService.seedStarterCard(
          starterId,
          tier: state.onboardingFlow == onboardingFlowReel
              ? CardTier.silver
              : CardTier.bronze,
        );
      } catch (e, stack) {
        debugPrint('[Onboarding] seed starter card failed: $e\n$stack');
      }
      // Refresh local card_collection cache so the collection screen shows
      // the seeded card immediately. Separate try/catch so a hydration
      // failure isn't misattributed to the seed call above.
      try {
        await hydrateUserDataFromBatchRpc();
      } catch (e, stack) {
        debugPrint(
            '[Onboarding] post-seed user data hydration failed: $e\n$stack');
      }
    }

    // Seed the 7-Name queue — needs auth, so it runs after the persist, and
    // before the completion flag so the promise exists by the time the user is
    // "onboarded". `seedIfEmpty` pre-checks with an RLS select and never
    // swallows a raise (the RPC's errcode can't distinguish "already seeded"
    // from a wholesale failure), so a genuine failure lands here loudly rather
    // than leaving a silently dead W3 unseal. It must not abort the rest of
    // completion, though: the caller in onboarding_screen swallows throws, and
    // an escape here would skip markOnboardingCompleted + markOnboarded.
    final queueIds = await buildQueueNameIds();
    if (queueIds.length >= 2) {
      try {
        await _nameQueue.seedIfEmpty(queueIds);
      } catch (e, stack) {
        debugPrint('[Onboarding] name-queue seed FAILED — the daily unseal '
            'will have nothing to open: $e\n$stack');
      }
    }

    // Flip the server-side onboarding flag now that the user has actually
    // finished onboarding. Doing this earlier (e.g. right after sign-up)
    // causes `requestPermissionIfPreviouslyEnabled` to prompt for push
    // permission before the user reaches the notification screen.
    try {
      await _authService.markOnboardingCompleted();
    } catch (_) {}

    // Only NOW drop the local onboarding state. Wiping it first (as this did
    // until W2-C2) meant a crash anywhere above restarted onboarding from a
    // blank slate — a fresh Name₁ resolved against a queue the server had
    // already frozen, and a `first_problem_text` the freeze trigger would
    // reject. Losing the wipe to a crash is the cheap failure: the next run
    // re-persists the same answers idempotently.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    // Re-sync first steps now that user_profiles row exists
    await syncFirstStepsFromSupabase();

    // Refer-to-Unlock confirm hook: if this user was referred, flip their
    // referrals row pending → confirmed. The SQL RPC handles the 30d grant
    // for the referrer atomically when the 3-confirmed threshold is crossed.
    // Wrapped in try/catch — must NEVER block onboarding completion. The
    // post-RPC refreshReferralPremiumCache surfaces any new window the
    // referee earned to PurchaseService.isPremium().
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null && uid.isNotEmpty) {
        await ReferralService(Supabase.instance.client)
            .confirmReferralIfPending(uid);
        // Also refresh for the referee branch — in case their own 7d window
        // was granted earlier via apply_referral but the cache hasn't been
        // populated yet on this device.
        await PurchaseService().refreshReferralPremiumCache();
        // And the Sakina Gift cache — if the user pre-claimed on another
        // device, restore that entitlement immediately on this one.
        await PurchaseService().refreshGiftPremiumCache();
      }
    } catch (e, stack) {
      debugPrint(
          '[Onboarding] referral confirm failed (non-fatal): $e\n$stack');
    }

    // Mark onboarded in the single source of truth
    await appSession.markOnboarded();

    // Put the new user INTO the hard-paywall gate by writing the local
    // paywall-cleared latch = false NOW, so the router enforces tour → wall
    // immediately and deterministically — without depending on the async
    // batch-sync hydrate winning the race against the first redirect / the
    // one-shot tour-start in progress_screen (the cold-launch race two
    // reviewers flagged). Flag-gated: a user who onboards while the kill
    // switch is OFF must stay grandfathered if it later flips ON, so we only
    // set the latch when the gate is actually active.
    if (appSession.hardPaywallFlowEnabled) {
      await appSession.enterOnboardingGate();
    }
  }
}

final cachedOnboardingStateProvider = Provider<OnboardingState?>((ref) => null);

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(
    restored: ref.read(cachedOnboardingStateProvider),
    authService: ref.read(authServiceProvider),
  ),
);
