# Deck Draft — Al-Barr (id 85) — R1

> **R1, 2026-08-03 — one ruling, one re-run, no content change.**
> 1. **The "the Good" re-rendering (over Saheeh's "the Beneficent") was reviewed by the
>    coordinator and confirmed correct**, and is now the standing model for this project: **re-
>    rendering from the Arabic and naming ONE published translation that agrees is a sourcing
>    decision with a citable backstop — it is not a composite.** (Contrast the fix this ruling
>    forced on the sibling deck `al-jami@1`, which *had* assembled a string from two translators
>    and was reverted to one, pasted whole.)
> 2. **The rendered-English token-frequency sweep is re-run against the current 45-deck asset**
>    (11 decks landed while this draft was in progress: Allah, Al-Quddus, Al-Azeez, Al-Wahhab,
>    Al-Hayy, Al-Qabid, Al-Basit, Al-Khafid, Ar-Rafi, As-Sami, Ar-Rauf). **Result: every number
>    from R0 holds** except "kind"/"kindness" (substring), which grew from 5 to 7 on two
>    unrelated hits, neither blocking. `ar-rauf@1` — a tenderness deck specifically worth checking
>    — was read in full and adds no collision on any axis. See the token table below.

**Status: DRAFT, awaiting adversarial verification and founder sign-off.** Not yet in
`assets/content/name_stories.json`.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Author: Claude, 2026-08-03.
Claim filed at `.context/claims/85.md` **before** drafting, re-read immediately before this
verification table.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com/api/v4`. **Nothing
here was recalled, reconstructed or composed.** No ḥadīth is claimed on this deck — the card's
`hadith` field is empty and no beat cites one.

**Translation standard:** Saheeh International (`20`) is the base, **with one deliberate,
disclosed departure** on the verse beat — see below. **One character-level change, disclosed
once:** where Saheeh prints `Allāh`, beats render `Allah`, matching all 24 shipped decks at draft
time (45 in the current asset).

---

## ⚠️ Read first — the catalogue history named in this task

1. **The duʿā was corrupted in production and fixed 2026-08-02.** I read the *current*
   `collectible_names.json`, not any prior version. Current `dua_arabic`:
   `يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ الْقُلُوبُ`.
   Checked clause-by-clause against `dua_translation` — internally consistent, no drift, no
   interpolation. **Checked against the Qur'ān for a scripture match** (root ب-ر-ر and the phrase
   `ترتجف القلوب`) — **no match.** This is an authored catalogue invocation. **No defect found. No
   catalogue change recommended** — the fourth time this pass has run that check and found nothing
   to change, consistent with the standing rule that three of three prior recommendations in this
   project were wrong.
2. **The `hadith` field was independently wrong** (cited Muslim 1342, which is Al-Waliyy's
   mounting-for-a-journey duʿā and contains no Al-Barr material) and has been **repaired by
   removal**, not replacement — current `hadith` is **empty string**. Confirmed by direct read.
   This deck cites no ḥadīth and does not need one; the card's silence here is neutral.

## Deck `al-barr@1` — Al-Barr

**Why this deck exists, in one line:** the word for what carried you only comes to you afterward,
once you are far enough from the fear to say it.

**This Name sits in the project's densest collision zone.** *Goodness* and *kindness* already
render across four shipped decks — Al-Kareem (Most Generous), Al-Lateef (Subtle), Ar-Raḥmān,
Ar-Raḥīm. **Al-Barr's own root barely exists in the Qur'ān as a divine attribute** — a full sweep
(below) finds exactly **one** occurrence where `al-Barr` is said of Allah at all, and it sits as a
trailing predicate, in reported human speech, beside Ar-Raḥīm's own Name in the same clause. Every
choice below is built around that single, difficult āyah.

**Proposed metadata**

```json
{
  "deck_id": "al-barr@1",
  "name_id": 85,
  "transliteration": "Al-Barr",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED — content; spine incomplete (no reflection beat)"
}
```

**Beat 1 · bridge:**
> Some nights the fear is the only thing you can name. The goodness that was carrying you the
> whole time — you find the word for that later.

**Beat 2 · name_intro** *(from `collectible_names.json` id 85, verbatim)*:
> الْبَرُّ — Al-Barr — The Source of Goodness

**Beats 3–5 · story — "The word they found afterward":**
> 3. In Paradise, they will turn to one another, asking what their lives had been like.
> 4. One will say: **"We used to live in fear, among our own people, of displeasing our Lord."**
> 5. **"So Allah favoured us, and protected us from the punishment of the Scorching Fire."**

**Beat 6 · verse:**
> "We used to pray to Him: He is the Good…" — Qur'an 52:28

**Beat 7 · duʿā** *(catalog id 85, verbatim in full)*:
> يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ الْقُلُوبُ
> *Ya Barr, thabbitni 'ala birrik waj'al imani rasikhan hina tartajiful-qulub*
> "O Source of Goodness, keep me firm on the grounds of Your goodness. Make my faith steady when
> the hearts tremble."
> **NO source. This deck must not be pinned** — the duʿā is authored, not narrated (checked above).

**Beat 8 · takeaway:**
> They didn't call Him al-Barr while they were still afraid. They called Him that once they were
> safe — looking back at what had been carrying them the whole time.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **The attachment-pattern method, applied to n=1.** 52:28's naming clause is, taken alone, a trailing predicate in reported human speech — the exact shape bar 1 forbids as a carrier. **But it is not alone**: 52:25–27, in Allah's own narrating voice, immediately precede it with a shown act — fear (52:26), then favour and protection from the Fire's punishment (52:27) — and the naming in 52:28 is the *conclusion drawn from* that act, in the same breath, not an assertion floated free of it. The story beats carry the demonstration; the verse beat carries the Name. | **yes — beats 4–5 (the act), beat 6 (the naming)** |
| 2 | **shown, not stated** | No beat asserts "Al-Barr is the source of all kindness." The story shows a specific sequence — fear, then favour, then protection — and lets the naming arrive only after, in the speakers' own mouths. Beat 8 makes the *shown* structure explicit as the takeaway rather than restating the catalogue's `lesson` line, which was deliberately **not** used verbatim. | **yes — beats 3–5, and beat 8's construction** |
| 3 | **does not collapse into a sibling Name** | Full sweep below, Arabic roots and rendered English. **The one unavoidable in-text hazard (Ar-Raḥīm, same clause as the Name-noun) is cut with a visible ellipsis, not argued around.** | **yes, with one disclosed adjacency (below)** |
| 4 | **the Name's own root appears in the source text** | **Forced, not chosen.** Full-text sweep of root ب ر ر (32 occurrences, cross-checked against corpus.quran.com) finds **exactly one** place where `al-Barr` is said of Allah at all — 52:28. Bar 4 could not be traded even if I wanted to; it also renders twice more in Arabic on the duʿā beat (`بَرُّ` · `بِرِّكَ`). | **yes — beats 6 and 7** |
| 5 | **register — no punishment, and no arc terminating in it** | **Unusually clean.** The whole surrounding passage, 52:17–24, is uninterrupted Paradise imagery (gardens, reclining, food, drink, companionship) with **zero** warning material. 52:18 and 52:27 both mention "the punishment of the [Scorching] Fire" **only as what they were protected from** — safety, not threat. Successor sweep below. | **swept, clean** |

### What comes immediately before and after each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **52:25–28** (n−1…n−9, i.e. 52:17–24) | Uninterrupted: gardens and pleasure (52:17) · enjoying what their Lord gave them, protected from Hellfire's punishment (52:18) · "eat and drink in satisfaction" (52:19) · reclining, companionship (52:20) · descendants joined to them, "We will not deprive them of anything" (52:21) · fruit and meat (52:22) · a cup causing no ill speech or sin (52:23) · attendants "like pearls well-protected" (52:24). | **clean — the cleanest predecessor run found in this pipeline so far.** No warning, no rebuke, anywhere in eight āyāt. (52:21's `أَلْحَقْنَا` — "We will join with them their descendants" — is a *different* root, ل-ح-ق not ب-ر-ر, and is **not quoted**; noted only because it is thematically a reunion and could tempt a future Al-Jami drafter — it is **not** j-m-ʿ and was not used there either, per that deck's own claim.) |
| **52:28** (n+1) | 52:29: "So remind, [O Muḥammad], for you are not, by the favor of your Lord, a soothsayer or a madman." | **clean.** A pivot to defending the Prophet ﷺ against accusations, not a punishment clause. |
| **52:28** (n+2) | 52:30: "Or do they say [of you], 'A poet for whom we await a misfortune of time'?" | **clean — rhetorical, not a threat.** Sūrah aṭ-Ṭūr's punishment material (52:9–16) sits **before** this passage, not adjacent to it; not quoted, not touched. |
| **52:28** (its own tail) | `ٱلْبَرُّ ٱلرَّحِيمُ` — the Name-noun of Al-Barr immediately followed by Ar-Raḥīm's own Name-noun, in the same clause. | **cut, with a visible ellipsis.** The beat stops after "the Good…"; `الرَّحِيمُ` reaches no screen, in Arabic or English. This is the deck's one deliberate truncation and it is disclosed on the beat itself, per the plan's ellipsis rule. |

### Bar 3 in full — Arabic roots and rendered English

**Roots carried by the quoted text:** ب-ر-ر (52:28 `ٱلْبَرُّ`; duʿā ×2) · خ-و-ف / ش-ف-ق (52:26,
fear — human state, not a Name) · م-ن-ن (52:27 `فَمَنَّ`, favour) · و-ق-ي (52:27 `وَقَىٰنَا`,
protected) · د-ع-و (52:28 `نَدْعُوهُ`, called upon).
**Roots absent from every beat, checked word by word:** ر-ح-م (cut, per above) · ك-ر-م · ل-ط-ف ·
غ-ف-ر · ع-ف-و · ح-ل-م · و-ك-ل · ج-ب-ر.

**⚠️ R1 — RE-RUN against the current `assets/content/name_stories.json`, which grew from 24 to 45
decks while this draft was in progress** (Allah, Al-Quddus, Al-Azeez, Al-Wahhab, Al-Hayy, Al-Qabid,
Al-Basit, Al-Khafid, Ar-Rafi, As-Sami, Ar-Rauf landed). **Re-measured, not re-stated**, 2026-08-03,
against all 45 decks' `primary`/`label`/`translation` strings, plus this file's own beats:

| candidate string | count at R0 (24 decks) | count at R1 (45 decks) | verdict |
|---|---|---|---|
| "goodness" | 0 | **0 — unchanged** | fresh — first deck to render this token |
| "kind"/"kindness" (substring) | 5 | **7 — grew by 2.** New hits: `al-wahhab@1` "what kind of person" (type, not affection) · `ar-rauf@1` "man**kind** was created weak" (substring only, unrelated word). | Neither is a Name-gloss and neither is the affectionate sense this deck avoids using anyway (its own gloss is "Source of Goodness," and no beat renders *kind*/*kindness*) — **no shared string, verdict unchanged** |
| "merciful" | 9 | **9 — unchanged.** Confirmed `ar-rauf@1` (a tenderness deck landing after R0, specifically worth checking) adds no hit. | **the one real hazard, and it is why the ellipsis exists.** Cut before it reaches this deck's screen. |
| "He is truly the Good" (exact title construction) | not run precisely at R0 | **0**, precisely re-run | fresh |
| "favoured"/"favour" | 2 | **2 — unchanged** | no shared run ≥3 words; different grammatical role |
| "protected...from the punishment" (exact construction) | 0 | **0 — unchanged** | fresh construction |
| "firm" | 2 | **2 — unchanged.** Confirmed `ar-rauf@1` adds no hit here either — its duʿā is "be gentle with me **and protect me from trials**," a different root and word from "firm." | `al-mumin@1`'s duʿā asks to be kept firm **upon faith**; this duʿā (catalogue-locked) asks to be kept firm **on the grounds of [Allah's] goodness**. Different object, no shared run ≥3 words. |
| "tremble"/"trembling" | 0 | **0 — unchanged** | fresh |

**`ar-rauf@1` read in full, specifically because the coordinator flagged it as a tenderness deck
landing after this draft's initial read.** It is the Isrāʾ/Miʿrāj fifty-prayers-reduced-to-five
narrative (Bukhārī, not fetched by this deck) — different narrative, different root, different
engine ("lightened, not strengthened" vs. this deck's "named only after"). No shared string beyond
the two substring false-positives already itemised above.

**⚠️ Gloss-template overlap, disclosed per the ledger's own §7 flag on this row.** "The Source of
Goodness" (85) shares the template "The Source of ___" with shipped "The Source of Serenity"
(id 6, As-Salam). Applying the §9o test — could a user read both screens and think they were told
the same thing twice? — **no**: different noun, different `name_intro` string entirely, and the
two decks share no citation, engine or story. Recorded because the ledger names it, not because it
blocks.

**⚠️ Insight-level (beat 8) check, per §9an's three-surface method — roots, tokens, the move:**

| checked against | its engine | verdict |
|---|---|---|
| `al-lateef@1` [S] — "visible only from the far side" | a kindness's *subtlety* discovered in hindsight | ⚠️ **adjacent, disclosed.** Both are retrospect-payoff shapes. **Distinction:** `al-lateef@1`'s subject is the *quality* of an ongoing kindness (Yūsuf realizes years later it was subtle threading, not power); this deck's subject is the *word*, not the kindness — 52:28's own text has the speakers say "we used to call on Him **before**," i.e. they were never unaware and the goodness was never hidden. What arrived late was the **naming**, not the awareness. No shared string; the moves differ on what "arrives late." |
| `ar-raheem@1` [D] — "answered while unaware" | mercy operating during literal unconsciousness (three centuries asleep) | ✖ **no collision.** That deck's people are *asleep*; this deck's people are *actively calling on Him* the whole time. Opposite premise. |
| `at-tawwab@1` [S] — "met mid-road" | acceptance meeting a person while still turning back | ✖ none — no turning-back narrative here |
| all remaining ledger §3 engines | (per ledger) | ✖ none |

**Against ledger §3a's spent-engine list** — `named only after` is not on it and is not a
rephrasing of any entry on it.

### Ship-gate note — this deck must carry NO duʿā `source`

Catalogue id 85's duʿā is checked above and is an **authored catalogue invocation**, not a
narration. Per ledger §2b, `renderedDuaSources` is asserted bidirectionally, so: the duʿā beat's
`source` field **must be empty**, and **`al-barr@1` must NOT be added to `renderedDuaSources`.**

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1 | Beat 3: setting — Paradise, mutual questioning | paraphrase of 52:25 | [Qur'an 52:25](https://quran.com/52/25) | Qur'an | ✅ verified by live fetch `api.quran.com/api/v4/verses/by_key/52:25`, 2026-08-03 |
| 2 | Beat 4, quotation: "We used to live in fear, among our own people, of displeasing our Lord." | Saheeh International, lightly re-cast for the deck's register ("previously among our people fearful [of displeasing Allāh]" → "in fear, among our own people, of displeasing our Lord"); no interpolation, meaning preserved | [Qur'an 52:26](https://quran.com/52/26) | Qur'an | ✅ verified — same fetch batch. Arabic: `قَالُوٓا۟ إِنَّا كُنَّا قَبْلُ فِىٓ أَهْلِنَا مُشْفِقِينَ` |
| 3 | Beat 5, quotation: "So Allah favoured us, and protected us from the punishment of the Scorching Fire." | Saheeh International, `Allāh`→`Allah` only | [Qur'an 52:27](https://quran.com/52/27) | Qur'an | ✅ verified — same fetch batch. Arabic: `فَمَنَّ ٱللَّهُ عَلَيْنَا وَوَقَىٰنَا عَذَابَ ٱلسَّمُومِ` |
| 4 | Beat 6, verse anchor: "We used to call on Him before this. He is truly the Good…" | **re-rendered from the Arabic, corroborated against Abdel Haleem's "He is the Good"** (resource 85) rather than Saheeh's "the Beneficent." ⚠️ **R1 verifier correction — the disclosure was narrower than the beat.** It covered *"the Good"* and left the impression that the rest of the line was a published translation. It is not. Fetched and compared, all five: Saheeh — *"Indeed, we used to supplicate Him before. Indeed, it is He who is the Beneficent, the Merciful."* · Abdel Haleem — *"We used to pray to Him: He is the Good, the Merciful One."* · Pickthall — *"Lo! we used to pray unto Him of old."* · Yusuf Ali — *"Truly, we did call unto Him from of old."* · Hilali-Khan — *"Verily, We used to invoke Him (Alone and none else) before."* **No translation reads "We used to call on Him before this."** The whole beat is a re-rendering from the Arabic, not only its last two words — which §9bh permits **only** with a named published translation that agrees, and *"the Good"* has one while the opening clause does not. **A verifier must rule on the opening clause specifically**, not on the Name-word, which is the part that was argued. **Disclosed reason for the Name-word, per the task's own flag:** Saheeh's "the Beneficent" is disconnected from catalogue id 85's own `english` ("The Source of Goodness") and would make the Name invisible on screen — the same class of finding as `al-kareem@1`'s and `an-nur@1`'s translation-adjudication rulings, but running the **other** direction here: this is a fidelity/visibility choice (which accurate English keeps the Name legible), not a theological adjudication — both "Beneficent" and "Good" are accurate for `al-Barr`; nothing contested is resolved by choosing one. | [Qur'an 52:28](https://quran.com/52/28) | Qur'an | ✅ verified — live fetch, 2026-08-03. Arabic in full: `إِنَّا كُنَّا مِن قَبْلُ نَدْعُوهُ ۖ إِنَّهُۥ هُوَ ٱلْبَرُّ ٱلرَّحِيمُ`. **The beat renders only up to "the Good" — a visible ellipsis marks the cut before `ٱلرَّحِيمُ`.** |
| 5 | Beat 7 duʿā | catalog id 85 — **no scripture citation claimed** | catalog only | n/a | ✅ verified byte-identical to catalog across `dua_arabic`/`dua_transliteration`/`dua_translation`, checked programmatically. Authored catalogue invocation, checked against the Qur'ān and found no match (see the header note); **unpinned by design.** |
| 6 | Beat 2 `name_intro` | catalog id 85 | catalog only | n/a | ✅ verified byte-identical to catalog across `arabic`/`transliteration`/`english` (`الْبَرُّ`/`Al-Barr`/`The Source of Goodness`). No authored gloss appended. |
| 7 | Card `hadith` field | — | catalog only | n/a | ✅ confirmed **empty** by direct read; the prior Muslim 1342 mis-citation is gone, not replaced. **No change recommended.** |
| 8 | Full-text root sweep, ب ر ر | — | [corpus.quran.com](https://corpus.quran.com/qurandictionary.jsp?q=brr) | Qur'an (cross-check) | ✅ **32 occurrences, cross-checked against corpus.quran.com**, itemised by form in the claim file and in "Bar 4" above; own count summed and matches the corpus total. |
| 9 | Predecessor sweep, 52:17–24 | Saheeh International, read not quoted | [52:17](https://quran.com/52/17)–[52:24](https://quran.com/52/24) | Qur'an | ✅ all fetched live 2026-08-03 |
| 10 | Successor sweep, 52:29–30 | Saheeh International, read not quoted | [52:29](https://quran.com/52/29)–[52:30](https://quran.com/52/30) | Qur'an | ✅ fetched live 2026-08-03 |

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting adversarial verification and founder sign-off**

### Collision check against all 34 ledger/shipped decks

| ledger deck(s) | their inventory | collides? |
|---|---|---|
| `ar-raheem@1` [D] | 18:10–25, `الرَّحِيمُ` gloss | ⚠️ **the deck's one unavoidable in-text hazard, cut with a visible ellipsis before this deck's screen renders it.** No shared citation, no shared string. |
| `al-lateef@1` [S] | 12:100, "visible only from the far side" | ⚠️ **retrospect-payoff adjacency, disclosed in the bar-3 insight table above.** No shared citation or string. |
| `al-kareem@1` [D] · `ar-rahman@1` [S] | Bukhārī 1145 · Bukhārī 5999 | ✖ different narratives, different citations, different engines (supply-without-cost / wide mercy vs. this deck's named-only-after-safety) |
| `al-mumin@1` [D] | duʿā "make us firm upon faith" | ⚠️ **disclosed in the token table** — different object of "firm," no shared run |
| `as-salam@1` [S] | "The Source of Serenity" | ⚠️ **gloss-template overlap, disclosed** per ledger §7's own flag; not a §9o collision |
| all remaining ledger decks | (per ledger §1–§5) | ✖ none. 52:25–28 is unspent by any deck; no ḥadīth is cited. |
| **sibling claims live at write time** (`.context/claims/`: 1, 4, 5, 7, 8, 10, 12, 14, 15, 17, 24, 25, 40, 41, 42, 43, 44, 45, 57, 61, 69, 70, 73, 74, 77, 78, 80, 87, 93, 95, 96, 98) | — | ✖ **none touch id 85 or 52:25–28** — grepped for "barr," "85," "52:28" across all files, re-checked immediately before this table |

### Authoring notes (candidates considered, all fetched)

**Why not 2:177 (the birr āyah)?** It is the most famous `birr` verse in the Qur'ān — but it
**defines human righteousness** ("Righteousness is not that you turn your faces toward the east or
west, but..."), with people as the subject of `birr`, not Allah. Bar 1 requires the Name's own act,
demonstrated by Allah; a human-conduct verse, however thematically close in root, is the wrong
subject. **Rejected on bar 1, not on availability.**

**Why not human "birr toward parents" ḥadīth material?** Same reason — that virtue belongs to a
Name about human conduct, if one exists in this catalogue, not to Allah's own attribute of being
the source of goodness. Not fetched individually; excluded on the same ground as 2:177.

**Method limit, stated because the founder signs against this table:** the Qur'ān text itself is
single-source (`api.quran.com`) for the quotations. The root enumeration has an independent
cross-check (corpus.quran.com). No ḥadīth is cited on this deck, so the ḥadīth-corpus limitation
recorded on other decks does not apply here. No isnād question arises for the same reason.
