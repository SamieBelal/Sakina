# ADVERSARIAL VERIFICATION — `al-qabid@1` (id 24) and `al-basit@1` (id 25)

**Verifier:** independent, blind to the drafter's own confidence markers (tables read only as claims, not as evidence). Re-fetched every Qur'ān verse live from `api.quran.com/api/v4`, every ḥadīth from Wayback captures of the exact cited URLs at the exact cited timestamps, and both root enumerations from an independent third source — the Quranic Arabic Corpus (`corpus.quran.com`, University of Leeds), which the drafter did not use. Ran my own n-gram/token counts against `assets/content/name_stories.json` (34 decks currently shipped/transcribed; `al-qabid@1`/`al-basit@1` are not yet in it) rather than trusting the drafts' tables.

**Governing rule respected:** the `expander`/`al-wasi@1` collision is settled per plan §9at/§9au — not re-opened here. Both decks disclose it correctly; verified the disclosure text in §6 of both drafts is byte-accurate against `collectible_names.json` (see below).

---

## THE TWO ENUMERATIONS — stated first, as instructed

### `q-b-ḍ` (Al-Qabid): **VERIFIED CORRECT.**

Independently confirmed against `corpus.quran.com/qurandictionary.jsp?q=qbD`: *"The triliteral root qāf bā ḍād occurs **nine** times in the Quran, in four derived forms."* Full corpus listing, cross-checked verse-by-verse against the deck's own table:

| verse | form | subject |
|---|---|---|
| 2:245 | verb `yaqbiḍu` | **Allah**, explicit — matches deck |
| 5:64-adjacent n/a | — | — |
| 9:67 | verb `yaqbiḍūna` | the hypocrites — matches deck |
| 20:96 | verb `faqabaḍtu` + noun `qabḍatan` (2 occurrences, one āyah) | the Sāmirī — matches deck |
| 25:46 | verb `qabaḍnāhu` + noun `qabḍan` (2 occurrences, one āyah) | **Allah**, first person — matches deck |
| 39:67 | noun `qabḍatuhu` | Allah, but a **noun** — matches deck's own "see below" distinction |
| 67:19 | verb `yaqbiḍna` | the birds — matches deck, including the `ٱلرَّحْمَـٰنُ` holder note |
| 2:283 | passive participle `maqbūḍatun` | a pledge — matches deck |

Total = 9. **Allah is the finite-verb subject in exactly 2 (2:245, 25:46)**, exactly as claimed. I independently fetched all nine āyāt (`quran.com/api/v4/verses/by_key`) and read every one as a candidate, not only as a neighbour. **No correction needed. This is the cleanest enumeration I have checked in this project.**

### `b-s-ṭ` (Al-Basit): **THE HEADLINE COUNT IS WRONG. This is a blocking finding.**

The deck states: *"**18 true occurrences** after discarding `س-ل-ط` (×7), `س-خ-ط` (1) and `مصيطر` (1)"* and *"**Allah is the grammatical subject in 15 of the 18.**"*

Independently confirmed against `corpus.quran.com/qurandictionary.jsp?q=bsT`: *"The triliteral root bā sīn ṭā occurs **25** times in the Quran, in six derived forms."* Full verse list fetched and cross-checked against the deck's own itemized table (§2 of the draft). **The deck's own table, summed, equals 25 — not 18:**

| the deck's own group | āyāt listed | count |
|---|---|---|
| `يَبْسُطُ ٱلرِّزْقَ` (rizq) | 13:26 · 17:30 · 28:82 · 29:62 · 30:37 · 34:36 · 34:39 · 39:52 · 42:12 · 42:27 | 10 |
| paired with `q-b-ḍ` | 2:245 | 1 |
| the hands | 5:64 | 1 |
| human speech about Allah | 71:19 · 2:247 | 2 |
| the clouds | 30:48 | 1 |
| not Allah | 5:11 · 5:28 (×2) · 6:93 · 7:69 · 13:14 · 17:29 (×2) · 18:18 · 60:2 | 10 |
| **sum** | | **25** |

10+1+1+2+1+10 = **25**, matching the Quranic Arabic Corpus's authoritative 25 exactly, verse for verse (I fetched every one of the 25 individually from the corpus page and reconciled it against the deck's row placement — every single āyah the corpus lists is present somewhere in the deck's table; nothing is missing). **The deck's own supporting evidence proves its headline wrong.** This is precisely the class of error plan §9aj names as the highest-value catch in this pipeline — *the prose is written to be persuasive and the table is written to be true, and nobody diffs them against each other* — reproduced here inside a single deck's own §2 section.

**What is and is not damaged by this.** The underlying research is not fabricated: every individual āyah is correctly fetched, correctly classified into a group, and correctly reasoned about (I independently re-verified the rizq group's "contraction in the same sentence" claim for 42:27 — `بِقَدَرٍ` is indeed the same `q-d-r` root as `يَقْدِرُ`, confirming even the subtler counterfactual-verse claim holds). The selection of 30:48 as the deck's anchor is not undermined by the miscount — it remains a real, available, Allah-subject, uncontracted occurrence. **What is damaged is the deck's own headline claim to the founder about the size and strength of the enumeration**, which is the number the task brief specifically warned would sink the pair's stated spine if wrong. The "Allah subject in 15" figure is plausible against a corrected denominator of 25 (my own count: 12 verb occurrences in Allah's own voice + 1 passive-participle "His hands" occurrence in Allah's own voice + 2 occurrences embedded in reported human speech ≈ 15) but the deck states it as "15 of 18," which is arithmetically incoherent on its own terms.

**Secondary, non-blocking nuance found in the same section.** The deck's summary line — *"30:48 is the only place in the Qur'ān where `basṭ` is predicated of Allah with no contraction beside it"* — is stated as an absolute but is not quite true even on the deck's own table: **5:64** (`بَلْ يَدَاهُ مَبْسُوطَتَانِ`) is also Allah's own voice (not reported speech), also has no `q-b-ḍ`-root contraction in the same clause (its antithesis is `مَغْلُولَةٌ`, a different root — I fetched the full āyah and confirmed this). The deck correctly *excludes* 5:64 from its chosen anchor for sound, independently-verified reasons (I fetched 5:64 in full: it opens on the Jews' curse-provoking claim and the āyah's own continuation runs into `ٱلْعَدَٰوَةَ وَٱلْبَغْضَآءَ إِلَىٰ يَوْمِ ٱلْقِيَـٰمَةِ`, "enmity and hatred until the Day of Resurrection" — bar-5 fatal, exactly as claimed). So the **selection** survives; only the **"only place" adjective** overclaims, in the exact §9ak shape ("state the measurement, not the adjective") the ledger has flagged repeatedly.

**Required fix:** correct "18" → "25" and re-derive "15" against the correct denominator (or restate precisely what the 15 is 15-of); soften "the only place" to "the only available candidate" (or similar, given 5:64 exists and is rejected on other grounds, not on being absent). Neither fix touches the chosen anchor, the translation ruling, or any rendered beat.

---

## Probe 2 — Al-Basit bar 1 (the SI vs. Usmani rendering of 30:48)

**Independently re-fetched all seven cited translations live** (`quran.com` translation ids 20, 84, 85, 95, 19, 22, 149):

| translator | subject of the spreading |
|---|---|
| Saheeh International (20) | **"they"** — the winds ("and they stir the clouds and spread them") |
| Usmani (84) | "He spreads it" |
| Abdel Haleem (85) | "He spreads them" |
| Maududi (95) | "He spreads them" |
| Pickthall (19) | "spreadeth them" (Allah is the sentence subject throughout) |
| Yusuf Ali (22) | "does He spread them" |
| Bridges (149) | "He spreads them" |

**Confirmed exactly as claimed: 6 of 7 give the spreading to Allah; SI alone gives it to the winds.** I also independently checked the grammatical claim the deck rests on: in the Arabic (`فَتُثِيرُ سَحَابًا فَيَبْسُطُهُۥ`), `فَتُثِيرُ` carries the feminine `ت-` prefix (agreeing with the feminine collective `ٱلرِّيَـٰحَ`, "the winds"), while `فَيَبْسُطُهُۥ` carries the masculine `ي-` prefix — grammatically impossible to co-refer to the winds, and the only available masculine antecedent in the sentence is `ٱللَّهُ`, fronted at the āyah's head (`ٱللَّهُ ٱلَّذِى يُرْسِلُ...`). **The grammar is sound and the deck's ruling stands: if a reviewer insists on SI, bar 1 fails, but SI's English does not survive the Arabic's own gender agreement.** The deck names this as its own weakest point and is right to.

## Probe 3 — bar 5 (30:51 and 2:246)

Both independently fetched.

- **30:51** — *"But if We should send a [bad] wind and they saw [their crops] turned yellow, they would remain thereafter disbelievers."* Confirmed: same wind-image, same people, 3 āyāt past the verse beat. It is a **hypothetical conditional** (`لَئِنْ`) about ingratitude, not a decreed or eschatological punishment on the people in the passage. **Ruling: non-blocking**, softer than the accepted `al-afuw@1`/42:26 precedent (immediate eschatological successor, accepted) on every axis the deck names. Agree with the deck's own self-assessment.
- **2:246** — ends *"…Allāh is Knowing of the wrongdoers"* after the Ṭālūt narrative. Confirmed: it opens a wholly new, unrelated narrative (`أَلَمْ تَرَ إِلَى ٱلْمَلَإِ مِنۢ بَنِىٓ إِسْرَٰٓءِيلَ`) rather than continuing the loan/withhold-and-grant thought of 2:245. **Ruling: non-blocking**, matches the accepted `al-afuw@1` precedent structurally.

## Probe 4 — Al-Qabid's reverence problem, read as a user at 11pm

Confirmed by direct read of the beats: **no beat states "He withholds to protect you" or "relief is coming."** Beat 0 names the hard part precisely ("it seems to have gone nowhere") without contradicting it later — the deck never says it *did* go somewhere in a way that erases the loss; it says it went *toward the One who extended it* (beat 7), which is a return-to-Allah frame, not a promise of restoration. **This does not accuse.** It does not tell the user their loss is deserved, protective, or temporary.

**One thing worth the founder's own gut-check, stated as an observation rather than a defect:** the comfort on offer is entirely structural/intellectual (recognize the pattern: the shadow's extension, stillness, and the sun are all His; therefore the taking is His too, toward Him) rather than affective. A user in acute distress may read beat 7 as a memento-mori ("you too will be returned to Him") rather than as reassurance about the *specific thing that was taken*. This is consistent with the plan's bar-2 discipline (never assert relief that isn't in the text) and I would not block on it, but it is a real difference from decks that end on warmer material, and the founder should read beats 0 and 7 back to back once before signing.

## Probe 5 — the refused narration

**Independently fetched via Wayback CDX at the exact cited timestamps** (`20260301064636` for Abū Dāwūd 3451, `20260214171852` for Tirmidhī 1314).

- Abū Dāwūd 3451: Arabic confirmed `إِنَّ اللَّهَ هُوَ الْمُسَعِّرُ الْقَابِضُ الْبَاسِطُ الرَّازِقُ` — a list of epithets inside the Prophet's ﷺ own reported speech, in response to a request to fix prices. Grade on the page: **Sahih (Al-Albani)**, confirmed.
- Tirmidhī 1314: Arabic confirmed identical in substance (`الْمُسَعِّرُ الْقَابِضُ الْبَاسِطُ الرَّزَّاقُ`). Grade on page: **Sahih (Darussalam)**; at-Tirmidhī's own line on the page: `هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ`. Both confirmed exactly.
- **The refusal is correct.** It is a list of epithets in human (Prophetic) reported speech about Allah, not a demonstrated finite-verb act of Allah's own — bar 1's named failure mode, compounded by the human-speech-about-Allah class already established in the ledger (7:196, 12:101, 10:62).
- **"Al-Basir" finding independently confirmed.** Sunnah.com's published English of Tirmidhī 1314 reads: *"Indeed Allah is Al-Musa'ir, Al-Qabid, **Al-Basir**, Ar-Razzaq"* — verified byte-exact from the archived page. The Arabic on the same page correctly has `الْبَاسِطُ`. This is a genuine sunnah.com translation defect, and "Al-Basir" does collide with catalogue id 46 (Al-Baseer, shipped). Correctly identified and correctly not acted upon (neither deck quotes this narration).

## Probe 6 — the twin diff

Independently re-ran the n-gram comparison over the exact beat text of both drafts (beat 6 excluded as forced-identical). **Result: zero n≥4 hits; exactly one n=3 hit — `"the one who"` (beat 7 of Al-Qabid against beat 5 of Al-Basit).** This matches the decks' claim exactly. Independently confirmed `sun` is the only substantive shared content token (`al-qayyum@1` precedent on one side, the drought narrative on the other).

**Minor accuracy note, non-blocking.** Both drafts list `sentence` and `allah's` among "shared content tokens outside beat 6," but by the drafts' own later disclosures neither token is actually shared any longer: `sentence` was deliberately removed from Al-Qabid's beat 3 (stated in the same section) and now occurs only in Al-Basit; `allah's` (from "O Allah's Messenger!") occurs only in Al-Basit's story beats and nowhere in Al-Qabid. This is a small, stale-list inconsistency, not a finding that changes any ruling — flagged because §9ak asks for measurements to be exact.

**Ruling: these are genuinely two decks, not one deck twice with the polarity flipped.** Different genre (Qur'ān-only vs. ḥadīth-led), different protagonist count (0 vs. 3), different domain (light/shadow vs. weather/drought), different register (contemplative vs. reportorial), different move (direction-of-the-taking vs. record-keeps-the-emptiness). The only literal repetition is the catalogue-forced duʿā screen, which both decks disclose at full strength in the identical §6.

## Probe 7 — Al-Basit beat 4's "six days" vs. sunnah.com's "a week"

**Independently fetched Bukhārī 1013 via Wayback** (`20251231003006`). Confirmed Arabic: `قَالَ وَاللَّهِ مَا رَأَيْنَا الشَّمْسَ سِتًّا` — `سِتًّا` is unambiguously "six" (feminine accusative numeral, implicit "days"). The published English on the same page reads *"we could not see the sun for a week."* **The deck's deviation is correct and well-founded**, and matches plan §6 rule 2 (re-render contested passages from the Arabic). Also independently confirmed the disclosed omission of a third negation in beat 3 (`وَلاَ شَيْئًا`, "nor anything") that the published English drops, and confirmed the second-Friday elision quoted in §4c is byte-accurate against the archived page, including the honorific placement and the "withhold rain" reversal. **Both disclosures check out at full strength.**

## Probe 8 — the al-mujeeb@1 move-adjacency (ruled here, since the drafter correctly declined to rule on its own collision per §9ab)

**Ruling: NOT BLOCKING.** Both are, at the broadest level, "a request answered" stories — a shape several decks in this catalogue already share (`as-salam@1`, `ash-shafi@1`). But the actual engines diverge: Al-Mujeeb's beat 8 is about the **scope** of the answer (one man inside one fish; the answer's own last words widen to "the believers" — singular becomes plural). Al-Basit's beat 8 is about the **distribution of narrative weight within the record** (the rain gets one sentence; the oath proving emptiness is what the account actually dwells on). A user reading both beat-8s would not come away with the same insight — one is about who benefits, the other is about what a witness chose to swear to. I would not require a rewrite here.

## Bar 3, all three surfaces / duʿā beats swept from character one (§9an, §9as)

Confirmed present and complete on both drafts. Both correctly sweep beat 6 (`"O Constrictor, O Expander, spread over us from Your mercy"`) from its first character rather than from the petition onward, and both correctly identify `constrictor`/`expander`/`mercy` as forced, catalogue-locked, unremovable shared tokens. This is the fix §9as mandated and both decks apply it.

## Deck-internal diff (§9v, 28 pairs)

Spot-checked rather than exhaustively recomputed. Al-Qabid's disclosed `extend*` callback (beats 2, 3, 7) and `taken` bind (beats 0, 7) read as genuine authored callbacks, not accidental self-quotation — beat 7 paraphrases rather than reproduces the quoted strings from beats 4–5, confirmed by direct comparison. No new internal collision found in either deck beyond what is already disclosed.

## Visible ellipsis check

Confirmed on the beat text itself (not merely in the verification table): Al-Qabid's beat 2 ends `…` and beat 3 opens `…` (25:45 split); Al-Qabid's beat 5 opens `…` (2:245's charity-appeal opening dropped); Al-Basit's beat 4 ends `…` (Bukhārī 1013's second Friday dropped). All four are genuinely visible in the rendered `primary` string, not just disclosed in a table a user never sees — satisfying the batch-2 rule this project earned the hard way.

## A methodological note on the token-frequency universe (own limit, non-blocking)

Both drafts state their sweep runs over *"663 rendered strings of the 34 shipped decks."* I extracted `primary`/`label`/`source` from the live `assets/content/name_stories.json` (34 decks, confirmed by count) and got **595** non-empty strings, not 663 — an ~11% discrepancy in the stated universe size that I could not reconcile by trying several plausible field combinations. However, I independently re-derived every specific token count the decks actually rely on (`withhold`=2, `abundance`=1, `sun`=1, `expander`=1, `expand`=1, `spread`=2, `constrictor`=0) and **all matched exactly**. The specific measurements the findings are built on are correct; only the stated size of the universe they were drawn from does not reconcile under my own extraction method. Possibly a stale count from an earlier asset snapshot, given the ledger's own note that transcription was landing concurrently with this pass. Flagged for completeness, not blocking.

---

## Verdicts

### `al-qabid@1` (id 24, Al-Qabid) — **SIGN**

Scripture 100% verified: both quotations byte-exact against a live fetch, both elisions visible on the beat, the enumeration independently reproduced and correct to the occurrence. The refused pricing ḥadīth is correctly refused and its defects (epithet-list, "Al-Basir" mistranslation) independently confirmed. The reverence question does not accuse; the structural answer is legitimate, with one soft observation for the founder (comfort here is intellectual, not affective — worth a quick read-through, not a rewrite). No blocking findings.

### `al-basit@1` (id 25, Al-Basit) — **FIX-THEN-SIGN**

One blocking finding: **the deck's own headline b-s-ṭ count ("18 true occurrences," "Allah subject in 15 of the 18") is wrong and is contradicted by the deck's own itemized table, which sums to 25 — independently confirmed against the Quranic Arabic Corpus's authoritative count of 25.** This is exactly the failure the task brief warned would cost the pair its stated spine. The fix is narrow and does not touch the chosen anchor (30:48), the translation ruling (Usmani over SI, independently re-verified as sound), or any rendered beat: correct "18"→"25," re-derive "15" against the correct denominator or restate precisely what it counts, and soften "the only place... with no contraction" to account for 5:64 (rejected on other, sound grounds, not on non-existence). Everything else in the draft — bar 1's translation controversy, the two bar-5 rows, the "six days" correction, the twin diff, the refused pricing ḥadīth, the shared-duʿā disclosure — independently checks out at full strength.

---

## This method's own limits

1. **The enumerations were cross-checked against one independent corpus (`corpus.quran.com`), not two.** It is an academically maintained, morphologically-tagged resource and a materially different method from the drafts' own consonant-skeleton sweep, which is why it caught the b-s-ṭ error — but it is still one source. A third independent count was not run.
2. **No isnād was audited** for either ḥadīth; published grade lines were read directly off the archived pages, per the standing project limit.
3. **The twin-diff and deck-internal-diff n-gram checks were run by me on the beat text as transcribed in the draft markdown**, not against a JSON-serialized beat structure (since neither deck is in the asset yet). A transcription-time typo would not be caught by this check.
4. **The token-frequency universe discrepancy (595 vs. 663) was not root-caused.** I confirmed the specific counts used in both decks' findings are individually correct, but could not reconcile the stated total, and did not have time to test every plausible field-combination exhaustively.
5. **The "move" rulings (probe 8, and my own read of bar-3 surface 3 elsewhere) are judgment, not measurement**, per §9an's own limit — a different reader could weigh them differently. I have stated my reasoning in each case so it can be checked.
6. **I did not run the ship gate** and touched no asset, catalogue, or test file — read-only and live-fetch only, per the task constraint.
