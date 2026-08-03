# Deck Draft — Al-Mujeeb (hardship pack, Wave G batch 2, 1 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G, §G2b (the five bars + the successor sweep). Author: Claude, 2026-08-03. Batch theme: **hardship — the register of the user whose situation has not lifted, who is enduring rather than repenting.** Batch 1 completed mercy/forgiveness.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com` against the canonical `quran.com/{surah}/{ayah}` reference; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching). Scripture is quoted exactly from the fetched pages; story beats paraphrase only what the cited source carries, and every paraphrase is labelled as one.

**Translation standard (inherited from batch 1, founder ruling A1):** every Qur'ānic quotation is **Saheeh International** (`resource_id: 20`), quoted verbatim, with the **Abdel Haleem (`resource_id: 85`)** alternative fetched and compared per row. Abdel Haleem renders the divine name as **"God"** and lower-cases the Names, which would break the vocabulary of 19 decks; it is therefore **compared and named per row, adopted nowhere**. Khattab (`131`) remains unfetchable (`/quran/translations/131?verse_key=…` returns `{"translations":[]}`, re-confirmed 2026-08-03), so it is not quotable and the fetch-first rule forbids quoting it from memory.

**Implementation note (binding):** every beat stores Arabic / transliteration / translation as **separate fields**. Any em-dash formatting below is markdown shorthand only, never a single mixed-direction `Text`.

---

## Deck `al-mujeeb@1` — Al-Mujeeb

**Why this deck exists, in one line:** it is the one Name in the catalogue whose duʿā is, letter for letter, the sentence its story is about — **catalog id 37's `dua_arabic` is the closing clause of Qur'ān 21:87**, the words Yūnus said inside the fish. Plan §STEP-3 property 1, at full strength.

**Proposed metadata**

```json
{
  "deck_id": "al-mujeeb@1",
  "name_id": 37,
  "transliteration": "Al-Mujeeb",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You have said it more than once and nothing has moved. This is the Name for what happens to a sentence after it leaves you.

**Beat 2 · name_intro** *(from `collectible_names.json` id 37, verbatim)*:
> الْمُجِيبُ — Al-Mujeeb — The Responsive

**Beats 3–5 · story — "Inside the fish":**
> 1. A prophet went off in anger, and ended up inside the fish.
> 2. He called out within the darknesses: **"There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers."** There is nothing asked for in it.
> 3. **"So We responded to him and saved him from the distress. And thus do We save the believers."**

**Beat 6 · verse** *(excerpt, marked — the Name's own root is the verb of the sentence)*:
> "…indeed I am near. I respond to the invocation of the supplicant when he calls upon Me." — Qur'ān 2:186

**Beat 7 · duʿā** *(catalog id 37, verbatim in full — these are the words of Qur'ān 21:87)*:
> لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ
> *La ilaha illa anta subhanaka inni kuntu minaz-zalimin*
> "There is no god but You, glory be to You; indeed I have been of the wrongdoers."
>
> *(proposed `source` field on this beat: `Qur'an 21:87`)*

**Beat 8 · takeaway:**
> He asked for nothing. He said who Allah is, and who he had been — and that was enough to be answered.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | 21:88 — `فَٱسْتَجَبْنَا لَهُۥ وَنَجَّيْنَـٰهُ مِنَ ٱلْغَمِّ`. Allah is the subject; the verb is the Name's own root. Not asserted by the deck's prose and not carried by a trailing epithet. | **yes — beat 5** |
| 2 | **the distinguishing quality is shown, not stated** | The distinguishing quality of *Al-Mujīb* against `ar-rahman`/`ar-raheem` is not mercy but **response to a call**. The text supplies both halves in sequence: `فَنَادَىٰ` (he called) → `فَٱسْتَجَبْنَا` (We responded). 2:186 states the same pair as a standing rule: `أُجِيبُ دَعْوَةَ ٱلدَّاعِ إِذَا دَعَانِ`. | **yes — beats 4–6** |
| 3 | **does not collapse into a sibling Name** | No form of `r-ḥ-m`, `gh-f-r` or `ʿ-f-w` appears in any beat, in Arabic or in English. Nothing is forgiven, pardoned or healed anywhere in this deck — Yūnus is **answered** and **saved from distress** (`ٱلْغَمّ`), which is neither. **The one real adjacency is not a root, it is a shipped deck's sentence — see the ⚠️ box below, which is the most important thing on this page.** | **partly — the adjacency is off-screen; see below** |
| 4 | **the Name's own root appears in the source text** | **Yes, twice, and once as the finite verb of the beat.** `فَٱسْتَجَبْنَا` (21:88) and `أُجِيبُ` / `ٱلدَّاعِ … دَعَانِ` (2:186) are both `j-w-b` forms with Allah as subject. Tirmidhī 3505 gives a third: `إِلاَّ اسْتَجَابَ اللَّهُ لَهُ`. This deck does **not** pay the criterion-(2) cost that `al-haleem@1`, `al-kareem@1` and `ar-raheem@1` had to disclose. | **yes — beats 5 and 6** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | 21:89–90 immediately follow with Zakariyyā and `فَٱسْتَجَبْنَا لَهُۥ وَوَهَبْنَا لَهُۥ يَحْيَىٰ` — a second answered call, not a punishment. 2:187 is a fasting ruling. Full table below. | **yes — verified** |

### ⚠️ The one thing that could sink this deck: `ash-shafi@1` is four āyāt away and already quotes this deck's verb

This is disclosed first, at full strength, because it is the same defect class that cost batch 1 a whole deck (`ar-rahman@1`'s check caught one collision and missed `ash-shafi@1`).

`ash-shafi@1` **ships** with Ayyūb at **21:83–84**. This deck uses **21:87–88**. They are in the same passage of Sūrat al-Anbiyāʾ, three āyāt apart, and **they share an identical Qur'ānic verb phrase**:

| | `ash-shafi@1` (shipped) | `al-mujeeb@1` (proposed) |
|---|---|---|
| Arabic | 21:84 `فَٱسْتَجَبْنَا لَهُۥ فَكَشَفْنَا مَا بِهِۦ مِن ضُرٍّ` | 21:88 `فَٱسْتَجَبْنَا لَهُۥ وَنَجَّيْنَـٰهُ مِنَ ٱلْغَمِّ` |
| what is on screen | *"So We answered his prayer and removed his adversity, and gave him back his family, twice as many, as a mercy from Us."* (Khattab rendering, pinned in its `sources`) | *"So We responded to him and saved him from the distress. And thus do We save the believers."* (Saheeh International) |
| the deck's engine | what the answer **was** — restoration beyond the original | that there **was** an answer, and that the promise is generalised |
| closing insight | "The answer to Ayyūb was not repair. It was more than there was before the breaking." | "He asked for nothing… and that was enough to be answered." |

**The case for shipping it anyway, stated so the founder can reject it cleanly:**
1. **The two renderings differ on screen.** The shipped deck says *"answered his prayer… removed his adversity"*; this one says *"responded to him… saved him from the distress"*. A user meeting both does not read the same English sentence twice. That is luck, not design, and it is disclosed as luck.
2. **This deck's payload is the clause `ash-shafi@1` does not have:** `وَكَذَٰلِكَ نُنجِى ٱلْمُؤْمِنِينَ` — *"And thus do We save the believers."* Ayyūb's āyah ends with a reminder *for* worshippers; this one ends by extending the rescue *to* them. That generalisation is the reason the Name is teachable here and not there.
3. **No other Name in the catalogue has this duʿā.** The words on beat 7 are 21:87. If the deck moves to another passage, the single strongest property in the whole pipeline is thrown away.
4. **It is nonetheless a genuine proximity**, and if the founder's rule is "one deck per Qur'ānic passage", this deck fails it and should be cut. There is no substitute passage for Al-Mujīb's duʿā — see Authoring notes.

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **21:87** (n−1) | 21:86 *"And We admitted them into Our mercy. Indeed, they were of the righteous."* | **clean** — the passage arrives at this beat out of mercy, not out of warning. |
| **21:88** (n+1) | 21:89 *"And [mention] Zechariah, when he called to his Lord, 'My Lord, do not leave me alone [with no heir], while You are the best of inheritors.'"* → 21:90 *"So We responded to him, and We gave to him John…"* | **clean, and confirming** — the successor is a **second** answered call using the identical verb. Nothing in the neighbourhood turns to punishment. **Disclosed:** 21:89–90 is Zakariyyā, whose prayer is `as-samad@1`'s story at **19:2–7** — a different sūrah, different āyāt, and off-screen here, but the founder should know a shipped deck's protagonist is one tap past this deck's last story beat. |
| **2:186** (opens mid-āyah) | The omitted opening is *"And when My servants ask you, [O Muḥammad], concerning Me -"*. Nothing is hidden by the cut; it is dropped only because the vocative bracket does not read in one breath. | **clean** — marked as an excerpt on the beat. |
| **2:186** (n−1 / n+1) | 2:185 is the Ramaḍān fasting ruling; 2:187 is the fasting-night ruling. Neither is punishment. | **clean.** **Disclosed:** 2:187 contains `فَتَابَ عَلَيْكُمْ وَعَفَا عَنكُمْ` — the roots of `at-tawwab@1` (shipped) and `al-afuw@1` (batch 1) — one āyah after this deck's verse beat. Not on screen, not quoted, recorded because §G2b asks for sibling-root adjacency to be scanned. |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | Beat 3: a prophet "went off in anger" | paraphrase of the fetched Saheeh International (*"when he went off in anger"*) | [Qur'ān 21:87](https://quran.com/21/87) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/21:87?translations=20,85`, 2026-08-03. **Labelled paraphrase**; the beat adds nothing the āyah does not carry. Note the deck does **not** say "from his people" — 21:87 does not say that. |
| 1.2 | Beat 3: "inside the fish" | the narration's own words (`وَهُوَ فِي بَطْنِ الْحُوتِ`) | [Jami' at-Tirmidhi 3505](https://sunnah.com/tirmidhi:3505) | **ṣaḥīḥ** — page grade line `Grade : Sahih (Darussalam)` | ✅ **verified** via Wayback capture `20260217090443` of the exact URL, fetched 2026-08-03. Reference line: *"Jami\` at-Tirmidhi 3505"*. Narrator: **Saʿd (b. Abī Waqqāṣ)**. Chapter: *"Concerning the Supplication of Dhun-Nun"*. |
| 1.3 | Beat 4 quotation, verbatim: "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers." | **Saheeh International.** Abdel Haleem (85) fetched and compared: *"there is no God but You, glory be to You, I was wrong."* — shorter and cleaner, but it says **"God"**, and `إِنِّى كُنتُ مِنَ ٱلظَّـٰلِمِينَ` is flattened to three words, losing the self-description that beat 8 turns on. Not used. | [Qur'ān 21:87](https://quran.com/21/87) | Qur'ān | ✅ **verified** — **substring test run programmatically: byte-exact substring** of the fetched Saheeh International string **after stripping three `<sup>` footnote markers**. One of the three sits *inside* the quoted region, immediately after *"darknesses,"*; the deck's beat text does not reproduce it. **Disclosure:** the beat renders *"He called out within the darknesses:"* where the translation reads *"And he called out within the darknesses,"* — the connective is the deck's, the quoted sentence is not touched, and the nesting of quotation marks in the published English is thereby avoided rather than re-punctuated. |
| 1.4 | Beat 4's closing line: "There is nothing asked for in it." | — | authored | n/a | ✅ **honest label — authored copy, not a source claim.** It is an observation about the words quoted in the same beat, which contain no request. It asserts nothing about the narration or the āyah beyond what a reader can see on the screen. |
| 1.5 | Beat 5 quotation, verbatim in full: "So We responded to him and saved him from the distress. And thus do We save the believers." | **Saheeh International.** Abdel Haleem fetched and compared: *"We answered him and saved him from distress: this is how We save the faithful."* — genuinely tighter, and it does **not** say "God" here, so the batch-wide objection does not bite on this row. It is rejected only for batch consistency, and **the founder can take it; the cost is one row of mixed register.** | [Qur'ān 21:88](https://quran.com/21/88) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. **Byte-exact substring**; the fetched string carries **no footnote marker**, so nothing was stripped. Arabic: `فَٱسْتَجَبْنَا لَهُۥ وَنَجَّيْنَـٰهُ مِنَ ٱلْغَمِّ ۚ وَكَذَٰلِكَ نُـۨجِى ٱلْمُؤْمِنِينَ`. |
| 1.6 | Beat 6, verse anchor, verbatim excerpt: "…indeed I am near. I respond to the invocation of the supplicant when he calls upon Me." | **Saheeh International.** Abdel Haleem: *"I am near. I respond to those who call Me, so let them respond to Me…"* — more readable, says "God" only in the omitted opening, but drops `ٱلدَّاعِ` as a distinct noun. Not used. | [Qur'ān 2:186](https://quran.com/2/186) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. **Byte-exact substring**; no footnote marker in the fetched string. Arabic: `وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ ٱلدَّاعِ إِذَا دَعَانِ`. The excerpt is marked on the beat; the omitted tail (`فَلْيَسْتَجِيبُوا۟ لِى وَلْيُؤْمِنُوا۟ بِى لَعَلَّهُمْ يَرْشُدُونَ`) is an instruction, not a warning. |
| 1.7 | Beat 7 duʿā is the closing clause of 21:87 | — | [Qur'ān 21:87](https://quran.com/21/87) · [Jami' at-Tirmidhi 3505](https://sunnah.com/tirmidhi:3505) | Qur'ān / ṣaḥīḥ | ⚠️ **verified with a precise, disclosed caveat — read this row before signing.** Catalog id 37 `dua_arabic` is `لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ`. **Against `text_imlaei` of 21:87:** raw **False**, NFC **False**, NFC+format-strip **False**, **consonantal skeleton (all combining marks and format characters removed) True**. The differences are orthographic conventions, not words: the catalog writes `إِلَهَ` / `أَنْتَ` / `كُنْتُ` where quran.com's imlāʾī text writes `إِلَٰهَ` (dagger alif) / `أَنتَ` / `كُنتُ`. **Against the archived Tirmidhī 3505 page Arabic:** raw **False**, but the two strings are **identical as a multiset of code points** — the *only* difference is that the page orders `لاَ` / `إِلاَّ` (alif then fatḥa) where the catalog orders `لَا` / `إِلَّا` (fatḥa then alif). Every letter and every diacritic is the same. **Nothing here is a word-level difference, and the deck does not claim byte-identity.** |
| 1.8 | Beat 8's basis: the call was answered | — | [Qur'ān 21:88](https://quran.com/21/88) | Qur'ān | ✅ verified — the takeaway reports 21:88 and 21:87; it makes no promise to the reader and attributes no stance to the Name. |
| 1.9 | Beat 2 `name_intro`, and the duʿā's transliteration and translation fields | catalog id 37 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english` and `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03; the ship gate enforces each independently. |
| 1.10 | **Not on any beat, kept verified:** the Prophet's ﷺ promise attached to these exact words — *"So indeed, no Muslim man supplicates with it for anything, ever, except Allah responds to him."* | sunnah.com's published English, quoted as printed | [Jami' at-Tirmidhi 3505](https://sunnah.com/tirmidhi:3505) | **ṣaḥīḥ (Darussalam)** | ✅ **verified** — byte-exact substring of the archived page after whitespace normalisation. **Deliberately kept off the beats:** it would put a guarantee of response on a reveal screen, and the reverence line in the format spec is safer held. It is recorded here so the founder can add it to beat 8 if he wants it — **one line either way.** |

### ⚠️ Catalog-level flag (not fixable by a deck)

**Catalog id 37's `hadith` field cites the narration loosely and unnumbered:** *"The Prophet ﷺ said: 'No Muslim calls with the dua of Yunus except that Allah responds.' (Tirmidhi)"*. The wording is a fair précis of **Tirmidhī 3505** and the attribution to Tirmidhī is **correct** — this is the *opposite* of the `al-afuw@1` A2 flag, where the catalog named the wrong collection. Recorded as a positive check rather than a defect: **the Name card and this deck teach the same narration.** No founder action needed.

### Ship-gate note — **this deck's duʿā citation MUST be pinned at transcription time**

`renderedDuaSources` in `test/content/name_stories_ship_gate_test.dart` is asserted **in both directions** (commit `a12f1db`): a pinned deck that drops its `source` fails, **and an unpinned deck that carries a `source` also fails.** If this deck is signed, add — **this exact string**:

```dart
'al-mujeeb@1': "Qur'an 21:87",
```

and the duʿā beat's `source` field must read exactly `Qur'an 21:87`. *(This document does not edit the test or `name_stories.json`.)* Verified: with this pin the full gate passes over `existing ∪ batch 2` with **0 failures**; without it, the gate reports `al-mujeeb@1 renders a duʿa citation that is not in renderedDuaSources`.

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 19 existing decks (14 shipped + 5 batch-1 drafts)

Rebuilt from `assets/content/name_stories.json` (every `sources[].url` plus every beat `source`) and from the five batch-1 draft files, 2026-08-03.

| existing deck | its narrative | its inventory | collides? |
|---|---|---|---|
| `as-salam@1` · `al-wakeel@1` | the cave of Thawr · after Uḥud | 13:28, 9:40, 59:23, Bukhārī 3653, Muslim 591 · 3:172–174, 65:3, Bukhārī 4563 | ✖ none |
| `al-wadud@1` · `al-hadi@1` | the lost camel · Mūsā to Midian | 11:90, Muslim 2747a, Bukhārī 6309 · 28:22, 28:15/21/23, 22:54, 1:6 | ✖ none |
| `al-ghaffar@1` · `at-tawwab@1` | the servant who kept returning · the hundred lives | Bukhārī 7507, 39:53 · Bukhārī 3470, 2:37 | ✖ none — and the **engines** differ: those two are *return and acceptance*; this one is *a call and its answer*. Nothing in this deck is forgiven. |
| `al-jabbar@1` · `al-lateef@1` | Yaʿqūb's grief · Yūsuf | 12:84/86/87/18/94/96 · 12:100/15/20/42, 42:19, 67:13 | ✖ none |
| **`ash-shafi@1`** | **Ayyūb** | **21:83–84**, 26:80, Bukhārī 5743 | ⚠️ **the batch's headline disclosure — same sūrah, three āyāt away, shared verb phrase. Full table above.** |
| `ar-razzaq@1` · `al-fattah@1` | the birds · Ḥudaybiyyah | 65:2–3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/2731 | ✖ none |
| `ar-rahman@1` · `al-baseer@1` · `as-samad@1` | mother among captives · Hājar · Zakariyyā | 2:286, 7:156, 55:1, Bukhārī 5999 · 58:1, Bukhārī 3364, Ibn Mājah 188 · **19:2–7**, 112:2 | ⚠️ **`as-samad@1` only, and off-screen:** this deck's successor āyāt (21:89–90) are Zakariyyā's prayer in another sūrah. No shared āyah, no shared quotation, nothing on a beat. Disclosed. |
| **batch-1 drafts** | `al-afuw@1` (Ibn Mājah 3850, Tirmidhī 3513, 97:3, 42:25) · `al-ghafur@1` (Bukhārī 2441, Abū Dāwūd 1516, 4:110) · `al-kareem@1` (Bukhārī 1145, Bukhārī 4684, 27:40) · `al-haleem@1` (Bukhārī 7378, 19:90–91, 35:45) · `ar-raheem@1` (18:10/11/18, 33:43) | | ✖ **no shared citation.** See the insight check below for the one real adjacency. |

**Verified negative, run programmatically over the rebuilt inventory:** **21:87, 21:88, 2:186, Jami\` at-Tirmidhi 3505** appear in **no** shipped deck and **no** batch-1 draft. Complete shipped ḥadīth set: Bukhārī 2731, 3364, 3470, 3653, 4172, 4563, 4833, 5743, 5999, 6309, 7507 · Muslim 591, 2747a · Tirmidhī 2344 · Ibn Mājah 188. Complete shipped Qur'ān set: 1:6, 2:37, 2:286, 3:172–174, 7:156, 9:40, 11:90, 12:15/18/20/42/84/86/87/94/96/100, 13:28, 19:2–7, **21:83, 21:84**, 22:54, 26:80, 28:15/21/22/23, 35:2, 39:53, 42:19, 48:1, 55:1, 58:1, 59:23, 65:2/3, 67:13, 112:2.

**Insight-level check.** Beat 8 — *"He asked for nothing. He said who Allah is, and who he had been — and that was enough to be answered."*

| checked against | its insight | verdict |
|---|---|---|
| `ar-raheem@1` (batch 1) | *"That sentence was theirs first. They said it going in — and it was being answered the whole time…"* | ⚠️ **the closest adjacency in the batch, and the reason beat 8 was rewritten.** Both decks carry a duʿā that is the story's own words, so *"the words in your hand are the story's words"* is a move both could make. **`ar-raheem@1` keeps it; this deck gives it up** and lands instead on *what is absent from the sentence*. An earlier draft of beat 8 ended *"It is the one now in your hands"* — that was `ar-raheem@1`'s move verbatim in shape, and it was cut for that reason. **Disclosed rather than declared resolved:** if the founder reads the two takeaways together and still hears one idea, this deck's beat 8 is the thing to change, not the story. |
| `al-afuw@1` (batch 1) | *"Of every request available on the best night of the year, she was taught to ask for the erasing."* | ✖ **none, and it is a clean inversion.** That deck's move is *which request was chosen*; this deck's is *that no request was made at all*. |
| `ash-shafi@1` (shipped) | *"The answer to Ayyūb was not repair. It was more than there was before the breaking."* | ✖ none — that insight is about the **content** of the answer, this one about the **form of the asking**. |
| `at-tawwab@1`, `al-hadi@1`, `al-lateef@1`, `as-samad@1`, `al-fattah@1`, `al-wakeel@1` | mid-road acceptance · needing guidance is not falling behind · what you could not say was never unsaid · leaning is not weakness · gatekeepers cannot withhold · you were never asked to hold every outcome | ✖ none |

### Authoring notes (candidates considered)

- **Selected: Yūnus, 21:87–88, anchored on 2:186, with Tirmidhī 3505 as the narration warrant.** Three properties no other candidate had together: (a) the catalog duʿā **is** the story's sentence, word for word; (b) the Name's own root is the finite verb of Allah's action in two independent places; (c) the situation is the ICP's — enclosed, unable to act, having done something wrong, with nothing left to do but say one thing.
- **Rejected as the story — Qur'ān 37:139–148** (the same prophet, the casting of lots, `فَلَوْلَآ أَنَّهُۥ كَانَ مِنَ ٱلْمُسَبِّحِينَ`). It carries the same Name but the passage is a longer narrative with a lot-casting scene that cannot be compressed into three beats without inventing connective detail, and 37:139–148 does not contain the duʿā the user recites. 21:87–88 does.
- **Rejected as the verse anchor — Qur'ān 11:61** (`إِنَّ رَبِّى قَرِيبٌ مُّجِيبٌ`, the Name-noun in-text, and the catalog duʿā of id 45). **Fetched and read whole.** Rejected on **bar 5**: it is Ṣāliḥ's address to Thamūd, and the passage terminates in Thamūd's destruction (11:65–68). The Name in-text is not worth an arc that ends in a wiped-out nation, in a pack read at night.
- **Rejected as the verse anchor — Qur'ān 40:60** (`ٱدْعُونِىٓ أَسْتَجِبْ لَكُمْ`, the Name's root, imperative). **Rejected on bar 5:** the same āyah continues *"Indeed, those who disdain My worship will enter Hell [rendered] contemptible."* The threat is inside the āyah, not merely after it, so no excerpt is honest.
- **Rejected as the verse anchor — Qur'ān 42:26** (`وَيَسْتَجِيبُ ٱلَّذِينَ ءَامَنُوا۟`, the Name's root, Allah as subject). Fetched. Rejected because the āyah ends *"But the disbelievers will have a severe punishment"* — **and because it is the āyah immediately after `al-afuw@1`'s verse beat (42:25)**, whose own successor sweep already flagged it. 2:186 costs nothing and has neither problem.
- **Register check:** no beat attributes waiting, wanting or withholding to the Name. Beat 8 reports what the cited text contains and makes **no promise to the reader** — deliberately, which is why row 1.10's guarantee of response is verified but left off the screen.
