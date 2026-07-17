import 'package:sakina/features/dua_times/models/dua_window_type.dart';

/// A curated, sourced definition of a RECURRING duʿā-acceptance window.
///
/// This is *metadata* only — copy key, tier, and source reference. The concrete
/// `startUtc`/`endUtc` bounds are resolved at runtime by the `DuaWindowEngine`
/// from prayer times.
///
/// No scripture is fabricated here: [sourceRef] carries the hadith reference
/// verbatim from the design spec §3 tables (per `CLAUDE.md` — content comes from
/// verified sources, never AI generation).
class DuaWindowDefinition {
  const DuaWindowDefinition({
    required this.type,
    required this.tier,
    required this.titleKey,
    required this.sourceRef,
  });

  /// The window category.
  final DuaWindowType type;

  /// Visual + priority weight on the surfaces.
  final DuaWindowTier tier;

  /// i18n copy key for the window title.
  final String titleKey;

  /// Hadith source reference (verbatim from spec §3). Never fabricated.
  final String sourceRef;
}

/// Curated definitions for the RECURRING (location-dependent) windows only.
///
/// Calendar/all-day windows (ʿArafah, Dhul-Ḥijjah 1–10, last-10-nights,
/// Ramadan, ʿAshura, White Days, Eids) are NOT hard-coded here — they come from
/// the seeded server-side `dua_windows` table (spec decision D3/D4), so this
/// file carries only the three recurring windows from spec §3.
///
/// Friday (as a whole day) is a pure device-weekday check with no metadata
/// needed, so it is intentionally absent from this list too.
class DuaWindowCatalog {
  const DuaWindowCatalog._();

  /// Last third of the night — Maghrib→Fajr, final third.
  /// Source: al-Bukhari 1145. Location-dependent.
  static const DuaWindowDefinition lastThirdOfNight = DuaWindowDefinition(
    type: DuaWindowType.lastThirdOfNight,
    tier: DuaWindowTier.hero,
    titleKey: 'dua_window.last_third.title',
    sourceRef: 'al-Bukhari 1145',
  );

  /// The Friday hour — ʿAsr→Maghrib on Friday.
  /// Sources: al-Bukhari 935, Muslim 852; Abu Dawud/Nasa'i "last hour after
  /// ʿAsr". The Friday-ness is calendar; the *hour* is location-dependent.
  static const DuaWindowDefinition fridayHour = DuaWindowDefinition(
    type: DuaWindowType.fridayHour,
    tier: DuaWindowTier.hero,
    titleKey: 'dua_window.friday_hour.title',
    sourceRef: 'al-Bukhari 935, Muslim 852; Abu Dawud/Nasaʾi (the last hour before Maghrib)',
  );

  /// The Friday hero window opens this many minutes before Maghrib. The hadith's
  /// "seek it in the last hour" → the final 60 min before sunset. Anchored to
  /// Maghrib (sunset) ONLY — no ʿAsr, no madhab: the ruling is itself approximate
  /// so a madhab-precise ʿAsr would be false precision (and would force us to
  /// gather the user's madhab).
  static const Duration fridayHourLeadBeforeMaghrib = Duration(minutes: 60);

  /// Iftar moment — ~20 min before Maghrib during Ramadan.
  /// Source: Tirmidhi 3598 (the fasting person's duʿā). Location-dependent.
  static const DuaWindowDefinition iftar = DuaWindowDefinition(
    type: DuaWindowType.iftar,
    tier: DuaWindowTier.special,
    titleKey: 'dua_window.iftar.title',
    sourceRef: 'Tirmidhi 3598',
  );

  /// The iftar window opens this many minutes before Maghrib (spec §3).
  static const Duration iftarLeadBeforeMaghrib = Duration(minutes: 20);

  /// Soft location-absent framing — "the depths of the night", keyed to the
  /// device clock, justified by Muslim 757 ("an hour each night"). Humble copy
  /// only, never a precise claim (spec §3). Used by the engine when location is
  /// unavailable; carried here so the copy + source live in one place.
  static const DuaWindowDefinition softNight = DuaWindowDefinition(
    type: DuaWindowType.lastThirdOfNight,
    tier: DuaWindowTier.soft,
    titleKey: 'dua_window.soft_night.title',
    sourceRef: 'Muslim 757',
  );
}
