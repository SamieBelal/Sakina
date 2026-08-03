# Deck Draft — Al-Waliyy (hardship pack, Wave G batch 2, 4 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

**This is the weakest of the five and it is presented as such.** It clears all five bars, but it has two costs the founder must price — a **register question** (its duʿā is literally about travel) and a **sūrah-crowding question** (its verse beat is the third deck in Sūrat ash-Shūrā). Both are laid out below, and a clean cut option is stated at the end.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G, §G2b. Author: Claude, 2026-08-03.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com`; ḥadīth via Wayback archive of the exact `sunnah.com` URL. Story beats paraphrase only what the cited source carries, and every paraphrase is labelled.

**Translation standard:** Saheeh International (`20`) for Qur'ān, Abdel Haleem (`85`) fetched and compared per row and adopted nowhere. Khattab (`131`) remains unfetchable. **For ḥadīth this deck makes a deliberate, disclosed split between two collections — see rows 4.2 and 4.3.**

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on every beat.

---

## Deck `al-waliyy@1` — Al-Waliyy

**Why this deck exists, in one line:** catalog id 64's duʿā is, word for word, a clause of a ṣaḥīḥ Muslim narration — **and it is the only duʿā in the catalogue that names both halves of the ICP's actual life: where they are, and the people they are not with.**

**Proposed metadata**

```json
{
  "deck_id": "al-waliyy@1",
  "name_id": 64,
  "transliteration": "Al-Waliyy",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You are far from the people who would notice, and the people you left are far from you. Both halves of that have one Name.

**Beat 2 · name_intro** *(from `collectible_names.json` id 64, verbatim)*:
> الْوَلِيُّ — Al-Waliyy — The Protecting Friend

**Beats 3–5 · story — "Setting out":**
> 1. Whenever the Prophet ﷺ set out on a journey and mounted his camel, he said the same words.
> 2. **"O Allah You are the companion on the journey, and the caretaker for the family."**
> 3. **"O Allah, I seek refuge in You from the difficulties of the journey, and from returning in great sadness."**

**Beat 6 · verse** *(the Name appears in the verse itself)*:
> "And it is He who sends down the rain after they had despaired and spreads His mercy. And He is the Protector, the Praiseworthy." — Qur'ān 42:28

**Beat 7 · duʿā** *(catalog id 64, verbatim in full — the second sentence of the narration above)*:
> اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ
> *Allahumma anta's-sahibu fi's-safar wa'l-khalifatu fi'l-ahl*
> "O Allah, You are my companion in travel and the guardian over my family."
>
> *(proposed `source` field on this beat: `Sahih Muslim 1342`)*

**Beat 8 · takeaway:**
> One half of that sentence is about where you are. The other half is about the people you are not with. He is named for both at once.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | ⚠️ **This is the deck's weakest bar and it is met on the verse beat, not the story beats.** 42:28 is Allah's own words and it is an **action**: `وَهُوَ ٱلَّذِى يُنَزِّلُ ٱلْغَيْثَ مِنۢ بَعْدِ مَا قَنَطُوا۟` — He sends the relief **after** they have given up, and the āyah names Him `ٱلْوَلِىُّ` in the same breath. The story beats are a **taught duʿā**, i.e. what the Prophet ﷺ *said about* Allah, not a narrated act of Allah. **That is the same construction `al-afuw@1` uses and the reviewer called that deck the batch's cleanest** — but it is worth naming rather than assuming. | **yes — beat 6 carries the bar** |
| 2 | **the distinguishing quality is shown, not stated** | Al-Waliyy's distinguishing quality against `as-samad@1` (leaned on) and `al-wakeel@1` (entrusted with) is **presence and guardianship in two places at once** — with the person, and over what the person left. The duʿā states exactly that split; 42:28 supplies the timing (`after they had despaired`). | **yes — beats 4 and 6** |
| 3 | **does not collapse into a sibling Name** | No form of `r-ḥ-m` on any beat *in the Name position* — **one disclosure:** 42:28's quoted English contains *"spreads His mercy"* (`وَيَنشُرُ رَحْمَتَهُۥ`). It is a verb about what He does, not a Name, and it stands next to `ٱلْوَلِىُّ` rather than substituting for it; `ar-rahman@1`'s own verse beat is 7:156 and `ar-raheem@1`'s is 33:43, so no shipped or batch-1 deck's verse text is repeated. **Second disclosure:** 42:28 ends `ٱلْوَلِىُّ ٱلْحَمِيدُ` — Al-Hameed (catalog id 65), **not shipped and not in this batch.** No `w-k-l` and no `ṣ-m-d` anywhere. | **yes, with two disclosures** |
| 4 | **the Name's own root appears in the source text** | **Yes — `ٱلْوَلِىُّ` is in 42:28**, and Saheeh International renders it *"the Protector"*. **Disclosed:** the catalogue's English for id 64 is *"The Protecting Friend"*, so the verse beat prints a shortened form of the beat-2 word, not the same word. Partial criterion-(2) hit. The root is **not** in the ḥadīth. | **yes — beat 6** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | The ḥadīth is a free-standing duʿā narration with no consequence clause. 42:29 is a creation-signs āyah. **The disclosure this deck owes is in the *backward* direction and on sūrah crowding — full table below.** | **yes — verified, with disclosures** |

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **Jami\` at-Tirmidhi 3438** | Nothing narrative. The page carries Abū ʿĪsā's remark on the isnād and a second route through Suwayd; there is no continuation of the scene and no consequence clause. | **clean, and structurally clean.** |
| **Sahih Muslim 1342** | The narration continues past the deck's material with the returning form: *"We are returning, repentant, worshipping our Lord. and praising Him."* | **clean** — the continuation is dhikr, not warning. Recorded because the deck stops before it. |
| **42:28** (n−1) | 42:27 *"And if Allāh had extended [excessively] provision for His servants, they would have committed tyranny throughout the earth. But He sends [it] down in an amount which He wills. Indeed He is, of His servants, Aware and Seeing."* | **clean, but it changes how the beat must be read, and it is disclosed on two counts.** (a) **Abdel Haleem renders 42:28 lower-case** — *"it is He who sends relief through rain…"* — which is §G2b's reliable tell that **42:28 grammatically continues 42:27**. Saheeh International capitalises it and it stands alone as an English sentence, which is why it can start a beat unedited. (b) 42:27 contains `ٱلرِّزْقَ` and `بَسَطَ` — the roots of `ar-razzaq@1` (shipped) and Al-Basit (catalog id 25) — one āyah before this deck's verse beat. Not on screen. |
| **42:28** (n+1) | 42:29 *"And of His signs is the creation of the heavens and earth and what He has dispersed throughout them of creatures. And He, for gathering them when He wills, is competent."* | **clean, with one within-batch disclosure:** 42:29 ends `قَدِيرٌ` — **`al-qadir@1`'s Name-noun, one āyah past this deck's verse beat.** It reaches no screen in either deck. This is the `al-haleem@1` 35:41-`غَفُورًا` class of finding, caught by the sweep before it became a beat. |
| **42:28, in its neighbourhood** | 42:25 is **`al-afuw@1`'s verse beat**. 42:26 ends *"But the disbelievers will have a severe punishment"* — the clause `al-afuw@1`'s own sweep already disclosed. 42:19 is **`al-lateef@1`'s verse beat**. | ⚠️ **the deck's second real cost. Sūrat ash-Shūrā would carry three decks: `al-lateef@1` at 42:19 (shipped), `al-afuw@1` at 42:25 (batch 1), and this one at 42:28.** No shared āyah and no shared quotation, but 42:25 and 42:28 are **three āyāt apart** and both are verse beats. If the founder's rule is "one deck per passage", this deck fails it and should take a different anchor or be cut. See Authoring notes for what the alternatives cost. |

### ⚠️ The register question — this deck's largest risk, stated plainly

**Catalog id 64's duʿā is a travel supplication, and the user reciting it is in a bedroom at 1am.** *"O Allah, You are my companion in travel and the guardian over my family."*

Three things bear on it, and the founder should weigh them himself:

1. **The catalogue already reads it figuratively.** Id 64's own `lesson` line is *"You are never alone. Al-Waliyy is closer to you than your own loneliness."* — no travel in it. The app has already decided this duʿā means what the deck says it means; the deck did not invent the reading.
2. **The ICP is disproportionately literally in it.** A 20-something Muslim away from the city they grew up in, with parents in another country, is not reading *"companion in travel / guardian over the family"* as a metaphor. **Beat 1 is written to make that reading the obvious one without ever asserting it.**
3. **It is nonetheless a stretch the other four decks in this batch do not make**, and if the founder reads beat 7 and feels the duʿā belongs to a suitcase rather than to the reader, that is the correct thing to fail this deck on. **There is no substitute duʿā** — the ship gate forces byte-identity with catalog id 64. Failing on this means cutting the Name from this batch, which is a clean outcome and is recommended over a fourth compromise.

### ⚠️ The two-collection split on the ḥadīth — deliberate, disclosed, and reversible in one line

**The duʿā is pinned to Ṣaḥīḥ Muslim 1342. The beats quote Jāmiʿ at-Tirmidhī 3438.** Both narrations carry the **identical Arabic clause**; the split is purely about which published English reaches the screen.

| | Ṣaḥīḥ Muslim 1342 (Ibn ʿUmar) | Jāmiʿ at-Tirmidhī 3438 (Abū Hurayra) |
|---|---|---|
| grade | **ṣaḥīḥ** (collection's own condition) | **ḥasan (Darussalam)**; Abū ʿĪsā's own remark: `حَسَنٌ غَرِيبٌ` |
| the clause, in Arabic | `اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الأَهْلِ` | **identical** |
| sunnah.com's published English | *"O Allah, Thou art (our) companion during the journey, and guardian of (our) family."* | *"O Allah You are the companion on the journey, and the caretaker for the family"* |
| refuge clause | *"I seek refuge with Thee from hardships of the journey, gloominess of the sights, and finding of evil changes in property and family on return."* | *"I seek refuge in You from the difficulties of the journey, and from returning in great sadness"* |

**Why the split rather than one collection for both:** the founder review checklist asks that *"a 20-something scrolling from a reel understands every word"*. Muslim's English on sunnah.com is Siddiqui's 1970s rendering — *"Thou art"*, *"gloominess of the sights"*, *"finding of evil changes in property and family on return"*. The batch rule inherited from `al-haleem@1` is **re-render only where the published English resolves a contested reading; readability alone is not a licence** — so re-rendering Muslim's English was not available. Quoting a **different, verified, ḥasan narration of the same words** was.

**What it costs, stated plainly:** beats 4–5 will render the source line `Jami' at-Tirmidhi 3438` while beat 7 renders `Sahih Muslim 1342`. A careful reader sees two citations for one sentence. That is honest but it is a seam, and it is exactly the "quiet mismatch" `al-afuw@1` went out of its way to avoid.

**Three options, all one line:**
- **(a) as drafted** — Tirmidhī on the story beats, Muslim on the duʿā. Strongest grade where the words are, most readable English where the prose is.
- **(b) Muslim throughout** — pin stays, beats 4–5 quote *"Thou art (our) companion…"*. One citation, archaic English.
- **(c) Tirmidhī throughout** — beats and pin both `Jami' at-Tirmidhi 3438`. One citation, modern English, **ḥasan rather than ṣaḥīḥ on the duʿā line the user sees.**

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 4.1 | Beat 3: the Prophet ﷺ said these words whenever he set out and mounted | paraphrase of both narrations (Muslim: *"whenever Allah's Messenger ﷺ mounted his camel while setting out on a journey"*; Tirmidhī: *"When the Prophet ﷺ would travel, and he would mount his riding camel"*) | [Sahih Muslim 1342](https://sunnah.com/muslim:1342) · [Jami' at-Tirmidhi 3438](https://sunnah.com/tirmidhi:3438) | ṣaḥīḥ · ḥasan | ✅ **verified** — both pages fetched via Wayback archives of the exact URLs, 2026-08-03. Muslim 1342: capture `20260303093718`, reference line *"Sahih Muslim 1342"*, in-book Book 15 Hadith 479, narrator **Ibn ʿUmar**, chapter *"It is recommended to recite statements of remembrance when setting out for Hajj or any other purpose"*. Tirmidhī 3438: capture `20260413080740`, reference line *"Jami\` at-Tirmidhi 3438"*, in-book Book 48 Hadith 69, narrator **Abū Hurayra**, `Grade : Hasan (Darussalam)`. **Labelled paraphrase** — the beat drops the takbīr-three-times detail and the `سُبْحَانَ ٱلَّذِى سَخَّرَ لَنَا هَـٰذَا` opening, which are real and simply do not fit three beats. |
| 4.2 | Beat 4 quotation, verbatim: "O Allah You are the companion on the journey, and the caretaker for the family." | **Jāmiʿ at-Tirmidhī 3438's published English (Darussalam), quoted as printed. NOT re-rendered.** See the split box above for why this collection and not Muslim's. | [Jami' at-Tirmidhi 3438](https://sunnah.com/tirmidhi:3438) | **ḥasan (Darussalam)** | ✅ **verified — substring test run programmatically: byte-exact substring** of the archived page English after whitespace normalisation. **One disclosure:** the beat adds a full stop where the published English runs on with a comma into the next clause. No word is changed, added, dropped or reordered. Page Arabic: `اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الأَهْلِ`. |
| 4.3 | Beat 5 quotation, verbatim: "O Allah, I seek refuge in You from the difficulties of the journey, and from returning in great sadness." | **Jāmiʿ at-Tirmidhī 3438's published English, quoted as printed.** Muslim 1342's rendering of the parallel clause is *"…hardships of the journey, gloominess of the sights, and finding of evil changes in property and family on return"* — **fuller** (Muslim's Arabic carries `وَكَآبَةِ الْمَنْظَرِ وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالأَهْلِ`, Tirmidhī's carries `وَكَآبَةِ الْمُنْقَلَبِ`), and unreadable at reveal-beat speed. **The two narrations differ in this clause and the deck quotes the shorter one; this is a real wording difference, not only a rendering difference, and it is disclosed here rather than blurred.** | [Jami' at-Tirmidhi 3438](https://sunnah.com/tirmidhi:3438) | ḥasan (Darussalam) | ✅ **verified — byte-exact substring** of the archived page English after whitespace normalisation. **One disclosure:** the beat adds a full stop where the published English runs on. |
| 4.4 | Beat 6, verse anchor, verbatim in full: "And it is He who sends down the rain after they had despaired and spreads His mercy. And He is the Protector, the Praiseworthy." | **Saheeh International.** Abdel Haleem fetched and compared: *"it is He who sends relief through rain after they have lost hope, and spreads His mercy far and wide. He is the Protector, Worthy of All Praise."* — **opens lower-case mid-sentence** (it continues 42:27) and so cannot start a beat without editing a quotation, which this batch does not do. It does not say "God" in this āyah. Not used. | [Qur'ān 42:28](https://quran.com/42/28) | Qur'ān | ✅ **verified** — live fetch `?translations=20,85`, 2026-08-03. **Byte-exact**; the fetched string carries **no footnote marker**. Arabic: `وَهُوَ ٱلَّذِى يُنَزِّلُ ٱلْغَيْثَ مِنۢ بَعْدِ مَا قَنَطُوا۟ وَيَنشُرُ رَحْمَتَهُۥ ۚ وَهُوَ ٱلْوَلِىُّ ٱلْحَمِيدُ`. |
| 4.5 | Duʿā text (catalog id 64) is the Arabic of Ṣaḥīḥ Muslim 1342 — **same words, same letters; the catalogue is one diacritic more fully vowelled than the archived page** | — | [Sahih Muslim 1342](https://sunnah.com/muslim:1342) | ṣaḥīḥ | ⚠️ **verified programmatically with a precise, disclosed caveat.** Catalog `dua_arabic` vs the archived page span: raw **False**, NFC **False**, NFC+format-strip **False**, **consonantal skeleton True**. Character-level diff: **four shadda-ordering differences** (the page orders the shadda and the vowel differently around the same letters) **plus one genuine extra mark in the catalogue — a sukūn (U+0652) on the lām of `الْأَهْلِ`, where the page reads `الأَهْلِ`.** Every letter and every word is the same. **The deck does not claim byte-identity**, and this is a strictly more honest statement than revision 1 of `al-afuw@1` made about its own duʿā. |
| 4.6 | Beat 2 `name_intro`, and the duʿā's transliteration and translation fields | catalog id 64 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english` and `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03. |
| 4.7 | Beat 8 | — | authored | n/a | ✅ **honest label — authored copy.** It restates the two halves of the clause quoted on beat 4 and the Name printed on beat 6. It makes **no promise to the reader** and attributes no stance to the Name. |

### ⚠️ Catalog-level flag (not fixable by a deck)

**Catalog id 64's `hadith` field cites a narration that is about something else:**

> *"The Prophet ﷺ said: 'Be in this world as if you are a stranger or a wayfarer.' Your only consistent companion is Al-Wali. (Bukhari)"*

The quoted ḥadīth is real and is in Bukhārī (unnumbered on the card), but it is an instruction about **detachment from the world**, and the sentence that follows it — *"Your only consistent companion is Al-Wali"* — is the card's own gloss, presented in the same breath. **The narration that actually carries this Name's duʿā is Ṣaḥīḥ Muslim 1342, and the card does not mention it.** Founder decision: id 64's `hadith` could carry Muslim 1342 instead, which would make the Name card and this deck teach the same narration. **Third of the four catalogue flags raised across the five batch-2 decks — and the only deck to raise two.**

**Second, smaller flag:** the card also spells the Name **"Al-Wali"** in its gloss, while `transliteration` is **"Al-Waliyy"** and catalog id **83** is a *different* Name also transliterated **"Al-Wali"**. Two Names, one spelling, on cards a user can hold at the same time.

### Ship-gate note — **this deck's duʿā citation MUST be pinned at transcription time**

If this deck is signed **as drafted (option a or b)**, add — this exact string:

```dart
'al-waliyy@1': 'Sahih Muslim 1342',
```

and the duʿā beat's `source` must read exactly `Sahih Muslim 1342`. **If the founder picks option (c)**, the pin and the beat both become `Jami' at-Tirmidhi 3438` — the map and the beat must change together or the gate goes red in both directions (commit `a12f1db`). Verified: with the `Sahih Muslim 1342` pin the full gate passes over `existing ∪ batch 2` with **0 failures**; without it the gate reports `al-waliyy@1 renders a duʿa citation that is not in renderedDuaSources`.

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 19 existing decks

| existing deck | its inventory | collides? |
|---|---|---|
| **`al-lateef@1`** (shipped) | 12:100/15/20/42, **42:19**, 67:13 | ⚠️ **shared sūrah.** Its verse beat is 42:19; this deck's is 42:28. Nine āyāt apart, no shared āyah, no shared quotation. See the crowding disclosure above. |
| **`al-afuw@1`** (batch 1) | Ibn Mājah 3850, Tirmidhī 3513, 97:3, **42:25** | ⚠️ **shared sūrah, three āyāt apart, both verse beats.** This is the closest citation adjacency in batch 2 after `al-mujeeb@1`'s, and it is the deck's second stated cost. |
| `as-salam@1` · `al-wakeel@1` | 13:28, 9:40, 59:23, Bukhārī 3653, **Muslim 591** · 3:172–174, 65:3, Bukhārī 4563 | ✖ none on citations. **`al-wakeel@1` is worth a word:** Al-Wakeel is *the One you hand outcomes to*; Al-Waliyy is *the One who is with you and over what you left*. Different engines, no shared source. |
| `al-wadud@1` · `al-hadi@1` · `al-ghaffar@1` · `at-tawwab@1` · `al-jabbar@1` | 11:90, Muslim 2747a, Bukhārī 6309 · 28:22 etc. · Bukhārī 7507, 39:53 · Bukhārī 3470, 2:37 · 12:84 etc. | ✖ none |
| `ash-shafi@1` · `ar-razzaq@1` · `al-fattah@1` · `ar-rahman@1` · `al-baseer@1` · `as-samad@1` | 21:83–84, 26:80, Bukhārī 5743 · 65:2–3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/2731 · 2:286, 7:156, 55:1, Bukhārī 5999 · 58:1, Bukhārī 3364, Ibn Mājah 188 · 19:2–7, 112:2 | ✖ none. **`as-samad@1` is worth a word:** its insight is *leaning is not weakness*; this deck's is *He is named for both places at once*. Different claims. |
| **batch-1 drafts** | `al-ghafur@1` · `al-kareem@1` · `al-haleem@1` · `ar-raheem@1` | ✖ none beyond the `al-afuw@1` row above |
| **batch-2 siblings** | `al-mujeeb@1` · `al-qayyum@1` · **`al-qadir@1`** · `al-muid@1` | ⚠️ **`al-qadir@1`'s Name-noun sits in 42:29, one āyah after this deck's verse beat.** Off-screen in both decks. Disclosed. |

**Verified negative, run programmatically:** **42:28, Ṣaḥīḥ Muslim 1342 and Jāmiʿ at-Tirmidhī 3438** appear in **no** shipped deck and **no** batch-1 draft. (`as-salam@1` cites **Muslim 591**, a different narration.)

**Insight-level check.** Beat 8 — *"One half of that sentence is about where you are. The other half is about the people you are not with. He is named for both at once."*

| checked against | its insight | verdict |
|---|---|---|
| `as-samad@1` (shipped) | *"'Needed by all' means everyone leans here… Leaning is not weakness; it is the meaning of the Name."* | ✖ none — that is about **permission to lean**; this is about **simultaneous presence in two places**. |
| `al-lateef@1` (shipped) | *"What you couldn't say was never unsaid to Him."* | ✖ none — and worth checking hard, since two real insight collisions with `al-lateef@1` were found in batch 1. That deck's move is about **being known**; this one's is about **being accompanied**. |
| `al-wakeel@1` (shipped) | *"You were never asked to hold every outcome."* | ✖ none |
| `al-baseer@1`, `al-fattah@1`, `al-afuw@1`, `al-kareem@1`, `ar-raheem@1` | seen · gatekeepers · what was chosen to be asked for · the supply does not run down · the sentence was theirs first | ✖ none |

### Authoring notes (candidates considered)

- **Selected: the travel duʿā (Muslim 1342 / Tirmidhī 3438), anchored on 42:28.** The properties: the catalogue duʿā **is** a clause of a ṣaḥīḥ narration (plan §STEP-3 property 1), the verse anchor carries the Name in-text **and** contains the single most on-register phrase found anywhere in this batch's sweep — *"after they had despaired"* — and no shipped or batch-1 deck uses either source.
- **Rejected as the verse anchor — [Qur'ān 2:257](https://quran.com/2/257)** (fetched, 2026-08-03; Saheeh International: *"Allāh is the Ally of those who believe. He brings them out from darknesses into the light."*). On content it is the best Al-Waliyy āyah in the Qur'ān, and the Name is in-text. **Rejected on two counts:** (a) **the second half of the same āyah** turns to those who disbelieve and ends *"Those are the companions of the Fire; they will abide eternally therein."* — the threat is **inside** the āyah, not merely after it, so no excerpt is fully honest, and this deck is not going to argue that a mid-āyah cut is fine; (b) `ٱلظُّلُمَـٰت` — *"darknesses"* — is the operative word of **`al-mujeeb@1`'s beat 4 in this same batch.**
- **Rejected as the verse anchor — [Qur'ān 12:101](https://quran.com/12/101)** (fetched; `أَنتَ وَلِىِّۦ فِى ٱلدُّنْيَا وَٱلْـَٔاخِرَةِ`, Saheeh International *"You are my protector in this world and the Hereafter."*). The Name is in-text, but the words are **Yūsuf's**, not Allah's — bar 1 — and **it is the āyah immediately after `al-lateef@1`'s verse-and-story anchor at 12:100**, in a sūrah that already carries two shipped decks.
- **Rejected as the verse anchor — [Qur'ān 7:196](https://quran.com/7/196)** (fetched; Saheeh International *"Indeed, my protector is Allāh, who has sent down the Book; and He is an ally to the righteous."*). It is **human speech** — the Prophet's ﷺ declaration — so on bar 1 it would teach the Name through what a person says rather than what Allah does. That is the reverence line the format spec draws and the ground Ṭāʾif was rejected on in batch 1.
- **Rejected as the Name for this material — Al-Wali (catalog id 83, "The Governor").** Its authored duʿā is arguably better on register (*"be my protector when the world drifts away… guide me gently through what I do not understand"*), but the Name is thin Qur'ānically: its clearest occurrence, [13:11](https://quran.com/13/11) (fetched), is a **negative** construction — Saheeh International *"And there is not for them besides Him any patron."* — and it is transliterated identically to id 64 on the cards. Two Names, one spelling, one batch: not both.
- **The clean cut option, recommended over any further compromise:** if the founder does not price the register question and the ash-Shūrā crowding, **cut Al-Waliyy from batch 2.** Batch 1 proved that is a legitimate outcome. The batch then ships four, and Al-Hayy (id 15, on Tirmidhī 3524, ḥasan — see `al-qayyum@1`'s authoring notes) is the ready replacement with a stronger narration and no register question.
- **Register check:** no beat attributes waiting, wanting or withholding to the Name. Beat 8 reports the clause and the verse and makes no promise to the reader.
