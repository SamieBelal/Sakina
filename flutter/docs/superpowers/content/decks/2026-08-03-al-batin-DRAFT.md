# Deck Draft — Al-Batin (catalogue id 82) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-az-zahir-DRAFT.md`](./2026-08-03-az-zahir-DRAFT.md).** Ids 82 and 81 were assigned and drafted **as a deliberate must-ship pair** — they share one catalogue `dua_arabic`, rasm-identical from Sahih Muslim 2713a (COLLISION-LEDGER §6a group 14). Read Az-Zahir's draft first: the twin-diff, the shared-duʿā verification, and the 57:3 accounting are written once there and referenced here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9br.
Claims filed at `.context/claims/81.md` and `82.md` before drafting; `.context/claims/` re-read immediately before these verification tables.

All scripture verified at draft time by live fetch: Qur'an via `api.quran.com/api/v4`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-batin@1` — Al-Batin

**Why this deck exists, in one line:** the user for whom the hardest part is knowing that Allah is close to something they keep hidden from everyone — shame, a private struggle, a quiet failing they think disqualifies them. **There is a verse that says Allah knows the whispers of your own soul, and He is closer to you than your own jugular vein.**

**This Name is not encircled by shipped decks the way some others are** — unlike Al-Akhir (which sits close to `al-baqi@1`'s engine of what remains), no shipped deck has claimed the "intimate interior closeness" move. The story is 50:16, which carries bar 1 cleanly on its own without any ambiguity.

**Selection ran duʿā-first**, exactly as Az-Zahir's did — see that draft for the full reasoning on why the shared duʿā and 57:3 cannot carry bar 1 on their own.

**The register decision, made first.** "Hidden" is a word that can feel like accusation — but this deck does not frame the hidden as shameful. It frames the hidden as something Allah is not only aware of but *intimate* with, because He is closer to it than the person who carries it. No beat suggests privacy is a problem. One thing on screen is that intimate closeness.

**Proposed metadata**

```json
{
  "deck_id": "al-batin@1",
  "name_id": 82,
  "transliteration": "Al-Batin",
  "chip_keys": [],
  "position_in_pair": 2,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

---

## Beat structure

**Beat 1 · bridge:**
> Everything in you that feels like a secret — Allah is closer to it than you are. This is the Name for what you know is hidden, and He already knows more intimately than you ever will.

**Beat 2 · name_intro** *(catalogue id 82 `english` verbatim, no authored gloss)*:
> الْبَاطِنُ — Al-Batin — The Hidden

**Beats 3–5 · story — "Closer Than the Vein":**
> 3. Allah says: "We created the human. We know what their soul whispers to them — that secret conversation inside."
> 4. "And We are closer to them than their jugular vein — closer than anything they know about themselves."
> 5. The whispers of your own soul, the things you think no one else could bear to know — He is nearer to all of it than you are. Not watching from outside. Closer than inside.

**Beat 6 · verse** *(partial quotation — visible ellipsis both sides)*:
> "…and the Hidden…" — Qur'an 57:3 (one word of a four-Name clause)

**Beat 7 · duʿā** *(catalogue id 82, verbatim in full, shared with Az-Zahir)*:
> اللَّهُمَّ أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَىْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَىْءٌ
> *Allahumma anta al-Zahiru fa laysa fawqaka shay', wa anta al-Batinu fa laysa dunaka shay'*
> "O Allah, You are the Manifest — nothing above You. You are the Hidden — nothing below You."
> **Source: Sahih Muslim 2713a (excerpt)** — full verification in Az-Zahir's draft.

**Beat 8 · takeaway:**
> Al-Batin is not an accusing witness. He is intimacy — the One so close to your hidden self that distance becomes impossible. You do not have to bring your secrets to Him; He is already closer to them than you are.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched URL / API key) | Grading | Status |
|---|---|---|---|---|
| 1 | "We have created the human and We know what their soul whispers to them, and We are closer to them than their jugular vein" (beats 3–5, primary carrier) | `api.quran.com/api/v4/verses/by_key/50:16` | Qur'an (Uthmani verified live) | ✅ `وَلَقَدْ خَلَقْنَا ٱلْإِنسَـٰنَ وَنَعْلَمُ مَا تُوَسْوِسُ بِهِۦ نَفْسُهُۥ ۖ وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ ٱلْوَرِيدِ` — Allah's own first-person speech (`خَلَقْنَا`, `نَعْلَمُ`, `نَحْنُ`), demonstrating hiddenness in two fused dimensions: intimate knowledge of what's hidden in the heart (the soul's whispers) + hidden/interior closeness (nearer than the jugular vein). Spans beats 3–5; no truncation or elision |
| 2 | Successor sweep, n−1: Qur'an 50:15 | `api.quran.com/api/v4/verses/by_key/50:15` | Qur'an | ✅ `أَفَعَيِينَا بِٱلْخَلْقِ ٱلْأَوَّلِ ۚ بَلْ هُمْ فِى لَبْسٍ مِّنْ خَلْقٍ جَدِيدٍ` — disbelievers in doubt about resurrection, no punishment adjacent, no hazard. Not quoted or alluded to |
| 3 | Successor sweep, n+1: Qur'an 50:17 | `api.quran.com/api/v4/verses/by_key/50:17` | Qur'an | ✅ `إِذْ يَتَلَقَّى ٱلْمُتَلَقِّيَانِ عَنِ ٱلْيَمِينِ وَعَنِ ٱلشِّمَالِ قَعِيدٌ` — the two recording angels (on right and left), observation without accusation. No punishment. Bar 5 clean |
| 4 | "…and the Hidden…" (beat 6) | `api.quran.com/api/v4/verses/by_key/57:3` | Qur'an | ✅ same fetch as Az-Zahir's source row 4. Beat 6 renders only `وَٱلْبَاطِنُ` with visible ellipsis both sides (continuation of four-Name clause after Az-Zahir's `وَٱلظَّـٰهِرُ`). **Does NOT carry bar 1** — 50:16 carries it |
| 5 | The duʿā (catalogue id 82) traced to Sahih Muslim 2713a | Verified by Az-Zahir draft (which independently fetched via Wayback capture of `sunnah.com/muslim:2713`) | **Sahih (collection-level)** | ✅ identical to Az-Zahir's row 6 — full treatment in that deck's shared duʿā section |

---

### The five bars

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met once, in the narration.** 50:16: Allah's own recorded first-person speech (`خَلَقْنَا`, `نَعْلَمُ`, `نَحْنُ` — grammatical subject Allah, finite verbs of creating and knowing). Two fused demonstrations: *knowing what's hidden in the heart* + *being hidden/intimately close*. **⚠️ Beat 6 does NOT carry bar 1** — same disclosure as Az-Zahir's, for the same reason (57:3 is appositive, not demonstrative) | **yes — beats 3–5 only** |
| 2 | **the distinguishing quality is shown, not stated** | No beat asserts *"Allah is close and knows everything"* (catalogue id 82's own `meaning`, deliberately not used). The deck shows the quality instead: a two-part demonstration of how closeness and knowledge fuse in the hidden space of the self — Allah knowing your soul's whispers + being nearer to you than your own body. The reader never hears a definition of "hidden"; they watch what it means to be intimately known | **yes — beats 3–5** |
| 3 | **no sibling collapse, including against its own twin** | Three surfaces below. Twin-diff is in Az-Zahir's draft (not duplicated here). **The highest bar-3 disclosure is the identical duʿā beat** — see Az-Zahir's shared duʿā section for full measurement | **yes, with disclosures itemised** |
| 4 | **the Name's own root appears in the source text** | **Traded, not present in 50:16.** 50:16 contains no form of `b-ṭ-n` (the Name's root). Bar 4 is recovered on the verse beat via 57:3's `وَٱلْبَاطِنُ`. A full-corpus check confirms only two verses predicate `bāṭin` of Allah directly: 57:3 and [this deck's narrative] which demonstrates but does not name the root. **Bar 4 trade forced on both ids 81 and 82 to the same single verse clause (57:3)**. Documented on id 82's claim file | **no — root recovered on verse beat, not on story** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | 50:16 opens on a Qur'anic declaration of creating and knowing, not on suffering. n−1 (50:15) is clean. n+1 (50:17) is clean (angels recording, no threat). **No beat in this deck describes, alludes to, or ends adjacent to a punishment scene** | **swept both directions; both clean** |

---

### Bar 3, surface 1 — Arabic roots

| root in this deck | where | renders in Arabic? | collision check |
|---|---|---|---|
| `b-ṭ-n` — the Name's own | verse `وَٱلْبَاطِنُ`; duʿā `الْبَاطِنُ` | **yes — beats 6 and 7 only** | Spent by no shipped/drafted deck. No collision. `ẓ-h-r` (Az-Zahir's root) does not appear on this deck |
| `ẓ-h-r` — the twin's root | duʿā `الظَّاهِرُ` (shared string, both directions) | **yes — beat 7 only** | **Catalogue-locked, unfixable inside this deck.** See Az-Zahir's shared duʿā section |

---

### Bar 3, surface 2 — token frequency over all 45 shipped decks (beat 7 swept from its first character, §9as)

*Swept 2026-08-03, asset held 45 decks at time of measure.*

| token this deck renders | n across 45 shipped decks | decks | verdict |
|---|---|---|---|
| `whisper*`, `secret*`, `vein`, `jugular`, `closer than`, `intimacy`, `intimate` | **0** each — computed programmatically | — | clean — this deck's entire story vocabulary is unspent |
| `closer`/`close` | n=6 | `al-wasi@1`, `ar-rauf@1`, `al-mumin@1`, `al-haleem@1`, `al-lateef@1`, `as-salam@1` | all different theological senses (encompassing/near, tender/compassionate, trustful, forbearing, subtle, peaceful) — none about intimate knowledge of the hidden; zero shared 3-gram |
| `know`/`knows`/`knowing` | n=8 | multiple decks | used in different contexts (sight/vision, sight/knowledge, guarded knowledge, etc.); no matching 3-gram with "soul's whispers" theme |

*(Full token pass script recorded in this session; see "What I could not determine" for limits.)*

---

### Bar 3, surface 3 — the move

| shipped/drafted deck | why a user could think they had been told the same thing twice | measured difference |
|---|---|---|
| **`al-aleem@1`** — *"the All-Knowing"* | Both involve Allah's comprehensive knowledge. | Al-Aleem is about knowledge of *scale* and *scope* (all things in all dimensions). This deck's move is knowledge of *intimacy* — not breadth but depth, how close Allah is to what you hide. Different grammatical subject and different object of knowledge. No shared vocabulary |
| **`al-lateef@1`** — *"the Subtle One"*, 42:19 | Both involve subtle interior work. | Subtlety here is about a *way of operating* (achieving divine purposes without force). This deck is about *proximity* and *knowledge* of what's already there. Different engines entirely — one is method, one is closeness. No shared scripture or rendered string |
| **`az-zahir@1`** (twin) | — | **Twin-diff is in Az-Zahir's draft — written once, not duplicated.** |

---

## The shared duʿā

Identical to Az-Zahir — see that deck's "The shared duʿā screen" section for full treatment. Both ids 81 and 82 render one bedtime invocation split across two duʿā pairs by the catalogue. A user who collects both Names in one session sees the same duʿā twice. Disclosed; no beat claims Name-specificity.

---

## The 57:3 note

Identical structure to Az-Zahir — see that deck's section. This deck renders only `وَٱلْبَاطِنُ` (the final epithet in the four-Name clause), with visible ellipsis both sides, immediately after Az-Zahir's `وَٱلظَّـٰهِرُ`. The closing `وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ` (Al-Aleem's territory, already shipped) is not rendered.

---

## Rejected — fetched, evaluated, and recorded so nobody re-derives it

| candidate | what it is | why refused |
|---|---|---|
| **Qur'an 57:4** | `وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ وَمَا يَنزِلُ مِنَ ٱلسَّمَآءِ وَمَا يَعْرُجُ فِيهَا` ("He is with you wherever you are… knows what descends and ascends") | **Fetched, evaluated, deliberately not used — flagged in claim file.** A strong candidate for the "interior closeness" engine (omnipresence + knowing the seen and unseen). **Not used because using 57:4 on this deck would risk collapsing the pair's semantic separation with Az-Zahir** (both would then render "outside and inside" knowledge). The pairing model (Al-Muizz/Al-Muzill) shows how to handle that: independent narratives per Name. Held free for a future drafter if the pair constraint is ever lifted |
| **Qur'an 31:20** | `نِعَمَهُۥ ظَـٰهِرَةً وَبَاطِنَةً` ("His favors, apparent and hidden") | **Refused on bar 1.** Same issue as Az-Zahir found: the referent is Allah's favors, not Allah Himself — a weaker demonstrative bar than 50:16 where Allah is grammatical subject of creating, knowing and being close. Also presents the same separation-collapse risk as 57:4 if used on both decks |
| **Qur'an 57:13** | wall passage (`بَاطِنُهُۥ فِيهِ ٱلرَّحْمَةُ`) | **Flagged as bar-5 hazard.** Same assessment as Az-Zahir: the referent is a wall's appearance, not Allah's attributes, and the same āyah contains `ٱلْعَذَابُ` (torment) |

---

## Catalogue findings — reported, **NO change recommended**

1. **Ids 81 and 82 duʿā are catalogue-identical** — already the subject of Az-Zahir's shared duʿā section. No recommendation.

2. **Id 82's `meaning` (9 words) overlaps id 98 Al-Baqi's `meaning` (10 words) at the catalogue level** — disclosed in id 82's claim file as a measured finding, not a collision within any beat. This deck's narratives and engines are independent from Al-Baqi's. No change recommended.

---

## What I could not determine, and what a verifier should attack first

1. **The `b-ṭ-n` root sweep was not independently hand-verified against an external corpus.** Per §9bq, cross-check against `corpus.quran.com` to confirm 57:3 is the primary (and 50:16's paraphrase via demonstration is the only other) place where `bāṭin` predicates Allah. No independent check performed.

2. **Hadith checking is not independent of prior drafts.** Muslim 2713a is verified by Az-Zahir's fetch of Al-Awwal's Wayback capture; no direct Shamela or printed-edition confirmation. Standing limit.

3. **The decision to avoid 57:4 is a pairing judgement, not a measurement.** I judged that using it would collapse the "outside revelations" vs. "inside knowledge" separation, but a verifier may disagree on whether this separation is actually load-bearing or merely aesthetic.

4. **The rows to attack first, in order:** (a) whether beat 6's disclosed non-bar-1 status is acceptable (same concern as Az-Zahir, given task brief's 57:3 warning); (b) whether 50:16 really carries bar 1 cleanly on its own without ambiguity (it should, but verify the grammatical subject); (c) whether the pairing constraint is justifiable on the five grounds stated in id 82's claim file, or whether enforcement in the gate is necessary and sufficient.

5. **The enforceability of the must-pair ruling** is the same unresolved engineering question as Az-Zahir — see the claim files and ledger §9bg for status.
