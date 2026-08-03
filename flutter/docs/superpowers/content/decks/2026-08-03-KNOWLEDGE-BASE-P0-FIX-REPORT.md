# knowledge_base.dart — P0 fix report: removal of fabricated quoted speech

**Fixes against:** `docs/superpowers/content/decks/2026-08-03-KNOWLEDGE-BASE-P0-SWEEP.md` (committed at `8912794`).
**Files repaired:** 2 — see §4. **Not committed. No database touched.**

**Standard applied:** deletion of the quotation is the default; replacement only where a source was fetched in this session and quoted verbatim. Nothing was composed, reconstructed, or paraphrased into quotation marks. No teaching content was re-authored — every edit is confined to the quoted span and the clause that frames it.

**Totals: 19 repair sites — 9 deleted, 10 replaced with fetched verbatim text, 1 verified-unchanged.**

---

## 1. Tier 1 — the five with the primary narration located and the disputed words absent

| # | Entry | What it said | What it says now | Fetched | Verdict |
|---|---|---|---|---|---|
| 1 | `Al-Shakur` | `A man moved a thorn branch from a path. Allah said: 'You did that for me.' Sins forgiven.` | `A man walking along a path found a thorny twig lying on the way and put it aside; the Prophet ﷺ said Allah appreciated it and forgave him (Sahih Muslim 1914).` | **Sahih Muslim 1914** via Wayback `20230131025445` — *"While a man walks along a path, finds a thorny twig lying on the way and puts it aside, Allah would appreciate it and forgive him."* **No divine speech in the narration.** | **DELETED** |
| 2 | `Al-Shakur` | `A man who had lived a life of sin gave water to a thirsty dog. Allah said: 'You did that for my creation.' Jannah.` | `A man dying of thirst climbed down a well to drink, came out and found a dog eating the earth from thirst, went back down and filled his shoe with water for it; Allah thanked him for it and forgave him (Sahih al-Bukhari 2466).` | **Sahih al-Bukhari 2466** via Wayback `20221005153219` — Arabic retrieved: *فَشَكَرَ اللَّهُ لَهُ، فَغَفَرَ لَهُ*. **No divine speech.** Note the file also had the actor wrong: Bukhari 2466 is a thirsty man, not "a man who had lived a life of sin" (that is the separate prostitute narration). Corrected to match the narration cited. | **DELETED** |
| 3 | `Al-Karim` | `The Prophet felt completely unworthy: 'Who am I? I can't read. I'm nobody.'` | `The Prophet ﷺ answered the angel three times, 'I do not know how to read' (Sahih al-Bukhari 3) — and the revelation came anyway.` | **Sahih al-Bukhari 3** via Wayback `20220421152907`. English: *"I do not know how to read."* Arabic: *مَا أَنَا بِقَارِئٍ*, three times. Nothing resembling the disputed words. | **REPLACED** |
| 4 | `Al-Ghaffar / Al-Ghafoor / At-Tawwab` | `The Prophet ﷺ said: "…seek His forgiveness — because sometimes a sin that brings you closer to Allah is better than a good deed that fills you with arrogance."` | `The Prophet ﷺ said: "…seek His forgiveness." (Sahih Muslim 2749) Ibn Ata'illah drew the lesson out: a sin that leaves you humbled and in need of Allah is better for you than an act of obedience that fills you with pride.` | **Sahih Muslim 2749** via Wayback `20220703154620` — the narration **ends** at *"and He would have pardoned them."* The trailing clause is the ʿAṭāʾī ḥikma *رب معصية أورثت ذلاً وانكساراً خير من طاعة أورثت عزاً واستكباراً*, attributed to **Ibn ʿAṭāʾillāh al-Sakandarī** by Dar al-Iftaa al-Misriyyah (fatwa 18008). | **REPLACED** — prophetic quote closed at the narration's end; aphorism moved outside the quotation marks and named. |
| 5 | `As-Samīʿ` | (already repaired before this pass) | unchanged | **VERIFIED, not redone.** Byte-compared the in-file Q19:7 string against a live `api.quran.com` fetch (`translations=20`) — **exact match**, including the `[He was told]` and `[this]` translator brackets. | **VERIFIED** |

> **On finding #4 I differ from the sweep.** The sweep attributed the trailing clause to **Ibn al-Qayyim**. The canonical wording is Ḥikma of **Ibn ʿAṭāʾillāh** (al-Ḥikam), which is also how **this same file already attributes the identical sentiment at ~L1362 and ~L934**. I followed the file's own precedent and the Dar al-Iftaa attribution rather than the sweep's. Flagging the disagreement explicitly rather than silently picking one.

---

## 2. Tier 2 — the remaining unlocatable quotations

| # | Entry | What it said | What it says now | Basis | Verdict |
|---|---|---|---|---|---|
| 6 | `Al-Karim` | `…because you realize He's already said: 'I've got you.'` | `…because you already know who has undertaken to provide for you.` | No source exists or was ever claimed. | **DELETED** |
| 7 | `Al-Shakur` | `Allah says to the angels: 'Bear witness that I have forgiven everyone in this gathering for every sin they ever committed in their entire life.' An angel says: 'But Ya Allah, one man wasn't even here intentionally — he just passed by.' Allah says: 'Him too.'` | The three quotations now read verbatim: `'So I do call You to witness that I have forgiven them.'` / `'Indeed among them is so-and-so, a sinner, he did not intend them, he only came to them for some need.'` / `'They are the people, that none who sits with them shall be miserable.'` (Jami' at-Tirmidhi 3600, Sahih) | **Jami' at-Tirmidhi 3600** via Wayback `20260414065420`, graded **Sahih (Darussalam)**, full text read. | **REPLACED.** Note: the sweep flagged only the *"for every sin…"* embellishment. Reading the narration showed **all three** quotations in the sequence were wrong, including a fabricated `'Him too.'` the sweep did not list. |
| 8 | `Al-Wadud` | `Dawood (AS) asked Allah: 'What do you love most?' Allah said: 'That you cause other people to love Me — remind them of My blessings upon them.'` | *(sentence removed entirely)* | Not located by the sweep across 9 editions or by targeted retrieval; surfaces only in later devotional compilations. I added nothing. | **DELETED** |
| 9 | `Al-Qarib / Al-Mujib` | `They brought his dua before Allah. Allah said: 'Answer him. Of course I will.'` | `They brought his dua before Allah, and he was answered.` | The al-Bazzār/Ibn Jarīr Yūnus narration quotes **no divine reply**. | **DELETED** |
| 10 | `Al-Wahhab` | `Zakariah asked: 'How?' Allah's answer: 'I said so.'` | `Zakariah asked how. Quran 19:9 — the angel said: "Thus [it will be]; your Lord says, 'It is easy for Me, for I created you before, while you were nothing.'"` | **Q19:9** fetched verbatim from `api.quran.com`. `'I said so'` appears nowhere in it. | **REPLACED** |
| 11 | `Al-Mani` | `He returned and told the Prophet ﷺ, who said: "Stay."` | `He returned and told the Prophet ﷺ, who kept him back from the journey.` | Not located in any collection; the file gives no citation for the story. | **DELETED** |
| 12 | `An-Nasir` | `His tribe? Aslam — meaning 'peace.' The Prophet looked at Abu Bakr and smiled: 'We're safe.'` | `His tribe? Aslam — from the root meaning peace and safety. The Prophet looked at Abu Bakr and smiled at the omen in the name.` | Sīrah-only wordplay (Ibn Hishām / Bayhaqī's *Dalāʾil*); not in the six books. | **DELETED** |
| 13 | `Al-Azeez` | `asked, "What do you think I will do to you?" They said, "A noble brother and the son of a noble brother." He replied, "Go, for you are free."` | `…stood in Mecca as the Prophet ﷺ entered at its conquest, and he let them go free rather than take retribution.` | Standard sīrah (Ibn Hishām; Bayhaqī), not in a canonical collection, presented in the file with no source. | **DELETED** |

---

## 3. Tier 3 & 4 — mismatched scripture, and the ḍaʿīf quotation

| # | Entry | What it said | What it says now | Fetched |
|---|---|---|---|---|
| 14 | `Al-Fattah` | `The Quran says: 'If you believe in Him and are aware of Him, Allah will open up baraka in your life.'` | `Quran 7:96 ties the opening of baraka to belief and taqwa: 'And if only the people of the cities had believed and feared Allah, We would have opened [i.e., bestowed] upon them blessings from the heaven and the earth.'` | **Q7:96**, `api.quran.com`. The counterfactual about past nations is restored; the invented present-tense promise to the reader is gone. **REPLACED** |
| 15 | `Al-Qahhar / Al-Jabbar` | `Allah mocks the schemers: "They plot, and Allah plots, and His plot always prevails."` | `And Quran 8:30, on the schemers: "But they plan, and Allah plans. And Allah is the best of planners."` | **Q8:30**, `api.quran.com`. **REPLACED** |
| 16 | `Al-Qahhar / Al-Jabbar` | `"Never think Allah is unaware of what the wrongdoers do — He only delays them to a day when their eyes will stare in horror."` | `Quran 14:42: "And never think that Allah is unaware of what the wrongdoers do. He only delays them [i.e., their account] for a Day when eyes will stare [in horror]."` | **Q14:42**, `api.quran.com`. The sweep listed this as *located* in §3; fetching it showed the in-file wording had **drifted** from the translation. **REPLACED** — beyond the sweep's deliverable. |
| 17 | `Al-Karim` | `Allah introduced Himself … as 'Al-Karim' — 'Iqra' wa rabbuka al-Akram.'` | `…with this very quality — 'Iqra' wa rabbuka al-Akram,' Quran 96:3: 'Recite, and your Lord is the most Generous' (al-Akram, the superlative of Karim).` | **Q96:1–3**, `api.quran.com`. The verse says **al-Akram**. **REPLACED** |
| 18 | `Al-Qawi / Al-Matin` | `'Shall I not teach you a word that is a treasure from beneath the throne?'` | `'Shall I tell you a sentence which is one of the treasures of Paradise?' (Sahih al-Bukhari 4205)` | **Sahih al-Bukhari 4205** via Wayback `20230129081020` (English) and **6384** via `20220630123817` (Arabic: *كَنْزٌ مِنْ كُنُوزِ الْجَنَّةِ*). "Beneath the throne" is not in the narration. **REPLACED** |
| 19 | `Al-Karim / Al-Wahhab` (Tier 4) | `The Prophet ﷺ said: 'Indeed Allah is Jawad and He loves generosity.'` | *(quotation removed; the adjacent ṣaḥīḥ birds-of-tawakkul hadith is retained)* | **Jami' at-Tirmidhi 2799** via Wayback `20241007201939` — graded **Da'if (Darussalam)**, and the main chain is **mawqūf to Saʿīd b. al-Musayyab**, not marfūʿ. Removed rather than caveated, since the AI prompt strips context. **DELETED** |

### One repair beyond the sweep's list, same failure class

| Entry | What it said | What it says now | Fetched |
|---|---|---|---|
| `Al-Fattah` | `And He says: 'I am shy — shy to let your raised hands come back empty.'` — **Allah speaking in the first person** | `And the Prophet ﷺ said: 'Indeed, Allah is Hayy, Generous, when a man raises his hands to Him, He feels too shy to return them to him empty and rejected' (Jami' at-Tirmidhi 3556).` | **Jami' at-Tirmidhi 3556** via Wayback `20221129044200`. The sweep filed this under "located" with a note that the file renders the Prophet's *description of* Allah as Allah's own speech. That is the same failure class as the rest of this pass — invented first-person divine speech — so I fixed it. Abū ʿĪsā grades it *ḥasan gharīb*; some narrate it mawqūf. **REPLACED** |

---

## 4. Mirroring — the catalogue does live in more than one place, and a previous fix was partial

Seven files matched a catalogue phrase. I checked each for the 17 fabricated spans:

| File | Carries the fabrications? | Action |
|---|---|---|
| `flutter/lib/core/constants/knowledge_base.dart` | **yes — all 19 sites** | repaired |
| `lib/knowledgeBase.ts` (repo root, legacy Expo app) | **yes — 17 of 19** (it has 49 entries, not 100; Al-Mani and Al-Azeez are absent) | repaired identically, 14 replacements applied and asserted unique |
| `constants/quiz.ts` | no | untouched |
| `flutter/lib/core/constants/discovery_quiz.dart` | no | untouched |
| `flutter/assets/content/name_anchors.json` | no | untouched |
| `flutter/supabase/migrations/20260512110000_seed_name_anchors_to_98.sql` | no | untouched |
| `flutter/build/unit_test_assets/…/name_anchors.json` | no (build artifact) | untouched |

The last five carry only short per-Name blurbs, not the long teaching prose.

### ⚠️ The mirror matters, and it was already missed once

`lib/knowledgeBase.ts` is **not dead code within its own app** — `lib/claude.ts:2` imports `getRelevantTeachings` from it and injects the result into the model prompt at `lib/claude.ts:324–329`, exactly as `ai_service.dart` does. The whole root-level Expo app is frozen (last commit touching it is `9981e8b`, the initial import), so this is very likely dormant in production — **but it should be confirmed or deleted, not assumed.**

Concretely: **the As-Samīʿ fabrication (`'I heard you — and here is the child you were asking for, already named Yahya.'`) was still present in `lib/knowledgeBase.ts`** when I started, even though it is the worked precedent the Dart file was fixed against. The earlier repair updated one copy of two. I have now fixed it in both.

---

## 5. Method, and where it stops

**Extraction.** I re-ran the sweep's census with two independent extractors and reconciled, per the warning that a clean first pass means nothing:

- **Method A** (naive paired delimiters, ASCII + curly, single + double): **684** spans before, **668** after.
- **Method B** (apostrophe-safe: single quotes only honoured at a non-word boundary on open and a non-letter on close): **539** before, **526** after.

The two disagree by ~145 spans by construction — A over-segments on internal apostrophes (`can't`, `I'm`), B under-segments on non-greedy pairing. I filtered the **union**, not either alone. Attribution-filtered candidates: **193 before → 177 after**.

**The attribution filter has a known blind spot and I am not claiming it is complete.** `"Go, for you are free."` (Al-Azeez) did *not* surface in my own filtered list — its 120-character lead-in is `He replied,`, which my attribution regex does not model. I only repaired it because the sweep had already named it. A quotation attributed by a verb my regex does not enumerate, in an entry the sweep did not flag, would still be invisible. This is the same class of failure as the sweep's apostrophe bug, one level up: the bug moved from the extractor into the classifier.

**Sourcing limits — stated plainly, because every pass in this project has had them:**

1. **I reached no corpus independent of sunnah.com.** Every ḥadīth verdict here rests on Wayback captures of sunnah.com pages (CDX API; `/wayback/available` was not used). Qurʾān came from `api.quran.com` (Saheeh International, `translations=20`). No manuscript, no printed critical edition, no second translation tradition.
2. **I audited no isnād. Not one.** Where a grade appears above it is Darussalam's, copied off the page, not evaluated. I did not open a single chain.
3. **I fetched each cited number bare and exact** (`bukhari:3`, `muslim:2749`, `muslim:1914`, `bukhari:2466`, `bukhari:4205`, `bukhari:6384`, `tirmidhi:3600`, `tirmidhi:3556`, `tirmidhi:2799`). No `a`/`b` suffixed page was substituted for a bare number.
4. **"Not located" here is a bounded negative**, inherited from the sweep — it means "not in what was searched", not "does not exist". For the Tier-1 five I am on firmer ground: the primary narration itself was retrieved and read, and the disputed words are demonstrably absent from it.
5. **Two entries lost a quotation but kept an uncited story** (Al-Mani's dream/caravan, Al-Azeez's conquest). Removing the invented speech does not make the surrounding narrative sourced. Flagged below.

---

## 6. Unresolved — deliberately not chased, per instructions

These were noted, not touched. They share one root cause: **this is transcript-derived prose in which speaker attribution collapsed.** The teaching content was distilled from lecture transcripts (`knowledge/ep*.txt`) in which the lecturer moves between reciting a hadith, paraphrasing it, quoting a scholar, and speaking in his own voice — all in the same spoken register. Flattened into a single prose string, those four registers become indistinguishable, and every one of them ends up inside `'…'`. That is why the fabrications cluster in the narrative-heavy first half of the file, and why fixing the quotations one at a time does not fix the generator.

The AI prompt makes this materially worse: `_buildTeachingContext` (`ai_service.dart` ~L730) injects `coreTeaching` and `propheticStory` as raw prose with no per-span provenance, so the model sees `The Prophet ﷺ said: '…'` and `Sheikh Mikaeel reflects: '…'` as the same kind of token.

Specifically deferred:

- **Unquoted-but-attributed prophetic speech.** `Al-Shakur` ~L1362: `The Prophet ﷺ said: our two-rakat prayer — half-distracted … is still seen, still valued, still lifted up by Al-Shakur.` No quotation marks, so it fell outside both the sweep's filter and mine — but it is still an unsourced claim attributed to the Prophet ﷺ. **There is no reason to think this is the only one; nothing has ever scanned for this shape.**
- **Uncited scholar sayings in quotation marks** — a large consistent pattern (Ibn al-Qayyim, Ibn Taymiyyah, Ibn al-Jawzī, al-Ghazālī, al-Nābulusī, Imam Aḥmad).
- **Iblīs's direct speech** attributed to "the narration" with no collection (~L934).
- **The Ṭāʾif duʿā** (~L971), real and famous, chain widely graded weak, presented with no source.
- **Sheikh Mikaeel's first-person testimony** (~L936, L1330, L1364, L1621) in the same quoted register as the hadith beside it — the prompt-injection-shaped risk above.
- **Two now-unquoted but still uncited stories**: Al-Mani's dream/caravan, Al-Azeez's conquest of Mecca.
- **~110 un-refetched inline `Quran x:y` citations in entries 48–99** — the sweep's own stated gap. Finding #16 above (Q14:42 drift) was found by fetching one verse the sweep had marked "located". That is direct evidence this gap is not empty.

---

## 7. Verification

- **`flutter analyze` (full):** `40 issues found`, **0 errors**. 7 of the 40 are in `knowledge_base.dart`, all `prefer_single_quotes` infos on lines I did not touch (2178, 2270, 2293, 2500, 2594, 2732, 2847). No new issue was introduced.
- **`flutter test` (full suite):** `All tests passed!` — **+3471 passed, 0 failed, ~4 skipped**, exit code 0.
- `lib/knowledgeBase.ts` — every string literal on all 13 changed lines tokenizes cleanly (no unbalanced quote characters outside a literal). **No TypeScript compiler is installed in this repo, so this is a lexical check, not a type-check.**
- All 17 fabricated spans grep to **0 occurrences** in both repaired files.
- **Quoted-span census reconciled two ways:** Method A 684→668 spans, Method B 539→526; attributed divine/prophetic candidates **193→177**.
- `git status` is clean of stray artifacts — no `companion_*.png` regeneration, no build output.

### Working-tree note (not mine)

`flutter/lib/features/daily/providers/daily_loop_provider.dart` shows as modified in `git status`. **That is another agent's in-flight work in this shared worktree — I did not touch it and did not revert it.** It was already modified when I started and the full suite passes with it in place. Flagging it so it is not mistaken for part of this change; the content fix touches only the two catalogue files plus this report.

**Nothing was committed. No database was touched.**
