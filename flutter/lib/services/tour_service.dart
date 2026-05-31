// This file used to host the per-tab TourKey enum + TourService.shouldShow /
// markSeen / resetAll API, plus TourCopy strings and guidedSequenceActiveProvider.
//
// The interactive guided tour (2026-05-26) replaces all of that with the
// unified OnboardingTourController + OnboardingTourOverlayHost. The single
// remaining external touch point is the win-back push copy below (consumed
// by the OneSignal segment that re-engages users who skipped the tour).
//
// All other tour state — per-step copy, seen flag, step sequencing — lives
// in:
//   - lib/features/tour/models/onboarding_tour_step.dart
//   - lib/features/tour/providers/onboarding_tour_controller.dart

/// Win-back push copy. Referenced by the OneSignal automation that fires
/// for users who skipped the tour AND haven't checked in for 3+ days.
class TourCopy {
  TourCopy._();
  static const winBackPushTitle = 'Want me to show you around?';
  static const winBackPushBody = 'Tap to retake the Sakina tour — 30 seconds.';
}
