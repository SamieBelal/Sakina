# Wave 2 adversarial verdict — Ar-Rauf (87) and Al-Wahhab (12)

**Verifier:** independent, blind to the drafter's own verdict — read the drafts' claims as claims,
not as evidence. Every scripture citation below was re-fetched live during this pass; no citation
was accepted on the drafter's word.

**Method actually used (stated so its limits are visible):**
- Qurʾān: `api.quran.com/api/v4/verses/by_key/{s}:{a}?fields=text_uthmani&translations=20`, live,
  for every citation and every successor-sweep neighbour in both drafts (46 distinct āyāt fetched).
- Ḥadīth: Wayback **CDX API** for the bare `sunnah.com/bukhari:3207` capture, decoded (curl handled
  the `zstd` transparently), read in full — matn, isnād line, and a whole-page grep for
  `hell/fire/punish/النار/عذاب`.
- Catalogue: read `assets/content/collectible_names.json` ids 87 and 12 directly, and
  `assets/content/name_stories.json` (all 34 shipped decks, all beats, all four rendered fields) —
  not the drafts' quotations of them.
- Ran my own programmatic n-gram diff (N=5, N=4) of both drafts' eight beats against every rendered
  string in the shipped corpus, and a deck-internal beat-to-beat diff, independent of the drafts'
  own tables.
- Read `COLLISION-LEDGER.md` in full (1286 lines) and the governing plan §5–§7.

---

## Verdict: Ar-Rauf (`ar-rauf@1`, id 87) — **FIX-THEN-SIGN**

### What independently checks out (high confidence)

- **All 13 `r-ʾ-f` citations fetched and confirmed verbatim** (Arabic + SI English), matching the
  draft exactly: 2:143, 2:207, 3:30, 9:117, 9:128, 16:7, 16:47, 22:65, 24:20, 57:9, 59:10 (the 11
  `رَءُوف`), plus 24:2 and 57:27 (the 2 `رَأْفَة`). Nine of the eleven really are the fixed pair
  `رَءُوفٌ رَّحِيمٌ`; 9:128's `رَءُوف` really does predicate the Prophet ﷺ, not Allah (confirmed
  grammatically — subject is `رَسُولٌ`); 24:2's raʾfa really is human and forbidden inside a ḥadd
  passage ending on witnessed punishment; 57:27's really is placed in human hearts, ending
  `وَكَثِيرٌ مِّنْهُمْ فَـٰسِقُونَ`. I could not independently re-run the full 6,236-āyah sweep
  myself in the time available, but every individual āyah the draft cites checks out, the count (11
  + 2 = 13, no verbal form) matches well-established Qurʾān word-frequency data, and nothing in my
  spot-checking contradicts it. **This is real, not asserted.**
- **Bukhārī 3207 verified independently via the exact CDX capture the draft names
  (`20260701073633`).** Confirmed: page title "Beginning of Creation — كتاب بدء الخلق" (Kitāb Badʾ
  al-Khalq); isnād reads `حَدَّثَنَا أَنَسُ بْنُ مَالِكٍ ، عَنْ مَالِكِ بْنِ صَعْصَعَةَ`
  (Anas ← Mālik b. Ṣaʿṣaʿa, exactly as claimed); the number sequence fifty→forty→thirty→twenty→
  ten→five is in the Arabic in that order; the closing clause is byte-for-byte
  `فَنُودِيَ إِنِّي قَدْ أَمْضَيْتُ فَرِيضَتِي وَخَفَّفْتُ عَنْ عِبَادِي، وَأَجْزِي الْحَسَنَةَ
  عَشْرًا` followed only by a supplementary isnād note about al-Bayt al-Maʿmūr, exactly as claimed;
  and a whole-page grep for `hell/fire/punish/النار/عذاب` returned **zero hits**, confirming claim
  1.4 exactly. The page prints no grade line (only a UI tab labelled "Grade" with no value), matching
  the draft's own disclosure. **Claim 1.1–1.4 all independently confirmed.**
- **Successor sweep (4:26–4:30) confirmed verbatim.** 4:30's Fire clause is real, at n+2, and is
  conditional on 4:29's specific unjust-consumption/killing — the draft's calibration against
  shipped `al-afuw@1` (42:26's harder, class-aimed, eschatological punishment, non-blocking) is a
  fair comparison. **I rule bar 5 MET, non-blocking**, on the same calibration.
- **The al-lateef@1 collision is real and exactly as measured**, independently re-derived by me from
  `name_stories.json` rather than trusted from the draft: `al-lateef@1`'s duʿā Arabic is
  `يَا لَطِيفُ الْطُفْ بِي فِيمَا جَرَتْ بِهِ الْمَقَادِيرُ` (shares `الْطُفْ بِي`, 2 words) and its
  English is *"O Subtle One, be gentle with me in all that destiny has decreed"* (shares *"One, be
  gentle with me"*, 5 words, against catalogue id 87's *"O Compassionate One, be gentle with me and
  protect me from trials."*). My own cross-corpus n-gram diff of all 8 beats against all 34 shipped
  decks' four rendered fields (N=5, N=4) found **exactly the same three hits the draft reports and
  no others** — `"one be gentle with me"` (5-gram), `"be gentle with me"` (4-gram), `"one be gentle
  with"` (4-gram), all against `al-lateef@1` beat 7. This collision **predates the draft** — it is
  already in `COLLISION-LEDGER.md` §4c and §6d.4, computed before this deck was written — so the
  draft did not manufacture or miss it; it inherited a known, catalogue-locked, unfixable defect and
  disclosed it at full strength, correctly.
- **Deck-internal self-overlap: confirmed zero 4-gram collisions** across all 28 beat pairs
  (re-derived independently, not trusted from the draft's §9v-style claim).
- **Bar-3 "the move" table:** I independently ruled on the two flagged adjacencies.
  - `as-samad@1` (*"Leaning is not weakness"*) vs Ar-Rauf (*"the requirement moved to fit the
    creature"*): **NON-BLOCKING.** As-Samad answers shame about *being* needy; Ar-Rauf's beat 8
    never addresses the user's feelings about needing at all — it states a historical fact about a
    number changing. A user reading both would not feel told the same thing twice.
  - `al-kareem@1` (also a first-person night ḥadīth) vs Ar-Rauf: **NON-BLOCKING.** Different ḥadīth,
    different questions asked, different takeaway object (cost to the Giver vs. size of the demand).

### Findings that must be corrected before sign-off

1. **Minor but real overclaim in the bar-3 token table: `kind` n=3 is padded by two false
   positives.** I independently re-derived every occurrence of the token `kind` in the 34-deck
   corpus. There are 3, but only **one** (`al-lateef@1` verse beat, *"Allah is Ever Kind to His
   servants"*) is the adjective sense (gentle/compassionate) relevant to a bar-3 collision. The
   other two are a different word entirely: `al-jabbar@1` beat 3's *"the same **kind of** shirt"*
   and `al-qadir@1` beat 0's *"its own **kind of** tired"* both use *kind* to mean *type/category*,
   unrelated to compassion. This does not change the deck's own claim (it renders *kind* zero
   times), but the table should not cite those two as corpus density for the relevant sense — it is
   exactly the "state the measurement, not the adjective" failure mode the ledger's §9ak names.
2. **The deck's central premise is unverified and should be surfaced to the founder as a named
   decision, not left in item 6 of the closing list.** The entire bar-1/bar-4 trade rests on reading
   *raʾfa* as "the tenderness that will not overload a creature" — and then treating Allah's
   `خَفَّفْتُ` (*I lightened*) and `يُخَفِّفَ` (*He wants to lighten*) as *demonstrations* of that
   quality, even though `kh-f-f` is a different root from `r-ʾ-f` and no cited text ever uses the
   Name's own root in a verbal or predicative sense. I have no tafsīr or lexicon access and could
   not corroborate this equivalence independently — **I could not confirm it, and per the brief's
   own instruction I default to flagging rather than accepting it.** The sweep proving bar 4 is
   forced is genuinely excellent and independently reproduced by me; that is not in question. What
   is in question is whether "lightening a religious obligation" is the right substitute
   demonstration for "tenderness," and that is a theological judgment call, not a fetch. It should
   be the first thing the founder is asked to sign, not the sixth.
3. **Minor: the `al-hadi@1` beat-8 line is quoted with quotation marks in the bar-3 "move" table but
   is truncated without an ellipsis**, dropping its final clause ("...asking for it is the prayer
   itself."). Not user-facing — internal to the verification report only — but should be exact or
   marked, per the same discipline the ledger enforces on shipped beats.

### My own method's limits, stated

I did not run the full 6,236-āyah sweep myself; I re-verified every individual citation and the
count against well-known Qurʾān word-frequency data, but I did not reproduce the drafter's exact
mark-folding/subsequence-match procedure from scratch. I audited no isnād — collection-level ṣaḥīḥ
was accepted for Bukhārī 3207, as the plan permits. I have no tafsīr/lexicon corpus, so finding 2
above (the raʾfa≈lightening premise) is flagged, not resolved, by me.

---

## Verdict: Al-Wahhab (`al-wahhab@1`, id 12) — **FIX-THEN-SIGN**

### What independently checks out (high confidence)

- **Every Qurʾānic citation fetched and confirmed verbatim**, Arabic and SI English, including all
  ten Allah-subject `wahaba` āyāt (6:84, 19:49, 19:50, 19:53, **21:72**, 21:90, 29:27, 38:30, 38:43,
  42:49) and all three Name-noun `ٱلْوَهَّاب` occurrences (3:8, 38:9, 38:35), plus 37:99–101, 37:112,
  11:71, 3:7, 3:9, 42:50, and the full successor sweep of 21:68–74. I found **no mismatch anywhere.**
- **21:72 really is the only one of the ten with no sibling root in the āyah** — verified word by
  word against the fetched Arabic (`وَوَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ نَافِلَةً ۖ وَكُلًّا
  جَعَلْنَا صَـٰلِحِينَ`: no `r-ḥ-m`, `h-d-y`, `q-d-r`, `ʿ-l-m`). 6:84 really carries `هَدَيْنَا`;
  19:50/19:53 really carry `رَّحْمَتِنَا`; 21:90 really is Zakariyyā (`فَٱسْتَجَبْنَا لَهُۥ
  وَوَهَبْنَا لَهُۥ يَحْيَىٰ`); 38:43 really is Ayyūb with the identical "doubled family" content
  already on shipped `ash-shafi@1`'s screen; 42:49 really is the grammatically strongest form and
  42:50 really does end `وَيَجْعَلُ مَن يَشَآءُ عَقِيمًا` with trailing `عَلِيمٌ قَدِيرٌ`.
- **3:8 really is human speech** (`ٱلرَّٰسِخُونَ فِى ٱلْعِلْمِ`'s own words, confirmed by fetching
  3:7), and — critically — **the deck does not use it as a bar-1 carrier.** Bar 1's actual carrier
  is 21:72 (Allah's own finite verb, first person plural). 3:8 is used only as the duʿā beat, which
  is human petition by the format's own design (every shipped duʿā-pinned deck does this). **The
  probe in the brief — "if any beat's bar-1 carrier is human speech, that is blocking" — does not
  fire here.** This is correctly handled, not a violation.
- **The catalogue duʿā truncation is exactly as claimed**: id 12's `dua_arabic` is the first 12
  words of 3:8, differing in exactly the two orthographic marks claimed (`مِنْ`/`مِن`,
  `لَدُنْكَ`/`لَّدُنكَ`), and the omitted tail is exactly the 3 words `إِنَّكَ أَنتَ ٱلْوَهَّابُ` —
  I computed this independently from the fetched 3:8 and the catalogue string and it matches.
- **Zakariyyā is correctly and entirely avoided.** The brief specifically probed this (As-Samad and
  Al-Aleem both use Zakariyyā/Maryam-passage material). This deck's story is Ibrāhīm → Isḥāq →
  Yaʿqūb (21:72, 37:100, 11:71) — no Zakariyyā content anywhere, confirmed by reading every quoted
  and cited passage. **Clean on this axis.**
- **Distinguished from `ar-razzaq@1` correctly.** Ar-Razzaq's move (verified from
  `name_stories.json`) is *"provide for them from sources they could never imagine"* — trust
  producing routine sustenance. Al-Wahhab's move is a specific request answered with a **named
  surplus** beyond its own terms. These are not the same insight; I rule **NON-BLOCKING.**
- **The ar-raheem@1 and al-hadi@1 duʿā collisions are real, exactly as measured, and pre-existing**
  (already in `COLLISION-LEDGER.md` §4c and §6d.6, computed before this draft existed). My own
  independent n-gram diff of all 8 beats against the full 34-deck corpus found **exactly the three
  hits the draft reports and no others**: `"grant us mercy from yourself"` (5-gram), `"grant us
  mercy from"` (4-gram), `"us mercy from yourself"` (4-gram), all against `ar-raheem@1` beat 7. The
  Arabic 3-word run (`مِنْ لَدُنْكَ رَحْمَةً`) is also confirmed exact.
- **Deck-internal self-overlap: confirmed near-zero** — my own re-derivation found a single trivial
  3-gram (*"asked for is"*, beats 1 and 4, a formulaic fragment) and **zero 4-grams**, matching the
  draft's own claim at its stated threshold (N=4).
- **The 37:100↔21:72 authored join is honestly disclosed**, and the corroboration (37:112's
  `نَبِيًّا مِّنَ ٱلصَّـٰلِحِينَ`, twelve āyāt after `هَبْ لِى مِنَ ٱلصَّـٰلِحِينَ` — I confirmed
  100→112 is exactly 12 āyāt) is real and does what it claims: shows the Qurʾān itself running the
  same word back to Ibrāhīm inside the same sūrah, independent of this deck's cross-sūrah splice.
- **as-samad@1 / al-jabbar@1 staging adjacencies**: I rule both **NON-BLOCKING**. As-Samad's engine
  is about the shame of neediness; Al-Wahhab's is about a request being exceeded — different objects
  entirely, and As-Samad's distinctive tokens (`heir`, `prayed`) are correctly absent from
  Al-Wahhab's beats (see finding 1 below for a correction to *how* this was measured, not to the
  underlying fact). Al-Jabbar/Yaʿqūb: same person, opposite role (grieving father vs. the gift
  itself), zero shared strings — non-blocking.

### Findings that must be corrected before sign-off

1. **A demonstrably false claim in the verification table.** Row: *"`prayed` / `heir` | **2** /
   **1** — both at `as-samad@1` b2."* **This is false.** I independently counted every occurrence of
   `prayed` across all four rendered fields of all 34 shipped decks. There are exactly two — but
   only **one** is at `as-samad@1` (story beat: *"An old man with no heir **prayed** a prayer..."*).
   The second is at **`an-nur@1`'s bridge beat**: *"...to watch how the Prophet ﷺ **prayed**."*
   The undermeasured fact (Al-Wahhab uses neither token) is still true, and the claim does not
   change any bar ruling. But it is a **verified, exact false measurement**, of precisely the class
   the ledger's §9ak/§9aj/§9u sections name as the recurring, catchable failure mode across every
   prior wave — a number that reads as checked but was not checked against the full corpus, only
   against the expected deck. **Must be corrected in the packet before it is treated as reliable.**
2. **Bar-4's "on screen" claim overstates what actually renders.** The table states: *"the Name's
   own root twice, on two rendered screens... on screen? yes — beats 6 and 7."* Beat 6 (verse) in
   this draft has no populated Arabic field — it is English-only, matching the 11-of-14 shipped
   majority the plan's own schema note (§ "One schema fact that bar 3 depends on") explicitly warns
   about. So `وَوَهَبْنَا` does **not** visibly render on screen at beat 6 — only the English word
   *"gave"* does. The Arabic root visibly renders **once**, at beat 7 (the duʿā, catalogue-locked,
   not authored by this deck). The underlying fact — the root is present in the cited 21:72 — is
   true and unaffected; the "on screen: beats 6 and 7" framing conflates *present in the cited
   scripture* with *visibly rendered in Arabic on screen*, which is exactly the distinction the plan
   itself calls out as a live risk for verse beats. **Correct the claim to: root present in the
   underlying scripture at beat 6 (English only renders); root visibly renders in Arabic only at
   beat 7.**

### My own method's limits, stated

I did not run the full 6,236-āyah `w-h-b` sweep myself from scratch; I re-verified every individual
citation the draft produced from it and found no mismatch, but I did not reproduce the
mark-folding/homograph-filtering procedure independently. I audited no isnād (this deck cites none).
I have no tafsīr/lexicon corpus, so I could not independently adjudicate the `نَافِلَةً` question —
but the draft does not ask a verifier to; it discloses the ambiguity and shows its chosen rendering
(SI's *"in addition"*) does not depend on resolving it, which I find sound as stated.

---

## Summary for the founder

| deck | authenticity | bar 1 | bar 2 | bar 3 | bar 4 | bar 5 | verdict |
|---|---|---|---|---|---|---|---|
| `ar-rauf@1` (87) | clean, independently re-verified | met, but on an **unverified lexical premise** (raʾfa ≈ "lightening") — flag for founder | met | met, one pre-existing catalogue-locked collision (al-lateef@1), correctly disclosed | traded, sweep independently confirmed forced | met (argued, calibrated against shipped precedent) | **FIX-THEN-SIGN** |
| `al-wahhab@1` (12) | clean, independently re-verified | met cleanly, strongest available form, no lexical leap needed | met | met, three pre-existing catalogue-locked collisions, correctly disclosed | met, but "on screen" framing overstates by one beat | met (argued, well-corroborated) | **FIX-THEN-SIGN** |

**Neither deck contains a fabricated, misnumbered, or misattributed citation.** Every failure found
in this pass is measurement precision, not authenticity or a hidden bar failure — consistent with
the pattern the ledger records across every prior wave. The one item that should genuinely give the
founder pause before signing `ar-rauf@1` is not a defect the pipeline can fix mechanically: it is
whether *"the tenderness that will not overload"* is the right reading of *raʾfa*, since the entire
deck is built on treating a different root's action (`kh-f-f`, lightening) as the demonstration of
it. That is a theological call, not a citation check, and it is the deck's real risk.
