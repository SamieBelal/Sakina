# `allah@1` — **Allah** (catalogue id 1, *God*) — DRAFT

**Drafted 2026-08-03**, wave 3, by the agent holding **id 1 + id 5**, **after the coordinator ruled
on the three unblockers named in my refusal.**

**Supersedes:** [`2026-08-03-allah-name-id-1-REFUSAL.md`](./2026-08-03-allah-name-id-1-REFUSAL.md)
— **kept on disk, not deleted.** Its enumerations are this deck's §4 and §9 evidence, and its three
"what would unblock it" items are now three coordinator rulings recorded in §1. **Read it for the
sweeps; read this for the deck.**
**Sibling deck:** [`2026-08-03-al-quddus-DRAFT.md`](./2026-08-03-al-quddus-DRAFT.md) — **amended by
this draft**, see §8.
**Claim files:** [`.context/claims/1.md`](../../../../.context/claims/1.md), [`5.md`](../../../../.context/claims/5.md).

All scripture fetched live via `api.quran.com/api/v4` (Saheeh International, resource `20`).
**Every quoted span was substring-tested against the fetched translation programmatically** — results
in §3. Nothing composed, reconstructed or recalled.

---

## 1 · The three rulings this deck is built on

| # | ruling | how this deck complies |
|---|---|---|
| **1** | **Mūsā may carry a third deck; Ṭā Hā may carry a second. APPROVED — the *figure* is shared, the *scene* must not be.** | **Met, and measured: ZERO 3-gram overlap between any beat of this deck and any rendered string of `al-hadi@1` or `al-haqq@1`.** §9c. The scene is the fire — neither the flight to Madyan (28:15–23) nor the magicians (20:65–70). **`al-haqq@1` filed a Mūsā-adjacency row; §9c is mine, built on the same precedent.** |
| **2** | **The "God" `name_intro` is ACCEPTED — disclose as *Restorer*-class, not blocking.** | Beat 1 renders **"God — the Name every other Name belongs to"**: catalogue id 1 `english` verbatim plus one authored gloss line (the `al-wakeel@1` / `al-muid@1` / `al-mumin@1` precedent). Disclosed at full strength in §9d **as a register inconsistency, not a bar-3 failure**. |
| **3** | **UNPINNED duʿā.** | Beat 6 carries **`source: ""`**. `allah@1` **must not** enter `renderedDuaSources`. ⚠️ **§7 was corrected 2026-08-03: the Mishkat/Razīn route IS reachable and IS a splice-match; the conclusion survives on tier-and-grading grounds, not on the original "unreachable" framing.** See §7 for the corrected reasoning and the general rule it produced. |

**Two constraints carried from the refusal and honoured:** 27:9 is **not** used (its trailing
`ٱلْعَزِيزُ ٱلْحَكِيمُ` is bar 1's failure, and **`al-azeez@1` is drafting this wave**) — **20:14 is
the anchor.** **7:180 stays BLOCKED**, recorded as blocked in §10, not passed over.

---

## 2 · The deck

| # | kind | rendered `primary` | `arabic` | `source` |
|---|---|---|---|---|
| 0 | `bridge` | Some nights there is no word for it. There is still a Name. | — | — |
| 1 | `name_intro` | **God — the Name every other Name belongs to** | `اللَّهُ` | — |
| 2 | `story` | "And has the story of Moses reached you? - When he saw a fire and said to his family, "Stay here; indeed, I have perceived a fire; perhaps I can bring you a torch…"" | — | Qur'an 20:9-10 (excerpt, marked) |
| 3 | `story` | "And when he came to it, he was called, "O Moses, Indeed, I am your Lord, so remove your sandals…"" | — | Qur'an 20:11-12 (excerpt, marked) |
| 4 | `story` | "And I have chosen you, so listen to what is revealed [to you]." What comes next is all of it, in one sentence. | — | Qur'an 20:13 |
| 5 | `verse` | Indeed, I am Allāh. There is no deity except Me, so worship Me and establish prayer for My remembrance. | — | Qur'an 20:14 (the Name, in Allah's own first person) |
| 6 | `dua` | O Allah, I ask You by every Name that belongs to You. | `اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ` | **`""` — UNPINNED, deliberately** |
| 7 | `takeaway` | He was not given an attribute. He was given the Name, and then one instruction. Every other Name you will meet is a description of the One that sentence named. | — | — |

**Beat labels:** 1 — `catalog id 1 english verbatim, plus one authored gloss line` ·
2–4 — `The fire on the road` · 5 — `quoted in full — no elision, no ellipsis` ·
6 — `catalog id 1, verbatim in full — UNPINNED, see §7`.
Beat 6 `transliteration`: `Allahumma inni as'aluka bi kulli ismin huwa lak` (catalogue, verbatim).

**Structure:** the `al-hadi@1` / `al-khaliq@1` shape — three story beats from one passage, verse beat
from the **same passage's climax āyah**. Precedent for the verse beat being the story's own last
āyah: `al-mujeeb@1` (21:87 is both a story beat and the duʿā source) and `al-muid@1` (30:27).
Beat 7 is a **plain takeaway, not a pair-synergy beat** (26 of 34 shipped decks do the same).

---

## 3 · `Claim | Source | Grading | Status`

| # | claim | source (as rendered) | URL fetched | grading | status |
|---|---|---|---|---|---|
| 1 | Beat 2's first clause is **20:9 in full** | Qur'an 20:9-10 | `api.quran.com/api/v4/verses/by_key/20:9?translations=20` | Qurʾān | ✅ **verified — `t.strip()==span.strip()` returned True.** The trailing ` -` is **Saheeh International's own** and is retained. |
| 2 | Beat 2's second clause is **20:10, exact prefix**, with a marked elision | Qur'an 20:9-10 | `…by_key/20:10?translations=20` | Qurʾān | ✅ **verified — substring test True, nothing omitted before.** **Omitted after, quoted verbatim:** ` or find at the fire some guidance."` **⚠️ This elision is load-bearing and is argued in §5. It is visible on the beat.** |
| 3 | Beat 3's first clause is **20:11 in full** | Qur'an 20:11-12 | `…by_key/20:11` | Qurʾān | ✅ **verified — full-āyah quote True.** |
| 4 | Beat 3's second clause is **20:12, exact prefix**, with a marked elision | Qur'an 20:11-12 | `…by_key/20:12` | Qurʾān | ✅ **verified — substring True.** **Omitted after, verbatim:** `. Indeed, you are in the blessed valley of Ṭuwā.` **⚠️ This is the sibling deck's root — see §8.** ⚠️ **Saheeh renders `ٱلْمُقَدَّسِ` as "blessed", not "holy"**, which is recorded because the Al-Quddus draft relies on that fact. |
| 5 | Beat 4 is **20:13 in full** | Qur'an 20:13 | `…by_key/20:13` | Qurʾān | ✅ **verified — full-āyah quote True.** The bracket `[to you]` is **Saheeh's own** and is retained (the `al-mumin@1` / 106:4 precedent). |
| 6 | Beat 5 is **20:14 in full** | Qur'an 20:14 | `…by_key/20:14` | Qurʾān | ✅ **verified — full-āyah quote True. No `<sup>`, no elision, no ellipsis.** |
| 7 | Successor sweep on 20:14 | 20:15 · 20:16 · 20:17 · 20:18 · 20:19 · 20:20 · 20:21 | each fetched individually | Qurʾān | ✅ **run — §6. This is the row to attack first.** |
| 8 | Predecessor sweep | **20:7 · 20:8 · 20:9** | fetched | Qurʾān | ✅ **run — §6. 20:8 is a significant find and is quoted on NO beat; see §7.** |
| 9 | Bar 1 enumeration — **three** āyāt in the Qurʾān have Allah naming Himself with the lafẓ in the first person | full Uthmānī text | 6,236 āyāt assembled locally from `verses/by_chapter` | Qurʾān | ✅ **run against the FULL TEXT, not a search API** (§9ac). **20:14, 27:9, 28:30 — and 79:24 is PHARAOH, 9:94 a fold false positive.** Table in the refusal §2; conclusion in §4 below. |
| 10 | Bar-3 English pass over **all 34** decks | `assets/content/name_stories.json` | local asset | — | ✅ **run — 734 rendered strings. Three disclosed 4-gram classes, all on locked scripture; §9b.** |
| 11 | **Binding condition** — scene not shared with either Mūsā deck | `al-hadi@1`, `al-haqq@1` | local asset | — | ✅ **run at n=3, not n=4. ZERO hits.** §9c. |
| 12 | Deck-internal beat-to-beat diff, all 28 pairs (§9v / §9al) | this deck | — | — | ✅ **run. Zero pairs with a ≥4-word overlap.** |
| 13 | Duʿā provenance | — | Wayback **CDX**: `sunnah.com/ahmad:3712`, `ahmad:37*`, `mishkat:2452` | — | ⚠️ **CORRECTED 2026-08-03 — original status was wrong.** ~~UNVERIFIABLE BY THIS PIPELINE~~. The Ahmad routes are genuinely unreachable (reconfirmed). **The Mishkat/Razīn route IS reachable and returns a splice-match, excluded on tier and grading, not on unreachability.** UNPINNED still stands. See §7. |
| 14 | Catalogue check: id 1's `hadith` field | Sahih al-Bukhari 2736 | `web.archive.org/web/20211224174239id_/https://sunnah.com/bukhari:2736` | ṣaḥīḥ | ✅ **verified real, correctly numbered, correctly attributed (Abū Hurayra).** ⚠️ **Finding recorded in §11. NO change recommended.** **Quoted on no beat.** |

**No claim in this table is inherited.** Every ✅ describes a command I ran.

---

## 4 · The five bars

| bar | verdict | evidence, as a measurement |
|---|---|---|
| **1 — the Name's act demonstrated in the cited text, in Allah's words** | **MET, and by the only construction that exists for this Name** | The Name `Allah` is a **proper name, not an attribute** — it has no act, so bar 1's only possible carrier is **Allah naming Himself**. Beat 5 is `إِنَّنِىٓ أَنَا ٱللَّهُ` — **the lafẓ itself, in Allah's own first person, as the predicate of a first-person nominal sentence, followed by two finite imperatives of His own (`فَٱعْبُدْنِى`, `وَأَقِمِ`).** Not an epithet, not a trailing tag, not this deck's prose. **The enumeration in §9 of the refusal shows there are exactly three such āyāt in the Qurʾān and this is the cleanest of the three.** ⚠️ **The limit, stated: I am not claiming an "act" in the sense the other 98 Names have one. I am claiming the strongest available form for a Name that is not an attribute, and saying so rather than dressing self-naming up as a deed.** |
| **2 — shown, not stated** | **MET at the story level; and the one place it could have failed is why 20:8 is NOT the verse beat** | The deck does not assert *"this is the greatest Name"* anywhere. It shows a man walking toward a fire and being **handed the Name**, in sequence: called → told whose presence it is → told he is chosen → told the Name. ⚠️ **20:8 (`ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ۖ لَهُ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ`) *states* the deck's whole thesis in one āyah, four āyāt earlier — and it is deliberately quoted on no beat.** That is bar 2 applied against my own best material; the ground that killed `al-haleem@1` rev 1 and blocked 24:35. |
| **3 — no collapse into a sibling Name** | **MET on the binding condition by measurement. THREE disclosures, all now resolved.** | §9. Binding condition (the Mūsā scene): **0 three-gram hits.** Own beats: **0 of 28 pairs.** Three 4-gram classes vs the corpus, **all on locked scripture** — the *tawḥīd* formula (§9b.2, **RULED NOT BLOCKING 2026-08-03** — a creedal formula is shared scripture, not a taught insight, per §9o; will recur on Al-Hayy/Al-Ahad/Al-Wahid), `I am your Lord` (§9b.1), and the generic duʿā opener (§9b.3). ⚠️ **And the structural risk the coordinator named — *"if beat 8 could sit on any shipped deck, it is not this deck's beat 8"* — is answered in §9e with a test, not an assurance.** |
| **4 — the Name's root in the source text** | **MET, NOT traded — at maximum** | **The Name is the source text.** `ٱللَّهُ` is the second word of beat 5 and the lafẓ is beat 1's `arabic`. There is no stronger form of bar 4 available anywhere in this project: the verse beat's operative clause **is** the Name, spoken by its Bearer. Beat 6 renders `ٱللَّهُمَّ`, the vocative of the same lafẓ, in Arabic. **Beats 2, 3, 4 do not contain it** — disclosed, and irrelevant, since the bar asks for the source text, not every beat. |
| **5 — register / reverence** | **MET — but it is an ARGUMENT, not a 404. §6a names it as the row to attack first.** | No battle, punishment or curse in any quoted text. ⚠️ **n+1 (20:15) is the Hour and n+2 (20:16) ends `فَتَرْدَىٰ` — "you [then] would perish."** Fully disclosed in §6 with the calibration. **The passage does not terminate there: 20:17–21 is the staff, and 20:21 is `خُذْهَا وَلَا تَخَفْ` — "Seize it and fear not."** The arc's own resolution is a reassurance. |

---

## 5 · The elision on beat 2 — the most consequential decision in this deck

**Omitted, verbatim:** ` or find at the fire some guidance."` (`أَوْ أَجِدُ عَلَى ٱلنَّارِ هُدًى`)

**Why it is omitted.** `هُدًى` is **shipped `al-hadi@1`'s Name-root**, `al-hadi@1` **is the other
Mūsā deck**, and its beat 3 renders **Mūsā's own speech hoping to be guided** — *"He carried no
certainty. Only this: 'I trust my Lord will guide me to the right way.'"* Rendering *Mūsā, on a road,
hoping to find guidance* would be that beat again, in a different sūrah. Applying §9o's test — *could
a user read both screens and think they had been told the same thing twice?* — **yes.** Measured:
`guide` renders **6 times**. ⚠️ **Corrected 2026-08-03 (§9ak):** the independent verifier recomputed
this and found "6 decks" was an occurrence count reported as a deck count. **The exact word `guide`
occurs 6 times across only 3 decks** (`al-hadi@1` ×2, `al-wadud@1` ×1, `ar-raheem@1` ×1, plus 2 more
recurring inside `al-hadi@1`'s own beats), `guidance` in **2** (both `al-hadi@1`). This does not
change the elision decision — the actual root cause is `al-hadi@1` rendering the same root inside the
same clause, which is untouched by the correction — but the figure is corrected here rather than left
wrong.

**⚠️ AND HERE IS THE PART A VERIFIER SHOULD PRESS ON, WHICH I AM STATING AGAINST MYSELF.**

An elision that removes *"or find at the fire some guidance"* makes it **easy** to write a deck
whose engine is *"he wasn't looking for God — he went out for a burning stick."* **That engine
would be false, and the elision would be manufacturing it.** The āyah says he hoped for **both** a
torch **and** guidance.

**So the deck does not use that engine, anywhere.**
- **Beat 4 does not say what he was or was not looking for.** It says *"What comes next is all of
  it, in one sentence"* — a claim about **20:14**, unaffected by anything in 20:10.
- **Beat 7 does not say it either.** Its subject is what he was **given**, not what he **wanted**.
- **No beat renders the words *stick*, *branch*, *looking for*, *expecting* or *instead*.**

**The elision removes a collision. It does not shape a claim.** If a verifier judges that the
elision still shapes the reading, **the one-line fix is to restore the clause and take the
`al-hadi@1` hit** — and I would rather ship the disclosure than the false engine.

**The second elision, beat 3:** `. Indeed, you are in the blessed valley of Ṭuwā.` — argued in §8.
**Both elisions are marked with a visible `…` on the beat.** (Plan §7 / batch-2 rule 2.)

---

## 6 · Successor and predecessor sweep — Sūrat Ṭā Hā

| | text | the three questions |
|---|---|---|
| **n−2 · 20:7** | *"And if you speak aloud - then indeed, He knows the secret and what is [even] more hidden."* | Clean. ⚠️ Noted: this is `al-lateef@1` / `al-aleem@1` register (*the hidden, the known*), **two āyāt before the story opens and on no beat.** |
| **n−1 · 20:8** | ***"Allāh - there is no deity except Him. To Him belong the best names."*** | **The most significant thing this sweep found, and it is a refusal.** It **states** this deck's entire thesis, and its clause `لَهُ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ` is **the catalogue duʿā's own sentence in Allah's voice**. **Quoted on NO beat.** Two reasons: **(a) bar 2** — it states what beats 2–5 show; **(b) §9v** — it renders `لَآ إِلَـٰهَ إِلَّا هُوَ`, which beat 5 already renders as `لَآ إِلَـٰهَ إِلَّآ أَنَا`. Quoting both would make this deck **repeat its own creedal clause two screens apart**, which is exactly the defect §9v found in `al-malik@1`. |
| **20:9** | *"And has the story of Moses reached you? -"* | The story's own opening. **Quoted, in full, as beat 2's first clause** — so the deck opens where the passage opens and nothing precedes it misleadingly. |
| **n+1 · 20:15** | *"Indeed, the Hour is coming - I almost conceal it - so that every soul may be recompensed according to that for which it strives."* | **Q1: no contradiction.** **Q2: nothing left misleadingly open.** ⚠️ **Disclosed: it is eschatological.** But `لِتُجْزَىٰ كُلُّ نَفْسٍۭ بِمَا تَسْعَىٰ` is **recompense in both directions** — it names no punishment and no class of people. |
| **n+2 · 20:16** | *"So do not let one avert you from it who does not believe in it and follows his desire, for you [then] would perish."* | ⚠️ **Disclosed at full strength — this is the sharpest fact in the sweep. `فَتَرْدَىٰ` is "you would perish."** Three mitigations, stated as measurements not adjectives: (a) it is **addressed to Mūsā**, the protagonist, not to a class the reader might fear belonging to; (b) it is **conditional** on being averted; (c) it is **n+2**, not the successor. |
| **n+3 … n+7 · 20:17–21** | *"And what is that in your right hand, O Moses?" … "It is my staff; I lean upon it…" … "Throw it down…" … "Seize it and **fear not**; We will return it to its former condition."* | **Q3, answered: the passage does NOT terminate at 20:16.** It continues into the staff and closes that movement on **`وَلَا تَخَفْ` — "fear not."** **The arc's own resolution is a reassurance, not a reversal** — the §9aa shape, which is the structural inverse of what killed `al-haleem@1` rev 2. |

### 6a · The bar-5 row a reviewer should attack first

**It is 20:16.** My argument is above; it is an argument. **The strongest form of bar 5 — a
sūrah-final 404 — is not available**, and I am not going to dress a three-part mitigation up as one.

**The calibration, stated so a reviewer can check the rule against itself:** shipped `al-afuw@1`
renders 42:26 ending on *"the disbelievers will have a severe punishment"* — **divine,
eschatological, aimed at a class a reader might fear belonging to** — and the ledger records it
**non-blocking**. §9aa then ruled `al-haqq@1`'s bar 5 **MET** on **20:71 — Pharaoh threatening
amputation and crucifixion, one āyah past its last story beat**. Mine sits **two** āyāt out, is
**conditional**, is **addressed to a prophet**, and is followed by *"fear not."* **A rule cannot
forbid this case while shipping those two.**

⚠️ **And the honest counter, which nobody else will state for me:** `al-haqq@1`'s bar-5 argument and
mine are now **the same argument, in the same sūrah, in the same wave.** If a reviewer tightens bar 5,
it should be tightened on both at once, not on whichever is read second.

⚠️ **Sūrat Ṭā Hā now carries two decks** — this one at 20:9–14 and `al-haqq@1` at 20:65–70,
**51 āyāt apart.** Precedent: az-Zumar at 11 āyāt, disclosed and accepted (§2c). §9b's line is
*"treat a fourth as the ash-Shūrā shape"*; Ṭā Hā carries **two**.

---

## 7 · The duʿā — UNPINNED. Reachable, and outside the tier — not unreachable.

**Beat 6 carries `source: ""`. `allah@1` must NOT enter `renderedDuaSources`. The UNPINNED conclusion
SURVIVES — on the corrected grounds below.**

**⚠️ CORRECTION, 2026-08-03, made by the independent verifier — the paragraph below is struck because
it is factually false, not because the underlying UNPINNED call was wrong:**

> ~~CDX for `sunnah.com/mishkat:2452` → empty response. Therefore this duʿā is unverifiable by this
> pipeline.~~

**The verifier re-ran the identical query. It is not empty: 7 rows, 6 of them `statuscode:200`.** The
verifier fetched the page directly
(`web.archive.org/web/20260417131107id_/https://sunnah.com/mishkat:2452`) and it renders. **The page
is *Mishkat al-Maṣābīḥ* 2452**, narrated from **Ibn Masʿūd**, **transmitted by Razīn** (outside the
six canonical books; the page prints no grade line), and its Arabic reads in full:

> `اللَّهُمَّ إِنِّي عَبْدُكَ وَابْنُ عَبْدِكَ وَابْنُ أَمَتِكَ ... أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ سَمَّيْتَ بِهِ نَفْسَكَ أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ أَوْ أَلْهَمْتَ عِبَادَكَ أَوِ اسْتَأْثَرْتَ بِهِ فِي مَكْنُونِ الْغَيْبِ عِنْدَكَ...`

**Catalogue id 1's `dua_arabic`** — `اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ` — **is a
splice** of this page's opening (`اللَّهُمَّ إِنِّي`) directly onto its `أَسْأَلُكَ بِكُلِّ اسْمٍ
هُوَ لَكَ` clause, **omitting the entire intervening servant/forelock/decree clause** — **the same
composite shape COLLISION-LEDGER §9k already names for ids 17 and 61.** I did not find this myself; I
am recording the verifier's finding here because the draft it corrects is mine.

**What survives, and on what grounds:** the UNPINNED call is unchanged, but the reasoning is now
tier-and-grading, not reachability. **Razīn is outside the six books**, and this page carries **no
grade line** — combined with the splice, this remains correctly unpinnable under this project's
sourcing tier (plan §5: *"Qur'an and canonical collections are authorities for text… grading is a
required column"*). **It is not that the pipeline cannot reach the *hamm/ḥazan* supplication. It can,
and did, and what it found is a near-match, disqualified on tier and on being a splice — not a 404.**

**What did NOT change — Musnad Ahmad remains genuinely unreachable, reconfirmed:** Wayback **CDX**
for `sunnah.com/ahmad:3712` → **zero captures**. CDX for `sunnah.com/ahmad:37*` with
`filter=statuscode:200`, collapsed → **10 archived pages, every one a 2–3 digit number**
(`ahmad:37`, `370`–`379`); **the 3,7xx range of Musnad Ahmad is not in the archive.** This route was
independently re-run by the verifier and confirmed exactly as claimed. **The Ahmad route is the
correct example of "unreachable"; the Mishkat/Razīn route was not, and should not have been described
with the same word.**

**⚠️ The general rule this error exposes, recorded because it is new and it is mine to have found the
hard way (per the verifier, whose framing I adopt verbatim because it is exactly right):**
COLLISION-LEDGER §9k already teaches not to report *"unverifiable"* as *"unsourced."* **This is the
mirror failure — reporting *"my query failed"* as *"the source is unreachable."* A tool returning
nothing tells you about your query, your encoding, or the endpoint — not about whether the text
exists. A negative retrieval result may only be reported as a property of the retrieval, and never as
unreachability, unless a second query shape and a second endpoint both come back empty.** The Ahmad
finding above meets that bar (two query shapes, `ahmad:3712` and `ahmad:37*`, both genuinely empty or
non-matching). The original Mishkat claim did not — one query, reported as a property of the source
rather than the query, and it was wrong.

**⚠️ A trap planted for the next drafter (§9w shape) — restated, now with the corrected target:**
this duʿā **will look traceable**, and now that the Mishkat/Razīn route is known to be a *reachable,
disqualified* near-match rather than a dead end, the temptation to propose a pin from it (or from
memory of the *hamm/ḥazan* supplication generally) is if anything stronger. **Do not.** It is outside
the tier and it is a splice. Four of four confident recommendations to change catalogue data in this
project have been wrong.

**⚠️ And the nearest Qurʾānic counterpart is on this deck's own doorstep and is still not a pin:**
**20:8's `لَهُ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ`** is the duʿā's sentence in Allah's voice, **four āyāt from
beat 2** — and **7:180's `وَلِلَّهِ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ فَٱدْعُوهُ بِهَا`** is that plus the
imperative to call by them. **Neither is the duʿā's source**; the duʿā is a petition, they are
declarations. **A `cf.` would assert a derivation I cannot demonstrate.** Recorded so the resemblance
is on the record as a resemblance.

**No catalogue change is recommended for id 1.**

---

## 8 · Amendment to the sibling deck — 20:12 is now partially spent

**I hold both decks, so I state this rather than let two files disagree.**

`2026-08-03-al-quddus-DRAFT.md` §10 records **20:11–14 (Ṭuwā)** as *"Blocked, not free"* and refuses
it on three grounds. **Two of those grounds are unchanged and the third has been lifted:**

| Al-Quddus's ground for refusing 20:12 | status now |
|---|---|
| **bar 1** — the holiness is predicated of **a valley**, a made thing (§9af's class) | **unchanged, and it is the load-bearing one.** |
| **Saheeh renders `ٱلْمُقَدَّسِ` as *"the blessed valley"***, so the English would not carry the word *holy* | **unchanged — verified again in §3 row 4.** |
| **blocked by the Mūsā encumbrance** | **LIFTED by the coordinator's ruling 1.** |

**So `allah@1` now spends 20:12 — the FIRST CLAUSE ONLY.** The clause carrying
`ٱلْوَادِ ٱلْمُقَدَّسِ` is **elided with a visible `…` and reaches no screen in either deck.**

**Net effect on `al-quddus@1`: none.** Its bar-4 trade rests on the enumeration of all 10 `q-d-s`
āyāt, and 20:12 was **already refused there on bar 1**. **`q-d-s` still renders on exactly one
`al-quddus@1` beat (beat 6) and on zero beats of this deck.** The Al-Quddus draft's §10 row for
20:11–14 should be read with this amendment; **its verdict does not change.**

---

## 9 · Bar 3, on all three surfaces

### 9a · Surface 1 — Arabic roots

| root | where | on a screen? |
|---|---|---|
| **the lafẓ `ٱللَّه`** | beat 5 `ٱللَّهُ`, beat 1 `اللَّهُ`, beat 6 `اللَّهُمَّ` | **yes — and that is bar 4 at maximum.** ⚠️ **The lafẓ already renders in Arabic on 17 of 34 decks and in English in 66 strings across 29 decks.** It cannot be "kept apart" and no deck could. §9d. |
| `h-d-y` (**shipped `al-hadi@1`**) | 20:10's **omitted** clause `هُدًى` | **NO — removed by the elision. §5.** |
| `q-d-s` (**`al-quddus@1`, my own sibling**) | 20:12's **omitted** clause | **NO — removed by the elision. §8.** |
| `n-w-r` (`an-nur@1`, wave 1) | `نَارًا` ×2 in 20:10 — **`n-w-r`'s sister root `n-y-r`/`nār`**, rendered *"fire"* | **English only.** ⚠️ Disclosed: `an-nur@1`'s Name is *The Light*. **`fire` renders in 2 decks** (`al-wakeel@1` — Ibrāhīm at the fire; `ar-rahman@1`); `light` renders in `an-nur@1` only. **Different word, different root vowelling, no shared n-gram.** |
| `ṣ-l-w` (prayer), `dh-k-r`, `ʿ-b-d`, `kh-l-ʿ`, `w-ḥ-y`, `kh-y-r`, `ʾ-n-s`, `q-b-s` | the quoted spans | English only |
| `gh-f-r` · `r-ḥ-m` · `ʿ-f-w` · `t-w-b` · `ṣ-b-r` · `sh-f-y` · `j-b-r` · `q-d-r` · `w-k-l` | — | **absent from every beat, Arabic and English.** Verified: `mercy` `merciful` `forgive` `pardon` `repent` `patient` `heal` `trust` all **n=0** in this deck's strings. |

### 9b · Surface 2 — token frequency over all 734 rendered strings of all 34 decks

**Beat 6's `primary` was swept from its FIRST character** (§9as). **Own-beat diff, all 28 pairs:
zero overlaps at ≥4 words.**

**Three 4-gram classes hit the corpus. All three are locked scripture. I rule on none of them alone.**

**1. `"I am your Lord"` — 4-word run, beat 3 ↔ shipped `al-wadud@1` beat 3.**
`al-wadud@1` renders the man in the desert who, out of extreme joy, **says it backwards by mistake**
(*"O Allah, You are my slave and I am your Lord"*, Muslim 2747a). Mine is **20:12, Allah speaking.**
**My view — offered as a view:** the two are not a repetition but a *contrast*, and a user reading
both would feel the second as the correction of the first, not as a second telling. **Both strings
are locked translations of different sources. ⚠️ The one-line fix exists and I am naming it so the
verifier can take it: drop 20:12 from beat 3 entirely** (beat 3 becomes 20:11 + 20:13, and the
sandals are lost). **Per §9ab I do not clear my own beat-to-beat echo.**

**2. `"There is no deity except…"` — 5-word run, verse beat ↔ shipped `al-qayyum@1`'s verse beat
(2:255), and 4-word run ↔ `al-mujeeb@1` beat 3 (21:87). ⚠️ THIS NEEDED A STANDING RULING AND I
REQUESTED ONE, NOT MADE ONE. RULED 2026-08-03 — see below: NOT BLOCKING.**

- **The measurement:** the *tawḥīd* formula already renders on **2 decks across 3 beats** —
  `al-qayyum@1` beat 5 (`لَآ إِلَـٰهَ إِلَّا هُوَ`), `al-mujeeb@1` beat 3 (`لَآ إِلَـٰهَ إِلَّآ
  أَنتَ`) and `al-mujeeb@1` beat 6 (*"There is no god but You"*, its duʿā). Tokens: `deity` n=2,
  `god` n=1. This deck would make it **3 decks, 4 beats**.
- **Why this is not the `يَـٰعِبَادِى` case:** §9o exempts **forms of address**. `لَا إِلَٰهَ إِلَّا`
  is **a substantive claim**, which is §9o's *blocking* row.
- **Why it may nonetheless not be a collision:** it is the Qurʾān's own creedal formula, repeated
  more than any other clause in the Book. Bar 3 exists to stop two decks **teaching the same
  insight** or **renaming the same Name** — and none of the three decks *teaches* tawḥīd: it is
  `al-qayyum@1`'s āyah's opening, `al-mujeeb@1`'s duʿā's opening, and here it is the second half of
  the sentence in which Allah gives His Name. **And if any deck in this pack may render it, the deck
  for the Name `Allah` is that deck.**
- **What I refuse to do:** elide it. Cutting `لَآ إِلَـٰهَ إِلَّآ أَنَا` out of 20:14 to satisfy a
  string diff is exactly what §9o warns against — *"mutilating the text to satisfy a string diff"* —
  and §9ag ruled the same way when it withdrew an offered ellipsis on a doxology.
- **Why the ruling is needed beyond this deck:** it **will recur**. Al-Hayy (15), Al-Ahad (74),
  Al-Wahid (73) and Al-Baqi's neighbours all sit on tawḥīd texts. **A one-line standing rule here
  saves four future round-trips**, exactly as §9o's `يَـٰعِبَادِى` ruling did.

**⚠️ RULED, 2026-08-03, by the independent verifier: NOT BLOCKING.** The ruling was made on the
grounds already argued above, on §9o's existing exemption: **a creedal formula is shared scripture,
not a taught insight**, and two decks quoting the same creed have not each taught it. **This is now
settled, not merely argued — record it here rather than re-escalating it.** The verifier further
recorded that this ruling **will recur** on Al-Hayy, Al-Ahad and Al-Wahid exactly as anticipated
above, and should be handled the same way each time.

**3. `"O Allah, I ask You…"` — beat 6 ↔ `al-wadud@1` and `al-haleem@1` duʿā beats.**
**Non-blocking by the ledger's own method:** §7's worklist explicitly **filters** *"generic openers
(`اللهم اني اسالك`, 'O Allah I ask You', 'You are the', …)"* when computing shared runs. All three
strings are catalogue-locked. **Disclosed for completeness, not raised.**

**Tokens this deck introduces that are corpus-absent (n=0 decks):** `sandals` · `torch` · `chosen` ·
`instruction` · `description` · `establish` · `listen` · `perceived` · `perhaps` · `reach` · `stay`.
**Hapaxes touched, all disclosed:** `attribute` n=1 (`al-haleem@1` — *"an attribute"* in a different
sense), `god` n=1 (`al-mujeeb@1`, see class 2), `worship` n=1 (`al-wasi@1`), `remembrance` n=1
(`as-salam@1` — its 13:28 verse beat renders *"remembrance of Allah"*; ⚠️ **mine renders *"My
remembrance"* on a verse beat too — disclosed; different āyah, different referent, no shared
3-gram**), `revealed` n=1 (`al-baseer@1`), `remove` n=1 (`ash-shafi@1`), `meet` n=1 (`al-wakeel@1`),
`saw` n=1, `reached` n=1, `bring` n=1, `here` n=1.

### 9c · **THE BINDING CONDITION — the scene, measured**

**Run at n=3, not n=4, because the coordinator made this the condition of approval.**

> **Result: ZERO 3-gram overlaps between any beat of this deck and any rendered string of
> `al-hadi@1` or `al-haqq@1`.**

| deck | its Mūsā scene | its rendered ground | mine |
|---|---|---|---|
| **`al-hadi@1` [S]** | **the flight to Madyan**, 28:15/21/22/23 | *"Musa fled Egypt at his lowest"* · *"I trust my Lord will guide me to the right way"* · *"It was Midian — shelter, and a family"* | **the fire on the road, 20:9–14.** No shared āyah, no shared sūrah. **Its Name-word `guidance` is removed from my beat 2 by an explicit elision (§5).** |
| **`al-haqq@1` [D, this wave]** | **the magicians**, 20:65–70 + 7:118 | *"Pharaoh's magicians went first"* · *"Fear not. Indeed, it is you who are superior"* · *"the magicians fell down in prostration"* | **51 āyāt earlier in the same sūrah.** Different scene, different cast. **`pharaoh` and `staff` are n=0 in my beats.** |

⚠️ **One thing no sweep would surface, so I state it: the corpus now renders the prophet's name three
ways.** `al-hadi@1` renders **`Musa`** (n=4 strings); `al-haqq@1` renders **`Mūsā`** in its authored
prose and **`Moses`** inside its Saheeh quotations; **this deck renders `Moses` only, and only inside
quotations** — it has no authored prose naming him. **That is consistent with `al-haqq@1`'s practice
and inconsistent with `al-hadi@1`'s.** It is a **transliteration-convention question across three
decks**, not a bar failure, and it is a founder/catalogue-track call, not a drafting one.

⚠️ **Second, and it is the real risk of stacking three decks on one prophet:** each is individually
distinct, but **a user who collects all three meets Mūsā three times.** No pairwise diff can see
that. **Recorded for the founder as a pack-sequencing note.**

### 9d · The `"God"` `name_intro` — disclosed as ruled, not treated as blocking

**The measurement stands and I am not softening it:** `Allah*` renders in **66 strings across 29 of
34 decks**; the token `god` renders **once** — lower-case, inside `al-mujeeb@1`'s duʿā (*"There is no
god but You"*). Beat 1 renders **"God"** as this Name's gloss.

**Applying the coordinator's ruling and §9o's test:** *could a user read two screens and think they
had been told the same thing twice?* **No** — *"God"* renames nothing and duplicates no other Name's
gloss. **It is a register inconsistency, not a bar-3 collision. Restorer-class, catalogue-locked,
unfixable at deck level. Disclosed; not blocking.**

**What the deck does about it, within its own scope:** beat 1 adds the authored gloss
*"— the Name every other Name belongs to"*, so the screen is not the bare word. That gloss is
grounded in the card's **own** fields (id 1 `meaning`: *"the proper name of God, encompassing all
divine attributes"*; id 1 `lesson`: *"Every other Name is an attribute of Allah"*) **and** in the
duʿā's own sentence (*"every Name that belongs to You"*). **Precedent: `al-wakeel@1`, `al-muid@1`,
`al-mumin@1`.**

### 9e · Surface 3 — the move. **The coordinator's test, applied.**

> *"A deck for the Name that contains the others has to say something the others do not. If beat 8
> could sit on any shipped deck, it is not this deck's beat 8."*

**Beat 7:** *"He was not given an attribute. He was given the Name, and then one instruction. Every
other Name you will meet is a description of the One that sentence named."*

**The test, run mechanically rather than asserted: substitute any other Name into it and it breaks.**
On `ar-raheem@1` the first sentence is **false** (mercy *is* the attribute). On `al-hadi@1`,
`al-wakeel@1`, `al-kareem@1` — same. **The second sentence is not merely false on another deck; it is
unsayable**, because it presupposes being the Name the others describe. **This line is the one beat-8
in the pack that is non-transferable by construction, and that is exactly because of the property
that made me refuse the deck in the first place.**

**Engine, three words: *the Name preceded the attributes*.** Checked against §3a's spent engines and
wave 1's additions (*nothing was default · the appraisal was wrong · made of it not given it · the
counterfeiters recognised it · safety is provision · reported on in your absence · the unlisted
share · the inventory inverts · the taking is in the same hand as the giving · your record never
touched Him*): **no match.**

**⚠️ Adjacencies I am disclosing rather than clearing:**
- **`as-samad@1` beat 7** — *"'Needed by all' means everyone leans here… Leaning is not weakness."*
  Both decks make a claim about a Name's **scope**. **Different claim** (everyone needs Him vs every
  Name describes Him) and zero shared n-gram at n≥3.
- **`al-afuw@1` beat 7** — *"Of every request available on the best night of the year, she was taught
  to ask for the erasing."* Both read **which words were given**. `al-afuw@1`'s engine is *which
  request was chosen*; mine is *what category the thing given belonged to*. Disclosed.
- **The bridge–takeaway axis inside this deck.** Beat 0 (*"Some nights there is no word for it.
  There is still a Name."*) and beat 7 both turn on *Name*. **Measured: 0 shared 4-grams across all
  28 own-beat pairs.** Deliberate framing, not repetition.

**§9ar check — the takeaway's last clause against the preceding beat's last noun.** Beat 6 ends
*"…every Name that belongs to You."*; beat 7 ends *"…a description of the One that sentence named."*
**Read in order, out loud: the user says the duʿā, then is told what the Names are.** No inversion,
no misreading available. ⚠️ The nearest risk was an earlier draft ending *"…so that He is
remembered"*, which would have **adjudicated `لِذِكْرِى`** (for My remembrance / so that I am
remembered / when you remember Me) — the §9z failure, by choice of gloss. **Cut for that reason;
beat 7 now paraphrases none of 20:14.**

---

## 10 · Rejected, and recorded as blocked rather than passed over

**Bar 1 candidates (the full enumeration is in the refusal §2, run over all 6,236 āyāt):**
- **27:9** (`إِنَّهُۥٓ أَنَا ٱللَّهُ ٱلْعَزِيزُ ٱلْحَكِيمُ`) — **trailing epithet pair inside the
  same clause**, bar 1's named failure; and **`al-azeez@1` is drafting this wave** (its claim file
  `8.md` was read: 36:13–14 + 10:65, no overlap with mine).
- **28:30** (`إِنِّىٓ أَنَا ٱللَّهُ رَبُّ ٱلْعَـٰلَمِينَ`) — **six āyāt from shipped `al-hadi@1`'s
  28:23, in its sūrah, continuing its journey.** **Blocked, not free.**
- **79:24** — **Pharaoh.** Recorded because a careless sweep misreads it.

**Names-as-a-set texts (all nine enumerated):**
- **7:180** — **STAYS BLOCKED**, per the coordinator. Its own āyah ends *"They will be recompensed
  for what they have been doing"* and **n−1 is 7:179, *"We have certainly created for Hell many of
  the jinn and mankind"*** — both fetched. Sūrat al-Aʿrāf also carries `ar-rahman@1` (7:156) and
  `al-haqq@1` (7:118).
- **17:110** — renders `ٱلرَّحْمَـٰن`, **shipped `ar-rahman@1`'s entire Name**; states rather than
  shows; runs on into prayer-volume instruction inside the same āyah.
- **20:8** — **bar 2 (states) and §9v (self-repetition).** §6. **Free for nobody: it is this
  passage's own n−1 and this deck deliberately leaves it unrendered.**
- **59:24** — three Names in one clause + trailing `ٱلْعَزِيزُ ٱلْحَكِيمُ`; `.context/claims/10.md`
  already rejects it.
- **2:31 · 2:33** — the names **Ādam** was taught; `.context/claims/14.md` rejects 2:30–33 and
  shipped `at-tawwab@1` sits at 2:37 in the same episode.
- **7:71 · 12:40 · 53:23** — names **the idolaters invented**. Opposite subject.

**Ḥadīth:**
- **Bukhārī 2736 / 7392** (the ninety-nine Names) — **2736 fetched and verified; on no beat.** It is
  a **statement of number, not a narrative** — the class the ledger rejected for Bukhārī 6469
  (*"a statement of scale, not a narrative"*). **Free, with that caveat.**
- **The *hamm/ḥazan* supplication** — ⚠️ **CORRECTED 2026-08-03:** the Mishkat/Razīn route is
  reachable and is a splice-match, excluded on tier and grading, not on unreachability (§7). The
  Ahmad route remains genuinely unreachable. **Unspent** either way.

---

## 11 · Catalogue finding — reported, NO change recommended

**Id 1's `hadith` renders one Arabic word as two acts, inside quotation marks.**

- **Card:** *"…Whoever **memorizes and acts upon them** will enter Paradise." (Bukhari)*
- **Fetched page, Ṣaḥīḥ al-Bukhārī 2736**, Abū Hurayra,
  `مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ`, page English *"whoever **knows them** will go to Paradise."*

The narration is **real, correctly numbered, correctly attributed and ṣaḥīḥ.** The defect is that
`أَحْصَاهَا` is **one** word and the card renders it as **two acts**, in a field users read as a
quotation — the `al-kareem@1` class (plan §6 rule 2), in the column the 2026-08-03 repair pass
already swept. **Reported as a finding. No change recommended.** It blocks nothing: **this deck
quotes the card's ḥadīth on no beat.**

---

## 12 · What this pass could NOT determine — read before signing

1. ~~The duʿā's provenance. Unverifiable by this pipeline, not disproven.~~ **CORRECTED 2026-08-03:**
   the Mishkat/Razīn route **is** reachable and **is** a splice-match; it is excluded on tier and
   grading, not on unreachability. The Ahmad route remains genuinely unreachable. See §7 for the full
   correction and the general rule it produced (a negative retrieval result is a property of the
   query, not of the source, absent a second query shape and endpoint). **Still the single most
   important line in this document — now for the corrected reason.**
2. ~~The *tawḥīd*-formula ruling (§9b.2) is requested, not made.~~ **RULED 2026-08-03: NOT BLOCKING**
   (§9o's creedal-formula exemption applies — shared scripture is not a taught insight). The deck
   keeps 20:14 whole; no elision was ever needed. This will recur on Al-Hayy, Al-Ahad and Al-Wahid and
   should be handled the same way each time.
3. **The `"I am your Lord"` echo with `al-wadud@1` (§9b.1) is disclosed, not cleared.** §9ab: a
   drafter may not rule on its own beat-to-beat echo. **The one-line fix is named.**
4. **Bar 5 is an argument, not a 404** (§6a) — and it is **the same argument `al-haqq@1` makes, in
   the same sūrah, in the same wave.** Tighten both or neither.
5. **The three-spellings finding and the three-Mūsā-decks sequencing note (§9c)** are founder calls
   I have surfaced, not solved.
6. **No successor sweep beyond 20:21.** I read 20:7–20:21. I have **not** read 20:22 onward and make
   no claim about it.
7. **No ḥadīth reached a beat of this deck**, so the project's sunnah.com-dependency limit does not
   bind the deck's content — but it **does** bind §7's negative result and §11's catalogue check,
   both of which rest on Wayback captures of sunnah.com. **No isnād was audited.**
8. **`.context/claims/` re-read before this table: 17 files** (10 at my start; late: **8, 24, 25, 45,
   87**). All read; **none claims Ṭā Hā, 20:x, 7:180, Bukhārī 2736 or the Mūsā ground.** A claim
   filed after that read is invisible to me (§9s).
9. **I ran no tests and edited no asset.** `assets/content/`, `collectible_names.json` and the ship
   gate were **read only**.

---

## 13 · Prose-vs-table diff (§9aj), and the measurements (§9ak)

Claims that came down to their rows while writing:

- §4 bar 1 originally read *"bar 1 is met at full strength."* The table forced the narrower true
  statement: **the Name has no act, so "full strength" is meaningless here** — it is *the strongest
  construction that exists for a Name that is not an attribute*, and §4 now says so.
- §5 originally read *"the elision is purely a collision fix."* Diffing it against beat 7 showed the
  elision **could** manufacture an engine, so §5 now argues **against itself** and names the fix.
- §6 originally read *"the passage does not terminate in punishment."* The row shows **20:16 ends
  `فَتَرْدَىٰ`.** §6 now states the word, then the three mitigations, then the resolution at 20:21.
- §9b.2 originally read *"the tawḥīd formula is formulaic, therefore exempt under §9o."* **§9o's own
  table says a substantive clause is blocking.** It is now a **request for a ruling**, not a ruling.

**Every quantity is a number:** 6,236 āyāt swept · **3** self-naming āyāt, **1** used · **9**
Names-as-a-set āyāt, all refused · **0** three-gram hits vs both Mūsā decks · **0** of 28 own-beat
pairs ≥4 words · **3** disclosed 4-gram classes, **all** locked scripture · **6** quoted spans, **4**
full-āyah and **2** exact prefixes · **2** marked elisions · **51** āyāt between this deck and
`al-haqq@1` in Ṭā Hā · **6** āyāt between 28:30 and `al-hadi@1`'s 28:23 · **66** *Allah* strings in
**29 of 34** decks vs `god` **n=1** · **0** Wayback captures of `ahmad:3712`.

---

## 14 · Fixes applied per the independent verifier's ruling — 2026-08-03

**Source:** `2026-08-03-WAVE2-VERDICT-allah-al-quddus.md`. **Verdict on this deck: FIX-THEN-SIGN, on
two findings — one blocking, one minor.** Everything else was independently reproduced exactly:
the bar-1 enumeration (three self-naming āyāt, 9:94 the fold false positive), 7:180 BLOCKED, the
zero-3-gram scene separation from both Mūsā decks, the successor/predecessor sweep on 20:7–20:21, all
six quoted spans, the 734-string count, the 66/29 *Allah*-string measurement, and the zero-overlap
own-beat diff.

**1. BLOCKING — the duʿā-provenance disclosure was factually wrong.** §7 stated Wayback CDX for
`sunnah.com/mishkat:2452` returned an empty response and concluded the duʿā was "unverifiable by this
pipeline." **The verifier re-ran the identical query: 7 rows, 6 status 200.** The page is *Mishkat
al-Maṣābīḥ* 2452 (Ibn Masʿūd, via Razīn, no printed grade) and its Arabic contains catalogue id 1's
duʿā as a splice, the same shape §9k already names for ids 17 and 61. **Fixed:** §7 is rewritten in
full to state what was actually found — reachable, and a near-match, excluded on tier and grading —
and records the general rule this error exposes (a negative retrieval result is a property of the
query/endpoint, not of the source, unless a second query shape and endpoint both come back empty).
The UNPINNED conclusion is unchanged. The Ahmad-route findings were independently reconfirmed and are
untouched.

**2. Minor (§9ak) — an occurrence count reported as a deck count.** §5 said `guide` "renders in 6
decks." **Corrected:** 6 occurrences across 3 decks (`al-hadi@1` ×2, `al-wadud@1` ×1, `ar-raheem@1`
×1). Does not change the elision decision.

**Ruled, not re-escalated — the tawḥīd-formula standing question (§9b.2):** **NOT BLOCKING**, on
§9o's existing creedal-formula exemption. Recorded in §4 bar 3, §9b.2 and §12 point 2. **This will
recur on Al-Hayy (15), Al-Ahad (74) and Al-Wahid (73) and is settled for all of them** — a future
drafter hitting the same shared-scripture overlap on those Names does not need to re-request a
ruling.

**Nothing else in this deck changed.** No other beat, citation, story or bar verdict was touched.
`assets/content/name_stories.json`, `collectible_names.json`, the ship-gate test and
`COLLISION-LEDGER.md` were not opened.
