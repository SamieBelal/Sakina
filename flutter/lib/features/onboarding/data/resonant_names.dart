/// Names offered on the onboarding resonant-name picker (screen 7).
/// Single source of truth — the picker renders these and the personalized
/// plan screen looks up the chosen ID against this list. Adding a new entry
/// here is enough; nothing else needs to be touched.
class ResonantName {
  const ResonantName({
    required this.id,
    required this.arabic,
    required this.translit,
    required this.english,
    required this.emotion,
  });

  final String id;
  final String arabic;
  final String translit;
  final String english;
  final String emotion;
}

const kResonantNames = <ResonantName>[
  ResonantName(
    id: 'ar-rahman',
    arabic: 'الرَّحْمَنُ',
    translit: 'Ar-Rahman',
    english: 'The Most Merciful',
    emotion: 'For when you need warmth.',
  ),
  ResonantName(
    id: 'ar-rahim',
    arabic: 'الرَّحِيمُ',
    translit: 'Ar-Rahim',
    english: 'The Especially Merciful',
    emotion: 'For when you need closeness.',
  ),
  ResonantName(
    id: 'as-salam',
    arabic: 'السَّلَامُ',
    translit: 'As-Salam',
    english: 'The Source of Peace',
    emotion: 'For when your mind is racing.',
  ),
  ResonantName(
    id: 'al-wadud',
    arabic: 'الْوَدُودُ',
    translit: 'Al-Wadud',
    english: 'The Most Loving',
    emotion: 'For when you feel unseen.',
  ),
  ResonantName(
    id: 'al-hafiz',
    arabic: 'الْحَفِيظُ',
    translit: 'Al-Hafiz',
    english: 'The Preserver',
    emotion: 'For when you feel afraid.',
  ),
  ResonantName(
    id: 'al-karim',
    arabic: 'الْكَرِيمُ',
    translit: 'Al-Karim',
    english: 'The Most Generous',
    emotion: 'For when you feel small.',
  ),
];

/// Returns the transliteration for [id], or the first entry's transliteration
/// if [id] is null/unknown. Falling back to the list (instead of a hardcoded
/// string) means new names added to [kResonantNames] never silently render
/// as the wrong name.
String resonantTranslitForId(String? id) {
  for (final n in kResonantNames) {
    if (n.id == id) return n.translit;
  }
  return kResonantNames.first.translit;
}
