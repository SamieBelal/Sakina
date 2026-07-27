# Sacred Canvas Threshold — entrance & exit motion

**Date:** 2026-07-27
**Status:** Design approved, pending implementation plan
**Surfaces:** Muḥāsabah, Reflect, Build-a-Dua

---

## 1. Problem

Every entry into the emerald sacred canvas is a single-frame hard cut. The app is on
warm cream (`AppColors.backgroundLight`, `#FBF7F2`) with a white card and dark ink;
one frame later it is full-bleed emerald (`sacredCanvasGradient`) with cream ink.
That luminance and hue inversion inside 16ms reads as a flash — closer to a rendering
glitch than a doorway. Nothing carries the user across.

The canvas motion *inside* the flow is well built (450ms fade+slide beat advance,
mihrab draw-on, name reveal scale — DESIGN.md §5). The canvas is unpolished only at
its threshold.

### Where the cuts are

| Surface | Entry mechanism | Anchor available? |
|---|---|---|
| Muḥāsabah | Tap *Go Deeper* → `startDeeper()` flips `currentStep` to `deeper`; next frame `build()` returns `BeatRevealFlow` (`muhasabah_screen.dart:132`). AI loads **on** the canvas | **Yes** — the pill is still on screen at the moment of transition |
| Reflect | No button. `inFlow` flips when the AI result lands (`reflect_screen.dart:193`); loading happens on the light screen first | No — result-driven |
| Build-a-Dua | No button. `duas_screen.dart:238-243` swaps the light Scaffold body for `BuiltDuaSectionView`, which brings its own `sacredCanvasGradient` | No — result-driven |

*Go Deeper* is a muḥāsabah-only CTA (`muhasabah_screen.dart:503` is the sole
`startDeeper()` caller besides error-retry). The other two surfaces enter the canvas
with no user gesture at the moment of transition.

### A second cut inside the flow

`BeatRevealFlow._body()` (`beat_reveal_flow.dart:192`) swaps `_LoadingView` for
`_flowView()` with no animation. On the muḥāsabah path the user therefore gets **two**
pops: cream → emerald-loader, then loader → beat 1. Fixing only the first leaves the
entrance ending on a hard cut.

---

## 2. Goals

- One consistent way to cross into and out of the sacred canvas, shared by all three
  surfaces, so the transition reads as house style rather than a muḥāsabah quirk.
- Motion that is calm and short per DESIGN.md §5 — arrival curves, no bounce outside
  the sanctioned name-reveal moment.
- Zero added latency: the AI request must fire on the same frame it does today.

### Non-goals

- Changing any motion *inside* the flow (beat advance, mihrab, name reveal).
- The `onReturnHome` back-out at beat 0 — that goes through `context.go('/')` and
  keeps GoRouter's own transition.
- Any change to gating, analytics, or the AI request lifecycle.

---

## 3. Motion design

### Enter — emerald bloom

The sacred gradient expands as a circle from `origin` until it covers the screen. The
outgoing cream tree sits beneath, fading to 0 and settling `1.0 → 0.98`.

- **700ms**, `Curves.easeOutCubic`.
- Radius animates from 0 to the distance from `origin` to the farthest screen corner.
- `origin` null → screen centre.

The origin rule is **anchored when tap-driven, centre when result-driven**. This is
not per-surface configuration; it falls out of when each surface transitions.
Muḥāsabah enters the canvas on the tap itself (deliberately — the wait is part of the
ritual), so the pill is genuinely under the user's thumb. Reflect and Build-a-Dua
transition *after* a loading screen, where a stale button position would be dishonest;
centre is also where both of their loaders already sit, so the bloom reads as the
loader opening out into the canvas.

### Exit — dissolve

The canvas fades out over the incoming cream tree. **400ms**.

Deliberately *not* a contracting bloom: rewinding the entrance would read as an undo,
which is wrong immediately after Ameen. A dissolve reads as returning gently.

### The gold hairline

The hairline attaches to **the first mount of `BeatProgressBar`**, not to the bloom
landing. Those are different moments on different paths (Reflect enters at `ready`,
muḥāsabah enters at `loading` and has no progress bar yet), so anchoring it to the
bar's own first frame is the one rule that stays self-consistent everywhere.

`BeatProgressBar` already renders 3px `AppColors.secondary` segments on
`sacredTrack`. On first mount it plays `scaleX 0 → 1` from centre plus a fade, **320ms**
`easeOutCubic` — a hairline that widens into the segmented track. Replays are static
(one-shot flag, same pattern as `_playNameEntrance`).

Build-a-Dua has its own `DuaSegmentedProgress` (`built_dua_section_controls.dart`),
also gold on `sacredTrack` but pinned to the *bottom* alongside the Next / Ameen CTA
rather than to the top. It gets the same one-shot treatment on first mount; the sweep
reads identically whichever edge it sits on.

### Loader → beat 1

`BeatRevealFlow._body()` is wrapped in a **350ms** fade `AnimatedSwitcher` so the
loading view dissolves into the first beat.

### Sequencing after Ameen

Existing `_CompletionBeat` runs 1100ms (`beat_reveal_flow.dart:157`), then `onAmeen()`
fires and the threshold dissolves for 400ms — ~1.5s of closing ceremony. If that drags
on device the tuning knob is the completion delay, not the fade.

---

## 4. Component

`lib/widgets/beat_reveal/sacred_canvas_threshold.dart`

```dart
SacredCanvasThreshold({
  required bool onCanvas,   // is the sacred canvas the current child?
  Offset? origin,           // global tap origin; null → screen centre
  required Widget child,    // whatever the host wants to render right now
})
```

An `AnimatedSwitcher`-shaped component keyed on `onCanvas`: both trees stay mounted
for the duration, the stale one is dropped on completion.

The one thing a stock `AnimatedSwitcher` cannot do here is **invert stacking order by
direction**:

- **Enter** — new child (canvas) on top, revealed by an animated `ClipPath`; old child
  (cream) beneath.
- **Exit** — *old* child (canvas) on top, fading out; new child (cream) beneath.

That requires a custom `layoutBuilder` that orders children by transition direction.
Everything else is stock switcher behaviour.

No snapshotting. Both trees are real and mounted, which keeps the component testable
and avoids `RepaintBoundary`/`toImage` timing hazards.

---

## 5. Per-surface wiring

Each host already computes the boolean the threshold needs.

**Muḥāsabah** (`muhasabah_screen.dart`)
- `onCanvas: state.currentStep == DailyLoopStep.deeper`
- A `GlobalKey` on the *Go Deeper* pill; on tap, resolve its `RenderBox` centre to a
  global `Offset`, store it in state, **then** call `startDeeper()` exactly as today.
  The request fires on the same frame; the 700ms plays over the network wait.
- Exit fires on `deeper → completed` (`_buildCompleted`).

**Reflect** (`reflect_screen.dart`)
- `onCanvas: inFlow` (already computed at line 181 for immersive mode)
- `origin: null`
- Exit fires when `reset()` returns the screen to input.

**Build-a-Dua** (`duas_screen.dart`)
- `onCanvas: state.buildResult != null` — already computed at line 215 as `inCanvas`
  for immersive mode; reuse it rather than deriving a second boolean.
- `origin: null`
- Wraps `_buildBuildTab`'s branch, covering both `BuiltDuaSectionView` and
  `BuiltDuaAmeenScreen` (both are canvas states; the threshold does not fire between
  them).
- Exit fires when `buildResult` is cleared.

---

## 6. Reduced motion

`MediaQuery.disableAnimations` collapses both directions to a **150ms** fade, and the
progress-bar hairline to a static mount. Per DESIGN.md §5 this is non-negotiable: no
content may be gated behind an animation that cannot be turned off.

Screen-reader behaviour is unchanged — the threshold is decorative chrome and is
excluded from semantics. The existing per-beat announcements still fire on the same
state changes.

---

## 7. Performance

Both trees mount for the transition window (700ms enter, 400ms exit), and the enter
path clips a full-screen gradient. This is the only real risk in the change, and it is
the kind of thing the simulator will lie about — it must be verified on the physical
device, on the muḥāsabah path specifically, where the outgoing tree is the heaviest
(Name card with shadow + sparkle row).

If the clip proves expensive, the fallback is a `ShaderMask` radial alpha ramp instead
of `ClipPath`, which keeps the same visual and avoids the clip.

---

## 8. Testing

Widget tests:
- Enter completes and unmounts the cream tree.
- Exit completes and unmounts the canvas tree.
- Reduced-motion path completes in the short duration and skips the clip.
- `startDeeper()` fires once, on the tap frame, and is not deferred by the animation.
- Progress-bar hairline plays on first mount and is static on rebuild.

Device QA on all three surfaces, both directions, plus the muḥāsabah
loading → ready dissolve.

---

## 9. Documentation

DESIGN.md §5 gains the threshold timings (700 / 400 / 350 / 320ms) alongside the
existing beat-advance entry.

---

## 10. Deferred

- `onReturnHome` back-out at beat 0 (keeps GoRouter's transition).
- Any transition between Build-a-Dua's section viewer and its Ameen screen — both are
  canvas states and the threshold correctly does not fire between them.
