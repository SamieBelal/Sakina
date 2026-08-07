# Deck Draft — Al-Waliyy (hardship pack, Wave G batch 2, 4 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

> **REVISION 2, 2026-08-03.** Revision 1 was **REJECTED** on three blocking findings, and it also recommended cutting the Name. **The recommendation is withdrawn**: under the founder's 2026-08-03 decision every one of the 99 Names gets a deck, so "cut Al-Waliyy" is not an available answer and this revision does not offer it. What it offers instead is a **new verse anchor** — 42:28 is gone — and an **on-beat fix to the elision inside the quoted duʿā**. §"What revision 1 got wrong" is the first thing to read.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G, §G2b. Author: Claude, 2026-08-03.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com`; ḥadīth via Wayback archive of the exact `sunnah.com` URL. Story beats paraphrase only what the cited source carries, and every paraphrase is labelled.

**Translation standard:** Saheeh International (`20`) for Qur'ān, Abdel Haleem (`85`) fetched and compared per row and adopted nowhere. Khattab (`131`) remains unfetchable. **For ḥadīth this deck makes a deliberate, disclosed split between two collections — see rows 4.2 and 4.3.**

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on every beat.

---

## What revision 1 got wrong, and what changed

| the verdict's finding | status in R2 |
|---|---|
| **BLOCKING — bar 1 is carried by a trailing epithet, which is what bar 1 forbids.** 42:28's demonstrated act is **sending rain**; `ٱلْوَلِىُّ ٱلْحَمِيدُ` is a paired epithet appended at the end. *"Nothing in the āyah shows protecting friendship."* | **Accepted in full. 42:28 is gone from this deck.** The verse anchor is now **Qur'ān 93:6** — `أَلَمْ يَجِدْكَ يَتِيمًا فَـَٔاوَىٰ`, *"Did He not find you an orphan and give [you] refuge?"* — where the act is a **finite verb of Allah's own action, performed on a person who by definition has no guardian**. Bar 1 is met on the act; **bar 4 is the bar that gives**, and §"Why bar 4 is traded" records the sweep that proves the trade is forced rather than convenient. |
| **BLOCKING — the defence-by-analogy to `al-afuw@1` is false.** `al-afuw@1`'s 42:25 carries `وَيَعْفُوا۟` as a **finite verb of Allah's action inside the demonstrating clause**; that is not the same construction as an epithet appended after an unrelated act. | **Accepted, and the sentence is deleted rather than reworded.** The verifier is right and the claim was the single most persuasive false statement in revision 1 — the kind a founder accepts without checking. It is recorded here as an error, not repaired into a weaker version of itself. |
| **BLOCKING — unmarked elision inside a quoted duʿā**, against an explicit ✅ reading *"No word is changed, added, dropped or reordered."* Beats 4–5 rendered two consecutive quotation-marked sentences while silently dropping the middle clause *"O Allah, accompany us with Your protection, and return us in security,"*. | **Accepted. Fixed on the beat, not in a table.** The dropped clause is **restored into beat 4**, and beats 4 and 5 now carry **visible ellipses** showing that each is part of one running quotation. Row 4.2's ✅ is rewritten to say what is actually true. |
| Minor: row 4.1's paraphrase disclosure described **Muslim 1342's** omissions while beats 3–5 quote **Tirmidhī 3438**, whose own dropped detail is the finger gesture. | **Corrected in row 4.1.** |
| Minor: row 4.5 claimed *"four shadda-ordering differences"* that did not survive normalisation on the verifier's run; only one sukūn difference reproduced. | **Corrected: the count is withdrawn.** The row now states only what re-runs: same letters, same words, the catalogue one diacritic more fully vowelled, raw comparison fails, skeleton matches. |
| The verdict's recommendation: *"Take the deck's own clean-cut option."* | **Not available.** The founder's 2026-08-03 decision removes "reject the Name" as a resolution. **This is the one place where R2 declines the verifier's advice, and it declines it on an instruction rather than on an argument** — the verifier's reasoning about revision 1 was correct in every particular. |

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
> 2. **"O Allah You are the companion on the journey, and the caretaker for the family, O Allah, accompany us with Your protection, and return us in security…"**
> 3. **"…O Allah, I seek refuge in You from the difficulties of the journey, and from returning in great sadness."**

**Beat 6 · verse** *(the act is Allah's own, and the person it is done to is the one person guaranteed to have no protector)*:
> "Did He not find you an orphan and give [you] refuge?" — Qur'ān 93:6

**Beat 7 · duʿā** *(catalog id 64, verbatim in full — the opening clause of the narration above)*:
> اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الْأَهْلِ
> *Allahumma anta's-sahibu fi's-safar wa'l-khalifatu fi'l-ahl*
> "O Allah, You are my companion in travel and the guardian over my family."
>
> *(proposed `source` field on this beat: `Sahih Muslim 1342`)*

**Beat 8 · takeaway:**
> One half of that sentence is about where you are. The other half is about the people you are not with. And the Prophet ﷺ, who taught it, had been an orphan himself.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **Qur'ān 93:6, beat 6 — and this is the bar revision 1 failed.** `أَلَمْ يَجِدْكَ يَتِيمًا فَـَٔاوَىٰ`. **`فَـَٔاوَىٰ` is a finite verb of Allah's own action**, in Allah's own speech, inside the same clause as the person it is done to. It is **not** a trailing epithet appended after an unrelated act — the construction the verifier correctly identified as bar 1's strongest form (`al-afuw@1`'s 42:25 `وَيَعْفُوا۟`) is the construction here. **And the object is the point:** a `يَتِيم` is, by the word's own definition, **a child left without the person who would have been in charge of him.** The catalogue's own `meaning` for id 64 is *"The One who is the helper and protector of the believers"* and its `lesson` is *"You are never alone."* **Taking in someone who has no one is that, demonstrated.** | **yes — beat 6** |
| 2 | **the distinguishing quality is shown, not stated** | Al-Waliyy's distinguishing quality against `as-samad@1` (leaned on) and `al-wakeel@1` (entrusted with) is **being in charge of someone, and in two places at once** — with the person, and over what the person left. 93:6 supplies the *in-charge-of* half as an act. The duʿā supplies the *two-places* half in the user's own mouth. **Nothing here is stated by the deck's prose.** | **yes — beats 4 and 6** |
| 3 | **does not collapse into a sibling Name** | **Arabic pass.** No `w-k-l`, no `ṣ-m-d`, no `r-ḥ-m`, no `gh-f-r` on any beat. The operative roots are `ʾ-w-y` (take in / shelter), `y-t-m` (orphan), `ṣ-ḥ-b` (accompany) and `kh-l-f` (succeed / stand in for). **⚠️ Two disclosures, both new in R2 and both real.** (a) **93:7, the very next āyah, is `وَوَجَدَكَ ضَآلًّا فَهَدَىٰ` — `al-hadi@1`'s Name-verb** (shipped), one āyah past this deck's verse beat. It is not quoted and reaches no screen; disclosed in the sweep table. (b) **English pass, and this one is a genuine adjacency the founder should price:** shipped `as-samad@1` renders **"The Eternal Refuge"** on its `name_intro` and **"O Allah, O Eternal Refuge"** on its duʿā, and this deck's verse beat renders **"give [you] refuge"**. **Same English word, two decks, one pack.** It is weaker than the `al-muid@1`/`al-jabbar@1` case — there it is Name-gloss against Name-gloss, here it is a Name-gloss against a **finite verb inside a quotation**, and Al-Waliyy is never glossed *"refuge"* anywhere — but it is not nothing. **See §"The one collision R2 did not close".** | **argued, with one open adjacency** |
| 4 | **the Name's own root appears in the source text** | **No — and this is deliberate, forced, and the trade is documented.** `w-l-y` appears in **neither** 93:6 nor Tirmidhī 3438 / Muslim 1342. Revision 1 had the root (42:28's `ٱلْوَلِىُّ`) **and failed bar 1 for it**. `al-haleem@1` set the precedent in batch 1 for giving up bar 4 when no passage can hold it and bar 3 at once; **plan §7 states bar 4 as the only "ideally" bar.** **§"Why bar 4 is traded" below records the sweep of every `w-l-y`-of-Allah occurrence in the Qur'ān, all fetched, which is what makes the trade legitimate rather than convenient.** **Partial mitigation, stated as mitigation and not as a bar:** `ٱلْوَلِىُّ` **does** render in Arabic on beat 2 (`name_intro` and `dua` beats are the only ones that render Arabic — plan §7's schema fact), and the catalogue's English *"The Protecting Friend"* is on the same beat. | **no — disclosed** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **Maximal, and this is 93:6's strongest property.** Sūrat aḍ-Ḍuḥā **contains no punishment anywhere**, its āyāt after the verse beat are 93:7–8 (two more favours) and 93:9–11 (three instructions), and **`verses/by_key/93:12` returns HTTP 404 — 93:11 is the final āyah**, ending *"But as for the favor of your Lord, report [it]."* The ḥadīth is a free-standing duʿā narration with no consequence clause. Full table below. | **yes — verified** |

### ⚠️ Why bar 4 is traded — the sweep, fetched, that makes it forced

**Plan §7 bar 4:** *"The Name's own root ideally appears in the source text — but not at the cost of bar 3. Al-Ḥalīm gave this up deliberately… Recording the sweep that proves it is what makes the trade legitimate."* This deck gives it up at the cost of **bar 1**, and the same standard applies: here is the sweep.

**Every Qur'ānic occurrence of `walī` / `mawlā` predicated of Allah was fetched from `api.quran.com`, 2026-08-03.** They fall into exactly three shapes, and only one of them can meet bar 1:

| shape | occurrences fetched | can it meet bar 1? |
|---|---|---|
| **Trailing or predicate epithet** — the Name is named, with no act of walāya in the clause | **3:68** *"And Allāh is the Ally of the believers."* · **3:122** *"but Allāh was their ally"* · **3:150** *"But Allāh is your protector, and He is the best of helpers."* · **4:45** *"sufficient is Allāh as an ally"* · **5:55** *"Your ally is none but Allāh…"* · **6:127** *"And He will be their protecting friend because of what they used to do."* · **22:78** *"He is your protector; and excellent is the protector"* · **42:28** *"And He is the Protector, the Praiseworthy."* · **45:19** *"but Allāh is the protector of the righteous"* · **47:11** · **66:2** | **No.** This is precisely the construction bar 1 forbids, and **42:28 — revision 1's anchor — is in this list.** |
| **Negative construction** — "you have no protector besides Him" | **2:107** · **13:11** *"And there is not for them besides Him any patron."* · **32:4** · **33:17** | **No.** Nothing is demonstrated; a lack is asserted about others. |
| **Human speech about Allah** | **7:196** *"Indeed, my protector is Allāh…"* (the Prophet's ﷺ declaration) · **12:101** *"You are my protector in this world and the Hereafter."* (Yūsuf) · **10:62** (about the human *awliyāʾ* of Allah, not the Name) | **No** — the reverence line the format spec draws, and the ground Ṭāʾif was rejected on in batch 1. |
| **Name + an act in the same clause** | **2:257** `ٱللَّهُ وَلِىُّ ٱلَّذِينَ ءَامَنُوا۟ يُخْرِجُهُم مِّنَ ٱلظُّلُمَـٰتِ إِلَى ٱلنُّورِ` · **42:9** *"But Allāh - He is the Protector, and He gives life to the dead"* | **These two, and only these two, in the whole Qur'ān.** |

**And both of the two fail another bar.**

- **2:257 fails bar 5, inside its own āyah.** Fetched: the second half is *"And those who disbelieve - their allies are ṭāghūt… **Those are the companions of the Fire; they will abide eternally therein.**"* **The threat is inside the āyah, not merely after it, so no excerpt is honest** — which is the exact ground `al-mujeeb@1` rejected 40:60 on **in this same batch**. Taking 2:257 here would break a rule the batch has already enforced against a sibling deck. *(It also carries `ٱلظُّلُمَـٰت` — "darknesses" — which is on `al-mujeeb@1`'s beat 4, on screen, in this batch.)*
- **42:9's act is `يُحْىِ ٱلْمَوْتَىٰ`** — giving life to the dead, which is not walāya and is `al-qadir@1`'s subject matter in this batch. It is also in Sūrat ash-Shūrā, which revision 1 was already criticised for crowding.

**So the honest statement, and the founder should have it plainly: there is no passage in the Qur'ān that satisfies bar 1 and bar 4 simultaneously for this Name.** One of the two must go. **Bar 1 binds absolutely; bar 4 is the one the plan itself marks as conditional.** That is the whole argument, and it is why 93:6 is the anchor.

### ⚠️ The one collision R2 did not close

**`as-samad@1` ships today with `name_intro` = "The Eternal Refuge" and a duʿā rendering "O Allah, O Eternal Refuge". This deck's verse beat renders "give [you] refuge".**

This is a bar-3-in-English finding of the same family as the two the verifier caught, and it is disclosed rather than argued away. **What weakens it:** *refuge* is Aṣ-Ṣamad's **gloss**, and here it is a **verb inside a quoted āyah**; Al-Waliyy is glossed *"The Protecting Friend"* and never *"refuge"*; and the two decks' insights do not touch (permission to lean vs. being taken charge of).

**The one-line fix, fetched and ready, and NOT taken unilaterally.** Abdel Haleem renders 93:6 *"Did He not find you an orphan and **shelter** you?"* — fetched 2026-08-03, and unusually for this batch **it says neither "God" nor a lower-cased Name in this āyah**, so the standing objection to Abdel Haleem does not bite on this row at all. Swapping it removes the word *refuge* from the deck entirely.

**It is not taken because the batch rule is Saheeh International throughout and this row does not meet the exception** (*re-render only where the published English resolves a contested reading*). Changing a batch-wide translation standard to dodge one word is a founder's call, not a drafter's. **Founder decision, one line either way:** SI as drafted with the adjacency disclosed, or Abdel Haleem on this single beat with the adjacency gone and one mixed row.

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **Jami\` at-Tirmidhi 3438** | Nothing narrative. The page carries Abū ʿĪsā's remark on the isnād and a second route through Suwayd; there is no continuation of the scene and no consequence clause. | **clean, and structurally clean.** |
| **Sahih Muslim 1342** | The narration continues past the deck's material with the returning form: *"We are returning, repentant, worshipping our Lord. and praising Him."* | **clean** — the continuation is dhikr, not warning. Recorded because the deck stops before it. |
| **93:6** (n+1) | 93:7 *"And He found you lost and guided [you],"* → 93:8 *"And He found you poor and made [you] self-sufficient."* | **clean, and confirming** — two more favours in the same grammatical shape as the beat. ⚠️ **Disclosed: 93:7's verb is `فَهَدَىٰ`, `al-hadi@1`'s Name-verb** (shipped, whose own verse beat is 22:54). Not quoted, no shared citation, off-screen. 93:8's `فَأَغْنَىٰ` is Al-Ghani (id 88), **not shipped and not in this batch.** |
| **93:6** (n−1) | 93:5 *"And your Lord is going to give you, and you will be satisfied."* | **clean.** |
| **93:6, to the end of the sūrah** | 93:9 *"So as for the orphan, do not oppress [him]."* → 93:10 *"And as for the petitioner, do not repel [him]."* → 93:11 *"But as for the favor of your Lord, report [it]."* → **93:12 = HTTP 404.** | **clean, all the way to the end.** **Nothing in Sūrat aḍ-Ḍuḥā turns to warning or punishment at any point** — the strongest available form of bar 5, the same sūrah-final signal that carried `al-haleem@1`'s 35:45. **Disclosed:** 93:9 turns the sūrah's own word `ٱلْيَتِيم` from the beat into an **instruction to the reader** about how to treat orphans. It contradicts nothing and is not quoted; a founder tapping the citation will meet it three āyāt down. |
| **93:6, the sūrah's opening** | 93:1–3 — the oaths and `مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ`. | ⚠️ **Named, because of where it has been.** **93:1–3 was revision 1 of `al-qayyum@1`'s story, and it was rejected there** on the ground that it demonstrates non-abandonment during a pause in revelation, *"a different attribute from Al-Qayyūm's."* **It is not this deck's material either** — this deck quotes 93:6 and nothing else from the sūrah — but the founder should see the two revisions side by side and check that the sūrah has not simply been passed from one Name to another. **The claim this deck makes is narrower and different:** not that Allah did not leave him, but that **Allah took charge of him when there was no one to.** |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 4.1 | Beat 3: the Prophet ﷺ said these words whenever he set out and mounted | paraphrase of both narrations (Muslim: *"whenever Allah's Messenger ﷺ mounted his camel while setting out on a journey"*; Tirmidhī: *"When the Prophet ﷺ would travel, and he would mount his riding camel"*) | [Sahih Muslim 1342](https://sunnah.com/muslim:1342) · [Jami' at-Tirmidhi 3438](https://sunnah.com/tirmidhi:3438) | ṣaḥīḥ · ḥasan | ✅ **verified** — both pages fetched via Wayback archives of the exact URLs. Muslim 1342: capture `20260303093718`, reference line *"Sahih Muslim 1342"*, in-book Book 15 Hadith 479, narrator **Ibn ʿUmar**. Tirmidhī 3438: capture `20260413080740`, re-fetched and re-read in full 2026-08-03, reference line *"Jami\` at-Tirmidhi 3438"*, in-book **Book 48, Hadith 69**, narrator **Abū Hurayra**, `Grade : Hasan (Darussalam)`, `حَسَنٌ غَرِيبٌ`. **⚠️ R2 correction — revision 1 attached the wrong narration's omissions to this row.** It disclosed *"the takbīr-three-times detail and the `سُبْحَانَ ٱلَّذِى سَخَّرَ لَنَا هَـٰذَا` opening"*, **which are Muslim 1342's**; beats 3–5 quote **Tirmidhī 3438**, whose own omitted detail is **the finger gesture** — the page reads *"he would gesture with his finger" – and Shu`bah stretched out his finger –* (`قَالَ بِأُصْبُعِهِ وَمَدَّ شُعْبَةُ بِأُصْبُعِهِ`). **That is what beat 3 drops, and it is the only thing it drops.** Muslim 1342's own omissions remain true of Muslim 1342 and are irrelevant to these beats. |
| 4.2 | Beat 4 quotation: **"O Allah You are the companion on the journey, and the caretaker for the family, O Allah, accompany us with Your protection, and return us in security…"** | **Jāmiʿ at-Tirmidhī 3438's published English (Darussalam), quoted as printed. NOT re-rendered.** See the split box below for why this collection and not Muslim's. | [Jami' at-Tirmidhi 3438](https://sunnah.com/tirmidhi:3438) | **ḥasan (Darussalam)** | ⚠️→✅ **R2 — this row previously carried a false ✅ and it is the deck's most serious repaired defect.** Revision 1 asserted *"No word is changed, added, dropped or reordered"* while beats 4 and 5 rendered **two closed, consecutive quotation-marked sentences** that **silently dropped the middle clause** *"O Allah, accompany us with Your protection, and return us in security,"* (`اللَّهُمَّ اصْحَبْنَا بِنُصْحِكَ وَاقْلِبْنَا بِذِمَّةٍ`). A reader tapped beat 4, then beat 5, and believed that was the duʿā's sequence. **A note in this table would not have been a disclosure — the user never sees this table.** **Fix: the clause is restored into beat 4, and beat 4 now ends with a visible ellipsis** showing the quotation runs on. **Re-verified programmatically 2026-08-03:** the archived page's English is **one continuous quotation** and beat 4's string is a **byte-exact substring** of it after whitespace normalisation. Page Arabic: `اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الأَهْلِ اللَّهُمَّ اصْحَبْنَا بِنُصْحِكَ وَاقْلِبْنَا بِذِمَّةٍ`. **What is still changed, stated exactly:** the beat closes with an ellipsis where the published English runs on with a comma. **No word inside the quoted region is changed, added, dropped or reordered — and this time the claim is true of what renders.** |
| 4.3 | Beat 5 quotation: **"…O Allah, I seek refuge in You from the difficulties of the journey, and from returning in great sadness."** | **Jāmiʿ at-Tirmidhī 3438's published English, quoted as printed.** Muslim 1342's rendering of the parallel clause is *"…hardships of the journey, gloominess of the sights, and finding of evil changes in property and family on return"* — **fuller** (Muslim's Arabic carries `وَكَآبَةِ الْمَنْظَرِ وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالأَهْلِ`, Tirmidhī's carries `وَكَآبَةِ الْمُنْقَلَبِ`), and unreadable at reveal-beat speed. **The two narrations differ in this clause and the deck quotes the shorter one; this is a real wording difference, not only a rendering difference, and it is disclosed here rather than blurred.** | [Jami' at-Tirmidhi 3438](https://sunnah.com/tirmidhi:3438) | ḥasan (Darussalam) | ✅ **verified — byte-exact substring** of the archived page English after whitespace normalisation, re-run 2026-08-03. **R2: the beat now opens with a visible ellipsis**, marking that it continues beat 4's quotation rather than starting a new one. **One further disclosure the sweep turned up, new in R2:** the page's **transliteration** carries a clause the page's **English does not** — `Allāhummazwi lanal-arḍa wa hawwin ʿalainas-safar` (`اللَّهُمَّ ازْوِ لَنَا الأَرْضَ وَهَوِّنْ عَلَيْنَا السَّفَرَ`, *"fold up the earth for us and make the journey easy"*). **That omission is the published translator's, not the deck's**, and the deck cannot restore it without composing English for an Arabic clause — which the fetch-first rule forbids. **Recorded so that nobody later mistakes the deck's ellipsis for covering it.** |
| 4.4 | Beat 6, verse anchor, verbatim in full: **"Did He not find you an orphan and give [you] refuge?"** | **Saheeh International.** Abdel Haleem fetched and compared: *"Did He not find you an orphan and shelter you?"* — **and this is the batch's most defensible Abdel Haleem row**: it says neither *"God"* nor a lower-cased Name in this āyah, it is shorter, and **it would remove the `as-samad@1` "refuge" adjacency entirely**. Not used, on batch consistency alone. **See §"The one collision R2 did not close" — this is a live founder decision, one line either way.** | [Qur'ān 93:6](https://quran.com/93/6) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/93:6?fields=text_uthmani,text_imlaei&translations=20,85`, 2026-08-03. **Byte-exact against the RAW string; the fetched translation carries ZERO `<sup>` footnote markers**, so nothing was stripped and nothing needed to be. The bracket `[you]` is the translator's own and is retained. Arabic: `أَلَمْ يَجِدْكَ يَتِيمًا فَـَٔاوَىٰ`. **Position verified: `verses/by_key/93:12` returns HTTP 404**, i.e. the sūrah runs five more āyāt and stops, with no punishment in any of them. |
| 4.5 | Duʿā text (catalog id 64) is the Arabic of Ṣaḥīḥ Muslim 1342 — **same words, same letters; the catalogue is one diacritic more fully vowelled than the archived page** | — | [Sahih Muslim 1342](https://sunnah.com/muslim:1342) | ṣaḥīḥ | ⚠️ **verified programmatically with a precise, disclosed caveat — and R2 withdraws a count that did not reproduce.** Catalog `dua_arabic` vs the archived page span: raw **False**, NFC **False**, NFC+format-strip **False**, **consonantal skeleton True**. **Revision 1 claimed "four shadda-ordering differences" plus one sukūn; the independent verifier could reproduce only the sukūn (U+0652 on the lām of `الْأَهْلِ`, where the page reads `الأَهْلِ`) after normalisation. The count is therefore withdrawn rather than defended.** What stands, and is all that matters: **every letter and every word is the same, the catalogue is more fully vowelled, and the deck does not claim byte-identity.** |
| 4.6 | Beat 2 `name_intro`, and the duʿā's transliteration and translation fields | catalog id 64 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english` and `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03. |
| 4.7 | Beat 8 (R2): *"One half of that sentence is about where you are. The other half is about the people you are not with. And the Prophet ﷺ, who taught it, had been an orphan himself."* | — | authored + [Qur'ān 93:6](https://quran.com/93/6) | Qur'ān | ✅ **honest label — authored copy over one fetched fact.** The first two sentences restate the two halves of the clause quoted on beat 4 and printed in Arabic on beat 7 (`ٱلصَّاحِبُ فِى ٱلسَّفَرِ` / `ٱلْخَلِيفَةُ فِى ٱلْأَهْلِ`). The third reports **93:6 as fetched** — the āyah addresses the Prophet ﷺ and says *"Did He not find you an orphan"*. **It is a report, not a gloss:** the deck deliberately does **not** define *orphan* as "someone with no walī" on the beat, because that is a lexical argument the bar-1 cell makes to the founder and not a claim to put on a reveal screen. **It makes no promise to the reader** and attributes no stance to the Name. |

### ⚠️ The register question — unchanged from R1, still live, still a founder call

**Catalog id 64's duʿā is a travel supplication, and the user reciting it is in a bedroom at 1am.** *"O Allah, You are my companion in travel and the guardian over my family."*

1. **The catalogue already reads it figuratively.** Id 64's own `lesson` line is *"You are never alone. Al-Waliyy is closer to you than your own loneliness."* — no travel in it. The app has already decided this duʿā means what the deck says it means; the deck did not invent the reading.
2. **The ICP is disproportionately literally in it.** A 20-something Muslim away from the city they grew up in, with parents in another country, is not reading *"companion in travel / guardian over the family"* as a metaphor. **Beat 1 is written to make that reading the obvious one without ever asserting it.**
3. **It is nonetheless a stretch the other four decks in this batch do not make.** **There is no substitute duʿā** — the ship gate forces byte-identity with catalog id 64. **What has changed since R1:** failing on this can no longer mean cutting the Name. It would mean **re-drafting the deck around a different register** — and since the duʿā is fixed and renders on beat 7 regardless, the only lever is the bridge and the takeaway. **If the founder wants the travel framing off the screen, the story beats would have to leave the travel narration behind**, which costs the deck its one §STEP-3 property-1 asset (the duʿā *is* a clause of a ṣaḥīḥ narration). That trade is stated here rather than discovered later.

### ⚠️ The two-collection split on the ḥadīth — deliberate, disclosed, and reversible in one line

**The duʿā is pinned to Ṣaḥīḥ Muslim 1342. The beats quote Jāmiʿ at-Tirmidhī 3438.** Both narrations carry the **identical Arabic clause**; the split is purely about which published English reaches the screen.

| | Ṣaḥīḥ Muslim 1342 (Ibn ʿUmar) | Jāmiʿ at-Tirmidhī 3438 (Abū Hurayra) |
|---|---|---|
| grade | **ṣaḥīḥ** (collection's own condition) | **ḥasan (Darussalam)**; Abū ʿĪsā's own remark: `حَسَنٌ غَرِيبٌ` |
| the clause, in Arabic | `اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الأَهْلِ` | **identical** |
| sunnah.com's published English | *"O Allah, Thou art (our) companion during the journey, and guardian of (our) family."* | *"O Allah You are the companion on the journey, and the caretaker for the family"* |
| refuge clause | *"I seek refuge with Thee from hardships of the journey, gloominess of the sights, and finding of evil changes in property and family on return."* | *"I seek refuge in You from the difficulties of the journey, and from returning in great sadness"* |

**Why the split rather than one collection for both:** the founder review checklist asks that *"a 20-something scrolling from a reel understands every word"*. Muslim's English on sunnah.com is Siddiqui's 1970s rendering — *"Thou art"*, *"gloominess of the sights"*. The batch rule inherited from `al-haleem@1` is **re-render only where the published English resolves a contested reading; readability alone is not a licence** — so re-rendering Muslim's English was not available. Quoting a **different, verified, ḥasan narration of the same words** was.

**What it costs:** beats 4–5 render the source line `Jami' at-Tirmidhi 3438` while beat 7 renders `Sahih Muslim 1342`. A careful reader sees two citations for one sentence.

**Three options, all one line:** **(a) as drafted** — Tirmidhī on the story beats, Muslim on the duʿā. **(b) Muslim throughout** — pin stays, beats 4–5 quote *"Thou art (our) companion…"*. **(c) Tirmidhī throughout** — beats and pin both `Jami' at-Tirmidhi 3438`, ḥasan rather than ṣaḥīḥ on the duʿā line the user sees.

### ✅ Catalog-level flag — RESOLVED by the catalogue track, and the replacement was evaluated as a candidate

**Revision 1 flagged id 64's `hadith` field for citing a real Bukhārī ḥadīth about something else** (*"Be in this world as if you are a stranger or a wayfarer"* — detachment from the world) **and gloss-welding it** (*"Your only consistent companion is Al-Wali"*), **and separately for spelling the Name "Al-Wali", which is also catalog id 83's transliteration.**

**As of 2026-08-03 both are fixed.** Re-read from `assets/content/collectible_names.json` this pass, id 64 `hadith` now reads:

> *"In a hadith qudsi, the Prophet ﷺ reported that Allah said: 'I will declare war against him who shows hostility to a pious worshipper of Mine… and if he asks Me, I will give him, and if he asks My protection, I will protect him.' Al-Waliyy is the ally who never withdraws. **(Sahih al-Bukhari 6502 — Sahih)**"*

Numbered, graded, on-topic, and the gloss now spells **Al-Waliyy**. **Both flags close, and both findings were correct.**

### ⚠️ Bukhārī 6502 was fetched and considered as this deck's bar-1 foundation — and rejected. Here is why.

The obvious question, once the card carries it: **should the deck stand on 6502 instead of 93:6?** It was fetched and read in full before answering. **Ṣaḥīḥ al-Bukhārī 6502**, Wayback capture `20220129035033`; Abū Hurayra; *Kitāb ar-Riqāq*; in-book **Book 81, Hadith 91**. Three English strings substring-tested **byte-exact** against the archived page, and the Arabic `مَنْ عَادَى لِي وَلِيًّا فَقَدْ آذَنْتُهُ بِالْحَرْبِ` confirmed present.

**What it has going for it, stated fairly:** it is a **ḥadīth qudsī** — Allah speaking in the first person — the acts are unambiguously Allah's (*"if he asks Me, I will give him, and if he asks My protection… I will protect him"*), **the root `w-l-y` is in the text**, and the card now cites it, which would give this deck the `al-muid@1`-style mitigation that the Name card and the deck teach the same narration. **On paper it looks like it solves bar 1 and bar 4 at once.**

**Four reasons it does not, in descending order of seriousness:**

1. **The `walī` in the text is the human, not Allah.** `مَنْ عَادَى لِي وَلِيًّا` — *"whoever shows hostility to a **walī of Mine**"*. The word denotes **the servant**, and the published English renders it *"a pious worshipper of Mine"*, so **the Name's word does not reach the screen in English at all.** Anchoring a deck about **Allah as Al-Waliyy** on a text whose only `w-l-y` names a *human* would teach the wrong referent. **Bar 4 is not actually met here; it only appears to be.**
2. **It puts the Name behind a condition, and the condition is the opposite of this pack's premise.** The protection in 6502 arrives *"till I love him"*, by way of nawāfil. **This is the hardship pack — its reader is enduring, not performing.** A beat that tells someone at 1am that this protection is what you get after enough voluntary worship is a register failure the deck would deserve to be rejected for.
3. **It carries a doctrinal-confusion risk of exactly the class that just sank `al-qayyum@1` revision 1.** *"I become his sense of hearing with which he hears, and his sense of sight with which he sees"* requires a gloss to be read correctly. **On a reveal screen with no tafsīr, the plainest reading available to a 20-something is theologically wrong** — which is precisely the verifier's *"your Satan = Jibrīl"* finding, one revision later, on a different deck. **The batch should not walk straight back into it.**
4. **Register and collision, minor by comparison.** The ḥadīth opens *"I will declare war against him"* and includes *"his hand with which he grips, and his leg with which he walks"*. And its published English renders `أُعِيذَنَّهُ` as *"his protection (Refuge)"* — **capital R** — which makes the `as-samad@1` *"The Eternal Refuge"* adjacency worse, not better.

**Verdict: 93:6 stays.** 6502 is a genuinely better *card* citation than what it replaced, and a genuinely worse *deck* anchor than 93:6. **Recorded in full so the founder can see the option was fetched, weighed on its merits and declined with reasons — not missed.**

**One consequence for the deck, and it is positive:** the card and the deck now teach **compatible but different** things — the card is Allah's wilāya toward the one who draws near; the deck is Allah taking charge of the one who has no one. **No contradiction to resolve**, which is more than four of the five batch-1 decks could say about their own cards.

**One residual catalogue note, downgraded but not gone:** catalog id **83** is still a different Name transliterated **"Al-Wali"** against id 64's **"Al-Waliyy"**. The card gloss no longer confuses them, but **under the all-99 decision both Names need decks**, and two decks whose `name_intro` transliterations differ by two letters is the `al-muid@1`/`al-jabbar@1` problem in a harder form. *(Noted also: id 83's card now cites **Qur'ān 7:196** — the āyah this deck rejected as human speech. That is a reasonable home for it and creates no collision with this deck, which cites 7:196 nowhere.)*

### Ship-gate note — **this deck's duʿā citation MUST be pinned at transcription time**

If this deck is signed **as drafted (option a or b)**, add — this exact string:

```dart
'al-waliyy@1': 'Sahih Muslim 1342',
```

and the duʿā beat's `source` must read exactly `Sahih Muslim 1342`. **If the founder picks option (c)**, the pin and the beat both become `Jami' at-Tirmidhi 3438` — the map and the beat must change together or the gate goes red in both directions (commit `a12f1db`).

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review (revision 2)**

### Collision check against all 19 existing decks

| existing deck | its inventory | collides? |
|---|---|---|
| **`al-lateef@1`** (shipped) · **`al-afuw@1`** (batch 1) | 12:100/15/20/42, **42:19**, 67:13 · Ibn Mājah 3850, Tirmidhī 3513, 97:3, **42:25** | ✅ **RESOLVED IN R2 — the ash-Shūrā crowding is gone.** Revision 1's verse beat was 42:28, which would have made **three decks in ten āyāt** of one sūrah. **This deck no longer cites Sūrat ash-Shūrā at all.** Recorded rather than deleted, because it was one of revision 1's two stated costs and the founder should see it retired. |
| **`as-samad@1`** (shipped) | 19:2–7, 112:2 | ⚠️ **the deck's one open collision, in English, boxed above.** *"The Eternal Refuge"* (its `name_intro` and its duʿā) vs this deck's *"give [you] refuge"* (verse beat). No shared citation. Insights do not touch. **Not closed; a founder call with a fetched one-line fix.** |
| **`al-hadi@1`** (shipped) | 28:22, 28:15/21/23, 22:54, 1:6 | ⚠️ **new in R2, off-screen: 93:7 — the āyah immediately after this deck's verse beat — is `وَوَجَدَكَ ضَآلًّا فَهَدَىٰ`,** that deck's Name-verb. Not quoted, no shared citation, no shared rendered string. This is the `al-haleem@1` 35:41-`غَفُورًا` class of finding, caught by the sweep. |
| `as-salam@1` · `al-wakeel@1` | 13:28, 9:40, 59:23, Bukhārī 3653, **Muslim 591** · 3:172–174, 65:3, Bukhārī 4563 | ✖ none on citations. **`al-wakeel@1` is worth a word:** Al-Wakeel is *the One you hand outcomes to*; Al-Waliyy is *the One who is with you and over what you left*. Different engines, no shared source. *(`as-salam@1` cites **Muslim 591**, a different narration.)* |
| `al-wadud@1` · `al-ghaffar@1` · `at-tawwab@1` · `al-jabbar@1` · `ash-shafi@1` · `ar-razzaq@1` · `al-fattah@1` · `ar-rahman@1` · `al-baseer@1` | 11:90, Muslim 2747a, Bukhārī 6309 · Bukhārī 7507, 39:53 · Bukhārī 3470, 2:37 · 12:84 etc. · 21:83–84, 26:80, Bukhārī 5743 · 65:2–3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/2731 · 2:286, 7:156, 55:1, Bukhārī 5999 · 58:1, Bukhārī 3364, Ibn Mājah 188 | ✖ none |
| **batch-1 drafts** | `al-ghafur@1` · `al-kareem@1` · `al-haleem@1` · `ar-raheem@1` | ✖ none |
| **batch-2 siblings** | `al-mujeeb@1` (21:87–88, 2:186, Tirmidhī 3505) · **`al-qayyum@1`** (**R2:** Bukhārī 595, 39:42, 2:255) · `al-qadir@1` (2:260, 75:40) · `al-muid@1` (30:27, Muslim 918a) | ⚠️ **One thing to look at directly.** Revision 1 of `al-qayyum@1` was built on **93:1–3**; this deck now anchors on **93:6**. **`al-qayyum@1` R2 no longer touches Sūrat aḍ-Ḍuḥā at all**, so there is no live collision — but the founder should satisfy himself that the sūrah has not been passed from one Name to another to rescue a rejected draft. **The two claims are different:** 93:1–3 says *He has not taken leave of you*; 93:6 says *He took you in when you had no one*. The first is non-abandonment (rejected as Al-Qayyūm's attribute, and it is not Al-Waliyy's either); the second is an act of taking charge. **No shared āyah, no shared quotation, no shared rendered string.** *(R1's disclosed `al-qadir@1` 42:29-`قَدِيرٌ` adjacency is void — 42:28 is gone.)* |

**Verified negative, run programmatically:** **93:6, Ṣaḥīḥ Muslim 1342 and Jāmiʿ at-Tirmidhī 3438** appear in **no** shipped deck and **no** batch-1 draft. No sūrah-93 āyah appears in any shipped deck.

**English pass, run 2026-08-03 (the new bar-3 requirement).** Every rendered `primary` / `label` / `source` string of all 14 shipped decks plus both draft batches was diffed against this deck's strings. **One hit: *"refuge"*, against `as-samad@1` — boxed above.** *"companion on the journey"*, *"caretaker for the family"*, *"great sadness"*, *"orphan"* and *"had been an orphan himself"* return zero hits outside this file.

**Insight-level check.** Beat 8 — *"One half of that sentence is about where you are. The other half is about the people you are not with. And the Prophet ﷺ, who taught it, had been an orphan himself."*

| checked against | its insight | verdict |
|---|---|---|
| `as-samad@1` (shipped) | *"'Needed by all' means everyone leans here… Leaning is not weakness; it is the meaning of the Name."* | ✖ none on insight — that is about **permission to lean**; this is about **simultaneous presence in two places**. ⚠️ **The collision with this deck is lexical, not conceptual — see the box.** |
| `al-lateef@1` (shipped) | *"What you couldn't say was never unsaid to Him."* | ✖ none — and worth checking hard, since two real insight collisions with `al-lateef@1` were found in batch 1. That deck's move is about **being known**; this one's is about **being accompanied**. |
| `al-wakeel@1` (shipped) | *"You were never asked to hold every outcome."* | ✖ none |
| `al-baseer@1`, `al-fattah@1`, `al-afuw@1`, `al-kareem@1`, `ar-raheem@1` | seen · gatekeepers · what was chosen to be asked for · the supply does not run down · the sentence was theirs first | ✖ none |

### Authoring notes (candidates considered)

- **Selected: the travel duʿā (Muslim 1342 / Tirmidhī 3438), anchored on 93:6.** The properties: the catalogue duʿā **is** a clause of a ṣaḥīḥ narration (plan §STEP-3 property 1); the verse anchor is **an act of Allah, in Allah's words, done to a person defined by having no guardian**; and Sūrat aḍ-Ḍuḥā has **no punishment in it at all** and a verified 404 at its end.
- **Rejected as the verse anchor — [Qur'ān 42:28](https://quran.com/42/28), revision 1's anchor.** Fetched and re-read. **The Name is in-text, and the āyah's demonstrated act is sending rain.** `ٱلْوَلِىُّ ٱلْحَمِيدُ` is a paired epithet at the end. **This is the construction plan §7 bar 1 explicitly forbids**, and revision 1 passed it anyway by arguing that the āyah *"names Him `ٱلْوَلِىُّ` in the same breath"*. **Recorded as a rejection, not as a near miss.**
- **Rejected as the verse anchor — [Qur'ān 2:257](https://quran.com/2/257).** Fetched. **The strongest Al-Waliyy āyah in the Qur'ān on bar 1** — the Name is the subject and `يُخْرِجُهُم` is the finite verb of Allah's act in the same clause. **Rejected on bar 5, inside the āyah:** the second half ends *"Those are the companions of the Fire; they will abide eternally therein."* — the same ground `al-mujeeb@1` rejected 40:60 on in this batch. Also `ٱلظُّلُمَـٰت` is on `al-mujeeb@1`'s beat 4. **This is the deck's most painful rejection and it is why bar 4 had to be traded.**
- **Rejected as the verse anchor — [Qur'ān 42:9](https://quran.com/42/9)** (`فَٱللَّهُ هُوَ ٱلْوَلِىُّ وَهُوَ يُحْىِ ٱلْمَوْتَىٰ`). Fetched. Name + act in one clause, but the act is **giving life to the dead** — not walāya, and `al-qadir@1`'s subject in this batch. Ash-Shūrā crowding besides.
- **Rejected as the verse anchor — [Qur'ān 12:101](https://quran.com/12/101) and [7:196](https://quran.com/7/196).** Both fetched. Both are **human speech** — Yūsuf's and the Prophet's ﷺ — so on bar 1 they teach the Name through what a person says rather than what Allah does. 12:101 is also the āyah immediately after `al-lateef@1`'s anchor at 12:100.
- **Rejected as the verse anchor — [Qur'ān 13:11](https://quran.com/13/11), [32:4](https://quran.com/32/4), [33:17](https://quran.com/33/17), [2:107](https://quran.com/2/107).** All fetched. All **negative constructions** — *"there is not for them besides Him any patron"* — which assert a lack about others rather than demonstrate an act.
- **Rejected as the verse anchor — [3:68](https://quran.com/3/68), [3:122](https://quran.com/3/122), [3:150](https://quran.com/3/150), [4:45](https://quran.com/4/45), [5:55](https://quran.com/5/55), [6:127](https://quran.com/6/127), [22:78](https://quran.com/22/78), [45:19](https://quran.com/45/19), [47:11](https://quran.com/47/11), [66:2](https://quran.com/66/2).** All fetched, all **trailing or predicate epithets** with no act of walāya in the clause. Several also sit in battle contexts (3:122, 3:150, 4:45). **This list is the evidence for §"Why bar 4 is traded" and it is the most useful thing in this file for the remaining ~85 decks:** for some Names the Qur'ān simply does not supply a passage that satisfies bars 1 and 4 together.
- **Rejected as the deck's anchor — [Sahih al-Bukhari 6502](https://sunnah.com/bukhari:6502)**, the ḥadīth qudsī of wilāya, which catalog id 64's `hadith` field acquired on 2026-08-03. **Fetched and read in full this pass.** Four reasons, argued at length in the box above: its `walī` denotes **the servant**, not Allah, and never reaches the English at all; it puts the protection behind *"till I love him"*, which is the wrong condition for a pack whose reader is enduring rather than performing; *"I become his sense of hearing…"* is a doctrinal-confusion risk of the exact class that sank `al-qayyum@1` revision 1; and its *"his protection (Refuge)"* worsens the `as-samad@1` adjacency. **A better card citation than what it replaced, and a worse deck anchor than 93:6.**
- **Rejected as the Name for this material — Al-Wali (catalog id 83, "The Governor").** Its authored duʿā is arguably better on register, but the Name is thin Qur'ānically and it is transliterated identically to id 64 on the cards. **Under the all-99 decision this is no longer a substitution question — id 83 needs its own deck, and the shared transliteration is now a scheduling constraint on the catalogue rather than a reason to pick one.**
- **The clean-cut option, withdrawn.** Revision 1 recommended cutting Al-Waliyy from the batch, and the independent verifier endorsed it. **That route is closed by the founder's 2026-08-03 decision** and no version of it is offered here. If this revision is still not good enough, the answer is a third revision, not a different Name.
- **Register check:** no beat attributes waiting, wanting or withholding to the Name. Beat 8 reports the clause, the Arabic on beat 7 and one fetched fact from 93:6, and makes no promise to the reader.
