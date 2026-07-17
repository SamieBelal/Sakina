import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/supabase_sync_service.dart';

/// A single seeded ALL-DAY calendar row from `dua_windows` (spec §3/§4).
///
/// [startDate]/[endDate] are **bare local dates** (y/m/d, no time-of-day). The
/// engine expands each to the device-local midnight→midnight span; a fixed UTC
/// instant would mis-open ʿArafah by up to ~13h at the date line (spec §4). The
/// inclusive range covers `[startDate, endDate]` days.
@immutable
class DuaCalendarRow {
  const DuaCalendarRow({
    required this.id,
    required this.kind,
    required this.tier,
    required this.titleKey,
    required this.startDate,
    required this.endDate,
    required this.sourceRef,
  });

  /// Stable row id (e.g. `arafah_1448`).
  final String id;

  /// Row category — maps to a `DuaWindowType` (`arafah`, `ramadan`, …).
  final String kind;

  /// `hero` | `special` | `soft` — maps to a `DuaWindowTier`.
  final String tier;

  /// Client copy-lookup key (no baked strings).
  final String titleKey;

  /// Inclusive start (bare local date, time-of-day is midnight local).
  final DateTime startDate;

  /// Inclusive end (bare local date). Single-day rows set = [startDate].
  final DateTime endDate;

  /// Optional hadith/source reference for the "why" disclosure.
  final String? sourceRef;

  /// Parse from a Supabase/asset row map. Dates are `YYYY-MM-DD` strings;
  /// parsed as bare local dates (midnight-local via [DateTime]).
  factory DuaCalendarRow.fromMap(Map<String, dynamic> m) {
    return DuaCalendarRow(
      id: m['id'] as String,
      kind: m['kind'] as String,
      tier: m['tier'] as String,
      titleKey: m['title_key'] as String,
      startDate: _parseDate(m['start_date'] as String),
      endDate: _parseDate(m['end_date'] as String),
      sourceRef: m['source_ref'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'kind': kind,
        'tier': tier,
        'title_key': titleKey,
        'start_date': _fmtDate(startDate),
        'end_date': _fmtDate(endDate),
        'source_ref': sourceRef,
      };

  /// Parse a bare `YYYY-MM-DD` into a local-midnight [DateTime]. We deliberately
  /// build a local [DateTime] (not UTC): the engine anchors the all-day span to
  /// the device's own local day (spec §4).
  static DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

/// The parsed calendar: the dated rows + the seed-horizon sentinel.
@immutable
class DuaCalendar {
  const DuaCalendar({
    required this.rows,
    required this.lastSeededThrough,
    required this.fromBundledAsset,
  });

  /// All seeded all-day calendar rows.
  final List<DuaCalendarRow> rows;

  /// The last DATE the seed covers with confidence (from `dua_windows_meta`).
  /// Null if unknown. Drives the seed-horizon health check (spec §4).
  final DateTime? lastSeededThrough;

  /// True when these rows came from the bundled Flutter asset (cold-start
  /// offline) rather than the Supabase-backed cache.
  final bool fromBundledAsset;

  bool get isEmpty => rows.isEmpty;

  static const DuaCalendar empty = DuaCalendar(
    rows: <DuaCalendarRow>[],
    lastSeededThrough: null,
    fromBundledAsset: false,
  );
}

/// Fetches the seeded `dua_windows` + `dua_windows_meta` via the public-catalog
/// anon-read pattern, caches locally in SharedPreferences, and cold-start-falls
/// back to a BUNDLED Flutter asset when the cache is empty AND the network is
/// unavailable (spec §4).
///
/// No Riverpod / Supabase-widget coupling (pure service, per `CLAUDE.md`).
/// The Supabase fetch + prefs + asset load are injectable seams so the engine's
/// tests are deterministic and offline.
class DuaWindowRepository {
  DuaWindowRepository({
    SupabaseSyncService? syncService,
    Future<SharedPreferences> Function()? prefs,
    Future<String> Function(String assetPath)? loadAsset,
  })  : _sync = syncService ?? supabaseSyncService,
        _prefs = prefs ?? SharedPreferences.getInstance,
        _loadAsset = loadAsset ?? rootBundle.loadString;

  final SupabaseSyncService _sync;
  final Future<SharedPreferences> Function() _prefs;
  final Future<String> Function(String assetPath) _loadAsset;

  /// SharedPreferences cache key for the merged calendar JSON.
  static const String cacheKey = 'sakina_dua_windows_v1';

  /// SharedPreferences key holding the epoch-ms of the last SUCCESSFUL remote
  /// fetch — drives the [refreshFromRemote] throttle.
  static const String lastFetchKey = 'sakina_dua_windows_last_fetch_ms';

  /// Minimum spacing between remote fetches. The provider calls
  /// [refreshFromRemote] on every foreground (2 Supabase round-trips each), but
  /// the seed changes ~yearly, so a fetch within this window returns the cache
  /// without hitting the network.
  static const Duration remoteRefreshThrottle = Duration(hours: 6);

  /// In-memory mirror of [lastFetchKey], seeded lazily on first [refreshFromRemote]
  /// so repeated foregrounds in one session don't re-read prefs.
  int? _lastFetchMs;

  /// Bundled cold-start asset (registered under `assets:` in pubspec.yaml).
  static const String bundledAssetPath = 'assets/dua_calendar/dua_windows.json';

  /// Supabase table + meta-table names (public anon-read).
  static const String _table = 'dua_windows';
  static const String _metaTable = 'dua_windows_meta';

  /// The number of days before [DuaCalendar.lastSeededThrough] at which the
  /// health check begins to warn (spec §4 seed-horizon safety).
  static const Duration seedHorizonWarnLead = Duration(days: 90);

  /// Load the calendar, preferring (in order): local cache → bundled asset.
  ///
  /// Does NOT hit the network — call [refreshFromRemote] first (on foreground)
  /// to update the cache. This mirrors the public-catalog bootstrap→refresh
  /// split so a cold offline launch still surfaces dated windows.
  Future<DuaCalendar> load() async {
    final cached = await _readCache();
    final calendar = (cached != null && cached.rows.isNotEmpty)
        ? cached
        : await _readBundledAsset();
    // Seed-horizon check runs on the offline/cold-start path too — not just on
    // [refreshFromRemote] — so an app that never gets a fresh remote fetch still
    // logs the "extend the seed" warning before the feature silently goes blank.
    _warnIfNearHorizon(calendar);
    return calendar;
  }

  /// Fetch the latest rows + sentinel from Supabase and overwrite the cache.
  ///
  /// Degrades silently: on any failure or empty result the existing cache is
  /// preserved and the method returns the currently-loadable calendar. Safe to
  /// call whether or not a Supabase client is initialised.
  Future<DuaCalendar> refreshFromRemote() async {
    // Throttle: skip the network fetch (2 Supabase round-trips) if a successful
    // fetch happened within [remoteRefreshThrottle]. Seeded data changes
    // ~yearly, so serving the cache between foregrounds is safe.
    if (await _isFetchThrottled()) {
      return load();
    }
    try {
      final rows = await _sync.fetchPublicRows(_table, orderBy: 'start_date');
      final metaRows = await _sync.fetchPublicRows(_metaTable, orderBy: 'id');

      if (rows.isEmpty) {
        // Nothing usable from remote — keep whatever we can already load.
        return load();
      }

      final parsedRows = rows.map(DuaCalendarRow.fromMap).toList();
      final lastSeeded = _extractLastSeeded(metaRows);

      final payload = <String, dynamic>{
        'version': 1,
        'last_seeded_through':
            lastSeeded == null ? null : DuaCalendarRow._fmtDate(lastSeeded),
        'rows': parsedRows.map((r) => r.toMap()).toList(),
      };
      await _sync.setPublicCatalogCache(cacheKey, jsonEncode(payload));
      await _recordFetchNow();

      final calendar = DuaCalendar(
        rows: parsedRows,
        lastSeededThrough: lastSeeded,
        fromBundledAsset: false,
      );
      _warnIfNearHorizon(calendar);
      return calendar;
    } catch (e) {
      debugPrint('[DuaWindowRepository] refreshFromRemote failed: $e');
      return load();
    }
  }

  /// True when a successful remote fetch happened within [remoteRefreshThrottle]
  /// of now — the caller should serve the cache instead of hitting the network.
  /// Seeds the in-memory [_lastFetchMs] from prefs on first call.
  Future<bool> _isFetchThrottled() async {
    if (_lastFetchMs == null) {
      try {
        final p = await _prefs();
        _lastFetchMs = p.getInt(lastFetchKey);
      } catch (e) {
        debugPrint('[DuaWindowRepository] _isFetchThrottled read failed: $e');
        return false;
      }
    }
    final last = _lastFetchMs;
    if (last == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= 0 && elapsed < remoteRefreshThrottle.inMilliseconds;
  }

  /// Stamp the last-successful-fetch time in prefs + the in-memory mirror.
  Future<void> _recordFetchNow() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _lastFetchMs = nowMs;
    try {
      final p = await _prefs();
      await p.setInt(lastFetchKey, nowMs);
    } catch (e) {
      debugPrint('[DuaWindowRepository] _recordFetchNow persist failed: $e');
    }
  }

  /// Seed-horizon health check (spec §4): true when [now] is within
  /// [seedHorizonWarnLead] of (or past) the last seeded date, meaning the seed
  /// must be extended before the feature silently goes blank.
  bool isNearSeedHorizon(DuaCalendar calendar, DateTime now) {
    final through = calendar.lastSeededThrough;
    if (through == null) return true;
    return !now.isBefore(through.subtract(seedHorizonWarnLead));
  }

  void _warnIfNearHorizon(DuaCalendar calendar) {
    final now = DateTime.now();
    if (isNearSeedHorizon(calendar, now)) {
      debugPrint(
        '[DuaWindowRepository] WARNING: dua_windows seed horizon '
        '(${calendar.lastSeededThrough}) is within '
        '${seedHorizonWarnLead.inDays}d of now — extend the seed (see TODO.md).',
      );
    }
  }

  Future<DuaCalendar?> _readCache() async {
    try {
      final p = await _prefs();
      final json = p.getString(cacheKey);
      if (json == null || json.isEmpty) return null;
      return _parsePayload(json, fromBundledAsset: false);
    } catch (e) {
      debugPrint('[DuaWindowRepository] _readCache failed: $e');
      return null;
    }
  }

  Future<DuaCalendar> _readBundledAsset() async {
    try {
      final json = await _loadAsset(bundledAssetPath);
      return _parsePayload(json, fromBundledAsset: true);
    } catch (e) {
      debugPrint('[DuaWindowRepository] _readBundledAsset failed: $e');
      return DuaCalendar.empty;
    }
  }

  DuaCalendar _parsePayload(String json, {required bool fromBundledAsset}) {
    final decoded = jsonDecode(json);
    final map = decoded as Map<String, dynamic>;
    final rawRows = (map['rows'] as List<dynamic>? ?? const <dynamic>[]);
    final rows = rawRows
        .map((r) => DuaCalendarRow.fromMap(r as Map<String, dynamic>))
        .toList();
    final through = map['last_seeded_through'] as String?;
    return DuaCalendar(
      rows: rows,
      lastSeededThrough:
          (through == null || through.isEmpty) ? null : _parseDate(through),
      fromBundledAsset: fromBundledAsset,
    );
  }

  DateTime? _extractLastSeeded(List<Map<String, dynamic>> metaRows) {
    if (metaRows.isEmpty) return null;
    final v = metaRows.first['last_seeded_through'] as String?;
    if (v == null || v.isEmpty) return null;
    return _parseDate(v);
  }

  static DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
