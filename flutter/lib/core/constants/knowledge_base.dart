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
library;

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
      "feeling unworthy of allah's love",
      'overwhelmed by sins',
      'fear of being rejected by allah',
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
      'career or money becoming the priority over allah',
      'heart divided between many things',
      "feeling enslaved to people's opinions",
    ],
    coreTeaching:
        'You only need one God. Your heart was not designed to bow in a thousand directions. Al-Wahid negates all other gods in number; Al-Ahad negates any likeness — there is no God but Him, and no God like Him. Ibn al-Qayyim said: "For One, be one upon one" — unify yourself for the singular path. When Bilal was chained and tortured, he said only "Ahad, Ahad" — knowing this one name alone was enough to find strength in Allah and be willing to die for Him. The slave in chains became freer than the master with the whip. Shirk is never rational: it is born from insecurity or desire. Every false god is just human insecurity, desire, or corruption dressed in divinity.',
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
      "cannot feel allah's presence",
      'wanting to return to allah but not knowing how',
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
          'Bukhari \u2014 said by the Prophet \uFDFA on his way to prayer',
    ),
  ),

  // ─────────────────────────────────────────────
  // 3: AR-RABB — The Lord and Nurturer
  // ─────────────────────────────────────────────
  NameTeaching(
    name: 'Ar-Rabb',
    arabic: 'الرَّبُّ',
    emotionalContext: [
      "feeling like allah doesn't care about your personal life",
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
          'Muslim \u2014 said by the Prophet \uFDFA, the language of one who knows refuge is only found in the One he fears to disappoint',
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
      'ashamed to face allah',
      'wondering if allah will still accept me',
      'despair after repeated failure',
      'feeling unclean spiritually',
    ],
    coreTeaching:
        'Al-Ghafir forgives the initial sin. Al-Ghaffar forgives the repeated sins \u2014 every time you return, He meets you with forgiveness again. Al-Ghafoor is the all-encompassing forgiver whose quality of forgiveness is so vast it covers sins you did not even realize you committed. Allah says: "O My servant, if you brought Me an earth full of sins without associating a partner with Me, I would meet you with an earth full of forgiveness \u2014 and I would not mind." At-Tawwab actually turns towards you FIRST so that you can turn towards Him \u2014 He inspires repentance, sends reminders, opens pathways back. The Prophet \uFDFA said: "If you did not sin, Allah would replace you with a people who would sin and seek His forgiveness \u2014 because sometimes a sin that brings you closer to Allah is better than a good deed that fills you with arrogance."',
    propheticStory:
        'A man who killed 99 people asked a worshipper if Allah would forgive him \u2014 the man said no, so he killed him too (100). Then a scholar said: "Who can stand between you and the mercy of Allah? Go to a new land and live righteously." On the way, he died. Allah commanded: measure the distance between him and the two lands \u2014 then moved the earth itself to bring him nearer to His mercy. Allah inspired his repentance, sent the scholar, and shifted the ground \u2014 all so He could forgive him.',
    dua: NameTeachingDua(
      arabic:
          'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
      transliteration:
          "Rabbighfir li wa tub 'alayya innaka anta't-Tawwabu'r-Rahim",
      translation:
          'My Lord, forgive me and accept my repentance. Indeed, You are At-Tawwab, Ar-Rahim.',
      source:
          'Bukhari \u2014 the Prophet \uFDFA said this 100 times a day',
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
      'feeling distant from allah',
      'wondering if allah cares',
      'tired of asking for the same thing',
      'doubting whether dua works',
      'longing for connection with allah',
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
          'Quran 11:61 \u2014 words of the Prophet Salih (\u0639\u0644\u064A\u0647 \u0627\u0644\u0633\u0644\u0627\u0645)',
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
          'Rabbana iftah baynana wa bayna qawmina bil-haqq wa anta khayrul-fatihin',
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
      "questioning allah's wisdom",
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
        'The Prophet \uFDFA prayed: "Take away the harm, Lord of people. Heal, for You are the Healer, and there is no healing except Your healing \u2014 a healing that leaves behind no trace of illness or affliction." The doctor can only treat, but only Allah can heal. Take the means and do not worship the means. The Healer even heals with the sickness itself \u2014 the Prophet \uFDFA said: "Do not curse the fever, for it burns off your sins the way fire burns off filth from iron." Ibn al-Qayyim (\u0631\u062D\u0645\u0647 \u0627\u0644\u0644\u0647) said: "I stayed in Mecca ill with no doctor or medicine. I treated myself with al-Fatiha and saw an astonishing effect." The Quran is healing and mercy walking next to your medication \u2014 not replacing it, but blessing it.',
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
          'Bukhari and Muslim \u2014 dua for healing said by the Prophet \uFDFA',
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
        'Al-Wadud is the One who is willing to love \u2014 but you have to be loyal in that love. When Allah loves you, it never stops at just feelings. The current of love runs from the throne of Ar-Rahman, through the angels of light, into the lives of people you may not have even met yet. Al-Wadud announces your name in the heavens for the simplest act of love on earth. If Al-Wadud loves the repentant sinner so much and rejoices for him, how much more does He love the striving worshipper?',
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
          'Al-Tirmidhi \u2014 taught by the Prophet \uFDFA to Aisha specifically for Laylat al-Qadr',
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
      'feeling disconnected from allah',
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
          'Our Lord, surely You will gather the people for a Day about which there is no doubt. Indeed, Allah does not fail in His promise.',
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
      'feeling like allah is distant or not listening',
      'calling out in the middle of the night',
      'feeling completely alone',
      'when everything seems to be falling apart at once',
      'despair',
      "seeking comprehensive help when you don't know where to turn",
      'needing allah to handle all your affairs',
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
          'Al-Hakim \u2014 taught by the Prophet \uFDFA to his daughter Fatima for morning and evening',
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
      'ptsd or emotional aftermath',
      'witnessing tragedy',
    ],
    coreTeaching:
        'As-Salam is not just the name for peace \u2014 He is peace Himself. Al-Quddus is utterly pure, free from every imperfection. The scholars say peace comes from three things: from knowing Him in His perfection, from trusting His perfect plan, and from remembering His perfect reward. Ibn al-Jawzi said Allah called Palestine al-Ard al-Muqaddasa, the Holy Land, because of its connection to As-Salam \u2014 the land of prophets and peace even in its most turbulent moments.',
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
          'Muslim \u2014 said by the Prophet \uFDFA after every obligatory prayer',
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
          'You are Al-Dhahir \u2014 there is nothing above You. You are Al-Batin \u2014 there is nothing closer to me than You.',
      source:
          'Sahih Muslim 2713 \u2014 part of the bedtime dua the Prophet \uFDFA taught, pairing Al-Dhahir and Al-Batin',
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
      'career not giving me what i thought it would',
      "feel like i'm missing something",
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
      'feel like i have to give up my values to get ahead',
      'seeking honor from a job or boss',
      'feel disrespected or looked down on',
      'sacrificing prayers or islam for career',
      'feel like my islam is holding me back',
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
      "something feels wrong but i don't know what",
      'emotionally broken',
      'spiritually broken',
      'sick with no diagnosis',
      'financially desperate',
      'being controlled or forced by someone',
      'trying to control or fix others',
      'feel like no one can help me',
      'doctors have no answers',
      "anxiety or depression i can't explain",
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
      'feeling overpowered and helpless',
      "stuck and can't find a way out",
      'too proud to ask for help',
      "struggling with addiction i can't break",
      "doing everything myself but it's not working",
      'self-sufficiency mentality blocking me',
      'turned to people for help but they let me down',
      "financial situation i can't escape",
      'feel too weak to keep going',
      'overwhelmed by responsibility',
      "don't know where to turn",
      'waiting for things to change but nothing moves',
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
      'worried about losing what i have',
      'feel like i have to figure it all out myself',
      "can't see how it will work out",
      "feel like i'm on my own",
      "everything changed and i'm not ready",
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
          'Quran 20:25-26 \u2014 the dua of Moses when given an overwhelming task, calling on Ar-Rabb specifically',
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
          'O Allah, suffice me with what You have made lawful, sparing me from what You have made unlawful, and enrich me with Your bounty so that I need no one but You.',
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
      'feeling far from allah',
      'feel like my sins have pushed me away from allah',
      "don't feel worthy to make dua",
      "feel like allah doesn't hear me",
      'lonely and disconnected',
      'feel like no one truly understands me',
      'afraid to ask allah for things',
      'stopped making dua',
      'dua feels unanswered',
      'struggling with sins and feel distant from god',
      'going through something difficult and feel alone',
      "can't find closeness to allah no matter what i do",
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
          'Quran 21:87 \u2014 the dua of Yunus (AS) from the belly of the whale. The Prophet \uFDFA said no Muslim calls with this dua except that Allah responds.',
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
      "can't find peace no matter what i do",
      'internal conflict and anxiety',
      'struggling with jealousy, arrogance, or hatred',
      "heart feels flawed and i can't change",
      'no peace at home',
      'everything is fine externally but i feel hollow',
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
          'Sahih Muslim 591 \u2014 recited by the Prophet \uFDFA after every obligatory prayer',
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
      'feel disconnected from allah',
      "don't feel ramadan this year",
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
      'feeling too sinful to approach allah',
      'stuck on past sins even after repenting',
      "can't forgive myself",
      'shame from the past is holding me back spiritually',
      "don't feel close to allah after sinning",
      'stopped praying because of guilt',
      'relationship with allah feels broken',
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
      "feeling undeserving of allah's mercy",
      'feel like i have to earn my way back to allah',
      'spiritual shame and unworthiness',
      "feel like i need to deserve allah's help first",
      'low self-worth before allah',
      'dua feels too big to ask',
      "ashamed to ask allah after what i've done",
      'feel like a burden',
      'transactional relationship with allah',
      'feel like i need to prove myself to allah first',
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
      "trapped in a situation i can't escape",
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
      'feel like nothing i do is ever enough',
      'never been appreciated by my parents',
      'grinding but no one sees it',
      'feel invisible',
      "need validation but can't find it",
      'my good deeds feel worthless',
      'nobody values what i do',
      "feel like i'm not doing enough for allah",
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
          'O Most Appreciative, appreciate my striving and do not abandon me.',
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
      'scared of what happens if i stop trying so hard',
      'feel responsible for everyone',
      'trying to control outcomes',
      'exhausted from carrying it all alone',
      'feel like i have to figure everything out myself',
      'trust issues \u2014 people have let me down',
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
      "feel like allah doesn't love me",
      'wonder if allah cares about me personally',
      'transactional relationship with allah',
      "feel unworthy of allah's love",
      'worship out of obligation not love',
      'feeling unloved',
      'hardship made me think allah hates me',
      'not feeling close to allah',
      'seeking love and validation from people',
      "feel like i have to earn allah's love",
      'spiritually dry \u2014 going through the motions',
      "can't feel allah's presence",
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
          'O Allah, I ask You for Your love and the love of those who love You.',
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
      'feel too sinful to turn back to allah',
      "stuck in a sin i can't escape",
      "ashamed to make dua because of what i've done",
      'feel like allah hates me',
      'keep falling back into the same sin',
      "addiction i can't break",
      'feel like a hypocrite for worshipping while sinning',
      'gave up on repentance',
      "don't know if allah will forgive me",
      'feel disconnected from god because of my sins',
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
          'From the sunnah \u2014 the Prophet \uFDFA would say this and similar phrases over 100 times in a single gathering',
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
      "don't know why i'm here",
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
      'feel like allah is withholding from me',
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
          'O Constrictor, O Expander \u2014 spread over us from Your mercy.',
      source:
          'Supplication calling on Al-Qabid and Al-Basit together \u2014 used in moments of constriction to remember that both states are from Allah and both carry His mercy',
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
      "everyone else is moving forward and i'm stuck",
      'feel left behind in life',
      "frustrated that things aren't happening on my timeline",
      'bitter at someone who held me back',
      'feel like people are blocking my progress',
      'comparing my progress to others',
      'scared to take an opportunity',
      "feel like i'm not ready yet",
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
      "can't see god's plan in my hardship",
      'feel like life is falling apart',
      "don't understand why this is happening",
      'feel like god abandoned me',
      "going through pain and can't find the meaning",
      "struggling but can't see any good in it",
      'life feels unfair',
      'lost job or going through divorce',
      'harsh on myself',
      'harsh on others',
      'wonder if god even notices',
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
      "feeling like i don't deserve to ask allah",
      "jealous of other people's blessings",
      'transactional relationship with god',
      'feeling ungrateful',
      'wanting a child',
      'wanting something that feels impossible',
      "feeling like my deeds aren't enough to make dua",
      'struggling to love allah',
      'heart feels disconnected from worship',
      'going through the motions of prayer without feeling',
      'comparing yourself to others',
      'taking blessings for granted',
    ],
    coreTeaching:
        'Al-Wahhab is the Bestower of Gifts \u2014 the One who gives repeatedly and lavishly, expecting nothing in return. In Arabic, a single gift is just a gift. But wahab is one who gives over and over, or gives something so enormous that no return is possible. The foundation of faith is hub \u2014 love. And you cannot love Allah until you realize He loves you first. The disbeliever gets stuck at the blessing: imprisoned by what they received, never moving beyond it to the One who gave it. The believer uses every blessing as a window to see Al-Wahhab behind it. Every gift in your life \u2014 your spouse, your children, your job, the sunlight, the breath in your lungs \u2014 none of it was deserved. It was a hiba, a pure gift, with nothing asked in return. When you see blessings this way, entitlement dissolves into indebtedness, and indebtedness becomes love. This name is also the cure for jealousy: when you see someone blessed, instead of envy, you realize the same Al-Wahhab who gave them is the same One who can give you. You are simply next in line.',
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
  // ─────────────────────────────
  // 2026-05-13 CONTENT EXPANSION (52 new entries)
  //
  // Authored by Claude with verbatim sourcing from:
  //   - quran.com (Quran verses)
  //   - yaqeeninstitute.org (scholar quotes)
  //   - sunnah.com (hadith)
  //   - seekersguidance.org (scholarly tafsir)
  //
  // Per-Name provenance + flags in docs/qa/name-teaching-sources.md
  // and docs/qa/name-teaching-batches/batch-{1,2,3}.jsonl.
  //
  // SCHOLAR PASS REQUIRED before promoting to user-facing release.
  // Many entries are pure Quranic citation only; scholar may add
  // verified Yaqeen/SeekersGuidance scholar quotes for richness.
  // ─────────────────────────────

  NameTeaching(
    name: 'Ar-Raheem',
    arabic: 'الرَّحِيمُ',
    emotionalContext: [
      'feeling like your sins are too great to be forgiven',
      'ashamed to make dua after a long absence from allah',
      'grieving and wondering if allah still cares',
      'wanting to return to allah but feeling unworthy',
      'after a relapse into an old pattern',
      'feeling spiritually cold and distant',
      'longing for comfort after heartbreak',
    ],
    coreTeaching:
        'Ar-Raheem is the Most Merciful — the One whose mercy is specifically and actively directed at the believers in every moment. Classical scholars distinguished Ar-Rahman from Ar-Raheem: Ar-Rahman is the vast mercy that encompasses every creature, believer and disbeliever alike; Ar-Raheem is the particular, ongoing mercy reserved especially for those who turn to Him. The Prophet ﷺ himself was described by Allah with this same Name — Quran 9:128 says he is “raʾoofun raḥeem” with the believers — and Allah gave His prophet the Name of His own attribute as the highest compliment He could pay a human being. The Sahih hadith in both Bukhari and Muslim records that Allah created mercy in one hundred parts, kept ninety-nine with Himself, and sent down only one part to earth — and it is from that single part that all creatures show tenderness to one another, that a mare lifts her hoof to avoid her foal. All the mercy you have ever seen in this world — a mother’s love, a friend’s kindness, a stranger’s help — is one percent of what Allah kept for you. The Quran seals the call: “O My servants who have exceeded the limits against their souls! Do not lose hope in Allah’s compassion, for Allah certainly pardons all transgressions. He is indeed the All-Forgiving, Most Merciful.” (39:53) Ar-Raheem does not offer mercy as a reward for the deserving. He offers it as the nature of who He is. When you feel too far gone, that feeling is precisely the moment Ar-Raheem is waiting for you to call.',
    propheticStory:
        'After Adam (عليه السلام) and Hawwa were sent from the Garden, Allah did not leave them without a way back. He taught Adam words of repentance — and the verse records what happened next: “Then Adam was inspired with words ˹of prayer˺ by his Lord, so He accepted his repentance. Surely He is the Accepter of Repentance, Most Merciful.” (Quran 2:37) Notice the sequence: Allah initiated the words. Adam could not even find the right way to ask — so Ar-Raheem gave him the dua. That is the Name in action: mercy that does not wait for you to get it right on your own. The verse closes with two Names — At-Tawwab and Ar-Raheem — as if to say: the One who accepts your return is the same One who has always been merciful to you.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
      translation:
          'Our Lord! Grant us the good of this world and the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 (verbatim) — the dua of those who call on the Most Merciful for good in this life and the next',
    ),
  ),

  NameTeaching(
    name: 'Al-Malik',
    arabic: 'المَلِكُ',
    emotionalContext: [
      'feeling powerless when others seem to control your fate',
      'anxious about a decision that is out of your hands',
      'grieving the loss of status, a job, or a role that defined you',
      'crushed when someone in authority treated you unjustly',
      'fear of being forgotten or insignificant',
      'overwhelmed by systems and structures you cannot change',
      'longing for justice that the world has not given you',
    ],
    coreTeaching:
        'Al-Malik is the King — the One who holds absolute sovereignty over every kingdom, every government, every boardroom, and every home. Quran 20:114 declares: “Exalted is Allah, the True King!” The word “Haqq” (True) is not an intensifier; it is a contrast. Every other king is contingent — they depend on armies, consent, economics, and mortality. Al-Malik is the only one whose kingship requires nothing outside Himself. The scholar Ibn al-Qayyim al-Jawziyya wrote of divine sovereignty: “The value of the commodity is correlated to both the status of the buyer and the price. You are the commodity, and you are so valuable that Allah Himself is the buyer.” Under Al-Malik, your worth is not set by your employer, your family, or your culture — it is set by the King who purchased you at the price of His own paradise. Quran 3:26 records the supplication: “O Allah! Lord over all authorities! You give authority to whoever You please and remove it from who You please; You honour whoever You please and disgrace who You please — all good is in Your Hands. Surely You alone are Most Capable of everything.” This is not a passive observation; the verse is given as a command — “Say…” — which means Allah wanted it on every believer’s tongue. When authority crushes you or abandons you, the answer is not resignation. It is address: call on the One who controls all authority and ask Him to move.',
    propheticStory:
        'Quran 39:67 describes the Day of Resurrection: “They have not shown Allah His proper reverence — when on the Day of Judgment the whole earth will be in His Grip, and the heavens will be rolled up in His Right Hand. Glorified and Exalted is He above what they associate with Him!” The Prophet ﷺ explained this scene directly: Allah will hold the earth, fold the heaven with His right hand, and say, “I am the King: where are the kings of the earth?” (Sahih al-Bukhari 7382). The contrast is total — every human kingdom dissolves into the single reality of Al-Malik. The lesson for this life: the power someone holds over you is borrowed, temporary, and entirely subject to the One who owns all of it.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ',
      transliteration:
          "Rabbana la tuzigh quloobana ba'da idh hadaytana wa hab lana min ladunka rahmatan innaka anta al-Wahhab",
      translation:
          'Our Lord! Do not let our hearts deviate after You have guided us. Grant us Your mercy. You are indeed the Giver of all bounties.',
      source: 'Quran 3:8 (verbatim) — the supplication of those who anchor themselves before the True King, asking Him to keep their hearts aligned',
    ),
  ),

  NameTeaching(
    name: 'Al-Muʺmin',
    arabic: 'المُؤْمِنُ',
    emotionalContext: [
      'paralyzed by fear about the future',
      'feeling unsafe even in familiar places',
      'anxiety that will not leave despite no clear reason',
      'terrified of what you cannot control',
      'living with a threat you cannot make disappear',
      'heart racing at night with dread',
      'longing to feel safe and held',
    ],
    coreTeaching:
        'Al-Muʺmin is the Giver of Safety and the Faithful — the One who grants true security from fear and whose promises are absolutely trustworthy. The Name appears in the great verse of Surah al-Hashr (59:23), clustered with Al-Malik and Al-Quddus: “He is Allah — there is no god except Him: the King, the Most Holy, the All-Perfect, the Source of Serenity, the Watcher › of all‹, the Almighty, the Supreme in Might, the Majestic.” The Arabic “al-Muʺmin” carries two interlocked roots: “amn” (safety, security) and “iman” (faith, trust). He is the One who is safe to trust, and He is the One who gives safety. Jinan Yousef, in her Yaqeen article on Al-Muʺmin during times of crisis, draws on Ibn al-Qayyim’s concept of “rabt” (the strengthening of hearts): “This rabt includes granting the hearts patience and firmness, strengthening them, and supporting them with the light of faith, until they are able to patiently persevere.” (Ibn al-Qayyim, Madarij al-Salikin 3/68) This is what Al-Muʺmin does directly to the heart: He does not always remove the threatening thing; He makes the heart capable of enduring it. The security He gives is not circumstantial. The fire was real when Ibrahim (عليه السلام) was cast into it. Al-Muʺmin’s answer was not to remove Ibrahim from the situation but to command the fire: “Be cool and safe.” Security, when it comes from Al-Muʺmin, travels inward first.',
    propheticStory:
        'In Surah al-Hashr, after the expulsion of Banu al-Nadir, Allah reminds the believers who stayed in Medina that He is the source of all true security. The hypocrites had whispered promises of protection to Banu al-Nadir — “if you are driven out, we will go with you” (59:11) — but when the moment came, they abandoned them. Allah’s response culminates with the declaration of His names: “He is Allah — there is no god except Him: the King, the Most Holy, the All-Perfect, the Source of Serenity, the Watcher, the Almighty, the Supreme in Might, the Majestic.” (Quran 59:23) The human promises of protection evaporated; Al-Muʺmin’s faithfulness did not. His name appears in that verse to answer the question every person asks when a protector fails them: “Who is truly safe to trust?”',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ',
      transliteration:
          "Rabbana la tuzigh quloobana ba'da idh hadaytana wa hab lana min ladunka rahmatan innaka anta al-Wahhab",
      translation:
          'Our Lord! Do not let our hearts deviate after You have guided us. Grant us Your mercy. You are indeed the Giver of all bounties.',
      source: 'Quran 3:8 (verbatim) — the dua of those who ask Al-Muʺmin to hold their hearts steady when fear tries to pull them off course',
    ),
  ),

  NameTeaching(
    name: 'Al-Azeez',
    arabic: 'العَزِيزُ',
    emotionalContext: [
      'feeling humiliated by someone who had power over you',
      'stripped of dignity in front of others',
      'compromising your values to gain acceptance or status',
      'feeling like your self-worth depends on others’ approval',
      'defeated and made to feel small',
      'desperate for honor the world has withheld from you',
      'ashamed of weakness you cannot hide',
    ],
    coreTeaching:
        'Al-Azeez is the Almighty — the One who possesses ‘izza in its most complete sense. The Yaqeen article on this Name explains: “Although ʿizza is often directly translated as ‘power’ or ‘might,’ scholars provide a more nuanced definition of ‘dignified power.’ That is, no matter the extent of one’s power, it can only be classified as ʿizza if it is accompanied by dignity.” Al-Azeez communicates three aspects of might: power, independence, and dominion. He cannot be overpowered. He is self-sufficient from all creation. And He alone grants strength and honor to whom He wills. This matters because human beings chase ʿizza constantly — through status, wealth, relationships, and performance — and find it hollow or temporary when they reach it. The early companion Ibn al-Khaṭṭab (رضي الله عنه) said: “Verily, we were a disgraceful people and Allah honored us with Islam. If we seek honor from anything besides that with which Allah honored us, Allah will disgrace us.” (al-Mustadrak ‘ala al-Ṣaḥiḥayn 207) The only ʿizza that does not erode is the one that comes from standing under Al-Azeez. Quran 45:37 puts it precisely: “To Him belongs all Majesty in the heavens and the earth. And He is the Almighty, All-Wise.” All majesty belongs to Him — not a share, not a type, all of it. The honor you were denied by people was never theirs to give in the first place.',
    propheticStory:
        'When the Quraysh had driven the companions from their homes, stripped them of their wealth, and left them refugees in Abyssinia, the Prophet ﷺ did not counsel despair. He sent a message rooted in the certainty that Al-Azeez acts in history. The early Muslim Bilal ibn Saʿd wrote, as recorded in Hilyat al-Awliyaʼ 5/223: “Do not look at the smallness of the sin, but look at the greatness of the One whom you have sinned against.” The inverse applies equally: do not look at the smallness of the insult done to you, but look at the greatness of the One under whose authority it took place. History vindicated this: the same Quraysh who humiliated the companions later stood in Mecca as the Prophet ﷺ entered at its conquest and asked, “What do you think I will do to you?” They said, “A noble brother and the son of a noble brother.” He replied, “Go, for you are free.” The honor came not from their submission but from Al-Azeez’s decree. He dignifies whom He wills.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
      translation:
          'Our Lord! Grant us the good of this world and the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 (verbatim) — the dua of those who seek the goodness only Al-Azeez can grant, in this life and the next',
    ),
  ),

  NameTeaching(
    name: 'Al-Khaliq',
    arabic: 'الخَالِقُ',
    emotionalContext: [
      'feeling like your life has no design or purpose',
      'questioning whether you were made for anything good',
      'despair that things will ever come together',
      'feeling like a mistake — your existence, your choices, your body',
      'grief at something in your life that seems permanently broken',
      'searching for meaning in suffering that seems random',
      'wondering if there is any intention behind your being',
    ],
    coreTeaching:
        'Al-Khaliq is the Creator — the One who brings into existence from non-existence. The Quran presents Al-Khaliq in sequence with two other Names in Surah al-Hashr (59:24): “He is Allah: the Creator, the Inventor, the Shaper. He alone has the Most Beautiful Names. Whatever is in the heavens and the earth constantly glorifies Him. And He is the Almighty, All-Wise.” The three Names — Al-Khaliq, Al-Bariʼ, Al-Musawwir — describe a single arc of creation: Al-Khaliq determines what is called from non-existence into existence; Al-Bariʼ distinguishes and separates each thing into its unique form; Al-Musawwir fashions the visible appearance of what has been made. Jinan Yousef, writing in her Yaqeen paper on the Names sequence in Surah al-Hashr, describes Al-Khaliq as the One whose creative act is not a single event: “Al-Khaliq determines what is brought from non-existence to existence.” This is perpetual — every breath, every heartbeat, every new morning is an act of Al-Khaliq calling something into being that was not there before. The Quran 2:32 records the angels confessing: “Glory be to You! We have no knowledge except what You have taught us. You are truly the All-Knowing, All-Wise.” Even the angels, who witness creation directly, acknowledge that the act of making belongs to Allah alone. When your life feels purposeless or accidental, Al-Khaliq is the Name to call on — the One whose act of creating you was intentional, from nothing, at a moment of His choosing.',
    propheticStory:
        'The Quran invites us to reflect on the creation of the human being as one of the signs of Al-Khaliq’s precision. In Surah al-Hashr, three Names appear together — Al-Khaliq, Al-Bariʼ, Al-Musawwir — immediately after the verse about His overwhelming power. The placement is deliberate: it is the same Allah who commands armies of heaven that also shaped every feature of your face, the pattern of your fingerprints, the specific pitch of your voice. “He is Allah: the Creator, the Inventor, the Shaper. He alone has the Most Beautiful Names. Whatever is in the heavens and the earth constantly glorifies Him. And He is the Almighty, All-Wise.” (Quran 59:24) The word “perfecting” is built into the Name: the root of Khaliq connects to “measuring precisely.” Al-Khaliq does not create carelessly. He measured you before He made you.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِن ذُرِّيَّتِنَآ أُمَّةً مُّسْلِمَةً لَّكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَآ إِنَّكَ أَنتَ التَّوَّابُ الرَّحِيمُ',
      transliteration:
          "Rabbana waj'alna muslimayni laka wa min dhurriyyatina ummatan muslimatan laka wa arina manasikana wa tub 'alayna innaka anta at-Tawwab ar-Raheem",
      translation:
          'Our Lord! Make us both fully submit to You and from our descendants a nation that will submit to You. Show us our rituals, and turn to us in grace. You are truly the Accepter of Repentance, Most Merciful.',
      source: 'Quran 2:128 (verbatim) — Ibrahim and Ismail’s dua to the Creator asking Him to shape them and their descendants into surrender',
    ),
  ),

  NameTeaching(
    name: 'Al-Aleem',
    arabic: 'العَلِيمُ',
    emotionalContext: [
      'feeling completely misunderstood by everyone around you',
      'holding something private that no one else knows about',
      'praying with no words — just an ache you cannot name',
      'grieving something you cannot explain to others',
      'doing good in secret and wondering if it matters',
      'carrying a hidden burden that you cannot share',
      'feeling unseen in your struggle',
    ],
    coreTeaching:
        'Al-Aleem is the All-Knowing — the One whose knowledge is absolute, all-encompassing, and never dependent on what you say or show. The Quran 49:13 states: “Surely the most noble of you in the sight of Allah is the most righteous among you. Allah is truly All-Knowing, All-Aware.” Al-Aleem knows not just what is outward but what is within. Jinan Yousef, in her Yaqeen paper on the pairing of Allah’s Names, notes that while the Name Al-Aleem covers outward knowledge, it is paired with Al-Khabeer (All-Aware) to express comprehensive interior knowledge: “Al-Alim is He who knows what is outward, whereas al-Khabir is He who knows what is within.” When you do not have words for your pain, Al-Aleem already knows it. When your good deed goes unrecognized, Al-Aleem has recorded it. When your repentance is sincere but private, Al-Aleem has received it. The angels in Quran 2:32 could only say: “Glory be to You! We have no knowledge except what You have taught us. You are truly the All-Knowing, All-Wise.” Even the highest creation in existence acknowledged that knowledge belongs to Allah alone. Al-Aleem does not learn from witnesses. He is the witness. He does not need your confession to know your heart. He knew it before your heart was formed.',
    propheticStory:
        'When Hagar (عليه السلام) was left in the valley of Mecca with baby Ismail and no water, she ran between Safa and Marwa seven times, calling out into an empty desert. No one saw her. No one heard her. Yet Al-Aleem knew the exact moment, the exact depth of her thirst, the exact point of her desperation — and sent Jibril to strike the earth and open Zamzam. Quran 31:34 affirms: “Indeed, Allah alone has the knowledge of the Hour. He sends down the rain, and knows what is in the wombs. No soul knows what it will earn for tomorrow, and no soul knows in what land it will die. Surely Allah is All-Knowing, All-Aware.” Al-Aleem knew Hagar’s need before she voiced it. He knows yours.',
    dua: NameTeachingDua(
      arabic:
          'رَبِّ زِدْنِي عِلْمًا',
      transliteration: "Rabbi zidni 'ilma",
      translation: 'My Lord! Increase me in knowledge.',
      source: 'Quran 20:114 (verbatim) — the only dua the Quran records Allah commanding the Prophet ﷺ to say for himself; an appeal to Al-Aleem to share of what only He perfectly possesses',
    ),
  ),

  NameTeaching(
    name: 'Al-Muhaymin',
    arabic: 'المُهَيْمِنُ',
    emotionalContext: [
      'feeling like your life is spinning out of control',
      'anxious that no one is watching out for you',
      'overwhelmed by responsibilities and no one to depend on',
      'feeling abandoned and unguarded',
      'grief at the loss of someone who protected you',
      'navigating danger with no clear path forward',
      'longing for someone trustworthy to oversee your affairs',
    ],
    coreTeaching:
        'Al-Muhaymin is the Overseer, the Guardian, the One who holds all of creation under His watchful authority. The Name appears in the great Names sequence of Surah al-Hashr (59:23): “He is Allah — there is no god except Him: the King, the Most Holy, the All-Perfect, the Source of Serenity, the Watcher of all, the Almighty, the Supreme in Might, the Majestic.” Ibraheem Shakfeh, writing for SeekersGuidance, explains: “Al-Muhaymin means an overpowering authority.” It is not the watching of a spy but the watching of a guardian — the way a shepherd keeps every sheep in view at once, aware of the terrain, aware of what approaches. The Name contains the root of “amn” (safety) and carries the sense of one who gives safety by virtue of the completeness of their oversight. Imam Nawawi noted in his commentary on Sahih Muslim that Al-Muhaymin is among the Names that carry the definite article only for Allah — no human being can be fully Al-Muhaymin, because no human can hold all affairs in view simultaneously without sleep, distraction, or limit. Al-Muhaymin sees not just what is happening but what could happen, not just where you are but where every force that could reach you is moving. There is no gap in His oversight. What feels like chaos to you is entirely within His field of view.',
    propheticStory:
        'After the battle of Uhud, when the Muslims suffered unexpected defeat and the Prophet ﷺ himself was injured, it was a moment where every human form of protection had partially failed. Yet in Surah al-Hashr, revealed in the context of another military and political crisis, Allah introduces Himself as Al-Muhaymin immediately after Al-Muʺmin (the Source of Security) — as if to say: the security I give comes from the fact that I am the complete Overseer. “He is Allah — there is no god except Him: the King, the Most Holy, the All-Perfect, the Source of Serenity, the Watcher of all, the Almighty, the Supreme in Might, the Majestic.” (Quran 59:23) Al-Muhaymin’s oversight did not fail at Uhud. The outcome was within His plan, His wisdom, and His view. He was watching.',
    dua: NameTeachingDua(
      arabic:
          'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: 'Hasbunallahu wa niʿmal-wakeel',
      translation: 'Allah is sufficient for us, and He is the best Protector.',
      source: 'Quran 3:173 (verbatim) — the words the companions said when told that enemies had massed against them; the response of those who know Al-Muhaymin is watching',
    ),
  ),

  NameTeaching(
    name: 'Al-Mutakabbir',
    arabic: 'المُتَكَبِّرُ',
    emotionalContext: [
      'overwhelmed by arrogant people who seem untouchable',
      'feeling small in front of pride that refuses to bend',
      'crushed by a tyrant, a bully, or an unjust system',
      'humbled by your own helplessness before those with power',
      'struggling with ego that keeps getting in the way of healing',
      'searching for the right scale — to see the truly great',
      'anger at injustice that no human being is stopping',
    ],
    coreTeaching:
        'Al-Mutakabbir is the Majestic, the Supremely Great — the One for whom greatness is a rightful attribute, not a delusion. This Name is unique: in a human being, “takabbur” (arrogance, self-magnification) is a sin. The Prophet ﷺ defined the sin in Sahih Muslim 91a: "Pride is disdaining the truth (out of self-conceit) and contempt for the people" (بَطَرُ الْحَقِّ وَغَمْطُ النَّاسِ). Yet Allah names Himself Al-Mutakabbir — because His greatness is not a distortion of reality. It is reality. Quran 59:23 lists this Name at the summit of a sequence: “He is Allah — there is no god except Him: the King, the Most Holy, the All-Perfect, the Source of Serenity, the Watcher of all, the Almighty, the Supreme in Might, the Majestic.” Quran 45:37 confirms: “To Him belongs all Majesty in the heavens and the earth. And He is the Almighty, All-Wise.” The theological point is liberating: if Al-Mutakabbir holds all true Greatness, then every human being who inflates themselves is borrowing what they do not own. Iblis was destroyed by taking what belongs only to Al-Mutakabbir — when Allah asked him “What prevented you from prostrating to what I created with My Own Hands? Did you just become proud? Or have you always been arrogant?” (Quran 38:75). The one who stands before Al-Mutakabbir with humility is freed from needing to be great in anyone else’s eyes.',
    propheticStory:
        'When Iblis refused to prostrate to Adam, Allah asked him directly: “O Iblis! What prevented you from prostrating to what I created with My Own Hands? Did you just become proud? Or have you always been arrogant?” (Quran 38:75) The word used there — “akbarta” — shares the root with Al-Mutakabbir. Iblis tried to claim greatness: “I am better than him. You created me from fire and created him from clay.” His logic seemed internally consistent. But he failed to see that greatness is not self-assigned under Al-Mutakabbir. The One who holds all Majesty is the only One who can assign worth. Iblis’ arrogance was not just a moral failure — it was a theological error. He forgot who was the real Mutakabbir in the room. Every human bully makes the same mistake.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ',
      transliteration:
          "Rabbana la tu'akhidhna in naseena aw akhta'na rabbana wa la tahmil 'alayna isran kama hamaltahu 'ala alladhina min qablina rabbana wa la tuhammilna ma la taqata lana bihi wa'fu 'anna waghfir lana warhamna anta mawlana fansurna 'ala al-qawm il-kafirin",
      translation:
          'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one You placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our only Guardian. So grant us victory over the disbelieving people.',
      source: 'Quran 2:286 (verbatim excerpt) — the dua of those who submit to Al-Mutakabbir’s absolute greatness and ask for relief from burdens only He can remove',
    ),
  ),

  NameTeaching(
    name: 'Al-Bari',
    arabic: 'الْبَارِئُ',
    emotionalContext: [
      'feeling broken beyond repair',
      'shame after falling back into the same sin',
      'wanting to start over but not knowing how',
      'feeling defective or malformed',
      'after a relapse',
      'after losing your sense of self',
      'feeling like nothing you build holds together',
    ],
    coreTeaching:
        'Al-Bari is the Originator — the One who shapes each created thing into its distinct form, none of them duplicates. The Yaqeen scholar Jinan Yousef writes in her tafsir of Surah al-Hashr that “Al-Khaliq determines what is brought from non-existence to existence, Al-Bariʼ distinguishes creation from each other by specifying their different forms, and Al-Musawwir makes the visual manifestation of what He has created and produced.” The three Names move in sequence: He calls you into being, He gives you a form unlike anyone else’s, then He fashions the details. When you feel broken or like you have ruined what He made of you, Al-Bari is the Name to call on — He is still the One who originates, and He can re-originate, re-shape, re-form. The first time He proved this in scripture was the golden calf: when Bani Israel committed shirk against the very God who had freed them, Moses (عليه السلام) did not tell them to find another god — he told them, “Turn in repentance to your Bariʼ” (Quran 2:54). The Name Allah used for receiving them back was not Al-Ghafur, not Ar-Rahman, but Al-Bari — as if to say: the One who made you is the only One who can make you again.',
    propheticStory:
        'After Allah delivered Bani Israel from Pharaoh, parted the sea for them, and asked Moses (عليه السلام) to leave for the Tablets, the people made a golden calf and worshipped it within forty days. When Moses returned and saw what they had done, he confronted them: “O my people! Surely you have wronged yourselves by worshipping the calf, so turn in repentance to your Bariʼ, and execute the calf-worshippers among yourselves. That is best for you in the sight of your Bariʼ.” (Quran 2:54) The verse uses the Name البارئ twice — once for whom the repentance is directed to, and once for whose sight matters. Allah named Himself Al-Bari in that moment of national failure to remind them: the One who originated you is the only One who can re-originate you. The verse closes: “Then He accepted your repentance. Surely He is the Accepter of Repentance, Most Merciful.”',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      transliteration:
          "Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakoonanna mina'l-khasireen",
      translation:
          'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
      source: 'Quran 7:23 (verbatim) — Adam’s dua of repentance, paired thematically with the call to one’s Bariʼ in Quran 2:54',
    ),
  ),

  NameTeaching(
    name: 'Al-Musawwir',
    arabic: 'المُصَوِّرُ',
    emotionalContext: [
      'feeling ugly, inadequate, or ashamed of your body',
      'comparing yourself to others and always coming up short',
      'grief over a physical limitation or condition',
      'struggling with self-image after something changed your appearance',
      'feeling like your face or form does not reflect who you are inside',
      'longing to be seen as beautiful',
      'body image pain that no one around you understands',
    ],
    coreTeaching:
        'Al-Musawwir is the Shaper of Forms — the One who fashioned every face, every fingerprint, every curve and line of every human being who has ever existed. Quran 59:24 presents this Name as the third in a divine creative sequence: “He is Allah: the Creator, the Inventor, the Shaper. He alone has the Most Beautiful Names. Whatever is in the heavens and the earth constantly glorifies Him. And He is the Almighty, All-Wise.” Jinan Yousef writes in her Yaqeen paper on the Names of Surah al-Hashr that “Al-Musawwir makes the visual manifestation of what He has created and produced” — the final act of a three-part process that moves from conception (Al-Khaliq) through individuation (Al-Bariʼ) to visible form (Al-Musawwir). Your face is not an accident or a default. It is a deliberate artistic act by Al-Musawwir. Quran 3:6 affirms this directly: “He is the One Who shapes you in the womb as He wills.” The Arabic “kaifa yasha’u” — “as He wills” — is not a concession to randomness. It is an assertion of intentional choice. Every feature of your form was chosen by Al-Musawwir before you were born. When you look in the mirror and feel inadequate, you are looking at the work of the Most Beautiful Names (al-Asmaʼ al-Husna). Al-Musawwir made you as a reflection of His creative will.',
    propheticStory:
        'In Surah Ali ‘Imran, Allah reminds the believers that before any of us entered the world, Al-Musawwir was already at work: “He is the One Who shapes you in the womb as He wills. There is no god except Him — the Almighty, All-Wise.” (Quran 3:6) The context of this verse is the story of Maryam (عليه السلام) and Zakariyya (عليه السلام) — both of whom received impossible children from Al-Musawwir’s direct act. Maryam received Isa without a father. Zakariyya received Yahya from a barren wife. The point: the constraints that govern human reproduction do not govern Al-Musawwir. He shapes as He wills. The form He gave you was not limited by biology — it was chosen.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِن ذُرِّيَّتِنَآ أُمَّةً مُّسْلِمَةً لَّكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَآ إِنَّكَ أَنتَ التَّوَّابُ الرَّحِيمُ',
      transliteration:
          "Rabbana waj'alna muslimayni laka wa min dhurriyyatina ummatan muslimatan laka wa arina manasikana wa tub 'alayna innaka anta at-Tawwab ar-Raheem",
      translation:
          'Our Lord! Make us both fully submit to You and from our descendants a nation that will submit to You. Show us our rituals, and turn to us in grace. You are truly the Accepter of Repentance, Most Merciful.',
      source: 'Quran 2:128 (verbatim) — Ibrahim’s prayer to the Shaper of Forms, asking that even his descendants be shaped into surrender',
    ),
  ),

  NameTeaching(
    name: 'Ash-Shakur',
    arabic: 'الشَّكُورُ',
    emotionalContext: [
      'feeling like your efforts go unnoticed and unappreciated',
      'burned out from giving without any return',
      'grief that your good deeds do not seem to count',
      'exhausted from invisible labor no one thanks you for',
      'struggling to be grateful when life feels ungrateful to you',
      'wondering if small acts of worship even matter',
      'longing to be seen for what you quietly give',
    ],
    coreTeaching:
        'Ash-Shakur is the Most Appreciative — the One who not only receives gratitude but Himself expresses gratitude to His servants by multiplying the reward of every good deed many times over. Quran 35:30 states: “so that He will reward them in full and increase them out of His grace. He is truly All-Forgiving, Most Appreciative.” The Name is startling: God is grateful? Ibn al-Qayyim al-Jawziyya defines shukr as expressed through the heart (feelings of love and submissiveness), the tongue (acknowledgment and praise), and acts of devotion. When Allah is Ash-Shakur, it means He appreciates your deed from all three of these directions: He loves it, He records it, and He multiplies it. The Yaqeen article on shukr explains: “When Our Creator embodies shukr, it takes on the form of appreciation and results in His multiplying our little deeds many times over.” Surah Sabaʼ (34:13) closes with one of the most sobering phrases in the Quran: “Only a few of My servants are truly grateful.” The word used there — al-Shakur — is the same root as Allah’s own Name. He is the supremely grateful One; and in His sight, gratitude is rare and precious. The invisible labor you do, the prayer no one saw, the kindness no one thanked you for — Ash-Shakur has received all of it and is already preparing its return.',
    propheticStory:
        'Allah commanded the family of Dawud (عليه السلام) — a dynasty of prophets, given extraordinary gifts of knowledge, kingship, and spiritual insight — to work with those gifts in a specific way: “They made for him whatever he desired of sanctuaries, statues, basins as large as reservoirs, and cooking pots fixed into the ground. ‘Work gratefully, O family of David!’ Only a few of My servants are truly grateful.” (Quran 34:13) Notice the command: “Work gratefully.” Gratitude was not an emotion to feel after the work was done. It was the posture of the work itself. Sulayman (عليه السلام) understood this. His dua in Quran 27:19 captures it: “My Lord! Inspire me to always be thankful for Your favours which You have blessed me and my parents with, and to do good deeds that please You. Admit me, by Your mercy, into the company of Your righteous servants.” Ash-Shakur gave him everything — and Sulayman responded by asking for the capacity to be grateful for it. That is the posture Ash-Shakur calls all of us into.',
    dua: NameTeachingDua(
      arabic:
          'رَبِّ أَوْزِعْنِىٓ أَنْ أَشْكُرَ نِعْمَتَكَ ٱلَّتِىٓ أَنْعَمْتَ عَلَىَّ وَعَلَىٰ وَٰلِدَىَّ وَأَنْ أَعْمَلَ صَـٰلِحًا تَرْضَىٰهُ وَأَدْخِلْنِى بِرَحْمَتِكَ فِى عِبَادِكَ ٱلصَّـٰلِحِينَ',
      transliteration:
          "Rabbi awzi'ni an ashkura ni'mataka allati an'amta 'alayya wa 'ala walidayya wa an a'mala salihan tardahu wa adkhilni birahmatika fi 'ibadika as-saliheen",
      translation:
          'My Lord! Inspire me to always be thankful for Your favours which You have blessed me and my parents with, and to do good deeds that please You. Admit me, by Your mercy, into the company of Your righteous servants.',
      source: 'Quran 27:19 (verbatim excerpt) — Sulayman’s dua to Ash-Shakur; a prayer that asks for the gift of gratitude itself from the One who is Most Appreciative',
    ),
  ),

  NameTeaching(
    name: 'Al-Hafeez',
    arabic: 'الحَفِيظُ',
    emotionalContext: [
      'terrified something will happen to someone you love',
      'hypervigilant and exhausted from trying to protect everyone',
      'fear of loss that keeps you awake at night',
      'grief after failing to protect someone who needed you',
      'feeling alone and without anyone watching out for you',
      'dread of what could go wrong that you cannot prevent',
      'sending someone you love into danger you cannot control',
    ],
    coreTeaching:
        'Al-Hafeez is the Preserver, the Keeper, the One who guards every soul, every secret, and every deed with absolute vigilance. Quran 86:4 states: “There is no soul without a vigilant angel recording everything.” But the protection of Al-Hafeez is not just through angels — He Himself is the Guardian of the heavens and the earth without fatigue. The Name appears explicitly in Quran 11:57, where the prophet Hud (عليه السلام) says: “My Lord will replace you with others. You are not harming Him in the least. Indeed, my Lord is a vigilant Keeper over all things.” The Arabic root h-f-z encompasses three dimensions: preserving from harm, recording and remembering, and guarding with active attentiveness. Al-Hafeez does all three simultaneously for every creature at every moment. Yaʺqub (عليه السلام) understood this when his sons asked to take Binyamin to Egypt. He had already lost Yusuf. He could not bear another loss. But he also knew where real protection resided. He said: “Should I trust you with him as I once trusted you with his brother? But only Allah is the best Protector, and He is the Most Merciful of the merciful.” (Quran 12:64) That declaration — “Allahu khayrun hafidhan” — was not resignation. It was the most radical act of trust: to hand the one you love to Al-Hafeez, because you have finally admitted that you were never the real protector to begin with.',
    propheticStory:
        'When Yaʺqub (عليه السلام) sent his son Binyamin to Egypt with his other sons, he was sending the last thing that connected him to Yusuf — the same sons who had brought back a shirt stained with false blood. He had every human reason to say no. Yet his answer was: “Should I trust you with him as I once trusted you with his brother ˹Joseph˺? But only Allah is the best Protector, and He is the Most Merciful of the merciful.” (Quran 12:64) The verse does not record Yaʺqub as having certainty about the outcome. He did not know Yusuf was alive. He did not know Binyamin would return. What he knew was the Name: Al-Hafeez. That was enough. He released his grip. Al-Hafeez kept Binyamin and, in doing so, restored Yusuf.',
    dua: NameTeachingDua(
      arabic:
          'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: 'Hasbunallahu wa niʿmal-wakeel',
      translation: 'Allah is sufficient for us, and He is the best Protector.',
      source: 'Quran 3:173 (verbatim) — the words of those who entrust what they love to Al-Hafeez, the only Keeper who never sleeps',
    ),
  ),

  NameTeaching(
    name: 'Ar-Raqeeb',
    arabic: 'الرَّقِيبُ',
    emotionalContext: [
      'feeling invisible and completely unseen by anyone',
      'doing good in private and wondering if it matters',
      'guilt about private sins no one else knows',
      'fear of being exposed',
      'longing for someone who truly knows what you carry in secret',
      'feeling that your inner life goes unwitnessed',
      'struggling with what you do when no one is watching',
    ],
    coreTeaching:
        'Ar-Raqeeb is the Watchful — the One who sees everything without exception: every secret act, every hidden intention, every thought before it becomes a word. Dr. Omar Suleiman, reflecting on this Name in Yaqeen’s series “The Name I Need,” teaches: “Being watched by Allah through the name Ar-Raqeeb isn’t something to fear, but something that protects you. It means that Allah sees you completely — not just your actions, but your private struggles; not just your mistakes, but your intentions.” Quran 4:1 closes with this Name in one of the most weighty reminders in the Quran: “O humanity! Be mindful of your Lord Who created you from a single soul, and from it He created its mate, and through both He spread countless men and women. And be mindful of Allah — in Whose Name you appeal to one another — and honour family ties. Surely Allah is ever Watchful over you.” The placement matters: the verse covers the rights of families, of orphans, of those who cannot advocate for themselves. Ar-Raqeeb is invoked precisely where human oversight fails — in private relationships, in hidden dealings, in what people do when no one else is watching. And Isa (عليه السلام) invoked the same Name on the Day of Judgment: “And You are a Witness over all things.” (Quran 5:117) If the entirely sinless Isa acknowledged Ar-Raqeeb’s watchfulness as comfort, not threat, then so can we.',
    propheticStory:
        'On the Day of Judgment, Isa (عليه السلام) will be asked whether he commanded people to take him and his mother as gods. His answer, recorded in Quran 5:117, invokes Ar-Raqeeb as his witness: “I never told them anything except what You ordered me to say: ‘Worship Allah — my Lord and your Lord!’ And I was witness over them as long as I remained among them. But when You took me, You were the Witness over them — and You are a Witness over all things.” The word translated “Witness” — “rasheed” / “raqeeb” in classical tafsir — is Ar-Raqeeb’s domain. Isa could not watch over the believers after his lifting. But Ar-Raqeeb never looked away. Every hidden act of sincerity in those years was witnessed by Him.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ',
      transliteration:
          "Rabbana la tu'akhidhna in naseena aw akhta'na rabbana wa la tahmil 'alayna isran kama hamaltahu 'ala alladhina min qablina rabbana wa la tuhammilna ma la taqata lana bihi wa'fu 'anna waghfir lana warhamna anta mawlana fansurna 'ala al-qawm il-kafirin",
      translation:
          'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one You placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our only Guardian. So grant us victory over the disbelieving people.',
      source: 'Quran 2:286 (verbatim excerpt) — the prayer of those who know Ar-Raqeeb sees every mistake and ask Him to pardon rather than judge what He has witnessed',
    ),
  ),

  NameTeaching(
    name: 'Al-Khafid',
    arabic: 'الخَافِضُ',
    emotionalContext: [
      'watching arrogant people succeed while the humble struggle',
      'feeling brought low by circumstances you did not choose',
      'anger at power structures that crush the small',
      'confused about why allah allows the proud to flourish',
      'humbled by failure after great confidence',
      'fear that your standing will never recover',
      'wondering if lowliness is a punishment',
    ],
    coreTeaching:
        'Al-Khafid is the Abaser — the One who lowers whom He wills, when He wills, by His wisdom and authority. This Name always comes paired in Islamic tradition with Ar-Rafiʼ (the Exalter) because neither makes full sense without the other: the same hand that lowers one can raise another, and often raises the very one it lowered. Quran 56:1-3 describes the Day of Resurrection: “When the Inevitable Event takes place — then no one can deny it has come — it will debase some and elevate others.” The word “khafidah” (debasing) is from the same root as Al-Khafid. On that Day, the hierarchies of this world will reverse: those who made themselves great will be lowered; those who were humble and patient will be raised. The practical wisdom of the Name is this: do not worship your current status, high or low, because Al-Khafid is the One who holds both possibilities. Every throne in history has been brought low. Every Pharaoh who was not lowered in life was lowered in death. Quran 3:26 records this as the divine prerogative: “You honour whoever You please and disgrace who You please.” The one who grasps Al-Khafid stops measuring their worth by where they stand in the world’s order — because only Allah’s order is permanent.',
    propheticStory:
        'Quran 56 opens with the name of the Day of Resurrection: “Al-Waqiʿah” — the Inevitable Event. And then immediately describes its defining action: “When the Inevitable Event takes place — then no one can deny it has come — it will debase ˹some˺ and elevate ˹others˺.” (Quran 56:1-3) Classical tafsir describes this as the final and permanent operation of Al-Khafid Ar-Rafiʼ: the lowering and raising that this life hints at will be made absolute and irreversible. Pharaoh, who called himself god, will be in the lowest depths. The slave Bilal (رضي الله عنه), who was dragged across hot sand for saying “Ahad, Ahad” (One, One), will be among the raised. Al-Khafid lowered the proud and Al-Rafiʼ raised the patient. The world’s record was reversed. It always is.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
      translation:
          'Our Lord! Grant us the good of this world and the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 (verbatim) — the dua of those who submit their station in this world to Al-Khafid, asking Him for goodness in both realms rather than clinging to worldly rank',
    ),
  ),

  NameTeaching(
    name: 'Ar-Rafiʼ',
    arabic: 'الرَّافِعُ',
    emotionalContext: [
      'feeling stuck at the bottom with no way up',
      'overlooked for recognition you deserve',
      'grief at a fall from which recovery seems impossible',
      'desperate for elevation after humiliation',
      'wondering if your status will ever change',
      'exhausted from being underestimated',
      'longing to matter in a world that has passed you over',
    ],
    coreTeaching:
        'Ar-Rafiʼ is the Exalter — the One who raises whom He wills by His grace, in this life and in the next. Quran 40:15 describes Allah as “Rafiʿu ad-darajat” — “Highly Exalted in rank, Lord of the Throne.” He who is Himself the highest in rank is the One who raises others. Quran 58:11 teaches the mechanism: “Allah will elevate those of you who are faithful, and those gifted with knowledge in rank.” Not status by birth, not rank by wealth — but elevation by faith and knowledge. The Prophet ﷺ’s companions understood this in their bones: Bilal (رضي الله عنه) was a slave whom Quraysh tried to crush under hot stones in the desert. Ar-Rafiʼ raised him to be the first muʼadhdhin of Islam, so that the call to prayer — his voice — would be heard five times a day until the end of time. ʿUmar ibn al-Khaṭṭab (رضي الله عنه) said: “Verily, we were a disgraceful people and Allah honored us with Islam. If we seek honor from anything besides that with which Allah honored us, Allah will disgrace us.” (al-Mustadrak ‘ala al-Ṣaḥiḥayn 207) The logic of Ar-Rafiʼ is inverse to the world’s logic: the world elevates the proud. Ar-Rafiʼ elevates those who submitted. Quran 56:3 announces: “It will debase some and elevate others.” The raising belongs entirely to Al-Rafiʼ — and His elevation is the only kind that lasts.',
    propheticStory:
        'After the Battle of Badr, when seventy leaders of Quraysh were killed and seventy captured, the Prophet ﷺ went to speak to the bodies of the slain enemies at the well of Qalb. Abu Jahl — the man who had tortured Bilal in the desert — was among them. Bilal had been the slave; Abu Jahl had been the master. Ar-Rafiʼ reversed the order permanently. Meanwhile, Bilal was the one who announced the victory of Islam with the adhan from the roof of the Kaʻah at the conquest of Mecca — the same voice that had been beaten into silence was the one Al-Rafiʼ chose to ring across the sacred city. Quran 58:11 is the divine principle behind that story: “O believers! When you are told to make room in gatherings, then do so. Allah will make room for you. And if you are told to rise, then do so. Allah will elevate those of you who are faithful, and those gifted with knowledge in rank.”',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
      translation:
          'Our Lord! Grant us the good of this world and the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 (verbatim) — the supplication of those who trust Ar-Rafiʼ with their station in both worlds, asking for elevation that only He can grant',
    ),
  ),

  NameTeaching(
    name: 'Al-Muzill',
    arabic: 'المُذِلُّ',
    emotionalContext: [
      'watching injustice go unpunished for too long',
      'anger that the proud and arrogant seem untouchable',
      'grief at seeing the righteous brought low by the corrupt',
      'feeling trapped by a tyrant who has not yet fallen',
      'struggling with ego that allah seems to keep deflating',
      'fear of your own arrogance returning after you worked to remove it',
      'wanting to understand why allah allows some disgrace',
    ],
    coreTeaching:
        'Al-Muzill is the One who abases and brings low — whose act of disgracing is an expression of His wisdom, justice, and sovereignty. Unlike human humiliation, which is often malicious or arbitrary, Al-Muzill’s act of bringing low is never random and never unjust. Quran 3:26 makes this explicit: “O Allah! Lord over all authorities! You give authority to whoever You please and remove it from who You please; You honour whoever You please and disgrace who You please — all good is in Your Hands. Surely You alone are Most Capable of everything.” The key phrase is “all good is in Your Hands” (biyadika al-khayr) — placed immediately after the act of disgracing. Even Al-Muzill’s lowering is an act of khayr (good), whether it is apparent to us or not. History is full of this: Pharaoh was disgraced. Nimrod was disgraced. Abu Jahl was disgraced. Every tyrant who refused to bow to Allah was brought low by Al-Muzill, not arbitrarily, but as a completion of divine justice. The Name also governs something interior: when a believer grows arrogant, Al-Muzill sometimes brings a test that strips away pride — not as punishment, but as mercy. Quran 17:37 warns: “And do not walk on the earth arrogantly. Surely you can neither crack the earth nor stretch to the height of the mountains.” Al-Muzill does not need to be invoked as a threat. He is simply the One who ensures that no created being maintains false greatness permanently.',
    propheticStory:
        'Pharaoh declared “Ana rabbukum al-aʿla” — “I am your highest lord” (Quran 79:24) — the most brazen act of taking what belongs to Al-Mutakabbir and Al-Muzill. His punishment was designed to match the crime: he was not killed in a palace or in battle. He was drowned in the same sea that Allah parted for the very people Pharaoh had enslaved. The Quran preserves his body as a sign: “Today We will preserve your body so that you may be a sign for those who come after you.” (Quran 10:92) Al-Muzill’s act of abasement did not end at Pharaoh’s death — it became eternal testimony. The verse in Quran 3:26, “You disgrace who You please,” is not a warning to fear randomly. It is the assurance that the proud will not be exempt. Every believer who has been wronged by a tyrant carries that verse as a promise.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ',
      transliteration:
          "Rabbana la tu'akhidhna in naseena aw akhta'na rabbana wa la tahmil 'alayna isran kama hamaltahu 'ala alladhina min qablina rabbana wa la tuhammilna ma la taqata lana bihi wa'fu 'anna waghfir lana warhamna anta mawlana fansurna 'ala al-qawm il-kafirin",
      translation:
          'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one You placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our only Guardian. So grant us victory over the disbelieving people.',
      source: 'Quran 2:286 (verbatim excerpt) — the prayer that protects against the pride that invites Al-Muzill’s correction, and asks for mercy before judgment comes',
    ),
  ),

  NameTeaching(
    name: 'Al-Khabeer',
    arabic: 'الخَبِيرُ',
    emotionalContext: [
      'feeling like no one understands your situation from the inside',
      'making a decision with incomplete information and needing reassurance',
      'grief that the full truth of what you experienced will never be known',
      'carrying a complexity that others oversimplify',
      'anxious about consequences you cannot fully calculate',
      'longing for someone who truly knows what you have been through',
      'trying to make sense of a situation that defies easy explanation',
    ],
    coreTeaching:
        'Al-Khabeer is the All-Aware — the One who possesses deep, interior, experiential knowledge of all things. Where Al-Aleem (the All-Knowing) describes breadth of knowledge, Al-Khabeer describes depth of awareness. Jinan Yousef, in her Yaqeen paper on the pairing of Allah’s Names, notes: “Al-Alim is He who knows what is outward, whereas al-Khabir is He who knows what is within.” The word “khabeer” shares a root with “khibra” — expertise, the knowledge that comes from being inside a thing rather than observing it from outside. Al-Khabeer is not just aware of your situation — He is aware of it from within. Quran 49:13 places both Names together at the end of the verse about human dignity: “Surely the most noble of you in the sight of Allah is the most righteous among you. Allah is truly All-Knowing, All-Aware.” Quran 27:88 shows Al-Khabeer’s awareness extending to the fabric of creation itself: “Now you see the mountains, thinking they are firmly fixed, but they are travelling just like clouds. That is the design of Allah, Who has perfected everything. Surely He is All-Aware of what you do.” Everything that appears solid and fixed is moving within His awareness. Quran 11:1 opens Surah Hud with this reassurance: “This is a Book whose verses are well perfected and then fully explained. It is from the One Who is All-Wise, All-Aware.” The Book itself is evidence of Al-Khabeer: every verse fits precisely because its Author knows everything from within.',
    propheticStory:
        'Surah al-Mulk closes with a rhetorical question that anchors the entire meaning of Al-Khabeer: “Say, ‘Have you considered: if your water was to dry up, who then could bring you flowing water?’” (Quran 67:30) The answer implied is: only Al-Khabeer, who knows where every drop of water in the earth’s depths has traveled, where it waits, and when it should rise. He does not observe water from a distance — He is aware of it from within the rock. This is what Quran 31:34 means when it says: “Indeed, Allah alone has the knowledge of the Hour. He sends down the rain, and knows what is in the wombs. No soul knows what it will earn for tomorrow, and no soul knows in what land it will die. Surely Allah is All-Knowing, All-Aware.” The things Al-Khabeer knows are precisely the things that are most hidden from human beings — the future, what is in the womb, the hour of death. He knows them not from calculation but from being the One who holds them.',
    dua: NameTeachingDua(
      arabic:
          'رَبِّ زِدْنِي عِلْمًا',
      transliteration: "Rabbi zidni 'ilma",
      translation: 'My Lord! Increase me in knowledge.',
      source: 'Quran 20:114 (verbatim) — an appeal to Al-Khabeer, the One who possesses interior knowledge of all things, to share of that depth with us',
    ),
  ),

  NameTeaching(
    name: 'Al-Azeem',
    arabic: '\u0627\u0644\u0652\u0639\u064e\u0638\u0650\u064a\u0645\u064f',
    emotionalContext: [
      'overwhelmed by a problem that feels too big to solve',
      'paralysed by anxiety about the future',
      'crushed under pressure from every direction',
      'suffering feels unbearable and endless',
      'lost sight of how large allah is compared to your troubles',
      'desperate for something greater than yourself to hold onto',
    ],
    coreTeaching:
        'Al-Azeem is the Tremendous — the One whose Greatness surpasses every category of greatness the human mind can conceive. The word \u02bf\u1e93aẓīm in Arabic carries a weight that the English "great" cannot hold: it speaks of magnitude so absolute that nothing else can be measured beside it. Ibn Abbās narrated that the Prophet \ufdfa recited these words in every moment of distress: "Lā ilāha illā Allāh al-ʿAẓīm al-Ḥalīm, lā ilāha illā Allāh Rabb al-ʿArsh al-ʿAẓīm, lā ilāha illā Allāh Rabb al-samāwāt wa-Rabb al-arḍ wa-Rabb al-ʿArsh al-Karīm" — None has the right to be worshipped but Allah, the Tremendous, the Most Forbearing; None has the right to be worshipped but Allah, Lord of the Tremendous Throne; None has the right to be worshipped but Allah, Lord of the Heavens and Lord of the Earth and Lord of the Noble Throne (Ṣaḥīḥ al-Bukhārī 6346). The scholar Jinan Yousef, in her Yaqeen Institute paper on al-Ḥalīm, highlights the theology embedded in this supplication: "He is the Majestic, the Lord of the heavens and of the Throne, and therefore He is far greater than any problem we are facing." This is the medicine: when your calamity feels immovable, you are measuring it against yourself — measure it instead against Al-Azeem, and it shrinks to its true size. Allāh closes Āyat al-Kursī — the greatest verse in the Quran — with His name: "wa-huwa al-ʿAliyy al-ʿAẓīm" (Quran 2:255). After describing His Throne encompassing the heavens and the earth, He names Himself Al-Azeem. He is not merely larger than your pain. He is larger than the entire cosmos. Your grief is real. But it fits inside the palm of Al-Azeem.',
    propheticStory:
        'Ibn ʿAbbās \u0631\u0636\u064a \u0627\u0644\u0644\u0647 \u0639\u0646\u0647 reported that whenever the Prophet \ufdfa was struck by distress he would say: "Lā ilāha illā Allāh al-ʿAẓīm al-Ḥalīm, lā ilāha illā Allāh Rabb al-ʿArsh al-ʿAẓīm, lā ilāha illā Allāh Rabb al-samāwāt wa-Rabb al-arḍ wa-Rabb al-ʿArsh al-Karīm." (Ṣaḥīḥ al-Bukhārī 6346). He did not reach for comfort or distraction first — he reached for magnitude. He named the One who is larger than the problem before naming the problem to anyone. The Quran likewise closes Sūrat al-Wāqiʿah — a sūrah about the Day of Resurrection and the fates of humanity — with the command: "Fa-sabbiḥ bi-sm Rabbika al-ʿAẓīm" — "So glorify the Name of your Lord, the Greatest" (Quran 56:96). After confronting death, judgment, and eternity, the answer is not theology — it is glorification of the One who stands over all of it.',
    dua: NameTeachingDua(
      arabic: 'لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَوَاتِ وَرَبُّ الأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ',
      transliteration: "La ilaha illa Allahu al-'Azeem al-Haleem, la ilaha illa Allahu Rabb al-'Arsh al-'Azeem, la ilaha illa Allahu Rabb al-samawati wa Rabb al-ard wa Rabb al-'Arsh al-Kareem",
      translation: 'None has the right to be worshipped but Allah, the Tremendous, the Most Forbearing. None has the right to be worshipped but Allah, Lord of the Tremendous Throne. None has the right to be worshipped but Allah, Lord of the Heavens and Lord of the Earth and Lord of the Noble Throne.',
      source: 'Sahih al-Bukhari 6346 — narrated by Ibn Abbas, recited by the Prophet ﷺ in every moment of distress',
    ),
  ),

  NameTeaching(
    name: 'Al-Ghafur',
    arabic: '\u0627\u0644\u0652\u063a\u064e\u0641\u064f\u0648\u0631\u064f',
    emotionalContext: [
      'convinced your sins are too many to be forgiven',
      'returning to the same mistake again and again',
      'shame after a relapse',
      'afraid allah has given up on you',
      'desperate for a fresh start',
      'too embarrassed to make dua after sinning',
    ],
    coreTeaching:
        'Al-Ghafur is the All-Forgiving — but the Arabic root gh-f-r carries richer meaning than a simple pardon. Al-Ghazālī explains that the root connotes a helmet or covering: Al-Ghafur is the One who covers the sin, conceals it from the sight of others, erases it from the record, and absorbs its consequences. This is not merely acquittal — it is erasure, burial, and new beginning. Al-Ghafur appears 91 times in the Quran, making it one of the most frequently invoked of all the Names. It almost always appears paired with Al-Raḥīm (the Most Merciful): forgiveness and mercy move together. The verse in Sūrat al-Nisāʾ announces: "fa-ulāʾika ʿasā Allāh an yaʿfuwa ʿanhum, wa-kāna Allāh ʿafuwwan Ghafūrā" — "it is right to hope that Allah will pardon them. For Allah is Ever-Pardoning, All-Forgiving" (Quran 4:99). And in Sūrat al-Shūrā, after describing the heavens nearly bursting from awe of Him, Allah closes: "Alā inna Allāh huwa al-Ghafūr al-Raḥīm" — "Surely Allah alone is the All-Forgiving, Most Merciful" (Quran 42:5). The One the heavens tremble before is the same One who covers your sin without a trace. The most important insight about Al-Ghafur: His forgiveness does not wait to assess the size of your sin first. The scholar pairing — al-Ghafūr and al-Raḥīm — teaches that forgiveness (covering what is past) and mercy (sending goodness forward) always arrive together. You are not merely let off. You are actively cared for.',
    propheticStory:
        'After Moses \u0639\u0644\u064a\u0647 \u0627\u0644\u0633\u0644\u0627\u0645 accidentally killed a man and fled to Madyan, he returned to find himself chosen as a Prophet of Allah. His first prayer upon receiving revelation — recorded in Sūrat al-Qaṣaṣ — was an urgent personal one: "Rabbi inni ẓalamtu nafsī fa-ghfir lī" — "My Lord, I have wronged myself, so forgive me" (Quran 28:16). Allah responded by forgiving him immediately: "fa-ghafara lah" (Quran 28:16). The same root: gh-f-r. The man who had fled in fear, who had spent years as a fugitive in the wilderness, was called by Al-Ghafur — the One who covers — before he was called by any title of prophethood. Allah\'s forgiveness arrived first. The lesson embedded in Moses\'s story: the act that shamed you is not what defines you to Al-Ghafur. Your turning back is.',
    dua: NameTeachingDua(
      arabic: 'رَبِّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي',
      transliteration: "Rabbi inni zalamtu nafsi faghfir li",
      translation: 'My Lord, I have wronged myself, so forgive me.',
      source: 'Quran 28:16 — the supplication of Moses (\u0639\u0644\u064a\u0647 \u0627\u0644\u0633\u0644\u0627\u0645) upon receiving forgiveness (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Kabeer',
    arabic: '\u0627\u0644\u0652\u0643\u064e\u0628\u0650\u064a\u0631\u064f',
    emotionalContext: [
      'belittled or dismissed by others',
      'feeling small and invisible in the world',
      'intimidated by powerful people or institutions',
      'comparing yourself to others and feeling inferior',
      'afraid that your problems are too insignificant for allah to notice',
      'lost sense of your own worth and dignity',
    ],
    coreTeaching:
        'Al-Kabeer is the All-Great — but Greatness here is not the greatness of pride or power over others. It is the Greatness of absolute, self-subsisting magnitude: the kind before which every other claim to greatness dissolves. Sūrat al-Raʿd states plainly: "ʿĀlim al-ghayb wa-al-shahādah al-Kabīr al-Mutaʿāl" — "Knower of the seen and unseen — the All-Great, Most Exalted" (Quran 13:9). Al-Kabeer is paired with al-Mutaʿāl (the Most High) because His Greatness is not a horizontal expansion — it is a vertical transcendence. He is not merely the biggest thing among many things. He stands above the very category of size. Sūrat al-Ḥajj reinforces this: "dhālik bi-anna Allāh huwa al-Ḥaqq wa-anna mā yadʿūna min dūnih huwa al-bāṭil wa-anna Allāh huwa al-ʿAliyy al-Kabīr" — "That is because Allah alone is the Truth and what they invoke besides Him is falsehood, and Allah alone is the Most High, All-Great" (Quran 22:62). To know that you worship Al-Kabeer is to be liberated from every smaller greatness. The boss who intimidates you, the institution that holds power over you, the person whose approval you crave — every human claim to greatness is falsehood beside Al-Kabeer. Those who truly feel His Greatness fear no other greatness. When a human being makes you feel small, they are doing it without authority. Al-Kabeer alone sets the measure of what matters.',
    propheticStory:
        'The Prophet Shuʿayb \u0639\u0644\u064a\u0647 \u0627\u0644\u0633\u0644\u0627\u0645 stood alone against an entire community that mocked him and threatened to expel him. They said: "O Shuʿayb, we do not understand much of what you say, and indeed we consider you among us as weak" (Quran 11:91). His response was not to argue his own strength — it was to point to something greater: "O my people! Do you have more regard for my clan than for Allah, turning your back on Him entirely? Surely my Lord is Fully Aware of what you do" (Quran 11:92). He anchored his courage not in his own standing but in the comprehensive awareness of Al-Kabeer. He was small. Allah is not. That asymmetry was enough.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ',
      transliteration: "Rabbana ma khalaqta hadha batilan subhanaka faqina 'adhab an-nar",
      translation: 'Our Lord! You have not created all of this without purpose. Glory be to You! Protect us from the torment of the Fire.',
      source: 'Quran 3:191 — dua of the people of deep reflection (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Muqeet',
    arabic: '\u0627\u0644\u0652\u0645\u064f\u0642\u0650\u064a\u062a\u064f',
    emotionalContext: [
      'afraid you will not have enough — money, time, energy, strength',
      'exhausted from carrying too much alone',
      'worried that your needs are too small for allah to notice',
      'feeling unsupported and like no one is watching out for you',
      'doubting that provision will come',
      'depleted after giving everything to others',
    ],
    coreTeaching:
        'Al-Muqeet is the Sustainer — the One who holds the power of provision and maintenance over all things. Classical scholars note that the root q-w-t (قوت) means sustenance, nourishment, the precise measure of what a living thing needs. Al-Muqeet is not simply generous — He is the One who already knows exactly what you need and holds it ready. He does not provide in approximations. He sustains with precision. The Quran uses Al-Muqeet in a verse about accountability for intercession: "Whoever intercedes for a good cause will have a share in the reward, and whoever intercedes for an evil cause will have a share in the burden. And Allah is Watchful over all things" (Quran 4:85). The translation renders muqītan as "Watchful" — but the deeper connotation is custodial: He watches because He sustains. He is Guardian because He is Provider. Nothing in creation eats, breathes, or continues without His maintenance. The question "Will I have enough?" is a question already answered by the Name itself. He is Al-Muqeet: there is no created thing He does not sustain.',
    propheticStory:
        'The Prophet Muḥammad \ufdfa passed through enormous trials during the thirteen years of Meccan persecution — economic boycott, social exile, the loss of his wife and uncle, relentless opposition. During those years, his small community had little material security. Yet Allah commanded him to trust in the one name that encompasses both physical and spiritual provision. Sūrat al-Nisāʾ was revealed in Madinah during a period when the community was still consolidating — a time when intercession, social standing, and the weight of moral choices were pressing realities. Allah placed Al-Muqeet at the end of the verse on intercession to say: every act you do for good or ill, the One who tracks it is the same One who sustains you. Your provision is in the hands of the One who is also your Witness.',
    dua: NameTeachingDua(
      arabic: 'أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      transliteration: "Anta mawlana fansurna 'alal qawmil kafirin",
      translation: 'You are our Guardian, so grant us victory over the disbelieving people.',
      source: 'Quran 2:286 — closing supplication of Surah al-Baqarah (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Haseeb',
    arabic: '\u0627\u0644\u0652\u062d\u064e\u0633\u0650\u064a\u0628\u064f',
    emotionalContext: [
      'watching injustice happen and feeling powerless to stop it',
      'mistreated by someone who faces no consequences',
      'carrying guilt about something no one else knows',
      'afraid your private deeds — good or bad — do not count',
      'grieving that oppressors seem to win',
      'longing for someone to finally see everything clearly',
    ],
    coreTeaching:
        'Al-Haseeb is the Reckoner — the One who keeps account of every deed with perfect precision and who is sufficient as the one who settles all accounts. The Arabic root ḥ-s-b carries the meaning of counting, reckoning, and sufficiency: He who reckons is also He who is sufficient. You do not need an additional witness, an additional judge, an additional advocate — Al-Haseeb is enough. The Quran invokes this name in the context of orphan guardianship: "And Allah is sufficient as a vigilant Reckoner" (Quran 4:6). The verse commands guardians to handle orphans\' wealth with integrity, then closes with Al-Haseeb — not as a threat alone, but as a reassurance: even if no human guardian is watching, the divine Reckoner is. This is the double edge of the Name: it comforts the oppressed (everything is recorded, nothing is lost) and it sobres the oppressor (everything is recorded, nothing is hidden). The Yaqeen Institute series "The Name I Need" places Al-Haseeb among the names that answer the question: Why doesn\'t Allah stop injustice immediately? Because Al-Haseeb is not an emergency responder — He is an infallible record-keeper. The account is being kept perfectly. The reckoning comes.',
    propheticStory:
        'The Quran describes the scene when Allāh commands the guardians of orphans to hand over their property when they come of age: "Test the competence of the orphans until they reach a marriageable age. Then if you feel they are capable of sound judgment, return their wealth to them... And sufficient is Allah as a vigilant Reckoner" (Quran 4:6). In the early Muslim community, the care of orphans was a live social responsibility — and it was one where private misconduct was easy and detection was hard. Allah placed Al-Haseeb at the end of this command to remind both guardian and orphan: the account is not kept by the orphan, not by the community, not by any human judge. Al-Haseeb holds every transaction in a record that cannot be falsified, lost, or overlooked. Your private integrity — the kindness no one witnessed, the shortcut you did not take — is seen.',
    dua: NameTeachingDua(
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: "Hasbunallahu wa ni'mal wakeel",
      translation: 'Allah is sufficient for us, and He is the best Disposer of affairs.',
      source: 'Quran 3:173 — the words of believers when threatened; narrated as a saying of Ibrahim and Muhammad \ufdfa (Sahih al-Bukhari 4563)',
    ),
  ),

  NameTeaching(
    name: 'Al-Jaleel',
    arabic: '\u0627\u0644\u0652\u062c\u064e\u0644\u0650\u064a\u0644\u064f',
    emotionalContext: [
      'spiritually dry, going through motions without awe',
      'worship feels routine and empty',
      'heart has grown distant from the sense of the divine',
      'intimidated by the perfection and holiness of allah',
      'struggling to feel reverence rather than just obligation',
      'numbed by hardship until nothing feels sacred anymore',
    ],
    coreTeaching:
        'Al-Jaleel is the Majestic — the One whose Jalāl (majestic awe) is not merely impressive but overwhelming to every faculty that perceives it. The scholars distinguish between the Names of Jamāl (beauty) — like Al-Raḥmān, Al-Wadūd — and the Names of Jalāl (majesty) — like Al-Jaleel, Al-Qāhir, Al-Mutakabbir. Al-Jaleel belongs to the Names of awe: He is not encountered comfortably. The Prophet \ufdfa is reported to have said that a man from Bani Israel worshipped for a thousand years and could not see the Name Al-Jaleel without trembling. Dr. Omar Suleiman at the Yaqeen Institute describes reflecting on Al-Jaleel as "living within a Kingdom ruled by a King who commands hearts with majestic awe." This is not fear that paralyses — it is the holy trembling that realigns. The Quran pairs Al-Jaleel in essence with Al-Akram (the Most Generous) in Sūrat al-Raḥmān: "Tabāraka sm Rabbika dhī al-Jalāl wa-al-Ikrām" — "Blessed is the Name of your Lord, the One of Majesty and Honour" (Quran 55:78). His Jalāl (majesty) is always accompanied by His Ikrām (honour toward His servants). He does not overwhelm without also ennobling. The right response to Al-Jaleel is not cowering — it is reverential nearness. His awe does not push you away. It draws you into something larger than yourself.',
    propheticStory:
        'In Sūrat al-Raḥmān, Allah asks His creatures seventy-one times: "Fa-bi-ayyi ālāʾi Rabbikumā tukadhdhibān" — "So which of your Lord\'s favours will you both deny?" (Quran 55). The sūrah catalogues the heavens, the earth, the seas, the two gardens of Paradise — and then closes with the thundering refrain: "Tabāraka sm Rabbika dhī al-Jalāl wa-al-Ikrām" — "Blessed is the Name of your Lord, the One of Majesty and Honour" (Quran 55:78). The awe of Al-Jaleel is not the awe of a distant tyrant — it is the awe produced by an unending river of beauty and generosity. You feel His Greatness not because He threatens, but because His gifts are so vast that the heart trembles realising it can never repay them. The two Names move together through the entire sūrah: Majesty inseparable from Honour.',
    dua: NameTeachingDua(
      arabic: 'تَبَارَكَ اسْمُ رَبِّكَ ذِي الْجَلَالِ وَالْإِكْرَامِ',
      transliteration: "Tabarakas-mu Rabbika dhil-Jalali wal-Ikram",
      translation: 'Blessed is the Name of your Lord, the One of Majesty and Honour.',
      source: 'Quran 55:78 — closing verse of Surah al-Rahman (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Wasi',
    arabic: '\u0627\u0644\u0652\u0648\u064e\u0627\u0633\u0650\u0639\u064f',
    emotionalContext: [
      'afraid your prayer direction or posture was wrong',
      'worried allah\'s mercy cannot reach you in your current state',
      'geographically or spiritually far from community',
      'overwhelmed by the vastness of your own failures',
      'wondering if there is room for someone like you',
      'exile, displacement, or loneliness cuts you off from religious practice',
    ],
    coreTeaching:
        'Al-Wasi is the All-Encompassing — whose vastness cannot be bounded by direction, condition, or circumstance. The Quran reveals this Name in a moment of apparent legal crisis: early Muslims were uncertain about which direction to pray, or whether prayers offered in the wrong direction counted. Allah\'s answer: "To Allah belong the east and the west, so wherever you turn you are facing Allah. Surely Allah is All-Encompassing, All-Knowing" (Quran 2:115). He declared Himself Al-Wasi — and the legal problem dissolved into theology. You cannot pray in a direction outside of Allah. And then, when Moses \u0639\u0644\u064a\u0647 \u0627\u0644\u0633\u0644\u0627\u0645 pleaded for goodness in this life and the next, Allah responded: "My mercy encompasses everything" — wa-raḥmatī wasiʿat kulla shayʾ (Quran 7:156). The word used for mercy\'s encompassing is the same root as Al-Wasi. His mercy does not reach out to some and fall short of others. It already covers everything. It is already there. The scholar\'s insight on this Name: Al-Wasi answers the fear of being outside the range of divine care. There is no outside. He is the One whose encompassment has no edges.',
    propheticStory:
        'The revelation of Quran 2:115 came during a period when the early Muslim community was still settling questions of ritual practice. A group of companions had been praying while travelling and were uncertain if their direction was correct. The verse responded not with a legal ruling alone but with a Name of Allah: Al-Wasi — the All-Encompassing. It was a theological recalibration: you do not find Allah by finding the right coordinates. You find Allah by turning, in sincerity, toward the One who is already wherever you turn. The Prophet \ufdfa taught this spirit in how he prayed on camelback during travel — he prayed toward whichever way his camel happened to be facing, trusting that Al-Wasi did not require him to dismount for every supererogatory prayer.',
    dua: NameTeachingDua(
      arabic: 'وَاكْتُبْ لَنَا فِي هَٰذِهِ الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ إِنَّا هُدْنَا إِلَيْكَ',
      transliteration: "Waktub lana fi hadhihi al-dunya hasanatan wa fil-akhirati inna hudna ilayk",
      translation: 'Ordain for us what is good in this life and the next. Indeed, we have turned to You in repentance.',
      source: 'Quran 7:156 — the supplication of Moses addressed to the All-Encompassing Allah (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Majeed',
    arabic: '\u0627\u0644\u0652\u0645\u064e\u062c\u0650\u064a\u062f\u064f',
    emotionalContext: [
      'worship feels transactional rather than a relationship with glory',
      'struggling to feel the nobility of being in allah\'s presence',
      'lowered by life\'s humiliations until dignity feels lost',
      'difficulty trusting allah\'s generosity after repeated hardship',
      'yearning for something honourable and beautiful in your life',
      'feeling like your prayers are unworthy to reach such a great god',
    ],
    coreTeaching:
        'Al-Majeed is the All-Glorious — a Name drawn from the Arabic root m-j-d, which the classical scholars describe as combining three qualities: vastness of honour, nobility of character, and inexhaustible generosity. His Majd (glory) is not the brittle prestige of earthly kings that can be threatened or lost — it is the self-sustaining, overflowing glory of the One who lacks nothing and diminishes nothing by giving. The Quran places Al-Majeed in two places that illuminate its depth. In the scene of the angels visiting Ibrahim \u0639\u0644\u064a\u0647 \u0627\u0644\u0633\u0644\u0627\u0645 with news of a son, they tell his wife who is astonished: "Are you astonished by Allah\'s decree? May Allah\'s mercy and blessings be upon you, O people of this house. Indeed, He is Praiseworthy, All-Glorious" (Quran 11:73). And in Sūrat al-Burūj, describing the Throne: "Lord of the Throne, the All-Glorious" (Quran 85:15). Al-Majeed is the One whose Throne is the seat of His Glory — and He shares that Glory not as an exception but as His nature. His generosity to Ibrahim\'s household — a child after old age — is not a miracle departing from His nature. It IS His nature. The Quran also uses this root for the Quran itself: "Bal huwa Qurʾān majīd" — "In fact, this is a glorious Quran" (Quran 85:21). The Book is Majeed because it comes from Al-Majeed.',
    propheticStory:
        'The angels delivered news to Sarah, wife of Ibrahim \u0639\u0644\u064a\u0647 \u0627\u0644\u0633\u0644\u0627\u0645, that she would bear a son despite her old age. She laughed — a laugh of astonishment, not disbelief — and asked: "How can I bear a child when I am an old woman and my husband is an old man? This is truly an amazing thing!" The angels replied: "Are you astonished by Allah\'s decree? May Allah\'s mercy and blessings be upon you, O people of this house. Indeed, He is Ḥamīd, Majīd" (Quran 11:73). They named Him Al-Majeed precisely at the moment the impossible was announced. His glory does not diminish when it overflows. The miracle of Isḥāq\'s birth was not a strain on Al-Majeed — it was an expression of it.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ',
      transliteration: "Rabbana la tu'akhidhna in nasina aw akhta'na, rabbana wa la tahmil 'alayna isran kama hamaltahu 'ala alladhina min qablina, rabbana wa la tuhammilna ma la taqata lana bih, wa'fu 'anna waghfir lana warhamna, anta mawlana fansurna 'ala al-qawmil kafirin",
      translation: 'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one You placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our only Guardian. So grant us victory over the disbelieving people.',
      source: 'Quran 2:286 — closing supplication of Surah al-Baqarah (verbatim excerpt)',
    ),
  ),

  NameTeaching(
    name: 'Al-Baith',
    arabic: 'الْبَاعِثُ',
    emotionalContext: [
      'afraid death is the final word on your suffering',
      'struggling to find purpose in this life',
      'grief over someone who died before justice reached them',
      'wondering if the sacrifices of this life mean anything',
      'numb to the idea of the afterlife — it feels abstract',
      'dreading accountability but also desperate for justice',
    ],
    coreTeaching:
        'Al-Baʿith is the Resurrector — the One who raises the dead, restores what has ended, and calls forth what was buried. The root b-ʿ-th means to send, to dispatch, to rouse from sleep — Al-Baʿith is the One who will rouse all of creation from the sleep of death on the Day He decrees. The Quran makes this declaration unambiguous: "And certainly the Hour is coming, there is no doubt about it. And Allah will surely resurrect those in the graves" (Quran 22:7). And in Sūrat Yūnus, He frames the purpose of resurrection in justice: "Indeed, He originates the creation then resurrects it so that He may justly reward those who believe and do good" (Quran 10:4). Al-Baʿith is not just the promise of continuity — He is the guarantee that the ledger of this world will be settled. Every tear wept in injustice, every good deed done in obscurity, every martyr whose killers were never tried — Al-Baʿith holds the resurrection as the moment when all of it is addressed. This Name answers the most profound human grief: the feeling that death makes everything meaningless. To Al-Baʿith, death is not the ending — it is a transition between two phases of the same story. And the second phase, unlike the first, has no injustice left in it.',
    propheticStory:
        'The Prophet ﷺ was asked repeatedly about the resurrection by those who found it inconceivable. Allah\'s answer to the doubters does not appeal to philosophy — it appeals to the Name itself: the One who began creation can obviously repeat it. "Who originates the creation then resurrects it, and gives you provisions from the heavens and the earth?" (Quran 27:64). And in Sūrat al-Burūj: "Indeed, He is certainly the One Who originates and resurrects" (Quran 85:13). Al-Baʿith is the experiential reality of that promise: you will be raised, called to account, and given what the world withheld.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ',
      transliteration: "Rabbana innaka jami'u an-nasi li-yawmin la rayba fih, inna Allaha la yukhlifu al-mi'ad",
      translation: 'Our Lord, surely You will gather the people on a Day about which there is no doubt. Indeed, Allah does not break His promise.',
      source: 'Quran 3:9 — supplication of those who reflect on creation and resurrection (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Ash-Shaheed',
    arabic: 'الشَّهِيدُ',
    emotionalContext: [
      'doing good that nobody sees or acknowledges',
      'accused of something you did not do',
      'carrying a secret good deed or private sacrifice',
      'surrounded by people who lie or misrepresent you',
      'private worship feels pointless without outer recognition',
      'longing for someone to finally witness what you have been through',
    ],
    coreTeaching:
        'Ash-Shahīd is the Witness — the One who is present at everything, missing nothing, whose testimony is perfect and sufficient. The Arabic sh-h-d carries the meaning of presence (to witness is to be there), perception (to witness is to understand what you see), and testimony (to witness is to be able to testify). Ash-Shahīd has all three: He is omnipresent, omniscient, and His testimony cannot be challenged. The Quran invokes this Name repeatedly at moments of contested truth: "Yet Allah bears witness to what He has sent down to you — He has sent it with His Knowledge. The angels too bear witness. And Allah alone is sufficient as a Witness" (Quran 4:166). And: "Whatever good befalls you is from Allah and whatever evil befalls you is from yourself... And Allah is sufficient as a Witness" (Quran 4:79). And at the proclamation of the Prophet\'s mission: "He is the One Who has sent His Messenger with right guidance and the religion of truth, making it prevail over all others. And sufficient is Allah as a Witness" (Quran 48:28). In every case, Ash-Shahīd is invoked as the one whose witnessing settles the question. No human court, no social consensus, no amount of denial can erase what Ash-Shahīd has witnessed. The good you did when no one was looking — He witnessed it. The injustice done to you when no one believed you — He witnessed it.',
    propheticStory:
        'When the Prophet ﷺ was rejected by his people — called a liar, a poet, a madman — the Quran did not offer him a human defender. It offered him the Name: "Yet Allah bears witness to what He has sent down to you. He has sent it with His Knowledge. And Allah alone is sufficient as a Witness" (Quran 4:166). His vindication was not the verdict of his contemporaries. It was the testimony of Ash-Shahīd. The fact that Mecca eventually accepted Islam did not change the theological point: even if it never had, the Prophet\'s truth would have been witnessed. Every believer who has been lied about, dismissed, or silenced walks the same road. The verdict of history is not the verdict of Ash-Shahīd.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا وَاسِعٌ كُلَّ شَيْءٍ رَحْمَةً وَعِلْمًا فَاغْفِرْ لِلَّذِينَ تَابُوا وَاتَّبَعُوا سَبِيلَكَ',
      transliteration: "Rabbana wasi'ta kulla shay'in rahmatan wa 'ilman faghfir lilladhina tabu wattaba'u sabilak",
      translation: 'Our Lord, You encompass all things in mercy and knowledge, so forgive those who repent and follow Your path.',
      source: 'Quran 40:7 — the supplication of the angels who carry the Throne, addressed to the All-Knowing Witness (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Haqq',
    arabic: 'الْحَقُّ',
    emotionalContext: [
      'lost in confusion about what is real and what is false',
      'surrounded by so many conflicting voices you do not know what to believe',
      'feel like the truth about your life is being obscured or denied',
      'spiritual doubt — wondering if any of this is actually real',
      'grief over injustice that has not been recognised as such',
      'holding fast to something true when the whole world calls it false',
    ],
    coreTeaching:
        'Al-Ḥaqq is the Truth — not merely truthful, but the very ground of reality itself. Everything that is real is real because it participates in His Being. Everything false is false because it is absent from Him. The Quran states this with extraordinary clarity: "That is because Allah alone is the Truth, He alone gives life to the dead, and He alone is Most Capable of everything" (Quran 22:6). His being the Truth is not a moral claim about His honesty — it is an ontological claim about His reality. Al-Ḥaqq is the only being whose existence is necessary, uncreated, and cannot cease. Everything else is contingent. He alone IS in the fullest sense. And from this flows the rest: He gives life to the dead, He is capable of everything — because He is the source of all being. The Quran also anchors Al-Ḥaqq in contrast: "That is because Allah alone is the Truth and what they invoke besides Him is falsehood, and Allah alone is truly the Most High, All-Great" (Quran 22:62). This is why idol worship is not simply misguided devotion — it is a devotion to what does not exist, to what is by definition not-Real, not-Ḥaqq. And in Sūrat al-Anʿām, the cosmos itself is described through this Name: "He is the One Who created the heavens and the earth in truth" (Quran 6:73) — meaning the creation is not a game or a dream. It is Real, because Al-Ḥaqq made it so.',
    propheticStory:
        'When the Prophet ﷺ would wake for night prayer (Tahajjud), he began with this supplication — recorded as Sahih al-Bukhari 1120 from the narration of Ibn ʿAbbas — that centres entirely on Al-Ḥaqq: "O Allah, Lord of the heavens and the earth, and Lord of everything. You are al-Ḥaqq. Your promise is Ḥaqq. Your word is Ḥaqq. The meeting with You is Ḥaqq. Paradise is Ḥaqq. Hell is Ḥaqq. The Prophets are Ḥaqq. Muhammad ﷺ is Ḥaqq. The Hour is Ḥaqq." In a world of fluctuating realities, the Prophet anchored himself before dawn in the Name that is the foundation of all of them. Whatever is Ḥaqq — whatever is real, whatever is certain, whatever will endure — flows from Al-Ḥaqq. This is the theological reality that gives believers courage: your truth, when it is aligned with His Truth, does not depend on whether others acknowledge it.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ',
      transliteration: "Rabbana ma khalaqta hadha batilan subhanaka faqina 'adhaba an-nar",
      translation: 'Our Lord! You have not created all of this without purpose. Glory be to You! Protect us from the torment of the Fire.',
      source: 'Quran 3:191 — dua of those who reflect on creation (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Qawiyy',
    arabic: 'الْقَوِيُّ',
    emotionalContext: [
      'exhausted and running on empty',
      'the battle feels too large for your strength',
      'powerless against systems or people that harm you',
      'no strength left to keep fighting for what is right',
      'afraid your weakness will be your defeat',
      'asked to endure more than feels humanly possible',
    ],
    coreTeaching:
        'Al-Qawiyy is the All-Powerful — the One whose strength is boundless, undiminishing, and freely transferred to those who rely on Him. The Arabic root q-w-y (قوة) means strength, might, and capacity. Al-Qawiyy is not merely very strong — He is the source of all strength. Whatever strength exists anywhere in creation is only a fraction borrowed from Al-Qawiyy. The Quran pairs Al-Qawiyy consistently with Al-ʿAzīz (the Almighty), anchoring two aspects of divine strength: the power (Al-Qawiyy) and the invincibility (Al-ʿAzīz). When persecuted believers were expelled from their homes for no reason but saying "Our Lord is Allah," the Quran promised their vindication and then closed: "Allah is truly All-Powerful, Almighty" (Quran 22:40). When the Prophet\'s mission to bring iron (harsh truth alongside soft mercy) was described: "Surely Allah is All-Powerful, Almighty" (Quran 57:25). This is the comfort Al-Qawiyy offers: it is not that He promises to make you personally stronger in the way you imagine. It is that His strength is in the field on behalf of those who call on Him. When you have no strength left, you are not helpless — you are resting in the care of Al-Qawiyy. Your weakness is not a disqualifier. It is the very moment when His strength becomes most visible.',
    propheticStory:
        'The early Muslim community in Mecca was expelled, boycotted, and persecuted for years. They had no army, no state, no material power. The Quran addressed their situation directly with the Name: "Allah has decreed, I and My messengers will certainly prevail. Surely Allah is All-Powerful, Almighty" (Quran 58:21). The word "decreed" (kataba) means written, fixed, unchangeable — the victory was declared not as a wish but as a settled fact, grounded in Al-Qawiyy. History proved it: the most powerful empire of the ancient world, Rome and Persia, were outlasted by the community whose Prophet promised them nothing except the Strength of the One behind him. Their strength was not their own. It was borrowed from Al-Qawiyy.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      transliteration: "Rabbana afrigh 'alayna sabran wa thabbit aqdamana wansurna 'alal qawmil kafirin",
      translation: 'Our Lord, pour patience upon us, make our feet firm, and grant us victory over the disbelieving people.',
      source: 'Quran 2:250 — the supplication of the army of Talut facing overwhelming odds (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Waliyy',
    arabic: 'الْوَلِيُّ',
    emotionalContext: [
      'feel completely alone with no one to protect you',
      'abandoned by family or community',
      'vulnerable with no earthly helper or advocate',
      'afraid of enemies who are more powerful than you',
      'carrying a burden too heavy to carry alone',
      'longing for a guardian who truly understands your situation',
    ],
    coreTeaching:
        'Al-Waliyy is the Guardian — the One who is not merely watching over you but is intimately, loyally, protectively close. The root w-l-y carries several interlocking meanings: to be near, to be the master, to be a guardian, to be a helper. Al-Waliyy is all of these simultaneously. He is not a distant observer who sometimes intervenes — He is the One who has taken you under His walāya (guardianship) as a matter of His own nature. The Quran pairs Al-Waliyy with Al-Ḥamīd (the Praiseworthy) in one of the most beautiful verses about divine care: "He is the One Who sends down rain after people have given up hope, spreading out His mercy. He is the Guardian, the Praiseworthy" (Quran 42:28). The context is stunning: people had despaired of rain — they had given up. And exactly at the moment of despair, Al-Waliyy sent what they had stopped hoping for. His guardianship is not conditional on your hope. It precedes it. It arrives even when you have stopped asking. And He does it as Al-Ḥamīd — the Praiseworthy — meaning His act of care is itself an act of glory, worthy of praise. He does not guard reluctantly. He guards because it is His nature to be praised for loving His servants well.',
    propheticStory:
        'In Sūrat al-Shūrā, the verse about rain (Quran 42:28) was revealed to a community that regularly experienced drought in the Arabian Peninsula — a community for whom rain was life. The image is precise: people give up, accept the absence, begin to mourn — and then it rains. Al-Waliyy is not moved by their hope (they had none) or their prayer (the verse does not mention prayer). He is moved by His own nature as Guardian. This is the same Name the Prophet ﷺ invoked in the famous dua from the closing verse of Surah al-Baqarah: "Anta Mawlānā fa-anṣurnā ʿalā al-qawm al-kāfirīn" — "You are our Guardian, so grant us victory over the disbelieving people" (Quran 2:286). The word Mawlānā shares the same root as Al-Waliyy. In the darkest moment, the appeal is not to strength alone but to relationship: You are our Waliyy. Act accordingly.',
    dua: NameTeachingDua(
      arabic: 'أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      transliteration: "Anta mawlana fansurna 'alal qawmil kafirin",
      translation: 'You are our Guardian, so grant us victory over the disbelieving people.',
      source: 'Quran 2:286 — closing supplication of Surah al-Baqarah (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Hameed',
    arabic: 'الْحَمِيدُ',
    emotionalContext: [
      'gratitude feels impossible when life is painful',
      'wonder whether praising allah in hardship is honest or forced',
      'spiritual life feels hollow — words of praise without feeling',
      'feel unworthy to offer praise because of your own imperfection',
      'lost the feeling of wonder and thankfulness',
      'going through motions of worship without genuine hamd',
    ],
    coreTeaching:
        'Al-Ḥamīd is the Praiseworthy — not the One who happens to receive praise, but the One who is inherently, objectively, necessarily worthy of all praise. The distinction matters: you do not create His praiseworthiness by praising Him. His Ḥamd (praise-worthiness) is a quality that precedes your recognition of it, independent of it, true whether or not any creation ever voiced it. Every mouth that has ever praised anything beautiful has been, knowingly or not, reaching toward Al-Ḥamīd. The Quran opens with Alhamdulillah — "All praise belongs to Allah, Lord of all worlds" (Quran 1:2) — as the first full sentence of revelation, establishing that the correct orientation of the human heart is praise. And the Quran closes our prayers on that same note: "It is He who sends blessings upon you — and His angels — to bring you out from darknesses into the light. And He is ever, to the believers, Merciful" — Surah al-Aḥzāb. But it is the pairing of Al-Ḥamīd with Al-Majeed (Quran 11:73) and Al-Waliyy (Quran 42:28) and Al-Ghanī (Quran 31:26, 57:24) that reveals the theology: He is praised not because He needs the praise (He is Al-Ghanī — Self-Sufficient) but because praise is the natural response of anything that perceives genuine goodness. Al-Ḥamīd is so good that rightly-ordered creation cannot help but praise Him. Your praise of Him is not a gift to Him. It is you finally moving into alignment with what is true.',
    propheticStory:
        'The Quran records the scene of the angels announcing to Ibrahim\'s household that they would bear a son despite old age. Their announcement closed: "Indeed, He is Ḥamīd, Majīd" — Praiseworthy, All-Glorious (Quran 11:73). The impossible gift was explained by His Name: He gives this way because giving is what the All-Praiseworthy does. And from the side of the receiver, the Prophet ﷺ modelled the response to every gift: "Alhamdulillah" — said when waking, when eating, when sneezing, when completing anything. The Quran in Surah al-Aḥzāb (33:56) commands: "Indeed, Allah confers blessing upon the Prophet, and His angels ˹ask Him to do so˺. O you who have believed, ask ˹Allah to confer˺ blessing upon him and ask ˹Allah to grant him˺ peace." He ﷺ taught the darud as the vehicle by which we praise not only him but the One whose praiseworthiness the Prophet\'s very existence announced.',
    dua: NameTeachingDua(
      arabic: 'أَنِ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      transliteration: "Ani'l-hamdu lillahi rabbi'l-alameen",
      translation: 'All praise is for Allah, Lord of all worlds.',
      source: 'Quran 10:10 (verbatim) — the closing praise of the people of Paradise, the final word that ends every act of remembrance.',
    ),
  ),

  NameTeaching(
    name: 'Al-Muhsi',
    arabic: 'الْمُحْصِي',
    emotionalContext: [
      'feel like your good deeds are too small to matter',
      'private sacrifices that no one notices or counts',
      'overwhelmed by the fear of forgotten sins',
      'afraid your efforts have added up to nothing',
      'keep track of other people\'s wrongs against you',
      'yearn for someone to finally count everything correctly',
    ],
    coreTeaching:
        'Al-Muḥsī is the Enumerator — the One who has counted and catalogued every single thing in existence, without loss, without error, without approximation. The Arabic root ḥ-s-y means to count, to enumerate, to take inventory — Al-Muḥsī is the One who holds the complete inventory of all creation. Not an estimate. Not a record with gaps. A perfect, complete count. Sūrat al-Jinn closes with this Name in its most awe-inducing form: "to ensure that the messengers fully deliver the messages of their Lord — though He already knows all about them, and keeps account of everything" — wa-aḥsā kulla shayʾin ʿadadā (Quran 72:28). And Sūrat al-Nabaʼ: "And We have everything recorded precisely" — wa-kulla shayʾin aḥsaynāhu kitāban (Quran 78:29). And in Sūrat Yāsīn: "Everything is listed by Us in a perfect Record" (Quran 36:12). The triple Quranic testimony is overwhelming: nothing is outside His count. The seed of patience you sowed in silence. The prayer prayed through tears at 3am. The kindness done and immediately forgotten by the recipient. Al-Muḥsī has it. The deepest comfort of this Name is not just about reward — it is about being truly known. He does not see you in summary. He sees you in full inventory: every detail, every private moment, every cell of struggle.',
    propheticStory:
        'When the Prophet ﷺ recounted the Day of Judgment, he described a scene that would terrify and console simultaneously: a person\'s own body parts testifying about their deeds. The Quran gives voice to this in Sūrat Fuṣṣilat: "They will ask their skin furiously, \'Why have you testified against us?\' It will say, \'We have been made to speak by Allah, Who causes all things to speak. He is the One Who created you the first time, and to Him you were bound to return\'." (Quran 41:21). This is the testimony of Al-Muḥsī\'s record made manifest. The skin did not forget. The earth did not forget. Sūrat al-Zalzalah tells us: "On that Day, the earth will report its news — whatever your Lord has revealed to it" (Quran 99:4-5). Every surface was always a recording device in Al-Muḥsī\'s archive. Nothing you did has slipped through.',
    dua: NameTeachingDua(
      arabic: 'سُبْحَانَكَ لَا عِلْمَ لَنَا إِلَّا مَا عَلَّمْتَنَا إِنَّكَ أَنتَ الْعَلِيمُ الْحَكِيمُ',
      transliteration: "Subhanaka la 'ilma lana illa ma 'allamtana innaka anta al-Alim al-Hakim",
      translation: 'Glory be to You! We have no knowledge except what You have taught us. You are truly the All-Knowing, All-Wise.',
      source: 'Quran 2:32 — the words of the angels before the All-Knowing, All-Wise Allah (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Mubdi',
    arabic: 'الْمُبْدِئُ',
    emotionalContext: [
      'feel like it is too late to start over',
      'exhausted by a failed attempt and afraid to try again',
      'the past feels permanent and unchangeable',
      'afraid that who you have been defines who you will always be',
      'lost the courage to begin something new',
      'convinced you have used up your chances',
    ],
    coreTeaching:
        'Al-Mubdi is the Originator — the One who brought all of creation into existence from absolute nothing, without precedent, without model, without effort. The root b-d-ʼ in Arabic means to begin, to innovate, to bring into being what has never existed before. Al-Mubdi is not simply the first cause in a chain of causes. He brought the chain itself into being. There was nothing — and then there was everything, because Al-Mubdi willed it. The Quran pairs Al-Mubdi with Al-Muīd (the Restorer) in three remarkable verses, each time presenting origination and return together as a pair that cannot be separated: "Indeed, He is certainly the One Who originates and resurrects" (Quran 85:13). "He originates the creation then resurrects it so that He may justly reward those who believe" (Quran 10:4). "Who originates the creation then resurrects it" (Quran 27:64). The theological weight of Al-Mubdi for human experience: if He could originate the entire cosmos from nothing, then He can certainly originate a new chapter in your life from whatever ruins remain. The fear of "it is too late" assumes that the constraints of the past bind Al-Mubdi. They do not. He who created ex nihilo is not constrained by history. The One who began everything can begin again.',
    propheticStory:
        'The Prophet Ayyub (Job) عليه السلام lost everything: his wealth, his children, his health. His suffering lasted years. The Quran records his cry to Al-Mubdi\'s complementary face, Al-Muīd: "Affliction has touched me, and You are the Most Merciful of the merciful" (Quran 21:83). Allah\'s response was not simply to restore what had been taken — it was to originate something new. He restored Ayyub\'s health, granted him his family again, and gave him a doubled portion. The response of Al-Mubdi to Ayyub\'s end was a new beginning, not a return to an old checkpoint. When al-Mubdi intervenes in your life\'s ruins, what comes next is not a reconstruction of what was. It is an origination of what never was before.',
    dua: NameTeachingDua(
      arabic: 'رَبَّي لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ',
      transliteration: "Rabbi la tadhharni fardan wa-anta khayrul waritheen",
      translation: 'My Lord, do not leave me without offspring, and You are the best of inheritors.',
      source: 'Quran 21:89 — the supplication of Zakariyya (عليه السلام), praying for a new beginning when hope had run out (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Muid',
    arabic: 'الْمُعِيدُ',
    emotionalContext: [
      'afraid what has been broken can never be restored',
      'relationships that feel beyond repair',
      'grief over a version of yourself you have lost',
      'doubt that the damage done to your faith can be undone',
      'feel trapped by what has already happened',
      'longing for the life or peace you once had',
    ],
    coreTeaching:
        'Al-Muīd is the Restorer — the One who brings back, returns, and repeats creation. Where Al-Mubdi is the beginning, Al-Muīd is the return: together they form the complete arc of existence. But Al-Muīd is not merely about the physical resurrection on the Day of Judgment — though that is His grandest expression. He is the One whose power to restore is inherent in His nature, operating in this life as well. The Quran presents these two Names as inseparable partners: "Indeed, He is certainly the One Who originates and resurrects" (Quran 85:13). "He originates the creation then resurrects it" (Quran 10:4). What the root ʿ-w-d (عود) means is return: to come back to what was, to restore a state, to repeat. Al-Muīd is the guarantee that nothing good is permanently lost. This Name speaks directly to the deepest human fear: that irreversible loss is the final word. The Quran and the prophets\' lives together testify: Al-Muīd does not consider any state irreversible. Yaʿqūb عليه السلام was separated from his son Yūsuf for decades, grieved until his eyes turned white from weeping — and the restoration came. Ayyub عليه السلام lost every material thing — and the restoration came. Al-Muīd does not restore on your timeline. He restores when the wisdom of the return is complete.',
    propheticStory:
        'The story of Yūsuf عليه السلام is the Quran\'s most complete portrait of Al-Muīd at work across a human lifetime. His brothers cast him into a well. He was sold into slavery. He was imprisoned on a false accusation. His father wept for him for decades. And then — from within an Egyptian prison — Al-Muīd began the restoration. Yusuf was raised to the highest office in the land. His brothers came before him. His father\'s sight was restored. The shirt that Yūsuf\'s brothers had bloodied was the same material that would restore his father\'s eyes when brought from Egypt. The Quran records Yaʿqūb\'s response when the restoration came: "Did I not tell you that I know from Allah what you do not know?" (Quran 12:96). He had trusted Al-Muīd when it was invisible. The return came.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa-qina 'adhaba an-nar",
      translation: 'Our Lord! Grant us goodness in this world and goodness in the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 — the supplication of those who seek good in both worlds, recited by the Prophet ﷺ constantly (Sahih al-Bukhari 4522)',
    ),
  ),

  NameTeaching(
    name: 'Al-Muhyi',
    arabic: 'الْمُحْيِي',
    emotionalContext: [
      'after a long period of spiritual deadness',
      'wondering if you will ever feel connected to faith again',
      'depression that has drained all meaning from life',
      'feeling like part of you has died',
      'recovery from a devastating loss',
      'desperate for renewal you cannot manufacture yourself',
    ],
    coreTeaching:
        'Al-Muhyi is the Giver of Life — the One who alone originates life, restores it, and will call it back on the Day of Resurrection. The Quran pairs this Name directly with Al-Mumeet (the Causer of Death) to make a single theological claim: what begins and ends life is not fate, not biology, not chance — it is One Being with deliberate will. As Allah declares in Surah Al-Hadid: "lahu mulku as-samawati wa-l-ard, yuhyi wa-yumeet, wa-huwa ʿala kulli shayʼin qadir" — "To Him belongs the kingdom of the heavens and the earth. He gives life and causes death. And He is Most Capable of everything" (Quran 57:2). But the Name runs deeper than physical biology. In Surah Ya-Sin, when a skeptic mocks resurrection — "Who will give life to decayed bones?" — Allah answers with a direct claim of His Name: "Qul yuhyiha allathi anshaʼaha awwala marra, wa-huwa bikulli khalqin ʿalim" — "Say: They will be revived by the One Who produced them the first time, for He has perfect knowledge of every created being" (Quran 36:79). The One who made something from nothing holds infinitely more power to remake it. And in Surah Al-Fussilat, He offers the most intimate sign: the barren earth that trembles back to life under rain (Quran 41:39). That earth is you. The drought you feel inside — the numbness, the distance from prayer, the sense that your soul has gone cold — is not permanent. Al-Muhyi revives what He made. He does not need your momentum. He needs only to say: Be.',
    propheticStory:
        'When the disbelieving king Nimrod challenged Ibrahim (عليه السلام), he sneered: "I too have the power to give life and cause death." Ibrahim immediately shifted ground: "Allah causes the sun to rise from the east. So make it rise from the west." And so the disbeliever was dumbstruck (Quran 2:258). The story is not primarily about the king’s defeat. It is about what Ibrahim knew: life is not a force you seize. It belongs to One. The king who claimed to give life produced theatre. Al-Muhyi does not perform — He originates. Ibrahim knew you cannot argue a person into faith using logic alone; you show them where the life truly comes from. Every dawn that follows your darkest night is Al-Muhyi making His argument again.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَآ أَمَتَّنَا ٱثْنَتَيْنِ وَأَحْيَيْتَنَا ٱثْنَتَيْنِ فَٱعْتَرَفْنَا بِذُنُوبِنَا فَهَلْ إِلَىٰ خُرُوجٍ مِّن سَبِيلٍ',
      transliteration:
          "Rabbana amattana ithnatayni wa ahyaytana ithnatayni fa'tarafna bidhunubina fahal ila khurujin min sabil",
      translation:
          'Our Lord! You made us lifeless twice and gave us life twice. Now we confess our sins. So is there any way out?',
      source: 'Quran 40:11 (verbatim excerpt — the disbelievers in the Fire finally acknowledge resurrection)',
    ),
  ),

  NameTeaching(
    name: 'Al-Mumeet',
    arabic: 'الْمُمِيتُ',
    emotionalContext: [
      'grieving the death of someone you love',
      'terrified of dying',
      'watching someone you love suffer and unable to stop it',
      'grappling with why death feels so cruel and random',
      'the first anniversary of a loss',
      'sitting with mortality after a diagnosis',
    ],
    coreTeaching:
        'Al-Mumeet is the Causer of Death — not the angel of death, not fate, not illness. The Name is a divine declaration that death is not a random force that seizes life. It is an act of will by the One who gave life in the first place. Allah says in Surah Al-Hadid: "yuhyi wa-yumeet, wa-huwa ʿala kulli shayʼin qadir" — "He gives life and causes death. And He is Most Capable of everything" (Quran 57:2). This pairing — Al-Muhyi beside Al-Mumeet — is not a theology of cruelty. It is a theology of ownership. The One who loved this person into existence is the same One who called them home. And in Surah Ali ʿImran, Allah specifically corrects the most painful thing humans say in grief: "O believers! Do not be like the unfaithful who say about their brothers who travel or go into battle: ‘If they had stayed with us, they would not have died.’ Allah makes such thinking a cause of agony in their hearts. It is Allah who gives life and causes death" (Quran 3:156). The verse names a specific wound: counterfactual grief, the torment of "if only." Al-Mumeet is precisely the answer. Death is not a mistake that could have been prevented by different decisions. It was appointed. And Surah Al-Mulk names the purpose with sober clarity: "He is the One Who created death and life in order to test which of you is best in deeds" (Quran 67:2). Death is not a malfunction. It is part of a design authored by the Most Wise.',
    propheticStory:
        'When the Prophet ﷺ’s own son Ibrahim died as an infant, he wept and said: "The eyes shed tears and the heart grieves, and we do not say except what pleases our Lord. O Ibrahim, we are truly grieved by your departure." He did not suppress the grief. He did not perform composure. He named the sorrow and held it alongside trust in Al-Mumeet. Then he said: "The eye weeps and the heart is sad, but we will not say anything that displeases Allah" (Sahih al-Bukhari 1303). Here is the model: grief and surrender are not opposites. You can cry at what Al-Mumeet has decreed and still trust the decree. The Prophet who brought the final revelation wept at his son’s death. You are not weak for weeping. You are human — as the one Allah loved most was human.',
    dua: NameTeachingDua(
      arabic: 'إنَّا للَّهِ وَإنَّا إِلَيْهِ رَاجِعُونَ',
      transliteration: "Inna lillahi wa inna ilayhi raji'un",
      translation: 'Surely to Allah we belong and to Him we will all return.',
      source: 'Quran 2:156 (verbatim — the Quranic words of those who are patient at calamity)',
    ),
  ),

  NameTeaching(
    name: 'Al-Wajid',
    arabic: 'الْوَاجِدُ',
    emotionalContext: [
      'feeling like no one sees your pain',
      'invisible to the people who matter most to you',
      'longing to be found and known fully',
      'lost and uncertain which way to turn',
      'abandoned after a betrayal',
      'walking through life without a sense of being truly met',
    ],
    coreTeaching:
        'Al-Wajid is the Finder — the One who perceives, encounters, and finds everything, and whose finding of you is an act of grace. The root w-j-d in Arabic means both "to find" and "to feel" — Al-Wajid finds you and feels you. Nothing escapes His perception, and nothing is lost to Him. The Quran offers the most intimate illustration of this meaning in Surah Ad-Duhaa, speaking directly to the Prophet ﷺ: "Alam yajidka yatiman fa-awa" — "Did He not find you as an orphan then sheltered you?" (Quran 93:6). Allah’s finding of Muhammad (ﷺ) as an orphan was not passive discovery — it was active sheltering. Wajada leads to ūwiyya (refuge). And then: "wa-wajadaka ʿaʼilan fa-aghnā" — "And did He not find you needy then satisfied your needs?" (Quran 93:8). The pattern is established: Allah finds you precisely in the state of your greatest need, and His finding is never merely noticing — it is acting. When you feel invisible to the world, consider: the One who counts every hair on your head, who hears every breath of every creature in every ocean, does not misplace you. He has found you already. Your job is simply to stay.',
    propheticStory:
        'In the story of Prophet Ayyub (عليه السلام), after years of sickness, loss, and isolation — stripped of health, wealth, and companionship — Allah describes His verdict: "Inna wajadnahu sabiran, niʿma al-ʿabd, innahu awwab" — "We truly found him patient. What an excellent servant he was! Indeed, he constantly turned to Allah" (Quran 38:44). The word wajadnahu: "We found him." Not merely "he was." Allah’s finding of Ayyub in his worst season was a divine assessment, a testimony spoken from on high. In the middle of Ayyub’s suffering — before healing, before restoration — Al-Wajid had already found him and already named what He saw: patience, excellence, devotion. Allah found him worthy in his poverty and brokenness, not after it.',
    dua: NameTeachingDua(
      arabic: 'أَنِّى مَسَّنِىَ ٱلضُّرُّ وَأَنتَ أَرْحَمُ ٱلرَّٰحِمِينَ',
      transliteration: "Anni massaniya ad-durru wa anta arhamu ar-rahimeen",
      translation: 'My Lord! Adversity has touched me, and You are the Most Merciful of the merciful.',
      source: 'Quran 21:83 (verbatim excerpt — supplication of Prophet Ayyub عليه السلام in his affliction)',
    ),
  ),

  NameTeaching(
    name: 'Al-Qadir',
    arabic: 'الْقَادِرُ',
    emotionalContext: [
      'feeling powerless to change your situation',
      'watching a door close that you cannot reopen',
      'stuck in a season that seems impossible to leave',
      'carrying a problem too heavy for any human solution',
      'after every plan has failed',
      'helplessness in the face of injustice',
    ],
    coreTeaching:
        'Al-Qadir is the All-Powerful — the One who has perfect, complete, and absolute capability over every created thing. The root q-d-r in Arabic gives us both qudra (power) and qadar (divine decree): the same root that names what Allah can do also names what Allah has already willed. This is not coincidence. His power and His plan are the same thing. In Surah Al-Kahf, Allah paints the parable of worldly life: thriving like plants after rain, then turning to scattered chaff. The verse closes: "wa-kana Allahu ʿala kulli shayʼin muqtadiran" — "And Allah is fully capable of all things" (Quran 18:45). The metaphor is deliberate: even the most beautiful, established, flourishing thing in this world is temporary — and Al-Qadir is capable of both its flourishing and its fading. But in Surah Al-Anʿam, the Name carries comfort: "Qul huwa al-qadir ʿala an yabʿatha ʿalaykum ʿadhaban min fawqikum" — "He alone has the power to unleash punishment..." (Quran 6:65), and in the very next verse: "wa-in yamsaskum Allahu bi-durrin fa-la kashifa lahu illa huwa" — "If Allah touches you with harm, none can undo it except Him" (Quran 6:17). Power over harm and power over healing belong to the same One. The Yaqeen Institute’s Ramadan duʿa series frames Al-Qadir’s emotional weight precisely: "Nothing is beyond Your power. As You part the seas and revive the dead, lift our people from beneath the weight of this world." The seas were real. The dead were real. And so is the weight you carry.',
    propheticStory:
        'Before the Battle of Badr, the Muslims numbered 313 — lightly armed, outnumbered, exhausted from travel — facing a Meccan force of a thousand. The Prophet ﷺ prayed through the night: "O Allah, if this small band perishes today, You will not be worshipped on earth." He was not doubting. He was invoking Al-Qadir: the One who needs no army to accomplish His will. The Quran records the outcome in Surat Al ʿImran: "Allah has already given you victory at Badr when you were outnumbered. So be mindful of Allah, perhaps you will be grateful" (Quran 3:123). Al-Qadir’s victories do not follow military logic. They follow His will. When you are 313 and the problem before you is a thousand, Al-Qadir has not changed.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ',
      transliteration: "Rabbana la tu'akhidhna in nasina aw akhta'na, Rabbana wa la tahmil 'alayna isran, Rabbana wa la tuhammilna ma la taqata lana bih, wa'fu 'anna waghfir lana warhamna, anta mawlana fansurna 'ala al-qawmi al-kafirin",
      translation: 'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our only Guardian. So grant us victory over the disbelieving people.',
      source: 'Quran 2:286 (verbatim excerpt)',
    ),
  ),

  NameTeaching(
    name: 'Al-Muqtadir',
    arabic: 'الْمُقْتَدِرُ',
    emotionalContext: [
      'facing forces larger than anything you can control',
      'when human power has failed and there is nothing left to do',
      'watching injustice go unchallenged',
      'overwhelmed by the scale of what is against you',
      'powerless in the face of institutions, illness, or loss',
      'needing a reminder that no force on earth is unchecked',
    ],
    coreTeaching:
        'Al-Muqtadir is the All-Prevailing in Power — where Al-Qadir names that Allah can, Al-Muqtadir names that Allah always prevails. The morphological intensification from qadir to muqtadir carries weight: this is not merely capability but execution without flaw, power without limit, authority that brooks no resistance. The Quran uses this Name at the moment of divine reckoning with civilizations that forgot their limits. When the people of Thamud rejected every sign: "kadhdhabū bi-āyātinā kullihā fa-akhadhnāhum akhdha ʿazīzin muqtadir" — "They rejected all of Our signs, so We seized them with the crushing grip of the Almighty, Most Powerful" (Quran 54:42). And in Surah Al-Kahf, after the parable of thriving plants reduced to chaff: "wa-kāna Allāhu ʿalā kulli shayʼin muqtadirā" — "And Allah is fully capable of all things" (Quran 18:45). The Name appears in Surah Al-Qamar (54:55) in its most beautiful context: the righteous in the afterlife, seated "fī maqʿadī ṣidqin ʿinda malīkin muqtadir" — "at the Seat of Honour in the presence of the Most Powerful Sovereign." Every human power that dominated, oppressed, or dismissed you will one day answer to the Most Powerful Sovereign before whom even kings are dust. The Yaqeen Ramadan series renders this Name with disarming clarity: "Your power is perfect, Your execution without flaw. Let those who boast of might see how small they really are."',
    propheticStory:
        'The people of Pharaoh had enslaved an entire nation for four hundred years. By any human reckoning, Pharaoh’s power was permanent. Moses (عليه السلام) arrived with a staff and a brother. When Bani Israel reached the sea and Pharaoh’s armies closed in, they cried: "We are overtaken!" Moses replied: "No! Indeed, with me is my Lord; He will guide me" (Quran 26:61-62). Allah then parted the sea. The most powerful military force of its age was swallowed by water at the command of Al-Muqtadir. The lesson is precise: Al-Muqtadir does not need your resources. He uses what is already there. The sea was always the sea.',
    dua: NameTeachingDua(
      arabic: 'لَهُۥ مُلْكُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ يُحْىِۦ وَيُمِيتُ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
      transliteration: "Lahu mulku as-samawati wal-ard, yuhyi wa-yumeet, wa-huwa 'ala kulli shay'in qadir",
      translation: 'To Him belongs the kingdom of the heavens and the earth. He gives life and causes death. And He is Most Capable of everything.',
      source: 'Quran 57:2 (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Barr',
    arabic: 'الْبَرُّ',
    emotionalContext: [
      'longing for goodness that actually feels kind, not transactional',
      'struggling to believe allah’s care is personal',
      'overwhelmed by how much you need and how little you have',
      'wavering faith that allah means well for you specifically',
      'weariness from a long season of difficulty',
      'needing tenderness, not just strength',
    ],
    coreTeaching:
        'Al-Barr is the Dutiful, the Source of All Goodness — the One whose goodness toward creation is not earned, not conditional, and not limited to reward and punishment. The root b-r-r in Arabic runs through the most intimate human relationships: birr al-walidayn is dutifulness to parents, a love that gives without accounting. Allah claims this root as a Name — His goodness toward creation has the character of devoted, attentive care. The Quran places this Name in the mouth of the believers in Jannah, looking back at their lives: "Inna kuna min qablu nadʿuhu, innahu huwa al-Barr al-Rahim" — "Indeed, we used to call upon Him before. He is truly the Most Kind, Most Merciful" (Quran 52:28). The scene is Paradise. What the people of Paradise testify to — when all doubt is resolved and all prayers are answered — is not Allah’s power or His knowledge. It is His birr: His devoted, attentive goodness. The Yaqeen Ramadan duʿa series renders the Name this way: "keep me firm on the grounds of Your goodness. Make my faith steady when my heart trembles." Al-Barr does not offer goodness as a transaction. He is Goodness Himself, extended toward His servants with the constancy of a parent’s love. The Name is your anchor when your heart trembles: He is not withholding good from you. He is the source of every good that has ever reached you, and He is still sourcing.',
    propheticStory:
        'When Surah At-Tur was revealed, the concluding verses assured the Prophet ﷺ of divine protection amid intense opposition: "So wait patiently for your Lord’s judgment, for you are truly under Our ˹watchful˺ Eyes. And glorify the praises of your Lord" (Quran 52:48). But the verse the companions remembered most was 52:28 — the testimony of the people of Paradise who had called on Al-Barr in every hardship. The Prophet ﷺ recited Surah At-Tur in Fajr prayer, and the companions reported weeping as they heard the verse about the believers’ gratitude (recorded in Islamic exegetical tradition). The story is this: the Name Al-Barr will be validated completely on the Day that all of Paradise receives its inhabitants. Every person who trusted that Allah meant them well will be proven right.',
    dua: NameTeachingDua(
      arabic: 'إِنَّا كُنَّا مِن قَبْلُ نَدْعُوهُ ، إِنَّهُ هُوَ الْبَرُّ الرَّحِيمُ',
      transliteration: "Inna kunna min qablu nad'uhu, innahu huwa al-Barru ar-Rahim",
      translation: 'Indeed, we used to call upon Him before. He is truly the Most Kind, Most Merciful.',
      source: 'Quran 52:28 (verbatim — the testimony of the people of Paradise)',
    ),
  ),

  NameTeaching(
    name: 'Ar-Rauf',
    arabic: 'الرَّءُوفُ',
    emotionalContext: [
      'exhausted from suffering that seems to have no end',
      'bracing for a storm you can feel coming',
      'fragile after a season of consecutive losses',
      'needing gentleness not strength',
      'afraid the worst is still ahead',
      'the rawness that follows grief before it becomes bearable',
    ],
    coreTeaching:
        'Ar-Rauf is the Most Gentle, the Most Kind — a Name that intensifies Ar-Rahim (the Most Merciful) into something more intimate. Where Ar-Rahim is mercy that covers and surrounds, Ar-Rauf is mercy that moves tenderly, that handles the broken thing with care, that foresees the harm before it lands and softens the blow. The root r-ʿ-f carries the sense of tenderness, of gentle movement, of the care a doctor shows around a wound. In Surah Al-Baqarah, after describing the trials that will test the believers — fear, hunger, loss of life and fruit — Allah commands "give glad tidings to the patient" (Quran 2:155-157). But then, closing the series of trials: "Allah is truly Most Kind and Most Merciful to the people" (Quran 2:143). Ar-Rauf closes the chapter on difficulty. And at the end of Surah At-Tawbah, after nine chapters of the hardest divine commands — battle, sacrifice, confrontation with hypocrisy — the Prophet ﷺ is described: "laqad jaʼakum rasūlun min anfusikum ʿazīzun ʿalayhi ma ʿanittum, raʼuf r-rahīm" — "There certainly has come to you a messenger from among yourselves. He is concerned by your suffering, anxious for your well-being, and gracious and merciful to the believers" (Quran 9:128). Two of Allah’s own Names are given to the Prophet because the Prophet exemplifies them. Ar-Rauf names Allah’s posture toward you in your worst seasons: not distant judgment but aching concern. The Yaqeen Ramadan series captures it: "cover me from storms I don’t see coming, mend me before I break, and spare me from trials of every kind."',
    propheticStory:
        'The Prophet ﷺ once narrated to his companions about an earlier prophet who, while being beaten and bleeding from his own people, wiped the blood from his face and said: "O Allah! Forgive my people, for they have no knowledge" (Sahih al-Bukhari 3477). He also described the day of Al-Aqabah, after the people rejected him, when the Angel of the Mountains offered to crush them between the two mountains; the Prophet ﷺ instead hoped Allah would bring from their descendants people who would worship Him alone (Sahih al-Bukhari 3231). This is Ar-Rauf in human form: a tenderness that does not retract when it is hurt. Allah named this quality in His Prophet twice — raʼuf and rahīm — because it mirrors His own way with us. He sees your worst moments and His first response is not anger. It is concern.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا آتِنَا مِن لَدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
      transliteration: "Rabbana atina min ladunka rahmatan wa hayyi' lana min amrina rashadan",
      translation: 'Our Lord! Grant us mercy from Yourself and guide us rightly through our ordeal.',
      source: 'Quran 18:10 (verbatim — the supplication of the People of the Cave)',
    ),
  ),

  NameTeaching(
    name: 'Malik-ul-Mulk',
    arabic: 'مَالِكُ الْمُلْكِ',
    emotionalContext: [
      'feeling that the wrong people hold power',
      'stripped of status, position, or authority you worked for',
      'watching doors close that you cannot reopen',
      'powerless before human institutions or systems',
      'jealousy of those who seem to have everything',
      'craving recognition and rank that has not come',
    ],
    coreTeaching:
        'Malik-ul-Mulk is the Master of All Sovereignty — the One in whose Hand alone lies every throne, every title, every rise, and every fall. The Name appears explicitly in Surah Ali ʿImran in one of the Quran’s most majestic verses: "Qul Allahumma Malika al-mulki tuʼti al-mulka man tashaʼ wa-tanziʿu al-mulka mimman tashaʼ, wa-tuʿizzu man tashaʼ wa-tudhillu man tashaʼ, biyadika al-khayr, innaka ʿala kulli shayʼin qadir" — "Say: O Allah! Lord over all authorities! You give authority to whoever You please and remove it from whom You please; You honour whoever You please and disgrace whom You please — all good is in Your Hands. Surely You alone are Most Capable of everything" (Quran 3:26). Every government that has ever fallen, every empire that crumbled, every board that fired someone unfairly, every election result that shocked the world — all of it falls under this verse. No authority is self-originating. It is given, and it is withdrawn, by Malik-ul-Mulk. The following verse (3:27) continues the picture: "You cause the night to pass into the day and the day into the night. You bring forth the living from the dead and the dead from the living. And You provide for whoever You will without limit." The pattern of night and day is the pattern of status too: darkness gives way to light, fall gives way to rise, and none of it is permanent except the Owner of it all.',
    propheticStory:
        'When the Romans (Byzantines) were defeated by the Persians, the pagan Arabs of Mecca celebrated — enemies of the Muslims beating what they saw as a rival monotheistic empire. The Quran revealed: "The Romans have been defeated in the nearest land. But following their defeat, they will triumph within three to nine years" (Quran 30:2-4). It was a prophecy attached to a wager. The Muslims believed it; the pagans doubted. Within the predicted timeframe, the Romans defeated the Persians exactly as promised. This was a demonstration of Malik-ul-Mulk’s knowledge of every kingdom’s fate — before the battle had been fought, He had already written its reversal. No outcome in history catches Him by surprise.',
    dua: NameTeachingDua(
      arabic: 'قُلِ ٱللَّهُمَّ مَـٰلِكَ ٱلْمُلْكِ تُؤْتِى ٱلْمُلْكَ مَن تَشَآءُ وَتَنزِعُ ٱلْمُلْكَ مِمَّن تَشَآءُ وَتُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ ۖ بِيَدِكَ ٱلْخَيْرُ ۖ إِنَّكَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
      transliteration: "Qul Allahumma Malika al-mulki tu'ti al-mulka man tasha' wa-tanzi'u al-mulka mimman tasha', wa-tu'izzu man tasha' wa-tudhillu man tasha', biyadika al-khayr, innaka 'ala kulli shay'in qadir",
      translation: 'Say: O Allah! Lord over all authorities! You give authority to whoever You please and remove it from whom You please; You honour whoever You please and disgrace whom You please — all good is in Your Hands. Surely You alone are Most Capable of everything.',
      source: 'Quran 3:26 (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Dhul-Jalali wal-Ikram',
    arabic: 'ذُو الْجَلَالِ وَالْإِكْرَامِ',
    emotionalContext: [
      'feeling small before the immensity of life',
      'stripped of dignity by how others have treated you',
      'longing to be honoured after being humiliated',
      'wanting to experience the sacred in daily life',
      'after a crisis has hollowed out your sense of worth',
      'searching for transcendence beyond the ordinary',
    ],
    coreTeaching:
        'Dhul-Jalali wal-Ikram is the Possessor of Majesty and Honour — the One whose very Name contains two paired realities: the Majesty (Jalal) that makes all creation tremble, and the Generosity (Ikram) that honours and dignifies His servants. These are not opposites. Allah’s grandeur does not crush you — it protects you. His honour does not hoard itself — it is given. Surah Ar-Rahman closes with this Name twice. First: "wa-yabqa wajhu Rabbika Dhul-Jalali wal-Ikram" — "Only your Lord Himself, full of Majesty and Honour, will remain forever" (Quran 55:27). And last: "Tabaraka ismu Rabbika Dhil-Jalali wal-Ikram" — "Blessed is the Name of your Lord, full of Majesty and Honour" (Quran 55:78). In a surah that repeats "fa-bi-ayyi alaʼ i Rabbikuma tukadhdhiban" ("So which of your Lord’s favours would you deny?") thirty-one times, the whole surah ends not with creation, not with paradise, but with this Name. Everything passes. Only Dhul-Jalali wal-Ikram remains. And the Prophet ﷺ taught a companion to "be constant" with this Name. In the Tirmidhi hadith (graded Hasan), Anas ibn Malik narrates that whenever the Prophet faced distress, he would say: "Ya Hayyu Ya Qayyum bi-rahmatika astaghith" — and he also instructed: "Alillu bi-ya Dhal-Jalali wal-Ikram" — "Be constant with: O Possessor of Majesty and Honour" (Jamiʼ at-Tirmidhi 3524). This is a Name for daily recitation, not only crisis. Start your duʿa with it. Let it frame the words you bring.',
    propheticStory:
        'A companion was finishing his prayer when the Prophet ﷺ heard him supplicate: "Allahumma inni asʼaluka bi-anna laka al-hamd, la ilaha illa ant, al-Mannan, Badiʿu as-samawati wal-ard, Ya Dhal-Jalali wal-Ikram, Ya Hayyu Ya Qayyum" — "O Allah, I ask You by the fact that all praise belongs to You, there is none worthy of worship except You, the Bestower of blessings, Originator of the heavens and earth, O Possessor of Majesty and Honor, O Living, O Self-Sustaining." The Prophet ﷺ said: "He has supplicated Allah using His Greatest Name — when invoked by it, He responds, and when asked through it, He gives" (Sunan Abi Dawud 1495 — Sahih; Jamiʼ at-Tirmidhi 3544 — Sahih). Dhul-Jalali wal-Ikram is not merely beautiful to invoke. According to the Prophet ﷺ, it may be among the Names through which Allah’s response is guaranteed.',
    dua: NameTeachingDua(
      arabic: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      transliteration: "Allahumma anta as-Salam wa minka as-Salam, tabarakta Ya Dhal-Jalali wal-Ikram",
      translation: 'O Allah! You are Peace, and peace comes from You; Blessed are You, O Possessor of Glory and Honour.',
      source: 'Sahih Muslim 591 — the Prophet’s ﷺ duʿa recited after every prayer (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Muqsit',
    arabic: 'الْمُقْسِطُ',
    emotionalContext: [
      'seething at an injustice you cannot correct',
      'victim of a decision that was simply wrong',
      'watching the guilty walk free',
      'treated unfairly by someone in power',
      'when justice is delayed so long it feels like a lie',
      'carrying anger that has nowhere to go',
    ],
    coreTeaching:
        'Al-Muqsit is the Perfectly Just — the One who deals in absolute equity, from whom no wrong escapes notice and no right goes unrecognized. The root q-s-t means to be fair, to give exactly the right measure. Al-Muqsit is not merely fair in the end; He is Just in His essence. His justice does not depend on courts, on witnesses, on recorded evidence. It is built into His nature. In the Hadith Qudsi narrated by Abu Dharr and recorded in Sahih Muslim, Allah declares: "Ya ʿibadi, inni harramtu az-zulma ʿala nafsi wa-jaʿaltuhu baynakum muharraman fa-la tazalamuu" — "O My servants, I have forbidden oppression for Myself and have made it forbidden amongst you, so do not oppress one another" (Sahih Muslim 2577a). Allah declares injustice forbidden upon Himself. Al-Muqsit is not a distant judge who might or might not see. He has committed, before all of creation, to the abolition of every form of zulm (injustice). The Quran commands believers to embody this Name: "O believers! Stand firm for Allah and bear true testimony. Do not let the hatred of a people lead you to injustice. Be just! That is closer to righteousness. And be mindful of Allah" (Quran 5:8). The Yaqeen Ramadan series prays for Al-Muqsit: "Restore to the victims what was stolen from them, and to the weary hearts what hope they lost." Justice is not hope. It is a Name.',
    propheticStory:
        'At the Farewell Pilgrimage, the Prophet ﷺ stood before the largest gathering of his life and declared: "Verily, your blood, your property, and your honour are sacred to one another as the sacredness of this day, in this month, in this city" (Sahih al-Bukhari 105). He then said: "Have I conveyed?" — and the crowd answered: "Yes." And he said: "O Allah, be witness." Al-Muqsit was being named into the history of that gathering. The Prophet ﷺ was establishing a permanent record: the rights of every human being are inviolable, and the One who guarantees them is watching. When human courts fail, when injustice is never corrected in this life, the Farewell Sermon remains in the record of Al-Muqsit — who will restore what was taken.',
    dua: NameTeachingDua(
      arabic: 'يَا عِبَادِي إِنِّي حَرَّمْتُ الظُّلْمَ عَلَىٰ نَفْسِي وَجَعَلْتُهُ بَيْنَكُمْ مُحَرَّمًا فَلَا تَظَالَمُوا',
      transliteration: "Ya 'ibadi inni harramtu az-zulma 'ala nafsi wa-ja'altuhu baynakum muharraman fa-la tazalamuu",
      translation: 'O My servants, I have forbidden oppression for Myself and have made it forbidden amongst you, so do not oppress one another.',
      source: 'Sahih Muslim 2577a — Hadith Qudsi: Allah’s own words on justice (verbatim, to be recited as a remembrance of Al-Muqsit’s covenant)',
    ),
  ),

  NameTeaching(
    name: 'Al-Ghaniyy',
    arabic: 'الْغَنِيُّ',
    emotionalContext: [
      'scarcity that makes you feel like a burden to everyone',
      'financial anxiety that colours every decision',
      'envy of those who seem to have more',
      'feeling that your need makes you less worthy',
      'exhausted from always being in want',
      'shame around money or material lack',
    ],
    coreTeaching:
        'Al-Ghaniyy is the Self-Sufficient — the One who has absolute, eternal, complete sufficiency that depends on nothing and no one outside Himself. Every act of creation, every breath given, every blessing bestowed is not the output of need but the overflow of pure generosity. The Name appears in one of the Quran’s most arresting declarations: "Ya ayyuha an-nasu, antumu al-fuqaraʼ ila Allahi, wa-Allahu huwa al-Ghaniyy al-Hamid" — "O humanity! It is you who stand in need of Allah, but Allah alone is the Self-Sufficient, Praiseworthy" (Quran 35:15). This is the entire human condition stated in one sentence. Every person reading it is, without exception, a faqir — one in absolute need. And Allah is, without exception, Al-Ghaniyy — needing nothing, overflowing with everything. The consequence is that Al-Ghaniyy’s giving is never reluctant, never a favor that costs Him, never something He weighs against what you deserve. He gives from a supply that cannot be depleted. And in Surah Al-Hadid: "wa-man yatawalla fa-inna Allaha huwa al-Ghaniyy al-Hamid" — "whoever turns away should know that Allah alone is truly the Self-Sufficient, Praiseworthy" (Quran 57:24). Al-Ghaniyy’s sufficiency is not threatened by rejection. He does not need your worship to remain whole. He invites it for your sake, not His. The Yaqeen Ramadan series puts it plainly: "You are free of all need while I am always in need of You. Let me never beg from those as poor as me."',
    propheticStory:
        'The Prophet ﷺ said: "Allah said: ‘O My servants, all of you are astray except for those I have guided, so seek guidance of Me and I shall guide you. O My servants, all of you are hungry except for those I have fed, so seek food of Me and I shall feed you. O My servants, all of you are naked except for those I have clothed, so seek clothing of Me and I shall clothe you’" (Sahih Muslim 2577a). This is the description of Al-Ghaniyy as seen from creation’s side: absolute need met by absolute supply. The Prophet ﷺ taught his companions to bring every need — for guidance, food, clothing, forgiveness — to the One who lacks nothing. The theology is precise: it is irrational to beg from a fellow faqir when Al-Ghaniyy has opened His door.',
    dua: NameTeachingDua(
      arabic: 'يَا عِبَادِي كُلُّكُمْ جَائِعٌ إِلَّا مَنْ أَطْعَمْتُهُ فَاسْتَطْعِمُونِي أُطْعِمْكُمْ',
      transliteration: "Ya 'ibadi kullukum ja'i'un illa man at'amtuhu fa-ista'imuuni ut'imkum",
      translation: 'O My servants, all of you are hungry except for those I have fed, so seek food of Me and I shall feed you.',
      source: 'Sahih Muslim 2577a — Hadith Qudsi: Allah’s words on His sufficiency (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Al-Mughni',
    arabic: 'الْمُغْنِي',
    emotionalContext: [
      'praying for financial relief that hasn’t come',
      'watching others be enriched while you remain in want',
      'fear that your provision will run out',
      'despair after a financial loss',
      'tempted to pursue haram income because halal feels insufficient',
      'economic anxiety keeping you up at night',
    ],
    coreTeaching:
        'Al-Mughni is the Enricher — the One who removes poverty, not just materially but in every form of want: spiritual emptiness, emotional poverty, the ache of feeling that you lack something essential. The root gh-n-y is the same root as Al-Ghaniyy (the Self-Sufficient); Al-Mughni is the One who extends His own sufficiency outward, making others sufficient through His giving. The Quran invokes this attribute at a moment of economic anxiety in the early Muslim community: when the believers feared that cutting off pagan access to the Sacred Mosque would hurt their trading income, Allah replied: "wa-in khiftum ʿaylatan fa-sawfa yughnikumu Allahu min fadlihi" — "If you fear poverty, Allah will enrich you out of His bounty, if He wills" (Quran 9:28). The verb yughnikumu is the active form of Al-Mughni: Allah enriching directly, from His own bounty. And the pattern of Surah Ad-Duhaa reinforces it: Allah reminded His Prophet ﷺ that He had already enriched him after need — "wa-wajadaka ʿaʼilan fa-aghnā" (Quran 93:8). What Allah did for the Prophet He is capable of doing for you. Al-Mughni does not enrich according to how much you deserve or how hard you worked. He enriches "min fadlihi" — from His own bounty, which is without limit and without cost to Him.',
    propheticStory:
        'The Prophet ﷺ redirected his community from measuring richness by possessions to measuring it by inner sufficiency: "Wealth is not in having many possessions, but rather true wealth is feeling sufficiency in the soul" (Sahih al-Bukhari 6446). This is the prophetic lens for Al-Mughni: Allah enriches outwardly when He wills, but He also enriches the chest so a person is not owned by fear of lack. What Allah enriched in the Prophet ﷺ was not merely provision; it was ṣadr — a heart spacious enough to trust the One who gives. And He can enrich yours.',
    dua: NameTeachingDua(
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration: "Rabbana atina fi ad-dunya hasanatan wa fi al-akhirati hasanatan wa qina 'adhab an-nar",
      translation: 'Our Lord! Grant us the good of this world and the good of the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 (verbatim — the supplication that encompasses all provision)',
    ),
  ),

  NameTeaching(
    name: 'Al-Mani',
    arabic: 'الْمَانِعُ',
    emotionalContext: [
      'frustrated when a door closes that you wanted open',
      'angry at a blessing that was withheld',
      'jealous of what others received that you did not',
      'bitter about a missed opportunity',
      'questioning why your prayer was not answered the way you hoped',
      'struggling to accept a "no" from allah',
    ],
    coreTeaching:
        'Al-Mani is the Withholder — the One who prevents, withholds, and shields. This Name is among the hardest to sit with, because it names the divine hand behind every closed door, every denied prayer, every blessing that did not arrive. But the Name only wounds if you misread it. Al-Mani does not withhold to deprive. He withholds to protect. In Surah Al-Muʼminun, Allah answers those who ask who holds ultimate authority: "Qul man biyadihi malakutu kulli shayʼin wa-huwa yujiru wa-la yujaru ʿalayhi" — "Say: In Whose Hands is the authority over all things, protecting all while none can protect against Him?" (Quran 23:88). The One who withholds is the same One who gives refuge. His "no" is a form of His protection. The Prophet ﷺ taught the greatest expression of this understanding after every prayer. The hadith from Sahih al-Bukhari records: "La ilaha illa Allah, wahdahu la sharika lahu. Allahumma la maniʿa lima aʿtayt, wa-la muʿtiya lima manaʿt, wa-la yanfaʿu dhal-jaddi minka al-jadd" — "None has the right to be worshipped but Allah Alone Who has no partner. O Allah! No one can withhold what You give, and none can give what You withhold, and the fortune of a man of means is useless before You" (Sahih al-Bukhari 6615). This is the perfect theological response to a withheld blessing: no human power can override Al-Mani’s decision, and no human power can substitute for Al-Mani’s giving. The door that closed was closed by the One who holds every door.',
    propheticStory:
        'When the Prophet ﷺ sent a companion on a journey, the man had a dream: he was told he would die on the journey. He returned and told the Prophet ﷺ, who said: "Stay." The companion obeyed. The caravan he would have traveled with was attacked, and many were killed. What Al-Mani withheld was not a journey. It was a death. The "no" that prevented something that seemed good was the "yes" to life itself. Every time you are turned away from something you wanted, consider: Al-Mani knows what the journey holds.',
    dua: NameTeachingDua(
      arabic: 'لا إله إلا اللَّهُ وحده لا شريك له. اللَّهُمَّ لا مَانِعَ لِمَا أعْطَيْتَ وَلا مُعْطِيَ لِمَا مَنعتَ ولا ينْفَعُ ذَا الجَدِّ مِنكَ الجَدُّ',
      transliteration: "La ilaha illa Allahu wahdahu la sharika lah. Allahumma la mani'a lima a'tayt, wa la mu'tiya lima mana't, wa la yanfa'u dhal-jaddi minka al-jadd",
      translation: 'None has the right to be worshipped but Allah Alone Who has no partner. O Allah! No one can withhold what You give, and none can give what You withhold, and the fortune of a man of means is useless before You.',
      source: 'Sahih al-Bukhari 6615 (verbatim — recited by the Prophet ﷺ after every prayer)',
    ),
  ),

  NameTeaching(
    name: 'Ad-Darr',
    arabic: 'الضَّارُّ',
    emotionalContext: [
      'in acute suffering with no end in sight',
      'afflicted by pain — physical, emotional, or spiritual — beyond your control',
      'wondering why allah is allowing this to happen to you',
      'desperate for the suffering to stop',
      'angry at the cause of your pain, whether person, illness, or circumstance',
      'when calamity has arrived and your defences have failed',
    ],
    coreTeaching:
        'Ad-Darr is the Bringer of Hardship — the One who, by His absolute will, sends the trials that afflict and test. This is one of the most theologically sensitive Names, because it names divine authorship over pain. But the theology is not cruel — it is liberating. If only Allah can bring harm, then no human being, no illness, no circumstance has the ultimate power over you. The Quran states the principle directly: "wa-in yamsaska Allahu bi-durrin fa-la kashifa lahu illa huwa" — "If Allah touches you with harm, none can undo it except Him" (Quran 6:17). And: "wa-in yamsaska Allahu bi-durrin fa-la kashifa lahu illa huwa, wa-in yuridka bi-khayrin fa-la radda li-fadlihi" — "If Allah touches you with harm, none can undo it except Him. And if He intends good for you, none can withhold His bounty" (Quran 10:107). Ad-Darr and An-Nafi are paired Names — and the pairing is grounded here in the Quranic principle that harm and benefit are both under Allah’s sole command. The One who sends the harm is the same One who removes it. This means your suffering is not in the hands of randomness. It is not abandoned in the cosmos without a plan. It sits in the hands of the One who also holds your healing.',
    propheticStory:
        'The Prophet ﷺ said: "Be mindful of Allah and Allah will protect you. Be mindful of Allah and you will find Him in front of you. If you ask, ask Allah alone; if you seek help, seek help from Allah alone. And know that if the whole of creation were to gather together to benefit you, they could not benefit you except with what Allah had written for you. And if they gathered to harm you, they could not harm you except with what Allah had written against you" (Jamiʼ at-Tirmidhi 2516 — Hasan). This is the hadith of Ad-Darr in its most personal form: the entire universe cannot move the point of your harm by a single degree beyond what has been ordained. This is not resignation — it is the most profound safety. Your suffering is measured.',
    dua: NameTeachingDua(
      arabic: 'وَإِن يَمْسَسْكَ اللَّهُ بِضُرُّ فَلَا كَاشِفَ لَهُ إِلَّا هُوَ ، وَإِن يُرِدْكَ بِخَيْرٍ فَلَا رَآدَّ لِفَضْلِهِ',
      transliteration: "Wa in yamsaska Allahu bi-durrin fa-la kashifa lahu illa huwa, wa in yuridka bi-khayrin fa-la radda li-fadlihi",
      translation: 'If Allah touches you with harm, none can undo it except Him. And if He intends good for you, none can withhold His bounty.',
      source: 'Quran 10:107 (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'An-Nafi',
    arabic: 'النَّافِعُ',
    emotionalContext: [
      'doubting whether your good actions make any difference',
      'feeling that no one benefits from your existence',
      'wondering if your prayers, charity, or kindness actually reach anyone',
      'struggling to see the fruit of a long effort',
      'wanting your life to matter',
      'when your giving goes unnoticed or unappreciated',
    ],
    coreTeaching:
        'An-Nafi is the Bestower of Benefit — the One from whom all good that reaches any created being flows. Where Ad-Darr names divine authorship over hardship, An-Nafi names divine authorship over benefit. Together they form one of the most profound paired Names in Islamic theology: no benefit you receive came from chance, and no harm that reaches you arrived without His knowledge. Every good in your life — every healing, every provision, every meeting that changed your path, every moment of clarity — passed through the hands of An-Nafi before it reached you. The Quran states the principle with precision: "wa-in yuridka bi-khayrin fa-la radda li-fadlihi, yusibu bihi man yashaʼu min ʿibadih" — "if He intends good for you, none can withhold His bounty. He grants it to whoever He wills of His servants" (Quran 10:107). This same verse holds harm and benefit together under Allah’s will, making the pairing with Ad-Darr a Quranic theological principle. The Name also carries a second truth: Allah created benefit itself. Every genuine good that has ever existed — love, justice, healing, knowledge — originated in An-Nafi. When you act with benefit in mind — when you help, give, heal, speak truth — you are channeling the attribute of the One whose essence is benefit.',
    propheticStory:
        'The Prophet ﷺ taught that a Muslim does not abandon another Muslim to oppression, and then said: "Whoever fulfilled the needs of his brother, Allah will fulfill his needs" (Sahih al-Bukhari 2442). This is An-Nafi reflected in human conduct: the benefit you bring to another believer becomes a path by which Allah benefits you. You do not merely receive from An-Nafi — you are invited to embody the attribute by relieving distress, meeting needs, and becoming a door of mercy for someone else.',
    dua: NameTeachingDua(
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      transliteration:
          "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
      translation:
          'Our Lord! Grant us the good of this world and the Hereafter, and protect us from the torment of the Fire.',
      source: 'Quran 2:201 (verbatim excerpt) — a Quranic supplication for every form of beneficial good in this life and the next',
    ),
  ),

  NameTeaching(
    name: 'Al-Badi',
    arabic: 'الْبَدِيعُ',
    emotionalContext: [
      'trapped in a life that feels like it can only be one thing',
      'convinced your situation is impossible to change',
      'waiting for a solution that looks like one you’ve seen before',
      'creative despair — unable to imagine anything new',
      'grief over what feels like a dead end',
      'when the only way forward requires something unprecedented',
    ],
    coreTeaching:
        'Al-Badi is the Incomparable Originator — the One who creates entirely without precedent, with no model, no template, no prior reference. The Arabic root b-d-ʼa names something utterly unprecedented: bidʼa (innovation) comes from the same root. Al-Badi is the Original — the One for whom nothing is without solution because He is the One who created the very category of solution. The Quran states this Name twice in the same context. In Surah Al-Baqarah: "Badiʼu as-samawati wal-ard, wa idha qada amran fa-innama yaqulu lahu kun fa-yakun" — "He is the Originator of the heavens and earth! When He decrees a matter, He simply tells it: ‘Be!’ And it is!" (Quran 2:117). And in Surah Al-Anʿam: "Badiʼu as-samawati wal-ard, anna yakunu lahu waladun" — "He is the Originator of the heavens and earth. How could He have children?" (Quran 6:101). Both verses place Al-Badi in the context of creation that required no prior material, no pre-existing pattern, no assistance. The heavens and earth were made from nothing, by command alone. If Al-Badi could create galaxies from a single word, He can create a way out of your impossible situation from nothing. The hadith tradition affirms: He is called upon by His Greatest Name which, when invoked, brings response — and this Name is among those listed in Sunan Abi Dawud 1495: "Badiʼu as-samawati wal-ard, Ya Dhal-Jalali wal-Ikram, Ya Hayyu Ya Qayyum."',
    propheticStory:
        'When Allah commanded Ibrahim (عليه السلام) to leave his wife Hajar and infant son Ismaʼil in a barren valley with no water and no people, Hajar asked: "Has Allah commanded you to do this?" Ibrahim replied: "Yes." She said: "Then He will not abandon us." She then ran between Safa and Marwa searching for water. Allah’s answer was not an existing spring. He created Zamzam — water from nothing, in the most waterless place, sustained for thousands of years. Al-Badi’s solution to an impossible situation was unprecedented. It always is.',
    dua: NameTeachingDua(
      arabic: 'بَدِيعُ السَّمَاوَاتِ وَالْأَرْضِ ، وَإِذَا قَضَىٰ أَمْرًا فَإِنَّمَا يَقُولُ لَهُ كُن فَيَكُونُ',
      transliteration: "Badi'u as-samawati wal-ard, wa idha qada amran fa-innama yaqulu lahu kun fa-yakun",
      translation: 'He is the Originator of the heavens and earth. When He decrees a matter, He simply says to it: Be! And it is.',
      source: 'Quran 2:117 (verbatim — a declaration of Al-Badi\'s unlimited creative power, used as duʿa-opening)',
    ),
  ),

  NameTeaching(
    name: 'Al-Baqi',
    arabic: 'الْبَاقِي',
    emotionalContext: [
      'grief over what cannot be recovered',
      'watching everything you built crumble',
      'the impermanence of everything you love',
      'terrified of losing the people who matter most to you',
      'struggling with aging, endings, and finitude',
      'looking for something that will not disappear',
    ],
    coreTeaching:
        'Al-Baqi is the Ever-Lasting — the One who remains when everything else has gone. This Name is the answer to every form of grief over impermanence: the relationship that ended, the health that left, the season of life that closed, the person who died. Everything that passes is passing. Only Al-Baqi remains. The Quran states the principle with startling directness in Surah Ar-Rahman: "Kullu man ʿalayha fan" — "Every being on earth is bound to perish" (Quran 55:26). And then immediately: "wa-yabqa wajhu Rabbika Dhul-Jalali wal-Ikram" — "Only your Lord Himself, full of Majesty and Honour, will remain forever" (Quran 55:27). Between those two verses is the entire human experience of loss. And its resolution: Al-Baqi. The Quran elsewhere offers the most practical expression: "ma ʿindakum yanfadu, wa-ma ʿinda Allahi baq" — "Whatever you have will end, but whatever Allah has is everlasting" (Quran 16:96). This verse was revealed in a context of reward for patience — but the principle is universal. Everything you have is on loan. Everything He has is permanent. And in Surah Al-Qasas: "kullu shayʼin halik illawajhahu" — "Everything is bound to perish except He Himself" (Quran 28:88). Al-Baqi’s permanence is not cold philosophy. It is the ground you stand on when everything else shifts. When you are afraid of losing what you love, bring that fear to the One who cannot be lost.',
    propheticStory:
        'When the Sahabi Khabbab ibn al-Aratt was tortured by the Meccans for years — burned, beaten, enslaved — he came to the Prophet ﷺ and said: "O Messenger of Allah, will you not ask Allah to help us?" The Prophet ﷺ, sitting with his back against the Kaaba, said: "Among those before you, a man would be placed in a ditch dug for him, and a saw would be placed on his head... and that would not cause him to abandon his religion. By Allah, this religion will be perfected until a rider travels from Sanaʼa to Hadramawt fearing nothing but Allah..." (Sahih al-Bukhari 3612). The Prophet ﷺ’s response to the suffering of the moment was to point to Al-Baqi’s timeline: what endures. The torture is temporary. The din is not. The reward is not. The promise of Al-Baqi is not.',
    dua: NameTeachingDua(
      arabic: 'مَا عِندَكُمْ يَنفَدُ ، وَمَا عِندَ اللَّهِ بَاقٍ ، وَلَنَجْزِيَنَّ الَّذِينَ صَبَرُوا أَجْرَهُم بِأَحْسَنِ مَا كَانُوا يَعْمَلُونَ',
      transliteration: "Ma 'indakum yanfadu, wa ma 'inda Allahi baq, wa lanajziyana alladhina sabaru ajrahum bi ahsani ma kanu ya'malun",
      translation: 'Whatever you have will end, but whatever Allah has is everlasting. And We will certainly reward the steadfast according to the best of their deeds.',
      source: 'Quran 16:96 (verbatim)',
    ),
  ),

  NameTeaching(
    name: 'Ar-Rasheed',
    arabic: 'الرَّشِيدُ',
    emotionalContext: [
      'paralysed by indecision at a crossroads',
      'unable to tell the right path from the wrong one',
      'aftermath of a bad decision you regret',
      'searching for wisdom you do not feel you possess',
      'confused by conflicting advice from people you trust',
      'praying for clarity that hasn’t come yet',
    ],
    coreTeaching:
        'Ar-Rasheed is the Infallible Guide to the Right Path — the One whose guidance is never mistaken, never late, never partial. The root r-sh-d in Arabic names guidance that reaches its mark: rashad is right direction found, not merely direction given. Ar-Rasheed’s guidance is not instruction from a distance. It is the turning of the heart, the opening of a door at the right moment, the sudden clarity that you did not manufacture. The Quran uses this root in the prayer of the companions of the Cave: "Rabbana atina min ladunka rahmatan wa-hayyiʼ lana min amrina rashada" — "Our Lord! Grant us mercy from Yourself and guide us rightly through our ordeal" (Quran 18:10). Rashad: the right way through. They did not ask for the easiest path. They asked for the guided one. The Yaqeen Ramadan series frames Ar-Rasheed with precision: "teach me to see truth instinctively. Make faith beloved to me." And the Name also appears in the Quran in a subtle moment: the jinn who accepted Islam said, "We do not know whether evil is intended for those on earth, or their Lord intends for them rashadan" — "right guidance" (Quran 72:10). Rashad is what Allah intends. The question is whether you are oriented to receive it. Istikhara — the prayer of seeking guidance — is the practice built directly on this Name. When you do not know which way to turn, Ar-Rasheed does.',
    propheticStory:
        'The Prophet ﷺ was asked about the verse: "And He found you lost (dallan) and guided you" (Quran 93:7). The early commentators noted: the Prophet ﷺ before prophethood did not know the full way. He was searching. Ar-Rasheed guided him — not all at once, not with a map, but revelation by revelation, moment by moment, over twenty-three years. The guidance of Ar-Rasheed is rarely the lightning flash. It is more often the gentle, persistent light that arrives as needed. Ibrahim (عليه السلام) asked for guidance before he knew toward what he was asking; the Prophet ﷺ received it in increments. Ar-Rasheed guides as the journey requires it, not all at once.',
    dua: NameTeachingDua(
      arabic: 'اللَّهُمَّ إنِّي أَسْأَلُكَ الهُدَىٰ وَالتُّقَىٰ وَالْعَفَافَ وَالغِنَىٰ',
      transliteration: "Allahumma inni as'aluka al-huda wat-tuqa wal-'afafa wal-ghina",
      translation: 'O Allah, I ask You for guidance, piety, chastity, and self-sufficiency.',
      source: 'Sahih Muslim 2721 — narrated by Ibn Masʿud, a supplication taught by the Prophet ﷺ (verbatim)',
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
    MapEntry(['allah absent from my life', "can't see allah anywhere", 'spiritually disconnected', 'only focused on appearances', 'heart feels dirty', 'hidden resentment', "can't find meaning in daily life", 'mundane has no connection to god', 'is god really there', "feel like allah doesn't see me", 'hollow inside externally fine'], 26), // Al-Dhahir/Al-Batin
    MapEntry(['feel empty', 'void inside', 'still not satisfied', 'chasing the next thing', 'filling emptiness', 'looking for completion', 'restless despite blessings', 'always wanting more', 'shopping to feel better', 'career not fulfilling', 'missing something'], 27), // Al-Ghani
    MapEntry(['chasing approval from people', 'compromising deen for status', 'give up values to get ahead', 'seeking honor from boss', 'disrespected', 'sacrificing prayers for career', 'islam holding me back', 'worried what people think', 'people-pleasing', 'feel humiliated', 'giving up identity for acceptance', 'career pressure to fit in', 'selling out', 'am i sacrificing allah'], 28), // Al-Mu'izz/Al-Mudhil
    MapEntry(['broken heart', 'broken', 'fix me', 'something is wrong', "can't be fixed", 'no one can help', "doctors don't know", 'feel shattered', 'emotionally broken', 'financially broke', 'need to be mended', 'being forced', 'someone controlling me'], 29), // Al-Jabbar
    MapEntry(['overpowered', 'helpless', 'stuck', "can't break", 'addiction', 'doing it alone', 'people let me down', 'no way out', 'too weak', 'overwhelmed', 'self-sufficient', "can't find a way"], 30), // An-Nasir
    MapEntry(['scared about the future', 'big transition', 'between jobs', "waiting and don't know what's next", 'no one looking out for me', 'feel abandoned in hard season', 'have to figure it all out myself', "can't see how it will work out", 'feel on my own', 'everything changed and not ready', 'who is taking care of me', 'going through transition'], 31), // Ar-Rabb
    MapEntry(['anxious about money', 'worried about provision', 'scared about finances', 'feel like i have to figure out finances alone', "scared i won't have enough", "jealous of others' wealth", 'boss controls my future', 'scarcity mindset', "can't trust things will work out", 'grinding but not enough', "feel like i'm providing for everyone", 'slave to the means'], 32), // Ar-Razzaq
    MapEntry(['far from allah', 'feel distant', "allah doesn't hear", 'dua unanswered', 'stopped making dua', 'sins pushed me away', "don't feel worthy to ask", 'feel alone with my problems', 'nobody understands'], 33), // Al-Qarib/Al-Mujib
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

// ---------------------------------------------------------------------------
// Dua normalization — keep the AI from rendering transliteration as scripture
// ---------------------------------------------------------------------------
//
// The reflect prompt asks the model to emit the dua's Arabic text directly.
// When the model uses one of the teaching duas above, it has only seen the
// transliteration (the teaching context historically omitted the Arabic), so —
// correctly refusing to fabricate scripture — it copies the transliteration
// into the Arabic slot. The reflect UI then renders transliteration where
// Arabic should be (reported bug: "Rabbi ishrah li sadri wa yassir li amri"
// shown as the Arabic dua).
//
// `normalizeReflectDua` is the deterministic safety net: it recovers the
// verified Arabic from this knowledge base whenever it can identify which dua
// the model used, and otherwise guards the Arabic slot against non-Arabic text.

/// Arabic script Unicode block (U+0600–U+06FF). Covers the letters and harakat
/// used by every dua/verse in this app.
final RegExp _arabicScript = RegExp(r'[؀-ۿ]');

/// True when [text] contains at least one Arabic-script character.
bool containsArabicScript(String text) => _arabicScript.hasMatch(text);

/// Collapse a transliteration to a comparison key: lowercase, strip everything
/// that isn't a latin letter or digit. Makes matching tolerant of apostrophes,
/// hyphens, commas, diacritics, and spacing the model may add or drop.
String _transliterationKey(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Lazily-built lookup from a normalized transliteration key to its verified
/// `NameTeachingDua`. Built once on first access.
Map<String, NameTeachingDua>? _duaByTransliterationKey;

Map<String, NameTeachingDua> get _duaLookup {
  final cached = _duaByTransliterationKey;
  if (cached != null) return cached;
  final map = <String, NameTeachingDua>{};
  for (final teaching in nameTeachings) {
    final key = _transliterationKey(teaching.dua.transliteration);
    // First teaching wins on collisions; teaching duas are distinct in practice.
    map.putIfAbsent(key, () => teaching.dua);
  }
  return _duaByTransliterationKey = map;
}

/// Find a verified teaching dua whose transliteration matches [transliteration]
/// (case/punctuation/spacing-insensitive). Returns null for null/empty/unknown.
NameTeachingDua? teachingDuaByTransliteration(String? transliteration) {
  if (transliteration == null) return null;
  final key = _transliterationKey(transliteration);
  if (key.isEmpty) return null;
  return _duaLookup[key];
}

/// Normalize an AI-produced dua against the verified knowledge base.
///
/// 1. Robust substitution: if the model's transliteration (or the Arabic slot,
///    in case the transliteration leaked into it) matches a verified teaching
///    dua, return that verified record verbatim — we never trust the model to
///    reproduce scripture.
/// 2. Guard: with no canonical match, the Arabic slot must actually contain
///    Arabic script. If it doesn't (transliteration/English leaked in), blank
///    it so the UI never renders transliteration as Arabic; the transliteration,
///    translation, and source fields are preserved so the card still conveys
///    the dua textually.
NameTeachingDua normalizeReflectDua({
  required String arabic,
  required String transliteration,
  required String translation,
  required String source,
}) {
  final matched = teachingDuaByTransliteration(transliteration) ??
      teachingDuaByTransliteration(arabic);
  if (matched != null) return matched;

  final safeArabic = containsArabicScript(arabic) ? arabic : '';
  return NameTeachingDua(
    arabic: safeArabic,
    transliteration: transliteration,
    translation: translation,
    source: source,
  );
}
