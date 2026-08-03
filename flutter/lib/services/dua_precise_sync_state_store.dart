import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the last precise sync did, remembered across launches.
@immutable
class DuaPreciseSyncState {
  const DuaPreciseSyncState({this.lastSyncedAt, this.lastLocationPresent});

  /// When a sync last *settled* (UTC). Null means "never synced on this device",
  /// which always forces a run.
  final DateTime? lastSyncedAt;

  /// Whether that run saw a location. Null when unknown.
  ///
  /// This is the load-bearing field: a false→true change is the moment a user
  /// finally granted, and it must reach the server immediately rather than
  /// waiting out a 6-hour throttle.
  final bool? lastLocationPresent;
}

/// Persistence seam for [DuaPreciseSyncState] — plain Dart, no Riverpod, so the
/// gate stays unit-testable (per `CLAUDE.md`, services carry no Riverpod).
abstract class DuaPreciseSyncStateStore {
  Future<DuaPreciseSyncState> read();
  Future<void> write(DuaPreciseSyncState state);
  Future<void> clear();
}

/// SharedPreferences-backed [DuaPreciseSyncStateStore].
///
/// Deliberately **not** user-scoped: the throttle is a property of this device's
/// last round-trip, not of a person, and `lastSyncedAt` leaking across a user
/// switch would at worst delay one sync by 6h. `sign-out` already calls
/// `gate.clear()`, which clears this.
class SharedPreferencesDuaPreciseSyncStateStore
    implements DuaPreciseSyncStateStore {
  SharedPreferencesDuaPreciseSyncStateStore({
    Future<SharedPreferences> Function()? prefs,
  }) : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  static const String lastSyncedAtKey = 'dua_precise_sync_last_at_ms';
  static const String lastLocationPresentKey =
      'dua_precise_sync_last_location_present';

  @override
  Future<DuaPreciseSyncState> read() async {
    try {
      final p = await _prefs();
      final ms = p.getInt(lastSyncedAtKey);
      return DuaPreciseSyncState(
        lastSyncedAt: ms == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        lastLocationPresent: p.getBool(lastLocationPresentKey),
      );
    } catch (e) {
      debugPrint('[DuaPreciseSyncStateStore] read failed: $e');
      // Unknown state forces a sync, which is the safe direction.
      return const DuaPreciseSyncState();
    }
  }

  @override
  Future<void> write(DuaPreciseSyncState state) async {
    try {
      final p = await _prefs();
      final at = state.lastSyncedAt;
      if (at == null) {
        await p.remove(lastSyncedAtKey);
      } else {
        await p.setInt(lastSyncedAtKey, at.toUtc().millisecondsSinceEpoch);
      }
      final present = state.lastLocationPresent;
      if (present == null) {
        await p.remove(lastLocationPresentKey);
      } else {
        await p.setBool(lastLocationPresentKey, present);
      }
    } catch (e) {
      debugPrint('[DuaPreciseSyncStateStore] write failed: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final p = await _prefs();
      await p.remove(lastSyncedAtKey);
      await p.remove(lastLocationPresentKey);
    } catch (e) {
      debugPrint('[DuaPreciseSyncStateStore] clear failed: $e');
    }
  }
}
