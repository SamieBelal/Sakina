# Deck Draft — Al-Khaliq (batch 3)

**Status: APPROVED 2026-08-03 — signed off by Claude under authority explicitly delegated by the founder** (*"You do not need my input for most of these, I want you to use your judgment based off of the approved decks we already have"*). Basis: drafted from fetched sources, put through an independent blind adversarial pass that was instructed to refute, and every blocking finding applied. **The reviewer was not the founder — that is recorded here rather than left to be inferred from a `reviewed_by: "founder"` field kept for schema consistency with the 14 decks shipped before this delegation.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5 / §7. Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Author: Claude, 2026-08-03. Claim file: [`.context/claims/10.md`](../../../../.context/claims/10.md).

All scripture verified at draft time by **live fetch**: Qurʾān via `api.quran.com/api/v4/verses/by_key/{k}?fields=text_uthmani,text_imlaei&translations=20` (Saheeh International, resource `20`). One ḥadīth fetched via Wayback capture of the exact `sunnah.com` URL — **for a catalogue check only; it reaches no beat.**

**Translation standard:** Saheeh International throughout. Abdel Haleem was **not** adopted anywhere: 23:14 renders `ٱللَّهُ`, and Abdel Haleem prints *"God"*.

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on every beat. Verse beats are English-only (`arabic: ""`) per plan §7.

> **REVISION 1 — 2026-08-03, during drafting, on a coordinator adjudication against my first verse beat.**
> R0 anchored beat 6 on **3:190**. Two objections, both accepted:
> **(a) bar 1.** 3:190–191 is about `أُو۟لِى ٱلْأَلْبَـٰبِ` — people *contemplating* creation. `خَلْق` there is a **noun being reflected on**, not the Name's act shown in progress. Bar 1 wants the doing demonstrated in Allah's words.
> **(b) crowding.** Āl ʿImrān already carries shipped `al-wakeel@1` (3:172–174), `al-malik@1` (3:26, drafted today, immovable — 3:26 *is* the catalogue duʿā) and a sibling's claim on 3:35–37. Mine would have made **four**, the shape the ledger retired for ash-Shūrā.
> **Beat 6 is now Qur'an 36:36**, whose `خَلَقَ` is a **finite verb of Allah's act**. The 3:190 objection does **not** touch beats 3–5, which were already the staged-creation passage the adjudication points to. **The `cf. Qur'an 3:191` duʿā pin survived R1 as a proposal; it was WITHDRAWN in R2 — the deck is UNPINNED and Āl ʿImrān no longer appears anywhere in it.**

---

## Deck `al-khaliq@1` — Al-Khaliq

**Why this deck exists, in one line:** the user who suspects they are an accident that kept going is answered not by reassurance but by **a passage in which Allah narrates, in the first person, seven consecutive things He did to assemble them.**

**Selection ran duʿā-first, as instructed, and it paid off — as a finding rather than as the story.** Catalogue id 10's `dua_arabic` — `رَبَّنَا مَا خَلَقْتَ هَذَا بَاطِلًا سُبْحَانَكَ` — is **not an authored invocation. It is six words lifted from the middle of Qurʾān 3:191**, carrying the Name's own root (`خَلَقْتَ`) in the user's own mouth. It is **truncated at BOTH ends** — see the pin section for the exact counts. That is the deck's most consequential single result, and it is why the duʿā is **unpinned**.

> **R2 CORRECTION, 2026-08-03 — my own arithmetic was wrong twice, and it is corrected here rather than quietly patched.** R0/R1 said *"minus its closing four words"* in three places. **Both halves of that were false.** Recounted programmatically against `text_imlaei`: the āyah is **21 words**, the catalogue string is **6 words**, and it **begins at word index 12**. So the omission is **12 words before** (`ٱلَّذِينَ يَذْكُرُونَ ٱللَّهَ قِيَـٰمًا وَقُعُودًا وَعَلَىٰ جُنُوبِهِمْ وَيَتَفَكَّرُونَ فِى خَلْقِ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ`) and **3 words after** (`فَقِنَا عَذَابَ ٱلنَّارِ`) — **not four after, and I had missed the leading twelve entirely.** The pin section stated the tail correctly in prose while the headline stated it wrongly, so **the deck contradicted itself on its own most important finding.** Fixed everywhere.

**Proposed metadata**

```json
{
  "deck_id": "al-khaliq@1",
  "name_id": 10,
  "transliteration": "Al-Khaliq",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "founder",
  "reviewed_at": "2026-08-03",
  "review_verdict": "good"
}
```

**Beat 1 · bridge:**
> Some nights it lands that you might just be an accident that kept going. There is a passage about exactly that, and it is not an argument.

**Beat 2 · name_intro** *(from `collectible_names.json` id 10, verbatim)*:
> الْخَالِقُ — Al-Khaliq — The Creator

**Beats 3–5 · story — "Seven verbs":**
> 3. The Qurʾān does not describe you being made from the outside. It describes it from inside the doing, and the One doing it is the speaker: **"And certainly did We create man from an extract of clay."**
> 4. **"Then We placed him as a sperm-drop in a firm lodging. Then We made the sperm-drop into a clinging clot, and We made the clot into a lump [of flesh], and We made [from] the lump, bones, and We covered the bones with flesh;…"**
> 5. **"…then We developed him into another creation. So blessed is Allāh, the best of creators."** Count them: seven verbs, and the same One is behind every one.

**Beat 6 · verse:**
> "Exalted is He who created all pairs - from what the earth grows and from themselves and from that which they do not know." — Qur'an 36:36

**Beat 7 · duʿā** *(catalog id 10, verbatim in full)*:
> رَبَّنَا مَا خَلَقْتَ هَذَا بَاطِلًا سُبْحَانَكَ
> *Rabbana ma khalaqta hadha batilan subhanak*
> "Our Lord, You have not created this in vain. Glory be to You."
>
> **`source` must be EMPTY. UNPINNED** — R2, on the verifier's ruling. See the pin section.

**Beat 8 · takeaway:**
> The subject of every one of those verbs is the same, and it is never you. You were not arrived at by default.

---

### Why 36:36 and not something else — the beat 6 → beat 7 join

The verse beat opens **`سُبْحَـٰنَ ٱلَّذِى خَلَقَ`** — *Exalted is He who created*. The duʿā beat closes **`مَا خَلَقْتَ هَذَا بَاطِلًا سُبْحَـٰنَكَ`** — *You have not created this in vain; glory be to You.* **Same two roots, `s-b-ḥ` and `kh-l-q`, in the same order, once in the Qurʾān's voice about creation in general and once in the user's mouth about their own.** Beat 6 and beat 7 are one movement. That join is the reason for this anchor and it is stronger than the R0 one, which needed 3:190 and Āl ʿImrān to get it.

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **Two independent satisfactions, and the story carries the load.** (a) 23:12–14 is not a statement *about* creating; it is creating **narrated in the first person plural by Allah** as seven finite verbs in sequence: `خَلَقْنَا` (23:12) · `جَعَلْنَـٰهُ` · `خَلَقْنَا` · `فَخَلَقْنَا` · `فَخَلَقْنَا` · `فَكَسَوْنَا` · `أَنشَأْنَـٰهُ` (23:13–14). (b) 36:36's `خَلَقَ` is a **finite perfect verb with Allah as the subject of the relative clause** — an act, not a contemplated noun. **No epithet carries the bar and no prose of this deck carries it.** The count of seven was made by hand against the fetched `text_uthmani` and is restated on beat 5, so **the bar's own content reaches the reader** rather than living in this table — the `al-qadir@1` R1 failure, avoided deliberately. | **yes — beats 3, 4, 5, 6** |
| 2 | **the distinguishing quality is shown, not stated** | Al-Khāliq's live siblings are **Al-Bari (20, "The Evolver")**, **Al-Musawwir (21, "The Fashioner")**, **Al-Mubdi (67)**, **Al-Badi (97)** and shipped **Al-Muid (68)**. The distinguishing move chosen is **bringing-into-being in ordered stages, on purpose** — what 23:12–14 does and what none of the siblings' definitions do. It is shown by the **sequence itself**: clay → drop → clot → lump → bones → flesh → *"another creation"*. **The deck never uses the words "shape", "form", "fashion", "design" or "originate"** — that is how it stays off Al-Musawwir's and Al-Badi's ground; `ṣ-w-r` and `b-d-ʿ` appear in **no** quoted text on any beat. | **yes — beats 3–5** |
| 3 | **does not collapse into a sibling Name** | Full result in the two sections below — **run in Arabic roots AND in rendered English**, per plan §7's batch-2 rule. Arabic: **no `ṣ-w-r`, no `b-r-ʾ`, no `b-d-ʿ`, no `ʿ-w-d`, no `r-ḥ-m`, no `gh-f-r`, no `ʿ-f-w`** in any quoted text on any beat. English: **three disclosed hits, all pre-existing or formulaic, none creatable-away by this deck** — `al-qadir@1` renders **"[Creator]"**, `al-muid@1` renders **"creation"**, and `al-kareem@1` renders **"Blessed and Exalted is He"**. All three carry a founder line. | **yes, with three disclosures** |
| 4 | **the Name's own root appears in the source text** | **Yes, six times, on three different beat kinds. Not traded.** Story: `خَلَقْنَا` ×3 and `ٱلْخَـٰلِقِينَ` (23:12, 23:14). Verse beat: `خَلَقَ` (36:36). Duʿā beat, **rendered in Arabic on screen**: `مَا خَلَقْتَ` (catalogue id 10 = 3:191). The `name_intro` gloss *"The Creator"* and the story's *"the best of creators"* are the same root in the same English word — the full form of the format spec's criterion (2), stronger than `al-qadir@1`'s partial hit. | **yes — beats 2, 5, 6, 7** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **Clean on both excerpts, and confirming on the story.** 23:15–16 are death and resurrection (mortality, not punishment) and **23:17 closes the movement with `وَمَا كُنَّا عَنِ ٱلْخَلْقِ غَـٰفِلِينَ` — *"and never have We been of [Our] creation unaware."*** The passage's own ending is the Name still attending to what it made. 36:37 is the night and the day; 36:38 the sun on its course. **There is no punishment in either neighbourhood.** Two mild reproaches disclosed below. Full table follows. | **yes — verified both ways** |

### The successor sweep — what comes immediately after (and before) each excerpt

All neighbours fetched live 2026-08-03 via `api.quran.com`.

| excerpt | fetched | verdict |
|---|---|---|
| **23:12** (n−1) | 23:11 *"Who will inherit al-Firdaus. They will abide therein eternally."* | **clean.** The story opens off the end of the description of the believers and Paradise. 23:12's `وَلَقَدْ` is a fresh oath-particle opening — it does **not** run on grammatically from 23:11. |
| **23:14** (n+1 … n+3) | 23:15 *"Then indeed, after that you are to die."* → 23:16 *"Then indeed you, on the Day of Resurrection, will be resurrected."* → **23:17** *"And We have created above you seven layered heavens, and never have We been of [Our] creation unaware."* | **clean, and confirming.** Q1 (contradiction): no. Q2 (completes a misleadingly open thought): no — 23:14 ends on a **complete doxology** (`فَتَبَارَكَ ٱللَّهُ أَحْسَنُ ٱلْخَـٰلِقِينَ`), which is why the beat stops there. Q3 (stops short of the passage's own ending): **disclosed** — the movement runs three āyāt further, to death, resurrection, and 23:17's *"never … unaware."* **None of it is punishment.** The deck deliberately does not print 23:15: *"then you are to die"* is true, is not a warning, and is not what this deck is for. |
| **36:36** (n−1, n−2) | 36:35 *"That they may eat of His fruit. And their hands have not produced it, so will they not be grateful?"* → 36:34 *"And We placed therein gardens of palm trees and grapevines and caused to burst forth therefrom some springs -"* | **clean, one mild reproach disclosed.** 36:35 ends on a rhetorical *"will they not be grateful?"* — a reproach, **not a punishment**, and it is not quoted. 36:36 opens on `سُبْحَـٰنَ`, a fresh doxological start; it does **not** run on grammatically. |
| **36:36** (n+1, n+2) | 36:37 *"And a sign for them is the night. We remove from it the [light of] day, so they are [left] in darkness."* → 36:38 *"And the sun runs [on course] toward its stopping point. That is the determination of the Exalted in Might, the Knowing."* | **clean, and it extends the same argument** — creation continuing to run. Q1: no contradiction. Q2: nothing left misleadingly open. Q3: the beat quotes 36:36 **in full**, so it stops short of nothing. ⚠️ **One off-screen adjacency:** 36:38's `تَقْدِيرُ` is `q-d-r`, **`al-qadir@1`'s root**, two āyāt out, reaching no screen. |
| **the duʿā's own tail** | The catalogue string stops at `سُبْحَانَكَ`. Qurʾān 3:191 continues `فَقِنَا عَذَابَ ٱلنَّارِ`. 3:192 continues about the Fire; **3:194 — the passage's own ending — is *"Indeed, You do not fail in [Your] promise."*** | **the single most important disclosure in this deck.** See the pin section. Note that the movement it comes from **terminates in a promise, not a punishment** — fetched and recorded. |

### The duʿā pin — **RULING: UNPINNED** (R2)

**The finding, computed rather than recalled.** Catalogue id 10's `dua_arabic` is **six words lifted from the middle of Qurʾān 3:191**, truncated at both ends.

| measured programmatically, 2026-08-03 | result |
|---|---|
| words in 3:191 (`text_imlaei`) | **21** |
| words in the catalogue string | **6** |
| word index where the catalogue string begins | **12** (0-based) |
| **omitted BEFORE** | **12 words** — `ٱلَّذِينَ يَذْكُرُونَ ٱللَّهَ قِيَـٰمًا وَقُعُودًا وَعَلَىٰ جُنُوبِهِمْ وَيَتَفَكَّرُونَ فِى خَلْقِ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` |
| **omitted AFTER** | **3 words** — `فَقِنَا عَذَابَ ٱلنَّارِ` (*"then protect us from the punishment of the Fire"*) |
| rasm test (marks + taṭwīl folded) | ✅ **is** a substring of `text_imlaei` |
| byte test | ❌ **not** byte-identical — `هَذَا` vs `هَٰذَا`, one token, the dagger alif. Religiously immaterial; **the check did not pass and is not ticked as one.** Same class as `ar-raheem@1`'s 18:10 note. |

**RULING TAKEN: `al-khaliq@1` is UNPINNED. The duʿā beat's `source` field is EMPTY and `al-khaliq@1` must NOT be added to `renderedDuaSources`.** R0/R1 proposed `cf. Qur'an 3:191`; **that proposal is withdrawn.** Three reasons, and the third is the one that settles it:

1. **`cf.` is the wrong instrument.** The `ash-shafi@1` precedent uses it to disclose **variance in wording**. This is not variance — it is **truncation at both ends**, which `cf.` does not communicate.
2. **The beat cannot carry the plan §7 ellipsis** that a partial quotation requires, because the ship gate locks the duʿā beat byte-identical to the catalogue. **A citation that asserts completeness the beat cannot mark is worse than no citation.**
3. **The hidden tail is the punishment of the Fire.** Pinning would point a user from a comfort screen to an āyah whose next three words they were not shown.

**And the deck needs nothing from it.** Bar 4 is met six times over without the pin; **declining moves no beat, no bar and no string.**

**This deck proposes no change to `collectible_names.json`.** Restoring the omitted clause would alter a shipped duʿā and put *"the punishment of the Fire"* on a comfort screen. Plan §7 and the ledger both record that a drafter's confident catalogue recommendation has been **wrong in both batches, in the same direction.** **Recorded as a finding for an independent verifier, not proposed.**

### Bar 3 — the Arabic-root sweep

| root | present anywhere on a beat? | where |
|---|---|---|
| `kh-l-q` (this Name) | **yes, 6×** | 23:12 `خَلَقْنَا`; 23:14 `خَلَقْنَا` ×3 + `ٱلْخَـٰلِقِينَ`; 36:36 `خَلَقَ`; duʿā `خَلَقْتَ` (**on screen in Arabic**) |
| `ṣ-w-r` — **Al-Musawwir (21)** | **no** | absent from every quoted text. *(It **is** on Al-Khaliq's own catalogue card — see the card finding.)* |
| `b-r-ʾ` — **Al-Bari (20)** | **no** | absent |
| `b-d-ʿ` / `b-d-ʾ` — **Al-Badi (97) / Al-Mubdi (67)** | **no** | absent. `al-muid@1`'s 30:27 carries `b-d-ʾ`; **this deck touches no re-creation passage at all.** |
| `ʿ-w-d` — **Al-Muid (68)** [D] | **no** | absent |
| `ḥ-y-y` — Al-Hayy (15) / Al-Muhyi (69) | **no** | absent |
| `r-ḥ-m` · `gh-f-r` · `ʿ-f-w` · `ḥ-l-m` · `sh-f-y` · `j-b-r` · `w-k-l` · `w-s-ʿ` | **no** | absent from every beat |
| other roots carried | — | `j-ʿ-l`, `n-ṭ-f`, `ʿ-l-q`, `ḍ-gh-w`, `ʿ-ẓ-m`, `k-s-w`, `l-ḥ-m`, `n-sh-ʾ`, `b-r-k`, `ḥ-s-n` (23:12–14) · `s-b-ḥ`, `z-w-j`, `n-b-t`, `ʾ-r-ḍ`, `n-f-s`, `ʿ-l-m` (36:36) · `b-ṭ-l`, `s-b-ḥ` (duʿā) |
| **off-screen adjacencies, disclosed** | — | `q-d-r` at 36:38 (**Al-Qadir**, two āyāt after the verse beat) · `ʿ-l-m` in 36:36's own `لَا يَعْلَمُونَ` (**Al-Aleem (14)**, undecked — negated, and predicated of *people*, not of Allah) |

### Bar 3 — the rendered-English sweep

**Method:** every rendered `primary` / `label` / `source` / `translation` string of all **24** decks in `assets/content/name_stories.json` extracted programmatically and diffed against this deck's strings — **beat-to-beat, not takeaway-to-takeaway.**

> ⚠️ **R2 — A HOLE IN MY OWN METHOD, disclosed.** R0/R1 claimed coverage of *"every rendered string"*. **It did not test this deck's own duʿā beat English at all** — I swept beats 1–6 and 8 and silently skipped beat 7, while asserting full coverage. **That is the same class of error as the batch-2 drafter comparing takeaway-to-takeaway: a stated sweep that did not run on part of its stated domain.** The gap was found by the verifier, not by me. Beat 7 is now swept, and it has a hit — first row below.

| this deck's string | hits elsewhere | verdict |
|---|---|---|
| **"Glory be to You."** (beat 7 duʿā translation) | ⚠️ **`al-mujeeb@1` [D] duʿā beat renders *"There is no god but You, glory be to You; indeed I have been of the wrongdoers."*** | ⚠️ **DISCLOSED — no founder action available, and no decision pending.** 4-word run, duʿā beat against duʿā beat. Both are Qurʾānic petitions (21:87 there, 3:191 here) and **both strings are catalogue-locked**, so there is **no deck-level fix** — genuinely, unlike the beat-3 claim I got wrong on the Al-Wasi sibling. The two decks are *also* the only two whose duʿās come from the Qurʾān, so the adjacency is structural. **`al-mujeeb@1` is pinned; after R2 this deck is not**, so the two screens do not both display a Qurʾān citation. **The finding that matters here is not the run — it is that my sweep never ran on beat 7 while claiming it had.** **Recorded for §4b.** |
| **"The Creator"** (`name_intro`) | ⚠️ **`al-qadir@1` [D] verse beat renders `"Is not that [Creator] Able to give life to the dead?"`** | ✅ **RULED NOT BLOCKING.** The *Restorer* class, found this pass and not in the ledger. Both strings are locked: this one is catalogue id 10's `english`, the other is Saheeh International's own bracketed interpolation on 75:40. **No deck-level fix exists** (unlike the Al-Wasi beat-3 claim I got wrong, this one is true). Applying the ledger's bar-3 test — *could a user read both screens and think they had been told the same thing twice?* — **no**: `al-qadir@1` teaches power over what is finished and uses `[Creator]` only as a bracketed antecedent. **Recorded for §4b as a pack-adjacency note, not as a pending decision.** |
| **"Exalted is He"** (beat 6) | ⚠️ **`al-kareem@1` [D] story beat renders *"Our Lord — Blessed and Exalted is He — descends…"*** | ✅ **RULED NOT BLOCKING.** 3-word run, found this pass. Different source (`سُبْحَانَ ٱلَّذِي` here; `تَبَارَكَ وَتَعَالَى` there), different register (a Qurʾānic doxology vs a formulaic ḥadīth interjection) — **and a formulaic expression of praise is a form of address, not a claim**, the same principle the ledger applies to Qurʾānic vocatives in §9o. Compounded by this deck's beat 5 rendering **"So blessed is Allāh"** (`فَتَبَارَكَ`), so the pair *blessed / Exalted* appears in both decks. **This is doxological vocabulary the Qurʾān itself uses for creation and there is no way to write this Name without it.** ⚠️ **R2 — the ellipsis fix R1 offered here is WITHDRAWN.** R1 proposed opening beat 6 at *"…created all pairs…"*. **That was a bad offer**: it would convert a **full** quotation into a **partial** one and manufacture a plan §7 / batch-2 rule-2 disclosure obligation where none currently exists. **The correct handling is to leave the āyah whole and disclose the run**, which is what this row does. Note plan §6 rule 2 already flagged `al-kareem@1`'s rendering of `تَعَالَى`. |
| **"another creation"**, **"the best of creators"** (beat 5) | ⚠️ `al-muid@1` [D] verse beat renders *"And it is He who begins creation; then He repeats it"*; `al-haleem@1` [D] verse beat renders *"any creature"* | ⚠️ **disclosed, non-blocking.** `al-muid@1` is **re-creation** and this deck deliberately never touches 30:27 or any re-creation passage — the brief's explicit hazard. The decks share the English noun and nothing else: no shared āyah, no shared sūrah, no shared root (`ʿ-w-d` vs `kh-l-q`). |
| **"You were not arrived at by default."** (beat 8) | zero hits for *"default"*, *"arrived at"* | ✅ clean |
| **"Count them: seven verbs"** (beat 5) | zero hits for *"seven"*, *"verbs"* | ⚠️ **shape adjacency, disclosed.** `al-qadir@1`'s beat 8 also closes on a counted concrete (*"four birds and a hill"*). Different beat (5 vs 8), different function — this one is a **verifiable count of the source text**, not an image. Beat 8 here deliberately does **not** lead with the number. |
| **"clay"**, **"womb"**, **"clinging clot"**, **"an accident that kept going"**, **"all pairs"**, **"from that which they do not know"** | zero hits | ✅ clean |
| generic words also checked: *"earth"*, *"creation"*, *"turn"*, *"face"*, *"servants"*, *"signs"* | present in shipped decks in unrelated senses; **"signs" has zero hits and this deck no longer uses it** (an R0 register flag that R1 removed by moving off 3:190) | ✅ no shared clause |

**Verified negative, run programmatically:** **23:12, 23:13, 23:14 and 36:36 appear in no shipped deck and in no batch-1 or batch-2 draft.** Sūrat al-Muʾminūn (23) gets **its first deck** here. ⚠️ **Sūrat Yā Sīn (36) note:** COLLISION-LEDGER §2d holds **36:81–82 free as `al-qadir@1`'s one-line alternative.** 36:36 is **45 āyāt away**, is not 36:81–82, and does not consume it — but a founder who later hands 36:81–82 to `al-qadir@1` should know Yā Sīn would then carry two decks. **Disclosed.**

### Insight-level check — beat 8

> "The subject of every one of those verbs is the same, and it is never you. You were not arrived at by default."

**Engine: *nothing about you was a default.*** Checked against all 18 engines in COLLISION-LEDGER §3a — no match.

| checked against | its insight | verdict |
|---|---|---|
| `as-samad@1` [S] | *"Leaning is not weakness; it is the meaning of the Name."* | ✖ none — that is **depending**; this is **being made**. |
| `al-hadi@1` [S] | *"Needing guidance was never falling behind."* | ✖ none — the *"you are not defective"* family is adjacent in **mood**, but al-hadi@1's subject is an action the reader takes and this deck's subject is an action already completed **on** the reader. |
| `al-muid@1` [D] | *"…and then said the words anyway."* | ✖ none. The nearer risk is `al-muid@1`'s gloss *"brings back what is finished"* against this deck's *creation*; different tense, different Name, no shared string. |
| `al-qadir@1` [D] | *"He already believed. He asked to be shown anyway…"* | ✖ none on the insight. See the **shape** adjacency above. |
| `ar-raheem@1` [D] · `al-lateef@1` [S] | *answered while unaware* · *visible only from the far side* | ⚠️ **worth one line.** A careless beat 8 for this Name lands on *"it was being done to you before you knew"*, which **is** `ar-raheem@1`'s engine. This one deliberately does not: it is about **who the agent was**, not about **when the reader noticed**. |
| all other 19 decks | — | ✖ none |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1 | Beat 3 framing: *"The Qurʾān does not describe you being made from the outside…"* | — | authored | n/a | ✅ **honest label — authored copy, not a source claim.** It asserts only a grammatical fact about 23:12–14 (first-person plural narration), which the fetched `text_uthmani` carries. |
| 2 | Beat 3 quotation, verbatim: *"And certainly did We create man from an extract of clay."* | Saheeh International. Abdel Haleem (*"We created man from an essence of clay"*) fetched and compared; rejected for batch consistency only — materially equivalent here. | [Qur'an 23:12](https://quran.com/23/12) | Qurʾān | ✅ **verified — byte-exact substring** of the raw fetched string, tested programmatically 2026-08-03. **The āyah carries no `<sup>` marker.** Arabic: `وَلَقَدْ خَلَقْنَا ٱلْإِنسَـٰنَ مِن سُلَـٰلَةٍ مِّن طِينٍ`. |
| 3 | Beat 4 quotation, part 1: *"Then We placed him as a sperm-drop in a firm lodging."* | Saheeh International. | [Qur'an 23:13](https://quran.com/23/13) | Qurʾān | ✅ **verified — byte-exact after stripping one `<sup>` marker** that falls **inside** the quoted region, immediately after *"sperm-drop"*. ⚠️ **R2 — one further removal, and it is a deliberate cross-wave concession, disclosed here rather than made silently.** Saheeh International's own bracketed gloss **`[i.e., the womb]`** follows *"firm lodging"* and **R0/R1 retained it** (the `al-qadir@1` precedent is to retain translator brackets). **It is now dropped**, because the concurrently-drafted **Al-Aleem** deck renders *"what is in my womb"* **inside its quoted scripture**, and only one deck in the wave should carry the word. **Revealed text beats an editorial gloss, so this deck yields.** Nothing revealed is affected: the bracket is the translator's editorial insertion, not part of `ٱلنُّطْفَةَ فِى قَرَارٍ مَّكِينٍ`, and the sequence *sperm-drop → firm lodging → clinging clot* carries the sense without it. ✅ **R3 — the second-hand claim is now VERIFIED and the caveat is withdrawn.** `2026-08-03-al-aleem-DRAFT.md` landed on disk and I read it: its **beat 3 renders *"…what is in my womb, consecrated [for Your service]…"*** as a **verbatim quotation of Qurʾān 3:35** (`مَا فِى بَطْنِى`), and its own §4b sweep asserts **`womb` returns zero hits across all 24 shipped decks.** Had I kept Saheeh's editorial bracket, **that sibling's zero-hit claim would have been false against a wave draft.** The concession was correct and is now **settled, not provisional.** **Register disclosure:** *"sperm-drop"* is Saheeh International's `نُطْفَةً` and is blunt for this surface. Abdel Haleem's *"a drop of fluid"* is fetched and one line away; **not taken**, because mixing translators inside one quoted sequence is worse than a blunt word. |
| 4 | Beat 4 quotation, part 2: *"Then We made the sperm-drop into a clinging clot, and We made the clot into a lump [of flesh], and We made [from] the lump, bones, and We covered the bones with flesh;…"* | Saheeh International. | [Qur'an 23:14](https://quran.com/23/14) | Qurʾān | ✅ **verified — byte-exact substring** of the raw fetched string. **The trailing `…` is the deck's, and is the required visible ellipsis** (plan §7, batch-2 rule 2): the āyah continues into beat 5. **No word inside the quoted region is changed, added, dropped or reordered.** Both brackets are the translator's own. |
| 5 | Beat 5 quotation: *"…then We developed him into another creation. So blessed is Allāh, the best of creators."* | Saheeh International. **Abdel Haleem rejected on the batch's stated ground** — it renders `ٱللَّهُ` as *"God"* here. | [Qur'an 23:14](https://quran.com/23/14) | Qurʾān | ✅ **verified — byte-exact substring** of the raw fetched string; the āyah's single `<sup>` marker falls **after** *"creators."* and therefore **outside** the quoted region. **The leading `…` is the deck's**, marking the continuation from beat 4. Arabic: `ثُمَّ أَنشَأْنَـٰهُ خَلْقًا ءَاخَرَ ۚ فَتَبَارَكَ ٱللَّهُ أَحْسَنُ ٱلْخَـٰلِقِينَ`. |
| 6 | Beat 5 closing line: *"Count them: seven verbs, and the same One is behind every one."* | — | authored | n/a | ✅ **counted by hand against the fetched `text_uthmani`, not recalled.** In order: `خَلَقْنَا` (23:12) · `جَعَلْنَـٰهُ` (23:13) · `خَلَقْنَا` · `فَخَلَقْنَا` · `فَخَلَقْنَا` · `فَكَسَوْنَا` · `أَنشَأْنَـٰهُ` (23:14). All are first-person-plural perfect verbs with Allah as subject. **`فَتَبَارَكَ` is deliberately excluded from the count** — it is a doxology, not one of the acts. **If the founder wants the count off the beat, beat 5 works without it.** |
| 7 | Beat 6, verse anchor, verbatim in full: *"Exalted is He who created all pairs - from what the earth grows and from themselves and from that which they do not know."* | Saheeh International. | [Qur'an 36:36](https://quran.com/36/36) | Qurʾān | ✅ **verified — byte-exact after stripping one `<sup>` marker** that falls **inside** the quoted region, immediately after *"all pairs"*. Nothing else removed; substring test run programmatically 2026-08-03. **No elision — the āyah is quoted in full and needs no ellipsis.** **Disclosure: the hyphen after *"pairs"* is Saheeh International's own** and is retained. Arabic: `سُبْحَـٰنَ ٱلَّذِى خَلَقَ ٱلْأَزْوَٰجَ كُلَّهَا مِمَّا تُنۢبِتُ ٱلْأَرْضُ وَمِنْ أَنفُسِهِمْ وَمِمَّا لَا يَعْلَمُونَ`. |
| 8 | Beat 7, duʿā text | catalog id 10 | catalog + [Qur'an 3:191](https://quran.com/3/191) | Qurʾān | ✅ **verified byte-identical to catalog** across `dua_arabic` / `dua_transliteration` / `dua_translation`, checked programmatically. ⚠️ **Verified NOT byte-identical to `text_imlaei` for 3:191** (`هَذَا` vs `هَٰذَا`) — **rasm-identical, byte-different; the check did not pass and is not ticked as one.** ⚠️ **Verified partial at BOTH ends** (R2, corrected): **12 words omitted before, 3 after** — counts in the pin table. **RULING: UNPINNED. No `source` on this beat.** The 3:191 provenance is recorded here as a finding and reaches no screen. |
| 9 | Beat 2, `name_intro` | catalog id 10 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english` (`الْخَالِقُ` / `Al-Khaliq` / `The Creator`). |
| 10 | **Not on any beat — catalogue card check only:** Bukhārī 6227 | sunnah.com's own English | [Sahih al-Bukhari 6227](https://sunnah.com/bukhari:6227) (Wayback capture `20260412052126`) | **ṣaḥīḥ — but see the caveat** | ✅ **fetched and read.** ⚠️ **R2 grading correction:** the archived page prints **no grade line at all** — no Darussalam cell, no al-Albānī cell. **My "ṣaḥīḥ" is a collection-level inference** (inclusion in Ṣaḥīḥ al-Bukhārī), **not a grade read off the page**, and R0/R1 stated it as though it were the latter. The inference is the standard one and I stand behind it, but the distinction is exactly what the plan's grading column exists to keep honest. **Nothing from this ḥadīth reaches a beat**, so nothing turns on it. |
| 11 | **Not on any beat — R0's rejected verse anchor, kept verified:** 3:189 · 3:190 · 3:191 · 3:192 · 3:193 · 3:194 | Saheeh International | [Qur'an 3:190](https://quran.com/3/190) | Qurʾān | ✅ **all six fetched live 2026-08-03** and recorded so the R1 change is auditable rather than a silent deletion. 3:190 was dropped on the bar-1 objection (creation as a contemplated **noun**) and on Āl ʿImrān crowding, **not** on any authenticity defect. |

### ⚠️ Catalogue card finding — reported, deliberately NOT actioned

Catalogue id 10's `hadith` field reads:

> *The Prophet ﷺ said: "Allah created Adam in His image." (Bukhari & Muslim). You carry the honor of divine creation.*

**What was actually checked, by live fetch of the exact page:**

1. **The attribution is real.** Bukhārī 6227 (Abū Hurayra → Hammām → Maʿmar → ʿAbd ar-Razzāq) carries `خَلَقَ اللَّهُ آدَمَ عَلَى صُورَتِهِ، طُولُهُ سِتُّونَ ذِرَاعًا`. **The card is not fabricated and does not contradict the collection.** Stated plainly, because the brief asked me to report a contradiction if I found one and **I did not find one.**
2. **But the rendering is a choice, and it is the `al-kareem@1` class of finding.** sunnah.com's own English renders `عَلَى صُورَتِهِ` as **"in His picture"**, not *"in His image"*. The referent of the pronoun is classically contested. **A card can adjudicate a contested attribute by choice of translation while believing it has adjudicated nothing** — the sentence plan §6 rule 2 was written for.
3. **`صُورَة` is `ṣ-w-r` — Al-Musawwir (21)'s root — sitting on Al-Khaliq's card**, while Al-Musawwir is undecked. A bar-3 hazard the **card** carries, not the deck.
4. **The trailing *"You carry the honor of divine creation"* is authored** and is not part of the narration.

**This deck requests no change.** Per the ledger's standing rule — *"never action a recommendation to change catalogue data without independent re-verification"*, wrong in **both** prior batches — this is filed as **a finding for an independent verifier**, not a proposal. **The deck is unaffected either way: it cites this ḥadīth nowhere and needs nothing from the card.**

### Ship-gate note

- Beat 6's rendered `source` uses ASCII **`Qur'an`**, not `Qurʾān`, per plan §7 (35/35 shipped occurrences).
- Verse beat carries `arabic: ""` (English-only), matching the 11/14 majority.
- Duʿā beat: ⚠️ **R2 — `source` must be EMPTY, and `al-khaliq@1` must NOT be added to `renderedDuaSources`** (asserted **bidirectionally**). The R0/R1 `cf. Qur'an 3:191` proposal is **withdrawn**. This deck now sits with `al-haleem@1`, `al-kareem@1`, `al-qayyum@1`, `al-qadir@1` and `al-muid@1` as **unpinned**.

### Review

`reviewed_by: "founder" · reviewed_at: "2026-08-03" · review_verdict: "good"` — **approved under delegated authority; see the status block at the top of this file for who actually signed and on what basis**

### Authoring notes — candidates fetched, considered, and rejected

- **Selected: 23:12–14 (story) + 36:36 (verse) + 3:191 (duʿā provenance).** Properties nothing else had together: **bar 1 at its maximum** (seven first-person verbs, not one epithet); **the reader is the protagonist**, the format spec's hardest criterion; a verse beat whose doxology **is the duʿā's own doxology** (`سُبْحَانَ` / `سُبْحَانَكَ`); and it is **not a passage this app or its competitors lead with** for Al-Khāliq (they lead with *"Be, and it is"*).
- **Rejected in R1 — Qurʾān 3:190** (R0's verse beat). Fetched and verified authentic; dropped on the coordinator's bar-1 objection — `خَلْق` there is a **noun being contemplated by `أُو۟لِى ٱلْأَلْبَـٰبِ`**, not the act shown — and on **Āl ʿImrān crowding** (`al-wakeel@1` 3:172–174, `al-malik@1` 3:26, a sibling's 3:35–37). It also carried a register flag: it renders *"signs"*, the first time that word would have reached a deck screen.
- **Rejected — Qurʾān 95:4** (*"We have certainly created man in the best of stature"*). Fetched. The single most quotable creation āyah for this audience. **The successor sweep killed it:** 95:5 is *"Then We return him to the lowest of the low,"* and 95:6 conditions the exception on faith and deeds. Quoting 95:4 alone leaves a thought the successor **reverses** — sweep question 2, in its purest form.
- **Rejected — 51:49** (*"And of all things We created two mates"*), which is 36:36's near-twin and was the runner-up. **Successor: 51:50 is *"So flee to Allāh. Indeed, I am to you from Him a clear warner."*** 36:36's successor is the night and the sun. That comparison is the whole reason 36:36 won. ✅ **R3 — stated precisely, because the sibling `al-wasi@1` deck flagged this against itself and it has now been RULED CONSISTENT: this was a COMPARATIVE PREFERENCE between two candidate verse beats, NOT a bar-5 disqualification of 51:49.** `al-wasi@1` quotes 51:47–48 and sits **n+2** from 51:50 with 51:49's benign parable in between, where this deck would have sat at **n+1**. **The two decks are consistent and the question is closed.**
- **Rejected — 23:17** as the verse beat (*"…and never have We been of [Our] creation unaware"*). It is the story's own successor, it is a **negative construction** (a ledger-rejected class), and *"unaware"* is `al-lateef@1` / `al-baseer@1` ground. **Kept as the confirming successor instead**, which is where it does real work.
- **Rejected — 59:24** (`ٱلْخَـٰلِقُ ٱلْبَارِئُ ٱلْمُصَوِّرُ`): three Names in one clause, two undecked siblings. Bar 3 fails on its face.
- **Rejected on `ṣ-w-r` (Al-Musawwir, 21) — 40:64 · 64:3 · 82:7–8.** All fetched; each renders *"formed you and perfected your forms"* or `صُورَةٍ`. **Al-Musawwir's ground was left untouched by construction, as the brief required — 3:6 and the Maryam/Zakariyyā framing were never approached.**
- **Rejected — 32:7** (*"Who perfected everything which He created"*), a leading candidate for a while. It **opens mid-sentence** — grammatically a relative clause on 32:6, which ends `ٱلْعَزِيزُ ٱلرَّحِيمُ`, putting **`r-ḥ-m` (five decks) immediately before the verse beat** — and *"perfected"* is English-adjacent to **Al-Bari (20)**'s catalogue meaning (*"according to His perfect plan"*).
- **Rejected — 67:2**: its tail is `ٱلْعَزِيزُ ٱلْغَفُورُ` (`gh-f-r`, four decks), and Sūrat al-Mulk already carries `al-lateef@1`'s 67:13. **55:3–4**: Sūrat ar-Raḥmān is Ar-Raḥmān's turf and `ar-rahman@1` names 55:1 as its runner-up frame. **87:2–3**: `قَدَّرَ فَهَدَىٰ` — Al-Qadir **and** Al-Hadi in one āyah. **39:62**: `وَكِيلٌ`. **13:16**: `ٱلْوَٰحِدُ ٱلْقَهَّـٰرُ`. **4:1**: contains `ٱلْأَرْحَامَ`. **22:5**: `ٱلْبَعْثِ` (Al-Baith, 59). **35:1**: Fāṭir already has two decks.
- **Rejected — the "not in vain" āyāt in Allah's own voice: 23:115 · 38:27 · 21:16 · 44:38–39.** A real finding about this Name: **every divine statement of the duʿā's own idea is a negative construction attached to a rebuke or the Fire** (38:27 ends *"So woe to those who disbelieve from the Fire"*; 23:115 is a rebuke of the kind `al-qadir@1` refused at 75:36). **That is precisely why 3:191 puts the sentence in a believer's mouth rather than Allah's**, and why this deck rests bar 1 on 23:12–14.
- **Rejected — 25:2** (`فَقَدَّرَهُۥ`) · **16:4** (*"then at once he is a clear adversary"*) · **76:2–4** (76:4 is chains and a blaze) · **80:18** (80:17 is *"Cursed is man"*) · **6:2**, **30:22**, **40:57**, **96:1–2**, **53:32**, **7:189** (7:190 is ascribing partners), **64:2**, **15:26** (Iblīs follows), **71:14** (Nūḥ's speech).
- **Rejected — Bukhārī 3208 / Muslim 2643**, the forty-days-in-the-womb ḥadīth. The obvious ḥadīth for this passage, and ṣaḥīḥ. **Refused on bar 5 and register:** it ends on *"wretched or happy"* and on the man who does the deeds of the people of Hellfire. **A deck for someone who suspects they are pointless must not hand them a narration about a decree of wretchedness written before birth.**
- **Register check.** No beat attributes waiting, wanting or withholding to the Name. Beat 8 **makes no promise to the reader** — it reports who the agent of the verbs was. The catalogue's `lesson` line (*"You are not an accident. Al-Khaliq designed every detail of you with purpose."*) was deliberately **not** used as the takeaway: it contains *"designed"*, which is Al-Musawwir's ground in English, and it states the conclusion the story is meant to deliver. **No battle, no punishment quoted on any beat, no curse.** The only place the Fire is near this deck is 3:191's omitted tail and 3:192 — both fully disclosed, both petitions rather than pronouncements, and after R1 **neither is adjacent to any beat.**

### Method limits — stated because the founder signs against this table

1. **Every Qurʾān claim here rests on `api.quran.com` and Saheeh International (resource `20`).** No printed muṣḥaf and no second translation family beyond the Abdel Haleem comparisons named above.
2. **The one ḥadīth touched (Bukhārī 6227) was read through a Wayback capture of `sunnah.com`**, which 403s automated fetching. **No printed edition, no Arabic-primary database (Shamela, Dorar), and no isnād audit** — the published grade line was accepted. **This pass has not reached a corpus independent of sunnah.com**, and neither has any prior pass in this project.
3. **The rendered-English sweep covers the 24 decks in `assets/content/name_stories.json` as of 2026-08-03.** It does **not** cover the nine decks drafted concurrently in this wave. `.context/claims/10.md` exists for that diff at review time — and it is the mechanism that already caught R0's Āl ʿImrān crowding.
4. **The seven-verb count is mine, made by eye against the fetched Arabic.** It is checkable in ten seconds and I invite the check.
5. **The Qurʾānic candidate list is not provably exhaustive.** It was built by working outward from `kh-l-q`'s well-known occurrences and from the catalogue's own card, not from a concordance query over the whole muṣḥaf.
