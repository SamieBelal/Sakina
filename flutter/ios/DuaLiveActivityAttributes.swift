// SHARED ActivityKit attributes for the duʿā-times Live Activity.
//
// ⚠️ This file must be a member of BOTH targets:
//   • Runner                 (LiveActivityBridge.swift requests/updates/ends it)
//   • SakinaWidgetExtension   (DuaLiveActivity.swift renders it)
// ActivityKit matches the `ActivityConfiguration` to a running `Activity` by the
// attributes TYPE, so the app and the extension must compile the *same* source.
// It lives OUTSIDE the `ios/SakinaWidget/` file-system-synchronized group (which
// only feeds the extension) precisely so it can also be added to Runner. In
// Xcode: select this file → File Inspector → Target Membership → tick BOTH
// "Runner" and "SakinaWidgetExtension". See
// docs/superpowers/plans/2026-07-16-dua-live-activities.md §8.
//
// The keys mirror the flat map `DuaLiveActivityService.toMap()` sends from Dart
// (a golden test pins them). `@available(iOS 16.2, *)` on the type (plan
// correction #1) so both targets compile below the ActivityKit floor.

import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct DuaLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// The window close instant (epoch millis) the countdown targets.
        var endUtcMillis: Int64
        /// Escalation wire string: `comfortable` | `closing` | `last_call`.
        var urgency: String
        /// True for all-day windows (v1 never starts these — carried for the
        /// stale-render guard so a drifted all-day activity never ticks).
        var isAllDay: Bool
        /// O3 grace state: when true the activity renders a static
        /// "Build your duʿā" (no timer) just before it dismisses.
        var isFinal: Bool = false
    }

    /// Window kind wire string (e.g. `last_third_of_night`) — drives copy.
    var windowType: String
    /// The Build-a-Duʿā deep link (carries `?source=live_activity`).
    var deepLink: String
}
