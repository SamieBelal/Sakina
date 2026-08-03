# Deck Draft — Al-Awwal (catalogue id 79) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-akhir-DRAFT.md`](./2026-08-03-al-akhir-DRAFT.md).** Ids 79 and 80 were
assigned and drafted **as a deliberate pair** — they share one catalogue `dua_arabic`, rasm-identical
(COLLISION-LEDGER §6a group 13).

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9bb.
Claims filed at `.context/claims/79.md` and `80.md` **before drafting**; the whole `.context/claims/`
directory (22 files at claim time) was read first, and re-read immediately before writing the
verification tables below.

All scripture verified at draft time by live fetch: Qur'an via `api.quran.com/api/v4`; hadith via
Wayback captures of the exact bare `sunnah.com` number, located via the CDX API. **Nothing here was
recalled, reconstructed or composed.**

---

## Deck `al-awwal@1` — Al-Awwal

**Why this deck exists, in one line:** the user whose problem feels like it came out of nowhere.
**There is a ṣaḥīḥ narration in which Allah's first act, before anything else existed, was to have
the decree of every future thing written down** — which means nothing that reaches you today reached
Him first.

**Selection ran duʿā-first.** Catalogue ids 79 and 80 share one `dua_arabic` — a mid-hadith excerpt
of the Prophet's ﷺ bedtime supplication (verified below to be **Sahih Muslim 2713a**, not an authored
invocation). That hadith names both Awwal and Akhir together, the same shape as Qur'an 57:3. **Neither
verse nor hadith, read as a pair-naming, demonstrates anything — it declares.** So bar 1 could not be
built on either the shared duʿā or on 57:3. It had to be built on a *different*, single-Name text, and
that is what sent this deck to the Pen hadith.

**The register decision, made first.** This Name's failure mode is abstraction — "before all
creation" is true and inert. So the deck does not open on cosmology. It opens on the one hadith where
"first" is not a description of Allah's *rank* but a fact about the **order of two events**: the Pen,
then everything else, including whatever the reader is carrying today.

**Proposed metadata**

```json
{
  "deck_id": "al-awwal@1",
  "name_id": 79,
  "transliteration": "Al-Awwal",
  "chip_keys": [],
  "position_in_pair": 1,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

> ⚠️ **Pairing note, read with Al-Akhir's own headline.** Both decks' `dua_arabic` render **the
> sibling Name's own English gloss** inside their own duʿā screen — id 79's duʿā contains the literal
> words *"You are the Last"*, and id 80's contains *"You are the First"*. This is not a shared root
> (the `al-khafid`/`ar-rafi` shape); it is the sibling's **Name itself**, on screen, in both
> directions. See "The shared duʿā screen" below for the full measurement. **Recommended:
> `position_in_pair: 1` (Name₁), with Al-Akhir at `2`** — beat 8 below is written as a pair-synergy
> beat. Whether the gate can enforce co-shipping is the same open engineering question ledger §9az
> already raised for Al-Khafid/Ar-Rafi'; not re-litigated here, only inherited.

**Beat 1 · bridge:**
> Before the thing you're carrying today had a name, there was already an answer written for it. This is the Name for what was there first.

**Beat 2 · name_intro** *(catalogue id 79 `english` verbatim, no authored gloss)*:
> الْأَوَّلُ — Al-Awwal — The First

**Beats 3–5 · story — "The Pen":**
> 3. At the end of his life, ʿUbadah ibn as-Samit called his son and told him what he had heard the Prophet ﷺ say about the very first thing Allah made.
> 4. "The first thing Allah created was the Pen. He said to it: Write."
> 5. "It said: My Lord, what shall I write? He said: Write the decrees of everything, until the Hour is established."

**Beat 6 · verse** *(partial quotation — visible ellipsis; does not carry bar 1, see below)*:
> "He is the First…" — Qur'an 57:3 (opening clause)

**Beat 7 · duʿā** *(catalog id 79, verbatim in full)*:
> اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ
> *Allahumma anta'l-Awwalu fa laysa qablaka shay', wa anta'l-Akhiru fa laysa ba'daka shay'*
> "O Allah, You are the First — nothing before You. You are the Last — nothing after You."
> **Source: Sahih Muslim 2713a (excerpt)** — see the shared duʿā section.

**Beat 8 · takeaway (pair-synergy):**
> Before your worry existed, the decree for it was already written — in the first thing He ever made. Al-Akhir, the second Name of your answer, is the One still there after it ends.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched URL / API key) | Grading | Status |
|---|---|---|---|---|
| 1 | The Prophet ﷺ said: "The first thing Allah created was the Pen. He said to it: Write. It asked: What should I write, my Lord? He said: Write what was decreed about everything till the Last Hour comes." (beats 4–5, primary carrier) | `sunnah.com/abudawud:4700` — Wayback capture `20240408121904` | **Sahih (Al-Albani)** — grade line printed on the page | ✅ `إِنَّ أَوَّلَ مَا خَلَقَ اللَّهُ الْقَلَمَ فَقَالَ لَهُ اكْتُبْ. قَالَ رَبِّ وَمَاذَا أَكْتُبُ قَالَ اكْتُبْ مَقَادِيرَ كُلِّ شَىْءٍ حَتَّى تَقُومَ السَّاعَةُ` — quoted in full, no elision |
| 2 | Corroborating route, quoted nowhere, narrated by ʿAtaʾ from al-Walid b. ʿUbadah from his father | `sunnah.com/tirmidhi:2155` — Wayback capture `20250905223959` | **Sahih (Darussalam)**, but ⚠️ at-Tirmidhi's own closing note on the same page reads `هَذَا حَدِيثٌ غَرِيبٌ مِنْ هَذَا الْوَجْهِ` ("gharib from this route") | ✅ verified (archive) — `إِنَّ أَوَّلَ مَا خَلَقَ اللَّهُ الْقَلَمَ فَقَالَ اكْتُبْ. فَقَالَ مَا أَكْتُبُ قَالَ اكْتُبِ الْقَدَرَ مَا كَانَ وَمَا هُوَ كَائِنٌ إِلَى الأَبَدِ` — same content, longer isnad chain (via the Az-Zukhruf preamble). **Not the deck's primary citation because of the gharib note; recorded as corroboration, not relied on alone** |
| 3 | Successor sweep, n−1: Abu Dawud 4699 | `sunnah.com/abudawud:4699` — Wayback `20220908200024` | Sahih (Al-Albani) | ✅ fetched, quoted nowhere. A **different** narration (Ibn ad-Daylami asking Ubayy b. Kaʿb about qadar), same chapter. Contains a conditional punishment clause (*"were Allah to punish everyone… He would do so without being unjust"*) and ends *"were you to die on other than this you would enter the Fire."* **Disclosed**: same chapter, adjacent number, not a continuation of beat 4–5's narration, not quoted or alluded to |
| 4 | Successor sweep, n+1: Abu Dawud 4701 | `sunnah.com/abudawud:4701` — Wayback `20220127212650` | Sahih (Al-Albani) | ✅ fetched, quoted nowhere. The Adam/Musa disputation — Adam answers Musa's blame with *"a decree He wrote for me forty years before He created me"*. **Clean**: no punishment, and it reinforces the same theme (decree predates the event), which is why it is disclosed rather than borrowed from |
| 5 | Successor sweep within Abu Dawud 4700's own text: the hadith continues past the deck's quotation, on the same page | same page as row 1 | Sahih (Al-Albani) | ✅ the full hadith continues: *"Son, I heard the Messenger of Allah ﷺ say: He who dies on something other than this does not belong to me."* **Not quoted on any beat.** A fidelity/disownment clause, not a narrated punishment scene; disclosed rather than used |
| 6 | "He is the First…" (beat 6) | `api.quran.com/api/v4/verses/by_key/57:3?fields=text_uthmani,text_imlaei&translations=20` | Qur'an | ✅ `text_uthmani`: `هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`. Saheeh International (resource 20): *"He is the First and the Last, the Ascendant and the Intimate, and He is, of all things, Knowing."* **Beat 6 renders only "He is the First…" — visible ellipsis, does NOT carry bar 1 (see below)** |
| 7 | Successor/context sweep: 57:2 and 57:4 | `verses/by_key/57:2`, `verses/by_key/57:4` | Qur'an | ✅ fetched. 57:2: *"His is the dominion of the heavens and earth. He gives life and causes death…"* — no punishment. 57:4: *"…He is with you wherever you are…"* — continues the *same* clause-chain but toward **Az-Zahir/Al-Batin's** territory (omnipresence, inside/outside knowledge), not Awwal/Akhir's. **Neither quoted; flagged for a future 81/82 drafter in the claim file** |
| 8 | The dua (catalog id 79) traced to Sahih Muslim 2713a | `sunnah.com/muslim:2713` — Wayback capture `20250811110019` | **Sahih (Muslim, collection-level)** | ✅ verified (archive) — see full treatment in "The shared duʿā screen" below |
| 9 | Root sweep, ʾ-w-l | `corpus.quran.com/qurandictionary.jsp?q=Awl` | — | ✅ **170 total occurrences** across 4 derived forms (nominal *awwal* 82, *ūlī* 45, *āl* 26, *taʾwīl* 17). Cross-checked against the project's standing limit (§9av): this is a dictionary-page count, not a hand-verified verse-by-verse enumeration — see "What I could not determine" |

---

### The five bars

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met once, in the hadith, and nowhere else this deck reaches.** Abu Dawud 4700: Allah's own recorded speech, `فَقَالَ لَهُ اكْتُبْ` / `قَالَ اكْتُبْ مَقَادِيرَ كُلِّ شَىْءٍ حَتَّى تَقُومَ السَّاعَةُ` — a finite verb of Allah's own action (commanding, then dictating), inside a Prophetic narration. **⚠️ Beat 6 does NOT carry bar 1** — 57:3's *"He is the First"* is an appositive declaration, exactly the failure mode the task brief names; the deck does not rest on it. Precedent for a verse beat that does not carry bar 1: `al-khafid@1`'s 28:83 | **yes — beats 4–5 only** |
| 2 | **the distinguishing quality is shown, not stated** | No beat asserts *"Allah has always existed"* or *"nothing precedes Him"* (that is catalogue id 79's own `meaning`, deliberately not used as a beat). The story **shows** the shape instead: a specific first object, a specific first instruction, and the scope of what gets written before anything else exists. The reader is never told what "first" means in the abstract — they watch what happened first | **yes — beats 4–5** |
| 3 | **no sibling collapse, including against its own twin** | Three surfaces run below, plus a beat-by-beat twin-diff against Al-Akhir | **yes, with disclosures itemised below** |
| 4 | **the Name's own root appears in the source text** | **Met, not traded.** `أَوَّلَ` (root `ʾ-w-l`) appears in beat 4's own quotation, in Allah's narrated speech about His own first act — not the grammatical Divine-Name construction (`al-Awwal`), but the same triliteral root, doing real work in the sentence (a temporal ordinal describing Allah's own first creation). Stated at that precise, narrower size rather than overclaimed | **yes — beat 4, in English (story beats render `arabic: ""` in 42/42 shipped precedent, so the root is not visible in Arabic on screen)** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | Abu Dawud 4700's own continuation (row 5 above) is a disownment/fidelity clause, not a punishment scene, and is not quoted. n−1 (row 3) carries a conditional punishment clause but is a **different narration** in the same chapter, not a continuation, and is not quoted or alluded to. n+1 (row 4) is clean. **No beat in this deck describes, alludes to, or ends adjacent to a punishment scene** | **swept both directions; one adjacent-chapter row disclosed, non-blocking** |

### Bar 3, surface 1 — Arabic roots

| root in this deck | where | renders in Arabic? | collision check |
|---|---|---|---|
| `ʾ-w-l` — the Name's own | Abu Dawud 4700 `أَوَّلَ`; duʿā `الْأَوَّلُ`; verse `ٱلْأَوَّلُ` | **yes — beat 7 (duʿā) and beat 6 (verse)** | Spent by no shipped/drafted deck. Corpus-wide it is dense (170 occurrences, row 9) but the vast majority are `ūlī`/`āl`/`taʾwīl` or the idiom "first to do X" (Musa at 7:143, the Prophet ﷺ at 6:14) — none of it claimed elsewhere |
| `ʾ-kh-r` — the twin's root | duʿā `الْآخِرُ` (both directions of the shared string); verse fragment excluded (ends before `وَٱلْـَٔاخِرُ`) | **yes — beat 7 only** | **Catalogue-locked, unfixable inside this deck.** Same finding as Al-Akhir's duʿā rendering `الْأَوَّلُ`. See the shared duʿā section |
| `q-d-r` (`مَقَادِيرَ`) | Abu Dawud 4700, beat 5 | no (story beats render `arabic: ""`) | ⚠️ `al-qadir@1` [D] and Al-Muqaddim/Al-Muakhkhir (77/78, undecked) share this root family. English rendering is *"decrees"*, not *"Capable"/"Able"* — no shared rendered string with `al-qadir@1`. Disclosed, non-blocking |
| `s-w-r` (`ٱلسَّاعَةُ` — no, this is `s-w-ʿ`) | beat 5 *"until the Hour is established"* | no | eschatological register word, ordinary; no deck claims it |

### Bar 3, surface 2 — token frequency over all 34 shipped decks (beat 7 swept from its first character, §9as)

| token this deck renders | n across 34 shipped decks | decks | verdict |
|---|---|---|---|
| `pen` (whole-word), `decree`/`decreed` (as used here), `crawl*`, `mock*`, `laugh*`, `ten times`, `forelock`, `already full`, `write the decree`, `wrote the decree` | **0** each — computed programmatically, see table below | — | clean — this deck's entire distinctive vocabulary is unspent |
| `first` | **7** — `al-muid@1`, `ar-raheem@1` (×2), `al-haqq@1` (×3), `al-wasi@1`, `an-nur@1` | all generic ("the first to X", "the first: 'And...'"), none a Name-gloss or a claim about Allah's own firstness | clean — no shared 3-gram, no Name-gloss usage elsewhere |
| `decree` | **2** — `al-lateef@1` beat 7 duʿā (*"destiny has decreed"*), `al-qayyum@1` beat 4 story (*"the time of their death"*, unrelated clause) | different sense (submission to fate vs. the Pen's own decree-writing act); zero shared run ≥3 | non-blocking |
| `write`/`wrote`/`written` | **0** | — | first occurrence in the corpus |

*(Full token pass script and raw counts are recorded in this session; see "What I could not determine" for the method's limits.)*

### Bar 3, surface 3 — the move

| shipped/drafted deck | why a user could think they had been told the same thing twice | measured difference |
|---|---|---|
| **`al-qayyum@1`** [D] — *"nothing that keeps you has ever needed a night off"* | Both decks are about something that predates and outlasts the reader's own timeline. | Al-Qayyum's engine is **ongoing sustaining, uninterrupted** (a continuous present). This deck's engine is a **single completed act at the very start** (the Pen, written once, "until the Hour"). One is about *now, always*; this one is about *then, once, and it already covers you*. No shared scripture, no shared rendered string |
| **`al-qadir@1`** [D] — Ibrahim's four birds, *"He already believed. He asked to be shown anyway"* | Both involve Allah's own recorded speech in a two-line exchange (question, then answer). | Different register entirely: Al-Qadir is about being **permitted to ask**; this deck is about a decree **already settled before anyone could ask**. Zero shared vocabulary beyond ordinary function words |
| **`al-baqi@1`** [S] — *"what Allah has is lasting"*, an inventory that inverts | Both are about what does or doesn't run out over time. | Al-Baqi's move is **retrospective** (what's left after loss). This deck's move is **prospective** (what was fixed before anything began). Opposite temporal direction. See Al-Akhir's draft for the fuller Al-Baqi differentiation, since that Name sits closer to Al-Akhir |
| **`al-akhir@1`** (twin) | — | **See the twin-diff below — written once, here, not duplicated in the sibling draft.** |

### Twin-diff — Al-Awwal vs Al-Akhir, beat by beat

| beat | Al-Awwal | Al-Akhir | shared run ≥4 words? |
|---|---|---|---|
| 1 bridge | "Before the thing you're carrying today had a name…" | "Something you're sure is over, one day, all of it will be…" | **yes — 6 words: "…this is the Name for…"** |
| 2 name_intro | "The First" | "The Last" | no (catalogue-locked, different words) |
| 3-5 story | The Pen — a single first act, before creation | The last man out of the Fire — a single last act, at the end of judgement | zero shared vocabulary; different narrators, different collections, different chapters |
| 6 verse | "He is the First…" (57:3 opening) | "…and the Last…" (57:3 mid-clause) | **shares only the connective from the same āyah; the two fragments do not overlap in rendered text** — see the 57:3 disclosure |
| 7 dua | byte-shared with Al-Akhir (catalogue-locked) | byte-shared with Al-Awwal | **fully shared — this is the one beat where both decks render the same string, disclosed at full strength below** |
| 8 takeaway | pair-synergy, ends on Al-Akhir | standalone, does not reference Al-Awwal | no |

**Computed, not eyeballed** (`difflib.SequenceMatcher` longest-match over every beat pair, both decks,
beat 7 excluded as deliberately shared): **the actual longest cross-deck run is 6 words, at beat 1 —
both bridges close on "…this is the Name for…".** My own first draft of this row said "zero words at
n≥4", which was wrong; corrected here rather than silently fixed, per the standing rule to diff prose
against the table before shipping (ledger §9aj). **Non-blocking**: "This is the Name for [X]" is
already a standing bridge template, used verbatim by four *shipped* decks before this pair
(`ar-raheem@1`, `al-malik@1`, `al-kareem@1`, `al-mujeeb@1`) — it is scaffolding, not a collision,
under the same rule the ledger applies to "For the weight you named…" (§4b). **Own-beat diff within
each deck** (§9al): Al-Awwal's own beats top out at a 3-word run ("first thing Allah", beats 3–4);
Al-Akhir's at 3 words ("and the Last", beats 3/6). No pair at n≥4 inside either deck.

---

## The shared duʿā screen

**Both decks render the identical duʿā beat.** Catalogue ids 79 and 80 carry the same `dua_arabic`,
`dua_transliteration` and `dua_translation` (COLLISION-LEDGER §6a group 13) — this is a catalogue
fact, not a drafting choice, and neither deck can change it.

**What this pass adds: the duʿā is not an authored invocation. It is Sahih Muslim 2713a, excerpted.**
Sunan editors sometimes assume catalogue duʿās with no citation are authored; this one traces
cleanly. Suhayl reports that Abu Salih used to instruct: when about to sleep, lie on your right side
and say a longer invocation that includes, verbatim mid-hadith:

> `اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَىْءٌ وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَىْءٌ وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَىْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَىْءٌ`

Catalogue id 79/80's `dua_arabic` (`اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ
الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ`) is the **first half** of this clause, stopping before Zahir/Batin.
Catalogue id 81/82's `dua_arabic` is the **second half** (confirmed by reading both catalogue entries
directly — see the claim files). **The catalogue split one hadith into two duʿā pairs.**

**Rasm-identical, not byte-identical** (§9ax vocabulary). Diffs, computed by comparison, not
eyeballed: catalogue `أَنتَ` vs sunnah.com `أَنْتَ` (sukun); catalogue `شَيْءٌ` vs sunnah.com `شَىْءٌ`
(ya vs alif maqsura, a standard digitisation-convention difference); hamza-seat rendering on
`الْأَوَّلُ`/`الْآخِرُ`. All three are orthographic, not textual — the consonantal skeleton and every
word match.

**Recommendation for `renderedDuaSources`:** `"al-awwal@1": "Sahih Muslim 2713a (excerpt)"` and
`"al-akhir@1": "Sahih Muslim 2713a (excerpt)"` — the `(excerpt)` disclosure follows the precedent set
by `al-aleem@1`'s `"(opening words)"` and `al-malik@1`'s `"(opening)"`, since the gate-locked Arabic
cannot itself carry an ellipsis mark.

**What renders identically on both screens, and what does not.** Arabic, transliteration and
translation are byte-shared between the two decks — a user who collects both Names in one session
sees the same duʿā twice. This is the catalogue's own construction (one hadith, two Name-pairs) and
is disclosed rather than concealed; no beat in either deck claims the duʿā is Name-specific.

---

## The 57:3 note — what was spent here, and what is left for ids 81/82

**57:3 names four Names in one clause:** `هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ ۖ
وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`. This deck's verse beat renders **only** `هُوَ ٱلْأَوَّلُ` (with a
visible ellipsis marking that the clause continues) — the smallest fragment that names this deck's
own Name and nothing past it.

**Deliberately not rendered, in Arabic or English, on this deck:** `وَٱلْـَٔاخِرُ` (ceded to
Al-Akhir's own fragment — see its draft), `وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ` (left whole and untouched),
and the closing `وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ` (Al-Aleem's territory, already shipped as `al-aleem@1`
on a different āyah — not examined here, not needed).

**Also flagged, not spent:** 57:4 (`وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ` — "He is with you wherever you
are") continues the same passage in the direction of omnipresence / inside-outside knowledge, which
reads as Az-Zahir/Al-Batin's territory, not Awwal/Akhir's. Fetched and read (row 7), quoted nowhere,
recorded in the claim file so a future 81/82 drafter does not have to re-derive it.

**This deck treats 57:3 exactly as the task brief warns against if used as bar 1's carrier — a chain
of appositive epithets — and does not use it that way.** It is verse-beat-only, disclosed as not
carrying bar 1, with the actual demonstration living entirely in the Pen hadith.

---

## Rejected — fetched, evaluated, and recorded so nobody re-derives it

| candidate | what it is | why refused |
|---|---|---|
| **Qur'an 21:104** (`كَمَا بَدَأْنَآ أَوَّلَ خَلْقٍ نُّعِيدُهُۥ`) | "As We began the first creation, We will repeat it" — carries `ʾ-w-l` (`أَوَّلَ`) in Allah's own first-person promise | **Refused on bar 3.** The verb `نُّعِيدُهُۥ` (root `ʿ-w-d`, "We will repeat/restore it") is **shipped `al-muid@1`'s own Name-root** — that deck's own sweep (recorded in its draft) reads this exact āyah as one of seven `ʿ-w-d` candidates it examined and did not select. Using 21:104 here would put a sibling Name's root in English translation ("repeat") on this deck's own screen. Bar 1 is also weaker: the demonstrated act is re-creation, not "firstness" as such |
| **Qur'an 29:19–20** (`كَيْفَ يُبْدِئُ ٱللَّهُ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ`) | The same re-origination theme, `an-nashʾa al-ākhirah` at 29:20 | **Same reason as above** — `ʿ-w-d` root, already swept and left unclaimed by `al-muid@1`. Held free for a future drafter, not spent here |
| **Qur'an 53:25** (`وَإِنَّ لِلَّهِ ٱلْـَٔاخِرَةَ وَٱلْأُولَىٰ`) | "And to Allah belongs the Last [life] and the First" | **Refused on bar 2 and on ambiguity.** `al-ākhirah` here means *the Hereafter*, not "the Last" as a divine epithet — using it would blur two different senses of the same root for a reader who cannot see the distinction. It is also a possession-statement (*"belongs to"*), not a demonstrated act |
| **Qur'an 6:14, 7:143, 39:12** (Musa/the Prophet ﷺ declaring themselves "first") | Human speech using `awwal` | **Rejected class** — human speech about being first, not Allah's own act (ledger §2d's "human speech about Allah" class) |
| **Bukhari 6570** (the luckiest-by-intercession hadith, n−1 of Al-Akhir's citation) | Adjacent chapter material | Not this deck's; examined as part of Al-Akhir's successor sweep, recorded there |

---

## Catalogue findings — reported, **NO change recommended**

1. **Id 79's `hadith` card field already correctly attributes Muslim** ("The Prophet ﷺ prayed: 'O
   Allah, You are the First…'" (Muslim)) — this pass confirms the attribution is right (Sahih Muslim
   2713a) and no more specific than the card claims. No change needed.
2. **Id 79's `dua_arabic` is shared with id 80** (§6a group 13) — catalogue-level, already the subject
   of the shared duʿā section above. No recommendation.
3. **Both decks' duʿā screens render the sibling Name's English gloss** — disclosed in the pairing
   note. Catalogue-locked; no recommendation.

---

## What I could not determine, and what a verifier should attack first

1. **The `ʾ-w-l` root sweep (170 occurrences) was not hand-verified verse by verse.** It rests on
   `corpus.quran.com`'s categorised dictionary page, which itself groups by derived form. I spot-
   checked the sample entries it surfaced (2:41, 6:14, 21:104) against `api.quran.com` and they match;
   I did not independently re-derive the total of 170 from the raw Uthmani text the way `al-basit@1`'s
   verifier did for `b-s-ṭ` (§9av). If the true count differs, it does not change this deck's
   selection — no candidate beyond 21:104/29:19 (already rejected on other grounds) was found.
2. **At-Tirmidhi 2155's own "gharib" note is disclosed but not resolved.** I did not consult a third
   collection or an isnad study to determine whether the *content* is independently corroborated
   beyond Abu Dawud 4700's separate chain (which the deck relies on primarily, precisely because it
   carries a clean grade with no such caveat).
3. **Hadith checking is not independent of sunnah.com as a corpus.** No isnad audited; no printed
   edition, Shamela, or Dorar consulted — standing limit, unchanged.
4. **Whether the founder wants `position_in_pair: 1/2` enforced by a gate mechanism** is unresolved
   engineering, inherited from ledger §9az (Al-Khafid/Ar-Rafi'), not decided here.
5. **The rows to attack first, in order:** (a) whether beat 6's disclosed non-bar-1 status is
   acceptable at all, given the task brief's explicit warning about 57:3; (b) the 21:104/29:19
   rejection reasoning (a verifier should confirm `al-muid@1`'s own draft really does list these as
   examined-not-selected, not selected); (c) whether the Pen hadith's root match (`أَوَّلَ` as a
   temporal ordinal, not the Name form) is a legitimate bar-4 satisfaction or should be recorded as a
   trade like `al-haleem@1`/`al-waliyy@1`.
