// Pure resolution core for the Sakina duʿā-times widget.
//
// EXTRACTED from SakinaDuaTimesWidget.swift so the decode + resolve logic is
// Foundation-only (no SwiftUI / WidgetKit) and therefore unit-testable with a
// plain `swiftc` harness — the widget extension itself can't run under XCTest
// without the full Xcode target. The widget file keeps the App-Group load, the
// bundled-calendar fallback, the copy tables, and all the views; it delegates
// the "which window, active or upcoming, at this instant" decision to
// `resolveDecoded` here.
//
// Keys must match the golden JSON (§7 contract). See the widget file header.
//
// Types + funcs here are `internal` (not `private`) so the standalone swiftc
// harness in ../SakinaWidgetTests/main.swift can exercise them directly. The
// `ios/SakinaWidget/` folder is a PBXFileSystemSynchronizedRootGroup, so this
// file joins the widget extension target automatically — no .pbxproj wiring.

import Foundation

// MARK: - Decoded schedule model (§7 contract — keys must match the golden JSON)

/// Mirrors `UrgencyState` in dua_window_type.dart. Decoded from the schedule's
/// `urgency` field; drives the escalation ladder without re-deriving it.
enum Urgency: String, Decodable {
    case comfortable
    case closing
    case lastCall = "last_call"
    case allDay = "all_day"
    case upcoming
}

/// Mirrors `DuaWindowType` @JsonValue strings in dua_window_type.dart. An
/// unrecognized string is intentionally NOT coerced — `Window`'s decoder drops
/// the whole window rather than mis-render an unknown future kind (fail safe:
/// no window over the wrong window). Default `RawRepresentable` conformance
/// gives us the throwing decode we want (unknown raw ⇒ decode error, caught by
/// the caller).
enum WindowType: String, Decodable {
    case lastThirdOfNight = "last_third_of_night"
    case fridayHour = "friday_hour"
    case iftar
    case arafah
    case dhulHijjah10 = "dhul_hijjah_10"
    case laylatAlQadr = "laylat_al_qadr"
    case ramadan
    case ashura
    case whiteDays = "white_days"
    case eid
    case fridayDay = "friday_day"
}

/// One resolved window. Instants arrive as epoch **millis** (int) — divide by
/// 1000 for `Date(timeIntervalSince1970:)` (§7 / EpochMillisConverter).
struct Window: Decodable {
    let type: WindowType
    let startUTC: Date
    let endUTC: Date
    let isAllDay: Bool
    let locationDependent: Bool

    // NOTE: `tier`, `title_key`, `source_ref` may still be present in the JSON
    // but are deliberately NOT decoded — all copy is driven by `type`. An
    // unrecognized `type` throws here so callers can drop the window (fail safe).
    enum CodingKeys: String, CodingKey {
        case type
        case startUTC = "start_utc"
        case endUTC = "end_utc"
        case isAllDay = "is_all_day"
        case locationDependent = "location_dependent"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(WindowType.self, forKey: .type)
        startUTC = Self.date(try c.decode(Int64.self, forKey: .startUTC))
        endUTC = Self.date(try c.decode(Int64.self, forKey: .endUTC))
        isAllDay = try c.decode(Bool.self, forKey: .isAllDay)
        locationDependent = try c.decode(Bool.self, forKey: .locationDependent)
    }

    private static func date(_ millis: Int64) -> Date {
        Date(timeIntervalSince1970: Double(millis) / 1000.0)
    }
}

// Convenience memberwise init for Window (Decodable declared a custom init, so
// add one for programmatic construction in the fallback path + tests).
extension Window {
    init(type: WindowType, startUTC: Date, endUTC: Date,
         isAllDay: Bool, locationDependent: Bool) {
        self.type = type
        self.startUTC = startUTC
        self.endUTC = endUTC
        self.isAllDay = isAllDay
        self.locationDependent = locationDependent
    }
}

/// Travel-guard + staleness stamp (spec §7/§9, decision D5).
struct Stamp: Decodable {
    let tz: String
    let lat: Double?
    let lon: Double?
    let computedThroughUTC: Date
    /// Epoch **millis** the payload was built (nullable/absent when unknown).
    /// Drives the build-age staleness guard in `resolveDecoded` — beyond 48h old
    /// we drop to the bundled calendar even if the horizon still covers `date`.
    let builtAtUTC: Int64?

    enum CodingKeys: String, CodingKey {
        case tz
        case lat
        case lon
        case computedThroughUTC = "computed_through_utc"
        case builtAtUTC = "built_at_utc"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tz = try c.decode(String.self, forKey: .tz)
        lat = try c.decodeIfPresent(Double.self, forKey: .lat)
        lon = try c.decodeIfPresent(Double.self, forKey: .lon)
        let millis = try c.decode(Int64.self, forKey: .computedThroughUTC)
        computedThroughUTC = Date(timeIntervalSince1970: Double(millis) / 1000.0)
        builtAtUTC = try c.decodeIfPresent(Int64.self, forKey: .builtAtUTC)
    }
}

struct Schedule: Decodable {
    let active: Window?
    let next: Window?
    let upcoming: [Window]
    let urgency: Urgency
    let computedAt: Stamp

    enum CodingKeys: String, CodingKey {
        case active
        case next
        case upcoming
        case urgency
        case computedAt = "computed_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // A window with an unrecognized `type` throws in Window.init — treat it
        // as absent rather than coercing it to the wrong kind (fail safe, §7).
        active = (try? c.decodeIfPresent(Window.self, forKey: .active)) ?? nil
        next = (try? c.decodeIfPresent(Window.self, forKey: .next)) ?? nil
        upcoming = Self.decodeUpcoming(from: c)
        urgency = (try? c.decode(Urgency.self, forKey: .urgency)) ?? .upcoming
        computedAt = try c.decode(Stamp.self, forKey: .computedAt)
    }

    /// Decode `upcoming` element-by-element so one window with an unknown
    /// `type` is dropped instead of failing the whole array. Each slot is first
    /// consumed as a `FailableWindow` (which always succeeds and advances the
    /// unkeyed container's cursor), then its optional payload is unwrapped.
    private static func decodeUpcoming(
        from c: KeyedDecodingContainer<CodingKeys>
    ) -> [Window] {
        guard var array = try? c.nestedUnkeyedContainer(forKey: .upcoming) else {
            return []
        }
        var result: [Window] = []
        while !array.isAtEnd {
            // FailableWindow.init never throws, so the cursor always advances —
            // avoids the classic "failed decode doesn't consume the element"
            // stall in an unkeyed container.
            guard let slot = try? array.decode(FailableWindow.self) else { break }
            if let w = slot.window { result.append(w) }
        }
        return result
    }
}

/// Wraps a `Window` decode so an element with an unknown `type` (or otherwise
/// malformed) yields `window == nil` instead of throwing — letting the unkeyed
/// container advance past it. Used only to skip bad rows in `upcoming`.
struct FailableWindow: Decodable {
    let window: Window?
    init(from decoder: Decoder) throws {
        window = try? Window(from: decoder)
    }
}

// MARK: - Render model

/// What the widget shows at a given timeline instant. Flattened so the OS can
/// flip visuals from a pre-baked entry without a fresh provider call.
struct DuaRender {
    /// The window driving the copy — active if any, else the next upcoming one.
    let window: Window?
    /// Escalation state (already recomputed for THIS entry's instant).
    let urgency: Urgency
    /// True when [window] is active (inside its bounds) vs an upcoming target.
    let isActive: Bool
    /// The instant urgency should be evaluated from (the timeline entry's date).
    let at: Date
    /// True when we're NOT showing precise times — location was never granted
    /// (`computed_at.lat == nil`) or we're on the stale/bundled fallback. The
    /// home widget then shows an "Open Sakina to turn on precise times" hint,
    /// since a widget extension can't request location itself (spec §9).
    var promptEnable: Bool = false
}

// MARK: - Pure helpers

/// Recompute urgency for a specific instant. Mirrors `_urgencyFor` in
/// dua_window_engine.dart so pre-baked boundary entries escalate correctly even
/// if the provider isn't re-run (WidgetKit won't wake at an exact instant).
func urgencyFor(active: Window?, at date: Date) -> Urgency {
    guard let w = active else { return .upcoming }
    if w.isAllDay { return .allDay }
    let remaining = w.endUTC.timeIntervalSince(date)
    if remaining <= 15 * 60 { return .lastCall }
    if remaining <= 60 * 60 { return .closing }
    return .comfortable
}

/// Suppress location-dependent windows when the device tz differs from the
/// stamp (spec §9/§10, D5): we'd otherwise show the OLD city's prayer times.
func travelGuardTripped(_ stamp: Stamp) -> Bool {
    stamp.tz != "local" && stamp.tz != TimeZone.current.identifier
}

// MARK: - Resolution core

/// Decide what to render at `date` from the App-Group `schedule`, applying the
/// travel guard + staleness guards. On missing/stale payload OR a tripped guard
/// with no surviving window, invokes `fallback` (the bundled-calendar path).
///
/// Pure + Foundation-only so it can be unit-tested without WidgetKit.
func resolveDecoded(_ schedule: Schedule?,
                    at date: Date,
                    fallback: () -> DuaRender) -> DuaRender {
    if let schedule = schedule {
        let tripped = travelGuardTripped(schedule.computedAt)
        // Horizon staleness: the payload no longer covers this instant.
        var stale = schedule.computedAt.computedThroughUTC < date
        // Build-age staleness: if the payload declares when it was built and
        // that's older than 48h, distrust it (data drift) and fall through to
        // the bundled calendar. Absent `built_at_utc` ⇒ horizon-only (legacy).
        if let builtMillis = schedule.computedAt.builtAtUTC {
            let builtAt = Date(timeIntervalSince1970: Double(builtMillis) / 1000.0)
            if date.timeIntervalSince(builtAt) > 48 * 3600 { stale = true }
        }

        if !stale {
            // No location stamp ⇒ user never granted → prompt them to open the
            // app (or after a tripped guard, opening re-computes at the new tz).
            let prompt = schedule.computedAt.lat == nil || tripped
            // Active window — but only if it's STILL within its bounds at this
            // instant. The payload names the window that was live when it was
            // BUILT; a pre-baked boundary entry (or a payload the app hasn't
            // re-pushed yet) can ask us to render an instant AFTER that window
            // closed. Without this end-check a Friday all-day window keeps
            // rendering "Make duʿā now · today only" into Saturday. Dropping it
            // here falls through to the upcoming/next branch so the widget
            // self-heals at the window's end without waiting on a fresh push.
            var active = schedule.active
            if let a = active, date >= a.endUTC {
                active = nil
            }
            // …and suppressed if it's precise and the travel guard tripped.
            if let a = active, tripped && a.locationDependent {
                active = nil
            }
            if let a = active {
                return DuaRender(window: a,
                                 urgency: urgencyFor(active: a, at: date),
                                 isActive: true,
                                 at: date,
                                 promptEnable: prompt)
            }
            // Between: point at the next window. When the guard tripped, skip
            // precise upcoming windows and surface the next calendar one.
            let upcoming = schedule.upcoming.filter { $0.startUTC >= date }
            let candidate = upcoming.first {
                !(tripped && $0.locationDependent)
            } ?? (tripped ? nil : schedule.next)
            if let n = candidate {
                return DuaRender(window: n, urgency: .upcoming,
                                 isActive: false, at: date,
                                 promptEnable: prompt)
            }
        }
    }

    // No usable payload (missing / stale / guard left nothing) → bundled calendar.
    return fallback()
}
