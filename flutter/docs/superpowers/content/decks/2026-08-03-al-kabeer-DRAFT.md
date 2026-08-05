# Deck Draft — Al-Kabeer (catalogue id 53) — **R0, awaiting independent blind verification**

> **Id 53 was previously quarantined for fabricated content.** That draft was not reused and not read as precedent; its ground was released.
>
> Its verse beat uses ground **reserved for it by `al-mutaali@1`**, which renders only one word of 13:9 and left `ٱلْكَبِيرُ` standing.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/53.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-kabeer@1` — Al-Kabeer

**Why this deck exists, in one line:** the user with something looming — a diagnosis, a deadline, a person — that has grown until it is the only thing they can see the size of.

**The reader's position:** **outsized.** Not doubting He is great in principle; unable to make the comparison land against the specific thing in front of them.

**Proposed metadata**

```json
{
  "deck_id": "al-kabeer@1",
  "name_id": 53,
  "transliteration": "Al-Kabeer",
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
> Whatever is looming over you right now has a size. It also has something it is smaller than.

**Beat 2 · name_intro** *(catalogue id 53 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْكَبِيرُ — Al-Kabeer — The Greatest

**Beats 3–5 · story — "The Smaller Half of the Promise"** *(Qur'an 9:72)*:
> 3. Allah promises the believers gardens with rivers running beneath them, and good dwellings in gardens of perpetual residence.
> 4. Then, inside the same sentence, He says the thing that makes all of that the smaller half: "…but approval from Allah is greater."
> 5. Greater than the gardens. The verse sets the highest thing anyone was ever promised beside one word — His being pleased — and tells you which of the two is larger.

**Beat 6 · verse** *(partial quotation — **one word** of a four-epithet clause, ellipsis both sides)*:
> …the Grand… — Qur'an 13:9

**Beat 7 · duʿā** *(catalogue id 53, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا كَبِيرُ أَشْعِرْنِي بِصِغَرِي أَمَامَكَ حَتَّى لَا يَمْلَأَ قَلْبِي كِبْرٌ
> *Ya Kabeer, ash'irni bisighari amamak hatta la yamla' qalbi kibr*
> "O Greatest, let me feel my smallness before You so that arrogance never fills my heart."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Azeem resets the scale you measure on. Al-Kabeer answers the comparison you are actually running — the thing you are frightened of, held up against Him. That verse performs the comparison once, and it uses Paradise as the smaller term.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Name the thing that is looming. Now say out loud what it is smaller than.

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Allah has promised the believing men and believing women gardens beneath which rivers flow … but approval from Allah is greater."* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../9:72` | ✅ `وَعَدَ ٱللَّهُ … وَرِضْوَٰنٌ مِّنَ ٱللَّهِ أَكْبَرُ` — **whole āyah**, described and quoted |
| 2 | *"…the Grand…"* (beat 6) | `.../13:9` | ✅ `ٱلْكَبِيرُ` — **one word**, ellipsis both sides. **Reserved for this Name by `al-mutaali@1`**, which renders only `ٱلْمُتَعَالِ` |
| 3 | Successor sweep n−1: 9:71 | `.../9:71` | ✅ clean — believers as allies, closes `سَيَرْحَمُهُمُ ٱللَّهُ` |
| 4 | Successor sweep n+1: 9:73 | `.../9:73` | ⚠️ **Hell** — `وَمَأْوَىٰهُمْ جَهَنَّمُ`. **Not rendered** |
| 5 | Root sweep | `corpus…?q=kbr` | ✅ **161 occurrences, 18 forms** — the second-largest root in the project |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **9:72** — Allah's own narration of what He has promised, and then His own ranking of it against His `رِضْوَٰن` | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **performs a comparison rather than asserting a magnitude** — it lists the gardens in full, then subordinates them in the same sentence. Greatness is shown by what it outranks | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ك-ب-ر` as `أَكْبَرُ` (9:72) and `ٱلْكَبِيرُ` (13:9) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ n−1 (9:71) is clean — believers as allies, mercy promised; **n+1 (9:73) is Hell** | ⚠️ **PASS — successor never rendered** |

**Bar 5 finding, stated not smoothed.** **9:73** — `يَـٰٓأَيُّهَا ٱلنَّبِىُّ جَـٰهِدِ ٱلْكُفَّارَ … وَمَأْوَىٰهُمْ جَهَنَّمُ` — is the immediate successor and it names Hell. **Not rendered, not alluded to.** **9:71**, the predecessor, is clean and warm: believers as allies of one another, closing on `سَيَرْحَمُهُمُ ٱللَّهُ`.

**9:72 itself contains no punishment at all** — it is entirely gardens, dwellings and approval, closing `ذَٰلِكَ هُوَ ٱلْفَوْزُ ٱلْعَظِيمُ`. The exposure is a reader who reads on, and it is the same exposure every truncated citation carries.

**Why the Name-form was not the carrier.** `ك-ب-ر` is **161 occurrences in 18 forms** — the second-largest root touched in this project — and `ٱلْكَبِير` predicated of Allah appears at 13:9, 22:62, 31:30, 34:23 and 40:12, **all trailing epithets in pairs**, three of them cited in pending drafts and 40:12 set inside a Judgment rebuke. **9:72's `أَكْبَرُ` is an elative doing comparative work in a sentence**, which is what makes it demonstrate.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"of the two"* (vs `ar-rafi@1`'s takeaway), a function-word run. **No finding.**

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **9:71–9:73 free · 13:9 free.** Checked and left: **22:62 · 31:30 · 34:23** cited in the `al-ali`, `al-mutakabbir` and `an-nafi` drafts; **40:12** free but a Judgment rebuke; **13:9's `عَـٰلِمُ ٱلْغَيْبِ` left for id 60**, `ٱلْمُتَعَالِ` **rendered by `al-mutaali@1`**.

### Bar 3(c) — the move

**Al-Kabeer's move is the comparison itself, performed once by the Qur'ān with Paradise as the smaller term.**

The reader is not short of belief that Allah is great; they are unable to get the belief to touch the specific thing frightening them tonight. **9:72 does the arithmetic in public**: it lists the whole promised reward — gardens, rivers, eternal residence, good dwellings — and then, in the same breath, calls something else `أَكْبَرُ`. **If Paradise is the smaller half of a sentence, the thing looming over the reader has a place in that ranking too.**

**Against `al-azeem@1` (drafted this session):** Al-Azeem **removes** the comparison — magnitude that resets the ruler, shown through water and fire. **Al-Kabeer keeps the comparison and wins it.** One says *stop measuring*; the other says *measure, and see*.

**Against `al-mutaali@1` (drafted this session), which shares 13:9:** that Name is transcendence over **descriptions**. This one is greatness over **things**. They render one word each of the same āyah and argue different clauses of it.

**Against `al-mutakabbir@1` (drafted, id 19):** supremacy against a **claimant** — a rival asserting itself. Al-Kabeer needs no rival: the thing it outranks in 9:72 is Paradise, which is not competing.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **13:9 as the bar-1 carrier** | a **four-epithet chain** — labels, does not demonstrate (§9bk). Used as the verse beat, where it needn't carry bar 1 |
| **22:62 · 31:30 · 34:23** `ٱلْعَلِىُّ ٱلْكَبِيرُ` | trailing epithet pairs, each cited in a pending draft, and each welded to **id 52's** Name |
| **40:12** `فَٱلْحُكْمُ لِلَّهِ ٱلْعَلِىِّ ٱلْكَبِيرِ` | the root and Allah's voice — spoken **to the damned in Hell**. Bar 5, absolutely |
| **17:43's `عُلُوًّا كَبِيرًا`** | **left free by `al-mutaali@1`** for this Name — but it is cited in the `al-quddus` draft and its head is `ع-ل-و`. Not taken |
| **29:45 `وَلَذِكْرُ ٱللَّهِ أَكْبَرُ`** | free, and a genuine alternative — but its subject is **the remembrance**, not Allah, and the comparison is with prayer's effects. **Left available** |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing.** Id 53's `english` (*The Greatest*), `meaning` and `lesson` (*Whatever towers over you in fear — Al-Kabeer is greater than it*) are consistent, and the `lesson` is this deck's engine.

---

## What I could not determine — attack these first

1. **`ك-ب-ر`'s 161 occurrences were not exhaustively fetched** (§9cc) — the second-largest root here. The form breakdown was read and the `ٱلْكَبِير` predications enumerated; **incomplete on the root.**
2. **9:73's Hell adjacency** is disclosed, not resolved.
3. **The `al-azeem@1` separation** — *remove the comparison* vs *win it* — is argued, not measured, and both decks were written by the same author in the same session. **Re-argue** (§9cd).
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Read alongside `al-azeem@1` and `al-mutaali@1` — the first for the engine split, the second because they divide 13:9.
