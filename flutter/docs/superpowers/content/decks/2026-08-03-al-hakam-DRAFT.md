# Deck Draft — Al-Hakam (catalogue id 47) — **R0, awaiting independent blind verification**

**One of the judgment four.** Ids 47, 48, 55 and 90 share one locked `dua_arabic`. **The shared material — the duʿā's non-Qurʾānic construction (§9cf), the group-wide bar-5 ruling, all four root sweeps, the āyah partition, and the four engines side by side — lives in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) and is not repeated here.** Read it first; this file carries only what is specific to this Name.

> **Id 47 was previously quarantined for fabricated content.** That draft was not reused and not read as precedent; its ground was released.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Group claim: `.context/claims/47-48-55-90.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International). **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-hakam@1` — Al-Hakam

**Why this deck exists, in one line:** the user carrying a case nobody will ever hear — not a grievance they could prove, just the private certainty that something was done to them and nothing followed.

**The reader's grievance, which is what separates this deck from its three siblings:** **unheard.** Not that the verdict might go badly, and not that the scale is crooked — that no verdict is coming at all.

**Proposed metadata**

```json
{
  "deck_id": "al-hakam@1",
  "name_id": 47,
  "transliteration": "Al-Hakam",
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
> You have been carrying a case nobody will hear. Not a grievance you could prove — just the private certainty that something was done to you and nothing followed.

**Beat 2 · name_intro** *(catalogue id 47 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْحَكَمُ — Al-Hakam — The Judge

**Beats 3–5 · story — "The Day the Case Is Heard"** *(Qur'an 22:56)*:
> 3. Allah says of a day still coming: "All sovereignty that Day is for Allah; He will judge between them."
> 4. Not that justice exists somewhere. Not that it will work out. A verb, with a subject: He will judge. The case is heard. Something follows it.
> 5. "So they who believed and did righteous deeds will be in the Gardens of Pleasure." That is where the verdict lands for the ones who waited without ever being heard.

**Beat 6 · verse** *(whole āyah, no truncation; **sūrah-final**)*:
> Is not Allah the most just of judges? — Qur'an 95:8

**Beat 7 · duʿā** *(catalogue id 47, **byte-for-byte**, asserted programmatically (§9cb). **`source: ""` — the string is NOT Qurʾānic, §9cf**)*:
> اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ
> *Allahumma uhkum baynana wa bayna qawmina bil-haqq wa anta khayrul-hakimin*
> "O Allah, judge between us and our people in truth — You are the best of judges."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> The other three Names in this family answer questions about the verdict — how it is calculated, who testifies for you, whether the scale is level. Al-Hakam answers an earlier one: whether it is ever delivered at all. Most of the weight you carry is not unfairness. It is a case still open.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What would you put down tonight if you believed the hearing was scheduled rather than refused?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"All sovereignty that Day is for Allah; He will judge between them. So they who believed and did righteous deeds will be in the Gardens of Pleasure"* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../22:56` | ✅ `ٱلْمُلْكُ يَوْمَئِذٍ لِّلَّهِ يَحْكُمُ بَيْنَهُمْ ۚ فَٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ فِى جَنَّـٰتِ ٱلنَّعِيمِ` — rendered from `يَحْكُمُ` onward; `ٱلْمُلْكُ يَوْمَئِذٍ لِّلَّهِ` **left for id 88** |
| 2 | *"Is not Allah the most just of judges?"* (beat 6) | `.../95:8` | ✅ `أَلَيْسَ ٱللَّهُ بِأَحْكَمِ ٱلْحَـٰكِمِينَ` — whole āyah, no truncation |
| 3 | Successor sweep n−1: 22:55 | `.../22:55` | ⚠️ **punishment** — `عَذَابُ يَوْمٍ عَقِيمٍ`. Not rendered |
| 4 | Successor sweep n+1: 22:57 | `.../22:57` | ⚠️ **punishment** — `فَأُو۟لَـٰٓئِكَ لَهُمْ عَذَابٌ مُّهِينٌ`. Not rendered |
| 5 | Successor sweep n−1 of the verse beat: 95:7 | `.../95:7` | ✅ rhetorical question, no punishment |
| 6 | Successor sweep n+1 of the verse beat: 95:9 | `.../95:9` | ✅ **HTTP 404 — sūrah-final**, verified by status code |
| 7 | The locked duʿā | `collectible_names.json` id 47 | ✅ all three fields asserted present (§9cb). **`source: ""` — not Qurʾānic, §9cf** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **22:56** `يَحْكُمُ بَيْنَهُمْ` — finite verb, Allah the grammatical subject, in Allah's own narration of a future act | ✅ **PASS** |
| 2 | Shown, not stated | the āyah does not assert that Allah judges — it **narrates the judging and then its outcome**, `فَٱلَّذِينَ ءَامَنُوا۟ … فِى جَنَّـٰتِ ٱلنَّعِيمِ`. A verdict with a consequence attached is an event, not an attribute | ✅ **PASS** |
| 3 | No sibling-Name collapse | three surfaces, measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ح-ك-م` in **both** rendered scripture beats — `يَحْكُمُ` (22:56) and `بِأَحْكَمِ ٱلْحَـٰكِمِينَ` (95:8) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **punishment on *both* sides of the carrier** — the worst bar-5 neighbourhood in the group | ⚠️ **PASS after truncation — this deck's weakest point** |

**Bar 5, at full strength rather than summarised.** 22:56 is bracketed by punishment: **22:55** ends `عَذَابُ يَوْمٍ عَقِيمٍ`, and **22:57** reads `فَأُو۟لَـٰٓئِكَ لَهُمْ عَذَابٌ مُّهِينٌ` — *"for those there will be a humiliating punishment."* The deck renders **22:56 only**, which resolves into `جَنَّـٰتِ ٱلنَّعِيمِ`, and no beat alludes to either neighbour.

**That does not make the exposure disappear, and it is not being graded away.** A reader who looks up 22:56 lands on 22:57. **Of the four decks in this group this is the one most likely to be sent back**, and a verifier should treat the truncation argument as the thing to attack rather than the thing to tick. The counter-argument, for completeness: 22:56 is a self-contained sentence whose own resolution is the Garden, and the group's bar-5 ruling ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §2) is that Judgment as the reader's *vindication* is in register while Judgment as their *peril* is not. **If that ruling falls, this deck falls with it.**

The verse beat carries the strongest available bar-5 form: **95:8 is sūrah-final** — `api.quran.com/.../95:9` returns **HTTP 404**, verified by status code — and 95:7 is a rhetorical question with no punishment.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time**, not from a note (§9bi): **45**. Every beat run against every `primary` and `translation` string, maximum shared word-run computed by dynamic programming.

**Maximum shared word-run across the whole deck: 3** — every hit a function-word run ("weight you", "what the", "is the"). **No finding.**

**Intra-group twin-diff — against all three siblings, not one** (§9bs: a twin-diff between two members of a four-Name group is not sufficient):

| vs | max run | the run |
|---|---|---|
| `al-adl@1` | **3** | "have been" |
| `al-haseeb@1` | **3** | "would you" |
| `al-muqsit@1` | **4** | "scale is level" — this deck's takeaway **naming** Al-Muqsit in order to separate from it |

**An earlier revision measured worse. Recorded so the regression is not reintroduced.** Beat 8 originally shared a **6-gram** with `al-quddus@1`'s bridge — *"what you are carrying is"* — and the intra-group diff found a **10-gram** with `al-adl@1`, because both takeaways repeated one differentiating sentence verbatim. **Both rewritten.** The second is the instructive one: cross-referencing siblings in order to separate them had produced exactly the duplication bar 3(c) exists to prevent.

**Every āyah was checked against the shipped asset *and* all 26 pending drafts**, with a two-sided boundary match: **22:56 free · 95:8 free** — no shipped deck renders either and no pending draft cites them.

### Bar 3(c) — the move

**Al-Hakam's move is the narrowest of the four and the earliest in sequence: whether a verdict is delivered at all.**

Its three siblings all answer questions *about* a verdict — Al-Adl how it is calculated, Al-Haseeb who has to testify, Al-Muqsit whether the instrument is level. **All three presuppose the case is already before the court.** This deck is for the reader who has not got that far: whose complaint is not that justice went wrong, but that nothing ever happened.

That is why the carrier is a **finite verb in a future sense** — `يَحْكُمُ`, *He will judge* — rather than an epithet. The Name-form `حَكَمًا` appears at 6:114 inside `قُلْ`-instructed recitation and **cannot carry bar 1** (§9bk). The Name had to be built on the act; the act is also the only thing that answers the grievance.

Full four-way comparison in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §6.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **6:114** `أَفَغَيْرَ ٱللَّهِ أَبْتَغِى حَكَمًا` | the only occurrence of the Name-form `حَكَمًا`, and it sits inside **`قُلْ`-instructed recitation** — §9bk rules that this does not carry bar 1. Rejected on the ladder, not on register |
| **5:1** `إِنَّ ٱللَّهَ يَحْكُمُ مَا يُرِيدُ` | root and divine subject both present, but it is a **trailing clause on a passage of dietary law** — it labels rather than narrates, and its surroundings cannot reach the reader |
| **10:109 · 7:87 · 12:80** (`وَهُوَ خَيْرُ ٱلْحَـٰكِمِينَ`) | all three are **third-person epithets appended to human speech or to instruction**; 10:109 is also cited in the `al-azeez@1` draft |
| **95:8 as the bar-1 carrier** | a rhetorical question, not a narrated act. Used as the verse beat, where it does not need to carry bar 1 |
| **22:55 · 22:57** | punishment. Never rendered |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā is Qurʾān-shaped and is not Qurʾānic** — construction table in [`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §1 and ledger **§9cf**. It must ship with `source: ""`. Reported for all four decks at once and **not actioned**.
2. **Nothing else.** Id 47's `english` (*"The Judge"*), `meaning` and `lesson` are mutually consistent, and the `lesson` — *"When the world is unjust, remember that Al-Hakam will settle every account"* — is precisely this deck's engine.

---

## What I could not determine — attack these first

1. **Bar 5 is this deck's load-bearing weakness** — punishment one āyah before and one āyah after the carrier. Disclosed above at full strength. **Attack this first.**
2. **`ح-ك-م` has 210 occurrences and was not exhaustively enumerated** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §7). The corpus headline and form breakdown were read; individual āyāt were fetched only for the named candidates. **This is the likeliest place in the group for a better carrier to have been missed** — §9cc's "fetch every occurrence" was not affordable at this root size. Stated as a limit, not dressed as completeness.
3. **The group bar-5 ruling** ([`2026-08-03-JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) §2) is a judgement call. If it is rejected, all four decks fall together — which is the right granularity for it.
4. **No ḥadīth fetched.** There are no ḥadīth beats and the duʿā claims no narration, so `sunnah.com` was never queried — a fact about this deck's needs, not a claim about that site (§9bc).

---

## Pairing verdict

**No hard ship dependency, but read with its group.** This deck renders text disjoint from all three siblings (22:56 and 95:8; the siblings use 21:47, 3:18, 4:86, 4:40, 6:115). **The duʿā beat is identical on all four** — catalogue-locked, disclosed, and no beat on any of them claims it is Name-specific.
