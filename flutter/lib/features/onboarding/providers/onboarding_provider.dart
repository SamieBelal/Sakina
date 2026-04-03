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
  });

  final int currentPage;
  final String? intention;
  final Set<String> struggles;
  final bool notificationPermissionGranted;
  final String? demoFeelingInput;
  final bool demoCheckinCompleted;
  final bool isLoadingDemoResult;

  OnboardingState copyWith({
    int? currentPage,
    String? intention,
    Set<String>? struggles,
    bool? notificationPermissionGranted,
    String? demoFeelingInput,
    bool? demoCheckinCompleted,
    bool? isLoadingDemoResult,
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
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

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
