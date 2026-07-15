# Home-Screen Widget — "A Name for What You're Carrying"

**Date:** 2026-07-14
**Status:** Design approved, pending spec review → implementation plan
**Author:** Ibrahim Ahmed (with Claude)

## 1. Summary

Ship Sakina's first home-screen widget: a daily, glanceable card that presents a
Name of Allah **as the answer to an emotional state** — the exact framing of our
best-performing reel ("the Name of Allah that solves what you're going through").
The widget copies the two empirically proven retention mechanics in this category —
**fresh daily content** (YouVersion Verse-of-the-Day → 19M single-day opens) and
**streak / loss-aversion** (Duolingo → half of widget-installers hold 6-month
streaks; Gratitude → +25% retention for widget users) — while routing taps into
our #1 feature (muḥāsabah) and #2 feature (build-a-dua).

## 2. Why this widget (evidence)

**Feature usage, last 30 days (Supabase, 664 active / 865 total users):**

| Feature | Events | Unique users | Reach of active base |
|---|---|---|---|
| Card discovered (gacha) | 3,332 | 711 | ~universal |
| Muḥāsabah check-in | 2,035 | 662 | ~universal |
| Build-a-dua | 593 | 389 | ~59% |
| Reflect | 206 | 104 | ~16% |

The daily muḥāsabah loop is the retention spine; build-a-dua is a strong #2. The
widget leads with the muḥāsabah/Name content and offers build-a-dua as a secondary
action.

**Reel alignment:** the reel's content already exists as structured data in
`name_anchors` (98 rows, public catalog, anonymously readable):
- `anchor` — punchy emotional hook (e.g. *"Even what causes you pain is under His authority."*)
- `detail` — the teaching / short story
- plus `name`, `arabic`, `name_key`

`collectible_names` (99 rows) adds `meaning`, `lesson`, `hadith`, and a per-Name dua
if richer content is wanted later.

**Widget best-practice constraints honored:** glanceable value with no required tap;
changes daily (never stale); renders logged-out (public content); not a bare
launcher; refreshes once per local midnight (fits the WidgetKit timeline budget).

## 3. Scope (v1 decisions)

- **Platform:** iOS first (WidgetKit / SwiftUI), Android (Jetpack Glance) as a fast-follow. This spec covers iOS; the Android port reuses the same shared-data contract.
- **Surfaces:** `systemSmall`, `systemMedium` (Home Screen) + one Lock Screen accessory (`accessoryRectangular`). `systemSmall` auto-appears in StandBy for free ambient impressions.
- **Hero layout (Medium):** **Direction B** — Arabic Name as the calligraphic hero on the left ~40%, meta stacked on the right (gold-ink kicker → anchor line → English → streak/dua footer). Approved via design review 2026-07-14 (see §5 and Approved Mockups).
- **Content source (hybrid):** if the user has completed today's muḥāsabah, show the Name they received; otherwise show a **global deterministic daily Name** from `name_anchors` (keyed to day-of-year, same rotation grammar as `getTodaysName()`), as a fresh hook that pulls them into a check-in.
- **Streak on face:** yes — the muḥāsabah streak (🔥 count) renders on the Medium + Lock Screen surfaces.
- **Rendering:** native SwiftUI (not Flutter-rendered-to-image), for correct Aref Ruqaa / Amiri Arabic typography and premium fidelity. Flutter provisions data only.

## 4. Architecture

### 4.1 Components

1. **`WidgetDataService` (Dart, `lib/services/`)** — the single writer of widget state.
   Wraps the `home_widget` package. Exposes `syncWidget()` which composes the current
   widget payload and writes it to the shared container (iOS App Group / Android
   prefs), then calls `HomeWidget.updateWidget(...)`.
2. **Shared data contract** — a small, flat, JSON-serializable payload (see 4.3)
   written to the App Group so the native extension can read it with zero network.
3. **Bundled anchor catalog** — the 98 `name_anchors` rows shipped **inside the widget
   extension** as a bundled JSON resource, so the widget renders the daily Name fully
   offline and for logged-out users. Regenerated at build time from Supabase via a
   small script (kept in sync with the DB; content is static/public).
4. **iOS widget extension (`SakinaWidget`, SwiftUI + WidgetKit)** — `TimelineProvider`
   produces one entry per local day (midnight boundary, `.after(nextMidnight)` policy),
   selecting the Name: personalized if the shared payload says "checked in today",
   else the deterministic daily index into the bundled catalog. Renders small / medium /
   accessory layouts.
5. **Deep-link handling** — `widgetURL` on small/accessory; `Link` regions on medium.
   URLs map to existing GoRouter routes.

### 4.2 Data flow

```
App event (check-in done, streak change, app foreground, login/logout)
        │
        ▼
WidgetDataService.syncWidget()   ── writes payload ──▶  App Group shared store
        │                                                      │
        └── HomeWidget.updateWidget() ─▶ WidgetCenter reload    ▼
                                              TimelineProvider reads payload
                                              + bundled anchor catalog
                                                     │
                                                     ▼
                                        SwiftUI renders small/medium/accessory
                                                     │
                                              tap → widgetURL / Link
                                                     ▼
                                     app .onOpenURL → GoRouter route
```

The widget never calls Supabase or the network. Personalized state arrives only
through the payload the app writes; if absent (fresh install, logged out), the widget
falls back to the deterministic daily Name from the bundled catalog.

### 4.3 Shared payload (contract)

```json
{
  "mode": "personalized" | "daily",
  "name_key": "al-wakil",
  "name": "Al-Wakīl",
  "name_english": "The Trustee",
  "arabic": "الْوَكِيل",
  "anchor": "Hand it over — He is enough to manage it.",
  "checked_in_today": true,
  "streak": 12,
  "updated_at": "2026-07-14T09:12:00Z"
}
```

- When `checked_in_today` is false, the extension **ignores `name_key`/`anchor`** and
  computes the daily Name itself from the bundled catalog (so the daily card stays
  correct even if the app hasn't run in days). `streak` is still shown from the last
  written value.
- `streak` is read from `getStreak().currentStreak` (SharedPreferences
  `sakina_current_streak`, scoped) — no economy-table write; read-only mirror.

### 4.4 Deep links

| Surface / region | URL | Route |
|---|---|---|
| Small (whole widget), Lock Screen | `sakina://widget/muhasabah` | `/muhasabah` |
| Medium — main content region | `sakina://widget/muhasabah` | `/muhasabah` |
| Medium — "🤲 Make a dua with this Name" | `sakina://widget/build-dua?name_key=<key>` | `/duas` (seed builder with the Name) |

`/muhasabah` and `/duas` already exist in `lib/core/router.dart`. Seeding the dua
builder with a Name is a small addition to the duas route/provider (query param →
prefill). App registers a custom URL scheme + `.onOpenURL` handler mapping these to
GoRouter.

### 4.5 Refresh triggers (app → widget)

`WidgetDataService.syncWidget()` is called on:
- successful muḥāsabah check-in (sets `checked_in_today`, updates Name + streak),
- streak change / daily rollover handling,
- app foreground (`AppLifecycleState.resumed`),
- sign-in / sign-out (sign-out clears personalized fields → widget reverts to daily).

The widget's own timeline also self-advances at two local boundaries, independent of
the app running: **~8pm** (if `checked_in_today` is false, switch the streak chip to
the amber "Don't lose your N" loss-aversion state — §5.5) and **midnight** (roll the
daily Name, reset "checked in today", clear the amber state). Two scheduled entries/day
— cheap, well within the refresh budget.

## 5. Layouts (native SwiftUI)

Design-system aligned. **Arabic and Latin are always separate Text views with explicit
direction** (never mixed in one view) — mirrors the app's cardinal RTL rule.

### 5.1 Tokens

| Token | Value | Use |
|---|---|---|
| `cream` | `#FBF7F2` | light background |
| `charcoal-card` | warm charcoal (NOT pure black), e.g. `#2A2723` | dark background |
| `emerald` | `#1B6B4A` | Arabic hero, primary text (light) |
| `emerald-dark-mode` | lightened emerald, e.g. `#8FD3B0` | Arabic hero on dark |
| `gold` (fill) | `#C8985E` | dua pill fill, decorative accent |
| **`gold-ink` (text)** | **`#9A6F37`** | **kicker + labels — passes WCAG 4.5:1 on cream** (bright gold fails at ~2.2:1, review 2026-07-14) |
| `ink` / `ink-soft` | `#2C2A26` / `#6B6459` | body / secondary |

Fonts: Aref Ruqaa (Arabic Name hero, via `AdjustedArabicDisplay` grammar), Amiri
(any verse text), DM Serif Display (transliteration), DM Sans (kicker, anchor line,
UI). Decorative Islamic geometric accent at 6% opacity, one corner only. Streak/dua
glyphs use **SF Symbols** (`flame.fill`, `hands.sparkles.fill`) not emoji.

### 5.2 Medium (`systemMedium`, 4×2) — Direction B (approved)

- **Left ~40%:** Arabic Name hero (Aref Ruqaa, emerald). Transliteration beneath it
  (DM Serif). Separated from the right column by generous whitespace + an optional
  hairline that **fades top/bottom** (no hard dashboard rule — review Pass 4).
- **Right ~60%, top→bottom:** gold-ink kicker (the emotional hook, weighted, the first
  thing the eye lands on after the Name) → anchor line (DM Sans, ink) → English meaning
  (ink-soft) → footer row: streak chip (left) + "Make a dua" gold pill (right, second
  `Link`). Two tap regions.

### 5.3 Small (`systemSmall`, 2×2)

Direction B's two columns do not fit 158pt, so Small is a **centered single column**:
gold-ink kicker (≤2 lines) · Arabic Name hero · transliteration · streak chip. No
anchor sentence, no dua pill (glanceable core only). One tap target → muḥāsabah.

### 5.4 Lock Screen (`accessoryRectangular`)

One line: kicker + Name + streak, system-tinted/desaturated — legibility rides on
**weight/shape, not color**. Whole-widget deep link → muḥāsabah. (`accessoryCircular`
with the Name + streak is an optional later add.)

### 5.5 Interaction states

| State | Small | Medium | Lock |
|---|---|---|---|
| **Loading / first paint** | last cached entry renders instantly (no spinner); bundled catalog guarantees content | same | same |
| **Logged out / fresh install** | daily Name from bundled catalog; **streak hidden** (no login wall) | same, dua pill still deep-links (app handles auth) | Name only |
| **Checked in today** | streak = solid emerald `🔥 12` | same | `🔥 12` |
| **Not checked in yet** | daily Name + kicker; streak chip → gold-ink `✦ Tap to begin today` | same + dua pill | Name + `Tap to begin` |
| **Streak = 0 (new user)** | gold-ink `✦ Start your streak` in the chip slot | same | `Start your streak` |
| **Not done, after ~8pm local** | amber loss-aversion chip `Don't lose your 12` | same | `Keep your 12` |
| **Long Name / long anchor** | Arabic auto-scales one step, then anchor clamps to 2 lines + tail ellipsis; English clamps to 1 | same | single line, truncates with ellipsis |
| **Stale (app not opened days)** | daily Name still rotates via widget's own midnight timeline; streak shows last-known value | same | same |

### 5.6 Accessibility

- **VoiceOver:** each widget exposes one coherent phrase via `accessibilityLabel`,
  e.g. *"Al-Wakīl, The Trustee. When the weight won't lift. 12 day streak."* The dua
  pill is a separate element with its own label ("Make a dua with this Name") +
  `accessibilityHint` ("Opens Sakina to build a dua").
- **Dynamic Type:** text scales; the §5.5 auto-scale/clamp rules keep it legible at
  large sizes. Test across sizes.
- **Contrast:** all text ≥ 4.5:1 (gold-ink token exists for this reason); Lock Screen
  relies on weight/shape under system tint.
- **Tap targets:** whole widget is the primary target; the Medium dua-pill region is
  ≥ 44pt.
- **Dark mode:** warm charcoal card, lightened emerald for the Arabic; never pure black.

## 6. Error handling & edge cases

- **No payload / logged out / fresh install:** render deterministic daily Name from
  bundled catalog; hide streak (or show nothing) rather than a login wall.
- **Stale payload (app not opened in days):** daily Name still rotates via the
  extension's own midnight timeline; streak shows last-known value (acceptable — it's a
  mirror, corrected on next app open).
- **Catalog/DB drift:** bundled anchor JSON is regenerated at build time; a CI check can
  assert row count parity with `name_anchors`.
- **Timezone:** daily index uses device-local midnight (consistent with in-app
  `getTodaysName()`); documented as intentional.
- **Refresh budget:** never assume real-time; one entry/day + app-triggered reloads.

## 7. Testing

- **Dart unit:** `WidgetDataService` payload composition (personalized vs daily,
  logged-out clears personalized fields, streak mirrored correctly).
- **Dart unit:** deep-link URL → GoRouter route mapping, including `name_key` seed into
  the dua builder.
- **Native:** snapshot/preview tests for small/medium/accessory in light + dark +
  Lock Screen tint; daily-index selection is deterministic for a given date.
- **Manual QA:** add-widget flow, check-in updates the face, midnight rollover,
  logged-out fallback, StandBy appearance. Physical device for Lock Screen/StandBy.

## 8. Out of scope (v1)

- Android Glance implementation (fast-follow; shares the payload contract).
- Interactive check-in *from* the widget (iOS 17 App Intents) — deep-link only in v1.
- User-configurable widget (intent configuration), verse/dua-of-the-day variants,
  large widget.
- Widget-install onboarding prompt (worth a v2 — adoption is the gating factor for
  widget retention; note it, don't build it yet).
- Analytics: build-a-dua/reflect are still uninstrumented in Mixpanel; adding those
  events is a separate, related task (do not block the widget on it, but flag it).

## What already exists (reuse, don't reinvent)

- **Content:** `name_anchors` (98 rows: `anchor` + `detail`) and `collectible_names`
  (99 rows: meaning/lesson/hadith/dua) — the widget's daily content, already public.
- **Daily selection grammar:** `getTodaysName()` in `lib/core/constants/allah_names.dart`
  (deterministic day-of-year index) — mirror it for the widget's daily fallback.
- **Streak read:** `getStreak()` → `StreakState.currentStreak` (SharedPreferences
  `sakina_current_streak`, scoped) — read-only mirror, no economy write.
- **Arabic rendering grammar:** `AdjustedArabicDisplay` (Aref Ruqaa bleed handling).
- **Color tokens:** `lib/core/constants/app_colors.dart` (`backgroundLight`, `primary`,
  `secondary`). Add the new `gold-ink` text token here.
- **Routes:** `/muhasabah`, `/duas` already in `lib/core/router.dart`.
- **No DESIGN.md exists** — the design system lives in `CLAUDE.md` + `app_colors.dart`.
  Consider `/design-consultation` later to formalize it, but not a blocker here.

## Approved Mockups

| Screen/Section | Mockup Path | Direction | Notes |
|---|---|---|---|
| Widget surfaces (Medium hero, Small, Lock Screen, dark, rotation) | `~/.gstack/projects/SamieBelal-Sakina/designs/widget-name-20260714/board.html` | **B — Arabic hero left / meta right** | Hand-built HTML at true iOS aspect ratios with real tokens + fonts (AI image gen was blocked on OpenAI org verification). Apply review fixes: `gold-ink #9A6F37` kicker, faded (not hard) divider, full streak states, SF Symbols. |

## 9. Key file touch-points (for the plan)

- `pubspec.yaml` — add `home_widget`.
- `lib/services/widget_data_service.dart` — new writer service.
- Hook `syncWidget()` into: muḥāsabah completion (`daily_loop_provider.dart` /
  check-in path), streak update (`streak_service.dart` consumers), app lifecycle,
  auth sign-in/out.
- `lib/core/router.dart` + app entry — custom URL scheme + `.onOpenURL` → routes;
  `name_key` seed param on `/duas`.
- `ios/` — new WidgetKit extension target, App Group entitlement, bundled anchor JSON,
  SwiftUI layouts.
- `scripts/` — small generator that exports `name_anchors` → bundled JSON.
- Tests per §7.

## 10. Engineering review decisions (2026-07-14)

Amends §3–§9 with the eng-review outcomes. Where these conflict with earlier text, these win.

### 10.1 Canonical daily-Name source (supersedes §4.3 fallback) — IMPLEMENTED
**Correction (build):** `allahNames` has **98** entries (the earlier "99" counted the
`AllahName` constructor), and `name_anchors` has **98** — a clean **98:98 bijection**, no
missing anchor. `getTodaysName()` is `% 98`.
The widget's daily fallback indexes **`dayOfYear % 98`** into `ios/SakinaWidget/catalog.json`,
whose order is identical to `allahNames`. `scripts/gen_widget_catalog.dart` joins `allahNames`
(order authority) to the committed snapshot `assets/widget/name_anchors_snapshot.json` via an
explicit 11-entry romanization override table, and **fails the build if the mapping is not a
bijection** (any unresolved Name or unused anchor). `test/services/widget_catalog_parity_test.dart`
asserts `catalog[i].transliteration == allahNames[i].transliteration` for all 98 and that the
`day % n` math agrees across a full year. Catalog is a **committed artifact**; CI needs no DB.

### 10.2 Catalog generation & CI (supersedes §6 "regenerated at build time")
The generated catalog JSON is a **committed artifact** with a `version` field (no DB
creds in CI). The parity check reads the **public catalog via the anon key** (already
public, no service role). `check_no_fake_strings.sh` is extended to scan
`ios/SakinaWidget/` (JSON + Swift) so widget content can't bypass the fake-string tripwire.

### 10.3 Deep-link wiring (supersedes §4.4 mechanism)
Route taps via the **`home_widget` click API**: SwiftUI `.widgetURL` with the plugin's
`homeWidget` query param → Dart `HomeWidget.widgetClicked` stream +
`HomeWidget.initiallyLaunchedFromHomeWidget()` for cold start → dispatch into GoRouter.
No bespoke URL scheme. **Cold-launch race:** queue the initial widget URL and replay it
after first frame + auth-resolved; the widget link takes precedence over
`DailyLaunchOverlay` for that launch (define explicitly in the router redirect).

### 10.4 syncWidget trigger (supersedes §4.5 four-site list)
`WidgetDataService.syncWidget()` is called **once from the data-sync completion**
(after `sync_all_user_data` / `supabaseSyncService` writes) + app-resume + auth change.
Any future check-in/streak/token path that already syncs updates the widget for free.
**Perf guard:** compare the newly-serialized payload to the last written blob and only
call `HomeWidget.updateWidget` when it changed (avoid thrashing the reload budget).

### 10.5 Privacy & sign-out (new — P1)
The App Group container is a **separate store** from scoped SharedPreferences, so the
existing `clearScopedPreferencesForUser` does NOT touch it. Add
`WidgetDataService.clearWidget()` (deletes App Group keys + forces the daily-fallback
render) and call it from **both** `signOut()` and `deleteAccount()` (which currently
does only the RPC, no local wipe). Write the payload with **`NSFileProtectionComplete`**.
Logged-out/cleared state shows the daily Name with **no streak** (never another user's).

### 10.6 Fonts in the extension (new — P1)
Aref Ruqaa / Amiri / DM Serif / DM Sans must be added to the **widget extension target**
(Copy Bundle Resources + `UIAppFonts` in the extension `Info.plist`). Main-app fonts are
invisible to the widget process; without this the premium-Arabic rationale (§3) silently
degrades to system font.

### 10.7 Timeline reliability (supersedes §4.5 "self-advances")
WidgetKit does not guarantee a wake at an exact wall-clock instant (budget-throttled,
suspended in Low Power Mode). Each timeline load **pre-bakes both future entries** in the
array — an entry dated 8pm (amber loss-aversion if not checked in) and one dated next
midnight (roll Name, reset state) — so the render flips even with no fresh provider call.
Timing is **approximate**; document it. Use the payload `updated_at`: if it's from a
prior local day, the widget ignores `checked_in_today` and treats the streak as at-risk
rather than asserting a stale count as authoritative.

### 10.8 App Group + provisioning (new — P1 setup)
Adds an **App Group capability** on both Runner and the widget extension, a **second
bundle ID** for the extension, and **two provisioning profiles**. This will break
`flutter build ios --release` until profiles regenerate — add to `TODO.md` release
checklist alongside the existing signing/OpenAI-proxy debt.

### 10.9 i18n / RTL (v1 stance)
**v1 widget copy is English-only** (from `name_anchors`) and the layout is **LTR-locked**
(Arabic hero left, meta right). RTL mirroring (`.environment(\.layoutDirection)`) +
localized anchor copy are a **v2 decision**, filed in §8, not a silent omission.

### 10.10 Test coverage (Dart unit + native snapshot)

```
CODE PATHS                                              USER FLOWS / STATES
[+] lib/services/widget_data_service.dart               [+] Widget lifecycle
  ├── syncWidget()                                        ├── [GAP] checked-in-today → streak solid
  │   ├── [GAP] personalized (checked in today)           ├── [GAP] not-checked-in → daily + "tap to begin"
  │   ├── [GAP] daily fallback (not checked in)            ├── [GAP] streak=0 → "start your streak"
  │   ├── [GAP] logged-out → personalized fields cleared   ├── [GAP] 8pm not-done → amber loss-aversion
  │   └── [GAP] payload-unchanged → no updateWidget call   └── [GAP] midnight rollover → new Name + reset
  ├── clearWidget()  [GAP] signout + deleteAccount clear App Group   [+] Deep links
  └── daily-index parity  [GAP] widgetCatalog[i]==allahNames[i] ×99   ├── [GAP][→E2E] tap → /muhasabah (cold+warm)
[+] router deep-link dispatch                                        └── [GAP][→E2E] dua pill → /duas seeded w/ name_key
  └── [GAP] initial URL queued + replayed after auth; precedence vs DailyLaunchOverlay

NATIVE (SwiftUI): [GAP] snapshot small/medium/accessory × light/dark/tinted; deterministic daily index for a fixed date; long-name clamp.
COVERAGE: 0/14 (new feature). Target 100% of Dart paths + native snapshots.
```

All GAPs above become test requirements written **alongside** the feature code. The
parity check (10.1) and the clear-on-signout test (10.5) are **CRITICAL** (privacy /
correctness). Deep-link cold+warm are `[→E2E]`.

### 10.11 Failure modes (each new codepath)
| Codepath | Realistic failure | Test? | Error handling? | User sees |
|---|---|---|---|---|
| App Group write | container unavailable / protection class blocks read while locked | add | needed | last cached entry (fine) |
| clearWidget on signout | not called → prior user's streak persists | **CRITICAL test** | needed | **another user's data (privacy)** — must not happen |
| daily index | widget `%98` vs app `%99` | **CRITICAL parity test** | n/a | wrong Name vs app |
| font bundling | TTF missing from extension | manual/snapshot | fallback | system font (degraded) |
| timeline wake | device asleep at midnight | n/a (pre-baked) | pre-bake entries | slightly late flip (acceptable) |
| cold-launch link | fires before auth | add | queue+replay | dropped link / wrong screen |

Any failure that is silent + untested + unhandled is a critical gap — the clear-on-signout
and daily-index parity are exactly those, hence CRITICAL tests.

### 10.12 Parallelization
- **Lane A (Dart):** `widget_data_service.dart` + sync-layer hook + router dispatch + catalog generator script + Dart tests. (shared `lib/`, sequential within lane)
- **Lane B (iOS native):** WidgetKit extension target, App Group entitlement, font bundling, SwiftUI layouts, snapshot tests. (shared `ios/`, sequential within lane)
- Lane A and Lane B are **largely independent** once the payload contract (§4.3) + `iOSName`/App Group ID are fixed first. Fix the contract, then run A + B in parallel worktrees, merge, then wire the E2E deep-link tests (needs both).

## Implementation Tasks
Synthesized from this review's findings. Each derives from a specific finding above.

- [ ] **T1 (P1, human: ~20min / CC: ~5min)** — tokens — Add `gold-ink #9A6F37` text token; use for kicker/labels, keep `#C8985E` for fills.
  - Surfaced by: Pass 5 — gold on cream ~2.2:1 fails WCAG 4.5:1.
  - Files: `lib/core/constants/app_colors.dart`
- [ ] **T2 (P1, human: ~1d / CC: ~30min)** — widget-ui — Build Direction B Medium + Small single-column + Lock `accessoryRectangular` in SwiftUI.
  - Surfaced by: Pass 1/3 — approved hero Direction B.
  - Files: `ios/SakinaWidget/`
- [ ] **T3 (P1, human: ~4h / CC: ~20min)** — widget-states — Implement full streak states incl. 8pm loss-aversion + midnight timeline entries.
  - Surfaced by: Pass 2/3 + streak-state decision.
  - Files: `ios/SakinaWidget/`, `lib/services/widget_data_service.dart`
- [ ] **T4 (P1, human: ~2h / CC: ~15min)** — a11y — VoiceOver labels/hints, Dynamic Type scale+clamp, 44pt targets, overflow rules.
  - Surfaced by: Pass 6 — 3/10 baseline.
  - Files: `ios/SakinaWidget/`
- [ ] **T5 (P2, human: ~30min / CC: ~5min)** — widget-ui — Replace hard column divider with faded hairline; SF Symbols not emoji.
  - Surfaced by: Pass 4 — divider reads dashboard-y.
  - Files: `ios/SakinaWidget/`
- [ ] **T6 (P1, human: ~3h / CC: ~20min)** — data/privacy — `clearWidget()` clears App Group keys; call from `signOut()` + `deleteAccount()`; write payload with `NSFileProtectionComplete`.
  - Surfaced by: §10.5 — sign-out leaks prior user's streak/Name.
  - Files: `lib/services/widget_data_service.dart`, `lib/services/auth_service.dart`
  - Verify: unit test — after signOut, App Group payload is empty + widget renders daily fallback.
- [ ] **T7 (P1, human: ~2h / CC: ~15min)** — content — Build-time catalog generator from `allahNames` (99), join `name_anchors` by key, backfill missing anchor; commit JSON + `version`; CI index-alignment parity check via anon key.
  - Surfaced by: §10.1/§10.2 — 99 vs 98 Name divergence.
  - Files: `scripts/gen_widget_catalog.dart`, `ios/SakinaWidget/catalog.json`, CI
  - Verify: parity test widgetCatalog[i] == allahNames[i] for all 99.
- [ ] **T8 (P1, human: ~4h / CC: ~25min)** — ios-setup — App Group capability on both targets, extension bundle ID, two provisioning profiles, add fonts (Aref Ruqaa/Amiri/DM) to extension `UIAppFonts`.
  - Surfaced by: §10.6/§10.8 — fonts invisible to extension; provisioning breaks release build.
  - Files: `ios/`, `TODO.md` release checklist
  - Verify: `flutter build ios --release` succeeds; snapshot shows Aref Ruqaa, not system font.
- [ ] **T9 (P1, human: ~2h / CC: ~15min)** — deep-link — `home_widget` `widgetClicked` stream + `initiallyLaunchedFromHomeWidget()`; queue initial URL, replay after first-frame+auth; precedence over `DailyLaunchOverlay`.
  - Surfaced by: §10.3 — cold-launch race, wrong-screen/dropped link.
  - Files: `lib/core/router.dart`, `lib/main.dart`
  - Verify: E2E — cold + warm tap → `/muhasabah`; dua pill → `/duas` seeded.
- [ ] **T10 (P1, human: ~2h / CC: ~15min)** — timeline — pre-bake 8pm + midnight entries in one `Timeline`; use `updated_at` staleness to gate `checked_in_today`.
  - Surfaced by: §10.7 — WidgetKit won't wake at exact instant; stale streak.
  - Files: `ios/SakinaWidget/`
- [ ] **T11 (P2, human: ~1h / CC: ~10min)** — safety — extend `check_no_fake_strings.sh` to scan `ios/SakinaWidget/`; centralize `syncWidget()` at sync layer + payload-changed guard.
  - Surfaced by: §10.2/§10.4.
  - Files: `scripts/check_no_fake_strings.sh`, sync layer
- [ ] **T12 (P3, human: ~30min / CC: ~5min)** — docs — correct StandBy "auto-appears" wording; document approximate timeline timing + local-time invariant.
  - Surfaced by: §10.7/§10.9 outside-voice P3.
  - Files: this spec, code comments

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | n/a | codex CLI broken (ENOENT) → Claude subagent used |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | clean | 3 arch + 1 CQ resolved; 11 outside-voice findings folded; scope accepted full-v1 |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | resolved | score 6/10 → 9/10, 4 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **CROSS-MODEL:** No tension — the outside voice (Claude subagent; Codex CLI was broken) extended the review with iOS platform/data-lifecycle findings rather than contradicting it. All P1/P2/P3 folded per user approval.
- **VERDICT:** DESIGN + ENG CLEARED — ready to implement. Full v1 in one PR.

NO UNRESOLVED DECISIONS
