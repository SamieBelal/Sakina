/// Translation map from `collectible_names.json` canonical transliterations
/// (e.g. `Al-Lateef`, `Ar-Raheem`) to the short-form anchor `name_key` slugs
/// used by `assets/content/name_anchors.json` (e.g. `al-latif`, `ar-rahim`).
///
/// Built empirically: the original 32 anchors used handcrafted shorter
/// spellings that don't derive naively from `lowercase+kebab(transliteration)`.
/// Where the naive slug matches the anchor slug (the majority), the entry
/// still appears here for completeness so consumers don't need to know which
/// transliterations are special.
///
/// Source of truth for canonical transliterations: `collectible_names.json`.
/// Source of truth for anchor slugs: `assets/content/name_anchors.json`.
/// Coverage pinned by `test/content/name_anchors_coverage_test.dart` (every
/// transliteration here must resolve to an existing anchor `name_key`).
///
/// `Allah` (id=1) is included so consumers can iterate the full list; it
/// maps to the conventional slug `allah` but has NO entry in name_anchors.json
/// because it is a proper Name, not an attribute Name. Callers must handle
/// the `allah` slug explicitly if they need a fallback.
library;

const Map<String, String> transliterationToAnchorSlug = {
  'Allah': 'allah',
  'Ar-Rahman': 'ar-rahman',
  'Ar-Raheem': 'ar-rahim',
  'Al-Malik': 'al-malik',
  'Al-Quddus': 'al-quddus',
  'As-Salam': 'as-salam',
  'Al-Mumin': 'al-mumin',
  'Al-Azeez': 'al-azeez',
  'Al-Jabbar': 'al-jabbar',
  'Al-Khaliq': 'al-khaliq',
  'Al-Ghaffar': 'al-ghaffar',
  'Al-Wahhab': 'al-wahhab',
  'Ar-Razzaq': 'ar-razzaq',
  'Al-Aleem': 'al-aleem',
  'Al-Hayy': 'al-hayy',
  'Al-Qayyum': 'al-qayyum',
  'An-Nur': 'an-nur',
  'Al-Muhaymin': 'al-muhaymin',
  'Al-Mutakabbir': 'al-mutakabbir',
  'Al-Bari': 'al-bari',
  'Al-Musawwir': 'al-musawwir',
  'Al-Qahhar': 'al-qahhar',
  'Al-Fattah': 'al-fattah',
  'Al-Qabid': 'al-qabid',
  'Al-Basit': 'al-basit',
  'Al-Hakeem': 'al-hakim',
  'Al-Wadud': 'al-wadud',
  'Ash-Shakur': 'ash-shakur',
  'Al-Haleem': 'al-haleem',
  'Al-Kareem': 'al-karim',
  'At-Tawwab': 'at-tawwab',
  'As-Sabur': 'as-sabur',
  'Al-Hadi': 'al-hadi',
  'As-Samad': 'as-samad',
  'Al-Wakeel': 'al-wakil',
  'Al-Lateef': 'al-latif',
  'Al-Mujeeb': 'al-mujib',
  'Ash-Shafi': 'ash-shafi',
  'Al-Hafeez': 'al-hafeez',
  'Ar-Raqeeb': 'ar-raqeeb',
  'Al-Khafid': 'al-khafid',
  'Ar-Rafi': 'ar-rafi',
  'Al-Muizz': 'al-muizz',
  'Al-Muzill': 'al-muzill',
  'As-Sami': 'as-sami',
  'Al-Baseer': 'al-basir',
  'Al-Hakam': 'al-hakam',
  'Al-Adl': 'al-adl',
  'Al-Khabeer': 'al-khabir',
  'Al-Azeem': 'al-azeem',
  'Al-Ghafur': 'al-ghafur',
  'Al-Ali': 'al-ali',
  'Al-Kabeer': 'al-kabeer',
  'Al-Muqeet': 'al-muqeet',
  'Al-Haseeb': 'al-haseeb',
  'Al-Jaleel': 'al-jaleel',
  'Al-Wasi': 'al-wasi',
  'Al-Majeed': 'al-majeed',
  'Al-Baith': 'al-baith',
  'Ash-Shaheed': 'ash-shahid',
  'Al-Haqq': 'al-haqq',
  'Al-Qawiyy': 'al-qawi',
  'Al-Mateen': 'al-matin',
  'Al-Waliyy': 'al-waliyy',
  'Al-Hameed': 'al-hameed',
  'Al-Muhsi': 'al-muhsi',
  'Al-Mubdi': 'al-mubdi',
  'Al-Muid': 'al-muid',
  'Al-Muhyi': 'al-muhyi',
  'Al-Mumeet': 'al-mumeet',
  'Al-Wajid': 'al-wajid',
  'Al-Majid': 'al-majid',
  'Al-Wahid': 'al-wahid',
  'Al-Ahad': 'al-ahad',
  'Al-Qadir': 'al-qadir',
  'Al-Muqtadir': 'al-muqtadir',
  'Al-Muqaddim': 'al-muqaddim',
  'Al-Muakhkhir': 'al-muakhkhir',
  'Al-Awwal': 'al-awwal',
  'Al-Akhir': 'al-akhir',
  'Az-Zahir': 'az-zahir',
  'Al-Batin': 'al-batin',
  'Al-Wali': 'al-wali',
  'Al-Mutaali': 'al-mutaali',
  'Al-Barr': 'al-barr',
  'Al-Afuw': 'al-afuw',
  'Ar-Rauf': 'ar-rauf',
  'Malik-ul-Mulk': 'malik-ul-mulk',
  'Dhul-Jalali wal-Ikram': 'dhul-jalali-wal-ikram',
  'Al-Muqsit': 'al-muqsit',
  'Al-Jami': 'al-jami',
  'Al-Ghaniyy': 'al-ghaniyy',
  'Al-Mughni': 'al-mughni',
  'Al-Mani': 'al-mani',
  'Ad-Darr': 'ad-darr',
  'An-Nafi': 'an-nafi',
  'Al-Badi': 'al-badi',
  'Al-Baqi': 'al-baqi',
  'Ar-Rasheed': 'ar-rasheed',
};

/// Returns the anchor `name_key` slug for a `collectible_names.json`
/// transliteration. Returns null if not found — callers should treat that
/// as a content authoring error and let the `name_anchors_coverage_test`
/// surface it at CI.
String? anchorSlugForTransliteration(String transliteration) {
  return transliterationToAnchorSlug[transliteration];
}
