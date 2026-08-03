# Deck Draft — Ar-Rafiʿ (wave 2, catalogue id 42) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-khafid-DRAFT.md`](./2026-08-03-al-khafid-DRAFT.md).** Ids 41 and 42 were
assigned and drafted as a deliberate pair — the Qurʾān names them together (`خَافِضَةٌ رَّافِعَةٌ`,
56:3) and the catalogue's own duʿās cross-reference each other. **The pairing verdict, and the
reason Al-Khafid must not ship alone, live in that file and in `.context/claims/41.md`.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full including §9–§9as.
Claim filed at `.context/claims/42.md` **before** drafting; `.context/claims/` **re-read immediately
before this file's verification tables** (ledger §9s) — 8 new claim files had landed (1, 5, 8, 12,
24, 25, 45, 87) and two of them bear on this deck. See "Cross-wave" below.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4`; ḥadīth via
Wayback captures of the exact bare `sunnah.com` number, piped through `zstd -d`.
**Nothing here was recalled, reconstructed or composed.**

**Translation standard:** Saheeh International (`20`) for Qurʾān, with Abdel Haleem (`85`) fetched
for comparison. **The ḥadīth is re-rendered from the page's Arabic rather than pasting the published
English** (plan §6 rule 2, the `al-kareem@1` rule); every departure is itemised with its reason.
Saheeh prints `Allāh`; beats render `Allah`, matching all 34 shipped decks.

---

## Deck `ar-rafi@1` — Ar-Rafiʿ

**Why this deck exists, in one line:** the user who has been described accurately, and the accurate
description was the smaller of the two true things about them. **There is a conversation on a road
outside Makkah in which a man is described twice, both times truly, and the second description is
the one that decided where he stood.**

**Selection ran duʿā-first.** Catalogue id 42's duʿā asks for two distinct things —
`ارْفَعْ دَرَجَتِي عِنْدَكَ` (rank *with You*) **and** `وَاجْعَلْ لِي مَكَانَةً فِي الدُّنْيَا`
(a standing *in this world*). The second half is what pointed at this narration: it is a text in
which someone's standing in the dunyā actually changes, and the Prophet ﷺ names what changed it.

**Proposed metadata**

```json
{
  "deck_id": "ar-rafi@1",
  "name_id": 42,
  "transliteration": "Ar-Rafi",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

> ⚠️ **`position_in_pair: 0` is what the asset supports today and it is NOT what this deck wants.**
> See the pairing section at the bottom, and `al-khafid@1`'s draft. This is a founder decision with
> an engineering dependency, not a drafting one.

**Beat 1 · bridge:**
> Someone described you correctly, and it was the smaller of the two true things about you. That happened out loud on a road outside Makkah, about a man who was not there.

**Beat 2 · name_intro** *(from `collectible_names.json` id 42, verbatim, no authored gloss)*:
> الرَّافِعُ — Ar-Rafi — The Exalter

**Beats 3–5 · story — "Who is Ibn Abza?":**
> 3. Nafi ibn Abd al-Harith was Umar's man over Makkah. They met on the road at Usfan, and Umar asked him: **"Whom did you leave in charge of the people of the valley?"**
> 4. **"Ibn Abza."** — **"And who is Ibn Abza?"** — **"One of our freed slaves."** — **"You left a freed slave in charge of them?"** — **"He is a reciter of the Book of Allah, and he knows the obligations."**
> 5. And Umar said: your Prophet ﷺ said — **"Allah raises peoples by this Book, and sets others down by it."**

**Beat 6 · verse:**
> "…Allah will raise those who have believed among you, and those who were given knowledge, by degrees…" — Qur'an 58:11

**Beat 7 · duʿā** *(catalog id 42, verbatim in full)*:
> يَا رَافِعُ ارْفَعْ دَرَجَتِي عِنْدَكَ وَاجْعَلْ لِي مَكَانَةً فِي الدُّنْيَا وَالْآخِرَةِ
> *Ya Rafi', irfa' darajati 'indak waj'al li makanatan fid-dunya wal-akhirah*
> "O Exalter, raise my rank with You and grant me a standing in this life and the next."
> **NO source. This deck must not be pinned** — see the ship-gate note.

**Beat 8 · takeaway:**
> Both answers about him were true — one of our freed slaves, and a reciter of the Book of Allah. Umar had asked for the first one. The sentence he answered with says which of the two Allah is using.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched URL / API key) | Grading | Status |
|---|---|---|---|---|
| 1 | Nāfiʿ b. ʿAbd al-Ḥārith met ʿUmar at ʿUsfān; ʿUmar had employed him over Makkah (beat 3) | `sunnah.com/muslim:817` — Wayback capture `20260511063600`, `id_` raw | **ṣaḥīḥ** (Ṣaḥīḥ Muslim; collection-level, no per-page grade line is printed for Muslim — see limits) | ✅ Arabic on the page reads `أَنَّ نَافِعَ بْنَ عَبْدِ الْحَارِثِ لَقِيَ عُمَرَ بِعُسْفَانَ وَكَانَ عُمَرُ يَسْتَعْمِلُهُ عَلَى مَكَّةَ` |
| 2 | *"Whom did you leave in charge of the people of the valley?"* (beat 3) | same page | ṣaḥīḥ | ✅ `فَقَالَ مَنِ اسْتَعْمَلْتَ عَلَى أَهْلِ الْوَادِي` |
| 3 | The four-turn exchange: *Ibn Abzā / who is he / a mawlā of ours / you left a mawlā in charge of them* (beat 4) | same page | ṣaḥīḥ | ✅ `فَقَالَ ابْنَ أَبْزَى ‏.‏ قَالَ وَمَنِ ابْنُ أَبْزَى قَالَ مَوْلًى مِنْ مَوَالِينَا ‏.‏ قَالَ فَاسْتَخْلَفْتَ عَلَيْهِمْ مَوْلًى` |
| 4 | *"He is a reciter of the Book of Allah, and he knows the obligations."* (beat 4) | same page | ṣaḥīḥ | ✅ `قَالَ إِنَّهُ قَارِئٌ لِكِتَابِ اللَّهِ عَزَّ وَجَلَّ وَإِنَّهُ عَالِمٌ بِالْفَرَائِضِ` — **`عَزَّ وَجَلَّ` is elided on the beat**, see the translation table |
| 5 | ʿUmar attributes the sentence to the Prophet ﷺ (beat 5) | same page | ṣaḥīḥ | ✅ `قَالَ عُمَرُ أَمَا إِنَّ نَبِيَّكُمْ صلى الله عليه وسلم قَدْ قَالَ` |
| 6 | **"Allah raises peoples by this Book, and sets others down by it."** (beat 5) — **bar 1's first carrier** | same page | ṣaḥīḥ | ✅ `إِنَّ اللَّهَ يَرْفَعُ بِهَذَا الْكِتَابِ أَقْوَامًا وَيَضَعُ بِهِ آخَرِينَ` — **quoted whole, no elision** |
| 7 | A second chain for the same matn exists | `sunnah.com/muslim:817b` — Wayback `20260511063600` | ṣaḥīḥ | ✅ Zuhrī ← ʿĀmir b. Wāthila al-Laythī, `بِمِثْلِ حَدِيثِ إِبْرَاهِيمَ بْنِ سَعْدٍ`. **Quoted on no beat** |
| 8 | **"…Allah will raise those who have believed among you, and those who were given knowledge, by degrees…"** (beat 6) — **bar 1's second carrier** | `api.quran.com/api/v4/verses/by_key/58:11?fields=text_uthmani&translations=20,85` | Qurʾān | ✅ `يَرْفَعِ ٱللَّهُ ٱلَّذِينَ ءَامَنُوا۟ مِنكُمْ وَٱلَّذِينَ أُوتُوا۟ ٱلْعِلْمَ دَرَجَـٰتٍ`. **Partial — visible `…` at both ends**; omitted text in the successor table |
| 9 | Successor sweep n−1 | `verses/by_key/58:10` | Qurʾān | ✅ fetched, quoted nowhere, verdict below |
| 10 | Successor sweep n+1 | `verses/by_key/58:12` | Qurʾān | ✅ fetched, quoted nowhere, verdict below |
| 11 | Recorded alternative verse beat, **rejected in favour of 58:11**, on no beat | `verses/by_key/94:4`; `verses/by_key/94:1`, `94:5`, `94:8`; **`verses/by_key/94:9` → HTTP 404** | Qurʾān | ✅ Sūrat ash-Sharḥ is 8 āyāt; **no warning, rebuke or punishment anywhere in it.** Reason for not taking it is in the rejection table |
| 12 | The `r-f-ʿ` enumeration this deck's bar-4 claim rests on | full 6,236-āyah Uthmānī text, `api.quran.com/api/v4/quran/verses/uthmani`, combining marks folded, alif/yāʾ/tāʾ-marbūṭa normalised, consonant-subsequence match, then hand-classified | — | ✅ **29 occurrences in 18 word-forms.** Enumerated in the bar-4 table below. **Run against the full text, not a search API** (ledger §9ac, §9af) |
| 13 | Catalogue id 42's duʿā has **no** narration this pass could find | — | — | ⚠️ **UNPINNED.** Stated as a negative I could not close; see limits. **No catalogue change recommended.** |

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met twice, independently.** (a) Muslim 817a: `إِنَّ اللَّهَ يَرْفَعُ` — **`ٱللَّهُ` is the explicit grammatical subject of a finite verb from the Name's own root**, inside the Prophet's ﷺ own speech. Same construction class as `al-mughni@1`'s `فَأَغْنَاكُمُ ٱللَّهُ`, ruled sufficient at ledger §9a. (b) 58:11: `يَرْفَعِ ٱللَّهُ … دَرَجَـٰتٍ` — Allah named, jussive finite verb, with an object (*those who believed / those given knowledge*) and a measure (*degrees*). **Neither is a participle, an epithet, an appositive, or human speech about Allah.** The 40:15 form `رَفِيعُ ٱلدَّرَجَـٰتِ` — this Name's root as a construct epithet — is bar 1's trap for this Name and is **rejected below**. | **yes — beats 5 and 6** |
| 2 | **the distinguishing quality is shown, not stated** | The deck asserts nothing. No beat says *"true honour comes from Allah"* (that is catalogue id 43's `lesson`, and Al-Muizz is BLOCKED), and no beat says *"knowledge raises you"*. **The story does it structurally:** the same man is described twice, both descriptions true, and the second one settles a governorship. The reader watches a rank change hands before any principle is stated, and the principle when it arrives is the Prophet's ﷺ, not the deck's. | **yes — beats 4 and 5** |
| 3 | **no sibling collapse, including against its own twin** | Three surfaces run separately (§9an). Tables below. **Two disclosures I cannot close and one I ruled on and should not have** — see the bar-3 tables. | **yes, with three disclosures** |
| 4 | **the Name's own root appears in the source text** | **MET, no trade, four times.** `يَرْفَعُ` (Muslim 817a, beat 5) · `يَرْفَعِ` (58:11, beat 6) · `يَا رَافِعُ` and `ارْفَعْ` (duʿā, beat 7, **in Arabic on screen**). The Name-participle `رَافِع` itself renders in Arabic on beat 7. | **yes — beats 5, 6, 7** |
| 5 | **register — no punishment, no battle/curse passage repurposed as comfort, and no arc terminating in punishment just outside the excerpt** | **Clean, and the cleanest row in this pair.** Muslim 817a **ends on the quoted sentence** — there is nothing after it to be dishonest about. 58:11's n+1 (58:12) is the ṣadaqa-before-consultation ruling closing `غَفُورٌ رَّحِيمٌ`; its n−1 (58:10) states that Shayṭān's whispering *"will not harm them at all except by permission of Allah"*. **Neither is a punishment.** No battle, no enemy, no curse, no eschatological threat anywhere in this deck. The one setting detail is an administrative appointment on a road. | **swept both directions** |

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **58:11** (n−1) | **58:10** — *"Private conversation is only from Satan that he may grieve those who have believed, but he will not harm them at all except by permission of Allāh. And upon Allāh let the believers rely."* | **Clean on bar 5 — no punishment.** ⚠️ **Two disclosures.** It renders `ٱلنَّجْوَىٰ`, and shipped `al-ghafur@1`'s entire narrative **is** *an-najwā* (Bukhārī 2441). Different najwā — there it is the private audience with Allah on the Day of Judgement, here it is conspiratorial whispering. It also carries `بِضَآرِّهِمْ` (Aḍ-Ḍārr, 95) and `فَلْيَتَوَكَّلِ` (`al-wakeel@1`, **shipped**). **All three are off-screen: 58:10 is quoted on no beat.** |
| **58:11** (n+1) | **58:12** — *"O you who have believed, when you [wish to] privately consult the Messenger, present before your consultation a charity… But if you find not [the means] — then indeed, Allāh is Forgiving and Merciful."* | **Clean.** A ruling, not a punishment. Closes on `غَفُورٌ رَّحِيمٌ` — `gh-f-r` (four decks) + `r-ḥ-m` (five decks) — **off-screen, quoted nowhere.** |
| **58:11** (its own head) | The āyah opens `يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا قِيلَ لَكُمْ تَفَسَّحُوا۟ فِى ٱلْمَجَـٰلِسِ فَٱفْسَحُوا۟ يَفْسَحِ ٱللَّهُ لَكُمْ ۖ وَإِذَا قِيلَ ٱنشُزُوا۟ فَٱنشُزُوا۟` — *"…when you are told 'Space yourselves' in assemblies, then make space; Allāh will make space for you. And when you are told 'Arise,' then arise…"* | **Elided, with a visible leading `…` on the beat.** Reason stated plainly: it is a specific etiquette ruling that needs its own occasion to be intelligible, and unpacking it would spend beat 6 on seating arrangements. **Note that it is thematically *favourable* to the deck** — the āyah's own body is about who sits where, i.e. visible rank — so the elision costs the deck rather than helping it. That is the honest direction for an elision to run. |
| **58:11** (its own tail) | `وَٱللَّهُ بِمَا تَعْمَلُونَ خَبِيرٌ` — *"And Allāh is Aware of what you do."* | **Elided, with a visible trailing `…`.** Reason: it is a **trailing epithet naming Al-Khabeer (id 49)**, and rendering another Name's gloss on this deck's only verse beat is the *Restorer* class (§9o row 4). Precedent for the same construction: shipped `al-jabbar@1` on 12:87, `al-mughni@1` on 4:130. **Nothing withheld is a warning.** |
| **Muslim 817a** (what follows) | Nothing. The narration **ends on the quoted sentence**; the page's next entry is 817b, the parallel chain. | **The strongest available bar-5 form for a ḥadīth** — the same shape `al-haleem@1` has on Bukhārī 7378. |
| **Muslim 817a** (chapter heading) | `باب فَضْلِ مَنْ يَقُومُ بِالْقُرْآنِ وَيُعَلِّمُهُ` — *"The virtue of one who acts in accordance with the Qurʾān and teaches it…"* | Recorded because it confirms Muslim's own reading of the ḥadīth is the one this deck takes. Reaches no screen. |

### Bar 3, surface 1 — Arabic roots

| root in this deck | where | renders in Arabic? | collision check |
|---|---|---|---|
| `r-f-ʿ` — the Name's own | Muslim 817a, 58:11, duʿā | **yes, beat 7 only** (`يَا رَافِعُ`, `ارْفَعْ`) — story beats carry `arabic: ""` in 42/42 shipped story beats, and this deck's verse beat is English-only per the plan §7 convention | **`r-f-ʿ` is spent by no shipped or drafted deck.** Its only other live holder is its own twin, `al-khafid@1`, whose **catalogue-locked duʿā renders `وَارْفَعْ`**. Unfixable — see the twin-diff |
| `w-ḍ-ʿ` | Muslim 817a `وَيَضَعُ` | **no** — story beat, `arabic: ""` | ⚠️ **`al-khafid@1`'s beat-5 quotation predicates the SAME verb `وَضَعَ` of Allah.** Disclosed at full strength in the twin-diff. Off-screen in Arabic on both decks |
| `k-t-b` | `ٱلْكِتَاب` | no | no deck |
| `ʿ-l-m` | 58:11 `ٱلْعِلْم`; Muslim 817a `عَالِمٌ` | no | ⚠️ **CORRECTION (verifier): `al-aleem@1` is SHIPPED, not "drafting this wave."** Confirmed against `name_stories.json`: `review_verdict: "good"`, wave 1 (`9d08cab`), closed before this draft began. Its axis is *what is known*; mine is *what carrying knowledge does to a rank*. Its claimed engine is *the appraisal was wrong*; mine is *which fact counted*. **No shared rendered string** — `knowledge` is **n 0** across all 34 decks and appears here once, in a quoted āyah |
| `d-r-j` | 58:11 `دَرَجَـٰتٍ`; duʿā `دَرَجَتِي` | **yes, beat 7** | no deck. ⚠️ **Aḍ-Ḍārr (95)'s catalogue duʿā carries `وَرَفْعًا لِدَرَجَاتِي` — this Name's root AND this word** — and 95 is undecked and must ship paired with An-Nāfiʿ (96). Recorded for whoever takes it |
| `f-r-ḍ` | `ٱلْفَرَائِض` | no | no deck |
| `kh-b-r` | 58:11's elided tail | **no — elided** | Al-Khabeer (49) is BLOCKED (§6e) |
| `n-j-w` | 58:10, 58:12 — **neighbours, quoted nowhere** | no | `al-ghafur@1`'s narrative; off-screen |

### Bar 3, surface 2 — token frequency over all 34 decks

Counted programmatically over **937 rendered beat strings** in `assets/content/name_stories.json`
(every beat field except `arabic`), 2026-08-03. **This is the pass §9ab, §9an and §9as say a phrase
match cannot substitute for.** Beat 7's `primary` was swept **from its first character**, per §9as.

| token this deck renders | n across 34 decks | decks | verdict |
|---|---|---|---|
| `exalter` | **0** | — | clean. This deck's `name_intro` is the first |
| `raise` / `raised` / `raises` / `raising` | **0 / 0 / 0 / 0** | — | **the whole raising vocabulary is unspent** |
| `rank` / `ranks` / `degree` / `degrees` / `status` / `high` / `higher` | **0** each | — | clean |
| `exalted` | **3** | `al-kareem@1`, `al-khaliq@1`, `al-mujeeb@1` | all **doxological** (*"Blessed and Exalted is He"*, *"exalted are You"*, *"Exalted is He"*). Ledger §9o row 2: **disclose, not blocking.** This deck renders *Exalter* as a **Name-gloss**, a different class (§9as row 2) — and no shipped gloss uses the word |
| `book` | **1** — a **hapax** | `al-ghafur@1` beat: *"he is given the book of his good deeds"* | ⚠️ **This is the row a verifier should attack first.** `afraid` n=1 was ruled **blocking** on hapax evidence alone (§9ab). Mine: different referent (the Qurʾān vs a deed-record), different capitalisation, **zero shared 3-gram**, and the two beats do opposite work. **I rule it non-blocking — and §9ab says a drafter may not rule on its own collision, so this ruling is offered to be overturned, not relied on.** No escape hatch exists: `الْكِتَاب` is the ḥadīth's hinge word |
| `umar` | **2** in `al-ghafur@1`'s JSON | `al-ghafur@1` | ⚠️ **CORRECTION (verifier): not a string collision.** `al-ghafur@1`'s shipped JSON renders **`ʿUmar`** (with the ʿayn modifier letter, U+02BF); this deck's beats render plain **`Umar`** (no ʿayn — confirmed by grep on the raw draft, beats 3/4/8). **The two never collide as literal strings on screen.** What is real is the underlying-person disclosure: **`al-ghafur@1`'s is Ibn ʿUmar, the narrator — a different person from ʿUmar b. al-Khaṭṭāb**, this deck's protagonist. Non-blocking, disclosed |
| `slaves` | **1** | `ar-rahman@1` (*"more merciful to His slaves"*) | different referent (Allah's servants vs a social status). This deck renders `slave` / `freed slave`, both **n 0**. Non-blocking |
| `charge` | **3** | `al-lateef@1`, `al-malik@1`, `ar-rahman@1` | ordinary register; no shared run ≥3 |
| `valley` | **5** | `al-baseer@1`, `al-mumin@1` | ⚠️ `al-baseer@1`'s valley is **Ibrāhīm's empty valley at Makkah**; mine is the ḥadīth's own `أَهْل الْوَادِي`, **also Makkah**. Same city, same word, different centuries and opposite content (an empty valley vs its administration). Non-blocking, **disclosed** — no rewording available, it is the narration's word |
| `bedouin` / `mawla` / `freedman` / `reciter` / `knowledge` / `appointed` / `assemblies` / `believe`(sing.) | **0** each | — | clean |
| `believed` | **6** | `al-haqq@1`, `al-qadir@1`, `al-wasi@1`, `ar-raheem@1` | Qurʾānic formulaic register; §9o row 1 |

### Bar 3, surface 3 — the move

**No mechanical pass reaches this (§9an, §9aq). Read against the shipped decks, not their tokens.**

| shipped/drafted deck | why a user could think they had been told the same thing twice | measured difference |
|---|---|---|
| **`al-fattah@1` [S]** — *"None of the gatekeepers you fear … can withhold what He opens."* | Both decks contain a gatekeeper being overruled: ʿUmar objects, and the objection does not hold. | **`al-fattah@1`'s move is that the gate opens regardless of who holds it.** Mine is that **the gate opened by the ordinary route** — Nāfiʿ persuaded ʿUmar with a reason, and ʿUmar accepted it. Nothing is overridden; a different criterion is produced and it wins on its merits. The consolation differs: al-Fattāḥ says *the gatekeeper is not the decider*; mine says *the qualification that decides is one you can be carrying already*. **Disclosed, ruled non-blocking, offered to be overturned.** |
| **`al-aleem@1` [S]** — *"the appraisal was wrong"* | ⚠️ **CORRECTION (verifier): SHIPPED, not "drafted this wave."** Wave 1, closed before this draft began. Both turn on a spoken description being answered. | In `al-aleem@1` the report is **corrected** (`وَٱللَّهُ أَعْلَمُ بِمَا وَضَعَتْ`). Here **neither answer is wrong** — the deck's whole point is that both are true. Different operation on the same material. Its claim file also cedes *watching/seen/recorded* vocabulary; I use none of it |
| **`al-mughni@1` [S]** — *"the unlisted share"* | ⚠️ **CORRECTION (verifier): SHIPPED, not "drafted this wave."** Wave 1, closed before this draft began. Both are Companion-era administrative scenes with a list. | Explicitly **not** taken as my engine, and named as such in `42.md` before drafting. Al-Mughni's object is **what someone goes home with**; mine is **which description of a person is load-bearing**. Zero shared rendered string |
| **`as-samad@1` [S]** — *"leaning is not weakness"* | Both concern someone of no standing. | as-Samad is about **need**; this deck is about **rank**. No overlap in text or engine |
| **`al-khafid@1`** (its twin) | — | **See the twin-diff, which is its own section.** |

### The twin-diff — `ar-rafi@1` against `al-khafid@1`, beat by beat

**Bar 3 says no sibling collapse *including against each other*. This is the section that answers it.
Run on all three surfaces plus the beat-by-beat diff the brief requires.**

| beat | `al-khafid@1` | `ar-rafi@1` | separated? |
|---|---|---|---|
| 1 bridge | something you had was ahead and isn't now | someone described you correctly, and it was the smaller true thing | **yes** — loss vs description. Zero shared 3-gram |
| 2 name_intro | *The Abaser — the One who brings down whatever rises* (catalogue + authored gloss) | *The Exalter* (catalogue, no gloss) | **yes.** ⚠️ **Both glosses are catalogue-locked antonyms; nothing can separate the concepts.** What is separated is that one carries an authored gloss and the other does not |
| 3–5 story | Bukhārī, Anas, the Prophet's ﷺ lifetime, a **camel**, a race, a collective feeling, **no person changes rank** | Muslim, Abū al-Ṭufayl, ʿUmar's caliphate, a **named man**, an appointment, a two-person argument, **a person's rank changes** | **yes, on every axis I can measure**: collection, narrator, decade, setting, protagonist type, object, and whether anyone's standing moves |
| 5 quoted sentence | *"…nothing in this world is raised except that He lowers it."* | *"Allah raises peoples by this Book, and sets others down by it."* | ⚠️ **THE REAL HIT, disclosed at full strength.** Both are one-sentence Prophetic statements about Allah raising and lowering, **both predicate `وَضَعَ` of Allah**, and both render *raise*-family and *down*-family English. **No rendering choice changes the Arabic fact.** What differs: the **object** (`أَقْوَامًا` — peoples, vs `شَىْءٌ مِنَ الدُّنْيَا` — a thing of this world), the **instrument** (`بِهَذَا الْكِتَابِ` — named, vs none), and the **load** — here the deck's whole weight is on `يَرْفَعُ` and the second clause is quoted only because eliding it would be batch-2 rule 2; there the whole weight is on `وَضَعَهُ`. **Longest shared multiword run between the two beats: 0 at n≥3.** A verifier should decide whether that is separation or decoration |
| 6 verse | 28:83, the **Hereafter's** house, assigned to those who seek no superiority here | 58:11, **this world's** assembly, degrees given to believers and to those given knowledge | **yes** — opposite world, opposite direction, different sūrah, no shared āyah, no shared run |
| 7 duʿā | catalogue id 41 | catalogue id 42 | ❌ **NOT SEPARATED, AND NEITHER DECK CAN FIX IT.** The two `dua_translation`s share a **5-word byte-identical run — *"raise my rank with You"*** (computed, not eyeballed), and id 41's `dua_arabic` renders **`وَارْفَعْ`**, *this* Name's root, in Arabic on the **other** deck's screen. Shared Arabic runs ≥2 words: **0**; shared single tokens: `عِنْدَكَ`. Both beats are gate-locked byte-identical to the catalogue. **Escalates to the catalogue track** |
| 8 takeaway | *positions are borrowed* + the pair-synergy line | *which fact counted* | **yes.** Different engines, no shared 4-gram |

**Summary in one line:** they are not one deck twice with the polarity flipped — the objects, the
protagonists, the collections, the centuries and the engines all differ — **but they are not
separable on the raise/lower vocabulary, and the duʿā screens collide in five identical words that
no deck can remove.** That is the accurate statement; anything stronger would be an adjective
standing where a number belongs (§9ak).

### Translation decisions, itemised (plan §6 rule 2)

| rendered on a beat | published English on the fetched page | what I did, and why |
|---|---|---|
| *"Allah raises peoples by this Book, and sets others down by it."* | *"By this Book, Allah would exalt some peoples and degrade others."* | **Re-rendered from `إِنَّ اللَّهَ يَرْفَعُ بِهَذَا الْكِتَابِ أَقْوَامًا وَيَضَعُ بِهِ آخَرِينَ`.** Four changes: (a) **word order restored** — the Arabic fronts `إِنَّ اللَّهَ`, and the published English fronts the instrument, which moves the subject off the front of the deck's bar-1 sentence; (b) *exalt* → **raises**: `يَرْفَعُ` is a plain verb and *exalt* collides with the doxological *"Exalted is He"* on three shipped decks; (c) *degrade* → **sets down**: `وَضَعَ` means *to set down / lower* and carries **no moral-humiliation sense**, which *degrade* imports — and it is the register bar 5 exists to police on this Name's twin; (d) *would* → **present tense**, matching the imperfective. ⚠️ **Disclosed against myself: change (c) also happens to reduce the string overlap with `al-khafid@1`'s beat 5. It is defensible on its own terms — but a founder should know a translation choice with a collision benefit was made, per §9q.** |
| *"a reciter of the Book of Allah, and he knows the obligations"* | *"He is well versed In the Book of Allah… and he is well versed In the commandments and injunctions (of the Shari'ah)."* | Re-rendered. `قَارِئٌ لِكِتَابِ اللَّهِ` is literally **a reciter of**, not *well versed in* — and *reciter* is what makes the sentence about the Qurʾān rather than about scholarship in general, which is the deck's hinge. `عَالِمٌ بِالْفَرَائِضِ` → *knows the obligations*; the page's *"(of the Shari'ah)"* is an unmarked interpolation and is dropped. **`عَزَّ وَجَلَّ` is elided** — a doxology, not content; noted here rather than marked on the beat, since marking an elided doxology with `…` inside a spoken line would read as omitted argument |
| *"One of our freed slaves"* / *"You left a freed slave in charge of them?"* | *"He is one of our freed slaves."* / *"So you have appointed a freed slave over them."* | Kept the page's rendering of `مَوْلًى مِنْ مَوَالِينَا`. **`mawlā` was considered and rejected**: it is scholar-register and opaque to the deck format's stated reader (spec §4). The available alternative is *"a client of ours"*, which is accurate and equally opaque. **`فَاسْتَخْلَفْتَ` is a question in the Arabic's flow** and is punctuated as one |
| *"…Allah will raise those who have believed among you, and those who were given knowledge, by degrees…"* | Saheeh: *"…Allāh will raise those who have believed among you and those who were given knowledge, by degrees."* | **Saheeh, byte-checked against the Arabic word by word, with `Allāh` → `Allah`** (the one character-level change all 34 decks make). No interpolation, no bracket. Abdel Haleem was fetched; not taken |

### Rejected — fetched, evaluated, and recorded so nobody re-derives it

**The full-text `r-f-ʿ` enumeration: 29 occurrences, 18 word-forms.** Every one classified:

| citation | form | verdict |
|---|---|---|
| **58:11** | `يَرْفَعِ ٱللَّهُ` | **TAKEN — verse beat** |
| **94:4** | `وَرَفَعْنَا لَكَ ذِكْرَكَ` | **Clean, and NOT TAKEN.** Allah's own first person; **`verses/by_key/94:9` → HTTP 404**, so Sūrat ash-Sharḥ is sūrah-final with no warning, rebuke or punishment anywhere — the maximal bar-5 form. Rejected only because **its object is the Prophet ﷺ alone**, giving the user no share, where 58:11 names *those who believed among you*. **Free and strong; recorded as this deck's one-line alternative if the founder rejects 58:11 on the al-baseer@1 sūrah adjacency.** ⚠️ 94:1 is on `al-wasi@1`'s rejection list and 94:5–6 on `ar-rauf@1`'s (`.context/claims/87.md`); **94:4 is claimed by nobody** |
| 3:55 `وَرَافِعُكَ إِلَىَّ` · 4:158 `بَل رَّفَعَهُ ٱللَّهُ إِلَيْهِ` | participle / finite, Allah subject | **Bar 1's strongest possible form, and refused.** The raising of ʿĪsā is the most polemicised passage between two faiths; a deck cannot render it without adjudicating (the `an-nur@1` §9j class). 4:157 is the crucifixion denial. And Āl ʿImrān already carries three decks (§9ai). **Blocked, not free** |
| 19:57 `وَرَفَعْنَـٰهُ مَكَانًا عَلِيًّا` | Allah first person | Refused: one āyah, no narrative; `عَلِيًّا` is **Al-Ali (52)**'s Name-word; Sūrat Maryam already carries `as-samad@1` (19:2–7) and `al-haleem@1` (19:90–91). **Free but crowded** |
| 6:83 · 12:76 `نَرْفَعُ دَرَجَـٰتٍ مَّن نَّشَآءُ` | Allah first person | 6:83 closes on the trailing epithets `حَكِيمٌ عَلِيمٌ` (Al-Hakeem 26 **BLOCKED**, Al-Aleem 14 — ⚠️ **CORRECTION (verifier): SHIPPED, not "claimed this wave"**). 12:76 is in Sūrat Yūsuf, which carries **two shipped decks** (`al-jabbar@1`, `al-lateef@1`) |
| 2:253 `وَرَفَعَ بَعْضَهُمْ دَرَجَـٰتٍ` | Allah subject | Refused: the object is **messengers**, which gives the reader nothing to stand in. Sūrat al-Baqara already carries five decks |
| 6:165 `وَرَفَعَ بَعْضَكُمْ فَوْقَ بَعْضٍ دَرَجَـٰتٍ` | Allah subject | **Bar 5 fails inside the same āyah** — it closes `إِنَّ رَبَّكَ سَرِيعُ ٱلْعِقَابِ` |
| 43:32 `وَرَفَعْنَا بَعْضَهُمْ فَوْقَ بَعْضٍ دَرَجَـٰتٍ` | Allah first person | Refused: it establishes **worldly hierarchy as a given** (`لِيَتَّخِذَ بَعْضُهُم بَعْضًا سُخْرِيًّا`), which is the opposite of this deck's engine |
| 35:10 `وَٱلْعَمَلُ ٱلصَّـٰلِحُ يَرْفَعُهُۥ` | subject contested | Refused: the subject is exegetically disputed; **`عَذَابٌ شَدِيدٌ` is in the same āyah**; Sūrat Fāṭir already carries `al-fattah@1` (35:2) and `al-haleem@1` (35:45) |
| 7:176 `وَلَوْ شِئْنَا لَرَفَعْنَـٰهُ بِهَا` | counterfactual | Refused: a **negative construction** (ledger's rejected class), attached to the dog simile and a named reviled figure |
| 2:63 · 2:93 · 4:154 `وَرَفَعْنَا فَوْقَكُمُ ٱلطُّورَ` | Allah first person | Refused: the mount raised over Banū Isrāʾīl is a **covenant under threat**, i.e. bar 5's register |
| 13:2 `ٱللَّهُ ٱلَّذِى رَفَعَ ٱلسَّمَـٰوَٰتِ` · 79:28 `رَفَعَ سَمْكَهَا` · 55:7 `وَٱلسَّمَآءَ رَفَعَهَا` | Allah subject, **physical** | Refused: raising the sky is not raising a rank, i.e. bar 2 (it would show the wrong quality). 13:28 is `as-salam@1`'s; 79:24 is ledger-rejected; ar-Raḥmān is Ar-Raḥmān's own sūrah |
| 40:15 `رَفِيعُ ٱلدَّرَجَـٰتِ` | **construct epithet** | Refused: **bar 1's named trap for this Name.** It states the attribute rather than showing the act |
| 2:127 (Ibrāhīm) · 12:100 (Yūsuf, and `al-lateef@1`'s āyah) · 49:2 (a command to people) · 24:36 (passive) · 52:5, 56:34, 80:14, 88:13, 88:18 (physical / passive / furnishings) | human, passive or physical | Not candidates |

**Also fetched and rejected, off the root:** **Ṣaḥīḥ Muslim 2588** (`وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ
إِلاَّ رَفَعَهُ اللَّهُ`, ṣaḥīḥ) — this is the source of the card `hadith` on **both** id 41 and id
42, and for id 42 it is topically **correct**. Refused as the deck's spine because it is a
**statement, not a narrative** (bar 2, the `al-haleem@1` rev-1 failure), and its other two clauses
carry `بِعَفْوٍ` (`al-afuw@1`'s Name), `عِزًّا` (Al-Muizz 43) and a charity-does-not-decrease-wealth
clause adjacent to `al-kareem@1`'s engine. **It corroborates the deck and is quoted on no beat.**

### Cross-wave, from the re-read of `.context/claims/` (§9s)

`.context/claims/` held **10** files when I claimed and **20** when I wrote these tables. The eight
new ones were read. Two bear on this deck:

- **`45.md` (As-Sami)** independently examined **Sūrat al-Mujādila** and moved off it because
  **58:1 is spent by shipped `al-baseer@1`**. That makes mine the **second** deck to render from
  al-Mujādila and the **third** to have examined it. 58:1 and 58:11 are **ten āyāt apart, both
  verse beats** — the same shape as `al-qayyum@1`/`al-ghaffar@1` in az-Zumar (eleven apart,
  disclosed non-blocking) and looser than the open 21:83/21:87 founder call (four apart).
  **Disclosed, not resolved.** My one-line escape is 94:4, costed above.
- **`24.md` / `25.md` (Al-Qabid / Al-Basit)** are **the other antonym pair in this wave**, and their
  drafter reached a structurally identical finding: *"the Qurʾān never predicates contraction of
  Allah on its own."* Mine is *"Allah is the subject of a `kh-f-ḍ` verb in zero āyāt."* **Two
  independent pairs, one wave, the same shape.** Neither deck renders that finding on a beat — it is
  a verification fact, not content — but the coordinator should know it happened twice.
  **No scripture overlap:** they hold 25:45–46, 2:245, 30:48, Bukhārī 1013/933; I hold none of it.

### Ship-gate notes

- **`ar-rafi@1` must NOT enter `renderedDuaSources`.** Catalogue id 42's duʿā is an authored
  invocation; no narration was found. A `source` on beat 7 would assert a provenance the text does
  not have and **fails the gate in the other direction** (the map is exhaustive, not a whitelist).
- **Beat 7 is byte-identical to catalogue id 42** — `dua_arabic`, `dua_transliteration`,
  `dua_translation`, unmodified.
- **Beat 6 renders no Arabic**, matching the 11/14 majority convention (plan §7).
- **Rendered `source` strings use ASCII `Qur'an`** — the deck's prose uses `Qurʾān`, beat 6 does not.
- **Deck-internal beat-to-beat diff (§9v, §9al): zero pairs share a run ≥4 words.** Run over all 28
  beat pairs before the cross-deck sweep.

### What I could not determine, and what a verifier should attack first

1. **Ṣaḥīḥ Muslim carries no per-page grade line.** *"ṣaḥīḥ"* here is a **collection-level
   inference**, exactly as §9ag records for Bukhārī 6227. Abū Dāwūd and Nasāʾī pages print grades;
   Bukhārī and Muslim pages do not.
2. **Ḥadīth checking is not independent of sunnah.com as a corpus.** Wayback captures of
   sunnah.com pages are still sunnah.com's digitisation. **No isnād was audited**; no printed
   edition, Shamela or Dorar was consulted. Plan §6's standing limit.
3. **The duʿā's negative is unclosed.** I did not find a narration for catalogue id 42's duʿā. I
   cannot prove one does not exist. **UNPINNED is the safe verdict and I recommend no catalogue
   change** — three of three prior confident recommendations to change catalogue data have been
   wrong (§8.4, §9d).
4. **The two rows to attack first:** (a) the `book` hapax against `al-ghafur@1` — I ruled on my own
   collision, which §9ab says a drafter may not do; (b) the twin-diff's beat-5 row, where both decks
   quote a Prophetic sentence predicating `وَضَعَ` of Allah and I claim separation on object, load
   and instrument rather than on strings.
5. **`al-fattah@1`'s gatekeeper adjacency is an argument, not a measurement.** Zero shared strings;
   the difference I claim is interpretive.

---

## The pairing verdict — stated here too, so neither file can be read alone

**Ar-Rafiʿ can ship alone. Al-Khafid cannot.** The full evidence is in
[`2026-08-03-al-khafid-DRAFT.md`](./2026-08-03-al-khafid-DRAFT.md) and `.context/claims/41.md`. The
one-line version: **`kh-f-ḍ` occurs 4 times in the whole Qurʾān and Allah is the subject in none of
them**, the only ṣaḥīḥ routes predicating it of Allah are unusable, every narrative of Allah
lowering a named person is a destruction arc, and **id 41's own gate-locked duʿā screen already
renders this Name's root and five of this Name's duʿā's English words.**

**If the founder ships only one of the two, it must be this one.** If both ship, Al-Khafid should be
`position_in_pair: 1` so its last beat hands the user here — **and that mechanism does not exist for
non-chip decks today.** See `al-khafid@1`'s draft for the measurement.
