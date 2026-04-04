/// Knowledge base for dua construction, drawn from:
/// - Yaqeen Institute: "Prophetic Prayers for Relief and Protection"
/// - Yaqeen Institute: "Calling Upon Allah Through His 99 Names" (Omar Suleiman Ramadan Series)

// ─── Etiquettes of dua (adab al-du'a) ────────────────────────────────────────

const String duaEtiquettes = '''
ETIQUETTES OF DUA (adab al-du'a) — must be reflected in every constructed dua:

1. BEGIN WITH HAMD AND THANA (Praise of Allah)
   - Open by praising and glorifying Allah before making any request.
   - Use His beautiful Names (Asma ul-Husna) that are directly relevant to the need.
   - The Prophet ﷺ said: "Every matter of importance that does not begin with praise of Allah is deficient."
   - Surah al-Fatiha is the model: praise before petition.
   - Example: "Al-hamdu lillahi rabbi al-'alameen" before any request.

2. SEND SALAWAT ON THE PROPHET ﷺ
   - After praising Allah, send blessings on the Prophet ﷺ.
   - "Allahumma salli wa sallim 'ala nabiyyina Muhammadin wa 'ala alihi wa sahbihi ajma'een"
   - The dua is suspended between heaven and earth until salawat is sent.
   - Close the dua with salawat again before the final hamd.

3. THE ASK — TAWADU' (humility) and ILHAH (urgency/insistence)
   - Address Allah directly: "Allahumma..." or "Ya [Name]..."
   - Be specific about the need — not generic.
   - Acknowledge your weakness and His power.
   - Use relevant Names of Allah within the ask itself.
   - The Prophet ﷺ said: "Let one of you ask his Lord for all of his needs."
   - Al-Mujeeb (The Answerer), Al-Qareeb (The Near), Al-Wakeel (The Trustee) are powerful to invoke in the ask.

4. CLOSE WITH SALAWAT AND HAMD
   - Return to salawat on the Prophet ﷺ.
   - Close with hamd of Allah: "wal-hamdu lillahi rabbi al-'alameen"
   - This bookends the dua with praise, following the prophetic model.

5. CALL ALLAH BY HIS RELEVANT NAMES
   - "And to Allah belong the best names, so invoke Him by them." [Quran 7:180]
   - Match the Name to the emotional and spiritual need (see name-to-need mapping below).
   - The Prophet ﷺ said: "Du'a is the essence of worship."

6. PRESENCE OF HEART (khushu')
   - The Prophet ﷺ said: "Allah does not answer the prayer coming from a preoccupied heart."
   - The dua should feel personal, not formulaic.

7. CONSISTENCY AND SINCERITY
   - "The most beloved deeds to Allah are those that are the most consistent, even if they are few."
   - Ibn al-Qayyim: "Du'a is the weapon of the believer; it repels calamity, cures it, prevents it."
''';

// ─── Data classes ────────────────────────────────────────────────────────────

class NameGuidance {
  const NameGuidance({
    required this.name,
    required this.arabic,
    required this.episode,
    required this.callFor,
    required this.invocationStyle,
    required this.samplePhrase,
  });

  final String name;
  final String arabic;
  final int episode;
  final List<String> callFor;
  final String invocationStyle;
  final String samplePhrase;
}

class SalawatFormula {
  const SalawatFormula({
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  final String arabic;
  final String transliteration;
  final String translation;
}

class HamdOpening {
  const HamdOpening({
    required this.theme,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  final String theme;
  final String arabic;
  final String transliteration;
  final String translation;
}

// ─── Name-to-need mapping ─────────────────────────────────────────────────────

const List<NameGuidance> nameGuidance = [
  // Mercy cluster
  NameGuidance(
    name: 'Ar-Rahman',
    arabic: 'الرَّحْمَنُ',
    episode: 1,
    callFor: ['mercy', 'unconditional love', 'past sins', 'overwhelming guilt', 'hope in hardship'],
    invocationStyle: "Ya Rahman, ighfir li wa-rhamni bi-rahmatika allati wasi'at kulla shay'",
    samplePhrase: 'Ya Rahman, ihfuf hayati kullaha bi-rahmatik',
  ),
  NameGuidance(
    name: 'Ar-Raheem',
    arabic: 'الرَّحِيمُ',
    episode: 1,
    callFor: ['returning to Allah after sin', 'tawbah', 'needing forgiveness', 'spiritual return'],
    invocationStyle: "Ya Raheem, tub 'alayya wa-rhamni",
    samplePhrase: "Ya Raheem, 'amilni bi-rahmatika allati 'indak",
  ),
  NameGuidance(
    name: "Ar-Ra'uf",
    arabic: 'الرَّؤُوفُ',
    episode: 1,
    callFor: ['protection from unseen harm', 'gentleness', 'fear of trials', 'anxiety'],
    invocationStyle: "Ya Ra'uf, ultuf bi wa-ini min al-bala'",
    samplePhrase: "Ya Ra'uf, uqini ma la utiquh min al-fitan",
  ),
  // Guidance cluster
  NameGuidance(
    name: 'Al-Hadi',
    arabic: 'الْهَادِي',
    episode: 3,
    callFor: ['guidance', 'confusion', 'losing direction', 'feeling lost spiritually'],
    invocationStyle: 'Ya Hadi, ihdini ila al-sirat al-mustaqim',
    samplePhrase: 'Ya Hadi, ukhrijni min al-dhulumati ila al-nur',
  ),
  NameGuidance(
    name: 'Al-Rasheed',
    arabic: 'الرَّشِيدُ',
    episode: 3,
    callFor: ['wisdom', 'right decisions', 'discernment', 'knowing truth from falsehood'],
    invocationStyle: 'Ya Rasheed, alhimni rushdi wa-qini sharra nafsi',
    samplePhrase: "Ya Rasheed, a'tini hikmatan ufsilu biha bayna al-haqq wa-al-batil",
  ),
  NameGuidance(
    name: 'An-Nur',
    arabic: 'النُّورُ',
    episode: 3,
    callFor: ['spiritual darkness', 'despair', 'feeling disconnected from Allah', 'clarity'],
    invocationStyle: 'Ya Nur, nawwir qalbi bi-nurik',
    samplePhrase: "Ya Nur, ij'al fi qalbi nuran wa-fi sam'i nuran wa-fi basari nuran",
  ),
  // Protection cluster
  NameGuidance(
    name: 'Al-Hafeedh',
    arabic: 'الْحَفِيظُ',
    episode: 12,
    callFor: ['protection', 'preserving faith', 'protecting family', 'fear of losing blessings'],
    invocationStyle: 'Ya Hafeedh, ihfadhni wa-ihfadh li man uhibb',
    samplePhrase: 'Ya Hafeedh, احفظني من بين يدي ومن خلفي وعن يميني وعن شمالي',
  ),
  NameGuidance(
    name: 'Al-Wakeel',
    arabic: 'الْوَكِيلُ',
    episode: 12,
    callFor: ['tawakkul', 'overwhelming circumstances', 'loss of control', 'delegation to Allah'],
    invocationStyle: 'Ya Wakeel, fawwadtu amri ilayk',
    samplePhrase: "Hasbiyallahu wa-ni'ma al-wakeel",
  ),
  NameGuidance(
    name: 'Al-Muhaymin',
    arabic: 'الْمُهَيْمِنُ',
    episode: 12,
    callFor: ['safety', 'watchfulness', 'protection from unseen threats', 'security'],
    invocationStyle: 'Ya Muhaymin, kun li hafidhan wa-rasidan',
    samplePhrase: "Ya Muhaymin, ihrasni bi-'aynik allati la tanam",
  ),
  // Forgiveness cluster
  NameGuidance(
    name: 'Al-Ghaffar',
    arabic: 'الْغَفَّارُ',
    episode: 9,
    callFor: ['repeated sins', 'habitual wrongdoing', 'shame', 'feeling unworthy'],
    invocationStyle: "Ya Ghaffar, ighfir li kull marra ata'udu ilayk",
    samplePhrase: "Ya Ghaffar, ighfir li dhunubi kullaha sirraha wa-'alaniyyataha",
  ),
  NameGuidance(
    name: 'Al-Ghafur',
    arabic: 'الْغَفُورُ',
    episode: 9,
    callFor: ['deep past sins', 'hidden sins', 'needing complete purification'],
    invocationStyle: "Ya Ghafur, ighfir li ma 'alimtu wa-ma lam a'lam",
    samplePhrase: 'Ya Ghafur, imhi \'anni dhunubi kama tughsal al-thawb al-abyad min al-danas',
  ),
  NameGuidance(
    name: "Al-'Afuww",
    arabic: 'الْعَفُوُّ',
    episode: 27,
    callFor: ['full pardon', 'Laylat al-Qadr', 'complete erasure of sins', 'seeking a clean slate'],
    invocationStyle: "Ya 'Afuww, innaka 'afuwwun tuhibb al-'afw fa'fu 'anni",
    samplePhrase: "Ya 'Afuww, imhu 'anni kull dhunb kama law lam yakun",
  ),
  NameGuidance(
    name: 'At-Tawwab',
    arabic: 'التَّوَّابُ',
    episode: 9,
    callFor: ['repentance', 'returning to Allah', 'tawbah after relapse', 'new beginning'],
    invocationStyle: "Ya Tawwab, tub 'alayya wa-taqabbal tawbati",
    samplePhrase: "Ya Tawwab, ij'al tawbati tawbatan nasuhan la arji'u ba'daha ila ma'siyah",
  ),
  // Provision cluster
  NameGuidance(
    name: 'Ar-Razzaq',
    arabic: 'الرَّزَّاقُ',
    episode: 21,
    callFor: ['rizq', 'financial hardship', 'provision', 'sustenance', 'livelihood'],
    invocationStyle: 'Ya Razzaq, urzuqni min haythu la ahtasib',
    samplePhrase: "Ya Razzaq, ij'al rizqi wasi'an halalan tayyiban mubarakan fihi",
  ),
  NameGuidance(
    name: 'Al-Kareem',
    arabic: 'الْكَرِيمُ',
    episode: 21,
    callFor: ['generosity', 'dignity', 'nobility', 'asking beyond what one deserves'],
    invocationStyle: "Ya Kareem, a'tini bi-karamik ma la astahiqquhu bi-'amali",
    samplePhrase: "Ya Akram al-Akrameen, jud 'alayya bi-fadlika al-'adheem",
  ),
  NameGuidance(
    name: 'Al-Fattah',
    arabic: 'الْفَتَّاحُ',
    episode: 15,
    callFor: ['closed doors', 'blocked opportunities', 'new beginnings', 'feeling stuck'],
    invocationStyle: 'Ya Fattah, iftah li abwaban ma uzliqa fi wajhi',
    samplePhrase: 'Ya Fattah, iftah li min amri makhrajam wa-min hammiya farajam',
  ),
  // Healing cluster
  NameGuidance(
    name: 'Al-Shafi',
    arabic: 'الشَّافِي',
    episode: 23,
    callFor: ['illness', 'physical healing', 'mental health', 'healing of the ummah'],
    invocationStyle: 'Ya Shafi, ashfi nafsiy wa-ashfi kull maridh',
    samplePhrase: "Allahumma Rabbi al-nas, adhhib al-ba's, ishfi anta al-Shafi la shifa'a illa shifa'uk",
  ),
  // Patience cluster
  NameGuidance(
    name: 'As-Sabur',
    arabic: 'الصَّبُورُ',
    episode: 24,
    callFor: ['patience', 'long trials', 'endurance', 'waiting on Allah'],
    invocationStyle: "Ya Sabur, 'allimni al-sabr allathi la yanfad",
    samplePhrase: "Ya Sabur, hab li sabran jamilan 'ala ma qaddart 'alayy",
  ),
  NameGuidance(
    name: 'Al-Haleem',
    arabic: 'الْحَلِيمُ',
    episode: 24,
    callFor: ['forbearance', 'forgiving others', 'anger', 'patience with people'],
    invocationStyle: "Ya Haleem, alhimni al-hilm wa-'afu 'anni bi-hilmik",
    samplePhrase: "Ya Haleem, ij'alni haliman ma'a man adha'ani kama anta halimun ma'i",
  ),
  // Strength cluster
  NameGuidance(
    name: 'Al-Qawiyy',
    arabic: 'الْقَوِيُّ',
    episode: 22,
    callFor: ['strength', 'weakness', 'feeling powerless', 'needing courage'],
    invocationStyle: "Ya Qawiyy, qawwi dhafafi wa-uqim 'awaji",
    samplePhrase: "Ya Qawiyy, hab li min quwwatika ma a'inu bihi 'ala ta'atik",
  ),
  NameGuidance(
    name: "Al-'Azeez",
    arabic: 'الْعَزِيزُ',
    episode: 22,
    callFor: ['dignity', 'honor', 'being looked down upon', 'self-worth'],
    invocationStyle: "Ya 'Azeez, a'izzani bi-'izzatik wa-la tudhillni",
    samplePhrase: "Ya 'Azeez, ij'al 'izzati bi-'ubdiyyatika la bi-mada'ih al-khalq",
  ),
  // Marriage/family cluster
  NameGuidance(
    name: 'Al-Wadud',
    arabic: 'الْوَدُودُ',
    episode: 10,
    callFor: ['marriage', 'love', 'family harmony', 'reconciliation', 'finding a spouse'],
    invocationStyle: 'Ya Wadud, hub al-mahabbah bayna qulubina',
    samplePhrase: 'Ya Wadud, arzuqni zawjan salihan taqiyyan yuhabbuni fikak wa-uhibbuhu fik',
  ),
  NameGuidance(
    name: "Al-Jaami'",
    arabic: 'الْجَامِعُ',
    episode: 28,
    callFor: ['reunion', 'broken family', 'gathering what is scattered', 'unity'],
    invocationStyle: "Ya Jaami', ajma' shatata amrina wa-waffiq baynana",
    samplePhrase: "Ya Jaami', ujma' bayna qulubina 'ala al-khayr wa-al-taqwa",
  ),
  // Trust/anxiety cluster
  NameGuidance(
    name: 'Al-Mujeeb',
    arabic: 'الْمُجِيبُ',
    episode: 11,
    callFor: ['unanswered duas', 'feeling unheard', 'desperation', 'urgent need'],
    invocationStyle: "Ya Mujeeb, ajib du'a'i wa-la tukhyib raja'i",
    samplePhrase: "Ya Mujeeb, ajibni kama ajabt Yunus fi dhulumati al-bahr",
  ),
  NameGuidance(
    name: 'Al-Qareeb',
    arabic: 'الْقَرِيبُ',
    episode: 11,
    callFor: ['loneliness', 'feeling distant from Allah', 'isolation', 'spiritual disconnection'],
    invocationStyle: "Ya Qareeb, aqribni ilayk wa-la taj'alni ba'idan 'ank",
    samplePhrase: "Ya Qareeb, asiruhu 'indi wa-ana 'indak fa-la tab'ud 'anni",
  ),
  NameGuidance(
    name: 'Al-Lateef',
    arabic: 'اللَّطِيفُ',
    episode: 17,
    callFor: ['subtle help', 'gentle relief', 'anxiety', 'unseen blessings', 'feeling overlooked'],
    invocationStyle: 'Ya Lateef, ultuf bi fi amri kullih',
    samplePhrase: "Ya Lateef, kama latafta li-Yusuf fi ma qaddart 'alayh, ultuf bi fi ma ana fih",
  ),
  // Gratitude cluster
  NameGuidance(
    name: 'Ash-Shakur',
    arabic: 'الشَّكُورُ',
    episode: 10,
    callFor: ['gratitude', 'feeling unappreciated', 'recognizing blessings', 'thankfulness'],
    invocationStyle: 'Ya Shakur, taqabbal shukri wa-zidni min fadlik',
    samplePhrase: "Ya Shakur, alhimni shukrak wa-ij'alni min al-shakireen",
  ),
  // Justice cluster
  NameGuidance(
    name: "Al-'Adl",
    arabic: 'الْعَدْلُ',
    episode: 20,
    callFor: ['injustice', 'oppression', 'unfair treatment', 'seeking justice'],
    invocationStyle: "Ya 'Adl, unsurni 'ala man dhalami",
    samplePhrase: "Ya 'Adl, uqim al-'adl wa-la tuhlikna bi-ma fa'ala al-sufaha'",
  ),
  NameGuidance(
    name: 'Al-Jabbar',
    arabic: 'الْجَبَّارُ',
    episode: 18,
    callFor: ['mending brokenness', 'healing after trauma', 'rebuilding after loss'],
    invocationStyle: 'Ya Jabbar, ujbur kasri wa-ajbir kull muksur fiya',
    samplePhrase: "Ya Jabbar, ujbur qalbi al-maksur wa-a'idni akwa mimma kunt",
  ),
];

// ─── Salawat formulas ─────────────────────────────────────────────────────────

class SalawatFormulas {
  const SalawatFormulas._();

  static const SalawatFormula standard = SalawatFormula(
    arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ',
    transliteration: "Allahumma salli wa sallim 'ala nabiyyina Muhammadin wa 'ala alihi wa sahbihi ajma'een",
    translation: 'O Allah, send peace and blessings upon our Prophet Muhammad and upon all his family and companions.',
  );

  static const SalawatFormula closing = SalawatFormula(
    arabic: 'وَصَلِّ اللَّهُمَّ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    transliteration: "Wa salli Allahumma 'ala nabiyyina Muhammadin wa 'ala alihi wa sahbihi wal-hamdu lillahi rabbi al-'alameen",
    translation: "And send blessings, O Allah, upon our Prophet Muhammad and upon his family and companions, and all praise belongs to Allah, Lord of all the worlds.",
  );
}

// ─── Opening hamd formulas ────────────────────────────────────────────────────

const List<HamdOpening> hamdOpenings = [
  HamdOpening(
    theme: 'general',
    arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ، الرَّحْمَنِ الرَّحِيمِ، مَالِكِ يَوْمِ الدِّينِ',
    transliteration: "Al-hamdu lillahi rabbi al-'alameen, ar-rahmani ar-raheem, maliki yawmi al-deen",
    translation: 'All praise belongs to Allah, Lord of all the worlds, the Most Gracious, the Most Merciful, Master of the Day of Judgment.',
  ),
  HamdOpening(
    theme: 'provision',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي بِيَدِهِ خَزَائِنُ السَّمَاوَاتِ وَالْأَرْضِ وَهُوَ يَبْسُطُ الرِّزْقَ لِمَنْ يَشَاءُ',
    transliteration: "Al-hamdu lillahi alladhi biyadihi khaza'inu al-samawati wa-al-ardi wa-huwa yabsutu al-rizqa liman yasha'",
    translation: 'All praise belongs to Allah in whose hand are the treasuries of the heavens and the earth, and He extends provision to whom He wills.',
  ),
  HamdOpening(
    theme: 'mercy',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي كَتَبَ الرَّحْمَةَ عَلَى نَفْسِهِ، وَوَسِعَتْ رَحْمَتُهُ كُلَّ شَيْءٍ',
    transliteration: "Al-hamdu lillahi alladhi kataba al-rahmata 'ala nafsihi wa-wasi'at rahmtuhu kulla shay'",
    translation: 'All praise belongs to Allah who wrote mercy upon Himself, and whose mercy encompasses all things.',
  ),
  HamdOpening(
    theme: 'healing',
    arabic: 'الْحَمْدُ لِلَّهِ الشَّافِي الْكَافِي الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ',
    transliteration: "Al-hamdu lillahi al-shafi al-kafi alladhi la yadurru ma'a ismihi shay'un fi al-ardi wa-la fi al-sama'",
    translation: 'All praise belongs to Allah, the Healer, the Sufficient, with whose name nothing is harmed on earth or in heaven.',
  ),
  HamdOpening(
    theme: 'guidance',
    arabic: 'الْحَمْدُ لِلَّهِ الَّذِي هَدَانَا لِهَذَا وَمَا كُنَّا لِنَهْتَدِيَ لَوْلَا أَنْ هَدَانَا اللَّهُ',
    transliteration: "Al-hamdu lillahi alladhi hadana li-hadha wa-ma kunna li-nahtadiya lawla an hadana Allah",
    translation: 'All praise belongs to Allah who guided us to this, and we would not have been guided had Allah not guided us.',
  ),
];

// ─── Closing hamd formula ────────────────────────────────────────────────────

const SalawatFormula closingHamd = SalawatFormula(
  arabic: 'وَالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
  transliteration: "wal-hamdu lillahi rabbi al-'alameen",
  translation: 'And all praise belongs to Allah, Lord of all the worlds.',
);

// ─── Helper: find relevant Names for a given need ────────────────────────────

List<NameGuidance> getNameGuidanceForNeed(String needText) {
  final lower = needText.toLowerCase();

  final scored = nameGuidance.map((n) {
    int score = 0;
    for (final tag in n.callFor) {
      if (lower.contains(tag)) score += 2;
      // partial word match
      final words = tag.split(' ');
      for (final w in words) {
        if (w.length > 4 && lower.contains(w)) score += 1;
      }
    }
    return (guidance: n, score: score);
  }).toList();

  scored.sort((a, b) => b.score.compareTo(a.score));

  return scored
      .where((item) => item.score > 0)
      .take(4)
      .map((item) => item.guidance)
      .toList();
}
