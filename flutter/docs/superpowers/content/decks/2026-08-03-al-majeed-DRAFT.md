# Deck Draft — Al-Majeed (catalogue id 58) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-azeem-DRAFT.md`](2026-08-03-al-azeem-DRAFT.md).** Ids 58 and 50 **share one locked `dua_arabic`** (§9ce) — a shared-duʿā group the handoff did not record until 2026-08-03. **The shared duʿā names only id 50** — `سُبْحَانَ رَبِّيَ الْعَظِيمِ`. **This deck's duʿā beat therefore never mentions Al-Majeed.** Catalogue-locked; see *The shared duʿā*.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/50-58.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-majeed@1` — Al-Majeed

**Why this deck exists, in one line:** the user who receives good news and immediately checks it for a catch, because somewhere they concluded they are not the kind of person good things happen to.

**What separates it from its pair-partner:** Al-Azeem is **magnitude that reframes**; Al-Majeed is **magnitude that comes close without shrinking to do it**.

**Proposed metadata**

```json
{
  "deck_id": "al-majeed@1",
  "name_id": 58,
  "transliteration": "Al-Majeed",
  "chip_keys": [],
  "position_in_pair": 2,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> Good news arrived and your first move was to check it for a catch. Some part of you has decided you are not the kind of person good things happen to.

**Beat 2 · name_intro** *(catalogue id 58 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمَجِيدُ — Al-Majeed — The Glorious

**Beats 3–5 · story — "I Created You Before, While You Were Nothing"** *(Qur'an 19:9)* — **R3: recut. The R0 carrier rested on angelic speech, which the ladder ruling excludes.**
> 3. An old man asks how he could possibly have a son. His bones have weakened; his wife has never been able to bear.
> 4. The answer comes back with Allah's own words inside it: "Thus [it will be]; your Lord says, 'It is easy for Me…'"
> 5. "…for I created you before, while you were nothing." The proof He offers is not a miracle somewhere else. It is the man He is speaking to.

**Beat 6 · verse** *(**R3** — whole āyah. **85:15 returns to this deck**: `ٱلْمَجِيدُ` is *this Name's own form*, and id 72's form `ٱلْمَاجِد` occurs nowhere in the Qurʾān, so it was the wrong deck to hold it)*:
> Honorable Owner of the Throne — Qur'an 85:15

**Beat 7 · duʿā** *(catalogue id 58, **byte-for-byte**, asserted programmatically (§9cb); **identical to id 50's** — catalogue-locked)*:
> سُبْحَانَ رَبِّيَ الْعَظِيمِ
> *Subhana Rabbiyal 'Azeem*
> "Glory be to my Lord, the Most Magnificent."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Azeem is scale. Al-Majeed is scale that comes close without shrinking to do it. Al-Qadir answers whether He can; this answers whether He would, for someone like you. The proof He gave was not a miracle elsewhere. It was the man He was speaking to.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you stopped asking for, because somewhere along the way you decided it was beyond you?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | The scene: Ibrāhīm's wife is told she will bear a child, and laughs (beats 3–5, **bar-1 and bar-4 carrier**) | `.../11:73` | ✅ `قَالُوٓا۟ أَتَعْجَبِينَ مِنْ أَمْرِ ٱللَّهِ ۖ رَحْمَتُ ٱللَّهِ وَبَرَكَـٰتُهُۥ عَلَيْكُمْ أَهْلَ ٱلْبَيْتِ ۚ إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` — **whole āyah.** Bar 1 contested: the words are the angels', the narration is Allah's |
| 2 | *"…Indeed, He is Praiseworthy and Honorable."* (beat 6, **R1 re-cut**) | `.../11:73` | ✅ `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` — **the closing clause of the carrier āyah**, visible leading ellipsis. Saheeh International verbatim |
| 3 | ~~Successor sweep n−1 of the verse beat: 85:14~~ | ~~`.../85:14`~~ | **MOOT after R2** — Sūrat al-Burūj is no longer touched by this deck at all. Row kept struck so the surrender is auditable |
| 4 | ~~Successor sweep n+1 of the verse beat: 85:16~~ | ~~`.../85:16`~~ | **MOOT after R2** — see row 3 |
| 5 | ~~Register check on the verse beat's sūrah: 85:12~~ | ~~`.../85:12`~~ | **MOOT after R2.** `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ` was this deck's worst bar-5 exposure; surrendering 85:15 removed it. **It did not disappear — it moved to `al-majid@1`, which now discloses the identical finding** |
| 6 | Root sweep — **complete at 4 occurrences** | `corpus…?q=mjd` | ✅ *"occurs four times in the Quran as the adjective majīd"*: 11:73, 50:1, 85:15, 85:21. **Two are about the Qurʾān** |
| 7 | The locked duʿā (shared with id 50) | `collectible_names.json` id 58 | ✅ all three fields asserted present (§9cb). **It names Al-Azeem, not this Name** |

---

### R3 — the refusal is lifted, on a carrier that clears the ladder

**The ladder ruling stands and is not being argued around.** 11:73's `قَالُوٓا۟ … إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` is **the angels speaking about Allah in the third person**, and that does not carry bar 1. R0 built the deck on it; the blind verifier refused it; the refusal was correct.

**19:9 is a different rung, and the difference is the whole point.**

> `قَالَ كَذَٰلِكَ قَالَ رَبُّكَ هُوَ عَلَىَّ هَيِّنٌ وَقَدْ خَلَقْتُكَ مِن قَبْلُ وَلَمْ تَكُ شَيْـًٔا`

The speech that reaches the reader is marked `قَالَ رَبُّكَ` — *your Lord says* — and what follows is **Allah's own first person**: `عَلَىَّ` (*for Me*), `خَلَقْتُكَ` (*I created you*). That is **rung 2 of §9bk — "Allah quoting Himself inside a narrative" — which carries.** At 11:73 the angels describe Allah; at 19:9 Allah's own words are quoted verbatim. **The rung the deck was refused on is not the rung it now stands on.**

| bar | where it is met now |
|---|---|
| **1** | ✅ Allah's own first-person speech, explicitly attributed (`قَالَ رَبُّكَ`) |
| **2** | ✅ **shown, not stated** — the proof offered is not an argument but **the addressee's own existence**: *I created you before, while you were nothing* |
| **4** | ✅ **85:15's `ٱلْمَجِيدُ` — this Name's own form, predicated of Allah, in Allah's own voice.** Returned to this deck at R3 |
| **5** | ✅ **clean both sides, fetched.** n−1 **19:8** is Zakariyyā's question; n+1 **19:10** is the sign of three nights' silence. Neither is punishment, neither is rendered |

**The correction to the R1 re-cut, and it was mine to make.** R1 gave 85:15 to `al-majid@1`. That was wrong on the facts: **id 58 is `ٱلْمَجِيدُ` and id 72 is `ٱلْمَاجِدُ`**, and `مَاجِد` **occurs nowhere in the Qurʾān**. Handing this Name's own attested form to a Name whose form is unattested made id 72 look better on paper and left id 58 with nothing. **Accuracy puts it back here**, and id 72 trades bar 4 in full — which is the honest description of its position either way.

**Availability, checked:** 19:8 · 19:9 · 19:10 all **free**; 85:14 and 85:16 free and unrendered.

**Bar 5 disclosure that survives the recut:** 85:15 sits **three āyāt after** `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ` (85:12), and Sūrat al-Burūj opens on the burning of believers. **Nothing of that is rendered** — the beat is the single āyah — and 85:14 (`ٱلْغَفُورُ ٱلْوَدُودُ`) and 85:16 (`فَعَّالٌ لِّمَا يُرِيدُ`) immediately around it are clean. **Stated, not smoothed.**

**Engine, and the separation from `al-qadir@1` (shipped), which is the new risk this carrier introduces:** Al-Qadir answers *can He?* — capability, argued from a miracle. **Al-Majeed answers *would He, for someone like me?*** — and the answer points at the reader: the precedent for the impossible thing is **you, who were nothing.** That is nobility spent on a particular person, not power demonstrated in the abstract.

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | ⚠️ **the weakest bar-1 in this wave, and the deck is built around the weakness.** 11:73's `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` is spoken by **the angels**, inside Allah's own narration (`قَالُوٓا۟`) | ⚠️ **CONTESTED — see below. Attack this first** |
| 2 | Shown, not stated | the scene **is** the demonstration — an old woman's disbelief at her own body, answered on the spot. Narrative, not declaration | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `م-ج-د` as `مَّجِيدٌ` (11:73), on **both** the story and the verse beat — the deck's only rendered āyah after the R1 re-cut | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **clean after R2.** The deck no longer renders anything from Sūrat al-Burūj; 11:73's own neighbourhood is clean in both directions (11:72 is the same scene, 11:74 is Ibrāhīm pleading **for** Lūṭ's people) | ✅ **PASS** |

**Bar 1 is contested and this deck does not pretend otherwise.** The root `م-ج-د` occurs **four times in the entire Qurʾān** — and that is the whole problem:

| occurrence | subject | verdict |
|---|---|---|
| **50:1** `وَٱلْقُرْءَانِ ٱلْمَجِيدِ` | **the Qurʾān** | not Allah |
| **85:21** `بَلْ هُوَ قُرْءَانٌ مَّجِيدٌ` | **the Qurʾān** | not Allah |
| **85:15** `ذُو ٱلْعَرْشِ ٱلْمَجِيدُ` | Allah | a bare epithet — labels, does not demonstrate |
| **11:73** `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` | Allah | **spoken by the angels**, narrated by Allah |

**So `مجيد` is predicated of Allah exactly twice, and neither is Allah speaking in His own voice about Himself.** §9bk's ladder rules on Allah's narration, Allah quoting Himself, `قُلْ`-instruction, a prophet's reported speech, and other human speech — **it does not rule on angelic speech inside divine narration**, which is where this deck sits.

**The argument for the rung, stated so it can be attacked:** the sentence reaching the reader is `قَالُوٓا۟ … إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` — **Allah narrating**, and what He narrates is an angelic declaration He is choosing to report about Himself. That is nearer to *"Allah quoting inside a narrative"* than to *"human speech about Allah"*. **The counter-argument is that the ladder's whole point is who the speaker is, and the speaker is not Allah.**

**If bar 1 is judged unmet, this Name has nowhere else to go** — the sweep above is complete at four occurrences. It would become a genuine refusal, and it would be a refusal **on bar 1 for lack of any divine-voice text**, not for lack of searching.

**Bar 5 — R2: the exposure is gone, and it is worth recording how.** R0 put 85:15 on the verse beat, which put this deck three āyāt from `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ` (*the assault of your Lord is severe*) and inside a sūrah that opens on the burning of believers in the trench. **After the R1 re-cut this deck renders nothing from Sūrat al-Burūj**, and its whole rendered surface is one āyah — 11:73 — whose n−1 is the same scene (the woman's own words) and whose n+1 is **Ibrāhīm pleading on behalf of Lūṭ's people**. Clean in both directions, no truncation needed.

**The honest accounting, since this deck is the beneficiary:** the 85:12 exposure did not disappear. It **moved to `al-majid@1`**, which now renders 85:15 and discloses the identical finding. A verifier weighing the re-cut should read that as one deck's bar-5 problem being handed to another, not as a bar-5 problem being solved.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** Every hit is a scripture or function-word run — *"mercy of allah"* (vs `al-jabbar@1`'s verse beat; a fixed Qurʾānic phrase, §9bl), *"woman who had"* (vs `ar-rahman@1`). **No finding.**

**Twin-diff vs `al-azeem@1`** (the pair-partner, which is the diff that matters here): ****3** — *"azeem is"*, this deck's takeaway naming its partner. Entirely disjoint scripture: 11:73 and 85:15 against 56:68–74.**

**Every āyah checked against the shipped asset *and* all 30 pending drafts**, two-sided boundary match: **11:73 free** — no shipped deck, no pending draft. **85:15 is no longer this deck's ground at all** (surrendered to `al-majid@1` at R1; see the bar-5 note). 50:1 and 85:21 evaluated and rejected (subject is the Qurʾān).

**R2 note — the re-cut was applied to the citation and not to the text, and that shipped as a misquotation for a day.** R1 changed beat 6's source from `85:15` to `11:73` but left the rendered line reading *"Honorable Owner of the Throne"* — which is 85:15's words, now printed under 11:73's citation. **11:73 says no such thing.** The Sources table went on asserting 85:15, and bars 4 and 5 went on describing a Sūrat al-Burūj exposure the deck no longer had, so the beat disagreed with three of its own tables at once. Beat 6 now renders **11:73's actual closing clause**, and rows 3–5 above are struck rather than deleted. **The general rule this earned is in the ledger as §9ch.**

### Bar 3(c) — the move

**Al-Majeed's move is that the majesty is the reason the unlikely thing is possible — not the reason it is unlikely.**

The reader's error is a hierarchy: great things belong to great people, and they have privately excluded themselves. **11:73 answers that in the setting where it is hardest to believe** — not a throne room, a household; not a prophet, an old woman laughing at her own body. The angels' reply is not a rebuke of her doubt, it is a re-description of who is doing this: *Are you amazed at the decree of Allah?* And then the word: **`مَّجِيدٌ`** — glory — attached directly to a mercy landing on one specific family.

**That is why the scene, and not 85:15's throne, is the story.** `ذُو ٱلْعَرْشِ ٱلْمَجِيدُ` says the glory is enthroned. 11:73 says the enthroned glory is the thing currently in your kitchen.

**Against the pair-partner:** Al-Azeem resets the scale you measure on and stays distant while doing it. **Al-Majeed closes the distance without becoming smaller** — the whole force of the word is that it did not have to shrink to arrive.

**Against `al-kareem@1` (shipped)**, the nearest non-pair neighbour and a genuine risk: Al-Kareem is **generosity that gives without being asked**. **Al-Majeed is generosity that does not lose its stature by giving.** One is about the gift, the other about the giver's undiminished rank. Measured at 4 (`"much to ask"`, since removed).

---

## The shared duʿā

Ids 58 and 50 render **one identical duʿā beat**: `سُبْحَانَ رَبِّيَ الْعَظِيمِ`. A user who collects both sees the same duʿā twice. **Catalogue-locked, disclosed rather than concealed, and no beat on either deck claims it is Name-specific.** Each deck's engine is carried on its **takeaway**, which is fixed and not AI-replaced.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **50:1** `وَٱلْقُرْءَانِ ٱلْمَجِيدِ` | the subject is **the Qurʾān**, not Allah. Bar 1 fails on the predicate, not the ladder |
| **85:21** `بَلْ هُوَ قُرْءَانٌ مَّجِيدٌ` | same |
| **85:15 as the bar-1 carrier** | a **bare epithet** — labels, does not demonstrate. Used as the verse beat, where it needn't carry bar 1 |
| **85:12 · 85:4–10** | `بَطْشَ رَبِّكَ لَشَدِيدٌ` and the trench. **Never rendered**, disclosed as the verse beat's neighbourhood |
| **85:14 `ٱلْغَفُورُ ٱلْوَدُودُ`** | shipped `al-ghafur@1` and `al-wadud@1` ground. Immediately before the verse beat; **left entirely** |
| **11:73's `حَمِيدٌ`** | **id 65 Al-Hameed's word**, and it is rendered here because it is inseparable from `مَّجِيدٌ` in the same clause. **Disclosed, not avoidable** — `حميد` has 17 occurrences and id 65 has ample ground elsewhere. Recorded so id 65's drafter knows this one is spent |

---

## Catalogue findings — reported, **NO change recommended**

1. **This deck's duʿā never mentions this deck's Name.** `سُبْحَانَ رَبِّيَ الْعَظِيمِ` names **Al-Azeem** (id 50). Catalogue-locked, disclosed, **not actioned** (§9ce).
2. **Id 58's `lesson` — *"Al-Majeed combines greatness with generosity — He is both awe-inspiring and giving"* — is precisely the 11:73 reading**, and is the reason this deck was built on the scene rather than on 85:15's throne. **It is also the only evidence outside the text that the intended engine is closeness rather than elevation**, which matters given how thin the scriptural base is.

---

## What I could not determine — attack these first

1. **Bar 1 is contested and is the whole deck.** Angelic speech inside divine narration is **not a rung §9bk rules on**. If a verifier places it with human reported speech, **this Name has no other text** — the root sweep is complete at four occurrences — and it becomes a refusal.
2. **The verse beat's sūrah is the harshest register any beat in this wave sits in.** 85:15 is three āyāt from *the assault of your Lord is severe* and in the sūrah of the trench. Nothing of it is rendered; the exposure is real.
3. **`حَمِيدٌ` is spent here for id 65 Al-Hameed** — unavoidably, since it is in the same clause. Flagged for that drafter.
4. **This is the shortest root sweep in the project (4 occurrences), which makes it complete** — the one bar this deck can claim without qualification.
5. **No ḥadīth fetched** (§9bc). **A ḥadīth carrier might rescue bar 1 if the angelic-speech ruling goes against this deck**, and none was sought — stated as an unexplored route, not a closed one (§9bo).

---

## Pairing verdict

**Ships independently *if bar 1 survives review*.** It has no dependency on `al-azeem@1` beyond the shared duʿā, and renders entirely disjoint scripture. **But it is the most likely deck in this wave to be sent back**, and the reason is a ladder question the project has not yet ruled on.

---

## R1 re-cut — 85:15 surrendered to `al-majid@1`

**Both decks improved, and the second one becomes possible at all.** Ids **58 Al-Majeed** and **72 Al-Majid** are the *same root*, `م-ج-د`, which has **four occurrences in the entire Qurʾān** — two describing the Qurʾān (50:1, 85:21) and two predicating Allah (11:73, 85:15). R0 of this deck took **both** divine occurrences: 11:73 as its story, 85:15 as its verse beat. **That left id 72 with nothing at all.**

**The re-cut:** this deck now renders **11:73 only**, using its closing clause `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` as the verse beat — the `al-adl@1` / `ash-shaheed@1` pattern of splitting one āyah across story and verse. **85:15 goes to `al-majid@1`.**

**Two things this fixes beyond fairness:**

1. **It removes this deck's bar-5 exposure.** 85:15 sits in Sūrat al-Burūj, **three āyāt after `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ`** and in the sūrah of the burning of the believers. R0 disclosed that as the deck's worst register problem. **With the re-cut, this deck no longer touches Sūrat al-Burūj at all**, and its whole text is 11:73 — a household, an old woman, and a blessing.
2. **It tightens the deck.** One āyah, story and verse beat, no imported second text and no second bar-5 neighbourhood.

**What does not change: bar 1 is still contested** — 11:73's `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` is spoken by the angels inside Allah's narration, a rung §9bk does not rule on. **That remains this deck's load-bearing question**, and the re-cut concentrates the deck on it rather than diluting it.

**Recorded because the ordering was luck, not process.** Id 58 was drafted hours before id 72 in the same session, and simply took both. **A drafter working a two-occurrence root must check whether a sibling Name shares it before spending both** — the same rule §4f records for ids 56/89 and 67/68, and the §9ce map does not catch any of the three, because they share a *root*, not a `dua_arabic`.
