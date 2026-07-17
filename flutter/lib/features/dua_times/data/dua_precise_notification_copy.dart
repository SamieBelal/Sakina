import 'package:sakina/features/dua_times/models/dua_window_type.dart';

/// The `title` + `body` copy for a precise-window push notification.
class DuaPreciseNotificationCopy {
  const DuaPreciseNotificationCopy({required this.title, required this.body});

  final String title;
  final String body;
}

/// Per-window-type notification copy for the SERVER-PUSH precise windows
/// (`last_third_of_night`, `friday_hour`, `iftar`).
///
/// These are resolved **client-side** (so they land in the user's language once
/// the i18n layer wires a localized lookup here) and stored verbatim in each
/// synced `dua_precise_notifications` row for the server to send as-is (plan §4 /
/// A4). Keeping them in ONE map keyed by window type is the single source of
/// truth for the precise-push voice.
///
/// i18n-ready (per `CLAUDE.md`): every string is a plain, extractable English
/// sentence. **No Arabic/English mixing in a single string** — the transliterated
/// terms here ("last third of the night", "Friday", "iftar") are English words,
/// not Arabic script, so there is no RTL bleed. When the localization slice
/// lands, swap [resolve] to read from the app's message catalog keyed by
/// [DuaWindowType.wireName]; the row-write contract does not change.
class DuaPreciseNotificationCopyBook {
  const DuaPreciseNotificationCopyBook._();

  /// The English defaults. The map key is [DuaWindowType.wireName] so a future
  /// localized override can be looked up by the same stable key.
  static const Map<DuaWindowType, DuaPreciseNotificationCopy> _copy = {
    DuaWindowType.lastThirdOfNight: DuaPreciseNotificationCopy(
      title: 'The last third of the night is here',
      body: 'A time when duʿās are answered. Turn to Allah with what is on '
          'your heart.',
    ),
    DuaWindowType.fridayHour: DuaPreciseNotificationCopy(
      title: 'The hour of Friday has come',
      body: 'The final hour before sunset on Friday is a time of accepted '
          'duʿā. Make yours now.',
    ),
    DuaWindowType.iftar: DuaPreciseNotificationCopy(
      title: 'Your duʿā at iftar is not turned away',
      body: 'As you break your fast, ask Allah — the fasting person’s '
          'duʿā is answered.',
    ),
  };

  /// The precise-push window types this copy book covers (the only three that
  /// take the server-push path).
  static const List<DuaWindowType> preciseTypes = [
    DuaWindowType.lastThirdOfNight,
    DuaWindowType.fridayHour,
    DuaWindowType.iftar,
  ];

  /// Resolve the copy for [type]. Returns null for non-precise types (the caller
  /// should never sync those). When the i18n slice lands this is the single
  /// swap-point for a localized lookup keyed by `type.wireName`.
  static DuaPreciseNotificationCopy? resolve(DuaWindowType type) => _copy[type];
}
