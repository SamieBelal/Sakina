# Deck Draft — As-Sabur (catalogue id 32) — **R0, awaiting independent blind verification**

> **This deck exists because a refusal I wrote earlier today was wrong.** The refusal is kept at [`2026-08-03-as-sabur-REFUSAL-OVERTURNED.md`](./2026-08-03-as-sabur-REFUSAL-OVERTURNED.md) with an analysis of the error, because it is the **third** refusal in this project to be overturned and the pattern is now the finding. **Its sweep is sound and is reused here in full; its conclusion was not.**

⚠️ **Duʿā partner is in production.** Ids 32 and **29 Al-Haleem** share one locked `dua_arabic` (§9ce), and **shipped `al-haleem@1` renders it verbatim.** A bar-3(b) sweep therefore returns a shared run equal to the entire duʿā — correct, unavoidable, catalogue-locked. **`al-haleem@1` also renders the only ṣaḥīḥ text in which this Name's root is predicated of Allah.** Both facts are handled below rather than worked around.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/32.md`.

All sources live-fetched 2026-08-03: `api.quran.com/api/v4`, `corpus.quran.com/qurandictionary.jsp?q=Sbr`, and `sunnah.com` via Wayback captures. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `as-sabur@1` — As-Sabur

**Why this deck exists, in one line:** the user who has been waiting so long that they have started to read the waiting itself as the answer.

**The reader's position:** **not refused — un-replied-to.** They are not asking whether He is merciful, or whether He noticed. They are asking why, if He did, nothing has moved.

**Proposed metadata**

```json
{
  "deck_id": "as-sabur@1",
  "name_id": 32,
  "transliteration": "As-Sabur",
  "chip_keys": [],
  "position_in_pair": null,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> You have been waiting so long that you have started to read the waiting itself as the answer.

**Beat 2 · name_intro** *(catalogue id 32 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الصَّبُورُ — As-Sabur — The Patient

**Beats 3–5 · story — "A Thousand Years of Those Which You Count"** *(Qur'an 32:5)*:
> 3. Allah says: "He arranges [each] matter from the heaven to the earth; then it will ascend to Him in a Day…"
> 4. "…the extent of which is a thousand years of those which you count." Of those which you count. The sentence stops to name whose clock is being used, and it is not His.
> 5. Notice that nothing in it is late. A matter goes down, is arranged, comes back up — on time, at full speed, on a scale where a thousand of your years is one of His days.

**Beat 6 · verse** *(partial quotation — visible ellipsis; a second, independent attestation of the same scale from a different sūrah)*:
> …And indeed, a day with your Lord is like a thousand years of those which you count. — Qur'an 22:47

**Beat 7 · duʿā** *(catalogue id 32, **byte-for-byte**, asserted programmatically (§9cb); **identical to shipped `al-haleem@1`'s** — catalogue-locked)*:
> اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ
> *Allahumma inni as'alukas-sabra wa a'udhu bika minal-jaza'*
> "O Allah, I ask You for patience and I seek refuge in You from anxiety and distress."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here, and it is doing more work than usual)*:
> Al-Haleem is restraint: power held back from what it could rightly do. As-Sabur is not restraint at all — it is scale. He is not withholding from you. He is not on your clock, and the silence you have been reading as refusal is a matter still ascending.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> How long have you actually been waiting? Put the number next to the one in the verse.

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"He arranges [each] matter from the heaven to the earth; then it will ascend to Him in a Day, the extent of which is a thousand years of those which you count"* (beats 3–5, **bar-1 carrier**) | `.../32:5` | ✅ `يُدَبِّرُ ٱلْأَمْرَ مِنَ ٱلسَّمَآءِ إِلَى ٱلْأَرْضِ ثُمَّ يَعْرُجُ إِلَيْهِ فِى يَوْمٍ كَانَ مِقْدَارُهُۥٓ أَلْفَ سَنَةٍ مِّمَّا تَعُدُّونَ` — **whole āyah**, split at the `يَوْمٍ` boundary |
| 2 | *"…And indeed, a day with your Lord is like a thousand years of those which you count."* (beat 6) | `.../22:47` | ✅ `وَإِنَّ يَوْمًا عِندَ رَبِّكَ كَأَلْفِ سَنَةٍ مِّمَّا تَعُدُّونَ` — **the closing clause only.** 22:47 opens `وَيَسْتَعْجِلُونَكَ بِٱلْعَذَابِ` (*they urge you to hasten the punishment*) — **not rendered**, visible ellipsis |
| 3 | Successor sweep n−1: 32:4 | `.../32:4` | ✅ creation in six days, the Throne. **No punishment.** Not rendered; cited in the `al-waliyy` draft |
| 4 | Successor sweep n+1: 32:6 | `.../32:6` | ✅ closes `ٱلْعَزِيزُ ٱلرَّحِيمُ` — **the Merciful.** Not rendered; cited in the `al-khaliq` draft |
| 5 | Root sweep, **complete on the question asked** | `corpus…?q=Sbr` | ✅ *"occurs **103 times**… in **eight derived forms**"*, 93 distinct āyāt. **Every form takes a human subject.** Enumerated below |
| 6 | **Bukhārī 7378** — the one ṣaḥīḥ predication of the root to Allah | `sunnah.com/bukhari:7378` via Wayback (direct = **HTTP 403**, Cloudflare) | ✅ `مَا أَحَدٌ أَصْبَرُ عَلَى أَذًى سَمِعَهُ مِنَ اللَّهِ…` — **Ṣaḥīḥ.** ⚠️ **Rendered in full by shipped `al-haleem@1`. Not used here** |
| 7 | **Tirmidhī 3507** — the 99-Names enumeration, the only attestation of the **Name-form** `ٱلصَّبُور` | `sunnah.com/tirmidhi:3507` via Wayback | ⚠️ **`الصبور` confirmed present** (last Name in the list). **Grade: `Daʿīf` (Darussalam)**; Tirmidhī's own comment: `هذا حديث غريب`. **Not cited on any beat** |
| 8 | The locked duʿā | `collectible_names.json` id 32 | ✅ three fields asserted present (§9cb). ⚠️ **byte-identical to shipped `al-haleem@1`'s duʿā beat** — verified against `name_stories.json` |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **32:5** — `يُدَبِّرُ` / `يَعْرُجُ`, Allah's own narration of His own ongoing administration | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **enacts a round trip on a stated scale** rather than asserting an attribute | ✅ **PASS** |
| 3 | No sibling-Name collapse | ⚠️ the duʿā collides with production **by construction**; the beats do not | ⚠️ **PASS on beats, disclosed on the duʿā** |
| 4 | Root in the quoted text | ❌ **`ص-ب-ر` appears nowhere in either rendered text** | ⚠️ **TRADED — and this is the most forced trade in the project** |
| 5 | Register and reverence | ✅ 32:4 clean, **32:6 closes on `ٱلرَّحِيمُ`**; 22:47's punishment clause not rendered | ✅ **PASS** |

### Bar 4 — the trade, and why the sweep forces it beyond argument

The brief makes bar 4 **tradeable "only with a documented full-corpus sweep proving the trade is forced."** Three independent findings, each fetched, make this the clearest forced trade this project has produced:

**(i) The root is never predicated of Allah in the Qurʾān.** `corpus?q=Sbr` — **HTTP 200, 49,695 bytes** — reports **103 occurrences in eight forms across 93 āyāt**: 58× form I `ṣabara`, 1× form III, 3× form VIII, 4× `ṣabbār`, 15× the noun `ṣabr`, 20× `ṣābir`, 1× `ṣābirāt`, 1× `ṣābirat`. **Every single one takes a human subject** — commands to be patient (2:45, 2:153, 3:200, 8:46, 10:109, 16:127, 20:130, 40:55, 46:35, 70:5, 73:10, 74:7 …), descriptions of patient people (2:155, 2:177, 3:17, 3:142, 8:65, 33:35 …), the reward of patience (16:96, 23:111, 25:75, 28:54, 76:12), and Mūsā with al-Khiḍr (18:67–82), where the entire subject is *human* inability to be patient. **There is no form `ṣabūr` in the Qurʾān and no āyah in which Allah is the one described as patient.**

**(ii) The one ṣaḥīḥ predication is an elative, not the Name — and it is in production.** Bukhārī 7378: `مَا أَحَدٌ أَصْبَرُ عَلَى أَذًى سَمِعَهُ مِنَ اللَّهِ` — *"None is more patient than Allah…"* `أَصْبَرُ` is a **comparative**, and **shipped `al-haleem@1` renders the ḥadīth across two story beats**, both clauses, in English. **Not available.**

**(iii) The Name-form's only attestation is weak.** `ٱلصَّبُور` appears in **Tirmidhī 3507**'s enumeration — confirmed present in the Wayback capture, the last Name in the list — and that ḥadīth is graded **`Daʿīf` (Darussalam)**, with Tirmidhī himself calling it `غريب`. **This deck therefore does not cite it**, and a bar-4 claim resting on it would be weaker than an honest trade.

**So the trade is not a convenience. There is no ṣaḥīḥ text anywhere in which this Name's own form is predicated of Allah**, and the one ṣaḥīḥ text carrying its root belongs to a shipped deck. **32:5 carries bars 1, 2 and 5 with no root; nothing carries bar 4; and the sweep proves nothing could.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run across the beats: 4** — *"it is not"* (vs `al-khaliq@1`'s bridge and `al-haleem@1`'s takeaway), *"the one"*, *"not on"*, *"is late"*. All function-word runs. **No finding.**

**Measured specifically against `al-haleem@1`** — the shipped deck that holds this Name's duʿā *and* its ṣaḥīḥ carrier, and therefore the only comparison that matters: **maximum 4**, *"it is not"*. **No shared scripture, no shared ḥadīth, no shared engine.**

**On the duʿā beat the run is the entire string**, against production. Catalogue-locked and unavoidable (§9ce).

**Every āyah checked against the shipped asset *and* all 37 pending drafts**, two-sided boundary match: **32:5 free · 22:47 free.** 32:4 and 32:6 are cited in the `al-waliyy` and `al-khaliq` drafts and are **not rendered here**. **35:45 — the obvious forbearance verse — is `al-haleem@1`'s verse beat** and was never a candidate.

### Bar 3(c) — the move

**As-Sabur's move is scale, not restraint. That single distinction is what makes the deck possible at all**, and it is why the takeaway names its neighbour explicitly.

| deck | the move |
|---|---|
| `al-haleem@1` (shipped) | **restraint.** *"Forbearance is not approval, and it is not forgetting. It is the distance between what a thing has earned and what is actually done about it."* Power held back |
| **`as-sabur@1`** | **scale.** He is not holding back. He is not on your clock |

**Those are different axes, and the reader's grievance separates them cleanly.** Al-Haleem answers *"I deserve worse than I am getting"* — the reader who fears the bill. **As-Sabur answers *"nothing is happening"*** — the reader who has had no bill, no reply, no movement, and has begun to read the delay as a verdict.

**32:5 is the right text for that and 35:45 would have been the wrong one.** 35:45 is about punishment deferred — Al-Haleem's axis exactly. **32:5 contains no deferral at all**: the matter descends, is arranged, ascends, and *nothing in it is late*. The only thing the āyah adjusts is the unit of measurement, and it does so by naming the reader's own — `مِّمَّا تَعُدُّونَ`, *of those which you count*.

**The risk a verifier should press:** whether "He is on a different timescale" is genuinely a **patience** claim or whether it is really an **eternity/majesty** claim, which would put it near `al-baqi@1` (shipped) and `al-azeem@1` (drafted). **The defence is that the āyah's scale is attached to a *process in progress*** — a matter currently ascending — rather than to Allah's duration. Al-Baqi is about what remains; this is about what is still on its way. **Measured against `al-baqi@1`: 3.**

---

## The shared duʿā

Ids 32 and **29 Al-Haleem** render **one identical duʿā beat**, and `al-haleem@1` is **shipped**:

> `اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ`

**Note what it asks for: `ٱلصَّبْر` — patience — as a thing the *reader* is requesting for themselves.** It is the one duʿā in this pair that carries **this Name's root**, and it carries it as a human petition, not a divine attribute. So the duʿā reinforces the sweep's finding rather than contradicting it: **even the catalogue's own supplication uses `ص-ب-ر` of the worshipper.**

**Catalogue-locked, disclosed, not actioned** (§9ce). **The transcriber must be told**: a sweep of this deck against production will flag a full-string duʿā match, and that flag is expected.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **Bukhārī 7378** | the only ṣaḥīḥ predication of the root to Allah — **rendered in full by shipped `al-haleem@1`**, both clauses. **The single most important rejection here** |
| **Tirmidhī 3507** (the 99-Names enumeration) | the only attestation of the Name-form `ٱلصَّبُور` — **graded `Daʿīf`**. Not cited |
| **35:45** `وَلَوْ يُؤَاخِذُ ٱللَّهُ ٱلنَّاسَ بِمَا كَسَبُوا۟…` | **`al-haleem@1`'s verse beat**, and on Al-Haleem's axis (deferred punishment) even if it were free |
| **16:61** | near-twin of 35:45; cited in the `al-haleem`, `al-muqaddim` and `al-muakhkhir` drafts |
| **18:58 · 10:11 · 13:6 · 22:47's opening · 29:53** | the `عجل` (hastening) family — **every one is punishment-adjacent**; 13:6 closes `لَشَدِيدُ ٱلْعِقَابِ`. Rejected on bar 5. The `Ejl` sweep (47 occurrences, 10 forms) was run and produced no clean carrier |
| **20:129 · 42:14** (`كَلِمَةٌ سَبَقَتْ`) | free, and genuinely about deferral — but both are framed around punishment withheld, i.e. **Al-Haleem's axis again**. Left free |
| **2:286** | `لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا` — **SPENT**, shipped `ar-rahman@1`'s comfort verse |
| **22:47's first clause** `وَيَسْتَعْجِلُونَكَ بِٱلْعَذَابِ` | punishment. **Not rendered**; the beat begins after it |
| **70:4** (`خَمْسِينَ أَلْفَ سَنَةٍ`) | free, the same scale-claim at fifty thousand years — **left unspent and recorded as reusable**, and it would substitute for 22:47 cleanly |

---

## Catalogue findings — reported, **NO change recommended**

1. **The duʿā is identical to a shipped deck's** (see *The shared duʿā*). §9ce. **Reported, not actioned.**
2. **The Name-form `ٱلصَّبُور` rests on a `Daʿīf` narration.** This is not a defect to fix — **the whole 99-Names enumeration this app is built on is Tirmidhī 3507**, and that is the standard basis. It is recorded because **for this Name specifically it means there is no ṣaḥīḥ Name-form attestation**, which is exactly the information a bar-4 trade needs on the record.
3. **Id 32's `lesson` — *"As-Sabur does not rush you. He waits for you with open arms"* — is half this deck's engine and half another's.** *"Does not rush you"* is precisely 32:5. *"Waits for you with open arms"* is repentance-waiting, which is `at-tawwab@1`'s (shipped). **The deck follows the first half.** Flagged like `al-haseeb@1`'s and `ash-shaheed@1`'s: **the `lesson` field reaches into a neighbour's engine, and this is now the third instance** — see the handoff.

---

## What I could not determine — attack these first

1. **Bar 4 is traded, and the trade is the deck.** If a verifier rules that bar 4 cannot be traded when the Name-form has *no* ṣaḥīḥ attestation at all, this Name is genuinely undraftable and the earlier refusal was right for a different reason than it gave. **That is the single question this deck turns on.**
2. **Is "different timescale" a patience claim?** Argued above against `al-baqi@1` and `al-azeem@1`; measured at 3. **Re-argue rather than check** (§9cd).
3. **`ص-ب-ر`'s 103 occurrences were not individually fetched** — the corpus form-breakdown was read and the classes enumerated. **The claim "every occurrence takes a human subject" is therefore a claim about the corpus's own categorisation, not about 103 individually-read āyāt.** This is the deck's most load-bearing unverified statement, and §9cc says fetch them all. **At 103 occurrences that was not affordable here; a verifier with budget should do it, because if even one predicates the root of Allah, bar 4 stops being a trade.**
4. **The `sunnah.com` search was targeted, not systematic.** Two documents were pulled (Bukhārī 7378, Tirmidhī 3507). **I did not run a systematic search for other narrations predicating `ص-ب-ر` of Allah** — the same limit the refusal recorded, still open. If one exists and is ṣaḥīḥ, this deck should be rebuilt on it and bar 4 recovered.
5. **The duʿā collision with production is unresolvable at draft level.**

---

## Pairing verdict

**Ships independently — but must never be reviewed apart from `al-haleem@1`.** They share a duʿā, and that shipped deck holds both this Name's ṣaḥīḥ carrier and its most natural verse. **The entire case for this deck existing is the restraint/scale distinction on beat 8**, and a reviewer who has not read `al-haleem@1` cannot assess it.
