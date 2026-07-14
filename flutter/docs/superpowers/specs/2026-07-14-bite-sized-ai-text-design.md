# Bite-Sized AI Text — Design

**Date:** 2026-07-14
**Status:** Approved direction (tap-through everywhere for first consumption; chunked scroll for re-reading surfaces)

## Problem

AI-generated content (reframe, story, dua) renders as undifferentiated walls of text.
The muḥāsabah deeper steps, Reflect flow, journal detail, and Build-a-Dua all display
each AI field as a single flat `Text` widget inside a card — no hierarchy, no beat
separation, no scannable structure. Users (starting with the first muḥāsabah — the
conversion moment per the reel-first plan) face paragraph blobs instead of a guided
spiritual moment.

The text is not actually long — the prompt constrains the reframe to 2-3 sentences and
the story to 3-5 (`ai_service.dart` reflect system prompt). It *reads* as a wall because:

1. **Zero internal hierarchy** — every sentence gets identical `bodyLarge` styling.
2. **One paragraph blob** — no sentence/beat separation or internal whitespace.
3. **No hard length enforcement** — gpt-4o-mini drifts past "3-5 sentences" and nothing trims.
4. **The story has no shape** — no title, no styled source attribution, no takeaway.

## Goals

- Every AI-text moment is consumed one idea at a time, at the user's tap rhythm
  (Glorify-style story tap-through), with real typographic hierarchy.
- Re-reading surfaces (journal detail, Ameen summary) stay scrollable but gain the
  same chunked typography.
- One structured-beats schema feeds both renderers.
- Old saved reflections (plain strings) still render chunked via a fallback splitter.

## Non-goals

- No changes to which content is AI-generated vs catalog-verified (duas/verses stay
  pre-verified; the AI still never generates scripture).
- No auto-advance timers (tap-to-advance only).
- No changes to the gacha reveal animation itself.
- No changes to `getFollowUpQuestions`, `getDailyResponse`, `_findNamesForNeed`
  (already short outputs).

## Architecture overview

Three layers:

```
AI prompt (beat markers) ──► ReflectResponse (structured beat fields)
                                   │
                     ┌─────────────┴──────────────┐
              BeatRevealFlow                ChunkedSectionView
         (full-screen tap-through,        (scrollable, pull-quote +
          first consumption)               beat paragraphs, re-reading)
                                   │
                     splitIntoBeats(String) fallback
                  (legacy saved strings / parse failures)
```

## 1. Beat schema — prompt + parser changes

`ai_service.dart` reflect system prompt: replace the `##REFRAME##` / `##STORY##`
output markers with structured beat markers. New response format:

```
##NAME## / ##NAME_AR##                (unchanged)
##REFRAME_KEY##    one resonant line, MAX 12 words — the single thought the user
                   should carry; no filler openers ("Remember that…")
##REFRAME_BODY##   1-2 short sentences expanding the key line, MAX 30 words total
##STORY_TITLE##    3-6 word title for the story (e.g. "Musa at the Sea")
##STORY_BEAT_1##   one sentence, MAX 20 words
##STORY_BEAT_2##   one sentence, MAX 20 words
##STORY_BEAT_3##   one sentence, MAX 20 words (omit if the story lands in 2 beats)
##STORY_SOURCE##   citation only (e.g. "Sahih al-Bukhari 3477" / "Qur'an 20:25-28")
##TAKEAWAY##       one line, MAX 14 words, connecting the story back to the user's feeling
##DUA_AR## / ##DUA_TR## / ##DUA_EN## / ##DUA_SOURCE##   (unchanged)
##RELATED## / verses                  (unchanged)
```

Prompt rules to add: "Write for a phone screen. One idea per line. Never exceed the
word caps." Authenticity rules unchanged (story/dua from Quran or sahih hadith only —
the beat structure changes *packaging*, not sourcing).

**Parser** (`parseReflectResponse`): parse new markers into new fields. Robustness
ladder, in order:

1. All beat markers present → structured response.
2. Beat markers missing but legacy `##REFRAME##` / `##STORY##` present (model
   noncompliance) → run `splitIntoBeats` on the legacy strings.
3. Word-cap overruns are accepted as-is (caps are prompt-side guidance; no truncation
   that could cut a hadith mid-sentence).

Legacy `reframe` / `story` getters remain on `ReflectResponse`, derived by joining
beats — nothing downstream breaks during migration.

## 2. Data model + persistence

`ReflectResponse` (Freezed) gains:

```dart
String reframeKey;        // pull-quote line
String reframeBody;
String storyTitle;
List<String> storyBeats;  // 2-3 entries
String storySource;
String takeaway;
```

`SavedReflection` (journal persistence, Supabase + local): add the same fields as
nullable columns/JSON. Old rows have them null → journal detail falls back to
`splitIntoBeats(reframe)` / `splitIntoBeats(story)`. No backfill migration; old
entries just take the fallback path forever.

**`splitIntoBeats(String) → List<String>`** — shared util (`lib/core/utils/` or
alongside the renderers): sentence-splits on `.`, `?`, `!` followed by whitespace,
respecting common abbreviations and honorifics ("ﷺ", "(saw)", "a.s."), merges
fragments under 4 words into the previous beat. Unit-tested.

## 3. Renderer A — `BeatRevealFlow` (tap-through, first consumption)

New shared widget: `lib/widgets/beat_reveal_flow.dart` (+ sub-widgets, one per file
per convention). Full-screen **emerald immersion canvas** (approved direction, see
"Approved Mockups"): deep-emerald vertical gradient, cream serif type, gold progress
segments, Islamic geometric accent in cream at ≤8% opacity in one corner only. The
canvas is a deliberate mode change — home stays cream; entering/leaving the flow
reads as entering/leaving the ritual (Calm/Hallow session-mode pattern). Same canvas
in light and dark themes (it is its own surface, not themed).

**Sacred canvas token set** (new block in `lib/core/constants/app_colors.dart`;
all flow widgets consume ONLY these tokens — no inline hex):

```dart
// Sacred canvas — the beat reveal flow's immersion surface
sacredCanvasTop   = Color(0xFF17553C);  // gradient start (178°)
sacredCanvasBase  = Color(0xFF1B6B4A);  // gradient mid (60%)
sacredCanvasGlow  = Color(0xFF1F7A55);  // gradient end
sacredInk         = Color(0xFFF6EFE4);  // primary text on canvas
sacredInkSoft     = sacredInk @ 70%;    // supporting text, loader line
sacredInkFaint    = sacredInk @ 45%;    // hint, source attributions
sacredTrack       = sacredInk @ 22%;    // progress segment track
// progress fill + accents on canvas: AppColors.secondary (gold #C8985E)
// geometric pattern accent: sacredInk @ 8%, one corner only
```

- **Segmented progress bar** at top (one segment per screen, Glorify/IG-story style),
  **gold fill on `sacredTrack`**.
- **Tap right 60% of screen** → next; **tap left 40%** → previous. Haptic light impact
  on advance. No auto-advance.
- **Skip affordance:** subtle "Skip to dua" text button, top-right, `labelMedium`
  tertiary color. Jumps to the dua screen (never skips saving/economy hooks).
- Each screen: one idea, vertically centered, staggered fade-in (existing
  `flutter_animate` patterns).

**Motion & pacing (the flow's felt rhythm):**

- **Beat advance:** outgoing beat fades out ~250ms; incoming fades in ~450ms with a
  12px upward settle (`easeOutCubic`); chrome (accent bar / label) leads the body
  text by ~120ms. Tap-back mirrors the motion downward (up = forward, down = back —
  direction is the wayfinding). One shared transition for every beat. A tap landing
  mid-transition skips to the end state — taps are never dropped or queued visibly.
- **First-run tap hint:** beats 1–2 of the user's first-ever flow show the bottom
  hint ("tap to continue", small, opacity pulsing 45%→0%); it never renders again
  after the user has advanced 3 beats lifetime (one persisted bool). If the user
  idles 5s on any beat during that first session, the hint re-pulses once.
- **Ameen exit (the landing):** tapping Ameen blooms the pill into a brief
  (≤1.2s, non-interactive, auto-advancing) completion beat — gold khatam pulse +
  "Ameen" echoed in serif — then the emerald canvas dissolves ~500ms into home,
  where existing streak/quest feedback plays as usual (reward toasts no longer
  collide with the flow). Reduced-motion: straight dissolve, no pulse.
**Accessibility & scaling (functional chrome must pass; only decoration whispers):**

- **Contrast rule for the canvas:** functional text on the emerald canvas (Skip,
  Try Again, Return home) uses `sacredInk` at ≥80% — measured ≥4.5:1. Gold
  (#C8985E) is ~2.5:1 on emerald and is therefore reserved for **non-text accents
  only** (progress fill, accent bars, pill fills — pill label contrast checked
  separately). Decorative whispers (tap hint, pattern) may sit at faint opacity
  because the first-run hint rule ensures they are never the only affordance.
- **Touch targets:** Skip gets a padded ≥44×44px hit area anchored top-right;
  tap zones are the screen halves so they trivially pass.
- **Text scaling / overflow (center-until-overflow):** honor `textScaleFactor`
  fully — never cap it. If a beat's content fits the stage, it is vertically
  centered (ideal composition); if it exceeds the stage (accessibility sizes or
  a noncompliant long beat), it top-aligns inside a scrollable stage with a
  subtle bottom fade, and the tap-forward zone shrinks to the bottom 25% so
  scrolling never accidentally advances. One golden test per layout mode.
- **Screen readers:** each beat screen is a single `Semantics` node — label =
  beat text plus position ("beat 2 of 7"), button trait, hint "double-tap to
  continue", custom accessibility actions **Next / Back / Skip to duʿa**. On
  advance, announce the new beat via `SemanticsService`. Progress bar and
  geometric pattern are `excludeSemantics`. One widget test asserts the tree.
- **Reduced motion:** drop the animations, never the screens.

**Loading state (the wait is part of the ritual):** the flow enters the emerald
canvas immediately when the user leaves the gacha reveal — the mode change happens
at the tap, not when the AI responds. While the reflect call is in flight, a
centered `SakinaLoader` (breathingStar variant, cream-tinted for the emerald
canvas) shows with a single quiet line ("Preparing your reflection…",
`bodyMedium`, cream at 70%). Beat 1 fades in the moment the response parses.
Never a bare `CircularProgressIndicator`, never a blank screen.

**Error / offline state (in-canvas, never a snackbar):** if the reflect call fails
or times out, stay on the emerald canvas: calm message ("We couldn't prepare your
reflection.") in serif, a gold **Try Again** pill, and a quiet "Return home" text
button beneath it. Retry re-fires the same request; Return home exits the canvas
with the standard exit transition. No red, no toast, no error codes.

**Screen inventory (muḥāsabah / Reflect):**

| # | Screen | Content | Typography |
|---|--------|---------|------------|
| 1 | Key line | `reframeKey` | DM Serif Display, large, pull-quote treatment |
| 2 | Reframe | `reframeBody` | `bodyLarge`, generous leading |
| 3 | Story open | `storyTitle` + `storyBeats[0]` | title `headlineSmall` serif, beat `bodyLarge` |
| 4..n | Story beats | `storyBeats[1..]`, source line styled small/tertiary on the last beat | `bodyLarge` |
| n+1 | Takeaway | `takeaway` + a quiet share icon (bottom-right, `sacredInk` 80%, ≥44px target, iOS share sheet) exporting the existing share-card rendering of Name + key line + takeaway on the emerald frame. Share appears on **this beat only**; the completion beat stays non-interactive. | serif, medium, gold accent bar |
| n+2.. | Verses (Reflect, when present) | one catalog verse **per screen** between takeaway and dua: Arabic (Amiri, centered) above translation + reference; same advance transition; progress segments include them (flow grows to ~9 taps with 2 verses — Skip covers the impatient path) | `quranArabic` + body styles |
| final | Dua + Ameen | Arabic + transliteration + translation + source **together on one screen** (recitation requires the trio; separate `Text` widgets with explicit `textDirection` per RTL rule), with the Ameen pill pinned at the bottom — one screen, no extra tap. Quest/economy hooks fire from Ameen exactly as today. | existing `quranArabic` + body styles |

**Dua screen internal hierarchy (see-first order, top to bottom):** 1. Arabic (largest,
the visual anchor) → 2. transliteration (italic, secondary) → 3. translation (body) →
4. source attribution (small, tertiary) → 5. Ameen pill (bottom-pinned). This is the
densest screen in the flow; nothing else competes — no header label, no skip (you're
already here). Content scrolls behind the pinned Ameen if it overflows small screens.

Total ~7 taps. The existing coarse step machine (`reflectStep` 0-3 in
`daily_loop_provider.dart` / Reflect's equivalent) is replaced by the flow's internal
index; the provider keeps a single "deeper reflection in progress / completed" state
so Ameen-side effects (quests, card engagement, journal save) fire exactly as today.

**Build-a-Dua** (`duas_screen.dart`): keep the existing 4-section step structure
(sections are already the right granularity) but move the section screens and the
Ameen screen onto the **sacred canvas** in this same release (decision 11A) —
one visual language for every dua ritual, consuming the same `sacredCanvas*`
tokens. Within a section, adopt the staggered reveal (label → Arabic →
transliteration → translation fade in sequentially, all end visible together) and
the segmented progress bar (gold on `sacredTrack`). Ameen screen: related duas
collapse into expandable cards (title + source visible; tap to expand full text).
Implementation caution: `duas_screen.dart` is dart-format-sensitive — re-apply
targeted edits matching base style, no whole-file format (see learnings).

## 4. Renderer B — `ChunkedSectionView` (scrollable, re-reading)

New shared widget for journal detail (`reflection_detail_page.dart`) and the
Ameen/share summary:

- `reframeKey` rendered as a **freestanding typographic pull quote**: DM Serif
  Display ~22px, emerald ink on the page background, a short 26px gold bar ABOVE
  the line — explicitly NOT a card, NOT a `border-left` accent, no fill. The
  existing `_sectionCard` (card + side gold bar) is dropped from the redesigned
  detail view; body content is plain paragraphs separated by whitespace.
- `reframeBody`, then story: title line, each beat its own paragraph with
  `AppSpacing.sm` gaps, source as a styled attribution line (small, tertiary).
- `takeaway` as a highlighted closing line.
- Dua block unchanged structurally (already 4 stacked parts) but adopts the
  attribution styling.
- Legacy entries (null structured fields) → `splitIntoBeats` produces the paragraph
  chunks; no pull quote (first beat is not promoted — a mid-sentence fragment as a
  pull quote looks worse than none).

## 5. Surface-by-surface summary

| Surface | Renderer | Notes |
|---|---|---|
| Muḥāsabah post-gacha (`muhasabah_screen.dart`) | BeatRevealFlow | replaces `_buildDeeper` card steps |
| Reflect result (`reflect_screen.dart`) | BeatRevealFlow | replaces step cards; verses screen appended if present |
| Build-a-Dua (`duas_screen.dart`) | sacred canvas + staggered section reveal + progress bar | section structure unchanged; Ameen related-duas collapse |
| Journal detail (`reflection_detail_page.dart`) | ChunkedSectionView | scrollable; legacy fallback |
| Ameen / share summary | ChunkedSectionView | share-card rendering unaffected |

## 6. Edge cases & error handling

- **Model returns legacy markers only** → `splitIntoBeats` fallback (ladder step 2).
- **Model returns 2 beats** → screen inventory shrinks; progress bar segment count is
  computed from content, never hardcoded.
- **Empty/blank beat** → dropped from the flow.
- **Old saved reflections** → fallback path in ChunkedSectionView (§4).
- **Guided tour anchors:** `readStoryCta` / `ameenCta` TourAnchors on the muḥāsabah
  flow must be re-anchored to the new flow's advance/Ameen controls — tour surface
  `TourSurface.muhasabah` step list updated in the same change (tour reveal
  regressions are a known sore spot; see 2026-06-08 tour findings).
- **Interruption mid-flow:** backgrounding/killing the app mid-tap-through follows
  today's behavior for mid-step interruption (state is provider-held for the
  session; no new persistence).

## 7. Analytics

- Existing `check_in_completed` and flow events unchanged.
- Add `reflect_beat_advanced` (props: `surface`, `beat_index`, `beat_kind`) and
  `reflect_flow_skipped` (props: `surface`, `from_beat_index`) to
  `lib/services/analytics_event_names.dart`, emitted via the static
  `onAnalyticsEvent` hook pattern (no Riverpod in services). These measure where
  users bail inside the flow — the whole point of the redesign is completion of
  the read, so instrument it.

## 8. Testing

- **Unit:** `splitIntoBeats` (abbreviations, honorifics, short-fragment merging);
  `parseReflectResponse` ladder (structured / legacy-marker fallback / partial beats).
- **Widget:** BeatRevealFlow — tap-forward/back, computed segment count, skip jumps
  to dua, dua trio renders on one screen (pin this: recitation constraint),
  Ameen side-effects fire once.
- **Widget:** journal detail renders a legacy (null-fields) SavedReflection chunked.
- **Existing pins:** onboarding auth routing test untouched; tour anchor tests
  updated with the re-anchoring.
- **Eval note:** the reflect prompt change should be spot-checked against the
  existing find_duas-style eval pattern; add a lightweight eval asserting the new
  markers parse on 10 canned feelings.

## 9. NOT in scope (considered and explicitly deferred)

- **Tap-through for the names catalog detail screens** — static content; revisit
  after this ships.
- **Ambient per-beat visuals** (gradient shifts per beat, illustrations) — the flow
  ships with the single sacred-canvas gradient; per-beat visual layering is a
  polish pass.
- **Prompt-side localization of beats** — i18n-ready strings apply to UI chrome
  only; AI output language handling is unchanged.
- **Sacred canvas on other surfaces** (gift moments, Ramadan card, onboarding) —
  the token set makes this cheap later; adopting it beyond the dua rituals dilutes
  the mode-change meaning for now.
- **A standalone DESIGN.md** — CLAUDE.md's design section remains the system of
  record; a `/design-consultation` formalization is tracked separately.

## 10. What already exists (reuse, don't reinvent)

- `SakinaLoader` (breathingStar) — the loading state's loader; cream-tint on canvas.
- `AppColors` / `AppTypography` / `AppSpacing` tokens — extended, not replaced.
- `AdjustedArabicDisplay` — required for any Aref Ruqaa Name rendering on canvas.
- `flutter_animate` fadeIn/slideY idioms — the beat transition composes them.
- Share-export pipeline (2026-04-26 share/export pass) — the takeaway share icon
  feeds it; no new renderer.
- `TourAnchor` system — anchors re-point at the flow's advance/Ameen controls.
- Gacha reveal animation — untouched; the canvas begins where it ends.

## Approved Mockups

| Screen/Section | Mockup Path | Direction | Notes |
|----------------|-------------|-----------|-------|
| Beat reveal flow (key line, story beat, takeaway+share, verse beat) | `~/.gstack/projects/SamieBelal-Sakina/designs/beat-reveal-flow-20260714/design-board.html` | **C — Emerald Immersion**: deep-emerald gradient canvas, cream serif type, gold progress on cream track | HTML board (AI image gen blocked on OpenAI org verification). Post-review sync applied: cream Skip ≥80% ink with 44px target (gold fails 4.5:1 on emerald), share icon on takeaway beat only, verse beats added. `approved.json` records the choice. |

## Implementation Tasks

Synthesized from the 2026-07-14 design review's findings. Each task derives from a
specific finding; the full build plan comes from `writing-plans` against this spec.

- [ ] **T1 (P1, human: ~1h / CC: ~5min)** — app_colors — Add the `sacredCanvas*` token block
  - Surfaced by: Pass 5 — new surface identity had zero named tokens (decision 7A)
  - Files: `lib/core/constants/app_colors.dart`
  - Verify: flow widgets compile consuming only tokens; grep shows no inline canvas hex
- [ ] **T2 (P1, human: ~1d / CC: ~20min)** — beat_reveal_flow — In-canvas loading (SakinaLoader breathingStar, cream-tinted) + warm retry error/offline state
  - Surfaced by: Pass 2 — loading and error states unspecified (decision 2A)
  - Files: `lib/widgets/beat_reveal_flow.dart`, `lib/widgets/sakina_loader.dart`
  - Verify: widget test — error state shows Try Again + Return home, never a snackbar
- [ ] **T3 (P1, human: ~half day / CC: ~10min)** — beat_reveal_flow — Dua screen with explicit hierarchy + bottom-pinned Ameen (one screen, no extra tap)
  - Surfaced by: Pass 1 — Dua/Ameen row ambiguity (decision 1A)
  - Files: `lib/widgets/beat_reveal_flow.dart`, `lib/features/daily/screens/muhasabah_screen.dart`
  - Verify: widget test pins dua trio + Ameen on one screen; hooks fire once
- [ ] **T4 (P1, human: ~1.5d / CC: ~30min)** — beat_reveal_flow — Motion spec: 250/450ms crossfade+settle advance, first-run tap hint (persisted bool, dies after 3 lifetime advances), Ameen completion beat (≤1.2s) + 500ms dissolve exit
  - Surfaced by: Pass 3 — transition/hint/exit unspecified (decisions 3A, 4A, 5A)
  - Files: `lib/widgets/beat_reveal_flow.dart`
  - Verify: reduced-motion drops animations not screens; mid-transition tap skips to end state
- [ ] **T5 (P1, human: ~1d / CC: ~20min)** — beat_reveal_flow — A11y: cream functional chrome (≥4.5:1), 44px Skip target, center-until-overflow text scaling, one Semantics node per beat + Next/Back/Skip actions + advance announcements
  - Surfaced by: Pass 6 — measured 2.5:1 gold-on-emerald; no scaling or SR model (decisions 8A, 9A, 10A)
  - Files: `lib/widgets/beat_reveal_flow.dart`
  - Verify: semantics widget test; golden tests for both layout modes
- [ ] **T6 (P2, human: ~half day / CC: ~10min)** — journal — Cardless typographic pull quote in ChunkedSectionView; drop `_sectionCard`
  - Surfaced by: Pass 4 — colored-left-border card = slop blacklist #8 (decision 6A)
  - Files: `lib/features/journal/screens/reflection_detail_page.dart`
  - Verify: legacy (null-fields) entry renders chunked, no card containers
- [ ] **T7 (P2, human: ~half day / CC: ~10min)** — reflect — Verse beats: one catalog verse per screen between takeaway and dua
  - Surfaced by: Pass 7 — "appended if present" had no position (decision 12A)
  - Files: `lib/widgets/beat_reveal_flow.dart`, `lib/features/reflect/screens/reflect_screen.dart`
  - Verify: 2-verse response yields 2 extra segments; 0-verse yields none
- [ ] **T8 (P2, human: ~half day / CC: ~10min)** — beat_reveal_flow — Takeaway share icon → existing share-export pipeline (emerald share card)
  - Surfaced by: Pass 7 — share-worthy moment had no share affordance (decision 13A)
  - Files: `lib/widgets/beat_reveal_flow.dart`, share/export service
  - Verify: icon on takeaway beat only; completion beat stays non-interactive
- [ ] **T9 (P2, human: ~1d / CC: ~30min)** — duas — Build-a-Dua sections + Ameen screen onto the sacred canvas
  - Surfaced by: Pass 7 — two dua rituals, two visual languages (decision 11A)
  - Files: `lib/features/duas/screens/duas_screen.dart`
  - Verify: visual parity with tokens; NO whole-file dart format (format-churn learning)

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — (last 2026-06-03, stale) | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — (outside voices declined this run) | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | — (last 2026-06-17, stale) | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR (FULL) | score: 6/10 → 9/10, 14 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **VERDICT:** DESIGN CLEARED — eng review required before implementation ships.

NO UNRESOLVED DECISIONS
