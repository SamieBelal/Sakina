# SakinaWidget — Xcode setup checklist

The Swift/plist/entitlements files here are the widget **source**. They do not
build until the Xcode target and capabilities are wired. Do these on the Mac,
then `flutter build ios`. Ordered; each step is required.

## 1. Create the Widget Extension target
- Xcode → open `ios/Runner.xcworkspace` → File ▸ New ▸ Target ▸ **Widget Extension**.
- Product name: `SakinaWidget`. **Uncheck** "Include Configuration Intent" (we use `StaticConfiguration`). **Uncheck** "Include Live Activity".
- When prompted "Activate scheme?", Activate.
- Delete the auto-generated `SakinaWidget.swift`/`Assets`/`Info.plist` Xcode created, and **add the files in this folder** to the new target instead (`SakinaWidget.swift`, `Info.plist`, `SakinaWidget.entitlements`, `catalog.json`).
- Set the target's **Info.plist** build setting to `ios/SakinaWidget/Info.plist`.
- Deployment target: iOS 16.0+ (accessory/Lock Screen). Small/Medium work on 14+.

## 2. App Group (BOTH targets)
- Runner target ▸ Signing & Capabilities ▸ **+ Capability ▸ App Groups** ▸ add
  `group.com.sakina.app.widget`.
- SakinaWidget target ▸ same capability, same group. (The committed
  `SakinaWidget.entitlements` already declares it; make sure the target's
  CODE_SIGN_ENTITLEMENTS points at it.)
- This group ID MUST equal `kWidgetAppGroupId` in
  `lib/services/widget_data_service.dart`. If you change it, change it in all
  three places (both entitlements + Dart).

## 3. Bundle `catalog.json`
- Add `ios/SakinaWidget/catalog.json` to the **SakinaWidget** target's
  "Copy Bundle Resources". Regenerate it whenever the Names/anchors change:
  `dart run scripts/gen_widget_catalog.dart` (fails if the mapping isn't a
  bijection). The parity test `test/services/widget_catalog_parity_test.dart`
  guards app↔widget agreement.

## 4. Fonts (ALREADY DOWNLOADED — just add to the target)
The TTFs are already staged in **`ios/SakinaWidget/Fonts/`** (OFL, fetched from
Google Fonts): `ArefRuqaa-Regular.ttf`, `Amiri-Regular.ttf`,
`DMSerifDisplay-Regular.ttf`, `DMSans.ttf` (variable — weights via
SwiftUI `.fontWeight()`). The app uses runtime `google_fonts`, which the widget
process cannot use, hence the bundled copies.
- In Xcode, drag the `Fonts/` folder into the **SakinaWidget** target's
  "Copy Bundle Resources" (or add each TTF). The `UIAppFonts` entries in
  `Info.plist` already match these filenames.
- Sanity-check PostScript names once in Font Book (Aref Ruqaa → `ArefRuqaa-Regular`,
  DM Serif Display → `DMSerifDisplay-Regular`, DM Sans → `DMSans`). If any differ,
  adjust the `.custom("…")` names in `SakinaWidget.swift`.

## 5. URL scheme for deep links
- Runner target ▸ Info ▸ URL Types ▸ add URL Scheme **`sakina`** (matches
  `kWidgetUrlScheme` in `lib/core/widget_deep_link.dart` and the `.widgetURL`s
  in `SakinaWidget.swift`).

## 6. Provisioning
- Adding an extension = a second bundle ID (`…Runner.SakinaWidget`) + its own
  provisioning profile, and the App Group must be enabled on both App IDs in the
  Apple Developer portal. Automatic signing usually handles this; for manual
  signing regenerate both profiles. **This will break `flutter build ios
  --release` until the profiles exist** — see `TODO.md` release checklist.

## 7. Verify on a physical device
- Add the widget (Small, Medium, Lock Screen). Confirm: Arabic renders in Aref
  Ruqaa (not system), daily Name matches the app's home for the same day, tap →
  muḥāsabah, dua pill → build-a-dua, streak states (do a check-in → chip turns
  emerald), sign out → widget reverts to daily with no streak (privacy).
