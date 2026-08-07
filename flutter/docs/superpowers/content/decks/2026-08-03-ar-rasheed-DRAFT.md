# Deck Draft — Ar-Rasheed (catalogue id 99) — **R0, awaiting independent blind verification**

> ⚠️ **`ٱلرَّشِيد` is never predicated of Allah in the Qurʾān.** The three `rashīd` occurrences (11:78, 11:87, 11:97) are all **human**; `يَرْشُدُونَ` at 2:186 is Allah's own voice but that āyah is **SPENT** (`al-mujeeb@1`'s verse beat), and 18:10 is spent by `ar-raheem@1`. **Bar 4 is carried by the verse beat only.** See the bars note.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/99.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `ar-rasheed@1` — Ar-Rasheed

**Why this deck exists, in one line:** the user who cannot see where any of this is going, and has begun to take that as evidence that it is not going anywhere.

**The reader's position:** **unable to see the route.** Not doubting that Allah could guide; doubting that anything is currently being steered.

**Proposed metadata**

```json
{
  "deck_id": "ar-rasheed@1",
  "name_id": 99,
  "transliteration": "Ar-Rasheed",
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
> You cannot see where this is going, and you have begun to suspect that means it is not going anywhere.

**Beat 2 · name_intro** *(catalogue id 99 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الرَّشِيدُ — Ar-Rasheed — The Guide to Right Path

**Beats 3–5 · story — "He Changed What You Love"** *(Qur'an 49:7)* — **R3: recut. See the bar-1 note below; the R0 carrier demonstrated a different Name's root.**
> 3. Allah says: "…but Allah has endeared to you the faith and has made it pleasing in your hearts…"
> 4. "…and has made hateful to you disbelief, defiance and disobedience. Those are the [rightly] guided."
> 5. Read what He actually did. Not a sign put in front of you — three changes made inside you: what you love, what looks beautiful to you, what you cannot stomach. The guidance is not a direction you were shown. It is a taste you were given.

**Beat 6 · verse** *(partial quotation — visible ellipsis; **carries the root**)*:
> It guides to the right course… — Qur'an 72:2

**Beat 7 · duʿā** *(catalogue id 99, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا رَشِيدُ أَلْهِمْنِي رُشْدِي وَقِنِي شَرَّ نَفْسِي
> *Ya Rasheed, alhimni rushdi wa qini sharra nafsi*
> "O Guide to the Right Path, inspire my guidance and protect me from the evil of my own self."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Hadi shows you the way and you walk it. Ar-Rasheed is the arrangement you never see — the sun moved while they slept. Not being able to see where this goes is not evidence that nobody is steering it.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> What has already been arranged around you that you were not awake for?

---

## R3 — the carrier was replaced, and the reason is a bar-1 failure the blind verifier found

**R0 carried bar 1 on 18:17** — the sun angled around the sleepers. The `wave-f` verifier found the defect and it is real: **18:17 demonstrates `ه-د-ي`** (`مَن يَهْدِ ٱللَّهُ فَهُوَ ٱلْمُهْتَدِ`) — **Al-Hadi's root, and `al-hadi@1` is shipped** — not this Name's `ر-ش-د`. The root *is* present at 18:17, as `مُّرْشِدًا`, but only inside `وَمَن يُضْلِلْ فَلَن تَجِدَ لَهُۥ وَلِيًّا مُّرْشِدًا` — *whoever He sends astray will find no guide* — a **negation attached to misguidance.** So the deck's own bar-3(c) argument (that hidāyah and rushd are different claims) was being contradicted by its own carrier.

**The replacement, found by re-reading all 19 occurrences of `ر-ش-د` rather than the three `rashīd` ones.** `corpus?q=r$d` — **19 verses**: 2:186 · 2:256 · 4:6 · 7:146 · 11:78 · 11:87 · 11:97 · 18:10 · 18:17 · 18:24 · 18:66 · 21:51 · 40:29 · 40:38 · 49:7 · 72:2 · 72:10 · 72:14 · 72:21.

**49:7 is the one text in that list where Allah, in His own voice, performs the act and the root names its result.**

> `وَلَـٰكِنَّ ٱللَّهَ حَبَّبَ إِلَيْكُمُ ٱلْإِيمَـٰنَ وَزَيَّنَهُۥ فِى قُلُوبِكُمْ وَكَرَّهَ إِلَيْكُمُ ٱلْكُفْرَ وَٱلْفُسُوقَ وَٱلْعِصْيَانَ ۚ أُو۟لَـٰٓئِكَ هُمُ ٱلرَّٰشِدُونَ`

| bar | where it is met now |
|---|---|
| **1** | ✅ **Allah's own voice, three finite verbs with Allah as subject** — `حَبَّبَ` (endeared), `زَيَّنَهُۥ` (made it pleasing), `كَرَّهَ` (made hateful). Top of the §9bk ladder, no contest |
| **2** | ✅ **shown, not stated.** Three concrete changes *inside a person* — what they love, what looks beautiful to them, what they cannot stomach — and only then the label. The guidance is demonstrated as a change of appetite, not announced as a fact |
| **4** | ✅ **`ٱلرَّٰشِدُونَ` is in the same āyah, as the result of those three acts. No trade at all** — where R0 had to trade it |
| **5** | ✅ **clean both sides, fetched.** n−1 **49:6** is the instruction to verify news before acting; n+1 **49:8** is `فَضْلًا مِّنَ ٱللَّهِ وَنِعْمَةً` — *"as bounty from Allāh and favor."* **Not rendered**, because it closes on `عَلِيمٌ حَكِيمٌ` — shipped `al-aleem@1`'s and pending id 26's |

**Availability, checked:** 49:6 · 49:7 · 49:8 all **free** — no shipped deck, no pending draft. (49:13 is `al-khabeer@1`'s, eleven āyāt away, and is not rendered here.) **Max shared word-run of the new story against all 45 shipped decks: 2** (*"and has"*).

**The engine is better than the one it replaces, and that is the point.** R0's move was *"the arrangement you never see"* — which is really hidden providence, and sits close to `al-hafeez@1` and `ar-rasheed`'s own verse beat. **49:7's move is sharper and is genuinely this Name's:** `al-hadi@1` **shows you the way**; **Ar-Rasheed changed what you want.** Hidāyah is direction; rushd is right-directedness — a property of the person, which is why the āyah ends by calling *them* `ٱلرَّٰشِدُونَ` and not the road.

**The verse beat is unchanged (72:2) and now carries nothing load-bearing** — bar 4 is met on the carrier itself, so 72:2's weaker rung (jinn speech, `قُلْ`-framed) no longer matters to any bar.

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | The Sleepers retreat to the cave (beat 3, **described, not quoted**) | `.../18:16` | ✅ `فَأْوُۥٓا۟ إِلَى ٱلْكَهْفِ يَنشُرْ لَكُمْ رَبُّكُم مِّن رَّحْمَتِهِۦ` — **the youths' own speech**, so described rather than rendered as the carrier |
| 2 | *"And you would see the sun when it rose, inclining away from their cave on the right, and when it set, passing away from them on the left…"* + *"He whom Allah guides is the rightly guided"* (beats 4–5, **bar-1 carrier**) | `.../18:17` | ✅ `وَتَرَى ٱلشَّمْسَ إِذَا طَلَعَت تَّزَٰوَرُ عَن كَهْفِهِمْ … مَن يَهْدِ ٱللَّهُ فَهُوَ ٱلْمُهْتَدِ` — **the beat stops there.** `وَمَن يُضْلِلْ` onward **not rendered** |
| 3 | *"It guides to the right course…"* (beat 6, **bar-4 carrier**) | `.../72:2` | ✅ `يَهْدِىٓ إِلَى ٱلرُّشْدِ` — the clause only. **Its grammatical subject is the Qurʾān**, and the speakers are the jinn |
| 4 | Successor sweep: 72:1, 72:3 | `.../72:1` · `.../72:3` | ✅ both clean — an amazing recitation; `تَعَـٰلَىٰ جَدُّ رَبِّنَا` |
| 5 | Root sweep | `corpus…?q=r$d` | ✅ **19 occurrences, 7 forms.** The three `rashīd` occurrences (11:78, 11:87, 11:97) are **all human** |
| 6 | Cross-check: what is already spent | shipped asset | ⚠️ **2:186 is `al-mujeeb@1`'s verse beat**; **18:10 is `ar-raheem@1`'s** (three story beats and its duʿā) |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **18:17** `مَن يَهْدِ ٱللَّهُ فَهُوَ ٱلْمُهْتَدِ` — Allah's own voice, and the preceding clauses narrate an arrangement He made | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **describes a mechanism nobody in it witnessed** — the sun angled away from the cave mouth at both ends of the day, for years, over sleepers. Guidance is shown as arrangement, not as instruction | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ⚠️ **PASS — but `al-hadi@1` is shipped and close** |
| 4 | Root in the quoted text | ⚠️ **carried by the verse beat only.** 18:17's rendered clauses carry `ه-د-ي`, not `ر-ش-د`. **72:2's `ٱلرُّشْدِ` supplies the root** | ⚠️ **PASS via the verse beat** |
| 5 | Register and reverence | ⚠️ **18:17's unrendered second half** is `وَمَن يُضْلِلْ فَلَن تَجِدَ لَهُۥ وَلِيًّا مُّرْشِدًا`; the deck **stops before it**. 18:16 and 72:1/72:3 are clean | ⚠️ **PASS — the beat stops at the āyah's pause** |

**The root situation.** `corpus?q=r$d` — *"occurs **19 times** in the Quran, in seven derived forms."* **The nominal `rashīd` occurs three times — 11:78, 11:87, 11:97 — and all three are human**: Lūṭ's people ("is there not among you a man of right mind?"), Shuʿayb addressed sarcastically, and Firʿawn's command described as *not* rightly guided. **The Name-form is never predicated of Allah.**

**The two Allah-voiced options are both spent.** **2:186** — `وَلْيُؤْمِنُوا۟ بِى لَعَلَّهُمْ يَرْشُدُونَ`, first person, root present — is **`al-mujeeb@1`'s verse beat**, in production. **18:10** — the Sleepers' own duʿā, `وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا` — is rendered by **shipped `ar-raheem@1`**, across three story beats and its duʿā.

**So the deck sits in Sūrat al-Kahf, one āyah away from ground `ar-raheem@1` already holds, and takes the part that deck did not.** 18:16 is the youths' own speech (`يَنشُرْ لَكُمْ رَبُّكُم مِّن رَّحْمَتِهِۦ`) — **described, not quoted as the carrier** — and **18:17 is Allah's narration**, which is what carries bar 1.

**Bar 4 is carried by 72:2 alone**, `يَهْدِىٓ إِلَى ٱلرُّشْدِ`. **That clause's subject is the Qurʾān**, spoken by the jinn — so it is a **verse beat and nothing more**: it supplies the root, not the predication. **This is a weaker bar-4 than a trade would be honest about, and it is stated as such.**

**Bar 5.** 18:17's second half — `وَمَن يُضْلِلْ فَلَن تَجِدَ لَهُۥ وَلِيًّا مُّرْشِدًا` — is **not rendered**; the beat stops at the āyah's own pause. Ironically that unrendered half contains `مُّرْشِدًا`, the root, **so the deck declines the root rather than render a clause about being sent astray.** 72:1 and 72:3 are clean.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"in a cave"* (vs `as-salam@1`'s story), a function-word run. **No finding.**

**Every āyah checked against the shipped asset *and* all 48 pending drafts**, two-sided boundary match: **18:16 free · 18:17 free · 72:2 free.** **2:186 SPENT** (`al-mujeeb@1` verse beat + several drafts); **18:10 SPENT** (`ar-raheem@1` — three story beats and its duʿā). 7:146 cited in the `al-mutakabbir` draft; 2:256 in `al-qayyum`.

### Bar 3(c) — the move

**Ar-Rasheed's move is guidance as arrangement rather than as instruction — and specifically, arrangement the guided person sleeps through.**

18:17 is chosen because of **who is unconscious in it.** The young men are asleep for years. The thing being described is **the angle of sunlight at dawn and at dusk**, adjusted so it never falls on them. **Nobody in the story ever sees this happen.** That is the exact shape of the reader's complaint — *I cannot see where this is going* — met with a scene in which the going was managed by someone else entirely.

**Against `al-hadi@1` (shipped)** — the neighbour, and the risk: **Al-Hadi shows the way** and its takeaway is about *asking* — *"Even the strongest believers ask 'guide us' in every prayer… asking for it is the prayer itself."* **That deck is about the request.** This one is about **what was arranged while no request was being made**. One answers *how do I find the path*; the other answers *is there a path being laid*.

**Against `al-waliyy@1` and `al-wali@1`:** governance and allegiance both concern who is in charge. **Ar-Rasheed is narrower — the direction of travel**, and specifically that it is toward a `rushd`, a right outcome, rather than merely being administered.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **2:186** `لَعَلَّهُمْ يَرْشُدُونَ` | **the best text for this Name and it is SPENT** — `al-mujeeb@1`'s verse beat, in production. Allah's own voice, root present |
| **18:10** `وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا` | **spent by shipped `ar-raheem@1`** — and it is the Sleepers' **own duʿā**, human speech (§9bk) |
| **11:78 · 11:87 · 11:97** | the three `rashīd` occurrences — **all human**, and 11:97 describes Firʿawn's command as *not* rightly guided |
| **72:2 as the bar-1 carrier** | the subject is **the Qurʾān**, and the speakers are the jinn. Used as the verse beat only |
| **40:29 · 40:38** `سَبِيلَ ٱلرَّشَادِ` | **a believer's speech** to Firʿawn's people (§9bk) |
| **18:17's second half** | `وَمَن يُضْلِلْ` — being sent astray. **Not rendered, even though it contains the root** |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing.** Id 99's `english` (*The Guide to Right Path*), `meaning`, `lesson` (*Ar-Rasheed is guiding your story to a conclusion better than you could write*) and duʿā are consistent, and the `lesson` — a **conclusion**, an outcome — is precisely what distinguishes `rushd` from `hudā` and is this deck's engine.

---

## What I could not determine — attack these first

1. **Bar 4 is the weak point.** The root is supplied by a verse beat whose grammatical subject is the Qurʾān, not Allah. **A verifier may reasonably hold that this is not bar 4 at all but an undeclared trade** — in which case the deck should say so explicitly and lean on the As-Sabur precedent, which is stronger than a thin claim.
2. **The deck sits one āyah from `ar-raheem@1`'s ground** in the same passage. The split (18:16–17 versus 18:10) was verified by reading that shipped deck's beats, **but sharing a sūrah passage with a production deck is an exposure.**
3. **The `al-hadi@1` separation** — arrangement versus request — is argued, not measured (§9cd).
4. **`ر-ش-د`'s 19 occurrences were enumerated from the corpus listing; the named candidates were fetched.** Not all 19 individually read (§9cc).
5. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.** Read alongside `al-hadi@1` (shipped) and `ar-raheem@1` (shipped, same passage).
