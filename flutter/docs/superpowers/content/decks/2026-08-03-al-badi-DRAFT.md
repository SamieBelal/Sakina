# Deck Draft — Al-Badi (catalogue id 97) — **R0, awaiting independent blind verification**

**No shared duʿā.** An independent single — but its ground was **deliberately reserved for it**: `al-ahad@1`'s draft elided `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` from 2:117 precisely to leave it here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/97.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-badi@1` — Al-Badi

**Why this deck exists, in one line:** the user who has run out of ways to imagine it working out, and has mistaken that for information about whether it can.

**The reader's position:** **out of mechanisms.** They are not doubting His power in the abstract. They cannot see the route.

**Proposed metadata**

```json
{
  "deck_id": "al-badi@1",
  "name_id": 97,
  "transliteration": "Al-Badi",
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
> You have been trying to picture how it could possibly work out, and coming up empty. That is a fact about picturing.

**Beat 2 · name_intro** *(catalogue id 97 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْبَدِيعُ — Al-Badi — The Originator of the Heavens

**Beats 3–5 · story — "One Word Wide"** *(Qur'an 2:117)*:
> 3. Allah says: "Originator of the heavens and the earth."
> 4. "When He decrees a matter, He only says to it: 'Be' — and it is."
> 5. No material is named. No process is described. The distance between the decree and the thing is one word wide.

**Beat 6 · verse** *(partial quotation — the second clause of the carrier, visible ellipsis)*:
> …When He decrees a matter, He only says to it: 'Be' — and it is. — Qur'an 2:117

**Beat 7 · duʿā** *(catalogue id 97, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا بَدِيعَ السَّمَاوَاتِ وَالْأَرْضِ أَنْتَ وَلِيِّي فَاغْفِرْ لِي
> *Ya Badi'as-samawati wal-ard, anta waliyyi faghfir li*
> "O Originator of the heavens and the earth, You are my protector — so forgive me."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Khaliq makes. Al-Musawwir gives the made thing its particular form. Al-Badi is earlier than either: there was no precedent for the thing to be made from. What you cannot picture is not evidence about what is possible.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you ruled out because you could not see the mechanism?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Originator of the heavens and the earth."* (beat 3, **bar-4 carrier**) | `.../2:117` | ✅ `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` — first clause. **Reserved for this deck by `al-ahad@1`**, which elided it |
| 2 | *"When He decrees a matter, He only says to it: 'Be' — and it is."* (beats 4–6, **bar-1 carrier**) | `.../2:117` | ✅ `وَإِذَا قَضَىٰٓ أَمْرًا فَإِنَّمَا يَقُولُ لَهُۥ كُن فَيَكُونُ` — second clause |
| 3 | Successor sweep n−1: 2:116 | `.../2:116` | ⚠️ polemic — *they say Allah has taken a son*, answered `سُبْحَـٰنَهُۥ`. **No punishment. Not rendered** |
| 4 | Successor sweep n+1: 2:118 | `.../2:118` | ✅ people demanding a sign; closes `قَدْ بَيَّنَّا ٱلْـَٔايَـٰتِ لِقَوْمٍ يُوقِنُونَ`. Not rendered |
| 5 | Root sweep — **complete at 4 occurrences** | `corpus…?q=bdE` | ✅ 57:27 (human), 46:9 (the Prophet), **2:117 and 6:101 — the only two predications of Allah, and the same two words** |
| 6 | Cross-check against production | `assets/content/name_stories.json` | ⚠️ **shipped `al-aleem@1`'s duʿā renders *Originator of the heavens and the earth*** — id 97's exact `english` gloss, from a different root (`ف-ط-ر`) |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **2:117** — Allah's own narration, and the second clause is a **described act**: `وَإِذَا قَضَىٰٓ أَمْرًا فَإِنَّمَا يَقُولُ لَهُۥ كُن فَيَكُونُ` | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **shows the mechanism by having none** — decree, one word, existence. The absence of an intermediate step is the demonstration | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — with a disclosed 7-word scripture run** |
| 4 | Root in the quoted text | `ب-د-ع` as `بَدِيعُ`, the Name's own form, in the rendered text | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ n−1 (2:116) is polemic — *they say Allah has taken a son* — answered by `سُبْحَـٰنَهُۥ`; n+1 (2:118) is mild. **Neither rendered** | ⚠️ **PASS** |

**The root sweep is complete, and it is the second-shortest in the project.** `corpus?q=bdE` — *"occurs **four times** in the Quran, in three derived forms"*: `ٱبْتَدَعُوهَا` (57:27, human innovation), `بِدْعًا` (46:9, *I am not something original among the messengers*), and **`بَدِيعُ` twice — 2:117 and 6:101, both the identical construct `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ`.**

So **the Name is predicated of Allah exactly twice, in the same two words**, and the choice between them is decided by what follows: **2:117 continues into `كُن فَيَكُونُ`** — an act — while **6:101 continues into `أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ`**, a polemic about offspring. **2:117 is the only one of the two that can carry bar 2.**

**Bar 5, fetched.** **2:116** is `وَقَالُوا۟ ٱتَّخَذَ ٱللَّهُ وَلَدًا ۗ سُبْحَـٰنَهُۥ` — a claim reported and immediately refuted, **no punishment**. **2:118** is people demanding a sign, closing `قَدْ بَيَّنَّا ٱلْـَٔايَـٰتِ لِقَوْمٍ يُوقِنُونَ`. **Neither rendered.** The exposure is polemic adjacency, not punishment adjacency, and it is the mildest bar-5 finding in this wave.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 7.** **7** — *"of the heavens and the earth"*, against **shipped `al-aleem@1`'s duʿā beat** (`فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ`, rendered *Originator of the heavens and the earth*). **This is a fixed Qurʾānic construct and §9bl forbids translation-shopping around it.** See the catalogue finding — it is sharper than the n-gram suggests.

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **2:117 cited in the `al-ahad` draft — and that citation is the reservation**, not a claim: `al-ahad@1` elided this clause deliberately to leave it here. **6:101 free and left.**

### Bar 3(c) — the move

**Al-Badi's move is that there was no precedent for the thing to be made from.**

The reader has confused *I cannot see how* with *there is no how.* **2:117 answers by removing the middle**: a decree, one word, and the thing exists. **No material is named. No process is described.** The gap between the intention and the object is a single imperative wide.

**Against `al-khaliq@1` (shipped):** the Creator **makes** — seven verbs, stages, clay, a sperm-drop, bone and flesh. **Process is that deck's whole engine.** Al-Badi is what happens where there is no process and no precedent.

**Against `al-musawwir@1` (drafted):** particularity of form, applied to something already being made. **Al-Badi is prior to both** — the originating, where nothing like it existed to copy.

**Against `al-bari@1` (drafted, id 20):** that Name is **precedence in time** — the register was written before the thing was brought into being. **This one is precedence in kind** — there was nothing of its type before it. Adjacent and genuinely different, and the two drafts were written in the same session, so **a verifier should re-argue this pair rather than check it.**

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **6:101** `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ` | the Name's only other occurrence — **the same two words**, but it continues into polemic about offspring rather than into an act. **Cannot carry bar 2.** Left free |
| **57:27** `ٱبْتَدَعُوهَا` | **human** innovation (monasticism). The root, wrong subject |
| **46:9** `مَا كُنتُ بِدْعًا مِّنَ ٱلرُّسُلِ` | the **Prophet** saying he is not unprecedented. The root, pointed away from Allah |
| **2:117's first clause as the verse beat** | it is rendered as beat 3; the **verse beat takes the second clause** so the two beats do not duplicate |

---

## Catalogue findings — reported, **NO change recommended**

1. **Shipped `al-aleem@1`'s duʿā renders this Name's exact English gloss.** Its Arabic is `فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ` — root `ف-ط-ر`, a **different** Name — but its rendered English is *Originator of the heavens and the earth*, which is **word-for-word id 97's catalogue `english`** (*The Originator of the Heavens*). **So a user who has collected Al-Aleem has already read this Name's gloss, attached to a different Name.** Reported, **not actioned** — both strings are locked, and the collision is in the English only. **But it is the reason this deck's max run is 7 and the number is not a drafting defect.**
2. **Id 97's `english` is a truncation.** *The Originator of the Heavens* drops *"and the Earth"*, which is in the Arabic construct and in every rendering. The deck renders the catalogue string verbatim regardless (§9bz). **Reported, not actioned.**

---

## What I could not determine — attack these first

1. **The `ف-ط-ر` / `ب-د-ع` English collision** (catalogue finding 1) is the deck's most awkward fact and cannot be fixed at draft level.
2. **The `al-bari@1` separation — precedence in *time* vs precedence in *kind*** — is fine and was decided by the same author in the same session. **Re-argue it** (§9cd).
3. **The root sweep is complete at 4 occurrences.** One of the few bars this deck can claim without qualification.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Should be reviewed near `al-bari@1` and `al-khaliq@1`, which sit on the same conceptual ground.
