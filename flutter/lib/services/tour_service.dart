import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifies one of the four tour surfaces.
enum TourKey { home, collection, journal, duas }

/// Per-user, versioned tour-seen flag store on SharedPreferences.
///
/// Versioning rule: bump the version for a single [TourKey] to re-trigger
/// just that tour for every user — other tours keep their seen flags. This
/// allows iterating on individual tour copy without spamming re-shows of
/// every tour.
class TourService {
  static const Map<TourKey, int> _versions = {
    TourKey.home: 1,
    TourKey.collection: 1,
    TourKey.journal: 1,
    TourKey.duas: 1,
  };

  String _key(String userId, TourKey k) =>
      'tour_seen_${userId}_${k.name}_v${_versions[k]!}';

  Future<bool> shouldShow(String userId, TourKey k) async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool(_key(userId, k)) ?? false);
  }

  Future<void> markSeen(String userId, TourKey k) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(userId, k), true);
  }

  /// Resets all four tour-seen flags for [userId]. Used by Settings "Replay
  /// app tour" and the in-app guided-sequence trigger.
  Future<void> resetAll(String userId) async {
    final p = await SharedPreferences.getInstance();
    for (final k in TourKey.values) {
      await p.remove(_key(userId, k));
    }
  }
}

final tourServiceProvider = Provider<TourService>((_) => TourService());

/// Set true during the sequenced replay walk (Home → Collection → Journal →
/// Duas). Each surface's tour `onComplete` checks this and auto-routes to
/// the next when true; final surface sets back to false. Riverpod state
/// (not SharedPreferences) so app restart resets — no stuck flag from
/// force-quit mid-walk.
final guidedSequenceActiveProvider = StateProvider<bool>((_) => false);

/// Single source of truth for tour copy. Referenced by feature wiring +
/// guarded by `test/features/tour/copy_table_test.dart`.
class TourCopy {
  TourCopy._();

  // Home tour
  static const homeStep1 =
      "Tap here daily. Today's Name unlocks after your check-in.";
  static const homeStep2 =
      "Your streak grows with every reflection. Don't break it.";
  static const homeStep3 = 'Cards, Journal, Duas — your library lives here.';

  // Empty states
  static const collectionEmptyCaption =
      'This is your first Name. Earn the next with tomorrow\'s check-in.';
  static const journalEmptyTitle = 'Reflect on today\'s Name.';
  static const journalEmptyBody =
      'Your entries stay private. Only you can read them.';
  static const journalEmptyCta = 'Write first entry';

  // Duas
  static const duasStep1 = 'Tap ♡ to save duas you love. Browse them anytime.';

  // Settings
  static const settingsReplayLabel = 'Replay app tour';

  // Win-back push (E5)
  static const winBackPushTitle = 'Want me to show you around?';
  static const winBackPushBody = 'Tap to retake the Sakina tour — 30 seconds.';
}
