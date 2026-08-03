# Deck Draft — Al-Wahid (id 73), drafted as a deliberate pair with Al-Ahad (id 74)

**Status: DRAFT, awaiting review.** Drafted from fetched sources; not yet through an independent
adversarial pass. Author: Claude, 2026-08-03.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Governing plan: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Claim file: `.context/claims/73.md`.
Sibling deck, same agent, same wave: **Al-Ahad (74)** —
[`2026-08-03-al-ahad-DRAFT.md`](./2026-08-03-al-ahad-DRAFT.md). See the joint separation section
at the end of both drafts, and **"The shared duʿā screen"** below — this is not optional context,
both decks render the identical duʿā beat.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4`
(`fields=text_uthmani,text_imlaei&translations=20`, Saheeh International). Root enumerations
cross-checked against `corpus.quran.com`. **No ḥadīth is used in this deck** — the selection is
Qurʾān-only (see "why no ḥadīth" below).

**Implementation note (binding):** Arabic / transliteration / translation are separate fields.
Verse beat is English-only (`arabic: ""`), per plan §7's convention for new decks.

---

## Deck `al-wahid@1` — Al-Wahid — The One

**Why this deck exists, in one line:** *"He is one"* is a sentence. **This deck shows what a
second would have done, and it never happened** — the heavens and the earth did not come apart,
because there was never a rival hand on them.

**Selection ran duʿā-first.** The shared `dua_arabic` (`يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي
وَوَحِّدْ قَصْدِي لَكَ`) asks for one thing: a scattered self gathered and a divided purpose made
one, addressed to both Names at once. Neither half of that request is carried by a bare declaration
of tawḥīd — it is carried by the idea that undivided rule *produces* coherence and divided rule
*produces* ruin. That is exactly what 21:22 demonstrates, which is why the passage was chosen over
every "your God is one God" declarative in the Qurʾān (see the root sweep below — all six are
either paired with Al-Qahhar or `قُلْ`-governed, and the ones that are neither only *state* it).

**Proposed metadata**

```json
{
  "deck_id": "al-wahid@1",
  "name_id": 73,
  "transliteration": "Al-Wahid",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge** *(authored, no scripture)*:
> When too many hands are pulling your life in different directions — advice, expectations, your
> own competing fears — this is the Name for the one grip underneath all of it that was never
> divided.

**Beat 2 · name_intro** *(from `collectible_names.json` id 73, verbatim)*:
> الْوَاحِدُ — Al-Wahid — The One

**Beats 3–5 · story — "What a second would have done":**

> 3. Before the argument, the challenge: **"Or have they taken for themselves gods from the earth
>    who resurrect [the dead]?"** — rivals with no power to do the one thing that would matter.
>    *(`source`: Qur'an 21:21)*
>
> 4. Then the demonstration itself: **"Had there been within them [i.e., the heavens and earth]
>    gods besides Allah, they both would have been ruined."**
>    *(`source`: Qur'an 21:22)*
>
> 5. **"So exalted is Allah, Lord of the Throne, above what they describe."**
>    *(`source`: Qur'an 21:22)*

**Beat 6 · verse** *(the Name's own root, on a separate anchor — see bar 4 below)*:
> "…And Allah has said, 'Do not take for yourselves two deities. He [i.e., Allah] is but one God…'"
>
> `source`: Qur'an 16:51 (partial — ellipsis on the beat, see sources table)

**Beat 7 · duʿā** *(catalog id 73, verbatim in full — **`source` MUST be empty**, per the ship-gate
note on locked-duʿā decks):*
> يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ
> *Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak*
> "O One, O Uniquely One, gather my scattered self and unify my purpose for You."

**Beat 8 · takeaway** *(authored — Name₁ slot, pair-synergy line)*:
> If there had been a second, the world you're standing in would not have held together. It did.
> Whatever is holding your life together right now is not divided between rivals — it answers to
> One. **Al-Ahad — the second Name of your answer — is why that One has no equal to be compared
> against.**

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words** | **21:22 is Allah's own third-person narration** — no `قُلْ`, no reported human or angelic speech (checked: 21:20–21 and 21:23–25 carry no `قُلْ` until 21:24, well past the quotation). It states a counterfactual consequence (multiple gods → ruin) as a fact about how the cosmos works, not a report of what someone said about Allah. **Structurally distinct from the rejected class** (7:196, 12:101, 10:62, 10:82 — all reported first-person human speech, checked directly in the claim file). | **yes — beat 4** |
| 2 | **shown, not stated** | No beat says "Allah is one." Beat 4 shows a **consequence that did not happen**: a second god would have produced `فَسَدَتَا` — ruin, corruption — of the heavens and the earth. The reader is not told there is one God; the reader is shown what the alternative would have cost, and that cost was never paid. Beat 6's declarative (16:51) comes *after* the demonstration, same ordering precedent as `al-haqq@1` beat 7. | **yes — beat 4, reinforced by beat 5's "exalted…above what they describe"** |
| 3 | **no sibling collapse — incl. against Al-Ahad** | See the full three-surface pass below. | **yes** |
| 4 | **the Name's own root appears in the source text** | **Traded on the story (21:21–22 carry no `و-ح-د`), recovered on the verse beat.** Full corpus sweep (below) shows the compact epithet `الْوَاحِدُ` occurs exactly 6 times in the Qurʾān and all six are `الْوَاحِدُ الْقَهَّارُ` — reserved for Al-Qahhar (id 22, undrafted; plan explicitly protects the fixed pair). Beat 6 instead uses 16:51's `إِلَٰهٌ وَٰحِدٌ` — a different grammatical form of the same root, in Allah's own direct speech (`وَقَالَ اللَّهُ`, not `قُلْ`), unpaired with Al-Qahhar. | **yes — beat 6, traded on the story** |
| 5 | **no punishment just outside the excerpt** | Successor sweep below. Clean in both directions on 21:21–23; 16:51's own continuation (`فَإِيَّايَ فَارْهَبُونِ`, "so fear only Me") is cut with a visible ellipsis for register, not for a punishment reason — disclosed as a register choice, not a bar-5 rescue. | **yes** |

### Bar 4 — the root sweep that forces the trade (corpus.quran.com, exhaustive)

Root **و ح د** occurs **68** times in the Qurʾān. Corpus breakdown, summed against its own headline:
30 `wāḥid` + 31 `wāḥidat` + 6 `waḥd` + 1 `waḥīd` = **68.** ✅ matches.

Of the 30 `wāḥid` occurrences, the **compact definite epithet** `الْوَاحِدُ` (the grammatical form
that reads as the Name itself, with the article) appears **exactly 6 times**:

| # | āyah | full phrase |
|---|---|---|
| 1 | 12:39 | `أَمِ اللَّهُ الْوَاحِدُ الْقَهَّارُ` |
| 2 | 13:16 | `وَهُوَ الْوَاحِدُ الْقَهَّارُ` |
| 3 | 14:48 | `وَبَرَزُوا لِلَّهِ الْوَاحِدِ الْقَهَّارِ` |
| 4 | 38:65 | `إِلَّا اللَّهُ الْوَاحِدُ الْقَهَّارُ` |
| 5 | 39:4 | `هُوَ اللَّهُ الْوَاحِدُ الْقَهَّارُ` |
| 6 | 40:16 | `لِلَّهِ الْوَاحِدِ الْقَهَّارِ` |

**6 of 6 — 100% — pair with `الْقَهَّارُ`.** Zero unpaired occurrences of the compact epithet exist
anywhere in the Qurʾān. This is measured, not estimated: every one of the 30 `wāḥid` hits was read
in context from the corpus page fetched 2026-08-03. The plan flags exactly this pair as fixed
Qurʾānic ground reserved for Al-Qahhar (id 22) — none of the six is spent here.

The remaining 24 `wāḥid` occurrences are either indefinite/generic ("one gate," "one soul," "one
community") or the predicate form `إِلَٰهٌ وَاحِدٌ` ("a god, one" / "one God") at 2:163, 5:73, 6:19,
9:31, 14:52, 16:22, 16:51, 18:110, 21:108, 22:34, 29:46, 37:4, 41:6, 4:171. Of those fourteen,
**six are `قُلْ`-governed** (6:19, 18:110, 21:108, 41:6, plus 6:19's own repetition) and therefore
share the rejected-class problem; the rest are bare declaratives with no demonstrative continuation
in the immediately adjacent āyāt (checked: 2:164 is the nearest exception, a signs-of-creation list
that never repeats the root, so it does not rescue 2:163 as a root-bearing *and* demonstrative
choice). **16:51 is the one non-`قُلْ` declarative whose continuation (16:52–53, "whatever you have
of favor is from Allah…to Him you cry for help") is warm and uncontested** — it was chosen for the
verse beat on that basis, not because it demonstrates anything itself; its job is bar 4 only, after
bar 1/2 have already been carried by beat 4.

### What comes immediately before and after each excerpt

| excerpt | fetched | verdict |
|---|---|---|
| **21:22 (n−1) = 21:21** | *"Or have they taken for themselves gods from the earth who resurrect [the dead]?"* | **rendered as beat 3.** Sets up the challenge; no punishment, no contradiction. |
| **21:22 (n+1) = 21:23** | *"He is not questioned about what He does, but they will be questioned."* | **clean and confirming** — reinforces the same sovereignty point. Not rendered (beat 5 is already complete on its own), but nothing here contradicts or completes a thought the excerpt leaves misleadingly open. |
| **21:22, further out: 21:24–25** | 21:24: *"Or have they taken gods besides Him? Say, 'Produce your proof.'"* (this is where `قُلْ` first appears in the passage). 21:25: *"And We sent not before you any messenger except We revealed to him that, 'There is no deity except Me, so worship Me.'"* | **disclosed, not rendered.** 21:25 is Allah's own first-person speech reported through revelation to prior messengers — thematically confirming, not contradicting; not used because it is one step further from the argument this deck tells. |
| **16:51 (n−1) = 16:49–50** | Creatures and angels prostrating to Allah, fearing their Lord, doing as commanded. | clean, no contradiction. |
| **16:51 — the excerpt's own tail** | `فَإِيَّايَ فَارْهَبُونِ` — *"so fear only Me."* | **cut, with a visible ellipsis on the beat.** Not a bar-5 rescue (it is not a punishment clause) — a register choice: "fear" reads harshly against the app's comfort register when the demonstration itself (beat 4) has already done the persuasive work. Disclosed rather than silently dropped. |
| **16:51 (n+1) = 16:52–53** | *"And to Him belongs whatever is in the heavens and the earth, and to Him is [due] worship constantly… And whatever you have of favor - it is from Allah. Then when adversity touches you, to Him you cry for help."* | **clean and warm.** Not rendered (beat 6 is complete), but confirms the cut was for register, not to hide a problem — the continuation the deck avoided (16:51's own tail) is a single clause, and what follows it (16:52–53) is reassuring, not a trap. |
| **Sūrah-level, 21** | **Sūrat al-Anbiyāʾ now carries three decks**: shipped `ash-shafi@1` (21:83–84), drafted `al-mujeeb@1` (21:87–88), and this deck (21:21–23). Gaps: 21:22→21:83 is **61 āyāt**; 21:22→21:87 is **65 āyāt**. | **disclosed.** Three decks in one sūrah is the precedent already accepted for Āl ʿImrān (`al-wakeel@1`, `al-malik@1`, `al-aleem@1`) — treated there as the acceptable ceiling, with a fourth flagged as "the ash-Shūrā shape." This deck is Anbiyāʾ's third, at a wider separation than either existing pair in that sūrah. |
| **Sūrah-level, 16** | **Sūrat an-Naḥl is touched by no other deck in the ledger.** Fresh ground, single citation, no crowding. | clean |

### Bar 3 — the three surfaces, run against all 34 shipped decks AND against Al-Ahad

**1. Arabic roots.** Quoted text carries: `ʾ-l-h` (god/deity — 21:21, 21:22, 16:51, ubiquitous),
`f-s-d` (ruin/corruption — 21:22, **appears in NO other deck's quoted text**), `s-b-ḥ` (exalted —
21:22, shared only with `al-jabbar@1`'s duʿā and a handful of other decks' generic "Glory be to
Allah" register, not a Name-specific collision), `w-ḥ-d` (16:51 only — the Name's own root, traded
off the story). No `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `w-k-l`, `b-ṣ-r`, `q-d-r`, `h-d-y`,
`j-w-b`, `ṣ-m-d`, `ʾ-ḥ-d` appears anywhere in this deck's quoted text. **`f-s-d` is spent by no
other deck in the 34-deck corpus** (checked programmatically against `name_stories.json`).

**2. Token frequency across every rendered `primary`/`label`/`translation`/`source` string, all 34
decks, checked 2026-08-03.** "ruined," "corruption," "rival(s)," "held together" → **zero** hits
outside this deck. "one" appears constantly across the corpus as ordinary generic address for
Allah (dozens of hits — `al-wakeel@1`, `al-lateef@1`, `al-baseer@1`, `al-kareem@1`, `al-mumin@1`,
and more) but **"The One" as a `name_intro` primary/gloss appears in no other deck** (§4a of the
ledger lists all 24 pre-existing `name_intro` primaries; none is "The One"; checked the 10 wave-1
additions the same way). So the common word is not a false alarm and the exact gloss is clean.

**3. The move.** This deck's engine is **undivided governance**: a counterfactual about what
*would* have happened if there had been a rival, answered by the fact that it didn't. That is
different from `al-wakeel@1`'s move (personal reliance after a real crisis, Uḥud, "ḥasbunallāh")
and different from `al-mumin@1`'s move (safety granted, not earned). No shipped or drafted deck
argues from "a second cause would have broken the system, and it never did." **Against Al-Ahad
specifically** (this is the bar the brief calls the hardest in the project): Al-Wahid's move is
about a **rival ruler** — a second *actor* competing for control of the same domain. Al-Ahad's move
(see its own draft) is about a **rival in kind** — something sharing Allah's own nature closely
enough to be called equal or comparable. Beat-by-beat diff:

| beat | Al-Wahid | Al-Ahad | shared words? |
|---|---|---|---|
| bridge | "too many hands…pulling in different directions" | (see Al-Ahad draft — comparison/ranking, not competing control) | none |
| story engine | rival **gods** governing the same cosmos | a **son/consort** — a being that would share Allah's own nature | "Allah," "He/His" only (unavoidable) |
| verse beat | 16:51, `إِلَٰهٌ وَٰحِدٌ` ("one God") | 6:102 cut, `لَا إِلَٰهَ إِلَّا هُوَ` ("no deity except Him") — different āyah, different sūrah | `إِلَٰه` (deity) common noun, unavoidable in any tawḥīd text; no shared clause |
| takeaway | "not divided between rivals — answers to One" | "nothing shares what He is — no second version" | none verbatim; both name the sibling deck once, per the pair-synergy convention |

No rendered string longer than the unavoidable `Allah`/`إِلَٰه` is shared. The two decks fail
differently if either one is removed, which is the test the ledger's §9an/§9aq entries use for "the
move," not just the words.

### Why no ḥadīth

Catalogue id 73's own `hadith` field ("When Bilāl (RA) was tortured, he kept saying 'Aḥad, Aḥad'…
(Seerah)") was considered and **not used**. It cites "(Seerah)," not a graded collection, and the
plan's sourcing rule is Ṣaḥīḥ/ḥasan-only for anything presented as prophetic or companion
narration. No independent Ṣaḥīḥ/ḥasan hadith carrying `الْوَاحِدُ` as a demonstrated act was found;
the Qurʾān carried both bar 1 and bar 2 cleanly, so none was needed.

### Sources

| # | Claim | Translation used | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | Beat 1 bridge | — | authored | n/a | ✅ honest label — authored copy, no scripture claim |
| 2.1 | Beat 2 `name_intro` | catalog id 73 | catalog only | n/a | ✅ verified byte-identical to catalog: `arabic`=`الْوَاحِدُ`, `transliteration`=`Al-Wahid`, `english`=`The One`, checked via direct Python equality against `collectible_names.json` 2026-08-03 |
| 3.1 | Beat 3, verbatim: *"Or have they taken for themselves gods from the earth who resurrect [the dead]?"* | Saheeh International | [Qur'an 21:21](https://quran.com/21/21) | Qurʾān | ✅ verified — live fetch `api.quran.com/api/v4/verses/by_key/21:21`, 2026-08-03. `text_uthmani`: `أَمِ ٱتَّخَذُوٓا۟ ءَالِهَةً مِّنَ ٱلْأَرْضِ هُمْ يُنشِرُونَ`. Quoted in full, no ellipsis needed. |
| 4.1 | Beat 4, verbatim: *"Had there been within them [i.e., the heavens and earth] gods besides Allah, they both would have been ruined."* | Saheeh International | [Qur'an 21:22](https://quran.com/21/22) | Qurʾān | ✅ verified — live fetch 2026-08-03. `text_uthmani`: `لَوْ كَانَ فِيهِمَآ ءَالِهَةٌ إِلَّا ٱللَّهُ لَفَسَدَتَا`. This is the āyah's first clause only; the second clause is beat 5. **Translator's bracket `[i.e., the heavens and earth]` retained.** No word inside either quoted clause is changed, added, dropped or reordered. |
| 5.1 | Beat 5, verbatim: *"So exalted is Allah, Lord of the Throne, above what they describe."* | Saheeh International | [Qur'an 21:22](https://quran.com/21/22) | Qurʾān | ✅ verified — same fetch as 4.1. `text_uthmani`: `فَسُبْحَـٰنَ ٱللَّهِ رَبِّ ٱلْعَرْشِ عَمَّا يَصِفُونَ`. Second clause of the same āyah; both clauses together are the whole āyah, split across two beats for the format's one-breath rule. |
| 6.1 | Beat 6, partial, ellipsis on the beat: *"…And Allah has said, 'Do not take for yourselves two deities. He [i.e., Allah] is but one God…'"* | Saheeh International, with the closing clause cut | [Qur'an 16:51](https://quran.com/16/51) | Qurʾān | ✅ verified — live fetch 2026-08-03. `text_uthmani`: `وَقَالَ ٱللَّهُ لَا تَتَّخِذُوٓا۟ إِلَـٰهَيْنِ ٱثْنَيْنِ ۖ إِنَّمَا هُوَ إِلَـٰهٌ وَٰحِدٌ ۖ فَإِيَّـٰىَ فَٱرْهَبُونِ`. **Quoted region ends at `وَٰحِدٌ`; `فَإِيَّـٰىَ فَٱرْهَبُونِ` ("so fear only Me") is cut, register reason recorded above, and the beat's own leading "…" plus trailing "…" mark both the mid-passage entry and the cut. Translator's brackets (footnote marker after "two"; `[i.e., Allah]` before "is but one God") — footnote marker stripped, `[i.e., Allah]` retained.** |
| 7.1 | Beat 7 duʿā | catalog id 73 — no scripture citation claimed | catalog only | n/a | ✅ verified byte-identical to catalog across `dua_arabic`/`dua_transliteration`/`dua_translation` — Python string equality against id 73's fields, 2026-08-03. **UNPINNED, `source` empty.** |
| 8.1 | Beat 8 takeaway | — | authored | n/a | ✅ honest label — authored copy. Traces: "world…held together" → beat 4 (21:22); "not divided between rivals" → the counterfactual's own logic; "answers to One" → beat 6 (16:51). |

### Disclosed adjacencies (recorded, not blocking)

- **Al-Qahhar (id 22) is undrafted but its entire likely ground (the six `الْوَاحِدُ الْقَهَّارُ`
  āyāt) is now explicitly reserved, not merely avoided.** A future Al-Qahhar drafter inherits a
  clean field.
- **Sūrat al-Anbiyāʾ now carries three decks** (see the sūrah-level row above) — disclosed at the
  density already accepted for Āl ʿImrān.
- **`al-wakeel@1`** (shipped) — different move (personal trust after real harm vs. a cosmological
  argument about rival governance); zero shared rendered strings beyond "Allah."
- **`al-mumin@1`** (drafted this project) renders "The Guardian of Faith — the One who grants
  safety" — uses "the One" as a generic gloss extension, not a Name-defining claim; not a collision
  under the §9as vocative test (different Name being described).

### Method limits

1. Qurʾān text rests on `api.quran.com` as the sole live source for the quotations themselves; no
   second digitisation was cross-read for the *text*, only for the *root count* (`corpus.quran.com`,
   which is independent tooling over the same Uthmani text).
2. No ḥadīth is used, so the sunnah.com/Wayback exposure that applies to most other decks does not
   apply here.
3. This has not been through the adversarial blind-review step. The bar-3 "move" comparison against
   Al-Ahad is my own read; an independent verifier reading both drafts blind is the check this
   project's own process (§7 of the deck-format spec, §6/§9 of the ledger) requires before a
   founder signs.
4. I did not exhaustively re-derive the 24 non-`الْوَاحِدُ` `wāḥid` occurrences' full grammatical
   context one by one beyond confirming which are `قُلْ`-governed and which have a demonstrative
   neighbour; the claim that 16:51 is *the* best non-`قُلْ` declarative rests on reading all
   fourteen `إِلَٰهٌ وَاحِدٌ`-type hits, not on an external ranking.

---

## The shared duʿā screen

**Al-Wahid and Al-Ahad render the identical duʿā beat, byte-for-byte** (`dua_arabic`,
`dua_transliteration`, `dua_translation` all verified equal via direct string comparison against
`collectible_names.json`, 2026-08-03). This is catalogue structure, not a drafting choice, and it
cannot be fixed inside a deck — see plan §7's ledger, §6a group 11, and §6e, which already lists
both Names as blocked on the duʿā axis before this draft existed.

**What the shared duʿā actually says and does:** `يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ
قَصْدِي لَكَ` — "O One, O Uniquely One, gather my scattered self and unify my purpose for You." It
addresses **both** Names in one vocative and asks for **one** thing: an inward gathering
(`اجْمَعْ شَمْلِي`, "gather my scattered self") and a unified aim (`وَحِّدْ قَصْدِي`, "unify my
purpose" — note this is a Form II verb of the Name's own root, `و-ح-د`, the only verb form of that
root anywhere in this deck pair; the Qurʾān itself carries no verb form of `و-ح-د` at all, per the
corpus sweep above — **this authored duʿā is the one place in either deck a verb form of the root
appears**, and it is catalogue-locked, not something either deck introduces).

**Why one duʿā for two Names is not itself a bar-3 failure.** The duʿā does not choose between the
two meanings — it uses both vocatives because the *request* sits at the seam between them: a
person who feels scattered is asking simultaneously for **no rival pull on their attention**
(Al-Wahid's sense: undivided governance, applied inward — nothing else has a rightful claim on
where this goes) and **no fragmentation of the self into competing versions** (Al-Ahad's sense:
indivisible unity, applied inward — one coherent "I," not several). Read this way the shared screen
is not a collapse of the two Names into each other; it is the one place in the pair where a user is
invited to feel *why* both matter to the same problem. That reading is offered as this drafter's
own gloss, not as scripture — it is authored interpretation of a catalogue string, disclosed as
such, and the founder may prefer to treat the shared screen as simply a known limitation to be
fixed in the duʿā de-duplication pass §6e calls for.

**What this section does NOT do:** it does not recommend a catalogue change. Per instruction, and
per the ledger's standing rule that a drafter's confident recommendation to change catalogue data
has been wrong in both prior batches, this is a description of what renders, not a proposal.

---

## Joint separation note (read together with Al-Ahad's draft)

**These two Names are near-synonyms in ordinary English — "The One" and "The Unique" — and this is
recorded as the hardest bar-3 pair drafted in this project so far.** The separation achieved:

1. **Different demonstration mechanism.** Al-Wahid: a counterfactual about **rival rulers**
   (21:22 — if there were two gods, the cosmos would break). Al-Ahad: a counterfactual about a
   **rival in kind** (6:101 — He has no consort, so no being shares His nature the way a child
   shares a parent's). Both are "shown, not stated" arguments, and neither could stand in for the
   other's passage without changing what is being proven.
2. **Different sūrahs for both story and verse beats**, with disclosed but non-blocking co-tenancy
   in each (Anbiyāʾ at three decks, matching the accepted Āl ʿImrān density; An-Naḥl fresh; Al-Anʿām
   fresh for this pair, shared only with two other decks' single verse-beat citations, see Al-Ahad's
   draft).
3. **Zero shared rendered vocabulary beyond `Allah`/`إِلَٰه`**, diffed both directions (table above).
4. **The one place they are NOT separated is the duʿā screen**, which is catalogue-locked and
   disclosed in both drafts rather than concealed.

**This is not a refusal.** Both Names clear bars 1, 2, 3 (against the whole corpus and against each
other), 4 (traded, with the sweep proving the trade was necessary and total for the paired epithet
form), and 5, on independently sourced, independently verified passages. **The recommendation is to
ship both — but to treat them as a linked pair in the founder's review, the way Al-Khāfiḍ/Ar-Rāfiʿ
and Al-Qābiḍ/Al-Bāsiṭ already are (ledger §9az)**, because the shared duʿā and the mutual beat-8
reference make them read best back to back, and because a future duʿā de-duplication pass will
touch both at once.
