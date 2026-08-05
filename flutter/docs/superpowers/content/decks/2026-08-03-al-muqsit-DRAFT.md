# Deck Draft — Al-Muqsit (catalogue id 90) — **R0, awaiting independent blind verification**

**One of the judgment four.** Ids 47, 48, 55 and 90 share one locked `dua_arabic`. **The shared material — the duʿā's non-Qurʾānic construction (§9cf), the group-wide bar-5 ruling, all four root sweeps, the āyah partition, and the four engines side by side — lives in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) and is not repeated here.** Read it first; this file carries only what is specific to this Name.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Group claim: `.context/claims/47-48-55-90.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International). **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-muqsit@1` — Al-Muqsit

**Why this deck exists, in one line:** the user who has stopped expecting fairness — not because they gave up, but because they have watched how these things go too many times.

**The reader's grievance, which is what separates this deck from its three siblings:** **distrust of the process itself.** Not whether the verdict comes, or how it is calculated, but whether the instrument was ever honest.

**Proposed metadata**

```json
{
  "deck_id": "al-muqsit@1",
  "name_id": 90,
  "transliteration": "Al-Muqsit",
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
> You have stopped expecting fairness — not because you gave up, but because you have watched how these things go too many times.

**Beat 2 · name_intro** *(catalogue id 90 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُقْسِطُ — Al-Muqsit — The Equitable

**Beats 3–5 · story — "The Scale Set Before Anyone Stands On It"** *(Qur'an 21:47, first half)*:
> 3. Allah says: "And We place the scales of justice for the Day of Resurrection…"
> 4. Placed — before anyone stands on them. The instrument is set before the first case is called, and it is set by the One who will hear it.
> 5. "…so no soul will be treated unjustly at all." Not most souls. Not the ones with someone to speak for them. Not one soul, not at all.

**Beat 6 · verse** *(partial quotation — visible ellipsis both sides; **four words of a very dense āyah**)*:
> …maintaining [creation] in justice… — Qur'an 3:18

**Beat 7 · duʿā** *(catalogue id 90, **byte-for-byte**, asserted programmatically (§9cb). **`source: ""` — the string is NOT Qurʾānic, §9cf**)*:
> اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ
> *Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin*
> "O Allah, judge between us and our people in truth — You are the best of judges."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Every other Name in this family acts once a case is already before it. This one acts earlier, on the instrument itself. The scale is level before the first soul steps onto it — so equity is never a favour granted case by case, and never something a better advocate could have won you more of.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Where have you been arguing for a fairness that was never actually in doubt?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And We place the scales of justice for the Day of Resurrection, so no soul will be treated unjustly at all"* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../21:47` | ✅ `وَنَضَعُ ٱلْمَوَٰزِينَ ٱلْقِسْطَ لِيَوْمِ ٱلْقِيَـٰمَةِ فَلَا تُظْلَمُ نَفْسٌ شَيْـًٔا` — **first half only**, stopping at the āyah's own `ۖ`. Second half **left to `al-haseeb@1`** |
| 2 | *"…maintaining [creation] in justice…"* (beat 6) | `.../3:18` | ✅ `قَآئِمًۢا بِٱلْقِسْطِ` — **four words**, ellipsis both sides. `شَهِدَ ٱللَّهُ` **left for id 60**; `ٱلْعَزِيزُ ٱلْحَكِيمُ` **left for id 26** |
| 3 | Successor sweep n−1: 21:46 | `.../21:46` | ⚠️ **punishment** — `عَذَابِ رَبِّكَ`, *"O woe to us"*. Not rendered |
| 4 | Successor sweep n+1: 21:48 | `.../21:48` | ✅ clean |
| 5 | The locked duʿā | `collectible_names.json` id 90 | ✅ all three fields asserted present (§9cb). **`source: ""` — not Qurʾānic, §9cf** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **21:47a** `وَنَضَعُ ٱلْمَوَٰزِينَ ٱلْقِسْطَ` — first-person plural, Allah the subject, a narrated act of placing | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **narrates an action with an order of operations** — the scales are *placed* `لِيَوْمِ ٱلْقِيَـٰمَةِ`, in advance of the day they serve — and then gives the consequence, `فَلَا تُظْلَمُ نَفْسٌ شَيْـًٔا`. Setup and result, not an attribute | ✅ **PASS** |
| 3 | No sibling-Name collapse | three surfaces, measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ق-س-ط` in **both** rendered scripture beats — `ٱلْقِسْطَ` (21:47) and `بِٱلْقِسْطِ` (3:18) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **n−1 (21:46) is a punishment āyah**; n+1 (21:48) is clean | ⚠️ **PASS — predecessor never rendered** |

**Bar 5 finding, shared with `al-haseeb@1` because the two decks divide one āyah.** **21:46** reads `وَلَئِن مَّسَّتْهُمْ نَفْحَةٌ مِّنْ عَذَابِ رَبِّكَ لَيَقُولُنَّ يَـٰوَيْلَنَآ` — a punishment āyah immediately before the carrier. **Never rendered, never alluded to.** 21:48 is clean (Mūsā and Hārūn given the criterion).

**Why bar 1 could not be built on the Name-form — the `qsT` sweep's main output.** 25 occurrences in 5 forms across 22 āyāt. The Name-form **`ٱلْمُقْسِطِينَ` occurs 3 times — 5:42, 49:9, 60:8 — and in all three the subject is *people*:** *"Allah loves those who act justly."* **It describes whom Allah loves, not what Allah does.** Likewise 55:9 (`وَأَقِيمُوا۟ ٱلْوَزْنَ بِٱلْقِسْطِ`) is an imperative to humans, and 4:3 / 4:127 / 2:282 are legal instructions. **Only 21:47 and 3:18 predicate `qisṭ` of Allah's own act**, and this deck uses both — which is also why its bar-4 needs no trade while its sibling Al-Adl's does.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time**, not from a note (§9bi): **45**. Every beat run against every `primary` and `translation` string, maximum shared word-run computed by dynamic programming.

**Maximum shared word-run across the whole deck: 3** — every hit a function-word run ("is the", "one has to"). **No finding.**

**Intra-group twin-diff — against all three siblings, not one** (§9bs: a twin-diff between two members of a four-Name group is not sufficient):

| vs | max run | the run |
|---|---|---|
| `al-hakam@1` | **4** | "scale is level" — Al-Hakam's takeaway naming this Name |
| `al-adl@1` | **3** | "you been" |
| `al-haseeb@1` | **3** | "says and" |

**An earlier revision measured worse. Recorded so the regression is not reintroduced.** The intra-group diff initially found a **9-gram** with `al-adl@1` and a **7-gram** with `al-hakam@1` — a shared story opener (*"Allah says of a day still coming"*) plus cross-quoted takeaway sentences. **This deck's beat 3 opener and beat 8 were both rewritten.**

**Every āyah was checked against the shipped asset *and* all 26 pending drafts**, with a two-sided boundary match: **21:47 free · 3:18 free.** 3:18 first appeared to be cited by the `al-haqq` draft; that was a **false positive from a substring match on `13:18`**, confirmed by reading the line.

### Bar 3(c) — the move

**Al-Muqsit's move is that the instrument is set before the first case is called.**

Its three siblings all act on a case already before the court. **This one acts a step earlier — on the scale itself.** `وَنَضَعُ ٱلْمَوَٰزِينَ ٱلْقِسْطَ`: the scales are *placed*, `لِيَوْمِ ٱلْقِيَـٰمَةِ`, ahead of the day they will be used, by the One who will also hear the case.

**That answers a grievance the other three do not touch.** A reader who distrusts *process* is not reassured by being told the judge is fair — that is precisely the claim they have stopped believing. What answers them is that the fairness is **structural**: `فَلَا تُظْلَمُ نَفْسٌ شَيْـًٔا`, not one soul, not at all. Equity here is not a favour granted case by case, and not something a better advocate could have won more of.

Full four-way comparison in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §6.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **5:42 · 49:9 · 60:8** (`ٱلْمُقْسِطِينَ`) | the only occurrences of the Name's own form, and **all three have humans as subject** — *"Allah loves those who act justly."* **Bar 1 cannot be built on this Name's form.** Left free |
| **55:9** `وَأَقِيمُوا۟ ٱلْوَزْنَ بِٱلْقِسْطِ` | imperative **to humans**; also adjacent to 55:7–8's balance imagery, which this deck deliberately does not borrow |
| **4:3 · 4:127 · 2:282 · 33:5 · 6:152** | `qisṭ` in legal instruction to people |
| **57:25** `لِيَقُومَ ٱلنَّاسُ بِٱلْقِسْطِ` | humans again — and cited in the `al-qawiyy@1` draft |
| **21:47's second half** | **deliberately left to `al-haseeb@1`.** This deck stops at the āyah's own `ۖ` pause |
| **3:18's `شَهِدَ ٱللَّهُ` and `ٱلْعَزِيزُ ٱلْحَكِيمُ`** | left for **60 Ash-Shaheed** and **26 Al-Hakeem**. This deck renders **four words** of 3:18 |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā is Qurʾān-shaped and is not Qurʾānic** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §1, ledger **§9cf**). `source: ""`. Reported, not actioned.
2. **Nothing else.** Id 90's `english` (*"The Equitable"*), `meaning` and `lesson` (*"Al-Muqsit will balance every scale. Justice will come"*) are consistent with one another and with this deck.

---

## What I could not determine — attack these first

1. **3:18 is the densest āyah any deck in this wave touches** — it carries Ash-Shaheed's root, Al-Aleem's, Al-Azeez's and Al-Hakeem's, plus the tawḥīd formula. This deck renders **four words** of it. **A verifier should confirm the truncation still reads as a verse beat** rather than as a fragment.
2. **The 21:47 split with `al-haseeb@1` was verified by reading both drafts' beat text — but both were written in the same session by the same author**, which is weaker than two independent drafters agreeing on a boundary. Re-check it independently.
3. **The group bar-5 ruling** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §2), plus 21:46's punishment adjacency.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**No hard ship dependency, but read with its group.** This deck renders text disjoint from all three siblings (21:47a and 3:18; Al-Haseeb takes 21:47c and 4:86, Al-Hakam 22:56 and 95:8, Al-Adl 4:40 and 6:115). **The duʿā beat is identical on all four** — catalogue-locked, disclosed, and no beat on any of them claims it is Name-specific.
