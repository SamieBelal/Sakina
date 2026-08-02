# Deck Draft — Al-Haleem (mercy/forgiveness pack, Wave G pilot 4 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

**Revision 3 — 2026-08-02. Second full re-source. Founder ruling: do not cut this Name.**

This deck has now failed twice, and both failures were the same failure wearing different clothes — the Name was carried by something adjacent to it rather than demonstrated.

- **Revision 1 (Uḥud, 3:152 + 3:155) was rejected** because both climax quotations turn on `عَفَا` — the root of **al-ʿAfuww**, a sibling deck in this batch. Outright pardon was demonstrated; ḥilm was demonstrated nowhere and entered only through the trailing epithet `غَفُورٌ حَلِيمٌ`.
- **Revision 2 (Pharaoh, 20:42–45 + 28:4 + 79:24) was rejected on two counts.**
  - **A factual error about scripture.** Beat 4 said "the whole of the instruction they carried was this" and beat 5 said "Not a warning. Not a deadline." **20:47–48 is inside the deck's own cited passage and is explicitly a warning of punishment** — fetched again for this revision: 20:47 *"So go to him and say, 'Indeed, we are messengers of your Lord, so send with us the Children of Israel and do not torment them…'"*; 20:48 *"Indeed, it has been revealed to us that the punishment will be upon whoever denies and turns away.'"* Row 4.4's ✅ verified that 20:44 is one āyah and is entirely that sentence — true — while the *beat* claimed 20:44 was the whole instruction, which is false. **The ✅ answered a different question than the beat asked.** That is the defect class this pipeline exists to catch and it shipped anyway.
  - **The deck broke its own stated rule.** It rejected Nūḥ (29:14) for *"stops short of the verse's own ending (dishonest excerpt)"* — then quoted 79:24 and stopped short of **79:25**, fetched: *"So Allāh seized him in exemplary punishment for the last and the first [transgression]."* Plus 10:90–92 (drowning; the tawba explicitly refused) and 40:46. On the most famous "too late" in scripture, in a mercy pack, at night.

Revision 3 is built against the five bars the founder set, and **§"The five bars, one by one" below shows where each one is met, in fetched text.** Nothing in revision 2 survives except the bridge beat and the duʿā flag.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G. Author: Claude, 2026-08-02.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com` against the canonical `quran.com/{surah}/{ayah}` reference; ḥadīth via Wayback archive of the exact `sunnah.com` URL (sunnah.com returns HTTP 403 to automated fetching). Scripture is quoted exactly from the fetched pages; story beats paraphrase only what the cited source carries.

**Translation standard for this deck (founder ruling A1 — most appropriate per Name, never at the cost of authenticity; Abdel Haleem is the named second option where Saheeh International reads stiffly).** Every quotation below is **Saheeh International** (`resource_id: 20`). The choice is named per row, with the Abdel Haleem alternative fetched and compared. See **§"The 126-translation correction"** — the premise revisions 1–2 gave for this standard was factually wrong.

**Implementation note (binding):** every beat stores Arabic / transliteration / translation as **separate fields**. The em-dash formatting below is markdown shorthand only, never a single mixed-direction `Text`.

---

## The 126-translation correction (batch-wide, and it changed a real decision)

Revisions 1–2 of all five decks said: *"`api.quran.com/api/v4/resources/translations` currently lists **eight** English translations and Khattab is not among them."*

**That is false.** `GET /api/v4/resources/translations?language=en` returns **126** entries (re-fetched 2026-08-02, counted programmatically).

What is true, and what the conclusion actually rested on: **Khattab (`resource_id: 131`) is genuinely absent from that list**, and `/quran/translations/131?verse_key=…` genuinely returns `{"translations":[]}` while `…/20` returns text. Both reproduced 2026-08-02. So Khattab still cannot be quoted, and the fetch-first rule still forbids quoting it from memory. **But the reason given was wrong, and it foreclosed options that are live** — chiefly **M.A.S. Abdel Haleem (`resource_id: 85`)**, which is live and has now been fetched for every quoted row in this deck.

**What re-running the choice against the real list changed for this deck.** The single strongest instance the false premise hid was revision 2's own: Saheeh International 20:44 reads *"…that perhaps he may be reminded or fear [Allāh]"* — a translator's bracket propping up a dangling intransitive — and the deck said "a smoother rendering exists" but is unreachable. **It is reachable. Abdel Haleem 20:44, fetched: *"Speak to him gently so that he may take heed, or show respect."*** No bracket, no dangling verb. That row would have been improved. It is recorded here because the premise cost a real decision — but **20:44 is no longer in this deck**, because revision 2 was rejected on substance (see the header) and the passage is gone.

For the rows this deck now carries, both translations were fetched and compared:

| row | Saheeh International (`20`) — **used** | Abdel Haleem (`85`) — fetched, not used | why |
|---|---|---|---|
| 19:90–91 | "The heavens almost rupture therefrom and the earth splits open and the mountains collapse in devastation" / "That they attribute to the Most Merciful a son." | "it almost causes the heavens to be torn apart, the earth to split asunder, the mountains to crumble to pieces," / "that they attribute offspring to the Lord of Mercy." | Abdel Haleem's 19:90 opens lower-case mid-sentence (it continues 19:89) and cannot start a beat without editing. Saheeh International's pair is self-contained. |
| 35:45 | "And if Allāh were to impose blame on the people for what they have earned…" | "If **God** were to punish people [at once] for the wrong they have done… He gives them respite for a stated time and, whenever their time comes, **God** has been watching His servants." | Abdel Haleem is markedly more readable here — "gives them respite for a stated time" is better English than "defers them for a specified term". **It says "God".** See the batch finding below. |

**The batch-wide finding that decided every row in all five decks:** Abdel Haleem renders the divine name as **"God"**, not "Allāh", and lower-cases the Names (`most forgiving`, `merciful`, `most generous`) where Saheeh International capitalises them. Against 14 shipped decks that all say "Allah", adopting it would break the app's core vocabulary mid-pack; and in exactly the rows where a deck's point is *the Name appearing in the verse*, it would delete the visual Name. So **Abdel Haleem is compared and named per row, and adopted nowhere in this batch.** If the founder wants readability to win on 35:45 specifically, Abdel Haleem's string is above and verified, and the cost is "God" on a reveal beat.

**The discontinuity that remains, stated plainly rather than left to be inferred:** the 14 shipped decks lean **Khattab** in register — `al-wakeel@1` (`˹alone˺`), `at-tawwab@1` (`˹of prayer˺`), `as-samad@1` (`˹needed by all˺`), and `ash-shafi@1`'s sources array literally pins *"Khattab rendering"*. These five ship in Saheeh International. `ar-rahman@1`'s founder-decided Saheeh International comfort verse is the precedent that mixing is permitted, so this is defensible — but it is a real register mix and the founder is signing it.

---

## Deck `al-haleem@1` — Al-Haleem

**Proposed metadata**

```json
{
  "deck_id": "al-haleem@1",
  "name_id": 29,
  "transliteration": "Al-Haleem",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You already know what you did. What you are actually carrying is how long it gets held against you.

**Beat 2 · name_intro** *(from `collectible_names.json` id 29, verbatim)*:
> الْحَلِيمُ — Al-Haleem — The Forbearing

**Beats 3–5 · story — "The words He hears":**
> 1. The Qur'ān records what creation does when a certain thing is said about Allah: **"The heavens almost rupture therefrom and the earth splits open and the mountains collapse in devastation — That they attribute to the Most Merciful a son."**
> 2. Of the people who say it, the Prophet ﷺ said: **"None is more patient than Allah against the harmful and annoying words He hears (from the people): They ascribe children to Him,…"**
> 3. **"…yet He bestows upon them health and provision."** The words are heard. The provision does not stop.

**Beat 6 · verse:**
> "And if Allāh were to impose blame on the people for what they have earned, He would not leave upon it [i.e., the earth] any creature. But He defers them for a specified term. And when their time comes, then indeed Allāh has ever been, of His servants, Seeing." — Qur'ān 35:45

**Beat 7 · duʿā** *(catalog id 29, verbatim in full)*:
> اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ
> *Allahumma inni as'alukas-sabra wa a'udhu bika minal-jaza'*
> "O Allah, I ask You for patience and I seek refuge in You from anxiety and distress."

**Beat 8 · takeaway:**
> Forbearance is not approval, and it is not forgetting. It is the distance between what a thing has earned and what is actually done about it. Every hour anyone has ever been given was inside that distance.

---

### The five bars, one by one

The founder set five bars for this revision. Each is met **in fetched text**, not by assertion, and each is on screen:

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **a real offence deserving punishment** | 19:90–91 — the offence is not merely named, the Qur'ān states creation's own reaction to it: the heavens near rupture. This is the theological maximum (`shirk`, attributing a son), stated in Allah's own words about Himself. Bukhārī 7378 names the same offence again in the Prophet's ﷺ words: *"They ascribe children to Him."* | **yes — beats 3 and 4** |
| 2 | **Allah's retained power to punish** | 35:45 states it as a counterfactual: *"if Allāh were to impose blame on the people for what they have earned, He would not leave upon it any creature."* Not one creature would remain. The capacity is total and is stated by the text, not inferred by the deck. | **yes — beat 6** |
| 3 | **deliberate withholding / postponement** | 35:45: *"**But He defers them** for a specified term."* — `وَلَـٰكِن يُؤَخِّرُهُمْ إِلَىٰ أَجَلٍ مُّسَمًّى`, an active verb with Allah as subject. And Bukhārī 7378 gives the same thing concretely, in sequence: the Arabic reads `يَدَّعُونَ لَهُ الْوَلَدَ، **ثُمَّ** يُعَافِيهِمْ وَيَرْزُقُهُمْ` — *they say it, **then** He grants them health and provision*. The withholding is not passive silence; it is the provision arriving anyway. | **yes — beats 5 and 6** |
| 4 | **does not collapse into a sibling Name** | **No form of `gh-f-r` and no form of `ʿ-f-w` appears in any beat, in Arabic or in English.** Nothing is pardoned and nothing is erased anywhere in this deck: the people in Bukhārī 7378 are not forgiven, they are *sustained*, and 35:45's people are not pardoned, they are *deferred*. The operative verbs are `أَصْبَرُ` (none more patient), `يُعَافِيهِمْ` / `يَرْزُقُهُمْ` (grants health / provision) and `يُؤَخِّرُهُمْ` (defers). **This is why the previous verse beat was dropped — see the next section.** One disclosure, made rather than hidden: `يُعَافِيهِمْ` is form III of the triliteral `ʿ-f-w/ʿ-f-y`, i.e. a lexical relative of `ʿafw`. Its sense here is `ʿāfiya` — bodily well-being — and the published English renders it "health", carrying no pardon sense. It is named because this deck died once on a root collision and the founder should not discover the relation on his own. | **yes — by construction** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **The rule is applied to this deck, in writing, in §"What comes immediately after each excerpt" below.** Headline: **35:45 is the final āyah of Sūrat Fāṭir** — there is no next āyah (36:1 is `يس`) — and it closes on *"then indeed Allāh has ever been, of His servants, **Seeing**"*, not on a punishment. That is the opposite of 16:61, whose own second half turns to *"they will not remain behind an hour."* | **yes — verified** |

### What comes immediately after each excerpt (the rule revision 2 broke, applied to revision 3)

| excerpt | what is immediately after it, fetched 2026-08-02 | verdict |
|---|---|---|
| **19:90–91** | 19:92 *"And it is not appropriate for the Most Merciful that He should take a son."* → 19:93 *"There is no one in the heavens and earth but that he comes to the Most Merciful as a servant."* → 19:96 *"Indeed, those who have believed and done righteous deeds — the Most Merciful will appoint for them **affection**."* | **clean.** The local arc runs *toward* `وُدًّا`, not toward punishment. **Disclosed anyway:** the sūrah's own last āyah, seven āyāt later, is 19:98 *"And how many have We destroyed before them of generations?"* That is the end of a sūrah, not the end of this passage — but revision 2 was rejected for not looking, so this deck looked and is telling you. |
| **Bukhārī 7378** | Nothing. It is a single free-standing narration in *Kitāb at-Tawḥīd* with no narrative continuation and no consequence clause. Full page text reproduced in row 4.2. | **clean, and structurally clean** — there is no "next āyah" to be dishonest about. |
| **35:45** | **Nothing in the sūrah.** 35:45 is the last āyah of Sūrat Fāṭir; the next text in the muṣḥaf is 36:1, `يس`. | **clean, and this is the strongest single reason for the selection.** |
| **35:45, looking *backwards*** | 35:42–44 do carry warning material — 35:44 is *"Have they not traveled through the land and observed how was the end of those before them?"* | **disclosed.** The sūrah raises the fate of earlier peoples and then **answers it with 35:45**, which is the deck's verse beat. A founder who opens `quran.com/35/45` and scrolls up will find warning āyāt; he should know that going in, and he should also see that the āyah the deck chose is the passage's own resolution of them. |

### Why the verse beat is 35:45 and no longer 35:41 — and the one-line alternative

Revision 2's verse beat was **35:41**, *"Indeed, Allāh holds the heavens and the earth, lest they cease… Indeed, He is Forbearing and Forgiving."* It is verified (live fetch, 2026-08-02, byte-exact) and it has the Name in-text: `إِنَّهُ كَانَ حَلِيمًا غَفُورًا`. It was dropped for one reason:

**`غَفُورًا` is Al-Ghafūr — catalog id 51 — which is a sibling deck shipping in this same batch.** Round 2 of the adversarial review flagged this (H3) and called it non-blocking; it is being treated as blocking here, because this deck has already been rejected once for putting a sibling Name's root on its climax screen, and "the sibling root is only in the *epithet* this time" is exactly the argument revision 1 lost with.

**What it costs, stated plainly: no beat in this deck now carries the Name-noun `حَلِيم` in its source text.** On the protocol's selection criterion (2) — *"best of all when the Name/phrase appears IN the source text"* — this deck now scores **low**, the same as `ar-raheem@1` and `al-kareem@1` in this batch, both of which disclose the same. The Name is on screen only at beat 2, from the catalog. **This is the deck's largest single weakness and it is not hidden.**

**The alternative, if the founder weighs it the other way:** put 35:41 back as beat 6. It is verified and ready. The trade is *Name-in-text* against *a sibling deck's Name printed on this deck's verse beat*, plus 35:41's neighbourhood (35:44's warning three āyāt later) against 35:45's (sūrah-final, closes on `بَصِيرًا`). One line either way.

**Two other Name-in-text candidates were checked and rejected, so the founder knows the field was swept, not skimmed:**
- **22:59** (`وَإِنَّ اللَّهَ لَعَلِيمٌ حَلِيمٌ`, fetched) — Name in-text, warm context, no sibling root *in* the āyah. Rejected because `ḥalīm` there is a closing epithet with no forbearance demonstrated anywhere in the passage (it is about those who emigrated and were killed) — i.e. **teaching the Name by epithet adjacency, which is precisely what revision 1 was rejected for.** Also, 22:60 — the very next āyah — closes `إِنَّ اللَّهَ لَعَفُوٌّ غَفُورٌ`: *both* sibling Names, one āyah away.
- **2:225, 2:235, 2:263, 17:44, 64:17** (all `ḥalīm` endings) — every one of them pairs `ḥalīm` with `gh-f-r` in the same clause (`غَفُورٌ حَلِيمٌ`, `مَغْفِرَةٌ`, `يَغْفِرْ`). **There is no āyah in the Qur'ān that puts `ḥalīm` in-text, demonstrates forbearance in its own passage, and keeps clear of both sibling roots.** That is a real property of the text, and it is why this deck accepts the criterion-(2) miss rather than manufacturing a pass.

### The honest weakness the founder must weigh: beats 3–5 are not a narrative

The format spec's beats 3–5 rule reads *"Prophet/companion **narrative**, 1–2 sentences per beat."* **This deck does not have one.** It has three quoted texts arranged as offence → response → response-continued. Two full re-sources produced this conclusion, and it is worth stating why rather than apologising for it:

**Ḥilm is the un-ended interval, and scripture narrates intervals from their endings.** Every candidate narrative sweep hit the same wall:

| candidate | why it fails a bar |
|---|---|
| Pharaoh (20:42–48, 79:23–25) — revision 2 | **bar 5.** 20:48 is a warning inside the cited passage; 79:25, 10:90–92 and 40:46 terminate the arc in punishment and a refused tawba. |
| Nūḥ, 950 years (29:14, Sūrat Nūḥ) | **bar 5.** Terminates in the flood. |
| Uḥud (3:152, 3:155) — revision 1 | **bar 4.** Both climax verbs are `عَفَا` — al-ʿAfuww's root. |
| The people of Yūnus (10:98) — the only town in the Qur'ān whose punishment was lifted | **bar 3/4.** `كَشَفْنَا عَنْهُمْ` is removal *after they believed* — the engine is tawba, and this pack already ships `at-tawwab@1` and `al-ghaffar@1` and is adding `al-ghafur@1` and `al-afuw@1`. Same ground `ar-raheem@1` rejected Kaʿb b. Mālik on. |
| Iblīs granted respite (7:14–15, 15:36–38) | Textbook deferral of deserved punishment — and **register**, plus **bar 5** (7:18). Unusable in a mercy pack. |
| 8:33 (*"Allah would not punish them while you are among them"*) | **bar 5.** 8:34 immediately reads *"But why should Allah not punish them…"* |
| Ibrāhīm arguing for the people of Lūṭ (11:74–76) | The `ḥalīm` in the passage is **Ibrāhīm's** — a human attribute. Fails the reverence line the format spec draws, and terminates in Lūṭ's people being destroyed. |
| The bedouin in the mosque (Bukhārī 6025), Ṭāʾif (Bukhārī 3231) | The forbearance recorded is the Prophet's ﷺ. Same reverence line; Ṭāʾif was already rejected on this ground by `al-afuw@1`. |

**So the founder's decision is a clean one, and it is the one the brief asked for:**

- **Sign it** — accepting three quoted texts in the story slot in exchange for a deck that clears all five substantive bars, whose Name-engine is demonstrated in three independent fetched sources, and which agrees with its own Name card (see below).
- **Cut Al-Ḥalīm from the pilot** — if the beats-3–5 *narrative* rule is absolute. That is a legitimate outcome and it is far better than a fourth compromise. **I am not recommending it**, because a rule about beat shape should not outrank five rules about truth, and because this construction is the one arrangement of verified text in which none of the five bars has to be argued for.

One precedent, in fairness: `al-afuw@1` in this same batch builds three beats out of one question and one answer and fills its middle beat with a Qur'ānic fact rather than narrative. The gap between that deck and this one is smaller than it looks.

### The catalog agrees with this deck — which is new in this batch

Every other deck in this batch had to flag a **contradiction** with its own Name card (`al-kareem@1` K6, `al-afuw@1` A2, `ar-raheem@1` R5, `al-ghafur@1` flag ②). This one flags the opposite. Catalog id 29's `hadith` field reads:

> *"The Prophet ﷺ said: 'No one shows more patience upon hearing abuse than Allah — they attribute a son to Him, yet He still gives them health and provision.' (Bukhari)"*

**That is this deck's story.** A user who meets the deck and then the Name card meets the same narration twice, in two renderings, with no contradiction to resolve. Selection criterion (2) — direct correlation to the Name — is met by the app's own catalog, independently of my judgement. (The catalog's wording is a looser rendering than sunnah.com's; the deck quotes sunnah.com's published English, which is the verified string.)

### Register risk, faced

Revision 2's register risk was Pharaoh. This one's is different and must be named: **beat 3 quotes the Qur'ān on people who say Allah has taken a son, which reads as pointed at Christians.** Three things bear on it, and the founder should weigh them himself:

1. **The order of the beats defuses it deliberately.** Beat 4 and beat 5 land on those same people being given *health and provision*. The story's argument is that they are sustained, not that they are condemned. If beat 3 and beat 5 were swapped, the story would end on rupture; as built it ends on provision.
2. **No beat says anything about them beyond what the two sources say.** There is no "unlike you", no comparison to the reader, and the takeaway never mentions them.
3. **It is nonetheless a sharper edge than the rest of the pack carries**, and if the founder reads beat 3 and feels the pack turn polemical, that is the correct thing to fail this deck on. There is no substitute story if he does — see the candidate table above. That failure means cutting the Name.

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 4.1 | Beat 3 quotation, verbatim: "The heavens almost rupture therefrom and the earth splits open and the mountains collapse in devastation — That they attribute to the Most Merciful a son." | **Saheeh International.** Abdel Haleem (85) fetched and compared: *"it almost causes the heavens to be torn apart, the earth to split asunder, the mountains to crumble to pieces, / that they attribute offspring to the Lord of Mercy."* — opens lower-case mid-sentence (continues 19:89) and cannot start a beat without editing it; Saheeh International's pair is self-contained. | [Qur'ān 19:90](https://quran.com/19/90) · [19:91](https://quran.com/19/91) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/{19:90,19:91}?translations=20,85`, 2026-08-02. **Substring test run programmatically:** each half is a **byte-exact substring** of the fetched Saheeh International string. **One typographic disclosure:** the two āyāt are consecutive and are one sentence in the Arabic (`أَن دَعَوْا` in 19:91 is the cause-clause of 19:90); the beat joins them with an em dash at the āyah boundary. **No word is changed, added, dropped or reordered**, and the capital "That" is the translation's own. The antecedent of "therefrom" is supplied by 19:91 itself, which is why the pair is quoted rather than 19:90 alone. |
| 4.2 | Beats 4–5 quotation, verbatim across two beats: "None is more patient than Allah against the harmful and annoying words He hears (from the people): They ascribe children to Him,… / …yet He bestows upon them health and provision." | **sunnah.com's published English** (Muhsin Khan for the Bukhārī corpus), quoted as printed. **Deliberately NOT re-rendered from the Arabic.** `al-kareem@1` in this batch does re-render, and the rule it proposes is narrow and is honoured here: *re-render only where the published English resolves a contested reading.* This English resolves nothing — readability alone is not a licence, and this deck is not going to acquire a self-authored rendering on top of everything else. | [Sahih al-Bukhari 7378](https://sunnah.com/bukhari:7378) | **ṣaḥīḥ** — Ṣaḥīḥ al-Bukhārī (the collection's own condition; sunnah.com prints no separate grade line for the two Ṣaḥīḥs, which is the site's convention and was re-confirmed on this page) | ✅ **verified** via Wayback capture `20260315140757` of the exact URL, fetched 2026-08-02. Reference line on the page: *"Sahih al-Bukhari 7378"*. Narrator: **Abū Mūsā al-Ashʿarī**. Isnād on the page: ʿAbdān ← Abū Ḥamza ← al-Aʿmash ← Saʿīd b. Jubayr ← Abū ʿAbd al-Raḥmān al-Sulamī ← Abū Mūsā al-Ashʿarī. Page Arabic: `مَا أَحَدٌ أَصْبَرُ عَلَى أَذًى سَمِعَهُ مِنَ اللَّهِ، يَدَّعُونَ لَهُ الْوَلَدَ، ثُمَّ يُعَافِيهِمْ وَيَرْزُقُهُمْ`. **Substring test run programmatically:** beat 4's string and beat 5's string are each **byte-exact substrings** of the page English after whitespace normalisation, and so is the two concatenated. **Two disclosures:** (a) the split point between beats 4 and 5 is mid-sentence at the comma after "Him", marked with an ellipsis on both sides; (b) the archived page prints `provision .` — a stray space before the final period — and omits the closing quotation mark. The beat closes the sentence normally. **No word is changed.** |
| 4.3 | Beat 5's closing line: "The words are heard. The provision does not stop." | — | authored | n/a | ✅ **honest label — this is authored copy, not a source claim.** It restates the clause quoted immediately above it in the same beat (`سَمِعَهُ` → heard; `يُعَافِيهِمْ وَيَرْزُقُهُمْ` → provision) and asserts nothing the narration does not carry. Labelled rather than passed off as verification, per the row-4.6 convention this deck introduced in revision 2 and `ar-raheem@1` row 1.5 is being corrected to match. |
| 4.4 | Beat 3's opening line: "The Qur'ān records what creation does when a certain thing is said about Allah:" | — | authored | n/a | ✅ **honest label — authored framing, not a source claim.** It is a pointer to the quotation that follows in the same beat and makes no claim beyond it. (**This row number previously carried the ✅ that round 2 identified as the batch's worst defect** — it verified "20:44 is one āyah and is entirely this sentence" while the beat claimed 20:44 was the whole instruction Mūsā and Hārūn carried, which 20:47–48 falsifies. That beat, that passage and that claim are all gone.) |
| 4.5 | Beat 6, verse anchor, verbatim in full: "And if Allāh were to impose blame on the people for what they have earned, He would not leave upon it [i.e., the earth] any creature. But He defers them for a specified term. And when their time comes, then indeed Allāh has ever been, of His servants, Seeing." | **Saheeh International.** The `[i.e., the earth]` bracket is **the translator's own**, present in the fetched string, not authored — retained rather than silently dropped, because `عَلَىٰ ظَهْرِهَا` ("upon its back") has no antecedent in English without it. Abdel Haleem (85) fetched and compared: *"If **God** were to punish people [at once] for the wrong they have done, there would not be a single creature left on the surface of the earth. He gives them respite for a stated time and, whenever their time comes, **God** has been watching His servants."* — genuinely more readable, and rejected only because it says "God". The founder can take it; the cost is named. | [Qur'ān 35:45](https://quran.com/35/45) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/35:45?translations=20,85&fields=text_uthmani`, 2026-08-02. **Substring test run programmatically: byte-exact substring** of the fetched Saheeh International string; the fetched string carries **no footnote marker**, so nothing was stripped. Arabic: `وَلَوْ يُؤَاخِذُ ٱللَّهُ ٱلنَّاسَ بِمَا كَسَبُوا۟ مَا تَرَكَ عَلَىٰ ظَهْرِهَا مِن دَآبَّةٍ وَلَـٰكِن يُؤَخِّرُهُمْ إِلَىٰٓ أَجَلٍ مُّسَمًّى ۖ فَإِذَا جَآءَ أَجَلُهُمْ فَإِنَّ ٱللَّهَ كَانَ بِعِبَادِهِۦ بَصِيرًۢا`. **Position verified: this is the final āyah of Sūrat Fāṭir** — 36:1 (`يسٓ`) was fetched to confirm there is no 35:46. **No `ḥ-l-m` form in this āyah** — the criterion-(2) miss, disclosed above. |
| 4.6 | Duʿā text | catalog id 29 (`collectible_names.json`) — **no scripture citation claimed** | catalog only | n/a | ✅ **verified byte-identical to catalog** — re-checked programmatically 2026-08-02 across all three fields (`dua_arabic`, `dua_transliteration`, `dua_translation`); the ship gate enforces it independently. See the duʿā flag below. |
| 4.7 | Beat 2 `name_intro` | catalog id 29 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`, re-checked programmatically 2026-08-02. |
| 4.8 | The Qur'ān's other statement of the attribute, **quoted in no beat** — the near-twin of 35:45 | Saheeh International | [Qur'ān 16:61](https://quran.com/16/61) | Qur'ān | ✅ **verified** — live fetch, 2026-08-02. Fetched string: *"And if Allāh were to impose blame on the people for their wrongdoing, He would not have left upon it [i.e., the earth] any creature, but He defers them for a specified term. And when their term has come, they will not remain behind an hour, nor will they precede [it]."* Retained as the deck's second warrant and **evaluated against 35:45 in the section below.** |
| 4.9 | The old verse beat, **quoted in no beat**, kept verified so the founder's alternative is one line away | Saheeh International | [Qur'ān 35:41](https://quran.com/35/41) | Qur'ān | ✅ **verified** — live fetch, 2026-08-02; **byte-exact substring** after stripping the footnote marker that renders as a stray `1` after "Forbearing". Arabic `إِنَّهُ كَانَ حَلِيمًا غَفُورًا`. Dropped for the `غَفُورًا` reason above, not for any verification failure. |

### 16:61 vs 35:45 — the re-evaluation the founder asked for, done honestly

Revision 2 rejected 16:61 on the ground that it *"turns the āyah toward warning"* and *"contains no form of `ḥ-l-m`"*. The founder's brief was right to say re-evaluate rather than inherit that judgement. Both āyāt were re-fetched and read whole.

**On the warning point, revision 2 was correct about 16:61 and did not know why.** The two āyāt are near-identical for two clauses and then diverge exactly where it matters:

| | 16:61 | 35:45 |
|---|---|---|
| retained power | `مَا تَرَكَ عَلَيْهَا مِن دَابَّةٍ` | `مَا تَرَكَ عَلَىٰ ظَهْرِهَا مِن دَابَّةٍ` — same |
| the withholding | `وَلَـٰكِن يُؤَخِّرُهُمْ إِلَىٰ أَجَلٍ مُّسَمًّى` | identical |
| **how the āyah ends** | *"they will not remain behind an hour, nor will they precede [it]"* — **the door closing** | *"then indeed Allāh has ever been, of His servants, **Seeing**"* — **an attribute of attention, not of sentence** |
| what follows it | 16:62: *"…Assuredly, they will have the **Fire**, and they will be [therein] neglected."* — **the next āyah** | **nothing.** Last āyah of the sūrah. |

So 35:45 states the attribute as completely as 16:61 does, and is the only one of the two whose own ending and whose neighbourhood survive bar 5. **On the `ḥ-l-m` point, revision 2 was right and it applies to both** — neither āyah contains the Name-noun, which is the cost this deck now pays and discloses.

**16:61 is not used and is not needed.** It remains verified in row 4.8 as the doctrinal warrant.

### ⚠️ Duʿā mismatch — disclosed, not fixable by this deck

Catalog id 29's duʿā asks for **the user's own ṣabr** and refuge from **jazaʿ**. It names no Name of Allah, and it asks for a *human* virtue while the deck teaches a *divine* attribute. There is a defensible reading — ḥilm in a created being is precisely patience toward the one who wronged you, and beat 5 now shows the divine case being *heard* and *answered with provision*, which is the shape the duʿā asks the user to grow — and that is how the deck is built. But the founder should see it stated rather than have it pass as a plain catalog invocation:

- Of the five decks in this batch, three duʿās do not name their own Name (`ar-raheem`, `al-ghafur`, `al-haleem`). Only `al-afuw@1` and `al-kareem@1` do.
- Catalog id 29's `dua_translation` renders `الْجَزَعِ` as *"anxiety and distress"*. **`Jazaʿ` is impatience, panic, unrestrained anguish** — "anxiety" imports a modern clinical register **and collides with the app's own `anxiety` chip vocabulary**, where it means something else. Catalog issue, out of this deck's reach (the ship gate forces byte-identity), but it is a real content bug and worth a ticket.
- No citation is claimed for this duʿā anywhere in the deck, and none was found. It is presented as a catalog invocation.

### Ship-gate note

**No `renderedDuaSources` entry for this deck** — its duʿā carries no citation, and it must stay unpinned.

This matters more than it did last revision. As of commit `a12f1db`, `renderedDuaSources` in `test/content/name_stories_ship_gate_test.dart` is asserted **in both directions**: an unpinned deck that carries a `source` on its duʿā beat now **fails** the gate, and a pinned deck that drops its `source` fails too. So the transcription rule for this deck is exact: **the duʿā beat must carry no `source` field, and `al-haleem@1` must not be added to `renderedDuaSources`.**

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 14 shipped decks

**Baseline correction.** Previous revisions' collision tables understated the shipped decks — they listed one or two āyāt per deck when the shipped `sources` arrays and beat `source` fields carry more. The table below is rebuilt from `assets/content/name_stories.json` itself (every `sources[].url` plus every beat `source`), 2026-08-02. Additions the earlier tables did not show are marked **(+)**.

| shipped deck | its narrative | its full inventory | collides? |
|---|---|---|---|
| `as-salam@1` | the cave of Thawr | 13:28, **9:40 (+)**, **59:23 (+)**, **Bukhārī 3653 (+)**, Muslim 591 | ✖ none |
| `al-wakeel@1` | Uḥud, Ḥamrāʾ al-Asad | 3:172, 3:173, 3:174, 65:3, **Bukhārī 4563 (+)** | ✖ **none, and the revision-1 overlap is retired.** Revisions 2 and 3 leave Uḥud entirely. |
| `al-hadi@1` | Mūsā to Midian | 28:22, **28:15 (+)**, **28:21 (+)**, **28:23 (+)**, 22:54, **1:6 (+)** | ✖ **none — and revision 2's shared-protagonist flag is retired too.** Mūsā is not in this deck at all any more. |
| `as-samad@1` | Zakariyyā | 19:2, 19:3, 19:4, 19:7, 112:2 | ⚠️ **shared sūrah, nothing else.** This deck's beat 3 uses **19:90–91**; `as-samad@1` uses 19:2–7. Different passage, different subject (Zakariyyā's prayer vs. the claim of a son), eighty-three āyāt apart, no shared verse, no shared quotation, no shared insight. Disclosed rather than dismissed — it is the same class of proximity `ar-raheem@1` discloses for the two caves. |
| `al-fattah@1` | Ḥudaybiyyah | 48:1, **35:2**, Bukhārī 4172, 4833, **Bukhārī 2731 (+)** | ⚠️ **shared sūrah, nothing else.** This deck's verse beat is **35:45**; `al-fattah@1`'s is 35:2. Opposite ends of Sūrat Fāṭir, no shared verse, no shared quotation. Disclosed. |
| `al-lateef@1` | Yūsuf | 12:100, **12:15 (+)**, **12:20 (+)**, **12:42 (+)**, 42:19, 67:13 | ✖ none |
| `al-jabbar@1` | Yaʿqūb's grief | 12:84, 12:86, 12:87, **12:18 (+)**, **12:94 (+)** | ✖ none |
| `al-ghaffar@1` · `at-tawwab@1` | the servant who kept returning · the hundred lives | Bukhārī 7507; 39:53 · Bukhārī 3470; 2:37 | ✖ none — **and note the engines differ from this deck's:** those two are *return and acceptance*; this one is *the interval in which nothing has been returned and nothing has been erased*. Beat 8 was rewritten this revision to stop borrowing their vocabulary (see below). |
| `ar-rahman@1` | mother among captives | 2:286, 7:156, **55:1 (+)**, Bukhārī 5999 | ✖ none |
| `ash-shafi@1` · `al-wadud@1` · `ar-razzaq@1` · `al-baseer@1` | Ayyūb · lost camel · the birds · Hājar | 21:83–84, 26:80, Bukhārī 5743 · 11:90, Muslim 2747a, Bukhārī 6309 · 65:2, 65:3, Tirmidhī 2344 · 58:1, Bukhārī 3364, **Ibn Mājah 188 (+)** | ✖ none |
| **sibling drafts in this batch** | `al-afuw@1` (Ibn Mājah 3850, Tirmidhī 3513, 97:3, 42:25) · `al-ghafur@1` (Bukhārī 2441, Abū Dāwūd 1516, 4:110) · `al-kareem@1` (Bukhārī 1145, Bukhārī 4684, 27:40) · `ar-raheem@1` (18:10, 18:11, 18:18, 33:43) | | ✖ **none, and specifically: no form of `ʿ-f-w` and no form of `gh-f-r` appears anywhere in this deck** — not in a quotation, not in an epithet, not in a verse ending. That was the defect in revision 1, it was left standing as a non-blocking flag on 35:41 in revision 2, and it is now closed by construction. |

**Verified negative, run against the rebuilt inventory above:** no shipped deck and no sibling draft uses **19:90, 19:91, 35:45 or Ṣaḥīḥ al-Bukhārī 7378** (nor 6099, its parallel). The complete shipped ḥadīth set is Bukhārī 3653, 4563, 6309, 7507, 3470, 5743, 2731, 4172, 4833, 5999, 3364 · Muslim 591, 2747a · Tirmidhī 2344 · Ibn Mājah 188 — 7378 is not in it.

**Insight-level check (the axis the collision tables previously missed).** Beat 8's closing line in revision 2 was *"Every turning anyone has ever made was made inside that distance"* — which made *turning* the payoff and quietly undid this deck's own stated distinction from `at-tawwab@1` and `al-ghaffar@1` (round 2, H4). It now reads *"Every hour anyone has ever been given was inside that distance"*, which reports 35:45's `أَجَلٍ مُّسَمًّى` and Bukhārī 7378's provision, and borrows no sibling deck's vocabulary. Checked against the shipped closing insights: `al-lateef@1` ("visible only from the far side"), `al-ghaffar@1`, `at-tawwab@1`, `ar-rahman@1` — **✖ none.**

### Authoring notes (candidates considered)

- **Selected: 19:90–91 + Ṣaḥīḥ al-Bukhārī 7378, anchored on 35:45.** The case is made bar-by-bar above rather than repeated here. The three properties that no other candidate had together: the offence is at the theological maximum *and is stated by the sources rather than characterised by the deck*; the withholding is an active verb with Allah as subject in two independent sources; and the arc has **nowhere to terminate** — the ḥadīth is free-standing and the verse is the last āyah of its sūrah. It is also the one selection in this batch that its own Name card already teaches.
- **Rejected — Pharaoh, 20:42–45 + 28:4 + 79:24 (revision 2).** See the header: H1 (factually false on-screen claims) and H2 (the deck's own rejection rule excluded its own story).
- **Rejected — Uḥud, 3:152 + 3:155 (revision 1).** `عَفَا` in both climax quotations.
- **Rejected — the full narrative sweep** (Nūḥ, the people of Yūnus, Iblīs's respite, 8:33, Ibrāhīm and Lūṭ's people, the bedouin in the mosque, Ṭāʾif). Tabulated with the failing bar for each in §"The honest weakness" above. **This sweep is the evidence for the claim that the narrative slot cannot be filled for this Name, and the founder should read it as the argument for the cut option if he does not accept the current construction.**
- **Rejected as the verse anchor — 35:41** (`حَلِيمًا غَفُورًا`), **22:59** (`عَلِيمٌ حَلِيمٌ`), **16:61**, and the remaining `ḥalīm` endings (2:225, 2:235, 2:263, 17:44, 64:17). Each with its reason above; all verified, none used.
- **Rejected — Bukhārī 6099**, the parallel of 7378 through the same isnād (al-Aʿmash ← Saʿīd b. Jubayr ← Abū ʿAbd al-Raḥmān al-Sulamī ← Abū Mūsā). Fetched and read: Wayback capture `20260117233253`, Arabic `لَيْسَ أَحَدٌ ـ أَوْ لَيْسَ شَىْءٌ ـ أَصْبَرَ عَلَى أَذًى سَمِعَهُ مِنَ اللَّهِ، إِنَّهُمْ لَيَدْعُونَ لَهُ وَلَدًا، وَإِنَّهُ لَيُعَافِيهِمْ وَيَرْزُقُهُمْ`. Same ṣaḥīḥ status. **Rejected on the published English only:** it breaks the sentence in the wrong place (*"…against the harmful saying. He hears from the people they ascribe children to Him…"*), which would force either an edit or a confusing beat. 7378's English is cleanly quotable. Recorded so the founder can see the choice was between two verified renderings of one ḥadīth, not between a good source and a bad one.
- **Register check:** no beat attributes waiting, wanting or withholding-as-a-stance to the Name. Beat 8 defines the attribute in the catalog's own terms (`meaning`: *"The One who withholds punishment despite having full power to act"*) and reports what the cited passages contain; it makes no promise about the reader. The catalog `lesson` line for this Name (*"this is Al-Haleem's patience with you"*) is a Name-action attribution about the reader and was again deliberately **not** used as the takeaway.
