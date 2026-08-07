# Batch 2 — fix report, and a feasibility read on "all 99 Names"

**Date:** 2026-08-03. **Author:** Claude (repair pass). **Fixing against:** [`2026-08-03-BATCH2-ADVERSARIAL-VERDICT.md`](./2026-08-03-BATCH2-ADVERSARIAL-VERDICT.md), which is treated as authoritative throughout.

**The premise this pass ran under, per the founder's 2026-08-03 decision:** every one of the 99 Names gets a deck. **"Reject the Name" is off the table as a resolution.** The five bars do not relax — authenticity, register and the no-sibling-collapse rule still bind absolutely — but a bar failure is now *"find a better source, passage or framing"*, never *"pick a different Name"*. The previously-recommended Al-Waliyy → Al-Hayy swap is **withdrawn**, and Al-Hayy is left free for its own deck.

**Nothing was transcribed.** `assets/content/name_stories.json`, `test/content/name_stories_ship_gate_test.dart` and `assets/content/collectible_names.json` are untouched. Nothing was committed. All five files remain marked DRAFT.

---

## 0 · Method, so the ✅s in the drafts mean something

Every ✅ written in this pass describes a check that was actually run in this pass.

- **Qur'ān:** `https://api.quran.com/api/v4/verses/by_key/{s}:{a}?fields=text_uthmani,text_imlaei&translations=20,85`. **58 āyāt fetched.** Substring tests run in Python, byte-level, against the **raw** translation string, with `<sup>` handling stated per row by character offset.
- **Ḥadīth:** sunnah.com 403s automation, so **Wayback captures of the exact sunnah.com URL**, dereferenced via the CDX / availability APIs. Newly fetched this pass: **Bukhārī 595**, **Muslim 680a**, **Muslim 680b**, **Muslim 681**, **Muslim 918a**, **Tirmidhī 3438**, **Tirmidhī 3524**.
- **Successor sweep** run on every new quotation, in both directions, with `verses/by_key/{s}:{n+1}` → **HTTP 404** used as the sūrah-final signal (confirmed for 93:12).
- **Bar 3 run twice**: once over Arabic roots, once over **rendered English** — every `primary` / `label` / `source` / `translation` string of all 14 shipped decks in `name_stories.json`, plus all five batch-1 drafts and all five batch-2 drafts. Both collisions the verifier found were invisible to the root-only sweep; the English pass is now recorded in each deck's bar-3 cell.
- **Every partial quotation now carries a visible ellipsis ON THE BEAT.** Table notes were not accepted as disclosure anywhere.
- **No scripture was composed or reconstructed from memory at any point.**

---

## 1 · `al-qayyum@1` — REJECTED → re-drafted from scratch

### What the verdict said
Bars 1 and 2 overclaimed: **93:1–3 has no `q-w-m` root** and demonstrates *non-abandonment during a pause in waḥy* — a different attribute; **2:255 *states* `لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ` rather than showing it.** The engine was therefore an undisclosed join, structurally identical to the one `al-muid@1` confesses in a dedicated section — *"two decks make the same move; one owns it and one does not."* The "Satan" beat priced a **tone** risk when the real one is **doctrinal confusion** (*"your Satan"* is the mocker's word for **Jibrīl**). And the duʿā flag's migration recommendation was **backwards**.

### What changed
**The scripture is entirely replaced. Only the Name, the bridge and the takeaway survive.**

| | R1 | R2 |
|---|---|---|
| story | Bukhārī 4950 — the taunt, and the aḍ-Ḍuḥā revelation | **Ṣaḥīḥ al-Bukhārī 595** — the night the whole camp slept through Fajr, *including Bilāl, who had volunteered to keep them awake* |
| bar-1 evidence | 93:3 (`w-d-ʿ`, `q-l-y`) | **Qur'ān 39:42 on beat 5** — `فَيُمْسِكُ … وَيُرْسِلُ`, Allah the subject, two finite verbs of *holding* and *releasing*, performed on every human every night |
| verse anchor | 2:255 (carrying bars 2 and 4) | **2:255, carrying bar 4 only.** It is no longer asked to demonstrate anything |
| "Satan" beat | present, priced as tone | **gone with the narration** |

**Why this is not the same join in different clothes:** the ḥadīth's payload sentence is the Prophet ﷺ saying **"Allah captured your souls when He wished, and released them when He wished"** (`إِنَّ اللَّهَ قَبَضَ أَرْوَاحَكُمْ حِينَ شَاءَ، وَرَدَّهَا عَلَيْكُمْ حِينَ شَاءَ`), and 39:42's subject is souls taken `فِى مَنَامِهَا` — *in their sleep*. **The two texts are about the same act on the same occasion type.** R1 welded a waḥy-pause narration to a self-subsistence āyah; R2 does not weld anything. The one join that remains — one night to every night — is stated **on the beat** in five words: *"The Qur'ān says it of every sleeper:"*.

**Bar 4 is kept, not traded.** `ٱلْقَيُّومُ` is in 2:255 and Saheeh International renders it *"the Self-Sustaining"*, which is catalog id 16's English word for word.

### What I fetched to justify it
- **Ṣaḥīḥ al-Bukhārī 595** — Wayback `20250429112101`. Narrator `Abdullāh b. Abī Qatāda ← his father; in-book Book 9 Hadith 70; book *Times of the Prayers*. **Four English strings substring-tested byte-exact** after whitespace normalisation, including the two on beats. No punishment, no rebuke of Bilāl, continuation is ablution + the prayer performed late.
- **Muslim 680a / 680b / 681** — all three fetched and read in full, as the parallel narrations of the same night. **680b carries `فَإِنَّ هَذَا مَنْزِلٌ حَضَرَنَا فِيهِ الشَّيْطَانُ`** — disclosed in the deck's sweep table so nobody later "enriches" the deck from it.
- **39:41 / 39:42 / 39:43** — fetched. 39:42's SI carries **zero `<sup>`**; the beat string is byte-exact against the raw string. 39:41 ends `وَمَآ أَنتَ عَلَيْهِم بِوَكِيلٍ` (`al-wakeel@1`'s Name-noun, n−1, off-screen — disclosed). 39:43 is a rhetorical question, no punishment.
- **2:254 / 2:255 / 2:256** — re-fetched. 2:255 carries six `<sup>`; **two fall inside the quoted region, at offsets 54 and 104, quote ending at 134** — R1's count and positions were correct and are restated with the offsets.
- **Sūrat az-Zumar crowding** — **newly disclosed**: `al-ghaffar@1` ships at 39:53, eleven āyāt from this deck's beat-5 quotation.

### The duʿā flag — deleted, and independently re-verified before writing anything
The verdict said R1's recommendation was backwards. **I re-verified from source rather than accepting either account.**

1. **The full string is one narration.** Anas b. Mālik → the Prophet ﷺ to Fāṭima: `يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله، ولا تكلني إلى نفسي طرفة عين`. **Checked programmatically against `collectible_names.json` id 16 `dua_arabic`: consonantal skeleton identical, character for character.** Collections: al-Nasāʾī (*ʿAmal al-Yawm wa'l-Layla* 570), al-Ḥākim (*Mustadrak* 1/545), al-Bazzār. Gradings found: **ṣaḥīḥ** (al-Ḥākim), **isnād ṣaḥīḥ** (al-Mundhirī, *at-Targhīb* 1/313), **ḥasan** (Ibn Ḥajar, *Natāʾij al-Afkār* 2/407), **isnād ḥasan** (al-Albānī, *Silsila Ṣaḥīḥa* 227). Fetched: <https://islamqa.info/en/answers/109609> and <https://hadithanswers.com/reference-for-the-dua-wa-la-takilni-ila-nafsi-tarfata-ayn/>.
2. **"A different narrator entirely" was false** — the al-Ḥākim/Fāṭima route *is* Anas b. Mālik.
3. **Tirmidhī 3524 re-fetched** (Wayback `20260309115006`): its text is `يَا حَىُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ` and nothing else — **which is catalog id 15 (Al-Hayy)'s entire `dua_arabic`**, differing by one orthographic character (`ي`/`ى`) and confirmed as an exact skeleton **prefix** of id 16's. R1's proposed migration would have attached an eight-word citation to a twenty-two-word card and duplicated id 15's citation.

**The flag is deleted, not softened. The correct catalogue action is the opposite of the one proposed: id 16's existing attribution is right and should be *graded*, not replaced.** The deck still ships **unpinned**, because the collections carrying the full string are outside the tiered, re-fetchable set.

### Unresolved
- **Bar 4 and the format.** Beat 5 is a `story` beat carrying a **doctrinal** Qur'ānic quotation rather than narrative. `al-qadir@1` sets precedent for Qur'ān on story beats, but not for this kind. **A reviewer may reasonably want 39:42 moved to the verse slot — and the cost of that is bar 4**, since 2:255 would leave the deck. Stated in the deck (row 2.6) as a founder trade, not resolved.
- **The narration was verified through secondary Arabic scholarship**, not al-Nasāʾī or al-Ḥākim directly; the exact volume/page is not independently verified, and **no isnād was audited**.

---

## 2 · `al-waliyy@1` — REJECTED → made to pass, at the cost of bar 4

### What the verdict said
**Bar 1 is carried by a trailing epithet, which is what bar 1 forbids** — 42:28's demonstrated act is *sending rain* and `ٱلْوَلِىُّ ٱلْحَمِيدُ` is appended. **The defence-by-analogy to `al-afuw@1` is demonstrably false** (42:25 carries `وَيَعْفُوا۟` as a finite verb of Allah's action inside the demonstrating clause). And there is an **unmarked elision inside a quoted duʿā**, against an explicit ✅ saying nothing was dropped. The verifier recommended taking the deck's own clean-cut option.

### What changed
**The verse anchor is replaced; the story stays and its elision is fixed on the beat; the false analogy is deleted; the cut recommendation is withdrawn.**

- **New verse beat: Qur'ān 93:6** — *"Did He not find you an orphan and give [you] refuge?"* `فَـَٔاوَىٰ` is **a finite verb of Allah's own action inside the same clause as the person it is done to** — the construction the verifier itself identified as bar 1's strongest form. **And the object is the argument:** a `يَتِيم` is by definition a child left without the person who would have been in charge of him, and the catalogue's own gloss for id 64 is *"the helper and protector"* / *"You are never alone."* Taking in someone who has no one **is** wilāya, demonstrated as an act.
- **The elision is fixed by restoring the dropped clause**, not by papering it. Beat 4 now reads *"…the caretaker for the family, **O Allah, accompany us with Your protection, and return us in security**…"* and beat 5 opens *"…"*. **Both ellipses render.** Row 4.2's false ✅ is rewritten to state exactly what is and is not changed.
- **`al-afuw@1` analogy: deleted, recorded as an error, not repaired into a weaker version.**
- **Two verifier minors fixed:** row 4.1's paraphrase disclosure was attached to Muslim 1342's omissions when the beats quote Tirmidhī 3438 (whose own dropped detail is the finger gesture, `قَالَ بِأُصْبُعِهِ`); row 4.5's *"four shadda-ordering differences"* is **withdrawn** as unreproducible.
- **The ash-Shūrā crowding is gone**, because 42:28 is gone. That was one of R1's two stated costs and it is retired.

### The bar-4 trade, and the sweep that makes it legitimate
**`w-l-y` is in neither 93:6 nor the ḥadīth. Bar 4 is given up deliberately.** Plan §7 marks bar 4 as the only conditional bar; `al-haleem@1` set the precedent; and the trade is **forced**, which I proved by fetching every Qur'ānic occurrence of `walī`/`mawlā` predicated of Allah:

| shape | fetched | meets bar 1? |
|---|---|---|
| trailing / predicate epithet | 3:68 · 3:122 · 3:150 · 4:45 · 5:55 · 6:127 · 22:78 · **42:28** · 45:19 · 47:11 · 66:2 | no — the forbidden construction, and R1's anchor is in this list |
| negative ("no protector besides Him") | 2:107 · 13:11 · 32:4 · 33:17 | no |
| human speech | 7:196 (the Prophet ﷺ) · 12:101 (Yūsuf) · 10:62 (about human *awliyāʾ*) | no |
| **Name + act in one clause** | **2:257** · **42:9** | **these two, and only these two** |

**And both fail another bar.** **2:257** — the strongest Al-Waliyy āyah in the Qur'ān on bar 1 — ends *"Those are the companions of the Fire; they will abide eternally therein."* **inside its own āyah**, which is the exact ground `al-mujeeb@1` rejected 40:60 on **in this same batch**; it also carries `ٱلظُّلُمَـٰت`, on `al-mujeeb@1`'s beat 4. **42:9**'s act is *giving life to the dead* — not walāya, `al-qadir@1`'s subject, and ash-Shūrā again.

**So: there is no passage in the Qur'ān that satisfies bar 1 and bar 4 together for this Name.** One had to go, and bar 1 is the one that binds.

### Unresolved — one open collision, deliberately not closed unilaterally
**Shipped `as-samad@1` renders "The Eternal Refuge" (`name_intro`) and "O Allah, O Eternal Refuge" (duʿā). This deck's verse beat renders "give [you] refuge."** Same English word, two decks, one pack. It is weaker than the `al-muid@1` case (Name-gloss vs a verb in a quotation; Al-Waliyy is never glossed *refuge*) but it is a real bar-3-in-English finding.

**Abdel Haleem's 93:6 is *"Did He not find you an orphan and shelter you?"* — fetched, and it says neither "God" nor a lower-cased Name in this āyah, so the standing objection to Abdel Haleem does not bite here at all. Swapping it removes the word entirely.** I did not take it: the batch rule is Saheeh International throughout, the exception is *re-render only where the published English resolves a contested reading*, and **changing a batch-wide translation standard to dodge one word is a founder's call, not a drafter's.** One line either way.

**Also still live and unchanged:** the **register question** — the duʿā is literally a travel supplication and the ship gate byte-locks it. Under the all-99 rule, failing on this can no longer mean cutting the Name; it would mean a third revision that leaves the travel narration behind, at the cost of the deck's one §STEP-3 property-1 asset.

**One thing the founder should check personally:** R1 of `al-qayyum@1` was built on **93:1–3**, and this deck now anchors on **93:6**. `al-qayyum@1` R2 no longer touches Sūrat aḍ-Ḍuḥā at all, and the claims are different (*He has not taken leave of you* vs *He took you in when you had no one*) — but the founder should satisfy himself that a rejected sūrah has not simply been passed to a neighbouring Name. It is flagged in both decks.

---

## 3 · `al-mujeeb@1` — FIX-THEN-SIGN (blocking) → fixed

### What the verdict said
**Undisclosed on-screen English collision with shipped `ash-shafi@1`**, which already renders *"He stated the pain and named the Mercy. **He demanded nothing.**"* against this deck's *"He asked for nothing"* / *"There is nothing asked for in it."* — same sūrah, four āyāt apart. The deck's table marked it ✖ because it **compared takeaway to takeaway**; the collision was **beat to beat**. Plus a **false ✅ on row 1.3**, an unswept `q-d-r` root, and an over-stated engine claim against `as-samad@1`.

### What changed
- **Beat 4's authored tail is deleted outright.** The beat now ends on the quotation.
- **Beat 8 is rewritten off the axis entirely:** *"He was one man inside one fish. The āyah does not stop with him — its last words are about the believers."* Beat 5 gains *"The sentence does not stop at him."* Both stand on `وَكَذَٰلِكَ نُـۨجِى ٱلْمُؤْمِنِينَ` — **the clause 21:84 does not contain**, i.e. the one thing that is genuinely this deck's and not `ash-shafi@1`'s.
- **Row 1.3's ✅ is corrected to describe the check that actually ran.** Fetched 21:87 carries **three `<sup>` markers at offsets 74, 161 and 231; the quoted region opens at offset 261. All three are before the quote; zero are inside it, and the beat string is a byte-exact substring of the RAW, unstripped translation.** R1 claimed the substring held only after stripping, and that one marker sat inside after *"darknesses,"* — **both halves wrong**; *"within the darknesses,"* is the translation's own narration, outside the quotation.
- **`نَّقْدِرَ` swept and recorded in both decks.** Confirmed present in 21:87's `text_uthmani`: `q-d-r`, `al-qadir@1`'s Name root, negated, Allah as subject, inside this deck's own story āyah. Off-screen (the quoted region begins after it; story beats carry `arabic: ""`), English *"decree"* ≠ *"Able"/"Capable"*. Non-blocking.
- **The `as-samad@1` engine claim is withdrawn.** *"A call and its answer"* is **not** unique to this deck — `as-samad@1` ships *"a hidden call… a lifetime of asking"* → *"The answer came…"*. The deck now claims only the narrower and true thing: the āyah's move from a singular rescue (`نَجَّيْنَـٰهُ`) to a plural one (`نُـۨجِى ٱلْمُؤْمِنِينَ`), which 19:2–7 does not make.

### What I fetched
21:86 / **21:87** / **21:88** / 21:89 / **2:186** re-fetched with `<sup>` offsets computed; Tirmidhī 3505 was left as verified by both prior passes. English pass re-run: *"asked for nothing"* now returns **zero** hits on any beat anywhere; *"demanded nothing"* remains `ash-shafi@1`'s alone; the three new strings return zero hits outside this file.

### Unresolved
**The citation proximity itself is untouched and still a founder call:** `ash-shafi@1` at 21:83–84 and this deck at 21:87–88 remain four āyāt apart in one sūrah. **If the founder's rule is "one deck per Qur'ānic passage", this deck still fails it** — and under the all-99 rule that would now mean re-drafting Al-Mujīb elsewhere, which costs the pipeline's single strongest property (catalog id 37's duʿā **is** 21:87's closing clause, byte-verified).

---

## 4 · `al-muid@1` — FIX-THEN-SIGN (blocking) → fixed, with one collision escalated

### What the verdict said
Four things: **(a)** `name_intro` *"The Restorer"* collides in **English** with shipped `al-jabbar@1`'s *"Restorer of the Broken"*; **(b)** beat 3 silently drops `إِنَّا لِلَّهِ وَإِنَّا إِلَيْهِ رَاجِعُونَ` from the head of the taught duʿā **while calling the remainder "one sentence"**; **(c)** beat 8's *"she said it after saying it could not be true"* interprets a rhetorical question; **(d)** **bar 2 fails on the verifier's independent read** — 30:27 is eschatological re-creation, the story is spousal replacement via `kh-l-f`, and *"juxtaposition on a beat spine IS assertion"*. Plus **(e)** beat 1's *"almost nobody can say it and mean it"*, an unsourced claim about people aimed at a reader who is enduring.

### What changed
- **(b) — the elision is fixed on the beat.** Beat 3 now quotes **"We belong to Allah and to Him shall we return; O Allah, reward me for my affliction and give me something better than it in exchange for it…"** with a **visible trailing ellipsis** (the published quotation continues into the promise clause, which stays off screen by design). The framing no longer counts sentences: *"He taught what to say the moment something is taken:"*. Both the restored quotation and the promise clause it stops before were **substring-tested byte-exact** against the archived Muslim 918a page.
- **(c) — beat 8 rewritten:** *"She asked out loud who could be better than him — and then said the words anyway. The narration keeps both, in that order."* Row 5.7's ✅ is rewritten to admit that R1's version was an inference printed as a report, contradicted by its own ✅. **Also fixed for free:** beat 4 now renders *"she said:"*, matching `قُلْتُ` — R1 disclosed this drift in row 5.2 and then did not take its own fix.
- **(d) — the join is now explicit and bounded, on the beat.** The verifier's finding is accepted in full: a beat spine asserts by adjacency. **The verse beat's rendered `source` now reads `Qur'an 30:27 — the Name's own verb, spoken of creation itself`** (precedent: `al-baseer@1` and `al-hadi@1` both carry explanatory `source` lines that render). **Bar 2 is now claimed on 30:27 alone** — Allah's own act, His own verb, His own words — and **the story is explicitly not offered as a second demonstration of the same act**; it is offered as the ṣaḥīḥ narration in which the catalogue duʿā's request was taught.
- **(e) — the line is cut.** Beat 1 now reads *"Something was taken from you. There are words for that moment, and meaning them is a different thing from saying them."*
- **(a) — partially fixed, and escalated.** `name_intro` now renders **"The Restorer — the One who brings back what is finished"**: catalog id 68's `english` plus one authored clause compressed from catalog id 68's own `meaning`. **The ship gate permits this** — I read it: it byte-locks `dua` beats to the catalogue and requires only non-empty `arabic`/`transliteration` on `name_intro` — and **`al-wakeel@1` already ships the same device** (*"The Trustee — the Guardian you hand your affairs to"*).

### Why (a) is not fully closed
**Both colliding strings are the catalogue's own.** `collectible_names.json` id 9 `english` **is** *"The Compeller — Restorer of the Broken"*; id 68 `english` **is** *"The Restorer"*. A deck cannot remove the head-word without changing catalogue data or shipped rendered content. The gloss puts the *distinction* on the same screen (*something broke and was mended* vs *something ended*), but **the word "Restorer" is still the first noun on both.** Escalated in the deck as a **fifth catalogue flag — the first that is a collision rather than a defect** — with the two options named and no recommendation made.

### On the bar-2 alternative
The verifier noted that if the founder holds bar 2, the deck's own recommended replacement (Al-Muhyi, id 69) applies. **Under the all-99 rule that is no longer a route to dropping Al-Muʿīd**, so I ran the sweep that a compliant Al-Muʿīd deck needs: **every Qur'ānic IV-form `ʿ-w-d` with Allah as subject was fetched and the Arabic form confirmed — 10:4, 21:104, 27:64, 29:19, 30:11, 30:27, 85:13** (34:49 excluded: its subject is *falsehood*). **All seven are about re-origination of creation. None is about restoring a loss to a living person.** So an Al-Muʿīd deck must either take 30:27 and name the join — which is what this revision does — or give up bar 4 entirely. That finding is recorded in the deck.

---

## 5 · `al-qadir@1` — FIX-THEN-SIGN (light) → fixed

### What the verdict said
Four fixes, none structural: **(a)** beat 5's *"He was shown"* outruns 2:260, which stops at the instruction; **(b)** the deck drops `[Allāh] said`, so bar 1's *"in Allah's words"* never reaches the user; **(c)** bar 2 rests on Saheeh International's bracketed `[after slaughtering them]` and the caveat is buried in a table row; **(d)** 21:87 contains `نَّقْدِرَ`, unswept.

### What changed
- **(a)** Beat 5 now ends **"He was not corrected. He was given something to do, and told what would happen."** — reporting only the two things the āyah contains: an instruction (`فَخُذْ … ثُمَّ ٱجْعَلْ … ثُمَّ ٱدْعُهُنَّ`) and a stated outcome in the imperfect (`يَأْتِينَكَ`). Row 3.4 is rewritten to say plainly that *"He was shown"* was an inference printed as completed fact.
- **(b)** Beats 4 and 5 now render **"Allah said:"** in place of R1's *"The answer came back:"* and its dropped attribution. **The bar-1 property now reaches the reader.** The deck still declines to print the bracketed `[Allāh]` on a beat; the unbracketed name asserts nothing the bracket does not.
- **(c)** The `[after slaughtering them]` caveat is **moved into the bar-2 cell**, stated at full strength: *"dead" is not in the Arabic of 2:260*; `فَصُرْهُنَّ إِلَيْكَ` says only *incline them toward you*; Abdel Haleem's *"train them to come back"* would collapse the bar. **The founder is signing a bar that depends on a translator's bracket, and now reads that where the bar is.**
- **(d)** `نَّقْدِرَ` swept, confirmed present in 21:87's `text_uthmani`, recorded in **both** this deck and `al-mujeeb@1`. Non-blocking. The deck's R1 disclosure about `al-waliyy@1`'s 42:29 `قَدِيرٌ` is marked **void** rather than silently deleted, since `al-waliyy@1` no longer anchors on 42:28.

### What I fetched
2:259 / **2:260** / 2:261 and **75:40** re-fetched with `<sup>` offsets computed (2:260 carries exactly one marker, at offset 246, inside the *"Take four birds…"* region — R1's claim was exactly right; 75:40 carries none). 21:87's Arabic re-checked for `نَّقْدِرَ`. English pass run: *"four birds"*, *"He was not corrected"* and *"Allah said"* return zero hits outside this file.

### Unresolved
Nothing blocking. The verifier's non-blocking register note stands as R1 already disclosed it: **75:40's addressee is a denier of resurrection, not the reader** (75:31–35 is the rebuke). Worth the founder knowing; it contradicts no beat.

---

## 5b · The catalogue moved mid-pass — what I re-read, and what it changed

**A concurrent catalogue-repair track rewrote `collectible_names.json`'s `hadith` column while this pass was running.** I re-read the asset directly for all six relevant ids **after** being told, and did not work from the copy I read at the start. Nothing here was edited by me — that track is not mine and I made no write to any catalogue file.

| id | before | now | effect on the deck |
|---|---|---|---|
| **75 Al-Qādir** | unnumbered quotation attributed to the Prophet ﷺ, *(Muslim)* | **`hadith == ''`** | **Flag closes; deck unaffected.** It never cited the field. The card is now silent where it used to contradict, which is strictly better. |
| **16 Al-Qayyūm** | al-Ḥākim / Fāṭima, ungraded | **`hadith == ''`** (id 15 likewise) | **Deck unaffected — no beat, row or bar cited it.** But it supersedes the recommendation R2 was about to make (*"grade it, don't replace it"*), so that recommendation is withdrawn rather than restated. |
| **64 Al-Waliyy** | off-topic Bukhārī + a card gloss inside the quote + the "Al-Wali" spelling clash | **Bukhārī 6502 (ḥadīth qudsī of wilāya), numbered and graded; gloss now spells "Al-Waliyy"** | **Both flags close.** 6502 was then **fetched and evaluated as a possible anchor, and rejected** — see below. |
| 37 Al-Mujeeb · 68 Al-Muʿīd | — | **unchanged** | Both decks' flag sections still hold as written. |

**Two things to hand back to the catalogue track, as notes and not requests.**

1. **The id-16 deletion rests on one side of a contested grade.** The stated ground was *"the only candidate narration is ḥasan, which fails the ṣaḥīḥ-only standard."* **What I actually found by fetch, before that deletion happened: al-Ḥākim declared it ṣaḥīḥ and al-Mundhirī said its isnād is ṣaḥīḥ; Ibn Ḥajar and al-Albānī graded it ḥasan.** islamqa.info's own summary line opens *"was narrated in a **sahih** hadith from Anas ibn Malik."* Under a strict ṣaḥīḥ-only rule the deletion may well be right anyway — **but the grade was disputed, not uniform**, and if the standard is "ṣaḥīḥ per any recognised grader" rather than "ṣaḥīḥ per all", this one qualifies. Worth one look before it is treated as settled.
2. **Al-Qādir's withheld replacement is not needed here, and I decline it with a reason.** Bukhārī 6398's `وَأَنْتَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ` is understood to be verified and available. **`al-qadir@1` does not want it:** bar 4 is already met on the verse beat by 75:40's `بِقَـٰدِرٍ`, the deck's duʿā is an authored catalogue invocation with no citation claimed anywhere, and adding a third quotation of one duʿā to the Name's surface is the repetition this batch has been rejecting elsewhere. Recorded in the deck so the offer shows as declined, not overlooked.

### Bukhārī 6502 as a possible `al-waliyy@1` anchor — fetched, weighed, rejected

The suggestion was worth taking seriously: this deck was rejected on bar 1 for resting on a trailing epithet, and 6502 is a **ḥadīth qudsī** in which Allah speaks in the first person, **the acts are unambiguously His**, and **the root `w-l-y` is in the text**. On paper it solves bars 1 and 4 at once.

**Verified myself first.** Wayback `20220129035033`; Abū Hurayra; *Kitāb ar-Riqāq*; in-book Book 81 Hadith 91. Three English strings substring-tested **byte-exact**; Arabic `مَنْ عَادَى لِي وَلِيًّا فَقَدْ آذَنْتُهُ بِالْحَرْبِ` confirmed on the page.

**Rejected, on four grounds, in descending seriousness:**

1. **The `walī` in the text is the human, not Allah.** *"Whoever shows hostility to a walī of Mine"* — and the published English renders it *"a pious worshipper of Mine"*, so **the Name's word never reaches the screen in English at all.** Anchoring a deck about **Allah as Al-Waliyy** on a text whose only `w-l-y` names a *servant* teaches the wrong referent. **Bar 4 only appears to be met.**
2. **It puts the Name behind a condition, and the condition inverts the pack's premise.** The protection arrives *"till I love him"*, via nawāfil. **This is the hardship pack — its reader is enduring, not performing.** Telling someone at 1am that this protection is what you get after enough voluntary worship is a register failure.
3. **It carries the exact doctrinal-confusion risk that just sank `al-qayyum@1` R1.** *"I become his sense of hearing with which he hears…"* needs a gloss to be read correctly, and a reveal screen has none. **That is the verifier's "your Satan = Jibrīl" finding, one revision later, on a different deck.**
4. **Register and collision.** It opens *"I will declare war against him"*, includes *"his hand with which he grips"*, and renders `أُعِيذَنَّهُ` as *"his protection (**Refuge**)"* — which makes the `as-samad@1` *"The Eternal Refuge"* adjacency worse.

**93:6 stays. 6502 is a much better card citation than what it replaced and a worse deck anchor than 93:6** — and the deck now has a card that is *compatible but different*, which is a genuine improvement over R1's contradiction.

---

## 6 · Cross-batch: what this pass changes about the pipeline

1. **A drafter's recommendation to change catalogue data has now been wrong in both batches, in the same direction** — proposing to replace a correct, broader attribution with a narrower one (id 51 in batch 1; id 16 in batch 2). **Treat it as the pipeline's highest-risk artifact and never action one without independent re-verification.** Both times the correct action was the opposite of the one proposed.
2. **Three of the five ✅-marked claims that failed this round failed because the ✅ described a check that was not run as described** (`al-mujeeb@1` 1.3, `al-waliyy@1` 4.2, `al-muid@1` 5.7). The fix that generalises: **a ✅ must state the artifact of the check** — offsets, counts, the exact normalisation — not its conclusion.
3. **Bar 4 is the shock absorber.** Two of five decks in this batch now meet bar 1 by giving up the Name's root in the source text. That is legitimate under plan §7 **only with the sweep recorded**, and this pass records both sweeps in full. **Expect this to become the normal shape of a hard deck**, not the exception — see §7.
4. **The verifier's rule about elisions held up under load.** All three flagged elisions were fixable on the beat, and in two of the three the fix was simply *restore the dropped clause* rather than *add an ellipsis*. **Prefer restoration to marking.**

---

## 7 · Feasibility read — "all 99 Names, none skipped"

**Asked plainly, answered plainly. The decision is achievable, but it is not free, and three of the nine rejected Names cannot be made to work without a change outside the deck pipeline.** Everything below was re-derived or re-verified in this pass; where I disagree with the batch-2 packet I say so.

### 7.1 The structural blocker, and it is bigger than nine Names

**`collectible_names.json` has 14 duplicate `dua_arabic` groups covering 30 of the 99 Names.** Counted programmatically this pass:

`(47 Al-Hakam, 48 Al-Adl, 55 Al-Haseeb, 90 Al-Muqsit)` · `(19 Al-Mutakabbir, 22 Al-Qahhar)` · `(24 Al-Qabid, 25 Al-Basit)` · `(26 Al-Hakeem, 49 Al-Khabeer)` · `(29 Al-Haleem, 32 As-Sabur)` · `(43 Al-Muizz, 44 Al-Muzill)` · `(46 Al-Baseer, 60 Ash-Shaheed)` · `(50 Al-Azeem, 58 Al-Majeed)` · `(52 Al-Ali, 84 Al-Mutaali)` · `(62 Al-Qawiyy, 63 Al-Mateen)` · `(73 Al-Wahid, 74 Al-Ahad)` · `(77 Al-Muqaddim, 78 Al-Muakhkhir)` · `(79 Al-Awwal, 80 Al-Akhir)` · `(81 Az-Zahir, 82 Al-Batin)`

**Why this is fatal rather than awkward:** the ship gate asserts `dua` beats **byte-identical to the catalogue by `name_id`**. So two Names in one group produce **two decks with a pixel-identical duʿā screen — Arabic, transliteration and translation.** That is the pack's most memorable surface. **Under all-99, every one of these 30 Names gets a deck, so all 14 collisions become real.**

**A correction to the batch-2 packet, found this pass.** It reported ids **26 (Al-Hakeem)** and **49 (Al-Khabeer)** as byte-identical to **Al-Lateef (id 36, shipped)**. **They are not.** Verified: 26 and 49 are byte-identical **to each other** (`اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا`), and id 36's string is different (`يَا لَطِيفُ الْطُفْ بِي فِيمَا جَرَتْ بِهِ الْمَقَادِيرُ`). **The defect is different and arguably worse than reported:** their duʿā **invokes Al-Lateef by name in the vocative** — and `dua` beats are one of only two beat kinds that render Arabic, so `يَا لَطِيفُ` would appear on screen in a deck for a different Name.

**And note what the concurrent catalogue-repair track did and did not touch.** It repaired the **`hadith`** column (56 of 99 defective, per its own report). **It did not touch `dua_arabic`.** So every number in this section is current as of a re-read on 2026-08-03, **and the largest catalogue obstacle to all-99 is still entirely unaddressed.** The two tracks should not be assumed to have overlapped.

**That vocative problem is not confined to those two.** Scanned this pass:

| deck for | its duʿā puts this **other** Name in the user's mouth | that Name's status |
|---|---|---|
| 26 Al-Hakeem, 49 Al-Khabeer | `يَا لَطِيفُ` | **Al-Lateef (36) is shipped** |
| 60 Ash-Shaheed | `يَا بَصِيرُ` | **Al-Baseer (46) is shipped** |
| 19 Al-Mutakabbir, 22 Al-Qahhar | `يَا قَهَّارُ … وَيَا جَبَّارُ اجْبُرْ كَسْرِي` — which **contains Al-Jabbar's entire duʿā as a substring** | **Al-Jabbar (9) is shipped** |

**So: at least five Names cannot get a bar-3-clean deck while the catalogue stands, and the reason is the catalogue, not the scripture.**

**What all-99 therefore requires, and it is a decision the founder has not yet made:** a **duʿā de-duplication pass over `collectible_names.json`** — authoring or sourcing distinct invocations for one member of each duplicate group, and removing foreign-Name vocatives. **~30 Names, i.e. roughly a third of the catalogue.** It is out of the deck pipeline's scope, it must precede the affected decks, and until it happens those decks cannot be drafted honestly. **This is the single largest hidden dependency in the all-99 decision.**

### 7.2 The nine, re-read under the new rule

| Name | why it was dropped | can a deck be built? | what it would take |
|---|---|---|---|
| **As-Sabur (32)** | duʿā byte-identical to **Al-Haleem (29, batch 1)**; near-synonym; not a Qur'ānic divine Name | **Not until the catalogue moves.** | New duʿā for one of the two. **And a harder problem the packet did not name:** As-Ṣabūr's whole semantic content is Al-Ḥalīm's, and `al-haleem@1` already spent the pipeline's best forbearance material. A compliant deck needs a *distinct* attribute — plausibly *duration* (endurance over time) vs *restraint* — and a passage that shows duration. **Hard, but not impossible.** |
| **Ash-Shaheed (60)** | duʿā byte-identical to **Al-Baseer (46, shipped)**, and its duʿā says `يَا بَصِيرُ` | **Not until the catalogue moves.** | New duʿā. **The scripture side is easy** — `شَهِيد` is dense in-text with Allah as subject, and the distinguishing attribute (*witness*, i.e. testimony, not sight) is genuinely different from Al-Baṣīr's. **This is the cheapest of the nine once the duʿā is fixed.** |
| **Al-Khabeer (49)** | duʿā byte-identical to **Al-Hakeem (26)**, says `يَا لَطِيفُ`; card's `hadith` quotes al-Ghazālī about **Al-Lateef** | **Not until the catalogue moves.** | New duʿā + a `hadith`-field fix. **Then the deck is buildable:** `خَبِير` is about *inner knowledge of what is hidden in a matter*, which is distinguishable from Al-Laṭīf's *subtlety of action*. |
| **Al-Hakeem (26)** | same duʿā as 49; and its natural story (Mūsā and al-Khiḍr) **has `al-lateef@1`'s exact insight already on screen** | **Yes, but the story must change.** | New duʿā, **and give up Mūsā/al-Khiḍr.** That is the real cost: it is the obvious Al-Ḥakīm story and it is spent. An alternative would have to demonstrate *wisdom as an act* without landing on *"visible only from the far side"*. **Hard.** |
| **Al-Qawiyy (62)** | live candidates sit in battle/punishment passages; 22:40 is the permission-to-fight āyah, 33:25 is clean but 33:26 is *"a party you killed"*; shares a duʿā with Al-Mateen | **Yes, with an explicit editorial decision from the founder.** | **This is the Name that forces a policy question rather than a research task.** `qawiyy` is a Name of *strength*, and the Qur'ān predominantly demonstrates strength in contexts of conflict and seizure. Options: (i) **the founder rules that a battle-context anchor is permissible for the strength Names** with the arc terminating before the casualty clause, which relaxes nothing in bar 5 only if the excerpt genuinely ends clean — 33:25/33:26 shows it usually does not; (ii) find a **non-conflict** demonstration of `q-w-y` (candidate not yet swept: 11:66, 40:22, 42:19, 57:25 — **none of these has been fetched and I am not asserting they work**); (iii) accept a bar-4 trade like `al-waliyy@1`'s and anchor on an act of strength that does not carry the root. **My read: (iii) is the most likely route, and it needs a fresh sweep.** |
| **Al-Mateen (63)** | its **only** in-text occurrence, 51:58, reads *"the [continual] **Provider**, the firm possessor of strength"* — it would print **Ar-Razzāq**, a shipped deck's Name, in its own verse beat; shares a duʿā with Al-Qawiyy | **Only via a bar-4 trade.** | **This one is structurally identical to `al-waliyy@1` and the same remedy applies:** if the sole root-bearing āyah cannot clear bar 3, **give up bar 4 and anchor on an act**, recording the sweep. Also needs the duʿā split from 62. **Buildable, and `al-waliyy@1` R2 is the template.** |
| **Ash-Shakur (28)** | **every** in-text occurrence pairs the Name with a batch-1 Name in the same clause — `غَفُورٌ شَكُورٌ` (35:30, 35:34, 42:23), `شَكُورٌ حَلِيمٌ` (64:17); 2:158's successor is *"cursed by Allāh"*; only 4:147 survives and it reads *"What would Allāh do with your punishment…"*; and its best story (Bukhārī 652, the thorny branch) puts `gh-f-r` on screen | **Yes — via a bar-4 trade, and it is the clearest case for one.** | **This is the strongest evidence in the whole sweep that bar 4 has to be the shock absorber.** Ash-Shakūr is a Name the Qur'ān *never* states alone. **A compliant deck must give up the root** and anchor on an act of Allah **appreciating a small thing** — e.g. the disproportion between a deed and its reward — with the sweep recorded, exactly as `al-haleem@1` and now `al-waliyy@1` do. **Buildable. Needs a fresh candidate hunt, not a catalogue change.** |
| **Al-Hafeez (39)** | best story (Mūsā's mother, 28:7–13) is **`al-jabbar@1`'s arc** — a parent's lost child returned; remaining anchors 11:57 (ʿĀd's destruction follows) and 12:64 (a third deck in Sūrat Yūsuf); root absent from 28:7–13 | **Yes, and this is the most fixable of the nine.** | The blocker is an **insight collision, not a source problem.** Mūsā's mother is not the only preservation story; and the `ḥ-f-ẓ` root has live in-text candidates that were never swept because the story was chosen first (**15:9, 12:12, 21:32, 86:4** — **not fetched, not asserted**). **Route: pick the anchor first, then find a story that does not end in a reunion.** |
| **Ad-Darr (95)** | **not attempted, on reverence grounds.** Not an independently attested Qur'ānic divine Name; duʿā is authored; a deck teaching *"Allah sends the difficulty"* to a user at 1am is the irreverence failure §8.2 warns about | ⚠️ **This is the one I would not promise, and I think the founder should decide it before batch 3, not during it.** | **The reverence objection is not a research gap that more fetching closes.** Two honest routes exist, and both are decisions rather than tasks. **(i) Pair it, never solo it.** The classical treatment is that Aḍ-Ḍārr is only ever named with An-Nāfiʿ (96), because the attribute is *"benefit and harm are both from one hand, and neither is from anyone else"*. A deck that teaches the **pair** and never Aḍ-Ḍārr alone is theologically standard and register-survivable. **The format supports it — the pair-synergy beat already exists** and the ship gate has a dedicated assertion for it. **(ii) Anchor on the human confession, not the divine act** — the register-safe content is that the user is *not* at the mercy of causes, which is the Name's comfort rather than its threat. **What I will not claim: that a deck can be written that shows Allah harming a person and survives the founder review checklist's reverence line.** If the founder wants Aḍ-Ḍārr solo, the honest answer is that the pipeline does not currently have a route to it, and the decision needs him and not a drafter. **Also note: its duʿā is authored, so it has no property-1 asset and no narration warrant to lean on.** |

### 7.3 The honest summary

**Achievable.** Six of the nine are buildable: two need only a catalogue duʿā fix (60, 49), two need a duʿā fix plus a new story (32, 26), two need a bar-4 trade with a recorded sweep (63, 28) — and one, 39, needs only a change of method (anchor first, story second). **Al-Qawiyy (62) needs a founder ruling on battle-context anchors, or a bar-4 trade.**

**Three things stand between the decision and its execution, and none of them is drafting effort:**

1. **The duʿā de-duplication pass — ~30 Names, a third of the catalogue.** Nothing in the affected groups can be drafted honestly until it happens. **This is the critical path and it is not currently on any plan.**
2. **A founder ruling on Aḍ-Ḍārr.** It is a reverence decision, not a sourcing problem, and the pipeline has no route to a solo deck. My recommendation is the **pair-with-An-Nāfiʿ** route, but that is his call and it should be made once, in advance, rather than re-litigated at draft time.
3. **An explicit blessing for bar-4 trades.** Two decks in this batch already meet bar 1 by giving up the Name's root, and **Ash-Shakūr, Al-Mateen and probably Al-Qawiyy cannot be built any other way.** Plan §7 permits it "with the sweep recorded"; **at all-99 scale that stops being an exception and becomes a normal outcome**, and the founder should know he is signing decks whose verse beat does not print the Name's own word — perhaps a dozen of them.

**The thing I would not reassure him about:** the batch-2 packet framed the nine as *"expensive findings batch 3 does not have to re-derive."* **Half of them were rejected on grounds that a redraft cannot touch** — a shared duʿā string, a shipped deck's Name inside the duʿā, a spent story. Those are catalogue and inventory problems, and they compound: **every deck that ships spends a story, an insight and a passage, so the last twenty Names will be materially harder than the first twenty, and the constraint that bites will be collision, not authenticity.** Batch 2 already found zero authenticity failures and five reasoning/collision/disclosure failures. **That ratio is the forecast.**

---

## 8 · What I could not resolve

1. **`al-waliyy@1`'s "refuge" adjacency with shipped `as-samad@1`.** Real, disclosed, and left open because closing it means breaking the batch's Saheeh-International-throughout rule for one beat. **Fetched Abdel Haleem alternative is ready. One line, founder's call.**
2. **`al-muid@1`'s "Restorer" collision.** Mitigated on screen with an authored gloss; **not removed**, because both colliding strings are catalogue `english` fields and `al-jabbar@1` already ships. **Needs a catalogue edit or a pack-adjacency rule.**
3. **`al-mujeeb@1`'s citation proximity to `ash-shafi@1`** (four āyāt, one sūrah). The English collision is fixed; the shared-passage question is a policy call I cannot make.
4. **`al-qayyum@1`'s format stretch** — a doctrinal Qur'ānic quotation on a `story` beat. Disclosed with its cost (moving it to the verse slot costs bar 4).
5. **`al-waliyy@1`'s register question** (a travel duʿā read at 1am) — unchanged from R1, still live, and now with no cut option behind it.
6. **Verification limits that carry over unchanged:** ḥadīth checking is still not independent of sunnah.com as a corpus (Wayback captures of the same digitisation, same Darussalam grade lines); **no isnād was audited anywhere**; the id-16 narration is attested by secondary Arabic scholarship, not a primary collection reached directly; Arabic "skeleton identical" means *same letters, not same diacritics*; **I did not run the ship gate** and did not transcribe anything.
