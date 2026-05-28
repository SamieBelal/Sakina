import 'package:flutter/foundation.dart';

/// Logical surface where a tour anchor lives. Used to namespace anchor IDs
/// so the same `anchorId` string can exist on multiple screens without
/// colliding in the registry.
///
/// `appShell` is special: the 5 bottom-nav tab icons live in `AppShell` and
/// are visible on whatever tab the user is currently on. Tour steps that
/// target a tab use `surface: TourSurface.appShell` regardless of which
/// screen the user happens to be standing on.
enum TourSurface {
  home,
  muhasabah,
  collection,
  duas,
  reflect,
  journal,
  duaDetail,
  appShell,
}

@immutable
class OnboardingTourStepDef {
  const OnboardingTourStepDef({
    required this.id,
    required this.surface,
    required this.anchorId,
    required this.message,
    required this.interactive,
    this.tooltipBelow = true,
    this.hint,
    this.cutoutPaddingTop = 0,
  });

  /// Stable identifier for analytics. Format: `<surface>.<short-name>`.
  final String id;

  /// Which screen owns the anchor.
  final TourSurface surface;

  /// Identifier within the surface. e.g. `beginMuhasabahCta`, `goDeeperCta`.
  final String anchorId;

  /// Body copy shown in the tooltip. Keep ≤ 14 words.
  final String message;

  /// True = tour advances when the user taps the highlighted target (cutout
  /// is tap-through). False = tooltip shows a Continue button (teach moment).
  final bool interactive;

  /// Preferred tooltip placement. Overlay flips automatically if the
  /// preferred side doesn't fit.
  final bool tooltipBelow;

  /// Optional secondary line under the message. Defaults to "Tap to continue ↗"
  /// for interactive steps if unset.
  final String? hint;

  /// Extra pixels to extend the cutout rect upward beyond the target.
  /// Used to highlight a related widget that lives above the actual tap
  /// target (e.g. Duas Build step extends upward to also highlight the
  /// text field, since the user needs to type before tapping Build).
  /// Default 0 = cutout matches target exactly.
  final double cutoutPaddingTop;
}

/// The 13 steps of the interactive guided onboarding tour.
///
/// Order is canonical — index in this list IS the step index used by
/// `OnboardingTourController`. Adding/removing/reordering changes the tour.
///
/// See `docs/superpowers/plans/2026-05-26-interactive-guided-tour.md` for
/// the full design and rationale behind each step.
const List<OnboardingTourStepDef> kOnboardingTourSteps = [
  // Phase A — First Muḥāsabah (steps 1-5, all interactive)
  OnboardingTourStepDef(
    id: 'home.beginMuhasabah',
    surface: TourSurface.home,
    anchorId: 'beginMuhasabahCta',
    message: 'Tap to start your daily check-in.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'muhasabah.goDeeper',
    surface: TourSurface.muhasabah,
    anchorId: 'goDeeperCta',
    message: 'Open the reflection, story, and dua for this Name.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'muhasabah.readStory',
    surface: TourSurface.muhasabah,
    anchorId: 'readStoryCta',
    message: 'Continue to a story from the Prophets ﷺ.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  // "See the Dua" step is intentionally omitted — three identical-shape
  // taps in a row would feel patronizing. User navigates through the Story
  // screen silently, then the Ameen coachmark fires on deeper step 3.
  OnboardingTourStepDef(
    id: 'muhasabah.ameen',
    surface: TourSurface.muhasabah,
    anchorId: 'ameenCta',
    message: 'Tap Ameen to seal this prayer.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'muhasabah.returnHome',
    surface: TourSurface.muhasabah,
    anchorId: 'returnHomeCta',
    message: "You're done. Tap to return home.",
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  // Phase B — Habit-forming streak beat + tab discovery
  OnboardingTourStepDef(
    id: 'home.streakPill',
    surface: TourSurface.home,
    anchorId: 'streakPill',
    message: 'Your streak just started. Come back tomorrow to keep it.',
    interactive: false,
    tooltipBelow: true,
  ),
  OnboardingTourStepDef(
    id: 'appShell.tabCollection',
    surface: TourSurface.appShell,
    anchorId: 'tabCollection',
    message: 'Your earned card lives in your Collection.',
    interactive: true,
    tooltipBelow: false,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'appShell.tabDuasFromCollection',
    surface: TourSurface.appShell,
    anchorId: 'tabDuas',
    message: 'Tap Duas to build your first dua.',
    interactive: true,
    tooltipBelow: false,
    hint: 'Tap to continue ↗',
  ),
  // Phase C — First dua
  OnboardingTourStepDef(
    id: 'duas.buildCta',
    surface: TourSurface.duas,
    anchorId: 'buildCta',
    message: "Type a need (e.g. 'patience'), then tap Build.",
    interactive: true,
    tooltipBelow: false,
    hint: 'Tap Build to continue ↗',
    // Extends the cutout UPWARD by 280pt so the text field above the
    // Build CTA is ALSO highlighted (and not obscured by the tooltip).
    // Single anchor, single message, larger visual region. The cutout
    // covers the form (text field + section pills + Build CTA). The
    // tooltip auto-flips ABOVE the expanded cutout where it sits over
    // the page header, not the input. Live tested 2026-05-26.
    cutoutPaddingTop: 280,
  ),
  OnboardingTourStepDef(
    id: 'duas.firstRelatedHeart',
    surface: TourSurface.duas,
    anchorId: 'firstRelatedHeart',
    message: 'Tap ♡ to save duas you love.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'appShell.tabJournalFromDuas',
    surface: TourSurface.appShell,
    anchorId: 'tabJournal',
    message: 'Find your saved duas in Journal.',
    interactive: true,
    tooltipBelow: false,
    hint: 'Tap to continue ↗',
  ),
  // Phase D — Save/recall loop closure
  OnboardingTourStepDef(
    id: 'journal.firstEntry',
    surface: TourSurface.journal,
    anchorId: 'firstEntry',
    message: 'Tap to revisit a saved entry anytime.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'duaDetail.done',
    surface: TourSurface.duaDetail,
    anchorId: 'centered',
    message: "Private to you. You're all set.",
    interactive: false,
  ),
];

/// Number of steps in the tour. Used by the controller for bounds checks
/// and by analytics for "Step X of N" labels.
int get kOnboardingTourLength => kOnboardingTourSteps.length;
