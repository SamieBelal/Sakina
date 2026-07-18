import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/features/dua_times/providers/dua_notification_scheduler_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_live_activity_service.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/widget_data_service.dart';

/// The observable state the duʿā-times card renders from.
///
/// [schedule] is the last-built schedule (null until the first build completes,
/// which resolves to the render-gated empty case). [now] is the ticking clock
/// the card uses to drive the live countdown WITHOUT rebuilding the whole
/// schedule every second — only the label depends on it (spec §8, keep the
/// Timer cheap). [locationPermissionResolved] records the outcome of the most
/// recent lazy prompt so the card can fire the granted/denied analytics once.
@immutable
class DuaWindowState {
  const DuaWindowState({
    this.schedule,
    required this.now,
    this.building = false,
    this.preciseBannerSnoozed = false,
  });

  final DuaWindowSchedule? schedule;
  final DateTime now;
  final bool building;

  /// True when the user dismissed the "Turn on precise times" banner and the
  /// 7-day snooze window is still active — the card hides the banner until then.
  final bool preciseBannerSnoozed;

  DuaWindow? get active => schedule?.active;
  DuaWindow? get next => schedule?.next;
  UrgencyState get urgency => schedule?.urgency ?? UrgencyState.upcoming;

  /// True when there's something worth rendering: an active window OR an
  /// imminent next window (mirrors the render-gate in the card). A schedule
  /// with neither collapses the card to `SizedBox.shrink()` (spec §8/§10).
  bool get hasRenderableWindow => active != null || next != null;

  DuaWindowState copyWith({
    DuaWindowSchedule? schedule,
    DateTime? now,
    bool? building,
    bool? preciseBannerSnoozed,
    bool clearSchedule = false,
  }) {
    return DuaWindowState(
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      now: now ?? this.now,
      building: building ?? this.building,
      preciseBannerSnoozed: preciseBannerSnoozed ?? this.preciseBannerSnoozed,
    );
  }
}

/// The outcome of a lazy location prompt, surfaced so the card fires the
/// `dua_times_location_granted` / `_denied` analytics exactly once.
enum LocationPromptOutcome { granted, denied }

/// Drives the in-app duʿā-times card (spec §7/§8).
///
/// Responsibilities:
/// - Resolve the IANA timezone via [FlutterTimezone] and pass it to the engine
///   as `tzName` (stamped for the widget's travel guard).
/// - Refresh the seeded calendar from remote, then build a [DuaWindowSchedule]
///   via [DuaWindowEngine].
/// - Push the schedule to the native widget via `WidgetDataService.instance
///   .saveDuaTimesSchedule(jsonEncode(schedule.toJson()))` on every rebuild.
/// - Tick a 1-second [Timer] so the card's live countdown updates without
///   rebuilding the schedule.
/// - Recompute on app-foreground, date-rollover, and location change.
///
/// Analytics for the location prompt outcome is surfaced via [promptLocation]'s
/// return value (emitted from the card, which has Riverpod `ref` — no static
/// hook needed here since this notifier IS Riverpod-native).
class DuaWindowNotifier extends StateNotifier<DuaWindowState>
    with WidgetsBindingObserver {
  DuaWindowNotifier({
    required DuaWindowEngine engine,
    required LocationService locationService,
    required DuaWindowRepository repository,
    DateTime Function()? clock,
    Future<String> Function()? resolveTimezone,
    WidgetDataService? widgetDataService,
    DuaLiveActivityService? liveActivityService,
    Future<SharedPreferences> Function()? prefs,
    void Function(DuaWindowSchedule schedule)? onScheduleBuilt,
    bool observeLifecycle = true,
    bool autoBuild = true,
    bool startTicker = true,
  })  : _engine = engine,
        _location = locationService,
        _repository = repository,
        _clock = clock ?? DateTime.now,
        _resolveTimezone = resolveTimezone ?? _defaultResolveTimezone,
        _widgetData = widgetDataService,
        _liveActivity = liveActivityService,
        _prefs = prefs ?? SharedPreferences.getInstance,
        _onScheduleBuilt = onScheduleBuilt,
        _observeLifecycle = observeLifecycle,
        _tickerEnabled = startTicker,
        super(DuaWindowState(now: (clock ?? DateTime.now)())) {
    if (_observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    // NOTE: the ticker is LAZY — it is NOT started here. `_syncTicker()` starts
    // it only once a rebuild produces a live per-second countdown, and cancels
    // it otherwise. Starting a perpetual `Timer.periodic` in the constructor
    // leaked a pending timer into every full-app widget test that renders this
    // card without an active window (tripped `!timersPending`), and burned a
    // 1Hz timer for nothing the ~99% of the day there's no live countdown.
    // Kick the first build; the card renders the empty case until it lands.
    if (autoBuild) unawaited(rebuild());
  }

  /// Seed a schedule directly (widget tests) without running the async engine.
  @visibleForTesting
  void debugSetSchedule(DuaWindowSchedule schedule, {DateTime? now}) {
    _lastBuiltYmd = _ymd(now ?? _clock());
    state = state.copyWith(schedule: schedule, now: now ?? _clock());
    _syncTicker();
  }

  /// Dev/QA only: freeze the card + widget on a synthetic [schedule] so a
  /// reviewer can SEE each state (Friday hour, last-call, ʿArafah…) without
  /// waiting for the real day. Suppresses real rebuilds until [debugUnfreeze],
  /// and pushes the schedule to the native widget too. Release-stripped (only
  /// reachable from Dev Tools). Instants are relative to now so countdowns tick.
  void debugPreview(DuaWindowSchedule schedule) {
    _debugFrozen = true;
    _lastBuiltYmd = _ymd(_clock());
    state = state.copyWith(schedule: schedule, now: _clock());
    _syncTicker();
    unawaited(_pushToWidget(schedule));
    unawaited(_syncLiveActivity(schedule));
  }

  /// Exit preview mode and rebuild the real schedule.
  void debugUnfreeze() {
    _debugFrozen = false;
    unawaited(rebuild());
  }

  /// Static analytics hook (mirrors [DuasNotifier.onAnalyticsEvent]). Wired in
  /// `main.dart` to `analytics.track`; left null in tests. Bridges the Live
  /// Activity start/end telemetry without giving this notifier an analytics
  /// dependency (the codebase's "no Riverpod/analytics in the notifier" rule).
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  final DuaWindowEngine _engine;
  final LocationService _location;
  final DuaWindowRepository _repository;
  final DateTime Function() _clock;
  final Future<String> Function() _resolveTimezone;
  final WidgetDataService? _widgetData;
  final DuaLiveActivityService? _liveActivity;
  final Future<SharedPreferences> Function() _prefs;

  /// Fired after every successful [rebuild] with the freshly-built schedule.
  /// The provider wires this to the duʿā calendar-notification scheduler so the
  /// local reminders are recomputed on the same triggers the card rebuilds on
  /// (foreground-resume, date-rollover, location change). Kept as a plain
  /// callback so this notifier stays free of the notification/service layer —
  /// the DI + opt-in gating lives in the provider (mirrors `_pushToWidget`).
  final void Function(DuaWindowSchedule schedule)? _onScheduleBuilt;

  final bool _observeLifecycle;

  /// Whether the per-second countdown ticker is allowed to run at all. Tests
  /// pass `startTicker: false` to keep a deterministic, timer-free notifier.
  final bool _tickerEnabled;

  /// SharedPreferences key holding the epoch-ms until which the precise-times
  /// banner is snoozed (set when the user taps its ✕).
  static const String _bannerSnoozeKey =
      'dua_times_precise_banner_snoozed_until';

  /// How long a single ✕ dismiss hides the banner before it resurfaces.
  static const Duration _bannerSnoozeDuration = Duration(days: 7);

  Timer? _ticker;
  String? _lastBuiltYmd;
  bool _disposed = false;

  /// When true, real rebuilds are suppressed and the card/widget stay on a
  /// synthetic Dev-Tools preview schedule (see [debugPreview]). The ticker still
  /// advances `now`, so the live countdown keeps ticking.
  bool _debugFrozen = false;

  static Future<String> _defaultResolveTimezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return 'local';
    }
  }

  /// The card reads this to gate the "Enable precise times" affordance: true
  /// when the schedule has no location stamp (calendar-only / degraded).
  bool get hasPreciseLocation => state.schedule?.computedAt.lat != null;

  // ---------------------------------------------------------------------------
  // Ticking clock — drives the live countdown only (cheap).
  // ---------------------------------------------------------------------------

  /// Start or stop the 1Hz ticker to match demand. The ticker runs ONLY while a
  /// live per-second countdown is on screen (an active window in the closing /
  /// last-call band); otherwise it is cancelled. Called after every state change
  /// (rebuild / tick / preview) so the timer's lifetime is tied to actual need —
  /// which both fixes the `!timersPending` leak in full-app tests and avoids a
  /// perpetual 1Hz timer the ~99% of the day there is nothing to count down.
  void _syncTicker() {
    if (!_tickerEnabled || _disposed || !_hasLiveCountdown) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_disposed) return;
    final now = _clock();
    // Date rollover (local day changed) → rebuild the schedule so a new day's
    // windows appear and stale ones drop (spec §7 date-rollover trigger).
    final ymd = _ymd(now);
    if (_lastBuiltYmd != null && ymd != _lastBuiltYmd) {
      unawaited(rebuild());
      return;
    }
    // Advance the clock so the live countdown label updates. `_syncTicker` only
    // keeps us ticking while `_hasLiveCountdown` holds, so this publish is never
    // wasted; once the window leaves the live band (or ends), re-sync stops us.
    if (_hasLiveCountdown) {
      state = state.copyWith(now: now);
    }
    _syncTicker();
  }

  /// True when the card is showing a ticking per-second countdown: an active,
  /// non-all-day window whose urgency is [UrgencyState.closing] or
  /// [UrgencyState.lastCall]. (all-day windows never tick; comfortable is a
  /// static > 1h deadline; upcoming/between counts down to a far next window.)
  bool get _hasLiveCountdown {
    final active = state.active;
    if (active == null) return false;
    final u = state.urgency;
    return u == UrgencyState.closing || u == UrgencyState.lastCall;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle — recompute on foreground (spec §7 foreground trigger).
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(rebuild());
    }
  }

  // ---------------------------------------------------------------------------
  // Location — lazy prompt (spec §15). Returns the outcome for analytics.
  // ---------------------------------------------------------------------------

  /// Lazily request location permission, then rebuild if it changed things.
  /// Returns whether permission ended up granted so the card can emit the
  /// matching analytics event. Never throws.
  Future<LocationPromptOutcome> promptLocation() async {
    if (await _location.hasPermission()) {
      // Already granted — a rebuild (with a fresh fix) is enough.
      await rebuild(promptLocation: true);
      return LocationPromptOutcome.granted;
    }
    // Prompt if askable; if permanently denied ("Never"), route to Settings so
    // the tap is never a dead end (the grant is picked up on foreground).
    final granted = await _location.ensureOrOpenSettings();
    await rebuild(promptLocation: true);
    return granted
        ? LocationPromptOutcome.granted
        : LocationPromptOutcome.denied;
  }

  /// Dismiss the "Turn on precise times" banner for [_bannerSnoozeDuration].
  /// Persisted so it survives relaunch; the banner resurfaces after the window
  /// (location is pivotal, so we snooze rather than permanently hide it).
  Future<void> snoozePreciseBanner() async {
    final until = _clock().add(_bannerSnoozeDuration);
    try {
      final p = await _prefs();
      await p.setInt(_bannerSnoozeKey, until.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[DuaWindowNotifier] snooze persist failed: $e');
    }
    if (_disposed) return;
    state = state.copyWith(preciseBannerSnoozed: true);
  }

  Future<bool> _isBannerSnoozed(DateTime now) async {
    try {
      final p = await _prefs();
      final untilMs = p.getInt(_bannerSnoozeKey);
      if (untilMs == null) return false;
      return now.millisecondsSinceEpoch < untilMs;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Build + push.
  // ---------------------------------------------------------------------------

  /// Rebuild the schedule from calendar + prayer times and push it to the
  /// widget. Safe to call repeatedly; degrades silently on any failure.
  Future<void> rebuild({bool promptLocation = false}) async {
    if (_disposed || _debugFrozen) return;
    state = state.copyWith(building: true, now: _clock());
    try {
      // Refresh the seeded calendar cache before building (spec §7 foreground
      // refresh). Degrades to cache/bundled asset internally.
      await _repository.refreshFromRemote();

      final now = _clock();
      final tzName = await _resolveTimezone();
      final schedule = await _engine.buildSchedule(
        now: now,
        tzName: tzName,
        promptLocation: promptLocation,
      );
      if (_disposed) return;
      _lastBuiltYmd = _ymd(now);
      state = state.copyWith(
        schedule: schedule,
        now: now,
        building: false,
        preciseBannerSnoozed: await _isBannerSnoozed(now),
      );
      _syncTicker();
      await _pushToWidget(schedule);
      // Promote the active time-boxed window to a Lock-Screen / Dynamic Island
      // Live Activity (best-effort, no-ops off-iOS). This IS the foreground
      // moment iOS < 17.2 requires to start one (plan §4) — `rebuild` runs on
      // `resumed`. Right next to the widget push so the two surfaces stay in
      // lockstep.
      await _syncLiveActivity(schedule);
      // Recompute the local calendar-notification schedule on the same triggers
      // the card rebuilds on. Best-effort: the callback itself never throws (the
      // scheduler degrades silently), but guard anyway so a hook failure can't
      // break the card.
      try {
        _onScheduleBuilt?.call(schedule);
      } catch (e) {
        debugPrint('[DuaWindowNotifier] onScheduleBuilt failed: $e');
      }
    } catch (e) {
      if (_disposed) return;
      debugPrint('[DuaWindowNotifier] rebuild failed: $e');
      state = state.copyWith(building: false);
    }
  }

  /// Push the schedule JSON to the native widget (shared contract, spec §7).
  ///
  /// Calls `WidgetDataService.saveDuaTimesSchedule(jsonEncode(schedule.toJson()))`
  /// — the exact signature owned by the widget-data wave. The task brief named
  /// the accessor `WidgetDataService.instance`; the merged codebase exposes the
  /// singleton as the top-level `widgetDataService` (matching the
  /// `supabaseSyncService` convention), so we bind to that. See the report seam.
  Future<void> _pushToWidget(DuaWindowSchedule schedule) async {
    try {
      final json = jsonEncode(schedule.toJson());
      final service = _widgetData ?? widgetDataService;
      await service.saveDuaTimesSchedule(json);
    } catch (e) {
      // Widget push is best-effort — never break the card on a widget failure.
      debugPrint('[DuaWindowNotifier] _pushToWidget failed: $e');
    }
  }

  /// Reconcile the Live Activity with the freshly-built [schedule] (plan §8 D2).
  ///
  /// - An active, **time-boxed** window (not all-day — plan O1/O2) → start (or
  ///   update / replace) the ticking countdown activity.
  /// - No active time-boxed window (between windows, or an all-day window is
  ///   active) → end any live activity.
  ///
  /// Emits `dua_live_activity_started` / `_ended` via [onAnalyticsEvent] on
  /// genuine transitions. Best-effort: the service never throws, but guard
  /// anyway so a Live-Activity failure can't break the card (like the widget
  /// push above).
  Future<void> _syncLiveActivity(DuaWindowSchedule schedule) async {
    final service = _liveActivity ?? duaLiveActivityService;
    try {
      final active = schedule.active;
      // O1/O2: only time-boxed windows get a Live Activity — an all-day window
      // has no countdown, so it would burn the single LA slot with static copy.
      final isTimeBoxed = active != null && !active.isAllDay;
      if (isTimeBoxed) {
        final content = DuaLiveActivityContent.fromWindow(
          active,
          schedule.urgency,
        );
        final result = await service.sync(content);
        // A replace ends the previous window before starting the new one.
        if (result.endedWindowType != null) {
          _emitLiveActivity(
            AnalyticsEvents.duaLiveActivityEnded,
            activeWindow: result.endedWindowType,
            reason: AnalyticsEvents.liveActivityEndWindowChanged,
          );
        }
        if (result.didStart) {
          _emitLiveActivity(
            AnalyticsEvents.duaLiveActivityStarted,
            activeWindow: content.windowType,
            urgency: content.urgency,
          );
        }
      } else {
        final endedType = await service.end();
        if (endedType != null) {
          _emitLiveActivity(
            AnalyticsEvents.duaLiveActivityEnded,
            activeWindow: endedType,
            reason: AnalyticsEvents.liveActivityEndWindowClosed,
          );
        }
      }
    } catch (e) {
      debugPrint('[DuaWindowNotifier] _syncLiveActivity failed: $e');
    }
  }

  void _emitLiveActivity(
    String event, {
    String? activeWindow,
    String? urgency,
    String? reason,
  }) {
    final props = <String, dynamic>{};
    if (activeWindow != null) props[AnalyticsEvents.propActiveWindow] = activeWindow;
    if (urgency != null) props[AnalyticsEvents.propUrgency] = urgency;
    if (reason != null) props[AnalyticsEvents.propReason] = reason;
    onAnalyticsEvent?.call(event, props);
  }

  static String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    if (_observeLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}

/// The card's provider. Constructed with the production engine/services; tests
/// override this with a notifier built from fakes + a fixed clock.
final duaWindowProvider =
    StateNotifierProvider<DuaWindowNotifier, DuaWindowState>((ref) {
  final repository = DuaWindowRepository();
  final locationService = LocationService();
  final engine = DuaWindowEngine(
    repository: repository,
    locationService: locationService,
  );
  return DuaWindowNotifier(
    engine: engine,
    locationService: locationService,
    repository: repository,
    // Recompute the local duʿā calendar reminders whenever the schedule is
    // rebuilt (foreground-resume / date-rollover / location change). The gate
    // enforces the opt-in + `notify_dua_windows` pref; it's null (no-op) when
    // the notifications plugin isn't wired (web / tests). Fire-and-forget so the
    // card never waits on the OS scheduler.
    onScheduleBuilt: (schedule) {
      final gate = ref.read(duaNotificationGateProvider);
      if (gate == null) return;
      unawaited(gate.apply(schedule));
    },
  );
});
