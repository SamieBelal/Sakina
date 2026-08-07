# Deck Draft — Al-Akhir (catalogue id 80) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-awwal-DRAFT.md`](./2026-08-03-al-awwal-DRAFT.md).** Ids 80 and 79 were
assigned and drafted **as a deliberate pair** — they share one catalogue `dua_arabic`, rasm-identical
(COLLISION-LEDGER §6a group 13). Read Al-Awwal's draft first: the twin-diff, the shared-duʿā
verification and the 57:3 accounting are written once, there, and referenced rather than duplicated
here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9bb — **§9am
(55:26–27 reserved for id 89) and the `al-baqi@1`/`as-samad@1` engines are load-bearing for this
Name specifically.**
Claims filed at `.context/claims/79.md` and `80.md` before drafting; `.context/claims/` re-read
immediately before these verification tables.

All scripture verified at draft time by live fetch: Qur'an via `api.quran.com/api/v4`; hadith via
Wayback captures of the exact bare `sunnah.com` number, located via the CDX API. **Nothing here was
recalled, reconstructed or composed.**

---

## Deck `al-akhir@1` — Al-Akhir

**Why this deck exists, in one line:** the user who is sure they are too late, too far behind, or the
last one anyone would bother with. **There is a sahih narration about the literal last person to
leave Hell and enter Paradise — and Allah does not process him. He negotiates with him, personally,
twice, until the man accuses Him of joking.**

**This Name is heavily encircled and the sweep is disclosed at full strength before the deck, not
after.** Shipped `al-baqi@1` (id 98, "The Everlasting") already holds the engine *what outlasts*, on
16:96. `as-samad@1` (id 34) is already glossed "The Eternal Refuge". `55:26–27` is reserved for id 89
(ledger §9am) and was not re-examined here. **Catalogue id 80's own `meaning` and `lesson` fields
overlap `al-baqi@1`'s at the data level** — measured precisely below, not repeated as an adjective.
None of that inherited ground was available to build on; this deck had to find a fourth, distinct
engine, and did not use any of 16:96, 112:2, or 55:26–27.

**Selection ran duʿā-first**, exactly as Al-Awwal's did — see that draft for the full reasoning on why
the shared duʿā and 57:3 could not carry bar 1 on their own.

**The register decision, made first.** "Last" is the failure-adjacent word for someone who already
feels forgotten. So this deck does not render Allah *waiting* on anyone, and does not render the man's
suffering — he is already leaving the Fire when the narration opens. The one thing on screen is
Allah's personal attention to the very last case.

**Proposed metadata**

```json
{
  "deck_id": "al-akhir@1",
  "name_id": 80,
  "transliteration": "Al-Akhir",
  "chip_keys": [],
  "position_in_pair": 2,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED — content; spine incomplete (no reflection beat)"
}
```

**Beat 1 · bridge:**
> Something you're sure is over will, one day, actually be over — all of it. This is the Name for who is still there when it is.

**Beat 2 · name_intro** *(catalogue id 80 `english` verbatim, no authored gloss)*:
> الْآخِرُ — Al-Akhir — The Last

**Beats 3–5 · story — "The last man out":**
> 3. ʿAbdullah ibn Masʿud said the Prophet ﷺ told him he knew who would be the very last person to leave the Fire, and the last to enter Paradise.
> 4. A man comes out of the Fire crawling. Allah says to him: "Go, enter Paradise." He goes — and comes back: "My Lord, I found it full."
> 5. It happens twice more. Then Allah says: "Go and enter Paradise — you will have the like of the whole world, and ten times over." The man says, "Are you mocking me…?" The Prophet ﷺ, telling it, laughed until his back teeth showed.

**Beat 6 · verse** *(partial quotation — visible ellipsis both sides; does not carry bar 1, see below)*:
> "…and the Last…" — Qur'an 57:3 (mid-clause)

**Beat 7 · duʿā** *(catalog id 80, verbatim in full — byte-shared with Al-Awwal's beat 7)*:
> اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ
> *Allahumma anta'l-Awwalu fa laysa qablaka shay', wa anta'l-Akhiru fa laysa ba'daka shay'*
> "O Allah, You are the First — nothing before You. You are the Last — nothing after You."
> **Source: Sahih Muslim 2713a (excerpt)** — full verification in Al-Awwal's draft.

**Beat 8 · takeaway:**
> He left the Fire last, and entered Paradise last — after everyone who had gone ahead had stopped looking back for him. Allah had not stopped keeping his place, or His generosity, for the very last turn.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched URL / API key) | Grading | Status |
|---|---|---|---|---|
| 1 | "I know the person who will be the last to come out of the Fire, and the last to enter Paradise…" through "…you will have what equals the world and ten times as much" (beats 3–5, primary carrier), narrated ʿAbdullah [ibn Masʿud] | `sunnah.com/bukhari:6571` — Wayback capture `20250420215228` | **Sahih** (Sahih al-Bukhari — collection-level; the page prints no separate grade line, same convention as `al-khafid@1`'s Bukhari 2872, §9ag) | ✅ `إِنِّي لأَعْلَمُ آخِرَ أَهْلِ النَّارِ خُرُوجًا مِنْهَا، وَآخِرَ أَهْلِ الْجَنَّةِ دُخُولاً رَجُلٌ يَخْرُجُ مِنَ النَّارِ كَبْوًا، فَيَقُولُ اللَّهُ اذْهَبْ فَادْخُلِ الْجَنَّةَ...فَيَقُولُ اذْهَبْ فَادْخُلِ الْجَنَّةَ، فَإِنَّ لَكَ مِثْلَ الدُّنْيَا وَعَشَرَةَ أَمْثَالِهَا` |
| 2 | The man's question and the Prophet's ﷺ own reaction (beat 5, second half) | same page | Sahih | ✅ `فَيَقُولُ تَسْخَرُ مِنِّي، أَوْ تَضْحَكُ مِنِّي وَأَنْتَ الْمَلِكُ ‏"‏ ‏‏.‏ فَلَقَدْ رَأَيْتُ رَسُولَ اللَّهِ صلى الله عليه وسلم ضَحِكَ حَتَّى بَدَتْ نَوَاجِذُهُ` — **⚠️ the beat elides "though You are the King" (`وَأَنْتَ الْمَلِكُ`) with a visible ellipsis.** Reason: `أَنْتَ الْمَلِكُ` renders in English as shipped `al-malik@1`'s exact Name-gloss ("the King"), whose own beat 5 has Allah say `أَنَا الْمَلِكُ` ("I am the King") in first person. Precedent for eliding a clause specifically to avoid a sibling Name's root/gloss: `al-malik@1` itself drops `وَتُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ` from its own 3:26 quotation to avoid Al-Muizz/Al-Muzill. What survives ("Are you mocking me…?") preserves the man's incredulity without the King reference |
| 3 | Successor sweep, n−1: Bukhari 6570 | `sunnah.com/bukhari:6570` — Wayback `20250207230627` | Sahih | ✅ fetched, quoted nowhere — Abu Hurayra asks who gets the Prophet's ﷺ intercession; answer is anyone who said the shahada sincerely. Same chapter ("The description of Paradise and the Fire"), no punishment, no contradiction |
| 4 | Successor sweep, n+1: Bukhari 6572 | `sunnah.com/bukhari:6572` — Wayback `20231211183016` | Sahih | ✅ fetched, quoted nowhere. `العباس` asks the Prophet ﷺ "Did you benefit Abu Talib with anything?" — the page's own text stops there. **Disclosed as an adjacency risk**: this question is widely known (elsewhere in the same collection, not on this page) to lead into a description of Abu Talib's post-death punishment. Not shown on THIS hadith's page, not quoted, not alluded to on any beat |
| 5 | A parallel of this narration (commonly cited as Sahih Muslim ~186) was independently located by another drafter's sweep for a different Name | `docs/superpowers/content/decks/2026-08-03-al-wasi-DRAFT.md:275` | ṣaḥīḥ, per that draft | ✅ recorded as "Muslim 186 — he crawls out of the Fire", fetched and **rejected there** for Al-Wasi ("no capacity content" for that Name). Not rendered on any beat anywhere — examined ground, not spent ground. **Not independently re-fetched by me**; disclosed as a limit below |
| 6 | "…and the Last…" (beat 6) | `api.quran.com/api/v4/verses/by_key/57:3?fields=text_uthmani,text_imlaei&translations=20` | Qur'an | ✅ same fetch as Al-Awwal's row 6. `text_uthmani`: `هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ...`. Saheeh International: *"He is the First and the Last, the Ascendant and the Intimate…"*. Beat 6 renders only *"…and the Last…"* — double-sided visible ellipsis, does NOT carry bar 1 |
| 7 | The dua (catalog id 80) traced to Sahih Muslim 2713a | `sunnah.com/muslim:2713` — Wayback `20250811110019` | Sahih (collection-level) | ✅ identical finding to Al-Awwal's row 8 — full treatment there, not repeated |
| 8 | Root sweep, ʾ-kh-r | `corpus.quran.com/qurandictionary.jsp?q=Axr` | — | ✅ **250 total occurrences** across 6 derived forms (`ākhir`/hereafter 155, `ākhar`/other 70, Form II "delay" 15, Form V 3, Form X 6, Form X participle 1). Dictionary-page count, same limit as Al-Awwal's row 9 |

---

### The five bars

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met once, in the hadith.** `فَيَقُولُ اللَّهُ اذْهَبْ فَادْخُلِ الْجَنَّةَ` — Allah's own recorded direct speech, said personally to the very last case, twice, escalating each time. **⚠️ Beat 6 does NOT carry bar 1** — same disclosure as Al-Awwal's, and for the same reason (57:3 is appositive, not demonstrative) | **yes — beats 4–5 only** |
| 2 | **the distinguishing quality is shown, not stated** | No beat says "Al-Akhir means Allah remains forever" (catalogue id 80's own `meaning`, not used). The story shows a man who is, by every measure inside the narration, at the very back of the line — and watches Allah's attention to him **increase**, not taper, the longer it takes. The reader never hears a definition of "last"; they watch what happens to the person who is | **yes — beats 4–5** |
| 3 | **no sibling collapse, including against its own twin** | Three surfaces below. Twin-diff is in Al-Awwal's draft (not duplicated). **The heaviest disclosure in this deck is the `al-malik@1` elision (row 2 above) and the `al-baqi@1`/`as-samad@1` engine differentiation below** | **yes, with disclosures itemised** |
| 4 | **the Name's own root appears in the source text** | **Met, not traded.** `آخِرَ` (root `ʾ-kh-r`) appears twice in beat 3's own quotation (`آخِرَ أَهْلِ النَّارِ`, `آخِرَ أَهْلِ الْجَنَّةِ`) — a temporal ordinal, not the grammatical Divine-Name form, describing who the man is, not describing Allah directly. Same class and same honest sizing as Al-Awwal's bar-4 finding | **yes — beat 3, in English (story beats render `arabic: ""`)** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | The excerpt itself opens on the man **already leaving** the Fire — no torment is described or dwelt on. It closes on laughter. n+1 (Bukhari 6572, row 4) carries a disclosed adjacency risk (Abu Talib) but is not a continuation and is not quoted. n−1 (row 3) is clean | **swept both directions; one adjacent-page risk disclosed, non-blocking** |

### Bar 3, surface 1 — Arabic roots

| root in this deck | where | renders in Arabic? | collision check |
|---|---|---|---|
| `ʾ-kh-r` — the Name's own | Bukhari 6571 `آخِرَ` ×2; duʿā `الْآخِرُ`; verse fragment `ٱلْـَٔاخِرُ` | **yes — beats 7 and 6** | Spent by no shipped/drafted deck. Corpus-wide dense (250 occurrences) but dominated by `ākhirah` (hereafter, 155×) and `ākhar` (other, 70×) — neither claimed by any deck on this specific sense |
| `ʾ-w-l` — the twin's root | duʿā `الْأَوَّلُ` (shared string) | **yes — beat 7 only** | Catalogue-locked, unfixable — same finding as Al-Awwal's. See its shared duʿā section |
| `m-l-k` (`الْمَلِكُ`) | Bukhari 6571's own text, **elided** from the beat | **no — deliberately removed** | This is the collision that would have existed against shipped `al-malik@1`. Handled by elision, disclosed above and in the sources table, not by pretending the source text doesn't contain it |
| `kh-r-j` (`خُرُوجًا`, `يَخْرُجُ`) | Bukhari 6571, beats 3–4 | no (story beats render `arabic: ""`) | ordinary; no deck claims it |

### Bar 3, surface 2 — token frequency over all 34 shipped decks (beat 7 swept from its first character, §9as)

| token this deck renders | n across 34 shipped decks | decks | verdict |
|---|---|---|---|
| `crawl*`, `mock*`, `laugh*` (as a verb of the Prophet ﷺ), `back teeth`, `ten times`, `already full`, `enter paradise`, `leave the fire`, `last man`, `every earlier arrival` | **0** each | — | clean — computed programmatically, this deck's entire distinctive vocabulary is unspent |
| `last` | **11** — `al-kareem@1` (×5, all "the last third of the night"), `al-mujeeb@1`, `al-baqi@1` (×2), `an-nur@1` (×2) | `al-kareem@1`'s is a fixed time-of-night idiom, unrelated sense. `al-baqi@1`'s two hits: *"what Allah has is lasting"* (verse, root `b-q-y` not `ʾ-kh-r`) and *"the only part... that did not last"* (takeaway) | ⚠️ **flagged, resolved below in surface 3** — same word family, different Arabic root, different engine |
| `remain*` / `keep` (as in "keeping his place") | check below | `al-baqi@1` beat 7 duʿā: *"You remain while we perish"* | ⚠️ this deck's beat 8 was drafted to avoid *"remain"* as a verb about Allah for exactly this reason — see the itemised differentiation below |
| `refuge` | **0** in this deck (checked because `as-samad@1` owns it) | — | clean |

### Bar 3, surface 3 — the move, with the three encircling Names named explicitly

| shipped deck | why a user could think they had been told the same thing twice | measured difference |
|---|---|---|
| **`al-baqi@1`** [S] — 16:96, *"the inventory inverts"*, beat 8 counts what's left of a sheep | Both Names are glossed around permanence/lastingness, and both are catalogue-adjacent (`meaning` fields overlap — see the catalogue finding below). | **Al-Baqi's engine is an accounting**: what you had vs. what remains, applied to *things* (a sheep's shoulder, a lifetime's worth of belongings). **This deck's engine is an encounter**: what happens to the *last person*, applied to a *someone*, not a something. Al-Baqi never has a second character on screen; this deck's entire narrative is a dialogue. Zero shared scripture, zero shared rendered string. This deck's beat 8 deliberately avoids the verb *"remain"* — the word `al-baqi@1`'s own duʿā uses about Allah — using instead *"kept his place"*, a claim about attention, not duration |
| **`as-samad@1`** [S] — "The Eternal Refuge", Zakariyya's hidden call, *"leaning is not weakness"* | Both are eschatology-adjacent Names about what a person can rely on. | As-Samad's engine is **need flowing toward Allah** (everyone leans here). This deck's engine is **Allah's attention flowing toward the person**, in the other direction, unprompted — the man in this story does not ask to be found; he is found. Different grammatical subject of the verb of care. No shared vocabulary at n≥3 |
| **id 89 (Dhul-Jalali wal-Ikram)** — 55:26–27 reserved (ledger §9am) | Not examined by this deck — the reservation was read and respected, not re-derived | This deck does not cite 55:26–27, 55:29, or any Sūrat ar-Rahman material |
| **`al-malik@1`** [S] — *"I am the King"* | Handled as a root/gloss elision, not a "move" question — see surface 1 above | The moves are unrelated in any case: Al-Malik is about sovereignty being given and withdrawn; this deck is about a single person's turn, at the very end of the line |

---

## Catalogue findings — reported, **NO change recommended**

1. **Id 80's `meaning` (9 words) is a word-for-word subsequence of id 98 Al-Baqi's `meaning` (10
   words) — measured precisely, not described as a "run".**
   - Id 80: *"The One who remains after all creation has perished."*
   - Id 98: *"The One who remains **forever** after all creation has perished."*
   - Computed with a sequence matcher: two matching blocks, not one — *"The One who remains"* (4
     words) and *"after all creation has perished"* (5 words), split by the single inserted word
     "forever". Every one of id 80's 9 meaning-words appears in id 98's meaning, in the same order.
     **This deck's beats do not use either phrase.**
2. **Id 80's `lesson` — *"Everything ends — except Al-Akhir. Invest in what reaches Him."* — states**
   `al-baqi@1`'s shipped engine (an inventory of what outlasts) in one sentence, as the task brief
   itself names. **Confirmed by re-reading `al-baqi@1`'s beats: its takeaway is exactly this shape**
   ("she counted what they had, he counted what was with Allah"). **This deck's beat 8 does not use
   this sentence, "invest", "reaches Him", or any paraphrase of it** — checked by direct comparison
   above.
3. **Id 80's `hadith` card field** (the "small plant" narration, attributed "Ahmad") **was not used
   as a citation and could not be independently located this pass.** CDX queries for
   `sunnah.com/adab:479` and a guessed `sunnah.com/ahmad:12981` both returned zero captures. **This is
   a negative retrieval result about my query, not a claim that the hadith doesn't exist** (per the
   standing rule at `2026-08-03-allah-DRAFT.md`'s §7, restated: a failed fetch is a property of the
   fetch, not of the source, unless multiple query shapes are exhausted — which they were not here).
   No catalogue change recommended; the card's own citation was not relied on or contradicted.

---

## What I could not determine, and what a verifier should attack first

1. **The Muslim ~186 parallel was not independently re-fetched.** I rely on Bukhari 6571 alone,
   which is sufficient on its own (Sahih, collection-level), but a second collection's exact wording
   was not cross-checked the way `al-khafid@1`'s draft cross-checked Abu Dawud 4802 against Bukhari
   2872. If Muslim's wording differs materially (e.g., in whether it also carries `الْمَلِكُ`), that
   changes nothing here since the beat already elides that clause regardless of collection.
2. **The elision of "though You are the King" is the single highest-value row for a verifier to
   attack.** Two questions worth separating: (a) is the elision itself legitimate (precedent:
   `al-malik@1`'s own 3:26 elisions); (b) does removing it change the man's tone in a way that matters
   theologically. I judge no — the incredulity ("are you mocking me") carries the beat's meaning
   without the King reference — but this is a judgement call, not a measurement, and is flagged as one.
3. **The `ʾ-kh-r` root sweep (250 occurrences) is a dictionary-page count**, same limit as Al-Awwal's.
   Not hand-verified verse by verse.
4. **Ahmad's "small plant" hadith (catalogue id 80's own card citation) remains unlocated.** If a
   verifier can reach it, it should be evaluated as a possible fourth story candidate, not assumed
   unusable — this pass simply ran out of fetch budget on a two-collection-empty CDX result.
5. **Whether the founder wants `position_in_pair: 1/2` enforced by a gate mechanism** is unresolved
   engineering — see Al-Awwal's draft. Not decided here.
6. **The rows to attack first, in order:** (a) the King elision (item 2 above); (b) whether beat 8's
   avoidance of "remain" fully closes the `al-baqi@1` adjacency or merely relocates it; (c) whether
   the disclosed Bukhari 6572/Abu Talib adjacency needs stronger handling than disclosure.
