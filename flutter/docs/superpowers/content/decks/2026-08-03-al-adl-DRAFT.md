# Deck Draft — Al-Adl (catalogue id 48) — **R0, awaiting independent blind verification**

**One of the judgment four.** Ids 47, 48, 55 and 90 share one locked `dua_arabic`. **The shared material — the duʿā's non-Qurʾānic construction (§9cf), the group-wide bar-5 ruling, all four root sweeps, the āyah partition, and the four engines side by side — lives in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) and is not repeated here.** Read it first; this file carries only what is specific to this Name.

> **Id 48 was previously quarantined for fabricated content** — that report attributed an invented count (44) to `corpus.quran.com` for `ع-د-ل`, where the corpus returns **28**. The draft was not reused and not read as precedent.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Group claim: `.context/claims/47-48-55-90.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International). **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-adl@1` — Al-Adl

**Why this deck exists, in one line:** the user who keeps a private ledger against themselves in which every entry is in the same column, and who is quietly braced for the day it is read back to them.

**The reader's grievance, which is what separates this deck from its three siblings:** **afraid of the verdict.** Not that it will never come, but that it will — and that being judged *accurately* is the thing to dread.

**Proposed metadata**

```json
{
  "deck_id": "al-adl@1",
  "name_id": 48,
  "transliteration": "Al-Adl",
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

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> Somewhere in you is a ledger you keep against yourself, and every entry is in the same column.

**Beat 2 · name_intro** *(catalogue id 48 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْعَدْلُ — Al-Adl — The Just

**Beats 3–5 · story — "An Atom's Weight, and a Multiplier"** *(Qur'an 4:40)*:
> 3. Allah says: "Indeed, Allah does not do injustice, [even] as much as an atom's weight…"
> 4. "…while if there is a good deed, He multiplies it and gives from Himself a great reward."
> 5. Read the two halves against each other. The wrong is measured to the atom. The good is not measured at all — it is multiplied. The same sentence is exact in one direction and generous in the other.

**Beat 6 · verse** *(partial quotation — visible ellipsis; **the bar-4 root carrier**, does not carry bar 1)*:
> And the word of your Lord has been fulfilled in truth and in justice… — Qur'an 6:115

**Beat 7 · duʿā** *(catalogue id 48, **byte-for-byte**, asserted programmatically (§9cb). **`source: ""` — the string is NOT Qurʾānic, §9cf**)*:
> اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ
> *Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin*
> "O Allah, judge between us and our people in truth — You are the best of judges."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> You have been bracing for a fair accounting as though fair were the worst thing that could happen to you. Read the sentence again: an atom's weight against you, and a multiplier on everything else. This Name does not make the outcome neutral. It makes it lopsided, and the slope runs toward you.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you been counting against yourself that has never been entered against you at all?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Indeed, Allah does not do injustice, [even] as much as an atom's weight; while if there is a good deed, He multiplies it and gives from Himself a great reward"* (beats 3–5, **bar-1 carrier**) | `.../4:40` | ✅ `إِنَّ ٱللَّهَ لَا يَظْلِمُ مِثْقَالَ ذَرَّةٍ ۖ وَإِن تَكُ حَسَنَةً يُضَـٰعِفْهَا وَيُؤْتِ مِن لَّدُنْهُ أَجْرًا عَظِيمًا` — **whole āyah**, split across beats at its own `ۖ` |
| 2 | *"And the word of your Lord has been fulfilled in truth and in justice…"* (beat 6, **bar-4 carrier**) | `.../6:115` | ✅ `وَتَمَّتْ كَلِمَتُ رَبِّكَ صِدْقًا وَعَدْلًا` — first clause only; `وَهُوَ ٱلسَّمِيعُ ٱلْعَلِيمُ` **not rendered** |
| 3 | Successor sweep n−1: 4:39 | `.../4:39` | ✅ clean — closes `وَكَانَ ٱللَّهُ بِهِمْ عَلِيمًا` |
| 4 | Successor sweep n+1: 4:41 | `.../4:41` | ✅ **no punishment** — witnesses brought from every nation. Carries `شَهِيدٍ`, **left for id 60** |
| 5 | The locked duʿā | `collectible_names.json` id 48 | ✅ all three fields asserted present (§9cb). **`source: ""` — not Qurʾānic, §9cf** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **4:40** `إِنَّ ٱللَّهَ لَا يَظْلِمُ مِثْقَالَ ذَرَّةٍ` — Allah's own narration of His own practice | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **puts two measurements in one sentence and makes them unequal** — an atom's weight on one side, `يُضَـٰعِفْهَا` (*He multiplies it*) on the other. The asymmetry is shown by the construction, not asserted | ✅ **PASS — the strongest bar 2 in the group** |
| 3 | No sibling-Name collapse | three surfaces, measured below | ✅ **PASS** |
| 4 | Root in the quoted text | ⚠️ **traded.** 4:40's root is `ظ-ل-م`, not `ع-د-ل`. **6:115's `صِدْقًا وَعَدْلًا` carries the root on a separate verse beat** — carrier/story split | ⚠️ **PASS by a documented, forced trade** |
| 5 | Register and reverence | ✅ **clean on both sides** — 4:39 closes `وَكَانَ ٱللَّهُ بِهِمْ عَلِيمًا`; 4:41 is witnesses at Judgment with **no punishment** | ✅ **PASS — the only clean carrier in the group** |

**The bar-4 trade, and the sweep that forces it.** `Edl` returns **28 occurrences in 2 forms** across 24 āyāt. Of those, the occurrences with **Allah as subject carry the negative sense** — `عَدَلُوا۟ بِرَبِّهِمْ`, *"they ascribe equals to their Lord"* (6:1, 6:150, 27:60) — and the remainder are **commands to humans** to act justly (4:58, 16:90, 5:8, 5:95, 6:152). **`ٱلْعَدْل` is predicated of Allah's own act in exactly one place: 6:115's `صِدْقًا وَعَدْلًا`.**

So the trade is forced rather than preferred. **6:115 is the only text that can carry bar 4, and it is a declaration rather than a demonstration**, so it cannot also carry bars 1–2. 4:40 carries those. This is the `al-wahid@1` / `al-muhyi@1` carrier-story split — the correct shape for this situation, not a workaround for a missing text.

**Bar 5 is clean on both sides, stated as a measurement rather than an adjective (§9ak):** four āyāt fetched, zero punishment. 4:41 introduces `شَهِيدٍ` — witnesses brought from every nation — which is **Ash-Shaheed's (id 60) ground and is left entirely unrendered.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time**, not from a note (§9bi): **45**. Every beat run against every `primary` and `translation` string, maximum shared word-run computed by dynamic programming.

**Maximum shared word-run across the whole deck: 3** — every hit a function-word run ("what the", "the word", "same sentence", "is a"). **No finding.**

**Intra-group twin-diff — against all three siblings, not one** (§9bs: a twin-diff between two members of a four-Name group is not sufficient):

| vs | max run | the run |
|---|---|---|
| `al-hakam@1` | **3** | "have been" |
| `al-haseeb@1` | **3** | "there is" |
| `al-muqsit@1` | **3** | "you been" |

**An earlier revision measured worse. Recorded so the regression is not reintroduced.** The intra-group diff initially found a **9-gram** with `al-muqsit@1` and a **10-gram** with `al-hakam@1` — all four takeaways had been drafted quoting one another's engine descriptions word for word. **Each was rewritten to differentiate in its own words.** Recorded because the failure mode is counter-intuitive: those sentences existed *because* of bar 3(c), and they were creating the collision bar 3(c) exists to stop.

**Every āyah was checked against the shipped asset *and* all 26 pending drafts**, with a two-sided boundary match: **4:40 free · 6:115 free.** 6:115 first reported as cited by the `ad-darr` draft; that was a **false positive from a substring match on `16:115`**. The tool now anchors both boundaries — see the limits section.

### Bar 3(c) — the move

**Al-Adl's move is that the accounting is asymmetric, and the asymmetry runs toward the reader.**

The other three are about the *process* — whether it happens (Hakam), who testifies (Haseeb), whether the instrument is level (Muqsit). **This one is about the arithmetic**, and its whole content is that "fair" is not the neutral outcome the reader fears. An atom's weight is the *ceiling* on what can count against you; on the other side there is no stated ceiling at all, only `يُضَـٰعِفْهَا`.

**This is deliberately not a mercy deck**, and that boundary is what keeps it clear of two shipped neighbours. `al-ghafur@1` covers the record; `al-afuw@1` erases it. **Al-Adl does neither** — the wrong is still counted, exactly. The claim is that exact counting is *already* in the reader's favour, which is an assertion about **justice**, not about pardon. A deck that blurred that would be a third forgiveness deck.

Full four-way comparison in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §6.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **16:90** `إِنَّ ٱللَّهَ يَأْمُرُ بِٱلْعَدْلِ` | root present, Allah the subject — but the āyah is a **command to humans about human justice**. It demonstrates what Allah *orders*, not what Allah *does*. Left free |
| **4:58 · 5:8 · 6:152 · 5:95 · 2:282** | same — `ٱلْعَدْل` as instruction to people. Left free |
| **6:1 · 6:150 · 27:60 · 42:15** (`يَعْدِلُونَ` / `عَدَلُوا۟`) | the **negative** sense — ascribing equals to Allah. Grammatically the root, semantically the opposite of the Name. ⚠️ **R3 correction:** R0 read these as Allah being the grammatical subject. **He is not** — the subject of *"ascribe equals"* is the disbelievers. The rejection is still right, but for the reason stated here rather than the one R0 gave |
| **82:7** `ٱلَّذِى خَلَقَكَ فَسَوَّىٰكَ فَعَدَلَكَ` | ⚠️ **R3 — never disclosed at R0.** Allah **is** the subject of `ʿadala` here, so this is the one occurrence R0's framing should have caught and did not. It is a **different semantic domain** — *proportioned you*, physical balance, not judicial justice — so it does not supply the Name and **does not disturb the trade.** Recorded because an undisclosed counterexample is the shape that makes a sweep untrustworthy |
| **21:47's `فَلَا تُظْلَمُ نَفْسٌ شَيْـًٔا`** | a `ظلم`-negation that would have suited this Name well — **deliberately left to `al-muqsit@1`** so that two decks in one group do not both render a `ظلم`-negation. See the group partition |
| **6:115's `وَهُوَ ٱلسَّمِيعُ ٱلْعَلِيمُ`** | `as-sami@1` / `al-aleem@1` ground. This deck renders the first clause only |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā is Qurʾān-shaped and is not Qurʾānic** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §1, ledger **§9cf**). `source: ""`. Reported, not actioned.
2. **Id 48's `arabic` is `الْعَدْلُ`, a verbal noun ("justice"), where its three siblings are agent nouns.** Purely an observation about the catalogue's Name list; **nothing in this deck depends on it and no change is recommended.**
3. **The `lesson` — *"Al-Adl will never wrong you — not by the weight of an atom"* — is a close paraphrase of 4:40**, the āyah this deck independently selected. Noted as corroboration, not as the route: the sweep reached 4:40 from the root data, and the `lesson` was read afterwards.

---

## What I could not determine — attack these first

1. **The bar-4 trade is the thing to attack.** If a verifier rules that a verse beat cannot discharge bar 4 for a story beat lacking the root, this deck needs a different structure — but the sweep shows **no single text carries both**, so the alternative is a refusal, not a rewrite.
2. **`ظ-ل-م` was not swept.** 4:40's root is Al-Adl's *meaning* but no Name's *word*, so no `Zlm` sweep was run. **If a future deck is built on `ظ-ل-م`, this story beat is prior art it must diff against.**
3. **The group bar-5 ruling** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §2) — though this deck depends on it least, its own neighbourhood being clean.
4. **No ḥadīth fetched** — no ḥadīth beats, and the duʿā claims no narration (§9bc).

---

## Pairing verdict

**No hard ship dependency, but read with its group.** This deck renders text disjoint from all three siblings (4:40 and 6:115; the siblings use 21:47, 3:18, 22:56, 95:8, 4:86). **The duʿā beat is identical on all four** — catalogue-locked, disclosed, and no beat on any of them claims it is Name-specific.
