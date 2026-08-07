# Deck Draft — Ash-Shaheed (catalogue id 60) — **R0, awaiting independent blind verification**

> ⚠️ **This Name's duʿā partner is already in production.** Ids 60 and **46 Al-Baseer** share one locked `dua_arabic` (§9ce), and **shipped `al-baseer@1` renders it verbatim.** A bar-3(b) sweep therefore returns a shared word-run equal to the entire duʿā — **correct, unavoidable, catalogue-locked.** Worse, `al-baseer@1`'s duʿā ends `فَٱشْهَدْ لِى` — **this Name's own root, spent in a shipped deck.** See *The shared duʿā*.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cf, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/60.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `ash-shaheed@1` — Ash-Shaheed

**Why this deck exists, in one line:** the user whose hardest hour had no one else in the room, and who has started to doubt their own account of it.

**The reader's position, which is what separates this deck from its neighbours:** **uncorroborated.** Not unseen — *unattested*. They believe He saw; what they doubt is that it will ever be said out loud.

**Proposed metadata**

```json
{
  "deck_id": "ash-shaheed@1",
  "name_id": 60,
  "transliteration": "Ash-Shaheed",
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

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> The part of it nobody else was there for is the part you have started to doubt yourself.

**Beat 2 · name_intro** *(catalogue id 60 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الشَّهِيدُ — Ash-Shaheed — The Witness

**Beats 3–5 · story — "Allah Bears Witness"** *(Qur'an 4:166)*:
> 3. Allah says of what He revealed: "But Allah bears witness to that which He has revealed to you. He has sent it down with His knowledge…"
> 4. Not that He knows it. That He testifies to it. The verb is the one used in a court, and the One using it is Allah.
> 5. "…and the angels bear witness as well. And sufficient is Allah as Witness." Sufficient — the testimony does not need a second signature.

**Beat 6 · verse** *(partial quotation — the closing clause of the carrier āyah, visible ellipsis)*:
> …And sufficient is Allah as Witness. — Qur'an 4:166

**Beat 7 · duʿā** *(catalogue id 60, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ
> *Ya Basir, anta tara ma la yara ahad, fashhadli bima la ya'lamuhu siwak*
> "O All-Seeing, You see what no one else sees. Bear witness for me in what only You know."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Baseer sees it. Ar-Raqeeb watches it. Ash-Shaheed is the One who will say what He saw. That distinction is the whole reason this Name's duʿā asks Him not to look but to speak — and it is why the thing no one else attended still has a witness who can be called.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What is the thing no one was there for? You are not the only one who knows it happened.

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"But Allah bears witness to that which He has revealed to you. He has sent it down with His knowledge, and the angels bear witness [as well]. And sufficient is Allah as Witness"* (beats 3–6, **bar-1 and bar-4 carrier**) | `.../4:166` | ✅ `لَّـٰكِنِ ٱللَّهُ يَشْهَدُ بِمَآ أَنزَلَ إِلَيْكَ ۖ أَنزَلَهُۥ بِعِلْمِهِۦ ۖ وَٱلْمَلَـٰٓئِكَةُ يَشْهَدُونَ ۚ وَكَفَىٰ بِٱللَّهِ شَهِيدًا` — **whole āyah**, split across the story beats with the closing clause on the verse beat |
| 2 | Successor sweep n−1: 4:165 | `.../4:165` | ✅ clean — `رُّسُلًا مُّبَشِّرِينَ وَمُنذِرِينَ`, messengers as bringers of good tidings |
| 3 | Successor sweep n+1: 4:167 | `.../4:167` | ⚠️ **rebuke, not punishment** — *"have certainly gone far astray."* No `عَذَاب`, no Fire. **Not rendered** |
| 4 | The locked duʿā | `collectible_names.json` id 60 | ✅ all three fields asserted present (§9cb). ⚠️ **byte-identical to shipped `al-baseer@1`'s duʿā beat** — verified against `name_stories.json` |
| 5 | Cross-check: what `al-baseer@1` renders | `assets/content/name_stories.json` | ⚠️ its duʿā beat carries `فَٱشْهَدْ لِى` — **this Name's root, in production** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **4:166** `لَّـٰكِنِ ٱللَّهُ يَشْهَدُ` — finite verb, Allah the grammatical subject, in Allah's own voice | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **performs the act rather than describing the capacity** — it is not *He is a witness* but *He bears witness*, with an object, alongside named co-witnesses, closing on sufficiency | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS on the beats — but see the duʿā, which collides with a shipped deck by construction** |
| 4 | Root in the quoted text | `ش-ه-د` **three times** in the carrier — `يَشْهَدُ`, `يَشْهَدُونَ`, `شَهِيدًا` — the densest bar-4 in this wave | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ n−1 (4:165) is clean — messengers as bringers of good tidings; **n+1 (4:167) is a rebuke** of those who avert people from Allah's way, **but not punishment and not the Fire** | ⚠️ **PASS — successor never rendered** |

**Bar 5, fetched.** **4:165** is `رُّسُلًا مُّبَشِّرِينَ وَمُنذِرِينَ` — messengers as bringers of good tidings and warners — clean. **4:167** reads `إِنَّ ٱلَّذِينَ كَفَرُوا۟ وَصَدُّوا۟ عَن سَبِيلِ ٱللَّهِ قَدْ ضَلُّوا۟ ضَلَـٰلًۢا بَعِيدًا` — *"have certainly gone far astray."* **A rebuke, not a punishment**: no `عَذَاب`, no Fire, and it is aimed at active obstruction rather than at the reader. **Not rendered.**

**The whole deck sits inside one āyah**, which is deliberate. 4:166 carries the root three times, the finite verb, the co-witnesses and the sufficiency clause — **everything the Name needs is in a single sentence**, so no second text is imported and no second bar-5 neighbourhood is opened. The precedent is `al-adl@1`, which splits 4:40 across beats the same way.

**Why the epithet occurrences were not used.** `ش-ه-د` has **160 occurrences in 9 forms**, and `شَهِيد` predicated of Allah is usually a **trailing epithet** — `وَٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ شَهِيدٌ` (22:17, 85:9), `وَٱللَّهُ شَهِيدٌ عَلَىٰ مَا تَعْمَلُونَ` (3:98). Those label. **4:166 is the one that acts.**

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4** — the only hit is *"the one who"* (vs `ar-rauf@1`'s takeaway), a function-word run. **No finding on the beats.** An earlier revision of beat 8 measured **9** against `al-baseer@1`'s **duʿā**, because the takeaway quoted this deck's own duʿā text — *"witness for me in what only you know"*. **Rewritten**; a takeaway must not restate its own beat 7, and here doing so also collided with a shipped deck.

**There is no twin-diff to run** — id 60 has no unshipped partner. **The relevant comparison is against the shipped `al-baseer@1`**, and on the beats it is **4**. On the duʿā beat it is **the entire string**, by catalogue construction.

**Every āyah checked against the shipped asset *and* all 34 pending drafts**, two-sided boundary match: **4:166 free** — no shipped deck, no pending draft. Also checked free and left: 22:17, 85:9, 3:98, 4:79, 10:29. **41:53 is `az-zahir@1`'s carrier** and was not considered. **3:18's `شَهِدَ ٱللَّهُ` is reserved for this Name** by `al-muqsit@1` (which renders four words of that āyah) — **not used here**, and left available.

### Bar 3(c) — the move

**Ash-Shaheed's move is that He will say what He saw.**

This is the distinction the whole family turns on, and it is narrow enough to state exactly:

| deck | what it does with the unseen thing |
|---|---|
| `al-baseer@1` (shipped) | **sees** it — *"You said no one sees it. This Name is about the One who always has."* |
| `ar-raqeeb@1` (shipped) | **watches** it, and the watchers file a report |
| `al-aleem@1` (shipped) | **knows** it, before any evidence |
| `al-muhsi@1` (drafted) | **counts** it, itemised |
| `al-haseeb@1` (drafted) | **suffices** for it — you need not make your case |
| **`ash-shaheed@1`** | **testifies** to it — the account is not merely held, it is **given** |

**Perception is private; testimony is public.** That is the whole gap this Name closes, and it is exactly what the reader's grievance needs: they do not actually doubt that Allah saw. They doubt that it will ever be *said*.

**And the duʿā — even though it names Al-Baseer — asks for precisely this.** `فَٱشْهَدْ لِى بِمَا لَا يَعْلَمُهُ سِوَاكَ`: *bear witness **for** me.* Not *look at me*. **The catalogue put the right request under the wrong vocative**, and this deck's takeaway is built on the request rather than on the vocative.

**The nearest risk is `al-haseeb@1`**, which measures 4: *sufficiency of the reckoning* against *the giving of testimony*. One says nothing more is needed from you; the other says something will be said on your behalf. **Thin. §9cd applies — re-argue it.**

---

## The shared duʿā

**This is the deck's structural problem and it cannot be solved, only disclosed.**

Id 60's locked duʿā is:

> `يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ`
> *"O All-Seeing, You see what no one else sees. Bear witness for me in what only You know."*

**Three facts, all verified against the asset:**

1. **The vocative is Al-Baseer's, not this Name's.** `يَا بَصِيرُ`, id 46.
2. **Shipped `al-baseer@1` renders this exact string** as its own beat 7 — Arabic, transliteration and translation all identical. **So a bar-3(b) sweep of this deck against production returns a shared run equal to the whole duʿā.** That is correct and unavoidable (§9ce), not a drafting defect.
3. **`al-baseer@1` therefore already renders this Name's own root** — `فَٱشْهَدْ`, `ش-ه-د` — in a shipped deck. **Ash-Shaheed's bar 3(a) has to start from the fact that its root is on someone else's screen.**

**What the deck does about it:** nothing to the duʿā, which is locked. It makes the *second half* of the duʿā — the request to testify — the thing beat 8 argues from, precisely because that half is Ash-Shaheed's and not Al-Baseer's. **The two decks read the same sentence and take different clauses out of it**, which is the same manoeuvre `al-muqsit@1` and `al-haseeb@1` perform on 21:47 — except here one of the two has already shipped and could not participate in the decision.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **22:17 · 85:9** `عَلَىٰ كُلِّ شَىْءٍ شَهِيدٌ` | trailing epithets — label, do not demonstrate. 85:9 also sits in Sūrat al-Burūj, three āyāt from the trench |
| **3:98** `وَٱللَّهُ شَهِيدٌ عَلَىٰ مَا تَعْمَلُونَ` | `قُلْ`-instructed (§9bk) **and** addressed as *"why do you disbelieve"* — register |
| **41:53** | **`az-zahir@1`'s carrier.** Not considered further |
| **3:18** `شَهِدَ ٱللَّهُ` | **reserved for this Name** by `al-muqsit@1`, which renders only `قَآئِمًۢا بِٱلْقِسْطِ`. Not used — 4:166's finite verb is stronger, and 3:18 is the densest āyah in the wave. **Left available** |
| **5:117** (ʿĪsā: `وَكُنتُ عَلَيْهِمْ شَهِيدًا`) | **reported prophetic speech**, and it hands over to `ٱلرَّقِيبَ` — shipped `ar-raqeeb@1`'s Name |
| **4:41** `فَكَيْفَ إِذَا جِئْنَا مِن كُلِّ أُمَّةٍۭ بِشَهِيدٍ` | **reserved for this Name** by `al-adl@1` (its n+1) — but the witnesses there are *prophets against nations*, a Judgment tableau. Bar 5 and fit. Left free |

---

## Catalogue findings — reported, **NO change recommended**

1. **The duʿā's vocative is another Name's, and that Name is shipped rendering the identical string** (see *The shared duʿā*). **Reported, not actioned** (§9ce) — but this is the strongest catalogue finding in the wave, because it is the only one where the collision is with production rather than with a draft.
2. **Id 60's `hadith` field is not a ḥadīth.** It reads *"Allah called the martyr a 'shahid' because the shahid bears witness to Allah's reward…"* — authored prose about the word's etymology, with **no isnād, no collection and no grading**. **This deck does not render it.** Reported because a drafter reading the catalogue top-to-bottom could mistake it for a citable narration.
3. **Id 60's `lesson` — *"Your silent sacrifice is not unseen. Ash-Shaheed was there"* — describes *presence*, which is `al-baseer@1`'s move, not testimony.** The deck follows the duʿā's second half instead. Flagged like `al-haseeb@1`'s: **the `lesson` points at a neighbour's engine.**

---

## What I could not determine — attack these first

1. **The duʿā collision with a shipped deck is unresolvable at draft level.** It is disclosed. **If a reviewer holds that two decks cannot render one duʿā when one is already in production, this is a catalogue decision, not a redraft.**
2. **`ش-ه-د` has 160 occurrences in 9 forms and was not exhaustively fetched** (§9cc) — the `shahīd` predications of Allah were enumerated and the named candidates fetched; the 44 form-I `shahida` occurrences (mostly human witnessing) were not.
3. **The `al-haseeb@1` separation measures 4 and is argued, not measured** — sufficiency vs testimony. §9cd.
4. **The whole deck rests on one āyah.** That is deliberate and precedented, but it means **there is no fallback if 4:166 is contested** — the epithet occurrences all fail bar 1, and 3:18 is spoken for.
5. **No ḥadīth fetched** (§9bc). Given catalogue finding 2, a *real* ḥadīth on `shahīd` might be worth someone's time — unexplored, not closed (§9bo).

---

## Pairing verdict

**Ships independently of everything except the disclosure.** No unshipped partner, no hard dependency — **but it must not be transcribed without the duʿā note reaching whoever merges it**, because the sweep against production will flag a full-string duʿā match and that flag is expected.
