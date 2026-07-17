# SakinaWidget — status & what's left

As of 2026-07-14 the widget is **code-complete and builds** (`flutter build ios
--simulator` is green: app + `SakinaWidgetExtension.appex`). Most of the original
checklist is done. This file now records what's done and what remains.

## ✅ Done (nothing to do)

1. **Widget Extension target** `SakinaWidgetExtension` created (Xcode 16 made it a
   *file-system-synchronized group*, so every file in `ios/SakinaWidget/` is
   automatically compiled/bundled — no manual "add to target").
2. **Sources reconciled** — the wizard's `SakinaWidgetBundle.swift` is the sole
   `@main`; it renders `SakinaWidget` (our widget). The unwanted Control Center
   widget was removed.
3. **App Group** `group.com.sakina.app.widget` on **both** Runner and
   SakinaWidgetExtension; matches `kWidgetAppGroupId` in
   `lib/services/widget_data_service.dart`. (Xcode's entitlements file is
   `ios/SakinaWidgetExtension.entitlements`.)
4. **`catalog.json`** — committed + auto-bundled (synced group). Regenerate when
   Names/anchors change: `dart run scripts/gen_widget_catalog.dart` (fails the
   build unless the mapping is a bijection; parity guarded by
   `test/services/widget_catalog_parity_test.dart`).
5. **Fonts** — `Fonts/` (Aref Ruqaa, Amiri, DM Serif Display, DM Sans-variable)
   staged + auto-bundled; `UIAppFonts` in the Info.plist matches.
6. **`sakina` URL scheme** — already present in `Runner/Info.plist`.
7. **Build blockers fixed** (do not revert):
   - Info.plist moved OUT of the synced folder to
     `ios/SakinaWidgetExtension-Info.plist` (else "Multiple commands produce
     Info.plist"). `INFOPLIST_FILE` points there.
   - Global helper renamed `widgetURL` → `widgetDeepLinkURL` (clashed with
     SwiftUI's `.widgetURL`).
   - "Embed Foundation Extensions" build phase moved ABOVE "Thin Binary" in the
     Runner target (fixes "Cycle inside Runner" — flutter/flutter#135056).

## Second widget — SakinaDuaTimesWidget (added 2026-07-15)

A **second** WidgetKit widget (`SakinaDuaTimesWidget`, kind
`"SakinaDuaTimesWidget"`) now lives in this folder and is referenced from
`SakinaWidgetBundle.body` alongside `SakinaWidget()`. It renders the duʿā
acceptance-times surface (families: systemSmall, systemMedium,
accessoryRectangular, accessoryInline) from a precomputed schedule the Flutter
app writes to the App Group under key `sakina_dua_times_payload`.

### ✅ Xcode target membership — automatic (no manual step)

Verified 2026-07-15 against `project.pbxproj`: the `SakinaWidget` group is a
`PBXFileSystemSynchronizedRootGroup` with an **empty `exceptions = ()`** list,
attached to the **SakinaWidgetExtension** target (and NOT Runner). That means
every file in `ios/SakinaWidget/` is a target member automatically — `.swift` →
Sources, `.json` → Resources. Proof: the original `catalog.json` is referenced
**nowhere** in `project.pbxproj` yet ships and loads fine today.

So both new files are **already** members — nothing to add in Xcode, and you
should NOT hand-edit `project.pbxproj` (that risks breaking the synced group):

1. **`SakinaDuaTimesWidget.swift`** — auto-compiled into SakinaWidgetExtension.
   (Correctly NOT `@main`; `SakinaWidgetBundle` remains the single `@main`.)
2. **`dua_calendar.json`** (bundled cold-start / travel-guard fallback, copied
   from `assets/dua_calendar/dua_windows.json`) — auto-bundled as a resource, so
   `Bundle.main.url(forResource: "dua_calendar", withExtension: "json")` resolves
   inside the extension, exactly like `catalog.json`.

The only real gate is a **clean build in Xcode / `flutter build ios`** — the
Swift was authored but never compiled in the dev env, so first build is the
proof. If a build ever fails on membership, re-check that no
`exceptions`/`membershipExceptions` were introduced for this folder.
3. **App Group** `group.com.sakina.app.widget` is **already shared** on both
   Runner and SakinaWidgetExtension (set up for the first widget) — no change
   needed. Both widgets read the same suite; only the payload KEY differs
   (`sakina_widget_payload` vs `sakina_dua_times_payload`).
4. **Fonts** — the duʿā widget reuses `ArefRuqaa-Regular` and `Outfit`, already
   staged in `Fonts/` and listed in the extension Info.plist. No new fonts.

### Payload contract note — `computed_at.built_at_utc` (added 2026-07-16)

The schedule's `computed_at` object carries an optional **`built_at_utc`** field —
an epoch-**millis** integer marking when the Flutter side built the payload
(nullable / absent when unknown). The widget decodes it as `Int64?` and uses it
for a **build-age staleness guard**: in addition to the existing horizon check
(`computed_through_utc < now`), a payload is treated as stale — and the widget
falls back to the bundled `dua_calendar.json` — when `built_at_utc` is present
AND `now − built_at > 48h`. If the field is absent, behavior is unchanged
(horizon-only staleness). The Dart writer in `widget_data_service.dart` should
emit `built_at_utc` under `computed_at` for this guard to engage; older payloads
without it still work.

Two related hardening changes shipped alongside it (no contract impact, just
fail-safe rendering): an unrecognized window `type`/`kind` is now **dropped**
rather than coerced to White Days (JSON may still carry extra `tier`/`title_key`/
`source_ref` keys — they're simply not decoded), so a future window kind renders
as *no window* instead of the wrong one.

### QA note for the duʿā widget

Add it via long-press ▸ **+** ▸ **Sakina** ▸ **Duʿā Times**. Verify: active
window shows "Make your duʿā" + a live `HH:MM:SS` countdown when <1h to close;
all-day windows (ʿArafah etc.) show "today only" and never tick; between-windows
shows "Build your duʿā" + a static relative label; lock-screen accessory is
monochrome (no color); every tap → Build-a-Duʿā. To exercise the **travel
guard**, change the device time zone in Settings without reopening the app — the
widget should drop precise night-third/Friday-hour windows and fall back to the
bundled calendar (Friday + seeded sacred days still render).

## Live Activity — SakinaDuaTimesLiveActivity (added 2026-07-17)

A **Live Activity** (Lock Screen + Dynamic Island) for the active duʿā window —
the same countdown as the home widget, promoted to a glanceable surface. v1 is a
purely **local, foreground-started** ticking countdown (no push/server). See
`docs/superpowers/plans/2026-07-16-dua-live-activities.md`.

### ✅ Done in code (Dart fully tested; Swift authored, needs first build)

- **Info.plist:** `NSSupportsLiveActivities = YES` added to BOTH
  `ios/Runner/Info.plist` and `ios/SakinaWidgetExtension-Info.plist`.
- **Dart seam:** `lib/services/dua_live_activity_service.dart` (channel
  `sakina/dua_live_activity`), wired into `DuaWindowNotifier` next to the widget
  push, ended on sign-out/delete in `auth_service.dart`. Unit-tested.
- **Swift:** `ios/DuaLiveActivityAttributes.swift` (shared attributes),
  `ios/SakinaWidget/DuaLiveActivity.swift` (ActivityConfiguration + Dynamic
  Island), `ios/Runner/LiveActivityBridge.swift` (ActivityKit bridge),
  registered in `AppDelegate`, and added to `SakinaWidgetBundle` (gated
  `if #available(iOS 16.2, *)`).

### ⚠️ Manual Xcode target membership (REQUIRED — do this before first build)

Unlike the `ios/SakinaWidget/` synced-group files, two files are NOT auto-added
to the right targets:

1. **`ios/DuaLiveActivityAttributes.swift`** — select it in Xcode → File
   Inspector → **Target Membership** → tick **BOTH** `Runner` AND
   `SakinaWidgetExtension`. (ActivityKit matches the activity to its config by
   this attributes type, so both the app and the extension must compile it.)
2. **`ios/Runner/LiveActivityBridge.swift`** — add to the **Runner** target only.
   (`DuaLiveActivity.swift` stays extension-only via the synced group.)

Do NOT hand-edit `project.pbxproj`. If the extension build ever complains about a
missing `DuaLiveActivityAttributes`, re-check membership #1.

### On-device QA (Dynamic Island needs an iPhone 14 Pro or later)

The existing **Dev Tools ▸ Duʿā Times preview** buttons drive the Live Activity
(they call `debugPreview`, which now syncs the LA):
- **Night · closing** / **Friday · closing** / **Friday · LAST CALL** → a
  time-boxed window is active → the Live Activity **starts** (Lock Screen +
  Dynamic Island), ticking `HH:MM:SS` to close; tap → Build-a-Duʿā.
- **ʿArafah · today** (all-day) → LA is **skipped** (O1) and any live one ends.
- **Between** → LA **ends** (flips to a static "Build your duʿā" grace state
  ~2 min, then dismisses).
- **Reset (real)** → syncs to the real schedule.

Also verify: Settings ▸ (disable Live Activities) → nothing starts, no crash;
sign out → the activity ends; the tap deep-link opens Build-a-Duʿā and fires
`dua_live_activity_tapped` (NOT `widget_opened`) — if the tap does NOT reach the
app, the LA URL isn't being forwarded to `HomeWidget.widgetClicked`; route
`sakina://widget/build-dua?source=live_activity` through `app_links` instead.

## ⬜ What's left (yours — needs a run / device / Apple account)

1. **Run it and add the widget** (simulator is fine for Small/Medium):
   `flutter run --dart-define-from-file=env.json`, then long-press the home
   screen ▸ **+** ▸ **Sakina** ▸ add Small or Medium.
2. **Visual/data QA:** Arabic renders in Aref Ruqaa (not system font); daily Name
   matches the app's home for the same day; do a check-in → streak chip turns
   emerald; tap → `/muhasabah`; dua pill → build-a-dua; sign out → widget reverts
   to daily with no streak (privacy).
3. **Physical device only:** Lock Screen + StandBy widgets. Automatic signing
   should provision the extension now that the App Group is set; if a release
   build complains, regenerate the profiles (see `TODO.md`).

If the Arabic shows as a plain font, the `Fonts/` subfolder path is the likely
cause — flatten the TTFs to the folder root. If the widget shows the generic
"Allah / Turn to Him" fallback after a check-in, the App Group payload isn't
landing — check the group ID on both targets.
