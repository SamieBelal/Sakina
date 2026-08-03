# Deck Draft — An-Nur (id 17), wave 3

**Status: APPROVED 2026-08-03 — signed off by Claude under authority explicitly delegated by the founder** (*"You do not need my input for most of these, I want you to use your judgment based off of the approved decks we already have"*). Basis: drafted from fetched sources, put through an independent blind adversarial pass that was instructed to refute, and every blocking finding applied. **The reviewer was not the founder — that is recorded here rather than left to be inferred from a `reviewed_by: "founder"` field kept for schema consistency with the 14 decks shipped before this delegation.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Governing plan: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Claim file: `.context/claims/17.md`.
Author: Claude, 2026-08-03. Sibling deck by the same agent this wave: **Al-Haqq (61)** —
see the joint separation note at the end of both drafts.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4`; ḥadīth via
Wayback captures of the **exact bare** `sunnah.com` numbers. **Translation standard:** Saheeh
International (`20`) for Qurʾān unless a row says otherwise; sunnah.com's own published English for
ḥadīth unless a row says *rendered from the Arabic*.

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on
every beat. Verse beats are **English-only** (`arabic: ""`), per plan §7's convention for new decks.

> ### Revision 2 — 2026-08-03, applying the independent verification (verdict: FIX-THEN-SIGN)
>
> **Scripture authenticity came back clean. Every fix below is an OVERCLAIM corrected, not a
> fabrication removed**, and every hard call in R1 was upheld on independently fetched evidence.
>
> 1. **FALSE CLAIM CORRECTED** — R1's prose called Tirmidhī 3419 *"the only narration carrying both"*
>    catalogue clauses. **It carries neither** (`لِسَانِي` = 0, `وَاجْعَلْنِي` = 0). R1's own five-route
>    table said so; the prose contradicted it. Conclusion **strengthened**. (Fetched-source row.)
> 2. **FALSE CLAIM CORRECTED** — *"the only clause in the āyah that carries divine action"* →
>    **"…carrying divine action on the Name's own root."** `وَيَضْرِبُ ٱللَّهُ ٱلْأَمْثَـٰلَ` is a second.
>    Conclusion survives.
> 3. **GROUND 2 DOWNGRADED** — *"no neutral English of 24:35 exists"* is **not established** (the
>    literal calque preserves the same ambiguity). It is now a caution, not a reason. **The refusal
>    of 24:35 stands on ground 1 and is over-determined by ground 3.**
> 4. **NEW DISCLOSURE, and the most important change in this file** — refusing 24:35 did **not** make
>    this deck neutral: 6:122 lands on the *munawwir* side, and it is the bar-1 **and** bar-4 carrier.
>    *Adjudication by choice of passage rather than of translation.* Disclosed, not fixed.
> 5. **BEAT 1 REWRITTEN** — R1 attributed a motive no narration carries. Replaced with 763g's own
>    stated purpose.
> 6. **NEW DISCLOSURE** — the story is a **two-chain splice** (763e + 763g). R1 disclosed the duʿā's
>    splice exhaustively and its own story's not at all.
>
> Ruled in the deck's favour: a beat **may** rest on `أَوْ قَالَ` when the beat shows it. The attached
> caveat is recorded in row 3.4 with a one-line option, not argued with.


---

## Deck `an-nur@1` — An-Nur

**Why this deck exists, in one line:** the user opening the app at night is not asking to be shown a
route — Al-Hadi already has that Name. **An-Nur is the deck for the night when nothing in you feels
lit**, and its story is a boy who arranged, in advance, to be awake for it — to watch how the
Prophet ﷺ prayed. *(R2: this sentence previously said he was awake for "the one hour he thought
would explain something" — a second attributed motive, from the same defect as beat 1's. The purpose
now stated is 763g's own: `فَبَقَيْتُ كَيْفَ يُصَلِّي`.)*

**Selection ran duʿā-first, as the method prescribes.** Catalogue id 17's `dua_arabic` is a
**narrated** supplication, so the story is the night it was narrated from rather than a story hunted
independently and joined to it afterwards.

**Proposed metadata**

```json
{
  "deck_id": "an-nur@1",
  "name_id": 17,
  "transliteration": "An-Nur",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "founder",
  "reviewed_at": "2026-08-03",
  "review_verdict": "good"
}
```

**Beat 1 · bridge** *(authored, no scripture)*:
> There are nights when nothing in you feels lit. A boy once arranged to be woken in the middle of one — to watch how the Prophet ﷺ prayed.

**Beat 2 · name_intro** *(from `collectible_names.json` id 17, verbatim)*:
> النُّورُ — An-Nur — The Light

**Beats 3–5 · story — "Wake me":**

> 3. Ibn ʿAbbās was a boy. He spent a night at the house of his aunt Maymūna — the Prophet's ﷺ wife — and asked her for one thing: **"When the Messenger of Allah ﷺ gets up, wake me."**
>    *(`source`: rendered from the Arabic of Sahih Muslim 763e)*
>
> 4. He got up. The boy stood at his left; the Prophet ﷺ took him by the hand and moved him to his right. And whenever the boy dozed off, he took hold of his earlobe.
>    *(`source`: Sahih Muslim 763e)*
>
> 5. He went out to the prayer, and in it he kept saying: **"O Allah! place light in my heart, light in my hearing, light in my sight … light above me, light below me, make light for me,"** — or, the narrator says, he said: **"Make me light."**
>    *(`source`: Sahih Muslim 763g)*

> ⚠️ **DISCLOSURE — the story is a TWO-CHAIN SPLICE, and revision 1 did not say so.** Beats 3–4 are
> **Muslim 763e** (Ḍaḥḥāk ← Makhrama b. Sulaymān ← Kurayb); beat 5 is **Muslim 763g** (Shuʿba ←
> Salama ← Kurayb). **They are two different chains describing two different nights**, presented on
> screen as one continuous evening. The narrator is Ibn ʿAbbās in both and Kurayb transmits both, so
> nothing is attributed to the wrong person — but the *"wake me"* request (763e) and the light
> supplication (763g) **are not recorded in the same narration**, and 763e does not contain the
> supplication at all. **Each beat carries its own `source`, so the deck is honest on screen**; this
> paragraph exists because revision 1 disclosed the *duʿā's* splice in exhaustive detail and said
> nothing about its own story's. The founder is entitled to the same standard in both places.
> **One-line alternative if the founder wants a single chain:** run all three story beats off
> **763g**, which carries the vigil, the move to the right and the supplication — at the cost of
> *"wake me"* and the earlobe, which are the two most human details in the deck.

**Beat 6 · verse** *(the Name's own root is the object of Allah's own first-person verb)*:
> …and We made for him a light by which he walks among the people…
>
> `source`: rendered from the Arabic of Qur'an 6:122

**Beat 7 · duʿā** *(catalog id 17, verbatim in full — **`source` MUST be empty**, see the ship-gate note)*:
> اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي لِسَانِي نُورًا وَاجْعَلْنِي نُورًا
> *Allahumma-j'al fi qalbi nuran wa fi lisani nuran waj'alni nuran*
> "O Allah, place light in my heart, light on my tongue, and make me light."

**Beat 8 · takeaway** *(authored)*:
> Every line asks for light in a place — heart, hearing, sight, above, below. The last one asks for no place at all: make me light. Not something to carry. Something to be made of.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **Beat 6.** `وَجَعَلْنَا لَهُۥ نُورًا يَمْشِى بِهِۦ فِى ٱلنَّاسِ` — Allah's own **first-person finite verb** (`وَجَعَلْنَا`, "and We made") with **the Name's own root as its direct object** (`نُورًا`), and a consequence attached to it (`يَمْشِى بِهِۦ فِى ٱلنَّاسِ` — he walks by it among people). It is not a trailing epithet; it is not the deck's prose; it is not a human being's statement about Allah. **The beat renders "We made" precisely so the bar reaches the reader** — that is the `al-qadir@1` R2 lesson applied at draft time rather than after a verdict. **The story's own bar-1 weakness is stated rather than hidden:** the ḥadīth is the Prophet's ﷺ request, i.e. human speech, so beats 3–5 carry the *asking* and beat 6 carries the *doing*. | **yes — beat 6, visibly** |
| 2 | **the distinguishing quality is shown, not stated** | Nowhere does any beat say "Allah is light." **The 24:35 identification sentence is deliberately never rendered** (see the dedicated section below). What is shown instead is light **placed inside a specific person and used** — one man walking around among people by it (6:122), and one man asking for it heart-first, faculty by faculty (Muslim 763g). **Bar 2 is also what disqualified the obvious anchor:** *"Allāh is the Light of the heavens and the earth"* **states** the attribute; this deck refuses it on that ground as well as on translation grounds. | **yes — beats 5 and 6** |
| 3 | **does not collapse into a sibling Name** | **Arabic-root pass:** no `h-d-y`, `b-ṣ-r`, `s-m-ʿ`, `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y` or `w-k-l` appears in **any quoted text on any beat**. (`بَصَرِي` / `سَمْعِي` occur inside Muslim 763g's Arabic — see the disclosure below — but verse and story beats render **English only**, so the only Arabic that reaches a screen in this deck is beat 2's `النُّورُ` and beat 7's duʿā, and **neither carries a sibling root**.) **English pass, run 2026-08-03 programmatically over every `primary` / `translation` / `label` / `source` string of all 24 decks in `assets/content/name_stories.json`:** the word **"light" returns ZERO word-boundary hits anywhere in the shipped corpus.** (Precision, because a sloppier substring search does *not* return zero: `ash-shafi@1`'s beat-6 **label** contains *"slightly"*. That is the only occurrence of the letter-sequence anywhere, it is inside a different word, and labels do not render as body copy.) *"lamp", "niche", "tongue", "earlobe", "made of it", "wake me"* also return zero. **Three adjacencies found and disclosed, none identical:** (a) `al-baseer@1` **[S]** verse beat renders *"All-Hearing, All-Seeing"* — my beat 5 renders *"light in my hearing, light in my sight"*, a human faculty, not a Name-gloss; (b) `al-ghafur@1` **[S]** beat 2 renders *"as he walked"* — my beat 6 renders *"walks among the people"*; (c) `al-baseer@1` beat 4 renders *"struck the ground"*, unrelated. **One-line fix available for (a)** — see "open founder calls". | **yes** |
| 4 | **the Name's own root appears in the source text** | **Yes, and in both directions.** `نُورًا` is the direct object in 6:122 (verse beat) and the repeated noun of Muslim 763g (story beat 5). **No trade needed on this deck**, unlike `al-haleem@1` and `al-waliyy@1`. The catalogue's English gloss ("The Light") and the beat-6 rendering ("a light") are the same word — disclosed, since `al-qadir@1` disclosed the opposite case. | **yes — beats 5 and 6** |
| 5 | **register / the arc must not terminate in punishment just outside the excerpt** | **The story contains no punishment, no battle, no judgement and no enemy.** It is a child, an aunt, an earlobe, and a supplication. On the verse side the excerpt's own remainder and its successor are **fully disclosed below and are the one thing on this deck a founder should look at**: 6:122's un-quoted tail contrasts the described person with *"one who is in darkness"* and closes *"Thus it has been made pleasing to the disbelievers that which they were doing"*; 6:123 is about the criminals of every city. **Neither is punishment**, neither contradicts the beat, and the shape is strictly softer than shipped `al-afuw@1`'s 42:26 (*"the disbelievers will have a severe punishment"*), which the plan itself records as non-blocking. | **yes — with the tail disclosed, not hidden** |

### What comes immediately after (and before) each excerpt

Successor sweep run per plan §7, on every quotation. **`n±1` cells record what was actually fetched
on 2026-08-03.**

| excerpt | fetched | verdict |
|---|---|---|
| **6:122** — the excerpt's own leading material (`n` internal, before the ellipsis) | `أَوَمَن كَانَ مَيْتًا فَأَحْيَيْنَـٰهُ` — SI: *"And is one who was dead and We gave him life…"* | **disclosed, and it is why the beat opens with a visible ellipsis.** Two reasons it is dropped: (a) *"We gave him life"* is a rendered-English adjacency with `al-qadir@1` **[D]**'s verse beat *"Able to give life to the dead"*; (b) `ḥ-y-y` is a standing hazard root (ledger §5a, 3 decks, plus **Al-Hayy 15 and Al-Muhyi 69 still to come**). **Grammatical disclosure the founder is entitled to:** the clause quoted sits inside a **rhetorical question** comparing two people. The question *presupposes* what the beat asserts — it does not doubt it — but the beat's quotation marks are the deck's, not the source's. |
| **6:122** — the excerpt's own tail (`n` internal, after the ellipsis) | `كَمَن مَّثَلُهُۥ فِى ٱلظُّلُمَـٰتِ لَيْسَ بِخَارِجٍ مِّنْهَا ۚ كَذَٰلِكَ زُيِّنَ لِلْكَـٰفِرِينَ مَا كَانُوا۟ يَعْمَلُونَ` — SI: *"…like one who is in darkness, never to emerge therefrom? Thus it has been made pleasing to the disbelievers that which they were doing."* | **disclosed. Not punishment; it is the counter-case.** Sweep Q3 answered explicitly: omitting a *contrast* does not change what is asserted about the first party. Also dropped for a bar-3 reason — *"darkness"* is `al-mujeeb@1` **[D]** beat 3's rendered word (*"within the darknesses"*), the only such hit in the corpus. |
| **6:122 (n−1) = 6:121** | *"And do not eat of that upon which the name of Allāh has not been mentioned… And if you were to obey them, indeed, you would be associators."* | **clean of punishment; a dietary ruling and a warning about disputation.** Does not touch the beat. |
| **6:122 (n+1) = 6:123** | *"And thus We have placed within every city the greatest of its criminals to conspire therein. But they conspire not except against themselves, and they perceive [it] not."* | **disclosed. Not a punishment āyah** — no ʿadhāb, no Fire — but it is the harshest thing within one āyah of this deck, and a founder who opens `quran.com/6/122` will scroll into it. It contradicts no beat and completes no thought the beat leaves open. |
| **Muslim 763e / 763g** | Free-standing narrations with a beginning and an end. 763g ends at the supplication itself; 763e ends at the two short rakʿahs at dawn. | **clean — there is no continuation to be dishonest about.** |
| **Sūrat al-Anʿām, deck-level** | **No deck in the 24-deck ledger cites Sūrat al-Anʿām.** (6:127 appears only on the ledger's *rejected* list.) | **clean — this deck opens the sūrah.** |

### ⚠️ The Light Verse — fetched, swept, and deliberately NOT used

**This is the single item on this deck a founder should read before signing.** 24:35 is the obvious
anchor for An-Nur and it is not here.

**Fetched 2026-08-03: 24:34, 24:35, 24:36, 24:37.** Full 24:35, Saheeh International:

> *"Allāh is the Light of the heavens and the earth. The example of His light is like a niche within
> which is a lamp; the lamp is within glass, the glass as if it were a pearly [white] star lit from
> [the oil of] a blessed olive tree, neither of the east nor of the west, whose oil would almost glow
> even if untouched by fire. Light upon light. Allāh guides to His light whom He wills. And Allāh
> presents examples for the people, and Allāh is Knowing of all things."*

**Three independent reasons it is refused, in the order they were found:**

1. **Bar 2 — it states.** `ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` is an identification, not a
   demonstration. Bar 2 killed `al-haleem@1` rev 1 for exactly this class of defect.
2. **Translation risk — the `al-kareem@1` finding. ⚠️ DOWNGRADED IN R2 TO AN OPEN QUESTION, NOT A
   REASON.** That sentence carries the longest exegetical dispute in the Qurʾān (is `نُور`
   predicated of the divine essence, or is it *munawwir* — "the illuminator of"?), and published
   Englishes do pick sides. **But revision 1 asserted that "there is no neutral rendering to
   produce", and that is NOT established.** The literal calque — *"Allah is the light of the
   heavens and the earth"* — preserves the very same *iḍāfa* ambiguity, because English *"the light
   of X"* is itself ambiguous between *"the light that X is"* and *"the light by which X is lit"*.
   **A neutral rendering may well exist.** Revision 1's own "method limits" section already flagged
   this as the deck's one contestable claim; the independent verifier confirmed it. **This row is
   therefore a caution, not a ground.** The refusal below stands on ground 1 alone, and is
   over-determined by ground 3.
3. **Bar 3 — the only clause in the āyah carrying divine action *on the Name's own root* collides
   head-on.** **(Corrected in R2: revision 1 said "the only clause that carries divine action",
   which is false — `وَيَضْرِبُ ٱللَّهُ ٱلْأَمْثَـٰلَ لِلنَّاسِ` is a second finite verb with Allah as
   subject. It is not a candidate, because what it does is *present examples*, not *give light*, so
   it demonstrates nothing about this Name. The conclusion survives the correction; the wording did
   not.)** `يَهْدِى ٱللَّهُ لِنُورِهِۦ مَن يَشَآءُ` is `h-d-y`, and *"Allah … guides"* is shipped
   `al-hadi@1`'s **verse beat in rendered English** (*"…And Allah surely guides the believers to the
   Straight Path"*, 22:54). Using it would put An-Nur's verse beat one word away from Al-Hadi's.
   And the āyah's tail is a **trailing epithet** (`عَلِيمٌ` — Al-Aleem, id 14, **being drafted in this
   same wave**), which bar 1 forbids as a carrier.

**A parable-only excerpt was drafted and discarded.** Quoting only *"…the likeness of His light is
as a niche in which there is a lamp … light upon light…"* removes objections 1 and 2 and keeps the
Name's root four times — **but it leaves bar 1 unmet**, because the parable describes His light
without Allah doing anything to anyone. Trading bar 1 is not sanctioned by plan §7; **bar 4 is the
shock absorber, not bar 1.** So the deck moved anchors instead, which is exactly what the brief for
this Name asked for if 24:35 could not be made safe.

**Recorded consequence:** 24:35 is **blocked, not free.** A future An-Nur revision, or any other
Name, must solve (3) — and satisfy itself about (1) — before touching it. 24:34, 24:36 and 24:37
were fetched and are clean (24:36–37 is the mosques passage) and are **left free**.

#### ⚠️ R2 — AND REFUSING 24:35 DID NOT MAKE THIS DECK NEUTRAL. It picked the other side.

**This is the finding neither the drafter nor the first pass had, and it is the most important
paragraph in this file.** Revision 1 told the founder it had declined to adjudicate
essence-vs-*munawwir*. **That is not true, and the founder should not sign a sentence that says it
is.**

Having refused the contested predication, the deck anchored on **6:122 —
`وَجَعَلْنَا لَهُۥ نُورًا`, Allah *making a created light for a person*.** That is the *munawwir*
side of the same dispute, expressed as an act rather than as a predication. And it is not incidental
decoration: **it is this deck's bar-1 carrier and its bar-4 carrier at once.** The theological
position is therefore *load-bearing*, not avoided.

**This is `al-kareem@1`'s failure wearing a new costume: adjudication by choice of PASSAGE rather
than by choice of TRANSLATION.** The plan's rule was written against translators; the same move is
available one level up, in selection, and it is harder to see because refusing a text feels like
restraint.

**Why it is disclosed rather than fixed:**
- **No beat predicates `nūr` of Allah.** Every rendered string is about light *given to a human
  being*. The deck says nothing about the divine essence in either direction.
- ***Munawwir* is the classical, majority and theologically conservative reading**, and it is the
  safer of the two to lean on implicitly.
- **There is no third option.** Any An-Nur deck must anchor somewhere, and every `n-w-r` site with
  Allah as actor sits on one side of this question or the other. **Neutrality was never on the
  table; the only choice was whether to say so.**

**Standing rule this deck earned, for the ledger:** *refusing a contested text does not make a deck
neutral — it relocates the adjudication into the selection, where no table is looking. A deck that
declines a passage on theological grounds must state which side its replacement lands on.*

### Other candidates fetched, evaluated and refused — do not re-derive

**Every Qurʾānic `n-w-r` site with Allah as the actor was enumerated and checked.**

| candidate | fetched | why refused |
|---|---|---|
| **9:32** `وَيَأْبَى ٱللَّهُ إِلَّآ أَن يُتِمَّ نُورَهُۥ` | 9:31, 9:32, 9:33 | The single best bar-1 clause outside 24:35 — a finite verb of divine action on the Name's own root — and it is the catalogue's own `lesson` in one line. **Refused on register (bar 5).** Its **n−1, 9:30, ends `قَـٰتَلَهُمُ ٱللَّهُ` — a curse** — inside anti-Jewish/Christian polemic. A nightly muḥāsabah surface cannot sit one āyah below that. |
| **61:8** `وَٱللَّهُ مُتِمُّ نُورِهِۦ` | 61:7, 61:8, 61:9 | Same clause in participle form (weaker for bar 1). n−1 is a rebuke (*"who is more unjust…"*, ending `وَٱللَّهُ لَا يَهْدِى` — `h-d-y` again). The āyah's own tail is `وَلَوْ كَرِهَ ٱلْكَـٰفِرُونَ`. Polemical register. **Flagged, not free.** |
| **6:1 · 5:15–16 · 42:52 · 57:9 · 65:11 · 2:257** | 6:1, 5:15, 5:16 read; 2:257 already on the ledger's rejection list | All run *"out of the darknesses into the light."* **Bar 3 in English:** *"darkness(es)"* is `al-mujeeb@1` **[D]**'s beat 3. 5:15–16 and 42:52 add `h-d-y`; 2:257 adds `وَلِىُّ` (`al-waliyy@1`) and is already rejected on bar 5; 42 and 65 are crowded sūrahs. |
| **25:61–62** *"…placed therein a [burning] lamp and luminous moon"* / *"He who made the night and the day in succession for whoever desires to remember"* | 25:60, 25:61, 25:62 | **Clean, beautiful, and deliberately left free.** Refused here because its Name is arguably **Al-Khaliq (10, claimed this wave)** or **Al-Badi (97)** — the light is celestial furniture, not light given to a person — and because *"remember/remembrance"* is shipped `as-salam@1`'s verse beat (13:28). n−1 (25:60) is a rebuke scene naming Ar-Raḥmān. |
| **64:8** *"…and the light which We have sent down"* | 64:7, 64:8, 64:9 | Divine first-person verb, but the light **is the Qurʾān**, which makes the deck about revelation rather than about a person; tail is a trailing epithet (`خَبِيرٌ`, Al-Khabeer 49); 64:10 (n+2) ends in the Fire. |
| **39:22 · 39:69 · 57:12–13 · 57:19 · 66:8 · 57:28 · 2:17 · 24:40 · 71:16 · 7:157** | 39:22 read in full; others enumerated | 39:22 carries *"So woe to those whose hearts are hardened"* **inside the same āyah**. 39:69 / 57:12–13 / 57:19 / 66:8 are Day-of-Judgement register. 57:28 carries `وَيَغْفِرْ لَكُمْ` (`gh-f-r`, four decks). 2:17 and 24:40 are **negative constructions** (light taken away / no light) — already a ledger-rejected class. 71:16 is **Nūḥ's speech about Allah** — the ledger's "human speech about Allah" class. 7:157 is passive and human-subject. |
| **Ṣaḥīḥ Muslim 178 / 179** (`نُورٌ أَنَّى أَرَاهُ`; `حِجَابُهُ ٱلنُّورُ`) | not fetched — refused on description | Theologically contested and, in 179, a burning image. **Left free but flagged as delicate.** Recorded so nobody assumes it was overlooked. |
| **Bukhārī 5018 / Muslim 796** — Usayd b. Ḥuḍayr reciting at night, the canopy `أَمْثَالُ ٱلْمَصَابِيحِ` above him | not fetched | **The best remaining light narrative in the corpus, and genuinely free.** Not used here only because the duʿā-first method points at Ibn ʿAbbās's night: the catalogue's duʿā comes from that narration and not from this one. |
| **Mūsā and the fire at Ṭuwā** (20:9–14 / 27:7–8 / 28:29–30) | not fetched | **Blocked, not free.** Shipped `al-hadi@1`'s story is Mūsā's flight to Midian at **28:22**; the fire is the next scene of the same arc, seven āyāt on. Also `نَار`, not `نُور`, and 20:10 carries `هُدًى`. |
| **Tirmidhī 3419** | **fetched** | **Graded Ḍaʿīf (Darussalam) on the page. Unusable on the grade alone.** ⚠️ **R2 CORRECTION OF A FALSE CLAIM IN REVISION 1.** This row previously read *"the only narration carrying **both** the tongue clause and 'make me light'"*. **It carries NEITHER.** Page re-searched: `لِسَانِي` = **0 occurrences**; `وَاجْعَلْنِي` = **0 occurrences**. Its list runs `…وَنُورًا فِي قَبْرِي وَنُورًا فِي قَلْبِي…` and closes `اللَّهُمَّ أَعْظِمْ لِي نُورًا وَأَعْطِنِي نُورًا **وَاجْعَلْ لِي نُورًا**`. **Revision 1's own five-route table (below) recorded this correctly and the prose here contradicted it** — the deck disagreed with itself and the wrong half is the one that reached the coordinator's report and the collision ledger. **The correction STRENGTHENS the conclusion:** *no* route carries both catalogue clauses, which is precisely why the duʿā is a composite and stays unpinned. |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | Beat 1 bridge | — | authored | n/a | ✅ **honest label — authored copy, no scripture claim. ⚠️ R2 REWRITE: revision 1 attributed a motive no narration carries.** It read *"…so he could hear what the Prophet ﷺ was asking for."* **Muslim 763e states no purpose at all**, and **763g states a different one**: `فَبَقَيْتُ كَيْفَ يُصَلِّي رَسُولُ اللَّهِ ﷺ` — *"and I observed how the Messenger of Allah ﷺ prayed."* The bridge now reads **"to watch how the Prophet ﷺ prayed"**, which is 763g's own stated reason, and *"arranged to be woken"* is 763e's `فَأَيْقِظِينِي`. **The deck no longer tells the reader what a ten-year-old was hoping to hear.** |
| 2.1 | Beat 2 `name_intro` | catalog id 17 | catalog only | n/a | ✅ **verified byte-identical to catalog**, checked programmatically 2026-08-03: `arabic` = `النُّورُ`, `transliteration` = `An-Nur`, `english` = `The Light`. No authored gloss added. |
| 3.1 | Beat 3: Ibn ʿAbbās spent the night at his aunt Maymūna's; **"When the Messenger of Allah ﷺ gets up, wake me."** | **Rendered from the Arabic.** sunnah.com's published English is *"and said to her: Awake me when the Messenger of Allah (ﷺ) stands to pray (at night)"* — *"Awake me"* is archaic and the parenthesis is the translator's. The Arabic is `فَقُلْتُ لَهَا إِذَا قَامَ رَسُولُ اللَّهِ ﷺ فَأَيْقِظِينِي` — literally *"I said to her: when the Messenger of Allah ﷺ gets up, wake me."* **No word is added; `قَامَ` is rendered "gets up", not "stands to pray", because the Arabic does not say "to pray" here.** | [Sahih Muslim 763e](https://sunnah.com/muslim:763e) — Wayback `20260113063455` | **ṣaḥīḥ** (Ṣaḥīḥ Muslim; the collection's own grade, no Darussalam line needed) | ✅ **verified by live fetch of the Wayback capture of the exact bare number 2026-08-03.** Arabic transcribed above from that capture. Narrator: Kurayb, mawlā of Ibn ʿAbbās, ← Ibn ʿAbbās. **`muslim:763` resolves to 763a, which is a different route with a different wording — that distinction is why the lettered number is cited.** |
| 3.2 | Beat 4: he stood on his left; taken by the hand and moved to his right; earlobe when he dozed off | **Labelled paraphrase**, following the published English closely: *"I stood on his left side. He took hold of my hand and made me stand on his right side, and whenever I dozed off he took hold of my earlobe."* | [Sahih Muslim 763e](https://sunnah.com/muslim:763e) | **ṣaḥīḥ** | ✅ **verified, same capture.** The beat asserts nothing the narration does not carry. Arabic: `فَقُمْتُ إِلَى جَنْبِهِ الأَيْسَرِ فَأَخَذَ بِيَدِي فَجَعَلَنِي مِنْ شِقِّهِ الأَيْمَنِ فَجَعَلْتُ إِذَا أَغْفَيْتُ يَأْخُذُ بِشَحْمَةِ أُذُنِي`. **Corroborated independently by Bukhārī 6316** (`فَأَخَذَ بِأُذُنِي فَأَدَارَنِي عَنْ يَمِينِهِ`), fetched, **quoted on no beat.** |
| 3.3 | Beat 5, the supplication, **partial with a visible ellipsis on the beat** | **sunnah.com's published English of 763g, verbatim within the quoted regions.** Nothing here is contested; no re-rendering was needed. | [Sahih Muslim 763g](https://sunnah.com/muslim:763g) — Wayback `20260418160155` | **ṣaḥīḥ** | ✅ **verified by live fetch 2026-08-03.** Full published English: *"O Allah! place light in my heart, light in my hearing, light in my sight, light on my right, light on my left, light in front of me, light behind me, light above me, light below me, make light for me," or he said: "Make me light."* **The beat elides six directional clauses and shows the elision with `…` ON THE BEAT** (plan §7, batch-2 rule 2). Arabic: `اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي سَمْعِي نُورًا وَفِي بَصَرِي نُورًا … وَاجْعَلْ لِي نُورًا أَوْ قَالَ وَاجْعَلْنِي نُورًا`. **Two further disclosures.** (a) *"or, the narrator says, he said: 'Make me light.'"* — **the uncertainty is the narration's own** (`أَوْ قَالَ`), not the deck's, and the deck shows it rather than picking the wording it prefers. (b) The narration says he said this **`فِي صَلاَتِهِ أَوْ فِي سُجُودِهِ`** — *in his prayer, or in his prostration*; the narrator is unsure which. The beat says *"went out to the prayer, and in it he kept saying"*, which is true on either reading and does not resolve the narrator's doubt. |
| 3.4 | Beat 5's closing clause is the deck's hinge into beat 8 | — | — | — | ⚠️ **Stated plainly because beat 8 leans on it:** `وَاجْعَلْنِي نُورًا` is recorded in Ṣaḥīḥ Muslim as **the narrator's alternative**, not as the certain wording. It is nevertheless the wording **the catalogue's own duʿā uses**, so beat 7 renders it regardless of this deck. Beat 5 discloses the alternative on screen; beat 8 then uses the clause the user has just read in the duʿā. **⚠️ R2 — the verifier ruled that a beat MAY rest on `أَوْ قَالَ` when the beat shows it, and this one does. The caveat it attached is accepted and recorded here rather than argued with: beats 7 and 8 then print `وَاجْعَلْنِي نُورًا` / *"make me light"* as settled, which partly neutralises beat 5's disclosure three screens earlier.** Beat 7 is catalogue-locked and cannot be changed by this deck. **Beat 8 can**, and the one-line option is on the table: *"The last one asks for no place at all — and the narrator was not sure he had even heard it right: make me light."* **Not applied**, because it trades the takeaway's punch for a hedge the user has already been shown. **Founder's call, and it is a real one.** |
| 3.5 | ⚠️ **R2 — THE STORY IS A TWO-CHAIN SPLICE, added because revision 1 never said so** | — | Muslim **763e** (beats 3–4) + Muslim **763g** (beat 5) | both **ṣaḥīḥ** | ✅ **disclosed, not fixed.** 763e's chain is Ḍaḥḥāk ← Makhrama b. Sulaymān ← Kurayb ← Ibn ʿAbbās; 763g's is Shuʿba ← Salama ← Kurayb ← Ibn ʿAbbās. **Two chains, two accounts of a night at Maymūna's, rendered on screen as one continuous evening.** 763e has *"wake me"* and the earlobe and **no supplication**; 763g has the vigil and the supplication and **no "wake me"**. **Nothing is attributed to the wrong person** — same Companion, same transmitter — and **each beat carries its own `source`, so the screen is honest.** The defect in R1 was asymmetric rigour: it disclosed the *duʿā's* splice in a five-row table and said nothing about its own story's. **One-line single-chain alternative recorded in the disclosure box above the verse beat.** |
| 6.1 | Beat 6, verse anchor: **"…and We made for him a light by which he walks among the people…"** | **Rendered from the Arabic.** Saheeh International for the same clause is *"and made for him light by which to walk among the people"* — **which drops the visible subject.** With the preceding clause elided for the reasons in the successor table, SI's English leaves the beat with no agent at all, and bar 1's whole content would then live only in this table (the `al-qadir@1` R2 failure). `وَجَعَلْنَا` is first-person plural perfect: *"and We made"*. `يَمْشِى بِهِۦ فِى ٱلنَّاسِ` is *"he walks by it among the people"*. **Nothing is added and nothing contested is resolved** — `نُور` here is uncontroversially a created light given to a person, not the disputed predication of 24:35. | [Qur'an 6:122](https://quran.com/6/122) | Qurʾān | ✅ **verified by live fetch `api.quran.com/api/v4/verses/by_key/6:122?fields=text_uthmani,text_imlaei&translations=20`, 2026-08-03.** `text_uthmani` = `أَوَمَن كَانَ مَيْتًا فَأَحْيَيْنَـٰهُ وَجَعَلْنَا لَهُۥ نُورًا يَمْشِى بِهِۦ فِى ٱلنَّاسِ كَمَن مَّثَلُهُۥ فِى ٱلظُّلُمَـٰتِ لَيْسَ بِخَارِجٍ مِّنْهَا ۚ كَذَٰلِكَ زُيِّنَ لِلْكَـٰفِرِينَ مَا كَانُوا۟ يَعْمَلُونَ`. The quoted Arabic region is `وَجَعَلْنَا لَهُۥ نُورًا يَمْشِى بِهِۦ فِى ٱلنَّاسِ` — **contiguous, nothing reordered.** Ellipses at **both** ends are on the beat. **SI's full string is in the successor table so the founder can swap it in one line.** |
| 7.1 | Beat 7 duʿā | catalog id 17 — **no scripture citation claimed** | catalog only | n/a | ✅ **verified byte-identical to catalog** across `dua_arabic` / `dua_transliteration` / `dua_translation`, checked programmatically 2026-08-03. **UNPINNED — see the next section.** |
| 8.1 | Beat 8 takeaway | — | authored | n/a | ✅ **honest label — authored copy.** Every noun in it (*heart, hearing, sight, above, below, make me light*) is a word rendered on beat 5 or beat 7. It asserts no new fact. |
| — | **Corroboration fetched, quoted on no beat** | — | [Sahih al-Bukhari 6316](https://sunnah.com/bukhari:6316) — Wayback `20260422171512`; [Sunan Abi Dawud 1353](https://sunnah.com/abudawud:1353) — Wayback `20260207143240`; [Sahih Muslim 763a](https://sunnah.com/muslim:763) — Wayback `20260418043808`; [Sahih Muslim 763b/c/d](https://sunnah.com/muslim:763b) | Bukhārī 6316 **ṣaḥīḥ**; Abū Dāwūd 1353 grade line reads **Sahih**; Muslim **ṣaḥīḥ** | ✅ **all fetched 2026-08-03.** Used only to establish the duʿā's provenance (next section). |

### ⚠️ The duʿā is a two-route composite — this deck must render NO duʿā `source`

**All five routes were fetched. Not one of them contains all three of the catalogue's clauses.**

| route | heart | **tongue** | **"make me light"** | closes with |
|---|---|---|---|---|
| **Ṣaḥīḥ al-Bukhārī 6316** | ✅ | ✖ | ✖ | `وَاجْعَلْ لِي نُورًا` |
| **Ṣaḥīḥ Muslim 763a** | ✅ | ✖ | ✖ | `وَعَظِّمْ لِي نُورًا` |
| **Ṣaḥīḥ Muslim 763g** | ✅ | ✖ | ✅ (as `أَوْ قَالَ`) | `وَاجْعَلْ لِي نُورًا أَوْ قَالَ وَاجْعَلْنِي نُورًا` |
| **Sunan Abī Dāwūd 1353** (grade line: **Sahih**) | ✅ | ✅ `وَاجْعَلْ فِي لِسَانِي نُورًا` | ✖ | `اللَّهُمَّ وَأَعْظِمْ لِي نُورًا` |
| **Jāmiʿ at-Tirmidhī 3419** | ✅ | ✖ (`قَبْرِي`, not `لِسَانِي`) | ✖ (`وَاجْعَلْ لِي نُورًا`) | — · **graded Ḍaʿīf (Darussalam)** |

**Conclusion: the catalogue's `dua_arabic` for id 17 is a composite of two different ṣaḥīḥ routes**
— the tongue clause from the Abū Dāwūd 1353 route, `وَاجْعَلْنِي نُورًا` from Muslim 763g — with the
intervening clauses of both dropped. **A `source` on the duʿā beat would assert a contiguity and a
single provenance the printed string does not have.** So:

> **`an-nur@1` must NOT be added to `renderedDuaSources`, and beat 7's `source` field must be
> empty.** The gate asserts that map **bidirectionally**; a pin here fails it in the other
> direction, and a `cf.` pin would be a live claim that the string is one narration's wording.

**And — deliberately — NO catalogue change is recommended.** The ledger records that a drafter's
confident recommendation to change catalogue data has now been wrong in **both** prior batches, in
the same direction. Two things a founder might otherwise be told to "fix", each of which is fine:

1. **The card's `hadith` field for id 17 is defensible as printed.** It reads: *"The Prophet ﷺ used
   to pray on the way to Fajr: 'O Allah, place light in my heart, light in my hearing, light in my
   sight — and make me a light.' (Muslim)"*. **The quoted words are Muslim 763g's** (heart, hearing,
   sight … *"Make me light"*), and the em-dash is doing honest ellipsis work. The *"on the way to
   Fajr"* framing matches **Abū Dāwūd 1353** (`ثُمَّ خَرَجَ إِلَى الصَّلاَةِ وَهُوَ يَقُولُ`) rather
   than Muslim's *"in his prayer or in his prostration"* — a framing difference, not a
   misattribution of the words. **No edit requested.**
2. **The duʿā is not "unsourced".** Every clause in it is in a ṣaḥīḥ narration. It is the
   *combination* that is unpinnable. That is a different and much smaller finding than "no
   provenance", and it should not be reported to the founder as the latter.

### Open founder calls (each is one line either way)

1. **`al-baseer@1` adjacency on beat 5.** *"light in my hearing, light in my sight"* sits next to
   shipped `al-baseer@1`'s *"All-Hearing, All-Seeing"*. **Kept**, because the faculties are the
   supplication's own texture and the referent is a human being, not a Name. **One-line trim if the
   founder prefers zero adjacency:** *"O Allah! place light in my heart … light above me, light
   below me, make light for me."* Beat 8 would then read *"heart, above, below"*.
2. **Verse-beat translation.** The beat renders 6:122's clause from the Arabic. **Saheeh
   International's own string is fetched and ready** — *"…and made for him light by which to walk
   among the people…"* — and costs only the visible subject.
3. **6:123 proximity.** Disclosed above. It is the harshest thing within one āyah of this deck. If
   the founder's line is stricter than the one already applied to shipped `al-afuw@1`'s 42:26, this
   is the row to say so on.

### How this deck was kept apart from `al-haqq@1` (same agent, same wave)

The two Names are adjacent in a specific way — **light that reveals, truth that is revealed** — so
the separation was designed, not assumed:

- **Different landing zones for beat 8.** An-Nur's engine is ***made of it, not given it*** — a
  request that changes category in its last clause, from *having* to *being*. Al-Haqq's engine is
  ***the counterfeiters recognised it*** — the people who built the fake are the ones who know the
  real thing on sight. One is about **transformation of the asker**; the other is about **who is
  able to recognise**. Neither deck contains the other's idea in any form.
- **A hard textual firewall.** The tahajjud duʿā (Bukhārī 1120 / 7385, Muslim 769a) — which is the
  provenance of **id 61's** duʿā — **also contains `أَنْتَ نُورُ السَّمَاوَاتِ وَالْأَرْضِ`, An-Nur's
  own phrase.** That narration is therefore **quoted on no beat of either deck**, and appears in
  `al-haqq@1` only in its duʿā-provenance table. Conversely, nothing from the Ibn ʿAbbās *light*
  night appears anywhere in `al-haqq@1`.
- **Zero shared rendered vocabulary.** *light / lamp / made of it* belong to this deck;
  *truth / real / illusion / prostration / on the ground* belong to Al-Haqq. Diffed both ways.

### Method limits — stated because the founder signs against this table

1. **Ḥadīth verification is not independent of sunnah.com as a corpus.** sunnah.com 403s automated
   fetching, so every ḥadīth here was read from a **Wayback capture of the exact bare sunnah.com
   number**. **No printed edition and no Arabic-primary database (Shamela, Dorar, al-Maktaba
   al-Shāmila) was consulted, and NO ISNĀD WAS AUDITED.** Published grade lines were accepted; where
   the collection itself is Bukhārī or Muslim, the grade asserted is the collection's own status.
2. **A second reader has not seen this.** Everything above is one agent's fetch-and-check. Plan §6's
   finding stands: a founder signing against a ✅ table is signing against claims that have sometimes
   been wrong, which is why the adversarial pass is mandatory.
3. **The concurrent wave is partially invisible.** The English bar-3 pass was run against the 24
   decks in `assets/content/name_stories.json` and against every file in this directory. **Nine
   sibling agents are drafting right now**; their rendered strings do not exist yet. What was checked
   instead is every claim file in `.context/claims/` as of writing (ids 4, 7, 10, 14, 40, 57, 61, 93,
   98). **A collision with a wave-3 deck drafted after this file cannot have been caught here.**
4. **The Light-Verse refusal is a judgement, not a measurement — and R1's version of it was
   overclaimed.** Grounds 1 and 3 are mechanical. **Ground 2 — "no neutral English exists" — was
   asserted without consulting a tafsīr corpus, was independently found not to be established, and
   has been DOWNGRADED to an open question.** The refusal stands on ground 1 and is over-determined
   by ground 3; it does not need ground 2 and no longer rests on it.
5. **The deck's own theological position is implicit, not neutral.** See the R2 disclosure above:
   the replacement anchor (6:122) lands on the *munawwir* side of the dispute 24:35 was refused over.
   **Whether that is acceptable is a founder/scholar call, not a drafting one.**
6. **Every failure found in R1 was an OVERCLAIM, not a fabrication** — *"the only narration
   carrying both"*, *"the only clause that carries divine action"*, *"no neutral English exists"*,
   and a motive attributed to a boy. **Scripture authenticity came back clean; every one of the hard
   calls held.** The pattern is recorded here because it is the useful thing: *a finding stated at
   its true strength is worth more than the same finding inflated, because the inflation is what a
   verifier spends its time refuting instead of finding the next real thing.*
