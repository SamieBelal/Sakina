# Deck Draft — Al-Mumin (wave 3, id 7)

**Status: APPROVED 2026-08-03 — signed off by Claude under authority explicitly delegated by the founder** (*"You do not need my input for most of these, I want you to use your judgment based off of the approved decks we already have"*). Basis: drafted from fetched sources, put through an independent blind adversarial pass that was instructed to refute, and every blocking finding applied. **The reviewer was not the founder — that is recorded here rather than left to be inferred from a `reviewed_by: "founder"` field kept for schema consistency with the 14 decks shipped before this delegation.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5, §7. Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Author: Claude, 2026-08-03. Claim filed **before** drafting at `.context/claims/7.md`.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4/verses/by_key`; ḥadīth via Wayback captures of the **exact bare `sunnah.com` number**. Nothing here is recalled, reconstructed or composed.

**Translation standard:** Saheeh International (`20`) unless a row states otherwise and says why. Abdel Haleem (`85`) fetched and compared on every quoted āyah.

---

## The correction this deck is built on

**Al-Mumin is the *Giver of security* — the One who makes people safe. It is not "the believer".** The catalogue's `english` ("The Guardian of Faith") points at the right idea and its `meaning` field says the thing outright: *"The One who grants safety…"*. Every beat below is about safety being **given**, never about faith as the user's act.

**Distinguishing move against shipped `as-salam@1` (Peace), which this Name collapses into most easily:** As-Salam's deck is an **interior** state — its own beat 8 says *"peace itself — the Name for what is inside you"*, its story is the stillness inside the cave at Thawr, its verse beat is *hearts find comfort*. This deck never once describes a feeling. It describes **a drawn sword over a sleeping man, and an answer that names someone who is not in the valley**, and an āyah in which Allah lists safety next to food. **Interior calm vs. external grant.** That line is held on every beat and stated on beat 8. *(R2: this paragraph originally rested on the cut *"Are you afraid of me?"* exchange — it now describes only what the deck renders.)*

---

## Deck `al-mumin@1` — Al-Mumin

**Why this deck exists, in one line:** the user who cannot stop bracing thinks the fix is to be braver. The narration puts a drawn sword over a sleeping man and records what he said when asked who could possibly stop it — and the answer is not about himself.

**Proposed metadata**

```json
{
  "deck_id": "al-mumin@1",
  "name_id": 7,
  "transliteration": "Al-Mumin",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "founder",
  "reviewed_at": "2026-08-03",
  "review_verdict": "good"
}
```

**Beat 1 · bridge:**
> You said you can't stop bracing for what might happen. This Name is not about being braver. It is about who makes a person safe.

**Beat 2 · name_intro** *(catalogue id 7 `english` verbatim + a gloss lifted verbatim from catalogue id 7's own `meaning`)*:
> الْمُؤْمِنُ — Al-Mumin — The Guardian of Faith — the One who grants safety

**Beats 3–5 · story — "The sword on the thorn tree":**

> **3.** On the way back from Najd, midday caught them in a valley thick with thorn trees. Everyone scattered into the shade. The Prophet ﷺ lay down under one, hung his sword on a branch, and slept.
> *(source line: Sahih al-Bukhari 2910)*

> **4.** A man took the sword down and drew it. "…Then who will protect you from me?" "Allah will protect me from you."
> *(source line: Sahih Muslim 843a)*

> **5.** In Bukhari's route the answer is one word — "Allah" — and he says it three times. Neither route narrates a miracle. His companions closed in, the man sheathed the sword and hung it back up, and the Prophet ﷺ did not punish him.
> *(source line: Sahih al-Bukhari 2910 · Sahih Muslim 843a)*

> *(**Revision 2, 2026-08-03 — two blocking fixes from the independent verifier, plus three non-blocking ones.** (a) **Beat 4's opening exchange — *"Are you afraid of me?" "No."* — is cut**, and the beat now opens on a **visible leading ellipsis** marking the elided dialogue. This is the escape hatch R1 itself offered, ruled **BLOCKING** rather than optional; the reasoning is in the rendered-English table, and the cost — losing the direct `khawf` bind — is absorbed by beats 1 and 6, which still carry it. (b) **Beat 5's *"He said it three times"* was a cross-route conflation and is corrected.** Bukhārī's `ثَلاَثًا` attaches to the **one-word answer `اللَّهُ`**; Muslim's full sentence is said **once**. R1's beat 4 ended on Muslim's sentence and beat 5 said he said *it* three times — **a thing no ṣaḥīḥ route reports.** R1's defence, that beat 5 did not attribute it to Muslim, was **false as rendered**: the source line named both collections and nothing on screen separated the clauses. The route is now named on the beat. (c) *"only"* removed from beat 5 — it overclaimed, since both routes do report more (see the successor table's new ḥadīth rows). (d) *"reports a miracle"* → *"narrates a miracle"*, to say precisely what is meant. (e) The two routes' **settings** are now disclosed as blended — see row 1.1a.)*

**Beat 6 · verse** *(excerpt — the leading ellipsis is on the beat because 106:4 grammatically continues 106:3)*:
> "…Who has fed them, [saving them] from hunger and made them safe, [saving them] from fear." — Qur'an 106:4

**Beat 7 · duʿā** *(catalogue id 7, verbatim in full — **no `source`**, see the ship-gate note)*:
> اللَّهُمَّ ثَبِّتْنَا عَلَى الْإِيمَانِ
> *Allahumma thabbitna 'alal-iman*
> "O Allah, make us firm upon faith."

**Beat 8 · takeaway:**
> He did not answer that he was brave. He answered by naming who was protecting him. And the ayah counts being made safe alongside being fed — safety is not something you rise to. It is something you are given.

---

## The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **106:4 — `وَءَامَنَهُم مِّنْ خَوْفٍ`.** A **finite verb of Allah's own action** from the Name's own root `ʾ-m-n` (form IV, *He made them safe*), with an explicit object (*them*) and an explicit thing they were made safe from (*fear*). It is not a trailing epithet, it is not a predicate adjective, and it is not asserted by this deck's prose — the āyah's whole grammatical spine is *the One who fed them … and made them safe*. This is the same shape the ledger records as **bar 1's strongest form** for `al-afuw@1` (42:25's `وَيَعْفُوا۟`). | **yes — beat 6** |
| 2 | **the distinguishing quality is shown, not stated** | The quality being distinguished is **safety as a grant, not composure as a state**. It is *shown* three ways and asserted nowhere: (a) the man is **asleep** when the sword is taken — he contributes nothing; (b) asked who could possibly protect him, he answers with **a subject that is not himself** — `اللَّهُ يَمْنَعُنِي مِنْكَ`, *Allah protects me from you*; (c) the āyah puts `ءَامَنَهُم` in **grammatical parallel with `أَطْعَمَهُم`** — being made safe is listed in the same clause structure as being fed. Nothing on any beat describes a feeling, a mood or a mindset. **R2 note:** argument (b) in R1 rested on the cut *"Are you afraid of me?" "No."* exchange. It has been **re-grounded on the clause that survives**, which carries the bar at least as well: the question `فَمَنْ يَمْنَعُكَ مِنِّي` invites a claim about **himself**, and the answer names **someone else**. Beat 8 rests on the same clause and was verified by the reviewer to still land without the cut exchange. | **yes — beats 3, 4 and 6** |
| 3 | **does not collapse into a sibling Name** | **Run in Arabic roots AND rendered English against all 24 ledger decks — see the two tables below.** Arabic: `s-l-m` appears nowhere in any quoted text; `w-k-l`, `ḥ-f-ẓ`, `r-ḥ-m`, `gh-f-r`, `ʿ-f-w` appear nowhere. English: **R1 failed this bar and R2 fixes it.** A **three-beat consecutive run** against shipped `al-wakeel@1` was ruled **BLOCKING** — R1 found two of its rows, filed them as unrelated findings, and could not see the third because its method matched long phrases and no long phrase was shared. **Beat 4's *"Are you afraid of me?" "No."* is cut**, removing the corpus hapax at the centre of the run. Residual, both disclosed: **"Guardian"** (catalogue-level, unfixable at deck level) and **"protect"** (adjacent-beat lexical family, unrewordable without misquoting). A **token-frequency pass** is now run in addition to the phrase pass. | **yes — after the R2 fix; see the run table** |
| 4 | **the Name's own root appears in the source text** | **Yes, twice, and one of them renders in Arabic.** `ءَامَنَهُم` (106:4, verse beat) and `ٱلْإِيمَانِ` (the duʿā beat, which renders Arabic on screen). **No trade needed on this deck.** | **yes — beats 6 and 7** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **`verses/by_key/106:5` returns HTTP 404 — 106:4 is the final āyah of Sūrat Quraysh.** All four āyāt of the sūrah were fetched: **there is no warning, no rebuke and no punishment anywhere in it.** This is the maximal available form of bar 5, the same signal that carried `al-haleem@1`'s 35:45 and `al-qadir@1`'s 75:40. **One backward disclosure is made below**, about the *preceding sūrah*. | **yes — verified** |

---

## Successor sweep — what comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **106:4** (n+1) | **`api.quran.com/api/v4/verses/by_key/106:5` → `{"status": 404, "error": "Ayah not found"}`.** 106:4 is the last āyah of Sūrat Quraysh. | **clean — no successor exists.** |
| **106:4** (n−1) | 106:3 — *"Let them worship the Lord of this House,"* | **clean, and it is why the beat opens on an ellipsis.** 106:4 begins `ٱلَّذِىٓ` — a relative pronoun whose antecedent is *the Lord of this House* in 106:3. The āyah is grammatically the second half of 106:3's sentence. **Abdel Haleem confirms the tell the plan names: he renders 106:4 opening lower-case — *"who provides them with food…"***. The leading `…` on beat 6 is therefore required, not decorative. |
| **106:4** (the excerpt's own tail) | The quotation runs to the āyah's **final word**. Nothing whatever is omitted from the right-hand side. | **clean — nothing withheld.** |
| **106:1–2** (the whole sūrah, read rather than scanned) | 106:1 *"For the accustomed security of the Quraysh -"* ; 106:2 *"Their accustomed security [in] the caravan of winter and summer -"* | **clean, and confirming.** `لِإِيلَـٰفِ` / `إِۦلَـٰفِهِمْ` are the same root `ʾ-l-f` (habituation), and Saheeh International renders both as ***security***, so the sūrah's opening word and its closing verb are the same subject. **Sūrat Quraysh is four āyāt about being kept safe, and nothing else.** |
| **Ṣaḥīḥ Muslim 843a — the ḥadīth's own continuation** ⚠️ **NEW IN R2** | **It continues, and R1's sweep had no ḥadīth row at all.** After the man sheathes the sword, the narration runs straight on: *"Then call to prayer was made and he (the Holy Prophet) led a group in two rakʿah. Then (the members of this group) withdrew and he led the second group in two rakʿah…"* — i.e. **ṣalāt al-khawf, the prayer of fear**, which is what Muslim is actually reporting this narration for. Muslim files the whole thing under **`باب صَلاَةِ الْخَوْفِ`** in Kitāb Ṣalāt al-Musāfirīn. | **clean, and it must be stated.** The continuation **contradicts no beat** and contains no punishment — it is a prayer ruling. **But R1 claimed the story's ending and never said the story does not end there**, which is the same species of omission the ellipsis rule exists for. Two things follow. (1) **The deck stops at a real narrative boundary, not an arbitrary one** — the sword episode closes and a legal report begins. (2) **The chapter title is `khawf`.** The word this deck's verse beat turns on is the heading Muslim files the story under. That is a point in the selection's favour and R1 should have found it. |
| **Ṣaḥīḥ al-Bukhārī 2910 — its book placement** ⚠️ **NEW IN R2** | Kitāb al-Jihād wa's-Siyar, chapter *"Whoever hung his sword on a tree at midday nap"* (`باب مَنْ عَلَّقَ سَيْفَهُ بِالشَّجَرِ فِي السَّفَرِ عِنْدَ الْقَائِلَةِ`). | **disclosed.** The narration sits in the book of military expeditions. **There is no fighting, no killing, no punishment and no curse in the text itself** — it is a rest stop, a question and one word — so bar 5's register test is met on the passage. But a founder opening the URL lands on *"Fighting for the Cause of Allah"* at the top of the page, and should not meet that for the first time at review. |
| **backward, across the sūrah boundary** | 105:5 — *"And He made them like eaten straw."* | **⚠️ disclosed, non-blocking.** The **preceding sūrah** (al-Fīl) is a destruction narrative, and classical exegesis reads 106:1 as continuing from it. **No word of it is on any beat, and this deck's story is not the Elephant.** But a founder who opens `quran.com/106/4` and scrolls up crosses a sūrah boundary into a punishment passage, and the ledger's precedent (`al-haleem@1`'s 35:44, `al-qadir@1`'s 75:31–35) is to say so rather than let it be found at review. |

---

## Bar 3 · the Arabic-root sweep

| root | where it appears in this deck's quoted texts | renders in Arabic on screen? |
|---|---|---|
| `ʾ-m-n` (**the Name's own**) | `وَءَامَنَهُم` (106:4) · `ٱلْإِيمَانِ` (duʿā) | duʿā: **yes**. Verse beat: no (English-only verse beat, per plan §7's convention for new decks). |
| `ṭ-ʿ-m` | `أَطْعَمَهُم` (106:4) | no |
| `kh-w-f` | `خَوْفٍ` (106:4) · `أَتَخَافُنِي` (Muslim 843a) | no — both on English-only beats |
| `m-n-ʿ` | `يَمْنَعُكَ` / `يَمْنَعُنِي` (Muslim 843a) | no |
| `th-b-t` | `ثَبِّتْنَا` (duʿā) | **yes** |
| `ʾ-l-f` | `لِإِيلَـٰفِ` (106:1–2) | quoted nowhere |

**Absent from every beat, in Arabic and in English:** `s-l-m` (As-Salam, **shipped**), `w-k-l` (Al-Wakeel, **shipped**), `ḥ-f-ẓ` (Al-Hafeez, 39), `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `j-b-r`, `b-ṣ-r`.

**Root-level adjacencies disclosed:**
- **`m-n-ʿ` is Al-Māniʿ's root (id 94, "The Withholder").** It is the verb of the story's central question (`مَنْ يَمْنَعُكَ مِنِّي`) and of its answer. It is **off-screen in Arabic** (story beats carry `arabic: ""`) and its **English on the beat is *"protect"*, not *"withhold"***, so it does not touch id 94's gloss. Recorded for whoever drafts 94.
- **`th-b-t` + `ʾ-m-n` together are also id 85 Al-Barr's duʿā** (`يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا`). Al-Barr is undecked and unclaimed. The ledger's ≥3-word run computation returned **no hit** for id 7 (the shared material is `ثَبِّتْنَا` / `ثَبِّتْنِي` + `عَلَى`, a two-word run with a different pronoun). **Non-blocking today; a flag for whoever takes 85.**

---

## Bar 3 · the rendered-English sweep

**⚠️ R1's METHOD WAS BROKEN, AND THIS IS THE CORRECTION.** R1 substring-matched **long candidate phrases** against every rendered string. That method **structurally cannot detect a single-token overlap**, and the verifier proved it: R1 missed a third collision in the same three-beat run it had already half-found, and reported the two halves it did find as **two unrelated findings on separate rows**. R2 therefore adds a **token-frequency pass** — every rendered string tokenised, every token counted across all 24 decks with its beat locations — which is the check that finds hapaxes. **Two further findings surfaced from the token pass alone and are reported below; neither was visible to R1's method, and one of them is in the sibling draft.**

**Method, as now run:** every `primary`, `label`, `source` and `translation` string of **all 24 decks in `assets/content/name_stories.json`** was loaded, 2026-08-03 — **425 non-empty strings by this counting**; the verifier's independent count is **473**, and the difference is a counting-method difference (which fields are enumerated), not a disagreement about content. Both long-phrase substring matching **and** per-token frequency were run. Not eyeballed.

**Zero hits anywhere, phrase pass AND token pass:** *"hung his sword"* · *"thorn"* · *"scattered into the shade"* · *"who will protect you from me"* · *"Allah will protect me from you"* · *"three times"* · *"did not punish"* · *"sheathed"* · *"closed in"* · *"fed against"* / *"being fed"* · *"grants safety"* · *"bracing"* · *"who makes a person safe"* · *"not something you rise to"*. **Token counts across all 24 decks, from the new pass:** `sword` **0** · `brave` **0** · `safe` **0** · `safety` **0** · `miracle` **0** · `punish` **0** · `thorn` **0**. **`afraid` is no longer in this deck** — see the ruling below.

### The finding that changed the deck: a **three-beat consecutive run** against shipped `al-wakeel@1` — **RULED BLOCKING**

R1 found two of these, filed them as unrelated rows, and never saw the third. Set out as the verifier set them out, with **this document's own 1-based beat indices** and the token counts that make the middle row decisive:

| `al-wakeel@1` (**shipped**) | this deck, R1 as drafted | token evidence |
|---|---|---|
| **b2** `name_intro` — *"The Trustee — **the Guardian** you hand your affairs to"* | **b2** `name_intro` — *"**The Guardian of Faith** — the One who grants safety"* | `guardian` **n=2** across 24 decks (`al-wakeel@1` b2, `al-waliyy@1` b7 duʿā) |
| **b3** story — *"…and were told to be **afraid**. They were not."* | **b4** story — *"Are you **afraid** of me?" "No."* | **`afraid` is a corpus hapax: n=1 across all 24 decks.** R1's deck would have been the **only other occurrence**, doing the **identical job** — staging an invitation to fear and its refusal. |
| **b4** story — *"…and He is the best **Protector**."* | **b4** story — *"who will **protect** you from me?" / "Allah will **protect** me from you."* | `protect` **n=0** (this deck would introduce it); `protector` **n=2**; `protecting` **n=1**. **Same lexical family, adjacent beats. R1 never saw this row** — its method matched long phrases, and no long phrase is shared. |

**Ruling accepted, and applied.** R1's defence — that the two beats resolve in opposite directions (ḥasbunallāh, the believers' own act, vs. an attribution to someone else) — was **verified as correct and found insufficient**, on an argument this deck now adopts: **a difference in resolution does not undo a repetition in staging, because beats land one at a time.** And the argument that settles it: **half the run is unfixable.** *"The Guardian of Faith"* is catalogue id 7's own `english` — the *Restorer* class, which no deck can edit. **Precisely because that half cannot be fixed, the fixable half must be.**

**What changed:** beat 4's *"Are you afraid of me?" "No."* is **cut**, and the beat opens on a visible ellipsis. `afraid` no longer appears anywhere in this deck. **The escape hatch was tested before being applied** — the objection that it orphans beat 8 was raised and retracted on checking: bravado was an available answer to `فَمَنْ يَمْنَعُكَ مِنِّي` and was not taken, so *"He did not answer that he was brave"* still lands on the clause that remains.

**What remains after the fix, and is a founder call, not a drafting one:**

| residue | position |
|---|---|
| **b2 *"Guardian"*** — unchanged and unfixable at deck level. | The gloss *"— the One who grants safety"* is what pulls the reading off Al-Wakeel's trustee sense. **Option in one line:** drop the gloss and render catalogue id 7's string bare, at the cost of the *faith-as-your-act* drift this deck exists to prevent. **Better option, outside this deck:** the same catalogue decision that *Restorer* (ids 9/68) is already waiting on. |
| **b4 *"protect"*** — retained. | `يَمْنَعُكَ` / `يَمْنَعُنِي` is the narration's own verb and the deck's load-bearing line; **rewording it would be misquoting.** With the middle row gone this is no longer part of a run — it is one adjacent-beat lexical-family overlap, disclosed. |

### Two further findings, surfaced only by the new token pass

| finding | severity | position |
|---|---|---|
| **`question` is a corpus hapax — n=1, at shipped `al-baseer@1` b3** (*"She asked one **question**: has Allah ordered this?"*). The sibling draft `ar-raqeeb@1`'s beat 8 opens *"He asks a **question** He does not need the answer to."* **`al-baseer@1` is precisely the deck that draft was told to check first.** | **disclosed; judged non-blocking; self-found.** | Reported here because it is the same *class* as the `afraid` ruling and was found by the method that ruling forced. It is judged differently on the facts: the two uses have **opposite subjects and opposite functions** — a human asking in order to learn, versus Allah asking **while not needing to learn** — there is no run, and no shared multi-token phrase. **Disclosed in full in the `ar-raqeeb@1` draft, with a one-line alternative, alongside the mandated `al-ghafur@1` disclosure that bears on the same beat.** |
| **"My servants"** on shipped `al-ghaffar@1` b6. Token `servants` is **n=4** (`al-ghaffar@1`, `al-lateef@1`, `al-afuw@1`, `al-haleem@1` — all verse beats), so the token is **common, not rare**; the narrower finding is the two-word run. | non-blocking. | Not a string in **this** deck — carried in the sibling `ar-raqeeb@1` draft, where it is disclosed. R1 reported this as though the token were notable; the token pass shows it is not. |

**Insight-engine check (ledger §3a).** This deck's engine is **`safety is provision, not composure`**. Diffed against all 18 spent engines in §3a: no match. The nearest live neighbours and why they do not collapse:

| neighbour | why it is not the same insight |
|---|---|
| `as-salam@1` beat 8 (**shipped**) — *"peace itself — the Name for what is inside you"* | That is an **interior** claim. This deck's is that safety is **exterior and issued**, filed by the āyah next to a meal. The two are complementary, not duplicate — and this deck never uses the words *peace*, *calm*, *still* or *serenity*. |
| `al-wakeel@1` beat 8 (**shipped**) — *"Handing them over is not giving up"* | Direction of travel is **opposite**: Al-Wakeel is about what you **give away**; Al-Mumin is about what you are **given**. Deliberately avoided the verb *hand* on beat 8 for this reason. |
| `ar-razzaq@1` (**shipped**) — *"about what reaches you"* | Nearest real hazard, because both Names are provision-shaped. Held apart by **what** is provided: rizq (what arrives) vs amn (a threat's removal). This deck does not use *provide*, *provider*, *provision* or *reaches* on any beat. |
| `as-samad@1` beat 8 (**shipped**) — *"leaning is not weakness"* | About **dependence** being legitimate. This deck makes no claim about the user's posture at all. |

---

## Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | **Beat 3** — Najd expedition; the return; midday in a valley of thorn trees; the people scattering into the shade; the Prophet ﷺ under a tree with his sword hung on it; sleeping | **labelled paraphrase** of the narration's opening, no quotation | [Sahih al-Bukhari 2910](https://sunnah.com/bukhari:2910) | **ṣaḥīḥ** (Ṣaḥīḥ al-Bukhārī) | ✅ **verified by live fetch** — Wayback capture `20230401175309` of the exact bare number `bukhari:2910`, 2026-08-03 (sunnah.com 403s automation). Arabic on the page: `غَزَا مَعَ رَسُولِ اللَّهِ ﷺ قِبَلَ نَجْدٍ … فَأَدْرَكَتْهُمُ الْقَائِلَةُ فِي وَادٍ كَثِيرِ الْعِضَاهِ … وَتَفَرَّقَ النَّاسُ يَسْتَظِلُّونَ بِالشَّجَرِ، فَنَزَلَ رَسُولُ اللَّهِ ﷺ تَحْتَ سَمُرَةٍ وَعَلَّقَ بِهَا سَيْفَهُ`. Every element of the beat is in that sentence. In-book: Book 56, Hadith 123. |
| 1.1a | **Beats 3–4 blend the two routes' SETTINGS** ⚠️ **NEW DISCLOSURE IN R2** | — | both | n/a | ✅ **honest label — R1 did not disclose this and should have.** Beat 3's setting is **Bukhārī's**: an expedition *"towards Najd"*, `الْقَائِلَة` (the midday nap), a valley `كَثِيرِ الْعِضَاهِ` (thick with thorn trees), a `سَمُرَة` (thorn tree). Beat 4's dialogue is **Muslim's**, and Muslim names the place **`بِذَاتِ الرِّقَاعِ` (Dhāt ar-Riqāʿ)** and its tree simply `شَجَرَةٍ ظَلِيلَةٍ` (a shady tree the Companions left for him) — **it says nothing about Najd, nothing about midday, and nothing about thorn trees.** The deck therefore renders one continuous scene assembled from two routes' details. **Nothing invented, nothing contradicted** — the two are classically understood as the same episode, and the deck names both collections on the beats — but the *reader* meets a single valley, and the founder should know that valley is composite. **One-line alternative:** drop *"from Najd"* and *"thick with thorn trees"* from beat 3, leaving *"midday caught them on the road"*, which is common ground. Not taken, because the thorn valley is the more vivid and it is Bukhārī's own word. |
| 1.2 | **Beat 3** — *"and slept"* / the sword taken while he was asleep | paraphrase | [Sahih al-Bukhari 2910](https://sunnah.com/bukhari:2910) | **ṣaḥīḥ** | ✅ **verified** — same fetch. The Prophet's ﷺ own reported words: `إِنَّ هَذَا اخْتَرَطَ عَلَىَّ سَيْفِي وَأَنَا نَائِمٌ، فَاسْتَيْقَظْتُ وَهْوَ فِي يَدِهِ صَلْتًا` — *"this man drew my sword on me while I was asleep; I woke and it was unsheathed in his hand."* **The sleeping detail is Bukhārī's and is absent from Muslim 843a** — which is why this deck uses both routes and says which is which. |
| 1.3 | **Beat 4**, quoted: "…Then who will protect you from me?" / "Allah will protect me from you." | **Re-rendered from the page's Arabic**, per plan §6 rule 2, **not** pasted from the published English. Reason stated in the Status cell. | [Sahih Muslim 843a](https://sunnah.com/muslim:843) | **ṣaḥīḥ** (Ṣaḥīḥ Muslim) | ✅ **verified by live fetch** — Wayback capture `20251011123543`. **⚠️ Number discipline, per the `muslim:2653`/`2653b` precedent: the bare URL `sunnah.com/muslim:843` resolves to the page whose own reference line reads *"Sahih Muslim 843a"*. This deck cites 843a, not 843.** Arabic: `فَقَالَ لِرَسُولِ اللَّهِ ﷺ أَتَخَافُنِي قَالَ "لاَ" . قَالَ فَمَنْ يَمْنَعُكَ مِنِّي قَالَ "اللَّهُ يَمْنَعُنِي مِنْكَ"`. **Published English, fetched verbatim for comparison: *"Are you afraid of Me? He (the Holy Prophet) said: No. He again said: Who would protect you from me? He said: Allah will protect me from you."*** Two reasons it was re-rendered rather than pasted: (a) it capitalises **"Me"** for the attacker, which on a beat about Allah's protection is a genuine theological misread of a typographic slip; (b) *"Who would protect you"* is archaic where `يَمْنَعُكَ` is plain imperfect. **The one line that carries the deck — *"Allah will protect me from you"* — is the published English verbatim, unchanged.** No word is added or reordered. **⚠️ R2 — ELISION, DISCLOSED ON THE BEAT, NOT ONLY HERE.** The narration's first exchange — `أَتَخَافُنِي` / `لاَ`, *"Are you afraid of me?" "No."* — **is dropped**, for the bar-3 reason ruled blocking above and for no source-critical reason. **Beat 4 therefore carries a visible leading ellipsis inside the quotation marks**, exactly as beat 6 does for 106:4, so the user is told the dialogue began earlier. The retained `فَ` in *"Then"* is the narration's own connective and now points at the elided exchange rather than at nothing. **Nothing else in the quoted region is changed.** |
| 1.4 | **Beat 5** — *"In Bukhari's route the answer is one word — 'Allah' — and he says it three times"* | paraphrase, with the route named **on the beat** | [Sahih al-Bukhari 2910](https://sunnah.com/bukhari:2910) | **ṣaḥīḥ** | ✅ **verified — and this row records a REAL R1 ERROR, corrected.** Bukhārī's text: `فَقَالَ مَنْ يَمْنَعُكَ مِنِّي فَقُلْتُ "اللَّهُ" ‏‏.‏ ثَلاَثًا` — **`ثَلاَثًا` attaches to the one-word answer `اللَّهُ`.** Muslim 843a's answer is the **full sentence** `اللَّهُ يَمْنَعُنِي مِنْكَ`, said **once**. **R1's beat 4 ended on Muslim's sentence and R1's beat 5 said *"He said it three times"* — a cross-route conflation asserting something no ṣaḥīḥ route reports.** R1's defence in this very row (*"beat 5 does not attribute it to Muslim"*) was **false as rendered**: beat 5's source line named **both** collections and nothing on screen separated the clauses. **The fix names the route on the beat and restores what `ثَلاَثًا` actually counts.** Recorded rather than quietly patched, because a verification table that defended the error is worse than the error. |
| 1.4a | **Beat 5** — *"Neither route narrates a miracle"* | authored, and load-bearing | both routes | n/a | ✅ **honest label — R2-corrected.** R1 read *"Neither narration reports a miracle — **only** that his companions closed in…"*. **The *"only"* overclaimed**: both routes report more than the clauses listed (Bukhārī continues in Kitāb al-Jihād; **Muslim runs straight on into ṣalāt al-khawf** — see the new ḥadīth rows in the successor table). *"only"* is removed and the sentence split. *"reports"* → *"narrates"*, because the claim being made is specifically that **no route narrates a miraculous event**, which the verifier independently confirmed on both pages. |
| 1.5 | **Beat 5** — *"his companions closed in, the man sheathed the sword and hung it back up"* | paraphrase | [Sahih Muslim 843a](https://sunnah.com/muslim:843) | **ṣaḥīḥ** | ✅ **verified** — same fetch: `فَتَهَدَّدَهُ أَصْحَابُ رَسُولِ اللَّهِ ﷺ فَأَغْمَدَ السَّيْفَ وَعَلَّقَهُ`. **This is included deliberately and is the deck's most important honesty decision.** The popular retelling of this story has the sword fall from the man's hand. **Neither ṣaḥīḥ route says that.** Omitting the Companions in order to leave a miracle-shaped hole would be exactly the elision batch 2 was rejected for. Beat 5 therefore states outright that **no miracle is narrated**, and the deck's claim rests where the text puts it: on the answer given while the blade was drawn. |
| 1.6 | **Beat 5** — *"the Prophet ﷺ did not punish him"* | paraphrase of `وَلَمْ يُعَاقِبْهُ وَجَلَسَ` | [Sahih al-Bukhari 2910](https://sunnah.com/bukhari:2910) | **ṣaḥīḥ** | ✅ **verified** — same fetch. **Kept to one clause on purpose.** The ledger rejected Ṭāʾif and the bedouin-in-the-mosque from `al-haleem@1` because *"the forbearance recorded is the Prophet's ﷺ, i.e. human"*. This deck must not become a deck about the Prophet's ﷺ magnanimity. The clause is reported because it is how the narration ends and dropping it would be an elision; **no beat builds on it and beat 8 does not mention it.** |
| 1.7 | **Beat 6**, verse anchor, verbatim: "…Who has fed them, [saving them] from hunger and made them safe, [saving them] from fear." | **Saheeh International**, verbatim, translator's brackets retained. **Abdel Haleem fetched and rejected with a reason:** *"who provides them with food to ward off hunger, safety to ward off fear"* — it renders `وَءَامَنَهُم`, **a finite verb of Allah's action, as the bare noun "safety"**, which dissolves the single grammatical fact this deck's bar 1 rests on. Rejected. | [Qur'an 106:4](https://quran.com/106/4) | Qurʾān | ✅ **verified by live fetch** — `api.quran.com/api/v4/verses/by_key/106:4?fields=text_uthmani,text_imlaei&translations=20,85`, 2026-08-03. Uthmānī: `ٱلَّذِىٓ أَطْعَمَهُم مِّن جُوعٍ وَءَامَنَهُم مِّنْ خَوْفٍۭ`. The fetched Saheeh string carries **no `<sup>` footnote marker**; the quotation is byte-exact after prepending the ellipsis. Both `[saving them]` brackets are the translator's own and are **retained rather than silently dropped** — dropping them would leave *"fed them from hunger"*, which is wrong English. **One-line alternative if the founder finds two bracket pairs too heavy on a beat:** a plain re-rendering from the Arabic, *"…the One who fed them against hunger and made them safe from fear."* Fetched, checked, and not adopted — Saheeh International is accurate here and the batch standard applies. |
| 1.8 | **Beat 7** — duʿā text, all three scripts | catalogue id 7 only — **no scripture citation claimed** | catalogue only | n/a | ✅ **verified byte-identical to `assets/content/collectible_names.json` id 7**, checked programmatically 2026-08-03 across `dua_arabic` / `dua_transliteration` / `dua_translation`. Scanned for Arabic presentation forms (U+FE70–FEFF): **none**. **Provenance: I could not locate `اللَّهُمَّ ثَبِّتْنَا عَلَى الْإِيمَانِ` as a primary narration, and I am not claiming one.** It reads as an authored catalogue invocation of the same shape as ids 75, 68 and 16. **See the ship-gate note — and note that I am explicitly making no catalogue recommendation**, per the ledger's standing rule that this artifact has been wrong in both prior batches. |
| 1.9 | **Beat 2** — `name_intro` | catalogue id 7 | catalogue only | n/a | ✅ **verified byte-identical to catalogue id 7** for `arabic` (`الْمُؤْمِنُ`), `transliteration` (`Al-Mumin`) and the English up to the em-dash (`The Guardian of Faith`). The gloss after the em-dash, *"the One who grants safety"*, is a **verbatim prefix of catalogue id 7's own `meaning` field** (*"The One who grants safety and confirms the faith of His servants."*) — it is not authored from nothing. **Precedent for a glossed `name_intro`, checked against the catalogue rather than assumed: exactly two decks do this** — shipped `al-wakeel@1` (catalogue id 35 is bare *"The Trustee"*; the deck adds *"— the Guardian you hand your affairs to"*) and drafted `al-muid@1` (catalogue id 68 is bare *"The Restorer"*; the deck adds *"— the One who brings back what is finished"*). `al-jabbar@1`'s *"— Restorer of the Broken"* and `as-samad@1`'s *"The Eternal Refuge"* are **not** glosses: both strings are verbatim catalogue `english`. This deck is the third glossed `name_intro`, and — like `al-wakeel@1`'s — its gloss is the source of a rendered-English disclosure above. |
| 1.10 | **Not on any beat, fetched and refused:** Qurʾān 24:55 — *"…and that He will surely substitute for them, after their fear, security…"* | Saheeh International | [Qur'an 24:55](https://quran.com/24/55) | Qurʾān | ✅ **verified by live fetch, and rejected on bar 5.** `وَلَيُبَدِّلَنَّهُم مِّنۢ بَعْدِ خَوْفِهِمْ أَمْنًا` is the single most on-the-nose `ʾ-m-n` clause in the Qurʾān for this Name — *fear exchanged for security*, in Allah's own emphatic verb. **The same āyah ends: *"But whoever disbelieves after that - then those are the defiantly disobedient."*** The failure is **inside the excerpt's own āyah**, not one āyah away, which is a worse form of the shape that killed Al-Ḥalīm rev 2. **Recorded so nobody re-proposes it: it is blocked, not free.** |
| 1.11 | **Not on any beat, fetched and refused:** Qurʾān 105:5 | Saheeh International | [Qur'an 105:5](https://quran.com/105/5) | Qurʾān | ✅ **verified by live fetch** — *"And He made them like eaten straw."* Fetched solely to characterise the backward direction accurately in the successor table rather than assert it from memory. **Quoted on no beat.** |

---

## The catalogue's own `hadith` field for id 7 — a real finding, and **no change is recommended**

Read from `assets/content/collectible_names.json` this pass, id 7 `hadith`:

> *"The Prophet ﷺ said: \"The believer is a mirror to his brother.\" (Abu Dawud). Al-Mumin protects faith in every heart that seeks Him."*

**I fetched it. The narration is real and the grade is good.** [Sunan Abi Dawud 4918](https://sunnah.com/abudawud:4918), Wayback capture `20211020121216`: `الْمُؤْمِنُ مِرْآةُ الْمُؤْمِنِ وَالْمُؤْمِنُ أَخُو الْمُؤْمِنِ يَكُفُّ عَلَيْهِ ضَيْعَتَهُ وَيَحُوطُهُ مِنْ وَرَائِهِ` — *"The believer is the believer's mirror, and the believer is the believer's brother who guards him against loss and protects him when he is absent."* **Grade printed on the page: Ḥasan (Al-Albani).** Kitāb al-Adab, chapter *"Regarding sincere counsel and protection"*.

**So the defect is not authenticity. It is that the card is teaching the homonym.** `الْمُؤْمِنُ` in Abū Dāwūd 4918 is **the human believer**, twice in one sentence. The card places it under **Allah's Name** Al-Muʾmin, whose meaning is *the Giver of security*. It is the precise drift the founder flagged when assigning this deck — *"do not let the English drift into faith as the user's act"* — and it is currently on the Name card the user sees, one tap from this deck.

Two smaller observations from the same fetch: the card's rendering *"a mirror to his brother"* **merges the narration's two separate clauses** (mirror; and brother-who-guards) into one; and the card's trailing sentence *"Al-Mumin protects faith in every heart that seeks Him"* is unattributed authored prose sitting inside a field the user reads as a quotation.

### ⚠️ R2 — a second field on the same card, missed in R1 because only `hadith` was audited

Catalogue id 7 `lesson`:

> *"Al-Mumin sees your sincerity even when others doubt you."*

**That is Al-Baseer's register, and there is no safety in it at all.** The verb is `sees`; the object is your sincerity; the consolation is *being perceived correctly*. Compare **shipped** catalogue id 46 (Al-Baseer) `lesson`: *"Al-Baseer witnesses your struggle even when no one else does."* — **the same construction**, down to the *"even when others / even when no one else"* tail. Al-Mumin's one-line lesson, the line under the Name on the card, teaches a shipped Name.

It is also the **exact drift this deck was assigned to correct**, expressed in the catalogue itself: id 7's `meaning` says *"The One who grants safety"* and id 7's `lesson` says He *sees your sincerity*. **The two fields on one card point at two different Names.**

**Both id 7 findings are findings. I am recommending no catalogue change and proposing no replacement text.** The ledger's standing rule is explicit: a drafter's confident recommendation to change catalogue data *"is the highest-risk artifact this pipeline produces, and it has now been wrong in both batches"* — both times proposing the opposite of the correct action. **These are findings for independent re-verification, not instructions.** Note also that this deck **cites neither field anywhere**; no beat, row or bar moves whichever way the founder decides.

**And the general lesson R1 should have drawn: `hadith` is not the only field on a Name card.** R1 audited `hadith` alone because that is the field the concurrent repair pass touched. `meaning` and `lesson` render too, and on this Name and on Ar-Raqeeb's they are where the collisions actually live.

---

## Ship-gate note — **this deck must carry NO duʿā `source`**

`renderedDuaSources` is asserted **bidirectionally** in `test/content/name_stories_ship_gate_test.dart` (read this pass, lines 234–243): an unpinned deck that grows a `source` on its `dua` beat **fails the gate**, and the test's own comment calls that *"the fabrication this whole gate exists to make impossible."*

**Therefore: `al-mumin@1`'s `dua` beat `source` must be `""`, and `al-mumin@1` must NOT be added to `renderedDuaSources`.** The deck joins the 16 unpinned decks, for the same reason `al-qadir@1`, `al-muid@1` and `al-qayyum@1` are unpinned: the catalogue duʿā is an authored invocation and a pin would assert a provenance the text does not have.

The gate's other assertions on this deck's beats, checked against the draft: `dua` and `name_intro` carry non-empty `arabic` + `transliteration` ✅; `dua` `arabic`/`transliteration`/`primary` byte-match catalogue id 7 ✅; the `verse` beat carries a non-empty `source` ✅; every beat has non-empty `primary` ✅; the spine is `bridge → name_intro → story×3 → verse → dua → takeaway` ✅; `chip_keys: []` so the pair-synergy assertion does not apply ✅. **I did not run `flutter test` — this deck is not in the asset.**

Per plan §7's transcription conventions: the verse beat is **English-only** (`arabic: ""`), matching the 11-of-14 majority; and the rendered `source` string uses ASCII **`Qur'an`**, not the macron form used in this document's prose.

---

## Authoring notes — narratives fetched, considered and refused

Recorded so the work is not repeated. **Every rejection below is a real read, not a guess.**

- **The cave of Thawr / Surāqa's sinking horse / the whole hijrah cluster.** Spent by shipped `as-salam@1`, which holds 9:40 and Bukhārī 3653. The single most obvious "Allah made him safe" narrative in the sīra is **gone**, and that is the main reason this deck went looking on a different expedition.
- **Uḥud (3:154's `أَمَنَةً نُّعَاسًا` — sleep sent down as security) and Badr (8:11).** Both are `ʾ-m-n` in Allah's own verb and both are stunning. Refused on two counts: the aftermath of Uḥud is **shipped `al-wakeel@1`'s territory** (3:172–174), and both are battle register under bar 5. 3:154 additionally turns on the hypocrites **inside the same āyah**, so an excerpt would stop short of the passage's own ending in a way that changes its meaning.
- **Ibrāhīm's duʿā for a secure city (2:126, 14:35–37) answered generations later in 106:4.** The most elegant structure available — a request for safety made in an empty valley, answered in Allah's own words centuries after the asker. Refused twice over: the empty valley **is shipped `al-baseer@1`'s Hājar**, same setting and same family; and the insight would land near `ar-raheem@1`'s spent engine *answered while unaware*. 2:126 also ends in the Fire.
- **Qurʾān 12:99 (`ٱدْخُلُوا۟ مِصْرَ … ءَامِنِينَ`).** Name's own root, and *one āyah* from shipped `al-lateef@1`'s 12:100 inside shipped `al-jabbar@1`'s sūrah. Double-blocked.
- **Qurʾān 5:67 (`وَٱللَّهُ يَعْصِمُكَ مِنَ ٱلنَّاسِ`).** The sword story's own protection clause and a tempting verse beat. The āyah ends *"Indeed, Allah does not guide the disbelieving people"* — bar 5 — and its `h-d-y` is shipped `al-hadi@1`'s.
- **Bukhārī 3612 — Khabbāb, and the rider who will travel from Ṣanʿāʾ to Ḥaḍramawt fearing none but Allah.** The most beautiful *amn* line in the corpus and arguably a better deck than this one. **Refused on register and left free:** the Prophet ﷺ prefaces it by describing believers sawn in two and combed with iron, and closes it with *"but you are hasty"* — a rebuke to a man in pain, on a surface a user meets at night. **A future drafter who can solve that opening should take it.**
- **The Elephant (Sūrat al-Fīl).** A punishment narrative. Refused on bar 5 and named in the successor table because it is the sūrah immediately before this deck's verse beat.
