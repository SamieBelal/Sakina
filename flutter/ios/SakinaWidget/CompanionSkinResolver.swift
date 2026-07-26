// Foundation-only core of the companion widget's lantern-skin resolution.
//
// Split out of SakinaCompanionWidget.swift (which imports SwiftUI/WidgetKit and
// therefore can't be compiled by a CLI test harness) so the payload decoding,
// id sanitisation, and asset fallback chain are unit-testable — same split as
// DuaScheduleResolver.swift. Tested by ios/SakinaWidgetTests/CompanionSkin/main.swift.
//
// Auto-bundled: ios/SakinaWidget/ is a Xcode-16 file-system-synchronized group,
// so this file compiles into the widget target with no manual "add to target".

import Foundation

/// The skin the widget falls back to. MUST match `kDefaultWidgetLanternSkinId`
/// in `lib/services/widget_data_service.dart` and `LanternSkin.classicGold.id`.
let kDefaultLanternSkinId = "classic_gold"

/// The subset of the shared widget payload the companion widget reads.
///
/// `lantern_skin` is optional ON PURPOSE: payloads written by an app build older
/// than Lane E have no such key, and `Decodable` must not fail on them (the
/// widget would fall back to its logged-out state and lose the streak).
/// Unknown keys are ignored by `Decodable`, so the reverse direction — an old
/// widget reading a new payload — is safe too.
struct CompanionPayload: Decodable {
    let checked_in_today: Bool
    let streak: Int
    let updated_at: String
    let mode: String
    let lantern_skin: String?
}

/// Decode the raw App-Group JSON. Returns nil for a missing/garbled blob.
func decodeCompanionPayload(_ raw: String?) -> CompanionPayload? {
    guard let raw = raw,
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(CompanionPayload.self, from: data)
    else { return nil }
    return payload
}

/// Accept only ids that can safely address a bundled asset: lowercase ASCII,
/// digits, and underscores. Anything else (a path fragment, mixed case, an
/// empty string, a nil) resolves to the default rather than being interpolated
/// into a `Bundle.main.url(forResource:)` lookup.
func sanitizedLanternSkinId(_ raw: String?) -> String {
    guard let raw = raw, !raw.isEmpty, raw.count <= 64 else {
        return kDefaultLanternSkinId
    }
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
    guard raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
        return kDefaultLanternSkinId
    }
    return raw
}

/// Asset base names to try, most specific first:
///   1. the equipped skin's frame            (`companion_<skin>_<brightness>`)
///   2. the default skin's frame             (`companion_classic_gold_<brightness>`)
///   3. the legacy un-prefixed frame         (`companion_<brightness>`)
///
/// Step 2 covers a skin equipped on a newer app build than the installed widget
/// has frames for (the Dart writer already filters those, but the widget must
/// not depend on the writer being current). Step 3 is the last resort that keeps
/// pre-Lane-E installs and any missed export from rendering blank.
func companionAssetCandidates(skinId: String, brightness: String) -> [String] {
    let skin = sanitizedLanternSkinId(skinId)
    var names = ["companion_\(skin)_\(brightness)"]
    if skin != kDefaultLanternSkinId {
        names.append("companion_\(kDefaultLanternSkinId)_\(brightness)")
    }
    names.append("companion_\(brightness)")
    return names
}
