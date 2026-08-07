# Deck Draft — Al-Azeem (catalogue id 50) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-majeed-DRAFT.md`](2026-08-03-al-majeed-DRAFT.md).** Ids 50 and 58 **share one locked `dua_arabic`** (§9ce) — a shared-duʿā group the handoff did not record until 2026-08-03. **The duʿā names only this Name** — `سُبْحَانَ رَبِّيَ الْعَظِيمِ` — so id 58's deck renders a duʿā that never mentions Al-Majeed. Catalogue-locked; see *The shared duʿā*.

> **Id 50 was previously quarantined for fabricated content.** That draft was not reused and not read as precedent; its ground was released.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/50-58.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-azeem@1` — Al-Azeem

**Why this deck exists, in one line:** the user whose one problem has expanded to fill the entire frame, so that nothing else in their life is visible tonight.

**What separates it from its pair-partner:** Al-Azeem is **magnitude that reframes**; Al-Majeed is **magnitude that comes close**. One changes the scale you are measuring on, the other arrives in the room.

**Proposed metadata**

```json
{
  "deck_id": "al-azeem@1",
  "name_id": 50,
  "transliteration": "Al-Azeem",
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
> The thing you cannot stop turning over tonight is genuinely large. It is not large next to everything.

**Beat 2 · name_intro** *(catalogue id 50 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْعَظِيمُ — Al-Azeem — The Magnificent

**Beats 3–5 · story — "The Water and the Fire"** *(Qur'an 56:68–72)*:
> 3. Allah asks: "And have you seen the water that you drink? Is it you who brought it down from the clouds, or is it We who bring it down?"
> 4. "And have you seen the fire that you ignite? Is it you who produced its tree, or are We the producer?"
> 5. Water and fire — the two most ordinary things in a household. The passage does not argue that He is great. It asks whether you have ever noticed the size of what you use without thinking.

**Beat 6 · verse** *(whole āyah, no truncation; **the source of this deck's own duʿā**)*:
> So exalt the name of your Lord, the Most Great. — Qur'an 56:74

**Beat 7 · duʿā** *(catalogue id 50, **byte-for-byte**, asserted programmatically (§9cb); **identical to id 58's** — catalogue-locked)*:
> سُبْحَانَ رَبِّيَ الْعَظِيمِ
> *Subhana Rabbiyal 'Azeem*
> "Glory be to my Lord, the Most Magnificent."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Kabeer answers whatever towers over you. Al-Azeem is not a comparison at all — it is the size of what is already in your hands, unnoticed all day. And it is the Name your own duʿā says out loud every time you bow.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Say it once, slowly, the way it is said in rukuʿ. What in your day changes size?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"And have you seen the water that you drink? Is it you who brought it down from the clouds, or is it We who bring it down?"* (beat 3) | `.../56:68` + `.../56:69` | ✅ `أَفَرَءَيْتُمُ ٱلْمَآءَ ٱلَّذِى تَشْرَبُونَ` · `ءَأَنتُمْ أَنزَلْتُمُوهُ مِنَ ٱلْمُزْنِ أَمْ نَحْنُ ٱلْمُنزِلُونَ` — **bar-1 carrier**, first-person plural |
| 2 | *"And have you seen the fire that you ignite? Is it you who produced its tree, or are We the producer?"* (beat 4) | `.../56:71` + `.../56:72` | ✅ `أَفَرَءَيْتُمُ ٱلنَّارَ ٱلَّتِى تُورُونَ` · `ءَأَنتُمْ أَنشَأْتُمْ شَجَرَتَهَآ أَمْ نَحْنُ ٱلْمُنشِـُٔونَ` |
| 3 | *"So exalt the name of your Lord, the Most Great."* (beat 6, **bar-4 carrier**) | `.../56:74` | ✅ `فَسَبِّحْ بِٱسْمِ رَبِّكَ ٱلْعَظِيمِ` — whole āyah, and **the passage's own conclusion** |
| 4 | 56:70, inside the story passage but **not rendered** | `.../56:70` | ⚠️ `لَوْ نَشَآءُ جَعَلْنَـٰهُ أُجَاجًا فَلَوْلَا تَشْكُرُونَ` — *"so why are you not grateful?"* A mild reproach. **Deliberately skipped**; beats 3 and 4 jump 56:69 → 56:71 |
| 5 | Successor sweep n−1 of the verse beat: 56:73 | `.../56:73` | ✅ `تَذْكِرَةً وَمَتَـٰعًا لِّلْمُقْوِينَ` — a reminder and provision. Clean |
| 6 | Successor sweep n+1 of the verse beat: 56:75 | `.../56:75` | ✅ an oath by the setting of the stars. Clean |
| 7 | The locked duʿā (shared with id 58) | `collectible_names.json` id 50 | ✅ all three fields asserted present (§9cb). **It is 56:74 turned into the worshipper's own words** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **56:69 and 56:72** — `أَمْ نَحْنُ ٱلْمُنزِلُونَ` / `أَمْ نَحْنُ ٱلْمُنشِـُٔونَ`, first-person plural, Allah the subject, in Allah's own voice | ✅ **PASS** |
| 2 | Shown, not stated | a **two-part rhetorical demonstration** — the water you drink, the fire you light — each posed as a question the reader answers themselves. The brief names this form as qualifying | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ع-ظ-م` as `ٱلْعَظِيمِ` on the verse beat (56:74), which is the passage's **own conclusion** — the story and the root carrier are consecutive āyāt | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **clean both sides** — 56:73 is *a reminder and provision for the travelers*; 56:75 is an oath by the setting of the stars | ✅ **PASS** |

**The structural point worth noticing: bar 4 is discharged by the passage's own last line.** 56:68–72 asks the questions; **56:74 draws the conclusion — `فَسَبِّحْ بِٱسْمِ رَبِّكَ ٱلْعَظِيمِ`.** The verse beat is not a root carrier imported from elsewhere; it is where the story was already going. That is the tightest carrier/verse relationship in this wave.

**And it closes the loop on the duʿā.** Id 50's locked duʿā is `سُبْحَانَ رَبِّيَ الْعَظِيمِ` — the tasbīḥ of rukūʿ — which is the direct imperative of 56:74 turned into the worshipper's own words. **The deck's verse beat and its duʿā beat are the same act of tasbīḥ, once as command and once as response.** ⚠️ **R3 correction:** R0 said *"the same sentence"*. They are **not** the same sentence — 56:74 is an imperative addressed to the Prophet ﷺ (`فَسَبِّحْ`, second person), the duʿā is the worshipper's own exclamation in the first person (`سُبْحَانَ رَبِّيَ`). The **liturgical link is real** — the tasbīḥ of rukūʿ is traditionally tied to this āyah — but *"the same sentence"* was rhetoric where the protocol wants a measurement (§9ak). Nothing in the deck had to be arranged for this; it is how the passage is built.

**Bar 5, measured (§9ak):** two āyāt fetched, zero punishment, and 56:73 is provision.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** Every hit is a function-word or scripture run — *"brought it down"* (vs `ar-rauf@1`'s takeaway; scripture phrasing), *"the name"*. **No finding.**

**Twin-diff vs `al-majeed@1`** (the pair-partner, which is the diff that matters here): ****3** — *"azeem is"*, this deck's takeaway naming itself. No shared move, no shared text.**

**Every āyah checked against the shipped asset *and* all 30 pending drafts**, two-sided boundary match: **56:68–72 all free · 56:74 free.** **39:67 was the first choice and was abandoned** — see Rejected; it collides with a shipped deck. **2:255 SPENT** (`al-qayyum@1` + 11 drafts). 42:4 free but left for register reasons.

### Bar 3(c) — the move

**Al-Azeem's move is that the scale you have been measuring on is the wrong instrument — demonstrated with two objects already in the reader's house.**

This is deliberately **not** "your problem is small". The passage never says that. It asks whether the reader has ever registered the size of **water and fire** — the two most ordinary things in a household — and it does so by asking who actually produced them. The magnitude arrives through the domestic, not the cosmic.

**That choice is load-bearing, because the cosmic route is taken.** The obvious text for this Name is 39:67 — the earth in His grip, the heavens folded in His right hand — and **shipped `al-malik@1` already renders the ḥadīth parallel of exactly that image** (*Allah will hold the whole earth, and roll all the heavens up in His Right Hand…*). Using 39:67 would have put the same picture on two decks. **The `al-qabid@1` drafter had independently refused 39:67 for a related reason.**

**Against the pair-partner:** Al-Majeed's move is majesty **that draws near** — glory in a household, spoken to one woman. **Al-Azeem's is magnitude that reorders perspective** — it does not come closer, it changes what "large" means. Both are size Names; one closes distance, the other resets the ruler.

**Against `al-kabeer@1` (id 53, unstarted):** Al-Kabeer answers **what towers over you** — a comparison with a threat in it. **Al-Azeem removes the comparison.** Whoever drafts 53 owes the diff against this deck.

---

## The shared duʿā

Ids 50 and 58 render **one identical duʿā beat**: `سُبْحَانَ رَبِّيَ الْعَظِيمِ`. A user who collects both sees the same duʿā twice. **Catalogue-locked, disclosed rather than concealed, and no beat on either deck claims it is Name-specific.** Each deck's engine is carried on its **takeaway**, which is fixed and not AI-replaced.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **39:67** `وَٱلْأَرْضُ جَمِيعًا قَبْضَتُهُۥ … وَٱلسَّمَـٰوَٰتُ مَطْوِيَّـٰتٌۢ بِيَمِينِهِۦ` | **the strongest text for this Name by imagery, and refused.** Shipped **`al-malik@1` renders the ḥadīth parallel of the same scene**; a 4-gram (*"his right hand"*) and an identical picture. Also **lacks the root** (`ق-د-ر`, `ق-ب-ض`), so it would have needed a bar-4 trade as well. Refused on bar 3(c), not on bar 5 |
| **2:255** `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ` | **spent** — `al-qayyum@1` verse beat plus 11 pending drafts |
| **42:4** `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ` | free, but a trailing epithet pair, and **`ٱلْعَلِىُّ` is id 52's word**, being drafted in the same wave |
| **69:33** `لَا يُؤْمِنُ بِٱللَّهِ ٱلْعَظِيمِ` | the root predicated of Allah — inside a **punishment passage**. Bar 5 |
| **56:96 · 69:52** | the identical sentence to 56:74. Free, left unspent, and **either would substitute cleanly** if 56:74 is ever contested |
| **The 120 `عَظِيم` occurrences generally** | overwhelmingly `أَجْرٌ عَظِيمٌ` (great reward), `عَذَابٌ عَظِيمٌ` (great punishment) and `يَوْمٍ عَظِيمٍ` — **the adjective describes things, not Allah**, in most of its 128 occurrences |

---

## Catalogue findings — reported, **NO change recommended**

1. **The duʿā shared with id 58 names only this Name.** `سُبْحَانَ رَبِّيَ الْعَظِيمِ` contains `ٱلْعَظِيمِ` and nothing of Al-Majeed. **Al-Majeed's deck therefore renders a duʿā that never mentions Al-Majeed** — reported for the pair, **not actioned**, and disclosed on both decks (§9ce).
2. **Id 50's `lesson` — *"Your problems feel massive — until you remember the magnificence of Al-Azeem"* — is exactly this deck's engine**, and was read after the text was selected rather than before.

---

## What I could not determine — attack these first

1. **`ع-ظ-م` has 128 occurrences and was not exhaustively fetched** (§9cc). The form breakdown was read and the occurrences predicated *of Allah* were enumerated; the ~120 `ʿaẓīm` uses describing rewards, punishments and days were not individually fetched. **Complete on the divine predications, incomplete on the root.**
2. **The 39:67 refusal is a judgement call about imagery, not a measurement.** The n-gram was only 4. **A verifier may reasonably hold that the Qurʾānic text should outrank a shipped deck's ḥadīth rendering of the same scene** — in which case this deck should move to 39:67 and `al-malik@1` should be re-examined. Stated as an open question, since it went the conservative way.
3. **Bar 2 rests on rhetorical questions counting as demonstration.** The brief allows parables and counterfactuals explicitly; a question-with-evidence is adjacent but not named. Attack this if the 39:67 point does not land.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Reviewed with `al-majeed@1` for the shared duʿā only — the two render entirely disjoint scripture (56:68–74 vs 11:73 and 85:15) and different engines.
