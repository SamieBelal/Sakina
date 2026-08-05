# Deck Draft — Al-Mutaali (catalogue id 84) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-ali-DRAFT.md`](2026-08-03-al-ali-DRAFT.md).** Ids 84 and 52 **share one locked `dua_arabic`** (§9ce) — a shared-duʿā group the handoff did not record until 2026-08-03. They **also share the root `ع-ل-و`** — one duʿā, one root, two Names.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/52-84.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-mutaali@1` — Al-Mutaali

**Why this deck exists, in one line:** the user who has quietly settled on a conclusion about God, drawn from the worst thing that happened to them, and has been living inside it ever since.

**What separates it from its pair-partner:** Al-Ali is about **the form an encounter takes**; Al-Mutaali is about **every description falling short** — including the flattering ones, and including this deck's.

**Proposed metadata**

```json
{
  "deck_id": "al-mutaali@1",
  "name_id": 84,
  "transliteration": "Al-Mutaali",
  "chip_keys": [],
  "position_in_pair": 2,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> Every picture of God you have ever held was too small. That is not a failure of yours. It is the one thing about Him you can be certain of.

**Beat 2 · name_intro** *(catalogue id 84 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُتَعَالِ — Al-Mutaali — The Most Exalted

**Beats 3–5 · story — "The Question That Points"** *(Qur'an 27:63)*:
> 3. Allah asks: "Is He [not best] who guides you through the darknesses of the land and sea, and who sends the winds as good tidings before His mercy?"
> 4. The question does not argue with you. It points — at the dark you were led through, at the wind that arrived before the rain did — and then leaves you to answer it yourself.
> 5. "…High is Allah above whatever they associate with Him." Above the rivals, and above the descriptions. Whatever you concluded He was from what happened to you, He is higher than that too.

**Beat 6 · verse** *(partial quotation — **one word** of a four-epithet clause, ellipsis both sides)*:
> …the Exalted. — Qur'an 13:9

**Beat 7 · duʿā** *(catalogue id 84, **byte-for-byte**, asserted programmatically (§9cb); **identical to id 52's** — catalogue-locked)*:
> يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ
> *Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar*
> "O The Exalted, O The Supremely Exalted, raise my heart above resentment and smallness."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Ali is about the form an encounter with Him has to take. Al-Mutaali is the correction that never stops being needed: whatever you have concluded He is, He is already beyond it — this deck's own sentences included. That is not a wall you keep walking into. It is the reason there is always more of Him left to find.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you quietly decided about God, based on what happened to you? Hold it loosely tonight.

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Is He [not best] who guides you through the darknesses of the land and sea, and who sends the winds as good tidings before His mercy? … High is Allah above whatever they associate with Him"* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../27:63` | ✅ `أَمَّن يَهْدِيكُمْ فِى ظُلُمَـٰتِ ٱلْبَرِّ وَٱلْبَحْرِ وَمَن يُرْسِلُ ٱلرِّيَـٰحَ بُشْرًۢا بَيْنَ يَدَىْ رَحْمَتِهِۦٓ ۗ أَءِلَـٰهٌ مَّعَ ٱللَّهِ ۚ تَعَـٰلَى ٱللَّهُ عَمَّا يُشْرِكُونَ` — the clause `أَءِلَـٰهٌ مَّعَ ٱللَّهِ` is **not rendered** |
| 2 | *"…the Exalted."* (beat 6) | `.../13:9` | ✅ `ٱلْمُتَعَالِ` — **one word**, ellipsis both sides. `عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ` **left for id 60** and `al-aleem@1`; `ٱلْكَبِيرُ` **left for id 53** |
| 3 | Successor sweep n−1: 27:62 | `.../27:62` | ✅ **the warmest predecessor in this wave** — *He who responds to the desperate one when he calls*. Not rendered; `al-mujeeb@1`'s ground |
| 4 | Successor sweep n+1: 27:64 | `.../27:64` | ✅ creation and provision, closes on a challenge to produce proof. **No punishment** |
| 5 | The locked duʿā (shared with id 52) | `collectible_names.json` id 84 | ✅ all three fields asserted present (§9cb) |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **27:63** — Allah's own voice, and the exalting verb `تَعَـٰلَى ٱللَّهُ` is predicated in the same āyah as two narrated acts (guiding through darkness, sending the winds) | ✅ **PASS** |
| 2 | Shown, not stated | the āyah is **a rhetorical question with evidence inside it** — `أَمَّن يَهْدِيكُمْ فِى ظُلُمَـٰتِ ٱلْبَرِّ وَٱلْبَحْرِ`. It does not assert exaltedness; it produces two acts and lets the reader draw it | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ع-ل-و` as `تَعَـٰلَى` (27:63) and as `ٱلْمُتَعَالِ` — **the Name's own form** — on the verse beat (13:9) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **clean both sides** — 27:62 is *He who responds to the desperate one when he calls*; 27:64 is creation and provision with a mild challenge, no punishment | ✅ **PASS** |

**Bar 5, measured:** four āyāt fetched, zero punishment. **27:62 is the warmest predecessor in this wave** — `أَمَّن يُجِيبُ ٱلْمُضْطَرَّ إِذَا دَعَاهُ وَيَكْشِفُ ٱلسُّوٓءَ`, *Is He [not best] who responds to the desperate one when he calls upon Him and removes evil?* Not rendered here — **it is `al-mujeeb@1`'s ground** (drafted) — but its presence one āyah before the carrier is the strongest possible register signal for a deck about a reader in distress.

**Why the verse beat is one word.** `ٱلْمُتَعَالِ` — the Name's own form — occurs **exactly once in the Qurʾān**, at 13:9, inside a **four-epithet chain**: `عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ ٱلْكَبِيرُ ٱلْمُتَعَالِ`. That chain **cannot carry bar 1** (§9bk: it labels rather than demonstrates) and it carries three other Names' ground — `عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ` (**id 60 Ash-Shaheed** and `al-aleem@1`) and `ٱلْكَبِيرُ` (**id 53 Al-Kabeer**). So the deck takes **one word** and leaves the rest, the same structure `az-zahir@1` and `al-batin@1` use on 57:3. **Bar 1 therefore had to come from a `تَعَـٰلَىٰ` verb elsewhere, and bar 4 is met twice over.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** Every hit is a function-word or scripture run — *"sends the winds"* (vs `al-basit@1`'s verse beat, both quoting wind-before-mercy āyāt; **scripture, §9bl**), *"is the one"*. **No finding.**

**Twin-diff vs `al-ali@1`** (the pair-partner, which is the diff that matters here): ****4** — *"is not a wall"*, a deliberate echo of the partner's beat 4 (see that draft). An earlier revision measured **5**, because this deck's takeaway quoted the partner's phrase *"the address has a shape"* verbatim while trying to differentiate from it. **Rewritten** — the identical failure the judgment four produced.**

**Every āyah checked against the shipped asset *and* all 30 pending drafts**, two-sided boundary match: **27:63 free · 13:9 free.** Checked and rejected as spent-or-cited: 17:43 (`al-quddus` draft), 6:100 (`al-wahid`, `al-ahad`), 10:18 (`ad-darr`, `an-nafi`), 20:114 / 23:116 (`al-malik`), 30:40 (`al-muhyi`, `al-mumeet`), 7:190 (`al-khaliq`).

### Bar 3(c) — the move

**Al-Mutaali's move is that every conception of Him is already exceeded — including the one the reader is currently holding, and including this deck's own sentences.**

That last clause is the deck's whole risk and its whole point. A Name meaning *the one above all description* is trivially easy to render as a vague superlative. **27:63 prevents that by grounding it**: before the exalting verb, the āyah names two concrete things — being guided through darkness on land and sea, and wind arriving ahead of rain. **The exaltedness is the remainder after the evidence, not a substitute for it.**

**Against the pair-partner:** Al-Ali describes **the channel** — revelation, partition, messenger. **Al-Mutaali describes the limit of the description itself.** One tells you how contact works; the other tells you that whatever you concluded from the contact is still short.

**Against `al-mutakabbir@1` (drafted, id 19)**, the nearest non-pair neighbour: that Name is **greatness over rivals** — supremacy against a claimant. **This one is transcendence over *accounts*** — there is no rival in the frame, only the reader's own too-small picture. The two collapse if either is written as "He is greater than everything", so neither is.

---

## The shared duʿā

Ids 84 and 52 render **one identical duʿā beat**: `يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ`. A user who collects both sees the same duʿā twice. **Catalogue-locked, disclosed rather than concealed, and no beat on either deck claims it is Name-specific.** Each deck's engine is carried on its **takeaway**, which is fixed and not AI-replaced.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **13:9 as the bar-1 carrier** | the Name's **only** occurrence, and a four-epithet chain — labels, does not demonstrate (§9bk). Used as the verse beat, where it needn't carry bar 1 |
| **17:43** `سُبْحَـٰنَهُۥ وَتَعَـٰلَىٰ عَمَّا يَقُولُونَ عُلُوًّا كَبِيرًا` | the root **twice** and the most on-the-nose text for this Name — **cited in the `al-quddus` draft**, and `عُلُوًّا كَبِيرًا` carries **id 53's** word. Left |
| **6:100 · 10:18 · 30:40 · 7:190 · 20:114 · 23:116** | all cited in pending drafts (`al-wahid`/`al-ahad`, `ad-darr`/`an-nafi`, `al-muhyi`/`al-mumeet`, `al-khaliq`, `al-malik`) |
| **16:3 · 23:92 · 28:68 · 72:3** | free, and all viable. **Left unspent and recorded as reusable** — 28:68 (`وَرَبُّكَ يَخْلُقُ مَا يَشَآءُ وَيَخْتَارُ`) is the strongest of them |
| **23:116** `فَتَعَـٰلَى ٱللَّهُ ٱلْمَلِكُ ٱلْحَقُّ` | carries **`al-malik@1`'s and `al-haqq@1`'s** ground, and is cited in the `al-malik` draft |
| **13:9's `ٱلْكَبِيرُ` and `عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ`** | left for **id 53 Al-Kabeer**, **id 60 Ash-Shaheed** and `al-aleem@1`. This deck renders **one word** of the āyah |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā names both Names** (`يَا عَلِيُّ يَا مُتَعَالِي`) — the only shared-duʿā group in the catalogue with no mismatch between the duʿā's vocative and the decks' Names. See the partner draft.
2. **Id 84's `arabic` is `الْمُتَعَالِ`**, matching 13:9's pausal form exactly. Noted as correct, not as a defect.

---

## What I could not determine — attack these first

1. **The Name's own form occurs once in the Qurʾān**, in a chain that cannot carry bar 1. The deck is therefore built on a **different form of the same root**, which is legitimate but should be checked: a verifier may hold that `تَعَـٰلَى` (a verb about being above associations) and `ٱلْمُتَعَالِ` (the Name) are not close enough for the verb to demonstrate the Name.
2. **A quarantined Haiku draft in this wave inverted exactly this root identity** — it treated `ٱلْمُتَعَالِ` and `ٱلْعَلِىُّ` as *different* roots when both are `ع-ل-و` (ledger §9bw). **This deck asserts they are the same root**, which the corpus confirms (`Elw`, 70 occurrences, both forms listed). Stated explicitly because the opposite claim is already in the project's history.
3. **`ع-ل-و`'s 70 occurrences across 14 forms were not exhaustively fetched** (§9cc) — complete on `ٱلْمُتَعَالِ` and on the named `تَعَـٰلَىٰ` candidates, incomplete on the root.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently, but must be reviewed alongside `al-ali@1`** — shared duʿā *and* shared root means a reviewer seeing only one deck cannot judge whether the pair separates.
