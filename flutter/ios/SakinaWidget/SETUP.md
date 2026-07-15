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
