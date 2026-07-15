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
2. **Partial-structured (decision 15A — the likeliest failure mode):** if ANY beat
   marker parsed, use every field that parsed; missing `storyBeats` →
   `splitIntoBeats` over whatever story text exists; missing
   keyLine/title/takeaway → their screens simply drop from the inventory (segment
   count already computes from content). Unit tests cover 3 partial shapes.
3. No beat markers but legacy `##REFRAME##` / `##STORY##` present (full
   noncompliance) → run `splitIntoBeats` on the legacy strings.
4. Word-cap overruns are accepted as-is in the flow (caps are prompt-side guidance;
   no display truncation that could cut a hadith mid-sentence — persistence clamps
   are separate, see §2).

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

`SavedReflection` (journal persistence, Supabase + local): one nullable
**`beat_data jsonb`** column on `user_reflections` holding
`{reframeKey, reframeBody, storyTitle, storyBeats[], storySource, takeaway}`.
The migration adds a CHECK validating the key set, string types, per-field length
caps, and ≤3 beats — cloned from the existing `verses[]` shape-validation pattern
(migration `20260524164841`), matching the table's constraint conventions instead
of adding five columns that fight them. `toSupabaseRow()`/`fromSupabaseRow()` map
it; `beat_data IS NULL` ⇒ legacy fallback (`splitIntoBeats(reframe/story)`). No
backfill; old rows take the fallback path forever. Save order stays
Supabase-first-then-local, cloning `_saveReflection` (`reflect_provider.dart:722+`).

**Client clamps before insert (decision 9A):** `toSupabaseRow()` clamps beat fields
via the existing `_clampText` pattern (keyLine≤200, body/beats≤500 each, title≤120,
source≤200, takeaway≤200 chars) so a verbose model response can never make the
CHECK throw and drop the save — the table's documented design rejects rather than
truncates (`reflect_provider.dart:776-783`). In-flow display still shows the
unclamped text; the CHECK mirrors the same caps as server-side defense against
malicious clients. The round-trip unit test covers an overrun.

**Source of truth (decision 21A):** when `beat_data` is present it is the source of
truth; `reframe` / `story` / `reframePreview` are derived (joined) values kept for
legacy clients and previews — any future write path must regenerate them from
beats, never edit them independently.

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

**Off-topic state (decision 17A — Reflect only):** an `offTopic` response stays
in-canvas on the same layout with gentle copy ("Share how you're feeling, and I'll
find a Name for it") and a gold "Try again" returning to the input with the text
preserved. The existing `cancelActiveBypassIfAny()` token-refund path
(`reflect_provider.dart:650-660`) is explicitly retained; a widget test pins the
refund + state.

**Journal-cap upsell deferral (decision 18A):** a `needsUpgrade` raised by the
response-time save is queued and surfaces AFTER the Ameen dissolve on home (same
slot as streak/quest feedback) — never a sheet over the canvas. The reflection
still displays fully in-flow from memory even when the save was capped. Widget
test pins no-sheet-during-flow.

**Screen inventory (muḥāsabah / Reflect):**

| # | Screen | Content | Typography |
|---|--------|---------|------------|
| 1 | Key line | `reframeKey` | DM Serif Display, large, pull-quote treatment |
| 2 | Reframe | `reframeBody` | `bodyLarge`, generous leading |
| 3 | Story open | `storyTitle` + `storyBeats[0]` | title `headlineSmall` serif, beat `bodyLarge` |
| 4..n | Story beats | `storyBeats[1..]`, source line styled small/tertiary on the last beat | `bodyLarge` |
| n+1 | Takeaway | `takeaway` + a quiet share icon (bottom-right, `sacredInk` 80%, ≥44px target, iOS share sheet) exporting a **new emerald share-card composition** (Name + key line + takeaway, sacredCanvas tokens) through the existing capture/share-sheet pipeline. Share appears on **this beat only**; the completion beat stays non-interactive. | serif, medium, gold accent bar |
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
collapse into expandable cards — **the FIRST related dua renders expanded by
default** so the full tour variant's `firstRelatedHeart` anchor stays visible.

**Full tour variant protection (decision 11A-tour):** `kFullOnboardingTourSteps`
anchors `duaSectionNext` and `firstRelatedHeart` inside this screen
(`onboarding_tour_step.dart:247,367-375`). The canvas migration must keep both
anchors registered and visible; the staggered reveal must complete before the
tour's 400ms anchor-settle gate; the tour widget test extends to pin both
full-variant duas anchors.

**Extraction (decision 19A):** the section step viewer + Ameen screen are extracted
into `lib/features/duas/widgets/` files (≤200 lines each, consuming `sacredCanvas*`
tokens + `DuaTextBlock`); `duas_screen.dart` shrinks to orchestration. New files
start cleanly formatted, sidestepping the file's documented dart-format churn
hazard; edits to the remaining file follow the no-whole-file-format rule.

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

**Shared `DuaTextBlock` widget (decision 4A):** new `lib/widgets/dua_text_block.dart`
renders the Arabic + transliteration + translation + source stack for every surface,
with an `onSacredCanvas` variant (sacredInk styles vs light-theme styles). It owns
the RTL rule internally (separate `Text` widgets, explicit `textDirection`).
Muḥāsabah, Reflect, journal, Build-a-Dua, and the canvas dua screen all consume it —
the four existing hand-rolled stacks (`muhasabah_screen.dart:592-638` and
equivalents) are deleted in the extraction.

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
- **Guided tour anchors (decision 3A — same step count, re-targeted):** keep the
  5-step muḥāsabah path and the existing anchorIds (`onboarding_tour_step.dart:157-201`)
  so persisted tour-progress indices never shift: `beginMuhasabahCta` unchanged →
  `goDeeperCta` re-targets the canvas-entry CTA → `readStoryCta` re-targets the
  **tap-hint zone** (outline ring around the bottom hint, padded — tapping it
  advances, same gesture the flow teaches). **Hint render rule (decision 10A):**
  show when (first-run rule 4A) OR (a muḥāsabah tour step is active) — this
  guarantees the anchor target exists on every tour path including
  resume-after-kill, closing the anchor-timeout failure class
  (2026-06-01/06-08 findings). Step copy teaches the gesture ("Tap to move through
  your reflection") rather than naming the story, since the step fires on the
  key-line beat. The widget test pins hint presence under tourActive=true with the
  lifetime counter exhausted → `ameenCta`
  targets the Ameen pill (the completion beat auto-advances, so the step fires on
  the pill, never the confirmation) → `returnHomeCta` unchanged. A widget test pins
  step count + anchor registration (tour regressions are the known sore spot; see
  2026-06-08 tour findings).
- **Interruption mid-flow / lifecycle (decisions 2A + 8A — per-surface semantics):**
  the provider persists only a coarse `{notStarted, inProgress, completed}`
  lifecycle — this **intentionally replaces** the fine-grained persisted
  `reflectStep` in `_persistTodayState()` (`daily_loop_provider.dart:1141-1160`);
  delete that field, don't strand it. Re-entry is per-surface, matching today's
  real gating/save semantics:
  - **Muḥāsabah:** the deeper call is free (`daily_loop_provider.dart:1041-1045`)
    and never journal-saves; quest/economy hooks stay Ameen-side. Relaunch while
    `inProgress` re-enters at beat 1 with the cached/prefetched response —
    re-fetching is safe because the call costs nothing.
  - **Reflect:** `markUsed` / bypass-commit / `_saveReflection` stay **at response
    time** (today's behavior, `reflect_provider.dart:642-696` — unchanged economy
    semantics). Relaunch while `inProgress` **re-hydrates the flow from the
    just-saved `SavedReflection`** (local cache) — it NEVER re-fetches and never
    re-gates, so double-charge and double-save are impossible by construction, and
    a bailed user's paid reflection is already in their journal. Only quest hooks
    remain Ameen-side.
- **Route & system back (decision 2A):** the flow is a full-screen opaque GoRoute
  pushed on the root navigator. `PopScope` intercepts Android back: back = previous
  beat; back on beat 1 = exit the canvas (lifecycle stays `inProgress`; the home CTA
  re-enters and restarts from beat 1).

## 6.5 Deletions (same PR — no dormant second path; decision 5A)

Replaced code is **deleted**, not left dormant (this repo's `answerCheckin` /
dead-`_CheckInStep` history is the cautionary tale):

- `muhasabah_screen.dart`: `_buildDeeper` card steps, `_textContent`, `_duaContent`
  (superseded by BeatRevealFlow + `DuaTextBlock`).
- `reflect_screen.dart` / `reflect_provider.dart`: `_buildReflectionStep`,
  `_buildStoryStep`, `_buildDuaStep`, and the `ReflectStep` enum + `continueStep()`.
- `reflection_detail_page.dart`: `_sectionCard`.
- `daily_loop_provider.dart`: the persisted `reflectStep` field (decision 2A).

**Doc sync in the same PR:** CLAUDE.md's "Daily flow" section and
`docs/qa/ui-map.md` muḥāsabah/Reflect entries are rewritten to describe the beat
flow — stale docs are worse than no docs.

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
- **Regression pins (CRITICAL — iron rule, existing behavior being rewired):**
  (a) Ameen fires `onMuhasabahCompleted` / `onNameDiscovered` / economy hooks
  **exactly once**; (b) `_saveReflection` still enforces the journal limit and
  text clamps when `beat_data` is present.
- **Decisions coverage (6A):** widget test — relaunch with lifecycle=`inProgress`
  re-enters at beat 1, hooks fire once; widget test — `PopScope` back = previous
  beat, back on beat 1 exits with lifecycle intact; widget test — error state's
  Try Again re-fires the request and recovers; unit — `toSupabaseRow`/
  `fromSupabaseRow` beat_data round-trip incl. null-legacy; **pgtap** — `beat_data`
  CHECK accepts valid shape, rejects wrong keys / oversized blobs / >3 beats.
- **Analytics:** unit-assert `reflect_beat_advanced` / `reflect_flow_skipped`
  emissions (props: surface, beat_index/beat_kind or from_beat_index) via the
  static `onAnalyticsEvent` hook.
- **Existing pins:** onboarding auth routing test untouched; tour widget test pins
  muḥāsabah step count + anchor registration (decision 3A).
- **Eval (7A — mechanical + baseline-first):** extend the 10-canned-feelings eval to
  assert (a) beat markers parse, (b) word caps respected (keyLine≤12, beats≤20,
  takeaway≤14 — warn, don't fail, up to +20%), (c) `STORY_SOURCE` matches a
  citation pattern (Qur'an x:y or a named collection), (d) Name is canonical.
  **Run the eval suite on master BEFORE the prompt change** to record the known
  flaky baseline (find_duas fails on clean checkout) so this PR isn't blamed for
  it. Full LLM-judge content grading is deferred until beat output stabilizes.
- **Pre-ship human source review (decision 16A — ship gate):** before release, a
  human verifies each canned-eval story beat set against its cited source (Qur'an
  verse / hadith reference); checklist recorded under `docs/qa/`. Any distortion ⇒
  prompt iteration before ship. This is the only check that reads the compressed
  content against its sources — it guards the NEVER-fabricate rule directly and
  repeats after any prompt change.

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
- **Remote kill switch for the beat prompt** (`beat_prompt_enabled` app_config
  flag) — proposed by the eng review's outside voice, **declined by user decision
  13B**; the parser ladder + splitIntoBeats fallback are the accepted safety net.
- **Release sequencing against the reverse-trial readout** — proposed by the
  outside voice (#8), **declined by user decision 14B**; the redesign ships when
  ready.
- **Full LLM-judge content eval** — deferred until beat output stabilizes
  (decisions 7A/16A); the pre-ship human source review covers the gap.

## 10. What already exists (reuse, don't reinvent)

- `SakinaLoader` (breathingStar) — the loading state's loader; cream-tint on canvas.
- `AppColors` / `AppTypography` / `AppSpacing` tokens — extended, not replaced.
- `AdjustedArabicDisplay` — required for any Aref Ruqaa Name rendering on canvas.
- `flutter_animate` fadeIn/slideY idioms — the beat transition composes them.
- Share-export pipeline (2026-04-26 share/export pass) — the capture + share-sheet
  plumbing is reused; the takeaway card itself is a new composition (decision 20A).
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
- [ ] **T8 (P2, human: ~1d / CC: ~20min)** — beat_reveal_flow — Takeaway share icon: reuse the capture/share-sheet pipeline, ADD a new emerald share-card composition (Name + keyLine + takeaway, sacredCanvas tokens) alongside the existing card (decision 20A — this IS a new composition, not "no new renderer")
  - Surfaced by: Pass 7 — share-worthy moment had no share affordance (decision 13A); estimate corrected by outside-voice #12
  - Files: `lib/widgets/beat_reveal_flow.dart`, `lib/widgets/share_card.dart` (or sibling)
  - Verify: icon on takeaway beat only; completion beat stays non-interactive
- [ ] **T9 (P2, human: ~1d / CC: ~30min)** — duas — Build-a-Dua sections + Ameen screen onto the sacred canvas
  - Surfaced by: Pass 7 — two dua rituals, two visual languages (decision 11A)
  - Files: `lib/features/duas/screens/duas_screen.dart`
  - Verify: visual parity with tokens; NO whole-file dart format (format-churn learning)

### Eng-review additions (2026-07-14 /plan-eng-review — one PR per decision D2-A)

- [ ] **T10 (P1, human: ~1d / CC: ~20min)** — reflect_provider — Per-surface re-entry: Reflect re-hydrates from the just-saved SavedReflection (never re-fetch/re-gate); muḥāsabah re-fetches freely; delete persisted `reflectStep`
  - Surfaced by: Architecture §1 + outside-voice #1/#2 (decisions 2A+8A)
  - Files: `lib/features/reflect/providers/reflect_provider.dart`, `lib/features/daily/providers/daily_loop_provider.dart`
  - Verify: 6A widget test — relaunch inProgress → beat 1, hooks/gating fire once
- [ ] **T11 (P1, human: ~2h / CC: ~10min)** — persistence — `beat_data jsonb` migration + shape CHECK + client clamps + source-of-truth rule
  - Surfaced by: Architecture §1 (1A) + outside-voice #3/#13 (9A/21A)
  - Files: `supabase/migrations/`, `lib/features/reflect/providers/reflect_provider.dart`
  - Verify: pgtap CHECK test; round-trip unit test incl. overrun + null-legacy
- [ ] **T12 (P1, human: ~half day / CC: ~15min)** — tour — Hint render rule (first-run OR tour-active), gesture-teaching step copy, same step count; full-variant duas anchors preserved (first related dua expanded)
  - Surfaced by: Architecture §1 (3A) + outside-voice #4/#5/#15 (10A/11A-tour)
  - Files: `lib/features/tour/models/onboarding_tour_step.dart`, `lib/widgets/beat_reveal_flow.dart`, `lib/features/duas/`
  - Verify: tour widget test — step count, hint under tourActive with counter exhausted, both duas anchors
- [ ] **T13 (P1, human: ~half day / CC: ~10min)** — ai_service — Parser rung 1.5: per-field partial-structured degradation
  - Surfaced by: outside-voice #9 (15A)
  - Files: `lib/services/ai_service.dart`
  - Verify: unit tests over 3 partial shapes
- [ ] **T14 (P2, human: ~half day / CC: ~15min)** — beat_reveal_flow — In-canvas off-topic state (refund retained) + journal-cap upsell deferred to post-Ameen landing
  - Surfaced by: outside-voice #11/#14 (17A/18A)
  - Files: `lib/widgets/beat_reveal_flow.dart`, `lib/features/reflect/providers/reflect_provider.dart`
  - Verify: widget tests — refund fires, no sheet during flow
- [ ] **T15 (P1, human: ~half day / CC: ~15min)** — widgets — Extract shared `DuaTextBlock` (onSacredCanvas variant, owns the RTL rule); execute the §6.5 deletion + doc-sync list
  - Surfaced by: Code Quality §2 (4A/5A)
  - Files: `lib/widgets/dua_text_block.dart`, all five dua surfaces, CLAUDE.md, `docs/qa/ui-map.md`
  - Verify: grep shows no hand-rolled dua stacks; deleted symbols gone; docs updated
- [ ] **T16 (P1, human: ~1d / CC: ~30min)** — tests/eval — 6A test set (lifecycle, back, retry, round-trip, pgtap) + 2 regression criticals + 7A mechanical eval with pre-change baseline + 16A human source-review ship gate
  - Surfaced by: Test Review §3 (6A/7A/16A + iron rule)
  - Files: `test/`, `supabase/tests/`, eval suite, `docs/qa/`
  - Verify: `flutter test` + pgtap green (modulo known flaky baseline, recorded first)

_No new tasks from Performance §4._

**Failure modes audit:** every new codepath now has a named test AND error handling
AND a visible (never silent) user outcome — loading (SakinaLoader), API failure
(warm retry), off-topic (refund + retry), process death (re-hydrate/restart),
oversize output (client clamp), partial parse (rung 1.5), tour resume (forced
hint), journal cap (deferred upsell). **0 critical gaps** (silent+untested+unhandled).

**Worktree parallelization:** single-PR delivery (decision D2-A), but within it:
Lane A (`ai_service` schema/parser/eval) ∥ Lane B (`app_colors` tokens →
`BeatRevealFlow` + screens; depends on A's model fields) ∥ Lane C (duas extraction
+ canvas; depends on tokens + DuaTextBlock only) ∥ Lane D (journal restyle; depends
on tokens + splitIntoBeats). Launch A first, B after A's models land, C/D anytime
after tokens. Lanes B and C both touch tour anchors — coordinate the step-list edit.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — (last 2026-06-03, stale) | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — (CLI failing; Claude subagent ran as outside voice) | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 12 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR (FULL) | score: 6/10 → 9/10, 14 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **CROSS-MODEL:** outside voice (Claude subagent, code-verified) raised 16 findings; 11 accepted into the plan (per-surface gating/re-entry 8A, client clamps 9A, tour-proof hint 10A, full-variant duas anchors, parser rung 1.5, human source review, off-topic state, upsell deferral, duas extraction, share-card correction, source-of-truth rule), 2 declined by user decision (kill switch 13B, reverse-trial sequencing gate 14B), schema-vs-renderer challenge resolved in favor of keeping the schema (12B), 2 absorbed as corrections.
- **VERDICT:** DESIGN + ENG CLEARED — ready to implement.

NO UNRESOLVED DECISIONS
