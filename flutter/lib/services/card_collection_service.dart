import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Card Tiers — evolving system (Bronze → Silver → Gold)
// ---------------------------------------------------------------------------

enum CardTier {
  bronze, // Tier 1: Name + meaning
  silver, // Tier 2: + hadith/prophetic teaching
  gold,   // Tier 3: + dua
}

extension CardTierX on CardTier {
  String get label {
    switch (this) {
      case CardTier.bronze:
        return 'Bronze';
      case CardTier.silver:
        return 'Silver';
      case CardTier.gold:
        return 'Gold';
    }
  }

  int get number {
    switch (this) {
      case CardTier.bronze:
        return 1;
      case CardTier.silver:
        return 2;
      case CardTier.gold:
        return 3;
    }
  }

  int get colorValue {
    switch (this) {
      case CardTier.bronze:
        return 0xFFCD7F32;
      case CardTier.silver:
        return 0xFFA8A9AD;
      case CardTier.gold:
        return 0xFFC8985E;
    }
  }

  static CardTier fromNumber(int n) {
    switch (n) {
      case 1:
        return CardTier.bronze;
      case 2:
        return CardTier.silver;
      case 3:
        return CardTier.gold;
      default:
        return CardTier.bronze;
    }
  }
}

// ---------------------------------------------------------------------------
// Collectible card definition
// ---------------------------------------------------------------------------

class CollectibleName {
  final int id;
  final String arabic;
  final String transliteration;
  final String english;
  final String meaning;
  final String lesson;

  // Tier 2 content
  final String hadith;

  // Tier 3 content
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;

  const CollectibleName({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.english,
    required this.meaning,
    required this.lesson,
    this.hadith = '',
    this.duaArabic = '',
    this.duaTransliteration = '',
    this.duaTranslation = '',
  });

  bool get hasTier2Content => hadith.isNotEmpty;
  bool get hasTier3Content => duaArabic.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Engage result
// ---------------------------------------------------------------------------

class CardEngageResult {
  final bool isNew;
  final int newTier; // 1, 2, or 3
  final bool tierChanged; // true if tier went up this engagement

  const CardEngageResult({
    required this.isNew,
    required this.newTier,
    required this.tierChanged,
  });

  CardTier get tier => CardTierX.fromNumber(newTier);
}

// ---------------------------------------------------------------------------
// All 99 Names with tier content
// ---------------------------------------------------------------------------

const List<CollectibleName> allCollectibleNames = [
  CollectibleName(
    id: 1, arabic: 'اللَّهُ', transliteration: 'Allah', english: 'God',
    meaning: 'The greatest Name — the proper name of God, encompassing all divine attributes.',
    lesson: 'Every other Name is an attribute of Allah. He is the one you call when no other name suffices.',
    hadith: 'The Prophet ﷺ said: "Allah has ninety-nine Names. Whoever memorizes and acts upon them will enter Paradise." (Bukhari)',
    duaArabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ',
    duaTransliteration: 'Allahumma inni as\'aluka bi kulli ismin huwa lak',
    duaTranslation: 'O Allah, I ask You by every Name that belongs to You.',
  ),
  CollectibleName(
    id: 2, arabic: 'الرَّحْمَنُ', transliteration: 'Ar-Rahman', english: 'The Most Gracious',
    meaning: 'The One whose mercy encompasses all creation without condition.',
    lesson: 'His mercy precedes His wrath. Every moment you breathe is a gift from Ar-Rahman.',
    hadith: 'The Prophet ﷺ said: "Allah divided mercy into 100 parts. He kept 99 parts with Himself and sent down one part to earth." (Muslim)',
    duaArabic: 'يَا رَحْمَنُ ارْحَمْنِي بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ',
    duaTransliteration: 'Ya Rahman irhamni bi rahmatika allati wasi\'at kulla shay',
    duaTranslation: 'O Most Gracious, have mercy on me with Your mercy that encompasses all things.',
  ),
  CollectibleName(
    id: 3, arabic: 'الرَّحِيمُ', transliteration: 'Ar-Raheem', english: 'The Most Merciful',
    meaning: 'The One whose special mercy is reserved for the believers.',
    lesson: 'Even when you feel distant, Ar-Raheem is drawing you back with mercy.',
    hadith: 'The Prophet ﷺ said: "Allah is more merciful to His servants than a mother is to her child." (Bukhari & Muslim)',
    duaArabic: 'رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
    duaTransliteration: 'Rabbana atina min ladunka rahmatan wa hayyi\' lana min amrina rashada',
    duaTranslation: 'Our Lord, grant us mercy from Yourself and guide us rightly through our affair.',
  ),
  CollectibleName(
    id: 4, arabic: 'الْمَلِكُ', transliteration: 'Al-Malik', english: 'The King',
    meaning: 'The absolute sovereign who owns and governs all existence.',
    lesson: "When the world's kings fail you, Al-Malik never abandons His servants.",
    hadith: 'The Prophet ﷺ said: "Allah will fold the heavens on the Day of Resurrection, then He will say: I am the King, where are the kings of the earth?" (Bukhari)',
    duaArabic: 'اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ',
    duaTransliteration: 'Allahumma Malikal-Mulk tu\'til-mulka man tasha\'',
    duaTranslation: 'O Allah, Owner of Sovereignty, You give sovereignty to whom You will.',
  ),
  CollectibleName(
    id: 5, arabic: 'الْقُدُّوسُ', transliteration: 'Al-Quddus', english: 'The Most Holy',
    meaning: 'The One free from all imperfection, deficiency, and fault.',
    lesson: 'In a world full of imperfection, Al-Quddus is your anchor of purity.',
    hadith: 'The angels glorify Him saying: "Holy, Holy, Holy is the Lord of the angels and the spirit." (Muslim)',
    duaArabic: 'سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلَائِكَةِ وَالرُّوحِ',
    duaTransliteration: 'Subbuhun Quddusun Rabbul-mala\'ikati war-ruh',
    duaTranslation: 'Glorified, Holy, Lord of the angels and the spirit.',
  ),
  CollectibleName(
    id: 6, arabic: 'السَّلَامُ', transliteration: 'As-Salam', english: 'The Source of Peace',
    meaning: 'The One from whom all peace flows and in whom all peace rests.',
    lesson: 'True peace is not the absence of struggle — it is As-Salam dwelling in your heart.',
    hadith: 'The Prophet ﷺ said: "Spread peace, feed the hungry, pray at night while people sleep, and you will enter Paradise in peace." (Tirmidhi)',
    duaArabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    duaTransliteration: 'Allahumma Antas-Salam wa minkas-salam tabarakta ya Dhal-Jalali wal-Ikram',
    duaTranslation: 'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of Majesty and Honor.',
  ),
  CollectibleName(
    id: 7, arabic: 'الْمُؤْمِنُ', transliteration: 'Al-Mumin', english: 'The Guardian of Faith',
    meaning: 'The One who grants safety and confirms the faith of His servants.',
    lesson: 'Al-Mumin sees your sincerity even when others doubt you.',
    hadith: 'The Prophet ﷺ said: "The believer is a mirror to his brother." (Abu Dawud). Al-Mumin protects faith in every heart that seeks Him.',
    duaArabic: 'اللَّهُمَّ ثَبِّتْنَا عَلَى الْإِيمَانِ',
    duaTransliteration: 'Allahumma thabbitna \'alal-iman',
    duaTranslation: 'O Allah, make us firm upon faith.',
  ),
  CollectibleName(
    id: 8, arabic: 'الْعَزِيزُ', transliteration: 'Al-Azeez', english: 'The Almighty',
    meaning: 'The One of perfect might and honor who is never overcome.',
    lesson: 'Lean on Al-Azeez. You are not weak when you call upon Him.',
    hadith: 'The Prophet ﷺ said: "Might belongs to Allah, His Messenger, and the believers." (Quran 63:8)',
    duaArabic: 'يَا عَزِيزُ أَعِزَّنِي بِطَاعَتِكَ',
    duaTransliteration: 'Ya Azeez a\'izzani bi ta\'atik',
    duaTranslation: 'O Almighty, honor me through obedience to You.',
  ),
  CollectibleName(
    id: 9, arabic: 'الْجَبَّارُ', transliteration: 'Al-Jabbar', english: 'The Compeller',
    meaning: 'The One who mends what is broken and compels all to His will.',
    lesson: 'Al-Jabbar heals broken hearts. Bring Him your shattered pieces.',
    hadith: 'The Prophet ﷺ used to say in his prostration: "My face has prostrated to the One who created it and fashioned it, and split open its hearing and sight, by His might and power." (Tirmidhi)',
    duaArabic: 'يَا جَبَّارُ اجْبُرْ كَسْرِي',
    duaTransliteration: 'Ya Jabbar ujbur kasri',
    duaTranslation: 'O Compeller, mend my brokenness.',
  ),
  CollectibleName(
    id: 10, arabic: 'الْخَالِقُ', transliteration: 'Al-Khaliq', english: 'The Creator',
    meaning: 'The One who brings everything into existence from nothing.',
    lesson: 'You are not an accident. Al-Khaliq designed every detail of you with purpose.',
    hadith: 'The Prophet ﷺ said: "Allah created Adam in His image." (Bukhari & Muslim). You carry the honor of divine creation.',
    duaArabic: 'رَبَّنَا مَا خَلَقْتَ هَذَا بَاطِلًا سُبْحَانَكَ',
    duaTransliteration: 'Rabbana ma khalaqta hadha batilan subhanak',
    duaTranslation: 'Our Lord, You have not created this in vain. Glory be to You.',
  ),
  CollectibleName(
    id: 11, arabic: 'الْغَفَّارُ', transliteration: 'Al-Ghaffar', english: 'The Ever-Forgiving',
    meaning: 'The One who forgives sins repeatedly and covers faults completely.',
    lesson: "Al-Ghaffar's door never closes. Return as many times as you fall.",
    hadith: 'The Prophet ﷺ said: "By Allah, I seek forgiveness from Allah and repent to Him more than seventy times a day." (Bukhari)',
    duaArabic: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الْغَفُورُ',
    duaTransliteration: 'Rabbighfir li wa tub \'alayya innaka Antat-Tawwabul-Ghafur',
    duaTranslation: 'My Lord, forgive me and accept my repentance. You are the Acceptor of Repentance, the Forgiving.',
  ),
  CollectibleName(
    id: 12, arabic: 'الْوَهَّابُ', transliteration: 'Al-Wahhab', english: 'The Bestower',
    meaning: 'The One who gives endlessly without expecting anything in return.',
    lesson: 'Every gift you have — talent, love, breath — is from Al-Wahhab.',
    hadith: 'The Prophet ﷺ said: "The hand of Allah is full, and spending does not diminish it. He gives abundantly day and night." (Bukhari)',
    duaArabic: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً',
    duaTransliteration: 'Rabbana la tuzigh qulubana ba\'da idh hadaytana wa hab lana min ladunka rahmah',
    duaTranslation: 'Our Lord, do not let our hearts deviate after You have guided us, and grant us mercy from Yourself.',
  ),
  CollectibleName(
    id: 13, arabic: 'الرَّزَّاقُ', transliteration: 'Ar-Razzaq', english: 'The Provider',
    meaning: 'The One who provides all sustenance, seen and unseen.',
    lesson: 'Worry less. Ar-Razzaq has written your provision before you were born.',
    hadith: 'The Prophet ﷺ said: "If you relied on Allah as He should be relied upon, He would provide for you as He provides for the birds — they go out hungry in the morning and return full in the evening." (Tirmidhi)',
    duaArabic: 'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    duaTransliteration: 'Allahumma ikfini bi halalika \'an haramik wa aghnini bi fadlika amman siwak',
    duaTranslation: 'O Allah, suffice me with what is lawful against what is unlawful, and enrich me by Your favor over all others.',
  ),
  CollectibleName(
    id: 14, arabic: 'الْعَلِيمُ', transliteration: 'Al-Aleem', english: 'The All-Knowing',
    meaning: 'The One whose knowledge encompasses everything, hidden and apparent.',
    lesson: 'You never need to explain your pain to Al-Aleem. He already knows.',
    hadith: 'The Prophet ﷺ said: "Allah knew what His servants would do, and He wrote it all fifty thousand years before creating the heavens and the earth." (Muslim)',
    duaArabic: 'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ',
    duaTransliteration: 'Allahumma \'Alimal-ghaybi wash-shahadah, Fatiras-samawati wal-ard',
    duaTranslation: 'O Allah, Knower of the unseen and the seen, Originator of the heavens and the earth.',
  ),
  CollectibleName(
    id: 15, arabic: 'الْحَيُّ', transliteration: 'Al-Hayy', english: 'The Ever-Living',
    meaning: 'The One who has always lived and will never die.',
    lesson: 'Everything you lean on will pass away — except Al-Hayy.',
    hadith: 'The Prophet ﷺ said: "Call upon Allah using \'Ya Hayyu Ya Qayyum\' — by Your mercy I seek relief." (Tirmidhi)',
    duaArabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    duaTransliteration: 'Ya Hayyu Ya Qayyum bi rahmatika astaghith',
    duaTranslation: 'O Ever-Living, O Self-Sustaining, by Your mercy I seek relief.',
  ),
  // ── Remaining Names (tier 2/3 content to be added) ──
  CollectibleName(id: 16, arabic: 'الْقَيُّومُ', transliteration: 'Al-Qayyum', english: 'The Self-Sustaining', meaning: 'The One who sustains all of creation by His power.', lesson: 'You do not sustain yourself. Al-Qayyum holds you together even when you feel like falling apart.'),
  CollectibleName(id: 17, arabic: 'النُّورُ', transliteration: 'An-Nur', english: 'The Light', meaning: 'The One who illuminates the heavens, the earth, and every heart.', lesson: 'When darkness surrounds you, An-Nur is the light that no shadow can extinguish.'),
  CollectibleName(id: 18, arabic: 'الْمُهَيْمِنُ', transliteration: 'Al-Muhaymin', english: 'The Overseer', meaning: 'The One who watches over and protects all things.', lesson: 'Nothing escapes His watchful care. Al-Muhaymin guards what you cannot.'),
  CollectibleName(id: 19, arabic: 'الْمُتَكَبِّرُ', transliteration: 'Al-Mutakabbir', english: 'The Supreme', meaning: 'The One whose greatness is beyond all comparison.', lesson: 'True greatness belongs only to Al-Mutakabbir. In recognizing this, you find humility.'),
  CollectibleName(id: 20, arabic: 'الْبَارِئُ', transliteration: 'Al-Bari', english: 'The Evolver', meaning: 'The One who shapes creation according to His perfect plan.', lesson: 'Al-Bari is still shaping you. Your story is not finished yet.'),
  CollectibleName(id: 21, arabic: 'الْمُصَوِّرُ', transliteration: 'Al-Musawwir', english: 'The Fashioner', meaning: 'The One who gives each creation its unique form and beauty.', lesson: 'Your face, your fingerprint, your soul — Al-Musawwir made you one of a kind.'),
  CollectibleName(id: 22, arabic: 'الْقَهَّارُ', transliteration: 'Al-Qahhar', english: 'The Subduer', meaning: 'The One who overcomes all and to whom everything submits.', lesson: 'The tyrant you fear is nothing before Al-Qahhar.'),
  CollectibleName(id: 23, arabic: 'الْفَتَّاحُ', transliteration: 'Al-Fattah', english: 'The Opener', meaning: 'The One who opens the doors of mercy, provision, and guidance.', lesson: 'When every door seems closed, Al-Fattah opens ways you never imagined.'),
  CollectibleName(id: 24, arabic: 'الْقَابِضُ', transliteration: 'Al-Qabid', english: 'The Withholder', meaning: 'The One who contracts, withholds, and tests through scarcity.', lesson: 'Sometimes Al-Qabid withholds to protect you from what would harm you.'),
  CollectibleName(id: 25, arabic: 'الْبَاسِطُ', transliteration: 'Al-Basit', english: 'The Expander', meaning: 'The One who expands, extends, and gives abundantly.', lesson: 'After every constriction comes expansion. Trust the rhythm of Al-Basit.'),
  CollectibleName(id: 26, arabic: 'الْحَكِيمُ', transliteration: 'Al-Hakeem', english: 'The All-Wise', meaning: 'The One who acts with perfect wisdom in everything He decrees.', lesson: "You may not understand the plan, but Al-Hakeem's wisdom never errs."),
  CollectibleName(id: 27, arabic: 'الْوَدُودُ', transliteration: 'Al-Wadud', english: 'The Most Loving', meaning: 'The One whose love for His servants is unconditional and constant.', lesson: 'Al-Wadud loves you not for your perfection but for your turning toward Him.'),
  CollectibleName(id: 28, arabic: 'الشَّكُورُ', transliteration: 'Ash-Shakur', english: 'The Most Appreciative', meaning: 'The One who rewards abundantly for the smallest good deed.', lesson: 'Even your private acts of goodness are seen and multiplied by Ash-Shakur.'),
  CollectibleName(id: 29, arabic: 'الْحَلِيمُ', transliteration: 'Al-Haleem', english: 'The Forbearing', meaning: 'The One who withholds punishment despite having full power to act.', lesson: "That you are still here, still trying — this is Al-Haleem's patience with you."),
  CollectibleName(id: 30, arabic: 'الْكَرِيمُ', transliteration: 'Al-Kareem', english: 'The Most Generous', meaning: 'The One whose generosity is without limit or expectation.', lesson: 'Ask Al-Kareem without shame. His generosity is never depleted.'),
  CollectibleName(id: 31, arabic: 'التَّوَّابُ', transliteration: 'At-Tawwab', english: 'The Acceptor of Repentance', meaning: 'The One who turns toward His servants when they turn toward Him.', lesson: 'You took one step back to Him — At-Tawwab is already running toward you.'),
  CollectibleName(id: 32, arabic: 'الصَّبُورُ', transliteration: 'As-Sabur', english: 'The Patient', meaning: 'The One who is patient with the disobedience of His creation.', lesson: 'As-Sabur does not rush you. He waits for you with open arms.'),
  CollectibleName(id: 33, arabic: 'الْهَادِي', transliteration: 'Al-Hadi', english: 'The Guide', meaning: 'The One who guides hearts to truth and feet to the straight path.', lesson: 'You are not lost. Al-Hadi placed the longing for guidance in your heart.'),
  CollectibleName(id: 34, arabic: 'الصَّمَدُ', transliteration: 'As-Samad', english: 'The Eternal Refuge', meaning: 'The One to whom all creation turns in need, yet He needs nothing.', lesson: 'When you have nowhere to turn, As-Samad is the refuge that never turns you away.'),
  CollectibleName(id: 35, arabic: 'الْوَكِيلُ', transliteration: 'Al-Wakeel', english: 'The Trustee', meaning: 'The One who is sufficient as a guardian and disposer of affairs.', lesson: 'Hand it over to Al-Wakeel. He manages what you cannot.'),
  CollectibleName(id: 36, arabic: 'اللَّطِيفُ', transliteration: 'Al-Lateef', english: 'The Subtle', meaning: 'The One who is aware of the finest details and acts with gentleness.', lesson: 'Al-Lateef works in ways you cannot see, arranging what you cannot plan.'),
  CollectibleName(id: 37, arabic: 'الْمُجِيبُ', transliteration: 'Al-Mujeeb', english: 'The Responsive', meaning: 'The One who answers the call of those who call upon Him.', lesson: 'Your dua was heard the moment your lips moved. Al-Mujeeb is already responding.'),
  CollectibleName(id: 38, arabic: 'الشَّافِي', transliteration: 'Ash-Shafi', english: 'The Healer', meaning: 'The One who cures every illness of body and soul.', lesson: 'No wound is too deep for Ash-Shafi. He heals what medicine cannot reach.'),
  CollectibleName(id: 39, arabic: 'الْحَفِيظُ', transliteration: 'Al-Hafeez', english: 'The Preserver', meaning: 'The One who guards and protects all things in His care.', lesson: 'Everything you love is in the hands of Al-Hafeez — even when you cannot hold it.'),
  CollectibleName(id: 40, arabic: 'الرَّقِيبُ', transliteration: 'Ar-Raqeeb', english: 'The Watchful', meaning: 'The One who sees every action, thought, and intention.', lesson: 'Ar-Raqeeb sees the good you do in secret. Nothing is wasted.'),
  CollectibleName(id: 41, arabic: 'الْخَافِضُ', transliteration: 'Al-Khafid', english: 'The Abaser', meaning: 'The One who lowers whoever He wills by His wisdom.', lesson: 'Al-Khafid humbles the arrogant and reminds us that all status belongs to Him.'),
  CollectibleName(id: 42, arabic: 'الرَّافِعُ', transliteration: 'Ar-Rafi', english: 'The Exalter', meaning: 'The One who raises His servants in rank and honor.', lesson: 'Ar-Rafi elevates those who humble themselves before Him.'),
  CollectibleName(id: 43, arabic: 'الْمُعِزُّ', transliteration: 'Al-Muizz', english: 'The Bestower of Honor', meaning: 'The One who gives honor and dignity to whom He wills.', lesson: 'True honor comes from Al-Muizz, not from people or positions.'),
  CollectibleName(id: 44, arabic: 'الْمُذِلُّ', transliteration: 'Al-Muzill', english: 'The Humiliator', meaning: 'The One who disgraces those who defy His command.', lesson: 'Al-Muzill reminds us that no empire lasts without His permission.'),
  CollectibleName(id: 45, arabic: 'السَّمِيعُ', transliteration: 'As-Sami', english: 'The All-Hearing', meaning: 'The One who hears every sound, whisper, and silent prayer.', lesson: 'Even the prayer you could not put into words — As-Sami heard it.'),
  CollectibleName(id: 46, arabic: 'الْبَصِيرُ', transliteration: 'Al-Baseer', english: 'The All-Seeing', meaning: 'The One who sees all things, open and hidden.', lesson: 'Al-Baseer witnesses your struggle even when no one else does.'),
  CollectibleName(id: 47, arabic: 'الْحَكَمُ', transliteration: 'Al-Hakam', english: 'The Judge', meaning: 'The One whose judgment is absolute and perfectly just.', lesson: 'When the world is unjust, remember that Al-Hakam will settle every account.'),
  CollectibleName(id: 48, arabic: 'الْعَدْلُ', transliteration: 'Al-Adl', english: 'The Just', meaning: 'The One who is perfectly balanced in all He does.', lesson: 'Al-Adl will never wrong you — not by the weight of an atom.'),
  CollectibleName(id: 49, arabic: 'الْخَبِيرُ', transliteration: 'Al-Khabeer', english: 'The All-Aware', meaning: 'The One who is aware of the inner reality of all things.', lesson: 'You do not need to pretend with Al-Khabeer. He knows your truth already.'),
  CollectibleName(id: 50, arabic: 'الْعَظِيمُ', transliteration: 'Al-Azeem', english: 'The Magnificent', meaning: 'The One whose greatness is beyond human comprehension.', lesson: 'Your problems feel massive — until you remember the magnificence of Al-Azeem.'),
  CollectibleName(id: 51, arabic: 'الْغَفُورُ', transliteration: 'Al-Ghafur', english: 'The Forgiving', meaning: 'The One who forgives and conceals faults with grace.', lesson: 'Al-Ghafur does not just forgive — He erases the sin as if it never happened.'),
  CollectibleName(id: 52, arabic: 'الْعَلِيُّ', transliteration: 'Al-Ali', english: 'The Most High', meaning: 'The One who is above all creation in rank and majesty.', lesson: 'When you prostrate to Al-Ali, you reach the highest station a human can attain.'),
  CollectibleName(id: 53, arabic: 'الْكَبِيرُ', transliteration: 'Al-Kabeer', english: 'The Greatest', meaning: 'The One who is greater than everything in existence.', lesson: 'Whatever towers over you in fear — Al-Kabeer is greater than it.'),
  CollectibleName(id: 54, arabic: 'الْمُقِيتُ', transliteration: 'Al-Muqeet', english: 'The Nourisher', meaning: 'The One who nourishes and sustains every living thing.', lesson: 'Al-Muqeet feeds not only your body but your soul and your purpose.'),
  CollectibleName(id: 55, arabic: 'الْحَسِيبُ', transliteration: 'Al-Haseeb', english: 'The Reckoner', meaning: 'The One who takes account of all deeds with precision.', lesson: 'Al-Haseeb counts every kindness. Nothing good is ever lost.'),
  CollectibleName(id: 56, arabic: 'الْجَلِيلُ', transliteration: 'Al-Jaleel', english: 'The Majestic', meaning: 'The One of overwhelming majesty and grandeur.', lesson: 'Stand in awe of Al-Jaleel, and the things you feared will shrink.'),
  CollectibleName(id: 57, arabic: 'الْوَاسِعُ', transliteration: 'Al-Wasi', english: 'The All-Encompassing', meaning: 'The One whose mercy, knowledge, and provision encompass everything.', lesson: 'Your need is never too big for Al-Wasi. His capacity has no limit.'),
  CollectibleName(id: 58, arabic: 'الْمَجِيدُ', transliteration: 'Al-Majeed', english: 'The Glorious', meaning: 'The One who is glorious and generous in all His actions.', lesson: 'Al-Majeed combines greatness with generosity — He is both awe-inspiring and giving.'),
  CollectibleName(id: 59, arabic: 'الْبَاعِثُ', transliteration: 'Al-Baith', english: 'The Resurrector', meaning: 'The One who raises the dead and brings all to account.', lesson: 'Al-Baith can revive a dead heart just as He will raise the dead on the Last Day.'),
  CollectibleName(id: 60, arabic: 'الشَّهِيدُ', transliteration: 'Ash-Shaheed', english: 'The Witness', meaning: 'The One who witnesses all things at all times.', lesson: 'Your silent sacrifice is not unseen. Ash-Shaheed was there.'),
  CollectibleName(id: 61, arabic: 'الْحَقُّ', transliteration: 'Al-Haqq', english: 'The Truth', meaning: 'The One who is the ultimate reality and absolute truth.', lesson: 'In a world of illusions, Al-Haqq is the only certainty you need.'),
  CollectibleName(id: 62, arabic: 'الْقَوِيُّ', transliteration: 'Al-Qawiyy', english: 'The Strong', meaning: 'The One whose strength is unlimited and never weakens.', lesson: 'When you feel powerless, Al-Qawiyy lends strength to those who rely on Him.'),
  CollectibleName(id: 63, arabic: 'الْمَتِينُ', transliteration: 'Al-Mateen', english: 'The Firm', meaning: 'The One whose power is unshakeable and inexhaustible.', lesson: 'When everything around you is shaking, Al-Mateen is the unshakeable ground.'),
  CollectibleName(id: 64, arabic: 'الْوَلِيُّ', transliteration: 'Al-Waliyy', english: 'The Protecting Friend', meaning: 'The One who is the helper and protector of the believers.', lesson: 'You are never alone. Al-Waliyy is closer to you than your own loneliness.'),
  CollectibleName(id: 65, arabic: 'الْحَمِيدُ', transliteration: 'Al-Hameed', english: 'The Praiseworthy', meaning: 'The One who is worthy of all praise in every situation.', lesson: 'Even in hardship, Al-Hameed deserves praise — and praising Him transforms the hardship.'),
  CollectibleName(id: 66, arabic: 'الْمُحْصِي', transliteration: 'Al-Muhsi', english: 'The Counter', meaning: 'The One who counts and records everything with precision.', lesson: 'Al-Muhsi has numbered every tear you have shed. None are forgotten.'),
  CollectibleName(id: 67, arabic: 'الْمُبْدِئُ', transliteration: 'Al-Mubdi', english: 'The Originator', meaning: 'The One who begins creation without any prior model.', lesson: 'Al-Mubdi created you as something entirely new. You are not a copy.'),
  CollectibleName(id: 68, arabic: 'الْمُعِيدُ', transliteration: 'Al-Muid', english: 'The Restorer', meaning: 'The One who brings back creation after its end.', lesson: 'What was taken from you — Al-Muid can restore it, or replace it with better.'),
  CollectibleName(id: 69, arabic: 'الْمُحْيِي', transliteration: 'Al-Muhyi', english: 'The Giver of Life', meaning: 'The One who gives life to the dead and to all living things.', lesson: 'Al-Muhyi can breathe life into your hopes when they feel dead.'),
  CollectibleName(id: 70, arabic: 'الْمُمِيتُ', transliteration: 'Al-Mumeet', english: 'The Bringer of Death', meaning: 'The One who takes life at its appointed time.', lesson: 'Al-Mumeet reminds us that this world is temporary — live for what lasts.'),
  CollectibleName(id: 71, arabic: 'الْوَاجِدُ', transliteration: 'Al-Wajid', english: 'The Finder', meaning: 'The One who finds whatever He wills and lacks nothing.', lesson: 'Al-Wajid is never at a loss. He always finds a way for you.'),
  CollectibleName(id: 72, arabic: 'الْمَاجِدُ', transliteration: 'Al-Majid', english: 'The Noble', meaning: 'The One whose nobility and generosity overflow.', lesson: 'Al-Majid treats you with a generosity you could never earn.'),
  CollectibleName(id: 73, arabic: 'الْوَاحِدُ', transliteration: 'Al-Wahid', english: 'The One', meaning: 'The One who is unique and without partner in His essence.', lesson: 'Al-Wahid is the only One who will never let you down.'),
  CollectibleName(id: 74, arabic: 'الْأَحَدُ', transliteration: 'Al-Ahad', english: 'The Unique', meaning: 'The One who is absolutely singular, indivisible, and incomparable.', lesson: 'Nothing compares to Al-Ahad. And nothing compares to the peace of knowing Him.'),
  CollectibleName(id: 75, arabic: 'الْقَادِرُ', transliteration: 'Al-Qadir', english: 'The Capable', meaning: 'The One who has power over all things without effort.', lesson: 'What seems impossible to you is effortless for Al-Qadir.'),
  CollectibleName(id: 76, arabic: 'الْمُقْتَدِرُ', transliteration: 'Al-Muqtadir', english: 'The Omnipotent', meaning: 'The One who prevails over all things through His absolute power.', lesson: 'Al-Muqtadir has power even over the things that overpower you.'),
  CollectibleName(id: 77, arabic: 'الْمُقَدِّمُ', transliteration: 'Al-Muqaddim', english: 'The Expediter', meaning: 'The One who brings forward whatever He wills.', lesson: 'Al-Muqaddim advances what is good for you, even when you cannot see the timing.'),
  CollectibleName(id: 78, arabic: 'الْمُؤَخِّرُ', transliteration: 'Al-Muakhkhir', english: 'The Delayer', meaning: 'The One who delays whatever He wills in His wisdom.', lesson: 'What Al-Muakhkhir delays is not denied — it is being perfected.'),
  CollectibleName(id: 79, arabic: 'الْأَوَّلُ', transliteration: 'Al-Awwal', english: 'The First', meaning: 'The One who existed before all creation, with no beginning.', lesson: 'Before your worries existed, Al-Awwal was already there with the solution.'),
  CollectibleName(id: 80, arabic: 'الْآخِرُ', transliteration: 'Al-Akhir', english: 'The Last', meaning: 'The One who remains after all creation has perished.', lesson: 'Everything ends — except Al-Akhir. Invest in what reaches Him.'),
  CollectibleName(id: 81, arabic: 'الظَّاهِرُ', transliteration: 'Az-Zahir', english: 'The Manifest', meaning: 'The One whose existence is evident in all creation.', lesson: 'Look at the sky, the mountains, a newborn — Az-Zahir is manifest everywhere.'),
  CollectibleName(id: 82, arabic: 'الْبَاطِنُ', transliteration: 'Al-Batin', english: 'The Hidden', meaning: 'The One who is hidden from human perception yet closer than all.', lesson: 'Al-Batin is invisible to the eyes but unmistakable to the heart.'),
  CollectibleName(id: 83, arabic: 'الْوَالِي', transliteration: 'Al-Wali', english: 'The Governor', meaning: 'The One who governs and manages all affairs.', lesson: 'Al-Wali is running everything. You can rest.'),
  CollectibleName(id: 84, arabic: 'الْمُتَعَالِ', transliteration: 'Al-Mutaali', english: 'The Most Exalted', meaning: 'The One who is exalted above all that creation ascribes to Him.', lesson: 'No matter how grand your conception of God — Al-Mutaali is greater.'),
  CollectibleName(id: 85, arabic: 'الْبَرُّ', transliteration: 'Al-Barr', english: 'The Source of Goodness', meaning: 'The One who is the source of all kindness and benevolence.', lesson: 'Every good thing in your life traces back to Al-Barr.'),
  CollectibleName(id: 86, arabic: 'الْعَفُوُّ', transliteration: 'Al-Afuw', english: 'The Pardoner', meaning: 'The One who erases sins completely, as if they never happened.', lesson: "Al-Afuw doesn't just forgive — He wipes the slate clean entirely."),
  CollectibleName(id: 87, arabic: 'الرَّءُوفُ', transliteration: 'Ar-Rauf', english: 'The Compassionate', meaning: 'The One whose compassion is tender and overwhelmingly gentle.', lesson: "Ar-Rauf's compassion is softer than a mother's — and He never tires of it."),
  CollectibleName(id: 88, arabic: 'مَالِكُ الْمُلْكِ', transliteration: 'Malik-ul-Mulk', english: 'Owner of Sovereignty', meaning: 'The One who owns all dominion and grants it to whom He wills.', lesson: 'Kingdoms rise and fall by the decree of Malik-ul-Mulk alone.'),
  CollectibleName(id: 89, arabic: 'ذُو الْجَلَالِ وَالْإِكْرَامِ', transliteration: 'Dhul-Jalali wal-Ikram', english: 'Lord of Majesty and Bounty', meaning: 'The One who possesses both overwhelming majesty and abundant generosity.', lesson: 'He is both awe-inspiring and intimately generous. Majesty and mercy, together.'),
  CollectibleName(id: 90, arabic: 'الْمُقْسِطُ', transliteration: 'Al-Muqsit', english: 'The Equitable', meaning: 'The One who acts with perfect fairness and justice.', lesson: 'Al-Muqsit will balance every scale. Justice will come.'),
  CollectibleName(id: 91, arabic: 'الْجَامِعُ', transliteration: 'Al-Jami', english: 'The Gatherer', meaning: 'The One who gathers all creation on the Day of Judgment.', lesson: 'Al-Jami will bring together what was scattered — including your broken pieces.'),
  CollectibleName(id: 92, arabic: 'الْغَنِيُّ', transliteration: 'Al-Ghaniyy', english: 'The Self-Sufficient', meaning: 'The One who is free of all needs and upon whom all depend.', lesson: 'Al-Ghaniyy needs nothing from you — yet He invites you to ask.'),
  CollectibleName(id: 93, arabic: 'الْمُغْنِي', transliteration: 'Al-Mughni', english: 'The Enricher', meaning: 'The One who enriches whom He wills and frees them from need.', lesson: 'True richness is when Al-Mughni fills your heart, not just your hands.'),
  CollectibleName(id: 94, arabic: 'الْمَانِعُ', transliteration: 'Al-Mani', english: 'The Withholder', meaning: 'The One who prevents harm and withholds what would not benefit.', lesson: 'What Al-Mani withholds from you is also a form of His protection.'),
  CollectibleName(id: 95, arabic: 'الضَّارُّ', transliteration: 'Ad-Darr', english: 'The Distresser', meaning: 'The One who creates difficulty as a means of growth and return.', lesson: 'The pain you feel is not pointless — Ad-Darr uses it to bring you back.'),
  CollectibleName(id: 96, arabic: 'النَّافِعُ', transliteration: 'An-Nafi', english: 'The Benefiter', meaning: 'The One who creates benefit and good for His servants.', lesson: 'An-Nafi placed benefit in places you have not yet looked.'),
  CollectibleName(id: 97, arabic: 'الْبَدِيعُ', transliteration: 'Al-Badi', english: 'The Originator of the Heavens', meaning: 'The One who creates wonders without any prior model or material.', lesson: 'Al-Badi is endlessly creative. Your next chapter can be unlike anything before.'),
  CollectibleName(id: 98, arabic: 'الْبَاقِي', transliteration: 'Al-Baqi', english: 'The Everlasting', meaning: 'The One who remains forever after all creation has perished.', lesson: 'Attach your heart to Al-Baqi — everything else will pass away.'),
  CollectibleName(id: 99, arabic: 'الرَّشِيدُ', transliteration: 'Ar-Rasheed', english: 'The Guide to Right Path', meaning: 'The One who directs all affairs toward their right conclusion.', lesson: 'Ar-Rasheed is guiding your story to a conclusion better than you could write.'),
];

// ---------------------------------------------------------------------------
// Quick lookup by transliteration
// ---------------------------------------------------------------------------

String _normalize(String s) {
  var r = s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  r = r.replaceAll('ee', 'i');
  r = r.replaceAll('oo', 'u');
  r = r.replaceAll('aa', 'a');
  return r;
}

CollectibleName? findCollectibleByName(String name) {
  final norm = _normalize(name);

  for (final n in allCollectibleNames) {
    if (n.transliteration.toLowerCase() == name.toLowerCase().trim()) return n;
  }
  for (final n in allCollectibleNames) {
    if (_normalize(n.transliteration) == norm) return n;
  }
  final stripped = norm.replaceFirst(RegExp(r'^(al|ar|as|ash|at|az|an)'), '');
  for (final n in allCollectibleNames) {
    final nStripped = _normalize(n.transliteration)
        .replaceFirst(RegExp(r'^(al|ar|as|ash|at|az|an)'), '');
    if (nStripped == stripped && stripped.length > 2) return n;
  }
  for (final n in allCollectibleNames) {
    final key = _normalize(n.transliteration);
    if (key.contains(norm) || norm.contains(key)) return n;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Pick a card that can still be upgraded (for guaranteed tier-up reward)
// ---------------------------------------------------------------------------

CollectibleName? pickUpgradeableCard(CardCollectionState collection) {
  final upgradeable = allCollectibleNames.where((n) {
    final tier = collection.tierFor(n.id);
    return tier < 3; // not yet gold
  }).toList();
  if (upgradeable.isEmpty) return null;
  return upgradeable[math.Random().nextInt(upgradeable.length)];
}

// ---------------------------------------------------------------------------
// Collection persistence
// ---------------------------------------------------------------------------

const String _collectionKey = 'sakina_card_collection';

class CardCollectionState {
  final Set<int> discoveredIds;
  final Map<int, String> discoveryDates;
  final Map<int, int> tiers; // card id → tier (1, 2, or 3)

  const CardCollectionState({
    this.discoveredIds = const {},
    this.discoveryDates = const {},
    this.tiers = const {},
  });

  int get totalDiscovered => discoveredIds.length;
  int get totalCards => allCollectibleNames.length;
  double get progress => totalCards > 0 ? totalDiscovered / totalCards : 0;

  bool isDiscovered(int id) => discoveredIds.contains(id);

  int tierFor(int id) => tiers[id] ?? 0;
  CardTier? cardTierFor(int id) {
    final t = tiers[id];
    if (t == null || t == 0) return null;
    return CardTierX.fromNumber(t);
  }

  int countByTier(CardTier tier) {
    return discoveredIds.where((id) => tiers[id] == tier.number).length;
  }

  int get totalGold => countByTier(CardTier.gold);
  int get totalSilver => countByTier(CardTier.silver);
  int get totalBronze => countByTier(CardTier.bronze);
}

Future<CardCollectionState> getCardCollection() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_collectionKey);
  if (raw == null) return const CardCollectionState();

  final data = jsonDecode(raw) as Map<String, dynamic>;
  final ids = (data['ids'] as List<dynamic>?)?.cast<int>().toSet() ?? {};
  final dates = (data['dates'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), v as String)) ??
      {};
  final tiers = (data['tiers'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
      {};

  return CardCollectionState(discoveredIds: ids, discoveryDates: dates, tiers: tiers);
}

/// Engage with a card — discover it or upgrade its tier.
Future<CardEngageResult> engageCard(int cardId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_collectionKey);

  Set<int> ids;
  Map<int, String> dates;
  Map<int, int> tiers;

  if (raw != null) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    ids = (data['ids'] as List<dynamic>?)?.cast<int>().toSet() ?? {};
    dates = (data['dates'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), v as String)) ??
        {};
    tiers = (data['tiers'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
        {};
  } else {
    ids = {};
    dates = {};
    tiers = {};
  }

  final bool isNew = !ids.contains(cardId);
  final int currentTier = tiers[cardId] ?? 0;
  final int newTier;
  final bool tierChanged;

  if (isNew) {
    ids.add(cardId);
    dates[cardId] = DateTime.now().toIso8601String().substring(0, 10);
    newTier = 1;
    tierChanged = true;
  } else if (currentTier < 3) {
    newTier = currentTier + 1;
    tierChanged = true;
  } else {
    newTier = 3;
    tierChanged = false;
  }

  tiers[cardId] = newTier;

  await prefs.setString(
    _collectionKey,
    jsonEncode({
      'ids': ids.toList(),
      'dates': dates.map((k, v) => MapEntry(k.toString(), v)),
      'tiers': tiers.map((k, v) => MapEntry(k.toString(), v)),
    }),
  );

  return CardEngageResult(isNew: isNew, newTier: newTier, tierChanged: tierChanged);
}
