# Catalogue `hadith` repair — fix report

**Date:** 2026-08-03
**Repairs against:** [`2026-08-03-CATALOGUE-HADITH-AUDIT.md`](./2026-08-03-CATALOGUE-HADITH-AUDIT.md)
**Database status:** **NOTHING WAS APPLIED.** Not one row. The change is staged at
`supabase/staged/fix_catalog_hadith_2026_08_03.sql` for the founder to apply.

---

## 0. The standard applied

> **Ṣaḥīḥ narrations only. Prefer Ṣaḥīḥ al-Bukhārī and Ṣaḥīḥ Muslim. A narration graded
> ḥasan is not sufficient. Removing the field is always a valid outcome and is strongly
> preferred over a weak citation.**

That standard is why this pass **empties 14 fields and replaces only 13**. Every replacement
below is Ṣaḥīḥayn. No Tirmidhī, no Abū Dāwūd, no Ibn Mājah, no tafsīr, no scholar's saying,
no article was used as a substitute anywhere.

Nothing here was recalled. Every quotation was fetched, and the fetched text is reproduced in
§5 so a reviewer can disagree with any judgement without re-fetching.

---

## 1. Headline

| | Count |
|---|---|
| Names touched | **27** |
| Replaced with a fetched Ṣaḥīḥayn narration | **13** |
| **Emptied** (no ṣaḥīḥ narration verified for that Name) | **14** |
| Frame-corrected Qurʾān (divine speech was attributed to the Prophet ﷺ) | **2** (inside the 13) |
| Names in the audit's 56 **not** repaired, and why | **31** — see §6 |

**P0 — the fabrications — are done.**

- **id 45 As-Samīʿ**: the invented divine speech `Allah said: "I heard you — and here is the
  child, already named Yaḥyā."` is **gone from all four in-repo mirrors and from the staged
  SQL**. Nothing anywhere now puts authored words in Allah's mouth.
- **All 8 unlocatable prophetic quotations** (75, 77, 71, 94, 54, 56, 20, 45) are resolved:
  5 emptied, 3 replaced with a fetched Ṣaḥīḥ al-Bukhārī narration. The strings
  `(Derived from Names teachings)`, `(Yaqeen, …)` and the bare `(Hadith)` **no longer appear
  in the catalogue at all** (verified by grep across the asset, the Dart const, and the SQL).

---

## 2. (a) Names whose field was EMPTIED, and why

Emptied means `hadith` is set to `""` — an empty string, never `NULL`. The client contract
(`lib/services/public_catalog_contracts.dart:96`) requires the key to be non-null on all 99
rows, and the card UI's `hasTier2Content => hadith.isNotEmpty`
(`lib/services/card_collection_service.dart:125`) already degrades an empty value to the
existing **"Coming soon…"** state on all four card tiers. So an emptied Name renders as a
deliberate blank, not as a broken card.

| id | Name | What it said | Why it was emptied rather than replaced |
|---|---|---|---|
| **15** | Al-Ḥayy | *"Call upon Allah using 'Ya Ḥayyu Ya Qayyūm'…" (Tirmidhi)* | The only candidate is **Jāmiʿ at-Tirmidhī 3524, graded Ḥasan** — below the bar. See list (b). |
| **16** | Al-Qayyūm | *"The Prophet ﷺ said to Fāṭima…" (Al-Hakim)* | Same narration family as id 15 → same Ḥasan ceiling. The `(Al-Hakim)` citation has no volume, no number, no grade, and al-Mustadrak was unreachable to this pass as it was to the audit. |
| **20** | Al-Bāriʾ | *"You brought me out of nothingness into being." (Yaqeen, The Name I Need)* | Unlocatable. A modern content series quoted as prophetic speech. No ṣaḥīḥ narration demonstrating Al-Bāriʾ was found. |
| **43** | Al-Muʿizz | Athar of ʿUmar (RA), *(Al-Hakim)* | Not a prophetic narration; unnumbered, ungraded; al-Mustadrak unreachable. **Verbatim duplicate of 44.** |
| **44** | Al-Muzill | identical to 43 | Same. |
| **52** | Al-ʿAlī | *"Whoever humbles himself… Whoever exalts himself, Allah lowers him." (Muslim)* | Only the **first** clause is in Muslim 2588 (verified, §5). The audit proposed keeping that clause. **I rejected that**: the surviving clause is about the *servant* being raised, not about Allah's ʿuluww, and Muslim 2588 is **already carried verbatim by ids 41 and 42**. Trimming would have produced a third copy of a topically-inverted hadith. |
| **84** | Al-Mutaʿālī | identical to 52 | Same, and emptying breaks the 52/84 duplicate. |
| **54** | Al-Muqīt | *"Allah provides for every creature…" (Ibn Kathir, Tafsir of Quran 4:85)* | Unlocatable as a narration; a tafsīr is not a narration source. The one plausible ṣaḥīḥ substitute (Muslim 2577's "all of you are hungry except those I feed") is **already reused at ids 33, 47, 55 and 90** — a fifth copy is filler, not a repair. |
| **56** | Al-Jalīl | *"Fill your heart with reverence…" (Yaqeen, The Name I Need Day 06)* | Unlocatable. Modern content quoted as prophetic speech. |
| **71** | Al-Wājid | *"Allah is never at a loss for what you need." (Derived from Names teachings)* | Unlocatable, and the citation string itself admitted the words were authored. No ṣaḥīḥ narration demonstrates Al-Wājid. |
| **75** | Al-Qādir | *"Nothing is beyond the power of Allah." (Muslim)* | Unlocatable — zero hits in Muslim. See §3 for the substitute I found and deliberately did **not** use. |
| **82** | Al-Bāṭin | *"I never go to sleep without cleaning my heart…" (Ahmad)* | Musnad Aḥmad is not reachable in English in any corpus I could open, and the narration is not in the nine collections. Unnumbered, ungraded. Unverified is not a pass. |
| **85** | Al-Barr | *"Our Lord is Al-Barr, Al-Ghafūr," said upon completing Hajj. (Muslim 1342)* | Muslim 1342 is the duʿāʾ on **mounting for a journey**; the quoted phrase is in no collection. No ṣaḥīḥ substitute demonstrating Al-Barr was found. |
| **96** | An-Nāfiʿ | *"Ask Allah for benefit (nafʿ) in this world and the next." (Ibn Majah 3846)* | The quoted sentence is not in Ibn Mājah 3846 (which asks for *khayr*). The nearest ṣaḥīḥ candidate, **Muslim 2664** (*"be keen on what benefits you"*), is about the servant seeking benefit — it does not demonstrate **Allah** as An-Nāfiʿ. Stretching it would repeat exactly the id-64 mistake this pass is fixing. |

---

## 3. (b) Names where only a ḤASAN (or contested) candidate exists — FOR THE FOUNDER, NOT USED

These are listed so a decision can be made deliberately. **None of them was used.**

| id | Name | Candidate | Published grades |
|---|---|---|---|
| **15** | Al-Ḥayy | Jāmiʿ at-Tirmidhī 3524 — *"Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth"* | **Ḥasan** (al-Albānī; Zubair ʿAlī Zaʾī). Not ṣaḥīḥ. |
| **16** | Al-Qayyūm | same narration | same |
| **65** | Al-Ḥamīd | Jāmiʿ at-Tirmidhī 2466 — the qudsī *"devote yourself to My worship…"* | **Contested**: Ṣaḥīḥ (al-Albānī, Shākir) vs **Ḥasan** (Bashār ʿAwwād) vs **Isnād Ḥasan** (Zubair ʿAlī Zaʾī). Not used — id 65 got Ṣaḥīḥ Muslim 2734a instead. |
| **50** | Al-ʿAẓīm | Sunan Abī Dāwūd 869 — the audit's own proposal | **Ḍaʿīf** (al-Albānī; Muḥyī al-Dīn ʿAbd al-Ḥamīd); Isnād Ṣaḥīḥ (Zubair ʿAlī Zaʾī). **The audit proposed keeping it with the Ḍaʿīf grade stated. I rejected that** and used Ṣaḥīḥ Muslim 772. |
| **77** | Al-Muqaddim | Sunan Abī Dāwūd 1509 — the same duʿāʾ **with an English translation** | Ṣaḥīḥ (al-Albānī, ʿAbd al-Ḥamīd, al-Arnaʾūṭ, Zubair ʿAlī Zaʾī). Not used — Ṣaḥīḥ al-Bukhārī 6398 carries the same duʿāʾ and was preferred; see the caveat in §5. |
| **75** | Al-Qādir | Ṣaḥīḥ al-Bukhārī 6398 clause *"wa anta ʿalā kulli shayʾin qadīr"* | Ṣaḥīḥ. **Available and correct**, deliberately unused: it would be a third quotation of one duʿāʾ (already used at 77) and the founder's instruction makes deletion the default for Tier 1. **If the founder wants id 75 filled, this is the ready answer.** |

### Wider ḥasan exposure the founder should know about

The audit marked **43 entries CLEAN**, but "clean" there meant *the citation resolves*, not
*ṣaḥīḥ*. Under the standard now in force, a number of those CLEAN entries rest on narrations
whose highest published grade is **Ḥasan**, not Ṣaḥīḥ — including **id 89 (Dhul-Jalāli
wal-Ikrām, Tirmidhī 3524 — Ḥasan)** and **id 95 (Ad-Ḍārr, Tirmidhī 2396 — Ḥasan Ṣaḥīḥ per
al-Albānī, Ḍaʿīf per Zubair ʿAlī Zaʾī)**. **I did not re-grade all 43 CLEAN entries** — that was
not in scope and I did not have budget to do it properly. **It is the single largest piece of
unfinished work this report leaves behind**, and it is a bigger population than the 27 I fixed.

One further finding, offered because it bears on the whole product: **Jāmiʿ at-Tirmidhī 3507**,
the narration that carries the *enumerated list* of the ninety-nine Names, is graded **Ḍaʿīf by
al-Albānī, by Aḥmad Shākir, and by Zubair ʿAlī Zaʾī** (fetched this pass). The *existence* of
ninety-nine Names is Ṣaḥīḥayn (Bukhārī 7392 / Muslim 2677); the *specific list* is not. That is a
scholar's question, not mine, but a product built on the list should know it.

---

## 4. (c) Anything I could not verify

| Item | Status |
|---|---|
| **al-Ḥākim, *al-Mustadrak*** (ids 16, 43, 44) | **Unreachable.** Same as the audit. Those three were emptied rather than guessed at. |
| **Musnad Aḥmad** (id 82, and the Salmān al-Fārisī narration behind id 91) | **Unreachable in English** in any corpus I could open. Id 82 emptied. |
| **dorar.net** | Not attempted; the audit reports it Cloudflare-blocked. |
| **Every isnād** | **I audited none.** See §7. |
| **Whether the 43 "CLEAN" entries meet the ṣaḥīḥ-only bar** | **Not established.** See §3. |
| **The staged SQL against a live database** | **Not executed.** By instruction, nothing was applied, so the script is reviewed but not run. Its drift guard is untested against real rows. |

---

## 5. Per-Name detail — the 13 replacements

Format: **what it said → what it says now**, the exact URL fetched, the fetched text, and the
verifier's verdict.

### id 5 — Al-Quddūs
- **Was:** `The angels glorify Him saying: "Holy, Holy, Holy is the Lord of the angels and the spirit." (Muslim)`
- **Now:** `'A'isha (RA) reported that the Prophet ﷺ used to say while bowing and prostrating: "All Glorious, All Holy, Lord of the Angels and the Spirit." Al-Quddus is holy beyond every flaw the mind could imagine. (Sahih Muslim 487a — Sahih)`
- **Fetched:** `http://web.archive.org/web/20260306075857/https://sunnah.com/muslim/4/253`
  → reference line reads *"Sahih Muslim 487a"*; text: *"'A'isha reported that the Messenger of Allah (ﷺ) used to pronounce while bowing and prostrating himself: All Glorious, All Holy, Lord of the Angels and the Spirit."*
- **Collection / number / grade:** Ṣaḥīḥ Muslim 487a — Ṣaḥīḥ.
- **Defect corrected:** the words were attributed to **the angels**; they are **the Prophet's ﷺ**.
  The triple *"Holy, Holy, Holy"* is not in the narration (the Arabic is two distinct words,
  *Subbūḥ* and *Quddūs*); it has been removed. The card's own `dua_arabic` already carried the
  correct Arabic, which is why the error was invisible.

### id 8 — Al-ʿAzīz *(Qurʾān, frame fix)*
- **Was:** `The Prophet ﷺ said: "Might belongs to Allah, His Messenger, and the believers." (Quran 63:8)`
- **Now:** `Allah says: "And to Allah belongs [all] honor, and to His Messenger, and to the believers." Al-Azeez is the source of every might that is real. (Quran 63:8)`
- **Fetched:** `https://api.quran.com/api/v4/verses/by_key/63:8?fields=text_uthmani&translations=20`
  → *"…And to Allāh belongs [all] honor, and to His Messenger, and to the believers, but the hypocrites do not know."*
- **Defect corrected:** divine speech was framed as prophetic speech. The quotation is now the
  Ṣaḥīḥ International text verbatim rather than a loose rendering. This is a **frame fix on
  correct Qurʾān**, not a rewrite of Qurʾān into ḥadīth.

### id 14 — Al-ʿAlīm
- **Was:** `The Prophet ﷺ said: "Allah knew what His servants would do, and He wrote it all fifty thousand years before creating the heavens and the earth." (Muslim)`
- **Now:** `The Prophet ﷺ said: "Allah ordained the measures of the creation fifty thousand years before He created the heavens and the earth, as His Throne was upon water." Al-Aleem knew it all before it happened. (Sahih Muslim 2653 — Sahih)`
- **Fetched:** `eng-muslim.json` (fawazahmed0/hadith-api), hadith 6749 — the legacy USC number the audit maps to Ṣaḥīḥ Muslim 2653 — *"Allah ordained the measures (of quality) of the creation fifty thousand years before He created the heavens and the earth, as His Throne was upon water."* The Wayback capture of `sunnah.com/muslim:2653` resolves to the **2653a** variant-chain page, which carries no independent text.
- **Elision disclosed:** the translator's parenthetical **"(of quality)"** is dropped. Nothing else.
- **Defect corrected:** the clause *"Allah knew what His servants would do, and He wrote it all"*
  sat **inside the quotation marks** and is not in the narration. It is gone; the interpretive
  sentence now sits outside the quotation.

### id 19 — Al-Mutakabbir
- **Was:** `The Prophet ﷺ said: "Greatness is My cloak and pride is My garment. Whoever competes with Me in either, I will throw into the Fire." (Muslim)`
- **Now:** `In a hadith qudsi, the Prophet ﷺ reported that Allah said: "Glory is His lower garment and Majesty is His cloak; he who contends with Me in regard to them, I shall torment him." Greatness belongs to Al-Mutakabbir alone. (Sahih Muslim 2620 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/muslim:2620` → *"Allah, the Exalted and Glorious, said: Glory is His lower garment and Majesty is His cloak and (Allah says,) He who contends with Me in regard to them I shall torment him."*
- **Defect corrected:** the ending *"I will throw into the Fire"* is **not Muslim's wording**; it
  is Sunan Abī Dāwūd 4090's. Sahihayn authority had been attached to non-Sahihayn wording.
  First-person divine speech now carries an explicit **hadith qudsi** marker.

### id 35 — Al-Wakīl
- **Was:** `Ibrahim (AS), when thrown into the fire, said: "Hasbunallah wa ni'mal Wakeel." Allah commanded the fire: "Be cool and safe for Ibrahim." (Quran 3:173)`
- **Now:** `Ibn 'Abbas (RA) said: "'Allah is Sufficient for us and He is the Best Disposer of affairs' was said by Ibrahim when he was thrown into the fire, and it was said by Muhammad ﷺ when they said: 'A great army is gathering against you, therefore fear them.'" Al-Wakeel is the One you hand the outcome to. (Sahih al-Bukhari 4563 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/bukhari:4563` → Narrated Ibn ʿAbbās, text as quoted.
- **Defect corrected:** Qurʾān 3:173 is **the believers at Ḥamrāʾ al-Asad**, not Ibrāhīm; and
  *"Be cool and safe"* is **21:69**, not 3:173. One citation had been attached to two claims it
  does not support. The Ibrāhīm attribution is now sourced where it actually lives — as
  **Ibn ʿAbbās's own statement (mawqūf) recorded in Ṣaḥīḥ al-Bukhārī**, which the card now says
  explicitly rather than presenting as the Prophet's ﷺ speech.

### id 45 — As-Samīʿ ***(P0 — the fabricated divine speech)***
- **Was:** `Zakariyya (AS) made a silent call in the corner of the masjid. Before he could finish, Allah said: "I heard you — and here is the child, already named Yahya." (Quran 19:3-7)`
- **Now:** `When the companions raised their voices in dhikr on a journey, the Prophet ﷺ said: "O people! Be merciful to yourselves, for you are not calling a deaf or an absent one, but One Who is with you; no doubt He is All-Hearer, ever Near." As-Sami hears the call you never said aloud. (Sahih al-Bukhari 2992 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/bukhari:2992` (Abū Mūsā al-Ashʿarī) → *"We were in the company of Allah's Messenger (ﷺ) (during Hajj). Whenever we went up a high place we used to say: 'None has the right to be worshipped but Allah, and Allah is Greater,' and our voices used to rise, so the Prophet (ﷺ) said, 'O people! Be merciful to yourselves (i.e. don't raise your voice), for you are not calling a deaf or an absent one, but One Who is with you, no doubt He is All-Hearer, ever Near (to all things).'"*
- **Elision disclosed:** the translator's aside *"(i.e. don't raise your voice)"* and the trailing
  *"(to all things)"* are dropped. The framing sentence "raised their voices in dhikr on a
  journey" is the card's own words, outside the quotation, and is supported by the narration.
- **Defect corrected:** the sentence in quotation marks attributed to **Allah** does not exist.
  19:7 reads *"[He was told], 'O Zechariah, indeed We give you good tidings of a boy whose name
  will be John…'"* (fetched). The replacement is Ṣaḥīḥayn and contains the Name itself —
  *innahu Samīʿun Qarīb*.

### id 50 — Al-ʿAẓīm
- **Was:** `When Surah Al-A'la was revealed, the Prophet ﷺ said: "Make this in your sujud." In our deepest prostration we declare His highest. (Abu Dawud)`
- **Now:** `Hudhayfah (RA) prayed a night prayer with the Prophet ﷺ and reported that he would bow and say: "Glory be to my Mighty Lord." In ruku' the servant names Al-Azeem. (Sahih Muslim 772 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/muslim:772` (Ḥudhayfah) → *"…and would then bow and say: Glory be to my Mighty Lord … He would then prostrate himself and say: Glory be to my Lord most High…"*
- **I did not follow the audit's proposal.** The audit suggested keeping **Sunan Abī Dāwūd 869
  with its Ḍaʿīf grade stated**. Ḍaʿīf fails the standard. Independent corroboration for the
  swap: `eng-abudawud.json` shows **Abū Dāwūd 869 graded Ḍaʿīf** (al-Albānī; ʿAbd al-Ḥamīd)
  while **Abū Dāwūd 871 (Ḥudhayfah) is Ṣaḥīḥ**, and Zubair ʿAlī Zaʾī annotates 871 as
  *"Sahih Muslim (772)"* — the exact locus used here.
- **Defect corrected:** the card had been given **Al-Aʿlā's prostration half** and glossed it
  *"we declare His highest"*, which is Al-Aʿlā's meaning, not Al-ʿAẓīm's. It now carries the
  **rukūʿ** half, which is Al-ʿAẓīm's.

### id 63 — Al-Matīn
- **Was:** `The Prophet ﷺ said: "Shall I not teach you a treasure from beneath the throne? La hawla wa la quwwata illa billah." (Bukhari & Muslim)`
- **Now:** `The Prophet ﷺ said: "Shall I tell you a word which is one of the treasures of Paradise? It is: La hawla wa la quwwata illa billah." All strength is borrowed from Al-Mateen. (Sahih al-Bukhari 6384 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/bukhari:6384` → *"…Or he said, 'Shall I tell you a word which is one of the treasures of Paradise? It is: La haul a wala quwwata illa bil-lah.'"*
- **Transliteration normalisation disclosed:** sunnah.com renders the Arabic
  لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ as *"La haul a wala quwwata illa bil-lah"*. The card writes
  *"La hawla wa la quwwata illa billah"*. That is a normalisation of a transliteration against
  the fetched Arabic, not a change to the text.
- **Defect corrected:** *"from beneath the throne"* is in neither Ṣaḥīḥ. Ṣaḥīḥayn authority had
  been attached to wording that does not exist there.

### id 64 — Al-Waliyy
- **Was:** `The Prophet ﷺ said: "Be in this world as if you are a stranger or a wayfarer." Your only consistent companion is Al-Wali. (Bukhari)`
- **Now:** `In a hadith qudsi, the Prophet ﷺ reported that Allah said: "I will declare war against him who shows hostility to a pious worshipper of Mine… and if he asks Me, I will give him, and if he asks My protection, I will protect him." Al-Waliyy is the ally who never withdraws. (Sahih al-Bukhari 6502 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/bukhari:6502` → text as quoted, with an elision
  marked by `…` over the intervening *"…and the most beloved things with which My slave comes
  nearer to Me…"* section.
- **I did not follow the audit's proposal.** The audit suggested **Qurʾān 2:257**. That would have
  put another Qurʾān verse into the `hadith` field — the exact categorical defect §6 reports.
  Bukhārī 6502 is the actual ḥadīth of *wilāya* and is Ṣaḥīḥayn.
- **Defect corrected:** Bukhārī 6416 is real but is about **detachment from the world**; it says
  nothing about *wilāya*.

### id 65 — Al-Ḥamīd
- **Was:** `In a Hadith Qudsi: "O child of Adam, devote yourself to My worship, and I will fill your heart with richness." The more you praise a blessing, the more fulfilling it becomes. (Muslim)`
- **Now:** `The Prophet ﷺ said: "Allah is pleased with His servant who says: Al-Hamdu lillah while taking a morsel of food and while drinking." Al-Hameed is praised in the smallest mouthful. (Sahih Muslim 2734a — Sahih)`
- **Fetched:** `http://web.archive.org/web/20260214094552/https://sunnah.com/muslim/48/123`
  → reference line *"Sahih Muslim 2734a"*; text: *"Anas b. Malik reported that Allah's Messenger (ﷺ) said: Allah is pleased with His servant who says: Al-Hamdu lillah while taking a morsel of food and while drinking."*
- **I did not follow the audit's proposal.** The audit suggested re-citing the old qudsī to
  **Tirmidhī 2466 (Ṣaḥīḥ)**. Two reasons to reject: its grade is **contested** (Ḥasan per Bashār
  ʿAwwād, Isnād Ḥasan per Zubair ʿAlī Zaʾī — see §3), and the audit itself noted the narration is
  about **worship and sufficiency**, not **ḥamd**, so it does not demonstrate Al-Ḥamīd.
  Muslim 2734a is Ṣaḥīḥ and is directly about *ḥamd*.
- **Confirmed independently:** the old qudsī returns **zero occurrences in Ṣaḥīḥ Muslim** — the
  `(Muslim)` tag was false.

### id 66 — Al-Muḥṣī *(Qurʾān, frame fix)*
- **Was:** `The Prophet ﷺ said: "Not a leaf falls but that He knows it. There is no grain in the darkness of the earth, nor anything moist or dry, but that it is written in a clear record." …(Quran 6:59)`
- **Now:** `Allah says: "Not a leaf falls but that He knows it. And no grain is there within the darknesses of the earth and no moist or dry [thing] but that it is [written] in a clear record." Al-Muhsi has numbered every tear. (Quran 6:59)`
- **Fetched:** `https://api.quran.com/api/v4/verses/by_key/6:59?fields=text_uthmani&translations=20`
- **Defect corrected:** divine speech framed as prophetic speech, and the quotation was a loose
  rendering rather than the translation it claimed. Both fixed. Again: **a frame fix on correct
  Qurʾān, not a rewrite into ḥadīth.**

### id 77 — Al-Muqaddim ***(P0)***
- **Was:** `The Prophet ﷺ said: "Your rizq chases you the way death chases you." What Al-Muqaddim advances is always on time. (Hadith)`
- **Now:** `The Prophet ﷺ used to invoke: "Allahumma ighfir li ma qaddamtu wa ma akhkhartu wa ma asrartu wa ma a'lantu. Anta-l-muqaddimu wa anta-l-mu'akhkhiru, wa anta 'ala kulli shai'in qadir." Al-Muqaddim is named in the Prophet's own supplication — He brings forward whom He wills. (Sahih al-Bukhari 6398 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/bukhari:6398` (Abū Mūsā) → *"The Prophet (ﷺ) used to invoke Allah with the following invocation: 'Rabbi-ghfir-li Khati'ati wa jahli… Allahumma ighrifli ma qaddamtu wa ma akhartu wa ma asrartu wa ma a'lantu. Anta-l-muqaddimu wa anta-l-mu'akh-khiru, wa anta 'ala kulli shai'in qadir.'"*
- **Two disclosures, please read them:**
  1. **sunnah.com supplies no English for this duʿāʾ** — only a transliteration. I therefore
     quote the **transliteration**, and the card's own explanatory sentence sits **outside** the
     quotation marks. I did **not** author an English translation of it, because translating
     fetched scripture myself is the failure mode this whole pass exists to clean up.
  2. **Transliteration typos normalised:** sunnah.com prints *"ighrifli"* and *"akhartu"*. The
     card writes *"ighfir li"* and *"akhkhartu"*, normalised against the **Arabic on the same
     fetched page** (اللَّهُمَّ اغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ), and corroborated by Bukhārī 6317
     and Ibn Mājah 1355 which print the same duʿāʾ correctly.
- **If the founder prefers a card with English**, the same duʿāʾ is at **Sunan Abī Dāwūd 1509**
  with a full English translation (*"…You are the Advancer, the Delayer, there is no god but
  You"*) and a unanimous **Ṣaḥīḥ** grading from al-Albānī, ʿAbd al-Ḥamīd, al-Arnaʾūṭ and Zubair
  ʿAlī Zaʾī. I chose Bukhārī on the "prefer Ṣaḥīḥayn" instruction; this is a one-line swap.
- **Defect corrected:** the quoted sentence exists nowhere and the citation was the bare word
  `(Hadith)`.

### id 94 — Al-Māniʿ ***(P0)***
- **Was:** `The Prophet ﷺ said: "What Allah withholds is also His mercy." … (Derived from Names teachings)`
- **Now:** `The Prophet ﷺ used to say after every obligatory prayer: "Allahumma la mani'a lima a'tayta, wa la mu'tiya lima mana'ta — O Allah! Nobody can hold back what You gave, nobody can give what You held back." What Al-Mani withholds, no one can release. (Sahih al-Bukhari 844 — Sahih)`
- **Fetched:** Wayback of `https://sunnah.com/bukhari:844` (Warrād, clerk of al-Mughīra) → *"…the Prophet (ﷺ) used to say after every compulsory prayer, 'La ilaha illa l-lahu wahdahu la sharika lahu… Allahumma la mani`a lima a`taita, wa la mu`tiya lima mana`ta, wa la yanfa`u dhal-jaddi minka l-jadd. [There is no Deity but Allah, Alone, no Partner to Him. His is the Kingdom and all praise, and Omnipotent is he. O Allah! Nobody can hold back what you gave, nobody can give what You held back, and no struggler's effort can benefit against You].'"*
  Both the transliteration **and** the bracketed English are on the fetched page — nothing here
  is my translation.
- **Number differs from the audit's suggestion.** The audit pointed at
  `knowledge_base.dart:2819` citing **Bukhārī 6615**. I fetched and verified **Bukhārī 844**
  directly and cite that. (Both may carry it; 844 is the one I read.)
- **Defect corrected:** the quoted sentence exists nowhere, and the citation string itself
  admitted the words were authored while the sentence said the Prophet ﷺ said them.

---

## 6. What I did NOT repair, and why — the other 31 of the audit's 56

Being explicit, because a silent omission would read as clearance.

### 6.1 The 20 accurate Qurʾān entries — **left alone, deliberately**
ids **21, 22, 23, 26, 30, 34, 36, 57, 59, 67, 68, 69, 76, 83, 87, 88, 97, 98** (+ 8 and 66, which
I frame-fixed because those two *did* attribute divine speech to the Prophet ﷺ).

**These are not a truth problem and I did not rewrite them.** Every verse was fetched and
confirmed accurate by the audit. **This is a field-naming problem and it should be fixed in the
schema, not the content:**

- The column is `hadith`. A third of the catalogue uses it as a generic "source text" slot.
- Worse, and not noted in the audit: **the card UI hard-codes the label `PROPHETIC TEACHING`
  above this field** — at `lib/features/collection/screens/collection_screen.dart:1523`,
  `widgets/gold_ornate_card.dart:580`, `widgets/emerald_ornate_card.dart`, and
  `widgets/bronze_ornate_card.dart`. So **20 accurate Qurʾān āyāt are being shown to users under
  a heading that says they are prophetic narration.** Renaming the column does not fix that on
  its own; the label has to change too.
- **I did not edit those files.** Wave H is editing under `lib/features/` concurrently. This is
  flagged, not touched — per instruction.
- Recommended shape: add a `source_kind` (`quran` | `hadith` | `athar` | `authored`) and drive
  the label from it. That is a schema change, not a content change, and it is cheap.
- Minor, left alone: **id 83** introduces 7:196 with "Allah says" though the verse is the
  Prophet's speech (*"Say: Indeed my protector is Allah…"*). Rewriting it risks introducing an
  error to fix a hair; reported instead.

### 6.2 The 11 "unfalsifiable" entries — **reported, not rewritten**
ids **40, 46** (`(Ibn Mas'ud)` — a narrator's name used as a citation), **73, 74, 91**
(`(Seerah)` — a genre), **48** (Ibn Taymiyyah, no work, no page), **49** (al-Ghazālī, uncited),
**53, 58** (al-Ghazālī / "the scholars say"), **60, 78** (no citation of any kind).

**None of these puts an invented sentence in the Prophet's ﷺ mouth** — they are honestly
attributed to a scholar, a genre, or nobody. Under the instruction *"only fix the ones where the
label lies about what the text is,"* they are out of scope for this pass. Two of them are
nonetheless real content bugs and should be scheduled:

- **id 49 (Al-Khabīr)** carries **a definition of Al-Laṭīf**. Confirmed: the same al-Ghazālī
  gloss appears correctly placed under **Al-Laṭīf** at `knowledge_base.dart:404`. Wrong Name.
- **id 40 (Ar-Raqīb)** opens by describing **Al-Baṣīr**, and is a near-duplicate of id 46.

### 6.3 Duplicates left standing
The audit counted nine shared texts. This pass removed three duplicate pairs (43=44, 52=84 both
emptied; 45 and 63 no longer share the Abū Mūsā hadith's clauses with anything). Still standing
and **not repaired**: **24=25**, **26=36**, **40≈46**, **41≈42**, **73=74**, **92≈93**, and Muslim
2577 at **33, 47, 55, 90**. Each is accurate; the defect is that they read as filler.

---

## 7. Method, and its limits — read this before treating anything above as clearance

**What I did.**
- **Qurʾān:** every verse fetched live from `api.quran.com/api/v4`, translation id 20 (Ṣaḥīḥ
  International). No verse recalled.
- **Ḥadīth:** every claim fetched. Two reads per citation wherever possible — (1) the **Wayback
  capture of the exact sunnah.com URL** (sunnah.com 403s automation), and (2) the
  `fawazahmed0/hadith-api` English editions, which carry the published grade lines from
  al-Albānī, Aḥmad Shākir, Zubair ʿAlī Zaʾī, Shuʿayb al-Arnaʾūṭ, Bashār ʿAwwād and Muḥammad Fuʾād
  ʿAbd al-Bāqī.
- **I composed no narration, no isnād, and no translation of scripture.** Where sunnah.com gave
  only a transliteration (id 77), I quoted the transliteration rather than author an English
  rendering.
- **Adversarial verification:** two independent subagents that had not seen my reasoning were
  spawned and instructed to **refute**, to re-fetch every citation themselves, and to default to
  reject when they could not confirm. Their verdicts are in §8.

**Limits.**
1. **I reached no corpus independent of sunnah.com.** The hadith-api editions derive from the
   same underlying sunnah.com data, and the Wayback captures *are* sunnah.com. This is **one
   corpus read twice, not two corpora agreeing** — exactly the limit the audit declared, and it
   is still true of me. A scholar with a printed Fatḥ al-Bārī would be doing something I did not.
2. **I audited no isnād. Not one.** Every grade in this report is a **published ruling read off
   an edition**, not a judgement I made or checked.
3. **Three sources stayed out of reach:** al-Ḥākim's *al-Mustadrak*, *Musnad Aḥmad* in English,
   and dorar.net. Ids 16, 43, 44 and 82 were emptied on that basis. **Emptying them is a
   decision made under ignorance, not a finding that the narrations are false.**
4. **"Zero hits" is a strong signal, not a proof of non-existence.** A narration living only in
   al-Bayhaqī, al-Ṭabarānī, Aḥmad or a tafsīr would not have surfaced.
5. **English translations differ.** Every elision, transliteration normalisation and added
   framing sentence is disclosed inline in §5 so a reviewer can overrule any of them.
6. **The 43 entries the audit called CLEAN were not re-graded against the ṣaḥīḥ-only bar.**
   See §3. This is the largest known gap.
7. **The staged SQL has never been executed.** Its drift guard is reasoned, not proven.

---

## 8. Adversarial verifiers' verdicts

*(Filled in from the two refutation subagents — see §8.1/§8.2 below.)*

---

## 9. Mirrors — what was written where

The audit's mirror map was **checked, and it is wrong in one place.**

| # | Location | Status |
|---|---|---|
| 1 | `assets/content/collectible_names.json` | **Updated.** 27 `hadith` values; diff is exactly 27 lines, no other field touched, formatting preserved. |
| 2 | `lib/services/card_collection_service.dart` (`allCollectibleNames`) | **Updated.** Verified byte-identical to the asset for all 99 values by parsing the Dart const list (a naive substring check falsely reports 13 diffs because of Dart `\'` escaping — that is what makes this mirror easy to get wrong). **`dart format` was deliberately NOT run**: this repo is not formatted with the Dart 3.11 tall-style formatter, and running it rewrites ~90 unrelated lines. |
| 3 | Supabase `public.collectible_names.hadith` | **STAGED ONLY, NOT APPLIED** → `supabase/staged/fix_catalog_hadith_2026_08_03.sql`. |
| 4 | `lib/core/constants/knowledge_base.dart` | **Updated — but the audit's description of it is incorrect.** It contains **zero verbatim copies** of the catalogue `hadith` strings. What it holds are *paraphrases embedded in `coreTeaching` / `propheticStory` prose*, which is fed straight into the AI prompt (`ai_service.dart:730-731`). Three defects fixed there: the Ḍaʿīf *"Make this in your sujud"* (Abū Dāwūd 869) — **twice**, at lines 772 and 862; the audit found only one — replaced with the Ṣaḥīḥ Muslim 772 locus. The conflated *"Whoever exalts himself, Allah lowers him"* clause — trimmed to the verified Muslim 2588 wording with its citation. The unverifiable ʿUmar athar (ids 43/44) — removed. **4 lines changed.** |
| 5 | `tool/export_public_catalog_snapshots.dart` / `import_…` | **No change needed, verified.** The exporter writes `JsonEncoder.withIndent('  ')` + trailing newline, which is byte-for-byte the format the asset was written in here, so a post-apply re-export is a no-op diff. The SQL footer tells the founder to run it. |

`lib/services/public_catalog_contracts.dart` still passes: all 99 rows keep a non-null `hadith`.

---

## 10. Verification run

- `flutter analyze` — see §10 of the accompanying hand-off note for exact counts.
- `flutter test` — see §10 of the accompanying hand-off note for exact counts.

---

*Repairs performed 2026-08-03. **No database row was modified.** Nothing was committed.*
