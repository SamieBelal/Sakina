# Deck Draft — Al-Ali (catalogue id 52) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-mutaali-DRAFT.md`](2026-08-03-al-mutaali-DRAFT.md).** Ids 52 and 84 **share one locked `dua_arabic`** (§9ce) — a shared-duʿā group the handoff did not record until 2026-08-03. They **also share the root `ع-ل-و`**, which makes this the tightest pair in the project — one duʿā, one root, two Names.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/52-84.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-ali@1` — Al-Ali

**Why this deck exists, in one line:** the user who has been addressing Him the way you address someone in the room, and reading the silence back as absence.

**What separates it from its pair-partner:** Al-Ali is about **the form an encounter takes**; Al-Mutaali is about **every description falling short**. One is architecture, the other is correction.

**Proposed metadata**

```json
{
  "deck_id": "al-ali@1",
  "name_id": 52,
  "transliteration": "Al-Ali",
  "chip_keys": [],
  "position_in_pair": 1,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> You have been talking to Him the way you talk to someone in the room. He is not in the room. That is not distance — it is height.

**Beat 2 · name_intro** *(catalogue id 52 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْعَلِيُّ — Al-Ali — The Most High

**Beats 3–5 · story — "Three Ways of Being Spoken To"** *(Qur'an 42:51)*:
> 3. Allah says: "And it is not for any human being that Allah should speak to him except by revelation, or from behind a partition, or that He sends a messenger to reveal, by His permission, what He wills."
> 4. Three ways, and not one of them is face to face. Not because He withdraws — because of what He is. A partition is not a wall between strangers. It is what height requires.
> 5. Notice what the sentence is actually about: He does speak. All three are ways of speaking. The elevation does not end the conversation. It shapes it.

**Beat 6 · verse** *(partial quotation — visible ellipsis; `حَكِيمٌ` **left for id 26 Al-Hakeem**)*:
> …Indeed, He is Most High… — Qur'an 42:51

**Beat 7 · duʿā** *(catalogue id 52, **byte-for-byte**, asserted programmatically (§9cb); **identical to id 84's** — catalogue-locked)*:
> يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ
> *Ya 'Aliyyu ya Muta'ali, irfa' qalbi fawqa'd-daghina wa's-sighar*
> "O The Exalted, O The Supremely Exalted, raise my heart above resentment and smallness."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Mutaali is that He is above every account of Him, including this one. Al-Ali is nearer than that, and harder: the height is the reason the address has a shape at all. You are not being kept outside. You are being spoken to in the only form the distance permits — and He chose to speak.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What would change if the quiet you have been reading as absence were the shape of an answer instead?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And it is not for any human being that Allah should speak to him except by revelation, or from behind a partition, or that He sends a messenger to reveal, by His permission, what He wills"* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../42:51` | ✅ `وَمَا كَانَ لِبَشَرٍ أَن يُكَلِّمَهُ ٱللَّهُ إِلَّا وَحْيًا أَوْ مِن وَرَآئِ حِجَابٍ أَوْ يُرْسِلَ رَسُولًا فَيُوحِىَ بِإِذْنِهِۦ مَا يَشَآءُ ۚ إِنَّهُۥ عَلِىٌّ حَكِيمٌ` — the three modes rendered whole; the closing `حَكِيمٌ` **not rendered** |
| 2 | *"…Indeed, He is Most High…"* (beat 6) | `.../42:51` | ✅ `إِنَّهُۥ عَلِىٌّ` — visible ellipsis both sides. `حَكِيمٌ` **left for id 26 Al-Hakeem** |
| 3 | Successor sweep n−1: 42:50 | `.../42:50` | ✅ no punishment — `يَجْعَلُ مَن يَشَآءُ عَقِيمًا`, closes `عَلِيمٌ قَدِيرٌ` |
| 4 | Successor sweep n+1: 42:52 | `.../42:52` | ✅ **good news** — revelation as `نُورًا نَّهْدِى بِهِۦ`, a light by which He guides |
| 5 | The locked duʿā (shared with id 84) | `collectible_names.json` id 52 | ✅ all three fields asserted present (§9cb) |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **42:51** — Allah's own narration of how He speaks to human beings, in three enumerated modes | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **enumerates a structure** — `وَحْيًا` / `مِن وَرَآئِ حِجَابٍ` / `يُرْسِلَ رَسُولًا` — and the elevation is what the structure is *made of*. It is shown by the shape of the encounter, never asserted | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ع-ل-و` as `عَلِىٌّ` in the rendered clause of 42:51 | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **clean both sides** — 42:50 has no punishment; **42:52 is revelation described as light and guidance** | ✅ **PASS** |

**Bar 5 as a measurement, not an adjective (§9ak):** two āyāt fetched, zero punishment. **42:52 is unusually good news for a successor** — `وَلَـٰكِن جَعَلْنَـٰهُ نُورًا نَّهْدِى بِهِۦ مَن نَّشَآءُ مِنْ عِبَادِنَا`, *but We have made it a light by which We guide whom We will of Our servants.* The passage the deck sits in continues into guidance, not warning.

**Why 2:255 is not used, which is the sweep's most important output.** `ٱلْعَلِىُّ` occurs 11 times as a nominal, and its most famous location — **Āyat al-Kursī, `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ`** — is **spent**: rendered by shipped `al-qayyum@1`'s verse beat and cited in **11 pending drafts**. A drafter reaching for this Name from memory goes to 2:255 first and finds it gone. **42:51 is better anyway**, because 2:255's `ٱلْعَلِىُّ` is a trailing epithet that labels, while 42:51 demonstrates.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** Every hit is a function-word or scripture run — *"of them is"* (vs `al-kareem@1`), *"it is not"* (vs `al-khaliq@1`, `al-haleem@1`). **No finding.**

**Twin-diff vs `al-mutaali@1`** (the pair-partner, which is the diff that matters here): ****4** — *"is not a wall"*. This deck's beat 4 says a partition *is not a wall between strangers*; the partner's takeaway says its correction *is not a wall you keep walking into*. **A deliberate echo across a pair that shares a duʿā**, disclosed rather than removed; the two sentences make opposite points with the same image. An earlier revision measured **5** (*"address has a shape"*) because the partner's takeaway quoted this deck's phrasing verbatim — **rewritten**, the same failure the judgment four produced and the reason intra-pair diffs are run at all.**

**Every āyah checked against the shipped asset *and* all 30 pending drafts**, two-sided boundary match: **42:51 free · 42:4 free** (42:4 evaluated and left — see Rejected). **2:255 SPENT** — `al-qayyum@1` verse beat plus 11 pending drafts.

### Bar 3(c) — the move

**Al-Ali's move is that the height is what gives the address its shape — and that there *is* an address.**

The reader's error is treating elevation as absence. 42:51 answers it structurally rather than reassuringly: **all three modes in the āyah are modes of *speaking*.** `وَحْيًا`, from behind a partition, by a sent messenger — the list is not about what is withheld, it is an inventory of how the speech gets through.

**Against the pair-partner:** Al-Mutaali is a claim about *your descriptions* — every one falls short. **Al-Ali is a claim about *the channel*** — it has a form, and the form is a consequence of the height rather than a substitute for contact.

**Against `al-quddus@1` (shipped)**, which is the nearest non-pair neighbour: that deck's move is **purity** — He is free of defect. This deck's is **elevation with a channel attached**. Purity separates; height, here, delivers.

---

## The shared duʿā

Ids 52 and 84 render **one identical duʿā beat**: `يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ`. A user who collects both sees the same duʿā twice. **Catalogue-locked, disclosed rather than concealed, and no beat on either deck claims it is Name-specific.** Each deck's engine is carried on its **takeaway**, which is fixed and not AI-replaced.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **2:255** `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ` | **spent** — shipped `al-qayyum@1`'s verse beat plus 11 pending drafts. Also a trailing epithet: it labels, it does not demonstrate |
| **42:4** `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ` | free, but the same epithet pair, and **`ٱلْعَظِيمُ` is id 50's word** — taking it would spend a Name that is being drafted in the same wave. Left |
| **34:23 · 31:30 · 22:62** | `ٱلْعَلِىُّ` present, but each is cited in a pending draft (`an-nafi`, `al-mutakabbir`) and each is an appended epithet |
| **43:4** `لَعَلِىٌّ حَكِيمٌ` | free — but the subject is **the Qurʾān**, not Allah. `ٱلْكِتَـٰب` is exalted here, and bar 1 requires the Name predicated of Allah |
| **4:34** | `عَلِيًّا كَبِيرًا` in a passage on marital discipline — register, and `كَبِيرًا` is id 53's word |
| **42:51's `حَكِيمٌ`** | **left for id 26 Al-Hakeem.** This deck truncates before it |

---

## Catalogue findings — reported, **NO change recommended**

1. **Ids 52 and 84 share one duʿā that names *both* Names** — `يَا عَلِيُّ يَا مُتَعَالِي`. Unusual and helpful: unlike ids 26/49 (whose duʿā invokes Al-Lateef) or 50/58 (whose duʿā names only Al-Azeem), **this duʿā is accurate for both decks.** Recorded as the one shared-duʿā group in the catalogue with no mismatch.
2. **Nothing else.** Id 52's `english`, `meaning` and `lesson` are mutually consistent.

---

## What I could not determine — attack these first

1. **`ع-ل-و` has 70 occurrences in 14 forms and was not exhaustively fetched.** The form breakdown was read and the `ʿaliyy` nominal occurrences plus the named candidates were fetched — so the sweep is **complete on the Name-form and incomplete on the root** (§9cc).
2. **The pair shares a root as well as a duʿā**, which makes the surface-(c) argument the load-bearing one. **Re-argue it rather than check it** (§9cd).
3. **42:51 is a theologically dense āyah** about the modes of revelation. This deck reads it as demonstrating elevation; **a verifier should confirm that reading is not doing more work than the text supports**, since the āyah's primary subject is revelation, not the Name.
4. **No ḥadīth fetched** — no ḥadīth beats, duʿā claims no narration (§9bc).

---

## Pairing verdict

**Ships independently of everything except its own honesty about the shared duʿā.** No hard dependency on `al-mutaali@1`, but the two should be **reviewed together** — they share a duʿā *and* a root, so a reviewer who sees only one cannot judge the separation.
