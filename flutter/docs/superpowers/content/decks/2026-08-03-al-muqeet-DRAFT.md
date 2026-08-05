# Deck Draft — Al-Muqeet (catalogue id 54) — **R0, awaiting independent blind verification**

**No shared duʿā, no quarantine history.** An independent single — and **the shortest complete root sweep in the project**: `ق-و-ت` occurs **twice in the entire Qurʾān, and this deck holds both.**
>
> Its verse beat was **reserved for it by `al-haseeb@1`** (drafted this session), which met 4:85 as its own n−1 and left it entirely.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/54.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-muqeet@1` — Al-Muqeet

**Why this deck exists, in one line:** the user running the sum on whether there will be enough — money, time, strength — and getting a number that does not close.

**The reader's position:** **short.** Not doubting that provision exists; doubting that the quantity was ever set high enough.

**Proposed metadata**

```json
{
  "deck_id": "al-muqeet@1",
  "name_id": 54,
  "transliteration": "Al-Muqeet",
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
> You have been running the sum on whether there will be enough, and it keeps coming out short.

**Beat 2 · name_intro** *(catalogue id 54 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُقِيتُ — Al-Muqeet — The Nourisher

**Beats 3–5 · story — "Measured Into the Ground First"** *(Qur'an 41:10)*:
> 3. Allah says of the earth: "And He placed on it firmly set mountains over its surface, and He blessed it…"
> 4. "…and determined therein its sustenance in four days without distinction — for those who ask."
> 5. Determined. Measured out and set into the ground before anyone who would need it was on it. The provision was built into the place, not delivered to it afterwards.

**Beat 6 · verse** *(partial quotation — the closing clause, visible ellipsis)*:
> …And ever is Allah, over all things, a Keeper. — Qur'an 4:85

**Beat 7 · duʿā** *(catalogue id 54, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا مُقِيتُ أَقِتْنِي بِذِكْرِكَ وَأَغْذِ رُوحِي بِقُرْبِكَ
> *Ya Muqeet, aqitni bidhikrika wa-aghdhi ruhi biqurbik*
> "O Nourisher, sustain me with Your remembrance and nourish my soul with Your nearness."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Ar-Razzaq hands you the provision. Al-Muqeet set the quantity, and set it into the earth before you arrived on it. The question tonight is not whether there will be enough. It is what was measured in before you got here.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What are you rationing that was apportioned before you arrived?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And He placed on it firmly set mountains over its surface, and He blessed it and determined therein its sustenance in four days without distinction — for those who ask."* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../41:10` | ✅ `وَجَعَلَ فِيهَا رَوَٰسِىَ مِن فَوْقِهَا وَبَـٰرَكَ فِيهَا وَقَدَّرَ فِيهَآ أَقْوَٰتَهَا فِىٓ أَرْبَعَةِ أَيَّامٍ سَوَآءً لِّلسَّآئِلِينَ` — **whole āyah** |
| 2 | *"…And ever is Allah, over all things, a Keeper."* (beat 6) | `.../4:85` | ✅ `وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ مُّقِيتًا` — closing clause only; the intercession clause **not rendered** |
| 3 | Successor sweep n−1: 41:9 | `.../41:9` | ⚠️ `قُلْ`-framed challenge to disbelievers. **Not rendered** |
| 4 | Successor sweep n+1: 41:11 | `.../41:11` | ✅ **clean** — the heaven addressed while smoke; `قَالَتَآ أَتَيْنَا طَآئِعِينَ` |
| 5 | Successor sweep n−1 of the verse beat: 4:84 | `.../4:84` | ⚠️ fighting, closes `أَشَدُّ تَنكِيلًا`. **Not rendered** |
| 6 | Root sweep — **complete at 2 occurrences, both rendered** | `corpus…?q=qwt` | ✅ *"occurs **twice** in the Quran, in two derived forms"* — `أَقْوَٰت` (41:10) and `مُّقِيت` (4:85) |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **41:10** — Allah's own narration of His own act: `وَقَدَّرَ فِيهَآ أَقْوَٰتَهَا`, *He determined therein its sustenance* | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **narrates a sequence of construction** — mountains set, the earth blessed, sustenance measured in — and gives the timescale. Provision is shown being *built into* a place, not delivered to it | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ق-و-ت` as `أَقْوَٰتَهَا` (41:10) and `مُّقِيتًا` (4:85) — **the root's only two Qurʾānic occurrences, both rendered** | ✅ **PASS, no trade — and the sweep is complete** |
| 5 | Register and reverence | ⚠️ 41:9 is a `قُلْ`-framed polemic; **41:11–12 are clean** (the heaven as smoke, *We have come willingly*). The verse beat's n−1, **4:84, is a fighting āyah** | ⚠️ **PASS — neither rendered** |

**The complete sweep, which is this deck's strongest fact.** `corpus?q=qwt` — *"occurs **twice** in the Quran, in two derived forms: once as the noun `aqwāt` (أَقْوَٰت), once as the form IV active participle `muqīt` (مُّقِيت)."* **Two occurrences: 41:10 and 4:85. This deck renders both.** There is no third text, nothing was rejected for convenience, and **bar 4 is met without a trade on a root where a trade would have been unarguable.**

**Bar 5, fetched.** **41:9** is `قُلْ أَئِنَّكُمْ لَتَكْفُرُونَ` — a `قُلْ`-framed challenge, **not rendered**, and the deck begins at 41:10. **41:11** is one of the most striking clean successors in the Qurʾān: the heaven addressed while it was smoke, answering `أَتَيْنَا طَآئِعِينَ`. On the verse-beat side, **4:84 is a fighting āyah closing `أَشَدُّ تَنكِيلًا`** — **not rendered**; the beat takes only 4:85's closing clause, and **4:86 is `al-haseeb@1`'s ground.**

**One disclosure about the verse beat's own āyah.** 4:85 is about **intercession** — whoever intercedes for a good cause gets a share of it. The deck renders **only** the closing `وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ مُّقِيتًا` and makes no use of the intercession clause, which belongs to no Name in this catalogue but is not this deck's subject.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 3.** the only hit is *"is what"* (vs `al-quddus@1`'s bridge), a two-word function run. **The lowest measured maximum of the entire wave.**

**Every āyah checked against the shipped asset *and* all 48 pending drafts**, two-sided boundary match: **41:9–12 all free · 4:85 cited only by `al-haseeb@1`, which explicitly left it** (it appears there as an n−1 successor-sweep row, with `مُّقِيتًا` flagged as *"Al-Muqeet's (id 54) Name-form. Left entirely."*).

### Bar 3(c) — the move

**Al-Muqeet's move is that the quantity was set before you arrived.**

`وَقَدَّرَ فِيهَآ أَقْوَٰتَهَا` — *He determined therein its sustenance* — and the placement matters: it comes **between** the mountains being set and the heavens being completed. **The provision is part of the construction, not a later delivery.** For a reader whose sum will not close, the claim is not that more will be sent; it is that the amount was measured in at the build.

**Against `ar-razzaq@1` (shipped)** — the neighbour this deck must not collapse into: **Ar-Razzaq is the act of giving**, provision arriving in someone's hands. **Al-Muqeet is the apportioning** — the quantity determined, in the earth, before there was anyone to hand it to. One is transaction; the other is specification.

**Against `al-wasi@1` (drafted):** vastness of capacity. **Al-Muqeet is the opposite emphasis — a measured amount**, `قَدَّرَ`, which is a limit as much as a supply. The deck does not claim the provision is unlimited. It claims it was calculated.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **4:85 as the bar-1 carrier** | `وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ مُّقِيتًا` is a **trailing epithet** — it labels. Used as the verse beat, where it needn't carry bar 1 |
| **4:84** | fighting, closing `أَشَدُّ تَنكِيلًا`. **Never rendered** |
| **41:9** | `قُلْ`-framed challenge to disbelievers. Not rendered |
| **Any third text** | **there is none.** `ق-و-ت` has two Qurʾānic occurrences and this deck holds both |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing.** Id 54's `english` (*The Nourisher*), `meaning`, `lesson` (*Al-Muqeet feeds not only your body but your soul and your purpose*) and duʿā (*sustain me with Your remembrance*) are consistent. **The `lesson` and duʿā both extend the Name to non-material sustenance**, which 41:10 does not say — the āyah is about the earth's provision. **The deck stays with the āyah and lets the reader make the transfer**, which is the same restraint `ash-shaheed@1` applies.

---

## What I could not determine — attack these first

1. **The root sweep is complete — two of two occurrences fetched and rendered.** This is the only deck in the project that can say that. **It is also the deck's only real strength**: everything else rests on one āyah.
2. **Bar 1 rests entirely on 41:10.** If a verifier rules that `قَدَّرَ … أَقْوَٰتَهَا` is about the earth's provisioning rather than about Allah as *provider of sustenance*, there is no second text.
3. **The `ar-razzaq@1` separation** — apportioning vs giving — is argued, not measured (§9cd).
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Read alongside `ar-razzaq@1` and `al-haseeb@1` — the latter because it reserved this deck's verse beat.
