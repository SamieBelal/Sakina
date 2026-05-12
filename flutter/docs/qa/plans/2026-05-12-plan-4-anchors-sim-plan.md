# Plan 4 — iOS Simulator Test Plan (2026-05-12)

Manual sim test for the Name Anchors backfill (32 → 98). The implementing
agent did NOT execute the simulator. The user should run the steps below
and append results to this file.

## Environment

- **Bundle ID:** `com.sakina.app.sakina`
- **Simulator:** iPhone 17 (UDID `708E6FCA-05B0-4CEC-A372-1E9BAAA6E07E`)
- **Logical viewport:** 402 × 874 pt
- **Bottom tab layout (y = 812):**
  - Home — x ≈ 40
  - Collection — x ≈ 120
  - Reflect — x ≈ 201
  - Duas — x ≈ 281
  - Journal — x ≈ 362

## Build & launch

```bash
cd flutter
flutter run -d 708E6FCA-05B0-4CEC-A372-1E9BAAA6E07E --dart-define-from-file=env.json
```

Wait for hot-reload-ready before navigating.

## Test path A — Collection tab → tap discovered card → anchor renders

**Purpose:** verify the anchor sentence renders in the Collection card detail
view for both pre-existing (in the original 32) and freshly-backfilled Names.

1. Tap Collection tab (x=120, y=812).
2. Scroll to find any unlocked Name.
3. Tap the Name tile.
4. Inspect the green callout area on the detail screen.
5. **PASS** = anchor sentence appears in human-readable English (e.g.
   "He sees everything others overlook in you." for Al-Baseer).
   **FAIL** = slug rendered as-is (e.g. literal "al-baseer"), empty box, or
   placeholder text.
6. Repeat for **at least 3** unlocked Names that were in the original 32
   (regression: al-rahman, al-rahim, al-wakil) and **at least 3** that are
   new in Plan 4 (al-malik, al-aleem, al-kabeer).

If the user's account does not have the Plan-4 names unlocked, use test path B
to surface them via the discovery quiz result screen instead.

## Test path B — Discovery quiz surfaces previously-orphan Names with anchor + detail

**Purpose:** verify that quiz results for Names that previously lacked
anchors now render their anchor + detail correctly.

1. From Home or Settings, launch the discovery quiz (per `discovery_quiz.dart`
   routing).
2. Answer the 6 questions in patterns that score the following 5 previously-
   orphan Names (one Name per quiz run; restart between):
   - `al-malik` (sovereignty / control theme)
   - `al-mubdi` (new beginnings)
   - `al-haseeb` (justice / being counted)
   - `al-jami` (reunion / loss)
   - `ar-rauf` (gentleness)
3. On each result screen, confirm:
   - The Name anchor (1-line) renders cleanly.
   - The Name detail (paragraph) renders cleanly below.
   - Arabic calligraphy displays without bleed (Aref Ruqaa metric issue —
     covered separately by `AdjustedArabicDisplay`).
4. **PASS** = all 5 result screens show populated anchor + detail.
   **FAIL** = any of the 5 shows a slug, empty text, or "anchor not found".

If the quiz scoring functions don't deterministically route to these specific
Names, sample 5 result Names whatever they are, and confirm anchor + detail
populate for each (the coverage test guarantees they're all in the JSON).

## Test path C — Sample 10 random Names across the alphabet

**Purpose:** breadth check across the 98 anchors. Sample includes top, middle,
and bottom of the alphabetical-by-`name_key` list.

| # | name_key | transliteration | Confirm anchor renders | Confirm detail renders |
|---|----------|-----------------|------------------------|------------------------|
| 1 | ad-darr | Ad-Darr | ☐ | ☐ |
| 2 | al-azeez | Al-Azeez | ☐ | ☐ |
| 3 | al-bari | Al-Bari | ☐ | ☐ |
| 4 | al-hayy | Al-Hayy | ☐ | ☐ |
| 5 | al-malik | Al-Malik | ☐ | ☐ |
| 6 | al-quddus | Al-Quddus | ☐ | ☐ |
| 7 | al-wakil | Al-Wakeel (slug=`al-wakil`) | ☐ | ☐ |
| 8 | ar-rahman | Ar-Rahman | ☐ | ☐ |
| 9 | az-zahir | Az-Zahir | ☐ | ☐ |
| 10 | dhul-jalali-wal-ikram | Dhul-Jalali wal-Ikram | ☐ | ☐ |

For each: use whichever surface the user can navigate to most easily —
collection detail, quiz result, or settings → "Resonant Name" card if the
profile is configured for that Name.

If a Name isn't unlocked, the discovery quiz is the primary surfacing
mechanism. Alternatively, the user can dev-only seed via Supabase Studio
(out of scope for this sim pass).

## Regression checks

Run after the above:

- [ ] **Original 32 anchors unchanged.** Pick 3 (al-afuw, al-fattah,
      ar-razzaq) and confirm anchor text matches the pre-Plan-4 wording
      (no copyedit drift). Diff against `git show HEAD~1:assets/content/name_anchors.json`.
- [ ] **Gacha overlay still works post-checkin.** Complete a daily check-in,
      verify the `NameRevealOverlay` phase progression still gates correctly
      (regression test for the 2026-04-27 gacha eager-dismiss fix).
- [ ] **`findCanonicalName` test suite green.** Run
      `flutter test test/services/validate_names_test.dart` (or equivalent).
- [ ] **No console errors on launch.** `flutter logs` should not surface
      `Expected 98 rows for name_anchors, got X` — that's the canary for the
      contract bump being missed.

## Recording results

After the run, append a `## Simulator verification YYYY-MM-DD` section to this
file with:
- iOS Simulator OS version
- Tester initials
- Pass / fail per path
- Screenshots (saved alongside in `docs/qa/runs/`)

## Notes for the agent who ran the authoring

- I (the authoring agent) did NOT run the simulator myself.
- All 98 entries pass the coverage test (`flutter test test/content/name_anchors_coverage_test.dart` GREEN).
- 3 entries (`al-muzill`, `al-khafid`, `ad-darr`) tagged for theological
  review before sim sign-off — see `2026-05-12-plan-4-anchor-authoring-ledger.md`.
