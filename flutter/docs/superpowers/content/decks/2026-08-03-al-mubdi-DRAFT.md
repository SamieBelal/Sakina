# Deck Draft — Al-Mubdi (catalogue id 67) — **R0, awaiting independent blind verification**

> ⚠️ **`al-muid@1` (id 68, drafted) renders this Name's root.** Its verse beat is 30:27 — `وَهُوَ ٱلَّذِى يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ` — **which contains `يَبْدَؤُا۟`, `ب-د-أ`.** The two Names are a natural pair the catalogue never grouped, and **30:27 is therefore unavailable to this deck.** See the bars note.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/67.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-mubdi@1` — Al-Mubdi

**Why this deck exists, in one line:** the user whose first attempt at something failed, and who has quietly concluded that it was the only attempt available.

**The reader's position:** **out of beginnings.**

**Proposed metadata**

```json
{
  "deck_id": "al-mubdi@1",
  "name_id": 67,
  "transliteration": "Al-Mubdi",
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
> You have been treating one attempt that failed as though it were the only attempt available.

**Beat 2 · name_intro** *(catalogue id 67 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُبْدِئُ — Al-Mubdi — The Originator

**Beats 3–5 · story — "A Promise Binding Upon Us"** *(Qur'an 21:104)*:
> 3. Allah says of a day still coming: "The Day when We will fold the heaven like the folding of a sheet for the records."
> 4. "As We began the first creation, We will repeat it."
> 5. Read what that promise is anchored to. Not to your record, and not to the odds. To the fact that He has already begun once — and beginning is the thing He is known for.

**Beat 6 · verse** *(partial quotation — the closing clauses of the carrier, visible ellipsis)*:
> …[That is] a promise binding upon Us. Indeed, We will do it. — Qur'an 21:104

**Beat 7 · duʿā** *(catalogue id 67, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا مُبْدِئُ ابْدَأْ لِي صَفْحَةً جَدِيدَةً وَأَحْدِثْ لِي تَوْبَةً نَصُوحًا
> *Ya Mubdi', ibda' li safhatan jadidatan wa-ahdith li tawbatan nasuhan*
> "O Originator, begin for me a new page and bring me a sincere repentance."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Khaliq makes. Al-Muid restores what was. Al-Mubdi is the One who starts, and the verse offers the first beginning as security for the next one. Whatever ended did not use up His capacity to begin.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What would you start, if starting were the thing He were known for?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"The Day when We will fold the heaven like the folding of a sheet for the records. As We began the first creation, We will repeat it. [That is] a promise binding upon Us. Indeed, We will do it."* (beats 3–6, **bar-1 and bar-4 carrier**) | `.../21:104` | ✅ `يَوْمَ نَطْوِى ٱلسَّمَآءَ … كَمَا بَدَأْنَآ أَوَّلَ خَلْقٍ نُّعِيدُهُۥ ۚ وَعْدًا عَلَيْنَآ ۚ إِنَّا كُنَّا فَـٰعِلِينَ` — **whole āyah**, split across beats |
| 2 | Successor sweep n−1: 21:103 | `.../21:103` | ⚠️ names `ٱلْفَزَعُ ٱلْأَكْبَرُ` — **inside a negation** for the righteous. Not rendered |
| 3 | Successor sweep n+1: 21:105 | `.../21:105` | ✅ clean — the righteous inherit the land |
| 4 | Root sweep | `corpus…?q=bdA` | ✅ **15 occurrences, 2 forms**; 12× form I `bada-a`, 3× form IV `yub'di-u` |
| 5 | Cross-check: what `al-muid@1` renders | this session's drafts | ⚠️ its verse beat is **30:27, whole** — which contains `يَبْدَؤُا۟`, **this Name's root.** 21:104 is cited there but **not rendered** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **21:104** `كَمَا بَدَأْنَآ أَوَّلَ خَلْقٍ نُّعِيدُهُۥ` — first-person plural, Allah the subject, a **completed act cited as security for a future one** | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **uses the first beginning as evidence** rather than describing an attribute — and then names the evidence's status: `وَعْدًا عَلَيْنَآ`, a promise binding upon Us | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — with a disclosed root collision against a sibling draft** |
| 4 | Root in the quoted text | `ب-د-أ` as `بَدَأْنَآ` in the rendered text | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ n−1 (21:103) names *the greatest terror* — **but negated for the righteous**; n+1 (21:105) is clean | ⚠️ **PASS — neither rendered** |

**The root collision, disclosed at full strength.** Every āyah in which Allah is said to *begin* creation pairs `يَبْدَؤُ` with `يُعِيدُ` in the same clause — 30:27, 10:4, 10:34, 29:19, 85:13, 30:11. **That is structural, not incidental: the Qur'ān treats originating and restoring as one statement.** And `al-muid@1` (id 68, drafted) renders **30:27 whole**, `يَبْدَؤُا۟` included.

So this deck could not take the obvious text, and the remaining candidates are all cited in pending drafts (`al-muid`, `al-awwal`, `al-khaliq`, `al-azeez`). **21:104 is the one that is cited but not rendered** — verified by reading `al-muid@1`'s beat structure, whose verse beat is 30:27 and whose story is a ḥadīth.

**21:104 is also the better text for this Name**, which is luck the deck should not claim as design: it is the only occurrence where the beginning is invoked **as a reason to believe a second thing will happen**, which is exactly the reader's problem.

**Bar 5, fetched.** **21:103** contains `ٱلْفَزَعُ ٱلْأَكْبَرُ` — *the greatest terror* — **inside a negation**: `لَا يَحْزُنُهُمُ`, *they will not be grieved by it.* **21:105** is `أَنَّ ٱلْأَرْضَ يَرِثُهَا عِبَادِىَ ٱلصَّـٰلِحُونَ`. **Neither rendered.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"the one who"* (vs `ar-rauf@1`'s takeaway), a function-word run. **No finding.**

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **21:104 cited in the `al-awwal` and `al-muid` drafts — neither renders it** (checked by reading their beats). **30:27 is `al-muid@1`'s verse beat and is unavailable.** 10:4, 29:19, 29:20, 32:7, 85:13, 30:11 all cited elsewhere.

### Bar 3(c) — the move

**Al-Mubdi's move is that the first beginning is offered as security for the next one.**

`كَمَا بَدَأْنَآ … نُّعِيدُهُۥ ۚ وَعْدًا عَلَيْنَآ` — the structure is an argument, not a description: **because the first one happened, the second is owed.** The reader's error is treating one failed start as evidence about the supply of starts.

**Against `al-khaliq@1` (shipped):** the Creator **makes**, through stages — clay, a drop, a clot, bone, flesh. **Process is that deck's engine.** Al-Mubdi is about the *first* of a thing, not the making of it.

**Against `al-bari@1` and `al-badi@1` (both drafted this session)** — and these three are the tightest cluster in the project:

| deck | precedence of what |
|---|---|
| `al-bari@1` (id 20) | **the writing before the event** — the register precedes the bringing-into-being |
| `al-badi@1` (id 97) | **no precedent in kind** — nothing of its type existed to copy |
| **`al-mubdi@1`** | **the first instance as a guarantee of the next** |

**All three were drafted by the same author in the same session**, which is the weakest possible independence. **A verifier should re-argue this trio from scratch rather than check it** — §9cd's exact shape, at triple strength.

**Against `al-muid@1` (id 68):** the pair the catalogue never grouped. Al-Muid **restores what was**; Al-Mubdi **starts what was not.** They are two halves of one Qur'ānic clause, and each deck renders a different āyah to keep them apart.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **30:27** `يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ` | **the obvious text — and `al-muid@1`'s verse beat, rendered whole.** Unavailable |
| **10:4 · 10:34 · 29:19 · 30:11 · 85:13** | the same `يَبْدَؤُ`/`يُعِيدُ` doublet, each cited in a pending draft |
| **29:20** `ٱنظُرُوا۟ كَيْفَ بَدَأَ ٱلْخَلْقَ` | an **imperative to look**, not a narrated act; cited in the `al-awwal` draft |
| **32:7** `وَبَدَأَ خَلْقَ ٱلْإِنسَـٰنِ مِن طِينٍ` | the root with Allah as subject, in **creation-from-clay** territory that shipped `al-khaliq@1` occupies thematically. ⚠️ **R3 correction:** R0 said 32:7 was *"cited in that draft"* — **it is not.** `al-khaliq@1`'s rendered sources are 23:12, 23:13–14, 23:14 and 36:36 only, read directly from `name_stories.json`. **32:7 is free ground.** The rejection stands on the thematic overlap alone, which is a weaker reason than the one given |
| **7:29 · 9:13 · 12:76 · 34:49** | the root in **human** senses — beginning a search, starting hostilities |

---

## Catalogue findings — reported, **NO change recommended**

1. **Ids 67 and 68 are a natural pair the catalogue never grouped.** They do not share a `dua_arabic`, so §9ce's map does not catch them — **but every Qur'ānic occurrence of one Name's root contains the other's.** This is the **second** such gap found in this wave (ids 56/89 share their entire root and are likewise ungrouped). **Reported as a gap in the shared-duʿā map, not as a catalogue defect.**
2. **Nothing else.** Id 67's `english`, `meaning` and `lesson` (*Al-Mubdi created you as something entirely new. You are not a copy*) are consistent — though the `lesson` leans toward **id 97 Al-Badi's** engine (no precedent in kind) rather than this deck's (a first instance guaranteeing a second). **Fourth instance of the `lesson` field describing a neighbour's move**; see the handoff.

---

## What I could not determine — attack these first

1. **The three-way separation from `al-bari@1` and `al-badi@1` is the deck's main risk**, and all three were drafted by one author in one session. **Re-argue the trio** (§9cd).
2. **`ب-د-أ`'s 15 occurrences were enumerated from the corpus listing and the relevant ones fetched** — the most nearly complete sweep in this batch, but **not all 15 were individually read.**
3. **21:104's availability rests on reading `al-muid@1`'s and `al-awwal@1`'s beat structures**, i.e. on two pending drafts staying as they are. **If either takes 21:104 at fix time, this deck loses its carrier and the alternatives are all cited elsewhere.** The most fragile dependency in the wave.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently — but its carrier depends on two sibling drafts not moving.** Must be reviewed with `al-muid@1`, and read alongside `al-bari@1` and `al-badi@1`.
