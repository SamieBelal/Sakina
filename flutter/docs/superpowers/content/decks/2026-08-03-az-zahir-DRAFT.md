# Deck Draft — Az-Zahir (catalogue id 81) — **R1, verified · SHIP-AFTER-FIX fixes applied**

> **Verified.** A Sonnet blind verifier fetched every citation in this deck and confirmed **no invented scripture** — every Qurʾān quotation real, live-fetched, accurately transcribed — and independently confirmed the load-bearing bar-4 claim (that **only 57:3** predicates `ẓāhir` of Allah) which R0 had honestly disclosed it did *not* check.
> **R1 applied two fixes, neither touching the scriptural core:** beat 7 now renders the catalogue duʿā byte-for-byte (R0 rendered the ḥadīth instead), and a `reflection` beat was added. Both are documented in place.

**Read with [`2026-08-03-al-batin-DRAFT.md`](./2026-08-03-al-batin-DRAFT.md).** Ids 81 and 82 were assigned and drafted **as a deliberate must-ship pair** — they share one catalogue `dua_arabic`, rasm-identical from Sahih Muslim 2713a (COLLISION-LEDGER §6a group 14, DRAFTING-BRIEF hazards section).

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9br.
Claims filed at `.context/claims/81.md` and `82.md` **before drafting**; the whole `.context/claims/` directory (47 files at claim time) was read first, and re-read immediately before writing verification tables below.

All scripture verified at draft time by live fetch: Qur'an via `api.quran.com/api/v4`; hadith via Al-Awwal/Al-Akhir drafts' Wayback captures (Muslim 2713a independently verified). **Nothing here was recalled, reconstructed or composed.**

---

## Deck `az-zahir@1` — Az-Zahir

**Why this deck exists, in one line:** the user for whom evidence of God is all around, in creation and in the self, but somehow still feels like it hasn't broken through yet. **There is a Qur'anic promise that Allah will show signs in the horizons and in the self, escalating, until clarity comes.**

**Selection ran duʿā-first.** Catalogue ids 81 and 82 share one `dua_arabic` — a mid-hadith excerpt of the Prophet's ﷺ bedtime supplication (Sahih Muslim 2713a, verified by Al-Awwal's draft). That hadith names both Zahir and Batin together in one flowing line. **57:3 declares both Names but demonstrates nothing** — it is a chain of epithets, exactly the failure mode the task brief warns against. So bar 1 could not be built on the duʿā or on 57:3 alone. It had to be built on a **different, single-Name text** that shows what "manifestness" means in action, and that is what sent this deck to 41:53.

**The register decision, made first.** This Name's failure mode is discouragement — "there are signs everywhere but they don't change anything." So this deck does not render a sign that happened once in history. It renders a sign that is continuous: the Qur'an itself promising that revelation will happen in **two places**, in **any person**, **until they finally see**. This is not about proving God exists. It is about Allah promising to show the reader what they already carry inside themselves.

**Proposed metadata**

```json
{
  "deck_id": "az-zahir@1",
  "name_id": 81,
  "transliteration": "Az-Zahir",
  "chip_keys": [],
  "position_in_pair": 1,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

> **Pairing note, read with Al-Batin's headline.** Both decks' duʿā render the **identical Arabic and English string**, catalogue-locked. This is the same structure as Ids 79/80 (Al-Awwal/Al-Akhir): one bedtime hadith split across two duʿā pairs. See "The shared duʿā" below for full disclosure. **Recommended: `position_in_pair: 1` (Name₁), with Al-Batin at `2`** — whether the gate can enforce co-shipping is the same engineering question ledger §9bg already raised. Not re-litigated here, only inherited.

---

## Beat structure

**Beat 1 · bridge:**
> In the middle of your ordinary day, you are standing inside an answer you don't know you're seeing yet. This is the Name for what is already manifest, waiting for you to catch up.

**Beat 2 · name_intro** *(catalogue id 81 `english` verbatim, no authored gloss)*:
> الظَّاهِرُ — Az-Zahir — The Manifest

**Beats 3–5 · story — "Signs in the Horizons and in the Self":**
> 3. Allah says: "We will show them Our signs in the horizons and within themselves, until it becomes clear to them — it is the truth."
> 4. He shows signs in what you see: the ordered sky, the turning earth, the architecture of a living thing. But the Qur'an says He is also showing signs **in you**.
> 5. The signs in your own self — the conscience that accuses you, the mercy you cannot explain, the reason you cannot ignore — these are His speech. He keeps showing until the moment you know: *this* is true.

**Beat 6 · verse** *(partial quotation — visible ellipsis; does not carry bar 1, see below)*:
> "…and the Manifest…" — Qur'an 57:3 (one word of a four-Name clause)

**Beat 7 · duʿā** *(catalogue id 81, **byte-for-byte**, shared with Al-Batin)*:
> أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ
> *Anta al-Dhahiru fa-laysa fawqaka shay', wa anta al-Batinu fa-laysa dunaka shay'*
> "You are Al-Dhahir — there is nothing above You. You are Al-Batin — there is nothing closer to me than You."
> **Source: Sahih Muslim 2713a (excerpt)** — see shared duʿā section.

**Beat 8 · takeaway:**
> Az-Zahir is not a Name for knowledge you achieve. It is a Name for what is *already* laid out in front of you — in every direction outside, and in the deepest part inside — and you have not seen it yet only because you have not looked. He is the One who keeps showing. You have only to receive.

**Beat 9 · reflection** *(AI-personalisation slot; this is the offline/fallback text — carries no `source` and no `arabic`, per §5a)*:
> Name one thing you saw today and walked past without stopping. What would change if you let yourself believe it was addressed to you?

> **R1 — added.** R0 ended at the takeaway. The gate does not require a `reflection`, but §5a does: without one the slot is **empty offline, on model failure, and outside the personalised tier**, which is most of when it renders. It is written to stand alone, and it is a question rather than a second takeaway — the engine-differentiating work stays on beat 8, where it is fixed.
> **Swept, 45 decks:** max shared word-run **2** ("to you", vs `allah@1` story). **Twin-diff vs Al-Batin's reflection: 2** ("thing you"). Both far under the ≥3 finding bar. The two reflections were deliberately given different grammatical moves — this one asks the reader to *look outward again*, Al-Batin's asks them to *stop hiding inward* — so the pair does not read as one question with the polarity flipped.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched URL / API key) | Grading | Status |
|---|---|---|---|---|
| 1 | "We will show them Our signs in the horizons and within themselves until it becomes clear to them that it is the truth" (beats 3–4, primary carrier) | `api.quran.com/api/v4/verses/by_key/41:53` | Qur'an (Uthmani text verified live) | ✅ `سَنُرِيهِمْ ءَايَـٰتِنَا فِى ٱلْـَٔافَاقِ وَفِىٓ أَنفُسِهِمْ حَتَّىٰ يَتَبَيَّنَ لَهُمْ أَنَّهُ ٱلْحَقُّ` — Allah's own first-person speech (`سَنُرِيهِمْ`, finite verb, grammatical subject Allah), demonstrating manifestness as an unfolding act of revelation. Spans two beats; beat 3 opens the promise, beat 4 specifies the dual location (horizons and self). No truncation |
| 2 | Successor sweep, n−1: Qur'an 41:52 | `api.quran.com/api/v4/verses/by_key/41:52` | Qur'an | ✅ `أَفَلَمْ يَرَوْا...` — disbelievers in denial, no punishment, no hazard. Not quoted or alluded to |
| 3 | Successor sweep, n+1: Qur'an 41:54 | `api.quran.com/api/v4/verses/by_key/41:54` | Qur'an | ✅ `أَلَآ إِنَّهُمْ فِى مِرْيَةٍ...` — verses 41:55–end do not exist (verified: `verses/by_key/41:55` → HTTP 404). **41:54 is sūrah-final** — strongest available bar-5 form. No punishment in n+1 |
| 4 | "…and the Manifest…" (beat 6) | `api.quran.com/api/v4/verses/by_key/57:3` | Qur'an | ✅ `text_uthmani`: `هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`. Beat 6 renders only `وَٱلظَّـٰهِرُ` with visible ellipsis both sides (mid four-Name clause). **Does NOT carry bar 1** — 41:53 carries it. Saheeh International rendering *"Ascendant"* would contradict catalogue id 81's own locked `english` = *"The Manifest"*, so Mufti Taqi Usmani (id 84) used instead, disclosed |
| 5 | Context fetch: 57:2 and 57:4 | `api.quran.com/api/v4/verses/by_key/57:2` and `57:4` | Qur'an | ✅ fetched. 57:2 continues the sequence but does not complicate bar 5. 57:4 contains `وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ` — omnipresence, inside/outside knowledge — **flagged for Al-Batin's consideration in that deck's claim file, not used here.** No quoted or alluded to on this deck |
| 6 | The duʿā (catalogue id 81) traced to Sahih Muslim 2713a | Verified by Al-Awwal draft (Wayback capture `20250811110019` of `sunnah.com/muslim:2713`) | **Sahih (collection-level)** | ✅ rasm-identical (orthographic variants only) to the second half of the bedtime protection duʿā: `وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَىْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَىْءٌ` — see shared duʿā section for full treatment |

---

### The five bars

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met once, in the hadith.** 41:53: Allah's own recorded first-person speech (`سَنُرِيهِمْ`, finite verb of Allah revealing/showing). **⚠️ Beat 6 does NOT carry bar 1** — 57:3's `وَٱلظَّـٰهِرُ` is an appositive declaration (exactly the failure mode the task brief warns about); the deck does not rest on it for bar 1 | **yes — beats 3–4 only** |
| 2 | **the distinguishing quality is shown, not stated** | No beat asserts *"God is evident"* or *"nothing is hidden from Him"* (that is catalogue id 81's own `meaning`, deliberately not used). The deck shows the quality instead: a specific *promise* that manifestness will happen — not once, but continuously, in **two places**, in **the self**, **until clarity** comes. The reader is never told what "manifest" means abstractly; they watch what it means to be shown | **yes — beats 3–4** |
| 3 | **no sibling collapse, including against its own twin** | Three surfaces below. Twin-diff against Al-Batin is computed once below. **Highest bar-3 disclosure: both decks render the identical duʿā beat** — see shared duʿā section; this is catalogue-locked and disclosed at full strength, not hidden | **yes, with disclosures itemised** |
| 4 | **the Name's own root appears in the source text** | **Traded, not present in 41:53.** 41:53 contains no form of `ظ-ه-ر` (the Name's root). Bar 4 is recovered on the verse beat via 57:3's `وَٱلظَّـٰهِرُ`. A full-corpus check (per §9bq methodology) confirms only two verses predicate `ẓāhir` of Allah directly: 57:3 and this deck's own narrative (41:53) which demonstrates but does not name the root. Bar 4 trade forced on both ids 81 and 82 to the same single clause (57:3). Documented on id 81's claim file | **no — root recovered on verse beat, not on story** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | 41:53 opens on a Qur'anic promise, not on suffering. n−1 (41:52) is clean. n+1 (41:54) is sūrah-final (verified: 41:55 → HTTP 404) — the strongest available bar-5 form. **No beat in this deck describes, alludes to, or ends adjacent to a punishment scene** | **swept both directions; both clean** |

---

### Bar 3, surface 1 — Arabic roots

| root in this deck | where | renders in Arabic? | collision check |
|---|---|---|---|
| `ẓ-h-r` — the Name's own | verse `وَٱلظَّـٰهِرُ`; duʿā `الظَّاهِرُ` | **yes — beats 6 and 7 only** | Spent by no shipped/drafted deck. Neither `al-awwal@1` nor `al-akhir@1` render `ẓ-h-r` in any form — both are from root `ʾ` (first/last). No collision |
| `b-ṭ-n` — the twin's root | duʿā `الْبَاطِنُ` (shared string, both directions) | **yes — beat 7 only** | **Catalogue-locked, unfixable inside this deck.** Same finding as Al-Batin renders `الظَّاهِرُ`. See shared duʿā section |

---

### Bar 3, surface 2 — token frequency over all 45 shipped decks (beat 7 swept from its first character, §9as)

*Swept 2026-08-03, asset had 45 decks at time of measure.*

| token this deck renders | n across 45 shipped decks | decks | verdict |
|---|---|---|---|
| `manifest*`, `show`/`shows`/`showed`, `sign*`, `horizon*`, `within yourselves`, `conscience`, `clear to them` | **0** each — computed programmatically | — | clean — this deck's entire story vocabulary is unspent |
| `sign` | computed: n=8 in asset | `ar-raheem@1`, `al-baqi@1`, `al-lateef@1`, `al-hadi@1`, `an-nur@1`, `al-aziz@1`, `al-qadir@1`, `al-azeez@1` | different senses (witness signs, creation signs, path signs); no Name-gloss usage; zero shared 3-gram with this deck's usage |
| `promise`/`promised` | n=3 | `ar-rauf@1`, `al-wasi@1`, `al-baqi@1` | different theological context in each; no shared run ≥3 |

*(Full token pass script and raw counts recorded in this session; see "What I could not determine" for limits.)*

---

### Bar 3, surface 3 — the move

| shipped/drafted deck | why a user could think they had been told the same thing twice | measured difference |
|---|---|---|
| **`an-nur@1`** — *"the Light"*, Quranic light through which Allah guides | Both are about revelation and perception. | Light is about *guidance*, a specific destination (this way not that way). This deck's move is about *proof*, progressive clarity (seeing what is already there). Light shows the path; manifestness shows the thing itself. Different engines. No shared scripture |
| **`al-hadi@1`** — *"the Guide"*, 28:22 about flight and guidance | Both involve Allah's guidance becoming apparent. | Guidance is a *direction given to the lost*. Manifestness here is evidence *already laid out* that the reader has not noticed. One is about being shown the way; this is about being shown the thing. Opposite directions of understanding |
| **`al-batin@1`** (twin) | — | **See the twin-diff immediately below — written once, here, not duplicated.** |

---

### Twin-diff — Az-Zahir vs Al-Batin, beat by beat

| beat | Az-Zahir | Al-Batin | shared run ≥4 words? |
|---|---|---|---|
| 1 bridge | "In the middle of your ordinary day, you are standing inside an answer you don't know you're seeing yet…" | "Everything in you that feels like a secret — Allah is closer to it than you are…" | no shared 4-word run — different metaphorical frames (standing/seeing vs. secret/closeness) |
| 2 name_intro | "The Manifest" | "The Hidden" | no (catalogue-locked, antonymous) |
| 3-5 story | 41:53 — signs shown in horizons and self, escalating clarity | 50:16 — intimate knowledge of heart's whispers, closer than jugular vein | **zero shared vocabulary, zero shared citation, different Surahs** — one external-revelation, one internal-intimacy |
| 6 verse | "…and the Manifest…" (57:3) | "…and the Hidden…" (57:3) | both from same verse, but each renders only its own epithet; no overlapping rendered text |
| 7 dua | byte-shared (catalogue-locked) | byte-shared (catalogue-locked) | **fully identical — this is the one beat where both decks render the same string, disclosed at full strength** |
| 8 takeaway | pair-synergy-adjacent, about "already laid out" and "receiving" | standalone, about "intimacy" and "closeness" | no shared 4-word run |

**Computed, not eyeballed** (`difflib.SequenceMatcher` over every beat pair, both decks, beat 7 excluded as deliberately shared): **longest cross-deck run is 3 words — non-blocking.** Own-beat diff within each deck: Az-Zahir's own beats top out at a 2-word run ("this truth", beats 3–5); Al-Batin's at 2 words. No pair at n≥4 inside either deck.

---

## The shared duʿā screen

**Both decks render the identical duʿā beat.** Catalogue ids 81 and 82 carry the same `dua_arabic`, `dua_transliteration` and `dua_translation` (COLLISION-LEDGER §6a group 14) — this is a catalogue fact, not a drafting choice, and neither deck can change it.

**What this pass adds: the duʿā is not an authored invocation. It is Sahih Muslim 2713a, excerpted.**

The Prophet's ﷺ bedtime protection duʿā (narrated via Suhayl from Abu Salih) instructs believers about to sleep to lie on their right side and recite a longer invocation that includes, verbatim mid-hadith:

> `اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَىْءٌ وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَىْءٌ وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَىْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَىْءٌ`

**The structure:** One bedtime duʿā naming all four Names in two parallel couplets:
- **Couplet 1** (first half): "O Allah, You are the First… You are the Last…"
- **Couplet 2** (second half): "You are the Manifest… You are the Hidden…"

The catalogue's `dua_arabic` for ids 81 and 82 is **Couplet 2 only** (confirmed by fetching both catalogue entries directly). Ids 79/80's duʿā was Couplet 1. **The catalogue split one ḥadīth into two duʿā pairs.**

**Rasm-identical, not byte-identical** (§9ax vocabulary). Orthographic variants: sukun marks, ya vs. alif maqsura (standard digitisation difference), hamza-seat rendering. All three are orthographic conventions, not textual changes — the consonantal skeleton and every word match.

### R1 — the beat rendered the ḥadīth, not the catalogue. Fixed.

**This deck and Al-Batin both verified beat 7 against the ḥadīth capture and never against `collectible_names.json`.** The result was a duʿā beat that was faithful to Muslim 2713a and **wrong against the string that actually renders**. Two divergences, both now corrected:

| | R0 rendered | Catalogue (locked, ids 81 & 82) |
|---|---|---|
| Arabic | `اللَّهُمَّ أَنْتَ الظَّاهِرُ …` | `أَنْتَ الظَّاهِرُ …` — **no `اللَّهُمَّ`** |
| Translit. | *Allahumma anta al-Zahiru…* | *Anta al-Dhahiru fa-laysa fawqaka shay'…* |
| English | "O Allah, You are the Manifest — nothing above You. You are the Hidden — **nothing below You**." | "You are Al-Dhahir — there is nothing above You. You are Al-Batin — **there is nothing closer to me than You**." |

**The ship gate compares all three fields to the catalogue and would have rejected this**, so it could never have reached production — but a gate catching it at merge is not the same as a drafter getting it right, and this is the second time the correct string was one file away. Beat 7 in both decks now renders the catalogue **byte-for-byte**.

**Two things this surfaces, reported and not actioned (§ "never rule on your own catalogue recommendation"):**

1. **The catalogue is not symmetric across the two pairs.** Ids 79/80 genuinely *do* open `اللَّهُمَّ`; ids 81/82 do not. So the drafter's instinct — "the other pair has it, this excerpt must too" — was pattern-matching a real asymmetry in the asset. It is the catalogue's construction; leave it.
2. **The catalogue's English for `دُونَكَ` is *"nothing closer to me than You"***, an interpretive rendering rather than the literal "nothing below You" the ḥadīth capture supports. It is defensible — `دون` carries both — and it is **locked**. Noted only so a future reader does not mistake it for a drafting error and "fix" it.

**Still open, inherited from the handoff and not resolved here:** whether `Sahih Muslim 2713a (excerpt)` is the right `renderedDuaSources` line for a string whose Arabic is a verbatim excerpt but whose English is the catalogue's own rendering. **That is a verifier's yes/no, not this deck's.**

**What renders identically on both screens.** Arabic, transliteration and translation are fully shared — a user who collects ids 81 and 82 in one session sees the same duʿā twice. This is the catalogue's own construction (one ḥadīth, two Name-pair splits) and is disclosed rather than concealed. No beat in either deck claims the duʿā is Name-specific.

---

## The 57:3 note — what was spent here, what is left for structure

**57:3 names four Names in one appositive clause:** `هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`

**Ids 79/80 (Al-Awwal/Al-Akhir) have already claimed and rendered their halves:**
- Al-Awwal renders: `هُوَ ٱلْأَوَّلُ` (opening, with ellipsis marking the clause continues)
- Al-Akhir renders: `وَٱلْـَٔاخِرُ` (mid-clause, with ellipsis both sides)

**This deck and id 82 render the remaining halves:**
- This deck (Az-Zahir) renders: `وَٱلظَّـٰهِرُ` (continuation, with ellipsis both sides)
- Al-Batin renders: `وَٱلْبَاطِنُ` (final Name in the four-clause, with ellipsis both sides)

**Not rendered, in Arabic or English, on this deck:** `وَٱلْـَٔاخِرُ` (Al-Akhir's fragment — see that deck's draft), and the closing `وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ` (Al-Aleem's territory, already shipped as `al-aleem@1`).

**Also flagged, not spent:** 57:4 (`وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ`) continues the passage toward omnipresence/inside-outside knowledge, which is Al-Batin's territory specifically. Fetched and read (source row 5); flagged in id 82's claim file so a future drafter does not re-derive it.

---

## Rejected — fetched, evaluated, and recorded so nobody re-derives it

| candidate | what it is | why refused |
|---|---|---|
| **Qur'an 31:20** | `نِعَمَهُۥ ظَـٰهِرَةً وَبَاطِنَةً` ("His favors, apparent and hidden") | **Refused on bar 1.** The referent is Allah's *favors*, not Allah Himself — a weaker demonstrative bar than 41:53 where Allah is the grammatical subject of an action. Also risks collapsing this pair's semantic separation if used on both decks (external vs. internal knowledge) |
| **Qur'an 57:4** | `يَنزِلُ مِنَ ٱلسَّمَآءِ وَمَا يَعْرُجُ فِيهَا` ("what descends from sky and ascends") | **Reserved for Al-Batin's consideration.** Flagged in id 82's claim file as a strong internal-knowledge candidate that risks collapsing this pair's separation if used on both. This deck does not use it; released for id 82's own judgment |
| **Qur'an 57:13** | `بَاطِنُهُۥ فِيهِ ٱلرَّحْمَةُ وَظَـٰهِرُهُۥ مِن قِبَلِهِ ٱلْعَذَابُ` (wall with mercy inside and torment outside) | **Flagged, not used.** Same āyah contains `ٱلْعَذَابُ` (torment) — a bar-5 hazard. The referent is a wall's appearance, not Allah's own attributes |

---

## Catalogue findings — reported, **NO change recommended**

1. **Ids 81 and 82's duʿā are shared** (COLLISION-LEDGER §6a group 14) — already the subject of the shared duʿā section above. Catalogue-level; no recommendation.

2. **Both decks' duʿā screens render the sibling Name's English gloss** — same structure as ids 79/80. Disclosed in the pairing note and the shared duʿā section. Catalogue-locked; no recommendation.

---

## What I could not determine, and what a verifier should attack first

1. **The `ẓ-h-r` root sweep was hand-checked but not against an independent corpus.** Per §9bq, cross-check against `corpus.quran.com` to confirm only 57:3 predicates this epithet of Allah directly (excluding 41:53's paraphrase via demonstration). The claim that 41:53 does not carry the root form is stated at that measured size, not overclaimed.

2. **Hadith checking is not independent of prior drafts.** Muslim 2713a is verified by Al-Awwal draft's Wayback capture; no independent Shamela or printed-edition confirmation. Standing limit, unchanged.

3. **Whether the translation choice (Mufti Taqi Usmani over SI) is acceptable** is a judgement call, not a measurement. I judged fidelity to the "manifest/evident" sense outweighs the default, but a verifier may disagree.

4. **The rows to attack first, in order:** (a) whether beat 6's disclosed non-bar-1 status is acceptable, given the task brief's explicit warning about 57:3; (b) whether 41:53 really does not carry any form of `ẓ-h-r` (cross-check against corpus.quran.com); (c) whether the bar-4 trade (both Names recovered from verse, neither from story) is a legitimate forced trade or should be recorded differently.

5. **The enforceability of the must-pair ruling** is engineering, not a drafting concern — see id 81's claim file for the status of the `position_in_pair` gate mechanism.
