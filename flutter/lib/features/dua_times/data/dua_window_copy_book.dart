import 'package:sakina/features/dua_times/models/dua_window_type.dart';

/// The `title` + `body` copy for a CALENDAR-window local notification.
class DuaWindowCopy {
  const DuaWindowCopy({required this.title, required this.body});

  final String title;
  final String body;
}

/// Per-window-type notification copy for the CALENDAR (all-day,
/// location-independent) windows that the LOCAL scheduler
/// ([DuaNotificationScheduler]) fires (`white_days`, `arafah`, `ashura`,
/// `dhul_hijjah_10`, `laylat_al_qadr`, `ramadan`, `eid`, `friday_day`).
///
/// The seeded `dua_windows` rows carry raw i18n *keys* in `title_key`
/// (e.g. `dua_window.white_days`), NOT display strings — passing those straight
/// into a notification would show the literal key. This map is the resolver: it
/// mirrors [DuaPreciseNotificationCopyBook] (the server-push precise copy) so
/// the two notification paths share one voice and one lookup shape.
///
/// i18n-ready (per `CLAUDE.md`): every string is a plain, extractable English
/// sentence. **No Arabic/English mixing in a single string** — the
/// transliterated terms here ("ʿArafah", "duʿā", "Laylat al-Qadr") are English
/// spellings, not Arabic script, so there is no RTL bleed. When the localization
/// slice lands, swap [resolve] to read from the app's message catalog keyed by
/// [DuaWindowType.wireName]; the scheduler contract does not change.
class DuaWindowCopyBook {
  const DuaWindowCopyBook._();

  /// Fallback copy for an unmapped (future/unknown) calendar window type, so the
  /// scheduler still fires a real, warm string rather than a raw key.
  static const DuaWindowCopy fallback = DuaWindowCopy(
    title: 'A blessed time for duʿā is here',
    body: 'Take a moment to turn to Allah with what is on your heart.',
  );

  /// The English defaults. The map key is [DuaWindowType] (mirroring
  /// [DuaPreciseNotificationCopyBook]); the `eid` type covers both Eids with one
  /// warm line even though the seed carries `eid_fitr` / `eid_adha` title keys.
  static const Map<DuaWindowType, DuaWindowCopy> _copy = {
    DuaWindowType.whiteDays: DuaWindowCopy(
      title: 'The White Days are here',
      body: 'The bright nights of the month — a beautiful time to fast and to '
          'make duʿā.',
    ),
    DuaWindowType.arafah: DuaWindowCopy(
      title: 'Today is the Day of ʿArafah',
      body: 'The best day of the year for duʿā. Ask Allah for all that you '
          'hope for.',
    ),
    DuaWindowType.ashura: DuaWindowCopy(
      title: 'Today is the Day of ʿAshura',
      body: 'A blessed day to fast and to turn to Allah in duʿā.',
    ),
    DuaWindowType.dhulHijjah10: DuaWindowCopy(
      title: 'The ten days of Dhul-Hijjah',
      body: 'No days are more beloved to Allah for good deeds. Make the most of '
          'them with duʿā.',
    ),
    DuaWindowType.laylatAlQadr: DuaWindowCopy(
      title: 'The last ten nights are here',
      body: 'Seek the Night of Power. Turn to Allah — a night better than a '
          'thousand months.',
    ),
    DuaWindowType.ramadan: DuaWindowCopy(
      title: 'The blessed month of Ramadan',
      body: 'A month of mercy and answered duʿā. Keep your heart close to Allah '
          'today.',
    ),
    DuaWindowType.eid: DuaWindowCopy(
      title: 'A blessed Eid to you',
      body: 'A day of gratitude and joy. Remember Allah and ask Him for good.',
    ),
    DuaWindowType.fridayDay: DuaWindowCopy(
      title: 'It is the blessed day of Jumuʿah',
      body: 'Friday carries an hour when duʿā is answered. Send blessings upon '
          'the Prophet and ask Allah today.',
    ),
  };

  /// The calendar window types this copy book covers (the ones the LOCAL
  /// scheduler fires — precise/location-dependent types go through
  /// [DuaPreciseNotificationCopyBook] instead).
  static const List<DuaWindowType> calendarTypes = [
    DuaWindowType.whiteDays,
    DuaWindowType.arafah,
    DuaWindowType.ashura,
    DuaWindowType.dhulHijjah10,
    DuaWindowType.laylatAlQadr,
    DuaWindowType.ramadan,
    DuaWindowType.eid,
    DuaWindowType.fridayDay,
  ];

  /// Resolve the copy for [type]. Never null — an unmapped type returns
  /// [fallback] so the scheduler always fires a real string, never a raw key.
  /// When the i18n slice lands this is the single swap-point for a localized
  /// lookup keyed by `type.wireName`.
  static DuaWindowCopy resolve(DuaWindowType type) => _copy[type] ?? fallback;
}
