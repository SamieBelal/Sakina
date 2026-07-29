// This file used to host the per-tab TourKey enum + TourService.shouldShow /
// markSeen / resetAll API, plus TourCopy strings and guidedSequenceActiveProvider.
//
// The interactive guided tour (2026-05-26) replaced all of that with the
// unified OnboardingTourController + OnboardingTourOverlayHost — and that tour
// was itself DELETED 2026-07-28 (One Ship W2, plan §F1a) after it was measured
// costing ~48% of signups. Nothing in the app can start a tour any more.
//
// What is left below is copy for an EXTERNAL consumer, which is why it did not
// go with the rest: the OneSignal automation that re-engages users who skipped
// the tour still references these strings. Retire the automation, then this
// file (F1b).

/// Win-back push copy. Referenced by the OneSignal automation that fires
/// for users who skipped the tour AND haven't checked in for 3+ days.
///
/// DEAD IN-APP: the deep link it carries (`sakina://settings?action=replay_tour`)
/// now lands on a Settings row whose tour has no overlay to render. Turn the
/// automation off rather than shipping users into a no-op.
class TourCopy {
  TourCopy._();
  static const winBackPushTitle = 'Want me to show you around?';
  static const winBackPushBody = 'Tap to retake the Sakina tour — 30 seconds.';
}
