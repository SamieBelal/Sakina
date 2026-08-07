# Deck Draft — Ar-Raheem (mercy/forgiveness pack, Wave G pilot 1 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

**Revision 3 — 2026-08-02. No beat changed. Four corrections, all of them disclosure and marking:**
1. **Row 1.5's ✅ was overstated (R3).** *"That was the answer."* was marked *"✅ **verified** — this is the sūrah's own sequence, **not an inference**"*. **It is an inference** — a mainstream and well-grounded one, but every neighbouring ✅ in this table means "this string matches the fetched page". Relabelled with the honest label the sibling deck already uses.
2. **An undisclosed excerpt boundary at 18:25/18:26 (R2).** Beat 5 states "three hundred years, and nine" flat, and **18:26 — the very next āyah — is *"Say, 'Allāh is most knowing of how long they remained.'"*** The deck carefully disclosed the omitted remainder of 18:18 and never mentioned this. Now disclosed the same way.
3. **The authored joint is named (R6).** The qualifier that makes this Ar-Raḥīm rather than Ar-Raḥmān — `بِالْمُؤْمِنِينَ` — comes from **33:43, a different sūrah with no connection to the cave.** The teaching is shown rather than asserted, but the join between the passage and the qualifier is the deck's, not the text's.
4. **An insight collision with shipped `al-lateef@1` was marked ✖ none (R1)** and is now disclosed with the reason it is being kept rather than rewritten.

Plus the batch-wide **126-translation correction** (below), the collision-table baseline, and the ship-gate note, which was describing a version of the gate that no longer exists.

**Revision 2 — 2026-08-02.** Revision 1 (the Ayyūb selection) was **rejected**: it duplicated the shipped, founder-signed `ash-shafi@1` — same prophet, same two āyāt (21:83–84), same two quotations, same "his whole prayer was one line" framing, same "he demanded nothing" takeaway. `ash-shafi@1` even already carries *"You are the Most Merciful of the merciful"*, i.e. the hook revision 1 nominated as Ar-Raḥīm's own. The story below is a full re-source. The whole 14-deck story inventory was rebuilt first and is checked at the bottom of this file.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G. Author: Claude, 2026-08-02.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com` against the canonical `quran.com/{surah}/{ayah}` reference; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching). Scripture is quoted exactly from the fetched pages; story beats paraphrase only what the cited source carries.

**Translation standard for this deck (founder ruling A1 — most appropriate per Name, never at the cost of authenticity; Abdel Haleem is the named second option where Saheeh International reads stiffly):** every quotation below is **Saheeh International** (`resource_id: 20`), named per row in the sources table, with the **Abdel Haleem (`resource_id: 85`)** alternative fetched and compared per row.

### ⚠️ The 126-translation correction (batch-wide, BLOCKING before sign-off)

Revisions 1–2 of all five decks said: *"`api.quran.com/api/v4/resources/translations` currently lists **eight** English translations and Khattab is not among them."*

**That is false.** `GET /api/v4/resources/translations?language=en` returns **126** entries (re-fetched and counted programmatically, 2026-08-02).

What is true, and what the conclusion actually rested on: **Khattab (`resource_id: 131`) is genuinely absent from that list**, and `/quran/translations/131?verse_key=…` genuinely returns `{"translations":[]}` while `…/20` returns text. Both reproduced 2026-08-02. So Khattab still cannot be quoted and the fetch-first rule still forbids quoting it from memory — but the reason given was wrong, and it foreclosed live options, chiefly **M.A.S. Abdel Haleem (`resource_id: 85`)**, which is live and has now been fetched for every quoted row below.

**What re-running the choice against the real list changed for this deck — nothing, and here is the fetched evidence:**

| row | Saheeh International (`20`) — **used** | Abdel Haleem (`85`) — fetched, not used | why |
|---|---|---|---|
| 18:11 | "So We cast [a cover of sleep] over their ears within the cave for **a number of years**." | "We sealed their ears [with sleep] in the cave for years." | Abdel Haleem drops `عَدَدًا` — "a number of" — which is the vagueness the whole story turns on (18:26: *"Allāh is most knowing of how long they remained"*). Saheeh International keeps it. |
| 18:18 | "And you would think them awake, while they were asleep. And We turned them to the right and to the left…" | "You would have thought they were awake, though they lay asleep. We turned them over, to the right and the left…" | Effectively equivalent; no reason to switch, and switching would put one Abdel Haleem beat next to two Saheeh International ones. |
| 33:43 | "And ever is He, to the believers, **Merciful**." | "He is ever **merciful** towards the believers-" | **Decisive.** Abdel Haleem lower-cases the Name and ends on a hyphen running into 33:44. This beat exists to put `رَحِيمًا` on the page **as the Name**, with `بِالْمُؤْمِنِينَ` attached. Abdel Haleem deletes the Name visually. |

The batch-wide reason the same answer came back on every row of all five decks: **Abdel Haleem renders the divine name as "God", not "Allāh", and lower-cases the Names** where Saheeh International capitalises them. Against 14 shipped decks that all say "Allah", adopting it would break the app's core vocabulary mid-pack. So it is **compared and named per row, adopted nowhere.**

**The discontinuity that remains, stated plainly:** the 14 shipped decks lean **Khattab** in register — `al-wakeel@1` (`˹alone˺`), `at-tawwab@1` (`˹of prayer˺`), `as-samad@1` (`˹needed by all˺`), and `ash-shafi@1`'s sources array literally pins *"Khattab rendering"*. These five ship in Saheeh International. `ar-rahman@1`'s founder-decided Saheeh International comfort verse is the precedent that mixing is permitted, so this is defensible — but it is a real register mix and the founder is signing it, now on a true premise rather than a false one.

**Implementation note (binding):** every beat stores Arabic / transliteration / translation as **separate fields**. The em-dash formatting below is markdown shorthand only, never a single mixed-direction `Text`.

---

## Deck `ar-raheem@1` — Ar-Raheem

**Proposed metadata**

```json
{
  "deck_id": "ar-raheem@1",
  "name_id": 3,
  "transliteration": "Ar-Raheem",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

*(Pack content, not a chip pair — `chip_keys: []` keeps it outside the seven chip-pair assertions in the ship gate, and outside the pair-synergy rule.)*

**Beat 1 · bridge:**
> There is a mercy that keeps everyone alive. And there is a mercy that answers. This is the Name for the second one.

**Beat 2 · name_intro** *(from `collectible_names.json` id 3, verbatim)*:
> الرَّحِيمُ — Ar-Raheem — The Most Merciful

**Beats 3–5 · story — "Three hundred years and nine":**
> 1. They were young men who believed in their Lord, in a place where saying so would have got them stoned. They withdrew to a cave and asked Him for one thing.
> 2. **"So We cast [a cover of sleep] over their ears within the cave for a number of years."** That was the answer. Sleep.
> 3. **"And you would think them awake, while they were asleep. And We turned them to the right and to the left…"** — for three hundred years, and nine.

**Beat 6 · verse** *(marked excerpt — the Name appears in the verse itself, with the exact qualifier that distinguishes it)*:
> "…And ever is He, to the believers, Merciful." — Qur'ān 33:43

**Beat 7 · duʿā** *(catalog id 3, verbatim in full — these are the words the youths said in the cave, Qur'ān 18:10)*:
> رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا
> *Rabbana atina min ladunka rahmatan wa hayyi' lana min amrina rashada*
> "Our Lord, grant us mercy from Yourself and guide us rightly through our affair."
>
> *(proposed `source` field on this beat: `Qur'an 18:10`)*

**Beat 8 · takeaway:**
> That sentence was theirs first. They said it going in — and it was being answered the whole time they were unconscious of it, one turn at a time, for three centuries.

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | Beat 3: "young men who believed in their Lord" | Saheeh International — the only English rendering verifiable today (see note above) | [Qur'ān 18:13](https://quran.com/18/13) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/18:13?translations=20`, 2026-08-02. Fetched string: *"Indeed, they were youths who believed in their Lord, and We increased them in guidance."* Beat paraphrases; nothing quoted. |
| 1.2 | Beat 3: "where saying so would have got them stoned" | Saheeh International | [Qur'ān 18:20](https://quran.com/18/20) | Qur'ān | ✅ **verified** — live fetch, 2026-08-02. Fetched string: *"Indeed, if they come to know of you, they will stone you or return you to their religion. And never would you succeed, then - ever."* **Precise provenance, since the beat compresses it:** these are the youths' **own** words about the people they had fled, spoken to one another after they woke (18:19–20), not third-person narration about the city before they left. The beat states their assessment of the danger, which is what the passage carries. Nothing quoted. |
| 1.3 | Beat 3: "They withdrew to a cave and asked Him for one thing" | Saheeh International | [Qur'ān 18:10](https://quran.com/18/10) · [18:16](https://quran.com/18/16) | Qur'ān | ✅ **verified** — live fetch of both, 2026-08-02. 18:10: *"[Mention] when the youths retreated to the cave and said, 'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance.'"* 18:16: *"And when you have withdrawn from them and that which they worship other than Allāh, retreat to the cave…"* The prayer itself is deliberately **not** quoted here — it is beat 7. |
| 1.4 | Beat 4 quotation, verbatim: "So We cast [a cover of sleep] over their ears within the cave for a number of years." | **Saheeh International**; the `[a cover of sleep]` bracket is **the translator's own**, present in the fetched string, not authored. Abdel Haleem (85) fetched and compared — *"We sealed their ears [with sleep] in the cave for years."* — rejected because it drops `عَدَدًا` ("a number of"), which is the vagueness 18:26 turns on. | [Qur'ān 18:11](https://quran.com/18/11) | Qur'ān | ✅ **verified** — live fetch `?translations=20,85`, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched Saheeh International string; the fetched string carries no footnote marker, so nothing was stripped. |
| 1.5 | Beat 4: "That was the answer." | — | [Qur'ān 18:10–11](https://quran.com/18/11) | Qur'ān | ✅ **honest label — this is authored reading, not a source claim, and this is the corrected row.** Revisions 1–2 marked it *"✅ **verified** … **not an inference**"*, which put a string-match mark on an interpretation while every neighbouring ✅ in this table means "this string matches the fetched page". **It is an inference.** What is verified: 18:11 opens with the conjunctive *fa-* (`فَضَرَبْنَا`, "*So* We cast") and immediately follows the prayer in 18:10 — both fetched, both true. What is inferred: that the sleep therefore *is* the answer to that prayer. The reading is mainstream and the `fa-` supports it, but the Qur'ān does not say it, and the deck should not mark it as though it did. Label matched to the sibling `al-haleem@1`'s convention for authored copy. |
| 1.6 | Beat 5 quotation, marked excerpt: "And you would think them awake, while they were asleep. And We turned them to the right and to the left…" | **Saheeh International**; Abdel Haleem (85) fetched and compared and is effectively equivalent here — not switched, because it would put one Abdel Haleem beat between two Saheeh International ones | [Qur'ān 18:18](https://quran.com/18/18) | Qur'ān | ✅ **verified** — live fetch `?translations=20,85`, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched Saheeh International string. The ellipsis marks the omitted remainder (*"…while their dog stretched his forelegs at the entrance. If you had looked at them, you would have turned from them in flight and been filled by them with terror."*) — omitted for register and length, and the omission is disclosed here |
| 1.7 | Beat 5: "for three hundred years, and nine" | Saheeh International | [Qur'ān 18:25](https://quran.com/18/25) | Qur'ān | ⚠️ **verified, with an excerpt boundary now disclosed (R2).** Live fetch, 2026-08-02. Fetched string: *"And they remained in their cave for three hundred years and exceeded by nine."* A footnote marker rendering as a stray `1` in the API string is not carried into the beat; the beat does not quote this verse, it states its number. **The disclosure, which revisions 1–2 omitted:** the very next āyah is **18:26**, fetched — *"Say, 'Allāh is most knowing of how long they remained. He has [knowledge of] the unseen [aspects] of the heavens and the earth…'"* Classical readings split on whether 18:25 reports the People of the Book's figure with 18:26 as the divine qualifier — Abdel Haleem's rendering makes that reading explicit and was fetched to confirm it: *"[Some say], 'The sleepers stayed in their cave for three hundred years,' some added nine more."* **Under the majority reading the beat is fine, and it is what the shipped Saheeh International text says flatly.** But 18:26 is the first thing a founder tapping this citation reads, and this deck already discloses the omitted remainder of 18:18 — so the same standard is applied here. **Founder option if he prefers maximum caution:** beat 5 can end at the 18:18 quotation and drop "for three hundred years, and nine" entirely; the story does not depend on the number, and beat 8's "three centuries" would become "the whole time". *(The 18:25 footnote itself was fetched — id 196698, *"i.e., 309 lunar years."* — and is immaterial; it was correctly dropped.)* |
| 1.8 | Beat 6, verse anchor, marked excerpt: "…And ever is He, to the believers, Merciful." | **Saheeh International.** Abdel Haleem (85) fetched and compared — *"He is ever **merciful** towards the believers-"* — rejected because it lower-cases the Name and ends on a hyphen running into 33:44; this beat exists to show the Name. | [Qur'ān 33:43](https://quran.com/33/43) | Qur'ān | ✅ **verified** — live fetch `?translations=20,85`, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched Saheeh International after the footnote marker is stripped. Full verse: *"It is He who confers blessing upon you, and His angels [ask Him to do so] that He may bring you out from darknesses into the light. And ever is He, to the believers, Merciful."* The footnote marker (id 197101, fetched) renders as a stray `1` after "upon you", falls in the omitted opening, and never reaches the beat. Arabic `وَكَانَ بِالْمُؤْمِنِينَ رَحِيمًا` — the Name in-text **and** the qualifier `بِالْمُؤْمِنِينَ` ("to the believers"). ⚠️ **The joint is authored — see the note below (R6).** |
| 1.10 | Beat 2 `name_intro` | catalog id 3 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`, re-checked programmatically 2026-08-02. Duʿā fields likewise byte-identical across all three (`dua_arabic` / `dua_transliteration` / `dua_translation`); the ship gate enforces both independently. |
| 1.9 | Duʿā beat carries `source: Qur'an 18:10` | catalog id 3 translation (see the ⚠️ below) | [Qur'ān 18:10](https://quran.com/18/10) | Qur'ān | ⚠️ **partially verified — read the flag below.** The Arabic is the same words and the same consonantal text; it is **not** byte-identical, and the English is not Saheeh International. |

### ⚠️ R6 — the joint between the story and the qualifier is authored, and it was not named

The claim the deck makes is that this story teaches **Ar-Raḥīm as distinct from Ar-Raḥmān**: mercy that is *particular* (to these named believers) and *ongoing* (across three centuries). Both halves genuinely are in the cited text — 18:10's `آتِنَا` is a request by named believers, and 18:18's `وَنُقَلِّبُهُمْ` is a real imperfect, an action still in progress. That much is shown, not asserted.

**What is authored, and must be named: the qualifier that does the actual distinguishing — `بِالْمُؤْمِنِينَ` — comes from 33:43, a verse in a different sūrah with no connection to the cave.** Nothing in the Kahf passage says the mercy was particular *because* they were believers. 18:13 says they were believers; 18:10–11 says mercy was asked for and sleep was given; **the causal link between the two is the deck's.**

This is a genuine authoring move, not a defect — the verse beat is *supposed* to name the Name, and putting a Name-in-text verse next to a story that lacks one is what every deck in this batch does. But the deck's existing "Honest weakness, recorded" covers only the *absence* of the Name-noun from the story, not the *presence* of an argument the deck supplies. It is now covered. **The founder is signing: a story that shows particularity and continuity, plus one authored inference (1.5) and one authored join (this one).**

### ⚠️ R1 — insight collision with shipped, founder-signed `al-lateef@1`

Revisions 1–2 marked `al-lateef@1` **✖ none**. On sources that is true — 12:100 / 42:19 / 67:13 share nothing with Sūrat al-Kahf. **On closing insight it is not:**

| | `ar-raheem@1` beat 8 | `al-lateef@1` beat 5 (shipped, signed) |
|---|---|---|
| | "…it was being **answered the whole time they were unconscious of it**, one turn at a time, for three centuries." | "Subtle kindness, **threaded through every wound — visible only from the far side**." |

Same engine: care operating unseen throughout, recognised only in retrospect. It is structurally reinforced, too — `al-lateef@1`'s verse beat is 42:19 `اللَّهُ لَطِيفٌ بِعِبَادِهِ`, a particularising preposition attached to the Name, which is the identical move as this deck's 33:43 `بِالْمُؤْمِنِينَ`.

**Disclosed rather than resolved, and here is the reasoning so the founder can overrule it.** Unlike `al-ghafur@1`'s collision with the same deck — which was two beats echoing in near-identical *syntax* and was rewritten — this is one beat sharing a *shape of insight* with no shared vocabulary, no shared sentence structure, and a different subject (mercy vs. subtlety). Rewriting beat 8 would cost the deck its strongest property: that the duʿā the user says at beat 7 **is the prayer this story answers**, which is what beat 8 exists to land. **If the founder judges the two too close, the fix is to cut "the whole time they were unconscious of it" and let beat 8 rest on "That sentence was theirs first."** One line, and it is his call, not mine — the point of this note is that he gets to make it instead of the table telling him there is nothing to decide.

### ⚠️ Two honest corrections to revision 1's sources table

Revision 1 recorded *"✅ verified — letter-for-letter identical to quran.com's `text_imlaei` for 18:10 (checked programmatically; only diacritic conventions differ)"*. **That ✅ was wrong** — a string cannot be letter-for-letter identical and also differ in letters, and the check does not pass. Here is what a real run returns (Python, `unicodedata.normalize('NFC', …)`, 2026-08-02):

- catalog id 3 `dua_arabic` ⊂ quran.com `text_imlaei` for 18:10 → **False** raw, **False** after NFC.
- Token-by-token over the nine words: **7 of 9 byte-identical**, 2 differ:

| catalog id 3 | quran.com `text_imlaei` | what differs |
|---|---|---|
| `مِنْ` | `مِن` | catalog writes the sukūn on the nūn; the muṣḥaf orthography omits it before the assimilated lām |
| `لَدُنْكَ` | `لَّدُنكَ` | the muṣḥaf marks the *idghām* with a shadda on the lām and omits the sukūn on the nūn |

Consonantal text (rasm) identical; the difference is idghām notation only. **Religiously immaterial — but it is not "letter-for-letter identical", and the deck now says so.**

Second correction, not previously disclosed at all: **the catalog's English is not the Saheeh International rendering of 18:10.**

- Saheeh International: *"Our Lord, grant us **from Yourself mercy and prepare for us from our affair right guidance**."*
- catalog id 3 `dua_translation` (which the ship gate forces the beat to carry byte-for-byte): *"Our Lord, grant us **mercy from Yourself and guide us rightly through our affair**."*

Faithful, and better English — but it is a **paraphrase carrying a Qur'ān citation**. The shipped `al-wakeel@1` sets the precedent (its catalog duʿā carries `source: "Qur'an 3:173"` on a non-identical rendering), so the practice is established, not new. Founder call, stated plainly rather than buried: **keep `source: Qur'an 18:10`** (recommended — the words genuinely are the āyah, and the story is *about* that āyah, so removing the citation would hide the deck's own point), or drop the source field and let the duʿā stand as a bare catalog invocation.

### Ship-gate note — **this deck's duʿā citation MUST be pinned at transcription time**

`renderedDuaSources` in `test/content/name_stories_ship_gate_test.dart` is now asserted **in both directions** (commit `a12f1db`): a pinned deck that drops its `source` fails the gate, **and an unpinned deck that carries a `source` also fails.** Revisions 1–2 described it as a one-way whitelist; that is out of date, and it means the beat and the map must change together or the gate goes red.

If this deck is signed, add at transcription time — **this exact string, in `test/content/name_stories_ship_gate_test.dart`**:

```dart
'ar-raheem@1': "Qur'an 18:10",
```

and the duʿā beat's `source` field must read exactly `Qur'an 18:10`. **If the founder takes the "drop the citation" option** raised in the correction box above, then the beat must carry **no** `source` field and this line must **not** be added — the two are asserted for equality, so a half-applied decision fails CI rather than shipping silently. *(This document does not edit the test or `name_stories.json`; it states the pin so transcription is mechanical.)*

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 14 shipped decks (run before drafting, not after)

**Baseline correction (revision 3).** Previous revisions' collision tables understated the shipped decks — they listed one or two āyāt per deck when the shipped `sources` arrays and beat `source` fields carry more. The table below is rebuilt from `assets/content/name_stories.json` itself (every `sources[].url` plus every beat `source`), 2026-08-02. Additions the earlier tables did not show are marked **(+)**. The conclusions survive unchanged, but the founder was reading a table that did not show the inventory it was checked against.

| shipped deck | its narrative | its full inventory | collides? |
|---|---|---|---|
| `as-salam@1` | the cave of Thawr, during the hijrah | 13:28, **9:40 (+)**, **59:23 (+)**, **Bukhārī 3653 (+)**, Muslim 591 | ⚠️ **both stories involve a cave, and nothing else.** **And the (+) additions sharpen this rather than softening it: 9:40 is the Thawr āyah itself** (*"when they were in the cave"*), which the earlier table did not show. It is still not a collision — different cave, different century, different people, no shared verse — but the founder should see that the shipped deck's cave is scripturally anchored, not merely narrated. Still: different cave, different century, different people, no shared verse, no shared quotation, no shared insight (there: stillness inside while danger stays outside; here: mercy continuing over a span nobody was awake for). The story **label** is therefore deliberately *"Three hundred years and nine"*, never "The Cave", so the two never read as one on screen. Disclosed rather than dismissed. |
| `ash-shafi@1` | Ayyūb | 21:83–84, 26:80, Bukhārī 5743 | ✖ none — **this is the collision that killed revision 1**, and it is now fully avoided: no shared prophet, sūrah, verse, quotation or takeaway |
| `ar-rahman@1` | the mother among the captives | 2:286, 7:156, **55:1 (+)**, Bukhārī 5999 | ✖ none in source. The two mercy decks now teach the *distinction*: 7:156 `وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ` (mercy that encompasses **everything**) for Ar-Raḥmān; 33:43 `وَكَانَ بِالْمُؤْمِنِينَ رَحِيمًا` (Merciful **to the believers**) for Ar-Raḥīm. That is exactly the founder's brief. ⚠️ **but see catalog flag ① below — the Ar-Raheem *name card* hands the user Ar-Rahman's deck's climax.** |
| `al-lateef@1` | Yūsuf's answer | 12:100, **12:15 (+)**, **12:20 (+)**, **12:42 (+)**, 42:19, 67:13 | ✖ none in source — **but see R1 above.** The closing insights share an engine, and revisions 1–2 marked this row ✖ none without looking at that axis. |
| `al-wakeel@1` · `al-wadud@1` · `al-hadi@1` · `al-ghaffar@1` · `at-tawwab@1` · `al-jabbar@1` · `ar-razzaq@1` · `al-fattah@1` · `al-baseer@1` · `as-samad@1` | Uḥud aftermath · lost camel · Mūsā to Midian · the servant who kept returning · the hundred lives · Yaʿqūb's grief · the birds · Ḥudaybiyyah · Hājar · Zakariyyā | 3:172–174, 65:3, **Bukhārī 4563 (+)** · 11:90, Muslim 2747a, Bukhārī 6309 · 28:22, **28:15/21/23 (+)**, 22:54, **1:6 (+)** · 39:53, Bukhārī 7507 · 2:37, Bukhārī 3470 · 12:84, 12:86, 12:87, **12:18/12:94 (+)** · 65:2, 65:3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/**2731 (+)** · 58:1, Bukhārī 3364, **Ibn Mājah 188 (+)** · 19:2–7, 112:2 | ✖ none |
| **sibling drafts in this batch** | `al-afuw@1` (Ibn Mājah 3850, Tirmidhī 3513, 97:3, 42:25) · `al-ghafur@1` (Bukhārī 2441, Abū Dāwūd 1516, 4:110) · `al-kareem@1` (Bukhārī 1145, Bukhārī 4684, 27:40) · `al-haleem@1` (**re-sourced in revision 3** — Bukhārī 7378, 19:90–91, 35:45) | | ✖ none |

**Verified negative, run against the rebuilt inventory above:** **no shipped deck uses any verse of Sūrat al-Kahf, and none uses 33:43.** Complete shipped Qur'ān inventory checked against: 1:6, 2:37, 2:286, 3:172, 3:173, 3:174, 7:156, 9:40, 11:90, 12:15, 12:18, 12:20, 12:42, 12:84, 12:86, 12:87, 12:94, 12:96, 12:100, 13:28, 19:2, 19:3, 19:4, 19:7, 21:83, 21:84, 22:54, 26:80, 28:15, 28:21, 28:22, 28:23, 35:2, 39:53, 42:19, 48:1, 55:1, 58:1, 59:23, 65:2, 65:3, 67:13, 112:2. **Sūrat al-Kahf: absent. 33:43: absent.**

### ⚠️ Catalog-level flag the founder should see (not fixable by a deck)

**① The Ar-Raheem name card hands the user Ar-Rahman's deck's climax.** Catalog id 3's `hadith` field reads:

> *"The Prophet ﷺ said: 'Allah is more merciful to His servants than a mother is to her child.' (Bukhari & Muslim)"*

That is **Ṣaḥīḥ al-Bukhārī 5999 — the entire story and the beat-5 punchline of the shipped, founder-signed `ar-rahman@1`.** So a user who meets this deck (which is built to teach the Raḥmān/Raḥīm *distinction*) and then opens the Ar-Raheem name card is handed the other mercy deck's payoff under this Name. Out of this deck's reach — the ship gate forces catalog byte-identity for the `name_intro` and duʿā, and the `hadith` field is a Name-card surface, not a deck surface. But it partly undercuts the distinction the deck's whole selection argument rests on, and it is the same class of flag `al-ghafur@1` and `al-kareem@1` raise for their Names. **Founder decision: does the id 3 `hadith` line move?** Raised now; revisions 1–2 did not raise it.

### Authoring notes (candidates considered)

- **Selected: the youths of the cave (18:10–25).**
  1. **Name-engine.** Ar-Raḥīm is, in this app's own catalog, *"The One whose special mercy is reserved for the believers"* — mercy that is **particular** and **ongoing**, against Ar-Raḥmān's universal mercy. This narrative is both: it is asked for by named believers (`آتِنَا مِن لَّدُنكَ رَحْمَةً` — "grant **us** from Yourself mercy"), it is granted to those particular people, and its most astonishing detail is that it *continues* — `وَنُقَلِّبُهُمْ` is an imperfect verb, an act still in progress across three centuries, performed on people who were not awake to notice it.
  2. **Highest available duʿā correlation.** The catalog duʿā the user says on the last screen **is this story's own prayer**. That is the property the adversarial reviewer singled out as what makes `al-afuw@1` the strongest deck in the batch — and Ar-Raheem is the only other Name in the batch where the catalog hands it to us for free.
  3. **Qur'ān-sourced**, which the protocol prefers over ḥadīth at comparable impact.
  4. **Honest weakness, recorded:** the Name-noun `الرَّحِيم` does **not** appear in the story passage — 18:10 has `رَحْمَةً`, 18:16 has `مِن رَّحْمَتِهِ`. The Name-in-text is carried by the verse beat (33:43), not by the story. Selection criterion (2) is therefore met by the Name's *meaning* being the story's engine, not by the word being on the page. Said plainly so the founder is not signing a claim the deck cannot support.
- **Rejected — Ayyūb, 21:83–84 (revision 1's selection).** Already shipped as `ash-shafi@1`, signed by the founder 2026-07-25. See the header.
- **Rejected — Kaʿb b. Mālik and the three who were left behind (Bukhārī 4418; Qur'ān 9:117–118).** Genuinely the runner-up, and 9:117 closes on `إِنَّهُ بِهِمْ رَءُوفٌ رَّحِيمٌ` — the Name in-text, with `بِهِم` ("to **them**"), which is the particularity this deck is about. Rejected because its engine is *tawba*: the pack already ships `at-tawwab@1` and `al-ghaffar@1` and this batch adds `al-ghafur@1` and `al-afuw@1`, so a fifth forgiveness narrative would make Ar-Raḥīm the fourth forgiveness deck rather than the mercy deck. **Held as the fallback if the cave is ruled not-good** — it is verifiable, and I would fetch and grade Bukhārī 4418 properly before drafting it.
- **Rejected — Yūnus in the fish (21:87–88).** `وَكَذَٰلِكَ نُنجِي الْمُؤْمِنِينَ` ("and thus do We save the believers") is a strong particular-mercy line. Rejected on collision proximity: 21:87–88 sits four āyāt from `ash-shafi@1`'s 21:83–84, and 21:88 opens `فَاسْتَجَبْنَا لَهُ` — the identical construction to the 21:84 clause `ash-shafi@1` already quotes. It would read as a re-run of a shipped deck's page.
- **Rejected — Mūsā's mother (28:7–13).** Beautiful and particular ("So We restored him to his mother that she might be content and not grieve"), but no form of *r-ḥ-m* in the passage, so the Name would be attached by theme alone.
- **Rejected — mercy divided into one hundred parts (Bukhārī 6469).** Carried over from revision 1: verified, but a statement about scale rather than a narrative, and it closes on a clause about the Fire — wrong register here. Its actual content is the Raḥmān/Raḥīm *distinction*, so it is a better footnote than a story.
- **⚠️ Beat 1 and beat 6 define the Name on two different axes, and the deck reconciles neither.** The bridge says *"There is a mercy that keeps everyone alive. And there is a mercy that **answers**. This is the Name for the second one."* — **responsiveness**, which is al-Mujīb's axis (`al-kareem@1` flags exactly this conflation *against itself* in this same batch). The catalog gloss and the verse beat are about **particularity** (`بِالْمُؤْمِنِينَ`), not responsiveness. So the deck's opening line and its closing verse teach two different distinctions. **Not rewritten, and here is why the founder should decide rather than me:** responsiveness is what makes the bridge land for a burdened reader at beat 1, and it is *true of this story* (the prayer in 18:10 is answered in 18:11) — it is just not what 33:43 distinguishes. **The one-line fix if he wants the axes to match:** *"There is a mercy that keeps everyone alive. And there is a mercy with names attached to it. This is the Name for the second one."* Raised now; revisions 1–2 did not raise it.
- **Register check:** no beat attributes an action, a stance or waiting to the Name. Beats 4–5 quote the Qur'ān's own past-tense narration. Beat 8 reports what the cited passage records; it makes no claim about what will happen to the reader.
- **What revision 3 did NOT change:** not one beat. The changes are two relabels (1.5, 1.7), three disclosures (R1, R6, catalog flag ①), the translations premise, the collision baseline, and the ship-gate note.
