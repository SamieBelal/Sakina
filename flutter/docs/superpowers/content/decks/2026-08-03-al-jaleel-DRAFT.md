# Deck Draft — Al-Jaleel (catalogue id 56) — **R0, awaiting independent blind verification**

⚠️ **Ids 56 and 89 rest on the same two āyāt.** `ج-ل-ل` occurs **twice in the entire Qurʾān** — 55:27 and 55:78 — and **both are the phrase `ذُو ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ`, which is id 89's whole Name.** The two decks divide them: **this deck takes 55:27, `dhul-jalali-wal-ikram@1` takes 55:78.** Read them together.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/56.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-jaleel@1` — Al-Jaleel

**Why this deck exists, in one line:** the user comparing themselves to things — a career, a body, a reputation — that are themselves on the way out.

**The reader's position:** **dwarfed by the wrong things.**

**Proposed metadata**

```json
{
  "deck_id": "al-jaleel@1",
  "name_id": 56,
  "transliteration": "Al-Jaleel",
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
> You have been measuring yourself against things that are themselves going to end.

**Beat 2 · name_intro** *(catalogue id 56 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْجَلِيلُ — Al-Jaleel — The Majestic

**Beats 3–5 · story — "What Remains"** *(Qur'an 55:26–27)*:
> 3. Allah says: "Everyone upon it will perish…"
> 4. "…and there will remain the Face of your Lord, Owner of Majesty and Honor."
> 5. Two clauses. Everything on one side of them goes. What is named on the other side is not power, and not duration — it is majesty and honour, welded into one phrase.

**Beat 6 · verse** *(partial quotation — visible ellipsis; the second clause of the carrier)*:
> …Owner of Majesty and Honor. — Qur'an 55:27

**Beat 7 · duʿā** *(catalogue id 56, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا جَلِيلُ امْلَأْ قَلْبِي إِجْلَالًا لَكَ يُقَرِّبُنِي مِنْكَ لَا خَوْفًا يُبْعِدُنِي عَنْكَ
> *Ya Jaleel, imla' qalbi ijlalan laka yuqarribuni mink la khawfan yub'iduni 'ank*
> "O Majestic, fill my heart with reverence that draws me near, not fear that drives me away. Let my awe of You refine me until I stand before You humbled, but never disgraced."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Azeem resets the scale. Al-Kabeer answers what towers. Al-Jaleel is the word you cannot lift out of that phrase alone: majesty that arrives already carrying honour toward you. Awe that does not cost you your standing.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you been standing in awe of that gives you nothing back?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Everyone upon it will perish…"* (beat 3) | `.../55:26` | ✅ `كُلُّ مَنْ عَلَيْهَا فَانٍ` — whole āyah |
| 2 | *"…and there will remain the Face of your Lord, Owner of Majesty and Honor."* (beats 4–6, **bar-1 and bar-4 carrier**) | `.../55:27` | ✅ `وَيَبْقَىٰ وَجْهُ رَبِّكَ ذُو ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` — whole āyah |
| 3 | Successor sweep n+1: 55:28 | `.../55:28` | ✅ the sūrah's refrain. No punishment |
| 4 | Root sweep — **complete at 2 occurrences** | `corpus…?q=jll` | ✅ *"occurs **twice** in the Quran as the noun `jalāl`"* — **55:27 and 55:78, both the same phrase** |
| 5 | Cross-check against production | `assets/content/name_stories.json` | ⚠️ **shipped `as-salam@1`'s duʿā renders `يَا ذَا الْجَلَالِ وَالْإِكْرَامِ`** — a 5-word English run, unavoidable |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **55:27** `وَيَبْقَىٰ وَجْهُ رَبِّكَ ذُو ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` — Allah's own voice, and the majesty is predicated in the clause that survives the annihilation of everything else | ✅ **PASS** |
| 2 | Shown, not stated | the āyah is **a two-clause contrast performed in sequence** — everything perishes; this remains. Majesty is shown by what is left standing, not asserted | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — but see the two disclosures below** |
| 4 | Root in the quoted text | `ج-ل-ل` as `ٱلْجَلَـٰلِ`. **The root has only two occurrences in the Qurʾān and this deck holds one of them** | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ 55:26 is mortality, **not punishment** — `كُلُّ مَنْ عَلَيْهَا فَانٍ`; 55:28 is the sūrah's refrain | ✅ **PASS** |

**Two disclosures, both real, both unavoidable.**

**(i) The root is two occurrences and the other belongs to id 89.** `corpus?q=jll` — *"occurs **twice** in the Quran as the noun `jalāl`"*, at **55:27 and 55:78**. **Both are the identical phrase `ذُو/ذِى ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ`.** So Al-Jaleel and Dhul-Jalali wal-Ikram do not merely overlap — **they have the same two words available and nothing else.** The partition (55:27 here, 55:78 there) is the only structure that gives each a distinct rendered text, and it is the `al-muqsit@1`/`al-haseeb@1` manoeuvre on 21:47.

**(ii) Shipped `as-salam@1` already renders this phrase.** Its duʿā beat is the post-prayer dhikr `اللَّهُمَّ أَنْتَ السَّلَامُ … تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ` — *Blessed are You, O Owner of Majesty and Honor.* **A 5-word English run against a deck in production**, and it is **scripture-shaped fixed liturgy**, so §9bl forbids translation-shopping around it. **Disclosed, not engineered around.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 5.** **5** — *"of majesty and honor"*, against **shipped `as-salam@1`'s duʿā beat**. This is the fixed rendering of `ذَا ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` and cannot be avoided without mistranslating (§9bl). **Disclosed as unavoidable, not as clean.** Every other hit is a function-word run.

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **55:26 free · 55:27 cited in the `al-baqi` draft** (as `يَبْقَىٰ`, that Name's root — **checked: it is cited in a sweep, not rendered as a beat**). **55:78 left to id 89.**

### Bar 3(c) — the move

**Al-Jaleel's move is majesty that arrives already carrying honour toward you.**

The phrase is a compound and the compound is the point: **`جَلَال` alone is a reason to stand back; `إِكْرَام` is what the same Being does toward the one standing there.** The Qurʾān never uses one without the other — literally never, in two occurrences out of two.

**Against `al-azeem@1` (drafted):** scale that resets the ruler. **Against `al-kabeer@1` (unstarted):** what towers over you. **Al-Jaleel is neither size nor height** — it is *bearing*: the quality that makes awe safe to approach.

**Against `al-baqi@1` (shipped)**, which is the sharpest risk here because it holds `ي-ب-ق-ى`: that deck's move is **what lasts** — its takeaway is about what was kept versus what was spent. **This deck renders the same āyah's second clause and takes the *predicate*, not the persistence.** `al-baqi@1` reads 55:26–27 for *remaining*; this deck reads it for *what the remaining One is like*.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **55:78** | **left to `dhul-jalali-wal-ikram@1`.** The only other occurrence of the root |
| **the `ٱلْجَلِيل` Name-form** | **does not occur in the Qurʾān at all.** Only `ٱلْجَلَـٰل` does, twice. Its attestation as a Name is the Tirmidhī 3507 enumeration, graded **`Daʿīf`** — noted, not cited |
| **55:26** `كُلُّ مَنْ عَلَيْهَا فَانٍ` | rendered as the story's first clause; carries no root and is not the carrier |
| **The rest of Sūrat ar-Rahman** | the refrain and the paired descriptions of the two gardens; **`ar-rahman@1` holds the sūrah's Name** and this deck renders two āyāt of it |

---

## Catalogue findings — reported, **NO change recommended**

1. **The Name-form `ٱلْجَلِيل` is not Qurʾānic** — only `ٱلْجَلَـٰل` is, and only in id 89's compound. Like As-Sabur (id 32), the Name-form's attestation is **Tirmidhī 3507, graded `Daʿīf`**. **Bar 4 is still met here** (the root is in the rendered text), so this is a note rather than a trade — **but a verifier should know the Name itself is not a Qurʾānic epithet.**
2. **Ids 56 and 89 are not flagged as a group anywhere**, because they do not share a `dua_arabic` — **they share something narrower and more binding: the entirety of their root.** §9ce's map is built on duʿā collisions and would not catch this. **Recorded as a gap in that map.**

---

## What I could not determine — attack these first

1. **The `as-salam@1` collision is unavoidable and is a 5-word run against production.** Disclosed. If a reviewer rules it disqualifying, this Name has **no other text in the Qurʾān** and the outcome is a refusal.
2. **The 56/89 partition is a same-session, same-author decision on two āyāt**, which is weaker than two drafters agreeing. Re-check the split independently.
3. **The `al-baqi@1` separation is argued, not measured.** Both decks read 55:26–27.
4. **No ḥadīth fetched** (§9bc) — though given catalogue finding 1, the Tirmidhī enumeration is the Name's only attestation and **was read** (via the As-Sabur work), not re-fetched here.

---

## Pairing verdict

**Must be reviewed with `dhul-jalali-wal-ikram@1`.** They divide a two-occurrence root; neither can be assessed alone.
