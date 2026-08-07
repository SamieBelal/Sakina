# `al-quddus@1` — Al-Quddus (catalogue id 5, *The Most Holy*) — DRAFT

**Drafted 2026-08-03**, wave 3, by the agent holding **id 1 + id 5**.
**Companion deliverable:** [`2026-08-03-allah-name-id-1-REFUSAL.md`](./2026-08-03-allah-name-id-1-REFUSAL.md) — id 1
is **not drafted**; that file is the reasoned refusal and its enumeration.
**Claim file:** [`.context/claims/5.md`](../../../../.context/claims/5.md).
**Governing:** plan `2026-08-02-name-story-decks.md` §5–§7 · `COLLISION-LEDGER.md` §§1–9as ·
spec `2026-07-25-name-stories-deck-format.md`.

All scripture below was **fetched live at draft time**. Qurʾān: `api.quran.com/api/v4` (Saheeh
International, resource `20`). Ḥadīth: **Wayback captures of the exact bare `sunnah.com` numbers**,
retrieved through the **CDX API** and decoded through `zstd -d`. Nothing was composed, reconstructed
or recalled.

---

## 0 · The one-line finding, before anything else

**Catalogue id 5's `dua_arabic` is not an authored invocation. It is Ṣaḥīḥ Muslim 487 a.**

Selection ran duʿā-first, per the standing rule, and this is the **sixth** Name in the project whose
duʿā turns out to be scripture (after ids 4, 10, 14, 37, 64). **A pin is proposed** (§7).

---

## 1 · The two errors repaired on this card this week — neither is reintroduced

| the error | what the fetched page actually says | where this deck stands |
|---|---|---|
| the words are the **angels'** | `أَنَّ عَائِشَةَ نَبَّأَتْهُ أَنَّ رَسُولَ اللَّهِ ﷺ كَانَ يَقُولُ فِي رُكُوعِهِ وَسُجُودِهِ` — **ʿĀʾisha** reports that **the Prophet ﷺ** used to say it **in his bowing and his prostration** | no beat attributes these words to angels. Beat 7's `label` names the Prophet ﷺ and the two postures. |
| ***"Holy, Holy, Holy"*** | the page's English is *"All Glorious, All Holy, Lord of the Angels and the Spirit."* The Arabic is two words, `سُبُّوحٌ قُدُّوسٌ`, **each once** | **no beat of this deck repeats any word three times.** Measured: the string `Holy` occurs **twice** in the whole deck — beat 2's `name_intro` (*The Most Holy*) and beat 7's catalogue-locked duʿā. Never adjacently, never three times. |

*"Holy, Holy, Holy"* is **Isaiah 6:3**. It is in **no** collection on sunnah.com. This deck asserts it
nowhere.

---

## 2 · The deck

| # | kind | rendered `primary` | `arabic` | `source` |
|---|---|---|---|---|
| 0 | `bridge` | Some of what you are carrying is the thing itself. Some of it is what you think it has done to Him. | — | — |
| 1 | `name_intro` | **The Most Holy** | `الْقُدُّوسُ` | — |
| 2 | `story` | There is a narration in which the Prophet ﷺ reports the words of Allah Himself, in the first person. Of one of the men who carried it — Abu Idris al-Khawlani — the text keeps a single detail: when he narrated it, he knelt upon his knees. | — | Sahih Muslim 2577a |
| 3 | `story` | "O My servants, were the first of you and the last of you, the human of you and the jinn of you to be as pious as the most pious heart of any one man of you, that would not increase My dominion in anything…" | — | Sahih Muslim 2577a |
| 4 | `story` | "…were the first of you and the last of you, the human of you and the jinn of you to be as wicked as the most wicked heart of any one man of you, that would not decrease My dominion in anything." The same sentence, said twice. Three words change: *pious* becomes *wicked*, and *increase* becomes *decrease*. The answer does not move. | — | Sahih Muslim 2577a |
| 5 | `verse` | Their meat will not reach Allāh, nor will their blood, but what reaches Him is piety from you… | — | Qur'an 22:37 (of the animals given in sacrifice) |
| 6 | `dua` | Glorified, Holy, Lord of the angels and the spirit. | `سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلَائِكَةِ وَالرُّوحِ` | **Sahih Muslim 487a** |
| 7 | `takeaway` | Abu Idris knelt every time he repeated this — right after saying, in the same breath, that nothing anyone does moves Allah at all. He was not bargaining with Him. He knelt because a man who has just heard the truth about his own smallness still has a body, and a body has to do something with that. Kneel too. Not to move Him. To answer what you just heard. | — | — |

**⚠️ Beat 7 REPLACED 2026-08-03, post-verifier.** The original beat 7 (*"Nothing anyone has ever
done has made Him more…It is the piety from you."*) is struck from the rendered deck. It is kept,
struck through, in §9d together with the verifier's ruling and the replacement rationale. **This is
a new beat, not a reword** — the required fix; see §9d and §13.

**Beat labels** (not scripture; the fields shipped decks use for provenance):

- beat 1 — `catalog id 5, verbatim`
- beat 2 — `It would not increase My dominion` · **re-rendered from the page's Arabic** (plan §6 rule 2), see §5
- beats 3–4 — `It would not increase My dominion` · Saheeh-of-the-page English, verbatim, elisions marked
- beat 5 — `excerpt, marked — the closing clause is omitted; see §6`
- beat 6 — `catalog id 5, verbatim in full — the words the Prophet ﷺ said in his bowing and his prostration, Sahih Muslim 487a`

**Structure note.** Eight beats, `bridge · name_intro · story ×3 · verse · dua · takeaway` — the
`al-haleem@1` shape. **No protagonist in the quoted divine speech**, the shape shipped by
`al-haleem@1`, `al-wasi@1` and `al-malik@1`. Beat 7 is a **plain takeaway, not a pair-synergy beat**
(26 of 34 shipped decks do the same).

---

## 3 · `Claim | Source | Grading | Status`

| # | claim | source (as rendered) | URL fetched | grading | status |
|---|---|---|---|---|---|
| 1 | Beat 6's Arabic is the catalogue's `dua_arabic` for id 5, byte-identical | `collectible_names.json` id 5 | local asset | — | ✅ **verified** — read programmatically from the asset and string-compared; the gate asserts this bidirectionally. |
| 2 | That same Arabic is **Ṣaḥīḥ Muslim 487 a**, to within **one orthographic word** | Sahih Muslim 487a | `web.archive.org/web/20260210003623id_/https://sunnah.com/muslim:487a` | ṣaḥīḥ (Ṣaḥīḥ Muslim) | ✅ **verified, and measured.** 5 words vs 5 words. **Four are byte-identical.** Word 4 differs **only in mark placement**: catalogue `الْمَلَائِكَةِ` (ل ـَ ا ئ) vs page `الْمَلاَئِكَةِ` (ل ا ـَ ئ) — the fatḥa sits before vs after the alif. **Rasm identical; skeleton-folded strings compare equal.** Same shape and same size as the `al-aleem@1` pin (one orthographic word). |
| 3 | Muslim 487a is narrated by **ʿĀʾisha**, of **the Prophet ﷺ**, said **in rukūʿ and sujūd** | Sahih Muslim 487a | as above | ṣaḥīḥ | ✅ **verified on the page**, Arabic and English both. Chapter: `باب مَا يُقَالُ فِي الرُّكُوعِ وَالسُّجُودِ`. **⚠️ Disclosure: the page prints NO grade line.** *Ṣaḥīḥ* here is a **collection-level inference** from Ṣaḥīḥ Muslim, not a printed verdict — the same disclosure `al-khaliq@1` made for Bukhārī 6227. |
| 4 | Beats 3–4 are Ṣaḥīḥ Muslim 2577 a, Saheeh-of-the-page English, **verbatim within the quoted spans** | Sahih Muslim 2577a | `web.archive.org/web/20260801213232id_/https://sunnah.com/muslim:2577a` | ṣaḥīḥ (Ṣaḥīḥ Muslim) | ✅ **verified — substring test run programmatically** against the extracted page English. **⚠️ Same no-printed-grade disclosure as row 3.** |
| 5 | `sunnah.com/muslim:2577` (bare) and `muslim:2577a` are the **same ḥadīth** | — | both captures fetched (`20260207230351`, `20260801213232`) | — | ✅ **verified by fetching both.** Both pages render the heading *"Sahih Muslim 2577 a"* and identical Arabic. Recorded because the plan's own rule (`muslim:2653` ≠ `muslim:2653b`) makes this the check that must not be skipped. **2577b and 2577c exist and are different chains; neither is used.** |
| 6 | Beat 2's kneeling detail is on the same page | Sahih Muslim 2577a | as above | ṣaḥīḥ | ✅ **verified.** Arabic: `قَالَ سَعِيدٌ كَانَ أَبُو إِدْرِيسَ الْخَوْلاَنِيُّ إِذَا حَدَّثَ بِهَذَا الْحَدِيثِ جَثَا عَلَى رُكْبَتَيْهِ`. Page English: *"Sa'id said that when Abu Idris Khaulini narrated this hadith he knelt upon his knees."* **⚠️ Beat 2 re-renders the name as *Abu Idris al-Khawlani* and drops the transmitter's name *Saʿīd* from the beat.** Both are disclosed here; neither changes what is asserted. |
| 7 | Beat 5 is Qurʾān 22:37, Saheeh International, **exact prefix**, with a marked elision | Qur'an 22:37 | `api.quran.com/api/v4/verses/by_key/22:37?translations=20` | Qurʾān | ✅ **verified — `clean.startswith(beat)` returned True programmatically.** 22:37 carries **no `<sup>` marker at all**. Omitted tail, quoted in full: *". Thus have We subjected them to you that you may glorify Allāh for that [to] which He has guided you; and give good tidings to the doers of good."* **The ellipsis is ON THE BEAT.** |
| 8 | The successor sweep on 22:37 | 22:36 · 22:38 · 22:39 | fetched individually | Qurʾān | ✅ **run — see §6.** |
| 9 | Bar 4 is traded, and the `q-d-s` sweep proving it forced | full Uthmānī text | 6,236 āyāt assembled locally from `verses/by_chapter` | Qurʾān | ✅ **run against the FULL TEXT, not a search API** — see §8. **10 āyāt, enumerated by form.** |
| 10 | Bar-3 English pass | all **34** decks in `assets/content/name_stories.json` | local asset | — | ✅ **run — 734 rendered strings, all fields. Zero 4-gram hits and zero 5-gram hits.** See §9. |
| 11 | Deck-internal beat-to-beat diff (§9v / §9al) | this deck | — | — | ✅ **run over all 28 pairs.** One overlap, deliberate and stated on screen — see §9c. |
| 12 | **Not on any beat** — Muslim 2577a's other six `يَا عِبَادِي` clauses | Sahih Muslim 2577a | same capture | ṣaḥīḥ | ✅ **read in full and deliberately excluded** — reasons and exact texts in §5. |
| 13 | Catalogue check: id 5's `hadith` field | Sahih Muslim 487a | same capture | ṣaḥīḥ | ✅ **verified as repaired.** The card now correctly says *ʿĀʾisha … the Prophet ﷺ … while bowing and prostrating*, and cites *(Sahih Muslim 487a — Sahih)*. **No catalogue change is recommended for id 5.** |

**No claim in this table is inherited from another agent's report.** Every ✅ describes a command I
ran or a page I read.

---

## 4 · The five bars

| bar | verdict | the evidence, stated as a measurement |
|---|---|---|
| **1 — the Name's act demonstrated in the cited text, in Allah's words** | **MET, at the strongest form this Name admits** | The bar-1 carrier is **beats 3–4, which are Allah's own first-person speech** (`فِيمَا رَوَى عَنِ اللَّهِ تَبَارَكَ وَتَعَالَى أَنَّهُ قَالَ`) — a ḥadīth qudsī, the same class as `al-kareem@1`'s Bukhārī 1145. **No epithet carries it and no prose of this deck carries it.** Beat 5 adds a second, Qurʾānic carrier: `لَن يَنَالَ ٱللَّهَ … وَلَـٰكِن يَنَالُهُ` — **two finite verbs with Allah as the explicit object of reaching**, in Allah's own narration. ⚠️ **The limit, stated plainly:** Al-Quddus predicates a **negation** — freedom from deficiency — so its "act" can only ever be shown as an *unaffectedness*, never as a verb of Allah's doing. **I am not claiming a verb of Allah's action from the Name's own root exists. §8 proves none does.** |
| **2 — shown, not stated** | **MET** | Beats 3–4 do not say *He is free of imperfection*. They run a thought experiment with a stated result: every human and jinn, first and last, at the maximum of piety → **no increase**; at the maximum of wickedness → **no decrease**. Beat 5 does not say *He is beyond the material*; it names two material things and says they do not arrive. **This is the bar that killed `al-haleem@1` rev 1 and blocked 24:35, and it is the reason 59:23 and 62:1 are refused in §8** — those *state* the attribute as an epithet. |
| **3 — no collapse into a sibling Name** | **MET on all three surfaces. Surface 3's disclosed adjacency was RULED BLOCKING by the independent verifier and is now fixed by a new beat 8 (this deck's 0-indexed beat 7).** | §9. Roots: clean. Tokens: **zero 4-gram hits across 734 rendered strings of 34 decks**; `holy` `pure` `piety` `pious` `wicked` `dominion` `increase` `decrease` `meat` `knelt` `knees` `jinn` all **n=0** (against the ORIGINAL beat 7 — see §9d for the corresponding sweep on the replacement). **The move: `al-kareem@1` beat 7 and this deck's original beat 7 both landed on *He is not diminished*.** §9d stated it at full strength and, per §9ab/§9aq, declined to self-clear it. **The verifier ruled BLOCKING (2026-08-03) and required a new beat, not a reword; §9d and §13 record the ruling and the replacement, built from the unspent kneeling detail in beat 2 — a different move (embodied response, not a claim about Allah's unaffectedness).** |
| **4 — the Name's root in the source text** | **TRADED, and the sweep proving it forced is in §8** | The Name's root appears in **neither** source text. **It is FORCED:** across all 6,236 āyāt there are exactly **10** `q-d-s` occurrences; the Name-word predicated of Allah occurs **twice** (59:23, 62:1) and **both are appositive epithets inside a Name-chain** — bar 1's named failure. Every other form is predicated of a **place**, of the **Spirit**, or is the **angels' speech**. **Partial recovery, stated precisely:** the root **does render on beat 6**, in Arabic (`قُدُّوسٌ`) and in English (*Holy*), and beat 6's pinned source Muslim 487a carries it. Precedent for the trade: `al-haleem@1`, `al-waliyy@1`, `ar-raqeeb@1`. |
| **5 — register / reverence** | **MET** | No battle, no punishment, no curse, in either text or in any neighbour that is quoted. Muslim 2577a's chapter is *The Prohibition of Oppression* and its opening clause is `حَرَّمْتُ ٱلظُّلْمَ عَلَىٰ نَفْسِي` — a self-imposed prohibition, not a threat. 22:37's own ending is **good tidings**. §6 records the two neighbours worth naming and **§6a names the row a reviewer should attack first.** |

---

## 5 · What is quoted, what is omitted, and why — Muslim 2577a

The narration has **nine** `يَا عِبَادِي` clauses. **Three reach a beat.** Here is every one of the
six that does not, with its exact text, so nothing is hidden behind the word *"excerpt"*.

| clause | page English | on a beat? | why |
|---|---|---|---|
| 1 | *"I have forbidden oppression for Myself and have made it forbidden amongst you, so do not oppress one another."* | **no** | different Name (Al-ʿAdl / Al-Muqsiṭ, ids 48 / 90 — both **BLOCKED** on the duʿā axis and therefore not being taken from anyone). |
| 2 | *"all of you are astray except for those I have guided, so seek guidance of Me and I shall guide you"* | **no** | **bar 3.** `h-d-y` and the English *guide/guided* — shipped **`al-hadi@1`**'s Name and Name-verb. `guide` renders in **6** decks. |
| 3 | *"all of you are hungry except for those I have fed…"* | **no** | `ar-razzaq@1` (shipped) and `al-mughni@1` (wave 1). |
| 4 | *"all of you are naked except for those I have clothed…"* | **no** | same reason as 3. |
| 5 | *"you sin by night and by day, and I forgive all sins, so seek forgiveness of Me and I shall forgive you"* | **no** | **bar 3, and it is the sharpest one in the narration.** `gh-f-r` is carried by **four** decks, and shipped **`al-ghaffar@1`'s verse beat (39:53)** renders *"Indeed, Allāh forgives all sins."* This clause's English is *"I forgive all sins."* **That is the *"do not lose hope in the mercy of Allah"* class — a substantive clause on two screens — and it is avoided by omission, not by rewording.** |
| 6 | *"you will not attain harming Me so as to harm Me, and will not attain benefitting Me so as to benefit Me"* | **no** | **This is the one I most wanted and gave up, and the reason is a measurement.** `harm` is a **corpus hapax, n=1** (`al-wakeel@1` beat 4, *"suffering no harm"*), and `benefit` is a **corpus hapax, n=1** (`al-kareem@1` beat 5, *"[the benefit of] himself"*). One beat would have doubled **both** hapaxes at once. §9ab ruled a single-token hapax (`afraid`, n=1) **blocking** on that evidence alone. **Omitted on that precedent, before a verifier had to find it.** |
| 7 | *"…as pious as the most pious heart… would not increase My dominion in anything"* | **beat 3** | the deck. |
| 8 | *"…as wicked as the most wicked heart… would not decrease My dominion in anything"* | **beat 4** | the deck. |
| 9 | *"…to rise up in one place and make a request of Me, and were I to give everyone what he requested, that would not decrease what I have, any more that a needle decreases the sea if put into it."* | **no** | **the needle and the sea.** `.context/claims/57.md` and `.context/claims/93.md` both record it as **`al-kareem@1` beat 7's substance**. It is not mine to spend and it reaches no screen. |
| closing | *"it is but your deeds that I record for you and then recompense you for. So let him who finds good, praise Allah, and let him who finds other than that blame no one but himself."* | **no** | the narration's own ending. **Not punishment**, but it is an admonition and it would pull the deck toward reckoning. |

**Every elision is marked with a visible `…` on beats 3 and 4.** Beat 3 ends `…"` and beat 4 opens
`"…`. **The user sees that the quotation is partial.** (Plan §7 / batch-2 rule 2.)

**Beat 2 is re-rendered from the page's Arabic** rather than pasted: the page's English spells the
transmitter *"Abu Idris Khaulini"* and opens *"Sa'id said that…"*. The beat renders
`كَانَ أَبُو إِدْرِيسَ الْخَوْلاَنِيُّ إِذَا حَدَّثَ بِهَذَا الْحَدِيثِ جَثَا عَلَى رُكْبَتَيْهِ` as
*"when he narrated it, he knelt upon his knees."* **Nothing is added; `Saʿīd`'s name is dropped and
that is disclosed in §3 row 6.**

---

## 6 · Successor sweep — Qurʾān 22:37

| | text | the three questions |
|---|---|---|
| **n−1 · 22:36** | *"And the camels and cattle We have appointed for you as among the symbols [i.e., rites] of Allāh… then eat from them and feed the needy… Thus have We subjected them to you that you may be grateful."* | **Fetched because 22:37 opens on an unexplained pronoun** (*"Their meat…"*). 22:36 is its antecedent: the sacrificial animals. **No punishment, no rebuke.** ⚠️ **This is why the beat's `source` reads `Qur'an 22:37 (of the animals given in sacrifice)`** — the precedent is shipped `al-baseer@1`, whose `source` is *"Qur'an 58:1 (revealed for a woman whose complaint the person in the same room could not hear)"*. **The antecedent is supplied in the `source`, not interpolated into the quotation.** |
| **n+1 · 22:38** | *"Indeed, Allāh defends those who have believed. Indeed, Allāh does not like everyone treacherous and ungrateful."* | Q1 **no contradiction** — it continues in the same direction (protection of believers). Q2 nothing left open. Q3 — see the elision row below. ⚠️ **Disclosed:** the āyah's second half is a statement of what Allah does not like. **That is not punishment**, and it is softer than shipped `al-afuw@1`'s 42:26 (*"the disbelievers will have a severe punishment"*), which the ledger records as non-blocking. |
| **n+2 · 22:39** | *"Permission [to fight] has been given to those who are being fought, because they were wronged…"* | ⚠️ **Disclosed at full strength: two āyāt after this deck's verse beat, Sūrat al-Ḥajj turns to the permission to fight.** It is **not quoted, not alluded to, and not the successor.** Calibration: shipped `al-wakeel@1` sits **immediately after Uḥud** and shipped `al-fattah@1` at Ḥudaybiyyah; `al-mughni@1`'s bar 5 was **ACCEPTED** in ledger §9a on a setting closer to war than this one. |
| **the elision · Q3** | the beat stops before *"Thus have We subjected them to you that you may glorify Allāh for that [to] which He has guided you; and give good tidings to the doers of good."* | **Q3 answered honestly: yes, the beat stops short of the āyah's own ending — and the ending is BENIGN.** It is not a reversal; it is *good tidings*. **So the elision is not a bar-5 rescue. It is a bar-3 necessity, and it is forced:** the omitted clause renders *"He has guided you"*, and **shipped `al-hadi@1`'s verse beat is 22:54 — the same sūrah, 17 āyāt away — rendering *"And Allah surely guides the believers to the Straight Path."*** Quoting 22:37 in full would put Al-Hādī's own verb on a **second** verse beat in the **same sūrah**. Ledger §9o's table calls a shared substantive clause **blocking**. **Measured:** `guide` n=6 decks, `guided` n=1 (near-hapax, `al-mughni@1`). |

⚠️ **Sūrat al-Ḥajj now carries two decks** — `al-hadi@1` at 22:54 (shipped) and this deck at 22:37.
**17 āyāt apart.** Precedent: az-Zumar, 11 āyāt apart, **disclosed and accepted** (ledger §2c).
Also recorded there: 22:59, 22:65 and 22:78 are already on the ledger's rejection list, so this sūrah
has been worked before and 22:37 was not found by anyone.

**Ḥadīth carry no successor sweep obligation** (precedent `al-haleem@1` / Bukhārī 7378). Muslim 2577a
is nonetheless *internally* continuous, so **§5 enumerates every clause I did not quote** rather than
leaving "excerpt" to do the work.

### 6a · The bar-5 row a reviewer should attack first

**It is 22:39.** Not because it is quoted — it is not — but because a rule that forbids *"the arc
terminates in punishment just outside the excerpt"* has to say what *just outside* means, and this
deck sits **n+2** from a permission to fight. My argument is that the āyah's **actual** successor
(22:38) is protection, that 22:39 is a legal permission rather than a punishment or a curse, and
that shipped decks sit closer to war than this. **I state it as an argument, not a 404.** The
strongest version of bar 5 — a sūrah-final 404 — is not available here.

---

## 7 · The duʿā — PIN PROPOSED

**`renderedDuaSources` addition proposed: `'al-quddus@1': "Sahih Muslim 487a"`.**

**Why a bare pin and not a `cf.`:** the difference between the catalogue string and the page is
**one orthographic word, mark placement only, rasm identical** (§3 row 2). That is the same size of
difference as `al-aleem@1`'s approved pin (`السَّمَاوَاتِ` vs `السَّمَوَاتِ`) and **smaller** than
`ash-shafi@1`'s, which took `cf.` for differing wording *and* clause order. **Nothing is truncated**,
so no `(opening)` qualifier is needed either.

**What the pin tells the user:** the words on beat 6 are not an authored supplication written for a
card. **They are what the Prophet ﷺ said with his forehead on the ground.** That is the deck's whole
arc and the pin is the only place it can be said in a rendered field.

**This is a recommendation about `renderedDuaSources` — a test fixture — NOT about
`collectible_names.json`.** Per COLLISION-LEDGER §8.4 / §9d, **three of three (now four of four)
confident recommendations to change catalogue data have been wrong.** **I make none.** Id 5's card,
duʿā, `meaning` and `lesson` are left exactly as they are.

⚠️ **One catalogue observation, reported with NO change recommended:** id 5's `dua_translation`
reads *"Glorified, Holy, Lord of the angels and the spirit."* The sunnah.com page renders the same
Arabic *"All Glorious, All Holy, Lord of the Angels and the Spirit."* **Both are defensible
renderings of `سُبُّوحٌ قُدُّوسٌ`; the catalogue's is not asserting anything the Arabic does not
say.** This is **not** an instance of the §9m / §9t defect class (an English petition with no
counterpart in its own Arabic) — I checked for that specifically and **id 5 is clean**: no
imperative in the English, none in the Arabic, and `dua_transliteration` covers the whole string.

---

## 8 · Bar 4 — the `q-d-s` sweep, run against the full text

**Method, stated because §9ac and §9af both turn on it.** All **6,236** āyāt of `text_uthmani` were
assembled locally from `api.quran.com/api/v4/verses/by_chapter`. Every word was mark-folded
(all combining marks, `ٱ آ أ إ → ا`, `ى → ي`, `ة → ه`) and tested for the consonant **subsequence**
`ق د س`. A subsequence test is a **superset** of a contiguous-root test, so it cannot produce a false
negative for any form of the root, including forms with infixes. **This is not a search API.**

**Result: exactly 10 āyāt. Enumerated by form, not by the Name's own morphology (§9af's rule):**

| form | āyāt | the word | subject of the holiness | verdict |
|---|---|---|---|---|
| **Form II verb, 1st pl.** | 2:30 | `وَنُقَدِّسُ لَكَ` | **the angels declaring it** | **fails bar 1** — it is the angels' speech about Allah, the ledger's *"human [creaturely] speech about Allah"* class (7:196, 12:101, 10:62). Also: Allah's reply `إِنِّى أَعْلَمُ مَا لَا تَعْلَمُونَ` is **Al-Aleem (14)'s**, drafted this wave, and `.context/claims/14.md` records 2:30–33 as already rejected. |
| **Form II verbal noun, in `iḍāfa`** | 2:87 · 2:253 · 5:110 · 16:102 | `رُوحِ ٱلْقُدُسِ` / `رُوحُ ٱلْقُدُسِ` | **the Spirit (Jibrīl)** | not predicated of Allah at all. |
| **Form II passive participle, fem.** | 5:21 | `ٱلْأَرْضَ ٱلْمُقَدَّسَةَ` | **a land** | predicate of a made thing. |
| **Form II passive participle, masc.** | 20:12 · 79:16 | `ٱلْوَادِ ٱلْمُقَدَّسِ طُوًى` | **a valley** | **fails bar 1** on §9af's ground (a predicate of a made thing). ⚠️ **And Saheeh International does not even render it as holy — it reads *"the blessed valley of Ṭuwā"*.** So it would carry neither the bar nor the word. |
| **the Name, `فُعُّول` pattern** | 59:23 · 62:1 | `ٱلْقُدُّوسُ` / `ٱلْقُدُّوسِ` | **Allah** | **the only two, and both fail bar 1 as appositive epithets inside a Name-chain.** 59:23 lists **eight** Names — `al-malik@1`'s R2 note already rejected it on that ground, and **four of the eight are decked or in-wave** (Al-Malik, As-Salam, Al-Muʾmin, Al-Jabbar). 62:1 lists **four**, opening with **Al-Malik — drafted this same wave.** ⚠️ Also **bar 2**: an epithet chain *states*. |

**Conclusion, stated at its true strength: there is no `q-d-s` form anywhere in the Qurʾān with Allah
as the subject of an act, and the two occurrences that predicate the Name of Allah are the exact
construction bar 1 forbids by name. The trade is forced.**

**Limit of this sweep, stated:** it enumerates the **Qurʾān**. It does not enumerate the ḥadīth
corpus for `q-d-s`, and I make no claim about that. What I do claim is narrower and checkable: the
**one** ḥadīth occurrence this deck relies on — `قُدُّوسٌ` in Muslim 487a — was fetched and is on
beat 6.

---

## 9 · Bar 3, on all three surfaces

### 9a · Surface 1 — Arabic roots

| root | where | on a screen? |
|---|---|---|
| `q-d-s` (this Name) | duʿā beat 6, `قُدُّوسٌ` | **yes**, Arabic and English |
| `s-b-ḥ` | duʿā beat 6, `سُبُّوحٌ` | **yes**. ⚠️ *Doxological* — see 9b. |
| `m-l-k` | Muslim 2577a `مُلْكِي` ×2, **beats 3–4 in English as *dominion*** | **English only** — story beats render `arabic: ""`. ⚠️ **Al-Malik (id 4) is being drafted this same wave.** Disclosed in 9b. |
| `t-q-y` | 22:37 `ٱلتَّقْوَىٰ`, beat 5 as *piety*; Muslim 2577a `أَتْقَى`, beat 3 as *pious* | English only |
| `n-y-l`, `l-ḥ-m`, `d-m-w`, `z-y-d`, `n-q-ṣ`, `f-j-r`, `j-n-n`, `q-l-b`, `j-th-w`, `r-k-b` | the two source texts | English only |
| `h-d-y` (**shipped `al-hadi@1`**) | 22:37's **omitted** tail, `هَدَىٰكُمْ` | **NO — removed by the elision, on purpose.** §6. |
| `gh-f-r` (4 decks) · `r-ḥ-m` (5 decks) · `ʿ-f-w` · `t-w-b` · `ṣ-b-r` · `sh-f-y` · `j-b-r` | — | **absent from every beat of this deck, in Arabic and in English.** Verified by token sweep: `forgive` `mercy` `merciful` `pardon` `repent` `patient` `heal` `mend` all **n=0** in this deck's strings. |
| `r-z-q` (shipped `ar-razzaq@1`) · `gh-n-y` (`al-mughni@1`, wave 1) | Muslim 2577a's **omitted** clauses 3–4, 9 | **NO — omitted.** §5. |

### 9b · Surface 2 — token frequency over every rendered string of all 34 decks

**Method:** 734 rendered strings (`label`, `primary`, `arabic`, `transliteration`, `translation`,
`source`) across all 34 decks in `assets/content/name_stories.json`. **Beat 6's `primary` was swept
from its FIRST character** (§9as) — it opens *"Glorified, Holy,…"*, and *Holy* **is** this Name's own
gloss, so it is counted.

**Headline: zero 4-gram hits and zero 5-gram hits between any beat of this deck and any rendered
string of any of the 34 decks.**

**Tokens this deck introduces that are corpus-absent (n=0 decks):**
`holy` · `pious` · `piety` · `wicked` · `dominion` · `increase` · `decrease` · `meat` · `jinn` ·
`knelt` · `knees` · `glorified` · `spirit` · `offering` · `changed` · `less` · `idris` · `khawlani`.

**Tokens this deck touches that are corpus HAPAXES (n=1 deck) — every one, disclosed:**

| token | existing occurrence | this deck | verdict |
|---|---|---|---|
| `blood` | `al-jabbar@1` beat 3 — *"the same kind of shirt that once carried false blood"* | beat 5, Saheeh's locked 22:37 — *"nor will their blood"* | **non-blocking.** Different referent (a shirt's staged blood vs sacrificial animals), different beat kind, no shared 2-gram. Both strings are locked translations. |
| `reaches` | `ar-razzaq@1` beat 7 (takeaway) — *"Ar-Razzaq is about what reaches you."* | beat 5 — *"but what reaches Him is piety from you"* | ⚠️ **disclosed, and steered around.** The 2-word run *"what reaches"* is real. **The directions are opposite** (what reaches **you** vs what reaches **Him**). **Deliberate mitigation: `reach`/`reaches` appears in this deck exactly ONCE, on the locked Saheeh string. Beat 7 was rewritten to say *get through* precisely so the takeaway-to-takeaway axis stays clean.** |
| `get` | `al-haqq@1` (wave 1) | beat 7 — *"what does get through"* | non-blocking; ordinary register, no shared n-gram. |
| `tonight` | `al-haqq@1` (wave 1) | beat 7 | non-blocking, but recorded: **two decks in one wave now say *tonight*.** |
| `taking` | `al-mughni@1` (wave 1) | beat 0 | non-blocking; `al-mughni@1`'s is *"taking away"* of goods, mine is *"how He must be taking this."* |
| `nor` | `al-qayyum@1` | beat 5, locked | non-blocking. |

**Tokens at n=2, worth one line each:**
- **`angels` (n=2 — `ar-raqeeb@1`, `at-tawwab@1`).** Beat 6 renders *"Lord of the angels and the
  spirit"* — **catalogue-locked**, cannot be changed by any deck. ⚠️ **`ar-raqeeb@1` is drafted this
  same wave and its entire story is angels.** **Different referent** (Allah's lordship over them vs
  angels watching a person) and **zero shared n-gram at n≥2**. Disclosed; not fixable inside either
  deck.
- **`twice` (n=2 — `ar-raqeeb@1`, `ash-shafi@1`).** `ar-raqeeb@1` beat 2 says *"They all come
  together twice"*; my beat 4 says *"said twice"*. Ordinary counting word, different objects.
- **`human` (n=2), `narrated` (n=2), `part` (n=2), `whatever` (n=2), `anything` (n=2), `abu` (n=2),
  `done` (n=2)** — ordinary register, no shared n-gram.

**Doxological, disclosed and NOT blocking per §9o:** beat 6 renders *"Glorified"*. `glory` renders on
**three** duʿā beats (`al-khaliq@1`, `al-mughni@1`, `al-mujeeb@1`) and *"Exalted"* on three more.
**`glorified` itself is n=0.** §9o's row for doxological set phrases is *"No, but disclose."*
Disclosed. **The `al-khaliq@1` R2 precedent applies exactly: do NOT take an ellipsis fix on a
doxology.** None is proposed here, and beat 6 is gate-locked anyway.

**`servants`: `يَا عِبَادِي` renders on beats 3 and 4.** `servants` is at n=6 decks.
**§9o rules this NOT a collision and requires no disclosure** — a Qurʾānic/prophetic vocative is a
form of address, not a claim. It is recorded here only so the verifier can see it was considered and
which rule disposed of it.

**Name-gloss check (§9as rule 2).** This deck renders its own gloss *Holy* on **two** beats — beat 1
(`name_intro`) and beat 6 (duʿā `primary`). **Measured against every other deck's gloss: `holy` is
n=0 across all 34.** **No *Restorer*-class collision exists on this Name.**

### 9c · Deck-internal beat-to-beat diff — all 28 pairs (§9v / §9al)

**One overlap, and it is the deck's premise, stated on screen.**

Beats 3 and 4 share **26 four-grams**, including a **22-word identical opening run**
(*"were the first of you and the last of you, the human of you and the jinn of you to be as"*).
**That is the narration's own construction and it is the point of the deck.** Beat 4 says so in the
user's own words — *"The same sentence, said twice. Three words change."*

**The measurement behind that on-screen claim, because §9ak forbids the adjective:** in the rendered
**English**, exactly **three word-slots** differ — `pious`→`wicked` (×2) and `increase`→`decrease`.
⚠️ **In the ARABIC, there are four differences, not three**: `أَتْقَى`→`أَفْجَرِ`, `زَادَ`→`نَقَصَ`,
`فِي`→`مِنْ`, **and `مِنْكُمْ` is present in the first and absent in the second.** **The beat's
claim is scoped to the English the user is reading, which is what renders. That scoping is
deliberate and it is stated here so nobody has to discover it.**

**All other 27 pairs: zero shared 4-grams.** ⚠️ **Superseded 2026-08-03.** This paragraph originally
described the ORIGINAL beat 7, which deliberately closed on beat 5's own last three words (*"the
piety from you"*) — a 3-word callback, below the 4-gram threshold, intentional, and the same device
shipped `al-lateef@1` uses when its takeaway quotes 67:13. **That beat was replaced per the
verifier's ruling in §9d.** The replacement beat 7 instead calls back to beat 2 directly, sharing the
deck-original tokens `knelt`/`knees` (both corpus n=0, disclosed in §9b) rather than a phrase from
beat 5. The deck-internal diff was re-run against the replacement text and remains **zero shared
4-grams and zero shared 3-grams against all other 27 pairs** — see §13.

### 9d · Surface 3 — the move. **THE ROW THE VERIFIER MUST RULE ON.**

> **`al-kareem@1` beat 7 (shipped):** *"You are not drawing on a supply that runs down. The One being
> asked is Free of need — the asking costs Him nothing at all."*
> **`al-quddus@1` beat 7 (this deck):** *"Nothing anyone has ever done has made Him more. Nothing
> anyone has ever done has made Him less…"*

**Both land on *He is not diminished*. Zero shared 3-grams. Every mechanical pass in this pipeline
rates this clean, and would rate it clean forever.** That is precisely the shape of §9aq's worked
example (`ar-raqeeb@1` vs `al-ghafur@1`), which **survived both a drafter's pass and a verifier's**.

**My reasons for thinking it is separable — offered as reasons, not as a ruling:**
1. **The object differs.** `al-kareem@1`'s is what He **gives**; mine is what you have **done**.
2. **The consolation differs.** `al-kareem@1` relieves the shame of *asking for too much*. This deck
   relieves the shame of *having damaged something*. At 11pm those are different people.
3. **The direction differs.** `al-kareem@1` is one-directional (giving does not deplete). This deck
   is **two-directional and symmetrical** — the good adds nothing *and* the bad subtracts nothing —
   and the symmetry is the deck's whole structure, not a flourish.
4. **The narration overlap is real and I am not hiding it.** Muslim 2577a's **needle-and-the-sea
   clause is `al-kareem@1` beat 7's substance** by two claim files' own account. **It reaches no beat
   of this deck** (§5, clause 9). I am spending the narration, not that clause.
5. **Vocabulary hygiene, measured:** *"Free of need"*, *"a supply that runs down"*, *"costs Him"*,
   *"drawing on"* — **all n=0 in this deck.** `benefit` (a `al-kareem@1` hapax) was **omitted from a
   beat for this reason** (§5, clause 6).

**Per COLLISION-LEDGER §9ab — *"a drafter may not rule on its own collision"* — I do not rule. If the
verifier calls it a repeat, the fix is a new beat 7, not a reword**, and the deck has the material
for one: the kneeling in beat 2 is unspent and could carry a takeaway about what a man does with his
body before he repeats a sentence.

#### 9d.1 · VERIFIER RULING, 2026-08-03 — BLOCKING. Fixed by a new beat, not a reword.

**The independent verifier (`2026-08-03-WAVE2-VERDICT-allah-al-quddus.md`, probe 9) ruled this
BLOCKING**, and did so on the grounds this deck itself named but declined to apply: §9ab/§9aq hold
that a drafter may not clear its own beat-to-beat move-echo, and the verifier's own precedent record
is now **3 for 3** — every prior case where a drafter disclosed a move-collision and offered reasons
rather than a ruling, the independent pass overturned the drafter's separability argument
(`al-mumin@1`/`al-wakeel@1` at §9ab; `ar-raqeeb@1`/`al-ghafur@1` at §9aq; now this one). The four
reasons offered above were read and found real at the level of content, not at the level of shape —
and shape is what bar 3's third surface exists to catch.

**The original beat 7 is struck, not merely reworded**, per the verifier's instruction and this
deck's own §9d closing sentence naming the fix in advance:

> ~~Nothing anyone has ever done has made Him more. Nothing anyone has ever done has made Him less.
> Whatever you are carrying tonight has not changed Him — and what does get through was never the
> offering. It is the piety from you.~~ *(struck 2026-08-03 — see §13 for the replacement and the
> token check run before it was written.)*

**Replacement beat 7 (now rendered — see §2):**

> Abu Idris knelt every time he repeated this — right after saying, in the same breath, that nothing
> anyone does moves Allah at all. He was not bargaining with Him. He knelt because a man who has just
> heard the truth about his own smallness still has a body, and a body has to do something with that.
> Kneel too. Not to move Him. To answer what you just heard.

**The move changed, not just the words.** The original beat 7 was a claim *about Allah* — a
bipolar-negation collapse to *He is not diminished*, addressed as reassurance about the user's own
record. The replacement makes no claim about Allah's (in)dependence at all; it is built entirely from
the unspent kneeling detail in beat 2 and lands on an **embodied response** — what a man who has just
heard this did with his body, and an imperative to do likewise. That is a different move from
`al-kareem@1` beat 7's *"the asking costs Him nothing"* at the level of shape, not only at the level
of vocabulary. Full token-check results in §13.

### 9e · Bar 3 against shipped `as-salam@1` — the adjacency the brief named

| axis | result |
|---|---|
| story | Thawr / the hijrah vs a ḥadīth qudsī. **No overlap.** The ledger records the hijrah cluster as `as-salam@1`'s; this deck does not go near it. |
| passage | 9:40 + 13:28 vs 22:37. **No shared sūrah.** |
| ḥadīth | Muslim 591 vs Muslim 487a / 2577a. **No shared number.** |
| engine | *peace inside you* (pair-synergy with Al-Wakeel) vs *your record never touched Him*. **Different.** |
| rendered English | **zero shared 4-grams.** `peace` n=0 in this deck; `holy` n=0 in `as-salam@1`. |
| Arabic root | `s-l-m` n=0 here; `q-d-s` n=0 there. |
| **the one real link** | **both Names sit in 59:23's chain** — `ٱلْمَلِكُ ٱلْقُدُّوسُ ٱلسَّلَـٰمُ`. **This deck REFUSES 59:23** (§8), so the chain reaches no screen. ⚠️ **Also recorded: id 89's Name-phrase already renders on `as-salam@1`'s duʿā beat (ledger §6d.2). That is a different Name's problem, not this one's** — and this deck's duʿā shares **zero** words with `as-salam@1`'s. |

**Verdict: clean, and clean by construction rather than by luck.**

---

## 10 · Candidates considered and rejected — recorded so they are not re-derived

**Qurʾān**

- **59:23 · 62:1** — the only two āyāt predicating the Name of Allah. **Bar 1 (appositive epithet) and
  bar 2 (states).** 62:1 additionally opens its chain with **Al-Malik, drafted this wave**.
- **20:11–14, the sacred valley of Ṭuwā.** The strongest `q-d-s` text in Allah's own first-person
  speech, and I want the record to show it was refused rather than missed. **Three grounds:**
  (a) bar 1 — the holiness is predicated of a **valley** (§9af's class); (b) **Saheeh International
  renders it *"the blessed valley"***, so the English would not even carry the word; (c) **blocked
  twice this wave** — `al-haqq@1` holds Ṭā Hā 20:65–70 with **Mūsā** as its central figure, and
  shipped `al-hadi@1` is also Mūsā. **Blocked, not free.**
- **50:38** (`وَمَا مَسَّنَا مِن لُّغُوبٍ` — *"and there touched Us no weariness"*). **The best
  non-`q-d-s` tanzīh clause in Allah's first-person voice, and genuinely painful to give up.**
  Refused on **bar 3**: the same āyah is `خَلَقْنَا ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ` — `al-khaliq@1`'s
  root, subject and rendered English verb, **drafted this wave** with 36:36 (*"Exalted is He who
  created…"*) on **its** verse beat. Also `فَٱصْبِرْ` at 50:39 (As-Sabur, 32). **Blocked, not free.**
- **112:1–4** — 112:2 is shipped `as-samad@1`'s verse beat; `أَحَدٌ` is Al-Ahad (74).
- **42:11** (`لَيْسَ كَمِثْلِهِۦ شَىْءٌ`) — trailing `ٱلسَّمِيعُ ٱلْبَصِيرُ` = As-Sami (45) and
  **shipped** Al-Baseer (46); and a negative construction, a ledger-rejected class.
- **37:180** (`سُبْحَـٰنَ رَبِّكَ رَبِّ ٱلْعِزَّةِ عَمَّا يَصِفُونَ`). **Bar 5 is superb here** — the
  sūrah ends two āyāt later on *peace* and *praise*. **Refused on bar 2: it states the attribute**,
  the ground that killed `al-haleem@1` rev 1 and blocked 24:35. **Left free for a Name that can use
  a declaration.**
- **21:22 · 23:91** (the *"had there been gods besides Him"* arguments). Both **show** rather than
  state, and both are blocked by sūrah crowding this wave: al-Anbiyāʾ already carries `ash-shafi@1`
  **and** `al-mujeeb@1` (an open founder call), and al-Muʾminūn is `al-khaliq@1`'s (23:12–14), whose
  root `خَلَقَ` is inside 23:91.
- **17:43–44** — 17:44 is on the ledger's bar-3 rejection list (`حَلِيمًا غَفُورًا`).
- **19:88–91** — the heavens almost rupturing at the claim of a son: **the strongest transcendence
  narrative in the Qurʾān, and already spent by `al-haleem@1`.**
- **35:15 · 14:8 · 29:6 · 3:97 · 4:131** (the *ghinā* āyāt) — all trailing epithets (bar 1); 14:8 is
  **Mūsā's speech**; Sūrat Fāṭir already carries two decks.
- **2:30** — see §8; also already rejected in `.context/claims/14.md`.
- **7:180** — see the companion refusal document; blocked on an intra-āyah warning tail.

**Ḥadīth**

- **Muslim 482** (*"the closest a servant is to his Lord is while in prostration"*). Fetch-adjacent
  and **not used**: the beat it produces lands on *he asked for nothing*, which is shipped
  `ash-shafi@1`'s move (*"He demanded nothing."*, ledger §4b). **Left free but flagged.**
- **Muslim 487b** — the parallel chain of 487a; **not fetched into a beat**, nothing in this deck
  depends on it.
- **Bukhārī 6408** (Allah asking the angels what His servants say). **`ar-raqeeb@1` holds Bukhārī
  555 this wave**, the same scene and the same move. **Not touched.**
- **Muslim 2577 b · 2577 c** — different chains of the same ḥadīth; not used.

---

## 11 · What this pass could NOT determine — read before signing

1. **Neither Muslim page prints a grade line.** *Ṣaḥīḥ* for 487a and 2577a is a **collection-level
   inference** from Ṣaḥīḥ Muslim, not a printed Darussalam verdict. Same disclosure `al-khaliq@1`
   made for Bukhārī 6227.
2. **No isnād was audited, and no corpus independent of sunnah.com was reached.** sunnah.com 403s
   automated fetching, so both ḥadīth came from **Wayback captures of sunnah.com** — one
   digitisation. No printed edition, no Shamela, no Dorar. **This limit is unchanged since the pilot
   and this deck does not improve on it.**
3. **The `q-d-s` sweep covers the Qurʾān only.** I did not enumerate `q-d-s` across the ḥadīth
   corpus and make no claim about it.
4. ~~The `al-kareem@1` beat-7 adjacency is unresolved by design (§9d). I have given reasons, not a
   ruling.~~ **RESOLVED 2026-08-03 by the independent verifier: BLOCKING.** Beat 7 has been replaced,
   not reworded — see §9d.1 and §13.
5. **Bar 5 here is an argument, not a 404** (§6a). 22:37 is not sūrah-final and 22:39 is two āyāt
   away.
6. **The token sweep is over `assets/content/name_stories.json` as it stood on 2026-08-03 with 34
   decks.** Four sibling agents are drafting concurrently; **their beats are not in that file.**
   `.context/claims/` was re-read immediately before this table was written and every claim file
   present was diffed against these beats — but a claim filed after that read is invisible to me.
   This is COLLISION-LEDGER §9s's known hole and I am inside it, not outside it.
7. **Whether the ship gate passes.** I ran no tests and edited no asset. `assets/content/`,
   `collectible_names.json` and the ship-gate test were **read only**.

---

## 11a · §9s re-read — `.context/claims/` re-read immediately before this table, and it found five late files

At my start the directory held **10** files (`4, 7, 10, 14, 17, 40, 57, 61, 93, 98`). **Re-read after
the beats were fixed: it holds 17.** Five were filed after I began — **8 (Al-Azeez), 24 (Al-Qabid),
25 (Al-Basit), 45 (As-Sami), 87 (Ar-Rauf)** — plus my own 1 and 5. **All five were read and diffed
against these beats.** This is exactly the hole §9s exists to close, and it caught real neighbours.

| late claim | its citations | collision with this deck? |
|---|---|---|
| **8 Al-Azeez** | 36:13–14, 10:65 | **none.** No shared sūrah, ḥadīth or string. |
| **24 Al-Qabid** | 25:45–46, 2:245 | **none.** |
| **25 Al-Basit** | Bukhārī 1013/1014/933, 30:48 | **none.** |
| **45 As-Sami** | **Ṣaḥīḥ Muslim 395**, 20:46, 11:61 | **No citation overlap.** ⚠️ **Structural adjacency, disclosed:** Muslim 395 is also a **ḥadīth qudsī** — Allah answering al-Fātiḥa **in the first person** — so **two decks in this wave build bar 1 on Allah's own first-person speech in a Muslim narration.** Different narration, different number, different move (*answered line by line* vs *unaffected either way*). Zero shared rendered string. **Recorded, not resolved by me.** |
| **87 Ar-Rauf** | Bukhārī 3207/349, 4:28 | **No citation overlap.** ⚠️ **Two disclosures.** (a) **Bukhārī 3207's narrator is Abū Dharr — and so is Muslim 2577a's.** Abū Dharr would be the narrator behind two decks of one wave. **Neither deck renders his name on a beat** (mine names only Abu Idris al-Khawlani), so this reaches no screen. (b) That claim file **cites `al-quddus@1` as a bar-4-trade precedent**, i.e. it read my claim before I read its. The mechanism worked in that direction. |

**No late claim changes a beat, a citation or a bar in this deck.**

## 12 · Prose-vs-table diff (§9aj) — run before reporting

Every claim the prose above makes was checked against the row that supports it. **Three came down to
the row:**

- §1 originally read *"no beat repeats a word three times"*. The **table** made me count: `Holy`
  occurs **twice** in the deck. The prose now states the count.
- §9c originally read *"three words change"* full stop. The table's Arabic column shows **four**
  differences in the Arabic. **The beat's on-screen claim is now explicitly scoped to the English**,
  and the Arabic figure is stated beside it.
- §8 originally read *"there is no usable `q-d-s` text anywhere"*. The enumeration supports the
  narrower true statement — **no `q-d-s` form has Allah as the subject of an act, and the two that
  predicate the Name of Allah are appositive epithets** — which is what it now says.

**Per §9ak, every quantity above is a number, not an adjective:** 10 āyāt · 2 Name-occurrences ·
734 rendered strings · 34 decks · 0 four-gram hits · 0 five-gram hits · 1 orthographic word ·
22-word identical run · 3 English word-slots (4 Arabic differences) · 6 omitted clauses · 2 hapaxes
avoided by omission · 17 āyāt between this deck and `al-hadi@1` in Sūrat al-Ḥajj.

---

## 13 · Fix applied per the independent verifier's ruling — 2026-08-03

**Source:** `2026-08-03-WAVE2-VERDICT-allah-al-quddus.md`, probe 9. **Verdict on this deck:
FIX-THEN-SIGN, on this one finding.** Nothing else in the verdict required a change here — the
verifier independently reproduced the bar-1 enumeration, the `q-d-s` sweep, Muslim 487a and 2577a,
the 22-word run, and every disclosed hapax, all exactly as claimed.

**Finding, as the verifier stated it:** this deck's original beat 7 (*"Nothing anyone has ever done
has made Him more…"*) and shipped `al-kareem@1`'s beat 7 (*"You are not drawing on a supply that
runs down…"*) are a zero-shared-n-gram collision in the *move* — both a negated bipolar pair
collapsing to *He is unaffected*, both the deck's final mic-drop line, both addressed to the user at
the same product moment. **Ruled BLOCKING**, on the pipeline's own precedent that a drafter may not
clear a self-disclosed move-echo (§9ab/§9aq) and on the record that the independent pass has now
overturned every prior case where a drafter offered reasons instead of a ruling on this exact shape
(3 for 3).

**Fix applied, per the verifier's instruction (a new beat, not a reword) and this draft's own §9d,
which had already named the escape hatch:** beat 7 is replaced, built from the unspent kneeling
detail in beat 2 (Abū Idrīs al-Khawlānī kneeling each time he narrated Muslim 2577a). The struck
original and the replacement are both recorded in §9d.1; the replacement is what now renders in §2.

**Why this is a different move, not a softer version of the same one:** the original beat made a
claim *about Allah* (unaffected either way). The replacement makes no claim about Allah's
(in)dependence — it is about what a human narrator did with his body upon hearing that claim, and it
closes on an imperative to do likewise. That is the pivot the verifier's precedent (`ar-raqeeb@1`'s
replacement, recorded as *"the better beat, with the collision as what made the deck look for it"*)
describes.

**Token check, run before the replacement was finalized (§9as: check before writing, not after):**

- **3/4/5-gram sweep against all 734 rendered strings of the 34 shipped decks:** zero 4-gram and zero
  5-gram hits. Three trivial 3-gram hits, all common function-word runs (`in the same`, `he was not`,
  `to do something`, `every time he`) — the same order of coincidental overlap the rest of this deck
  already tolerates at n=3, and below the deck's own n=4 blocking threshold.
- **Against `al-kareem@1` beat 7 specifically, at n=2 through n=5:** one trivial 2-gram (`at all`);
  zero at n≥3. The original beat 7 was already zero-shared-3-gram against `al-kareem@1`; the
  replacement holds the same floor while changing the move itself.
- **Deck-internal, against this deck's other 7 beats (all 7 remaining pairs):** zero shared 3-grams,
  4-grams or 5-grams. The replacement does not reintroduce the beat-5 callback (`"the piety from
  you"`) that the original beat 7 used; it calls back to beat 2 instead, sharing only the
  deck-original tokens `knelt`/`knees`, both corpus n=0 (§9b).
- **Word count:** 69 words, in range with the deck's other takeaways (the original was 50 words).

**Nothing else in this deck changed.** No other beat, citation, bar verdict, or table row was
touched. Per the verdict's rules, the minor `guide`/`decks` imprecision noted for `allah@1` §5 is
that deck's fix, not this one's — this deck's own §5 uses the same "6" figure for a different clause
and was not named by the verifier, so it is left as written.
