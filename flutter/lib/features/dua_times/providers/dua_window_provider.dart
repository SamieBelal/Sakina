import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
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
    Future<SharedPreferences> Function()? prefs,
    bool observeLifecycle = true,
    bool autoBuild = true,
    bool startTicker = true,
  })  : _engine = engine,
        _location = locationService,
        _repository = repository,
        _clock = clock ?? DateTime.now,
        _resolveTimezone = resolveTimezone ?? _defaultResolveTimezone,
        _widgetData = widgetDataService,
        _prefs = prefs ?? SharedPreferences.getInstance,
        _observeLifecycle = observeLifecycle,
        super(DuaWindowState(now: (clock ?? DateTime.now)())) {
    if (_observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    if (startTicker) _startTicker();
    // Kick the first build; the card renders the empty case until it lands.
    if (autoBuild) unawaited(rebuild());
  }

  /// Seed a schedule directly (widget tests) without running the async engine.
  @visibleForTesting
  void debugSetSchedule(DuaWindowSchedule schedule, {DateTime? now}) {
    _lastBuiltYmd = _ymd(now ?? _clock());
    state = state.copyWith(schedule: schedule, now: now ?? _clock());
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
    unawaited(_pushToWidget(schedule));
  }

  /// Exit preview mode and rebuild the real schedule.
  void debugUnfreeze() {
    _debugFrozen = false;
    unawaited(rebuild());
  }

  final DuaWindowEngine _engine;
  final LocationService _location;
  final DuaWindowRepository _repository;
  final DateTime Function() _clock;
  final Future<String> Function() _resolveTimezone;
  final WidgetDataService? _widgetData;
  final Future<SharedPreferences> Function() _prefs;
  final bool _observeLifecycle;

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

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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
    // Otherwise only advance the clock when a LIVE per-second countdown is
    // actually on screen — an active, non-all-day window in the closing or
    // last-call urgency band. For comfortable / all-day / between / upcoming
    // states the label doesn't change per second, so publishing `now` every
    // tick would rebuild the card at 1Hz for nothing.
    if (_hasLiveCountdown) {
      state = state.copyWith(now: now);
    }
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
      await _pushToWidget(schedule);
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
  );
});
