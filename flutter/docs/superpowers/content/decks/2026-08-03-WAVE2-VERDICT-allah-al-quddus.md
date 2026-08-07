# Wave 2 adversarial verdict — `allah@1` and `al-quddus@1`

**Independent verifier, blind to the drafter's own ✅ table.** Every claim below was re-derived from
a live fetch or a local recomputation over `assets/content/name_stories.json` (34 shipped decks, 734
rendered strings, confirmed by direct count) and the full 6,236-āyah Uthmānī text (fetched fresh from
`api.quran.com/api/v4/verses/by_chapter/{1..114}`, confirmed 6,236 rows). Methods are stated inline;
"could not verify" items are in §5.

---

## Probe 9 first, as instructed — `al-kareem@1` beat 8 vs `al-quddus@1` beat 8

**RULING: BLOCKING.**

Independently confirmed, byte-for-byte, from `assets/content/name_stories.json`:

- `al-kareem@1` beat 8 (`takeaway`): *"You are not drawing on a supply that runs down. The One being
  asked is Free of need — the asking costs Him nothing at all."*
- `al-quddus@1` draft beat 8: *"Nothing anyone has ever done has made Him more. Nothing anyone has
  ever done has made Him less. Whatever you are carrying tonight has not changed Him — and what
  does get through was never the offering. It is the piety from you."*

A 3/4/5-gram sweep of the exact `al-quddus@1` beat text against all 734 rendered strings of the 34
shipped decks (script run independently) returns **zero shared n-grams at n≥3 with `al-kareem@1`
specifically** — confirming the drafter's own measurement. The collision is not lexical; it is the
move, and §9an/§9aq exist precisely because n-gram cleanliness does not settle bar 3.

**Why I rule blocking rather than accepting the drafter's four differentiators (object / consolation
/ direction / vocabulary hygiene):** those are real and I re-verified the vocabulary-hygiene claim
independently (`"Free of need"`, `"a supply that runs down"`, `"costs Him"`, `"drawing on"` — all
n=0 in the `al-quddus@1` beats, confirmed). But COLLISION-LEDGER §9x/§9ab/§9ao/§9aq establish, as a
now-empirical rule, that **a drafter may not clear its own beat-to-beat "move" echo**, and in the two
prior instances where a drafter offered reasons rather than a ruling on exactly this shape
(`al-mumin@1`/`al-wakeel@1` at §9ab, and `ar-raqeeb@1`/`al-ghafur@1` at §9aq→§9ao), the independent
pass overturned the drafter's separability argument both times. This deck's own §9d explicitly
declines to rule and asks the verifier to. I take that seriously and rule.

On the substance: both beats are the deck's final, "mic-drop" line; both are built from the identical
rhetorical device (a negated bipolar pair collapsing to "He is unaffected"); both are addressed to a
user at the same moment in the product's daily-card mechanic. The differentiators the drafter names
are real at the level of *content* (what act — asking vs. having-acted — is said not to move Him) but
not at the level of *shape*, and shape is exactly what n-gram sweeps cannot see and what bar 3's
third surface exists to catch. Applying §9o's test at the level the pipeline has actually applied it
in its two live precedents (not at the level of "is it literally the same sentence," which neither
precedent case was either) — **yes, a user could plausibly feel told the same thing twice.**

**Required fix:** per the drafter's own named escape hatch (§9d) and the precedent in §9ao (a
beat-to-beat move echo is fixed with a *new* beat 8, not a reword) — replace `al-quddus@1` beat 8
using the unspent kneeling detail in beat 2. Do not reword the current beat 8; the drafter is
correct that no local rewording removes the shape.

---

## `allah@1` — **FIX-THEN-SIGN**

### Verified independently and holding up

1. **Bar-1 enumeration (probe 1).** Re-ran the "Allah names Himself in the first person" sweep over
   the freshly-fetched full 6,236-āyah text (fold: strip combining marks, normalize alif/yā/tā
   marbūṭa variants; substring-match `انا الله`). **Result: exactly the same four hits the draft
   reports — 20:14, 27:9, 28:30, and the 9:94 fold false positive (`نَبَّأَنَا ٱللَّهُ`, "Allah has
   informed us," not self-naming).** No fifth hit exists under this method. **No fourth genuine
   āyah found — the enumeration's central claim holds.**
2. **7:180 BLOCKED (probe 3).** Fetched 7:179/7:180/7:181 live. 7:180 ends `سَيُجْزَوْنَ مَا كَانُوا۟
   يَعْمَلُونَ` ("They will be recompensed for what they have been doing") and n−1 (7:179) is the
   Hell āyah — both exactly as claimed. Confirmed BLOCKED is correct, not a pass-over.
3. **Scene separation from `al-hadi@1`/`al-haqq@1` (probe 2).** Ran a full 3/4/5-gram sweep of all 8
   `allah@1` beats against all 734 rendered strings of the 34 shipped decks. **Zero overlaps at any
   n against `al-hadi@1` or `al-haqq@1` specifically** — confirmed independently. The shared figure
   (Mūsā) does not produce a shared scene in rendered text.
4. **Successor/predecessor sweep on 20:7–20:21** — every fetched āyah (20:7, 20:8, 20:9, 20:10,
   20:11, 20:12, 20:13, 20:15, 20:16, 20:17, 20:18, 20:19, 20:20, 20:21) matches what is quoted or
   described in the draft, including 20:16's `فَتَرْدَىٰ` ("you [then] would perish") and 20:21's
   `خُذْهَا وَلَا تَخَفْ` ("Seize it and fear not"). Bar-5 argument (probe 5's "arm the reviewer with
   the row to attack") is accurately stated, not inflated.
5. **All six quoted spans (beats 2–6) verified as exact substrings/full-āyāt of the live Saheeh
   International translation**, with both elisions (20:10's `هُدًى` clause, 20:12's `ٱلْوَادِ
   ٱلْمُقَدَّسِ` clause) genuinely omitted and marked with a visible `…` in the rendered beat text.
6. **The 734-rendered-string corpus count is exact** (recomputed independently from the JSON: 34
   decks × non-empty `label/primary/arabic/transliteration/translation/source` = 734).
7. **The "66 English `Allah` strings in 29 of 34 decks" measurement is exact** under the definition
   the deck actually uses (bare ASCII "Allah," word-boundary, excluding the macron form `Allāh` and
   excluding transliteration/Arabic fields) — recomputed and got 66/29 precisely. `god` token: exact
   single hit, `al-mujeeb@1`'s duʿā, confirmed. This is the deck's load-bearing bar-3 finding for the
   `name_intro` "God" and it survives.
8. **Deck-internal diff: zero beat-pairs ≥4 words**, confirmed by independent recomputation over all
   28 pairs.
9. **The tawḥīd-formula ruling the deck explicitly requests (§9b.2) — I rule on it.** `لَآ إِلَـٰهَ
   إِلَّآ` is the Qurʾān's own creedal formula, and unlike a beat-to-beat *move* echo (probe 9,
   above), this is lexically-identical *shared scripture*, the class §9o already rules on: a Qurʾānic
   formula is a form of address/creed, not a claim a deck is "teaching." **RULING: NOT BLOCKING.**
   Elsewhere this recurs (Al-Hayy, Al-Ahad, Al-Wahid) and should be handled the same way each time.

### Blocking finding — the duʿā provenance disclosure is factually wrong (probe 4)

The draft's §7 states: *"Wayback CDX for `sunnah.com/mishkat:2452` → **empty response**"* and
concludes the *hamm/ḥazan* duʿā is *"unverifiable by this pipeline."*

**I re-ran the identical query and it is false.**

```
GET https://web.archive.org/cdx/search/cdx?url=sunnah.com/mishkat:2452&output=json
```
returns **7 rows, 6 of them `statuscode:200`** (timestamps 20220617173636, 20231207075327,
20240527012918, 20250319070126, 20260115093149, 20260417131107). I fetched
`https://web.archive.org/web/20260417131107id_/https://sunnah.com/mishkat:2452` directly (plain
HTML, no zstd on this capture) and it renders. **The page is *Mishkat al-Masabih* 2452**, narrated
from Ibn Masʿūd, **transmitted by Razin** (outside the six canonical books; the page prints no grade
line), and its Arabic reads in full:

> `اللَّهُمَّ إِنِّي عَبْدُكَ وَابْنُ عَبْدِكَ وَابْنُ أَمَتِكَ ... أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ سَمَّيْتَ بِهِ نَفْسَكَ أَوْ أَنْزَلْتَهُ فِي كِتَابِكَ أَوْ عَلَّمْتَهُ أَحَدًا مِنْ خَلْقِكَ أَوْ أَلْهَمْتَ عِبَادَكَ أَوِ اسْتَأْثَرْتَ بِهِ فِي مَكْنُونِ الْغَيْبِ عِنْدَكَ...`

Catalogue id 1's `dua_arabic` — `اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ` — is a **splice**
of this page's opening (`اللَّهُمَّ إِنِّي`) directly onto its `أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ` clause,
**omitting the entire intervening servant/forelock/decree clause** — the same composite shape
COLLISION-LEDGER §9k already names for ids 17 and 61.

**What this changes and what it does not:**
- It does **not** change the final disposition. Razin's additions to *Mishkat al-Masabih* are outside
  the six books and this page carries no grade; combined with the splice, this remains **correctly
  unpinnable** under this project's sourcing tier (plan §5: "Qur'an and canonical collections are
  authorities for text... grading is a required column").
- It **does** falsify the specific claim that grounds the "unverifiable by this pipeline" framing.
  A route was reached, read, and is a plausible near-match — the correct finding is "found, but
  disqualified by tier and by being a splice," not "the collections that carry it are outside what
  this pipeline can reach." Those are different findings, and per the deck's own citation of §9k, the
  distinction the deck is trying to protect (unverifiable ≠ unsourced) is exactly the one this error
  gets backwards in the other direction: the deck reports "unreachable" for a route that is in fact
  reachable and substantively informative.

**Required fix:** rewrite §7 (and the §12 point-1 callback) to state what was actually found: the
Ahmad route (`ahmad:3712`, `ahmad:37*`) is genuinely unreachable (independently confirmed: CDX for
`ahmad:3712` returns `[]`; CDX for `ahmad:37*` returns exactly 10 captures, all 2–3-digit numbers,
none in the 3,7xx range — both reconfirmed exactly as claimed); the Mishkat/Razin route **is**
reachable and **is** a splice-match, and is excluded on tier/grading, not on unreachability. The
duʿā stays UNPINNED — the conclusion survives — but on the corrected grounds.

### Minor, non-blocking — a measurement stated imprecisely (§9ak)

§5's collision-avoidance argument for eliding 20:10's guidance clause states: *"Measured: `guide`
renders in **6 decks**, `guidance` in **2** (both `al-hadi@1`)."* Recomputed independently: the exact
word **"guide"** occurs **6 times**, but across only **3 decks** (`al-hadi@1` ×2, `al-wadud@1` ×1,
`ar-raheem@1` ×1 — recount: `al-hadi@1` contributes 2 of the 6, `al-wadud@1` 1, `ar-raheem@1` 1; the
6th and 5th recur inside `al-hadi@1`'s own beats). **"6" is an occurrence count, reported as a deck
count.** This does not change the elision decision (the actual root cause, `al-hadi@1` rendering the
same root inside the same clause, is untouched) but §9ak exists precisely to catch this class of
slip. Correct "6 decks" to "6 occurrences across 3 decks" before shipping.

### Everything else probed and holding

- Bar-1 "Names as a set" enumeration: re-ran the `اسما` sweep over the full text, got the same 9
  hits (2:31, 2:33, 7:71, 7:180, 12:40, 17:110, 20:8, 53:23, 59:24) as the refusal document claims.
- 27:9, 28:30, 79:24, 9:94, 20:8 all fetched and match the draft's quoted Arabic/English exactly.
- Al-Quddus amendment (§8): confirmed 20:12's `ٱلْوَادِ ٱلْمُقَدَّسِ` clause is elided from
  `allah@1` beat 3 and unrendered on both decks; `al-quddus@1`'s own bar-1 refusal of 20:12 (a valley,
  not Allah) is independent of this and unaffected, consistent with the claim of "net effect: none."

---

## `al-quddus@1` — **FIX-THEN-SIGN**

Everything checkable in this draft was checked, and it is the more accurate of the two packets.

### Verified independently and holding up, in full

- **Muslim 487a (probe 6/7).** Fetched the exact cited capture
  (`web.archive.org/web/20260210003623id_/https://sunnah.com/muslim:487a`). Page Arabic:
  `سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلاَئِكَةِ وَالرُّوحِ`; catalogue `dua_arabic`:
  `سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلَائِكَةِ وَالرُّوحِ`. **The only difference is fatḥa-before-alif vs.
  fatḥa-after-alif in "the angels" — a single orthographic/typesetting variant, rasm-identical**,
  matching the claimed size exactly and matching the `al-aleem@1`-pin precedent (confirmed against
  the test file's actual pin string, which needs `(opening words)` only because *that* duʿā is
  truncated — `al-quddus@1`'s is not, so the "no qualifier needed" reasoning holds). **Bare pin
  `'al-quddus@1': "Sahih Muslim 487a"` is well-supported.**
- **Narrator and posture (probe 7).** The fetched page reads: `أَنَّ عَائِشَةَ نَبَّأَتْهُ أَنَّ
  رَسُولَ اللَّهِ ﷺ كَانَ يَقُولُ فِي رُكُوعِهِ وَسُجُودِهِ` — ʿĀʾisha, of the Prophet ﷺ, in
  bowing and prostration. **No angels-as-speaker anywhere on the page or in the deck.**
  `grep -i angel` on the fetched HTML returns only the phrase *"Lord of the **Angels**"* inside the
  translated content, never as a narrator. **"Holy, Holy, Holy" appears nowhere on the page** (only
  "All Glorious, All Holy," each word once) and nowhere in the deck (`Holy` occurs exactly twice, per
  the deck's own count, verified). Both previously-repaired errors stay repaired.
- **Muslim 2577a (probes on §5).** Fetched the exact cited capture
  (`web.archive.org/web/20260801213232id_/https://sunnah.com/muslim:2577a`, zstd-decoded). Full
  ḥadīth text matches the draft's quotations verbatim, including beats 3–4's exact clauses and the
  closing kneeling detail (*"Sa'id said that when Abu Idris Khaulini narrated this hadith he knelt
  upon his knees"*). **Narrator chain confirmed as Abū Dharr** (`عَنْ أَبِي ذَرٍّ`), matching the
  deck's own §11a cross-check against claim 87 (Ar-Rauf). Bare `muslim:2577` capture confirmed to be
  the same page, titled "Sahih Muslim 2577a." Neither page prints a grade line (confirmed: only UI
  checkbox labels reading "Grade" appear, no verdict text) — the disclosure is accurate.
- **Bar-4 `q-d-s` sweep, run fully independently (probe 8).** Assembled all 6,236 āyāt fresh, folded
  marks, tested the consonant subsequence ق-د-س word-by-word. **Result: exactly 10 hits — 2:30, 2:87,
  2:253, 5:21, 5:110, 16:102, 20:12, 59:23, 62:1, 79:16 — matching the draft's enumeration and
  classification exactly** (angels' declarative speech at 2:30; the Spirit at 2:87/2:253/5:110/16:102;
  a land/valley at 5:21/20:12/79:16; the Name itself, both appositive epithets in a Name-chain, at
  59:23/62:1). **The trade is forced; independently reconfirmed, not merely re-asserted.**
- **22:37/22:38/22:39 (probe 10) and the 22:36 antecedent** all fetched and match verbatim, including
  the exact omitted tail (*"...that you may glorify Allāh for that [to] which He has guided you; and
  give good tidings to the doers of good"*) and the disclosed n+2 (22:39, permission to fight — not
  quoted, correctly characterized as an argument rather than a 404).
- **Every specific number in this draft that I re-derived came back exact:** 734 rendered strings;
  zero 4-gram and zero 5-gram hits against the full corpus (recomputed independently — confirmed
  zero at both thresholds); 26 shared 4-grams between beats 3 and 4 (recomputed: exactly 26); the
  22-word identical opening run (recomputed: exactly 22 words, `were the first of you ... to be as`);
  the Arabic beats-3/4 differences (fetched and confirmed: `أَتْقَى`→`أَفْجَرِ`, `زَادَ`→`نَقَصَ`,
  `فِي`→`مِنْ`, and `مِنْكُمْ` present only in the first clause — all four, exactly as claimed); every
  disclosed hapax (`blood` n=1 `al-jabbar@1`, `reaches` n=1 `ar-razzaq@1`, `attribute`/`worship`/
  `remembrance` claims on the sibling deck all independently recount to n=1 exactly; `holy` n=0
  across the other 33 decks, confirmed).
- **Deck-internal diff:** the beat-3/beat-4 overlap is the only one, exactly as disclosed; no other
  pair exceeds threshold.

I found no fabricated, misnumbered, or misattributed citation in this deck, and no overstated
absolute that didn't survive re-derivation, with the single exception of probe 9 (ruled above,
inherited from `al-kareem@1`'s side of the comparison as much as this deck's).

### Blocking finding

**Probe 9, above: beat 8 collides with `al-kareem@1` beat 8 in the move. Requires a new beat 8.**

---

## What my own method could not determine

1. **No isnād was audited on any ḥadīth in either deck** — same standing limit the project has
   carried since the pilot. I confirmed pages resolve and read as claimed; I did not evaluate chain
   authenticity independently of what sunnah.com prints.
2. **Muslim 2577b and 2577c were not independently fetched.** I did not verify the claim that they are
   "different chains" of the same ḥadīth; I only confirmed that the cited 2577a capture is genuine and
   that the bare `muslim:2577` route resolves to the same 2577a page.
3. **`.context/claims/*.md` contents were not independently read** — I could not confirm the
   deck's claims about claim files 8, 24, 25, 45, 87, 61, 14, 10, 93, 57 without opening each; I
   treated citations of already-ledger-verified shipped-deck facts (e.g. `al-haqq@1`'s bar-5 ruling
   at ledger §9aa, `al-mughni@1`'s bar-5 acceptance) as given rather than re-litigating shipped-deck
   history, which is out of scope for a wave-2 verification of two new decks.
4. **The successor sweep past 20:21 (`allah@1`) and the ḥadīth corpus beyond the Qurʾān (`q-d-s` on
   `al-quddus@1`) were not extended past what the drafts themselves disclose as their own limits** —
   I did not independently re-derive a hadith-corpus `q-d-s` sweep; I accept the draft's own stated
   limit there as honestly disclosed.
5. **No page beyond sunnah.com/Wayback and api.quran.com was consulted** — same corpus-independence
   limit as the pilot and both prior batches. No printed edition, Shamela, or Dorar was reached.
6. **I did not re-verify shipped-deck (the other 33) internal accuracy** — only their rendered text
   as it exists today in `name_stories.json`, which is the correct surface for a bar-3 sweep and is
   what a user actually sees.

---

## Summary

| deck | verdict | blocking findings |
|---|---|---|
| `allah@1` | **FIX-THEN-SIGN** | §7/§12 duʿā-provenance disclosure is factually false (Mishkat 2452 IS reachable and IS a splice-match; conclusion survives, reasoning must be rewritten) |
| `al-quddus@1` | **FIX-THEN-SIGN** | Beat 8 collides with shipped `al-kareem@1` beat 8 in the move (probe 9, ruled blocking); needs a new beat 8 built from the unspent beat-2 kneeling detail |

Non-blocking, should still be corrected before transcription: `allah@1` §5's "guide renders in 6
decks" should read "6 occurrences across 3 decks" (§9ak).

Ruled, as requested: the tawḥīd-formula standing question in `allah@1` §9b.2 is **NOT BLOCKING**
(§9o's formulaic/creedal-formula exemption applies; will recur on Al-Hayy/Al-Ahad/Al-Wahid and should
be handled the same way each time).
