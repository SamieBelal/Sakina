# Deck Draft — Al-Ghaniyy (catalogue id 92, *The Self-Sufficient*) — **NO DECK. REASONED REFUSAL.**

**Drafted 2026-08-03.** Claim filed at [`.context/claims/92.md`](../../../.context/claims/92.md)
**before** this document, and re-read against the full claims directory (32 files at write time)
immediately before the verification table below. Protocol:
[`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full including §9 (§9ab, §9aj,
§9ak, §9an, §9as, §9ba especially). Precedent for this deliverable's shape:
[`2026-08-03-allah-name-id-1-REFUSAL.md`](./2026-08-03-allah-name-id-1-REFUSAL.md).

Per plan §7a.2 (founder, 2026-08-03): **this is not a rejection of the Name.** It is the §6e class —
*not draftable under today's constraints* — with every constraint named and every candidate verse
fetched, graded and disposed of on the record, so no future drafter re-spends the sweep.

All scripture below was fetched live at draft time. Qurʾān: `api.quran.com/api/v4` (Saheeh
International, resource `20`) — the **entire Qurʾān, all 114 sūrahs**, assembled locally via
`verses/by_chapter` for the full-text root sweep. Ḥadīth: Wayback capture of the exact bare
`sunnah.com`/`tirmidhi` number via the CDX API. **Nothing here was recalled, reconstructed or
composed.**

---

## 0 · The one-line finding

**Every Qurʾānic occurrence of `الْغَنِيُّ` predicated of Allah — 18, full-text swept — falls into
one of four classes. All four are closed**: (A) the self-benefit idiom, which collides by a
**computed rendered-string match** with shipped `al-kareem@1`'s own verse beat; (B) a static
possession/ownership epithet with no demonstrated act; (C) conditioned on disbelief or withholding —
a rebuke register, not a comfort one; (D) a charity-context epithet that either collides directly
with shipped `al-haleem@1`'s gloss or sits beside a register-risky parable. **No occurrence clears
bars 1, 2, 3 and 5 at once.**

---

## 1 · Selection ran duʿā-first, per the standing rule

**Catalogue id 92's `dua_arabic` is not an independent invocation. It is a truncated fragment of the
exact narration that already underlies shipped `ar-razzaq@1`'s (id 13) full duʿā.**

| | id 13 Ar-Razzaq (shipped) `dua_arabic` | id 92 Al-Ghaniyy `dua_arabic` |
|---|---|---|
| text | `اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ` | `اللَّهُمَّ أَغْنِنِي بِفَضْلِكَ عَمَّن سِوَاكَ` |

**Jamiʿ at-Tirmidhi 3563** (narrated ʿAlī b. Abī Ṭālib; graded *ḥasan gharīb* by at-Tirmidhi himself,
printed *Ḥasan (Darussalam)*) reads: `قُلِ اللَّهُمَّ اكْفِنِي بِحَلاَلِكَ عَنْ حَرَامِكَ وَأَغْنِنِي
بِفَضْلِكَ عَمَّنْ سِوَاكَ`. Id 13's `dua_arabic` is that hadith minus the imperative `قُلِ` ("say").
**Id 92's `dua_arabic` is only the second half of that same sentence**, with the connective `وَ`
("and") swapped for a fresh vocative `اللَّهُمَّ`. Four of id 92's five words are, skeleton-folded,
byte-for-byte the hadith's own closing four words.

**No pin is proposed.** Pinning id 92 to Tirmidhi 3563 would put two decks — one of them shipped and
currently **unpinned** — on the same narration, with id 92 rendering a subset of what id 13's fuller
text already covers. This is reported as a finding, per the standing rule that a drafter's
recommendation to touch catalogue data or `renderedDuaSources` has been wrong in every prior instance
in this project (COLLISION-LEDGER §8, §9l, §9u). **No change is recommended to either Name's `dua`
fields.**

---

## 2 · Bar 4 — the full-text sweep, and the count summed against its own breakdown

**Method:** all 114 sūrahs fetched via `verses/by_chapter` (`text_uthmani`, `translations=20`),
combining marks stripped, alef/yāʾ/tāʾ-marbūṭah forms folded, every word tested by exact-match
against the `غني` skeleton (a subset test, not a search API). **Run twice, independently, with
consistent results.** `corpus.quran.com`'s search interface was queried for cross-check; it did not
return a scrapable result set from this environment (a stated method limit, not a substitute
verification — see §7).

**20 raw hits; 2 are false positives (human "rich": 4:6, the orphan's guardian; 4:135, the party being
testified about) — 18 survive as Allah-predicated.** Classified into four clusters, and the
arithmetic is stated so it can be checked against the headline: **A = 3, B = 3, C = 10, D = 2.
3 + 3 + 10 + 2 = 18.**

### Cluster A — the self-benefit idiom (`man faʿala fa-innamā yafʿalu li-nafsihi … fa-inna [Rabbahu]
ghaniyyun [epithet]`) — **3 āyāt, and it is spent**

| citation | text (excerpt) | verdict |
|---|---|---|
| **27:40** | `وَمَن كَفَرَ فَإِنَّ رَبِّى غَنِىٌّ كَرِيمٌ` | **SPENT — shipped `al-kareem@1`'s own verse beat**, rendered: *"…And whoever is ungrateful — then indeed, my Lord is Free of need and Generous."* |
| **29:6** | `وَمَن جَـٰهَدَ فَإِنَّمَا يُجَـٰهِدُ لِنَفْسِهِۦٓ ۚ إِنَّ ٱللَّهَ لَغَنِىٌّ عَنِ ٱلْعَـٰلَمِينَ` | **This was the leading candidate**, and it fails on a measurement, not a guess. Saheeh renders: *"And whoever strives only strives for [the benefit of] himself. Indeed, Allāh is Free from need of the worlds."* **Computed against the current 34-deck asset: this rendering shares a literal 5-gram with `al-kareem@1`'s `primary` string — "for the benefit of himself"** (both carry Saheeh's identical bracket for the same recurring Qurʾānic construction), and the payload clause differs from `al-kareem@1`'s *"Free of need"* by one preposition (*"Free from need"*). Otherwise clean: Allah's own first-person voice (29:2–8 is a first-person passage — `فَتَنَّا`, `يَسْبِقُونَا`, `مَرْجِعُكُمْ`), a first-occurrence sūrah for this Name (Sūrat al-ʿAnkabūt is not yet spent at 29:1–8 — `al-wasi@1` [S] sits at 29:56, 50 āyāt away), and the **cleanest bar-5 successor sweep found in this whole search**: n−1 (29:5) is neutral, n+1 (**29:7**) is a *reward* verse — *"…We will surely remove from them their misdeeds and will surely reward them…"* — softer than any shipped precedent. **Fails bar 3 alone, on a computed string, not a subtle move.** |
| **31:12** | `وَمَن يَشْكُرْ فَإِنَّمَا يَشْكُرُ لِنَفْسِهِ ۖ وَمَن كَفَرَ فَإِنَّ ٱللَّهَ غَنِىٌّ حَمِيدٌ` | **Worse than 29:6** — it repeats 27:40's own verb (`shakara`/`yashkuru`), not merely its frame. Computed: shares an **8-word contiguous run** with `al-kareem@1`'s rendered verse beat (*"and whoever is grateful … for the benefit of himself and whoever … is free of need and"*). Near-total duplicate of already-spent ground. |

**Why this cluster exists at all:** the Qurʾān itself reuses one grammatical template — an act
(gratitude, striving) that "returns only to the one who did it" — and pairs it with `ghaniyy` at
least three times. `al-kareem@1` claimed the cleanest instance (27:40, where the trailing epithet is
`kareem` and the deck's engine is inexhaustible giving). Every other instance of the template inherits
its rendered shape, because Saheeh International translates the underlying Arabic idiom identically
each time.

### Cluster B — static ownership/possession, no demonstrated act — **3 āyāt**

| citation | text | verdict |
|---|---|---|
| **4:131** | `وَلِلَّهِ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۗ … وَكَانَ ٱللَّهُ غَنِيًّا حَمِيدًا` | **One āyah past `al-mughni@1`'s own verse beat (4:130).** Flagged in that draft as *"on no screen"* for their deck, not spent — but taking it here is the tempting neighbour, not an independent find, and it fails bar 2 on its own terms: *"to Allah belongs whatever is in the heavens and earth… and ever is Allah free of need"* **states** ownership; it does not show an act. |
| **22:64** | `لَّهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۗ وَإِنَّ ٱللَّهَ لَهُوَ ٱلْغَنِىُّ ٱلْحَمِيدُ` | Same construction, same bar-2 failure. **Sūrat al-Ḥajj already carries `al-hadi@1`** (22:54) and the `al-quddus@1` draft's own 22:37 — a third citation in this sūrah, on ground that already fails bar 2, is not worth the crowding. |
| **31:26** | `لِلَّهِ مَا فِى ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۚ إِنَّ ٱللَّهَ هُوَ ٱلْغَنِىُّ ٱلْحَمِيدُ` | Same construction, same bar-2 failure, same sūrah as 31:12 above. |

**The pattern these three share is the exact one that killed `al-haleem@1` rev 1**: an epithet
introduced by a possession clause is an assertion, not a demonstration. Bar 2 is not tradeable.

### Cluster C — conditioned on disbelief or withholding — **10 āyāt**

| citation | demonstrated act? | why it is closed |
|---|---|---|
| **14:8** | — | Mūsā's own reported speech (`وَقَالَ مُوسَىٰ`). Human speech about Allah — the 7:196/12:101/10:62/`al-quddus@1`'s-own-10:82-trap class. Not Allah's words. |
| **3:97** | no | `وَمَن كَفَرَ فَإِنَّ ٱللَّهَ غَنِىٌّ عَنِ ٱلْعَـٰلَمِينَ` — pure epithet, closing a Ḥajj-obligation āyah. States, does not show. |
| **10:68** | no | Rebuts the claim *"Allah has taken a son"* with ownership + epithet. A refutation, not a demonstration. |
| **39:7** | partial | The **softest** member: `إِن تَكْفُرُوا۟ فَإِنَّ ٱللَّهَ غَنِىٌّ عَنكُمْ ۖ وَلَا يَرْضَىٰ لِعِبَادِهِ ٱلْكُفْرَ` — *"If you disbelieve, indeed Allah is free of need of you. And He does not approve for His servants disbelief."* The second clause is a genuine act (a stance Allah holds, for the servant's own sake, despite owing them nothing) — but **its own first clause is still `إِن تَكْفُرُوا۟`, "if you disbelieve."** The Name's root cannot be quoted here without that frame attached. |
| **47:38** | yes | `وَإِن تَتَوَلَّوْا۟ يَسْتَبْدِلْ قَوْمًا غَيْرَكُمْ` — *"if you turn away, He will replace you with another people."* An explicit rebuke to those withholding charity. Demonstrated, but addressed as a warning, not offered as comfort. |
| **57:24** | no | `وَمَن يَتَوَلَّ فَإِنَّ ٱللَّهَ هُوَ ٱلْغَنِىُّ ٱلْحَمِيدُ` — epithet, closing a rebuke of stinginess (*"those who are stingy and enjoin upon people stinginess"*). |
| **60:6** | no | Same *"whoever turns away"* epithet-close, following praise of Ibrāhīm's example. |
| **64:6** | no (act is past-tense, aimed at a punished nation) | `وَٱسْتَغْنَى ٱللَّهُ ۚ وَٱللَّهُ غَنِىٌّ حَمِيدٌ` — closes a passage about a disbelieving nation that rejected its messengers. |
| **6:133** | **yes** | `إِن يَشَأْ يُذْهِبْكُمْ وَيَسْتَخْلِفْ مِنۢ بَعْدِكُم مَّا يَشَآءُ` — *"if He wills, He can do away with you and give succession after you to whomever He wills."* The one occurrence pairing `الْغَنِىُّ` with `ذُو ٱلرَّحْمَةِ` (*"possessor of mercy"*) rather than `Ḥamīd` — genuinely distinctive rendered English. **But its context (6:128–131, four to five āyāt back) is a Day-of-Judgment/Fire scene** — jinn and mankind testifying against themselves, entering the Fire — and the address (*"your Lord"*, i.e. the Prophet ﷺ regarding the disbelievers just described) reads as a warning that the audience is replaceable, not a general comfort statement. n+1 (6:134, *"what you are promised is coming"*) and n+2 (6:135, *"the wrongdoers will not succeed"*) are softer, but the passage's own weight sits behind, not ahead. |
| **35:15** (with 35:16–17) | **yes** | `إِن يَشَأْ يُذْهِبْكُمْ وَيَأْتِ بِخَلْقٍ جَدِيدٍ ۝ وَمَا ذَٰلِكَ عَلَى ٱللَّهِ بِعَزِيزٍ` — the cleanest bar-5 sweep of this cluster: n−1 (35:14) is about idols not hearing prayers, n+1 (35:18) is *"no bearer of burdens bears another's… you can only warn those who fear their Lord"* — benign, even instructive. **But Sūrat Fāṭir already carries two decks** (`al-fattah@1` 35:2, `al-haleem@1` 35:45); a third citation on register-risky ground ("O mankind… if He wills, He could erase you and start again") is a stack, not a stray. And the token sweep (below) shows it shares *"free of need the"* as a 4-gram with `al-kareem@1` — the epithet's own recurring gloss, disclosed not blocking on its own, but one more echo on top of the register question. |

**Every member of this cluster is either human speech, a static epithet, or a demonstrated act
inseparable from an address to rejection or withholding.** None is a general, unconditioned statement
suitable for a nightly reflection surface without either dropping the Name's own root (losing bar 4)
or keeping the rebuke frame on screen (a register risk this drafter will not resolve unilaterally —
see §5 below).

### Cluster D — charity-giving context — **2 āyāt**

| citation | verdict |
|---|---|
| **2:263** | `وَٱللَّهُ غَنِىٌّ حَلِيمٌ`. **Fails bar 3 outright** — the trailing epithet is `Ḥalīm`, and *"The Forbearing"* is shipped `al-haleem@1`'s own `name_intro`. A rendered Name-gloss on the wrong Name's screen, the *Restorer* class, unfixable inside a deck. |
| **2:267** | `وَٱعْلَمُوٓا۟ أَنَّ ٱللَّهَ غَنِىٌّ حَمِيدٌ` — *"and know that Allah is Free of need and Praiseworthy."* States, does not show — the same bar-2 defect as Cluster B, introduced by *"know that"* rather than a possession clause. Its immediate successors (2:264–266) carry the bare-rock and burnt-garden parables — register-risky, not pursued past this successor check. |

---

## 3 · The `al-mughni@1` separation — the row a verifier will attack first, answered even though the
deck is not being drafted

**This section exists because the brief demands it explicitly, and because the separation is real —
it was never the axis that blocked this Name.**

**Al-Mughni (93) is Allah *making someone* need nothing — transitive.** Its verse beat, 4:130
(`يُغْنِ ٱللَّهُ كُلًّا مِّن سَعَتِهِۦ`), and its story (Bukhārī 4330, the Anṣār after Ḥunayn) are both
about a **gift-event**: something moves from Allah to a recipient, or is conspicuously withheld while
something else is given instead. **Al-Ghaniyy (92) is Allah *needing* nothing — intransitive.** Every
candidate examined above that survives bar 1 (29:6, 6:133, 35:16, 39:7) contains **no transitive verb
of Allah's own giving act at all.** 29:6's whole point is that no benefit reaches Him in either
direction; 6:133/35:16's "replace you" clause is not a gift to the replaced or the replacement, it is
a demonstration of independence from both. **There is no candidate in this search where Al-Ghaniyy's
material could be mistaken for Al-Mughni's** — the two Names never compete for the same verse, because
their verbs point in structurally opposite directions (nothing flows to Him vs. something flows from
Him). **The catalogue-level collision the brief names — the shared 3-word English run *"I need no
one"* between ids 92 and 93's `dua_translation`s — is real, disclosed in COLLISION-LEDGER §9c/§6d,
catalogue-locked, and not fixable inside a deck of either Name.** It is not evidence that the two
Names' *content* collapses; it is evidence that their *duʿā English* was authored with overlapping
phrasing. This drafter's own duʿā finding (§1 above) is a sharper, previously-unrecorded instance of
the same class, on the Arabic axis rather than the English one.

**What actually blocked this Name was Al-Kareem, not Al-Mughni** — a collision the brief did not
name, found only by running the mandatory rendered-English sweep against the current 34-deck asset
before selecting an anchor (§2, Cluster A).

---

## 4 · Bar 3, on all three surfaces — measured, not asserted

### 4a · Surface 1 — Arabic roots

`gh-n-y` (the Name's own root) appears, as established, 18 times as Allah's predicate across the
Qurʾān — none reaching a screen, because no deck was written. No other sibling root (`r-ḥ-m`, `gh-f-r`,
`k-r-m`, `ʿ-f-w`) was quoted in any candidate examined above except where explicitly named (Ḥalīm at
2:263, Ḥamīd throughout — not a shipped Name yet).

### 4b · Surface 2 — token frequency over the current 34-deck asset

**Method:** all 734 rendered strings (`label`, `primary`, `arabic`, `transliteration`, `translation`,
`source`) across the 34 decks currently in `assets/content/name_stories.json`, extracted
programmatically; every candidate rendering above tested for shared 3-, 4- and 5-grams.

| candidate | result |
|---|---|
| **29:6** (Saheeh rendering) | **5-gram hit**: *"for the benefit of himself"* → `al-kareem@1` `primary`. **Blocking**, per §2. |
| **31:12** (Saheeh rendering) | **8-word contiguous run** shared with `al-kareem@1` `primary`. **Blocking, and worse than 29:6.** |
| **6:133** (Saheeh rendering) | 4-gram *"free of need the"* → `al-kareem@1` `primary`. Disclosed, not independently blocking (a recurring gloss, not a distinctive insight) — superseded by the register finding in Cluster C. |
| **35:15–17** (Saheeh rendering) | Same 4-gram as 6:133. Same disposition. |
| **39:7** (Saheeh rendering) | No 3-gram-or-longer hit. Clean on this surface alone — still closed by Cluster C's register finding. |
| **47:38** (Saheeh rendering) | 3-gram *"free of need"* → `al-kareem@1` (generic); 3-gram *"you are the"* → four other decks (generic, formulaic — §9o class, not blocking on its own). Superseded by the register finding. |

### 4c · Surface 3 — the move

No deck was written, so no beat-8 insight exists to test against COLLISION-LEDGER §3a's spent-engine
list. **What can be said:** the strongest surviving candidate's implicit engine — *"your effort
circulates back to you, not to Him"* — is, in substance, the same family of comfort as `al-kareem@1`'s
shipped beat 8 (*"You are not drawing on a supply that runs down… the asking costs Him nothing at
all"*). Both land on *He does not need what passes through this transaction.* That the rendered strings
also collide (§4b) is the more severe and easier-to-check version of the same underlying problem —
consistent with COLLISION-LEDGER §9an's rule that a clean token table does not certify bar 3, but here
the token table is **not** clean, which is the more dangerous case, not the milder one.

---

## 5 · What is NOT being ruled here

This drafter does not rule on the register question in Cluster C (6:133 / 35:15–17 / 39:7) — per
COLLISION-LEDGER §9ab, *"a drafter may not rule on its own collision."* The candidates are handed
over whole, with their exact successor sweeps, so a verifier or founder can decide whether *"if He
wills, He could replace you"* is reframeable as comfort (the `ar-raqeeb@1`/`al-khafid@1` precedent) or
is inescapably a rebuke on this Name's specific material.

---

## 6 · `Claim | Source | Grading | Status`

| # | Claim | Source (URL) | Grading | Status |
|---|---|---|---|---|
| 1 | Full-text `gh-n-y` sweep — 114 sūrahs, 18 Allah-predicated occurrences of `الْغَنِيُّ` | `api.quran.com/api/v4/verses/by_chapter/{1..114}?fields=text_uthmani&translations=20` | Qurʾān | ✅ fetched live 2026-08-03, all 114 chapters; word-level regex match on a mark-folded skeleton, run twice independently, same 18-āyah result both times. `corpus.quran.com` search queried as cross-check; did not return a scrapable result set from this environment — **stated limit, not a substitute verification.** |
| 2 | 27:40 is shipped `al-kareem@1`'s verse beat, verbatim | `assets/content/name_stories.json`, `al-kareem@1` beat `kind: verse` | Qurʾān | ✅ read directly from the shipped asset (not re-fetched from quran.com — the asset is itself the ship-gate-enforced source of truth for what renders); cross-checked against a live `api.quran.com` fetch of 27:40, text matches Saheeh International to the same substring. |
| 3 | 29:6 — Allah's own first-person voice (29:2–8), clean bar-5 successor, shares a 5-gram with `al-kareem@1` | `api.quran.com/api/v4/verses/by_key/29:2` through `29:8?fields=text_uthmani,text_imlaei&translations=20` | Qurʾān | ✅ fetched live 2026-08-03, each āyah individually; n-gram collision computed programmatically against all 734 rendered strings of the 34-deck asset, not eyeballed. |
| 4 | 31:12 shares an 8-word run with `al-kareem@1`'s rendered verse beat | `api.quran.com/api/v4/verses/by_key/31:12` | Qurʾān | ✅ fetched live; n-gram computed the same way as row 3. |
| 5 | 6:133, its full successor sweep (6:128–137) | `api.quran.com/api/v4/verses/by_chapter/6` (individual āyāt extracted) | Qurʾān | ✅ fetched live 2026-08-03, 6:128 through 6:137 individually read. |
| 6 | 35:15–19, its full successor sweep | `api.quran.com/api/v4/verses/by_chapter/35` (individual āyāt extracted) | Qurʾān | ✅ fetched live 2026-08-03, 35:10 through 35:19 individually read. |
| 7 | 39:7, its wording | `api.quran.com/api/v4/verses/by_chapter/39` | Qurʾān | ✅ fetched live 2026-08-03 (chapter dump), cross-read against the by-chapter data. |
| 8 | 4:131 is one āyah past `al-mughni@1`'s verse beat (4:130), and is disclosed *"on no screen"* in that draft | `docs/superpowers/content/decks/2026-08-03-al-mughni-DRAFT.md` §"What comes immediately after (and before) each excerpt" | — | ✅ read directly from the sibling draft, not re-derived. |
| 9 | 93:8 recorded BLOCKED | `docs/superpowers/content/decks/2026-08-03-al-mughni-DRAFT.md` §"Authoring notes" | — | ✅ read directly from the sibling draft; not retried here. |
| 10 | Ṣaḥīḥ Muslim 2577a is shipped `al-quddus@1`'s entire story (beats 2–4) | `docs/superpowers/content/decks/2026-08-03-al-quddus-DRAFT.md` §2 | ṣaḥīḥ (per that draft's own verification) | ✅ read directly from the sibling draft; not re-fetched here, since it is not being spent by this deck. |
| 11 | Id 92's `dua_arabic` is a fragment of Jamiʿ at-Tirmidhi 3563 | `web.archive.org/web/20260608103401id_/https://sunnah.com/tirmidhi:3563` | **ḥasan gharīb** (at-Tirmidhi's own words, on the page) / printed **Ḥasan (Darussalam)** | ✅ verified by live fetch. Narrator: ʿAlī b. Abī Ṭālib. Arabic on the page: `قُلِ اللَّهُمَّ اكْفِنِي بِحَلاَلِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ`. String-compared against id 13 and id 92's `dua_arabic` programmatically. |
| 12 | Id 13 (Ar-Razzaq)'s `dua_arabic` and id 92 (Al-Ghaniyy)'s `dua_arabic`, exact catalogue text | `assets/content/collectible_names.json` | catalogue | ✅ read programmatically, both records, full JSON. |
| 13 | 2:263's trailing epithet `Ḥalīm` collides with shipped `al-haleem@1`'s `name_intro` | `api.quran.com/api/v4/verses/by_key/2:263`; `assets/content/name_stories.json` `al-haleem@1` | Qurʾān / catalogue | ✅ both fetched/read; `name_intro` primary is *"The Forbearing"* verbatim in the asset. |
| 14 | 2:264–266 (successor of 2:267) carry the bare-rock and burnt-garden parables | `api.quran.com/api/v4/verses/by_chapter/2` (extracted) | Qurʾān | ✅ fetched live (part of the full chapter-2 sweep); read for register only, not quoted. |
| 15 | 22:64 sits in a sūrah already carrying `al-hadi@1` (22:54, shipped) and `al-quddus@1`'s draft (22:37) | `assets/content/name_stories.json`; `docs/superpowers/content/decks/2026-08-03-al-quddus-DRAFT.md` §2 | — | ✅ cross-read against both sources. |
| 16 | Token/n-gram sweep of every candidate rendering against the 34-deck asset | `assets/content/name_stories.json` (34 decks, 734 rendered strings, extracted programmatically) | — | ✅ run; results in §4b, reproducible. |
| 17 | Successor sweep for 29:6 — 29:5 (n−1), 29:7 (n+1) | `api.quran.com/api/v4/verses/by_key/29:5`, `29:7` | Qurʾān | ✅ fetched live individually. |

---

## 7 · Method limits, stated because this refusal will be signed against

1. **The full-text sweep is a word-level regex match on a locally-assembled, mark-folded corpus, not
   a query against `corpus.quran.com`.** The corpus's search page was queried and returned HTML with
   no scrapable result list from this environment; this is disclosed rather than silently skipped.
   The sweep was run **twice, independently**, with the same 18-āyah result both times, and the
   arithmetic (3+3+10+2=18) is summed against the headline per COLLISION-LEDGER §9av's rule.
2. **Ḥadīth verification is not independent of sunnah.com as a corpus.** Tirmidhi 3563 was read from
   one Wayback capture; no printed edition, no Shamela, no Dorar, no isnād audit. Same limit every
   pass in this project has carried.
3. **The register judgement in Cluster C (§5) is explicitly not ruled on.** This drafter states the
   evidence and declines to decide whether 6:133/35:15–17/39:7 can be reframed as comfort. That
   decision belongs to a verifier or the founder, per §9ab.
4. **No deck exists, so no beat-8 engine, no beat-to-beat diff, and no reverence checklist pass (spec
   §"Founder review checklist" items 3–4) were run** — there is nothing to run them against.
