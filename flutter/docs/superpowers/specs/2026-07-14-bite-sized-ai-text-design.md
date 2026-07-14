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
per convention). Full-screen, warm cream background, subtle geometric accent at
≤8% opacity per design system.

- **Segmented progress bar** at top (one segment per screen, Glorify/IG-story style),
  emerald fill on cream track.
- **Tap right 60% of screen** → next; **tap left 40%** → previous. Haptic light impact
  on advance. No auto-advance.
- **Skip affordance:** subtle "Skip to dua" text button, top-right, `labelMedium`
  tertiary color. Jumps to the dua screen (never skips saving/economy hooks).
- Each screen: one idea, vertically centered, staggered fade-in (existing
  `flutter_animate` patterns).
- Accessibility: whole-screen `Semantics` with the full text of that beat; respects
  reduced-motion by dropping the animations, not the screens.

**Screen inventory (muḥāsabah / Reflect):**

| # | Screen | Content | Typography |
|---|--------|---------|------------|
| 1 | Key line | `reframeKey` | DM Serif Display, large, pull-quote treatment |
| 2 | Reframe | `reframeBody` | `bodyLarge`, generous leading |
| 3 | Story open | `storyTitle` + `storyBeats[0]` | title `headlineSmall` serif, beat `bodyLarge` |
| 4..n | Story beats | `storyBeats[1..]`, source line styled small/tertiary on the last beat | `bodyLarge` |
| n+1 | Takeaway | `takeaway` | serif, medium, gold accent bar |
| n+2 | Dua | Arabic + transliteration + translation + source **together on one screen** (recitation requires the trio; separate `Text` widgets with explicit `textDirection` per RTL rule) | existing `quranArabic` + body styles |
| final | Ameen CTA | existing Ameen button + quest/economy hooks unchanged | — |

Total ~7 taps. The existing coarse step machine (`reflectStep` 0-3 in
`daily_loop_provider.dart` / Reflect's equivalent) is replaced by the flow's internal
index; the provider keeps a single "deeper reflection in progress / completed" state
so Ameen-side effects (quests, card engagement, journal save) fire exactly as today.

**Build-a-Dua** (`duas_screen.dart`): keep the existing 4-section step viewer
(sections are already the right granularity). Within a section, adopt the staggered
reveal (label → Arabic → transliteration → translation fade in sequentially, all end
visible together) and the segmented progress bar. Ameen screen: related duas collapse
into expandable cards (title + source visible; tap to expand full text).

## 4. Renderer B — `ChunkedSectionView` (scrollable, re-reading)

New shared widget for journal detail (`reflection_detail_page.dart`) and the
Ameen/share summary:

- `reframeKey` rendered as a pull quote (serif, gold accent bar).
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
| Build-a-Dua (`duas_screen.dart`) | staggered section reveal + progress bar | sections unchanged; Ameen related-duas collapse |
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

## 9. Out of scope / later

- Tap-through for the *names* catalog detail screens (static content; revisit after
  this ships).
- Ambient per-beat visuals (gradient shifts, illustrations) — flow ships with the
  standard cream background first; visual layering is a polish pass.
- Prompt-side localization of beats (i18n-ready strings apply to UI chrome only;
  AI output language handling is unchanged).
