// Standalone TDD harness for the duʿā-times widget resolution core.
//
// The widget extension can't run under XCTest without the full Xcode target, so
// we compile the Foundation-only resolver together with this file via `swiftc`
// and run it directly:
//
//   swiftc ios/SakinaWidget/DuaScheduleResolver.swift \
//          ios/SakinaWidgetTests/main.swift \
//          -o /tmp/duaresolvertests && /tmp/duaresolvertests
//
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

func millis(_ d: Date) -> Int64 { Int64(d.timeIntervalSince1970 * 1000) }

/// Build a §7-shaped payload JSON. `activeStart/activeEnd` bound the all-day
/// window the payload declares active at build time; `built` is when it was
/// built; `through` is the horizon end.
func payloadJSON(activeStart: Date, activeEnd: Date,
                 nextStart: Date, nextEnd: Date,
                 built: Date, through: Date) -> String {
    """
    {
      "active": {
        "type": "friday_day",
        "start_utc": \(millis(activeStart)),
        "end_utc": \(millis(activeEnd)),
        "is_all_day": true,
        "location_dependent": false
      },
      "next": {
        "type": "friday_day",
        "start_utc": \(millis(nextStart)),
        "end_utc": \(millis(nextEnd)),
        "is_all_day": true,
        "location_dependent": false
      },
      "upcoming": [
        {
          "type": "friday_day",
          "start_utc": \(millis(nextStart)),
          "end_utc": \(millis(nextEnd)),
          "is_all_day": true,
          "location_dependent": false
        }
      ],
      "urgency": "all_day",
      "computed_at": {
        "tz": "local",
        "computed_through_utc": \(millis(through)),
        "built_at_utc": \(millis(built))
      }
    }
    """
}

/// Payload variant for the prompt/refresh split: `tz` and `lat` are the two
/// fields that decide which message the widget shows.
func payloadJSON(tz: String, lat: Double?,
                 activeStart: Date, activeEnd: Date,
                 nextStart: Date, nextEnd: Date,
                 built: Date, through: Date) -> String {
    let latField = lat.map { "\"lat\": \($0)," } ?? ""
    return """
    {
      "active": {
        "type": "friday_day",
        "start_utc": \(millis(activeStart)),
        "end_utc": \(millis(activeEnd)),
        "is_all_day": true,
        "location_dependent": false
      },
      "next": null,
      "upcoming": [],
      "urgency": "all_day",
      "computed_at": {
        "tz": "\(tz)",
        \(latField)
        "computed_through_utc": \(millis(through)),
        "built_at_utc": \(millis(built))
      }
    }
    """
}

func decode(_ json: String) -> Schedule {
    try! JSONDecoder().decode(Schedule.self, from: json.data(using: .utf8)!)
}

/// A fallback sentinel so we can tell "hit the bundled calendar" apart from the
/// between/next branch.
func fallbackSentinel(at date: Date) -> DuaRender {
    DuaRender(window: nil, urgency: .upcoming, isActive: false,
              at: date, promptEnable: true)
}

let hour: TimeInterval = 3600
let day: TimeInterval = 24 * 3600

// ---------------------------------------------------------------------------
// Case 1 (the reported bug): a Friday all-day window that ENDED before the
// render instant must NOT render as active. Payload built 36h ago (fresh),
// horizon far in the future — so neither staleness guard fires; only the
// end-of-window check can drop it.
// ---------------------------------------------------------------------------
do {
    let render = Date(timeIntervalSince1970: 1_785_000_000) // "Saturday noon"
    let activeStart = render.addingTimeInterval(-36 * hour)  // Friday 00:00
    let activeEnd = render.addingTimeInterval(-12 * hour)    // Saturday 00:00 (ended)
    let nextStart = render.addingTimeInterval(6 * day)       // next Friday
    let nextEnd = render.addingTimeInterval(7 * day)
    let built = render.addingTimeInterval(-36 * hour)        // within 48h
    let through = render.addingTimeInterval(30 * day)        // horizon still covers now

    let schedule = decode(payloadJSON(
        activeStart: activeStart, activeEnd: activeEnd,
        nextStart: nextStart, nextEnd: nextEnd,
        built: built, through: through))

    let r = resolveDecoded(schedule, at: render) { fallbackSentinel(at: render) }

    check(!r.isActive,
          "an all-day window that ended before the render instant is not active")
    check(r.window != nil && r.window?.startUTC == nextStart,
          "resolution points at the next upcoming window, not the ended one")
    check(r.urgency == .upcoming,
          "urgency is 'upcoming' once the active window has ended")
}

// ---------------------------------------------------------------------------
// Case 2 (guard against over-correction): a window still in bounds at the
// render instant MUST stay active. Protects the fix from dropping live windows.
// ---------------------------------------------------------------------------
do {
    let render = Date(timeIntervalSince1970: 1_785_000_000)
    let activeStart = render.addingTimeInterval(-6 * hour)   // opened this morning
    let activeEnd = render.addingTimeInterval(12 * hour)     // ends tonight (still live)
    let nextStart = render.addingTimeInterval(6 * day)
    let nextEnd = render.addingTimeInterval(7 * day)
    let built = render.addingTimeInterval(-6 * hour)
    let through = render.addingTimeInterval(30 * day)

    let schedule = decode(payloadJSON(
        activeStart: activeStart, activeEnd: activeEnd,
        nextStart: nextStart, nextEnd: nextEnd,
        built: built, through: through))

    let r = resolveDecoded(schedule, at: render) { fallbackSentinel(at: render) }

    check(r.isActive && r.window?.startUTC == activeStart,
          "a window still within its bounds stays active")
    check(r.urgency == .allDay,
          "an ongoing all-day window keeps 'all_day' urgency")
}

// ---------------------------------------------------------------------------
// The prompt/refresh split. `promptEnable` used to be
// `lat == nil || tripped`, so a user who granted location and then travelled
// was told to "turn on precise times" — something they had already done.
// ---------------------------------------------------------------------------
do {
    let render = Date(timeIntervalSince1970: 1_785_000_000)
    let activeStart = render.addingTimeInterval(-6 * hour)
    let activeEnd = render.addingTimeInterval(12 * hour)
    let built = render.addingTimeInterval(-6 * hour)
    let through = render.addingTimeInterval(30 * day)
    let here = TimeZone.current.identifier

    // No location at all → a permission pointer, and NOT a refresh hint.
    let noLoc = decode(payloadJSON(
        tz: here, lat: nil,
        activeStart: activeStart, activeEnd: activeEnd,
        nextStart: activeStart, nextEnd: activeEnd,
        built: built, through: through))
    let a = resolveDecoded(noLoc, at: render) { fallbackSentinel(at: render) }
    check(a.promptEnable, "no location stamp → prompt to open the app")
    check(!a.needsRefresh, "no location is not a refresh problem")

    // Located, but the device has moved to another time zone → refresh, and
    // emphatically NOT a permission pitch.
    let travelled = decode(payloadJSON(
        tz: here == "Asia/Riyadh" ? "America/Los_Angeles" : "Asia/Riyadh",
        lat: 21.4225,
        activeStart: activeStart, activeEnd: activeEnd,
        nextStart: activeStart, nextEnd: activeEnd,
        built: built, through: through))
    let b = resolveDecoded(travelled, at: render) { fallbackSentinel(at: render) }
    check(!b.promptEnable,
          "a travelled user already granted — never pitch permission at them")
    check(b.needsRefresh, "a tripped travel guard asks for a refresh")

    // Located and in the right place → say nothing.
    let fine = decode(payloadJSON(
        tz: here, lat: 21.4225,
        activeStart: activeStart, activeEnd: activeEnd,
        nextStart: activeStart, nextEnd: activeEnd,
        built: built, through: through))
    let c = resolveDecoded(fine, at: render) { fallbackSentinel(at: render) }
    check(!c.promptEnable && !c.needsRefresh,
          "a located, current payload shows no nudge at all")
}

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) CHECK(S) FAILED")
exit(failures == 0 ? 0 : 1)
