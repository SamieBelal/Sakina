# Deck Draft — Ash-Shakur (catalogue id 28) — **R0, awaiting independent blind verification**

**No shared duʿā, no quarantine history.** An independent single.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/28.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `ash-shakur@1` — Ash-Shakur

**Why this deck exists, in one line:** the user who did the costly, invisible thing — and has quietly filed it as not counting, because nothing came back.

**The reader's position:** **unreciprocated.** They are not asking to be forgiven or noticed. They are asking whether it registered.

**Proposed metadata**

```json
{
  "deck_id": "ash-shakur@1",
  "name_id": 28,
  "transliteration": "Ash-Shakur",
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
> You have done things whose cost nobody could see. That is the part you assume did not count.

**Beat 2 · name_intro** *(catalogue id 28 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الشَّكُورُ — Ash-Shakur — The Most Appreciative

**Beats 3–5 · story — "In Full, and Then Increased"** *(Qur'an 35:29–30)*:
> 3. Allah describes people who give "secretly and publicly", and says they can expect "a transaction that will never perish" —
> 4. "That He may give them in full their rewards and increase for them of His bounty."
> 5. Read the order. In full — and then increased. The full amount was already everything that was owed. The increase is not payment. It is appreciation.

**Beat 6 · verse** *(partial quotation — the closing clause, visible ellipsis)*:
> …Indeed, He is Forgiving and Appreciative. — Qur'an 35:30

**Beat 7 · duʿā** *(catalogue id 28, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا شَكُورُ اشْكُرْ لِي سَعْيِي وَلَا تَخْذُلْنِي
> *Ya Shakuru ushkur li sa'yi wa la takhdhulni*
> "O Most Appreciative, appreciate my striving and do not abandon me."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Kareem gives before you ask. Ash-Shakur answers what you already did, and answers it out of proportion. The word in the verse is not a reward; it is a Name. The smallness of what you managed is not something He is politely overlooking.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What did you do that cost you something no one else could see?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"…those who recite the Book of Allah and establish prayer and spend out of what We have provided them, secretly and publicly, [can] expect a transaction that will never perish"* (beat 3) | `.../35:29` | ✅ `إِنَّ ٱلَّذِينَ يَتْلُونَ كِتَـٰبَ ٱللَّهِ … يَرْجُونَ تِجَـٰرَةً لَّن تَبُورَ` — described and partially quoted |
| 2 | *"That He may give them in full their rewards and increase for them of His bounty. Indeed, He is Forgiving and Appreciative."* (beats 4–6, **bar-1 and bar-4 carrier**) | `.../35:30` | ✅ `لِيُوَفِّيَهُمْ أُجُورَهُمْ وَيَزِيدَهُم مِّن فَضْلِهِۦ ۚ إِنَّهُۥ غَفُورٌ شَكُورٌ` — **whole āyah** |
| 3 | Successor sweep n−1: 35:28 | `.../35:28` | ✅ clean — colours of people and livestock, closes `عَزِيزٌ غَفُورٌ` |
| 4 | Successor sweep n+1: 35:31 | `.../35:31` | ✅ clean — closes `لَخَبِيرٌۢ بَصِيرٌ` |
| 5 | Root sweep | `corpus…?q=$kr` | ✅ **75 occurrences, 6 forms**; `shakūr` 10×, **the rest human gratitude** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **35:30** `لِيُوَفِّيَهُمْ أُجُورَهُمْ وَيَزِيدَهُم مِّن فَضْلِهِۦ ۚ إِنَّهُۥ غَفُورٌ شَكُورٌ` — Allah's own narration of His own response, with the Name attached to the act it just described | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **performs an arithmetic and then exceeds it** — `لِيُوَفِّيَهُمْ` (pay in full) followed by `وَيَزِيدَهُم` (and increase). The appreciation is the surplus, shown | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ش-ك-ر` as `شَكُورٌ` in the rendered clause of 35:30 | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **clean both sides** — 35:29 is the setup (*a transaction that will never perish*); 35:31 closes `لَخَبِيرٌۢ بَصِيرٌ` | ✅ **PASS** |

**Bar 5, measured (§9ak):** two āyāt fetched, zero punishment, and **35:29 is not merely clean — it is the deck's own setup**, describing people who give *secretly and publicly* (`سِرًّا وَعَلَانِيَةً`). The story runs continuously across 35:29→35:30 with no elision.

**Why the sweep pointed here.** `ش-ك-ر` has **75 occurrences in six forms**, and **the overwhelming majority are human gratitude** — 46× form I `shakara`, 14× `shākir`. `شَكُور` predicated of **Allah** occurs 10 times, and most are trailing epithets (`إِنَّ رَبَّنَا لَغَفُورٌ شَكُورٌ` 35:34, which is **human speech**; `وَٱللَّهُ شَكُورٌ حَلِيمٌ` 64:17, cited in the `al-haleem` draft). **35:30 is the one where the epithet is attached directly to a described act of Allah's**, which is what makes it demonstrate rather than label.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 3.** the only hit is *"one else"* (vs `al-mughni@1`'s duʿā), a function-word run. **The lowest measured maximum in this wave.**

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **35:29 free · 35:30 free.** Checked and left: **64:17** cited in the `al-haleem` draft; **35:34** is human speech; **42:23** and **4:147** free but epithets.

### Bar 3(c) — the move

**Ash-Shakur's move is that the response is disproportionate on purpose.**

`لِيُوَفِّيَهُمْ أُجُورَهُمْ` — *pay them their wages in full* — already discharges the debt entirely. **Everything after that word is surplus**, and the āyah names the surplus `مِّن فَضْلِهِ`, from His bounty, before naming Him `شَكُورٌ`. **The Name is the surplus.**

**Against `al-kareem@1` (shipped)** — the nearest neighbour and a real risk: Al-Kareem's move is **giving before being asked**, generosity with no antecedent. **Ash-Shakur's requires an antecedent** — it is a *response*, and the whole consolation depends on it: the reader is not asking to be given something, they are asking whether the thing they did landed.

**Against `al-wahhab@1` (shipped):** the Bestower gives freely and without cause. Again: this Name answers something. **A deck that made Ash-Shakur about generosity would be a third gift deck**, and it does not.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **64:17** `وَٱللَّهُ شَكُورٌ حَلِيمٌ` | root present and Allah's voice — **cited in the `al-haleem` draft**, and `حَلِيمٌ` is that shipped deck's Name |
| **35:34** `إِنَّ رَبَّنَا لَغَفُورٌ شَكُورٌ` | **reported human speech** — the people of Paradise. §9bk bottom rung |
| **42:23** `إِنَّ ٱللَّهَ غَفُورٌ شَكُورٌ` | free; a trailing epithet on a passage about the Prophet's recompense. **Left available** |
| **4:147** `وَكَانَ ٱللَّهُ شَاكِرًا عَلِيمًا` | a different form (`shākir`), and the āyah opens on `مَّا يَفْعَلُ ٱللَّهُ بِعَذَابِكُمْ` — **punishment in the first clause.** Bar 5 |
| **the 46 form-I occurrences** | **human** gratitude — the wrong subject for this Name |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing.** Id 28's `english`, `meaning`, `lesson` (*Even your private acts of goodness are seen and multiplied by Ash-Shakur*) and duʿā are consistent — and the `lesson`'s **"multiplied"** is precisely 35:30's `وَيَزِيدَهُم`.

---

## What I could not determine — attack these first

1. **`ش-ك-ر`'s 75 occurrences were not exhaustively fetched** (§9cc) — the form breakdown was read and the 10 divine `shakūr` predications enumerated.
2. **The `al-kareem@1` separation is argued, not measured** (§9cd) — *response* vs *unprompted gift*. Thin enough to re-argue.
3. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.**
