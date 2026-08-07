# Verdict — batch `antonym-pairs` (43 Al-Muizz · 44 Al-Muzill · 77 Al-Muqaddim · 78 Al-Muakhkhir)

**Blind adversarial verification, 2026-08-04.** I did not write these decks. Every citation below was fetched live during this review from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International), `corpus.quran.com/qurandictionary.jsp`, and `sunnah.com` via Wayback raw captures. The twin-diffs (§4) were run programmatically by me over the exact rendered `primary` strings transcribed from each draft's beats table — not read off the drafters' own tables. Where I write "confirmed," I fetched it myself and it matched; where I write a discrepancy, I fetched it myself and it did not.

---

## 1 · Citation table — every fetch, what it actually says

| Claim (as it reaches a beat) | Source fetched | Text returned | Verdict |
|---|---|---|---|
| Al-Muizz beat 5 / Al-Muzill beat 5: `3:26` | `api.quran.com/.../3:26` | Arabic: `...وَتُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ...` Saheeh: *"...You honor whom You will and You humble whom You will..."* | ✅ **both clauses confirmed, verbatim, adjacent, joined by one `وَ`** |
| Al-Muizz beat 5 renders only | — | *"…You honor whom You will…"* | ✅ matches the fetched clause exactly, no more, no less |
| Al-Muzill beat 5 renders only | — | *"…You humble whom You will…"* | ✅ matches the fetched clause exactly, no more, no less |
| Shipped `al-malik@1` verse beat, checked against the live asset | `assets/content/name_stories.json` | *"Say, 'O Allah, Owner of Sovereignty, You give sovereignty to whom You will and You take sovereignty away from whom You will… In Your hand is [all] good…'"* | ✅ **confirmed disjoint** — elides the honor/humble clause internally and the `قَدِيرٌ` clause at the trailing ellipsis. **The three-way split of 3:26 (al-malik@1 / al-muizz@1 / al-muzill@1) is clean: no deck renders another's clause.** |
| 3:26 successor sweep | `.../3:25`, `.../3:27`, `.../3:28` | 3:25 closes *"they will not be wronged"*; 3:27 runs to provision, no punishment; 3:28 is a warning two āyāt out, not quoted | ✅ confirmed clean, matches both drafts |
| Al-Muizz beats 2–4: Ṣaḥīḥ Muslim 2588 | `web.archive.org/.../sunnah.com/muslim:2588` | Arabic: `مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلاَّ عِزًّا وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ` — English on the page: *"Abu Huraira reported Allah's Messenger (ﷺ) as saying: Charity does not decrease wealth, no one forgives another except that Allah increases his honor, and no one humbles himself for the sake of Allah except that Allah raises his status."* | ✅ **confirmed as ONE sentence, one narration, one isnād** — the deck's three beats are a clean split of one hadith, not stitched from several |
| Muslim 2588 n−1: Muslim 2587 | `.../muslim:2587` | *"When two persons indulge in hurling (abuses) upon one another, it would be the first one who would be the sinner..."* | ✅ confirmed, unrelated topic, no punishment bearing on this deck |
| Muslim 2588 n+1: Muslim 2589 | `.../muslim:2589` | not retrievable — this Wayback capture returned a JS-rendered shell with no hadith text in the static HTML | ⚠️ **could not independently verify.** Topic (definition of backbiting) is plausible and consistent with the book's chapter sequence, but I did not read it with my own eyes. Flagged in §6. |
| Al-Muqaddim / Al-Muakhkhir bar-1 carrier: Bukhārī 6398 | `web.archive.org/.../sunnah.com/bukhari:6398` | Arabic: `...اللَّهُمَّ اغْفِرْ لِي مَا قَدَّمْتُ وَمَا أَخَّرْتُ وَمَا أَسْرَرْتُ وَمَا أَعْلَنْتُ، أَنْتَ الْمُقَدِّمُ، وَأَنْتَ الْمُؤَخِّرُ، وَأَنْتَ عَلَى كُلِّ شَىْءٍ قَدِيرٌ` (page's own transliteration, not a translation, confirming the R1→R2 fix's premise) | ✅ **both epithets confirmed real, in the same sentence, coordinated by `وَ`, with a third clause (`qadīr`) after them** |
| Al-Muqaddim beat 4 renders only | — | *"You are the One Who makes the things go ahead…"* | ✅ trailing ellipsis; the twin's clause and the `qadīr` clause are both absent, in Arabic and English |
| Al-Muakhkhir beat 2 renders only | — | *"…and You are the One Who delays them."* | ✅ leading ellipsis; the twin's clause and the `qadīr` clause are both absent, in Arabic and English |
| `al-qadir@1`'s declination of the `qadīr` clause | `2026-08-03-al-qadir-DRAFT.md:116` | *"...A ṣaḥīḥ substitute is understood to exist and to have been deliberately withheld (Bukhārī 6398's clause `وَأَنْتَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ`)... Recorded so the founder can see the option was offered and declined with a reason, not overlooked."* | ✅ **confirmed real** — not a claim invented for this pair |
| Al-Muqaddim beat 5: `49:1` | `.../49:1` | Arabic: `يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ لَا تُقَدِّمُوا۟ بَيْنَ يَدَىِ ٱللَّهِ وَرَسُولِهِۦ ۖ وَٱتَّقُوا۟ ٱللَّهَ ۚ إِنَّ ٱللَّهَ سَمِيعٌ عَلِيمٌ` Saheeh: *"O you who have believed, do not put [yourselves] before Allāh and His Messenger but fear Allāh. Indeed, Allāh is Hearing and Knowing."* | ✅ confirmed, verbatim; the deck's ellipsis correctly signals the omitted "but fear Allāh" clause |
| 49:1 successor sweep | `.../48:29`, `.../49:2`, `.../49:3` | 48:29 clean/positive; 49:2 carries a conditional loss-of-deeds warning (disclosed, not quoted); 49:3 clean/positive, resolves forward | ✅ confirmed, matches both drafts exactly |
| Al-Muakhkhir beats 3–5: `71:3`, `71:4` | `.../71:3`, `.../71:4` | 71:3: *"To worship Allāh, fear Him and obey me."* 71:4: *"He [i.e., Allāh] will forgive you of your sins and delay you for a specified term. Indeed, the time [set by] Allāh, when it comes, will not be delayed, if you only knew."* | ✅ confirmed verbatim, Saheeh International |
| 71:1–6 successor sweep | `.../71:1`, `.../71:2`, `.../71:5`, `.../71:6` | 71:1 names *"a painful punishment"* (disclosed, deliberately not quoted); 71:2, 71:5, 71:6 clean | ✅ confirmed, matches the draft's own disclosure exactly |
| `q-d-m` full-corpus sweep | `corpus.quran.com/qurandictionary.jsp?q=qdm` | *"occurs 48 times... in eight derived forms: twice Form I, 27 times Form II, twice Form V, four times Form X, once `aqdamūn`, eight times `qadam`, three times `qadīm`, once Form X participle"* | ✅ **confirmed exactly** — matches the draft's breakdown (2+27+2+4+1+8+3+1=48) digit for digit |
| `ʾ-kh-r` full-corpus sweep | `corpus.quran.com/qurandictionary.jsp?q=Axr` | *"occurs 250 times... in six derived forms: 15 Form II, 3 Form V, 6 Form X, 155 `ākhir`, 70 `ākhar`, 1 Form X participle"* | ✅ **confirmed exactly** — matches the draft's claim of 250/6 forms/15 Form-II |
| The `112:1`/`قُلْ` bar-1 precedent Al-Muakhkhir relies on | `2026-08-03-al-ahad-DRAFT.md:43-57` | *"`قُلْ` is Allah commanding the Prophet ﷺ to recite the content that follows... 112:1 fails bar 1 on this reading."* | ✅ **confirmed real**, not fabricated for this draft |
| Catalogue duʿā, ids 43/44 | `collectible_names.json` | byte-identical `dua_arabic`/`dua_translation` across both ids | ✅ confirmed programmatically |
| Catalogue duʿā, ids 77/78 | `collectible_names.json` | byte-identical `dua_arabic`/`dua_translation` across both ids | ✅ confirmed programmatically |
| `name_intro` glosses | `collectible_names.json` | id 43 `english`="The Bestower of Honor", 44="The Humiliator", 77="The Expediter", 78="The Delayer" | ✅ all four decks render byte-identical to catalogue `english`, never `meaning` |
| chip_keys / ship-gate reach | `test/content/name_stories_ship_gate_test.dart` | `chipKeys` is a **fixed 7-item set** (`anxiety, far-from-allah, guilt, heavy, rizq, sign, unseen`); both pair-assertion tests iterate `for (final chip in chipKeys)` then filter `d['chip_keys'].contains(chip)` | ✅ **confirmed** — with `chip_keys: []` on all four decks, neither test's filter ever selects any of them; the tests silently pass with zero evaluation of this pair |
| 45-deck asset count | `assets/content/name_stories.json` | `len() == 45`; none of ids 43/44/77/78 present | ✅ confirmed — these four are still drafts, not yet transcribed |

**No fabrication found anywhere in this batch's sourced material.** Every quotation I checked against a live fetch matched, word for word, the published translation named.

---

## 2 · Five-bars verdict per deck

### Al-Muizz (43)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | `تُعِزُّ`, finite Form-IV verb, 2nd person, Allah addressed in a taught `قُلِ` prayer — confirmed by direct fetch of 3:26 |
| 2 | **PASS** | No beat states "you deserve honor." The hadith shows a mechanism; the verse shows the act in Allah's own grammar. |
| 3 | **PASS** | Confirmed disjoint from `al-malik@1` (fetched from the live asset) and from `al-muzill@1` (see §4). Formulaic "whom You will" frame shared with both siblings, correctly treated as non-blocking (§9o precedent). |
| 4 | **PASS, disclosed trade** | `تُعِزُّ` carries the root on the verse beat directly — not a trade at all on this bar; the *story*'s root (`عِزًّا`, a noun object of `زَادَ`) is the traded element, correctly disclosed. |
| 5 | **PASS** | Muslim 2587/2589 unrelated topics (2589 unverifiable, see §6); 3:25/27/28 clean, confirmed by fetch. |

**Verdict: SHIP**, contingent on the pairing question in §5.

### Al-Muzill (44)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | `تُذِلُّ`, same construction as the twin, confirmed |
| 2 | **PASS** | The idol's failure is shown (cannot speak, cannot guide) before the consequence is named in the Qur'ān's own words |
| 3 | **PASS** | See §4 |
| 4 | **PASS, disclosed trade** | Same shape as the twin — `تُذِلُّ` carries the root directly on the verse beat; the story's root is `وَذِلَّةٌ`, a noun-object, correctly disclosed as a trade |
| 5 | **CONTESTED — see §3, my own ruling below, not deferred to the drafter** | 7:152 itself (not a neighbour) is a rebuke passage: *"will obtain anger from their Lord and humiliation in the life of this world... thus do We recompense the inventors [of falsehood]"* |

**Verdict: SHIP WITH FOUNDER-LEVEL SIGN-OFF SPECIFICALLY ON BAR 5**, not a mechanical pass. See §3.

### Al-Muqaddim (77)

| bar | verdict | evidence |
|---|---|---|
| 1 | **TRADED, disclosed, and I accept the trade** | No verse in the Qur'ān carries `q-d-m` as Allah's positive finite act (corpus-confirmed 48/8, zero Allah-subject positive occurrences read individually in the draft). The naming clause of Bukhārī 6398 is the only attestation; it is a nominal address, not a finite verb, but it is Allah's own vocative address *from the Prophet's own mouth in a taught prayer*, and the same standard the corpus applies to `al-malik@1`/`al-muizz@1`/`al-muzill@1`'s split of 3:26 licenses this. |
| 2 | **PARTIALLY MET, disclosed correctly** — beat 4 states, 49:1 shows without asserting bar 1 | matches draft's own disclosure |
| 3 | **PASS**, with one correction — see §4 | drafts' own "zero at n≥4" claim is **wrong**; true max is 5 words, see §4 |
| 4 | **MET** | `الْمُقَدِّمُ` on the naming axis; 49:1's `تُقَدِّمُوا۟` independently, weakly, human-subject-negated |
| 5 | **PASS** | 48:29–49:3 clean on both sides, confirmed by fetch; no punishment in the swept window |

**Verdict: SHIP**, contingent on the pairing question in §5.

### Al-Muakhkhir (78)

| bar | verdict | evidence |
|---|---|---|
| 1 | **TRADED, disclosed, and I accept the trade** — same reasoning as the twin, and I independently confirm the `112:1`/`قُلْ` precedent is real (not fabricated for this draft) and correctly applied: Nūḥ's reported speech (71:3–4) cannot carry bar 1 if `قُلْ`-dictated recitation cannot | confirmed, §1 |
| 2 | **MET, and the register discipline holds** | No beat promises relief or frames the wait as protective; checked every beat myself against the two banned phrases, neither appears |
| 3 | **PASS**, with one correction — see §4 | same correction as the twin |
| 4 | **MET** | `الْمُؤَخِّرُ` on the naming axis; 71:4's `يُؤَخِّرْكُمْ`/`لَا يُؤَخَّرُ` independently, inside Nūḥ's reported speech, disclosed as not carrying bar 1 alone |
| 5 | **PASS, with one disclosed exposure** | 71:1 names "a painful punishment," confirmed by fetch, correctly excluded from the excerpt and disclosed rather than quoted; the swept window itself (71:2–71:6) is clean |

**Verdict: SHIP**, contingent on the pairing question in §5.

---

## 3 · Bar 5 for Al-Muzill — my own ruling, not deferred

**The task brief asks me to rule on this without deferring to the drafter, and I want to be honest that this is a close call I went back and forth on.**

The excerpt itself — not a neighbour, the actual rendered text on beats 3–4 — reads: *"Indeed, those who took the calf [for worship] will obtain anger from their Lord and humiliation in the life of this world... and thus do We recompense the inventors [of falsehood]."* I fetched this myself; it is exactly what the deck renders. This is explicit divine anger and humiliation, stated as consequence, on a deck for a Name whose meaning is *The Humiliator*, potentially met by someone who is themself feeling humiliated, at 11pm. The brief's own bar-5 language — *"no rebuke passages... no accusation of the reader"* — describes this passage's content at the sentence level, not merely its neighbours. On a strict reading, **this is a rebuke passage on the beat itself**, and I do not think that fact is fully answered by checking that n−1/n+1 avoid Fire imagery, because bar 5 as stated is broader than a neighbour check.

**The mitigating case, which I find genuinely substantial, not merely offered:**

1. **The target is a historical third party for a named act**, not the reader — grammatically and narratively, "those who took the calf." No beat uses second person for the consequence. The bridge names "someone," never "you."
2. **No Fire, no Judgment Day.** "Humiliation in the life of this world" is explicitly this-worldly, not eschatological — a real, checkable distinction from the passages this project has rejected elsewhere on bar-5 grounds (`35:41`-class rejections all carry Hereafter or Fire language; this does not).
3. **The deck's own construction is unusually careful**, and I verified this by fetching what it deliberately avoided: 7:149-151 (Mūsā's anger, violence, the mercy/forgiveness clause carrying `gh-f-r`/`r-ḥ-m`) and 7:153 (the mercy/repentance clause immediately following the excerpt) are both fetched-and-confirmed as real, and both are genuinely absent from every beat. This is not a drafter who didn't look — it is one who looked at the escape routes and chose not to take them, for reasons stated in the file.
4. **The takeaway does real reframing work, not merely reassurance-by-assertion**: *"The calf could not speak and could not guide — it was never a real source of standing."* This is a textually grounded claim (7:148's own rhetorical question), not an authored promise like "it will be okay" — it redirects the reader from *"I might be humiliated"* toward *"the false things I measure myself against have no real standing,"* which is a materially different message from what the raw verse alone would communicate.
5. **"Reject the Name" was ruled off the table by the founder** (ledger, 2026-08-03) for exactly this class of Name, which narrows the actual decision space to *how* Al-Muzill ships, not *whether*.

**My ruling: CONTESTED, and I resolve it in favor of shipping — but only with the register risk flagged for the founder's own eyes, not waved through as a clean pass.** The drafter's own bar-5 row calls this *"the hardest bar for this Name, and answered structurally"* — I read that as an honest hedge, not a claim of clean passage, and I want to be equally honest in the other direction: I do not think a mechanically-applied bar 5 clears this beat, and a reader in acute distress who happens to feel humiliated could plausibly read "anger from their Lord and humiliation" and feel accused, the third-party grammar notwithstanding. I would not block the deck on this alone, given points 1-5 above, but I would not certify it "MET" either. **This is the single row in this batch a founder should personally read before it ships**, and I note with some concern that `2026-08-04-R2-VERIFICATION.md`'s own "where a blind verifier should go first" list (§4 of that file) does not mention it at all, despite the drafter's own file flagging it as the hardest bar it faces — see §7 below.

---

## 4 · The twin diff, run programmatically — max shared word-run

**Method:** I transcribed the exact `primary` field text for every beat of each deck (verbatim from the beats tables in §1 of each draft, including quotation marks and preambles, excluding only markdown formatting and the visible ellipsis characters, which do not affect word tokenization), then computed the longest common contiguous token run between every beat of one deck and every beat of its twin, via dynamic-programming longest-common-substring over lowercased word tokens. I ran this twice per pair: once over all beats, once excluding beat 6 (the catalogue-locked shared duʿā, which is forced byte-identical by the ship gate and is not a drafting choice — including it in a "collision" measurement would be meaningless).

### Al-Muizz vs Al-Muzill

- **Including the shared duʿā beat:** 17 words (the entire duʿā sentence, expected and disclosed).
- **Excluding the shared duʿā beat: max shared run = 3 words — `"whom you will"`**, between Al-Muizz beat 5 and Al-Muzill beat 5. This is 3:26's own repeated grammatical frame across its four parallel clauses (also present in shipped `al-malik@1`'s rendering of the sovereignty clauses, which I confirmed directly from the live asset in §1). **This matches the draft's own claim of "zero hits at n≥4"** — 3 is below that threshold, and I confirm it independently.

**My verdict on this pair's move:** genuinely different, not the same move negated. Al-Muizz's engine is a hadith about voluntary human action (charity, forgiving, self-effacement) *causing* an increase in status — "letting go first." Al-Muzill's engine is the exposure of a fabricated object's failure on its own terms — "it was never real" — with the consequence borne by a community's act of false worship, not by a virtue withheld. Neither deck's takeaway is reachable by negating the other's. A user who reads "give and you rise" does not thereby learn "withhold and you fall" from this pair; they learn two structurally unrelated things.

### Al-Muqaddim vs Al-Muakhkhir

- **Including the shared duʿā beat:** 16 words (the entire duʿā sentence, expected and disclosed).
- **Excluding the shared duʿā beat: max shared run = 5 words — `"you are the one who"`**, between Al-Muqaddim beat 4 (*"You are the One Who makes the things go ahead…"*) and Al-Muakhkhir beat 2 (*"...and You are the One Who delays them."*).

**This is a real discrepancy against both drafts' own claims.** `al-muqaddim@1`'s §5c states *"Zero hits at n ≥ 4"* and `al-muakhkhir@1`'s §5g states *"zero hits at n ≥ 4"* for the twin diff specifically. My own measurement, run directly against the transcribed beat text (including beat 2's full preamble, "The Prophet's ﷺ own prayer names it directly:"), finds **5**, not 0. I checked this by hand as well as programmatically: `you / are / the / one / who` appears verbatim in both beats, immediately preceding the diverging verb (`makes` vs `delays`).

**Is this a real collision, or the same class of finding as "whom you will"?** I judge it to be the same class — it is the Muhsin Khan translator's own parallel rendering of the Arabic's own parallel construction (`أَنْتَ الْمُقَدِّمُ، وَأَنْتَ الْمُؤَخِّرُ` — literally "you [are]... and you [are]..."), split across two decks by the same technique the ledger already blesses for 3:26. Under the ledger's own §9o formulaic-construction ruling and the precedent this exact pair invokes for 3:26, I would rule this **non-blocking** on the same grounds. **But it is still a measured fact the drafts got wrong**, not merely a difference of interpretation — both files assert "zero" where the true number is "five," and 5 is above this project's own stated ≥3-word finding bar (§9bl). This is the same failure shape the ledger names in §9bm: *"the stale sweep was not wrong about its conclusion, it was wrong about its evidence."* I am reporting the evidence.

**My verdict on this pair's move:** also genuinely different, not the same move negated. Al-Muqaddim's engine is "the order is His" — a private confession grounding forgiveness in Allah's authorship of sequence, paired with a Qur'ānic boundary about not getting ahead of Allah and His Messenger. Al-Muakhkhir's engine is "the boundary is exact" — Nūḥ's fixed, named term as evidence that a wait has content and is not a void. Neither is reachable by negating the other; "your turn is ordered" and "your wait has an exact edge" are not mirror-image claims.

---

## 5 · The ship-gate mechanic is broken, and the consequence for a reader

**Confirmed by direct reading of `test/content/name_stories_ship_gate_test.dart`** (§1 above). `chipKeys` is a hardcoded 7-item set of mood-tags (`anxiety, far-from-allah, guilt, heavy, rizq, sign, unseen`) unrelated to any of these four Names. Both must-ship-together assertions — *"every rendered chip maps to exactly two decks (positions 1 and 2)"* and *"exactly one pair-synergy beat per pair, carried by position 1"* — begin `for (final chip in chipKeys) { final forChip = decks.where((d) => (d['chip_keys'] as List).contains(chip)); ... }`. With `chip_keys: []` on all four of these decks (confirmed in every beats-table header), `d['chip_keys'].contains(chip)` is `false` for every `chip` in the fixed set, for every one of these four decks, always. **`forChip` is always empty for them. Neither test body ever executes for these decks — not "passes vacuously" in a way that still checks something, but literally never iterates over them at all.**

**The consequence for a reader is exactly what the ledger already names and I independently confirm: nothing in CI stops Al-Muzill from shipping without Al-Muizz, or Al-Muakhkhir without Al-Muqaddim.** If a future transcription pass adds `al-muzill@1` to `assets/content/name_stories.json` with `review_verdict: "good"` and simply never gets around to `al-muizz@1` — a scheduling accident, not a deliberate act — the full test suite goes green. A reader who draws the Al-Muzill card via the daily gacha would then meet *The Humiliator*, its 7:152 anger-and-humiliation passage, and its takeaway that depends on "the sentence that gives the real [standing] is the same sentence" — **without ever being shown Al-Muizz, the deck that sentence's other half lives in and that this deck's own takeaway presupposes the reader can eventually reach.** The register mitigation I credited in §3 (point 4, the takeaway's reframing) does not depend on the reader having seen Al-Muizz, so Al-Muzill is not unsafe standalone in the acute sense — but its own argument for existing at all (§7 of its draft, "Can Al-Muzill stand alone?") explicitly answers *no*, and the mechanism meant to enforce that answer does not run.

Same finding, same mechanism, for Al-Muqaddim/Al-Muakhkhir — and there the asymmetry is sharper, because Al-Muakhkhir's bar 1 (§2 above) has **no independent Qur'ānic route at all**: its only attestation is the twin's half of one hadith sentence. A reader who draws Al-Muakhkhir alone, without Al-Muqaddim ever shipping, would meet a Name whose entire scriptural grounding sits on a screen they never see.

**I recommend: do not ship any of these four decks until either (a) `chip_keys` is populated with a real pair-key so the existing must-ship-together tests actually evaluate this pair, or (b) an equivalent `requires_deck`-style constraint is added and tested.** This is not a content defect in the decks themselves — it is a release-mechanism gap that makes the decks' own stated pairing requirement unenforceable, and it is a pre-existing, already-documented gap (ledger §9bg, written before this pair existed) that this batch simply inherits and does not fix.

---

## 6 · Synergy-beat rule — verified against the actual test, and what would happen if `chip_keys` were populated

**Confirmed:** none of the four decks declares `position_in_pair: 1` or `2`. Al-Muizz and Al-Muzill each explicitly declare `position_in_pair: 0` (stated verbatim in both drafts' beats-table footers). **Al-Muqaddim and Al-Muakhkhir never declare `position_in_pair` at all** — I grepped both files directly for the string and found zero matches outside the two Muizz/Muzill files. Given the shipped precedent (`al-malik@1`'s asset entry carries `"position_in_pair": 0` as its default), I expect these two would also transcribe to `0` absent an explicit value.

**None of the four decks carries a pair-synergy beat.** I checked every takeaway (`kind: takeaway`) against the test's own detection logic — `label` containing the substring `"synergy"`, or `kind == 'pair_synergy'` — and none matches; none of the four takeaways uses the *"— the second Name of your answer —"* template the chip-paired decks use (confirmed present in the ledger's §3 table for the shipped chip pairs, e.g. `al-baseer@1`, `al-fattah@1`).

**So if `chip_keys` were populated as-is, with position_in_pair left at its current/default value of 0:**

1. **"every rendered chip maps to exactly two decks (positions 1 and 2)" would FAIL.** The test asserts `forChip.map((d) => d['position_in_pair']).toSet() == {1, 2}`. With both decks in each pair at `0`, the actual set is `{0}`, not `{1, 2}` — a hard assertion failure, not a soft warning.
2. **"exactly one pair-synergy beat per pair, carried by position 1" would technically not itself fail**, because neither deck has `position_in_pair == 1`, so both fall into the `else` branch expecting `synergyBeats` to be empty — which is true for both. But this is a vacuous pass, not evidence the mechanism works: it passes only because no deck claims to be "position 1," not because a synergy beat correctly exists where one is required.

**Conclusion: these four decks are not merely unenforced by the pairing mechanism — they are structurally incompatible with it as currently written.** Simply adding a chip key to `chip_keys` would not make them pass; it would introduce a new, immediate CI failure on assertion 1, and the pairing these decks actually rest on (a shared duʿā plus a shared, split scriptural clause) is a different kind of pairing from the "problem chip" mechanism the gate tests — closer in shape to the other four ungated must-pair Names (`ad-darr`/`an-nafi`, `al-qabid`/`al-basit`, `al-khafid`/`ar-rafi`) than to the chip-carrying decks. This confirms and sharpens §5's recommendation: whatever mechanism eventually enforces this needs its own `position_in_pair` convention and its own synergy-or-equivalent beat requirement, not a naive reuse of the chip-pair test as written.

---

## 7 · Reconciliation with `2026-08-04-R2-VERIFICATION.md`

**Where I agree.** R2's source-fidelity claims for this batch all check out against my own independent fetches: Bukhārī 6398 graded Ṣaḥīḥ (collection-level, no separate grade line — confirmed, this is the correct reading of a Bukhārī/Muslim page), Ṣaḥīḥ Muslim 2588 likewise, the `q-d-m` (48/8) and `ʾ-kh-r` (250/6) corpus counts, the `112:1`/`قُلْ` precedent's authenticity, and the 19-decks-missing-`reflection` finding (all four of this batch's decks are on that list, confirmed by direct read of each draft's own stamp). R2 is honest and correctly self-limiting about what it is: source fidelity, not the independent blind review.

**Where I disagree, or go further than R2 does:**

1. **R2's §4 "where a blind verifier should go first" list omits Al-Muzill's bar-5 register risk entirely**, despite the drafter's own file (`al-muzill-DRAFT.md` §4, row 5) explicitly flagging it as *"the hardest bar for this Name."* R2 names `al-majeed@1`'s angelic-speech bar-1 question, `al-muhaymin@1`'s referent question, `as-sabur@1`/`ar-rasheed@1`'s traded bar 4, `al-hakam@1`'s double-sided punishment, and the judgment-four group ruling — but says nothing about the one deck in its own scope whose excerpt itself contains explicit "anger... and humiliation" language for a Name literally called *The Humiliator*. Given that R2 was written by the same author as the draft it is reviewing, and given §3's finding above, I consider this a real gap in R2's own stated coverage, not a disagreement about the underlying facts.
2. **R2 does not run or report the twin-diff word-run measurement at all** for either pair in this batch — it is not in R2's method table (§1 of that file lists Qur'ān fidelity, translation attribution, ḥadīth authenticity, locked-string checks, AI-slot safety, and beat-spine completeness; cross-deck n-gram collision is not among them). My own measurement in §4 catches a real 5-word discrepancy against both drafts' self-reported "zero at n≥4" that R2 had no mechanism to catch, because it wasn't looking.
3. **R2 does not mention the `chip_keys: []` ship-gate gap** for this specific batch at all (it is a pre-existing ledger finding, §9bg/§9bn, that predates R2 and that R2 does not re-surface in its own report). I treat this as a real omission worth restating in a batch-specific verdict, since a reader of R2 alone would not learn that these four decks are currently shippable without their required twin.
4. **On bar 1 for Al-Muqaddim/Al-Muakhkhir**, R2 lists it as reliable ("Ṣaḥīḥ ✅") in its narration-authenticity table (§3, row for Bukhārī 6398) — which is correct as far as it goes (the *hadith* is authentically graded), but that table is about grade-line fidelity, not about whether a nominal naming-clause can carry bar 1 at all. I do not disagree with R2's actual claim, only note that a reader skimming the ✅ could mistake "the hadith is Sahih" for "bar 1 is settled" — they are different claims, and the draft's own file is careful about this distinction where R2's summary table is not.

---

## 8 · What I could not verify — stated as a limit, not softened into a claim

1. **Ṣaḥīḥ Muslim 2589 (Al-Muizz's n+1 successor-sweep neighbour)** — my Wayback fetch at the timestamp the draft cited returned a JS-rendered shell with no hadith text in the static HTML. I did not retry with a different capture year within this review's time budget. The draft's claim (backbiting definition, unrelated topic) is plausible given the book's chapter sequence and given that I did successfully verify n−1 (Muslim 2587), but I have not read n+1 with my own eyes and am not certifying it.
2. **No isnād was audited** for any narration in this batch — I accepted the printed collection-level grade (Bukhārī/Muslim, both self-authenticating by inclusion) as this project's standing convention does, and as R2 also does. I did not independently trace any chain of narrators.
3. **The `dh-l-l` and `ʿ-z-z` root sweeps** (Al-Muizz/Al-Muzill's bar-4 argument) were run by the drafter as a full-mushaf skeleton match, not against `corpus.quran.com`'s own morphological tagging the way I was able to cross-check `q-d-m` and `ʾ-kh-r`. I did not independently re-run the 6,236-āyah skeleton sweep myself — I spot-checked the single load-bearing claim (3:26 is the only Allah-subject, person-humiliating finite verb) against the fetched āyah itself, which confirms the clause exists as claimed, but I have not verified the *exhaustiveness* claim (that no 25th or 29th occurrence exists) independently.
4. **The Muhsin Khan translation of Bukhārī 6398** quoted on Al-Muqaddim/Al-Muakhkhir's story beats is drawn from an OCR'd archive.org scan per the draft's own disclosure; I did not fetch that archive.org text myself to check it character-for-character against the OCR. I did independently confirm the underlying Arabic and its transliteration directly from sunnah.com's own page, which corroborates the *content* of the translation (both epithets, in the same order, coordinated by `وَ`, followed by a third `qadīr` clause) but I have not verified the exact English wording quoted on the beats against a clean digital edition.
5. **I did not run `flutter test` or `flutter analyze`.** Nothing was modified in this review — no asset file, no draft, no test. Purely read-only, per the task's hard constraints.
6. **My bar-5 ruling on Al-Muzill (§3) is a judgment call, explicitly presented as contested rather than settled.** A different reasonable verifier, weighting the literal text of the excerpt more heavily against the third-party-target mitigation, could reach FAIL rather than my CONTESTED-resolved-to-ship-with-flag. I have tried to show my work rather than assert a confident number where none exists.
