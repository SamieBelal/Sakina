# DRAFT — `al-qahhar@1` · Al-Qahhar (catalogue id 22, *The Subduer*)

> **R2 REVIEW STAMP — 2026-08-04 · verdict: VERIFIED — content; spine incomplete (no `reflection` beat).** Reviewed by Claude on the three axes the founder asked for: **completion**, **narration authenticity** (nothing weak or fabricated on any beat), and **story impact / fit to the Name**. Every rendered scriptural quotation was re-fetched live and compared word-for-word against a named published translation; every ḥadīth rendered on a beat was re-fetched and its printed grade re-read. **This is a mechanical source-fidelity pass and is NOT the independent blind adversarial review the pipeline still owes this deck** — the reviewer is the same author for much of this wave. Full record: [`2026-08-04-R2-VERIFICATION.md`](./2026-08-04-R2-VERIFICATION.md).
>
> ⚠️ **The one completion gap:** this deck has no `reflection` beat. The ship gate does not require one, but `DRAFTING-BRIEF.md` §5a does — without it the slot renders **empty offline, on model failure, and outside the personalised tier.** Not authored here, deliberately: authoring a beat and then verifying it is the conflict of interest this same review flags elsewhere.

**Drafted 2026-08-03.** Claim file: [`.context/claims/22.md`](../../../../.context/claims/22.md).
**Twin draft, drafted by the same agent in the same pass, and required reading alongside this one:**
[`2026-08-03-al-mutakabbir-DRAFT.md`](./2026-08-03-al-mutakabbir-DRAFT.md). The two share
`dua_arabic` byte-for-byte, both render the same duʿā screen — see **§5, "The shared duʿā screen,"**
present in both drafts.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md).

All scripture verified at draft time by **live fetch**: Qur'ān via `api.quran.com/api/v4` (Saheeh
International, `translations=20`), including the **full 6,236-āyah Uthmānī mushaf in one call**
(`api.quran.com/api/v4/quran/verses/uthmani`) for the root sweep, cross-checked against
`corpus.quran.com`'s morphological dictionary. No ḥadīth is cited on this deck. Nothing here is
composed, reconstructed or recalled.

**Selection method: duʿā-first.** Catalogue ids 19 and 22 share one `dua_arabic`:
`يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي` — *"O Subduer, subdue
every stubborn tyrant. O Compeller-Healer, mend my brokenness."* What it demonstrates: the object of
"subduing" is an **external stubborn tyrant**, not the person praying, and the second half is a
**self-directed** request to be mended, never a request to be corrected. That is the register this
deck has to hold: outward (something else's claimed power is not final), never inward (you will be
brought low).

---

## 1 · The beats

| # | kind | `primary` | `arabic` | `source` |
|---|---|---|---|---|
| 0 | `bridge` | You keep bracing for the thing that has decided it can't be stopped. Al-Qahhar is the answer to what actually happens to a stubborn tyrant that comes for you. | — | — |
| 1 | `name_intro` | The Subduer | `الْقَهَّارُ` (translit. `Al-Qahhar`) | — |
| 2 | `story` | "Have you not considered how your Lord dealt with the companions of the elephant?" | — | `Qur'an 105:1` |
| 3 | `story` | "Did He not make their plan into misguidance? And He sent against them birds in flocks," | — | `Qur'an 105:2-3` |
| 4 | `story` | "…striking them with stones of hard clay. And He made them like eaten straw." | — | `Qur'an 105:4-5` |
| 5 | `verse` | And He is the subjugator over His servants… | — | `Qur'an 6:18 (excerpt)` |
| 6 | `dua` | O Subduer, subdue every stubborn tyrant. O Compeller-Healer, mend my brokenness. | `يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي` · translit. `Ya Qahhar, iqhar kulla jabbarin 'anid, wa Ya Jabbar, ujbur kasri` | **empty — UNPINNED** |
| 7 | `takeaway` | An army came once for the thing that mattered most, certain nothing could stand in its way. It never arrived. Whatever is marching at you tonight as if it can't be stopped is not the exception to that. | — | — |

`chip_keys: []`, `position_in_pair: 0`. Beat 6 must carry no `source` — the shared duʿā is catalogue-
authored (it embeds Al-Jabbar's own duʿā verbatim, which is itself the tell that this is a composite,
not a single narration), so it must **not** enter `renderedDuaSources`. Story beats carry `label`:
*"The Army That Never Arrived."*

**Transcription note:** deck prose below uses `Qurʾān`; rendered `source` strings use ASCII
`Qur'an`, per plan §7.

---

## 2 · The root sweep — why 6:18, not the six `ٱلْوَٰحِدُ ٱلْقَهَّارُ` occurrences

`corpus.quran.com/qurandictionary.jsp?q=qhr` (fetched 2026-08-03) and an independent full-mushaf
skeleton sweep (`api.quran.com/api/v4/quran/verses/uthmani`, infix-tolerant for `ا و ي`) agree
exactly: **root `ق-ه-ر` occurs 10 times total.**

| form | verses | usable for bar 1? |
|---|---|---|
| Form-I verb `تَقْهَرْ` | 93:9 | **no** — negative construction, Allah's command *to the Prophet ﷺ* re: the orphan, human addressee, not Allah's own act |
| Intensive epithet `ٱلْقَهَّارُ`/`ٱلْقَهَّارِ` | 12:39, 13:16, 14:48, 38:65, 39:4, 40:16 | **no** — every one of the six is the fixed pair `ٱلْوَٰحِدُ ٱلْقَهَّارُ`. The task brief names this pair explicitly: leaning on it fails bar 1 (trailing epithet). `.context/claims/73.md` (Al-Wahid, concurrently drafted) independently found the same six and reserved them for this deck — **not spent here**, the reservation is moot because the brief already rules the form out |
| Active participle `ٱلْقَاهِرُ`/`قَـٰهِرُونَ` | 6:18, 6:61, 7:127 | **7:127 no** (Firʿawn's people boasting of dominance over the Israelites — human speech). **6:18 and 6:61 yes** — see below |

**`وَهُوَ ٱلْقَاهِرُ فَوْقَ عِبَادِهِۦ`** — "And He is the subjugator over His servants" — occurs
verbatim at both 6:18 and 6:61. Same root, a **non-intensive, non-paired** form: the entire predicate
of an independent clause (`huwa` + `al-qāhir` + `fawqa ʿibādihi`), not a coda appended to an
unrelated statement. This is the deck's bar-1 carrier.

---

## 3 · The five bars

| # | bar | verdict | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words — not a trailing epithet** | **MET.** `ٱلْقَاهِرُ فَوْقَ عِبَادِهِۦ` (6:18) is the whole predicate of an independent Qurʾānic sentence in Allah's own third-person narration — not appended to another statement, not reported human speech, not the epithet-pair form the brief names as unusable. | yes — beat 5 |
| 2 | **shown, not stated** | **MET on the story; the verse is a direct declaration (see below).** The story does not assert "tyrants fail" — it narrates one specific army's plan going to nothing, in five short, concrete clauses (birds, stones, straw), with no editorializing beat. | yes — beats 2–4 |
| 3 | **no sibling collapse, including against the twin deck** | **MET — full sweep, all three surfaces, plus the twin diff. See §4.** | see §4 |
| 4 | **the Name's own root appears in the source text** | **MET on the verse beat** (`ٱلْقَاهِرُ`, 6:18). **Bar-4 trade on the story**: no `ق-ه-ر` in Sūrat al-Fīl — disclosed, and the same pattern the ledger already accepts for `al-jabbar@1` (whose root is "duʿā only," per ledger §5). | yes — beat 5; traded on beats 2–4 |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **MET, maximal form — see §"Successor sweep."** | yes |

**On bar 2 for the verse beat specifically:** 6:18 is a direct declarative statement, not a narrative
demonstration — the same shape the ledger accepts on verse beats generally (`al-fattah@1`'s 48:1,
`ash-shafi@1`'s 26:80 are both direct declarations, not arguments). The "shown, not stated" bar is
carried by the **story**, which is where this deck's real demonstration lives.

---

## 4 · Bar 3, run on all three surfaces, checked against the current 45-deck asset

**Method note, per the coordinator's mid-run correction:** `assets/content/name_stories.json` moved
from 34 to 45 decks while this deck was in progress (commit `1bca4ae`, 11 more landed, including
`al-azeez@1`). **Every sweep below was run against the file as it stood after that merge — 45 decks,
counted directly** (`len(data) == 45` verified programmatically), not inherited from the ledger's
34-deck figure.

### 4a · Surface 1 — Arabic roots

Rendered Arabic exists only on `name_intro` and `dua` beats (story and verse beats render `arabic: ""`
throughout this deck, per plan §7's convention). `ق-ه-ر` appears on this deck's `name_intro`
(`الْقَهَّارُ`) and nowhere else in the current asset's rendered Arabic. `ج-ب-ر` appears on this
deck's `dua` beat only, inherited from the catalogue-locked shared duʿā (disclosed in §5).

### 4b · Surface 2 — rendered English, token frequency, checked against all 45 decks

Every `primary`/`label`/`source`/`translation` string across all 45 decks extracted programmatically;
this deck's candidate strings checked against them by n-gram diff (widths 7→4) and by targeted token
search.

| finding | verdict |
|---|---|
| `arrogan*` `greatness` `debased` `straw` `tyrant` `subdue` `elephant` `kibr*` `qahr*` — checked as exact-token searches across all 45 decks' rendered fields | **zero hits, every token**, except `arrogan*` (1 hit: `al-khafid@1`'s own duʿā, *"lower my arrogance"* — a different Name, self-directed request, no overlap with this deck's content) |
| `birds` | 9 hits: `ar-razzaq@1` (a parable — birds leaving empty, returning full) and `al-qadir@1` (four birds recombined to show life given). **Different job in both cases** — a provision parable and a life-given demonstration, versus this deck's *judgment delivered on an aggressor*. Disclosed, not blocking, per the standing rule that a shared common noun blocks only when it performs the same job in the same staging (ledger §9ay). |
| "Have you not considered" (beat 2) | **n=4 hit against shipped `al-qabid@1`**, whose story opens *"Have you not considered your Lord — how He extends the shadow…"* (25:45). **Both are the Qurʾān's own formulaic rhetorical-question opener `أَلَمْ تَرَ`** — the same class the ledger's standing rule (§9o) exempts: a formulaic Qurʾānic construction is not a bar-3 collision. Confirmed by checking al-qabid@1's citation directly: a different āyah (25:45 vs. 105:1), same Qurʾānic idiom. |
| "And He is the…" (beat 5 opening) | n=4 hit against `al-wakeel@1`'s story and duʿā (*"And He is the best Disposer of affairs"*-type phrasing) — a generic English connective, not a distinctive phrase; same class as the ledger's "generic openers…filtered out" convention (§7's worklist methodology). Non-blocking. |
| Bridge template *"is the answer to"* | n=4 hit against shipped `al-hadi@1`'s bridge. **Template class, disclosed, non-blocking** — identical finding and identical ruling already made for `al-muizz@1`'s bridge against the same shipped deck (ledger §4b treats bridge scaffolding this way). |

### 4c · Surface 3 — the move

**Engine, three words: it never reached you.** The army meant to erase what mattered most was already
"eaten straw" — a defeated thing — before it arrived.

| shipped / drafted deck | its move | this deck's move | separated? |
|---|---|---|---|
| `al-fattah@1` [S] | *gatekeepers cannot withhold* — a closed door reframed as no obstacle at all | *an approaching force fails before contact* — an active threat, not a closed door | **yes**, different mechanism (passive withholding vs. active assault repelled) |
| `al-qabid@1` [S] | *withholding read structurally, no reassurance authored on* | this deck's takeaway does author a direct claim (*"was not the exception"*) rather than only structural silence — a real difference in method, disclosed rather than hidden | **yes, and noted as a difference in approach, not just content** |
| `al-mumin@1` [S] | *safety named alongside being fed, "not something you rise to"* — the man contributes nothing, safety is granted | this deck's protagonist-community also contributes nothing (no fighting happens on their side), but the mechanism is an aggressor's defeat, not a personal rescue narrated through someone's own words | **yes**, different scene entirely, zero shared scripture |

Checked against the ledger's spent-engine list (§3a: *answered while unaware, known without words,
the un-ended interval, allowed to ask, said before believed, the gap was on your side, singular
becomes plural, present in two places, handing over is not quitting, more than there was before,
covering rather than publishing, the gatekeepers cannot withhold, leaning is not weakness, met
mid-road, which request chosen, the supply does not run down*) — no match.

### 4d · The twin diff — beat by beat, against `al-mutakabbir@1`

| axis | `al-qahhar@1` | `al-mutakabbir@1` | same deck flipped? |
|---|---|---|---|
| root | `ق-ه-ر` | `ك-ب-ر` | **no** |
| sūrah | 6 (verse), 105 (story) | 45 (verse), 7 (story) | **no** |
| story genre | a defended community, an aggressor destroyed at a remove | a single named claim, refused by direct address | **no** |
| protagonist | none named — a communal "you"/"them," an army with no individual identity | Iblīs, named, individual | **no**, and asymmetric on purpose |
| bar-1 carrier | 6:18 `ٱلْقَاهِرُ` (verse); story is a bar-4 trade | 45:37 `ٱلْكِبْرِيَآءُ` (verse) + 7:13 `تَتَكَبَّرَ` (story, direct root match) | **no** — this deck trades on the story, the twin does not |
| the move | *it never reached you* (external threat defeated) | *the claim was refused* (illegitimate claim voided) | **no** |
| register mechanism | punishment lands entirely on an aggressor army, zero identifiable individual | a specific being (Iblīs) is directly refused and told to leave — heavier, addressed in §"Register" of the twin draft | **no — the two decks carry different, and differently-sized, register risk, disclosed separately in each** |

**Programmatic n-gram diff, every beat of one against every beat of the other:** zero hits at n≥4
outside the shared duʿā screen (§5, catalogue-forced) and the shared bridge-template class already
disclosed in §4b (`al-mutakabbir@1`'s bridge shares the same 4-gram with `al-hadi@1`, not with this
deck — the two decks' own bridges share zero n-grams with each other, checked directly).

---

## 5 · The shared duʿā screen

*(This section is present verbatim in both drafts.)*

**Catalogue ids 19 and 22 carry byte-identical `dua_arabic`, `dua_transliteration` AND
`dua_translation`.** Verified programmatically against `assets/content/collectible_names.json`,
2026-08-03 — all three fields, exact string equality.

```
arabic:          يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي
transliteration: Ya Qahhar, iqhar kulla jabbarin 'anid, wa Ya Jabbar, ujbur kasri
translation:     O Subduer, subdue every stubborn tyrant. O Compeller-Healer, mend my brokenness.
```

Both decks render the same duʿā beat — Arabic, transliteration and translation, pixel-identical.
**This is forced by the ship gate (`dua` beats assert byte-identical to the catalogue by `name_id`)
and is not a drafting choice on either deck.**

**Three further facts about that screen, measured, not asserted:**

1. **Id 19's own vocative is absent.** The duʿā never says "O Supreme One" — it opens `يَا قَهَّارُ`
   (invoking id 22, this deck's own Name) and closes `يَا جَبَّارُ اجْبُرْ كَسْرِي`, which is
   catalogue id 9 Al-Jabbar's **entire** `dua_arabic`, embedded verbatim. Verified by direct string
   comparison against id 9's row.
2. **⚠️ The English collides with two SHIPPED decks.** *"O Compeller-Healer, mend my brokenness"*
   shares its root (`ج-ب-ر`) and the exact phrase *"mend my brokenness"* with shipped `al-jabbar@1`'s
   own duʿā (*"O Compeller, mend my brokenness"*) — a direct, root-and-phrase collision. The added
   `-Healer` (not present in id 9's Arabic or English at all) collides at the **English-only** level
   with shipped `ash-shafi@1`'s gloss ("The Healer") — no shared Arabic root (`sh-f-y` does not
   appear anywhere in this duʿā), confirmed by direct root search.
3. **Both this deck and `al-mutakabbir@1` are BLOCKED on the duʿā axis** per the ledger's own
   classification (§6e), and are among the **eight** collisions in the whole 99-Name catalogue that
   are already irreversible because the colliding Name (Al-Jabbar) is already shipped.

**No catalogue change is recommended.** Three of three prior confident recommendations to change
catalogue duʿā data in this project were wrong, in the same direction (id 51, id 16, and the id-98
trap named in §9w). This is a report, not a proposal. Both decks disclose the collision on their own
duʿā beat's surrounding prose (this section) rather than proposing a fix that isn't this pipeline's
to make.

---

## 6 · Read as a user at 11pm

Something has been circling all day — a boss, a diagnosis, a person who has made themselves
impossible to argue with, a feeling that has decided it isn't leaving. The bridge names that directly:
*"the thing that has decided it can't be stopped."* Then the story: an army came for the one place
that mattered most, certain of itself, and never got there. Nobody on the receiving end fought back —
the beats don't narrate courage or a plan, just: it came, and then it was "eaten straw." The verse
follows the same shape in Allah's own voice, plainly: He is dominant over every one of His servants —
not some of them, not the ones who behave, **every one**, which includes whatever the reader is
bracing against. The duʿā hands the reader the same two moves in one breath: ask for the tyrant to be
subdued, ask for yourself to be mended — never ask to be corrected. The takeaway closes the loop by
naming what the story already showed: *not the exception.*

**Does it accuse the reader? My own read: no, and this is the more defensible of the two decks in
this pair on that question.** No beat addresses "you" as the target of anything Allah does. The
punishment in the story lands entirely on a specific, named-by-deed aggressor (an army marching to
destroy something sacred) — not on "the wicked" as a class the reader might fear belonging to, not
on a person the reader is asked to identify with. The reader's position in the story is the protected
party, not the punished one.

**The one place I want to be honest rather than confident: this story was independently examined and
set aside by another agent's draft for a different Name.** `al-mumin@1`'s draft (Al-Mumin, catalogue
id 7) fetched Sūrat al-Fīl as backward successor-sweep ground for its own verse beat (106:4, the very
next sūrah) and called it *"A punishment narrative. Refused on bar 5."* I take that finding seriously
rather than ignoring it, and here is the calibration that I judge distinguishes this deck's use from
that refusal: Al-Mumin's whole register is a **person's** granted safety, built on a gentle, un-violent
scene (a sleeping man, a lowered sword) — introducing an army's destruction, however distant the
mechanism, would have been tonally discordant with that specific, already-sufficient story, and there
was no reason for that deck to take the risk when it didn't need the ground. **This deck's whole
purpose is what happens to a stubborn tyrant** — the destruction is not adjacent noise here, it is the
demonstration bar 1 requires. Weighed against the project's own accepted calibration precedent
(`al-haqq@1`'s ruling, ledger §9aa: *"a rule cannot forbid the softer case while shipping the harder
one"*) — this passage is **softer** than several already-accepted anchors: it is a single historical,
temporal event (not eschatological Hellfire), aimed at a specific army (not "the disbelievers" as a
class), the sūrah ends completely on it (maximal bar 5, no possibility of the punishment worsening
past the excerpt), and the immediately following sūrah is explicitly about the safety and provision
that resulted. **I disclose the prior finding rather than let it be discovered at review, and I record
my own reasoning for why it does not transfer — the founder should read both.**

---

## 7 · Successor sweep — every quotation, fetched independently

**Qurʾān 6:18 (verse beat).** Fetched 6:16–6:20.

| | text | verdict |
|---|---|---|
| **n−1 · 6:17** | *"And if Allāh should touch you with adversity, there is no remover of it except Him. And if He touches you with good — then He is over all things competent."* | clean, and the exact shape of the duʿā's own request: no other power, however `جَبَّار` it looks, can finally harm or help outside His will |
| **n+1 · 6:19** | *"Say, 'What thing is greatest in testimony?' Say, 'Allāh is witness between me and you…'"* — tawḥīd, no partners | clean, no punishment |

**6:61 considered, not used**: same clause verbatim, but its own continuation (guardian angels, then
the angels of death) is a mortality passage — not needed once 6:18 carries the clause cleanly, and not
claimed as spent ground for a future drafter (it is the same clause as 6:18, already on this deck).

**Qurʾān 105:1–5 (story), maximal bar-5 form.** `verses/by_key/105:6` → **HTTP 404**, fetched
2026-08-03: Sūrat al-Fīl has five āyāt; 105:5 is its last. No successor can contradict, complete or
truncate the beat because there is no successor. **n−1 is not applicable in the strict sense** —
105:1 opens a new sūrah on a new subject; the preceding sūrah (al-Humazah, 104) is a different topic
entirely (fetched 104:9 for completeness — unrelated content, not part of this passage's discourse).

**Thematic continuation, NOT quoted, NOT claimed as spent ground for a future drafter**: Sūrat
Quraysh (106) opens *"For the accustomed security of the Quraysh"* and closes 106:4, *"Who has fed
them, [saving them] from hunger and made them safe, [saving them] from fear."* **106:4 is already a
SHIPPED deck's verse beat** (`al-mumin@1`, confirmed by direct read of the current asset). This deck
quotes nothing from Sūrat Quraysh — noted here only for successor-sweep completeness (the very next
sūrah is positive, reinforcing rather than undercutting the beat) and so no future drafter re-derives
it as free ground.

**Does the excerpt stop short of the passage's own ending in a way that changes its meaning?** No —
the excerpt (105:1–5) **is** the entire sūrah.

---

## 8 · Claim | Source | Grading | Status

| # | claim | source | URL fetched | grading | status |
|---|---|---|---|---|---|
| 1 | *"Have you not considered how your Lord dealt with the companions of the elephant?"* (beat 2, verbatim) | Qur'ān 105:1 | `api.quran.com/api/v4/verses/by_key/105:1?fields=text_uthmani,text_imlaei&translations=20` | Qur'ān | ✅ **verified verbatim** — `text_uthmani`, `text_imlaei` and Saheeh International all fetched live |
| 2 | *"Did He not make their plan into misguidance? And He sent against them birds in flocks,"* (beat 3) | Qur'ān 105:2–3 | `…/verses/by_key/105:2`, `…/verses/by_key/105:3` | Qur'ān | ✅ **verified verbatim** against Saheeh International — checked against all 45 decks, zero n≥4 collisions |
| 3 | *"striking them with stones of hard clay. And He made them like eaten straw."* (beat 4) | Qur'ān 105:4–5 | `…/verses/by_key/105:4`, `…/verses/by_key/105:5` | Qur'ān | ✅ **verified verbatim** against Saheeh International |
| 4 | *"And He is the subjugator over His servants…"* (beat 5, partial, visible ellipsis) | Qur'ān 6:18 | `…/verses/by_key/6:18?fields=text_uthmani,text_imlaei&translations=20` | Qur'ān | ✅ **verified** — trailing `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ` deliberately not rendered, ellipsis marks the cut |
| 5 | 6:18's n−1 (6:17), n+1 (6:19) | Qur'ān 6:17, 6:19 | `…/verses/by_key/6:17`, `…/verses/by_key/6:19` | — | ✅ **fetched and read**, table in §7 |
| 6 | 105's sūrah-final status | `verses/by_key/105:6` | `…/verses/by_key/105:6` | — | ✅ **HTTP 404 confirmed**, 2026-08-03 |
| 7 | Sūrat Quraysh (106) continues positively; 106:4 already shipped on `al-mumin@1` | `assets/content/name_stories.json` (45 decks) + Qur'ān 106:1–4 | local read + `…/verses/by_key/106:1..4` | — | ✅ **verified** by direct file read and live fetch |
| 8 | The `ق-ه-ر` full-mushaf enumeration (10 total: 1 verb, 6 epithet-pair, 3 participle) | `api.quran.com/api/v4/quran/verses/uthmani` (full call) + `corpus.quran.com/qurandictionary.jsp?q=qhr` | full-mushaf fetch + corpus dictionary fetch | — | ✅ **independently run and cross-checked**, exact match, §2 |
| 9 | Catalogue ids 19 and 22 share `dua_arabic`/`dua_transliteration`/`dua_translation` byte-for-byte | `assets/content/collectible_names.json` ids 19, 22 | local read | — | ✅ **verified programmatically**, exact string equality |
| 10 | Id 19's duʿā embeds id 9 Al-Jabbar's `dua_arabic` verbatim | `collectible_names.json` ids 9, 19 | local string comparison | — | ✅ **verified programmatically** |
| 11 | Zero ≥4-word rendered-English overlap with any of the 45 shipped/drafted decks except the disclosed formulaic-opener and template classes | `assets/content/name_stories.json` (45 decks) | local, n-gram diff 7→4 | — | ✅ **run against 45 decks**, output in §4b |
| 12 | Twin diff against `al-mutakabbir@1`: zero shared n≥4-grams outside the shared duʿā screen | both drafts | local n-gram diff | — | ✅ **run in this session**, table in §4d |
| 13 | `al-mumin@1`'s draft calls Sūrat al-Fīl "a punishment narrative, refused on bar 5" | `docs/superpowers/content/decks/2026-08-03-al-mumin-DRAFT.md` | local file read | — | ✅ **read directly, quoted verbatim, engaged with in §6** |
| — | isnād / ḥadīth authenticity | not applicable — no ḥadīth cited on this deck | — | — | n/a |

---

## 9 · Limits of this verification — stated because the founder signs against it

1. **The Qur'ān side is single-source** — `api.quran.com`, Saheeh International only. Not cross-checked
   against a second muṣḥaf text or a second translation for the specific quoted clauses (the root
   enumeration itself was cross-checked against `corpus.quran.com`, a second, independent source).
2. **The root enumeration is a skeleton match over one Qur'ān text**, not a morphological parse
   independent of api.quran.com's own text encoding — though its totals were confirmed against
   corpus.quran.com's separately-maintained dictionary, which uses a different underlying text
   pipeline (morphologically tagged), giving genuine cross-source agreement rather than checking a
   method against itself.
3. **The register judgment in §6 is a judgment, not a measurement.** I have stated my reasoning and
   the prior finding I am weighing it against; a founder or adversarial reviewer may reasonably weigh
   it differently.
4. **I did not run `flutter test`.** Nothing was written to `assets/content/name_stories.json`,
   `collectible_names.json` or the ship-gate test — read-only, per the task's constraint.
5. **The 45-deck asset and the DRAFT.md files on disk were read at one point in time** (2026-08-03,
   during this drafting pass); other agents are working concurrently and the corpus may have grown
   again by the time this is reviewed. The exact count swept (45) is stated so staleness is
   detectable rather than silent.
