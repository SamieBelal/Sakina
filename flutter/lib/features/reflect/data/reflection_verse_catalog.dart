import 'dart:async' show FutureOr, unawaited;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
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
  reference: "Al-A'raf 7:23",
);

const ReflectVerse _believersMercyVerse = ReflectVerse(
  arabic:
      'رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِّلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَّحِيمٌ',
  translation:
      'Our Lord, forgive us and our brothers who preceded us in faith, and put not in our hearts any resentment toward those who have believed. Our Lord, indeed You are Kind and Merciful.',
  reference: 'Al-Hashr 59:10',
);

const ReflectVerse _goodWorldsVerse = ReflectVerse(
  arabic:
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
  translation:
      'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
  reference: 'Al-Baqarah 2:201',
);

const ReflectVerse _acceptanceVerse = ReflectVerse(
  arabic: 'رَبَّنَا تَقَبَّلْ مِنَّا ۖ إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ',
  translation:
      'Our Lord, accept from us. Indeed You are the Hearing, the Knowing.',
  reference: 'Al-Baqarah 2:127',
);

const ReflectVerse _protectionVerse = ReflectVerse(
  arabic:
      'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
  translation:
      'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth.',
  reference: 'Al-Baqarah 2:255',
);

// =====================================================================
// Plan 1: Reflection verse catalog expansion (2026-05-13).
// Added const ReflectVerse declarations covering 83 additional canonical
// Names. Every Arabic + Sahih International translation pair was fetched
// from quran.com (Uthmani text via api.quran.com/api/v4 with translation
// id 20 = Saheeh International). Source provenance lives in
// docs/qa/reflection-verse-sources.md + docs/qa/reflection-verse-batches/.
// Whitelisted source contract: quran.com only.
// =====================================================================

const ReflectVerse _verse51_58 = ReflectVerse(
  arabic: 'إِنَّ ٱللَّهَ هُوَ ٱلرَّزَّاقُ ذُو ٱلْقُوَّةِ ٱلْمَتِينُ',
  translation:
      'Indeed, it is Allāh who is the [continual] Provider, the firm possessor of strength.',
  reference: 'Adh-Dhariyat 51:58',
);

const ReflectVerse _verse87_1 = ReflectVerse(
  arabic: 'سَبِّحِ ٱسْمَ رَبِّكَ ٱلْأَعْلَى',
  translation:
      'Exalt the name of your Lord, the Most High,',
  reference: 'Al-A\'la 87:1',
);

const ReflectVerse _verse7_183 = ReflectVerse(
  arabic: 'وَأُمْلِى لَهُمْ ۚ إِنَّ كَيْدِى مَتِينٌ',
  translation:
      'And I will give them time. Indeed, My plan is firm.',
  reference: 'Al-A\'raf 7:183',
);

const ReflectVerse _verse33_39 = ReflectVerse(
  arabic: 'ٱلَّذِينَ يُبَلِّغُونَ رِسَـٰلَـٰتِ ٱللَّهِ وَيَخْشَوْنَهُۥ وَلَا يَخْشَوْنَ أَحَدًا إِلَّا ٱللَّهَ ۗ وَكَفَىٰ بِٱللَّهِ حَسِيبًۭا',
  translation:
      '[Allāh praises] those who convey the messages of Allāh and fear Him and do not fear anyone but Allāh. And sufficient is Allāh as Accountant.',
  reference: 'Al-Ahzab 33:39',
);

const ReflectVerse _verse33_52 = ReflectVerse(
  arabic: 'لَّا يَحِلُّ لَكَ ٱلنِّسَآءُ مِنۢ بَعْدُ وَلَآ أَن تَبَدَّلَ بِهِنَّ مِنْ أَزْوَٰجٍ وَلَوْ أَعْجَبَكَ حُسْنُهُنَّ إِلَّا مَا مَلَكَتْ يَمِينُكَ ۗ وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ رَّقِيبًا',
  translation:
      'Not lawful to you, [O Muḥammad], are [any additional] women after [this], nor [is it] for you to exchange them for [other] wives, even if their beauty were to please you, except what your right hand possesses. And ever is Allāh, over all things, an Observer.',
  reference: 'Al-Ahzab 33:52',
);

const ReflectVerse _verse6_101 = ReflectVerse(
  arabic: 'بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ وَلَمْ تَكُن لَّهُۥ صَـٰحِبَةٌ ۖ وَخَلَقَ كُلَّ شَىْءٍ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ',
  translation:
      '[He is] Originator of the heavens and the earth. How could He have a son when He does not have a companion [i.e., wife] and He created all things? And He is, of all things, Knowing.',
  reference: 'Al-An\'am 6:101',
);

const ReflectVerse _verse6_114 = ReflectVerse(
  arabic: 'أَفَغَيْرَ ٱللَّهِ أَبْتَغِى حَكَمًۭا وَهُوَ ٱلَّذِىٓ أَنزَلَ إِلَيْكُمُ ٱلْكِتَـٰبَ مُفَصَّلًۭا ۚ وَٱلَّذِينَ ءَاتَيْنَـٰهُمُ ٱلْكِتَـٰبَ يَعْلَمُونَ أَنَّهُۥ مُنَزَّلٌۭ مِّن رَّبِّكَ بِٱلْحَقِّ ۖ فَلَا تَكُونَنَّ مِنَ ٱلْمُمْتَرِينَ',
  translation:
      '[Say], "Then is it other than Allāh I should seek as judge while it is He who has revealed to you the Book [i.e., the Qur\'ān] explained in detail?" And those to whom We [previously] gave the Scripture know that it is sent down from your Lord in truth, so never be among the doubters.',
  reference: 'Al-An\'am 6:114',
);

const ReflectVerse _verse6_17 = ReflectVerse(
  arabic: 'وَإِن يَمْسَسْكَ ٱللَّهُ بِضُرٍّ فَلَا كَاشِفَ لَهُۥٓ إِلَّا هُوَ ۖ وَإِن يَمْسَسْكَ بِخَيْرٍ فَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'And if Allāh should touch you with adversity, there is no remover of it except Him. And if He touches you with good - then He is over all things competent.',
  reference: 'Al-An\'am 6:17',
);

const ReflectVerse _verse2_115 = ReflectVerse(
  arabic: 'وَلِلَّهِ ٱلْمَشْرِقُ وَٱلْمَغْرِبُ ۚ فَأَيْنَمَا تُوَلُّوا۟ فَثَمَّ وَجْهُ ٱللَّهِ ۚ إِنَّ ٱللَّهَ وَٰسِعٌ عَلِيمٌۭ',
  translation:
      'And to Allāh belongs the east and the west. So wherever you [might] turn, there is the Face of Allāh. Indeed, Allāh is all-Encompassing and Knowing.',
  reference: 'Al-Baqarah 2:115',
);

const ReflectVerse _verse2_117 = ReflectVerse(
  arabic: 'بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ وَإِذَا قَضَىٰٓ أَمْرًا فَإِنَّمَا يَقُولُ لَهُۥ كُن فَيَكُونُ',
  translation:
      'Originator of the heavens and the earth. When He decrees a matter, He only says to it, \'Be,\' and it is.',
  reference: 'Al-Baqarah 2:117',
);

const ReflectVerse _verse2_143 = ReflectVerse(
  arabic: 'وَكَذَٰلِكَ جَعَلْنَـٰكُمْ أُمَّةً وَسَطًا لِّتَكُونُوا۟ شُهَدَآءَ عَلَى ٱلنَّاسِ وَيَكُونَ ٱلرَّسُولُ عَلَيْكُمْ شَهِيدًا ۗ وَمَا جَعَلْنَا ٱلْقِبْلَةَ ٱلَّتِى كُنتَ عَلَيْهَآ إِلَّا لِنَعْلَمَ مَن يَتَّبِعُ ٱلرَّسُولَ مِمَّن يَنقَلِبُ عَلَىٰ عَقِبَيْهِ ۚ وَإِن كَانَتْ لَكَبِيرَةً إِلَّا عَلَى ٱلَّذِينَ هَدَى ٱللَّهُ ۗ وَمَا كَانَ ٱللَّهُ لِيُضِيعَ إِيمَـٰنَكُمْ ۚ إِنَّ ٱللَّهَ بِٱلنَّاسِ لَرَءُوفٌ رَّحِيمٌ',
  translation:
      'And thus We have made you a median [i.e., just] community that you will be witnesses over the people and the Messenger will be a witness over you. And We did not make the qiblah which you used to face except that We might make evident who would follow the Messenger from who would turn back on his heels. And indeed, it is difficult except for those whom Allāh has guided. And never would Allāh have caused you to lose your faith [i.e., your previous prayers]. Indeed Allāh is, to the people, Kind and Merciful.',
  reference: 'Al-Baqarah 2:143',
);

const ReflectVerse _verse2_160 = ReflectVerse(
  arabic: 'إِلَّا ٱلَّذِينَ تَابُوا۟ وَأَصْلَحُوا۟ وَبَيَّنُوا۟ فَأُو۟لَـٰٓئِكَ أَتُوبُ عَلَيْهِمْ ۚ وَأَنَا ٱلتَّوَّابُ ٱلرَّحِيمُ',
  translation:
      'Except for those who repent and correct themselves and make evident [what they concealed]. Those - I will accept their repentance, and I am the Accepting of Repentance, the Merciful.',
  reference: 'Al-Baqarah 2:160',
);

const ReflectVerse _verse2_163 = ReflectVerse(
  arabic: 'وَإِلَـٰهُكُمْ إِلَـٰهٌ وَٰحِدٌ ۖ لَّآ إِلَـٰهَ إِلَّا هُوَ ٱلرَّحْمَـٰنُ ٱلرَّحِيمُ',
  translation:
      'And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful.',
  reference: 'Al-Baqarah 2:163',
);

const ReflectVerse _verse2_186 = ReflectVerse(
  arabic: 'وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ ٱلدَّاعِ إِذَا دَعَانِ ۖ فَلْيَسْتَجِيبُوا۟ لِى وَلْيُؤْمِنُوا۟ بِى لَعَلَّهُمْ يَرْشُدُونَ',
  translation:
      'And when My servants ask you, [O Muḥammad], concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. So let them respond to Me [by obedience] and believe in Me that they may be [rightly] guided.',
  reference: 'Al-Baqarah 2:186',
);

const ReflectVerse _verse2_20 = ReflectVerse(
  arabic: 'يَكَادُ ٱلْبَرْقُ يَخْطَفُ أَبْصَـٰرَهُمْ ۖ كُلَّمَآ أَضَآءَ لَهُم مَّشَوْا۟ فِيهِ وَإِذَآ أَظْلَمَ عَلَيْهِمْ قَامُوا۟ ۚ وَلَوْ شَآءَ ٱللَّهُ لَذَهَبَ بِسَمْعِهِمْ وَأَبْصَـٰرِهِمْ ۚ إِنَّ ٱللَّهَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'The lightning almost snatches away their sight. Every time it lights [the way] for them, they walk therein; but when darkness comes over them, they stand [still]. And if Allāh had willed, He could have taken away their hearing and their sight. Indeed, Allāh is over all things competent.',
  reference: 'Al-Baqarah 2:20',
);

const ReflectVerse _verse2_245 = ReflectVerse(
  arabic: 'مَّن ذَا ٱلَّذِى يُقْرِضُ ٱللَّهَ قَرْضًا حَسَنًا فَيُضَـٰعِفَهُۥ لَهُۥٓ أَضْعَافًا كَثِيرَةً ۚ وَٱللَّهُ يَقْبِضُ وَيَبْصُۜطُ وَإِلَيْهِ تُرْجَعُونَ',
  translation:
      'Who is it that would loan Allāh a goodly loan so He may multiply it for him many times over? And it is Allāh who withholds and grants abundance, and to Him you will be returned.',
  reference: 'Al-Baqarah 2:245',
);

const ReflectVerse _verse2_257 = ReflectVerse(
  arabic: 'ٱللَّهُ وَلِىُّ ٱلَّذِينَ ءَامَنُوا۟ يُخْرِجُهُم مِّنَ ٱلظُّلُمَـٰتِ إِلَى ٱلنُّورِ ۖ وَٱلَّذِينَ كَفَرُوٓا۟ أَوْلِيَآؤُهُمُ ٱلطَّـٰغُوتُ يُخْرِجُونَهُم مِّنَ ٱلنُّورِ إِلَى ٱلظُّلُمَـٰتِ ۗ أُو۟لَـٰٓئِكَ أَصْحَـٰبُ ٱلنَّارِ ۖ هُمْ فِيهَا خَـٰلِدُونَ',
  translation:
      'Allāh is the Ally of those who believe. He brings them out from darknesses into the light. And those who disbelieve - their allies are ṭāghūt. They take them out of the light into darknesses. Those are the companions of the Fire; they will abide eternally therein.',
  reference: 'Al-Baqarah 2:257',
);

const ReflectVerse _verse2_268 = ReflectVerse(
  arabic: 'ٱلشَّيْطَـٰنُ يَعِدُكُمُ ٱلْفَقْرَ وَيَأْمُرُكُم بِٱلْفَحْشَآءِ ۖ وَٱللَّهُ يَعِدُكُم مَّغْفِرَةًۭ مِّنْهُ وَفَضْلًۭا ۗ وَٱللَّهُ وَٰسِعٌ عَلِيمٌۭ',
  translation:
      'Satan threatens you with poverty and orders you to immorality, while Allāh promises you forgiveness from Him and bounty. And Allāh is all-Encompassing and Knowing.',
  reference: 'Al-Baqarah 2:268',
);

const ReflectVerse _verse2_32 = ReflectVerse(
  arabic: 'قَالُوا۟ سُبْحَـٰنَكَ لَا عِلْمَ لَنَآ إِلَّا مَا عَلَّمْتَنَآ ۖ إِنَّكَ أَنتَ ٱلْعَلِيمُ ٱلْحَكِيمُ',
  translation:
      'They said, "Exalted are You; we have no knowledge except what You have taught us. Indeed, it is You who is the Knowing, the Wise."',
  reference: 'Al-Baqarah 2:32',
);

const ReflectVerse _verse2_37 = ReflectVerse(
  arabic: 'فَتَلَقَّىٰٓ ءَادَمُ مِن رَّبِّهِۦ كَلِمَـٰتٍ فَتَابَ عَلَيْهِ ۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ',
  translation:
      'Then Adam received from his Lord [some] words, and He accepted his repentance. Indeed, it is He who is the Accepting of Repentance, the Merciful.',
  reference: 'Al-Baqarah 2:37',
);

const ReflectVerse _verse2_54 = ReflectVerse(
  arabic: 'وَإِذْ قَالَ مُوسَىٰ لِقَوْمِهِۦ يَـٰقَوْمِ إِنَّكُمْ ظَلَمْتُمْ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلْعِجْلَ فَتُوبُوٓا۟ إِلَىٰ بَارِئِكُمْ فَٱقْتُلُوٓا۟ أَنفُسَكُمْ ذَٰلِكُمْ خَيْرٌۭ لَّكُمْ عِندَ بَارِئِكُمْ فَتَابَ عَلَيْكُمْ ۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ',
  translation:
      'And [recall] when Moses said to his people, "O my people, indeed you have wronged yourselves by your taking of the calf [for worship]. So repent to your Creator and kill yourselves [i.e., the guilty among you]. That is best for [all of] you in the sight of your Creator." Then He accepted your repentance; indeed, He is the Accepting of Repentance, the Merciful.',
  reference: 'Al-Baqarah 2:54',
);

const ReflectVerse _verse2_56 = ReflectVerse(
  arabic: 'ثُمَّ بَعَثْنَـٰكُم مِّنۢ بَعْدِ مَوْتِكُمْ لَعَلَّكُمْ تَشْكُرُونَ',
  translation:
      'Then We revived you after your death that perhaps you would be grateful.',
  reference: 'Al-Baqarah 2:56',
);

const ReflectVerse _verse85_13 = ReflectVerse(
  arabic: 'إِنَّهُۥ هُوَ يُبْدِئُ وَيُعِيدُ',
  translation:
      'Indeed, it is He who originates [creation] and repeats.',
  reference: 'Al-Buruj 85:13',
);

const ReflectVerse _verse85_14 = ReflectVerse(
  arabic: 'وَهُوَ ٱلْغَفُورُ ٱلْوَدُودُ',
  translation:
      'And He is the Forgiving, the Affectionate,',
  reference: 'Al-Buruj 85:14',
);

const ReflectVerse _verse85_15 = ReflectVerse(
  arabic: 'ذُو ٱلْعَرْشِ ٱلْمَجِيدُ',
  translation:
      'Honorable Owner of the Throne,',
  reference: 'Al-Buruj 85:15',
);

const ReflectVerse _verse85_9 = ReflectVerse(
  arabic: 'ٱلَّذِى لَهُۥ مُلْكُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۚ وَٱللَّهُ عَلَىٰ كُلِّ شَىْءٍۢ شَهِيدٌ',
  translation:
      'To whom belongs the dominion of the heavens and the earth. And Allāh, over all things, is Witness.',
  reference: 'Al-Buruj 85:9',
);

const ReflectVerse _verse25_31 = ReflectVerse(
  arabic: 'وَكَذَٰلِكَ جَعَلْنَا لِكُلِّ نَبِىٍّ عَدُوًّا مِّنَ ٱلْمُجْرِمِينَ ۗ وَكَفَىٰ بِرَبِّكَ هَادِيًا وَنَصِيرًا',
  translation:
      'And thus have We made for every prophet an enemy from among the criminals. But sufficient is your Lord as a guide and a helper.',
  reference: 'Al-Furqan 25:31',
);

const ReflectVerse _verse57_2 = ReflectVerse(
  arabic: 'لَهُۥ مُلْكُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ يُحْىِۦ وَيُمِيتُ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'His is the dominion of the heavens and earth. He gives life and causes death, and He is over all things competent.',
  reference: 'Al-Hadid 57:2',
);

const ReflectVerse _verse57_3 = ReflectVerse(
  arabic: 'هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ',
  translation:
      'He is the First and the Last, the Ascendant and the Intimate, and He is, of all things, Knowing.',
  reference: 'Al-Hadid 57:3',
);

const ReflectVerse _verse22_18 = ReflectVerse(
  arabic: 'أَلَمْ تَرَ أَنَّ ٱللَّهَ يَسْجُدُ لَهُۥ مَن فِى ٱلسَّمَـٰوَٰتِ وَمَن فِى ٱلْأَرْضِ وَٱلشَّمْسُ وَٱلْقَمَرُ وَٱلنُّجُومُ وَٱلْجِبَالُ وَٱلشَّجَرُ وَٱلدَّوَآبُّ وَكَثِيرٌ مِّنَ ٱلنَّاسِ ۖ وَكَثِيرٌ حَقَّ عَلَيْهِ ٱلْعَذَابُ ۗ وَمَن يُهِنِ ٱللَّهُ فَمَا لَهُۥ مِن مُّكْرِمٍ ۚ إِنَّ ٱللَّهَ يَفْعَلُ مَا يَشَآءُ',
  translation:
      'Do you not see [i.e., know] that to Allāh prostrates whoever is in the heavens and whoever is on the earth and the sun, the moon, the stars, the mountains, the trees, the moving creatures and many of the people? But upon many the punishment has been justified. And he whom Allāh humiliates - for him there is no bestower of honor. Indeed, Allāh does what He wills.',
  reference: 'Al-Hajj 22:18',
);

const ReflectVerse _verse22_54 = ReflectVerse(
  arabic: 'وَلِيَعْلَمَ ٱلَّذِينَ أُوتُوا۟ ٱلْعِلْمَ أَنَّهُ ٱلْحَقُّ مِن رَّبِّكَ فَيُؤْمِنُوا۟ بِهِۦ فَتُخْبِتَ لَهُۥ قُلُوبُهُمْ ۗ وَإِنَّ ٱللَّهَ لَهَادِ ٱلَّذِينَ ءَامَنُوٓا۟ إِلَىٰ صِرَٰطٍ مُّسْتَقِيمٍ',
  translation:
      'And so those who were given knowledge may know that it is the truth from your Lord and [therefore] believe in it, and their hearts humbly submit to it. And indeed is Allāh the Guide of those who have believed to a straight path.',
  reference: 'Al-Hajj 22:54',
);

const ReflectVerse _verse22_6 = ReflectVerse(
  arabic: 'ذَٰلِكَ بِأَنَّ ٱللَّهَ هُوَ ٱلْحَقُّ وَأَنَّهُۥ يُحْىِ ٱلْمَوْتَىٰ وَأَنَّهُۥ عَلَىٰ كُلِّ شَىْءٍۢ قَدِيرٌۭ',
  translation:
      'That is because Allāh is the True Reality and because He gives life to the dead and because He is over all things competent.',
  reference: 'Al-Hajj 22:6',
);

const ReflectVerse _verse22_60 = ReflectVerse(
  arabic: '۞ ذَٰلِكَ وَمَنْ عَاقَبَ بِمِثْلِ مَا عُوقِبَ بِهِۦ ثُمَّ بُغِىَ عَلَيْهِ لَيَنصُرَنَّهُ ٱللَّهُ ۗ إِنَّ ٱللَّهَ لَعَفُوٌّ غَفُورٌ',
  translation:
      'That [is so]. And whoever responds [to injustice] with the equivalent of that with which he was harmed and then is tyrannized - Allāh will surely aid him. Indeed, Allāh is Pardoning and Forgiving.',
  reference: 'Al-Hajj 22:60',
);

const ReflectVerse _verse22_62 = ReflectVerse(
  arabic: 'ذَٰلِكَ بِأَنَّ ٱللَّهَ هُوَ ٱلْحَقُّ وَأَنَّ مَا يَدْعُونَ مِن دُونِهِۦ هُوَ ٱلْبَـٰطِلُ وَأَنَّ ٱللَّهَ هُوَ ٱلْعَلِىُّ ٱلْكَبِيرُ',
  translation:
      'That is because Allāh is the True Reality, and that which they call upon other than Him is falsehood, and because Allāh is the Most High, the Grand.',
  reference: 'Al-Hajj 22:62',
);

const ReflectVerse _verse22_69 = ReflectVerse(
  arabic: 'ٱللَّهُ يَحْكُمُ بَيْنَكُمْ يَوْمَ ٱلْقِيَـٰمَةِ فِيمَا كُنتُمْ فِيهِ تَخْتَلِفُونَ',
  translation:
      'Allāh will judge between you on the Day of Resurrection concerning that over which you used to differ.',
  reference: 'Al-Hajj 22:69',
);

const ReflectVerse _verse22_7 = ReflectVerse(
  arabic: 'وَأَنَّ ٱلسَّاعَةَ ءَاتِيَةٌۭ لَّا رَيْبَ فِيهَا وَأَنَّ ٱللَّهَ يَبْعَثُ مَن فِى ٱلْقُبُورِ',
  translation:
      'And [that they may know] that the Hour is coming - no doubt about it - and that Allāh will resurrect those in the graves.',
  reference: 'Al-Hajj 22:7',
);

const ReflectVerse _verse59_23 = ReflectVerse(
  arabic: 'هُوَ ٱللَّهُ ٱلَّذِى لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْمَلِكُ ٱلْقُدُّوسُ ٱلسَّلَـٰمُ ٱلْمُؤْمِنُ ٱلْمُهَيْمِنُ ٱلْعَزِيزُ ٱلْجَبَّارُ ٱلْمُتَكَبِّرُ ۚ سُبْحَـٰنَ ٱللَّهِ عَمَّا يُشْرِكُونَ',
  translation:
      'He is Allāh, other than whom there is no deity, the Sovereign, the Pure, the Perfection, the Grantor of Security, the Overseer, the Exalted in Might, the Compeller, the Superior. Exalted is Allāh above whatever they associate with Him.',
  reference: 'Al-Hashr 59:23',
);

const ReflectVerse _verse59_24 = ReflectVerse(
  arabic: 'هُوَ ٱللَّهُ ٱلْخَـٰلِقُ ٱلْبَارِئُ ٱلْمُصَوِّرُ ۖ لَهُ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ ۚ يُسَبِّحُ لَهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ وَهُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ',
  translation:
      'He is Allāh, the Creator, the Producer, the Fashioner; to Him belong the best names. Whatever is in the heavens and earth is exalting Him. And He is the Exalted in Might, the Wise.',
  reference: 'Al-Hashr 59:24',
);

const ReflectVerse _verse49_13 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلنَّاسُ إِنَّا خَلَقْنَـٰكُم مِّن ذَكَرٍۢ وَأُنثَىٰ وَجَعَلْنَـٰكُمْ شُعُوبًۭا وَقَبَآئِلَ لِتَعَارَفُوٓا۟ ۚ إِنَّ أَكْرَمَكُمْ عِندَ ٱللَّهِ أَتْقَىٰكُمْ ۚ إِنَّ ٱللَّهَ عَلِيمٌ خَبِيرٌۭ',
  translation:
      'O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allāh is the most righteous of you. Indeed, Allāh is Knowing and Aware.',
  reference: 'Al-Hujurat 49:13',
);

const ReflectVerse _verse49_9 = ReflectVerse(
  arabic: 'وَإِن طَآئِفَتَانِ مِنَ ٱلْمُؤْمِنِينَ ٱقْتَتَلُوا۟ فَأَصْلِحُوا۟ بَيْنَهُمَا ۖ فَإِنۢ بَغَتْ إِحْدَىٰهُمَا عَلَى ٱلْأُخْرَىٰ فَقَـٰتِلُوا۟ ٱلَّتِى تَبْغِى حَتَّىٰ تَفِىٓءَ إِلَىٰٓ أَمْرِ ٱللَّهِ ۚ فَإِن فَآءَتْ فَأَصْلِحُوا۟ بَيْنَهُمَا بِٱلْعَدْلِ وَأَقْسِطُوٓا۟ ۖ إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُقْسِطِينَ',
  translation:
      'And if two factions among the believers should fight, then make settlement between the two. But if one of them oppresses the other, then fight against the one that oppresses until it returns to the ordinance of Allāh. And if it returns, then make settlement between them in justice and act justly. Indeed, Allāh loves those who act justly.',
  reference: 'Al-Hujurat 49:9',
);

const ReflectVerse _verse112_1 = ReflectVerse(
  arabic: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
  translation:
      'Say, "He is Allāh, [who is] One,',
  reference: 'Al-Ikhlas 112:1',
);

const ReflectVerse _verse112_1_2 = ReflectVerse(
  arabic: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ ٱللَّهُ ٱلصَّمَدُ',
  translation:
      'Say, "He is Allāh, [who is] One, Allāh, the Eternal Refuge.',
  reference: 'Al-Ikhlas 112:1-2',
);

const ReflectVerse _verse112_2 = ReflectVerse(
  arabic: 'ٱللَّهُ ٱلصَّمَدُ',
  translation:
      'Allāh, the Eternal Refuge.',
  reference: 'Al-Ikhlas 112:2',
);

const ReflectVerse _verse3_156 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ لَا تَكُونُوا۟ كَٱلَّذِينَ كَفَرُوا۟ وَقَالُوا۟ لِإِخْوَٰنِهِمْ إِذَا ضَرَبُوا۟ فِى ٱلْأَرْضِ أَوْ كَانُوا۟ غُزًّى لَّوْ كَانُوا۟ عِندَنَا مَا مَاتُوا۟ وَمَا قُتِلُوا۟ لِيَجْعَلَ ٱللَّهُ ذَٰلِكَ حَسْرَةً فِى قُلُوبِهِمْ ۗ وَٱللَّهُ يُحْىِۦ وَيُمِيتُ ۗ وَٱللَّهُ بِمَا تَعْمَلُونَ بَصِيرٌ',
  translation:
      'O you who have believed, do not be like those who disbelieved and said about their brothers when they traveled through the land or went out to fight, \'If they had been with us, they would not have died or have been killed,\' so Allāh makes that [misconception] a regret within their hearts. And it is Allāh who gives life and causes death, and Allāh is Seeing of what you do.',
  reference: 'Al-Imran 3:156',
);

const ReflectVerse _verse3_173 = ReflectVerse(
  arabic: 'ٱلَّذِينَ قَالَ لَهُمُ ٱلنَّاسُ إِنَّ ٱلنَّاسَ قَدْ جَمَعُوا۟ لَكُمْ فَٱخْشَوْهُمْ فَزَادَهُمْ إِيمَـٰنًۭا وَقَالُوا۟ حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ',
  translation:
      'Those to whom people said, \'Indeed, the people have gathered against you, so fear them.\' But it increased them in faith, and they said, \'Sufficient for us is Allāh, and [He is] the best Disposer of affairs.\'',
  reference: 'Al-Imran 3:173',
);

const ReflectVerse _verse3_2 = ReflectVerse(
  arabic: 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ',
  translation:
      'Allāh - there is no deity except Him, the Ever-Living, the Self-Sustaining.',
  reference: 'Al-Imran 3:2',
);

const ReflectVerse _verse3_26 = ReflectVerse(
  arabic: 'قُلِ ٱللَّهُمَّ مَـٰلِكَ ٱلْمُلْكِ تُؤْتِى ٱلْمُلْكَ مَن تَشَآءُ وَتَنزِعُ ٱلْمُلْكَ مِمَّن تَشَآءُ وَتُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ ۖ بِيَدِكَ ٱلْخَيْرُ ۖ إِنَّكَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'Say, \'O Allāh, Owner of Sovereignty, You give sovereignty to whom You will and You take sovereignty away from whom You will. You honor whom You will and You humble whom You will. In Your hand is [all] good. Indeed, You are over all things competent.\'',
  reference: 'Al-Imran 3:26',
);

const ReflectVerse _verse3_6 = ReflectVerse(
  arabic: 'هُوَ ٱلَّذِى يُصَوِّرُكُمْ فِى ٱلْأَرْحَامِ كَيْفَ يَشَآءُ ۚ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ',
  translation:
      'It is He who forms you in the wombs however He wills. There is no deity except Him, the Exalted in Might, the Wise.',
  reference: 'Al-Imran 3:6',
);

const ReflectVerse _verse3_8 = ReflectVerse(
  arabic: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ ٱلْوَهَّابُ',
  translation:
      '[Who say], "Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower."',
  reference: 'Al-Imran 3:8',
);

const ReflectVerse _verse3_9 = ReflectVerse(
  arabic: 'رَبَّنَآ إِنَّكَ جَامِعُ ٱلنَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ ۚ إِنَّ ٱللَّهَ لَا يُخْلِفُ ٱلْمِيعَادَ',
  translation:
      'Our Lord, surely You will gather the people for a Day about which there is no doubt. Indeed, Allāh does not fail in His promise."',
  reference: 'Al-Imran 3:9',
);

const ReflectVerse _verse82_6 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلْإِنسَـٰنُ مَا غَرَّكَ بِرَبِّكَ ٱلْكَرِيمِ',
  translation:
      'O mankind, what has deceived you concerning your Lord, the Generous,',
  reference: 'Al-Infitar 82:6',
);

const ReflectVerse _verse17_30 = ReflectVerse(
  arabic: 'إِنَّ رَبَّكَ يَبْسُطُ ٱلرِّزْقَ لِمَن يَشَآءُ وَيَقْدِرُ ۚ إِنَّهُۥ كَانَ بِعِبَادِهِۦ خَبِيرًۢا بَصِيرًا',
  translation:
      'Indeed, your Lord extends provision for whom He wills and restricts [it]. Indeed He is ever, concerning His servants, Aware and Seeing.',
  reference: 'Al-Isra 17:30',
);

const ReflectVerse _verse17_70 = ReflectVerse(
  arabic: 'وَلَقَدۡ كَرَّمۡنَا بَنِيٓ ءَادَمَ وَحَمَلۡنَٰهُمۡ فِي ٱلۡبَرِّ وَٱلۡبَحۡرِ وَرَزَقۡنَٰهُم مِّنَ ٱلطَّيِّبَٰتِ وَفَضَّلۡنَٰهُمۡ عَلَىٰ كَثِيرٖ مِّمَّنۡ خَلَقۡنَا تَفۡضِيلٗا',
  translation:
      'And We have certainly honored the children of Adam and carried them on the land and sea and provided for them of the good things and preferred them over much of what We have created, with [definite] preference.',
  reference: 'Al-Isra 17:70',
);

const ReflectVerse _verse17_82 = ReflectVerse(
  arabic: 'وَنُنَزِّلُ مِنَ ٱلْقُرْءَانِ مَا هُوَ شِفَآءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ ۙ وَلَا يَزِيدُ ٱلظَّـٰلِمِينَ إِلَّا خَسَارًا',
  translation:
      'And We send down of the Qur\'ān that which is healing and mercy for the believers, but it does not increase the wrongdoers except in loss.',
  reference: 'Al-Isra 17:82',
);

const ReflectVerse _verse72_28 = ReflectVerse(
  arabic: 'لِّيَعْلَمَ أَن قَدْ أَبْلَغُوا۟ رِسَـٰلَـٰتِ رَبِّهِمْ وَأَحَاطَ بِمَا لَدَيْهِمْ وَأَحْصَىٰ كُلَّ شَىْءٍ عَدَدًۢا',
  translation:
      'That he [i.e., Muḥammad (ﷺ)] may know that they have conveyed the messages of their Lord; and He has encompassed whatever is with them and has enumerated all things in number.',
  reference: 'Al-Jinn 72:28',
);

const ReflectVerse _verse18_10 = ReflectVerse(
  arabic: 'إِذْ أَوَى ٱلْفِتْيَةُ إِلَى ٱلْكَهْفِ فَقَالُوا۟ رَبَّنَآ ءَاتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
  translation:
      '[Mention] when the youths retreated to the cave and said, \'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance.\'',
  reference: 'Al-Kahf 18:10',
);

const ReflectVerse _verse18_17 = ReflectVerse(
  arabic: '۞ وَتَرَى ٱلشَّمْسَ إِذَا طَلَعَت تَّزَٰوَرُ عَن كَهْفِهِمْ ذَاتَ ٱلْيَمِينِ وَإِذَا غَرَبَت تَّقْرِضُهُمْ ذَاتَ ٱلشِّمَالِ وَهُمْ فِى فَجْوَةٍ مِّنْهُ ۚ ذَٰلِكَ مِنْ ءَايَـٰتِ ٱللَّهِ ۗ مَن يَهْدِ ٱللَّهُ فَهُوَ ٱلْمُهْتَدِ ۖ وَمَن يُضْلِلْ فَلَن تَجِدَ لَهُۥ وَلِيًّا مُّرْشِدًا',
  translation:
      'And [had you been present], you would see the sun when it rose, inclining away from their cave on the right, and when it set, passing away from them on the left, while they were [lying] within an open space thereof. That was from the signs of Allāh. He whom Allāh guides is the [rightly] guided, but he whom He sends astray - never will you find for him a protecting guide.',
  reference: 'Al-Kahf 18:17',
);

const ReflectVerse _verse58_11 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا قِيلَ لَكُمْ تَفَسَّحُوا۟ فِى ٱلْمَجَـٰلِسِ فَٱفْسَحُوا۟ يَفْسَحِ ٱللَّهُ لَكُمْ ۖ وَإِذَا قِيلَ ٱنشُزُوا۟ فَٱنشُزُوا۟ يَرْفَعِ ٱللَّهُ ٱلَّذِينَ ءَامَنُوا۟ مِنكُمْ وَٱلَّذِينَ أُوتُوا۟ ٱلْعِلْمَ دَرَجَـٰتٍ ۚ وَٱللَّهُ بِمَا تَعْمَلُونَ خَبِيرٌ',
  translation:
      'O you who have believed, when you are told, \'Space yourselves\' in assemblies, then make space; Allāh will make space for you. And when you are told, \'Arise,\' then arise; Allāh will raise those who have believed among you and those who were given knowledge, by degrees. And Allāh is Aware of what you do.',
  reference: 'Al-Mujadila 58:11',
);

const ReflectVerse _verse67_1 = ReflectVerse(
  arabic: 'تَبَـٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'Blessed is He in whose hand is dominion, and He is over all things competent -',
  reference: 'Al-Mulk 67:1',
);

const ReflectVerse _verse67_13 = ReflectVerse(
  arabic: 'وَأَسِرُّوا۟ قَوْلَكُمْ أَوِ ٱجْهَرُوا۟ بِهِۦٓ ۖ إِنَّهُۥ عَلِيمٌۢ بِذَاتِ ٱلصُّدُورِ',
  translation:
      'And conceal your speech or publicize it; indeed, He is Knowing of that within the breasts.',
  reference: 'Al-Mulk 67:13',
);

const ReflectVerse _verse67_14 = ReflectVerse(
  arabic: 'أَلَا يَعْلَمُ مَنْ خَلَقَ وَهُوَ ٱللَّطِيفُ ٱلْخَبِيرُ',
  translation:
      'Does He who created not know, while He is the Subtle, the Aware?',
  reference: 'Al-Mulk 67:14',
);

const ReflectVerse _verse67_19 = ReflectVerse(
  arabic: 'أَوَلَمْ يَرَوْا۟ إِلَى ٱلطَّيْرِ فَوْقَهُمْ صَـٰٓفَّـٰتٍ وَيَقْبِضْنَ ۚ مَا يُمْسِكُهُنَّ إِلَّا ٱلرَّحْمَـٰنُ ۚ إِنَّهُۥ بِكُلِّ شَىْءٍۭ بَصِيرٌ',
  translation:
      'Do they not see the birds above them with wings outspread and [sometimes] folded in? None holds them [aloft] except the Most Merciful. Indeed He is, of all things, Seeing.',
  reference: 'Al-Mulk 67:19',
);

const ReflectVerse _verse67_21 = ReflectVerse(
  arabic: 'أَمَّنْ هَـٰذَا ٱلَّذِى يَرْزُقُكُمْ إِنْ أَمْسَكَ رِزْقَهُۥ ۚ بَل لَّجُّوا۟ فِى عُتُوٍّ وَنُفُورٍ',
  translation:
      'Or who is it that could provide for you if He withheld His provision? But they have persisted in insolence and aversion.',
  reference: 'Al-Mulk 67:21',
);

const ReflectVerse _verse60_8 = ReflectVerse(
  arabic: 'لَّا يَنْهَىٰكُمُ ٱللَّهُ عَنِ ٱلَّذِينَ لَمْ يُقَـٰتِلُوكُمْ فِى ٱلدِّينِ وَلَمْ يُخْرِجُوكُم مِّن دِيَـٰرِكُمْ أَن تَبَرُّوهُمْ وَتُقْسِطُوٓا۟ إِلَيْهِمْ ۚ إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُقْسِطِينَ',
  translation:
      'Allāh does not forbid you from those who do not fight you because of religion and do not expel you from your homes - from being righteous toward them and acting justly toward them. Indeed, Allāh loves those who act justly.',
  reference: 'Al-Mumtahanah 60:8',
);

const ReflectVerse _verse73_9 = ReflectVerse(
  arabic: 'رَّبُّ ٱلْمَشْرِقِ وَٱلْمَغْرِبِ لَآ إِلَـٰهَ إِلَّا هُوَ فَٱتَّخِذْهُ وَكِيلًۭا',
  translation:
      '[He is] the Lord of the East and the West; there is no deity except Him, so take Him as Disposer of [your] affairs.',
  reference: 'Al-Muzzammil 73:9',
);

const ReflectVerse _verse54_42 = ReflectVerse(
  arabic: 'كَذَّبُوا۟ بِـَٔايَـٰتِنَا كُلِّهَا فَأَخَذْنَـٰهُمْ أَخْذَ عَزِيزٍ مُّقْتَدِرٍ',
  translation:
      'They denied Our signs, all of them, so We seized them with a seizure of one Exalted in Might and Perfect in Ability.',
  reference: 'Al-Qamar 54:42',
);

const ReflectVerse _verse54_55 = ReflectVerse(
  arabic: 'فِى مَقْعَدِ صِدْقٍ عِندَ مَلِيكٍ مُّقْتَدِرٍۭ',
  translation:
      'In a seat of honor near a Sovereign, Perfect in Ability.',
  reference: 'Al-Qamar 54:55',
);

const ReflectVerse _verse28_88 = ReflectVerse(
  arabic: 'وَلَا تَدْعُ مَعَ ٱللَّهِ إِلَـٰهًا ءَاخَرَ ۘ لَآ إِلَـٰهَ إِلَّا هُوَ ۚ كُلُّ شَىْءٍ هَالِكٌ إِلَّا وَجْهَهُۥ ۚ لَهُ ٱلْحُكْمُ وَإِلَيْهِ تُرْجَعُونَ',
  translation:
      'And do not invoke with Allāh another deity. There is no deity except Him. Everything will be destroyed except His Face. His is the judgement, and to Him you will be returned.',
  reference: 'Al-Qasas 28:88',
);

const ReflectVerse _verse56_10 = ReflectVerse(
  arabic: 'وَٱلسَّـٰبِقُونَ ٱلسَّـٰبِقُونَ',
  translation:
      'And the forerunners, the forerunners',
  reference: 'Al-Waqi\'ah 56:10',
);

const ReflectVerse _verse56_3 = ReflectVerse(
  arabic: 'خَافِضَةٌ رَّافِعَةٌ',
  translation:
      'It will bring down [some] and raise up [others].',
  reference: 'Al-Waqi\'ah 56:3',
);

const ReflectVerse _verse56_96 = ReflectVerse(
  arabic: 'فَسَبِّحْ بِٱسْمِ رَبِّكَ ٱلْعَظِيمِ',
  translation:
      'So exalt the name of your Lord, the Most Great.',
  reference: 'Al-Waqi\'ah 56:96',
);

const ReflectVerse _verse16_61 = ReflectVerse(
  arabic: 'وَلَوْ يُؤَاخِذُ ٱللَّهُ ٱلنَّاسَ بِظُلْمِهِم مَّا تَرَكَ عَلَيْهَا مِن دَآبَّةٍۢ وَلَـٰكِن يُؤَخِّرُهُمْ إِلَىٰٓ أَجَلٍۢ مُّسَمًّۭى ۖ فَإِذَا جَآءَ أَجَلُهُمْ لَا يَسْتَـْٔخِرُونَ سَاعَةًۭ ۖ وَلَا يَسْتَقْدِمُونَ',
  translation:
      'And if Allāh were to impose blame on the people for their wrongdoing, He would not have left upon it any creature, but He defers them for a specified term.',
  reference: 'An-Nahl 16:61',
);

const ReflectVerse _verse16_90 = ReflectVerse(
  arabic: 'إِنَّ ٱللَّهَ يَأْمُرُ بِٱلْعَدْلِ وَٱلْإِحْسَـٰنِ وَإِيتَآئِ ذِى ٱلْقُرْبَىٰ وَيَنْهَىٰ عَنِ ٱلْفَحْشَآءِ وَٱلْمُنكَرِ وَٱلْبَغْىِ ۚ يَعِظُكُمْ لَعَلَّكُمْ تَذَكَّرُونَ',
  translation:
      'Indeed, Allāh orders justice and good conduct and giving [help] to relatives and forbids immorality and bad conduct and oppression. He admonishes you that perhaps you will be reminded.',
  reference: 'An-Nahl 16:90',
);

const ReflectVerse _verse53_44 = ReflectVerse(
  arabic: 'وَأَنَّهُۥ هُوَ أَمَاتَ وَأَحْيَا',
  translation:
      'And that it is He who causes death and gives life',
  reference: 'An-Najm 53:44',
);

const ReflectVerse _verse53_48 = ReflectVerse(
  arabic: 'وَأَنَّهُۥ هُوَ أَغْنَىٰ وَأَقْنَىٰ',
  translation:
      'And that it is He who enriches and suffices',
  reference: 'An-Najm 53:48',
);

const ReflectVerse _verse27_40 = ReflectVerse(
  arabic: 'قَالَ ٱلَّذِى عِندَهُۥ عِلْمٌ مِّنَ ٱلْكِتَـٰبِ أَنَا۠ ءَاتِيكَ بِهِۦ قَبْلَ أَن يَرْتَدَّ إِلَيْكَ طَرْفُكَ ۚ فَلَمَّا رَءَاهُ مُسْتَقِرًّا عِندَهُۥ قَالَ هَـٰذَا مِن فَضْلِ رَبِّى لِيَبْلُوَنِىٓ ءَأَشْكُرُ أَمْ أَكْفُرُ ۖ وَمَن شَكَرَ فَإِنَّمَا يَشْكُرُ لِنَفْسِهِۦ ۖ وَمَن كَفَرَ فَإِنَّ رَبِّى غَنِىٌّ كَرِيمٌ',
  translation:
      'Said one who had knowledge from the Scripture, \'I will bring it to you before your glance returns to you.\' And when [Solomon] saw it placed before him, he said, \'This is from the favor of my Lord to test me whether I will be grateful or ungrateful. And whoever is grateful - his gratitude is only for [the benefit of] himself. And whoever is ungrateful - then indeed, my Lord is Free of need and Generous.\'',
  reference: 'An-Naml 27:40',
);

const ReflectVerse _verse4_1 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُوا۟ رَبَّكُمُ ٱلَّذِى خَلَقَكُم مِّن نَّفْسٍ وَٰحِدَةٍ وَخَلَقَ مِنْهَا زَوْجَهَا وَبَثَّ مِنْهُمَا رِجَالًا كَثِيرًا وَنِسَآءً ۚ وَٱتَّقُوا۟ ٱللَّهَ ٱلَّذِى تَسَآءَلُونَ بِهِۦ وَٱلْأَرْحَامَ ۚ إِنَّ ٱللَّهَ كَانَ عَلَيْكُمْ رَقِيبًا',
  translation:
      'O mankind, fear your Lord, who created you from one soul and created from it its mate and dispersed from both of them many men and women. And fear Allāh, through whom you ask one another, and the wombs. Indeed Allāh is ever, over you, an Observer.',
  reference: 'An-Nisa 4:1',
);

const ReflectVerse _verse4_140 = ReflectVerse(
  arabic: 'وَقَدْ نَزَّلَ عَلَيْكُمْ فِى ٱلْكِتَـٰبِ أَنْ إِذَا سَمِعْتُمْ ءَايَـٰتِ ٱللَّهِ يُكْفَرُ بِهَا وَيُسْتَهْزَأُ بِهَا فَلَا تَقْعُدُوا۟ مَعَهُمْ حَتَّىٰ يَخُوضُوا۟ فِى حَدِيثٍ غَيْرِهِۦٓ ۚ إِنَّكُمْ إِذًا مِّثْلُهُمْ ۗ إِنَّ ٱللَّهَ جَامِعُ ٱلْمُنَـٰفِقِينَ وَٱلْكَـٰفِرِينَ فِى جَهَنَّمَ جَمِيعًا',
  translation:
      'And it has already come down to you in the Book [i.e., the Qur\'ān] that when you hear the verses of Allāh [recited], they are denied [by them] and ridiculed; so do not sit with them until they enter into another conversation. Indeed, you would then be like them. Indeed, Allāh will gather the hypocrites and disbelievers in Hell all together -',
  reference: 'An-Nisa 4:140',
);

const ReflectVerse _verse4_166 = ReflectVerse(
  arabic: 'لَّـٰكِنِ ٱللَّهُ يَشْهَدُ بِمَآ أَنزَلَ إِلَيْكَ ۖ أَنزَلَهُۥ بِعِلْمِهِۦ ۖ وَٱلْمَلَـٰٓئِكَةُ يَشْهَدُونَ ۚ وَكَفَىٰ بِٱللَّهِ شَهِيدًا',
  translation:
      'But Allāh bears witness to that which He has revealed to you. He has sent it down with His knowledge, and the angels bear witness [as well]. And sufficient is Allāh as Witness.',
  reference: 'An-Nisa 4:166',
);

const ReflectVerse _verse4_43 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ لَا تَقْرَبُوا۟ ٱلصَّلَوٰةَ وَأَنتُمْ سُكَـٰرَىٰ حَتَّىٰ تَعْلَمُوا۟ مَا تَقُولُونَ وَلَا جُنُبًا إِلَّا عَابِرِى سَبِيلٍ حَتَّىٰ تَغْتَسِلُوا۟ ۚ وَإِن كُنتُم مَّرْضَىٰٓ أَوْ عَلَىٰ سَفَرٍ أَوْ جَآءَ أَحَدٌ مِّنكُم مِّنَ ٱلْغَآئِطِ أَوْ لَـٰمَسْتُمُ ٱلنِّسَآءَ فَلَمْ تَجِدُوا۟ مَآءً فَتَيَمَّمُوا۟ صَعِيدًا طَيِّبًا فَٱمْسَحُوا۟ بِوُجُوهِكُمْ وَأَيْدِيكُمْ ۗ إِنَّ ٱللَّهَ كَانَ عَفُوًّا غَفُورًا',
  translation:
      'O you who have believed, do not approach prayer while you are intoxicated until you know what you are saying or in a state of janābah, except those passing through [a place of prayer], until you have washed [your whole body]. And if you are ill or on a journey or one of you comes from the place of relieving himself or you have contacted women [i.e., had sexual intercourse] and find no water, then seek clean earth and wipe over your faces and your hands [with it]. Indeed, Allāh is ever Pardoning and Forgiving.',
  reference: 'An-Nisa 4:43',
);

const ReflectVerse _verse4_58 = ReflectVerse(
  arabic: 'إِنَّ ٱللَّهَ يَأْمُرُكُمْ أَن تُؤَدُّوا۟ ٱلْأَمَـٰنَـٰتِ إِلَىٰٓ أَهْلِهَا وَإِذَا حَكَمْتُم بَيْنَ ٱلنَّاسِ أَن تَحْكُمُوا۟ بِٱلْعَدْلِ ۚ إِنَّ ٱللَّهَ نِعِمَّا يَعِظُكُم بِهِۦٓ ۗ إِنَّ ٱللَّهَ كَانَ سَمِيعًۢا بَصِيرًۭا',
  translation:
      'Indeed, Allāh commands you to render trusts to whom they are due and when you judge between people to judge with justice. Excellent is that which Allāh instructs you. Indeed, Allāh is ever Hearing and Seeing.',
  reference: 'An-Nisa 4:58',
);

// Al-Wajid (The Finder) root w-j-d attestation — `لَوَجَدُوا۟ ٱللَّهَ`.
const ReflectVerse _verse4_64 = ReflectVerse(
  arabic: 'وَمَآ أَرْسَلْنَا مِن رَّسُولٍ إِلَّا لِيُطَاعَ بِإِذْنِ ٱللَّهِ ۚ وَلَوْ أَنَّهُمْ إِذ ظَّلَمُوٓا۟ أَنفُسَهُمْ جَآءُوكَ فَٱسْتَغْفَرُوا۟ ٱللَّهَ وَٱسْتَغْفَرَ لَهُمُ ٱلرَّسُولُ لَوَجَدُوا۟ ٱللَّهَ تَوَّابًا رَّحِيمًا',
  translation:
      'And We did not send any messenger except to be obeyed by permission of Allāh. And if, when they wronged themselves, they had come to you, [O Muḥammad], and asked forgiveness of Allāh and the Messenger had asked forgiveness for them, they would have found Allāh Accepting of Repentance and Merciful.',
  reference: 'An-Nisa 4:64',
);

const ReflectVerse _verse4_6 = ReflectVerse(
  arabic: 'وَٱبْتَلُوا۟ ٱلْيَتَـٰمَىٰ حَتَّىٰٓ إِذَا بَلَغُوا۟ ٱلنِّكَاحَ فَإِنْ ءَانَسْتُم مِّنْهُمْ رُشْدًۭا فَٱدْفَعُوٓا۟ إِلَيْهِمْ أَمْوَٰلَهُمْ ۖ وَلَا تَأْكُلُوهَآ إِسْرَافًۭا وَبِدَارًا أَن يَكْبَرُوا۟ ۚ وَمَن كَانَ غَنِيًّۭا فَلْيَسْتَعْفِفْ ۖ وَمَن كَانَ فَقِيرًۭا فَلْيَأْكُلْ بِٱلْمَعْرُوفِ ۚ فَإِذَا دَفَعْتُمْ إِلَيْهِمْ أَمْوَٰلَهُمْ فَأَشْهِدُوا۟ عَلَيْهِمْ ۚ وَكَفَىٰ بِٱللَّهِ حَسِيبًۭا',
  translation:
      'And test the orphans [in their abilities] until they reach marriageable age. Then if you perceive in them sound judgement, release their property to them. And do not consume it excessively and quickly, [anticipating] that they will grow up. And whoever, [when acting as guardian], is self-sufficient should refrain [from taking a fee]; and whoever is poor - let him take according to what is acceptable. Then when you release their property to them, bring witnesses upon them. And sufficient is Allāh as Accountant.',
  reference: 'An-Nisa 4:6',
);

const ReflectVerse _verse4_85 = ReflectVerse(
  arabic: 'مَّن يَشْفَعْ شَفَـٰعَةً حَسَنَةًۭ يَكُن لَّهُۥ نَصِيبٌۭ مِّنْهَا ۖ وَمَن يَشْفَعْ شَفَـٰعَةًۭ سَيِّئَةًۭ يَكُن لَّهُۥ كِفْلٌۭ مِّنْهَا ۗ وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍۢ مُّقِيتًۭا',
  translation:
      'Whoever intercedes for a good cause will have a share [i.e., reward] therefrom; and whoever intercedes for an evil cause will have a portion [i.e., burden] therefrom. And ever is Allāh, over all things, a Keeper.',
  reference: 'An-Nisa 4:85',
);

const ReflectVerse _verse24_25 = ReflectVerse(
  arabic: 'يَوْمَئِذٍۢ يُوَفِّيهِمُ ٱللَّهُ دِينَهُمُ ٱلْحَقَّ وَيَعْلَمُونَ أَنَّ ٱللَّهَ هُوَ ٱلْحَقُّ ٱلْمُبِينُ',
  translation:
      'That Day, Allāh will pay them in full their true [i.e., deserved] recompense, and they will know that it is Allāh who is the manifest Truth [i.e., perfect in justice].',
  reference: 'An-Nur 24:25',
);

const ReflectVerse _verse24_35 = ReflectVerse(
  arabic: 'ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۚ مَثَلُ نُورِهِۦ كَمِشْكَوٰةٍۢ فِيهَا مِصْبَاحٌ ۖ ٱلْمِصْبَاحُ فِى زُجَاجَةٍ ۖ ٱلزُّجَاجَةُ كَأَنَّهَا كَوْكَبٌۭ دُرِّىٌّۭ يُوقَدُ مِن شَجَرَةٍۢ مُّبَـٰرَكَةٍۢ زَيْتُونَةٍۢ لَّا شَرْقِيَّةٍۢ وَلَا غَرْبِيَّةٍۢ يَكَادُ زَيْتُهَا يُضِىٓءُ وَلَوْ لَمْ تَمْسَسْهُ نَارٌۭ ۚ نُّورٌ عَلَىٰ نُورٍۢ ۗ يَهْدِى ٱللَّهُ لِنُورِهِۦ مَن يَشَآءُ ۚ وَيَضْرِبُ ٱللَّهُ ٱلْأَمْثَـٰلَ لِلنَّاسِ ۗ وَٱللَّهُ بِكُلِّ شَىْءٍ عَلِيمٌۭ',
  translation:
      'Allāh is the Light of the heavens and the earth. The example of His light is like a niche within which is a lamp; the lamp is within glass, the glass as if it were a pearly [white] star lit from [the oil of] a blessed olive tree, neither of the east nor of the west, whose oil would almost glow even if untouched by fire. Light upon light. Allāh guides to His light whom He wills. And Allāh presents examples for the people, and Allāh is Knowing of all things.',
  reference: 'An-Nur 24:35',
);

const ReflectVerse _verse13_16 = ReflectVerse(
  arabic: 'قُلْ مَن رَّبُّ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ قُلِ ٱللَّهُ ۚ قُلْ أَفَٱتَّخَذْتُم مِّن دُونِهِۦٓ أَوْلِيَآءَ لَا يَمْلِكُونَ لِأَنفُسِهِمْ نَفْعًا وَلَا ضَرًّا ۚ قُلْ هَلْ يَسْتَوِى ٱلْأَعْمَىٰ وَٱلْبَصِيرُ أَمْ هَلْ تَسْتَوِى ٱلظُّلُمَـٰتُ وَٱلنُّورُ ۗ أَمْ جَعَلُوا۟ لِلَّهِ شُرَكَآءَ خَلَقُوا۟ كَخَلْقِهِۦ فَتَشَـٰبَهَ ٱلْخَلْقُ عَلَيْهِمْ ۚ قُلِ ٱللَّهُ خَـٰلِقُ كُلِّ شَىْءٍ وَهُوَ ٱلْوَٰحِدُ ٱلْقَهَّـٰرُ',
  translation:
      'Say, "Who is Lord of the heavens and earth?" Say, "Allāh." Say, "Have you then taken besides Him allies not possessing [even] for themselves any benefit or any harm?" Say, "Is the blind equivalent to the seeing? Or is darkness equivalent to light? Or have they attributed to Allāh partners who created like His creation so that the creation [of each] seemed similar to them?" Say, "Allāh is the Creator of all things, and He is the One, the Prevailing."',
  reference: 'Ar-Ra\'d 13:16',
);

const ReflectVerse _verse13_9 = ReflectVerse(
  arabic: 'عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ ٱلْكَبِيرُ ٱلْمُتَعَالِ',
  translation:
      '[He is] Knower of the unseen and the witnessed, the Grand, the Exalted.',
  reference: 'Ar-Ra\'d 13:9',
);

const ReflectVerse _verse55_26_27 = ReflectVerse(
  arabic: 'كُلُّ مَنْ عَلَيْهَا فَانٍ ۝ وَيَبْقَىٰ وَجْهُ رَبِّكَ ذُو ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ',
  translation:
      'Everyone upon it [i.e., the earth] will perish, And there will remain the Face of your Lord, Owner of Majesty and Honor.',
  reference: 'Ar-Rahman 55:26-27',
);

const ReflectVerse _verse55_27 = ReflectVerse(
  arabic: 'وَيَبْقَىٰ وَجْهُ رَبِّكَ ذُو ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ',
  translation:
      'And there will remain the Face of your Lord, Owner of Majesty and Honor.',
  reference: 'Ar-Rahman 55:27',
);

const ReflectVerse _verse55_78 = ReflectVerse(
  arabic: 'تَبَـٰرَكَ ٱسْمُ رَبِّكَ ذِى ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ',
  translation:
      'Blessed is the name of your Lord, Owner of Majesty and Honor.',
  reference: 'Ar-Rahman 55:78',
);

const ReflectVerse _verse30_11 = ReflectVerse(
  arabic: 'ٱللَّهُ يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ ثُمَّ إِلَيْهِ تُرْجَعُونَ',
  translation:
      'Allāh begins creation; then He will repeat it; then to Him you will be returned.',
  reference: 'Ar-Rum 30:11',
);

const ReflectVerse _verse30_27 = ReflectVerse(
  arabic: 'وَهُوَ ٱلَّذِى يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ وَهُوَ أَهْوَنُ عَلَيْهِ ۚ وَلَهُ ٱلْمَثَلُ ٱلْأَعْلَىٰ فِى ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۚ وَهُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ',
  translation:
      'And it is He who begins creation; then He repeats it, and that is [even] easier for Him. To Him belongs the highest description [i.e., attribute] in the heavens and earth. And He is the Exalted in Might, the Wise.',
  reference: 'Ar-Rum 30:27',
);

const ReflectVerse _verse30_50 = ReflectVerse(
  arabic: 'فَٱنظُرْ إِلَىٰٓ ءَاثَـٰرِ رَحْمَتِ ٱللَّهِ كَيْفَ يُحْىِ ٱلْأَرْضَ بَعْدَ مَوْتِهَآ ۚ إِنَّ ذَٰلِكَ لَمُحْىِ ٱلْمَوْتَىٰ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'So observe the effects of the mercy of Allāh - how He gives life to the earth after its lifelessness. Indeed, that [same one] will give life to the dead, and He is over all things competent.',
  reference: 'Ar-Rum 30:50',
);

const ReflectVerse _verse26_80 = ReflectVerse(
  arabic: 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ',
  translation:
      'And when I am ill, it is He who cures me',
  reference: 'Ash-Shu\'ara 26:80',
);

const ReflectVerse _verse42_12 = ReflectVerse(
  arabic: 'لَهُۥ مَقَالِيدُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ يَبْسُطُ ٱلرِّزْقَ لِمَن يَشَآءُ وَيَقْدِرُ ۚ إِنَّهُۥ بِكُلِّ شَىْءٍ عَلِيمٌ',
  translation:
      'To Him belong the keys of the heavens and the earth. He extends provision for whom He wills and restricts [it]. Indeed He is, of all things, Knowing.',
  reference: 'Ash-Shura 42:12',
);

const ReflectVerse _verse42_19 = ReflectVerse(
  arabic: 'ٱللَّهُ لَطِيفٌۢ بِعِبَادِهِۦ يَرْزُقُ مَن يَشَآءُ ۖ وَهُوَ ٱلْقَوِىُّ ٱلْعَزِيزُ',
  translation:
      'Allāh is Subtle with His servants; He gives provision to whom He wills. And He is the Powerful, the Exalted in Might.',
  reference: 'Ash-Shura 42:19',
);

const ReflectVerse _verse42_28 = ReflectVerse(
  arabic: 'وَهُوَ ٱلَّذِى يُنَزِّلُ ٱلْغَيْثَ مِنۢ بَعْدِ مَا قَنَطُوا۟ وَيَنشُرُ رَحْمَتَهُۥ ۚ وَهُوَ ٱلْوَلِىُّ ٱلْحَمِيدُ',
  translation:
      'And it is He who sends down the rain after they had despaired and spreads His mercy. And He is the Protector, the Praiseworthy.',
  reference: 'Ash-Shura 42:28',
);

const ReflectVerse _verse42_4 = ReflectVerse(
  arabic: 'لَهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۖ وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ',
  translation:
      'To Him belongs whatever is in the heavens and whatever is in the earth, and He is the Most High, the Most Great.',
  reference: 'Ash-Shura 42:4',
);

const ReflectVerse _verse42_9 = ReflectVerse(
  arabic: 'أَمِ ٱتَّخَذُوا۟ مِن دُونِهِۦٓ أَوْلِيَآءَ ۖ فَٱللَّهُ هُوَ ٱلْوَلِىُّ وَهُوَ يُحْىِ ٱلْمَوْتَىٰ وَهُوَ عَلَىٰ كُلِّ شَىْءٍۢ قَدِيرٌۭ',
  translation:
      'Or have they taken protectors [or allies] besides Him? But Allāh - He is the Protector, and He gives life to the dead, and He is over all things competent.',
  reference: 'Ash-Shura 42:9',
);

const ReflectVerse _verse65_11 = ReflectVerse(
  arabic: 'رَّسُولًۭا يَتْلُوا۟ عَلَيْكُمْ ءَايَـٰتِ ٱللَّهِ مُبَيِّنَـٰتٍۢ لِّيُخْرِجَ ٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ مِنَ ٱلظُّلُمَـٰتِ إِلَى ٱلنُّورِ ۚ وَمَن يُؤْمِنۢ بِٱللَّهِ وَيَعْمَلْ صَـٰلِحًۭا يُدْخِلْهُ جَنَّـٰتٍۢ تَجْرِى مِن تَحْتِهَا ٱلْأَنْهَـٰرُ خَـٰلِدِينَ فِيهَآ أَبَدًۭا ۖ قَدْ أَحْسَنَ ٱللَّهُ لَهُۥ رِزْقًا',
  translation:
      '[He sent] a Messenger [i.e., Muḥammad (ﷺ)] reciting to you the distinct verses of Allāh that He may bring out those who believe and do righteous deeds from darknesses into the light. And whoever believes in Allāh and does righteousness - He will admit him into gardens beneath which rivers flow to abide therein forever. Allāh will have perfected for him a provision.',
  reference: 'At-Talaq 65:11',
);

const ReflectVerse _verse9_117 = ReflectVerse(
  arabic: 'لَّقَد تَّابَ ٱللَّهُ عَلَى ٱلنَّبِىِّ وَٱلْمُهَـٰجِرِينَ وَٱلْأَنصَارِ ٱلَّذِينَ ٱتَّبَعُوهُ فِى سَاعَةِ ٱلْعُسْرَةِ مِنۢ بَعْدِ مَا كَادَ يَزِيغُ قُلُوبُ فَرِيقٍ مِّنْهُمْ ثُمَّ تَابَ عَلَيْهِمْ ۚ إِنَّهُۥ بِهِمْ رَءُوفٌ رَّحِيمٌ',
  translation:
      'Allāh has already forgiven the Prophet and the Muhājireen and the Anṣār who followed him in the hour of difficulty after the hearts of a party of them had almost inclined [to doubt], and then He forgave them. Indeed, He was to them Kind and Merciful.',
  reference: 'At-Tawbah 9:117',
);

const ReflectVerse _verse9_28 = ReflectVerse(
  arabic: 'يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِنَّمَا ٱلْمُشْرِكُونَ نَجَسٌ فَلَا يَقْرَبُوا۟ ٱلْمَسْجِدَ ٱلْحَرَامَ بَعْدَ عَامِهِمْ هَـٰذَا ۚ وَإِنْ خِفْتُمْ عَيْلَةً فَسَوْفَ يُغْنِيكُمُ ٱللَّهُ مِن فَضْلِهِۦٓ إِن شَآءَ ۚ إِنَّ ٱللَّهَ عَلِيمٌ حَكِيمٌ',
  translation:
      'O you who have believed, indeed the polytheists are unclean, so let them not approach al-Masjid al-Ḥarām after this, their [final] year. And if you fear privation, Allāh will enrich you from His bounty if He wills. Indeed, Allāh is Knowing and Wise.',
  reference: 'At-Tawbah 9:28',
);

const ReflectVerse _verse95_5 = ReflectVerse(
  arabic: 'ثُمَّ رَدَدْنَـٰهُ أَسْفَلَ سَـٰفِلِينَ',
  translation:
      'Then We return him to the lowest of the low,',
  reference: 'At-Tin 95:5',
);

const ReflectVerse _verse52_28 = ReflectVerse(
  arabic: 'إِنَّا كُنَّا مِن قَبۡلُ نَدۡعُوهُۖ إِنَّهُۥ هُوَ ٱلۡبَرُّ ٱلرَّحِيمُ',
  translation:
      'Indeed, we used to supplicate Him before. Indeed, it is He who is the Beneficent, the Merciful.',
  reference: 'At-Tur 52:28',
);

const ReflectVerse _verse39_53 = ReflectVerse(
  arabic: 'قُلْ يَـٰعِبَادِىَ ٱلَّذِينَ أَسْرَفُوا۟ عَلَىٰٓ أَنفُسِهِمْ لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ ۚ إِنَّ ٱللَّهَ يَغْفِرُ ٱلذُّنُوبَ جَمِيعًا ۚ إِنَّهُۥ هُوَ ٱلْغَفُورُ ٱلرَّحِيمُ',
  translation:
      'Say, "O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allāh. Indeed, Allāh forgives all sins. Indeed, it is He who is the Forgiving, the Merciful."',
  reference: 'Az-Zumar 39:53',
);

const ReflectVerse _verse39_62 = ReflectVerse(
  arabic: 'ٱللَّهُ خَـٰلِقُ كُلِّ شَىْءٍۢ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍۢ وَكِيلٌۭ',
  translation:
      'Allāh is the Creator of all things, and He is, over all things, Disposer of affairs.',
  reference: 'Az-Zumar 39:62',
);

const ReflectVerse _verse35_10 = ReflectVerse(
  arabic: 'مَن كَانَ يُرِيدُ ٱلْعِزَّةَ فَلِلَّهِ ٱلْعِزَّةُ جَمِيعًا ۚ إِلَيْهِ يَصْعَدُ ٱلْكَلِمُ ٱلطَّيِّبُ وَٱلْعَمَلُ ٱلصَّـٰلِحُ يَرْفَعُهُۥ ۚ وَٱلَّذِينَ يَمْكُرُونَ ٱلسَّيِّـَٔاتِ لَهُمْ عَذَابٌ شَدِيدٌ ۖ وَمَكْرُ أُو۟لَـٰٓئِكَ هُوَ يَبُورُ',
  translation:
      'Whoever desires honor [through power] - then to Allāh belongs all honor. To Him ascends good speech, and righteous work raises it. But they who plot evil deeds will have a severe punishment, and the plotting of those - it will perish.',
  reference: 'Fatir 35:10',
);

const ReflectVerse _verse35_15 = ReflectVerse(
  arabic: '۞ يَـٰٓأَيُّهَا ٱلنَّاسُ أَنتُمُ ٱلْفُقَرَآءُ إِلَى ٱللَّهِ ۖ وَٱللَّهُ هُوَ ٱلْغَنِىُّ ٱلْحَمِيدُ',
  translation:
      'O mankind, you are those in need of Allāh, while Allāh is the Free of need, the Praiseworthy.',
  reference: 'Fatir 35:15',
);

const ReflectVerse _verse35_2 = ReflectVerse(
  arabic: 'مَّا يَفْتَحِ ٱللَّهُ لِلنَّاسِ مِن رَّحْمَةٍ فَلَا مُمْسِكَ لَهَا ۖ وَمَا يُمْسِكْ فَلَا مُرْسِلَ لَهُۥ مِنۢ بَعْدِهِۦ ۚ وَهُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ',
  translation:
      'Whatever Allāh grants to people of mercy - none can withhold it; and whatever He withholds - none can release it thereafter. And He is the Exalted in Might, the Wise.',
  reference: 'Fatir 35:2',
);

const ReflectVerse _verse41_39 = ReflectVerse(
  arabic: 'وَمِنْ ءَايَـٰتِهِۦٓ أَنَّكَ تَرَى ٱلْأَرْضَ خَـٰشِعَةً فَإِذَآ أَنزَلْنَا عَلَيْهَا ٱلْمَآءَ ٱهْتَزَّتْ وَرَبَتْ ۚ إِنَّ ٱلَّذِىٓ أَحْيَاهَا لَمُحْىِ ٱلْمَوْتَىٰٓ ۚ إِنَّهُۥ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ',
  translation:
      'And of His signs is that you see the earth stilled, but when We send down upon it rain, it quivers and grows. Indeed, He who has given it life is the Giver of Life to the dead. Indeed, He is over all things competent.',
  reference: 'Fussilat 41:39',
);

const ReflectVerse _verse41_53 = ReflectVerse(
  arabic: 'سَنُرِيهِمْ ءَايَـٰتِنَا فِى ٱلْـَٔافَاقِ وَفِىٓ أَنفُسِهِمْ حَتَّىٰ يَتَبَيَّنَ لَهُمْ أَنَّهُ ٱلْحَقُّ ۗ أَوَلَمْ يَكْفِ بِرَبِّكَ أَنَّهُۥ عَلَىٰ كُلِّ شَىْءٍۢ شَهِيدٌ',
  translation:
      'We will show them Our signs in the horizons and within themselves until it becomes clear to them that it is the truth. But is it not sufficient concerning your Lord that He is, over all things, a Witness?',
  reference: 'Fussilat 41:53',
);

const ReflectVerse _verse40_20 = ReflectVerse(
  arabic: 'وَٱللَّهُ يَقْضِى بِٱلْحَقِّ ۖ وَٱلَّذِينَ يَدْعُونَ مِن دُونِهِۦ لَا يَقْضُونَ بِشَىْءٍ ۗ إِنَّ ٱللَّهَ هُوَ ٱلسَّمِيعُ ٱلْبَصِيرُ',
  translation:
      'And Allāh judges with truth, while those they invoke besides Him judge not with anything. Indeed, Allāh - He is the Hearing, the Seeing.',
  reference: 'Ghafir 40:20',
);

const ReflectVerse _verse11_57 = ReflectVerse(
  arabic: 'فَإِن تَوَلَّوۡاْ فَقَدۡ أَبۡلَغۡتُكُم مَّآ أُرۡسِلۡتُ بِهِۦٓ إِلَيۡكُمۡۚ وَيَسۡتَخۡلِفُ رَبِّي قَوۡمًا غَيۡرَكُمۡ وَلَا تَضُرُّونَهُۥ شَيۡـًٔاۚ إِنَّ رَبِّي عَلَىٰ كُلِّ شَيۡءٍ حَفِيظٞ',
  translation:
      'But if you turn away, then I have already conveyed that with which I was sent to you. My Lord will give succession to a people other than you, and you will not harm Him at all. Indeed my Lord is, over all things, Guardian.',
  reference: 'Hud 11:57',
);

const ReflectVerse _verse11_6 = ReflectVerse(
  arabic: 'وَمَا مِن دَآبَّةٍۢ فِى ٱلْأَرْضِ إِلَّا عَلَى ٱللَّهِ رِزْقُهَا وَيَعْلَمُ مُسْتَقَرَّهَا وَمُسْتَوْدَعَهَا ۚ كُلٌّۭ فِى كِتَـٰبٍۢ مُّبِينٍۢ',
  translation:
      'And there is no creature on earth but that upon Allāh is its provision, and He knows its place of dwelling and place of storage. All is in a clear register.',
  reference: 'Hud 11:6',
);

const ReflectVerse _verse11_61 = ReflectVerse(
  arabic: 'وَإِلَىٰ ثَمُودَ أَخَاهُمْ صَـٰلِحًا ۚ قَالَ يَـٰقَوْمِ ٱعْبُدُوا۟ ٱللَّهَ مَا لَكُم مِّنْ إِلَـٰهٍ غَيْرُهُۥ ۖ هُوَ أَنشَأَكُم مِّنَ ٱلْأَرْضِ وَٱسْتَعْمَرَكُمْ فِيهَا فَٱسْتَغْفِرُوهُ ثُمَّ تُوبُوٓا۟ إِلَيْهِ ۚ إِنَّ رَبِّى قَرِيبٌ مُّجِيبٌ',
  translation:
      'And to Thamūd [We sent] their brother Ṣāliḥ. He said, \'O my people, worship Allāh; you have no deity other than Him. He has produced you from the earth and settled you in it, so ask forgiveness of Him and then repent to Him. Indeed, my Lord is near and responsive.\'',
  reference: 'Hud 11:61',
);

const ReflectVerse _verse11_66 = ReflectVerse(
  arabic: 'فَلَمَّا جَآءَ أَمْرُنَا نَجَّيْنَا صَـٰلِحًۭا وَٱلَّذِينَ ءَامَنُوا۟ مَعَهُۥ بِرَحْمَةٍۢ مِّنَّا وَمِنْ خِزْىِ يَوْمِئِذٍ ۗ إِنَّ رَبَّكَ هُوَ ٱلْقَوِىُّ ٱلْعَزِيزُ',
  translation:
      'So when Our command came, We saved Ṣāliḥ and those who believed with him, by mercy from Us, and [saved them] from the disgrace of that day. Indeed, it is your Lord who is the Powerful, the Exalted in Might.',
  reference: 'Hud 11:66',
);

const ReflectVerse _verse11_73 = ReflectVerse(
  arabic: 'قَالُوٓا۟ أَتَعْجَبِينَ مِنْ أَمْرِ ٱللَّهِ ۖ رَحْمَتُ ٱللَّهِ وَبَرَكَـٰتُهُۥ عَلَيْكُمْ أَهْلَ ٱلْبَيْتِ ۚ إِنَّهُۥ حَمِيدٌۭ مَّجِيدٌۭ',
  translation:
      'They said, "Are you amazed at the decree of Allāh? May the mercy of Allāh and His blessings be upon you, people of the house. Indeed, He is Praiseworthy and Honorable."',
  reference: 'Hud 11:73',
);

const ReflectVerse _verse14_1 = ReflectVerse(
  arabic: 'الٓرۚ كِتَٰبٌ أَنزَلۡنَٰهُ إِلَيۡكَ لِتُخۡرِجَ ٱلنَّاسَ مِنَ ٱلظُّلُمَٰتِ إِلَى ٱلنُّورِ بِإِذۡنِ رَبِّهِمۡ إِلَىٰ صِرَٰطِ ٱلۡعَزِيزِ ٱلۡحَمِيدِ',
  translation:
      'Alif, Lām, Rā. [This is] a Book which We have revealed to you, [O Muḥammad], that you might bring mankind out of darknesses into the light by permission of their Lord - to the path of the Exalted in Might, the Praiseworthy -',
  reference: 'Ibrahim 14:1',
);

const ReflectVerse _verse14_42 = ReflectVerse(
  arabic: 'وَلَا تَحْسَبَنَّ ٱللَّهَ غَـٰفِلًا عَمَّا يَعْمَلُ ٱلظَّـٰلِمُونَ ۚ إِنَّمَا يُؤَخِّرُهُمْ لِيَوْمٍۢ تَشْخَصُ فِيهِ ٱلْأَبْصَـٰرُ',
  translation:
      'And never think that Allāh is unaware of what the wrongdoers do. He only delays them for a Day when eyes will stare.',
  reference: 'Ibrahim 14:42',
);

const ReflectVerse _verse31_26 = ReflectVerse(
  arabic: 'لِلَّهِ مَا فِى ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۚ إِنَّ ٱللَّهَ هُوَ ٱلْغَنِىُّ ٱلْحَمِيدُ',
  translation:
      'To Allāh belongs whatever is in the heavens and earth. Indeed, Allāh is the Free of need, the Praiseworthy.',
  reference: 'Luqman 31:26',
);

const ReflectVerse _verse31_27 = ReflectVerse(
  arabic: 'وَلَوْ أَنَّمَا فِى ٱلْأَرْضِ مِن شَجَرَةٍ أَقْلَـٰمٌ وَٱلْبَحْرُ يَمُدُّهُۥ مِنۢ بَعْدِهِۦ سَبْعَةُ أَبْحُرٍ مَّا نَفِدَتْ كَلِمَـٰتُ ٱللَّهِ ۗ إِنَّ ٱللَّهَ عَزِيزٌ حَكِيمٌ',
  translation:
      'And if whatever trees upon the earth were pens and the sea [was ink], replenished thereafter by seven [more] seas, the words of Allāh would not be exhausted. Indeed, Allāh is Exalted in Might and Wise.',
  reference: 'Luqman 31:27',
);

const ReflectVerse _verse19_94 = ReflectVerse(
  arabic: 'لَّقَدْ أَحْصَىٰهُمْ وَعَدَّهُمْ عَدًّۭا',
  translation:
      'He has enumerated them and counted them a [full] counting.',
  reference: 'Maryam 19:94',
);

const ReflectVerse _verse47_38 = ReflectVerse(
  arabic: 'هَـٰٓأَنتُمْ هَـٰٓؤُلَآءِ تُدْعَوْنَ لِتُنفِقُوا۟ فِى سَبِيلِ ٱللَّهِ فَمِنكُم مَّن يَبْخَلُ ۖ وَمَن يَبْخَلْ فَإِنَّمَا يَبْخَلُ عَن نَّفْسِهِۦ ۚ وَٱللَّهُ ٱلْغَنِىُّ وَأَنتُمُ ٱلْفُقَرَآءُ ۚ وَإِن تَتَوَلَّوْا۟ يَسْتَبْدِلْ قَوْمًا غَيْرَكُمْ ثُمَّ لَا يَكُونُوٓا۟ أَمْثَـٰلَكُم',
  translation:
      'Here you are - those invited to spend in the cause of Allāh - but among you are those who withhold [out of greed]. And whoever withholds only withholds [benefit] from himself; and Allāh is the Free of need, while you are the needy. And if you turn away, He will replace you with another people; then they will not be the likes of you.',
  reference: 'Muhammad 47:38',
);

const ReflectVerse _verse71_4 = ReflectVerse(
  arabic: 'يَغْفِرْ لَكُم مِّن ذُنُوبِكُمْ وَيُؤَخِّرْكُمْ إِلَىٰٓ أَجَلٍۢ مُّسَمًّى ۚ إِنَّ أَجَلَ ٱللَّهِ إِذَا جَآءَ لَا يُؤَخَّرُ ۖ لَوْ كُنتُمْ تَعْلَمُونَ',
  translation:
      'He will forgive you of your sins and delay you for a specified term. Indeed, the time set by Allāh, when it comes, will not be delayed, if you only knew.',
  reference: 'Nuh 71:4',
);

const ReflectVerse _verse34_26 = ReflectVerse(
  arabic: 'قُلْ يَجْمَعُ بَيْنَنَا رَبُّنَا ثُمَّ يَفْتَحُ بَيْنَنَا بِٱلْحَقِّ وَهُوَ ٱلْفَتَّاحُ ٱلْعَلِيمُ',
  translation:
      'Say, \'Our Lord will bring us together; then He will judge between us in truth. And He is the Knowing Judge.\'',
  reference: 'Saba 34:26',
);

const ReflectVerse _verse38_35 = ReflectVerse(
  arabic: 'قَالَ رَبِّ ٱغۡفِرۡ لِي وَهَبۡ لِي مُلۡكٗا لَّا يَنۢبَغِي لِأَحَدٖ مِّنۢ بَعۡدِيٓۖ إِنَّكَ أَنتَ ٱلۡوَهَّابُ',
  translation:
      'He said, "My Lord, forgive me and grant me a kingdom such as will not belong to anyone after me. Indeed, You are the Bestower."',
  reference: 'Sad 38:35',
);

const ReflectVerse _verse20_114 = ReflectVerse(
  arabic: 'فَتَعَـٰلَى ٱللَّهُ ٱلْمَلِكُ ٱلْحَقُّ ۗ وَلَا تَعْجَلْ بِٱلْقُرْءَانِ مِن قَبْلِ أَن يُقْضَىٰٓ إِلَيْكَ وَحْيُهُۥ ۖ وَقُل رَّبِّ زِدْنِى عِلْمًۭا',
  translation:
      'So high is Allāh, the Sovereign, the Truth. And, [O Muḥammad], do not hasten with [recitation of] the Qur\'ān before its revelation is completed to you, and say, \'My Lord, increase me in knowledge.\'',
  reference: 'Ta-Ha 20:114',
);

const ReflectVerse _verse10_107 = ReflectVerse(
  arabic: 'وَإِن يَمْسَسْكَ ٱللَّهُ بِضُرٍّ فَلَا كَاشِفَ لَهُۥٓ إِلَّا هُوَ ۖ وَإِن يُرِدْكَ بِخَيْرٍ فَلَا رَآدَّ لِفَضْلِهِۦ ۚ يُصِيبُ بِهِۦ مَن يَشَآءُ مِنْ عِبَادِهِۦ ۚ وَهُوَ ٱلْغَفُورُ ٱلرَّحِيمُ',
  translation:
      'And if Allāh should touch you with adversity, there is no remover of it except Him; and if He intends for you good, then there is no repeller of His bounty. He causes it to reach whom He wills of His servants. And He is the Forgiving, the Merciful.',
  reference: 'Yunus 10:107',
);

const ReflectVerse _verse12_39 = ReflectVerse(
  arabic: 'يَـٰصَـٰحِبَىِ ٱلسِّجْنِ ءَأَرْبَابٌ مُّتَفَرِّقُونَ خَيْرٌ أَمِ ٱللَّهُ ٱلْوَٰحِدُ ٱلْقَهَّارُ',
  translation:
      'O [my] two companions of prison, are separate lords better or Allāh, the One, the Prevailing?',
  reference: 'Yusuf 12:39',
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
  // --- Plan 1 expansion: 83 additional canonical Names ---
  'Al-Jabbar': [_verse59_23, _verse59_24],
  'Al-Khaliq': [_verse59_24, _verse39_62],
  'Al-Wahhab': [_verse3_8, _verse38_35],
  'Al-Aleem': [_verse2_32, _verse49_13],
  'Al-Hayy': [_protectionVerse, _verse3_2],
  'Al-Qayyum': [_protectionVerse, _verse3_2],
  'An-Nur': [_verse24_35, _verse65_11],
  'Al-Muhaymin': [_verse59_23, _verse11_57],
  'Al-Mutakabbir': [_verse59_23, _verse13_9],
  'Al-Bari': [_verse59_24, _verse2_54],
  'Al-Musawwir': [_verse59_24, _verse3_6],
  'Al-Qahhar': [_verse12_39, _verse13_16],
  'Al-Fattah': [_verse34_26, _verse35_2],
  'Al-Qabid': [_verse2_245, _verse17_30],
  'Al-Basit': [_verse2_245, _verse42_12],
  'Al-Hakeem': [_verse2_32, _verse31_27],
  'Al-Kareem': [_verse82_6, _verse27_40],
  'At-Tawwab': [_verse2_37, _verse2_160],
  'Al-Hadi': [_verse22_54, _verse25_31],
  'As-Samad': [_verse112_1_2, _protectionVerse],
  'Al-Wakeel': [_verse3_173, _verse73_9],
  'Al-Mujeeb': [_verse2_186, _verse11_61],
  'Ash-Shafi': [_verse26_80, _verse17_82],
  'Ar-Raqeeb': [_verse4_1, _verse33_52],
  'Al-Khafid': [_verse56_3, _verse95_5],
  'Ar-Rafi': [_verse56_3, _verse58_11],
  'Al-Muizz': [_verse3_26, _verse35_10],
  'Al-Muzill': [_verse3_26, _verse22_18],
  'As-Sami': [_acceptanceVerse, _verse40_20],
  'Al-Baseer': [_verse40_20, _verse67_19],
  'Al-Hakam': [_verse6_114, _verse22_69],
  'Al-Adl': [_verse4_58, _verse16_90],
  'Al-Khabeer': [_verse67_14, _verse49_13],
  'Al-Azeem': [_protectionVerse, _verse56_96],
  'Al-Ghafur': [_verse39_53, _verse85_14],
  'Al-Ali': [_verse42_4, _verse87_1],
  'Al-Kabeer': [_verse13_9, _verse22_62],
  'Al-Muqeet': [_verse4_85, _verse11_6],
  'Al-Haseeb': [_verse4_6, _verse33_39],
  'Al-Jaleel': [_verse55_27, _verse55_78],
  'Al-Wasi': [_verse2_115, _verse2_268],
  'Al-Majeed': [_verse11_73, _verse85_15],
  'Al-Baith': [_verse22_7, _verse2_56],
  'Ash-Shaheed': [_verse4_166, _verse85_9],
  'Al-Haqq': [_verse22_6, _verse24_25],
  'Al-Qawiyy': [_verse11_66, _verse42_19],
  'Al-Mateen': [_verse51_58, _verse7_183],
  'Al-Waliyy': [_verse2_257, _verse42_28],
  'Al-Hameed': [_verse14_1, _verse31_26],
  'Al-Muhsi': [_verse19_94, _verse72_28],
  'Al-Mubdi': [_verse30_11, _verse85_13],
  'Al-Muid': [_verse30_27, _verse85_13],
  'Al-Muhyi': [_verse30_50, _verse41_39],
  'Al-Mumeet': [_verse53_44, _verse3_156],
  'Al-Wajid': [_verse4_64, _verse35_15],
  'Al-Majid': [_verse11_73, _verse85_15],
  'Al-Wahid': [_verse13_16, _verse2_163],
  'Al-Ahad': [_verse112_1, _verse112_2],
  'Al-Qadir': [_verse67_1, _verse2_20],
  'Al-Muqtadir': [_verse54_42, _verse54_55],
  'Al-Muqaddim': [_verse16_61, _verse56_10],
  'Al-Muakhkhir': [_verse14_42, _verse71_4],
  'Al-Awwal': [_verse57_3, _verse57_2],
  'Al-Akhir': [_verse57_3, _verse28_88],
  'Az-Zahir': [_verse57_3, _verse41_53],
  'Al-Batin': [_verse57_3, _verse67_13],
  'Al-Wali': [_verse42_9, _verse2_257],
  'Al-Mutaali': [_verse13_9, _verse20_114],
  'Al-Barr': [_verse52_28, _verse17_70],
  'Al-Afuw': [_verse4_43, _verse22_60],
  'Ar-Rauf': [_verse2_143, _verse9_117],
  'Malik-ul-Mulk': [_verse3_26, _verse67_1],
  'Dhul-Jalali wal-Ikram': [_verse55_27, _verse55_78],
  'Al-Muqsit': [_verse49_9, _verse60_8],
  'Al-Jami': [_verse3_9, _verse4_140],
  'Al-Ghaniyy': [_verse35_15, _verse47_38],
  'Al-Mughni': [_verse9_28, _verse53_48],
  'Al-Badi': [_verse2_117, _verse6_101],
  'Al-Baqi': [_verse55_26_27, _verse28_88],
  'Ad-Darr': [_verse6_17, _verse10_107],
  'An-Nafi': [_verse10_107, _verse35_2],
  'Al-Mani': [_verse35_2, _verse67_21],
  'Ar-Rasheed': [_verse18_10, _verse18_17],

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

/// Fallback callback signature. Accepts sync or async callers (`FutureOr`).
///
/// The wrapper inside `normalizeApprovedVerses` catches BOTH sync throws AND
/// async throws (via `catchError` on the returned Future) so a misbehaving
/// telemetry callback can never break the reflect flow.
typedef NormalizeFallback = FutureOr<void> Function(String aiReturnedName);

List<ReflectVerse> normalizeApprovedVerses(
  String name,
  List<ReflectVerse> verses, {
  NormalizeFallback? onFallback,
}) {
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

  final byName = approvedVersesForName(name);
  if (byName.isNotEmpty) {
    return byName.take(2).toList();
  }

  // Final safety net: any Name not in the catalog still gets two "always-safe"
  // verses. Prevents verseless cards if the AI returns a non-canonical Name.
  // Debug-only warning (debugPrint is a no-op in release). When investigating a
  // suspected canonical-name mismatch, run the app in debug mode and watch the
  // console for "unknown-name fallback fired" lines.
  if (kDebugMode) {
    debugPrint('[reflect_verse] WARN: unknown-name fallback fired for "$name". '
        'Check AI prompt + canonical-names list for spelling mismatch.');
  }
  // Fire-and-forget telemetry hook. Caller (ai_service.dart) wires a Supabase
  // insert into reflect_unknown_name_log. Optional so the catalog stays
  // dependency-free for unit tests. Wrapped to catch both sync AND async
  // throws because reflect must NEVER break because of telemetry — pinned by
  // reflection_verse_catalog_unknown_name_callback_test.dart "throws" tests.
  if (onFallback != null) {
    try {
      final result = onFallback(name);
      if (result is Future) {
        unawaited(result.catchError((Object e) {
          if (kDebugMode) {
            debugPrint('[reflect_verse] onFallback async error: $e — swallowed.');
          }
        }));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[reflect_verse] onFallback threw: $e — swallowed.');
      }
    }
  }
  return const [_heartsRestVerse, _noBurdenVerse];
}

// `buildApprovedVersePrompt` was removed in Plan 1 Task 0 (2026-05-12).
// The AI prompt no longer enumerates approved verses — the catalog is the
// deterministic source via `normalizeApprovedVerses` instead. Saves ~10KB
// input tokens per reflect call. If reintroducing AI-driven verse selection,
// regenerate this helper from `approvedReflectVersesByName.entries`.
