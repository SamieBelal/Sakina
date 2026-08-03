# Wave 1 adversarial verdict — `al-malik@1` (id 4) and `al-baqi@1` (id 98)

**Verifier:** independent blind adversarial agent, 2026-08-03. Instructed to **refute**, and to
default to reject where a claim could not be independently confirmed.
**Drafts under review:** `2026-08-03-al-malik-DRAFT.md`, `2026-08-03-al-baqi-DRAFT.md`.
**Method:** every quotation re-fetched from source in this session. The drafts' `Claim | Source |
Grading | Status` tables were read only to learn *what is asserted*; **no ✅ was treated as evidence.**
Nothing was edited: no draft, no `name_stories.json`, no `collectible_names.json`, no test, no commit.

---

## VERDICTS

| deck | verdict |
|---|---|
| **`al-malik@1`** | **FIX-THEN-SIGN** |
| **`al-baqi@1`** | **FIX-THEN-SIGN** |

**Scripture authenticity is clean on both decks.** Every āyah and every ḥadīth resolves at the exact
bare cited number, quoted accurately, correctly attributed to collection *and* narrator, correctly
graded. No fabrication, no misnumbering, no invented narrator. Every one of the five probes the
assignment set was run to completion and **four of five confirmed the drafter**.

**Neither deck fails a bar.** Both verdicts are FIX-THEN-SIGN because each draft contains at least
one **demonstrably false factual claim that has already propagated into `COLLISION-LEDGER.md` §9b**
as a ruling — which is the exact failure mode the adversarial step exists to catch, third batch
running.

---

# PART 1 — `al-malik@1` (catalogue id 4)

## 1.1 What I confirmed, by fetch

### Probe 1 — "id 4's `dua_arabic` is Qurʾān 3:26 minus `قُلِ`" — **CONFIRMED, and confirmed at the drafter's own precision**

Fetched `https://api.quran.com/api/v4/verses/by_key/3:26?fields=text_uthmani,text_imlaei&translations=20`
and read `assets/content/collectible_names.json` id 4 locally. Normalisation script run by me
(combining marks stripped, `ـ` removed, alif/yāʾ/tāʾ variants folded):

- catalogue rasm: `اللهم مالك الملك توتي الملك من تشاء`
- 3:26 `text_imlaei` rasm minus `قل`, truncated at the same point: **identical.**
- Fully-vocalised word-by-word diff: **exactly one word differs** — catalogue `مَنْ` (with U+0652
  sukūn) vs āyah `مَن`. Every other word byte-identical.

**The drafter's claim 11 holds exactly as written, sukūn and all.** This is the check the pilot got
wrong on 18:10; here it passes. **Pinning is correct**, and `Qur'an 3:26 (opening)` has shipped
precedent — `name_stories.json` already carries parenthesised source qualifiers on verse beats
(`Qur'an 39:53 (excerpt)`, `Qur'an 42:19 (the Name in-text)`, `Qur'an 112:2 (the Name itself)`) and
`cf. Sahih al-Bukhari 5743` on `ash-shafi@1`'s duʿā beat.

### Probe 2 — "Bukhārī 4812 carries `أَنَا الْمَلِكُ، أَيْنَ مُلُوكُ الأَرْضِ`" — **CONFIRMED at the bare number**

`https://web.archive.org/web/20260217212758id_/https://sunnah.com/bukhari:4812` (CDX-selected latest
200 capture; served zstd, decoded).

> `حَدَّثَنَا سَعِيدُ بْنُ عُفَيْرٍ … عَنْ أَبِي سَلَمَةَ، أَنَّ أَبَا هُرَيْرَةَ، قَالَ سَمِعْتُ رَسُولَ اللَّهِ ﷺ يَقُولُ "يَقْبِضُ اللَّهُ الأَرْضَ، وَيَطْوِي السَّمَوَاتِ بِيَمِينِهِ، ثُمَّ يَقُولُ أَنَا الْمَلِكُ، أَيْنَ مُلُوكُ الأَرْضِ"`
>
> English on the page: *"Allah will hold the whole earth, and roll all the heavens up in His Right
> Hand, and then He will say, 'I am the King; where are the kings of the earth?"'*
>
> In-book reference: **Book 65, Hadith 334** — bracketed correctly by 4811 (333) and 4813 (335).

Narrator Abū Hurayra ✔. Narration terminates at `أَيْنَ مُلُوكُ الأَرْضِ` ✔ (claim 2 holds).

### Probe 3 — "Muslim 2787 renders `أَنَا الْمَلِكُ` as *I am the Lord*" — **CONFIRMED**

`https://web.archive.org/web/20260312043506id_/https://sunnah.com/muslim:2787`

> *"Allah, the Exalted and Glorious, will take in His grip the Earth on the Day of Judgment and He
> would roll up the sky in His right hand and would say: **I am the Lord; where are the sovereigns of
> the world?**"*
> Arabic: `… وَيَطْوِي السَّمَاءَ بِيَمِينِهِ ثُمَّ يَقُولُ أَنَا الْمَلِكُ أَيْنَ مُلُوكُ الأَرْضِ`

**The route choice is correct and the reason given for it is true.** Muslim's Arabic is `السَّمَاءَ`
singular and does add `يَوْمَ الْقِيَامَةِ`, exactly as the draft says. Routing Al-Malik through
Muslim's published English would have deleted *King* from a deck about Al-Malik. This is the single
most load-bearing finding in the draft and **it survives adversarial checking intact.**

### Probe 4 — "both elisions carry a visible ellipsis **on the beat**" — **CONFIRMED**

Beat 6 as written renders:
`Say, "O Allah, Owner of Sovereignty, You give sovereignty to whom You will and You take sovereignty away from whom You will… In Your hand is [all] good…"`
The internal `…` (dropping `وَتُعِزُّ … وَتُذِلُّ`) and the trailing `…` (dropping
`إِنَّكَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ`) are **both in the rendered string**, not only in the table.
Beats 4/5 likewise carry `…` at the split in both directions. **Batch 2's rule is satisfied.**

### Probe 5 — successor sweep — **run independently, result confirmed**

| | fetched text (Saheeh International, `translations=20`) | my verdict |
|---|---|---|
| **3:25** | *"So how will it be when We assemble them for a Day about which there is no doubt? And each soul will be compensated [in full for] what it earned, and they will not be wronged."* | Does not contradict. Closes on the absence of wrong. 3:26 opens with `قُلِ`, a new imperative — no mid-sentence continuation. **Clean.** |
| **3:27** | *"…And You give provision to whom You will without account [i.e., limit or measure]."* | No punishment; runs toward provision. `وَتَرْزُقُ` = Ar-Razzaq (13, **shipped**) one āyah out, off-screen. `تُخْرِجُ ٱلْحَىَّ مِنَ ٱلْمَيِّتِ` = Al-Muhyi/Al-Hayy territory. **Clean, adjacency real and correctly disclosed.** |
| **3:28** | *"…And Allāh warns you of Himself, and to Allāh is the [final] destination."* | A warning, two āyāt out, not quoted and not pointed at. **Non-blocking; correctly disclosed rather than buried.** |
| **Bukhārī 4811** | Rabbi/`Abdullah b. Mas'ūd; heavens on one finger, earths on one finger…`فَيَقُولُ أَنَا الْمَلِكُ`; the Prophet ﷺ smiles in confirmation and recites 39:67. | Confirmed verbatim. **The deck's decision to leave it unused is right** and the warning against "enriching" the story from it should be honoured at transcription. |
| **Bukhārī 4813** | Abū Hurayra; first to raise his head after the second trumpet; sees Mūsā at the Throne. | Different subject, no punishment. **Clean.** |
| **Muslim 2788a** | `أَنَا الْمَلِكُ أَيْنَ الْجَبَّارُونَ أَيْنَ الْمُتَكَبِّرُونَ`; English *"I am the Lord; where are the haughty and where are the proud (today)?"* | Rejection is correct: `j-b-r` is shipped `al-jabbar@1`, `k-b-r` is Al-Mutakabbir (19), and the English is a rebuke. **Confirmed.** |

**Bar 5: PASS.** Bukhārī 4812 is free-standing; 3:27 is creation and provision.

### Bar 3, run by me, both axes — **the headline claim holds**

I loaded every `primary` / `label` / `source` field of **all 24 shipped decks** plus the beat strings
of **every other `2026-08-03-*-DRAFT.md`** in the directory, normalised (case, diacritics,
punctuation), and diffed at n-gram widths 8→5.

- **`king` / `kings` as a noun: 0 hits corpus-wide.** (`thinking`, `asking`, `taking`, `breaking`
  match a naive substring search; none match on a word boundary.) **Confirmed.**
- **`sovereign` / `sovereignty`: 0 hits.** Confirmed.
- **Only ≥5-word overlap anywhere:** `this is the name for` — `al-kareem@1`, `al-mujeeb@1`,
  `ar-raheem@1` (shipped) and `2026-08-03-al-mujeeb-DRAFT.md`. **Exactly the three the draft named.**
  Bridge template, ledger §4b classes it as deliberate. **Not a collision.**
- `hand`: 6 hits — `as-salam@1` takeaway (*"outside your hands"*), `al-wakeel@1` bridge/name_intro/
  takeaway, `ar-razzaq@1` ×2. **All four disclosed by the draft, all four verified verbatim.**
- **Firewall between the two decks, run by me:** Al-Malik's beats contain **zero** matches for
  `last|remain|endur|perish`; Al-Baqi's contain **zero** for `king|sovereign|hand`. **Confirmed.**
- Elision justification: ids **43 and 44 carry byte-identical `dua_translation`** — *"O Allah, honor
  me through obedience to You, and do not humiliate me through disobedience to You."* **Confirmed.**
  The `وَتُعِزُّ … وَتُذِلُّ` elision is genuinely forced.
- Ledger §9j precedent checked: 67:1 closes on `قَدِيرٌ`, 67:2 on `ٱلْعَزِيزُ ٱلْغَفُورُ` (shipped
  `al-ghafur@1`) — **confirmed by fetch**; the 67:1 rejection stands.
- 40:16 carries `ٱلْقَهَّارِ` and 40:17 is recompense — **confirmed by fetch**; rejection stands.

### Schema claim 16 — **CONFIRMED**

`lib/widgets/beat_reveal/beat_reveal_models.dart` documents that `label` reaches the screen **only**
for story beats; `beat_screen_view.dart` renders `source` on verse and duʿā beats. The ship gate
(`test/content/name_stories_ship_gate_test.dart:195–244`) locks a duʿā beat's `arabic`,
`transliteration` **and** `primary` to the catalogue byte-for-byte, and asserts `source` against
`renderedDuaSources` **bidirectionally**. **The drafter's reasoning about why the truncation
disclosure must live in `source` is correct.**

---

## 1.2 FAILED / UNVERIFIABLE CLAIMS — `al-malik@1`

### **M1 (BLOCKING, undisclosed, on-screen) — beat 6 renders beat 7's *entire* duʿā English verbatim, two beats apart**

The ship gate forces beat 7's `primary` to equal catalogue id 4's `dua_translation`:

> `O Allah, Owner of Sovereignty, You give sovereignty to whom You will.`

Beat 6 as drafted **contains that string verbatim**, 12 words, byte-exact:

> `Say, "`**`O Allah, Owner of Sovereignty, You give sovereignty to whom You will`**` and You take sovereignty away from whom You will… In Your hand is [all] good…"`

Computed, not eyeballed: a 12-gram intersection of exactly one member. **The user sees the same
sentence twice, two screens apart, in the same wording.**

The draft ran its rendered-English diff against the 24 shipped decks and against its sibling draft.
**It never diffed its own beats against each other** — which is the *identical* methodological error
batch 2 recorded (`al-mujeeb@1` compared takeaway-to-takeaway and missed a beat-to-beat collision),
in a new place. It is disclosed nowhere in the draft, in any form.

This is arguably by construction — the deck's whole premise is that the duʿā *is* the āyah — but a
premise is not a disclosure. **Founder must be shown it and choose:** accept the repetition as the
point, or trim beat 6 to open at *"You give sovereignty to whom You will and You take sovereignty
away…"* (cost: loses the `Say,` the drafter deliberately kept to mark taught speech).

### **M2 (BLOCKING — false claim already in the ledger) — "beat 6 renders id 88's *entire* duʿā English"**

Draft §"What this deck spends for Malik-ul-Mulk (88)", and **propagated verbatim into
`COLLISION-LEDGER.md` §9b** as *"Al-Malik permanently spends id 88 (Malik-ul-Mulk)'s **entire** duʿā
English on a verse beat."*

Catalogue id 88's actual `dua_translation`:

> `O Owner of Sovereignty, You give sovereignty to whom You will and take it from whom You will. Teach me that nothing I hold is truly mine.`

Computed: **`b88 in beat6` → False.** Longest contiguous shared run = **11 words**,
`Owner of Sovereignty, You give sovereignty to whom You will and`. The wording then diverges
(`take it from whom You will` vs `You take sovereignty away from whom You will`) and id 88's **entire
second sentence is absent**.

The collision is real and serious; **the word "entire" is false.** It errs toward over-blocking, so
it is not dangerous — but it is a false statement of fact standing in the collision index as a
ruling, and §9b must be corrected in the same change as the deck.

### **M3 (BLOCKING — false claim) — bar 2's "It is shown twice and stated nowhere"**

The bar-2 row asserts the distinguishing quality is *"shown twice and stated nowhere"*, defending it
with *"The deck's prose never says 'sovereign', 'absolute' or 'in control' about Allah."*

Two refutations, both on rendered beats:

1. **Beat 5 renders `I am the King`.** That is a bare declaration of the attribute. Ledger §9j
   **BLOCKED 24:35** on precisely this ground — *"`ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` **states**
   the attribute. That is what killed `al-haleem@1` rev 1."*
2. **Beat 1 renders `This is the Name for who is actually in charge.`** The drafter's defence
   enumerates three exact strings and avoids them while the beat says the same thing in a synonym.
   *"in charge"* is *"in control"*.

**My ruling: bar 2 still PASSES, but not for the reason given.** What is *shown* and not stated is
the **distinguishing** quality — that sovereignty is His to hand out *and to withdraw* — carried by
the question `أَيْنَ مُلُوكُ الأَرْضِ` and by 3:26's four finite verbs. The bare attribute *is*
stated, twice. **The draft's absolute phrasing does not survive and must be corrected**, and the
tension with §9j's 24:35 ruling must be reconciled on the record rather than left for a future
drafter to discover as an inconsistency.

### M4 (non-blocking, correct the record) — "59:23 is spent by shipped `as-salam@1`"

Draft's rejection table. **False as stated.** 59:23 appears in **no shipped deck**: `as-salam@1`'s
verse beat is 13:28 and *"The Source of Serenity"* is catalogue id 6's `english`, not a rendering of
59:23. Fetched 59:23: Saheeh renders `ٱلسَّلَـٰمُ` as *"the Perfection"* and `ٱلْمَلِكُ` as
*"the Sovereign"* — neither string is in the corpus.

The **rejection is right for stronger reasons than given**: 59:23 is a list of trailing epithets
(bar 1) and additionally carries `ٱلْمُؤْمِنُ` (id 7, `al-mumin@1` drafting this wave),
`ٱلْجَبَّارُ` (shipped `al-jabbar@1`) and `ٱلْمُتَكَبِّرُ` (id 19).

### M5 (non-blocking, disclose) — "two clauses longer" for id 88

Id 88's `dua_arabic` adds exactly **one** clause (`وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ`), not two.
Rasm-identity to 3:26 **confirmed by my own script**; note that id 88 differs from `text_imlaei` in
**three** orthographic words (`مَنْ`/`مَن`, `وَتَنْزِعُ`/`وَتَنزِعُ`, `مِمَّنْ`/`مِمَّن`), not one.

### M6 (non-blocking, record) — two silent edits to the published English of Bukhārī 4812

| page | beat | status |
|---|---|---|
| `roll all the heavens up in His **Right Hand**` | `…up in His **right hand**…` | **Disclosed** in the translation audit, described as *"changing no word."* True of the words; **not true of the act.** Lower-casing a capitalised attribute term is itself an editorial decision on the one surface the deck says it *"deliberately does not adjudicate."* Plan §6 rule 2 territory. Founder should sign it knowingly, or take the drafter's own offered alternative (elide the clause with a visible `…`). |
| `and then He will say**,** 'I am the King` | `and then He will say**:** 'I am the King` | Comma→colon. Immaterial; **not disclosed anywhere.** |

### M7 (non-blocking, orthographic) — macron dropped from the Divine Name

Saheeh International as served by `api.quran.com` reads `Say, "O **Allāh**, Owner of Sovereignty…`.
Beat 6 renders `Allah`. **Orthographic, not material**, and consistent with all 24 shipped decks —
but it is a byte difference in a string the draft calls *"quoted verbatim"*, and the assignment asked
for it. Same applies to 3:25/3:27/3:28 in the sweep table.

### M8 (observation, not a bar failure) — the question's register in the ṣaḥīḥ parallel

Bukhārī 4812's `أَيْنَ مُلُوكُ الأَرْضِ` is read by the deck as consolation. **Muslim 2788a — which
the draft itself fetched — puts the same divine utterance to `الْجَبَّارُونَ` and `الْمُتَكَبِّرُونَ`,
the haughty and the proud.** Bukhārī's own wording is *kings of the earth* and the deck quotes only
Bukhārī, so this is not a bar-5 failure and not a misquotation. It is a founder-visible fact: the
canonical addressee of that question, in its sibling ṣaḥīḥ route, is the arrogant, not the bereaved.

### M9 (craft, non-blocking) — "ends on a question" is rendered twice

Beat 3: *"It is short, and it ends on a question."* Beat 5: *"That is the whole narration. It ends on
the question."* Two of the deck's eight screens spend their closing sentence on the same
meta-observation.

---

# PART 2 — `al-baqi@1` (catalogue id 98)

## 2.1 What I confirmed, by fetch

### Probe 6 — "Tirmidhī 2470 carries BOTH Darussalam *ḥasan* and at-Tirmidhī's own `هَذَا حَدِيثٌ صَحِيحٌ`" — **CONFIRMED, both lines present**

`https://web.archive.org/web/20250814204011id_/https://sunnah.com/tirmidhi:2470`

> *Abu Maisarah narrated from 'Aishah that they had slaughtered a sheep, so the Prophet (s.a.w) said:*
> *"What remains of it?" She said: "Nothing remains of it except its shoulder." He said: "All of it
> remains except its shoulder."*
>
> `… عَنْ أَبِي مَيْسَرَةَ، عَنْ عَائِشَةَ، أَنَّهُمْ ذَبَحُوا شَاةً فَقَالَ النَّبِيُّ ﷺ "مَا بَقِيَ مِنْهَا". قَالَتْ مَا بَقِيَ مِنْهَا إِلاَّ كَتِفُهَا. قَالَ "بَقِيَ كُلُّهَا غَيْرَ كَتِفِهَا". **قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ صَحِيحٌ**. وَأَبُو مَيْسَرَةَ هُوَ الْهَمْدَانِيُّ اسْمُهُ عَمْرُو بْنُ شُرَحْبِيلَ`
>
> **Grade: Hasan (Darussalam)** · In-book reference: **Book 37, Hadith 56**

**Both grade lines exist on the page, exactly as claimed.** Beats 4–5 are **byte-exact** against the
page's published English. Abū Maysara's identification as `عَمْرُو بْنُ شُرَحْبِيلَ` ✔. The
grade-honesty disclosure (deck claims the weaker of the two) is accurate and admirable.

Translation audit spot-checked against the page's Arabic: `مَا بَقِيَ مِنْهَا` → *"What remains of
it?"* ✔; `مَا بَقِيَ مِنْهَا إِلاَّ كَتِفُهَا` ✔; `بَقِيَ كُلُّهَا غَيْرَ كَتِفِهَا` ✔ with the
fronting preserved. **No interpolation, no brackets, no attribute clause.** The draft's claim that
this is the cleanest translation surface of the pair is correct.

### Probe 7 — 16:96 and its sweep — **CONFIRMED**

| | fetched text | my verdict |
|---|---|---|
| **16:96** | `مَا عِندَكُمْ يَنفَدُ ۖ وَمَا عِندَ ٱللَّهِ بَاقٍ ۗ وَلَنَجْزِيَنَّ ٱلَّذِينَ صَبَرُوٓا۟ أَجْرَهُم بِأَحْسَنِ مَا كَانُوا۟ يَعْمَلُونَ` — *"Whatever you have will end, but what Allāh has is lasting. And We will surely give those who were patient their reward according to the best of what they used to do."* | Beat 6 matches the fetched Saheeh text as a substring (see **B5** on the macron). Trailing `…` **visible on the beat** ✔. Elided clause is exactly the one named ✔, and it **reinforces** rather than qualifies — so the truncation weakens the deck's own case. **Correct.** |
| **16:95** | *"…Indeed, what is with Allāh is best for you, if only you could know."* | Same argument one step earlier; no punishment; 16:96 does not open mid-sentence. **Clean.** |
| **16:97** | *"…We will surely cause him to live a good life, and We will surely give them their reward…"* | Runs toward reward. `فَلَنُحْيِيَنَّهُۥ` (Al-Muhyi/Al-Hayy) one āyah out, off-screen, correctly disclosed. **Clean.** |
| **16:98** | *"So when you recite the Qur'ān, [first] seek refuge in Allāh from Satan, the expelled…"* | Different subject. **Clean.** |
| **Tirmidhī 2469** | *"The Messenger of Allah (s.a.w) had a leather cushion stuffed with palm fibres which he would lean on."* — **Sahih (Darussalam)** | Household austerity, ʿĀʾisha, no warning. **Clean.** |
| **Tirmidhī 2471** | *"We, the family of Muhammad, would go for a month without kindling a fire, having only water and dates."* — **Sahih (Darussalam)** | Same. **Clean.** |
| **Muslim 2958a** | `… إِلاَّ مَا أَكَلْتَ فَأَفْنَيْتَ أَوْ لَبِسْتَ فَأَبْلَيْتَ **أَوْ تَصَدَّقْتَ فَأَمْضَيْتَ**` — *"…or which you gave as charity and sent it forward?"* | Confirmed verbatim, root `f-n-y` ✔. Quoted on no beat ✔. The grade trade (ṣaḥīḥ Muslim declined for a ḥasan-graded Tirmidhī) is real and correctly surfaced. |

**Bar 5: PASS.** The strongest bar-5 result of the pair.

### Probe 8 — the three grounds for refusing 55:26–27 — **(a) TRUE · (b) FALSE · (c) TRUE**

All five āyāt (55:25–29) fetched by me.

**(a) TRUE, and it is the real ground.** 55:27 Saheeh: *"And there will remain the Face of your Lord,
**Owner of Majesty and Honor**."* Shipped `as-salam@1` beat 6 (`kind: dua`) `primary` reads:
*"O Allah, You are Peace and from You comes peace. **Blessed are You, O Owner of Majesty and
Honor.**"* — **byte-identical 5-word phrase, verified in `assets/content/name_stories.json`.** Ledger
§6d already records id 89's Name-phrase as pre-spent. **Confirmed.**
*(One refinement: the draft calls the string "the whole Name of catalogue id 89". Id 89's `english`
is actually "Lord of Majesty and **Bounty**". The string is a translation of the Name, not the
catalogue's rendering of it.)*

**(b) FALSE — see B1 below. This is the blocking finding on this deck.**

**(c) TRUE.** 55:28 is `فَبِأَىِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ` — *"So which of the favors of your
Lord would you deny?"*, immediately after the excerpt. **Confirmed.**

**28:88 rejection confirmed** by fetch: root is `h-l-k` (`كُلُّ شَىْءٍ هَالِكٌ`), sūrah-final. Correct.

### Probe 9 — tracing the duʿā — **I could not trace it either. UNPINNED is correct. But I found something the drafter missed.**

I ran four independent Arabic web searches on the exact opening phrase and its variants, and
attempted `dorar.net`'s public API (**blocked by Cloudflare — recorded as a method limit**). **No
page in any primary collection carries this wording.** The drafter's refusal to act on a search
engine's generated Abū Dāwūd assertion was correct.

**NEW FINDING — the duʿā is an authored analogue of a *narrated* formula, and that is a trap.**
Fetched `https://web.archive.org/web/20260419105706id_/https://sunnah.com/abudawud:1173` (Sunan Abī
Dāwūd, Kitāb al-Istisqāʾ, narrated **ʿĀʾisha** — the same narrator as the deck's own story):

> `… اللَّهُمَّ **أَنْتَ اللَّهُ لاَ إِلَهَ إِلاَّ أَنْتَ الْغَنِيُّ وَنَحْنُ الْفُقَرَاءُ** أَنْزِلْ عَلَيْنَا الْغَيْثَ …`
> Abū Dāwūd's own comment on the page: `وَهَذَا حَدِيثٌ غَرِيبٌ إِسْنَادُهُ جَيِّدٌ`

Catalogue id 98's duʿā — `اللَّهُمَّ أَنْتَ الْبَاقِي وَنَحْنُ الْفَانُونَ …` — is **the same
syntactic template `اللَّهُمَّ أَنْتَ الْ[Name] وَنَحْنُ الْ[opposite]` with the attribute pair
swapped**. That explains its shape, **confirms it is authored rather than narrated**, and therefore
**strengthens UNPINNED rather than undermining it**.

**Record it as a trap.** A future drafter searching this template will land on Abū Dāwūd 1173 and may
propose pinning id 98 to it. That would be the id-51 / id-16 shape a fifth time. **Id 98 must never
be pinned to Abū Dāwūd 1173: the Name in the narrated formula is `الْغَنِيّ` (Al-Ghaniyy, id 92), not
`الْبَاقِي`.**

### Bar 3, run by me — **the headline claim holds**

Same corpus and method as Part 1. Al-Baqi's nine beat strings return **ZERO** overlaps at n≥5 against
any of the 24 shipped decks **and** against every other `2026-08-03-*` draft. Not even the bridge
template — beat 1 uses no scaffolding phrase, exactly as claimed. Verified independently:
`al-lateef@1` does carry *"This Name belongs to"*, and three shipped decks carry *"This is the Name
for"*.

Root axis: `b-q-y` only on rendered fields ✔. `ṣ-b-r` confined to the elided clause ✔. `m-l-k`
absent from every Al-Baqi beat ✔ (firewall verified mechanically, both directions).

---

## 2.2 FAILED / UNVERIFIABLE CLAIMS — `al-baqi@1`

### **B1 (BLOCKING — false claim already in the ledger) — "55:29 is id 34 As-Samad's `meaning` almost verbatim"**

Draft's rejection table, ground (b); draft claim 10 marks it ✅ *"confirmed, not assumed"*; and it is
**propagated verbatim into `COLLISION-LEDGER.md` §9b**.

| | text |
|---|---|
| **55:29, fetched** | `يَسْـَٔلُهُۥ مَن فِى ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۚ كُلَّ يَوْمٍ هُوَ فِى شَأْنٍ` — *"Whoever is within the heavens and earth asks Him; every day He is in [i.e., bringing about] a matter."* |
| **`collectible_names.json` id 34 `meaning`, read locally** | *"The One to whom all creation turns in need, yet He needs nothing."* |

**Zero shared substantive words. No shared run of any length above the article.** "asks Him" vs
"turns in need"; "Whoever is within the heavens and earth" vs "all creation"; and 55:29 has **no
counterpart at all** to id 34's operative second clause *"yet He needs nothing"*.

This is a **conceptual** adjacency — a defensible one — described as *"almost verbatim"* and marked
✅ *"confirmed, not assumed."* **It is neither verbatim nor near-verbatim, and the ✅ does not hold.**
Both the draft and **ledger §9b** must be corrected in the same change as the deck.

Why this matters beyond bookkeeping: **it is one of the three grounds on which the deck refused the
Name's natural verse**, and it is the ground the drafter volunteered as proof of diligence. See B3.

### **B2 (BLOCKING) — beat 3's *"Most of it left the house"* is NOT the entailment the draft says it is**

Draft claim 3: ✅ *"verified as an entailment"* of `مَا بَقِيَ مِنْهَا إِلاَّ كَتِفُهَا`.

ʿĀʾisha's sentence entails only that **nothing of it remains except the shoulder**. It says nothing
about *where* it went — it is equally consistent with the household having eaten it. **"Left the
house" is a locational fact neither speaker states.** Beat 8's *"the part that never left"* inherits
the same unstated premise, and the deck's entire engine rests on it.

The inference the deck actually needs — that the rest was **given away** — comes from the **Prophet's
ﷺ reply**, not from ʿĀʾisha's: *"All of it remains except its shoulder"* is only coherent if the rest
went somewhere that counts with Allah. That is a strong inference and I do not dispute it. **But the
draft attributes the entailment to the wrong sentence, and then re-describes the charity reading it
correctly declines to assert as a weaker claim that is not entailed at all.**

The §"one thing this story does not say" section is honest about the charity gap and then closes it
with a paraphrase carrying the same content. **Fix is one line** — e.g. *"Most of it was already
gone."* — and it costs the deck nothing.

### **B3 (BLOCKING disclosure) — bar 1 is weaker than the draft states, and the stronger text was refused partly on B1**

The bar-1 row calls 16:96 the deck's carrier. Grammatically:

> `وَمَا عِندَ ٱللَّهِ **بَاقٍ**` — `بَاقٍ` is a predicate **of `مَا عِندَ ٱللَّهِ`** ("what is with
> Allah"), **not of Allah**. There is no finite verb of Allah's action in the clause.

Compare **ledger §9a**, which awarded 4:130 to Al-Mughni over Al-Wasi **on exactly this grammar**:
`يُغْنِ ٱللَّهُ` is a finite verb of Allah's action → bar 1 satisfied; `وَٰسِعًا` sits in a trailing
predicate → *"bar 1 forbids it."*

Now compare the refused text: **55:27 is `وَيَبْقَىٰ وَجْهُ رَبِّكَ`** — a **finite verb** from the
Name's own root, with the Face of your Lord as its **subject**. **By the ledger's own §9a test, the
āyah this deck refused is the grammatically stronger bar-1 carrier, and one of the three grounds for
refusing it is false (B1).**

**And the drafter never considered the tool it used elsewhere.** Ground (a) — the only serious one —
is defeated by a **visible ellipsis**, the exact device applied to 16:96 four sections earlier:

> *"Everyone upon it will perish, and there will remain the Face of your Lord…"* — Qur'an 55:26–27

That renders zero words of *"Owner of Majesty and Honor"*, leaves 55:28's refrain outside the
excerpt, and carries `b-q-y` as a finite verb. **I am not recommending the swap** — 55:26–27 has a
bar-2 problem of its own (it is nearly a bare statement of the attribute, ledger §9j territory), and
16:96's `يَنفَدُ`/`بَاقٍ` antithesis serves the deck's engine better. **But the founder is currently
being asked to sign a refusal argued on a false ground, with an available escape unexamined.** Record
the grammar honestly and record why 16:96 is still preferred.

### B4 (non-blocking, correct the record) — "an eight-word shared `meaning` run" between ids 80 and 98

Computed over the actual catalogue strings:

- id 80: *"The One who remains after all creation has perished."*
- id 98: *"The One who remains forever after all creation has perished."*
- **Longest contiguous shared run: 5 words** — `after all creation has perished.` (plus a separate
  4-word run, `The One who remains`).

**There is no eight-word run.** `COLLISION-LEDGER.md` §9c states it correctly, **with an ellipsis**
(*"The One who remains … after all creation has perished"*); the draft drops the ellipsis and asserts
a single contiguous run. The finding itself is real and the scheduling constraint on Al-Akhir (80)
stands. Id 80's `lesson` is verbatim *"Everything ends — except Al-Akhir. Invest in what reaches
Him."* — the draft's characterisation of it as this deck's engine in one sentence is **fair**.

### B5 (non-blocking, orthographic) — macron dropped

`api.quran.com` Saheeh reads *"but what **Allāh** has is lasting."* Beat 6 renders `Allah`.
Orthographic, consistent with all 24 shipped decks, **not material** — recorded because the beat is
described as *"Saheeh International verbatim."*

### B6 (non-blocking, factual error in the sweep table) — Tirmidhī 2471's chapter heading is misattributed

The draft's `n+1 · Tirmidhī 2471` row states the chapter heading on **that** page is *"Chapter: His
SAW Saying About the Sheep."* It is not. Fetched:

- **2470** — `Chapter: His SAW Saying About the Sheep` (chapter 33)
- **2471** — `Chapter: The Ahadith of Aishah, Anas, Ali, and Abu Hurairah` (chapter 34)
- **2469** — `Chapter: His SAW Saying About the Curtain: "It Reminds Me of the World"` (chapter 32)

Also: the draft says 2469 is *"Same chapter, same narrator"* as 2470. **Same book (37) and same
narrator (ʿĀʾisha); three different chapters.** Neither error changes the bar-5 verdict — all three
are household-austerity narrations with no warning — but both are ✅-marked assertions about a page
that do not match the page.

---

# PART 3 — Ledger §9g, offered rather than owed

§9g asks the blind verifier to rule on **`al-mumin@1` beat 4 vs shipped `al-wakeel@1` story beat 1**.
**That is not one of my two assigned decks**, so this is offered, not a ruling of record — whoever
verifies `al-mumin@1` owns it.

Run against my corpus: `"…and were told to be afraid. They were not."` vs
`"Are you afraid of me?" "No."` share **zero n-grams at n≥4**. Batch 2's precedent collision
(`He asked for nothing` / `He demanded nothing`) was a near-identical **phrase**; this is a thematic
echo with no textual overlap. **I would rule NON-BLOCKING — but on the string evidence, not on the
drafter's three reasons**, two of which are interpretive and therefore not the kind of thing an
adversarial pass can confirm.

---

# PART 4 — COULD NOT VERIFY / limits of *this* pass

Stated because the founder signs against this document too.

1. **I reached no corpus independent of sunnah.com.** Every ḥadīth in this verdict — Bukhārī
   4811/4812/4813, Muslim 2787/2788a/2958a, Tirmidhī 2469/2470/2471, Abū Dāwūd 1173 — was read from
   a **Wayback capture of a sunnah.com page**. I attempted **`dorar.net`'s public API and was blocked
   by Cloudflare** (verified: the block fires on a known-good control query too). No Shamela, no
   printed edition, no Arabic-primary database. **This limit is now four passes old and unbroken.**
2. **I audited no isnād.** Published grade lines were accepted as printed. For Tirmidhī 2470 that
   means both *Hasan (Darussalam)* and `قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ صَحِيحٌ` are taken as
   printed; I did not evaluate `أَبُو مَيْسَرَةَ` / `عَمْرُو بْنُ شُرَحْبِيلَ` against any rijāl
   work, nor `أَبُو إِسْحَاق`'s tadlīs, which is the obvious question a muḥaddith would ask of this
   chain. **Nobody in this pipeline has yet asked it.**
3. **My ḥadīth reading is the same digitisation as the drafter's.** For `bukhari:4812` and
   `tirmidhi:2470` the CDX API returned the **same latest capture the drafter cited**. Independent
   *retrieval*, not an independent *witness*.
4. **The Qurʾān side is single-source.** `api.quran.com`, Saheeh International (`translations=20`),
   for Arabic and English both. I fetched no second muṣḥaf, no second translation API, and **no
   Abdel Haleem** for 3:26 or 16:96 — so the plan §6 rule-2 cross-check on those two renderings
   rests on the drafter's clause-by-clause audit plus my reading of the Arabic, not on a second
   published English.
5. **My duʿā-provenance search is negative evidence only.** Four Arabic web searches and one blocked
   API do not prove no narration exists. What I *did* establish positively is the Abū Dāwūd 1173
   template match — which explains the wording without supplying a pin.
6. **I ran no `flutter test`.** I read the ship gate's assertions; I did not execute them. The
   `renderedDuaSources` transcription requirement for `al-malik@1` is verified as *necessary* from
   the source, not as *passing*.
7. **The rendered-English corpus for the other in-flight drafts is heuristic.** For the 24 shipped
   decks I diffed the actual JSON fields. For the sibling `2026-08-03-*-DRAFT.md` files I extracted
   `> `-prefixed lines from markdown, which will include some prose the beats do not render. That
   biases toward **false positives**, not misses — and it returned no hit for either of my decks
   beyond the bridge template.
8. **Bar 2 and bar 5 are judgement, not measurement.** M3, M8 and B3 are arguments. I have marked
   which findings are mechanical (M1, M2, B1, B4, B6 — all computed or read off a fetched page) and
   which are not. **Only the mechanical ones should be treated as settled by this pass.**

---

# PART 5 — the change list a signer needs

**`al-malik@1` — FIX-THEN-SIGN**

| # | fix | where |
|---|---|---|
| M1 | Disclose (or trim) beat 6's verbatim containment of beat 7's whole duʿā English | draft + founder decision |
| M2 | Correct *"id 88's **entire** duʿā English"* → an 11-word run; second sentence absent | draft **and `COLLISION-LEDGER.md` §9b`** |
| M3 | Correct bar 2's *"stated nowhere"*; reconcile `I am the King` with §9j's 24:35 ruling | draft |
| M4 | Correct *"59:23 is spent by shipped `as-salam@1`"* — it is in no shipped deck | draft |
| M5 | *"two clauses longer"* → one clause; id 88 differs in three orthographic words, not one | draft |
| M6 | Record the comma→colon edit; have the founder knowingly sign `Right Hand`→`right hand` | draft |
| M7 | Record the `Allāh`→`Allah` normalisation | draft |
| — | **Then sign.** Scripture clean; all five bars pass; pin `Qur'an 3:26 (opening)` **approved**; `renderedDuaSources` entry required in the same change | — |

**`al-baqi@1` — FIX-THEN-SIGN**

| # | fix | where |
|---|---|---|
| B1 | **Retract** *"55:29 is id 34 As-Samad's `meaning` almost verbatim"* — false; downgrade to a conceptual adjacency | draft **and `COLLISION-LEDGER.md` §9b** |
| B2 | Reword beat 3 (and re-ground beat 8) — *"Most of it left the house"* is not entailed | draft |
| B3 | State bar 1's real grammar (`بَاقٍ` predicates `مَا عِندَ ٱللَّهِ`); record the unexamined 55:27-with-ellipsis option and why 16:96 is still preferred | draft |
| B4 | *"eight-word shared run"* → 5 contiguous words (ledger §9c is already right) | draft |
| B5 | Record the `Allāh`→`Allah` normalisation | draft |
| B6 | Fix the Tirmidhī 2471 chapter heading; *"same chapter"* → same **book**, three chapters | draft |
| + | **Add the new finding:** id 98's duʿā mirrors the narrated Abū Dāwūd 1173 istisqāʾ template with the attribute pair swapped. **UNPINNED stands. Id 98 must never be pinned to Abū Dāwūd 1173** — the Name in that formula is `الْغَنِيّ` (id 92) | draft + ledger |
| — | **Then sign.** Scripture clean; beats 4–5 byte-exact; both grade lines confirmed; bar 5 the cleanest of the pair | — |
