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
import 'package:sakina/features/dua_times/widgets/precise_paused_notice.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_live_activity_service.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
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
    this.preciseState = PreciseTimesState.neverAsked,
  });

  final DuaWindowSchedule? schedule;
  final DateTime now;
  final bool building;

  /// True when the user dismissed the "Turn on precise times" banner and the
  /// 7-day snooze window is still active — the card hides the banner until then.
  final bool preciseBannerSnoozed;

  /// What the card should say about precise times (see [PreciseTimesState]).
  final PreciseTimesState preciseState;

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
    PreciseTimesState? preciseState,
    bool clearSchedule = false,
  }) {
    return DuaWindowState(
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      now: now ?? this.now,
      building: building ?? this.building,
      preciseBannerSnoozed: preciseBannerSnoozed ?? this.preciseBannerSnoozed,
      preciseState: preciseState ?? this.preciseState,
    );
  }
}

/// The outcome of a lazy location prompt, surfaced so the card fires the
/// matching analytics exactly once.
///
/// [openedSettings] and [servicesOff] exist because reporting them as [denied]
/// was a lie: the user denied nothing in either case, and many grant seconds
/// later in Settings. That mis-report is why the granted/denied ratio was
/// untrustworthy before 2026-08.
enum LocationPromptOutcome { granted, denied, openedSettings, servicesOff }

/// What the card should say about precise times.
///
/// Resolved from one **durable** fact (we asked this user at least once) and one
/// **live** fact (what the OS says now). The durable fact never claims the
/// feature works — it only selects which copy a non-working user sees.
enum PreciseTimesState {
  /// A location is in hand. The feature works; say nothing.
  working,

  /// We have never asked. The only state that earns the full pitch.
  neverAsked,

  /// Asked and granted at some point, but the OS grant is gone — the iOS
  /// "Allow Once" case, or a later revoke.
  permissionLapsed,

  /// Asked, and the OS has never once said yes. Asked-and-answered: the card
  /// says nothing at all, and Settings is the way back. Kept distinct from
  /// [permissionLapsed] so the "iOS reset your access" copy is never shown to
  /// someone who simply declined, and so the Allow-Once cohort measured by
  /// `dua_times_precise_state{permission_lapsed}` is not inflated by denials.
  declined,

  /// App permission is fine; the device's Location Services are off.
  servicesOff,

  /// Everything is granted and no fix has landed yet. Transient by definition —
  /// renders nothing, exists only so analytics can tell it apart from a lapse.
  unresolved,
}

extension PreciseTimesStateX on PreciseTimesState {
  /// Stable snake_case analytics value. Kept beside the enum so the two cannot
  /// drift (mirrors `DuaWindowType.wireName`).
  String get wireName => switch (this) {
        PreciseTimesState.working => 'working',
        PreciseTimesState.neverAsked => 'never_asked',
        PreciseTimesState.permissionLapsed => 'permission_lapsed',
        PreciseTimesState.declined => 'declined',
        PreciseTimesState.servicesOff => 'services_off',
        PreciseTimesState.unresolved => 'unresolved',
      };
}

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
    String? Function()? userId,
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
        _userId = userId ?? _defaultUserId,
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
  ///
  /// [preciseState] defaults to the value the resolver would produce from the
  /// schedule alone, so existing tests keep their exact behaviour.
  @visibleForTesting
  void debugSetSchedule(
    DuaWindowSchedule schedule, {
    DateTime? now,
    PreciseTimesState? preciseState,
  }) {
    _lastBuiltYmd = _ymd(now ?? _clock());
    state = state.copyWith(
      schedule: schedule,
      now: now ?? _clock(),
      preciseState: preciseState ??
          (schedule.computedAt.lat != null
              ? PreciseTimesState.working
              : PreciseTimesState.neverAsked),
    );
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
  final String? Function() _userId;

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

  /// Epoch-ms of the FIRST "Turn on precise times" tap. Written *before* the OS
  /// dialog is shown — this single key is what ends the recurring nag, and
  /// writing it early is the only version that survives the app being killed
  /// while the user is away in Settings.
  static const String preciseOptInBaseKey = 'dua_times_precise_opt_in_at';

  /// Epoch-ms of the first time we OBSERVED a real grant. Distinguishes
  /// "asked and never granted" from "granted, then it lapsed" for analytics.
  static const String preciseGrantedBaseKey = 'dua_times_precise_granted_at';

  /// Progress of the lapse notice for one episode, as `<wire_name>|<n>` while
  /// it is still being shown and `<wire_name>|ack` once the user has actually
  /// dealt with it (tapped it or dismissed it with the ✕).
  ///
  /// A bare `<wire_name>` with no suffix is the pre-✕ format, where merely
  /// *rendering* the notice spent it. Those users already saw their one notice,
  /// so it is read as `ack` — an upgrade must not re-open a closed episode.
  static const String preciseNoticeShownBaseKey =
      'dua_times_precise_notice_state';

  /// How many opens one lapse episode may surface its notice for if the user
  /// never engages with it.
  ///
  /// The notice no longer auto-fades (founder decision 2026-08-03: a 6s fade on
  /// a screen the user may not be looking at spends the notice on nobody, which
  /// is how a tester hunting for it still missed it). Persisting until dismissed
  /// is what makes it reliably seen — but "until dismissed" with no bound is a
  /// permanent resident, which is the original bug. Three opens, then Settings
  /// holds the state alone.
  static const int lapseNoticeMaxShows = 3;

  Timer? _ticker;
  String? _lastBuiltYmd;
  bool _disposed = false;

  /// The shape signature of the last schedule we emitted `dua_schedule_built`
  /// for. rebuild() runs on EVERY `resumed` (incl. transient Control-Center /
  /// notification-shade bounces), so an unconditional emit would both flood
  /// Mixpanel and bias the eligibility denominator toward fidgety users. We only
  /// emit when the schedule's shape actually changes — so a user still gets one
  /// event per distinct eligibility state, not one per app-glance.
  String? _lastScheduleBuiltSignature;

  /// Dedup signature for `dua_times_precise_state` (see [_emitPreciseState]).
  String? _lastPreciseStateSignature;

  /// When true, real rebuilds are suppressed and the card/widget stay on a
  /// synthetic Dev-Tools preview schedule (see [debugPreview]). The ticker still
  /// advances `now`, so the live countdown keeps ticking.
  bool _debugFrozen = false;

  /// Unscoped is the safe read when Supabase is not initialised (tests, very
  /// early boot): it can never leak another user's state, because there is not
  /// one yet.
  static String? _defaultUserId() {
    try {
      return supabaseSyncService.currentUserId;
    } catch (_) {
      return null;
    }
  }

  static Future<String> _defaultResolveTimezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return 'local';
    }
  }

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
  /// Returns the honest outcome so the card can emit the matching analytics.
  /// Never throws.
  Future<LocationPromptOutcome> promptLocation() async {
    // 1. Persist the opt-in FIRST — before the OS dialog, before any Settings
    //    round-trip. If the app is killed while the user is away in Settings,
    //    the tap still counted. THIS line is the bug fix: the gate used to be
    //    derived entirely from a position fix, which evaporates, so a user who
    //    said yes was indistinguishable from one who had never been asked.
    await _markPreciseOptIn();

    // 2. No `hasPermission()` short-circuit. requestPreciseAccess() is already
    //    idempotent when permission is held, and it is the ONLY path that
    //    handles granted-but-services-off — the short-circuit is exactly what
    //    made the button a visible no-op in that state.
    final outcome = await _location.requestPreciseAccess();
    if (outcome == LocationGrantOutcome.granted ||
        outcome == LocationGrantOutcome.servicesOff) {
      // servicesOff still implies the app-level grant is held.
      await _markPreciseGranted();
    }
    await rebuild(promptLocation: true);
    return switch (outcome) {
      LocationGrantOutcome.granted => LocationPromptOutcome.granted,
      LocationGrantOutcome.denied => LocationPromptOutcome.denied,
      LocationGrantOutcome.openedSettings =>
        LocationPromptOutcome.openedSettings,
      LocationGrantOutcome.servicesOff => LocationPromptOutcome.servicesOff,
    };
  }

  // ---------------------------------------------------------------------------
  // Precise-times opt-in memory.
  // ---------------------------------------------------------------------------

  /// User-scoped key, mirroring `SupabaseSyncService.scopedKey` but resolved
  /// through an injectable seam so this is unit-testable without a live
  /// Supabase client (the `firstVisitHintScopedKey` precedent).
  ///
  /// Scoping matters here: these keys are a per-user consent record, and the
  /// `:<uid>` suffix is the contract `clearScopedPreferencesForUser` matches on,
  /// so sign-out clears them for free. The older dua-times keys are unscoped and
  /// leak across users on a shared device — deliberately not copied.
  String _scopedKey(String baseKey) {
    final userId = _userId();
    return (userId == null || userId.isEmpty) ? baseKey : '$baseKey:$userId';
  }

  Future<bool> _hasPreciseOptIn() => _hasStamp(preciseOptInBaseKey);

  Future<void> _markPreciseOptIn() => _markStamp(preciseOptInBaseKey);

  Future<void> _markPreciseGranted() => _markStamp(preciseGrantedBaseKey);

  Future<bool> _hasStamp(String baseKey) async {
    try {
      final p = await _prefs();
      final scoped = _scopedKey(baseKey);
      if (p.getInt(scoped) != null) return true;

      // Adopt a pre-signup write. The onboarding location ask runs at page 12
      // and signup is at ~17-19, so `_userId()` is null when the stamp is
      // written and it lands on the bare key. Without this the user signs up,
      // the scoped read misses, and they are treated as never-asked — the pitch
      // returns and `dua_times_precise_state{never_asked}` fires for someone we
      // demonstrably asked, which is the exact metric this fix is judged on.
      // (Mirrors `SupabaseSyncService.migrateLegacyIntCache`.)
      if (scoped == baseKey) return false;
      final legacy = p.getInt(baseKey);
      if (legacy == null) return false;
      await p.setInt(scoped, legacy);
      await p.remove(baseKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// True when we have ever OBSERVED a real grant for this user — as opposed to
  /// merely having asked. Load-bearing: without it, denying the very first
  /// prompt lands on [PreciseTimesState.permissionLapsed] and the card tells the
  /// user "iOS reset location access" moments after they themselves declined.
  Future<bool> _hasEverGranted() => _hasStamp(preciseGrantedBaseKey);

  /// Write-once: the stamp records when this first happened, so a later call
  /// must not move it.
  Future<void> _markStamp(String baseKey) async {
    try {
      final p = await _prefs();
      final key = _scopedKey(baseKey);
      if (p.getInt(key) != null) return;
      await p.setInt(key, _clock().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[DuaWindowNotifier] stamp $baseKey failed: $e');
    }
  }

  /// Resolve what the card should say, and whether this build owes the user a
  /// one-time lapse notice.
  ///
  /// **Deliberate divergence from the `NotificationService` F2 reconcile**
  /// (`notification_service.dart:353-363`), which force-corrects a stored ON
  /// belief to OFF when the OS disagrees. Doing that here would *clear* the
  /// opt-in on a lapse and re-arm the full pitch — reproducing the exact bug
  /// this fixes. The principle it protects (a stored belief must never override
  /// live OS truth) is kept differently: [PreciseTimesState.working] is derived
  /// from live truth alone, and the stored key never asserts the feature works.
  /// Do not "fix" this into a reconcile.
  Future<({PreciseTimesState state, LocationReadiness? readiness})>
      _resolvePreciseState(DuaWindowSchedule schedule) async {
    try {
      final readiness = await _location.readiness();

      // A cached coordinate can keep the schedule populated after the
      // device-wide Location Services switch is disabled. Surface that
      // actionable state rather than presenting precise times as working.
      if (readiness == LocationReadiness.servicesOff) {
        await _markPreciseOptIn();
        await _markPreciseGranted();
        return (
          state: PreciseTimesState.servicesOff,
          readiness: readiness,
        );
      }

      if (schedule.computedAt.lat != null) {
        // Migration back-fill: everyone who already granted lands here on their
        // first launch of this build and is stamped before any banner logic
        // runs, so the install base never sees the pitch again.
        await _markPreciseOptIn();
        await _markPreciseGranted();
        return (state: PreciseTimesState.working, readiness: null);
      }

      if (readiness == LocationReadiness.granted) {
        await _markPreciseOptIn();
        await _markPreciseGranted();
      }
      if (!await _hasPreciseOptIn()) {
        return (state: PreciseTimesState.neverAsked, readiness: readiness);
      }
      // Asked, but the OS has never once said yes → they declined. That is not
      // a lapse, and calling it one would have the card tell someone "iOS reset
      // location access" seconds after they pressed Don't Allow.
      final everGranted = await _hasEverGranted();
      final state = switch (readiness) {
        LocationReadiness.granted => PreciseTimesState.unresolved,
        LocationReadiness.servicesOff => PreciseTimesState.servicesOff,
        LocationReadiness.denied ||
        LocationReadiness.deniedForever ||
        LocationReadiness.undetermined =>
          everGranted
              ? PreciseTimesState.permissionLapsed
              : PreciseTimesState.declined,
      };
      return (state: state, readiness: readiness);
    } catch (e) {
      debugPrint('[DuaWindowNotifier] _resolvePreciseState failed: $e');
      if (_disposed) {
        // The `state` getter asserts `mounted`; reading it here would throw
        // into rebuild()'s catch and fire a spurious dua_schedule_build_failed.
        return (state: PreciseTimesState.unresolved, readiness: null);
      }
      // Keep the last good state. A transient failure must never resurrect the
      // pitch for someone who already answered.
      return (state: state.preciseState, readiness: null);
    }
  }

  /// Claim the one-time notice for [next]. Returns true at most once per
  /// transition into that state.
  ///
  /// **Called by the widget, not by [rebuild].** Mirrors
  /// `FirstVisitHintService.claim`, and the co-location is the point: claim and
  /// visibility must be the same event. Claiming during `rebuild()` spent the
  /// notice while the card sat behind the opaque `DailyLaunchOverlay` — which is
  /// up on precisely the cold starts where a lapse is detected — so the user saw
  /// nothing and the claim was gone for good.
  ///
  /// Marking at claim rather than at dismiss is deliberate, per the same
  /// precedent: a user who ignored the notice has still been told.
  Future<bool> claimLapseNotice(PreciseTimesState next) async {
    if (PrecisePausedNotice.messageFor(next) == null) return false;
    try {
      final p = await _prefs();
      final key = _scopedKey(preciseNoticeShownBaseKey);
      final shown = _noticeShowsSoFar(p.getString(key), next);
      if (shown == null || shown >= lapseNoticeMaxShows) return false;
      await p.setString(key, '${next.wireName}|${shown + 1}');
      return true;
    } catch (e) {
      debugPrint('[DuaWindowNotifier] claimLapseNotice failed: $e');
      // A notice we cannot remember showing is a notice that shows forever.
      return false;
    }
  }

  /// How many times this episode's notice has been shown, or null when it must
  /// never show again (the user dealt with it, or this is a pre-✕ record).
  ///
  /// A record for a *different* state reads as zero on purpose: `servicesOff`
  /// and `permissionLapsed` say different things and name different fixes, so
  /// each earns its own notice.
  static int? _noticeShowsSoFar(String? raw, PreciseTimesState next) {
    if (raw == null) return 0;
    final parts = raw.split('|');
    if (parts.first != next.wireName) return 0;
    if (parts.length == 1) return null; // pre-✕ record → already spent
    return parts[1] == 'ack' ? null : (int.tryParse(parts[1]) ?? 0);
  }

  /// Record that the user actually dealt with the notice — tapped through to
  /// the steps, or dismissed it with the ✕. Either way this episode is closed.
  ///
  /// Deliberately separate from [claimLapseNotice]: rendering is not
  /// acknowledgement, and conflating the two is what let a notice be spent on a
  /// frame nobody read.
  Future<void> acknowledgeLapseNotice(PreciseTimesState next) async {
    if (PrecisePausedNotice.messageFor(next) == null) return;
    try {
      final p = await _prefs();
      await p.setString(
        _scopedKey(preciseNoticeShownBaseKey),
        '${next.wireName}|ack',
      );
    } catch (e) {
      debugPrint('[DuaWindowNotifier] acknowledgeLapseNotice failed: $e');
    }
  }

  /// Re-arm the notice once the user is no longer in a lapsed state, so a
  /// *future* lapse earns a fresh one. Runs on every rebuild — unlike the claim,
  /// this is safe off-screen because it only ever un-spends.
  Future<void> _rearmLapseNoticeIfRecovered(PreciseTimesState next) async {
    if (PrecisePausedNotice.messageFor(next) != null) return;
    try {
      final p = await _prefs();
      final key = _scopedKey(preciseNoticeShownBaseKey);
      if (p.getString(key) != null) await p.remove(key);
    } catch (e) {
      debugPrint('[DuaWindowNotifier] rearm failed: $e');
    }
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
      // Both gate inputs are re-derived here, which is the whole lifecycle
      // story: rebuild() already runs on cold start and every `resumed`, so no
      // extra observer is needed.
      final precise = await _resolvePreciseState(schedule);
      if (_disposed) return;
      await _rearmLapseNoticeIfRecovered(precise.state);
      // Resolve the awaited value BEFORE touching `state`. Dart evaluates the
      // receiver ahead of the arguments, so `state.copyWith(x: await …)` reads
      // `state` first and writes that pre-await snapshot back — silently
      // reverting anything that landed while the await was in flight. The
      // symptom is a field mysteriously reset with no code that resets it,
      // which points nowhere near the cause. Found by a repo-wide sweep after
      // the same shape cost four suites in the daily loop (Wave C, 2026-08-02).
      //
      // MERGE NOTE 2026-08-05: master added the `precise` lines above while
      // still writing `preciseBannerSnoozed: await _isBannerSnoozed(now)`
      // inline, which is exactly the shape that sweep removed. Taking either
      // side alone was wrong — master's `precise` is required by
      // `_emitPreciseState` below, and master's inline await reintroduces the
      // bug. Both are kept, with the await hoisted.
      final snoozed = await _isBannerSnoozed(now);
      if (_disposed) return;
      state = state.copyWith(
        schedule: schedule,
        now: now,
        building: false,
        preciseBannerSnoozed: snoozed,
        preciseState: precise.state,
      );
      _syncTicker();
      _emitPreciseState(precise.state, precise.readiness);
      _emitScheduleBuilt(schedule);
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
      // Engine-health alarm: a build failure is invisible otherwise (the card
      // just silently stays empty). Lets prod distinguish "no window today" from
      // "the engine is broken".
      onAnalyticsEvent?.call(AnalyticsEvents.duaScheduleBuildFailed, const {});
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

  /// Emit `dua_schedule_built` (engine-liveness + eligibility) — but ONLY when
  /// the schedule's shape changed since the last emit. rebuild() runs on every
  /// `resumed` (including transient Control-Center / app-switcher bounces), so
  /// an unconditional emit would flood Mixpanel AND bias the eligibility
  /// denominator toward fidgety users (10 glances ≠ 10 eligibility states). The
  /// dedup keeps one event per distinct state per session, which is what the
  /// prod question ("is the engine producing eligible/located schedules?")
  /// actually needs.
  void _emitScheduleBuilt(DuaWindowSchedule schedule) {
    final activeWindow = schedule.active?.type.wireName;
    final urgency = schedule.urgency.wireName;
    final hasNext = schedule.next != null;
    final locationPresent = schedule.computedAt.lat != null;
    // `has_active` is derivable from `active_window`, so it's not in the
    // signature — a null active_window already encodes it.
    final signature =
        '${activeWindow ?? '-'}|$urgency|$hasNext|$locationPresent';
    if (signature == _lastScheduleBuiltSignature) return;
    _lastScheduleBuiltSignature = signature;
    onAnalyticsEvent?.call(AnalyticsEvents.duaScheduleBuilt, {
      AnalyticsEvents.propHasActive: schedule.active != null,
      AnalyticsEvents.propActiveWindow: activeWindow,
      AnalyticsEvents.propUrgency: urgency,
      AnalyticsEvents.propHasNext: hasNext,
      AnalyticsEvents.propLocationPresent: locationPresent,
    });
  }

  /// Emit `dua_times_precise_state` — but ONLY when the state actually changed.
  /// Same rationale as [_emitScheduleBuilt]: `rebuild()` runs on every
  /// `resumed`, including transient Control-Center bounces, so an unconditional
  /// emit would both flood Mixpanel and bias any denominator toward fidgety
  /// users.
  void _emitPreciseState(PreciseTimesState s, LocationReadiness? readiness) {
    final signature = '${s.wireName}|${readiness?.name ?? '-'}';
    if (signature == _lastPreciseStateSignature) return;
    _lastPreciseStateSignature = signature;
    onAnalyticsEvent?.call(AnalyticsEvents.duaTimesPreciseState, {
      AnalyticsEvents.propPreciseState: s.wireName,
      if (readiness != null) AnalyticsEvents.propPermission: readiness.name,
    });
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
    if (activeWindow != null) {
      props[AnalyticsEvents.propActiveWindow] = activeWindow;
    }
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
