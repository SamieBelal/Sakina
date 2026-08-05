# Deck Draft — Al-Muhaymin (catalogue id 18) — **R0, awaiting independent blind verification**

> **Id 18 was previously quarantined for fabricated content.** That draft was not reused and not read as precedent.
>
> ⚠️ **Bar 1 is contested and the deck is built around the contest.** `مُهَيْمِن` occurs **twice in the entire Qurʾān**: at **5:48 its referent is the Book, not Allah**, and at **59:23 it sits in an eight-epithet chain** that labels rather than demonstrates. See the bars note.
>
> **Completes the four-way watching/protecting family** with shipped `ar-raqeeb@1`, `al-mumin@1` and `al-hafeez@1` (drafted this session, which explicitly owed this deck the diff).

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/18.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-muhaymin@1` — Al-Muhaymin

**Why this deck exists, in one line:** the user supervising something they cannot actually watch — a grown child, an illness, a situation two countries away — where the vigilance has become its own exhaustion.

**The reader's position:** **standing guard without standing.** They are watching, and they know watching is not the same as being able to do anything.

**Proposed metadata**

```json
{
  "deck_id": "al-muhaymin@1",
  "name_id": 18,
  "transliteration": "Al-Muhaymin",
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
> You have been checking on something you cannot actually watch, and the checking has become its own exhaustion.

**Beat 2 · name_intro** *(catalogue id 18 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُهَيْمِنُ — Al-Muhaymin — The Overseer

**Beats 3–5 · story — "Confirming, and Standing Over"** *(Qur'an 5:48)*:
> 3. Allah says of the Book He sent down: "And We have revealed to you the Book in truth, confirming that which preceded it of the Scripture — and as a criterion over it."
> 4. Two words for what it does. Confirming: it does not erase what came before it. And muhaymin: it stands over that, keeping it, deciding what holds.
> 5. That is how the Qur'an uses the word about itself. Not surveillance. Custody with standing — present over a thing, and answerable for it.

**Beat 6 · verse** *(partial quotation — **one word** of an eight-epithet clause, ellipsis both sides)*:
> …the Overseer… — Qur'an 59:23

**Beat 7 · duʿā** *(catalogue id 18, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا مُهَيْمِنُ احْرُسْنِي بِعَيْنِكَ الَّتِي لَا تَنَامُ
> *Ya Muhaymin, ihrusni bi 'aynikal-lati la tanam*
> "O Overseer, guard me with Your eye that never sleeps."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Ar-Raqeeb watches. Al-Hafeez keeps. Al-Muhaymin is over it — with the standing to rule on a thing, not only the attention to notice it. Whatever you have been trying to supervise from underneath already has someone above it.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you been standing guard over that was never yours to authorise?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And We have revealed to you the Book in truth, confirming that which preceded it of the Scripture — and as a criterion over it."* (beats 3–5, **bar-4 carrier**) | `.../5:48` | ✅ `وَأَنزَلْنَآ إِلَيْكَ ٱلْكِتَـٰبَ بِٱلْحَقِّ مُصَدِّقًا لِّمَا بَيْنَ يَدَيْهِ مِنَ ٱلْكِتَـٰبِ وَمُهَيْمِنًا عَلَيْهِ` — the first clause only. **`فَٱحْكُم بَيْنَهُم` onward not rendered** |
| 2 | *"…the Overseer…"* (beat 6) | `.../59:23` | ✅ `ٱلْمُهَيْمِنُ` — **one word** of an eight-epithet chain, ellipsis both sides |
| 3 | Successor sweep n−1: 5:47 | `.../5:47` | ⚠️ ends `فَأُو۟لَـٰٓئِكَ هُمُ ٱلْفَـٰسِقُونَ`. **Not rendered** |
| 4 | Successor sweep n+1: 5:49 | `.../5:49` | ⚠️ warns `أَن يُصِيبَهُم بِبَعْضِ ذُنُوبِهِمْ`. **Not rendered** |
| 5 | Root inventory | direct fetch of both occurrences | ⚠️ **`corpus?q=hymn` returns the wrong root** (it returns آدم entries — §9by). The two occurrences were established **by fetching 5:48 and 59:23 directly.** Stated as a limit |

---

### R3 — bar 1 ruled, on accuracy rather than on comfort

**The root is complete at two occurrences and there is no third text.** Independently re-confirmed: `corpus?q=hmn` — *"occurs twice in the Quran as the form II active participle `muhaymin`"* — **5:48 and 59:23**. (The code is `hmn`; `hymn` silently returns آدم's entries, §9by.) So every option was on the table at once, and there are only two.

| | what it is | what it can carry |
|---|---|---|
| **5:48** `وَمُهَيْمِنًا عَلَيْهِ` | the Name-word, **predicated of the Book** | bars 1–2 **at one remove** — the act is Allah's (`وَأَنزَلْنَآ`), and the custody is what He conferred |
| **59:23** `ٱلْمُهَيْمِنُ` | the Name-word, **predicated of Allah**, inside an eight-epithet chain | **bar 4**, cleanly. Not bar 1 — a chain labels |

**Ruling: PASS, and the referent is stated rather than blurred.** Bar 1 asks that the Name be *demonstrated in Allah's words*. At 5:48 Allah is the speaker and the subject — `وَأَنزَلْنَآ إِلَيْكَ ٱلْكِتَـٰبَ بِٱلْحَقِّ` — and what He narrates is **His own act of placing one thing in authority over another.** The word `مُهَيْمِنًا` names the standing He conferred. **Custody exercised through an appointed instrument is still His custody**, and the demonstration is of the attribute in operation, which is what bar 2 asks for.

**What this deck must not do is claim more than that.** It does not claim `مُهَيْمِنًا` describes Allah at 5:48 — **it describes the Book, and the deck says so on its own story beat** (*"That is how the Qur'an uses the word about itself"*). The Name predicated of Allah is at **59:23**, and that is where bar 4 sits. **A verifier who requires bar 1's Name-word to be predicated of Allah in the same clause will refuse this deck, and the honest answer is that no text in the Qurʾān satisfies that requirement for this Name.**

**Bar 5, fetched and disclosed:** **5:47** closes `فَأُو۟لَـٰٓئِكَ هُمُ ٱلْفَـٰسِقُونَ` and **5:49** warns of affliction for turning away. **Neither is rendered** — the beat is 5:48's opening clause only, stopping before `فَٱحْكُم بَيْنَهُم`. Same shape as `al-hakeem@1` (n−1 is a Fire āyah) and `al-khabeer@1` (n−1 is a visceral rebuke), both of which passed disclosed.

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | ⚠️ **contested.** 59:23 predicates `ٱلْمُهَيْمِنُ` **of Allah**, in Allah's own voice — but as an epithet in a chain, which §9bk says labels. 5:48 is Allah's own voice and a described act, but its `مُهَيْمِنًا` **describes the Book** | ⚠️ **CONTESTED — attack this first** |
| 2 | Shown, not stated | 5:48 **shows the word working** — the Book is `مُصَدِّقًا` (confirming what preceded) *and* `مُهَيْمِنًا عَلَيْهِ` (standing over it). Two functions in one clause, which is what defines the term | ✅ **PASS on the definition; see bar 1 for whose attribute it is** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ه-ي-م-ن` as `مُهَيْمِنًا` (5:48) and `ٱلْمُهَيْمِنُ` (59:23) — **both of the root's two Qurʾānic occurrences** | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **both neighbours of the carrier carry rebuke** — 5:47 ends `ٱلْفَـٰسِقُونَ`, 5:49 warns of affliction for sins. **Neither rendered** | ⚠️ **PASS — neighbours never rendered** |

**Bar 1, stated as the deck's open question rather than argued past.** The root has **two occurrences and that is the whole inventory**:

| occurrence | what `muhaymin` describes | verdict |
|---|---|---|
| **5:48** `وَأَنزَلْنَآ إِلَيْكَ ٱلْكِتَـٰبَ … وَمُهَيْمِنًا عَلَيْهِ` | **the Book** | Allah's own voice and a narrated act — **but the attribute is the Qurʾān's** |
| **59:23** `هُوَ ٱللَّهُ … ٱلْمُهَيْمِنُ` | **Allah** | predicated correctly — **but inside an eight-epithet chain, which labels** (§9bk) |

**So no single text both predicates the Name of Allah *and* demonstrates it.** The deck's structure is the only one available: **5:48 defines the term by showing it operate; 59:23 attaches it to Allah.** The takeaway then argues the transfer explicitly rather than smuggling it.

**This is the Al-Majeed pattern** (id 58, drafted this session), and a verifier who rejects one should look hard at the other. **If bar 1 is judged unmet, this Name has nowhere else to go** — the sweep is complete at two — and it becomes a refusal on bar 1 for lack of any demonstrative divine predication. **Per §9cg, do not refuse it for "no single text does everything."**

**A corpus note that cost time and is worth recording.** The corpus code `hymn` **does not return this root** — it returns the entries for آدم. §9by's silent-failure trap: the page renders, the āyāt look plausible (2:31, 7:11, 20:115), and nothing signals an error. **The two occurrences here were established by fetching 5:48 and 59:23 directly**, not from a corpus headline, and **no occurrence count from `corpus?q=hymn` should be trusted.**

**Bar 5, fetched.** **5:47** ends `فَأُو۟لَـٰٓئِكَ هُمُ ٱلْفَـٰسِقُونَ`; **5:49** warns `أَن يُصِيبَهُم بِبَعْضِ ذُنُوبِهِمْ`. **Neither is punishment or Fire, neither is rendered, and neither addresses the reader** — both concern judges ruling by other than what Allah revealed.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 3.** the only hit is *"only the"* (vs `al-ghafur@1`'s takeaway), a function-word run. An earlier revision measured **5** (*"is the word the"* vs `al-wahhab@1`) and beat 5 was rewritten.

**Every āyah checked against the shipped asset *and* all 48 pending drafts**, two-sided boundary match: **5:48 free.** **59:23 cited in several drafts** — including `al-qayyum`, `al-kareem` and `al-mutakabbir` — as a **Names-chain reference**, and **this deck renders one word of it**, the same manoeuvre `az-zahir@1` and `al-batin@1` use on 57:3. 59:22 is cited in the `al-khafid` draft; 59:24 in four.

### Bar 3(c) — the move

**Al-Muhaymin's move is standing, not attention.**

The other three in the family are all about the *quality of the watching*. This one is about **authority over the thing watched** — `مُهَيْمِنًا عَلَيْهِ`, *over it*. 5:48 makes that concrete: the Book does not merely observe the scriptures before it, and does not erase them either. **It confirms them and it rules on them.** Custody with jurisdiction.

| deck | the move |
|---|---|
| `ar-raqeeb@1` (shipped) | **observation** — watchers file a report |
| `al-mumin@1` (shipped) | **security given** to a person |
| `al-hafeez@1` (drafted) | **custody** — the thing does not depend on your grip |
| **`al-muhaymin@1`** | **jurisdiction** — someone is *over* it, with standing to decide |

**The one to press is `al-hafeez@1`**, drafted hours earlier and the closest: *keeping* versus *being over*. The split is authority — Al-Hafeez preserves a thing, Al-Muhaymin has the standing to rule on it. **Thin, same author, same session. Re-argue it** (§9cd).

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **59:23 as the bar-1 carrier** | an **eight-epithet chain** — labels, does not demonstrate (§9bk). Used as the verse beat, where it needn't carry bar 1 |
| **5:48's continuation** (`فَٱحْكُم بَيْنَهُم بِمَآ أَنزَلَ ٱللَّهُ` …) | an instruction to the Prophet about judging, and `فَٱحْكُم` is **id 47 Al-Hakam's** root. **Not rendered** |
| **5:47 · 5:49** | rebuke and threatened affliction. **Never rendered** |
| **Any third text** | **there is none.** The root has two Qurʾānic occurrences, both used here |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing in the catalogue.** Id 18's `english` (*The Overseer*), `meaning`, `lesson` (*Nothing escapes His watchful care. Al-Muhaymin guards what you cannot*) and duʿā (*guard me with Your eye that never sleeps*) are consistent — **though all four lean toward *watching*, which is `ar-raqeeb@1`'s move**, while the Arabic leans toward *authority over*. **Fifth instance of the `lesson` field pointing at a neighbour's engine**; the deck follows the Arabic and flags it.

---

## What I could not determine — attack these first

1. **Bar 1 is contested and it is the whole deck.** No text both predicates the Name of Allah and demonstrates it. **Attack this before anything else.**
2. **The root sweep was done by direct fetch, not by the corpus** — `corpus?q=hymn` returns the wrong root entirely (§9by). **So "two occurrences" rests on standard knowledge of the Name plus two verified fetches, not on a corpus enumeration.** If a third occurrence exists, this sweep would not have found it. **The most under-verified claim in this deck.**
3. **The `al-hafeez@1` separation** is argued, same author, same session (§9cd).
4. **No ḥadīth fetched** (§9bc). Given bar 1's weakness, a ḥadīth predicating `muhaymin` of Allah demonstratively would settle it — **unexplored, not closed** (§9bo).

---

## Pairing verdict

**Ships only if bar 1 survives review.** Must be read with `al-hafeez@1`, `ar-raqeeb@1` and `al-mumin@1` — the family argument covers all four and no one deck carries it.
