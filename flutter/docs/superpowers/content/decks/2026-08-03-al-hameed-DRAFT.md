# Deck Draft — Al-Hameed (catalogue id 65) — **R0, awaiting independent blind verification**

**No shared duʿā.** An independent single — but **part of its ground was spent before it was drafted**: `al-majeed@1` (id 58, drafted this session) renders 11:73's `حَمِيدٌ مَّجِيدٌ`, because the two words are inseparable in that clause. Recorded in `.context/claims/50-58.md`.
>
> It also **shares an āyah with two other decks**: 34:1 is divided between `al-hakeem@1` (`ٱلْحَكِيمُ`), `al-khabeer@1` (`ٱلْخَبِيرُ`) and **this deck (the two `ٱلْحَمْدُ` clauses)** — a three-way split of one āyah, the `al-malik@1`/`al-muizz@1`/`al-muzill@1` precedent on 3:26.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/65.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-hameed@1` — Al-Hameed

**Why this deck exists, in one line:** the user for whom gratitude currently feels like a performance they cannot honestly give.

**The reader's position:** **unable to praise.** They are not in doubt about His deserving it. They cannot produce it, and have concluded that makes them a fraud.

**Proposed metadata**

```json
{
  "deck_id": "al-hameed@1",
  "name_id": 65,
  "transliteration": "Al-Hameed",
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
> Praise, when things are going badly, feels like lying. It is not.

**Beat 2 · name_intro** *(catalogue id 65 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْحَمِيدُ — Al-Hameed — The Praiseworthy

**Beats 3–5 · story — "Praise in Both Places"** *(Qur'an 34:1)*:
> 3. Allah says: "[All] praise is due to Allah, to whom belongs whatever is in the heavens and whatever is in the earth…"
> 4. "…and to Him belongs [all] praise in the Hereafter."
> 5. Both. Praise from inside a world where things break, and praise from inside one where nothing does. The same praise. The verse does not wait for conditions to improve before it becomes true.

**Beat 6 · verse** *(partial quotation — the second `ٱلْحَمْد` clause, visible ellipsis)*:
> …and to Him belongs [all] praise in the Hereafter. — Qur'an 34:1

**Beat 7 · duʿā** *(catalogue id 65, **byte-for-byte**, asserted programmatically (§9cb))*:
> الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ
> *Al-hamdu lillahi Rabbil 'aalameen hamdan katheeran tayyiban mubarakan feeh*
> "All praise is due to Allah, Lord of all the worlds — abundant, pure, and blessed praise."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Wadud is loved. Al-Hameed is praised — and praise answers what a thing is, not how it has been treating you lately. This Name does not ask you to feel grateful tonight. It says the praise is owed whether or not you can currently produce any.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What would you praise Him for, if you were not allowed to mention yourself?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"[All] praise is due to Allah, to whom belongs whatever is in the heavens and whatever is in the earth… and to Him belongs [all] praise in the Hereafter."* (beats 3–6, **bar-1 and bar-4 carrier**) | `.../34:1` | ✅ `ٱلْحَمْدُ لِلَّهِ ٱلَّذِى لَهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ وَلَهُ ٱلْحَمْدُ فِى ٱلْـَٔاخِرَةِ` — **both `ٱلْحَمْد` clauses.** `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ` **not rendered** |
| 2 | Successor sweep n+1: 34:2 | `.../34:2` | ✅ closes `وَهُوَ ٱلرَّحِيمُ ٱلْغَفُورُ`. **34:1 is sūrah-opening**, so no n−1 within the sūrah |
| 3 | Root sweep | `corpus…?q=Hmd` | ✅ **63 occurrences, 5 forms**; `ḥamd` 43×, `ḥamīd` 17× — **and `ٱلْحَمِيد` is almost always welded to another Name** |
| 4 | Cross-check: what `al-majeed@1` renders | this session's drafts | ⚠️ **11:73's `حَمِيدٌ مَّجِيدٌ` is spent** — inseparable clause, recorded in `.context/claims/50-58.md` |
| 5 | Cross-check: the 34:1 partition | this session's drafts | ✅ `al-hakeem@1` takes `ٱلْحَكِيمُ`, `al-khabeer@1` takes `ٱلْخَبِيرُ`, **neither touches `ٱلْحَمْد`** — verified by reading their beat text |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **34:1** — Allah's own voice, and the praise is predicated **twice, in two different worlds**, as a statement of what is owed rather than of what is felt | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **splits the claim across two conditions** — `فِى ٱلْـَٔاخِرَةِ` explicitly named alongside the present — so the praise is shown to be **independent of circumstances**, which is the reader's exact objection | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — three decks divide this āyah; see below** |
| 4 | Root in the quoted text | `ح-م-د` as `ٱلْحَمْدُ`, twice, in the rendered clauses | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ 34:1 is **sūrah-opening** (no n−1 within the sūrah); **34:2 closes `وَهُوَ ٱلرَّحِيمُ ٱلْغَفُورُ`** | ✅ **PASS** |

**The three-way split of 34:1, disclosed in full.** The āyah reads `ٱلْحَمْدُ لِلَّهِ ٱلَّذِى لَهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ وَلَهُ ٱلْحَمْدُ فِى ٱلْـَٔاخِرَةِ ۚ وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ`. Three decks drafted in this session divide it:

| deck | renders | leaves |
|---|---|---|
| **`al-hameed@1`** | both `ٱلْحَمْدُ` clauses | the closing epithets |
| `al-hakeem@1` | `ٱلْحَكِيمُ` — **one word** | everything else |
| `al-khabeer@1` | `ٱلْخَبِيرُ` — **one word** | everything else |

**No deck renders another's clause** — verified by reading all three drafts' beat text, not inferred from the boundaries. **All three were written by the same author in the same session, which is weaker than three drafters agreeing**, and a verifier should re-check the partition independently.

**Bar 5.** 34:1 opens Sūrat Saba', so there is **no n−1 within the sūrah**; **34:2** closes `وَهُوَ ٱلرَّحِيمُ ٱلْغَفُورُ` — the Merciful, the Forgiving. Clean.

**Why `حَمِيد` itself is not the carrier.** `ح-م-د` has **63 occurrences**: 43× the noun `ḥamd`, **17× the nominal `ḥamīd`** — and `ٱلْحَمِيد` predicated of Allah is **almost always welded to another Name**: `ٱلْغَنِىُّ ٱلْحَمِيدُ` (14:8, 31:26, 35:15 — `al-ghaniyy@1`'s), `ٱلْوَلِىُّ ٱلْحَمِيدُ` (42:28 — `al-waliyy@1`'s), `حَمِيدٌ مَّجِيدٌ` (11:73 — **now `al-majeed@1`'s**). **The noun `ٱلْحَمْد` is where the Name is free**, and 34:1 is where it is doubled.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"all praise is"* (vs `as-sami@1`'s story), a fixed Qurʾānic opening rendered identically. Function words plus scripture. **No finding.**

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **34:1 cited in the `al-hakeem` and `al-khabeer` drafts — by partition, not by conflict.** Checked and left: **11:73** (`حَمِيدٌ مَّجِيدٌ`) **spent by `al-majeed@1`**; 14:8, 31:26, 35:15 (`ٱلْغَنِىُّ ٱلْحَمِيدُ`) are `al-ghaniyy@1`'s ground; 42:28 is `al-waliyy@1`'s.

### Bar 3(c) — the move

**Al-Hameed's move is that praise is a description of Him, not a report on your mood.**

The reader's objection is honest: praising while things are bad feels like lying. **34:1 answers it by predicating the praise twice — once in a world where things break, once in a world where nothing does — and making no reference to the praiser at all.** The clause is `لَهُ ٱلْحَمْدُ`, *to Him belongs the praise*. It is a statement about ownership, not about production.

**Against `al-wadud@1` (shipped):** Al-Wadud is **loved** — the affection runs from Him and back. **Al-Hameed is praised**, and praise answers what a thing *is*, independent of how it has treated you. A reader who cannot currently feel warmth toward Him can still be told the praise is owed.

**Against `ash-shakur@1` (drafted this session):** **exact inverse, and the pair is worth reading together.** Ash-Shakur is **Allah appreciating you**; Al-Hameed is **Allah being praiseworthy** whether or not you manage it. One is a response owed to the reader; the other a description owed to Him.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **11:73** `إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` | **spent by `al-majeed@1`** (id 58, drafted this session) — the two words are inseparable in the clause, and that deck needed `مَّجِيدٌ`. **Recorded in that claim file as unavoidable** |
| **14:8 · 31:26 · 35:15** `ٱلْغَنِىُّ ٱلْحَمِيدُ` | `al-ghaniyy@1`'s Name in the same construct |
| **42:28** `وَهُوَ ٱلْوَلِىُّ ٱلْحَمِيدُ` | `al-waliyy@1`'s Name in the same construct |
| **1:2** `ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ` | the opening of the Fātiḥah — **the most-rendered sentence in the religion**, and id 65's own duʿā already contains it. Using it as a beat would duplicate beat 7 |
| **34:1's `ٱلْحَكِيمُ ٱلْخَبِيرُ`** | **left to `al-hakeem@1` and `al-khabeer@1`** |

---

## Catalogue findings — reported, **NO change recommended**

1. **Id 65's duʿā is itself a `ح-م-د` text** — `الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ`. **Unusually, the duʿā carries the Name's root three times.** The deck therefore avoids 1:2 on its beats so beat 7 is not pre-empted. Noted, not actioned.
2. **Nothing else.** `english`, `meaning` and `lesson` (*Even in hardship, Al-Hameed deserves praise — and praising Him transforms the hardship*) are consistent, and the `lesson` is this deck's engine.

---

## What I could not determine — attack these first

1. **The three-way 34:1 split is same-author, same-session.** Re-check the partition independently — it is the only three-way split in the project besides 3:26, and that one was made by three separate drafters.
2. **11:73 was spent by a deck drafted hours earlier in this same session**, which is the tightest ordering dependency in the wave. Had this deck been drafted first, `al-majeed@1` would have had a harder problem. **Recorded because it is luck, not process.**
3. **`ح-م-د`'s 63 occurrences were not exhaustively fetched** (§9cc) — the form breakdown was read and the `ḥamīd` predications enumerated.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Should be reviewed alongside `al-hakeem@1` and `al-khabeer@1` (shared āyah) and read next to `ash-shakur@1` (inverse engines).
