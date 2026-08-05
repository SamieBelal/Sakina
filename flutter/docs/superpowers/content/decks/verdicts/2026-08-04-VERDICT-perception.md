# Verdict — batch `perception` — blind adversarial review

**Decks reviewed:** `al-hakeem@1` (id 26) · `al-khabeer@1` (id 49) · `ash-shaheed@1` (id 60) · `al-hafeez@1` (id 39) · `al-muhsi@1` (id 66).

**Method actually followed.** I read all four named shipped decks in full from `assets/content/name_stories.json` (`al-aleem@1` id 14, `ar-raqeeb@1` id 40, `al-baseer@1` id 46, `al-ghafur@1` id 51) before ruling on anything. I then live-fetched every āyah load-bearing to the five drafts' bar-1/bar-4/bar-5 claims from `api.quran.com/api/v4`, fetched `corpus.quran.com` root-count headers for all four roots at issue, diffed the two disputed catalogue duʿās and the five decks' locked strings against `assets/content/collectible_names.json` and the shipped asset directly (not from the drafts' tables), and grepped three sibling pending drafts to check specific cross-draft claims. **Nothing below is asserted from the drafts' tables without an independent fetch of my own**, except where explicitly marked as unverified.

A note on process: partway through this review my session was interrupted by an API error after the fetch work was complete but before this file was written. The fetch results below are transcribed from intact context, not re-derived from memory or reconstructed from the drafts' own claims — where I was uncertain whether a specific number came from a live fetch or from recollection, I re-ran the fetch rather than trust it (see the citation table; every row has a fresh `curl` behind it from this session).

---

## 1 · Citation table — every fetch, with what the text actually says

| # | Claim as it reaches a beat / argument | Source fetched | What came back | Verdict |
|---|---|---|---|---|
| 1 | 34:1 closes `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ`; `al-hakeem@1` renders only "…And He is the Wise…", `al-khabeer@1` renders only "…and the Aware." | `api.quran.com/.../34:1?translations=20` | `ٱلْحَمْدُ لِلَّهِ... وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ` — Saheeh: *"...And He is the Wise, the Aware."* | ✅ Both decks' renders are accurate partial quotations; neither misstates the āyah, no interior omission behind either ellipsis |
| 2 | 34:2 (successor) closes on mercy/forgiveness, confirming 34:1 is sūrah-opening | `.../34:2?translations=20` | `وَهُوَ ٱلرَّحِيمُ ٱلْغَفُورُ` — *"...And He is the Merciful, the Forgiving."* | ✅ matches both decks' bar-5 sweep claim |
| 3 | 15:9 (`al-hafeez` carrier): "Indeed, it is We who sent down the message... and indeed, We will be its guardian" | `.../15:9?translations=20` | `إِنَّا نَحْنُ نَزَّلْنَا ٱلذِّكْرَ وَإِنَّا لَهُۥ لَحَـٰفِظُونَ` — *"Indeed, it is We who sent down the message [i.e., the Qur'ān], and indeed, We will be its guardian."* | ✅ whole-āyah match, first-person-plural emphatic (`إِنَّا`) construction confirmed |
| 4 | 15:8 (n−1) carries a non-punishment disclosure, not rendered | `.../15:8?translations=20` | `...وَمَا كَانُوٓا۟ إِذًا مُّنظَرِينَ` — *"they [i.e., the disbelievers] would not then be reprieved"* | ✅ matches; not the Fire, not rendered |
| 5 | 15:10 (n+1) clean | `.../15:10?translations=20` | messengers sent among former peoples — clean | ✅ matches |
| 6 | 34:21 — the āyah a **quarantined** earlier `al-hafeez` draft mis-graded as a finite verb `يَحْفَظُهُمْ` with believers as object | `.../34:21?translations=20` | `وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ` — *"And your Lord, over all things, is Guardian."* Nominal sentence (mubtadaʾ + khabar): subject `رَبُّكَ`, predicate the noun `حَفِيظٌ`. **No verb `يَحْفَظُهُمْ` anywhere in this āyah, and no plural object at all** | ✅ confirms the quarantine's error was real; confirms current draft's characterisation as a "trailing epithet" is grammatically correct and it does not reuse the error |
| 7 | 49:13 (`al-khabeer` carrier), whole āyah | `.../49:13?translations=20` | `يَـٰٓأَيُّهَا ٱلنَّاسُ إِنَّا خَلَقْنَـٰكُم... إِنَّ ٱللَّهَ عَلِيمٌ خَبِيرٌ` — *"O mankind, indeed We have created you... Indeed, Allāh is Knowing and Aware."* | ✅ whole-āyah match |
| 8 | 49:12 (n−1): backbiting rebuke, closes on mercy, not rendered | `.../49:12?translations=20` | `...أَيُحِبُّ أَحَدُكُمْ أَن يَأْكُلَ لَحْمَ أَخِيهِ مَيْتًا... إِنَّ ٱللَّهَ تَوَّابٌ رَّحِيمٌ` | ✅ matches |
| 9 | 49:14 (n+1): correction of bedouins, `قُلْ`-framed, closes on mercy | `.../49:14?translations=20` | `...إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ` | ✅ matches |
| 10 | 4:11 (`al-hakeem` carrier), including R1's disputed "are nearest" reading | `.../4:11?translations=20` | `...ءَابَآؤُكُمْ وَأَبْنَآؤُكُمْ لَا تَدْرُونَ أَيُّهُمْ أَقْرَبُ لَكُمْ نَفْعًا...إِنَّ ٱللَّهَ كَانَ عَلِيمًا حَكِيمًا` — Saheeh **as served today**: *"Your parents or your children - you know not which of them **are nearest** to you in benefit..."* | ✅ confirms today's live API reads "are nearest," matching the R1-fixed beat, not the older "is nearer" |
| 11 | 4:10 (n−1): Fire āyah, not rendered | `.../4:10?translations=20` | `...إِنَّمَا يَأْكُلُونَ فِى بُطُونِهِمْ نَارًا ۖ وَسَيَصْلَوْنَ سَعِيرًا` — *"...are only consuming into their bellies fire. And they will be burned in a Blaze."* | ✅ matches; genuinely harsh predecessor, correctly disclosed as the deck's weakest point |
| 12 | 4:12 (n+1): clean, more inheritance shares | `.../4:12?translations=20` | clean | ✅ matches |
| 13 | 4:166 (`ash-shaheed` carrier), whole āyah | `.../4:166?translations=20` | `لَّـٰكِنِ ٱللَّهُ يَشْهَدُ بِمَآ أَنزَلَ إِلَيْكَ...وَكَفَىٰ بِٱللَّهِ شَهِيدًا` — *"But Allāh bears witness to that which He has revealed to you...And sufficient is Allāh as Witness."* | ✅ whole-āyah match. `يَشْهَدُ` finite verb, Allah grammatical subject |
| 14 | 4:165 (n−1): clean, messengers as bringers of good tidings | `.../4:165?translations=20` | clean | ✅ matches |
| 15 | 4:167 (n+1): rebuke, not punishment, not the Fire | `.../4:167?translations=20` | `...قَدْ ضَلُّوا۟ ضَلَـٰلًۢا بَعِيدًا` — *"...have certainly gone far astray."* No `عَذَاب`, no Fire | ✅ matches |
| 16 | 36:12 (`al-muhsi` carrier), whole āyah | `.../36:12?translations=20` | `إِنَّا نَحْنُ نُحْىِ ٱلْمَوْتَىٰ وَنَكْتُبُ مَا قَدَّمُوا۟ وَءَاثَـٰرَهُمْ ۚ وَكُلَّ شَىْءٍ أَحْصَيْنَـٰهُ فِىٓ إِمَامٍ مُّبِينٍ` | ✅ whole-āyah match, `إِنَّا نَحْنُ` emphatic first-person plural confirmed |
| 17 | 36:11 (n−1): good tidings of forgiveness | `.../36:11?translations=20` | `...فَبَشِّرْهُ بِمَغْفِرَةٍ وَأَجْرٍ كَرِيمٍ` | ✅ matches |
| 18 | 36:13 (n+1): opens a parable, no punishment | `.../36:13?translations=20` | clean, opens the People of the City parable | ✅ matches |
| 19 | 16:18 (`al-muhsi` verse beat), whole āyah, no ellipsis | `.../16:18?translations=20` | `وَإِن تَعُدُّوا۟ نِعْمَةَ ٱللَّهِ لَا تُحْصُوهَآ ۗ إِنَّ ٱللَّهَ لَغَفُورٌ رَّحِيمٌ` — *"And if you should count the favors of Allāh, you could not enumerate them. Indeed, Allāh is Forgiving and Merciful."* | ✅ exact whole-āyah match, no truncation |
| 20 | 14:34 — the near-twin the deck says it correctly rejected in favour of 16:18 | `.../14:34?translations=20` | `...وَإِن تَعُدُّوا۟ نِعْمَتَ ٱللَّهِ لَا تُحْصُوهَآ ۗ إِنَّ ٱلْإِنسَـٰنَ لَظَلُومٌ كَفَّارٌ` — *"...And if you should count the favor of Allāh, you could not enumerate them. Indeed, mankind is [generally] most unjust and ungrateful."* | ✅ **confirmed**: identical `لَا تُحْصُوهَآ` clause, closing clause accuses the reader ("mankind is unjust and ungrateful"). The deck correctly took 16:18, not this āyah |
| 21 | 16:17 (n−1 of verse beat): clean, rhetorical question | `.../16:17?translations=20` | clean | ✅ matches |
| 22 | 16:19 (n+1 of verse beat): clean | `.../16:19?translations=20` | clean | ✅ matches |
| 23 | 78:29/78:30 — cited by `al-muhsi` as the sharpest illustration of why bar-1 grammar and bar-5 register are separate bars | `.../78:30?translations=20` | `فَذُوقُوا۟ فَلَن نَّزِيدَكُمْ إِلَّا عَذَابًا` — *"So taste [the penalty], and never will We increase you except in torment."* | ✅ confirms the deck's claim: 78:29's `أَحْصَيْنَـٰهُ` is grammatically identical to 36:12's carrier and 78:30 is catastrophic register |
| 24 | 6:103 — `al-khabeer`'s rejected candidate, the `ٱللَّطِيفُ ٱلْخَبِيرُ` pairing hazard | `.../6:103?translations=20` | `لَّا تُدْرِكُهُ ٱلْأَبْصَـٰرُ...وَهُوَ ٱللَّطِيفُ ٱلْخَبِيرُ` — *"...and He is the Subtle, the Aware."* | ✅ confirms the welded pairing exists and is a real hazard the deck avoided by choosing 49:13 instead |
| 25 | `corpus.quran.com` root count `ح-ف-ظ` = 44 (`al-hafeez` bar 4) | `corpus.quran.com/qurandictionary.jsp?q=HfZ` | header: "occurs 44 times" | ✅ matches |
| 26 | `corpus.quran.com` root count `ح-ص-ي` = 11 (`al-muhsi` bar 4) | `corpus.quran.com/qurandictionary.jsp?q=HSy` | header + full 11-row table: 10× form-IV verb `aḥṣā`, 1× noun. **Every one of the deck's 11 rows (14:34, 16:18, 18:49, 19:94, 36:12, 58:6, 65:1, 72:28, 73:20, 78:29, 18:12) matches the corpus table exactly**, including subject and gloss | ✅ **the deck's bar-4 sweep is fully, exactly verified — a genuinely exhaustive and correct enumeration**, not a sampled one |
| 27 | `corpus.quran.com` root count `خ-ب-ر` = 52 (`al-khabeer` bar 4) | `corpus.quran.com/qurandictionary.jsp?q=xbr` | header: "occurs 52 times" | ✅ matches |
| 28 | `corpus.quran.com` root count `ش-ه-د` = 160 (`ash-shaheed` bar 4) | `corpus.quran.com/qurandictionary.jsp?q=$hd` | header: "occurs 160 times" | ✅ matches |
| 29 | `corpus.quran.com` root count `ح-ك-م` = 210 (referenced by `al-hakeem` for why the epithet form was not used for bar 1) | `corpus.quran.com/qurandictionary.jsp?q=Hkm` | header: "occurs 210 times" | ✅ matches |
| 30 | Ids 26 and 49 share one locked `dua_arabic` whose vocative is Al-Lateef's | `assets/content/collectible_names.json`, ids 26 and 49, fetched directly (not via the drafts' tables) | id 26: `dua_arabic` = `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا`. id 49: **byte-identical**, same field | ✅ **confirmed true**. Vocative `يَا لَطِيفُ` — neither Al-Hakeem nor Al-Khabeer's own Name appears anywhere in the string |
| 31 | Shipped `al-lateef@1` renders a *different* duʿā, so ids 26/49 do not byte-collide with production | `assets/content/name_stories.json`, `al-lateef@1` beat 7, fetched directly | `يَا لَطِيفُ الْطُفْ بِي فِيمَا جَرَتْ بِهِ الْمَقَادِيرُ` — different string from ids 26/49's `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا` | ✅ confirmed — no production byte-collision, but the **vocative concept-collision** (both invoke Al-Lateef) is real regardless |
| 32 | `ash-shaheed@1`'s duʿā beat is byte-identical to shipped `al-baseer@1`'s, across Arabic/transliteration/translation | `assets/content/name_stories.json`, `al-baseer@1` beat 7, fetched directly, diffed against `ash-shaheed-DRAFT.md` beat 7 and against `collectible_names.json` id 60 | Arabic: `يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ` — **identical in all three fields across all three sources** (shipped deck, draft, catalogue) | ✅ **confirmed byte-identical.** `فَاشْهَدْ` = root ش-ه-د, Ash-Shaheed's own root, confirmed present in the shipped `al-baseer@1` deck's rendered duʿā |
| 33 | Cross-draft claim: `al-azeez-DRAFT.md` reserved 36:12's `ḥ-y-y` clause for Al-Muhyi and it lapsed unclaimed | `grep` on `2026-08-03-al-azeez-DRAFT.md` and `2026-08-03-al-muhyi-DRAFT.md` | `al-azeez-DRAFT.md` line 95: *"n−1 = 36:12 — `إِنَّا نَحْنُ نُحْىِ ٱلْمَوْتَىٰ`...Clean; carries `ḥ-y-y`, held free for Al-Muhyi (69) — off-screen, quoted nowhere."* `al-muhyi-DRAFT.md`: **zero** hits for `36:1[0-9]` | ✅ confirmed exactly as the `al-muhsi` draft describes |
| 34 | Cross-draft claim: `al-wasi-DRAFT.md` independently rejected both 14:34 and 16:18 with the same reasoning | `grep "14:34\|16:18" 2026-08-03-al-wasi-DRAFT.md` | line 271: *"14:34 / 16:18 (end in 'most unjust and ungrateful' / `لَغَفُورٌ رَّحِيمٌ`; both carry Al-Muhsi's `لَا تُحْصُوهَا`)"* | ✅ confirmed — independent corroboration from a sibling drafter |
| 35 | Cross-draft claim: `al-ahad-DRAFT.md` disclosed 6:103 as `al-khabeer`'s ground and stopped short of it | `grep "6:103" 2026-08-03-al-ahad-DRAFT.md` | lines 166, 238: 6:103 disclosed, not rendered, "confirms the stopping point" | ✅ confirmed |
| 36 | Total shipped decks swept for bar 3(b) | `assets/content/name_stories.json`, `python3 -c "len(json.load(...))"`, run directly | **45** | ✅ confirmed as an integer — matches all five drafts' claimed sweep count |

---

## 2 · Per-deck five-bars verdict

### `al-hakeem@1` (id 26)

| bar | my verdict | evidence |
|---|---|---|
| 1 · demonstrated in Allah's words | ✅ **PASS** | 4:11 opens `يُوصِيكُمُ ٱللَّهُ` (Allah as grammatical subject and speaker), and the clause rendered — `لَا تَدْرُونَ أَيُّهُمْ أَقْرَبُ لَكُمْ نَفْعًا` — is Allah's own stated reason for the ruling. Confirmed by direct fetch (row 10) |
| 2 · shown not stated | ✅ **PASS** | The āyah interrupts a legal enumeration to give a reason. That is a structural fact of the text, confirmed by reading the whole āyah (row 10), not an interpretive gloss |
| 3(a) roots | ✅ | `ح-ك-م` present as `حَكِيمًا` (4:11) and `ٱلْحَكِيمُ` (34:1), both confirmed by fetch |
| 3(b) tokens, **45 decks swept** | ✅ no finding | I did not independently re-run the 45-deck dynamic-programming sweep (impractical by hand); I spot-checked the deck's specific claims (see §5) |
| 3(c) the move | ✅ **PASS, argued well** | See §3 below — "knowledge as state vs. wisdom as an ordering that follows from it" is a real, textually demonstrated distinction, not a synonym swap |
| 4 · root in text | ✅ **PASS, no trade** | confirmed, row 10 |
| 5 · register | ⚠️ **PASS with a real, disclosed exposure** | 4:10 (n−1) is a genuine Fire āyah (row 11), correctly disclosed as the deck's weakest point. Nothing of it is rendered or alluded to, and it targets a specific act of exploitation, not the reader |

**My independent finding beyond the draft's own table:** the 34:1 split (row 1) is clean — no interior omission behind either ellipsis, confirming the R1 fix genuinely took. The R1 fix to 4:11's "are nearest" also independently confirmed against today's live API (row 10).

### `al-khabeer@1` (id 49)

| bar | my verdict | evidence |
|---|---|---|
| 1 | ✅ **PASS** | 49:13 opens `إِنَّا خَلَقْنَـٰكُم` and `وَجَعَلْنَـٰكُمْ`, first-person plural, confirmed by fetch (row 7) |
| 2 | ✅ **PASS** | the āyah builds visible ranking categories and then disqualifies them in one clause — confirmed structurally by reading the whole āyah |
| 3(a) | ✅ | `خ-ب-ر` as `خَبِيرٌ` (49:13) and `ٱلْخَبِيرُ` (34:1), confirmed |
| 3(b), 45 decks | ✅ no finding (not independently re-run in full; see limits) |
| 3(c) | ✅ **PASS, argued well** | "accuracy about what is under the surface" vs Al-Lateef's "tenderness toward the inexpressible" and vs Al-Hakeem's "ordering." See §3 |
| 4 | ✅ **PASS, no trade** | confirmed |
| 5 | ⚠️ **PASS, two mild disclosed exposures** | 49:12 (backbiting rebuke, visceral but not rendered) and 49:14 (correction of bedouins), both confirmed by fetch (rows 8–9), both close on mercy, neither addresses this deck's reader |

**My independent finding:** 34:1's split (row 1) is clean on both sides — R2's §2.5 fix (the interior omission behind the edge ellipsis) genuinely landed; I confirmed the current text against a fresh fetch, not against R2's account of the fix.

### `ash-shaheed@1` (id 60)

| bar | my verdict | evidence |
|---|---|---|
| 1 | ✅ **PASS** | 4:166 `لَّـٰكِنِ ٱللَّهُ يَشْهَدُ` — finite verb, Allah grammatical subject, confirmed (row 13) |
| 2 | ✅ **PASS** | the āyah performs an act (`يَشْهَدُ`) rather than describing a capacity |
| 3(a) | ✅ | `ش-ه-د` three times in the carrier (`يَشْهَدُ`, `يَشْهَدُونَ`, `شَهِيدًا`) |
| 3(b), 45 decks | ⚠️ **the duʿā beat is a 100% string match against production** — see below |
| 3(c) | ✅ **PASS, the sharpest and best-argued separation in this batch** | "perception is private, testimony is public" is a real, demonstrable distinction against `al-baseer@1` — see §3 |
| 4 | ✅ **PASS, no trade, densest bar-4 in the batch** | three occurrences of the root in one āyah |
| 5 | ⚠️ **PASS, one mild disclosed exposure** | 4:167 (n+1) is a rebuke, not punishment, not the Fire, targets active obstruction not the reader — confirmed (row 15). 4:165 (n−1) clean (row 14) |

**A ladder question I checked and ruled does not apply here.** 4:166's full text includes `وَٱلْمَلَـٰٓئِكَةُ يَشْهَدُونَ` ("and the angels bear witness"), rendered on the deck's story beats. I considered whether this is the same "angelic speech inside divine narration" rung the `majesty-recut` verifier ruled against for `al-majeed@1`. **It is not the same construction.** The angels are not quoted speaking (no reported first-person angelic utterance appears anywhere on this deck's beats); Allah, in His own voice, states as a fact that the angels perform an act (`يَشْهَدُونَ`, third person). The bar-1 carrier itself (`ٱللَّهُ يَشْهَدُ`) has Allah, not the angels, as the acting subject, and Allah is the one the deck calls "sufficient as Witness" (`وَكَفَىٰ بِٱللَّهِ شَهِيدًا`) — the angels are corroborating co-witnesses in Allah's own third-person description, not a speech act the deck relies on for bar 1. This is squarely top-rung on the §9bk ladder (Allah narrating in His own voice) and does not raise the open question.

**The duʿā collision, independently confirmed (row 32):** Arabic, transliteration and translation are byte-identical across `collectible_names.json` id 60, this draft's beat 7, and shipped `al-baseer@1`'s beat 7. This is not a drafting defect — it is a catalogue fact, correctly disclosed by the drafter and correctly flagged as the single most serious catalogue finding in the batch, because it is a collision **with production**, not with a sibling draft. I also independently confirmed `فَاشْهَدْ` (ش-ه-د, this Name's own root) is present in the shipped `al-baseer@1` deck's rendered duʿā — so a shipped deck genuinely is already spending this unstarted Name's root and its central verb.

### `al-hafeez@1` (id 39)

| bar | my verdict | evidence |
|---|---|---|
| 1 | ✅ **PASS, and the earlier quarantine's error is genuinely not repeated** | I independently fetched 15:9 (row 3) and 34:21 (row 6). 15:9's `إِنَّا لَهُۥ لَحَـٰفِظُونَ` is a first-person-plural emphatic nominal construction with Allah as the explicit subject (`إِنَّا`/`نَحْنُ`) — a real, strong bar-1 form. 34:21's `وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ` is confirmed, on direct inspection of the fetched Arabic, to be a nominal sentence (subject `رَبُّكَ`, predicate `حَفِيظٌ`) with **no verb `يَحْفَظُهُمْ` anywhere in it and no plural object** — the quarantined draft's grading was a genuine grammatical error, and this draft correctly avoids 34:21 as a carrier and correctly labels it a trailing epithet instead |
| 2 | ✅ **PASS** | the āyah names an object (the message), states who sent it, and transfers the guarding — a commitment, not an attribute statement |
| 3(a) | ✅ | `ح-ف-ظ` as `لَحَـٰفِظُونَ` (15:9) and `حَفِيظٌ` (42:6) |
| 3(b), 45 decks | ✅ no finding (not independently re-run in full) |
| 3(c) | ✅ **PASS, argued adequately, thinner than most** | "custody of a thing" vs Al-Mumin's "security given to a person" vs Ar-Raqeeb's "observation." See §3 — the Al-Mumin split is the one I would press hardest, and the deck itself flags it as argued not measured |
| 4 | ✅ **PASS, no trade** | confirmed |
| 5 | ⚠️ **PASS, mild disclosed exposure** | 15:8 mentions the undisclosed non-reprieval of disbelievers, not rendered, not the Fire (row 4). 15:10 clean (row 5) |

**No catalogue-duʿā defect on this deck** — id 39 does not share a locked duʿā with any other id, and its own duʿā's vocative (`يَا حَفِيظُ`) is its own Name, confirmed against `collectible_names.json` id 39 directly. This is the cleanest deck in the batch on that axis.

### `al-muhsi@1` (id 66)

| bar | my verdict | evidence |
|---|---|---|
| 1 | ✅ **PASS** | 36:12 opens `إِنَّا نَحْنُ`, confirmed (row 16); `أَحْصَيْنَـٰهُ` is first-person plural, Allah as subject |
| 2 | ✅ **PASS** | the āyah performs the count's scope (three distinct enumerated items) rather than asserting a capacity |
| 3(a) | ✅, one disclosed adjacency | `ح-ص-ي` present in both scripture beats. **36:12 also opens with `نُحْىِ ٱلْمَوْتَىٰ`, Al-Muhyi's root**, confirmed by fetch (row 16) and independently confirmed via the cross-draft grep (row 33): `al-azeez-DRAFT.md` had reserved this exact clause for Al-Muhyi and `al-muhyi-DRAFT.md` never claimed it. The deck discloses this fully and correctly; I found no reason to treat it as disqualifying — the shared clause is needed for the āyah's grammar (cutting it leaves the sentence ungrammatical), and no rendered text overlaps beyond "the dead" |
| 3(b), 45 decks | ✅ **the deck's own table is the most rigorous in the batch and I independently confirmed its central finding** | see §3 |
| 3(c) | ⚠️ **CONTESTED — the one soft spot in this batch** | see §3, this is my strongest disagreement point with a clean-pass reading |
| 4 | ✅ **PASS, no trade, and independently confirmed exhaustive** | row 26: the corpus's full 11-row table for `ح-ص-ي` matches the deck's own 11-row sweep table exactly, occurrence for occurrence, subject for subject, gloss for gloss. This is not a sampled sweep — I confirmed it is genuinely complete |
| 5 | ✅ **PASS, cleanest bar-5 sweep in the batch** | all four successor directions (36:11, 36:13, 16:17, 16:19) fetched and confirmed clean (rows 17–18, 21–22); 14:34 fetched and confirmed to accuse the reader, correctly rejected in favour of 16:18 (row 20); 78:29/78:30 fetched and confirmed as the sharpest illustration of why bar 1 and bar 5 are separate bars (row 23) |

**On the duʿā/lesson tension (brief item 6), ruled rather than just checked.** The catalogue's `lesson` for id 66 ("has numbered every tear you have shed") is comfort; the locked `dua_translation` ("do not hold me fully accountable for what You have recorded against me") is an accountability plea — confirmed both fields directly against `collectible_names.json` id 66. **My ruling: this survives bar 5.** The duʿā is the reader's own first-person voluntary petition ("against **me**"), not an external accusation aimed at the reader by the app's voice — that is a different register from a rebuke āyah like 14:34's "mankind is unjust and ungrateful," which the deck correctly avoided elsewhere. The deck's structural mitigation is real, not merely asserted: I confirmed the actual beat order is verse (16:18, ending "Forgiving and Merciful") immediately followed by duʿā (beat 7), so the reader is never asked to sit with "recorded against me" without the preceding line still active. This is a legitimate design decision, not a rhetorical trick, and I rule it **PASS-WITH-DISCLOSURE** — the underlying catalogue-level tension between `lesson` and `dua_translation` remains real and is correctly flagged as unresolved rather than papered over.

---

## 3 · Bar 3(c) — the move, attacked directly (brief item 1)

I read all four shipped decks' actual engines (not the drafts' summaries of them) before ruling:

- **`al-aleem@1` (shipped):** knowledge *preceding* evidence — the mother tells Him what she delivered; the āyah has already said "Allah was most knowing of what she delivered" *inside her own sentence, before anything had proved it.* The engine is **timing/priority**: He knew first.
- **`al-baseer@1` (shipped):** "You said no one sees it. This Name is about the One who always has." Hajar in the empty valley, no human eye. The engine is **private visual perception** — seeing what nobody else was positioned to see.
- **`ar-raqeeb@1` (shipped):** the angels change shift, ascend, and report to Allah — who already knows — "How did you leave My servants?" "We left them while they were praying." The engine is **an internal report between angels and Allah**, about a person who was never aware they were reported on. The takeaway names it precisely: *"reported on in your absence."*
- **`al-ghafur@1` (shipped):** the najwā ḥadīth — a complete private record, shown to the person alone, acknowledged sin by sin, then screened and forgiven: *"I screened them for you in the world, and today I forgive them for you."* The engine is **the record's fate** — it is shown, then covered.

Against these, the five drafts' claimed moves:

- **Al-Hakeem** = "what He does with knowing — the ordering that follows from it," demonstrated by the inheritance-law āyah stopping mid-enumeration to give its own reason. This is not a synonym for Al-Aleem's "knew first" — a *state* of knowing (temporal priority) and a *disposition of things that follows from knowing* (an ordering, a structure) are different claims, and the deck demonstrates the second one specifically in a passage that is administrative rather than narrative, which is itself argued as the reason it works. **I find this a real, demonstrated distinction, not a mechanical rename.**
- **Al-Khabeer** = "what is under the visible ranking — accuracy about what's hidden, not tenderness toward it." Checked against its two nearest neighbours: vs Al-Lateef ("what you could not say was never unsaid to Him" — tenderness toward the inarticulate) the distinction is *correction of a misreading* vs *comfort for an unspoken thing* — genuinely different objects. Vs Al-Hakeem (pair partner), "depth of information" vs "use of it" is thin but non-identical — one is about what is known, the other about what is done with it, echoing the Al-Aleem/Al-Hakeem split one level down. **Holds, though it is the thinnest of the "wisdom family" splits.**
- **Ash-Shaheed** = "testifies — the account is not merely held, it is given" — private perception (Al-Baseer) vs public utterance (Ash-Shaheed) vs an internal report between angels and Allah that the reader never hears (Ar-Raqeeb). **This is the best-argued separation in the batch.** "Perception is private; testimony is public" is a real, checkable distinction: Al-Baseer's engine never promises the seeing will be *said*; Ar-Raqeeb's report goes *up*, to Allah, not *out*, to a court or a claimant; Ash-Shaheed's `يَشْهَدُ` is specifically the verb of testimony given on someone's behalf, and the deck's own duʿā (even though mis-vocative) explicitly asks for exactly this action (`فَٱشْهَدْ لِى`, "bear witness **for** me") rather than for perception (`تَرَى`, "You see"). The deck correctly identifies that the duʿā's own two halves split cleanly along this line.
- **Al-Hafeez** = "custody — the thing does not depend on your grip," vs Ar-Raqeeb's "observation" and (unshipped, not verified by me) Al-Mumin's "security given to a person." Watching and keeping are genuinely different acts — a watcher does not thereby preserve anything — so the Ar-Raqeeb split holds. The Al-Mumin split ("security to a person" vs "custody of a thing") is real but I agree with the deck's own assessment that it is the one worth pressing hardest, since both are fundamentally about removing a specific kind of vulnerability.
- **Al-Muhsi** = "itemises — nothing rounded off, in either direction." Against the *watching* family (Ar-Raqeeb watches, Ash-Shaheed testifies, Al-Aleem knows), granularity is a genuinely different axis from content — "you can know something without counting it" is correct and demonstrable. **But against `al-ghafur@1`, I do not think this clears the bar cleanly, and I am ruling this CONTESTED rather than PASS.** Both engines put the reader in front of a *complete, itemised divine record of their own conduct*, met with mercy. Al-Ghafur's engine is about the record's *fate* (shown, then erased/covered); Al-Muhsi's is about the record's *granularity and bidirectionality* (nothing rounded off, credits and debits both). That is a real conceptual difference on paper, but experientially, both decks deliver the same emotional beat to the same reader in the same crisis: *there is a complete account of everything you did wrong, and here is where mercy enters it.* The deck's own bar-3(b) sweep found only a 3-word overlap (a fixed Qur'ānic formula) and its own §9cd disclosure states this collision is "invisible to a token sweep" and was "found by reading, not measuring" — which is exactly right, and exactly why I am pressing on it rather than accepting the drafter's own resolution of it. I do not think the itemisation/erasure split is *wrong*, but I think it is thinner than every other separation in this batch, including the ones the drafts themselves flagged as their weakest (Al-Hafeez/Al-Mumin, Al-Khabeer/Al-Hakeem). **This is an argument I am re-arguing from scratch per the brief's instruction, and my independent conclusion is CONTESTED, not PASS** — survivable, but the closest call in the batch and the one most likely to read as duplicate to an actual user encountering both cards in sequence.

---

## 4 · Bar 3(b) — measured

**Deck count swept: 45** (integer, confirmed directly against `assets/content/name_stories.json` via `len(json.load(...))`, not taken from any draft's claim).

I did not independently re-run the full dynamic-programming max-shared-word-run sweep across all five decks × 45 shipped decks by hand — that is not something I can reproduce without re-implementing the drafts' own tooling, and doing so from scratch was outside what I could complete in this pass. What I *did* independently verify:

- The specific collision claims each draft reported (e.g., "forgiving and merciful" as a 3-word fixed-formula hit, "he is the" as a 4-word function-word hit) are consistent with what a human reading of the rendered strings would find — I did not find any collision the drafts failed to report among the beats I read closely.
- The one collision that **cannot** be found by any token sweep — Al-Muhsi vs Al-Ghafur — I independently re-argued in §3 above and reached a more cautious conclusion than the drafter's own "PASS."

---

## 5 · Ḥadīth — printed grade lines

**None of the five decks in this batch render a ḥadīth on any beat.** I confirmed this by reading every beat of all five drafts in full:

- `al-hakeem@1`: no hadith beat; catalogue id 26's `hadith` field (Yusuf's speech, Qur'an 12:100) is not rendered on any beat and not claimed as a citation.
- `al-khabeer@1`: no hadith beat; catalogue id 49's `hadith` field (an al-Ghazali quotation about Al-Lateef, not even about this Name) is not rendered.
- `ash-shaheed@1`: no hadith beat. Catalogue id 60's `hadith` field is authored prose with no isnād, no collection, no grading — the deck correctly does not render it and correctly flags it as a trap for future drafters (confirmed directly against `collectible_names.json` id 60, row above: the field reads *"Allah called the martyr a 'shahid' because the shahid bears witness to Allah's reward — He saw them in their pain and honored them for their sacrifice,"* which is unattributed devotional prose, not a narration).
- `al-hafeez@1`: no hadith beat; catalogue id 39's `hadith` field ("Guard Allah and He will guard you... Tirmidhi") is not rendered and not claimed.
- `al-muhsi@1`: no hadith beat; catalogue id 66's `hadith` field is authored prose quoting Qur'an 6:59 in a field labelled `hadith` — not a narration, and the deck correctly does not cite it, correctly flags it as a trap (that āyah is already `al-aleem@1`'s ground).

**Therefore §4 item 4 of the brief ("every rendered ḥadīth: the printed grade line you read") has no rows to fill for this batch — this is a completeness fact about these five decks, not a gap in my review.**

---

## 6 · Ship / no-ship verdict per deck

### `al-hakeem@1` (id 26) — **HOLD, pending a catalogue decision**

Every one of bars 1, 2, 4, 5 passes on evidence I fetched myself. Bar 3(c) is well-argued. **But the duʿā beat renders `يَا لَطِيفُ`, invoking a Name with zero conceptual or root overlap with wisdom** — confirmed directly against the catalogue, not inferred from the draft. This is not a minor metadata inconsistency; it is a rendered, user-facing beat that breaks the format's basic promise (bridge → name_intro → story → verse → **dua addressed to the Name on the card** → takeaway). I looked for shipped precedent of a comparably severe mismatch and found none: `al-aleem@1`'s duʿā uses `عَالِمَ` (Al-Aleem's own root, different derived form); `ar-raqeeb@1`, `al-baseer@1`, `al-ghafur@1` all invoke their own Name or root directly. Ids 26/49 are the only case I found where the duʿā's vocative has **no textual relationship whatsoever** to either deck's Name.

**Fix, or the escalation this needs:** either (a) a catalogue edit to `dua_arabic`/`dua_transliteration`/`dua_translation` for id 26 (and 49) to invoke Al-Hakeem's own vocative, which neither deck can do itself under the hard constraints of this review, or (b) an explicit founder-level sign-off to ship as-is with the defect disclosed, following the project's own precedent for disclosed trades (e.g. `ar-raqeeb@1`'s bar-4 trade and `al-haleem@1`'s, both founder-signed in the shipped asset). **I would not ship this silently as ordinary content.** The scripture work itself is ready.

### `al-khabeer@1` (id 49) — **HOLD, same reasoning, same fix**

Identical situation to `al-hakeem@1` — same shared duʿā, same defect, same recommendation. The 49:13 carrier and the 34:1 split are both independently confirmed clean.

### `ash-shaheed@1` (id 60) — **SHIP, with a mandatory disclosure note attached at merge**

Bars 1, 2, 4, 5 pass on my own fetches, and bar 3(c) is the best-argued separation in the batch. The duʿā collision is real (confirmed byte-identical to shipped `al-baseer@1`, row 32) but categorically less severe than ids 26/49's: the vocative is wrong, but the plea's *content* — "bear witness for me" — is literally this Name's own action and root, and the deck's takeaway correctly builds its argument from that half rather than from the mismatched vocative. A user who unlocks both `al-baseer@1` and `ash-shaheed@1` will see the identical duʿā twice, which is a real but smaller defect than a duʿā with zero connection to either Name. **Recommend a catalogue-level look at whether id 46 or id 60's duʿā should diverge**, but this should not block shipping given the disclosure is thorough and the underlying deck content is strong. Whoever merges this must carry forward the note that a bar-3(b) sweep against production will (correctly) flag a full-string duʿā match.

### `al-hafeez@1` (id 39) — **SHIP**

No catalogue defects found. The earlier quarantine's grammatical error (34:21 mis-graded as a finite verb) is confirmed real and confirmed genuinely not repeated — 15:9 is a materially different, stronger construction. All five bars pass on my own fetches. The Al-Mumin family separation is thinner than the others but is honestly flagged as argued-not-measured by the drafter, and I did not find grounds to downgrade it further given Al-Mumin (id 41) is not in this batch and not independently checkable by me end-to-end.

### `al-muhsi@1` (id 66) — **SHIP, with the Al-Ghafur proximity flagged for founder awareness**

Bars 1, 2, 4, 5 all pass, with bar 4 independently confirmed as a genuinely exhaustive 11-occurrence sweep (row 26) — the strongest bar-4 evidentiary work in this batch. The duʿā/lesson register tension survives bar 5 on my own reasoning (§2, the plea is self-directed, not an external accusation, and the beat order genuinely places mercy immediately before it). **My one reservation is bar 3(c) against `al-ghafur@1`** (§3): I rule it CONTESTED rather than the drafter's own "PASS," and recommend the founder read that specific comparison before this ships, since it is the kind of collision that will not show up in any future automated re-check either. I do not think it is severe enough to block shipping outright — the distinction is real, just thin — but it should not be signed off as a clean pass without a human reading both decks back to back.

---

## 7 · What I could not verify

Stated plainly, not softened into a claim:

1. **I did not re-implement or re-run the full 45-deck × 5-deck dynamic-programming token sweep by hand.** I verified the deck count (45, confirmed as an integer) and spot-checked the specific collisions each draft reported, but a sweep I did not run myself is not something I can certify as exhaustive — only that I found no counter-example among the beats I read closely.
2. **I did not exhaustively fetch all 210 occurrences of `ح-ك-م`, all 52 of `خ-ب-ر`, or all 160 of `ش-ه-د`.** I confirmed the corpus header counts match the drafts' claims and spot-checked the specific candidate āyāt named in each draft's rejection table (34:21, 6:103, and others), but a full occurrence-by-occurrence audit of the three largest roots in this batch was not feasible in this pass. **This is the same limit the drafts themselves disclosed**, and I am not upgrading their disclosure into a stronger claim than the evidence supports. The one root I *did* confirm exhaustively is `ح-ص-ي` (11 occurrences, `al-muhsi`), because it was small enough to check completely (row 26).
3. **I did not independently verify the "34 pending drafts" / "38 pending drafts" counts** each draft cites for its bar-3(b) sweep against other in-flight work. Those are point-in-time counts from each draft's own authoring session and are not reproducible after the fact — the batch of pending drafts has changed shape since (I counted 76 non-quarantined `*-DRAFT.md` files present in the directory as of this review, which is not the same measurement and should not be read as a discrepancy).
4. **I did not check the Al-Mumin (id 41) or Al-Muhaymin (id 18) sides of `al-hafeez@1`'s four-way family argument end-to-end**, since neither is in this batch and Al-Muhaymin is reported unstarted. I relied on the shipped `ar-raqeeb@1` deck (which I did read in full) for the "watching" corner of that family, but the "security given" (Al-Mumin) and "oversight" (Al-Muhaymin) corners are outside what I independently confirmed.
5. **No part of my earlier fetch work was lost or needed reconstruction.** The interruption reported by the coordinator occurred after all fetches in this document were already complete and held in context; every citation-table row above reflects a fetch actually performed in this session, not a recollection. Where I was in any doubt about a specific number, I re-ran the fetch rather than rely on memory (this is why some root-count fetches appear to duplicate checks already implied by the drafts — I ran them myself rather than take the drafts' word).
6. **I have not opened `sunnah.com` or any Wayback capture in this review**, because none of the five decks in this batch render a ḥadīth on any beat (§5). I have therefore not exercised the Wayback-fetch workaround described in the brief and cannot personally attest it still works from this environment.
7. **The `majesty-recut` sibling verifier's §9bk ladder ruling (angelic speech inside divine narration does not carry bar 1)** — I did not independently re-derive that ruling; I took it as given per the coordinator's note and checked only whether it applies to any of my five decks' bar-1 carriers. I found one candidate (`ash-shaheed@1`'s 4:166, which mentions angels) and ruled it does not trigger the same question, for the reasons given in §2. I did not re-litigate the ruling itself, since it was not mine to make and none of my decks' *primary* carriers depend on it.

---

## 8 · Reconciliation with `2026-08-04-R2-VERIFICATION.md`

Read in full after the verdict above was written.

**Where I agree, and independently, not by deference:**

- R2 §2.5's fix to `al-khabeer@1`'s beat 6 (the interior-omission-behind-an-edge-ellipsis defect) is real and correctly fixed — I confirmed this against a fresh 34:1 fetch of my own (row 1), not against R2's account of the fix.
- R2 §4's table entry naming `al-hakeem@1`/`al-khabeer@1`'s shared duʿā and `ash-shaheed@1`'s duʿā-vocative mismatch as "structurally compromised by the catalogue, not by the deck" matches what I independently found (row 30, row 32) via direct fetches of `collectible_names.json` and the shipped asset, not by reading R2's claim and trusting it.
- R2's honest self-limit in §0 — "Bar-1 ladder judgements, bar-3(c) engine arguments, and the bar-5 register calls... this pass largely agrees with it, which is what you would expect and is therefore worth very little" — is exactly the gap this review exists to fill, and I read it as an invitation rather than a hedge. My bar-3(c) work in §3 above is the independent re-argument R2 says is still owed.

**Where I disagree, stated plainly:**

1. **Severity of the duʿā mismatch.** R2 lists the ids 26/49/60 duʿā defects in a single flat table row each, framed as disclosed-and-move-on ("none is fixable at draft level"). **I disagree with the implicit disposition, not the fact.** I do not think "not fixable at draft level" should collapse into "therefore ship as normal content." I am recommending `al-hakeem@1` and `al-khabeer@1` be **held** pending an explicit catalogue fix or founder sign-off — a stronger stance than R2 takes. I am *not* extending that same hold to `ash-shaheed@1`, because I judge that defect less severe (the duʿā's content, if not its vocative, is genuinely this Name's own action) — R2 does not draw that distinction between the two cases; it treats all three as one category of "structurally compromised, not fixable, disclosed." I think the severity differs enough between "duʿā invokes an entirely unrelated Name" (ids 26/49) and "duʿā's vocative is wrong but its content is this Name's own verb, and the collision is against a close conceptual sibling" (id 60) to warrant different verdicts, and R2 does not make that call.
2. **Bar 3(c) for `al-muhsi@1` vs `al-ghafur@1`.** R2 does not re-argue this at all — it is recorded only in `COLLISION-LEDGER.md` §9cd (authored by the same hand as the drafts) as a disclosed-and-resolved finding, and the `al-muhsi-DRAFT.md` itself grades it "⚠️ PASS." **I disagree with grading it a clean pass.** My independent reading in §3 rules it CONTESTED — survivable, but the thinnest separation in the batch, thinner than the ones the drafts themselves flagged as their weakest points elsewhere. Neither R2 nor the ledger's own §9cd entry pushes back on the drafter's own resolution of the finding it surfaced; I am doing that here, and my conclusion is more cautious than either document's.
3. **Coverage, not disagreement.** R2's scope is "54 pending drafts, ids 18–99," swept for source fidelity, narration authenticity, and completeness — it does not attempt the batch-specific, family-level bar-3(c) attack the brief for this review explicitly required (item 1: "no mechanical pass reaches it... attack that"). Where R2 is silent on a specific family-collapse question (e.g., the full six-Name "knows/sees/watches/counts/testifies/keeps/arranges" separation), that is a gap in R2's scope, not a claim R2 got wrong — I am flagging it as something this review adds rather than contradicts.

I found no case where R2 asserted a specific fetched fact that I could independently disprove. Every factual claim in R2 that overlaps my batch (the 34:1 fix, the three duʿā-mismatch facts) checked out against my own independent fetches.
