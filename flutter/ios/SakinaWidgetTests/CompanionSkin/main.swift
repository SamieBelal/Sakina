// Standalone TDD harness for the companion widget's lantern-skin resolution.
//
// The widget extension can't run under XCTest without a full Xcode target
// (there isn't one), so we compile the Foundation-only resolver together with
// this file via `swiftc` and run it directly — same pattern as
// ios/SakinaWidgetTests/main.swift:
//
//   swiftc ios/SakinaWidget/CompanionSkinResolver.swift \
//          ios/SakinaWidgetTests/CompanionSkin/main.swift \
//          -o /tmp/companion_skin_tests && /tmp/companion_skin_tests
//
// Lives in a subdirectory because top-level executable code is only legal in a
// file named main.swift, and ios/SakinaWidgetTests/main.swift is taken.
// Exits non-zero if any check fails.

import Foundation

var failures = 0
func check(_ cond: Bool, _ msg: String) {
    if cond {
        print("PASS: \(msg)")
    } else {
        print("FAIL: \(msg)")
        failures += 1
    }
}

func payload(skinLine: String) -> String {
    """
    {
      "mode": "personalized",
      "name_key": "al-malik",
      "checked_in_today": true,
      "streak": 12,
      "updated_at": "2026-07-26T09:00:00.000Z"\(skinLine)
    }
    """
}

// ---------------------------------------------------------------------------
// Backward compatibility: a payload written by an app build older than Lane E
// has no lantern_skin key. It must still decode, and resolve to the default.
// ---------------------------------------------------------------------------
do {
    let p = decodeCompanionPayload(payload(skinLine: ""))
    check(p != nil, "a payload without lantern_skin still decodes")
    check(p?.streak == 12, "the rest of the payload decodes normally")
    check(sanitizedLanternSkinId(p?.lantern_skin) == kDefaultLanternSkinId,
          "a missing lantern_skin resolves to classic_gold")
}

// ---------------------------------------------------------------------------
// Forward path: an equipped skin is carried through verbatim.
// ---------------------------------------------------------------------------
do {
    let p = decodeCompanionPayload(payload(skinLine: ",\n  \"lantern_skin\": \"obsidian_gold\""))
    check(sanitizedLanternSkinId(p?.lantern_skin) == "obsidian_gold",
          "an equipped skin id is used as-is")
}

// ---------------------------------------------------------------------------
// Hostile / garbled ids must never reach a Bundle resource lookup.
// ---------------------------------------------------------------------------
do {
    check(sanitizedLanternSkinId("../../etc/passwd") == kDefaultLanternSkinId,
          "a path-traversal id falls back to the default")
    check(sanitizedLanternSkinId("") == kDefaultLanternSkinId,
          "an empty id falls back to the default")
    check(sanitizedLanternSkinId("Obsidian_Gold") == kDefaultLanternSkinId,
          "asset names are lowercase; a mixed-case id falls back")
    check(sanitizedLanternSkinId(nil) == kDefaultLanternSkinId,
          "a nil id falls back to the default")
    check(decodeCompanionPayload("not json at all") == nil,
          "garbage JSON decodes to nil, not a crash")
    check(decodeCompanionPayload(nil) == nil, "a nil raw payload decodes to nil")
}

// ---------------------------------------------------------------------------
// The asset fallback chain: specific skin -> classic_gold -> legacy frame.
// A widget must never be able to render blank.
// ---------------------------------------------------------------------------
do {
    let c = companionAssetCandidates(skinId: "obsidian_gold", brightness: "fullyLit")
    check(c == ["companion_obsidian_gold_fullyLit",
                "companion_classic_gold_fullyLit",
                "companion_fullyLit"],
          "a non-default skin gets the full three-step fallback chain")

    let d = companionAssetCandidates(skinId: "classic_gold", brightness: "dim")
    check(d == ["companion_classic_gold_dim", "companion_dim"],
          "the default skin does not repeat itself in the chain")

    let u = companionAssetCandidates(skinId: "!!bad!!", brightness: "glowing")
    check(u == ["companion_classic_gold_glowing", "companion_glowing"],
          "a rejected id resolves to the default skin's chain")
}

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) CHECK(S) FAILED")
exit(failures == 0 ? 0 : 1)
