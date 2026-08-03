# Deck Draft — Al-Qayyum (hardship pack, Wave G batch 2, 2 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G, §G2b. Author: Claude, 2026-08-03. Batch theme: **hardship — the situation that has not lifted.**

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com`; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching). Scripture is quoted exactly from the fetched pages; story beats paraphrase only what the cited source carries, and every paraphrase is labelled.

**Translation standard:** Saheeh International (`20`) throughout, with Abdel Haleem (`85`) fetched and compared per row and **adopted nowhere** (it says "God" and lower-cases the Names). Khattab (`131`) remains unfetchable.

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on every beat.

---

## Deck `al-qayyum@1` — Al-Qayyum

**Why this deck exists, in one line:** it is the only place in the sources where **Allah answers the specific accusation that He has stopped showing up** — and He answers it in His own words, about a stretch of two or three nights in which nothing was happening.

**Proposed metadata**

```json
{
  "deck_id": "al-qayyum@1",
  "name_id": 16,
  "transliteration": "Al-Qayyum",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You stopped doing the thing you used to do. Something in you decided that meant you had been dropped.

**Beat 2 · name_intro** *(from `collectible_names.json` id 16, verbatim)*:
> الْقَيُّومُ — Al-Qayyum — The Self-Sustaining

**Beats 3–5 · story — "Two or three nights":**
> 1. The Prophet ﷺ became ill, and for two or three nights he did not stand for the night prayer.
> 2. A woman came and said: **"O Muhammad! I think that your Satan has forsaken you, for I have not seen him with you for two or three nights!"**
> 3. What was revealed swore by the daylight and by the night, and then answered her: **"Your Lord has not taken leave of you, [O Muḥammad], nor has He detested [you]."**

**Beat 6 · verse** *(excerpt, marked — the Name appears in the verse itself, in the catalog's own English)*:
> "Allāh - there is no deity except Him, the Ever-Living, the Self-Sustaining. Neither drowsiness overtakes Him nor sleep." — Qur'ān 2:255

**Beat 7 · duʿā** *(catalog id 16, verbatim in full)*:
> يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ
> *Ya Hayyu Ya Qayyum, bi-rahmatika astagheeth, aslih li sha'ni kullahu wa la takilni ila nafsi tarfata 'ayn*
> "O Ever-Living, O Self-Sustaining, in Your mercy I seek help. Rectify all my affairs and do not leave me to myself even for the blink of an eye."

**Beat 8 · takeaway:**
> The gap was in what you were doing, not in what was holding you up. Nothing that keeps you has ever needed a night off.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | 93:3 is Allah's own statement of what He has **not** done: `مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ`. It is not the deck asserting continuity — it is the āyah denying discontinuity, in the first person of revelation, in direct response to a stated accusation. | **yes — beat 5** |
| 2 | **the distinguishing quality is shown, not stated** | Al-Qayyūm's distinguishing quality against `as-samad@1` (the One leaned on) is **non-lapsing** — the holding never pauses. 2:255 states it as the absence of the two things that pause a human: `لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ`. The story supplies the concrete case: two or three nights in which a human stopped, and the divine side did not. | **yes — beats 3, 5 and 6** |
| 3 | **does not collapse into a sibling Name** | **No form of `r-ḥ-m`, `gh-f-r`, `ʿ-f-w` or `ḥ-l-m` appears on any beat.** Nothing is forgiven, pardoned, deferred or healed. The operative words are `وَدَّعَ` (take leave of), `قَلَىٰ` (detest) and `لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ`. **Two disclosures, made rather than hidden:** (a) 2:255's excerpt contains `ٱلْحَىُّ` — **Al-Hayy, catalog id 15** — which is a real Name and is **not** a shipped deck and **not** in this batch; and it is the first word of this deck's own duʿā, so the pairing is the catalog's, not an accident. (b) 2:255's un-quoted tail ends `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ` — Al-Ali (52) and Al-Azeem (50), neither shipped nor in this batch. | **yes** |
| 4 | **the Name's own root appears in the source text** | **Yes — `ٱلْقَيُّومُ` is in 2:255, and Saheeh International renders it "the Self-Sustaining", which is catalog id 16's English word for word.** The Name the user meets on beat 2 is the Name printed on beat 6. This deck does **not** pay the criterion-(2) cost `al-haleem@1` had to. **Disclosed:** the root is *not* in 93:1–3; the story beats teach the attribute, the verse beat names it. | **yes — beat 6** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **Sūrat aḍ-Ḍuḥā contains no punishment anywhere, and `verses/by_key/93:12` returns HTTP 404 — 93:11 is the final āyah**, and it is *"But as for the favor of your Lord, report [it]."* This is the strongest available form of bar 5, the same signal that carried `al-haleem@1`'s 35:45. Full table below. | **yes — verified** |

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **Ṣaḥīḥ al-Bukhārī 4950** | Nothing. It is a free-standing narration in *Kitāb at-Tafsīr*, chapter *"The Statement of Allah the Most High: 'Your Lord has neither forsaken you nor hates you.' (V.93:3)"*, with no narrative continuation and no consequence clause. | **clean, and structurally clean** — there is no "next line" to be dishonest about. |
| **93:1–3** (n+1) | 93:4 *"And the Hereafter is better for you than the first [life]."* → 93:5 *"And your Lord is going to give you, and you will be satisfied."* → 93:6–8 *"Did He not find you an orphan and give [you] refuge? And He found you lost and guided [you]. And He found you poor and made [you] self-sufficient."* → 93:9–11 *"So as for the orphan, do not oppress [him]. And as for the petitioner, do not repel [him]. But as for the favor of your Lord, report [it]."* → **93:12 = HTTP 404.** | **clean, all the way to the end of the sūrah.** Nothing in aḍ-Ḍuḥā turns to warning or punishment. **Disclosed:** 93:7 is `وَوَجَدَكَ ضَآلًّا فَهَدَىٰ` — *"And He found you lost and guided [you]"* — which is `al-hadi@1`'s Name-verb four āyāt after this deck's last story beat. It is not on any screen here, and `al-hadi@1`'s own verse beat is 22:54, so there is no shared citation; recorded because §G2b asks for sibling adjacency to be scanned, not just shared numbers. |
| **93:1** (n−1, looking back across the sūrah boundary) | 92:21, the final āyah of Sūrat al-Layl: *"And he is going to be satisfied."* | **clean** — the preceding text ends on satisfaction, not on threat. |
| **2:255** (n+1) | 2:256 *"There shall be no compulsion in [acceptance of] the religion… And Allāh is Hearing and Knowing."* | **clean.** |
| **2:255** (n−1, looking *backwards*) | 2:254 ends *"And the disbelievers - they are the wrongdoers."* | **disclosed.** A founder who opens `quran.com/2/255` and scrolls up will find that clause one āyah earlier. It contradicts no beat and is not quoted; `al-haleem@1` set the precedent of disclosing the backward direction rather than only the forward one. |
| **2:255** (the excerpt's own tail) | The quotation stops after *"nor sleep."* The remaining two-thirds of the āyah run through His ownership, intercession, knowledge, the Kursī, *"and their preservation tires Him not"*, and close on *"And He is the Most High, the Most Great."* | **clean — nothing withheld is a warning.** The cut is for length and for one breath, not to hide an ending. |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 2.1 | Beat 3: illness, and two or three nights without the night prayer | paraphrase of sunnah.com's published English (*"Once Allah's Messenger ﷺ became sick and could not offer his night prayer (Tahajjud) for two or three nights."*) | [Sahih al-Bukhari 4950](https://sunnah.com/bukhari:4950) | **ṣaḥīḥ** — Ṣaḥīḥ al-Bukhārī (the collection's own condition; sunnah.com prints no separate grade line for the two Ṣaḥīḥs, its standing convention, re-confirmed on this page) | ✅ **verified** via Wayback capture of the exact URL, fetched 2026-08-03. Reference line: *"Sahih al-Bukhari 4950"*, in-book Book 65 Hadith 472. Narrator: **Jundub b. Sufyān**. Isnād on the page: Aḥmad b. Yūnus ← Zuhayr ← al-Aswad b. Qays ← Jundub b. Sufyān. Page Arabic: `اشْتَكَى رَسُولُ اللَّهِ صلى الله عليه وسلم فَلَمْ يَقُمْ لَيْلَتَيْنِ أَوْ ثَلاَثًا`. **Labelled paraphrase** — the beat drops the translator's parenthetical *"(Tahajjud)"* and nothing else. |
| 2.2 | Beat 4 quotation, verbatim: "O Muhammad! I think that your Satan has forsaken you, for I have not seen him with you for two or three nights!" | sunnah.com's published English (Muhsin Khan for the Bukhārī corpus), quoted as printed. **Deliberately NOT re-rendered** — the batch rule is re-render only where the published English resolves a contested reading; this resolves nothing. | [Sahih al-Bukhari 4950](https://sunnah.com/bukhari:4950) | ṣaḥīḥ | ✅ **verified — substring test run programmatically: byte-exact substring** of the archived page English after whitespace normalisation. **One disclosure:** the published English introduces the speaker as *"a lady (the wife of Abu Lahab)"*; **the parenthetical identification is the translator's and is absent from the Arabic** (`فَجَاءَتِ امْرَأَةٌ` — "a woman came"). The beat renders *"A woman came and said:"*, which follows the Arabic and drops a gloss rather than adding one. |
| 2.3 | Beat 5: "swore by the daylight and by the night" | paraphrase of 93:1–2, which are oaths (`وَٱلضُّحَىٰ`, `وَٱلَّيْلِ إِذَا سَجَىٰ`) | [Qur'ān 93:1](https://quran.com/93/1) · [93:2](https://quran.com/93/2) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. **Labelled paraphrase, and deliberate:** quoting 93:1–2 as well would force the beat to join three āyāt across two capitalisations, and 93:2 carries a `<sup>` footnote marker immediately after *"with darkness,"*. Saheeh International 93:1 = *"By the morning brightness"*; 93:2 = *"And [by] the night when it covers with darkness,"* — both fetched and reproduced here so the founder can see exactly what the paraphrase stands for. |
| 2.4 | Beat 5 quotation, verbatim: "Your Lord has not taken leave of you, [O Muḥammad], nor has He detested [you]." | **Saheeh International.** Abdel Haleem (85) fetched and compared: *"your Lord has not forsaken you [Prophet], nor does He hate you,"* — **markedly more readable**, does not say "God" anywhere in this āyah, and replaces two brackets with one. It is rejected **only** for batch consistency with the four sibling decks and the 14 shipped ones. **This is the row where Abdel Haleem is most defensible, and the founder can take it at the cost of one mixed row; the string above is fetched and ready.** | [Qur'ān 93:3](https://quran.com/93/3) | Qur'ān | ✅ **verified** — live fetch `?translations=20,85`, 2026-08-03. **Byte-exact substring**; the fetched string carries **no footnote marker**. The two brackets `[O Muḥammad]` and `[you]` are **the translator's own**, present in the fetched string, retained rather than silently dropped. Arabic: `مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ`. |
| 2.5 | Beat 6, verse anchor, verbatim excerpt: "Allāh - there is no deity except Him, the Ever-Living, the Self-Sustaining. Neither drowsiness overtakes Him nor sleep." | **Saheeh International.** Abdel Haleem: *"God: there is no god but Him, the Ever Living, the Ever Watchful.Neither slumber nor sleep overtakes Him."* — says **"God"**, lower-cases the Names, renders `ٱلْقَيُّومُ` as *"the Ever Watchful"* (which would **delete the Name from the deck's own verse beat**), and the fetched string has a **missing space** after *"Ever Watchful."*. Rejected on all three counts. | [Qur'ān 2:255](https://quran.com/2/255) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. **Byte-exact substring after stripping two `<sup>` footnote markers that fall inside the quoted region** — one immediately after *"the Ever-Living,"* and one immediately after *"the Self-Sustaining."*. Nothing else was removed. Arabic: `ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ`. The excerpt is marked as such on the beat. |
| 2.6 | Beat 8's basis | — | authored | n/a | ✅ **honest label — authored copy.** *"Nothing that keeps you has ever needed a night off"* restates 2:255's `لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ` against the story's *"two or three nights"*. It makes **no promise to the reader** and attributes no stance to the Name. *"The gap was in what you were doing"* reports Bukhārī 4950 (the Prophet ﷺ did not stand; nothing is said about the divine side stopping). |
| 2.7 | Duʿā text | catalog id 16 — **no scripture citation claimed** | catalog only | n/a | ✅ **verified byte-identical to catalog** across `dua_arabic` / `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03. **See the duʿā flag below — this row is deliberately weaker than it looks.** |
| 2.8 | Beat 2 `name_intro` | catalog id 16 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`. |
| 2.9 | **Not on any beat, kept verified:** the parallel narration | sunnah.com's published English | [Sahih al-Bukhari 4983](https://sunnah.com/bukhari:4983) | ṣaḥīḥ | ✅ **verified** via Wayback archive, 2026-08-03. Same companion (**Jundub**), same isnād root (al-Aswad b. Qays), in *Kitāb Faḍāʾil al-Qurʾān* rather than *Tafsīr*: *"Once the Prophet ﷺ fell ill and did not offer the night prayer for a night or two. A woman (the wife of Abu Lahab) came to him and said, 'O Muhammad! I do not see but that your Satan has left you.'"* **Recorded so the founder can see the choice was between two verified renderings of one ḥadīth**: 4950's English is the fuller sentence and is the one quoted. |

### ⚠️ Duʿā flag — disclosed, not fixable by this deck

Catalog id 16's duʿā is **not** cited to any collection by this deck, and it must ship unpinned. Three things the founder should see rather than infer:

1. **It is a composite in the catalogue, and its parts are narrated separately.** `يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ` and `وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ` are each attested in the ḥadīth literature, but **this deck did not find a single canonical narration carrying the whole string as printed**, and the fetch-first rule forbids asserting one on the strength of recognition. **No citation is therefore claimed anywhere in this deck.** If the founder wants it cited, that is a research task on the catalogue, not a deck edit.
2. **The catalogue's own `hadith` field for id 16 cites al-Ḥākim and attributes the words to an exchange with Fāṭima** (*"The Prophet ﷺ said to Fatima: 'Do not leave off a morning or evening without saying: Ya Hayyu Ya Qayyum, bi rahmatika astagheeth.' (Al-Hakim)"*). Al-Ḥākim's *Mustadrak* is **not** one of the tiered collections in §G2, and no grade is given on the card. **Meanwhile the canonical route for that same string is a different narrator entirely:** [Jami' at-Tirmidhi 3524](https://sunnah.com/tirmidhi:3524), **ḥasan (Darussalam)**, narrated by **Anas b. Mālik** — *"Whenever a matter would distress him, the Prophet ﷺ would say: 'O Living, O Self-Sustaining Sustainer! In Your Mercy do I seek relief.'"* (verified via Wayback archive of the exact URL, 2026-08-03; Tirmidhī's own remark on the page is `هَذَا حَدِيثٌ غَرِيبٌ`). **Founder decision, catalogue-level:** id 16's `hadith` field could point at a ḥasan Tirmidhī narration instead of an ungraded al-Ḥākim one. This deck cites neither and does not repeat the attribution.
3. **The duʿā names the Name.** Unlike three of batch 1's five, `يَا قَيُّومُ` is in the user's own mouth on beat 7 and in the verse on beat 6. That is a real strength and it is why the Name survives an uncited duʿā.

### ⚠️ Register risk, faced

**Beat 4 puts the word "Satan" on a reveal screen, at night, in a wellness app.** Three things bear on it, and the founder should weigh them himself:

1. **It is the load-bearing line.** The accusation is what 93:3 answers. Remove it and the āyah becomes a general reassurance rather than a reply, and bar 1 weakens to an assertion.
2. **The taunt is an opponent's, and the beat order defuses it.** Beat 5 lands immediately on the answer; nothing in the deck endorses or elaborates the jibe, and the takeaway never mentions it.
3. **It is a sharper edge than the shipped pack carries**, and if the founder reads beat 4 and feels the deck turn away from the app's register, that is the correct thing to fail this deck on. **There is a fallback that keeps the deck:** cut beat 4 to *"Someone came and told him he had been abandoned"* — a labelled paraphrase that is true to `مَا أُرَى شَيْطَانَكَ إِلاَّ قَدْ تَرَكَكَ` in substance while dropping the word. The cost is that the sharpest sentence in the deck becomes the blandest. **This is a founder call, and it is one line either way.**

### Ship-gate note — **this deck must carry NO duʿā `source`**

As of commit `a12f1db` the `renderedDuaSources` map is asserted **in both directions**: an unpinned deck that carries a `source` on its duʿā beat now **fails** the gate. So the transcription rule is exact: **the duʿā beat's `source` field must be empty, and `al-qayyum@1` must NOT be added to `renderedDuaSources`.** Verified: the full gate passes over `existing ∪ batch 2` with this deck unpinned.

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 19 existing decks

| existing deck | its inventory | collides? |
|---|---|---|
| `as-salam@1` · `al-wakeel@1` · `al-wadud@1` · `al-hadi@1` | 13:28, 9:40, 59:23, Bukhārī 3653, Muslim 591 · 3:172–174, 65:3, Bukhārī 4563 · 11:90, Muslim 2747a, Bukhārī 6309 · 28:22, 28:15/21/23, 22:54, 1:6 | ✖ none — see the 93:7 disclosure above for `al-hadi@1`'s off-screen adjacency |
| `al-ghaffar@1` · `at-tawwab@1` · `al-jabbar@1` · `al-lateef@1` | Bukhārī 7507, 39:53 · Bukhārī 3470, 2:37 · 12:84/86/87/18/94/96 · 12:100/15/20/42, 42:19, 67:13 | ⚠️ **`at-tawwab@1` shares a sūrah and nothing else** — its verse beat is **2:37**, this deck's is **2:255**, 218 āyāt apart, no shared āyah, no shared quotation, different engines (acceptance of return vs. non-lapsing sustenance). Disclosed. |
| `ash-shafi@1` · `ar-razzaq@1` · `al-fattah@1` · `al-baseer@1` | 21:83–84, 26:80, Bukhārī 5743 · 65:2–3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/2731 · 58:1, Bukhārī 3364, Ibn Mājah 188 | ✖ none |
| `ar-rahman@1` | 2:286, 7:156, 55:1, Bukhārī 5999 | ⚠️ **shared sūrah, nothing else.** Its comfort verse is **2:286**; this deck's verse beat is **2:255**. Thirty-one āyāt apart, no shared āyah. Disclosed — and worth noting because `ar-rahman@1`'s 2:286 is the one verse in the pack a user is most likely to have already met. |
| `as-samad@1` | 19:2–7, 112:2 | ✖ none — **and the Names are the pack's closest semantic pair, so the distinction is stated rather than assumed.** As-Ṣamad is *the One everything leans on*; Al-Qayyūm is *the One whose holding does not pause*. That deck's insight is about the legitimacy of leaning; this one's is about the continuity of the support. No shared citation, no shared insight. |
| **batch-1 drafts** | `al-afuw@1` (Ibn Mājah 3850, Tirmidhī 3513, 97:3, 42:25) · `al-ghafur@1` (Bukhārī 2441, Abū Dāwūd 1516, 4:110) · `al-kareem@1` (Bukhārī 1145, Bukhārī 4684, 27:40) · `al-haleem@1` (Bukhārī 7378, 19:90–91, 35:45) · `ar-raheem@1` (18:10/11/18, 33:43) | ✖ **no shared citation.** `al-kareem@1` is set in the last third of the night and this deck is set across two or three nights — **different nights, different sources, and different subjects** (what is offered then, vs. what did not stop while nothing was offered). Disclosed because both decks trade on night. |

**Verified negative, run programmatically:** **93:1, 93:2, 93:3, 2:255, Ṣaḥīḥ al-Bukhārī 4950 and 4983** appear in **no** shipped deck and **no** batch-1 draft.

**Insight-level check.** Beat 8 — *"The gap was in what you were doing, not in what was holding you up. Nothing that keeps you has ever needed a night off."*

| checked against | its insight | verdict |
|---|---|---|
| `ar-raheem@1` (batch 1) | *"…it was being answered the whole time they were unconscious of it, one turn at a time, for three centuries."* | ⚠️ **adjacent and deliberately steered away from.** Both decks could land on *"it was working the whole time"*. `ar-raheem@1` keeps that; this deck's beat 8 instead names **where the discontinuity actually was** — in the human side. Different claim, adjacent feeling. Disclosed. |
| `al-lateef@1` (shipped) | *"Subtle kindness, threaded through every wound — visible only from the far side."* | ✖ none — that is about **retrospect**; this is about **the present tense of the gap**. Recorded because two real insight collisions with `al-lateef@1` were found in batch 1, so this axis is not vacuous. |
| `as-samad@1` (shipped) | *"Leaning is not weakness; it is the meaning of the Name."* | ✖ none |
| `at-tawwab@1`, `al-hadi@1`, `al-ghaffar@1`, `al-wakeel@1`, `al-haleem@1` | mid-road acceptance · needing guidance is not falling behind · forgiving that does not run out · you were never asked to hold every outcome · the distance between what a thing has earned and what is done about it | ✖ none |

### Authoring notes (candidates considered)

- **Selected: Ṣaḥīḥ al-Bukhārī 4950 + Qur'ān 93:1–3, anchored on 2:255.** The properties no other candidate had together: an **accusation of abandonment stated out loud in a ṣaḥīḥ narration**, an **answer in Allah's own words** rather than a companion's, a sūrah with **no punishment in it at all** and a verified 404 at its end, and a verse anchor whose English word for the Name is **identical to the catalogue's**.
- **Rejected — Qur'ān 3:2 and 20:111** (both carry `ٱلْحَىُّ ٱلْقَيُّومُ`). 3:2 is a two-clause opening with nothing demonstrated around it; 20:111 is *"And [all] faces will be humbled before the Ever-Living, the Self-Sustaining"* — a Day-of-Judgement scene, wrong register for this pack and it demonstrates the Name by the posture of creation rather than by an act of Allah.
- **Rejected — Qur'ān 25:58** (`وَتَوَكَّلْ عَلَى ٱلْحَىِّ ٱلَّذِى لَا يَمُوتُ`, *"And rely upon the Ever-Living who does not die"*). Superb line, and rejected on **bar 3**: its imperative is `تَوَكَّلْ`, which is `al-wakeel@1`'s Name-verb, and that deck's whole engine is reliance. Putting it on this deck's screen would hand a shipped deck's Name to Al-Qayyūm.
- **Rejected as the story — the duʿā of distress, [Jami' at-Tirmidhi 3524](https://sunnah.com/tirmidhi:3524), ḥasan (Darussalam), narrated by Anas b. Mālik** — *"Whenever a matter would distress him, the Prophet ﷺ would say: 'O Living, O Self-Sustaining Sustainer! In Your Mercy do I seek relief.'"* (verified via Wayback archive of the exact URL, 2026-08-03; page Arabic `كَانَ النَّبِيُّ صلى الله عليه وسلم إِذَا كَرَبَهُ أَمْرٌ قَالَ يَا حَىُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ`.) On ICP fit this is arguably the single best narration in the pack — *the sentence he reached for when something was pressing on him*. It is held back for one reason: it is the natural companion to catalog id **15** (Al-Hayy), whose `dua_arabic` **is exactly that shorter string**, and id 15's and id 16's duʿā beats already open with the same four words. Shipping both in one batch would put a near-duplicate on the pack's most memorable screen. **Recommendation: Al-Hayy is a strong batch-3 candidate on the strength of this narration, and this deck deliberately leaves it free.**
- **Rejected — Al-Muhaymin (catalog id 18) as an alternative Name for this material.** Its duʿā is *"guard me with Your eye that never sleeps"*, which is 2:255's clause in the user's mouth — a direct collision with this deck's verse beat. One of the two Names can have 2:255; this deck takes it, and that is a cost recorded rather than hidden.
- **Register check:** no beat attributes waiting, wanting or withholding to the Name. Beat 8 defines the attribute in the catalogue's own terms (`meaning`: *"The One who sustains all of creation by His power"*) and the catalogue's `lesson` line (*"Al-Qayyum holds you together even when you feel like falling apart"*) was deliberately **not** used as the takeaway, because it is a Name-action promise about the reader.
