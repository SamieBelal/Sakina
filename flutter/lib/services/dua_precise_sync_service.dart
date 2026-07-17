import 'package:flutter/foundation.dart';

import 'package:sakina/features/dua_times/data/dua_precise_notification_copy.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

/// The Supabase table that holds each user's synced precise-window fire
/// instants. The Supabase-side agent owns the DDL + RLS; the client only writes
/// its own rows (RLS scopes reads/writes to `auth.uid()`).
const String kDuaPreciseNotificationsTable = 'dua_precise_notifications';

/// The narrow persistence surface the sync service needs, so it can be unit
/// tested against an in-memory fake without a live Supabase client. The real
/// implementation ([_SupabaseBackend]) routes every call through the existing
/// [SupabaseSyncService] layer (per `CLAUDE.md` — no direct Supabase in
/// widgets/business logic seams; the write goes through the service layer).
abstract class DuaPreciseSyncBackend {
  /// The current authenticated user id, or null when signed out.
  String? get currentUserId;

  /// The largest existing `sync_version` for [userId], or null when the user
  /// has no rows yet.
  Future<int?> currentSyncVersion(String userId);

  /// Insert the [rows] (all stamped with the SAME new `sync_version`). Returns
  /// true on success.
  Future<bool> insertRows(List<Map<String, dynamic>> rows);

  /// Delete [userId]'s rows whose `sync_version` is strictly below
  /// [belowVersion] — the retire-the-old-version step, run AFTER the new rows
  /// are inserted.
  Future<bool> deleteRowsBelowVersion(String userId, int belowVersion);

  /// Delete ALL of [userId]'s precise-notification rows (toggle-off / opt-out).
  Future<bool> deleteAllForUser(String userId);
}

/// Production [DuaPreciseSyncBackend] over the shared [SupabaseSyncService].
class _SupabaseBackend implements DuaPreciseSyncBackend {
  const _SupabaseBackend();

  SupabaseSyncService get _sync => supabaseSyncService;

  @override
  String? get currentUserId => _sync.currentUserId;

  @override
  Future<int?> currentSyncVersion(String userId) => _sync.fetchMaxInt(
        kDuaPreciseNotificationsTable,
        userId,
        column: 'sync_version',
      );

  @override
  Future<bool> insertRows(List<Map<String, dynamic>> rows) =>
      _sync.batchInsertRows(kDuaPreciseNotificationsTable, rows);

  @override
  Future<bool> deleteRowsBelowVersion(String userId, int belowVersion) =>
      _sync.deleteRowsBelow(
        kDuaPreciseNotificationsTable,
        userId,
        column: 'sync_version',
        value: belowVersion,
      );

  @override
  Future<bool> deleteAllForUser(String userId) => _sync.deleteRow(
        kDuaPreciseNotificationsTable,
        'user_id',
        userId,
      );
}

/// Syncs the on-device–computed PRECISE-window fire instants to the server-push
/// table (plan §4 client-sync). This is the client half of the hybrid delivery:
/// the calendar windows are scheduled locally by `DuaNotificationScheduler`;
/// the three precise windows (last-third-of-night, Friday hour, iftar) are
/// enqueued server-side from the rows this service writes.
///
/// **Privacy (plan §5):** only derived `fire_utc` timestamps + localized copy
/// leave the device — never the raw lat/lon. Location is resolved on-device and
/// consumed by the engine; it is not transmitted.
///
/// **Atomic sync-by-`sync_version` (plan Risk 2):** each [sync] bumps the
/// version, INSERTS the fresh rows at the new version, and only THEN deletes the
/// user's rows at any lower version. Insert-before-delete means the user is
/// never left with zero scheduled rows mid-run — the mirror of the local id-band
/// targeted cancel. A blind delete-all-then-insert (which could drop a due push
/// if the process died between the two calls) is deliberately avoided.
///
/// A plain service — NO Riverpod (per `CLAUDE.md`). The engine, location service,
/// backend, and clock are injected so it is deterministic + unit-testable.
/// Every public method degrades silently on error: a sync failure must never
/// crash or surface to the user.
class DuaPreciseSyncService {
  DuaPreciseSyncService({
    required DuaWindowEngine engine,
    required LocationService locationService,
    DuaPreciseSyncBackend? backend,
    DateTime Function()? clock,
    NightThirdFatiguePolicy nightThirdPolicy =
        NightThirdFatiguePolicy.specialNightsOnly,
  })  : _engine = engine,
        _location = locationService,
        _backend = backend ?? const _SupabaseBackend(),
        _clock = clock ?? DateTime.now,
        _nightThirdPolicy = nightThirdPolicy;

  final DuaWindowEngine _engine;
  final LocationService _location;
  final DuaPreciseSyncBackend _backend;
  final DateTime Function() _clock;
  final NightThirdFatiguePolicy _nightThirdPolicy;

  /// Compute the 30-day precise horizon and sync it into
  /// `dua_precise_notifications` atomically by `sync_version`.
  ///
  /// - No signed-in user → no-op (nothing to scope rows to).
  /// - No location (permission absent / no cached fix) → the computed instant
  ///   list is empty; we treat that as "clear my precise rows" so a user who
  ///   revoked location stops getting precise pushes (mirrors the card degrade).
  ///
  /// Never throws — returns silently on any failure.
  Future<void> sync() async {
    try {
      final userId = _backend.currentUserId;
      if (userId == null) return;

      final location = await _resolveLocation();
      final instants = await _engine.computePreciseInstants(
        now: _clock(),
        location: location,
        nightThirdPolicy: _nightThirdPolicy,
      );

      // No instants (no location, or the horizon genuinely produced none) →
      // retire everything so we don't leave stale pushes enqueued.
      if (instants.isEmpty) {
        await _backend.deleteAllForUser(userId);
        return;
      }

      final priorVersion = await _backend.currentSyncVersion(userId) ?? 0;
      final nextVersion = priorVersion + 1;

      final rows = <Map<String, dynamic>>[];
      for (final instant in instants) {
        final copy = DuaPreciseNotificationCopyBook.resolve(instant.type);
        // Only the three precise types have copy; the engine never emits others,
        // but guard so a stray type is dropped rather than written with no body.
        if (copy == null) continue;
        rows.add(<String, dynamic>{
          'user_id': userId,
          'window_type': instant.type.wireName,
          'fire_utc': instant.fireUtc.toUtc().toIso8601String(),
          'sync_version': nextVersion,
          'title': copy.title,
          'body': copy.body,
        });
      }

      if (rows.isEmpty) {
        await _backend.deleteAllForUser(userId);
        return;
      }

      // Insert the NEW version's rows first…
      final inserted = await _backend.insertRows(rows);
      // …then retire the previous version(s). If the insert failed we do NOT
      // delete — better to keep the (possibly stale) prior rows than to leave
      // the user with nothing scheduled.
      if (inserted) {
        await _backend.deleteRowsBelowVersion(userId, nextVersion);
      }
    } catch (error) {
      debugPrint('[DuaPreciseSyncService] sync failed: $error');
    }
  }

  /// Delete all of the current user's precise rows (toggle-off / opt-out).
  /// Fulfils the toggle-off symmetry (plan §6): turning `notify_dua_windows`
  /// off stops server pushes by clearing the synced rows.
  Future<void> clear() async {
    try {
      final userId = _backend.currentUserId;
      if (userId == null) return;
      await _backend.deleteAllForUser(userId);
    } catch (error) {
      debugPrint('[DuaPreciseSyncService] clear failed: $error');
    }
  }

  Future<EngineLocation?> _resolveLocation() async {
    try {
      // Never PROMPT here — the sync runs on background triggers (opt-in,
      // foreground-resume, location/tz change), not an explicit user tap. A
      // cached/granted fix is used; absence degrades to no precise rows.
      final coarse = await _location.getCoarseLocation();
      if (coarse == null) return null;
      return EngineLocation(lat: coarse.lat, lon: coarse.lon);
    } catch (error) {
      debugPrint('[DuaPreciseSyncService] resolveLocation failed: $error');
      return null;
    }
  }
}
