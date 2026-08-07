# Handoff — 99-Names decks, as of 2026-08-03

Written so a fresh session can pick this up cold. Branch `feat/journaling-and-name-mastery`, all commits local, nothing pushed.

---

## 1 · Where the work stands

| | Count | |
|---|---|---|
| **Shipped** in `assets/content/name_stories.json` | **45** | ship gate green |
| **Drafted, R2-verified 2026-08-04** | **54** | **all 54** reviewed for source fidelity + narration authenticity + Name fit — [`2026-08-04-R2-VERIFICATION.md`](./2026-08-04-R2-VERIFICATION.md). **8 defects found and fixed**, incl. a misquotation on `al-majeed@1`'s beat 6 (§9ch). **19 still lack a `reflection` beat** (§5). A **blind** adversarial review is still owed. 3 of them also reviewed and fixed to R1 (§2a); ids **20**, **26**, **47**, **48**, **49**, **50**, **52**, **55**, **58**, **60**, **66**, **84**, **90**, **32**, **28**, **39**, **53**, **56**, **59**, **65**, **67**, **76**, **89**, **97**, 21, 19, 22, 43, 44, 62, 63, 69, 70, 71, 73, 74, 77, 78, 79, 80, 81, 82, 85, 91, 92, 94, 95, 96 |
| **Remaining, unstarted** | **0** | ✅ **all 99 Names are now shipped or drafted** |
| **Refused** | **0** | the one refusal (32 As-Sabur) was **overturned the same day** — §4e |

**Quarantined (9 files, `*-QUARANTINED*.md`).** Renamed off the `*-DRAFT.md` glob so no transcription pass can pick them up. Their ids are UNCLAIMED and free to redraft: **~~20~~ · ~~47~~ · ~~48~~ · ~~50~~ (all redrafted 2026-08-03, see §4a/§4c/§4d), 21 (Al-Bari retry only — the Al-Musawwir draft survives), 18, 39, 53.** Do not read them as precedent; see §3.

---

## 2a · The one completed review — three decks, **fixes now applied (R1)**

A Sonnet blind verifier fetched every citation in **Az-Zahir (81), Al-Batin (82), Al-Musawwir (21)** and confirmed **no invented scripture in any of the three** — every Qurʾān quotation real, live-fetched, accurately transcribed. It also independently confirmed the two decks' load-bearing bar-4 claim (that **only 57:3** predicates `ẓāhir`/`bāṭin` of Allah) which both drafters had honestly disclosed they had *not* checked.

**All five items are now closed. The three drafts are marked R1 in their own headers.** None of the fixes touched the scriptural core.

| # | Finding | Status |
|---|---|---|
| 1 | **Az-Zahir + Al-Batin beat 7 did not match the locked catalogue duʿā** — both rendered the ḥadīth from Muslim 2713a, adding `اللَّهُمَّ` and substituting *"the Manifest"/"the Hidden"* for the catalogue's *"Al-Dhahir"/"Al-Batin"*. | **FIXED** — beat 7 in both decks now renders all three catalogue fields byte-for-byte; asserted programmatically. New rule **§9cb** written from it. |
| 2 | **Al-Musawwir beat 2 rendered `meaning` where the house convention is `english`** — *"The Fashioner"* appeared nowhere on the deck (§9bz). | **FIXED** — and the sample was widened from 10 to **all 45**: 45/45 render `english`, 0 render `meaning`. |
| 3 | **Al-Musawwir's corpus sweep was method-invalid** (grepping the letter `ص`) and repeated the false *"cannot access corpus.quran.com"* claim. | **FIXED** — sweep rebuilt on a live `?q=Swr` fetch (HTTP 200, 17,768 B). Corpus: **19 occurrences, five forms**. **11 of the 19 are not the fashioning sense** — ten are `ṣūr` = *the Trumpet*, one is 2:260's "incline". Real inventory: **6 āyāt** (3:6, 7:11, 40:64, 64:3, 82:8, 59:24), with 7:11/64:3/59:24 rejected on stated grounds. Bar 4 still passes — but now by method, not by luck. R0 sweep kept struck, in a fold. |
| 4 | Bar-3(b) was left marked *"PENDING"* under a green tick; the verifier found **zero real collisions across 45 decks**. | **FIXED** — actually run at fix time. Max shared word-run was **7** (the tawḥīd formula `لَآ إِلَـٰهَ إِلَّا هُوَ`, on the verse beat). See the new finding below. |
| 5 | **Ruled:** the Usmani-over-Saheeh choice for `ٱلظَّاهِر` is **fidelity, not §9bl collision-dodging.** | Unchanged, no action. |

**One new finding, which the verifier's list could not have contained because R0 never ran the sweep that produced it.** Al-Musawwir's verse beat rendered 3:6 in full, including its closing `لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ`. Swept: **no shipped deck renders "the Exalted in Might" or "the Wise"** — so that clause is **unspent ground belonging to id 26 Al-Hakeem**, which is unstarted, and rendering a neighbour's clause is the one thing §9bo says actually disqualifies. **Beat 6 now truncates at the clause boundary with a visible ellipsis**, which drops the max shared word-run from 7 to 4 and leaves id 26 its ground. Bar 4 unaffected — `يُصَوِّرُكُمْ` is inside the retained clause.

**Also added at fix time:** a `reflection` beat to Az-Zahir and Al-Batin (they had none; see §5). Both swept against all 45 decks — max runs 2 and 3, twin-diff 2.

**Al-Musawwir's weakest surviving point, flagged rather than re-graded:** 40:63, the predecessor of the beat-4 āyah, is a rebuke passage (deniers likened to cattle). R0 graded it *"minor judgment theme"* and passed bar 5 on the argument that 40:64 opens a new sentence at `ذَٰلِكُمُ ٱللَّهُ`. Defensible, but "minor" is an adjective where §9ak wants a measurement. **Left for a verifier.**

---

## 2 · Model policy — the reason this handoff exists

**Draft with Sonnet. Do not draft with Haiku.**

A ten-Name Haiku run on 2026-08-03 produced **one usable deck**. Four pairs were quarantined for fabricated content, each failing differently — ledger §9bt, §9bu, §9bv, §9bw, §9bx:

- declared `api.quran.com` / `corpus.quran.com` / `sunnah.com` unreachable, then quoted them from memory (all three answered fine from the same machine)
- fabricated a tool result — *"59:24 → HTTP 404"* — and graded bar 5 a PASS on it; 59:24 returns 200
- graded a trailing epithet (`وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ`) as *"finite verb `يَحْفَظُهُمْ`, believers as object"*
- attributed invented counts to `corpus.quran.com` **by name and date** — 19 for `ح-ك-م` where the corpus returns 210, 44 for `ع-د-ل` where it returns 28
- inverted the one root identity a separation argument rested on (`ٱلْمُتَعَالِ` vs `ٱلْعَلِىُّ` — same root, `ع-ل-و`)
- refused Al-Bari on *"`ب-ر-أ`: 0 creation verbs"*, missing **57:22's `نَّبْرَأَهَآ`** (*"before We bring it into being"*)

**Every one of those reports looked complete and passing** — five-bars tables, measured-looking numbers, method-limits sections, ticks throughout. **None was catchable by reading the report.** All fell in minutes to one move: open the āyah.

**One of them was corrected explicitly** — §9bt pasted into its brief, the working `curl` commands included — and reproduced all four banned behaviours on the retry. **Where a failure survives explicit correction, change the assignment, not the wording.**

**Haiku is fine for transcription and merge passes**, where the text is already fixed and there is nothing to select or grade.

---

## 3 · The pipeline

```
draft (Sonnet)  →  blind adversarial verify (Sonnet)  →  fix pass  →  transcribe  →  merge + ship gate  →  commit
```

- **`DRAFTING-BRIEF.md`** is the binding protocol for drafters. Task messages should carry **only** what is Name-specific; everything standing lives there.
- **`COLLISION-LEDGER.md`** §9a–§9ch are binding rules, each earned from a real failure. §9bq (never sweep a root by adjacent-radical substring — Arabic infixes, and it fails *low*, which is the direction a bar-4 trade argument wants) and §9bi (sweep the asset as it is now, and state the deck count as an integer) are the two most-broken.
- **Verifiers must be blind and adversarial** — the drafter's tables are claims, never evidence. Brief them with §9bt–§9bx as the failure catalogue, and require **a table of every citation fetched with what the text actually says**.
- **Claim before drafting** in `.context/claims/<id>.md`, and re-read that directory before finalising — agents run concurrently.

**Working commands** (two agents wrongly reported these unreachable):

```bash
curl "https://api.quran.com/api/v4/verses/by_key/3:6?fields=text_uthmani&translations=20"
curl "https://corpus.quran.com/qurandictionary.jsp?q=Swr"     # parseable HTML, ~18kB
# NOTE: the q= code is case-sensitive and fails SILENTLY (§9by). `Swr` = ص-و-ر;
# `swr`/`SwR`/`sur` all return 200 for an unrelated entry with no error.
# Verified codes: Zhr=59 · bTn=25 · Swr=19 · brA=31 · Hkm=210 · Edl=28
#                 HSy=11 (ح-ص-ي) · bEv=67 (ب-ع-ث) · $kr=75 (ش-ك-ر) · bdE=4 (ب-د-ع)
# Scheme: H=ح x=خ v=ث * =ذ $=ش S=ص D=ض T=ط Z=ظ E=ع g=غ A=hamza
# sunnah.com via Wayback/CDX when blocked; captures may be zstd — pipe through `zstd -d`
```

**And before you write the report, assert your duʿā beat against the catalogue** — not against the ḥadīth or āyah it was excerpted from (§9cb; two decks in one pair got this wrong by carefully verifying the wrong artifact):

```bash
python3 -c "
import json,sys
nid, draft = int(sys.argv[1]), sys.argv[2]
c = {n['id']: n for n in json.load(open('assets/content/collectible_names.json'))}[nid]
t = open(draft, encoding='utf-8').read()
for f in ('dua_arabic','dua_transliteration','dua_translation','english'):
    print(f, c[f] in t)
" 21 docs/superpowers/content/decks/2026-08-03-al-musawwir-DRAFT.md
```

---

## 4 · Remaining: **none.** All 99 Names are shipped (45) or drafted (54)

Verified programmatically: the union of `name_id` in the shipped asset and in every `*-DRAFT.md` covers **99 of 99** catalogue ids, with **no gaps**.

---

## 4a · Al-Bari (id 20) — **drafted 2026-08-03**, third attempt, awaiting blind verification

`2026-08-03-al-bari-DRAFT.md`. The two quarantined drafts were not reused or read as precedent. **The refusal they rested on is dead:** `corpus?q=brA` (live, HTTP 200, 24,829 B) reports **31 occurrences in 10 forms**, including a **form I verb glossed "to bring into existence"** — the exact thing the refusal said did not exist.

**The sweep's reusable output, so nobody re-derives it.** **25 of the 31 are a different semantic field** — *absolve / disown / heal / innocent*. The creation sense is **6 occurrences across 5 āyāt**, and only one is a verb:

| āyah | bar 1 | bar 5 | outcome |
|---|---|---|---|
| **57:22 `نَّبْرَأَهَآ`** | ✅ Allah's own voice, 1st-pers. pl. | ✅ after truncation | **the deck** — the only text carrying bars 1 and 4 together |
| 2:54 `بَارِئِكُمْ` ×2 | ❌ Mūsā's reported speech | ❌ `فَٱقْتُلُوٓا۟ أَنفُسَكُمْ` | rejected twice over |
| 59:24 `ٱلْبَارِئُ` | ❌ trailing epithet chain | ✅ **sūrah-final** (59:25 → real 404) | **verse beat only**, one word |
| 98:6 / 98:7 `ٱلْبَرِيَّةِ` | ❌ predicate about people | ❌ Hellfire at 98:6 | rejected |

**So the choice was forced, not preferred — and there is nowhere to move this deck to.** That matters for the two things the draft flags as its weak points:

1. **Bar 2 is the weakest bar.** 57:22 is an order-of-operations (`مِّن قَبْلِ أَن` — the register precedes the bringing-into-being), not a parable or counterfactual. **If a verifier rules that a temporal sequence does not *show*, the deck has no fallback text and becomes a refusal on bar 2** — which is at least the right bar; both quarantined drafts put the refusal on bar 1, where it does not belong.
2. **Bar 5 is a real finding, handled by truncation.** 57:23's tail (`وَٱللَّهُ لَا يُحِبُّ كُلَّ مُخْتَالٍ فَخُورٍ`) is **one clause** after the last rendered word, and 57:24 continues the rebuke. The deck renders 57:22 (minus its closing `إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ`, omitted on register grounds) plus **57:23a only** — `لِّكَيْلَا تَأْسَوْا۟`, which is the passage's own stated purpose: *"so that you not despair."*

**The design problem was the duʿā, not the scripture.** Id 20's locked duʿā speaks in *repair* vocabulary — "repair what I have broken within myself" — which is where `al-jabbar@1` and `ash-shafi@1` already live. The deck's engine is therefore **precedence, not repair**: not *that* you exist (Khaliq), not *which* you (Musawwir), not mending (Jabbar), not magnitude of restoration (Shafi), but **when the writing happened relative to the event**. That argument sits on the **takeaway**, which is fixed and not AI-replaced.

**Measured:** 45 decks swept, max shared word-run **4** (both explained — one is the takeaway deliberately naming its neighbours, one is scripture). Twin-diff vs the `al-musawwir@1` R1 draft: **3**. Engine vocabulary unspent across the asset (`register` 0 · `disaster` 0 · `into being` 0 · `Producer`/`Evolver` 0). **Sūrah 57 is otherwise untouched by the shipped asset.**

**Catalogue finding, reported not actioned:** id 20's `english` is *"The Evolver"* while its `dua_translation` opens *"O Producer"* — so beat 2 and beat 7 name the Name differently, on the same deck. Both are locked. Flagged because it is the thing most likely to read as an error to someone who has not checked.

---

## 4b · Al-Muhsi (id 66) — **drafted 2026-08-03**, awaiting blind verification

`2026-08-03-al-muhsi-DRAFT.md`. **Carrier 36:12** (`أَحْصَيْنَـٰهُ`, first-person plural, āyah opens `إِنَّا نَحْنُ` — top of the §9bk ladder). **Verse beat 16:18** (`تُحْصُوهَآ` — the root on the *human* side, closing on `لَغَفُورٌ رَّحِيمٌ`). Both whole āyāt, no truncation. **Bar 5 clean in all four directions with no truncation needed** — the only deck in this wave where the successor sweep produced no finding, and 36:11 is itself *"good tidings of forgiveness and noble reward."*

**The design problem was the duʿā, and a verifier should start there.** Id 66's locked duʿā is *"do not hold me fully accountable for what You have **recorded against me**"* — an accountability plea — while the catalogue's `lesson` for the same Name reads *"Al-Muhsi has numbered every tear you have shed. None are forgotten."* **Comfort and accusation, both locked.** The deck's answer is structural: it reaches the duʿā through 16:18's `لَغَفُورٌ رَّحِيمٌ`, so the plea lands one line after "Forgiving and Merciful" rather than cold. **That is an argument, not a measurement.** If it fails, it is a catalogue-level problem, not a redraft.

**Two things this deck produced that outlive it — both now ledger rules:**

- **§9cc — the near-twin trap.** 14:34 and 16:18 carry the **identical clause** and differ only in the closing: 14:34 ends *"mankind is most unjust and ungrateful"*, 16:18 ends *"Allah is Forgiving and Merciful."* Coin-flip if you reach from memory, indistinguishable until the whole āyah is fetched. Same shape at 78:29, whose grammar equals the carrier's and whose successor is `فَذُوقُوا۟`. **Fetch every occurrence the corpus lists** — doing so caught **two wrong glosses in this draft's own rejection table** (73:20, 18:12), neither of which reached a beat.
- **§9cd — the nearest neighbour is invisible to surface (b).** Max shared word-run vs `al-ghafur@1` is **3**, on a Qurʾānic formula — yet its engine (a complete private record, shown, then covered) is within a hair of this Name's duʿā. **No mechanical check finds that.** It was found by reading the neighbouring deck.

**Measured:** 45 decks swept, **max shared word-run 3 across the entire deck** — every hit a function-word run except the `غَفُورٌ رَّحِيمٌ` formula. Engine vocabulary unspent (`enumerate` 0 · `register` 0 · `traces` 0 · `left behind` 0 · `put forth` 0 · `tear` 0). Diffed against the `al-muhyi@1` pending draft too (its root `ح-ي-ي` is rendered in beat 3): **max 2**, no collision.

**Ground deliberately left, recorded so it is not re-spent:** **58:6** closes `وَٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ شَهِيدٌ` — **Ash-Shaheed's (id 60) text**; 73:20 and 72:28 free; **19:94** root-dense but bar-5 blocked by 19:95. **And a trap for the next reader: id 66's catalogue `hadith` field is prose built on Qur'an 6:59, which `al-aleem@1` already renders.** The field points at spent ground.

**Note for whoever drafts 60 Ash-Shaheed and 39 Al-Hafeez:** this deck's surface-(c) family argument was made against neighbours that **do not exist yet**. You owe the diff against this deck, not the reverse.

---

## 4c · The judgment four (47, 48, 55, 90) — **drafted 2026-08-03 as one group**

Five files: [`JUDGMENT-FOUR-GROUP.md`](./2026-08-03-JUDGMENT-FOUR-GROUP.md) plus one draft each. **Read the group file first** — the shared duʿā treatment, the group-wide bar-5 ruling, all four root sweeps, the āyah partition and the four engines side by side live there and are not repeated in the drafts. Group claim: `.context/claims/47-48-55-90.md`.

**Two findings that outlive these decks:**

- **§9cf — their shared duʿā is Qurʾān-shaped and is not Qurʾānic.** `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` is a **composite**: 7:89's `ٱفْتَحْ … وَأَنتَ خَيْرُ ٱلْفَـٰتِحِينَ` with the root swapped `ف-ت-ح`→`ح-ك-م`, welded to 7:87/10:109/12:80's `وَ**هُوَ** خَيْرُ ٱلْحَـٰكِمِينَ` converted to second person, plus a prefixed `اللَّهُمَّ`. **No āyah contains this sentence.** All four ship with `source: ""`. Four decks = four chances to cite it as 7:89, which would be the exact failure class that put nineteen fabricated quotations into production.
- **The group-wide bar-5 ruling, made once so it can be rejected once.** Every strong carrier for these Names sits in a Judgment context — which is what the Names *are*. Read mechanically, bar 5 makes all four undraftable. The ruling: **Judgment as the reader's vindication is in register; Judgment as the reader's peril is not.** Enforced beat-by-beat — no beat renders punishment, `عَذَاب`, the Fire or `ٱلَّذِينَ كَفَرُوا۟`, and the reader is never positioned as the defendant. **A verifier who rejects this rejects all four at once, which is the correct granularity.**

**The partition.** `21:47` carries **three** of the four roots in Allah's own first-person plural, so two decks divide it at the āyah's own `ۖ` pause — the `al-malik@1`/`al-muizz@1`/`al-muzill@1` precedent on 3:26:

| Name | renders | bar 4 |
|---|---|---|
| **90 Al-Muqsit** | 21:47**a** `وَنَضَعُ ٱلْمَوَٰزِينَ ٱلْقِسْطَ …` + 3:18 (**four words**) | ✅ no trade |
| **55 Al-Haseeb** | 21:47**c** `… أَتَيْنَا بِهَا ۗ وَكَفَىٰ بِنَا حَـٰسِبِينَ` + 4:86 | ✅ no trade |
| **47 Al-Hakam** | 22:56 (from `يَحْكُمُ`) + 95:8 (**sūrah-final**, 95:9 → real 404) | ✅ no trade |
| **48 Al-Adl** | 4:40 + 6:115a | ⚠️ **traded** — `ٱلْعَدْل` is predicated of Allah's own act in exactly **one** place in the Qurʾān |

**The engines, separated by the reader's grievance rather than by synonyms for justice:** Al-Hakam = *unheard* (does a verdict ever land) · Al-Adl = *afraid of the verdict* (the arithmetic is lopsided your way) · Al-Haseeb = *unwitnessed* (you needn't make your case) · Al-Muqsit = *distrusts the process* (the scale was level first).

**Measured:** all four at **max shared word-run 3** against the 45-deck asset; intra-group max **4**. **The intra-group diff earned its keep** — the first pass found runs of **7–10 words between siblings**, because each takeaway quoted the others' engine descriptions verbatim in order to differentiate. Cross-referencing to separate had produced the duplication bar 3(c) exists to prevent. All four takeaways rewritten.

**Weakest points, flagged not smoothed:** **Al-Hakam's 22:56 has punishment on *both* sides** (22:55, 22:57) — the most likely of the four to be sent back. **Al-Haseeb's separation from `al-muhsi@1` is thin** (granularity vs sufficiency) and measures only 3 — §9cd's exact shape. **Al-Adl's bar-4 trade** is forced by the sweep, not chosen. **`ح-ك-م` (210 occurrences) was not exhaustively enumerated** — the one place §9cc's "fetch every occurrence" was unaffordable, and the likeliest spot for a missed better carrier.

---

## 4d · Wave B — the two remaining all-unstarted duʿā pairs, **drafted 2026-08-03**

**52 Al-Ali + 84 Al-Mutaali** (`.context/claims/52-84.md`) · **50 Al-Azeem + 58 Al-Majeed** (`.context/claims/50-58.md`).

| Name | carrier | verse beat | note |
|---|---|---|---|
| **52 Al-Ali** | **42:51** — the three modes of divine speech | 42:51 truncated at `عَلِىٌّ` | **2:255 is SPENT** (`al-qayyum@1` + 11 drafts); 42:51 demonstrates where 2:255 only labels |
| **84 Al-Mutaali** | **27:63** — guidance through darkness, winds before mercy | **one word** of 13:9 | `ٱلْمُتَعَالِ` occurs **once in the Qurʾān**, in a four-epithet chain that can't carry bar 1 |
| **50 Al-Azeem** | **56:68–72** — the water and the fire | **56:74**, the passage's own conclusion | verse beat and duʿā are **the same sentence**, once as command, once as response |
| **58 Al-Majeed** | **11:73** — the old woman who laughs | 85:15 | ⚠️ **bar 1 contested — see below** |

**Two refusals worth more than the decks:**

- **Al-Azeem does not use 39:67** (*the earth in His grip, the heavens folded in His right hand*) — the obvious text for this Name. **Shipped `al-malik@1` renders the ḥadīth parallel of exactly that scene** (*"Allah will hold the whole earth, and roll all the heavens up in His Right Hand…"*), and `al-qabid@1`'s drafter had independently refused it too. 39:67 also lacks the root. **Left free, with the refusal reasoning recorded** — a verifier may reasonably rule the Qurʾānic text should outrank a shipped ḥadīth rendering, in which case both decks need re-examining.
- **`م-ج-د` occurs FOUR times in the whole Qurʾān** — the shortest root sweep in the project, and therefore the only **complete** one. **Two are about the Qurʾān** (50:1, 85:21); 85:15 is a bare epithet; **11:73 is spoken by the angels.** So `مجيد` is predicated of Allah twice, and **neither is Allah speaking in His own voice.**

**Al-Majeed is the most likely deck in the project to be sent back, and the reason is a ladder question nobody has ruled on.** §9bk covers Allah's narration, Allah quoting Himself, `قُلْ`-instruction, a prophet's reported speech, and other human speech — **it says nothing about angelic speech inside divine narration**, which is exactly where 11:73 sits. The deck argues that `قَالُوٓا۟ … إِنَّهُۥ حَمِيدٌ مَّجِيدٌ` is Allah *choosing to narrate* an angelic declaration about Himself, closer to "quoting inside a narrative" than to "human speech about Allah". **If that fails, the Name has nowhere else to go** — the sweep is complete — and it becomes a refusal on bar 1 for lack of any divine-voice text. **A ḥadīth carrier was not sought; that route is unexplored, not closed** (§9bo).

**Unavoidably spent:** 11:73's `حَمِيدٌ` is **id 65 Al-Hameed's** word and is rendered by Al-Majeed, because it is inseparable from `مَّجِيدٌ` in the same clause. `حميد` has 17 occurrences, so id 65 has ample ground — **but that drafter should know this one is gone.**

**Measured:** all four at **max 4** against the 45-deck asset — every hit a function-word or scripture run. **Both intra-pair diffs repeated the judgment four's failure**: Al-Mutaali's takeaway quoted Al-Ali's phrase *"the address has a shape"* verbatim (5-gram), for the third time in this wave a takeaway created a collision *while trying to differentiate*. Both rewritten; pair maxima now 4 and 3.

---

## 4e · Wave C — 26+49 drafted, 60 drafted, **32 As-Sabur REFUSED**

**26 Al-Hakeem + 49 Al-Khabeer** (`.context/claims/26-49.md`) — they **split 34:1**, whose closing `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ` carries both Names; one word each, the 3:26 precedent. Carriers: **4:11**'s *"you know not which of them is nearer to you in benefit"* (Al-Hakeem — wisdom demonstrated as the reason a ruling is fixed rather than delegated) and **49:13** (Al-Khabeer — the whole apparatus of visible ranking built and then disqualified). **Their duʿā invokes `يَا لَطِيفُ` — a third Name, already shipped** — so neither deck's duʿā mentions its own Name, and all of bar 3(c) sits on the takeaway.

**60 Ash-Shaheed** (`.context/claims/60.md`) — **4:166**, `يَشْهَدُ`, root three times in one āyah, whole deck inside one sentence. Its move is **testimony, not perception**: `al-baseer@1` sees it, `ar-raqeeb@1` watches it, `al-aleem@1` knows it, `al-muhsi@1` counts it — **Ash-Shaheed says it.** The duʿā's second half asks exactly that (`فَٱشْهَدْ لِى` — *bear witness **for** me*), even though its vocative is Al-Baseer's. ⚠️ **Its duʿā beat is byte-identical to shipped `al-baseer@1`**, so a sweep against production returns a full-string match — expected, and the transcriber must be told.

### 32 As-Sabur — **refused, then overturned the same day. Now drafted.**

Draft: `2026-08-03-as-sabur-DRAFT.md`. The refusal is kept at `2026-08-03-as-sabur-REFUSAL-OVERTURNED.md` with an analysis of the error, because it is the **third of three** refusals in this project to be overturned and the pattern is now the finding — **ledger §9cg**.

**The sweep was right and the conclusion was wrong.** All three facts hold: **`ص-ب-ر` has 103 Qurʾānic occurrences in 8 forms and not one predicates the root of Allah**; the single ṣaḥīḥ predication (Bukhārī 7378, `أَصْبَرُ` — an elative, not the Name-form) is **rendered in full by shipped `al-haleem@1`**; and the Name-form's only attestation, **Tirmidhī 3507, is graded `Daʿīf`**. **That is exactly the evidence bar 4 requires before it yields** — *"tradeable, with a documented full-corpus sweep proving the trade is forced"* — and the refusal used it to close the Name instead.

**The error, precisely:** it collapsed **the bar-1 carrier and the bar-4 carrier into one text**, then read the absence of that text as the absence of a deck. §9bo names the same shape for the two earlier overturns (which collapsed bar-1 carrier and *story*). **The brief permits splitting all of them** — §4, plus `al-wahid@1`, `al-muhyi@1` and `al-adl@1` as precedent.

**What unlocked it was one question: what does As-Sabur mean that Al-Haleem does not?**

| deck | move |
|---|---|
| `al-haleem@1` (shipped) | **restraint** — power held back from what it could rightly do |
| **`as-sabur@1`** | **scale** — He is not holding back; He is not on your clock |

**Carrier: 32:5** — `يُدَبِّرُ ٱلْأَمْرَ مِنَ ٱلسَّمَآءِ إِلَى ٱلْأَرْضِ ثُمَّ يَعْرُجُ إِلَيْهِ فِى يَوْمٍ كَانَ مِقْدَارُهُۥٓ أَلْفَ سَنَةٍ مِّمَّا تَعُدُّونَ`. Free, Allah's own voice, **nothing in it is deferred** — the matter descends, is arranged and ascends on time; the only thing adjusted is the unit, and the āyah names the reader's own (`مِّمَّا تَعُدُّونَ`). n−1 clean, **n+1 closes on `ٱلرَّحِيمُ`**. **Verse beat 22:47's closing clause** (its punishment opening not rendered). **Measured against `al-haleem@1`: max 4**, a function-word run.

**35:45 would have been the wrong text even if it were free** — it is punishment *deferred*, which is Al-Haleem's axis. It is also that deck's verse beat.

**Two procedural failures worth copying out of §9cg:** the refusal **searched one axis and stopped** (never asked what the Name means that its blocker does not), and it **repeated a mistake it had itself documented four paragraphs earlier** — reporting the Name-form unattested after a literal-substring search, when `الصبور` *is* in Tirmidhī 3507 and was missed because of interposed diacritics (§9bq). Writing the warning does not immunise you against it.

**Still open on this deck:** bar 4 is traded, and if a verifier rules it untradeable when the Name-form has **no ṣaḥīḥ attestation at all**, the Name is genuinely undraftable. And the claim *"all 103 occurrences take a human subject"* rests on the corpus's own form-categorisation, **not on 103 individually-fetched āyāt** — §9cc says fetch them all, and that was not affordable. **One counterexample would turn the trade back into a pass.**

**A third instance of a pattern now worth naming: the catalogue `lesson` field keeps describing a neighbour's engine.** Id 55 Al-Haseeb's reads as `al-muhsi@1`'s; id 60 Ash-Shaheed's reads as `al-baseer@1`'s; id 32's *"waits for you with open arms"* is `at-tawwab@1`'s. **In all three the deck followed the scripture and flagged the divergence.**

---

## 4f · The last six — **analysed, not drafted.** Each has a named carrier and a named blocker

**These are the six hardest Names in the catalogue, and the reason is structural in every case: the Name-form is rare, or already spent by a shipped deck.** The root sweeps are done. Nobody needs to redo them.

| id | root sweep | the blocker | best route found |
|---|---|---|---|
| **18 Al-Muhaymin** | `مُهَيْمِن` = **2 occurrences** | **5:48's `وَمُهَيْمِنًا` describes the Qurʾān, not Allah**; 59:23 is an eight-epithet chain (labels, §9bk) | **5:48 story + 59:23's one word as the verse beat.** Bar 1 **contested** — the Al-Majeed pattern. Bar 5 findings: 5:47 ends `ٱلْفَـٰسِقُونَ`, 5:49 threatens affliction |
| **54 Al-Muqeet** | `qwt` = **2 occurrences, total** | 4:85's `مُّقِيتًا` is a trailing epithet; its n−1 (4:84) is a fighting āyah closing `أَشَدُّ تَنكِيلًا` | **41:10 as the carrier** — `وَقَدَّرَ فِيهَآ أَقْوَٰتَهَا`, Allah's own act of apportioning sustenance, **free**, in a clean creation passage (41:9–12) — **plus 4:85 as the verse beat. Bar 4 met twice. This one is genuinely draftable and is the easiest of the six** |
| **72 Al-Majid** | `م-ج-د` = **4 occurrences** | **all four are gone**: 50:1 and 85:21 describe the Qurʾān; 11:73 and 85:15 were taken by **`al-majeed@1` (id 58) hours earlier in this session** | **Bar 4 fully traded**, the As-Sabur pattern. **And the deeper question first: ids 58 and 72 are the same root with adjacent meanings** — this may be the project's one genuine merge case, which is an editorial call |
| **83 Al-Wali** | `ٱلْوَالِي` = **1 occurrence** (13:11) | it is a **negative construction** — *"they have not besides Him any patron"* — and **`al-waliyy@1` explicitly rejected 13:11 for exactly that** | Either accept the negation (and argue it demonstrates), or **trade bar 4** and carry the Name on a governance text. `ٱلْوَلِىّ` belongs to `al-waliyy@1` |
| **88 Malik-ul-Mulk** | `مَـٰلِكَ ٱلْمُلْكِ` = **1 occurrence** (3:26) | **3:26 is `al-malik@1`'s verse beat *and* its duʿā** — doubly spent, in production | **64:1 — `لَهُ ٱلْمُلْكُ وَلَهُ ٱلْحَمْدُ`, free, Allah's voice, root present.** Bar 4 met on `ٱلْمُلْك` but **not on the compound Name**, which is a partial trade to document. 67:1 is cited in the `al-malik` draft |
| **99 Ar-Rasheed** | `ر-ش-د` = **19 occurrences** | **`ٱلرَّشِيد` is never predicated of Allah.** The three `rashīd` occurrences (11:78, 11:87, 11:97) are all **human**. 2:186 (`يَرْشُدُونَ`, Allah's own voice) is **SPENT** — `al-mujeeb@1`'s verse beat; 18:10 is spent by `ar-raheem@1` | **Bar 4 traded**, As-Sabur pattern. 72:2 (`يَهْدِىٓ إِلَى ٱلرُّشْدِ`) is free but is **the jinn speaking about the Qurʾān**; 40:38 is a believer's speech |

**Four of the six need a traded or contested bar — and that is now well-precedented rather than exceptional.** As-Sabur (§4e) established the shape: a **complete** root sweep proving the trade is forced, a carrier on a different axis from the blocking neighbour, and the trade stated as the deck's load-bearing weakness. **Do not refuse any of these six on "no single text does everything"** — that is §9cg, and it has been wrong three times out of three.

**Two structural findings from this batch that the shared-duʿā map does not catch:**

- **Ids 56 and 89 share their *entire root*** (`ج-ل-ل`, two occurrences, both the same phrase) and are **not** a §9ce group, because they do not share a `dua_arabic`. They were partitioned one āyah each.
- **Ids 67 and 68 (Al-Mubdi / Al-Muid) are the same case**: every Qurʾānic occurrence of one Name's root contains the other's, because the Qurʾān states originating and restoring in one clause. **`al-muid@1` renders 30:27 whole, `يَبْدَؤُا۟` included.**

**§9ce's map is built on `dua_arabic` collisions and will keep missing root-level pairs. That is now a known gap.**

**Three shipped decks spend an unstarted Name's ground**, all found this wave and all the same failure class: `al-baseer@1`'s duʿā renders **Ash-Shaheed's root**; `al-haleem@1` renders **As-Sabur's only ṣaḥīḥ carrier**; `as-salam@1`'s duʿā renders **Dhul-Jalali wal-Ikram in full**. **None was catchable before shipping, because no check existed. The rule earned (§4e §6) is now: before shipping any deck, check whether its carrier is the only carrier for a Name it shares a duʿā or a root with.**

**And a fourth instance of the `lesson`-field pattern:** id 67's *"Al-Mubdi created you as something entirely new. You are not a copy"* is **id 97 Al-Badi's** engine (no precedent in kind), not Al-Mubdi's (a first instance guaranteeing a second). With ids 55, 60 and 32, that is **four catalogue `lesson` fields describing a neighbour's move.** In all four the deck followed the scripture and flagged it.

---

## 4g · Wave F — the last six, **drafted 2026-08-03**

`.context/claims/wave-F.md`. **Every one needed either a contested bar 1 or a split/traded bar 4** — which is what made them last, and what §9cg says is not grounds for refusal.

| id | carrier | verse beat | the hard part |
|---|---|---|---|
| **54 Al-Muqeet** | **41:10** — sustenance measured into the earth before anyone needed it | 4:85 | **The complete sweep: `ق-و-ت` has 2 occurrences and this deck renders both.** The only deck in the project that can say that |
| **18 Al-Muhaymin** | **5:48** — the Book *confirming* and *standing over* prior scripture | 59:23, one word | ⚠️ **bar 1 contested.** 2 occurrences: at 5:48 the referent is **the Book**; 59:23 is an eight-epithet chain |
| **72 Al-Majid** | **17:70** — the children of Adam honoured as a category | **85:15** | Root exhausted by id 58 — **resolved by re-cutting `al-majeed@1`** |
| **83 Al-Wali** | **10:3** — `يُدَبِّرُ ٱلْأَمْرَ`, present tense, continuous | 13:11 | Name-form occurs **once**, as a **negation** `al-waliyy@1` rejected |
| **99 Ar-Rasheed** | **18:17** — the sun angled around the sleepers for years | 72:2 | `ٱلرَّشِيد` **never predicated of Allah**; 2:186 and 18:10 both spent |
| **88 Malik-ul-Mulk** | **64:1** — everything *acts*, only He *owns* | 64:1 | Compound Name occurs **once** (3:26) and is **doubly spent** |

**A re-cut was made, and it is disclosed as a conflict of interest.** Ids 58 and 72 share `م-ج-د`, which has **four Qurʾānic occurrences — two describing the Qurʾān**. `al-majeed@1`'s R0 took both divine ones and left id 72 nothing. **It now renders 11:73 only, and 85:15 goes to `al-majid@1`.** This also **removed `al-majeed@1`'s worst bar-5 exposure** — it no longer touches Sūrat al-Burūj at all. **The drafter who made the re-cut is the one who needed the text; a verifier should check it is an improvement and not a rationalisation.** The argument that it is, is in that deck's R1 section.

**A fourth production collision, and the sharpest yet.** Shipped **`al-malik@1`'s duʿā is `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ` — a strict prefix of id 88's duʿā, and it speaks id 88's entire Name.** With `al-baseer@1`→id 60's root, `al-haleem@1`→id 32's only ṣaḥīḥ carrier, and `as-salam@1`→id 89 in full, that is **four shipped decks spending an unstarted Name's ground.** All catalogue-locked, all disclosed, **none catchable before shipping because no check existed.**

**A §9by data point worth keeping:** `corpus?q=hymn` **does not return `ه-ي-م-ن`** — it returns the entries for آدم, with plausible-looking āyāt and no error. **Al-Muhaymin's two occurrences were established by direct fetch instead**, and that is stated in the draft as its most under-verified claim.

**And a fifth `lesson`-field instance:** id 18's *"Nothing escapes His watchful care"* is `ar-raqeeb@1`'s move (watching), where the Arabic `مُهَيْمِن` means *standing over with authority*. **Five catalogue `lesson` fields now describe a neighbour's engine** — ids 18, 32, 55, 60, 67. In every case the deck followed the scripture and flagged it.

---

## 5 · Open items that outlive the drafting work

- **Five must-ship-together pairs are ruled and none is enforced in code** (§9bg): Aḍ-Ḍārr/An-Nāfiʿ, Al-Qābiḍ/Al-Bāsiṭ, Al-Khāfiḍ/Ar-Rāfiʿ, Al-Muʿizz/Al-Muẓill, Al-Muqaddim/Al-Muakhkhir. The gate's pair assertion only runs inside a loop over `chipKeys`, and all ten decks carry an empty one — so it never evaluates them. **Engineering decision needed before ship.**
- **Two duʿā pins await a verifier's yes/no** — `al-jami@1` → `Qur'an 3:9`, and `al-awwal@1`/`al-akhir@1` → `Sahih Muslim 2713a (excerpt)`. Each becomes a line in `renderedDuaSources`.
- **AI personalisation (§9br)** is wired: `bridge` and a new optional trailing `reflection` beat are the two slots the runtime may replace; both are gate-forbidden from carrying `source` or `arabic`. **28 of 48 pending drafts have authored a `reflection` beat** — every deck drafted 2026-08-03 has one; the ~20 without are the earlier wave — the rest need one added at fix time. Adding one is cheap and it is the fallback for a slot that is otherwise **empty offline, on model failure, and outside the personalised tier**, which is most of when it renders.
- **Runtime rejection of scripture-shaped generated text is not built.** The gate guarantees the *slot* can't hold scripture; nothing yet inspects what the model puts in it.
- **The staged catalogue SQL** (`supabase/staged/fix_catalog_hadith_2026_08_03.sql`) has never been applied and its drift guard has never run.

---

## 6 · R2 verification pass — 2026-08-04

**All 54 pending drafts reviewed** on the three axes the founder named: completion · narration authenticity (nothing weak or fabricated) · story impact and fit to the Name. Full record: [`2026-08-04-R2-VERIFICATION.md`](./2026-08-04-R2-VERIFICATION.md). Each draft carries a verdict in its metadata block or an `R2 REVIEW STAMP` at the head.

**Eight defects found and fixed. One was serious.**

`al-majeed@1`'s beat 6 read *"Honorable Owner of the Throne — Qur'an 11:73"*. **Those are 85:15's words; 11:73 does not contain them.** The R1 re-cut changed the citation and left the text, because the string replacement written for the text **failed to match and failed silently** — and it survived because the Sources table, bar 4, bar 5 and the bar-3(b) sweep all still described the old cut and therefore agreed with each other. **Four tables agreeing with each other and disagreeing with the beat.** Ledger **§9ch**.

The other seven: `al-mateen@1`'s 50:38 was **no published translation** while claiming `translations=20` · `al-qawiyy@1`'s 30:54 **spliced two translations** · `al-khabeer@1` deleted `ٱلْحَكِيمُ` from **inside** 34:1 behind an edge ellipsis · `al-bari@1`'s 57:23 connective · `al-hakeem@1`'s 4:11 (*"is nearer"* → *"are nearest"*) · `an-nafi@1`'s 2:164 (*"heaven"* → *"heavens"*) · `al-wajid@1`'s duʿā beat was **not byte-exact** against the locked catalogue string (dagger alif). `al-barr@1`'s 52:28 was **not** changed — its disclosure was widened instead, because **no published translation reads "We used to call on Him before this"** and only the Name-word was ever argued. **That one needs a ruling.**

**On authenticity, the answer is clean.** Every ḥadīth rendered on a beat was re-fetched and its printed grade re-read: **Ṣaḥīḥ or Ḥasan, without exception.** The one `Daʿīf` narration in the corpus — **Tirmidhī 3507**, the 99-Names enumeration, and the *only* attestation of `ٱلصَّبُور` and `ٱلْجَلِيل` — is cited in bar-4 reasoning on **both** decks and **on no beat**, which is the correct handling. **No drafter in this wave inflated a grade**; two disclosed material that undercut their own deck.

**The safety property holds: 0 of 54** decks put a `source`, an āyah citation or a single Arabic codepoint in a `bridge` or `reflection` slot.

**The one open completion gap: 19 decks have no `reflection` beat** (all from the earlier wave). Listed in §5 of the verification record. **Not authored in that pass on purpose** — writing the beats and then verifying them is the same conflict of interest the pass criticises in the `al-majeed@1` re-cut. It is a small drafting wave: one question per deck, plus the sweep.

**And the `al-majid@1` re-cut was audited and stands, with one claim struck.** Ids 58 and 72 are **not the same Name-form** — id 58 is `ٱلْمَجِيدُ`, id 72 is `ٱلْمَاجِدُ`, which **occurs nowhere in the Qurʾān**. So 85:15's word is the neighbour's Name-form on id 72's deck, the deck's claim that it was *"the Name's own form"* was false, and **bar 4 for id 72 is a form-level trade whichever āyah it gets.** The bar-5 exposure the re-cut "removed" from id 58 did not disappear — **it moved to id 72**, which now discloses it. Both files say so.

---

## 7 · Blind adversarial verification — COMPLETE, 2026-08-04

**All 54 pending drafts blind-verified.** 11 verifiers, batched by shared duʿā and pair so group rulings were made once. Coverage checked: no gaps, no duplicates. Every verdict file is in [`verdicts/`](./verdicts/), each with a citation table of every fetch and what the text actually returned.

**→ [`verdicts/2026-08-04-DECISION-SHEET.md`](./verdicts/2026-08-04-DECISION-SHEET.md) is the founder's page.** It is the only file that needs reading to act.

**Outcome: 34 ship as-is · 8 ship after a named mechanical fix · 11 need a founder ruling · 1 refuse.**

**The refusal is `al-majeed@1` (58), and it settles a standing open question.** The **§9bk ladder now rules that angelic speech inside divine narration does not carry bar 1** — the deck's argument that Allah's *choosing to narrate* it lifts the rung **proves too much**, since Allah narrates a prophet's reported speech too and that rung is already excluded. `م-ج-د` re-confirmed complete at 4 occurrences; the unexplored ḥadīth route was searched and Tirmidhī 3507 is `Daʿīf`. **Fourth refusal in the project, and the first that closed its routes on fetched evidence rather than on argument.** Ids 58/72 ruled **not** to merge.

**The most important finding is about method, not about a deck.** `al-musawwir@1`'s bar-5 successor sweep is **5 of 6 fabricated or mislabeled** — 3:5 is 31:28's text, 82:9 is 50:45's, 40:65 is 23:116's, 82:6 splices two āyāt, and the "cattle simile" at 40:63 exists in no āyah. **It survived R0, R1, a blind Sonnet verifier and R2 because every pass scoped itself to citations that RENDER.** Nobody fetched the ones that exist only to justify a bar-5 verdict. **And the blind verifier marked 40:65 ✅ "matches exactly" — a verification error inside the verification.**

A coordinator sweep then audited **every off-beat quoted citation (21) and every table-format beat (25) across all 54 drafts**: the fabrication is confined to that one deck, plus one unattributed re-rendering in `al-mutakabbir@1` (45:37, now fixed). **Still unaudited project-wide: successor sweeps written as Arabic-plus-gloss**, which neither pattern reaches.

**The thing that can hurt a user is not a citation.** Three verifiers independently confirmed **nothing stops `ad-darr@1` — *The Distresser* — shipping without `an-nafi@1`**. Both gate assertions loop over `chip_keys` and every pair deck carries `[]`. **Populating it does not fix this; it breaks the gate** — no pair deck declares `position_in_pair` 1 or 2 or carries a synergy beat, so naive population newly fails the *"exactly two decks, positions 1 and 2"* test. The five pairs need their own mechanism.

**Three duʿā pins ruled YES** and are ready for `renderedDuaSources`: `al-jami@1` → `Qur'an 3:9` (no qualifier needed) · `al-awwal@1`/`al-akhir@1` and `az-zahir@1`/`al-batin@1` → `Sahih Muslim 2713a (excerpt)` · `an-nafi@1` → `Sunan Ibn Majah 925`.

**§5's reflection-beat item is reframed: 0 of 45 shipped decks have one.** The 19 drafts without it are not defective — the beat is new and the whole shipped corpus predates it. Asset-scope decision, not a ship blocker.

**Five corrections to the R2 pass were accepted**, including that it parsed only `>` blockquote beats and so never checked twelve table-format drafts' beats, and that it rendered collection-level *inference* (`Ṣaḥīḥ ✅`) identically to a *read* grade line. Both are listed in §5 of the decision sheet.
