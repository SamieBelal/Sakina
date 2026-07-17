# Duʿā Live Activities — Implementation Plan (Phase 2)

**Date:** 2026-07-16
**Status:** Plan — pending review
**Author:** Ibrahim + Claude
**Feature:** Live Activity for the duʿā-acceptance-times window (v1 local, foreground-started)
**Builds on:** `docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md` (the shipped Duʿā Times home-widget feature). Read that first — this plan reuses its App Group, its precomputed `DuaWindowSchedule`, and its urgency ladder verbatim.

---

## 1. Overview

The shipped Duʿā Times feature (spec 2026-07-15) already answers *"are you inside a window when duʿā is more likely accepted, and if not, when is the next one?"* on two surfaces: an in-app card and a native **home-screen** widget with a live `Text(timerInterval:)` countdown. A home-screen widget is passive — the user has to *go looking* at their home screen. This Phase 2 adds a **Live Activity**: the same countdown promoted to the **Lock Screen** and **Dynamic Island**, glanceable without unlocking, ticking down to *"Ask before it closes."*

The Live Activity is the highest-intent surface we can own: a user who sees "Make your duʿā — 11:40 left · until Fajr" on their lock screen at 4 AM is one tap from Build-a-Duʿā during the exact moment the whole feature is designed for. Its north star is identical to the home widget's (spec §9): **every glance and every tap drives into Build-a-Duʿā**, the #2 feature and the retention engine (per project memory `home-screen-widget-project.md`).

### How it drives retention into Build-a-Duʿā

- The Live Activity only exists *while a window is active* — so its mere presence on the lock screen is a time-boxed, urgency-carrying nudge that Build-a-Duʿā "now is the moment."
- The whole surface + every tap deep-links to `sakina://widget/build-dua?homeWidget` (reusing the existing routing in `widget_deep_link.dart` and the home widget's `duaDeepLinkURL()`), so the tap target is unambiguous.
- The countdown is emotionally load-bearing: a ticking `HH:MM:SS` to "until Fajr" converts far better than a static "it's a good time" card, because loss-aversion ("the window is closing") is doing the work.
- Unlike the home widget (which the user must add manually), a Live Activity **appears on its own** when a window opens and the app is foregrounded — zero setup, so reach is much higher for users who never add widgets.

---

## 2. What already exists to reuse vs. what is net-new

### Reuse (already shipped, do not rebuild)

| Asset | Where | How the Live Activity uses it |
|---|---|---|
| **WidgetKit extension `SakinaWidgetExtension`** | `ios/SakinaWidget/` (file-system-synchronized group, auto target membership) | The `ActivityConfiguration` is *added to this same extension* — an `ActivityConfiguration` is just another `Widget` in the bundle. No new target. |
| **`@main SakinaWidgetBundle`** | `ios/SakinaWidget/SakinaWidgetBundle.swift` (currently renders `SakinaWidget()` + `SakinaDuaTimesWidget()`) | Add a third member: `SakinaDuaTimesLiveActivity()`. Still one `@main`. |
| **App Group `group.com.sakina.app.widget`** | On both Runner + extension (SETUP.md §3) | ActivityKit needs no App Group to *tick* a local timer, but we reuse it so the extension can read the same `DuaWindowSchedule` payload if we ever hydrate the activity from it. |
| **`Text(timerInterval:countsDown:)`** | Already used in `SakinaDuaTimesWidget.swift` (`DuaSmallView.cue`, `DuaMediumView.countdown`, lock-screen views) | Copy the exact same on-device ticking-clock pattern into the Live Activity views — **no push needed to tick** (see §4). |
| **Domain types `Window`, `Schedule`, `Urgency`, `resolve(at:)`, `urgencyFor(active:at:)`, `travelGuardTripped`** | `ios/SakinaWidget/SakinaDuaTimesWidget.swift` (all `private` in that file today) | These already encode the escalation ladder + travel guard. We reuse the *logic*; see the "shared file" decision in §7. |
| **Copy tables `verb()`, `closeLabel()`, `windowLabel()`, `whyLine()`, `glyphName()`** | same file | The Live Activity's Lock-Screen + Dynamic Island views render from these — identical copy/voice as the widget. |
| **`WidgetDataService` (Dart→App Group writer)** | `lib/services/widget_data_service.dart` (`saveDuaTimesSchedule`, `kDuaTimesPayloadKey`, byte-identical perf guard, `clearWidget()` wipe) | Template for the new Dart↔ActivityKit bridge. The Live-Activity bridge mirrors its shape (thin seam over a platform channel, perf-guarded, wiped on sign-out). |
| **`DuaWindowNotifier`** | `lib/features/dua_times/providers/dua_window_provider.dart` (`rebuild()`, foreground-resume via `didChangeAppLifecycleState`, `_pushToWidget()`, ticker, `_hasLiveCountdown`) | The single place that already knows the active window + urgency + foreground moment. The Live-Activity start/update/end lifecycle hangs off `rebuild()` right next to `_pushToWidget()`. |
| **`DuaWindowSchedule` / `DuaWindow` / `UrgencyState` Dart models** | `lib/features/dua_times/models/` | The activity's initial + updated content state is derived from `schedule.active` — the models already carry `endUtc`, `isAllDay`, `urgency`. |

### Net-new (this plan)

1. **`DuaLiveActivityAttributes`** — `ActivityAttributes` + nested `ContentState` (Swift, in the extension).
2. **`SakinaDuaTimesLiveActivity`** — an `ActivityConfiguration` widget: Lock-Screen/banner view + Dynamic Island (compact leading/trailing, minimal, expanded).
3. **A thin native `MethodChannel`** (`sakina/dua_live_activity`) in the **Runner** target (a small `LiveActivityBridge.swift` + registration in `AppDelegate`) that calls `Activity.request` / `.update` / `.end`. ActivityKit APIs live in the app process, not the extension.
4. **A Dart seam `DuaLiveActivityService`** mirroring `WidgetDataService`: `start(schedule)`, `update(schedule)`, `end()`, perf-guarded, no-ops on non-iOS / unsupported OS.
5. **Lifecycle wiring** in `DuaWindowNotifier`: start on foreground-with-active-window, update on urgency/window change, end at `window.endUtc` via `dismissalPolicy`.
6. **Info.plist flag** `NSSupportsLiveActivities = YES` on the Runner Info.plist (and the extension's).
7. **Deployment-target bump** for the extension floor + runtime gating (§5).
8. **Tests** — Dart-side unit tests for the bridge decision logic; device-only manual QA for the Dynamic Island.

---

## 3. Architecture — local, no server

```
DuaWindowNotifier.rebuild()  (Dart, already runs on foreground / date-rollover / location change)
    │  builds DuaWindowSchedule (active window + urgency)  [EXISTING]
    ├── _pushToWidget(schedule)              → WidgetDataService.saveDuaTimesSchedule(json)   [EXISTING]
    └── _syncLiveActivity(schedule)          → DuaLiveActivityService.start/update/end(...)   [NEW]
                                                    │  MethodChannel 'sakina/dua_live_activity'
                                                    ▼
                                          LiveActivityBridge.swift  (Runner target, NEW)
                                                    │  Activity.request / .update / .end
                                                    ▼
                                          iOS ActivityKit
                                                    │  renders + LOCALLY ticks Text(timerInterval:)
                                                    ▼
                                   SakinaDuaTimesLiveActivity  (ActivityConfiguration in the
                                   existing SakinaWidgetExtension, NEW)
```

**Key architectural facts (from research, not re-derived):**

- **No push, no server.** The countdown is a *purely local* Live Activity: `Text(timerInterval: now...window.endUtc, countsDown: true)` ticks on-device once started, exactly like the home widget already does. We call `Activity.request(...)` with `pushType: nil`. (ActivityKit docs: `request(attributes:content:pushType:)` — `pushType` is optional; omit it for a local activity. The `Text(timerInterval:)` pattern is the same one shipped in `SakinaDuaTimesWidget.swift`.)
- **Start on foreground when a window is active.** Per Apple, `Activity.request` **must be called while the app is in the foreground** on iOS < 17.2; a background attempt throws `ActivityAuthorizationError.visibility` ("The app attempts to start a Live Activity while it is in the background") (ActivityKit docs). `DuaWindowNotifier` already recomputes on `AppLifecycleState.resumed`, so the foreground moment is exactly where we start.
- **End at `window.endUtc` via `dismissalPolicy`.** We don't need to keep the app alive to end it. When we `end(...)`, pass `dismissalPolicy: .after(window.endUtc)` (or `.after(.now + grace)` for a short "the window closed" tail), so the system removes it at the boundary even if the app is backgrounded. `ActivityUIDismissalPolicy` supports `.immediate`, `.after(_:)`, `.default` (ActivityKit docs, `activity.end(_:dismissalPolicy:)`).
- **`staleDate` guards the ticker.** Set `ActivityContent(state:staleDate: window.endUtc)` so if anything drifts, the activity flips to `ActivityState.stale` at the window boundary rather than showing a duʿā window that has already closed (ActivityKit `staleDate` / `ActivityState.stale`, iOS 16.2+).
- **Gate on `ActivityAuthorizationInfo().areActivitiesEnabled`** before every `request` (iOS 16.1+). If the user disabled Live Activities in Settings, we silently skip — the home widget + in-app card still cover them.

### The Dart↔ActivityKit bridge (mirroring `WidgetDataService`)

`DuaLiveActivityService` is a thin, testable seam — same shape as `WidgetDataService`:

- A `LiveActivityChannel` abstraction (default = the real `MethodChannel('sakina/dua_live_activity')`) so the service is unit-testable without the platform channel, exactly like `HomeWidgetClient` wraps `home_widget`.
- **Perf guard:** track the last-sent content signature (`type|endUtcMillis|urgency|isAllDay`) and skip `update` when identical — mirrors `WidgetDataService._lastDuaTimesWritten` byte-identical guard. `DuaWindowNotifier.rebuild()` fires on every foreground; we must not spam ActivityKit.
- **Sign-out / delete wipe:** `end()` is called from the same place `clearWidget()` is (sign-out, account delete) so a second user on the device never inherits a live activity carrying the first user's window (parallels the `clearWidget()` privacy fix in the spec).
- Methods: `Future<void> start({required DuaLiveActivityContent content})`, `update(...)`, `end()`, `isSupported()` (returns false off-iOS or below the OS floor so callers no-op cleanly).

Content passed over the channel is a flat map: `{ type, verb, closeLabel, whyLine, glyphName, end_utc_millis, is_all_day, urgency, deep_link }`. We send *pre-resolved copy* rather than re-deriving it in Swift, but the Swift side ALSO has the copy tables (reused from the widget) as a fallback — see the shared-file decision (§7).

---

## 4. The foreground-start limitation and how it constrains v1

This is the single most important product constraint, so it's called out explicitly.

**The limitation (iOS < 17.2):** a Live Activity can only be *started* (`Activity.request`) while the app is in the **foreground**. There is no way, on 16.1–17.1, to start one from the background or on a schedule. (Confirmed: `ActivityAuthorizationError.visibility` is thrown on a background start attempt — ActivityKit docs.)

**What this means for v1 UX:** the Live Activity **"starts when the user opens the app during (or near) an active window."** Concretely:

- User opens Sakina at 4:10 AM. `DuaWindowNotifier.rebuild()` runs on `resumed`, sees the last-third-of-night window is active, and starts the Live Activity. It then persists on the lock screen and ticks down even after the app is backgrounded/closed — because a *local* activity keeps ticking without the app. ✅
- User never opens Sakina during the window → no Live Activity that day. ❌ (This is the inherent v1 gap.)

**Why this is acceptable for v1 and how we mitigate it:** this Live Activity is designed to **pair with the Phase-2 scheduled-notifications feature** (spec §2 "Out of scope (deferred) → Phase 2": `flutter_local_notifications` local, per-device/location scheduling). The notification *"The last third of the night has begun — raise your hands"* is precisely the thing that brings the user to the foreground during the window, at which point the Live Activity starts. So the two Phase-2 pieces are complementary: **the notification gets them to foreground; the Live Activity rewards the glance with a live countdown.** We should sequence the scheduled-notification work either before or alongside this, and note the dependency in `TODO.md`.

Additional v1 mitigation (cheap, no push): whenever the app foregrounds with an active window and no live activity yet, start one. Over a typical day a user opens the app at least once; if that open lands inside a window, they get the activity. We do **not** promise it appears without an app open in v1.

### The iOS 17.2+ push-to-start upgrade (clearly-separated later phase — NOT v1)

iOS 17.2 added **push-to-start**: `Activity.pushToStartToken` / `pushToStartTokenUpdates` (a `Data?` obtained *without* first starting an activity), which the app registers with a server; an APNs push then starts the Live Activity **while the app is backgrounded or killed** (ActivityKit docs, iOS 17.2+). This would close the v1 gap — the activity would appear at the window boundary *without* the user opening the app.

**Why it's a separate phase (and expensive):**

- It needs an **APNs proxy** (a Supabase Edge Function + APNs auth key/`.p8`, per-device push-to-start token storage, and a scheduler that fires at each device's *local* window boundary). This is a whole server subsystem — the same class of work the spec already flagged for OneSignal ("server-push cannot do location-local timing cleanly", spec §2/§13).
- Per-device local timing means the proxy must know each device's timezone/location-derived boundaries — reusing the `computed_at.tz` stamp already in the payload, but now server-side.
- It also wants `NSSupportsLiveActivitiesFrequentUpdates = YES` if we push content updates frequently (ActivityKit docs) — not needed for a purely local ticker, so v1 omits it.

**Decision: v1 is local + foreground-started only. Push-to-start is Phase 2b, explicitly deferred, tracked in `TODO.md` with the APNs-proxy dependency named.** The v1 architecture is forward-compatible: adding push-to-start later is *additive* (register `pushToStartTokenUpdates`, add the proxy) and does not change the `ActivityAttributes`/`ContentState`/views.

---

## 5. iOS version floor & runtime gating

- **Live Activities require iOS 16.1+; Dynamic Island requires 16.2+; `staleDate` requires 16.2+; push-to-start requires 17.2+** (ActivityKit docs).
- **Current repo state:** `Podfile` is `platform :ios, '14.0'`; the Runner app target and the widget extension have mixed `IPHONEOS_DEPLOYMENT_TARGET` (some `14.0`, some `26.5` in `project.pbxproj`). WidgetKit itself already requires iOS 14+, and the shipped `SakinaDuaTimesWidget.swift` gates iOS-17 container APIs with `if #available(iOS 17.0, *)`.
- **Deployment-target handling:**
  - Keep the **app** deployment floor as-is (do not raise the whole app to 16.2 — that would drop iOS 14/15 users of the core app). Instead **gate at runtime**.
  - The **`ActivityConfiguration` code** compiles under any deployment target but must be wrapped so it's only added to the bundle when available: use `if #available(iOS 16.2, *)` in `SakinaWidgetBundle.body` around `SakinaDuaTimesLiveActivity()` (a `WidgetBundleBuilder` supports availability). Below 16.2 the bundle simply doesn't include it.
  - The **Swift bridge** (`LiveActivityBridge.swift`) guards every ActivityKit call with `if #available(iOS 16.2, *)` and returns a benign result otherwise.
  - The **Dart seam** `DuaLiveActivityService.isSupported()` returns false on Android/non-iOS and lets the native side report unsupported OS; all callers no-op.
- **Choose 16.2 (not 16.1) as the effective floor** because we want the Dynamic Island + `staleDate`, and 16.1-only devices are a negligible slice by 2026.

---

## 6. Info.plist requirement

`NSSupportsLiveActivities = YES` is **required** and must be present in the Info.plist of **both** the app (Runner) and, to be safe, the Widget Extension (confirmed by both ActivityKit docs and the `live_activities` package README — "add the key to the Info.plist file for both the main application and the Widget Extension").

- **Runner:** add to `ios/Runner/Info.plist`.
  ```xml
  <key>NSSupportsLiveActivities</key>
  <true/>
  ```
- **Extension:** add to `ios/SakinaWidgetExtension-Info.plist` (the extension's Info.plist was deliberately moved OUT of the synchronized folder — SETUP.md §7 "Info.plist moved OUT of the synced folder"). Add the same key there.
- **Grep confirms neither key exists today** (`grep -rn NSSupportsLiveActivities ios/` → no matches), so this is net-new.
- Do **not** add `NSSupportsLiveActivitiesFrequentUpdates` in v1 (that's a push-update concern, Phase 2b only).

---

## 7. `live_activities` package vs. thin native channel — decision

**Decision: build a THIN native `MethodChannel` into the EXISTING `SakinaWidgetExtension`. Do NOT adopt the `live_activities` pub package.**

### Evaluated: `live_activities` (`/istornz/flutter_live_activities`, v-current)

Its API is genuinely small and pleasant:
```dart
final la = LiveActivities();
await la.init(appGroupId: 'group.com.sakina.app.widget');
final id = await la.createActivity('activity_1', {'title': ..., 'status': ...});
await la.updateActivity('activity_1', {...});
await la.endActivity('activity_1');
```

**Why it fights our working setup:**

1. **It expects you to create *its own* Widget Extension target and its own `ActivityAttributes`,** and it drives the SwiftUI views by reading **UserDefaults keys prefixed with the activity's UUID** (docs: "Keys are constructed by prefixing the attribute name with the activity's UUID"). Our extension is a **file-system-synchronized group** with **empty `exceptions`** (SETUP.md §"Xcode target membership — automatic") — every `.swift`/`.json` in `ios/SakinaWidget/` is auto-compiled. Introducing the package's conventions (its own attributes struct, its UUID-prefixed UserDefaults contract) means either (a) a *second* extension target — which the two shipped widgets and the SETUP.md explicitly warn against ("do NOT hand-edit `project.pbxproj` — that risks breaking the synced group"), or (b) contorting the package to share our extension, which it isn't built for.
2. **Its UserDefaults data model duplicates a shape we already have.** We already ship a clean `DuaWindowSchedule` JSON contract (spec §7 golden test). The package's per-attribute UUID-prefixed keys are a *different*, less-testable serialization we'd have to reconcile against the golden fixture.
3. **We only need three verbs** (`start`/`update`/`end`) and *already own* the Swift views + domain types. The package's value-add (SwiftUI plumbing, UserDefaults bridging) is exactly the part we already built for the home widget and want to reuse. Adding the package would mean *re-authoring* the views under its conventions.
4. **Dependency/versioning risk:** it's a third-party plugin in the iOS build graph alongside `home_widget ^0.9.3`; a plugin-registration or CocoaPods conflict would jeopardize the *shipped* home widgets. The thin channel adds zero new pub/pod dependencies.

### Chosen: thin `MethodChannel`

- **~120 lines of Swift** (`LiveActivityBridge.swift` in Runner) + **~60 lines of Dart** (`DuaLiveActivityService`) + the `ActivityConfiguration` (which reuses the widget's views/domain types).
- **Zero new dependencies**, no new target, no risk to the two shipped widgets.
- **Reuses the golden `DuaWindowSchedule` contract** and the existing copy tables verbatim.
- Mirrors the codebase's existing seam pattern (`WidgetDataService` + `HomeWidgetClient`), so it's idiomatic here.

**Shared-domain-types note:** the domain types (`Window`, `Urgency`, `urgencyFor`, copy tables) are currently `private` inside `SakinaDuaTimesWidget.swift`. To let the `ActivityConfiguration` reuse them, extract the shared pieces (enums, copy functions, `urgencyFor`, glyph/verb helpers) into a new **`DuaWindowShared.swift`** in `ios/SakinaWidget/` (auto-compiled by the synced group) and drop `private`. Both the widget and the Live Activity import nothing (same module) and share one source of truth for copy + ladder. This is a pure refactor of the shipped file — guard it with the existing widget's build + a re-run of `flutter build ios`.

---

## 8. Phased implementation steps

Build order mirrors the spec's philosophy (prove the seam before the pixels). Each step is independently reviewable.

### Phase A — Foundations (no user-visible change yet)

**A1. Info.plist + deployment gating**
- Add `NSSupportsLiveActivities = YES` to `ios/Runner/Info.plist` and `ios/SakinaWidgetExtension-Info.plist` (§6).
- Confirm the extension builds; no target-membership change needed (synced group).

**A2. Extract shared domain/copy into `DuaWindowShared.swift`**
- Move `Urgency`, `WindowType`, `Window` (or a lighter `LiveWindow`), `urgencyFor`, `verb`, `closeLabel`, `windowLabel`, `whyLine`, `glyphName`, `duaDeepLinkURL` out of `SakinaDuaTimesWidget.swift` into `DuaWindowShared.swift`, non-`private`.
- Re-run `flutter build ios --simulator`; the shipped home widget must still render identically (this is the regression gate).

### Phase B — Native ActivityKit surface

**B1. `DuaLiveActivityAttributes` (in the extension)**
```swift
import ActivityKit
struct DuaLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endUtcMillis: Int64      // drives Text(timerInterval:)
        var urgency: String          // "closing" | "last_call" | "all_day" | "comfortable"
        var isAllDay: Bool
    }
    // static: chosen once at start; the copy the views render
    var windowType: String           // maps to windowLabel/whyLine/closeLabel/verb
    var deepLink: String             // sakina://widget/build-dua?homeWidget
}
```
Static data (window kind, deep link) lives in the attributes; the *ticking* bits (end time, urgency) live in `ContentState` so `update()` can escalate comfortable→closing→last-call without recreating the activity.

**B2. `SakinaDuaTimesLiveActivity: Widget` (`ActivityConfiguration`)**
- Lock-Screen/banner view: crescent glyph + `verb()` + a live `Text(timerInterval: .now...endDate, countsDown: true)` when `urgency ∈ {closing,last_call}`, else the static `closeLabel`/"today only". **Monochrome-friendly** (lock screen tints), amber accent only on `last_call` where color is available (banner/home). Reuse the widget's lock-screen view code near-verbatim.
- Dynamic Island:
  - **compact leading:** crescent / ⚠ glyph (`glyphName`).
  - **compact trailing:** the live `Text(timerInterval:)` (closing/last-call) or a short static label ("today only", "until Fajr").
  - **minimal:** the glyph only.
  - **expanded:** leading = glyph + `دُعَاء` (Aref Ruqaa, own RTL widget — never mixed with Latin, per `CLAUDE.md`); trailing/center = `verb()` + `whyLine()`; bottom = countdown + a "Build now →" Link to the deep link.
- Wrap with `if #available(iOS 16.2, *)` in `SakinaWidgetBundle.body`.
- Set `staleDate = endDate` in the content.

### Phase C — Bridge

**C1. `LiveActivityBridge.swift` (Runner target)**
- `MethodChannel('sakina/dua_live_activity')` registered in `AppDelegate.didInitializeImplicitFlutterEngine` (next to `GeneratedPluginRegistrant`).
- Methods: `start`, `update`, `end`, `isSupported`.
- `start`: guard `if #available(iOS 16.2, *)` + `ActivityAuthorizationInfo().areActivitiesEnabled`; build `DuaLiveActivityAttributes` + initial `ContentState`; `Activity.request(attributes:content:pushType:nil)` (no push); store the returned activity by a stable id. Catch + surface `ActivityAuthorizationError.visibility` as a benign "not started (background)" result (never crash).
- `update`: `activity.update(ActivityContent(state:staleDate:endDate))`.
- `end`: `activity.end(ActivityContent(state:finalState, staleDate:nil), dismissalPolicy: .after(endDate))`.

**C2. `DuaLiveActivityService` (Dart seam)**
- Mirror `WidgetDataService`: a `LiveActivityChannel` abstraction (default wraps the real `MethodChannel`) for testability.
- Perf guard on a content signature; `start/update/end/isSupported`; all methods swallow errors (`debugPrint`, never throw) — a Live Activity failure must never break the card, exactly like `_pushToWidget` is best-effort today.

### Phase D — Lifecycle wiring in `DuaWindowNotifier`

**D1.** Add `DuaLiveActivityService? _liveActivity` (injectable, like `_widgetData`).
**D2.** Add `_syncLiveActivity(schedule)` called from `rebuild()` right after `_pushToWidget(schedule)`:
- If `schedule.active != null` AND not all-day-only-with-no-countdown-value AND `isSupported()` AND we're foreground (we are — `rebuild` on `resumed`) → `start` (or `update` if one is already live for this window).
- If the active window changed (different `type`/`endUtc`) → `end` the old + `start` the new.
- If `schedule.active == null` (we're now between windows) → `end()`.
- **All-day windows (ʿArafah etc.):** start a *non-ticking* activity ("today only") OR skip — see Open Decision O1. Default recommendation: skip the Live Activity for all-day windows (a day-long lock-screen activity with no countdown is low-value and burns the slot); the home widget already covers "today only".
**D3.** Call `_liveActivity?.end()` from wherever `clearWidget()` runs (sign-out/account-delete) so no cross-user leak.
**D4.** The existing `_ticker` does NOT drive the activity — ActivityKit ticks `Text(timerInterval:)` itself. The ticker stays purely for the in-app card. We only call `update()` at **urgency-band transitions** (comfortable→closing→last-call), which are already boundary moments the schedule knows.

### Phase E — QA + polish

- Physical-device Dynamic Island QA (§9); copy proof against the spec §9.1 ladder; deep-link proof; sign-out/end proof.

---

## 9. Testing strategy

### Unit-testable on the Dart side (CI, no device)

- **`DuaLiveActivityService` decision logic** via a fake `LiveActivityChannel`:
  - `start` called once with the right content signature when a window is active.
  - Perf guard: identical content → no repeat `update`.
  - Window-change → `end` old + `start` new.
  - Between-windows → `end`.
  - `isSupported()==false` → all calls no-op (Android/unsupported OS path).
  - Errors from the channel are swallowed (never throw).
- **`DuaWindowNotifier` wiring** (extend the existing provider tests): inject a fake `DuaLiveActivityService`, feed synthetic schedules via `debugSetSchedule`, assert start/update/end are invoked at the right transitions (comfortable→closing→last-call→ended). This reuses the exact test harness already used for `_pushToWidget`.
- **Content-map contract test:** the flat map Dart sends matches the Swift `ContentState`/attributes keys (a golden fixture, mirroring the spec's §7 serialization contract test — same failure mode: a silent key drift leaves the activity blank).

### Device-only (manual — cannot be CI'd)

- **Dynamic Island requires a physical iPhone 14 Pro or later** (the Simulator renders the Lock-Screen/banner presentation but **not** the Dynamic Island reliably; compact/expanded/minimal must be checked on hardware).
- Lock-Screen presentation + live `HH:MM:SS` tick to "until Fajr"; amber last-call under 15 min; deep link → Build-a-Duʿā.
- Foreground-start proof: open app inside a synthetic active window (use `debugPreview` on the notifier, mirroring the existing Dev-Tools preview) → activity appears; background the app → it keeps ticking; cross the boundary → it ends via `dismissalPolicy`.
- Live-Activities-disabled-in-Settings → `areActivitiesEnabled==false` → nothing starts, no crash.
- Sign-out → activity ends immediately.
- Note the **pre-existing flaky-test baseline** (project memory `pre-existing-flaky-tests.md`) — the suite exits non-zero on a clean checkout; assert only the new tests, don't gate on a green whole-suite.

---

## 10. Open decisions (with recommendations)

- **O1 — All-day windows (ʿArafah, ʿAshura, White Days):** start a non-ticking "today only" Live Activity, or skip? **Recommend: skip for v1.** A day-long lock-screen activity with no countdown is low-signal, and the home widget + in-app card already handle "today only." Revisit if users want the persistent presence.
- **O2 — Which window kinds get an activity:** time-boxed only (night-third, Friday hour, iftar) vs. all. **Recommend: time-boxed only** — those are where the ticking countdown creates urgency and where the feature's value is highest.
- **O3 — Grace tail after close:** end exactly at `endUtc`, or `.after(endUtc + ~2 min)` with a "window closed — build for next time" final state? **Recommend: `.after(endUtc)` with a short final content state** flipping the copy to "Build your duʿā" so the last glance still routes to Build-a-Duʿā.
- **O4 — Start proactively on any foreground during a window, or only once/day:** **Recommend: idempotent start** — if an activity for the current window already exists, `update` instead of re-`request` (the bridge dedups by window id). No once/day cap needed; the perf guard handles spam.
- **O5 — Analytics:** add `dua_live_activity_started` / `_tapped` / `_ended` event-name constants (`analytics_event_names.dart`), emitted from the provider via the `onAnalyticsEvent` hook (not the service). **Recommend: yes**, so we can measure the surface's tap-through into Build-a-Duʿā (its north star). Deep-link taps already flow through `widget_deep_link.dart` — tag them with a `source: live_activity` param.

---

## 11. Risks / blockers

- **Background-start limitation (v1's inherent gap):** without push-to-start, the activity only appears if the user foregrounds during a window. Mitigation: pair with Phase-2 scheduled notifications; document the gap so it's a known tradeoff, not a bug. (This is *the* reason v1 is honest about "starts when you open the app.")
- **Extension-target / package coexistence:** adding a *second* extension (which `live_activities` wants) risks breaking the file-system-synchronized group that carries the **two already-shipped home widgets**. Chosen thin-channel approach avoids this entirely (no new target, no new pod). The one touch to the shipped extension is the `DuaWindowShared.swift` refactor — gated by re-running `flutter build ios` and eyeballing the home widget.
- **Device-only QA:** the Dynamic Island can't be verified in CI or reliably in the Simulator; requires an iPhone 14 Pro+. Budget real-device time. (Consistent with the home widget's "physical device only" caveat in SETUP.md §"What's left".)
- **Deployment-target drift:** the repo has mixed `IPHONEOS_DEPLOYMENT_TARGET` values (14.0 and 26.5) across targets in `project.pbxproj`. The `if #available(iOS 16.2, *)` gates make this safe, but verify the extension's effective min-OS is ≥ 14 and that the availability wrapping compiles cleanly under whatever the extension target's floor ends up being.
- **App Review scrutiny (inherited):** the underlying feature already carries the location-permission review risk logged in the spec §12 / `TODO.md`. A Live Activity doesn't add data collection (it's local), but a reviewer may probe "why a lock-screen countdown for prayer timing" — the same coarse-only, on-device, purpose-string mitigations apply. No new privacy surface.
- **`Text(timerInterval:)` multi-day caveat:** never route an all-day/multi-day target through the live timer (it renders wrong) — already handled by the `showsLiveTimer` predicate we reuse; keep that invariant in the Live Activity views.

---

## 12. Effort estimate

| Phase | Scope | Estimate |
|---|---|---|
| A | Info.plist flags + deployment gating + `DuaWindowShared.swift` refactor | 0.5 day |
| B | `ActivityAttributes` + `ActivityConfiguration` + Dynamic Island views (reusing widget views) | 1–1.5 days |
| C | `LiveActivityBridge.swift` + `DuaLiveActivityService` Dart seam | 1 day |
| D | Lifecycle wiring in `DuaWindowNotifier` (start/update/end, sign-out end) | 0.5–1 day |
| E | Dart unit tests + physical-device Dynamic Island QA + copy proof | 1 day |
| **v1 total (local, foreground-started)** | | **~4–5 days** |
| **Phase 2b — push-to-start (SEPARATE)** | APNs `.p8` + Supabase Edge Function proxy + per-device `pushToStartToken` storage + local-boundary scheduler + `NSSupportsLiveActivitiesFrequentUpdates` + device QA | **~5–8 days** (server subsystem; treat as its own project) |

v1 is deliberately small because it **reuses** the shipped extension, App Group, `Text(timerInterval:)`, domain types, and copy tables — the net-new surface is one attributes struct, one `ActivityConfiguration`, a ~120-line bridge, and a ~60-line Dart seam. Push-to-start is where the real cost lives, and it is explicitly *not* v1.

---

## Sources

- **ActivityKit** (Apple Developer docs, via context7 `/websites/developer_apple_activitykit`): `ActivityAttributes`/nested `ContentState`; `Activity.request(attributes:content:pushType:style:)` (start *in the foreground*, `pushType` optional → omit for local); `ActivityAuthorizationInfo().areActivitiesEnabled` (iOS 16.1+); `ActivityAuthorizationError.visibility` ("attempts to start … while in the background"); `ActivityConfiguration(for:)` + `DynamicIsland { expanded / compactLeading / compactTrailing / minimal }`; `staleDate` + `ActivityState.stale` (iOS 16.2+); `activity.end(_:dismissalPolicy:)` with `.immediate`/`.after(_:)`/`.default`; `pushToStartToken` / `pushToStartTokenUpdates` (iOS 17.2+); `NSSupportsLiveActivitiesFrequentUpdates` for frequent push updates.
- **`live_activities` Flutter package** (context7 `/istornz/flutter_live_activities`): `init(appGroupId:)` / `createActivity` / `updateActivity` / `endActivity`; requires `NSSupportsLiveActivities = YES` in **both** app and Widget Extension Info.plist; drives SwiftUI via **UUID-prefixed UserDefaults keys** in a **dedicated extension target** — the conventions that would fight our synced-group setup (basis for the "thin channel" decision, §7).
- **`home_widget`** (context7 `/abausg/home_widget`): confirms the App Group + `saveWidgetData`/`updateWidget` model already used by `WidgetDataService`; the Live Activity reuses the same App Group but does not need `home_widget` to tick.
- **Repo:** `docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md`; `ios/SakinaWidget/SakinaDuaTimesWidget.swift` (`Window`/`Urgency`/`urgencyFor`/`resolve(at:)`/`travelGuardTripped`/copy tables/`Text(timerInterval:)`); `ios/SakinaWidget/SakinaWidgetBundle.swift` (single `@main`, two widgets); `ios/SakinaWidget/SETUP.md` (synchronized group, empty `exceptions`, App Group on both targets, Info.plist moved out of synced folder); `lib/services/widget_data_service.dart` (`saveDuaTimesSchedule`, `kDuaTimesPayloadKey`, perf guard, `clearWidget()`); `lib/features/dua_times/providers/dua_window_provider.dart` (`rebuild()`, foreground resume, `_pushToWidget`, ticker); `ios/Runner/AppDelegate.swift`; `ios/Podfile` (`platform :ios, '14.0'`); `ios/Runner.xcodeproj/project.pbxproj` (mixed `IPHONEOS_DEPLOYMENT_TARGET`).
