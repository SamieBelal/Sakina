import 'package:flutter/foundation.dart' show visibleForTesting;
// state_notifier is re-exported by flutter_riverpod (which is a real
// dependency); importing via that path avoids depend_on_referenced_packages
// without adding a redundant pubspec entry.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/gating_service.dart';

/// Shared bypass-flow lifecycle for the 3 notifiers that consume the
/// AI-bypass reservation pattern (reflect, build-a-dua, discover-name).
///
/// Pre-stated extraction rule from `reflect_provider.dart` (pre-refactor):
/// "If a 4th gated feature is added, extract a BypassFlowMixin — three
/// sites is the YAGNI threshold." This mixin is that extraction — it
/// landed when DailyLoopNotifier became the 3rd consumer.
///
/// Lifecycle contract for consumers:
///
/// ```text
///   1. Caller guards re-entry with [bypassInFlight] (and feature-local
///      loading flags like state.screenState == loading).
///   2. Caller invokes [reserveActiveBypass] — sets _submitInFlight, captures
///      the in-flight future, awaits, clears ownership when identical.
///   3. Caller checks `!mounted` AFTER the await. If unmounted, return
///      immediately; the dispose chain owns cancellation.
///   4. On null reservation (rejected), caller writes state.error and
///      returns. The mixin is now back to clean (no active id).
///   5. On non-null reservation, caller invokes [trackActiveBypassReservation]
///      with the returned id, then runs the AI work.
///   6. Caller checks `!mounted` again after the AI work.
///   7. On success → [commitActiveBypassIfAny]. On failure →
///      [cancelActiveBypassIfAny].
///   8. Caller clears [bypassInFlight] in a `finally`, unconditionally.
///   9. Notifier's `dispose()` calls [disposeBypassFlow] BEFORE
///      `super.dispose()`.
/// ```
///
/// All async cleanup wraps `try { ... .ignore(); } catch (_) {}` so app
/// shutdown can't escape unhandled errors. The 15-min orphan cron on the
/// server is the last-resort safety net if Dart `dispose` never runs
/// (e.g., iOS hard-kill).
mixin BypassFlowMixin<S> on StateNotifier<S> {
  /// The gated feature this notifier owns. Used as the cancel arg.
  GatedFeature get bypassFeature;

  String? _activeBypassReservationId;
  Future<BypassReservation?>? _inflightReserveFuture;
  bool _submitInFlight = false;

  @visibleForTesting
  String? get debugActiveBypassReservationId => _activeBypassReservationId;
  @visibleForTesting
  Future<BypassReservation?>? get debugInflightReserveFuture =>
      _inflightReserveFuture;

  /// True if a bypass-funded submit is in flight. Callers should also check
  /// their own loading flags (e.g., `state.checkinLoading`) as appropriate.
  bool get bypassInFlight => _submitInFlight;

  /// Reserve a bypass, tracking the in-flight future for dispose-chain
  /// cleanup. Returns null if rejected (no tokens, cap reached, premium).
  /// Callers MUST check `mounted` after this await before writing state.
  /// On non-null return, caller MUST assign the reservation id via
  /// [trackActiveBypassReservation] before any further awaits.
  Future<BypassReservation?> reserveActiveBypass() async {
    _submitInFlight = true;
    final future = GatingService().reserveBypass(bypassFeature);
    _inflightReserveFuture = future;
    try {
      final reservation = await future;
      if (identical(_inflightReserveFuture, future)) {
        _inflightReserveFuture = null;
      }
      return reservation;
    } catch (_) {
      if (identical(_inflightReserveFuture, future)) {
        _inflightReserveFuture = null;
      }
      rethrow;
    }
  }

  /// Record that the server returned an active reservation. Must be called
  /// before any awaits between [reserveActiveBypass] and the commit/cancel
  /// step, so [disposeBypassFlow] can see the id.
  void trackActiveBypassReservation(String reservationId) {
    _activeBypassReservationId = reservationId;
  }

  /// Unconditional re-entry flag reset. Safe to call after `!mounted` —
  /// instance-field writes don't throw on disposed notifiers (only `state =`
  /// writes do).
  void clearBypassInFlight() {
    _submitInFlight = false;
  }

  /// Mark the in-flight flag for non-bypass code paths (e.g. the standard
  /// gated [submit] that doesn't reserve a bypass). The bypass paths call
  /// [reserveActiveBypass] which flips this internally — this setter exists
  /// so the same `_submitInFlight` flag guards re-entry across all submit
  /// flavors of a notifier, not just the bypass-funded one.
  void markBypassInFlight() {
    _submitInFlight = true;
  }

  /// Fire-and-forget commit of an active bypass reservation. Failures here
  /// are absorbed because the server-side orphan-cleanup cron will rescue a
  /// missed-commit by cancelling the (still-pending) reservation after 15
  /// min — at which point the user already received the AI value, so they
  /// effectively got a free use. Acceptable failure mode.
  Future<void> commitActiveBypassIfAny() async {
    final id = _activeBypassReservationId;
    if (id == null) return;
    _activeBypassReservationId = null;
    await GatingService().commitBypass(id);
  }

  /// Best-effort cancel: a cancel-RPC failure (offline, RLS race) just means
  /// the reservation stays pending until the orphan-cleanup cron picks it
  /// up.
  Future<void> cancelActiveBypassIfAny() async {
    final id = _activeBypassReservationId;
    if (id == null) return;
    _activeBypassReservationId = null;
    await GatingService().cancelBypass(id, bypassFeature);
  }

  /// Call from each consumer's `dispose()` BEFORE `super.dispose()`.
  /// Fires a cancel for either the assigned-but-uncommitted reservation,
  /// or chains one for a still-in-flight reserve future.
  ///
  /// P0-4 covers the post-assignment case (dispose lands while AI work is
  /// running). P1-B covers the pre-assignment case (dispose lands while
  /// the `reserveBypass` RPC is still in flight) — the chained `.then()`
  /// catches the late-resolving reservation and cancels it immediately.
  void disposeBypassFlow() {
    final id = _activeBypassReservationId;
    final inflight = _inflightReserveFuture;
    _activeBypassReservationId = null;
    _inflightReserveFuture = null;
    if (id != null) {
      try {
        GatingService().cancelBypass(id, bypassFeature).ignore();
      } catch (_) {
        // Tearing down; orphan cron will refund.
      }
    } else if (inflight != null) {
      inflight.then((reservation) {
        if (reservation != null) {
          try {
            GatingService()
                .cancelBypass(reservation.reservationId, bypassFeature)
                .ignore();
          } catch (_) {
            // Tearing down; orphan cron will refund.
          }
        }
      }).catchError((_) {
        // Reserve RPC threw — no server-side reservation to cancel.
      });
    }
  }
}
