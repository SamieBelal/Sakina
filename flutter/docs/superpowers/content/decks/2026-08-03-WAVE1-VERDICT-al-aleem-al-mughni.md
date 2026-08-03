# Blind adversarial verdict — `al-aleem@1` (id 14) and `al-mughni@1` (id 93)

**Verifier:** independent agent, 2026-08-03. Instructed to **refute**, not approve; to default to reject where independent confirmation is unavailable; and to treat every ✅ in the drafters' Sources tables as an unverified assertion by an interested party.

**Everything below was re-fetched.** No claim was carried over from either draft. Qurʾān via `api.quran.com/api/v4/verses/by_key/{k}?fields=text_uthmani,text_imlaei&translations=20`. Ḥadīth via Wayback **CDX** lookups of the exact bare `sunnah.com` number, fetched at `…id_/` and decoded. Root enumeration run over a full independent Qurʾān text (`api.alquran.cloud/v1/quran/quran-simple`, 6236 āyāt), not over either draft's list.

---

## VERDICTS

| deck | verdict |
|---|---|
| **`al-aleem@1`** | **FIX-THEN-SIGN** — 3 blocking fixes, all one-line. Scripture, grading, narrator and the two-route duʿā finding all independently confirmed. |
| **`al-mughni@1`** | **FIX-THEN-SIGN** — 2 blocking fixes (one of them close to a reject) and 5 record-level corrections. Scripture, narrator and the withdrawn weeping detail all independently confirmed. |

Neither deck contains a fabricated, misnumbered, misattributed or misgraded citation. **Every failure below is reasoning, elision, disclosure or record — which is where §7 said the remaining risk now lives, and it was right.**

---

# PART 1 — `al-aleem@1`

## 1.1 The load-bearing grammatical claim — **CONFIRMED**

The whole deck rests on 3:36's `وَٱللَّهُ أَعْلَمُ بِمَا وَضَعَتْ` being third-person (Allah's own comment) rather than `وَضَعْتُ` (a continuation of her speech). **Fetched `text_uthmani` for 3:36:**

```
فَلَمَّا وَضَعَتْهَا قَالَتْ رَبِّ إِنِّى وَضَعْتُهَآ أُنثَىٰ وَٱللَّهُ أَعْلَمُ بِمَا وَضَعَتْ وَلَيْسَ ٱلذَّكَرُ كَٱلْأُنثَىٰ ۖ ...
```

The contrast is visible **inside one āyah**: her speech is `إِنِّى وَضَعْتُهَآ` (1st-person, `تُ`), the divine clause is `بِمَا وَضَعَتْ` (3rd-person fem., `تْ`). This is the Ḥafṣ text as served. `text_imlaei` agrees. **Bar 1 stands. The deck is not a reject on this ground.**

## 1.2 The duʿā two-route finding — **CONFIRMED IN FULL, and the "no catalogue change" recommendation is CORRECT**

Both routes fetched independently.

| route | capture fetched | opening as printed | grade as printed |
|---|---|---|---|
| Jāmiʿ at-Tirmidhī 3392 | `web.archive.org/web/20260124120456id_/https://sunnah.com/tirmidhi:3392` | `قُلِ اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالأَرْضِ رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ…` | `قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ` — **ḥasan ṣaḥīḥ**, on the page |
| Sunan Abī Dāwūd 5067 | `web.archive.org/web/20250515164929id_/https://sunnah.com/abudawud:5067` | `قُلِ اللَّهُمَّ فَاطِرَ السَّمَوَاتِ وَالأَرْضِ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ…` — **clauses reversed** | `Grade: Sahih (Al-Albani) / صحيح (الألباني)`, on the page |

Both carry the same companion chain (Yaʿlā b. ʿAṭāʾ ← ʿAmr b. ʿĀṣim ← Abū Hurayra ← Abū Bakr's request).

**Diacritic-folded token diff, catalogue id 14 vs Tirmidhī 3392, computed here:**

```
catalogue: ['اللهم','عالم','الغيب','والشهادة','فاطر','السماوات','والارض']   (7 tokens)
tirmidhi : ['اللهم','عالم','الغيب','والشهادة','فاطر','السموات','والارض']    (7 tokens)
diff     : index 5 only — السماوات vs السموات
```

**Exactly one token differs, and it is the plene/defective spelling of the same word.** The drafter's claim is exact. A drafter who had fetched only Abū Dāwūd 5067 would indeed have reported the catalogue's clauses as "backwards" and recommended reordering id 14 — and would have been wrong. **I independently endorse: NO change to `collectible_names.json` id 14.**

Also independently checked and clean: id 14's `dua_translation` ("O Allah, Knower of the unseen and the seen, Originator of the heavens and the earth.") contains **no content absent from its Arabic** — i.e. it does not carry the ledger §9m defect. Beat 7's Arabic / transliteration / translation are byte-identical to the catalogue.

## 1.3 The proposed pin `"Jami' at-Tirmidhi 3392 (opening words)"` — **acceptable, with one imprecision worth a founder's eye**

The catalogue text is the **opening of the supplication**, not the opening of the narration. Tirmidhī 3392 opens with the isnād and then Abū Bakr's request (`يَا رَسُولَ اللَّهِ مُرْنِي بِشَيْءٍ أَقُولُهُ إِذَا أَصْبَحْتُ`); the supplication itself begins at `قُلِ اللَّهُمَّ عَالِمَ الْغَيْبِ…`. The catalogue drops the imperative `قُلِ` and takes the next seven words verbatim.

So `(opening words)` is true of the **duʿā**, not of the **ḥadīth**. Every reader will read it the intended way and I am not treating it as blocking, but if the founder wants it airtight the honest string is `Jami' at-Tirmidhi 3392 (opening of the supplication)`. **Not a blocker.**

## 1.4 Byte-exact substring tests — **ALL PASS**

Re-run programmatically against the fetched `translations[0].text` (Saheeh International, resource 20), after the disclosed `Allāh → Allah` substitution:

| beat | fragment | result |
|---|---|---|
| 3 | `My Lord, indeed I have pledged to You what is in my womb, consecrated [for Your service], so accept this from me` | **PASS** |
| 4 | `"My Lord, I have delivered a female."` | **PASS** |
| 4 | `And Allāh was most knowing of what she delivered` | **PASS** |
| 5 | `So her Lord accepted her with good acceptance and caused her to grow in a good manner` | **PASS** |
| 6 | `And with Him are the keys of the unseen; none knows them except Him` | **PASS** |
| 6 | `Not a leaf falls but that He knows it` | **PASS** |

**Zero `<sup>` footnote markers** in 3:35, 3:36, 3:37 or 6:59 as served — so no marker falls inside a quoted region. (6:60 and 4:129 *do* carry markers, but neither is quoted.)

## 1.5 Successor sweep — re-run independently, **clean on bar 5**

- **3:34** (n−1 of the story): ends `وَٱللَّهُ سَمِيعٌ عَلِيمٌ` — this Name as a trailing epithet paired with As-Sami. On no screen; the draft's reason for not using it is correct.
- **3:35 tail:** `إِنَّكَ أَنتَ ٱلسَّمِيعُ ٱلْعَلِيمُ`. Cut, with visible `…`. Correct call: it is human speech about Allah (the already-rejected 7:196/12:101/10:62 class) *and* would render As-Sami's gloss.
- **3:36 tail:** `وَلَيْسَ ٱلذَّكَرُ كَٱلْأُنثَىٰ` then the naming and the refuge. Cut with visible `…`. **Confirmed contested; refusing to adjudicate it by translation choice is the right application of the `al-kareem@1` rule.**
- **3:37 tail:** Zakariyyā + `إِنَّ ٱللَّهَ يَرْزُقُ مَن يَشَآءُ بِغَيْرِ حِسَابٍ`. Confirmed — quoting it would put `as-samad@1`'s protagonist and `ar-razzaq@1`'s exact territory on an Al-Aleem screen. Cut is right.
- **3:38** (n+1): Zakariyyā's supplication. **No punishment.** Bar 5 clean.
- **6:58** (n−1): `وَٱللَّهُ أَعْلَمُ بِٱلظَّـٰلِمِينَ` — same root, judicial register, on no screen. Confirmed.
- **6:60** (n+1): souls taken by night, then the return and the informing. **No punishment clause.** Bar 5 clean. **And the drafter is right that this is `al-qayyum@1`'s story material one āyah out** — shipped `al-qayyum@1` runs the same taking-of-souls-in-sleep material from 39:42. Off-screen, correctly disclosed.

## 1.6 Bar 3 — Arabic roots and **rendered English**, run by me

`ʿ-l-m` reaches the screen three times (3:36 `أَعْلَمُ` in a story beat — Arabic, so it does **not** render; 6:59 ×3 — the verse beat carries `arabic: ""`, so also does not render; the duʿā's `عَالِمَ` **does** render, in Arabic and in English). Bar 4 is satisfied without a trade.

**English pass, run against all 24 shipped decks' `primary`/`label`/`translation`/`source` strings and all 33 draft files:**

- *"You already decided what it added up to"*, *"I have delivered a female"*, *"most knowing of what she delivered"*, *"accepted her with good acceptance"*, *"grow in a good manner"*, *"keys of the unseen"*, *"Not a leaf falls but that He knows it"*, *"in the middle of her sentence"*, *"before anything had proved it"* — **zero hits outside this file.** Confirmed.
- `delivered` · `womb` · `Maryam` · `Mary` · `female` · `leaf` · `grain` · `clear record` — **zero hits in all 24 shipped decks.** Confirmed. (Non-blocking draft-level hits exist: `womb` in al-khaliq/al-wasi/ar-raqeeb, `Maryam`/`Mary` in the rizq pair, al-haqq and al-khaliq. None is a beat-level string collision.)

### The `al-lateef@1` question — **the deck genuinely escapes it, and this is not a rename**

Verified against the shipped asset. `al-lateef@1` beat 8 is exactly:

> `"Whether you speak secretly or openly — He surely knows best what is hidden in the heart." (Qur'an 67:13) What you couldn't say was never unsaid to Him.`

That is *known without words*. Al-Aleem's woman **says it out loud** and the knowing **contradicts her report**. Applying ledger §9o's own test — *could a user read both screens and think they had been told the same thing twice?* — no: one screen says your silence was heard, the other says your assessment was wrong. Different claim, opposite mechanism, and the catalogue's `lesson` line for id 14 (which *is* `al-lateef@1`'s insight in a different noun) is deliberately not used. **Bar 3 passes on the deck's biggest hazard.** The English strings differ too (`knows best` vs `most knowing`, Saheeh's own words for 3:36).

### Confirmed adjacencies, non-blocking

- `al-baseer@1`'s shipped duʿā beat renders *"Bear witness for me in what only You know"* + `لَا يَعْلَمُهُ سِوَاكَ` — **verified in the asset.** This Name's root, in English, on a different card's screen. Catalogue text; unfixable inside this deck; correctly disclosed.
- `as-samad@1`'s protagonist at 3:38, `ar-razzaq@1`'s root in 3:37's unquoted tail, `al-qayyum@1`'s material at 6:60 — all verified, all off-screen, all disclosed.

## 1.7 ⚠️ BLOCKING FIX 1 — beat 6 truncates a quotation with **no visible ellipsis** and adds a closing quotation mark the source does not have

Beat 6 renders:

> `"And with Him are the keys of the unseen; none knows them except Him… Not a leaf falls but that He knows it." — Qur'an 6:59`

The **interior** cut is marked. The **terminal** cut is not: 6:59 continues for a further substantial clause — *"And no grain is there within the darknesses of the earth and no moist or dry [thing] but that it is [written] in a clear record."* The beat closes on a period and a quotation mark that are **the deck's, not the source's** — the draft admits both in its own table but does not carry either onto the beat.

Plan §7's batch-2 rule is explicit and was earned on exactly this: *"A partial quotation carries a visible ellipsis ON THE BEAT… If the beat does not show the elision, the beat is claiming a completeness it does not have. A disclosure in a verification table is not a disclosure: the user never sees the table."*

**Fix (one line):** `…Not a leaf falls but that He knows it…"` — or restore the tail. **This is a rule violation, not a judgement call.**

## 1.8 ⚠️ BLOCKING FIX 2 — the deck's central structural claim is asserted in prose and shown on no screen

Beat 4 asserts *"The ayah answers inside her own sentence"*; beat 8 repeats it — *"the ayah says so in the middle of her sentence"*. That is the deck's entire bar-2 argument ("shown by structure, not by adjective").

**But the structure is never on screen.** The evidence for interruption is that her speech *resumes* after the divine clause (`وَإِنِّى سَمَّيْتُهَا مَرْيَمَ` / *"And I have named her Mary…"*). Beat 5 **paraphrases that away** — *"She named the girl Maryam and asked Allah to protect her"* — for a stated and good reason (avoiding *"Satan, the expelled"* on a night surface). The consequence is that a reader sees: she said X → deck prose claiming an interruption → the divine clause. They see two adjacent quotations and one authorial assertion. In Saheeh's own rendering the divine clause sits **between two closed quotations**, which is precisely what the beat says it is not.

Bar 2 requires the quality be **shown**. Here it is stated by the deck and the demonstration is removed.

**Fix (one line):** open beat 5 with the resumption as a quotation with a visible ellipsis — `Her sentence resumes: "And I have named her Mary…"` — which restores the structure to the screen and *still* stops before the refuge clause. Alternative fix: soften beats 4 and 8 to claim only what the screens show (*the answer arrives before her report is accepted*). **Do one or the other; do not ship the claim without the evidence.**

## 1.9 ⚠️ BLOCKING FIX 3 (record-level) — a false "verified negative", and a sibling sweep that covered 4 of 10 live claims

The draft states:

> **Verified negative, run programmatically: 3:35, 3:36, 3:37 and 6:59 appear in no shipped deck, no DRAFT file and no sibling claim.**

**This is false as written.** My run: `3:35` appears in `2026-08-03-al-khaliq-DRAFT.md`, `2026-08-03-al-malik-DRAFT.md`, `2026-08-03-al-mughni-DRAFT.md` and `.context/claims/10.md`; `3:37` appears in `2026-07-25-rizq-pair-DRAFT.md`; `6:59` appears in `2026-08-03-al-mughni-DRAFT.md`. Every one of those is a *reference to this deck's own claim* or a runner-up note, so **nothing material is wrong** — but the sentence the founder signs against is not true, and this is the same class of false ✅ that §6 records twice already.

Relatedly: the draft's sibling row lists **four** claims live this wave (ids 4, 7, 14, 40). **`.context/claims/` contains ten** — 4, 7, 10, 14, 17, 40, 57, 61, 93, 98. The bar-3 sweep against concurrent work therefore covered under half the field. (On Al-Aleem this turns out to be harmless; on Al-Mughni it was not — see §2.7.)

**Fix:** restate as *"appear on no beat of any shipped deck or draft"*, and either widen the sibling row to all ten claims or say plainly which subset was swept.

## 1.10 Non-blocking corrections to the packet

1. **The `ar-raqeeb@1` disclosure is stale and overstates a collision that is already closed.** The draft says id 40 *"quotes Bukhārī 555's `وَهْوَ أَعْلَمُ بِهِمْ` on one beat (*'though He knows them best'*)"*. The `ar-raqeeb@1` draft as it stands does the opposite: it explicitly **rejects** *"though He knows them best"* on the `al-lateef@1` collision and renders **Muslim 632a's published *"though He is the best informed about them"*** instead. Al-Aleem's flag errs toward over-disclosure; correct it rather than act on it.
2. `الشَّهَادَة` in the duʿā is the witnessed world, not Ash-Shaheed's agent noun. **Agreed, non-collision.** Ash-Shaheed (60) is independently blocked per ledger §6e.
3. Card corroboration **Bukhārī 4697** verified at `…/20260314173812id_/…/bukhari:4697`: narrator **Ibn ʿUmar**; Arabic `مَفَاتِيحُ الْغَيْبِ خَمْسٌ لاَ يَعْلَمُهَا إِلاَّ اللَّهُ…`; chapter heading is indeed **13:8** *"Allah knows what every female bears…"*. The catalogue's id 14 `hadith` field cites 4697 and quotes it accurately. Correct as printed.
4. `name_intro` beat verified byte-identical to catalogue id 14 (`الْعَلِيمُ` / `Al-Aleem` / `The All-Knowing`).

## 1.11 The five bars, judged by me

| bar | verdict |
|---|---|
| **1 — demonstrated in Allah's words, not a trailing epithet** | **PASS, asked strictly.** `وَٱللَّهُ أَعْلَمُ بِمَا وَضَعَتْ` is a finite clause of Qurʾānic narration in Allah's voice, not an epithet, and it *does* something — the next āyah is the acceptance. 6:59 reinforces with three finite verbs. Independently verified on `text_uthmani`. |
| **2 — shown, not stated** | **FAIL as written → PASS after fix 1.8.** The distinguishing quality is real but its demonstration is paraphrased off-screen while the deck's prose asserts it. |
| **3 — does not collapse into a sibling** | **PASS.** `al-lateef@1` escaped by construction, verified against the asset. `al-baseer@1` and `ar-raqeeb@1` adjacencies are real, off this deck's beats, and disclosed. |
| **4 — Name's root in the source text** | **PASS, untraded.** Confirmed in 3:36, 6:59 ×3 and the duʿā (the last renders on screen in both scripts). |
| **5 — register / successor sweep** | **PASS.** 3:38 and 6:60 both independently fetched; neither is punishment, battle or curse. No beat attributes waiting, wanting or withholding. Beat 8 makes no promise. |

---

# PART 2 — `al-mughni@1`

## 2.1 Ṣaḥīḥ al-Bukhārī 4330 — **narrator, triple and wording ALL CONFIRMED**

Fetched at `web.archive.org/web/20260417125412id_/https://sunnah.com/bukhari:4330` (my own CDX pick, not the draft's capture).

- **Narrator: `عَنْ عَبْدِ اللَّهِ بْنِ زَيْدِ بْنِ عَاصِمٍ` — ʿAbdullāh b. Zayd b. ʿĀṣim.** The drafter's self-correction is **right**; the claim file's original "Anas" was wrong. (Anas is the narrator of 3778, 4331 and 4337 — a natural confusion, and the correction is the right one.)
- **The triple is on the page, verbatim as the draft renders its Arabic:**
  `يَا مَعْشَرَ الأَنْصَارِ أَلَمْ أَجِدْكُمْ ضُلاَّلاً فَهَدَاكُمُ اللَّهُ بِي، وَكُنْتُمْ مُتَفَرِّقِينَ فَأَلَّفَكُمُ اللَّهُ بِي وَعَالَةً، فَأَغْنَاكُمُ اللَّهُ بِي`
  astray→guided · divided→united · poor→`أَغْنَاكُمُ`. **Order matches 4330 and is not mixed with Muslim 1061** (which orders it astray→guided, poor→enriched, divided→united). Route discipline is clean.
- Opening `لَمَّا أَفَاءَ اللَّهُ عَلَى رَسُولِهِ ﷺ يَوْمَ حُنَيْنٍ قَسَمَ فِي النَّاسِ فِي الْمُؤَلَّفَةِ قُلُوبُهُمْ، وَلَمْ يُعْطِ الأَنْصَارَ شَيْئًا` ✅, `فَكَأَنَّهُمْ وَجَدُوا إِذْ لَمْ يُصِبْهُمْ مَا أَصَابَ النَّاسَ` ✅, `كُلَّمَا قَالَ شَيْئًا قَالُوا اللَّهُ وَرَسُولُهُ أَمَنُّ` ✅, `أَتَرْضَوْنَ أَنْ يَذْهَبَ النَّاسُ بِالشَّاةِ وَالْبَعِيرِ، وَتَذْهَبُونَ بِالنَّبِيِّ ﷺ إِلَى رِحَالِكُمْ` ✅ — every Arabic string quoted in the Sources table is on the page, unaltered.
- The re-render corrections are all defensible: `فَكَأَنَّهُمْ وَجَدُوا` really does not carry the published English's *"felt angry and sad"*; `بِالشَّاةِ وَالْبَعِيرِ` really is generic singular where Muhsin Khan pluralises; `أَمَنُّ` really is the comparative of `مَنّ`. **Bar-1-adjacent translation work is honest here.**

## 2.2 The withdrawn weeping — **THE WITHDRAWAL WAS CORRECT**

I tried to find it, as instructed.

| page | fetched | *"wept until their beards were wet"* present? |
|---|---|---|
| Bukhārī 4330 | `…/20260417125412id_/…` | **No.** Ends `فَاصْبِرُوا حَتَّى تَلْقَوْنِي عَلَى الْحَوْضِ`. |
| Bukhārī 3778 | `…/20231202143624id_/…` | **No.** (Anas; *"our swords are still dribbling with the blood of Quraysh"* — confirms the register rejection.) |
| Bukhārī 4337 | `…/20251006165008id_/…` | **No.** (Anas; narrates the rout and the flight — confirms the register rejection.) |
| Bukhārī 4331 | `…/20250321144244id_/…` (fetched on my own initiative) | **No.** Ends `فَلَمْ يَصْبِرُوا`. |
| **Ṣaḥīḥ Muslim 1061** | `…/20260317061533id_/…` (fetched on my own initiative — this is 4330's Muslim parallel, same narrator) | **No.** |

**The detail is absent from all three pages the drafter checked, and from two more I checked that it did not.** Withdrawing it was right and no beat mentions it.

One correction to the record: the claim file says the weeping *"belongs to a Muslim narration this pass did not fetch."* I fetched the obvious candidate (Muslim 1061, same isnād spine, same event) and it is **not there either**. So the *attribution* is an unverified guess. Immaterial — no beat claims it — but it should not sit in a claim file as though established. **Say "not located in any route fetched" rather than naming a collection.**

## 2.3 Ṣaḥīḥ al-Bukhārī 6446 (card corroboration) — **CONFIRMED**

`…/20231004193620id_/…/bukhari:6446`. Narrator **Abū Hurayra**. Arabic `لَيْسَ الْغِنَى عَنْ كَثْرَةِ الْعَرَضِ، وَلَكِنَّ الْغِنَى غِنَى النَّفْسِ`. Chapter `باب الْغِنَى غِنَى النَّفْسِ`. Catalogue id 93's `hadith` cites this number and paraphrases it faithfully. **Card correct, no change needed.** Correctly kept off every beat.

## 2.4 ⚠️ BLOCKING FIX 1 — beat 6 drops `[by divorce]` and the beat is **not** honest about the referent. The `al-kareem@1` rule is misapplied.

Fetched 4:130:

```
UTHMANI: وَإِن يَتَفَرَّقَا يُغْنِ ٱللَّهُ كُلًّا مِّن سَعَتِهِۦ ۚ وَكَانَ ٱللَّهُ وَٰسِعًا حَكِيمًا
SAHEEH : But if they separate [by divorce], Allāh will enrich each [of them] from His abundance. And ever is Allāh Encompassing and Wise.
```
Substring test: Saheeh's string **PASSES** byte-exact. The deck's re-render **FAILS** (it is a re-render, as disclosed).

**The re-render is lexically defensible** — `يَتَفَرَّقَا` is a dual verb and *"if the two of them part"* is what it says. **The problem is not accuracy, it is referent.** The dual's antecedent is the husband and wife of 4:128–129; 4:129 is verifiably about a man leaving a wife `كَٱلْمُعَلَّقَةِ` — *hanging*. Saheeh brackets `[by divorce]` because in isolated English *"if they separate"* has no antecedent at all.

Beat 6 renders in isolation, with **nothing** on any beat indicating a marriage — and it is preceded by three beats about a group of people watching a distribution go to others. A user meets *"if the two of them part"* immediately after *"they went home without a sheep or a camel"* and will read it generically. **The beat is not honest about its referent, and it is bar 1's only load-bearing text.**

The draft's stated reason — *"pasting a translator's interpolation onto a beat is the `al-kareem@1` finding"* — **misapplies the rule it cites.** The `al-kareem@1` finding (plan §6 rule 2) is about a published English **adjudicating a contested theological attribute** while pretending to adjudicate nothing (`تَعَالَى` → "the Superior"; an interpolated *"to us"* flattening non-spatiality). `[by divorce]` adjudicates **nothing contested by anyone**; it discloses an uncontested grammatical antecedent. Removing it does the *opposite* of what the rule intends: it **removes** information and lets the beat float free of the passage it comes from. The draft's own "one-line alternative" (*"But if they separate, Allah will enrich each of them from His abundance"*) does not fix this — it has the same defect.

**Fix (one line, founder's choice):**
- (a) render Saheeh verbatim **with** the bracket: `"But if they separate [by divorce], Allah will enrich each [of them] from His abundance…"` — this also converts the beat back into a byte-exact quotation; or
- (b) keep the re-render and put the referent on the beat: `"And if the two of them part, Allah will enrich each one out of His own abundance…" — said of a marriage that ends. (Qur'an 4:130)`

**This is the row I came closest to rejecting on.** It is fixable in one line, so it is FIX rather than REJECT — but it must not ship as written.

## 2.5 ⚠️ BLOCKING FIX 2 — beat 5 begins mid-utterance with **no leading ellipsis**, and an interior elision is undisclosed

The page's sequence, verified, is:

> …[the triple]… `كُلَّمَا قَالَ شَيْئًا قَالُوا اللَّهُ وَرَسُولُهُ أَمَنُّ` · `قَالَ "مَا يَمْنَعُكُمْ أَنْ تُجِيبُوا رَسُولَ اللَّهِ ﷺ"` · `قَالَ كُلَّمَا قَالَ شَيْئًا قَالُوا اللَّهُ وَرَسُولُهُ أَمَنُّ` · `قَالَ "لَوْ شِئْتُمْ قُلْتُمْ جِئْتَنَا كَذَا وَكَذَا. أَتَرْضَوْنَ أَنْ يَذْهَبَ النَّاسُ…"`

Beat 5 opens `Then: "Are you content that the people go away…"` — i.e. it starts **inside** the Prophet's ﷺ utterance, after `لَوْ شِئْتُمْ قُلْتُمْ جِئْتَنَا كَذَا وَكَذَا`, and it silently passes over the *"What stops you from answering the Messenger of Allah?"* exchange that sits between beats 4 and 5. The trailing `…` is present and correct. **The leading one is missing, and neither elision appears in the successor table** — that table covers only the narration's *ending* and its *opening*.

**Fix (one line):** `Then: "…Are you content that the people go away with the sheep and the camel…?…"`, and add the interior elision to the successor table alongside the ending.

## 2.6 ⚠️ The `gh-n-y` enumeration — **RE-RUN, AND IT IS SEVEN, NOT SIX. The conclusion survives; the record does not.**

I enumerated every IV-form `gh-n-y` token in the full Qurʾān independently (48 āyāt hit the token filter) and then isolated those where **Allah is the subject of a transitive enrichment**:

| # | āyah | text | in the draft's list? |
|---|---|---|---|
| 1 | 4:130 | `يُغْنِ ٱللَّهُ كُلًّا مِّن سَعَتِهِۦ` | yes |
| 2 | 9:28 | `فَسَوْفَ يُغْنِيكُمُ ٱللَّهُ مِن فَضْلِهِ` | yes |
| 3 | 9:74 | `أَغْنَاهُمُ ٱللَّهُ وَرَسُولُهُ مِن فَضْلِهِ` | yes |
| 4 | 24:32 | `يُغْنِهِمُ ٱللَّهُ مِن فَضْلِهِ` | yes |
| 5 | **24:33** | **`حَتَّىٰ يُغْنِيَهُمُ ٱللَّهُ مِن فَضْلِهِ`** | **NO — uncounted** |
| 6 | 53:48 | `وَأَنَّهُۥ هُوَ أَغْنَىٰ وَأَقْنَىٰ` | yes |
| 7 | 93:8 | `وَوَجَدَكَ عَآئِلًا فَأَغْنَىٰ` | yes |

**24:33 carries an explicit, transitive, Allah-subject `يُغْنِيَهُمُ ٱللَّهُ مِن فَضْلِهِ` in its own right.** The draft treats 24:33 only as 24:32's unusable *successor* and never as a candidate — so the sentence *"There are six. Five die"* is **numerically false in the packet the founder signs against.**

**Does the anchor choice survive? Yes.** I fetched 24:33: it continues into `وَلَا تُكْرِهُوا۟ فَتَيَـٰتِكُمْ عَلَى ٱلْبِغَآءِ` — the compelled-prostitution clause, **inside the same āyah**, not merely adjacent. It is unusable on this surface for the same reason the draft gives for its neighbour, and dies harder (the defect is intra-āyah, not successor-level). **4:130 remains the only survivor and the anchor is genuinely forced.** But the record must say seven and must state 24:33's own grounds.

**Two further corrections inside that section:**
- **53:48's litany reaches destruction in TWO āyāt, not seven.** Fetched: 53:49 `رَبُّ ٱلشِّعْرَىٰ`, **53:50 `وَأَنَّهُۥٓ أَهْلَكَ عَادًا ٱلْأُولَىٰ`**, 53:51 `وَثَمُودَا۟ فَمَآ أَبْقَىٰ`. The error understates the hazard; the rejection is correct and becomes stronger.
- **9:28's rejection is confirmed.** 9:29 fetched: `قَـٰتِلُوا۟ ٱلَّذِينَ لَا يُؤْمِنُونَ…` — the fighting āyah, immediately adjacent. Correct.
- **9:74's rejection is confirmed.** Its own tail is `يُعَذِّبْهُمُ ٱللَّهُ عَذَابًا أَلِيمًا فِى ٱلدُّنْيَا وَٱلْـَٔاخِرَةِ` — punishment inside the āyah.
- **93:8's block is confirmed.** `al-waliyy@1` is **shipped** (present in `name_stories.json`) and holds 93:6 on its verse beat; 93:8 is two āyāt away in an eleven-āyah sūrah. The "blocked, not free" record is right. *(Minor: the draft labels `al-waliyy@1` `[D]` in its collision table; it is in the shipped asset.)*

## 2.7 ⚠️ A false "verified negative" on the deck's own verse beat, and an undisclosed adjudication

The draft states:

> **Verified negative, run programmatically: 4:130, Bukhārī 4330 and Bukhārī 6446 appear in no shipped deck, no DRAFT file and no sibling claim.**

**False for 4:130.** It appears in `2026-08-03-al-wasi-DRAFT.md` (six times, including its own rejected-candidates section) **and in `.context/claims/57.md`**, where Al-Wāsiʿ records: *"4:130 is CEDED to Al-Mughni (93) on coordinator adjudication… Do not re-propose 4:130 for Al-Wasi."*

**The outcome went this deck's way** (COLLISION-LEDGER §9a rules 4:130 to Al-Mughni on grammar — `يُغْنِ ٱللَّهُ` finite verb vs `وَٰسِعًا` trailing epithet — and I independently agree with that reasoning). **But this deck did not find the conflict; the coordinator did.** The draft's sibling row lists **four** live claims (ids 4, 7, 14, 40) when `.context/claims/` holds **ten** — and **57 is precisely the one that had a live conflict on this deck's verse beat.**

That is the batch-2 bar-3 lesson recurring: the sweep that was run was not the sweep that was needed. It is non-material here only by luck.

**Fix:** correct the verified-negative sentence; widen the sibling row to all ten claims; and **disclose the 4:130 adjudication in the draft** — the founder should learn from this packet, not from the ledger, that another deck claimed and ceded this deck's verse beat today.

## 2.8 Bar 5 — the row I was told to attack. **PASS, but the row overstates itself and one word softens the register by translation.**

I confirm the substance: **no beat renders fighting, an enemy, a killing, a rout or a name of an opposing tribe.** Bukhārī 4330 uniquely among the Ḥunayn routes contains no combat narration at all (3778 has *"swords dribbling with the blood of Quraysh"*, 4337 has the flight and the rout, 4331 has *"our swords are still dribbling with their blood"* — all four fetched; the selection of 4330 is correct and is the strongest available). Successor sweep clean in both directions (§2.9). **What bar 5 actually forbids — a punishment or curse passage repurposed as comfort — is absent.**

Two qualifications the founder should have before signing:

1. **"No spoil-taking" is overstated.** Beat 5 renders *"the people go away with the sheep and the camel"* and beat 8 renders *"the only ones who went home without a sheep or a camel."* Those animals **are** the distributed war-gains. What is genuinely absent is any *labelling* of them as spoils, and any fighting or enemy. The accurate claim is *"no beat renders fighting, an enemy or a killing, and the goods are never named as spoils"* — not *"no spoil-taking."* The ledger §9a row records the drafter's absolute phrasing as ACCEPTED; **I am flagging that the phrasing, not the deck, is what should be corrected.**
2. **`أَفَاءَ` is softened in beat 3.** Both published Englishes render `لَمَّا أَفَاءَ اللَّهُ عَلَى رَسُولِهِ` as *"the war booty"* / *"the booty"*; the beat renders *"what Allah had granted His Messenger ﷺ."* That is lexically defensible (`أفاء` = bestowed as fayʾ) but it **subtracts** the war-gain sense the source carries — the mirror image of the `al-kareem@1` failure, where the published English **added**. Combined with (1), the deck is quietly helping its own bar-5 case by translation. The draft discloses the opposite direction (`أَغْنَىٰ` → *"enriched"*, "the deck helping itself") and is right to; it should disclose this one the same way. **Non-blocking, but it belongs in the same row.**

## 2.9 Successor sweep, re-run — **clean, and 4:131 confirmed**

- **4:129** (n−1): confirmed as establishing that the *"two"* are spouses; ends `غَفُورًا رَّحِيمًا`. No punishment. Carries a `<sup>` footnote marker — immaterial, not quoted.
- **4:130 tail:** `وَكَانَ ٱللَّهُ وَٰسِعًا حَكِيمًا` — cut with a visible `…`. Correct: quoting it would render Al-Wasi's and Al-Hakeem's glosses on an Al-Mughni screen.
- **4:131** (n+1): **confirmed — ends `وَكَانَ ٱللَّهُ غَنِيًّا حَمِيدًا`.** Al-Ghaniyy (92) and Al-Hameed (65), **one āyah past the verse beat, in this deck's own root.** On no screen; disclosed. And confirmed clean on bar 5 — *"But if you disbelieve — then to Allāh belongs whatever is in the heavens and whatever is on the earth"* is a statement of divine independence with **no punishment clause**. The draft's reading is right.

## 2.10 Bar 3 — the two roots that reach the screen. **Both acceptable; not a bar-3 failure.**

- **`h-d-y` — *"and Allah guided you through me"* on beat 4.** Verified: shipped `al-hadi@1` renders *"…And Allah surely guides the believers to the Straight Path"*, *"guide us"*, *"I trust my Lord will guide me to the right way."* So this **is** a shipped Name-verb in English on an Al-Mughni beat. **I rule it acceptable**, on ledger §9o's own test: could a user read both screens and think they had been told the same thing twice? No — on `al-hadi@1` guidance is the thing being asked for and received; on Al-Mughni it is the **first member of a rhetorical triple whose climax and whole point is the third**. No shared string. Cutting two thirds of a quoted prophetic sentence to protect a one-word overlap would be the worse distortion. **Keep, with the disclosure standing.**
- **`ʾ-l-f` — *"brought you together"*.** Al-Jami (91) is `j-m-ʿ`, not `ʾ-l-f`. **Confirmed: nothing to collide with.** Recorded for id 91's drafter.

**English pass, run by me over all 24 shipped decks and 33 drafts:** *"did the arithmetic"*, *"found something in themselves"*, *"Allah enriched you through me"*, *"brought you together through me"*, *"go away with the Prophet"*, *"enrich each one out of His own abundance"*, *"without a sheep or a camel"*, *"already taking home"*, *"a share was coming"* — **zero hits outside this file.** `Ansar`, `Hunayn`, `booty`, `spoils`, `abundance`, `richness`, `distribution` — **zero hits in all 24 shipped decks.** Confirmed.

Confirmed adjacencies:
- **`ar-razzaq@1`'s shipped duʿā beat renders *"…and enrich me by Your favor over all others"* in English, with `وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ` in Arabic — VERIFIED IN THE ASSET.** The draft's claim is **true**: a shipped duʿā screen already asks for exactly what this Name means, in this Name's own root, under a different card. Catalogue text, unfixable inside this deck. Correctly disclosed; correctly separated (this deck's duʿā English says *"make me rich"*, never *"enrich me"*, and never *"over all others"*).
- **`al-kareem@1`** verified: verse beat 27:40 renders *"my Lord is Free of need and Generous"* and beat 8 renders *"The One being asked is Free of need."* This deck uses none of that vocabulary and declines Muslim 2577 deliberately. Correct.
- **`al-qadir@1`** verified: *"that my heart may be satisfied"* is the pack's only `satisfied`. This deck renders *"Are you content."* Correctly separated.
- **`al-wadud@1`** / **`al-waliyy@1`** camel adjacency verified in the asset; different function, no shared string. Non-blocking.

## 2.11 ⚠️ NEW FINDING the draft did not make — catalogue id 93's `dua_translation` renders content its own Arabic does not contain (ledger §9m class), **on this deck's beat 7**

```
dua_arabic         : يَا مُغْنِي أَغْنِنِي بِغِنَاكَ عَنْ سِوَاكَ وَاجْعَلْ قَلْبِي غَنِيًّا بِكَ
dua_transliteration: Ya Mughni, aghnini bighinaka 'an siwak waj'al qalbi ghaniyyan bik
dua_translation    : O Enricher, make me rich through You so I need no one else.
                     Fill my heart with You until no desire competes with Your glory.
```

The Arabic's second petition is `وَاجْعَلْ قَلْبِي غَنِيًّا بِكَ` — *"and make my heart rich/self-sufficient through You."* The English **appends *"until no desire competes with Your glory"***, which has **no counterpart in the Arabic or in the transliteration** (both stop at `bik` / `بِكَ`).

Beat 7 renders Arabic, transliteration and translation **side by side on one screen**. This is exactly the defect the ledger logs at §9m for id 61 and §9p for id 57 — *"an English petition with no counterpart in the Arabic beside it"* — and the ledger says the `dua_translation` column **has been audited zero times**.

The draft did not run that check. Worse, it **affirmatively endorsed the English**: *"The catalogue's id 93 duʿā is a good, on-register invocation whose English ('Fill my heart with You') matches the card's own `lesson` line and this deck's engine exactly."* It quotes the clean half and does not examine the added half.

**This is now the fourth instance in one wave** (ids 57, 61, 93, plus the standing pattern). **I make no recommendation to change the catalogue** — the standing rule that four of four confident catalogue-change recommendations have been wrong applies to me as much as to the drafter, and delete-vs-add on a supplication is a content decision. **It is a finding, and it belongs in the founder packet because it renders on this deck's own screen.**

For contrast: **id 14's `dua_translation` is clean** on the same check.

## 2.12 Ship-gate posture — **CORRECT as stated**

Catalogue id 93's duʿā **is** an authored invocation (vocative `يَا مُغْنِي` + two imperatives, the ids-75/68/16/30 pattern). I found no narration behind it and will not manufacture one. `renderedDuaSources` is asserted bidirectionally in `test/content/name_stories_ship_gate_test.dart:56–74` — verified — so the duʿā beat's `source` **must be empty** and `al-mughni@1` **must not** enter that map. **Do not do half of it.**

For Al-Aleem the inverse holds: if the founder approves the Tirmidhī 3392 pin, transcription **must** add `'al-aleem@1': "Jami' at-Tirmidhi 3392 (opening words)"` to that map in the same change; if he declines, the duʿā beat's `source` must be empty and the deck must not appear. Both are passing states; the half-states are build failures.

## 2.13 The five bars, judged by me

| bar | verdict |
|---|---|
| **1 — demonstrated in Allah's words, not a trailing epithet** | **PASS on the text, CONDITIONAL on fix 2.4.** `وَإِن يَتَفَرَّقَا يُغْنِ ٱللَّهُ كُلًّا مِّن سَعَتِهِۦ` is Allah's own words, a finite transitive verb in the Name's root with an object and a source — verified on `text_uthmani`, and correctly preferred over the trailing `وَٰسِعًا` (which is why the 4:130 adjudication went this way). It is the deck's **only** bar-1 text, so a beat that misstates its referent puts bar 1 at risk. Fix 2.4 is therefore a bar-1 fix, not a cosmetic one. |
| **2 — shown, not stated** | **PASS.** The distinguishing quality against Ar-Razzāq is that **nothing arrives**, and the narration demonstrates it: no late share, no compensating gift, no promise of one. No beat says *"true richness is in the heart"* — and the catalogue `lesson` line that does say it was deliberately not used. |
| **3 — does not collapse into a sibling** | **PASS.** `h-d-y` and `ʾ-l-f` on screen are acceptable (§2.10). The Ar-Razzāq, Al-Kareem and Al-Ghaniyy separations are real and verified against the asset. |
| **4 — Name's root in the source text** | **PASS, untraded.** `يُغْنِ` (4:130) and `فَأَغْنَاكُمُ` (4330) both verified; both reach the screen in English; the duʿā adds four in Arabic. |
| **5 — register** | **PASS, with the phrasing corrected per §2.8.** Successor sweep clean both directions; no punishment or curse repurposed as comfort; no fighting, enemy or killing on any beat. The absolute claim *"no spoil-taking"* should be narrowed, and the `أَفَاءَ` softening disclosed. |

---

# PART 3 — Consolidated blocking list

## `al-aleem@1` — FIX-THEN-SIGN

1. **Beat 6:** add a trailing ellipsis (and drop the deck-invented terminal quotation mark, or keep it after the ellipsis). Plan §7 batch-2 rule 2. §1.7
2. **Beat 5 / beats 4 & 8:** either quote the resumption of her speech (`"And I have named her Mary…"`) so the interruption is visible, or stop asserting a structure no screen shows. Bar 2. §1.8
3. **Record:** the "verified negative" sentence is false as written; the sibling row covers 4 of 10 live claims. §1.9
4. *(non-blocking)* Correct the stale `ar-raqeeb@1` disclosure — that deck now renders Muslim 632a's *"though He is the best informed about them"*, having itself rejected *"knows them best"* on the `al-lateef@1` collision. §1.10
5. *(non-blocking)* `(opening words)` describes the supplication, not the narration. §1.3

## `al-mughni@1` — FIX-THEN-SIGN

1. **Beat 6:** restore Saheeh's `[by divorce]` (which also restores byte-exactness) **or** put the marital referent on the beat. The `al-kareem@1` rule was misapplied to justify dropping it. **Bar 1's only text.** §2.4
2. **Beat 5:** add a leading ellipsis and disclose the interior elision (the *"What stops you from answering…"* exchange and `لَوْ شِئْتُمْ قُلْتُمْ جِئْتَنَا كَذَا وَكَذَا`). §2.5
3. **Record:** the `gh-n-y` enumeration is **seven**, not six — **24:33 (`حَتَّىٰ يُغْنِيَهُمُ ٱللَّهُ مِن فَضْلِهِ`) is uncounted.** The anchor is still forced (24:33 dies intra-āyah on `وَلَا تُكْرِهُوا۟ فَتَيَـٰتِكُمْ عَلَى ٱلْبِغَآءِ`), but the sentence *"There are six. Five die"* is false. Also: 53:48 → destruction is **two** āyāt, not seven. §2.6
4. **Record:** the "verified negative" on 4:130 is false — it is in `2026-08-03-al-wasi-DRAFT.md` and `.context/claims/57.md`. The 4:130 cession from Al-Wāsiʿ is **undisclosed in this draft** and was found by the coordinator, not by this deck's own sweep (4 of 10 claims checked). §2.7
5. **Bar-5 row:** narrow *"no spoil-taking"* to what is true, and disclose that `أَفَاءَ` → *"what Allah had granted His Messenger"* subtracts the war-gain sense both published Englishes carry. §2.8
6. *(finding, no action recommended)* Catalogue id 93's `dua_translation` appends *"until no desire competes with Your glory"* with no Arabic counterpart — ledger §9m class, rendering on this deck's own beat 7, and affirmatively endorsed by the draft. §2.11

---

# PART 4 — Could not verify (limits of my own method)

Stated because the founder signs against this document too.

1. **Ḥadīth verification is not independent of sunnah.com as a corpus.** sunnah.com 403s automated fetching. All eight ḥadīth pages (Bukhārī 4330, 4331, 3778, 4337, 6446, 4697; Muslim 1061; Tirmidhī 3392; Abū Dāwūd 5067) were read from Wayback captures of the exact bare-numbered sunnah.com URLs. **All derive from one digitisation.** I consulted no printed edition and no Arabic-primary database (Shamela, Dorar). I chose my own capture timestamps rather than reusing either drafter's, which rules out a stale-or-wrong-capture error but not a corpus-level one.
2. **No isnād was audited.** Published grade lines were read off the page and accepted as printed (`هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ` for Tirmidhī 3392; `Sahih (Al-Albani)` for Abū Dāwūd 5067; collection-level ṣaḥīḥ for the Bukhārī pages, which carry no per-page grade line). I did not verify that these grade lines reflect the printed Darussalam apparatus.
3. **The weeping detail is proven absent from five pages, not from the corpus.** I fetched Bukhārī 4330, 4331, 3778, 4337 and Muslim 1061. I did **not** run a corpus-wide search for `اخضل` / *"beards"*, so I can say the withdrawal was correct and the drafter's Muslim attribution is unsupported — I cannot say where the detail actually lives.
4. **The `gh-n-y` enumeration is a morphological filter over a single simple-script text**, then hand-classified for subject and transitivity. It catches every token matching `(و|ف|ل|ب|ك|س)*(ا|ي|ت|ن|م)غن`. A form outside that shape — or an enrichment expressed without the root — would be missed. The seven I list are the IV-form Allah-subject transitives; I make no claim about the root's non-verbal occurrences.
5. **The English bar-3 pass compares `primary`/`label`/`translation`/`source` strings** of the 24 shipped decks and raw markdown of 33 draft files. **Draft files are prose, not beat arrays** — a hit inside a draft's *verification table* is indistinguishable from a hit on a *beat* without reading it, so I read every hit that mattered but cannot claim a mechanical beat-to-beat diff against unfinished siblings. This is the same limit `al-wasi@1`'s draft records at its own note 4.
6. **I did not run the ship gate.** I read `test/content/name_stories_ship_gate_test.dart:56–74` for `renderedDuaSources` and reasoned about it; I did not execute `flutter test`, and I edited no asset, draft or test.
7. **Two judgements below are mine and are contestable, and I say so rather than presenting them as findings of fact:** (a) that `h-d-y` reaching an Al-Mughni screen is acceptable under §9o; (b) that the 4:130 referent problem is a fix rather than a reject. On (b), a founder with a stricter line on verse-beat context could reasonably reject `al-mughni@1` outright and require a different anchor — in which case §2.6 says there is **no other surviving `gh-n-y` text**, and the deck would have to trade bar 4 or be shelved.
8. **I did not re-verify the drafters' claim of a programmatic run.** I re-ran the substance myself and report my own results; where mine agree with theirs I say so, and where they disagree (§1.9, §2.6, §2.7) mine is the one I stand behind.
