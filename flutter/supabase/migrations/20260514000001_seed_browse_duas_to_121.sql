-- Seed the 45 browse_duas rows added in PR #12 that were never migrated to remote.
-- Idempotent: ON CONFLICT (id) DO NOTHING skips any row already present.

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'addiction-1',
  'addiction'::public.dua_category,
  'When you feel powerless against a habit',
  'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ',
  'Allahumma inni a''udhu bika minal-hammi wal-hazani, wal-''ajzi wal-kasali, wal-jubni wal-bukhli, wa dhala''id-dayni, wa ghalabatir-rijal',
  'O Allah! I seek refuge with You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from being heavily in debt and from being overpowered by (other) men.',
  'Sahih al-Bukhari 6369',
  ARRAY['addiction','weakness','self-control','powerlessness','anxiety'],
  'Recite morning and evening, or whenever you feel overcome by compulsion, lethargy, or the sense that you cannot break free from a destructive habit.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'addiction-2',
  'addiction'::public.dua_category,
  'Grant my soul its piety and purify it',
  'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ وَالْجُبْنِ وَالْبُخْلِ وَالْهَرَمِ وَعَذَابِ الْقَبْرِ اللَّهُمَّ آتِ نَفْسِي تَقْوَاهَا وَزَكِّهَا أَنْتَ خَيْرُ مَنْ زَكَّاهَا',
  'Allahumma inni a''udhu bika minal-''ajzi wal-kasali wal-jubni wal-bukhli wal-harami wa ''adhabil-qabri. Allahumma ati nafsi taqwaha wa zakkiha anta khayru man zakkaha',
  'O Allah, I seek refuge in You from incapacity, from sloth, from cowardice, from miserliness, from decrepitude, and from torment of the grave. O Allah, grant to my soul the sense of righteousness and purify it, for You are the Best Purifier thereof.',
  'Sahih Muslim 2722',
  ARRAY['addiction','nafs','self-control','purification','spiritual-struggle'],
  'Recite when struggling against the nafs (self) that pulls toward sin or harmful habits, or when seeking inner purification and taqwa.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'addiction-3',
  'addiction'::public.dua_category,
  'Seeking refuge when Shaytan whispers',
  'وَإِمَّا يَنزَغَنَّكَ مِنَ ٱلشَّيْطَـٰنِ نَزْغٌۭ فَٱسْتَعِذ بِٱللَّهِ ۚ إِنَّهُۥ سَمِيعٌ عَلِيمٌ',
  'Wa imma yanzaghannaka mina ash-shaytani nazghun fas-ta''idh billah, innahu sami''un ''alim',
  'If you are tempted by Satan, then seek refuge with Allah. Surely He is All-Hearing, All-Knowing.',
  'Quran 7:200',
  ARRAY['addiction','temptation','shaytan','self-control','craving'],
  'Recite ''A''udhu billahi min ash-shaytanir-rajim'' the moment a craving or compulsion arises. This verse is the scriptural command to do so.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'addiction-4',
  'addiction'::public.dua_category,
  'Acknowledging the nafs that inclines to evil',
  'وَمَآ أُبَرِّئُ نَفْسِىٓ ۚ إِنَّ ٱلنَّفْسَ لَأَمَّارَةٌۢ بِٱلسُّوٓءِ إِلَّا مَا رَحِمَ رَبِّىٓ ۚ إِنَّ رَبِّى غَفُورٌۭ رَّحِيمٌۭ',
  'Wa ma ubarri''u nafsi, innan-nafsa la-''ammaratun bis-su''i illa ma rahima rabbi, inna rabbi ghafurun rahim',
  'And I do not seek to free myself from blame, for indeed the soul is ever inclined to evil, except those shown mercy by my Lord. Surely my Lord is All-Forgiving, Most Merciful.',
  'Quran 12:53',
  ARRAY['addiction','shame','nafs','self-blame','mercy','relapse'],
  'Reflect on this verse when struggling with relapse or self-blame. It acknowledges the nafs''s tendency honestly while affirming that Allah''s mercy is the path out — not willpower alone.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'anger-1',
  'anger'::public.dua_category,
  'When anger overtakes you',
  'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ',
  'A''udhu billahi mina-sh-shaytan',
  'I seek refuge with Allah from Satan.',
  'Sahih al-Bukhari 3282',
  ARRAY['anger','self-control','rage'],
  'When feeling rage rising or witnessing someone in anger'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'anger-2',
  'anger'::public.dua_category,
  'Seeking refuge from Satan''s provocation',
  'رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَٰتِ ٱلشَّيَـٰطِينِ وَأَعُوذُ بِكَ رَبِّ أَن يَحْضُرُونِ',
  'Rabbi a''udhu bika min hamazati-sh-shayatini wa-a''udhu bika rabbi an yahdhurun',
  'My Lord! I seek refuge in You from the temptations of the devils. And I seek refuge in You, my Lord, that they even come near me.',
  'Quran 23:97-98',
  ARRAY['anger','temptation','self-control','spiritual-protection'],
  'When feeling provoked, stirred to anger, or sensing evil whispers'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'anger-3',
  'anger'::public.dua_category,
  'When the devil provokes your heart',
  'وَإِمَّا يَنزَغَنَّكَ مِنَ ٱلشَّيْطَـٰنِ نَزْغٌۭ فَٱسْتَعِذْ بِٱللَّهِ ۚ إِنَّهُۥ سَمِيعٌ عَلِيمٌ',
  'Wa-imma yanazghannaka mina-sh-shaytani nazghun fa-sta''idh billah, innahu Sami''un ''Alim',
  'If you are tempted by Satan, then seek refuge with Allah. Surely He is All-Hearing, All-Knowing.',
  'Quran 7:200',
  ARRAY['anger','patience','spiritual-protection'],
  'When feeling irritation, provocation, or a sudden surge of anger'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'burnout-1',
  'burnout'::public.dua_category,
  'Relief from exhaustion, worry, and overwhelm',
  'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْجُبْنِ وَالْبُخْلِ، وَضَلَعِ الدَّيْنِ، وَغَلَبَةِ الرِّجَالِ',
  'Allahumma inni a''udhu bika min al-hammi wal-hazani, wal-''ajzi wal-kasali, wal-jubni wal-bukhli, wa dhala''id-dayni, wa ghalabatir-rijal',
  'O Allah! I seek refuge with You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from being heavily in debt and from being overpowered by (other) men.',
  'Sahih al-Bukhari 6369',
  ARRAY['burnout','exhaustion','overwhelm','anxiety','grief'],
  'When exhaustion, overwhelm, or a crushing sense of ''I can''t go on'' sets in. The Prophet ﷺ frequently recited this prayer — seeking Allah''s protection from the very feelings that burnout brings: worry, grief, and incapacity.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'burnout-2',
  'burnout'::public.dua_category,
  'Do not burden us beyond what we can bear',
  'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًۭا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعْفُ عَنَّا وَٱغْفِرْ لَنَا وَٱرْحَمْنَآ ۚ أَنتَ مَوْلَىٰنَا فَٱنصُرْنَا عَلَى ٱلْقَوْمِ ٱلْكَـٰفِرِينَ',
  'Rabbana la tu''akhidhna in nasina aw akhta''na, Rabbana wa la tahmil ''alayna isran kama hamaltahu ''alal-ladhina min qablina, Rabbana wa la tuhammilna ma la taqata lana bih, wa''fu ''anna waghfir lana warhamna, anta mawlana fansurna ''alal-qawmil-kafirin',
  'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one you placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our ˹only˺ Guardian. So grant us victory over the disbelieving people.',
  'Quran 2:286',
  ARRAY['burnout','overwhelm','exhaustion','overburdened'],
  'When you feel crushed by life''s weight and cannot carry on — Allah Himself promises He does not burden a soul beyond its capacity. This prayer is the closing supplication of Surah Al-Baqarah and beloved to recite morning and night.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'burnout-3',
  'burnout'::public.dua_category,
  'Musa''s prayer when his people failed him',
  'رَبِّ لَوْ شِئْتَ أَهْلَكْتَهُم مِّن قَبْلُ وَإِيَّـٰىَ ۖ أَتُهْلِكُنَا بِمَا فَعَلَ ٱلسُّفَهَآءُ مِنَّآ ۖ إِنْ هِىَ إِلَّا فِتْنَتُكَ تُضِلُّ بِهَا مَن تَشَآءُ وَتَهْدِى مَن تَشَآءُ ۖ أَنتَ وَلِيُّنَا فَٱغْفِرْ لَنَا وَٱرْحَمْنَا ۖ وَأَنتَ خَيْرُ ٱلْغَـٰفِرِينَ',
  'Rabbi law shi''ta ahlaktahum min qablu wa iyyaya, atuhlikuna bima fa''ala-s-sufaha''u minna, in hiya illa fitnatuka tudillu biha man tasha''u wa tahdi man tasha''u, anta waliyyuna faghfir lana warhamna wa anta khayrul-ghafirin',
  'My Lord! Had You willed, You could have destroyed them long ago, and me as well. Will You destroy us for what the foolish among us have done? This is only a test from You—by which You allow whoever You will to stray and guide whoever You will. You are our Guardian. So forgive us and have mercy on us. You are the best forgiver.',
  'Quran 7:155',
  ARRAY['burnout','leadership exhaustion','responsibility','feeling failed by others'],
  'When you are burned out from carrying responsibility for others — leading, guiding, or caring while people around you fail. Musa (AS) prayed this when exhausted by his people''s failures. Acknowledge that guidance is in Allah''s hands, not yours alone.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'burnout-4',
  'burnout'::public.dua_category,
  'Grant us mercy and guide us through our ordeal',
  'رَبَّنَآ ءَاتِنَا مِن لَّدُنكَ رَحْمَةًۭ وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًۭا',
  'Rabbana atina min ladunka rahmatan wa hayyi'' lana min amrina rashada',
  'Our Lord! Grant us mercy from Yourself and guide us rightly through our ordeal.',
  'Quran 18:10',
  ARRAY['burnout','exhaustion','seeking refuge','overwhelm','guidance needed'],
  'The prayer of the People of the Cave — young people who fled oppression and exhaustion, took refuge, and asked only for mercy and guidance. Recite when you have no energy left and need Allah to show you a way through.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'death_grief-1',
  'death_grief'::public.dua_category,
  'When struck by loss — Inna lillahi wa inna ilayhi raji''un',
  'إِنَّا لِلَّهِ وَإِنَّآ إِلَيْهِ رَٰجِعُونَ',
  'Inna lillahi wa inna ilayhi raji''un',
  'Surely to Allah we belong and to Him we will all return.',
  'Quran 2:156',
  ARRAY['death_grief','loss','mourning','inna lillahi','calamity','patience'],
  'Say immediately upon hearing of a death or calamity. This is the verse the Quran records believers saying when struck by any disaster. It is both a statement of faith and a supplication of surrender.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'death_grief-2',
  'death_grief'::public.dua_category,
  'The Prophet''s dua at the moment of death',
  'اللَّهُمَّ اغْفِرْ لأَبِي سَلَمَةَ وَارْفَعْ دَرَجَتَهُ فِي الْمَهْدِيِّينَ وَاخْلُفْهُ فِي عَقِبِهِ فِي الْغَابِرِينَ وَاغْفِرْ لَنَا وَلَهُ يَا رَبَّ الْعَالَمِينَ وَافْسَحْ لَهُ فِي قَبْرِهِ وَنَوِّرْ لَهُ فِيهِ',
  'Allahumma-ghfir li Abi Salamata warfa'' darajatahu fil-mahdiyyin, wakhlufhu fi ''aqibihi fil-ghābirin, waghfir lana wa lahu ya Rabbal-''alamin, waf-sah lahu fi qabrihi wa nawwir lahu fih',
  'O Allah, forgive Abu Salama, raise his degree among those who are rightly guided, grant him a successor in his descendants who remain. Forgive us and him, O Lord of the Universe, and make his grave spacious, and grant him light in it.',
  'Sahih Muslim 920a',
  ARRAY['death_grief','janazah','mourning','dua-for-deceased','funeral'],
  'Recite (substituting the deceased''s name) immediately after someone passes away, or at the moment of closing the eyes. The Prophet (peace be upon him) said this over Abu Salama and reminded those present: ''Do not supplicate for yourselves anything but good, for angels say Amen to what you say.'''
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'death_grief-3',
  'death_grief'::public.dua_category,
  'Dua for consolation after loss — asking for a better successor',
  'اللَّهُمَّ اغْفِرْ لِي وَلَهُ وَأَعْقِبْنِي مِنْهُ عُقْبَى حَسَنَةً',
  'Allahumma-ghfir li wa lahu wa a''qibni minhu ''uqba hasana',
  'O Allah, forgive me and him, and grant me in his place a good successor.',
  'Sahih Muslim 919',
  ARRAY['death_grief','loss','mourning','consolation','acceptance','widowhood'],
  'Say when you have lost someone dear — a spouse, parent, or companion — and feel the grief of their absence. The Prophet (peace be upon him) taught Umm Salama these words after her husband''s death.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'death_grief-4',
  'death_grief'::public.dua_category,
  'Those who persevere — Allah''s blessings and mercy are upon them',
  'أُو۟لَـٰٓئِكَ عَلَيْهِمْ صَلَوَٰتٌۭ مِّن رَّبِّهِمْ وَرَحْمَةٌۭ ۖ وَأُو۟لَـٰٓئِكَ هُمُ ٱلْمُهْتَدُونَ',
  'Ula''ika ''alayhim salawatun min rabbihim wa rahma, wa ula''ika humul-muhtadun',
  'They are the ones who will receive Allah''s blessings and mercy. And it is they who are rightly guided.',
  'Quran 2:157',
  ARRAY['death_grief','patience','comfort','mercy','mourning','hope'],
  'Recite for comfort after loss. This verse follows 2:156 (inna lillahi) and 2:155 (the promise of tests) — it is Allah''s direct response to those who say ''inna lillahi'', promising them His salawat (blessings) and mercy.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'envy-1',
  'envy'::public.dua_category,
  'Protection from the evil eye',
  'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ وَمِنْ كُلِّ عَيْنٍ لاَمَّةٍ',
  'A''udhu bi-kalimat-Allahi-t-tammati min kulli shaytanin wa hammatin wa-min kulli ''aynin lammah',
  'I seek refuge in the Perfect Words of Allah from every devil, every harmful creature, and every harmful evil eye.',
  'Sunan Ibn Majah 3525',
  ARRAY['envy','evil-eye','spiritual-protection','jealousy'],
  'When seeking protection for yourself, your children, or loved ones from envy or the evil eye. The Prophet ﷺ used this supplication over Hasan and Husayn.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'envy-2',
  'envy'::public.dua_category,
  'Protection from all harm through Allah''s perfect words',
  'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
  'A''udhu bi-kalimat-Allahi-t-tammati min sharri ma khalaq',
  'I seek refuge in the Perfect Words of Allah from the evil of that which He has created.',
  'Sunan Ibn Majah 3518',
  ARRAY['envy','spiritual-protection','evil-eye','fear'],
  'Morning and evening, and whenever fearing envy, harm, or malice from others'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'envy-3',
  'envy'::public.dua_category,
  'Asking Allah to purify your heart from bitterness toward others',
  'رَبَّنَا ٱغْفِرْ لَنَا وَلِإِخْوَٰنِنَا ٱلَّذِينَ سَبَقُونَا بِٱلْإِيمَـٰنِ وَلَا تَجْعَلْ فِى قُلُوبِنَا غِلًّۭا لِّلَّذِينَ ءَامَنُوا۟ رَبَّنَآ إِنَّكَ رَءُوفٌۭ رَّحِيمٌ',
  'Rabbana-ghfir lana wa-li-ikhwaninallladhina sabaquna bi-l-imani wa-la taj''al fi qulubina ghillan lilladhina amanu rabbana innaka Ra''ufun Rahim',
  'Our Lord! Forgive us and our fellow believers who preceded us in faith, and do not allow bitterness into our hearts towards those who believe. Our Lord! Indeed, You are Ever Gracious, Most Merciful.',
  'Quran 59:10',
  ARRAY['envy','jealousy','heart-purification','forgiveness'],
  'When sensing jealousy or resentment stirring in the heart toward another believer'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'illness-1',
  'illness'::public.dua_category,
  'The Prophet''s healing prayer over the sick',
  'أَذْهِبِ الْبَاسَ رَبَّ النَّاسِ، اشْفِ وَأَنْتَ الشَّافِي، لاَ شِفَاءَ إِلاَّ شِفَاؤُكَ، شِفَاءً لاَ يُغَادِرُ سَقَمًا',
  'Adh-hibil-ba''sa Rabban-nas, ishfi wa antash-shafi, la shifa''a illa shifa''uk, shifa''an la yughadiru saqama',
  'Take away the disease, O the Lord of the people! Cure him as You are the One Who cures. There is no cure but Yours, a cure that leaves no disease.',
  'Sahih al-Bukhari 5675',
  ARRAY['illness','healing','sickness','hope','tawakkul'],
  'Recite when visiting someone who is sick, or when ill yourself. The Prophet (peace be upon him) would wipe the sick person with his right hand while saying these words.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'illness-2',
  'illness'::public.dua_category,
  'Placing your hand on pain and seeking refuge',
  'بِسْمِ اللَّهِ، أَعُوذُ بِاللَّهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ',
  'Bismillah. A''udhu billahi wa qudratihi min sharri ma ajidu wa uhadhir',
  'In the name of Allah. I seek refuge with Allah and with His Power from the evil that I find and that I fear.',
  'Sahih Muslim 2202',
  ARRAY['illness','pain','healing','sickness','physical-distress'],
  'When experiencing physical pain or illness. Place your hand on the site of pain, say Bismillah three times, then say the refuge prayer seven times, as the Prophet ﷺ taught Uthman ibn Abi al-''As.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'illness-3',
  'illness'::public.dua_category,
  'Asking Allah, Lord of the Mighty Throne, to heal',
  'أَسْأَلُ اللَّهَ الْعَظِيمَ رَبَّ الْعَرْشِ الْعَظِيمِ أَنْ يَشْفِيَكَ',
  'As''alullaha al-''azima rabbal-''arshil-''azimi an yashfiyak',
  'I ask Allah, the Mighty, the Lord of the Mighty Throne, to cure you.',
  'Sunan Abi Dawud 3106',
  ARRAY['illness','healing','visiting-the-sick','intercession','hope'],
  'Recite seven times when visiting a sick person whose time of death has not yet come. The Prophet (peace be upon him) said Allah will cure them of that disease.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'illness-4',
  'illness'::public.dua_category,
  'Removing hardship — the Prophet''s ruqyah from Sahih al-Bukhari',
  'امْسَحِ الْبَاسَ رَبَّ النَّاسِ، بِيَدِكَ الشِّفَاءُ، لاَ كَاشِفَ لَهُ إِلاَّ أَنْتَ',
  'Imsahil-ba''sa Rabban-nas, biyadikas-shifa'', la kashifa lahu illa ant',
  'Remove the hardship, O Lord of the people. The cure is in Your Hand. There is no one who can remove it except You.',
  'Sahih al-Bukhari 5744',
  ARRAY['illness','healing','ruqyah','sickness','reliance-on-Allah'],
  'Recite when performing ruqyah on a sick person, passing the right hand gently over them. This is a variant of the Prophet''s healing formula, narrated by Aisha (RA).'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'loneliness-1',
  'loneliness'::public.dua_category,
  'When you feel utterly alone',
  'لَّآ إِلَـٰهَ إِلَّآ أَنتَ سُبْحَـٰنَكَ إِنِّى كُنتُ مِنَ ٱلظَّـٰلِمِينَ',
  'La ilaha illa anta subhanaka inni kuntu min adh-dhalimin',
  'There is no god ˹worthy of worship˺ except You. Glory be to You! I have certainly done wrong.',
  'Quran 21:87',
  ARRAY['loneliness','abandonment','despair','isolation'],
  'Recite in moments of isolation, distress, or when you feel abandoned — as Prophet Yunus (AS) called out from the darkness of the whale''s belly. Allah answered him; He will answer you.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'loneliness-2',
  'loneliness'::public.dua_category,
  'During moments of distress and isolation',
  'لاَ إِلَهَ إِلاَّ اللَّهُ الْعَظِيمُ الْحَلِيمُ، لاَ إِلَهَ إِلاَّ اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لاَ إِلَهَ إِلاَّ اللَّهُ رَبُّ السَّمَوَاتِ، وَرَبُّ الأَرْضِ، وَرَبُّ الْعَرْشِ الْكَرِيمِ',
  'La ilaha illallahu al-''Azim al-Halim, la ilaha illallahu Rabbul-''arsh il-''azim, la ilaha illallahu Rabbu-s-samawati wa Rabbul-ard wa Rabbul-''arsh il-karim',
  'There is no god but Allah, the Magnificent, the Forbearing. There is no god but Allah, Lord of the Magnificent Throne. There is no god but Allah, Lord of the heavens, Lord of the earth, and Lord of the Noble Throne.',
  'Sahih al-Bukhari 6346',
  ARRAY['loneliness','distress','anxiety','overwhelm'],
  'Recite at a time of distress (عِنْدَ الْكَرْبِ) — when loneliness, grief, or anxiety overwhelms you. The Prophet ﷺ used to say this during hardship.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'loneliness-3',
  'loneliness'::public.dua_category,
  'Returning to Allah when you feel cut off',
  'اللَّهُمَّ أَنْتَ رَبِّي، لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَىَّ وَأَبُوءُ لَكَ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ',
  'Allahumma anta rabbi, la ilaha illa anta, khalaqtani wa ana ''abduka, wa ana ''ala ''ahdika wa wa''dika masta-ta''tu, a''udhu bika min sharri ma sana''tu, abu''u laka bini''matika ''alayya wa abu''u laka bidhanbi, faghfir li, fa innahu la yaghfiru-dh-dhunuba illa ant',
  'O Allah, You are my Lord, there is none worthy of worship except You. You have created me, and I am Your servant, and I am faithful to Your covenant and promise as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessings upon me, and I admit my sins. So forgive me, for none forgives sins except You.',
  'Sahih al-Bukhari 6306',
  ARRAY['loneliness','spiritual disconnection','guilt','seeking forgiveness'],
  'The Master of Seeking Forgiveness (Sayyid al-Istighfar) — recite in the morning and evening, and whenever you feel spiritually distant or cut off from Allah. It is a declaration of belonging: ''You are my Lord.'''
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'loneliness-4',
  'loneliness'::public.dua_category,
  'Surrendering to Allah — excerpt from the night prayer',
  'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ رَبُّ السَّمَوَاتِ وَالأَرْضِ، لَكَ الْحَمْدُ أَنْتَ قَيِّمُ السَّمَوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ، لَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَوَاتِ وَالأَرْضِ، اللَّهُمَّ لَكَ أَسْلَمْتُ، وَبِكَ آمَنْتُ، وَعَلَيْكَ تَوَكَّلْتُ، وَإِلَيْكَ أَنَبْتُ، فَاغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ، وَأَسْرَرْتُ وَأَعْلَنْتُ، أَنْتَ إِلَهِي لاَ إِلَهَ لِي غَيْرُكَ',
  'Allahumma lakal-hamdu anta Rabbu-s-samawati wal-ard, lakal-hamdu anta qayyimu-s-samawati wal-ardi wa man fihinn, lakal-hamdu anta nuru-s-samawati wal-ard, Allahumma laka aslamtu, wa bika amantu, wa ''alayka tawakkaltu, wa ilayka anabtu, faghfir li ma qaddamtu wa ma akhkhartu, wa asrartu wa a''lantu, anta ilahi la ilaha li ghairuk',
  'O Allah: All the Praises are for You: You are the Lord of the Heavens and the Earth. All the Praises are for You; You are the Maintainer of the Heaven and the Earth and whatever is in them. All the Praises are for You; You are the Light of the Heavens and the Earth. O Allah! I surrender myself to You, and I believe in You and I depend upon You, and I repent to You. O Allah! Forgive me my sins that I did in the past or will do in the future, and also the sins I did in secret or in public. You are my only God (Whom I worship) and there is no other God for me.',
  'Sahih al-Bukhari 7385',
  ARRAY['loneliness','isolation','spiritual surrender','seeking Allah''s presence'],
  'When loneliness makes you feel the world has left you — declare to Allah: ''You are my Light, my Lord, my only companion.'' This is an excerpt from a longer dua the Prophet ﷺ would say at night.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'lust-1',
  'lust'::public.dua_category,
  'Asking Allah for chastity and contentment',
  'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
  'Allahumma inni as''aluka-l-huda wa-t-tuqa wa-l-''afafa wa-l-ghina',
  'O Allah, I beg of Thee the right guidance, safeguard against evils, chastity and freedom from want.',
  'Sahih Muslim 2721a',
  ARRAY['lust','chastity','desire','self-control','temptation'],
  'As a daily supplication, especially when struggling with desire or temptation'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'lust-2',
  'lust'::public.dua_category,
  'Yusuf''s prayer for protection from temptation',
  'قَالَ رَبِّ ٱلسِّجْنُ أَحَبُّ إِلَىَّ مِمَّا يَدْعُونَنِىٓ إِلَيْهِ ۖ وَإِلَّا تَصْرِفْ عَنِّى كَيْدَهُنَّ أَصْبُ إِلَيْهِنَّ وَأَكُن مِّنَ ٱلْجَـٰهِلِينَ',
  'Rabbi-s-sijnu ahabbu ilayya mimma yad''unani ilayhi wa-illa tasrif ''anni kaydahunna asbu ilayhinna wa-akun mina-l-jahilin',
  'My Lord! I would rather be in jail than do what they invite me to. And if You do not turn their cunning away from me, I might yield to them and fall into ignorance.',
  'Quran 12:33',
  ARRAY['lust','temptation','chastity','strength','desire'],
  'When facing sexual temptation or pressure to sin against one''s own chastity'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'lust-3',
  'lust'::public.dua_category,
  'Seeking refuge from the evil of one''s own soul',
  'اللَّهُمَّ فَاطِرَ السَّمَوَاتِ وَالأَرْضِ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ رَبَّ كُلِّ شَىْءٍ وَمَلِيكَهُ أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي وَشَرِّ الشَّيْطَانِ وَشِرْكِهِ',
  'Allahumma Fatira-s-samawati wa-l-ardi ''Alima-l-ghaybi wa-sh-shahadati Rabba kulli shay''in wa-malikahu, ash-hadu an la ilaha illa ant, a''udhu bika min sharri nafsi wa-sharri-sh-shaytani wa-shirkihi',
  'O Allah, Creator of the heavens and the earth, Who knowest the unseen and the seen, Lord and Possessor of everything. I testify that there is no god but Thee; I seek refuge in Thee from the evil within myself, from the evil of the devil, and his incitement to attributing partners to Allah.',
  'Sunan Abi Dawud 5067',
  ARRAY['lust','nafs','temptation','self-control','spiritual-protection'],
  'Morning, evening, and before sleep — especially when struggling with desires of the lower self (nafs)'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'marriage_conflict-1',
  'marriage_conflict'::public.dua_category,
  'Asking Allah for a righteous and joyful marriage',
  'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَٰجِنَا وَذُرِّيَّـٰتِنَا قُرَّةَ أَعْيُنٖ وَٱجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
  'Rabbana hab lana min azwajina wa dhurriyyatina qurrata a''yunin waj''alna lil-muttaqina imama',
  'Our Lord! Bless us with ˹pious˺ spouses and offspring who will be the joy of our hearts, and make us models for the righteous.',
  'Quran 25:74',
  ARRAY['marriage conflict','marital tension','family','longing for harmony'],
  'When you are experiencing conflict in your marriage — ask Allah not for the conflict to disappear, but for Him to make your spouse and family the joy of your eyes. This prayer shifts perspective from grievance to aspiration.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'marriage_conflict-2',
  'marriage_conflict'::public.dua_category,
  'Grant us goodness in this life and the next',
  'رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةًۭ وَفِى ٱلْـَٔاخِرَةِ حَسَنَةًۭ وَقِنَا عَذَابَ ٱلنَّارِ',
  'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina ''adhaban-nar',
  'Our Lord! Grant us the good of this world and the Hereafter, and protect us from the torment of the Fire.',
  'Quran 2:201',
  ARRAY['marriage conflict','seeking goodness','overall wellbeing','family peace'],
  'The most comprehensive prayer in the Quran — recite during marital difficulties to ask Allah for what is truly good, including goodness in your marriage and home, while keeping your gaze on what endures beyond this world.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'marriage_conflict-3',
  'marriage_conflict'::public.dua_category,
  'Join our hearts and mend what is between us',
  'اللَّهُمَّ أَلِّفْ بَيْنَ قُلُوبِنَا وَأَصْلِحْ ذَاتَ بَيْنِنَا وَاهْدِنَا سُبُلَ السَّلَامِ وَنَجِّنَا مِنَ الظُّلُمَاتِ إِلَى النُّورِ وَجَنِّبْنَا الْفَوَاحِشَ مَا ظَهَرَ مِنْهَا وَمَا بَطَنَ وَبَارِكْ لَنَا فِي أَسْمَاعِنَا وَأَبْصَارِنَا وَقُلُوبِنَا وَأَزْوَاجِنَا وَذُرِّيَّاتِنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ وَاجْعَلْنَا شَاكِرِينَ لِنِعْمَتِكَ مُثْنِينَ بِهَا قَابِلِيهَا وَأَتِمَّهَا عَلَيْنَا',
  'Allahumma allif bayna qulubina wa aslih dhata baynina, wahdina subula-s-salam, wa najjina mina-dh-dhulumati ila-n-nur, wa jannibna-l-fawahisha ma zahara minha wa ma batan, wa barik lana fi asma''ina wa absarina wa qulubina wa azwajina wa dhurriyyatina, wa tub ''alayna innaka anta-t-Tawwabu-r-Rahim, waj''alna shakirin li-ni''matika muthnina biha qabiliha wa atimmaha ''alayna',
  'O Allah, join our hearts, mend what is between us, guide us to the paths of peace, bring us from darkness to light, keep us away from obscenities, outward and inward, and bless our hearing, our sight, our hearts, our spouses, and our children. Turn toward us, for You are the Accepter of repentance, the Most Merciful. Make us grateful for Your blessing, praising it, accepting it, and complete it upon us.',
  'Sunan Abi Dawud 969',
  ARRAY['marriage conflict','marital tension','seeking Allah''s help with spouse','reconciliation'],
  'During marital tension, family strain, or any conflict where hearts need reconciliation and Allah''s guidance toward peace.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'marriage_conflict-4',
  'marriage_conflict'::public.dua_category,
  'Do not let our hearts deviate from one another',
  'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ ٱلْوَهَّابُ',
  'Rabbana la tuzigh qulubana ba''da idh hadaytana wa hab lana min ladunka rahmah, innaka anta-l-Wahhab',
  'Our Lord! Do not let our hearts deviate after you have guided us. Grant us Your mercy. You are indeed the Giver ˹of all bounties˺.',
  'Quran 3:8',
  ARRAY['marriage conflict','hardened heart','seeking mercy','marital estrangement'],
  'When conflict in your marriage makes hearts feel hardened or distant from each other — ask Allah, the Turner of Hearts, to keep your hearts aligned with His guidance and softened toward your spouse.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'parenting-1',
  'parenting'::public.dua_category,
  'Ibrahim''s prayer for praying children',
  'رَبِّ ٱجْعَلْنِى مُقِيمَ ٱلصَّلَوٰةِ وَمِن ذُرِّيَّتِى ۚ رَبَّنَا وَتَقَبَّلْ دُعَآءِ',
  'Rabbij-''alni muqimas-salati wa min dhurriyyati, Rabbana wa taqabbal du''a''',
  'My Lord! Make me and those ˹believers˺ of my descendants keep up prayer. Our Lord! Accept my prayers.',
  'Quran 14:40',
  ARRAY['parenting','children''s faith','prayer for children','spiritual upbringing'],
  'The prayer of Prophet Ibrahim (AS) — a father who worried about his children''s spiritual future. Recite for your children: ask Allah to establish prayer in their hearts and accept your duas for them.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'parenting-2',
  'parenting'::public.dua_category,
  'Zakariyya''s prayer for righteous children',
  'رَبِّ هَبْ لِى مِن لَّدُنكَ ذُرِّيَّةًۭ طَيِّبَةً ۖ إِنَّكَ سَمِيعُ ٱلدُّعَآءِ',
  'Rabbi hab li min ladunka dhurriyyatan tayyibah, innaka sami''ud-du''a''',
  'My Lord! Grant me—by your grace—righteous offspring. You are certainly the Hearer of ˹all˺ prayers.',
  'Quran 3:38',
  ARRAY['parenting','longing for children','righteous children','hope','prayer for offspring'],
  'The prayer of Prophet Zakariyya (AS) — said when he longed for a child who would be righteous and carry on goodness. Recite when hoping for children, or when praying for a child who has strayed, trusting that Allah hears every prayer.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'parenting-3',
  'parenting'::public.dua_category,
  'A parent''s prayer for righteous children',
  'رَبِّ أَوْزِعْنِىٓ أَنْ أَشْكُرَ نِعْمَتَكَ ٱلَّتِىٓ أَنْعَمْتَ عَلَىَّ وَعَلَىٰ وَٰلِدَىَّ وَأَنْ أَعْمَلَ صَـٰلِحًۭا تَرْضَىٰهُ وَأَصْلِحْ لِى فِى ذُرِّيَّتِىٓ ۖ إِنِّى تُبْتُ إِلَيْكَ وَإِنِّى مِنَ ٱلْمُسْلِمِينَ',
  'Rabbi awzi''ni an ashkura ni''matakallati an''amta ''alayya wa ''ala walidayya wa an a''mala salihan tardahu wa aslih li fi dhurriyyati, inni tubtu ilayka wa inni minal-muslimin',
  'My Lord! Inspire me to ˹always˺ be thankful for Your favours which You blessed me and my parents with, and to do good deeds that please You. And instil righteousness in my offspring. I truly repent to You, and I truly submit ˹to Your Will˺.',
  'Quran 46:15',
  ARRAY['parenting','gratitude','righteous children','spiritual responsibility','family'],
  'Recite at forty — or any time you feel the weight of parenthood. Ask Allah to make you a grateful child and a righteous parent, and to plant goodness in your children''s hearts. ''Aslih li fi dhurriyyati'' — rectify my offspring for me.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'parenting-4',
  'parenting'::public.dua_category,
  'Grant me an heir who will be pleasing to You',
  'فَهَبْ لِى مِن لَّدُنكَ وَلِيًّۭا ۝ يَرِثُنِى وَيَرِثُ مِنْ ءَالِ يَعْقُوبَ ۖ وَٱجْعَلْهُ رَبِّ رَضِيًّۭا',
  'Fa hab li min ladunka waliyya, yarithuni wa yarithu min ali ya''quba, waj''alhu Rabbi radiyya',
  'So grant me, by Your grace, an heir who will inherit ˹prophethood˺ from me and the family of Jacob, and make him, O Lord, pleasing ˹to You˺!',
  'Quran 19:5-6',
  ARRAY['parenting','longing for children','righteous offspring','hope','trust in Allah'],
  'Zakariyya (AS) was old and his wife barren, yet he asked Allah for a child who would be righteous and pleasing to Him — not for his own satisfaction, but for the continuation of goodness. Recite when longing for children or praying that your children grow up beloved to Allah.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'shame-1',
  'shame'::public.dua_category,
  'The Master Supplication for Forgiveness (Sayyid al-Istighfar)',
  'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَىَّ وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ',
  'Allahumma anta Rabbi la ilaha illa ant, khalaqtani wa-ana ''abduk, wa-ana ''ala ''ahdika wa-wa''dika ma-stata''t, a''udhu bika min sharri ma sana''t, abu''u laka bi-ni''matika ''alayya wa-abu''u laka bi-dhanbi fa-ghfir li fa-innahu la yaghfiru-dh-dhunuba illa ant',
  'O Allah, You are my Lord, there is none worthy of worship except You. You have created me, and I am Your servant, and I am faithful to Your covenant and promise as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessings upon me, and I admit my sins. So forgive me, for none forgives sins except You.',
  'Sahih al-Bukhari 6306',
  ARRAY['shame','guilt','repentance','forgiveness','regret'],
  'Morning and evening; after any sin; when feeling shame, regret, or a crushed heart'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'shame-2',
  'shame'::public.dua_category,
  'Adam and Hawwa''s prayer after transgression',
  'قَالَا رَبَّنَا ظَلَمۡنَآ أَنفُسَنَا وَإِن لَّمۡ تَغۡفِرۡ لَنَا وَتَرۡحَمۡنَا لَنَكُونَنَّ مِنَ ٱلۡخَٰسِرِينَ',
  'Rabbana zalamna anfusana wa-in lam taghfir lana wa-tarhamna lanakunanna mina-l-khasirin',
  'Our Lord! We have wronged ourselves. If You do not forgive us and have mercy on us, we will certainly be losers.',
  'Quran 7:23',
  ARRAY['shame','guilt','repentance','forgiveness','self-blame'],
  'After any sin or mistake; when overwhelmed with shame; when seeking Allah''s mercy after wronging oneself'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'shame-3',
  'shame'::public.dua_category,
  'Asking for pardon, forgiveness, and mercy',
  'رَبَّنَا لَا تُؤَاخِذْنَآ إِن نَّسِينَآ أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَآ إِصْرًۭا كَمَا حَمَلْتَهُۥ عَلَى ٱلَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِۦ ۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ',
  'Rabbana la tu''akhidhna in nasina aw akhta''na, rabbana wa-la tahmil ''alayna isran kama hamaltahu ''ala-lladhina min qablina, rabbana wa-la tuhammilna ma la taqata lana bih, wa-''fu ''anna wa-ghfir lana wa-rhamna, anta mawlana fa-nsurna ''ala-l-qawmi-l-kafirin',
  'Our Lord! Do not punish us if we forget or make a mistake. Our Lord! Do not place a burden on us like the one you placed on those before us. Our Lord! Do not burden us with what we cannot bear. Pardon us, forgive us, and have mercy on us. You are our only Guardian. So grant us victory over the disbelieving people.',
  'Quran 2:286',
  ARRAY['shame','guilt','forgiveness','repentance','overwhelm'],
  'When carrying shame or guilt from past mistakes; before sleep; when seeking comprehensive forgiveness'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'shame-4',
  'shame'::public.dua_category,
  'Crying out to the Ever-Living in distress',
  'يَا حَىُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
  'Ya Hayyu Ya Qayyumu bi-rahmatika astaghith',
  'O Ever-Living, O Self-Sustaining Sustainer! In Your Mercy do I seek relief.',
  'Jami'' at-Tirmidhi 3524',
  ARRAY['shame','despair','grief','mercy','distress'],
  'In moments of despair, spiritual heaviness, or shame that feels unbearable'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'work-1',
  'work'::public.dua_category,
  'Musa''s prayer when in desperate need of provision',
  'رَبِّ إِنِّى لِمَآ أَنزَلْتَ إِلَىَّ مِنْ خَيْرٍۢ فَقِيرٌۭ',
  'Rabbi inni lima anzalta ilayya min khayrin faqir',
  'My Lord! I am truly in desperate need of whatever provision You may have in store for me.',
  'Quran 28:24',
  ARRAY['work','provision','rizq','need','tawakkul','poverty','job-seeking'],
  'Recite when job-seeking, between projects, facing financial hardship, or whenever you need provision and have done what you can — then turn to Allah as Musa (AS) did after drawing water for the women.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'work-2',
  'work'::public.dua_category,
  'Make the halal sufficient against the haram',
  'اللَّهُمَّ اكْفِنِي بِحَلاَلِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
  'Allahumma akfini bihalalika ''an haramika, wa aghnini bifadlika ''amman siwak',
  'O Allah, suffice me with Your lawful against Your prohibited, and make me independent of all besides You.',
  'Jami'' at-Tirmidhi 3563',
  ARRAY['work','rizq','halal','financial-pressure','debt','independence','contentment'],
  'Recite morning and evening, especially when facing financial pressure or temptation toward dishonest or haram earnings. The Prophet (peace be upon him) taught this to someone whose debts felt as heavy as a mountain.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'work-3',
  'work'::public.dua_category,
  'O Allah, I ask You for guidance, piety, chastity, and sufficiency',
  'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
  'Allahumma inni as''aluka al-huda wat-tuqa wal-''afafa wal-ghina',
  'O Allah, indeed, I ask You for guidance, piety, chastity, and sufficiency.',
  'Jami'' at-Tirmidhi 3489',
  ARRAY['work','rizq','guidance','taqwa','contentment','dignity','livelihood'],
  'Recite at the start of a workday, before a business meeting, or when seeking dignified livelihood. ''Ghina'' (sufficiency/contentment) and ''afaf'' (chastity/dignity) together cover both the rizq and the ethical dimension of earning.'
) on conflict (id) do nothing;

insert into public.browse_duas (id, category, title, arabic, transliteration, translation, source, emotion_tags, when_to_recite) values (
  'work-4',
  'work'::public.dua_category,
  'My Lord, increase me in knowledge',
  'وَقُل رَّبِّ زِدْنِى عِلْمًۭا',
  'Wa qul rabbi zidni ''ilma',
  'And pray, ''My Lord! Increase me in knowledge.''',
  'Quran 20:114',
  ARRAY['work','knowledge','learning','skill','career','growth'],
  'Recite before studying, learning a new skill, preparing for an exam, or entering any professional endeavour that requires expertise. Knowledge is the foundation of dignified, skilled work.'
) on conflict (id) do nothing;

