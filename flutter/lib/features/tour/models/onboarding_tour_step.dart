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

/// Which guided-tour variant a user sees. The slim-vs-full A/B (2026-06-15)
/// runs `slim` (the 7-step Muḥāsabah → Duas tour) against `full` (the original
/// 13-step tour) to measure whether the shorter tour actually lifts retention.
/// See `assignTourVariant` + the `tour_ab_enabled` `app_config` flag.
enum TourVariant { full, slim }

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
/// safe. Shared by the two interactive tab steps (Duas, Home).
const double kTabCutoutPadX = 24;
const double kTabCutoutPadBottom = 24;
const double kTabCutoutPadTop = 8;

/// The 8 steps of the interactive guided onboarding tour.
///
/// Order is canonical — index in this list IS the step index used by
/// `OnboardingTourController`. Adding/removing/reordering changes the tour.
///
/// Slimmed 2026-06-15 to the **Muḥāsabah → Duas (build)** path. The original
/// 13-step tour bled ~56% of users across a Collection→Duas→Journal "tourism"
/// back half (worst at the tab-navigation steps); post-release cohort data
/// showed the tour length — not the paywall — was the first-session retention
/// bottleneck. This keeps the muḥāsabah aha (steps 0-4) and a single dua build
/// (steps 5-7, ONE tab hop, no Collection/Journal detour). The tour ends at the
/// END of the dua flow (step 7, the Ameen/result screen) — NOT on the Build tap
/// — so the user builds and SEES their full dua before the tour completes (and,
/// when `hard_paywall_after_tour_enabled` is on, the post-tour wall fires). The
/// "come back tomorrow" return hook is carried by the
/// evening streak push (`send-scheduled-notifications`: "Keep your N-day streak
/// alive"), so an in-tour streak beat (and the return-home hop it required) was
/// dropped to cut a second, less-reliable tab step. Collection and Journal are
/// surfaced contextually in-app instead of force-toured. See
/// `docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md`.
///
/// This is the `slim` arm of the slim-vs-full A/B; [kFullOnboardingTourSteps]
/// is the control. [kOnboardingTourSteps] aliases this as the default.
const List<OnboardingTourStepDef> kSlimOnboardingTourSteps = [
  // Phase A — First Muḥāsabah (all interactive taps)
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
  // screen silently, then the Ameen coachmark fires next.
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
  // Phase B — One dua build, the tour's finale. A single tab hop to Duas (no
  // Collection detour); the tour completes when the user taps Build, ending on
  // their own dua. No return-home/streak step — the streak return hook is
  // carried by the evening streak push instead.
  OnboardingTourStepDef(
    id: 'appShell.tabDuas',
    surface: TourSurface.appShell,
    anchorId: 'tabDuas',
    message: "Let's build your first dua, {name}. Tap Duas.",
    interactive: true,
    hint: 'Tap to continue ↗',
    // Advance when the user actually lands on /duas — robust to the tab
    // icon→activeIcon swap that disposes the anchor's pointer Listener
    // mid-tap (see Bug 1).
    navigateRoute: '/duas',
    // Anchor is the tab ICON only; grow the cutout into the full tab cell so
    // the "Duas" label is highlighted too (not greyed under the scrim).
    cutoutPaddingTop: kTabCutoutPadTop,
    cutoutPaddingBottom: kTabCutoutPadBottom,
    cutoutPaddingX: kTabCutoutPadX,
  ),
  OnboardingTourStepDef(
    id: 'duas.buildCta',
    surface: TourSurface.duas,
    anchorId: 'buildCta',
    message: "Type what's on your heart, then tap Build.",
    interactive: true,
    hint: 'Tap Build to continue ↗',
    // Extends the cutout UPWARD by 280pt so the text field above the Build CTA
    // is ALSO highlighted (and not obscured by the tooltip). The tooltip
    // auto-flips ABOVE the expanded cutout. Live tested 2026-05-26.
    cutoutPaddingTop: 280,
  ),
  // Reader coachmark — fires the instant the dua is built and the first section
  // ("Opening Praise") appears. Highlights the green "Next" button so the user
  // is guided to read through their dua section by section. Before this step
  // existed the tour advanced straight to `duas.buildComplete`, whose anchor
  // (Build Another Dua) only exists on the final result screen — so the first
  // section showed an EMPTY cutout (device repro 2026-06-18). Interactive
  // (tap-through): tapping Next advances both the section and the tour. Shows
  // despite the Build-a-Dua suppression latch because its anchor IS present
  // (the host only suppression-hides steps whose anchor is absent).
  OnboardingTourStepDef(
    id: 'duas.sectionNext',
    surface: TourSurface.duas,
    anchorId: 'duaSectionNext',
    message: 'Read through your dua, {name} — tap Next.',
    interactive: true,
    hint: 'Tap Next to continue ↗',
  ),
  // FINAL step — anchored at the END of the Build-a-Dua flow (the Ameen/result
  // screen). Suppression-gated: its `duaBuildComplete` anchor only exists on the
  // result view, so while the dua is building (loader + reader beats) the tour
  // stays hidden and pending. It reveals once the user has built and SEEN their
  // full dua, then auto-advances → the tour COMPLETES here, which is what
  // triggers the post-tour hard paywall (when that flag is on). This is why the
  // tour no longer ends on the Build TAP — the wall now waits until the dua flow
  // is fully done. Teach step (non-interactive) so the cutout isn't tap-through
  // over the real "Build Another Dua" button underneath it.
  OnboardingTourStepDef(
    id: 'duas.buildComplete',
    surface: TourSurface.duas,
    anchorId: 'duaBuildComplete',
    message: "Masha'Allah, {name} — your first dua is ready. 🌙",
    interactive: false,
    autoAdvance: Duration(milliseconds: 4500),
  ),
];

/// The original 13-step guided tour (pre-2026-06-15). Retained as the **control
/// arm** of the slim-vs-full A/B — DO NOT delete while the experiment runs. If
/// the experiment confirms the slim tour, this can be removed and the variant
/// machinery collapsed back to a single list. See
/// `docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md`.
const List<OnboardingTourStepDef> kFullOnboardingTourSteps = [
  // Phase A — First Muḥāsabah (steps 0-5, all interactive)
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
    navigateRoute: '/collection',
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
    cutoutPaddingTop: 280,
  ),
  // Reader coachmark (shared with the slim arm) — highlights the "Next" button
  // on the first built-dua section so the first screen isn't an empty cutout.
  // See the slim-arm copy of this step for the full rationale.
  OnboardingTourStepDef(
    id: 'duas.sectionNext',
    surface: TourSurface.duas,
    anchorId: 'duaSectionNext',
    message: 'Read through your dua, {name} — tap Next.',
    interactive: true,
    hint: 'Tap Next to continue ↗',
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

/// Default tour = slim (the go-forward variant). The A/B picks the live variant
/// at runtime via [assignTourVariant]; this alias is the idle/fallback default
/// and is what the unit tests pin.
const List<OnboardingTourStepDef> kOnboardingTourSteps =
    kSlimOnboardingTourSteps;

/// The step list for [variant].
List<OnboardingTourStepDef> tourStepsForVariant(TourVariant variant) =>
    variant == TourVariant.full
        ? kFullOnboardingTourSteps
        : kSlimOnboardingTourSteps;

/// Stable 0–99 bucket for [userId] (FNV-1a/32 over UTF-16 code units). Pure and
/// deterministic across sessions/devices with no persistence, so a user keeps
/// the same variant every launch. Empty id (anon) hashes to a fixed bucket.
int tourBucket(String userId) {
  var hash = 0x811c9dc5;
  for (final unit in userId.codeUnits) {
    hash = (hash ^ unit) & 0xffffffff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash % 100;
}

/// 50/50 split: lower half of the bucket space → slim, upper half → full.
/// Stable per [userId]. Caller only invokes this when `tour_ab_enabled` is on.
TourVariant assignTourVariant(String userId) =>
    tourBucket(userId) < 50 ? TourVariant.slim : TourVariant.full;

/// Number of steps in the DEFAULT (slim) tour. Used by tests + as a fallback;
/// live bounds checks use the active variant's `OnboardingTourState.steps`.
int get kOnboardingTourLength => kOnboardingTourSteps.length;
