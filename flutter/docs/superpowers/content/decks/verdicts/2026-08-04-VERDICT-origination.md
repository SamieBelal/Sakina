# Verdict — batch `origination` — 2026-08-04

Blind adversarial verifier. Decks reviewed: `al-bari@1` (id 20), `al-badi@1` (id 97), `al-mubdi@1` (id 67), `al-baith@1` (id 59), `al-muhyi@1` (id 69), `al-mumeet@1` (id 70). Every citation below was fetched live during this review (`api.quran.com/api/v4`, `corpus.quran.com/qurandictionary.jsp`, Wayback raw captures of `sunnah.com`) — none was taken from a drafter's table.

**Headline finding:** unlike the failure catalogue in the brief, this batch's sourcing held up under fetch. Every Qurʾān quotation I checked (≈35 āyāt across six decks) matched `text_uthmani` and Saheeh International byte-for-byte in the region claimed; both corpus root-sweep tables I re-derived matched the drafters' arithmetic; the one ḥadīth rendered on a beat (Bukhārī 1339) matched Arabic and English on the Wayback capture, including the specific Arabic words the deck's verification table named. I did find one real citation error (§1, row marked ❌) and several judgment calls that deserve CONTESTED rather than PASS. Full detail below.

---

## 1 · Citation table — every fetch, what came back

| Claim (as it reaches a beat / a drafter's argument) | Source fetched | What the text actually says | Status |
|---|---|---|---|
| 57:22 whole: "No disaster strikes... except that it is in a register before We bring it into being – indeed that, for Allah, is easy" | `api.quran.com/.../57:22`, translations=20 | `مَآ أَصَابَ مِن مُّصِيبَةٍ فِى ٱلْأَرْضِ وَلَا فِىٓ أَنفُسِكُمْ إِلَّا فِى كِتَـٰبٍ مِّن قَبْلِ أَن نَّبْرَأَهَآ ۚ إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ`. Deck renders to the first `ۚ`, correctly omits the closing clause | ✅ |
| 57:23a: "In order that you not despair over what has eluded you..." | `.../57:23` | `لِّكَيْلَا تَأْسَوْا۟ عَلَىٰ مَا فَاتَكُمْ وَلَا تَفْرَحُوا۟ بِمَآ ءَاتَىٰكُمْ ۗ وَٱللَّهُ لَا يُحِبُّ كُلَّ مُخْتَالٍ فَخُورٍ`. Saheeh: "In order that you not despair..." — R1's fix from "so that" is confirmed correct against the live translation | ✅ |
| 57:23b tail rendered nowhere on the deck | same fetch | `وَٱللَّهُ لَا يُحِبُّ كُلَّ مُخْتَالٍ فَخُورٍ` — "Allah does not like every self-deluded, boastful person" — a real rebuke clause, one clause past the deck's ellipsis | ✅ confirms the deck's own disclosed bar-5 exposure |
| 57:21 (n−1 of carrier): forgiveness/Garden, no punishment | `.../57:21` | confirmed clean | ✅ |
| 57:24 (n+1 of 57:23): stinginess passage | `.../57:24` | confirmed, not rendered | ✅ |
| 59:24 whole, incl. "…the Producer…" | `.../59:24` | `هُوَ ٱللَّهُ ٱلْخَـٰلِقُ ٱلْبَارِئُ ٱلْمُصَوِّرُ...` Saheeh: "the Creator, the Producer, the Fashioner" | ✅ trailing-epithet chain confirmed; deck correctly does not claim bar 1 from it |
| 59:25 → HTTP 404 (sūrah-final) | `curl -o /dev/null -w %{http_code} .../59:25` | **404** | ✅ confirms sūrah-final, strongest bar-5 form |
| `corpus?q=brA`: 31 occurrences, 10 forms | `corpus.quran.com/qurandictionary.jsp?q=brA` | Headline: "occurs 31 times... in 10 derived forms." Full form breakdown (1 verb I / 2 verb II / 2 verb IV / 5 verb V / 1 noun barā / 2 noun barāat / 12 nominal barī / 2 noun bariyyat / 3 participle bāri / 1 passive participle) sums to 31 | ✅ arithmetic and every count independently reproduced |
| 2:54 ×2 `بَارِئِكُمْ`, Mūsā's reported speech, "kill yourselves" | `.../2:54` | `فَتُوبُوٓا۟ إِلَىٰ بَارِئِكُمْ فَٱقْتُلُوٓا۟ أَنفُسَكُمْ` — confirmed, Mūsā's speech, imperative to kill | ✅ |
| 98:6/98:7 `ٱلْبَرِيَّةِ`, 98:6 = Hellfire | `.../98:6`, `.../98:7` | 98:6 `فِى نَارِ جَهَنَّمَ خَـٰلِدِينَ فِيهَآ` confirmed | ✅ |
| 2:117 whole: "Originator of the heavens and the earth. When He decrees a matter, He only says to it 'Be' — and it is" | `.../2:117` | `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ وَإِذَا قَضَىٰٓ أَمْرًا فَإِنَّمَا يَقُولُ لَهُۥ كُن فَيَكُونُ` | ✅ |
| 2:116 (n−1): "they say Allah has taken a son," refuted, no punishment | `.../2:116` | `وَقَالُوا۟ ٱتَّخَذَ ٱللَّهُ وَلَدًا ۗ سُبْحَـٰنَهُۥ` confirmed | ✅ |
| 2:118 (n+1): people demanding a sign, closes on certainty | `.../2:118` | confirmed, `قَدْ بَيَّنَّا ٱلْـَٔايَـٰتِ لِقَوْمٍ يُوقِنُونَ` | ✅ |
| 6:101: same two words `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ`, continues into polemic about a son | `.../6:101` | `أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ` confirmed | ✅ |
| `corpus?q=bdE`: 4 occurrences, 3 forms, only 2:117/6:101 predicate Allah | `corpus.quran.com/qurandictionary.jsp?q=bdE` | "occurs four times... in three derived forms": 57:27 (human, ٱبْتَدَعُوهَا), 46:9 (Prophet, بِدْعًا), 2:117 and 6:101 (`بَدِيعُ`) | ✅ exact match |
| Catalogue cross-check: shipped `al-aleem@1`'s duʿā renders "Originator of the heavens and the earth" (id 14, root `ف-ط-ر`) — same English as id 97's `english` | `assets/content/name_stories.json`, `al-aleem@1` dua beat | `primary`: "O Allah, Knower of the unseen and the seen, **Originator of the heavens and the earth.**" `arabic`: `فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ` | ✅ confirmed — a real 7-word English collision, correctly attributed to translation-of-different-roots, not actionable per §9bl |
| 21:104 whole, incl. "As We began the first creation, We will repeat it. [That is] a promise binding upon Us" | `.../21:104` | `يَوْمَ نَطْوِى ٱلسَّمَآءَ ... كَمَا بَدَأْنَآ أَوَّلَ خَلْقٍ نُّعِيدُهُۥ ۚ وَعْدًا عَلَيْنَآ ۚ إِنَّا كُنَّا فَـٰعِلِينَ` | ✅ |
| 21:103 (n−1): "the greatest terror" negated for the righteous | `.../21:103` | `لَا يَحْزُنُهُمُ ٱلْفَزَعُ ٱلْأَكْبَرُ` — confirmed inside a negation | ✅ |
| 21:105 (n+1): clean, righteous inherit the land | `.../21:105` | confirmed | ✅ |
| **30:27 whole is shipped `al-muid@1`'s verse beat, and contains `يَبْدَؤُا۟` (Al-Mubdi's root)** | `.../30:27`; `assets/content/name_stories.json` `al-muid@1` verse beat | `وَهُوَ ٱلَّذِى يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ ...` Shipped beat text: "And it is He who begins creation; then He repeats it, and that is [even] easier for Him." — verbatim match to Saheeh | ✅ **confirmed true.** This is the core fact behind task item 2 and `HANDOFF.md` line 254 |
| `corpus?q=bdA`: 15 occurrences, 2 forms (12 form I, 3 form IV) | `corpus.quran.com/qurandictionary.jsp?q=bdA` | "occurs 15 times... in two derived forms: 12 times as the form I verb... three times as the form IV verb" | ✅ exact match |
| **al-mubdi's rejected-candidate claim: "32:7 ... is al-khaliq@1's territory, cited in that draft"** | `assets/content/name_stories.json`, `al-khaliq@1` full `sources` array | Shipped `al-khaliq@1` cites **23:12, 23:13–14, 36:36**, and its successor sweep covers 23:11–17 and 36:34–38. **32:7 appears nowhere in the shipped deck.** | ❌ **inaccurate citation-attribution.** 32:7 is thematically adjacent to Al-Khaliq's clay-creation ground but is **not actually cited** by the shipped deck. Does not change al-mubdi's own bar-1/4 carrier (21:104), which never needed 32:7 |
| 2:55 whole: the demand to see Allah, the thunderbolt | `.../2:55` | `فَأَخَذَتْكُمُ ٱلصَّـٰعِقَةُ وَأَنتُمْ تَنظُرُونَ` confirmed | ✅ |
| 2:56 whole: "Then We revived you after your death that perhaps you would be grateful" | `.../2:56` | `ثُمَّ بَعَثْنَـٰكُم مِّنۢ بَعْدِ مَوْتِكُمْ لَعَلَّكُمْ تَشْكُرُونَ` | ✅ |
| 2:57 (n+1): manna, quails, clean | `.../2:57` | confirmed | ✅ |
| 22:7 closing clause: "...and that Allah will resurrect those in the graves" | `.../22:7` | `وَأَنَّ ٱللَّهَ يَبْعَثُ مَن فِى ٱلْقُبُورِ` | ✅ |
| 22:8 (n+1 of verse beat): disputation without knowledge, no punishment | `.../22:8` | confirmed | ✅ |
| 22:6 (n−1 of verse beat) — **not checked by the deck** | `.../22:6` | `وَأَنَّهُۥ يُحْىِ ٱلْمَوْتَىٰ` — "He gives life to the dead" — clean, positive, and (incidentally) contains Al-Muhyi's root off-screen | ⚠️ **gap found**: the deck's successor sweep covers n−1 of the *story* carrier (2:55) and n+1 of both citations, but never fetches n−1 of the *verse-beat* citation (22:7). Benign in outcome (22:6 is clean) but the sweep as documented is incomplete |
| `corpus?q=bEv`: 67 occurrences, 5 forms, 52 form I | `corpus.quran.com/qurandictionary.jsp?q=bEv` | "occurs 67 times... in five derived forms: 52 times as the form I verb..." | ✅ exact match |
| 30:48–30:52, 41:38–41:40, all six fetched for al-muhyi | `api.quran.com` × 9 | All confirmed word-for-word against the deck's quotations, paraphrases (labelled), and disclosed non-blocking passages (30:51 conditional, 41:40 rhetorical comparison, neither addressed to the reader) | ✅ |
| Twin-diff: max cross-deck shared word-run between `al-muhyi@1` and `al-mumeet@1` rendered beats = 2 | independently re-computed, dynamic-programming longest-common-word-run over both decks' 8 rendered beats each, all 64 pairs | Reproduced: **max = 2** (`"of life"`, plus several 2-word function fragments); no run of 3+ anywhere | ✅ independently confirmed, not taken on the drafter's word |
| Bukhārī 1339, full narration (Mūsā and the angel of death) | Wayback raw, `web.archive.org/web/2024id_/https://sunnah.com/bukhari:1339` | Arabic and English both fetched; every Arabic fragment the deck's verification table names (`أُرْسِلَ مَلَكُ الْمَوْتِ`, `صَكَّهُ`, `فَرَدَّ اللَّهُ عَلَيْهِ عَيْنَهُ`, `ثُمَّ الْمَوْتُ`, `فَالآنَ`, `الأَرْضِ الْمُقَدَّسَةِ`) is present verbatim. **No printed grade line on the page** — consistent with sunnah.com's convention for Bukhārī (collection-level authenticity, no separate grade tab content; confirmed by grepping the raw HTML for "Grade" — the label appears with no attached text) | ✅ |
| Catalogue id 70's own `hadith` field cites Tirmidhī 2307 (not rendered on any beat) | Wayback raw, `.../tirmidhi:2307` | Arabic and English match the catalogue's paraphrase. **Printed grade line, read directly off the page: "Grade : Hasan (Darussalam)"** | ✅ confirmed independently; matches the deck's own claim exactly |
| 63:10 (n−1), 63:11 (carrier, sūrah-final), 63:12 → 404 | `api.quran.com` ×3 | All confirmed; 63:12 returns HTTP 404 | ✅ |
| Full-text doublet sweep (`يُحْىِ`/`نُحْىِ` + `يُمِيتُ`/`نُمِيتُ`, 16/16) and the two disclosed exceptions (2:259, 80:21) | spot-fetched 2:259, 80:21, 2:28, 57:2, 3:156 | 2:259: `فَأَمَاتَهُ ٱللَّهُ ... ثُمَّ بَعَثَهُۥ` — paired with `بَعَثَ` (Al-Baith's root), not a `ح-ي-ي` form, confirming the deck's exception. 80:21: `ثُمَّ أَمَاتَهُۥ فَأَقْبَرَهُۥ` — paired with burial, confirming the exception. 2:28/57:2/3:156 all carry the WA-paired doublet as claimed | ✅ spot-checked, consistent with the claimed sweep; I did not re-run the full 114-chapter regex myself (see §6) |
| Catalogue `dua`/`name_intro` fields byte-match for ids 20, 97, 67, 59, 69, 70 | `assets/content/collectible_names.json` | All six decks' rendered `dua_arabic`/`dua_translation` and `name_intro` `english` strings match the catalogue verbatim, including id 20's `english`/`dua_translation` Name-word mismatch ("The Evolver" vs. "O Producer") that `al-bari@1` self-reports | ✅ |

---

## 2 · Per-deck five-bars verdict

### `al-bari@1` (id 20)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 57:22 `نَّبْرَأَهَآ` — form I, 1st-pl., Allah the subject, direct narration. Top rung |
| 2 | **CONTESTED** | 57:22 is an order-of-operations (register precedes event), not a parable or counterfactual — the deck says so itself. I agree it *shows* a sequence rather than *stating* an attribute, but this is the thinnest bar-2 case in the batch and the deck is honest that it has no fallback text. I would not fail it, but I would not call it a clean PASS either |
| 3 | **PASS**, with disclosed collisions | (a) roots clean; (b) 45 decks swept, max run 4, both accounted for (one scripture, one deliberate cross-reference); spot-checked two of the five listed collisions against the shipped asset and both reproduced exactly. (c) see §3 below — genuinely distinct from Jabbar/Shafi (repair-after-break vs. precedence-before-being), thinner against Badi/Mubdi |
| 4 | **PASS, no trade** | `نَّبْرَأَهَآ` and `ٱلْبَارِئُ` both present in rendered text; sweep confirms only 6 creation-sense occurrences across 5 āyāt exist at all, and 57:22 is the only one that survives bar 1 and bar 5 together |
| 5 | **PASS after truncation** | 59:25 → 404 confirmed (sūrah-final, strongest form). 57:23's tail (`وَٱللَّهُ لَا يُحِبُّ...`) is a real rebuke one clause past the ellipsis — disclosed, not eliminated. This is a genuine, sharp exposure and I'd flag it for founder attention, but the truncation is real and the rendered text itself carries no rebuke |

**Ship verdict: SHIP**, with the bar-2 thinness and the 57:23 proximity flagged for sign-off, not as blockers.

### `al-badi@1` (id 97)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 2:117 second clause, Allah's own narration, `كُن فَيَكُونُ` a described act |
| 2 | **PASS** | the absence of an intermediate step is itself what's shown — a genuinely different shape from bar-2 attribute-statement failures |
| 3 | **PASS**, disclosed 7-word scripture collision (al-aleem@1, confirmed real, correctly unactionable) | see §3 for (c) |
| 4 | **PASS, no trade** | `بَدِيعُ` in the rendered text; sweep is genuinely complete at 4 occurrences, only 2 predicate Allah, and 6:101 is correctly rejected for its polemic continuation |
| 5 | **PASS, mildest finding in the batch** | 2:116 is a refuted claim, not a punishment; 2:118 is clean. Confirmed both |

**Ship verdict: SHIP.** Cleanest deck in the batch on the fetched evidence.

### `al-mubdi@1` (id 67)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 21:104 `بَدَأْنَآ`, 1st-pl., a completed act cited as security for a future one |
| 2 | **PASS** | the promise structure (`وَعْدًا عَلَيْنَآ`) is genuinely argumentative, not a bare attribute |
| 3 | **PASS mechanically**, **CONTESTED on (c)** | max shared run 4, function words only. (c): see §3 — this is the deck the task explicitly flags as riskiest, and I agree it is the thinnest separation in the trio |
| 4 | **PASS, no trade** | `بَدَأْنَآ` present. Root sweep (15, 2 forms) confirmed |
| 5 | **PASS** | 21:103's "greatest terror" confirmed inside a negation for the righteous; 21:105 clean |

**Found in this review:** the deck's own rejected-candidate table misattributes 32:7 to shipped `al-khaliq@1` ("cited in that draft") — verified false; 32:7 appears nowhere in the shipped deck (§1). Immaterial to this deck's own carrier (21:104), which does not depend on 32:7 being spent elsewhere, but it is a citation error and should be corrected on any respin.

**Ship verdict: SHIP**, with the 32:7 misattribution corrected and the trio-separation (§3) treated as a founder-level call, not a drafting defect.

### `al-baith@1` (id 59)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 2:56 `بَعَثْنَـٰكُم`, 1st-pl., a completed act |
| 2 | **PASS** | the sequence (death → revival → purpose stated after) is shown, not stated |
| 3 | **PASS** | max run 4, function words. (c): see §3 |
| 4 | **PASS, no trade** | `بَعَثْنَـٰكُم` and `يَبْعَثُ` both present |
| 5 | **CONTESTED — read closely, not deferred to the drafter** | See §4. I confirm the fetched facts the deck's own argument rests on (2:55 has no `عَذَاب`, no Fire, a named third party, a completed historical event) are accurate. I also confirm a real gap: the deck's successor sweep never fetches 22:6 (n−1 of the verse-beat citation) — benign in outcome but incomplete as documented (§1) |

**Ship verdict: SHIP**, bar 5 argument upheld on its own terms (see §4 for the close reading), with the 22:6 sweep gap noted as a documentation fix, not a register problem (22:6 is in fact clean).

### `al-muhyi@1` (id 69)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | `لَمُحْىِ ٱلْمَوْتَىٰ` at 30:50 and 41:39, both Allah as subject, confirmed live twice |
| 2 | **PASS** | "so observe... how He gives life... that same one will give life to the dead" — an argument from an observed process, not a bare attribute |
| 3 | **PASS mechanically** | catalogue-level id 59 collision (2-word Arabic / 3-word English run in the *duʿā only*) confirmed via the catalogue file directly, correctly kept off this deck's own authored prose |
| 4 | **PASS, no trade** | root present twice, independently |
| 5 | **PASS** | 30:51 and 41:40 both confirmed non-blocking (conditional and rhetorical-comparative respectively, neither reader-addressed, neither rendered) |

**Spine defect:** no `reflection` beat, confirmed (JSON has 8 beats, `bridge`/`name_intro`/3×`story`/`verse`/`dua`/`takeaway`, no `reflection`). Deck's own R2 stamp discloses this.

**Ship verdict: SHIP AFTER FIX** — sourcing is clean, but the missing `reflection` beat is a real completion gap per `DRAFTING-BRIEF.md` §5a (empty slot offline / on model failure / outside personalised tier). This is a one-beat fix, not a re-derivation.

### `al-mumeet@1` (id 70)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | Bukhārī 1339, Allah as the one who decides and names the term (`ثُمَّ الْمَوْتُ`), confirmed on the Arabic |
| 2 | **PASS** | a negotiated exchange with a real refusal and a real choice, not a stated attribute |
| 3 | **PASS mechanically**, independently reconfirmed | twin-diff against al-muhyi re-computed by me from scratch: max run 2 words (§1) |
| 4 | **PASS, via a disclosed trade** | root carried as a noun (`الْمَوْتِ`) in the ḥadīth rather than a Qur'anic finite verb; the doublet-formula sweep and its two exceptions spot-checked and confirmed (§1). This is a genuine trade, disclosed as such, and the brief requires the trade be *forced* — the sweep evidence for that is credible on what I checked, though I did not re-run the full 114-chapter regex myself |
| 5 | **CONTESTED — this is the hardest case in the batch, ruled without deferring to §7** | See §5 |

**Spine defect:** no `reflection` beat, confirmed, same shape as al-muhyi.

**Ship verdict: SHIP AFTER FIX**, contingent on (a) adding the `reflection` beat and (b) a founder-level read of §5's register call — the sourcing is sound but the *experience* question is a product call, not something a citation check can close.

---

## 3 · Bar 3(c) — the four "He starts things" Names, attacked directly

The task is right that this is the batch's central risk. Having read all six decks' actual rendered prose (not just their self-description), here is where I land:

- **Al-Khaliq** (shipped, for reference): process — seven finite verbs, stage by stage, "you were not arrived at by default." Not at risk from this batch; none of the six decks touches its verses.
- **Al-Bari**: **timing relative to a specific event.** 57:22 is not fundamentally about *how a thing begins* — it's about *when the record of it was fixed relative to when it happened*. The reader's problem it answers is "did my disaster slip past the plan," not "did anything begin." This is a genuinely different question from Badi's and Mubdi's, even though all three share the English word "precedence." I'd call this **holds up**, but it is the least intuitive of the three separations and depends on the reader tracking "register" vs. "origination" as different ideas — a real comprehension risk even if the textual distinction is sound.
- **Al-Badi**: **mode of origination — no material, no process.** 2:117's whole engine is the absence of an intermediate step. This is about *how* a thing comes to be (nothing to copy, nothing to build from), independent of *when* it was decreed (Bari) or *what it proves* (Mubdi). **Holds up cleanly** — it's the most textually distinctive of the three, because "Be, and it is" is a different grammatical object (an imperative-result pair) from either of the other two carriers.
- **Al-Mubdi**: **a first instance used as evidence for a second.** 21:104's structure is explicitly evidentiary/legal (`وَعْدًا عَلَيْنَآ`, "a promise binding upon Us") — the first beginning is cited *as proof* that a second is owed. This is not a claim about *how* origination happens (Badi) or *when* it was written (Bari); it's about what a completed first instance obligates. **Holds up**, but it is the thinnest of the three in practice, because the takeaway prose ("Whatever ended did not use up His capacity to begin") reads, to an ordinary user, very close to Badi's "what you cannot picture is not evidence about what is possible" — both cash out as "don't rule out a next attempt." I would not call this a collapse, but I would not certify it as obviously distinct to a reader either. **This is the item I'd send back for a founder read**, not because the Qurʾānic grounding is wrong (it isn't — all three carriers are real, distinct āyāt, verified above) but because the *reader-facing* separation is thinner than the *textual* separation the drafter measured.
- **Al-Baith**: **a discrete, one-time act on people already, historically, factually dead** — "nothing has to be salvageable first." This is a different kind of claim from all three above (they're about *origination*; this is about *restoration after total loss*, given as a completed historical event to a named third party). Clearly distinct from Bari/Badi/Mubdi. Its risk is against **Al-Muid** (restoration) and **Al-Muhyi** (life-giving), not against the origination cluster — and I find it holds up against both: Al-Muid's engine is grief-and-exchange (Umm Salama, a different *kind* of object may come back), Al-Muhyi's is an ongoing natural process taken as standing proof, and Al-Baith is a one-time, named-party, post-mortem act. Genuinely three different moves.
- **Al-Muhyi / Al-Mumeet**: not part of the "starts things" cluster at all (giving life to what exists / ending life), and independently confirmed via my own recomputation to share a maximum 2-word run with each other and to not overlap textually with the origination cluster.

**Bottom line on 3(c):** five of the six pass on genuine textual grounds I independently verified. The one I would flag as CONTESTED rather than PASS is **Al-Mubdi against Al-Badi** — not because either drafter fabricated or misquoted anything (both are clean on every fetch I ran), but because the *English takeaway prose*, read by an ordinary user with no Arabic and no access to the underlying grammar, is closer than the underlying āyāt are. This is exactly the kind of thing "no mechanical pass reaches" that the brief warns about, and it is a judgment call, not a sourcing defect.

---

## 4 · Al-Baith's bar-5 hazard, ruled directly (task item 4)

Fetched 2:54–2:57 in full (§1). The deck's own argument: 2:55 is a completed historical event, has a named third party (the Children of Israel at Sinai, via Mūsā's address), carries no `عَذَاب`, no Fire, and is never applied to the reader.

I read all four āyāt as the target reader (someone at 11pm who has written some part of themselves off). The thunderbolt (`ٱلصَّـٰعِقَةُ`) is graphic — a group of people killed on the spot for demanding to see Allah outright. But: it is narrated entirely in third person, past tense, about a specific historical group's specific demand; nothing in the rendered beat instructs or accuses the reader; and the very next clause — "Then We revived you after your death" — is the reason the scene is there. **I agree with the deck (and R2) that this passes**: the strike is not gratuitous, it is load-bearing for the Name's own demonstration, and removing it would leave "revived" with nothing to revive. The register is closer to "an old story, told plainly" than to a warning. I would still flag it to a founder as the single most viscerally intense beat in this batch — "a thunderbolt took them while you were looking on" is stronger imagery than anything else across the six decks — but on the brief's actual five-bars test (no rebuke of the reader, no Fire, no accusation) it passes, and I did not find grounds to overturn it.

---

## 5 · Al-Mumeet's bar 5, ruled as the named reader, not deferring to §7 (task item 6)

Confirmed independently: Bukhārī 1339 is real, ṣaḥīḥ by collection (no separate printed grade — verified by inspecting the raw page for a "Grade" tab payload and finding none, which is the correct expectation for Bukhārī), and the Arabic supports every clause the deck renders, including the one disclosed inferential step ("there, close to it, he died," which the narration implies via the Prophet's ﷺ closing remark about the grave rather than stating outright).

Reading it as the named reader — someone reached at night, possibly grieving or afraid, by a Name that means "The Bringer of Death":

- The narrative is not softened. An angel physically struck (`صَكَّهُ`, translated "slapped... severely, spoiling one of his eyes") and blinded is a startling image to put in front of someone already afraid of death — even though it is Mūsā striking the angel, not the reverse, and even though the eye is restored in the next line. A reader skimming without care could misread who does what to whom in the first sentence.
- The "offer": years of life counted in strands of ox-hair, declined in favor of an earlier death near sacred ground. For a reader who is *not* ready to go, or who is actively fighting for more time (illness, a dying relative), a prophet's choice to decline extension could land as implicitly prescriptive — "the righteous thing is not to want more time" — even though the deck's takeaway is careful to frame it as Mūsā's own choice ("Not more time. Just better ground to meet it on") rather than an instruction.
- 63:11 — "never will Allah delay a soul when its time has come" — is a flat statement of inevitability with no comfort clause attached on this beat. It is true and unthreatening in the literal five-bars sense (no rebuke, no Fire, no accusation), but it is also the least softened verse-beat in this entire batch: nothing on the beat answers the anxiety the statement could provoke in someone who is afraid.
- What the deck gets right, and what I confirm holds: no invented reassurance, no "you'll die well," no fear-mongering, no direct address blaming the reader, no Fire/Judgment language anywhere. The duʿā (a good ending, not more time) is the catalogue's own, unmodified.

**My ruling:** this deck **passes the five bars as literally stated** — I found no rebuke, no Fire, no Judgment adjacency, no accusation on any rendered beat. But I do not think it should ship on a mechanical PASS alone. The risk is not textual, it is experiential: this is the one Name in the 99 whose plain meaning is "the one who ends your life," delivered by an app that explicitly targets a distressed user at night, and the deck's dignity-not-comfort register (deliberate, per §6 of the draft) is a genuine, defensible design choice — but it is a **founder-level call about what this app is willing to put in front of someone in acute grief or fear**, not something a citation check can close out. I am marking bar 5 **CONTESTED**, not FAIL and not PASS, and recommending it be read by a human before ship, ideally alongside a support contact / "if you need someone to talk to" pattern if one exists elsewhere in the app for acute-distress moments — that is outside this review's scope to design, but worth naming.

---

## 6 · What I could not verify

1. **The full 114-chapter, 6,236-āyah regex sweep behind al-mumeet's/al-muhyi's doublet-formula claim (16/16, two exceptions)** — I spot-checked 5 of the 16 paired āyāt and both disclosed exceptions (2:259, 80:21), all of which came back exactly as claimed. I did not re-run the sweep itself across all 114 chapters; I have no way to rule out a missed 17th occurrence without doing so.
2. **`al-awwal@1` and `al-ahad@1`'s actual current beat structure** — both are cited by decks in my batch (al-mubdi claims 21:104 is "cited but not rendered" in al-awwal; al-badi claims al-ahad "deliberately elided" 2:117's first clause) as reasons a citation is free. Neither file is in my batch; I could not open them to confirm these claims independently. They are reported here as **unverified inputs to my verdict**, not as things I confirmed.
3. **Whether al-mubdi@1's carrier (21:104) is still free at the moment this verdict is read** — the deck itself names this as its most fragile dependency (two sibling drafts not moving). I have no way to check drafts outside my assigned batch for changes made after this review started.
4. **Whether the 22:6 gap in al-baith's successor sweep (§1) is the only such gap in the batch** — I checked n±1 for every citation I could identify as a "carrier" or "verse beat," but I did not re-derive n±1 for every one of the ~35 āyāt touched (e.g. n±1 of 30:47–41:40's own individual sub-citations beyond what the deck already fetched). I consider the citations I did check representative, not exhaustive.
5. **Product-level appropriateness of al-mumeet's register** (§5) — I have given my reading as the named distressed-at-night user, but this is inherently a judgment call about what the app should say to someone grieving, not a fact I can resolve by fetching a URL. Flagged, not resolved.
6. **al-badi's claim that its corpus sweep is "the second-shortest in the project"** and similar comparative claims about the rest of the 99-Name project outside my six decks — not checked, immaterial to any bar.
7. I did **not** attempt to independently verify the `.context/claims/` cross-checks any deck makes (e.g. al-muhyi's claim to have grepped 9 newly-added claim files for specific strings) — these are process claims about another agent's filesystem state at a point in time I cannot reproduce.

---

## 7 · One correction to the task brief itself

Task item 1 lists `al-musawwir@1` among "shipped" decks alongside `al-khaliq@1`, `al-muid@1`, `al-qadir@1`, `al-baqi@1`, `al-qayyum@1`. **I checked `assets/content/name_stories.json` directly: it contains 45 decks, and `al-musawwir@1` is not among them** — only the other five are shipped. `al-musawwir@1` is still a `*-DRAFT.md` file (currently R1, verified, not founder-signed into the asset). This doesn't change any of my rulings above (I read the draft anyway, since three of my six decks reason against it), but the premise that it's already shipped is factually wrong, and I did not want to silently inherit it.

Also worth flagging: task item 2's framing — "every Qurʾānic occurrence of one Name's root contains the other's" (ب-د-أ / ع-و-د) — is **not literally true**. I fetched the full `bdA` corpus listing and checked 9:13 ("they had begun the attack upon you the first time" — human, no `يعيد`), 29:20 ("observe how He began creation. Then Allah will produce the final creation" — uses `يُنشِئُ`, root `ن-ش-أ`, not `يعيد`), and 32:7 ("began the creation of man from clay" — no repeat-verb in the same clause). None of these three pairs the two roots. The **narrower** claim — that every āyah where Allah's *beginning of creation* is paired with a promise to *repeat* it uses both roots in one clause (30:27, 10:4, 10:34 ×2, 27:64, 29:19, 30:11, 85:13, 21:104) — **is** true and is what `al-mubdi@1`'s own draft actually claims, more carefully than the task brief's summary of it.

---

## 8 · Reconciliation with `2026-08-04-R2-VERIFICATION.md`

Read in full after the verdict above was written, as instructed. That document covers all 54 pending drafts (mine plus 48 others); its author is largely the same author as the drafts, and it says so itself (§0). Where it touches my six decks:

**Where I agree:**

- **`al-bari@1`'s 57:23 fix (R2 §2.6).** R2 reports the "so that" → "In order that" correction. I independently fetched 57:23 live and confirmed the *current* draft text already reads "In order that you not despair" — the fix is in place and correct against today's `translations=20`.
- **`al-baith@1`'s bar-5 hazard, "upheld" (R2 §4).** R2's one-paragraph ruling on 2:55 — completed historical event, named third party, no `عَذَاب`, no Fire, no reader-address, and 2:56 is the whole point of putting it there — is the same shape of argument I independently built from the same four fetched āyāt (§4 above). I did not defer to R2 to reach this; I fetched 2:54–2:57 myself before reading R2 at all. Where I go further than R2: I flagged the thunderbolt's imagery as the single most viscerally intense beat in the batch and worth founder attention even though it passes the literal test — R2 states the pass without that caveat.
- **19 decks missing `reflection`, including `al-muhyi@1` and `al-mumeet@1` (R2 §5).** Confirmed independently by reading both JSON blocks directly; matches.
- **Tirmidhī 2307's grade, "Hasan (Darussalam)" (R2 §3, listed generally as `Ṣaḥīḥ`/`Hasan` sources spot-checked elsewhere in R2's table, though R2's own table does not list Tirmidhī 2307 by name).** I fetched and read the grade line myself; R2 does not specifically enumerate this one in its table (its §3 table lists other decks' ḥadīth, not this one, and separately notes in §3's prose that al-mumeet's *duʿā* — not its `hadith` field — is unlocatable). No conflict, just a gap in R2's own table that I filled.
- **The retrieval-limit framing for al-mumeet's duʿā (R2 §3, "correctly stated as a limit and not a proof").** Matches the deck's own §1 and my own reading — `source: ""`, not entered into `renderedDuaSources`, correctly treated as an absence-of-evidence, not evidence-of-absence.

**Where I disagree, or go further than R2:**

- **R2 never examines `al-badi@1`, `al-mubdi@1`, or `al-muhyi@1` in any detail.** Its worked examples (§2, §3, §4) are entirely about *other* decks in the 54-deck sweep (majeed, majid, mateen, qawiyy, khabeer, hakeem, wajid, barr, jami, muizz, etc.) — three of my six decks are not mentioned by name anywhere except the missing-`reflection` list. R2's headline claim ("54 verified") is therefore not a claim it demonstrates for half of my batch; it is a claim I had to verify from zero for `al-badi@1`, `al-mubdi@1`, and `al-muhyi@1`, which I did (§1–§2 above).
- **R2 does not catch the `al-mubdi@1` → `al-khaliq@1` (32:7) misattribution I found (§1, §2).** This is a small thing — it doesn't touch any bar — but it is exactly the class of "citation doesn't match what's actually in the cited file" defect R2's own §2.1 (the al-majeed 11:73/85:15 mix-up) says the pipeline is supposed to catch by *opening the other file*, not by reading the claim. R2 opened `al-khaliq@1` for other purposes elsewhere in its own audit trail but did not cross-check this specific claim against it.
- **R2 states no register concern about `al-mumeet@1` beyond confirming sourcing.** Its §2/§3/§4 never engage with the *experience* of the ḥadīth (the eye-striking image, the declined-years framing, 63:11's flat inevitability) — its scope is explicitly sourcing fidelity, not register-as-read-by-a-distressed-user (§0 says so: "bar-5 register calls" are named as things "not reliable" in R2, still owed to a blind verifier). I did that reading in §5 above and reached a **CONTESTED**, not a clean pass — this is the one place I actively push past where R2 stops, per its own stated scope.
- **R2's "8 defects, 1 completion gap" headline undercounts what a from-scratch fetch finds in my batch alone**, once you count: the 32:7 misattribution (new, this review), the missing 22:6 successor-sweep fetch on `al-baith@1` (new, this review), and the two `reflection`-beat gaps (which R2 does count, just not as "defects" — it calls them a separate, deliberately-deferred category). None of these are severe — nothing here rises to R2's own P0 example (`al-majeed@1`'s misquoted citation) — but "zero new findings" would have been the wrong thing to report, and R2 itself would presumably agree, since its own §0 explicitly disclaims being the adversarial pass and asks for exactly this kind of second look.

**Net:** R2 and I agree on every claim it actually makes about my six decks. We diverge mainly by scope — R2 spent its attention on the other 48 drafts and left three of mine essentially unaudited by name, and R2's stated mandate never included the register-as-lived-experience question that task item 6 asked me to rule on directly.
