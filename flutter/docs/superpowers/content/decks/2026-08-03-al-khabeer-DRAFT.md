# Deck Draft — Al-Khabeer (catalogue id 49) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-hakeem-DRAFT.md`](./2026-08-03-al-hakeem-DRAFT.md).** Ids 49 and 26 **share one locked `dua_arabic`** (§9ce) whose vocative is **Al-Lateef's** — a third, already-shipped Name. Full treatment in *The shared duʿā*.

**The two decks divide one āyah.** 34:1 closes `وَهُوَ ٱلْحَكِيمُ ٱلْخَبِيرُ`; each renders its own word.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/26-49.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-khabeer@1` — Al-Khabeer

**Why this deck exists, in one line:** the user who maintains a version of themselves for other people and has been managing the gap for so long that they have stopped believing the private one is real.

**The reader's position, which is what separates this deck from its neighbours:** **unreadable.** Not unseen — *misread*. Judged accurately on the surface and wrongly underneath.

**Proposed metadata**

```json
{
  "deck_id": "al-khabeer@1",
  "name_id": 49,
  "transliteration": "Al-Khabeer",
  "chip_keys": [],
  "position_in_pair": 2,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> There is a version of you that other people get, and a version only you have seen. You have been managing the gap for years.

**Beat 2 · name_intro** *(catalogue id 49 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْخَبِيرُ — Al-Khabeer — The All-Aware

**Beats 3–5 · story — "Peoples and Tribes, and One Measure"** *(Qur'an 49:13)*:
> 3. Allah says: "O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another."
> 4. Peoples, tribes, families, names — every category anyone has ever used to rank you. The verse says what they are for: recognition. Not ranking.
> 5. "Indeed, the most noble of you in the sight of Allah is the most righteous of you." One measure, and it is not one anybody can see from outside — including you.

**Beat 6 · verse** *(partial quotation — **one word** of a two-Name clause, ellipsis both sides)*:
> …and the Aware. — Qur'an 34:1

**Beat 7 · duʿā** *(catalogue id 49, **byte-for-byte**, asserted programmatically (§9cb))*:
> اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا
> *Allahumma ya Lateefu, lutf bi fi umuri kulliha*
> "O Allah, O Gentle One, be gentle with me in all my affairs."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Aleem holds the facts. Al-Khabeer holds what is under them — the motive you did not admit, the effort nobody counted, the reason you did the right thing badly. You do not have to perform for the One who is already inside the account.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What would you stop explaining, if you knew the explaining had never been necessary?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allah is the most righteous of you"* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../49:13` | ✅ `يَـٰٓأَيُّهَا ٱلنَّاسُ إِنَّا خَلَقْنَـٰكُم مِّن ذَكَرٍ وَأُنثَىٰ وَجَعَلْنَـٰكُمْ شُعُوبًا وَقَبَآئِلَ لِتَعَارَفُوٓا۟ ۚ إِنَّ أَكْرَمَكُمْ عِندَ ٱللَّهِ أَتْقَىٰكُمْ ۚ إِنَّ ٱللَّهَ عَلِيمٌ خَبِيرٌ` — **whole āyah** |
| 2 | *"…and the Aware."* (beat 6) | `.../34:1` | ✅ `ٱلْخَبِيرُ` — **one word**, leading ellipsis; the āyah's last word, so no trailing ellipsis. `ٱلْحَكِيمُ` **left to `al-hakeem@1`**. **R1 fix:** R0 read *"…And He is the Aware."*, which silently deleted `ٱلْحَكِيمُ` from **inside** the clause and told the reader 34:1 ends *"And He is the Aware"* — it ends *"And He is the Wise, the Aware."* The ellipsis was at the edge, but the omission was interior. `al-hakeem@1`'s beat 6 got the same clause right (*"…And He is the Wise…"*, ellipsis on both sides), which is what made the divergence findable |
| 3 | Successor sweep n−1: 49:12 | `.../49:12` | ⚠️ **rebuke** — suspicion, spying, backbiting, `أَيُحِبُّ أَحَدُكُمْ أَن يَأْكُلَ لَحْمَ أَخِيهِ مَيْتًا`. **Not rendered.** Closes `تَوَّابٌ رَّحِيمٌ` |
| 4 | Successor sweep n+1: 49:14 | `.../49:14` | ⚠️ correction of the bedouins, `قُلْ`-framed. **No punishment**; closes `غَفُورٌ رَّحِيمٌ` |
| 5 | Successor sweep n+1 of the verse beat: 34:2 | `.../34:2` | ✅ closes `ٱلرَّحِيمُ ٱلْغَفُورُ`. 34:1 is sūrah-opening |
| 6 | The locked duʿā (shared with id 26) | `collectible_names.json` id 49 | ✅ all three fields asserted present (§9cb). **Its vocative is Al-Lateef's** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **49:13** — Allah's own first-person plural (`خَلَقْنَـٰكُم`, `جَعَلْنَـٰكُمْ`), stating the purpose of every visible category and then naming the only measure that counts | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **builds the whole apparatus of visible ranking — peoples, tribes — and then disqualifies it in one clause.** The awareness is shown by what it overturns, not declared | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `خ-ب-ر` as `خَبِيرٌ` in the rendered text of 49:13, and as `ٱلْخَبِيرُ` on the verse beat (34:1) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ **n−1 (49:12) is a rebuke about backbiting** with visceral imagery; n+1 (49:14) corrects the bedouins. **Both close on mercy** | ⚠️ **PASS — neither rendered** |

**Bar 5, fetched and stated.** **49:12** forbids suspicion, spying and backbiting and asks `أَيُحِبُّ أَحَدُكُمْ أَن يَأْكُلَ لَحْمَ أَخِيهِ مَيْتًا` — *"Would one of you like to eat the flesh of his brother when dead?"* **Not rendered, not alluded to**; it closes `إِنَّ ٱللَّهَ تَوَّابٌ رَّحِيمٌ`. **49:14** tells the bedouins *"you have not [yet] believed"* — a correction, `قُلْ`-framed, closing `إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ`.

**Both neighbours are rebukes and both end in mercy**, which is the register this deck needs and does not have to argue for. The exposure is real but mild: neither is punishment, neither is the Fire, and neither addresses the reader of this deck.

**Why the Name's own form could not carry bar 1 alone.** `خ-ب-ر` has **52 occurrences, 45 of them the nominal `khabīr`** — and `خَبِيرٌ` predicated of Allah is almost always a **trailing epithet**, very often welded to `ٱللَّطِيف`: `وَهُوَ ٱللَّطِيفُ ٱلْخَبِيرُ` (6:103, 22:63, 31:16, 67:14). **That pairing is the deck's real hazard, not its opportunity** — `al-lateef@1` is shipped, and the shared duʿā already invokes Al-Lateef. **49:13 was chosen partly because `خَبِيرٌ` there is paired with `عَلِيمٌ`, not with `ٱللَّطِيف`.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4** — the only hits are *"he is the"* (vs `al-wakeel@1`'s story and duʿā), a function-word run. **No finding.**

**Twin-diff vs `al-hakeem@1`** (the pair-partner): **4** — *"he is the"*, from the two verse beats, which are the two halves of one clause. Expected and disclosed.

**Every āyah checked against the shipped asset *and* all 34 pending drafts**, two-sided boundary match: **49:13 free · 34:1 free.** Checked and rejected as cited: **6:103** (`al-ahad`), **67:14** (`sign-pair`), **31:34** (`al-aleem`), **35:14** (`al-ghaniyy`), **64:8** (`an-nur`, `al-jami`), **6:18** (`ad-darr`, `al-qahhar`).

### Bar 3(c) — the move

**Al-Khabeer's move is that the ranking everyone can see is not the ranking that is being kept.**

The reader's error is believing the surface reading of them is the true one — either because it flatters and they know better, or because it condemns and they cannot argue. **49:13 dismantles that by building it first**: peoples, tribes, lineage, every apparatus of visible standing — stated as real, given a purpose (`لِتَعَارَفُوٓا۟`, recognition), and then set beside **one** measure that no observer can read, *including the reader themselves*.

**Against `al-lateef@1` (shipped)** — the nearest neighbour, and the Name this deck's own duʿā invokes: Al-Lateef's move is **what you could not say was never unsaid to Him** — gentleness reaching into the inexpressible. **Al-Khabeer's is accuracy about what is already there**: not tenderness toward the hidden, but *correct reading* of it. One consoles the inarticulate; the other corrects the record.

**Against the pair-partner `al-hakeem@1`:** depth of information vs use of it. Al-Khabeer knows what is under the surface; Al-Hakeem arranges what follows.

**Against `al-aleem@1` (shipped):** Al-Aleem is knowledge as *priority* — He knew before the evidence. Al-Khabeer is knowledge as *penetration* — He knows beneath the evidence. A verifier should press on whether that survives contact.

---

## The shared duʿā

Ids 49 and 26 render **one identical duʿā beat**:

> `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا` — *"O Allah, O Gentle One, be gentle with me in all my affairs."*

**Neither Name appears in it.** The vocative is **Al-Lateef's** (id 30), whose deck is **shipped**. Two decks about wisdom and awareness both close on a plea to a third Name.

**Catalogue-locked, disclosed, not actioned** (§9ce). **For this deck specifically it is sharper than for its partner**, because `ٱللَّطِيف` and `ٱلْخَبِير` are welded together in four āyāt — so the duʿā pulls toward exactly the neighbour bar 3(c) has to hold this deck away from. **That is why 49:13 was chosen over 6:103 and 67:14**, both of which would have put `ٱللَّطِيفُ ٱلْخَبِيرُ` on the deck itself.

**Checked:** shipped `al-lateef@1` renders its own, different duʿā, so there is no byte-collision with production.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **6:103** `لَّا تُدْرِكُهُ ٱلْأَبْصَـٰرُ وَهُوَ يُدْرِكُ ٱلْأَبْصَـٰرَ ۖ وَهُوَ ٱللَّطِيفُ ٱلْخَبِيرُ` | a genuine demonstration and the best-looking candidate — **rejected twice over**: cited in the `al-ahad` draft, and it renders `ٱللَّطِيفُ`, the shipped neighbour this deck must not collapse into (and the Name its own duʿā invokes) |
| **67:14** `أَلَا يَعْلَمُ مَنْ خَلَقَ وَهُوَ ٱللَّطِيفُ ٱلْخَبِيرُ` | same pairing problem; also cited in the `sign-pair` draft |
| **31:16** (Luqmān's mustard seed) | **reported human speech** — Luqmān to his son, bottom rung of §9bk — and **the mustard-seed image is now `al-haseeb@1`'s** (21:47) |
| **31:34 · 35:14 · 64:8 · 6:18** | trailing epithets, and each cited in a pending draft |
| **100:11** `إِنَّ رَبَّهُم بِهِمْ يَوْمَئِذٍ لَّخَبِيرٌ` | Judgment framing at the close of a sūrah about ingratitude. Bar 5 |
| **49:12's `أَيُحِبُّ أَحَدُكُمْ أَن يَأْكُلَ لَحْمَ أَخِيهِ مَيْتًا`** | the predecessor. **Never rendered** |
| **34:1's `ٱلْحَكِيمُ`** | **left to `al-hakeem@1`.** This deck renders one word |

---

## Catalogue findings — reported, **NO change recommended**

1. **The shared duʿā names a third, shipped Name** (see *The shared duʿā*). Reported, **not actioned** (§9ce).
2. **Id 49's `lesson` — *"You do not need to pretend with Al-Khabeer. He knows your truth already"* — is this deck's engine exactly**, and is the reason the deck reads 49:13 as being about *the reader's* unreadability rather than about social equality, which is the āyah's more usual application. **That is an interpretive choice and a verifier should test it**: the āyah is addressed to `ٱلنَّاس` about tribes, and this deck turns it inward.

---

## What I could not determine — attack these first

1. **The inward reading of 49:13 is the deck's main interpretive risk.** The āyah's plain subject is the equality of peoples; this deck applies it to one person's private self-assessment. **The move is licensed by `أَتْقَىٰكُمْ` being unobservable**, but it is a move, and it should be attacked before anything else here.
2. **`خ-ب-ر`'s 52 occurrences were not exhaustively fetched** (§9cc) — complete on the `khabīr` predications of Allah that are not already cited elsewhere, incomplete on the root.
3. **The `al-lateef@1` and `al-aleem@1` separations are argued, not measured** — both measure ≤4. **§9cd's exact shape; re-argue rather than check.**
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Reviewed with `al-hakeem@1` for the shared duʿā and the 34:1 split.
