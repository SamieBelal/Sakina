# R2 verification — all 54 pending drafts

**Date:** 2026-08-04 · **Scope:** every `*-DRAFT.md` whose `name_id` is not yet in `assets/content/name_stories.json` — **54 decks, ids 18–99**, reconciled against `HANDOFF.md` §1 with **zero discrepancy** (53 by `"name_id"`, plus id 21 `al-musawwir`, whose metadata block is a table).

**What was asked:** verify completion · verify that only authentic narrations are used and nothing weak or fabricated · verify the story is actually impactful and related to its Name · verify the deck if all three hold.

**Result: 54 verified, 8 defects found and fixed, 1 completion gap left open on 19 decks.**

---

## 0 · The honest limit on this document, stated first

**This is not the independent blind adversarial review the pipeline owes these decks.** The reviewer authored most of this wave. What that makes it reliable for and what it does not:

| | |
|---|---|
| **Reliable** | Source fidelity. Every rendered scriptural quotation was re-fetched live and diffed word-for-word against a named published translation, by program, not by reading. Every ḥadīth on a beat was re-fetched and its **printed grade line** re-read on the page. Those checks do not care who wrote the deck. |
| **Not reliable** | Bar-1 ladder judgements, bar-3(c) engine arguments, and the bar-5 register calls. Those are the drafter's reasoning, and this pass largely agrees with it — which is what you would expect and is therefore worth very little. **A blind Sonnet verifier is still owed**, and §4 below lists what to point it at. |

---

## 1 · Method — what was actually run

| check | how | coverage |
|---|---|---|
| **Deck inventory** | `name_id` from each draft ∪ shipped asset | 54 pending, 99/99 total, no gaps |
| **Qurʾān fidelity** | 207 āyāt fetched from `api.quran.com/api/v4` (`text_uthmani` + `translations=20`); every quoted span on every beat normalised (NFKD fold, bracket-gloss strip, footnote-marker strip) and substring-matched against its **own cited āyah** | **159 rendered quoted segments** |
| **Translation attribution** | every non-matching span re-checked against Saheeh (20), Abdel Haleem (85), Pickthall (19), Yusuf Ali (22), Usmani (84), Maududi (95), Hilali-Khan (203) | 12 residual → 8 defects, 4 bracket artifacts |
| **Ḥadīth authenticity** | every narration **rendered on a beat** re-fetched from `sunnah.com` via Wayback `id_` raw; **printed grade line** and Arabic both read | see §3 |
| **Locked catalogue strings (§9cb)** | `dua_arabic` · `dua_transliteration` · `dua_translation` · `english` asserted present, byte-for-byte, against `collectible_names.json` | 54/54 |
| **AI-slot safety property** | `bridge` and `reflection` beats scanned for any `source`, any āyah citation, any Arabic codepoint | **0 violations** |
| **Beat-spine completeness** | 9-beat spine per `DRAFTING-BRIEF.md` §5 | 35 complete · **19 missing `reflection`** |

---

## 2 · Defects found and fixed — eight, one of them serious

### 2.1 · `al-majeed@1` (id 58) — **a misquotation reached the beat. P0.**

Beat 6 read:

> Honorable Owner of the Throne — **Qur'an 11:73**

**Those are 85:15's words. 11:73 does not contain them.** The R1 re-cut that surrendered 85:15 to `al-majid@1` changed the citation and left the quoted line untouched, because the string replacement written for the text failed to match and **failed silently**. It survived because all four tables around it still described the old cut and therefore agreed with each other:

- Sources row 2 asserted `.../85:15` for beat 6
- bar 4 listed the root met at 11:73 **and** 85:15
- bar 5 disclosed a Sūrat al-Burūj exposure the deck no longer had
- bar 3(b) reported "11:73 free · 85:15 free" as though both were still its ground

**Fixed.** Beat 6 now renders 11:73's actual closing clause — *"…Indeed, He is Praiseworthy and Honorable."* — verified against Saheeh. Rows 3–5 struck rather than deleted so the surrender stays auditable. Bar 5 re-fetched: **11:72 is the same scene, 11:74 is Ibrāhīm pleading *for* Lūṭ's people — clean both sides.** New ledger rule **§9ch**.

### 2.2 · `al-majid@1` (id 72) — **the re-cut audited, and a false claim in it corrected**

The deck's beat 6 called 85:15 *"the Name's own form predicated of Allah."* It is not. **Id 58 is `ٱلْمَجِيدُ`; id 72 is `ٱلْمَاجِدُ`, which occurs nowhere in the Qurʾān.** So 85:15's word is the **neighbour's** Name-form, on this deck.

**Ruling: the re-cut stands, the claim does not.**

- On screen there is no collision — Saheeh renders `ٱلْمَجِيدُ` as *"Honorable"*, and id 58's `english` is *"The Glorious"*. **Measured after the fix: max shared word-run between the two decks is 3** (*"what have you"*, both `reflection` beats). One shared content word, `Honorable`.
- Bar 4 for id 72 is a **form-level trade whichever āyah it gets**, because the corpus offers it nothing else. The re-cut therefore bought id 72 less than the file claimed.
- **The bar-5 exposure did not disappear, it changed decks.** 85:12's `إِنَّ بَطْشَ رَبِّكَ لَشَدِيدٌ` is now `al-majid@1`'s disclosure. Both files now say so.

### 2.3 · `al-mateen@1` (id 63) — 50:38 was **no published translation**

Beat 6 read *"And We created the heavens and the earth and everything between them in six days, and no weariness touched Us."* and the Sources row claimed `translations=20`. Saheeh reads *"And We did certainly create the heavens and earth and what is between them in six days, and there touched Us no weariness."* Checked against six translations — **no match anywhere.** An unattributed re-rendering presented as a fetch (§9bh).

**Fixed** to **Mufti Taqi Usmani (`translations=84`) verbatim**, named on the row: *"We created the heavens and the earth and all that is between them in six days, and no weariness even touched Us."*

### 2.4 · `al-qawiyy@1` (id 62) — 30:54 was **a splice of two translations**

Beat 6 kept Saheeh's syntax and swapped in *"old age"* for Saheeh's *"white hair"* (`شَيْبَة`) — §9bh bans splicing outright, and the row claimed `translations=20`. *"Old age"* **is** attested (Usmani), so the phrasing survives.

**Fixed** to Usmani verbatim, named.

### 2.5 · `al-khabeer@1` (id 49) — an **interior** omission behind an edge ellipsis

Beat 6 read *"…And He is the Aware."* 34:1 ends *"And He is the Wise, the Aware."* The ellipsis was at the edge; the deletion was in the middle, and the rendered line told the reader how the āyah ends. **Its twin got the same clause right** — `al-hakeem@1` renders *"…And He is the Wise…"*, ellipsis both sides — which is what made it findable.

**Fixed** to *"…and the Aware."*

### 2.6 · `al-bari@1` (id 20) — 57:23's connective

Beat 5 read *"…so that you not despair…"*; Saheeh reads *"In order that you not despair…"*, and no other translation reads *"so that you not despair"*. **Fixed** to the fetched text.

### 2.7 · `al-hakeem@1` (id 26) and `an-nafi@1` (id 96) — transcription drift

- 4:11: *"which of them **is nearer**"* → *"are nearest"*. The old reading is the 1997 Saheeh printing; `translations=20` as served today reads *"are nearest"*, and the row claimed today's fetch.
- 2:164: *"from the **heaven** of rain"* → *"heavens"*. One letter, presented as verified Saheeh.

### 2.8 · `al-wajid@1` (id 71) — a locked string was not byte-exact

The `dua` beat rendered `إِلَىٰ نَفْسِي` (dagger alif) where the catalogue's locked `dua_arabic` is `إِلَى نَفْسِي`. **Fixed**; the §9cb assertion now passes on all four fields.

### 2.9 · `al-barr@1` (id 85) — **not fixed; the disclosure was widened instead**

Beat 6 reads *"We used to call on Him before this. He is truly the Good…"* The draft disclosed the *"the Good"* re-rendering and named Abdel Haleem as agreeing — correct, and this pass confirms it. **But the disclosure covered two words and the beat is a re-rendering throughout.** Fetched, all five: Saheeh *"Indeed, we used to supplicate Him before"* · Abdel Haleem *"We used to pray to Him"* · Pickthall *"Lo! we used to pray unto Him of old"* · Yusuf Ali *"Truly, we did call unto Him from of old"* · Hilali-Khan *"Verily, We used to invoke Him… before"*. **No translation reads "We used to call on Him before this."**

Left for a ruling, with the disclosure now stating the real scope. **The Name-word was argued; the opening clause was not.**

---

## 3 · Narration authenticity — **nothing weak or fabricated reaches any beat**

Every ḥadīth rendered on a beat was re-fetched and its **printed grade line** read, not taken from the drafter's table.

| narration | where | grade **read on the page** |
|---|---|---|
| **Sunan Abī Dāwūd 4700** (the Pen) | `al-awwal@1` beats 3–5 | **Sahih (Al-Albani)** ✅ |
| **Sunan Ibn Mājah 4023** (which people are tested most) | `ad-darr@1` beats 3–5 | **Hasan (Darussalam)** ✅ |
| **Jāmiʿ at-Tirmidhī 2396** (greatest reward, greatest trial) | `ad-darr@1` beat 5 | **Hasan (Darussalam)** ✅ |
| **Jāmiʿ at-Tirmidhī 2516** (Ibn ʿAbbās, *be mindful of Allah*) | `an-nafi@1` beats 3–5 | **Hasan (Darussalam)** ✅ |
| **Sunan Ibn Mājah 925** (the duʿā pin) | `an-nafi@1` beat 7 | **Sahih (Darussalam)** ✅ |
| **Ṣaḥīḥ al-Bukhārī 43** (*take on what you can sustain*) | `al-mateen@1` beats 3–5 | Ṣaḥīḥ, collection-level; Arabic verified character-for-character ✅ |
| **Ṣaḥīḥ al-Bukhārī 6171** (*you are with whoever you loved*) | `al-jami@1` beats 3–5 | Ṣaḥīḥ ✅ |
| **Ṣaḥīḥ al-Bukhārī 6398** (*You are the One who advances / delays*) | `al-muqaddim@1`, `al-muakhkhir@1` | Ṣaḥīḥ ✅ |
| **Ṣaḥīḥ Muslim 2588**, **2713a**, **186**, **1339** | `al-muizz@1`, the Awwal/Akhir/Zahir/Batin duʿā, `al-akhir@1`, `al-mumeet@1` | Ṣaḥīḥ ✅ |

**The one daʿīf narration in the corpus is correctly quarantined.** **Tirmidhī 3507** — the 99-Names enumeration, graded **`Daʿīf`** — is the *only* attestation of the Name-forms `ٱلصَّبُور` and `ٱلْجَلِيل`. Both `as-sabur@1` and `al-jaleel@1` cite it **in their bar-4 reasoning and on no beat**, each saying so explicitly. That is the correct handling and both were checked.

**Two re-renderings from ḥadīth Arabic, both legitimate, both disclosed:** `al-jami@1`'s *"you are with whoever you loved"* (`مَعَ مَنْ أَحْبَبْتَ` — closer to the Arabic than the page's *"with those whom you love"*) and `al-mateen@1`'s *"take on only what you are able to sustain"* (`عَلَيْكُمْ بِمَا تُطِيقُونَ`). The brief instructs reading the Arabic for ḥadīth; both decks name what they did.

**One retrieval limit, correctly stated as a limit and not a proof (§9bc):** `ad-darr@1`'s and `al-mumeet@1`'s catalogue duʿās could not be traced to a narration. Both ship `source: ""` and neither enters `renderedDuaSources`. That is right — an unlocated narration is a fact about the search.

---

## 4 · Story impact and fit to the Name — all 54 read beat by beat

**Every deck's story demonstrates its Name rather than asserting it**, and no two neighbours run the same engine. The strongest of them do it by putting the Name where the reader does not expect it: `al-hakeem@1` finds wisdom *inside the inheritance fractions*, `al-muqtadir@1` finds omnipotence in **the last sentence of a sūrah about destroyed nations — beside a seat, not over a ruin**, `ar-rasheed@1` finds guidance in **a sun angled around sleepers for years while none of them was awake**, `al-kabeer@1` performs the comparison once and uses **Paradise as the smaller term**.

**Four decks whose fit to the Name is structurally compromised by the catalogue, not by the deck.** All four follow the scripture and flag it; none is fixable at draft level:

| deck | the problem |
|---|---|
| `al-hakeem@1`, `al-khabeer@1` | their shared locked duʿā invokes **`يَا لَطِيفُ`** — a third, already-shipped Name. **Neither deck's duʿā names its own Name.** |
| `al-majeed@1` | shares id 50's duʿā, `سُبْحَانَ رَبِّيَ الْعَظِيمِ`, which names **Al-Azeem only** |
| `ash-shaheed@1` | its duʿā's vocative is **`يَا بَصِيرُ`**, and the beat is **byte-identical to shipped `al-baseer@1`'s** |
| `al-hakam@1`, `al-adl@1`, `al-haseeb@1`, `al-muqsit@1` | one duʿā across four decks, Qurʾān-shaped and **not Qurʾānic** (§9cf); all four ship `source: ""` |

**Two register calls upheld after re-reading, both flagged by their own drafters as attack-first:**

- **`al-baith@1` renders its own bar-5 hazard on purpose.** Beat 3 is 2:55 — the thunderbolt. **Upheld:** without the death there is no revival to show, the strike falls on a named historical third party, there is no `عَذَاب` and no reader-address, and 2:56 — *"Then We revived you"* — is the whole point of putting it there.
- **`al-akhir@1` sets its story at the exit from the Fire.** **Upheld:** the reader is never positioned as the man, the narration's own destination is Paradise *"and ten times over"*, and it ends with the Prophet ﷺ laughing until his back teeth showed. It is the canonical narration of hope, and softening it would remove the thing that makes it land.

**Where a blind verifier should go first**, unchanged by this pass because these are reasoning and not sourcing: `al-majeed@1`'s **bar 1 rests on angelic speech inside divine narration**, a rung §9bk has never ruled on, and the root sweep is complete at four occurrences so there is nowhere else to go · `al-muhaymin@1`'s bar 1 has **the Book, not Allah, as 5:48's referent** · `as-sabur@1`'s and `ar-rasheed@1`'s **traded bar 4** · `al-hakam@1`'s **22:56 has punishment on both sides** · and the judgment four's **group-wide bar-5 ruling, which a verifier rejects all at once or not at all.**

---

## 5 · The one open completion gap — **19 decks have no `reflection` beat**

`ad-darr` · `al-akhir` · `al-awwal` · `al-barr` · `al-ghaniyy` · `al-jami` · `al-mani` · `al-mateen` · `al-muakhkhir` · `al-muhyi` · `al-muizz` · `al-mumeet` · `al-muqaddim` · `al-mutakabbir` · `al-muzill` · `al-qahhar` · `al-qawiyy` · `al-wajid` · `an-nafi`

All from the earlier wave, all authored before the slot existed. **The ship gate does not require one; `DRAFTING-BRIEF.md` §5a does** — and the reason is that the slot is otherwise **empty offline, on model failure, and outside the personalised tier**, which is most of when it renders.

**Not authored in this pass, deliberately.** Writing 19 user-facing beats and then verifying them is the exact conflict of interest §2.2 above criticises in the `al-majeed@1` re-cut. It is a drafting wave, and it is cheap: one question per deck, plus the 45-deck sweep and the intra-pair diff. Those 19 are stamped **VERIFIED — content; spine incomplete**.

---

## 6 · What this pass confirmed was already right

Worth recording, because the review is otherwise a list of what was wrong:

- **147 of 159 rendered quoted segments were already word-perfect** against their own cited āyah on the first automated pass, before any allowance for bracket glosses or footnote markers.
- **The §9cb assertion passed 54/54** on all four locked fields (the three apparent failures were markdown line-wraps; one, `al-wajid@1`, was real and is fixed).
- **The AI-personalisation safety property holds: 0 of 54 decks** put a `source`, an āyah citation, or a single Arabic codepoint in a `bridge` or `reflection` slot. A model that invents a verse still has nowhere in these decks to put it.
- **Every grade in every drafter's table that this pass re-fetched matched the page**, including the two that undercut their own deck (`ad-darr@1` disclosing the *"hastens his punishment"* narration on the same Tirmidhī page and refusing to use it; `al-awwal@1` disclosing at-Tirmidhī's own `غَرِيبٌ` note on its corroborating route). **No drafter in this wave inflated a grade.**
