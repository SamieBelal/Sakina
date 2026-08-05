# Deck Draft — Al-Muhsi (catalogue id 66) — **R0, awaiting independent blind verification**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cb. Protocol: [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md).
Claim filed at `.context/claims/66.md` **before drafting** — see that file for a real limit on the claims check.

All scripture live-fetched at draft time: `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International), `corpus.quran.com/qurandictionary.jsp?q=HSy`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-muhsi@1` — Al-Muhsi

**Why this deck exists, in one line:** the user who did something today that nobody saw and nobody will thank them for, and has quietly concluded it therefore did not count.

**Selection ran duʿā-first, and the duʿā turned out to be the whole design problem.** Id 66's locked duʿā is:

> *"O Counter, **do not hold me fully accountable for what You have recorded against me**, and pardon me with Your mercy."*

**That is an accountability plea, and it points the opposite way from the catalogue's own `lesson` field** — *"Al-Muhsi has numbered every tear you have shed. None are forgotten."* One is comfort; the other names a record kept *against* the reader, on a screen that renders at 11pm to someone in distress (bar 5: no accusation of the reader). **Neither can be changed; both are locked or catalogue-fixed.**

**The deck's whole structure is the resolution of that tension**, and it is structural rather than rhetorical: the deck arrives at the duʿā **already inside mercy**, because the verse beat immediately before it is 16:18 — which carries the root *and* closes `إِنَّ ٱللَّهَ لَغَفُورٌ رَّحِيمٌ`. So the reader does not meet "recorded against me" cold. They meet it one line after "Forgiving and Merciful," and one line after being told that the favours running the *other* way are past their own ability to count. **The plea then reads as daring rather than dread** — which is what a duʿā is.

**The register decision, made first.** No beat tells the reader what is on their record. The deck asserts only that the record is *itemised* and that it runs in **both** directions. The word "sin" does not appear on any beat. The single reference to fault is the reader's own, in the duʿā, in their own mouth.

**Proposed metadata**

```json
{
  "deck_id": "al-muhsi@1",
  "name_id": 66,
  "transliteration": "Al-Muhsi",
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
> Most of what you did today will not be remembered by anyone, including you. It was still counted.

**Beat 2 · name_intro** *(catalogue id 66 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُحْصِي — Al-Muhsi — The Counter

**Beats 3–5 · story — "A Clear Register"** *(Qur'an 36:12)*:
> 3. Allah says: "Indeed, it is We who bring the dead to life and record what they have put forth and what they left behind…"
> 4. "…and all things We have enumerated in a clear register." Not summarised. Not weighed into a total. **Enumerated** — each thing kept as its own item, on its own line.
> 5. Read what is on that list: not only what they put forth, but their **traces** — what their doing set in motion after they had stopped watching it. You do not have to have seen the effect for it to be entered.

**Beat 6 · verse** *(whole āyah, no truncation)*:
> And if you should count the favors of Allāh, you could not enumerate them. Indeed, Allāh is Forgiving and Merciful. — Qur'an 16:18

**Beat 7 · duʿā** *(catalogue id 66, **byte-for-byte**; asserted programmatically against `collectible_names.json`, §9cb)*:
> يَا مُحْصِي لَا تُحَاسِبْنِي بِمَا أَحْصَيْتَهُ عَلَيَّ وَاعْفُ عَنِّي بِرَحْمَتِكَ
> *Ya Muhsi, la tuhasibni bima ahsaytahu 'alayya wa'fu 'anni birahmatik*
> "O Counter, do not hold me fully accountable for what You have recorded against me, and pardon me with Your mercy."

**Beat 8 · takeaway** *(fixed, **not** personalised — this is where bar 3(c) lands)*:
> Ar-Raqeeb watches, Ash-Shaheed testifies, Al-Aleem knows, Al-Ghafur covers. Al-Muhsi does something narrower than any of them: He **itemises**. Nothing is rounded off or absorbed into a total — in either direction. That is why this Name's duʿā does not ask for an audit. It asks for mercy on a list you already know is complete.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What did you do today that no one will ever thank you for? It has already been entered. Sit with that before you decide the day was wasted.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched) | Grading | Status |
|---|---|---|---|---|
| 1 | "Indeed, it is We who bring the dead to life and record what they have put forth and what they left behind… and all things We have enumerated in a clear register" (beats 3–4 — **the bar-1 and bar-4 carrier**) | `api.quran.com/api/v4/verses/by_key/36:12` | Qur'an (Uthmani verified live) | ✅ `إِنَّا نَحْنُ نُحْىِ ٱلْمَوْتَىٰ وَنَكْتُبُ مَا قَدَّمُوا۟ وَءَاثَـٰرَهُمْ ۚ وَكُلَّ شَىْءٍ أَحْصَيْنَـٰهُ فِىٓ إِمَامٍ مُّبِينٍ` — **whole āyah, split across two beats at the āyah's own `ۚ` pause.** Nothing elided |
| 2 | "And if you should count the favors of Allāh, you could not enumerate them. Indeed, Allāh is Forgiving and Merciful." (beat 6) | `…/16:18` | Qur'an | ✅ `وَإِن تَعُدُّوا۟ نِعْمَةَ ٱللَّهِ لَا تُحْصُوهَآ ۗ إِنَّ ٱللَّهَ لَغَفُورٌ رَّحِيمٌ` — **whole āyah, no ellipsis.** Root present as `تُحْصُوهَآ` |
| 3 | Successor sweep, n−1 of the carrier: 36:11 | `…/36:11` | Qur'an | ✅ *"So give him good tidings of **forgiveness and noble reward**."* Not merely clean — the predecessor is itself good news. Not quoted |
| 4 | Successor sweep, n+1 of the carrier: 36:13 | `…/36:13` | Qur'an | ✅ *"And present to them an example: the people of the city…"* — opens a parable, no punishment in the āyah. **Not quoted — and it is `al-azeez@1`'s ground**, see bar 3(a) |
| 5 | Successor sweep, n−1 of the verse beat: 16:17 | `…/16:17` | Qur'an | ✅ *"Then is He who creates like one who does not create?"* — rhetorical question, no punishment. Not quoted |
| 6 | Successor sweep, n+1 of the verse beat: 16:19 | `…/16:19` | Qur'an | ✅ *"And Allāh knows what you conceal and what you declare."* No punishment. Not quoted |
| 7 | The locked duʿā (beat 7) | `assets/content/collectible_names.json` id 66 | catalogue-locked, **not scripture** | ✅ all three fields asserted as substrings of this file (§9cb check). **No ḥadīth or āyah is claimed for it** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | 36:12 `أَحْصَيْنَـٰهُ` — form IV verb, **first-person plural, in an āyah that opens `إِنَّا نَحْنُ`** ("Indeed, it is We"). Top rung of the §9bk ladder, and about as unambiguous as the ladder gets | ✅ **PASS** |
| 2 | Shown, not stated | The āyah does not say "Allah counts." It **performs the count's scope** — three distinct items enumerated (`مَا قَدَّمُوا۟`, `ءَاثَـٰرَهُمْ`, `كُلَّ شَىْءٍ`), each named separately rather than summed | ✅ **PASS** |
| 3 | No sibling-Name collapse | three surfaces, all measured below | ⚠️ **PASS — but this is the deck's hard bar.** See surface (c) |
| 4 | Root in the quoted text | `ح-ص-ي` in **both** rendered scripture beats: `أَحْصَيْنَـٰهُ` (36:12) and `تُحْصُوهَآ` (16:18) | ✅ **PASS, no trade** |
| 5 | Register and reverence | both successor sweeps clean **in all four directions**; no rebuke, no Fire, no Judgment scene rendered or adjacent | ✅ **PASS — and unusually cleanly** |

**On bar 5, stated as a measurement rather than an adjective (§9ak).** Four neighbours fetched, four clean, and one of them (36:11) is *good tidings of forgiveness*. **This is the first deck in this wave whose bar-5 sweep required no truncation and produced no finding.** For contrast, the same sweep on `al-bari@1` found a rebuke one clause after the last rendered word. The difference is not luck — it is that this Name's strongest carrier happens to sit in a consolation passage, and the alternatives that sit in Judgment passages were rejected for exactly that reason (see the sweep table).

---

### Bar 3, surface (a) — Arabic roots, and one adjacency that must be disclosed

| beat | roots present | note |
|---|---|---|
| 3–4 (36:12) | `ح-ص-ي` (`أَحْصَيْنَـٰهُ`) · `ح-ي-ي` (`نُحْىِ`) · `ك-ت-ب` (`نَكْتُبُ`) · `ق-د-م` (`قَدَّمُوا۟`) · `أ-ث-ر` (`ءَاثَـٰرَهُمْ`) | **`نُحْىِ` is `al-muhyi@1`'s root** (`ح-ي-ي`, id 62, drafted). See below |
| 6 (16:18) | `ح-ص-ي` (`تُحْصُوهَآ`) · `ع-د-د` (`تَعُدُّوا۟`) · `ن-ع-م` · `غ-ف-ر` · `ر-ح-م` | `غ-ف-ر`/`ر-ح-م` are `al-ghafur@1`/`ar-raheem@1`'s roots, in a fixed Qurʾānic closing formula |
| 7 (duʿā) | `ح-ص-ي` (`أَحْصَيْتَهُ`) | **the locked duʿā carries the Name's own root** — worth noting, it is not common |

**Two disclosures, both checked rather than inferred:**

1. **36:12 opens with `نُحْىِ ٱلْمَوْتَىٰ` — "We bring the dead to life" — which is Al-Muhyi's root and subject, and this deck renders that clause.** It is the first half of the carrier āyah; cutting it leaves the sentence ungrammatical.

   **A pending-draft sweep found something a shipped-asset sweep cannot, and it is a real disclosure against this deck.** `2026-08-03-al-azeez-DRAFT.md` cites 36:12 as its own n−1 successor and records: *"Clean; **carries `ḥ-y-y`, held free for Al-Muhyi** — off-screen, quoted nowhere."* **That drafter deliberately reserved this clause.** Al-Muhyi's draft then did not take it — it rests on **30:48–50 and 41:39** (grepped: zero 36:12 hits) — so the reservation lapsed unclaimed, and **this deck has now spent ground another drafter set aside.**

   **Measured consequence: none.** Max shared word-run against 68 rendered strings extracted from the Al-Muhyi draft is **2** (*"the dead"*). No rendered text is shared, and the reserved root is carried in a clause this deck needs for grammar, not for its argument.

   **Recorded anyway, because the mechanism is the finding.** `.context/claims/` was empty (gitignored, fresh workspace), so the reservation existed only inside a sibling draft where no claim check would look. A verifier should decide whether the lapse is acceptable or whether beat 3 should open at `وَنَكْتُبُ` instead — **which is possible**: dropping `إِنَّا نَحْنُ نُحْىِ ٱلْمَوْتَىٰ` costs the beat its `إِنَّا نَحْنُ` emphasis but **not** bar 1, since `أَحْصَيْنَـٰهُ` is itself first-person plural. **That is the cheapest available fix and it is left as the verifier's call, not taken unilaterally.**
2. **36:13 is `al-azeez@1`'s ground** — that shipped deck runs three story beats on 36:13–14. This deck renders **36:12 only**, its immediate predecessor. Adjacent āyāt, disjoint rendered text: the `al-malik@1`/`al-muizz@1`/`al-muzill@1` precedent on 3:26. Disclosed, per §9bo, because adjacency is a disclosure and not a disqualification — what disqualifies is rendering the neighbour's clause, which this deck does not.

### Bar 3, surface (b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat run against every `primary` and `translation`, maximum shared word-run by dynamic programming. **Every hit ≥3 words — there are no hits above 3:**

| n | this beat | collides with | shared run |
|---|---|---|---|
| 3 | 6 (verse) | `al-ghafur@1` verse | "forgiving and merciful" |
| 3 | 8 (takeaway) | `al-haleem@1` bridge | "you already know" |
| 3 | 3 (story) | `al-haqq@1` verse · `al-haleem@1` verse | "and what they" · "what they have" |
| 3 | 1 (bridge) | `al-malik@1` · `al-quddus@1` · `al-haleem@1` bridges | "most of what" · "of what you" · "what you did" |
| 3 | 8 | `ar-raqeeb@1` bridge · `ar-rafi@1` story · `al-afuw@1` story | "for this name" · "of them he" · "it asks for" |

**Maximum shared word-run across the whole deck: 3.** Every one is a function-word run except **"forgiving and merciful"**, which is Saheeh's standard rendering of `غَفُورٌ رَّحِيمٌ` — a fixed Qurʾānic formula, here in 16:18 against `al-ghafur@1`'s 4:110. **Different āyāt, same formula. §9bl: scripture does not yield to a rendered-string collision, and translation-shopping to dodge it is banned.**

**Engine vocabulary, swept across all 45:** `enumerate`/`enumerated` **0** · `register` **0** · `traces` **0** · `left behind` **0** · `put forth` **0** · `tear` **0** · `numbered` **0** · `ledger` **0** · `favours`/`favors` **1** (`al-wakeel@1` story). **The engine vocabulary is unspent.** `count` appears 8 times across the asset but never as a divine act of enumeration — the closest, `al-baqi@1`'s takeaway ("She counted what they still had"), is a *human* counting and its engine is what lasts, not what is recorded.

### Bar 3, surface (c) — the move. **This deck's hard bar.**

**No mechanical pass reaches this surface** — and here that is not a formality, because the nearest neighbour is one a token sweep *cannot* find. Al-Muhsi sits inside a large family:

| deck | its move |
|---|---|
| `ar-raqeeb@1` (shipped) | **being observed.** The watchers went up and gave their report, and the report was that they were praying |
| `al-aleem@1` (shipped) | **knowledge preceding evidence.** "He already knew what she had delivered — before anything had proved it" |
| `al-lateef@1` (shipped) | **what you could not say was never unsaid to Him** |
| **`al-ghafur@1` (shipped)** | **the record is shown privately, then covered.** The najwā ḥadīth: every sin named once, to the One who already knew, then *"today I forgive them for you"* |
| 60 Ash-Shaheed (unstarted) | witnessing / testifying |
| 39 Al-Hafeez (unstarted) | preserving, guarding |

**`al-ghafur@1` is the dangerous one, and no measurement found it.** Its max shared word-run with this deck is **3**, on a Qurʾānic formula. But its *engine* — a complete private record, presented to a person, met with mercy — is within a hair of what this deck's duʿā asks for. **A sweep that stopped at surface (b) would have graded this deck clean and missed the only real collision in it.** That is the whole reason surface (c) exists, and this is the clearest instance of it in the wave.

**The separation, and it is testable rather than asserted:**

- **`al-ghafur@1` is about what happens *to* the record** — it is screened, then erased. Its takeaway: *"Al-Ghafur is not only the forgiving — it is the covering."* The record's fate is the point.
- **`al-muhsi@1` is about the record being *itemised at all*, and about which direction it runs in.** Nothing is rounded off, averaged, or absorbed into a total — and that cuts *both ways*: the fault is on it, and so is the thing nobody thanked you for. The deck never says the record is erased. That is Al-Ghafur's beat, not this one's, and this deck deliberately does not take it.

**Against the watching family**, the distinction is narrower still and it is the word *itemise*: Ar-Raqeeb **watches**, Ash-Shaheed **testifies**, Al-Aleem **knows** — all three are relations to the *content*. Al-Muhsi is a relation to the **granularity**. You can know something without counting it; the Name is about the counting.

**All of that is on beat 8, which is fixed and not AI-replaced** (§5a). It only binds because it is fixed, which is why none of this reasoning sits in the bridge or the reflection.

---

### Bar 4 — the full-corpus root sweep

`corpus.quran.com/qurandictionary.jsp?q=HSy` — **fetched live, HTTP 200, 15,572 bytes.** (Case-sensitive and silently wrong on the wrong case, §9by.) Corpus headline, quoted: *"The triliteral root ḥāʾ ṣād yāʾ (ح ص ي) occurs **11 times** in the Quran, in **two derived forms**: 10 times as the form IV verb `aḥṣā`, once as the noun `aḥṣā`."* **Arithmetic: 10 + 1 = 11.** ✓

**A root with only 11 occurrences means this sweep is complete rather than sampled — every occurrence is below, with its disposition.**

| # | āyah | word | subject | disposition |
|---|---|---|---|---|
| 1 | **36:12** | `أَحْصَيْنَـٰهُ` | **Allah, 1st-pers. pl.** | ✅ **THE CARRIER.** Bar 1 top rung, bar 5 clean in both directions |
| 2 | **16:18** | `تُحْصُوهَآ` | humans (negated) | ✅ **the verse beat.** Does not carry bar 1 — the subject is *you* — but carries the root, the reciprocal, and lands on `لَغَفُورٌ رَّحِيمٌ`. **Independently reserved for this Name** — see below |
| 3 | 14:34 | `تُحْصُوهَا` | humans (negated) | near-duplicate of 16:18 and **weaker on bar 5**: fetched, 14:34 closes `إِنَّ ٱلْإِنسَـٰنَ لَظَلُومٌ كَفَّارٌ` — Saheeh: *"Indeed, mankind is [generally] most unjust and ungrateful."* An accusation of the reader. **16:18 says the same thing and closes on mercy instead.** Rejected |
| 4 | 19:94 | `أَحْصَىٰهُمْ` | Allah | root-dense and tempting (`وَعَدَّهُمْ عَدًّا` alongside). **Rejected on bar 5:** 19:95 is `وَكُلُّهُمْ ءَاتِيهِ يَوْمَ ٱلْقِيَـٰمَةِ فَرْدًا` — coming to Him on the Day of Resurrection **alone**. Left free |
| 5 | 18:49 | `أَحْصَاهَا` | the record | fetched: the āyah opens on `ٱلْمُجْرِمِينَ` — *"you will see the criminals fearful of that within it, and they will say, 'Oh, woe to us!'"* The clause carrying the root is **inside the criminals' own speech**. **Rejected on bar 5 and on bar 1** |
| 6 | 58:6 | `أَحْصَىٰهُ` | Allah | fetched: *"On the Day when Allāh will resurrect them all and inform them of what they did."* Day-of-Resurrection framing. **Rejected on bar 5.** Note also that it closes `وَٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ شَهِيدٌ` — **Ash-Shaheed's ground (id 60, unstarted)**, so leaving it costs this deck nothing and preserves that Name's text |
| 7 | 78:29 | `أَحْصَيْنَـٰهُ` | **Allah, 1st-pers. pl.** | grammatically the equal of 36:12 — **and its successor 78:30, fetched, is `فَذُوقُوا۟ فَلَن نَّزِيدَكُمْ إِلَّا عَذَابًا`: *"So taste [the penalty], and never will We increase you except in torment."*** The single clearest illustration in this sweep of why bar 5 is a separate bar from bar 1: identical grammar to the carrier, catastrophic register. **Rejected** |
| 8 | 72:28 | `وَأَحْصَىٰ` | Allah | clean, but the context is messengers conveying revelation — impersonal, and it does not reach the reader. Rejected on fit, not on a bar. Left free |
| 9 | 73:20 | `تُحْصُوهُ` | humans (negated) | the night-prayer āyah — `عَلِمَ أَن لَّن تُحْصُوهُ فَتَابَ عَلَيْكُمْ`, and it closes `إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ`. **A genuine alternative and warm.** Rejected because 16:18 states the asymmetry about *favours* rather than about *worship*, which is the direction this deck needs — **and because of the translation problem in the note below.** Left free and flagged as reusable |
| 10 | 65:1 | `وَأَحْصُوا۟` | **humans, imperative** | *"and keep count of the waiting period"* — divorce law. Not about Allah at all. Rejected |
| 11 | 18:12 | `أَحْصَىٰ` (noun) | the two factions | Saheeh: *"which of the two factions was **most precise in calculating** what [extent] they had remained in time"* — the Sleepers of the Cave. Not about Allah. Rejected |

**Bar 4 is met with no trade.** Two findings from this sweep are worth more than the verdict:

**(0) Independent confirmation, found by sweeping the pending drafts rather than only the asset.** `2026-08-03-al-wasi-DRAFT.md` evaluated **both 14:34 and 16:18**, rejected them, and recorded the reason in its own rejection list: *"end in 'most unjust and ungrateful' / `لَغَفُورٌ رَّحِيمٌ`; **both carry Al-Muhsi's `لَا تُحْصُوهَا`**."* So a different drafter, working a different Name, (a) **made the same closing-clause observation independently**, and (b) **explicitly reserved this āyah for this Name.** The verse beat is not merely uncontested — it was set aside for it.

**(i) The 14:34 / 16:18 trap.** Two near-identical āyāt — same clause, `وَإِن تَعُدُّوا۟ نِعْمَةَ ٱللَّهِ لَا تُحْصُوهَا` — **and the choice between them is decided entirely by their closing clauses**: 14:34 calls mankind *"most unjust and ungrateful"*, 16:18 calls Allah *"Forgiving and Merciful."* A drafter reaching from memory for "the verse about not being able to count Allah's favours" has a **coin-flip chance of taking the one that fails bar 5**, and **the two are indistinguishable until you fetch the whole āyah.** Recorded so nobody does.

**(ii) 73:20's root is not translated as counting, and I got this wrong before fetching it.** An earlier revision of this table glossed it *"He knows that you will not be able to count it."* **Saheeh renders `لَّن تُحْصُوهُ` as "will not be able to `do` it"** — the referent is the night vigil, not an act of counting. That gloss was my own rendering, unbacked by any published translation, which §9bh forbids outright. **It is corrected above.** Flagged prominently because it is a small instance of the exact failure this whole protocol exists for: the root was genuinely present, the sentence I wrote was plausible, and it was wrong until a fetch made it wrong out loud. **A second, smaller instance in the same table:** 18:12 was glossed *"best in calculating"*; Saheeh says *"most precise in calculating."* Both corrections were made by fetching all eleven occurrences rather than the two the deck uses.

---

## Twin-diff

**No twin — drafted alone**, and id 66 shares no catalogue duʿā with any other id (checked against the §9bs group and the ids 79/80/81/82 pairs).

Diffed anyway against the nearest drafts written in this session: **max shared word-run vs `2026-08-03-al-bari-DRAFT.md` = 1.** No shared text, no shared engine (precedence vs granularity), no shared āyah.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **6:59** | **already spent — `al-aleem@1`'s verse beat renders it.** And it is a trap: **id 66's own catalogue `hadith` field is prose built on 6:59**, so the next drafter who reads the catalogue top-to-bottom will be pointed straight at an āyah another deck has taken |
| **14:34** | accuses the reader in its closing clause. 16:18 is its twin and does not |
| **19:94 · 18:49 · 58:6 · 78:29** | bar 5 — Judgment scene or explicit punishment adjacent |
| **65:1 · 18:12 · 73:20 · 72:28** | 65:1 and 18:12 are not about Allah; 72:28 does not reach the reader; 73:20 is a real alternative, left free |
| **36:13–14** | `al-azeez@1`'s ground |
| **Erasure / covering of the record** | that is `al-ghafur@1`'s engine. See surface (c) — this deck stops at *itemised*, deliberately |

---

## Catalogue findings — reported, **NO change recommended**

Per the brief: never rule on your own catalogue recommendation. Three of the first three such recommendations in this project were wrong.

1. **Id 66's `lesson` and `dua_translation` point in opposite emotional directions.** `lesson`: *"Al-Muhsi has numbered every tear you have shed. None are forgotten."* `dua_translation`: *"do not hold me fully accountable for what You have recorded **against** me."* Comfort vs. accountability, for the same Name. **This deck does not harmonise them — it sequences them**, arriving at the duʿā through 16:18's `لَغَفُورٌ رَّحِيمٌ`. Whether that is sufficient is a verifier's call, and it is the single most important thing to review here.
2. **Id 66's `hadith` field is not a ḥadīth.** It is authored prose quoting **Qur'an 6:59** — an āyah, in a field named `hadith`, for a Name whose duʿā claims no narration. **And 6:59 is already rendered by `al-aleem@1`.** Reported because it actively misdirects the next reader, not because this deck was affected.

---

## What I could not determine — attack these first

1. **The duʿā tension is the deck's load-bearing judgement call.** The structural answer — reach the accountability plea through a mercy closing — is the best available given two locked strings, but it is an argument, not a measurement. **If a verifier judges that "recorded against me" cannot render at 11pm to someone in distress regardless of what precedes it, that is a catalogue-level problem this deck cannot solve**, and it would need escalating rather than redrafting.
2. **The `al-ghafur@1` engine proximity** (surface (c)). I believe the itemisation/erasure split holds, but I found it by reading that deck, not by measuring — and no measurement in this draft would have surfaced it. **A verifier should re-argue it from scratch rather than check my argument.**
3. ~~**`al-muhyi@1` overlap unverified.**~~ **Closed — measured.** Beat 3 renders `نُحْىِ ٱلْمَوْتَىٰ`, which is that Name's root and subject, so the overlap was worth checking properly rather than asserting. Its draft cites **30:48, 30:50, 41:39 and never 36:12** (grepped: 0 hits), and diffing my beats against **68 candidate rendered strings** extracted from it gives a **maximum shared word-run of 2** — *"the dead"*. **No collision.** Recorded as a closed item rather than deleted, because "I did not check the pending drafts" is the standing gap and this is one instance of it actually being closed.
4. **The 24 other pending drafts were not swept.** Bar 3(b) is measured against the **45 shipped decks only**. This is the standing gap across the whole wave, not new here — but for *this* Name it is sharper than usual, because two of its closest relatives (60 Ash-Shaheed, 39 Al-Hafeez) are **unstarted**, so the family argument on surface (c) is made against neighbours that do not exist yet. **Whoever drafts 60 and 39 must diff against this deck, not the reverse.**
5. **`.context/claims/` was empty at claim time** — gitignored, fresh workspace. Prior claims were reconstructed from drafts and the shipped asset rather than read.
6. **No ḥadīth was fetched.** There are no ḥadīth beats and the duʿā claims no narration, so `sunnah.com` was never queried — **a fact about this deck's needs, not a claim about that site's availability** (§9bc).
7. **Two glosses in this draft's own rejection table were wrong until fetched** (73:20 and 18:12 — see the bar-4 section). Both were in *rejected* candidates, so neither reached a beat, and both are corrected. **Stated here rather than buried**, because a report that only lists the checks that passed is the shape of every quarantined draft in this project. The fix was mechanical and worth generalising: **fetch every occurrence the corpus lists, not only the ones the deck uses.** For an 11-occurrence root that costs eight extra requests.

---

## Pairing verdict

**Ships independently.** No shared catalogue duʿā; no must-ship-together partner; both scripture beats are whole āyāt with no truncation, so nothing depends on a neighbouring deck rendering the rest of a clause.
