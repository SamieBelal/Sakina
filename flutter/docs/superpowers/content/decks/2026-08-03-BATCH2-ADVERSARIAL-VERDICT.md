# Batch 2 — independent adversarial verdict

**Verifier:** a second Claude instance, run blind. **Date:** 2026-08-03.
**Blinding held:** `.context/deck-batch-2-review-packet.md` was never opened. Each draft's
`Claim | Source | Grading | Status` table was read only to learn *what is asserted*; no ✅ in it was
treated as evidence. Every scripture string below was re-fetched from source by this verifier.

**Method.** Qur'ān: `api.quran.com/api/v4/verses/by_key/{s}:{a}?fields=text_uthmani,text_imlaei&translations=20,85`
(67 āyāt fetched). Ḥadīth: Wayback captures of the exact `sunnah.com` URLs (sunnah.com 403s automation —
see *Limits* §7). Catalog claims: read directly from `assets/content/collectible_names.json`.
Collision inventory: rebuilt programmatically from `assets/content/name_stories.json`.
Substring tests run in Python, byte-level, with `<sup>` handling made explicit.

---

## Verdicts at a glance

| deck | verdict | why, in one line |
|---|---|---|
| `al-mujeeb@1` | **FIX-THEN-SIGN — blocking** | Scripture is clean, but the deck's own insight (*"He asked for nothing"*) is **already on screen in shipped `ash-shafi@1`** four āyāt away, and the deck's table marks that comparison ✖. |
| `al-qayyum@1` | **REJECT** | The duʿā flag's migration recommendation is **backwards** (pilot's id-51 failure, repeated); bars 1–2 are overclaimed; the "Satan" disclosure omits what the word refers to. |
| `al-qadir@1` | **FIX-THEN-SIGN** | Strongest of the five. Scripture and sweep verified exactly as claimed. Four fixes, none structural. |
| `al-waliyy@1` | **REJECT** | Bar 1 is met by a **trailing epithet** — the construction bar 1 explicitly forbids — and the deck's defence-by-analogy to `al-afuw@1` is demonstrably false. Also an **unmarked elision inside a quoted duʿā**. |
| `al-muid@1` | **FIX-THEN-SIGN — blocking** | Best disclosure quality in the batch, but bar 2 fails on my read, `name_intro` collides in English with shipped `al-jabbar@1`, and two quotations are silently cut. |

**Scripture authenticity across all five: clean.** Every āyah and every ḥadīth is real, correctly
numbered, correctly attributed to collection *and* narrator, correctly graded, and quoted verbatim.
No fabrication was found anywhere. Every failure below is a **reasoning, collision, disclosure or
elision** failure, not an authenticity one.

---

## 1 · `al-mujeeb@1` — **FIX-THEN-SIGN (blocking)**

### Independently confirmed ✔

| item | result |
|---|---|
| 21:87 SI beat-4 quote | **byte-exact substring, raw, no stripping.** `https://api.quran.com/api/v4/verses/by_key/21:87?translations=20` |
| 21:88 SI beat-5 quote | byte-exact, 0 `<sup>` in the fetched string ✔ |
| 2:186 SI beat-6 excerpt | byte-exact, 0 `<sup>` ✔ |
| Successor sweep 21:86 / 21:89 / 21:90 / 2:185 / 2:187 | fetched; all as the deck describes. 21:90 is `So We responded to him, and We gave to him John…` — a second answered call, confirming rather than reversing. |
| Tirmidhī 3505 | Wayback `web.archive.org/web/2024/https://sunnah.com/tirmidhi:3505`. Narrator **Saʿd**, chapter *"Concerning the Supplication of Dhun-Nun"*, `Grade : Sahih (Darussalam)`, in-book 48:136. Row 1.10's English is a byte-exact substring. ✔ |
| Catalog id 37 (row 1.7) | Reproduced exactly: vs `text_imlaei` raw **False**, NFC **False**, consonantal skeleton **True**. Diffs are `إِلَٰهَ`/`إِلَهَ`, `أَنتَ`/`أَنْتَ`, `كُنتُ`/`كُنْتُ`. The deck's statement is accurate and appropriately hedged. ✔ |
| name_intro + duʿā fields vs catalog | byte-identical on all six fields ✔ |
| Citation-negative (21:87, 21:88, 2:186, Tirmidhī 3505 in no shipped deck) | reproduced programmatically ✔ |

### 1a · BLOCKING — the insight collision the deck's own table marks ✖

`ash-shafi@1` **ships today** with this story beat:

> **"He stated the pain and named the Mercy. He demanded nothing."**
> — `assets/content/name_stories.json`, `ash-shafi@1`, story beat 2

`al-mujeeb@1` proposes:

> beat 4 tail: **"There is nothing asked for in it."**
> beat 8: **"He asked for nothing.** He said who Allah is, and who he had been — and that was enough to be answered."

Same sūrah. Four āyāt apart. Same shape: *a prophet in enclosed affliction says one sentence that
asks for nothing, and is answered.* The deck's insight table records `ash-shafi@1` as **✖ none —
"that insight is about the content of the answer, this one about the form of the asking."** That is
false: `ash-shafi@1`'s **middle story beat is about the form of the asking**, in nearly the same words.
The deck compared takeaway-to-takeaway and never compared to the shipped deck's story beats.

This is the exact defect class plan §6 rule 1 exists for (*"the pilot's own collision check caught
`ar-rahman@1` and missed `ash-shafi@1`"*). It is being missed a second time, on the same deck.

**Fix (blocking):** rewrite beat 4's tail and beat 8 off the *"asked for nothing"* axis entirely, or
cut the deck. The deck's headline ⚠️ box, which is about the shared verb `فَٱسْتَجَبْنَا`, is the
*lesser* half of the problem — the shared verb never renders (story beats carry `arabic: ""`), the
shared English insight does.

### 1b · A false ✅ in the sources table (row 1.3)

> *"byte-exact substring **after stripping three `<sup>` footnote markers**. One of the three sits
> *inside* the quoted region, immediately after *'darknesses,'*"*

**Refuted.** Fetched 21:87 has exactly 3 `<sup>` markers, **all three before the opening quotation
mark**; the deck's beat-4 string is a byte-exact substring of the **raw, unstripped** translation
(`sups before quote: 3, sups inside quote: 0`). No stripping was needed and nothing sat inside.
Religiously immaterial — but it is a ✅ describing a check that did not happen as described, which is
the pilot's §6 finding recurring.

### 1c · Unswept sibling-root adjacency (non-blocking)

21:87 — the deck's own story āyah — contains `فَظَنَّ أَن لَّن **نَّقْدِرَ** عَلَيْهِ`. `q-d-r` is
**`al-qadir@1`'s Name root, in this batch**, applied to Allah in a negated form, inside the cited
āyah. Off-screen (the quoted region starts after it, and story beats render no Arabic), but plan §7
asks for the scan and this one was not recorded.

### 1d · Under-weighted engine adjacency (non-blocking)

The deck asserts its engine — *"a call and its answer"* — is unique among shipped decks.
`as-samad@1` ships with *"a hidden call… a lifetime of asking"* → *"The answer came."* That is also
call-and-answer. The deck's table marks `as-samad@1` ✖ on citations and discloses only the off-screen
21:89–90 proximity; the engine claim is over-stated.

---

## 2 · `al-qayyum@1` — **REJECT**

### Independently confirmed ✔

| item | result |
|---|---|
| Bukhārī 4950 | Wayback of `sunnah.com/bukhari:4950`. **Narrator Jundub bin Sufyān** ✔; isnād Aḥmad b. Yūnus ← Zuhayr ← al-Aswad b. Qays ← Jundub ✔; in-book 65:472 ✔; chapter is the 93:3 tafsīr bāb ✔. Beat-4 English is a byte-exact substring ✔. Arabic `فَجَاءَتِ امْرَأَةٌ` confirms the *"wife of Abu Lahab"* parenthetical is the translator's ✔. |
| Occasion of revelation | **Confirmed inside the ṣaḥīḥ narration itself**, not merely in tafsīr: the page reads *"On that Allah revealed: 'By the fore-noon, and by the night when it darkens, your Lord has neither forsaken you, nor hated you.' (93.1-3)"*. The deck's beat-5 framing is defensible on this point. |
| Bukhārī 4983 (row 2.9) | Wayback verified. Same companion Jundub, same isnād root al-Aswad b. Qays, Arabic `مَا أُرَى شَيْطَانَكَ إِلاَّ قَدْ تَرَكَكَ`. ✔ |
| 93:3 SI | byte-exact, 0 `<sup>` ✔ |
| 2:255 SI excerpt | byte-exact **after stripping 2 `<sup>`** — deck's count and positions correct ✔ |
| Abdel Haleem 2:255 | reproduced exactly, including *"the Ever Watchful.Neither"* — the missing space is real ✔ |
| `verses/by_key/93:12` | **HTTP 404** — sūrah-final confirmed ✔ |
| 92:21, 93:4–11, 2:254, 2:256 | fetched; sweep as described. 2:254 does end *"And the disbelievers - they are the wrongdoers."* ✔ |
| Tirmidhī 3524 | Wayback verified: Anas b. Mālik, `Grade : Hasan (Darussalam)`, `هَذَا حَدِيثٌ غَرِيبٌ`, in-book 48:155 ✔ |
| Catalog id 16 fields | byte-identical on all six ✔ |

### 2a · BLOCKING — the duʿā flag's recommendation is backwards. This is the pilot's id-51 failure, repeated.

The deck writes:

> *"this deck did not find a single canonical narration carrying the whole string as printed"*
> *"**Meanwhile the canonical route for that same string is a different narrator entirely:** Jami' at-Tirmidhi 3524 … narrated by **Anas b. Mālik**"*
> *"**Founder decision, catalogue-level:** id 16's `hadith` field could point at a ḥasan Tirmidhī narration instead of an ungraded al-Ḥākim one."*

**All three fail.**

1. **A single narration carrying the whole string exists.** Anas b. Mālik → the Prophet ﷺ to Fāṭima:
   `يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله، ولا تكلني إلى نفسي طرفة عين` — **the exact wording
   `collectible_names.json` prints for id 16**, all three clauses in one narration.
   Recorded by al-Nasāʾī (*ʿAmal al-Yawm wa'l-Layla*; *as-Sunan al-Kubrā*), al-Ḥākim (*Mustadrak*),
   al-Bazzār, al-Bayhaqī (*al-Asmāʾ wa'ṣ-Ṣifāt*).
   Sources fetched: <https://hadithanswers.com/reference-for-the-dua-wa-la-takilni-ila-nafsi-tarfata-ayn/>
   and <https://islamqa.info/en/answers/109609> — two independent Arabic-scholarship pages agreeing on
   text, narrator, collections and grade.
2. **"A different narrator entirely" is false.** The al-Ḥākim/Fāṭima route **is narrated by Anas b.
   Mālik** — the same companion the deck names for Tirmidhī 3524.
3. **The proposed migration would weaken the card, not strengthen it.** Tirmidhī 3524 carries **only
   the first clause** (`يَا حَىُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ`), which is **catalog id 15
   (Al-Hayy)'s duʿā**, verified byte-for-byte against `collectible_names.json`. Pointing id 16's
   `hadith` at Tirmidhī 3524 would attach a citation covering eight of the duʿā's words to a card that
   prints twenty-two — and would duplicate id 15's citation. The **correct** action is the opposite of
   the one proposed: id 16's existing al-Ḥākim/Fāṭima attribution is the right route and should be
   *graded*, not replaced.
4. **"No grade is given on the card"** is true of the card but the deck implies none exists. Gradings
   found: **ṣaḥīḥ** (al-Ḥākim), **isnād ṣaḥīḥ** (al-Mundhirī, *at-Targhīb*), **ḥasan** (Ibn Ḥajar,
   *Natāʾij al-Afkār*), **isnād ḥasan** (al-Albānī, *as-Silsila aṣ-Ṣaḥīḥa* 227).

The plan §6 says a founder signing against a ✅ table is signing against claims that are sometimes
wrong, and that batch 1's example *"would have led the founder to make exactly the wrong migration
decision."* **This is that, again, on a different Name.**

### 2b · BLOCKING — bars 1 and 2 are overclaimed, and the join is not disclosed as a join

- **Bar 1** asks that *the thing the Name does* be demonstrated in the cited text, in Allah's words.
  93:3 is `مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ`. Its verbs are `w-d-ʿ` (take leave of) and `q-l-y`
  (detest). **There is no `q-w-m` root in 93:1–3 and nothing about subsisting or sustaining.** What
  93:3 demonstrates is *non-abandonment of the Prophet ﷺ during a pause in waḥy* — a real and moving
  thing, and **a different attribute from Al-Qayyūm's**.
- **Bar 2** asks that the quality be **shown, not stated**. 2:255 does exactly the forbidden thing: it
  **states** `لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ`. The deck's own bar-2 cell concedes this by phrasing
  it as *"2:255 **states** it as the absence of the two things that pause a human."*
- Therefore the deck's engine — *"revelation paused; the holding did not"* — is **the deck's own
  inference joining a ḥadīth about waḥy to an āyah about self-subsistence.** That is structurally
  identical to the weakness `al-muid@1` confesses in a dedicated section. `al-qayyum@1` confesses
  nothing and records ✅ on both bars.

**This is the single most important asymmetry in the batch: two decks make the same move; one owns it
and one does not.**

### 2c · BLOCKING — the "Satan" disclosure omits what the word refers to

The register box weighs beat 4 as a *tone* risk (*"a sharper edge than the shipped pack carries"*). It
never tells the founder the thing that decides the question: **in the taunt, "your Satan" is the
mocker's name for Jibrīl** — she is jeering that the angel of revelation has abandoned him. Commentary
on this narration is explicit (*"referred to Jibril al-Amin as a devil"*, e.g.
<https://en.tohed.com/hadith/bukhari/4950/>; the woman is Umm Jamīl bint Ḥarb).

On a reveal screen with no gloss and no tafsīr, the plainest reading available to a 20-something is
that the Prophet ﷺ had a personal Satan. That is a **doctrinal-confusion** risk, not a tone risk, and
the founder is being asked to price the wrong thing. The Arabic is also softer than the English the
deck quotes: `إِنِّي لأَرْجُو أَنْ يَكُونَ شَيْطَانُكَ قَدْ تَرَكَكَ` is *"I **hope** your Satan has
left you"*; Muhsin Khan renders it *"I **think**"*. The deck quotes the published English as printed
(correct per the batch rule) but does not note that the jibe is harsher in Arabic than on screen.

### 2d · Minor

Row in the register box attributes `مَا أُرَى شَيْطَانَكَ إِلاَّ قَدْ تَرَكَكَ` to the beat's source.
That Arabic is **Bukhārī 4983's**, not 4950's (4950 reads `إِنِّي لأَرْجُو أَنْ يَكُونَ شَيْطَانُكَ قَدْ تَرَكَكَ`).
Both verified.

---

## 3 · `al-qadir@1` — **FIX-THEN-SIGN**

The strongest deck in the batch. Every mechanical claim I could test came back true.

### Independently confirmed ✔

| item | result |
|---|---|
| 2:260 SI — three beat-4 quotes | each a byte-exact substring, raw ✔ |
| 2:260 SI — beat-5 quote | byte-exact **after stripping 1 `<sup>`**, which does fall inside the quoted region immediately after *"commit them to yourself."* — deck's claim exactly right ✔ |
| 75:40 SI beat-6 | byte-exact, 0 `<sup>` ✔ |
| `verses/by_key/75:41` | **HTTP 404** — sūrah-final ✔ |
| 2:259, 2:261, 75:31–39 | fetched; sweep accurate to the word, including *"Woe to you, and woe!"* at 75:34–35 and the 75:36–39 creation argument ✔ |
| 75:36 refusal box | 75:36 SI = *"Does man think that he will be left neglected?"*, AH = *"Does man think he will be left alone?"* — both reproduced exactly; the deck's reading of `سُدًى` and its refusal are correct and are the best single paragraph in the batch ✔ |
| 46:33/34, 36:81/82, 30:50, 11:61, 40:60 rejections | all fetched; every stated reason holds ✔ |
| Abdel Haleem 2:260 | *"train them to come back to you"* — reproduced; the deck's characterisation (drops the slaughter, changes what is demonstrated) is correct ✔ |
| Catalog id 75 fields | byte-identical on all six ✔ |
| Catalog id 75 `hadith` flag | confirmed verbatim: *"The Prophet ﷺ said: 'Nothing is beyond the power of Allah.' … (Muslim)"* — unnumbered, unlocatable as printed. Flag is fair. ✔ |
| Cross-batch 42:29 `قَدِيرٌ` adjacency to `al-waliyy@1`'s 42:28 | reproduced ✔ |

### Fixes

1. **Beat 5's "He was shown" outruns 2:260.** The āyah stops at Allah's instruction and His statement
   of what *will* happen (`يَأْتِينَكَ سَعْيًا`). It does **not** narrate that Ibrāhīm did it or that
   he saw it. *"He was shown"* is the deck's inference stated on screen as completed fact. Row 3.4
   defends only the weaker claim (*"an instruction rather than a reproof"*). Soften, or label.
2. **Bar 1 is invisible to the user.** The deck deliberately replaces `[Allāh] said` with *"The answer
   came back:"* and drops the attribution before *"Take four birds…"* entirely. Row 3.2 discloses the
   swap, but the consequence is not drawn: **on screen no one is named as the speaker of the āyah's
   command**, so the bar-1 property (*demonstrated in Allah's words*) does not reach the reader. Put
   it in the beat `label` or `source`.
3. **Bar 2 rests on a bracketed interpolation, and the bar cell does not say so.** *"they are **dead**
   and dispersed across hills"* depends on SI's `[after slaughtering them]` — a translator's bracket;
   the Arabic `فَصُرْهُنَّ إِلَيْكَ` does not say it. The deck names this candidly in row 3.3 (*"the
   batch's clearest case of a translation choice doing theological work"*) and then builds bar 2 on
   the chosen reading without repeating the caveat at the bar. Move the disclosure to the bar.
   *(The reading itself is the majority one and is consistent with the āyah's own question
   `كَيْفَ تُحْىِ ٱلْمَوْتَىٰ` — I am not disputing it, only where it is disclosed.)*
4. **Register, non-blocking:** 75:40 is the closing move of an argument *against a denier of
   resurrection* (75:31–35 is the rebuke). The deck discloses the backward direction honestly. Worth
   the founder knowing that the āyah's addressee is not the reader.

---

## 4 · `al-waliyy@1` — **REJECT**

### Independently confirmed ✔

| item | result |
|---|---|
| Muslim 1342 | Wayback verified. **Ibn ʿUmar** ✔, in-book 15:479 ✔, chapter as quoted ✔, Arabic clause `اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ وَالْخَلِيفَةُ فِي الأَهْلِ` ✔, continuation *"We are returning, repentant…"* ✔ |
| Tirmidhī 3438 | Wayback verified. **Abū Hurayra** ✔, `Grade : Hasan (Darussalam)` ✔, `حَسَنٌ غَرِيبٌ` ✔, in-book 48:69 ✔, second route through Suwayd ✔ |
| Beat 4 + beat 5 English | each a byte-exact substring of Tirmidhī 3438's published English ✔ |
| 42:28 SI | byte-exact, 0 `<sup>` ✔ |
| Abdel Haleem 42:28 | *"it is He who sends relief through rain…"* — lower-case opening reproduced; the deck's §G2b "tell" reading is correct ✔ |
| 42:19 / 42:25 / 42:26 / 42:27 / 42:29 | fetched; the ash-Shūrā crowding disclosure is accurate and if anything understated (42:26 also carries `وَيَسْتَجِيبُ`, `al-mujeeb@1`'s root, between two of the three verse beats) |
| 2:257, 12:101, 7:196, 13:11 rejections | all fetched; every stated reason holds ✔ |
| Catalog id 64 fields | byte-identical on all six ✔ |
| Catalog id 64 `hadith` flag + the Al-Wali/Al-Waliyy spelling clash with id 83 | both confirmed verbatim in `collectible_names.json` ✔ |
| Ship gate forces duʿā byte-identity | confirmed at `test/content/name_stories_ship_gate_test.dart` — so *"there is no substitute duʿā"* is correct ✔ |

### 4a · BLOCKING — bar 1 is carried by a trailing epithet, which is what bar 1 forbids

Plan §7 bar 1, verbatim: *"The thing the Name does is demonstrated in the cited text, in Allah's
words — not asserted by the deck's own prose, and **not carried by a trailing epithet**."*

42:28 is `وَهُوَ ٱلَّذِى يُنَزِّلُ ٱلْغَيْثَ مِنۢ بَعْدِ مَا قَنَطُوا۟ وَيَنشُرُ رَحْمَتَهُۥ ۚ
**وَهُوَ ٱلْوَلِىُّ ٱلْحَمِيدُ**`. The demonstrated act is **sending rain**. The Name is a **paired
trailing epithet** at the end of the āyah. Nothing in the āyah shows *protecting friendship*; the
bridge from "sends rain after despair" to "the Protector" is the deck's inference. The deck's own bar-1
cell states the structure plainly and then passes it: *"He sends the relief after they have given up,
and the āyah names Him `ٱلْوَلِىُّ` **in the same breath**."*

And the story beats cannot rescue it: they are a **taught duʿā** — human speech *about* Allah, which
the deck itself concedes, and which it rejected 7:196 and 12:101 for being.

### 4b · BLOCKING — the defence-by-analogy to `al-afuw@1` is false

> *"That is the same construction `al-afuw@1` uses and the reviewer called that deck the batch's cleanest."*

**Refuted by fetch.** `al-afuw@1`'s verse beat is **42:25**:
`وَهُوَ ٱلَّذِى يَقْبَلُ ٱلتَّوْبَةَ عَنْ عِبَادِهِۦ **وَيَعْفُوا۟** عَنِ ٱلسَّيِّـَٔاتِ`
— *"and **pardons** misdeeds"*. There the Name's root is a **finite verb of Allah's action inside the
demonstrating clause**. That is the strongest form of bar 1, and it is **not** the same construction
as an epithet appended after an unrelated act. The analogy that carries this deck's weakest bar does
not hold, and it is the one claim in the deck a founder is most likely to accept without checking.

### 4c · BLOCKING — unmarked elision inside a quoted duʿā

Row 4.2 asserts: *"**No word is changed, added, dropped or reordered.**"*

Tirmidhī 3438's published English is **one continuous quotation**:

> "O Allah You are the companion on the journey, and the caretaker for the family, **O Allah, accompany
> us with Your protection, and return us in security,** O Allah, I seek refuge in You from the
> difficulties of the journey, and from returning in great sadness (…)."

The deck renders beats 4 and 5 as **two consecutive quotation-marked sentences**, silently dropping the
bolded middle clause (`اللَّهُمَّ اصْحَبْنَا بِنُصْحِكَ وَاقْلِبْنَا بِذِمَّةٍ` and
`اللَّهُمَّ ازْوِ لَنَا الأَرْضَ وَهَوِّنْ عَلَيْنَا السَّفَرَ`) with **no ellipsis and no
disclosure**. A reader taps beat 4 then beat 5 and believes that is the duʿā's sequence. The deck's
only disclosure on both rows is *"the beat adds a full stop where the published English runs on"* —
which describes the punctuation and hides the omission.

This is the deck's most fixable defect (add an ellipsis, or mark both beats as excerpts) but it
contradicts an explicit ✅ and sits inside a **quoted supplication**, which is the highest-risk
material in the product.

### 4d · Minor

Row 4.1's paraphrase disclosure (*"the beat drops the takbīr-three-times detail and the
`سُبْحَانَ ٱلَّذِى سَخَّرَ لَنَا هَـٰذَا` opening"*) describes **Muslim 1342's** omissions, but beats
3–5 quote **Tirmidhī 3438**, whose own dropped detail is the finger gesture (`قَالَ بِأُصْبُعِهِ`).
The disclosure is attached to the wrong narration.

Row 4.5's Arabic diff: I could reproduce **only one** difference after NFC — a sukūn (U+0652) on the
lām of `الْأَهْلِ` where the page reads `الأَهْلِ`. The claimed *"four shadda-ordering differences"*
did not survive normalisation on my run. The deck's substantive conclusion (same letters, same words,
one extra mark, raw comparison fails) is correct and appropriately hedged; only the count is
unreproducible.

### Recommendation

**Take the deck's own clean-cut option.** It offers it, and it is right: the register question is real,
the ash-Shūrā crowding is real, and bars 1 is not met on the plan's own wording. Cutting is a
legitimate outcome; batch 1 proved it.

---

## 5 · `al-muid@1` — **FIX-THEN-SIGN (blocking)**

The best-disclosed deck in the batch. Its self-criticism is honest and its rejections are the most
rigorously argued. It still has three problems it did not find.

### Independently confirmed ✔

| item | result |
|---|---|
| Muslim 918a | Wayback verified. **Umm Salama** ✔, in-book 11:4 ✔, chapter *"What should be said at times of calamity?"* ✔, isnād Yaḥyā b. Ayyūb / Qutayba / Ibn Ḥujr ← Ismāʿīl b. Jaʿfar ← Saʿd b. Saʿīd ← ʿUmar b. Kathīr b. Aflaḥ ← Ibn Safīna ← Umm Salama ✔ |
| Beats 3, 4 and row 5.3's source sentence | all three byte-exact substrings of the archived English ✔ |
| Continuation past beat 5 (Ḥāṭib, the marriage message) | reproduced verbatim; no punishment, no reversal ✔ |
| 30:27 SI | byte-exact, 0 `<sup>` ✔ |
| 30:26, 30:28, 30:50 | fetched; sweep accurate ✔ |
| 85:13/85:14, 10:4, 30:11/30:12 rejections | all fetched; **every** stated reason holds — 85:14 is `وَهُوَ ٱلْغَفُورُ ٱلْوَدُودُ` ✔, 10:4 ends in *"a painful punishment"* ✔, 30:12 is *"the criminals will be in despair"* ✔ |
| Abdel Haleem 30:27 | *"will do it again**-** this"* — the hyphen-as-dash is real ✔ |
| Catalog id 68 fields | byte-identical on all six ✔ |
| Catalog id 68 `hadith` field holds a **Qur'ān** citation | confirmed verbatim ✔ — and it does make exactly the join this deck makes, which is a genuine mitigation |
| Row 5.5's core warning (the catalogue duʿā is **not** the narrated wording) | confirmed: narration is `اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا` (`kh-l-f`), catalogue is `يَا مُعِيدُ أَعِدْ إِلَيَّ…` (`ʿ-w-d`). **The deck is right to ship unpinned.** ✔ |

### 5a · BLOCKING — `name_intro` collides in English with a shipped deck

`al-jabbar@1` **ships today** with:

> `name_intro` primary: **"The Compeller — Restorer of the Broken"**
> story beat 3: **"Sight restored. Son restored. Whole again."**

`al-muid@1` proposes `name_intro`: **"The Restorer"**.

Bar 3 must be judged against **what renders** (plan §7, the schema fact). What renders here is the
word *Restorer*, on the second beat of both decks, to the same user. The collision table argues the
*engines* at length and never notices that **the Name's English gloss is already taken by a shipped
deck**. This is a bar-3 finding of the same shape as the root checks the deck runs carefully in
Arabic, missed because it was only run in Arabic.

### 5b · BLOCKING — beat 3 silently truncates the taught duʿā

Muslim 918a's taught sentence is:

> *"…what Allah has commanded him, **"We belong to Allah and to Him shall we return;** O Allah, reward
> me for my affliction and give me something better than it in exchange for it,"…"*
> Arabic: `إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا`

Beat 3 says *"He taught **one sentence** for the moment something is taken:"* and then quotes only the
second half, **dropping the istirjāʿ**, with no ellipsis. Row 5.1 discloses the *framing* change
(*"replacing the conditional clause"*) but not the **head of the quotation being cut**. Calling the
remainder *"one sentence"* while the narration's taught formula opens with `إِنَّا لِلَّهِ` is an
unmarked elision inside a supplication — same class as `al-waliyy@1` 4c, and in a deck whose entire
payload is *what she said*.

### 5c · BLOCKING — beat 8 interprets where row 5.7 claims it reports

> Beat 8: *"**She said it after saying it could not be true.** The narration keeps both, in that order…"*
> Row 5.7: ✅ *"It reports the order of the narration … **and nothing else**."*

What Umm Salama said is `أَىُّ الْمُسْلِمِينَ خَيْرٌ مِنْ أَبِي سَلَمَةَ` — *"Which Muslim is better
than Abū Salama?"* — a rhetorical question about **her husband's rank**. She did not say the duʿā, or
the promise, *"could not be true."* Reading her question as a denial of the promise is the deck's
inference, on screen, unlabelled, and specifically contradicted by its own ✅. Row 5.2 shows the deck
is capable of catching this class (it flags *"she thought"* vs *"she said"*, correctly) — the larger
drift in beat 8 slipped past the same check.

### 5d · Bar 2 — my independent read: it fails

The deck offers this as a founder call. My verdict, independently:

- 30:27's `يُعِيدُهُ` is **eschatological re-origination of creation**. Catalog id 68's own `meaning`
  field agrees: *"The One who brings back **creation after its end**."*
- The story is **replacement of a spouse**, whose verb is `أَخْلَفَ` (`kh-l-f`) — a different root,
  which the deck states.
- The deck's defence — *"the deck asserts the join in no beat"* — **is false in the format's own
  terms.** `BeatRevealFlow` is a tap-through spine: beat 5 (she was given a replacement) → beat 6 (He
  repeats creation) with nothing between them. **Juxtaposition on a beat spine is assertion.** A deck
  cannot both choose the adjacency and disclaim the inference.
- Genuine mitigation, verified: catalog id 68's card already makes this join and cites this āyah, so
  the deck introduces no contradiction the app does not already carry.

**If the founder holds bar 2, the deck's own recommended replacement (Al-Muhyi, id 69) applies.**

### 5e · Minor

Beat 1's *"almost nobody can say it and mean it"* is an unsourced claim about people, and is the one
line in the deck that edges toward moralising at a reader who is enduring. Not covered by any row.

---

## 6 · Cross-batch findings

1. **Two decks make the same unstated join; one confesses it.** `al-muid@1` writes a dedicated
   *"honest weakness"* section for joining a re-creation āyah to a replacement story. `al-qayyum@1`
   makes the identical move (a waḥy-pause narration joined to a self-subsistence āyah) and records ✅
   on both bars. A founder reading the two packets side by side will conclude the second deck is
   stronger. It is not; it is less disclosed.
2. **Three of the five have unmarked elisions or overruns inside quoted material**
   (`al-waliyy@1` 4c, `al-muid@1` 5b, `al-qadir@1` fix 1). The batch's disclosure discipline is
   excellent on *translation choice* and weak on *where a quotation starts and stops*. That asymmetry
   is worth a standing rule: **any quoted region that is not the whole narrated sentence carries a
   visible ellipsis on the beat, not a note in a table.**
3. **Bar 3 was run in Arabic and not in English.** `al-muid@1`'s *"The Restorer"* vs shipped
   `al-jabbar@1`'s *"Restorer of the Broken"*, and `al-mujeeb@1`'s *"asked for nothing"* vs shipped
   `ash-shafi@1`'s *"He demanded nothing"*, are both **on-screen English collisions with shipped
   decks** that the Arabic-root sweeps could not see. Plan §7's schema note says bar 3 should be judged
   against what renders; what renders is mostly English.
4. **The catalogue-flag pattern the batch reports is real** — I confirmed all four `hadith`-field
   defects verbatim (id 16 al-Ḥākim unnumbered/ungraded, id 75 unlocatable + *(Muslim)*, id 64
   off-topic Bukhārī + a card gloss inside the quote, id 68 a Qur'ān citation in a ḥadīth column) —
   **but the batch's own recommendation for id 16 is the wrong direction** (§2a). The finding stands;
   the remedy for one of the four does not.
5. **Sūrat ash-Shūrā is worse than disclosed.** 42:19 (`al-lateef@1`, shipped), 42:25 (`al-afuw@1`,
   batch 1), 42:28 (`al-waliyy@1`, batch 2) — three verse beats in ten āyāt; and 42:26, sitting between
   two of them, carries `وَيَسْتَجِيبُ`, `al-mujeeb@1`'s Name root, and ends *"But the disbelievers
   will have a severe punishment."*

---

## 7 · Could not verify — the limits of *this* pass

State these to the founder before he signs against anything above.

1. **Ḥadīth checking is not independent of sunnah.com as a corpus.** sunnah.com 403s automated
   fetching, so — exactly like the drafter — I used **Wayback captures of the same sunnah.com URLs**.
   Same digitisation, same Darussalam grade lines. **No printed edition, no Shamela, no Dorar, and no
   isnād was audited.** Where I write "grade verified" I mean *the grade line printed on that page was
   read*, not that the grading was independently assessed.
2. **The Fāṭima/Anas narration (§2a) was verified through secondary scholarship, not a primary
   collection.** I reached <https://hadithanswers.com/…> and <https://islamqa.info/en/answers/109609>,
   which agree on wording, narrator (Anas b. Mālik), collections and gradings. I did **not** reach
   al-Nasāʾī's *ʿAmal al-Yawm wa'l-Layla* or al-Ḥākim's *Mustadrak* directly, and the two pages give
   **different Mustadrak page references** (1/545 vs 1/730). The *existence and wording* of the
   narration is well-attested by two independent sources; the *exact volume/page* is not verified.
3. **The "your Satan = Jibrīl" reading (§2c) is commentary, not the Bukhārī page.** The narration
   itself carries only the taunt. I read the identification on a tafsīr-summary page, not in a primary
   tafsīr.
4. **I did not run the ship gate.** I read `test/content/name_stories_ship_gate_test.dart` and confirmed
   the bidirectional `renderedDuaSources` assertion, the byte-identity duʿā assertions, the beat-order
   assertion and the verse-beat `source` requirement are exactly as the decks describe. I did **not**
   transcribe the decks into `name_stories.json` and did not verify the claim that the gate passes
   over `existing ∪ batch 2` with 0 failures.
5. **I did not re-verify batch 1's own content** beyond the specific claims batch 2 makes about it
   (`al-afuw@1`'s 42:25 construction, `ar-raheem@1`'s takeaway, `al-haleem@1`'s 35:45 precedent).
6. **Arabic normalisation is a soft floor.** All "skeleton identical" results strip **all** combining
   marks and format characters. That is the right test for *is this the same word*, and the wrong test
   for *is this the same vowelling*. Where a deck says "skeleton True", read it as **same letters, not
   same diacritics**.
7. **I judged register and reverence as a reader, not as a scholar.** §2c is my strongest register
   finding and it rests on a claim about how a 20-something with no tafsīr will read one word. That is
   a judgement, and the founder's is the one that counts.
8. **Nothing was edited.** No DRAFT file, no `name_stories.json`, no test, no commit.
