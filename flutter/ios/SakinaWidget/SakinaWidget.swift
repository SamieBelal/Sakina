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
    /// True when today's Name has not been revealed yet, so there is no Name to
    /// show. The Name fields are empty in this state and views MUST render the
    /// invitation instead. See `resolve(at:phase:)`.
    let awaitingReveal: Bool
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

    // `awaiting` = signed in, but today's Name has not been revealed yet, so
    // there is no Name to show (W4 Wave 6). The app used to send a day-of-year
    // rotation here and this extension ignored it and computed its own — either
    // way the widget was naming a Name that had nothing to do with the reveal,
    // which comes from the queue planner or `pickNextCard`. Harmless while the
    // reveal was a blind gacha; a broken promise now that it is the answer to a
    // question the user was asked.
    //
    // Nothing is guessed to replace it. Showing the queue's next Name cannot be
    // made correct offline: this provider pre-bakes a next-midnight entry and
    // then sleeps on `.after(nextMidnight)`, so it would have to know the
    // server-side unseal and its 20-hour floor, and would still be wrong
    // whenever the plan holds or the queue is exhausted and the reveal falls
    // through to an ordinary pull.
    //
    // Also date-guarded: a payload from a previous day says nothing about
    // today, so it decays back to the catalog rotation rather than freezing the
    // widget in an invitation forever if the app is never opened again.
    let awaiting = payload.map {
        $0.mode == "awaiting" && isSameLocalDay($0.updated_at, date, cal)
    } ?? false

    let base: (key: String, arabic: String, translit: String, english: String, anchor: String)
    if personalized, let p = payload {
        base = (p.name_key, p.arabic, p.transliteration, p.name_english, p.anchor)
    } else if awaiting {
        // Deliberately empty: the awaiting views render none of these, and
        // leaving a Name here is a Name some future reader will show.
        base = ("", "", "", "", "")
    } else if let catalog = catalog, !catalog.names.isEmpty {
        // Logged out, or a stale payload — the catalog rotation is honest here
        // because it is content, not a promise about the user's own day.
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
                       anchor: base.anchor, streak: streak, streakState: state,
                       awaitingReveal: awaiting)
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
    // build-a-dua is need-based (free text), not tied to a Name, so no name_key.
    let path = build ? "build-dua" : "muhasabah"
    return URL(string: "sakina://widget/\(path)?homeWidget")
}

/// The pre-reveal hero: what stands where the Name stands, before there is a
/// Name. Says exactly what the home CTA and the question screen say, so the
/// widget, the button and the prompt are one sentence rather than three.
///
/// Valence-neutral on purpose (spec M4) — a widget that asks what is *weighing*
/// on you has no slot for the honest answer on a good day, and this one is on
/// the Home Screen where it is read dozens of times.
private struct AwaitingHero: View {
    /// Arabic-hero point size of the family this replaces, so the invitation
    /// occupies the same optical weight as the Name it stands in for.
    let heroSize: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: heroSize * 0.42))
                .foregroundColor(Palette.gold)
            Text("What's on your heart today?")
                .font(.custom("Outfit", size: heroSize * 0.36)).fontWeight(.semibold)
                .foregroundColor(Palette.emerald)
                .multilineTextAlignment(.center)
                .lineLimit(3).minimumScaleFactor(0.6)
        }
    }
}

/// A capsule pill that visually matches the Dua pill (same padding/shape), so
/// the footer reads as a matched pair. Uses Outfit (the app's Latin UI font).
private struct StreakChip: View {
    let display: NameDisplay

    /// Drops the `.atRisk` loss copy back to the neutral count.
    ///
    /// Set in the **awaiting** state only (W4 Wave 6 review, F2). The 8 PM
    /// timeline entry resolves `.atRisk` whenever the user has not revealed
    /// yet — which IS the awaiting state — so the widget read "What's on your
    /// heart today?" directly above "Don't lose your 5". That is a guilt
    /// mechanic underneath an invitation, on a Home Screen surface seen dozens
    /// of times a day, and plan §2 rule 6 forbids it. The wave made the hero
    /// valence-neutral for exactly that reason; this carries the same rule one
    /// line down.
    ///
    /// The streak still shows — the count, the flame, the gold. Only the
    /// framing changes, and only here: outside awaiting the chip is untouched,
    /// because a user who HAS reflected is being told about a streak they are
    /// keeping rather than one they are about to lose.
    var suppressLossFraming: Bool = false

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
            if suppressLossFraming {
                pill("\(display.streak)", icon: "flame.fill",
                     fg: Palette.goldInk, bg: Palette.gold.opacity(0.16))
            } else {
                pill("Don't lose your \(display.streak)", icon: "flame.fill",
                     fg: Palette.amber, bg: Palette.amber.opacity(0.18))
            }
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
                if display.awaitingReveal {
                    AwaitingHero(heroSize: 44)
                } else {
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
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                // Anchor is the hook — no redundant "A NAME FOR YOU" label.
                // Shrink-to-fit: the full anchor ALWAYS shows (up to 3 lines).
                // Pre-reveal there is no anchor (it is the Name's teaching line),
                // so the slot carries the invitation's second half instead.
                Text(display.awaitingReveal
                     ? "Answer today's question to meet your Name."
                     : display.anchor)
                    .font(.custom("Outfit", size: 15)).fontWeight(.medium)
                    .foregroundColor(Palette.ink)
                    .lineLimit(3).minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                // The Name's meaning. Omitted entirely pre-reveal rather than
                // rendered empty — an empty Text still reserves a line and would
                // leave a visible gap where a meaning used to be.
                if !display.awaitingReveal {
                    Text(display.english)
                        .font(.custom("Outfit", size: 12))
                        .foregroundColor(Palette.ink.opacity(0.65))
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
                // Matched capsule pills, vertically centered: streak (status) and
                // Dua (action) read as a proper pair.
                //
                // The Spacer belongs to the PAIR, not to the row. `StreakChip`
                // renders `EmptyView()` when the streak state is `.hidden`
                // (logged out — see the payload check in `makeDisplay`), and an
                // unconditional Spacer then shoved a lone Dua pill against the
                // right edge with a hand-span of dead space beside it. With no
                // chip there is no pair to separate, so the pill simply starts
                // at the leading edge the way the lantern widget's Reflect pill
                // already does. Founder, 2026-07-29.
                HStack(alignment: .center, spacing: 6) {
                    if display.streakState != .hidden {
                        StreakChip(display: display,
                                   suppressLossFraming: display.awaitingReveal)
                        Spacer(minLength: 4)
                    }
                    Link(destination: widgetDeepLinkURL(display.nameKey, build: true) ?? URL(string: "sakina://widget/muhasabah")!) {
                        Label("Dua", systemImage: "hands.sparkles.fill")
                            .font(.custom("Outfit", size: 12)).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Palette.gold).clipShape(Capsule())
                    }
                    if display.streakState == .hidden {
                        Spacer(minLength: 0)
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

/// Small — the "status" tile: Name + a state-driven footer that prompts
/// "Reflect today" when the daily muḥāsabah isn't done, and rewards the streak
/// when it is. Colors render on the Home Screen (unlike the tinted Lock Screen).
private struct SmallView: View {
    let display: NameDisplay
    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            if display.awaitingReveal {
                AwaitingHero(heroSize: 40)
            } else {
                Text(display.arabic)
                    .font(.custom("ArefRuqaa-Regular", size: 40))
                    .foregroundColor(Palette.emerald)
                    .environment(\.layoutDirection, .rightToLeft)
                    .minimumScaleFactor(0.45).lineLimit(1)
                Text(display.transliteration)
                    .font(.custom("Outfit", size: 17)).fontWeight(.bold)
                    .foregroundColor(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(14)
        .widgetURL(widgetDeepLinkURL(display.nameKey))
    }

    @ViewBuilder private var footer: some View {
        // Pre-reveal the hero already asks the question, so the footer carries
        // the streak rather than repeating the CTA underneath it. This is the
        // "lantern + streak, no Name" state plan §8 asks for: status, not a
        // second prompt. (`.hidden` is unreachable here — awaiting requires a
        // payload, and `.done` requires personalized, which awaiting is not.)
        if display.awaitingReveal {
            StreakChip(display: display, suppressLossFraming: true)
        } else {
            nameFooter
        }
    }

    @ViewBuilder private var nameFooter: some View {
        switch display.streakState {
        case .done:
            // Reward: the streak chip (they've reflected today).
            StreakChip(display: display)
        case .pending, .atRisk:
            // Not reflected yet → the CTA (this is the "status" tile's job).
            Text("Reflect today")
                .font(.custom("Outfit", size: 12)).fontWeight(.bold)
                .foregroundColor(Palette.goldInk)
        case .zero:
            Text("Start your streak")
                .font(.custom("Outfit", size: 12)).fontWeight(.semibold)
                .foregroundColor(Palette.goldInk)
        case .hidden:
            // Logged out → the meaning (content, no personal state).
            Text(display.english)
                .font(.custom("Outfit", size: 11))
                .foregroundColor(Palette.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.7)
        }
    }
}

/// Lock Screen (highest-frequency surface, ~80–100 glances/day) = the muḥāsabah
/// RETENTION NUDGE. State-driven, loss-aversion when the daily reflection isn't
/// done; a calm reward when it is; fresh daily content when logged out. Tinted
/// monochrome by the system, so state is conveyed by TEXT, never color.
private struct AccessoryView: View {
    let display: NameDisplay

    /// The awaiting state is neutral here too (W4 Wave 6 review, F2).
    ///
    /// The small and medium families already suppress loss framing while the
    /// user has not answered yet — `AwaitingHero` plus
    /// `StreakChip(suppressLossFraming: true)`. This view was missed, and it is
    /// the WORST place to miss it: the Lock Screen is the highest-frequency
    /// surface in the app, ~80–100 glances a day.
    ///
    /// The 8 PM timeline entry resolves `.atRisk` whenever the reveal has not
    /// happened, which IS the awaiting state — so an evening glance read
    /// "Don't lose your 5" / "Reflect before midnight" about a question the app
    /// had not yet asked. Plan §2 rule 6 forbids exactly that: no guilt
    /// mechanic under an invitation, and no clock near the reveal.
    ///
    /// `.pending`'s "Keep your 5" goes the same way while awaiting. It is
    /// softer than the `.atRisk` copy but it is the same move, and `StreakChip`
    /// resolves both to the bare count. The streak still shows; only the
    /// framing changes, and only here — outside awaiting every branch below is
    /// untouched, because a user who HAS reflected is being told about a streak
    /// they are keeping rather than one they are about to lose.
    private var title: String {
        if display.awaitingReveal { return "What's on your heart today?" }
        switch display.streakState {
        case .done:    return display.transliteration        // reward: the Name you received
        case .pending: return "Reflect today"                // gentle nudge
        case .atRisk:  return "Don't lose your \(display.streak)"  // loss aversion (evening)
        case .zero:    return "Reflect today"
        case .hidden:  return display.transliteration         // logged out: fresh daily Name
        }
    }

    @ViewBuilder private var subtitle: some View {
        if display.awaitingReveal {
            // The count, the flame — never the loss. Mirrors
            // `StreakChip(suppressLossFraming: true)` exactly.
            if display.streak > 0 {
                Label("\(display.streak)", systemImage: "flame.fill")
                    .labelStyle(.titleAndIcon)
            } else {
                Text("Start your streak")
            }
        } else {
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
