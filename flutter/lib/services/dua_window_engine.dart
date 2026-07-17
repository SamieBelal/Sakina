import 'package:flutter/foundation.dart';

import 'package:sakina/features/dua_times/data/dua_window_catalog.dart';
import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/prayer_time_service.dart';

/// Coarse coordinates the engine computes precise windows from.
@immutable
class EngineLocation {
  const EngineLocation({required this.lat, required this.lon});
  final double lat;
  final double lon;
}

/// A single PRECISE-window fire instant, computed on-device for the server-push
/// sync path (plan §4). Only the window category + its fire instant leave the
/// device — never raw lat/lon (plan §5 privacy win).
///
/// [fireUtc] is the window's **start** instant (decision D2: fire at window
/// open — the server enqueues the OneSignal push at exactly this local moment).
@immutable
class PreciseInstant {
  const PreciseInstant({required this.type, required this.fireUtc});

  final DuaWindowType type;

  /// Absolute UTC instant the window opens (== the push fire time, D2).
  final DateTime fireUtc;

  @override
  bool operator ==(Object other) =>
      other is PreciseInstant &&
      other.type == type &&
      other.fireUtc.isAtSameMomentAs(fireUtc);

  @override
  int get hashCode => Object.hash(type, fireUtc.toUtc().millisecondsSinceEpoch);

  @override
  String toString() => 'PreciseInstant(${type.wireName}, $fireUtc)';
}

/// D1 fatigue policy for the location-dependent **last-third-of-night** push.
///
/// The night-third recurs EVERY night, but a nightly 3am buzz is fatiguing, so
/// by default the sync only emits it on the nights that carry extra spiritual
/// weight (Friday nights, White-Days nights, Laylat-al-Qadr nights). The
/// friday-hour and iftar precise pushes are ALWAYS included and are not affected
/// by this policy.
///
/// TUNABLE (plan D1 — "default Fri / White Days / Laylat, not nightly; full
/// nightly optional"): switch to [everyNight] to opt a user into the nightly
/// cadence, or [never] to suppress the night-third push entirely.
enum NightThirdFatiguePolicy {
  /// Only Friday nights, White-Days nights, and Laylat-al-Qadr nights (default).
  specialNightsOnly,

  /// Every night in the horizon (opt-in; more reminders).
  everyNight,

  /// Never — suppress the night-third precise push.
  never,
}

/// Converts a bare local date (y/m/d) to the absolute UTC instant of that
/// date's device-local midnight (spec §4 date-line rule).
///
/// The default implementation builds a local [DateTime] and converts to UTC —
/// which, on a device, IS its local midnight. Tests inject a fixed-offset
/// variant to simulate Honolulu (UTC-10) vs Auckland (UTC+13) deterministically.
typedef LocalMidnightResolver = DateTime Function(int year, int month, int day);

DateTime _deviceLocalMidnightUtc(int year, int month, int day) =>
    DateTime(year, month, day).toUtc();

/// The core: composes prayer-time (recurring) + seeded calendar (all-day)
/// windows into a [DuaWindowSchedule] for a given `now` (+ optional location).
///
/// Deterministic and side-effect-free given its injected seams: clock (`now`),
/// [LocationService]/explicit location, [DuaWindowRepository] (calendar), the
/// [PrayerTimeService], the [LocalMidnightResolver], and the IANA `tz` label.
/// No Riverpod / no platform channels here (per `CLAUDE.md`).
///
/// Overlap priority (spec §4, highest wins the hero line):
///   ʿArafah > Laylat-al-Qadr > last-third-of-night > Friday hour >
///   Ramadan/other special day > Friday (day) > White Days.
class DuaWindowEngine {
  DuaWindowEngine({
    required DuaWindowRepository repository,
    LocationService? locationService,
    PrayerTimeService prayerTimeService = const PrayerTimeService(),
    LocalMidnightResolver localMidnightUtc = _deviceLocalMidnightUtc,
  })  : _repository = repository,
        _locationService = locationService,
        _prayer = prayerTimeService,
        _localMidnightUtc = localMidnightUtc;

  final DuaWindowRepository _repository;
  final LocationService? _locationService;
  final PrayerTimeService _prayer;
  final LocalMidnightResolver _localMidnightUtc;

  /// How far ahead the schedule's `upcoming[]` timeline reaches (spec §9 widget
  /// timeline). Seven days keeps the widget correct without the app reopening.
  static const Duration horizon = Duration(days: 7);

  /// How far ahead [computePreciseInstants] projects the server-push precise
  /// windows (plan §4/D4 — "rec: 30–45d"). A longer horizon covers more dormancy
  /// at ~no cost; 30 days is the low end of the recommended band. Kept SEPARATE
  /// from [horizon] (the widget timeline) so the widget stays cheap while the
  /// sync reaches further ahead.
  static const Duration preciseSyncHorizon = Duration(days: 30);

  /// Overlap priority weight — higher wins the hero line (spec §4).
  static int priorityOf(DuaWindowType type) {
    switch (type) {
      case DuaWindowType.arafah:
        return 100;
      case DuaWindowType.laylatAlQadr:
        return 90;
      case DuaWindowType.lastThirdOfNight:
        return 80;
      case DuaWindowType.fridayHour:
        return 70;
      case DuaWindowType.iftar:
        return 65;
      case DuaWindowType.ramadan:
        return 60;
      case DuaWindowType.dhulHijjah10:
        return 58;
      case DuaWindowType.ashura:
        return 56;
      case DuaWindowType.eid:
        return 54;
      case DuaWindowType.fridayDay:
        return 40;
      case DuaWindowType.whiteDays:
        return 30;
    }
  }

  /// Build the schedule.
  ///
  /// - [now] is the reference instant (inject a fixed clock in tests).
  /// - [location] overrides location lookup. When null, the [LocationService]
  ///   (if provided) is consulted; if that also yields nothing, precise windows
  ///   are omitted and only calendar + soft-night survive (spec §10 degrade).
  /// - [tzName] is the IANA/local tz label stamped for the widget travel guard.
  Future<DuaWindowSchedule> buildSchedule({
    required DateTime now,
    EngineLocation? location,
    String tzName = 'local',
    bool promptLocation = false,
  }) async {
    final nowUtc = now.toUtc();
    final horizonEnd = nowUtc.add(horizon);

    final resolvedLocation =
        location ?? await _resolveLocation(prompt: promptLocation);

    final calendar = await _repository.load();

    // ----- Calendar (all-day) windows over the horizon -----
    final windows = <DuaWindow>[
      ..._calendarWindows(calendar, nowUtc, horizonEnd),
      ..._fridayWindows(nowUtc, horizonEnd),
    ];

    // ----- Precise (location-dependent) recurring windows -----
    if (resolvedLocation != null) {
      windows.addAll(
        _preciseWindows(resolvedLocation, calendar, now, nowUtc, horizonEnd),
      );
    } else {
      // Degrade: no precise windows; add a soft-night marker (spec §10).
      final soft = _softNightWindow(now, nowUtc);
      if (soft != null) windows.add(soft);
    }

    return _assemble(
      windows: windows,
      nowUtc: nowUtc,
      horizonEnd: horizonEnd,
      tzName: tzName,
      location: resolvedLocation,
    );
  }

  Future<EngineLocation?> _resolveLocation({required bool prompt}) async {
    final svc = _locationService;
    if (svc == null) return null;
    final coarse = await svc.getCoarseLocation(prompt: prompt);
    if (coarse == null) return null;
    return EngineLocation(lat: coarse.lat, lon: coarse.lon);
  }

  // ---------------------------------------------------------------------------
  // Precise-instant projection (server-push sync path — plan §4)
  // ---------------------------------------------------------------------------

  /// Project a [preciseSyncHorizon]-day list of PRECISE-window fire instants for
  /// the server-push path — `last_third_of_night`, `friday_hour`, and `iftar`,
  /// each as a [PreciseInstant] whose `fireUtc` is the window's **start** instant
  /// (D2: fire at window open).
  ///
  /// This reuses the exact same prayer-time math as [buildSchedule]'s
  /// `_preciseWindows`, only over the longer horizon and with the D1 fatigue
  /// filter applied to the night-third. It is DELIBERATELY separate from
  /// `buildSchedule` and does NO network / location lookup itself — the caller
  /// (the sync service) resolves the coarse [location] first and passes it in.
  /// When [location] is null (permission absent / no cached fix) this returns an
  /// EMPTY list — precise windows degrade to nothing, consistent with the card
  /// (plan §10 degrade).
  ///
  /// Pure + deterministic given ([now], [location], the injected [PrayerTimeService]
  /// and the calendar). No Riverpod / platform channels (per `CLAUDE.md`).
  Future<List<PreciseInstant>> computePreciseInstants({
    required DateTime now,
    required EngineLocation? location,
    NightThirdFatiguePolicy nightThirdPolicy =
        NightThirdFatiguePolicy.specialNightsOnly,
  }) async {
    if (location == null) return const <PreciseInstant>[];

    final nowUtc = now.toUtc();
    final horizonEnd = nowUtc.add(preciseSyncHorizon);
    final calendar = await _repository.load();

    final out = <PreciseInstant>[];
    final localNow = DateTime(now.year, now.month, now.day);

    // Walk each local day in the horizon (plus the day before, for the
    // night-third that opened yesterday) — mirrors `_preciseWindows`.
    for (var i = -1; i <= preciseSyncHorizon.inDays + 1; i++) {
      final day = localNow.add(Duration(days: i));

      // ---- Last third of the night (D1 fatigue-gated) ----
      // The third queried for `day` opens on the EVENING of `day` (post-Maghrib)
      // and fires in the pre-dawn of `day + 1`. So the fatigue anchor is `day`
      // itself: "Friday night" = the third that opens Friday evening.
      final eveningDay = day;
      if (nightThirdPolicy != NightThirdFatiguePolicy.never &&
          (nightThirdPolicy == NightThirdFatiguePolicy.everyNight ||
              _isSpecialNight(calendar, eveningDay))) {
        final third = _prayer.lastThirdOfNight(
          lat: location.lat,
          lon: location.lon,
          now: day.isAtSameMomentAs(localNow) ? now : day,
          nowLocalDate: day,
        );
        _addInstant(
          out,
          DuaWindowType.lastThirdOfNight,
          third?.startUtc,
          nowUtc,
          horizonEnd,
        );
      }

      // Prayer times only when the day can produce a precise window — Fridays
      // (friday hour) or Ramadan fasting days (iftar). Same guard as
      // `_preciseWindows` so the astronomical calc isn't run needlessly.
      final needsPrayerTimes =
          day.weekday == DateTime.friday || _isRamadanLocalDay(calendar, day);
      if (!needsPrayerTimes) continue;
      final pt = _prayer.prayerTimes(
        lat: location.lat,
        lon: location.lon,
        date: day,
      );

      // ---- Friday hour: the last hour before Maghrib on Friday (always) ----
      if (day.weekday == DateTime.friday && pt.maghrib != null) {
        final start =
            pt.maghrib!.subtract(DuaWindowCatalog.fridayHourLeadBeforeMaghrib);
        _addInstant(
          out,
          DuaWindowType.fridayHour,
          start,
          nowUtc,
          horizonEnd,
        );
      }

      // ---- Iftar: ~20 min before Maghrib during Ramadan (always) ----
      if (pt.maghrib != null && _isRamadanLocalDay(calendar, day)) {
        final start =
            pt.maghrib!.subtract(DuaWindowCatalog.iftarLeadBeforeMaghrib);
        _addInstant(out, DuaWindowType.iftar, start, nowUtc, horizonEnd);
      }
    }

    // Stable order (by fire, then type) for a deterministic sync payload +
    // deterministic version diffing. De-dup by (type, fireUtc) since day-walking
    // can emit the same night-third twice.
    final seen = <String>{};
    final deduped = <PreciseInstant>[];
    for (final p in out) {
      final key = '${p.type.wireName}|${p.fireUtc.millisecondsSinceEpoch}';
      if (seen.add(key)) deduped.add(p);
    }
    deduped.sort((a, b) {
      final byFire = a.fireUtc.compareTo(b.fireUtc);
      if (byFire != 0) return byFire;
      return a.type.wireName.compareTo(b.type.wireName);
    });
    return deduped;
  }

  /// Add a [PreciseInstant] if [start] is non-null and its fire instant is in
  /// `[nowUtc, horizonEnd]` (future-only, D2 fire-at-start).
  void _addInstant(
    List<PreciseInstant> out,
    DuaWindowType type,
    DateTime? start,
    DateTime nowUtc,
    DateTime horizonEnd,
  ) {
    if (start == null) return;
    final fireUtc = start.toUtc();
    if (fireUtc.isBefore(nowUtc)) return;
    if (fireUtc.isAfter(horizonEnd)) return;
    out.add(PreciseInstant(type: type, fireUtc: fireUtc));
  }

  /// True when the EVENING of [eveningDay] opens a night that carries extra
  /// weight for the night-third fatigue policy (D1): a Friday night, a
  /// White-Days night, or a Laylat-al-Qadr night. The caller passes the evening
  /// day (the third that fires pre-dawn AFTER [eveningDay] belongs to it), so
  /// e.g. a Friday evening ⇒ the pre-dawn third of Saturday qualifies.
  bool _isSpecialNight(DuaCalendar calendar, DateTime eveningDay) {
    final localDay = eveningDay;
    if (localDay.weekday == DateTime.friday) return true;
    final dayStart = _localMidnightUtc(
      localDay.year,
      localDay.month,
      localDay.day,
    );
    for (final row in calendar.rows) {
      if (row.kind != 'white_days' && row.kind != 'laylat_al_qadr') continue;
      final start = _localMidnightUtc(
        row.startDate.year,
        row.startDate.month,
        row.startDate.day,
      );
      final endExclusive = row.endDate.add(const Duration(days: 1));
      final end = _localMidnightUtc(
        endExclusive.year,
        endExclusive.month,
        endExclusive.day,
      );
      if (!dayStart.isBefore(start) && dayStart.isBefore(end)) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Calendar (all-day) windows
  // ---------------------------------------------------------------------------

  List<DuaWindow> _calendarWindows(
    DuaCalendar calendar,
    DateTime nowUtc,
    DateTime horizonEnd,
  ) {
    final out = <DuaWindow>[];
    for (final row in calendar.rows) {
      // Expand [startDate, endDate] inclusive to device-local midnight bounds.
      final startUtc = _localMidnightUtc(
        row.startDate.year,
        row.startDate.month,
        row.startDate.day,
      );
      // end is inclusive → the window closes at local midnight of the day AFTER
      // endDate.
      final endExclusive = row.endDate.add(const Duration(days: 1));
      final endUtc = _localMidnightUtc(
        endExclusive.year,
        endExclusive.month,
        endExclusive.day,
      );

      // Keep windows that are active now or open within the horizon.
      if (endUtc.isBefore(nowUtc)) continue;
      if (startUtc.isAfter(horizonEnd)) continue;

      // Unknown kind → drop the row rather than mislabel it (wrong copy +
      // priority). The mapper logs and returns null; skip it.
      final type = _typeFromKind(row.kind);
      if (type == null) continue;

      out.add(
        DuaWindow(
          type: type,
          tier: _tierFromString(row.tier),
          titleKey: row.titleKey,
          sourceRef: row.sourceRef,
          startUtc: startUtc,
          endUtc: endUtc,
          isAllDay: true,
          locationDependent: false,
        ),
      );
    }
    return out;
  }

  /// Friday (Jumuʿah) whole-day windows — a pure device-weekday check, no data
  /// needed (spec §3). Emits every Friday-day in the horizon.
  List<DuaWindow> _fridayWindows(DateTime nowUtc, DateTime horizonEnd) {
    final out = <DuaWindow>[];
    // Walk each candidate local day from ~yesterday through the horizon. We seed
    // the walk from `now`'s calendar components (the [LocalMidnightResolver]
    // does the actual per-zone UTC anchoring), and start one day early so a
    // Friday whose local midnight lands before `now`'s UTC instant (positive-tz
    // devices) is still considered.
    final startDay = DateTime(nowUtc.year, nowUtc.month, nowUtc.day)
        .subtract(const Duration(days: 1));

    for (var i = 0; i <= horizon.inDays + 2; i++) {
      final day = startDay.add(Duration(days: i));
      final startUtc = _localMidnightUtc(day.year, day.month, day.day);
      final next = day.add(const Duration(days: 1));
      final endUtc = _localMidnightUtc(next.year, next.month, next.day);
      if (endUtc.isBefore(nowUtc)) continue;
      if (startUtc.isAfter(horizonEnd)) break;

      // Weekday of the LOCAL day this window covers. We derive it from the
      // local midnight instant to stay correct across the date-line seam.
      final localMidnightAsLocal = DateTime(day.year, day.month, day.day);
      if (localMidnightAsLocal.weekday != DateTime.friday) continue;

      out.add(
        DuaWindow(
          type: DuaWindowType.fridayDay,
          tier: DuaWindowTier.special,
          titleKey: 'dua_window.friday.title',
          sourceRef: null,
          startUtc: startUtc,
          endUtc: endUtc,
          isAllDay: true,
          locationDependent: false,
        ),
      );
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Precise (location-dependent) recurring windows
  // ---------------------------------------------------------------------------

  List<DuaWindow> _preciseWindows(
    EngineLocation loc,
    DuaCalendar calendar,
    DateTime now,
    DateTime nowUtc,
    DateTime horizonEnd,
  ) {
    final out = <DuaWindow>[];

    // Walk each local day in the horizon (plus the day before, for the
    // night-third that opened yesterday).
    final localNow = DateTime(now.year, now.month, now.day);
    for (var i = -1; i <= horizon.inDays + 1; i++) {
      final day = localNow.add(Duration(days: i));

      // ---- Last third of the night ----
      final third = _prayer.lastThirdOfNight(
        lat: loc.lat,
        lon: loc.lon,
        now: day.isAtSameMomentAs(localNow) ? now : day,
        nowLocalDate: day,
      );
      if (third != null &&
          !third.endUtc.isBefore(nowUtc) &&
          !third.startUtc.isAfter(horizonEnd)) {
        out.add(
          DuaWindow(
            type: DuaWindowType.lastThirdOfNight,
            tier: DuaWindowTier.hero,
            titleKey: DuaWindowCatalog.lastThirdOfNight.titleKey,
            sourceRef: DuaWindowCatalog.lastThirdOfNight.sourceRef,
            startUtc: third.startUtc,
            endUtc: third.endUtc,
            isAllDay: false,
            locationDependent: true,
          ),
        );
      }

      // Prayer times for this local day (for Friday hour + iftar). Only compute
      // when the day can actually produce a precise window — Fridays (the Friday
      // hour) or Ramadan fasting days (iftar) — since `prayerTimes` is the
      // expensive astronomical calc and the rest of the ~9-day walk never reads
      // it. The night-third above uses its own `lastThirdOfNight` call.
      final needsPrayerTimes =
          day.weekday == DateTime.friday || _isRamadanLocalDay(calendar, day);
      final pt = needsPrayerTimes
          ? _prayer.prayerTimes(lat: loc.lat, lon: loc.lon, date: day)
          : null;

      // ---- The Friday hour: the LAST HOUR BEFORE MAGHRIB on Friday ----
      // Anchored to Maghrib (sunset) only — NOT ʿAsr. The hadith says "the last
      // hour"; ʿAsr is the one madhab-dependent prayer, and pinning to it would
      // be false precision + force gathering the user's madhab. Sunset is
      // madhab-independent, so this needs no madhab.
      if (day.weekday == DateTime.friday && pt?.maghrib != null) {
        final end = pt!.maghrib!;
        final start =
            end.subtract(DuaWindowCatalog.fridayHourLeadBeforeMaghrib);
        if (end.isAfter(start) &&
            !end.isBefore(nowUtc) &&
            !start.isAfter(horizonEnd)) {
          out.add(
            DuaWindow(
              type: DuaWindowType.fridayHour,
              tier: DuaWindowTier.hero,
              titleKey: DuaWindowCatalog.fridayHour.titleKey,
              sourceRef: DuaWindowCatalog.fridayHour.sourceRef,
              startUtc: start,
              endUtc: end,
              isAllDay: false,
              locationDependent: true,
            ),
          );
        }
      }

      // ---- Iftar (~20 min before Maghrib, ONLY during Ramadan) ----
      // Iftar breaks the fast at Maghrib on each fasting day. Convention: the
      // seeded Ramadan `start_date` IS the first fasting day and `end_date` the
      // last (Umm al-Qura). So iftar fires Maghrib of start_date … end_date and
      // NOT the evening before Ramadan nor on Eid (the day after end_date is
      // excluded by _isRamadanLocalDay's exclusive end). Pinned by the
      // "fasting days" boundary test. (±1 vs local moon-sighting is inherent.)
      if (pt?.maghrib != null && _isRamadanLocalDay(calendar, day)) {
        final end = pt!.maghrib!;
        final start = end.subtract(DuaWindowCatalog.iftarLeadBeforeMaghrib);
        if (!end.isBefore(nowUtc) && !start.isAfter(horizonEnd)) {
          out.add(
            DuaWindow(
              type: DuaWindowType.iftar,
              tier: DuaWindowTier.special,
              titleKey: DuaWindowCatalog.iftar.titleKey,
              sourceRef: DuaWindowCatalog.iftar.sourceRef,
              startUtc: start,
              endUtc: end,
              isAllDay: false,
              locationDependent: true,
            ),
          );
        }
      }
    }

    return out;
  }

  /// A humble soft-night marker keyed to the device clock when location is
  /// absent (spec §3/§10). Marks tonight's local 01:00→05:00 band as the
  /// "depths of the night" — never a precise claim, `soft` tier, all-day=false
  /// but NOT location-dependent (so the widget keeps it after the travel guard).
  DuaWindow? _softNightWindow(DateTime now, DateTime nowUtc) {
    final local = DateTime(now.year, now.month, now.day);
    // If it's already past ~05:00 local, target tonight (next calendar day's
    // pre-dawn); else target this pre-dawn.
    final localHour = now.hour;
    final anchorDay =
        localHour >= 5 ? local.add(const Duration(days: 1)) : local;
    final start = _localMidnightUtc(
      anchorDay.year,
      anchorDay.month,
      anchorDay.day,
    ).add(const Duration(hours: 1));
    final end = _localMidnightUtc(
      anchorDay.year,
      anchorDay.month,
      anchorDay.day,
    ).add(const Duration(hours: 5));
    if (end.isBefore(nowUtc)) return null;
    return DuaWindow(
      type: DuaWindowCatalog.softNight.type,
      tier: DuaWindowCatalog.softNight.tier,
      titleKey: DuaWindowCatalog.softNight.titleKey,
      sourceRef: DuaWindowCatalog.softNight.sourceRef,
      startUtc: start,
      endUtc: end,
      isAllDay: false,
      locationDependent: false,
    );
  }

  /// True if [localDay] is a Ramadan fasting day: its local midnight falls in
  /// `[start_date, end_date + 1 day)`. The exclusive end means the day AFTER
  /// `end_date` (Eid) is NOT a fasting day, so iftar never fires on Eid.
  bool _isRamadanLocalDay(DuaCalendar calendar, DateTime localDay) {
    final dayStart = _localMidnightUtc(
      localDay.year,
      localDay.month,
      localDay.day,
    );
    for (final row in calendar.rows) {
      if (row.kind != 'ramadan') continue;
      final start = _localMidnightUtc(
        row.startDate.year,
        row.startDate.month,
        row.startDate.day,
      );
      final endExclusive = row.endDate.add(const Duration(days: 1));
      final end = _localMidnightUtc(
        endExclusive.year,
        endExclusive.month,
        endExclusive.day,
      );
      if (!dayStart.isBefore(start) && dayStart.isBefore(end)) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Assembly: active / next / upcoming + urgency + stamp
  // ---------------------------------------------------------------------------

  DuaWindowSchedule _assemble({
    required List<DuaWindow> windows,
    required DateTime nowUtc,
    required DateTime horizonEnd,
    required String tzName,
    required EngineLocation? location,
  }) {
    // De-dup identical windows (same type + bounds) that day-walking can emit.
    final deduped = _dedupe(windows);

    // Active = highest-priority window whose [start, end) contains now.
    DuaWindow? active;
    for (final w in deduped) {
      if (!nowUtc.isBefore(w.startUtc) && nowUtc.isBefore(w.endUtc)) {
        if (active == null || priorityOf(w.type) > priorityOf(active.type)) {
          active = w;
        }
      }
    }

    // Upcoming = windows opening at/after now, ordered by start then priority.
    final upcoming = deduped.where((w) => !w.startUtc.isBefore(nowUtc)).toList()
      ..sort((a, b) {
        final byStart = a.startUtc.compareTo(b.startUtc);
        if (byStart != 0) return byStart;
        return priorityOf(b.type).compareTo(priorityOf(a.type));
      });

    final next = upcoming.isEmpty ? null : upcoming.first;

    final urgency = _urgencyFor(active, nowUtc);

    return DuaWindowSchedule(
      active: active,
      next: next,
      upcoming: upcoming,
      urgency: urgency,
      computedAt: DuaScheduleStamp(
        tz: tzName,
        lat: location?.lat,
        lon: location?.lon,
        computedThroughUtc: horizonEnd,
        // Build-instant staleness stamp: `nowUtc` is the engine's reference
        // clock (already UTC). The native widget's refresh guard reads this.
        builtAtUtc: nowUtc,
      ),
    );
  }

  UrgencyState _urgencyFor(DuaWindow? active, DateTime nowUtc) {
    if (active == null) return UrgencyState.upcoming;
    if (active.isAllDay) return UrgencyState.allDay;
    final remaining = active.endUtc.difference(nowUtc);
    if (remaining <= const Duration(minutes: 15)) return UrgencyState.lastCall;
    if (remaining <= const Duration(hours: 1)) return UrgencyState.closing;
    return UrgencyState.comfortable;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<DuaWindow> _dedupe(List<DuaWindow> windows) {
    final seen = <String>{};
    final out = <DuaWindow>[];
    for (final w in windows) {
      final key = '${w.type}|${w.startUtc.millisecondsSinceEpoch}'
          '|${w.endUtc.millisecondsSinceEpoch}';
      if (seen.add(key)) out.add(w);
    }
    return out;
  }

  DuaWindowType? _typeFromKind(String kind) {
    switch (kind) {
      case 'arafah':
        return DuaWindowType.arafah;
      case 'dhul_hijjah_10':
        return DuaWindowType.dhulHijjah10;
      case 'laylat_al_qadr':
        return DuaWindowType.laylatAlQadr;
      case 'ramadan':
        return DuaWindowType.ramadan;
      case 'ashura':
        return DuaWindowType.ashura;
      case 'white_days':
        return DuaWindowType.whiteDays;
      case 'eid':
        return DuaWindowType.eid;
      case 'friday_day':
        return DuaWindowType.fridayDay;
      default:
        // Unknown kind: drop the row rather than mislabel it with the wrong
        // copy/priority. Caller skips a null.
        debugPrint('[DuaWindowEngine] unknown calendar kind (dropped): $kind');
        return null;
    }
  }

  DuaWindowTier _tierFromString(String tier) {
    switch (tier) {
      case 'hero':
        return DuaWindowTier.hero;
      case 'special':
        return DuaWindowTier.special;
      case 'soft':
      default:
        return DuaWindowTier.soft;
    }
  }
}
