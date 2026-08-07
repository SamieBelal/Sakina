# Wave 2 Verdict — Al-Khafid (id 41) / Ar-Rafiʿ (id 42)

**Independent adversarial verifier.** Blind to the drafts' own ✅ tables — every claim below was
re-derived from a primary fetch or a script run by me, not read off the drafts' verification tables.
Method: `api.quran.com/api/v4`, Wayback captures of bare `sunnah.com/<collection>:<n>` URLs (fetched
directly, HTML parsed for the Arabic `matn`), and Python scripts run against
`assets/content/name_stories.json` and `assets/content/collectible_names.json`, plus a from-scratch
root sweep over the full 6,236-āyah Uthmānī text (`quran/verses/uthmani`).

---

## THE CALL THAT MATTERS MOST — reverence ruling on `al-khafid@1`

**Ruling: HOLDS. Does not accuse.** Read straight through as a user at 11pm after a bad week:

- Beat 1 validates the pain without moralizing it (*"the part that stings is how much it stings"*)
  and immediately universalizes it (*"to people you would not expect it from"*) — the opposite move
  from "you had this coming."
- Beats 3–5 never narrate Allah lowering a **person**. The narration's emotional center is a
  **communal** reaction (the Companions, collectively, about a camel race) that the Prophet ﷺ
  neither confirms nor shames — he reframes it as a **law about things** (`شَىْءٌ مِنَ الدُّنْيَا`),
  not a verdict about the people feeling it.
- Beat 7's duʿā redirects "lowering" onto something the user asks for **about themselves, on their
  own initiative** (*lower my arrogance*) — paired in the same breath with a raising *"with You."*
  Structurally this is the deck refusing to let Allah be grammatical subject of a person's abasement
  anywhere a user's eyes land.
- I independently re-derived the design choice that makes this possible: **Allah is the finite
  subject of a `kh-f-ḍ` verb in zero out of 6,236 āyāt** (script output below) — so the deck could
  not have quoted scripture doing the thing a user would fear even if it wanted to. That is a
  genuine structural safety, not merely a drafting choice.

**One dependency I would not have caught without reading it as a whole document twice:** beat 8's
final clause — *"Ar-Rafi — the second Name of your answer — is the Name for the one place where
being raised is not on loan"* — **makes a promise to a Name the user has not been shown** if this
deck ships alone. That is not a reverence failure by itself, but it is a second, independent
argument (beyond the collision findings) for why this deck cannot stand alone as written: shipped
solo, its own last sentence is a dangling reference.

**Verdict: reverence PASSES. It holds.**

---

## Pairing verdict — independently re-derived, not read off the draft

**I agree: Al-Khafid must not ship solo; if both ship, Al-Khafid is Name₁.** Independently confirmed:

1. **Catalogue collision is real, not asserted.** Fetched `collectible_names.json` directly:
   - id 41 `dua_arabic`: `يَا خَافِضُ اخْفِضْ كِبْرِيَائِي وَارْفَعْ قَدْرِي عِنْدَكَ` — contains
     `وَارْفَعْ`, the twin's root, in Arabic. **Confirmed.**
   - id 41 `dua_translation`: *"O Abaser, lower my arrogance and **raise my rank with You**."*
     id 42 `dua_translation`: *"O Exalter, **raise my rank with You** and grant me a standing…"*
     **Byte-identical 5-word run confirmed** by direct string comparison.
2. **Ad-Darr precedent confirmed.** `COLLISION-LEDGER.md` §7a.1: *"Ad-Darr (id 95) will be paired
   with An-Nāfiʿ (id 96) and never shipped solo. Founder decision, recorded."* Real, and I also
   independently confirmed id 95's own duʿā (`وَرَفْعًا لِدَرَجَاتِي`) carries `r-f-ʿ` **and**
   `d-r-j` — the same shape the drafts flag.
3. **The enforcement gap is real, with one correction to how the draft states it** (below).

**Verdict: SOLO SHIP REJECTED, PAIR-ONLY ACCEPTED.** Al-Khafid as Name₁, Ar-Rafiʿ as Name₂.

---

## Per-deck verdicts

### `al-khafid@1` — **FIX-THEN-SIGN**

**Scripture authenticity: 100% clean.** Every citation I attempted to independently verify checked
out exactly, including chapter/book headings and grade lines:

| claim | my fetch | match |
|---|---|---|
| Bukhārī 2872 full matn (`نَاقَةٌ تُسَمَّى الْعَضْبَاءَ…` through `…إِلاَّ وَضَعَهُ`) | Wayback `20260207142914` | **exact, byte-for-byte**, incl. Ḥumayd's aside and the `طَوَّلَهُ مُوسَى…` cross-reference note |
| Bukhārī 2872 title/breadcrumb | same page | `<title>… Fighting for the Cause of Allah (Jihaad) - كتاب الجهاد والسير …` — **the "Book of Jihād" disclosure is real** |
| Abū Dāwūd 4802 (`حَقٌّ عَلَى اللَّهِ عَزَّ وَجَلَّ أَنْ لاَ يَرْفَعَ شَيْئًا…`), Sahih (Al-Albani) | Wayback `20260411114222` | **exact**, incl. isnād `مُوسَى…حَمَّادٌ…ثَابِتٍ…أَنَسٍ` — **is** Bukhārī's cross-referenced route, confirmed |
| Nasāʾī 3588, Sahih (Darussalam), incl. the un-rendered Companions' line | Wayback `20260411203617` | **exact** |
| Bukhārī 7411 (`يَخْفِضُ وَيَرْفَعُ`, `يَدُ اللَّهِ مَلأَى…`) | Wayback `20251216215745` | **exact** — correctly rejected, and correctly identified as the single strongest bar-1+bar-4 text available |
| Muslim 2588 (`وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ`) | Wayback `20260419211856` | **exact** |
| Muslim 179 / 993 — claimed NOT VERIFIED | CDX query | **`[]` — confirmed no capture exists for either bare URL** |
| Qurʾān 28:81–84, 56:1–6, 15:88, 17:24, 26:215 | `api.quran.com/api/v4` | **exact on every field**, incl. Saheeh's *"exaltedness"* (deck swaps to Abdel Haleem's *"superiority"* for the disclosed reason) |

**Bar-1 root claim independently re-derived from scratch, not from the drafter's count.** I wrote my
own consonant-subsequence sweep over the full `quran/verses/uthmani` text (6,236 āyāt), normalizing
hamza/alif/tāʾ-marbūṭa variants:

```
kh-f-ḍ subsequence matches: 4
15:88  وَٱخْفِضْ
17:24  وَٱخْفِضْ
26:215 وَٱخْفِضْ
56:3   خَافِضَةٌ
```

**Exact match to the deck's claim of "4 occurrences, 2 word-forms," and I confirm the conclusion
independently: Allah is the finite subject of zero of them.** 56:3's `خَافِضَةٌ` is a feminine
participle whose subject (per 56:1's `إِذَا وَقَعَتِ ٱلْوَاقِعَةُ`, "when **the Occurrence**
occurs") is the Hour — confirmed by my own fetch of 56:1–3, matching the deck's ruling that **56:3
cannot carry bar 1.** Neither draft rests bar 1 on 56:3, which is the exact failure the brief asked
me to check for. **Neither deck makes that error.**

**Bar 1, asked strictly: MET, but on a weaker construction than its twin.** Bukhārī 2872's subject
attribution runs through `حَقٌّ عَلَى ٱللَّهِ … إِلَّا وَضَعَهُ` — Allah is subject of `وَضَعَهُ` by
the pronoun's antecedent, not by an adjacent noun-verb pair. This is a legitimate finite-verb
construction (I agree with the deck's own precedent citation to `al-mughni@1`'s `فَأَغْنَاكُمُ
ٱللَّهُ`), but it is measurably a step further from a bare subject-verb than Ar-Rafiʿ's `إِنَّ
ٱللَّهَ يَرْفَعُ`. **Not blocking — disclosed for the founder's own read.**

**Token-frequency and story-collision claims: verified near-exactly by independent script against
the live `name_stories.json`.** `camel` = 8 across `al-wadud@1`(5)/`al-mughni@1`(2)/`al-waliyy@1`(1)
— **exact match**. `above`=4, `outcome`=1 (hapax, `al-wakeel@1`), `lost`=5, `stopped`=2
(`al-qayyum@1`), `home`=3, `earth`=9 — **all exact matches** to the drafted counts and deck lists.
`al-jabbar@1`'s `name_intro` is confirmed byte-exact `"The Compeller — Restorer of the Broken"` and
its story does end `"Sight restored. Son restored. Whole again."` — the `grief`×4 count is **exact**
by my own script. The bar-3 separation argued against `al-jabbar@1` (mends vs. does-not-mend) holds
up under my own reading.

**One finding I could not confirm and rule the opposite way: the `(:284)` gate-behavior claim.**
The metadata warning states *"Beat 8 … 'synergy' … which the current gate rejects for any deck not
at position 1 (`:284`)."* I read `test/content/name_stories_ship_gate_test.dart:272–289` directly:

```dart
for (final chip in chipKeys) {                       // the 7-chip set only
  final forChip = decks.where((d) => (d['chip_keys'] as List).contains(chip));
  for (final d in forChip) { ... }                    // line 284's assertion lives HERE
}
```

A deck with `chip_keys: []` (exactly what this draft proposes) is **never a member of `forChip` for
any chip**, so the loop body — including line 284's `expect(synergyBeats, isEmpty, …)` — **never
executes for it at all**. **The gate does not reject a synergy label on a chipless deck; it never
evaluates one.** This is the opposite defect from what the draft states (silence, not rejection), and
it makes the deck's own headline point *stronger*, not weaker — there is even less enforcement than
claimed. **This is a factual correction to a specific, checkable code citation, and a founder
fact-checking `:284` would find the draft's framing backwards.** Non-blocking to the pairing
conclusion; blocking to signing the sentence as written.

**Second finding, shared with the twin (see below): 10 sibling decks are mislabeled "(drafted this
wave)."**

### `ar-rafi@1` — **FIX-THEN-SIGN**

**Scripture authenticity: 100% clean.**

| claim | my fetch | match |
|---|---|---|
| Muslim 817a full matn (`نَافِعَ بْنَ عَبْدِ الْحَارِثِ … إِنَّ ٱللَّهَ يَرْفَعُ بِهَذَا ٱلْكِتَابِ أَقْوَامًا وَيَضَعُ بِهِ آخَرِينَ`) | CDX confirms `20260511063600`; fetched | **exact**, incl. chapter heading `بَاب فَضْلِ مَنْ يَقُومُ بِالْقُرْآنِ…`, incl. no printed grade line (confirmed — "Grade" only appears in the report-error form widget) |
| Qurʾān 58:10–12, incl. head/tail elision on 58:11 | `api.quran.com/api/v4` | **exact**; the elided head (*"Space yourselves… Arise"*) is genuinely favorable content to the deck's own theme, so the elision-costs-the-deck disclosure is honest, not self-serving |
| Qurʾān 94:1, 94:4, 94:5, 94:8 real; **94:9 → HTTP 404** | direct fetch | **exact — confirmed 404**, i.e. Sūrat ash-Sharḥ genuinely ends at 8 āyāt, the strongest possible bar-5 form, as claimed |
| Qurʾān 40:15 `رَفِيعُ ٱلدَّرَجَـٰتِ` (bar-1 trap, correctly refused as a construct epithet) | direct fetch | **exact**, Saheeh renders it *"[He is] the Exalted above [all] degrees"* |

**Bar-4 root claim independently re-derived from scratch.** My own subsequence sweep over the full
Uthmānī text:

```
r-f-ʿ subsequence matches: 29, in 18 distinct normalized word-forms
```

**Exact match to the deck's claimed "29 occurrences in 18 word-forms."** This is the same method
the deck claims to use, run independently by me, landing on the identical two numbers — a strong
signal the enumeration is real rather than asserted. I confirm Allah is finite grammatical subject in
well over half of them (2:63, 2:93, 2:253, 3:55, 4:154, 4:158, 6:83, 6:165, 7:176, 12:76, 13:2,
19:57, 43:32, 55:7, 58:11, 79:28), so **bar 1 is met cleanly and is not a trade** — the stronger of
the pair's two bar-1 cases, as noted above.

**Token-frequency claims: verified exactly by independent script**, with one caveat. `exalted`=3
(`al-kareem@1`, `al-khaliq@1`, `al-mujeeb@1`), `book`=1 hapax (`al-ghafur@1`), `slaves`=1
(`ar-rahman@1`), `charge`=3, `valley`=5 (`al-baseer@1`×4, `al-mumin@1`×1), `believed`=6 across 4
decks, `earth`=9 across 6 decks — **all exact matches**, including the deck lists named.

**`umar`=2 claim: could not confirm as stated, and the reason is a real, disclosed-nowhere
typography gap.** `al-ghafur@1`'s shipped JSON literally renders **`ʿUmar`** (with the modifier-letter
ayin, U+02BF) twice. This draft's own beats render the Caliph's name as plain **`Umar`** (no ʿ) —
confirmed by grep on the raw draft markdown (lines 65, 67, 79). A strict token sweep on the *rendered*
strings therefore does not actually collide on the string `"umar"` the way the table implies (my
regex found 0 hits for exact-word `umar` project-wide before I understood why). **The underlying
disclosure — two different people named Umar, one a Companion narrator and one the Caliph — is still
correct and the ruling (non-blocking) still holds**, but the table asserts a string-level match that
the two decks' own typographic conventions do not actually produce on screen. Minor; worth a fix.

**Finding shared with the twin: 10 sibling decks mislabeled "(drafted this wave)."** I confirmed
against `name_stories.json`'s `review_verdict`/`reviewed_by`/`reviewed_at` fields that
`al-aleem@1`, `al-baqi@1`, `al-haqq@1`, `al-khaliq@1`, `al-malik@1`, `al-mughni@1`, `al-mumin@1`,
`al-wasi@1`, `an-nur@1`, `ar-raqeeb@1` are **all already `review_verdict: "good"`, `reviewed_by:
"founder"`, `reviewed_at: "2026-08-03"`** — i.e. **already shipped**, as part of the git-logged
"wave 1" batch (`9d08cab feat(decks): 24 become 34 — wave 1`) that closed *before* this draft began.
Both drafts label these decks "(drafted this wave)" in the bar-3 "the move" tables and the cross-wave
section, the same status class used for the genuinely-concurrent `al-qabid@1`/`al-basit@1` (claim
files 24/25, confirmed still unshipped). **This is a real status error**: it treats ten pieces of
locked, immutable content as if they were still-fluid siblings whose collision resolution might be
"reported to the coordinator" rather than judged final. It does not change any specific measured
collision ruling I checked (the underlying JSON content is what it is, shipped or not), but a founder
reading "(drafted this wave)" would reasonably infer these are still open for negotiation, which they
are not.

**Register / bar 5: clean, confirmed by my own fetch of 58:10 and 58:12** — no punishment, no
battle, no curse on either neighbor.

---

## Twin-diff — independently spot-checked, not re-derived in full

I hand-checked the deck's own claim that the two beat-5 quotations share **zero** 3-word run:

> A: *"Allah has bound Himself to this: nothing in this world is raised except that He lowers it."*
> B: *"Allah raises peoples by this Book, and sets others down by it."*

**Confirmed — no shared 3-gram.** I also confirm the disclosed Arabic overlap is real and not
minimized: Al-Khafid's quote carries `وَضَعَهُ` and Ar-Rafiʿ's carries `وَيَضَعُ`, same root `w-ḍ-ʿ`,
both predicated of Allah, both quoted in full rather than trimmed to hide it. **This is the one real
collision between the pair and both drafts state it at full strength rather than downplay it — I
have nothing to add to it.**

On the "one deck twice with the polarity flipped" test the brief asked me to run explicitly: **no.**
Different collections (Bukhārī vs. Muslim), different narrators (Anas vs. Nāfiʿ b. ʿAbd al-Ḥārith /
ʿUmar), different centuries (Prophetic lifetime vs. ʿUmar's caliphate), different protagonist class
(an animal/a collective feeling vs. a named man whose rank actually changes), different objects
(`شَىْءٌ مِنَ ٱلدُّنْيَا` vs. `أَقْوَامًا`/named peoples), and — most importantly for a reverence
read — **opposite treatment of whether a person is the one being acted upon** (Al-Khafid: nobody's
rank changes, the law is about "things"; Ar-Rafiʿ: a named man's rank visibly changes). I concur with
the twin-diff's own conclusion.

---

## Method limits (mine, not the drafts')

1. **Ḥadīth verification is not independent of sunnah.com as a corpus.** I fetched Wayback captures
   of sunnah.com pages, same as both drafts — no isnād audit, no printed edition, no Shamela/Dorar
   cross-check. If sunnah.com's own digitisation is wrong, my check inherits the error.
2. **My root sweep uses a consonant-subsequence method** (skip-allowed, not fixed-window), same class
   the drafts describe. It could over-match if a root's three letters appear as a coincidental
   subsequence in an unrelated word; I hand-reviewed every hit in both sweeps (33 total) and none
   were false positives, but I did not attempt to independently derive a more conservative method.
3. **I did not re-derive the full rejection tables** (Qārūn/Pharaoh/Iblīs class, 3:55/4:158, 6:83/
   12:76, etc.) — I fetched and confirmed the specific verses named in the headline argument and the
   ones the brief flagged by name (56:1–6, 28:81–84, 58:10–12, 94:1–9, 40:15, 15:88/17:24/26:215),
   and spot-checked the rest of the r-f-ʿ table only insofar as my own 29-item sweep reproduced it in
   full. I did not independently re-fetch every one of the ~20 other rejected candidates' surrounding
   āyāt.
4. **I did not run the full 28-pair deck-internal beat diff** for either deck — I spot-checked the
   one pairing the brief specifically named (beat 5 vs. beat 5, cross-deck) and the beat-8→beat-7
   twin-diff row, both by hand tokenization, not a script over all 28×28 pairs.
5. **I did not attempt to verify Muslim 817b** (the parallel-chain corroboration cited but rendered
   on no beat) beyond confirming a Wayback capture exists for it via CDX.

---

## Summary

| deck | verdict | reverence | pair-or-solo |
|---|---|---|---|
| `al-khafid@1` | **FIX-THEN-SIGN** | **HOLDS — does not accuse** | **must ship paired, Name₁** |
| `ar-rafi@1` | **FIX-THEN-SIGN** | not at issue (positive register); bar 5 independently confirmed clean | **can ship alone, but should not if Al-Khafid ships — must be Name₂** |

**Fixes required before sign, itemized:**
1. `al-khafid@1`'s metadata warning must correct the `(:284)` citation — the gate **skips**
   chipless decks rather than **rejecting** them; the practical conclusion (no enforcement exists) is
   unchanged and, if anything, strengthened.
2. Both drafts must relabel `al-aleem@1`, `al-baqi@1`, `al-haqq@1`, `al-khaliq@1`, `al-malik@1`,
   `al-mughni@1`, `al-mumin@1`, `al-wasi@1`, `an-nur@1`, `ar-raqeeb@1` from **"(drafted this wave)"**
   to **`[S]`** — confirmed already shipped (`review_verdict: "good"`, `reviewed_at: "2026-08-03"`,
   wave 1, which closed before this draft began). Only `al-qabid@1`/`al-basit@1` (ids 24/25) are
   genuinely concurrent.
3. `ar-rafi@1`'s `umar`-collision row should note the typographic non-match (`Umar` vs. `ʿUmar`)
   rather than imply an exact string collision that the two decks' own rendering conventions do not
   produce.

**No fabrication, no misattribution, no misgrading, no misquotation found in either deck** — every
citation I attempted to independently re-fetch matched byte-for-byte, including subtle details
(chapter headings, cross-referenced isnād chains, HTTP 404 as sūrah-final proof, and two from-scratch
root enumerations that reproduced the drafts' counts exactly). This is the cleanest authenticity
result I can construct from an adversarial pass; the three fixes above are all disclosure/citation
corrections, not scripture problems.
