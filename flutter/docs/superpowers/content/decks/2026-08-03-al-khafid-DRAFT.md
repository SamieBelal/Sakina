# Deck Draft — Al-Khafid (wave 2, catalogue id 41) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-ar-rafi-DRAFT.md`](./2026-08-03-ar-rafi-DRAFT.md).** Ids 41 and 42 were
assigned and drafted as a deliberate pair.

> ## ⚠️ THE HEADLINE FINDING, BEFORE THE DECK
>
> **This Name should ship only as half of the Khafid/Rafiʿ pair, and it should be Name₁.**
> This is **not** a rejection of the Name (ledger §7a.2 forbids that) and it is **not** a register
> preference. Four measurements force it, and each can be re-checked in seconds:
>
> 1. **`kh-f-ḍ` occurs 4 times in the entire Qurʾān, in 2 word-forms** — swept over the full
>    6,236-āyah Uthmānī text, not a search API (§9ac, §9af). Three are `وَٱخْفِضْ` (15:88, 17:24,
>    26:215): an **imperative to the Prophet ﷺ**, human actor, and the sense is *gentleness*
>    (*lower your wing*). The fourth is `خَافِضَةٌ` (56:3): a **feminine** active participle agreeing
>    with `ٱلْوَاقِعَة`. **Allah is the subject of a `kh-f-ḍ` verb in zero āyāt.**
> 2. **56:3 therefore cannot carry bar 1.** `خَافِضَةٌ رَّافِعَةٌ` describes **the Hour, not Allah** —
>    the brief's own caution, confirmed by the feminine agreement and by Saheeh's *"**It** will bring
>    down [some] and raise up [others]"*. This is the same grammatical test that awarded 4:130 to
>    Al-Mughni over Al-Wasi (§9a): bar 1 wants Allah as the **actor**, not the decree as instrument.
> 3. **Every ṣaḥīḥ route that does predicate the root of Allah is unusable** — the two I could reach
>    are itemised in the rejection table, and **two more could not be fetched at all** (see limits).
> 4. **The catalogue has already decided the pairing.** Id 41's `dua_arabic` renders **`وَارْفَعْ`** —
>    Ar-Rafiʿ's root, imperative — **in Arabic on this deck's own duʿā screen**, and its
>    `dua_translation` shares a **5-word byte-identical run with id 42's**: ***"raise my rank with
>    You"***. Both strings are gate-locked. **Al-Khafid cannot reach a screen without its twin's
>    action already on that screen.**
>
> **And the enforcement does not exist.** The ship gate's pair-synergy assertion
> (`name_stories_ship_gate_test.dart:272`) runs **only over the 7 `chipKeys`**; all 7 chips are full
> (14 decks) and **all 20 batch-1/2/wave-1 decks ship `chip_keys: []`, `position_in_pair: 0`**.
> `NameStoriesService.deckForName(nameId)` serves any deck standalone. **There is no mechanism today
> that would stop Al-Khafid being met alone — and the same is true of Aḍ-Ḍārr (95), which the founder
> has already decided must never ship solo (§7a.1).** That is an engineering finding, not a drafting
> one, and it is the reason this deck is drafted with `position_in_pair: 0` while asking for `1`.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full including §9–§9as.
Claim filed at `.context/claims/41.md` **before** drafting; `.context/claims/` **re-read immediately
before these verification tables** (§9s) — 8 new files had landed.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4`; ḥadīth via
Wayback captures of the exact bare `sunnah.com` number, `zstd -d`.
**Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-khafid@1` — Al-Khafid

**Why this deck exists, in one line:** the user who had something ahead and does not any more, and is
privately embarrassed by how much it hurts. **There is a ṣaḥīḥ narration in which exactly that
happened to the Companions — over a camel race — and the Prophet ﷺ did not tell them it would come
back. He told them what kind of thing it had been.**

**The register decision, made first and made explicitly.** This Name's failure mode is a person who
already feels low being handed *The Abaser* at 11pm. **So the deck never renders Allah lowering a
person.** The one text it quotes lowers **a thing** (`شَىْءٌ مِنَ الدُّنْيَا`), and the person in the
story is the one who is *comforted* by the lowering, not subjected to it. Every rejection in the
table below was made on that line, including the rejection of the Name's own strongest Qurʾānic
image (Qārūn, 28:81) and of its own root's clearest ḥadīth (Bukhārī 7411).

**Selection ran duʿā-first.** Catalogue id 41's duʿā is `اخْفِضْ كِبْرِيَائِي وَارْفَعْ قَدْرِي
عِنْدَكَ` — the thing asked to be lowered is **the petitioner's own pride**, and it is asked for in
the same sentence as a raising. **The catalogue's own duʿā refuses the solo reading of this Name**,
and that is where the pairing verdict started.

**Proposed metadata**

```json
{
  "deck_id": "al-khafid@1",
  "name_id": 41,
  "transliteration": "Al-Khafid",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

> ⚠️ **`position_in_pair: 0` is what the asset supports, not what this deck asks for.** Beat 8 is
> written as a **pair-synergy beat** and its `label` therefore contains *"synergy"*.
>
> ⚠️ **CORRECTION (verifier, post-R0): the citation below this line was BACKWARDS.** This warning
> originally read *"which the current gate rejects for any deck not at position 1 (`:284`)."* **It
> does not.** `test/content/name_stories_ship_gate_test.dart:272–289`:
> ```dart
> for (final chip in chipKeys) {                       // the 7-chip set only
>   final forChip = decks.where((d) => (d['chip_keys'] as List).contains(chip));
>   for (final d in forChip) { ... }                    // line 284's assertion lives HERE
> }
> ```
> That loop runs **only over the 7 `chipKeys`.** A `chip_keys: []` deck — exactly what this draft
> proposes — is **never a member of `forChip` for any chip**, so the loop body, including line 284's
> `synergyBeats` assertion, **never executes for it at all.** **The gate does not reject a synergy
> label on a chipless deck; it never evaluates one.** This is the opposite defect from what was
> originally claimed here (silence, not rejection) — **and it makes this deck's own "no enforcement
> exists" argument stronger, not weaker: there is even less enforcement than the original wording
> implied.** A founder fact-checking `:284` against the original framing would have found it wrong.
>
> **This reopens a gap that is bigger than one deck.** Three Name-pairs in this project now carry a
> "must be met together" ruling — **Aḍ-Ḍārr/An-Nāfiʿ (ledger §7a.1), Al-Qābiḍ/Al-Bāsiṭ (ids 24/25),
> and Al-Khafid/Ar-Rafiʿ (this pair)** — and **nothing in the code enforces any of them.** Either
> these pairs need `chip_keys` so the existing pair-synergy machinery (the loop above) applies to
> them, or a new constraint (e.g. a bidirectional `requires_deck` field) is needed. **That is an
> engineering decision for the founder; this draft recommends nothing beyond flagging that it is now
> unsettled for three pairs, not one.**
>
> Shipping this deck as written requires either a new chip, or a gate change, or dropping the word
> *synergy* from the label while keeping the line. **Founder + engineering decision. Do not
> transcribe this deck without settling it.**

**Beat 1 · bridge:**
> Something you had was above, and it isn't now — and the part that stings is how much it stings. That happened once over a race, to people you would not expect it from.

**Beat 2 · name_intro** *(catalogue id 41 `english` verbatim + an authored gloss — see the gloss note)*:
> الْخَافِضُ — Al-Khafid — The Abaser — the One who brings down whatever rises

**Beats 3–5 · story — "The race al-Adba lost":**
> 3. The Prophet ﷺ had a she-camel called al-Adba, and she was not outstripped. (Humaid, who passed the report on, said: **or hardly ever outstripped.**)
> 4. A bedouin came on a young camel, and outstripped her.
> 5. It weighed on the Muslims, until he saw it in them. He said: **"Allah has bound Himself to this: nothing in this world is raised except that He lowers it."**

**Beat 6 · verse:**
> "That home of the Hereafter We assign to those who do not desire superiority upon the earth or corruption. And the [best] outcome is for the righteous." — Qur'an 28:83

**Beat 7 · duʿā** *(catalog id 41, verbatim in full)*:
> يَا خَافِضُ اخْفِضْ كِبْرِيَائِي وَارْفَعْ قَدْرِي عِنْدَكَ
> *Ya Khafid, ikhfid kibriya'i warfa' qadri 'indak*
> "O Abaser, lower my arrogance and raise my rank with You."
> **NO source. This deck must not be pinned** — see the ship-gate note.

**Beat 8 · takeaway (pair-synergy):**
> They were not upset about a camel. Something of theirs had been above, and had stopped being above. Al-Khafid is the Name for how long anything here stays up. Ar-Rafi — the second Name of your answer — is the Name for the one place where being raised is not on loan.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched URL / API key) | Grading | Status |
|---|---|---|---|---|
| 1 | The Prophet ﷺ had a she-camel called al-ʿAḍbāʾ; she was not outstripped (beat 3) | `sunnah.com/bukhari:2872` — Wayback capture `20260207142914`, `id_` raw | **ṣaḥīḥ** (Ṣaḥīḥ al-Bukhārī; collection-level — the page prints **no grade line**, §9ag) | ✅ `كَانَ لِلنَّبِيِّ صلى الله عليه وسلم نَاقَةٌ تُسَمَّى الْعَضْبَاءَ لاَ تُسْبَقُ` |
| 2 | Ḥumayd's own qualification — *"or hardly ever outstripped"* (beat 3, **attributed to him by name**) | same page | ṣaḥīḥ | ✅ `قَالَ حُمَيْدٌ أَوْ لاَ تَكَادُ تُسْبَقُ`. **Kept rather than smoothed away** — it is the sub-narrator hedging inside the text, and dropping it would harden a claim the narration itself softens |
| 3 | A bedouin came on a young camel and outstripped her (beat 4) | same page | ṣaḥīḥ | ✅ `فَجَاءَ أَعْرَابِيٌّ عَلَى قَعُودٍ فَسَبَقَهَا` |
| 4 | It weighed on the Muslims, until he saw it in them (beat 5) | same page | ṣaḥīḥ | ✅ `فَشَقَّ ذَلِكَ عَلَى الْمُسْلِمِينَ، حَتَّى عَرَفَهُ` |
| 5 | **"Allah has bound Himself to this: nothing in this world is raised except that He lowers it."** (beat 5) — **bar 1's only carrier** | same page | ṣaḥīḥ | ✅ `حَقٌّ عَلَى اللَّهِ أَنْ لاَ يَرْتَفِعَ شَىْءٌ مِنَ الدُّنْيَا إِلاَّ وَضَعَهُ` — **quoted whole, no elision.** Rendering itemised below |
| 6 | Bukhārī's own page points at a longer route | same page | — | ✅ `طَوَّلَهُ مُوسَى عَنْ حَمَّادٍ عَنْ ثَابِتٍ عَنْ أَنَسٍ` — **that chain is exactly Abū Dāwūd 4802's** (row 7). Bukhārī cross-referencing the corroborating route is unusually good provenance and is recorded rather than assumed |
| 7 | Corroborating route, **quoted on no beat** | `sunnah.com/abudawud:4802` — Wayback `20260411114222` | **Sahih (Al-Albani)** — grade line printed on the page | ✅ `حَقٌّ عَلَى اللَّهِ عَزَّ وَجَلَّ أَنْ لاَ يَرْفَعَ شَيْئًا مِنَ الدُّنْيَا إِلاَّ وَضَعَهُ`. ⚠️ **This route makes Allah the subject of BOTH verbs** (`يَرْفَعَ` transitive), where Bukhārī's has `يَرْتَفِعَ` (Form VIII, subject = *a thing*). **Bar 1 is met on either; the deck quotes Bukhārī's** |
| 8 | Corroborating route, **quoted on no beat** | `sunnah.com/nasai:3588` — Wayback `20260411203617` | **Sahih (Darussalam)** — grade line printed | ✅ `إِنَّ حَقًّا عَلَى اللَّهِ أَنْ لاَ يَرْتَفِعَ مِنَ الدُّنْيَا شَىْءٌ إِلاَّ وَضَعَهُ`. It also carries the Companions' spoken line — *"O Messenger of Allah, al-ʿAḍbāʾ has been beaten"* — **which is deliberately NOT used**, to keep the deck single-source rather than a two-collection splice |
| 9 | **"That home of the Hereafter We assign to those who do not desire superiority upon the earth or corruption. And the [best] outcome is for the righteous."** (beat 6) | `api.quran.com/api/v4/verses/by_key/28:83?fields=text_uthmani&translations=20,85` | Qurʾān | ✅ `تِلْكَ ٱلدَّارُ ٱلْـَٔاخِرَةُ نَجْعَلُهَا لِلَّذِينَ لَا يُرِيدُونَ عُلُوًّا فِى ٱلْأَرْضِ وَلَا فَسَادًا ۚ وَٱلْعَـٰقِبَةُ لِلْمُتَّقِينَ` — **quoted whole, no ellipsis.** One word changed from Saheeh; itemised below |
| 10 | Successor sweep n−1, n−2 | `verses/by_key/28:82`, `28:81` | Qurʾān | ✅ fetched, quoted nowhere. **28:81 is Qārūn's destruction.** Disclosed at full strength below |
| 11 | Successor sweep n+1 | `verses/by_key/28:84` | Qurʾān | ✅ fetched, quoted nowhere, verdict below |
| 12 | The `kh-f-ḍ` enumeration this deck's bar-4 trade rests on | full 6,236-āyah Uthmānī text, `api.quran.com/api/v4/quran/verses/uthmani`, combining marks folded, alif/yāʾ/tāʾ-marbūṭa normalised, consonant-subsequence match, hand-classified | — | ✅ **4 occurrences, 2 word-forms: `وَٱخْفِضْ` at 15:88, 17:24, 26:215; `خَافِضَةٌ` at 56:3.** Full text, not a search API |
| 13 | 56:3's subject is `ٱلْوَاقِعَة`, not Allah | `verses/by_key/56:1`, `56:2`, `56:3`, `56:4`, `56:5`, `56:6` | Qurʾān | ✅ feminine participles; Saheeh *"**It** will bring down [some] and raise up [others]"*; 56:4–6 is the earth convulsed and the mountains crumbled to dust |
| 14 | Ṣaḥīḥ al-Bukhārī 7411 fetched and **rejected** | `sunnah.com/bukhari:7411` — Wayback capture | ṣaḥīḥ | ✅ `وَبِيَدِهِ الأُخْرَى الْمِيزَانُ يَخْفِضُ وَيَرْفَعُ` — real, and the Name's own root with Allah as subject. **Two reasons for rejection below** |
| 15 | Ṣaḥīḥ Muslim 2588 fetched and **rejected** as a spine | `sunnah.com/muslim:2588` — Wayback capture | ṣaḥīḥ | ✅ `وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ` — **this is the source of the card `hadith` on both id 41 and id 42.** See the catalogue finding |
| 16 | Ṣaḥīḥ Muslim 179 and 993 | `sunnah.com/muslim:179`, `sunnah.com/muslim:993` | — | ❌ **NOT VERIFIED. No Wayback capture exists for either bare-number URL.** CDX queried repeatedly with a known-good control to distinguish rate-limiting from absence. **I did not fetch them, I cite them nowhere, and I assert nothing about their text.** Recorded so nobody assumes they were checked |
| 17 | Catalogue id 41's duʿā has **no** narration this pass could find | — | — | ⚠️ **UNPINNED.** A negative I could not close. **No catalogue change recommended.** |

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met once, in the ḥadīth, and nowhere else in the corpus that this deck could reach.** Bukhārī 2872: `حَقٌّ عَلَى اللَّهِ أَنْ لاَ يَرْتَفِعَ شَىْءٌ مِنَ الدُّنْيَا **إِلاَّ وَضَعَهُ**` — the subject of `وَضَعَهُ` is **Allah**, carried from `حَقٌّ عَلَى اللَّهِ`, in a finite verb, inside the Prophet's ﷺ own speech. Same construction class as `al-mughni@1`'s `فَأَغْنَاكُمُ ٱللَّهُ`, ruled sufficient at §9a. Abū Dāwūd 4802 makes it explicit with a transitive `يَرْفَعَ` and the same `وَضَعَهُ`. **⚠️ Beat 6 does NOT carry bar 1** — 28:83 shows Allah *assigning the next home*, not lowering — and that is stated rather than implied. Precedent for a verse beat that does not carry bar 1: `al-kareem@1`, whose 27:40 is Sulaymān's speech (§2a) | **yes — beat 5 only** |
| 2 | **the distinguishing quality is shown, not stated** | No beat asserts *"Al-Khafid humbles the arrogant"* (that is catalogue id 41's own `lesson`, and it is deliberately not used). The story **shows** the shape: a pre-eminence that had held for years ends in one afternoon, the people who mind are the best people there are, and the answer they get is a law about **things**, not a verdict about **them**. The reader never sees Allah lower a person | **yes — beats 4 and 5** |
| 3 | **no sibling collapse, including against its own twin** | Three surfaces run separately (§9an), plus the beat-by-beat twin-diff. **The largest disclosure in this deck is `camel`, n=8 across three shipped decks** | **yes, with four disclosures** |
| 4 | **the Name's own root appears in the source text** | **TRADED, and the sweep that forces it is row 12 above: 4 occurrences in the whole Qurʾān, Allah the subject of none.** The deck's demonstration is `w-ḍ-ʿ` (`وَضَعَهُ`). Precedent: `al-haleem@1`, `al-waliyy@1`, `ar-raqeeb@1`. **Partial recovery: the duʿā beat renders `يَا خَافِضُ اخْفِضْ` in Arabic on screen**, so the Name's own root does reach one beat — which `al-haleem@1` and `al-waliyy@1` could not manage at all | **only on beat 7, in Arabic** |
| 5 | **register — no punishment, and no arc terminating in punishment just outside the excerpt** | **Bukhārī 2872 ends on the quoted sentence.** Nothing follows it but the isnād note. There is no enemy, no fighting, no curse and no eschatological threat anywhere in this deck. **The one row to attack: 28:83's n−2 is 28:81, `فَخَسَفْنَا بِهِۦ وَبِدَارِهِ ٱلْأَرْضَ` — Qārūn swallowed by the earth.** That is **the strongest abasement image in the Qurʾān**, it is this deck's Name's most obvious narrative, the deck **refuses it on bar 5** — and then sits two āyāt from it. Stated at full strength rather than buried. Backward punishment is disclosed-and-accepted precedent (`al-haleem@1` on 35:44, `al-qayyum@1` on 2:254, `al-wasi@1` on 51:46 and 29:55); **forward is clean** | **swept both directions; one row flagged** |

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **Bukhārī 2872** (what follows) | Nothing but `طَوَّلَهُ مُوسَى عَنْ حَمَّادٍ عَنْ ثَابِتٍ عَنْ أَنَسٍ` — a chain note, not matn | **The strongest bar-5 form available to a ḥadīth.** Same shape as `al-haleem@1` on Bukhārī 7378 |
| **Bukhārī 2872** (chapter) | `كتاب الجهاد والسير` → `باب نَاقَةِ النَّبِيِّ` — *the Book of Jihād*, chapter *the she-camel of the Prophet ﷺ* | ⚠️ **Disclosed, and it matters.** The **book** heading is martial; the **chapter** and the ḥadīth are not. **No fighting, enemy, weapon or gain appears in the text or on any beat.** Precedent is already looser: `al-wakeel@1` sits immediately after Uḥud, `al-fattah@1` at Ḥudaybiyyah, `al-mughni@1` in the Ḥunayn distribution (§9a, §9q). Recorded so a founder is not surprised by the URL's breadcrumb |
| **28:83** (n−1) | **28:82** — *"And those who had wished for his position the previous day began to say, 'Oh, how Allāh extends provision to whom He wills of His servants and restricts it! If not that Allāh had conferred favor on us, He would have caused it to swallow us…'"* | **Quoted nowhere.** ⚠️ Three disclosures: it is **human speech about Allah** (the ledger's rejected class); it carries `يَبْسُطُ … وَيَقْدِرُ` — **Al-Basit (25) and Al-Qabid (24), both being drafted in this wave** (`.context/claims/24.md`, `25.md`) and both holding 2:245 for the same pairing; and it names the swallowing again. **All off-screen** |
| **28:83** (n−2) | **28:81** — *"And We caused the earth to swallow him and his home…"* | **The bar-5 row, disclosed at full strength above.** Quoted nowhere, alluded to nowhere, and the deck's rejection table records Qārūn as refused **before** 28:83 was chosen, not after |
| **28:83** (n+1) | **28:84** — *"Whoever comes with a good deed will have better than it; and whoever comes with an evil deed — then those who did evil deeds will not be recompensed except [as much as] what they used to do."* | **Clean on bar 5** — a recompense statement whose second half is a **limit** on recompense, not a threat. Calibration: shipped `al-afuw@1` carries 42:26 ending *"the disbelievers will have a severe punishment"* and is recorded non-blocking (plan §7). This is softer on every axis |
| **28:83** (its own tail) | Nothing omitted — the āyah is quoted in full | No ellipsis needed, and none used |
| **56:1–6** | Fetched as the Name's only Qurʾānic root site. 56:4–6: *"When the earth is shaken with convulsion, and the mountains are broken down, crumbling, and become dust dispersing"* | **Rejected, and the rejection is bar 1, not register** — the agent of `خَافِضَةٌ رَّافِعَةٌ` is the Hour. The apocalypse successor is a **second** reason, recorded so the rejection does not look like taste |

### Bar 3, surface 1 — Arabic roots

| root in this deck | where | renders in Arabic? | collision check |
|---|---|---|---|
| `kh-f-ḍ` — the Name's own | **duʿā only** (`يَا خَافِضُ`, `اخْفِضْ`) | **yes, beat 7** | Spent by no deck. Its 4 Qurʾānic occurrences are all rejected or unusable (row 12) |
| `w-ḍ-ʿ` — the bar-1 carrier | Bukhārī 2872 `وَضَعَهُ` | **no** — story beat, `arabic: ""` in 42/42 shipped story beats | ⚠️ **`ar-rafi@1`'s beat-5 quotation predicates the SAME verb `وَضَعَ` of Allah** (`وَيَضَعُ بِهِ آخَرِينَ`). Disclosed at full strength in the twin-diff. Off-screen in Arabic on both |
| `r-f-ʿ` | Bukhārī 2872 `يَرْتَفِعَ`; **duʿā `وَارْفَعْ`** | **yes, beat 7 — and it is the TWIN'S root** | ❌ **Catalogue-locked and unfixable.** The Name that abases renders the Name that exalts, in Arabic, on its own duʿā screen. This is the fourth measurement in the headline |
| `ʿ-l-w` | 28:83 `عُلُوًّا` | no (verse beats are English-only here) | **Al-Ali (52)** and **Al-Mutaali (84)** are both **BLOCKED** on the duʿā axis (§6e) and will not be drafted. Rendered as *superiority*, not *exaltedness* — see the translation table |
| `f-s-d` · `ʿ-q-b` · `w-q-y` | 28:83 | no | no deck |
| `d-n-y` | `ٱلدُّنْيَا` (ḥadīth) | no | ordinary |
| `s-b-q` | `لاَ تُسْبَقُ`, `فَسَبَقَهَا` | no | no deck |

### Bar 3, surface 2 — token frequency over all 34 decks

Counted over **937 rendered beat strings**, beat 7 swept from its first character (§9as).

| token this deck renders | n across 34 decks | decks | verdict |
|---|---|---|---|
| `abaser` · `arrogance` · `superiority` · `corruption` · `hereafter` · `bound` · `weighed` · `race` · `borrowed` · `stays` · `adba` · `outstripped` · `bedouin` · `stings` | **0** each | — | clean — the whole abasement vocabulary is unspent |
| `raise` / `raised` / `raises` / `rank` / `low` / `lower` / `high` / `status` / `degree` | **0** each | — | clean. Beat 5's *"is raised"* and beat 7's locked *"raise my rank"* are the first occurrences in the corpus |
| **`camel`** | **8** | `al-wadud@1` (5, incl. its repeated label *"The lost camel"*), `al-mughni@1` (2), `al-waliyy@1` (1) | ⚠️ **THE LARGEST DISCLOSURE IN THIS DECK, and the row a verifier should take first.** `al-wadud@1` is **shipped** and its story's centre *is* a camel. Mitigations actually applied: the story **label is "The race al-Adba lost"** (no *camel*), the animal is **named** (`al-ʿAḍbāʾ`, **n 0**), and *camel* renders **twice**, against `al-wadud@1`'s five. **Zero shared multiword run**; the narratives are a lost-and-found in a desert vs a race, with opposite emotional shapes (despair→joy vs pre-eminence→loss). **I rule it non-blocking — and under §9ab a drafter may not rule on its own collision, so this is offered to be overturned.** No further mitigation exists: the narration's subject is a she-camel |
| `above` | **4** | `al-waliyy@1`, `al-wasi@1`, `an-nur@1` | ordinary directional register; beat 8 uses it twice. `al-wasi@1`'s *"above you and underneath you"* is a **cosmological** above; mine is **relational**. No shared run ≥3 |
| `outcome` | **1** — a **hapax** | `al-wakeel@1` beat 8: *"You were never asked to hold every outcome."* | Different sense (a result you might control vs `ٱلْعَـٰقِبَة`, the final end). Zero shared 3-gram. **Disclosed because hapaxes are what got `al-mumin@1`'s beat cut (§9ab).** One-line escape exists: Abdel Haleem's *"the happy ending"* — **not taken**, because it is looser and *ending* would be a fresh token with no gain |
| `lost` | **5** | `al-wadud@1`, `ar-rahman@1`, `ash-shafi@1` | appears in this deck **only in the story label** (*"The race al-Adba lost"*), not on any `primary`. `al-wadud@1`'s label is *"The lost camel"* — **`lost` + `camel` in a label on both decks.** Disclosed as part of the camel row |
| `stopped` | **2** | `al-qayyum@1` | ⚠️ `al-qayyum@1`'s engine is *nothing that holds you up has ever stopped*. Beat 8 renders *"had stopped being above"*. **Opposite subject** — there it is Allah's sustaining that never stops, here it is a worldly position that did. Zero shared 3-gram. Disclosed |
| `home` | **3** | `al-fattah@1`, `al-mughni@1` | beat 6 renders *"That home of the Hereafter"*. `al-mughni@1` renders *"go away … to their homes"* / *"went home"*. Different referent, no shared run ≥3 |
| `earth` | **9** | 6 decks | ordinary Qurʾānic register |
| `righteous` · `seek` · `desire` | low, ordinary | — | no run ≥3 |

### Bar 3, surface 3 — the move

| shipped/drafted deck | why a user could think they had been told the same thing twice | measured difference |
|---|---|---|
| **`al-jabbar@1` [S]** — *"The Compeller — Restorer of the Broken"*, and its `grief` ×4 | The brief flags this: the **abasement register sits right next to the restoration register.** Both decks are about something going down. | `al-jabbar@1`'s engine is **what broke gets mended** — sight restored, son restored. **This deck mends nothing.** The camel does not win the next race; the narration ends on the law, not a repair. **They are opposite endings**, and that is the cleanest separation in this deck. `grief` renders **only** in `al-jabbar@1`'s label; this deck renders *stings*, *weighed*, *upset* — **all n 0 or n 0 at beat level** |
| **`al-qayyum@1`** — *"Nothing that keeps you has ever needed a night off"* | Both say something about permanence. | Al-Qayyūm: **what holds you up never pauses.** This deck: **what you are standing on does not last.** Different subject (the Sustainer vs the position), opposite claim. Disclosed on the `stopped` token above |
| **`al-baqi@1` [S]** — *"the inventory inverts"*, 16:96 *"what Allah has is lasting"* | ⚠️ **CORRECTION (verifier): SHIPPED, not "drafted this wave."** Confirmed against `name_stories.json`: `review_verdict: "good"`, `reviewed_by: "founder"`, `reviewed_at: "2026-08-03"` — part of wave 1 (`9d08cab`), which closed before this draft began. Both contrast the transient with the lasting. | ⚠️ **The nearest engine in the corpus, and the reason 20:131 was rejected** (`وَرِزْقُ رَبِّكَ خَيْرٌ وَأَبْقَىٰ` would have put this deck on al-Bāqī's exact sentence). `al-baqi@1`'s move is an **inventory** — what left is the part that stayed. Mine is a **direction** — nothing goes up and stays up. No shared scripture, no shared rendered string |
| **`al-qabid@1` / `al-basit@1`** (the wave's other antonym pair) | Both pairs are a divine give/take polarity, and **both drafters independently concluded the negative Name is never predicated alone.** | **Reported to the coordinator rather than resolved.** Their objects are **provision, the shadow, the rain**; mine is **rank**. Their scripture (25:45–46, 2:245, 30:48, Bukhārī 1013/933) and mine share nothing. Their claimed engine is *the direction of the taking*; mine is *positions are borrowed*. **The structural finding appears in both claim files and on neither deck's beats** |
| **`al-mughni@1` [S]** — *"the unlisted share"* | ⚠️ **CORRECTION (verifier): SHIPPED, not "drafted this wave."** Same confirmation as `al-baqi@1` above — wave 1, closed. Both are Companions being consoled about something they did not get or lost, and **both render `camel`.** | Al-Mughni's consolation is **what you are already taking home**; mine is **what kind of thing it was.** Al-Mughni's people are given nothing and told what they have; mine lose nothing and are told what the world is |
| **`ar-rafi@1`** (its twin) | — | **See the twin-diff in the Ar-Rafiʿ draft — it is written once, there, and not duplicated here.** |

### Translation decisions, itemised (plan §6 rule 2)

| rendered on a beat | published English on the fetched page | what I did, and why |
|---|---|---|
| **"Allah has bound Himself to this: nothing in this world is raised except that He lowers it."** | Bukhārī 2872: *"It is Allah's Law that He brings down whatever rises high in the world."* · Abū Dāwūd 4802: *"It is Allah's right that nothing should become exalted in the world but he lowers it."* · Nasāʾī 3588: *"It is a right upon Allah that nothing is raised in this world except He lowers it."* | **Re-rendered from `حَقٌّ عَلَى اللَّهِ أَنْ لاَ يَرْتَفِعَ شَىْءٌ مِنَ الدُّنْيَا إِلاَّ وَضَعَهُ`, and this is the deck's one theological rendering decision.** (a) **`حَقٌّ عَلَى اللَّهِ` → "Allah has bound Himself to this."** *"A right upon Allah"* is the literal calque and it is **misleading in ordinary English**, where it implies an obligation imposed on Allah from outside — which no school holds. The construction means a due He has settled **upon Himself**, and *"bound Himself"* is reflexive, which is exactly the safe reading. Bukhārī's own page renders it *"Allah's Law"*, which is safe but **drops the exceptive force** that is the whole sentence. **This is an interpretive gloss and it is disclosed as one, not presented as literal.** (b) **`إِلاَّ وَضَعَهُ` → "except that He lowers it."** `وَضَعَ` = *set down / lower*; Abū Dāwūd's page uses *lowers* too. (c) **`لاَ يَرْتَفِعَ` → "is raised"** — Form VIII with `شَىْءٌ` as subject; *"whatever rises high"* (Bukhārī's page) is also correct, and *"is raised"* was chosen because the Abū Dāwūd route reads `أَنْ لاَ يَرْفَعَ` with **Allah** as the agent, and a passive keeps both routes true. ⚠️ **Disclosed against myself: (b) and the twin's *"sets others down"* were chosen partly to keep the two beat-5 strings apart. The Arabic overlap is unchanged and is disclosed in the twin-diff** (§9q) |
| **"…superiority upon the earth…"** (beat 6) | Saheeh: *"…exaltedness upon the earth…"* · Abdel Haleem: *"…superiority on earth…"* | **One word swapped from Saheeh, and the reason is bar 3, not taste.** *Exaltedness* is the twin's Name-gloss family — this deck's verse beat would have said the Hereafter goes to people who do not want **exaltedness** while its paired Name is **The Exalter**, on the same night, four screens apart. `عُلُوّ` is `ʿ-l-w`, **not** `r-f-ʿ`, so the Arabic never had the collision; only the English introduced it. *Superiority* is Abdel Haleem's own word for the same word. **Everything else on beat 6 is Saheeh byte-exact**, including the `[best]` bracket, with `Allāh`→`Allah` (the change all 34 decks make; here the word does not occur) |
| **"Humaid, who passed the report on, said: or hardly ever outstripped."** (beat 3) | *"(Humaid, a subnarrator said, 'Or could hardly be excelled.')"* | Kept, and **moved out of parentheses into the beat's own sentence** so a reader cannot mistake it for the deck's aside. *"Subnarrator"* → *"who passed the report on"*: the technical term is scholar-register (spec §4) |
| **"A bedouin came on a young camel"** (beat 4) | *"a bedouin came riding a camel below six years of age"* | `قَعُود` is specifically a young riding-camel. *"below six years of age"* is the page's gloss of the term, not a translation of it, and it slows the beat without changing anything. **Nothing is subtracted: the point is that it was a young animal, and that is what renders** |

### Rejected — fetched, evaluated, and recorded so nobody re-derives it

| candidate | what it is | why refused |
|---|---|---|
| **Ṣaḥīḥ al-Bukhārī 7411** (fetched) | `وَبِيَدِهِ الأُخْرَى الْمِيزَانُ **يَخْفِضُ** وَيَرْفَعُ` — **the Name's own root, finite verb, Allah the subject.** The single best bar-1+bar-4 text in the corpus for this Name | **Two independent reasons.** (a) Its opening two-thirds is `يَدُ اللَّهِ مَلأَى لاَ يَغِيضُهَا نَفَقَةٌ` — **`al-kareem@1`'s beat-8 engine verbatim in substance** (*"a supply that runs down"*), and its parallel **Bukhārī 4684 is already on `al-kareem@1`'s source table** (§2b). (b) The clause carrying `يَخْفِضُ` **cannot be rendered without putting `يَدُ اللَّهِ` and `عَرْشُهُ عَلَى الْمَاءِ` on a beat**, and this project forbids a deck adjudicating a contested attribute by choice of rendering (plan §6 rule 2; §9j, §9z). Eliding mid-clause to dodge those words is the §9af failure — *removing the half you can remove, not the half that overlaps*. **Blocked, not free** |
| **Ṣaḥīḥ Muslim 179 · Ṣaḥīḥ Muslim 993** | The other two routes circulated as carrying `يَخْفِضُ` of Allah | ❌ **NOT VERIFIED — no Wayback capture of either bare-number URL.** No claim is made about them. Even on the circulated text they would fail: `لاَ يَنَامُ` is `al-qayyum@1`'s entire engine, and `an-nur@1`'s claim file already flags Muslim 178/179 as delicate |
| **Ṣaḥīḥ Muslim 2588** (fetched) | `وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ` | A **statement, not a narrative** (bar 2 — the `al-haleem@1` rev-1 failure). Its other clauses carry `بِعَفْوٍ` (`al-afuw@1`'s Name), `عِزًّا` (Al-Muizz 43) and a wealth-does-not-decrease clause adjacent to `al-kareem@1`. **And it is topically about RAISING** — see the catalogue finding |
| **Qurʾān 56:1–3** | The Name's only Qurʾānic root site | **Bar 1 fails** — the agent is the Hour. Second reason: 56:4–6 |
| **Qurʾān 15:88** | `لَا تَمُدَّنَّ عَيْنَيْكَ … وَلَا تَحْزَنْ عَلَيْهِمْ وَٱخْفِضْ جَنَاحَكَ` — the only āyah pairing *"do not look longingly at what We have given some to enjoy"* with the Name's own root | **Three reasons.** Saheeh **and** Abdel Haleem both gloss the referent as **`[the disbelievers]`**, importing an us/them frame; 15:89 is *"I am the clear warner"* and 15:90–91 the muqtasimīn; and rendering `وَٱخْفِضْ جَنَاحَكَ` would teach a **human virtue (gentleness) under a divine Name** — the reverence line that killed `al-haleem@1` rev 1 and that the ledger applies to Ṭāʾif and to the bedouin in the mosque. **Blocked, not free.** ⚠️ Its *"do not extend your eyes"* would also have made `eyes` **n 2**, against `ar-raqeeb@1`'s hapax verse beat *"before Our eyes"* |
| **Qurʾān 20:131** | `زَهْرَةَ ٱلْحَيَوٰةِ ٱلدُّنْيَا … وَرِزْقُ رَبِّكَ خَيْرٌ وَأَبْقَىٰ` | Head-on with **`al-baqi@1`**'s engine and its verse beat 16:96 (*"what Allah has is lasting"*), and `رِزْق` is `ar-razzaq@1`'s |
| **Qurʾān 57:22–23** | *"…so that you do not despair over what has eluded you, nor exult over what He has given you…"* — **the best consolation clause in the Qurʾān for this Name** | Refused **only** on construction: it is a two-āyah composite opening mid-sentence (`لِّكَيْلَا`), 57:23's own tail is `وَٱللَّهُ لَا يُحِبُّ كُلَّ مُخْتَالٍ فَخُورٍ` and 57:24 is the miserly. **Genuinely free and strong** for a Name that can carry a disclosed composite. Recorded as this deck's one-line alternative if the founder rejects 28:83 on the Qārūn proximity |
| **Qurʾān 95:4–5** | `ثُمَّ رَدَدْنَـٰهُ أَسْفَلَ سَـٰفِلِينَ` — Allah's own first-person lowering | **Refused on register, and this is the clearest statement of this deck's tone line.** On a night surface, to someone already low, *"He returns him to the lowest of the low"* **is** the harm bar 5 exists to prevent. Its reading is also contested (Hell vs decrepitude), so a deck would adjudicate. `al-khaliq@1` separately rejected 95:4 |
| **Qurʾān 3:26's `وَتُعِزُّ … وَتُذِلُّ`** | The clearest raise/abase pair in the Qurʾān | **Reserved by `al-malik@1`'s claim for Al-Muizz (43) / Al-Muzill (44)**, and 3:26 is `al-malik@1`'s verse beat and duʿā pin. Not taken |
| **Qurʾān 3:140** `وَتِلْكَ ٱلْأَيَّامُ نُدَاوِلُهَا بَيْنَ ٱلنَّاسِ` | *"These days We alternate among the people"* — the Name-pair as history | Four grounds: Uḥud/battle register · `شُهَدَآءَ` · a closing negative construction (`وَٱللَّهُ لَا يُحِبُّ ٱلظَّـٰلِمِينَ`) · **Āl ʿImrān already carries three decks** (§9ai) |
| **Qurʾān 30:2–5** (the Romans) | An empire lowered and raised, with `لِلَّهِ ٱلْأَمْرُ` | **Bar 1 fails** — possession, not a demonstrated act. Sūrat ar-Rūm carries `al-muid@1` (30:27) and 30:50 is reserved for Al-Muhyi (§2d) |
| **Qurʾān 28:76–82 — Qārūn** · **Pharaoh (20:42–48, 79:24, 10:90–92)** · **Iblīs's fall (7:13–15)** · **the man of the two gardens (18:32–44)** | Every Qurʾānic narrative in which Allah brings a named person low | **All destruction arcs.** Most are already on the ledger's bar-5 rejection list (§2d); 18:32–44 adds that Sūrat al-Kahf is `ar-raheem@1`'s. **This class is the third measurement in the headline: there is no narrative of Allah lowering a person that survives bar 5** |
| **Qurʾān 59:21** (the mountain humbled by the Qurʾān) | A lowering in Allah's first-person voice | A counterfactual (`لَوْ`); 59:20 is the companions of the Fire; 59:22–24 is the Names litany that `al-malik@1`'s verifier rejected for its nine appositives |

### Catalogue findings — reported, and **NO change recommended**

The standing rule holds: **three of three prior confident recommendations to change catalogue data
have been wrong** (§8.4, §9d). These are findings.

1. **The brief's warning is confirmed and its size is now measured. Id 41's `hadith` is topically
   inverted, and it is not fabricated.** The card reads: *"The Prophet ﷺ said: 'Whoever humbles
   himself for Allah, Allah raises him.' Al-Khafid lowers whoever He wills…"* — **the quoted words
   are Ṣaḥīḥ Muslim 2588's** (`وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ`), fetched and
   ṣaḥīḥ. **The defect is that the only verb in the quotation is `رَفَعَ` — the twin's root** — so the
   card for *The Abaser* proves *The Exalter*, and the abasement is carried entirely by the card's
   own unattributed prose after the quotation. **Id 42's `hadith` is the same narration, correctly
   used.** So the two cards quote **one ḥadīth between them** and one of the two uses it backwards.
   **This deck does not inherit that confusion and does not cite the card as a source** — every
   citation here is a fetched page.
2. **Id 41's `dua_translation` and id 42's share a 5-word byte-identical run: *"raise my rank with
   You"*.** Computed over the catalogue, not eyeballed. Both duʿā beats are gate-locked
   byte-identical, so **neither deck can fix it.** ⚠️ **Invisible to COLLISION-LEDGER §7**, which
   measures runs only against **decked** duʿās — and neither 41 nor 42 was decked when §7 was
   computed. **Any pair of undecked Names could be hiding the same defect; §7's "clear" verdict means
   *clear against decked Names*, not *clear*.**
3. **Id 41's `dua_arabic` renders `وَارْفَعْ` — the twin's root — in Arabic on this deck's own duʿā
   screen.** Shared Arabic runs between the two duʿās at n≥2: **0**. Shared single token: `عِنْدَكَ`.
4. **Neither duʿā was traced to any narration.** Both **UNPINNED**. Neither deck may enter
   `renderedDuaSources`; a `source` on beat 7 fails the gate in the other direction.

### Ship-gate notes

- **`al-khafid@1` must NOT enter `renderedDuaSources`.**
- **Beat 7 is byte-identical to catalogue id 41** — Arabic, transliteration, translation, unmodified.
- **Beat 6 renders no Arabic** (plan §7 convention); `source` uses ASCII `Qur'an`.
- **Beat 8 carries a `synergy` label and the current gate forbids that at `position_in_pair: 0`.**
  Blocking for transcription. See the metadata warning.
- **Deck-internal beat-to-beat diff (§9v, §9al): the longest run shared by any two beats is 3 words**
  (*"had been above"* → *"stopped being above"* sit inside one beat, not across two). **Zero pairs at
  n≥4.** Run before the cross-deck sweep.
- **§9ar check run:** beat 8's final clause (*"where being raised is not on loan"*) read directly
  against the preceding beat's last words (*"raise my rank with You"*) — reinforcing, not inverting.

### What I could not determine, and what a verifier should attack first

1. **Two ṣaḥīḥ routes could not be fetched at all** (Muslim 179, Muslim 993). Their absence is why
   the bar-1 conclusion is stated as *"the routes I could reach"* rather than *"the only routes"*.
   **If either is fetchable by another means, the bar-1 picture for this Name changes** — though
   both fail on collision grounds independently.
2. **Bukhārī and Muslim pages print no grade line.** *"ṣaḥīḥ"* for Bukhārī 2872 is a
   **collection-level inference** (§9ag). Abū Dāwūd 4802 and Nasāʾī 3588 do print grades, and both
   are recorded verbatim.
3. **Ḥadīth checking is not independent of sunnah.com as a corpus.** No isnād audited; no printed
   edition, Shamela or Dorar consulted.
4. **`حَقٌّ عَلَى اللَّهِ` is rendered by an interpretive gloss.** *"Allah has bound Himself to this"*
   is the standard scholarly reading, but it is a reading, and I hold no tafsīr corpus. **All three
   published Englishes are in the table so the founder can substitute one in a line.**
5. **The duʿā negative is unclosed.** I did not find a narration for id 41's duʿā and cannot prove
   none exists.
6. **The rows to attack first, in order:** (a) **`camel` n=8 against shipped `al-wadud@1`** — I ruled
   on my own collision; (b) **28:83's n−2 being Qārūn**, i.e. the deck refusing a narrative and then
   quoting two āyāt from it; (c) the twin-diff's beat-5 row (in the Ar-Rafiʿ draft); (d) whether an
   **authored** `name_intro` gloss — *"the One who brings down whatever rises"* — is legitimate when
   its purpose is to move the Name's object from persons to things. It is entailed by the deck's own
   primary text and has three precedents (`al-wakeel@1`, `al-muid@1`, `al-mumin@1`), **but it is the
   deck softening its own Name, and that should be decided consciously rather than inherited.**

---

## The pairing verdict, stated as a recommendation

**Recommended: ship 41 and 42 together, Al-Khafid as Name₁, or ship neither.**
Ar-Rafiʿ can stand alone; Al-Khafid should not. Name₁ is forced by register — the synergy beat sits
on position 1, so making Al-Khafid Name₁ is what guarantees a user who reaches this Name is handed
the other one before the deck ends. If Ar-Rafiʿ were Name₁, Al-Khafid would be the **terminal** deck
and the night would end on abasement.

**The mechanism to do that does not exist for non-chip decks and needs a decision that is not the
drafter's.** Three options, costed:
- **A new chip** (`brought-low`, or similar) — reuses the shipped pair machinery unchanged, but adds
  an eighth chip to a surface the reel-first work already tuned.
- **A gate change** — a `requires_deck` field asserted bidirectionally, so `al-khafid@1` cannot ship
  without `ar-rafi@1` and the daily loop never serves 41 without 42 available. **This is also what
  Aḍ-Ḍārr (95) needs, and 95 has already been decided (§7a.1) without it existing.**
- **Ship Ar-Rafiʿ only**, and hold Al-Khafid until the catalogue's duʿā de-duplication pass (§6e)
  reaches ids 41/42, which would also let its duʿā stop renderi ng the twin's root.

**A reasoned refusal is on the table too and is not recommended:** ledger §7a.2 puts *"reject the
Name"* off the table, and this deck does not reject it — it found a ṣaḥīḥ, bar-1-clean,
register-clean text and built on it. What it could not do is make Al-Khafid *self-sufficient*, and
the reason is in the corpus, not in the drafting.
