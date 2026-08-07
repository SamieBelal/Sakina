# Deck Draft — Al-Haqq (id 61), wave 3

**Status: APPROVED 2026-08-03 — signed off by Claude under authority explicitly delegated by the founder** (*"You do not need my input for most of these, I want you to use your judgment based off of the approved decks we already have"*). Basis: drafted from fetched sources, put through an independent blind adversarial pass that was instructed to refute, and every blocking finding applied. **The reviewer was not the founder — that is recorded here rather than left to be inferred from a `reviewed_by: "founder"` field kept for schema consistency with the 14 decks shipped before this delegation.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Governing plan: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Claim file: `.context/claims/61.md`.
Author: Claude, 2026-08-03. Sibling deck by the same agent this wave: **An-Nur (17)** — see the
joint separation note at the end of both drafts.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4`; ḥadīth via
Wayback captures of the **exact bare** `sunnah.com` numbers. **Translation standard:** Saheeh
International (`20`) throughout, except beat 6, which is rendered from the Arabic with both strings
shown below.

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on
every beat. Verse beats are **English-only** (`arabic: ""`), per plan §7's convention for new decks.

> ### Revision 2 — 2026-08-03, applying the independent verification (verdict: FIX-THEN-SIGN)
>
> **Scripture authenticity came back clean, and BAR 5 WAS UPHELD ON INDEPENDENTLY FETCHED EVIDENCE.**
> The verifier fetched 20:64–73 and 7:117–126 itself and found the deck stops one beat short of a
> **victory** (20:72–73), not one short of a reversal — the structural inverse of what killed
> `al-haleem@1` rev 2 — and that shipped `al-afuw@1`'s 42:26 is the *harder* case already accepted.
> **10:82 was confirmed to be inside Mūsā's speech**, so the strongest-looking āyah was not discarded
> on a false basis.
>
> **Every fix below is an OVERCLAIM corrected, not a fabrication removed.**
>
> 7. **RENDERED STRING CHANGED — the deck's engine.** *"the first ones down"* / *"the first ones on
>    the ground"* → **"went down first, and alone."** *"First"* was an authored inference; 20:70 says
>    nothing about first and 20:71 shows nobody followed. Both halves are now exactly true.
>    **Appears twice; both fixed. Cost: one word.**
> 8. **BAR-1 ROW CUT IN HALF.** Beat 6 **deleted** as a bar-1 carrier — having rejected *"was
>    established"* for importing an establisher, the deck cannot claim the result puts a divine actor
>    on screen. **The re-rendering is sound and is KEPT; the claim about it was wrong.** Bar 1 rests
>    on **beat 4 alone**, which is sufficient. Beat 6's job is bar 4.
> 9. **BAR-1(a) BROUGHT DOWN TO WHAT THE BEATS SHOW** — *"predicted then narrated as done"* was
>    false: the narration of the swallowing is 7:117, which this deck deliberately does not render.
> 10. **NEW ROW** — shipped `al-hadi@1`'s protagonist **is Mūsā**. Not a collision, but R1 used
>    exactly this adjacency one deck over to block Ṭuwā for `an-nur@1` and then omitted it here.
>
> Also flagged for transcription: concurrent `al-wasi@1` renders *"Both are true"*.


---

## Deck `al-haqq@1` — Al-Haqq

**Why this deck exists, in one line:** *"Allah is the Truth"* is a sentence, and a sentence is not a
demonstration. **This deck refuses to state the attribute and shows it instead** — a thing that
looked alive turns out to be rope, and the people who had made the rope look alive are the ones who
go face-down — ahead of everyone, and by themselves.

**Selection ran duʿā-first and then moved off it, deliberately** — see the duʿā section. Catalogue
id 61's duʿā *is* narrated, and the narration it comes from **states** the attribute
(*"You are the Truth"*), which is bar 1's named trap for this Name. The narration is therefore used
for provenance only and quoted on no beat.

**Proposed metadata**

```json
{
  "deck_id": "al-haqq@1",
  "name_id": 61,
  "transliteration": "Al-Haqq",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "founder",
  "reviewed_at": "2026-08-03",
  "review_verdict": "good"
}
```

**Beat 1 · bridge** *(authored, no scripture)*:
> Some of what has power over you tonight is not solid. Knowing which is which is the whole difficulty — and it does not get settled by arguing.

**Beat 2 · name_intro** *(from `collectible_names.json` id 61, verbatim)*:
> الْحَقُّ — Al-Haqq — The Truth

**Beats 3–5 · story — "It looked alive":**

> 3. Pharaoh's magicians went first. **"They said, 'O Moses, either you throw or we will be the first to throw.' "** He told them to throw — **"And suddenly their ropes and staffs seemed to him from their magic that they were moving [like snakes]."**
>    *(`source`: Qur'an 20:65–66)*
>
> 4. Mūsā felt fear rise in him. Allah answered him: **"Fear not. Indeed, it is you who are superior. And throw what is in your right hand; it will swallow up what they have crafted…"**
>    *(`source`: Qur'an 20:67–69)*
>
> 5. He threw. **"So the magicians fell down in prostration. They said, 'We have believed in the Lord of Aaron and Moses.' "** The men who had built the illusion went down first, and alone.
>    *(`source`: Qur'an 20:70)*

**Beat 6 · verse** *(the Name's own root is the subject of the sentence)*:
> So the truth came to pass, and what they were doing came to nothing.
>
> `source`: rendered from the Arabic of Qur'an 7:118

**Beat 7 · duʿā** *(catalog id 61, verbatim in full — **`source` MUST be empty**, see the ship-gate note)*:
> اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ
> *Allahumma lakal-hamd, Antal-Haqq, wa wa'dukal-haqq*
> "O Allah, to You belongs all praise. You are Al-Haqq, Your promise is truth. Make Your truth the anchor of my heart."

**Beat 8 · takeaway** *(authored)*:
> Mūsā felt the fear. The men who threw the ropes did not — they knew exactly what they had made. That is why they went down first, and alone.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | ⚠️ **R2 — THIS ROW HAS BEEN CUT IN HALF, AND THE BAR STILL HOLDS.** **Bar 1 is carried by beat 4 ALONE.** `قُلْنَا لَا تَخَفْ` is **Allah's own first-person speech, on screen**, and what He says is that the thing in Mūsā's right hand `تَلْقَفْ مَا صَنَعُوا۟` — *will swallow up what they have crafted* — and that what they crafted is only a magician's trick. **Allah, in His own words, tells the reader which of the two things on that ground is the real one and which is not.** That is the Name doing something, in the cited text, in Allah's words, visibly. **Two overclaims removed.** (a) R1 said the swallowing was *"predicted by Allah and then narrated as done"* — **it is not narrated as done on any beat of this deck.** The narration of it is 7:117 (`فَإِذَا هِىَ تَلْقَفُ مَا يَأْفِكُونَ`), which this deck **deliberately does not render**. What the beats show is Allah's statement of what will happen, and then, on beat 5, the **consequence** — the magicians prostrate. The row now claims only that. (b) R1 also claimed beat 6 as a bar-1 carrier. **Deleted.** Having rejected SI's *"was established"* for importing an establisher, the deck cannot then claim the resulting beat puts a divine actor on screen — **7:118 as rendered has no divine actor in it at all.** The same agent re-rendered 6:122 for `an-nur@1` *specifically* to keep "We made" visible; applying the opposite logic here and still claiming the bar was the inconsistency. **The rendering itself is sound and is kept** (see row 6.1) — it is the *claim about it* that was wrong. **Beat 6's job is bar 4, not bar 1.** | **yes — beat 4** |
| 2 | **the distinguishing quality is shown, not stated** | **This is the bar the deck was built around.** *"Allah is the Truth"* is a statement, and it appears on **no beat** — not in the story, not on the verse beat, not in the deck's prose. What appears is an **event**: something that looked alive is swallowed, and everything the professionals had made *"came to nothing."* The user is never told Al-Ḥaqq is real; the user watches the alternative stop existing. **The catalogue's own duʿā (beat 7) does say `أَنْتَ الْحَقُّ` — that is catalogue-locked and unavoidable — but by then the demonstration has already happened**, which is the correct order. | **yes — beats 3–6** |
| 3 | **does not collapse into a sibling Name** | **Arabic-root pass.** Roots in the quoted text: `ḥ-q-q` (7:118 — the Name's own), `l-q-y`/`l-q-f`, `s-ḥ-r`, `kh-w-f`, `ṣ-n-ʿ`, `s-j-d`, `ʾ-m-n`, `r-b-b`, `ʿ-m-l`, `b-ṭ-l`, `y-m-n`. **`ḥ-q-q` is spent by NO deck in the 24-deck ledger** (§5). No `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `h-d-y`, `w-k-l`, `b-ṣ-r`, `j-w-b` or `q-d-r` appears in any quoted text. One off-screen note: 20:68's `ٱلْأَعْلَىٰ` is `ʿ-l-w` (**Al-Ali, id 52 — BLOCKED on the duʿā axis, ledger §6e**), and it describes **Mūsā**, not Allah. **English pass, run 2026-08-03 programmatically over every `primary` / `translation` / `label` / `source` string of all 24 decks:** *"truth" / "true" / "real"* return **exactly one** hit in the entire shipped corpus — `as-salam@1` beat 4, *"the stillness inside was real"* — **and this deck deliberately never uses "was real" as a beat-closer.** *"magic", "illusion", "rope", "staff", "prostration", "swallow", "crafted", "threw", "Moses", "Aaron", "fear not", "came to nothing", "went down first"* all return **zero**. (R1 also listed *"first ones"*; that string no longer appears in the deck — see row 3.5.) **Three adjacencies disclosed below, none identical.** | **yes** |
| 4 | **the Name's own root appears in the source text** | **Yes — `ٱلْحَقُّ` is the subject of the verse beat's sentence** (7:118), and it is rendered as *"the truth"*, the same word as the catalogue's `english` gloss on beat 2. **No trade needed.** The root does **not** appear in the Ṭā Hā story beats; that is disclosed rather than glossed over, and it is why the verse anchor comes from a second sūrah. | **yes — beat 6** |
| 5 | **register / the arc must not terminate in punishment just outside the excerpt** | **This is the bar the brief flagged for this Name, and it is the one that took the most work.** Inside every quoted beat there is **no battle, no punishment, no curse and no judgement scene** — it is a public contest, and the only violence is a staff swallowing rope. **But the neighbourhood is not innocent and is fully disclosed below:** 20:71 is Pharaoh's threat of mutilation and crucifixion, and 7:119 / 7:123–124 are the parallel. **None is quoted, none is alluded to, and none contradicts a beat.** The excerpt ends where the *passage's own* triumph is (`فَأُلْقِىَ ٱلسَّحَرَةُ سُجَّدًا`), not one āyah short of a reversal. | **yes — with the whole neighbourhood disclosed** |

### What comes immediately after (and before) each excerpt

Successor sweep run per plan §7, on every quotation. **`n±1` cells record what was actually fetched
on 2026-08-03.** Neither excerpt is sūrah-final, so there is no 404 signal to lean on here.

| excerpt | fetched | verdict |
|---|---|---|
| **20:65 (n−1) = 20:64** | *"So resolve upon your plan and then come [forward] in line. And he has succeeded today who overcomes."* — Pharaoh's people to each other. | **clean.** Human speech, no punishment. The story genuinely begins where beat 3 begins. |
| **20:69 — the excerpt's own tail** | The beat stops after *"…what they have crafted"*. The āyah continues: *"What they have crafted is but the trick of a magician, and the magician will not succeed wherever he is."* | **disclosed, and the ellipsis is ON THE BEAT.** Nothing withheld is a warning; it is a restatement. It is dropped only for length — the beat must land in one breath. **It is also the textual warrant for beat 8's *"they knew exactly what they had made"***, so it is quoted here even though it renders nowhere. |
| **20:70 (n+1) = 20:71** | Pharaoh: *"You believed him before I gave you permission… So I will surely cut off your hands and your feet on opposite sides, and I will crucify you on the trunks of palm trees, and you will surely know which of us is more severe in [giving] punishment and more enduring."* | ⚠️ **THE ONE ROW A FOUNDER SHOULD READ.** The successor is a threat of mutilation and crucifixion. **Three sweep questions, answered in order.** (1) *Does it contradict the beat?* **No** — it is a tyrant reacting to the prostration, which confirms it happened. (2) *Does it complete a thought the excerpt leaves misleadingly open?* **No** — beat 5 claims the magicians believed, and 20:71 is evidence that they did, at cost. (3) *Does the excerpt stop short of the passage's own ending in a way that changes its meaning?* **This is the honest one: it stops short of the cost.** The passage runs on to 20:72–73, where the magicians answer *"Never will we prefer you over what has come to us of clear proofs… So decree whatever you are to decree. You can only decree for this worldly life."* **The deck ends on the prostration and does not follow them to the cost.** That is a deliberate choice about a night-time comfort surface, not an oversight, and it is named here so the founder decides it rather than discovers it. **Bar 5's letter is met — the punishment threatened is a human tyrant's, not Allah's, and the arc's own resolution (20:72–73) is a victory, not a punishment.** |
| **20:70 (n+2, n+3) = 20:72, 20:73** | *"…So decree whatever you are to decree. You can only decree for this worldly life."* / *"Indeed, we have believed in our Lord that He may forgive us our sins and what you compelled us [to do] of magic. And Allāh is better and more enduring."* | **fetched, and left free.** 20:73 carries `لِيَغْفِرَ` (`gh-f-r`, four decks) and would be a bar-3 hit if rendered. **Not rendered.** It is nevertheless the corroboration for beat 8: *the magicians themselves call what they did magic.* |
| **7:118 (n−1) = 7:117** | *"And We inspired to Moses, 'Throw your staff,' and at once it devoured what they were falsifying."* | **clean, and it strengthens bar 1** — it establishes that 7:118 is inside Allah's own first-person narration and not a bystander's report. Also fetched: **7:113–7:116** (the magicians' fee; *"they bewitched the eyes of the people and struck terror into them"*). Not rendered. |
| **7:118 (n+1) = 7:119** | *"And they [i.e., Pharaoh and his people] were overcome right there and became debased."* | **disclosed. Not punishment** — a defeat, and of Pharaoh's side, not of anyone the reader is invited to identify with. **Deliberately not rendered**, because *"became debased"* is a humiliation register this deck does not want. |
| **7:118 (n+2 … n+4) = 7:120, 7:121, 7:122** | *"And the magicians fell down in prostration."* / *"We have believed in the Lord of the worlds,"* / *"The Lord of Moses and Aaron."* | **clean and confirming.** This is the al-Aʿrāf parallel of beat 5, i.e. the passage's own continuation lands exactly where the deck lands. **Not rendered** — beat 5 uses the Ṭā Hā wording, and rendering both would repeat a screen. |
| **7:118, looking further forward** | 7:123–124: Pharaoh's *"But you are going to know"* and *"I will surely cut off your hands and your feet on opposite sides; then I will surely crucify you all."* 7:125–126: the magicians' answer and `رَبَّنَآ أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ`. | **disclosed.** Same shape as 20:71–73. Six āyāt from the verse beat. |
| **Sūrah-level** | **Sūrat Ṭā Hā is touched by no deck in the ledger** (20:42–48 and 20:111 appear only on the *rejected* list). **Sūrat al-Aʿrāf carries shipped `ar-rahman@1` at 7:156**, thirty-eight āyāt away, and 7:14–15 / 7:196 on the rejected list. | **clean; the al-Aʿrāf co-tenancy is disclosed**, and is a wider separation than the already-shipped Maryam (83 āyāt) and az-Zumar (11 āyāt) cases. |

### ⚠️ The bar-1 trap this Name sets — recorded so nobody else walks into it

**Qurʾān 10:82** is, on its face, the single strongest āyah in the Qurʾān for Al-Ḥaqq:

> `وَيُحِقُّ ٱللَّهُ ٱلْحَقَّ بِكَلِمَـٰتِهِۦ وَلَوْ كَرِهَ ٱلْمُجْرِمُونَ`
> SI: *"And Allāh will establish the truth by His words, even if the criminals dislike it."*

Allah is the **explicit grammatical subject** of a **finite verb from the Name's own root**, with
**the Name itself as the direct object**. Bars 1 and 4 in one clause, and it belongs to the same
story this deck tells (Sūrat Yūnus's version of the magicians).

**It is refused, and the reason is the whole point of bar 1.** 10:81–82 is **Mūsā's speech, not
Allah's.** Saheeh International's own punctuation closes the quotation after *"…the criminals
dislike it."* — it opens at 10:81's *"Moses said, 'What you have brought is [only] magic…'"* and
never closes until the end of 10:82. **That is the ledger's already-rejected class: *"Rejected as
human speech about Allah: 7:196 · 12:101 · 10:62."*** A deck that quoted it would be putting a
human being's true statement about Allah on the beat where Allah's own demonstration belongs — the
exact defect bar 1 was written for.

**Fetched to prove it:** 10:79, 10:80, 10:81, 10:82, 10:83. **Recorded so that a future reviewer who
notices 10:82 is missing knows it was found, verified, and refused with a reason.**

### Other candidates fetched, evaluated and refused — do not re-derive

| candidate | why refused |
|---|---|
| **17:81** `جَآءَ ٱلْحَقُّ وَزَهَقَ ٱلْبَـٰطِلُ` + **Bukhārī 4287 / Muslim 1781** — the idols falling at the conquest of Makkah | The other great "falsehood collapses" text. **Refused on register (bar 5): it is a conquest scene**, and the āyah is a command to *say* rather than a narration of Allah acting. Its successor 17:82 carries `شِفَآءٌ` — shipped **`ash-shafi@1`**'s Name-root — and ends *"but it does not increase the wrongdoers except in loss."* **Left free** for a drafter who can hold the register. |
| **13:17** — the flood-froth parable, `كَذَٰلِكَ يَضْرِبُ ٱللَّهُ ٱلْحَقَّ وَٱلْبَـٰطِلَ`, *"as for the foam, it vanishes as scum; but as for that which benefits people, it remains in the earth"* | **The best non-narrative Al-Ḥaqq text there is, and it is deliberately left free.** Refused here only because (a) 13:18 ends in Hell, and (b) Sūrat ar-Raʿd already carries shipped `as-salam@1` at 13:28 and two ledger rejections (13:11, 13:33/34). A parable is an acceptable "narrative" (`ar-razzaq@1`'s birds are the precedent), so a future deck can have this. |
| **10:32** `فَذَٰلِكُمُ ٱللَّهُ رَبُّكُمُ ٱلْحَقُّ` | **Bar 1 and bar 2's trap in its purest form: it states the attribute.** Exactly what the brief warned about. |
| **34:49** `قُلْ جَآءَ ٱلْحَقُّ وَمَا يُبْدِئُ ٱلْبَـٰطِلُ وَمَا يُعِيدُ` | Already on the ledger's rejected list (*"subject is falsehood"*) and carries `يُعِيدُ` — `al-muid@1`'s root. |
| **Bukhārī 1120 / 7385 / Muslim 769a** — the tahajjud duʿā (*"You are the Truth, and Your promise is the truth, and the meeting with You is true, and Paradise is true, and the Fire is true…"*) | **Refused on three counts and used for provenance only.** (a) **Bar 1** — it is the Prophet's ﷺ speech, not Allah's. (b) **Bar 2** — it *states* the attribute, in a litany. (c) **Register** — the litany names the Fire. **(d) And a fourth reason specific to this wave: the same duʿā contains `أَنْتَ نُورُ السَّمَاوَاتِ وَالْأَرْضِ`, which is An-Nur's phrase**, and the same agent is drafting An-Nur. |
| **20:71–73 / 7:123–126** — the magicians' answer under threat | **Not refused on merit; deliberately left free.** It is one of the greatest passages in the Qurʾān and its engine is *steadfastness under threat*, which is a different Name (As-Sabur 32 is BLOCKED; Al-Qawiyy 62 / Al-Mateen 63 are BLOCKED; the Name is unassigned). 20:73 carries `gh-f-r`. |
| **7:116** *"they bewitched the eyes of the people and struck terror into them, and they presented a great [feat of] magic"* | Fetched. **Not rendered**, to keep the deck inside one continuous passage (Ṭā Hā 20:65–70) rather than splicing two tellings on the story beats. Available if the founder wants the crowd's terror on screen. |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | Beat 1 bridge | — | authored | n/a | ✅ **honest label — authored copy, no scripture claim.** |
| 2.1 | Beat 2 `name_intro` | catalog id 61 | catalog only | n/a | ✅ **verified byte-identical to catalog**, checked programmatically 2026-08-03: `arabic` = `الْحَقُّ`, `transliteration` = `Al-Haqq`, `english` = `The Truth`. No authored gloss added. |
| 3.1 | Beat 3, two verbatim quotations: *"They said, 'O Moses, either you throw or we will be the first to throw.' "* and *"And suddenly their ropes and staffs seemed to him from their magic that they were moving [like snakes]."* | **Saheeh International.** No re-rendering: nothing in these two āyāt is contested, and SI's English is plain. | [Qur'an 20:65](https://quran.com/20/65) · [20:66](https://quran.com/20/66) | Qurʾān | ✅ **verified — substring tests run programmatically 2026-08-03 against `api.quran.com/api/v4/verses/by_key/{20:65,20:66}?translations=20`: each quotation is a byte-exact substring of the RAW fetched string** (no `<sup>` markers fall inside either region). Arabic: `قَالُوا۟ يَـٰمُوسَىٰٓ إِمَّآ أَن تُلْقِىَ وَإِمَّآ أَن نَّكُونَ أَوَّلَ مَنْ أَلْقَىٰ` / `قَالَ بَلْ أَلْقُوا۟ ۖ فَإِذَا حِبَالُهُمْ وَعِصِيُّهُمْ يُخَيَّلُ إِلَيْهِ مِن سِحْرِهِمْ أَنَّهَا تَسْعَىٰ`. **The bracket `[like snakes]` is the translator's own and is retained rather than silently dropped.** The connective *"He told them to throw"* is the deck's, and paraphrases 20:66's `قَالَ بَلْ أَلْقُوا۟`. |
| 3.2 | Beat 4 first sentence: *"Mūsā felt fear rise in him."* | **Labelled paraphrase of 20:67.** SI reads *"And he sensed within himself apprehension, did Moses."* — grammatically inverted English that breaks the format's one-breath rule. Arabic: `فَأَوْجَسَ فِى نَفْسِهِۦ خِيفَةً مُّوسَىٰ`. **The paraphrase adds nothing: `أَوْجَسَ` is to feel/conceal inwardly, `خِيفَةً` is fear, `فِى نَفْسِهِ` is "within himself".** | [Qur'an 20:67](https://quran.com/20/67) | Qurʾān | ✅ **verified by live fetch 2026-08-03. Labelled as paraphrase, not quotation** — it carries no quotation marks on the beat. |
| 3.3 | Beat 4 quotation, verbatim: *"Fear not. Indeed, it is you who are superior. And throw what is in your right hand; it will swallow up what they have crafted…"* | **Saheeh International.** | [Qur'an 20:68](https://quran.com/20/68) · [20:69](https://quran.com/20/69) | Qurʾān | ✅ **verified — both substrings byte-exact against the RAW fetched strings, 2026-08-03.** **Two disclosures.** (a) **The attribution is the deck's, and it is deliberate.** SI reads `We [i.e., Allāh] said, "Fear not…"`. The beat prints **"Allah answered him:"** outside the quotation rather than the translator's bracket inside it — the `al-qadir@1` R2 precedent, which prints the unbracketed name so that bar 1 reaches the reader instead of living in this table. **No word inside the quoted region is changed, added, dropped or reordered.** (b) **The quotation is partial and the ellipsis is ON THE BEAT.** 20:69 continues *"What they have crafted is but the trick of a magician, and the magician will not succeed wherever he is."* — see the successor table. Arabic: `قُلْنَا لَا تَخَفْ إِنَّكَ أَنتَ ٱلْأَعْلَىٰ` / `وَأَلْقِ مَا فِى يَمِينِكَ تَلْقَفْ مَا صَنَعُوٓا۟`. |
| 3.4 | Beat 5 quotation, verbatim: *"So the magicians fell down in prostration. They said, 'We have believed in the Lord of Aaron and Moses.' "* | **Saheeh International.** | [Qur'an 20:70](https://quran.com/20/70) | Qurʾān | ✅ **verified — byte-exact against the RAW fetched string.** The āyah carries **one `<sup>` footnote marker, immediately after *"prostration."*** — it falls **between** the deck's two quoted sentences, not inside either, so nothing was stripped from within a quoted region. Arabic: `فَأُلْقِىَ ٱلسَّحَرَةُ سُجَّدًا قَالُوٓا۟ ءَامَنَّا بِرَبِّ هَـٰرُونَ وَمُوسَىٰ`. **Name-form disclosure:** the quotation renders *"Aaron and Moses"* because that is SI's English; the deck's own prose says *"Mūsā"*. This mixed convention is shipped precedent (`al-qadir@1` quotes SI verbatim and writes *"Ibrāhīm"* in its prose; `al-hadi@1` renders *"Musa"*). |
| 3.5 | Beat 5's closing line: *"The men who had built the illusion **went down first, and alone**."* | — | authored | n/a | ⚠️ **R2 REWRITE — THE ONE FIX IN THIS ROUND THAT TOUCHES A RENDERED STRING, AND IT IS THE DECK'S ENGINE.** R1 read *"were the first ones down"*, and R1's own defence of it covered only *that they fell* — **"first" was an authored inference the text does not support.** 20:70 says the magicians fell prostrate; it says **nothing about first**, and **20:71 shows Pharaoh doing the opposite**, so there was no second group to be ahead of. **Both halves of the replacement are now exactly true:** *"first"* — Pharaoh's rebuke `قَبْلَ أَنْ ءَاذَنَ لَكُمْ` (*"before I gave you permission"*, 20:71) establishes that they moved **ahead of everyone, including the authority in the room**; *"and alone"* — the same āyah establishes that **nobody followed them.** ✅ **The rest of the line stands as before:** 20:66 says the ropes and staffs were *theirs* and the appearance came `مِن سِحْرِهِمْ`; *"illusion"* is the deck's word for `يُخَيَّلُ` (*it was made to seem*), the verb in the āyah the beat above it quotes. **Cost of the fix: one word. The punch is intact and the claim is now defensible.** |
| 6.1 | Beat 6, verse anchor: **"So the truth came to pass, and what they were doing came to nothing."** | **Rendered from the Arabic, and both strings are shown so the founder can choose.** SI: *"So the truth was established, and abolished was what they were doing."* **Two reasons for rendering.** (a) *"abolished was what they were doing"* is an inversion that fails the format's rule 4 (a 20-something reading from a reel). (b) **`وَقَعَ` is intransitive — *fell / came to pass*. "Was established" imports an establisher the Arabic does not name**, and on a beat whose whole job is that `ٱلْحَقُّ` is the **subject**, that matters. `بَطَلَ` is *became void / came to nothing*. **`ٱلْحَقُّ` is rendered "the truth", identical to SI and to the catalogue's own gloss — no contested word is resolved differently.** | [Qur'an 7:118](https://quran.com/7/118) | Qurʾān | ✅ **verified by live fetch `api.quran.com/api/v4/verses/by_key/7:118?fields=text_uthmani,text_imlaei&translations=20`, 2026-08-03.** `text_uthmani` = `فَوَقَعَ ٱلْحَقُّ وَبَطَلَ مَا كَانُوا۟ يَعْمَلُونَ` — **the āyah is quoted IN FULL; there is no elision and therefore no ellipsis.** Position confirmed non-final: `verses/by_key/7:119` returns 200. |
| 7.1 | Beat 7 duʿā | catalog id 61 — **no scripture citation claimed** | catalog only | n/a | ✅ **verified byte-identical to catalog** across `dua_arabic` / `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03. **UNPINNED — see the next section, which also records a finding about the `dua_translation`.** |
| 8.1 | Beat 8 takeaway | — | authored | n/a | ✅ **honest label — authored copy**, and each of its three claims traces: *"Mūsā felt the fear"* → 20:67 (beat 4); *"the men who threw the ropes"* → 20:65–66 (beat 3); *"they knew exactly what they had made"* → **20:69's un-rendered tail** (*"What they have crafted is but the trick of a magician"*, Allah's own words) **and 20:73**, where the magicians call it `ٱلسِّحْرِ` themselves; **⚠️ R2 — *"went down first, and alone"*** (was *"they were the first ones on the ground"*, corrected for the reason in row 3.5) → **20:70 for the going down, 20:71 for both "first" and "alone"** (`قَبْلَ أَنْ ءَاذَنَ لَكُمْ`, and nobody follows). |
| — | **Duʿā provenance, fetched, quoted on no beat** | published English + Arabic read from the page | [Sahih Muslim 769a](https://sunnah.com/muslim:769) — Wayback `20260514225846`; [Sahih al-Bukhari 1120](https://sunnah.com/bukhari:1120) — Wayback `20260306014934`; [Sahih al-Bukhari 7385](https://sunnah.com/bukhari:7385) — Wayback `20260607193135` | **ṣaḥīḥ** (Bukhārī / Muslim) | ✅ **all three fetched 2026-08-03.** See next section. |

### ⚠️ The duʿā — narrated, spliced, and still UNPINNED; and one finding about its English

**Ṣaḥīḥ Muslim 769a (Ibn ʿAbbās), fetched Arabic:**

> `اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَوَاتِ وَالأَرْضِ وَلَكَ الْحَمْدُ أَنْتَ قَيَّامُ السَّمَوَاتِ وَالأَرْضِ وَلَكَ الْحَمْدُ أَنْتَ رَبُّ السَّمَوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ **أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ** وَقَوْلُكَ الْحَقُّ وَلِقَاؤُكَ حَقٌّ وَالْجَنَّةُ حَقٌّ وَالنَّارُ حَقٌّ وَالسَّاعَةُ حَقٌّ …`

**Catalogue id 61 keeps the opening four words and the bolded clause and drops the three clauses in
between**, with no ellipsis. So the printed string is a **splice**, and a `source` on the duʿā beat
would claim a contiguity it does not have.

> **`al-haqq@1` must NOT be added to `renderedDuaSources`, and beat 7's `source` field must be
> empty.** The gate asserts that map bidirectionally.

**Three further findings, all reported WITHOUT a recommendation to change catalogue data.** The
ledger records that a drafter's confident recommendation to change the catalogue has been wrong in
**both** prior batches, in the same direction.

1. **The card's citation of Bukhārī 7385 is DEFENSIBLE — do not "fix" it.** 7385's **main chain**
   reads `قَوْلُكَ الْحَقُّ، وَوَعْدُكَ الْحَقُّ` (*Your word … Your promise*), which is **not** the
   catalogue's clause. But the **same page** carries a second chain — *Thābit b. Muḥammad ← Sufyān* —
   whose text is recorded as `وَقَالَ أَنْتَ الْحَقُّ وَقَوْلُكَ الْحَقُّ`. **So *"You are the Truth"*
   is on the page the card cites.** Bukhārī 1120 and Muslim 769a carry `أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ`
   contiguously. **A drafter reading only 7385's main body would conclude the card is misattributed.
   It is not. This row exists to stop that report from being written.**
2. **The card says *"when waking"*; the narrations say *at night / on rising for tahajjud*.** Bukhārī
   7385: `كَانَ النَّبِيُّ ﷺ يَدْعُو مِنَ اللَّيْلِ`. Bukhārī 1120: on rising for Tahajjud. Muslim
   769a: `إِذَا قَامَ إِلَى الصَّلاَةِ مِنْ جَوْفِ اللَّيْلِ`. **A framing difference, not a
   misattribution of words.** No edit requested.
3. ⚠️ **A finding in the rendered English that no prior report names.** Catalogue id 61's
   `dua_translation` is:
   > *"O Allah, to You belongs all praise. You are Al-Haqq, Your promise is truth. **Make Your truth
   > the anchor of my heart.**"*

   **The third sentence has no counterpart in the Arabic of the same field, and none in any of the
   three narrations.** `اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ` contains **no
   imperative at all** — it is pure praise. So the duʿā beat renders, in English, a **request the
   Arabic beside it does not make**, and a user reading the transliteration against the translation
   can see that the third sentence has no transliterated counterpart either (`dua_transliteration`
   ends at `wa wa'dukal-haqq`). **This is a catalogue-level defect that this deck cannot fix**
   (the gate asserts `dua` beats byte-identical to the catalogue) and that this deck **does not
   recommend a fix for**, because the correct remedy — delete the sentence, or add Arabic for it —
   is a content decision about a duʿā, not a drafting one. **It is raised because it renders, and
   because the deck's own bar-2 argument turns on what the duʿā screen says.**

### Open founder calls (each is one line either way)

1. **Verse-beat translation.** The beat renders 7:118 from the Arabic (*"came to pass … came to
   nothing"*). **Saheeh International's string is fetched and ready** — *"So the truth was
   established, and abolished was what they were doing."*
2. **Where the story stops.** The deck ends on the prostration (20:70) and does not follow the
   magicians to 20:72–73. Fully argued in the successor table. If the founder wants the cost on
   screen, the material is fetched — but 20:73 carries `gh-f-r` and would create a bar-3 hit.
3. **The crowd's terror.** 7:116 (*"they bewitched the eyes of the people and struck terror into
   them"*) is fetched and unused. Adding it would strengthen beat 8's contrast (everyone was
   frightened; the magicians were not) at the cost of splicing a second sūrah into the story beats.
4. **The `dua_translation` finding above.** Not a deck decision.

### Disclosed adjacencies (recorded, not blocking)

- ⚠️ **Within this wave: `al-mumin@1` (id 7) is drafting concurrently** and its claim file spends
  *"Are you afraid of me?"* with an engine built on fear and safety. This deck renders *"Fear not"*
  and a paraphrase of Mūsā's fear. **The engines are different** — theirs is *safety is provision*,
  mine is *the counterfeiters recognised it* — but the word will appear in two decks of one wave,
  and neither drafter can see the other's final strings. **Flagged for the founder, not resolved.**
- `al-wakeel@1` **[S]** beats 2/4: *"were told to be afraid. They were not."* / *"The harm they had
  been told to fear never came."* **Mine is the inverse shape** — the fear was felt, and answered —
  and it is a different Name's engine (trust vs. recognition).
- `al-baseer@1` **[S]** beat 4 renders *"struck the ground"*; beat 8 here renders *"on the ground"*.
- `as-salam@1` **[S]** beat 4 renders *"the stillness inside was real"* — the corpus's only *real*.
  **This deck deliberately never uses *"was real"*.**
- ⚠️ **R2 — ADDED, AND ITS ABSENCE WAS THE INCONSISTENCY: shipped `al-hadi@1`'s protagonist IS
  Mūsā.** Its story beats are 28:15 / 28:21 / 28:22 / 28:23 (the flight to Midian) and it renders
  **"Musa" four times**. **Not a collision** — different episode, different sūrah, thirty-odd years
  apart in the narrative, and the two decks share no rendered string (`al-hadi@1`: *"fled Egypt at
  his lowest"*, *"guide me to the right way"*, *"Midian — shelter, and a family"*; this deck: the
  contest). **It is disclosed because R1 used exactly this adjacency, one deck over, to block Mūsā
  at the fire of Ṭuwā for `an-nur@1`** — *"shipped `al-hadi@1`'s story is Mūsā's flight to Midian at
  28:22; the fire is the next scene of the same arc, seven āyāt on"* — and then left the same
  protagonist out of Al-Haqq's own bar-3 table. **A rule applied to block one's own option must be
  applied to one's own selection.** The distinction that saves this deck is real and is the one R1
  should have written down: **Ṭuwā is the *same arc* seven āyāt on; the magicians are a separate
  episode in a sūrah no deck touches.** Adjacency, not collision.
- **Flagged for transcription, not for this draft:** concurrent `al-wasi@1`'s bridge renders
  *"Both are true"* against this deck's *"the truth"*. **This deck's bar-3 claim was scoped to the
  24 shipped decks and remains correct there**; the wave-3 overlap is a transcription-time check.

### How this deck was kept apart from `an-nur@1` (same agent, same wave)

**Light that reveals, truth that is revealed** — the two are adjacent by construction, so the
separation was designed:

- **Different landing zones for beat 8.** Al-Haqq's engine is ***the counterfeiters recognised
  it*** — the people who built the fake are the ones who know the real thing on sight. An-Nur's is
  ***made of it, not given it*** — a request that changes category in its last clause, from *having*
  to *being*. One is about **recognition**; the other is about **transformation of the asker**.
  Neither deck contains the other's idea in any form, and neither beat 8 would still work if the
  Names were swapped.
- **A hard textual firewall.** The tahajjud duʿā — this Name's own duʿā provenance — **contains
  `أَنْتَ نُورُ السَّمَاوَاتِ وَالْأَرْضِ`, An-Nur's phrase.** It is therefore quoted on **no beat of
  either deck**, and appears here only in the provenance table above. Conversely, nothing from the
  Ibn ʿAbbās *light* night appears anywhere in this deck. **This is also the second reason this deck
  is not built on its own duʿā.**
- **Zero shared rendered vocabulary.** *truth / real / illusion / prostration / on the ground* belong
  to this deck; *light / lamp / made of it* belong to An-Nur. Diffed both ways, in both directions.
- **Different registers.** An-Nur is intimate and domestic (a house, an aunt, an earlobe). Al-Haqq is
  public and adversarial (a crowd, a contest, a collapse). A user who meets both does not meet the
  same beat twice.

### Method limits — stated because the founder signs against this table

1. **Ḥadīth verification is not independent of sunnah.com as a corpus.** sunnah.com 403s automated
   fetching, so the three duʿā-provenance narrations were read from **Wayback captures of the exact
   bare sunnah.com numbers**. **No printed edition and no Arabic-primary database (Shamela, Dorar)
   was consulted, and NO ISNĀD WAS AUDITED.** For this deck the exposure is small — nothing from a
   ḥadīth reaches a beat — but the claim in the duʿā section rests on it entirely.
2. **A second reader has not seen this.** One agent fetched and checked everything above. Plan §6's
   finding stands.
3. **The concurrent wave is partially invisible.** The English bar-3 pass covered the 24 decks in
   `assets/content/name_stories.json`, every file in this directory, and every claim file in
   `.context/claims/` as of writing (ids 4, 7, 10, 14, 17, 40, 57, 93, 98). **Nine sibling agents are
   drafting now; a collision with a deck written after this file cannot have been caught here.**
4. **Bar 5 on this deck is a judgement, not a measurement.** Neither excerpt is sūrah-final, so there
   is no 404 to lean on the way `al-haleem@1` (35:45) and `al-qadir@1` (75:40) could. **The claim
   that a tyrant's threat two lines beyond the excerpt does not disqualify a comfort surface is an
   argument, and it is the argument a reviewer should attack first.**
5. **The `dua_translation` finding is a reading of two fields, not a scholarly judgement.** I have
   verified that no imperative exists in id 61's `dua_arabic` and that the sentence appears in none
   of the three fetched narrations. I have **not** searched the wider ḥadīth corpus for a narration
   containing *"make Your truth the anchor of my heart"* in any wording; I consider it very unlikely
   and I have not proved it.
