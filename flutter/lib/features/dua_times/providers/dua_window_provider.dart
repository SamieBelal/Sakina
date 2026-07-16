import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../services/dua_window_engine.dart';
import '../../../services/dua_window_repository.dart';
import '../../../services/location_service.dart';
import '../../../services/widget_data_service.dart';
import '../models/dua_window.dart';
import '../models/dua_window_schedule.dart';
import '../models/dua_window_type.dart';

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
  });

  final DuaWindowSchedule? schedule;
  final DateTime now;
  final bool building;

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
    bool clearSchedule = false,
  }) {
    return DuaWindowState(
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      now: now ?? this.now,
      building: building ?? this.building,
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
    bool observeLifecycle = true,
    bool autoBuild = true,
    bool startTicker = true,
  })  : _engine = engine,
        _location = locationService,
        _repository = repository,
        _clock = clock ?? DateTime.now,
        _resolveTimezone = resolveTimezone ?? _defaultResolveTimezone,
        _widgetData = widgetDataService,
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

  final DuaWindowEngine _engine;
  final LocationService _location;
  final DuaWindowRepository _repository;
  final DateTime Function() _clock;
  final Future<String> Function() _resolveTimezone;
  final WidgetDataService? _widgetData;
  final bool _observeLifecycle;

  Timer? _ticker;
  String? _lastBuiltYmd;
  bool _disposed = false;

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
    // Otherwise just advance the clock so the countdown label re-renders. Only
    // matters while a time-boxed window is active/closing.
    state = state.copyWith(now: now);
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
    // ensurePermission() is the only method that prompts (spec §15 lazy prompt).
    await _location.ensurePermission();
    final nowGranted = await _location.hasPermission();
    await rebuild(promptLocation: true);
    // Treat anything that isn't a positive grant as denied for analytics.
    return nowGranted
        ? LocationPromptOutcome.granted
        : LocationPromptOutcome.denied;
  }

  // ---------------------------------------------------------------------------
  // Build + push.
  // ---------------------------------------------------------------------------

  /// Rebuild the schedule from calendar + prayer times and push it to the
  /// widget. Safe to call repeatedly; degrades silently on any failure.
  Future<void> rebuild({bool promptLocation = false}) async {
    if (_disposed) return;
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
      state = state.copyWith(schedule: schedule, now: now, building: false);
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

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
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
