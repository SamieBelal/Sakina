/// Knowledge base for dua construction, drawn from:
/// - Yaqeen Institute: "Prophetic Prayers for Relief and Protection"
/// - Yaqeen Institute: "Calling Upon Allah Through His 99 Names" (Omar Suleiman Ramadan Series)
library;

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
    samplePhrase: 'Ya Mujeeb, ajibni kama ajabt Yunus fi dhulumati al-bahr',
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

  // Core Divine Names
  NameGuidance(
    name: 'Allah',
    arabic: 'اللَّهُ',
    episode: 0,
    callFor: ['any need', 'all circumstances', 'when no other name suffices', 'total dependence'],
    invocationStyle: "Allahumma inni as'aluka bi kulli ismin huwa lak",
    samplePhrase: "Allahumma inni as'aluka bi kulli ismin huwa lak",
  ),
  NameGuidance(
    name: 'Al-Malik',
    arabic: 'الْمَلِكُ',
    episode: 4,
    callFor: ['feeling powerless', 'unjust authority', 'worldly failures', 'trust in divine sovereignty'],
    invocationStyle: "Ya Malikal-Mulk, tu'til-mulka man tasha'",
    samplePhrase: "Allahumma Malikal-Mulk tu'til-mulka man tasha'",
  ),
  NameGuidance(
    name: 'Al-Quddus',
    arabic: 'الْقُدُّوسُ',
    episode: 5,
    callFor: ['spiritual purification', 'feeling polluted by sin', 'seeking holiness', 'purity of heart'],
    invocationStyle: 'Subbuhun Quddusun Rabbul-mala\'ikati war-ruh',
    samplePhrase: 'Subbuhun Quddusun Rabbul-mala\'ikati war-ruh',
  ),
  NameGuidance(
    name: 'As-Salam',
    arabic: 'السَّلَامُ',
    episode: 6,
    callFor: ['anxiety', 'inner turmoil', 'seeking peace', 'after trials'],
    invocationStyle: 'Allahumma Antas-Salam wa minkas-salam tabarakta ya Dhal-Jalali wal-Ikram',
    samplePhrase: 'Allahumma Antas-Salam wa minkas-salam tabarakta ya Dhal-Jalali wal-Ikram',
  ),
  NameGuidance(
    name: 'Al-Mumin',
    arabic: 'الْمُؤْمِنُ',
    episode: 7,
    callFor: ['doubt', 'wavering faith', 'fear', 'seeking security and reassurance'],
    invocationStyle: "Allahumma thabbitna 'alal-iman",
    samplePhrase: "Allahumma thabbitna 'alal-iman",
  ),

  // Creation cluster
  NameGuidance(
    name: 'Al-Khaliq',
    arabic: 'الْخَالِقُ',
    episode: 14,
    callFor: ['feeling purposeless', 'identity crisis', 'new beginnings', 'creative endeavors'],
    invocationStyle: 'Rabbana ma khalaqta hadha batilan subhanak',
    samplePhrase: 'Rabbana ma khalaqta hadha batilan subhanak',
  ),
  NameGuidance(
    name: 'Al-Bari',
    arabic: 'الْبَارِئُ',
    episode: 14,
    callFor: ['self-repair', 'healing brokenness within', 'reconstructing after failure'],
    invocationStyle: "Ya Bari', aslih ma afsadtuhu fi nafsi",
    samplePhrase: "Ya Bari', aslih ma afsadtuhu fi nafsi waj'alni kamilan bi-diqqati sun'ik",
  ),
  NameGuidance(
    name: 'Al-Musawwir',
    arabic: 'الْمُصَوِّرُ',
    episode: 14,
    callFor: ['self-image', 'body image struggles', 'feeling uniquely made', 'character development'],
    invocationStyle: "Ya Musawwir, jammil akhlaaqi kama jammalta khalqi",
    samplePhrase: "Ya Musawwir, jammil akhlaaqi kama jammalta khalqi",
  ),
  NameGuidance(
    name: 'Al-Wahhab',
    arabic: 'الْوَهَّابُ',
    episode: 16,
    callFor: ['gifts without deserving', 'asking for children', 'seeking mercy', 'firmness of heart'],
    invocationStyle: "Rabbana la tuzigh qulubana ba'da idh hadaytana wa hab lana min ladunka rahmah",
    samplePhrase: "Rabbana la tuzigh qulubana ba'da idh hadaytana wa hab lana min ladunka rahmah",
  ),
  NameGuidance(
    name: 'Al-Badi',
    arabic: 'الْبَدِيعُ',
    episode: 97,
    callFor: ['new beginnings', 'creativity', 'wanting something unprecedented', 'forgiveness'],
    invocationStyle: "Ya Badi'as-samawati wal-ard, anta waliyyi faghfir li",
    samplePhrase: "Ya Badi'as-samawati wal-ard, anta waliyyi faghfir li",
  ),

  // Knowledge cluster
  NameGuidance(
    name: 'Al-Aleem',
    arabic: 'الْعَلِيمُ',
    episode: 19,
    callFor: ['feeling misunderstood', 'hidden intentions', 'seeking clarity', 'knowledge and learning'],
    invocationStyle: "Allahumma 'Alimal-ghaybi wash-shahadah, Fatiras-samawati wal-ard",
    samplePhrase: "Allahumma 'Alimal-ghaybi wash-shahadah, Fatiras-samawati wal-ard",
  ),
  NameGuidance(
    name: 'Al-Khabeer',
    arabic: 'الْخَبِيرُ',
    episode: 25,
    callFor: ['feeling exposed', 'hidden struggles', 'seeking divine awareness', 'inner honesty'],
    invocationStyle: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
    samplePhrase: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
  ),
  NameGuidance(
    name: 'Al-Hakeem',
    arabic: 'الْحَكِيمُ',
    episode: 26,
    callFor: ['confusion', 'painful decrees', 'not understanding why', 'trusting the plan'],
    invocationStyle: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
    samplePhrase: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
  ),

  // Observation cluster
  NameGuidance(
    name: 'Ar-Raqeeb',
    arabic: 'الرَّقِيبُ',
    episode: 40,
    callFor: ['sincerity in private', 'accountability', 'guarding speech and actions', 'hidden good deeds'],
    invocationStyle: "Ya Raqib, ihfadhni fi sirri wa 'alaniyyati",
    samplePhrase: "Ya Raqib, ihfadhni fi sirri wa 'alaniyyati",
  ),
  NameGuidance(
    name: 'As-Sami',
    arabic: 'السَّمِيعُ',
    episode: 45,
    callFor: ['unheard prayers', 'silent suffering', 'longing to be heard', 'hope in dua'],
    invocationStyle: 'Inna Rabbi qaribun mujib',
    samplePhrase: 'Inna Rabbi qaribun mujib',
  ),
  NameGuidance(
    name: 'Al-Baseer',
    arabic: 'الْبَصِيرُ',
    episode: 46,
    callFor: ['unseen struggle', 'silent sacrifice', 'feeling invisible', 'witnessing injustice'],
    invocationStyle: "Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya'lamuhu siwak",
    samplePhrase: "Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya'lamuhu siwak",
  ),
  NameGuidance(
    name: 'Ash-Shaheed',
    arabic: 'الشَّهِيدُ',
    episode: 50,
    callFor: ['feeling overlooked', 'silent acts of goodness', 'seeking divine witness', 'accountability'],
    invocationStyle: "Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya'lamuhu siwak",
    samplePhrase: "Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya'lamuhu siwak",
  ),

  // Majesty cluster
  NameGuidance(
    name: 'Al-Ali',
    arabic: 'الْعَلِيُّ',
    episode: 36,
    callFor: ['feeling small', 'humiliation', 'raising self above worldly concerns', 'nearness in sujud'],
    invocationStyle: "Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar",
    samplePhrase: "Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar",
  ),
  NameGuidance(
    name: 'Al-Kabeer',
    arabic: 'الْكَبِيرُ',
    episode: 37,
    callFor: ['overwhelming fears', 'arrogance check', 'perspective on worldly problems', 'humility'],
    invocationStyle: "Ya Kabeer, ash'irni bisighari amamak",
    samplePhrase: "Ya Kabeer, ash'irni bisighari amamak hatta la yamla' qalbi kibr",
  ),
  NameGuidance(
    name: 'Al-Azeem',
    arabic: 'الْعَظِيمُ',
    episode: 43,
    callFor: ['problems feeling insurmountable', 'glorification', 'perspective', 'awe of Allah'],
    invocationStyle: "Subhana Rabbiyal 'Azeem",
    samplePhrase: "Subhana Rabbiyal 'Azeem",
  ),
  NameGuidance(
    name: 'Al-Jaleel',
    arabic: 'الْجَلِيلُ',
    episode: 44,
    callFor: ['reverence', 'awe without fear', 'drawing closer through majesty', 'taqwa'],
    invocationStyle: "Ya Jaleel, imla' qalbi ijlalan laka yuqarribuni mink",
    samplePhrase: "Ya Jaleel, imla' qalbi ijlalan laka yuqarribuni mink la khawfan yub'iduni 'ank",
  ),
  NameGuidance(
    name: 'Al-Mutaali',
    arabic: 'الْمُتَعَالِ',
    episode: 78,
    callFor: ['transcendence', 'rising above pettiness', 'humility before Allah', 'lifting the heart'],
    invocationStyle: "Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar",
    samplePhrase: "Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar",
  ),
  NameGuidance(
    name: 'Al-Mutakabbir',
    arabic: 'الْمُتَكَبِّرُ',
    episode: 10,
    callFor: ['humility', 'tyrants and oppressors', 'recognizing false pride', 'true greatness'],
    invocationStyle: "Ya Qahhar, iqhar kulla jabbarin 'anid",
    samplePhrase: "Ya Qahhar, iqhar kulla jabbarin 'anid, wa Ya Jabbar, ujbur kasri",
  ),

  // Subduing cluster
  NameGuidance(
    name: 'Al-Qahhar',
    arabic: 'الْقَهَّارُ',
    episode: 16,
    callFor: ['oppressors', 'tyrants', 'ego and nafs', 'overcoming what overpowers you'],
    invocationStyle: "Ya Qahhar, iqhar kulla jabbarin 'anid",
    samplePhrase: "Ya Qahhar, iqhar kulla jabbarin 'anid, wa Ya Jabbar, ujbur kasri",
  ),

  // Expansion/Constriction
  NameGuidance(
    name: 'Al-Qabid',
    arabic: 'الْقَابِضُ',
    episode: 20,
    callFor: ['hardship', 'feeling withheld from', 'constriction', 'trusting divine withholding'],
    invocationStyle: "Ya Qabidu ya Basitu ibsut 'alayna min rahmatik",
    samplePhrase: "Ya Qabidu ya Basitu ibsut 'alayna min rahmatik",
  ),
  NameGuidance(
    name: 'Al-Basit',
    arabic: 'الْبَاسِطُ',
    episode: 20,
    callFor: ['expansion', 'abundance', 'relief after hardship', 'opening of provision'],
    invocationStyle: "Ya Qabidu ya Basitu ibsut 'alayna min rahmatik",
    samplePhrase: "Ya Qabidu ya Basitu ibsut 'alayna min rahmatik",
  ),

  // Rank cluster
  NameGuidance(
    name: 'Al-Khafid',
    arabic: 'الْخَافِضُ',
    episode: 21,
    callFor: ['humbling arrogance', 'lowering pride', 'spiritual refinement', 'seeking true rank'],
    invocationStyle: "Ya Khafid, ikhfid kibriya'i warfa' qadri 'indak",
    samplePhrase: "Ya Khafid, ikhfid kibriya'i warfa' qadri 'indak",
  ),
  NameGuidance(
    name: 'Ar-Rafi',
    arabic: 'الرَّافِعُ',
    episode: 21,
    callFor: ['elevation of rank', 'feeling low', 'seeking status with Allah', 'after humiliation'],
    invocationStyle: "Ya Rafi', irfa' darajati 'indak",
    samplePhrase: "Ya Rafi', irfa' darajati 'indak waj'al li makanatan fid-dunya wal-akhirah",
  ),
  NameGuidance(
    name: 'Al-Muizz',
    arabic: 'الْمُعِزُّ',
    episode: 22,
    callFor: ['honor', 'dignity', 'being looked down upon', 'true honor through obedience'],
    invocationStyle: "Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik",
    samplePhrase: "Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik",
  ),
  NameGuidance(
    name: 'Al-Muzill',
    arabic: 'الْمُذِلُّ',
    episode: 22,
    callFor: ['oppressors brought low', 'humility reminder', 'no lasting power without Allah'],
    invocationStyle: "Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik",
    samplePhrase: "Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik",
  ),

  // Justice/Judgment cluster
  NameGuidance(
    name: 'Al-Hakam',
    arabic: 'الْحَكَمُ',
    episode: 47,
    callFor: ['injustice', 'disputes', 'seeking divine judgment', 'when human justice fails'],
    invocationStyle: "Allahumma uhkum baynana wa bayna qawmina bil-haqq",
    samplePhrase: "Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin",
  ),
  NameGuidance(
    name: 'Al-Haseeb',
    arabic: 'الْحَسِيبُ',
    episode: 49,
    callFor: ['accountability', 'good deeds going unnoticed', 'Day of Judgment', 'hidden effort'],
    invocationStyle: "Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin",
    samplePhrase: "Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin",
  ),
  NameGuidance(
    name: 'Al-Muqsit',
    arabic: 'الْمُقْسِطُ',
    episode: 90,
    callFor: ['injustice', 'scales of fairness', 'oppression', 'patience with unfairness'],
    invocationStyle: "Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin",
    samplePhrase: "Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin",
  ),
  NameGuidance(
    name: 'Al-Haqq',
    arabic: 'الْحَقُّ',
    episode: 52,
    callFor: ['confusion about truth', 'falsehood around you', 'seeking certainty', 'grounding in reality'],
    invocationStyle: "Allahumma lakal-hamd, Antal-Haqq, wa wa'dukal-haqq",
    samplePhrase: "Allahumma lakal-hamd, Antal-Haqq, wa wa'dukal-haqq",
  ),

  // Provision/Sustenance cluster
  NameGuidance(
    name: 'Al-Muqeet',
    arabic: 'الْمُقِيتُ',
    episode: 48,
    callFor: ['spiritual nourishment', 'soul sustenance', 'purpose and energy', 'provision'],
    invocationStyle: "Ya Muqeet, aqitni bidhikrika wa-aghdhi ruhi biqurbik",
    samplePhrase: "Ya Muqeet, aqitni bidhikrika wa-aghdhi ruhi biqurbik",
  ),
  NameGuidance(
    name: 'Al-Wasi',
    arabic: 'الْوَاسِعُ',
    episode: 55,
    callFor: ['feeling limited', 'expansion of heart', 'when needs feel too great', 'abundance'],
    invocationStyle: "Ya Wasi', wassi' qalbi lis-sabr",
    samplePhrase: "Ya Wasi', wassi' qalbi lis-sabr wa-basiirati litajawuzi hududy",
  ),
  NameGuidance(
    name: 'Al-Ghaniyy',
    arabic: 'الْغَنِيُّ',
    episode: 88,
    callFor: ['needing nothing but Allah', 'financial stress', 'contentment', 'freedom from dependence'],
    invocationStyle: "Allahumma aghnini bifadlika amman siwak",
    samplePhrase: "Allahumma aghnini bifadlika amman siwak",
  ),
  NameGuidance(
    name: 'Al-Mughni',
    arabic: 'الْمُغْنِي',
    episode: 89,
    callFor: ['enrichment of heart', 'rising above material needs', 'true wealth', 'contentment'],
    invocationStyle: "Ya Mughni, aghnini bighinaka 'an siwak",
    samplePhrase: "Ya Mughni, aghnini bighinaka 'an siwak waj'al qalbi ghaniyyan bik",
  ),

  // Life/Death cluster
  NameGuidance(
    name: 'Al-Hayy',
    arabic: 'الْحَيُّ',
    episode: 62,
    callFor: ['lifelessness of heart', 'spiritual death', 'urgency in dua', 'seeking the living God'],
    invocationStyle: 'Ya Hayyu Ya Qayyum bi rahmatika astaghith',
    samplePhrase: 'Ya Hayyu Ya Qayyum bi rahmatika astaghith',
  ),
  NameGuidance(
    name: 'Al-Qayyum',
    arabic: 'الْقَيُّومُ',
    episode: 63,
    callFor: ['feeling unsustained', 'falling apart', 'needing divine upholding', 'complete reliance'],
    invocationStyle: "Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha'ni kullahu",
    samplePhrase: "Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn",
  ),
  NameGuidance(
    name: 'Al-Muhyi',
    arabic: 'الْمُحْيِي',
    episode: 60,
    callFor: ['dead heart', 'lost hope', 'revival', 'spiritual resurrection'],
    invocationStyle: "Ya Muhyi, ahyi qalbi bil-iman",
    samplePhrase: "Ya Muhyi, ahyi qalbi bil-iman wa-ahyi amaliyyal-lati amatat-hal-dunya",
  ),
  NameGuidance(
    name: 'Al-Mumeet',
    arabic: 'الْمُمِيتُ',
    episode: 61,
    callFor: ['remembering death', 'good ending', 'perspective on dunya', 'preparing for akhirah'],
    invocationStyle: "Allahumma ahsin khatimati waj'al akhira a'mali khayriha",
    samplePhrase: "Allahumma ahsin khatimati waj'al akhira a'mali khayriha",
  ),
  NameGuidance(
    name: 'Al-Baith',
    arabic: 'الْبَاعِثُ',
    episode: 73,
    callFor: ['dead motivation', 'spiritual revival', 'resurrection hope', 'reviving the heart'],
    invocationStyle: "Ya Ba'ith, ahyi qalbi kama tuhyil-ardal-mayyitata bil-matar",
    samplePhrase: "Ya Ba'ith, ahyi qalbi kama tuhyil-ardal-mayyitata bil-matar",
  ),

  // Time/Eternity cluster
  NameGuidance(
    name: 'Al-Awwal',
    arabic: 'الْأَوَّلُ',
    episode: 57,
    callFor: ['anxiety about future', 'trust in divine planning', 'His existence before all things'],
    invocationStyle: "Allahumma anta'l-Awwalu fa laysa qablaka shay'",
    samplePhrase: "Allahumma anta'l-Awwalu fa laysa qablaka shay', wa anta'l-Akhiru fa laysa ba'daka shay'",
  ),
  NameGuidance(
    name: 'Al-Akhir',
    arabic: 'الْآخِرُ',
    episode: 58,
    callFor: ['grief over endings', 'impermanence', 'investing in akhirah', 'perspective on loss'],
    invocationStyle: "Allahumma anta'l-Awwalu fa laysa qablaka shay', wa anta'l-Akhiru fa laysa ba'daka shay'",
    samplePhrase: "Allahumma anta'l-Awwalu fa laysa qablaka shay', wa anta'l-Akhiru fa laysa ba'daka shay'",
  ),
  NameGuidance(
    name: 'Az-Zahir',
    arabic: 'الظَّاهِرُ',
    episode: 59,
    callFor: ['seeing Allah in creation', 'gratitude for visible blessings', 'recognizing signs'],
    invocationStyle: "Anta al-Dhahiru fa-laysa fawqaka shay'",
    samplePhrase: "Anta al-Dhahiru fa-laysa fawqaka shay', wa anta al-Batinu fa-laysa dunaka shay'",
  ),
  NameGuidance(
    name: 'Al-Batin',
    arabic: 'الْبَاطِنُ',
    episode: 59,
    callFor: ['hidden nearness of Allah', 'feeling distant', 'inner knowing', 'closeness beyond sight'],
    invocationStyle: "Anta al-Batinu fa-laysa dunaka shay'",
    samplePhrase: "Anta al-Dhahiru fa-laysa fawqaka shay', wa anta al-Batinu fa-laysa dunaka shay'",
  ),
  NameGuidance(
    name: 'Al-Baqi',
    arabic: 'الْبَاقِي',
    episode: 96,
    callFor: ['grief over loss', 'impermanence of dunya', 'attaching heart to what lasts'],
    invocationStyle: "Allahumma Antal-Baqi wa nahnul-fanun faj'al baqaana ta'atan lak",
    samplePhrase: "Allahumma Antal-Baqi wa nahnul-fanun faj'al baqaana ta'atan lak",
  ),

  // Eternity/Oneness cluster
  NameGuidance(
    name: 'As-Samad',
    arabic: 'الصَّمَدُ',
    episode: 112,
    callFor: ['total reliance', 'needing an eternal refuge', 'loneliness', 'when everything fails'],
    invocationStyle: "Allahumma ya Samad, ij'alni ghaniyyan bika 'an siwak",
    samplePhrase: "Allahumma ya Samad, ij'alni ghaniyyan bika 'an siwak",
  ),
  NameGuidance(
    name: 'Al-Wahid',
    arabic: 'الْوَاحِدُ',
    episode: 64,
    callFor: ['scattered focus', 'divided heart', 'people-pleasing', 'unifying intention for Allah'],
    invocationStyle: "Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak",
    samplePhrase: "Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak",
  ),
  NameGuidance(
    name: 'Al-Ahad',
    arabic: 'الْأَحَدُ',
    episode: 65,
    callFor: ['uniqueness of Allah', 'shirk protection', 'complete tawhid', 'under pressure like Bilal'],
    invocationStyle: "Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak",
    samplePhrase: "Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak",
  ),

  // Power cluster
  NameGuidance(
    name: 'Al-Qadir',
    arabic: 'الْقَادِرُ',
    episode: 66,
    callFor: ['what seems impossible', 'helplessness', 'seeking divine capability', 'blocked paths'],
    invocationStyle: "Ya Qadir, la ya'jizuka shay' faqdhi li hajati",
    samplePhrase: "Ya Qadir, la ya'jizuka shay' faqdhi li hajati wa-a'inni 'ala ma a'jazani",
  ),
  NameGuidance(
    name: 'Al-Muqtadir',
    arabic: 'الْمُقْتَدِرُ',
    episode: 67,
    callFor: ['complete powerlessness', 'overwhelming circumstances', 'needing omnipotent help'],
    invocationStyle: "Ya Muqtadir, arini qudrataka fi amri",
    samplePhrase: "Ya Muqtadir, arini qudrataka fi amri waj'al quwwataka hisni",
  ),
  NameGuidance(
    name: 'Al-Mateen',
    arabic: 'الْمَتِينُ',
    episode: 54,
    callFor: ['seeking firm ground', 'instability', 'feeling shaken', 'firmness in trials'],
    invocationStyle: "La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem",
    samplePhrase: "La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem",
  ),

  // Timing cluster
  NameGuidance(
    name: 'Al-Muqaddim',
    arabic: 'الْمُقَدِّمُ',
    episode: 71,
    callFor: ['timing and advancement', 'being passed over', 'trust in divine sequencing'],
    invocationStyle: "Allahumma ij'alni radiyan bima qasamta li wa barik li fihi",
    samplePhrase: "Allahumma ij'alni radiyan bima qasamta li wa barik li fihi",
  ),
  NameGuidance(
    name: 'Al-Muakhkhir',
    arabic: 'الْمُؤَخِّرُ',
    episode: 72,
    callFor: ['delayed answers', 'waiting on Allah', 'trust in divine timing', 'patience with delay'],
    invocationStyle: "Allahumma ij'alni radiyan bima qasamta li wa barik li fihi",
    samplePhrase: "Allahumma ij'alni radiyan bima qasamta li wa barik li fihi",
  ),

  // Restoration cluster
  NameGuidance(
    name: 'Al-Mubdi',
    arabic: 'الْمُبْدِئُ',
    episode: 58,
    callFor: ['fresh start', 'new chapter', 'repentance and beginning again', 'originality'],
    invocationStyle: "Ya Mubdi', ibda' li safhatan jadidatan",
    samplePhrase: "Ya Mubdi', ibda' li safhatan jadidatan wa-ahdith li tawbatan nasuhan",
  ),
  NameGuidance(
    name: 'Al-Muid',
    arabic: 'الْمُعِيدُ',
    episode: 59,
    callFor: ['restoration of what was lost', 'returning to good state', 'recovery', 'resurrection hope'],
    invocationStyle: "Ya Mu'id, a'id ilayya ma akhadhtahu minni aw abdilni khayran minh",
    samplePhrase: "Ya Mu'id, a'id ilayya ma akhadhtahu minni aw abdilni khayran minh",
  ),
  NameGuidance(
    name: 'Al-Wajid',
    arabic: 'الْوَاجِدُ',
    episode: 76,
    callFor: ['feeling lost', 'finding a way out', 'when all doors seem closed', 'Allah never at a loss'],
    invocationStyle: "Ya Wajid, awjid li makhrajam mimma ana fih",
    samplePhrase: "Ya Wajid, awjid li makhrajam mimma ana fih wa la takilni ila nafsi",
  ),

  // Accounting cluster
  NameGuidance(
    name: 'Al-Muhsi',
    arabic: 'الْمُحْصِي',
    episode: 57,
    callFor: ['fearing accountability', 'seeking pardon for recorded sins', 'hidden good deeds counted'],
    invocationStyle: "Ya Muhsi, la tuhasibni bima ahsaytahu 'alayya wa'fu 'anni birahmatik",
    samplePhrase: "Ya Muhsi, la tuhasibni bima ahsaytahu 'alayya wa'fu 'anni birahmatik",
  ),

  // Sovereignty cluster
  NameGuidance(
    name: 'Malik-ul-Mulk',
    arabic: 'مَالِكُ الْمُلْكِ',
    episode: 84,
    callFor: ['ultimate sovereignty', 'worldly power failing', 'divine ownership of all'],
    invocationStyle: "Allahumma Malikal-Mulk, tu'til-mulka man tasha'",
    samplePhrase: "Allahumma Malikal-Mulk, tu'til-mulka man tasha' wa tanzi'ul-mulka mimman tasha'",
  ),
  NameGuidance(
    name: 'Dhul-Jalali wal-Ikram',
    arabic: 'ذُو الْجَلَالِ وَالْإِكْرَامِ',
    episode: 85,
    callFor: ['seeking both awe and intimacy', 'majesty and mercy combined', 'protection from Fire'],
    invocationStyle: "Ya Dhal-Jalali wal-Ikram, ajirna minan-nar",
    samplePhrase: "Ya Dhal-Jalali wal-Ikram, ajirna minan-nar",
  ),

  // Wealth/withholding cluster
  NameGuidance(
    name: 'Al-Mani',
    arabic: 'الْمَانِعُ',
    episode: 91,
    callFor: ['divine withholding', 'what is blocked for your protection', 'understanding divine refusal'],
    invocationStyle: "Ya Mani', mna' 'anni kulla ma yuba'iduni 'ank",
    samplePhrase: "Ya Mani', mna' 'anni kulla ma yuba'iduni 'ank wa-a'tini kulla ma yuqarribuni ilayk",
  ),
  NameGuidance(
    name: 'Ad-Darr',
    arabic: 'الضَّارُّ',
    episode: 93,
    callFor: ['trials as purification', 'making sense of harm', 'pain with purpose', 'expiation'],
    invocationStyle: "Allahumma ij'al ma asabani min dharrin kaffaratan lidhunubi",
    samplePhrase: "Allahumma ij'al ma asabani min dharrin kaffaratan lidhunubi wa-raf'an lidarajati",
  ),
  NameGuidance(
    name: 'An-Nafi',
    arabic: 'النَّافِعُ',
    episode: 94,
    callFor: ['seeking benefit', 'beneficial knowledge', 'pure provision', 'accepted deeds'],
    invocationStyle: "Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbalan",
    samplePhrase: "Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbalan",
  ),

  // Praise/Nobility cluster
  NameGuidance(
    name: 'Al-Hameed',
    arabic: 'الْحَمِيدُ',
    episode: 56,
    callFor: ['gratitude in hardship', 'praising Allah through difficulty', 'hamd as worship'],
    invocationStyle: "Al-hamdu lillahi Rabbil 'aalameen hamdan katheeran tayyiban mubarakan feeh",
    samplePhrase: "Al-hamdu lillahi Rabbil 'aalameen hamdan katheeran tayyiban mubarakan feeh",
  ),
  NameGuidance(
    name: 'Al-Majeed',
    arabic: 'الْمَجِيدُ',
    episode: 77,
    callFor: ['generosity beyond deserving', 'awe of divine bounty', 'glorification'],
    invocationStyle: "Subhana Rabbiyal 'Azeem",
    samplePhrase: "Subhana Rabbiyal 'Azeem",
  ),
  NameGuidance(
    name: 'Al-Majid',
    arabic: 'الْمَاجِدُ',
    episode: 48,
    callFor: ['undeserved generosity', 'divine honor', 'nobility beyond merit'],
    invocationStyle: "Ya Majid, 'amilni bisakhaikhal-ladhi la astahiqquhu",
    samplePhrase: "Ya Majid, 'amilni bisakhaikhal-ladhi la astahiqquhu wa-akrimni biqurbik",
  ),

  // Guardianship cluster
  NameGuidance(
    name: 'Al-Waliyy',
    arabic: 'الْوَلِيُّ',
    episode: 34,
    callFor: ['friendship with Allah', 'loneliness', 'needing a companion in hardship', 'travel'],
    invocationStyle: "Allahumma anta's-sahibu fi's-safar wa'l-khalifatu fi'l-ahl",
    samplePhrase: "Allahumma anta's-sahibu fi's-safar wa'l-khalifatu fi'l-ahl",
  ),
  NameGuidance(
    name: 'Al-Wali',
    arabic: 'الْوَالِي',
    episode: 77,
    callFor: ['divine governance', 'needing someone to run things', 'total surrender', 'trust'],
    invocationStyle: "Ya Wali, kun li waliyyan hina yabtab'idud-dunya 'anni",
    samplePhrase: "Ya Wali, kun li waliyyan hina yabtab'idud-dunya 'anni wa-tawalla amri kullahu",
  ),
  NameGuidance(
    name: 'Al-Barr',
    arabic: 'الْبَرُّ',
    episode: 79,
    callFor: ['gratitude for goodness', 'source of all good', 'steadfastness in birr', 'faith in trials'],
    invocationStyle: "Ya Barr, thabbintni 'ala birrik",
    samplePhrase: "Ya Barr, thabbintni 'ala birrik waj'al imani rasikhana hina tartajifu qulub",
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
    translation: 'And send blessings, O Allah, upon our Prophet Muhammad and upon his family and companions, and all praise belongs to Allah, Lord of all the worlds.',
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
    transliteration: 'Al-hamdu lillahi alladhi hadana li-hadha wa-ma kunna li-nahtadiya lawla an hadana Allah',
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
