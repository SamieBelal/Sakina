# Tiered Card Reveal Animations — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the approved Emerald "legendary" reveal spike into a **tiered reveal system** where Bronze/Silver/Gold/Emerald each get a polished gacha-style open→burst→card animation whose spectacle escalates with rarity — Emerald stays the nicest — and wire it into the real muḥāsabah flow, replacing the legacy `NameRevealOverlay`.

**Architecture:** Extract the hardcoded Emerald values from `emerald_reveal_spike.dart` into a data-driven `RevealSpec` (one per `CardTier`). Rename the widget to `CardRevealOverlay`, which reads a spec and toggles/scales each FX layer (god-rays, burst shafts, aurora, foil, halo, motes, lens-flare, spin turns, haptics, duration). The shared normalized timeline (0→1 `_seg` windows) is reused across tiers; only wall-clock duration and feature intensities change. The card face is the tier's existing ornate tile; a shared card-back is tinted per tier. Emerald's spec reproduces today's spike **exactly** (regression guard).

**Tech Stack:** Flutter (Dart) · Riverpod · custom `CustomPainter` FX (native, no new Lottie) · `CompanionMedallion`/`LanternPainter` (existing lantern) · Mixpanel via the `onAnalyticsEvent` hook.

---

## Background & current state

- The working spike lives in `lib/features/daily/widgets/emerald_reveal_spike.dart` (`EmeraldRevealSpike`). It is **native**, self-contained, and driven by one `AnimationController` (`_reveal`, 7000ms) plus a looping `_ambient` controller. Every beat is a `_seg(t, a, b)` window.
- Emerald FX layers already built and approved: atmosphere (darken + emerald pool + vignette), lantern god-rays (`_LanternRaysPainter`), aurora (`_AuroraPainter`), burst flash + radial shafts + rings (`_BurstPainter`), sparks with trails (`_SparkPainter`), halo (`_HaloPainter`), floating motes (`_MotePainter`), holographic foil + specular glint (`_FoilPainter`), lens-flare (`_LensFlarePainter`), shine sweep (`_ShineSweepPainter`), "forged from light" birth overexposure, settle overshoot, ratchet haptics, staggered/shimmer caption.
- The vessel is the real `CompanionMedallion` lantern (starts `pendingUnlit`, ignites to `glowing` on tap, `ambient: false`).
- **Legacy reveal being replaced:** `lib/features/daily/widgets/name_reveal_overlay.dart` (`NameRevealOverlay`) — a single-Lottie light burst, tier-blind. Pushed from `muhasabah_screen.dart` when `cardEngageResult.tierChanged` rises (see `muhasabah_screen.dart:85-114`, `:269-298`).
- **Tier outcome source:** `discoverName()` in `daily_loop_provider.dart:485` sets `cardEngageResult` = `CardEngageResult` whose `.tier` (`CardTierX.fromNumber`) is the outcome tier. `engageResult.tierChanged` = a new card (Bronze) or a tier-up (Silver/Gold/Emerald); `isDuplicate` = no change (token awarded).
- **Tier colors** (`CardTier.colorValue`, `card_collection_service.dart:62`): Bronze `0xFFCD7F32`, Silver `0xFFA8A9AD`, Gold `0xFFC8985E`, Emerald `0xFF50C878`.
- **Ornate tile widgets** (the card face per tier): `BronzeOrnateTile` (`bronze_ornate_card.dart`), `SilverOrnateTile`/preview (`silver_card_preview.dart`), `GoldOrnateTile` (`gold_ornate_card.dart`), `EmeraldOrnateTile` (`emerald_ornate_card.dart`). All take `CollectibleName card` and are `AspectRatio(0.72)`.
- **Temp debug scaffolding to remove at the end:** the `TEMP-REVEAL-DEBUG` block in `lib/main.dart` (`_SakinaAppState.initState`) that auto-launches the reveal, and its two imports (`emerald_reveal_spike.dart`, `achievement_toast.dart`).
- **Simulator caveat:** idb HID taps are broken on this machine — verify interactive taps with the mouse in Simulator, or use the `autoStart` loop flag for headless frame capture. Screenshots must be `sips -Z 1600` immediately (CLAUDE.md).

**Design guardrails (do not violate):**
- Do not fork/recolor the shared `LanternPainter` flame — it's the companion identity. Tier color lives only in **our** aura/rays/burst layers.
- Silent (haptics only) — no audio.
- Respect reduced-motion (see Task 9).
- Never mix Arabic + English in one `Text` widget (CLAUDE.md); the ornate tiles already handle this.

---

## Tier escalation table (the spec values)

| Field | Bronze (new) | Silver | Gold | Emerald (premium) |
|---|---|---|---|---|
| `duration` (ms) | 2400 | 3600 | 5000 | 7000 |
| `spinTurns` | 0 (no spin) | 1 | 2 | 3 |
| `godRays` (0-1) | 0.25 | 0.5 | 0.75 | 1.0 |
| `radialShafts` | 0.0 | 0.0 | 0.6 | 1.0 |
| `aurora` | 0.0 | 0.25 | 0.6 | 1.0 |
| `halo` | false | false | false | **true** |
| `foil` | 0.0 | 0.0 | 0.5 | 1.0 |
| `restMotes` | 0.15 | 0.4 | 0.7 | 1.0 |
| `lensFlare` | 0.0 | 0.3 | 0.7 | 1.0 |
| `shineSweep` | false | true | true | true |
| `forgeBirth` | false | true | true | true |
| `sparkCount` | 8 | 14 | 22 | 30 |
| `haptics` | `light` | `medium` | `rich` | `legendary` |

**Read:** Bronze = fast, tasteful pop (ignite → small burst → card fades/scales in → settle). Each tier up adds a real capability (flip → shine → foil+shafts+aurora → full spin+halo+forge). Emerald keeps every feature at max and is the only tier with the halo and full holographic foil.

**Motion by `spinTurns`:** `0` → `fadeScale` (no rotation, no card-back; card scales+fades from the burst). `>0` → the existing spin code (`angle = (1-spinT) * spinTurns * 2π`) with front/back swap; overshoot wobble applies to all spinning tiers.

---

## File Structure

- **Create** `lib/features/daily/models/reveal_spec.dart` — `RevealSpec`, `HapticProfile` enum, `revealSpecFor(CardTier)` map, `tierPalette(CardTier)`.
- **Create** `lib/features/daily/widgets/card_reveal_overlay.dart` — `CardRevealOverlay` (generalized from the spike; reads a `RevealSpec`). Move the painters here.
- **Create** `lib/features/daily/widgets/reveal_card_tile.dart` — `revealCardTile(CollectibleName, CardTier)` returns the correct ornate tile; `RevealCardBack(tier)` tinted per tier.
- **Delete** `lib/features/daily/widgets/emerald_reveal_spike.dart` (superseded by `card_reveal_overlay.dart`).
- **Modify** `lib/features/settings/screens/dev_tools_screen.dart` — Reveal Previews: one button per tier.
- **Modify** `lib/features/daily/screens/muhasabah_screen.dart` — push `CardRevealOverlay` with `revealSpecFor(engageResult.tier)` instead of `NameRevealOverlay`.
- **Modify** `lib/services/analytics_event_names.dart` — add `cardRevealShown`, `cardRevealCompleted`.
- **Modify** `lib/main.dart` — remove the `TEMP-REVEAL-DEBUG` block + its two imports.
- **Delete** `lib/features/daily/widgets/name_reveal_overlay.dart` — after the muḥāsabah swap + its test is updated.
- **Test** `test/features/daily/reveal_spec_test.dart`, `test/features/daily/card_reveal_overlay_test.dart`.

---

## Task 1: `RevealSpec` model + per-tier map

**Files:**
- Create: `lib/features/daily/models/reveal_spec.dart`
- Test: `test/features/daily/reveal_spec_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/daily/reveal_spec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/models/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';

void main() {
  test('every tier has a spec and escalates', () {
    final b = revealSpecFor(CardTier.bronze);
    final s = revealSpecFor(CardTier.silver);
    final g = revealSpecFor(CardTier.gold);
    final e = revealSpecFor(CardTier.emerald);

    // Duration escalates strictly.
    expect(b.duration < s.duration, isTrue);
    expect(s.duration < g.duration, isTrue);
    expect(g.duration < e.duration, isTrue);

    // Spin escalates; Bronze does not spin.
    expect(b.spinTurns, 0);
    expect([s.spinTurns, g.spinTurns, e.spinTurns], [1, 2, 3]);

    // Emerald exclusives.
    expect(e.halo, isTrue);
    expect(b.halo || s.halo || g.halo, isFalse);
    expect(e.foil, 1.0);

    // Tier colour matches the card system.
    expect(e.tierColor.toARGB32(), CardTier.emerald.colorValue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/daily/reveal_spec_test.dart`
Expected: FAIL — `reveal_spec.dart` does not exist.

- [ ] **Step 3: Write the model + map**

```dart
// lib/features/daily/models/reveal_spec.dart
import 'package:flutter/material.dart';
import 'package:sakina/services/card_collection_service.dart';

/// Escalating haptic richness. Resolved to a concrete schedule in the overlay.
enum HapticProfile { light, medium, rich, legendary }

/// A tier's signature colours (used only in OUR fx layers, never the lantern flame).
class TierPalette {
  const TierPalette({required this.color, required this.bright, required this.glow});
  final Color color; // base signature (CardTier.colorValue)
  final Color bright; // lighter accent
  final Color glow; // additive glow accent
}

TierPalette tierPalette(CardTier tier) {
  switch (tier) {
    case CardTier.bronze:
      return const TierPalette(
        color: Color(0xFFCD7F32), bright: Color(0xFFE8A154), glow: Color(0xFFF0B36A));
    case CardTier.silver:
      return const TierPalette(
        color: Color(0xFFA8A9AD), bright: Color(0xFFD8DBE0), glow: Color(0xFFEDEFF3));
    case CardTier.gold:
      return const TierPalette(
        color: Color(0xFFC8985E), bright: Color(0xFFEDD9A3), glow: Color(0xFFE8C56D));
    case CardTier.emerald:
      return const TierPalette(
        color: Color(0xFF50C878), bright: Color(0xFF7EEAAF), glow: Color(0xFF4AE68A));
  }
}

/// Data-driven description of a tier's reveal. The overlay reads this to toggle
/// and scale every fx layer; the normalized timeline windows are shared.
class RevealSpec {
  const RevealSpec({
    required this.tier,
    required this.duration,
    required this.spinTurns,
    required this.godRays,
    required this.radialShafts,
    required this.aurora,
    required this.halo,
    required this.foil,
    required this.restMotes,
    required this.lensFlare,
    required this.shineSweep,
    required this.forgeBirth,
    required this.sparkCount,
    required this.haptics,
  });

  final CardTier tier;
  final Duration duration;
  final int spinTurns; // 0 = fade/scale in (no rotation)
  final double godRays; // 0-1 lantern ignite ray intensity
  final double radialShafts; // 0-1 burst shafts
  final double aurora; // 0-1 sustained aurora
  final bool halo; // rest halo ring (emerald flex)
  final double foil; // 0-1 holographic foil
  final double restMotes; // 0-1 floating embers
  final double lensFlare; // 0-1 settle flare
  final bool shineSweep;
  final bool forgeBirth; // white-hot "forged from light" entrance
  final int sparkCount;
  final HapticProfile haptics;

  bool get spins => spinTurns > 0;
  TierPalette get palette => tierPalette(tier);
}

RevealSpec revealSpecFor(CardTier tier) {
  switch (tier) {
    case CardTier.bronze:
      return const RevealSpec(
        tier: CardTier.bronze,
        duration: Duration(milliseconds: 2400),
        spinTurns: 0, godRays: 0.25, radialShafts: 0.0, aurora: 0.0,
        halo: false, foil: 0.0, restMotes: 0.15, lensFlare: 0.0,
        shineSweep: false, forgeBirth: false, sparkCount: 8,
        haptics: HapticProfile.light,
      );
    case CardTier.silver:
      return const RevealSpec(
        tier: CardTier.silver,
        duration: Duration(milliseconds: 3600),
        spinTurns: 1, godRays: 0.5, radialShafts: 0.0, aurora: 0.25,
        halo: false, foil: 0.0, restMotes: 0.4, lensFlare: 0.3,
        shineSweep: true, forgeBirth: true, sparkCount: 14,
        haptics: HapticProfile.medium,
      );
    case CardTier.gold:
      return const RevealSpec(
        tier: CardTier.gold,
        duration: Duration(milliseconds: 5000),
        spinTurns: 2, godRays: 0.75, radialShafts: 0.6, aurora: 0.6,
        halo: false, foil: 0.5, restMotes: 0.7, lensFlare: 0.7,
        shineSweep: true, forgeBirth: true, sparkCount: 22,
        haptics: HapticProfile.rich,
      );
    case CardTier.emerald:
      return const RevealSpec(
        tier: CardTier.emerald,
        duration: Duration(milliseconds: 7000),
        spinTurns: 3, godRays: 1.0, radialShafts: 1.0, aurora: 1.0,
        halo: true, foil: 1.0, restMotes: 1.0, lensFlare: 1.0,
        shineSweep: true, forgeBirth: true, sparkCount: 30,
        haptics: HapticProfile.legendary,
      );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/daily/reveal_spec_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/daily/models/reveal_spec.dart test/features/daily/reveal_spec_test.dart
git commit -m "feat(reveal): add RevealSpec + per-tier escalation map"
```

---

## Task 2: Tier card-tile + tinted card-back selector

**Files:**
- Create: `lib/features/daily/widgets/reveal_card_tile.dart`
- Verify tile class names: `grep -n "class .*OrnateTile\|class .*PreviewTile\|class SilverCard" lib/features/collection/widgets/*.dart`

- [ ] **Step 1: Confirm the four tile widget class names**

Run: `grep -rn "class " lib/features/collection/widgets/bronze_ornate_card.dart lib/features/collection/widgets/silver_card_preview.dart lib/features/collection/widgets/gold_ornate_card.dart lib/features/collection/widgets/emerald_ornate_card.dart | grep -i tile`
Expected: prints the exact tile classes (e.g. `BronzeOrnateTile`, `SilverOrnateTile`, `GoldOrnateTile`, `EmeraldOrnateTile`). Use the printed names below; if Silver's tile differs, substitute it.

- [ ] **Step 2: Write the selector + tinted back**

```dart
// lib/features/daily/widgets/reveal_card_tile.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sakina/features/collection/widgets/bronze_ornate_card.dart';
import 'package:sakina/features/collection/widgets/silver_card_preview.dart';
import 'package:sakina/features/collection/widgets/gold_ornate_card.dart';
import 'package:sakina/features/collection/widgets/emerald_ornate_card.dart';
import 'package:sakina/features/daily/models/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';

/// The card FACE for a reveal — the tier's real collection tile.
Widget revealCardTile(CollectibleName card, CardTier tier) {
  switch (tier) {
    case CardTier.bronze:
      return BronzeOrnateTile(card: card);
    case CardTier.silver:
      return SilverOrnateTile(card: card); // substitute if grep shows another name
    case CardTier.gold:
      return GoldOrnateTile(card: card);
    case CardTier.emerald:
      return EmeraldOrnateTile(card: card);
  }
}

/// A shared card BACK, tinted per tier (shown only for spinning tiers).
class RevealCardBack extends StatelessWidget {
  const RevealCardBack({super.key, required this.tier});
  final CardTier tier;

  @override
  Widget build(BuildContext context) {
    final p = tierPalette(tier);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.1,
          colors: [p.color.withValues(alpha: 0.35), const Color(0xFF0F1F16)],
        ),
        border: Border.all(color: p.bright.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(color: p.glow.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: CustomPaint(painter: _BackPainter(p)),
    );
  }
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.p);
  final TierPalette p;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.30;
    final line = Paint()
      ..color = p.bright.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, line);
    }
    canvas.drawCircle(c, r * 0.62, line..strokeWidth = 1.0);
    canvas.drawCircle(c, 3, Paint()..color = p.bright);
  }

  @override
  bool shouldRepaint(covariant _BackPainter old) => false;
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze --no-pub lib/features/daily/widgets/reveal_card_tile.dart`
Expected: No issues (fix the Silver class name if analyzer reports it undefined).

- [ ] **Step 4: Commit**

```bash
git add lib/features/daily/widgets/reveal_card_tile.dart
git commit -m "feat(reveal): tier card-face selector + tinted card back"
```

---

## Task 3: Generalize the spike into `CardRevealOverlay(spec)`

**Files:**
- Create: `lib/features/daily/widgets/card_reveal_overlay.dart` (from `emerald_reveal_spike.dart`)
- Delete: `lib/features/daily/widgets/emerald_reveal_spike.dart`

- [ ] **Step 1: Copy the spike file to the new path**

```bash
git mv lib/features/daily/widgets/emerald_reveal_spike.dart lib/features/daily/widgets/card_reveal_overlay.dart
```

- [ ] **Step 2: Rename the widget + take a `RevealSpec`**

In `card_reveal_overlay.dart`, rename `EmeraldRevealSpike` → `CardRevealOverlay` and `_EmeraldRevealSpikeState` → `_CardRevealOverlayState`. Add the spec field and derive the palette:

```dart
class CardRevealOverlay extends StatefulWidget {
  const CardRevealOverlay({
    super.key,
    required this.card,
    required this.spec,
    this.onContinue,
    this.autoStart = false,
  });

  final CollectibleName card;
  final RevealSpec spec;
  final VoidCallback? onContinue;
  final bool autoStart;

  @override
  State<CardRevealOverlay> createState() => _CardRevealOverlayState();
}
```

Replace the hardcoded `_revealDuration`/`_spinTurns` constants with spec reads:

```dart
Duration get _revealDuration => widget.spec.duration;
int get _spinTurns => widget.spec.spinTurns;
```

Add palette shorthands used by the layers (replace the module-level `_emeraldBright`/`_glow`/`_emeraldCore` **inside the state's build/layers** with palette-derived locals; keep the module constants only for `_canvas`, `_gold`, `_goldBright` which are tier-neutral):

```dart
Color get _tColor => widget.spec.palette.color;
Color get _tBright => widget.spec.palette.bright;
Color get _tGlow => widget.spec.palette.glow;
```

- [ ] **Step 3: Thread the spec into every layer**

Update `build()` to pass spec-driven values. Each layer already accepts an intensity/opacity — multiply by the spec toggle. Concretely:
- Lantern rays: `grow: _seg(t,0.05,0.34) * spec.godRays`, `color: _tGlow`.
- Aurora: multiply `opacity` by `spec.aurora`; pass `bright: _tBright` (add a color param to `_AuroraPainter` — replace the hardcoded `_emeraldBright`/`_goldBright` alternation with `[_tBright, _goldBright]`).
- Burst: `shafts: _bell(_seg(t,0.40,0.56)) * spec.radialShafts`; pass `_tBright` into the flash/shafts colors (add a `color` param).
- Sparks: build the spark list from `spec.sparkCount` (see Step 4); pass `_tBright`.
- Halo: only include the layer `if (spec.halo && t > 0.80)`.
- Motes: multiply `opacity` by `spec.restMotes`; include `if (spec.restMotes > 0 && t > 0.80)`; pass tier colors.
- Atmosphere: pass `pool` color = `_tColor` (add a color param; replace `_emeraldCore`).
- Card: pass `spec` to `_buildCard`; see Task 4 for spin/no-spin + foil/shine/flare/forge gating.
- Caption: badge text = `spec.tier.label.toUpperCase()`; badge/border colors from palette.

- [ ] **Step 4: Make the spark list spec-sized**

Replace `final List<_Spark> _sparks = _buildSparks(30);` with:

```dart
late final List<_Spark> _sparks = _buildSparks(widget.spec.sparkCount);
```

- [ ] **Step 5: Add color params to the shared painters**

Add a `Color color` (and where used `Color bright`) parameter to `_AuroraPainter`, `_BurstPainter`, `_SparkPainter`, `_MotePainter`, `_HaloPainter`, `_AtmospherePainter`, and the card overlays (`_FoilPainter`, `_LensFlarePainter`, `_ShineSweepPainter` may stay white). Default nothing — pass explicitly from `build()`. Replace internal `_emeraldBright`/`_emeraldCore`/`_glow` references with the passed colors. Keep `_goldBright` as the shared warm accent.

- [ ] **Step 6: Resolve haptics from the profile**

Replace the fixed `_scheduleHaptics` body with a profile switch:

```dart
void _scheduleHaptics() {
  void at(double frac, VoidCallback fn) =>
      Future.delayed(_revealDuration * frac, () { if (mounted) fn(); });

  switch (widget.spec.haptics) {
    case HapticProfile.light:
      at(0.30, HapticFeedback.selectionClick);
      at(0.55, HapticFeedback.mediumImpact); // small pop
      at(0.90, HapticFeedback.lightImpact);
      break;
    case HapticProfile.medium:
      at(0.25, HapticFeedback.selectionClick);
      at(0.48, HapticFeedback.heavyImpact); // burst
      at(0.70, HapticFeedback.selectionClick);
      at(0.90, HapticFeedback.lightImpact);
      break;
    case HapticProfile.rich:
      at(0.22, HapticFeedback.selectionClick);
      at(0.44, HapticFeedback.heavyImpact);
      for (final f in [0.56, 0.64, 0.72, 0.80]) at(f, HapticFeedback.selectionClick);
      at(0.88, HapticFeedback.heavyImpact);
      at(0.96, HapticFeedback.lightImpact);
      break;
    case HapticProfile.legendary:
      // the tuned Emerald ratchet (unchanged from the approved spike)
      at(0.18, HapticFeedback.selectionClick);
      at(0.30, HapticFeedback.selectionClick);
      at(0.42, HapticFeedback.heavyImpact);
      for (final f in [0.50, 0.56, 0.62, 0.68]) at(f, HapticFeedback.selectionClick);
      at(0.74, HapticFeedback.lightImpact);
      at(0.80, HapticFeedback.lightImpact);
      at(0.86, HapticFeedback.heavyImpact);
      at(0.96, HapticFeedback.lightImpact);
      break;
  }
}
```

- [ ] **Step 7: Update the debug launcher import in main.dart to the new class**

The temp block references `EmeraldRevealSpike`. Update it to `CardRevealOverlay(card: allCollectibleNames.first, spec: revealSpecFor(CardTier.emerald), autoStart: true, onContinue: nav.pop)` and add `import '...reveal_spec.dart'`. (This whole block is removed in Task 8; keep it working until then.)

- [ ] **Step 8: Verify Emerald is byte-for-behavior identical**

Run: `flutter analyze --no-pub lib/features/daily/widgets/card_reveal_overlay.dart lib/main.dart`
Expected: No issues.
Then device-QA (Dev Tools → Emerald, or the temp auto-launch): the Emerald reveal must look **identical** to the approved spike. Since Emerald's spec has every toggle at max, all multiplications are `* 1.0` and `spec.halo == true`, so nothing changes.

- [ ] **Step 9: Commit**

```bash
git add lib/features/daily/widgets/card_reveal_overlay.dart lib/main.dart
git commit -m "refactor(reveal): generalize spike into CardRevealOverlay(spec); emerald unchanged"
```

---

## Task 4: Motion + fx gating by spec in `_buildCard`

**Files:**
- Modify: `lib/features/daily/widgets/card_reveal_overlay.dart` (`_buildCard`, `_CardFace`)

- [ ] **Step 1: Gate spin vs fade-scale**

In `_buildCard`, branch on `widget.spec.spins`:

```dart
final spec = widget.spec;
final appear = Curves.easeOutBack.transform(_seg(t, 0.46, 0.58));
double angle = 0;
bool facingFront = true;
double spinTilt = 0;
double foilPhase = _ambient.value;
if (spec.spins) {
  final spinT = Curves.easeOutCubic.transform(_seg(t, 0.49, 0.86));
  final land = _seg(t, 0.86, 1.0);
  final wobble = math.sin(land * math.pi * 2.4) * (1 - land) * 0.11;
  angle = (1 - spinT) * spec.spinTurns * 2 * math.pi + wobble;
  facingFront = math.cos(angle) >= 0;
  spinTilt = math.sin(angle);
  foilPhase = ((angle / (2 * math.pi)) + _ambient.value) % 1.0;
}
```

The `Transform(...rotateY(angle))` still applies (angle 0 for Bronze → flat). Use `RevealCardBack(tier: spec.tier)` instead of `_CardBack` when `!facingFront`.

- [ ] **Step 2: Gate the card overlays by spec**

Pass spec toggles into `_CardFace`:

```dart
_CardFace(
  card: widget.card,
  tier: spec.tier,
  shine: spec.shineSweep ? _seg(t, 0.87, 0.97) : 0,
  birth: spec.forgeBirth ? (1 - _seg(t, 0.47, 0.62)).clamp(0.0, 1.0) : 0,
  foil: spec.foil, foilPhase: foilPhase, spinTilt: spinTilt,
  flare: _bell(_seg(t, 0.86, 0.95)) * spec.lensFlare,
  glowBreath: breath, glow: _tGlow,
)
```

In `_CardFace.build`, multiply the foil painter alpha by `foil` (skip the `_FoilPainter` layer entirely if `foil == 0 && spinTilt == 0`), use `revealCardTile(card, tier)` for the face, and use the passed `glow` color for the outer shadow. Skip `_ShineSweepPainter` when `shine == 0`, `_LensFlarePainter` when `flare < 0.01`, `_forge` overlay when `birth < 0.01`.

- [ ] **Step 3: Verify**

Run: `flutter analyze --no-pub lib/features/daily/widgets/card_reveal_overlay.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/daily/widgets/card_reveal_overlay.dart
git commit -m "feat(reveal): spec-gated card motion + overlays (fade/flip/spin per tier)"
```

---

## Task 5: Dev Tools — one preview button per tier

**Files:**
- Modify: `lib/features/settings/screens/dev_tools_screen.dart`

- [ ] **Step 1: Replace the single Emerald button with four**

Update the import to `card_reveal_overlay.dart` + `reveal_spec.dart`, and:

```dart
Widget _buildRevealPreviewButtons() {
  return Wrap(spacing: 8, runSpacing: 8, children: [
    for (final tier in CardTier.values)
      _actionChip(tier.label, () => _previewReveal(tier)),
  ]);
}

void _previewReveal(CardTier tier) {
  final card = allCollectibleNames.first;
  final nav = Navigator.of(context, rootNavigator: true);
  nav.push(PageRouteBuilder(
    opaque: false,
    pageBuilder: (_, __, ___) => CardRevealOverlay(
      card: card, spec: revealSpecFor(tier), onContinue: nav.pop),
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    transitionDuration: const Duration(milliseconds: 250),
  ));
}
```

- [ ] **Step 2: Verify + device-QA each tier**

Run: `flutter analyze --no-pub lib/features/settings/screens/dev_tools_screen.dart`
Expected: No issues.
Then build to the sim and tap each of Bronze/Silver/Gold/Emerald from Dev Tools → Reveal Previews. Confirm escalation reads (Bronze quick/modest → Emerald fullest) and each tier's card face is the correct ornate tile. Tune the spec table values (Task 1) as needed — this is the visual-tuning loop; iterate here.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/screens/dev_tools_screen.dart
git commit -m "feat(devtools): per-tier reveal preview buttons"
```

---

## Task 6: Analytics events

**Files:**
- Modify: `lib/services/analytics_event_names.dart`
- Modify: `lib/features/daily/widgets/card_reveal_overlay.dart`

- [ ] **Step 1: Add event-name constants**

Per `docs/analytics/funnel-flags-and-querying.md`, add to `analytics_event_names.dart`:

```dart
static const String cardRevealShown = 'card_reveal_shown';
static const String cardRevealCompleted = 'card_reveal_completed';
```

- [ ] **Step 2: Emit from the overlay via the static hook**

Services use the `onAnalyticsEvent` hook pattern (no Riverpod in widgets that are pushed as routes — pass a callback). Add an `onEvent` callback to `CardRevealOverlay` (`void Function(String, Map<String,Object?>)? onEvent`). Fire `cardRevealShown` in `_open()` and `cardRevealCompleted` in `_continue()` with `{'tier': spec.tier.label, 'dwell_ms': <elapsed>, 'auto': widget.autoStart}`. The muḥāsabah caller (Task 7) wires `onEvent` to the app's analytics dispatch.

- [ ] **Step 3: Verify**

Run: `flutter analyze --no-pub lib/services/analytics_event_names.dart lib/features/daily/widgets/card_reveal_overlay.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/services/analytics_event_names.dart lib/features/daily/widgets/card_reveal_overlay.dart
git commit -m "feat(reveal): card_reveal_shown/completed telemetry"
```

---

## Task 7: Wire into the muḥāsabah flow (replace `NameRevealOverlay`)

**Files:**
- Modify: `lib/features/daily/screens/muhasabah_screen.dart:85-114,269-298`

- [ ] **Step 1: Read the current push site**

Run: `sed -n '260,300p' lib/features/daily/screens/muhasabah_screen.dart`
Expected: shows `_pushNameRevealOverlay()` constructing `NameRevealOverlay(...)`.

- [ ] **Step 2: Swap the overlay**

Replace the `NameRevealOverlay(...)` construction with:

```dart
CardRevealOverlay(
  card: engagedCard, // the CollectibleName from state.engagedCard
  spec: revealSpecFor(engageResult.tier),
  onContinue: () => nav.pop(),
  onEvent: (name, props) => AnalyticsService.instance.track(name, props),
)
```

Keep the existing `ref.listen` gate (`cardEngageResult.tierChanged` rising) and the `rootNavigator` `PageRouteBuilder` (opaque:false, fade). The `onContinue` must preserve the existing post-reveal handoff into the deeper reflection (`BeatRevealFlow`) — verify the `.then(...)`/callback that ran after `NameRevealOverlay` still runs after `CardRevealOverlay` pops.

- [ ] **Step 3: Duplicate (no tier change) path**

`ref.listen` already only fires on `tierChanged`. Confirm `isDuplicate` pulls (token awarded, no reveal) do NOT push the overlay — they shouldn't, since `cardResult` is null when `!tierChanged` (`daily_loop_provider.dart:499-506`). No new code; add a comment noting the intentional skip.

- [ ] **Step 4: Verify + device-QA the real loop**

Run: `flutter analyze --no-pub lib/features/daily/screens/muhasabah_screen.dart`
Expected: No issues.
Device-QA: use Dev Tools → "Clear Card Collection" then run a muḥāsabah (Home → Begin Muḥāsabah) → confirm the new Bronze reveal fires for a fresh discovery, and (Dev Tools tier-up scroll or repeat encounters) confirm Silver/Gold/Emerald reveals fire with the right spec and the deeper reflection follows.

- [ ] **Step 5: Commit**

```bash
git add lib/features/daily/screens/muhasabah_screen.dart
git commit -m "feat(reveal): muhasabah uses tiered CardRevealOverlay (replaces NameRevealOverlay)"
```

---

## Task 8: Remove debug scaffolding + delete legacy overlay

**Files:**
- Modify: `lib/main.dart` (remove `TEMP-REVEAL-DEBUG` block + 2 imports)
- Delete: `lib/features/daily/widgets/name_reveal_overlay.dart` (+ update/remove its test if any)

- [ ] **Step 1: Remove the temp block from main.dart**

Delete the `// ── TEMP-REVEAL-DEBUG` … `// ── END TEMP-REVEAL-DEBUG ──` block in `_SakinaAppState.initState`, and remove the now-unused imports `emerald_reveal_spike.dart`/`card_reveal_overlay.dart` and `achievement_toast.dart` (only if `rootNavigatorKey` isn't used elsewhere in main.dart — verify with grep).

Run: `grep -n "rootNavigatorKey" lib/main.dart`
Expected: no remaining references after the block is removed → safe to drop the `achievement_toast.dart` import.

- [ ] **Step 2: Find and retire legacy references**

Run: `grep -rn "NameRevealOverlay" lib test`
Expected: only the definition + its own test remain. Delete `name_reveal_overlay.dart` and remove/rename its test (`test/features/daily/name_reveal_overlay_test.dart` if present). Keep `name_reveal.json` asset only if nothing else references it (`grep -rn "name_reveal.json" lib`).

- [ ] **Step 3: Verify the whole app compiles**

Run: `flutter analyze --no-pub lib` (or `flutter analyze`)
Expected: no new errors (baseline infos only).

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(reveal): remove debug auto-launch + delete legacy NameRevealOverlay"
```

---

## Task 9: Reduced-motion + skip affordance

**Files:**
- Modify: `lib/features/daily/widgets/card_reveal_overlay.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/features/daily/card_reveal_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/daily/models/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';

void main() {
  testWidgets('reduced motion resolves to the card + Continue quickly', (tester) async {
    var continued = false;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: CardRevealOverlay(
          card: allCollectibleNames.first,
          spec: revealSpecFor(CardTier.emerald),
          autoStart: true,
          onContinue: () => continued = true,
        ),
      ),
    ));
    // Under reduced motion the sequence collapses to <= 600ms.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Tap to continue'), findsOneWidget);
    await tester.tap(find.byType(CardRevealOverlay));
    await tester.pump();
    expect(continued, isTrue);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/daily/card_reveal_overlay_test.dart`
Expected: FAIL (no reduced-motion handling; 7s controller not elapsed).

- [ ] **Step 3: Implement reduced-motion + tap-to-skip**

In `_open()` / `build()`, read `MediaQuery.maybeOf(context)?.disableAnimations ?? false`. When true: set the controller duration to `const Duration(milliseconds: 500)` and jump straight to a simple fade of the settled card + caption (skip spin/particles). Add tap-to-skip for all tiers: in `_handleTap`, if `_started && !_interactive`, snap `_reveal.value = 1.0` (jump to settle) instead of swallowing the tap — a second tap then continues.

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/features/daily/card_reveal_overlay_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/daily/widgets/card_reveal_overlay.dart test/features/daily/card_reveal_overlay_test.dart
git commit -m "feat(reveal): reduced-motion fallback + tap-to-skip"
```

---

## Task 10: Performance pass (device)

**Files:**
- Modify: `lib/features/daily/widgets/card_reveal_overlay.dart` (only if profiling flags jank)

- [ ] **Step 1: Profile each tier on a physical device**

Run: `flutter run --profile --dart-define-from-file=env.json` on a real device; open each tier via Dev Tools; watch the performance overlay (`P`) for raster/build spikes. Emerald (most layers + blurs) is the worst case.

- [ ] **Step 2: Mitigate if needed**

If raster time exceeds ~16ms: reduce full-screen `MaskFilter.blur` radii, cap `sparkCount`/mote counts on the low tiers (already lower), and confirm the ornate tile is inside its `RepaintBoundary` (Task 3/4). Do NOT add blur to the lantern (it's cached via `CompanionMedallion`'s own `RepaintBoundary`).

- [ ] **Step 3: Commit (if changes made)**

```bash
git add lib/features/daily/widgets/card_reveal_overlay.dart
git commit -m "perf(reveal): trim blur/particle cost to hold 60fps on device"
```

---

## Out of scope (tracked, not built here)

These surfaced during review and are **not** part of this animation plan — file as follow-ups:
- **Emerald has no unique text content** (`CollectibleName` gates hadith at t2, dua at t3; Emerald t4 = same as Gold). The biggest animation lands on the least-new content. Decide: give Emerald a unique content layer, or keep it a pure prestige/cosmetic flex.
- **The deeper reflection is not tier/encounter-aware** (`_deeperContextText`, `daily_loop_provider.dart:990`) — re-encounters can feel repetitive. A "you return to this Name a 3rd time…" framing is a separate content task.
- **Lottie migration** (optional): the FX painter layers are the migration candidates if we later want to author them in `~/lottie-lab`; the card + spin stay native (data-driven Arabic). Not needed for v1.

---

## Self-Review

- **Spec coverage:** All four tiers get a spec (Task 1), correct card face + tinted back (Task 2), spec-gated motion/fx (Tasks 3-4), dev previews (Task 5), telemetry (Task 6), real-flow wiring (Task 7), cleanup (Task 8), a11y/skip (Task 9), perf (Task 10). "Emerald nicest, others polished" is enforced by the escalation table.
- **Placeholder scan:** No TBDs; the one lookup (Silver tile class name) is an explicit grep step with a substitution instruction.
- **Type consistency:** `RevealSpec`/`revealSpecFor`/`tierPalette`/`TierPalette`/`HapticProfile` names are used consistently across Tasks 1-9; `CardRevealOverlay` (not `EmeraldRevealSpike`) everywhere after Task 3; `revealCardTile`/`RevealCardBack` from Task 2 used in Task 4.
- **Regression guard:** Emerald spec = all toggles max, so Task 3 is behavior-preserving for the approved reveal (verified in Task 3 Step 8).
```
