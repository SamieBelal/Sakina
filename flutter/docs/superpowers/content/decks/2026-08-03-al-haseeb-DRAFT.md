# Deck Draft — Al-Haseeb (catalogue id 55) — **R0, awaiting independent blind verification**

**One of the judgment four.** Ids 47, 48, 55 and 90 share one locked `dua_arabic`. **The shared material — the duʿā's non-Qurʾānic construction (§9cf), the group-wide bar-5 ruling, all four root sweeps, the āyah partition, and the four engines side by side — lives in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) and is not repeated here.** Read it first; this file carries only what is specific to this Name.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Group claim: `.context/claims/47-48-55-90.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International). **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-haseeb@1` — Al-Haseeb

**Why this deck exists, in one line:** the user who did something no one saw, and has half-decided it did not really happen — because there is no one left who could confirm it.

**The reader's grievance, which is what separates this deck from its three siblings:** **unwitnessed.** Not doubting that justice comes, but doubting that anything they did survived into the record without someone there to vouch for it.

**Proposed metadata**

```json
{
  "deck_id": "al-haseeb@1",
  "name_id": 55,
  "transliteration": "Al-Haseeb",
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
> The thing you did that nobody saw — you have half-decided it did not really happen, because there is no one left who could confirm it.

**Beat 2 · name_intro** *(catalogue id 55 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْحَسِيبُ — Al-Haseeb — The Reckoner

**Beats 3–5 · story — "The Mustard Seed Brought Forth"** *(Qur'an 21:47, second half)*:
> 3. Allah says: "And if there is [even] the weight of a mustard seed, We will bring it forth."
> 4. Brought forth — from wherever it went when no one was looking. You do not produce it. You are not asked to.
> 5. "And sufficient are We as accountant." Sufficient: no second opinion, no corroborating witness, no case for you to build.

**Beat 6 · verse** *(partial quotation — visible ellipsis; the Name-form in-text)*:
> …Indeed Allah is ever, over all things, an Accountant. — Qur'an 4:86

**Beat 7 · duʿā** *(catalogue id 55, **byte-for-byte**, asserted programmatically (§9cb). **`source: ""` — the string is NOT Qurʾānic, §9cf**)*:
> اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ
> *Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin*
> "O Allah, judge between us and our people in truth — You are the best of judges."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Muhsi itemises; Al-Haseeb suffices. The difference is who has to do the work. Sufficient as accountant means the reckoning does not wait on your evidence, your memory, or anyone else having been in the room.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> If none of it needs a witness, what would you stop rehearsing tonight?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And if there is [even] the weight of a mustard seed, We will bring it forth. And sufficient are We as accountant"* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../21:47` | ✅ `وَإِن كَانَ مِثْقَالَ حَبَّةٍ مِّنْ خَرْدَلٍ أَتَيْنَا بِهَا ۗ وَكَفَىٰ بِنَا حَـٰسِبِينَ` — **second half only**, beginning after the āyah's own `ۖ`. First half **left to `al-muqsit@1`** |
| 2 | *"…Indeed Allah is ever, over all things, an Accountant"* (beat 6) | `.../4:86` | ✅ `إِنَّ ٱللَّهَ كَانَ عَلَىٰ كُلِّ شَىْءٍ حَسِيبًا` — closing clause only, visible ellipsis; the greeting law is not rendered |
| 3 | Successor sweep n−1: 21:46 | `.../21:46` | ⚠️ **punishment** — `عَذَابِ رَبِّكَ`, *"O woe to us"*. Not rendered |
| 4 | Successor sweep n+1: 21:48 | `.../21:48` | ✅ clean — Mūsā and Hārūn given the criterion |
| 5 | Successor sweep n−1 of the verse beat: 4:85 | `.../4:85` | ✅ no punishment — but closes `مُّقِيتًا`, **Al-Muqeet's (id 54) Name-form. Left entirely** |
| 6 | Successor sweep n+1 of the verse beat: 4:87 | `.../4:87` | ✅ Day-of-Resurrection assembly, **no punishment** |
| 7 | The locked duʿā | `collectible_names.json` id 55 | ✅ all three fields asserted present (§9cb). **`source: ""` — not Qurʾānic, §9cf** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **21:47c** `أَتَيْنَا بِهَا` — first-person plural, Allah the subject, a narrated act (*We will bring it forth*) | ✅ **PASS** |
| 2 | Shown, not stated | a **counterfactual with a magnitude** — `وَإِن كَانَ مِثْقَالَ حَبَّةٍ مِّنْ خَرْدَلٍ`, *even if it were the weight of a mustard seed*. The brief names counterfactuals as qualifying | ✅ **PASS** |
| 3 | No sibling-Name collapse | three surfaces, measured below | ⚠️ **PASS — but this is the deck's hard bar.** See surface (c) |
| 4 | Root in the quoted text | `ح-س-ب` in **both** rendered scripture beats — `حَـٰسِبِينَ` (21:47) and `حَسِيبًا` (4:86) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **n−1 (21:46) is a punishment āyah**; n+1 (21:48) is clean | ⚠️ **PASS — predecessor never rendered** |

**Bar 5 finding, stated not smoothed.** **21:46**, the predecessor of the carrier, reads `وَلَئِن مَّسَّتْهُمْ نَفْحَةٌ مِّنْ عَذَابِ رَبِّكَ لَيَقُولُنَّ يَـٰوَيْلَنَآ إِنَّا كُنَّا ظَـٰلِمِينَ` — *"if [as much as] a whiff of the punishment of your Lord should touch them, they would surely say, 'O woe to us!'"* **Never rendered, never alluded to.** 21:48 is clean.

**The `Hsb` sweep is why this deck is built on a verb and not on the Name-form.** 109 occurrences in 8 forms — but **44 are form I `ḥasiba`, *"they think / they suppose"***, a human act of mistaken reckoning, and **39 are `ḥisāb`, "the reckoning"**, overwhelmingly in Judgment contexts. **The Name-form `ḥasīb` occurs only 4 times** (4:6, 4:86, 33:39, 17:14), all predicate epithets that label rather than demonstrate. Bar 1 therefore had to come from `أَتَيْنَا` in 21:47, with `حَسِيبًا` supplying the Name-form on the verse beat.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time**, not from a note (§9bi): **45**. Every beat run against every `primary` and `translation` string, maximum shared word-run computed by dynamic programming.

**Maximum shared word-run across the whole deck: 3** — every hit a function-word run ("has to", "to do", "is ever", "are not"). **No finding.**

**Intra-group twin-diff — against all three siblings, not one** (§9bs: a twin-diff between two members of a four-Name group is not sufficient):

| vs | max run | the run |
|---|---|---|
| `al-hakam@1` | **3** | "would you" |
| `al-adl@1` | **3** | "there is" |
| `al-muqsit@1` | **3** | "says and" |

Also diffed against **`al-muhsi@1` (id 66, drafted)**, the nearest neighbour outside the group: **3**. Which is precisely §9cd's point — *the measurement does not find the risk.* See bar 3(c).

**An earlier revision measured worse. Recorded so the regression is not reintroduced.** This deck was the only one of the four whose intra-group runs never exceeded 3. The other three needed takeaway rewrites after the first diff found runs of 7–10 between them; noted here so the group's history is legible from any of its four files.

**Every āyah was checked against the shipped asset *and* all 26 pending drafts**, with a two-sided boundary match: **21:47 free · 4:86 free.** **65:3 was checked first and is heavily spent** — shipped `al-wakeel@1`'s verse beat plus **17 pending drafts** — which is why the sufficiency sense had to be reached through 21:47 instead.

### Bar 3(c) — the move

**Al-Haseeb's move is sufficiency: you do not have to make your own case.**

`وَكَفَىٰ بِنَا حَـٰسِبِينَ` — *sufficient are We as accountant*. The operative word is **sufficient**, not *accountant*. The reckoning does not wait on the reader's evidence, their memory, or anyone having been in the room.

**This is the deck at real risk of collapse, and §9cd is why it has to be said out loud.** Two neighbours are close and **no measurement finds either** — `al-muhsi@1` (id 66, drafted) measures **3** against this deck, and `al-ghafur@1` measures **3**:

| deck | what it is about |
|---|---|
| `al-muhsi@1` | **granularity.** Nothing is rounded off or absorbed into a total |
| `al-ghafur@1` | **the record's fate.** It is shown privately, then covered |
| **`al-haseeb@1`** | **sufficiency.** Nothing more is needed *from you* |

**Al-Muhsi says the list is complete; Al-Haseeb says the list needs nothing added by you.** One is a claim about the record, the other about the reader's obligation toward it. That is a real distinction and also a thin one — **a verifier should re-argue it from scratch rather than check this paragraph**, exactly as §9cd prescribes.

Full four-way comparison in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §6.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **65:3** `وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥ` | the warmest text for the *sufficiency* sense, and **heavily spent** — rendered by shipped `al-wakeel@1`'s verse beat and cited in **17 pending drafts**. Not available |
| **3:173** `حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ` | **reported human speech**, bottom rung of §9bk — and `al-wakeel@1`'s ground |
| **33:39** `وَكَفَىٰ بِٱللَّهِ حَسِيبًا` | Name-form present and register clean, but the āyah is **about messengers conveying revelation**; it does not reach the reader. Left free |
| **4:6** `وَكَفَىٰ بِٱللَّهِ حَسِيبًا` | the same phrase inside **orphans' property law**; also cited in two pending drafts. Rejected on fit |
| **17:14** | `حَسِيبًا` inside the *"read your record"* Judgment scene — bar 5 |
| **21:47's first half** | **deliberately left to `al-muqsit@1`.** This deck begins after the āyah's own `ۖ` pause |
| **4:85's `مُّقِيتًا`** (n−1 of the verse beat) | **Al-Muqeet's (id 54) own Name-form.** Left entirely unrendered |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā is Qurʾān-shaped and is not Qurʾānic** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §1, ledger **§9cf**). `source: ""`. Reported, not actioned.
2. **Id 55's `lesson` reads as another deck's engine.** *"Al-Haseeb counts every kindness. Nothing good is ever lost"* is a **granularity** claim, where this Name's Qurʾānic weight is **sufficiency** — and `al-muhsi@1` already occupies the granularity reading. **This deck follows the scripture rather than the `lesson`**, and the divergence is flagged here rather than quietly resolved. **No change recommended**, but a verifier should decide which of the two the deck ought to serve.

---

## What I could not determine — attack these first

1. **The `al-muhsi@1` separation is the load-bearing argument and it is thin.** Both decks are about a complete accounting; the split is *granularity* vs *sufficiency*. **Re-argue it, do not check it** (§9cd).
2. **The catalogue `lesson` points at the other deck's engine** (catalogue finding 2). A genuine unresolved tension, not a drafting preference.
3. **`Hsb`'s 109 occurrences were not exhaustively fetched.** The form breakdown was read and all 4 `ḥasīb` occurrences plus the named candidates were fetched, so **the sweep is complete on the Name-form and incomplete on the root** — §9cc's "fetch every occurrence" was not affordable at this size.
4. **The group bar-5 ruling** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §2), plus 21:46's punishment adjacency.
5. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**No hard ship dependency, but read with its group.** This deck renders text disjoint from all three siblings (21:47c and 4:86; Al-Muqsit takes 21:47a and 3:18, Al-Hakam 22:56 and 95:8, Al-Adl 4:40 and 6:115). **The duʿā beat is identical on all four** — catalogue-locked, disclosed, and no beat on any of them claims it is Name-specific.
