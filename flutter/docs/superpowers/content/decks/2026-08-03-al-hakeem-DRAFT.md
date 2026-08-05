# Deck Draft — Al-Hakeem (catalogue id 26) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-khabeer-DRAFT.md`](./2026-08-03-al-khabeer-DRAFT.md).** Ids 26 and 49 **share one locked `dua_arabic`** (§9ce) — and **that duʿā invokes neither of them**: its vocative is `يَا لَطِيفُ`, **Al-Lateef's**, and `al-lateef@1` is already shipped. See *The shared duʿā*.

**The two decks divide one āyah.** 34:1 closes `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ` — both Names in one clause — so each renders its own word and neither renders the other's, on the `al-malik@1`/`al-muizz@1`/`al-muzill@1` precedent (3:26).

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/26-49.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-hakeem@1` — Al-Hakeem

**Why this deck exists, in one line:** the user who has been asking why, getting nothing back, and has started to read the silence as evidence that there is no reason.

**The reader's position, which is what separates this deck from its neighbours:** **owed an explanation.** Not doubting that He can act, and not doubting that He knows — doubting that what happened had a reason at all.

**Proposed metadata**

```json
{
  "deck_id": "al-hakeem@1",
  "name_id": 26,
  "transliteration": "Al-Hakeem",
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
> You have been asking why, and getting nothing back. The absence of an answer is not the absence of a reason.

**Beat 2 · name_intro** *(catalogue id 26 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْحَكِيمُ — Al-Hakeem — The All-Wise

**Beats 3–5 · story — "The Sentence in the Middle of the Fractions"** *(Qur'an 4:11)*:
> 3. Inside the inheritance law — the driest passage in the Qur'an, all fractions and shares — Allah stops and says something else.
> 4. "Your parents or your children — you know not which of them are nearest to you in benefit."
> 5. That is why the shares are fixed and not left to you. Not because your judgement is bad. Because the information you would need is not available to you, and is available to Him.

**Beat 6 · verse** *(partial quotation — **one word** of a two-Name clause, ellipsis both sides)*:
> …And He is the Wise… — Qur'an 34:1

**Beat 7 · duʿā** *(catalogue id 26, **byte-for-byte**, asserted programmatically (§9cb)) — **RECUT 2026-08-05**, see §The shared duʿā*:
> لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ اللَّهُ أَكْبَرُ كَبِيرًا وَالْحَمْدُ لِلَّهِ كَثِيرًا سُبْحَانَ اللَّهِ رَبِّ الْعَالَمِينَ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَزِيزِ الْحَكِيمِ
> *La ilaha illallahu wahdahu la shareeka lah, Allahu akbaru kabeera, wal-hamdu lillahi katheera, subhanallahi rabbil 'alameen, la hawla wa la quwwata illa billahil 'Azeezil Hakeem*
> "There is no god but Allah, the One, having no partner with Him. Allah is the Greatest of the great and all praise is due to Him. Exalted is Allah (He is free from imperfection), the Lord of the worlds, there is no Might and Power but that of Allah, the All-Powerful and the Wise." — Sahih Muslim 2696

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Aleem is that He knows. Al-Hakeem is what He does with knowing — the ordering that follows from it. The verse does not tell you the reason for your share. It tells you that a reason exists, that it is about benefit, and that you were never in a position to compute it.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What have you been trying to work out that you do not actually have the information for?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Your parents or your children — you know not which of them are nearest to you in benefit"* (beats 3–5, **bar-1 and bar-4 carrier**) — **R1 fix:** R0 read *"is nearer"*, which is the 1997 Saheeh printing; `translations=20` as served today reads *"are nearest"*, and the beat now matches the source the table claims to have fetched | `.../4:11` | ✅ `ءَابَآؤُكُمْ وَأَبْنَآؤُكُمْ لَا تَدْرُونَ أَيُّهُمْ أَقْرَبُ لَكُمْ نَفْعًا ۚ فَرِيضَةً مِّنَ ٱللَّهِ ۗ إِنَّ ٱللَّهَ كَانَ عَلِيمًا حَكِيمًا` — **the clause only.** The inheritance fractions themselves are described, never quoted |
| 2 | *"…And He is the Wise…"* (beat 6) | `.../34:1` | ✅ `ٱلْحَكِيمُ` — **one word** of `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ`, ellipsis both sides. `ٱلْخَبِيرُ` **left to `al-khabeer@1`** |
| 3 | Successor sweep n−1: 4:10 | `.../4:10` | ⚠️ **Fire** — `يَأْكُلُونَ فِى بُطُونِهِمْ نَارًا ۖ وَسَيَصْلَوْنَ سَعِيرًا`. **Not rendered.** The deck's weakest point |
| 4 | Successor sweep n+1: 4:12 | `.../4:12` | ✅ more inheritance shares. No punishment |
| 5 | Successor sweep n+1 of the verse beat: 34:2 | `.../34:2` | ✅ closes `وَهُوَ ٱلرَّحِيمُ ٱلْغَفُورُ`. 34:1 is **sūrah-opening**, so there is no n−1 within the sūrah |
| 6 | The locked duʿā (shared with id 49) | `collectible_names.json` id 26 | ✅ all three fields asserted present (§9cb). **Its vocative is Al-Lateef's** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **4:11** — Allah's own voice (`يُوصِيكُمُ ٱللَّهُ`), and the clause the deck renders is Allah stating what the addressee cannot know | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **interrupts a legal enumeration to give the reason for it** — `لَا تَدْرُونَ أَيُّهُمْ أَقْرَبُ لَكُمْ نَفْعًا`. The wisdom is demonstrated as *the cause of a ruling being fixed rather than delegated*, not asserted as a quality | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ح-ك-م` as `حَكِيمًا` in the rendered clause of 4:11, and as `ٱلْحَكِيمُ` on the verse beat (34:1) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **n−1 (4:10) is a Fire āyah**; n+1 (4:12) is more inheritance law, clean | ⚠️ **PASS — predecessor never rendered** |

**Bar 5 finding, stated not smoothed.** **4:10**, immediately before the carrier, reads `إِنَّ ٱلَّذِينَ يَأْكُلُونَ أَمْوَٰلَ ٱلْيَتَـٰمَىٰ ظُلْمًا إِنَّمَا يَأْكُلُونَ فِى بُطُونِهِمْ نَارًا ۖ وَسَيَصْلَوْنَ سَعِيرًا` — *"…are only consuming into their bellies fire. And they will be burned in a Blaze."* **This is the harshest predecessor of any carrier in this wave.**

**Three things make it survivable, and they are checks rather than inferences.** (i) **Nothing of 4:10 is rendered or alluded to** — the deck begins inside 4:11. (ii) The rebuke is aimed at a **specific act of exploitation**, not at the reader, and the reader of this deck is the bereaved party in an inheritance, not the devourer of one. (iii) **4:12, the successor, is clean** — more shares, no punishment. **A verifier should still treat this as the deck's weakest point**, and it is the reason the beats deliberately open by naming the passage as *legal* rather than by quoting into it.

**Why the Name's own form could not carry bar 1.** `ح-ك-م` is the largest root in this project — **210 occurrences** — and `ٱلْحَكِيم` predicated of Allah is **overwhelmingly a trailing epithet in a pair**: `ٱلْعَزِيزُ ٱلْحَكِيمُ`, `ٱلْعَلِيمُ ٱلْحَكِيمُ`, `حَكِيمٍ خَبِيرٍ`. Those label; they do not demonstrate (§9bk). **4:11 is different because the wisdom is the āyah's stated reason for its own content** — the epithet arrives *after* an explanation, not instead of one.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4** — the only hit is *"he is the"* (vs `al-wakeel@1`), a function-word run. **No finding.** An earlier revision measured **5** — *"the middle of the"* against `al-basit@1`'s story — and beat 3 was rewritten.

**Twin-diff vs `al-khabeer@1`** (the pair-partner): **4** — *"he is the"*, from the two decks' verse beats, which are the two halves of one clause. Expected and disclosed; the halves are different words.

**Every āyah checked against the shipped asset *and* all 34 pending drafts**, two-sided boundary match: **4:11 free · 34:1 free** — no shipped deck, no pending draft. **2:216** (the *"perhaps you hate a thing"* wisdom āyah) is **cited in the `al-aleem` draft** and its root is `ع-ل-م`, not this Name's. **6:18** (`ٱلْحَكِيمُ ٱلْخَبِيرُ`) is cited in the `ad-darr` and `al-qahhar` drafts.

### Bar 3(c) — the move

**Al-Hakeem's move is that a reason exists, is about benefit, and was never computable by you.**

The reader's error is treating an unexplained outcome as an unreasoned one. **4:11 answers that in the least sentimental place in the Qurʾān** — the middle of inheritance fractions — which is exactly why it works: nobody can accuse the āyah of consoling. It is doing administration, and it stops to say *why* the shares are fixed: `لَا تَدْرُونَ أَيُّهُمْ أَقْرَبُ لَكُمْ نَفْعًا`.

**Against `al-aleem@1` (shipped)**, the nearest neighbour: Al-Aleem's move is **knowledge preceding evidence** — *"He already knew what she had delivered, before anything had proved it."* **Al-Hakeem's is what follows from knowing** — an ordering. Knowledge is a state; wisdom is a disposition of things. The deck's takeaway carries that distinction explicitly, because without it the two Names are one.

**Against the pair-partner `al-khabeer@1`:** Al-Khabeer is **what He knows about you that others cannot see**. Al-Hakeem is **what He arranges that you could not have arranged**. One is depth of information, the other is use of it.

---

## The shared duʿā — **RESOLVED for id 26, 2026-08-05**

Ids 26 and 49 used to render **one identical duʿā beat**, and it was the strangest
in the catalogue:

> `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا` — *"O Allah, O Gentle One, be gentle with me in all my affairs."*

**Neither Name appeared in it.** The vocative is `يَا لَطِيفُ` — **Al-Lateef**, whose
deck `al-lateef@1` is already shipped with a *different* duʿā of its own. So two
decks about wisdom and awareness both closed on a plea to a **third** Name.

**Now actioned for id 26** (founder-directed, 2026-08-05). Full research in
[`2026-08-05-DUA-COLLISION-RESEARCH.md`](./2026-08-05-DUA-COLLISION-RESEARCH.md).

**Ṣaḥīḥ Muslim 2696**, Book 48 (*Dhikr, Supplication, Repentance and Istighfār*),
Ḥadīth 43, chapter *"The Virtue Of Tahlil, Tasbih And Du'a"*. A bedouin asks the
Prophet ﷺ to **teach him words to say** — the strongest provenance a duʿā beat can
have, since it is the Prophet ﷺ prescribing a supplication rather than a narrator
reporting one. Verified by fetching `sunnah.com/muslim:2696` **individually**, not
off the book-listing page.

**Why it fits this deck specifically:** the occasion is a man who **could not work
out what to say**, being taught — and `لَا حَوْلَ وَلَا قُوَّةَ` is the surrender of
exactly the working-out that beat 5 and beat 9 name. The Name is invoked in the
closing clause, `بِاللَّهِ الْعَزِيزِ الْحَكِيمِ`.

**Two costs, both accepted and stated:**

1. **It also names Al-ʿAzīz (id 8).** Unavoidable, not a compromise — al-Ḥakīm
   **never appears alone in any supplication**, in the Qurʾān or the ḥadīth
   corpus. Every duʿā-form containing it pairs it (2:32 `ٱلْعَلِيمُ ٱلْحَكِيمُ`;
   2:129 / 5:118 / 60:5 `ٱلْعَزِيزُ ٱلْحَكِيمُ`). A two-Name duʿā is the only form
   that exists.
2. ⚠️ **208 characters** against a catalogue median of 70 and a previous maximum
   of 125 (`ash-shafi@1`). `BeatScreenView` is center-until-overflow over a
   `SingleChildScrollView`, so it renders and scrolls rather than clipping — but
   **the collectible-card surface has not been checked and should be, on device,
   before this ships.**

**Id 49 (`al-khabeer@1`) keeps the `yā Laṭīf` duʿā and keeps this disclosure.**
That is not an omission: **no authentic supplication invoking Al-Khabeer exists.**
All 43 Qurʾānic occurrences of the Name-form are declarative, and `يا خبير` returns
zero across the supplication chapters of six collections. Its only ḥadīth
appearances are inside the 99-Names enumeration, which is a list rather than a
prayer and is `Daʿīf`. Al-Lateef is at least its **Qurʾānic pair** (`لَطِيفٌ خَبِيرٌ`,
6:103 · 22:63 · 31:16 · 33:34 · 67:14), which is how the drift happened.

**Still open (founder):** ids **62 / 63** (`al-qawiyy`, `al-mateen`) share
`لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ`, which invokes
**Al-ʿAliyy (52)** and **Al-ʿAẓīm (50)** and neither of them. **Same defect,
already shipped.**

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **2:216** `وَعَسَىٰٓ أَن تَكْرَهُوا۟ شَيْـًٔا وَهُوَ خَيْرٌ لَّكُمْ` | **the most famous wisdom āyah, and it is not this Name's.** Its root is `ع-ل-م` (`وَٱللَّهُ يَعْلَمُ وَأَنتُمْ لَا تَعْلَمُونَ`) — **Al-Aleem's** — and it is cited in that draft. Also set in `ٱلْقِتَال`. Rejected on bar 4 and on ground |
| **18:60–82** (Mūsā and al-Khiḍr) | the Qurʾān's great narrative of hidden wisdom — **and it carries no `ح-ك-م`** (it is built on `عِلْم`, `رُشْد`, `صَبْر`), so bar 4 would need a trade. **Rejected on bar 5 regardless:** the episode's centre is the killing of a boy, which cannot render at 11pm to someone in distress. Left free with the reasoning, since it will be reached for again |
| **6:18 · 34:1's full clause · 31:27 · 4:165** | `ٱلْحَكِيم` as a trailing epithet in a pair — labels, does not demonstrate. 6:18 also cited in two drafts |
| **42:51's `حَكِيمٌ`** | **reserved for this Name by `al-ali@1`**, which truncates before it — and **not used here**, because 42:51's subject is the modes of revelation, not wisdom. Left free; a future re-cut could take it |
| **3:6 and 3:18's `ٱلْعَزِيزُ ٱلْحَكِيمُ`** | **reserved for this Name** by `al-musawwir@1` and `al-muqsit@1`, both of which truncate before it. Also trailing epithets; **left unspent and available** |
| **34:1's `ٱلْخَبِيرُ`** | **left to `al-khabeer@1`.** This deck renders one word |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā names a third Name, not either of its own** (see *The shared duʿā*). Reported for the pair, **not actioned** (§9ce).
2. **Id 26's `lesson` — *"You may not understand the plan, but Al-Hakeem's wisdom never errs"* — is this deck's engine**, and unusually it names the reader's *incomprehension* rather than the attribute. Read after the text was selected.

---

## What I could not determine — attack these first

1. **`ح-ك-م`'s 210 occurrences were not exhaustively fetched** — the largest root in the project and the one place §9cc's "fetch every occurrence" is plainly unaffordable. The form breakdown was read and the named candidates fetched. **This is the likeliest Name in the project for a better carrier to exist unfound**, and it is the same limit the judgment four recorded for id 47.
2. **4:10's Fire adjacency** is the deck's weakest point. Disclosed, not resolved.
3. **The `al-aleem@1` separation is argued, not measured.** Knowledge vs ordering is a real distinction and a fine one — **re-argue it rather than check it** (§9cd).
4. **No ḥadīth fetched** — no ḥadīth beats, and the duʿā claims no narration (§9bc).

---

## Pairing verdict

**Ships independently.** Reviewed alongside `al-khabeer@1` for the shared duʿā and the 34:1 split, but neither deck depends on the other shipping.
