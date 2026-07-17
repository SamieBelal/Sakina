// Sakina duʿā-times widget — "make it now".
//
// A time-aware, CTA-first surface telling the user whether they are inside one
// of the Islamically-recognized windows when duʿā is more likely accepted
// (awqāt al-ijābah) — and if not, counting down / pointing at Build-a-Duʿā.
//
// COMPUTE IN FLUTTER, RENDER IN SWIFT. This extension has NO location and NO
// prayer math: it reads a precomputed schedule JSON the Flutter app writes to
// the App Group (via home_widget), and falls back to a bundled calendar export
// (dua_calendar.json) when the payload is missing/stale OR the travel guard
// trips. See docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md
// (§7, §9, §9.1, §10) and the sibling SakinaWidget.swift for house style.
//
// SETUP: this file is the extension SOURCE. Like SakinaWidget.swift it does not
// build until the Xcode target, App Group entitlement, bundled fonts, and
// dua_calendar.json are added — see SETUP.md.

import SwiftUI
import WidgetKit

// MARK: - Constants (mirror lib/services/widget_data_service.dart)

private let kAppGroupId = "group.com.sakina.app.widget"
private let kDuaPayloadKey = "sakina_dua_times_payload"
private let kDuaWidgetKind = "SakinaDuaTimesWidget"

// Reuse the SakinaWidget palette exactly (spec §9.1). Redeclared privately here
// because Swift `private` scopes to the file; values match SakinaWidget.swift.
private enum Palette {
    static let cream = Color(red: 0.984, green: 0.969, blue: 0.949)      // #FBF7F2
    static let emerald = Color(red: 0.106, green: 0.420, blue: 0.290)    // #1B6B4A
    static let goldInk = Color(red: 0.604, green: 0.435, blue: 0.216)    // #9A6F37
    static let gold = Color(red: 0.784, green: 0.596, blue: 0.369)       // #C8985E
    static let ink = Color(red: 0.173, green: 0.165, blue: 0.149)        // #2C2A26
    static let amber = Color(red: 0.910, green: 0.631, blue: 0.329)      // #E8A154
    static let amberInk = Color(red: 0.718, green: 0.416, blue: 0.125)   // #B76A20
}

// MARK: - Decoded schedule model (§7 contract — keys must match the golden JSON)

/// Mirrors `UrgencyState` in dua_window_type.dart. Decoded from the schedule's
/// `urgency` field; drives the escalation ladder without re-deriving it.
private enum Urgency: String, Decodable {
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
private enum WindowType: String, Decodable {
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
private struct Window: Decodable {
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

/// Travel-guard + staleness stamp (spec §7/§9, decision D5).
private struct Stamp: Decodable {
    let tz: String
    let lat: Double?
    let lon: Double?
    let computedThroughUTC: Date
    /// Epoch **millis** the payload was built (nullable/absent when unknown).
    /// Drives the build-age staleness guard in `resolve(at:)` — beyond 48h old
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

private struct Schedule: Decodable {
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
private struct FailableWindow: Decodable {
    let window: Window?
    init(from decoder: Decoder) throws {
        window = try? Window(from: decoder)
    }
}

// MARK: - Bundled calendar fallback (dua_calendar.json — mirrors the asset)

private struct CalendarRow: Decodable {
    let kind: String
    let tier: String
    let title_key: String
    let start_date: String   // "YYYY-MM-DD" bare local date
    let end_date: String
    let source_ref: String?
}

private struct CalendarFile: Decodable {
    let rows: [CalendarRow]
}

private func loadBundledCalendar() -> CalendarFile? {
    guard let url = Bundle.main.url(forResource: "dua_calendar", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let file = try? JSONDecoder().decode(CalendarFile.self, from: data)
    else { return nil }
    return file
}

/// Expand a bare "YYYY-MM-DD" date to its **device-local** midnight (spec §4
/// date-line rule). Returns nil on a malformed string.
private func localMidnight(_ ymd: String, _ cal: Calendar) -> Date? {
    let parts = ymd.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    var comps = DateComponents()
    comps.year = parts[0]
    comps.month = parts[1]
    comps.day = parts[2]
    return cal.date(from: comps).map { cal.startOfDay(for: $0) }
}

/// Map a bundled row's `kind` to a `WindowType`, or nil for an unknown/newer
/// kind — the caller skips those rows rather than mis-rendering them (fail safe).
private func windowType(fromKind kind: String) -> WindowType? {
    WindowType(rawValue: kind)
}

// MARK: - Payload loading

private func loadSchedule() -> Schedule? {
    guard let defaults = UserDefaults(suiteName: kAppGroupId),
          let raw = defaults.string(forKey: kDuaPayloadKey),
          let data = raw.data(using: .utf8),
          let schedule = try? JSONDecoder().decode(Schedule.self, from: data)
    else { return nil }
    return schedule
}

// MARK: - Resolution → the render model

/// What the widget shows at a given timeline instant. Flattened so the OS can
/// flip visuals from a pre-baked entry without a fresh provider call.
private struct DuaRender {
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

/// Recompute urgency for a specific instant. Mirrors `_urgencyFor` in
/// dua_window_engine.dart so pre-baked boundary entries escalate correctly even
/// if the provider isn't re-run (WidgetKit won't wake at an exact instant).
private func urgencyFor(active: Window?, at date: Date) -> Urgency {
    guard let w = active else { return .upcoming }
    if w.isAllDay { return .allDay }
    let remaining = w.endUTC.timeIntervalSince(date)
    if remaining <= 15 * 60 { return .lastCall }
    if remaining <= 60 * 60 { return .closing }
    return .comfortable
}

/// Suppress location-dependent windows when the device tz differs from the
/// stamp (spec §9/§10, D5): we'd otherwise show the OLD city's prayer times.
private func travelGuardTripped(_ stamp: Stamp) -> Bool {
    stamp.tz != "local" && stamp.tz != TimeZone.current.identifier
}

/// Build the render model from the App Group schedule, applying the travel
/// guard; on missing/stale payload OR a tripped guard with no calendar survivor,
/// fall back to the bundled calendar (Friday + seeded sacred days still render).
private func resolve(at date: Date) -> DuaRender {
    let cal = Calendar.current

    if let schedule = loadSchedule() {
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
            // Active window — suppressed if it's precise and the guard tripped.
            var active = schedule.active
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
    return resolveFromBundledCalendar(at: date, cal: cal)
}

private func resolveFromBundledCalendar(at date: Date, cal: Calendar) -> DuaRender {
    // Bundled fallback = no fresh located schedule → always prompt to open the app.
    guard let file = loadBundledCalendar() else {
        return DuaRender(window: nil, urgency: .upcoming, isActive: false,
                         at: date, promptEnable: true)
    }

    var active: Window?
    var upcoming: [Window] = []

    // Seeded all-day sacred days.
    for row in file.rows {
        // Unknown/newer kind → skip the row (don't coerce to White Days).
        guard let type = windowType(fromKind: row.kind) else { continue }
        guard let start = localMidnight(row.start_date, cal),
              let endInclusive = localMidnight(row.end_date, cal) else { continue }
        // end is inclusive → close at local midnight of the day AFTER end_date.
        let end = cal.date(byAdding: .day, value: 1, to: endInclusive) ?? endInclusive
        if end <= date { continue }
        let w = calendarWindow(type: type, start: start, end: end)
        if start <= date && date < end {
            if active == nil { active = w }
        } else if start > date {
            upcoming.append(w)
        }
    }

    // Friday (device weekday) — a whole local day, no data needed.
    if let friday = fridayWindow(covering: date, cal: cal) {
        active = active ?? friday
    }
    if let nextFriday = nextFridayWindow(after: date, cal: cal) {
        upcoming.append(nextFriday)
    }

    if let a = active {
        return DuaRender(window: a, urgency: .allDay, isActive: true, at: date,
                         promptEnable: true)
    }
    upcoming.sort { $0.startUTC < $1.startUTC }
    return DuaRender(window: upcoming.first, urgency: .upcoming,
                     isActive: false, at: date, promptEnable: true)
}

private func calendarWindow(type: WindowType, start: Date, end: Date) -> Window {
    // Construct via JSON round-trip-free init isn't available; build directly.
    Window(type: type,
           startUTC: start,
           endUTC: end,
           isAllDay: true,
           locationDependent: false)
}

/// Build a whole-local-day `.fridayDay` window starting at `start` (its local
/// midnight). Shared by the "covering today" and "next Friday" helpers so the
/// literal Window args live in exactly one place.
private func fridayWindow(start: Date, cal: Calendar) -> Window {
    let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
    return Window(type: .fridayDay, startUTC: start, endUTC: end,
                  isAllDay: true, locationDependent: false)
}

private func fridayWindow(covering date: Date, cal: Calendar) -> Window? {
    let start = cal.startOfDay(for: date)
    guard cal.component(.weekday, from: start) == 6 else { return nil } // Fri = 6
    return fridayWindow(start: start, cal: cal)
}

private func nextFridayWindow(after date: Date, cal: Calendar) -> Window? {
    let today = cal.startOfDay(for: date)
    for i in 1...7 {
        guard let day = cal.date(byAdding: .day, value: i, to: today) else { continue }
        if cal.component(.weekday, from: day) == 6 {
            return fridayWindow(start: day, cal: cal)
        }
    }
    return nil
}

// Convenience memberwise init for Window (Decodable declared a custom init, so
// add one for programmatic construction in the fallback path).
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

// MARK: - Copy tables (spec §9.1)

/// Short day/window label for the supporting cue ("ʿArafah", "Fajr", …).
private func windowLabel(_ w: Window) -> String {
    switch w.type {
    case .lastThirdOfNight: return "the last third of the night"
    case .fridayHour:       return "the Friday hour"
    case .iftar:            return "iftar"
    case .arafah:           return "ʿArafah"
    case .dhulHijjah10:     return "Dhul-Ḥijjah"
    case .laylatAlQadr:     return "Laylat al-Qadr"
    case .ramadan:          return "Ramadan"
    case .ashura:           return "ʿAshura"
    case .whiteDays:        return "the White Days"
    case .eid:              return "Eid"
    case .fridayDay:        return "Friday"
    }
}

/// The "until X" close reference for active time-boxed windows.
private func closeLabel(_ w: Window) -> String {
    switch w.type {
    case .lastThirdOfNight: return "until Fajr"
    case .fridayHour:       return "until Maghrib"
    case .iftar:            return "until Maghrib"
    default:                return "today only"
    }
}

/// A short "why" line for the medium home surface (source-flavored, never a
/// fabricated claim — these are curated framings, not scripture).
private func whyLine(_ w: Window) -> String {
    switch w.type {
    case .lastThirdOfNight: return "The last third of the night."
    case .fridayHour:       return "The last hour of Jumuʿah."
    case .iftar:            return "The fasting person's duʿā."
    case .arafah:           return "The best duʿā of the year."
    case .dhulHijjah10:     return "The ten most beloved days."
    case .laylatAlQadr:     return "Better than a thousand months."
    case .ramadan:          return "A month of mercy."
    case .ashura:           return "A blessed day of fasting."
    case .whiteDays:        return "The bright nights of the month."
    case .eid:              return "A blessed day of celebration."
    case .fridayDay:        return "The best day of the week."
    }
}

// MARK: - Deep link (reuse the existing widget deep-link style)

/// Whole widget AND every CTA → Build-a-Duʿā (spec §9 north star). The
/// `homeWidget` marker mirrors SakinaWidget.swift's links.
private func duaDeepLinkURL() -> URL {
    URL(string: "sakina://widget/build-dua?homeWidget")!
}

// MARK: - Countdown rule (§9 bullet 3 / §9.1 ladder)

/// Live `Text(timerInterval:)` ONLY for near time-boxed targets (closing /
/// last-call). All-day windows never tick; comfortable/between show static text.
private func showsLiveTimer(_ urgency: Urgency, isActive: Bool, window: Window?) -> Bool {
    guard isActive, let w = window, !w.isAllDay else { return false }
    return urgency == .closing || urgency == .lastCall
}

// MARK: - Timeline

private struct DuaEntry: TimelineEntry {
    let date: Date
    let render: DuaRender
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DuaEntry {
        DuaEntry(date: Date(), render: resolve(at: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (DuaEntry) -> Void) {
        completion(DuaEntry(date: Date(), render: resolve(at: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DuaEntry>) -> Void) {
        let now = Date()
        var entries: [DuaEntry] = [DuaEntry(date: now, render: resolve(at: now))]

        // Pre-bake entries at window BOUNDARIES so the render flips (active →
        // between, comfortable → closing → last-call) without a fresh provider
        // call. Mirror SakinaWidget.swift's pre-baked-entry approach.
        var boundaries: [Date] = []
        let schedule = loadSchedule()
        if let s = schedule {
            if let a = s.active {
                // Escalation thresholds for the active window + its close.
                let lastCall = a.endUTC.addingTimeInterval(-15 * 60)
                let closing = a.endUTC.addingTimeInterval(-60 * 60)
                boundaries.append(contentsOf: [closing, lastCall, a.endUTC])
            }
            for w in s.upcoming.prefix(6) {
                boundaries.append(w.startUTC)   // window opens
                boundaries.append(w.endUTC)     // window closes
            }
        }
        // Keep only future boundaries, sorted + de-duped, capped for budget.
        let future = Set(boundaries.filter { $0 > now })
            .sorted()
            .prefix(12)
        for b in future {
            entries.append(DuaEntry(date: b, render: resolve(at: b)))
        }

        let lastEntryDate = entries.map(\.date).max() ?? now
        // Reload after the last pre-baked boundary; but never let a thin schedule
        // go longer than a day without the OS re-asking (catches a stale payload
        // that the app hasn't refreshed). `.after(min(...))` = the sooner of the
        // two, so we always refresh at least daily.
        let dailyNudge = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? lastEntryDate
        let policyDate = min(lastEntryDate, dailyNudge)
        completion(Timeline(entries: entries, policy: .after(policyDate)))
    }
}

// MARK: - Shared view pieces

/// The SF Symbol per state (spec §9.1). moon.stars = comfortable/active,
/// exclamationmark.circle.fill = last-call, moon = between.
private func glyphName(urgency: Urgency, isActive: Bool) -> String {
    if urgency == .lastCall { return "exclamationmark.circle.fill" }
    if isActive { return "moon.stars" }
    return "moon"
}

private func verb(urgency: Urgency, isActive: Bool) -> String {
    if !isActive { return "Build your duʿā" }
    if urgency == .lastCall { return "Ask before it closes" }
    return "Make your duʿā"
}

/// SHORT verb for the tiny lock-screen accessories, so it never truncates
/// ("Ask before it clo…") — the accessory slot is a fixed OS size, so the copy
/// has to be terse to fill it fully.
private func lockVerb(urgency: Urgency, isActive: Bool) -> String {
    if !isActive { return "Build duʿā" }
    // "Make duʿā now" over "Ask now" — unambiguous. Urgency is carried by the
    // ⚠ glyph + ticking countdown, so we don't need a separate last-call verb.
    return "Make duʿā now"
}

private func ctaText(isActive: Bool) -> String {
    isActive ? "Ask now →" : "Build now →"
}

// MARK: - Home views (color available)

/// systemSmall — verb leads, one supporting cue, gold CTA pill. Under 15m the
/// whole card shifts amber (spec §9.1 mockup).
private struct DuaSmallView: View {
    let render: DuaRender
    private var urgent: Bool { render.urgency == .lastCall }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: glyphName(urgency: render.urgency, isActive: render.isActive))
                    .font(.system(size: 18))
                    .foregroundColor(urgent ? Palette.amberInk : Palette.emerald)
                Spacer()
            }
            Spacer(minLength: 2)
            Text(verb(urgency: render.urgency, isActive: render.isActive))
                .font(.custom("Outfit", size: 18)).fontWeight(.bold)
                .foregroundColor(urgent ? Color(red: 0.29, green: 0.20, blue: 0.09) : Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
            cue
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 2)
            Text(ctaText(isActive: render.isActive))
                .font(.custom("Outfit", size: 12.5)).fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(urgent ? Palette.amber : Palette.gold)
                .clipShape(Capsule())
        }
        .padding(14)
        .widgetURL(duaDeepLinkURL())
    }

    @ViewBuilder private var cue: some View {
        if showsLiveTimer(render.urgency, isActive: render.isActive, window: render.window),
           let w = render.window {
            Text(timerInterval: render.at...w.endUTC, countsDown: true)
                .font(.custom("Outfit", size: 12.5)).fontWeight(.semibold)
                .foregroundColor(urgent ? Palette.amberInk : Color(red: 0.44, green: 0.42, blue: 0.38))
                .monospacedDigit()
                .lineLimit(1)
        } else {
            Text(cueText)
                .font(.custom("Outfit", size: 12.5)).fontWeight(.semibold)
                .foregroundColor(Color(red: 0.44, green: 0.42, blue: 0.38))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private var cueText: String {
        // Location off → point them to the app (widget can't prompt).
        if render.promptEnable { return "Open Sakina · precise times" }
        guard let w = render.window else { return "" }
        if render.isActive {
            if w.isAllDay { return "today only" }
            return closeLabel(w)
        }
        return windowLabel(w)
    }
}

/// systemMedium — crescent + `دُعَاء` hero (own RTL Aref Ruqaa, never mixed) on
/// the left; kicker / verb / why / countdown + gold CTA on the right.
private struct DuaMediumView: View {
    let render: DuaRender
    private var urgent: Bool { render.urgency == .lastCall }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                Image(systemName: glyphName(urgency: render.urgency, isActive: render.isActive))
                    .font(.system(size: 22))
                    .foregroundColor(urgent ? Palette.amberInk : Palette.emerald)
                Text("دُعَاء")
                    .font(.custom("ArefRuqaa-Regular", size: 26))
                    .foregroundColor(urgent ? Palette.amberInk : Palette.emerald)
                    .environment(\.layoutDirection, .rightToLeft)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(width: 88)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(urgent
                          ? Color(red: 0.97, green: 0.88, blue: 0.78)
                          : Color(red: 0.89, green: 0.93, blue: 0.90))
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(kicker)
                    .font(.custom("Outfit", size: 10.5)).fontWeight(.bold)
                    .foregroundColor(urgent ? Palette.amberInk : Palette.goldInk)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(verb(urgency: render.urgency, isActive: render.isActive))
                    .font(.custom("Outfit", size: 21)).fontWeight(.heavy)
                    .foregroundColor(urgent ? Color(red: 0.29, green: 0.20, blue: 0.09) : Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.55)
                if render.promptEnable {
                    // Widget extensions can't request location — tell a
                    // widget-only user where the switch is (spec §9).
                    Label("Open Sakina to turn on precise times",
                          systemImage: "location.circle.fill")
                        .font(.custom("Outfit", size: 12)).fontWeight(.semibold)
                        .foregroundColor(Palette.goldInk)
                        .lineLimit(2).minimumScaleFactor(0.75)
                } else if let w = render.window {
                    Text(render.isActive ? whyLine(w) : "\(windowLabel(w)) — \(whyLine(w))")
                        .font(.custom("Outfit", size: 12.5)).fontWeight(.medium)
                        .foregroundColor(Color(red: 0.44, green: 0.42, blue: 0.38))
                        .lineLimit(2).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 2)
                HStack(alignment: .center, spacing: 8) {
                    countdown
                    Spacer(minLength: 4)
                    Link(destination: duaDeepLinkURL()) {
                        Text(ctaText(isActive: render.isActive))
                            .font(.custom("Outfit", size: 13)).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(urgent ? Palette.amber : Palette.gold)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .widgetURL(duaDeepLinkURL())
    }

    private var kicker: String {
        if !render.isActive { return "Coming up" }
        switch render.urgency {
        case .lastCall:  return "Closing soon"
        case .allDay:    return "Today"
        default:         return "A beloved time"
        }
    }

    @ViewBuilder private var countdown: some View {
        if showsLiveTimer(render.urgency, isActive: render.isActive, window: render.window),
           let w = render.window {
            (Text(render.urgency == .lastCall ? "closing · " : "")
                + Text(timerInterval: render.at...w.endUTC, countsDown: true))
                .font(.custom("Outfit", size: 13)).fontWeight(.bold)
                .foregroundColor(urgent ? Palette.amberInk : Color(red: 0.44, green: 0.42, blue: 0.38))
                .monospacedDigit()
                .lineLimit(1)
        } else {
            Text(staticCountLabel)
                .font(.custom("Outfit", size: 13)).fontWeight(.bold)
                .foregroundColor(Color(red: 0.44, green: 0.42, blue: 0.38))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private var staticCountLabel: String {
        guard let w = render.window else { return "" }
        if render.isActive {
            return w.isAllDay ? "today only" : closeLabel(w)
        }
        // Between: static relative label ("opens Tomorrow", "opens Fri").
        return "opens \(relativeDay(w.startUTC))"
    }
}

/// A coarse relative-day label for between-state targets (§9 static label).
private func relativeDay(_ date: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(date) { return "today" }
    if cal.isDateInTomorrow(date) { return "tomorrow" }
    let days = cal.dateComponents([.day],
                                  from: cal.startOfDay(for: Date()),
                                  to: cal.startOfDay(for: date)).day ?? 0
    if days <= 6 && days >= 0 {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }
    return "in \(days)d"
}

// MARK: - Lock screen views (MONOCHROME — urgency by number + glyph, never color)

/// accessoryRectangular — one line: glyph + verb + cue. Live countdown replaces
/// the static cue when closing/last-call. Never color (system tints it).
private struct DuaRectView: View {
    let render: DuaRender

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: glyphName(urgency: render.urgency, isActive: render.isActive))
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                fittedVerb
                cue
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(duaDeepLinkURL())
    }

    /// The verb at the LARGEST size that fits the accessory width on one line.
    /// `minimumScaleFactor` is unreliable on Lock-Screen accessories, so we use
    /// `ViewThatFits` (WidgetKit's proper tool): it renders the first candidate
    /// that fits, biggest → smallest, so the verb is never truncated.
    @ViewBuilder private var fittedVerb: some View {
        let s = lockVerb(urgency: render.urgency, isActive: render.isActive)
        ViewThatFits(in: .horizontal) {
            Text(s).font(.title2).fontWeight(.semibold).lineLimit(1)
            Text(s).font(.title3).fontWeight(.semibold).lineLimit(1)
            Text(s).font(.headline).lineLimit(1)
            Text(s).font(.subheadline).fontWeight(.semibold).lineLimit(1)
            Text(s).font(.footnote).fontWeight(.semibold).lineLimit(1)
        }
    }

    @ViewBuilder private var cue: some View {
        if showsLiveTimer(render.urgency, isActive: render.isActive, window: render.window),
           let w = render.window {
            (Text(timerInterval: render.at...w.endUTC, countsDown: true)
                + Text(" left"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
        } else {
            Text(cueText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private var cueText: String {
        guard let w = render.window else { return "" }
        if render.isActive {
            return w.isAllDay ? "today only" : closeLabel(w)
        }
        return "\(windowLabel(w)) · \(relativeDay(w.startUTC))"
    }
}

/// accessoryInline — one row shared with the clock. Max restraint.
private struct DuaInlineView: View {
    let render: DuaRender

    var body: some View {
        if showsLiveTimer(render.urgency, isActive: render.isActive, window: render.window),
           let w = render.window {
            // System caps inline to a single Text-ish view; concatenate.
            Label {
                Text(lockVerb(urgency: render.urgency, isActive: render.isActive))
                    + Text(" · ")
                    + Text(timerInterval: render.at...w.endUTC, countsDown: true)
            } icon: {
                Image(systemName: glyphName(urgency: render.urgency, isActive: render.isActive))
            }
        } else {
            Label(inlineText, systemImage: glyphName(urgency: render.urgency, isActive: render.isActive))
        }
    }

    private var inlineText: String {
        guard let w = render.window else {
            return lockVerb(urgency: render.urgency, isActive: render.isActive)
        }
        if render.isActive {
            let tail = w.isAllDay ? "make duʿā" : closeLabel(w)
            return "\(lockVerb(urgency: render.urgency, isActive: render.isActive)) · \(tail)"
        }
        return "Build duʿā · \(windowLabel(w)) \(relativeDay(w.startUTC))"
    }
}

// MARK: - Entry view + container (iOS 17 guard, mirror SakinaWidget.swift)

private struct DuaTimesEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DuaEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            accessoryContainer { DuaRectView(render: entry.render) }
        case .accessoryInline:
            // Inline never adopts containerBackground.
            DuaInlineView(render: entry.render)
        case .systemMedium:
            container { DuaMediumView(render: entry.render) }
        default:
            container { DuaSmallView(render: entry.render) }
        }
    }

    @ViewBuilder private func accessoryContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 17.0, *) {
            content().containerBackground(.clear, for: .widget)
        } else {
            content()
        }
    }

    @ViewBuilder private func container<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 17.0, *) {
            content().containerBackground(Palette.cream, for: .widget)
        } else {
            content().background(Palette.cream)
        }
    }
}

// NOTE: @main is SakinaWidgetBundle; this widget is referenced from its body, so
// it must NOT also be @main.
struct SakinaDuaTimesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kDuaWidgetKind, provider: Provider()) { entry in
            DuaTimesEntryView(entry: entry)
        }
        .configurationDisplayName("Duʿā Times")
        .description("The best times to raise your hands — with a live countdown.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
