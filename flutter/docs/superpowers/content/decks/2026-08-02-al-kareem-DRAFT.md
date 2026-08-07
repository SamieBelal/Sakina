# Deck Draft — Al-Kareem (mercy/forgiveness pack, Wave G pilot 5 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

**Revision 2 — 2026-08-02.** The narration selection is **unchanged and stands** (founder ruling A3: *keep the narration, fix the translation*). Revision 1 pasted the published USC-MSA/Khan English of Bukhārī 1145 verbatim — which was quoted correctly, but that English does two things the Arabic does not: it interpolates **"to us"** (absent from `إِلَى السَّمَاءِ الدُّنْيَا`) and renders **`تَعَالَى` as "the Superior"** instead of "the Exalted". Together those flatten the one word in the sentence that negates spatiality while amplifying the spatial reading. **A deck must not adjudicate a contested attribute by choice of translation.** Beats 4–5 are now rendered from the cited Arabic; nothing else in the deck changed.

**Revision 3 — 2026-08-02. No beat changed. Three claims in the box the founder signs were overstated or wrong, and are now restated to match the checks that were actually run:**
1. **"the Arabic word order is preserved" was untrue** and is replaced. `يَنْزِلُ رَبُّنَا` is verb-subject; the rendering is "Our Lord … descends". **Clause order** is preserved; word order is not, and cannot be, between Arabic and English.
2. **"Nothing is added" was too strong** and is replaced. `تَبَارَكَ` / `تَعَالَى` are finite verbs rendered adjectivally with an added copula ("is He"), and `يَقُولُ` ("He says") is subordinated to "saying:". Neither adds *content*; both are more than nothing.
3. **Row 5.2's "the Arabic was read off the archived page character-for-character" was the batch's clearest overstated ✅** — the identical overstatement `al-afuw@1` was corrected for in the same revision, left standing here. The raw byte comparison is **False**. The row now uses `al-afuw@1`'s corrected wording and names the check that passes.

Plus the batch-wide **126-translation correction** (below), which was re-run against 27:40 and changed nothing but is now recorded with the alternative named; the unflagged catalog contradiction on 96:3; and the collision-table baseline.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G. Author: Claude, 2026-08-02.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com` against the canonical `quran.com/{surah}/{ayah}` reference; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching).

**Translation standard for this deck (founder ruling A1 — most appropriate per Name, never at the cost of authenticity; Abdel Haleem is the named second option where Saheeh International reads stiffly):**
- **Qur'ān (27:40): Saheeh International** (`resource_id: 20`), quoted verbatim with one disclosed typographic normalisation. **Abdel Haleem (`resource_id: 85`) was fetched and compared for this row and is not used** — see the correction box below, which also says exactly what that comparison would have bought and what it would have cost.
- **Ḥadīth (Bukhārī 1145): the app's own rendering, made from the Arabic on the cited page.** This is the exception, and the reason is set out in full in the box below. Authenticity beat readability *and* convenience here: the published English was easier and was already verified as quoted correctly, and it is still the wrong string to put on the screen.

### ⚠️ The 126-translation correction (batch-wide, BLOCKING before sign-off)

Revisions 1–2 of all five decks said: *"the API's English resource list returns **eight** translations and Khattab is not among them."*

**That is false.** `GET /api/v4/resources/translations?language=en` returns **126** entries (re-fetched and counted programmatically, 2026-08-02).

What is true, and what the conclusion actually rested on: **Khattab (`resource_id: 131`) is genuinely absent from that list**, and `/quran/translations/131?verse_key=…` genuinely returns `{"translations":[]}` while `…/20` returns text. Both reproduced 2026-08-02. So Khattab still cannot be quoted and the fetch-first rule still forbids quoting it from memory — but the reason given was wrong, and it foreclosed live options, chiefly **M.A.S. Abdel Haleem (`resource_id: 85`)**.

**What re-running the choice against the real list changed for 27:40 — and this is the one row in the batch where it was a genuine near-miss.** This deck had to normalise Saheeh International's spaced hyphens to em dashes. **Abdel Haleem carries no spaced hyphens, so that normalisation would simply disappear.** Fetched, 2026-08-02:

> *"…if anyone is grateful, it is for his own good, if anyone is ungrateful, then my Lord is self-sufficient and most generous."*

**It is not used, for a reason specific to this deck:** Saheeh International reads *"my Lord is **Free of need and Generous**"* — capitalised, so `غَنِيٌّ كَرِيمٌ` lands on screen as **the Name**. Abdel Haleem lower-cases it to "most generous", which is precisely the thing this verse beat exists to put on the page (this deck's story carries no `k-r-m` at all; 27:40 is the only place the Name appears in a source text). Trading the Name away to remove one hyphen substitution is the wrong trade. **The founder can make the opposite call in one line** — the string is above and verified.

The batch-wide reason the same answer came back on every row of all five decks: **Abdel Haleem renders the divine name as "God", not "Allāh", and lower-cases the Names** where Saheeh International capitalises them. Against 14 shipped decks that all say "Allah", adopting it would break the app's core vocabulary mid-pack. So it is **compared and named per row, adopted nowhere.**

**The discontinuity that remains, stated plainly:** the 14 shipped decks lean **Khattab** in register — `al-wakeel@1` (`˹alone˺`), `at-tawwab@1` (`˹of prayer˺`), `as-samad@1` (`˹needed by all˺`), and `ash-shafi@1`'s sources array literally pins *"Khattab rendering"*. These five ship in Saheeh International. `ar-rahman@1`'s founder-decided Saheeh International comfort verse is the precedent that mixing is permitted, so this is defensible — but it is a real register mix and the founder is signing it, now on a true premise rather than a false one.

**Implementation note (binding):** every beat stores Arabic / transliteration / translation as **separate fields**. The em-dash formatting below is markdown shorthand only, never a single mixed-direction `Text`.

---

## Deck `al-kareem@1` — Al-Kareem

**Proposed metadata**

```json
{
  "deck_id": "al-kareem@1",
  "name_id": 30,
  "transliteration": "Al-Kareem",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> It is late, and asking again feels like too much to ask. This is the Name for the hour you are in.

**Beat 2 · name_intro** *(from `collectible_names.json` id 30, verbatim)*:
> الْكَرِيمُ — Al-Kareem — The Most Generous

**Beats 3–5 · story — the last third of the night:**
> 1. Abū Hurayra narrated what the Prophet ﷺ said happens in the last third of every night.
> 2. **"Our Lord — Blessed and Exalted is He — descends every night to the lowest heaven, when the last third of the night remains, saying: Who calls upon Me, that I may answer him?"**
> 3. **"Who asks Me, that I may give him? Who seeks My forgiveness, that I may forgive him?"** Three questions, and every one of them is an offer.

**Beat 6 · verse** *(excerpt, marked as such — the Name appears in the verse itself)*:
> "…And whoever is grateful — his gratitude is only for [the benefit of] himself. And whoever is ungrateful — then indeed, my Lord is Free of need and Generous." — Qur'ān 27:40

**Beat 7 · duʿā** *(catalog id 30, verbatim in full)*:
> يَا كَرِيمُ بِرَحْمَتِكَ أَغِثْنِي
> *Ya Karimu birahmatika aghithni*
> "O Most Generous, by Your mercy, rescue me."

**Beat 8 · takeaway:**
> You are not drawing on a supply that runs down. The One being asked is Free of need — the asking costs Him nothing at all.

### ⚠️ The quoted narration is the app's own rendering, from the cited Arabic. Here is exactly why.

**The Arabic on the archived page** (`https://sunnah.com/bukhari:1145`, Wayback capture `20260422043007`, read off the page's `arabic_text_details` block, 2026-08-02):

> يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ يَقُولُ مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ مَنْ يَسْأَلُنِي فَأُعْطِيَهُ مَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ

**The published English on the same page**, which revision 1 pasted: *"Our Lord, the Blessed, the Superior, comes every night down on the nearest Heaven to us when the last third of the night remains, saying: Is there anyone to invoke Me, so that I may respond to invocation? Is there anyone to ask Me, so that I may grant him his request? Is there anyone seeking My forgiveness, so that I may forgive him?"*

**Two defects in that string, both concrete:**

1. **"to us" is not in the Arabic.** `إِلَى السَّمَاءِ الدُّنْيَا` is "to the lowest heaven" — a location in creation. "the nearest Heaven **to us**" adds an indexical that turns it into a statement of motion *toward the reader*. That is precisely the modality (`kayfiyya`) the schools divide over, and the beat would assert it inside quotation marks as the Prophet's ﷺ words.
2. **"the Superior" mistranslates `تَعَالَى`.** The standard rendering is "the Exalted" / "Most High". In Ashʿarī and Māturīdī theology `taʿālā` is exactly the clause that negates place and direction. Rendering it "the Superior" flattens the one word guarding against the anthropomorphic reading, while "comes down… to us" amplifies that reading.

**The net effect is that the published English leans toward one classical position — which is the opposite of this deck's design intent.** Atharī/Ḥanbalī theology affirms the descent without asking how (`bilā kayf`); Ashʿarī and Māturīdī theology — the creedal schools of most Shāfiʿīs, Mālikīs and Ḥanafīs — either consign the meaning (`tafwīḍ`) or interpret it (`taʾwīl`). A reveal deck should not pick between them, and it must not pick by accident through a translator's word choice.

**The rendering used, clause by clause,** so the founder can check it against the Arabic above without knowing Arabic:

| Arabic | rendered as | note |
|---|---|---|
| `يَنْزِلُ رَبُّنَا` | "Our Lord … descends" | `nazala` = to descend; the verb is left as the text has it, un-glossed |
| `تَبَارَكَ وَتَعَالَى` | "— Blessed and Exalted is He —" | **`تَعَالَى` restored to "Exalted"**, as the founder ruled |
| `كُلَّ لَيْلَةٍ` | "every night" | |
| `إِلَى السَّمَاءِ الدُّنْيَا` | "to the lowest heaven" | **"to us" removed** — it is not in the Arabic |
| `حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الآخِرُ` | "when the last third of the night remains" | |
| `يَقُولُ` | "saying:" | |
| `مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ` | "Who calls upon Me, that I may answer him?" | |
| `مَنْ يَسْأَلُنِي فَأُعْطِيَهُ` | "Who asks Me, that I may give him?" | |
| `مَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ` | "Who seeks My forgiveness, that I may forgive him?" | |

**What is and is not claimed for this rendering — restated in revision 3, because two of the three claims here were overstated:**

- ✅ **No content is added and none is dropped.** Every Arabic clause above has exactly one English clause and no English clause lacks an Arabic one. *(This is the claim; it holds.)*
- ✅ **No commentary is attached and no classical position is named on screen.** *(Holds.)*
- ✅ **Clause order is preserved** — the nine clauses appear in the order the Arabic has them.
- ⚠️ **"the Arabic word order is preserved" — WITHDRAWN. That was untrue.** `يَنْزِلُ رَبُّنَا` is verb-subject; the rendering is "Our Lord … descends", subject-verb. Arabic VSO cannot survive into English SVO and no English rendering of this sentence preserves word order. Clause order does; word order does not.
- ⚠️ **"Nothing is added" — WITHDRAWN as phrased.** Two grammatical additions exist and neither adds meaning: `تَبَارَكَ` and `تَعَالَى` are finite verbs (*"He is blessed", "He is exalted"*) rendered adjectivally with an added copula — "Blessed and Exalted **is He**"; and `يَقُولُ` ("He says") is subordinated to the participial "saying:". Both are moves the published English makes too. They are more than nothing and are now named.

It reads better than "the Blessed, the Superior" as a side effect, not as the goal — the goal was to stop the translation from adjudicating. It is also shorter, which matters at reveal-beat speed.

**Precedent this sets, for the founder to accept or reject deliberately:** to date every ḥadīth quotation in the shipped decks is the sunnah.com published English. This is the first app-authored rendering. It is confined to a passage on a contested attribute; the rule I would propose is exactly that — *paste the published English by default; re-render from the Arabic only where the published English resolves a contested reading, and show the clause table when you do.* **That rule is being honoured elsewhere in the batch, not just proposed:** `al-haleem@1` revision 3 quotes Bukhārī 7378's published English as printed — including a stray space before its final period — because that English resolves nothing, and `al-ghafur@1` leaves *"shelter him with His Screen"* as published for the same reason. If instead the founder would rather the pack not touch the attribute at all, the substitute is still available (see the notes below) — but note it substitutes one divine-attribute text for another.

**⚠️ On-screen attribution — this needs a founder decision and currently has neither answer (round 2, K3).** The `source` field will render **"Sahih al-Bukhari 1145"**. Anyone who opens that URL finds materially different English under the same reference — which is the whole point of the box above, and is also a founder-checklist item (*"open each URL — does the quoted text actually appear there?"*) that will read as a failure. Two options, and one of them must be chosen before sign-off:
- **(a)** put the signal on screen: `source: "rendered from the Arabic of Sahih al-Bukhari 1145"`; or
- **(b)** record an explicit founder decision that no on-screen signal is shown, and that the disclosure lives only in this document.

**Recommended: (a).** It costs six words on one beat and it makes the rendered citation self-describing. Note that the same problem exists in `al-ghafur@1` from the opposite direction — there the deck quotes the page's Arabic faithfully while the page's *English* diverges — so whichever convention is chosen should be chosen for the batch, not for this deck.

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 5.1 | Beat 3: the narration is Abū Hurayra's, and is about the last third of the night | — | [Sahih al-Bukhari 1145](https://sunnah.com/bukhari:1145) | **ṣaḥīḥ** — Ṣaḥīḥ al-Bukhārī (the collection's own condition; sunnah.com prints no separate grade line for the two Ṣaḥīḥs, which is the site's convention) | ✅ **verified** via Wayback capture `20260422043007` of the exact URL, fetched 2026-08-02. Reference line on the page: *"Sahih al-Bukhari 1145"*. Isnād on the page: ʿAbdullāh b. Maslama ← Mālik ← Ibn Shihāb ← Abū Salama **and** Abū ʿAbdillāh al-Aghharr ← **Abū Hurayra** (raḍiyallāhu ʿanhu). |
| 5.2 | Beats 4–5, the quotation itself | **the app's own rendering, made from the Arabic on the cited page** — not a published translation. Full clause-by-clause justification in the box above. Reason, in one line: the published English interpolates "to us" and renders `تَعَالَى` as "the Superior", which together adjudicate a contested attribute the deck must not adjudicate. | [Sahih al-Bukhari 1145](https://sunnah.com/bukhari:1145) | ṣaḥīḥ | ✅ **verified — and this is the corrected row (revision 3).** The Arabic reproduced in the box above **is identical in letters and diacritics to the archived page's `arabic_text_details`; identical as a string after Unicode NFC normalisation, not as raw bytes.** Substring test run programmatically 2026-08-02: **raw → False**, **NFC → True**, **NFC + format-character strip → True**. The archived page serves a different normalisation form and carries RLM/format characters, which a byte comparison sees and a reader does not. Revisions 1–2 said *"read off the archived page **character-for-character**"* — that named a stronger check than the one that passes, and it is **the identical overstatement `al-afuw@1` was corrected for in the same revision**; this row now uses that deck's corrected wording. ⚠️ **This row is deliberately not a "quoted verbatim from a published translation" ✅** — it is a different and weaker claim, and it is stated as such: *the Arabic is verified; the English is ours*. |
| 5.3 | Beat 6, verse anchor, verbatim marked excerpt: "And whoever is grateful — his gratitude is only for [the benefit of] himself. And whoever is ungrateful — then indeed, my Lord is Free of need and Generous." | **Saheeh International**; the `[the benefit of]` bracket is the translator's own, present in the fetched string. **Abdel Haleem (85) fetched and compared** (*"if anyone is grateful, it is for his own good, if anyone is ungrateful, then my Lord is self-sufficient and most generous"*): it carries **no spaced hyphens**, so the normalisation below would vanish — and it lower-cases the Name, which is the one thing this verse beat exists to show. Saheeh International kept; see the correction box above. | [Qur'ān 27:40](https://quran.com/27/40) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/27:40?translations=20,85`, 2026-08-02. **Word-for-word exact; one typographic normalisation, disclosed and re-tested:** Saheeh International prints a spaced hyphen (`grateful - his`, `ungrateful - then`) and the beat renders both as em dashes (`grateful — his`). Programmatic substring test, re-run 2026-08-02: **as printed on the beat → False; with the two hyphens restored → True.** No word, bracket or punctuation mark of meaning is changed; a spaced hyphen reads as a typo on the reveal canvas. This remains the *only* such substitution in the batch — the other quoted Qur'ān strings across the five decks (18:11, 18:18, 33:43, 4:110, 97:3, 42:25, and `al-haleem@1`'s new 19:90, 19:91, 35:45) were each re-tested this revision and are **byte-exact substrings** of the fetched Saheeh International after footnote markers are stripped. Arabic `غَنِيٌّ كَرِيمٌ` — **the Name in-text**. The verse opens with the throne being brought and the quoted clause is **Sulaymān's speech**, disclosed here and marked as an excerpt on screen. |
| 5.4 | Beat 8, "a supply that runs down" — supporting narration, **quoted in no beat**: "Allah's Hand is full, and (its fullness) is not affected by the continuous spending night and day." | sunnah.com's published English (Muhsin Khan), named here because it appears nowhere on screen and therefore carries no theological surface | [Sahih al-Bukhari 4684](https://sunnah.com/bukhari:4684) | **ṣaḥīḥ** — Ṣaḥīḥ al-Bukhārī | ✅ **verified** via Wayback archive of the exact URL, 2026-08-02 |
| 5.5 | Duʿā text | catalog id 30 (`collectible_names.json`) — **no scripture citation claimed** | catalog only | n/a | ✅ **verified byte-identical to catalog** — re-checked programmatically 2026-08-02 across all three fields (`dua_arabic`, `dua_transliteration`, `dua_translation`); the ship gate enforces it independently |
| 5.6 | Beat 2 `name_intro` | catalog id 30 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`, re-checked programmatically 2026-08-02 |

### ⚠️ Catalog-level flag the founder should see (not fixable by a deck)

**The Name card contradicts this deck's own reason for rejecting its most famous verse.** This deck rejects 96:3 as the verse anchor precisely because its word is *al-Akram* (superlative), not *al-Karīm* — *"using it would quietly widen the Name"*. But catalog id 30's `hadith` field reads:

> *"Allah introduced Himself in the first revelation as Al-Karim: 'Recite, and your Lord is Al-Akram — the Most Generous.' (Quran 96:3)"*

So the Name card does exactly what the deck refused to do, on the same āyah, and states it as an identification (*"introduced Himself … as Al-Karim"*). A user who meets this deck and then the card is handed the widening the deck declined. **Founder decision: does the id 30 `hadith` line change?** This is the same class of flag `al-ghafur@1` raises for its Name; it was not raised here in revisions 1–2 and is raised now. It does not change any beat.

### Ship-gate note

**No `renderedDuaSources` entry for this deck** — its duʿā carries no citation, and it must stay unpinned.

This is now load-bearing. As of commit `a12f1db`, `renderedDuaSources` in `test/content/name_stories_ship_gate_test.dart` is asserted **in both directions**: an unpinned deck that carries a `source` on its duʿā beat **fails** the gate, and a pinned deck that drops its `source` fails too. Transcription rule for this deck: **the duʿā beat must carry no `source` field, and `al-kareem@1` must not be added to `renderedDuaSources`.** (Note this constrains only the *duʿā* beat — the story beats' `source` fields, including whichever form of the Bukhārī 1145 attribution the founder picks in the K3 decision above, are unaffected by that map.)

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 14 shipped decks

**Baseline correction (revision 3).** Previous revisions' collision tables understated the shipped decks — they listed one or two sources per deck when the shipped `sources` arrays and beat `source` fields carry more. The table below is rebuilt from `assets/content/name_stories.json` itself (every `sources[].url` plus every beat `source`), 2026-08-02. Additions the earlier tables did not show are marked **(+)**.

| shipped deck | its narrative | its full inventory | collides? |
|---|---|---|---|
| `ar-razzaq@1` | the birds going out empty | Tirmidhī 2344; 65:2, 65:3 | ✖ none — nearest in *theme* (provision without depletion), but different narration, different verse, different Name-engine (reliance vs. generosity that initiates) |
| `al-ghaffar@1` · `at-tawwab@1` · `ar-rahman@1` · `al-baseer@1` | Bukhārī 7507; 39:53 · Bukhārī 3470; 2:37 · Bukhārī 5999; 2:286, 7:156, **55:1 (+)** · Bukhārī 3364; 58:1, **Ibn Mājah 188 (+)** | | ✖ none — no shared narration number |
| `ash-shafi@1` · `al-wadud@1` · `al-fattah@1` | Bukhārī 5743 (cf.); 21:83–84, 26:80 · Muslim 2747a, Bukhārī 6309; 11:90 · Bukhārī 4172, 4833, **2731 (+)**; 48:1, 35:2 | | ✖ none |
| `as-salam@1` · `al-wakeel@1` · `al-hadi@1` · `al-jabbar@1` · `al-lateef@1` · `as-samad@1` | Muslim 591, **Bukhārī 3653 (+)**; 13:28, **9:40 (+)**, **59:23 (+)** · 3:172–174, 65:3, **Bukhārī 4563 (+)** · 28:22, **28:15/21/23 (+)**, 22:54, **1:6 (+)** · 12:84, 12:86, 12:87, **12:18/12:94 (+)** · 12:100, **12:15/12:20/12:42 (+)**, 42:19, 67:13 · 19:2–7, 112:2 | | ✖ none |
| **sibling drafts in this batch** | `al-ghafur@1` (Bukhārī 2441, Abū Dāwūd 1516, 4:110) · `al-afuw@1` (Ibn Mājah 3850, Tirmidhī 3513, 97:3, 42:25) · `al-haleem@1` (**re-sourced in revision 3** — Bukhārī 7378, 19:90–91, 35:45) · `ar-raheem@1` (18:10, 18:11, 18:18, 33:43) | | ✖ none |

**Verified negative, run against the rebuilt inventory above:** no shipped deck and no sibling draft uses **Bukhārī 1145, Bukhārī 4684 or 27:40**. The complete shipped ḥadīth set is Bukhārī 3653, 4563, 6309, 7507, 3470, 5743, 2731, 4172, 4833, 5999, 3364 · Muslim 591, 2747a · Tirmidhī 2344 · Ibn Mājah 188 — neither 1145 nor 4684 is in it. Nearest structural neighbour: `al-fattah@1` also uses Sūrat Fāṭir (35:2) as `al-haleem@1` now does (35:45); nothing touches Sūrat an-Naml.

**Insight-level check (the axis the collision tables previously missed).** Beat 8 — *"You are not drawing on a supply that runs down. The One being asked is Free of need — the asking costs Him nothing at all."* — checked against the shipped closing insights, in particular `ar-razzaq@1` (provision that does not depend on the striving) and `al-lateef@1` ("visible only from the far side"). **✖ none.** `ar-razzaq@1` is the nearest and its engine is the *arriving* of provision; this one's is the *cost to the Giver*.

### Authoring notes (candidates considered)

- **Selected: the last third of the night, Bukhārī 1145.** It is the only candidate whose *timing* matches the product: this app's core loop is a nightly muḥāsabah, and a user meeting this Name is very often reading it in the exact hour the narration describes. *Karam* is generosity that initiates — and in this narration the asking is called for before it is offered.
  - **Honest weakness, recorded (the adversary raised it and it is fair):** Bukhārī 1145 contains no form of `k-r-m`. Its engine is nearness and responsiveness — arguably `al-Qarīb` / `al-Mujīb`. On protocol selection criterion (2), *"best of all when the Name/phrase appears IN the source text"*, this story scores **low**; the Name-in-text is carried only by the verse beat (27:40, `غَنِيٌّ كَرِيمٌ`). The argument for selection is product-timing, which is genuinely good product reasoning but **is not the protocol's criterion**, and the founder should sign it knowing that.
  - **Second honest note:** 27:40's `غَنِيٌّ` is Sulaymān saying Allah does not need *his* gratitude. Beat 8 repurposes it — "the asking costs Him nothing at all" — into a claim about the cost of petition. The proposition is true and is supported by Bukhārī 4684, but 4684 is deliberately never shown, so beat 8's support is invisible to the reader while the verse above it says something adjacent rather than the same thing.
- **Rejected — the private conversation (Bukhārī 2441).** Would work for Al-Kareem, but it is the selected story of `al-ghafur@1` in this same batch, and its engine is concealment, which belongs to that Name.
- **Rejected as the story — "Allah's Hand is full" (Bukhārī 4684, ṣaḥīḥ, verified).** One image, not a narrative; three beats would be padding. Retained in the sources table as the support for beat 8's phrasing, quoted in no beat. **It remains the substitute story if the founder rules the pack should stay off the descent narration entirely** — with the caveat that 4684 is *itself* a divine-attribute text ("Allah's Hand is full"), so it swaps one contested attribute for another rather than avoiding the category.
- **Verse anchor: 27:40 chosen over [Qur'ān 82:6](https://quran.com/82/6) and [Qur'ān 96:3](https://quran.com/96/3)** (both verified by live fetch, 2026-08-02). 82:6 — *"O mankind, what has deceived you concerning your Lord, the Generous"* — is the most famous Al-Karīm verse and has the Name in-text, but it is a rebuke, and the register rule for a burdened reader is mercy-led. 96:3 — *"Recite, and your Lord is the most Generous"* — is warm and is what the catalog's own `hadith` field cites, but its word is *al-Akram* (superlative), not *al-Karīm*; using it would quietly widen the Name. 27:40 has *Karīm* literally, is warm, and says the thing the user needs.
- **Register check:** no beat says the Name is waiting for the reader. Beat 5's closing line describes the three questions inside the quotation.
