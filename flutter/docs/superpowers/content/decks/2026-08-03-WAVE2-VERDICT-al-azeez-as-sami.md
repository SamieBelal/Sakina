# Wave-4 adversarial verdict — `al-azeez@1` (id 8) and `as-sami@1` (id 45)

**Verifier note on method.** Blind per the brief: I read both drafts' beats/citations/Arabic in
full, then treated every ✅/verdict cell in their tables as a claim to re-derive, never as evidence.
All Qurʾān text below is freshly fetched from `api.quran.com/api/v4` (both the full 6,236-āyah
Uthmānī corpus for the two enumerations, and per-verse `text_uthmani`/`text_imlaei`/translations
20+85 for every cited āyah and its n±1 neighbours). Both ḥadīth were fetched from the **exact bare
cited numbers** via Wayback CDX (`muslim:395` capture `20260306031510`; `bukhari:2992` capture
`20250312100442`) — the same captures the drafter cites, independently re-fetched and re-read by me,
byte-for-byte. Catalogue facts (`collectible_names.json`) and shipped-deck facts
(`name_stories.json`, 34 decks, confirmed neither `al-azeez@1` nor `as-sami@1` is among them) were
read directly from the asset files in this worktree.

---

## `al-azeez@1` (id 8) — **FIX-THEN-SIGN**

### Confirmed independently (no defect)

1. **The enumeration (§1) is correct, recomputed from scratch.** I fetched the full 6,236-āyah
   Uthmānī text (`api.quran.com/api/v4/quran/verses/uthmani`, confirmed 6,236 verses) and ran my own
   mark-folded substring sweep for `عز`, independent of the drafter's method.
   - **33 distinct skeleton forms / 140 total occurrences** — matches the draft exactly.
   - Independently classified the 17 non-`ʿ-z-z` forms by root (`ʿ-z-m` ×6 forms, `ʿ-z-r` ×3,
     `ʿ-z-l` ×3, `ʿ-z-b` ×1, `m-ʿ-z` ×1, proper nouns ×2, `عزين` ×1 = **17 forms**) and summed their
     occurrences independently: **21 occurrences** — matches.
   - Remainder: **16 `ʿ-z-z` forms / 119 occurrences** — matches, including the exact split
     (`ٱلْعَزِيزُ` 46 + `ٱلْعَزِيزِ` 18 = 64; `عَزِيزٌ` 23 + `عَزِيزٍ` 1 = 24; `عَزِيزًا` 7; etc.).
   - **Finite `ʿ-z-z` verbs: exactly three** — `وَعَزَّنِى` (38:23, human), `وَتُعِزُّ` (3:26, Allah),
     `فَعَزَّزْنَا` (36:14, Allah). Confirmed by direct fetch of each verse. No fourth finite verb
     exists in the corpus. **Claim 1 in the task brief holds.**
   - The three elatives (`أَعَزُّ` 11:92, `وَأَعَزُّ` 18:34, `ٱلْأَعَزُّ` 63:8) are comparative
     adjectives, not finite verbs — correctly excluded from the bar-1 count.
   - 12:30/12:51/12:78/12:88 independently confirmed to be the Egyptian official's title
     (`al-ʿAzeez`), not a divine epithet.
   - 63:8 and 35:10 independently fetched; both rejection reasons hold (63:8 = hypocrites' boast +
     a stated clause; 35:10 contains `لَهُمْ عَذَابٌ شَدِيدٌ` inside the āyah).

2. **3:26 is genuinely spent.** `assets/content/name_stories.json`'s `al-malik@1` beat 5/6 render
   3:26 with `source: "Qur'an 3:26"` / `"Qur'an 3:26 (opening)"`, and `collectible_names.json` id 4's
   `dua_arabic` is confirmed to be the 3:26 opening. `al-azeez@1`/`as-sami@1` are confirmed absent
   from the 34-deck shipped asset (not yet transcribed), so this is genuinely unspent ground for
   3:26's alternative — 36:14 — not a race condition.

3. **36:13, 36:14, 10:65 — fetched, and the beats are Saheeh International (id 20) verbatim**,
   including beat 6's truncation point (`…Allāh entirely…` — the fetched translation is
   *"…entirely. He is the Hearing, the Knowing."*; the beat cuts before *"He is"*, ellipsis visible
   in the rendered `primary` string, not only the `source` field). Abdel Haleem's alternates (id 85)
   independently fetched and match the draft's characterization.

4. **Successor sweep at n±1 is accurate as far as it goes.** 36:12 (life-giving, off-screen
   `ḥ-y-y`), 36:15 (denial, no punishment), 10:64 (good tidings), 10:66 (no punishment) all fetched
   and match the draft's characterization exactly.

5. **Sūrah bounds confirmed by direct HTTP check:** `36:83`→200, `36:84`→404; `10:109`→200,
   `10:110`→404.

6. **Word-absence claim (§6, point 4) verified programmatically against the actual 8 rendered
   `primary` strings**: `battle`, `enemy`, `victory`, `destroyed`, `shout`, `punish*`, `kill*`,
   `war`, `sword`, `fight*` — **zero hits**, all ten. Confirmed.

7. **Bar-3 token-frequency claims verified against the real 34-deck corpus** (I built the string
   table from `name_stories.json` myself — 734 strings across `primary`/`arabic`/
   `transliteration`/`translation`/`source`/`label`): `almighty` **n=0**, `honor` **n=1** (only in
   shipped `as-salam@1`'s duʿā, *"Owner of Majesty and Honor"*), `town` **n=2** (both in shipped
   `at-tawwab@1`). All three match the draft exactly.

8. **Duʿā collision with ids 43/44 (Al-Muizz/Al-Muzill) verified against `collectible_names.json`
   directly.** Id 8: `يَا عَزِيزُ أَعِزَّنِي بِطَاعَتِكَ` / *"O Almighty, honor me through obedience to
   You."* Ids 43 and 44 (byte-identical to each other): `اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا
   تُذِلَّنِي بِمَعْصِيَتِكَ` / *"O Allah, honor me through obedience to You, and do not humiliate me
   through disobedience to You."* Shared Arabic run `أَعِزَّنِي بِطَاعَتِكَ` (2 words) and shared
   English run *"honor me through obedience to You"* (6 words, exact) both confirmed.

9. **Move adjacency vs. `al-mumin@1` — I RULE NON-BLOCKING.** Fetched `al-mumin@1`'s actual beats
   from the asset. Zero shared n-grams at any length (confirmed programmatically), and — unlike the
   `al-wakeel@1`/`al-mumin@1` precedent that was overturned to BLOCKING in ledger §9ab — there is
   **no beat-to-beat staging echo**: `al-mumin@1`'s beats 2–4 stage an armed physical threat
   resolved by protection; `al-azeez@1`'s beats 3–5 stage social rejection that is never resolved.
   No register word (`afraid`, `protect`, `safe`) appears in either deck's counterpart beats. The
   "given, not achieved" adjacency is real at the engine level but does not repeat itself
   beat-for-beat the way the precedent case did. Non-blocking.

### Findings requiring a fix before signing

**F1 — Bar-5 disclosure stops at 36:29 and should also cover 36:18, which is closer and darker.**
I fetched 36:16–20 (not disclosed in the draft's successor sweep, which only examined 36:12 and
36:15). **36:18 reads:** `قَالُوٓا۟ إِنَّا تَطَيَّرْنَا بِكُمْ ۖ لَئِن لَّمْ تَنتَهُوا۟
لَنَرْجُمَنَّكُمْ وَلَيَمَسَّنَّكُم مِّنَّا عَذَابٌ أَلِيمٌ` — *"They said, 'Indeed, we consider you
[a bad omen]. If you do not desist, we will surely stone you, and you will surely be touched by a
painful punishment from us.'"* This is an **explicit threat of stoning and painful punishment**,
directed at the messengers, sitting only **4 āyāt** past the deck's last quoted material (36:14) —
far closer than the 36:29 destruction the draft does disclose and argue at length (15 āyāt out).
The deck's own stated register discipline for this Name is *"do not conflate might with victory in
battle"* / avoid violence imagery, and 36:18 is exactly that register, one tap from the citation.

It does **not** overturn the deck's claim — the threat is never carried out on-screen, is not
narrated as an outcome, and if anything reinforces "the town never agreed" rather than contradicting
it — but it is closer, harsher, and more on-point for the founder's own named risk than the argued
36:29, and the draft's §6 ("the argument, stated so it can be attacked") does not mention it. **Fix:
add 36:16–19 to the disclosed successor sweep and extend §6's argument to cover it**, on the same
terms already used for 36:29 (softer-than-shipped-precedent calibration, contradicts no beat).

**F2 — The deck-internal-diff claim in §7, point 6 is factually wrong, though the true result is
even cleaner than claimed.** The draft states: *"The only ≥3-word deck-internal repeat is 'and the
town' (beats 3–4)."* I ran a pairwise n-gram diff over all 28 beat pairs of the 8 rendered `primary`
strings myself. **Result: zero shared ≥3-word runs between any pair of beats.** The phrase "and the
town" occurs exactly **once** in the whole deck (beat 4: *"...and the town called both of them
liars"*) — beat 8 has "The town never believed them," which shares only the 2-word "the town," not
"and the town," and not with beat 3 at all. There is no repeat to disclose; the claim describes a
collision that does not exist. **Fix: correct the sentence to state the true, stronger result** —
zero ≥3-word deck-internal repeats — rather than leave a specific, checkable, and wrong citation in
the table. Non-dangerous (it understates the deck's cleanliness rather than overstates it), but it
is exactly the class of error ledger §9ak exists to catch.

### Verdict: al-azeez@1 — FIX-THEN-SIGN

Both required fixes are prose/disclosure-only — no citation, beat, or catalogue change. Scripture
authenticity is 100% clean on independent re-derivation of every claim I could re-derive, including
the deck's central and most load-bearing finding (the full-corpus enumeration).

---

## `as-sami@1` (id 45) — **FIX-THEN-SIGN**

### Confirmed independently (no defect)

1. **Ṣaḥīḥ Muslim 395a — fetched from the exact cited Wayback capture
   (`web.archive.org/web/20260306031510/https://sunnah.com/muslim:395`) and read directly (page was
   served as plain UTF-8, no zstd needed for this capture).** Confirmed:
   - This is genuinely hadith **395a** (`<div class="hadith_reference_sticky">Sahih Muslim 395 a`,
     In-book reference **Book 4, Hadith 41** — matches the draft's claim exactly).
   - **No grade line is printed anywhere in the hadith body or its reference table** (only the UI's
     "Grade" filter-checkbox label contains the word "grade" — I confirmed this is the only 3 hits
     of the string "grade" on the page). The draft's claim that "ṣaḥīḥ" is a collection-level
     inference, not a fetched grade, is correct.
   - All three quoted Arabic clauses match byte-for-byte: `قَسَمْتُ الصَّلاَةَ بَيْنِي وَبَيْنَ
     عَبْدِي نِصْفَيْنِ وَلِعَبْدِي مَا سَأَلَ`; `فَإِذَا قَالَ الْعَبْدُ {الْحَمْدُ لِلَّهِ رَبِّ
     الْعَالَمِينَ} قَالَ اللَّهُ تَعَالَى حَمِدَنِي عَبْدِي`; `فَإِذَا قَالَ {إِيَّاكَ نَعْبُدُ
     وَإِيَّاكَ نَسْتَعِينُ} قَالَ هَذَا بَيْنِي وَبَيْنَ عَبْدِي وَلِعَبْدِي مَا سَأَلَ`.
   - **The §6 elision table's three omitted exchanges are verified verbatim against the fetched
     page**, including the narration's own variant (*"قَالَ مَجَّدَنِي عَبْدِي - وَقَالَ مَرَّةً
     فَوَّضَ إِلَىَّ عَبْدِي"*) and the final clause (*"قَالَ هَذَا لِعَبْدِي وَلِعَبْدِي مَا
     سَأَلَ"*). All three cited sibling-Name removals (Ar-Raḥmān/Ar-Raḥīm, Al-Malik, Al-Hādī) are
     correctly identified from the fetched Arabic.
   - Beats 3–5 are genuinely re-rendered, not pasted — the page's actual published English is the
     archaic USC-MSA text (*"Praise be to Allah, the Lord of the universe"*), confirmed different
     from the deck's rendering.

2. **Ṣaḥīḥ al-Bukhārī 2992 — fetched from the exact cited Wayback capture
   (`.../20250312100442/.../bukhari:2992`).** Confirmed byte-for-byte: `فَإِنَّكُمْ لاَ تَدْعُونَ
   أَصَمَّ وَلاَ غَائِبًا، إِنَّهُ مَعَكُمْ، إِنَّهُ سَمِيعٌ قَرِيبٌ` — matches the draft's cited
   Arabic exactly, including its distinction from the `لَيْسَ بِأَصَمَّ وَلَا غَائِبٍ` variant
   ("that page" vs. "a different route"). No grade line printed on this page either. This is also
   catalogue id 45's own `hadith` field (confirmed against `collectible_names.json`), quoted on no
   beat, used only as corroboration — as claimed.

3. **The fabricated line is absent, confirmed in two places, not one.** I read all 8 rendered
   `primary` strings of `as-sami@1` — no Zakariyyā/Yaḥyā content anywhere. I additionally pulled
   shipped `as-samad@1` (which does carry the Zakariyyā narrative, 19:2–7) directly from
   `name_stories.json` and confirmed its actual beat 4 reads *"We give you the good news of a son,
   whose name will be John — a name We have not given to anyone before"* — the real 19:7 content,
   with no trace of the fabricated *"I heard you — and here is the child, already named Yahya."*

4. **The `s-m-ʿ` enumeration substantively reproduces**, with one unexplained aggregate-count
   discrepancy that does not affect the load-bearing conclusion. Running my own mark-folded sweep
   over the full 6,236-āyah text (`سمع` substring plus the `سميع` family separately, since the
   latter has a yāʾ between mīm and ʿayn exactly as the draft notes):
   - The `سميع` family independently reproduces exactly: **5 forms / 47 occurrences**
     (`سميع` 21, `السميع` 19, `سميعا` 4, `لسميع` 2, `والسميع` 1) — matches the draft's corrected
     figure exactly, including the same yāʾ blind-spot the draft flags against its own first pass.
   - My aggregate count for the full root came to **39 forms / 163 occurrences**, against the
     draft's **40 forms / 167 occurrences** (after excluding Ismāʿīl). The 1-form/4-occurrence gap
     traces to how `يَسَّمَّعُونَ` (37:8, Form V "eavesdrop," shadda-intensive) folds against
     `يَسْمَعُونَ` under my diacritic-stripping — a known limit of my method (see below), not a
     reproduction of theirs.
   - **This does not change the substantive bar-1 finding**, which I verified directly rather than
     by trusting the aggregate: I independently pulled every candidate verb where Allah could
     plausibly be the hearing subject and fetched each one. Result: **exactly the same four āyāt,
     five tokens** the draft claims — **58:1** (two verbs, confirmed spent by shipped `al-baseer@1`
     via direct read of its `source` field), **3:181** (fetched: *"...We will record what they said
     ... and will say, 'Taste the punishment of the Burning Fire'"* — bar-5 fatal, confirmed), and
     **43:80** (fetched: rebuke register, confirmed, plus its second clause independently confirmed
     to carry the "recording messengers" theme, though see F3 below on how that clause is framed).
     **20:46 is confirmed the sole survivor.** The two excluded causatives — **35:22**
     `إِنَّ ٱللَّهَ يُسْمِعُ مَن يَشَآءُ` and **8:23** `لَّأَسْمَعَهُمْ`/`أَسْمَعَهُمْ` — were both
     fetched directly and independently confirmed to be Form IV ("cause to hear"), correctly
     excluded on the drafter's stated grounds.

5. **20:42–48 re-proposal (§2d live objection) — I RULE BAR 5 MET; not blocking.** I fetched
   20:42–48 in full, including 20:43 (`ٱذْهَبَآ إِلَىٰ فِرْعَوْنَ إِنَّهُۥ طَغَىٰ`, confirming
   Pharaoh is named in the passage, just never on a beat). The ledger's original rejection
   (`al-haleem@1`) was for a **forbearance** deck whose subject was Pharaoh's respite terminating in
   his eventual destruction. `as-sami@1`'s excerpt is a different sub-arc of the same passage —
   Mūsā and Hārūn's stated fear and Allah's reassurance — and renders no beat naming Pharaoh, a
   threat, or a confrontation. 20:48's *"the punishment will be upon whoever denies and turns
   away"* sits at n+2, is embedded in **instructed human speech** (words Mūsā/Hārūn are told to
   deliver *to* Pharaoh), general/conditional rather than an outcome for the story's subjects, and
   divine/eschatological rather than an enacted event — the same shape ledger §9aa already used to
   clear `al-haqq@1`'s comparable 20:71 finding, and softer on every axis than shipped
   `al-afuw@1`'s already-cleared 42:26 (severe punishment at n+1, unconditional). Under the
   established calibration rule ("a rule cannot forbid the softer case while shipping the harder
   one"), this passes. **The re-proposal is legitimate; §2d's rejection was correctly scoped to the
   Pharaoh sub-arc and does not reach this one.**

6. **The `hear` n=1→2 hapax — I RULE NON-BLOCKING, and this is distinguishable from the `afraid`
   precedent, not merely by the drafter's say-so.** I confirmed `hear` occurs exactly once in the
   34-deck corpus (`al-baseer@1`'s verse-beat `source` field: *"...the person in the same room could
   not hear"*). The `afraid` precedent (ledger §9ab) was overturned to BLOCKING because it was
   **one token doing the identical job across three consecutive staged beats** in near-identical
   phrasing. Here: (a) `al-baseer@1`'s "hear" sits in a **citation/source annotation**, not a
   primary rendered beat, and describes a **bystander's failure** to hear a human's complaint; (b)
   `as-sami@1`'s "hear" sits in the **verse beat's primary text**, spoken by Allah in the first
   person, and is the Name's own defining act. I compared both decks' full beat sequences and found
   **no staging echo** — `al-baseer@1`'s beats narrate Hājar and Zamzam; `as-sami@1`'s narrate the
   Fātiḥa qudsī and Mūsā/Hārūn. The word is doing structurally different work in a different field
   of a different narrative. Non-blocking.

7. **Move adjacency vs. `ar-raqeeb@1` — I RULE NON-BLOCKING.** Fetched `ar-raqeeb@1`'s actual beats.
   Zero shared n-grams, confirmed. Structurally distinct: `ar-raqeeb@1`'s consolation is that a
   **third party (angels) reports about an absent person to Allah**; `as-sami@1`'s is that **Allah
   replies directly to the person's own words while the person is present and mid-sentence**. No
   beat-to-beat staging parallel exists between the two decks (confirmed by reading both in full).

8. **All catalogue-locked collisions in §9 (items 1–6) confirmed directly against
   `collectible_names.json` and `name_stories.json`:** the "All-Hearing" gloss and 58:1 spent by
   `al-baseer@1` (confirmed via direct read of its actual `verse` beat's `primary` and `source`
   fields); `مُجِيبٌ`/*"responsive"* rendering `al-mujeeb@1`'s Arabic and English `name_intro`
   (confirmed: `الْمُجِيبُ` / *"The Responsive"*); `close`/`near` synonym pair (confirmed `near`
   n=2 across `al-ghafur@1` and `al-mujeeb@1`, `close` n=1 in `as-salam@1`); the *"Indeed my Lord
   is"* 4-word cross-deck run (confirmed against shipped `al-lateef@1` beat 3 and `al-kareem@1`
   beat 5, both fetched from the asset).

9. **Deck-internal diff (28 pairs) confirmed accurate**, unlike Al-Azeez's: I found exactly the
   claimed 5-word run (*"between Me and My servant"*) between beats 3 and 5, matching the draft's
   own disclosure and the §9v/§9al precedent (disclose, do not trim) precisely.

10. **Ellipsis visibility confirmed** on beats 3, 5, and 6 — all three visible in the rendered
    `primary` string, not only in the table.

### Finding requiring a fix before signing

**F3 — The 11:61 duʿā "byte-identical" claim is FALSE. Re-verified as instructed; the recommendation's
premise does not hold as stated.** The draft's §4 table and §7 both assert: *"quran.com's
`text_imlaei` tail: byte-identical, exact string equality... Not 'close', not 'to within one word'
— string equality."* I fetched `11:61` fresh and extracted the closing four words of `text_imlaei`:

```
catalogue dua_arabic  (id 45): إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ
quran.com text_imlaei (tail):  إِنَّ رَبِّي قَرِيبٌ مُّجِيبٌ
```

These are **not byte-identical**. `text_imlaei`'s `مُّجِيبٌ` carries a shadda (U+0651) on the mīm
(idghām) that the catalogue's `مُجِيبٌ` lacks — confirmed by codepoint-level diff. The correct
description is **rasm-identical, one diacritic differs** — the exact same class of overclaim the
project has already caught once, on the same axis, for a different deck: ledger §2a records `18:10`
(`ar-raheem@1`'s pinned duʿā source) as *"catalogue text is not byte-identical to `text_imlaei`;
rasm identical,"* and the pilot report (plan §6) records the identical failure mode for `18:10` in
an earlier wave (*"'letter-for-letter identical' ... when the strings differ ... immaterial
religiously, but the check did not pass"*).

**This does not block shipping the deck** — the duʿā ships **unpinned** either way (Option B), no
catalogue change is proposed, and the draft itself says the recommendation must not be actioned
without independent re-verification. That re-verification is now done, and it fails at the letter
the drafter chose to stand on. **Fix: correct "byte-identical / exact string equality" to
"rasm-identical, one diacritic differs (shadda)" in both §4 and §7** before this table is shown to
anyone deciding whether to pin. If Option A is ever actioned later, it should be actioned on the
corrected, weaker claim, not the false stronger one.

### Verdict: as-sami@1 — FIX-THEN-SIGN

One required fix, and it is entirely inside the verification prose (§4/§7) — no beat, citation, or
catalogue change, since the duʿā already ships unpinned. Every ḥadīth citation, the fabrication
check, the enumeration's substantive conclusion, both previously-open live objections (20:42–48,
the `hear` hapax), and both disclosed-but-unruled move adjacencies (`al-mumin@1`/Al-Azeez,
`ar-raqeeb@1`/As-Sami) all independently confirm or resolve non-blocking.

---

## My own method's limits, stated

1. **No corpus independent of `api.quran.com`.** Both my root enumerations and every per-verse
   fetch used the same API family the drafters used. A muṣḥaf-independent re-run (Tanzil, a
   downloaded Uthmānī text file, or a morphological corpus) is the strongest remaining check on
   both enumerations, and neither drafter nor I have done it.
2. **My root-form counting is mark-folding by regex, not a morphological parse**, same limit both
   drafts already disclose about themselves. My al-`ʿ-z-z` recount matched the draft's figures
   exactly; my `s-m-ʿ` recount did not (39/163 vs. 40/167), and I could not fully resolve the
   discrepancy inside this pass — I resolved it the only way that matters for a bar-1 ruling, by
   fetching every individual Allah-as-subject candidate directly rather than trusting either
   aggregate, and both drafts' four-āyāt conclusion held under that direct check.
3. **No isnād audited, same as both drafts disclose.** I confirmed the absence of a printed grade
   line on both fetched ḥadīth pages myself, which is a narrower and different check than auditing
   the chain.
4. **I did not exhaustively n-gram-diff either draft's 8 beats against all 34 shipped decks' full
   734-string corpus.** I ran targeted checks against every specific claim the drafts made (and
   against the two named move-adjacencies), and those all held or were correctable as stated above.
   A brute-force all-pairs diff was not run within this pass.
5. **Wayback/CDX captures derive from the same underlying sunnah.com digitisation** the drafters
   used; no printed edition or Shamela/Dorar was consulted by me either.
