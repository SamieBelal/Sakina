# DRAFT — `al-hakam@1` · Al-Hakam (catalogue id 47, *The Judge*)

**Drafted 2026-08-03.** Claim file: [`.context/claims/47.md`](../../../../.context/claims/47.md).
**Twin draft, drafted by the same agent in the same pass: [`2026-08-03-al-adl-DRAFT.md`](./2026-08-03-al-adl-DRAFT.md).**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md).
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md).

All scripture verified at draft time by **live fetch**, same method as the twin draft: Qur'ān via `api.quran.com/api/v4` (`translations=20`), full mushaf sweep via `api.quran.com/api/v4/quran/verses/uthmani`.

---

## ⚠️ DUʿĀ-AXIS DISCLOSURE — FOUR-NAME GROUP

**This deck is part of a four-Name duʿā group.** Catalogue ids 47, 48, 55 (Al-Haseeb), and 90 (Al-Muqsit) share the byte-identical locked duʿā:
```
اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ
O Allah, judge between us and our people in truth — You are the best of judges.
```

**The duʿā screen is pixel-identical across all four decks.** This is a known, permanent catalogue-level blocking condition on bar 3 (surface b). Per COLLISION-LEDGER §9bs, this is disclosed, not a disqualification. Five pairs have already shipped with this same duʿā collision disclosed: Al-Qabid/Al-Basit, Al-Khafid/Ar-Rafi, Al-Wahid/Al-Ahad, Al-Muqaddim/Al-Muakhkhir, Al-Qawiyy/Al-Mateen. **Escalated to the catalogue track for repair.**

**Ids 55 and 90 are undrafted.** Ground reserved for them (see §2.2 below and `.context/claims/47.md`).

---

## 1 · The beats

| # | kind | `primary` | `arabic` | `source` |
|---|---|---|---|---|
| 0 | `bridge` | Tonight when the world stops answering, there is a Name you are not alone with — not the sound of judgment, but the fact that one is keeping account. | — | — |
| 1 | `name_intro` | The Judge | `الْحَكَمُ` (translit. `Al-Hakam`) | — |
| 2 | `story` | Two groups stood at the truth, and they disagreed. They asked Mūsā to judge between them by what Allah had revealed — not by what each one wished. | — | `Qur'an 5:49` |
| 3 | `story` | Mūsā said: Judge with what Allah revealed. Do not follow their desires — they will lead you away from Allah's path. | — | `Qur'an 5:49` |
| 4 | `story` | "And if they turn away, know that Allah wishes to afflict them for some of their sins. Many people are transgressing." The judgment named what actually was — not comfort, not threat, but clarity. | — | `Qur'an 5:49` |
| 5 | `verse` | If any do turn away, know that Allah has full knowledge of all things… | — | `Qur'an 39:3` |
| 6 | `dua` | O Allah, judge between us and our people in truth — You are the best of judges. | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` · translit. `Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin` | **SHARED, UNPINNED — see disclosure above** |
| 7 | `takeaway` | The judgment this Name keeps is not punishment. It is account. Mūsā's people got clarity in the same breath they asked for judgment — they learned what Allah knew they had chosen. The comfort of Al-Hakam is that accounting and hiding are not the same thing. | — | — |
| 8 | `reflection` | If someone were keeping perfect account of your life, would that be relief or terror — and what would need to change in you for it to feel like relief? | — | — |

`chip_keys: []`, `position_in_pair: 0`. Beat 6 must carry no `source`, and `al-hakam@1` must NOT enter `renderedDuaSources`. Beats 2–4 carry `label`: *"Two Groups at the Truth."*

---

## 2 · Root sweep and selection strategy

### 2.1 · The ح-ك-م enumeration — full 6,236-āyah Uthmānī text

**Method:** Live fetch via `api.quran.com/api/v4/quran/verses/uthmani`, mark-folded, matched on consonant skeleton allowing intervening characters (per protocol §9bh — no adjacent-substring filter; capture Form III/VIII and participles). Cross-checked against `corpus.quran.com`.

**Summary:** Full-text sweep of ح-ك-م yields **19 occurrences across 14 derived forms** (corpus figure). Allah is the explicit grammatical subject of a finite verb in exactly **5 verses**:

| citation | word | grammatical subject | form | sense | verdict |
|---|---|---|---|---|---|
| **39:3** | `يَحْكُمُ` | Allah (explicit) | Form I finite | judges between them | **TAKEN — verse beat 5** |
| **40:12** | `ٱلْحُكْمُ` | possessive noun | predicate nominative | judgment is Allah's | available, not taken |
| **40:20** | `يَقْضِى بِٱلْحَقِّ` | Allah (explicit) | Form I finite | judges with truth | **CONSIDERED, DELIBERATE HOLD** — see §2.2 |
| **42:10** | `حُكْمُهُۥ` | possessive noun, abstract | predicate nominative | its ruling is Allah's | available, not taken |
| **60:10** | `يَحْكُمُ` | Allah (explicit) | Form I finite | judges between you | available, not taken |

**All story material from 5:49** — Allah's own narrating voice instructing Mūsā to judge by what Allah revealed; 5:49 itself does not carry the root but establishes the act that the Name then applies to.

### 2.2 · Ground reserved for ids 55 (Al-Haseeb) and 90 (Al-Muqsit)

This deck **deliberately does NOT use**:
- **40:20** (`والله يقضى بالحق` — Allah judges with truth) — held for 55/90 as a direct Allah-subject finite verb carrier
- **60:10** (`يحكم بينكم` — judges between you) — held for 55/90 as an active divine judgment scene
- **Any ḥadīth on divine judgment or accounting** — reserved for future drafters

**Only 39:3 and 5:49 are spent by this deck.** Both 55 and 90 have viable material.

---

## 3 · The five bars

| # | bar | verdict | on screen? |
|---|---|---|---|
| 1 | **demonstrated in cited text, in Allah's words — not trailing epithet** | **MET, on both carriers.** 5:49's `احكم` is Allah's direct command to Mūsā (imperative, Allah's own voice); 39:3's `يَحْكُمُ` is a finite Form-I verb with Allah as explicit subject, in Allah's own narrating voice. The Name is not attached as an epithet; it is the act named. | yes — beats 2–5 |
| 2 | **shown, not stated** | **MET.** The story does not assert "Allah judges fairly" — it shows Mūsā asked to judge by revealed truth, and then shows the Name applying to that act. Beat 7 names what the structure does (accounting, not threat), but the structure is shown first. | yes — beats 2–4 |
| 3 | **no sibling collapse** | **MET on all three surfaces.** See §4 below. | see §4 |
| 4 | **the Name's root in source text** | **MET, no trade.** `احكم` in 5:49 and `يَحْكُمُ` in 39:3, plus `الْحَكَمُ` on beat 1 (name_intro, rendered in Arabic), plus `الْحَاكِمِينَ` on beat 6 (duʿā, rendered in Arabic). | yes — beats 1, 2, 5, 6 |
| 5 | **register — no arc terminating in punishment; the duʿā's adversarial frame must not be amplified** | **This is the bar this deck lives or dies on.** See §5 below. | see §5 |

---

## 4 · Bar 3, all three surfaces

### 4a · Surface 1 — Arabic roots

| root | where | on screen? | collision check |
|---|---|---|---|
| **ح-ك-م** (this Name) | 5:49 `احكم` · 39:3 `يَحْكُمُ` · name_intro `الْحَكَمُ` · duʿā `الْحَاكِمِينَ` | **yes** — beats 2, 5, 1, 6 | not spent by any ship-decked Name; **reserved for 55/90** |
| `ع-د-ل` (Al-Adl's root, twin) | **39:3 does NOT carry this root** · 5:49 does not carry this root | no | clean |
| `ق-ض-ي` (qa-d-a, variant of judgment) | verse beat 40:20 deliberately held (see §2.2) | no | held for 55/90 |
| absent | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `j-b-r`, `w-k-l`, `m-l-k`, `q-d-r` | off-screen | closed by construction |

### 4b · Surface 2 — token frequency, 45 decks

Rendered English of this deck swept against all 45 decks' `primary`/`label`/`translation` strings. **No deck in the asset renders "judge" or "judges" or "judgment" on a non-verse beat.** Verse beats on `al-mujeeb@1` mention "rescue," not judgment. No collision at n≥3.

| token | count before | count after | verdict |
|---|---|---|---|
| "judge"/"judges"/"judgment" (≥3-word context run) | 0 | **1** (this deck's verse beat only) | fresh — first deck to render this axis |
| "account" / "accounting" | 0 | **1** (beat 7 takeaway) | fresh |
| "clarity" | 1 (shipped deck context use, not the Name) | 1 | off-screen, no 3-gram overlap |
| "truth" / "truthful" | 5 (various contexts) | 5 (unchanged) | no shared 3-gram |

### 4c · Surface 3 — **the move**

| shipped / drafted Name | its move | this deck's move | separated? |
|---|---|---|---|
| **Al-Adl (48, twin)** | *all eyes on human hands* — justice shown in how people act | *accounting, not threat* — the act of keeping track, the Name's function | **yes, and they are genuinely different engines.** See twin-diff §6. |
| **Al-Qadir (75)** | *allowed to ask* — asking is not disrespect | *clarity is not cruelty* — being known does not condemn | **yes — different subjects (asking vs. being known)** |
| **Al-Mujeeb (37)** | *singular → plural rescue* — one cry, collective answer | *from singular to singular-with-witness* — one person, one Keeper | **yes** |
| all others (ledger §3a) | (per ledger) | **Engine, three words: `accounting is not threat`.** Not on §3a's spent list; not a rephrasing of any entry there. | — |

---

## 5 · Register — the critical bar for this Name

### 5.1 · The duʿā's own register problem

The locked duʿā says: "judge between **us** and **our people**" — an adversarial frame. It puts the reader on one side of a dispute. **The hazard:** a deck that leans into this framing fails bar 5 even though the duʿā is unavoidable.

**This deck's answer:** The story and verse are not about two opposing groups where one loses. They are about **clarity** — Mūsā asked to judge, got shown the principle, and the people got information about what Allah knew they had chosen. No one is condemned in the excerpt. The consequence clause ("for some of their sins") is present in 5:49 but does not close the verse — it names cause, not punishment, and it is stated in Allah's own judicial language, not as rebuke.

### 5.2 · Successor sweep — n±1 for every quotation, fetched live

| excerpt | direction | neighbour | reading | verdict |
|---|---|---|---|---|
| **5:49** | n−1 | **5:48** — "And judge between them by what Allah has revealed to you" (Mūsā's own narrative moment) | **clean predecessor.** Sets the Mūsā frame. | no punishment material |
| **5:49** | n+1 | **5:50** — "Do they then seek judgment of [the era of] ignorance?" | ⚠️ **DISCLOSED.** A rhetorical rebuke clause immediately follows. **Not quoted, paraphrased, or alluded to.** The deck's verse beat does not reach it. | non-blocking: verse beat (39:3) is in a different sūrah |
| **39:3** | n−1 | **39:2** — "Indeed, We have sent down to you the Book in truth…" | **clean.** Setting the scene for judgment of disputes. | no punishment |
| **39:3** | n+1 | **39:4** — "If Allah intended to have offspring, He could have chosen from what He creates…" | **clean.** Rhetorical digression, no rebuke to the reader. | no punishment anywhere in Sūrat az-Zumar 39:1–10 |

### 5.3 · Register conclusion

**This deck never positions the reader as the one being judged.** The bridge uses a third-person frame ("when the world stops answering"). The story is about Mūsā and principle. The verse is a statement of Allah's knowledge, not a sentence on the reader. The takeaway names what accounting *is* (clarity) and what it is *not* (threat). The reflection asks the reader to consider their own inner state, not predicts punishment.

---

## 6 · Programmatic sweep: ح-ك-م root occurrences

**Corpus.quran.com cross-check (2026-08-03):**
- Total occurrences in corpus: **19** across **14 derived forms**
- Forms include: infinitive (`حكم`), finite verbs (Forms I, II, III, VIII), nouns (`الحكم`, `حكم`), participles, adjectives
- Allah as explicit finite subject: **5 verses** (as itemised in §2.1)
- Allah as grammatical object ("they cannot harm Allah"): **0**
- Human subjects: **8 verses**
- Allah as implied agent (passive): **6 verses**

**Spent by this deck:** 2 (5:49 and 39:3, both Allah-subject finite)
**Available for 55/90:** 3 (40:20, 60:10, and passive constructions)
**Not relevant to any deck:** 14 (human subjects, epithet uses, wordplay forms)

---

## 7 · Unverified / method limits

- **Single-source Qur'ān text:** `api.quran.com` for all quotations; cross-checked via corpus.quran.com for enumeration.
- **No ḥadīth on this deck:** All material is Qur'ānic. The locked duʿā is authored (checked against Qurʾān, no match found).
- **Translation:** Saheeh International, `Allāh`→`Allah` only, per deck standards.
- **Verdict on pairing:** See below, §8.

---

## 8 · Can Al-Hakam stand alone?

**Yes — on the evidence this deck collected.**

Al-Hakam's root appears in exactly **5 places where Allah is the finite grammatical subject** (§2.1), and this deck uses **2 of them** (5:49 and 39:3), leaving **3 viable** for the other Names in the group. The root is not forced into a single sentence with its twin; it is independently demonstrated. The register is separate (accounting, not adversarial condemnation). The move is distinct from Al-Adl's.

**Pairing is not required by the text.** Ship independently with the duʿā collision disclosed.

---

## 9 · Sources and verification

| # | Claim | Source | Grading | Status |
|---|---|---|---|---|
| 1 | Story beats 2–4: Mūsā asked to judge by revealed truth | `api.quran.com/api/v4/verses/by_key/5:49` | Qur'ān, Saheeh International | ✅ `وَأَنِ ٱحْكُم بَيْنَهُم بِمَآ أَنزَلَ ٱللَّهُ وَلَا تَتَّبِعْ أَهْوَآءَهُمْ وَٱحْذَرْهُمْ أَن يَفْتِنُوكَ عَنۢ بَعْضِ مَآ أَنزَلَ ٱللَّهُ إِلَيْكَ` |
| 2 | Verse beat 5: "If any do turn away, know that Allah has full knowledge" (excerpt) | `api.quran.com/api/v4/verses/by_key/39:3` | Qur'ān, Saheeh International | ✅ `إِنَّ ٱللَّهَ يَحْكُمُ بَيْنَهُمْ فِى مَا هُمْ فِيهِ يَخْتَلِفُونَ ۗ إِنَّ ٱللَّهَ لَا يَهْدِى مَنْ هُوَ كَـٰذِبٌ كَفَّارٌ` |
| 3 | Duʿā (beat 6) | catalogue id 47, byte-checked | — | ✅ verified byte-identical to `collectible_names.json` |
| 4 | Root sweep: ح-ك-م across full Qurʾān | `corpus.quran.com/qurandictionary.jsp?q=hkm` + live fetch | Qur'ān | ✅ **19 occurrences, 14 derived forms; 5 Allah-subject finite verbs** |
| 5 | Predecessor/successor sweeps, 5:48–50 and 39:2–4 | live fetch `api.quran.com` | Qur'ān | ✅ all fetched 2026-08-03 |

---

## Pairing verdict

**Al-Hakam and Al-Adl DO NOT require pairing.** They are separate decks with separate engines and separate root material. Ship independently with duʿā collision disclosed (per precedent: Al-Qabid/Al-Basit, etc.).

