# Duʿā Acceptance Times — Widget Design Spec

**Date:** 2026-07-15
**Status:** Design — pending user review
**Author:** Ibrahim + Claude

## 1. Goal

A time-aware surface that tells the user, in the moment, whether they are inside
one of the Islamically-recognized windows when duʿā is more likely to be
accepted (*awqāt al-ijābah*) — and when they are not, counts down to the next
one. Special Islamic days/nights layer on top of the recurring daily windows.

The **"best time to make duʿā"** framing is the hero. Special days are the
secondary layer. Both are delivered on two surfaces: an **in-app home card** and
a **native iOS home-screen widget**.

Tone rule: these are times of *hope*, never a guarantee. Copy says "a beloved
time to raise your hands," never "your duʿā will be accepted."

## 2. Scope

### In scope (v1)
- Precise, location-aware recurring windows via on-device prayer-time calc.
- Location-independent calendar windows (Friday + seeded Islamic days).
- In-app card (render-gated, mirrors `RamadanGiftCard` pattern).
- Native iOS widget (small, medium, lock-screen accessory) with live countdown.
- Graceful degrade to calendar-only windows when location is unavailable/denied.
- **No madhab setting (D6).** Dropped — the Friday window anchors to Maghrib
  (sunset), not ʿAsr, so nothing in the feature is madhab-dependent. No madhab
  is gathered or stored.

### Out of scope (deferred)
- **Scheduled notifications** ("ʿArafah is tomorrow", "the night-third has begun") → Phase 2. Requires `flutter_local_notifications` scheduling per device/location; OneSignal (server-push) cannot do location-local timing cleanly.
- **Android home-screen widget** → follow-on (no Android widget exists in repo today; the in-app card covers Android in v1).
- **Adhān / iqāmah window** → dropped (iqāmah time is mosque-specific, not computable).
- **Qibla, adhan alerts, full prayer-times UI** → explicitly NOT built. This feature is duʿā-timing, not a prayer-times product (see §12).
- **Rain window** → dropped for v1 (needs weather API + location sent off-device).

## 3. Content model — the curated windows

All content is a **curated, sourced constant list** in Dart (e.g.
`lib/features/dua_times/data/dua_window_catalog.dart`). No AI generation, no
fabrication (per `CLAUDE.md`). Each window carries a hadith source reference for
an optional "why" disclosure.

### Recurring windows (location-dependent unless noted)

| Window | Timing | Source | Needs location? |
|---|---|---|---|
| Last third of the night | Maghrib→Fajr, final third (`adhan_dart` `SunnahTimes.lastThirdOfTheNight`) | al-Bukhari 1145 | Yes |
| The Friday hour | **last hour before Maghrib** on Friday (sunset-anchored, D6) | al-Bukhari 935, Muslim 852; Abu Dawud/Nasa'i "seek it in the last hour" | Friday = no; the *hour* = yes (Maghrib) |
| Iftar moment (Ramadan) | ~20 min before Maghrib during Ramadan | Tirmidhi 3598 (fasting person's duʿā) | Yes |

Soft framing when location is absent: "the depths of the night" keyed to the
device clock (justified by Muslim 757, "an hour each night") — humble copy only,
never a precise claim.

### Calendar windows (location-independent, all-day/all-night)

| Day / night | Hijri anchor | Source | Data source |
|---|---|---|---|
| Friday (Jumuʿah) | weekday | — | device weekday |
| Day of ʿArafah | 9 Dhul-Ḥijjah | Tirmidhi 3585 (best duʿā of the year) | `dua_windows` |
| First 10 days of Dhul-Ḥijjah | 1–10 Dhul-Ḥijjah | al-Bukhari 969 | `dua_windows` |
| Last 10 nights / Laylat al-Qadr (odd emphasis) | 21–30 Ramadan | al-Bukhari 2020 | `dua_windows` |
| All of Ramadan | Ramadan | — | `dua_windows` |
| ʿAshura (+ 9th) | 9–10 Muharram | Muslim 1162 | `dua_windows` |
| White Days | 13–15 each Hijri month | Tirmidhi 761 | `dua_windows` (seeded ahead) |
| The two Eids | 1 Shawwal, 10 Dhul-Ḥijjah | — | `dua_windows` |

**Excluded:** 15 Shaʿbān (Shab e Barāʾah) — scholarly-contested; consistent with
the prior decision to remove Mawlid occasions.

**Authority — single seeded source (D3, D4).** ALL dated duʿā days, including the
monthly White Days, come from a **new `dua_windows` table** seeded server-side
for several years ahead (±0 moon-sighting error). We do **NOT** reuse
`islamic_occasions` — that table powers the paid Sakina Gift, and
`GiftService.currentOccasion()` (gift_service.dart:132) matches any active row
with no `kind` filter, so adding duʿā rows there would make the gift card grant
premium on ʿArafah/ʿAshura/etc. Separate table = zero gift blast radius, one
source of truth, and no on-device `hijri` dependency (dropped). Friday remains a
pure device-weekday check (no data needed).

## 4. Detection engine

### Prayer times
- `adhan_dart` (pure Dart, MIT, no runtime deps, Dart 3.11 compatible). Computes
  Fajr/Sunrise/Dhuhr/Asr/Maghrib/Isha + `SunnahTimes` (last third / middle of
  night) offline from lat/long + date + method. (No madhab — ʿAsr is unused, D6.)
- **Pin the exact version and verify the API before building (step 0 of impl).**
  The port has historically re-cased/renamed members. Confirm `SunnahTimes`
  exposes `lastThirdOfTheNight` in the pinned version and add a one-line
  compile-guard test that references the symbol, so an upgrade that renames it
  fails CI instead of silently breaking the night-third path.
- High-latitude rule configured (Fajr/Isha can be undefined above ~48° in
  summer) — pick a sane `HighLatitudeRule` default.

### Location
- `geolocator` — coarse accuracy is sufficient. Cache last lat/long in
  `SharedPreferences` so the app works offline and does not re-prompt.
- iOS `Info.plist`: `NSLocationWhenInUseUsageDescription`. Android manifest:
  `ACCESS_COARSE_LOCATION`.
- Permission denied / services off → degrade to calendar-only (§9).

### Calendar
- New **`dua_windows`** table (Supabase), public-readable like the catalog,
  seeded server-side for ~5 years of dated days (ʿArafah, Dhul-Ḥijjah 1–10,
  last-10-nights, Ramadan, ʿAshura, White Days, Eids). Schema:
  `id, kind, tier, hijri_date/date bounds, source_ref, location_dependent`.
- **All-day windows are anchored to the device's local day, not a fixed UTC
  instant.** Seed each all-day day as a bare (Hijri/Gregorian) **date**; the
  device expands it to its own local midnight→midnight. A fixed UTC `starts_at`
  would open ʿArafah up to ~13h early/late at the date line (Honolulu/Auckland).
- **Cold-start offline:** bundle the calendar export as a **Flutter asset** too
  (not only in the widget extension), so a first launch with no network still
  shows dated windows instead of only Friday + soft night.
- **Seed-horizon safety:** store a `last_seeded_through` sentinel; the app runs a
  health check and warns (and we log to TODO.md) well before the horizon, so the
  feature never silently goes blank when the seed runs out.
- Fetched via the existing public-catalog read pattern; cached locally. The
  widget's bundled fallback JSON is a build-time export of this table.
- No on-device Hijri calc; `hijri` package NOT added.

### Window resolution
- `DuaWindowEngine` computes, for a given `now` + location: the **active**
  window (if any) and the **next** window, plus an ordered schedule for the next
  N days (for the widget timeline).
- **Night-third — which date's `PrayerTimes`?** The window Maghrib→Fajr spans
  local midnight. At 02:00 you are in the third that opened at *yesterday's*
  Maghrib, but `SunnahTimes(PrayerTimes(today))` yields tonight's Maghrib→
  tomorrow's Fajr. Rule: **before today's Fajr, instantiate from yesterday's
  `PrayerTimes`; at/after Maghrib, from today's.** Precise-instant windows,
  never truncated at midnight, never double-counted. (Tested at exactly 02:00.)
- Overlap priority (highest wins for the hero line): ʿArafah > Laylat-al-Qadr
  nights > last-third-of-night > Friday hour > Ramadan/other special day >
  Friday (day) > White Days. Secondary windows can still be listed.

## 5. Settings & defaults

- **Madhab: none (D6).** Removed. Madhab only ever affects ʿAsr, and the Friday
  window now anchors to Maghrib (sunset), not ʿAsr — so no prayer in the feature
  is madhab-dependent. This deletes both a Settings toggle AND an onboarding
  "gather your madhab" step. Faithful to the hadith ("the last hour"), since a
  madhab-precise ʿAsr would be false precision for a devotional nudge.
- **Calculation method:** default Muslim World League (MWL). Fixed in v1 (not
  user-exposed) to keep the surface small; expandable later. (Method sets the
  Fajr/Isha twilight angle → the night-third boundary; it is NOT madhab.)
- These are local device settings (SharedPreferences), not economy/server data.

## 6. Architecture & components

New feature module: `lib/features/dua_times/`

```
dua_times/
  data/
    dua_window_catalog.dart        # curated sourced window definitions + copy keys
  models/
    dua_window.dart                # Freezed: type, tier, titleKey, sourceKey, start, end
    dua_window_schedule.dart       # active + next + upcoming[]
  services/                        # (or lib/services/ per convention)
    prayer_time_service.dart       # adhan_dart wrapper → PrayerTimes + SunnahTimes
    location_service.dart          # geolocator + cache + permission state
    dua_window_engine.dart         # composes prayer + calendar → schedule
  providers/
    dua_window_provider.dart       # Riverpod; ticking active/next state for the card
  widgets/
    dua_times_card.dart            # in-app home card (render-gated)
```

Services stay in the service layer (no Riverpod inside services; use the
`onAnalyticsEvent` static-hook pattern if emitting events from a service).

## 7. Data flow (app → widget)

```
DuaWindowEngine (Flutter)
  → computes ~7-day schedule (deterministic from location + calendar)
  → JSON-encodes schedule
  → WidgetDataService.saveWidgetData(kDuaTimesPayloadKey, json)
  → WidgetDataService.updateWidget(name: kDuaTimesWidgetName)  // reloads timeline
```

The payload is **stamped with `computed_at: {tz, lat, lon}`** (D5) so the widget
can detect travel — see §9/§10.

Recompute + push triggers: app foreground, location change, date rollover,
madhab setting change. Precomputing ~7 days keeps the widget correct even if the
app isn't opened (well within the 40–70 reloads/day budget — ~1 reload/day).

New constants in `widget_data_service.dart`:
- `kDuaTimesWidgetName = 'SakinaDuaTimesWidget'` (new WidgetKit kind)
- `kDuaTimesPayloadKey = 'sakina_dua_times_payload'`
Same App Group `group.com.sakina.app.widget`.
- **Extend `clearWidget()` (widget_data_service.dart:148) to also null
  `kDuaTimesPayloadKey`** on sign-out/account-delete. It currently wipes only the
  Name payload; without this a second user on the device inherits the first
  user's location-derived schedule (leaks approximate home location).

## 8. In-app card UI

`DuaTimesCard`, render-gated like `RamadanGiftCard`, placed on the primary home
surface (candidate: alongside `RamadanGiftCard` in `progress_screen.dart` and/or
the main home dashboard — exact slot finalized in the plan).

CTA-first, on the emerald **sacred canvas**, using the same copy + escalation
ladder as the widget (§9.1) but with color available throughout:
- **Active:** "Make your duʿā" + short "why" (source-backed) + live Dart-`Timer`
  countdown to close → gold "Ask now" CTA. Shifts to the **amber last-call**
  treatment under 15 min.
- **Between:** "Build your duʿā · {upcoming day}" + static relative label →
  "Build now" CTA (drives Build-a-Duʿā off-window too).

Ticking via a Dart `Timer` in the provider. Arabic/English never mixed in one
`Text` (per `CLAUDE.md`); use `AdjustedArabicDisplay` for the `دُعَاء` accent.

## 9. Native iOS widget

**Second widget in `SakinaWidgetBundle`** (new `SakinaDuaTimesWidget: Widget`,
new kind). Families: `.systemSmall`, `.systemMedium`, `.accessoryRectangular`.

- **Compute in Flutter, render in Swift.** Extension needs NO location, NO
  prayer math — it reads the precomputed schedule JSON from the App Group.
- **Timeline:** `TimelineProvider` reads the schedule, emits entries at each
  window **boundary** (open/close), not per-second.
- **Live countdown — near targets only.** `Text(timerInterval:)` renders a
  running `HH:MM:SS` clock, not "in 3 days." Use the live timer only when the
  target is near (≲1h, or same-session window close); for far "next window"
  targets show a **static relative label** ("Fri", "in 3 days", "Tomorrow,
  ʿArafah"). Don't route a multi-day countdown through `timerInterval`.
- **Travel guard (D5).** The payload carries `computed_at.tz`. The extension
  reads `TimeZone.current`; if it differs from the stamp, **suppress precise
  windows** and render calendar + soft-night only. Prevents showing the old
  city's prayer times as local after the user flies without reopening the app.
- **Reload policy:** `.after(lastEntryDate)` + app-triggered
  `WidgetCenter.reloadTimelines` on foreground/location/date change.
- **Bundled calendar fallback:** ship a `dua_calendar.json` in the extension
  (like today's `catalog.json`) so Friday + seeded special days still render
  correctly when the schedule is stale, location was never granted, or the
  travel guard tripped. Only the precise night-third/Maghrib windows are lost
  until the app refreshes at the new location.
- **Deep link:** `widgetURL` → `sakina://widget/build-dua` (reuse existing
  deep-link routing in `widget_deep_link.dart`). The whole widget AND every CTA
  point at Build-a-Duʿā — this widget's north star is Build-a-Duʿā retention.

### 9.1 Visual design & copy (approved 2026-07-15)

**North star:** every surface is a *straight call to action* that escalates
urgency as the window closes. Mockup reference:
`docs/superpowers/specs/mockups/dua-times-widget-mockups.html`.

**Fonts & palette — match the existing `SakinaWidget` exactly.** Reuse the
`Palette` enum already in `SakinaWidget.swift` (emerald `#1B6B4A`, gold
`#C8985E`, amber `#E8A154`, cream `#FBF7F2`, ink `#2C2A26`). Type:
- **Arabic accent** (small `دُعَاء` / crescent) → `ArefRuqaa-Regular`, emerald,
  own RTL widget (never mixed with Latin).
- **All Latin** (verb, CTA, cue) → `Outfit` — verb `.bold/.heavy`, CTA
  `.semibold`, cue `.medium`. **No DM Serif** (the mockup used it; the shipping
  widget stays Outfit-only to match the Name widget).
- SF Symbols: `moon.stars` (comfortable/active), `moon` (between),
  `exclamationmark.circle.fill` (last-call).

**Families:** `.systemSmall`, `.systemMedium`, `.accessoryRectangular`,
`.accessoryInline`. (Skip `.accessoryCircular` — a ring to a multi-hour window
is misleading.)

**Lock screen is monochrome** — urgency is carried ONLY by the ticking number +
glyph swap, never color.

**Per-family copy by state:**

| State | accessoryRectangular (1 line) | accessoryInline | systemSmall | systemMedium |
|---|---|---|---|---|
| Comfortable (>1h) | `☾ Make duʿā now · until Fajr` | `☾ Make duʿā now · until 4:52` | verb "Make your duʿā" + "until Fajr" + gold "Ask now →" | crescent+`دُعَاء` hero · "A beloved time" / "Make your duʿā" / why · "until Fajr" + gold "Ask now →" |
| Closing (<1h) | `☾ Make duʿā now · 47:12 left` (live) | `☾ Make duʿā now · 47:12` | live countdown replaces static cue | live countdown in footer |
| Last call (<15m) | `⚠ Ask before it closes · 11:40` (live) | `⚠ Ask before 4:52` | **amber** card, "Ask before it closes", live | **amber** accent, "Ask before Fajr", live |
| All-day active (ʿArafah…) | `☾ Make duʿā now · today only` | `☾ ʿArafah · make duʿā` | "today only" (no ticking) | day name + "the best duʿā of the year" |
| Between | `☽ Build your duʿā · ʿArafah tomorrow` | `☽ Build duʿā · ʿArafah tomorrow` | "Build your duʿā" + "ʿArafah" + gold "Build →" | "Coming tomorrow" / "Build your duʿā" / "opens in 14h" + gold "Build now →" |

**Escalation ladder (drives the countdown-format decision from §9 bullet 3):**

| Window kind | >1h | <1h | <15m |
|---|---|---|---|
| Time-boxed (night-third, Friday hour, iftar) | calm static deadline | live `Text(timerInterval:)` | amber + `exclamationmark.circle.fill` + sharper verb |
| All-day (ʿArafah, ʿAshura, White Days) | "today only" — no ticking (a day isn't a countdown) | — | — |
| Between (upcoming) | static relative label ("tomorrow", "in 3 days") | — | — |

The in-app **card (§8)** uses the same copy/escalation ladder but on the emerald
sacred canvas with color available throughout, and a live Dart-`Timer` countdown.

## 10. Degrade / fallback / edge cases

- **Permission denied / location off:** calendar-only windows (Friday + special
  days) + soft night framing. Card shows a **prominent "Turn on precise times"
  banner** (gold-bordered, full-width, with a "Turn on" action + a necessity
  subline naming the countdown AND the widget). This is NOT subtle: location is
  the switch that unlocks the whole feature — the WIDGET can never show precise
  times (an extension can't request location) until the app computes a located
  schedule, so the prompt must be unmissable.
- **High latitude:** apply `adhan_dart` high-latitude rule; if a window is still
  undefined, omit it silently (don't show a wrong time).
- **Travel / location change:** the *app* recomputes on significant change. The
  *widget* can't (no background location), so it relies on the **`computed_at.tz`
  travel guard** (§9, D5) to suppress precise windows until the app refreshes.
- **DST / timezone:** precise windows stored as absolute UTC instants (correct
  across DST); all-day calendar windows stored as bare dates, expanded to
  device-local midnight (§4).
- **Stale schedule:** widget falls back to bundled calendar; app refreshes on
  next foreground.

## 11. Analytics

New event-name constants in `analytics_event_names.dart`; emit via providers /
`onAnalyticsEvent` hook (not from services directly):
- `dua_times_card_impression` (with `active_window` / `next_window` props)
- `dua_times_card_cta_tap` (→ build-dua / muhasabah)
- `dua_times_location_prompt` / `_granted` / `_denied`
- `dua_times_widget_installed` (reuse existing widget-install analytics where possible)

## 12. Scope exception (ADR)

Path B crosses the `CLAUDE.md` "no prayer times / qibla" line. This is an
**intentional, bounded exception**: prayer times are used only as an *input* to
duʿā-timing. We will NOT add adhan alerts, a prayer-times screen, or qibla. A
short ADR will be added under `docs/decisions/` recording this boundary so it is
a deliberate decision, not scope drift.

**App Store submission risk (log in `TODO.md`).** A location permission whose
only visible use is prayer timing draws review scrutiny (data-minimization). Ship
coarse-only, a clear `NSLocationWhenInUseUsageDescription` purpose string, the
lazy prompt (§15), and a privacy-label / review-note stating **location never
leaves the device**. The §12 ADR is internal; the reviewer-facing mitigation is
separate and belongs in the release checklist.

## 13. Phasing & build order

- **v1 (one release):** engine + in-app card + native iOS widget + degrade path + ADR.
- **Internal build order (D2):** `dua_windows` table + seed → `PrayerTimeService`
  + `LocationService` → `DuaWindowEngine` (fully unit-tested) → `DuaTimesCard`
  (validate the window logic live) → schedule serialization → **native widget
  last**, consuming a schedule the card already proved correct.
- **Phase 2:** scheduled local notifications; Android widget; optional rain
  window. (No madhab work — dropped per D6.)

## 14. Testing

Coverage target: every `DuaWindowEngine` branch + the serialization contract.

- **`PrayerTimeService`** — known lat/long/date fixtures vs published times;
  `SunnahTimes.lastThirdOfTheNight` correctness. (No madhab test — dropped, D6.)
- **`DuaWindowEngine`** — active vs between resolution; next-window target;
  overlap priority; Friday-hour only Fri (last hour before Maghrib); iftar only in Ramadan;
  **night-third spanning local midnight** (regression-class edge — keyed to the
  night, not truncated at midnight); high-latitude undefined → omitted;
  permission-denied → calendar-only schedule; 7-day schedule generation; DST
  boundary correctness (absolute-instant windows).
- **Serialization contract test** — the JSON the engine pushes to the App Group
  must match the Swift decoder's shape. A golden test on the payload prevents a
  silent drift where the widget quietly falls back to bundled calendar and users
  never see precise windows. Mirror the field names in a shared fixture.
- **`LocationService`** — permission states, cache hit/miss, denied fallback.
- **Travel guard** — schedule stamped tz ≠ device tz → precise windows
  suppressed, calendar-only rendered (engine-side test of the suppression
  predicate the Swift guard mirrors).
- **All-day date-line** — ʿArafah opens/closes at *device-local* midnight in
  Honolulu (UTC-10) and Auckland (UTC+13), not a shared UTC instant.
- **Cold-start offline** — no network, empty `dua_windows` cache → engine reads
  the bundled Flutter asset and still surfaces an active dated window.
- **Sign-out wipe** — `clearWidget()` nulls `kDuaTimesPayloadKey` (no schedule
  leaks to the next user).
- **Widget test** — `DuaTimesCard` active vs between-windows states + CTA deep link.
- **Gift regression** — *avoided by design*: D3 uses a separate `dua_windows`
  table, so `GiftService`/`islamic_occasions` is untouched. No new gift test
  needed beyond the existing suite; do NOT add rows to `islamic_occasions`.
- **Manual** — native widget on a physical device (families, countdown, deep
  link, stale/bundled fallback). Note pre-existing flaky-test baseline.

## 15. Decisions locked (2026-07-15 eng review)

- **D2 — scope:** full v1 (card + native widget), sequenced internally per §13.
- **D3 — calendar data:** new `dua_windows` table; `islamic_occasions` untouched
  (gift blast-radius averted).
- **D4 — Hijri source:** all dated days (incl. White Days) seeded server-side;
  on-device `hijri` package dropped. Single source of truth.
- **D5 — widget travel safety:** payload stamped with `computed_at.tz`; Swift
  suppresses precise windows when device tz differs (calendar + soft-night
  fallback). Precise-in-widget preserved without lying after travel.
- **D6 — no madhab (2026-07-15):** the Friday window anchors to the last hour
  before **Maghrib** (sunset), not ʿAsr. ʿAsr is the only madhab-dependent
  prayer and it's now unused, so the `madhab` param, the Settings toggle, and
  the onboarding "gather madhab" step are all deleted. `Madhab` removed from
  `PrayerTimeService` + `DuaWindowEngine`.

### Remaining defaults (confirm or adjust anytime)

1. **In-app card placement** — default: primary home dashboard, mirroring the
   gift card's render-gating. (Confirm exact slot during impl.)
2. **Eid inclusion** — included as "blessed day" framing.
3. **Location prompt timing** — lazy, first time the card would show a precise
   window, not on launch.

## GSTACK REVIEW REPORT

**Skill:** /gstack-plan-eng-review · **Date:** 2026-07-15 · **Target:** this spec
(`docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md`) ·
**Branch:** master

### Runs / Status

| Run | Status | Notes |
|---|---|---|
| Scope gate (D1) | ✅ | Target confirmed = this design spec |
| Step 0 scope challenge | ✅ | Complexity trigger raised → D2 (full v1, sequenced) |
| Architecture review | ✅ | D3 (P1 gift blast-radius), D4 (P2 Hijri drift) |
| Code quality review | ✅ | No standalone findings (no code yet); folded into arch |
| Test review | ✅ | Coverage plan written incl. serialization contract + edges |
| Performance review | ✅ | No blockers — prayer calc is ms; guard against per-build recompute (cache schedule; Timer updates label only) |
| Outside voice | ⚠️→✅ | Codex CLI broken (`ENOENT`, vendored darwin-arm64 binary missing) → Claude subagent fallback. Surfaced 10 findings; P1 travel-lie promoted to D5, 7 folded as fixes |

### Findings absorbed

| ID | Sev | Finding | Resolution |
|---|---|---|---|
| D2 | — | v1 bundles 3 services + 2 surfaces | Full v1, build order engine→card→widget |
| D3 | P1 | Reusing `islamic_occasions` → gift card grants premium on ʿArafah | New `dua_windows` table; gift table untouched |
| D4 | P2 | Two Hijri sources drift (seeded vs on-device) | Seed all days; drop `hijri` pkg |
| D5 | P1 | Widget shows old-city prayer times after travel | Stamp `computed_at.tz`; Swift suppresses precise on tz mismatch |
| — | P1 | Night-third off-by-one (which date's `PrayerTimes`) | Explicit rule + 02:00 test (§4, §14) |
| — | P1 | `adhan_dart` symbol unverified | Pin version + compile-guard test (§4) |
| — | P2 | `Text(timerInterval:)` can't render multi-day | Live timer <1h only; static label else (§9) |
| — | P2 | App cold-start offline drops dated windows | Bundle calendar as Flutter asset (§4) |
| — | P2 | Seed-horizon cliff | `last_seeded_through` sentinel + health check + TODO (§4) |
| — | P2 | All-day window anchor tz ambiguous | Seed bare date, expand to device-local midnight (§4) |
| — | P2 | App Store location-permission risk | Coarse + purpose string + review note → TODO (§12) |
| — | P3 | Sign-out leaks schedule to next user | Extend `clearWidget()` to null dua-times key (§7) |

### VERDICT

**APPROVE with the above absorbed.** Plan is boring-by-default where it counts
(reuses App Group + home_widget + adhan_dart; no hand-rolled astronomy),
reversible (phased, feature-gated card), and the two money/trust P1s (gift
blast-radius, travel-lie) are closed by design. CODEX absorbed via Claude
fallback (CLI unavailable). No blocking issues remain.

NO UNRESOLVED DECISIONS
