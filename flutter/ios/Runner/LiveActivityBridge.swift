// Runner-side bridge that starts / updates / ends the duʿā-times Live Activity.
//
// ActivityKit's `Activity.request/.update/.end` run in the APP process (not the
// widget extension), so this lives in the Runner target and is driven from Dart
// over the `sakina/dua_live_activity` MethodChannel (mirrors the thin seam in
// lib/services/dua_live_activity_service.dart). See
// docs/superpowers/plans/2026-07-16-dua-live-activities.md §8 C1.
//
// CONCURRENCY: the start/update/end handlers run their ActivityKit work in a
// `Task` and only call the Flutter `result` AFTER it completes, so Dart's
// `await _channel.end(); await _channel.start()` genuinely serializes the native
// mutations (a false "await" — replying before the Task finished — let the
// replace path's end + start race). All mutable state (`currentActivityID`) is
// @MainActor-isolated, and the mutating methods are @MainActor, so there is no
// data race between the channel thread and the ActivityKit work.
//
// ⚠️ SETUP (manual, one-time): the Runner target is NOT a file-system-
// synchronized group, so this file must be added to the **Runner** target's
// "Compile Sources" in Xcode. DuaLiveActivityAttributes.swift must be a member
// of BOTH Runner and the extension (see SETUP.md §"Live Activity").

import ActivityKit
import Flutter
import Foundation

final class LiveActivityBridge {
    static let shared = LiveActivityBridge()

    private var channel: FlutterMethodChannel?

    /// The id of the activity we currently own. @MainActor-isolated so reads and
    /// writes are confined to the main actor (the mutating methods below hop to
    /// it), eliminating the channel-thread ↔ ActivityKit data race.
    @MainActor private var currentActivityID: String?

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
            if #available(iOS 16.2, *) {
                // Reply only AFTER the native work completes so Dart's await is
                // real ordering, not a dispatch acknowledgement.
                Task { await start(args); result(nil) }
            } else {
                result(nil)
            }
        case "update":
            if #available(iOS 16.2, *) {
                Task { await update(args); result(nil) }
            } else {
                result(nil)
            }
        case "end":
            if #available(iOS 16.2, *) {
                Task { await end(args); result(nil) }
            } else {
                result(nil)
            }
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

    // MARK: - ActivityKit (iOS 16.2+, main-actor isolated)

    @available(iOS 16.2, *)
    @MainActor
    private func start(_ args: [String: Any]) async {
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
        // Orphan reconciliation (correction #2): a Live Activity from a prior
        // session (app killed before `.end`) is unreachable via our in-memory id
        // on cold launch — end all existing ones before starting a fresh one so
        // we never double-render or hit the per-app activity limit.
        for activity in Activity<DuaLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        do {
            // staleDate = window close (correction #3): if anything drifts, the
            // activity flips to `.stale` at the boundary rather than showing a
            // window that already closed.
            let content = ActivityContent(state: state, staleDate: endDate)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil // purely local — ticks on-device, no server.
            )
            currentActivityID = activity.id
        } catch {
            // Includes ActivityAuthorizationError.visibility (a background start
            // attempt on iOS < 17.2) — benign, never crash.
            NSLog("[LiveActivityBridge] start failed: \(error)")
        }
    }

    @available(iOS 16.2, *)
    @MainActor
    private func update(_ args: [String: Any]) async {
        let endDate = Self.endDate(args)
        let state = DuaLiveActivityAttributes.ContentState(
            endUtcMillis: Self.int64(args["end_utc_millis"]),
            urgency: args["urgency"] as? String ?? "closing",
            isAllDay: args["is_all_day"] as? Bool ?? false
        )
        let activities = Activity<DuaLiveActivityAttributes>.activities
        // Prefer the activity we own; only fall back to the sole activity when
        // exactly one exists (never blind-update an arbitrary one).
        let target = activities.first { $0.id == currentActivityID }
            ?? (activities.count == 1 ? activities.first : nil)
        guard let activity = target else { return }
        await activity.update(ActivityContent(state: state, staleDate: endDate))
    }

    @available(iOS 16.2, *)
    @MainActor
    private func end(_ args: [String: Any]) async {
        // `immediate` (sign-out / account-delete): remove the activity at once —
        // any residue on a shared device is a privacy concern. Otherwise (a
        // window closing) keep the O3 grace: flip to a static "Build your duʿā"
        // and let it linger a short while so the last glance still routes in.
        let immediate = args["immediate"] as? Bool ?? false
        let showBuildFinal = args["final_build_state"] as? Bool ?? false
        let finalState = DuaLiveActivityAttributes.ContentState(
            endUtcMillis: Self.int64(args["end_utc_millis"]),
            urgency: args["urgency"] as? String ?? "closing",
            isAllDay: args["is_all_day"] as? Bool ?? false,
            isFinal: showBuildFinal
        )
        let policy: ActivityUIDismissalPolicy =
            immediate ? .immediate : .after(Date().addingTimeInterval(120))
        // End ALL activities (orphan-safe): covers the one we own plus any stray
        // from a killed prior session, so sign-out never leaves a residue.
        for activity in Activity<DuaLiveActivityAttributes>.activities {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: policy
            )
        }
        currentActivityID = nil
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
