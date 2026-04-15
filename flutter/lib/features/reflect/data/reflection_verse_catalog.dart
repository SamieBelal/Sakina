import 'package:sakina/features/reflect/models/reflect_verse.dart';

const ReflectVerse _heartsRestVerse = ReflectVerse(
  arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
  translation: 'Verily, in the remembrance of Allah do hearts find rest.',
  reference: 'Ar-Ra\'d 13:28',
);

const ReflectVerse _hardshipEaseVerse = ReflectVerse(
  arabic: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ﴿٥﴾ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
  translation:
      'For indeed, with hardship comes ease. Indeed, with hardship comes ease.',
  reference: 'Ash-Sharh 94:5-6',
);

const ReflectVerse _gratitudeIncreaseVerse = ReflectVerse(
  arabic: 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
  translation: 'If you are grateful, I will surely increase you in favor.',
  reference: 'Ibrahim 14:7',
);

const ReflectVerse _restrainAngerVerse = ReflectVerse(
  arabic: 'وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ',
  translation:
      'Those who restrain anger and pardon the people — and Allah loves the doers of good.',
  reference: 'Al-Imran 3:134',
);

const ReflectVerse _noBurdenVerse = ReflectVerse(
  arabic: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
  translation: 'Allah does not burden a soul beyond that it can bear.',
  reference: 'Al-Baqarah 2:286',
);

const ReflectVerse _trustAllahVerse = ReflectVerse(
  arabic: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
  translation: 'And whoever relies upon Allah — then He is sufficient for him.',
  reference: 'At-Talaq 65:3',
);

const ReflectVerse _favorsVerse = ReflectVerse(
  arabic: 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
  translation: 'So which of the favors of your Lord would you deny?',
  reference: 'Ar-Rahman 55:13',
);

const ReflectVerse _repentanceVerse = ReflectVerse(
  arabic:
      'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
  translation:
      'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
  reference: 'Quran 7:23',
);

const ReflectVerse _believersMercyVerse = ReflectVerse(
  arabic:
      'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِّلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَّحِيمٌ',
  translation:
      'Our Lord, forgive us and our brothers who preceded us in faith, and put not in our hearts any resentment toward those who have believed. Our Lord, indeed You are Kind and Merciful.',
  reference: 'Quran 59:10',
);

const ReflectVerse _goodWorldsVerse = ReflectVerse(
  arabic:
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
  translation:
      'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
  reference: 'Quran 2:201',
);

const ReflectVerse _acceptanceVerse = ReflectVerse(
  arabic: 'رَبَّنَا تَقَبَّلْ مِنَّا ۖ إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
  translation:
      'Our Lord, accept from us. Indeed You are the Hearing, the Knowing.',
  reference: 'Quran 2:127',
);

const ReflectVerse _protectionVerse = ReflectVerse(
  arabic:
      'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
  translation:
      'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth.',
  reference: 'Quran 2:255',
);

const Map<String, List<ReflectVerse>> approvedReflectVersesByName = {
  'Ar-Rahman': [_favorsVerse, _believersMercyVerse],
  'Ar-Raheem': [_believersMercyVerse, _favorsVerse],
  'Al-Malik': [_goodWorldsVerse, _acceptanceVerse],
  'Al-Quddus': [_acceptanceVerse, _heartsRestVerse],
  'As-Salam': [_heartsRestVerse, _favorsVerse],
  'Al-Mumin': [_protectionVerse, _heartsRestVerse],
  'Al-Azeez': [_trustAllahVerse, _goodWorldsVerse],
  'Al-Ghaffar': [_repentanceVerse, _believersMercyVerse],
  'Ar-Razzaq': [_trustAllahVerse, _goodWorldsVerse],
  'Al-Lateef': [_noBurdenVerse, _hardshipEaseVerse],
  'Ash-Shakur': [_gratitudeIncreaseVerse, _favorsVerse],
  'Al-Haleem': [_restrainAngerVerse, _hardshipEaseVerse],
  'Al-Wadud': [_believersMercyVerse, _favorsVerse],
  'As-Sabur': [_restrainAngerVerse, _hardshipEaseVerse],
  'Al-Hafeez': [_protectionVerse, _trustAllahVerse],
};

final Map<String, ReflectVerse> _approvedReflectVersesByReference = () {
  final entries = <String, ReflectVerse>{};
  for (final verses in approvedReflectVersesByName.values) {
    for (final verse in verses) {
      entries[_normalizeVerseKey(verse.reference)] = verse;
    }
  }
  return entries;
}();

String _normalizeVerseKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

List<ReflectVerse> approvedVersesForName(String name) {
  return List<ReflectVerse>.from(approvedReflectVersesByName[name] ?? const []);
}

List<ReflectVerse> normalizeApprovedVerses(
  String name,
  List<ReflectVerse> verses,
) {
  final approvedByReference = _approvedReflectVersesByReference;
  final normalized = <ReflectVerse>[];
  final seen = <String>{};

  for (final verse in verses) {
    final approved = approvedByReference[_normalizeVerseKey(verse.reference)];
    if (approved == null) continue;
    if (seen.add(approved.reference)) {
      normalized.add(approved);
    }
  }

  if (normalized.isNotEmpty) {
    return normalized.take(2).toList();
  }

  return approvedVersesForName(name).take(2).toList();
}

String buildApprovedVersePrompt() {
  final buffer = StringBuffer();
  buffer.writeln('## Approved Quran Verses');
  buffer.writeln(
    'Choose up to 2 verses ONLY from the approved verses listed for the chosen Name.',
  );
  buffer.writeln(
    'Copy the Arabic, English translation, and reference exactly as written below.',
  );

  for (final entry in approvedReflectVersesByName.entries) {
    buffer.writeln('- ${entry.key}:');
    for (final verse in entry.value) {
      buffer.writeln('  - Arabic: ${verse.arabic}');
      buffer.writeln('    English: ${verse.translation}');
      buffer.writeln('    Reference: ${verse.reference}');
    }
  }

  return buffer.toString().trimRight();
}
