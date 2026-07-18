import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';

/// The platform-channel name the native iOS bridge (`LiveActivityBridge.swift`)
/// listens on. Kept in one place — the Swift side must use the identical string.
const String kDuaLiveActivityChannel = 'sakina/dua_live_activity';

/// The deep link every Live Activity glance + tap routes to (Build-a-Duʿā —
/// this feature's north star, plan §1). The `source=live_activity` param makes
/// LA taps distinguishable from home-widget taps in analytics (plan correction
/// #5 — the tap-through north-star metric is unmeasurable otherwise).
const String kDuaLiveActivityDeepLink =
    'sakina://widget/build-dua?source=live_activity';

/// The immutable content one Live Activity renders from — the Dart↔Swift wire
/// contract (plan §8 B1). Only these keys cross the channel; the Swift
/// `ActivityAttributes`/`ContentState` decode them and derive all copy from
/// [windowType] via the shared copy tables (`DuaWindowShared.swift`). A golden
/// map test pins the exact keys so a silent rename leaves the activity blank
/// (the same drift class hit on the notifications PR — plan hardening note).
@immutable
class DuaLiveActivityContent {
  const DuaLiveActivityContent({
    required this.windowType,
    required this.endUtcMillis,
    required this.urgency,
    required this.isAllDay,
    this.deepLink = kDuaLiveActivityDeepLink,
  });

  /// Build from the schedule's active window. Timing is the absolute UTC close
  /// instant the Swift `Text(timerInterval:)` counts down to.
  factory DuaLiveActivityContent.fromWindow(
    DuaWindow window,
    UrgencyState urgency,
  ) {
    return DuaLiveActivityContent(
      windowType: window.type.wireName,
      endUtcMillis: window.endUtc.millisecondsSinceEpoch,
      urgency: urgency.wireName,
      isAllDay: window.isAllDay,
    );
  }

  /// The wire string for the window kind (e.g. `last_third_of_night`) — drives
  /// all Swift-side copy. Matches [DuaWindowType.wireName].
  final String windowType;

  /// The window close instant (epoch millis) the ticking countdown targets.
  final int endUtcMillis;

  /// The escalation state wire string (`comfortable`|`closing`|`last_call`).
  /// v1 is a purely local activity, so this cannot self-escalate on a schedule;
  /// it is only refreshed when the app foregrounds and calls [update]/[sync].
  final String urgency;

  /// True for all-day windows — never ticks. v1 skips all-day windows entirely
  /// (plan O1), so this is effectively always false for a started activity;
  /// carried for contract completeness + the Swift stale-render guard.
  final bool isAllDay;

  /// The Build-a-Duʿā deep link (with the `live_activity` source tag).
  final String deepLink;

  /// Identifies the *window instance*. Two contents with the same key are the
  /// same active window (a start→update, not a replace).
  String get windowKey => '$windowType|$endUtcMillis';

  /// The perf-guard signature (plan §8 C2): identical signature ⇒ skip the
  /// native `update`, exactly like `WidgetDataService._lastDuaTimesWritten`.
  String get signature => '$windowType|$endUtcMillis|$urgency|$isAllDay';

  /// The flat map sent over the channel — the wire contract keys.
  Map<String, dynamic> toMap() => {
        'window_type': windowType,
        'end_utc_millis': endUtcMillis,
        'urgency': urgency,
        'is_all_day': isAllDay,
        'deep_link': deepLink,
      };
}

/// How a [DuaLiveActivityService.sync] call resolved — lets the provider emit
/// the right analytics (start/end) without duplicating the "what's live now"
/// bookkeeping the service already owns.
enum LiveActivityTransition {
  /// Nothing changed (unsupported OS, or same window + identical signature).
  none,

  /// A new activity was started (none was live before).
  started,

  /// The already-live activity for the same window was updated in place.
  updated,

  /// A live activity for a *different* window was ended and a new one started.
  replaced,
}

/// The outcome of a [DuaLiveActivityService.sync]. On [LiveActivityTransition
/// .replaced], [endedWindowType] carries the window that was torn down so the
/// provider can emit an `ended{reason: window_changed}` for it alongside the
/// `started` for the new one.
@immutable
class LiveActivitySyncResult {
  const LiveActivitySyncResult(this.transition, {this.endedWindowType});

  final LiveActivityTransition transition;
  final String? endedWindowType;

  bool get didStart =>
      transition == LiveActivityTransition.started ||
      transition == LiveActivityTransition.replaced;
}

/// Thin seam over the native ActivityKit `MethodChannel` so
/// [DuaLiveActivityService] is unit-testable without the platform channel —
/// mirrors `HomeWidgetClient` wrapping the `home_widget` plugin.
abstract class LiveActivityChannel {
  /// Whether Live Activities can run here (iOS ≥ 16.2 with the user's
  /// system-level toggle on). False off-iOS.
  Future<bool> isSupported();
  Future<void> start(Map<String, dynamic> content);
  Future<void> update(Map<String, dynamic> content);
  Future<void> end(Map<String, dynamic> args);
}

/// Default channel — delegates to the real `MethodChannel`. Off-iOS it
/// short-circuits `isSupported()` to false so no channel call is ever made on
/// Android/web (where the native handler doesn't exist).
class _MethodChannelLiveActivity implements LiveActivityChannel {
  const _MethodChannelLiveActivity();

  static const MethodChannel _channel = MethodChannel(kDuaLiveActivityChannel);

  bool get _isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isSupported() async {
    if (!_isIOS) return false;
    final ok = await _channel.invokeMethod<bool>('isSupported');
    return ok ?? false;
  }

  @override
  Future<void> start(Map<String, dynamic> content) =>
      _channel.invokeMethod<void>('start', content);

  @override
  Future<void> update(Map<String, dynamic> content) =>
      _channel.invokeMethod<void>('update', content);

  @override
  Future<void> end(Map<String, dynamic> args) =>
      _channel.invokeMethod<void>('end', args);
}

/// Single owner of the duʿā-times Live Activity lifecycle (Lock Screen +
/// Dynamic Island). The provider ([DuaWindowNotifier]) calls [sync] on every
/// rebuild (foreground / date-rollover / location change) right next to the
/// home-widget push, and [end] wherever the widget is cleared (sign-out /
/// account delete).
///
/// Design mirrors `WidgetDataService`:
/// - a channel abstraction (default = the real `MethodChannel`) for tests;
/// - a perf guard on a content signature — identical content ⇒ no repeat
///   native `update` (the provider rebuilds on every foreground; we must not
///   spam ActivityKit);
/// - every method swallows errors (never throws) — a Live Activity failure must
///   never break the in-app card, exactly like the best-effort widget push.
///
/// It also owns the "what window is live now" bookkeeping so [sync] is
/// idempotent (plan O4): re-syncing the same active window updates in place;
/// a different active window ends the old + starts the new; between windows,
/// [end] tears it down.
class DuaLiveActivityService {
  DuaLiveActivityService({LiveActivityChannel? channel})
      : _channel = channel ?? const _MethodChannelLiveActivity();

  final LiveActivityChannel _channel;

  /// The content of the currently-live activity, or null when none is live.
  DuaLiveActivityContent? _current;

  /// Cached support result — `isSupported()` is a fixed answer per launch
  /// (OS version + a system toggle that, if changed, restarts the app), so we
  /// resolve it once and reuse it to avoid a channel round-trip per rebuild.
  bool? _supported;

  /// The window type currently backed by a live activity, or null. Exposed for
  /// the provider's analytics + tests.
  String? get currentWindowType => _current?.windowType;

  Future<bool> isSupported() async {
    if (_supported != null) return _supported!;
    try {
      _supported = await _channel.isSupported();
    } catch (_) {
      _supported = false;
    }
    return _supported!;
  }

  /// Reconcile the live activity with [content] — the active time-boxed window.
  /// Idempotent: safe to call on every rebuild. Returns how it resolved so the
  /// caller can emit analytics. Never throws.
  Future<LiveActivitySyncResult> sync(DuaLiveActivityContent content) async {
    if (!await isSupported()) {
      return const LiveActivitySyncResult(LiveActivityTransition.none);
    }
    try {
      final current = _current;
      if (current == null) {
        await _channel.start(content.toMap());
        _current = content;
        return const LiveActivitySyncResult(LiveActivityTransition.started);
      }
      if (current.windowKey == content.windowKey) {
        // Same window — perf guard: only push an update if something changed.
        if (current.signature == content.signature) {
          return const LiveActivitySyncResult(LiveActivityTransition.none);
        }
        await _channel.update(content.toMap());
        _current = content;
        return const LiveActivitySyncResult(LiveActivityTransition.updated);
      }
      // Different window is active now — end the old (immediately, so it doesn't
      // linger in a grace state while the new one starts), then start the new.
      final endedType = current.windowType;
      await _channel.end(_endArgs(current, immediate: true));
      await _channel.start(content.toMap());
      _current = content;
      return LiveActivitySyncResult(
        LiveActivityTransition.replaced,
        endedWindowType: endedType,
      );
    } catch (e) {
      debugPrint('[DuaLiveActivityService] sync failed: $e');
      return const LiveActivitySyncResult(LiveActivityTransition.none);
    }
  }

  /// End the live activity. Returns the window type that was ended (for
  /// analytics), or null if nothing was live. Never throws.
  ///
  /// - [immediate] true dismisses the activity at once (sign-out / account-
  ///   delete — any residue on a shared device is a privacy concern); false
  ///   applies the O3 grace (flip to a static "Build your duʿā", then dismiss).
  /// - [force] true always dispatches a native **end-all** even when this
  ///   process has no [_current] — so an orphaned activity from a killed prior
  ///   session (whose id we lost on cold launch) is still torn down before the
  ///   next user. The routine window-closed path leaves [force] false so it
  ///   no-ops when nothing is live, avoiding a channel call on every
  ///   between-windows rebuild.
  Future<String?> end({bool immediate = false, bool force = false}) async {
    final current = _current;
    _current = null;
    if (current == null && !force) return null;
    if (!await isSupported()) return current?.windowType;
    try {
      final args = current != null
          ? _endArgs(current, immediate: immediate)
          : <String, dynamic>{
              'final_build_state': !immediate,
              'immediate': immediate,
            };
      await _channel.end(args);
    } catch (e) {
      debugPrint('[DuaLiveActivityService] end failed: $e');
    }
    return current?.windowType;
  }

  Map<String, dynamic> _endArgs(
    DuaLiveActivityContent content, {
    required bool immediate,
  }) =>
      {
        ...content.toMap(),
        // `final_build_state` renders the O3 static "Build your duʿā" state
        // before dismissing; skipped for an immediate (privacy) teardown.
        'final_build_state': !immediate,
        'immediate': immediate,
      };
}

/// Global instance, matching the codebase's `widgetDataService` pattern. The
/// provider uses it by default (injectable for tests); the sign-out / account-
/// delete wipe in `auth_service.dart` calls [DuaLiveActivityService.end] on it
/// right next to `widgetDataService.clearWidget()` so a second user on the
/// device never inherits a live activity carrying the first user's window.
final DuaLiveActivityService duaLiveActivityService = DuaLiveActivityService();
