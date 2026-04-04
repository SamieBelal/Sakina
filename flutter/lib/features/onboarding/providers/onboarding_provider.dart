import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  Timer? _generateTimer;

  @override
  void dispose() {
    _generateTimer?.cancel();
    super.dispose();
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void setIntention(String intention) {
    state = state.copyWith(intention: intention);
  }

  void toggleStruggle(String struggle) {
    final updated = Set<String>.from(state.struggles);
    if (updated.contains(struggle)) {
      updated.remove(struggle);
    } else {
      updated.add(struggle);
    }
    state = state.copyWith(struggles: updated);
  }

  void setNotificationPermission(bool granted) {
    state = state.copyWith(notificationPermissionGranted: granted);
  }

  void setDemoFeelingInput(String input) {
    state = state.copyWith(demoFeelingInput: input);
  }

  Future<void> completeDemoCheckin() async {
    state = state.copyWith(isLoadingDemoResult: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isLoadingDemoResult: false,
      demoCheckinCompleted: true,
    );
  }

  void setFamiliarity(String familiarity) {
    state = state.copyWith(familiarity: familiarity);
  }

  void setQuranConnection(String quranConnection) {
    state = state.copyWith(quranConnection: quranConnection);
  }

  void toggleAttribution(String source) {
    final updated = Set<String>.from(state.attribution);
    if (updated.contains(source)) {
      updated.remove(source);
    } else {
      updated.add(source);
    }
    state = state.copyWith(attribution: updated);
  }

  void runGeneratingTheater(VoidCallback onComplete) {
    state = state.copyWith(generateProgress: 0.0);
    const totalDuration = Duration(seconds: 3);
    const tickInterval = Duration(milliseconds: 50);
    final totalTicks = totalDuration.inMilliseconds ~/ tickInterval.inMilliseconds;
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
  }

  void setSignUpEmail(String email) {
    state = state.copyWith(signUpEmail: email);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);

final initialOnboardingCompletedProvider = Provider<bool>((ref) => false);
