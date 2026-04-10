import 'dart:convert';

import 'package:sakina/services/public_catalog_service.dart';

class BrowseDua {
  final String id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;
  final List<String>? emotionTags;
  final String? whenToRecite;

  const BrowseDua({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
    this.emotionTags,
    this.whenToRecite,
  });
}

const List<String> duaCategories = [
  'anxiety',
  'grief',
  'hope',
  'gratitude',
  'morning',
  'evening',
  'protection',
  'forgiveness',
  'sleep',
  'travel',
  'food',
  'general',
  'wealth',
  'family',
  'guidance',
];

const List<BrowseDua> browseDuas = [
  // ── Morning ───────────────────────────────────────────────
  BrowseDua(
    id: 'morning-1',
    category: 'morning',
    title: 'Morning Remembrance',
    arabic:
        'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    transliteration:
        'Asbahna wa asbahal-mulku lillah, walhamdulillah, la ilaha illallahu wahdahu la sharika lah',
    translation:
        'We have entered the morning and the dominion belongs to Allah. Praise be to Allah. There is no god but Allah alone, with no partner.',
    source: 'Abu Dawud 5077',
    whenToRecite: 'Recite each morning upon waking.',
    emotionTags: ['morning', 'gratitude', 'peace'],
  ),
  BrowseDua(
    id: 'morning-2',
    category: 'morning',
    title: 'Morning Protection',
    arabic:
        'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
    transliteration:
        'Allahumma bika asbahna wa bika amsayna wa bika nahya wa bika namut wa ilaykan-nushur',
    translation:
        'O Allah, by You we enter the morning, by You we enter the evening, by You we live and by You we die, and to You is the resurrection.',
    source: "Jami' at-Tirmidhi 3391",
    whenToRecite: 'Recite in the morning.',
    emotionTags: ['morning', 'protection', 'trust'],
  ),
  BrowseDua(
    id: 'morning-3',
    category: 'morning',
    title: 'Seeking Wellbeing',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
    transliteration:
        "Allahumma inni as'alukal-'afiyata fid-dunya wal-akhirah",
    translation:
        'O Allah, I ask You for well-being in this world and the next.',
    source: 'Ibn Majah 3871',
    whenToRecite: 'Recite morning and evening.',
    emotionTags: ['morning', 'evening', 'hope', 'peace'],
  ),
  BrowseDua(
    id: 'morning-4',
    category: 'morning',
    title: 'Sayyid al-Istighfar',
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    transliteration:
        "Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana 'abduk, wa ana 'ala 'ahdika wa wa'dika mastata't, a'udhu bika min sharri ma sana't, abu'u laka bini'matika 'alayya wa abu'u bidhanbi faghfir li fa'innahu la yaghfirudh-dhunuba illa ant",
    translation:
        'O Allah, You are my Lord. There is no god but You. You created me and I am Your slave. I am upon Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessing upon me and acknowledge my sin, so forgive me, for none forgives sins but You.',
    source: 'Sahih al-Bukhari 6306',
    whenToRecite:
        'Recite in the morning. If one says it with conviction and dies that day, they are among the people of Paradise.',
    emotionTags: ['morning', 'forgiveness', 'repentance'],
  ),
  BrowseDua(
    id: 'morning-5',
    category: 'morning',
    title: 'Morning Praise',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'Subhanallahi wa bihamdih',
    translation: 'Glory be to Allah and praise be to Him.',
    source: 'Sahih Muslim 2691',
    whenToRecite:
        'Recite 100 times each morning. Sins are forgiven even if they are like the foam of the sea.',
    emotionTags: ['morning', 'gratitude', 'peace'],
  ),

  // ── Evening ───────────────────────────────────────────────
  BrowseDua(
    id: 'evening-1',
    category: 'evening',
    title: 'Evening Remembrance',
    arabic:
        'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    transliteration:
        'Amsayna wa amsal-mulku lillahi walhamdulillahi la ilaha illallahu wahdahu la sharika lah',
    translation:
        'We have entered the evening and the dominion belongs to Allah. Praise be to Allah. There is no god but Allah, alone, with no partner.',
    source: 'Abu Dawud 5077',
    whenToRecite: 'Recite each evening.',
    emotionTags: ['evening', 'gratitude', 'peace'],
  ),
  BrowseDua(
    id: 'evening-2',
    category: 'evening',
    title: 'Evening Forgiveness',
    arabic:
        'اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ وَمَلَائِكَتَكَ وَجَمِيعَ خَلْقِكَ أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ',
    transliteration:
        "Allahumma inni amsaytu ushhiduka wa ushhidu hamalata 'arshika wa mala'ikataka wa jami'a khalqika annaka antallahu la ilaha illa anta wa anna Muhammadan 'abduka wa rasuluk",
    translation:
        'O Allah, as I enter the evening I call on You to witness, and the bearers of Your Throne, Your angels, and all of Your creation, that You are Allah, none has the right to be worshipped but You, and that Muhammad is Your slave and Messenger.',
    source: 'Abu Dawud 5081',
    whenToRecite:
        'Recite 4 times each evening. One who says this will be freed from the Fire.',
    emotionTags: ['evening', 'forgiveness', 'peace'],
  ),
  BrowseDua(
    id: 'evening-3',
    category: 'evening',
    title: 'Seeking Refuge at Night',
    arabic:
        'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    transliteration:
        "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
    translation:
        'I seek refuge in the perfect words of Allah from the evil of what He has created.',
    source: 'Sahih Muslim 2708',
    whenToRecite:
        'Recite 3 times in the evening. Nothing will harm one who says this.',
    emotionTags: ['evening', 'protection', 'fear'],
  ),
  BrowseDua(
    id: 'evening-4',
    category: 'evening',
    title: 'Evening Tasbih',
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    transliteration: 'Subhanallahi wa bihamdih',
    translation: 'Glory be to Allah and praise be to Him.',
    source: 'Sahih Muslim 2691',
    whenToRecite: 'Recite 100 times each evening.',
    emotionTags: ['evening', 'gratitude'],
  ),
  BrowseDua(
    id: 'evening-5',
    category: 'evening',
    title: 'Ayat al-Kursi',
    arabic:
        'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
    transliteration:
        "Allahu la ilaha illa huwal-hayyul-qayyum, la ta'khudhuhu sinatun wa la nawm",
    translation:
        'Allah \u2014 there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep.',
    source: 'Quran 2:255',
    whenToRecite:
        'Recite once in the evening. Whoever recites it will be protected until morning.',
    emotionTags: ['evening', 'protection', 'peace'],
  ),

  // ── Sleep ─────────────────────────────────────────────────
  BrowseDua(
    id: 'sleep-1',
    category: 'sleep',
    title: 'Before Sleep',
    arabic: 'اللَّهُمَّ بِاسْمِكَ أَمُوتُ وَأَحْيَا',
    transliteration: 'Allahumma bismika amutu wa ahya',
    translation: 'O Allah, in Your name I die and I live.',
    source: 'Sahih al-Bukhari 6312',
    whenToRecite: 'Recite when lying down to sleep.',
    emotionTags: ['sleep', 'peace', 'trust'],
  ),
  BrowseDua(
    id: 'sleep-2',
    category: 'sleep',
    title: 'Sleep Dua of the Prophet \u{FDFA}',
    arabic:
        'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
    transliteration:
        "Allahumma qini 'adhabaka yawma tab'athu 'ibadak",
    translation:
        'O Allah, protect me from Your punishment on the day You resurrect Your servants.',
    source: 'Abu Dawud 5045',
    whenToRecite: 'Recite 3 times before sleep.',
    emotionTags: ['sleep', 'protection', 'fear'],
  ),
  BrowseDua(
    id: 'sleep-3',
    category: 'sleep',
    title: 'Al-Ikhlas, Al-Falaq, An-Nas Before Sleep',
    arabic:
        'قُلْ هُوَ اللَّهُ أَحَدٌ، اللَّهُ الصَّمَدُ، لَمْ يَلِدْ وَلَمْ يُولَدْ، وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    transliteration:
        'Qul huwallahu ahad. Allahus-samad. Lam yalid wa lam yulad. Wa lam yakun lahu kufuwan ahad',
    translation:
        'Say: He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born. Nor is there any equivalent to Him.',
    source: 'Quran 112 \u2014 Recite with Al-Falaq and An-Nas',
    whenToRecite:
        'Recite Surahs Al-Ikhlas, Al-Falaq, and An-Nas 3 times each before sleep, then blow into cupped hands and wipe over the body.',
    emotionTags: ['sleep', 'protection', 'peace'],
  ),
  BrowseDua(
    id: 'sleep-4',
    category: 'sleep',
    title: 'Dua When Waking at Night',
    arabic:
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    transliteration:
        "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa 'ala kulli shay'in qadir. Subhanallah, walhamdulillah, wa la ilaha illallah, wallahu akbar, wa la hawla wa la quwwata illa billah",
    translation:
        'There is no god but Allah alone with no partner. His is the dominion and His is the praise, and He has power over all things. Glory be to Allah. Praise be to Allah. There is no god but Allah. Allah is the Greatest. There is no power or might except with Allah.',
    source: 'Sahih al-Bukhari 1154',
    whenToRecite:
        'Recite when waking during the night. Make dua and it will be answered.',
    emotionTags: ['sleep', 'anxiety', 'peace'],
  ),
  BrowseDua(
    id: 'sleep-5',
    category: 'sleep',
    title: 'Dua for Good Dreams',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الشَّيْطَانِ الرَّجِيمِ وَمِنَ الأَحْلَامِ السَّيِّئَةِ',
    transliteration:
        "Allahumma inni a'udhu bika minash-shaytanir-rajim wa minal-ahlamis-sayyi'ah",
    translation:
        'O Allah, I seek refuge in You from the accursed Satan and from evil dreams.',
    source: 'Hisnul Muslim 108',
    whenToRecite: 'Recite when you wake from a bad dream.',
    emotionTags: ['sleep', 'protection', 'fear', 'anxiety'],
  ),

  // ── Anxiety ───────────────────────────────────────────────
  BrowseDua(
    id: 'anxiety-1',
    category: 'anxiety',
    title: 'Relief from Anxiety and Grief',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
    transliteration:
        "Allahumma inni a'udhu bika minal-hammi wal-hazani, wal-'ajzi wal-kasali, wal-bukhli wal-jubni, wa dhala'id-dayni wa ghalabatir-rijal",
    translation:
        'O Allah, I seek refuge in You from anxiety and grief, from weakness and laziness, from miserliness and cowardice, from being overcome by debt and the oppression of people.',
    source: 'Sahih al-Bukhari 6369',
    whenToRecite: 'Recite when feeling overwhelmed, anxious, or burdened.',
    emotionTags: ['anxiety', 'grief', 'stress', 'overwhelmed'],
  ),
  BrowseDua(
    id: 'anxiety-2',
    category: 'anxiety',
    title: 'For Ease in Difficulty',
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    transliteration: "Hasbunallahu wa ni'mal-wakil",
    translation:
        'Allah is sufficient for us, and He is the best Disposer of affairs.',
    source: 'Quran 3:173',
    whenToRecite:
        'Recite when facing a difficult situation or feeling helpless.',
    emotionTags: ['anxiety', 'fear', 'stress', 'trust'],
  ),
  BrowseDua(
    id: 'anxiety-3',
    category: 'anxiety',
    title: 'Dua of Yunus (AS)',
    arabic:
        'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    transliteration:
        'La ilaha illa anta subhanaka inni kuntu minaz-zalimin',
    translation:
        'There is no god but You, glory be to You; indeed I have been of the wrongdoers.',
    source: 'Quran 21:87',
    whenToRecite:
        'Recite in any moment of distress. The Prophet \u{FDFA} said no Muslim says this except that Allah responds to him.',
    emotionTags: ['anxiety', 'grief', 'repentance', 'distress'],
  ),
  BrowseDua(
    id: 'anxiety-4',
    category: 'anxiety',
    title: 'Dua for Distress',
    arabic:
        'اللَّهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ وَأَصْلِحْ لِي شَأْنِي كُلَّهُ',
    transliteration:
        "Allahumma rahmataka arju fala takilni ila nafsi tarfata 'aynin wa aslih li sha'ni kullahu",
    translation:
        'O Allah, it is Your mercy that I hope for. Do not leave me to myself for even a blink of an eye, and set right all my affairs.',
    source: 'Abu Dawud 5090',
    whenToRecite: 'Recite when feeling lost or overwhelmed.',
    emotionTags: ['anxiety', 'grief', 'overwhelmed', 'trust'],
  ),
  BrowseDua(
    id: 'anxiety-5',
    category: 'anxiety',
    title: 'The Dua for Hardship',
    arabic:
        'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
    transliteration:
        "Allahumma la sahla illa ma ja'altahu sahlan wa anta taj'alul-hazna idha shi'ta sahla",
    translation:
        'O Allah, there is no ease except in what You make easy, and You make the difficult easy when You will.',
    source: 'Ibn Hibban 974',
    whenToRecite: 'Recite when facing a difficult task or obstacle.',
    emotionTags: ['anxiety', 'stress', 'hope', 'trust'],
  ),

  // ── Grief ─────────────────────────────────────────────────
  BrowseDua(
    id: 'grief-1',
    category: 'grief',
    title: 'When Struck by Loss',
    arabic:
        'إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ، اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا',
    transliteration:
        "Inna lillahi wa inna ilayhi raji'un. Allahumma ajirni fi musibati wa akhlif li khayran minha",
    translation:
        'Indeed we belong to Allah, and to Him we shall return. O Allah, reward me in this affliction and replace it with something better.',
    source: 'Sahih Muslim 918',
    whenToRecite: 'Recite when struck by any calamity or loss.',
    emotionTags: ['grief', 'loss', 'sadness'],
  ),
  BrowseDua(
    id: 'grief-2',
    category: 'grief',
    title: 'For a Grieving Heart',
    arabic:
        'اللَّهُمَّ رَحْمَتَكَ أَرْجُو فَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ وَأَصْلِحْ لِي شَأْنِي كُلَّهُ',
    transliteration:
        "Allahumma rahmataka arju fala takilni ila nafsi tarfata 'aynin wa aslih li sha'ni kullahu",
    translation:
        'O Allah, it is Your mercy that I hope for. Do not leave me to myself for even a blink of an eye, and set right all my affairs.',
    source: 'Abu Dawud 5090',
    whenToRecite: 'Recite in times of grief and sorrow.',
    emotionTags: ['grief', 'sadness', 'loss'],
  ),
  BrowseDua(
    id: 'grief-3',
    category: 'grief',
    title: 'Dua When Visiting the Sick or Bereaved',
    arabic:
        'اللَّهُمَّ اغْفِرْ لِي وَلَهُ وَأَعْقِبْنِي مِنْهُ عُقْبَى حَسَنَةً',
    transliteration:
        "Allahummaghfir li wa lahu wa a'qibni minhu 'uqba hasanah",
    translation:
        'O Allah, forgive me and him (the deceased), and grant me a good reward after him.',
    source: 'Sahih Muslim 919',
    whenToRecite: 'Recite after the death of a loved one.',
    emotionTags: ['grief', 'loss', 'forgiveness'],
  ),

  // ── Hope ──────────────────────────────────────────────────
  BrowseDua(
    id: 'hope-1',
    category: 'hope',
    title: 'For Goodness in This World and Next',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
    translation:
        'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
    source: 'Quran 2:201',
    whenToRecite:
        'The most frequently recited dua of the Prophet \u{FDFA}. Recite at any time.',
    emotionTags: ['hope', 'general', 'aspiration'],
  ),
  BrowseDua(
    id: 'hope-2',
    category: 'hope',
    title: 'For Guidance and Firmness',
    arabic:
        'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
    transliteration:
        "Ya muqallibal-qulub, thabbit qalbi 'ala dinik",
    translation:
        'O Turner of hearts, make my heart firm upon Your religion.',
    source: "Jami' at-Tirmidhi 3522",
    whenToRecite:
        'Recite often, especially when feeling spiritually weak.',
    emotionTags: ['hope', 'faith', 'guidance'],
  ),
  BrowseDua(
    id: 'hope-3',
    category: 'hope',
    title: 'Dua of Ibrahim (AS)',
    arabic:
        'رَبِّ هَبْ لِي حُكْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ وَاجْعَلْ لِي لِسَانَ صِدْقٍ فِي الْآخِرِينَ',
    transliteration:
        "Rabbi hab li hukman wa alhiqni bis-salihin, waj'al li lisan sidqin fil-akhirin",
    translation:
        'My Lord, grant me wisdom and join me with the righteous, and grant me a reputation of truth among later generations.',
    source: 'Quran 26:83-84',
    whenToRecite:
        'Recite when seeking wisdom, righteousness, or a meaningful legacy.',
    emotionTags: ['hope', 'aspiration', 'guidance'],
  ),
  BrowseDua(
    id: 'hope-4',
    category: 'hope',
    title: 'For a Blessed Life',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    transliteration:
        "Allahumma inni as'alukal-huda wat-tuqa wal-'afafa wal-ghina",
    translation:
        'O Allah, I ask You for guidance, piety, chastity and self-sufficiency.',
    source: 'Sahih Muslim 2721',
    whenToRecite: 'Recite when seeking a wholesome and blessed life.',
    emotionTags: ['hope', 'guidance', 'contentment'],
  ),

  // ── Gratitude ─────────────────────────────────────────────
  BrowseDua(
    id: 'gratitude-1',
    category: 'gratitude',
    title: 'For the Ability to be Grateful',
    arabic:
        'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    transliteration:
        "Allahumma a'inni 'ala dhikrika wa shukrika wa husni 'ibadatik",
    translation:
        'O Allah, help me to remember You, to be grateful to You, and to worship You in an excellent manner.',
    source: 'Abu Dawud 1522',
    whenToRecite: 'Recite after every obligatory prayer.',
    emotionTags: ['gratitude', 'worship', 'morning'],
  ),
  BrowseDua(
    id: 'gratitude-2',
    category: 'gratitude',
    title: 'The Sunnah of Gratitude',
    arabic:
        'الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ',
    transliteration:
        'Alhamdulillahi alladhi bi ni\'matihi tatimmus-salihat',
    translation:
        'Praise be to Allah by Whose grace good deeds are completed.',
    source: 'Ibn Majah 3803',
    whenToRecite: 'Recite when something good happens.',
    emotionTags: ['gratitude', 'joy', 'blessing'],
  ),
  BrowseDua(
    id: 'gratitude-3',
    category: 'gratitude',
    title: 'When Wearing New Clothes',
    arabic:
        'الْحَمْدُ لِلَّهِ الَّذِي كَسَانِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
    transliteration:
        'Alhamdulillahil-ladhi kasani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah',
    translation:
        'Praise be to Allah who has clothed me with this and provided it for me, with no power or strength from me.',
    source: 'Abu Dawud 4023',
    whenToRecite: 'Recite when wearing new clothing.',
    emotionTags: ['gratitude', 'blessing'],
  ),

  // ── Protection ────────────────────────────────────────────
  BrowseDua(
    id: 'protection-1',
    category: 'protection',
    title: 'Ayat al-Kursi',
    arabic:
        'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
    transliteration:
        "Allahu la ilaha illa huwal-hayyul-qayyum, la ta'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard",
    translation:
        'Allah \u2014 there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth.',
    source: 'Quran 2:255',
    whenToRecite:
        'Recite after every obligatory prayer and before sleep. Whoever recites it after salah \u2014 only death separates them from Paradise.',
    emotionTags: ['protection', 'fear', 'peace', 'sleep'],
  ),
  BrowseDua(
    id: 'protection-2',
    category: 'protection',
    title: 'Morning and Evening Protection',
    arabic:
        'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    transliteration:
        "Bismillahil-ladhi la yadurru ma'asmihi shay'un fil-ardi wa la fis-sama'i wa huwas-sami'ul-'alim",
    translation:
        'In the name of Allah, with Whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing.',
    source: 'Abu Dawud 5088',
    whenToRecite:
        'Recite 3 times in the morning and evening. Nothing will harm the one who says it.',
    emotionTags: ['protection', 'morning', 'evening', 'fear'],
  ),
  BrowseDua(
    id: 'protection-3',
    category: 'protection',
    title: 'Seeking Refuge from Four Things',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْفَقْرِ، وَأَعُوذُ بِكَ مِنَ الْقِلَّةِ وَالذِّلَّةِ، وَأَعُوذُ بِكَ أَنْ أَظْلِمَ أَوْ أُظْلَمَ',
    transliteration:
        "Allahumma inni a'udhu bika minal-faqr, wa a'udhu bika minal-qillati wadh-dhillah, wa a'udhu bika an azlima aw uzlam",
    translation:
        'O Allah, I seek refuge in You from poverty, and I seek refuge in You from scarcity and humiliation, and I seek refuge in You from wronging others or being wronged.',
    source: 'Abu Dawud 1544',
    whenToRecite:
        'Recite when fearing hardship, injustice, or loss of dignity.',
    emotionTags: ['protection', 'anxiety', 'fear'],
  ),
  BrowseDua(
    id: 'protection-4',
    category: 'protection',
    title: 'Protection for Family',
    arabic:
        'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ',
    transliteration:
        "A'udhu bikalimatillahit-tammati min kulli shaytanin wa hammatin wa min kulli 'aynin lammah",
    translation:
        'I seek refuge in the perfect words of Allah from every devil, every poisonous creature, and from every evil eye.',
    source: 'Sahih al-Bukhari 3371',
    whenToRecite:
        'The Prophet \u{FDFA} used to seek protection for Al-Hasan and Al-Husain with this dua.',
    emotionTags: ['protection', 'family', 'evil eye'],
  ),
  BrowseDua(
    id: 'protection-5',
    category: 'protection',
    title: 'When Entering a Place',
    arabic:
        'أَعُوذُ بِوَجْهِ اللَّهِ الْكَرِيمِ وَبِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا يَنْزِلُ مِنَ السَّمَاءِ وَمَا يَعْرُجُ فِيهَا',
    transliteration:
        "A'udhu biwajhillahil-karim wa bikalimatillahit-tammati min sharri ma yanzilu minas-sama'i wa ma ya'ruju fiha",
    translation:
        'I seek refuge in the noble face of Allah and in the perfect words of Allah from the evil of what descends from the heaven and what ascends to it.',
    source: 'Abu Dawud 3899',
    whenToRecite: 'Recite when entering a new place or area.',
    emotionTags: ['protection', 'travel', 'fear'],
  ),

  // ── Forgiveness ───────────────────────────────────────────
  BrowseDua(
    id: 'forgiveness-1',
    category: 'forgiveness',
    title: 'Sayyid al-Istighfar',
    arabic:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    transliteration:
        "Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana 'abduk, wa ana 'ala 'ahdika wa wa'dika mastata't, a'udhu bika min sharri ma sana't, abu'u laka bini'matika 'alayya wa abu'u bidhanbi faghfir li fa'innahu la yaghfirudh-dhunuba illa ant",
    translation:
        'O Allah, You are my Lord. There is no god but You. You created me and I am Your slave. I am upon Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessing upon me and acknowledge my sin, so forgive me, for none forgives sins but You.',
    source: 'Sahih al-Bukhari 6306',
    whenToRecite:
        'The master supplication for forgiveness. Recite in the morning with conviction.',
    emotionTags: ['forgiveness', 'repentance', 'guilt', 'shame'],
  ),
  BrowseDua(
    id: 'forgiveness-2',
    category: 'forgiveness',
    title: 'Simple Istighfar',
    arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    transliteration: 'Astaghfirullaha wa atubu ilayh',
    translation:
        'I seek forgiveness from Allah and I repent to Him.',
    source: 'Sahih al-Bukhari 6307',
    whenToRecite:
        'The Prophet \u{FDFA} said this 70\u2013100 times a day. Recite at any time.',
    emotionTags: ['forgiveness', 'repentance', 'guilt'],
  ),
  BrowseDua(
    id: 'forgiveness-3',
    category: 'forgiveness',
    title: 'Dua of Adam (AS)',
    arabic:
        'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    transliteration:
        'Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakununna minal-khasirin',
    translation:
        'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
    source: 'Quran 7:23',
    whenToRecite:
        'Recite when feeling weighed down by sin or regret.',
    emotionTags: ['forgiveness', 'repentance', 'guilt', 'shame'],
  ),
  BrowseDua(
    id: 'forgiveness-4',
    category: 'forgiveness',
    title: 'Complete Forgiveness',
    arabic:
        'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ، دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ، وَعَلَانِيَتَهُ وَسِرَّهُ',
    transliteration:
        "Allahummaghfir li dhanbi kullahu, diqqahu wa jillahu, wa awwalahu wa akhirah, wa 'alaniyatahu wa sirrahu",
    translation:
        'O Allah, forgive me all my sins, the small and the great, the first and the last, the open and the secret.',
    source: 'Sahih Muslim 483',
    whenToRecite:
        'Recite when seeking complete forgiveness and a clean slate.',
    emotionTags: ['forgiveness', 'repentance', 'guilt'],
  ),
  BrowseDua(
    id: 'forgiveness-5',
    category: 'forgiveness',
    title: 'For Laylatul Qadr',
    arabic:
        'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    transliteration:
        "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni",
    translation:
        'O Allah, You are the Pardoner and You love to pardon, so pardon me.',
    source: "Jami' at-Tirmidhi 3513",
    whenToRecite:
        'Recite especially on the odd nights of the last 10 days of Ramadan, and whenever seeking pardon.',
    emotionTags: ['forgiveness', 'repentance', 'hope'],
  ),

  // ── Travel ────────────────────────────────────────────────
  BrowseDua(
    id: 'travel-1',
    category: 'travel',
    title: "Traveler's Dua",
    arabic:
        'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنقَلِبُونَ',
    transliteration:
        'Allahu akbar, Allahu akbar, Allahu akbar. Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin, wa inna ila rabbina lamunqalibun',
    translation:
        'Allah is the Greatest (\u00d73). Glory be to Him who has subjected this to us, and we could not have done it ourselves. And indeed, to our Lord we shall return.',
    source: 'Abu Dawud 2602',
    whenToRecite:
        'Recite when mounting a vehicle or beginning a journey.',
    emotionTags: ['travel', 'protection', 'gratitude'],
  ),
  BrowseDua(
    id: 'travel-2',
    category: 'travel',
    title: 'Dua Upon Returning',
    arabic:
        'آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
    transliteration:
        "Ayibuna ta'ibuna 'abiduna lirabbina hamidun",
    translation:
        'We return, repentant, worshipping, and praising our Lord.',
    source: 'Sahih al-Bukhari 1797',
    whenToRecite: 'Recite when returning from a journey.',
    emotionTags: ['travel', 'gratitude', 'repentance'],
  ),
  BrowseDua(
    id: 'travel-3',
    category: 'travel',
    title: 'For a Righteous Companion',
    arabic:
        'اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ',
    transliteration:
        "Allahumma hawwin 'alayna safarana hadha watwi 'anna bu'dahu, Allahumma anta as-sahibu fis-safari wal-khalifatu fil-ahl",
    translation:
        'O Allah, make this journey easy for us and fold up its distance for us. O Allah, You are the Companion in travel and the Guardian of the family.',
    source: 'Sahih Muslim 1342',
    whenToRecite: 'Recite at the start of a journey.',
    emotionTags: ['travel', 'protection', 'family'],
  ),
  BrowseDua(
    id: 'travel-4',
    category: 'travel',
    title: 'Entering a New Town',
    arabic:
        'اللَّهُمَّ رَبَّ السَّمَاوَاتِ السَّبْعِ وَمَا أَظْلَلْنَ، وَرَبَّ الْأَرَضِينَ السَّبْعِ وَمَا أَقْلَلْنَ، وَرَبَّ الشَّيَاطِينِ وَمَا أَضْلَلْنَ، وَرَبَّ الرِّيَاحِ وَمَا ذَرَيْنَ، أَسْأَلُكَ خَيْرَ هَذِهِ الْقَرْيَةِ وَخَيْرَ أَهْلِهَا',
    transliteration:
        "Allahumma rabbas-samawatis-sab'i wa ma azlalna, wa rabbal-aradinas-sab'i wa ma aqllalna, wa rabbash-shayatini wa ma adlalna, wa riyyahi wa ma dharayna, as'aluka khayra hadhihil-qaryati wa khayra ahlih",
    translation:
        'O Allah, Lord of the seven heavens and all they shade, Lord of the seven earths and all they carry, Lord of the devils and those they mislead, and Lord of the winds and what they scatter \u2014 I ask You for the good of this town and the good of its people.',
    source: 'Hisnul Muslim 173',
    whenToRecite: 'Recite when entering a new city or town.',
    emotionTags: ['travel', 'protection'],
  ),

  // ── Food ──────────────────────────────────────────────────
  BrowseDua(
    id: 'food-1',
    category: 'food',
    title: 'Before Eating',
    arabic: 'بِسْمِ اللَّهِ',
    transliteration: 'Bismillah',
    translation: 'In the name of Allah.',
    source: 'Sahih al-Bukhari 5376',
    whenToRecite:
        'Recite before eating. If you forget, say: Bismillahi awwalahu wa akhirah (In the name of Allah at its beginning and end).',
    emotionTags: ['food', 'gratitude'],
  ),
  BrowseDua(
    id: 'food-2',
    category: 'food',
    title: 'After Eating',
    arabic:
        'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ',
    transliteration:
        "Alhamdulillahil-ladhi at'amana wa saqana wa ja'alana muslimin",
    translation:
        'Praise be to Allah who has fed us and given us drink and made us Muslims.',
    source: 'Abu Dawud 3850',
    whenToRecite: 'Recite after finishing a meal.',
    emotionTags: ['food', 'gratitude'],
  ),
  BrowseDua(
    id: 'food-3',
    category: 'food',
    title: 'When Hosted',
    arabic:
        'اللَّهُمَّ بَارِكْ لَهُمْ فِيمَا رَزَقْتَهُمْ وَاغْفِرْ لَهُمْ وَارْحَمْهُمْ',
    transliteration:
        'Allahumma barik lahum fima razaqtahum waghfir lahum warhamhum',
    translation:
        'O Allah, bless them in what You have provided for them, forgive them and have mercy on them.',
    source: 'Sahih Muslim 2042',
    whenToRecite:
        'Recite as a dua for your host when invited to eat.',
    emotionTags: ['food', 'gratitude', 'blessing'],
  ),
  BrowseDua(
    id: 'food-4',
    category: 'food',
    title: 'When Breaking Fast',
    arabic:
        'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
    transliteration:
        "Dhahabaz-zama'u wabtallatil-'uruqu wa thabatal-ajru insha'allah",
    translation:
        'The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills.',
    source: 'Abu Dawud 2357',
    whenToRecite: 'Recite when breaking the fast at iftar.',
    emotionTags: ['food', 'gratitude', 'ramadan'],
  ),

  // ── General ───────────────────────────────────────────────
  BrowseDua(
    id: 'general-1',
    category: 'general',
    title: 'Dua for All Affairs',
    arabic:
        'اللَّهُمَّ أَصْلِحْ لِي دِينِيَ الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِيَ الَّتِي فِيهَا مَعَادِي',
    transliteration:
        "Allahumma aslih li dini alladhi huwa 'ismatu amri, wa aslih li dunyaya allati fiha ma'ashi, wa aslih li akhirati allati fiha ma'adi",
    translation:
        'O Allah, set right for me my religion which is the safeguard of my affairs. And set right for me my worldly life which is my means of livelihood. And set right for me my Hereafter which is where I shall return.',
    source: 'Sahih Muslim 2720',
    whenToRecite:
        'Recite when seeking comprehensive good in all dimensions of life.',
    emotionTags: ['general', 'hope', 'guidance'],
  ),
  BrowseDua(
    id: 'general-2',
    category: 'general',
    title: 'For Knowledge and Benefit',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
    transliteration:
        "Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbala",
    translation:
        'O Allah, I ask You for beneficial knowledge, wholesome sustenance, and accepted deeds.',
    source: 'Ibn Majah 925',
    whenToRecite: 'Recite after Fajr prayer.',
    emotionTags: ['general', 'morning', 'gratitude', 'hope'],
  ),
  BrowseDua(
    id: 'general-3',
    category: 'general',
    title: 'The Comprehensive Dua',
    arabic:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
    translation:
        'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
    source: 'Quran 2:201',
    whenToRecite:
        'The most frequently recited dua of the Prophet \u{FDFA}. Suitable for any occasion.',
    emotionTags: ['general', 'hope', 'gratitude'],
  ),
  BrowseDua(
    id: 'general-4',
    category: 'general',
    title: 'For a Good End',
    arabic:
        'اللَّهُمَّ اجْعَلْ خَيْرَ عُمُرِي آخِرَهُ وَخَيْرَ عَمَلِي خَوَاتِمَهُ وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ',
    transliteration:
        "Allahumma-j'al khayra 'umuri akhirah, wa khayra 'amali khawatimah, wa khayra ayyami yawma alqak",
    translation:
        'O Allah, make the best of my life its last part, the best of my deeds their final ones, and the best of my days the day I meet You.',
    source: 'Hisnul Muslim 246',
    whenToRecite: 'Recite when reflecting on your life and legacy.',
    emotionTags: ['general', 'hope', 'aspiration'],
  ),

  // ── Anxiety (new) ─────────────────────────────────────────────────────────
  BrowseDua(
    id: 'anxiety-6',
    category: 'anxiety',
    title: 'Make the Quran the Spring of My Heart',
    arabic:
        'اللَّهُمَّ إِنِّي عَبْدُكَ، ابْنُ عَبْدِكَ، ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ، أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ سَمَّيْتَ بِهِ نَفْسَكَ، أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ، أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ، أَوِ اسْتَأْثَرْتَ بِهِ فِي عِلْمِ الْغَيْبِ عِنْدَكَ، أَنْ تَجْعَلَ الْقُرْآنَ رَبِيعَ قَلْبِي، وَنُورَ صَدْرِي، وَجَلَاءَ حُزْنِي، وَذَهَابَ هَمِّي',
    transliteration:
        "Allahumma inni 'abduka, ibnu 'abdika, ibnu amatika, nasiyati biyadika, madin fiyya hukmuka, 'adlun fiyya qada'uka, as'aluka bikulli ismin huwa laka sammayta bihi nafsaka, aw anzaltahu fi kitabika, aw 'allamtahu ahadan min khalqika, awi asta'tharta bihi fi 'ilmil-ghaybi 'indaka, an taj'alal-Qur'ana rabi'a qalbi, wa nura sadri, wa jala'a huzni, wa dhahaba hammi",
    translation:
        'O Allah, I am Your slave, son of Your slave, son of Your maidservant. My forelock is in Your hand. Your command over me is forever executed and Your decree over me is just. I ask You by every name belonging to You which You have named Yourself, or revealed in Your Book, or taught to any of Your creation, or have preserved in the knowledge of the unseen with You, that You make the Quran the spring of my heart, the light of my chest, and the banisher of my sadness and the reliever of my anxiety.',
    source: 'Musnad Ahmad 3528',
    whenToRecite: 'Recite when overwhelmed by grief, stress, or anxiety.',
    emotionTags: ['anxiety', 'grief', 'peace', 'quran'],
  ),
  BrowseDua(
    id: 'anxiety-7',
    category: 'anxiety',
    title: 'Relief from Worries and Debt',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ',
    transliteration:
        "Allahumma inni a'udhu bika minal-hammi wal-hazan, wa a'udhu bika minal-'ajzi wal-kasal, wa a'udhu bika minal-jubni wal-bukhl, wa a'udhu bika min ghalabatid-dayni wa qahrir-rijal",
    translation:
        'O Allah, I seek refuge in You from anxiety and grief, and I seek refuge in You from inability and laziness, and I seek refuge in You from cowardice and miserliness, and I seek refuge in You from being overwhelmed by debt and overpowered by men.',
    source: 'Sunan Abi Dawud 1555',
    whenToRecite: 'Recite when facing financial stress, anxiety, or feeling powerless.',
    emotionTags: ['anxiety', 'grief', 'debt', 'worry'],
  ),
  BrowseDua(
    id: 'anxiety-8',
    category: 'anxiety',
    title: 'No Ease Except What You Make Easy',
    arabic:
        'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
    transliteration:
        "Allahumma la sahla illa ma ja'altahu sahlan, wa anta taj'alul-hazna idha shi'ta sahlan",
    translation:
        'O Allah, there is no ease except what You make easy, and You make grief easy if You will.',
    source: 'Sahih Ibn Hibban 2427',
    whenToRecite: 'Recite when facing a difficult situation or feeling overwhelmed.',
    emotionTags: ['anxiety', 'difficulty', 'trust'],
  ),

  // ── Grief (new) ───────────────────────────────────────────────────────────
  BrowseDua(
    id: 'grief-4',
    category: 'grief',
    title: 'Reward Me in My Calamity',
    arabic:
        'اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا',
    transliteration:
        "Allahumma'jurni fi musibati wa akhlif li khayran minha",
    translation:
        'O Allah, reward me in my calamity and replace it with something better.',
    source: 'Sahih Muslim 918',
    whenToRecite: 'Recite upon any loss or calamity.',
    emotionTags: ['grief', 'loss', 'patience', 'hope'],
  ),

  // ── Forgiveness (new) ─────────────────────────────────────────────────────
  BrowseDua(
    id: 'forgiveness-6',
    category: 'forgiveness',
    title: 'Dua of Adam (AS)',
    arabic:
        'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    transliteration:
        "Rabbana zalamna anfusana wa illam taghfir lana wa tarhamna lanakunanna minal-khosirin",
    translation:
        'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
    source: 'Quran 7:23',
    whenToRecite: 'Recite when seeking forgiveness after wrongdoing. The dua Allah taught Adam (AS) after his sin.',
    emotionTags: ['forgiveness', 'repentance', 'guilt'],
  ),

  // ── General (new) ─────────────────────────────────────────────────────────
  BrowseDua(
    id: 'general-5',
    category: 'general',
    title: 'Dua of Ibrahim (AS) for His Descendants',
    arabic:
        'رَبَّنَا تَقَبَّلْ مِنَّا ۖ إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
    transliteration:
        "Rabbana taqabbal minna innaka antas-Sami'ul-'Alim",
    translation:
        'Our Lord, accept from us. Indeed You are the Hearing, the Knowing.',
    source: 'Quran 2:127',
    whenToRecite: 'Recite after completing any act of worship or good deed.',
    emotionTags: ['general', 'acceptance', 'worship'],
  ),
  BrowseDua(
    id: 'general-6',
    category: 'general',
    title: 'For Righteous Provision Through Halal',
    arabic:
        'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    transliteration:
        "Allahumma ikfini bi-halalika 'an haramika wa aghnini bi-fadlika 'amman siwak",
    translation:
        'O Allah, suffice me with what You have made lawful, sparing me from what You have made unlawful, and make me independent of all others besides You through Your bounty.',
    source: "Jami' at-Tirmidhi 3563",
    whenToRecite: 'Recite when seeking sustenance or facing financial difficulty.',
    emotionTags: ['general', 'wealth', 'halal', 'trust'],
  ),

  // ── Wealth ────────────────────────────────────────────────────────────────
  BrowseDua(
    id: 'wealth-1',
    category: 'wealth',
    title: 'Contentment and Blessing in Provision',
    arabic:
        'اللَّهُمَّ قَنِّعْنِي بِمَا رَزَقْتَنِي وَبَارِكْ لِي فِيهِ وَاخْلُفْ عَلَيَّ كُلَّ غَائِبَةٍ لِي بِخَيْرٍ',
    transliteration:
        "Allahumma qanni'ni bima razaqtani wa barik li fihi wakhluf 'alayya kulla gha'ibatin li bikhair",
    translation:
        'O Allah, make me content with what You have provided me, bless me in it, and replace everything I have missed with something better.',
    source: 'Mustadrak al-Hakim 1/544',
    whenToRecite: 'Recite when feeling envious of others or lacking contentment with your provision.',
    emotionTags: ['wealth', 'contentment', 'gratitude', 'barakah'],
  ),
  BrowseDua(
    id: 'wealth-2',
    category: 'wealth',
    title: 'Protection from Debt',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ',
    transliteration:
        "Allahumma inni a'udhu bika minal-kufri wal-faqri wa a'udhu bika min 'adhabil-qabr",
    translation:
        'O Allah, I seek refuge in You from disbelief and poverty, and I seek refuge in You from the punishment of the grave.',
    source: 'Sunan Abi Dawud 5090',
    whenToRecite: 'Recite morning and evening as protection from financial hardship.',
    emotionTags: ['wealth', 'protection', 'poverty'],
  ),
  BrowseDua(
    id: 'wealth-3',
    category: 'wealth',
    title: 'For Barakah in Wealth',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
    transliteration:
        "Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbalan",
    translation:
        'O Allah, I ask You for beneficial knowledge, good lawful provision, and accepted deeds.',
    source: 'Sunan Ibn Majah 925',
    whenToRecite: 'Recite after Fajr prayer.',
    emotionTags: ['wealth', 'knowledge', 'worship', 'morning'],
  ),

  // ── Guidance / Istikhara ─────────────────────────────────────────────────
  BrowseDua(
    id: 'guidance-1',
    category: 'guidance',
    title: 'Dua of Istikhara',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ. اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ وَاقْدُرْ لِي الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ',
    transliteration:
        "Allahumma inni astakhiruka bi'ilmika wa astaqdiruka biqudratika wa as'aluka min fadlikal-'azim, fa-innaka taqdiru wa la aqdiru, wa ta'lamu wa la a'lamu, wa anta 'allamul-ghuyub. Allahumma in kunta ta'lamu anna hadhal-amra khayrun li fi dini wa ma'ashi wa 'aqibati amri faqdurhu li wa yassirhu li thumma barik li fihi, wa in kunta ta'lamu anna hadhal-amra sharrun li fi dini wa ma'ashi wa 'aqibati amri fasrifhu 'anni wasrifni 'anhu waqdur liyal-khayra haythu kana thumma ardini bih",
    translation:
        'O Allah, I seek Your guidance by Your knowledge, and I seek ability by Your power, and I ask You of Your great bounty. You have power and I have none. You know and I know not. You are the Knower of hidden things. O Allah, if You know that this matter is good for me in my religion, livelihood and in the outcome of my affairs, then ordain it for me, make it easy for me, then bless me in it. And if You know that this matter is bad for me in my religion, livelihood and in the outcome of my affairs, then turn it away from me and turn me away from it, and ordain for me the good wherever it may be, and then make me content with it.',
    source: 'Sahih al-Bukhari 1166',
    whenToRecite: 'Recite after two rak\'ahs of voluntary prayer when facing an important decision.',
    emotionTags: ['guidance', 'decision', 'trust', 'tawakkul'],
  ),
  BrowseDua(
    id: 'guidance-2',
    category: 'guidance',
    title: 'For Guidance on the Right Path',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    transliteration:
        "Allahumma inni as'alukal-huda wat-tuqa wal-'afafa wal-ghina",
    translation:
        'O Allah, I ask You for guidance, righteousness, chastity, and self-sufficiency.',
    source: 'Sahih Muslim 2721',
    whenToRecite: 'Recite regularly, especially when uncertain about a path in life.',
    emotionTags: ['guidance', 'taqwa', 'contentment'],
  ),
  BrowseDua(
    id: 'guidance-3',
    category: 'guidance',
    title: 'For a Straight Heart',
    arabic:
        'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
    transliteration:
        "Ya Muqallibal-qulubi thabbit qalbi 'ala dinik",
    translation:
        'O Turner of hearts, keep my heart firm upon Your religion.',
    source: "Jami' at-Tirmidhi 3522",
    whenToRecite: 'Recite frequently — the Prophet ﷺ said this dua often.',
    emotionTags: ['guidance', 'faith', 'steadfastness'],
  ),

  // ── Family ────────────────────────────────────────────────────────────────
  BrowseDua(
    id: 'family-1',
    category: 'family',
    title: 'For a Righteous Spouse and Children',
    arabic:
        'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
    transliteration:
        "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yunin waj'alna lilmuttaqina imama",
    translation:
        'Our Lord, grant us from among our wives and offspring comfort to our eyes and make us a leader for the righteous.',
    source: 'Quran 25:74',
    whenToRecite: 'Recite when making dua for your family, spouse, or children.',
    emotionTags: ['family', 'marriage', 'children', 'hope'],
  ),
  BrowseDua(
    id: 'family-2',
    category: 'family',
    title: 'For Righteous Children',
    arabic:
        'رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً ۖ إِنَّكَ سَمِيعُ الدُّعَاءِ',
    transliteration:
        "Rabbi hab li min ladunka dhurriyyatan tayyibah innaka sami'ud-du'a",
    translation:
        'My Lord, grant me from Yourself a good offspring. Indeed, You are the Hearer of supplication.',
    source: 'Quran 3:38',
    whenToRecite: 'Recite when making dua for children — this was the dua of Zakariya (AS).',
    emotionTags: ['family', 'children', 'hope', 'zakariya'],
  ),
  BrowseDua(
    id: 'family-3',
    category: 'family',
    title: 'For Parents',
    arabic:
        'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    transliteration:
        "Rabbir-hamhuma kama rabbayani saghira",
    translation:
        'My Lord, have mercy upon them as they brought me up when I was small.',
    source: 'Quran 17:24',
    whenToRecite: 'Recite regularly for your parents, especially after prayers.',
    emotionTags: ['family', 'parents', 'mercy', 'gratitude'],
  ),
  BrowseDua(
    id: 'family-4',
    category: 'family',
    title: 'For Wealth, Children, and Forgiveness',
    arabic:
        'اللَّهُمَّ أَكْثِرْ مَالَهُ وَوَلَدَهُ وَأَطِلْ حَيَاتَهُ وَاغْفِرْ لَهُ',
    transliteration:
        "Allahumma akthir malahu wa waladahu wa atil hayatahu waghfir lah",
    translation:
        'O Allah, increase his wealth, increase his children, extend his life, and forgive him his sins.',
    source: 'Sahih al-Bukhari 6334',
    whenToRecite: 'Recite as a dua for someone you love — the dua of the Prophet ﷺ for Anas ibn Malik (RA).',
    emotionTags: ['family', 'wealth', 'forgiveness', 'blessing'],
  ),

  // ── Guidance (new) ────────────────────────────────────────────────────────
  BrowseDua(
    id: 'guidance-4',
    category: 'guidance',
    title: 'Take Me Before a Fitna That Leads Me Astray',
    arabic:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ فِعْلَ الْخَيْرَاتِ وَتَرْكَ الْمُنْكَرَاتِ وَحُبَّ الْمَسَاكِينِ وَأَنْ تَغْفِرَ لِي وَتَرْحَمَنِي وَإِذَا أَرَدْتَ فِتْنَةً فِي النَّاسِ فَاقْبِضْنِي إِلَيْكَ غَيْرَ مَفْتُونٍ',
    transliteration:
        "Allahumma inni as'aluka fi'lal-khayrati wa tarkal-munkarat wa hubbal-masakin wa an taghfira li wa tarhamani wa idha aradta finnatан fin-nasi faqbidni ilayka ghayra maftun",
    translation:
        'O Allah, I ask You for the ability to do good deeds, to leave off evil, to love the poor, to forgive me and have mercy on me. And if You intend a trial for the people, then take me to You without being tried.',
    source: "Jami' at-Tirmidhi 3233",
    whenToRecite: 'Recite when fearing corruption of faith in times of widespread tribulation.',
    emotionTags: ['guidance', 'faith', 'protection', 'fitna'],
  ),

  // ── General (new) ─────────────────────────────────────────────────────────
  BrowseDua(
    id: 'general-7',
    category: 'general',
    title: 'Let Me Live and Die at the Best Time',
    arabic:
        'اللَّهُمَّ أَحْيِنِي مَا كَانَتِ الْحَيَاةُ خَيْرًا لِي وَتَوَفَّنِي إِذَا كَانَتِ الْوَفَاةُ خَيْرًا لِي',
    transliteration:
        "Allahumma ahyini ma kanatil-hayatu khayran li wa tawaffani idha kanatil-wafatu khayran li",
    translation:
        'O Allah, keep me alive as long as life is better for me, and let me die when death is better for me.',
    source: 'Sahih al-Bukhari 5671',
    whenToRecite: 'Recite when reflecting on life, death, and surrendering your timeline to Allah.',
    emotionTags: ['general', 'tawakkul', 'death', 'acceptance'],
  ),
  // ── Forgiveness (new) ─────────────────────────────────────────────────────
  BrowseDua(
    id: 'forgiveness-7',
    category: 'forgiveness',
    title: 'O Lord of Muhammad, Forgive Me',
    arabic:
        'اللَّهُمَّ رَبَّ مُحَمَّدٍ اغْفِرْ لِي ذَنْبِي وَأَذْهِبْ غَيْظَ قَلْبِي وَأَعِذْنِي مِنْ مُضِلَّاتِ الْفِتَنِ',
    transliteration:
        "Allahumma rabba Muhammadin ighfir li dhanbi wa adhhib ghayza qalbi wa a'idhni min mudillati al-fitan",
    translation:
        'O Allah, Lord of Muhammad, forgive my sin, remove the anger from my heart, and protect me from the trials that lead astray.',
    source: 'Mustadrak al-Hakim 1/527',
    whenToRecite: 'Recite when feeling angry, burdened by sin, or fearful of going astray.',
    emotionTags: ['forgiveness', 'anger', 'protection', 'fitna'],
  ),
  BrowseDua(
    id: 'forgiveness-8',
    category: 'forgiveness',
    title: 'Forgive Us and Our Brothers in Faith',
    arabic:
        'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِّلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَّحِيمٌ',
    transliteration:
        "Rabbana ighfir lana wa li-ikhwaninal-ladhina sabaquna bil-iman wa la taj'al fi qulubina ghillan lil-ladhina amanu Rabbana innaka Ra'ufur-Rahim",
    translation:
        'Our Lord, forgive us and our brothers who preceded us in faith, and put not in our hearts any resentment toward those who have believed. Our Lord, indeed You are Kind and Merciful.',
    source: 'Quran 59:10',
    whenToRecite: 'Recite when seeking forgiveness for yourself and the believers who came before you.',
    emotionTags: ['forgiveness', 'community', 'mercy', 'unity'],
  ),

  // ── General (new) ─────────────────────────────────────────────────────────
  BrowseDua(
    id: 'general-9',
    category: 'general',
    title: 'Best Dhikr of the Day of Arafah',
    arabic:
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    transliteration:
        "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir",
    translation:
        'There is no god but Allah alone, with no partner. To Him belongs the dominion, to Him all praise is due, and He is able to do all things.',
    source: "Jami' at-Tirmidhi 3585",
    whenToRecite: 'The best dhikr on the Day of Arafah and the best that the Prophet ﷺ and all prophets before him said.',
    emotionTags: ['general', 'gratitude', 'tawhid', 'arafah'],
  ),
  BrowseDua(
    id: 'general-10',
    category: 'general',
    title: 'Free Me from the Fire and Expand My Provision',
    arabic:
        'اللَّهُمَّ أَعْتِقْ رَقَبَتِي مِنَ النَّارِ وَأَوْسِعْ لِي مِنَ الرِّزْقِ الْحَلَالِ وَاصْرِفْ عَنِّي فَسَقَةَ الْجِنِّ وَالْإِنْسِ',
    transliteration:
        "Allahumma a'tiq raqabati minan-nar wa awsi' li minar-rizqil-halal wasrif 'anni fasaqatal-jinni wal-ins",
    translation:
        'O Allah, free me from the Fire, expand my lawful provision for me, and turn away from me the wickedness of the jinn and mankind.',
    source: 'Mustadrak al-Hakim 1/530',
    whenToRecite: 'Recite especially in the last ten nights of Ramadan and on the Day of Arafah.',
    emotionTags: ['general', 'protection', 'wealth', 'arafah'],
  ),

  BrowseDua(
    id: 'general-8',
    category: 'general',
    title: 'Protection from the Fire and the Grave',
    arabic:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ وَمِنْ عَذَابِ النَّارِ وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ وَمِنْ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ',
    transliteration:
        "Allahumma inni a'udhu bika min 'adhabil-qabri wa min 'adhabin-nar wa min fitnatil-mahya wal-mamat wa min fitnatil-masihid-dajjal",
    translation:
        'O Allah, I seek refuge in You from the punishment of the grave, from the punishment of the Fire, from the trials of life and death, and from the trial of the False Messiah.',
    source: 'Sahih al-Bukhari 1377',
    whenToRecite: 'Recite in the final tashahhud of every prayer — the Prophet ﷺ commanded this.',
    emotionTags: ['general', 'protection', 'afterlife', 'prayer'],
  ),
];

List<BrowseDua> get browseDuasCatalog {
  try {
    return getParsedCatalog<List<BrowseDua>>(
      PublicCatalogKeys.browseDuas,
      _parseBrowseDuas,
    );
  } catch (_) {
    return browseDuas;
  }
}

List<BrowseDua> _parseBrowseDuas(String raw) {
  final decoded = jsonDecode(raw) as List<dynamic>;
  final parsed = decoded.map((row) {
    final map = row as Map<String, dynamic>;
    return BrowseDua(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? '',
      title: map['title'] as String? ?? '',
      arabic: map['arabic'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      source: map['source'] as String? ?? '',
      emotionTags: (map['emotion_tags'] as List<dynamic>?)
          ?.map((tag) => tag.toString())
          .toList(),
      whenToRecite: map['when_to_recite'] as String?,
    );
  }).where((dua) => dua.id.isNotEmpty).toList();

  return parsed.isNotEmpty ? parsed : browseDuas;
}
