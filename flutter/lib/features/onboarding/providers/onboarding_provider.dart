import 'dart:async';
import 'dart:convert';
import 'dart:ui' show VoidCallback;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_session.dart';
import '../../../services/auth_service.dart';
import '../../../services/launch_gate_service.dart';

const _prefsKey = 'onboarding_state';

/// Last index in [OnboardingScreen]'s PageView (paywall). Inclusive range for
/// persisted `currentPage` is `0.._onboardingLastPageIndex`.
const int onboardingLastPageIndex = 18;

class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.intention,
    this.struggles = const {},
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
  });

  final int currentPage;
  final String? intention;
  final Set<String> struggles;
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

  OnboardingState copyWith({
    int? currentPage,
    String? intention,
    Set<String>? struggles,
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
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      intention: intention ?? this.intention,
      struggles: struggles ?? this.struggles,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'version': 2,
        'currentPage': currentPage,
        'intention': intention,
        'struggles': struggles.toList(),
        'notificationPermissionGranted': notificationPermissionGranted,
        'demoCheckinCompleted': demoCheckinCompleted,
        'familiarity': familiarity,
        'quranConnection': quranConnection,
        'attribution': attribution.toList(),
        'signUpName': signUpName,
        'signUpEmail': signUpEmail,
      };

  static OnboardingState fromJson(Map<String, dynamic> json) {
    var currentPage = json['currentPage'] as int? ?? 0;
    if (json['version'] == null && currentPage > 0) {
      currentPage -= 1;
    }
    currentPage = currentPage.clamp(0, onboardingLastPageIndex);
    return OnboardingState(
      currentPage: currentPage,
      intention: json['intention'] as String?,
      struggles: (json['struggles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      notificationPermissionGranted:
          json['notificationPermissionGranted'] as bool? ?? false,
      demoCheckinCompleted: json['demoCheckinCompleted'] as bool? ?? false,
      familiarity: json['familiarity'] as String?,
      quranConnection: json['quranConnection'] as String?,
      attribution: (json['attribution'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      signUpName: json['signUpName'] as String?,
      signUpEmail: json['signUpEmail'] as String?,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({OnboardingState? restored, AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(restored ?? const OnboardingState());

  final AuthService _authService;

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

  void toggleStruggle(String struggle) {
    final updated = Set<String>.from(state.struggles);
    if (updated.contains(struggle)) {
      updated.remove(struggle);
    } else {
      updated.add(struggle);
    }
    state = state.copyWith(struggles: updated);
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

    try {
      await _authService.saveOnboardingData(
        intention: state.intention,
        struggles: state.struggles.toList(),
        familiarity: state.familiarity,
        quranConnection: state.quranConnection,
        attribution: state.attribution.toList(),
      );
    } catch (_) {
      // Best-effort — don't block onboarding completion on DB failure
    }
  }

  Future<void> completeOnboarding(AppSessionNotifier appSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    // Reset the daily launch gate so the new user always sees the day-0
    // DailyLaunchOverlay when they land on the home screen.
    await resetDailyLaunchGate();

    await persistOnboardingToSupabase();

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

