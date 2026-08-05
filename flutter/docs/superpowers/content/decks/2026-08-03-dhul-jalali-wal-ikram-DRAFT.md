# Deck Draft — Dhul-Jalali wal-Ikram (catalogue id 89) — **R0, awaiting independent blind verification**

⚠️ **Ids 89 and 56 rest on the same two āyāt** — `ج-ل-ل` occurs **twice in the whole Qurʾān**, 55:27 and 55:78, **both the phrase that is this Name.** `al-jaleel@1` takes 55:27; **this deck takes 55:78**. Read them together.
>
> ⚠️ **Shipped `as-salam@1` renders this Name in its duʿā beat** — `تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ`. See the bars note.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/89.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `dhul-jalali-wal-ikram@1` — Dhul-Jalali wal-Ikram

**Why this deck exists, in one line:** the user who has decided that closeness and reverence are a trade — that getting near costs you the awe, and keeping the awe costs you the nearness.

**The reader's position:** **forced to choose between safety and closeness.**

**Proposed metadata**

```json
{
  "deck_id": "dhul-jalali-wal-ikram@1",
  "name_id": 89,
  "transliteration": "Dhul-Jalali wal-Ikram",
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
> You want to be near something vast without being flattened by it. Those two do not usually arrive together.

**Beat 2 · name_intro** *(catalogue id 89 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> ذُو الْجَلَالِ وَالْإِكْرَامِ — Dhul-Jalali wal-Ikram — Lord of Majesty and Bounty

**Beats 3–5 · story — "Where the Sūrah Stops Asking"** *(Qur'an 55:77–78)*:
> 3. Sūrat ar-Rahman asks one question again and again: which of the favors of your Lord would you deny?
> 4. Then it stops asking. Its final line is not a question.
> 5. "Blessed is the name of your Lord, Owner of Majesty and Honor." The sūrah of favours closes by naming the One who gave them — with both words at once.

**Beat 6 · verse** *(whole āyah, no truncation; **sūrah-final**)*:
> Blessed is the name of your Lord, Owner of Majesty and Honor. — Qur'an 55:78

**Beat 7 · duʿā** *(catalogue id 89, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا ذَا الْجَلَالِ وَالْإِكْرَامِ أَجِرْنَا مِنَ النَّارِ
> *Ya Dhal-Jalali wal-Ikram, ajirna minan-nar*
> "O Lord of Majesty and Bounty, protect us from the Fire and grant us the nearness of Your generosity."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Jaleel takes the first word of this phrase from an earlier āyah. This Name is the phrase entire, and the conjunction is the point. Majesty by itself would be a reason to keep back. Honour by itself would be warmth without weight. The Qur'an never separates them, and neither does the Name.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Where have you been choosing between being safe and being close?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | The sūrah's repeated question (beat 3, **described, not quoted as a beat**) | `.../55:77` | ✅ `فَبِأَىِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ` — the refrain, immediately before the carrier |
| 2 | *"Blessed is the name of your Lord, Owner of Majesty and Honor."* (beats 5–6, **bar-1 and bar-4 carrier**) | `.../55:78` | ✅ `تَبَـٰرَكَ ٱسْمُ رَبِّكَ ذِى ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` — **whole āyah** |
| 3 | Successor sweep n+1: 55:79 | `.../55:79` | ✅ **HTTP 404 — sūrah-final.** Verified by status code |
| 4 | Root sweep — **complete at 2 occurrences** | `corpus…?q=jll` | ✅ **55:27 and 55:78 only.** 55:27 **left to `al-jaleel@1`** |
| 5 | Cross-check against production | `assets/content/name_stories.json` | ⚠️ **shipped `as-salam@1`'s duʿā renders this Name in full** — `تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ` |
| 6 | The locked duʿā | `collectible_names.json` id 89 | ✅ three fields asserted present (§9cb). ⚠️ **it names the Fire** — see bars note |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **55:78** `تَبَـٰرَكَ ٱسْمُ رَبِّكَ ذِى ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` — Allah's own voice, the Name predicated in the sūrah's closing sentence | ✅ **PASS** |
| 2 | Shown, not stated | the demonstration is **structural and unusual**: a sūrah that has asked one question thirty-one times **stops asking**, and what it says instead is this Name. The compound is shown as the answer to seventy-seven āyāt of enumerated favours | ⚠️ **PASS — the weakest bar here; the argument is about placement, not about a narrated act** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — with a disclosed collision against production** |
| 4 | Root in the quoted text | `ج-ل-ل` as `ٱلْجَلَـٰلِ` and `ك-ر-م` as `ٱلْإِكْرَامِ` — **both halves of the compound Name, in the rendered text** | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **the strongest available form** — 55:77 is the refrain, and **55:79 returns HTTP 404: sūrah-final** | ✅ **PASS** |

**Bar 5 is the strongest form the sweep can report:** **55:79 returns HTTP 404**, verified by status code. **55:78 closes Sūrat ar-Rahman**, and its predecessor is the sūrah's own refrain.

**The collision with production, stated at full strength.** Shipped **`as-salam@1`'s duʿā beat** is the post-prayer dhikr: `اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ` — rendered *Blessed are You, O Owner of Majesty and Honor.* **That is this Name, in full, in a deck that is already live.** The measured run is **5 words**.

**It cannot be engineered around.** The phrase is fixed liturgy and fixed scripture; §9bl forbids translation-shopping to dodge a rendered-string collision, and there is no second rendering of `ذِى ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` that would be honest. **What the deck does instead is take the half `as-salam@1` does not use** — that deck's duʿā is a *vocative address*; this deck's argument is about **the conjunction**, which `as-salam@1` never comments on.

**Register finding on this deck's own duʿā, disclosed because bar 5 requires it.** Id 89's locked `dua_translation` is *O Lord of Majesty and Bounty, **protect us from the Fire** and grant us the nearness of Your generosity.* **The duʿā names the Fire.** It is catalogue-locked and unchangeable; it is the reader's own petition rather than a statement about them; and **no other beat in the deck mentions punishment**. Flagged rather than smoothed — this is the only deck in the wave whose *duʿā* carries the bar-5 hazard.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 5.** **5** — *"of majesty and honor"*, against **shipped `as-salam@1`'s duʿā**, i.e. against this Name rendered in production. **Unavoidable** (§9bl). All other hits are function-word runs.

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **55:77 free · 55:78 free.** **55:27 left to `al-jaleel@1`.** The `as-salam@1` duʿā collision is against the shipped asset, not against an āyah citation, and was found by the n-gram sweep rather than by the `spent` check — **which only looks at `source` fields.**

### Bar 3(c) — the move

**This Name's move is the conjunction itself.**

`جَلَال` alone is a reason to keep your distance. `إِكْرَام` alone is warmth without weight. **The Qurʾān joins them, twice out of two, and never separates them** — and the reader's grievance is precisely that they believe the two are in tension.

**The placement is the argument.** Sūrat ar-Rahman spends seventy-seven āyāt enumerating favours and interrogating the reader with one repeated question. **Then it stops.** The last thing it does is not ask — it *blesses*, and it blesses by naming both attributes at once. **The sūrah of favours ends on the compound**, which is the strongest available evidence that the compound is what the favours were demonstrating.

**Against `al-jaleel@1`:** that deck takes the first half of the phrase, from the earlier āyah, and argues about **bearing** — awe that is safe to approach. **This deck argues about the joint** — that the two were never available separately.

**Against `al-kareem@1` (shipped)**, which holds `ك-ر-م`: Al-Kareem is generosity as **behaviour**. `إِكْرَام` here is generosity as **half of a name**, inseparable from majesty. **The risk is real and it is on the takeaway.**

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **55:27** | **left to `al-jaleel@1`.** The only other occurrence of the root in the Qurʾān |
| **Any third text** | **there is none.** `corpus?q=jll` returns **two occurrences, total** |
| **The sūrah's garden passages (55:46–76)** | `ar-rahman@1` holds the sūrah's Name; this deck renders two āyāt of it and describes the refrain without quoting the gardens |

---

## Catalogue findings — reported, **NO change recommended**

1. **A shipped deck renders this Name in full.** `as-salam@1`'s duʿā beat carries `يَا ذَا الْجَلَالِ وَالْإِكْرَامِ`. **Reported, not actioned** — the duʿā is that deck's locked catalogue string and is correct for it. **But it means this Name reached production before its own deck existed**, which is the same failure class as `al-baseer@1` spending Ash-Shaheed's root and `al-haleem@1` spending As-Sabur's carrier. **Third instance; see the handoff.**
2. **This deck's own duʿā names the Fire** (`أَجِرْنَا مِنَ النَّارِ`). Locked. Disclosed under bar 5. **No change recommended** — it is a canonical supplication — but it is the only duʿā in the wave that carries a bar-5 hazard.
3. **Ids 56 and 89 share their entire root and are not flagged as a group**, because §9ce's map is built on `dua_arabic` collisions. **Recorded as a gap in that map.**

---

## What I could not determine — attack these first

1. **Bar 2 is the weakest bar.** The demonstration is *placement* — where the sūrah stops — rather than a narrated act. **If a verifier rules that placement cannot show, this Name has one remaining text (55:27) and it belongs to `al-jaleel@1`**, so the outcome would be a merge of the two decks or a refusal of one.
2. **The `as-salam@1` collision is against production and is unavoidable.**
3. **The 56/89 partition is a same-session, same-author decision.** Re-check independently.
4. **The `al-kareem@1` separation is argued, not measured** (§9cd).
5. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Must be reviewed with `al-jaleel@1`.** Two decks, one two-occurrence root, one āyah each. Neither is assessable alone, and a reviewer should decide whether two decks on `ج-ل-ل` is one deck too many.
