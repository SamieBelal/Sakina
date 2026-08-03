# Deck Draft — Al-Qadir (hardship pack, Wave G batch 2, 3 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G, §G2b. Author: Claude, 2026-08-03. Batch theme: **hardship — the situation that has not lifted.**

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com`; ḥadīth via Wayback archive of the exact `sunnah.com` URL. Scripture is quoted exactly from the fetched pages; story beats paraphrase only what the cited source carries, and every paraphrase is labelled.

**Translation standard:** Saheeh International (`20`) throughout, Abdel Haleem (`85`) fetched and compared per row and adopted nowhere (it says "God"). Khattab (`131`) remains unfetchable.

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on every beat.

---

## Deck `al-qadir@1` — Al-Qadir

**Why this deck exists, in one line:** the user who believes and cannot feel it thinks that gap is a defect. **Ibrāhīm names the same gap out loud, in the Qur'ān, and is not corrected for it.** Plan §STEP-3 criterion 4 at full strength — the struggle in the story is the reader's own, not a bystander's.

**Proposed metadata**

```json
{
  "deck_id": "al-qadir@1",
  "name_id": 75,
  "transliteration": "Al-Qadir",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You believe it. You just cannot feel it, and that gap is its own kind of tired. Someone said that out loud once.

**Beat 2 · name_intro** *(from `collectible_names.json` id 75, verbatim)*:
> الْقَادِرُ — Al-Qadir — The Capable

**Beats 3–5 · story — "Four birds":**
> 1. Ibrāhīm asked to be shown something he already believed.
> 2. He said: **"My Lord, show me how You give life to the dead."** Allah said: **"Have you not believed?"** He said: **"Yes, but [I ask] only that my heart may be satisfied."**
> 3. Allah said: **"Take four birds and commit them to yourself. Then [after slaughtering them] put on each hill a portion of them; then call them - they will come [flying] to you in haste."** He was not corrected. He was given something to do, and told what would happen.

*(Revision 2, 2026-08-03 — four changes, all from the independent adversarial verdict. (a) Beat 5's closing line no longer reads "He was shown": 2:260 stops at the instruction and at Allah's statement of what **will** happen, and never narrates that Ibrāhīm did it or saw it. (b) The deck's connective "The answer came back:" is replaced by **"Allah said:"** on both beats, so the bar-1 property — that the command is in Allah's words — reaches the reader instead of living only in this table. (c) The `[after slaughtering them]` caveat has been moved up into the bar-2 cell, where the bar actually rests on it. (d) 21:87's `نَّقْدِرَ` — this deck's Name root inside a sibling deck's story āyah — has now been swept and is recorded in the collision table.)*

**Beat 6 · verse** *(the Name's own root is the operative word)*:
> "Is not that [Creator] Able to give life to the dead?" — Qur'ān 75:40

**Beat 7 · duʿā** *(catalog id 75, verbatim in full)*:
> يَا قَادِرُ لَا يَعْجِزُكَ شَيْءٌ فَاقْضِ لِي حَاجَتِي وَأَعِنِّي عَلَى مَا أَعْجَزَنِي
> *Ya Qadir, la ya'jizuka shay' faqdhi li hajati wa-a'inni 'ala ma a'jazani*
> "O Capable, nothing is beyond Your power. Fulfill my need and help me with what has left me helpless."

**Beat 8 · takeaway:**
> He already believed. He asked to be shown anyway — and what came back was not a rebuke, it was four birds and a hill.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | 2:260 — the instruction and the outcome are both Allah's speech: `ثُمَّ ٱدْعُهُنَّ يَأْتِينَكَ سَعْيًا`. The reviving is not narrated by a third party and is not asserted by the deck; it is stated by Allah as what will happen, inside the āyah the deck quotes. **R2 fix — this bar now reaches the user.** Revision 1 replaced the translation's `[Allāh] said` attributions with *"The answer came back:"* and dropped the attribution before *"Take four birds…"* entirely, so **on screen nobody was named as the speaker of the command** and the bar's whole content stayed inside this table. Both beats now render **"Allah said:"**. | **yes — beats 4 and 5, and now visibly** |
| 2 | **the distinguishing quality is shown, not stated** | Al-Qādir's distinguishing quality against `al-fattah@1` (the Opener) and `ash-shafi@1` (the Healer) is **power over what is finished**, not power over what is closed or wounded. The demonstration is chosen for that: the birds are not blocked or ill, they are **dead and dispersed across hills**, and they come back `سَعْيًا` — in haste. 75:40 states the same capacity as a rhetorical question. **⚠️ R2 — the caveat this bar rests on, moved here from row 3.3 where it was buried.** *"Dead"* is **not in the Arabic of 2:260.** It comes from Saheeh International's bracketed interpolation `[after slaughtering them]`; `فَصُرْهُنَّ إِلَيْكَ` says only *"incline / draw them toward you"*. Abdel Haleem renders the same clause *"train them to come back to you"* and drops the slaughter entirely, which would change the demonstration from *reviving the dead* to *homing behaviour* and would collapse this bar. **So bar 2 is met on a translator's reading, not on the bare Arabic.** The reading is the majority one and is what the āyah's own question `كَيْفَ تُحْىِ ٱلْمَوْتَىٰ` asks about — but the founder is signing a bar that depends on a bracket, and revision 1 named that fact in a sources row and then did not repeat it here. | **yes — beats 5 and 6, on the reading stated** |
| 3 | **does not collapse into a sibling Name** | No form of `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y` or `f-t-ḥ` appears on any beat. **Two disclosures:** (a) 2:260's un-quoted tail ends `وَٱعْلَمْ أَنَّ ٱللَّهَ عَزِيزٌ حَكِيمٌ` — Al-Azeez (8) and Al-Hakeem (26), **neither shipped nor in this batch**; (b) the Name's nearest live sibling is **Al-Muqtadir (76)**, which is not shipped, is not in this batch, and was deliberately not drafted alongside — see Authoring notes. **R2 — the within-batch adjacency has changed:** `al-waliyy@1` no longer anchors on 42:28, so the 42:29-`قَدِيرٌ` proximity is gone; the live one is now **`نَّقْدِرَ` inside `al-mujeeb@1`'s 21:87**, off-screen in both decks — see the collision table. **English pass (new bar-3 requirement, plan §7): run 2026-08-03 over every rendered string of all 14 shipped decks plus both draft batches.** This deck's distinctive strings — *"four birds"*, *"He was not corrected"*, *"Allah said"* — return **zero** hits outside this file. | **yes** |
| 4 | **the Name's own root appears in the source text** | **Yes — `بِقَـٰدِرٍ` is the operative word of 75:40**, rendered by Saheeh International as *"Able"*. **Disclosed honestly:** the catalogue's English for id 75 is *"The Capable"*, and the verse beat prints *"Able"*. Same root, same sense, **different English word** — so the user does not see the beat-2 word repeated on beat 6 the way `al-qayyum@1`'s user does. This is a partial criterion-(2) hit, not a full one, and it is not hidden. The root is **not** in 2:260. | **yes — beat 6, in a different English word** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **`verses/by_key/75:41` returns HTTP 404 — 75:40 is the final āyah of Sūrat al-Qiyāmah.** There is no successor at all. On the story side, 2:261 is the parable of the grain of corn. Full table below, **including the backward direction, which is the one place this deck has something to disclose.** | **yes — verified** |

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **2:260** (n+1) | 2:261 *"The example of those who spend their wealth in the way of Allāh is like a seed [of grain] which grows seven spikes… And Allāh multiplies [His reward] for whom He wills. And Allāh is all-Encompassing and Knowing."* | **clean** — the successor is multiplication, not punishment. |
| **2:260** (n−1) | 2:259 — the man who passed a ruined town, asked *"How will Allāh bring this to life after its death?"*, was made to die a hundred years and then revived, and said *"I know that Allāh is over all things competent"* (`قَدِيرٌ`, the Name-noun). | **clean, and it strengthens bar 1 — but it carries the deck's second disclosure.** 2:259 is a **century-long suspension of consciousness followed by an awakening**, which is structurally the same shape as `ar-raheem@1`'s three hundred years and nine in the cave. **It is not on any screen in this deck, and it is precisely why 2:259 was rejected as this deck's story** — see Authoring notes. The founder should know that a reader who scrolls one āyah up from the deck's story finds it. |
| **2:260** (the excerpt's own tail) | The quotation closes after *"…in haste."* The āyah's remaining clause is *"And know that Allāh is Exalted in Might and Wise."* | **clean — nothing withheld is a warning.** **Disclosure: the closing quotation mark on beat 5 is the deck's, not the source's** — Saheeh International runs on to the omitted clause before closing its own quotation. No word inside the quoted region is changed, added, dropped or reordered. |
| **75:40** (n+1) | **HTTP 404. 75:40 is the last āyah of Sūrat al-Qiyāmah**; the next text in the muṣḥaf is 76:1. | **clean, and this is the strongest single reason for this verse anchor** — the same sūrah-final signal that carried `al-haleem@1`'s 35:45. |
| **75:40** (n−1) | 75:39 *"And made of him two mates, the male and the female."* → 75:38, 75:37 *"Had he not been a sperm from semen emitted?"* — a creation argument running into the closing question. | **clean immediately, disclosed further back.** |
| **75:40, looking further *backwards*** | 75:31 is *"And he [i.e., the disbeliever] had not believed, nor had he prayed."* and 75:31–35 is a rebuke sequence ending *"Woe to you, and woe!"* | **disclosed.** Nine āyāt before the verse beat, Sūrat al-Qiyāmah is rebuking someone. It contradicts no beat and is not quoted, but `al-haleem@1` set the precedent of disclosing the backward direction, and a founder who opens `quran.com/75/40` and scrolls up will find it. **The āyāt immediately adjacent (75:36–39) are a creation argument, not rebuke.** |

### ⚠️ One line that was found, verified, and deliberately refused

**75:36 — Saheeh International: *"Does man think that he will be left neglected?"* Abdel Haleem: *"Does man think he will be left alone?"*** (both fetched, 2026-08-03).

It is four āyāt before this deck's verse beat, it is the most quotable line in the passage for a pack about abandonment, and **using it would be a misreading.** `سُدًى` means *without command, without accountability* — the āyah is a rebuke of the person who assumes he will not be called to account, not a reassurance to a person who feels forgotten. Abdel Haleem's *"left alone"* makes the misreading more tempting, not less.

**Recorded here so that nobody adds it later**, and offered as evidence that the successor sweep was run as a reading of the passage rather than a scan of verse numbers.

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 3.1 | Beat 3: Ibrāhīm asked to be shown something he already believed | paraphrase of 2:260, whose own exchange establishes both halves (`أَوَلَمْ تُؤْمِن` / `بَلَىٰ`) | [Qur'ān 2:260](https://quran.com/2/260) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/2:260?translations=20,85`, 2026-08-03. **Labelled paraphrase**; the beat asserts nothing the āyah does not carry, and beat 4 quotes the exchange it summarises. |
| 3.2 | Beat 4, three verbatim quotations: "My Lord, show me how You give life to the dead." / "Have you not believed?" / "Yes, but [I ask] only that my heart may be satisfied." | **Saheeh International.** Abdel Haleem fetched and compared: *"My Lord, show me how You give life to the dead"* / *"Do you not believe, then?"* / *"Yes… but just to put my heart at rest."* — *"put my heart at rest"* is warmer English than *"that my heart may be satisfied"*, and it does **not** say "God" in this āyah. **This is the second-most defensible Abdel Haleem row in the batch and the founder can take it; the strings are fetched and ready.** Rejected only for batch consistency. | [Qur'ān 2:260](https://quran.com/2/260) | Qur'ān | ✅ **verified — substring tests re-run programmatically 2026-08-03 against `api.quran.com/api/v4/verses/by_key/2:260?translations=20`: each of the three is a byte-exact substring of the RAW fetched string** (the āyah carries exactly one `<sup>`, at offset 246, i.e. inside the *"Take four birds…"* region of row 3.3 and nowhere near these three). **Disclosure, changed in R2:** the connectives now read *"He said:"* / **"Allah said:"** / *"He said:"*, replacing the translation's `[Allāh] said` / `He said`. Revision 1 used *"The answer came back:"* here and no attribution at all on beat 5; the verdict's finding was that bar 1 then never reached the reader. The deck still declines to print the bracketed `[Allāh]` on a beat — it prints the unbracketed name instead, which asserts nothing the bracket does not. **No word inside any quoted region is changed.** The bracket `[I ask]` is the translator's own and is retained. |
| 3.3 | Beat 5 quotation, verbatim: "Take four birds and commit them to yourself. Then [after slaughtering them] put on each hill a portion of them; then call them - they will come [flying] to you in haste." | **Saheeh International.** Abdel Haleem: *"Take four birds and train them to come back to you. Then place them on separate hilltops, call them back, and they will come flying to you"* — **materially different**: *"train them to come back"* renders `فَصُرْهُنَّ إِلَيْكَ` as training and **drops the slaughter entirely**, which changes what is being demonstrated from *reviving the dead* to *homing behaviour*. **This is a contested reading and Saheeh International's is the one that matches the āyah's own question (`كَيْفَ تُحْىِ ٱلْمَوْتَىٰ`).** Recorded because it is the batch's clearest case of a translation choice doing theological work — the `al-kareem@1` finding, in the other direction. **R2: this caveat is now also stated in the bar-2 cell, because that is the bar it holds up.** | [Qur'ān 2:260](https://quran.com/2/260) | Qur'ān | ✅ **verified — byte-exact substring after stripping one `<sup>` footnote marker** that falls inside the quoted region, immediately after *"commit them to yourself."* Nothing else removed. Both brackets are the translator's own and are retained. **The closing quotation mark is the deck's** — see the successor table. Arabic: `فَخُذْ أَرْبَعَةً مِّنَ ٱلطَّيْرِ فَصُرْهُنَّ إِلَيْكَ ثُمَّ ٱجْعَلْ عَلَىٰ كُلِّ جَبَلٍ مِّنْهُنَّ جُزْءًا ثُمَّ ٱدْعُهُنَّ يَأْتِينَكَ سَعْيًا`. |
| 3.4 | Beat 5's closing line: **"He was not corrected. He was given something to do, and told what would happen."** | — | authored | n/a | ✅ **honest label — authored copy, not a source claim, and this is the R2-corrected row.** Revision 1 read *"He was not corrected. **He was shown.**"* and this table defended only the weaker half of that (*"an instruction rather than a reproof"*). **The verdict was right: 2:260 stops at the instruction and at Allah's statement of what will happen (`يَأْتِينَكَ سَعْيًا`). It does not narrate that Ibrāhīm took the birds, and it does not narrate that he saw anything.** *"He was shown"* was the deck's inference printed as completed fact. The replacement reports only the two things the āyah contains: an instruction (`فَخُذْ … ثُمَّ ٱجْعَلْ … ثُمَّ ٱدْعُهُنَّ`) and a statement of outcome in the imperfect (`يَأْتِينَكَ`). **Consequence, taken deliberately:** beat 8 still says *"what came back was not a rebuke, it was four birds and a hill"* — which is about **what he was given**, not about what he witnessed, and is true of the āyah as it stands. |
| 3.5 | Beat 6, verse anchor, verbatim in full: "Is not that [Creator] Able to give life to the dead?" | **Saheeh International.** Abdel Haleem: *"Does He who can do this not have the power to bring the dead back to life?"* — longer, and it dissolves the single word carrying the Name into *"have the power"*. Rejected. | [Qur'ān 75:40](https://quran.com/75/40) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. **Byte-exact**; the fetched string carries **no footnote marker**. The bracket `[Creator]` is the translator's own and is retained rather than silently dropped — without it the demonstrative has no antecedent in English. Arabic: `أَلَيْسَ ذَٰلِكَ بِقَـٰدِرٍ عَلَىٰٓ أَن يُحْـِۧىَ ٱلْمَوْتَىٰ`. **Position verified: `verses/by_key/75:41` returns HTTP 404.** |
| 3.6 | Duʿā text | catalog id 75 — **no scripture citation claimed** | catalog only | n/a | ✅ **verified byte-identical to catalog** across `dua_arabic` / `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03. It is an authored catalogue invocation, it names the Name (`يَا قَادِرُ`), and it is the batch's tightest duʿā-to-register match: *"help me with what has left me helpless."* |
| 3.7 | Beat 2 `name_intro` | catalog id 75 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`. |
| 3.8 | **Not on any beat, kept verified:** the alternative verse anchor | Saheeh International | [Qur'ān 36:81](https://quran.com/36/81) · [36:82](https://quran.com/36/82) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. *"Is not He who created the heavens and the earth Able to create the likes of them? Yes, [it is so]; and He is the Knowing Creator."* → 36:82 *"His command is only when He intends a thing that He says to it, 'Be,' and it is."* Also carries `بِقَـٰدِرٍ`, and its successor is one of the most quotable āyāt in the Qur'ān. **Rejected only because it is about creating *likes* of people rather than reviving the dead**, which is the exact thing beat 4 asks about. **One line away if the founder prefers it.** |

### ✅ Catalog-level flag — RESOLVED by the catalogue track while this revision was being written

**Revision 1 flagged catalog id 75's `hadith` field as carrying a quoted prophetic saying with no number that is not, as printed, a locatable narration:**

> *"The Prophet ﷺ said: 'Nothing is beyond the power of Allah.' Al-Qadir parts seas and revives the dead… **(Muslim)**"*

**As of 2026-08-03 that field is EMPTY.** Re-read from `assets/content/collectible_names.json` this pass: `id 75 hadith == ''`. A concurrent catalogue-repair pass removed it as unlocatable. **The flag is closed, and the finding was correct.**

**Two consequences for this deck, both benign:**

1. **Nothing in this deck ever cited that field**, so no beat, no row and no bar moves. The deck is unaffected on the merits.
2. **The card is now silent where it used to contradict.** A user who meets this deck and then Al-Qādir's Name card no longer meets an unnumbered quotation attributed to the Prophet ﷺ. That is strictly better for the deck.

**This deck does not request a replacement.** A ṣaḥīḥ substitute is understood to exist and to have been deliberately withheld (Bukhārī 6398's clause `وَأَنْتَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ`). **It is not needed here**: bar 4 is already met on the verse beat by 75:40's `بِقَـٰدِرٍ`, the deck's duʿā is an authored catalogue invocation with no citation claimed, and adding a third quotation of one duʿā to the Name's surface would create exactly the kind of repetition this batch has been rejecting elsewhere. **Recorded so the founder can see the option was offered and declined with a reason, not overlooked.**

### Ship-gate note — **this deck must carry NO duʿā `source`**

`renderedDuaSources` is asserted **in both directions** (commit `a12f1db`). **The duʿā beat's `source` field must be empty, and `al-qadir@1` must NOT be added to `renderedDuaSources`.** Verified: the full gate passes over `existing ∪ batch 2` with this deck unpinned.

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 19 existing decks

| existing deck | its inventory | collides? |
|---|---|---|
| `as-salam@1` · `al-wakeel@1` · `al-wadud@1` · `al-hadi@1` | 13:28, 9:40, 59:23, Bukhārī 3653, Muslim 591 · 3:172–174, 65:3, Bukhārī 4563 · 11:90, Muslim 2747a, Bukhārī 6309 · 28:22, 28:15/21/23, 22:54, 1:6 | ✖ none on citations — **but see the insight table for `al-hadi@1`, which is this deck's real adjacency.** |
| `al-ghaffar@1` · `at-tawwab@1` | Bukhārī 7507, 39:53 · Bukhārī 3470, **2:37** | ⚠️ **shared sūrah, nothing else** — 2:37 vs 2:260, no shared āyah, no shared quotation, and different engines entirely (return and acceptance vs. power over the finished). |
| `ar-rahman@1` | **2:286**, 7:156, 55:1, Bukhārī 5999 | ⚠️ **shared sūrah, nothing else** — 2:286 vs 2:260, twenty-six āyāt apart. Disclosed because 2:286 is the verse a user is most likely to have already met in this app. |
| `al-jabbar@1` · `al-lateef@1` · `ash-shafi@1` · `ar-razzaq@1` · `al-fattah@1` · `al-baseer@1` · `as-samad@1` | 12:84/86/87/18/94/96 · 12:100/15/20/42, 42:19, 67:13 · 21:83–84, 26:80, Bukhārī 5743 · 65:2–3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/2731 · 58:1, Bukhārī 3364, Ibn Mājah 188 · 19:2–7, 112:2 | ✖ none. **`ash-shafi@1` is worth a word:** its Ayyūb is *restoration after affliction*, this deck's Ibrāhīm is *demonstration to a believer who asked*. No shared citation, no shared protagonist, no shared insight. |
| **batch-1 drafts** | `al-afuw@1` · `al-ghafur@1` · `al-kareem@1` · `al-haleem@1` (Bukhārī 7378, 19:90–91, 35:45) · **`ar-raheem@1`** (18:10/11/18, 33:43) | ✖ **no shared citation. One structural adjacency, off-screen:** `ar-raheem@1`'s story is a centuries-long sleep and an awakening, and **2:259 — the āyah immediately before this deck's story — is a century-long death and a revival.** 2:259 is on no screen here and is not quoted; it is disclosed because it is one scroll away and because it is the reason it was rejected as the story. |
| **batch-2 siblings** | `al-mujeeb@1` (21:87–88, 2:186, Tirmidhī 3505) · `al-qayyum@1` (**R2:** Bukhārī 595, 39:42, 2:255) · **`al-waliyy@1`** (**R2:** 93:6, Muslim 1342, Tirmidhī 3438) · `al-muid@1` (30:27, Muslim 918a) | ⚠️ **two within-batch adjacencies, both off-screen, both disclosed.** **(a) — added in R2, and it is the sweep the verdict said was missing.** `al-mujeeb@1`'s own story āyah **21:87 contains `نَّقْدِرَ`** — *this deck's Name root*, in a negated form, with Allah as subject (*"and thought that We would not decree [anything] upon him"*). **Verified by fetch, 2026-08-03**: the word is present in `text_uthmani` for 21:87. It reaches **no screen in either deck** — `al-mujeeb@1`'s quoted region begins after it, and story beats carry `arabic: ""` — and the English *"decree"* does not collide with this deck's *"Able" / "Capable"*. **Non-blocking; recorded because §7 asks for the scan and revision 1 did not run it.** **(b)** Revision 1 disclosed `al-waliyy@1`'s 42:29 `قَدِيرٌ` adjacency; **that adjacency no longer exists** — `al-waliyy@1` R2 dropped 42:28 as its verse beat. Recorded so the change is visible rather than silently deleted. |

**Verified negative, run programmatically:** **2:260 and 75:40** appear in **no** shipped deck and **no** batch-1 draft.

**Insight-level check.** Beat 8 — *"He already believed. He asked to be shown anyway — and what came back was not a rebuke, it was four birds and a hill."*

| checked against | its insight | verdict |
|---|---|---|
| `al-hadi@1` (shipped) | *"Even the strongest believers ask 'guide us' in every prayer, every day. **Needing guidance was never falling behind — asking for it is the prayer itself.**"* | ⚠️ **this deck's real insight adjacency, and the reason beat 8 was rewritten.** Both decks make the move *"the thing you are ashamed of needing is a thing believers do."* An earlier beat 8 read *"Asking to be shown is not the opposite of believing. It is what a believer did, out loud"* — **that is `al-hadi@1`'s aphorism in a different noun**, and it was cut for that reason. The shipped version keeps the aphoristic shape; this deck's now ends on a **concrete image** (four birds and a hill) rather than a maxim, and its subject is **certainty**, not **direction**. **Disclosed rather than declared resolved:** if the founder reads the two together and still hears one idea, beat 8 is what to change. |
| `al-fattah@1` (shipped) | *"None of the gatekeepers you fear… can withhold what He opens."* | ✖ none — that is about **obstruction**, this is about **finality**. |
| `ash-shafi@1` (shipped) | *"The answer to Ayyūb was not repair. It was more than there was before the breaking."* | ✖ none — that is about the **size** of the answer; this is about **being allowed to ask**. |
| `al-lateef@1`, `as-samad@1`, `at-tawwab@1`, `al-haleem@1`, `al-kareem@1` | visible only from the far side · leaning is not weakness · acceptance met him mid-road · the distance between earned and done · the supply does not run down | ✖ none |

### Authoring notes (candidates considered)

- **Selected: Ibrāhīm and the four birds (2:260), anchored on 75:40.** Three properties no other candidate had together: (a) **the struggle in the story is the reader's own** — belief without felt certainty, stated in the first person by a prophet, which is the format spec's hardest criterion and the one `al-haleem@1` was criticised for missing; (b) a **sūrah-final verse anchor** carrying the Name's own root, i.e. bar 5 at its maximum; (c) it is **not a story this app or its competitors lead with**, so it arrives new.
- **Rejected as the story — Qur'ān 2:259**, the man who passed the ruined town, died a hundred years and was revived. Fetched and read whole; it is verified in the successor table. It has the Name-noun in-text at its own resolution (`أَعْلَمُ أَنَّ ٱللَّهَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ`) and it is, on its own, a better *demonstration* than 2:260. **Rejected on collision:** a centuries-long suspension of consciousness followed by an awakening is `ar-raheem@1`'s exact narrative shape, and that deck is in the batch immediately before this one. Batch 1 lost a deck to precisely this class of miss.
- **Rejected as the Name for this material — Al-Muhyi (catalog id 69, "The Giver of Life").** Its root `ḥ-y-y` is in 2:260 (`تُحْىِ`) and in 75:40 (`يُحْـِۧىَ`), so on bar 4 it scores **higher** than Al-Qādir does, and its catalogue duʿā — *"revive my heart with faith and revive the hopes that this world has killed"* — is the single most ICP-resonant string in the whole catalogue. **It was not taken because it and Al-Qādir cannot both use this passage, and because Al-Muʿīd (id 68) is already in this batch on restoration.** Three Names within one semantic field in one batch is the bar-3 failure mode. **Recommendation: Al-Muhyi is the strongest single batch-3 candidate, and this deck deliberately leaves 30:50 and 41:39 free for it.**
- **Rejected as the verse anchor — Qur'ān 46:33** (`بِقَـٰدِرٍ عَلَىٰٓ أَن يُحْـِۧىَ ٱلْمَوْتَىٰ`, near-identical to 75:40). **Bar 5:** 46:34 immediately reads *"And the Day those who disbelieved are exposed to the Fire…"*. 75:40 has no successor at all, which is why it wins.
- **Rejected as the verse anchor — Qur'ān 30:50** (`إِنَّ ذَٰلِكَ لَمُحْىِ ٱلْمَوْتَىٰ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ`). Fetched. Both Names in-text and a beautiful image (*"how He gives life to the earth after its lifelessness"*). **Held back for Al-Muhyi** rather than rejected on a defect, and named so the founder can see the batch is not taking every good verse it finds.
- **Rejected — Qur'ān 75:36.** See the box above. It is the passage's most quotable line and reading it as comfort is a misreading.
- **Register check:** no beat attributes waiting, wanting or withholding to the Name. Beat 8 reports the exchange and **makes no promise to the reader** — it does not say the reader will be shown. The catalogue's `lesson` line (*"What seems impossible to you is effortless for Al-Qadir"*) was deliberately **not** used as the takeaway, because a deck for a person whose situation has not lifted should not close by telling them their situation is easy to fix.
