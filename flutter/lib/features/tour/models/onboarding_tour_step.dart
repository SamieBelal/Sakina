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

/// How a tour step advances to the next one.
///
/// - [tapTarget]: the user taps the highlighted in-screen widget (detected by
///   the co-located `TourAnchor` `Listener`). This is the default and works for
///   buttons whose widget survives the tap (muhasabah CTAs, the dua heart).
/// - [navigate]: the user navigates to [navigateRoute]. The overlay host
///   advances when the app's active route becomes that path — used for the
///   bottom-nav tab steps, where tapping the tab swaps the icon for the
///   active-icon and disposes the anchor mid-gesture (so a pointer `Listener`
///   on the icon is fundamentally racy). Observing the route change instead is
///   robust regardless of where on the tab cell the user taps.
/// - [auto]: a read-only teach step that advances on a timer ([autoAdvance]).
enum TourAdvanceTrigger { tapTarget, navigate, auto }

@immutable
class OnboardingTourStepDef {
  const OnboardingTourStepDef({
    required this.id,
    required this.surface,
    required this.anchorId,
    required this.message,
    required this.interactive,
    this.hint,
    this.autoAdvance,
    this.navigateRoute,
    this.cutoutPaddingTop = 0,
    this.cutoutPaddingBottom = 0,
    this.cutoutPaddingX = 0,
  }) : assert(
          navigateRoute == null || interactive,
          'navigate steps are advanced by the user navigating — they are '
          'interactive (the user acts), never auto-advance teach steps',
        );

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

  /// Optional secondary line under the message. Defaults to "Tap to continue ↗"
  /// for interactive steps if unset.
  final String? hint;

  /// Non-null for read-only steps with nothing to tap (the streak beat, the
  /// final wrap-up). The overlay auto-advances after this delay; under a screen
  /// reader it shows a Continue instead. Tap steps leave this null.
  final Duration? autoAdvance;

  /// Non-null for steps the user advances by NAVIGATING to a destination
  /// (the bottom-nav tab steps). When set, the overlay host advances the tour
  /// the moment the app's active route equals this path — independent of which
  /// pixel the user tapped. This replaces the racy icon-`Listener` advance for
  /// tabs (tapping a tab disposes the anchor's `Listener` mid-gesture). The
  /// `TourAnchor`'s `GlobalKey` is still used to POSITION the spotlight; only
  /// the ADVANCE trigger moves to route observation. Path form: `/collection`.
  final String? navigateRoute;

  /// Derived advance trigger. `auto` if a teach step ([autoAdvance] set),
  /// `navigate` if it advances on reaching [navigateRoute], else `tapTarget`.
  TourAdvanceTrigger get trigger {
    if (autoAdvance != null) return TourAdvanceTrigger.auto;
    if (navigateRoute != null) return TourAdvanceTrigger.navigate;
    return TourAdvanceTrigger.tapTarget;
  }

  /// Extra pixels to extend the cutout rect upward beyond the target.
  /// Used to highlight a related widget that lives above the actual tap
  /// target (e.g. Duas Build step extends upward to also highlight the
  /// text field, since the user needs to type before tapping Build).
  /// Default 0 = cutout matches target exactly.
  final double cutoutPaddingTop;

  /// Extra pixels to extend the cutout rect downward beyond the target.
  /// Used to grow a small anchor into its full container — e.g. the bottom-nav
  /// tab steps anchor on the icon glyph only, so the cutout extends down to
  /// include the tab's text label. Default 0.
  final double cutoutPaddingBottom;

  /// Extra pixels to expand the cutout rect on BOTH horizontal sides beyond
  /// the target. Pairs with [cutoutPaddingBottom] to grow a centered icon
  /// anchor into a full tab-cell highlight (icon + label). Default 0.
  final double cutoutPaddingX;
}

/// Cutout padding that grows a bottom-nav tab's ICON anchor into its full
/// ~78×56pt cell, so the tab's text label is highlighted alongside the icon
/// instead of sitting greyed-out under the scrim. `X` (each side) widens the
/// ~24pt icon to comfortably cover the label without bleeding into neighbouring
/// tabs; `Bottom` reaches down past the label; `Top` lifts to the cell top.
/// All edges are clamped to the screen in `_targetRect`, so over-estimating is
/// safe. Shared by the three interactive tab steps.
const double kTabCutoutPadX = 24;
const double kTabCutoutPadBottom = 24;
const double kTabCutoutPadTop = 8;

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
    message: 'Assalamu alaikum, {name} 👋 Tap Begin Muhāsabah to start.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'muhasabah.goDeeper',
    surface: TourSurface.muhasabah,
    anchorId: 'goDeeperCta',
    message: 'Open Go Deeper, {name} — reflection, story and dua await.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'muhasabah.readStory',
    surface: TourSurface.muhasabah,
    anchorId: 'readStoryCta',
    message: 'Now read a story from the Prophets ﷺ.',
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
    message: 'Seal your prayer — tap Ameen.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'muhasabah.returnHome',
    surface: TourSurface.muhasabah,
    anchorId: 'returnHomeCta',
    message: 'Beautifully done, {name}. Head back home.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  // Phase B — Habit-forming streak beat + tab discovery
  OnboardingTourStepDef(
    id: 'home.streakPill',
    surface: TourSurface.home,
    anchorId: 'streakPill',
    message: 'Your streak begins today, {name}. Return tomorrow to keep it.',
    interactive: false,
    autoAdvance: Duration(milliseconds: 2000),
  ),
  OnboardingTourStepDef(
    id: 'appShell.tabCollection',
    surface: TourSurface.appShell,
    anchorId: 'tabCollection',
    message: 'Your first card is waiting — tap Collection.',
    interactive: true,
    hint: 'Tap to continue ↗',
    // Advance when the user actually lands on /collection — robust to the
    // tab icon→activeIcon swap that disposes the anchor's pointer Listener
    // mid-tap (the old icon-Listener advance never fired; see Bug 1).
    navigateRoute: '/collection',
    // Anchor is the tab ICON only; grow the cutout into the full tab cell so
    // the "Collection" label is highlighted too (not greyed under the scrim).
    cutoutPaddingTop: kTabCutoutPadTop,
    cutoutPaddingBottom: kTabCutoutPadBottom,
    cutoutPaddingX: kTabCutoutPadX,
  ),
  OnboardingTourStepDef(
    id: 'appShell.tabDuasFromCollection',
    surface: TourSurface.appShell,
    anchorId: 'tabDuas',
    message: "Let's build your first dua, {name}. Tap Duas.",
    interactive: true,
    hint: 'Tap to continue ↗',
    navigateRoute: '/duas',
    // Grow the icon anchor into the full tab cell (icon + "Duas" label).
    cutoutPaddingTop: kTabCutoutPadTop,
    cutoutPaddingBottom: kTabCutoutPadBottom,
    cutoutPaddingX: kTabCutoutPadX,
  ),
  // Phase C — First dua
  OnboardingTourStepDef(
    id: 'duas.buildCta',
    surface: TourSurface.duas,
    anchorId: 'buildCta',
    message: "Type what's on your heart, then tap Build.",
    interactive: true,
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
    message: 'Tap ♡ to keep a dua you love.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'appShell.tabJournalFromDuas',
    surface: TourSurface.appShell,
    anchorId: 'tabJournal',
    message: 'Your saved duas live in Journal, {name}.',
    interactive: true,
    hint: 'Tap to continue ↗',
    navigateRoute: '/journal',
    // Grow the icon anchor into the full tab cell (icon + "Journal" label).
    cutoutPaddingTop: kTabCutoutPadTop,
    cutoutPaddingBottom: kTabCutoutPadBottom,
    cutoutPaddingX: kTabCutoutPadX,
  ),
  // Phase D — Save/recall loop closure
  OnboardingTourStepDef(
    id: 'journal.firstEntry',
    surface: TourSurface.journal,
    anchorId: 'firstEntry',
    message: 'Tap any entry to revisit it anytime.',
    interactive: true,
    hint: 'Tap to continue ↗',
  ),
  OnboardingTourStepDef(
    id: 'duaDetail.done',
    surface: TourSurface.duaDetail,
    anchorId: 'centered',
    message: "That's the whole loop, {name}. Sakina is yours now. 🌙",
    interactive: false,
    autoAdvance: Duration(milliseconds: 3500),
  ),
];

/// Number of steps in the tour. Used by the controller for bounds checks
/// and by analytics for "Step X of N" labels.
int get kOnboardingTourLength => kOnboardingTourSteps.length;
