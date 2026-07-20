# Sakina — Design System

The canonical reference for Sakina's visual language. When code and this document
disagree, **the code is the source of truth** (`lib/core/constants/app_colors.dart`,
`lib/core/constants/app_spacing.dart`, `lib/core/theme/app_typography.dart`,
`lib/core/theme/app_theme.dart`) — but a disagreement is a bug in one or the other,
so fix the drift, don't leave it. This file exists so the next net-new surface
(widget, gift moment, onboarding refresh) is built from a written system instead of
re-derived from prose and one mockup.

> **Cross-links:** the "Design system" section of [`CLAUDE.md`](./CLAUDE.md) is the
> short-form philosophy; this file is the token-level spec. Keep the two in sync —
> when a token changes here, check whether CLAUDE.md's prose still holds.

---

## 1. Philosophy

The app should feel like **opening a beautifully typeset mushaf, not a tech product** —
warm, premium, spiritually grounded. Every surface earns quiet.

- **Light mode is the DEFAULT** (warm cream). Dark mode is secondary and uses a warm
  charcoal, **never pure black**.
- **Generous whitespace** — budget 20–30% more padding than feels necessary.
- **Soft rounded cards** (12–16px), hairline borders, **zero elevation** (no drop
  shadows anywhere in the theme — separation comes from border + background, not
  shadow).
- **Islamic geometric patterns appear ONLY as 5–8% opacity decorative accents**,
  never as foreground.
- The result card (Name + verse + duʿā) must be **share-worthy unprompted** — that's a
  growth mechanic, not just aesthetics.

**Visual references:** Glorify (primary) · Hallow (dark mode) · Calm (premium wellness)
· Duolingo (gamification *mechanics* only — NOT its bright palette) · Cal AI
(onboarding flow).

---

## 2. Color

All values from `lib/core/constants/app_colors.dart`. Two surface identities live
here: the **themed app** (light/dark) and the **Sacred Canvas** (its own un-themed
immersion surface).

### 2.1 Light mode (default)

| Token | Hex | Role |
|---|---|---|
| `backgroundLight` | `#FBF7F2` | Warm cream — app background |
| `surfaceLight` | `#FFFFFF` | Cards, sheets, inputs |
| `surfaceAltLight` | `#F3EDE4` | Recessed / alternate surface |
| `primary` | `#1B6B4A` | Deep emerald — brand, buttons, active state |
| `primaryLight` | `#E8F5EE` | Emerald tint — containers |
| `primaryDark` | `#134D36` | Emerald pressed/deep |
| `secondary` | `#C8985E` | Warm matte gold — **fills only** (pills, accents) |
| `secondaryLight` | `#F5EBD9` | Gold tint container |
| `goldInk` | `#9A6F37` | Gold **for text** on cream (kickers/labels) |
| `textPrimaryLight` | `#1A1A2E` | Primary text |
| `textSecondaryLight` | `#6B7280` | Secondary text |
| `textTertiaryLight` | `#9CA3AF` | Hints, disabled |
| `textOnPrimary` | `#FFFFFF` | Text on emerald |
| `streakAmber` | `#E8A154` | Streak flame (softened, not neon) |
| `streakBackground` | `#FEF3C7` | Streak chip background |
| `error` | `#DC2626` | Error |
| `errorBackground` | `#FEE2E2` | Error container |
| `borderLight` | `#E5E0D8` | Card / input border (hairline) |
| `dividerLight` | `#F0EBE3` | Dividers |

### 2.2 Dark mode (secondary — warm charcoal, never pure black)

| Token | Hex | Role |
|---|---|---|
| `backgroundDark` | `#1C1917` | Warm charcoal background |
| `surfaceDark` | `#292524` | Cards/surfaces |
| `surfaceAltDark` | `#1E1B19` | Recessed surface |
| `primaryDarkMode` | `#4ADE80` | Emerald brightened for dark |
| `primaryLightDark` | `#1A3A2A` | Emerald container (dark) |
| `secondaryDark` | `#D4A44C` | Gold (dark) |
| `secondaryLightDark` | `#3D2E1A` | Gold container (dark) |
| `textPrimaryDark` | `#F5F0EB` | Primary text |
| `textSecondaryDark` | `#A8A29E` | Secondary text |
| `streakAmberDark` | `#FBBF24` | Streak flame (dark) |
| `errorDark` | `#F87171` | Error (dark) |
| `borderDark` | `#44403C` | Borders (dark) |

### 2.3 The gold contrast rule (memorize this)

Bright gold `secondary` `#C8985E` is **~2.2:1 on cream** and **~2.5:1 on emerald** —
it **FAILS** WCAG 4.5:1 for text on **both** surfaces. Therefore:

- **Gold text on cream** → use `goldInk` `#9A6F37`, never `secondary`.
- **Gold on the Sacred Canvas** → **non-text accent only** (progress fill, bars,
  ornament). Functional text on the canvas uses cream `sacredInk`, never gold.
- **Gold as a fill** (pill background, accent block, ornament) → `secondary` is fine;
  the contrast rule is about *text*.

### 2.4 Sacred Canvas (the beat-reveal / Build-a-Duʿā immersion surface)

The emerald immersion surface for `BeatRevealFlow` (`lib/widgets/beat_reveal/`) and the
Reflect result/off-topic screens. It is a **deliberate mode change** from the cream
home — entering and leaving the flow should read as entering and leaving the ritual.
**Same canvas in light and dark themes** — it is its own surface, not a themed one.

| Token | Value | Role |
|---|---|---|
| `sacredCanvasTop` | `#17553C` | Gradient start (top) |
| `sacredCanvasBase` | `#1B6B4A` | Gradient mid (~60% stop) |
| `sacredCanvasGlow` | `#1F7A55` | Gradient end (bottom) |
| `sacredCanvasGradient` | 178° top→base→glow, stops `[0.0, 0.6, 1.0]` | The canvas fill |
| `sacredInk` | `#F6EFE4` (100%) | Primary text on canvas |
| `sacredInkSoft` | cream @ 70% (`0xB3…`) | Supporting text, loader |
| `sacredInkFaint` | cream @ 45% (`0x73…`) | Hints, source lines |
| `sacredTrack` | cream @ 22% (`0x38…`) | Progress-segment track |
| `sacredPattern` | cream @ 8% (`0x14…`) | Geometric accent (the 5–8% rule) |

**Canvas text ladder:** 100% → 70% → 45% is the only sanctioned opacity ramp for text
on the canvas. Chrome (skip button, etc.) stays at **≥80% cream** with a **≥44px hit
area**.

---

## 3. Typography

From `lib/core/theme/app_typography.dart`. Google Fonts, loaded at runtime.

> ⚠️ **Drift flag (2026-07-20):** CLAUDE.md's design section previously said *"DM Serif
> Display for English headings, DM Sans for body/UI."* The **type system uses `Outfit`**
> for all English display **and** body/UI (`GoogleFonts.outfitTextTheme()` in
> `app_theme.dart`, and every style in `app_typography.dart`). **No DM Serif / DM Sans
> font is registered** (`pubspec.yaml` bundles neither). Outfit is the source of truth;
> CLAUDE.md has been corrected. Two lingering references remain, both drift to clean up
> (out of scope for this doc):
> - `paywall_screen.dart:846` and `warmup_exhausted_sheet.dart:177` — **stale comments**
>   that say "DM Serif Display" but actually render `AppTypography` (Outfit). Harmless,
>   just misleading.
> - `coachmark_overlay.dart` (3 places) — hardcoded `fontFamily: 'DM Sans'`. Since DM Sans
>   isn't bundled, these **silently fall back to the system font** (SF/Roboto), not Outfit
>   — a real (minor) type-consistency bug in the coachmark, not just a comment.
>
> This is exactly the drift this document exists to stop.

### 3.1 English — Outfit

| Style | Font / weight | Size / height / tracking |
|---|---|---|
| `displayLarge` | Outfit 700 | 34 / 1.2 / -0.68 (−0.02em) — **standard for all main screen titles** |
| `displayMedium` | Outfit 700 | 28 / 1.25 |
| `displaySmall` | Outfit 700 | 24 / 1.3 |
| `headlineLarge` | Outfit 600 | 24 / 1.3 |
| `headlineMedium` | Outfit 600 | 20 / 1.3 |
| `bodyLarge` | Outfit 400 | 17 / 1.5 |
| `bodyMedium` | Outfit 400 | 15 / 1.5 |
| `bodySmall` | Outfit 400 | 13 / 1.5 |
| `labelLarge` | Outfit 500 | 15 / 1.4 |
| `labelMedium` | Outfit 500 | 13 / 1.4 |
| `labelSmall` | Outfit 500 | 11 / 1.4 |

> Note: `app_theme.dart` overrides display/headline weights to **w800/w700** in the
> `ThemeData` textTheme. When you pull a title from `Theme.of(context).textTheme` you
> get the heavier weight; the raw `AppTypography` constants are w700/w600. Prefer the
> theme for on-screen chrome so weights stay consistent.

### 3.2 Arabic — three faces, never mixed with English in one widget

| Style | Font | Size / height | Use |
|---|---|---|---|
| `quranArabic` | Amiri 400 (naskh) | 28 / 1.8 | Quran verses |
| `nameOfAllahDisplay` | Aref Ruqaa 700 (calligraphic) | 48 / 1.4 | Name-of-Allah hero |
| `arabicClassical` | Scheherazade New 400 | 24 / 1.8 | Alternate classical |

**Two hard rules for Arabic (from CLAUDE.md critical rules):**

1. **NEVER mix Arabic and English in a single `Text` widget** — mixed direction bleeds
   RTL into adjacent UI. Use separate widgets with explicit `textDirection`, or
   `RichText`/`TextSpan`.
2. **Aref Ruqaa (`nameOfAllahDisplay`) bleeds into surrounding UI** if used as raw
   text — always render it through
   [`AdjustedArabicDisplay`](./lib/widgets/adjusted_arabic_display.dart).

---

## 4. Spacing, radius & layout

From `lib/core/constants/app_spacing.dart`. 4px base grid.

| Token | px | Token | px |
|---|---|---|---|
| `xs` | 4 | `xxl` | 48 |
| `sm` | 8 | `xxxl` | 64 |
| `md` | 16 | `cardRadius` | 14 |
| `lg` | 24 | `buttonRadius` | 12 |
| `xl` | 32 | `inputRadius` | 12 |
| `pagePadding` | 24 | | |

- **Page gutter is `pagePadding` = 24** — the default screen horizontal inset.
- **Cards round at 14, buttons/inputs at 12** — cards read a touch softer than
  controls. This is the "soft 12–16px rounded cards" rule made concrete.
- **Whitespace bias:** when in doubt, step up one token (`md`→`lg`). The system is
  tuned to feel generous, not tight.

### Component defaults (from `app_theme.dart`)

- **Cards:** `surface` fill, **elevation 0**, hairline border (`border*` @ 0.5px),
  radius 14.
- **Elevated buttons:** `primary` fill, `onPrimary` text, **elevation 0**, padding
  `24×16`, radius 12, label Outfit 500 @ 16.
- **Inputs:** filled with `surface`, content padding `20×16`, radius 12; enabled border
  = `border*`, focused border = `primary` @ 1.5px.
- **AppBar / BottomNav:** flat (`elevation 0`, `scrolledUnderElevation 0`),
  background = surface/background, active = `primary`.
- **Dividers:** `divider*` (light) / `border*` (dark), 1px.

There are **no drop shadows** in the theme. Separation is border + background only.

---

## 5. Motion

The signature motion is the **beat-advance transition** in
`lib/widgets/beat_reveal/beat_reveal_flow.dart` — the tap-through rhythm of the sacred
canvas.

**Beat advance (`AnimatedSwitcher` + `_transition`):**
- **Forward** duration **450ms**, curve `Curves.easeOutCubic`; **reverse** 250ms.
- Combined **fade + slide**: new beat slides in from a **±0.045 vertical offset**
  (down when going forward, up when going back) while fading in. Small travel, soft
  landing — it should feel like a page settling, not a slide deck.
- Each beat is keyed by `ValueKey<int>(_index)` so the switcher animates on index
  change.

**Other canvas timings (same file):**
- **Progress bar** segment fill: 250ms (`beat_progress_bar.dart`).
- **Entry / reveal** beat: 1100ms.
- **Name reveal** scale: `scaleXY 0.6→1.0`, 500ms, `Curves.easeOutBack`.

**Reduced motion:** the flow reads `_reducedMotion` and collapses transition durations
to ~1ms (fade/slide effectively instant) while preserving the tap logic. **Any new
canvas motion must honor a reduced-motion path** — never gate content behind an
animation that can't be turned off.

**General principle:** motion is calm and short (200–500ms for chrome, ~1s for a
sacred reveal moment). Use `easeOutCubic`/`easeOutBack` for arrivals; avoid bounce or
overshoot outside the one sanctioned name-reveal moment.

---

## 6. On-canvas rules (quick reference)

When building anything on the **Sacred Canvas**:

1. **Text is cream (`sacredInk`), never gold.** Gold fails 4.5:1 on emerald.
2. **Gold is a non-text accent only** — progress fill, bars, ornament.
3. **Opacity ramp for text:** 100% / 70% / 45% (`sacredInk` / `Soft` / `Faint`).
4. **Chrome ink ≥ 80%**, hit area **≥ 44px**.
5. **Geometric pattern at 8%** (`sacredPattern`) — decorative accent, never foreground.
6. **Honor reduced motion.**
7. The duʿā trio (reframe → story → takeaway → duʿā) is a single tap-through; the duʿā
   itself should land on one screen (see the bite-sized-AI-text spec,
   `docs/superpowers/specs/2026-07-14-bite-sized-ai-text-design.md`).

---

## 7. Change log

- **2026-07-20** — Initial DESIGN.md formalized from code + CLAUDE.md. Captured the
  Sacred Canvas token block, the gold contrast rule, and the beat-advance motion.
  **Flagged typography drift:** CLAUDE.md said DM Serif/DM Sans; the type system uses
  Outfit (no DM font registered). Corrected CLAUDE.md. Noted lingering stray refs
  (stale comments + `coachmark_overlay.dart`'s unregistered `DM Sans` fallback) as
  cleanup out of scope for this doc. Surfaced by `/plan-design-review` of the
  bite-sized-AI-text spec (2026-07-14).
