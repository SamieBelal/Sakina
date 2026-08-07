# Verdict — wave-f (the five hardest Names)

**Verifier:** blind adversarial pass, per `.context/VERIFIER-BRIEF.md`. Decks: `al-muhaymin` (id 18), `al-muqeet` (id 54), `al-wali` (id 83), `ar-rasheed` (id 99), `malik-ul-mulk` (id 88).

**Method note.** Every fetch below is a fresh `curl` against `api.quran.com/api/v4` (`text_uthmani` + `translations=20`, Saheeh International) or `corpus.quran.com/qurandictionary.jsp`, run in this session, not copied from any draft's table. `assets/content/name_stories.json` and `assets/content/collectible_names.json` were read directly and counted/diffed programmatically (Python), not eyeballed.

---

## 1 · Citation table

| # | Claim (as it reaches a beat) | Fetch | Text returned | ✅/⚠️/❌ |
|---|---|---|---|---|
| 1 | Al-Muhaymin beats 3–5: 5:48 "confirming... criterion over it" | `.../verses/by_key/5:48` | `وَأَنزَلْنَآ إِلَيْكَ ٱلْكِتَـٰبَ بِٱلْحَقِّ مُصَدِّقًا لِّمَا بَيْنَ يَدَيْهِ مِنَ ٱلْكِتَـٰبِ وَمُهَيْمِنًا عَلَيْهِ` + `فَٱحْكُم بَيْنَهُم...` (rest not rendered). English matches deck exactly. `مُهَيْمِنًا` grammatically modifies **الْكِتَـٰبَ** (the Book) | ✅ |
| 2 | Al-Muhaymin beat 6: "…the Overseer… — 59:23" | `.../verses/by_key/59:23` | `هُوَ ٱللَّهُ ٱلَّذِى لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْمَلِكُ ٱلْقُدُّوسُ ٱلسَّلَـٰمُ ٱلْمُؤْمِنُ ٱلْمُهَيْمِنُ ٱلْعَزِيزُ ٱلْجَبَّارُ ٱلْمُتَكَبِّرُ` — eight-epithet self-declaration, `ٱلْمُهَيْمِنُ` is the fifth | ✅ |
| 3 | Al-Muhaymin bar-5 successors 5:47 / 5:49 | `.../5:47`, `.../5:49` | 5:47 ends `فَأُو۟لَـٰٓئِكَ هُمُ ٱلْفَـٰسِقُونَ`; 5:49 closes `أَن يُصِيبَهُم بِبَعْضِ ذُنُوبِهِمْ`. Both about judges, neither rendered | ✅ |
| 4 | Al-Muhaymin root sweep — "2 occurrences, established by direct fetch because `corpus?q=hymn` fails" | `corpus.quran.com/qurandictionary.jsp?q=hymn` **and** `?q=hmn` | `q=hymn` → آدَم (wrong root, confirms the deck's warning). **`q=hmn` (no y) → ه م ن, and returns the correct dictionary page**: *"The triliteral root hā mīm nūn (ه م ن) occurs twice in the Quran... (5:48:11) wamuhayminan... (59:23:12) l-muhaymin..."* | ✅ — **count independently confirmed at exactly 2, and a working corpus code was found that the draft did not have** |
| 5 | Al-Muqeet beats 3–5: 41:10, whole āyah | `.../41:10` | `وَجَعَلَ فِيهَا رَوَٰسِىَ مِن فَوْقِهَا وَبَـٰرَكَ فِيهَا وَقَدَّرَ فِيهَآ أَقْوَٰتَهَا فِىٓ أَرْبَعَةِ أَيَّامٍ سَوَآءً لِّلسَّآئِلِينَ` — matches deck verbatim | ✅ |
| 6 | Al-Muqeet beat 6: 4:85 closing clause | `.../4:85` | `...وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ مُّقِيتًا` — matches, intercession clause correctly left unrendered | ✅ |
| 7 | Al-Muqeet root sweep — "exactly 2, both rendered" | `corpus.quran.com/qurandictionary.jsp?q=qwt` | *"The triliteral root qāf wāw tā (ق و ت) occurs twice in the Quran... (41:10:10) aqwātahā... (4:85:22) muqīt..."* | ✅ — **independently confirmed, exact match to the deck's claim** |
| 8 | Al-Muqeet bar-5: 4:84 fighting āyah, 41:9 `قُلْ`-polemic, 41:11 clean | `.../4:84`, `.../41:9`, `.../41:11` | 4:84 closes `أَشَدُّ تَنكِيلًا`; 41:9 opens `قُلْ أَئِنَّكُمْ لَتَكْفُرُونَ`; 41:11 is the smoke/heaven scene, clean | ✅ |
| 9 | Al-Muqeet: 4:86 belongs to `al-haseeb@1`, not rendered here | `.../4:86` + `2026-08-03-al-haseeb-DRAFT.md` | 4:86 closes `إِنَّ ٱللَّهَ كَانَ عَلَىٰ كُلِّ شَىْءٍ حَسِيبًا`. The haseeb draft's own sources table (line 72) independently states: *"4:85... closes مُّقِيتًا, Al-Muqeet's (id 54) Name-form. Left entirely."* — cross-confirms both decks' claims about each other | ✅ |
| 10 | Al-Wali beats 3–5: 10:3 up to `يُدَبِّرُ ٱلْأَمْرَ` | `.../10:3` | `إِنَّ رَبَّكُمُ ٱللَّهُ ٱلَّذِى خَلَقَ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ فِى سِتَّةِ أَيَّامٍ ثُمَّ ٱسْتَوَىٰ عَلَى ٱلْعَرْشِ ۖ يُدَبِّرُ ٱلْأَمْرَ` — matches; continuation (`مَا مِن شَفِيعٍ...فَٱعْبُدُوهُ`) correctly left off | ✅ |
| 11 | Al-Wali beat 6: 13:11, "there is not for them besides Him any patron" | `.../13:11` | Full āyah: `لَهُۥ مُعَقِّبَـٰتٌ...وَإِذَآ أَرَادَ ٱللَّهُ بِقَوْمٍ سُوٓءًا فَلَا مَرَدَّ لَهُۥ ۚ وَمَا لَهُم مِّن دُونِهِۦ مِن وَالٍ`. Confirmed: **negation**, `وَالٍ` is the Name-form, and the āyah **does** contain the "ill/evil" clause the deck discloses as an exposure in the same āyah being partially rendered | ✅ |
| 12 | Al-Wali bar-5: 10:2 (magician insult), 10:4 (scalding water + painful punishment) | `.../10:2`, `.../10:4` | 10:2 closes `إِنَّ هَـٰذَا لَسَـٰحِرٌ مُّبِينٌ`; 10:4 closes `شَرَابٌ مِّنْ حَمِيمٍ وَعَذَابٌ أَلِيمٌۢ` | ✅ |
| 13 | Al-Wali cross-check: `al-waliyy@1` "explicitly rejected 13:11" | `assets/content/name_stories.json` id 64 **and** `2026-08-03-al-waliyy-DRAFT.md` | **The SHIPPED `al-waliyy@1` (name_stories.json, `review_verdict: "good"`) never touches 13:11 at all** — its verse beat is 93:6, duʿā is Tirmidhī 3438/Muslim 1342. The rejection of 13:11 ("Negative construction... 2:107, 13:11, 32:4, 33:17... No. Nothing is demonstrated") is in the **pending, unshipped** `2026-08-03-al-waliyy-DRAFT.md`, lines 95 and 239 | ⚠️ — **claim is substantively true but mis-cited: it attributes a pending draft's reasoning to the shipped deck** |
| 14 | Ar-Rasheed beats 3–5: 18:16 (paraphrase), 18:17 (quoted) | `.../18:16`, `.../18:17` | 18:16 is the youths' own speech (`فَأْوُۥٓا۟ إِلَى ٱلْكَهْفِ...`), correctly described not quoted. 18:17: `وَتَرَى ٱلشَّمْسَ...مَن يَهْدِ ٱللَّهُ فَهُوَ ٱلْمُهْتَدِ ۖ وَمَن يُضْلِلْ فَلَن تَجِدَ لَهُۥ وَلِيًّا مُّرْشِدًا` — matches deck; second half (containing `مُّرْشِدًا`, the root!) correctly left unrendered | ✅ |
| 15 | Ar-Rasheed beat 6: 72:2, "It guides to the right course…" | `.../72:1`, `.../72:2` | 72:1: `قُلْ أُوحِىَ إِلَىَّ أَنَّهُ ٱسْتَمَعَ نَفَرٌ مِّنَ ٱلْجِنِّ فَقَالُوٓا۟...`. 72:2: `يَهْدِىٓ إِلَى ٱلرُّشْدِ فَـَٔامَنَّا بِهِۦ...`. **Confirmed: grammatical subject is the Qur'ān, speaker is the jinn, reported via `قُلْ`** — the weakest rung on the bar-1 ladder, and this is the deck's *only* root-bearing text | ✅ |
| 16 | Ar-Rasheed root sweep — "19 occurrences, 7 forms, all 3 `rashīd` human" | `corpus.quran.com/qurandictionary.jsp?q=r$d` | *"occurs 19 times... in seven derived forms... (11:78:26) rashīdun... (11:87:20) al-rashīdu... (11:97:10) birashīdin..."* — independently confirmed 19/7, and fetched 11:78/87/97 directly | ✅ |
| 17 | Ar-Rasheed: 2:186 spent by `al-mujeeb@1`; 18:10 spent by `ar-raheem@1` | `name_stories.json` ids 37, 3 | `al-mujeeb@1` beat 6 (`verse`): *"…indeed I am near. I respond to the invocation..."* sourced `Qur'an 2:186` — confirmed. `ar-raheem@1`'s `dua` beat renders `رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا` (= 18:10 verbatim, contains `رَشَدًا`) sourced `Qur'an 18:10` | ⚠️ — spends confirmed, but "**three story beats** and its duʿā" overstates it: only the `dua` beat literally quotes 18:10; the three `story` beats cite the *range* `18:10-25` without quoting 18:10's text |
| 18 | Malik-ul-Mulk beats 3–5, verse, duʿā: 3:26 doubly spent by `al-malik@1` | `.../3:26`, `name_stories.json` id 4, `collectible_names.json` id 4 & 88 | 3:26: `قُلِ ٱللَّهُمَّ مَـٰلِكَ ٱلْمُلْكِ تُؤْتِى ٱلْمُلْكَ مَن تَشَآءُ وَتَنزِعُ ٱلْمُلْكَ مِمَّن تَشَآءُ...`. `al-malik@1`'s `verse` beat quotes exactly this āyah (Saheeh, "Say, 'O Allah, Owner of Sovereignty...'"); its `dua` beat's `arabic` is byte-for-byte `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ` = `collectible_names.json` id 4's `dua_arabic` exactly | ✅ — **doubly-spent claim fully confirmed** |
| 19 | Malik-ul-Mulk: id 88's duʿā is "a strict prefix" of id 4's/`al-malik@1`'s duʿā | `collectible_names.json` ids 4 & 88 | id 4: `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ`. id 88: `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ`. **Id 4's string is character-for-character the first half of id 88's string** | ✅ — exact prefix relationship confirmed |
| 20 | Malik-ul-Mulk beats 3–6: 64:1 | `.../64:1`, `.../64:2` | `يُسَبِّحُ لِلَّهِ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۖ لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ` — sūrah-opening (no n−1 possible), `وَلَهُ ٱلْحَمْدُ` and `قَدِيرٌ` correctly left for other Names. 64:2 clean, closes `بَصِيرٌ` | ✅ |
| 21 | Bar 3(b) deck count: "45 decks swept" (all five decks) | `assets/content/name_stories.json` | `len(json.load(...))` = **45** | ✅ measured directly, matches every deck's claim |

---

## 2 · Five-bars verdicts

### Al-Muhaymin (id 18)

| bar | verdict | evidence |
|---|---|---|
| 1 | **CONTESTED — I do not resolve it, and neither should shipping proceed silently** | No single Allah-voiced text both names Allah *and* demonstrates the act. 5:48's `مُهَيْمِنًا` modifies `ٱلْكِتَـٰبَ` (confirmed by direct fetch — see citation #1); 59:23 predicates `ٱلْمُهَيْمِنُ` of Allah correctly but as the fifth of eight self-declared epithets in one clause (`هُوَ ٱللَّهُ...`), which the bar's own worked example ("…and Allah is the Fashioner" labels) targets. The deck's structure — using 5:48 to *define* and 59:23 to *attach* — is not the §9cg-sanctioned move (splitting bar-1-carrier from bar-4-carrier/story across texts); it is synthesizing bar 1's own two components (predication + demonstration) from two texts about two different subjects. That is a materially different, less-precedented move. My lean, stated as opinion not ruling: 59:23 is Allah's own self-declaration, not a narrated action with a trailing label, which is a real point in the deck's favour — but this is a founder-level call, exactly as the deck itself frames it. |
| 2 | PASS on the definition | 5:48 genuinely shows two functions (`مُصَدِّقًا` / `مُهَيْمِنًا`) operating in one clause |
| 3 | PASS | 45-deck sweep, max run 3 ("only the," confirmed present in `al-ghafur@1`'s takeaway — see below) |
| 4 | PASS, no trade | Root exhausted at 2 (independently confirmed via `q=hmn`), both occurrences rendered |
| 5 | PASS | 5:47/5:49 confirmed clean neighbours, neither rendered |

**Bar 3(b) spot check:** `al-ghafur@1`'s shipped takeaway reads *"...not **only the** forgiving — it is the covering..."* — confirms the claimed 3-word collision is real and as-described, not overstated.

**Independently resolved finding:** the brief called this "the project's most under-verified claim." **It no longer is.** `corpus.quran.com/qurandictionary.jsp?q=hmn` (drop the `y`) returns the correct ه‑م‑ن dictionary page and states the root occurs exactly twice, at the same two references the deck found by direct fetch. The deck's manual-fetch route and the corpus's own machine-readable count now agree independently.

**Ship verdict: NO-SHIP without an explicit editorial ruling on bar 1.** Not because I have found a defect the deck missed — I haven't, and its own framing is unusually honest — but because bar 1 is the deck's foundation and I cannot certify it as met. Nothing else to fix; the root is exhausted, so there is no alternate route to try.

### Al-Muqeet (id 54)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 41:10 `وَقَدَّرَ فِيهَآ أَقْوَٰتَهَا` — Allah's own narration of His own act, confirmed |
| 2 | PASS | narrated construction sequence, confirmed |
| 3 | PASS | measured below |
| 4 | **PASS, no trade, sweep complete** | corpus independently confirms exactly 2 occurrences, both rendered |
| 5 | PASS | 4:84, 41:9 confirmed unrendered rebuke/polemic; 41:11 confirmed clean |

**Bar 3(b):** 45 decks (confirmed). Claimed max run 3 ("is what," vs `al-quddus@1`) — not independently re-measured token-by-token, but the deck's own methodology is identical to the other four and produced verifiably correct results elsewhere, so I have no reason to doubt it.

**This is the strongest deck in the batch and the strongest bar-4 position I have seen across this whole review.** A complete two-occurrence root sweep, both occurrences rendered, independently reproduced from the corpus. No defect found.

**Ship verdict: SHIP.**

### Al-Wali (id 83)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 10:3's `يُدَبِّرُ ٱلْأَمْرَ` — Allah's own voice, present-continuous, confirmed. This is the §9cg-sanctioned split: bar-1 carrier (10:3, root د‑ب‑ر) is a *different* text from the bar-4 carrier (13:11, root و‑ل‑ي) — exactly the pattern the ledger's own precedent (As-Sabur, three overturned refusals) explicitly permits |
| 2 | PASS | continuing-governance construction shown, confirmed |
| 3 | PASS, with the noted `al-waliyy@1` boundary | see citation #13 — the cited rejection is real but is in a pending draft, not the shipped sibling |
| 4 | **PASS on a negation — defensible but genuinely thin** | 13:11 is confirmed a negation (`وَمَا لَهُم مِّن دُونِهِۦ مِن وَالٍ`). Bar 4's literal text only requires "the root appears in the quoted text," which it does. Whether a negated construction should count is a judgment call the deck flags honestly and does not hide |
| 5 | PASS, with a real disclosed wrinkle | 10:2/10:4 confirmed clean of rendering. **13:11 itself** — the very āyah partially rendered — contains `وَإِذَآ أَرَادَ ٱللَّهُ بِقَوْمٍ سُوٓءًا` immediately before the rendered clause; this is not a neighbour-successor finding, it is content in the *same* āyah, honestly disclosed |

**Correction owed to the deck:** its own citation of `al-waliyy@1` "explicitly rejecting 13:11" is not accurate as written — the shipped `al-waliyy@1` (in `name_stories.json`, `review_verdict: "good"`) never engages 13:11 at all. The rejection is real, but it lives in a **pending, unshipped** `2026-08-03-al-waliyy-DRAFT.md`. The substance of the argument (a negation is a weak bar-4 carrier) stands regardless of which document says it; the citation should be corrected before ship.

**Ship verdict: SHIP, with one correction required** (fix the `al-waliyy@1` citation from "drafted, rejected" to point at the actual pending draft, not imply the shipped deck ruled on it). This is a paperwork fix, not a scriptural one.

### Ar-Rasheed (id 99)

| bar | verdict | evidence |
|---|---|---|
| 1 | **I do not agree this is a clean PASS — I rule it CONTESTED, more seriously than the deck discloses** | 18:17, the deck's sole bar-1 carrier, demonstrates `مَن يَهْدِ ٱللَّهُ فَهُوَ ٱلْمُهْتَدِ` — root ه‑د‑ي (hidāyah), **not** ر‑ش‑د (rushd/rasheed). Confirmed by direct fetch. **Al-Hadi (id 33, "The Guide") is already shipped, and this deck's own bar-3(c) section insists hidāyah and rushd are different claims** ("Al-Hadi shows the way... this one is about what was arranged"). If the deck's own separation argument is right, then 18:17 demonstrates *Al-Hadi's* Name, not Ar-Rasheed's, and cannot honestly carry Ar-Rasheed's bar 1. The deck's own bar-4 row concedes as much in different words ("18:17's rendered clauses carry ه‑د‑ي, not ر‑ش‑د") but the bar-1 row still marks a plain PASS. That is inconsistent within the deck's own tables |
| 2 | Same concern carries through | the "shown, not stated" scene (the sun angled around the sleepers) is a hidāyah scene, not obviously a rushd scene |
| 3 | ⚠️ under-flagged | the deck's own bar-3 note calls `al-hadi@1` merely "close"; on my reading this is closer to a genuine root/engine overlap than the deck credits |
| 4 | **PASS, but thin and honestly disclosed** — the weakest bar-4 in the batch | 72:2 confirmed: `يَهْدِىٓ إِلَى ٱلرُّشْدِ`, subject is the Qur'ān, reported via `قُلْ` by the jinn (72:1 confirmed: `قُلْ أُوحِىَ إِلَىَّ أَنَّهُ ٱسْتَمَعَ نَفَرٌ مِّنَ ٱلْجِنِّ`). This is not merely "not predicated of Allah" — the bar-1 ladder's bottom rung ("any other human speech about Allah does not carry") does not even quite fit, because the *subject* of the clause is the Qur'ān, not Allah, and the speaker is not human at all. It is the single weakest text in this entire batch on any bar |
| 5 | PASS | 18:17's own unrendered second half (containing `مُّرْشِدًا`, the root!) confirmed left out; 72:1/72:3 confirmed clean |

**Root sweep independently confirmed:** 19 occurrences, 7 forms, `rashīd` 3× all human (11:78/87/97) — exact match to the deck's table.

**Both spend claims independently confirmed:** `al-mujeeb@1`'s verse beat is 2:186 verbatim (confirmed in `name_stories.json`); `ar-raheem@1`'s duʿā beat renders 18:10 verbatim, containing `رَشَدًا`. One overstatement: the deck says 18:10 is spent by "three story beats **and** its duʿā" — only the duʿā beat literally quotes 18:10; the three story beats cite the *range* `18:10-25` as a label, without quoting 18:10's actual words. Minor, but worth correcting.

**Ship verdict: HOLD.** Not because of the traded bar 4 — that trade is honestly disclosed and about as forced as a trade can be (root sweep complete at 19, both Allah-voiced routes spent). The problem is bar 1: the deck's only candidate for "the Name demonstrated in Allah's own words" is, on inspection, a demonstration of a *different, already-shipped* Name's root. I could not find, in the material available to me, a text where Allah's own voice predicates guidance using the rushd root at all (2:186 and 18:10 are exactly that, and both are spent). This may be a genuine refusal candidate — the deck gestures at this ("if a verifier reasonably holds this is not bar 4 at all," "the weak point") but does not go far enough, because the weak point is bar 1, not only bar 4.

### Malik-ul-Mulk (id 88)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 64:1's `لَهُ ٱلْمُلْكُ` — Allah's own voice, contrast against a sūrah-opening list of everything that only acts, confirmed |
| 2 | PASS | grammatical contrast (verb for everything else, possession only for Allah) confirmed structurally |
| 3 | PASS on the beats, collision on the duʿā by construction | 45-deck count confirmed (21) |
| 4 | **PASS claimed "on the root," but I read this as thinner than stated** | `ٱلْمُلْكُ` (64:1) is confirmed present — but it is the **verbal noun** ("dominion/sovereignty"), not the **active participle** `مَالِك` ("owner") that opens this catalogue Name's own two-word form (`مَالِكُ الْمُلْكِ`). Elsewhere in this same batch (Ar-Rasheed) the verifier standard applied is that a *different derived form* of a shared root does not automatically carry a Name — the deck's own logic for Ar-Rasheed's weakness should, by consistency, apply here too. I do not think this deck's bar 4 is "met on the root, traded only on the compound" as stated; I think it is **traded**, full stop — disclosed responsibly either way, and the outcome (ship/no-ship) is the same |
| 5 | **PASS** | 64:1 confirmed sūrah-opening (no possible n−1); 64:2 confirmed clean, no punishment |

**Both headline claims independently confirmed exactly:** 3:26 doubly spent by `al-malik@1` (verse beat + duʿā, both confirmed byte-for-byte against `name_stories.json` and `collectible_names.json`), and id 88's duʿā is a **character-for-character strict prefix extension** of id 4's — I diffed both strings directly.

**On the general rule proposed (§ finding 6 in the brief):** *"before shipping any deck, check whether its carrier is the only carrier for a Name it shares a duʿā or a root with."* **I endorse this as sound and worth adopting**, with one addition: because most of the catalogue's 99 Names have no deck yet, the check cannot be scoped to "the 45 shipped decks vs each other" — it has to be each new deck's rendered text and duʿā swept against **all 99** `collectible_names.json` entries (not only the ~45–54 that currently have prose), because the collision that bit this deck (a shipped Name's duʿā already containing an *unstarted* Name's full string) is invisible to a deck-vs-deck sweep and only visible in a deck-vs-full-catalogue sweep. Cheap to run, and would have caught this at `al-malik@1`'s draft time in April, long before this deck existed.

**Ship verdict: SHIP, with the duʿā-prefix collision surfaced to product/founder as a catalogue-level issue, not a draft-level defect.** The deck has done what a single draft can do — a different story (64:1's hadith-free contrast) and a different verse citation from its sibling. The unfixable part (the duʿā prefix, and the compound Name's sole occurrence being spent) is locked at the catalogue layer and correctly reported as such, not engineered around.

---

## 3 · Ḥadīth check

**None of the five decks in this batch renders a ḥadīth on any beat.** All five explicitly disclose "No ḥadīth fetched" in their "what I could not determine" sections. I confirmed this by reading every beat in all five drafts — no `sunnah.com` citation appears on any rendered `story`, `verse`, or `dua` beat. Nothing to grade.

---

## 4 · Bar 3(b) — measured

**45.** Counted directly: `len(json.load(open('assets/content/name_stories.json')))` = 45. This matches every one of the five decks' stated sweep count.

---

## 5 · Ship/no-ship summary

| deck | verdict | what would fix it |
|---|---|---|
| Al-Muhaymin (18) | **HOLD** | Founder ruling on whether an eight-epithet Allah-voiced self-declaration (59:23) plus a Book-referent demonstration (5:48) together satisfy bar 1. No alternate route exists — root is exhausted at 2. |
| Al-Muqeet (54) | **SHIP** | Nothing found. Strongest deck in the batch. |
| Al-Wali (83) | **SHIP** | Correct the `al-waliyy@1` citation to point at the pending draft, not imply the shipped sibling ruled on 13:11. |
| Ar-Rasheed (99) | **HOLD** | Bar 1's sole candidate (18:17) demonstrates a different, already-shipped Name's root (Al-Hadi's ه‑د‑ي), not this Name's own ر‑ش‑د. Needs either a genuine Allah-voiced rushd-root text I did not find, or an honest refusal. |
| Malik-ul-Mulk (88) | **SHIP** | Surface the duʿā-prefix collision with `al-malik@1` to product as a catalogue-level open item; no draft-level fix exists. |

---

## 6 · What I could not verify

- **I did not re-run the full bar-3(b) 45-deck token-frequency sweep programmatically for every beat of every deck** — I spot-checked two claimed collisions (Al-Muhaymin vs `al-ghafur@1`, Al-Wali vs `al-aleem@1`) and both were confirmed exactly as described, but I did not re-derive the maximum shared word-run for all nine beats × 45 decks × 5 drafts from scratch. I trust the method because it reproduced correctly on every spot check, not because I re-ran it in full.
- **I did not sweep any of the five decks' rendered text against the 48 pending drafts**, only against the two pending drafts (`al-haseeb`, `al-waliyy`) that the decks themselves cite by name, both of which I read directly and both of which confirmed the citing deck's claim (with the al-waliyy caveat above).
- **I did not independently verify the `م-ل-ك` (206 occurrences) or `و-ل-ي` (232 occurrences) claims** — both are disclosed by their decks as "not swept, incomplete by design," and I have no basis to add or subtract from an unswept claim.
- **I did not fetch a hadith route for any of the five Names** — none is rendered, so there was nothing on a beat to check, but I also did not independently search `sunnah.com` for a *better* hadith route that might rescue Al-Muhaymin's or Ar-Rasheed's contested bar 1. That search was out of scope for a verification pass and would be original drafting work.
- **On Malik-ul-Mulk's bar 4, my "traded, full stop" reading versus the deck's "met on the root" reading is a judgment call I am not certain of** — Qur'ānic usage sometimes treats a verbal noun and its cognate participle as interchangeable evidence of "the root," and I have not found a ruling elsewhere in this project that settles which standard applies to a two-word construct Name. I flagged the inconsistency with how Ar-Rasheed's derived-form question is treated, but a stronger authority than me should settle it once, in the ledger, so it stops being re-litigated per deck.
- **I did not check whether Al-Wali's `و-ل-ي` boundary with `al-waliyy@1` creates any bar-3(a) Arabic-root collision** beyond what the deck already disclosed as "incomplete on the root by design."

---

## 7 · Reconciliation with `2026-08-04-R2-VERIFICATION.md`

**Where I agree.** R2 §4 explicitly flags, as unresolved and as exactly where a blind verifier should go first: *"al-muhaymin@1's bar 1 has the Book, not Allah, as 5:48's referent."* I agree, and I went further than R2 did — I independently reproduced the root-count-of-2 finding via a **working corpus code** (`hmn`, not `hymn`), which R2 does not mention finding. R2 also correctly notes (§0) that its own bar-1/bar-3(c)/bar-5 judgements are "not reliable" precisely because the reviewer authored most of the wave — I treat that self-assessment as accurate and my job as filling exactly that gap.

**Where I disagree, or go further than R2.**

1. **R2 never flags Ar-Rasheed's bar 1 at all.** R2 §4's "where a blind verifier should go first" list mentions Ar-Rasheed only for its **traded bar 4** ("`as-sabur@1`'s and `ar-rasheed@1`'s traded bar 4"), grouping it with As-Sabur's already-adjudicated, ledger-blessed trade pattern. It does not surface that Ar-Rasheed's bar-1 carrier (18:17) demonstrates a *different Name's root* (ه‑د‑ي, Al-Hadi's) rather than its own (ر‑ش‑د). This is, in my reading, a more serious and more specific problem than "traded bar 4," and R2 missed it — or at least did not name it.
2. **R2 does not surface the `al-waliyy@1` shipped-vs-draft citation confusion** in Al-Wali. This is a small, fixable documentation error, but it is exactly the kind of "the deck's own tables agree with each other and disagree with the underlying fact" pattern R2's own §9ch finding (the 11:73/85:15 misquotation) warns about — here it is a cross-document citation rather than a beat-vs-source mismatch, but the shape of the failure (confident cross-reference to a document that does not say what is claimed) is the same family.
3. **R2 does not weigh in on Malik-ul-Mulk's "root vs compound" bar-4 distinction** at the level of derived-form rigor — it is not in R2's scope (R2 predates or does not cover this specific deck's bar-4 argument in detail). I raise it here as a new finding, not a disagreement with something R2 said.
4. **I have somewhat more confidence than R2's phrasing suggests in Al-Muqeet.** R2 does not single it out, but on my independent check it is the cleanest deck I reviewed anywhere in this pass — complete root sweep, both occurrences rendered, no ambiguity on any bar. Worth noting as a positive contrast to the four contested/traded Names in this same wave.
5. **On the general "unstarted Name's ground" rule** (R2 doesn't discuss this — it's from this wave's own drafting notes, not R2): I endorse it, but note R2's own method (§1, "Qurʾān fidelity... 207 āyāt fetched... substring-matched against its own cited āyah") is deck-by-deck and would not have caught the al-malik@1/id-88 duʿā-prefix collision either, since that requires a catalogue-vs-catalogue sweep, not a deck-vs-source sweep. This is a gap in R2's method as much as in the original drafting, worth fixing once at the process level rather than per-verifier.
