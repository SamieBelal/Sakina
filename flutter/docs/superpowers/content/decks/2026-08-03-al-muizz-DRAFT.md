# DRAFT — `al-muizz@1` · Al-Muizz (catalogue id 43, *The Bestower of Honor*)

**Drafted 2026-08-03.** Claim file: [`.context/claims/43.md`](../../../../.context/claims/43.md).
**Twin draft, drafted by the same agent in the same pass, and required reading alongside this one:**
[`2026-08-03-al-muzill-DRAFT.md`](./2026-08-03-al-muzill-DRAFT.md). The two share `dua_arabic`
byte-for-byte, and their verse beats are two halves of one Qur'ānic sentence — see **§6, "The shared
duʿā screen,"** present verbatim in both drafts, and **§7, "Can Al-Muzill stand alone?"**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md).

All scripture verified at draft time by **live fetch**: Qur'ān via `api.quran.com/api/v4` (Sahih
International, `translations=20`), including the **full 6,236-āyah Uthmānī mushaf in one call**
(`api.quran.com/api/v4/quran/verses/uthmani`) for the root sweeps below. Ḥadīth via **Wayback
captures of the exact bare `sunnah.com` URL** (sunnah.com 403s automated fetching, confirmed this
session). Nothing here is composed, reconstructed or recalled. **Every ✅ in the Claim table
describes a request issued in this session.**

**Selection method: duʿā-first, and the duʿā is NOT scripture.** Catalogue id 43's `dua_arabic`
is `اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ`. It was searched (Arabic and
transliterated English, multiple phrasings) against sunnah.com's index and general web search
before any story-hunting began. **No ḥadīth collection returned this wording.** One web result
(not a primary source; not independently verified; reported, not acted on) attributes a version of
this line to Aḥmad ibn Ḥanbal as a personal supplication (*athar*), not a Prophetic narration.
**Status: UNPINNED — the same class as catalogue id 8's duʿā** (`.context/claims/8.md`).
`al-muizz@1` must **not** enter `renderedDuaSources`.

---

## 1 · The beats

| # | kind | `primary` | `arabic` | `source` |
|---|---|---|---|---|
| 0 | `bridge` | You did everything right and still heard nothing back. Al-Muizz is the answer to who actually decides who rises. | — | — |
| 1 | `name_intro` | The Bestower of Honor | `الْمُعِزُّ` (translit. `Al-Muizz`) | — |
| 2 | `story` | "Charity does not decrease wealth…" | — | `Sahih Muslim 2588` |
| 3 | `story` | "…no one forgives another except that Allah increases his honor…" | — | `Sahih Muslim 2588` |
| 4 | `story` | "…and no one humbles himself for the sake of Allah except that Allah raises his status." | — | `Sahih Muslim 2588` |
| 5 | `verse` | …You honor whom You will… | — | `Qur'an 3:26` |
| 6 | `dua` | O Allah, honor me through obedience to You, and do not humiliate me through disobedience to You. | `اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ` · translit. `Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik` | **empty — UNPINNED** |
| 7 | `takeaway` | Every raising in that sentence starts with someone who let go of something first — a coin, a grudge, their own name in the room. Al-Muizz was never for the person pushing to the front. | — | — |

`chip_keys: []`, `position_in_pair: 0`. Beat 6 must carry no `source`, and `al-muizz@1` must NOT
enter `renderedDuaSources` (the gate asserts that map bidirectionally). Story beats carry `label`:
*"Not by Force."*

**Transcription note:** deck prose below uses `Qurʾān`; rendered `source` strings use ASCII
`Qur'an`, per plan §7.

---

## 2 · Why this story, duʿā-first — and why the verse beat is only half a sentence

The catalogue duʿā asks for one thing and fears its opposite, in one breath: honor through obedience,
not humiliation through disobedience. It is not scripture (§ above). So selection ran on the
**Names' own roots**, not the duʿā's wording.

### The `ʿ-z-z` enumeration — inherited and re-verified, not re-derived

`.context/claims/8.md` (this same wave, `al-azeez@1`) already ran the full 6,236-āyah sweep for
`ʿ-z-z` and found **exactly three finite verbs**: 38:23 (human subject, rejected), **3:26**
(`وَتُعِزُّ مَن تَشَآءُ` — spent by shipped `al-malik@1`'s verse beat, clause **elided with a
visible ellipsis, left for this pair**), and **36:14** (spent by `al-azeez@1`, drafted this same
wave). **No fourth candidate exists.** I re-read that claim file and independently re-ran the
enumeration over the same full-mushaf fetch (method in §4) rather than trusting the count
unverified — it reproduces.

### The `dh-l-l` enumeration — run fresh this session, because no prior claim covers it

Full 6,236-āyah Uthmānī text fetched in one call, mark-folded, matched on the consonant skeleton
(script, not a search API). 28 word-hits on the bare skeleton `ذل`, excluding the unrelated homograph
`ذلك` ("that"). Of those, 4 are actually a different root (`r-dh-l`, "vile" — `أرذل`/`أراذل`,
excluded). Of the rest, **exactly one word in the whole Qur'ān is a finite verb with Allah as the
grammatical subject, carrying the sense "humiliate a person": `وَتُذِلُّ مَن تَشَآءُ`, 3:26** — the
same sentence, same `وَ`, immediately after the honor clause. Two other Allah-subject occurrences of
the root exist and were read as candidates, not dismissed by pattern-matching alone:

| citation | word | sense | verdict |
|---|---|---|---|
| **3:26** | `وَتُذِلُّ مَن تَشَآءُ` | humiliate a person | **the one candidate** — Al-Muzill's, not this deck's |
| 36:72 | `وَذَلَّلْنَـٰهَا` | "We tamed/subjected [cattle] for them" | different sense entirely (docility, not disgrace) — using it would misdemonstrate the Name |
| 76:14 | `وَذُلِّلَتْ` | Paradise's fruit "made low [for the taking]" | same — ease, not humiliation |

Full table for both roots, and the finding this forces, is in `al-muzill@1`'s draft §3 and §7.

**What this means for THIS deck:** `ʿ-z-z` also returns exactly one unspent candidate — the same
sentence. Al-Muizz's own root sweep is bar-4-forced into 3:26 as surely as Al-Muzill's is.

---

## 3 · The five bars

| # | bar | verdict | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words — not a trailing epithet** | **MET.** `تُعِزُّ` is a finite Form-IV verb, 2nd person, addressed to Allah in the taught prayer (`قُلِ`) — the same construction the ledger calls bar 1's strongest form for `al-afuw@1`'s `وَيَعْفُوا۟`. Not appended, not human speech. | yes — beat 5 |
| 2 | **shown, not stated** | **MET.** No beat asserts "you deserve honor" or "your honor is coming." The ḥadīth shows a mechanism (release something → be raised) without naming the reader; the verse shows the act in Allah's own grammar. | yes |
| 3 | **no sibling collapse, including against the twin deck** | **MET — full sweep, all three surfaces, plus the twin diff. See §5.** | see §5 |
| 4 | **the Name's own root appears in the source text** | **MET, and forced — see §2.** `تُعِزُّ` (`ʿ-z-z`) on the verse beat is the only unspent candidate in the Qur'ān. The story's own root is a bar-4 trade (§2, §4) — Muslim 2588 carries `عِزًّا` as a noun object of a different verb (`زَادَ`, not `ʿ-z-z`), not a finite `ʿ-z-z` verb; disclosed, not hidden. | yes — beats 1, 5 |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **Clean, both texts.** Muslim 2588's neighbours are unrelated hadith (mutual insults; backbiting) — see §4. 3:26's neighbours were independently re-fetched this session (not only inherited from `al-malik@1`): 3:25 sets the Day-of-Judgement scene without wronging anyone; 3:27 runs toward provision; 3:28 is a warning two āyāt out, not quoted or alluded to. | yes |

---

## 4 · Successor sweep — every quotation, fetched independently this session

**Ṣaḥīḥ Muslim 2588** (Book 45, Ḥadīth 90; `web.archive.org/web/20260419211856id_/https://sunnah.com/muslim:2588`):

| | text | verdict |
|---|---|---|
| **n−1 · Muslim 2587** | "When two persons indulge in hurling (abuses) upon one another, it would be the first one who would be the sinner so long as the oppressed does not transgress the limits." | unrelated topic (mutual insult), same narrator (Abū Hurayra) and chain family. No continuation, no punishment bearing on this deck. |
| **n+1 · Muslim 2589** | The definition of backbiting. | unrelated topic. Clean. |

**Qur'ān 3:26** — neighbours independently re-fetched this session (not only inherited from
`al-malik@1`'s claim, though the readings agree):

| | text | verdict |
|---|---|---|
| **n−1 · 3:25** | "…each soul will be compensated [in full for] what it earned, and they will not be wronged." | sets the Day-of-Judgement scene; closes on the *absence* of wrong. Clean. |
| **n+1 · 3:27** | "…And You give provision to whom You will without account." | clean, no punishment; `وَتَرْزُقُ` is shipped `ar-razzaq@1`'s root, one āyah away, off-screen — disclosed, matches `al-malik@1`'s own finding. |
| **n+2 · 3:28** | "…And Allāh warns you of Himself…" | a warning, two āyāt out, not quoted or alluded to. |

**Does the excerpt stop short of the passage's own ending in a way that changes its meaning?** No —
the clause taken (`وَتُعِزُّ مَن تَشَآءُ`) is a complete grammatical unit; both surrounding clauses
are already rendered on shipped `al-malik@1`'s beats (disclosed in §5) or reserved for the twin deck,
never orphaned or hidden.

---

## 5 · Bar 3, run on all three surfaces — plus the twin diff against `al-muzill@1`

### 5a · Surface 1 — Arabic roots

Rendered Arabic exists on two beat kinds only (`name_intro`, `dua`; this deck's `verse` beat carries
none, matching the 11/14 shipped-deck majority, plan §7).

| root | where | on screen? |
|---|---|---|
| `ʿ-z-z` (this Name) | `name_intro` `الْمُعِزُّ` · duʿā `أَعِزَّنِي` | **yes** — beats 1, 6 |
| **`dh-l-l`** (the twin's root) | duʿā `تُذِلَّنِي` | **yes, in Arabic, on the duʿā beat — catalogue-locked**, unfixable by either deck |
| absent from every beat, Arabic and English | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `j-b-r`, `w-k-l`, `q-d-r`, `m-l-k`, `q-b-ḍ`, `b-s-ṭ` | closed by construction |

### 5b · Surface 2 — rendered English against all 34 shipped decks

Method: 595 rendered `primary`/`label`/`source` strings extracted programmatically from
`assets/content/name_stories.json` (34 decks), lower-cased, tokenised, n-gram diffed at widths 7→4.

| finding | verdict |
|---|---|
| "honor whom you will", "let go of something first", "raises his status", "charity does not decrease wealth", "who actually decides who rises" — **zero** hits at n≥4. | clear |
| "This is the Name for…" bridge template — **not used**; this deck's bridge reads *"Al-Muizz is the answer to…"* instead, which shares a 4-gram (`is the answer to`) with shipped `al-hadi@1`'s bridge. | **template class, disclosed, non-blocking** — ledger §4b already treats bridge scaffolding this way. |
| `honor` (n=1 before this deck, from `as-salam@1`'s "Owner of Majesty and **Honor**" — a different Arabic word, `al-ikrām`, not `ʿizz`) → this deck adds it repeatedly. | expected; it is the Name's own English gloss. Disclosed, not a collision — the same class as `al-malik@1`'s "king" going 0→2. |
| `forgives`/`forgive` family (n=11 before this deck, spread across `al-ghaffar@1`, `al-ghafur@1`, `at-tawwab@1`, `al-afuw@1` — none render the word "forgives" itself except this ḥadīth) | ⚠️ **disclosed.** `al-afuw@1`'s own vocabulary is "pardon"/"Pardoner", never "forgive" — checked directly against its draft. Different lexical family for the same root-concept in English; zero shared bigrams with any `al-afuw@1` string. Not blocking. |

### 5c · Surface 3 — the move

| shipped / drafted deck | its move | this deck's move | separated? |
|---|---|---|---|
| `al-muid@1` [D] | *said before believed* — a restoration accepted before it is felt | *letting go first* — release precedes the raising, no restoration involved | yes |
| `al-wahhab@1` [D] (id 12, live sibling claim) | *his word, extended* — an ask exceeded, on people never named | this deck names no unnamed beneficiary; its move is a mechanism, not an excess | yes |
| `at-tawwab@1` [S] | *met mid-road* — acceptance meets the turning | this deck has no turning-back; the ḥadīth's subject already gave something up | yes |

**Engine, three words: `letting go first`.** Checked against ledger §3a's spent list — no match.

### 5d · The twin diff — beat by beat, against `al-muzill@1`

| axis | `al-muizz@1` | `al-muzill@1` | same deck flipped? |
|---|---|---|---|
| genre | Ḥadīth-led (Ṣaḥīḥ Muslim 2588) | Qur'ān-led (7:148, 7:152) | **no** |
| protagonist | none — a mechanism stated about "a servant," no name | Mūsā's people, unnamed as individuals — a communal act | **no**, and asymmetric on purpose |
| domain | charity, forgiving, humbling oneself | an idol that cannot speak or guide | **no** |
| bar-1 carrier | 3:26 `تُعِزُّ` (verse) + Muslim 2588 `زَادَ...عِزًّا` (story, bar-4 trade) | 3:26 `تُذِلُّ` (verse) + 7:152 `نَجْزِى` (story, bar-4 trade) | **structurally parallel by necessity — see §7** |
| the move | *letting go first* | *it was never real* (`al-muzill@1`'s own claim) | **no** |
| register | positive, no punishment anywhere in either text | consequence-bearing but impersonal (an object, not a person, fails) | **no** |
| verse-beat clause | `…You honor whom You will…` | `…You humble whom You will…` | **the two halves of one sentence, each deck rendering only its own half** — see §6 |

**Programmatic n-gram diff, every beat of one against every beat of the other:** zero hits at n≥4
except the bridge-template class already disclosed in §5b. The verse beats share only the 3-gram
`whom you will`, which is the āyah's own repeated grammatical frame across all four of its parallel
clauses (also present in the sovereignty clauses already spent by shipped `al-malik@1`) — not a
collision under the ledger's §9o formulaic-construction ruling.

**Honest statement of the residual:** the two decks are not "the same deck twice with the polarity
flipped." What they share is one duʿā screen (catalogue-forced, §6) and the grammatical shape of a
single Qur'ānic sentence split across two verse beats — disclosed at full strength in §6 and §7, not
buried.

---

## 6 · The shared duʿā screen

*(This section is present verbatim in both drafts.)*

**Catalogue ids 43 and 44 carry byte-identical `dua_arabic`, `dua_transliteration` AND
`dua_translation`.** Verified programmatically against `assets/content/collectible_names.json` on
2026-08-03 — all three fields, exact string equality.

```
arabic:          اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ
transliteration: Allahumma a'izzani bita'atika wa la tudhillani bima'siyatik
translation:     O Allah, honor me through obedience to You, and do not humiliate me through
                 disobedience to You.
```

The ship gate asserts each deck's `dua` beat byte-identical to its own catalogue row by `name_id`.
Both rows are the same string. **Therefore both decks render a pixel-identical duʿā screen — Arabic,
transliteration and translation. This is forced by the gate and is not a drafting choice.**

**What a user who meets both decks sees.** Beats 0–5 and 7 differ completely (§5d: zero shared
4-grams outside the disclosed template class and the āyah's own grammatical frame). **Beat 6 is the
same screen twice.** Unlike most duplicate-`dua_arabic` groups on the ledger (§6a), **this one does
not additionally invoke the other Name in the vocative** — the duʿā addresses `اللَّهُمَّ` (O Allah)
generically, not `يَا مُعِزُّ`/`يَا مُذِلُّ`. So the screen does not tell the user which deck they are
in by naming the wrong Name, which several other duplicate groups do (§6b).

**Three further facts about that screen, measured rather than asserted:**

1. **It is UNPINNED on both decks.** Neither may enter `renderedDuaSources`. My search for a primary
   narration was not exhaustive (§8), and I found none.
2. **⚠️ A 6-word exact English run collides with catalogue id 8 Al-Azeez's duʿā**, drafted this same
   wave (`al-azeez@1`). Id 8: *"O Almighty, **honor me through obedience to You**."* Ids 43/44:
   *"O Allah, **honor me through obedience to You**, and do not humiliate me through disobedience to
   You."* The run *"honor me through obedience to You"* is byte-identical, 6 words, verified by
   direct string comparison of both catalogue rows this session. **Catalogue-locked — no deck can
   change either Name's `dua_translation`.** `.context/claims/8.md` flagged this from the Al-Azeez
   side at claim time; this draft confirms it from the Al-Muizz/Al-Muzill side. **I recommend no
   catalogue change.**
3. **The catalogue's own English ("humiliate") diverges from Saheeh International's rendering of
   3:26 ("humble")** for the same root. Recorded in the translation audit, §8 — a genuine finding,
   not fixed (the catalogue field is gate-locked; the verse beat uses the fetched Qur'ān translation
   as-is, per plan §6 rule 2).

**I recommend nothing about the catalogue.** Three of three prior confident recommendations to change
catalogue data in this project were wrong, in the same direction. This is a report, not a proposal.

---

## 7 · Can Al-Muzill stand alone? (Full analysis in `al-muzill@1`'s own draft; summary here)

**Short answer, stated at this deck's own confidence: it is a materially harder case than this one,
and I judge it should not ship without its twin.** The full reasoning is `al-muzill@1`'s to carry
(its Name, its risk), but the fact that decides it is symmetric and belongs here too: **`ʿ-z-z` and
`dh-l-l` each return exactly one unspent finite-verb candidate in the entire Qur'ān, and it is the
same sentence for both roots.** Al-Muizz is the *safer* half of that forced pair — its ḥadīth (Muslim
2588) gives it an independent, positive, punishment-free story with no register risk. Al-Muzill's
independent story (7:152) is harder by the nature of the Name, and its verse beat has nowhere else in
scripture to stand. See `al-muzill@1`'s §7 for the reasoning in full; this deck does not repeat it,
only affirms it is drafted with that constraint already built in — beat 5 renders only "You honor
whom You will," never the twin's clause, and beat 7 does not lean on Al-Muzill's action to make its
own point.

---

## 8 · Claim | Source | Grading | Status

| # | claim | source | URL fetched | grading | status |
|---|---|---|---|---|---|
| 1 | *"Charity does not decrease wealth, no one forgives another except that Allah increases his honor, and no one humbles himself for the sake of Allah except that Allah raises his status."* (beats 2–4, split across three, verbatim) | Ṣaḥīḥ Muslim 2588, narrated Abū Hurayra | `web.archive.org/web/20260419211856id_/https://sunnah.com/muslim:2588` | **ṣaḥīḥ** (Ṣaḥīḥ Muslim; no separate grade line — Muslim's own collection). In-book reference: Book 45, Ḥadīth 90. | ✅ **verified (archive)** — Arabic and English both read off the capture. Arabic: `مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلاَّ عِزًّا وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ` |
| 2 | *"…You honor whom You will…"* (beat 5) | Qur'ān 3:26 | `api.quran.com/api/v4/verses/by_key/3:26?fields=text_uthmani,text_imlaei&translations=20` | — | ✅ **verified** — Saheeh International, quoted verbatim as a substring; both ellipses mark a mid-sentence excerpt on the beat |
| 3 | 3:26's n−1 (3:25), n+1 (3:27), n+2 (3:28) — independently re-fetched this session, not only inherited | Qur'ān 3:25, 3:27, 3:28 | `…/verses/by_key/{3:25,3:27,3:28}?…` | — | ✅ **fetched and read in this session**; readings in §4 |
| 4 | Muslim 2587 (n−1) and 2589 (n+1) are unrelated topics, no punishment bearing on this deck | Ṣaḥīḥ Muslim 2587, 2589 | `web.archive.org/web/20240716124858id_/…muslim:2587`, `web.archive.org/web/20230308000557id_/…muslim:2589` | ṣaḥīḥ (Muslim) | ✅ **verified (archive)** |
| 5 | The `ʿ-z-z` full-mushaf enumeration (3 finite verbs; 3:26 the only unspent) | inherited from `.context/claims/8.md`, **independently re-run** this session over `api.quran.com/api/v4/quran/verses/uthmani` | full-mushaf single-call fetch | — | ✅ **re-run and reproduces**; not trusted unverified |
| 6 | The `dh-l-l` full-mushaf enumeration (28 skeleton hits, 4 excluded as `r-dh-l`, exactly 1 Allah-subject "humiliate a person" finite verb) | run fresh this session, no prior claim covers this root | same full-mushaf fetch | — | ✅ **computed in this session**; script and table in §2 |
| 7 | Catalogue ids 43 and 44 share `dua_arabic`/`dua_transliteration`/`dua_translation` byte-for-byte | `assets/content/collectible_names.json` ids 43, 44 | local read | — | ✅ **verified programmatically**, exact string equality |
| 8 | The duʿā has no locatable primary narration | sunnah.com search index, general web search | web search, both Arabic and transliterated English phrasings | — | ⚠️ **searched, not found — see the limits section below.** One non-primary web result attributes a version to Aḥmad ibn Ḥanbal as an *athar*; **not independently verified, not acted on.** |
| 9 | The 6-word run *"honor me through obedience to You"* is byte-identical between ids 8 and 43/44 | `collectible_names.json` ids 8, 43 | local string comparison | — | ✅ **verified programmatically** |
| 10 | Zero ≥4-word rendered-English overlap with any of the 34 shipped decks, except the disclosed bridge-template class | `assets/content/name_stories.json` (34 decks) | local, n-gram diff 7→4 | — | ✅ **run in this session**; output in §5b |
| 11 | Twin diff against `al-muzill@1`: zero shared 4-grams outside the template class and the āyah's own repeated frame | both drafts | local n-gram diff | — | ✅ **run in this session**; table in §5d |
| 12 | 35:10 closes on `لَهُمْ عَذَابٌ شَدِيدٌ` in the same āyah | Qur'ān 35:10 | `…/verses/by_key/35:10?…` | — | ✅ **re-fetched and re-confirmed**, not only inherited from `.context/claims/8.md` |
| 13 | 63:8's successor sweep (63:5–11), sūrah-final at 63:11 | Qur'ān 63:5–63:11 | `…/verses/by_key/{63:5..63:11}?…`, `…/verses/by_key/63:12` → 404 | — | ✅ **fetched**; not used on any beat, reasons in §"Explicitly NOT claimed" of the claim file |
| — | isnād of Muslim 2588 | — | — | — | ❌ **NOT audited.** See §9. |

---

## 9 · Translation audit — the catalogue's English vs. the fetched Qur'ān English

Plan §6 rule 2: re-render contested passages from the Arabic; do not paste a published translation
unchecked.

| Arabic (3:26) | Saheeh International | catalogue id 43/44 `dua_translation` (different clause, same root) | note |
|---|---|---|---|
| `وَتُذِلُّ مَن تَشَآءُ` | *"You **humble** whom You will"* | *"do not **humiliate** me…"* | **Genuine divergence, disclosed, not fixed.** Both are defensible English for `dh-l-l`; the deck does not harmonise them because the verse beat quotes the fetched Qur'ān translation as-is and the duʿā beat is catalogue-locked. A user who reads both beats in one sitting will see two different English words for the same Arabic root. |

Ḥadīth English (Muslim 2588) is sunnah.com's own published translation, used as-is; audited
clause-by-clause against the fetched Arabic in §1 above and found faithful (no interpolation, no
adjudicated ambiguity).

---

## 10 · Limits of this verification — stated because the founder signs against it

1. **No corpus independent of sunnah.com.** Every ḥadīth here was read from a Wayback capture of a
   sunnah.com page. No printed edition, no Shamela, no Dorar. Same limit every prior deck in this
   project records.
2. **No isnād was audited.** Muslim's own placement of Ḥadīth 2588 is accepted as the grade.
3. **The Qur'ān side is single-source** — `api.quran.com`, Saheeh International only. Not
   cross-checked against a second muṣḥaf text or a second translation.
4. **The duʿā-provenance search was not exhaustive.** I searched sunnah.com's index and general web
   search with several phrasings and found no primary narration. That is evidence of absence, not
   proof of it — a systematic search of the duʿā-specific corpora (as opposed to ḥadīth collections)
   was not run.
5. **The root enumerations are a skeleton match over one Qur'ān text (`api.quran.com`'s Uthmānī),
   not a morphological parse**, and were not cross-checked against a second digitised muṣḥaf.
6. **I did not run `flutter test`.** Nothing was written to `assets/content/name_stories.json`,
   `collectible_names.json` or the ship-gate test — read-only, per the task's constraint.
