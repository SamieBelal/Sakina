# Deck Draft — Al-Majid (catalogue id 72) — **R0, awaiting independent blind verification**

> ⚠️ **Same root as id 58 Al-Majeed** — `م-ج-د`, **four occurrences in the entire Qurʾān**, two of which describe the Qurʾān rather than Allah. **`al-majeed@1`'s R0 took both divine occurrences and left this Name nothing.**
>
> **That draft has been re-cut** (see its R1 section): it now renders 11:73 only, and **85:15 is surrendered to this deck.** The re-cut also removed `al-majeed@1`'s worst bar-5 exposure, so both decks improved.
>
> **The prior question a reviewer should settle first: whether ids 58 and 72 should be two decks at all.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/72.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-majid@1` — Al-Majid

**Why this deck exists, in one line:** the user who has started treating unearned kindness as a debt, and has therefore stopped being able to receive any.

**The reader's position:** **unable to accept what they did not earn.**

**Proposed metadata**

```json
{
  "deck_id": "al-majid@1",
  "name_id": 72,
  "transliteration": "Al-Majid",
  "chip_keys": [],
  "position_in_pair": null,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> You have been treating kindness you did not earn as a debt, and it has stopped feeling like kindness.

**Beat 2 · name_intro** *(catalogue id 72 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمَاجِدُ — Al-Majid — The Noble

**Beats 3–5 · story — "Honoured Before Anyone Had Done Anything"** *(Qur'an 17:70)*:
> 3. Allah says: "And We have certainly honored the children of Adam…"
> 4. "…and carried them on the land and sea and provided for them of the good things and preferred them over much of what We have created, with definite preference."
> 5. Read who is being honoured. Not the righteous among them. Not the ones who asked. The children of Adam — the whole category, before anyone in it had done a thing.

**Beat 6 · verse** *(**R3** — 85:15 **returned to `al-majeed@1`**, whose Name-form `ٱلْمَجِيدُ` it literally is. This deck's own form `ٱلْمَاجِد` occurs **nowhere in the Qurʾān**, so **bar 4 is traded in full** and the verse beat now closes the carrier instead)*:
> …and preferred them over much of what We have created, with [definite] preference. — Qur'an 17:70

**Beat 7 · duʿā** *(catalogue id 72, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا مَاجِدُ عَامِلْنِي بِسَخَائِكَ الَّذِي لَا أَسْتَحِقُّهُ وَأَكْرِمْنِي بِقُرْبِكَ
> *Ya Majid, 'amilni bisakhaikhal-ladhi la astahiqquhu wa-akrimni biqurbik*
> "O Noble, treat me with a generosity I could never earn, and honor me with Your closeness."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Kareem gives. Al-Majid is what the giving reveals about its source: nobility that is not diminished by being spent on people who could never repay it. That honouring answers no merit at all. It reports a quality, not a transaction.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you been trying to deserve that was already given to the category you belong to?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And We have certainly honored the children of Adam and carried them on the land and sea and provided for them of the good things and preferred them over much of what We have created, with definite preference."* (beats 3–5, **bar-1 carrier**) | `.../17:70` | ✅ `وَلَقَدْ كَرَّمْنَا بَنِىٓ ءَادَمَ …` — **whole āyah.** Carries `ك-ر-م`, **not** this Name's root |
| 2 | *"Honorable Owner of the Throne"* (beat 6, **bar-4 carrier**) | `.../85:15` | ✅ `ذُو ٱلْعَرْشِ ٱلْمَجِيدُ` — whole āyah. **Surrendered to this deck by the `al-majeed@1` R1 re-cut** |
| 3 | Successor sweep n−1: 17:69 | `.../17:69` | ⚠️ **drowning** — `فَيُغْرِقَكُم بِمَا كَفَرْتُمْ`. **Not rendered** |
| 4 | Successor sweep n+1: 17:71 | `.../17:71` | ✅ records given in right hands, `وَلَا يُظْلَمُونَ فَتِيلًا`. No punishment |
| 5 | Register check on the verse beat's sūrah: 85:12 | `.../85:12` | ⚠️ `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ`, three āyāt before. **Not rendered.** 85:14 and 85:16 are clean |
| 6 | Root sweep — **complete at 4 occurrences** | `corpus…?q=mjd` | ✅ 50:1 and 85:21 describe **the Qurʾān**; 11:73 is **`al-majeed@1`'s**; 85:15 is this deck's |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **17:70** `وَلَقَدْ كَرَّمْنَا بَنِىٓ ءَادَمَ` — first-person plural, Allah the subject, four consecutive narrated acts of honouring | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **enumerates the honouring** — honoured, carried on land and sea, provided from the good things, preferred — and names its recipient as a **category, not a merit class** | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS on measurement — but see the prior question about ids 58/72** |
| 4 | Root in the quoted text | ⚠️ **split, and traded at the form level.** The story carries `ك-ر-م` (`كَرَّمْنَا`), **not** this Name's root. **85:15's `ٱلْمَجِيدُ` on the verse beat carries the root `م-ج-د`** — but `ٱلْمَجِيدُ` is **id 58's Name-form**, not this Name's. **`ٱلْمَاجِد` occurs nowhere in the Qurʾān**, so no āyah can meet bar 4 for id 72 on the Name-form, and every candidate is a form-level trade | ⚠️ **PASS at root level via the verse beat; the Name-form is unattested in the Qurʾān** |
| 5 | Register and reverence | ⚠️ **n−1 (17:69) is drowning** — `فَيُغْرِقَكُم بِمَا كَفَرْتُمْ`; n+1 (17:71) is the record given in the right hand, **no punishment**. On the verse-beat side, 85:15 sits **three āyāt after `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ`** | ⚠️ **PASS — nothing rendered, but two exposures** |

**The root situation, complete at four occurrences.** `corpus?q=mjd` — *"occurs **four times** in the Quran as the adjective `majīd`"*: **50:1** and **85:21** describe **the Qurʾān**; **11:73** and **85:15** predicate Allah. **Two Names share those two āyāt.**

**Why the split fell this way.** `al-majeed@1` (id 58) built on **11:73** — the angels' announcement to Ibrāhīm's wife — because that Name's engine is *majesty arriving in a household*. **85:15, `ذُو ٱلْعَرْشِ ٱلْمَجِيدُ`, is an enthroned epithet**, which suits a Name whose catalogue gloss is *"The Noble"* and whose duʿā asks to be *treated* with unearned generosity. **It also could not carry bar 1 for either deck** — it labels — so giving it to this deck as a **verse beat** costs id 58 nothing it was using for bar 1, and removes its Sūrat al-Burūj exposure entirely.

**Bar 4 is therefore split across beats**, which the brief permits and `al-adl@1` established this session: **story carries bars 1–2, verse beat carries bar 4.**

**R1 verifier correction — what the split actually costs, stated at full strength.** Ids 58 and 72 are **not the same Name-form**: id 58 is `ٱلْمَجِيدُ`, id 72 is `ٱلْمَاجِدُ`. **`مَاجِد` does not occur in the Qurʾān in any position.** So 85:15's `ٱلْمَجِيدُ` — the word this deck's verse beat rests on — **is id 58's Name-form verbatim, rendered on id 72's deck.** Three things follow, and a verifier should weigh all three rather than the first:

1. **On screen there is no collision.** Saheeh renders `ٱلْمَجِيدُ` as *"Honorable"* and id 58's `english` is *"The Glorious"*, so the word the reader sees on this deck never says id 58's Name. **Measured, both decks re-read after the R2 beat-6 fix, max shared word-run over every beat pair: 3** — *"what have you"*, a function-word run shared by the two `reflection` beats. The only shared content word between the two decks is **`Honorable`**, one token, which both take from Saheeh's rendering of the same root.
2. **In the Arabic it is a disclosure, not a pass.** The deck renders a neighbour's Name-form. §9bo's disqualifier is rendering the neighbour's *clause*, which this is — the difference is that **id 72 has no clause of its own anywhere in the Qurʾān to render instead.** The trade is forced by the corpus, not chosen.
3. **The re-cut bought id 72 less than it looks.** Bar 4 was going to be a trade for this Name whichever āyah it got. What 85:15 adds over a bare root-level trade is one attested occurrence of the root predicated of Allah — real, but smaller than "the Name's own form predicated of Allah", which is what this file said before this correction and which was **false**.

**Bar 5, fetched, two exposures, neither rendered.** **17:69** threatens drowning for denial; the deck begins at 17:70 and never alludes to it. **17:71** is clean — records given in right hands, `وَلَا يُظْلَمُونَ فَتِيلًا`. On the verse beat, **85:12's `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ`** is three āyāt away and **85:14/85:16 immediately around it are clean** (`ٱلْغَفُورُ ٱلْوَدُودُ` — shipped ground, left entirely — and `فَعَّالٌ لِّمَا يُرِيدُ`).

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 3.** the only hit is *"what the"* (vs `al-wadud@1`'s takeaway), a function-word run. An earlier revision measured **6** against `allah@1`'s takeaway (*"a description of the one"*) and beat 8 was rewritten twice.

**Every āyah checked against the shipped asset *and* all 48 pending drafts**, two-sided boundary match: **17:70 free · 85:15 freed by the `al-majeed@1` re-cut.** 50:1 and 85:21 describe the Qurʾān and are useless for bar 1. **11:73 remains `al-majeed@1`'s.**

### Bar 3(c) — the move

**Al-Majid's move is that the generosity says something about the giver, not about the recipient.**

17:70 is chosen for **who it names**: `بَنِىٓ ءَادَمَ` — the children of Adam, the whole category, **before anyone in it has done anything.** The honouring is not a reward and is not conditional; it is prior. For a reader who has begun to experience unearned kindness as debt, the answer is that **it was never a transaction to be balanced.**

**Against `al-kareem@1` (shipped)** — the closest neighbour and the real risk: **Al-Kareem is the act** — generosity given before being asked. **Al-Majid is the standing behind the act** — nobility that is not spent down or diminished by being lavished on people who cannot reciprocate. One describes what is given; the other, what the giving reveals.

**Against `al-majeed@1` (id 58, same root):** that deck is **majesty that comes close** — glory in a household, spoken to one woman. **This deck is nobility as conduct** — how the noble treats those beneath them. **The two are genuinely close and a reviewer should decide whether the catalogue is right to list both.** That is above a drafter's authority; the decks are drafted so that the choice can be made on real text rather than on absence.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **11:73** `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` | **`al-majeed@1`'s carrier.** The other divine occurrence of the root |
| **50:1 · 85:21** | `مَّجِيد` predicated of **the Qurʾān**, not Allah |
| **85:15 as the bar-1 carrier** | an **enthroned epithet** — labels, does not demonstrate. Used as the verse beat |
| **17:69** | drowning. **Never rendered** |
| **17:70's `كَرَّمْنَا`** as a bar-4 claim | it is `ك-ر-م`, **`al-kareem@1`'s root, not this Name's.** The deck does not claim it for bar 4 |

---

## Catalogue findings — reported, **NO change recommended**

1. **Ids 58 and 72 are the same root with adjacent glosses** — *The Glorious* and *The Noble* — and between them the entire Qurʾānic inventory is **two āyāt**. **Reported as the project's one plausible merge case.** No change recommended; the decision needs both decks on the table, which it now has.
2. **Nothing else.** Id 72's `lesson` (*Al-Majid treats you with a generosity you could never earn*) is this deck's engine verbatim, and its duʿā asks for exactly that.

---

## What I could not determine — attack these first

1. **The 58/72 distinction is the deck's load-bearing question**, and both decks were drafted by the same author in the same session. **Re-argue, do not check** (§9cd) — and consider whether one deck should absorb the other.
2. **Bar 4 is carried only by the verse beat.** If a verifier rules that a labelling epithet cannot discharge bar 4 for a story that lacks the root, this Name has **no route at all** — its two available texts are one epithet and one āyah belonging to its sibling.
3. **Two bar-5 exposures** (17:69, 85:12), neither rendered.
4. **The re-cut of `al-majeed@1` was made by this drafter, to enable this deck.** That is a conflict of interest and is disclosed as one: **a verifier should check that the re-cut genuinely improves id 58 and is not a rationalisation.** The argument that it does — it removes Sūrat al-Burūj entirely from that deck — is in its R1 section.
5. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Must be reviewed with `al-majeed@1`, and the reviewer should first decide whether both decks should exist.**
