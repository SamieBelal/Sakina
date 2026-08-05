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

/// How late the server will still deliver an instant, mirroring
/// `DUA_LATE_TOLERANCE_MS` in `supabase/functions/send-scheduled-notifications/
/// index.ts`. **These two values must track each other**: this is the width of
/// the band the client refuses to delete, and the server's willingness to fire
/// inside it is exactly what makes deleting there unsafe.
const Duration kDuaLateTolerance = Duration(hours: 1);

/// How a [DuaPreciseSyncService.sync] resolved — surfaced so the notification
/// gate can emit the `dua_notif_synced` observability event (the denominator
/// for the server-side `notification_sent{type: dua_window}`).
enum DuaPreciseSyncOutcome {
  /// No signed-in user — nothing to scope rows to (no analytics).
  skipped,

  /// Location was unavailable this run, so we left the user's rows alone.
  ///
  /// **This used to be [cleared], and that was the costlier half of the 2026-08
  /// re-nag bug.** A momentary permission lapse deleted all 30 days of the
  /// user's future instants *and* their `sent_at` history, and the server has no
  /// prayer math to rebuild them — so their precise pushes simply stopped,
  /// silently. The rows are still correct prayer times; the edge function
  /// independently re-checks `push_enabled AND notify_dua_windows` before
  /// sending, so leaving them in place cannot push to someone who opted out.
  retained,

  /// The user's precise rows were retired because the engine genuinely produced
  /// no instants *with a location in hand*. Near-unreachable in practice
  /// (`friday_hour` recurs weekly, so a 30-day horizon always holds ≥4), which
  /// is the point: after 2026-08 any `cleared` is a real signal.
  cleared,

  /// [count] rows were written for the new sync version.
  synced,

  /// A backend write failed (prior rows were kept, not dropped).
  failed,
}

/// The result of a precise sync: the [outcome] plus, on [DuaPreciseSyncOutcome
/// .synced], the [count] of precise instants written and the [syncVersion] they
/// were written under.
class DuaPreciseSyncResult {
  const DuaPreciseSyncResult(
    this.outcome, {
    this.count = 0,
    this.syncVersion,
    this.reason,
    this.locationPresent = false,
  });

  final DuaPreciseSyncOutcome outcome;
  final int count;

  /// Why this outcome happened: `no_location` | `no_copy` | `no_instants`.
  /// Emitted on `dua_notif_synced` so `retained` can be split into "the user's
  /// location lapsed" versus "a copy-book bug".
  final String? reason;

  /// Whether this run actually observed a location. The gate persists it to
  /// detect the false→true transition that must bypass the sync throttle.
  final bool locationPresent;

  /// The `sync_version` the rows were written under (null unless [outcome] is
  /// [DuaPreciseSyncOutcome.synced]). Stamped onto `dua_notif_synced` so the
  /// client sync can be joined to the server `notification_sent{dua_window}`
  /// (whose rows carry the same version) — per-sync attribution, not just
  /// population-level.
  final int? syncVersion;
}

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

  /// Insert the [rows] (all stamped with the SAME new `sync_version`) as an
  /// UPSERT on the `(user_id, window_type, fire_utc)` unique constraint —
  /// re-synced instants have their `sync_version`/`title`/`body` UPDATED (so
  /// they survive the delete-below), and duplicate instants are impossible.
  /// Returns true on success.
  Future<bool> insertRows(List<Map<String, dynamic>> rows);

  /// Retire [userId]'s rows below [belowVersion] — run AFTER the new rows are
  /// inserted — while never touching instants inside
  /// `[nowUtc - lateTolerance, nowUtc]`.
  ///
  /// That protected band is what makes a double-send structurally impossible on
  /// this path. A row in it is either about to be picked up by the next cron
  /// tick (delete it and the push is silently lost) or has just been sent
  /// (delete it and the `sent_at` that blocks a re-send goes with it). Rows the
  /// engine could resurrect are exactly the ones in that band, and they are
  /// exactly the ones we never delete.
  Future<bool> deleteSupersededRows(
    String userId,
    int belowVersion, {
    required DateTime nowUtc,
    required Duration lateTolerance,
  });

  /// Retire only [userId]'s FUTURE rows (`fire_utc > fromUtc`), leaving fired
  /// history and its `sent_at` stamps intact.
  Future<bool> deleteFutureRowsForUser(String userId, DateTime fromUtc);

  /// Delete ALL of [userId]'s precise-notification rows.
  ///
  /// The ONLY caller is [DuaPreciseSyncService.clear] — an explicit opt-out
  /// (the Settings toggle or a push opt-out). Location being unavailable is not
  /// an opt-out and must never reach here; see [DuaPreciseSyncOutcome.retained].
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
      // UPSERT on the (user_id, window_type, fire_utc) unique constraint,
      // UPDATING sync_version/title/body on conflict. Re-syncing the same
      // instants (the normal case) bumps their version so they survive the
      // subsequent delete-below-version instead of colliding and failing the
      // batch (which a plain insert would, emptying the schedule). Duplicate
      // instants are then physically impossible, so the sync race is benign.
      _sync.batchUpsertRows(
        kDuaPreciseNotificationsTable,
        rows,
        onConflict: 'user_id,window_type,fire_utc',
        updateOnConflict: true,
      );

  @override
  Future<bool> deleteSupersededRows(
    String userId,
    int belowVersion, {
    required DateTime nowUtc,
    required Duration lateTolerance,
  }) =>
      _sync.deleteRowsBelow(
        kDuaPreciseNotificationsTable,
        userId,
        column: 'sync_version',
        value: belowVersion,
        protectColumn: 'fire_utc',
        protectFromIso:
            nowUtc.subtract(lateTolerance).toUtc().toIso8601String(),
        protectToIso: nowUtc.toUtc().toIso8601String(),
      );

  @override
  Future<bool> deleteFutureRowsForUser(String userId, DateTime fromUtc) =>
      _sync.deleteRowsAfter(
        kDuaPreciseNotificationsTable,
        userId,
        column: 'fire_utc',
        isoValue: fromUtc.toUtc().toIso8601String(),
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
/// version, UPSERTS the fresh rows at the new version, and only THEN deletes the
/// user's rows at any lower version. Insert-before-delete means the user is
/// never left with zero scheduled rows mid-run — the mirror of the local id-band
/// targeted cancel. A blind delete-all-then-insert (which could drop a due push
/// if the process died between the two calls) is deliberately avoided.
///
/// The `(user_id, window_type, fire_utc)` UNIQUE constraint
/// (`20260717122000_dua_precise_notifications_unique_instant.sql`) now
/// GUARANTEES no duplicate-instant rows: the upsert-on-conflict UPDATES
/// `sync_version`/`title`/`body`, so re-syncing the same instants (the normal
/// case — same prayer times every sync) bumps them to the new version and they
/// survive the delete-below, while stale instants keep the old version and are
/// retired. This makes the concurrent-sync race (two devices / a fast double
/// foreground both reading `prior=N` and inserting at `N+1`) BENIGN — the two
/// runs converge on one row per instant instead of duplicating it. The
/// server-side dedup in the enqueue cron is now belt-and-suspenders, not the
/// primary guard against duplicate pushes (code-review P2-1).
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
  /// - No location (permission absent / no cached fix) → retain existing
  ///   precise rows. Location access can be temporary, so clearing a valid
  ///   schedule would leave the user without notifications when access returns.
  ///
  /// Never throws — returns a [DuaPreciseSyncResult] describing the outcome (so
  /// the gate can emit `dua_notif_synced`); [DuaPreciseSyncOutcome.failed] on
  /// any error.
  Future<DuaPreciseSyncResult> sync() async {
    // Tracked outside the try so the catch-all can report it honestly. Saying
    // `false` for a located user makes the gate see a false→true transition on
    // every subsequent foreground and sync forever.
    var locationPresent = false;
    try {
      final userId = _backend.currentUserId;
      if (userId == null) {
        return const DuaPreciseSyncResult(DuaPreciseSyncOutcome.skipped);
      }

      final now = _clock().toUtc();
      final location = await _resolveLocation();
      locationPresent = location != null;

      // No location this run → do NOTHING. Not a delete, not a write.
      //
      // This is the fix for the costlier half of the 2026-08 bug: a momentary
      // permission lapse used to wipe 30 days of correct prayer times plus the
      // `sent_at` history, and nothing server-side can rebuild them. An absent
      // location is a temporary condition, not an instruction.
      if (location == null) {
        return const DuaPreciseSyncResult(
          DuaPreciseSyncOutcome.retained,
          reason: 'no_location',
        );
      }

      final instants = await _engine.computePreciseInstants(
        now: _clock(),
        location: location,
        nightThirdPolicy: _nightThirdPolicy,
      );

      // Located, but the horizon genuinely produced nothing → retire the future
      // so we don't leave stale pushes enqueued. History is left alone.
      if (instants.isEmpty) {
        await _backend.deleteFutureRowsForUser(userId, now);
        return const DuaPreciseSyncResult(
          DuaPreciseSyncOutcome.cleared,
          reason: 'no_instants',
          locationPresent: true,
        );
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

      // Every instant resolved to no copy. That is a copy-book bug, not a user
      // signal, so it must not be destructive.
      if (rows.isEmpty) {
        return const DuaPreciseSyncResult(
          DuaPreciseSyncOutcome.retained,
          reason: 'no_copy',
          locationPresent: true,
        );
      }

      // Insert the NEW version's rows first…
      final inserted = await _backend.insertRows(rows);
      // …then retire the previous version(s). If the insert failed we do NOT
      // delete — better to keep the (possibly stale) prior rows than to leave
      // the user with nothing scheduled.
      if (!inserted) {
        return const DuaPreciseSyncResult(
          DuaPreciseSyncOutcome.failed,
          locationPresent: true,
        );
      }
      await _backend.deleteSupersededRows(
        userId,
        nextVersion,
        nowUtc: now,
        lateTolerance: kDuaLateTolerance,
      );
      return DuaPreciseSyncResult(
        DuaPreciseSyncOutcome.synced,
        count: rows.length,
        syncVersion: nextVersion,
        locationPresent: true,
      );
    } catch (error) {
      debugPrint('[DuaPreciseSyncService] sync failed: $error');
      return DuaPreciseSyncResult(
        DuaPreciseSyncOutcome.failed,
        locationPresent: locationPresent,
      );
    }
  }

  /// Delete all of the current user's precise rows (toggle-off / opt-out).
  /// Fulfils the toggle-off symmetry (plan §6): turning `notify_dua_windows`
  /// off stops server pushes by clearing the synced rows.
  ///
  /// This is the ONLY delete-all in the feature, and it is deliberately
  /// unconditional: an explicit opt-out should leave nothing behind. Unlike
  /// [sync], it does not protect the late-tolerance band, so a user who toggles
  /// duʿā windows off and back on within an hour of a window firing — on a
  /// device whose clock lags the server enough for the engine to still treat
  /// that instant as future — could get one duplicate buzz. It needs a
  /// deliberate double-toggle plus clock skew; accepted rather than trading it
  /// for up to an hour of retained data after an opt-out.
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
