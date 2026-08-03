# Deck Draft — Al-Mateen (catalogue id 63) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-qawiyy-DRAFT.md`](./2026-08-03-al-qawiyy-DRAFT.md).** Ids 62 and 63 share
catalogue `dua_arabic` byte-identically (ledger §6a group 10) and were drafted together, duʿā-first.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7,
especially §7a.3: *"Bar 4 is the shock absorber… expect it to be the normal shape of a hard deck —
Ash-Shakūr (28), Al-Mateen (63) and probably Al-Qawiyy (62) cannot be built any other way."* **This
deck confirms the first half of that prediction and, together with its twin, overturns the second —
Al-Qawiyy was built without a bar-4 trade at all; Al-Mateen's trade below is total.**
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9be.
Claim filed at `.context/claims/63.md`; re-read immediately before the tables below.

**Every citation fetched live 2026-08-03.** Qur'an: `api.quran.com/api/v4/verses/by_key/{s}:{a}`,
over the **full 6,236-āyah Uthmānī text** for the root sweep. Ḥadīth: Wayback CDX captures of the
exact bare `sunnah.com` number. **Nothing here was composed, reconstructed or recalled.**

---

## ⚠️ Why this Name was rejected/blocked before, read first

Two separate failures on record. **(1) Bar 3.** Al-Mateen's *only* in-text Qur'anic occurrence, 51:58
(`إِنَّ ٱللَّهَ هُوَ ٱلرَّزَّاقُ ذُو ٱلْقُوَّةِ ٱلْمَتِينُ`), prints *"the Provider"* — Ar-Razzāq, a
**shipped** Name — in the same clause. **(2) A silent-doubt failure.** An earlier attempt on this
Name used Bukhārī 6384 for the shared duʿā's clause and rendered it as flat direct speech, when the
matn actually carries it under the narrator's *shakk* (`أَوْ قَالَ`) — the undoubted routes are
Bukhārī 4205/6610. **This draft does not use 51:58 at all, and does not use 6384 at all.**

---

## Deck `al-mateen@1` — Al-Mateen

**Why this deck exists, in one line:** the user for whom everything feels like it is being held up by
their own effort, and who is running out of it. **There is a ṣaḥīḥ narration in which the Prophet ﷺ
told an over-exerting worshipper to do less — not because she was weak, but because what she was
leaning on does not tire.**

**Selection ran duʿā-first, jointly with `al-qawiyy@1`.** See that draft's "Why this story" section
for the full reasoning; the conclusion for this Name is that the duʿā's content (a negation of
self-generated power) forced the search onto ḥadīth for the story, and the root enumeration below
forces it onto a **traded** root for the verse.

**Proposed metadata**

```json
{
  "deck_id": "al-mateen@1",
  "name_id": 63,
  "transliteration": "Al-Mateen",
  "chip_keys": [],
  "position_in_pair": 2,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

> ⚠️ Same open engineering gap as `al-qawiyy@1`: `chip_keys: []` means the ship gate's pair-synergy
> assertion never evaluates either deck. `position_in_pair: 2` is a recommendation, not enforced.

**Beat 1 · bridge:**
> Everything you're holding up tonight, you're holding up alone — and that is the part that's shaking. There is a Name for what never has to strain.

**Beat 2 · name_intro** *(catalogue id 63 `english` verbatim)*:
> الْمَتِينُ — Al-Mateen — The Firm

**Beats 3–5 · story — "Take on what you can sustain":**
> 3. A woman was sitting with 'A'isha, and the Prophet ﷺ asked who she was. 'A'isha told him — and mentioned how much she prayed, barely stopping to rest.
> 4. He did not praise it. He said: "Take on only what you are able to sustain — for Allah does not grow weary until you do."
> 5. The religion most beloved to him was never the largest effort. It was whatever a person could keep doing.

**Beat 6 · verse:**
> "And We created the heavens and the earth and everything between them in six days, and no weariness touched Us." — Qur'an 50:38

**Beat 7 · duʿā** *(catalog id 63, verbatim in full)*:
> لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ
> *La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem*
> "There is no power and no strength except through Allah, the Most High, the Most Magnificent."
> **NO source. UNPINNED** — see "The shared duʿā screen."

**Beat 8 · takeaway (pair-synergy):**
> He told her to do less — not because she was weak, but because He does not tire and she would. Al-Qawiyy, the second Name of your answer, is the one that is never depleted by being leaned on.

---

## The `m-t-n` enumeration — the bar-4 trade, proven forced

Full 6,236-āyah Uthmānī sweep, independently run and cross-checked against corpus.quran.com's root
م-ت-ن page. **Exactly 3 occurrences. Zero verb forms of this root exist anywhere in the Qur'an.**

| citation | text | verdict |
|---|---|---|
| 7:183 | `وَأُمْلِى لَهُمْ ۚ إِنَّ كَيْدِى مَتِينٌ` | **REJECTED — bar 5.** n−1 (7:182): `سَنَسْتَدْرِجُهُم مِّنْ حَيْثُ لَا يَعْلَمُونَ` — Allah's own entrapment of deniers, leading directly into this clause. Not adjacent to punishment; the clause *is* the mechanism of punishment |
| 68:45 | `وَأُمْلِى لَهُمْ ۚ إِنَّ كَيْدِى مَتِينٌ` | **REJECTED — bar 5.** Identical clause, identical setup at 68:44 (`سَنَسْتَدْرِجُهُم مِّنْ حَيْثُ لَا يَعْلَمُونَ`, re-fetched and confirmed word-for-word identical to 7:182). Same failure |
| 51:58 | `إِنَّ ٱللَّهَ هُوَ ٱلرَّزَّاقُ ذُو ٱلْقُوَّةِ ٱلْمَتِينُ` | **REJECTED — bar 3.** `ٱلرَّزَّاقُ` (shipped `ar-razzaq@1`) sits in the identical clause. This is the citation the earlier rejection is named for; reconfirmed live, not re-derived from memory |

**3 of 3 — every occurrence of this Name's own root in the entire Qur'an fails a bar. This is what
"prove it forced" means measured, not asserted.** Bar 4 does not partially recover on this deck:
**the traded root (`m-t-n`) reaches no beat at all, including the duʿā** — the shared duʿā's content
is `q-w-y` (`قُوَّةَ`), not `m-t-n`. **Stated at its true, narrower size, per §9ak: this is not "bar 4
is traded," it is "bar 4 scores zero on every beat of this deck."** `al-khafid@1` recovered a partial
bar-4 hit on its own duʿā beat (`يَا خَافِضُ`); this Name's duʿā carries its twin's root, not its own,
so even that partial recovery is unavailable here.

---

## The five bars

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words** | **Traded onto two different roots, neither `m-t-n`.** Story (Bukhārī 43): `فَوَاللَّهِ لاَ يَمَلُّ اللَّهُ حَتَّى تَمَلُّوا` — a finite negative verb, Allah the explicit subject, inside the Prophet's ﷺ own direct speech responding to a concrete situation. Verse (50:38): `وَمَا مَسَّنَا مِن لُّغُوبٍ` — first-person plural, Allah's own voice, negating fatigue from a named act (creation). Neither is a trailing epithet; both are finite, negative, Allah-subject constructions | yes — beats 4, 6 |
| 2 | **shown, not stated** | The story shows a correction of a specific woman's specific over-exertion, with the negation of divine weariness offered as the *reason*, not floated alone. The verse shows the negation attached to a named, immense act (six days, heavens and earth), not asserted about Allah in the abstract | yes |
| 3 | **no sibling collapse** | Three surfaces run below, twin-diff against `al-qawiyy@1`, and a disclosed live adjacency to shipped `ar-rauf@1`'s engine | see below |
| 4 | **the Name's own root in the source text** | **TRADED COMPLETELY — the enumeration above is the proof.** `m-t-n` renders on zero beats of this deck | **no, and stated as such** |
| 5 | **register — no punishment, no arc terminating in punishment just outside the excerpt** | Neither citation renders fighting, killing, punishment or threat. 46:33's identical theme (rejected elsewhere for bar 5) is disclosed as the reason 50:38 was sought out specifically | see sweep below |

---

## Register — how this clears the earlier rejection, stated explicitly

**The 6384-shakk failure does not recur because 6384 is not used anywhere in this deck.** The story
is drawn from an entirely different collection and companion (Bukhārī 43, ʿĀʾisha) — the shared duʿā's
own provenance is handled once, jointly, in "The shared duʿā screen" below, and that section states
plainly that none of the fetched routes (including 6384) is used to justify the duʿā's wording; it is
UNPINNED. **The 51:58/Razzāq failure does not recur because 51:58 is not used anywhere in this deck**
— the enumeration above shows it was fetched, read, and rejected on the same ground the earlier
attempt was rejected on, not silently avoided.

**Register beyond the two named failures:** no beat says *"He is strong so don't worry."* The comfort
is structural — a specific act (creating the heavens and earth) paired with an explicit negation of
fatigue, and a specific correction (do less) paired with an explicit reason that is about Allah, not
about the reader's deficiency. The reader is never told they are weak.

---

## Successor sweep — every neighbour fetched

| excerpt | direction | neighbour | reading |
|---|---|---|---|
| 50:38 | n−1 | **50:37** — "Indeed in that is a reminder for whoever has a heart or who listens while he is present" | clean pivot away from the refrain below |
| 50:38 | n−2 | **50:36** — "how many a generation before them did We destroy who were greater than them in power…" | **disclosed at full strength.** Not adjacent (50:37 intervenes), not quoted, not alluded to |
| 50:38 | n+1 | **50:39** — "So be patient… and exalt with praise of your Lord before the rising of the sun and before its setting" | clean — a devotional instruction |
| 50:38 | n+2 | **50:40** — "And [in part] of the night exalt Him and after prostration" | clean |
| 50:38 | opens mid-sentence? | No — `وَلَقَدْ خَلَقْنَا` is a fresh independent clause (the emphatic `la-qad` opener), confirmed by reading 50:37's full stop | clean |
| — | same-theme comparison | **46:33** — `أَوَلَمْ يَرَوْا۟ أَنَّ ٱللَّهَ ٱلَّذِى خَلَقَ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ وَلَمْ يَعْىَ بِخَلْقِهِنَّ` (did We fail in creating the heavens and earth?) | **already on the ledger's bar-5 rejection list** (46:33/34) — 46:34 ends `فَذُوقُوا۟ ٱلْعَذَابَ`. **Not re-derived: cited as the reason 50:38 was sought as the register-clean carrier of the identical idea** |
| — | same-sūrah alternative, rejected | **50:15** — `أَفَعَيِينَا بِٱلْخَلْقِ ٱلْأَوَّلِ` (did We fail in the first creation?) | **REJECTED — bar 5.** Immediately preceded (50:12–14) by the same destroyed-nations refrain, ending `فَحَقَّ وَعِيدِ` ("so My threat was justly fulfilled") — n−1, not n−2. Worse than 50:38 on the exact axis that matters |

**No 404/sūrah-final result** — Sūrat Qāf is 45 āyāt; 50:38 sits mid-sūrah.

---

## Bar 3, all three surfaces (§9an) — plus the twin-diff

### Surface 1 — Arabic roots

| root | where | renders in Arabic? | collision check |
|---|---|---|---|
| `m-t-n` (this Name) | nowhere | **no, on any beat, including the duʿā** | the deck's central, disclosed limit |
| `l-gh-b` | 50:38 `لُّغُوبٍ` (verse beat, English-only per convention) | no | spent by no other deck |
| `m-l-l` | Bukhārī 43 `يَمَلُّ` (story, English-only) | no | spent by no other deck |
| `q-w-y` | duʿā `قُوَّةَ` (shared with id 62) | **yes, beat 7** | catalogue-locked; carries the twin's root, not this Name's — see the bar-4 disclosure |
| `ʿ-l-w`/`ʿ-ẓ-m` | duʿā `الْعَلِيِّ الْعَظِيمِ` | **yes, beat 7** | same as `al-qawiyy@1`'s disclosure — both Al-Ali (52) and Al-Azeem (50) BLOCKED, undecked |

### Surface 2 — token frequency, current 45-deck asset

**Checked against 45 decks.**

| token | n before this deck | where | ruling |
|---|---|---|---|
| `weary`/`weariness`/`tire`/`tires`/`fatigue` | 0 each | — | clean; the corpus's only `tired` hit (`al-qadir@1` bridge, *"that gap is its own kind of tired"*) is a metaphorical, unrelated sense — zero shared 2-gram |
| `firm` | 2 | `al-mumin@1` duʿā (*"make us firm upon faith"* — human firmness, petitionary); `al-khaliq@1` story (*"a firm lodging"* — the womb, a physical descriptor) | different senses; **this deck's `name_intro` adds a third, and it is this Name's own gloss** — not a collision, the catalogue `english` itself |
| `sustain`/`capacity` | 0 / 2 | `ar-rahman@1` (`comfort_verse`, "capacity" = 2:286's own word), `ar-rauf@1` bridge (*"short on capacity"*) | ⚠️ **see the dedicated disclosure below** |
| `created`/`creation`/`create` | 3 / 4 / 1 | `al-khaliq@1` (shipped, multiple), `ar-rauf@1` (4:28), `al-haleem@1`, `al-muid@1` | **this deck's verse beat adds `created` (50:38).** Same root as `al-khaliq@1`'s whole engine — see the move-diff below |
| `six`, `days` | 1 each | `al-basit@1` (*"they did not see the sun again for six days"*, unrelated — a drought/rain narrative) | zero shared 2-gram, unrelated sense |

**`sustain`/`capacity` — full disclosure, matching the class already flagged on the twin.** Shipped
`ar-rauf@1`'s bridge opens *"You are not short on effort. You are short on capacity…"* and its whole
engine is a demand being *reduced* (fifty prayers to five) so a finite capacity is not exceeded.
**This deck's beat 4 — "take on only what you can sustain" — sits on the same axis: don't overdo it.**
Genuinely different mechanism: **Ar-Rauf's mercy is Allah lowering the requirement; this deck's is
Allah explaining why pacing is wise, because His own reserve, unlike the reader's, is not finite.**
No shared citation (Bukhārī 3207 vs. Bukhārī 43), no shared rendered clause beyond ordinary English.
**Offered for the verifier to test, not ruled clean by the drafter — per §9ab/§9bd, a drafter may not
adjudicate its own move-adjacency.**

**`created` against `al-khaliq@1` — the move differs, and the difference is load-bearing.**
`al-khaliq@1`'s engine is the **sequence** of creation (embryology, "count them: seven verbs, and the
same One is behind every one" — process, craftsmanship). This deck's engine is **the absence of a
cost** to a single named act (six days, then nothing touched Him). Different question entirely — *how
He makes* vs. *what it cost Him to have made it.* Zero shared rendered clause.

### Surface 3 — the move

| shipped/drafted deck | its move | this deck's move | separated? |
|---|---|---|---|
| `ar-rauf@1` | the demand was lowered, not the capacity raised | the reserve was never finite to begin with | **flagged above, offered not ruled** |
| `al-khaliq@1` | the sequence of making | the cost of having made | yes |
| `al-qayyum@1` | vigilance never pauses (sleep/wakefulness register) | exertion never depletes (labour/fatigue register) | yes — different axis |
| `al-azeez@1` | reinforcement answers rejection | non-fatigue answers a finite reserve | yes |

**Engine, three words:** *never depleted by you.* Checked against §3a's spent list — no match.

### The twin-diff — against `al-qawiyy@1`, beat by beat

See `al-qawiyy@1`'s own twin-diff table (identical content, present in both drafts per the brief).
**Summary for this file:** genre parallel by construction (ḥadīth story + Qur'an verse), root
demonstrated diverges completely (`q-w-y` present on 3 beats of the twin vs. `m-t-n` present on
**zero** beats of this deck), story citations from different collections and companions, verses from
different subjects (a human life-cycle vs. Allah's own act), moves distinguished (*quiet, not
louder* vs. *never depleted by you*). **Programmatic n-gram diff, both directions: n ≥ 4, zero hits.**

---

## The shared duʿā screen

*(Present verbatim in both drafts, per the brief — identical to `al-qawiyy@1`'s copy.)*

**Catalogue ids 62 and 63 carry byte-identical `dua_arabic`, `dua_transliteration` AND
`dua_translation`.** Verified programmatically, exact string equality:

```
arabic:          لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ
transliteration: La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem
translation:     There is no power and no strength except through Allah, the Most High, the Most Magnificent.
```

Both rows are the same string; the ship gate asserts each deck's `dua` beat byte-identical to its own
catalogue row by `name_id`. **Both decks render a pixel-identical duʿā screen.** Forced by the gate,
not a drafting choice.

**Four further facts, measured rather than asserted:**

1. **The phrase is a splice, not a single narration.** The core is attested in multiple ṣaḥīḥ routes
   — Bukhārī 6610, 4205, 6384 and Ṣaḥīḥ Muslim 385 — **fetched directly, and none of the four carries
   `ٱلْعَلِيِّ ٱلْعَظِيمِ`.** That pair matches Qur'an 2:255's own closing words, confirmed live.
   **UNPINNED remains correct; this is a report, not a catalogue recommendation.**
2. **For THIS Name specifically, the duʿā is the only beat carrying `q-w-y`, and it carries none of
   `m-t-n`.** Stated so a reader does not mistake the shared screen for a bar-4 recovery — it is not.
3. **The vocative pair `ٱلْعَلِيِّ ٱلْعَظِيمِ` renders no sibling-Name gloss** — Al-Ali (52) and
   Al-Azeem (50) are both BLOCKED, undecked.
4. **A user meeting both decks in one session sees the same screen twice**, with nothing marking
   which deck they are in — the ids-24/25 shape.

**No catalogue change recommended.**

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | what it is | why refused |
|---|---|---|
| 51:58 | `ذُو ٱلْقُوَّةِ ٱلْمَتِينُ` | **bar 3 — `ٱلرَّزَّاقُ`, shipped, same clause.** The earlier rejection's own citation, reconfirmed |
| 7:183, 68:45 | `إِنَّ كَيْدِى مَتِينٌ` | **bar 5 — entrapment/punishment passage, both instances**, `سَنَسْتَدْرِجُهُم` immediately prior |
| Bukhārī 6384 | the treasure-hadith, doubted route | **carries the shared duʿā's clause under `أَوْ قَالَ`** — the exact failure named in the brief |
| 46:33 | `أَوَلَمْ يَرَوْا۟ أَنَّ ٱللَّهَ … وَلَمْ يَعْىَ بِخَلْقِهِنَّ` | **already rejected on the ledger for bar 5** (46:34, `فَذُوقُوا۟ ٱلْعَذَابَ`). Not re-derived; cited as the reason 50:38 was sought |
| 50:15 | `أَفَعَيِينَا بِٱلْخَلْقِ ٱلْأَوَّلِ` | **bar 5** — immediately preceded (50:12–14) by the destroyed-nations refrain, `فَحَقَّ وَعِيدِ` |
| Muslim 385 | the adhān-response ḥadīth | authentic, on-theme, adds nothing bar 1 does not already have; would make the deck a two-collection splice. Cited only in the duʿā-provenance report |

---

## Claim | Source | Grading | Status

| # | claim | source | grading | status |
|---|---|---|---|---|
| 1 | Story beats 3–5: a woman's excessive prayer; "take on only what you can sustain…"; the closing note on consistency | Wayback capture of `sunnah.com/bukhari:43`, ts `20251216144437` | **Ṣaḥīḥ al-Bukhārī** — no printed grade line (collection-level inference) | ✅ Arabic verified: `تَذْكُرُ مِنْ صَلاَتِهَا` (mentioning her prayer); `مَهْ، عَلَيْكُمْ بِمَا تُطِيقُونَ، فَوَاللَّهِ لاَ يَمَلُّ اللَّهُ حَتَّى تَمَلُّوا` (**quoted in full, no elision**); `وَكَانَ أَحَبَّ الدِّينِ إِلَيْهِ مَا دَامَ عَلَيْهِ صَاحِبُهُ` — closing note, re-rendered from the Arabic (see translation table) |
| 2 | Parallel corroboration, quoted on no beat | Wayback captures of `sunnah.com/muslim:782a` (ts `20260208053507`) and `muslim:782b` (ts `20260302163843`) | Ṣaḥīḥ Muslim | ✅ same clause (`فَإِنَّ ٱللَّهَ لاَ يَمَلُّ حَتَّى تَمَلُّوا`) confirmed in a second collection; not needed for bar 1, recorded for completeness |
| 3 | Beat 6, quoted in full: "And We created the heavens and the earth and everything between them in six days, and no weariness touched Us." | `api.quran.com/api/v4/verses/by_key/50:38?translations=20` | Qur'an | ✅ `وَلَقَدْ خَلَقْنَا ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضَ وَمَا بَيْنَهُمَا فِى سِتَّةِ أَيَّامٍ وَمَا مَسَّنَا مِن لُّغُوبٍ` — quoted whole, no ellipsis |
| 4 | Successor sweep: 50:36, 50:37, 50:39, 50:40 fetched and read; 46:33/34 and 50:12–15 fetched for the same-theme comparison | `api.quran.com/api/v4/verses/by_key/{k}` | Qur'an | ✅ all live 2026-08-03; findings in the sweep tables above |
| 5 | The `m-t-n` enumeration: exactly 3 occurrences, all rejected | full 6,236-āyah Uthmānī corpus, `api.quran.com/api/v4/verses/by_chapter/{1..114}` | — | ✅ run against the full text, cross-checked against corpus.quran.com's root م-ت-ن listing (3, matching exactly) |
| 6 | Bukhārī 6384 fetched and confirmed to carry the shakk | Wayback capture, ts `20240617221329` | Ṣaḥīḥ al-Bukhārī | ✅ `أَوْ قَالَ ‏"‏ أَلاَ أَدُلُّكَ عَلَى كَلِمَةٍ …` — confirmed; not used on any beat |
| 7 | Duʿā splice report (shared with `al-qawiyy@1`) | Wayback captures of 6610/4205/6384/Muslim 385 + `api.quran.com/api/v4/verses/by_key/2:255` | mixed | ✅ all checked directly for `ٱلْعَلِيِّ ٱلْعَظِيمِ` (absent in all four ḥadīth routes); 2:255's ending confirmed live |
| 8 | Beat 2 (`name_intro`) and beat 7 (`dua`) fields | `collectible_names.json` id 63 | — | ✅ byte-identical, read programmatically |
| 9 | `.context/claims/` read at claim time and re-read at report time | `.context/claims/*.md` | project artifact | ✅ 38 files at claim time; re-read immediately before this table — no new file touches 62/63, `m-t-n`, `q-w-y`, 50:38, or Bukhārī 43/782 |

---

## Read as a user at 11pm

You are not being told to hold on a little longer because He is strong so it will be fine. You are
being shown a woman who could not stop, and a Prophet ﷺ who did not congratulate her for it — he told
her to do less, and gave the reason: not that she was weak, but that what she was leaning on does not
tire the way she does. **Then the same idea, at a scale nothing you're carrying tonight comes close
to** — heavens and earth, in six days, and nothing about it touched Him. The duʿā that follows is not
asking Him to make you tireless. It is you saying, in your own words, that the tiredness was always
supposed to be yours to have, because the strength underneath it was never running on the same
supply.

---

## What I could not determine, and what a verifier should attack first

1. **The `capacity`/`sustain` disclosure against `ar-rauf@1` is offered, not ruled** — per §9ab/§9bd,
   this is the row to attack first.
2. **The `created` overlap with `al-khaliq@1`** is judged separated on "sequence vs. cost"; a
   verifier should test that distinction directly.
3. **No isnād was audited.** Ḥadīth checking is not independent of sunnah.com as a corpus.
4. **The duʿā's "unpinned" status is a negative I could not fully close** — see the twin's identical
   limit.
5. **Bar 4 scores zero, stated at its true size — not softened.** A founder should decide consciously
   whether that is acceptable for this Name, given the brief's own prediction that this is "the normal
   shape of a hard deck."
6. **Bar-3 surface 2 was checked against 45 decks**, as a number, per the coordinator's mid-run
   correction. Re-run if the asset grows again before transcription.
