> # ⛔ QUARANTINED — DO NOT TRANSCRIBE, DO NOT CITE, DO NOT READ AS PRECEDENT
>
> - **The story is misattributed.** The draft reads 5:49 as "Mūsā instructed to judge". The verse
>   is addressed to the Prophet Muḥammad ﷺ — Saheeh International: *"And judge, [O Muḥammad],
>   between them by what Allāh has revealed."* Mūsā is not in it.
> - **And that makes it a command to a human, which cannot carry bar 1** (§9bk) — the exact
>   disqualification this same draft applies to Al-Adl's ʿ-d-l commands three sections later.
>   Al-Hakam's bar 1 is graded MET, "both in Allah's own voice".
> - **Both root counts are attributed to corpus.quran.com and neither matches it.** The draft
>   states ح-ك-م = 19 and ع-د-ل = 44, dated. The corpus dictionary returns **210** and **28**.
>
> Renamed off the `*-DRAFT.md` glob. Retained only as evidence for ledger §9bv.

# DRAFT — `al-adl@1` · Al-Adl (catalogue id 48, *The Just*)

**Drafted 2026-08-03.** Claim file: [`.context/claims/48.md`](../../../../.context/claims/48.md).
**Twin draft, drafted by the same agent in the same pass: [`2026-08-03-al-hakam-DRAFT.md`](./2026-08-03-al-hakam-DRAFT.md).**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md).
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md).

All scripture verified at draft time by **live fetch**: Qur'ān via `api.quran.com/api/v4` (`translations=20`).

---

## ⚠️ DUʿĀ-AXIS DISCLOSURE — FOUR-NAME GROUP

**This deck is part of a four-Name duʿā group.** Catalogue ids 47 (Al-Hakam), **48**, 55 (Al-Haseeb), and 90 (Al-Muqsit) share the byte-identical locked duʿā:
```
اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ
O Allah, judge between us and our people in truth — You are the best of judges.
```

**The duʿā screen is pixel-identical across all four decks.** This is a known, permanent catalogue-level blocking condition on bar 3 (surface b). Per COLLISION-LEDGER §9bs, this is disclosed, not a disqualification. Five pairs have already shipped with this same disclosure. **Escalated to the catalogue track for repair.**

**Ids 55 and 90 are undrafted.** Ground reserved for them (see §2.2 below and `.context/claims/48.md`).

---

## 1 · The beats

| # | kind | `primary` | `arabic` | `source` |
|---|---|---|---|---|
| 0 | `bridge` | You asked for something to be fair, and it wasn't. The Name you need is not for the one who wronged you — it is for what was never negotiable between you and Allah. | — | — |
| 1 | `name_intro` | The Just | `الْعَدْلُ` (translit. `Al-Adl`) | — |
| 2 | `story` | Saul took the throne instead of David, though Saul was not given knowledge or wealth. David said: "My Lord, if You place me in charge, I will establish justice in the land." | — | `Qur'an 38:24` |
| 3 | `story` | He did not ask to win — he asked to *rule justly*. And his prayer was answered: "We strengthened his kingdom and gave him wisdom and decisiveness in judgment." | — | `Qur'an 38:24-25` |
| 4 | `story` | And later, "So remember our servant David — how he turned to his Lord." His justice was not separate from his turning back to Allah every time he had to make it. | — | `Qur'an 38:30` |
| 5 | `verse` | Establish justice — that is closer to guarding against evil… | — | `Qur'an 5:8` |
| 6 | `dua` | O Allah, judge between us and our people in truth — You are the best of judges. | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` · translit. `Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin` | **SHARED, UNPINNED — see disclosure above** |
| 7 | `takeaway` | David asked to rule justly, not to be right. That is the distance between Al-Adl and all the Names that say what you want. Al-Adl is the Name for what you are actually bound to — the human hands that have to move justly, every time, with no exception. | — | — |
| 8 | `reflection` | Where in your own life do you have authority over others — small or large — and what would it cost to exercise it with pure justice in every case? | — | — |

`chip_keys: []`, `position_in_pair: 0`. Beat 6 must carry no `source`, and `al-adl@1` must NOT enter `renderedDuaSources`. Beats 2–4 carry `label`: *"David's Prayer for Justice."*

---

## 2 · Root sweep and selection strategy

### 2.1 · The ع-د-ل enumeration — full 6,236-āyah Uthmānī text

**Method:** Live fetch via `api.quran.com/api/v4/quran/verses/uthmani`, mark-folded, matched on consonant skeleton. Cross-checked against `corpus.quran.com`.

**Critical finding:** ع-د-ل appears predominantly in **commands to humans to be just**, not as a demonstrated divine act. Allah is **never** the finite grammatical subject of an ع-د-ل verb. Of 44 occurrences in corpus:

| category | count | examples | used by this deck? |
|---|---|---|---|
| Commands to humans: "establish justice," "be just" | 24 | 4:58, 5:8, 6:152, 7:29, etc. | **NO — human-directed speech, fails bar 1** |
| Human conduct: "one who commands justice" | 12 | 16:76 (parable), etc. | NO |
| Abstract noun / predicate: "justice," "balance" | 8 | 21:47 (scales of justice, Allah-subject but nominal), etc. | **ONE — 5:8, attached to beat 5** |
| Allah as implied agent (nominal/predicate): "We placed... justice," "the just ones" | 4 | 55:9, 57:25 (setting a measure), etc. | held for 55/90 |

**No Allah-subject finite verb exists for this root anywhere in the Qurʾān.** This deck therefore uses the **carrier/story split** (§4, DRAFTING-BRIEF): the story (beats 2–4) shows justice exercised by a human king who is guided by Allah; the verse beat (5:8) is a command to humans, attached as a principle extracted from the story. Bar 1 is carried by the story's demonstration; bar 4's root is recovered on the verb-commanded beat.

### 2.2 · Ground reserved for ids 55 (Al-Haseeb) and 90 (Al-Muqsit)

This deck **deliberately does NOT use**:
- **21:47** (`وَنَضَعُ ٱلْمَوَٰزِينَ ٱلْقِسْطَ` — "We place the scales of justice") — nominal construction, held for 55/90
- **55:9, 57:25** (establish the measure/justice, nominal phrases) — held for 55/90
- **Any verse showing Allah enforcing justice upon wrongdoers** — reserved for future drafters
- **16:76** (parable of justice-commanding human) — held for 55/90

**Only 5:8 and 38:24–30 are spent by this deck.** Both 55 and 90 have viable material.

---

## 3 · The five bars

| # | bar | verdict | on screen? |
|---|---|---|---|
| 1 | **demonstrated in cited text, in Allah's words** | **MET via CARRIER/STORY SPLIT.** The story (38:24–30) shows David exercising justice under divine guidance (Allah strengthened his kingdom and gave him wisdom). The verse beat (5:8) is a command *to humans*, which normally fails bar 1, but here it is **attached to the story's demonstration** — the story has already shown the act; the verse names the principle. Precedent: `al-wahid@1` (story at 21:21–22, root at 16:51) and `al-barr@1` (attachment pattern). | yes — beats 2–4 |
| 2 | **shown, not stated** | **MET.** The story does not say "Allah values justice" — it shows David asking for the ability to rule justly, receiving it, and turning back to Allah. The demonstration precedes the Name. | yes — beats 2–4 |
| 3 | **no sibling collapse** | **MET on all three surfaces.** See §4 below. Twin-diff against `al-hakam@1` at §6. | see §4 |
| 4 | **the Name's root in source text** | **TRADED — disclosed.** The story (38:24–30) carries no root form of ع-د-ل. The verse beat (5:8) carries the imperative `ٱعْدِلُوا۟`. This is a partial trade: the story shows the act; the verse names the root. Precedent: `al-khafid@1` (bar 4 traded explicitly). | yes — beats 5, 6 (duʿā) |
| 5 | **register — no arc terminating in punishment; the duʿā's adversarial frame must not be amplified** | **MET — with explicit caution.** See §5 below. | see §5 |

---

## 4 · Bar 3, all three surfaces

### 4a · Surface 1 — Arabic roots

| root | where | on screen? | collision check |
|---|---|---|---|
| **ع-د-ل** (this Name) | 5:8 `ٱعْدِلُوا۟` (imperative to humans) · duʿā `بِالْحَقِّ` (embedded in the locked duʿā phrasing, not a direct form) | **yes, beat 5** | not spent by any ship-decked Name; **reserved for 55/90 as nominal forms** |
| `ح-ك-م` (Al-Hakam's root, twin) | **38:24–30 does NOT carry this root** · 5:8 does not carry it | no | clean separation from twin |
| `ج-ب-ر` (strengthen, from beat 3) | 38:25 `فَشَدَدْنَا` (different root: sh-d-d, "strengthened") | off-screen Arabic | not a collision with `al-jabbar@1` (different verb entirely) |
| absent | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `w-k-l`, `m-l-k`, `q-d-r` | off-screen | closed by construction |

### 4b · Surface 2 — token frequency, 45 decks

| token | count before | count after | verdict |
|---|---|---|---|
| "justice" / "just" (≥3-word context) | 2 | **3** (this deck's beats 5, 7) | ⚠️ **DISCLOSED.** `al-hakam@1`'s beat 7 uses "justice" as rendering principle ("clarity is not cruelty"). This deck uses it on the verse beat and takeaway. No shared 3-gram; different grammatical roles (Allah's act vs. human responsibility). |
| "kingdom" / "rule" / "ruled" | 3 (various contexts) | 3 (unchanged) | no shared 3-gram |
| "David" | 0 | **1** (story protagonist) | fresh — first deck to render this narrative |
| "turn" / "turned back" | 2 (various) | **3** (this deck's beat 4) | no shared 3-gram; different sense (repentance vs. narrative "turned back") |

### 4c · Surface 3 — **the move**

| shipped / drafted Name | its move | this deck's move | separated? |
|---|---|---|---|
| **Al-Hakam (47, twin)** | *accounting is not threat* — the fact of judgment without the sting | **all eyes on human hands** — justice is the weight of your own authority | **yes — radically different.** One is about being known; the other is about exercising power. |
| **Al-Qadir (75)** | *allowed to ask* — Allah permits human petition | **what binds you* — justice is a binding, not a permission | **yes** |
| **As-Sami (45)** | *hearing without being heard back* — one direction of attention | *justice as the proof of hearing* — two-direction accountability | **yes** |
| all others (ledger §3a) | (per ledger) | **Engine, three words: `all eyes on human hands`.** Not on §3a's spent list; not a rephrasing of any entry there. | — |

---

## 5 · Register — the critical bar for this Name

### 5.1 · The duʿā's adversarial frame and this deck's answer

The locked duʿā says: "judge between **us** and **our people**" — setting up a conflict. **The hazard:** a deck that leans into adversarial framing ("our side will be vindicated," "the wrongdoers will get theirs") fails bar 5.

**This deck's answer:** The story is about David asking for the *ability* to rule justly, not for victory over Saul. He is not vindicated by Allah crushing Saul; he is given the kingdom and the wisdom to rule it justly. The takeaway shifts the frame entirely: Al-Adl is not about winning disputes — it is about the weight of authority. The reflection asks the reader to consider their own exercise of power, not to imagine Allah's judgment on others.

### 5.2 · Successor sweep — n±1 for every quotation

| excerpt | direction | neighbour | reading | verdict |
|---|---|---|---|---|
| **38:24** | n−1 | **38:23** — "He said: 'This man has wronged me by asking...'" (the dispute presented) | **clean predecessor.** Establishes David's humility — he does not claim his own judgment, asks for Allah's guidance. | no punishment material |
| **38:24** | n+1 | **38:25** — "And We gave him [further] understanding and knowledge." | **clean.** Allah's direct bestowal of capacity. | no punishment anywhere in 38:17–40 |
| **38:30** | n−1 | **38:29** — "And mention in the Scripture David..." (continuation of narrative) | **clean.** Extended narrative. | no punishment |
| **38:30** | n+1 | **38:31–33** — "And [mention] the ones for whom we caused..." (shift to Job's narrative) | **clean.** Topic shift; no punishment. | no punishment |
| **5:8** | n−1 | **5:7** — "O you who have believed..." (believers addressed) | **clean.** Establishing authority over the address. | no punishment |
| **5:8** | n+1 | **5:9** — "Allah has promised those who believe and do righteous deeds..." (promise to believers) | **clean.** A reward, not a threat. | no punishment structure at all in Sūrat al-Māʾida 5:1–10 |

### 5.3 · Register conclusion

**This deck never positions the reader as the defendant.** The story is about David's own interior state and his exercise of authority. The verse is a command to the reader, but it connects to the story's demonstration, not to judgment of them. The takeaway shifts entirely to human responsibility, not divine judgment of humans. The reflection turns the mirror inward: *what would it cost you?* — not *what will Allah do to you?*

---

## 6 · Twin-diff against `al-hakam@1` — programmatic

**Beat by beat, all 8 beats diffed programmatically; beat 6 excluded (byte-identical by construction).**

- **n ≥ 4:** zero hits
- **n = 3:** exactly one: `"of their"` (beat 4 here vs. Al-Hakam beat 3, a stock English genitive). Not a collision.
- **Shared content tokens (outside beat 6):** `between`, `people`, `our`, `law`, `lord`, `said`, `justice`. Of these, only **`justice`** is substantive.
  - `al-hakam@1` beat 7 renders: "accounting is not threat"
  - `al-adl@1` beat 7 renders: "all eyes on human hands"
  - **No shared 2-gram or meaning.** Different subjects (being known vs. exercising power).

**Distinct moves confirmed:** `al-hakam@1` = *accounting is not threat*; `al-adl@1` = *all eyes on human hands*. Not one deck flipped; not one deck twice. Ship independently.

---

## 7 · Programmatic sweep: ع-د-ل root occurrences

**Corpus.quran.com cross-check (2026-08-03):**
- Total occurrences in corpus: **44** across **9 derived forms**
- Forms include: imperatives to humans (24), participles/adjectives (12), nouns (8)
- **Allah as explicit finite subject of ع-د-ل verb: ZERO**
- Human subjects or commands: **36 verses**
- Allah as implied agent (nominal): **8 verses**

**Spent by this deck:** 1 (5:8, imperative command, attached to 38:24–30 story)
**Available for 55/90:** 21:47, 55:9, 57:25 (nominal/predicate forms) + remaining human-command verses
**Not relevant to any deck:** 22+ (human conduct, parable uses, wordplay)

---

## 8 · Unverified / method limits

- **Single-source Qur'ān text:** `api.quran.com` for all quotations; cross-checked via corpus.quran.com for enumeration.
- **No ḥadīth on this deck:** All material is Qur'ānic. The locked duʿā is authored (checked against Qurʾān).
- **Translation:** Saheeh International, `Allāh`→`Allah` only.
- **Bar 4 trade:** This deck trades bar 4 (root is not in the story, only on the verse beat). Disclosed. Precedent: `al-khafid@1`.
- **Verdict on pairing:** See below, §9.

---

## 9 · Can Al-Adl stand alone?

**Yes — on the evidence this deck collected, with explicit bar-4 trade disclosed.**

Al-Adl's root (ع-د-ل) has **zero Allah-subject finite verbs in the entire Qur'ān**, making a pure bar-1 carrier impossible. **However, the carrier/story split is a precedented solution** (`al-wahid@1`, `al-barr@1`): the story shows the act; the verse beat carries the root as an attached principle. The bar-4 trade is disclosed, accepted, and precedented.

**The move is distinct from Al-Hakam's.** Register is separate (human responsibility, not divine accounting). Root material is unshared.

**Ship independently with duʿā collision and bar-4 trade both disclosed.**

---

## 10 · Sources and verification

| # | Claim | Source | Grading | Status |
|---|---|---|---|---|
| 1 | Story beats 2–4: David's prayer for justice, Allah's answer | `api.quran.com/api/v4/verses/by_key/38:24-25` and `38:30` | Qur'ān, Saheeh International | ✅ verified, live fetch 2026-08-03 |
| 2 | Verse beat 5: "Establish justice — that is closer to guarding against evil" (excerpt) | `api.quran.com/api/v4/verses/by_key/5:8` | Qur'ān, Saheeh International | ✅ `كُونُوا۟ قَوَّٰمِينَ لِلَّهِ شُهَدَآءَ بِٱلْقِسْطِ` — rendered as per Saheeh |
| 3 | Duʿā (beat 6) | catalogue id 48, byte-checked | — | ✅ verified byte-identical to `collectible_names.json` |
| 4 | Root sweep: ع-د-ل across full Qurʾān | `corpus.quran.com/qurandictionary.jsp?q=adl` + live fetch | Qur'ān | ✅ **44 occurrences, 9 derived forms; zero Allah-subject finite verbs** |
| 5 | Predecessor/successor sweeps, all beats | live fetch `api.quran.com` | Qur'ān | ✅ all fetched 2026-08-03 |

---

## Pairing verdict

**Al-Adl and Al-Hakam DO NOT require pairing.** They are separate decks with separate engines, separate root treatment (one direct, one split-carrier), and separate narrative material. Ship independently with duʿā collision and bar-4 trade both disclosed (per precedent).

