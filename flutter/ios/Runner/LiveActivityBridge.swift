// Runner-side bridge that starts / updates / ends the duʿā-times Live Activity.
//
// ActivityKit's `Activity.request/.update/.end` run in the APP process (not the
// widget extension), so this lives in the Runner target and is driven from Dart
// over the `sakina/dua_live_activity` MethodChannel (mirrors the thin seam in
// lib/services/dua_live_activity_service.dart). See
// docs/superpowers/plans/2026-07-16-dua-live-activities.md §8 C1.
//
// ⚠️ SETUP (manual, one-time): the Runner target is NOT a file-system-
// synchronized group, so this file must be added to the **Runner** target's
// "Compile Sources" in Xcode (unlike the ios/SakinaWidget/ files). The
// DuaLiveActivityAttributes type is shared source — add DuaLiveActivity.swift to
// the Runner target's membership TOO (it is already in the extension target), so
// both processes compile the same ActivityAttributes. (Attributes must be
// identical in both the app and the extension.)

import ActivityKit
import Flutter
import Foundation

final class LiveActivityBridge {
    static let shared = LiveActivityBridge()

    private var channel: FlutterMethodChannel?

    /// The id of the activity we currently own. We also enumerate
    /// `Activity.activities` on every mutation so an orphan from a killed prior
    /// session (correction #2) is reconciled even when this is nil on cold launch.
    private var currentActivityID: String?

    /// Register the channel. Called from `AppDelegate` with the messenger drawn
    /// from the plugin registrar (plan correction #4 — the implicit-engine bridge
    /// has no binary messenger of its own).
    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "sakina/dua_live_activity",
            binaryMessenger: messenger
        )
        shared.channel = channel
        channel.setMethodCallHandler { call, result in
            shared.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "isSupported":
            result(isSupported())
        case "start":
            if #available(iOS 16.2, *) { start(args) }
            result(nil)
        case "update":
            if #available(iOS 16.2, *) { update(args) }
            result(nil)
        case "end":
            if #available(iOS 16.2, *) { end(args) }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func isSupported() -> Bool {
        if #available(iOS 16.2, *) {
            // False when the user disabled Live Activities in Settings — the
            // home widget + in-app card still cover them, so Dart no-ops.
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }

    // MARK: - ActivityKit (iOS 16.2+)

    @available(iOS 16.2, *)
    private func start(_ args: [String: Any]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DuaLiveActivityAttributes(
            windowType: args["window_type"] as? String ?? "",
            deepLink: args["deep_link"] as? String
                ?? "sakina://widget/build-dua?source=live_activity"
        )
        let endDate = Self.endDate(args)
        let state = DuaLiveActivityAttributes.ContentState(
            endUtcMillis: Self.int64(args["end_utc_millis"]),
            urgency: args["urgency"] as? String ?? "closing",
            isAllDay: args["is_all_day"] as? Bool ?? false
        )
        Task {
            // Orphan reconciliation (correction #2): a Live Activity from a prior
            // session (app killed before `.end`) is unreachable via our in-memory
            // id on cold launch — end all existing ones before starting a fresh
            // one so we never double-render or hit the per-app activity limit.
            for activity in Activity<DuaLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            do {
                // staleDate = window close (correction #3): if anything drifts,
                // the activity flips to `.stale` at the boundary rather than
                // showing a window that already closed.
                let content = ActivityContent(state: state, staleDate: endDate)
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil // purely local — ticks on-device, no server.
                )
                await MainActor.run { self.currentActivityID = activity.id }
            } catch {
                // Includes ActivityAuthorizationError.visibility (a background
                // start attempt on iOS < 17.2) — benign, never crash.
                NSLog("[LiveActivityBridge] start failed: \(error)")
            }
        }
    }

    @available(iOS 16.2, *)
    private func update(_ args: [String: Any]) {
        let endDate = Self.endDate(args)
        let state = DuaLiveActivityAttributes.ContentState(
            endUtcMillis: Self.int64(args["end_utc_millis"]),
            urgency: args["urgency"] as? String ?? "closing",
            isAllDay: args["is_all_day"] as? Bool ?? false
        )
        let id = currentActivityID
        Task {
            let activities = Activity<DuaLiveActivityAttributes>.activities
            let target = activities.first { $0.id == id } ?? activities.first
            guard let activity = target else { return }
            await activity.update(ActivityContent(state: state, staleDate: endDate))
        }
    }

    @available(iOS 16.2, *)
    private func end(_ args: [String: Any]) {
        let showBuildFinal = args["final_build_state"] as? Bool ?? false
        let finalState = DuaLiveActivityAttributes.ContentState(
            endUtcMillis: Self.int64(args["end_utc_millis"]),
            urgency: args["urgency"] as? String ?? "closing",
            isAllDay: args["is_all_day"] as? Bool ?? false,
            isFinal: showBuildFinal
        )
        Task {
            // O3: flip to a static "Build your duʿā" final state and let it
            // linger a short grace before the system removes it, so the last
            // glance still routes into Build-a-Duʿā. End any strays too.
            for activity in Activity<DuaLiveActivityAttributes>.activities {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .after(Date().addingTimeInterval(120))
                )
            }
            await MainActor.run { self.currentActivityID = nil }
        }
    }

    // MARK: - Arg helpers

    /// MethodChannel numbers arrive as `Int` or `NSNumber` depending on size.
    private static func int64(_ value: Any?) -> Int64 {
        if let n = value as? NSNumber { return n.int64Value }
        if let i = value as? Int { return Int64(i) }
        return 0
    }

    private static func endDate(_ args: [String: Any]) -> Date {
        Date(timeIntervalSince1970: Double(int64(args["end_utc_millis"])) / 1000.0)
    }
}
