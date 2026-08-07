# Deck Draft — Malik-ul-Mulk (catalogue id 88) — **R0, awaiting independent blind verification**

> ⚠️ **The compound Name occurs once in the Qurʾān — 3:26 — and it is doubly spent.** Shipped **`al-malik@1` renders 3:26 as its verse beat *and* as its duʿā.**
>
> ⚠️ **Worse: `al-malik@1`'s duʿā already contains this Name in full.** Its locked string is `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ` — **a strict prefix of id 88's own duʿā.** The fourth case this wave of a shipped deck spending an unstarted Name's ground. See the bars note.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/88.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `malik-ul-mulk@1` — Malik-ul-Mulk

**Why this deck exists, in one line:** the user with a grip on something they are afraid to lose, whose fear has quietly become the way they hold it.

**The reader's position:** **an owner who suspects they are not one.**

**Proposed metadata**

```json
{
  "deck_id": "malik-ul-mulk@1",
  "name_id": 88,
  "transliteration": "Malik-ul-Mulk",
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
> Everything you call yours arrived, and will leave. That is not a threat being made to you. It is how the ownership was always arranged.

**Beat 2 · name_intro** *(catalogue id 88 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> مَالِكُ الْمُلْكِ — Malik-ul-Mulk — Owner of Sovereignty

**Beats 3–5 · story — "Everything Named Is Doing Something"** *(Qur'an 64:1)*:
> 3. Allah opens the sūrah: "Whatever is in the heavens and whatever is on the earth is exalting Allah."
> 4. Every single thing named there is doing something — exalting, running, existing. Not one of them is described as owning anything.
> 5. The owning is stated separately, in its own clause, with one holder. Your grip on what you have is real. It is also a loan you are administering.

**Beat 6 · verse** *(partial quotation — the ownership clause only, visible ellipsis)*:
> …To Him belongs dominion… — Qur'an 64:1

**Beat 7 · duʿā** *(catalogue id 88, **byte-for-byte**, asserted programmatically (§9cb))*:
> اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ
> *Allahumma Malikal-Mulk, tu'til-mulka man tasha' wa tanzi'ul-mulka mimman tasha'*
> "O Owner of Sovereignty, You give sovereignty to whom You will and take it from whom You will. Teach me that nothing I hold is truly mine."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Malik is the King — the One who rules. Malik-ul-Mulk is narrower: not the ruler of a kingdom but the owner of kingship itself, including whatever share of it you are currently holding and afraid to lose.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Name the thing you are most afraid of losing. On whose account is it actually held?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Whatever is in the heavens and whatever is on the earth is exalting Allah."* (beats 3–4) | `.../64:1` | ✅ `يُسَبِّحُ لِلَّهِ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ` — first clause |
| 2 | *"…To Him belongs dominion…"* (beats 5–6, **bar-1 and bar-4 carrier**) | `.../64:1` | ✅ `لَهُ ٱلْمُلْكُ` — the ownership clause only. **`وَلَهُ ٱلْحَمْدُ` left for `al-hameed@1` (id 65)**; `وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ` left for `al-qadir@1` |
| 3 | Successor sweep n+1: 64:2 | `.../64:2` | ✅ believer and disbeliever named, **no punishment**; closes `وَٱللَّهُ بِمَا تَعْمَلُونَ بَصِيرٌ`. **64:1 is sūrah-opening**, so no n−1 |
| 4 | Cross-check: what `al-malik@1` renders | `assets/content/name_stories.json` | ⚠️ **3:26 as verse beat AND duʿā**, and its duʿā string `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ` is **a strict prefix of id 88's** |
| 5 | The locked duʿā | `collectible_names.json` id 88 | ✅ three fields asserted present (§9cb). ⚠️ **superset of a shipped deck's duʿā** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **64:1** — Allah's own voice; `لَهُ ٱلْمُلْكُ` states the ownership as a fact about Him, set against a sūrah-opening list of everything that merely *does* | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **builds a contrast structurally** — everything in the heavens and the earth is described **exalting**, an activity; only He is described **owning**. The sovereignty is shown by what everything else is not | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS on the beats — the duʿā collides with production by construction** |
| 4 | Root in the quoted text | ⚠️ **partial.** `م-ل-ك` is met as `ٱلْمُلْكُ` — **but the compound Name `مَـٰلِكَ ٱلْمُلْكِ` is not in the rendered text**, because its only occurrence is spent | ⚠️ **PASS on the root, TRADED on the compound** |
| 5 | Register and reverence | ✅ 64:1 is **sūrah-opening** (no n−1 within the sūrah); 64:2 names believer and disbeliever with **no punishment**, closing `وَٱللَّهُ بِمَا تَعْمَلُونَ بَصِيرٌ` | ✅ **PASS** |

**The double collision with production, stated at full strength.**

**(i) 3:26 is unavailable.** `قُلِ ٱللَّهُمَّ مَـٰلِكَ ٱلْمُلْكِ` is **the compound Name's only Qurʾānic occurrence**, and shipped `al-malik@1` renders it **twice** — as its verse beat and as its duʿā. It is also `قُلْ`-instructed, so it could not have carried bar 1 here in any case (§9bk).

**(ii) `al-malik@1`'s duʿā *is* this Name.** Its locked string reads `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ` — *"O Allah, Owner of Sovereignty, You give sovereignty to whom You will."* **Id 88's duʿā is that same sentence plus `وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ`** (*"and take it from whom You will"*). **A strict prefix.** So a bar-3(b) sweep of this deck's duʿā beat against production returns **the whole of the shorter string**, and **the shipped deck's duʿā already speaks id 88's Name aloud.**

**This is the fourth instance this wave** — with `al-baseer@1` spending Ash-Shaheed's root, `al-haleem@1` spending As-Sabur's only ṣaḥīḥ carrier, and `as-salam@1` rendering Dhul-Jalali wal-Ikram in full. **All four are catalogue-locked, none was catchable before shipping, and all four are disclosed rather than engineered around** (§9ce, §9bl).

**What the deck does with it.** It takes the half `al-malik@1`'s duʿā does **not** contain — **`وَتَنْزِعُ`, the taking away** — as the reader's actual problem, and builds the takeaway on ownership rather than on rule. **64:1 is chosen precisely because it is not 3:26**: no `قُلْ`, no giving-and-taking, just the bare statement of who owns, set against a list of everything that only acts.

**Bar 5** is clean: 64:1 opens Sūrat at-Taghābun, so there is no n−1 within the sūrah, and 64:2 carries no punishment.

**One clause deliberately left.** 64:1 continues `وَلَهُ ٱلْحَمْدُ` — **`al-hameed@1`'s (id 65) ground, drafted this session on 34:1.** The beat stops before it, with a visible ellipsis.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"of them is"* (vs `al-kareem@1`'s story), a function-word run. An earlier revision measured **5** against `allah@1`'s takeaway (*"a description of the"*) and beat 1 was rewritten. **On the duʿā beat the run is the entire shipped string** — see the bars note.

**Every āyah checked against the shipped asset *and* all 48 pending drafts**, two-sided boundary match: **64:1 free.** **3:26 SPENT twice over** by `al-malik@1`. **67:1** (`بِيَدِهِ ٱلْمُلْكُ`) is cited in the `al-malik` draft. 64:2 and 64:3 are cited in the `al-khaliq` and `al-musawwir` drafts and are **not rendered here**.

### Bar 3(c) — the move

**Malik-ul-Mulk's move is ownership, not rule.**

`al-malik@1` is **the King** — the One who governs a kingdom. **This Name is the owner of kingship itself**, which is a narrower and stranger claim: not that He rules the realm, but that **the very capacity to hold anything is His property**, including whatever share of it the reader currently has.

**64:1 shows that by grammar.** Everything in the heavens and the earth gets a verb — `يُسَبِّحُ`, exalting. **Only Allah gets a possession.** Nothing in the entire list is described as owning any part of itself.

**Against `al-malik@1` (shipped):** rule versus title-deed. That deck's takeaway is about what is *in the hand* that gives and takes — *"and the word is not 'power'. It is 'good'."* **This deck is about whose name is on the thing at all.**

**Against `al-ghaniyy@1` (drafted):** self-sufficiency — He needs nothing. **Ownership is a different claim from independence**: this deck says the reader's holdings are on loan, not that Allah lacks want of them.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **3:26** `قُلِ ٱللَّهُمَّ مَـٰلِكَ ٱلْمُلْكِ` | **the compound Name's only occurrence — and doubly spent** by shipped `al-malik@1` (verse beat *and* duʿā). Also `قُلْ`-instructed (§9bk) |
| **67:1** `تَبَـٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ` | free of rendering but **cited in the `al-malik` draft**, and it is that Name's territory |
| **1:4** `مَـٰلِكِ يَوْمِ ٱلدِّينِ` | the participle, but bound to **the Day of Recompense** — Judgment framing, and the Fātiḥah's opening is the most-rendered text in the religion |
| **64:1's `وَلَهُ ٱلْحَمْدُ`** | **left for `al-hameed@1`** (id 65). The beat stops before it |
| **64:1's `وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ`** | **`al-qadir@1`'s** Name. Not rendered |

---

## Catalogue findings — reported, **NO change recommended**

1. **A shipped deck's duʿā contains this Name in full**, and id 88's duʿā is a strict superset of it (see the bars note). **Reported, not actioned** — both strings are locked and `al-malik@1`'s is correct for it. **Fourth instance this wave of production spending an unstarted Name's ground.**
2. **Id 88's `dua_translation` carries an authored final sentence** — *"Teach me that nothing I hold is truly mine"* — which has no counterpart in the Arabic (`اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ`). **The Arabic is 3:26's clause; the English adds a petition that is not in it.** Reported as a translation-scope observation, **not actioned** — it is locked, and it happens to state this deck's engine exactly.

---

## What I could not determine — attack these first

1. **Bar 4 is met on the root but traded on the compound.** The Name is `مَـٰلِكَ ٱلْمُلْكِ`, a construct, and that construct appears in no rendered beat. **If a verifier requires the compound, this Name has no route** — its one occurrence is spent twice over in production.
2. **The duʿā collision is unresolvable at draft level** and is against a shipped deck.
3. **`م-ل-ك` has 206 occurrences in 10 forms and was not swept** — it is overwhelmingly `al-malik@1`'s ground, and the compound form was located directly. **Incomplete by design, stated as such.**
4. **The `al-malik@1` separation** — rule versus ownership — is argued, not measured, and is the deck's reason for existing (§9cd).
5. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Must be reviewed with shipped `al-malik@1`.** They share a Name-phrase, a duʿā prefix and a root; a reviewer seeing only this deck cannot judge whether the pair is one deck too many.
