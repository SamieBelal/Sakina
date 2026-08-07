# Deck Draft — Al-Baith (catalogue id 59) — **R0, awaiting independent blind verification**

**No shared duʿā.** An independent single. **Its duʿā shares the phrase *revive my heart* with shipped id 69's** — flagged in the handoff before drafting and handled below.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/59.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-baith@1` — Al-Baith

**Why this deck exists, in one line:** the user who has already written some part of themselves off — a capacity, a relationship, a version of their faith — and is no longer asking for it back.

**The reader's position:** **past salvaging**, by their own assessment.

**Proposed metadata**

```json
{
  "deck_id": "al-baith@1",
  "name_id": 59,
  "transliteration": "Al-Baith",
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
> Some part of you has already been written off, and you are the one who wrote it off.

**Beat 2 · name_intro** *(catalogue id 59 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْبَاعِثُ — Al-Baith — The Resurrector

**Beats 3–5 · story — "Revived, and Then Told Why"** *(Qur'an 2:55–56)*:
> 3. A people demanded to see Allah outright, and a thunderbolt took them while they were looking on.
> 4. Then Allah says: "Then We revived you after your death…"
> 5. "…that perhaps you would be grateful." Not as a reward for having repented. The reviving comes first, and the gratitude is what it is for.

**Beat 6 · verse** *(partial quotation — the closing clause, visible ellipsis)*:
> …and that Allah will resurrect those in the graves. — Qur'an 22:7

**Beat 7 · duʿā** *(catalogue id 59, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا بَاعِثُ أَحْيِ قَلْبِي كَمَا تُحْيِي الْأَرْضَ الْمَيْتَةَ بِالْمَطَرِ
> *Ya Ba'ith, ahyi qalbi kama tuhyil-ardal-mayyitata bil-matar*
> "O Resurrector, revive my heart as You revive the dead earth with rain."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Muhyi gives life. Al-Baith raises what was already gone — and the difference is that nothing has to be salvageable first. The verse never says they deserved it. It says We revived you, and then it says what for.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you already buried — not because it died, but because you decided it had?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"…we will never believe you until we see Allah outright’; so the thunderbolt took you while you were looking on"* (beat 3) | `.../2:55` | ✅ `فَأَخَذَتْكُمُ ٱلصَّـٰعِقَةُ وَأَنتُمْ تَنظُرُونَ` — **rendered deliberately.** See the bars note |
| 2 | *"Then We revived you after your death that perhaps you would be grateful."* (beats 4–5, **bar-1 and bar-4 carrier**) | `.../2:56` | ✅ `ثُمَّ بَعَثْنَـٰكُم مِّنۢ بَعْدِ مَوْتِكُمْ لَعَلَّكُمْ تَشْكُرُونَ` — **whole āyah** |
| 3 | *"…and that Allah will resurrect those in the graves."* (beat 6) | `.../22:7` | ✅ `وَأَنَّ ٱللَّهَ يَبْعَثُ مَن فِى ٱلْقُبُورِ` — closing clause only |
| 4 | Successor sweep n+1: 2:57 | `.../2:57` | ✅ **provision** — clouds for shade, manna and quails |
| 5 | Successor sweep n+1 of the verse beat: 22:8 | `.../22:8` | ⚠️ disputation about Allah without knowledge. **No punishment.** Not rendered |
| 5b | Successor sweep n−1 of the verse beat: **22:6** ⚠️ **R3 — never fetched at R0**, an undocumented gap on the verse beat's own predecessor | `.../22:6` | ✅ `ذَٰلِكَ بِأَنَّ ٱللَّهَ هُوَ ٱلْحَقُّ وَأَنَّهُۥ يُحْىِ ٱلْمَوْتَىٰ` — **clean, no punishment.** Note it carries **`al-muhyi@1`'s root** (`يُحْىِ`) and shipped **`al-haqq@1`'s** word — **rendered on no beat here**, which is why the gap was benign |
| 6 | Root sweep | `corpus…?q=bEv` | ✅ **67 occurrences, 5 forms**; 52× form I, **most of them *sending messengers*** rather than raising the dead |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **2:56** `ثُمَّ بَعَثْنَـٰكُم مِّنۢ بَعْدِ مَوْتِكُمْ` — first-person plural, Allah the subject, a **completed act** rather than a future promise | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **narrates a sequence with an unearned middle** — they demanded, they died, *then We revived you* — and states the purpose afterward. The raising is shown happening before any repentance is mentioned | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ب-ع-ث` as `بَعَثْنَـٰكُم` (2:56) and `يَبْعَثُ` (22:7) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **n−1 (2:55) is the thunderbolt** — `فَأَخَذَتْكُمُ ٱلصَّـٰعِقَةُ`; n+1 (2:57) is manna and quails, clean | ⚠️ **PASS — and the predecessor IS rendered, deliberately** |

**This deck does something no other deck in the wave does: it renders its own bar-5 hazard, on purpose.** Beat 3 is 2:55 — the demand to see Allah outright, and the thunderbolt. **That is a strike, and it is on screen.**

**The argument for it, so a verifier can attack it directly.** Bar 5 forbids rebuke *of the reader* and Fire/Judgment adjacency. 2:55 is neither: it is a **completed historical event** with a named third party, it carries no `عَذَاب` and no Fire, and — decisively — **the deck exists because of what happens next.** Without the death in beat 3, beat 4's *"Then We revived you"* has nothing to revive. **A reviving story that omits the dying is not a reviving story.**

**What the deck does not do:** it never applies the strike to the reader, never moralises it, and never names what those people had done beyond the demand itself. **2:57 — manna, quails, and shade — is the clean successor**, and the passage's own next move is provision.

**If a verifier rules that no beat may render a strike, this deck has to move to 22:7** — which is available (it is the verse beat) but is a **Judgment-Day statement**, so the register problem would get worse, not better. **That trade-off is the thing to weigh.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"it says what"* (vs `al-malik@1`'s takeaway), a function-word run. **No finding.**

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **2:55 · 2:56 · 2:57 free · 22:7 free.** Checked and left: **2:259** (the man and the donkey) cited in **four** pending drafts including `al-qadir` and `al-hayy`; **6:36** free and available.

### Bar 3(c) — the move

**Al-Baith's move is that nothing has to be salvageable first.**

`مِنۢ بَعْدِ مَوْتِكُمْ` — *after your death*. **The condition of the thing being raised is total, and it is stated.** And the purpose clause comes **after**: `لَعَلَّكُمْ تَشْكُرُونَ`, *that perhaps you would be grateful* — so gratitude is what the reviving is **for**, not what it was **conditional on**. For a reader who has written something off, that ordering is the whole consolation.

**Against `al-muhyi@1` (drafted, id 62):** Al-Muhyi **gives life** — 30:48–50, rain on dead earth, a continuing natural process. **Al-Baith raises what is already gone**, as a discrete act on a specific occasion, to specific people who had just been struck down. Process versus event; ongoing versus once.

**Against `al-mumeet@1` (drafted, id 63):** the counterpart Name. This deck renders the dying only as the setup and never as the subject.

**Against `at-tawwab@1` (shipped):** the risk is that *raising the spiritually dead* becomes repentance-acceptance. **The deck avoids it by keeping 2:56 literal** — the people in the āyah were physically dead — and letting the reader do the transfer themselves in beat 9.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **2:259** (the man who passed a ruined town, dead a hundred years) | the most vivid `ب-ع-ث` narrative in the Qur'ān — **cited in four pending drafts** (`al-qadir`, `al-hayy`, `al-muhyi`, `al-mutakabbir`), and it closes `أَنَّ ٱللَّهَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ` — **`al-qadir@1`'s Name.** Left |
| **6:36** `وَٱلْمَوْتَىٰ يَبْعَثُهُمُ ٱللَّهُ` | free, clean, and a genuine alternative — but it is a **statement**, not a narration, so bar 2 would be weaker. **Left available** |
| **22:7 as the bar-1 carrier** | a Judgment-Day statement. Used as the verse beat, where it needn't carry bar 1 |
| **The remaining 52 form-I occurrences** | overwhelmingly *sending messengers* (`بَعَثَ رَسُولًا`) rather than raising the dead — a different sense of the root |

---

## Catalogue findings — reported, **NO change recommended**

1. **Id 59's duʿā shares *revive my heart* with shipped id 69's** — flagged in the handoff before this deck was drafted. **Measured: the two duʿā strings are not identical** (id 59's is `يَا بَاعِثُ أَحْيِ قَلْبِي كَمَا تُحْيِي ٱلْأَرْضَ ٱلْمَيْتَةَ بِٱلْمَطَرِ`), so this is **not** a §9ce shared-duʿā group — it is a shared **image**. Reported; **no change recommended**.
2. **Id 59's `english` is *The Resurrector*** and its `lesson` names both senses — reviving a dead heart *and* raising the dead on the Last Day. **The deck takes the second literally and lets the first be the reader's inference**, which is the opposite of the usual order. Noted as an interpretive choice.

---

## What I could not determine — attack these first

1. **Rendering 2:55's thunderbolt is the deck's load-bearing decision.** Argued above. **Attack this first.**
2. **`ب-ع-ث`'s 67 occurrences were not exhaustively fetched** (§9cc) — the form breakdown was read and the raising-the-dead sense separated from the sending-messengers sense by inspection of the corpus listing, **not by reading all 52 form-I occurrences.**
3. **The `at-tawwab@1` risk** — that this becomes a repentance deck — is held off by keeping 2:56 literal. Thin; re-argue (§9cd).
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Read alongside `al-muhyi@1` and `al-mumeet@1`.
