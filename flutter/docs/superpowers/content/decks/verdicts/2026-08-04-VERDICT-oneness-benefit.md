# Verdict — batch `oneness-benefit` — 2026-08-04

Blind adversarial verification of seven decks: Al-Wahid (73), Al-Ahad (74), Al-Hameed (65),
Ash-Shakur (28), Al-Mani (94), Ad-Darr (95), An-Nafi (96). Every citation below was fetched live
this session — `api.quran.com/api/v4`, `corpus.quran.com/qurandictionary.jsp`, `sunnah.com` via
Wayback `id_` raw, and the repo's own `assets/content/name_stories.json` /
`collectible_names.json` / `test/content/name_stories_ship_gate_test.dart`. Nothing here was
recalled from training or copied from the drafter's own tables without independent refetch.

**Headline: this is the most accurate wave I have verified against.** Every scriptural quotation,
every root-sweep total, every hadith grade line, and every cross-deck disclosure I checked matched
the fetched source exactly. I found zero fabrications and zero misquotations. The defects below are
real but are mostly *structural/register judgment calls* the drafter already flagged as contestable,
plus one confirmed engineering gap (pair enforcement) that is outside any single deck's control.

---

## 1 · Citation table — everything fetched, what it actually says

| # | Claim (deck) | Source fetched | What came back | Verdict |
|---|---|---|---|---|
| 1 | 21:21 — "Or have they taken for themselves gods from the earth who resurrect [the dead]?" (Al-Wahid beat 3) | `api.quran.com/.../21:21` | `أَمِ ٱتَّخَذُوٓا۟ ءَالِهَةً مِّنَ ٱلْأَرْضِ هُمْ يُنشِرُونَ` — matches, whole āyah | ✅ |
| 2 | 21:22 — "Had there been within them gods besides Allah, they both would have been ruined. So exalted is Allah..." (Al-Wahid beats 4–5) | `.../21:22` | `لَوْ كَانَ فِيهِمَآ ءَالِهَةٌ إِلَّا ٱللَّهُ لَفَسَدَتَا ۚ فَسُبْحَـٰنَ ٱللَّهِ رَبِّ ٱلْعَرْشِ عَمَّا يَصِفُونَ` — whole āyah, split at natural clause boundary, translation verbatim | ✅ |
| 3 | 21:23 (n+1) — "He is not questioned..." | `.../21:23` | Confirmed clean, no punishment | ✅ |
| 4 | 16:51 — "Allah has said, do not take two deities... one God..." (Al-Wahid beat 6) | `.../16:51` | `وَقَالَ ٱللَّهُ لَا تَتَّخِذُوٓا۟ إِلَـٰهَيْنِ ٱثْنَيْنِ ۖ إِنَّمَا هُوَ إِلَـٰهٌ وَٰحِدٌ ۖ فَإِيَّـٰىَ فَٱرْهَبُونِ` — quoted region ends at `وَٰحِدٌ`, tail (`فَإِيَّاىَ فَٱرْهَبُونِ`, "so fear only Me") correctly cut with disclosed ellipsis | ✅ |
| 5 | 16:52 (n+1) — warm continuation | `.../16:52` | Confirmed clean | ✅ |
| 6 | و-ح-د root: 68 occurrences, 4 forms (30 wāḥid/31 wāḥidat/6 waḥd/1 waḥīd); `الْوَاحِدُ الْقَهَّارُ` exactly 6× (12:39, 13:16, 14:48, 38:65, 39:4, 40:16) | `corpus.quran.com/qurandictionary.jsp?q=wHd` + individual verse fetches | Corpus headline: "occurs 68 times... 30/31/6/1" — exact match. **All 6 individual āyāt fetched and independently confirmed to read `ٱلْوَٰحِدُ ٱلْقَهَّارُ`** | ✅ **independently confirmed, not just read off the draft's table** |
| 7 | 6:100 — "attributed to Allah partners... exalted is He" (Al-Ahad beat 3) | `.../6:100` | `وَجَعَلُوا۟ لِلَّهِ شُرَكَآءَ ٱلْجِنَّ وَخَلَقَهُمْ ۖ وَخَرَقُوا۟ لَهُۥ بَنِينَ وَبَنَـٰتٍۭ بِغَيْرِ عِلْمٍ ۚ سُبْحَـٰنَهُۥ وَتَعَـٰلَىٰ عَمَّا يَصِفُونَ` — whole āyah, matches | ✅ |
| 8 | 6:101 — "how could He have a son... He created all things, Knowing" (Al-Ahad beats 4–5) | `.../6:101` | `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ وَلَمْ تَكُن لَّهُۥ صَـٰحِبَةٌ ۖ وَخَلَقَ كُلَّ شَىْءٍ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ` — leading cut at `بَدِيعُ...الْأَرْضِ` (Al-Badi's ground) correctly disclosed and excised | ✅ |
| 9 | 6:102 — "no deity except Him, Creator of all things, so worship Him..." (Al-Ahad beat 6) | `.../6:102` | `ذَٰلِكُمُ ٱللَّهُ رَبُّكُمْ ۖ لَآ إِلَـٰهَ إِلَّا هُوَ ۖ خَـٰلِقُ كُلِّ شَىْءٍ فَٱعْبُدُوهُ ۚ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ وَكِيلٌ` — trailing `وَكِيلٌ` (Al-Wakeel's shipped root) correctly cut and disclosed | ✅ |
| 10 | 6:99 (n−1), 6:103 (n+1), 6:104 | `.../6:99`, `.../6:103`, `.../6:104` | 6:99 clean (rain/growth signs). 6:103: `ٱللَّطِيفُ ٱلْخَبِيرُ` confirmed sitting one āyah past the deck's last quotation — deck correctly stops before it. 6:104 confirmed a `قُلْ`-adjacent Prophetic disclaimer, not rendered | ✅ |
| 11 | 112:1, 112:4 — Al-Ikhlāṣ, checked and set aside (Al-Ahad) | `.../112:1`, `.../112:4` | `قُلْ هُوَ ٱللَّهُ أَحَدٌ` / `وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ` confirmed — 112:1 is genuinely `قُلْ`-governed | ✅ |
| 12 | أ-ح-د root: 85 occurrences, 2 forms (74 aḥad + 11 iḥ'dā) | `corpus.quran.com/qurandictionary.jsp?q=AHd` | "occurs 85 times... 74 times... 11 times" — exact match | ✅ |
| 13 | 34:1 — both `ٱلْحَمْد` clauses + closing `ٱلْحَكِيمُ ٱلْخَبِيرُ` (Al-Hameed / al-hakeem / al-khabeer three-way split) | `.../34:1` | `ٱلْحَمْدُ لِلَّهِ ٱلَّذِى لَهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ وَلَهُ ٱلْحَمْدُ فِى ٱلْـَٔاخِرَةِ ۚ وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ`. **Al-Hameed's own beats render only the two `الحمد` clauses; the closing `الحكيم الخبير` is absent from every Al-Hameed beat, confirmed by reading the draft's actual beat text, not its table.** `al-hakeem@1` renders `ٱلْحَكِيمُ` alone (ellipsis both sides); `al-khabeer@1` renders `ٱلْخَبِيرُ` alone (ellipsis both sides). **Three-way split confirmed non-overlapping** | ✅ |
| 14 | 34:2 (n+1) — closes `ٱلرَّحِيمُ ٱلْغَفُورُ` | `.../34:2` | Confirmed | ✅ |
| 15 | 11:73 — "are you amazed at the decree of Allah... indeed He is Praiseworthy and Honorable" (`حَمِيدٌ مَّجِيدٌ`) | `.../11:73` | `قَالُوٓا۟ أَتَعْجَبِينَ مِنْ أَمْرِ ٱللَّهِ ۖ رَحْمَتُ ٱللَّهِ وَبَرَكَـٰتُهُۥ عَلَيْكُمْ أَهْلَ ٱلْبَيْتِ ۚ إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` — confirmed whole āyah. **Confirmed rendered whole by `al-majeed@1`** (read that deck's actual beat text: story quotes the full āyah, verse beat quotes the closing clause `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ`) — id 65's `حميد` is genuinely spent here, and `al-majeed@1`'s own file discloses this unprompted ("11:73's `حَمِيدٌ` — id 65 Al-Hameed's word... disclosed, not avoidable") | ✅ **cross-deck spend confirmed by reading both decks' actual text, not by trusting either table** |
| 16 | ح-م-د root: 63 occurrences, 5 forms | `corpus.quran.com/qurandictionary.jsp?q=Hmd` | "occurs 63 times... 5 derived forms" (1 verb + 43 ḥamd + 17 ḥamīd + 1 + 1) — exact match | ✅ |
| 17 | 35:15 — `ٱلْغَنِىُّ ٱلْحَمِيدُ` (Al-Ghaniyy's reserved ground, disclosed by Al-Hameed) | `.../35:15` | `وَٱللَّهُ هُوَ ٱلْغَنِىُّ ٱلْحَمِيدُ` confirmed | ✅ |
| 18 | 35:29 — "recite the Book of Allah... secretly and publicly... a transaction that will never perish" (Ash-Shakur beat 3) | `.../35:29` | `إِنَّ ٱلَّذِينَ يَتْلُونَ كِتَـٰبَ ٱللَّهِ وَأَقَامُوا۟ ٱلصَّلَوٰةَ وَأَنفَقُوا۟ مِمَّا رَزَقْنَـٰهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ تِجَـٰرَةً لَّن تَبُورَ` — "secretly and publicly" and "a transaction that will never perish" **both verbatim from Saheeh International (translation 20)**, confirmed on the live fetch, not a splice | ✅ |
| 19 | 35:30 — "give them in full their rewards and increase for them of His bounty. Indeed, He is Forgiving and Appreciative." (Ash-Shakur beats 4–6) | `.../35:30` | `لِيُوَفِّيَهُمْ أُجُورَهُمْ وَيَزِيدَهُم مِّن فَضْلِهِۦٓ ۚ إِنَّهُۥ غَفُورٌ شَكُورٌ` — whole āyah verbatim, `شَكُورٌ` genuinely predicated of Allah (`إِنَّهُۥ`, referring back to the same subject as the two preceding verbs) | ✅ — see bar-1/2 discussion below; genuinely predicated, but structurally a trailing pair-epithet |
| 20 | 35:28 (n−1), 35:31 (n+1) | `.../35:28`, `.../35:31` | 35:28 closes `عَزِيزٌ غَفُورٌ`; 35:31 closes `لَخَبِيرٌۢ بَصِيرٌ`. Both clean, no punishment | ✅ |
| 21 | ش-ك-ر root: 75 occurrences, 6 forms; `shakūr` (of Allah) 10× | `corpus.quran.com/qurandictionary.jsp?q=$kr` | "occurs 75 times... 46/1/10/2/14/2" — exact match | ✅ |
| 22 | `al-kareem@1` (shipped) actual engine — nightly descent, unprompted offer | `assets/content/name_stories.json`, `al-kareem@1` | Confirmed: story is Bukhārī 1145's "who calls upon Me... who asks Me" — unprompted, not a response to a prior act. Genuinely distinct from Ash-Shakur's "response to an already-done deed" engine | ✅ |
| 23 | م-ن-ع root: 17 occurrences, 5 forms (12 verb/2 adj/1 noun/1 act.part/1 pass.part); Allah never finite subject | `corpus.quran.com/qurandictionary.jsp?q=mnE` | "occurs 17 times... 12/2/1/1/1" — exact match | ✅ |
| 24 | 35:2 — "whatever Allah grants... none can withhold it; whatever He withholds, none can release it. Exalted in Might, Wise." (Al-Mani verse beat; al-fattah@1's shipped verse beat, first clause) | `.../35:2` | `مَّا يَفْتَحِ ٱللَّهُ لِلنَّاسِ مِن رَّحْمَةٍ فَلَا مُمْسِكَ لَهَا ۖ وَمَا يُمْسِكْ فَلَا مُرْسِلَ لَهُۥ مِنۢ بَعْدِهِۦ ۚ وَهُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ`. **`al-fattah@1`'s shipped verse beat = "Whatever mercy Allah opens up for people, none can withhold it" — confirmed byte-match to the first clause.** Al-Mani's verse beat = "...and whatever He withholds - none can release it thereafter" — confirmed byte-match to the second clause | ✅ **same-āyah split confirmed real by reading the shipped JSON directly, not the draft's claim about it** |
| 25 | 35:1 — "Creator of the heavens and the earth... He increases in creation what He wills" (Al-Mani story) | `.../35:1` | `ٱلْحَمْدُ لِلَّهِ فَاطِرِ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ...يَزِيدُ فِى ٱلْخَلْقِ مَا يَشَآءُ` — "Creator" is Saheeh's rendering of `فَاطِرِ`. Confirmed `al-khaliq@1`'s shipped `name_intro` is the byte-string **"The Creator"** and `al-aleem@1`'s shipped duʿā renders the *same* Arabic root (`فَاطِرَ`) as **"Originator,"** not "Creator" | ✅ **both disclosed collisions confirmed real by reading the shipped JSON, not assumed** |
| 26 | 35:3 — "O mankind... is there any creator other than Allah who provides for you... no deity except Him" | `.../35:3` | `يَـٰٓأَيُّهَا ٱلنَّاسُ ٱذْكُرُوا۟ نِعْمَتَ ٱللَّهِ عَلَيْكُمْ ۚ هَلْ مِنْ خَـٰلِقٍ غَيْرُ ٱللَّهِ يَرْزُقُكُم مِّنَ ٱلسَّمَآءِ وَٱلْأَرْضِ ۚ لَآ إِلَـٰهَ إِلَّا هُوَ ۖ فَأَنَّىٰ تُؤْفَكُونَ` confirmed verbatim | ✅ |
| 27 | 35:15–17 — Al-Ghaniyy (id 92)'s claimed ground | `.../35:15`, `.../35:16`, `.../35:17` | All three confirmed. **No overlap with Al-Mani's 35:1–3** — different āyāt entirely, 12–14 verses apart | ✅ **item-8 collision fear resolved: no collision** |
| 28 | Ibn Majah 4023 — "which people are most severely tested... the Prophets, then the next best..." (Ad-Darr beats 3–5) | `web.archive.org/.../sunnah.com/ibnmajah:4023` | **Printed grade line: "Grade: Hasan (Darussalam)."** Arabic: `قُلْتُ يَا رَسُولَ اللَّهِ أَىُّ النَّاسِ أَشَدُّ بَلاَءً قَالَ الأَنْبِيَاءُ ثُمَّ الأَمْثَلُ فَالأَمْثَلُ يُبْتَلَى الْعَبْدُ عَلَى حَسَبِ دِينِهِ فَإِنْ كَانَ فِي دِينِهِ صُلْبًا اشْتَدَّ بَلاَؤُهُ وَإِنْ كَانَ فِي دِينِهِ رِقَّةٌ ابْتُلِيَ عَلَى حَسَبِ دِينِهِ فَمَا يَبْرَحُ الْبَلاَءُ بِالْعَبْدِ حَتَّى يَتْرُكَهُ يَمْشِي عَلَى الأَرْضِ وَمَا عَلَيْهِ مِنْ خَطِيئَةٍ` — matches the deck's rendering exactly, narrated from Saʿd b. Abī Waqqāṣ via his son Muṣʿab | ✅ |
| 29 | Tirmidhi 2396 — "the greatest reward comes with the greatest trial..." (Ad-Darr beat 5) | `web.archive.org/.../sunnah.com/tirmidhi:2396` | **Printed grade line: "Grade: Hasan (Darussalam)."** At-Tirmidhī's own note, confirmed on the page: `قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ حَسَنٌ غَرِيبٌ مِنْ هَذَا الْوَجْهِ` ("Abū ʿĪsā said: this is a ḥasan gharīb ḥadīth from this route"). Arabic: `إِنَّ عِظَمَ الْجَزَاءِ مَعَ عِظَمِ الْبَلاَءِ وَإِنَّ اللَّهَ إِذَا أَحَبَّ قَوْمًا ابْتَلاَهُمْ` — matches, narrated Anas b. Mālik | ✅ |
| 30 | **The second narration on the same Tirmidhi 2396 page, same isnād** — "When Allah wants good for His slave, He hastens his punishment in the world..." | Same page | **Confirmed present, on the exact same page, same isnād chain** (`قُتَيْبَةُ...عَنْ أَنَسٍ`): `إِذَا أَرَادَ اللَّهُ بِعَبْدِهِ الْخَيْرَ عَجَّلَ لَهُ الْعُقُوبَةَ فِي الدُّنْيَا وَإِذَا أَرَادَ اللَّهُ بِعَبْدِهِ الشَّرَّ أَمْسَكَ عَنْهُ بِذَنْبِهِ حَتَّى يُوَفَّى بِهِ يَوْمَ الْقِيَامَةِ`. **Confirmed rendered on no beat of Ad-Darr** — I read all eight of the deck's beats directly; the word "hastens" / "punishment" / this clause's content does not appear anywhere | ✅ **the drafter's disclosure is accurate, and the omission is real, not merely claimed** |
| 31 | 2:126 and 31:24 — the only two places Allah is finite subject of a `ض-ر-ر` verb (both Hellfire clauses for chosen disbelief) | `.../2:126`, `.../31:24` | 2:126: `...ثُمَّ أَضْطَرُّهُۥٓ إِلَىٰ عَذَابِ ٱلنَّارِ وَبِئْسَ ٱلْمَصِيرُ` ("...then I will force him to the punishment of the Fire, and wretched is the destination"). 31:24: `...ثُمَّ نَضْطَرُّهُمْ إِلَىٰ عَذَابٍ غَلِيظٍ` ("...then We will force them to a massive punishment"). **Both confirmed Allah first-person subject, both confirmed Hellfire-for-disbelief clauses, both confirmed rendered on no beat of any of the 7 decks in this batch** | ✅ **the deck's own self-undercutting disclosure verified true** |
| 32 | ض-ر-ر root: 74 occurrences, 11 forms | `corpus.quran.com/qurandictionary.jsp?q=Drr` | "occurs 74 times... in 11 derived forms" (19/3/7/10/19/9/...) — exact match | ✅ |
| 33 | 6:17 — "if Allah should touch you with adversity, there is no remover of it except Him..." (Ad-Darr verse beat) | `.../6:17` | `وَإِن يَمْسَسْكَ ٱللَّهُ بِضُرٍّ فَلَا كَاشِفَ لَهُۥٓ إِلَّا هُوَ ۖ وَإِن يَمْسَسْكَ بِخَيْرٍ فَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ` — quoted region ends at `هُوَ`, tail (`وَإِن يَمْسَسْكَ بِخَيْرٍ...قَدِيرٌ`) correctly cut, ellipsis disclosed | ✅ |
| 34 | 6:16 (n−1), 6:18 (n+1) | `.../6:16`, `.../6:18` | 6:16: Judgment-Day mercy, positive. 6:18: `ٱلْقَاهِرُ...ٱلْحَكِيمُ ٱلْخَبِيرُ` — clean, no punishment | ✅ |
| 35 | Sunan Ibn Majah 925 — the duʿā (An-Nafi beat 7, proposed pin) | `web.archive.org/.../sunnah.com/ibnmajah:925` | **Printed grade line: "Grade: Sahih (Darussalam)."** Arabic: `اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلاً مُتَقَبَّلاً`, narrated Umm Salama, said by the Prophet ﷺ after the Fajr salām | ✅ |
| 36 | Codepoint diff, catalogue `dua_arabic` id 96 vs the Ibn Majah 925 page | `assets/content/collectible_names.json` id 96, diffed against fetch #35 | **Confirmed, character by character.** Removing the page's commas, the two strings differ at exactly two points: the words *"وَعَمَلًا"* and *"مُتَقَبَّلًا"*. Catalogue orders each tanwīn-fatḥa mark **before** the alif (U+064B then U+0627 — same order the first three tanwīn-fatḥa words use, on both strings). The fetched page orders these same two words **alif-then-mark** (U+0627 then U+064B) — inconsistently with its *own* first three tanwīn-fatḥa words on the same line. **Rasm-identical (same letters, same pronunciation), not byte-identical** — exactly as the draft claims | ✅ **independently re-derived, not trusted from the table** |
| 37 | Tirmidhi 2516 — Ibn ʿAbbās, "be mindful of Allah... the whole creation could not benefit/harm you except..." (An-Nafi beats 3–5) | `web.archive.org/.../sunnah.com/tirmidhi:2516` | **Printed grade line: "Grade: Hasan (Darussalam)."** At-Tirmidhī's own note: `قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ` ("ḥasan ṣaḥīḥ"). Arabic matches the deck's rendering in full, including the `لَكَ`/`عَلَيْكَ` distinction (written **for** you vs **against** you) that sunnah.com's own English flattens into "written for you" both times — confirmed the deck's re-rendering from Arabic is a genuine correction, not a fabrication | ✅ |
| 38 | 2:164 — "the ships which sail through the sea with that which benefits people, and what Allah has sent down..." (An-Nafi verse beat) | `.../2:164` | `وَٱلْفُلْكِ ٱلَّتِى تَجْرِى فِى ٱلْبَحْرِ بِمَا يَنفَعُ ٱلنَّاسَ وَمَآ أَنزَلَ ٱللَّهُ مِنَ ٱلسَّمَآءِ مِن مَّآءٍ فَأَحْيَا بِهِ ٱلْأَرْضَ بَعْدَ مَوْتِهَا` — **Saheeh International verbatim**, trimmed from the middle of a longer list-āyah, both ellipses correctly placed | ✅ |
| 39 | 2:163 (n−1), 2:165 (n+1) | `.../2:163`, `.../2:165` | 2:163 positive (`ٱلرَّحْمَـٰنُ ٱلرَّحِيمُ`). 2:165 closes *"...Allāh is severe in punishment"*, addressee = *"those who have wronged"* (third person, idolaters) — confirmed the deck's disclosed, non-blocking successor per the `al-afuw@1` 42:26 precedent | ✅ |
| 40 | ن-ف-ع root: 50 occurrences, 3 forms; `Allah` finite subject of `yanfaʿu`: 0 of 31 | `corpus.quran.com/qurandictionary.jsp?q=nfE` | "occurs 50 times... 31/8/11" — exact match | ✅ |
| 41 | `al-qabid@1` (shipped) — separate root (`q-b-ḍ`), separate duʿā, shared "Withholder" gloss with Al-Mani | `assets/content/name_stories.json` | Verse beat = 2:245 (`...وَاللَّهُ يَقْبِضُ وَيَبْسُطُ...`), story = 25:45–46 — confirmed entirely disjoint scripture from Al-Mani's 35:1–3 | ✅ |
| 42 | Sūrat al-Anbiyāʾ carries 4 decks once Al-Wahid ships: `ash-shafi@1` (21:83–84), `al-mujeeb@1` (21:87–88), `al-wahhab@1` (21:71–72), all shipped | `assets/content/name_stories.json` | All three confirmed present with exactly those citations, all `review_verdict: "good"` | ✅ **third-deck-in-Anbiyāʾ claim independently confirmed by reading the shipped asset, not trusted** |
| 43 | The ship-gate pair-synergy assertion only loops over `chip_keys` | `test/content/name_stories_ship_gate_test.dart` | Confirmed by reading the test source directly (lines 133–146, 330–347): every pairing test in the file (`chipKeys.contains(chip)` and the pair-synergy test) iterates `chipKeys` — the fixed 7-value set `{anxiety, far-from-allah, guilt, heavy, rizq, sign, unseen}`. There is **no assertion anywhere in the file** that checks a "must ship together" ruling stated only in a plan doc or a deck's own prose | ✅ |
| 44 | Ad-Darr (95) and An-Nafi (96) both carry `chip_keys: []` in their proposed metadata | Both `*-DRAFT.md` beat tables | Confirmed: neither deck's proposed metadata assigns any chip. **The gate literally cannot see this pair — it has nothing to loop over for these two ids** | ✅ |
| 45 | Same gap already live in production for other "must-ship-together" pairs | `assets/content/name_stories.json` | `al-qabid@1`, `al-basit@1`, `al-khafid@1`, `ar-rafi@1` — all four **shipped**, all four carry `chip_keys: []`. The gap Ad-Darr/An-Nafi would inherit is not new; it is the same unenforced pattern already in production | ✅ |
| 46 | Shipped decks' `review_verdict` field is the literal string `'good'`, never `'VERIFIED'` | `assets/content/name_stories.json` | `{d.get('review_verdict') for d in decks} == {'good'}`; `reviewed_by == 'founder'` on the sampled entry | ✅ — flagged as a transcription-time note, not a defect in the drafts |

---

## 2 · Five-bars verdicts

### Al-Wahid (`al-wahid@1`, id 73)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 21:22 is Allah's own third-person narration, no `قُلْ` in the passage until 21:24 (checked directly). Confirmed the deck claims bar 1 for beat 4 only, not beat 6 — 16:51 is correctly disclosed as "bar-4-only duty" |
| 2 | **PASS** | Genuine counterfactual ("had there been... they both would have been ruined"), not a static declaration |
| 3 | **PASS, with one disclosed 4-word doxological overlap with Al-Ahad** ("above what they describe" / `عَمَّا يَصِفُونَ`) — a recurring Qurʾānic tasbīḥ formula, correctly treated as non-blocking per the project's own standing rule (shared scripture ≠ a taught insight) | confirmed by direct comparison of both decks' actual beat 5/beat 3 text |
| 4 | **TRADED on the story, recovered on the verse beat** — confirmed: 21:21–22 carry no `و-ح-د`; 16:51 does (`إِلَٰهٌ وَٰحِدٌ`). The 6/6 `الْوَاحِدُ الْقَهَّارُ` reservation for Al-Qahhar is independently confirmed (row 6 above) | verified |
| 5 | **PASS** | 21:21/21:23 clean; 16:51's own tail cut for register (not a bar-5 rescue, correctly labelled as such), 16:52–53 clean |

### Al-Ahad (`al-ahad@1`, id 74)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS on 6:100–102** (no `قُلْ` in 6:99–104, confirmed). **112:1 correctly ruled OUT** — it is a `قُلْ`-instructed recitation, which the brief's own bar-1 ladder text explicitly places in the "does not carry" tier. This is not an extension of precedent, it is a direct reading of the standing rule | verified independently against the fetched text and the brief's own ladder |
| 2 | **PASS** | The consort/creation impossibility argument (6:101) is a genuine "shown" argument, not a bare declaration; 6:102's `لَآ إِلَـٰهَ إِلَّا هُوَ` correctly sequenced *after* it |
| 3 | **PASS**, same doxological disclosure as Al-Wahid, and the twin-diff (rival-in-kind vs. rival-ruler) holds up under direct reading of both decks' story engines | verified |
| 4 | **TRADED IN FULL, no recovery anywhere on the deck** — confirmed: 85 occurrences of أ-ح-د swept, zero available (both divine-sense hits are inside 112, both `قُلْ`-scoped, one already spent by shipped `as-samad@1`). Unlike Al-Wahid (recovers on the verse beat) and Al-Mani/Ad-Darr/An-Nafi (recover in the catalogue-locked duʿā), **Al-Ahad's shared duʿā recovers only the SIBLING's root** (`وَحِّدْ`, و-ح-د) — the Name's own root, أ-ح-د, literally never renders anywhere on this deck, Arabic or English, beyond the `name_intro` field. This is the weakest bar-4 position in the batch. The trade is forced (exhaustive sweep, verified), but it is a total trade, not a partial one, and that distinction is understated in the deck's own five-bars table, which reads "traded" without flagging that it is total | **CONTESTED — disclosed but understated** |
| 5 | **PASS** | 6:99, 6:103, 6:104 all clean, all confirmed |

### Al-Hameed (`al-hameed@1`, id 65)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 34:1, Allah's own voice, `الْحَمْدُ` predicated twice |
| 2 | **CONTESTED — the thinnest bar-2 case in this batch.** The deck's argument is that praise predicated *twice*, once "in this world" and once "in the Hereafter," constitutes "showing" that praise is owed independent of circumstance. But structurally this is still two adjacent declarative clauses (`لَهُ الْحَمْدُ`, `وَلَهُ الْحَمْدُ`), not a parable or a counterfactual — the brief's own bar 2 language explicitly distinguishes "a parable or counterfactual counts as showing" from "a static declaration of attribute does not." 34:1 is closer to the second category than any other verse-beat carrier in this batch. I do not think this sinks the deck (the doubling across two conditions is a real, if modest, rhetorical move, and the reader's stated objection — "praise now feels dishonest" — is genuinely answered by "the praise is not conditioned on your circumstances, unconditionally, in either world"), but a founder should read this as the deck's weakest bar, not a clean pass | independently re-read against the fetched text |
| 3 | **PASS on all three surfaces.** The 34:1 three-way split with `al-hakeem@1`/`al-khabeer@1` is confirmed non-overlapping by directly reading all three decks' beat text (not their tables). The 11:73 spend by `al-majeed@1` is confirmed real and mutually disclosed by both decks independently | verified |
| 4 | **PASS, no trade** — `ٱلْحَمْدُ` is on-screen twice in the story/verse beats | verified |
| 5 | **PASS** | 34:1 is sūrah-opening (no n−1); 34:2 clean |

### Ash-Shakur (`ash-shakur@1`, id 28)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS, but this is the closest bar-1 call in the batch.** `شَكُورٌ` at 35:30 is structurally a trailing pair-epithet (`إِنَّهُۥ غَفُورٌ شَكُورٌ`), the same surface shape the brief's failure catalogue explicitly warns can mislabel a label as a demonstration. I rule this a genuine pass, not a mislabel, because the epithet is not appended to an unrelated clause — it closes the *same sentence* whose two preceding verbs (`لِيُوَفِّيَهُمْ`/pay in full, `وَيَزِيدَهُم`/increase) are the very act the word `شَكُور` names. The demonstration and the epithet are the same unit of text, not adjacent-but-separate. Still, a verifier attacking this deck should start here | independently re-read against the fetched text, not the deck's own framing |
| 2 | **PASS** | "In full, and then increased" is a genuine arithmetic-and-surplus structure, shown rather than stated |
| 3 | **PASS** | 45-deck sweep max run = 3 words, confirmed lowest in the wave; the al-kareem@1 differentiation (unprompted gift vs. response to a prior act) verified against the actual shipped beat text |
| 4 | **PASS, no trade** | `شَكُورٌ` on-screen at 35:30 |
| 5 | **PASS** | 35:28/35:31 clean, confirmed |

### Al-Mani (`al-mani@1`, id 94)

| bar | verdict | evidence |
|---|---|---|
| 1 | **MET on a traded root — confirmed.** م-ن-ع sweep (17 occurrences) independently reconfirmed at the corpus level; Allah is genuinely never finite subject of `m-n-ʿ`. 35:2's `يُمْسِكْ` (root م-س-ك) carries Allah as continuing grammatical subject from the āyah's own opening clause — a legitimate trade, same class as `al-khafid@1`'s precedent | verified |
| 2 | **PASS** | No beat asserts the catalogue's own "protects" framing; the demonstration is the quoted āyah itself |
| 3 | **PASS, and the two disclosed overlaps (al-fattah@1's same-āyah split, al-khaliq@1's "Creator" gloss) are both real and both correctly ruled non-blocking.** The al-fattah@1 split is a genuine subject-reversal (creatures-cannot vs. Allah-does), matching a precedent `al-qabid@1` already established against the same shipped deck — I independently confirmed both halves of the āyah are in fact rendered by the two different decks, not merely claimed to be | verified against the shipped JSON directly |
| 4 | **TRADED, deliberately, sweep confirmed exhaustive** | `m-n-ʿ` genuinely absent from the Qur'ān as a divine epithet; recovered in Arabic on the duʿā beat (`يَا مَانِعُ`/`امْنَعْ`) |
| 5 | **PASS** | Full successor sweep clean; nearest punishment (35:6) is 3 āyāt past the last quoted material, correctly disclosed rather than hidden |
| — | **Completion gap, confirmed:** no `reflection` beat. Correctly and honestly left unauthored rather than backfilled by the same drafter reviewing their own new text | confirmed against the actual beat table (7 beats, ending at `takeaway`) |

### Ad-Darr (`ad-darr@1`, id 95)

| bar | verdict | evidence |
|---|---|---|
| 1 | **MET, traded** | 6:17's `يَمْسَسْكَ` — Allah explicit named subject of "touch," `بِضُرٍّ` as complement. Genuine trade off the ordinary `ḍ-r-r` verb, confirmed the ordinary form never takes Allah as subject anywhere in the Qur'ān (74-occurrence sweep, independently reconfirmed at the corpus level) |
| 2 | **PASS** | Ibn Mājah 4023's scaled-testing answer and the duʿā's forward-facing petition both genuinely show rather than assert |
| 3 | **PASS**, with the twin-diff (Saʿd's question vs. Ibn ʿAbbās's teaching, two different narrations on two different pages) confirmed by reading both hadith fetches directly — they are in fact different narrations, not a shared page split two ways | verified |
| 4 | **TRADED on the verse beat (noun, not finite verb), recovered in Arabic in full on the duʿā beat** (`ضَرٍّ`) | confirmed |
| 5 | **The genuinely hard bar in this batch, and the deck's own self-assessment is honest and correct.** The 74-occurrence sweep confirms Allah is finite subject of `ḍ-r-r` in exactly 2 places, both Hellfire-for-disbelief clauses (2:126, 31:24), and both are confirmed rendered on no beat. Beat 2 (the bare Name, `الضَّارُّ`/"The Distresser," with no gloss) is a real, undefended exposure for however long it takes a reader to reach beat 3 — the deck names this itself rather than hiding it, and I have no additional finding beyond what the deck already discloses. **I read all eight beats as a person in acute distress, per the brief's instruction, and my own read matches the deck's:** no beat states or implies Allah caused *this specific* hardship; beat 6 (6:17) is the one place Allah and *ḍurr* share a clause, and it is trimmed to pure exclusivity-of-relief with no causal or desert claim attached. The risk is real but is a register judgment call, not a factual defect | independently re-read; converges with the deck's own "Read as a user at 11pm" section |

### An-Nafi (`an-nafi@1`, id 96)

| bar | verdict | evidence |
|---|---|---|
| 1 | **MET, traded onto `kataba`** | Tirmidhī 2516's `كَتَبَهُ اللَّهُ` — Allah explicit named subject of "written," inside the Prophet's ﷺ own reported teaching, symmetrically for both benefit and harm clauses |
| 2 | **PASS** | Shown through a specific named teaching to a specific companion and a concrete list (2:164's ships/rain), not an abstract claim |
| 3 | **PASS**, twin-diff confirmed (different narrator, different scene, different narration from Ad-Darr) | verified |
| 4 | **TRADED on the story/verse (subject = "the whole creation," not Allah), recovered in Arabic in full on the duʿā** (`عِلْمًا نَافِعًا`) | confirmed |
| 5 | **PASS** | 2:163/2:165 clean, one correctly disclosed non-blocking successor (2:165's punishment clause, addressee-shifted to third-person idolaters) |
| — | **The proposed pin is sound. I rule the rasm-identical/not-byte-identical difference does NOT block the pin.** The ship gate (`name_stories_ship_gate_test.dart` lines 279–309) compares the deck's `arabic` field against `collectible_names.json`'s `dua_arabic` — both local, both already byte-identical by construction — and separately checks that `b['source']` equals the literal string in `renderedDuaSources`. **The gate never compares either string against sunnah.com's fetched HTML at all.** The tanwīn-ordering difference is a genuine and useful provenance finding (worth recording, and the drafter is right to flag it), but it describes a mismatch between the catalogue string and the *source webpage's own inconsistent encoding* (the same page orders the mark differently for the first three tanwīn-fatḥa words than for the last two) — not a mismatch the gate's byte-equality check would ever see or care about. A rasm-identical match — same letters, same pronunciation, same meaning, differing only in a combining-mark storage order that the source page itself is inconsistent about — is sufficient grounds for a citation. **PIN APPROVED**: `'an-nafi@1': "Sunan Ibn Majah 925"` | independently traced to the gate's actual assertion, not assumed |

---

## 3 · Bar 3(b), measured

Every deck's own claimed count (**45 decks**, `assets/content/name_stories.json`) is correct — I ran
`len(json.load(...))` directly: **45**. I did not re-run each deck's full 45-deck/771-string n-gram
sweep myself (that is a mechanical pass over hundreds of strings I could not fully re-derive in this
session's budget), but every *specific* collision claim I spot-checked (al-fattah@1's 35:2 split,
al-khaliq@1's "Creator," al-aleem@1's "Originator," al-qabid@1's disjoint scripture, al-majeed@1's
11:73 spend, al-ghaniyy@1's 35:15–17) was independently confirmed true against the shipped/drafted
JSON, not merely trusted from the table.

---

## 4 · Hadith grade lines — quoted as printed on the page

- **Sunan Ibn Majah 4023** (Ad-Darr, beats 3–5): *"Grade: **Hasan** (Darussalam)"*
- **Jami' at-Tirmidhi 2396** (Ad-Darr, beat 5): *"Grade: **Hasan** (Darussalam)"*; at-Tirmidhī's own note on the page: *"هَذَا حَدِيثٌ حَسَنٌ غَرِيبٌ مِنْ هَذَا الْوَجْهِ"* ("this is a ḥasan gharīb ḥadīth from this route")
- **Sunan Ibn Majah 925** (An-Nafi, beat 7, proposed pin): *"Grade: **Sahih** (Darussalam)"*
- **Jami' at-Tirmidhi 2516** (An-Nafi, beats 3–5): *"Grade: **Hasan** (Darussalam)"*; at-Tirmidhī's own note: *"هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ"* ("this is a ḥasan ṣaḥīḥ ḥadīth")

No weak or fabricated narration reaches any beat in this batch. The one narration explicitly checked
and rejected for weakness (An-Nafi's "best of people are those most beneficial" candidate) was
correctly excluded and never rendered.

---

## 5 · Ship / no-ship verdict per deck

| deck | verdict | what would fix it, if anything |
|---|---|---|
| **Al-Wahid** | **SHIP** | None required. Strongest-verified deck in the batch; every root count and every cited āyah independently reconfirmed |
| **Al-Ahad** | **SHIP, with one flag for the founder** | The bar-4 total-trade should be stated plainly in the deck's own bar-4 row ("traded, and recovers nowhere on this deck, not even the shared duʿā, whose recovered root belongs to the sibling") rather than the current unqualified "traded." Content is correct; the self-report understates its own weakest point |
| **Al-Hameed** | **SHIP, with one flag for the founder** | Bar 2 is thin — a doubled declaration, not a parable or counterfactual. I would not block on this alone (the doubling across "this world"/"the Hereafter" is a real, if modest, argument), but a founder reviewing bar-2 quality across the batch should know this is the weakest case, not read the deck's own "PASS" as equivalent-strength to Al-Wahid's or Ad-Darr's |
| **Ash-Shakur** | **SHIP** | None required. Closest bar-1 call in the batch (trailing-pair-epithet shape) but genuinely earns the pass on the same-sentence test; everything else is clean and independently confirmed |
| **Al-Mani** | **SHIP** | Missing `reflection` beat — correctly left unauthored per the drafter's own stated conflict-of-interest reasoning; the founder or a different agent should author one before this ships, matching `DRAFTING-BRIEF.md` §5a |
| **Ad-Darr** | **SHIP ONLY PAIRED WITH An-Nafi, AND ONLY AFTER THE PAIRING IS ENFORCED (or the takeaway's forward-reference is softened).** Content itself clears all five bars, including the hardest register bar in the project, on the strength of a genuinely exhaustive root sweep. But: (a) missing `reflection` beat; (b) **the ship gate has no mechanism to prevent this deck rendering alone** — confirmed by reading the gate source directly. A reader who draws Ad-Darr without ever having drawn/unlocked An-Nafi reads a takeaway that says *"An-Nafi — the second Name of your answer — is why that One has no equal"*-style forward pointer to a card they may never have seen, on a deck whose own analysis states it "structurally cannot resolve into relief" on its own material. This is the single highest-stakes instance of the unenforced-pairing gap in the whole catalogue, because unlike Al-Qabid/Al-Basit or Al-Khafid/Ar-Rafi (where the unpaired Name alone is still comfortable), Ad-Darr alone is the one deck in the project explicitly designed to require its partner to land safely | Either (1) add engineering enforcement to `NameStoriesService.deckForName` / the ship gate before either 95 or 96 ships, or (2) if shipping ahead of that engineering work, rewrite beat 8 so it does not depend on the reader having access to An-Nafi |
| **An-Nafi** | **SHIP, alongside Ad-Darr, same pairing caveat applies in reverse (weaker)** | Missing `reflection` beat. The duʿā pin is sound (see bar-4/bar-1 row above) — recommend approving `'an-nafi@1': "Sunan Ibn Majah 925"` in `renderedDuaSources` |

---

## 6 · What I could not verify

1. **I did not re-run the full 45-deck/771-string n-gram sweep for any of the seven decks.** I
   spot-checked roughly a dozen of the specific collision claims each deck makes (see §3) and found
   all of them accurate, but I did not independently regenerate the complete token-frequency tables.
   A collision the drafter's own sweep missed would not be caught by my spot-checks.
2. **I did not exhaustively re-verify every individual entry of the larger root sweeps** (و-ح-د's 30
   non-compact `wāḥid` occurrences, أ-ح-د's 74 `aḥad` occurrences beyond the two divine-sense hits,
   ش-ك-ر's 75, ح-م-د's 63, ن-ف-ع's 50, ض-ر-ر's 74) word-by-word against the corpus's own per-entry
   glosses. I confirmed every root's **headline total and form breakdown** against `corpus.quran.com`
   directly (all matched exactly, no discrepancies), and I independently fetched every specific āyah
   cited from each sweep's "notable occurrences" list, but I did not read all several hundred
   individual concordance entries the way the traded-bar4 batch's verifier did for As-Sabur.
3. **I did not audit any isnād.** Every grade I report is the printed grade line on the sunnah.com
   page, as instructed — I did not independently assess chain reliability.
4. **I did not consult a tafsīr** on any of the seven decks' bar-1/bar-2 readings. My rulings on
   6:100–102's "shown, not stated" status, on 35:30's epithet-vs-demonstration question, and on
   34:1's doubled-declaration question are my own reading of the plain text against this project's
   stated bars, not a claim about how classical exegesis categorises any of these passages.
5. **I did not fetch Bukhari 5641/5642** (Ad-Darr's rejected/held-in-reserve candidate,
   sickness-expiates-sin) since it is used on no beat — I took the drafter's summary of its content
   on trust, since nothing in this batch's verdict depends on it.
6. **I did not check whether `al-ghaniyy@1` (id 92) or `al-mumeet@1`, `al-muizz@1`/`al-muzill@1`,
   or any deck outside this batch's seven have their own unenforced "must-ship-together" status** —
   I confirmed the pattern for the four pairs the drafts themselves name (Ad-Darr/An-Nafi,
   Al-Qabid/Al-Basit, Al-Khafid/Ar-Rafi) but did not independently search the whole catalogue for
   others.
7. **The Al-Wahid/Al-Ahad forward-reference risk (beat 8 naming the sibling by name) is my own
   finding, added beyond the brief's checklist** — I have not checked whether the founder considers
   this pair "must-ship-together" in the same binding sense as Ad-Darr/An-Nafi (plan §7a.1's
   language), or merely "should be reviewed together." The drafts themselves only claim the latter,
   softer standard, so I have ranked this a lower-severity version of the same gap, not an equal one.

---

## 7 · Reconciliation with `2026-08-04-R2-VERIFICATION.md`

**Where I agree, in full:**

- R2's hadith-grade table for this batch (Ibn Majah 4023, Tirmidhi 2396, Tirmidhi 2516, Ibn Majah
  925, all Hasan/Sahih Darussalam) matches exactly what I independently re-fetched — including the
  specific detail that Ad-Darr's drafter found and disclosed the second, unused narration on the
  Tirmidhi 2396 page rather than hiding it. R2 calls this one of two hadith disclosures in the whole
  54-deck wave that "undercut their own deck," and I confirm it is accurate and the omission from
  Ad-Darr's actual beats is real, not merely claimed.
- R2's §2.1/§2.2 fix to `al-majeed@1`'s misquoted 11:73 beat is confirmed already applied in the
  current draft I read — the beat now correctly renders 11:73's own closing clause, and the file's
  own R2 note documents the fix rather than hiding that it was needed. This matters directly to this
  batch because Al-Hameed's own draft depends on `al-majeed@1`'s 11:73 citation being real and
  correctly cited — it is.
- R2's §5 list of 19 decks missing a `reflection` beat includes `al-mani`, `ad-darr`, and `an-nafi` —
  matches my own finding exactly (Al-Wahid, Al-Ahad, Al-Hameed, Ash-Shakur all have one; the
  withholding/harm/benefit cluster does not).
- R2's §6 note that "0 of 54 decks put a `source`, an āyah citation, or a single Arabic codepoint in
  a `bridge` or `reflection` slot" holds for all seven decks in this batch — I checked every bridge
  and reflection beat in all seven drafts directly and confirm none carries `source` or `arabic`.

**Where I disagree, or go further than R2:**

- **R2 does not flag the pair-enforcement gap for Ad-Darr/An-Nafi at all.** R2's scope is source
  fidelity, narration authenticity, and story impact — it explicitly disclaims ("Not reliable") any
  judgment on bar-1 ladder questions, bar-3(c) engine arguments, and bar-5 register calls, and the
  ship-gate engineering gap falls outside even that broader scope. This is the single most
  consequential finding in my review of this batch and it is absent from R2 entirely. I would put it
  above every other item in this reconciliation: **Ad-Darr should not ship standalone, and nothing
  in the current pipeline — not the ship gate, not R2's pass, not `deckForName`'s runtime behaviour —
  stops it from doing so.**
- **R2 treats Al-Ahad's bar-4 trade as settled** (it is listed only under the wave's general
  "already right" summary, not flagged as a specific risk). I rank it CONTESTED-but-disclosed rather
  than a clean pass, on the grounds that the deck's own bar-4 row says "traded" without stating the
  trade is *total and unrecovered even in the shared duʿā* — a materially different, weaker claim
  than Al-Wahid's, Al-Mani's, Ad-Darr's, or An-Nafi's partial trades, all of which recover the root
  somewhere on-screen. R2 does flag `al-majeed@1`'s bar-1 (angelic speech) as the wave's hardest
  open question needing a blind verifier — I agree that is the single hardest bar-1 call in the
  54-deck wave, but within *this* batch specifically, Al-Ahad's bar-4 and Al-Hameed's bar-2 are the
  comparable soft spots, and R2 does not single either out.
- **R2's §4 "where a blind verifier should go first" list does not mention this batch's decks at
  all** (it names `al-majeed@1`, `al-muhaymin@1`, `as-sabur@1`, `ar-rasheed@1`, `al-hakam@1`, and the
  judgment-four group). Having now done the blind pass R2 says this batch still owes, I would add:
  Ash-Shakur's bar-1 (trailing-pair-epithet shape, argued here to pass but genuinely contestable) and
  the Ad-Darr/An-Nafi pairing gap, which is not a bar question at all but is the most consequential
  finding in the batch.
- **On everything source-fidelity-related, I have nothing to add beyond independent confirmation.**
  R2's own honest framing — "reliable for source fidelity, not reliable for bar-1/3(c)/5 judgment,
  because the reviewer authored most of the wave" — is, in my independent assessment, an accurate
  self-description. The source fidelity holds up completely under a second, independent set of
  fetches; the judgment calls are where a genuinely blind read adds anything, and the two items above
  (the pairing gap and the two soft bars) are what that read turned up.
