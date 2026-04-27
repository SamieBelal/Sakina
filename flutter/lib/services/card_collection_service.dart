import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Card Tiers — evolving system (Bronze → Silver → Gold)
// ---------------------------------------------------------------------------

enum CardTier {
  bronze, // Tier 1: Name + meaning
  silver, // Tier 2: + hadith/prophetic teaching
  gold, // Tier 3: + dua
  emerald, // Tier 4: rare/special variant (DB enum value added 2026-04-26)
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
      case CardTier.emerald:
        return 'Emerald';
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
      case CardTier.emerald:
        return 4;
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
      case CardTier.emerald:
        return 0xFF50C878;
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
      case 4:
        return CardTier.emerald;
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

  factory CollectibleName.fromJson(Map<String, dynamic> json) {
    return CollectibleName(
      id: (json['id'] as num?)?.toInt() ?? 0,
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      english: json['english'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      lesson: json['lesson'] as String? ?? '',
      hadith: json['hadith'] as String? ?? '',
      duaArabic: json['dua_arabic'] as String? ?? '',
      duaTransliteration: json['dua_transliteration'] as String? ?? '',
      duaTranslation: json['dua_translation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arabic': arabic,
      'transliteration': transliteration,
      'english': english,
      'meaning': meaning,
      'lesson': lesson,
      'hadith': hadith,
      'dua_arabic': duaArabic,
      'dua_transliteration': duaTransliteration,
      'dua_translation': duaTranslation,
    };
  }
}

// ---------------------------------------------------------------------------
// Engage result
// ---------------------------------------------------------------------------

class CardEngageResult {
  final bool isNew;
  final int newTier; // 1, 2, or 3
  final bool tierChanged; // true if tier went up this engagement
  final bool
      isDuplicate; // true if card was already at max tier or cooldown not met

  const CardEngageResult({
    required this.isNew,
    required this.newTier,
    required this.tierChanged,
    this.isDuplicate = false,
  });

  CardTier get tier => CardTierX.fromNumber(newTier);
}

// ---------------------------------------------------------------------------
// All 99 Names with tier content
// ---------------------------------------------------------------------------

const List<CollectibleName> allCollectibleNames = [
  CollectibleName(
    id: 1,
    arabic: 'اللَّهُ',
    transliteration: 'Allah',
    english: 'God',
    meaning:
        'The greatest Name — the proper name of God, encompassing all divine attributes.',
    lesson:
        'Every other Name is an attribute of Allah. He is the one you call when no other name suffices.',
    hadith:
        'The Prophet ﷺ said: "Allah has ninety-nine Names. Whoever memorizes and acts upon them will enter Paradise." (Bukhari)',
    duaArabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ',
    duaTransliteration: 'Allahumma inni as\'aluka bi kulli ismin huwa lak',
    duaTranslation: 'O Allah, I ask You by every Name that belongs to You.',
  ),
  CollectibleName(
    id: 2,
    arabic: 'الرَّحْمَنُ',
    transliteration: 'Ar-Rahman',
    english: 'The Most Gracious',
    meaning: 'The One whose mercy encompasses all creation without condition.',
    lesson:
        'His mercy precedes His wrath. Every moment you breathe is a gift from Ar-Rahman.',
    hadith:
        'The Prophet ﷺ said: "Allah divided mercy into 100 parts. He kept 99 parts with Himself and sent down one part to earth." (Muslim)',
    duaArabic:
        'يَا رَحْمَنُ ارْحَمْنِي بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ',
    duaTransliteration:
        'Ya Rahman irhamni bi rahmatika allati wasi\'at kulla shay',
    duaTranslation:
        'O Most Gracious, have mercy on me with Your mercy that encompasses all things.',
  ),
  CollectibleName(
    id: 3,
    arabic: 'الرَّحِيمُ',
    transliteration: 'Ar-Raheem',
    english: 'The Most Merciful',
    meaning: 'The One whose special mercy is reserved for the believers.',
    lesson:
        'Even when you feel distant, Ar-Raheem is drawing you back with mercy.',
    hadith:
        'The Prophet ﷺ said: "Allah is more merciful to His servants than a mother is to her child." (Bukhari & Muslim)',
    duaArabic:
        'رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
    duaTransliteration:
        'Rabbana atina min ladunka rahmatan wa hayyi\' lana min amrina rashada',
    duaTranslation:
        'Our Lord, grant us mercy from Yourself and guide us rightly through our affair.',
  ),
  CollectibleName(
    id: 4,
    arabic: 'الْمَلِكُ',
    transliteration: 'Al-Malik',
    english: 'The King',
    meaning: 'The absolute sovereign who owns and governs all existence.',
    lesson:
        "When the world's kings fail you, Al-Malik never abandons His servants.",
    hadith:
        'The Prophet ﷺ said: "Allah will fold the heavens on the Day of Resurrection, then He will say: I am the King, where are the kings of the earth?" (Bukhari)',
    duaArabic: 'اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ',
    duaTransliteration: 'Allahumma Malikal-Mulk tu\'til-mulka man tasha\'',
    duaTranslation:
        'O Allah, Owner of Sovereignty, You give sovereignty to whom You will.',
  ),
  CollectibleName(
    id: 5,
    arabic: 'الْقُدُّوسُ',
    transliteration: 'Al-Quddus',
    english: 'The Most Holy',
    meaning: 'The One free from all imperfection, deficiency, and fault.',
    lesson:
        'In a world full of imperfection, Al-Quddus is your anchor of purity.',
    hadith:
        'The angels glorify Him saying: "Holy, Holy, Holy is the Lord of the angels and the spirit." (Muslim)',
    duaArabic: 'سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلَائِكَةِ وَالرُّوحِ',
    duaTransliteration: 'Subbuhun Quddusun Rabbul-mala\'ikati war-ruh',
    duaTranslation: 'Glorified, Holy, Lord of the angels and the spirit.',
  ),
  CollectibleName(
    id: 6,
    arabic: 'السَّلَامُ',
    transliteration: 'As-Salam',
    english: 'The Source of Peace',
    meaning: 'The One from whom all peace flows and in whom all peace rests.',
    lesson:
        'True peace is not the absence of struggle — it is As-Salam dwelling in your heart.',
    hadith:
        'The Prophet ﷺ said: "Spread peace, feed the hungry, pray at night while people sleep, and you will enter Paradise in peace." (Tirmidhi)',
    duaArabic:
        'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    duaTransliteration:
        'Allahumma Antas-Salam wa minkas-salam tabarakta ya Dhal-Jalali wal-Ikram',
    duaTranslation:
        'O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of Majesty and Honor.',
  ),
  CollectibleName(
    id: 7,
    arabic: 'الْمُؤْمِنُ',
    transliteration: 'Al-Mumin',
    english: 'The Guardian of Faith',
    meaning:
        'The One who grants safety and confirms the faith of His servants.',
    lesson: 'Al-Mumin sees your sincerity even when others doubt you.',
    hadith:
        'The Prophet ﷺ said: "The believer is a mirror to his brother." (Abu Dawud). Al-Mumin protects faith in every heart that seeks Him.',
    duaArabic: 'اللَّهُمَّ ثَبِّتْنَا عَلَى الْإِيمَانِ',
    duaTransliteration: 'Allahumma thabbitna \'alal-iman',
    duaTranslation: 'O Allah, make us firm upon faith.',
  ),
  CollectibleName(
    id: 8,
    arabic: 'الْعَزِيزُ',
    transliteration: 'Al-Azeez',
    english: 'The Almighty',
    meaning: 'The One of perfect might and honor who is never overcome.',
    lesson: 'Lean on Al-Azeez. You are not weak when you call upon Him.',
    hadith:
        'The Prophet ﷺ said: "Might belongs to Allah, His Messenger, and the believers." (Quran 63:8)',
    duaArabic: 'يَا عَزِيزُ أَعِزَّنِي بِطَاعَتِكَ',
    duaTransliteration: 'Ya Azeez a\'izzani bi ta\'atik',
    duaTranslation: 'O Almighty, honor me through obedience to You.',
  ),
  CollectibleName(
    id: 9,
    arabic: 'الْجَبَّارُ',
    transliteration: 'Al-Jabbar',
    english: 'The Compeller',
    meaning: 'The One who mends what is broken and compels all to His will.',
    lesson: 'Al-Jabbar heals broken hearts. Bring Him your shattered pieces.',
    hadith:
        'The Prophet ﷺ used to say in his prostration: "My face has prostrated to the One who created it and fashioned it, and split open its hearing and sight, by His might and power." (Tirmidhi)',
    duaArabic: 'يَا جَبَّارُ اجْبُرْ كَسْرِي',
    duaTransliteration: 'Ya Jabbar ujbur kasri',
    duaTranslation: 'O Compeller, mend my brokenness.',
  ),
  CollectibleName(
    id: 10,
    arabic: 'الْخَالِقُ',
    transliteration: 'Al-Khaliq',
    english: 'The Creator',
    meaning: 'The One who brings everything into existence from nothing.',
    lesson:
        'You are not an accident. Al-Khaliq designed every detail of you with purpose.',
    hadith:
        'The Prophet ﷺ said: "Allah created Adam in His image." (Bukhari & Muslim). You carry the honor of divine creation.',
    duaArabic: 'رَبَّنَا مَا خَلَقْتَ هَذَا بَاطِلًا سُبْحَانَكَ',
    duaTransliteration: 'Rabbana ma khalaqta hadha batilan subhanak',
    duaTranslation:
        'Our Lord, You have not created this in vain. Glory be to You.',
  ),
  CollectibleName(
    id: 11,
    arabic: 'الْغَفَّارُ',
    transliteration: 'Al-Ghaffar',
    english: 'The Ever-Forgiving',
    meaning:
        'The One who forgives sins repeatedly and covers faults completely.',
    lesson: "Al-Ghaffar's door never closes. Return as many times as you fall.",
    hadith:
        'The Prophet ﷺ said: "By Allah, I seek forgiveness from Allah and repent to Him more than seventy times a day." (Bukhari)',
    duaArabic:
        'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الْغَفُورُ',
    duaTransliteration:
        'Rabbighfir li wa tub \'alayya innaka Antat-Tawwabul-Ghafur',
    duaTranslation:
        'My Lord, forgive me and accept my repentance. You are the Acceptor of Repentance, the Forgiving.',
  ),
  CollectibleName(
    id: 12,
    arabic: 'الْوَهَّابُ',
    transliteration: 'Al-Wahhab',
    english: 'The Bestower',
    meaning:
        'The One who gives endlessly without expecting anything in return.',
    lesson: 'Every gift you have — talent, love, breath — is from Al-Wahhab.',
    hadith:
        'The Prophet ﷺ said: "The hand of Allah is full, and spending does not diminish it. He gives abundantly day and night." (Bukhari)',
    duaArabic:
        'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً',
    duaTransliteration:
        'Rabbana la tuzigh qulubana ba\'da idh hadaytana wa hab lana min ladunka rahmah',
    duaTranslation:
        'Our Lord, do not let our hearts deviate after You have guided us, and grant us mercy from Yourself.',
  ),
  CollectibleName(
    id: 13,
    arabic: 'الرَّزَّاقُ',
    transliteration: 'Ar-Razzaq',
    english: 'The Provider',
    meaning: 'The One who provides all sustenance, seen and unseen.',
    lesson:
        'Worry less. Ar-Razzaq has written your provision before you were born.',
    hadith:
        'The Prophet ﷺ said: "If you relied on Allah as He should be relied upon, He would provide for you as He provides for the birds — they go out hungry in the morning and return full in the evening." (Tirmidhi)',
    duaArabic:
        'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    duaTransliteration:
        'Allahumma ikfini bi halalika \'an haramik wa aghnini bi fadlika amman siwak',
    duaTranslation:
        'O Allah, suffice me with what is lawful against what is unlawful, and enrich me by Your favor over all others.',
  ),
  CollectibleName(
    id: 14,
    arabic: 'الْعَلِيمُ',
    transliteration: 'Al-Aleem',
    english: 'The All-Knowing',
    meaning:
        'The One whose knowledge encompasses everything, hidden and apparent.',
    lesson:
        'You never need to explain your pain to Al-Aleem. He already knows.',
    hadith:
        'The Prophet ﷺ said: "Allah knew what His servants would do, and He wrote it all fifty thousand years before creating the heavens and the earth." (Muslim)',
    duaArabic:
        'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ',
    duaTransliteration:
        'Allahumma \'Alimal-ghaybi wash-shahadah, Fatiras-samawati wal-ard',
    duaTranslation:
        'O Allah, Knower of the unseen and the seen, Originator of the heavens and the earth.',
  ),
  CollectibleName(
    id: 15,
    arabic: 'الْحَيُّ',
    transliteration: 'Al-Hayy',
    english: 'The Ever-Living',
    meaning: 'The One who has always lived and will never die.',
    lesson: 'Everything you lean on will pass away — except Al-Hayy.',
    hadith:
        'The Prophet ﷺ said: "Call upon Allah using \'Ya Hayyu Ya Qayyum\' — by Your mercy I seek relief." (Tirmidhi)',
    duaArabic: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    duaTransliteration: 'Ya Hayyu Ya Qayyum bi rahmatika astaghith',
    duaTranslation:
        'O Ever-Living, O Self-Sustaining, by Your mercy I seek relief.',
  ),
  // ── Remaining Names (tier 2/3 content to be added) ──
  CollectibleName(
    id: 16,
    arabic: 'الْقَيُّومُ',
    transliteration: 'Al-Qayyum',
    english: 'The Self-Sustaining',
    meaning: 'The One who sustains all of creation by His power.',
    lesson:
        'You do not sustain yourself. Al-Qayyum holds you together even when you feel like falling apart.',
    hadith:
        'The Prophet ﷺ said to Fatima: "Do not leave off a morning or evening without saying: Ya Hayyu Ya Qayyum, bi rahmatika astagheeth." (Al-Hakim)',
    duaArabic:
        'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
    duaTransliteration:
        'Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha\'ni kullahu wa la takilni ila nafsi tarfata \'ayn',
    duaTranslation:
        'O Ever-Living, O Self-Sustaining, in Your mercy I seek help. Rectify all my affairs and do not leave me to myself even for the blink of an eye.',
  ),
  CollectibleName(
    id: 17,
    arabic: 'النُّورُ',
    transliteration: 'An-Nur',
    english: 'The Light',
    meaning: 'The One who illuminates the heavens, the earth, and every heart.',
    lesson:
        'When darkness surrounds you, An-Nur is the light that no shadow can extinguish.',
    hadith:
        'The Prophet ﷺ used to pray on the way to Fajr: "O Allah, place light in my heart, light in my hearing, light in my sight — and make me a light." (Muslim)',
    duaArabic:
        'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي لِسَانِي نُورًا وَاجْعَلْنِي نُورًا',
    duaTransliteration:
        'Allahumma-j\'al fi qalbi nuran wa fi lisani nuran waj\'alni nuran',
    duaTranslation:
        'O Allah, place light in my heart, light on my tongue, and make me light.',
  ),
  CollectibleName(
    id: 18,
    arabic: 'الْمُهَيْمِنُ',
    transliteration: 'Al-Muhaymin',
    english: 'The Overseer',
    meaning: 'The One who watches over and protects all things.',
    lesson:
        'Nothing escapes His watchful care. Al-Muhaymin guards what you cannot.',
    hadith:
        'Allah says: "I am with My servant when he remembers Me." Al-Muhaymin watches over you with an eye that never sleeps. (Bukhari)',
    duaArabic: 'يَا مُهَيْمِنُ احْرُسْنِي بِعَيْنِكَ الَّتِي لَا تَنَامُ',
    duaTransliteration: 'Ya Muhaymin, ihrusni bi \'aynikal-lati la tanam',
    duaTranslation: 'O Overseer, guard me with Your eye that never sleeps.',
  ),
  CollectibleName(
    id: 19,
    arabic: 'الْمُتَكَبِّرُ',
    transliteration: 'Al-Mutakabbir',
    english: 'The Supreme',
    meaning: 'The One whose greatness is beyond all comparison.',
    lesson:
        'True greatness belongs only to Al-Mutakabbir. In recognizing this, you find humility.',
    hadith:
        'The Prophet ﷺ said: "Greatness is My cloak and pride is My garment. Whoever competes with Me in either, I will throw into the Fire." (Muslim)',
    duaArabic:
        'يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي',
    duaTransliteration:
        'Ya Qahhar, iqhar kulla jabbarin \'anid, wa Ya Jabbar, ujbur kasri',
    duaTranslation:
        'O Subduer, subdue every stubborn tyrant. O Compeller-Healer, mend my brokenness.',
  ),
  CollectibleName(
    id: 20,
    arabic: 'الْبَارِئُ',
    transliteration: 'Al-Bari',
    english: 'The Evolver',
    meaning: 'The One who shapes creation according to His perfect plan.',
    lesson: 'Al-Bari is still shaping you. Your story is not finished yet.',
    hadith:
        'The Prophet ﷺ said: "You brought me out of nothingness into being." Al-Baari perfects what He produces — He repairs what we have broken within ourselves. (Yaqeen, The Name I Need)',
    duaArabic:
        'يَا بَارِئُ أَصْلِحْ مَا أَفْسَدْتُهُ فِي نَفْسِي وَاجْعَلْنِي كَامِلًا بِدِقَّةِ صُنْعِكَ',
    duaTransliteration:
        'Ya Bari\', aslih ma afsadtuhu fi nafsi waj\'alni kamilan bi-diqqati sun\'ik',
    duaTranslation:
        'O Producer, repair what I have broken within myself. Make me whole again with the same precision by which You fashion all of Your creation.',
  ),
  CollectibleName(
    id: 21,
    arabic: 'الْمُصَوِّرُ',
    transliteration: 'Al-Musawwir',
    english: 'The Fashioner',
    meaning: 'The One who gives each creation its unique form and beauty.',
    lesson:
        'Your face, your fingerprint, your soul — Al-Musawwir made you one of a kind.',
    hadith:
        'Allah says: "He shaped you in the wombs however He willed." Al-Musawwir gave each creation its unique form — your face, your fingerprint, your soul are His deliberate design. (Quran 3:6)',
    duaArabic: 'يَا مُصَوِّرُ جَمِّلْ أَخْلَاقِي كَمَا جَمَّلْتَ خَلْقِي',
    duaTransliteration: 'Ya Musawwir, jammil akhlaaqi kama jammalta khalqi',
    duaTranslation:
        'O Fashioner, beautify my character as You have beautified my features. Let what You see within me be more pleasing than what others see of me.',
  ),
  CollectibleName(
    id: 22,
    arabic: 'الْقَهَّارُ',
    transliteration: 'Al-Qahhar',
    english: 'The Subduer',
    meaning: 'The One who overcomes all and to whom everything submits.',
    lesson: 'The tyrant you fear is nothing before Al-Qahhar.',
    hadith:
        'Yusuf (AS) said to his fellow prisoners: "Are many lords better, or is Allah the One, Al-Qahhar?" (Quran 12:39)',
    duaArabic:
        'يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي',
    duaTransliteration:
        'Ya Qahhar, iqhar kulla jabbarin \'anid, wa Ya Jabbar, ujbur kasri',
    duaTranslation:
        'O Subduer, subdue every stubborn tyrant. O Compeller-Healer, mend my brokenness.',
  ),
  CollectibleName(
    id: 23,
    arabic: 'الْفَتَّاحُ',
    transliteration: 'Al-Fattah',
    english: 'The Opener',
    meaning: 'The One who opens the doors of mercy, provision, and guidance.',
    lesson:
        'When every door seems closed, Al-Fattah opens ways you never imagined.',
    hadith:
        'Allah says: "Whatever Allah opens for people from His mercy, no one can hold it back." (Quran 35:2)',
    duaArabic: 'يَا فَتَّاحُ افْتَحْ لَنَا خَيْرَ الْفَتْحِ',
    duaTransliteration: 'Ya Fattahu iftah lana khayral fath',
    duaTranslation: 'O Opener, open for us the best of openings.',
  ),
  CollectibleName(
    id: 24,
    arabic: 'الْقَابِضُ',
    transliteration: 'Al-Qabid',
    english: 'The Withholder',
    meaning: 'The One who contracts, withholds, and tests through scarcity.',
    lesson:
        'Sometimes Al-Qabid withholds to protect you from what would harm you.',
    hadith:
        'The Prophet ﷺ said: "I do not fear poverty for you — I fear that the dunya will be opened up for you." (Bukhari & Muslim)',
    duaArabic: 'يَا قَابِضُ يَا بَاسِطُ ابْسُطْ عَلَيْنَا مِنْ رَحْمَتِكَ',
    duaTransliteration: 'Ya Qabidu ya Basitu ibsut \'alayna min rahmatik',
    duaTranslation:
        'O Constrictor, O Expander, spread over us from Your mercy.',
  ),
  CollectibleName(
    id: 25,
    arabic: 'الْبَاسِطُ',
    transliteration: 'Al-Basit',
    english: 'The Expander',
    meaning: 'The One who expands, extends, and gives abundantly.',
    lesson:
        'After every constriction comes expansion. Trust the rhythm of Al-Basit.',
    hadith:
        'The Prophet ﷺ said: "I do not fear poverty for you — I fear that the dunya will be opened up for you." (Bukhari & Muslim)',
    duaArabic: 'يَا قَابِضُ يَا بَاسِطُ ابْسُطْ عَلَيْنَا مِنْ رَحْمَتِكَ',
    duaTransliteration: 'Ya Qabidu ya Basitu ibsut \'alayna min rahmatik',
    duaTranslation:
        'O Constrictor, O Expander, spread over us from Your mercy.',
  ),
  CollectibleName(
    id: 26,
    arabic: 'الْحَكِيمُ',
    transliteration: 'Al-Hakeem',
    english: 'The All-Wise',
    meaning: 'The One who acts with perfect wisdom in everything He decrees.',
    lesson:
        "You may not understand the plan, but Al-Hakeem's wisdom never errs.",
    hadith:
        'Yusuf (AS) said: "Indeed my Lord is subtle in what He wills. Indeed He is the All-Knowing, the All-Wise." (Quran 12:100)',
    duaArabic: 'اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا',
    duaTransliteration: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
    duaTranslation:
        'O Allah, O Gentle One, be gentle with me in all my affairs.',
  ),
  CollectibleName(
    id: 27,
    arabic: 'الْوَدُودُ',
    transliteration: 'Al-Wadud',
    english: 'The Most Loving',
    meaning:
        'The One whose love for His servants is unconditional and constant.',
    lesson:
        'Al-Wadud loves you not for your perfection but for your turning toward Him.',
    hadith:
        'The Prophet ﷺ said: "When Allah loves a servant, He says to Jibreel: I love so-and-so, so love him. Then acceptance is placed for him on earth." (Bukhari & Muslim)',
    duaArabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ حُبَّكَ وَحُبَّ مَنْ يُحِبُّكَ',
    duaTransliteration:
        'Allahumma inni as\'aluka hubbaka wa hubba man yuhibbuk',
    duaTranslation:
        'O Allah, I ask You for Your love and the love of those who love You.',
  ),
  CollectibleName(
    id: 28,
    arabic: 'الشَّكُورُ',
    transliteration: 'Ash-Shakur',
    english: 'The Most Appreciative',
    meaning: 'The One who rewards abundantly for the smallest good deed.',
    lesson:
        'Even your private acts of goodness are seen and multiplied by Ash-Shakur.',
    hadith:
        'The Prophet ﷺ said: "A man removed a thorny branch from a path. Allah thanked him and forgave his sins." (Bukhari)',
    duaArabic: 'يَا شَكُورُ اشْكُرْ لِي سَعْيِي وَلَا تَخْذُلْنِي',
    duaTransliteration: 'Ya Shakuru ushkur li sa\'yi wa la takhdhulni',
    duaTranslation:
        'O Most Appreciative, appreciate my striving and do not abandon me.',
  ),
  CollectibleName(
    id: 29,
    arabic: 'الْحَلِيمُ',
    transliteration: 'Al-Haleem',
    english: 'The Forbearing',
    meaning:
        'The One who withholds punishment despite having full power to act.',
    lesson:
        "That you are still here, still trying — this is Al-Haleem's patience with you.",
    hadith:
        'The Prophet ﷺ said: "No one shows more patience upon hearing abuse than Allah — they attribute a son to Him, yet He still gives them health and provision." (Bukhari)',
    duaArabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ',
    duaTransliteration:
        'Allahumma inni as\'alukas-sabra wa a\'udhu bika minal-jaza\'',
    duaTranslation:
        'O Allah, I ask You for patience and I seek refuge in You from anxiety and distress.',
  ),
  CollectibleName(
    id: 30,
    arabic: 'الْكَرِيمُ',
    transliteration: 'Al-Kareem',
    english: 'The Most Generous',
    meaning: 'The One whose generosity is without limit or expectation.',
    lesson: 'Ask Al-Kareem without shame. His generosity is never depleted.',
    hadith:
        'Allah introduced Himself in the first revelation as Al-Karim: "Recite, and your Lord is Al-Akram — the Most Generous." (Quran 96:3)',
    duaArabic: 'يَا كَرِيمُ بِرَحْمَتِكَ أَغِثْنِي',
    duaTransliteration: 'Ya Karimu birahmatika aghithni',
    duaTranslation: 'O Most Generous, by Your mercy, rescue me.',
  ),
  CollectibleName(
    id: 31,
    arabic: 'التَّوَّابُ',
    transliteration: 'At-Tawwab',
    english: 'The Acceptor of Repentance',
    meaning: 'The One who turns toward His servants when they turn toward Him.',
    lesson:
        'You took one step back to Him — At-Tawwab is already running toward you.',
    hadith:
        'In a hadith qudsi, Allah says: "As long as you call upon Me and never lose hope in Me, I will forgive you for all you have done — and I do not care." (Tirmidhi)',
    duaArabic:
        'اللَّهُمَّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    duaTransliteration:
        'Allahumma ighfir li wa tub alayyah innaka anta at-tawwabur-rahim',
    duaTranslation:
        'O Allah, forgive me and accept my repentance. Indeed You are At-Tawwab, the Most Merciful.',
  ),
  CollectibleName(
    id: 32,
    arabic: 'الصَّبُورُ',
    transliteration: 'As-Sabur',
    english: 'The Patient',
    meaning: 'The One who is patient with the disobedience of His creation.',
    lesson: 'As-Sabur does not rush you. He waits for you with open arms.',
    hadith:
        'The Prophet ﷺ said: "No one has ever been given a gift better and more vast than patience." (Bukhari & Muslim)',
    duaArabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ',
    duaTransliteration:
        'Allahumma inni as\'alukas-sabra wa a\'udhu bika minal-jaza\'',
    duaTranslation:
        'O Allah, I ask You for patience and I seek refuge in You from anxiety and distress.',
  ),
  CollectibleName(
    id: 33,
    arabic: 'الْهَادِي',
    transliteration: 'Al-Hadi',
    english: 'The Guide',
    meaning:
        'The One who guides hearts to truth and feet to the straight path.',
    lesson:
        'You are not lost. Al-Hadi placed the longing for guidance in your heart.',
    hadith:
        'In a hadith qudsi: "O My servants, all of you are astray except those I have guided. So seek guidance of Me and I will guide you." (Muslim)',
    duaArabic: 'اللَّهُمَّ اهْدِنَا وَاهْدِ بِنَا',
    duaTransliteration: 'Allahumma ihdina wa ihdi bina',
    duaTranslation:
        'O Allah, guide us and make us a means of guidance for others.',
  ),
  CollectibleName(
    id: 34,
    arabic: 'الصَّمَدُ',
    transliteration: 'As-Samad',
    english: 'The Eternal Refuge',
    meaning:
        'The One to whom all creation turns in need, yet He needs nothing.',
    lesson:
        'When you have nowhere to turn, As-Samad is the refuge that never turns you away.',
    hadith:
        'Musa (AS) said: "My Lord, I am in need of whatever good You send down to me." He had nothing, and in that emptiness before As-Samad, everything came. (Quran 28:24)',
    duaArabic: 'اللَّهُمَّ يَا صَمَدُ اجْعَلْنِي غَنِيًّا بِكَ عَنْ سِوَاكَ',
    duaTransliteration:
        'Allahumma ya Samad, ij\'alni ghaniyyan bika \'an siwak',
    duaTranslation:
        'O Allah, O Eternal Refuge, make me needless of all others through You.',
  ),
  CollectibleName(
    id: 35,
    arabic: 'الْوَكِيلُ',
    transliteration: 'Al-Wakeel',
    english: 'The Trustee',
    meaning: 'The One who is sufficient as a guardian and disposer of affairs.',
    lesson: 'Hand it over to Al-Wakeel. He manages what you cannot.',
    hadith:
        'Ibrahim (AS), when thrown into the fire, said: "Hasbunallah wa ni\'mal Wakeel." Allah commanded the fire: "Be cool and safe for Ibrahim." (Quran 3:173)',
    duaArabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    duaTransliteration: 'Hasbunallahu wa ni\'mal-Wakil',
    duaTranslation:
        'Allah is enough for us, and He is the best disposer of affairs.',
  ),
  CollectibleName(
    id: 36,
    arabic: 'اللَّطِيفُ',
    transliteration: 'Al-Lateef',
    english: 'The Subtle',
    meaning:
        'The One who is aware of the finest details and acts with gentleness.',
    lesson:
        'Al-Lateef works in ways you cannot see, arranging what you cannot plan.',
    hadith:
        'Yusuf (AS) said: "Indeed my Lord is subtle (Latif) in what He wills. Indeed He is the All-Knowing, the All-Wise." (Quran 12:100)',
    duaArabic: 'يَا لَطِيفُ الْطُفْ بِي فِيمَا جَرَتْ بِهِ الْمَقَادِيرُ',
    duaTransliteration: 'Ya Lateefu ultuf bi fima jarat bihi al-maqadir',
    duaTranslation:
        'O Subtle One, be gentle with me in all that destiny has decreed.',
  ),
  CollectibleName(
    id: 37,
    arabic: 'الْمُجِيبُ',
    transliteration: 'Al-Mujeeb',
    english: 'The Responsive',
    meaning: 'The One who answers the call of those who call upon Him.',
    lesson:
        'Your dua was heard the moment your lips moved. Al-Mujeeb is already responding.',
    hadith:
        'The Prophet ﷺ said: "No Muslim calls with the dua of Yunus except that Allah responds." (Tirmidhi)',
    duaArabic:
        'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    duaTransliteration: 'La ilaha illa anta subhanaka inni kuntu minaz-zalimin',
    duaTranslation:
        'There is no god but You, glory be to You; indeed I have been of the wrongdoers.',
  ),
  CollectibleName(
    id: 38,
    arabic: 'الشَّافِي',
    transliteration: 'Ash-Shafi',
    english: 'The Healer',
    meaning: 'The One who cures every illness of body and soul.',
    lesson:
        'No wound is too deep for Ash-Shafi. He heals what medicine cannot reach.',
    hadith:
        'The Prophet ﷺ prayed: "Take away the harm, Lord of people. Heal, for You are the Healer, and there is no healing except Your healing." (Bukhari & Muslim)',
    duaArabic:
        'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ اشْفِ أَنتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
    duaTransliteration:
        'Allahumma Rabban-nasi, adhhib il-ba\'s, ishfi anta\'sh-Shafi, la shifa\'a illa shifa\'uk, shifa\'an la yughadiru saqama',
    duaTranslation:
        'O Allah, Lord of people, remove the illness, heal — You are the Healer, there is no healing except Your healing, a healing that leaves no illness behind.',
  ),
  CollectibleName(
    id: 39,
    arabic: 'الْحَفِيظُ',
    transliteration: 'Al-Hafeez',
    english: 'The Preserver',
    meaning: 'The One who guards and protects all things in His care.',
    lesson:
        'Everything you love is in the hands of Al-Hafeez — even when you cannot hold it.',
    hadith:
        'The Prophet ﷺ said: "Guard Allah and He will guard you. Guard Allah and you will find Him in front of you." (Tirmidhi)',
    duaArabic: 'يَا حَفِيظُ احْفَظْنِي وَاحْفَظْ لِي مَنْ أُحِبُّ',
    duaTransliteration: 'Ya Hafeedh, ihfadhni wa-ihfadh li man uhibb',
    duaTranslation: 'O Preserver, preserve me and preserve those I love.',
  ),
  CollectibleName(
    id: 40,
    arabic: 'الرَّقِيبُ',
    transliteration: 'Ar-Raqeeb',
    english: 'The Watchful',
    meaning: 'The One who sees every action, thought, and intention.',
    lesson: 'Ar-Raqeeb sees the good you do in secret. Nothing is wasted.',
    hadith:
        'Al-Basir saw Yunus (AS) in three layers of darkness — the night, the sea, and the belly of the whale — and Ar-Raqib recorded every moment of his patience. (Ibn Mas\'ud)',
    duaArabic: 'يَا رَقِيبُ احْفَظْنِي فِي سِرِّي وَعَلَانِيَتِي',
    duaTransliteration: 'Ya Raqib, ihfadhni fi sirri wa \'alaniyyati',
    duaTranslation: 'O Watchful One, guard me in my private and public life.',
  ),
  CollectibleName(
    id: 41,
    arabic: 'الْخَافِضُ',
    transliteration: 'Al-Khafid',
    english: 'The Abaser',
    meaning: 'The One who lowers whoever He wills by His wisdom.',
    lesson:
        'Al-Khafid humbles the arrogant and reminds us that all status belongs to Him.',
    hadith:
        'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah raises him." Al-Khafid lowers whoever He wills by His wisdom — reminding us that all status belongs to Him alone. (Muslim)',
    duaArabic: 'يَا خَافِضُ اخْفِضْ كِبْرِيَائِي وَارْفَعْ قَدْرِي عِنْدَكَ',
    duaTransliteration: 'Ya Khafid, ikhfid kibriya\'i warfa\' qadri \'indak',
    duaTranslation: 'O Abaser, lower my arrogance and raise my rank with You.',
  ),
  CollectibleName(
    id: 42,
    arabic: 'الرَّافِعُ',
    transliteration: 'Ar-Rafi',
    english: 'The Exalter',
    meaning: 'The One who raises His servants in rank and honor.',
    lesson: 'Ar-Rafi elevates those who humble themselves before Him.',
    hadith:
        'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah raises him high." Ar-Rafi elevates those who humble themselves sincerely before Him. (Muslim)',
    duaArabic:
        'يَا رَافِعُ ارْفَعْ دَرَجَتِي عِنْدَكَ وَاجْعَلْ لِي مَكَانَةً فِي الدُّنْيَا وَالْآخِرَةِ',
    duaTransliteration:
        'Ya Rafi\', irfa\' darajati \'indak waj\'al li makanatan fid-dunya wal-akhirah',
    duaTranslation:
        'O Exalter, raise my rank with You and grant me a standing in this life and the next.',
  ),
  CollectibleName(
    id: 43,
    arabic: 'الْمُعِزُّ',
    transliteration: 'Al-Muizz',
    english: 'The Bestower of Honor',
    meaning: 'The One who gives honor and dignity to whom He wills.',
    lesson: 'True honor comes from Al-Muizz, not from people or positions.',
    hadith:
        'Umar (RA) said: "We were a debased people. Allah gave us honor through Islam. If we seek honor through anything else, we will be debased again." (Al-Hakim)',
    duaArabic:
        'اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ',
    duaTransliteration:
        'Allahumma a\'izzani bita\'atika wa la tudhillani bima\'siyatik',
    duaTranslation:
        'O Allah, honor me through obedience to You, and do not humiliate me through disobedience to You.',
  ),
  CollectibleName(
    id: 44,
    arabic: 'الْمُذِلُّ',
    transliteration: 'Al-Muzill',
    english: 'The Humiliator',
    meaning: 'The One who disgraces those who defy His command.',
    lesson: 'Al-Muzill reminds us that no empire lasts without His permission.',
    hadith:
        'Umar (RA) said: "We were a debased people. Allah gave us honor through Islam. If we seek honor through anything else, we will be debased again." (Al-Hakim)',
    duaArabic:
        'اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ',
    duaTransliteration:
        'Allahumma a\'izzani bita\'atika wa la tudhillani bima\'siyatik',
    duaTranslation:
        'O Allah, honor me through obedience to You, and do not humiliate me through disobedience to You.',
  ),
  CollectibleName(
    id: 45,
    arabic: 'السَّمِيعُ',
    transliteration: 'As-Sami',
    english: 'The All-Hearing',
    meaning: 'The One who hears every sound, whisper, and silent prayer.',
    lesson: 'Even the prayer you could not put into words — As-Sami heard it.',
    hadith:
        'Zakariyya (AS) made a silent call in the corner of the masjid. Before he could finish, Allah said: "I heard you — and here is the child, already named Yahya." (Quran 19:3-7)',
    duaArabic: 'إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ',
    duaTransliteration: 'Inna Rabbi qaribun mujib',
    duaTranslation: 'Indeed my Lord is close and responsive.',
  ),
  CollectibleName(
    id: 46,
    arabic: 'الْبَصِيرُ',
    transliteration: 'Al-Baseer',
    english: 'The All-Seeing',
    meaning: 'The One who sees all things, open and hidden.',
    lesson: 'Al-Baseer witnesses your struggle even when no one else does.',
    hadith:
        'Al-Basir saw Yunus (AS) in three layers of darkness — the night, the sea, and the belly of the whale — and heard his call. (Ibn Mas\'ud)',
    duaArabic:
        'يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ',
    duaTransliteration:
        'Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya\'lamuhu siwak',
    duaTranslation:
        'O All-Seeing, You see what no one else sees. Bear witness for me in what only You know.',
  ),
  CollectibleName(
    id: 47,
    arabic: 'الْحَكَمُ',
    transliteration: 'Al-Hakam',
    english: 'The Judge',
    meaning: 'The One whose judgment is absolute and perfectly just.',
    lesson:
        'When the world is unjust, remember that Al-Hakam will settle every account.',
    hadith:
        'Allah says: "O My servants, I have forbidden oppression for Myself and made it forbidden among you, so do not oppress one another." (Muslim)',
    duaArabic:
        'اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ',
    duaTransliteration:
        'Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin',
    duaTranslation:
        'O Allah, judge between us and our people in truth — You are the best of judges.',
  ),
  CollectibleName(
    id: 48,
    arabic: 'الْعَدْلُ',
    transliteration: 'Al-Adl',
    english: 'The Just',
    meaning: 'The One who is perfectly balanced in all He does.',
    lesson: 'Al-Adl will never wrong you — not by the weight of an atom.',
    hadith:
        'Ibn Taymiyyah said: "Allah will sustain a just nation even if they are not Muslim, and He may destroy an unjust nation even if they are Muslim."',
    duaArabic:
        'اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ',
    duaTransliteration:
        'Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin',
    duaTranslation:
        'O Allah, judge between us and our people in truth — You are the best of judges.',
  ),
  CollectibleName(
    id: 49,
    arabic: 'الْخَبِيرُ',
    transliteration: 'Al-Khabeer',
    english: 'The All-Aware',
    meaning: 'The One who is aware of the inner reality of all things.',
    lesson:
        'You do not need to pretend with Al-Khabeer. He knows your truth already.',
    hadith:
        'Al-Ghazali said: "Al-Latif knows the hidden details only He knows, and delivers hidden benefits through ways only He knows."',
    duaArabic: 'اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا',
    duaTransliteration: 'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
    duaTranslation:
        'O Allah, O Gentle One, be gentle with me in all my affairs.',
  ),
  CollectibleName(
    id: 50,
    arabic: 'الْعَظِيمُ',
    transliteration: 'Al-Azeem',
    english: 'The Magnificent',
    meaning: 'The One whose greatness is beyond human comprehension.',
    lesson:
        'Your problems feel massive — until you remember the magnificence of Al-Azeem.',
    hadith:
        'When Surah Al-A\'la was revealed, the Prophet ﷺ said: "Make this in your sujud." In our deepest prostration we declare His highest. (Abu Dawud)',
    duaArabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
    duaTransliteration: 'Subhana Rabbiyal \'Azeem',
    duaTranslation: 'Glory be to my Lord, the Most Magnificent.',
  ),
  CollectibleName(
    id: 51,
    arabic: 'الْغَفُورُ',
    transliteration: 'Al-Ghafur',
    english: 'The Forgiving',
    meaning: 'The One who forgives and conceals faults with grace.',
    lesson:
        'Al-Ghafur does not just forgive — He erases the sin as if it never happened.',
    hadith:
        'In a hadith qudsi: "O My servant, if you brought Me an earth full of sins without associating a partner with Me, I would meet you with an earth full of forgiveness." (Tirmidhi)',
    duaArabic:
        'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    duaTransliteration:
        'Rabbighfir li wa tub \'alayya innaka anta\'t-Tawwabu\'r-Rahim',
    duaTranslation:
        'My Lord, forgive me and accept my repentance. Indeed, You are At-Tawwab, Ar-Rahim.',
  ),
  CollectibleName(
    id: 52,
    arabic: 'الْعَلِيُّ',
    transliteration: 'Al-Ali',
    english: 'The Most High',
    meaning: 'The One who is above all creation in rank and majesty.',
    lesson:
        'When you prostrate to Al-Ali, you reach the highest station a human can attain.',
    hadith:
        'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah exalts him. Whoever exalts himself, Allah lowers him." (Muslim)',
    duaArabic:
        'يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ',
    duaTransliteration:
        'Ya \'Aliyyu ya Muta\'ali, irfa\' qalbi fawqa\'d-daghina wa\'s-sighar',
    duaTranslation:
        'O The Exalted, O The Supremely Exalted, raise my heart above resentment and smallness.',
  ),
  CollectibleName(
    id: 53,
    arabic: 'الْكَبِيرُ',
    transliteration: 'Al-Kabeer',
    english: 'The Greatest',
    meaning: 'The One who is greater than everything in existence.',
    lesson: 'Whatever towers over you in fear — Al-Kabeer is greater than it.',
    hadith:
        'Imam al-Ghazali said: "And every great thing compared to Him is small." In salah you bow to Al-Azim and prostrate to Al-A\'la — the moment you are physically at your lowest you declare His highest. (Al-Ghazali)',
    duaArabic:
        'يَا كَبِيرُ أَشْعِرْنِي بِصِغَرِي أَمَامَكَ حَتَّى لَا يَمْلَأَ قَلْبِي كِبْرٌ',
    duaTransliteration:
        'Ya Kabeer, ash\'irni bisighari amamak hatta la yamla\' qalbi kibr',
    duaTranslation:
        'O Greatest, let me feel my smallness before You so that arrogance never fills my heart.',
  ),
  CollectibleName(
    id: 54,
    arabic: 'الْمُقِيتُ',
    transliteration: 'Al-Muqeet',
    english: 'The Nourisher',
    meaning: 'The One who nourishes and sustains every living thing.',
    lesson:
        'Al-Muqeet feeds not only your body but your soul and your purpose.',
    hadith:
        'The Prophet ﷺ said: "Allah provides for every creature — He is Al-Muqeet, the Nourisher of all things." Not just bodies but souls and purposes are sustained by Him. (Ibn Kathir, Tafsir of Quran 4:85)',
    duaArabic: 'يَا مُقِيتُ أَقِتْنِي بِذِكْرِكَ وَأَغْذِ رُوحِي بِقُرْبِكَ',
    duaTransliteration: 'Ya Muqeet, aqitni bidhikrika wa-aghdhi ruhi biqurbik',
    duaTranslation:
        'O Nourisher, sustain me with Your remembrance and nourish my soul with Your nearness.',
  ),
  CollectibleName(
    id: 55,
    arabic: 'الْحَسِيبُ',
    transliteration: 'Al-Haseeb',
    english: 'The Reckoner',
    meaning: 'The One who takes account of all deeds with precision.',
    lesson: 'Al-Haseeb counts every kindness. Nothing good is ever lost.',
    hadith:
        'Allah says: "O My servants, I have forbidden oppression for Myself." Al-Hasib accounts for every hidden tear and unacknowledged apology. (Muslim)',
    duaArabic:
        'اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ',
    duaTransliteration:
        'Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin',
    duaTranslation:
        'O Allah, judge between us and our people in truth — You are the best of judges.',
  ),
  CollectibleName(
    id: 56,
    arabic: 'الْجَلِيلُ',
    transliteration: 'Al-Jaleel',
    english: 'The Majestic',
    meaning: 'The One of overwhelming majesty and grandeur.',
    lesson: 'Stand in awe of Al-Jaleel, and the things you feared will shrink.',
    hadith:
        'The Prophet ﷺ said: "Fill your heart with reverence of Allah that draws you near, not fear that drives you away." Al-Jaleel is the Majestic whose awe refines the servant. (Yaqeen, The Name I Need Day 06)',
    duaArabic:
        'يَا جَلِيلُ امْلَأْ قَلْبِي إِجْلَالًا لَكَ يُقَرِّبُنِي مِنْكَ لَا خَوْفًا يُبْعِدُنِي عَنْكَ',
    duaTransliteration:
        'Ya Jaleel, imla\' qalbi ijlalan laka yuqarribuni mink la khawfan yub\'iduni \'ank',
    duaTranslation:
        'O Majestic, fill my heart with reverence that draws me near, not fear that drives me away. Let my awe of You refine me until I stand before You humbled, but never disgraced.',
  ),
  CollectibleName(
    id: 57,
    arabic: 'الْوَاسِعُ',
    transliteration: 'Al-Wasi',
    english: 'The All-Encompassing',
    meaning:
        'The One whose mercy, knowledge, and provision encompass everything.',
    lesson:
        'Your need is never too big for Al-Wasi. His capacity has no limit.',
    hadith:
        'Allah says: "To Allah belongs the East and the West — wherever you turn, there is the Face of Allah. Indeed Allah is All-Encompassing, All-Knowing." (Quran 2:115)',
    duaArabic:
        'يَا وَاسِعُ وَسِّعْ قَلْبِي لِلصَّبْرِ وَبَصِيرَتِي لِتَجَاوُزِ حُدُودِي',
    duaTransliteration:
        'Ya Wasi\', wassi\' qalbi lis-sabr wa-basiirati litajawuzi hududy',
    duaTranslation:
        'O All-Encompassing, expand my heart to hold more gratitude, my patience to endure with more grace, and my vision to see beyond my limits.',
  ),
  CollectibleName(
    id: 58,
    arabic: 'الْمَجِيدُ',
    transliteration: 'Al-Majeed',
    english: 'The Glorious',
    meaning: 'The One who is glorious and generous in all His actions.',
    lesson:
        'Al-Majeed combines greatness with generosity — He is both awe-inspiring and giving.',
    hadith:
        'The scholars say: in salah, you stand before Al-Kabir, bow to Al-Azim, fall before Al-A\'la, and rise with Al-Majid. (Al-Ghazali)',
    duaArabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
    duaTransliteration: 'Subhana Rabbiyal \'Azeem',
    duaTranslation: 'Glory be to my Lord, the Most Magnificent.',
  ),
  CollectibleName(
    id: 59,
    arabic: 'الْبَاعِثُ',
    transliteration: 'Al-Baith',
    english: 'The Resurrector',
    meaning: 'The One who raises the dead and brings all to account.',
    lesson:
        'Al-Baith can revive a dead heart just as He will raise the dead on the Last Day.',
    hadith:
        'Allah says: "Does man not consider that We created him from a sperm-drop? Then he is a clear adversary. He presents an argument and forgets his own creation." Al-Baith raises the dead as He first created life. (Quran 36:77-79)',
    duaArabic:
        'يَا بَاعِثُ أَحْيِ قَلْبِي كَمَا تُحْيِي الْأَرْضَ الْمَيْتَةَ بِالْمَطَرِ',
    duaTransliteration:
        'Ya Ba\'ith, ahyi qalbi kama tuhyil-ardal-mayyitata bil-matar',
    duaTranslation:
        'O Resurrector, revive my heart as You revive the dead earth with rain.',
  ),
  CollectibleName(
    id: 60,
    arabic: 'الشَّهِيدُ',
    transliteration: 'Ash-Shaheed',
    english: 'The Witness',
    meaning: 'The One who witnesses all things at all times.',
    lesson: 'Your silent sacrifice is not unseen. Ash-Shaheed was there.',
    hadith:
        'Allah called the martyr a "shahid" because the shahid bears witness to Allah\'s reward — He saw them in their pain and honored them for their sacrifice.',
    duaArabic:
        'يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ',
    duaTransliteration:
        'Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya\'lamuhu siwak',
    duaTranslation:
        'O All-Seeing, You see what no one else sees. Bear witness for me in what only You know.',
  ),
  CollectibleName(
    id: 61,
    arabic: 'الْحَقُّ',
    transliteration: 'Al-Haqq',
    english: 'The Truth',
    meaning: 'The One who is the ultimate reality and absolute truth.',
    lesson: 'In a world of illusions, Al-Haqq is the only certainty you need.',
    hadith:
        'The Prophet ﷺ used to say when waking: "O Allah, to You belongs all praise. You are the Truth (Al-Haqq), Your promise is truth, and the meeting with You is truth." (Bukhari 7385)',
    duaArabic: 'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ',
    duaTransliteration: 'Allahumma lakal-hamd, Antal-Haqq, wa wa\'dukal-haqq',
    duaTranslation:
        'O Allah, to You belongs all praise. You are Al-Haqq, Your promise is truth. Make Your truth the anchor of my heart.',
  ),
  CollectibleName(
    id: 62,
    arabic: 'الْقَوِيُّ',
    transliteration: 'Al-Qawiyy',
    english: 'The Strong',
    meaning: 'The One whose strength is unlimited and never weakens.',
    lesson:
        'When you feel powerless, Al-Qawiyy lends strength to those who rely on Him.',
    hadith:
        'The Prophet ﷺ said: "The strong one is not the one who overcomes others physically. The strong one is the one who controls himself in a fit of anger." (Bukhari & Muslim)',
    duaArabic:
        'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
    duaTransliteration:
        'La hawla wa la quwwata illa billahil \'Aliyyil \'Azeem',
    duaTranslation:
        'There is no power and no strength except through Allah, the Most High, the Most Magnificent.',
  ),
  CollectibleName(
    id: 63,
    arabic: 'الْمَتِينُ',
    transliteration: 'Al-Mateen',
    english: 'The Firm',
    meaning: 'The One whose power is unshakeable and inexhaustible.',
    lesson:
        'When everything around you is shaking, Al-Mateen is the unshakeable ground.',
    hadith:
        'The Prophet ﷺ said: "Shall I not teach you a treasure from beneath the throne? La hawla wa la quwwata illa billah." (Bukhari & Muslim)',
    duaArabic:
        'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
    duaTransliteration:
        'La hawla wa la quwwata illa billahil \'Aliyyil \'Azeem',
    duaTranslation:
        'There is no power and no strength except through Allah, the Most High, the Most Magnificent.',
  ),
  CollectibleName(
    id: 64,
    arabic: 'الْوَلِيُّ',
    transliteration: 'Al-Waliyy',
    english: 'The Protecting Friend',
    meaning: 'The One who is the helper and protector of the believers.',
    lesson:
        'You are never alone. Al-Waliyy is closer to you than your own loneliness.',
    hadith:
        'The Prophet ﷺ said: "Be in this world as if you are a stranger or a wayfarer." Your only consistent companion is Al-Wali. (Bukhari)',
    duaArabic:
        'اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ',
    duaTransliteration:
        'Allahumma anta\'s-sahibu fi\'s-safar wa\'l-khalifatu fi\'l-ahl',
    duaTranslation:
        'O Allah, You are my companion in travel and the guardian over my family.',
  ),
  CollectibleName(
    id: 65,
    arabic: 'الْحَمِيدُ',
    transliteration: 'Al-Hameed',
    english: 'The Praiseworthy',
    meaning: 'The One who is worthy of all praise in every situation.',
    lesson:
        'Even in hardship, Al-Hameed deserves praise — and praising Him transforms the hardship.',
    hadith:
        'In a Hadith Qudsi: "O child of Adam, devote yourself to My worship, and I will fill your heart with richness." The more you praise a blessing, the more fulfilling it becomes. (Muslim)',
    duaArabic:
        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ',
    duaTransliteration:
        'Al-hamdu lillahi Rabbil \'aalameen hamdan katheeran tayyiban mubarakan feeh',
    duaTranslation:
        'All praise is due to Allah, Lord of all the worlds — abundant, pure, and blessed praise.',
  ),
  CollectibleName(
    id: 66,
    arabic: 'الْمُحْصِي',
    transliteration: 'Al-Muhsi',
    english: 'The Counter',
    meaning: 'The One who counts and records everything with precision.',
    lesson:
        'Al-Muhsi has numbered every tear you have shed. None are forgotten.',
    hadith:
        'The Prophet ﷺ said: "Not a leaf falls but that He knows it. There is no grain in the darkness of the earth, nor anything moist or dry, but that it is written in a clear record." Al-Muhsi has numbered every tear. (Quran 6:59)',
    duaArabic:
        'يَا مُحْصِي لَا تُحَاسِبْنِي بِمَا أَحْصَيْتَهُ عَلَيَّ وَاعْفُ عَنِّي بِرَحْمَتِكَ',
    duaTransliteration:
        'Ya Muhsi, la tuhasibni bima ahsaytahu \'alayya wa\'fu \'anni birahmatik',
    duaTranslation:
        'O Counter, do not hold me fully accountable for what You have recorded against me, and pardon me with Your mercy.',
  ),
  CollectibleName(
    id: 67,
    arabic: 'الْمُبْدِئُ',
    transliteration: 'Al-Mubdi',
    english: 'The Originator',
    meaning: 'The One who begins creation without any prior model.',
    lesson:
        'Al-Mubdi created you as something entirely new. You are not a copy.',
    hadith:
        'Allah says: "He is the One who begins creation, then repeats it." Al-Mubdi originates without any prior model — you are not a copy of anyone who came before. (Quran 10:34)',
    duaArabic:
        'يَا مُبْدِئُ ابْدَأْ لِي صَفْحَةً جَدِيدَةً وَأَحْدِثْ لِي تَوْبَةً نَصُوحًا',
    duaTransliteration:
        'Ya Mubdi\', ibda\' li safhatan jadidatan wa-ahdith li tawbatan nasuhan',
    duaTranslation:
        'O Originator, begin for me a new page and bring me a sincere repentance.',
  ),
  CollectibleName(
    id: 68,
    arabic: 'الْمُعِيدُ',
    transliteration: 'Al-Muid',
    english: 'The Restorer',
    meaning: 'The One who brings back creation after its end.',
    lesson:
        'What was taken from you — Al-Muid can restore it, or replace it with better.',
    hadith:
        'Allah says: "He begins creation, then He will repeat it — and that is easier for Him." Al-Muid restores what was taken, and can replace it with better. (Quran 30:27)',
    duaArabic:
        'يَا مُعِيدُ أَعِدْ إِلَيَّ مَا أَخَذْتَهُ مِنِّي أَوْ أَبْدِلْنِي خَيْرًا مِنْهُ',
    duaTransliteration:
        'Ya Mu\'id, a\'id ilayya ma akhadhtahu minni aw abdilni khayran minh',
    duaTranslation:
        'O Restorer, return to me what was taken or replace it with something better.',
  ),
  CollectibleName(
    id: 69,
    arabic: 'الْمُحْيِي',
    transliteration: 'Al-Muhyi',
    english: 'The Giver of Life',
    meaning: 'The One who gives life to the dead and to all living things.',
    lesson: 'Al-Muhyi can breathe life into your hopes when they feel dead.',
    hadith:
        'Allah says: "Know that Allah gives life to the earth after its lifelessness." Al-Muhyi can breathe life into hopes that feel dead and revive what seems beyond saving. (Quran 57:17)',
    duaArabic:
        'يَا مُحْيِي أَحْيِ قَلْبِي بِالْإِيمَانِ وَأَحْيِ آمَالِي الَّتِي أَمَاتَتْهَا الدُّنْيَا',
    duaTransliteration:
        'Ya Muhyi, ahyi qalbi bil-iman wa-ahyi amaliyyal-lati amatat-hal-dunya',
    duaTranslation:
        'O Giver of Life, revive my heart with faith and revive the hopes that this world has killed.',
  ),
  CollectibleName(
    id: 70,
    arabic: 'الْمُمِيتُ',
    transliteration: 'Al-Mumeet',
    english: 'The Bringer of Death',
    meaning: 'The One who takes life at its appointed time.',
    lesson:
        'Al-Mumeet reminds us that this world is temporary — live for what lasts.',
    hadith:
        'The Prophet ﷺ said: "Remember frequently the destroyer of pleasures — death." Al-Mumeet reminds us this world is temporary, and investing in what remains is wisdom. (Tirmidhi 2307)',
    duaArabic:
        'اللَّهُمَّ أَحْسِنْ خَاتِمَتِي وَاجْعَلْ آخِرَ أَعْمَالِي خَيْرَهَا',
    duaTransliteration:
        'Allahumma ahsin khatimati waj\'al akhira a\'mali khayriha',
    duaTranslation:
        'O Allah, make my ending good and make the last of my deeds the best of them.',
  ),
  CollectibleName(
    id: 71,
    arabic: 'الْوَاجِدُ',
    transliteration: 'Al-Wajid',
    english: 'The Finder',
    meaning: 'The One who finds whatever He wills and lacks nothing.',
    lesson: 'Al-Wajid is never at a loss. He always finds a way for you.',
    hadith:
        'The Prophet ﷺ said: "Allah is never at a loss for what you need." Al-Wajid finds whatever He wills and lacks nothing — He always finds a way for His servant. (Derived from Names teachings)',
    duaArabic:
        'يَا وَاجِدُ أَوْجِدْ لِي مَخْرَجًا مِمَّا أَنَا فِيهِ وَلَا تَكِلْنِي إِلَى نَفْسِي',
    duaTransliteration:
        'Ya Wajid, awjid li makhrajam mimma ana fih wa la takilni ila nafsi',
    duaTranslation:
        'O Finder, find a way out for me from what I am in, and do not leave me to myself.',
  ),
  CollectibleName(
    id: 72,
    arabic: 'الْمَاجِدُ',
    transliteration: 'Al-Majid',
    english: 'The Noble',
    meaning: 'The One whose nobility and generosity overflow.',
    lesson: 'Al-Majid treats you with a generosity you could never earn.',
    hadith:
        'The Prophet ﷺ said in the salawat Ibrahim: "O Allah, send blessings upon Muhammad... as You sent blessings upon Ibrahim — You are Al-Majid." Al-Majid combines greatness with boundless generosity. (Bukhari 3370)',
    duaArabic:
        'يَا مَاجِدُ عَامِلْنِي بِسَخَائِكَ الَّذِي لَا أَسْتَحِقُّهُ وَأَكْرِمْنِي بِقُرْبِكَ',
    duaTransliteration:
        'Ya Majid, \'amilni bisakhaikhal-ladhi la astahiqquhu wa-akrimni biqurbik',
    duaTranslation:
        'O Noble, treat me with a generosity I could never earn, and honor me with Your closeness.',
  ),
  CollectibleName(
    id: 73,
    arabic: 'الْوَاحِدُ',
    transliteration: 'Al-Wahid',
    english: 'The One',
    meaning: 'The One who is unique and without partner in His essence.',
    lesson: 'Al-Wahid is the only One who will never let you down.',
    hadith:
        'When Bilal (RA) was tortured, he kept saying "Ahad, Ahad — One, One." He knew one name of Allah and was willing to die for it. (Seerah)',
    duaArabic: 'يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ',
    duaTransliteration: 'Ya Wahidu Ya Ahad, ijma\' shamli wa wahhid qasdi lak',
    duaTranslation:
        'O One, O Uniquely One, gather my scattered self and unify my purpose for You.',
  ),
  CollectibleName(
    id: 74,
    arabic: 'الْأَحَدُ',
    transliteration: 'Al-Ahad',
    english: 'The Unique',
    meaning:
        'The One who is absolutely singular, indivisible, and incomparable.',
    lesson:
        'Nothing compares to Al-Ahad. And nothing compares to the peace of knowing Him.',
    hadith:
        'When Bilal (RA) was tortured, he kept saying "Ahad, Ahad — One, One." He knew one name of Allah and was willing to die for it. (Seerah)',
    duaArabic: 'يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ',
    duaTransliteration: 'Ya Wahidu Ya Ahad, ijma\' shamli wa wahhid qasdi lak',
    duaTranslation:
        'O One, O Uniquely One, gather my scattered self and unify my purpose for You.',
  ),
  CollectibleName(
    id: 75,
    arabic: 'الْقَادِرُ',
    transliteration: 'Al-Qadir',
    english: 'The Capable',
    meaning: 'The One who has power over all things without effort.',
    lesson: 'What seems impossible to you is effortless for Al-Qadir.',
    hadith:
        'The Prophet ﷺ said: "Nothing is beyond the power of Allah." Al-Qadir parts seas and revives the dead — what seems impossible to you is effortless for Al-Qadir. (Muslim)',
    duaArabic:
        'يَا قَادِرُ لَا يَعْجِزُكَ شَيْءٌ فَاقْضِ لِي حَاجَتِي وَأَعِنِّي عَلَى مَا أَعْجَزَنِي',
    duaTransliteration:
        'Ya Qadir, la ya\'jizuka shay\' faqdhi li hajati wa-a\'inni \'ala ma a\'jazani',
    duaTranslation:
        'O Capable, nothing is beyond Your power. Fulfill my need and help me with what has left me helpless.',
  ),
  CollectibleName(
    id: 76,
    arabic: 'الْمُقْتَدِرُ',
    transliteration: 'Al-Muqtadir',
    english: 'The Omnipotent',
    meaning: 'The One who prevails over all things through His absolute power.',
    lesson: 'Al-Muqtadir has power even over the things that overpower you.',
    hadith:
        'Allah says: "In a seat of honor near a Sovereign, Perfect in Power (Al-Muqtadir)." His power is perfect in execution — He crushes arrogance and uplifts the helpless. (Quran 54:55)',
    duaArabic:
        'يَا مُقْتَدِرُ أَرِنِي قُدْرَتَكَ فِي أَمْرِي وَاجْعَلْ قُوَّتَكَ حِصْنِي',
    duaTransliteration:
        'Ya Muqtadir, arini qudrataka fi amri waj\'al quwwataka hisni',
    duaTranslation:
        'O Omnipotent, show Your power in my affairs and make Your strength my fortress.',
  ),
  CollectibleName(
    id: 77,
    arabic: 'الْمُقَدِّمُ',
    transliteration: 'Al-Muqaddim',
    english: 'The Expediter',
    meaning: 'The One who brings forward whatever He wills.',
    lesson:
        'Al-Muqaddim advances what is good for you, even when you cannot see the timing.',
    hadith:
        'The Prophet ﷺ said: "Your rizq chases you the way death chases you." What Al-Muqaddim advances is always on time. (Hadith)',
    duaArabic:
        'اللَّهُمَّ اجْعَلْنِي رَاضِيًا بِمَا قَسَمْتَ لِي وَبَارِكْ لِي فِيهِ',
    duaTransliteration:
        'Allahumma ij\'alni radiyan bima qasamta li wa barik li fihi',
    duaTranslation:
        'O Allah, make me pleased with what You have allotted me, and bless me in it.',
  ),
  CollectibleName(
    id: 78,
    arabic: 'الْمُؤَخِّرُ',
    transliteration: 'Al-Muakhkhir',
    english: 'The Delayer',
    meaning: 'The One who delays whatever He wills in His wisdom.',
    lesson: 'What Al-Muakhkhir delays is not denied — it is being perfected.',
    hadith:
        'Yusuf (AS) sat in prison for years after his cellmate forgot him. The delay was not the obstacle — it was the path to becoming minister of Egypt.',
    duaArabic:
        'اللَّهُمَّ اجْعَلْنِي رَاضِيًا بِمَا قَسَمْتَ لِي وَبَارِكْ لِي فِيهِ',
    duaTransliteration:
        'Allahumma ij\'alni radiyan bima qasamta li wa barik li fihi',
    duaTranslation:
        'O Allah, make me pleased with what You have allotted me, and bless me in it.',
  ),
  CollectibleName(
    id: 79,
    arabic: 'الْأَوَّلُ',
    transliteration: 'Al-Awwal',
    english: 'The First',
    meaning: 'The One who existed before all creation, with no beginning.',
    lesson:
        'Before your worries existed, Al-Awwal was already there with the solution.',
    hadith:
        'The Prophet ﷺ prayed: "O Allah, You are the First — nothing is before You. You are the Last — nothing is after You." (Muslim)',
    duaArabic:
        'اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ',
    duaTransliteration:
        'Allahumma anta\'l-Awwalu fa laysa qablaka shay\', wa anta\'l-Akhiru fa laysa ba\'daka shay\'',
    duaTranslation:
        'O Allah, You are the First — nothing before You. You are the Last — nothing after You.',
  ),
  CollectibleName(
    id: 80,
    arabic: 'الْآخِرُ',
    transliteration: 'Al-Akhir',
    english: 'The Last',
    meaning: 'The One who remains after all creation has perished.',
    lesson: 'Everything ends — except Al-Akhir. Invest in what reaches Him.',
    hadith:
        'The Prophet ﷺ said: "If the hour is established and one of you still has a small plant in his hand — plant it." Al-Akhir will see it through. (Ahmad)',
    duaArabic:
        'اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ',
    duaTransliteration:
        'Allahumma anta\'l-Awwalu fa laysa qablaka shay\', wa anta\'l-Akhiru fa laysa ba\'daka shay\'',
    duaTranslation:
        'O Allah, You are the First — nothing before You. You are the Last — nothing after You.',
  ),
  CollectibleName(
    id: 81,
    arabic: 'الظَّاهِرُ',
    transliteration: 'Az-Zahir',
    english: 'The Manifest',
    meaning: 'The One whose existence is evident in all creation.',
    lesson:
        'Look at the sky, the mountains, a newborn — Az-Zahir is manifest everywhere.',
    hadith:
        'The Prophet ﷺ taught a bedtime dua: "You are Al-Dhahir — nothing above You. You are Al-Batin — nothing closer to me than You." (Muslim)',
    duaArabic:
        'أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ',
    duaTransliteration:
        'Anta al-Dhahiru fa-laysa fawqaka shay\', wa anta al-Batinu fa-laysa dunaka shay\'',
    duaTranslation:
        'You are Al-Dhahir — there is nothing above You. You are Al-Batin — there is nothing closer to me than You.',
  ),
  CollectibleName(
    id: 82,
    arabic: 'الْبَاطِنُ',
    transliteration: 'Al-Batin',
    english: 'The Hidden',
    meaning: 'The One who is hidden from human perception yet closer than all.',
    lesson: 'Al-Batin is invisible to the eyes but unmistakable to the heart.',
    hadith:
        'A man the Prophet ﷺ pointed to as a person of Jannah had one hidden deed: "I never go to sleep without cleaning my heart of any hatred toward any person." (Ahmad)',
    duaArabic:
        'أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ',
    duaTransliteration:
        'Anta al-Dhahiru fa-laysa fawqaka shay\', wa anta al-Batinu fa-laysa dunaka shay\'',
    duaTranslation:
        'You are Al-Dhahir — there is nothing above You. You are Al-Batin — there is nothing closer to me than You.',
  ),
  CollectibleName(
    id: 83,
    arabic: 'الْوَالِي',
    transliteration: 'Al-Wali',
    english: 'The Governor',
    meaning: 'The One who governs and manages all affairs.',
    lesson: 'Al-Wali is running everything. You can rest.',
    hadith:
        'Allah says: "He is the Protecting Friend of the righteous." Al-Wali governs all affairs and is the patron who never abandons His servants. (Quran 7:196)',
    duaArabic:
        'يَا وَالِي كُنْ لِي وَلِيًّا حِينَ يَبْتَعِدُ الدُّنْيَا عَنِّي وَتَوَلَّ أَمْرِي كُلَّهُ',
    duaTransliteration:
        'Ya Wali, kun li waliyyan hina yabtab\'idud-dunya \'anni wa-tawalla amri kullahu',
    duaTranslation:
        'O Governor, be my protector when the world drifts away. Guard me with the grip that never slips and guide me gently through what I do not understand.',
  ),
  CollectibleName(
    id: 84,
    arabic: 'الْمُتَعَالِ',
    transliteration: 'Al-Mutaali',
    english: 'The Most Exalted',
    meaning: 'The One who is exalted above all that creation ascribes to Him.',
    lesson:
        'No matter how grand your conception of God — Al-Mutaali is greater.',
    hadith:
        'The Prophet ﷺ said: "Whoever humbles himself for Allah, Allah exalts him. Whoever exalts himself, Allah lowers him." (Muslim)',
    duaArabic:
        'يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ',
    duaTransliteration:
        'Ya \'Aliyyu ya Muta\'ali, irfa\' qalbi fawqa\'d-daghina wa\'s-sighar',
    duaTranslation:
        'O The Exalted, O The Supremely Exalted, raise my heart above resentment and smallness.',
  ),
  CollectibleName(
    id: 85,
    arabic: 'الْبَرُّ',
    transliteration: 'Al-Barr',
    english: 'The Source of Goodness',
    meaning: 'The One who is the source of all kindness and benevolence.',
    lesson: 'Every good thing in your life traces back to Al-Barr.',
    hadith:
        'The Prophet ﷺ said upon completing Hajj: "Our Lord is Al-Barr, Al-Ghafur." Al-Barr is the source of all kindness whose goodness is the origin of every blessing you have received. (Muslim 1342)',
    duaArabic:
        'يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ قُلُوبُ',
    duaTransliteration:
        'Ya Barr, thabbintni \'ala birrik waj\'al imani rasikhana hina tartajifu qulub',
    duaTranslation:
        'O Source of Goodness, keep me firm on the grounds of Your goodness. Make my faith steady when my heart trembles.',
  ),
  CollectibleName(
    id: 86,
    arabic: 'الْعَفُوُّ',
    transliteration: 'Al-Afuw',
    english: 'The Pardoner',
    meaning: 'The One who erases sins completely, as if they never happened.',
    lesson: "Al-Afuw doesn't just forgive — He wipes the slate clean entirely.",
    hadith:
        'Aisha (RA) asked: "If I find Laylat al-Qadr, what should I say?" The Prophet ﷺ taught: "Allahumma innaka Afuwwun tuhibbul afwa fa\'fu anni." (Tirmidhi)',
    duaArabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    duaTransliteration:
        'Allahumma innaka \'afuwwun tuhibbul-\'afwa fa\'fu \'anni',
    duaTranslation:
        'O Allah, You are the Pardoner, You love to pardon, so pardon me.',
  ),
  CollectibleName(
    id: 87,
    arabic: 'الرَّءُوفُ',
    transliteration: 'Ar-Rauf',
    english: 'The Compassionate',
    meaning: 'The One whose compassion is tender and overwhelmingly gentle.',
    lesson:
        "Ar-Rauf's compassion is softer than a mother's — and He never tires of it.",
    hadith:
        'Allah describes the Prophet ﷺ: "There has come to you a Messenger who is grieved by your suffering, concerned for your welfare — and to the believers he is Ra\'uf and Raheem." (Quran 9:128)',
    duaArabic: 'يَا رَؤُوفُ الْطُفْ بِي وَأَعِنِّي مِنَ الْبَلَاءِ',
    duaTransliteration: 'Ya Ra\'uf, ultuf bi wa a\'inni min al-bala\'',
    duaTranslation:
        'O Compassionate One, be gentle with me and protect me from trials.',
  ),
  CollectibleName(
    id: 88,
    arabic: 'مَالِكُ الْمُلْكِ',
    transliteration: 'Malik-ul-Mulk',
    english: 'Owner of Sovereignty',
    meaning: 'The One who owns all dominion and grants it to whom He wills.',
    lesson: 'Kingdoms rise and fall by the decree of Malik-ul-Mulk alone.',
    hadith:
        'Allah says: "Say: O Allah, Owner of Sovereignty (Malik-ul-Mulk), You give sovereignty to whom You will and You take sovereignty away from whom You will." (Quran 3:26)',
    duaArabic:
        'اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ',
    duaTransliteration:
        'Allahumma Malikal-Mulk, tu\'til-mulka man tasha\' wa tanzi\'ul-mulka mimman tasha\'',
    duaTranslation:
        'O Owner of Sovereignty, You give sovereignty to whom You will and take it from whom You will. Teach me that nothing I hold is truly mine.',
  ),
  CollectibleName(
    id: 89,
    arabic: 'ذُو الْجَلَالِ وَالْإِكْرَامِ',
    transliteration: 'Dhul-Jalali wal-Ikram',
    english: 'Lord of Majesty and Bounty',
    meaning:
        'The One who possesses both overwhelming majesty and abundant generosity.',
    lesson:
        'He is both awe-inspiring and intimately generous. Majesty and mercy, together.',
    hadith:
        'The Prophet ﷺ said: "Persist in saying Ya Dhal-Jalali wal-Ikram." He combines overwhelming majesty with abundant generosity — awe-inspiring and intimately giving at once. (Tirmidhi 3524)',
    duaArabic: 'يَا ذَا الْجَلَالِ وَالْإِكْرَامِ أَجِرْنَا مِنَ النَّارِ',
    duaTransliteration: 'Ya Dhal-Jalali wal-Ikram, ajirna minan-nar',
    duaTranslation:
        'O Lord of Majesty and Bounty, protect us from the Fire and grant us the nearness of Your generosity.',
  ),
  CollectibleName(
    id: 90,
    arabic: 'الْمُقْسِطُ',
    transliteration: 'Al-Muqsit',
    english: 'The Equitable',
    meaning: 'The One who acts with perfect fairness and justice.',
    lesson: 'Al-Muqsit will balance every scale. Justice will come.',
    hadith:
        'Allah says: "O My servants, I have forbidden oppression for Myself and made it forbidden among you, so do not oppress one another." (Muslim)',
    duaArabic:
        'اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ',
    duaTransliteration:
        'Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin',
    duaTranslation:
        'O Allah, judge between us and our people in truth — You are the best of judges.',
  ),
  CollectibleName(
    id: 91,
    arabic: 'الْجَامِعُ',
    transliteration: 'Al-Jami',
    english: 'The Gatherer',
    meaning: 'The One who gathers all creation on the Day of Judgment.',
    lesson:
        'Al-Jami will bring together what was scattered — including your broken pieces.',
    hadith:
        'Salman al-Farsi spent his life searching — from Zoroastrian Persia to Christian monasteries to slavery — until Al-Jami\' gathered every step in Madinah with the Prophet ﷺ. (Seerah)',
    duaArabic:
        'رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ',
    duaTransliteration:
        'Rabbana innaka jami\'un-nasi li-yawmin la rayba fih, innallaha la yukhlifu\'l-mi\'ad',
    duaTranslation:
        'Our Lord, surely You will gather the people for a Day about which there is no doubt. Indeed, Allah does not fail in His promise.',
  ),
  CollectibleName(
    id: 92,
    arabic: 'الْغَنِيُّ',
    transliteration: 'Al-Ghaniyy',
    english: 'The Self-Sufficient',
    meaning: 'The One who is free of all needs and upon whom all depend.',
    lesson: 'Al-Ghaniyy needs nothing from you — yet He invites you to ask.',
    hadith:
        'The Prophet ﷺ said: "Richness is not having many things — true richness is finding richness within yourself." (Bukhari & Muslim)',
    duaArabic: 'اللَّهُمَّ أَغْنِنِي بِفَضْلِكَ عَمَّن سِوَاكَ',
    duaTransliteration: 'Allahumma aghnini bifadlika amman siwak',
    duaTranslation:
        'O Allah, enrich me with Your bounty so that I need no one but You.',
  ),
  CollectibleName(
    id: 93,
    arabic: 'الْمُغْنِي',
    transliteration: 'Al-Mughni',
    english: 'The Enricher',
    meaning: 'The One who enriches whom He wills and frees them from need.',
    lesson:
        'True richness is when Al-Mughni fills your heart, not just your hands.',
    hadith:
        'The Prophet ﷺ said: "True richness is not having many things — true richness is finding richness within yourself." Al-Mughni fills the heart before the hand. (Bukhari 6446)',
    duaArabic:
        'يَا مُغْنِي أَغْنِنِي بِغِنَاكَ عَنْ سِوَاكَ وَاجْعَلْ قَلْبِي غَنِيًّا بِكَ',
    duaTransliteration:
        'Ya Mughni, aghnini bighinaka \'an siwak waj\'al qalbi ghaniyyan bik',
    duaTranslation:
        'O Enricher, make me rich through You so I need no one else. Fill my heart with You until no desire competes with Your glory.',
  ),
  CollectibleName(
    id: 94,
    arabic: 'الْمَانِعُ',
    transliteration: 'Al-Mani',
    english: 'The Withholder',
    meaning: 'The One who prevents harm and withholds what would not benefit.',
    lesson: 'What Al-Mani withholds from you is also a form of His protection.',
    hadith:
        'The Prophet ﷺ said: "What Allah withholds is also His mercy." Al-Mani prevents what would harm and withholds what would not benefit — His prevention is His protection. (Derived from Names teachings)',
    duaArabic:
        'يَا مَانِعُ امْنَعْ عَنِّي كُلَّ مَا يُبَاعِدُنِي عَنْكَ وَأَعْطِنِي كُلَّ مَا يُقَرِّبُنِي إِلَيْكَ',
    duaTransliteration:
        'Ya Mani\', mna\' \'anni kulla ma yuba\'iduni \'ank wa-a\'tini kulla ma yuqarribuni ilayk',
    duaTranslation:
        'O Withholder, prevent from me everything that distances me from You and give me everything that brings me closer to You.',
  ),
  CollectibleName(
    id: 95,
    arabic: 'الضَّارُّ',
    transliteration: 'Ad-Darr',
    english: 'The Distresser',
    meaning: 'The One who creates difficulty as a means of growth and return.',
    lesson:
        'The pain you feel is not pointless — Ad-Darr uses it to bring you back.',
    hadith:
        'The Prophet ﷺ said: "The greatest reward comes with the greatest trial. When Allah loves a people He tests them." Ad-Darr creates difficulty as a means of growth and return to Him. (Tirmidhi 2396)',
    duaArabic:
        'اللَّهُمَّ اجْعَلْ مَا أَصَابَنِي مِنْ ضَرٍّ كَفَّارَةً لِذُنُوبِي وَرَفْعًا لِدَرَجَاتِي',
    duaTransliteration:
        'Allahumma ij\'al ma asabani min dharrin kaffaratan lidhunubi wa-raf\'an lidarajati',
    duaTranslation:
        'O Allah, make whatever harm has befallen me an expiation for my sins and a raising of my ranks.',
  ),
  CollectibleName(
    id: 96,
    arabic: 'النَّافِعُ',
    transliteration: 'An-Nafi',
    english: 'The Benefiter',
    meaning: 'The One who creates benefit and good for His servants.',
    lesson: 'An-Nafi placed benefit in places you have not yet looked.',
    hadith:
        'The Prophet ﷺ said: "Ask Allah for benefit (naf\') in this world and the next." An-Nafi placed benefit in places you have not yet looked — every good thing traces back to Him. (Ibn Majah 3846)',
    duaArabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
    duaTransliteration:
        'Allahumma inni as\'aluka \'ilman nafi\'an wa rizqan tayyiban wa \'amalan mutaqabbalan',
    duaTranslation:
        'O Allah, I ask You for beneficial knowledge, pure provision, and accepted deeds.',
  ),
  CollectibleName(
    id: 97,
    arabic: 'الْبَدِيعُ',
    transliteration: 'Al-Badi',
    english: 'The Originator of the Heavens',
    meaning: 'The One who creates wonders without any prior model or material.',
    lesson:
        'Al-Badi is endlessly creative. Your next chapter can be unlike anything before.',
    hadith:
        'Allah says: "Badi\' al-samawati wal-ard — Originator of the heavens and the earth." Al-Badi creates wonders without any prior model — your next chapter can be unlike anything before. (Quran 2:117)',
    duaArabic:
        'يَا بَدِيعَ السَّمَاوَاتِ وَالْأَرْضِ أَنْتَ وَلِيِّي فَاغْفِرْ لِي',
    duaTransliteration: 'Ya Badi\'as-samawati wal-ard, anta waliyyi faghfir li',
    duaTranslation:
        'O Originator of the heavens and the earth, You are my protector — so forgive me.',
  ),
  CollectibleName(
    id: 98,
    arabic: 'الْبَاقِي',
    transliteration: 'Al-Baqi',
    english: 'The Everlasting',
    meaning: 'The One who remains forever after all creation has perished.',
    lesson: 'Attach your heart to Al-Baqi — everything else will pass away.',
    hadith:
        'Allah says: "Whatever is with you will end, and whatever is with Allah will last (baqi)." Al-Baqi remains forever after all creation has perished — attach your heart to what endures. (Quran 16:96)',
    duaArabic:
        'اللَّهُمَّ أَنْتَ الْبَاقِي وَنَحْنُ الْفَانُونَ فَاجْعَلْ بَقَاءَنَا طَاعَةً لَكَ',
    duaTransliteration:
        'Allahumma Antal-Baqi wa nahnul-fanun faj\'al baqaana ta\'atan lak',
    duaTranslation:
        'O Everlasting, You remain while we perish — make the remainder of our lives in obedience to You.',
  ),
  CollectibleName(
    id: 99,
    arabic: 'الرَّشِيدُ',
    transliteration: 'Ar-Rasheed',
    english: 'The Guide to Right Path',
    meaning: 'The One who directs all affairs toward their right conclusion.',
    lesson:
        'Ar-Rasheed is guiding your story to a conclusion better than you could write.',
    hadith:
        'The Prophet ﷺ said: "If Allah wants good for a person, He gives him understanding of the religion." Ar-Rasheed grants the wisdom to choose rightly. (Bukhari)',
    duaArabic: 'يَا رَشِيدُ أَلْهِمْنِي رُشْدِي وَقِنِي شَرَّ نَفْسِي',
    duaTransliteration: 'Ya Rasheed, alhimni rushdi wa qini sharra nafsi',
    duaTranslation:
        'O Guide to the Right Path, inspire my guidance and protect me from the evil of my own self.',
  ),
];

List<CollectibleName> currentCollectibleNames() {
  try {
    return getParsedCatalog<List<CollectibleName>>(
      PublicCatalogKeys.collectibleNames,
      _parseCollectibleNames,
    );
  } catch (_) {
    return allCollectibleNames;
  }
}

List<CollectibleName> _parseCollectibleNames(String raw) {
  final decoded = jsonDecode(raw) as List<dynamic>;
  final parsed = decoded
      .map((row) => CollectibleName.fromJson(row as Map<String, dynamic>))
      .where((card) => card.id > 0 && card.transliteration.isNotEmpty)
      .toList();
  return parsed.isNotEmpty ? parsed : allCollectibleNames;
}

CollectibleName getCollectiblePreviewCard() {
  final cards = currentCollectibleNames();
  return cards.isNotEmpty ? cards.first : allCollectibleNames.first;
}

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
  final cards = currentCollectibleNames();

  for (final n in cards) {
    if (n.transliteration.toLowerCase() == name.toLowerCase().trim()) return n;
  }
  for (final n in cards) {
    if (_normalize(n.transliteration) == norm) return n;
  }
  final stripped = norm.replaceFirst(RegExp(r'^(al|ar|as|ash|at|az|an)'), '');
  for (final n in cards) {
    final nStripped = _normalize(n.transliteration)
        .replaceFirst(RegExp(r'^(al|ar|as|ash|at|az|an)'), '');
    if (nStripped == stripped && stripped.length > 2) return n;
  }
  for (final n in cards) {
    final key = _normalize(n.transliteration);
    if (key.contains(norm) || norm.contains(key)) return n;
  }
  return null;
}

/// Smart name picker for the gacha flow:
/// 1. Undiscovered names first (random)
/// 2. Lowest-tier discovered names next (bronze before silver)
/// 3. All maxed — random gold card (duplicate)
CollectibleName pickNextCard(CardCollectionState collection) {
  final rand = math.Random();
  final cards = currentCollectibleNames();

  // Priority 1: undiscovered names
  final undiscovered =
      cards.where((n) => !collection.isDiscovered(n.id)).toList();
  if (undiscovered.isNotEmpty) {
    return undiscovered[rand.nextInt(undiscovered.length)];
  }

  // Priority 2: bronze cards (can tier to silver)
  final bronze = cards.where((n) => collection.tierFor(n.id) == 1).toList();
  if (bronze.isNotEmpty) {
    return bronze[rand.nextInt(bronze.length)];
  }

  // Priority 3: silver cards (can tier to gold)
  final silver = cards.where((n) => collection.tierFor(n.id) == 2).toList();
  if (silver.isNotEmpty) {
    return silver[rand.nextInt(silver.length)];
  }

  // All gold — random card (duplicate engagement)
  return cards[rand.nextInt(cards.length)];
}

// ---------------------------------------------------------------------------
// Tier enum helpers
// ---------------------------------------------------------------------------

String tierToEnum(int t) =>
    const {1: 'bronze', 2: 'silver', 3: 'gold', 4: 'emerald'}[t] ?? 'bronze';

int enumToTier(String e) =>
    const {'bronze': 1, 'silver': 2, 'gold': 3, 'emerald': 4}[e] ?? 1;

String _datePrefix(dynamic value) {
  final text = value?.toString() ?? '';
  return text.length >= 10 ? text.substring(0, 10) : text;
}

// ---------------------------------------------------------------------------
// Collection persistence
// ---------------------------------------------------------------------------

const String _collectionKey = 'sakina_card_collection';
const String _seenKey = 'sakina_card_seen';

class CardCollectionState {
  final Set<int> discoveredIds;
  final Map<int, String> discoveryDates;
  final Map<int, int> tiers; // card id → tier (1, 2, or 3)
  final Set<String>?
      _seenIds; // composite keys "$cardId:$tier" for viewed tiles

  const CardCollectionState({
    this.discoveredIds = const {},
    this.discoveryDates = const {},
    this.tiers = const {},
    Set<String>? seenIds,
  }) : _seenIds = seenIds;

  Set<String> get seenIds => _seenIds ?? const {};

  bool isUnseen(int id, [CardTier? tier]) {
    if (!discoveredIds.contains(id)) return false;
    if (tier != null) {
      return !seenIds.contains('$id:${tier.number}');
    }
    final maxTier = tiers[id] ?? 0;
    return !seenIds.contains('$id:$maxTier');
  }

  // Each name has 4 cards (Bronze, Silver, Gold, Emerald) = 396 total
  int get totalCards => currentCollectibleNames().length * 4;
  // Count tier-cards collected: a name at tier 3 = 3 cards, tier 2 = 2, tier 1 = 1
  int get totalDiscovered => tiers.values.fold(0, (sum, t) => sum + t);
  double get progress => totalCards > 0 ? totalDiscovered / totalCards : 0;

  bool isDiscovered(int id) => discoveredIds.contains(id);

  int tierFor(int id) => tiers[id] ?? 0;
  CardTier? cardTierFor(int id) {
    final t = tiers[id];
    if (t == null || t == 0) return null;
    return CardTierX.fromNumber(t);
  }

  bool hasTierVersion(int id, CardTier tier) {
    return (tiers[id] ?? 0) >= tier.number;
  }

  List<CardTier> unlockedTiersFor(int id) {
    final maxTier = tiers[id] ?? 0;
    return [
      if (maxTier >= 1) CardTier.bronze,
      if (maxTier >= 2) CardTier.silver,
      if (maxTier >= 3) CardTier.gold,
      if (maxTier >= 4) CardTier.emerald,
    ];
  }

  int countByTier(CardTier tier) {
    return discoveredIds.where((id) => (tiers[id] ?? 0) >= tier.number).length;
  }

  int get totalEmerald => countByTier(CardTier.emerald);
  int get totalGold => countByTier(CardTier.gold);
  int get totalSilver => countByTier(CardTier.silver);
  int get totalBronze => countByTier(CardTier.bronze);
}

Future<CardCollectionState> getCardCollection() async {
  final prefs = await SharedPreferences.getInstance();
  final scopedCollectionKey = supabaseSyncService.scopedKey(_collectionKey);

  const seedVersion = 'sakina_card_seed_v5';
  final scopedSeedVersion = supabaseSyncService.scopedKey(seedVersion);
  if (supabaseSyncService.currentUserId == null &&
      !prefs.containsKey(scopedSeedVersion)) {
    if (prefs.containsKey(seedVersion)) {
      await prefs.setBool(scopedSeedVersion, true);
    } else {
      await prefs.remove(scopedCollectionKey);
      await prefs.setBool(scopedSeedVersion, true);
    }
  }

  final raw =
      await supabaseSyncService.migrateLegacyStringCache(prefs, _collectionKey);
  if (raw == null) {
    return const CardCollectionState(
      discoveredIds: {},
      discoveryDates: {},
      tiers: {},
    );
  }

  final data = jsonDecode(raw) as Map<String, dynamic>;
  final ids = (data['ids'] as List<dynamic>?)?.cast<int>().toSet() ?? {};
  final dates = (data['dates'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), v as String)) ??
      {};
  final tiers = (data['tiers'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
      {};

  final seenRaw =
      await supabaseSyncService.migrateLegacyStringListCache(prefs, _seenKey) ??
          [];
  // Migration: old format was plain IDs ("5"), new format is "5:1", "5:2" etc.
  final seenIds = <String>{};
  for (final entry in seenRaw) {
    if (entry.contains(':')) {
      seenIds.add(entry);
    } else {
      final cardId = int.tryParse(entry);
      if (cardId != null) {
        final maxTier = tiers[cardId] ?? 0;
        for (int t = 1; t <= maxTier; t++) {
          seenIds.add('$cardId:$t');
        }
      }
    }
  }

  return CardCollectionState(
      discoveredIds: ids,
      discoveryDates: dates,
      tiers: tiers,
      seenIds: seenIds);
}

/// Engage with a card — discover it or upgrade its tier.
/// Each re-encounter tiers up immediately (no cooldown).
Future<CardEngageResult> engageCard(int cardId) async {
  final prefs = await SharedPreferences.getInstance();
  final scopedCollectionKey = supabaseSyncService.scopedKey(_collectionKey);
  final scopedSeenKey = supabaseSyncService.scopedKey(_seenKey);
  final raw =
      await supabaseSyncService.migrateLegacyStringCache(prefs, _collectionKey);
  final existingSeen =
      await supabaseSyncService.migrateLegacyStringListCache(prefs, _seenKey) ??
          [];

  Set<int> ids;
  Map<int, String> dates; // date card was first discovered
  Map<int, int> tiers;
  Map<int, String> tierUpDates; // date of last tier-up per card

  if (raw != null) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    ids = (data['ids'] as List<dynamic>?)?.cast<int>().toSet() ?? {};
    dates = (data['dates'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), v as String)) ??
        {};
    tiers = (data['tiers'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
        {};
    tierUpDates = (data['tierUpDates'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), v as String)) ??
        {};
  } else {
    ids = {};
    dates = {};
    tiers = {};
    tierUpDates = {};
  }

  final today = DateTime.now();
  final todayStr = today.toIso8601String().substring(0, 10);
  final bool isNew = !ids.contains(cardId);
  final int currentTier = tiers[cardId] ?? 0;
  int newTier = currentTier;
  bool tierChanged = false;

  if (isNew) {
    // First encounter — discover at Bronze (tier 1)
    ids.add(cardId);
    dates[cardId] = todayStr;
    tierUpDates[cardId] = todayStr;
    newTier = 1;
    tierChanged = true;
  } else if (currentTier < 3) {
    // Re-encounter — tier up immediately
    newTier = currentTier + 1;
    tierUpDates[cardId] = todayStr;
    tierChanged = true;
  }
  // tier 3 (Gold) is max — duplicate engagement

  final isDuplicate = !isNew && !tierChanged;

  // Mark the new tier as unseen so the glow shows on the new tile.
  if (tierChanged) {
    final seenList = List<String>.from(existingSeen);
    seenList.remove('$cardId:$newTier');
    await prefs.setStringList(scopedSeenKey, seenList);
  }

  tiers[cardId] = newTier;

  await prefs.setString(
    scopedCollectionKey,
    jsonEncode({
      'ids': ids.toList(),
      'dates': dates.map((k, v) => MapEntry(k.toString(), v)),
      'tiers': tiers.map((k, v) => MapEntry(k.toString(), v)),
      'tierUpDates': tierUpDates.map((k, v) => MapEntry(k.toString(), v)),
    }),
  );

  // Upsert to Supabase
  final userId = supabaseSyncService.currentUserId;
  if (userId != null && tierChanged) {
    await supabaseSyncService.upsertRow('user_card_collection', userId, {
      'name_id': cardId,
      'tier': tierToEnum(newTier),
      'discovered_at': dates[cardId] ?? todayStr,
      'last_engaged_at': todayStr,
    }, onConflict: 'user_id,name_id');
  }

  return CardEngageResult(
      isNew: isNew,
      newTier: newTier,
      tierChanged: tierChanged,
      isDuplicate: isDuplicate);
}

/// Mark a card as seen (user tapped to view detail).
Future<void> markCardSeen(int cardId, {int? tierNumber}) async {
  final prefs = await SharedPreferences.getInstance();
  final scopedSeenKey = supabaseSyncService.scopedKey(_seenKey);
  final existing = prefs.getStringList(scopedSeenKey) ?? [];
  final key = tierNumber != null ? '$cardId:$tierNumber' : '$cardId';
  if (!existing.contains(key)) {
    existing.add(key);
    await prefs.setStringList(scopedSeenKey, existing);
  }
}

/// Wipes the entire card collection (debug / stress-test use only).
Future<void> clearCardCollection() async {
  final prefs = await SharedPreferences.getInstance();
  final scopedCollectionKey = supabaseSyncService.scopedKey(_collectionKey);
  // Write empty collection — prevents seed logic from re-running
  await prefs.setString(
      scopedCollectionKey,
      jsonEncode({
        'ids': <int>[],
        'dates': <String, String>{},
        'tiers': <String, int>{},
        'tierUpDates': <String, String>{},
      }));
  await prefs.setBool(
      supabaseSyncService.scopedKey('sakina_card_seed_v5'), true);

  // Delete from Supabase
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    try {
      await supabaseSyncService.deleteRow(
          'user_card_collection', 'user_id', userId);
    } catch (_) {}
  }
}

Future<void> migrateCardCollectionCachesForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _collectionKey);
  await supabaseSyncService.migrateLegacyStringListCache(prefs, _seenKey);
}

Future<void> seedCardCollectionToSupabaseFromLocalCache() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final prefs = await SharedPreferences.getInstance();
  final localRaw =
      prefs.getString(supabaseSyncService.scopedKey(_collectionKey));
  if (localRaw == null) return;

  final data = jsonDecode(localRaw) as Map<String, dynamic>;
  final ids = (data['ids'] as List<dynamic>?)?.cast<int>() ?? [];
  if (ids.isEmpty) return;

  final dates = (data['dates'] as Map<String, dynamic>?) ?? {};
  final tiers = (data['tiers'] as Map<String, dynamic>?) ?? {};
  final tierUpDates = (data['tierUpDates'] as Map<String, dynamic>?) ?? {};

  final supabaseRows = ids.map((id) {
    final idStr = id.toString();
    final tierInt = (tiers[idStr] as int?) ?? 1;
    return {
      'user_id': userId,
      'name_id': id,
      'tier': tierToEnum(tierInt),
      'discovered_at': dates[idStr] as String? ??
          DateTime.now().toIso8601String().substring(0, 10),
      'last_engaged_at': tierUpDates[idStr] as String? ??
          DateTime.now().toIso8601String().substring(0, 10),
    };
  }).toList();

  await supabaseSyncService.batchInsertRows(
      'user_card_collection', supabaseRows);
}

Future<void> hydrateCardCollectionCacheFromRows(
  List<Map<String, dynamic>> rows,
) async {
  final prefs = await SharedPreferences.getInstance();
  final scopedCollectionKey = supabaseSyncService.scopedKey(_collectionKey);

  final ids = <int>{};
  final dates = <int, String>{};
  final tiers = <int, int>{};
  final tierUpDates = <int, String>{};

  for (final row in rows) {
    final nameId = row['name_id'] as int;
    ids.add(nameId);
    dates[nameId] = _datePrefix(row['discovered_at']);
    tiers[nameId] = enumToTier(row['tier'] as String? ?? 'bronze');
    tierUpDates[nameId] = _datePrefix(row['last_engaged_at']);
  }

  await prefs.setString(
    scopedCollectionKey,
    jsonEncode({
      'ids': ids.toList(),
      'dates': dates.map((k, v) => MapEntry(k.toString(), v)),
      'tiers': tiers.map((k, v) => MapEntry(k.toString(), v)),
      'tierUpDates': tierUpDates.map((k, v) => MapEntry(k.toString(), v)),
    }),
  );
}
