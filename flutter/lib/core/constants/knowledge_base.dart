/// Knowledge base distilled from Sheikh Omar Suleiman's "The Dua I Need" series.
/// Each entry captures the key teaching, emotional context, prophetic story, and dua
/// for a Name of Allah — drawn directly from the series transcripts.
///
/// Episodes covered:
///   Ep 2  — Al-Wahid, Al-Ahad, Al-Witr
///   Ep 3  — Al-Hadi, An-Nur, Al-Mubin
///   Ep 5  — Ar-Rabb, Al-Mawla, An-Nasir
///   Ep 7  — Ar-Rahman, Ar-Rahim
///   Ep 9  — Al-Ghafir, Al-Ghaffar, Al-Ghafoor, At-Tawwab
///   Ep 11 — As-Sami', Al-Qarib, Al-Mujib
///   Ep 13 — Al-Basir, Ash-Shahid, Ar-Raqib, As-Sittir
///   Ep 15 — Al-Ghani, Al-Hamid, Al-Fattah
///   Ep 17 — Al-Alim, Al-Hakim, Al-Latif, Al-Khabir
///   Ep 18 — Al-Qahhar, Al-Jabbar, Al-Mutakabbir
///   Ep 20 — Al-Adl, Al-Muqsit, Al-Hakam, Al-Hasib
///   Ep 23 — Ash-Shafi, At-Tayyib, Al-Mu'ti
///   Ep 24 — As-Sabur, Al-Halim, Al-Ali, Al-Muta'ali
///   Ep 29 — Al-Awwal, Al-Akhir, Az-Zahir, Al-Batin
///   Earlier episodes: Al-Wadud, Al-'Afuw, Al-Wakil, Al-Jami',
///                     Al-Karim/Al-Wahhab, Al-Hayy/Al-Qayyum,
///                     As-Samad, Al-Wali, Al-Majid/Al-'Azim,
///                     As-Salam/Al-Quddus, Al-Qawi/Al-Matin
///
/// "The Name I Need" series (Sheikh Mikaeel Smith):
///   Class 1  — Al-Fattah
///   Class 2  — Al-Shakur
///   Class 3  — Al-Karim
///   Class 4  — Al-Wakil
///   Class 5  — Al-Wadud
///   Class 6  — At-Tawwab
///   Class 7  — Al-Hadi
///   Class 8  — Al-Qabid, Al-Basit
///   Class 9  — Al-Dhahir, Al-Batin
///   Class 10 — Al-Ghani
///   Class 11 — Al-Mu'izz, Al-Mudhil
///   Class 12 — As-Salam, Al-Wahhab
///   Class 14 — Al-Jabbar
///   Class 15 — Al-Muqaddim, Al-Mu'akhkhir
///   Class 16 — Al-Qarib, Al-Mujib
///   Class 17 — Al-Latif
///   Class 18 — An-Nasir
///   Class 19 — Ar-Rabb
///   Class 20 — An-Nur
///   Class 21 — Ar-Razzaq
///   Class 22 — Al-'Afuww

class NameTeachingDua {
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;

  const NameTeachingDua({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
  });
}

class NameTeaching {
  final String name;
  final String arabic;
  final List<String> emotionalContext;
  final String coreTeaching;
  final String propheticStory;
  final NameTeachingDua dua;

  const NameTeaching({
    required this.name,
    required this.arabic,
    required this.emotionalContext,
    required this.coreTeaching,
    required this.propheticStory,
    required this.dua,
  });
}

const List<NameTeaching> nameTeachings = [
  // ─────────────────────────────────────────────
  // 0: AR-RAHMAN — The Most Merciful
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Ar-Rahman',
    arabic: 'الرَّحْمَٰنُ',
    emotionalContext: [
      "feeling unworthy of Allah's love",
      'overwhelmed by sins',
      'fear of being rejected by Allah',
      'grief or loss',
      'feeling like a burden',
      'depression',
      'hopelessness',
    ],
    coreTeaching:
        'Out of all His names, Allah chose Ar-Rahman and Ar-Rahim to open every surah because mercy is the first door to know Him. Before even Suleiman wrote it in his letter, it was written above the throne: "Verily, My mercy prevails over My wrath." The only name Allah pairs with His throne is Ar-Rahman — as if His mercy is the governing principle of everything beneath it, the roof of all creation. Ibn al-Qayyim said He made forgiveness more beloved to Him than vengeance, mercy more beloved than punishment, grace more beloved than justice, giving more beloved than withholding. His mercy frames every other name — He is merciful with His knowledge, merciful with His power, merciful with His decree.',
    propheticStory:
        'A woman who had been separated from her child in battle was seen clutching every child she found, desperately searching. When she finally found her child, she pressed him to her chest and nursed him. The Prophet \uFDFA asked: "Do you think this woman could throw her child into a fire?" They said no. He said, "Allah is more merciful to His servants than this woman is to her child."',
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ إِنَّكَ رَحْمَانٌ رَحِيمٌ وَرَحْمَتُكَ وَسِعَتْ كُلَّ شَيْءٍ فَارْحَمْنِي',
      transliteration:
          "Allahumma innaka Rahmanun Rahimun wa rahmatuka wasi'at kulla shay'in farhamni",
      translation:
          'O Allah, You are Ar-Rahman, Ar-Rahim, and Your mercy encompasses all things, so have mercy on me.',
      source:
          'Derived from Quranic attributes (7:156) and Prophetic tradition',
    ),
  ),

  // ─────────────────────────────────────────────
  // 1: AL-WAHID / AL-AHAD — The One
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wahid / Al-Ahad',
    arabic: 'الْوَاحِدُ الْأَحَدُ',
    emotionalContext: [
      'feeling pulled in too many directions',
      'distracted and scattered focus',
      'chasing approval from too many people',
      'addicted to validation',
      'career or money becoming the priority over Allah',
      'heart divided between many things',
      "feeling enslaved to people's opinions",
    ],
    coreTeaching:
        "You only need one God. Your heart was not designed to bow in a thousand directions. Al-Wahid negates all other gods in number; Al-Ahad negates any likeness — there is no God but Him, and no God like Him. Ibn al-Qayyim said: \"For One, be one upon one\" — unify yourself for the singular path. When Bilal was chained and tortured, he said only \"Ahad, Ahad\" — knowing this one name alone was enough to find strength in Allah and be willing to die for Him. The slave in chains became freer than the master with the whip. Shirk is never rational: it is born from insecurity or desire. Every false god is just human insecurity, desire, or corruption dressed in divinity.",
    propheticStory:
        'When Bilal (\u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647) was dragged across burning sand and rocks, he kept saying "Ahad, Ahad \u2014 One, One." When asked why he chose that word alone, he replied: "If I knew another name that would make them madder, I would have said it." We know all the names of Allah and are barely willing to live for Him, while Bilal knew one name and was willing to die for it.',
    dua: NameTeachingDua(
      arabic:
          'يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ',
      transliteration:
          "Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak",
      translation:
          'O One, O Uniquely One, gather my scattered self and unify my purpose for You.',
      source:
          'Derived from the teaching of Al-Wahid and Al-Ahad in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 2: AL-HADI / AN-NUR — The Guide / The Light
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Hadi / An-Nur',
    arabic: 'الْهَادِي النُّورُ',
    emotionalContext: [
      'spiritually lost',
      'confused about direction in life',
      'struggling with doubts about faith',
      'darkness of desire or despair',
      'stuck in a sin and cannot find the way out',
      "cannot feel Allah's presence",
      'wanting to return to Allah but not knowing how',
    ],
    coreTeaching:
        'In a Hadith Qudsi, Allah says: "O my servants, all of you are astray except those I have guided. So seek guidance of Me and I will guide you." Al-Hadi means the guide who did not create you without guidance \u2014 every atom knows its orbit, the baby finds its mother\'s chest, birds migrate without a compass. We too know how to make it back home to Him. Physical light lets the eye see physical forms; spiritual light lets the heart see meaning and expand. The Prophet \uFDFA said as he walked to prayer: "O Allah, place light in my heart, light on my tongue, light in my hearing, light in my sight \u2014 and make me a light." And when facing darkness of hardship: "I seek refuge in the light of Your face by which all darkness is dispelled."',
    propheticStory:
        "Umar ibn al-Khattab (\u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647) left home with a sword to kill the Prophet \uFDFA. A man mocked: 'Allah would guide the donkey of al-Khattab before He would guide Umar.' But look what happened \u2014 Al-Hadi flipped a switch already wired inside his chest, and Umar never looked back. He is now buried next to the Prophet \uFDFA. Al-Hadi guides whom He wills, not based on who we think is most deserving. Allah sees deep sincerity where we only see the surface.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي لِسَانِي نُورًا وَاجْعَلْنِي نُورًا',
      transliteration:
          "Allahumma ij'al fi qalbi nuran wa fi lisani nuran waj'alni nuran",
      translation:
          'O Allah, place light in my heart, light on my tongue, and make me a light.',
      source:
          "Bukhari \u2014 said by the Prophet \uFDFA on his way to prayer",
    ),
  ),

  // ─────────────────────────────────────────────
  // 3: AR-RABB — The Lord and Nurturer
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Ar-Rabb',
    arabic: 'الرَّبُّ',
    emotionalContext: [
      "feeling like Allah doesn't care about your personal life",
      'feeling purposeless',
      'wanting to belong to something',
      'searching for a father figure or guide',
      'exhausted from being your own guide',
      'feeling enslaved to systems or people',
      'wanting to be known and understood deeply',
    ],
    coreTeaching:
        "The Quran begins with \"Al-hamdu lillahi Rabb il-'alamin\" and ends with \"Rabb in-nas.\" From opening to closing, Allah frames your life through His Lordship. Rabb carries the meaning of tarbiyah \u2014 to nurture, to grow something, to bring it to its potential. Think of a farmer measuring the soil, measuring the water, shielding the plant from harsh wind, constantly giving nutrients and sunlight so it bears its maximum fruit. That's your Rabb with you. Ibn al-Qayyim said: \"Everything you fear in life, you run away from. But with Allah, you run TO Him \u2014 flee to Allah.\" The Prophet \uFDFA laughs at the despair of His servants while relief is near \u2014 not in mockery, but in mercy. Servitude to Allah is freedom from everything else.",
    propheticStory:
        "When Az-Zubayr (\u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647) was dying with massive debts, he told his son Abdullah: 'If you struggle to pay what I owe, seek help from my Mawla.' Abdullah did not understand until he asked: 'Who is your Mawla?' Az-Zubayr said: 'Allahu Mawlay \u2014 Allah is my Master.' After his death, whenever Abdullah struggled with the debts, he would say: 'Ya Mawla Az-Zubayr!' \u2014 and Allah would open a new door. The estate went from nothing to overflowing.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِرِضَاكَ مِنْ سَخَطِكَ وَبِمُعَافَاتِكَ مِنْ عُقُوبَتِكَ وَأَعُوذُ بِكَ مِنْكَ',
      transliteration:
          "Allahumma inni a'udhu bi-ridaka min sakhatika wa bi-mu'afatika min 'uqubatika wa a'udhu bika minka",
      translation:
          'O Allah, I seek refuge in Your pleasure from Your anger, and in Your pardon from Your punishment, and I seek refuge in You from You.',
      source:
          "Muslim \u2014 said by the Prophet \uFDFA, the language of one who knows refuge is only found in the One he fears to disappoint",
    ),
  ),

  // ─────────────────────────────────────────────
  // 4: AL-GHAFFAR / AL-GHAFOOR / AT-TAWWAB
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Ghaffar / Al-Ghafoor / At-Tawwab',
    arabic: 'الْغَفَّارُ الْغَفُورُ التَّوَّابُ',
    emotionalContext: [
      'guilt over sins',
      'feeling too sinful to be forgiven',
      'fallen into the same sin again after repenting',
      'ashamed to face Allah',
      'wondering if Allah will still accept me',
      'despair after repeated failure',
      'feeling unclean spiritually',
    ],
    coreTeaching:
        'Al-Ghafir forgives the initial sin. Al-Ghaffar forgives the repeated sins \u2014 every time you return, He meets you with forgiveness again. Al-Ghafoor is the all-encompassing forgiver whose quality of forgiveness is so vast it covers sins you did not even realize you committed. Allah says: "O My servant, if you brought Me an earth full of sins without associating a partner with Me, I would meet you with an earth full of forgiveness \u2014 and I would not mind." At-Tawwab actually turns towards you FIRST so that you can turn towards Him \u2014 He inspires repentance, sends reminders, opens pathways back. The Prophet \uFDFA said: "If you did not sin, Allah would replace you with a people who would sin and seek His forgiveness \u2014 because sometimes a sin that brings you closer to Allah is better than a good deed that fills you with arrogance."',
    propheticStory:
        "A man who killed 99 people asked a worshipper if Allah would forgive him \u2014 the man said no, so he killed him too (100). Then a scholar said: \"Who can stand between you and the mercy of Allah? Go to a new land and live righteously.\" On the way, he died. Allah commanded: measure the distance between him and the two lands \u2014 then moved the earth itself to bring him nearer to His mercy. Allah inspired his repentance, sent the scholar, and shifted the ground \u2014 all so He could forgive him.",
    dua: NameTeachingDua(
      arabic:
          'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
      transliteration:
          "Rabbighfir li wa tub 'alayya innaka anta't-Tawwabu'r-Rahim",
      translation:
          'My Lord, forgive me and accept my repentance. Indeed, You are At-Tawwab, Ar-Rahim.',
      source:
          "Bukhari \u2014 the Prophet \uFDFA said this 100 times a day",
    ),
  ),

  // ─────────────────────────────────────────────
  // 5: AS-SAMI' / AL-QARIB / AL-MUJIB
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "As-Sami' / Al-Qarib / Al-Mujib",
    arabic: 'السَّمِيعُ الْقَرِيبُ الْمُجِيبُ',
    emotionalContext: [
      'feeling like prayers are not being heard',
      'making dua for years with no answer',
      'feeling distant from Allah',
      'wondering if Allah cares',
      'tired of asking for the same thing',
      'doubting whether dua works',
      'longing for connection with Allah',
    ],
    coreTeaching:
        "Before your lips even moved, He was already listening. In every other question people ask the Prophet \uFDFA, the Quran says \"Say\" \u2014 but when asked about Allah's nearness, Allah answers directly without \"Say\": \"I am close.\" As-Sami' hears every voice, every decibel, and even what has not yet become sound. Al-Qarib's nearness can confront or comfort depending on what you are saying \u2014 He is close to everyone in His awareness, but close to the believer with His awareness AND His mercy. Imam Ahmad was asked: \"What is the distance between us and Allah's throne?\" He said: \"A sincere prayer from a pure heart.\" Du'a is not about informing Him \u2014 it is about transforming you. Every time you ask, you move closer.",
    propheticStory:
        "Zakariyya (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) stood alone in the corner of Masjid Al-Aqsa while the world slept, and made a silent call \u2014 what Arabic describes as a 'quiet shout,' because the cry of the soul doesn't need sound. Before he could even finish, Allah cut him off: 'I heard you \u2014 and here is the child you were asking for, already named Yahya.' Ibrahim (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) made the exact same du'a for a son generations before. As-Sami' heard both across generations, recorded their duas in His final revelation so that we all call upon our Rabb the same way.",
    dua: NameTeachingDua(
      arabic: 'إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ',
      transliteration: 'Inna Rabbi qaribun mujib',
      translation: 'Indeed my Lord is close and responsive.',
      source:
          "Quran 11:61 \u2014 words of the Prophet Salih (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645)",
    ),
  ),

  // ─────────────────────────────────────────────
  // 6: AL-BASIR / ASH-SHAHID
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Basir / Ash-Shahid',
    arabic: 'الْبَصِيرُ الشَّهِيدُ',
    emotionalContext: [
      'feeling invisible and unseen',
      'doing good that no one notices',
      'suffering in silence with no one witnessing your pain',
      'good deeds going unrecognized',
      'feeling like your struggle is unknown to anyone',
      'being judged wrongly or misunderstood',
      'sacrificing without acknowledgment',
    ],
    coreTeaching:
        "Al-Basir is the All-Seeing who sees what no one else sees \u2014 the parts you edit out even from yourself. In a world where cameras capture your face but not your heart, His gaze is the only one that heals instead of hunts. Ash-Shahid is the ever-present witness who testifies for you and to you. He is present in every scene, not just watching it. He witnesses the time you held yourself in pain and only responded with patience. He witnesses the time you held your tongue that no one else noticed. He called the martyr a \"shahid\" because the shahid bears witness to Allah's reward and how He saw them in their pain and honored them for their sacrifice. When no one stood up for you, Ash-Shahid recorded you.",
    propheticStory:
        "Yunus (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) was in three layers of darkness: the darkness of the night, the darkness of the sea, the darkness of the belly of the whale. Ibn Mas'ud (\u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647) narrated that Al-Basir saw and heard him in those three darknesses. Your heart can feel like that dark ocean sometimes. He says: 'The one who sees you when you rise and your circulation amongst those who prostrate' \u2014 between the two states, as if He's saying: 'You are never unseen. Not in your tears, not in your thoughts, not in your tests.'",
    dua: NameTeachingDua(
      arabic:
          'يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ',
      transliteration:
          "Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya'lamuhu siwak",
      translation:
          'O All-Seeing, You see what no one else sees. Bear witness for me in what only You know.',
      source:
          'Derived from the teaching of Al-Basir and Ash-Shahid in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 7: AL-GHANI / AL-FATTAH
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Ghani / Al-Fattah',
    arabic: 'الْغَنِيُّ الْفَتَّاحُ',
    emotionalContext: [
      'feeling stuck in life',
      'same cycle repeating with no way out',
      'stuck in a sin you cannot break free from',
      'feeling like doors are closed',
      'financial stagnation',
      'spiritual plateau',
      'feeling trapped',
    ],
    coreTeaching:
        "Al-Ghani is the Self-Sufficient who is entirely free of need. In a Hadith Qudsi: \"O child of Adam, devote yourself to My worship, and I will fill your heart with richness and remove your poverty. But if you don't, I will fill your hands with problems and not alleviate your poverty.\" The more you praise a blessing, the more fulfilling it becomes. Al-Fattah is the Opener \u2014 \"Whoever is mindful of Allah, He makes a way out, and provides for him from where he does not expect.\" Before Allah shows you the new entrance, He shows you the current exit. Ibn Taymiyyah when he was stuck would say: \"O teacher of Ibrahim, teach me. O giver of understanding to Sulaiman, grant me.\" Sometimes Al-Fattah doesn't open a new door to a new reality, but an inner door to the same reality \u2014 and suddenly you can walk where you once felt walled in.",
    propheticStory:
        "Nuh (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) said: 'My Lord, I am overpowered \u2014 so help me.' And Allah says: 'So We opened the gates of the heaven with rain pouring down and caused the earth to burst with springs.' Those who mocked him were swept away by the flood, opened by Al-Fattah. At Hudaybiyyah, the companions were turned away from the Ka'bah by terms they didn't want \u2014 then Allah said: 'Indeed, We have given you a clear conquest.' What looked like a setback was a door to victory. Al-Fattah will also open the final chapter with justice: every sealed file is opened on the Day of Judgment, and every wrong is met with His perfect fath, the opening no hand can close.",
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا افْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْفَاتِحِينَ',
      transliteration:
          "Rabbana iftah baynana wa bayna qawmina bil-haqq wa anta khayrul-fatihin",
      translation:
          'Our Lord, decide between us and our people in truth, and You are the best of those who decide.',
      source:
          "Quran 7:89 \u2014 dua of the Prophet Shu'ayb (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645)",
    ),
  ),

  // ─────────────────────────────────────────────
  // 8: AL-'ALIM / AL-HAKIM / AL-LATIF
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-'Alim / Al-Hakim / Al-Latif",
    arabic: 'الْعَلِيمُ الْحَكِيمُ اللَّطِيفُ',
    emotionalContext: [
      'unable to understand why something painful happened',
      'asking why me',
      'feeling like life makes no sense',
      'injustice with no explanation',
      'loss that feels pointless',
      'suffering without visible purpose',
      "questioning Allah's wisdom",
    ],
    coreTeaching:
        "Al-Alim knows what will happen before it does \u2014 He knows all the whats. Al-Hakim allows it to happen anyway for a greater purpose \u2014 He knows all the whys. These names are almost always paired because they complete each other. Yaqub didn't hand Yusuf a map to get home \u2014 he handed him the names of Allah. Al-Latif is He who delivers kindness and grace through hidden paths \u2014 you often only recognize His Lutf in hindsight. Imam al-Ghazali explained that Lutf has two strands: knowledge of the hidden details only He knows, and the delivery of hidden benefits through ways only He knows. He will put a glass of water, a sudden thought, someone's text message, a verse that seems revealed just for you \u2014 and it ends up being a game changer. That is Lutf.",
    propheticStory:
        "Yusuf (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) could have stared at the prison wall and said: 'Why would Al-Hakim put me in this rotten hole?' Instead, he noticed Al-Latif sending him the two cellmates with dreams to interpret. He could have focused on his brothers' cruelty in throwing him in the well. Instead he noticed Al-Latif sending the strangers' hand to lift him out. When he stood as the leader of Egypt, reunited with his family, he didn't say generic Alhamdulillah \u2014 he reached for Al-Latif: 'Indeed my Lord is subtle in what He wills. Indeed He is the All-Knowing, the All-Wise.' His father gave him Al-Alim and Al-Hakim to carry through it all. His lived experience unveiled Al-Latif.",
    dua: NameTeachingDua(
      arabic: 'اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا',
      transliteration:
          'Allahumma ya Lateefu, lutf bi fi umuri kulliha',
      translation:
          'O Allah, O Gentle One, be gentle with me in all my affairs.',
      source:
          'Traditional dua derived from the Name Al-Latif, cited in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 9: AL-QAHHAR / AL-JABBAR
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Qahhar / Al-Jabbar',
    arabic: 'الْقَهَّارُ الْجَبَّارُ',
    emotionalContext: [
      'facing oppression or injustice',
      'being bullied by someone with power over you',
      'wondering why the oppressor is still thriving',
      'feeling crushed by a tyrant',
      'workplace injustice',
      'political or systemic oppression',
      'feeling powerless against someone who wronged you',
    ],
    coreTeaching:
        'When you stand face to face with injustice, you don\'t need gentle names \u2014 you need the names that shake thrones. Al-Qahhar is the one who has the upper hand over all creation. He governs your heartbeat without permission, and He controls the tyrant\'s next breath without asking. Allah\'s delay is not neglect: "Never think Allah is unaware of what the wrongdoers do \u2014 He only delays them to a day when their eyes will stare in horror." Allah mocks the schemers: "They plot, and Allah plots, and His plot always prevails." Al-Jabbar means the Compeller AND the Healer \u2014 the word "jabara" means to set a broken bone back into place. Al-Qahhar breaks, Al-Jabbar repairs. Al-Qahhar presses the arrogant down, Al-Jabbar lifts the broken up.',
    propheticStory:
        "Yusuf (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645), speaking to his two fellow prisoners, said: 'O my fellow prisoners, are many lords better, or is Allah the One, Al-Qahhar, the Overpowering?' Pharaoh drowned in the same water he claimed to control \u2014 the mother of Musa had to put her son in a river to escape that tyrant, then Allah drowned Pharaoh by the staff of that very same Musa. Nimrod, who claimed to control life and death, was taken by a mosquito. Every tyrant is toppled by something smaller than himself so he can see how small he always was. On the Day the earth is changed, they will stand before Allah \u2014 the One, the Prevailing \u2014 the same names Yusuf used to free prisoners are the names Allah will use to judge the tyrant.",
    dua: NameTeachingDua(
      arabic:
          'يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي',
      transliteration:
          "Ya Qahhar, iqhar kulla jabbarin 'anid, wa Ya Jabbar, ujbur kasri",
      translation:
          'O Subduer, subdue every stubborn tyrant. O Compeller-Healer, mend my brokenness.',
      source:
          'Derived from the teaching of Al-Qahhar and Al-Jabbar in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 10: AL-'ADL / AL-HAKAM / AL-HASIB
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-'Adl / Al-Hakam / Al-Hasib",
    arabic: 'الْعَدْلُ الْحَكَمُ الْحَسِيبُ',
    emotionalContext: [
      'justice denied in this world',
      'no accountability for those who wronged you',
      'watching the wicked prosper',
      'suffering that went unacknowledged',
      'evidence destroyed or ignored',
      'corrupt systems',
      'loss of a loved one to injustice',
    ],
    coreTeaching:
        "Al-Adl means placing things exactly where they belong and giving every entitled one their due. \"O My servants, I have forbidden oppression for Myself and made it forbidden among you.\" Only He has the power to make something forbidden for Himself. Ibn Taymiyyah said: \"Allah will sustain a just nation even if they're not Muslim, and He may destroy an unjust nation even if they're Muslim.\" Al-Hakam delivers the final verdict with full knowledge of what was hidden and revealed, who intended treachery and who swallowed pain. Al-Hasib delivers the consequence \u2014 He accounts for every element no one else could capture: the hidden tears, the apology that no one acknowledged, the kindness that was misread as guilt, the text message you decided not to send. Allah kept the receipts of it all.",
    propheticStory:
        "Ali (\u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647), while Caliph, saw a Christian man walking with his armor. He said 'That's mine.' The man denied it. Ali \u2014 Caliph of the Muslims \u2014 said: 'Let's go to a judge.' The judge ruled against Ali because he had no proof. As they left, the man came back and said: 'I testify that this is the way of the Prophets \u2014 the leader took me to his judge, the judge ruled against him, and he abided by it. I bear witness there is no god but Allah.' He converted, gave the armor back, and said he had found it falling from Ali's luggage at the Battle of Siffin. Ali laughed and said: 'Take it back \u2014 as a gift for embracing Islam.' That is Al-Adl governing human beings.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ',
      transliteration:
          "Allahumma ij'al baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin",
      translation:
          'O Allah, judge between us and our people in truth \u2014 You are the best of judges.',
      source:
          'Derived from Quran 7:87 and the teaching of Al-Hakam in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 11: ASH-SHAFI
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Ash-Shafi',
    arabic: 'الشَّافِي',
    emotionalContext: [
      'illness \u2014 physical or mental',
      'chronic pain',
      'recovering from illness',
      'healing after trauma',
      'emotional wounds',
      'wanting healing but feeling unheard',
      'visiting or praying for a sick person',
    ],
    coreTeaching:
        "The Prophet \uFDFA prayed: \"Take away the harm, Lord of people. Heal, for You are the Healer, and there is no healing except Your healing \u2014 a healing that leaves behind no trace of illness or affliction.\" The doctor can only treat, but only Allah can heal. Take the means and do not worship the means. The Healer even heals with the sickness itself \u2014 the Prophet \uFDFA said: \"Do not curse the fever, for it burns off your sins the way fire burns off filth from iron.\" Ibn al-Qayyim (\u0631\u062D\u0645\u0647 \u0627\u0644\u0644\u0647) said: \"I stayed in Mecca ill with no doctor or medicine. I treated myself with al-Fatiha and saw an astonishing effect.\" The Quran is healing and mercy walking next to your medication \u2014 not replacing it, but blessing it.",
    propheticStory:
        "Muhammad ibn Hatib says: 'I was a child when a pot of boiling liquid tipped and burnt my hand. My mother ran with me to the Prophet \uFDFA.' He prayed: 'Take away the harm, Lord of people. Heal, for You are the Healer, and there is no healing except Your healing.' Ibrahim (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) said: 'And when I fall ill, it is He who cures me' \u2014 attributing the illness to himself but reserving the cure exclusively for Allah. The Prophet \uFDFA also told us that on the Day of Judgment, Allah will say: 'O son of Adam, I was sick but you did not visit Me.' When the servant asks how, Allah says: 'Did you not know that My servant was sick and you did not visit him? Had you visited him, you would have found Me with him.' The Healer is with the ill.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ اشْفِ أَنتَ الشَّافِي لَا شِفَاءَ إِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
      transliteration:
          "Allahumma Rabban-nasi, adhhib il-ba's, ishfi anta'sh-Shafi, la shifa'a illa shifa'uk, shifa'an la yughadiru saqama",
      translation:
          'O Allah, Lord of people, remove the illness, heal \u2014 You are the Healer, there is no healing except Your healing, a healing that leaves no illness behind.',
      source:
          "Bukhari and Muslim \u2014 dua for healing said by the Prophet \uFDFA",
    ),
  ),

  // ─────────────────────────────────────────────
  // 12: AS-SABUR / AL-HALIM
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'As-Sabur / Al-Halim',
    arabic: 'الصَّبُورُ الْحَلِيمُ',
    emotionalContext: [
      'running out of patience',
      'triggered and wanting to react',
      'patience wearing thin in a difficult relationship',
      'wanting to give up on someone',
      'chronic frustration',
      'anger management',
      'tired of waiting for change',
    ],
    coreTeaching:
        'As-Sabur is All-Patient \u2014 not the patience of one who cannot act, but the patience of one who can do everything in an instant, yet chooses the perfect moment. He never acts in haste and never ends up with regrets. His patience is endless, so He invites you to seek it from Him: "Seek help through patience and prayer." The Prophet \uFDFA said: "No one has ever been given a gift better and more vast than patience." Al-Halim is the Forbearing \u2014 how many times could He have seized you at the very moment of your sin? And yet He didn\'t. His forbearance isn\'t weakness, but measured power that comes from infinite grace. "No one shows more patience upon hearing abuse than Allah \u2014 they attribute a son to Him, yet He still gives them health and provision." So who are you and I not to be patient?',
    propheticStory:
        'A woman who was having seizures came to the Prophet \uFDFA: "When I have seizures I fall, and I\'m sometimes exposed. Can you make dua to remove this?" He said: "If you want, I can ask Allah to remove it. Or you can be patient and Jannah will be yours." She said: "Ya Rasulullah, I choose Jannah \u2014 but can you ask Allah that when I have a seizure, I\'m not exposed?" She went from wanting ash-Shafi to wanting as-Sabur because she understood that He would give her the capacity AND the reward that would make it all worth it.',
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ',
      transliteration:
          "Allahumma inni as'alukas-sabra wa a'udhu bika minal-jaza'",
      translation:
          'O Allah, I ask You for patience and I seek refuge in You from anxiety and distress.',
      source: 'Derived from Prophetic supplications for patience',
    ),
  ),

  // ─────────────────────────────────────────────
  // 13: AL-AWWAL / AL-AKHIR / AZ-ZAHIR / AL-BATIN
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Awwal / Al-Akhir / Az-Zahir / Al-Batin',
    arabic: 'الْأَوَّلُ الْآخِرُ الظَّاهِرُ الْبَاطِنُ',
    emotionalContext: [
      'fear of death',
      'grief over the passage of time',
      'fear of being forgotten',
      'anxiety about the future',
      'feeling like life is slipping away',
      'existential dread',
      'regret over wasted time',
    ],
    coreTeaching:
        'The Prophet \uFDFA prayed: "O Allah, You are the First \u2014 nothing is before You. You are the Last \u2014 nothing is after You. You are the Manifest \u2014 nothing is above You. You are the Hidden \u2014 nothing is nearer than You." Four names in a single breath framing your entire existence. Al-Awwal was there before the first star, before time had a clock to tick \u2014 you were thought of, designed, intended before a single human being was created. Al-Akhir doesn\'t mean the end in the way we fear endings \u2014 it means permanence. When everything else fades, He is just as there as He always was. Az-Zahir manifests in every sign around you. Al-Batin is not hidden as in inaccessible \u2014 He is hidden in nearness, in intimacy. He knows the thought before you thought it, the hope you\'re too ashamed to say out loud. He knows your worst \u2014 but He also knows your best before you can see it yourself.',
    propheticStory:
        "The Prophet \uFDFA said: 'If the hour is established and one of you still has a small plant in his hand and he is still able to plant it \u2014 then do so.' The sky is splitting, the earth is shaking, the horn is about to be blown \u2014 and you're holding a small plant. What's the point? Because Al-Awwal brought you here to do the seemingly insignificant. And Al-Akhir will see it through after you're gone. Al-Jami' will collect it. Al-Warith will inherit it. That deed is still with Him \u2014 recorded, preserved, rewarded. Don't be paralyzed by endings. Plant your seeds.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ',
      transliteration:
          "Allahumma anta'l-Awwalu fa laysa qablaka shay', wa anta'l-Akhiru fa laysa ba'daka shay'",
      translation:
          'O Allah, You are the First \u2014 nothing before You. You are the Last \u2014 nothing after You.',
      source:
          "Muslim \u2014 the Prophet \uFDFA's prayer that frames existence from beginning to end",
    ),
  ),

  // ─────────────────────────────────────────────
  // 14: AL-WADUD — The Loving
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wadud',
    arabic: 'الْوَدُودُ',
    emotionalContext: [
      'loneliness',
      'feeling unloved',
      'longing for connection',
      'broken relationships',
      'feeling forgotten or invisible',
      'heartbreak',
      'social isolation',
    ],
    coreTeaching:
        "Al-Wadud is the One who is willing to love \u2014 but you have to be loyal in that love. When Allah loves you, it never stops at just feelings. The current of love runs from the throne of Ar-Rahman, through the angels of light, into the lives of people you may not have even met yet. Al-Wadud announces your name in the heavens for the simplest act of love on earth. If Al-Wadud loves the repentant sinner so much and rejoices for him, how much more does He love the striving worshipper?",
    propheticStory:
        'The Prophet \uFDFA said: "When Allah loves a servant, He says to Jibreel: \'I love so-and-so, so love him.\' Then Jibreel loves him. Then Jibreel announces to the inhabitants of the heavens: \'Allah loves so-and-so, so love him.\' So the inhabitants of the heavens love him. Then acceptance is established for him on the earth." Your name can be echoing through the heavens because of one sincere moment of love.',
    dua: NameTeachingDua(
      arabic:
          'يَا وَدُودُ يَا رَحِيمُ اجْعَلْ فِي قَلْبِي مَحَبَّتَكَ وَحَبِّبْنِي إِلَيْكَ',
      transliteration:
          "Ya Wadud, Ya Rahim, ij'al fi qalbi mahabbataka wa habbibni ilayk",
      translation:
          'O Loving, O Merciful, place Your love in my heart and make me beloved to You.',
      source:
          'Derived from the teaching of Al-Wadud in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 15: AL-'AFUW — The Pardoner
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-'Afuw",
    arabic: 'الْعَفُوُّ',
    emotionalContext: [
      'guilt',
      'shame',
      'past sins weighing heavily',
      'fear of not being forgiven',
      'feeling spiritually dirty',
      'regret',
      'struggling to forgive yourself',
    ],
    coreTeaching:
        "Al-'Afuw is beyond Al-Ghafoor and At-Tawwab. Al-Ghafoor covers your sin \u2014 but a trace remains. Al-'Afuw erases the sin entirely from the record, as if it never happened. Think of two job applicants: one with a clean record, one whose record says 'pardoned.' Allah is Al-'Afuw \u2014 He doesn't deal with you like people do. He doesn't just forgive; He erases. 'Afw comes from the root meaning to erase, wipe clean. Forgiveness leaves a note in the file; pardon removes the file entirely.",
    propheticStory:
        "Aisha (\u0631\u0636\u064A \u0627\u0644\u0644\u0647 \u0639\u0646\u0647\u0627) asked: 'If I find Laylat al-Qadr, what should I say?' The Prophet \uFDFA taught her the most comprehensive dua of erasure: 'Allahumma innaka 'Afuwwun tuhibbul 'afwa fa'fu 'anni.' Through her single question, every believer was given the simplest key to the widest mercy.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
      transliteration:
          "Allahumma innaka 'Afuwwun tuhibbul 'afwa fa'fu 'anni",
      translation:
          "O Allah, You are Al-'Afuw, You love to pardon, so pardon me.",
      source:
          "Al-Tirmidhi \u2014 taught by the Prophet \uFDFA to Aisha specifically for Laylat al-Qadr",
    ),
  ),

  // ─────────────────────────────────────────────
  // 16: AL-WAKIL — The Trustee
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wakil',
    arabic: 'الْوَكِيلُ',
    emotionalContext: [
      'anxiety',
      'feeling out of control',
      'fear of the future',
      'overwhelmed by responsibilities',
      'facing powerful adversaries',
      'helplessness',
      'when things are beyond your control',
    ],
    coreTeaching:
        "Al-Wakil is the One you entrust your affairs to when you've done everything you can. Hasbunallah wa ni'mal wakeel is not a phrase of resignation \u2014 it is a declaration of transfer. Ibrahim (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) said it when thrown into the fire. Muhammad \uFDFA said it when warned about enemies. When you make Allah your Wakeel, you are not abandoning effort \u2014 you are handing the outcome to the One who can actually control it.",
    propheticStory:
        "When Ibrahim (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) was thrown into the fire, Jibreel appeared and asked: 'Do you need anything?' Ibrahim replied: 'From you, no.' He made Allah his Wakeel. Allah commanded the fire: 'Be cool and safe for Ibrahim.' The same fire intended as certain destruction became a place of coolness. What appears as certain harm in the hands of your enemies is always subject to the permission of Al-Wakil.",
    dua: NameTeachingDua(
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: "Hasbunallah wa ni'mal wakeel",
      translation:
          'Allah is sufficient for us, and He is the best of trustees.',
      source:
          'Quran 3:173 \u2014 spoken by the companions when warned of their enemies',
    ),
  ),

  // ─────────────────────────────────────────────
  // 17: AL-JAMI' — The Gatherer
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-Jami'",
    arabic: 'الْجَامِعُ',
    emotionalContext: [
      'feeling scattered and lost',
      'scattered life goals or dreams',
      'feeling like efforts are wasted',
      'missing loved ones',
      'wondering if scattered duas are heard',
      'feeling disconnected from Allah',
      'grief over what has been lost',
    ],
    coreTeaching:
        "Al-Jami' is the One who gathers what life has scattered \u2014 scattered hopes, scattered story, scattered self, scattered duas, all the years that don't seem to add up. Salman al-Farsi's entire life felt like a string of unanswered questions. Al-Latif had been bringing it all together for him his entire life, and he ended up digging a trench to survive a siege with the Messenger of Allah \uFDFA. Just like for Yusuf \u2014 the pit, the prison, the palace \u2014 Al-Jami' was working in each scattered chapter.",
    propheticStory:
        "Salman al-Farsi spent his life searching for truth \u2014 leaving his Zoroastrian family, following Christian monks across Persia and Syria, being enslaved, finally arriving in Madinah just in time to meet the Prophet \uFDFA. What looked like a broken, scattered life was Al-Jami' gathering every step toward a single destination. He narrated: 'Your Lord is shy and generous \u2014 He is too shy to turn away the hands of His servant when he raises them to Him.' All of it \u2014 the efforts, the prayers, the tears \u2014 gathered into something whole.",
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ',
      transliteration:
          "Rabbana innaka jami'un-nasi li-yawmin la rayba fih, innallaha la yukhlifu'l-mi'ad",
      translation:
          "Our Lord, surely You will gather the people for a Day about which there is no doubt. Indeed, Allah does not fail in His promise.",
      source: 'Quran 3:9',
    ),
  ),

  // ─────────────────────────────────────────────
  // 18: AL-KARIM / AL-WAHHAB — The Generous / The Bestower
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Karim / Al-Wahhab',
    arabic: 'الْكَرِيمُ الْوَهَّابُ',
    emotionalContext: [
      'financial stress or poverty',
      'feeling undeserving of goodness',
      'hopelessness about provision',
      'waiting for a blessing that seems delayed',
      'feeling like prayers about needs go unanswered',
      'wanting guidance or a child or a spouse',
      'comparing yourself to others who seem to have more',
    ],
    coreTeaching:
        "Al-Karim gives above what is due \u2014 generous not because you earned it, but because generosity is who He is. Al-Wahhab gives Hibah \u2014 a pure gift out of love with no strings attached, for no reason. The Prophet \uFDFA said: 'Indeed Allah is Jawad and He loves generosity.' And: 'If you were to trust Allah as He should be trusted, He would provide for you just as He provides for the birds \u2014 they leave in the morning empty and return full.' Wahb ibn Munabbih once said to a scholar going around courting kings for money: 'Woe to you \u2014 you go to one who shuts his door, shows you his poverty, and hides his wealth. And all along you leave the One who opens His door day and night, shows you His wealth, and says: Call upon Me, I will answer you.'",
    propheticStory:
        "Al-Wahhab is constantly on the tongues of the Prophets. Ibrahim (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645): 'Our Lord, give us from Yourself a righteous descendant \u2014 You are Al-Wahhab.' Sulayman (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645): 'My Lord, forgive me and grant me a kingdom such as will not belong to anyone after me \u2014 You are Al-Wahhab.' Zakariyya (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) prayed for a child after a lifetime of waiting. All of them called on Al-Wahhab in moments that seemed humanly impossible \u2014 and Allah gave.",
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ',
      transliteration:
          "Rabbana la tuzigh qulubana ba'da idh hadaytana wahab lana min ladunka rahmah, innaka anta'l-Wahhab",
      translation:
          'Our Lord, do not let our hearts deviate after You have guided us. Grant us from Yourself mercy. Indeed, You are Al-Wahhab.',
      source: 'Quran 3:8',
    ),
  ),

  // ─────────────────────────────────────────────
  // 19: AL-HAYY / AL-QAYYUM
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Hayy / Al-Qayyum',
    arabic: 'الْحَيُّ الْقَيُّومُ',
    emotionalContext: [
      'feeling like Allah is distant or not listening',
      'calling out in the middle of the night',
      'feeling completely alone',
      'when everything seems to be falling apart at once',
      'despair',
      "seeking comprehensive help when you don't know where to turn",
      'needing Allah to handle all your affairs',
    ],
    coreTeaching:
        "Al-Hayy is the Ever-Living whose life with all its perfection never began and never ends. His being alive means His knowledge never pauses, His hearing never dulls, His sight never weakens. When you call on Him in the middle of the night, He is not tired. When a billion people call at once, He is not overwhelmed. Al-Qayyum holds everything in place \u2014 if He were to leave for the blink of an eye, it would all fall apart. Every breath you take functions only because He sustains it. The Prophet \uFDFA said to Fatima: \"Do not leave off a morning or evening without saying: Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn.\"",
    propheticStory:
        "Anas ibn Malik said that whenever anything distressed the Prophet \uFDFA, he would say: 'Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth.' He used the most comprehensive names, then appealed to the most encompassing attribute (mercy), then made the most comprehensive request ('rectify all my affairs'). Do not leave me to myself even for the blink of an eye.",
    dua: NameTeachingDua(
      arabic:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      transliteration:
          "Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn",
      translation:
          'O Ever-Living, O Self-Sustaining, in Your mercy I seek help. Rectify all my affairs and do not leave me to myself even for the blink of an eye.',
      source:
          "Al-Hakim \u2014 taught by the Prophet \uFDFA to his daughter Fatima for morning and evening",
    ),
  ),

  // ─────────────────────────────────────────────
  // 20: AS-SAMAD — The Eternal Refuge
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'As-Samad',
    arabic: 'الصَّمَدُ',
    emotionalContext: [
      'emptiness inside',
      'feeling like nothing satisfies',
      'craving that nothing fills',
      'addiction or attachment to worldly things',
      'restlessness despite having everything',
      'existential emptiness',
      'searching for something you cannot name',
    ],
    coreTeaching:
        "As-Samad is at the heart of Surah Al-Ikhlas, a complete mystery to most Muslims. As-Samad does not need what needers need \u2014 and nothing is like Him or possible without Him. You were made to feel empty so that you would run back to As-Samad, the Fulfilling One, because everything other than Him leaves you feeling unfulfilled. Your emptiness is not a failure \u2014 it is a map back to the One who fills. Everything you've clung to was a finger pointing at As-Samad.",
    propheticStory:
        "The Prophet Musa (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) had everything in Pharaoh's palace \u2014 power, wealth, certainty. Yet something in him was always restless, always reaching. Ibn al-Qayyim wrote that the soul that does not know As-Samad will grasp at everything \u2014 power, status, approval \u2014 and still feel hollow. When Musa finally said 'Rabbi inni limaa anzalta ilayya min khayrin faqeer \u2014 My Lord, I am in need of whatever good You send down to me,' he had nothing. And in that moment of acknowledged emptiness before As-Samad, everything came.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ يَا صَمَدُ اجْعَلْنِي غَنِيًّا بِكَ عَنْ سِوَاكَ',
      transliteration:
          "Allahumma ya Samad, ij'alni ghaniyyan bika 'an siwak",
      translation:
          'O Allah, O Eternal Refuge, make me needless of all others through You.',
      source:
          'Derived from the teaching of As-Samad in the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 21: AL-WALI — The Protecting Friend
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wali',
    arabic: 'الْوَلِيُّ',
    emotionalContext: [
      'loneliness in a crowd',
      'feeling like no one truly has your back',
      'grief after losing someone',
      'being a stranger in a new place',
      'feeling abandoned',
      'fear of being alone',
      'loss of a close friend or mentor',
    ],
    coreTeaching:
        "Al-Wali is your Protecting Friend and Constant Companion \u2014 the One who never leaves. As Ibn Taymiyyah said: 'Even your shadow leaves you in the dark, but the One who created that shadow remains.' The dua of travel \u2014 'O Allah, You are my companion in travel' \u2014 was extended by scholars to life itself: 'O Allah, You are my companion on this journey of life as a whole.' The Prophet \uFDFA said: 'Be in this world as if you're a stranger or a wayfarer.' Your only consistent companion is the One who created every single step.",
    propheticStory:
        "Hajar (\u0639\u0644\u064A\u0647\u0627 \u0627\u0644\u0633\u0644\u0627\u0645) was left in the valley of Makkah with her infant, no water, no companion but Al-Wali. She ran between Safa and Marwa seven times in desperation. Not once does the Quran say she lost hope. Water burst from beneath her child's feet. The Prophet \uFDFA said: 'May Allah have mercy on the mother of Isma'il \u2014 had she left the water to flow freely, it would have been a flowing river.' From the most extreme loneliness came Zamzam, which still flows today.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ',
      transliteration:
          "Allahumma anta's-sahibu fi's-safar wa'l-khalifatu fi'l-ahl",
      translation:
          'O Allah, You are my companion in travel and the guardian over my family.',
      source:
          'Muslim \u2014 Dua al-Safar, extended by scholars to mean the journey of life',
    ),
  ),

  // ─────────────────────────────────────────────
  // 22: AL-'ALI / AL-'AZIM / AL-MAJID
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-'Ali / Al-'Azim / Al-Majid",
    arabic: 'الْعَلِيُّ الْعَظِيمُ الْمَجِيدُ',
    emotionalContext: [
      'feeling small and insignificant',
      'being humiliated',
      'struggling with ego',
      'feeling crushed by the weight of the world',
      'comparison and inadequacy',
      'arrogance needing to be checked',
    ],
    coreTeaching:
        "Imam al-Ghazali said: 'And every great thing compared to Him is small.' In salah, you stand before Al-Kabir, bow to Al-'Azim, fall before Al-A'la, and rise with Al-Majid. Whoever does not magnify Allah will inevitably magnify something else. You bend your back not to the world's weight, but to the One who carries all its weight. The scholars say He divided the day between your needs and your meeting with Him so you never pass a day without a portion of the divine.",
    propheticStory:
        "When Surah Al-A'la was revealed \u2014 'Glorify the Name of your Lord, the Most High' \u2014 the Prophet \uFDFA said: 'Make this in your sujud.' In our deepest prostration, forehead pressed to the earth, we call upon Al-A'la. The moment you are physically at your lowest is the moment you declare His highest. The one who is humbled before Al-'Azim is honored; the one who is humbled before people loses both worlds.",
    dua: NameTeachingDua(
      arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      transliteration: "Subhana Rabbiyal 'Azeem",
      translation: 'Glory be to my Lord, the Most Magnificent.',
      source:
          "Said in ruku' \u2014 instructed by the Prophet \uFDFA when this verse was revealed",
    ),
  ),

  // ─────────────────────────────────────────────
  // 23: AS-SALAM / AL-QUDDUS
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'As-Salam / Al-Quddus',
    arabic: 'السَّلَامُ الْقُدُّوسُ',
    emotionalContext: [
      "anxiety that won't go away",
      'internal restlessness despite outward calm',
      'trauma',
      'feeling like peace is impossible',
      'after a major crisis but wound remains',
      'PTSD or emotional aftermath',
      'witnessing tragedy',
    ],
    coreTeaching:
        "As-Salam is not just the name for peace \u2014 He is peace Himself. Al-Quddus is utterly pure, free from every imperfection. The scholars say peace comes from three things: from knowing Him in His perfection, from trusting His perfect plan, and from remembering His perfect reward. Ibn al-Jawzi said Allah called Palestine al-Ard al-Muqaddasa, the Holy Land, because of its connection to As-Salam \u2014 the land of prophets and peace even in its most turbulent moments.",
    propheticStory:
        "After every prayer, the Prophet \uFDFA would say three times: 'Astaghfirullah' \u2014 and then: 'Allahumma anta's-Salam wa minka's-salam, tabarakta ya Dhal Jalali wa'l-Ikram.' This dua acknowledges that true peace doesn't come from circumstances being resolved \u2014 it comes from turning toward the Source of peace Himself.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration:
          "Allahumma anta's-Salamu wa minka's-salamu tabarakta ya Dhal Jalali wa'l-Ikram",
      translation:
          'O Allah, You are As-Salam and from You comes all peace. Blessed are You, O Possessor of Majesty and Honor.',
      source:
          "Muslim \u2014 said by the Prophet \uFDFA after every obligatory prayer",
    ),
  ),

  // ─────────────────────────────────────────────
  // 24: AL-QAWI / AL-MATIN
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Qawi / Al-Matin',
    arabic: 'الْقَوِيُّ الْمَتِينُ',
    emotionalContext: [
      'exhaustion and burnout',
      'feeling weak after a long struggle',
      'being oppressed',
      'feeling powerless against injustice',
      'wanting to give up',
      'physical or emotional weakness',
      'needing strength to continue',
    ],
    coreTeaching:
        "Al-Qawi is the Powerful \u2014 but the Prophet \uFDFA redefined strength: 'The strong one is not the one who overcomes others physically. The strong one is the one who controls himself in a fit of anger.' True strength is spiritual self-mastery. Al-Matin means the Firm \u2014 His power never tires. Above the throne is written: 'My mercy overcomes My anger.' Between the mercy above and the strength beneath, you learn what true power is: it is yielding to the One who holds the throne.",
    propheticStory:
        "The Prophet \uFDFA said: 'Shall I not teach you a word that is a treasure from beneath the throne?' Then: 'La hawla wa la quwwata illa billah \u2014 there is no power and no strength except through Allah.' The Prophet Ayyub (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) \u2014 after years of sickness and loss \u2014 received his strength not by denying weakness, but by acknowledging that only Al-Qawi could restore him.",
    dua: NameTeachingDua(
      arabic:
          'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      transliteration:
          "La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem",
      translation:
          'There is no power and no strength except through Allah, the Most High, the Most Magnificent.',
      source:
          "Bukhari and Muslim \u2014 described by the Prophet \uFDFA as a treasure from beneath Allah's throne",
    ),
  ),

  // ─────────────────────────────────────────────
  // 25: AL-'ALI / AL-MUTA'ALI
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-'Ali / Al-Muta'ali",
    arabic: 'الْعَلِيُّ الْمُتَعَالِي',
    emotionalContext: [
      'being humiliated',
      'reputation attacked',
      'feeling small compared to others',
      'pride wounded',
      'struggling with ego and comparison',
      'resentment at being looked down on',
      'needing to rise above pettiness',
    ],
    coreTeaching:
        "Al-Ali is elevated above all creation in His essence, attributes, and dominance. Al-Muta'ali is not just the Most High in rank but absolutely above and beyond all limitations \u2014 exalted not only above, but beyond likeness, beyond limits, beyond any frame. The scholars say Al-Ali is dominant over what you see; Al-Muta'ali is dominant even over what you can't see. Every human claim to divine elevation is just a passing mirage of arrogance bound to tragically collapse. \"Whoever humbles himself for Allah, Allah exalts him. Whoever exalts himself, Allah lowers him.\" When you feel crushed, forgotten, or trampled \u2014 remember Al-Ali. He is not scrambling down here with you. He is above it all, seeing what you can't see and holding what you can't hold.",
    propheticStory:
        "When Surah Al-A'la was revealed \u2014 'Glorify the Name of your Lord, the Most High' \u2014 the Prophet \uFDFA said: 'Make this in your sujud.' The divine wisdom: the moment you are physically at your lowest \u2014 forehead pressed to earth \u2014 you declare His highest. The scholars note: the one who is humbled before Al-'Ali is honored; the one who is humbled before people loses both worlds. And as-Sabur gives you patience for all times. Al-Halim is patient with you. Al-Ali controls from above all that you see and can't see. Al-Muta'ali reigns supreme over what you can't even imagine. Trust His vantage point.",
    dua: NameTeachingDua(
      arabic:
          'يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ',
      transliteration:
          "Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar",
      translation:
          'O The Exalted, O The Supremely Exalted, raise my heart above resentment and smallness.',
      source:
          'Derived from the closing dua of Ep. 24 of the Dua I Need series',
    ),
  ),

  // ─────────────────────────────────────────────
  // 26: AL-DHAHIR & AL-BATIN
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 9
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Dhahir & Al-Batin',
    arabic: 'الظَّاهِرُ الْبَاطِنُ',
    emotionalContext: [
      'feel like allah is absent from my life',
      "can't see allah anywhere",
      'feel spiritually disconnected',
      'going through the motions externally but hollow inside',
      'life feels meaningless',
      'only focused on appearances',
      'heart feels dirty or cluttered',
      'holding on to hidden resentment or hatred',
      "feel like allah doesn't see what i'm going through",
      "can't find meaning in daily life",
      'feel like the mundane has no connection to god',
      'wonder if god is really there',
    ],
    coreTeaching:
        "Al-Dhahir means the Manifest \u2014 what is visible, clear, above all things. Al-Batin means the Hidden \u2014 the innermost, the deepest reality underneath everything. How can Allah be both? Imam Al-Ghazali explains: He is so manifest, so utterly present everywhere, that He becomes hidden to most people \u2014 like air. You don't notice it until you can't breathe. Al-Dhahir means everywhere you look in creation there are signs pointing back to Him. Al-Batin means the deeper you go into anything \u2014 into a cell under a microscope, into the stages of a child's development, into the hidden workings of your own life \u2014 the more you find Him. The problem is we look with our eyes and say 'where is Allah?' The Quran says: it's not the eyes that are blind, it's hearts that are blind. When you develop basirah \u2014 sight of the heart \u2014 you begin to see Him in everything. And knowing Al-Batin transforms your inner life: it means He is closer to you than yourself. You don't even have to articulate your pain. When you're on the prayer rug and the words won't come, just sit \u2014 because Al-Batin means He already knows what's inside. The practical implication: since He sees the internal and not just the external, you must tend to your inner state. Clean the heart of hatred, jealousy, and resentment before sleep. That was the single hidden deed of the man the Prophet \uFDFA pointed to as a person of Jannah \u2014 not extra tahajjud, not extra fasts. He didn't go to sleep with hatred for any person in his heart.",
    propheticStory:
        "Abdullah ibn Amr sat in a gathering when the Prophet \uFDFA pointed to the door and said: 'The next man who walks in is a man of Jannah.' A simple, unremarkable man walked in carrying his sandals, water still dripping from wudu. This happened three days in a row. Abdullah was so curious he asked to stay at the man's home for three days \u2014 and saw nothing extraordinary. Same prayers as every other Sahabi, nothing more. Before leaving, he confessed he had no family dispute \u2014 he just needed to see what made this man a person of Jannah. The man said: 'That's everything you saw. Except one thing you didn't see: I never go to sleep without cleaning my heart of any hatred toward any person.' That was it. Al-Batin demands inner work invisible to everyone else. The Prophet \uFDFA also taught a bedtime dua that pairs Al-Dhahir and Al-Batin directly: 'You are the First, nothing before You. You are the Last, nothing after You. You are Al-Dhahir \u2014 nothing above You. You are Al-Batin \u2014 nothing closer to me.' He then asked Allah to pay off his debts and protect him from poverty.",
    dua: NameTeachingDua(
      arabic:
          'أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ',
      transliteration:
          "Anta al-Dhahiru fa-laysa fawqaka shay', wa anta al-Batinu fa-laysa dunaka shay'",
      translation:
          "You are Al-Dhahir \u2014 there is nothing above You. You are Al-Batin \u2014 there is nothing closer to me than You.",
      source:
          "Sahih Muslim 2713 \u2014 part of the bedtime dua the Prophet \uFDFA taught, pairing Al-Dhahir and Al-Batin",
    ),
  ),

  // ─────────────────────────────────────────────
  // 27: AL-GHANI — The Self-Sufficient, The Enricher
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 10
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Ghani',
    arabic: 'الْغَنِيُّ',
    emotionalContext: [
      'feel empty inside',
      'have everything but still not satisfied',
      'chasing the next thing',
      "void that can't be filled",
      'addicted to things',
      'filling emptiness with relationships',
      'shopping or spending to feel better',
      "career not giving me what I thought it would",
      "feel like I'm missing something",
      'always wanting more',
      'restless despite blessings',
      'looking for completion in people',
    ],
    coreTeaching:
        "Al-Ghani means the Self-Sufficient \u2014 the One who needs nothing outside of Himself. And we are the opposite: faqir, utterly dependent on Him in every moment. The verse says: 'O people, you are the ones in need of Allah, and Allah is Al-Ghani.' Ibn Ata'illah said: 'Your greatest moment is the moment you are witnessing your need of God.' Not when you get the job, the marriage, the degree. The greatest moment is when you realize I need Him and turn to Him. The void is real. Ibn al-Jawzi said: 'In the heart there is a void that cannot be filled except by His love, turning to Him, always remembering Him, and being sincere to Him. Were a person given the entire world and everything in it, it would never fill the void.' We keep running to the creation \u2014 the next job, the next relationship, the next purchase, the next degree \u2014 to fill something that only Al-Ghani can fill. And Shaytan knows this. The narration says he inspected Adam before the soul was blown in and said: 'This creation is hollow inside. I know how to get him lost \u2014 I'll make him greedy for more.' True richness isn't having a lot. The Prophet \uFDFA said: 'Richness is not having many things \u2014 true richness is finding richness within yourself.' A man who always wants more is a poor man, no matter how much he has. The dua the Prophet \uFDFA would make: 'O Allah, enrich me with Your bounty so that I don't need anyone but You.'",
    propheticStory:
        "Zakariah (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) walked into Maryam's chamber and found fruit out of season. He asked: 'Where did this come from?' She said: 'It is from Allah \u2014 He provides for whom He wills without reckoning.' In that moment, Zakariah saw his need clearly. He didn't run to a doctor or a plan. He said: 'Ya Allah, I need a child.' He witnessed his faqr \u2014 his utter dependence \u2014 and turned it directly to Al-Ghani. Sheikh Mikaeel reflects: 'I remember the moment I first converted, holding a cigarette and asking: what are you actually trying to get from this? And in that moment I realized \u2014 everything I'd been chasing, the drugs, the jumping from person to person, the shopping \u2014 all of it was trying to fill a void. That void wasn't going to be filled by any of it. The void only fills when you turn to Him.' Ibn Ata'illah also said: 'Sins that cause you to feel low and in need of Allah are better than worship that causes you to feel arrogant.' Your addiction, your brokenness, your emptiness \u2014 if it drives you to your knees before Al-Ghani, it is your gateway to closeness with God.",
    dua: NameTeachingDua(
      arabic: 'اللَّهُمَّ أَغْنِنِي بِفَضْلِكَ عَمَّن سِوَاكَ',
      transliteration: 'Allahumma aghnini bifadlika amman siwak',
      translation:
          'O Allah, enrich me with Your bounty so that I need no one but You.',
      source:
          'Prophetic supplication calling on Al-Ghani \u2014 used when feeling empty, dependent on creation, or chasing completion in the wrong places',
    ),
  ),

  // ─────────────────────────────────────────────
  // 28: AL-MU'IZZ & AL-MUDHIL
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 11
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-Mu'izz & Al-Mudhil",
    arabic: 'الْمُعِزُّ الْمُذِلُّ',
    emotionalContext: [
      'chasing approval from people',
      'compromising deen for status',
      'feel like I have to give up my values to get ahead',
      'seeking honor from a job or boss',
      'feel disrespected or looked down on',
      'sacrificing prayers or Islam for career',
      'feel like my Islam is holding me back',
      'worried about what people think',
      'people-pleasing',
      'feel humiliated',
      'giving up my identity for acceptance',
      'career pressure to fit in',
    ],
    coreTeaching:
        "Al-Mu'izz is the One who gives honor (izza). Al-Mudhil is the One who debases (dhilla). Both names must be understood together \u2014 Allah's names include jalal (might and awe) alongside jamal (beauty and mercy), and without knowing both, your iman loses balance. The core lesson: all honor belongs only to Allah. 'Whoever desires honor \u2014 all honor belongs to Allah.' If you don't know that Allah is Al-Mu'izz, you will spend your entire life searching for izza in degrees, careers, relationships, status \u2014 and never find it. You are a free person from anything you don't put your hopes in, but a slave of everything you have greed for. Umar's statement captures it: 'We were a debased people. Allah gave us honor through Islam. If we seek honor through anything else, we'll be debased again.' The debasement happens gradually \u2014 once you sell out once, the only question left is your price. The antidote: ask yourself at every decision point, 'Am I sacrificing Allah, or am I sacrificing for Allah?' True izza often looks like humiliation from the outside \u2014 Ahmad ibn Hanbal was flogged 80 times publicly, yet his name is honored by billions for 1,200 years. Honor is not in the moment. Honor is what Allah leaves of your name behind you.",
    propheticStory:
        "After ten years of preaching in Mecca with no protection, the Prophet \uFDFA walked 80 kilometers to Ta'if alone, hoping for support. The leaders of Ta'if mocked him, spoke to him with contempt, and then lined up the city's thugs to stone him out \u2014 specifically aiming at his ankles so the rocks would hit bone. Every time he fell, they lifted him up to keep walking. He collapsed outside the city, bleeding. He made dua: 'O Allah, I complain to you of my weakness. But if You are not angry with me, I don't care about any of this.' Weeks later, Allah took him on the Night Journey through the seven heavens \u2014 straight to the divine presence. When the people of the earth will not honor you, Allah will honor you Himself. Uwais al-Qarni chose to stay back and care for his mother instead of traveling to meet the Prophet \u2014 he never became a Sahabi. Yet Omar ibn al-Khattab, the Khalifa, would stand at the edge of Mecca waiting for the Yemeni caravans just to find this unknown man \u2014 because the Prophet had told him: when you find him, ask him to make dua for you. True izza is found in the darkness of the night on the prayer rug, not in the light of day in front of people.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ',
      transliteration:
          "Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik",
      translation:
          'O Allah, honor me through obedience to You, and do not humiliate me through disobedience to You.',
      source:
          'Traditional supplication based on the teaching that izza lies exclusively in obedience to Allah',
    ),
  ),

  // ─────────────────────────────────────────────
  // 29: AL-JABBAR — The Compeller, The Mender
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 14
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Jabbar',
    arabic: 'الْجَبَّارُ',
    emotionalContext: [
      'broken heart',
      'feel shattered inside',
      "something feels wrong but I don't know what",
      'emotionally broken',
      'spiritually broken',
      'sick with no diagnosis',
      'financially desperate',
      'being controlled or forced by someone',
      'trying to control or fix others',
      'feel like no one can help me',
      "doctors have no answers",
      "anxiety or depression I can't explain",
    ],
    coreTeaching:
        "Al-Jabbar has three interlocking meanings. The first: the Compeller \u2014 the One whose will is never held back. If the entire world gathered to harm you in a way Allah has not written, they could not harm you in the least. This includes black magic, oppressive bosses, controlling family members \u2014 none of them are the true compeller. Only Allah is. The second meaning: the One who mends what is broken. In Arabic, a cast for a broken bone is called jabira \u2014 from the same root. Al-Jabbar is the one who sets right broken bones, broken hearts, broken minds, broken finances, broken spirits. The Prophet \uFDFA used to say between the two sajdahs: 'O Allah, forgive me, guide me, set me right.' Every room is full of broken people. Some know how they're broken. Some just know something's wrong. Both turn to Al-Jabbar. The third meaning: to set something right with a little force \u2014 like a dislocated shoulder snapped back into place. Your depression, your anxiety, your illness, your financial struggle \u2014 these are your personal invitation to Al-Jabbar. The very brokenness is by design. Without it, this name cannot be witnessed. And the one who cannot see their own brokenness? That is the deepest brokenness of all. The lesson for us: never become jabbar with others. You cannot compel people to goodness. You can only draw them through the beauty of your character.",
    propheticStory:
        "The Prophet \uFDFA received the first revelation and ran down the mountain shaking, terrified. He went straight to Khadijah. She did not say 'be strong.' She said with force: 'Kalla \u2014 no way. Allah will never humiliate you. You bring families together, help people in hardship, honor guests.' She set him right. She was jabbar for him in that moment. The Prophet \uFDFA also told Ibn Abbas: 'If the entire world gathered to harm you in a way Allah has not written, they could not harm you in the least bit. And if the entire world gathered to benefit you in a way Allah has not written, they could not benefit you.' No boss, no relative, no enemy \u2014 none hold a deed that Al-Jabbar has not already authored. And the Prophet \uFDFA himself, in every salah between the two prostrations, made dua: 'O Allah, forgive me, guide me, set me right' \u2014 even the most perfect human being saw in himself something to be mended by Al-Jabbar.",
    dua: NameTeachingDua(
      arabic: 'رَبِّ اجْبُرْنِي وَاجْبُرْ قَلْبِي',
      transliteration: 'Rabbi ujburni wa ujbur qalbi',
      translation: 'My Lord, mend me and mend my heart.',
      source:
          'Supplication calling on Al-Jabbar \u2014 used when broken in body, heart, or spirit and seeking divine restoration',
    ),
  ),

  // ─────────────────────────────────────────────
  // 30: AN-NASIR — The Helper
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 18
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'An-Nasir',
    arabic: 'النَّصِيرُ',
    emotionalContext: [
      "feeling overpowered and helpless",
      "stuck and can't find a way out",
      'too proud to ask for help',
      "struggling with addiction I can't break",
      "doing everything myself but it's not working",
      'self-sufficiency mentality blocking me',
      'turned to people for help but they let me down',
      "financial situation I can't escape",
      'feel too weak to keep going',
      'overwhelmed by responsibility',
      "don't know where to turn",
      "waiting for things to change but nothing moves",
    ],
    coreTeaching:
        "An-Nasir is the One who is perpetually, continuously helping. The problem this name addresses is one most of us carry without realizing it: self-sufficiency. We were raised to handle things ourselves, to not burden others, to grind through. But the Prophet \uFDFA taught us to ask Allah even for salt when it runs out. Not because Allah needs the small things \u2014 but because when even something as trivial as salt sends you to Allah first, your relationship with Him is ironclad. What's small? What's big? For Allah, everything is between the letters kaf and nun \u2014 He says 'Be' and it is. We've created categories that don't exist for Him. The scholars say this name especially helps against the two enemies always with us: the nafs (the inner child that wants instant gratification) and Shaytan. If you think your addiction is too big for Allah, you have belittled His power. That addiction is the same as needing milk. No difference. There are five conditions for the help of Allah to arrive: (1) A deep realization that you need Him \u2014 the moment you thought you had it handled at Hunayn, you started to lose. (2) Deep iman that the help is coming. (3) Preparation \u2014 trust in Allah never means passivity. Tie your camel. Apply for the job. Call the therapist. (4) Go help someone else \u2014 whoever removes a hardship from a believer, Allah removes theirs on the Day of Judgment. When you're in need, that's precisely the time to look around for who else needs help. (5) Patience \u2014 the help comes on Allah's timeline, not yours. The poet Rumi said: crying out loud and weeping are great resources. A nursing mother only waits to hear her child's cry. Allah created the child that is your wanting \u2014 so that you might cry out, so that milk might come.",
    propheticStory:
        "At the Battle of Badr, the Prophet \uFDFA stood in his tent the night before, arms raised so high in supplication that his shawl fell from his shoulders, begging Allah for what He had promised. Abu Bakr came and wrapped the shawl around him and said: 'That's enough, ya Rasulallah \u2014 you will be given what was promised.' That moment of total need, total vulnerability before Allah, is what an-Nasir responds to. Years later, when 12,000 Muslims marched out at Hunayn \u2014 the largest army Islam had ever assembled \u2014 someone said: 'We can never lose today.' They had shifted their eyes from Allah to their numbers. They began to lose. The help of Allah retreats the moment we stop seeing our need of Him. There was also a man named Buraydah who came to capture the Prophet \uFDFA with seventy armed men, a bounty of 100 camels on his head. The Prophet asked his name. Buraydah. His tribe? Aslam \u2014 meaning 'peace.' The Prophet looked at Abu Bakr and smiled: 'We're safe.' He then gave him da'wah, and Buraydah and all seventy accepted Islam on the spot. Help comes from every direction \u2014 even your enemies can become your greatest allies \u2014 because hearts are in the hands of Allah.",
    dua: NameTeachingDua(
      arabic:
          'حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ، نِعْمَ الْمَوْلَى وَنِعْمَ النَّصِيرُ',
      transliteration:
          "Hasbiyallahu wa ni'mal-wakil, ni'mal-mawla wa ni'man-nasir",
      translation:
          'Allah is sufficient for me and He is the best Disposer of affairs. What an excellent Protector and what an excellent Helper.',
      source:
          'Quran 3:173 and 8:40 \u2014 combined into one supplication of complete reliance on Allah',
    ),
  ),

  // ─────────────────────────────────────────────
  // 31: AR-RABB — The Lord, The Nurturer (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 19
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Ar-Rabb',
    arabic: 'الرَّبُّ',
    emotionalContext: [
      'scared about the future',
      'going through a big transition',
      'between jobs',
      "waiting for something that hasn't come yet",
      'feel like no one is looking out for me',
      "don't know what's next",
      'feel abandoned in a hard season',
      'worried about losing what I have',
      'feel like I have to figure it all out myself',
      "can't see how it will work out",
      "feel like I'm on my own",
      "everything changed and I'm not ready",
    ],
    coreTeaching:
        "Ar-Rabb has three dimensions. First: the Nurturer \u2014 the one who takes you from one stage to the next stage to the next, constantly making you better, refining you, bringing you toward your full potential. Second: the Sustainer \u2014 the one who keeps you going in the state you're already in. Third: the Owner \u2014 the one who has full possession of everything you are and everything you have. None of it is yours. You are 'abd, and He is Rabb. The moment you internalize this third dimension, loss transforms. Abu Talha's wife, when their son died while he was away, asked him: 'If someone gave you something on loan and then asked for it back, did they wrong you?' He said no. She said: 'Allah has taken our son back.' That is the station of the one who truly knows Ar-Rabb. The highest level of worship, Ibn al-Jawzi says, is to recognize yourself as a slave and servant of Allah \u2014 and you can only reach that when you know He is Rabb. But the practical entry point is this: look back at your life. Has He ever not taken you from one stage to the next? If He brought you here, He will take you forward. The transition you're in right now is not abandonment \u2014 it is nurturing.",
    propheticStory:
        "Moses was traveling with his family \u2014 not expecting anything \u2014 when Allah called him at the burning bush and gave him the most terrifying assignment: go to Pharaoh. Moses was overwhelmed. He made a long dua: expand my chest, ease my task, remove the impediment in my tongue, give me my brother as a helper. Allah responded: 'You are given what you asked. And don't forget \u2014 I have blessed you before.' He then walked Moses through every stage: I inspired your mother to place you in a basket on the river. I ensured your enemy brought you into his own home to raise you. I was nurturing you the whole time \u2014 even through Pharaoh. When Pharaoh himself later tried to use this against Moses \u2014 'Didn't I nurture you?' \u2014 Moses could say: 'No. Allah nurtured me by placing you in my life.' The people who raised you, shaped you, even the difficult ones \u2014 none of them were your true Rabb. Allah was using them. The Prophet \uFDFA himself went from loss to loss in his early years \u2014 father before birth, mother at six, grandfather at eight \u2014 and yet the very first revelation began: 'Recite in the name of your Rabb.' The first thing Allah needed him to know was: I have been your nurturer this whole time.",
    dua: NameTeachingDua(
      arabic: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
      transliteration: 'Rabbi ishrah li sadri wa yassir li amri',
      translation:
          'My Lord, expand my chest for me and ease my affairs.',
      source:
          "Quran 20:25-26 \u2014 the dua of Moses when given an overwhelming task, calling on Ar-Rabb specifically",
    ),
  ),

  // ─────────────────────────────────────────────
  // 32: AR-RAZZAQ — The Provider
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 21
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Ar-Razzaq',
    arabic: 'الرَّزَّاقُ',
    emotionalContext: [
      'anxious about money',
      'worried about provision',
      'lost my job',
      'scared about the future financially',
      'feel like i have to figure out my finances alone',
      "scared i won't have enough",
      "jealous of others' wealth or success",
      'feel like my boss or company controls my future',
      'scarcity mindset',
      "can't trust that things will work out",
      'grinding but still not enough',
      "feel like i'm the one providing for everyone",
    ],
    coreTeaching:
        "Ar-Razzaq is the only one who controls your provision (rizq). Not your boss, not your company, not the economy \u2014 no one can give you what Allah has not decreed, and no one can take away what He has written for you. This name removes the anxiety of provision at its root. The Prophet \uFDFA said: 'Wretched is the slave of the dollar and the dinar' \u2014 the problem is not having wealth, it's when wealth has you. Two types of rizq: material (money, food, health) and spiritual (contentment, trust in Allah, sweetness of ibada, knowledge of God). Many chase the material and get it \u2014 but still find no peace, because what they actually needed was the spiritual rizq underneath it. The scholar says: Al-Razzaq chose the wealthy and gave them provision. But those without, in that moment He gave them something greater \u2014 witnessing who the Provider actually is. The secret to increasing rizq: become a river, not a dam. Give generously, and Allah's blessings flow through you. Abdul Rahman ibn Awf gave the equivalent of a quarter billion dollars in charity in his lifetime \u2014 and died with the equivalent of a billion still in his estate. That's the arithmetic of Ar-Razzaq.",
    propheticStory:
        "Moses fled Egypt with nothing \u2014 a fugitive, no family, no wealth, no destination. He arrived at a well in Madyan and found two women unable to water their flock because the men had crowded them out. He had nothing to give but help, so he helped. Then he sat under a tree and made dua: 'Ya Allah, I am in need. I am in need.' Hours later, one of the women came back: 'My father is calling you.' The father cut straight to it: 'I want you to marry one of my daughters.' Moses had arrived with nothing. Within a short time he had a job, a wife, a home, and a path back to his family. The formula: give whatever you have, trust Ar-Razzaq for the rest. Hagar modeled the same \u2014 when Ibrahim left her in the desert, her motherly anxiety kicked in and she ran between Safa and Marwa looking for people, because people signify rizq. But Allah provided from below \u2014 from where she wasn't looking. She still ran. The lesson: your running doesn't cause Zamzam to flow. Your running shows Allah: I'll do whatever I can. I know You are the Provider.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
      transliteration:
          "Allahumma-kfini bihalалика 'an haramika wa aghнini bifadlika 'amman siwak",
      translation:
          "O Allah, suffice me with what You have made lawful, sparing me from what You have made unlawful, and enrich me with Your bounty so that I need no one but You.",
      source:
          "Jami' at-Tirmidhi 3563 \u2014 a supplication for provision that removes dependence on people",
    ),
  ),

  // ─────────────────────────────────────────────
  // 33: AL-QARIB / AL-MUJIB (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 16
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Qarib / Al-Mujib',
    arabic: 'الْقَرِيبُ الْمُجِيبُ',
    emotionalContext: [
      'feeling far from Allah',
      'feel like my sins have pushed me away from Allah',
      "don't feel worthy to make dua",
      "feel like Allah doesn't hear me",
      'lonely and disconnected',
      'feel like no one truly understands me',
      'afraid to ask Allah for things',
      'stopped making dua',
      'dua feels unanswered',
      'struggling with sins and feel distant from God',
      'going through something difficult and feel alone',
      "can't find closeness to Allah no matter what I do",
    ],
    coreTeaching:
        "Al-Qarib means the Closest \u2014 not close the way a friend is close, but closer than your jugular vein. Allah says in the Quran: 'When My servant asks about Me \u2014 I am near.' Not 'tell them I am near.' I am near. The response is direct and immediate. We spend our lives searching for closeness: in status, in relationships, in achievements \u2014 looking far for what was never far away. The soul is from Allah and it desires Allah. But our preoccupation with the dunya has locked the soul into things that cannot hold it. The beautiful reality: Allah is the constant. You're the one who moves. The moment you turn back, He is right there. He didn't go anywhere. Al-Mujib means the One who answers every call \u2014 and these two names are inseparable in the Quran. Once you truly feel how close Allah is, talking to Him becomes natural. You don't need formal Arabic, you don't need to be in wudu, you don't even need to move your tongue. The heart makes dua. A man on a plane once made a wordless dua in his heart \u2014 15 years later he was in the masjid he had prayed for without speaking a word. Allah's love language is to be asked. The more you ask, the more He loves. Don't wait for hard times \u2014 talk to Him when things are good too. Increase the frequency, the breadth, and the depth: bring the small things (the salt that ran out), and bring the deep things (the broken relationship, the hidden pain). Don't be too shy to ask. He only put the dua in your heart because He wanted to give.",
    propheticStory:
        "The Prophet Yunus (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) left his people before Allah gave him permission. He boarded a ship, a storm arose, and lots were drawn \u2014 his name came up every time. He was thrown into the sea and swallowed by the whale. Three layers of darkness: the night, the ocean, the belly of the whale. Scholars say the angels heard his call coming from that deep dark place and recognized the voice \u2014 this is the one who used to call on Allah in the times of ease. They brought his dua before Allah. Allah said: 'Answer him. Of course I will.' The hadith says: remember Allah in ease and He will remember you in hardship. No matter what sin placed you in your dark place \u2014 He is still just as close. Shaitan will tell you your sins have pushed you too far. They haven't. Yunus was in the darkest place a human can be, and Al-Qarib was still right there. He just had to call.",
    dua: NameTeachingDua(
      arabic:
          'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      transliteration:
          'La ilaha illa anta subhanaka inni kuntu minaz-zalimin',
      translation:
          'There is no god but You, glory be to You; indeed I have been of the wrongdoers.',
      source:
          "Quran 21:87 \u2014 the dua of Yunus (AS) from the belly of the whale. The Prophet \uFDFA said no Muslim calls with this dua except that Allah responds.",
    ),
  ),

  // ─────────────────────────────────────────────
  // 34: AS-SALAM — The Source of Peace (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 12
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'As-Salam',
    arabic: 'السَّلَامُ',
    emotionalContext: [
      'searching for peace in the wrong places',
      'restless and nothing satisfies',
      'addicted to shopping or substances seeking relief',
      'grinding for money but still empty inside',
      'expecting a person or marriage to complete me',
      'heart feels restless',
      "can't find peace no matter what I do",
      'internal conflict and anxiety',
      'struggling with jealousy, arrogance, or hatred',
      "heart feels flawed and I can't change",
      'no peace at home',
      'everything is fine externally but I feel hollow',
    ],
    coreTeaching:
        "As-Salam has two meanings that together form the complete picture. First: Allah is the Flawless One \u2014 His essence, His attributes, and His plan are free from all fault and error. This is the hardest part to accept: not just that Allah is perfect in Himself, but that His decree for you is perfect too. When the job didn't come through, when the marriage fell apart, when the door closed \u2014 As-Salam was not absent. He was the surgeon cutting through flesh to reach the problem. Ibn al-Qayyim wrote: you will only see Allah's plan as flawless when you truly understand that everything He does for you is good for you. Second: As-Salam is the source of all peace. Not a source \u2014 the source. We search for peace in things (we shop, we acquire, we consume), in people (we expect marriage or friendship to complete us), and in substances (one more hit, one more drink). But the psychologist said it best: seeking peace in what is not Allah is like drinking salt water \u2014 you only get thirstier. The dunya was never called dar al-salam. It is dar al-ibtila \u2014 the house of trial. The only way to carry peace inside the trial is to let As-Salam into the heart. And when you do, He lets you into dar al-salam. This name is also a purifier: scholars say the one who calls on As-Salam repeatedly, Allah purifies them from their own flaws \u2014 stinginess, hatred, jealousy, arrogance. You don't have to muscle through those qualities alone. You call the name.",
    propheticStory:
        "In the seventh year after Hijra, the Prophet \uFDFA dreamed they would perform Umrah. The Sahabah had longed for Mecca since they left it. They put on their ihram and set out full of hope \u2014 only to be stopped at Hudaybiyyah by the Quraysh. The Prophet \uFDFA negotiated a treaty: no Umrah this year, ten years of peace. When he came out of his tent and announced they were turning back, the Sahabah went silent. No one moved. They had been so close. As they shaved their heads in submission, they said it felt like cutting their own throats \u2014 that was the depth of the pain. Umar was beside himself. He came to the Prophet \uFDFA with a string of questions: aren't we on the truth? Aren't they on falsehood? Didn't you say we were going? The Prophet \uFDFA replied gently: 'Did I say this year?' Umar went to Abu Bakr \u2014 same questions, same answer. He couldn't see the wisdom yet. Then a verse was revealed: 'We have given you a clear victory.' What looked like the greatest loss was the opening of Mecca. Every scholar says the true conquest of Mecca began that day at Hudaybiyyah \u2014 in what appeared to be a humiliating retreat. As-Salam's plan had no fault in it. Umar just couldn't see it yet.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration:
          'Allahumma antas-salamu wa minkas-salamu tabarakta ya dhal-jalali wal-ikram',
      translation:
          'O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of majesty and honour.',
      source:
          "Sahih Muslim 591 \u2014 recited by the Prophet \uFDFA after every obligatory prayer",
    ),
  ),

  // ─────────────────────────────────────────────
  // 35: AN-NUR — The Light (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 20
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'An-Nur',
    arabic: 'النُّورُ',
    emotionalContext: [
      'feel spiritually empty',
      'feel like my heart is dark',
      'lost my sense of purpose',
      'confused about my path',
      "anxious and don't know why",
      'feel disconnected from Allah',
      "don't feel Ramadan this year",
      'heart feels hard',
      "can't find clarity",
      "feel like i'm walking in the dark",
      'spiritually dead',
      "don't feel the light i used to feel",
    ],
    coreTeaching:
        "An-Nur means Allah is the only source of all light \u2014 and light here means clarity, guidance, and the ability to see reality as it truly is. Every human being has a light inside them that recognizes God \u2014 that's the fitrah. But that light sits inside a glass (the heart), and that glass gets foggy from sins, heedlessness, and distance from God. The light never leaves. But when the glass is dirty, its radiance can't shine out. Ramadan is the month of rekindling: the fasting removes distractions, the Quran is the oil that feeds the lamp, and the dhikr polishes the glass. The goal isn't just to pray more \u2014 it's to dip the wick into the oil so that you carry that light for months after. Three signs that An-Nur is entering your heart: (1) your heart inclines toward the hereafter instead of chasing dunya; (2) you start to see through the deception of this world; (3) you begin preparing for death \u2014 not morbidly, but with presence, so that every moment with loved ones becomes intentional. On the Day of Judgment the only light that exists is the light you brought from this world. Some will have light shining in front of them; others will have nothing but a flicker. The believers on the dark side will beg to borrow light from those who built it here. So the question is: are you building your light now?",
    propheticStory:
        "Before revelation came, the Prophet \uFDFA knew something was deeply wrong with society and withdrew to the Cave of Hira \u2014 searching for clarity, for God. He already had that flame of fitrah inside him. Then in Ramadan, the angel Jibreel descended with the first verses of the Quran. Aisha described it: 'The truth came to him like the break of dawn.' That oil touched the flame, and the light has not gone out in 1,400 years. The Prophet \uFDFA walking to Fajr in darkness \u2014 that darkness is exactly what gives light on the Day of Judgment. Any act of worship done in the darkness of dunya becomes light in the akhirah. He used to make a long dua on the way to Fajr: 'O Allah, place light in my heart, light in my hearing, light in my sight, light on my right, light on my left, light in front of me, light behind me \u2014 and O Allah, make me light.'",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي لِسَانِي نُورًا وَاجْعَلْنِي نُورًا',
      transliteration:
          "Allahumma-j'al fi qalbi nuran wa fi lisani nuran waj'alni nuran",
      translation:
          'O Allah, place light in my heart, light on my tongue, and make me light.',
      source:
          "Sahih Muslim 763 \u2014 the Prophet's dua on the way to Fajr prayer",
    ),
  ),

  // ─────────────────────────────────────────────
  // 36: AL-'AFUWW — The Pardoner (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 22
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-'Afuww",
    arabic: 'الْعَفُوُّ',
    emotionalContext: [
      'feeling too sinful to approach Allah',
      'stuck on past sins even after repenting',
      "can't forgive myself",
      'shame from the past is holding me back spiritually',
      "don't feel close to Allah after sinning",
      'stopped praying because of guilt',
      'relationship with Allah feels broken',
      "holding a grudge and can't let go",
      'unable to forgive someone who hurt me',
      'feeling spiritually stuck',
      'cringe about past mistakes',
    ],
    coreTeaching:
        "Al-'Afuww is not just the One who forgives \u2014 He is the One who erases. There is a difference. Forgiveness (maghfirah) removes the punishment but the record remains. 'Afw means the sin is wiped away completely, as if it never happened \u2014 like desert wind that blows until no trace of a tent trench remains. Shake Nabulusi says: with maghfirah, next to the sin it says 'no punishment.' With 'afw, the sin isn't even there anymore. This is why you must stop holding your repented sins in front of you. Allah already let go. You haven't. The name has a second meaning: it means extra \u2014 to give more than what was asked. Like a friend who doesn't just return your mug clean, but returns it filled with fresh coffee. When you call on Al-'Afuww, you aren't just asking Him to clean your cup. You're asking Him to fill it. Add tawbah to my heart. Add serenity. Add love in my family. This is why the Prophet \uFDFA, when asked what to say on Laylat al-Qadr \u2014 the night worth 80 years of worship \u2014 taught this single dua: 'Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni.' Not a dua for wealth, health, or paradise \u2014 a dua for the slate to be wiped and the cup to be filled.",
    propheticStory:
        "When the verse about Al-'Afuww was revealed, it came in response to Abu Bakr al-Siddiq. He had been financially supporting his cousin Mista every month \u2014 a pure act of generosity. But Mista was among those who spread the slander against Abu Bakr's daughter, Aisha (RA). When Abu Bakr found out, he swore he would cut off the stipend. Allah revealed: 'Let them pardon and overlook. Do you not want Allah to forgive you?' Abu Bakr understood immediately. He didn't just reinstate the stipend \u2014 he doubled it. That is 'afw: not just returning the relationship to where it was, but going beyond it. And this is the model of Yusuf (AS) \u2014 when his brothers, who had thrown him in a well and sold him into slavery, stood before him in his moment of power, he said: 'No blame on you today.' When he later spoke to his father, he mentioned being taken 'from prison' as the start of his hardship \u2014 not the well \u2014 because his brothers were standing right there. He had already forgiven them so completely that he would not even bring it up.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
      transliteration:
          "Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni",
      translation:
          'O Allah, You are the Pardoner, You love to pardon, so pardon me.',
      source:
          "Jami' at-Tirmidhi 3513 \u2014 the dua the Prophet \uFDFA taught Aisha to say on Laylat al-Qadr",
    ),
  ),

  // ─────────────────────────────────────────────
  // 37: AL-KARIM — The Most Generous (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 3
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Karim',
    arabic: 'الْكَرِيمُ',
    emotionalContext: [
      "feeling undeserving of Allah's mercy",
      'feel like I have to earn my way back to Allah',
      'spiritual shame and unworthiness',
      "feel like I need to deserve Allah's help first",
      'low self-worth before Allah',
      'dua feels too big to ask',
      "ashamed to ask Allah after what I've done",
      'feel like a burden',
      'transactional relationship with Allah',
      'feel like I need to prove myself to Allah first',
    ],
    coreTeaching:
        "Al-Karim has six dimensions: He gives wanting nothing in return; He gives for no reason \u2014 not as a reward, just because; He gives to everyone regardless of who they are or what they've done; He gets happy when you receive His gifts; He gives and then praises you for having the quality; and He overlooks punishment. Al-Karim is the one who gives to those who don't deserve it. This is why Allah introduced Himself to the Prophet \uFDFA in the very first revelation as 'Al-Karim' \u2014 'Iqra' wa rabbuka al-Akram.' The Prophet felt completely unworthy: 'Who am I? I can't read. I'm nobody.' And Allah responded: I am Al-Karim. Your unworthiness is not the obstacle \u2014 it's the very reason I'm giving you this. The scholars say: call on Al-Karim specifically for duas you think are too big to ask. The logic of Karim is that it doesn't follow logic. The more undeserving you feel, the more fitting it is to call on this name. And when you truly internalize it, you stop begging others for what only He can give \u2014 because you realize He's already said: 'I've got you.'",
    propheticStory:
        "The Prophet Zakariah (AS) wanted a child, but he and his wife were elderly and she had been barren her whole life. The logic of the situation said: don't ask. Too late. Too impossible. Too much. But Zakariah didn't stop \u2014 he made dua quietly, in a low voice, out of shyness before Allah. The scholars explain that the whispered dua is actually more beloved to Allah than the loud one, because it shows the servant is embarrassed to ask such a big thing and yet still turning to Him. That is the spirit of calling on Al-Karim: you know you don't deserve it, you know it seems impossible, and you ask anyway \u2014 quietly, vulnerably, trusting that His generosity has no ceiling. Sheikh Mikaeel also shared the parable of a wealthy father whose child is dying of thirst, standing at a neighbor's door begging for water. The father is heartbroken \u2014 not because the child is thirsty, but because the child didn't come to him. Allah's heartbreak when we beg others for what He has already promised to give us is of this quality.",
    dua: NameTeachingDua(
      arabic: 'يَا كَرِيمُ بِرَحْمَتِكَ أَغِثْنِي',
      transliteration: 'Ya Karimu birahmatika aghithni',
      translation: 'O Most Generous, by Your mercy, rescue me.',
      source:
          "Traditional supplication calling on the name Al-Karim \u2014 taught specifically for duas that feel 'too big to ask'",
    ),
  ),

  // ─────────────────────────────────────────────
  // 38: AL-FATTAH — The Opener (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 1
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Fattah',
    arabic: 'الْفَتَّاحُ',
    emotionalContext: [
      'door keeps closing on me',
      'feel stuck with no way forward',
      'tried everything and nothing is opening',
      'heart feels locked',
      "can't break this addiction",
      'family member whose heart is closed',
      'business not taking off',
      'marriage not happening',
      'feel like people are blocking me',
      'everything seems impossible',
      'gave up on a dream',
      "trapped in a situation I can't escape",
    ],
    coreTeaching:
        "Al-Fattah is the Opener \u2014 the One who holds the keys to every closed door, every sealed heart, every locked situation. The Quran says: 'Whatever Allah opens for people from His mercy, no one can hold it back.' And what Allah holds back, no one can open. This name is for every person staring at a door that won't move \u2014 a heart that won't soften, a career that won't break through, a marriage that won't come, an addiction that won't release its grip. Al-Fattah doesn't open on your timeline. He opens when it's best. And He often combines Al-Fattah with Al-Alim \u2014 the Most Knowledgeable \u2014 because the opening comes when He knows it's right, not when you think it should. The door that didn't open wasn't a failure. It was Al-Fattah redirecting you. Allah only closes doors because He is opening other ones. The Quran says: 'If you believe in Him and are aware of Him, Allah will open up baraka in your life.' And He says: 'I am shy \u2014 shy to let your raised hands come back empty.' When you raise your hands to Al-Fattah and you know who you're asking, the One you're asking says He feels shy to let those hands drop without something in them. Two practices from this name: never lose hope that openings are always coming \u2014 especially for things that look completely sealed. And run toward the wall. Don't wait to see the door open first. Run at it, knowing Al-Fattah will open it. That's how you get to Hogwarts.",
    propheticStory:
        "The Prophet \uFDFA was an orphan whose father had died before his birth. When the women came to take babies to nurse \u2014 a paid arrangement \u2014 every woman passed over him. No father, no income, who would pay? Everyone walked past. Finally, Halima al-Sa'diyya said: 'I'll take the orphan boy. Maybe Allah will give us baraka.' That was Al-Fattah opening a door when everyone else saw only a closed one. Years later, at Hudaybiyyah, the Sahaba had prepared for Umrah with full intention and arrived at Makkah \u2014 only to be turned back. They were devastated. Omar was irate. It looked like a complete loss. But Allah revealed in that moment: 'Indeed We have given you a clear conquest.' The scholars say: had they entered Makkah then, the Fath of Makkah would never have happened. The apparent closing was the actual opening. Sheikh Mikaeel: 'I know now that if one right turn hadn't happened, if one phone call had been made, if one police officer had actually checked what he should have checked \u2014 my life would have been completely different. That is Al-Fattah. Working subtly, closing the wrong doors, leaving only one door open. The right one.'",
    dua: NameTeachingDua(
      arabic: 'يَا فَتَّاحُ افْتَحْ لَنَا خَيْرَ الْفَتْحِ',
      transliteration: 'Ya Fattahu iftah lana khayral fath',
      translation: 'O Opener, open for us the best of openings.',
      source:
          'Supplication calling on Al-Fattah \u2014 used when facing closed doors, sealed hearts, or situations that feel impossible to move through',
    ),
  ),

  // ─────────────────────────────────────────────
  // 39: AL-SHAKUR — The Appreciative (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 2
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Shakur',
    arabic: 'الشَّكُورُ',
    emotionalContext: [
      'feel like nothing I do is ever enough',
      'never been appreciated by my parents',
      'grinding but no one sees it',
      'feel invisible',
      "need validation but can't find it",
      'my good deeds feel worthless',
      'nobody values what I do',
      "feel like I'm not doing enough for Allah",
      'chasing approval from people',
      'anxious about whether my efforts matter',
      'grew up with parents who were never satisfied',
      'nobody acknowledges my sacrifice',
    ],
    coreTeaching:
        "Al-Shakur comes from the Arabic root shakaba \u2014 you give an animal a little food and it gives you back enormous amounts of milk. That is Al-Shakur: the One who takes a little and repays massively, far beyond what was deserved. This name is for everyone who was told growing up that they hadn't done enough. The A-minus that felt like a failure. The sacrifice no one noticed. The grind nobody saw. So many of us have internalized that nothing we do is ever enough \u2014 and we carry that wound into our relationship with Allah, thinking: 'My deeds are too small, my prayers too distracted, my good too little.' But you have forgotten who you're giving to. Al-Shakur doesn't measure the size of your deed. He measures the sincerity. A man moved a thorn branch from a path. Allah said: 'You did that for me.' Sins forgiven. A man who had lived a life of sin gave water to a thirsty dog. Allah said: 'You did that for my creation.' Jannah. The Prophet \uFDFA said: our two-rakat prayer \u2014 half-distracted, made while thinking about work \u2014 is still seen, still valued, still lifted up by Al-Shakur. Your struggle no one else has witnessed? Al-Shakur witnessed it. Your sacrifice that got no thank-you? Al-Shakur is the only one whose appreciation truly fills that void. Ibn Ata'illah: 'Sins that make you feel low and in need of Allah are better than worship that makes you arrogant.' And Al-Shakur is paired in the Quran with Al-Halim \u2014 the One who not only forgives but acts as if He didn't even see the wrong. You are seen. You are valued. Whatever little you have done \u2014 it was enough.",
    propheticStory:
        "The Prophet \uFDFA said in a hadith qudsi: 'My servant draws near to Me with the obligatory deeds. Then he continues with the voluntary deeds until I love him. And when I love him, I become the hearing with which he hears, the sight with which he sees, the hand with which he strikes, and the feet with which he walks.' Al-Shakur doesn't just notice what you do \u2014 He transforms you through it. Sheikh Mikaeel reflects: 'I myself had internalized this need for approval so deeply from my childhood. As I started to say this name more, I started to realize that Allah was saying: just do what you can. That's enough for Me. The moment I started to say that, the anxiety lifted. Because in the back of my head I'd been trying to prove something to my dad. To my older brother. But the moment you say Ya Shakur, you shift it. You put Allah right back in that place of true value.' The hadith says whoever gathers in a gathering of His remembrance \u2014 Allah says to the angels: 'Bear witness that I have forgiven everyone in this gathering for every sin they ever committed in their entire life.' An angel says: 'But Ya Allah, one man wasn't even here intentionally \u2014 he just passed by.' Allah says: 'Him too.'",
    dua: NameTeachingDua(
      arabic:
          'يَا شَكُورُ اشْكُرْ لِي سَعْيِي وَلَا تَخْذُلْنِي',
      transliteration:
          "Ya Shakuru ushkur li sa'yi wa la takhdhulni",
      translation:
          "O Most Appreciative, appreciate my striving and do not abandon me.",
      source:
          "Supplication calling on Al-Shakur \u2014 used when feeling unseen, unappreciated, or like one's efforts are too small to matter",
    ),
  ),

  // ─────────────────────────────────────────────
  // 40: AL-WAKIL — The Disposer of Affairs (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 4
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wakil',
    arabic: 'الْوَكِيلُ',
    emotionalContext: [
      'feel like everything depends on me',
      'anxious about the future',
      "can't let go of control",
      'grinding but nothing is working',
      'scared of what happens if I stop trying so hard',
      'feel responsible for everyone',
      'trying to control outcomes',
      'exhausted from carrying it all alone',
      'feel like I have to figure everything out myself',
      "trust issues \u2014 people have let me down",
      'afraid to rely on anyone',
      'feel like my effort is never enough',
    ],
    coreTeaching:
        "Al-Wakil is the one you hand your entire affairs over to \u2014 not because you stop doing your part, but because you finally understand who is actually in control. To trust Al-Wakil you need three things about Allah: He knows your situation completely; He is capable of changing it; and He loves you more than you love yourself. The failure point for most of us is the third one. We've been let down by people who said they loved us and didn't show up. But don't take the creation's image and make that the creator. Allah's love has no parallel. The hadith says: if you trusted Allah as you should, He would provide for you the way He provides for birds \u2014 they go out hungry and come back full. The birds still fly out. Tawakkul is not laziness \u2014 it is the heart never depending on anything but God while the limbs work hard. Hasballah wa ni'mal Wakil: Allah is enough for me, and He is the best disposer of affairs. Ibrahim said these exact words at 16 years old, as they placed him in the catapult to throw him into fire. Not 'save me' \u2014 just 'Allah is enough.' And the fire became cool.",
    propheticStory:
        "The night the Prophet \uFDFA fled Mecca with Abu Bakr, they hid in the Cave of Thawr for three days. Bounty hunters tracked them to the cave entrance \u2014 they were standing right above the opening. Abu Bakr whispered: 'Ya Rasoolallah, if they just lift their foot, they'll see us.' The Prophet looked at him and said: 'What do you think about two people, the third of which is Allah?' That moment captures Al-Wakil completely. The fire was blazing \u2014 the danger was real \u2014 but the awareness that Allah is with you changes your inner state entirely. The tranquility that descended on Abu Bakr's heart in that cave is the sakina that comes when you stop white-knuckling your life and realize: the third one is Allah. Hajra modeled this same quality in the desert \u2014 when Ibrahim told her he was leaving by God's command and couldn't look her in the eye, she said: 'If that's the case, we're good.' She didn't deny the hardship. She simply trusted the One in charge of her affairs more than the circumstances in front of her.",
    dua: NameTeachingDua(
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: "Hasbunallahu wa ni'mal-Wakil",
      translation:
          'Allah is enough for us, and He is the best disposer of affairs.',
      source:
          "Quran 3:173 \u2014 the words the Prophet \uFDFA and the Sahaba said when told 'the people have gathered against you, so fear them.' Also the dua of Ibrahim as he was thrown into the fire.",
    ),
  ),

  // ─────────────────────────────────────────────
  // 41: AL-WADUD — The Most Loving (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 5
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wadud',
    arabic: 'الْوَدُودُ',
    emotionalContext: [
      "feel like Allah doesn't love me",
      'wonder if Allah cares about me personally',
      'transactional relationship with Allah',
      "feel unworthy of Allah's love",
      'worship out of obligation not love',
      'feeling unloved',
      'hardship made me think Allah hates me',
      'not feeling close to Allah',
      'seeking love and validation from people',
      "feel like I have to earn Allah's love",
      "spiritually dry \u2014 going through the motions",
      "can't feel Allah's presence",
    ],
    coreTeaching:
        "Al-Wadud comes from a root that means three things at once: to desire/wish, to love, and to be with. Allah is Al-Wadud \u2014 the One whose love is the only love that fills you completely, the One who desires you, and the One who is always with you. The Quran says there are people who love other things the way they should love Allah \u2014 idols not made of stone, but of trauma, attention-seeking, and emotional need. La ilaha illallah, understood through this name, means: there is no love in my life except Allah. All the love you have for your children, your parents, your spouse \u2014 it only makes sense when it flows through the love of Allah. Ali told Hassan and Hussein: 'I only love you because loving you is how I love Allah.' The sign that Allah loves you is not that He opens the dunya to you \u2014 the Prophet \uFDFA said if this world were worth a mosquito's wing, He wouldn't give a sip of water to those who reject Him. Rather, the sign of Allah's love is that He withholds the dunya from you to protect your heart, like a mother protecting a sick child from food that would harm him. And the deepest sign? He told you who He is. You only reveal yourself to those you want to get closer to.",
    propheticStory:
        "The Prophet \uFDFA once pointed to a woman on a battlefield who had been separated from her infant. When she found her child, she grabbed him and pressed him to her chest \u2014 her heart overwhelmed, her shirt wet with milk from the emotion of it. The Prophet turned to the Sahaba and said: 'Can you imagine her throwing her child into the fire?' Everyone said no. He said: 'Allah loves you more than she loves that child.' And in a separate narration, he said to the Ansar \u2014 who felt overlooked when he gave wealth to new converts \u2014 'They go home with livestock and gold. You go home with me.' That is Allah's love language: He doesn't always give you the dunya. Sometimes He gives you Himself. Dawood (AS) asked Allah: 'What do you love most?' Allah said: 'That you cause other people to love Me \u2014 remind them of My blessings upon them.'",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ حُبَّكَ وَحُبَّ مَنْ يُحِبُّكَ',
      transliteration:
          "Allahumma inni as'aluka hubbaka wa hubba man yuhibbuk",
      translation:
          "O Allah, I ask You for Your love and the love of those who love You.",
      source:
          "Jami' at-Tirmidhi 3490 \u2014 part of a longer dua the Prophet \uFDFA taught Mu'adh ibn Jabal",
    ),
  ),

  // ─────────────────────────────────────────────
  // 42: AT-TAWWAB — The Ever-Returning (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 6
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'At-Tawwab',
    arabic: 'التَّوَّابُ',
    emotionalContext: [
      'feel too sinful to turn back to Allah',
      "stuck in a sin I can't escape",
      "ashamed to make dua because of what I've done",
      'feel like Allah hates me',
      'keep falling back into the same sin',
      "addiction I can't break",
      'feel like a hypocrite for worshipping while sinning',
      'gave up on repentance',
      "don't know if Allah will forgive me",
      'feel disconnected from God because of my sins',
      'too far gone to come back',
      'struggling to pray because of shame',
    ],
    coreTeaching:
        "At-Tawwab doesn't just mean 'the One who accepts repentance.' It means the One who loves when you turn back to him \u2014 and the One whose attention never left you in the first place. Toba is not a U-turn. It is not giving up the sin. Toba is keeping the thread. Every night that the man addicted to alcohol fell asleep saying 'Ya Allah, when will you free me?' \u2014 that was his Toba. He never gave up the address. Imam Ghazali says Toba is based on three things: knowing the sin is wrong, feeling shy before God, and staying connected. Not quitting. Staying connected. The Prophet \uFDFA would say 'Oh Allah, forgive me, I turn to you' a hundred times a day \u2014 not because he sinned a hundred times, but because Toba means turning your attention back to God whenever it drifts. You don't stand at the door hoping it opens. You stand at the door because it is an honor to be at the door. Shaytan wants one thing: to use your sin to cut the last thread. Don't let him. The hadith qudsi says: 'O son of Adam, as long as you call upon Me and never lose hope in Me, I will forgive you for all you have done \u2014 and I do not care.' If your sins reached the sky and you turned toward Him, He would come to you. If you walked toward Him, He would run.",
    propheticStory:
        "A man in Damascus was known to everyone as an alcoholic. Sheikh Ramadan al-Bouti saw him every day \u2014 at gatherings, on the street. Then one day, he was in the front row of every prayer, every circle of knowledge. The sheikh asked him: what happened? He said: every single night while I was drinking, I would turn my heart to Allah and say, 'Ya Allah, when will you free me from this sin?' Every night. He fell asleep in his sin. He woke up and fell back. But he never let go of that thread. One night, he had enough. He begged Allah until the door opened. His Toba wasn't when he gave up alcohol. His Toba was every night he never stopped talking to Allah. The Prophet \uFDFA told a parallel story: a man alone in the desert, his camel gone, his food and water gone. He lay under a tree and gave up all hope. He fell asleep. When he woke, his camel stood before him with everything on it. He was so overwhelmed with joy that he cried out, 'You are my Lord and I am your servant!' \u2014 mixing up the words from sheer ecstasy. The Prophet said: Allah is more joyful than that man when His servant turns back to Him.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
      transliteration:
          'Allahumma ighfir li wa tub alayyah innaka anta at-tawwabur-rahim',
      translation:
          'O Allah, forgive me and accept my repentance. Indeed You are At-Tawwab, the Most Merciful.',
      source:
          "From the sunnah \u2014 the Prophet \uFDFA would say this and similar phrases over 100 times in a single gathering",
    ),
  ),

  // ─────────────────────────────────────────────
  // 43: AL-HADI — The Guide (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 7
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Hadi',
    arabic: 'الْهَادِي',
    emotionalContext: [
      "don't know what to do next",
      'lost my purpose',
      'have everything but feel empty',
      'feel directionless',
      "don't know which path to choose",
      'achieved all my goals but still feel hollow',
      'confused about life decisions',
      'searching for meaning',
      "don't know why I'm here",
      'feel spiritually stagnant',
      'afraid to change',
      "don't know how to get back on track",
    ],
    coreTeaching:
        "Al-Hadi is the Guide \u2014 the One whose very name comes from the Arabic root meaning to incline, the way a gift (hadiya) makes someone incline toward the giver. You won't appreciate Al-Hadi until you admit you're lost. There are two types of being lost: not knowing your purpose at all, and knowing where you need to go but not knowing how to get there. Both are addressed by this name. The Prophet \uFDFA at age 40 felt this: he had a family, status, and integrity \u2014 yet something was missing deeper. He didn't google it. He retreated to Ghari Hira and asked Allah. Every person, whether born Muslim or not, must reach this honest moment: 'Ya Allah, I don't know what's next.' And there are two types of guidance Al-Hadi gives: showing you the way (dalala), and actually taking you there. Most of us need the second type \u2014 we already know what's right, we just can't get ourselves there. The hadith qudsi says it plainly: 'Ya ibadi, kullukum dall \u2014 every one of you is lost \u2014 illaman hadaytu \u2014 except the one I guide. Fastahduni \u2014 so ask Me. Ahdikum \u2014 and I will guide you.' Don't fear the guidance. Moses ran from it. Hamza stumbled into it. Omar was literally on his way to kill the Prophet when it found him. Guidance comes in the strangest ways, and it always makes you scared at first. Don't run.",
    propheticStory:
        "Umar ibn al-Khattab was addicted to alcohol. One night he went to drink with his companions \u2014 nobody was there. He went to buy alcohol \u2014 the shop was closed. So he wandered into the Haram to pass time. He saw the Prophet \uFDFA reciting Quran alone, facing the Kaaba. Umar hid under the curtain and slid around to listen, not wanting the Prophet to notice and change what he was reciting. The Prophet was in Surah al-Haqqah. Verse by verse it captivated Umar. 'He's a poet,' he thought. The next verse: 'These are not the words of a poet.' 'He's a soothsayer.' The next verse: 'Nor a soothsayer.' And then: 'This is revelation from Allah.' That night, Umar said, 'I was done.' But he was scared. The next morning, instead of going to accept Islam, he went to kill the Prophet \u2014 because when guidance comes, we often fight the very thing pulling us forward. Allah set everything up: the empty gathering spot, the closed shop, the late-night tawaf, the unguarded recitation. That is how Al-Hadi works \u2014 not always announcing itself, but arranging everything until the only door left open is the right one.",
    dua: NameTeachingDua(
      arabic: 'اللَّهُمَّ اهْدِنَا وَاهْدِ بِنَا',
      transliteration: 'Allahumma ihdina wa ihdi bina',
      translation:
          'O Allah, guide us and make us a means of guidance for others.',
      source:
          'Prophetic supplication \u2014 used when asking Al-Hadi for direction and to become a guide for others',
    ),
  ),

  // ─────────────────────────────────────────────
  // 44: AL-QABID & AL-BASIT (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 8
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Qabid & Al-Basit',
    arabic: 'الْقَابِضُ الْبَاسِطُ',
    emotionalContext: [
      "having a bad day and don't know why",
      'feel sad for no reason',
      'heart feels heavy',
      'lost my job',
      'financial hardship',
      'feel like life is contracting',
      'scared of the down moments',
      "wonder why things aren't expanding for me",
      'feel like Allah is withholding from me',
      "can't shake this sadness",
      'going through a rough patch',
      'why is everything going wrong',
      'stuck in a low period',
      'feel disconnected from people',
    ],
    coreTeaching:
        "Al-Qabid is the one who constricts \u2014 who withholds, pulls back, tightens. Al-Basit is the one who expands \u2014 who opens up, gives abundantly. You cannot understand one without the other. Allah sets the market: He raises and He corrects. If the market only ever trended upward, you would run rampant on the earth \u2014 the Quran says so explicitly about Qarun. The correction is the blessing. Spiritually, the moments of sadness (qabdh) are Allah's love language, not His punishment. Norepinephrine drops when you're sad \u2014 which means you disengage from the world, your attention narrows, your connection to the dunya weakens. That is exactly when He's calling you to Him. The feeling of distance from people is a sign Allah is saying: 'Come close to Me.' Don't confuse this with depression \u2014 depression is debilitating and satanic. Normal sadness is a market correction, a pull-in that shoots you forward. The Prophet \uFDFA said: 'I don't fear poverty for you \u2014 I fear that the dunya will be opened up for you the way it was for those before you, and then you'll compete over it.' The prophet feared Al-Basit more than Al-Qabid for the ummah. Learn to love both names.",
    propheticStory:
        "The Prophet \uFDFA was watching when Hanzala walked through Medina muttering, 'I'm a hypocrite. I'm a hypocrite.' Abu Bakr stopped him: 'What do you mean?' Hanzala said: 'When I'm with the Prophet, my iman is so high I can see Jannah. But when I go home to my wife and kids, I forget everything.' Abu Bakr said: 'Me too \u2014 I must be a hypocrite too.' They went to the Prophet. He listened and said: 'Sometimes here, sometimes there.' Some days at the peak, some days in the trough \u2014 this is the nature of a human being. If you stayed at that peak level constantly, the angels would greet you in the streets \u2014 but you're not meant to sustain that yet. The Prophet himself, before revelation began, felt an inexplicable sadness and withdrew from people. He didn't know why. Allah was pulling him in so He could open something far greater. The scholar told Sheikh Mikaeel: there's a difference between waking up and growing up. Waking up is recognizing that Al-Qabid is Allah's love language. Growing up is staying connected to Allah when the constriction comes \u2014 not throwing a tantrum, not breaking down \u2014 but saying: 'This is good for me too. Let's go.'",
    dua: NameTeachingDua(
      arabic:
          'يَا قَابِضُ يَا بَاسِطُ ابْسُطْ عَلَيْنَا مِنْ رَحْمَتِكَ',
      transliteration:
          "Ya Qabiду ya Basitu ibsut 'alayna min rahmatik",
      translation:
          "O Constrictor, O Expander \u2014 spread over us from Your mercy.",
      source:
          "Supplication calling on Al-Qabid and Al-Basit together \u2014 used in moments of constriction to remember that both states are from Allah and both carry His mercy",
    ),
  ),

  // ─────────────────────────────────────────────
  // 45: AL-MUQADDIM & AL-MU'AKHKHIR (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 15
  // ─────────────────────────────────────────────
  NameTeaching(
    name: "Al-Muqaddim & Al-Mu'akhkhir",
    arabic: 'الْمُقَدِّمُ الْمُؤَخِّرُ',
    emotionalContext: [
      'why is my blessing delayed',
      "everyone else is moving forward and I'm stuck",
      'feel left behind in life',
      "frustrated that things aren't happening on my timeline",
      'bitter at someone who held me back',
      'feel like people are blocking my progress',
      'comparing my progress to others',
      'scared to take an opportunity',
      "feel like I'm not ready yet",
      'resentful of responsibilities holding me back',
      'anxious about the future',
      "can't stop focusing on what should have happened by now",
    ],
    coreTeaching:
        "Al-Muqaddim is the One who advances \u2014 the One who pushes people forward and opens opportunities. Al-Mu'akhkhir is the One who delays \u2014 the One who holds things back and keeps you in a season longer. These two names must be studied together because they reveal one truth: Allah brings everything on time. Not your time. His time. The problem is we carry a mental list of 'shoulds' \u2014 I should have a job by now, I should be married by now, I should have graduated. Those shoulds steal our ability to see what Allah wants from us in the season we're actually in. Every season has its own beauty. The delay is not punishment \u2014 it's the growth itself. Like the slow eccentric in a workout, the growth happens in the holding back. Joseph was in prison for something he didn't do. When his cellmate forgot him, he held no bitterness \u2014 because he understood the one who delayed his freedom wasn't the cellmate, it was Allah, and Allah had a reason. Those extra years in prison gave him the dream interpretation that made the king say: I need this man by my side. The delay was the setup. The Prophet \uFDFA at Hudaybiyyah had the Sahaba ready to push forward to Makkah, but the camel sat down and wouldn't move. He read that sign: something else is happening here. He accepted the 'delay' of Omra. In that very acceptance came the revelation: 'We have given you a clear victory.' Your provision cannot miss you. The hadith says: 'Your rizq chases you the way death chases you.' You are not chasing it \u2014 it is chasing you. And you cannot get what Allah wrote for you through haram means. You'll get the check, but not the baraka. You'll relieve the desire, but carry the guilt.",
    propheticStory:
        "Yusuf (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) sat in prison for years after his cellmate \u2014 the one he helped interpret a dream \u2014 was freed and returned to the king's side. He forgot Yusuf completely. When the king had a dream no one could interpret, the former cellmate finally remembered. He went back to prison and asked Yusuf. Yusuf interpreted it immediately \u2014 without a hint of bitterness, without mentioning the years of waiting, without a single 'you forgot me.' Why? Because Yusuf understood that the delay was not in the cellmate's hands. It was in Allah's hands. The scholars explain: had he gotten out earlier, he would never have had the chance to interpret that dream. The dream interpretation was the door to becoming minister of Egypt. The delay was not the obstacle \u2014 it was the path. He ends up as the Aziz, effectively the ruler. Meanwhile, the Prophet \uFDFA's camel Qaswa sat down on the way to Makkah and refused to move, even though the Sahaba were eager. He recognized the sign, accepted the turning back, and signed the Treaty of Hudaybiyyah. The Sahaba were devastated. But Allah revealed: 'Indeed We have given you a clear conquest.' The conquest happened the moment they accepted the delay.",
    dua: NameTeachingDua(
      arabic:
          'اللَّهُمَّ اجْعَلْنِي رَاضِيًا بِمَا قَسَمْتَ لِي وَبَارِكْ لِي فِيهِ',
      transliteration:
          "Allahumma ij'alni radiyan bima qasamta li wa barik li fihi",
      translation:
          'O Allah, make me pleased with what You have allotted me, and bless me in it.',
      source:
          "Adapted from the prophetic morning dua \u2014 asking Al-Muqaddim and Al-Mu'akhkhir for contentment in one's season",
    ),
  ),

  // ─────────────────────────────────────────────
  // 46: AL-LATIF — The Subtle, The Gentle (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series, Class 17
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Latif',
    arabic: 'اللَّطِيفُ',
    emotionalContext: [
      "can't see God's plan in my hardship",
      'feel like life is falling apart',
      "don't understand why this is happening",
      'feel like God abandoned me',
      "going through pain and can't find the meaning",
      "struggling but can't see any good in it",
      'life feels unfair',
      'lost job or going through divorce',
      'harsh on myself',
      'harsh on others',
      'wonder if God even notices',
      "can't connect good intentions to bad outcomes",
    ],
    coreTeaching:
        "Al-Latif comes from a root with four interlocking meanings: to know things deeply (what's beneath the surface), to be gentle, to be benevolent, and to be subtle \u2014 so delicate and precise it's difficult to describe. Like a finely woven cloth where you can't separate the threads, Allah weaves our lives together in a tapestry that only makes sense when you step back. When you're in the hardship, all you see is the thread. Al-Latif sees the whole carpet. The scholars say: when you call this name in hardship, two things happen. First, it forces you to admit that God has a plan \u2014 because that is literally his name, the Subtle One, the One whose plans can't be measured or analyzed. Second, it asks him to be gentle with you, because hardship will break you if you try to carry it alone. Allah weaves even the most painful seasons into something beautiful. The teeth a child loses had to fall out \u2014 but Al-Latif arranged it so gently, through an apple bite or natural loosening, that there was almost no pain. That's how he moves in your life. Subtle. Gentle. Always working in the background. The eyes can't perceive God \u2014 but if you develop the inner sight, you begin to see him everywhere. In the 'coincidences' that led you here. In the near-misses you didn't even notice. In the job that taught you what you needed for the career you couldn't imagine yet. Al-Latif also knows what's in your heart \u2014 not just your external deeds, but the intention behind them. A handful of wheat given with pure sincerity outweighs a mountain of gold given for show.",
    propheticStory:
        "Yusuf (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) was thrown in a well by his brothers, sold into slavery, raised in a foreign house, wrongly accused, and forgotten in prison for years. At every stage, if you only saw the thread, you'd see nothing but cruelty and suffering. But when he finally stood on the throne with his parents before him and his brothers who had wronged him, he didn't call it a tragedy. He called it mercy. 'My Lord was so subtle in his plans,' he said. (Quran 12:100) The scholars note: where did a slave learn the economic wisdom to govern all of Egypt? In the house of the finance minister \u2014 when he was a slave. Al-Latif was teaching him through the very thing that looked like humiliation. He couldn't have become Aziz without first becoming a slave. The tapestry was always being woven. Sheikh Mikaeel reflected: 'I shouldn't be sitting here right now. I should be a statistic. But he's Latif. Subtle. Every right turn that shouldn't have happened. Every cop who didn't check what he should have checked. Every stranger who said the right thing at the right moment. That's Al-Latif, working gently in the background of a life that looked lost from the outside.'",
    dua: NameTeachingDua(
      arabic:
          'يَا لَطِيفُ الْطُفْ بِي فِيمَا جَرَتْ بِهِ الْمَقَادِيرُ',
      transliteration:
          'Ya Lateefu ultuf bi fima jarat bihi al-maqadir',
      translation:
          'O Subtle One, be gentle with me in all that destiny has decreed.',
      source:
          'Traditional dua of the awliya \u2014 recited morning and evening, calling on Al-Latif in hardship and uncertainty',
    ),
  ),

  // ─────────────────────────────────────────────
  // 47: AL-WAHHAB — The Bestower of Gifts (Mikaeel)
  // Source: Sheikh Mikaeel Smith, "The Name I Need" series
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Al-Wahhab',
    arabic: 'الْوَهَّابُ',
    emotionalContext: [
      "feeling like I don't deserve to ask Allah",
      "jealous of other people's blessings",
      'transactional relationship with God',
      'feeling ungrateful',
      'wanting a child',
      'wanting something that feels impossible',
      "feeling like my deeds aren't enough to make dua",
      'struggling to love Allah',
      'heart feels disconnected from worship',
      'going through the motions of prayer without feeling',
      'comparing yourself to others',
      'taking blessings for granted',
    ],
    coreTeaching:
        "Al-Wahhab is the Bestower of Gifts \u2014 the One who gives repeatedly and lavishly, expecting nothing in return. In Arabic, a single gift is just a gift. But wahab is one who gives over and over, or gives something so enormous that no return is possible. The foundation of faith is hub \u2014 love. And you cannot love Allah until you realize He loves you first. The disbeliever gets stuck at the blessing: imprisoned by what they received, never moving beyond it to the One who gave it. The believer uses every blessing as a window to see Al-Wahhab behind it. Every gift in your life \u2014 your spouse, your children, your job, the sunlight, the breath in your lungs \u2014 none of it was deserved. It was a hiba, a pure gift, with nothing asked in return. When you see blessings this way, entitlement dissolves into indebtedness, and indebtedness becomes love. This name is also the cure for jealousy: when you see someone blessed, instead of envy, you realize the same Al-Wahhab who gave them is the same One who can give you. You are simply next in line.",
    propheticStory:
        "The Prophet Zakariah (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) was 70 years old, his wife well beyond childbearing age, and he desperately wanted a child \u2014 not for legacy alone, but for companionship. He was a prophet of Allah, yet he said: 'O Allah, do not leave me alone.' Then he walked into Maryam's chamber and saw fruit out of season before her. He asked where it came from. She said simply: 'It is from Allah \u2014 He provides for whom He wills, without reckoning.' In that moment, Zakariah saw what was possible. He stopped looking at his means. He called upon Allah with the name Al-Wahhab: 'Rabbi hab li \u2014 O Lord, just bestow it upon me.' When the angel came with the news of Yahya, Zakariah asked: 'How?' Allah's answer: 'I said so.' The means did not need to exist. Al-Wahhab simply wills it. Ibrahim too used this name. Suleiman used it \u2014 asking for forgiveness and in the same breath, a kingdom unlike any the world had seen. These prophets didn't wait to deserve it. They knew who they were asking.",
    dua: NameTeachingDua(
      arabic:
          'رَبِّ هَبْ لِي مِن لَّدُنكَ ذُرِّيَّةً طَيِّبَةً إِنَّكَ سَمِيعُ الدُّعَاءِ',
      transliteration:
          "Rabbi hab li min ladunka dhurriyyatan tayyibah, innaka sami'ud-du'a'",
      translation:
          'My Lord, grant me from Yourself a good offspring. Indeed, You are the Hearer of supplication.',
      source:
          'Quran 3:38 \u2014 Dua of Zakariah (AS), used when asking Al-Wahhab for what seems impossible',
    ),
  ),
];

/// Returns the most relevant Names of Allah for a given emotional situation.
/// Used to seed the Claude system prompt with targeted knowledge.
List<NameTeaching> getRelevantTeachings(String userText) {
  final lower = userText.toLowerCase();

  // Keyword-to-name-index mapping for fast matching
  const List<MapEntry<List<String>, int>> keywordMap = [
    MapEntry(['sin', 'guilt', 'shame', 'forgive', 'repent', 'tawbah', 'forgiven', 'wrong'], 4),   // Al-Ghaffar
    MapEntry(['heard', 'prayer', 'dua', 'answer', 'respond', 'listen'], 5),                         // As-Sami
    MapEntry(['seen', 'invisible', 'unnoticed', 'witness', 'nobody sees'], 6),                       // Al-Basir
    MapEntry(['stuck', 'trapped', 'door', 'way out', 'blocked', 'same cycle'], 7),                  // Al-Fattah
    MapEntry(['why', 'wisdom', 'pain', 'makes no sense', 'understand', 'purpose'], 8),              // Al-Latif
    MapEntry(['oppressed', 'injustice', 'tyrant', 'unfair', 'bully', 'oppressor'], 9),              // Al-Qahhar
    MapEntry(['justice', 'account', 'reckoning', 'judge', 'wrong', 'unpunished'], 10),              // Al-Adl
    MapEntry(['heal', 'sick', 'illness', 'pain', 'disease', 'medicine'], 11),                       // Ash-Shafi
    MapEntry(['patient', 'patience', 'react', 'anger', 'frustrated', 'snap'], 12),                  // As-Sabur
    MapEntry(['time', 'death', 'end', 'passing', 'wasted', 'future', 'dying'], 13),                 // Al-Awwal
    MapEntry(['love', 'lonely', 'unloved', 'alone', 'heartbreak', 'connection'], 14),              // Al-Wadud
    MapEntry(['guilty', 'erased', 'pardon', 'laylat al-qadr', 'wiped clean'], 15),                 // Al-Afuw
    MapEntry(['anxious', 'anxiety', 'control', 'worry', 'fear', 'helpless'], 16),                   // Al-Wakil
    MapEntry(['scattered', 'lost dreams', 'gather', 'wasted effort'], 17),                          // Al-Jami
    MapEntry(['money', 'provision', 'rizi', 'finances', 'poor', 'gift', 'generous'], 18),           // Al-Karim
    MapEntry(['alone', 'middle of night', 'despair', 'everything falling apart'], 19),              // Al-Hayy
    MapEntry(['empty', 'nothing satisfies', 'restless', 'hollow', 'craving'], 20),                  // As-Samad
    MapEntry(['abandoned', 'no one', 'stranger', 'lonely', 'nobody', 'bereaved'], 21),             // Al-Wali
    MapEntry(['humiliated', 'small', 'insignificant', 'crushed', 'ego'], 22),                       // Al-Ali/Azim
    MapEntry(['peace', 'trauma', 'restless', 'panic', 'anxiety'], 23),                              // As-Salam
    MapEntry(['exhausted', 'weak', 'powerless', 'give up', 'burned out'], 24),                     // Al-Qawi
    MapEntry(['mercy', 'unworthy', 'hopeless', 'depressed', 'burden'], 0),                         // Ar-Rahman
    MapEntry(['divided', 'distracted', 'scatter', 'validation', 'approval'], 1),                   // Al-Wahid
    MapEntry(['guidance', 'confused', 'direction', 'doubt', 'dark', 'lost faith'], 2),             // Al-Hadi
    MapEntry(['purpose', 'meaning', 'lord', 'belonging', 'nobody cares', 'enslaved'], 3),           // Ar-Rabb
    MapEntry(["allah absent from my life", "can't see allah anywhere", 'spiritually disconnected', 'only focused on appearances', 'heart feels dirty', 'hidden resentment', "can't find meaning in daily life", 'mundane has no connection to god', 'is god really there', "feel like allah doesn't see me", 'hollow inside externally fine'], 26), // Al-Dhahir/Al-Batin
    MapEntry(['feel empty', 'void inside', 'still not satisfied', 'chasing the next thing', 'filling emptiness', 'looking for completion', 'restless despite blessings', 'always wanting more', 'shopping to feel better', 'career not fulfilling', 'missing something'], 27), // Al-Ghani
    MapEntry(['chasing approval from people', 'compromising deen for status', 'give up values to get ahead', 'seeking honor from boss', 'disrespected', 'sacrificing prayers for career', 'islam holding me back', 'worried what people think', 'people-pleasing', 'feel humiliated', 'giving up identity for acceptance', 'career pressure to fit in', 'selling out', 'am i sacrificing allah'], 28), // Al-Mu'izz/Al-Mudhil
    MapEntry(['broken heart', 'broken', 'fix me', 'something is wrong', "can't be fixed", 'no one can help', "doctors don't know", 'feel shattered', 'emotionally broken', 'financially broke', 'need to be mended', 'being forced', 'someone controlling me'], 29), // Al-Jabbar
    MapEntry(['overpowered', 'helpless', 'stuck', "can't break", 'addiction', 'doing it alone', 'people let me down', 'no way out', 'too weak', 'overwhelmed', 'self-sufficient', "can't find a way"], 30), // An-Nasir
    MapEntry(["scared about the future", 'big transition', 'between jobs', "waiting and don't know what's next", 'no one looking out for me', 'feel abandoned in hard season', 'have to figure it all out myself', "can't see how it will work out", 'feel on my own', 'everything changed and not ready', 'who is taking care of me', 'going through transition'], 31), // Ar-Rabb
    MapEntry(['anxious about money', 'worried about provision', 'scared about finances', 'feel like i have to figure out finances alone', "scared i won't have enough", "jealous of others' wealth", 'boss controls my future', 'scarcity mindset', "can't trust things will work out", 'grinding but not enough', "feel like i'm providing for everyone", 'slave to the means'], 32), // Ar-Razzaq
    MapEntry(["far from allah", 'feel distant', "allah doesn't hear", 'dua unanswered', 'stopped making dua', 'sins pushed me away', "don't feel worthy to ask", 'feel alone with my problems', 'nobody understands'], 33), // Al-Qarib/Al-Mujib
    MapEntry(['no peace', 'restless', 'hollow', 'nothing satisfies', 'searching for peace', 'empty inside', 'addicted', 'substance', 'shop', 'shopping', 'grind', 'marriage complete me', 'jealousy', 'arrogance', 'hatred'], 34), // As-Salam
    MapEntry(['feel spiritually empty', 'heart is dark', 'spiritually dead', "can't find clarity", 'feel disconnected from allah', 'heart feels hard', 'walking in the dark', "don't feel the light", 'lost my sense of purpose', 'confused about my path', "don't feel ramadan", 'spiritually hollow'], 35), // An-Nur
    MapEntry(['stuck on sin', "can't forgive myself", 'stopped praying', 'shame holding', 'too sinful', 'broken relationship', 'grudge', 'let go', 'past mistakes', 'cringe', "can't move on"], 36), // Al-'Afuww
    MapEntry(['undeserving', "don't deserve", 'not worthy', 'earn my way', 'low self-worth', 'who am i to ask', 'dua too big', 'ashamed to ask allah', 'too big to ask', 'need to prove myself first'], 37), // Al-Karim
    MapEntry(['door keeps closing', 'stuck with no way forward', 'tried everything', 'heart feels locked', 'nothing opening', "can't break through", 'everything seems impossible', 'gave up on a dream', 'trapped', 'people blocking me', 'closed door', 'sealed heart'], 38), // Al-Fattah
    MapEntry(['never appreciated', 'nothing i do is enough', 'nobody sees my struggle', 'feel invisible', 'need validation', 'good deeds feel worthless', 'nobody values me', 'chasing approval', "my efforts don't matter", 'never satisfied with me', 'nobody acknowledges my sacrifice', 'grind no one notices'], 39), // Al-Shakur
    MapEntry(['feel like everything depends on me', "can't let go of control", 'anxious about the future', 'grinding but nothing is working', 'scared to stop trying', 'feel responsible for everyone', 'trying to control outcomes', 'exhausted from carrying it all', 'trust issues', 'people let me down', 'afraid to rely on anyone', "can't hand it over"], 40), // Al-Wakil
    MapEntry(["feel like allah doesn't love me", 'wonder if allah cares', 'transactional relationship', 'worship out of obligation', 'feeling unloved', 'hardship means allah hates me', 'not feeling close to allah', 'seeking love from people', "earn allah's love", 'going through the motions', "can't feel allah's presence", 'spiritually dry'], 41), // Al-Wadud
    MapEntry(['sin i keep doing', "can't stop sinning", 'too sinful for allah', 'ashamed to pray', 'allah hates me', 'feel like a hypocrite', 'gave up repentance', 'keep falling back', "won't forgive me", 'disconnected because of sin', 'too far gone'], 42), // At-Tawwab
    MapEntry(['lost', "don't know what to do", 'no purpose', 'empty inside', 'have everything but', 'feel directionless', 'which path', "what's next", 'spiritually stagnant', 'afraid to change', 'get back on track'], 43), // Al-Hadi (Mikaeel)
    MapEntry(['bad day for no reason', 'heart feels heavy', 'lost my job', 'financial hardship', 'life is contracting', 'scared of down moments', 'allah withholding', "can't shake sadness", 'rough patch', 'everything going wrong', 'stuck in a low', 'feel disconnected from people', 'why is everything contracting', 'sad for no reason'], 44), // Al-Qabid/Al-Basit
    MapEntry(['delayed', 'held back', 'left behind', 'everyone else moving', 'not on my timeline', 'supposed to happen by now', 'not ready yet', 'blocking my progress', 'bitter at someone', 'comparing progress', 'responsibilities holding me back', 'should have happened'], 45), // Al-Muqaddim/Al-Mu'akhkhir
    MapEntry(["can't see the plan", 'life falling apart', "don't understand why", 'feel abandoned', 'pain has no meaning', 'life feels unfair', 'harsh on myself', 'wonder if god notices', 'gentle', 'hardship makes no sense', 'going through divorce', 'lost a job'], 46), // Al-Latif
    MapEntry(['deserve', 'jealous', 'jealousy', 'transactional', 'ungrateful', 'impossible', 'child', 'going through motions', 'gift', 'bestow', 'envy', 'deeds not enough'], 47), // Al-Wahhab
  ];

  final scores = List<int>.filled(nameTeachings.length, 0);

  for (final entry in keywordMap) {
    final keywords = entry.key;
    final idx = entry.value;
    for (final kw in keywords) {
      if (lower.contains(kw)) {
        scores[idx] += 2;
        break; // one match per keyword group is enough
      }
    }
  }

  // Also check each name's emotionalContext list
  for (var idx = 0; idx < nameTeachings.length; idx++) {
    final teaching = nameTeachings[idx];
    for (final ctx in teaching.emotionalContext) {
      final firstWord = ctx.toLowerCase().split(' ')[0];
      if (firstWord.length > 3 && lower.contains(firstWord)) {
        scores[idx] += 1;
      }
    }
  }

  final indexed = List.generate(
    scores.length,
    (i) => MapEntry(scores[i], i),
  );
  indexed.sort((a, b) => b.key.compareTo(a.key));

  final top = indexed
      .where((s) => s.key > 0)
      .take(3)
      .map((s) => nameTeachings[s.value])
      .toList();

  return top.isNotEmpty ? top : [nameTeachings[0]]; // default to Ar-Rahman
}
