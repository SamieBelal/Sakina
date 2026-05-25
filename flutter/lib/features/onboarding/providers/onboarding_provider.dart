import 'dart:async';
import 'dart:convert';
import 'dart:ui' show VoidCallback;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_session.dart';
import '../../../services/auth_service.dart';
import '../../../services/launch_gate_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/referral_service.dart';
import '../../../services/user_data_batch_sync_service.dart';
import '../../quests/providers/quests_provider.dart';
import '../../../core/env.dart';

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
///   17 Personalized plan, 18 Rating gate (if env on), 19 Paywall.
const int onboardingLastPageIndex = Env.ratingGateEnabled ? 19 : 18;

/// Legacy 27-screen flow last index. Used when `onboarding_trim_enabled=false`.
const int onboardingLegacyLastPageIndex = Env.ratingGateEnabled ? 26 : 25;

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
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 7,
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
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    // Bumped to 7 with the onboarding-trim refactor (page indices changed,
    // quranConnection / commonEmotions / aspirations fields removed). Old
    // blobs reference page indices that no longer exist after the trim, so
    // they are discarded and the user starts fresh.
    final version = json['version'] as int? ?? 0;
    if (version < 7) return const OnboardingState();

    var currentPage = json['currentPage'] as int? ?? 0;
    currentPage = currentPage.clamp(0, onboardingLastPageIndex);

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
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({OnboardingState? restored, AuthService? authService})
      : _authServiceOverride = authService,
        super(restored ?? const OnboardingState());

  final AuthService? _authServiceOverride;
  AuthService? _authServiceCached;
  AuthService get _authService =>
      _authServiceOverride ?? (_authServiceCached ??= AuthService());

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
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
      );
    } catch (e, stack) {
      // Best-effort — don't block onboarding completion on DB failure, but
      // make the failure audible so the analytics/UX cost is visible.
      debugPrint('[Onboarding] persist quiz answers failed: $e\n$stack');
    }
  }

  Future<void> completeOnboarding(AppSessionNotifier appSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    // Reset the daily launch gate so the new user always sees the day-0
    // DailyLaunchOverlay when they land on the home screen.
    await resetDailyLaunchGate();

    await persistOnboardingToSupabase();

    // Seed the user's first collection card with their starter Name from the
    // first check-in. Idempotent on (user_id, name_id) so re-runs are safe.
    final starterId = state.starterNameId;
    if (starterId != null) {
      try {
        await _authService.seedStarterCard(starterId);
      } catch (e, stack) {
        debugPrint('[Onboarding] seed starter card failed: $e\n$stack');
      }
      // Refresh local card_collection cache so the collection screen shows
      // the seeded bronze immediately. Separate try/catch so a hydration
      // failure isn't misattributed to the seed call above.
      try {
        await hydrateUserDataFromBatchRpc();
      } catch (e, stack) {
        debugPrint(
            '[Onboarding] post-seed user data hydration failed: $e\n$stack');
      }
    }

    // Flip the server-side onboarding flag now that the user has actually
    // finished onboarding. Doing this earlier (e.g. right after sign-up)
    // causes `requestPermissionIfPreviouslyEnabled` to prompt for push
    // permission before the user reaches the notification screen.
    try {
      await _authService.markOnboardingCompleted();
    } catch (_) {}

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
      debugPrint('[Onboarding] referral confirm failed (non-fatal): $e\n$stack');
    }

    // Mark onboarded in the single source of truth
    await appSession.markOnboarded();
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

