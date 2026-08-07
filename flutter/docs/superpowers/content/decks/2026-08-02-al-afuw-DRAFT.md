# Deck Draft — Al-Afuw (mercy/forgiveness pack, Wave G pilot 3 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

**Revision 3 — 2026-08-02. No content change: not one beat, source, citation or rejection note was altered.** Round 2 of the adversarial review returned a verdict of **sign** on this deck with nothing wrong. Four things are added, all of them labels and disclosures:
1. The batch-wide **126-translation correction** — and because this deck is the one that explicitly left 42:25 open pending a second readable rendering, **that row is now closed with the comparison run** (below).
2. **Beat 4's second clause is labelled as authored (A1).** *"and a thousand things a person could ask for on it"* is rhetoric in no source. It was unlabelled while the sibling `al-haleem@1` added a dedicated row for its authored copy — one batch, two standards.
3. **Two catalog-level flags now raised (A2, A3-adjacent):** catalog id 86's `hadith` field cites **Tirmidhī** for the wording this deck went out of its way to cite **Ibn Mājah** for; and "the best night of the year" is a gloss beyond 97:3.
4. The collision-table baseline and the ship-gate note, which described a version of the gate that no longer exists.

**Revision 2 — 2026-08-02. No content change: not one beat, source, citation or rejection note was altered** (founder ruling A5 — accepted). The only change is that **one verification claim is restated accurately.** Revision 1 recorded *"✅ verified programmatically — catalog `dua_arabic` == archived page Arabic, **exact string match including diacritics**."* That is stronger than the check supports: the match holds **after NFC normalisation** and fails on a raw byte comparison, because the archived page serves a different Unicode normalisation form. The words and the diacritics are the same. The ✅ is kept — but it now names the check that was actually run.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G. Author: Claude, 2026-08-02.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com` against the canonical `quran.com/{surah}/{ayah}` reference; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching). Scripture is quoted exactly from the fetched pages; story beats paraphrase only what the cited source carries.

**Translation standard for this deck (founder ruling A1 — most appropriate per Name, never at the cost of authenticity; Abdel Haleem is the named second option where Saheeh International reads stiffly):**
- **Qur'ān (97:3, 42:25): Saheeh International** (`resource_id: 20`), quoted verbatim, named per row below, with the **Abdel Haleem (`resource_id: 85`)** alternative fetched and compared per row. **The open question revision 2 left on 42:25 is now closed — see the correction box.**
- **Ḥadīth (Ibn Mājah 3850): the duʿā's Arabic and translation come from `collectible_names.json`, not from a translator** — the ship gate forces byte-identity with the catalog. The Arabic is verified against the cited page (row 3.5); the English is the catalog's own rendering.

### ⚠️ The 126-translation correction (batch-wide, BLOCKING before sign-off) — and it closes this deck's one open row

Revisions 1–2 of all five decks said: *"the API's English resource list returns **eight** translations and Khattab is not among them."*

**That is false.** `GET /api/v4/resources/translations?language=en` returns **126** entries (re-fetched and counted programmatically, 2026-08-02).

What is true, and what the conclusion actually rested on: **Khattab (`resource_id: 131`) is genuinely absent from that list**, and `/quran/translations/131?verse_key=…` genuinely returns `{"translations":[]}` while `…/20` returns text. Both reproduced 2026-08-02. So Khattab still cannot be quoted and the fetch-first rule still forbids quoting it from memory — but the reason given was wrong, and it foreclosed live options, chiefly **M.A.S. Abdel Haleem (`resource_id: 85`)**.

**This deck is where the false premise cost the most, by its own admission.** Revision 2 wrote: *"**42:25 is the one row in this batch where Khattab would most be worth re-reading** if the endpoint returns — the verse-anchor choice below was made on readability grounds against a different Saheeh International verse, so a second readable rendering could reopen it."* **A second readable rendering was reachable the whole time. It has now been fetched, and the row is closed rather than left open:**

| | 42:25 |
|---|---|
| Saheeh International (`20`) — **used** | "And it is He who accepts repentance from His servants and pardons misdeeds, and He knows what you do." |
| Abdel Haleem (`85`) — fetched, **not used** | "it is He who accepts repentance from His servants and pardons bad deeds**-** He knows everything you do." |

**The comparison the deck said it could not run, run:** Abdel Haleem's rendering **opens lower-case mid-sentence** (42:25 continues 42:24 in his layout) and would have to be capitalised to start a beat — an edit to a quotation, which this batch does not do — and it uses a **hyphen as a dash** (`deeds- He`), the exact typographic defect `al-kareem@1` had to disclose a normalisation for on 27:40. Saheeh International's rendering is a complete, self-contained sentence and reads in one breath. **It wins on readability, not only on availability, and the verse-anchor choice against 4:149 stands unchanged and now on a tested basis.**

97:3 was also re-run: Abdel Haleem is *"The Night of Glory is better than a thousand months;"* — Saheeh International's *"Night of Decree"* is the closer gloss on `الْقَدْر` and matches beat 3's "Laylat al-Qadr". Saheeh International kept.

The batch-wide reason the same answer came back on every row of all five decks: **Abdel Haleem renders the divine name as "God", not "Allāh", and lower-cases the Names** where Saheeh International capitalises them. Against 14 shipped decks that all say "Allah", adopting it would break the app's core vocabulary mid-pack. So it is **compared and named per row, adopted nowhere.**

**The discontinuity that remains, stated plainly:** the 14 shipped decks lean **Khattab** in register — `al-wakeel@1` (`˹alone˺`), `at-tawwab@1` (`˹of prayer˺`), `as-samad@1` (`˹needed by all˺`), and `ash-shafi@1`'s sources array literally pins *"Khattab rendering"*. These five ship in Saheeh International. `ar-rahman@1`'s founder-decided Saheeh International comfort verse is the precedent that mixing is permitted, so this is defensible — but it is a real register mix and the founder is signing it, now on a true premise rather than a false one.

**Implementation note (binding):** every beat stores Arabic / transliteration / translation as **separate fields**. The em-dash formatting below is markdown shorthand only, never a single mixed-direction `Text`.

---

## Deck `al-afuw@1` — Al-Afuw

**Proposed metadata**

```json
{
  "deck_id": "al-afuw@1",
  "name_id": 86,
  "transliteration": "Al-Afuw",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You can be told you are forgiven and still feel the thing sitting there. There is a Name for wanting it gone, not just excused.

**Beat 2 · name_intro** *(from `collectible_names.json` id 86, verbatim)*:
> الْعَفُوُّ — Al-Afuw — The Pardoner

**Beats 3–5 · story — what ʿĀʾisha was told to ask for:**
> 1. ʿĀʾisha asked the Prophet ﷺ: if I come upon Laylat al-Qadr, what should I say?
> 2. One night the Qur'ān calls better than a thousand months — and a thousand things a person could ask for on it.
> 3. He taught her one sentence, and what it asks for is to be pardoned. Not relief. Not provision. Pardon.

**Beat 6 · verse:**
> "And it is He who accepts repentance from His servants and pardons misdeeds, and He knows what you do." — Qur'ān 42:25

**Beat 7 · duʿā** *(catalog id 86, verbatim in full — the sentence from the story, in the wording of Sunan Ibn Mājah 3850)*:
> اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي
> *Allahumma innaka 'afuwwun tuhibbul-'afwa fa'fu 'anni*
> "O Allah, You are the Pardoner, You love to pardon, so pardon me."
>
> *(proposed `source` field on this beat: `Sunan Ibn Majah 3850`)*

**Beat 8 · takeaway:**
> Of every request available on the best night of the year, she was taught to ask for the erasing. It is still the sentence.

### Sources

| Claim | Source (URL) | Grading | Status |
|---|---|---|---|
| Beat 3: ʿĀʾisha's question about what to say if she comes upon Laylat al-Qadr | [Sunan Ibn Majah 3850](https://sunnah.com/ibnmajah:3850) | **ṣaḥīḥ** (Darussalam grade shown on the page) | ✅ verified via Wayback archive of the exact URL, fetched 2026-08-02 |
| Same, corroborating narration | [Jami' at-Tirmidhi 3513](https://sunnah.com/tirmidhi:3513) | **ḥasan ṣaḥīḥ** (Tirmidhī's own words on the page: `هذا حديث حسن صحيح`); Darussalam grade line: **ṣaḥīḥ** | ✅ verified via Wayback archive of the exact URL, fetched 2026-08-02 |
| Beat 4, first clause, verbatim: "The Night of Decree is better than a thousand months." | [Qur'ān 97:3](https://quran.com/97/3) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/97:3?translations=20,85`, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched Saheeh International string. Abdel Haleem fetched and compared (*"The Night of Glory…"*); Saheeh International's "Night of Decree" kept as the closer gloss on `الْقَدْر` and the one that matches beat 3's "Laylat al-Qadr". |
| **Beat 4, second clause: "and a thousand things a person could ask for on it"** | authored — no URL | n/a | ✅ **honest label — this is authored rhetoric, not a source claim, and this row is new in revision 3 (A1).** No source says it. It is a rhetorical mirror of 97:3's "thousand months" and it exists to set up beat 5's *"He taught her one sentence."* It asserts nothing about the night that the Qur'ān does not, and nothing about the narration. **It was previously unlabelled**, while the sibling `al-haleem@1` added a dedicated row (4.6) for exactly this kind of copy — and an unsourced clause in a story beat is the defect class that got a deck rejected in round 1 ("the line broke" is not in 3:152). Labelled now so the batch applies one standard. |
| Beat 5: the taught supplication asks for pardon | [Sunan Ibn Majah 3850](https://sunnah.com/ibnmajah:3850) | ṣaḥīḥ | ✅ verified — beat states only what the narration contains; no invented dialogue |
| Verse anchor, verbatim: "And it is He who accepts repentance from His servants and pardons misdeeds, and He knows what you do." | [Qur'ān 42:25](https://quran.com/42/25) | Qur'ān | ✅ **verified** — live fetch `?translations=20,85`, Saheeh International, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched string; no footnote marker present. **Abdel Haleem fetched and compared this revision and the row is closed** — see the correction box above; his rendering opens lower-case mid-sentence and uses a hyphen for a dash, so Saheeh International wins on readability as well as availability. |
| Beat 2 `name_intro`, and the duʿā's transliteration and translation fields | catalog id 86 | catalog only | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english` and `dua_transliteration` / `dua_translation`, re-checked programmatically 2026-08-02; the ship gate enforces both independently. (The `dua_arabic` field has its own row below.) |
| Duʿā text (catalog id 86) is the Arabic of Ibn Mājah 3850 — **identical in words and diacritics; identical as a string after Unicode NFC normalisation, not as raw bytes** | [Sunan Ibn Majah 3850](https://sunnah.com/ibnmajah:3850) | ṣaḥīḥ | ✅ **verified programmatically, 2026-08-02 — and this is the corrected row.** Wayback capture `20260304165817` of the exact URL; page reference line *"Sunan Ibn Majah 3850"*, grade cell `Grade : Sahih (Darussalam)`, page Arabic `…تَقُولِينَ اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي`. Substring test of catalog id 86 `dua_arabic` against it: **raw → False**, **NFC → True**, **NFC + format-character strip → True**. Every letter and every diacritic is the same; the archived page serves a different normalisation form, which a byte comparison sees and a reader does not. Revision 1's *"exact string match including diacritics"* overstated a check that passes only under normalisation, and the row now says which check was run. |

**Narration-variant note (deliberate, and the reason the citation is Ibn Mājah and not Tirmidhī):** Tirmidhī 3513 carries `اللَّهُمَّ إِنَّكَ عَفُوٌّ **كَرِيمٌ** تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي` — with *Karīm*. Ibn Mājah 3850 carries the shorter wording **without** *Karīm*, which is exactly the catalog's text. The deck therefore cites Ibn Mājah, so the citation matches the words on the screen character-for-character. Citing Tirmidhī here would have been a quiet mismatch.

### ⚠️ Two catalog-level flags the founder should see (neither fixable by a deck) — new in revision 3

1. **The catalog contradicts this deck's headline citation argument (A2).** The whole reason this deck cites **Ibn Mājah 3850** rather than Tirmidhī 3513 is that the catalog's wording is Ibn Mājah's (no `كَرِيمٌ`), so *"citing Tirmidhī here would have been a quiet mismatch"* — see the narration-variant note above. **But catalog id 86's own `hadith` field cites Tirmidhī for that same wording:**

   > *"Aisha (RA) asked: 'If I find Laylat al-Qadr, what should I say?' The Prophet ﷺ taught: 'Allahumma innaka Afuwwun tuhibbul afwa fa'fu anni.' **(Tirmidhi)**"*

   So the Name card the user also meets makes precisely the mismatch the deck went out of its way to avoid — it attributes the `كَرِيمٌ`-less wording to the collection whose wording carries `كَرِيمٌ`. **Founder decision: does the id 86 `hadith` attribution change to Ibn Mājah?** It costs one word in the catalog and it makes the app internally consistent on the deck's own central argument. Same class of flag `al-ghafur@1`, `al-kareem@1` and `ar-raheem@1` raise for their Names; this one goes to this deck's headline reasoning and was not raised in revisions 1–2.

2. **"the best night of the year" (beat 8) is a gloss beyond the cited verse (A3).** 97:3 says *"better than a thousand months"*, which is what row 3 verifies. *"The best night of the year"* is the standard and uncontroversial understanding, and no source in this deck states it. It is not a scripture claim inside quotation marks and it is not doing theological work — beat 8's argument is *what she was told to ask for*, and it would survive the phrase being cut to *"Of every request available on that night"*. **Recorded as a founder call rather than changed, because this deck's content was accepted (ruling A5) and revision 3 changes no beat.**

### Ship-gate note — **this deck's duʿā citation MUST be pinned at transcription time**

`renderedDuaSources` in `test/content/name_stories_ship_gate_test.dart` is now asserted **in both directions** (commit `a12f1db`): a pinned deck that drops its `source` fails the gate, **and an unpinned deck that carries a `source` also fails.** Revisions 1–2 described it as a one-way whitelist; that is out of date, and it means the beat and the map must change together or the gate goes red.

If this deck is signed, add at transcription time — **this exact string, in `test/content/name_stories_ship_gate_test.dart`**:

```dart
'al-afuw@1': 'Sunan Ibn Majah 3850',
```

and the duʿā beat's `source` field must read exactly `Sunan Ibn Majah 3850`. *(This document does not edit the test or `name_stories.json`; it states the pin so transcription is mechanical.)*

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 14 shipped decks

Run as a full inventory sweep before the batch, per the process rule the pilot earned (the original pass checked `ar-rahman@1` and missed `ash-shafi@1`, which cost a whole deck).

**Baseline correction (revision 3).** Previous revisions' collision tables understated the shipped decks — they listed one or two sources per deck when the shipped `sources` arrays and beat `source` fields carry more. The table below is rebuilt from `assets/content/name_stories.json` itself (every `sources[].url` plus every beat `source`), 2026-08-02. Additions the earlier tables did not show are marked **(+)**.

| shipped deck | its narrative | its full inventory | collides? |
|---|---|---|---|
| `al-ghaffar@1` · `at-tawwab@1` | the servant who kept returning · the hundred lives | Bukhārī 7507; 39:53 · Bukhārī 3470; 2:37 | ✖ none — different narrations, different verses, and different engines (repetition, and acceptance-of-return, vs. erasure) |
| `ar-rahman@1` · `ash-shafi@1` · `al-baseer@1` · `al-wadud@1` · `al-fattah@1` · `as-salam@1` · `ar-razzaq@1` | Bukhārī 5999; 2:286, 7:156, **55:1 (+)** · Bukhārī 5743 (cf.); 21:83–84, 26:80 · Bukhārī 3364; 58:1, **Ibn Mājah 188 (+)** · Muslim 2747a, Bukhārī 6309; 11:90 · Bukhārī 4172, 4833, **2731 (+)**; 48:1, 35:2 · Muslim 591, **Bukhārī 3653 (+)**; 13:28, **9:40 (+)**, **59:23 (+)** · Tirmidhī 2344; 65:2, 65:3 | | ✖ none — no shared narration number |
| `al-wakeel@1` · `al-hadi@1` · `al-jabbar@1` · `al-lateef@1` · `as-samad@1` | 3:172–174, 65:3, **Bukhārī 4563 (+)** · 28:22, **28:15/21/23 (+)**, 22:54, **1:6 (+)** · 12:84, 12:86, 12:87, **12:18/12:94 (+)** · 12:100, **12:15/12:20/12:42 (+)**, 42:19, 67:13 · 19:2–7, 112:2 | | ✖ none |
| **sibling drafts in this batch** | `al-ghafur@1` (Bukhārī 2441, Abū Dāwūd 1516, 4:110) · `al-kareem@1` (Bukhārī 1145, Bukhārī 4684, 27:40) · `al-haleem@1` (**re-sourced again in revision 3** — Bukhārī 7378, 19:90–91, 35:45) · `ar-raheem@1` (18:10, 18:11, 18:18, 33:43) | | ✖ none. **Note the batch-level fix this confirms, now twice over:** `al-haleem@1` revision 1 built its climax on `عَفَا` (3:152, 3:155) — the root of *this* deck's Name — and was rejected for it. Revision 2 removed the `ʿ-f-w` root but left `غَفُورًا` (Al-Ghafūr, a sibling) on its verse beat. **Revision 3 of that deck contains no form of `ʿ-f-w` and no form of `gh-f-r` anywhere**, so the overlap with this deck is gone by construction rather than by inspection. |

**Verified negative, run against the rebuilt inventory above:** no shipped deck and no sibling draft uses **Ibn Mājah 3850, Tirmidhī 3513, 97:3 or 42:25**. The complete shipped ḥadīth set is Bukhārī 3653, 4563, 6309, 7507, 3470, 5743, 2731, 4172, 4833, 5999, 3364 · Muslim 591, 2747a · Tirmidhī 2344 · Ibn Mājah 188 — neither Ibn Mājah 3850 nor Tirmidhī 3513 is in it. Complete shipped Qur'ān inventory: 1:6, 2:37, 2:286, 3:172–174, 7:156, 9:40, 11:90, 12:15/18/20/42/84/86/87/94/96/100, 13:28, 19:2/3/4/7, 21:83/84, 22:54, 26:80, 28:15/21/22/23, 35:2, 39:53, 42:19, 48:1, 55:1, 58:1, 59:23, 65:2/3, 67:13, 112:2 — neither 97:3 nor 42:25 is in it.

**Insight-level check (the axis the collision tables previously missed).** Beat 8 — *"Of every request available on the best night of the year, she was taught to ask for the erasing. It is still the sentence."* — checked against the shipped closing insights, in particular `al-lateef@1` (wordlessness), `al-ghaffar@1` (repetition), `at-tawwab@1` (acceptance of return) and `ar-rahman@1`. **✖ none.** This deck's closing move is *what was chosen to be asked for*, which no shipped deck uses. (Two real insight collisions were found on this axis elsewhere in the batch — `ar-raheem@1` R1 and `al-ghafur@1` G4, both against `al-lateef@1` — so the axis is not vacuous.)

### Craft note carried forward from the adversarial review (not a defect, and not fixed)

Two observations were raised and are recorded rather than acted on, because acting on either would change accepted content:

- **Beat thinness, and an internal standard that has now been reconciled.** This deck builds three beats out of a narration that is one question and one answer, and fills the middle beat with a Qur'ānic fact (97:3) rather than narrative. Revisions 1–2 noted that the sibling `al-haleem@1` *rejected* Bukhārī 7378 as its story on the grounds that "three beats out of one sentence would require inventing scene", and that the two decks were therefore held to different bars. **In revision 3 `al-haleem@1` selects Bukhārī 7378 after all** — split across two beats with a Qur'ānic passage supplying the third, which is structurally the same move this deck makes. **The standards now match**, and that deck says so. Nothing here invents scene, and nothing there does either.
- **The taught sentence is withheld until beat 7.** Beat 5 tells the user *about* a sentence it will not show them for two more taps. That is deliberate — the payoff is that the duʿā screen turns out to be the story's own words — but it is a real cost at reveal-beat speed.

### Authoring notes (candidates considered)

- **Selected: the Laylat al-Qadr duʿā (Ibn Mājah 3850 / Tirmidhī 3513).** Highest possible Name-correlation: the Name is *in* the narration, spoken by the Prophet ﷺ, and the words are the catalog duʿā the user says at beat 7. The story explains where the sentence in their hands came from — which is what makes a deck feel authored rather than assembled.
- **Rejected — Abū Bakr and Misṭaḥ, [Qur'ān 24:22](https://quran.com/24/22) (verse verified via live fetch, 2026-08-02).** "…and let them pardon and overlook. Would you not like that Allāh should forgive you?" A superb story, but its subject is *human* pardon of another human, and the divine Name it closes on is Ghafūr Raḥīm, not ʿAfuww. It teaches a duty; this deck's user needs to receive, not to perform. Also, the full narration (the ifk) is long and carries a slander plot that cannot be compressed into three beats safely.
- **Rejected — Ṭāʾif and the angel of the mountains ([Sahih al-Bukhari 3231](https://sunnah.com/bukhari:3231), ṣaḥīḥ, verified via archive 2026-08-02).** Enormously moving, but the restraint the narration records is the Prophet's ﷺ own choice. Using it for a Name **of Allah** would make the Name's engine a human decision — the reverence line the format spec draws.
- **Verse anchor: 42:25 chosen over [Qur'ān 4:149](https://quran.com/4/149) (also verified, 2026-08-02).** 4:149 has the Name in noun form (*ʿAfuwwan Qadīrā*) and would score higher on the protocol's "Name in-text" preference, but the Saheeh International rendering is "ever Pardoning and Competent", and "Competent" is a dead word to a 20-something reading one beat in one breath. 42:25 keeps the pardoning verb, reads in one breath, and needs no gloss. **Flagging this as a judgement call rather than a rule application.**
- Register check: beat 8 says what the narration asked for, not what the Name will do.
