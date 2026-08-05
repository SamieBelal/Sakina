# Deck Draft — Al-Wali (catalogue id 83) — **R0, awaiting independent blind verification**

> ⚠️ **`ٱلْوَالِي` occurs once in the Qurʾān** — 13:11 — and there it is a **negative construction**: *"there is not for them besides Him any patron."* **`al-waliyy@1` (drafted) explicitly rejected 13:11 for exactly that.** This deck takes it as the **verse beat only** and carries bars 1–2 elsewhere. See the bars note.
>
> **Not to be confused with `al-waliyy@1`** (`ٱلْوَلِىّ`, a different Name from the same root, drafted this session).

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/83.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-wali@1` — Al-Wali

**Why this deck exists, in one line:** the user holding a situation together by attention alone, who has come to believe that if they stop thinking about it, it will fall.

**The reader's position:** **at the controls, and exhausted by it.** Not asking to be rescued. Asking whether anyone else is actually running this.

**Proposed metadata**

```json
{
  "deck_id": "al-wali@1",
  "name_id": 83,
  "transliteration": "Al-Wali",
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
> You have been holding a situation together by attention alone, as though letting go of it would let it fall.

**Beat 2 · name_intro** *(catalogue id 83 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْوَالِي — Al-Wali — The Governor

**Beats 3–5 · story — "Arranging the Matter"** *(Qur'an 10:3)*:
> 3. Allah says: "Indeed, your Lord is Allah, who created the heavens and the earth in six days and then established Himself above the Throne…"
> 4. "…arranging the matter [of His creation]."
> 5. One phrase, present tense, with no object named. Not arranged, once, long ago. Arranging — continuously, all of it, now, including the part you are lying awake about.

**Beat 6 · verse** *(partial quotation — the closing clause, visible ellipsis; **the Name's only Qurʾānic occurrence**)*:
> …And there is not for them besides Him any patron. — Qur'an 13:11

**Beat 7 · duʿā** *(catalogue id 83, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا وَالِي كُنْ لِي وَلِيًّا حِينَ يَبْتَعِدُ الدُّنْيَا عَنِّي وَتَوَلَّ أَمْرِي كُلَّهُ
> *Ya Wali, kun li waliyyan hina yabtab'idud-dunya 'anni wa-tawalla amri kullahu*
> "O Governor, be my protector when the world drifts away. Guard me with the grip that never slips and guide me gently through what I do not understand."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Waliyy is the ally who is on your side. Al-Wali is the One running the place, and the difference matters at three in the morning: you are not asking to be defended. You are asking whether anybody is at the controls.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What are you supervising tonight that is already being administered?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Indeed, your Lord is Allah, who created the heavens and the earth in six days and then established Himself above the Throne, arranging the matter [of His creation]."* (beats 3–5, **bar-1 carrier**) | `.../10:3` | ✅ `إِنَّ رَبَّكُمُ ٱللَّهُ ٱلَّذِى خَلَقَ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ فِى سِتَّةِ أَيَّامٍ ثُمَّ ٱسْتَوَىٰ عَلَى ٱلْعَرْشِ ۖ يُدَبِّرُ ٱلْأَمْرَ` — rendered to that pause. The intercession and `فَٱعْبُدُوهُ` clauses **not rendered** |
| 2 | *"…And there is not for them besides Him any patron."* (beat 6, **bar-4 carrier**) | `.../13:11` | ✅ `وَمَا لَهُم مِّن دُونِهِۦ مِن وَالٍ` — **the Name's only Qurʾānic occurrence**, and a negation. Everything before it in 13:11, **including `وَإِذَآ أَرَادَ ٱللَّهُ بِقَوْمٍ سُوٓءًا`, is not rendered** |
| 3 | Successor sweep n−1: 10:2 | `.../10:2` | ⚠️ disbelievers call the Prophet a magician. **Not rendered** |
| 4 | Successor sweep n+1: 10:4 | `.../10:4` | ⚠️ ends `شَرَابٌ مِّنْ حَمِيمٍ وَعَذَابٌ أَلِيمٌ`. **Not rendered** |
| 5 | Cross-check: the 13:11 rejection ⚠️ **R3 correction — it is in the DRAFT, not in the shipped deck.** Shipped `al-waliyy@1` never touches 13:11; its verse beat is **93:6** and its story is Tirmidhī 3438, read directly from `name_stories.json`. The rejection lives in the unshipped `2026-08-03-al-waliyy-DRAFT.md` | `2026-08-03-al-waliyy-DRAFT.md` (pending) | ⚠️ it **rejected** 13:11 under *"Negative construction"*. This deck takes it knowingly, as a verse beat only |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **10:3** `يُدَبِّرُ ٱلْأَمْرَ` — Allah's own narration, **present tense, continuous**, with the administration stated as ongoing rather than completed | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **sets a scale and then a verb** — the heavens and earth made, the Throne established, *and then* `يُدَبِّرُ ٱلْأَمْرَ`, arranging, now. Governance is shown as a continuing activity, not an office held | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — but the `al-waliyy@1` boundary is the thing to check** |
| 4 | Root in the quoted text | ⚠️ **split.** 10:3 carries `د-ب-ر`, **not** this Name's root. **13:11's `وَالٍ` on the verse beat carries `و-ل-ي` in the Name's own form** | ⚠️ **PASS via the verse beat only, and via a negation** |
| 5 | Register and reverence | ⚠️ 10:2 is polemic (*this is an obvious magician*); **10:4 ends in `عَذَابٌ أَلِيمٌ`.** On the verse-beat side 13:11 itself contains `وَإِذَآ أَرَادَ ٱللَّهُ بِقَوْمٍ سُوٓءًا` | ⚠️ **PASS — none of it rendered, but 13:11 is rendered in part** |

**The Name-form problem, stated plainly.** `ٱلْوَالِي` occurs **exactly once**, at 13:11, and the clause is `وَمَا لَهُم مِّن دُونِهِۦ مِن وَالٍ` — *"there is not for them besides Him any patron."* **It is a negation, and `al-waliyy@1` rejected 13:11 on precisely that ground** (its rejection table lists it under *"Negative construction"* alongside 2:107, 32:4 and 33:17).

**This deck takes it anyway, as the verse beat only, and the argument is narrow:** a negation of all alternatives **is** a positive claim about the one remaining — `مِن دُونِهِ` names Him as the sole holder of the office. It is weaker than a demonstration and it is **not** asked to carry bar 1. **Bar 1 is carried by 10:3.**

**A second disclosure about 13:11:** the āyah also contains `وَإِذَآ أَرَادَ ٱللَّهُ بِقَوْمٍ سُوٓءًا فَلَا مَرَدَّ لَهُۥ` — *when Allah intends ill for a people, there is no repelling it.* **Not rendered.** The beat takes the final clause only, after the āyah's own pause. **A reader who looks up 13:11 lands on that sentence**, and it is a real exposure — one this deck cannot remove, because 13:11 is the Name's only occurrence.

**Bar 5 on the carrier.** **10:2** ends with disbelievers calling the Prophet a magician; **10:4** ends `شَرَابٌ مِّنْ حَمِيمٍ وَعَذَابٌ أَلِيمٌ`. **Neither rendered**, and the deck's story stops inside 10:3.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 5.** **5** — *"heavens and the earth"* (vs `al-aleem@1`'s duʿā beat, `فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ`). **A fixed Qurʾānic construct; §9bl forbids translation-shopping around it.** Disclosed, not clean. Every other hit is a function-word run.

**Every āyah checked against the shipped asset *and* all 48 pending drafts**, two-sided boundary match: **10:3 free · 13:11 cited in three drafts** — `al-waliyy` (which **rejected** it), `ar-raqeeb` and `al-hafeez`-adjacent sweeps — **and rendered by none.** 13:2 is cited in the `ar-rafi` draft; 32:5 is `as-sabur@1`'s carrier and was not available.

### Bar 3(c) — the move

**Al-Wali's move is administration, not allegiance.**

`يُدَبِّرُ ٱلْأَمْرَ` — *arranging the matter* — present tense, no object specified, therefore all of it. The reader is not asking to be defended or preferred. **They are asking whether the thing is being run**, and 10:3 answers that the running is continuous and is not theirs.

**Against `al-waliyy@1` (drafted, same root) — the boundary that matters most here:**

| deck | the move |
|---|---|
| `al-waliyy@1` (`ٱلْوَلِىّ`) | **the ally** — the One on your side, close, partisan |
| **`al-wali@1`** (`ٱلْوَالِي`) | **the governor** — the One running the place, whether or not you feel accompanied |

**One is relational; the other is administrative.** The catalogue's own gloss says so — id 83 is *"The Governor"* and its `lesson` is *"Al-Wali is running everything. You can rest."* **The rest is the point: this deck's consolation is that the reader can stop supervising, not that they are being taken sides with.**

**Against `al-qayyum@1` (shipped):** the Sustainer holds things **in existence**. Al-Wali **directs** them. Being upheld and being administered are different claims, and only the second answers *"is anyone steering?"*

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **13:11 as the bar-1 carrier** | a **negation**, and `al-waliyy@1` rejected it as such. Used as the verse beat only |
| **32:5** `يُدَبِّرُ ٱلْأَمْرَ …` | the same governance verb — **`as-sabur@1`'s carrier**, drafted this session |
| **13:2** `يُدَبِّرُ ٱلْأَمْرَ يُفَصِّلُ ٱلْـَٔايَـٰتِ` | free of rendering but **cited in the `ar-rafi` draft**, and its opening (`رَفَعَ ٱلسَّمَـٰوَٰتِ`) is that Name's root |
| **10:31** `وَمَن يُدَبِّرُ ٱلْأَمْرَ` | inside a `قُلْ`-framed interrogation of the disbelievers (§9bk) |
| **2:107 · 32:4 · 33:17** | the other negative `وَلِىّ`/`وَالٍ` constructions — **`al-waliyy@1`'s rejected set**. Left |
| **10:2 · 10:4** | polemic and `عَذَابٌ أَلِيمٌ`. **Never rendered** |

---

## Catalogue findings — reported, **NO change recommended**

1. **Ids 55-adjacent naming collision:** the catalogue lists **both `ٱلْوَلِىّ` and `ٱلْوَالِي`** as separate Names from one root, and **only one of them (`ٱلْوَالِي`) has a single, negative Qurʾānic occurrence.** Reported, **not actioned** — the enumeration is the standard one.
2. **Id 83's duʿā asks for both moves at once** — *"be my protector when the world drifts away"* (Al-Waliyy's register) and *"take charge of my whole affair"* (this deck's). **The duʿā does not separate the two Names the way the decks must.** Noted; no change recommended.

---

## What I could not determine — attack these first

1. **Bar 4 rests on a single negative occurrence**, which another drafter rejected on principle. **If a verifier agrees with `al-waliyy@1`, this deck's bar 4 collapses to a full trade** — recoverable (the As-Sabur precedent) but it should be decided, not assumed.
2. **13:11's `سُوٓءًا` clause is unavoidable exposure** — the Name's only occurrence sits in that āyah.
3. **The `al-waliyy@1` boundary is argued, same session, same author** (§9cd).
4. **`و-ل-ي` has 232 occurrences in 12 forms and was not swept** — it is overwhelmingly `al-waliyy@1`'s ground and the `ٱلْوَالِي` form was located directly. **Incomplete on the root by design, and stated as such.**
5. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Must be reviewed with `al-waliyy@1`.** They are one root and two catalogue Names; a reviewer seeing only one cannot judge the split.
