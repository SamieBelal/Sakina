# Lantern Cosmetics — Plan 3 of 5: Lane C (Render Productionization)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take the validated render spike (skin/backdrop painters) to production quality and lock it against regression — arch-top the glass window for real (no additive-cap seam), make `Backdrop.none` a genuinely plain surface, cut the full-screen backdrop's per-frame cost with `RepaintBoundary` + static-layer separation, and replace the throwaway PNG harnesses with committed `flutter_test` goldens.

**Architecture:** Pure Flutter/Dart — `CustomPainter`s + one thin composition widget. **DB-free**: no Supabase, no RPCs, no service layer, no dependency on Lane A/B. Everything here is verified with `flutter test` (golden tests + a frame-time harness). No app run, no device required for the plan's own gates (the low-end frame-budget number is captured as a repeatable test + a manual on-device note).

**Tech Stack:** Flutter (Dart 3.11 / Flutter 3.41), `CustomPainter`, `flutter_test` + `matchesGoldenFile`.

**Source spec:** `docs/superpowers/specs/2026-07-25-lantern-cosmetics-design.md` — §5 (rendering), §13 items 10 (backdrop perf), 11 (real golden coverage), 12 (`Backdrop.none` fix), and the §5 "arched-window fix (do in P0)" + spike learnings (the additive-cap seam, per-backdrop composition tuning).

**Scope of THIS plan (Lane C only):** arch-top the glass panel; fix `Backdrop.none`; backdrop `RepaintBoundary` + static/animated layer split + a frame-time harness; a committed golden set over skin × backdrop × representative states; a small `CompanionStage` composition widget (backdrop + medallion) that the goldens and Lane D both consume. **Out of scope here:** economy/RPCs (Lane A), client services/sync (Lane B), Companion/wardrobe/share UI beyond the bare `CompanionStage` (Lane D), widget PNG export + Swift lookup (Lane E). No new skins or backdrops are *designed* here — only the existing ones are productionized.

---

## Read first (exact current state — do NOT guess)

The CLAUDE.md design rules apply: gold is a non-text accent only (never mix Arabic/English in one `Text`), light mode is the default surface, and the lantern render must stay share-worthy. Before touching code, read:

- [ ] Read `lib/features/streaks/widgets/lantern_painter.dart` **in full**. Note especially:
  - The `panel` local is an **`RRect`** built at lines ~190-193 (`RRect.fromRectAndRadius(Rect.fromLTRB(...), Radius.circular(s * 0.03))`).
  - Every consumer of `panel`: `canvas.clipRRect(panel)`, `canvas.drawRRect(panel, ...)` (glass fill), `canvas.drawRRect(panel, outline)`, the reflection-streak path (uses `panel.left/top/bottom`), and the `panel.outerRect` passed to `_mashrabiya`, `_flame`, `_khatamLight`, `_dustFilm`, `_cobweb`, `_dustMotes`; plus `_cracks(canvas, panel)` and `_coldGhost(canvas, panel.outerRect)`.
  - `_archedWindow(canvas, s, panel.outerRect, g, metal, outline)` is the **additive cap** (guarded by `if (skin.form.archedWindow)`) drawn AFTER the rectangular panel — it paints a separate arch shape sitting on top of the panel's top edge → the horizontal **seam** at `panel.top`.
  - `shouldRepaint` already compares `skin`, `skin.form`, `glow`, `pulse`, `wear`, `dormant`, `protected`, `ambient`, `ambientShader`.
- [ ] Read `lib/features/streaks/models/lantern_skin.dart` — `LanternForm.archedWindow` (bool), which skins set it (`masjidBrass`, `ramadanRoyal`), and the full skin list (`LanternSkin.all` = 6 recolors, `LanternSkin.sculpted` = 3 heroes).
- [ ] Read `lib/features/streaks/models/backdrop.dart` — `BackdropTheme { laylatNight, emeraldSanctuary }`; `Backdrop.none` currently sets `theme: BackdropTheme.emeraldSanctuary` (**the bug** — `none` renders the full emerald scene); `Backdrop.all = [laylatNight, emeraldSanctuary]` (note: `none` is deliberately excluded from `all`).
- [ ] Read `lib/features/streaks/widgets/backdrop_painter.dart` — the `switch (backdrop.theme)` dispatch, the two scene builders `_laylatNight`/`_emeraldSanctuary`, and the shared helpers (`_skyPattern`, `_skyline`, `_mihrabArch`, `_crescent`, `_vignette`, the 64-star loop, the `pulse`-driven `math.sin(phase)` glow drift + star twinkle). `shouldRepaint` compares `backdrop` + `pulse`.
- [ ] Read `lib/features/streaks/widgets/companion_medallion.dart` — the production wrapper: it already wraps `LanternPainter` in a `RepaintBoundary` + `VisibilityDetector` + bounded `AnimationController`, with `animate:false` producing a static frame (used by the goldens below).
- [ ] Read `test/widgets/gen_skin_showcase_test.dart` + `test/widgets/gen_stage_spike_test.dart` — the spike harnesses that write PNGs to `docs/superpowers/specs/skin-previews/` (NOT goldens). Task 4 supersedes both with real goldens; these two files are deleted in Task 4.

**Facts confirmed for this plan:** the repo has **no** existing goldens, no `test/**/goldens/` dir, and no `flutter_test_config.dart`. `BackdropPainter` is **not yet wired into any widget** (only the painter + the spike harness exist). So this plan introduces the first goldens *and* the first `CompanionStage` composition widget.

## File structure

- **Modify:** `lib/features/streaks/widgets/lantern_painter.dart` — arch-top the panel clip/fill/outline; refactor the `panel`-as-`RRect` call sites to a shared `_GlassPanel` shape; delete the additive `_archedWindow` cap.
- **Modify:** `lib/features/streaks/models/backdrop.dart` — add `BackdropTheme.plain`; point `Backdrop.none` at it.
- **Modify:** `lib/features/streaks/widgets/backdrop_painter.dart` — add `_plain(...)`; split each animated scene into a **static** layer set + an **animated** layer set.
- **Create:** `lib/features/streaks/widgets/backdrop_stage.dart` — `CompanionStage` widget = static backdrop (`RepaintBoundary`, painted once) + animated overlay (`RepaintBoundary`, twinkle/glow drift) + child (the medallion) on top. This is the perf-correct composition Lane D reuses.
- **Create:** `test/widgets/goldens/lantern_skins_golden_test.dart` — skin × brightness goldens (via `CompanionMedallion(animate:false)`).
- **Create:** `test/widgets/goldens/backdrop_golden_test.dart` — each backdrop (incl. `plain`) as a golden.
- **Create:** `test/widgets/goldens/companion_stage_golden_test.dart` — composed skin+backdrop stage goldens.
- **Create:** `test/widgets/backdrop_frame_budget_test.dart` — a repeatable paint-count / frame-time harness for the backdrop stage.
- **Delete:** `test/widgets/gen_skin_showcase_test.dart`, `test/widgets/gen_stage_spike_test.dart` (replaced by the golden set).
- **Committed golden PNGs:** under `test/widgets/goldens/` (generated with `flutter test --update-goldens`, then reviewed + committed).

---

## Task 1: Arch-top the glass window (kill the additive-cap seam) — spec §5 / §13 rough-edge

The fix: for `archedWindow` forms the **glass panel itself** must be arch-topped — one continuous shape that is a rounded rectangle whose *top edge* is replaced by a pointed keel arch — so the clip, the fill, and the outline are all one path with no horizontal seam at `panel.top`. Recolor skins (rectangular window) render byte-identical to today.

**Files:**
- Modify: `lib/features/streaks/widgets/lantern_painter.dart`
- Golden verification: `test/widgets/goldens/lantern_skins_golden_test.dart` (created in Task 4; for THIS task, verify visually via a temporary before/after PNG as described in Step 4, then Task 4 locks it).

- [ ] **Step 1 (RED): add a focused unit test that pins the seam is gone.** A structural test (no image compare needed) — assert the arched panel is ONE closed path whose bounding box top is the arch apex, not the rectangle top. Create `test/widgets/lantern_arched_panel_test.dart`:

```dart
// Verifies the arched-window skins render the glass as a SINGLE arch-topped
// shape (apex above the rectangle top), not a rectangle + an additive cap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/lantern_glass_panel.dart';

void main() {
  const s = 400.0;
  final rect = Rect.fromLTRB(-s * 0.125, -s * 0.05, s * 0.125, s * 0.19);

  test('rectangular panel top edge == rect top (recolor skins)', () {
    final panel = GlassPanel(rect: rect, radius: s * 0.03, arched: false);
    // No arch: the path bounds top equals the rectangle top.
    expect(panel.path.getBounds().top, closeTo(rect.top, 0.5));
  });

  test('arched panel apex rises ABOVE the rectangle top (single shape)', () {
    final panel = GlassPanel(rect: rect, radius: s * 0.03, arched: true);
    final b = panel.path.getBounds();
    // The one continuous path extends above rect.top by the arch rise…
    expect(b.top, lessThan(rect.top - s * 0.10));
    // …while left/right/bottom still match the rectangle (it's the same window).
    expect(b.left, closeTo(rect.left, 0.5));
    expect(b.right, closeTo(rect.right, 0.5));
    expect(b.bottom, closeTo(rect.bottom, 0.5));
  });

  test('arched panel is a single closed contour (no seam sub-path)', () {
    final panel = GlassPanel(rect: rect, radius: s * 0.03, arched: true);
    // A single closed contour → exactly one metric in the path.
    final metrics = panel.path.computeMetrics().toList();
    expect(metrics.length, 1);
    expect(metrics.first.isClosed, isTrue);
  });
}
```

- [ ] **Step 2 (RED run):** `flutter test test/widgets/lantern_arched_panel_test.dart`
  Expected: **FAIL to compile** — `lib/features/streaks/widgets/lantern_glass_panel.dart` and `GlassPanel` do not exist yet.

- [ ] **Step 3 (GREEN — extract the panel shape).** Create `lib/features/streaks/widgets/lantern_glass_panel.dart`:

```dart
// The lantern's glass window as ONE shape. Recolor skins get a plain rounded
// rectangle; arched-window (mihrab) skins get the SAME rectangle whose top edge
// is replaced by a pointed keel arch — a single continuous, closed contour, so
// the clip/fill/outline never leave a seam between "rect glass" and "cap glass".
//
// Replaces the old approach where the window was an RRect + a separate additive
// `_archedWindow` cap painted on top (the visible horizontal seam at panel.top).

import 'dart:ui';

/// A resolved glass-panel geometry. `rect` is the rectangular window bounds;
/// `radius` its corner radius; `arched` swaps the flat top for a keel arch.
class GlassPanel {
  GlassPanel({required this.rect, required this.radius, required this.arched})
      : path = _build(rect, radius, arched);

  final Rect rect;
  final double radius;
  final bool arched;

  /// The single closed contour of the window (rounded rect, or arch-topped).
  final Path path;

  /// Convenience: the rectangular window bounds (unchanged for both forms — the
  /// khatam light, flame, lattice and dust all key off THIS, not the arch rise).
  Rect get innerRect => rect;

  static Path _build(Rect r, double rad, bool arched) {
    if (!arched) {
      return Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(rad)));
    }
    // Arch rise above the rectangle top — matches the old cap proportions
    // (apexY = top - height*0.24; shoulders bow via top - height*0.30).
    final h = r.height;
    final apexY = r.top - h * 0.24;
    final bowY = r.top - h * 0.30;
    // Walk: start below the top-left corner, up the left side, across the keel
    // arch to the apex and down to the top-right, down the right side, across
    // the (rounded) bottom, and close. One contour.
    return Path()
      ..moveTo(r.left, r.bottom - rad)
      ..lineTo(r.left, r.top)
      // left half of the keel arch → apex
      ..quadraticBezierTo(r.left, bowY, r.center.dx, apexY)
      // apex → right shoulder
      ..quadraticBezierTo(r.right, bowY, r.right, r.top)
      ..lineTo(r.right, r.bottom - rad)
      ..quadraticBezierTo(r.right, r.bottom, r.right - rad, r.bottom)
      ..lineTo(r.left + rad, r.bottom)
      ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - rad)
      ..close();
  }
}
```

- [ ] **Step 4 (GREEN — use it in the painter).** In `lantern_painter.dart`:

  1. Add the import at the top with the other local imports:
     ```dart
     import 'lantern_glass_panel.dart';
     ```
  2. Replace the `panel` construction (the `RRect.fromRectAndRadius(Rect.fromLTRB(...))` block, ~lines 190-193) with:
     ```dart
     final panelRect =
         Rect.fromLTRB(-w * 0.66, bodyTop + s * 0.028, w * 0.66, bodyBot - s * 0.03);
     final panel = GlassPanel(
       rect: panelRect,
       radius: s * 0.03,
       arched: skin.form.archedWindow,
     );
     ```
  3. Rewrite the glass block to clip/fill/outline the SINGLE `panel.path`:
     ```dart
     // Glass panel — dark, holds the khatam light (lit) or a cold, cracked
     // ghost of it (dormant). One arch-topped (or rounded-rect) shape.
     canvas.save();
     canvas.clipPath(panel.path);
     canvas.drawPath(
         panel.path, Paint()..color = dormant ? const Color(0xFF0A1116) : skin.glass);
     if (!dormant) {
       if (skin.form.lattice) _mashrabiya(canvas, panel.innerRect);
       _flame(canvas, panel.innerRect, g, phase, breath);
       _khatamLight(canvas, panel.innerRect, g);
       // Glass reflection streak (a dead lamp reflects nothing).
       canvas.drawPath(
         Path()
           ..moveTo(panel.innerRect.left + s * 0.02, panel.innerRect.top)
           ..lineTo(panel.innerRect.left + s * 0.08, panel.innerRect.top)
           ..lineTo(panel.innerRect.left + s * 0.02, panel.innerRect.bottom)
           ..lineTo(panel.innerRect.left - s * 0.04, panel.innerRect.bottom)
           ..close(),
         Paint()..color = Colors.white.withValues(alpha: 0.05),
       );
       if (neglect > 0.05) {
         _dustFilm(canvas, panel.innerRect, neglect);
         _cobweb(canvas, panel.innerRect, neglect, phase);
         _dustMotes(canvas, panel.innerRect, neglect, phase);
       }
     } else {
       _coldGhost(canvas, panel.innerRect);
       _cracks(canvas, panel.innerRect);
       _dustFilm(canvas, panel.innerRect, 1.0);
       _cobweb(canvas, panel.innerRect, 1.0, phase);
       _dustMotes(canvas, panel.innerRect, 1.0, phase);
     }
     canvas.restore();
     canvas.drawPath(panel.path, outline);
     ```
  4. **Delete** the additive-cap call + its guard (the block `if (skin.form.archedWindow) { _archedWindow(...); }`) and the entire `_archedWindow(...)` method.
  5. Change `_cracks` to take a `Rect` (it currently takes `RRect panel` and immediately does `final r = panel.outerRect;`). Update its signature to `void _cracks(Canvas canvas, Rect r) {` and delete the now-dead `final r = panel.outerRect;` line — the body already uses `r`.

  Note: the arch light-bloom that the old `_archedWindow` added inside the cap is now naturally covered — `_khatamLight` + `_flame` already fill the window with light, and the arch is part of the same clipped shape, so the light rises into the arch for free. No separate bloom needed.

- [ ] **Step 5 (GREEN run):** `flutter test test/widgets/lantern_arched_panel_test.dart`
  Expected: **PASS (3/3)**.
  Then `flutter analyze lib/features/streaks/widgets/lantern_painter.dart lib/features/streaks/widgets/lantern_glass_panel.dart` → **No issues** (in particular, no "unused method `_archedWindow`" / no unused `panel.outerRect`).

- [ ] **Step 6 (before/after visual proof — temporary).** Capture a quick before/after so a human can confirm the seam is gone. Create a throwaway `test/widgets/_arch_proof_test.dart` that paints `masjidBrass` (arched) at `glow:1.0` to `/tmp/arch_after.png`; `git stash` the painter change, run it to `/tmp/arch_before.png`, `git stash pop`. Open both, confirm: before has a visible horizontal line across the top of the glass; after is one continuous arch. **Delete `_arch_proof_test.dart` before committing** (the Task 4 golden is the permanent guard). Expected: no seam in the "after" image.

- [ ] **Step 7 (commit):**

```bash
git add lib/features/streaks/widgets/lantern_glass_panel.dart \
        lib/features/streaks/widgets/lantern_painter.dart \
        test/widgets/lantern_arched_panel_test.dart
git commit -m "fix(lantern): arch-top the glass panel itself (remove additive-cap seam)"
```

---

## Task 2: Fix `Backdrop.none` → a genuinely plain surface — spec §13.12

`Backdrop.none` currently maps to `BackdropTheme.emeraldSanctuary`, so "no backdrop" renders the full emerald mihrab scene. Add a real `plain` theme (a quiet warm surface, per the spec's "plain, quiet surface" blurb) and point `none` at it.

**Files:**
- Modify: `lib/features/streaks/models/backdrop.dart`
- Modify: `lib/features/streaks/widgets/backdrop_painter.dart`
- Test: `test/widgets/backdrop_plain_test.dart`

- [ ] **Step 1 (RED):** create `test/widgets/backdrop_plain_test.dart`:

```dart
// Backdrop.none must be a plain surface, NOT the emerald sanctuary scene.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';

void main() {
  test('Backdrop.none uses the plain theme (not emeraldSanctuary)', () {
    expect(Backdrop.none.theme, BackdropTheme.plain);
    expect(Backdrop.none.theme, isNot(BackdropTheme.emeraldSanctuary));
  });

  test('Backdrop.all still excludes none', () {
    expect(Backdrop.all, isNot(contains(Backdrop.none)));
  });
}
```

- [ ] **Step 2 (RED run):** `flutter test test/widgets/backdrop_plain_test.dart`
  Expected: **FAIL to compile** — `BackdropTheme.plain` does not exist.

- [ ] **Step 3 (GREEN — model).** In `backdrop.dart`, extend the enum and repoint `none`:

```dart
enum BackdropTheme { plain, laylatNight, emeraldSanctuary }
```

```dart
  /// The default "no backdrop" — a plain warm surface (used before any is owned).
  static const none = Backdrop(
    id: 'default',
    name: 'None',
    blurb: 'A plain, quiet surface.',
    theme: BackdropTheme.plain,
  );
```

  Leave `Backdrop.all = <Backdrop>[laylatNight, emeraldSanctuary];` unchanged (`none` stays out of the shop list).

- [ ] **Step 4 (GREEN — painter).** In `backdrop_painter.dart`, handle the new case in the dispatch and add the builder. The plain surface is the app's warm cream canvas (`#FBF7F2`, the light-mode default from CLAUDE.md) with a whisper of warm centre-light so the lantern still sits in a soft pool — but no scene, stars, skyline, or arch.

  In `paint`:
```dart
    switch (backdrop.theme) {
      case BackdropTheme.plain:
        _plain(canvas, size);
      case BackdropTheme.laylatNight:
        _laylatNight(canvas, size);
      case BackdropTheme.emeraldSanctuary:
        _emeraldSanctuary(canvas, size);
    }
```

  Add the builder (place it above `_laylatNight`):
```dart
  // ── Plain ─────────────────────────────────────────────────────────────────
  // The genuine "no backdrop": the app's warm cream surface with a soft warm
  // pool where the lantern stands. No scene — quiet, so it reads as "none".
  void _plain(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    // Warm cream base (light-mode canvas), a touch deeper toward the floor.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          const [Color(0xFFFBF7F2), Color(0xFFF3ECE1)],
        ),
    );
    // A soft warm pool under the lantern (no blend-plus needed on a light base).
    final glowC = Offset(w / 2, h * 0.66);
    canvas.drawCircle(
      glowC,
      w * 0.46,
      Paint()
        ..shader = ui.Gradient.radial(glowC, w * 0.46, [
          const Color(0xFFE9C88A).withValues(alpha: 0.16),
          const Color(0xFFE9C88A).withValues(alpha: 0.0),
        ]),
    );
    // Faint floor sheen so the lantern feels grounded, not floating.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.80), width: w * 0.5, height: h * 0.04),
      Paint()
        ..color = const Color(0xFFCBA76A).withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
  }
```

  `_plain` ignores `pulse` (a static surface — nothing to animate), which is exactly what Task 3's static/animated split wants.

- [ ] **Step 5 (GREEN run):** `flutter test test/widgets/backdrop_plain_test.dart`
  Expected: **PASS (2/2)**. `flutter analyze lib/features/streaks/...` → No issues (the `switch` is exhaustive over the 3-value enum).

- [ ] **Step 6 (commit):**

```bash
git add lib/features/streaks/models/backdrop.dart \
        lib/features/streaks/widgets/backdrop_painter.dart \
        test/widgets/backdrop_plain_test.dart
git commit -m "fix(backdrop): Backdrop.none renders a genuinely plain surface"
```

---

## Task 3: Backdrop performance — static/animated layer split + `RepaintBoundary` + frame-budget harness — spec §13.10

The animated scenes repaint gradients, 64 stars, blurs, and blend modes **every `pulse` frame** even though only the star twinkle and the horizon-glow drift actually move. Split each scene into a **static** layer set (painted once, raster-cached) and a small **animated** layer set (the only thing that repaints), compose them in a `CompanionStage` widget with two `RepaintBoundary`s, and add a repeatable frame-budget test.

**Files:**
- Modify: `lib/features/streaks/widgets/backdrop_painter.dart` (split each scene; add a `layer` selector + `pulse` gating in `shouldRepaint`)
- Create: `lib/features/streaks/widgets/backdrop_stage.dart` (`CompanionStage`)
- Test: `test/widgets/backdrop_frame_budget_test.dart`

- [ ] **Step 1 (RED):** create `test/widgets/backdrop_frame_budget_test.dart`. Two guarantees: (a) the **static** painter never repaints on `pulse` change; (b) the **animated** painter repaints on `pulse` change but does NOT repaint when `pulse` is unchanged (the exact property the split buys us).

```dart
// Frame-budget guard for the backdrop stage. The static layer must be
// pulse-independent (raster-cacheable); only the animated layer repaints.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';

void main() {
  final b = Backdrop.laylatNight;

  test('static layer ignores pulse (never repaints as it animates)', () {
    final a = BackdropPainter(backdrop: b, pulse: 0.0, layer: BackdropLayer.static_);
    final c = BackdropPainter(backdrop: b, pulse: 0.5, layer: BackdropLayer.static_);
    expect(a.shouldRepaint(c), isFalse); // pulse changed, static does not care
  });

  test('static layer repaints only when the backdrop identity changes', () {
    final a = BackdropPainter(
        backdrop: Backdrop.laylatNight, pulse: 0.0, layer: BackdropLayer.static_);
    final c = BackdropPainter(
        backdrop: Backdrop.emeraldSanctuary, pulse: 0.0, layer: BackdropLayer.static_);
    expect(a.shouldRepaint(c), isTrue);
  });

  test('animated layer repaints on pulse change, skips when unchanged', () {
    final a = BackdropPainter(backdrop: b, pulse: 0.0, layer: BackdropLayer.animated);
    final moved = BackdropPainter(backdrop: b, pulse: 0.5, layer: BackdropLayer.animated);
    final same = BackdropPainter(backdrop: b, pulse: 0.0, layer: BackdropLayer.animated);
    expect(a.shouldRepaint(moved), isTrue);
    expect(a.shouldRepaint(same), isFalse);
  });

  test('plain backdrop animated layer never repaints (nothing moves)', () {
    final a = BackdropPainter(
        backdrop: Backdrop.none, pulse: 0.0, layer: BackdropLayer.animated);
    final c = BackdropPainter(
        backdrop: Backdrop.none, pulse: 0.9, layer: BackdropLayer.animated);
    expect(a.shouldRepaint(c), isFalse); // plain has no animated content
  });
}
```

- [ ] **Step 2 (RED run):** `flutter test test/widgets/backdrop_frame_budget_test.dart`
  Expected: **FAIL to compile** — `BackdropLayer` and the `layer:` param don't exist.

- [ ] **Step 3 (GREEN — split the painter).** Refactor `backdrop_painter.dart` so a `BackdropPainter` paints only ONE layer, selected by a `layer` enum. Static = base gradient, sky khatam wash, moon+halo, skyline, mihrab arch, floor sheen, vignette (everything geometrically fixed). Animated = the star twinkle + the horizon-glow drift (the only `pulse`-driven strokes).

  1. Add the enum + field:
  ```dart
  /// Which layer this painter renders. Splitting lets the static scene raster-
  /// cache (painted once) while only the animated layer repaints per pulse.
  enum BackdropLayer { static_, animated }
  ```
  ```dart
  class BackdropPainter extends CustomPainter {
    BackdropPainter({
      required this.backdrop,
      this.pulse = 0.0,
      this.layer = BackdropLayer.static_,
    });

    final Backdrop backdrop;
    final double pulse;
    final BackdropLayer layer;
  ```

  2. Rewrite `paint` to dispatch on `(theme, layer)`:
  ```dart
    @override
    void paint(Canvas canvas, Size size) {
      switch (backdrop.theme) {
        case BackdropTheme.plain:
          // Plain is fully static; the animated layer is a no-op.
          if (layer == BackdropLayer.static_) _plain(canvas, size);
        case BackdropTheme.laylatNight:
          layer == BackdropLayer.static_
              ? _laylatNightStatic(canvas, size)
              : _laylatNightAnimated(canvas, size);
        case BackdropTheme.emeraldSanctuary:
          layer == BackdropLayer.static_
              ? _emeraldSanctuaryStatic(canvas, size)
              : _emeraldSanctuaryAnimated(canvas, size);
      }
    }
  ```

  3. Split `_laylatNight` into `_laylatNightStatic` (steps 1,2,4,5,7 of the current body — sky gradient, `_skyPattern`, crescent moon + halo, `_skyline`, floor sheen, `_vignette`) and `_laylatNightAnimated` (steps 3 + 6 — the 64-star twinkle loop, and the warm ground-glow radial whose radius uses `math.sin(phase)`). Keep the exact existing draw code; only move it. The star loop stays as-is (it reads `phase = pulse * 2 * math.pi`). The ground glow at `glowC = Offset(w/2, h*0.72)` with `w * (0.52 + 0.01 * math.sin(phase))` moves into the animated layer.

  4. Split `_emeraldSanctuary` the same way: `_emeraldSanctuaryStatic` = base fill + radial wash + `_skyPattern` + `_mihrabArch` + floor sheen + `_vignette`; `_emeraldSanctuaryAnimated` = only the warm inner-light circle (`w * (0.5 + 0.01 * math.sin(phase))`). If the emerald scene's animated contribution is negligible, still keep the method (empty-but-present is fine) so `shouldRepaint` semantics are uniform — but the emerald glow drift IS pulse-driven, so keep it.

  5. Replace `shouldRepaint`:
  ```dart
    @override
    bool shouldRepaint(BackdropPainter old) {
      if (old.backdrop != backdrop || old.layer != layer) return true;
      // The static layer is pulse-independent; only the animated layer cares.
      if (layer == BackdropLayer.static_) return false;
      // Plain has no animated content → never repaints on pulse.
      if (backdrop.theme == BackdropTheme.plain) return false;
      return old.pulse != pulse;
    }
  ```

- [ ] **Step 4 (GREEN — the stage widget).** Create `lib/features/streaks/widgets/backdrop_stage.dart`:

```dart
// Composes a backdrop + a foreground child (the lantern medallion) with the
// perf split from spec §13.10: the STATIC backdrop layer is painted once inside
// its own RepaintBoundary (raster-cached), the small ANIMATED layer repaints per
// pulse inside a second RepaintBoundary, and the child sits on top. This is the
// production Companion-stage surface; Lane D's CompanionScreen wraps it.

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';

class CompanionStage extends StatefulWidget {
  const CompanionStage({
    super.key,
    required this.backdrop,
    required this.child,
    this.animate = true,
  });

  final Backdrop backdrop;

  /// Foreground (the lantern medallion + status line, supplied by the screen).
  final Widget child;

  /// When false the twinkle/drift never runs (static frame — tests / thumbnails).
  final bool animate;

  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6), // slow, ambient drift
  );
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPulse();
  }

  @override
  void didUpdateWidget(CompanionStage old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate) _syncPulse();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPulse();
  }

  void _syncPulse() {
    final run = widget.animate && _visible && _foreground;
    if (run) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      if (_pulse.isAnimating) _pulse.stop();
    }
  }

  void _onVisibility(VisibilityInfo info) {
    final v = info.visibleFraction > 0.05;
    if (v != _visible) {
      _visible = v;
      _syncPulse();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('companion-stage-${identityHashCode(this)}'),
      onVisibilityChanged: _onVisibility,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static scene — painted once, cached.
          RepaintBoundary(
            child: CustomPaint(
              painter: BackdropPainter(
                backdrop: widget.backdrop,
                layer: BackdropLayer.static_,
              ),
            ),
          ),
          // Animated overlay — the only per-frame repaint.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: BackdropPainter(
                  backdrop: widget.backdrop,
                  pulse: _pulse.value,
                  layer: BackdropLayer.animated,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 5 (GREEN run):** `flutter test test/widgets/backdrop_frame_budget_test.dart`
  Expected: **PASS (4/4)**. `flutter analyze lib/features/streaks/widgets/backdrop_painter.dart lib/features/streaks/widgets/backdrop_stage.dart` → No issues.

- [ ] **Step 6 (frame-time note — manual, on-device).** The `shouldRepaint` test proves the static layer is cache-eligible; the *wall-clock* budget must be confirmed on real low-end hardware (the spec asks for a low-end frame-time + battery read). Add a doc note (not a CI gate — golden/test runs are headless and can't measure GPU raster). Append to this plan's task list a manual check to run once during Lane D device QA:
  - On the lowest-end target device, open the Companion stage with `laylat_night` (the heaviest scene), enable the performance overlay (`flutter run --profile`, `P` in DevTools or `showPerformanceOverlay: true`), and confirm the **raster** thread stays under the 16.6 ms budget with the medallion animating. Record the number in `docs/qa/findings/`. Expected target: raster < 16.6 ms (60 fps) on the low-end device; if it exceeds, the fallback is to drop the star count from 64 → 40 in `_laylatNightAnimated` (a one-line change) — the static/animated split already removes the gradient/skyline/vignette from the per-frame path.

- [ ] **Step 7 (commit):**

```bash
git add lib/features/streaks/widgets/backdrop_painter.dart \
        lib/features/streaks/widgets/backdrop_stage.dart \
        test/widgets/backdrop_frame_budget_test.dart
git commit -m "perf(backdrop): split static/animated layers + RepaintBoundary CompanionStage"
```

---

## Task 4: Real golden regression set (skin × backdrop × states) — spec §13.11 / §8

Replace the two throwaway PNG-writing harnesses with committed `flutter_test` goldens. Coverage: **every skin at `fullyLit` + `dim`** (the two states that carry the material read), **every backdrop** (incl. `plain`), and **a couple of composed stages**. Uses `CompanionMedallion(animate:false)` + `CompanionStage(animate:false)` so frames are deterministic (no pulse), and `matchesGoldenFile`.

**Files:**
- Create: `test/widgets/goldens/lantern_skins_golden_test.dart`
- Create: `test/widgets/goldens/backdrop_golden_test.dart`
- Create: `test/widgets/goldens/companion_stage_golden_test.dart`
- Delete: `test/widgets/gen_skin_showcase_test.dart`, `test/widgets/gen_stage_spike_test.dart`
- Committed reference PNGs under `test/widgets/goldens/`

- [ ] **Step 1 (the `CompanionState` values — confirmed).** The goldens drive `CompanionMedallion`, which takes a `CompanionState`. Its constructor is `CompanionState({required CompanionBrightness brightness, required bool protected})` (from `lib/features/streaks/models/companion_state.dart`) — it does NOT take a raw glow; the `brightness` enum resolves to `CompanionParams(glow, dormant, wear)`. The two states to render are the named enum tiers:
  - **fullyLit:** `const CompanionState(brightness: CompanionBrightness.fullyLit, protected: false)` (`glow: ~1.0`, clean).
  - **dim:** `const CompanionState(brightness: CompanionBrightness.dim, protected: false)` (`glow: ~0.44`, carries the approved worn look — this is why `dim` is one of the two golden states: it exercises the dust/tarnish path).

  In the golden tests below, `<companionStateFullyLit>` = the fullyLit expression above and `<companionStateDim>` = the dim expression above. Add the import `import 'package:sakina/features/streaks/models/companion_state.dart';` (already present in the harnesses) — `CompanionBrightness` and `CompanionState` both come from it. (No open lookup remains; these are the confirmed values.)

- [ ] **Step 2 (RED — skin goldens).** Create `test/widgets/goldens/lantern_skins_golden_test.dart`:

```dart
// Golden regression for every lantern skin at its two material-defining states
// (fullyLit + dim). Static frame (animate:false) → deterministic pixels.
// Regenerate refs with:  flutter test --update-goldens test/widgets/goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';

Widget _harness(LanternSkin skin, CompanionState state) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF17140F),
        body: Center(
          child: SizedBox(
            width: 320,
            height: 320,
            child: CompanionMedallion(
              key: ValueKey('${skin.id}-golden'),
              state: state,   // carries glow/wear/dormant
              skin: skin,     // Lane C adds this passthrough (see NOTE)
              size: 320,
              animate: false, // static hero frame
              ambient: false, // draw only the object, transparent bg
            ),
          ),
        ),
      ),
    );

void main() {
  final skins = [...LanternSkin.all, ...LanternSkin.sculpted];

  for (final skin in skins) {
    testWidgets('skin ${skin.id} · fullyLit', (tester) async {
      await tester.pumpWidget(_harness(skin, <companionStateFullyLit>));
      await tester.pump(const Duration(milliseconds: 16));
      await expectLater(
        find.byType(CompanionMedallion),
        matchesGoldenFile('skins/${skin.id}_fully_lit.png'),
      );
    });

    testWidgets('skin ${skin.id} · dim', (tester) async {
      await tester.pumpWidget(_harness(skin, <companionStateDim>));
      await tester.pump(const Duration(milliseconds: 16));
      await expectLater(
        find.byType(CompanionMedallion),
        matchesGoldenFile('skins/${skin.id}_dim.png'),
      );
    });
  }
}
```

  **NOTE (small passthrough Lane C owns):** `CompanionMedallion` currently constructs `LanternPainter` **without** forwarding a `skin`. To render skins in-widget (needed here *and* by Lane D), add a `final LanternSkin skin;` field to `CompanionMedallion` (default `LanternSkin.classicGold`) and pass `skin: widget.skin` into the `LanternPainter(...)` in its `build`. This is a 3-line additive change with no behavior change for existing call sites (they omit `skin` → default classic). Make this edit as part of Step 4 below; it's within Lane C's `lib/features/streaks/widgets` boundary.

- [ ] **Step 3 (RED — backdrop + stage goldens).** Create `test/widgets/goldens/backdrop_golden_test.dart`:

```dart
// Golden for every backdrop (incl. the plain 'none'), static layer only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/widgets/backdrop_painter.dart';

Widget _harness(Backdrop b) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        child: CustomPaint(
          size: const Size(360, 680),
          painter: BackdropPainter(backdrop: b, layer: BackdropLayer.static_),
        ),
      ),
    );

void main() {
  final backdrops = [Backdrop.none, ...Backdrop.all];
  for (final b in backdrops) {
    testWidgets('backdrop ${b.id}', (tester) async {
      await tester.pumpWidget(_harness(b));
      await expectLater(
        find.byType(CustomPaint).first,
        matchesGoldenFile('backdrops/${b.id}.png'),
      );
    });
  }
}
```

  Create `test/widgets/goldens/companion_stage_golden_test.dart` (a couple of composed stages — the spike's flattering pairings):

```dart
// Composed-stage goldens: skin + backdrop together (static), the two pairings
// the spike judged strongest, so the composition (anchor, contrast) is guarded.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';

Widget _stage(Backdrop b, LanternSkin skin, CompanionState state) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SizedBox(
        width: 360,
        height: 680,
        child: CompanionStage(
          backdrop: b,
          animate: false,
          child: Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CompanionMedallion(
                state: state,
                skin: skin,
                size: 240,
                animate: false,
                ambient: false,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('stage · masjid on laylat night', (tester) async {
    await tester.pumpWidget(
        _stage(Backdrop.laylatNight, LanternSkin.masjidBrass, <companionStateFullyLit>));
    await expectLater(
        find.byType(CompanionStage), matchesGoldenFile('stages/laylat_masjid.png'));
  });

  testWidgets('stage · jade on emerald sanctuary', (tester) async {
    await tester.pumpWidget(
        _stage(Backdrop.emeraldSanctuary, LanternSkin.emeraldJade, <companionStateFullyLit>));
    await expectLater(
        find.byType(CompanionStage), matchesGoldenFile('stages/emerald_jade.png'));
  });
}
```

- [ ] **Step 4 (make the skin passthrough + generate refs).**
  1. Apply the `CompanionMedallion` skin passthrough from Step 2's NOTE (add `final LanternSkin skin;` with `this.skin = LanternSkin.classicGold` default in the constructor + `import '../models/lantern_skin.dart';` + pass `skin: widget.skin` into `LanternPainter`).
  2. Generate the reference images:
     ```
     flutter test --update-goldens test/widgets/goldens
     ```
     Expected: writes PNGs to `test/widgets/goldens/skins/`, `.../backdrops/`, `.../stages/`. Confirm 6+3 = **9 skins × 2 = 18** skin PNGs, **3** backdrop PNGs (`default`, `laylat_night`, `emerald_sanctuary`), **2** stage PNGs.
  3. **Human review** every generated PNG before committing (a golden captures whatever renders — including a bug). Confirm: arched skins (`masjid_brass`, `ramadan_royal`) have a seamless arch (Task 1); `default` backdrop is the plain cream surface (Task 2), not the emerald scene; dim skins read as faint-but-clean (not cobwebbed).

- [ ] **Step 5 (GREEN run — verify goldens pass on a clean run):**
  ```
  flutter test test/widgets/goldens
  ```
  Expected: **all PASS** (each `matchesGoldenFile` compares against the just-committed refs).

- [ ] **Step 6 (delete the spike harnesses).**
  ```bash
  git rm test/widgets/gen_skin_showcase_test.dart test/widgets/gen_stage_spike_test.dart
  ```
  (The `docs/superpowers/specs/skin-previews/` PNGs they wrote are spike artifacts — leave any already-committed ones as historical spec context; the goldens under `test/` are now the regression guard.)

- [ ] **Step 7 (full-suite sanity + commit).**
  ```
  flutter analyze
  flutter test test/widgets
  ```
  Expected: analyze clean for the touched files; `test/widgets` golden + unit tests pass. (The repo has known pre-existing flaky tests elsewhere per MEMORY — do NOT run the whole suite as a gate; scope to `test/widgets`.)

```bash
git add test/widgets/goldens \
        lib/features/streaks/widgets/companion_medallion.dart
git commit -m "test(cosmetics): committed golden set for skins × backdrops × stages"
```

---

## Self-review (done)

- **Spec coverage:**
  - §5 arched-window fix ("glass window itself arch-topped rather than the additive cap … touches the panel clip path + the code that references `panel` as an `RRect`") → **Task 1** (extract `GlassPanel`, single closed contour, refactor every `panel`-as-`RRect` call site, delete `_archedWindow`, `_cracks` now takes a `Rect`).
  - §13.12 fix `Backdrop.none` → **Task 2** (`BackdropTheme.plain` + `_plain`; `none` repointed; `Backdrop.all` still excludes it).
  - §13.10 backdrop perf (`RepaintBoundary` + static-layer separation + low-end frame-time/battery) → **Task 3** (static/animated split, `BackdropLayer`, `pulse`-gated `shouldRepaint`, `CompanionStage` with two `RepaintBoundary`s, plus the repeatable `shouldRepaint` budget test AND the manual on-device profile-overlay note with the 64→40 star fallback).
  - §13.11 / §8 real golden coverage ("skin × backdrop × representative states", "every skin × key state is a committed golden") → **Task 4** (9 skins × {fullyLit, dim}, 3 backdrops incl. plain, 2 composed stages; spike harnesses deleted).
- **DB-free / no cross-lane dependency:** every task is `lib/features/streaks/**` + `test/widgets/**`, verified with `flutter test`/`flutter analyze`. No Supabase, no RPCs, no `env.json`, no app run required for the plan's gates. The one manual step (Task 3 Step 6) is explicitly deferred to Lane D device QA and is not a CI gate.
- **No placeholders:** all painter/model/widget/test code is complete and runnable. The only `<...>` tokens are `<companionStateFullyLit>` / `<companionStateDim>` in the golden tests, and Task 4 Step 1 gives their **exact, confirmed** substitution (`const CompanionState(brightness: CompanionBrightness.fullyLit, protected: false)` and `.dim`) — they're a readability shorthand repeated across three test files, not an unresolved lookup or a TODO.
- **Type / name consistency:**
  - `GlassPanel` exposes `path` (the single contour) + `innerRect` (the rectangular window all light/dust keys off). Every former `panel.outerRect` becomes `panel.innerRect`; every `clipRRect(panel)` / `drawRRect(panel, …)` becomes `clipPath(panel.path)` / `drawPath(panel.path, …)`. `_cracks` signature changed `RRect → Rect` to match.
  - `BackdropLayer { static_, animated }` (trailing underscore because `static` is a Dart reserved word) is used consistently in the painter, the stage widget, and the frame-budget test.
  - `BackdropTheme { plain, laylatNight, emeraldSanctuary }` — the `switch` in `paint` is exhaustive (no `default`), so adding `plain` forces the compiler to confirm all three cases handled.
  - `CompanionMedallion` gains a `skin` field (default `classicGold`) — additive, existing call sites unaffected; this is the passthrough the goldens + Lane D need, and it lives inside Lane C's widget boundary.
  - Golden paths are relative to the test file (`skins/…`, `backdrops/…`, `stages/…` under `test/widgets/goldens/`), matching `flutter test --update-goldens test/widgets/goldens`.
- **Rigor matched to Plan 1:** every task is RED (write/adjust test) → run-and-see-fail → GREEN (implement) → run-and-see-pass → commit, with exact commands and expected output; commit messages scoped per task.

## Dependency notes for the other lanes

- **Lane D (UI)** consumes `CompanionStage` (Task 3) and the `CompanionMedallion.skin` passthrough (Task 4) as-is — do not re-invent the stage. The wardrobe live-preview is `CompanionStage(animate:true, child: CompanionMedallion(skin: previewed, …))`.
- **Lane E (widget)** is unblocked by Task 1 (the arched panel is now a clean single shape, so the exported PNG frames won't carry the seam) but otherwise independent; it renders via the painter, not `CompanionStage` (backdrops are excluded from the widget per §5/§11).
- **No conflict with Lane A/B:** nothing here reads or writes economy state, the equip contract, or sync. Which skin/backdrop is *equipped* is resolved by Lane B/D and passed into these widgets as plain parameters.
