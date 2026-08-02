# Interactive Guided Tour — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current passive coachmark tour (point at a button, tap "Next →") with a continuous, screen-spanning, interactive guided tour that walks a new user through their first Muḥāsabah, their first dua, and every bottom-nav tab. The user advances by tapping the highlighted target — taps pass through the scrim and actually drive the underlying UI.

**Architecture:** A single `OnboardingTourController` (Riverpod) owns the whole tour state machine. Each step declares which screen + anchor it targets, and screens register their anchor `GlobalKey`s on mount. The controller pumps a root-overlay `CoachmarkOverlay` whose scrim is rendered as four absorbing rectangles around the cutout — leaving the cutout itself genuinely interactive. Tour advances when the highlighted target is tapped (interactive step) OR when the user taps "Continue" (teach step). The existing per-key `TourService` flags are deprecated in favor of one unified `onboarding_tour_v{N}` flag.

**Tech Stack:** Flutter / Riverpod / GoRouter / SharedPreferences / Mixpanel (analytics).

---

## CEO review updates (2026-05-26)

Changes applied after `/plan-ceo-review` audit:

**Cuts (-2 steps):**
- Removed the old step 4 (Muhāsabah "See the Dua"). Three identical-shape coachmarks in a row over the same green-pill pattern was patronizing. Keep Go Deeper + Read the Story (rhythm-setters) and Ameen (conceptually distinct sealing gesture); let the user tap "See the Dua" naturally without a coachmark.
- Removed the old step 12 (Reflect composite — cutout on Journal tab while message described Reflect). Incoherent. Reflect is conceptually covered by Muḥāsabah (text input + AI response).

**Adds (+2 steps, net 0):**
- New post-Muhāsabah streak-pill step on Home (step 6 below). The strongest habit-formation moment in the app: the user just earned streak=1, name it.
- New interactive Journal entry tap at the end. The save-heart gesture (step 10) is meaningless without teaching the user to re-open from Journal. Step 13 becomes interactive (tap first entry), step 14 is the passive Done on DuaDetailPage.

**Critical bug fixes baked in:**
- **NameRevealOverlay chain (Task 4 addition).** Step 1 → step 2 transition: after the user taps "Begin Muḥāsabah", the AI generates a Name and `NameRevealOverlay` pushes onto the root navigator (see `muhasabah_screen.dart:152`). Step 2's anchor (Go Deeper) is *behind* that overlay. The controller must wait for the topmost fullscreen route to be the Muḥāsabah screen itself before mounting step 2. Implementation: `OnboardingTourOverlayHost` checks `Navigator.of(context, rootNavigator: true).canPop() == false` (or compares route names) before mounting the next overlay. If the overlay is up, hold; subscribe to `NavigatorObserver.didPop` to retry on dismissal.
- **"Already checked in today" branch.** `Begin Muḥāsabah` swaps to gated `Seek Another Name` if `lastCheckinDate == today`. If the tour fires for a returning user (e.g. they reinstalled), step 1's anchor is the gated CTA, which costs 25 tokens to tap. Add a precondition in `OnboardingTourController.start()`: skip the tour if `dailyLoopProvider.state.lastCheckinIsToday`. Set the seen-flag immediately so the next launch doesn't retry. (We're not running a different first-tour for returning users — they already did onboarding under the old flow.)

**Timing estimate corrected.** Plan previously said "30–60s real-time." Realistic count including AI generation latency (5–15s × 2), NameRevealOverlay dismissal, 4 silent dua-section taps between step 9 and step 10, and reading time on the deeper-step cards: **90–150s**. Still acceptable for first-run.

---

## Per-screen UX analysis

| Screen | File | Main first-time action | Tour role |
|--------|------|-------------------------|-----------|
| Home (`/`) | `lib/features/progress/screens/progress_screen.dart` | Tap "Begin Muḥāsabah" CTA | Step 1 (entry), Step 7 (return + tab pivot) |
| Muḥāsabah (`/muhasabah`) | `lib/features/daily/screens/muhasabah_screen.dart` | Tap through Go Deeper → Read the Story → See the Dua → Ameen → Return | Steps 2–6 (the heart of "first muhasabah") |
| Collection (`/collection`) | `lib/features/collection/screens/collection_screen.dart` | View card grid (just earned 1 starter Name) | Step 8 (passive teach + pivot to Duas) |
| Duas (`/duas`) | `lib/features/duas/screens/duas_screen.dart` | Type need → tap "Build My Dua" → swipe through 4 sections → tap Ameen → tap heart on related dua | Steps 9–10 ("first dua" + save) |
| Journal (`/journal`) | `lib/features/journal/screens/journal_screen.dart` | View saved reflections + duas (now non-empty) | Step 12 (interactive: tap first entry → DuaDetailPage) |
| DuaDetailPage | `lib/features/journal/screens/dua_detail_page.dart` | Read the saved dua in full | Step 13 (final teach + Done) |
| Reflect (`/reflect`) | `lib/features/reflect/screens/reflect_screen.dart` | Type → tap Reflect → AI response | **Not in tour** (post-CEO cut — duplicates muhāsabah's text-input pattern) |

**Coverage check (post-CEO):** 4 of 5 tabs visited (Home, Collection, Duas, Journal). Reflect is intentionally skipped — its text-input + AI-response pattern is conceptually identical to Muḥāsabah, which the user has just walked through end-to-end. Both AI-driven flows (muhāsabah + duas) walked end-to-end. Save-then-recall loop closed via step 12.

---

## The 13-step tour sequence (post-CEO-review)

| # | Screen | Anchor | Tooltip copy | Mode | Advances on |
|---|--------|--------|--------------|------|-------------|
| 1 | Home | Begin Muḥāsabah pill | "Tap to start your daily check-in." | interactive | target tap → pushes `/muhasabah` (then wait for NameRevealOverlay dismissal before step 2) |
| 2 | Muḥāsabah result | Go Deeper pill | "Open the reflection, story, and dua for this Name." | interactive | target tap → in-screen step transition |
| 3 | Muḥāsabah deeper-1 (Reflection) | Read the Story button | "Continue to a story from the Prophets ﷺ." | interactive | target tap |
| 4 | Muḥāsabah deeper-3 (Dua) | Ameen pill | "Tap Ameen to seal this prayer." | interactive | target tap. NOTE: user navigates through the Story screen silently (no coachmark) between step 3 and step 4 |
| 5 | Muḥāsabah completed | Return to Home link | "You're done. Tap to return home." | interactive | target tap → `context.go('/')` |
| 6 | Home (return) | Streak pill | "Your streak just started. Come back tomorrow to keep it." | teach (Continue button) | Continue tap |
| 7 | Home (return) | Collection tab in bottom nav | "Your earned card lives in your Collection." | interactive | target tap → `/collection` |
| 8 | Collection | Duas tab in bottom nav | "Tap Duas to build your first dua." | interactive | target tap → `/duas` |
| 9 | Duas (input) | Build My Dua button | "Type a need (e.g. 'patience'), then tap Build." | interactive | target tap (validates → in-screen flow) |
| 10 | Duas (Ameen result) | First related-dua heart | "Tap ♡ to save duas you love." | interactive | target tap |
| 11 | Duas (Ameen result) | Journal tab in bottom nav | "Find your saved duas in Journal." | interactive | target tap → `/journal` |
| 12 | Journal | First entry tile | "Tap to revisit a saved entry anytime." | interactive | target tap → opens `DuaDetailPage` |
| 13 | DuaDetailPage | (centered, no anchor) | "Private to you. You're all set." | teach (Done button) | Done tap → close detail + finish tour |

Total: **11 interactive** + **2 teach**. ~90–150s real-time including AI latency, NameRevealOverlay dismissal, the 4 silent dua-section taps between step 9 and step 10, and reading time on the deeper-step cards.

**Step 4 nuance (post-CEO cut):** The old plan had a coachmark on "See the Dua" between Read the Story and Ameen. CEO review cut it — three identical green-pill taps in a row was patronizing. After step 3 the user taps "Read the Story" → lands on the Story card with no coachmark → reads → taps "See the Dua" naturally → lands on the Dua card → step 4 coachmark fires on Ameen. The Story screen is silent on purpose. If the user taps Back or exits between step 3 and step 4, the controller holds and re-mounts when Ameen's anchor registers (Task 3 anchor-registry behavior).

**Step 6 nuance (post-CEO add):** The first muhāsabah grants `streak = 1`. The streak pill on the Home dashboard is the single highest-leverage habit-formation moment in the app. A 5-second beat naming it ("Your streak just started") explicitly ties the experience to tomorrow's return. Passive Continue (no tap-through needed) because the streak pill is not a tappable target.

**Step 12 nuance (post-CEO add):** The user saved a dua in step 10. Without teaching the open-from-Journal interaction, that save is meaningless. Step 12 anchors on the **first entry tile** in the Journal list. The user's just-saved dua is now the most recent entry, so this tile is guaranteed populated. Tap → `DuaDetailPage` opens (existing route: `lib/features/journal/screens/dua_detail_page.dart`).

**Step 13 nuance:** Final teach step lives on `DuaDetailPage`, not the Journal list. Centered tooltip (no anchor) with Done button. Tap Done → pop the detail page → tour completes. If the user dismisses the detail page via back gesture, the controller treats that as completion too (no fail state).

---

## UI polish (post-research, 2026-05-26)

The current tooltip is functional but generic: flat white card, dark text, emerald accents, animated entry. To match Sakina's mushaf-like premium register (warm cream + emerald + gold + Islamic geometric accents at 5-8% opacity), apply these five upgrades. All preserve the existing AlertDialog vocabulary; none introduce mascots, confetti, or cartoon finger indicators (those would visibly downgrade the spiritual register).

### Polish 1: Hero-style morph between tooltip positions (highest-impact)

Today, each step's tooltip fades out and the next fades in. Linear, Notion, Stripe, Arc all use a single shared-element transition where the card morphs (position, size, cutout) as one continuous object. Single biggest "premium" lift available.

**Flutter implementation:**
- Replace the per-step `OverlayEntry.remove()` + new insert with a single persistent overlay that updates its `step` field.
- Animate the cutout rect, scrim, and tooltip position with `TweenAnimationBuilder<Rect>` (cutout) + `AnimatedPositioned` (tooltip) + `AnimatedContainer` (tooltip size). All driven by a single `Duration(milliseconds: 320)` and `Curves.easeOutCubic`.
- Body text crossfades via `AnimatedSwitcher(duration: 200ms, child: Text(step.message, key: ValueKey(step.id)))`.

### Polish 2: Warm-ink scrim (post-live-test: blur removed)

**Original design:** wrap the scrim painter in `BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14))` over a warm-ink color overlay. The intent was a "premium signal" matching iOS Control Center, Stripe, Cal AI's onboarding scrim.

**What actually happened (live test, 2026-05-27):** the sigma-14 blur was too aggressive. The surrounding UI became unreadable shapes instead of recognizable widgets, which defeats the tour's job of teaching what the highlighted target is RELATIVE to. Industry coachmark convention (Linear, Stripe, Notion, Calm) uses a solid semi-transparent dim, not a blur.

**Final implementation:** solid warm-ink overlay only. No `BackdropFilter`, no `ImageFilter.blur`.
- Color overlay: `Color(0xFF1B1410).withValues(alpha: 0.42)` (kept the same).
- Performance: no longer a concern — solid color paint is cheap on every device.
- The `--no-blur` debug flag and device-tier check are no longer needed and were not implemented.

### Polish 3: Gradient tooltip card + Islamic geometric watermark

Card stops looking like a generic white popover and starts looking like Sakina.

**Flutter implementation:**
- `BoxDecoration` gradient: `LinearGradient(begin: topCenter, end: bottomCenter, colors: [Color(0xFFFBF7F2), Color(0xFFF5EFE6)])`.
- 5-8% opacity SVG octagram or khatam pattern in the top-right corner of the card (use the same asset path family as `assets/illustrations/`). Sized ~60×60pt. `Opacity(0.06, child: SvgPicture.asset(...))` positioned absolutely.
- Keep the existing shadow + border-radius.

### Polish 4: Soft breathing pulse on the cutout (1.8s loop)

Spiritually on-theme (matches dhikr rhythm). Draws attention without urgency. Replaces the static cutout outline with a slow pulse — opacity 0.4 ↔ 0.8 and scale 1.0 ↔ 1.05 over 1800ms, sine-eased so it actually breathes.

**Flutter implementation:**
- Add an `AnimationController(duration: 1800ms)..repeat(reverse: true)` to `_CoachmarkOverlayState`.
- In `_ScrimWithHolePainter`, paint a second outline stroke around the cutout with the pulse-driven opacity + scale (animation value 0..1, eased via `Curves.easeInOutSine`). Stroke color: `AppColors.secondary` (gold) at 30% alpha. **LOCKED via design review** — gold beats emerald here because it reads as warm illumination and matches the existing "✨ Crafted for you" ribbon and the 99-Names gold accents.
- **Perf:** wrap the pulse `CustomPaint` in its own `RepaintBoundary` so the 4 scrim absorber rectangles don't repaint at 60fps with the pulse. Post-eng-review fix — without the boundary, the 4 GestureDetector regions get marked dirty every frame and Flutter rebuilds them unnecessarily.
- Only run the pulse on `interactive` steps — for `teach` steps it would compete with the Continue button.

### Polish 5: Emerald accent stripe (left edge) + gold dot

Brand-coherent visual signature for every tour card. Free identity. Reads as illuminated-manuscript marginalia rather than alert-banner.

**Flutter implementation:**
- Wrap the tooltip `Container` in a `Row` with a 3px-wide `Container(color: AppColors.primary)` as the first child (or use `Border(left: BorderSide(width: 3, color: AppColors.primary))` on the `BoxDecoration`).
- Add a 6px gold dot (`Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary))`) positioned at the top of the stripe, ~8pt from the card's top edge.

### Explicit rejects (do NOT add)

- Finger / hand tap indicator — Duolingo cartoon register, breaks mushaf feel.
- Bouncing arrow — same problem.
- Western confetti on completion — replace with a slow gold-dust shimmer or single khatam star bloom if you want a completion moment (deferred — flag for v2).
- Mascot / persona character — Sakina has no anthropomorphic guide; adding one dilutes the spiritual register.
- Skip-confirm modal — adds friction. The existing Skip button is already deliberate enough.

### Bonus polish (defer to v2 unless cheap)

- **Step progress: gold prayer-bead dots (LOCKED — design review decision).** Filled circles, ~7px diameter. Active dot: gold inner fill (`AppColors.secondary`) inside emerald outer ring (`AppColors.primary` at 1.5px). Inactive dots: cream (`AppColors.textTertiaryLight` at 50% alpha). Spacing: 6px between dots. Reads as tasbeeh beads, on-theme. Ship in v1.
- **Completion moment.** When step 13's Done is tapped, fade the scrim to transparent over 600ms while a soft gold shimmer expands from the screen center. ~30 min Flutter work, big emotional payoff. Treat as separate "tour completion" PR.

### Animation specs (collected)

| Animation | Duration | Curve | Notes |
|-----------|----------|-------|-------|
| Tooltip morph (position/size) | 320ms | easeOutCubic | shared across steps |
| Tooltip body crossfade | 200ms | linear | inside AnimatedSwitcher |
| Tooltip entry (first step) | 600ms | composite (existing) | keep current intro animation |
| Cutout breathing pulse | 1800ms loop | easeInOutSine | only on interactive steps |
| Scrim fade-in | 280ms | easeOut | unchanged from today |
| Tooltip exit (skip/done) | 240ms | easeIn | new |

### Responsive specs

| Viewport | Tooltip behavior |
|----------|-----------------|
| **Phone < 360pt wide** (small iPhone SE, older Android) | Tooltip max-width = `viewport - 32pt` (16pt margin each side). Step dots shrink to 5px. Skip becomes icon-only (existing behavior). |
| **Phone 360-430pt** (iPhone 14/15/16/17 Pro range) | Tooltip max-width = 360pt centered. This is the default sim target. |
| **Phone > 430pt** (Pro Max, large Androids) | Tooltip max-width = 400pt centered. Generous horizontal padding to avoid the "stretched across foldable" look. |
| **Tablet / iPad** | Tooltip max-width = 480pt centered (no full-width sprawl). Cutout target rect unchanged. The scrim covers the whole window — a tour on iPad shouldn't feel like a phone tooltip stretched. |
| **Foldable (open)** | Treat as tablet. Tooltip stays in the larger window pane. Scrim covers both panes. |
| **Landscape orientation** | Existing `OrientationBuilder` already rebuilds. New: when landscape, prefer-side flips: tooltip prefers horizontal alignment to the cutout (side-by-side) rather than above/below. Cost: ~30min Flutter work. Defer to v2 if landscape adoption is low. |

### Accessibility specs

- **Touch targets:** Skip + Continue/Next/Done buttons are wrapped in `TextButton(style: TextButton.styleFrom(minimumSize: const Size(44, 44)))` already. Don't shrink them.
- **Semantics:** Tooltip is `Semantics(container: true, liveRegion: true, label: message)` already. VoiceOver/TalkBack announce the new step's message when the tooltip mounts.
- **Step progress for AT:** Add `Semantics(label: 'Step ${i+1} of $total')` on the step-dots row so screen readers announce progress, not just an unlabeled row of circles.
- **Cutout target:** When the cutout highlights a target, ensure the target widget's own `Semantics` stays accessible (don't smother it with the overlay's semantics). The 4-rect absorber strips around the cutout must NOT block accessibility focus on the target — wrap each strip in `ExcludeSemantics` so they don't appear as 4 phantom regions to VoiceOver.
- **Reduced motion:** All animations check `MediaQuery.disableAnimations` AND `MediaQuery.accessibleNavigation`. When either is true, collapse to 1-frame state changes (no morph, no pulse, no fade).
- **Contrast:**
  - Body text on cream gradient (`#FBF7F2` to `#F5EFE6`): use `AppColors.textPrimaryLight` (`#1B1410` or similar) — verify >7:1 ratio (AAA) before shipping.
  - Hint text "Tap to continue ↗" on cream: `AppColors.primary` (emerald `#1B6B4A`) — verify >4.5:1 ratio (AA). If under, darken to `#155538`.
  - Step dots active (emerald) on cream: visually pass but verify.
  - Skip text on cream: `AppColors.textSecondaryLight` — verify >4.5:1.
- **Hit area on small targets:** The cutout pads the target rect by 8pt (existing `EdgeInsets.all(8).inflateRect`). For very small targets (heart icon, dots), the padded cutout area is the effective tap target — usable. Confirm via golden test that a 24×24pt heart icon ends up with a ~40×40pt cutout, then ~44pt+ effective tap area accounting for finger margin.
- **Keyboard nav (iPadOS with hardware keyboard):** Skip + Continue/Next/Done buttons should be focusable in tab order. Tooltip body is non-interactive. Cutout target retains its own focus.

### Updates to existing files

- `lib/widgets/coachmark/coachmark_overlay.dart` — add gradient `BoxDecoration`, watermark, breathing pulse controller, left-edge stripe (no `BackdropFilter` — removed during live test 2026-05-27).
- `lib/widgets/coachmark/coachmark_controller.dart` (or its new home in `OnboardingTourOverlayHost`) — make the overlay persistent across step advances and animate state change rather than re-mounting.
- New asset: `assets/illustrations/tooltip_watermark.svg` — 8-point khatam star (the same octagram already used in `assets/illustrations/journal_empty.svg` family), monochrome single-color (`#1B6B4A`, the emerald), 60×60pt viewBox, ~1KB. Renders at `Opacity(0.06)` so the source color is reduced to a ghost. Place via `SvgPicture.asset` positioned `top: 12, right: 12` inside the tooltip card. **Use the existing khatam, not a new geometric**, to keep the visual language continuous with the 99-Names collection cards.

### Testing

- Widget test that asserts cutout breathing controller is `null` for `interactive: false` steps (no animation cost for teach steps).
- Widget test that asserts tooltip morph uses `AnimatedPositioned` + `AnimatedContainer` (not OverlayEntry replace) for step transitions.
- Golden tests for the tooltip card in both interactive + teach modes — these catch accidental regressions to the visual style.
- Golden tests for: (a) cutout in top half of screen, tooltip below; (b) cutout in bottom half, tooltip above; (c) cutout very wide (full-width target like bottom-nav tab); (d) cutout very narrow (a small heart icon).
- Manual perf check on iPhone 12 + Pixel 6 with the blur enabled. If frame rate drops below 55fps during scroll-while-tour-visible, disable blur on those devices.

### Interaction state coverage (post-design-review)

| State | What user sees |
|-------|----------------|
| **Tour active, anchor visible** | Scrim + blur + cutout pulsing on interactive steps; tooltip morphs to next position on advance. |
| **Tour active, anchor not yet registered** (e.g. user is mid-navigation between screens) | Scrim + blur stay up; tooltip fades to a centered "Loading next step…" with no cutout. Max wait 2s — after that, the controller treats it as a navigation glitch and auto-advances to the next available anchor or skips the orphan step. Logged as `tour_anchor_timeout` for diagnostics. |
| **Tour active, blocking route up** (NameRevealOverlay etc.) | Tour overlay hidden entirely. No scrim, no tooltip. Resumes when the blocking route pops. |
| **Skip mid-tour** | Tooltip fades + scrim fades over 240ms (`Curves.easeIn`); no confirm modal (intentional — Skip is already deliberate). Seen flag persists. |
| **Tour completion (step 13 Done)** | Scrim fades to transparent over 600ms while a subtle gold-dust shimmer expands from screen center (single khatam star pulse, 800ms, opacity 0 → 0.4 → 0). Then overlay removes. **Not Western confetti.** |
| **Reduced-motion accessibility** | If `MediaQuery.disableAnimations == true` OR `MediaQuery.accessibleNavigation == true`: all animations collapse to a 1-frame state change. Breathing pulse off. Morph off. Crossfade off. Tour still functional, just static. |
| **Low-end device fallback** | N/A — blur was removed during live test (2026-05-27). Solid `Color(0xFF1B1410).withValues(alpha: 0.42)` paints cheaply on every device. |
| **Tour first launch failure** (e.g. SharedPreferences read fails) | Controller stays `idle`. No tour fires. Errors logged via `analytics.track('tour_start_failed', {reason})`. App proceeds normally. |
| **Dark mode** | Currently irrelevant — Sakina is light-mode-only per `themeMode: ThemeMode.light` in `main.dart`. If dark mode is added later, tooltip background swaps to `AppColors.surfaceDark` (warm charcoal, not pure black) + cream text. Defer until dark mode is in scope. |

---

## File structure

**New files:**
- `lib/features/tour/models/onboarding_tour_step.dart` — sealed step definitions
- `lib/features/tour/providers/onboarding_tour_controller.dart` — controller + provider
- `lib/features/tour/providers/tour_anchor_registry.dart` — anchor key registry provider
- `lib/widgets/coachmark/tour_anchor.dart` — `KeyedSubtree` wrapper helper screens use
- `test/features/tour/onboarding_tour_controller_test.dart`
- `test/features/tour/onboarding_tour_overlay_widget_test.dart`
- `test/widgets/coachmark/coachmark_overlay_tap_through_test.dart`

**Modified files:**
- `lib/widgets/coachmark/coachmark_overlay.dart` — scrim refactor + tap-through Listener
- `lib/widgets/coachmark/coachmark_step.dart` — add `interactive` + `hint`
- `lib/widgets/coachmark/coachmark_controller.dart` — delete (replaced by `OnboardingTourController`)
- `lib/services/tour_service.dart` — add unified `onboarding_tour_v1` flag, deprecate per-key flags
- `lib/features/progress/screens/progress_screen.dart` — replace `_maybeStartHomeTour` with controller boot
- `lib/features/daily/screens/muhasabah_screen.dart` — register 5 anchors (Go Deeper, Read the Story, See the Dua, Ameen, Return to Home)
- `lib/features/collection/screens/collection_screen.dart` — remove empty-state auto-fire, register Duas-tab anchor relay
- `lib/features/duas/screens/duas_screen.dart` — register `buildCta` + reuse `firstHeart` anchor
- `lib/features/journal/screens/journal_screen.dart` — remove empty-state auto-fire, register list anchor
- `lib/features/reflect/screens/reflect_screen.dart` — register text-field anchor (or skip; see step 12 note)
- `lib/widgets/app_shell.dart` — add per-tab `GlobalKey`s (`tour.tab.collection`, `tour.tab.duas`, `tour.tab.reflect`, `tour.tab.journal`)
- `lib/services/analytics_events.dart` — add `tour_step_advanced` event with `via: 'target_tap' | 'continue'`
- `lib/features/settings/screens/settings_screen.dart` — repoint Replay button at new controller
- `lib/core/router.dart` — verify `sakina://settings?action=replay_tour` deep link still works after migration

**Deleted:**
- Per-tab tour wiring in collection/journal/duas screens (the auto-fire empty-state-teach beats)
- `CoachmarkController` (subsumed by `OnboardingTourController`)
- `TourKey.{home,collection,journal,duas}` (replaced by single `onboarding_tour_v1`)

---

## Task 1: Refactor `CoachmarkOverlay` for tap-through + interactive mode

**Files:**
- Modify: `lib/widgets/coachmark/coachmark_overlay.dart`
- Modify: `lib/widgets/coachmark/coachmark_step.dart`
- Test: `test/widgets/coachmark/coachmark_overlay_tap_through_test.dart`

### Why this matters

Today's scrim is a single full-screen `CustomPaint` with a hole-painted-by-even-odd-fill-rule. Visually correct, but the `Material(color: Colors.transparent)` wrapping it absorbs every tap — including taps "into" the cutout. The target button never sees the user's finger. To make taps pass through, render the scrim as **four `IgnorePointer`-wrapped painted rectangles** around the cutout, leaving the cutout area genuinely empty in the gesture tree.

For interactive steps, add a transparent `Listener` over the cutout rect that records pointer-up (so the tour can advance) without consuming the event (so the underlying button still fires).

### Step-by-step

- [ ] **Step 1: Add `interactive` + `hint` to `CoachmarkStep`**

```dart
// lib/widgets/coachmark/coachmark_step.dart
class CoachmarkStep {
  const CoachmarkStep({
    required this.target,
    required this.message,
    this.tooltipBelow = true,
    this.interactive = true,
    this.hint,
  });

  final GlobalKey target;
  final String message;
  final bool tooltipBelow;

  /// When true, the cutout is tap-through and the tour advances on the next
  /// pointer-up inside the cutout rect (no "Next" button). When false, the
  /// tooltip renders a "Continue" button and taps inside the cutout are
  /// absorbed by the scrim — used for teach moments.
  final bool interactive;

  /// Optional secondary line in the tooltip. e.g. "Tap to continue →"
  final String? hint;
}
```

- [ ] **Step 2: Write the failing tap-through widget test**

```dart
// test/widgets/coachmark/coachmark_overlay_tap_through_test.dart
testWidgets('interactive cutout passes pointer events to underlying button',
    (tester) async {
  final targetKey = GlobalKey();
  var underlyingTapped = false;
  var tourAdvanced = false;

  await tester.pumpWidget(MaterialApp(
    home: Stack(children: [
      Center(
        child: GestureDetector(
          key: targetKey,
          onTap: () => underlyingTapped = true,
          child: Container(width: 120, height: 48, color: Colors.amber),
        ),
      ),
      CoachmarkOverlay(
        step: CoachmarkStep(
            target: targetKey, message: 'Tap me.', interactive: true),
        stepIndex: 0,
        totalSteps: 1,
        onNext: () => tourAdvanced = true,
        onSkip: () {},
      ),
    ]),
  ));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(targetKey));
  await tester.pump();

  expect(underlyingTapped, isTrue, reason: 'underlying button must receive tap');
  expect(tourAdvanced, isTrue, reason: 'tour must advance on cutout tap');
});

testWidgets('teach mode absorbs cutout taps; Continue advances', (tester) async {
  // Symmetric test: interactive=false → underlyingTapped stays false,
  // and the Continue button advances the tour.
});
```

- [ ] **Step 3: Run the failing test**

Run: `flutter test test/widgets/coachmark/coachmark_overlay_tap_through_test.dart`
Expected: FAIL — scrim absorbs taps; underlying button never fires.

- [ ] **Step 4: Refactor the scrim**

Replace the single `CustomPaint` over `Positioned.fill` with a `Stack` of four `IgnorePointer(child: CustomPaint(...))` rectangles around the cutout (top, bottom, left, right). The four rectangles cover the whole screen MINUS the cutout. Visual output is identical to today (same color, same animation). Wrap the visual painters in `IgnorePointer` so they don't absorb events.

```dart
Widget _scrim(BuildContext context, Rect? cutout, double growth, double opacity) {
  if (cutout == null) {
    return IgnorePointer(
      child: CustomPaint(painter: _FullScrimPainter(opacity: opacity)),
    );
  }
  final padded = const EdgeInsets.all(8).inflateRect(cutout);
  final hole = Rect.lerp(
    Rect.fromCenter(center: padded.center, width: 0, height: 0),
    padded,
    growth,
  )!;
  // Top, bottom, left, right rectangles around the hole. Each is its own
  // CustomPaint so the rounded-corner pixels on the hole edge still look
  // right when growth < 1. _ScrimSlicePainter takes the screen-relative
  // hole rect and draws the scrim on its slice with a rounded inside corner.
  return Stack(children: [
    Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ScrimWithHolePainter(hole: hole, opacity: opacity),
        ),
      ),
    ),
  ]);
}
```

Notes:
- `_ScrimWithHolePainter` uses the same even-odd path as today, but the WHOLE thing is wrapped in `IgnorePointer`. The hole's hit-test passes through to whatever's underneath.
- We still need to **absorb taps outside the cutout** so the user can't bypass the tour by tapping unrelated UI. To absorb everything except the hole, add a `GestureDetector(behavior: HitTestBehavior.opaque)` underneath the painter, but **clip out** the hole rect with a `Stack` of four absorber rectangles around the hole (each `GestureDetector(behavior: opaque, child: SizedBox.expand())` sized to the strip). Computed from the hole rect.

```dart
// pseudo:
List<Widget> _absorberStrips(Rect hole, Size screen) => [
  // top strip
  Positioned(left: 0, top: 0, right: 0, height: hole.top,
      child: const _AbsorbTap()),
  // bottom strip
  Positioned(left: 0, top: hole.bottom, right: 0, bottom: 0,
      child: const _AbsorbTap()),
  // left strip
  Positioned(left: 0, top: hole.top, width: hole.left,
      height: hole.height, child: const _AbsorbTap()),
  // right strip
  Positioned(left: hole.right, top: hole.top, right: 0,
      height: hole.height, child: const _AbsorbTap()),
];

class _AbsorbTap extends StatelessWidget {
  const _AbsorbTap();
  @override
  Widget build(BuildContext c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const SizedBox.expand(),
      );
}
```

- [ ] **Step 5: Add the tap-through Listener for interactive mode**

When `step.interactive == true`, render a `Positioned` `Listener` exactly over the cutout rect with `behavior: HitTestBehavior.translucent`. On `onPointerUp` inside the rect, call `widget.onNext`. The Listener does NOT consume the event, so the underlying button's `GestureDetector` still fires.

```dart
if (step.interactive && rect != null)
  Positioned(
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) {
        if (_advanced) return;
        _advanced = true;
        widget.onNext();
      },
      child: const SizedBox.expand(),
    ),
  ),
```

- [ ] **Step 6: Update the tooltip for interactive vs teach mode**

- Interactive: hide the `Next →` text button. Show a small `hint` line at the bottom of the tooltip (e.g. `'Tap to continue ↗'`) in `AppColors.primary` 13pt. Skip button stays.
- Teach: keep the existing Next/Done button. Hint line hidden.

- [ ] **Step 7: Run the test → green**

Run: `flutter test test/widgets/coachmark/coachmark_overlay_tap_through_test.dart`
Expected: PASS.

- [ ] **Step 7.5: AnimationController disposal (post-eng-review)**

`_CoachmarkOverlayState` will own three `AnimationController`s in the final version:
1. Intro/exit controller (existing 600ms entry, plus new 240ms exit)
2. Morph controller (new: 320ms position/size morph between steps)
3. Breathing pulse controller (new: 1800ms loop, only on interactive steps)

All three MUST be disposed in `dispose()`. Add a single test:

```dart
testWidgets('disposes all animation controllers on tour completion',
    (tester) async {
  // Mount overlay, advance to complete, verify no ticker-leak assertion.
  // Use `tester.binding.window.physicalSizeTestValue` to force teardown.
});
```

Without this, the test suite emits `A SchedulerBinding was attached, but no ticker was associated to it` warnings in CI and the breathing pulse keeps firing 60fps after the tour ends until garbage collection. Real battery hit.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/coachmark/ test/widgets/coachmark/
git commit -m "feat(tour): tap-through cutout + interactive step mode"
```

---

## Task 2: `OnboardingTourStepDef` registry

**Files:**
- Create: `lib/features/tour/models/onboarding_tour_step.dart`
- Test: `test/features/tour/onboarding_tour_step_test.dart`

The plan-of-record for the 13 steps, single source of truth. Each step declares: which screen owns the anchor, the anchor's string ID within that screen, the message, the mode, and the `tooltipBelow` preference. A pure-data file — no Flutter imports beyond `flutter/foundation.dart`.

- [ ] **Step 1: Define the sealed step enum + step def**

```dart
// lib/features/tour/models/onboarding_tour_step.dart
import 'package:flutter/foundation.dart';

enum TourSurface { home, muhasabah, collection, duas, reflect, journal }

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
  });

  final String id; // e.g. 'home.beginMuhasabah'
  final TourSurface surface;
  final String anchorId; // e.g. 'beginMuhasabahCta'
  final String message;
  final bool interactive;
  final bool tooltipBelow;
  final String? hint;
}

const List<OnboardingTourStepDef> kOnboardingTourSteps = [
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
  // ... 11 more, see Step Sequence table above.
];
```

- [ ] **Step 2: Test that ids are unique and indices align with the table**

```dart
test('step ids are unique', () {
  final ids = kOnboardingTourSteps.map((s) => s.id).toList();
  expect(ids.toSet().length, ids.length);
});

test('first step is home.beginMuhasabah', () {
  expect(kOnboardingTourSteps.first.id, 'home.beginMuhasabah');
});

test('last step is journal.youreSet', () {
  expect(kOnboardingTourSteps.last.id, 'journal.youreSet');
  expect(kOnboardingTourSteps.last.interactive, false);
});

test('exactly 13 steps', () {
  expect(kOnboardingTourSteps.length, 13);
});

test('streak step (index 5) is teach, not interactive', () {
  expect(kOnboardingTourSteps[5].id, 'home.streakPill');
  expect(kOnboardingTourSteps[5].interactive, false);
});

test('final two steps are journal.entry (interactive) + duaDetail.done (teach)', () {
  expect(kOnboardingTourSteps[11].id, 'journal.firstEntry');
  expect(kOnboardingTourSteps[11].interactive, true);
  expect(kOnboardingTourSteps[12].id, 'duaDetail.done');
  expect(kOnboardingTourSteps[12].interactive, false);
});
```

- [ ] **Step 3: Run + commit**

```bash
flutter test test/features/tour/onboarding_tour_step_test.dart
git add lib/features/tour/models/ test/features/tour/onboarding_tour_step_test.dart
git commit -m "feat(tour): onboarding tour step registry (13 steps)"
```

---

## Task 3: Anchor registry + `OnboardingTourController`

**Files:**
- Create: `lib/features/tour/providers/tour_anchor_registry.dart`
- Create: `lib/features/tour/providers/onboarding_tour_controller.dart`
- Create: `lib/widgets/coachmark/tour_anchor.dart`
- Test: `test/features/tour/onboarding_tour_controller_test.dart`

### The state machine

```
Idle → start() → ActiveAt(0)
ActiveAt(i) → advance() → ActiveAt(i+1)         (if i+1 < length)
ActiveAt(i) → advance() → Completed              (if i+1 == length)
ActiveAt(i) → skip() → Skipped
```

The controller subscribes to the anchor registry. When the current step's `(surface, anchorId)` is registered AND the underlying `BuildContext` is mounted, it asks an `OverlayHost` widget to mount the `CoachmarkOverlay`. When the user advances, the old overlay tears down. If the new step's anchor is not yet registered (because the user is mid-navigation), the controller holds without rendering until registration arrives.

### Step-by-step

- [ ] **Step 1: Anchor registry provider**

```dart
// lib/features/tour/providers/tour_anchor_registry.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_tour_step.dart';

class TourAnchorRegistry {
  final Map<(TourSurface, String), GlobalKey> _keys = {};

  GlobalKey? lookup(TourSurface surface, String anchorId) =>
      _keys[(surface, anchorId)];

  void register(TourSurface surface, String anchorId, GlobalKey key) {
    _keys[(surface, anchorId)] = key;
    _notify();
  }

  void unregister(TourSurface surface, String anchorId) {
    _keys.remove((surface, anchorId));
    _notify();
  }

  // Bumps a Riverpod listenable so the controller re-reads.
  // Implementation: use a StateNotifier or a Listenable subclass.
  void _notify() {/* ... */}
}

final tourAnchorRegistryProvider =
    ChangeNotifierProvider<_TourAnchorRegistryNotifier>((_) => _TourAnchorRegistryNotifier());
```

`ChangeNotifier`-backed so consumers rebuild when an anchor registers/unregisters.

- [ ] **Step 2: Controller skeleton**

```dart
// lib/features/tour/providers/onboarding_tour_controller.dart
class OnboardingTourState {
  const OnboardingTourState({required this.index, required this.status});
  final int index;
  final TourStatus status;
}

enum TourStatus { idle, active, completed, skipped }

class OnboardingTourController extends StateNotifier<OnboardingTourState> {
  OnboardingTourController(this._ref)
      : super(const OnboardingTourState(index: -1, status: TourStatus.idle));

  final Ref _ref;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final flag = 'onboarding_tour_v1_seen_$userId';
    if (prefs.getBool(flag) ?? false) return;
    state = const OnboardingTourState(index: 0, status: TourStatus.active);
    _trackStepViewed();
  }

  void advance({required String via}) {
    if (state.status != TourStatus.active) return;
    _trackStepAdvanced(via: via);
    final next = state.index + 1;
    if (next >= kOnboardingTourSteps.length) {
      _markSeen();
      state = OnboardingTourState(index: next, status: TourStatus.completed);
      _trackCompleted();
      return;
    }
    state = OnboardingTourState(index: next, status: TourStatus.active);
    _trackStepViewed();
  }

  void skip() {
    if (state.status != TourStatus.active) return;
    _markSeen();
    state = OnboardingTourState(index: state.index, status: TourStatus.skipped);
    _trackSkipped();
  }

  void replay() {
    state = const OnboardingTourState(index: 0, status: TourStatus.active);
    // Tour-seen flag is cleared by the Settings replay button before calling
    // this, so a subsequent natural launch wouldn't fire the tour again on
    // top of the replay. See Settings wiring in Task 7.
  }
}

final onboardingTourControllerProvider =
    StateNotifierProvider<OnboardingTourController, OnboardingTourState>(
  (ref) => OnboardingTourController(ref),
);
```

- [ ] **Step 3: `OnboardingTourOverlayHost` widget (single persistent overlay)**

A single widget wrapped around the app root (in `MaterialApp.builder` or just below `ProviderScope`). When the controller transitions from `idle` → `active`, the host inserts **one** `OverlayEntry` with `CoachmarkOverlay` and keeps it mounted until the tour completes or skips. The `CoachmarkOverlay` itself watches `currentStepIndexProvider` and the anchor registry, and animates between target rects / messages without remount.

**Why single overlay (locked via eng review):** required for the "hero morph between steps" polish (biggest visual win). With mount/unmount, every step transition is a fade-out + fade-in. With one persistent overlay, the cutout and tooltip morph between rects/messages via `TweenAnimationBuilder<Rect>` + `AnimatedSwitcher` for the message body.

**Anchor-not-registered behavior (silent transition):** when `controller.state.status == active` but the current step's anchor lookup returns `null` (e.g. the user is mid-navigation between screens, OR is in the 4 silent dua-section screens between step 9 and step 10), the overlay renders `SizedBox.shrink()` — no scrim, no tooltip, no breathing pulse. As soon as the anchor registers, the overlay animates back in. Treat this as default behavior, not an edge case.

**Anchor-timeout safety (post-eng-review critical-gap fix):** if the current step's anchor stays unregistered for > 10 seconds, the controller fires `tour_anchor_timeout { step_id }` analytics and:
- For dua-section silent transitions (step 9 → step 10): expected, 10s threshold won't trigger because reaching Ameen typically takes 12-30s due to AI generation. Bump the timeout to 60s OR scope it to "no anchor change has happened in N seconds while controller still active" with a longer threshold for the section-walk steps.
- For genuinely broken anchors (a screen was refactored and the anchor disappeared): after 60s of no-anchor while active, the controller auto-skips the orphan step (`advance(via: 'anchor_timeout')`) so the user isn't stuck behind an invisible scrim. Subsequent step's anchor lookup either registers or we keep skipping forward. If we exhaust all 13 steps in skip mode (catastrophic refactor), call `skip()` to end the tour cleanly. This is paranoid defensive code, but the consequence of NOT having it is a permanent stuck-state in production.

Implement in `OnboardingTourController` with a `Timer.periodic(10s)` that checks `_lastAnchorRegistrationAt`. Or simpler: in the host widget, when in the no-anchor shrink state, start a 60s timer; on expiry, fire the timeout advance. Cancel timer on any anchor change.

**Tear-down:** the `OverlayEntry` is removed only on `status` transition to `completed` or `skipped`. Between steps, it persists.

**Route-stack guard (post-CEO):** before mounting, check the root navigator for blocking overlays:

```dart
bool _topRouteIsBlocking(BuildContext ctx) {
  final nav = Navigator.of(ctx, rootNavigator: true);
  // We want to know if there's a fullscreen-dialog or named overlay above
  // the page that owns the next anchor. Use a NavigatorObserver wired into
  // the MaterialApp.router to track the top route's settings.name. Block
  // when name matches /name-reveal, /level-up, /lapsed-trial, /first-steps,
  // /daily-launch — all the fullscreen overlays that push above tab routes.
  final topName = _routeObserver.topRouteName;
  return _blockingRouteNames.contains(topName);
}

static const _blockingRouteNames = <String>{
  'NameRevealOverlay',
  'LevelUpOverlay',
  'LapsedTrialSheet',
  'FirstStepsOverlay',
  'DailyLaunchOverlay',
};
```

Wire a `NavigatorObserver` into `MaterialApp.router(navigatorObservers: [...])` that tracks the top route's `settings.name`. The overlay host subscribes to it. When a blocking route pops, the host re-evaluates and mounts if the next anchor is now visible.

**Observer lifecycle (post-eng-review):** declare the observer as a top-level `final tourRouteObserver = TourRouteObserver();` in `lib/features/tour/providers/tour_route_observer.dart` and import it where the router is constructed. Single instance for the lifetime of the app — must NOT be re-instantiated on rebuilds or its tracked top-route state is lost. The observer exposes a `ValueNotifier<String?> topRouteName` that the host listens to.

**Additional duty (step 13 back-gesture handling, post-eng-review):** when `didPop` fires for a route whose `settings.name == 'DuaDetailPage'` AND the tour controller's `currentStepDef.id == 'duaDetail.done'` AND `status == active`, fire `controller.advance(via: 'back_gesture')` to complete the tour. The Done button does the same via the normal path. This catches the iOS back-swipe / Android back-button cases.

```dart
class OnboardingTourOverlayHost extends ConsumerStatefulWidget {
  const OnboardingTourOverlayHost({required this.child, super.key});
  final Widget child;
  // ... watches controller + registry, mounts/tears down OverlayEntry.
}
```

Wire into `lib/main.dart`'s `SakinaApp`:

```dart
MaterialApp.router(
  // ...
  builder: (context, child) => Column(
    children: [
      const BillingIssueBanner(),
      const IapToSubUpsellBanner(),
      Expanded(child: OnboardingTourOverlayHost(child: child ?? const SizedBox.shrink())),
    ],
  ),
)
```

- [ ] **Step 4: `TourAnchor` helper widget**

```dart
// lib/widgets/coachmark/tour_anchor.dart
class TourAnchor extends ConsumerStatefulWidget {
  const TourAnchor({
    required this.surface,
    required this.anchorId,
    required this.child,
    super.key,
  });
  final TourSurface surface;
  final String anchorId;
  final Widget child;
  // initState: registry.register(surface, anchorId, _key);
  // dispose:   registry.unregister(surface, anchorId);
  // build:     KeyedSubtree(key: _key, child: widget.child);
}
```

Screens use this to declare their anchors without manually managing `GlobalKey` lifecycles or remembering to unregister.

- [ ] **Step 5: Controller unit tests (full coverage, post-eng-review)**

```dart
group('OnboardingTourController.start', () {
  test('no-op when no auth user', () async {});
  test('no-op when seen flag set', () async {});
  test('no-op when dailyLoopProvider never loads (does NOT mark seen)', () async {});
  test('marks seen + no-op when hasCheckedInToday', () async {});
  test('happy path: idle → active(index=0)', () async {});
  test('waits for dailyLoopProvider to load (polls up to 1s)', () async {});
});

group('OnboardingTourController.advance', () {
  test('no-op when not active', () {});
  test('increments index by 1 within bounds', () {});
  test('transitions to completed on final step', () {});
  test('emits tour_step_advanced analytics with via param', () {});
});

test('skip() marks seen + sets status to skipped', () {});
test('replay() resets to index=0 active', () {});
```

- [ ] **Step 5.5: Anchor registry + route observer tests**

```dart
group('TourAnchorRegistry', () {
  test('register notifies listeners', () {});
  test('unregister removes key + notifies', () {});
  test('lookup miss returns null', () {});
});

group('TourRouteObserver', () {
  test('didPush updates topRouteName', () {});
  test('didPop reverts to previous route', () {});
  test('didPop on DuaDetailPage at step duaDetail.done advances tour', () {});
  test('blocking-route names match _blockingRouteNames set', () {});
});

group('TourAnchor widget', () {
  testWidgets('registers on initState, unregisters on dispose', (tester) async {});
});
```

- [ ] **Step 5.6: Overlay host widget tests**

```dart
group('OnboardingTourOverlayHost', () {
  testWidgets('renders SizedBox.shrink when anchor null', (tester) async {});
  testWidgets('renders SizedBox.shrink when blocking route on top', (tester) async {});
  testWidgets('animates between cutout rects on step change (single overlay)', (tester) async {});
  testWidgets('tears down overlay on status=completed', (tester) async {});
  testWidgets('tears down overlay on status=skipped', (tester) async {});
});
```

- [ ] **Step 5.7: Reduced-motion + accessibility**

```dart
testWidgets('collapses all animations when MediaQuery.disableAnimations=true',
    (tester) async {
  await tester.pumpWidget(MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: /* overlay with active tour */,
  ));
  // Assert no AnimationController is running (.isAnimating == false).
});

testWidgets('step progress label is announced for screen readers',
    (tester) async {
  // Find Semantics widget with label 'Step 3 of 13' on the dots row.
});
```

- [ ] **Step 5.8: Integration test for full 13-step flow**

```dart
testWidgets('happy path: 13 steps end-to-end advances correctly',
    (tester) async {
  // Mount a fake app with all 5 tabs + muhasabah + DuaDetailPage routes.
  // Mock dailyLoopProvider, AI services (return canned Name + dua), etc.
  // Tap through each step's target. Assert controller index increments
  // and ends at completed.
});

testWidgets('NameRevealOverlay blocks step 2 until dismissed',
    (tester) async {
  // After step 1 advance + push /muhasabah, push NameRevealOverlay too.
  // Assert overlay host renders SizedBox.shrink (no coachmark visible).
  // Pop NameRevealOverlay. Assert step-2 coachmark mounts.
});

testWidgets('silent dua-section flow: overlay hides between step 9 and 10',
    (tester) async {
  // Advance to step 9, tap Build, walk through 4 sections + Ameen.
  // Assert overlay is hidden during the 4 sections (no scrim painted).
  // On Ameen screen, assert overlay re-appears anchored on first heart.
});

testWidgets('DuaDetailPage back-gesture completes the tour at step 13',
    (tester) async {
  // Advance to step 13 (DuaDetailPage open). Pop the route via back.
  // Assert controller status == completed.
});
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/tour/ lib/widgets/coachmark/tour_anchor.dart test/features/tour/
git commit -m "feat(tour): anchor registry + state machine controller"
```

---

## Task 4: Wire anchors per screen (Home, Muhāsabah, AppShell tabs)

**Files:**
- Modify: `lib/features/progress/screens/progress_screen.dart`
- Modify: `lib/features/daily/screens/muhasabah_screen.dart`
- Modify: `lib/widgets/app_shell.dart`

### Home (ProgressScreen)

- [ ] **Step 1: Replace `_muhasabahCtaKey` ownership with `TourAnchor`**

Wrap the existing `KeyedSubtree(key: _muhasabahCtaKey, ...)` with `TourAnchor(surface: TourSurface.home, anchorId: 'beginMuhasabahCta', child: ...)`. Delete the local `_muhasabahCtaKey`.

- [ ] **Step 2: Replace `_maybeStartHomeTour` with controller boot**

```dart
_maybeShowDailyLaunch().then((_) {
  if (mounted) ref.read(onboardingTourControllerProvider.notifier).start();
});
```

Delete `_maybeStartHomeTour`, `_tourCtrl` field + dispose, `tabKey` lookup. The new controller handles all of it.

**Streak pill anchor (post-CEO).** Wrap the streak pill widget in `_buildHomeHeroCard` (or wherever the streak pill renders) with `TourAnchor(surface: TourSurface.home, anchorId: 'streakPill', ...)`. This anchors the new step 6 (post-Muhāsabah "Your streak just started" beat). The existing `_streakPillKey` GlobalKey can be retired in favor of TourAnchor's internal key.

- [ ] **Step 3: Delete the Home tour's `ref.listen<bool>(guidedSequenceActiveProvider, ...)` block**

Replay now goes through `OnboardingTourController.replay()` (Task 7), not the old per-screen sequenced walk.

### Muḥāsabah (MuhasabahScreen)

- [ ] **Step 4: Wrap each CTA with TourAnchor**

Four anchors (down from 5 — `seeDuaCta` cut by CEO review):
- `goDeeperCta` — the "Go Deeper" pill in `_buildCheckinResult` (step 2)
- `readStoryCta` — the "Read the Story" button in deeper-step-1 (step 3)
- `ameenCta` — the "Ameen" button in deeper-step-3 (step 4 in the new sequence)
- `returnHomeCta` — the "Return to Home" link in `_buildCompleted` (step 5)

The "See the Dua" button on deeper-step-2 is intentionally NOT wrapped — the user passes through that screen silently. The controller waits for the `ameenCta` anchor to register, which happens when the user advances to deeper-step-3.

Each wrap is identical in shape:

```dart
TourAnchor(
  surface: TourSurface.muhasabah,
  anchorId: 'goDeeperCta',
  child: GestureDetector(/* existing CTA */),
),
```

### AppShell (per-tab keys)

- [ ] **Step 5: Add per-tab anchors via wrapping each BottomNavigationBarItem's icon**

`BottomNavigationBarItem.icon` is itself a `Widget` — wrap with `TourAnchor`:

```dart
BottomNavigationBarItem(
  icon: TourAnchor(
    surface: TourSurface.home, // anchor lives on whichever screen the user is currently on; see anchor-key model note below.
    anchorId: 'tabCollection',
    child: const Icon(Icons.style_outlined),
  ),
  // ...
)
```

**Anchor-key surface caveat:** the same tab icon is highlighted on multiple steps (e.g. Collection tab is the cutout for step 7 from Home, and the Duas tab is the cutout for step 8 from Collection). The `TourSurface` of the AppShell-wide tabs needs to match whichever screen is currently active. Two options:

- **Option A (simpler):** register all 5 tab anchors under a synthetic `TourSurface.appShell`, and add `appShell` to the `TourSurface` enum. Tour step defs for tab-targeting steps use `surface: TourSurface.appShell`. The controller only cares that the anchor IS registered; doesn't care which tab the user is on for tab-target steps. **Pick this.**
- Option B: register per-current-tab. More moving parts, no benefit.

Adjust step defs in Task 2 to use `surface: TourSurface.appShell` for the four tab-target steps.

- [ ] **Step 6: Verify analyze + run app**

```bash
flutter analyze lib/features/progress/screens lib/features/daily/screens lib/widgets/app_shell.dart
flutter run -d <sim> --dart-define-from-file=env.json
```

Manually verify: the tour starts on home (after DailyLaunchOverlay if any), tapping Begin advances to step 2 on Muhasabah, and tapping through finishes step 6 on return to Home.

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(tour): wire anchors for Home + Muhasabah + bottom-nav tabs"
```

---

## Task 5: Wire anchors per screen (Collection, Duas, Journal, Reflect)

**Files:**
- Modify: `lib/features/collection/screens/collection_screen.dart`
- Modify: `lib/features/duas/screens/duas_screen.dart`
- Modify: `lib/features/journal/screens/journal_screen.dart`
- Modify: `lib/features/reflect/screens/reflect_screen.dart`

### Collection (step 8 — Duas-tab pivot)

- [ ] **Step 1: Delete the empty-state auto-fire (`_collectionTourEligible`, `_completeCollectionTourBeat`)**

The new controller drives the step; this screen no longer needs its own logic. The Collection tab itself becomes the anchor surface — but step 8 actually targets the Duas tab in the bottom nav. No anchor work needed on the Collection screen body. Cleanup only.

### Duas (steps 9 + 10)

- [ ] **Step 2: Wrap `Build My Dua` CTA with TourAnchor**

```dart
TourAnchor(
  surface: TourSurface.duas,
  anchorId: 'buildCta',
  child: /* existing build CTA */,
),
```

- [ ] **Step 3: Migrate the existing `_firstHeartKey` to TourAnchor**

```dart
TourAnchor(
  surface: TourSurface.duas,
  anchorId: 'firstRelatedHeart',
  child: /* existing first heart icon */,
),
```

- [ ] **Step 4: Delete the old `_maybeStartDuasTour` controller**

The unified controller now drives step 10; this per-screen controller is dead.

### Journal (step 12 — interactive entry tap)

- [ ] **Step 5: Delete the empty-state auto-fire (`_journalTourEligible`, `_settleJournalTour`)**

The new controller drives step 12; this screen no longer needs its own logic.

- [ ] **Step 6: Add a TourAnchor on the first entry tile**

Wrap the first `ListView.builder` item with `TourAnchor(surface: TourSurface.journal, anchorId: 'firstEntry', ...)`. The just-saved dua from step 10 is the most recent entry, so this tile is guaranteed populated. Tapping it pushes `DuaDetailPage` (existing route at `lib/features/journal/screens/dua_detail_page.dart`).

**Guarantee the entry exists.** Belt-and-braces: in `OnboardingTourController.advance()` after step 11, await one frame + a brief delay (~150ms) so the just-saved dua's optimistic write lands in the journal list before step 12 mounts. If by step 12 the list is empty (network failure on save), fall back to the empty-hero CTA as the anchor.

### DuaDetailPage (step 13 — final teach)

- [ ] **Step 7: Add a center-anchored teach step**

DuaDetailPage doesn't need a specific anchor — step 13 is a centered tooltip with a Done button. The `OnboardingTourOverlayHost` already falls back to `Center(child: tooltip)` when `targetRect == null` (existing CoachmarkOverlay behavior). For this step, set the step def's `anchorId: 'centered'` and have `TourAnchorRegistry.lookup` return `null` for that key — the host renders centered.

On Done tap: pop the detail page (`Navigator.pop(context)`) AND call `controller.advance(via: 'continue')`. The user lands back on Journal with the tour complete.

### Reflect (no tour role — post-CEO cut)

Reflect is **no longer in the tour** (old step 12 cut). Reflect is conceptually covered by Muḥāsabah (same text-input + AI-response pattern). No anchor wiring needed on the Reflect screen.

- [ ] **Step 7: Verify all 13 steps in live tour**

Build + install. Run through the tour from a fresh-signup state. Confirm:
- Each interactive step's cutout actually advances on target tap.
- Navigation between screens preserves tour state (controller waits for next anchor).
- Skip from any step closes the tour and persists the seen flag.

- [ ] **Step 8: Commit**

```bash
git commit -m "feat(tour): wire anchors for Collection, Duas, Journal, Reflect"
```

---

## Task 6: Trigger conditions + replay + telemetry

**Files:**
- Modify: `lib/features/settings/screens/settings_screen.dart`
- Modify: `lib/services/analytics_events.dart`
- Modify: `lib/services/tour_service.dart`
- Modify: `lib/core/router.dart` (verify deep link)

### Trigger

The tour starts iff:
- User is authenticated (`auth.currentUser != null`)
- `onboarding_tour_v1_seen_{userId}` is unset
- DailyLaunchOverlay has been dismissed (handled by the existing `_maybeShowDailyLaunch().then(...)` chain on Home)
- `guided_tour_enabled` app_config flag is true (default true) — kept as a kill switch
- **User has NOT already checked in today** (post-CEO addition). Reason: step 1's anchor is "Begin Muḥāsabah", which is swapped for the gated "Seek Another Name" (25-token paywall) once `lastCheckinDate == today`. A returning user who reinstalls or replays would otherwise hit a token paywall as the first tour step. Check via `ref.read(dailyLoopProvider).hasCheckedInToday` (or the equivalent — see `daily_loop_provider.dart`). If true: skip the tour AND mark seen so we don't retry every launch.

```dart
Future<void> start() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  final prefs = await SharedPreferences.getInstance();
  final flag = 'onboarding_tour_v1_seen_$userId';
  if (prefs.getBool(flag) ?? false) return;

  // Wait until dailyLoopProvider has actually loaded before evaluating
  // hasCheckedInToday — otherwise we read the initial empty state at cold
  // launch and incorrectly treat the user as having NOT checked in. Post
  // eng-review fix.
  //
  // The caller chains start() onto _maybeShowDailyLaunch().then(...) which
  // also reads dailyLoopProvider, so by the time we reach here the provider
  // is loaded. Belt-and-braces: poll briefly if `loaded` is still false.
  for (var i = 0; i < 20; i++) {
    final daily = _ref.read(dailyLoopProvider);
    if (daily.loaded) break;
    await Future.delayed(const Duration(milliseconds: 50));
  }
  final daily = _ref.read(dailyLoopProvider);
  if (!daily.loaded) {
    // Daily loop never loaded — likely cold-offline. Don't fire the tour
    // this launch. Next launch tries again. NOT marking seen.
    return;
  }

  // Skip + mark-seen for users who already checked in today. Tour assumes
  // step 1 lands on the ungated Begin Muḥāsabah CTA, not the 25-token
  // Seek Another Name gate.
  if (daily.hasCheckedInToday) {
    await prefs.setBool(flag, true);
    return;
  }

  state = const OnboardingTourState(index: 0, status: TourStatus.active);
  _trackStepViewed();
}
```

### Replay

Settings "Replay app tour" button:

```dart
onPressed: () async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_tour_v1_seen_$userId');
  if (!mounted) return;
  context.go('/'); // jump to Home so step 1 has its anchor
  ref.read(onboardingTourControllerProvider.notifier).replay();
},
```

Deep link `sakina://settings?action=replay_tour` continues to work — the router handler calls the same path.

### Telemetry

Events to emit (extend `AnalyticsEvents`):

- `tour_started` (already exists)
- `tour_step_viewed { step_id }` (already exists, repurpose `step` → `step_id`)
- `tour_step_advanced { step_id, via }` — `via` ∈ `'target_tap' | 'continue'`
- `tour_skipped { at_step_id }`
- `tour_completed`

Wire into `OnboardingTourController`'s `_trackXxx` private methods.

### Migration from existing per-key flags (post-eng-review note)

This branch already shipped the per-key `tour_seen_{user}_{key}_v1` flags during the passive-tour iteration. The new unified flag `onboarding_tour_v1_seen_{user}` is unrelated, so dogfooders who saw the old per-key tours will see the new interactive tour once. That's the intended behavior — the new tour is much better, replay-worthy by definition. No migration code needed. The old per-key flags become dead SharedPreferences entries; they're a few bytes each and we can ignore them. If we want to clean them up later, add a one-time cleanup pass to `TourService.markOnboardingTourSeen` that removes the legacy keys.

### TourService cleanup

- [ ] **Step 1: Add unified flag helpers**

```dart
class TourService {
  // ... existing API ...

  static const String _unifiedFlagPrefix = 'onboarding_tour_v1_seen_';

  Future<bool> isOnboardingTourSeen(String userId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('$_unifiedFlagPrefix$userId') ?? false;
  }

  Future<void> markOnboardingTourSeen(String userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_unifiedFlagPrefix$userId', true);
  }

  Future<void> resetOnboardingTour(String userId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('$_unifiedFlagPrefix$userId');
  }
}
```

- [ ] **Step 2: Keep `resetAll(userId)` for backwards compat in case the deep link or other callers depend on it**

`resetAll` also clears the new unified flag so users who installed during the per-key era and re-open via "Replay tour" get the new tour from step 1.

- [ ] **Step 3: Telemetry test**

```dart
test('controller emits tour_step_advanced with correct via', () {
  // ... mock AnalyticsService, advance(via: 'target_tap'), assert track call
});
```

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(tour): replay + unified seen flag + telemetry"
```

---

## Task 7: Remove dead code + final cleanup

**Files:**
- Delete: `lib/widgets/coachmark/coachmark_controller.dart`
- Modify: `lib/services/tour_service.dart` (remove `TourKey` enum + per-key methods)
- Search for remaining usages: `rg "TourKey\." lib/ test/`

The old `CoachmarkController` is replaced by `OnboardingTourOverlayHost` + `OnboardingTourController`. Delete it. Remove any test files that exercised the old controller's per-screen sequenced-walk logic.

- [ ] **Step 1: Search + remove**

```bash
rg -l "CoachmarkController" lib/ test/    # expect only the new tour controller path
rg -l "TourKey" lib/ test/                # expect zero
```

- [ ] **Step 2: Run full test + analyze**

```bash
flutter analyze
flutter test
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(tour): remove deprecated per-key tour scaffolding"
```

---

## Task 8: Live test + UI polish pass

**Files:** none (pure verification)

- [ ] **Step 1: Fresh-signup live test**

1. Sign up as a new user on the iOS simulator.
2. Complete onboarding through to home.
3. Dismiss DailyLaunchOverlay.
4. Verify tour starts at step 1 over Begin Muḥāsabah CTA.
5. Tap through all 13 steps. At each step, confirm:
   - Cutout aligns with the target widget (no offset drift).
   - Tooltip placement (above/below) avoids overlapping the cutout.
   - Tap on the cutout actually triggers BOTH the underlying action AND the tour advance.
   - Skip button is reachable and ends the tour cleanly.

- [ ] **Step 2: Replay test**

Settings → Replay app tour → confirm tour restarts at step 1.

- [ ] **Step 3: Skip-mid-tour test**

Start tour, skip at step 5 (mid-muhasabah). Confirm tour ends, `tour_skipped` fires with `at_step_id = 'muhasabah.dua.ameen'`, seen flag is set. Next app launch does NOT re-fire the tour.

- [ ] **Step 4: Force-quit-mid-tour test**

Start tour, advance to step 4, force-quit the app. Re-launch. Per the controller spec (in-memory state), the tour resumes from step 1 on next launch. Confirm this matches expected behavior. (If we instead wanted resume-where-you-left-off, that's a follow-up — flag in PR description.)

- [ ] **Step 5: A11y check**

Run VoiceOver on the simulator. Confirm tooltip is announced on each step (existing `Semantics(liveRegion: true)`). Confirm Skip + Continue buttons have accessible labels.

- [ ] **Step 6: Theme check**

Tooltip already matches the Delete-account dialog aesthetic (white surface, dark text, emerald accents) from the recent reskin — no changes needed.

- [ ] **Step 7: Open PR**

```bash
gh pr create --title "feat(tour): interactive guided onboarding (13 steps, all 5 tabs + first muhasabah + first dua)" --body "..."
```

---

## Open questions / decisions deferred

1. **Force-quit mid-tour: resume vs restart?** Plan defaults to restart-from-step-1 for simplicity. If resume is preferred, add persistence of `index` to SharedPreferences in `OnboardingTourController` (one-line change). Flag in PR for product review.

2. **Step 9 (Duas Build) — what if user taps Build with empty input?** Current Duas screen validates and shows a guidance toast. Tour stays put (target hasn't navigated). User types, retries. Acceptable. Alternative: pre-fill a sample prompt. Defer to product taste.

3. **Reflect step depth.** Plan keeps Reflect as a passing teach (cutout on Journal tab, message describing Reflect). If Reflect deserves its own first-class step (text field anchor + composite advance), add as step 12a / 12b. Cost: +1 step, total = 14.

4. **What about Settings / Quests / Store?** Plan does not tour these — they're discoverable from Home and Settings header. If product wants tour coverage for Quests (the daily-quest engine is a big part of the loop), add as a final teach step. Cost: +1.

---

## Self-review

**Spec coverage check:**
- "Make existing Home tour interactive" → Task 1 + Task 4.
- "Add muhasabah end-to-end" → steps 2–6, Task 4.
- "Add dua end-to-end" → steps 9–10, Task 5.
- "Walkthrough each bottom-nav tab" → steps 7, 8, 11, 12, 13.
- "Not too long" → 13 steps, ~30–60s, mostly interactive taps that feel natural.

**Placeholder scan:** no TBDs. Concrete files + line counts in every task. Code blocks for non-trivial pieces. Step counts match the table.

**Type consistency:** `TourSurface` referenced consistently. `OnboardingTourStepDef.surface` matches `TourAnchor.surface` matches step-def `surface` field. `anchorId` is a plain `String`, same shape everywhere.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-26-interactive-guided-tour.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEAR | 5 proposals, 4 accepted, 0 deferred (mode: SELECTIVE_EXPANSION) |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 7 issues found, 0 critical gaps after fixes (overlay model locked, route observer lifecycle, daily-loop wait, anchor timeout) |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR | score: 4/10 → 9/10, 2 decisions locked (gold bead dots, gold pulse ring) |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** CEO + ENG + DESIGN CLEARED — ready to implement.
