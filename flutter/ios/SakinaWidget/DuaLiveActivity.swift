// Sakina duʿā-times Live Activity — the active-window countdown promoted to the
// Lock Screen + Dynamic Island.
//
// v1 is a purely LOCAL, foreground-started ticking countdown (no push). It is
// STARTED by the app (LiveActivityBridge in the Runner target) when the user
// foregrounds during a time-boxed window; once started, `Text(timerInterval:)`
// ticks on-device with no further updates. See
// docs/superpowers/plans/2026-07-16-dua-live-activities.md.
//
// SELF-CONTAINED BY DESIGN: this file does NOT depend on the shipped
// SakinaDuaTimesWidget.swift. It derives its small copy set from the
// `windowType` string the app sends over the channel, so the two shipped home
// widgets are untouched (zero regression risk). The copy here is the same
// spec §9.1 voice as the widget — keep the two in sync if either changes.
//
// SETUP: like the other files in ios/SakinaWidget/, this is auto-compiled into
// the SakinaWidgetExtension via the file-system-synchronized group (SETUP.md).
// It also needs `NSSupportsLiveActivities = YES` in the extension Info.plist
// (added) and the same key on the Runner (added). All ActivityKit types are
// gated `@available(iOS 16.2, *)` so the extension still compiles below 16.2.

import ActivityKit
import SwiftUI
import WidgetKit

// The `DuaLiveActivityAttributes` type lives in the shared
// ios/DuaLiveActivityAttributes.swift (a member of BOTH Runner + the extension).

// MARK: - Copy (spec §9.1 voice — mirrors the widget's tables for time-boxed
// windows; v1 only ever starts time-boxed windows).

@available(iOS 16.2, *)
private enum DuaLiveCopy {
    /// The "until X" close reference for the active window.
    static func closeLabel(_ windowType: String) -> String {
        switch windowType {
        case "last_third_of_night": return "until Fajr"
        case "friday_hour":         return "until Maghrib"
        case "iftar":               return "until Maghrib"
        default:                    return "closing soon"
        }
    }

    /// A short window label ("the last third of the night", …).
    static func windowLabel(_ windowType: String) -> String {
        switch windowType {
        case "last_third_of_night": return "the last third of the night"
        case "friday_hour":         return "the Friday hour"
        case "iftar":               return "iftar"
        default:                    return "a beloved time"
        }
    }

    /// The lead verb. Amber last-call is a color treatment, not a copy change,
    /// so the verb stays calm + unambiguous (matches the widget's `lockVerb`).
    static func verb(urgency: String) -> String {
        urgency == "last_call" ? "Ask before it closes" : "Make your duʿā"
    }

    /// SF Symbol per state — crescent normally, ⚠ on last-call.
    static func glyph(urgency: String) -> String {
        urgency == "last_call" ? "exclamationmark.circle.fill" : "moon.stars"
    }
}

@available(iOS 16.2, *)
private func duaEndDate(_ state: DuaLiveActivityAttributes.ContentState) -> Date {
    Date(timeIntervalSince1970: Double(state.endUtcMillis) / 1000.0)
}

@available(iOS 16.2, *)
private func duaURL(_ attributes: DuaLiveActivityAttributes) -> URL {
    URL(string: attributes.deepLink)
        ?? URL(string: "sakina://widget/build-dua?source=live_activity")!
}

// A warm gold + amber that read on the (tinted) Lock Screen / Dynamic Island.
@available(iOS 16.2, *)
private enum DuaLAPalette {
    static let gold = Color(red: 0.784, green: 0.596, blue: 0.369)   // #C8985E
    static let amber = Color(red: 0.910, green: 0.631, blue: 0.329)  // #E8A154
}

// MARK: - Lock-Screen / banner presentation

@available(iOS 16.2, *)
private struct DuaLiveActivityLockView: View {
    let context: ActivityViewContext<DuaLiveActivityAttributes>

    private var state: DuaLiveActivityAttributes.ContentState { context.state }
    private var isLastCall: Bool { state.urgency == "last_call" }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: DuaLiveCopy.glyph(urgency: state.urgency))
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                if state.isFinal {
                    // O3 grace: the window closed — the last glance still routes
                    // into Build-a-Duʿā.
                    Text("Build your duʿā")
                        .font(.headline).fontWeight(.semibold)
                    Text("The window has closed — carry it forward.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                } else {
                    Text(DuaLiveCopy.verb(urgency: state.urgency))
                        .font(.headline).fontWeight(.semibold)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    (Text(timerInterval: Date()...duaEndDate(state), countsDown: true)
                        + Text(" · \(DuaLiveCopy.closeLabel(context.attributes.windowType))"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - ActivityConfiguration (Lock Screen + Dynamic Island)

@available(iOS 16.2, *)
struct SakinaDuaTimesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DuaLiveActivityAttributes.self) { context in
            DuaLiveActivityLockView(context: context)
                .widgetURL(duaURL(context.attributes))
                .activityBackgroundTint(Color.black.opacity(0.35))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            let state = context.state
            let isLastCall = state.urgency == "last_call"
            let endDate = duaEndDate(state)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: DuaLiveCopy.glyph(urgency: state.urgency))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // دُعَاء — own RTL widget, never mixed with Latin (CLAUDE.md).
                    Text("دُعَاء")
                        .font(.system(size: 22, weight: .semibold))
                        .environment(\.layoutDirection, .rightToLeft)
                        .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(state.isFinal
                         ? "Build your duʿā"
                         : DuaLiveCopy.verb(urgency: state.urgency))
                        .font(.headline).fontWeight(.semibold)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if state.isFinal {
                            Text("The window has closed.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            (Text(timerInterval: Date()...endDate, countsDown: true)
                                + Text(" · \(DuaLiveCopy.closeLabel(context.attributes.windowType))"))
                                .font(.subheadline).foregroundStyle(.secondary)
                                .monospacedDigit().lineLimit(1)
                        }
                        Spacer()
                        Link(destination: duaURL(context.attributes)) {
                            Text("Build now →")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: DuaLiveCopy.glyph(urgency: state.urgency))
                    .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
            } compactTrailing: {
                if state.isFinal {
                    Image(systemName: "hands.sparkles.fill")
                        .foregroundStyle(DuaLAPalette.gold)
                } else {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .monospacedDigit()
                        .frame(maxWidth: 56)
                        .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
                }
            } minimal: {
                Image(systemName: DuaLiveCopy.glyph(urgency: state.urgency))
                    .foregroundStyle(isLastCall ? DuaLAPalette.amber : DuaLAPalette.gold)
            }
            .widgetURL(duaURL(context.attributes))
            .keylineTint(DuaLAPalette.gold)
        }
    }
}
