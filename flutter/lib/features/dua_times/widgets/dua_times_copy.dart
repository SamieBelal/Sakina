import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';

/// Human-readable copy for the in-app duʿā-times card (spec §9.1).
///
/// The models carry i18n `titleKey`s (e.g. `dua_window.last_third.title`) but no
/// live i18n layer exists yet, so this pure resolver maps window type + urgency
/// to the approved English strings. It is the single place all card copy lives,
/// so extraction to ARB/gen-l10n later touches one file. Every string is warm,
/// CTA-first, and never guarantees acceptance ("a beloved time", not "answered").
///
/// Tone rule (spec §1): times of *hope*, never a promise.
abstract final class DuaTimesCopy {
  /// The short "kicker" eyebrow above the verb on the medium/active card.
  static const String beforeItClosesKicker = 'Closing soon';
  static const String belovedTimeKicker = 'A beloved time';
  static const String comingUpKicker = 'Coming up';

  /// A short, human name for [type] used in the supporting cue line.
  static String windowName(DuaWindowType type) {
    switch (type) {
      case DuaWindowType.lastThirdOfNight:
        return 'the last third of the night';
      case DuaWindowType.fridayHour:
        return 'the Friday hour';
      case DuaWindowType.iftar:
        return 'the iftar moment';
      case DuaWindowType.arafah:
        return 'ʿArafah';
      case DuaWindowType.dhulHijjah10:
        return 'the ten days of Dhul-Ḥijjah';
      case DuaWindowType.laylatAlQadr:
        return 'the last ten nights';
      case DuaWindowType.ramadan:
        return 'Ramadan';
      case DuaWindowType.ashura:
        return 'ʿAshura';
      case DuaWindowType.whiteDays:
        return 'the White Days';
      case DuaWindowType.eid:
        return 'this blessed Eid';
      case DuaWindowType.fridayDay:
        return 'Friday';
    }
  }

  /// The "why this is a beloved time" one-liner shown on the active card.
  static String why(DuaWindowType type) {
    switch (type) {
      case DuaWindowType.lastThirdOfNight:
        return 'The last third of the night — "Who is calling upon Me?"';
      case DuaWindowType.fridayHour:
        return 'The hour on Friday when duʿā is not turned away.';
      case DuaWindowType.iftar:
        return "The fasting person's duʿā at the breaking of the fast.";
      case DuaWindowType.arafah:
        return 'The best of duʿā is the duʿā of the Day of ʿArafah.';
      case DuaWindowType.dhulHijjah10:
        return 'No days are more beloved for good deeds than these ten.';
      case DuaWindowType.laylatAlQadr:
        return 'Seek the Night of Decree in the last ten nights.';
      case DuaWindowType.ramadan:
        return 'A month whose every night carries an answered call.';
      case DuaWindowType.ashura:
        return 'A blessed day — raise your hands in hope.';
      case DuaWindowType.whiteDays:
        return 'The bright nights of the month — a beloved time to ask.';
      case DuaWindowType.eid:
        return 'A day of joy and nearness — turn to Him.';
      case DuaWindowType.fridayDay:
        return 'The best day on which the sun rises is Friday.';
    }
  }

  /// The relative day label for a between-state upcoming window, given days
  /// until it opens: "today", "tomorrow", or "in N days".
  static String relativeDay(int daysUntil) {
    if (daysUntil <= 0) return 'today';
    if (daysUntil == 1) return 'tomorrow';
    return 'in $daysUntil days';
  }

  /// The verb line for the active card. Escalates to a sharper ask under 15m.
  static String activeVerb({required bool lastCall}) =>
      lastCall ? 'Ask before it closes' : 'Make your duʿā';

  /// The between-state verb line.
  static const String betweenVerb = 'Build your duʿā';

  /// The gold CTA pill label.
  static String ctaLabel({required bool between}) =>
      between ? 'Build now →' : 'Ask now →';

  // --- Enable-precise-times banner (shown when location is absent) ---------
  // This is the switch that turns on the whole feature: without location the
  // card can't show a live countdown, and the home/lock WIDGET can NEVER show
  // precise times (an extension can't request location) until the app has
  // computed a located schedule. So the copy states the need plainly.

  /// Headline for the enable-location banner.
  static const String enablePreciseTitle = 'Turn on precise times';

  /// Benefit subline — short and punchy (one line). The necessity is carried by
  /// the prominence of the banner, not a long sentence.
  static const String enablePreciseSubtitle =
      'See the live countdown to each blessed moment.';

  /// The banner's action label.
  static const String enablePreciseCta = 'Turn on';
}

/// Formats a remaining [Duration] as a live `H:MM:SS` / `MM:SS` countdown for
/// the closing/last-call states (spec §9.1 — a live Dart-`Timer` countdown).
String formatCountdown(Duration remaining) {
  if (remaining.isNegative) remaining = Duration.zero;
  final h = remaining.inHours;
  final m = remaining.inMinutes.remainder(60);
  final s = remaining.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:$mm:$ss';
  return '$mm:$ss';
}

/// The window-type JSON value used as an analytics property (matches the
/// `@JsonValue` on [DuaWindowType]). Kept here so the card + tests share it.
String? windowAnalyticsValue(DuaWindow? window) {
  if (window == null) return null;
  return window.type.name;
}
