// Sakina home-screen widget — "A Name for What You're Carrying".
//
// Renders a daily Name of Allah framed to an emotional state, plus the
// muḥāsabah streak. Reads a JSON payload the Flutter app writes to the App
// Group (via the home_widget plugin), and falls back to a bundled catalog when
// there is no personalized state (logged out / cold start / stale). The daily
// index matches the app's getTodaysName() exactly (dayOfYear % count).
//
// SETUP: this file is the extension SOURCE. It does not build until the Xcode
// target, App Group entitlement (both targets), bundled fonts, and catalog.json
// are added — see SETUP.md.

import SwiftUI
import WidgetKit

// MARK: - Constants (mirror lib/services/widget_data_service.dart)

private let kAppGroupId = "group.com.sakina.app.widget"
private let kPayloadKey = "sakina_widget_payload"
private let kWidgetKind = "SakinaWidget"

private enum Palette {
    static let cream = Color(red: 0.984, green: 0.969, blue: 0.949)      // #FBF7F2
    static let charcoal = Color(red: 0.165, green: 0.153, blue: 0.137)   // #2A2723
    static let emerald = Color(red: 0.106, green: 0.420, blue: 0.290)    // #1B6B4A
    static let emeraldDark = Color(red: 0.561, green: 0.827, blue: 0.690) // #8FD3B0
    static let goldInk = Color(red: 0.604, green: 0.435, blue: 0.216)    // #9A6F37
    static let gold = Color(red: 0.784, green: 0.596, blue: 0.369)       // #C8985E
    static let ink = Color(red: 0.173, green: 0.165, blue: 0.149)        // #2C2A26
    static let amber = Color(red: 0.910, green: 0.631, blue: 0.329)      // #E8A154
}

// MARK: - Model

private struct NameDisplay {
    let nameKey: String
    let arabic: String
    let transliteration: String
    let english: String
    let anchor: String
    let streak: Int
    /// nil = don't show a streak (logged out); .done/.pending/.atRisk otherwise.
    let streakState: StreakState
}

private enum StreakState { case hidden, zero, done, pending, atRisk }

private struct CatalogRow: Decodable {
    let index: Int
    let name_key: String
    let arabic: String
    let transliteration: String
    let english: String
    let anchor: String
}

private struct Catalog: Decodable {
    let count: Int
    let names: [CatalogRow]
}

private struct Payload: Decodable {
    let mode: String
    let name_key: String
    let name: String
    let name_english: String
    let arabic: String
    let transliteration: String
    let anchor: String
    let checked_in_today: Bool
    let streak: Int
    let updated_at: String
}

// MARK: - Data loading

private func loadCatalog() -> Catalog? {
    guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let catalog = try? JSONDecoder().decode(Catalog.self, from: data)
    else { return nil }
    return catalog
}

private func loadPayload() -> Payload? {
    guard let defaults = UserDefaults(suiteName: kAppGroupId),
          let raw = defaults.string(forKey: kPayloadKey),
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(Payload.self, from: data)
    else { return nil }
    return payload
}

/// Days since Jan 1 (local), matching the Dart `getTodaysName()` calculation.
private func dayOfYear(_ date: Date, _ cal: Calendar) -> Int {
    let start = cal.date(from: cal.dateComponents([.year], from: date))!
    return cal.dateComponents([.day], from: start, to: cal.startOfDay(for: date)).day ?? 0
}

private func dailyRow(for date: Date, catalog: Catalog, cal: Calendar) -> CatalogRow {
    let idx = dayOfYear(date, cal) % catalog.names.count
    return catalog.names[idx]
}

private func isSameLocalDay(_ isoString: String, _ date: Date, _ cal: Calendar) -> Bool {
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let parsed = fmt.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    guard let parsed = parsed else { return false }
    return cal.isDate(parsed, inSameDayAs: date)
}

/// Resolve what to show at a given timeline instant. `pastEightPM`/`nextDay`
/// are pre-baked variants so the OS flips the visual without a fresh provider
/// call (WidgetKit won't wake at an exact wall-clock instant).
private func resolve(at date: Date, phase: RenderPhase) -> NameDisplay {
    let cal = Calendar.current
    let catalog = loadCatalog()
    let payload = loadPayload()

    // Personalized only when checked in today AND the payload is from today.
    let personalized = payload.map {
        $0.checked_in_today && $0.mode == "personalized" &&
            isSameLocalDay($0.updated_at, date, cal)
    } ?? false

    let base: (key: String, arabic: String, translit: String, english: String, anchor: String)
    if personalized, let p = payload {
        base = (p.name_key, p.arabic, p.transliteration, p.name_english, p.anchor)
    } else if let catalog = catalog, !catalog.names.isEmpty {
        let row = dailyRow(for: date, catalog: catalog, cal: cal)
        base = (row.name_key, row.arabic, row.transliteration, row.english, row.anchor)
    } else {
        base = ("", "الله", "Allah", "The One", "Turn to Him.")
    }

    let streak = payload?.streak ?? 0
    let checkedIn = personalized
    let state: StreakState
    if payload == nil {
        state = .hidden                       // logged out
    } else if streak <= 0 {
        state = .zero
    } else if checkedIn {
        state = .done
    } else if phase == .eveningAtRisk {
        state = .atRisk
    } else {
        state = .pending
    }

    return NameDisplay(nameKey: base.key, arabic: base.arabic,
                       transliteration: base.translit, english: base.english,
                       anchor: base.anchor, streak: streak, streakState: state)
}

private enum RenderPhase { case current, eveningAtRisk, nextDay }

// MARK: - Timeline

private struct NameEntry: TimelineEntry {
    let date: Date
    let display: NameDisplay
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NameEntry {
        NameEntry(date: Date(), display: resolve(at: Date(), phase: .current))
    }

    func getSnapshot(in context: Context, completion: @escaping (NameEntry) -> Void) {
        completion(NameEntry(date: Date(), display: resolve(at: Date(), phase: .current)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NameEntry>) -> Void) {
        let cal = Calendar.current
        let now = Date()
        var entries: [NameEntry] = [
            NameEntry(date: now, display: resolve(at: now, phase: .current))
        ]
        // Pre-bake 8pm (loss-aversion) and next-midnight (roll Name) so the
        // render flips even without a fresh provider call.
        if let eightPM = cal.date(bySettingHour: 20, minute: 0, second: 0, of: now),
           eightPM > now {
            entries.append(NameEntry(date: eightPM,
                                     display: resolve(at: eightPM, phase: .eveningAtRisk)))
        }
        let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now)!)
        entries.append(NameEntry(date: nextMidnight,
                                 display: resolve(at: nextMidnight, phase: .nextDay)))

        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }
}

// MARK: - Views

private func widgetDeepLinkURL(_ nameKey: String, build: Bool = false) -> URL? {
    let path = build ? "build-dua" : "muhasabah"
    let key = build && !nameKey.isEmpty ? "&name_key=\(nameKey)" : ""
    return URL(string: "sakina://widget/\(path)?homeWidget\(key)")
}

/// A capsule pill that visually matches the Dua pill (same padding/shape), so
/// the footer reads as a matched pair. Uses Outfit (the app's Latin UI font).
private struct StreakChip: View {
    let display: NameDisplay
    var body: some View {
        switch display.streakState {
        case .hidden:
            EmptyView()
        case .zero:
            pill("Start your streak", icon: "sparkles",
                 fg: Palette.goldInk, bg: Palette.gold.opacity(0.16))
        case .done:
            pill("\(display.streak)", icon: "flame.fill",
                 fg: Palette.emerald, bg: Palette.emerald.opacity(0.12))
        case .pending:
            pill("\(display.streak)", icon: "flame.fill",
                 fg: Palette.goldInk, bg: Palette.gold.opacity(0.16))
        case .atRisk:
            pill("Don't lose your \(display.streak)", icon: "flame.fill",
                 fg: Palette.amber, bg: Palette.amber.opacity(0.18))
        }
    }

    private func pill(_ text: String, icon: String, fg: Color, bg: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.custom("Outfit", size: 12)).fontWeight(.semibold)
            .foregroundColor(fg)
            .lineLimit(1)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(bg)
            .clipShape(Capsule())
    }
}

/// Medium — Direction B: Arabic hero left (~40%), meta right.
private struct MediumView: View {
    let display: NameDisplay
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(display.arabic)
                    .font(.custom("ArefRuqaa-Regular", size: 44))
                    .foregroundColor(Palette.emerald)
                    .environment(\.layoutDirection, .rightToLeft)
                    .minimumScaleFactor(0.45).lineLimit(1)
                Text(display.transliteration)
                    .font(.custom("Outfit", size: 16)).fontWeight(.bold)
                    .foregroundColor(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                // Anchor is the hook — no redundant "A NAME FOR YOU" label.
                // Shrink-to-fit: the full anchor ALWAYS shows (up to 3 lines).
                Text(display.anchor)
                    .font(.custom("Outfit", size: 15)).fontWeight(.medium)
                    .foregroundColor(Palette.ink)
                    .lineLimit(3).minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                Text(display.english)
                    .font(.custom("Outfit", size: 12))
                    .foregroundColor(Palette.ink.opacity(0.65))
                    .lineLimit(1).minimumScaleFactor(0.6)
                // Matched capsule pills, vertically centered: streak (status) and
                // Dua (action) read as a proper pair.
                HStack(alignment: .center, spacing: 6) {
                    StreakChip(display: display)
                    Spacer(minLength: 4)
                    Link(destination: widgetDeepLinkURL(display.nameKey, build: true) ?? URL(string: "sakina://widget/muhasabah")!) {
                        Label("Dua", systemImage: "hands.sparkles.fill")
                            .font(.custom("Outfit", size: 12)).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Palette.gold).clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .widgetURL(widgetDeepLinkURL(display.nameKey))
    }
}

/// Small — centered single column (Direction B's two columns don't fit 2×2).
private struct SmallView: View {
    let display: NameDisplay
    var body: some View {
        // 2×2 is too small for a full sentence — show the glanceable core
        // (Name + meaning + streak), all shrink-to-fit so nothing truncates.
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            Text(display.arabic)
                .font(.custom("ArefRuqaa-Regular", size: 40))
                .foregroundColor(Palette.emerald)
                .environment(\.layoutDirection, .rightToLeft)
                .minimumScaleFactor(0.45).lineLimit(1)
            Text(display.transliteration)
                .font(.custom("Outfit", size: 17)).fontWeight(.bold)
                .foregroundColor(Palette.ink)
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(display.english)
                .font(.custom("Outfit", size: 11))
                .foregroundColor(Palette.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            StreakChip(display: display)
        }
        .padding(14)
        .widgetURL(widgetDeepLinkURL(display.nameKey))
    }
}

/// Lock Screen (highest-frequency surface, ~80–100 glances/day) = the muḥāsabah
/// RETENTION NUDGE. State-driven, loss-aversion when the daily reflection isn't
/// done; a calm reward when it is; fresh daily content when logged out. Tinted
/// monochrome by the system, so state is conveyed by TEXT, never color.
private struct AccessoryView: View {
    let display: NameDisplay

    private var title: String {
        switch display.streakState {
        case .done:    return display.transliteration        // reward: the Name you received
        case .pending: return "Reflect today"                // gentle nudge
        case .atRisk:  return "Don't lose your \(display.streak)"  // loss aversion (evening)
        case .zero:    return "Reflect today"
        case .hidden:  return display.transliteration         // logged out: fresh daily Name
        }
    }

    @ViewBuilder private var subtitle: some View {
        switch display.streakState {
        case .done:
            Label("\(display.streak) · \(display.english)", systemImage: "flame.fill")
                .labelStyle(.titleAndIcon)
        case .pending:
            Label("Keep your \(display.streak)", systemImage: "flame.fill")
                .labelStyle(.titleAndIcon)
        case .atRisk:
            Text("Reflect before midnight")
        case .zero:
            Text("Start your streak")
        case .hidden:
            Text(display.english)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.title3).fontWeight(.semibold)
                .lineLimit(1).minimumScaleFactor(0.6)
            subtitle
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .widgetURL(widgetDeepLinkURL(display.nameKey))
    }
}

private struct SakinaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NameEntry

    var body: some View {
        switch family {
        case .systemSmall:
            container { SmallView(display: entry.display) }
        case .accessoryRectangular:
            // Lock Screen accessory: still MUST adopt containerBackground on
            // iOS 17+, but transparent so the system tint/material shows.
            accessoryContainer { AccessoryView(display: entry.display) }
        default:
            container { MediumView(display: entry.display) }
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

// NOTE: the @main entry point is SakinaWidgetBundle (Xcode wizard file); this
// widget is referenced from its body, so it must NOT also be @main.
struct SakinaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kWidgetKind, provider: Provider()) { entry in
            SakinaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("A Name for What You're Carrying")
        .description("A daily Name of Allah for how you feel — and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
