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
import '../../quests/providers/quests_provider.dart';

const _prefsKey = 'onboarding_state';

/// Last index in [OnboardingScreen]'s PageView (paywall at index 26).
/// PageView has 27 children; gacha on first_checkin is an overlay, not a page.
const int onboardingLastPageIndex = 26;

class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.intention,
    this.notificationPermissionGranted = false,
    this.demoFeelingInput,
    this.demoCheckinCompleted = false,
    this.isLoadingDemoResult = false,
    this.familiarity,
    this.quranConnection,
    this.attribution = const {},
    this.generateProgress = 0.0,
    this.isSignedUp = false,
    this.authError,
    this.signUpName,
    this.signUpEmail,
    // New in v3:
    this.ageRange,
    this.prayerFrequency,
    this.resonantNameId,
    this.duaTopics = const {},
    this.duaTopicsOther,
    this.commonEmotions = const {},
    this.aspirations = const {},
    this.dailyCommitmentMinutes,
    this.reminderTime,
    this.commitmentAccepted = false,
  });

  final int currentPage;
  final String? intention;
  final bool notificationPermissionGranted;
  final String? demoFeelingInput;
  final bool demoCheckinCompleted;
  final bool isLoadingDemoResult;
  final String? familiarity;
  final String? quranConnection;
  final Set<String> attribution;
  final double generateProgress;
  final bool isSignedUp;
  final String? authError;
  final String? signUpName;
  final String? signUpEmail;
  final String? ageRange;
  final String? prayerFrequency;
  final String? resonantNameId;
  final Set<String> duaTopics;
  final String? duaTopicsOther;
  final Set<String> commonEmotions;
  final Set<String> aspirations;
  final int? dailyCommitmentMinutes;
  final String? reminderTime; // "HH:mm" 24h
  final bool commitmentAccepted;

  OnboardingState copyWith({
    int? currentPage,
    String? intention,
    bool? notificationPermissionGranted,
    String? demoFeelingInput,
    bool? demoCheckinCompleted,
    bool? isLoadingDemoResult,
    String? familiarity,
    String? quranConnection,
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
    String? resonantNameId,
    Set<String>? duaTopics,
    String? duaTopicsOther,
    bool clearDuaTopicsOther = false,
    Set<String>? commonEmotions,
    Set<String>? aspirations,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool? commitmentAccepted,
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
      quranConnection: quranConnection ?? this.quranConnection,
      attribution: attribution ?? this.attribution,
      generateProgress: generateProgress ?? this.generateProgress,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      authError: clearAuthError ? null : (authError ?? this.authError),
      signUpName: clearSignUpName ? null : (signUpName ?? this.signUpName),
      signUpEmail: clearSignUpEmail ? null : (signUpEmail ?? this.signUpEmail),
      ageRange: ageRange ?? this.ageRange,
      prayerFrequency: prayerFrequency ?? this.prayerFrequency,
      resonantNameId: resonantNameId ?? this.resonantNameId,
      duaTopics: duaTopics ?? this.duaTopics,
      duaTopicsOther:
          clearDuaTopicsOther ? null : (duaTopicsOther ?? this.duaTopicsOther),
      commonEmotions: commonEmotions ?? this.commonEmotions,
      aspirations: aspirations ?? this.aspirations,
      dailyCommitmentMinutes:
          dailyCommitmentMinutes ?? this.dailyCommitmentMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      commitmentAccepted: commitmentAccepted ?? this.commitmentAccepted,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 4,
        'currentPage': currentPage,
        'intention': intention,
        'notificationPermissionGranted': notificationPermissionGranted,
        'demoCheckinCompleted': demoCheckinCompleted,
        'familiarity': familiarity,
        'quranConnection': quranConnection,
        'attribution': attribution.toList(),
        'signUpName': signUpName,
        'signUpEmail': signUpEmail,
        'ageRange': ageRange,
        'prayerFrequency': prayerFrequency,
        'resonantNameId': resonantNameId,
        'duaTopics': duaTopics.toList(),
        'duaTopicsOther': duaTopicsOther,
        'commonEmotions': commonEmotions.toList(),
        'aspirations': aspirations.toList(),
        'dailyCommitmentMinutes': dailyCommitmentMinutes,
        'reminderTime': reminderTime,
        'commitmentAccepted': commitmentAccepted,
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    // Spec §5: Sakina has no production users. Any blob with version < 4 is
    // discarded and the user starts fresh.
    final version = json['version'] as int? ?? 0;
    if (version < 4) return const OnboardingState();

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
      quranConnection: json['quranConnection'] as String?,
      attribution: readSet(json['attribution']),
      signUpName: json['signUpName'] as String?,
      signUpEmail: json['signUpEmail'] as String?,
      ageRange: json['ageRange'] as String?,
      prayerFrequency: json['prayerFrequency'] as String?,
      resonantNameId: json['resonantNameId'] as String?,
      duaTopics: readSet(json['duaTopics']),
      duaTopicsOther: json['duaTopicsOther'] as String?,
      commonEmotions: readSet(json['commonEmotions']),
      aspirations: readSet(json['aspirations']),
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

  void setQuranConnection(String quranConnection) {
    state = state.copyWith(quranConnection: quranConnection);
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

  void setResonantNameId(String value) {
    state = state.copyWith(resonantNameId: value);
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

  void toggleCommonEmotion(String emotion) {
    state = state.copyWith(
      commonEmotions: _toggled(state.commonEmotions, emotion),
    );
    _saveToPrefs();
  }

  void toggleAspiration(String aspiration) {
    state = state.copyWith(
      aspirations: _toggled(state.aspirations, aspiration),
    );
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
    const totalDuration = Duration(seconds: 3);
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
        intention: state.intention,
        familiarity: state.familiarity,
        quranConnection: state.quranConnection,
        attribution: state.attribution.toList(),
        ageRange: state.ageRange,
        prayerFrequency: state.prayerFrequency,
        resonantNameId: state.resonantNameId,
        duaTopics: state.duaTopics.toList(),
        duaTopicsOther: state.duaTopicsOther,
        commonEmotions: state.commonEmotions.toList(),
        aspirations: state.aspirations.toList(),
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

    // Flip the server-side onboarding flag now that the user has actually
    // finished onboarding. Doing this earlier (e.g. right after sign-up)
    // causes `requestPermissionIfPreviouslyEnabled` to prompt for push
    // permission before the user reaches the notification screen.
    try {
      await _authService.markOnboardingCompleted();
    } catch (_) {}

    // Re-sync first steps now that user_profiles row exists
    await syncFirstStepsFromSupabase();

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

