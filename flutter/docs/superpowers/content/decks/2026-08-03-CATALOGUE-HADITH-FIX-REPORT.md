# Catalogue `hadith` repair — fix report

**Date:** 2026-08-03
**Repairs against:** [`2026-08-03-CATALOGUE-HADITH-AUDIT.md`](./2026-08-03-CATALOGUE-HADITH-AUDIT.md)
**Database status:** **NOTHING WAS APPLIED.** Not one row. The change is staged at
`supabase/staged/fix_catalog_hadith_2026_08_03.sql` for the founder to apply.
**Nothing was committed.**

---

## 0. The standard applied

> **Ṣaḥīḥ narrations only. Prefer Ṣaḥīḥ al-Bukhārī and Ṣaḥīḥ Muslim. A narration graded
> ḥasan is not sufficient. Removing the field is always a valid outcome and is strongly
> preferred over a weak citation.**

That standard is why this pass **empties 14 fields and replaces only 13**. Every replacement is
Ṣaḥīḥayn — no Tirmidhī, no Abū Dāwūd, no Ibn Mājah, no tafsīr, no scholar's saying, no article
was used as a substitute anywhere.

Nothing here was recalled. Every quotation was fetched, and the fetched text is reproduced in §5
so a reviewer can overrule any judgement without re-fetching.

---

## 1. Headline

| | Count |
|---|---|
| Names touched in the catalogue | **27** |
| Replaced with a fetched Ṣaḥīḥayn narration | **13** |
| **Emptied** (no ṣaḥīḥ narration verified for that Name) | **14** |
| Qurʾān frame-corrections (divine speech had been attributed to the Prophet ﷺ) | **2** (inside the 13) |
| Separate defects fixed in `knowledge_base.dart` | **5** |
| Names in the audit's 56 **not** repaired, and why | **29** — see §6 |

### P0 status

**P0 is complete for the catalogue column and for the one `knowledge_base.dart` fabrication
found so far. It is NOT complete for `knowledge_base.dart` as a whole — see §4 and the coverage
statement in §8.3.**

- **id 45 As-Samīʿ, the invented divine speech** — `Allah said: "I heard you — and here is the
  child, already named Yahya."` — is gone from the asset, the Dart const, and the staged SQL.
- **It also existed a second time, in `knowledge_base.dart`**, in the As-Samīʿ `propheticStory`
  (`Allah cut him off: 'I heard you — and here is the child you were asking for, already named
  Yahya.'`). **I missed it on my first pass; the coordinator caught it.** That file is injected
  verbatim into the AI prompt (`ai_service.dart:730-731`), so the model was being handed
  fabricated divine speech as source material. It is now removed and Qurʾān 19:7 is quoted
  verbatim in its place. `grep "already named Yahya"` across all three in-repo mirrors returns
  **0**.
- **All 8 unlocatable prophetic quotations** (75, 77, 71, 94, 54, 56, 20, 45) are resolved:
  5 emptied, 3 replaced with a fetched Ṣaḥīḥ al-Bukhārī narration.
- The citation strings `(Derived from Names teachings)`, `(Yaqeen, …)` and the bare `(Hadith)`
  **no longer appear in the catalogue at all** (grep-verified across the asset and the Dart const).

### What the adversarial verification actually caught

Two independent subagents that had not seen my reasoning were instructed to **refute** and to
default to reject. **This step earned its keep four times:**

1. **id 14 was REJECTED.** I cited "Ṣaḥīḥ Muslim 2653". The bare number a reader would look up,
   `sunnah.com/muslim:2653`, resolves to **2653a** — a chain-repetition of the Ādam/Mūsā debate
   containing none of the quoted words. The text is at **2653b**. The verifier also judged the
   Name-fit weakest in the batch (the narration says Allah *wrote/ordained*, so "knew it all
   before it happened" was **my inference**). I did not take the one-character fix; I moved the
   Name to **Ṣaḥīḥ al-Bukhārī 4697** ("the keys of the Unseen are five which none knows but
   Allah"), which is direct prophetic speech about Allah's *knowledge* and cures both objections.
2. **id 63 was blocked.** Bukhārī 6384 carries the clause under the narrator's *shakk*
   (`Or he said` / `أَوْ قَالَ`). My draft silently flattened a doubted variant into direct speech.
   Re-cited to **Bukhārī 6610**, where it is undoubted.
3. **The audit's id-94 proposal was REFUTED.** The audit said the ḥadīth is at Bukhārī 6615, not
   844. Both carry it and **844 is the right one** — only 844 reads *"after every compulsory
   prayer"* (`فِي دُبُرِ كُلِّ صَلاَةٍ مَكْتُوبَةٍ`), which is exactly what the framing needs.
4. **id 35 is *mawqūf***, not marfūʿ — the isnād ends at Ibn ʿAbbās. The grade now says so
   explicitly so no reader takes it for prophetic speech.

**A standing lesson worth keeping:** the check that caught #1 was fetching the **bare cited
number**, not the convenient in-book URL. `muslim:2653` and `muslim:2653b` are different pages.
Every citation in this report was re-verified at the exact string a reader would type.

**Three of the audit's own proposals were rejected on fetched evidence** — ids 50, 64 and 65,
detailed in §5. Combined with #3 above, that is four audit recommendations that would have
changed catalogue data incorrectly.

---

## 2. (a) Names whose field was EMPTIED, and why

Emptied means `hadith = ""` — an empty string, never `NULL`. The client contract
(`lib/services/public_catalog_contracts.dart:96`) requires the key non-null on all 99 rows, and
`hasTier2Content => hadith.isNotEmpty` (`lib/services/card_collection_service.dart:125`) already
degrades an empty value to the existing **"Coming soon…"** state on all four card tiers. An
emptied Name renders as a deliberate blank, not a broken card.

| id | Name | What it said | Why emptied rather than replaced |
|---|---|---|---|
| **15** | Al-Ḥayy | *"Call upon Allah using 'Ya Ḥayyu Ya Qayyūm'…" (Tirmidhi)* | **The grade is CONTESTED, not settled — read §3.1 before accepting this deletion.** I applied the more conservative reading. Also independently defective: the old card converted a narration about the Prophet's ﷺ *own practice* into a direct imperative in quotation marks. |
| **16** | Al-Qayyūm | *"The Prophet ﷺ said to Fāṭima…" (Al-Hakim)* | **Same contested grade — see §3.1.** Additionally, `(Al-Hakim)` as shipped has no volume, no number and no grade, and al-Mustadrak was unreachable to me, to the audit, and to the deck agent. |
| **20** | Al-Bāriʾ | *"You brought me out of nothingness into being." (Yaqeen, The Name I Need)* | Unlocatable. A modern content series quoted as prophetic speech. |
| **43** | Al-Muʿizz | Athar of ʿUmar (RA), *(Al-Hakim)* | Not prophetic; unnumbered, ungraded; al-Mustadrak unreachable. **Verbatim duplicate of 44.** |
| **44** | Al-Muzill | identical to 43 | Same. |
| **52** | Al-ʿAlī | *"Whoever humbles himself… Whoever exalts himself, Allah lowers him." (Muslim)* | Only the **first** clause is in Muslim 2588 (verified). The audit proposed keeping it. **I rejected that**: the surviving clause is about the *servant* being raised, not Allah's ʿuluww, and Muslim 2588 is **already carried verbatim at ids 41 and 42** — trimming would have made a third copy of a topically-inverted ḥadīth. |
| **84** | Al-Mutaʿālī | identical to 52 | Same, and emptying breaks the 52/84 duplicate. |
| **54** | Al-Muqīt | *"Allah provides for every creature…" (Ibn Kathir, Tafsir of Quran 4:85)* | Unlocatable as a narration; a tafsīr is not a narration source. The one plausible ṣaḥīḥ substitute (Muslim 2577) is **already reused at ids 33, 47, 55 and 90** — a fifth copy is filler, not a repair. |
| **56** | Al-Jalīl | *"Fill your heart with reverence…" (Yaqeen … Day 06)* | Unlocatable. Modern content quoted as prophetic speech. |
| **71** | Al-Wājid | *"Allah is never at a loss for what you need." (Derived from Names teachings)* | Unlocatable; the citation string itself admitted the words were authored. |
| **75** | Al-Qādir | *"Nothing is beyond the power of Allah." (Muslim)* | Unlocatable — zero hits in Muslim. A correct ṣaḥīḥ substitute exists and was deliberately not used; see §3. |
| **82** | Al-Bāṭin | *"I never go to sleep without cleaning my heart…" (Ahmad)* | Musnad Aḥmad unreachable in English; not in the nine collections; unnumbered, ungraded. |
| **85** | Al-Barr | *"Our Lord is Al-Barr, Al-Ghafūr," said upon completing Hajj. (Muslim 1342)* | Muslim 1342 is the duʿāʾ on **mounting for a journey**; the quoted phrase is in no collection. No ṣaḥīḥ substitute found. |
| **96** | An-Nāfiʿ | *"Ask Allah for benefit (nafʿ) in this world and the next." (Ibn Majah 3846)* | The sentence is not in Ibn Mājah 3846 (which asks for *khayr*). The nearest ṣaḥīḥ candidate, Muslim 2664, is about the **servant** seeking benefit — it does not demonstrate **Allah** as An-Nāfiʿ. Stretching it would repeat the id-64 mistake this pass is fixing. |

---

## 3. (b) Names where only a ḤASAN (or contested, or otherwise unusable) candidate exists

**None of these was used.** Listed so the founder can decide deliberately.

| id | Name | Candidate | Published grades |
|---|---|---|---|
| **15** | Al-Ḥayy | Tirmidhī 3524 — *"Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth"* (first clause only) | **Ḥasan (Darussalam)**; Tirmidhī himself: *gharīb*. **But this is only one route — see §3.1.** |
| **16** | Al-Qayyūm | the **full** duʿā, via a different route: al-Nasāʾī *ʿAmal al-Yawm wa'l-Layla* 570; al-Ḥākim *Mustadrak*; al-Bazzār | **CONTESTED — see §3.1.** |
| **65** | Al-Ḥamīd | Tirmidhī 2466 — the qudsī *"devote yourself to My worship…"* | **Contested**: Ṣaḥīḥ (al-Albānī, Shākir) vs **Ḥasan** (Bashār ʿAwwād, Darussalam) vs *Isnād Ḥasan* (Zubair ʿAlī Zaʾī). Not used. |
| **50** | Al-ʿAẓīm | Abū Dāwūd 869 — **the audit's own proposal** | **Ḍaʿīf** (al-Albānī; ʿAbd al-Ḥamīd). The audit proposed shipping it *with the Ḍaʿīf grade stated*; rejected. |
| **77** | Al-Muqaddim | Abū Dāwūd 1509 — the same duʿāʾ **with an English translation** | Ṣaḥīḥ (al-Albānī, ʿAbd al-Ḥamīd, al-Arnaʾūṭ, Zubair ʿAlī Zaʾī). Not used; see the §5 caveat — this is a one-line swap if the founder wants English on that card. |
| **75** | Al-Qādir | Bukhārī 6398's clause *"wa anta ʿalā kulli shayʾin qadīr"* | Ṣaḥīḥ. **Available and correct**, deliberately unused: it would be a third quotation of one duʿāʾ, and deletion is the Tier-1 default. **Ready if wanted.** |
| **63** | Al-Matīn | Bukhārī 6384 | Ṣaḥīḥ, but the clause sits under the narrator's *shakk*. Superseded by Bukhārī 6610, which is undoubted. |
| **14** | Al-ʿAlīm | Muslim 2653**b** | Ṣaḥīḥ, and correct if cited with the `b`. Not used because it is about *ordaining* (`كتب`), not knowing. Bukhārī 4697 used instead. |

### 3.1 ids 15 (Al-Ḥayy) and 16 (Al-Qayyūm) — a CONTESTED grade, and three options

**Correction to an earlier draft of this report, which described these as simply "ḥasan". They
are not. The grade is a live disagreement among muḥaddithūn, and the founder is entitled to see
both sides.** A concurrent agent on the deck track independently re-verified this and its finding
is incorporated here.

**Two different routes are involved, and they are not the same narration:**

| Route | Carries | Grade |
|---|---|---|
| **Jāmiʿ at-Tirmidhī 3524** (Anas) | **Only the first clause** — *"Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth"*. That clause is id 15's entire duʿā and an exact prefix of id 16's. | **Ḥasan** (Darussalam; al-Albānī; Zubair ʿAlī Zaʾī). Tirmidhī himself: a bare *gharīb* — notably **not** the *ḥasan gharīb* he uses at 2466. Fetched and confirmed by my verifier. |
| **al-Nasāʾī, *ʿAmal al-Yawm wa'l-Layla* 570; al-Ḥākim, *Mustadrak*; al-Bazzār** (Anas → the Prophet ﷺ, to Fāṭima) | **The full duʿā**, i.e. the whole id-16 string. The deck agent checked it skeleton-identical to the catalogue's, character for character, programmatically. | **CONTESTED.** **Ṣaḥīḥ** per **al-Ḥākim**; **isnād ṣaḥīḥ** per **al-Mundhirī**. **Ḥasan** per **Ibn Ḥajar** and **al-Albānī**. |

**Which side I applied, and why.** I applied the **ḥasan** reading — the more conservative one —
and emptied both fields. Under a strict ṣaḥīḥ-only bar, deferring to the stricter grading is the
safe default, and al-Ḥākim's *Mustadrak* is the classic locus of over-lenient authentication, so
his ṣaḥīḥ alone would not carry it. **But "two major authorities grade it ṣaḥīḥ" is materially
different from "it is ḥasan", and I should not present my choice as though the question were
settled.** It is not.

**A caveat that weakens the ṣaḥīḥ side specifically:** neither I, nor the audit, nor the deck
agent could reach **al-Ḥākim's *Mustadrak* as a primary text**, and the page reference itself is
disputed in the secondary literature (**1/545 vs 1/730**). So the ṣaḥīḥ grading rests on
**secondary scholarship pages, not on a primary read.** The ḥasan side (al-Albānī on Tirmidhī
3524) I fetched directly.

**The three options, for the founder to choose between — I have applied option A only because it
is the reversible one, not because it is obviously right:**

- **A. Leave both empty** *(what is currently staged)*. Safest under a strict ṣaḥīḥ-only bar.
  Cost: two Names show "Coming soon…". Fully reversible.
- **B. Restore the narration** with an honest, contested grade line, e.g.
  `(al-Nasa'i, 'Amal al-Yawm wa'l-Layla 570 — graded Sahih by al-Hakim and al-Mundhiri, Hasan by Ibn Hajar and al-Albani)`.
  This is the only option that keeps the narration the Names actually belong to. It requires
  accepting a contested grade, and — separately from the grade — **the old id-15 wording must
  still be fixed**: it converted the Prophet's ﷺ own practice into a direct imperative in
  quotation marks, which is a defect independent of authenticity.
- **C. Use the Qurʾānic anchor** — **2:255, Āyat al-Kursī**: *"Allāh — there is no deity except
  Him, the Ever-Living, the Self-Sustaining."* Both Names in one clause, in the most-recited verse
  in the Qurʾān, and **it requires no grading at all**. If the contested grade resolves toward
  ṣaḥīḥ, this becomes a preference rather than a necessity.

**I am deliberately not choosing between B and C.** Both are defensible; the choice is the
founder's.

### Wider ḥasan exposure — the largest thing this report leaves unfinished

The audit marked **43 entries CLEAN**, but "clean" there meant *the citation resolves*, not
*ṣaḥīḥ*. Under the standard now in force, several of those rest on narrations whose highest
published grade is **Ḥasan** — including **id 89 (Dhul-Jalāli wal-Ikrām, Tirmidhī 3524 — the very
narration being rejected at ids 15/16)** and **id 95 (Aḍ-Ḍārr, Tirmidhī 2396 — Ḥasan Ṣaḥīḥ per
al-Albānī, Ḍaʿīf per Zubair ʿAlī Zaʾī)**. **I did not re-grade the 43 CLEAN entries.** That
population is larger than the 27 I fixed, and id 89 is a direct inconsistency: the same
narration is being deleted at 15/16 and kept at 89.

One further finding, because it bears on the whole product: **Jāmiʿ at-Tirmidhī 3507**, the
narration carrying the *enumerated list* of the ninety-nine Names, is graded **Ḍaʿīf by
al-Albānī, by Aḥmad Shākir, and by Zubair ʿAlī Zaʾī** (fetched this pass). The *existence* of
ninety-nine Names is Ṣaḥīḥayn (Bukhārī 7392 / Muslim 2677); the *specific list* is not. That is a
scholar's question, not mine — but a product built on the list should know it.

---

## 4. (c) Anything I could not verify

| Item | Status |
|---|---|
| **al-Ḥākim, *al-Mustadrak*** (ids 16, 43, 44) | **Unreachable.** Emptied rather than guessed at. |
| **Musnad Aḥmad** (id 82; also the Salmān al-Fārisī narration behind id 91) | **Unreachable in English** in any corpus I could open. |
| **dorar.net** | Not attempted; the audit reports it Cloudflare-blocked. |
| **Every isnād** | **I audited none.** See §8. |
| **Whether the 43 "CLEAN" entries meet the ṣaḥīḥ-only bar** | **Not established.** See §3. |
| **`knowledge_base.dart` prose beyond the entries I reached** | **Not established.** See §8.3 — this is an open P0 surface. |
| **The staged SQL against a live database** | **Not executed.** No PostgreSQL server was available in this environment (libpq client tools only). The drift guard is reasoned, not proven. |

**Say this plainly: ids 16, 43, 44 and 82 were emptied under ignorance, not on a finding that
the narrations are false.** A scholar with access to al-Mustadrak and Musnad Aḥmad may well be
able to restore them.

---

## 5. Per-Name detail — the 13 replacements

Every citation below was verified at the **bare number** a reader would look up. Every partial
quotation carries a **visible ellipsis in the rendered string**. Translator parentheticals are
reproduced rather than silently dropped.

### id 5 — Al-Quddūs · **verifier: CONFIRMED**
- **Was:** `The angels glorify Him saying: "Holy, Holy, Holy is the Lord of the angels and the spirit." (Muslim)`
- **Now:** `'A'isha (RA) reported that the Prophet ﷺ used to say while bowing and prostrating: "All Glorious, All Holy, Lord of the Angels and the Spirit." Al-Quddus is holy beyond every flaw the mind could imagine. (Sahih Muslim 487a — Sahih)`
- **Fetched:** `https://sunnah.com/muslim:487a` (Wayback `20260210003623`), corroborated at `/muslim/4/253`.
- **Fetched text:** *"'A'isha reported that the Messenger of Allah (may peace he upon him) used to pronounce while bowing and prostrating himself: All Glorious, All Holy, Lord of the Angels and the Spirit."* Arabic: `أَنَّ رَسُولَ اللَّهِ ﷺ كَانَ يَقُولُ فِي رُكُوعِهِ وَسُجُودِهِ "سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلاَئِكَةِ وَالرُّوحِ"`
- **Grade:** Ṣaḥīḥ Muslim 487a — Ṣaḥīḥ. Quotation is 100% verbatim, no elision.
- **Defects corrected:** attributed to **the angels**; they are **the Prophet's ﷺ** own words in
  rukūʿ and sujūd — the verifier calls the Arabic unambiguous, the angels appearing only as the
  genitive object. And the triple **"Holy, Holy, Holy"** has, per the verifier's search of all
  six books, **zero basis anywhere** — it is the Isaiah/Trisagion cadence, not this ḥadīth.

### id 8 — Al-ʿAzīz *(Qurʾān, frame fix)* · **verifier: CONFIRMED**
- **Was:** `The Prophet ﷺ said: "Might belongs to Allah, His Messenger, and the believers." (Quran 63:8)`
- **Now:** `Allah says: "…And to Allah belongs [all] honor, and to His Messenger, and to the believers…" Al-Azeez is the source of every might that is real. (Quran 63:8)`
- **Fetched:** `https://api.quran.com/api/v4/verses/by_key/63:8?…&translations=20` — verifier confirmed by programmatic exact-substring match.
- **Disclosures:** the leading and trailing **ellipses are now rendered** (the verse continues
  *", but the hypocrites do not know."*). Ṣaḥīḥ International prints **`Allāh`** with a macron;
  the card writes `Allah` to match the rest of the catalogue.
- **Defect corrected:** the verifier calls this *"a category error of the most serious kind in
  this domain — divine speech demoted to prophetic speech."* It also grepped Ṣaḥīḥ Muslim for
  "Might belongs to Allah" — **zero hits**, so it was not even a ḥadīth paraphrase; it was the
  āyah restyled as prophetic speech. **This is a frame fix on correct Qurʾān, not a rewrite of
  Qurʾān into ḥadīth.**

### id 14 — Al-ʿAlīm · **verifier REJECTED my first attempt; re-anchored**
- **Was:** `The Prophet ﷺ said: "Allah knew what His servants would do, and He wrote it all fifty thousand years before creating the heavens and the earth." (Muslim)`
- **First attempt (REJECTED):** Ṣaḥīḥ Muslim 2653. The bare number resolves to **2653a**, which
  contains none of the words; and the narration is about *ordaining*, so the gloss was my
  inference.
- **Now:** `The Prophet ﷺ said: "The keys of Unseen are five which none knows but Allah: None knows what will happen tomorrow but Allah; none knows what is in the wombs (a male child or a female) but Allah; none knows when it will rain but Allah; none knows at what place one will die; none knows when the Hour will be established but Allah." Al-Aleem alone holds what no one else can reach. (Sahih al-Bukhari 4697 — Sahih)`
- **Fetched:** `https://sunnah.com/bukhari:4697` (Wayback `20260314173812`), Ibn ʿUmar. Text as
  quoted, **verbatim, no elision**, direct prophetic speech, no *shakk*.
- **Why this and not Muslim 2653b:** 4697's predicate is Allah's **knowledge** (`لا يعلمها إلا الله`),
  which is what Al-ʿAlīm means. No overlap with id 66, which quotes 6:59's *second* half.
- **Defect corrected:** the clause *"Allah knew what His servants would do, and He wrote it all"*
  sat **inside the quotation marks** and is in no narration.

### id 19 — Al-Mutakabbir · **verifier: CONFIRMED** *(best Name-fit in the batch)*
- **Was:** `The Prophet ﷺ said: "Greatness is My cloak and pride is My garment. Whoever competes with Me in either, I will throw into the Fire." (Muslim)`
- **Now:** `In a hadith qudsi, the Prophet ﷺ reported that Allah said: "Glory is His lower garment and Majesty is His cloak and (Allah says,) He who contends with Me in regard to them I shall torment him." Greatness belongs to Al-Mutakabbir alone. (Sahih Muslim 2620 — Sahih)`
- **Fetched:** `https://sunnah.com/muslim:2620` (Wayback). Arabic: `الْعِزُّ إِزَارُهُ وَالْكِبْرِيَاءُ رِدَاؤُهُ فَمَنْ يُنَازِعُنِي عَذَّبْتُهُ`
- **Disclosure:** the translator's `(Allah says,)` is now **restored inside the quotation**
  rather than silently elided, per the verifier's recommendation.
- **Defect corrected:** *"I will throw into the Fire"* is **not in Muslim 2620** (which ends
  `عَذَّبْتُهُ`, "I shall torment him"). The verifier grepped all 7,563 Muslim ḥadīth for "throw into
  the Fire" — **zero hits**. That ending is **Abū Dāwūd 4090** (`قَذَفْتُهُ فِي النَّارِ`), which *also
  inverts the garments*. **The old card was a two-collection conflation cited wholly to Muslim.**
  First-person divine speech now carries an explicit *ḥadīth qudsī* marker.

### id 35 — Al-Wakīl · **verifier: CONFIRMED, mawqūf**
- **Was:** `Ibrahim (AS), when thrown into the fire, said: "Hasbunallah wa ni'mal Wakeel." Allah commanded the fire: "Be cool and safe for Ibrahim." (Quran 3:173)`
- **Now:** `Ibn 'Abbas (RA) said: "'Allah is Sufficient for us and He is the Best Disposer of affairs' was said by Abraham [Ibrahim] when he was thrown into the fire; and it was said by Muhammad ﷺ when they (i.e. hypocrites) said, 'A great army is gathering against you, therefore, fear them,' but it only increased their faith…" Al-Wakeel is the One you hand the outcome to. (Sahih al-Bukhari 4563 — Sahih; mawquf — these are Ibn 'Abbas's words, not the Prophet's ﷺ)`
- **Fetched:** `https://sunnah.com/bukhari:4563` (Wayback).
- **Disclosures:** the source reads **"Abraham"**, kept, with **`[Ibrahim]` bracketed in** rather
  than silently substituted; `(i.e. hypocrites)` restored so "they" has an antecedent; the tail
  is truncated with a **visible ellipsis**.
- **Defect corrected:** Qurʾān 3:173 is **the believers at Ḥamrāʾ al-Asad**, not Ibrāhīm; and
  *"Be cool and safe"* is **21:69**, not 3:173. One citation had been attached to two claims it
  does not support. The grade now states **mawqūf** so no reader takes it as prophetic speech.

### id 45 — As-Samīʿ ***(P0 — the fabricated divine speech)*** · **verifier: CONFIRMED**
- **Was:** `Zakariyya (AS) made a silent call in the corner of the masjid. Before he could finish, Allah said: "I heard you — and here is the child, already named Yahya." (Quran 19:3-7)`
- **Now:** `When the companions raised their voices in dhikr on a journey, the Prophet ﷺ said: "O people! Be merciful to yourselves (i.e. don't raise your voice), for you are not calling a deaf or an absent one, but One Who is with you, no doubt He is All-Hearer, ever Near (to all things)." As-Sami hears the call you never said aloud. (Sahih al-Bukhari 2992 — Sahih)`
- **Fetched:** `https://sunnah.com/bukhari:2992` (Wayback `20250312100442`), Abū Mūsā al-Ashʿarī.
  Arabic ends `إِنَّهُ سَمِيعٌ قَرِيبٌ` — the Name itself.
- **Disclosure:** both translator parentheticals **restored**; the quotation is now fully
  verbatim with no elision. The framing sentence is the card's own words, outside the quotation,
  and is supported by the narration ("our voices used to rise").
- **Defect corrected:** the sentence in quotation marks attributed to **Allah** exists nowhere.
  Qurʾān 19:7, fetched: *"[He was told], 'O Zechariah, indeed We give you good tidings of a boy
  whose name will be John. We have not assigned to any before [this] name.'"*

### id 50 — Al-ʿAẓīm · **verifier: CONFIRMED**
- **Was:** `When Surah Al-A'la was revealed, the Prophet ﷺ said: "Make this in your sujud." … (Abu Dawud)`
- **Now:** `Hudhayfah (RA) prayed a night prayer with the Prophet ﷺ and reported that he would bow and say: "Glory be to my Mighty Lord." In ruku' the servant names Al-Azeem. (Sahih Muslim 772 — Sahih)`
- **Fetched:** `https://sunnah.com/muslim:772` (Wayback). Arabic decisive:
  `ثُمَّ رَكَعَ … "سُبْحَانَ رَبِّيَ الْعَظِيمِ"` / `ثُمَّ سَجَدَ … "سُبْحَانَ رَبِّيَ الأَعْلَى"`.
- **I did not follow the audit's proposal.** It suggested keeping **Abū Dāwūd 869 with its
  Ḍaʿīf grade stated**. Ḍaʿīf fails the standard. Corroboration for the swap: Abū Dāwūd **871**
  (Ḥudhayfah, same pairing) is **Ṣaḥīḥ**, and Zubair ʿAlī Zaʾī annotates it *"Sahih Muslim (772)"*
  — the exact locus used here. Abū Dāwūd 874 agrees.
- **Defect corrected — a double defect:** the card had been given **Al-Aʿlā's prostration half**
  and glossed *"we declare His highest"*, which is Al-Aʿlā's meaning; and the weak narration it
  cited **itself assigns "mighty Lord" to bowing**, so the card contradicted even its own source.

### id 63 — Al-Matīn · **verifier BLOCKED my first attempt; re-cited**
- **Was:** `The Prophet ﷺ said: "Shall I not teach you a treasure from beneath the throne? La hawla wa la quwwata illa billah." (Bukhari & Muslim)`
- **First attempt (BLOCKED):** Bukhārī 6384 — where the clause sits under the narrator's *shakk*,
  `Or he said` (`أَوْ قَالَ`). My draft silently converted a doubted variant into flat direct speech.
- **Now:** `The Prophet ﷺ said: "O 'Abdullah bin Qais! Shall I teach you a sentence which is from the treasures of Paradise? (It is): La hawla wa la quwwata illa billah — there is neither might nor power except with Allah." All strength is Allah's alone. (Sahih al-Bukhari 6610 — Sahih)`
- **Fetched:** `https://sunnah.com/bukhari:6610` (Wayback `20260315043934`) — *"The Prophet ﷺ then
  said, 'O ʿAbdullah bin Qais! Shall I teach you a sentence which is from the treasures of
  Paradise? (It is): La haula wala quwata illa billah. (There is neither might nor power except
  with Allah).'"* **No shakk.** Independently undoubted also at Bukhārī 4205.
- **Disclosure:** the transliteration is normalised to `La hawla wa la quwwata illa billah`
  against the fetched Arabic `لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ`.
- **⚠ Name-fit caveat, flagged by the verifier:** **the Name Al-Matīn does not occur in this
  narration at all.** The link runs through *quwwah*. I judged it a genuine demonstration (the
  ḥadīth's whole claim is that all power is Allah's) and kept it — **but under the ṣaḥīḥ-only
  standard an empty field is an equally acceptable outcome here, and the founder may prefer it.**
- **Defect corrected:** *"from beneath the throne"* is in neither Ṣaḥīḥ; Ṣaḥīḥayn authority had
  been attached to wording that does not exist there.

### id 64 — Al-Waliyy · **verifier: CONFIRMED**
- **Was:** `The Prophet ﷺ said: "Be in this world as if you are a stranger or a wayfarer." … (Bukhari)`
- **Now:** `In a hadith qudsi, the Prophet ﷺ reported that Allah said: "I will declare war against him who shows hostility to a pious worshipper of Mine… and if he asks Me, I will give him, and if he asks My protection (Refuge), I will protect him." Al-Waliyy is the ally who never withdraws. (Sahih al-Bukhari 6502 — Sahih)`
- **Fetched:** `https://sunnah.com/bukhari:6502` (Wayback). Mid-quote elision carries a **visible
  ellipsis**; `(Refuge)` restored.
- **I did not follow the audit's proposal.** It suggested **Qurʾān 2:257** — which would push
  another Qurʾān verse into the `hadith` field, the exact categorical defect §6.1 reports.
  Bukhārī 6502 is the actual ḥadīth of *wilāya*.
- **Honest note on the Name-fit:** the word `وَلِيًّا` in this ḥadīth refers to the **human friend
  of Allah**, not the divine Name. The narration demonstrates Allah's *wilāya* **by content**
  (He declares war for His friend, gives when asked, protects when asked) — not by carrying the
  Name as a word.
- **Defect corrected:** Bukhārī 6416 is real but is about **detachment from the world**; it says
  nothing about *wilāya*.

### id 65 — Al-Ḥamīd · **verifier: CONFIRMED**
- **Was:** `In a Hadith Qudsi: "O child of Adam, devote yourself to My worship, and I will fill your heart with richness." … (Muslim)`
- **Now:** `The Prophet ﷺ said: "Allah is pleased with His servant who says: Al-Hamdu lillah while taking a morsel of food and while drinking." Al-Hameed is praised in the smallest mouthful. (Sahih Muslim 2734a — Sahih)`
- **Fetched:** `https://sunnah.com/muslim:2734a` (Wayback `20260219025048`), Anas b. Mālik.
  Arabic root `فَيَحْمَدَهُ` — the *ḥ-m-d* of Al-Ḥamīd. **100% verbatim, zero deviation.**
- **I did not follow the audit's proposal** (re-cite the old qudsī to Tirmidhī 2466 "Ṣaḥīḥ").
  Its grade is contested, and the audit itself noted the narration is about *worship*, not *ḥamd*.
- **The old card had three independent defects**, each fatal on its own, per the verifier:
  (1) **wrong collection** — the qudsī is in **neither Ṣaḥīḥ**, zero hits in Muslim and Bukhārī;
  (2) **below the grade bar** — Tirmidhī 2466 and Ibn Mājah 4107 are both **Ḥasan**;
  (3) **the wording matched neither source** — Ibn Mājah has "heart"+"contentment", Tirmidhī has
  "chest"+"riches"; the card blended the organ from one with the noun from the other. Ibn Mājah's
  chain also carries an explicit narrator hesitation about whether it is even *marfūʿ*.

### id 66 — Al-Muḥṣī *(Qurʾān, frame fix)* · **verifier: CONFIRMED — "cleanest item in the batch"**
- **Was:** `The Prophet ﷺ said: "Not a leaf falls but that He knows it. There is no grain in the darkness of the earth…" (Quran 6:59)`
- **Now:** `Allah says: "…Not a leaf falls but that He knows it. And no grain is there within the darknesses of the earth and no moist or dry [thing] but that it is [written] in a clear record." Al-Muhsi has numbered every tear. (Quran 6:59)`
- **Fetched:** `https://api.quran.com/api/v4/verses/by_key/6:59?…&translations=20` — verifier
  confirmed by programmatic exact-substring match, including both bracketed insertions and the
  unusual plural *darknesses*.
- **Disclosures:** a **leading ellipsis** now marks that this is the verse's second half.
  The gloss *"numbered every tear"* is **my image, not the verse's** — it sits outside the
  quotation marks and contradicts nothing, but it is extrapolation and is labelled as such here.
- **Defect corrected:** divine speech framed as prophetic speech, and the quotation was a loose
  rendering rather than the translation it claimed.

### id 77 — Al-Muqaddim ***(P0)*** · **verifier: CONFIRMED**
- **Was:** `The Prophet ﷺ said: "Your rizq chases you the way death chases you." … (Hadith)`
- **Now:** `The Prophet ﷺ used to invoke: "…Allahumma ighfir li ma qaddamtu wa ma akhkhartu wa ma asrartu wa ma a'lantu. Anta-l-muqaddimu wa anta-l-mu'akhkhiru, wa anta 'ala kulli shai'in qadir." Al-Muqaddim is named in the Prophet's own supplication — He brings forward whom He wills. (Sahih al-Bukhari 6398 — Sahih)`
- **Fetched:** `https://sunnah.com/bukhari:6398` (Wayback `20240524223210`), Abū Mūsā.
- **Three disclosures:**
  1. A **leading ellipsis** marks that the quotation starts mid-duʿāʾ.
  2. **sunnah.com supplies no English for this duʿāʾ — only a transliteration.** I therefore quote
     the transliteration and keep the card's explanatory sentence **outside** the quotation marks.
     I did **not** author an English translation, because translating fetched scripture myself is
     the failure mode this whole pass exists to clean up.
  3. **Transliteration typos normalised:** sunnah.com prints *"ighrifli"* and *"akhartu"*.
     Normalised against the **Arabic on the same page** (`اللَّهُمَّ اغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ`), and
     corroborated by Bukhārī 6317 and Ibn Mājah 1355 which print it correctly. **The verifier
     examined this specific question and ruled it acceptable, not a violation** — the page itself
     spells "ighfirli" correctly one clause earlier, so it is a typo, not a reading choice.
- **If the founder prefers English on this card:** the same duʿāʾ is at **Sunan Abī Dāwūd 1509**
  with a full translation (*"…You are the Advancer, the Delayer, there is no god but You"*) and a
  **unanimous Ṣaḥīḥ** grading from al-Albānī, ʿAbd al-Ḥamīd, al-Arnaʾūṭ and Zubair ʿAlī Zaʾī.
  One-line swap.

### id 94 — Al-Māniʿ ***(P0)*** · **verifier: CONFIRMED; audit REFUTED**
- **Was:** `The Prophet ﷺ said: "What Allah withholds is also His mercy." … (Derived from Names teachings)`
- **Now:** `The Prophet ﷺ used to say after every compulsory prayer: "…Allahumma la mani'a lima a'taita, wa la mu'tiya lima mana'ta… [O Allah! Nobody can hold back what you gave, nobody can give what You held back…]" What Al-Mani withholds, no one can release. (Sahih al-Bukhari 844 — Sahih)`
- **Fetched:** `https://sunnah.com/bukhari:844` (Wayback), Warrād (clerk of al-Mughīra). Both the
  transliteration **and** the bracketed English are printed on the page — **nothing here is my
  translation.** Leading and trailing ellipses mark the excerpt.
- **The audit's number is REFUTED.** It pointed at **Bukhārī 6615**. The verifier checked both:
  they both carry the duʿāʾ, but **only 844 says "after every compulsory prayer"**
  (`فِي دُبُرِ كُلِّ صَلاَةٍ مَكْتُوبَةٍ`), which is what the card's framing needs; 6615 says merely
  "after the prayer" with different English. **Switching to 6615 would have broken the card.**
  Also confirmed: **no 844a/b variant exists** — letter suffixes are a Muslim convention, not a
  Bukhārī one.
- **Defect corrected:** the quoted sentence exists nowhere, and the citation string itself
  admitted the words were authored while the sentence said the Prophet ﷺ said them.

---

## 6. What I did NOT repair, and why — the other 29 of the audit's 56

Being explicit, because a silent omission reads as clearance.

### 6.1 The 20 accurate Qurʾān entries — **left alone, deliberately**
ids **21, 22, 23, 26, 30, 34, 36, 57, 59, 67, 68, 69, 76, 83, 87, 88, 97, 98** (+ 8 and 66, which
I frame-fixed because those two *did* attribute divine speech to the Prophet ﷺ).

**These are not a truth problem and I did not rewrite them.** Every verse was fetched and
confirmed accurate by the audit. **This is a field-naming problem and it belongs in the schema:**

- The column is `hadith`. A third of the catalogue uses it as a generic "source text" slot.
- **Worse, and not noted in the audit: the card UI hard-codes the label `PROPHETIC TEACHING`
  above this field** — `lib/features/collection/screens/collection_screen.dart:1523`,
  `widgets/gold_ornate_card.dart:580`, `widgets/emerald_ornate_card.dart`,
  `widgets/bronze_ornate_card.dart`. **So 20 accurate Qurʾān āyāt are shown to users under a
  heading that says they are prophetic narration.** Renaming the column does not fix that; the
  label must change too.
- **I did not edit those files.** Wave H is editing under `lib/features/` concurrently. Flagged,
  not touched — per instruction.
- Recommended shape: a `source_kind` column (`quran` | `hadith` | `athar` | `authored`) driving
  the label. A schema change, not a content change, and cheap.
- Minor, left alone: **id 83** introduces 7:196 with "Allah says" though the verse is the
  Prophet's speech (*"Say: Indeed my protector is Allah…"*). Reported, not rewritten.

### 6.2 The 11 "unfalsifiable" entries — **reported, not rewritten**
ids **40, 46** (`(Ibn Mas'ud)` — a narrator's name as a citation), **73, 74, 91** (`(Seerah)` — a
genre), **48** (Ibn Taymiyyah, no work, no page), **49** (al-Ghazālī, uncited), **53, 58**
(al-Ghazālī / "the scholars say"), **60, 78** (no citation of any kind).

**None puts an invented sentence in the Prophet's ﷺ mouth** — each is honestly attributed to a
scholar, a genre, or nobody. Under *"only fix the ones where the label lies about what the text
is,"* they are out of scope. Two are nonetheless real content bugs and should be scheduled:

- **id 49 (Al-Khabīr)** carries **a definition of Al-Laṭīf**. Confirmed: the same al-Ghazālī gloss
  appears *correctly placed* under **Al-Laṭīf** at `knowledge_base.dart:404`. Wrong Name.
- **id 40 (Ar-Raqīb)** opens by describing **Al-Baṣīr**, and near-duplicates id 46.

### 6.3 `dua_arabic` — NOT touched, and a larger problem than the one I fixed
This pass repaired the **`hadith` column only**. It did not touch `dua_arabic`,
`dua_transliteration` or `dua_translation`, and it did not audit them. Flagged by the deck agent
and confirmed as out of scope: **duʿā duplication spans 14 duplicate groups across 30 of 99
Names** — a bigger structural defect than the ḥadīth duplication in §6.4. Surfaced for the
founder as its own decision; deliberately not started here.

### 6.4 Duplicates left standing
This pass removed three duplicate pairs (43=44 and 52=84 both emptied; 45 and 63 no longer share
clauses with anything). Still standing and **not repaired**: **24=25**, **26=36**, **40≈46**,
**41≈42**, **73=74**, **92≈93**, and Muslim 2577 at **33, 47, 55, 90**. Each is accurate; the
defect is that they read as filler.

---

## 7. PREPARED, NOT APPLIED — Qurʾānic anchors for emptied Names

The founder's call, put here with the āyāt actually fetched rather than described in the
abstract. **None of this has been applied to any file or to the database.**

The rule the 20 correct entries establish is: **Qurʾān is acceptable in this field when it is
labelled as Qurʾān and never introduced by "The Prophet ﷺ said".** Qurʾān is not a downgrade from
ṣaḥīḥ ḥadīth — it needs no grading at all. (This is why rejecting the audit's Qurʾān-2:257
proposal at id 64 was right *for that case*: a ṣaḥīḥ ḥadīth on *wilāya* existed. It does not
generalise to Names where nothing ṣaḥīḥ exists.)

All texts below fetched from `api.quran.com/api/v4`, translation 20 (Ṣaḥīḥ International).

| Emptied id | Name | Āyah | Fetched Ṣaḥīḥ International text | Strength |
|---|---|---|---|---|
| **15 + 16** | Al-Ḥayy, Al-Qayyūm | **2:255** (Āyat al-Kursī) | *"Allāh — there is no deity except Him, the Ever-Living, the Self-Sustaining."* | **Strongest** — both Names in one clause. **But see §3.1: for these two Names this is option C of three**, and it is only *necessary* if the contested grade is resolved toward ḥasan. |
| **52** | Al-ʿAlī | **2:255** (closing) | *"And He is the Most High, the Most Great."* | Strong — `al-ʿAliyy al-ʿAẓīm` verbatim. |
| **82** | Al-Bāṭin | **57:3** | *"He is the First and the Last, the Ascendant and the Intimate, and He is, of all things, Knowing."* | Strong — the four Names in one āyah. SI renders *al-Bāṭin* as **"the Intimate"**. |
| **84** | Al-Mutaʿālī | **13:9** | *"[He is] Knower of the unseen and the witnessed, the Grand, the Exalted."* | Strong — SI renders *al-Mutaʿāl* as **"the Exalted"**. |
| **20** | Al-Bāriʾ | **59:24** | *"He is Allāh, the Creator, the Producer, the Fashioner; to Him belong the best names."* | Strong — SI renders *al-Bāriʾ* as **"the Producer"**. |
| **75** | Al-Qādir | **46:33** | *"…is able to give life to the dead? Yes. Indeed, He is over all things competent."* | Good — `qadīr`, not `al-Qādir`. |
| **54** | Al-Muqīt | **4:85** | *"And ever is Allāh, over all things, a Keeper."* | ⚠ Usable but note **SI renders *Muqīt* as "a Keeper", not "Nourisher"** — the current card's "Nourisher" gloss is not this translation's. |
| **85** | Al-Barr | **52:28** | *"Indeed, it is He who is the Beneficent, the Merciful."* | ⚠ Usable but note **SI renders *al-Barr* as "the Beneficent"** — the Name is not visible in the English. |
| **43 + 44** | Al-Muʿizz, Al-Muzill | **3:26** | *"You honor whom You will and You humble whom You will."* | ⚠ Weaker — the **verbs**, not the Names. And it is the Prophet's ﷺ commanded speech ("Say"), so the frame must not be "Allah says". |
| **56** | Al-Jalīl | **55:27** | *"And there will remain the Face of your Lord, Owner of Majesty and Honor."* | ⚠ Weak — this is *Dhul-Jalāl* (already id 89), not *al-Jalīl*. |
| **71** | Al-Wājid | — | **No candidate found.** | Leave empty. |
| **96** | An-Nāfiʿ | — | **No candidate found.** | Leave empty. |

---

## 8. Method, and its limits — read before treating anything above as clearance

### 8.1 What was done
- **Qurʾān:** every verse fetched live from `api.quran.com/api/v4`, translation 20. No verse recalled.
- **Ḥadīth:** every claim fetched, and **every citation verified at the bare number a reader
  would look up**, not at a convenient in-book URL. Two reads per citation wherever possible:
  (1) the **Wayback capture of the exact sunnah.com URL** (sunnah.com 403s automation), and
  (2) the `fawazahmed0/hadith-api` English editions, which carry published grades from
  al-Albānī, Aḥmad Shākir, Zubair ʿAlī Zaʾī, Shuʿayb al-Arnaʾūṭ, Bashār ʿAwwād and Muḥammad Fuʾād
  ʿAbd al-Bāqī.
- **I composed no narration, no isnād, and no translation of scripture.** Where sunnah.com gave
  only a transliteration (id 77), I quoted the transliteration rather than author an English
  rendering.
- **Adversarial verification:** two subagents that had not seen my reasoning, instructed to
  refute, to re-fetch everything themselves, and to default to reject. They produced **one
  REJECT, one BLOCK, one refutation of the audit, and one correction of a narration's status**
  — all four are incorporated above.
- **Process note:** archive.org's `/wayback/available` API falsely returns zero snapshots under
  load. The **CDX API** (`web.archive.org/cdx/search/cdx?url=…&filter=statuscode:200`) is the
  fallback that works. Do not conclude "unarchived" from the availability API alone.

### 8.2 Limits
1. **No corpus independent of sunnah.com was reached — by me or by either verifier.** Wayback
   captures *are* sunnah.com; the hadith-api editions derive from the same data, and one verifier
   confirmed its numbering matched sunnah.com exactly. **Their agreement proves the capture was
   not corrupted; it does not prove the text.** This is one corpus read twice. A scholar with a
   printed Fatḥ al-Bārī would be doing something none of us did. **The only genuinely independent
   checks in this whole report are the Qurʾān ones** (api.quran.com is a different provider), and
   those were verified by programmatic exact-substring match.
2. **No isnād was audited. Not one.** Every grade quoted is a **published label read off a page**,
   not a judgement formed. One verifier partially mitigated by reading the Arabic against every
   English claim — which is what settled ids 14, 19 and 50 — but **that Arabic is also
   sunnah.com's**.
3. **Three sources stayed out of reach:** al-Ḥākim's *al-Mustadrak*, *Musnad Aḥmad* in English,
   dorar.net. **Ids 16, 43, 44 and 82 were emptied under ignorance, not on a finding that the
   narrations are false.** For id 16 specifically, the *Mustadrak* page reference is itself
   disputed in the secondary literature (**1/545 vs 1/730**), so the ṣaḥīḥ side of that contested
   grade rests on **secondary scholarship pages, not a primary read** — see §3.1.
   **Grades in this report are therefore not uniformly "labels read off a page" in the same
   sense**: al-Albānī's are, because I fetched the editions carrying them; al-Ḥākim's and
   al-Mundhirī's are second-hand to me, and I mark them as such.
4. **"Zero hits" is a strong signal, not a proof of non-existence.** A narration living only in
   al-Bayhaqī, al-Ṭabarānī, Aḥmad or a tafsīr would not have surfaced.
5. **Every elision, transliteration normalisation, diacritic change and added framing sentence is
   disclosed inline in §5**, so a reviewer can overrule any of them.
6. **The 43 entries the audit called CLEAN were not re-graded against the ṣaḥīḥ-only bar.** See
   §3. Largest known gap; includes a direct inconsistency at id 89.
7. **The staged SQL has never been executed.** No PostgreSQL server was available. Its drift
   guard is reasoned, not proven.

### 8.3 `knowledge_base.dart` — an OPEN P0 surface, honestly stated

The audit only ever examined the `hadith` column. `knowledge_base.dart` carries its own
`coreTeaching` and `propheticStory` prose containing **quoted divine and prophetic speech that
has never been audited by anything** — and it is injected verbatim into the AI prompt. The id-45
fabrication survived there precisely because nothing was looking at that surface, and **I missed
it on my first pass.**

Five defects are now fixed in that file (§9, mirror 4). **A systematic sweep of all its quoted
divine and prophetic speech is running as a separate task, and its coverage statement is not in
this document.** Until that sweep is complete and its findings applied, **`knowledge_base.dart`
must not be treated as cleared.** Also recorded, not chased: the same As-Samīʿ entry attributes a
saying to **Imām Aḥmad** with no citation.

---

## 9. Mirrors — what was written where

The audit's mirror map was **checked, and it is wrong in one place.**

| # | Location | Status |
|---|---|---|
| 1 | `assets/content/collectible_names.json` | **Updated.** 27 `hadith` values; diff is exactly 27 lines; no other field touched; formatting preserved. |
| 2 | `lib/services/card_collection_service.dart` (`allCollectibleNames`) | **Updated.** Verified byte-identical to the asset for all 99 values by **parsing the Dart const list** — a naive substring check falsely reports 13 diffs because of Dart `\'` escaping, which is what makes this mirror easy to get wrong. **`dart format` was deliberately NOT run**: the repo is not formatted with the Dart 3.11 tall-style formatter, and running it rewrote ~90 unrelated lines (reverted). |
| 3 | Supabase `public.collectible_names.hadith` | **STAGED ONLY, NOT APPLIED** → `supabase/staged/fix_catalog_hadith_2026_08_03.sql`. Read-before-write; idempotent; **raises on drift** rather than overwriting, reporting every drifted row before aborting; plus a **per-row post-condition** and a global 99-rows/non-null check. Round-trip verified: every `old` in the SQL equals the pristine pre-edit asset and every `new` equals the updated asset. |
| 4 | `lib/core/constants/knowledge_base.dart` | **Updated — and the audit's description of it is incorrect.** It contains **zero verbatim copies** of the catalogue `hadith` strings; it holds *paraphrases embedded in prose* that is fed straight into the AI prompt (`ai_service.dart:730-731`). **Five defects fixed:** (a) the **P0 invented divine speech** in the As-Samīʿ `propheticStory` — removed, Qurʾān 19:7 quoted verbatim in its place; (b) `"I am close."` in the same entry, in quotation marks attributed to Allah but matching no translation — replaced with the fetched Qurʾān 2:186 text and an explicit reference; (c) the **Ḍaʿīf** *"Make this in your sujud"* (Abū Dāwūd 869) — **twice**, at lines 772 and 862; the audit found only one — replaced with the Ṣaḥīḥ Muslim 772 locus; (d) the conflated *"Whoever exalts himself, Allah lowers him"* clause — trimmed to the verified Muslim 2588 wording with its citation; (e) the unverifiable ʿUmar athar (ids 43/44) — removed. **See §8.3: this file is not cleared.** |
| 5 | `tool/export_public_catalog_snapshots.dart` / `import_…` | **No change needed, verified.** The exporter writes `JsonEncoder.withIndent('  ')` + trailing newline — byte-for-byte the format the asset was written in here — so a post-apply re-export is a no-op diff. The SQL footer instructs the founder to run it. |

`lib/services/public_catalog_contracts.dart` still passes: all 99 rows keep a non-null `hadith`.

---

## 10. Verification run

| Check | Result |
|---|---|
| `flutter analyze` | **40 issues, 0 errors, exit 0.** Warnings/infos only. **None in any file this pass touched** — every issue is in `test/` or `lib/features/` files owned by other concurrent waves. |
| `flutter test` (full suite) | **3472 passed, 4 skipped, 0 failed — `All tests passed!` (exit 0).** Run twice: once after the first round of edits and again after the verifiers' corrections. Identical both times. |
| Widget-PNG side effect | **None.** `git status` shows no `companion_*.png` diffs (the generator is opt-in behind `GEN_WIDGET_FRAMES=1`). |
| Mirror consistency | Dart const ↔ JSON asset: **0 mismatches across all 99 rows** (parsed, not substring-matched). |
| SQL round-trip | **27 rows; every `old` matches the pristine asset, every `new` matches the updated asset; no row where `old == new`.** |
| Forbidden-string grep | `(Derived from Names teachings)`, `(Yaqeen…)`, bare `(Hadith)`, `already named Yahya`: **0 occurrences** across the asset, the Dart const and `knowledge_base.dart`. |
| Local SQL execution | **Not possible** — libpq client tools only, no PostgreSQL server. |

---

*Repairs performed 2026-08-03. **No database row was modified. Nothing was committed.***
