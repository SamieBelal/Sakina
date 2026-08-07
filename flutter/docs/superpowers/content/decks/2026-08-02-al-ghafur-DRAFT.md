# Deck Draft — Al-Ghafur (mercy/forgiveness pack, Wave G pilot 2 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

**Revision 2 — 2026-08-02.** Story selection **accepted and unchanged** (founder ruling A5). Three corrections:
1. **The duʿā's ⚠️ flag was factually wrong and is removed.** Revision 1 told the founder catalog id 51's duʿā was "one word away from a narrated supplication", claimed **no** provenance for it, and asked for a content-migration decision. **It is the Abū Dāwūd route, narrated, and ṣaḥīḥ.** The deck now *carries* the citation it wrongly said it could not have. The correct action was the opposite of the one proposed.
2. **"in the street" is dropped** — it is not in Bukhārī 2441.
3. Two catalog-level flags the adversarial review surfaced are now disclosed for the founder (near-duplicate against a **shipped** deck; and the catalog contradicting the deck's own Ghafūr/ʿAfuww distinction). Neither is fixable by a deck.

**Revision 3 — 2026-08-02. Story selection still unchanged; five corrections, two of which touch beats:**
1. **The quoted narration is re-rendered from the cited Arabic (G2 — beats 4 and 5 change).** The published English prints *"Did you commit such-and-such sins?"* **once**. The archived Arabic is `أَتَعْرِفُ ذَنْبَ كَذَا أَتَعْرِفُ ذَنْبَ كَذَا` — *"Do you know such-and-such a sin?"* — asked **twice**. Commission is not acknowledgement, and the repetition is the narration's own hinge. Revision 2 saw the difference (its own proposed alternative already had it right) and left the defective string in the beat. See the clause table below.
2. **The founder's URL check on `Sunan Abi Dawud 1516` will not match, and the deck now says so (G1).** The page's published **English** renders the ending as *"Thou art the Pardoning and forgiving One"*, not *"At-Tawwab, Ar-Rahim"*. The deck verified the page's **Arabic**, correctly, and never mentioned that the English diverges — so anyone following the format spec's *"open each URL"* step would have read a true citation as a failure.
3. **"verbatim" in catalog flag ② was factually wrong (G3)** and is corrected. The substance of that flag was right and is unchanged.
4. **Beat 1 and beat 8 are rewritten (G4).** Both echoed the corresponding beats of the shipped, founder-signed `al-lateef@1` in near-identical syntax while the collision table said ✖ none. Resolved rather than disclosed.
5. The batch-wide **126-translation correction** (below), and the collision-table baseline.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G. Author: Claude, 2026-08-02.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com` against the canonical `quran.com/{surah}/{ayah}` reference; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching).

**Translation standard for this deck (founder ruling A1 — most appropriate per Name, never at the cost of authenticity; Abdel Haleem is the named second option where Saheeh International reads stiffly):**
- **Qur'ān (4:110): Saheeh International** (`resource_id: 20`), quoted verbatim. **Abdel Haleem (`resource_id: 85`) fetched and compared for this row and not used** — see the correction box below.
- **Ḥadīth (Bukhārī 2441): the app's own rendering, made from the Arabic on the cited page** — changed in revision 3. Revisions 1–2 used sunnah.com's published English. That English states something the Arabic does not (*"Did you commit"* for `أَتَعْرِفُ`) and collapses a doubled question into one. Full clause table below.

### ⚠️ The 126-translation correction (batch-wide, BLOCKING before sign-off)

Revisions 1–2 of all five decks said: *"the API's English resource list returns **eight** translations and Khattab is not among them."*

**That is false.** `GET /api/v4/resources/translations?language=en` returns **126** entries (re-fetched and counted programmatically, 2026-08-02).

What is true, and what the conclusion actually rested on: **Khattab (`resource_id: 131`) is genuinely absent from that list**, and `/quran/translations/131?verse_key=…` genuinely returns `{"translations":[]}` while `…/20` returns text. Both reproduced 2026-08-02. So Khattab still cannot be quoted and the fetch-first rule still forbids quoting it from memory — but the reason given was wrong, and it foreclosed live options, chiefly **M.A.S. Abdel Haleem (`resource_id: 85`)**.

**What re-running the choice against the real list changed for 4:110 — nothing, and here is the fetched evidence:**

| | text |
|---|---|
| Saheeh International (`20`) — **used** | "And whoever does a wrong or wrongs himself but then seeks forgiveness of Allāh will find **Allāh Forgiving and Merciful**." |
| Abdel Haleem (`85`) — fetched, not used | "Yet anyone who does evil or wrongs his own soul and then asks **God** for forgiveness will find Him **most forgiving and merciful**." |

Two defects for this deck specifically: it says **"God"**, and it lower-cases the Name. This verse beat exists to put `غَفُورًا رَّحِيمًا` on the page **as a Name**; Abdel Haleem deletes it visually. Saheeh International kept.

The batch-wide reason the same answer came back on every row of all five decks: **Abdel Haleem renders the divine name as "God", not "Allāh", and lower-cases the Names** where Saheeh International capitalises them. Against 14 shipped decks that all say "Allah", adopting it would break the app's core vocabulary mid-pack. So it is **compared and named per row, adopted nowhere.**

**The discontinuity that remains, stated plainly:** the 14 shipped decks lean **Khattab** in register — `al-wakeel@1` (`˹alone˺`), `at-tawwab@1` (`˹of prayer˺`), `as-samad@1` (`˹needed by all˺`), and `ash-shafi@1`'s sources array literally pins *"Khattab rendering"*. These five ship in Saheeh International. `ar-rahman@1`'s founder-decided Saheeh International comfort verse is the precedent that mixing is permitted, so this is defensible — but it is a real register mix and the founder is signing it, now on a true premise rather than a false one.

**Implementation note (binding):** every beat stores Arabic / transliteration / translation as **separate fields**. The em-dash formatting below is markdown shorthand only, never a single mixed-direction `Text`.

---

## Deck `al-ghafur@1` — Al-Ghafur

**Proposed metadata**

```json
{
  "deck_id": "al-ghafur@1",
  "name_id": 51,
  "transliteration": "Al-Ghafur",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge** *(rewritten in revision 3 — see G4)*:
> The fear underneath guilt is usually not the punishment. It is being found out.

**Beat 2 · name_intro** *(from `collectible_names.json` id 51, verbatim)*:
> الْغَفُورُ — Al-Ghafur — The Forgiving

**Beats 3–5 · story — the private conversation (an-najwā):**
> 1. A man came in front of Ibn ʿUmar as he walked and asked him what he had heard the Prophet ﷺ say about *an-najwā* — the private conversation on the Day of Judgement.
> 2. He said: **"Allah will bring the believer near, and place His covering over him, and screen him, and say: Do you know such-and-such a sin? Do you know such-and-such a sin? He will say: Yes, my Lord."** He is asked until he has acknowledged all of them and sees within himself that he is ruined.
> 3. Then: **"I screened them for you in the world, and today I forgive them for you."** — and he is given the book of his good deeds.

**Beat 6 · verse** *(the Name appears in the verse itself)*:
> "And whoever does a wrong or wrongs himself but then seeks forgiveness of Allāh will find Allāh Forgiving and Merciful." — Qur'ān 4:110

**Beat 7 · duʿā** *(catalog id 51, verbatim in full — these are the words Ibn ʿUmar counted the Prophet ﷺ saying a hundred times in a single sitting)*:
> رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ
> *Rabbighfir li wa tub 'alayya innaka anta't-Tawwabu'r-Rahim*
> "My Lord, forgive me and accept my repentance. Indeed, You are At-Tawwab, Ar-Rahim."
>
> *(proposed `source` field on this beat: `Sunan Abi Dawud 1516`)*

**Beat 8 · takeaway** *(rewritten in revision 3 — see G4)*:
> Al-Ghafur is not only the forgiving — it is the covering. In that account every sin is named once, in private, to the One who already knew, and no one else is ever told.

### ⚠️ The quoted narration is the app's own rendering, from the cited Arabic (new in revision 3). Here is exactly why.

**The Arabic on the archived page** (`https://sunnah.com/bukhari:2441`, Wayback capture `20260215224255`, read off the page's `arabic_text_details` block, 2026-08-02):

> إِنَّ اللَّهَ يُدْنِي الْمُؤْمِنَ فَيَضَعُ عَلَيْهِ كَنَفَهُ، وَيَسْتُرُهُ فَيَقُولُ أَتَعْرِفُ ذَنْبَ كَذَا أَتَعْرِفُ ذَنْبَ كَذَا فَيَقُولُ نَعَمْ أَىْ رَبِّ‏.‏ حَتَّى إِذَا قَرَّرَهُ بِذُنُوبِهِ وَرَأَى فِي نَفْسِهِ أَنَّهُ هَلَكَ قَالَ سَتَرْتُهَا عَلَيْكَ فِي الدُّنْيَا، وَأَنَا أَغْفِرُهَا لَكَ الْيَوْمَ‏.‏ فَيُعْطَى كِتَابَ حَسَنَاتِهِ

**The published English on the same page**, which revisions 1–2 quoted: *"Allah will bring a believer near Him and shelter him with His Screen and ask him: Did you commit such-and-such sins? He will say: Yes, my Lord. Allah will keep on asking him till he will confess all his sins and will think that he is ruined. Allah will say: 'I did screen your sins in the world and I forgive them for you today', and then he will be given the book of his good deeds."*

**Two defects in that string, both concrete:**

1. **"Did you commit" is not what `أَتَعْرِفُ` says.** `ʿarafa` is to know / recognise; the question asks whether the man **acknowledges** the sin, and the narration's own next clause confirms it — `حَتَّى إِذَا قَرَّرَهُ بِذُنُوبِهِ`, "until He brought him to **acknowledge** (`iqrār`) his sins". Commission is assumed by the scene; **acknowledgement is what is being staged**, and it is the hinge the whole narration turns on. The published English converts an admission scene into an interrogation about the facts.
2. **The question is asked twice and the published English prints it once.** `أَتَعْرِفُ ذَنْبَ كَذَا أَتَعْرِفُ ذَنْبَ كَذَا` — the doubling is in the text, it is what "Allah will keep on asking him" is *summarising*, and at reveal-beat speed the repetition is the beat.

**The rendering used, clause by clause,** so the founder can check it against the Arabic above without knowing Arabic:

| Arabic | rendered as | note |
|---|---|---|
| `إِنَّ اللَّهَ يُدْنِي الْمُؤْمِنَ` | "Allah will bring the believer near" | `yudnī` = to bring near. **"to Him" removed** — it is not in the Arabic (the published English adds it) |
| `فَيَضَعُ عَلَيْهِ كَنَفَهُ` | "and place His covering over him" | `kanaf` = side / shelter / covering. Left as the text has it, un-capitalised and un-glossed |
| `وَيَسْتُرُهُ` | "and screen him" | `satr` — kept as its own clause; the published English folds `kanaf` and `satr` together into one capitalised "His Screen" |
| `فَيَقُولُ` | "and say:" | |
| `أَتَعْرِفُ ذَنْبَ كَذَا أَتَعْرِفُ ذَنْبَ كَذَا` | "Do you know such-and-such a sin? Do you know such-and-such a sin?" | **the correction: acknowledgement, not commission, and asked twice as the text has it** |
| `فَيَقُولُ نَعَمْ أَىْ رَبِّ` | "He will say: Yes, my Lord." | |
| `حَتَّى إِذَا قَرَّرَهُ بِذُنُوبِهِ وَرَأَى فِي نَفْسِهِ أَنَّهُ هَلَكَ` | *(paraphrased outside the quotation marks, in beat 4's closing sentence)* | marked as paraphrase, not quoted |
| `قَالَ سَتَرْتُهَا عَلَيْكَ فِي الدُّنْيَا، وَأَنَا أَغْفِرُهَا لَكَ الْيَوْمَ` | "I screened them for you in the world, and today I forgive them for you." | `سَتَرْتُهَا` carries the pronoun; **"your sins" removed** — the published English supplies a noun the Arabic leaves as `-hā` |
| `فَيُعْطَى كِتَابَ حَسَنَاتِهِ` | "and he is given the book of his good deeds" | outside the quotation marks in beat 5 |

**No content is added and none is dropped. Clause order is preserved (word order cannot be — Arabic is VSO). No contested reading is resolved in either direction, and `kanaf` is left as a plain covering rather than capitalised into an entity.**

**The one-standard rule this and `al-kareem@1` now share.** `al-kareem@1` re-renders Bukhārī 1145 because its published English *resolves a contested attribute*. This deck re-renders Bukhārī 2441 because its published English *states something the Arabic does not*. Stated as one rule for the batch: **paste the published English by default; re-render from the Arabic only where the published English (a) resolves a contested reading or (b) says something the source does not — and show the clause table when you do.** Under that rule `al-haleem@1` revision 3 correctly does **not** re-render Bukhārī 7378, whose English is merely clunky.

**⚠️ On-screen attribution — the same founder decision `al-kareem@1` raises (K3), and it should be answered once for the batch.** The `source` field will render **"Sahih al-Bukhari 2441"**, and anyone who opens that URL now finds different English under the same reference. Either put the signal on the beat (`source: "rendered from the Arabic of Sahih al-Bukhari 2441"`) or record a founder decision that no signal is shown. **Recommended: put it on the beat, in both decks.**

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 2.1 | Whole story, beats 3–5: the question about *an-najwā*, the covering, the doubled question, the acknowledgement, "I screened them for you in the world, and today I forgive them for you", the book of good deeds | **the app's own rendering, made from the Arabic on the cited page** — changed in revision 3. Full clause-by-clause justification in the box above. Reason, in one line: the published English says *"Did you commit"* where `أَتَعْرِفُ` says *"Do you know"*, and prints once a question the Arabic asks twice. | [Sahih al-Bukhari 2441](https://sunnah.com/bukhari:2441) | **ṣaḥīḥ** — Ṣaḥīḥ al-Bukhārī (the collection's own condition; sunnah.com prints no separate grade line for the two Ṣaḥīḥs, which is the site's convention and was re-confirmed on this page) | ✅ **verified** via Wayback capture `20260215224255` of the exact URL, 2026-08-02 — English **and** Arabic both read off the archived page and both reproduced in the box above. Reference line: *"Sahih al-Bukhari 2441"*. Narrator **Ṣafwān b. Muḥriz al-Māzinī**, reporting from **Ibn ʿUmar**; isnād on the page: Mūsā b. Ismāʿīl ← Hammām ← Qatāda ← Ṣafwān. ⚠️ **This row is deliberately not a "quoted verbatim from a published translation" ✅** — it is a different and weaker claim, and it is stated as such: *the Arabic is verified; the English is ours*. The doubled `أَتَعْرِفُ ذَنْبَ كَذَا أَتَعْرِفُ ذَنْبَ كَذَا` was read off the page directly and is reproduced above. |
| 2.2 | Beat 3's staging: "came in front of Ibn ʿUmar **as he walked**" | paraphrase of the archived page's English framing (not quoted on screen) | [Sahih al-Bukhari 2441](https://sunnah.com/bukhari:2441) | ṣaḥīḥ | ✅ **verified, and this is the corrected row.** The archived page reads: *"While I was walking with Ibn ʿUmar holding his hand, a man came in front of us and asked…"* Revision 1 said **"in the street"**, which the source does not contain — dropped. The beat now says only what the narration carries: he was walking, and a man came in front. |
| 2.3 | Deliberate omission: the narration continues about disbelievers and hypocrites being exposed publicly, and closes on a curse | published English (omitted material, quoted nowhere on screen) | [Sahih al-Bukhari 2441](https://sunnah.com/bukhari:2441) | ṣaḥīḥ | ✅ **verified** — the omitted tail on the archived page is *"Regarding infidels and hypocrites (their evil acts will be exposed publicly) and the witnesses will say: These are the people who lied against their Lord. Behold! The Curse of Allah is upon the wrongdoers."* Omitted for register; the beats are marked as an excerpt, not as the full narration. **Note it is also the narration's own contrast** — public exposure there, private covering here — which is what beat 8's *"no one else is ever told"* is reporting. |
| 2.4 | Beat 6, verse anchor, verbatim: "And whoever does a wrong or wrongs himself but then seeks forgiveness of Allāh will find Allāh Forgiving and Merciful." | **Saheeh International.** Abdel Haleem (85) fetched and compared — *"…then asks **God** for forgiveness will find Him **most forgiving and merciful**"* — rejected because it says "God" and lower-cases the Name this beat exists to show. | [Qur'ān 4:110](https://quran.com/4/110) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/4:110?translations=20,85`, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched Saheeh International string; the fetched string carries no footnote marker, so nothing was stripped. Arabic `غَفُورًا رَّحِيمًا` — **the Name in-text**. |
| 2.5 | **Duʿā beat carries `source: Sunan Abi Dawud 1516`** | catalog id 51 translation, which the ship gate forces byte-for-byte | [Sunan Abi Dawud 1516](https://sunnah.com/abudawud:1516) | **ṣaḥīḥ (al-Albānī)** — the grade line printed on the archived page: `Grade : Sahih (Al-Albani)  صحيح (الألباني)` | ✅ **verified by this author, by fetch, 2026-08-02** — Wayback capture `20260607195027` of the exact URL. Reference line: *"Sunan Abi Dawud 1516"*. Isnād on the page: al-Ḥasan b. ʿAlī ← Abū Usāma ← Mālik b. Mighwal ← Muḥammad b. Sūqa ← **Nāfiʿ** ← **Ibn ʿUmar**. Arabic on the page: `إِنْ كُنَّا لَنَعُدُّ لِرَسُولِ اللَّهِ ﷺ فِي الْمَجْلِسِ الْوَاحِدِ مِائَةَ مَرَّةٍ "رَبِّ اغْفِرْ لِي وَتُبْ عَلَىَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ"`. **Token comparison against catalog id 51, re-run 2026-08-02:** see the box below — 8 of 9 tokens byte-identical after NFC, 1 orthographic variant; whole-string substring test **False raw and False after NFC**, and the deck does not claim otherwise. ⚠️ **Read the English-mismatch disclosure immediately below before opening this URL.** |
| 2.6 | The *other* route, named in revision 1's flag and now verified rather than repeated second-hand | — | [Jami' at-Tirmidhi 3434](https://sunnah.com/tirmidhi:3434) | **ṣaḥīḥ (Darussalam)**, and Tirmidhī's own words in the Arabic on the page: `هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ غَرِيبٌ` | ✅ **verified by this author, by fetch, 2026-08-02** — Wayback capture `20260125085148` of the exact URL (**a capture does exist**; an earlier pass reported none). Reference line: *"Jami` at-Tirmidhi 3434"*. Isnād: Naṣr b. ʿAbd al-Raḥmān al-Kūfī ← al-Muḥāribī ← Mālik b. Mighwal ← Muḥammad b. Sūqa ← **Nāfiʿ** ← **Ibn ʿUmar**. Ends `التَّوَّابُ **الْغَفُورُ**` — which is **catalog id 11's** duʿā, not this one's. |
| 2.7 | Beat 2 `name_intro`, and the duʿā's three fields | catalog id 51 | catalog only | n/a | ✅ **verified byte-identical to catalog** — `arabic` / `transliteration` / `english` for the `name_intro`, and `dua_arabic` / `dua_transliteration` / `dua_translation` for beat 7. Re-checked programmatically 2026-08-02; the ship gate enforces both independently. |
### ⚠️ G1 — the founder's own URL check will not match on `Sunan Abi Dawud 1516`, and that is expected

The format spec's founder-review item 1 is *"open each URL — does the quoted text actually appear there?"* **On this URL, the English does not.** Disclosed here so the check produces the right answer instead of a false alarm.

**What the archived page prints as its English** (Wayback capture `20260607195027`, fetched 2026-08-02, verbatim):

> "We counted that the Messenger of Allah (ﷺ) would say a hundred times during a meeting: **'My Lord, forgive me and pardon me; Thou art the Pardoning and forgiving One'**."

**What beat 7 prints** (catalog id 51, which the ship gate forces byte-for-byte): *"My Lord, forgive me and accept my repentance. Indeed, You are At-Tawwab, Ar-Rahim."*

**They do not match, and the citation is still correct.** The divergence is entirely in the *English*: the published translator renders `وَتُبْ عَلَىَّ` ("and turn to me in acceptance") as "and pardon me", and `التَّوَّابُ الرَّحِيمُ` (At-Tawwāb, Ar-Raḥīm) as "the Pardoning and forgiving One" — a loose gloss that drops both Names. **The page's Arabic is `التَّوَّابُ الرَّحِيمُ`, exactly as row 2.5 states and as the token table below shows**, and the Arabic is what the citation is for: beat 7 renders Arabic, transliteration and translation as three separate fields, and the Arabic field is the one the citation attaches to.

Three consequences the founder should hold together:
1. **The citation stands.** The words on screen are the narrated words; only sunnah.com's English rendering of them differs.
2. **It is a second instance of the batch's on-screen-attribution problem**, from the opposite direction to `al-kareem@1`'s: there the deck's English diverges from the page's, here the *page's* English diverges from the catalog's. Whatever convention is chosen for K3 should cover this too.
3. **It is a live argument for `cf. Sunan Abi Dawud 1516`** over the plain form. The token divergence alone (one letter's orthography) did not justify "cf."; the English divergence might. Founder call — it changes only the `renderedDuaSources` string.

### The duʿā: what revision 1 got wrong, and the check that was actually run

Revision 1's ⚠️ flag said catalog id 51's duʿā is *"one word away from a narrated supplication"* ending `at-Tawwābu **al-Ghafūr**`, that the deck could therefore claim **no** ḥadīth provenance, and that fixing it would need a catalog migration. **All three claims were wrong.** There are **two routes**, both from Ibn ʿUmar via Nāfiʿ via Muḥammad b. Sūqa, diverging at Mālik b. Mighwal's students:

| route | ending | grade on the archived page | which catalog entry it matches |
|---|---|---|---|
| **Sunan Abi Dawud 1516** (al-Ḥasan b. ʿAlī ← Abū Usāma ← Mālik b. Mighwal) | `التَّوَّابُ الرَّحِيمُ` | **Sahih (Al-Albani)** | **id 51 — this deck** |
| **Jami' at-Tirmidhi 3434** (Naṣr al-Kūfī ← al-Muḥāribī ← Mālik b. Mighwal) | `التَّوَّابُ الْغَفُورُ` | **Sahih (Darussalam)**; Tirmidhī: *ḥasan ṣaḥīḥ gharīb* | id 11 (Al-Ghaffar), already shipped |

Two authenticated routes, not a near-miss. **Catalog id 51's duʿā is the Abū Dāwūd wording.**

**The exact comparison, so the ✅ means something** (Python, NFC normalisation, run 2026-08-02 against the text read off the archived page):

- Nine tokens. **Eight byte-identical** after NFC: `رَبِّ` `اغْفِرْ` `لِي` `وَتُبْ` `إِنَّكَ` `أَنْتَ` `التَّوَّابُ` `الرَّحِيمُ`.
- **One differs, and only in the letter carrying the same sound:**

| catalog id 51 | Abū Dāwūd printed edition | what differs |
|---|---|---|
| `عَلَيَّ` (ʿayn, fatḥa, lām, fatḥa, **yāʾ** U+064A, fatḥa, shadda) | `عَلَىَّ` (…, **alif maqṣūra** U+0649, fatḥa, shadda) | the same word `ʿalayya`, written with yāʾ in the catalog and with alif maqṣūra in the printed edition — an edition orthography convention, not a variant reading |

- Therefore: whole-string substring test is **False** raw and **False** after NFC. **It is not byte-identical, and this deck does not claim that it is.** It claims the words are the narrated words, which they are.
- **Precedent for citing on a non-byte-identical match:** the shipped, founder-signed `ash-shafi@1` carries `source: "cf. Sahih al-Bukhari 5743"` on a duʿā whose *wording and clause order* differ. The divergence here is one letter's orthography, far smaller — so the plain form `Sunan Abi Dawud 1516` (no "cf.") is proposed. If the founder prefers maximum caution, `cf. Sunan Abi Dawud 1516` is the alternative and needs only the `renderedDuaSources` string changed.

### Ship-gate note — **this deck's duʿā citation MUST be pinned at transcription time**

`renderedDuaSources` in `test/content/name_stories_ship_gate_test.dart` is now asserted **in both directions** (commit `a12f1db`): a pinned deck that drops its `source` fails the gate, **and an unpinned deck that carries a `source` also fails.** Revisions 1–2's description of the map as a one-way whitelist is out of date.

So this deck's duʿā beat and the map must be changed together, or the gate goes red. If this deck is signed, add at transcription time — **this exact string, in `test/content/name_stories_ship_gate_test.dart`**:

```dart
'al-ghafur@1': 'Sunan Abi Dawud 1516',
```

and the duʿā beat's `source` field must read exactly `Sunan Abi Dawud 1516`. **If the founder takes the "cf." option raised in G1 above**, both the beat and the map string become `cf. Sunan Abi Dawud 1516` — they are compared for equality, so they cannot diverge. *(This document does not edit the test or `name_stories.json`; it states the pin so transcription is mechanical.)*

### ⚠️ Two catalog-level flags the founder should see (neither fixable by a deck)

1. **This duʿā is a near-duplicate of a deck that ships *today*.** Revision 1 flagged the relationship to catalog id 11 (Al-Ghaffar) but missed the sharper one: catalog id 31 — **shipped `at-tawwab@1`** — reads `اللَّهُمَّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ`. The only difference from id 51 is `اللَّهُمَّ` vs `رَبِّ`. Two decks in the same forgiveness cluster will hand the user what is effectively the same sentence. Not a defect in either deck; a catalog decision about whether Al-Ghafur should carry a distinct invocation.
2. **The catalog contradicts this deck's own distinction.** Beat 8 teaches *ghafr = covering* against `al-afuw@1`'s *ʿafw = erasing* — a classical and defensible line (al-Ghazālī, Ibn al-Qayyim). But catalog id 51's `lesson` reads *"Al-Ghafur does not just forgive — **He erases the sin as if it never happened**"*, and catalog id 86 (Al-Afuw)'s `meaning` reads *"The One who **erases sins completely, as if they never happened**."* **The catalog hands Al-Ghafur Al-Afuw's distinctive.** A user who meets this deck ("the covering") and then the Al-Ghafur name card ("erases as if it never happened") is contradicted by the app itself. **Founder decision: does the id 51 `lesson` line move?** If it does not, beat 8 should probably be softened, because the deck will lose the argument to the card.

   **⚠️ Wording corrected in revision 3 (G3).** Revisions 1–2 said the id 51 `lesson` clause is *"**verbatim** the `meaning` of id 86"*. **That is false and it was a textual-identity claim, which is the category this pipeline gets wrong most often.** Substring test run programmatically 2026-08-02, both directions: **False.** The two strings are *"He erases the sin as if it never happened"* and *"erases sins completely, as if they never happened"* — singular vs plural, no "completely", different comma. **Same distinctive, different string.** The substance of the flag is unchanged and still correct; only the word "verbatim" was wrong, and it is gone.

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 14 shipped decks

**Baseline correction (revision 3).** Previous revisions' collision tables understated the shipped decks — they listed one or two sources per deck when the shipped `sources` arrays and beat `source` fields carry more. The table below is rebuilt from `assets/content/name_stories.json` itself (every `sources[].url` plus every beat `source`), 2026-08-02. Additions the earlier tables did not show are marked **(+)**.

| shipped deck | its narrative | its full inventory | collides? |
|---|---|---|---|
| `al-ghaffar@1` | the servant who kept returning | Bukhārī 7507; 39:53 | ✖ none in *source*, and the **distinction is the reason this deck exists**: Ghaffār = repetition (already shipped), Ghafūr = concealment (`satr`). Verse anchors deliberately disjoint — 39:53 is taken, so 4:110 is used. ⚠️ but see catalog flag ①: the two duʿās are one word apart. |
| `at-tawwab@1` | the man who took a hundred lives | Bukhārī 3470; 2:37 | ✖ none in narrative. ⚠️ **duʿā near-duplicate — see catalog flag ① above.** This is the collision revision 1 missed. |
| `al-lateef@1` | Yūsuf's answer | 12:100, **12:15 (+)**, **12:20 (+)**, **12:42 (+)**, 42:19, 67:13 | ✖ none in source — **but see the insight-collision note below, which revisions 1–2 marked ✖ none and should not have.** |
| `ar-rahman@1` · `al-baseer@1` · `ash-shafi@1` · `al-wadud@1` · `al-fattah@1` · `as-salam@1` | Bukhārī 5999; 2:286, 7:156, **55:1 (+)** · Bukhārī 3364; 58:1, **Ibn Mājah 188 (+)** · Bukhārī 5743; 21:83–84, 26:80 · Muslim 2747a, Bukhārī 6309; 11:90 · Bukhārī 4172, 4833, **2731 (+)**; 48:1, 35:2 · Muslim 591, **Bukhārī 3653 (+)**; 13:28, **9:40 (+)**, **59:23 (+)** | | ✖ none — no shared narration number |
| `al-wakeel@1` · `al-hadi@1` · `al-jabbar@1` · `ar-razzaq@1` · `as-samad@1` | 3:172–174, 65:3, **Bukhārī 4563 (+)** · 28:22, **28:15/21/23 (+)**, 22:54, **1:6 (+)** · 12:84, 12:86, 12:87, **12:18/12:94 (+)** · Tirmidhī 2344; 65:2, 65:3 · 19:2–7, 112:2 | | ✖ none |
| **sibling drafts in this batch** | `al-afuw@1` (Ibn Mājah 3850, Tirmidhī 3513, 97:3, 42:25) · `al-kareem@1` (Bukhārī 1145, Bukhārī 4684, 27:40) · `al-haleem@1` (**re-sourced in revision 3** — Bukhārī 7378, 19:90–91, 35:45) · `ar-raheem@1` (18:10, 18:11, 18:18, 33:43) | | ✖ none |

**Verified negative, run against the rebuilt inventory above:** no shipped deck and no sibling draft uses **Bukhārī 2441, Abū Dāwūd 1516 or 4:110**. The complete shipped ḥadīth set is Bukhārī 3653, 4563, 6309, 7507, 3470, 5743, 2731, 4172, 4833, 5999, 3364 · Muslim 591, 2747a · Tirmidhī 2344 · Ibn Mājah 188 — 2441 and Abū Dāwūd 1516 are not in it.

### ⚠️ G4 — the insight collision with shipped `al-lateef@1`, and how it was resolved

Revisions 1–2 marked `al-lateef@1` **✖ none**. On sources that is true. **On closing insight it was not**, and two beats echoed, not one:

| | `al-ghafur@1` revisions 1–2 | `al-lateef@1` (shipped, founder-signed) |
|---|---|---|
| bridge | "There is a thing you would **not want read out loud**." | "You **couldn't put it into words**." |
| takeaway | "the thing you **could not say out loud** was **never said out loud**." | "**What you couldn't say** was **never unsaid to Him**." |

Same sentence shape, same "the thing you couldn't say" hook, takeaways one negation apart. The meanings do differ — concealment vs. being known without words — but two beats of a new deck should not read as a paraphrase of two beats of a shipped one.

**Resolved, not disclosed.** Both beats are rewritten in revision 3 onto this deck's actual axis, which is **exposure**, not wordlessness:
- bridge → *"The fear underneath guilt is usually not the punishment. It is being found out."*
- takeaway → *"Al-Ghafur is not only the forgiving — it is the covering. In that account every sin is named once, in private, to the One who already knew, and no one else is ever told."*

The new takeaway is also **more sourced** than the old one: *"no one else is ever told"* is the narration's own contrast with its omitted tail (row 2.3 — the disbelievers and hypocrites *are* exposed publicly), and *"named once, in private"* is the doubled `أَتَعْرِفُ` and the `satr` now restored to beats 4–5.

**Re-checked against the shipped closing insights after the rewrite:** `al-lateef@1` (wordlessness), `al-ghaffar@1` (repetition), `at-tawwab@1` (acceptance of return), `ar-rahman@1` (mercy exceeding a mother's), `al-baseer@1` (heard when no one else could hear). **✖ none.** The nearest is `al-baseer@1` — being perceived when unperceived — and it is the inverse of this one: there the point is that Allah *notices*; here it is that Allah does not *publish*. Recorded so the next check starts from a true baseline.

### Authoring notes (candidates considered)

- **Selected: an-najwā, Bukhārī 2441.** It is the one narration whose engine is *satr* — covering — which is precisely what distinguishes Al-Ghafūr from Al-Ghaffār in this app's own catalog gloss ("forgives **and conceals** faults with grace"). Al-Ghaffār already ships a deck about repetition (`al-ghaffar@1`, Bukhārī 7507); if Al-Ghafūr also taught repetition, the pack would be teaching the same Name twice under two spellings. It is also, for the actual user, the fear underneath guilt: not punishment but exposure.
- **Rejected — "O son of Adam, were your sins to reach the clouds of the sky…" ([Jami' at-Tirmidhi 3540](https://sunnah.com/tirmidhi:3540), graded **ḥasan** (Darussalam), verified via archive 2026-08-02).** Genuinely the runner-up and emotionally enormous. Rejected on two grounds: ṣaḥīḥ outranks ḥasan where impact is comparable, and its engine is scale-of-forgiveness, which again overlaps `al-ghaffar@1`. Held as the fallback.
- **Rejected — the man who took a hundred lives (Bukhārī 3470).** Already shipped as the story of `at-tawwab@1`.
- **Rejected — Qur'ān 39:53 as the verse anchor** ("Do not lose hope…"). It is the obvious verse, and it is *already* the verse beat of `al-ghaffar@1`. 4:110 was chosen instead: same promise, the Name in-text, and the verb is *yajid* — "will find".
- **Register check:** no beat says the Name waits, wants, or withholds. Beat 8 reports what the cited narration contains — *"named once, in private"* is the doubled `أَتَعْرِفُ` plus `يَسْتُرُهُ`, and *"no one else is ever told"* is the contrast with the narration's own omitted tail (row 2.3). Beat 1 states a fact about fear, not a promise about the reader.
- **What revision 3 did NOT change:** the story selection, the verse anchor, the duʿā, the two-route argument, and every rejection above. The changes are a translation correction inside the quoted narration (G2), a disclosure (G1), a word (G3), two authored beats (G4), the translations premise, and the collision baseline.
