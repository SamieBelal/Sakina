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

### QA note for the duʿā widget

Add it via long-press ▸ **+** ▸ **Sakina** ▸ **Duʿā Times**. Verify: active
window shows "Make your duʿā" + a live `HH:MM:SS` countdown when <1h to close;
all-day windows (ʿArafah etc.) show "today only" and never tick; between-windows
shows "Build your duʿā" + a static relative label; lock-screen accessory is
monochrome (no color); every tap → Build-a-Duʿā. To exercise the **travel
guard**, change the device time zone in Settings without reopening the app — the
widget should drop precise night-third/Friday-hour windows and fall back to the
bundled calendar (Friday + seeded sacred days still render).

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
