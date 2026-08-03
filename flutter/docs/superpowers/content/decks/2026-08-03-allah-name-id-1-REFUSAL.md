# Catalogue id 1 — **`Allah`** — REASONED REFUSAL, not a draft

**2026-08-03, wave 3, by the agent holding id 1 + id 5.**
**Companion:** [`2026-08-03-al-quddus-DRAFT.md`](./2026-08-03-al-quddus-DRAFT.md) — id 5 **is** drafted.
**Claim file:** [`.context/claims/1.md`](../../../../.context/claims/1.md).

**This is the deliverable for id 1. No deck is proposed.** COLLISION-LEDGER §7a.2 says *"reject the
Name" is off the table* — a bar failure means *find a better source, passage or framing*, never *pick
a different Name*. **This document does not reject the Name.** It reports, with the sweeps run, that
**id 1 is not draftable in this wave**, names the exact three things that would make it draftable,
and hands over the ground it did not spend. It is the same class of finding as the ledger's own
*"Names that cannot get a bar-3-clean deck while the catalogue stands"* (§6e) — a **scheduling
fact**, not a verdict on the Name.

Everything below was fetched or computed. Nothing is recalled.

---

## 1 · The finding in one paragraph

**The Name `Allah` has no act, so bar 1 has only one possible carrier: an āyah in which Allah names
Himself with the lafẓ, in the first person.** Enumerated over the full 6,236-āyah Uthmānī text,
**exactly three such āyāt exist — 20:14, 27:9 and 28:30 — and all three are the same episode: Mūsā
at the fire.** That episode is **triple-encumbered** this wave. Separately, **bar 3 fails on a
measurement no deck can change**: `name_intro` is locked to catalogue `english`, which for id 1 is
the word **"God"** — a word this product renders **once** in 34 decks, against **"Allah"** in
**66 rendered strings across 29 of 34 decks**.

---

## 2 · Bar 1 — the enumeration

**Method.** All 6,236 āyāt of `text_uthmani` assembled locally from
`api.quran.com/api/v4/verses/by_chapter`, mark-folded, then matched for first-person self-naming
patterns (`أنا الله`, `إنني أنا الله`, `إنه أنا الله`, `أنا ربك`, `أنا ربكم`). **Full text, not a
search API** (COLLISION-LEDGER §9ac). Every hit was then read.

| āyah | text | Allah naming Himself? | verdict |
|---|---|---|---|
| **20:14** | `إِنَّنِىٓ أَنَا ٱللَّهُ لَآ إِلَـٰهَ إِلَّآ أَنَا۠ فَٱعْبُدْنِى وَأَقِمِ ٱلصَّلَوٰةَ لِذِكْرِىٓ` | **yes — the lafẓ, first person** | **Mūsā at the fire.** See §3. |
| **27:9** | `يَـٰمُوسَىٰٓ إِنَّهُۥٓ أَنَا ٱللَّهُ ٱلْعَزِيزُ ٱلْحَكِيمُ` | **yes** | **Mūsā at the fire**, plus a **trailing epithet pair** — Al-Azeez (8) and Al-Hakeem (26). Bar 1's named failure sits inside the same clause. |
| **28:30** | `يَـٰمُوسَىٰٓ إِنِّىٓ أَنَا ٱللَّهُ رَبُّ ٱلْعَـٰلَمِينَ` | **yes** | **Mūsā at the fire**, and **six āyāt from shipped `al-hadi@1`'s 28:23.** See §3. |
| 20:12 | `إِنِّىٓ أَنَا۠ رَبُّكَ` | no — `رَبّ`, not the lafẓ | (this is Al-Quddus's rejected Ṭuwā text; see the companion draft §10) |
| 21:92 · 23:52 | `وَأَنَا۠ رَبُّكُمْ` | no — `رَبّ` | — |
| 9:94 | `نَبَّأَنَا ٱللَّهُ` | **no** — a false positive of the fold (*"Allah has informed us"*) | — |
| **79:24** | `أَنَا۠ رَبُّكُمُ ٱلْأَعْلَىٰ` | **no — this is PHARAOH.** | Recorded because it is the one hit a careless sweep would misread. It is also already on the ledger's bar-5 rejection list. |

**Result: three candidates, one episode.**

**The alternative bar-1 shape — texts about the Names as a set — was enumerated too**
(`الأسماء الحسنى` / `أسماء`, full text). **Nine hits. Every one fails:**

| āyah | why it fails |
|---|---|
| **7:180** `وَلِلَّهِ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ فَٱدْعُوهُ بِهَا…` — *the* id-1 āyah, and it is the one that hurts | **Intra-āyah warning tail**, fetched in full: *"…And leave [the company of] those who practice deviation concerning His names. **They will be recompensed for what they have been doing.**"* That is the exact ground `al-mumin@1` gave up 24:55 on (*"the same āyah ends 'those are the defiantly disobedient'"*). ⚠️ **And n−1 is 7:179 — *"We have certainly created for Hell many of the jinn and mankind"*.** Fetched. **Blocked on both sides.** Sūrat al-Aʿrāf also already carries shipped `ar-rahman@1` (7:156) and `al-haqq@1` (7:118, this wave). |
| **17:110** `قُلِ ٱدْعُوا۟ ٱللَّهَ أَوِ ٱدْعُوا۟ ٱلرَّحْمَـٰنَ ۖ أَيًّا مَّا تَدْعُوا۟ فَلَهُ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ…` | **The best non-Mūsā candidate, and it fails bar 3 head-on: it renders `ٱلرَّحْمَـٰن` — shipped `ar-rahman@1`'s entire Name — on screen.** It also **states** rather than shows (bar 2), and it runs on into prayer-volume instruction in the same āyah. |
| **20:8** `ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ۖ لَهُ ٱلْأَسْمَآءُ ٱلْحُسْنَىٰ` | **Bar 2 — states the attribute**, the ground that killed `al-haleem@1` rev 1 and blocked 24:35 (§9j). It is also **four āyāt before the Ṭā Hā fire narrative**, i.e. the same encumbered ground as §3. |
| **59:24** | three Names in one clause (Al-Khaliq — **drafted this wave** — Al-Bari, Al-Musawwir) plus trailing `ٱلْعَزِيزُ ٱلْحَكِيمُ`. `.context/claims/10.md` already rejects it. |
| 2:31 · 2:33 | the names **Ādam** was taught, not Allah's. `.context/claims/14.md` already rejects 2:30–33 (shipped `at-tawwab@1` sits at 2:37 in the same episode). |
| 7:71 · 12:40 · 53:23 | names **the idolaters invented**. Polemic; the opposite subject. |

**Conclusion, at its true strength: bar 1 for id 1 reduces to one narrative episode. It is not that
the texts are weak — 20:14 is as strong a bar-1 text as exists in the Qurʾān. It is that there is
exactly one of them.**

---

## 3 · Why that one episode is not available this wave

| encumbrance | measurement |
|---|---|
| **Shipped `al-hadi@1` is Mūsā** | Its story beats are **28:15, 28:21, 28:22, 28:23** — Mūsā's flight to Midian. **28:30 is six āyāt later, and it is the continuation of the same journey**: the flight ends where the fire begins. A user meeting both decks meets one story told twice. **The ledger's own bar-3 test — *could a user read both screens and think they had been told the same thing twice?* — is failed by construction.** |
| **`al-haqq@1` is Mūsā, in Ṭā Hā, this wave** | `.context/claims/61.md`: central figures **Mūsā and Pharaoh's magicians**; story beats **20:65–20:70**. The only non-Qaṣaṣ route for id 1 is **20:14**, i.e. **the same sūrah**. That would make Ṭā Hā a two-deck sūrah **and** Mūsā a **three-deck** central figure. The ledger's precedent for a repeated figure is Yūsuf across two shipped decks, **resolved by an explicit cession** (`al-jabbar@1` gave up 12:100). **There is nothing to cede here — `al-haqq@1` claimed first and its scripture is already fetched and written.** |
| **27:9 is inside a Name-chain** | `ٱلْعَزِيزُ ٱلْحَكِيمُ` — a trailing epithet pair in the same clause. Bar 1's named failure. |
| **20:12 is Al-Quddus's own refused text** | Its `ٱلْوَادِ ٱلْمُقَدَّسِ` is the strongest `q-d-s` occurrence in Allah's first-person speech (companion draft §8). Building id 1 on 20:11–14 would **spend the sibling Name's last root occurrence** on a deck that does not need it. |

**None of these is a defect in the Name.** All four are scheduling facts, and three of them were
created by decisions taken in the last 48 hours.

---

## 4 · Bar 3 — the failure that no source change can fix

**This is the part I want a founder to see, because it is a measurement, not a judgement.**

| what renders | count | measured over |
|---|---|---|
| English `Allah*` | **66 rendered strings, in 29 of 34 decks** | all 734 rendered strings in `assets/content/name_stories.json` |
| the lafẓ `الله` / `اللهم` in **Arabic** | **18 strings, in 17 of 34 decks** | same |
| the token **`god`** | **1** — `al-mujeeb@1`'s duʿā beat, lower-case, inside *"There is no god but You"* | same |

**Beat 2 (`name_intro`) `primary` is locked to catalogue `english`.** For id 1 that string is
**"God"**.

So a deck for id 1 would put the word **"God"** on the Name-gloss screen of a product that says
**"Allah"** 66 times across 29 decks and has said **"God"** once, in lower case, inside a negation.
**That is the *Restorer* class in its most acute form** (ledger §4b, §9o's fourth row: *"a rendered
Name-gloss … yes, and unfixable inside a deck — escalate; do not paper over"*).

**And the structural half, stated as an argument rather than a measurement, because it cannot be
measured:** bar 3 asks that a deck not collapse into a sibling Name. Catalogue id 1's own `meaning`
is *"the proper name of God, **encompassing all divine attributes**."* Every story that could teach
it teaches one of the other 98 — the two best candidates prove it:

- **Mūsā at the fire** teaches *being answered when you went out for something else*. That is
  guidance and response — shipped `al-hadi@1` and drafted `al-mujeeb@1`.
- **The duʿā of grief** (§5) teaches *distress → one taught sentence → the removal*. **That is
  `al-mujeeb@1`'s Yūnus, beat for beat.**

**I state that as the weaker half of the case.** §9aq's lesson is that a collision in the *move* is
real and invisible to every mechanical pass — but it is also the half a founder may reasonably
overrule, and I am not pretending it is settled by a number. **The `name_intro` finding is settled by
a number.**

---

## 5 · The duʿā — the duʿā-first step, run, and its result is *unverifiable by this pipeline*

Catalogue id 1's `dua_arabic`: `اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ`
— *"O Allah, I ask You by every Name that belongs to You."*

**This does not read as an authored invocation.** It reads as the opening petition of the well-known
supplication for *hamm* and *ḥazan* — the one continuing
`… سَمَّيْتَ بِهِ نَفْسَكَ أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ أَوِ اسْتَأْثَرْتَ بِهِ فِي عِلْمِ الْغَيْبِ عِنْدَكَ`.
**I am not asserting that, because I could not verify it.**

**What I actually did, and what it returned:**

| attempt | result |
|---|---|
| Wayback **CDX** for `sunnah.com/ahmad:3712` (the number usually given) | **`[]` — zero captures.** |
| Wayback CDX for `sunnah.com/ahmad:37*`, `filter=statuscode:200`, collapsed | **10 pages archived, and every one is a 2–3 digit number** (`ahmad:37`, `370`–`379`). **The 3,7xx range of Musnad Ahmad is not in the archive.** |
| Wayback CDX for `sunnah.com/mishkat:2452` | **empty response** (the Mishkāt route). |

**So: this supplication is, to my knowledge, not in the six books, and the collections that carry it
are outside what this pipeline can reach.** The plan's own §6 records the standing limit — ḥadīth
checking here is not independent of sunnah.com, and sunnah.com 403s automated fetching — and **this
is the first time in the project that the limit has bitten on a duʿā rather than a story.**

**Consequences, stated exactly:**
1. **Id 1's duʿā would ship UNPINNED**, and correctly so.
2. ⚠️ **"Unpinned" here must NOT be reported as "unsourced".** COLLISION-LEDGER §9k makes this
   distinction binding, and it applies with full force: **I have not shown the words are unattested.
   I have shown that I could not fetch a route.** Those are different findings and only the second
   one is mine.
3. **A future drafter will find this traceable and may propose a pin.** Do not action it without a
   primary fetch — this is the §9w trap shape in advance.

**NO catalogue change is recommended for id 1.** Four of four confident recommendations to change
catalogue data in this project have been wrong (§8.4, §9d, §9l).

---

## 6 · Catalogue findings for id 1 — reported, NO change recommended

**Id 1's `hadith` field says more than Bukhārī 2736 does.**

- **Card:** *"The Prophet ﷺ said: 'Allah has ninety-nine Names. Whoever **memorizes and acts upon
  them** will enter Paradise.' (Bukhari)"*
- **Fetched page** (`web.archive.org/web/20211224174239id_/https://sunnah.com/bukhari:2736`),
  **Ṣaḥīḥ al-Bukhārī 2736**, Abū Hurayra, Arabic
  `إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمًا مِائَةً إِلاَّ وَاحِدًا مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ`,
  page English: *"Allah has ninety-nine names, i.e. one-hundred minus one, and whoever **knows them**
  will go to Paradise."*

**The narration is real, correctly numbered, correctly attributed and ṣaḥīḥ.** The defect is that
`أَحْصَاهَا` is one word and the card renders it as **two acts** — *memorizes* **and** *acts upon* —
inside quotation marks, in a field users read as a quotation. **That is a translation doing
interpretive work, the `al-kareem@1` failure class** (plan §6 rule 2), in the `hadith` column that
the 2026-08-03 repair pass already swept. **Reported. No change recommended. Not blocking anything.**

**Note the second-order fact:** this is the ḥadīth the whole product is built on, and it is the
**only** ḥadīth a deck for id 1 could naturally use. It is **also not a narrative** — it is a
statement of number and consequence. **The ledger already rejected that class**: *mercy in one
hundred parts (Bukhārī 6469) — "a statement of scale, not a narrative"* (§1a). **So id 1's own card
ḥadīth is unusable as a story on precedent already set.**

---

## 7 · What would make id 1 draftable — three things, in priority order

**This is the actionable half. None of the three is a drafting task.**

1. **A ruling that Mūsā may carry a third deck, and Ṭā Hā a second.** If a founder grants that,
   **20:9–14 is a genuinely excellent deck** — a man goes out into the cold to fetch a burning stick
   for his family and is answered with the Name — and bar 1 is met at its maximum (`إِنَّنِىٓ أَنَا
   ٱللَّهُ`, first person, the lafẓ itself, `سَمَّيْتَ بِهِ نَفْسَكَ` in the catalogue duʿā's own
   idiom). **The scripture is already fetched and recorded in §2.** This is the single unblock.
2. **A decision about the `name_intro` string "God".** Either the founder accepts the word on that
   one screen, or id 1 takes an authored gloss line beside it (the `al-wakeel@1` / `al-muid@1` /
   `al-mumin@1` precedent), or catalogue id 1's `english` moves. **The third option is a catalogue
   change and I am not recommending one.** ⚠️ **Whatever is decided, it should be decided for id 1
   before a drafter starts, not discovered at review** — that is what §9ai says three agents' worth
   of escalation costs.
3. **A duʿā route this pipeline can fetch**, or an explicit acceptance that id 1 ships unpinned with
   §5's distinction recorded verbatim.

**If (1) is refused, id 1 has no bar-1 carrier at all and should stay unassigned** — not because the
Name is hard, but because the three āyāt that could carry it are one story and that story now
belongs to two other decks.

---

## 8 · Ground I did NOT spend — free for whoever gets id 1

Because a refusal that also burns the ground is worthless.

- **20:9–14 (Ṭā Hā, the fire)** — fetched (20:12, 20:14), **claimed by nobody, rendered on no beat of
  any deck.** ⚠️ **20:12 is disclosed in the Al-Quddus draft as a rejected candidate and is
  explicitly left free.**
- **28:29–30 (al-Qaṣaṣ, the fire)** — read in the corpus, **not fetched individually, not used.**
  **Flagged, not free**: six āyāt from shipped `al-hadi@1`.
- **27:7–9 (an-Naml, the fire)** — read in the corpus. **Free, and weakest of the three** (the
  epithet pair).
- **7:180 · 17:110 · 20:8 · 59:24** — the "Names as a set" texts. **7:180 fetched with 7:179 and
  7:181 and recorded as BLOCKED, not free** (warning tail + n−1 is Hell). The other three are
  refused above on stated grounds and are **free for any Name that can solve them**.
- **Bukhārī 2736 / 7392** (the ninety-nine Names). **2736 fetched and verified; on no beat.**
  Free — but see §6 on why it is not a narrative.
- **The duʿā of grief** — **unspent and unverified.** Whoever reaches a corpus beyond sunnah.com
  should start here; it is the most affecting text available to this Name and it may not be
  reachable at all through Wayback.

---

## 9 · What this pass could NOT determine

1. **Whether id 1's duʿā is narrated.** §5. **Not fetched, therefore not asserted in either
   direction.**
2. **Whether the bar-3 "move" argument in §4 would survive an adversarial pass.** It is an argument
   about what a beat *does*, and §9x is right that an adversarial pass settles measurements, not
   arguments. **The `name_intro` half is a measurement; the collapse half is not.**
3. **No isnād was audited and no corpus independent of sunnah.com was reached** — the project's
   standing limit, unchanged.
4. **`.context/claims/` was re-read immediately before this document's tables were written, per
   §9s, and the re-read mattered.** At my start the directory held **10** files; at the re-read it
   held **17**. Five were filed after I began — **8, 24, 25, 45, 87** — and all five were read.
   **None of them touches id 1's ground**: no claim on 20:9–14, 27:7–9, 28:29–30, 7:180, 17:110,
   20:8, 59:24 or Bukhārī 2736/7392. **The Mūsā/Ṭā Hā encumbrance in §3 therefore rests on
   `.context/claims/61.md` and shipped `al-hadi@1`, both re-checked at that moment.** A claim filed
   after the re-read is still invisible to me.
5. **I did not run a successor sweep on 20:14, 27:9 or 28:30**, because I am not proposing them.
   **Whoever takes id 1 must run it** — and should start at 20:15–16, which I have not read.

---

## 10 · Prose-vs-table diff (§9aj), and the measurements (§9ak)

Three claims came down to their rows while writing this:

- *"There is no āyah where Allah names Himself"* → **false.** There are **three**. The finding is that
  **all three are one episode**, which is what §1 and §2 now say.
- *"The duʿā has no provenance"* → **not established.** §5 now says **I could not fetch a route**,
  and quotes §9k's rule against flattening the two.
- *"Id 1 collides with every shipped deck"* → **unmeasurable as stated.** §4 now separates the
  measured half (`name_intro` = *"God"*; 66 strings; 29 of 34 decks; `god` n=1) from the argued half.

**Every quantity here is a number:** 6,236 āyāt swept · **3** self-naming āyāt · **9** Names-as-a-set
āyāt, all failing · **1** episode · **6** āyāt between 28:30 and shipped `al-hadi@1`'s 28:23 ·
**66** rendered strings carrying *Allah* in **29 of 34** decks · **18** Arabic strings in **17** decks ·
**`god` n=1** · **0** Wayback captures of `ahmad:3712` · **10** archived `ahmad:37*` pages, none in the
3,7xx range.
