# Verdict — batch `judgment-four` (47 Al-Hakam · 48 Al-Adl · 55 Al-Haseeb · 90 Al-Muqsit)

**Blind adversarial verification, 2026-08-04.** I did not write these decks. Every citation below was fetched live during this review from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com/qurandictionary.jsp`. Nothing was recalled or reconstructed. Where I write "confirmed," I mean I fetched it myself and it matched; where I write a discrepancy, I fetched it myself and it did not.

---

## 1 · Citation table — every fetch, what it actually says

| Claim (as it reaches a beat / an argument) | Source fetched | Text returned | Verdict |
|---|---|---|---|
| Duʿā fragment 1: `ٱفْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِٱلْحَقِّ وَأَنتَ خَيْرُ ٱلْفَـٰتِحِينَ` claimed nearest to 7:89 | `.../7:89` | `رَبَّنَا ٱفْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِٱلْحَقِّ وَأَنتَ خَيْرُ ٱلْفَـٰتِحِينَ` — "Our Lord, decide between us and our people in truth, and You are the best of those who give decision." Reported human speech (Shuʿayb's followers). | ✅ matches claim exactly; root is `ف-ت-ح`, not `ح-ك-م` |
| Duʿā fragment 2: `خَيْرُ ٱلْحَـٰكِمِينَ` claimed nearest to 7:87 | `.../7:87` | `...حَتَّىٰ يَحْكُمَ ٱللَّهُ بَيْنَنَا ۚ وَهُوَ خَيْرُ ٱلْحَـٰكِمِينَ` — third person `وَهُوَ` | ✅ matches claim |
| same, claimed nearest to 10:109 | `.../10:109` | `...حَتَّىٰ يَحْكُمَ ٱللَّهُ ۚ وَهُوَ خَيْرُ ٱلْحَـٰكِمِينَ` — third person | ✅ matches claim |
| same, claimed nearest to 12:80 | `.../12:80` | `...أَوْ يَحْكُمَ ٱللَّهُ لِى ۖ وَهُوَ خَيْرُ ٱلْحَـٰكِمِينَ` — third person | ✅ matches claim |
| **Conclusion: no āyah contains `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` verbatim** | all four above | second-person `وَأَنتَ` never occurs with this verb/root in any of the four; verb root is swapped in 7:89, person is swapped in the other three | ✅ **composite confirmed — `source: ""` is correct on all four decks** |
| Al-Hakam beats 3–5: 22:56 | `.../22:56` | `ٱلْمُلْكُ يَوْمَئِذٍ لِّلَّهِ يَحْكُمُ بَيْنَهُمْ ۚ فَٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ فِى جَنَّـٰتِ ٱلنَّعِيمِ` | ✅ rendered verbatim, matches |
| n−1: 22:55 | `.../22:55` | `...عَذَابُ يَوْمٍ عَقِيمٍ` — "punishment of a barren Day" | ⚠️ confirmed punishment |
| n+1: 22:57 | `.../22:57` | `...فَأُو۟لَـٰٓئِكَ لَهُمْ عَذَابٌ مُّهِينٌ` — "a humiliating punishment" | ⚠️ confirmed punishment — **22:56 is sandwiched on both sides, as claimed** |
| Al-Hakam beat 6: 95:8 | `.../95:8` | `أَلَيْسَ ٱللَّهُ بِأَحْكَمِ ٱلْحَـٰكِمِينَ` | ✅ matches, whole āyah |
| n+1 of 95:8 | `.../95:9` | HTTP 404 | ✅ confirmed sūrah-final |
| Al-Adl beats 3–5: 4:40 | `.../4:40` | `إِنَّ ٱللَّهَ لَا يَظْلِمُ مِثْقَالَ ذَرَّةٍ ۖ وَإِن تَكُ حَسَنَةً يُضَـٰعِفْهَا وَيُؤْتِ مِن لَّدُنْهُ أَجْرًا عَظِيمًا` | ✅ matches, whole āyah |
| n−1: 4:39 | `.../4:39` | closes `...وَكَانَ ٱللَّهُ بِهِمْ عَلِيمًا` | ✅ clean, confirmed |
| n+1: 4:41 | `.../4:41` | witnesses brought from every nation, no punishment | ✅ clean, confirmed |
| Al-Adl beat 6: 6:115 | `.../6:115` | `وَتَمَّتْ كَلِمَتُ رَبِّكَ صِدْقًا وَعَدْلًا ۚ لَّا مُبَدِّلَ لِكَلِمَـٰتِهِۦ ۚ وَهُوَ ٱلسَّمِيعُ ٱلْعَلِيمُ` | ✅ matches, first clause rendered, ellipsis at the edge |
| Al-Haseeb/Al-Muqsit shared carrier: 21:47 | `.../21:47` | `وَنَضَعُ ٱلْمَوَٰزِينَ ٱلْقِسْطَ لِيَوْمِ ٱلْقِيَـٰمَةِ فَلَا تُظْلَمُ نَفْسٌ شَيْـًٔا ۖ وَإِن كَانَ مِثْقَالَ حَبَّةٍ مِّنْ خَرْدَلٍ أَتَيْنَا بِهَا ۗ وَكَفَىٰ بِنَا حَـٰسِبِينَ` | ✅ matches; the āyah's own `ۖ` sits exactly where Al-Muqsit stops and Al-Haseeb begins — **the split is clean, neither renders the other's clause** |
| n−1 of 21:47: 21:46 | `.../21:46` | `...عَذَابِ رَبِّكَ لَيَقُولُنَّ يَـٰوَيْلَنَآ` — "punishment of your Lord... O woe to us" | ⚠️ confirmed punishment (single-sided; n+1 is clean) |
| n+1: 21:48 | `.../21:48` | Mūsā and Hārūn given the criterion, no punishment | ✅ clean, confirmed |
| Al-Haseeb beat 6: 4:86 | `.../4:86` | `...إِنَّ ٱللَّهَ كَانَ عَلَىٰ كُلِّ شَىْءٍ حَسِيبًا` | ✅ matches, closing clause, ellipsis at front |
| n−1 of 4:86: 4:85 | `.../4:85` | closes `...مُّقِيتًا` (Al-Muqeet's root), no punishment | ✅ clean, confirmed |
| n+1: 4:87 | `.../4:87` | Day-of-Resurrection assembly, no punishment | ✅ clean, confirmed |
| Al-Muqsit beat 6: 3:18 | `.../3:18` | `شَهِدَ ٱللَّهُ أَنَّهُۥ لَآ إِلَـٰهَ إِلَّا هُوَ وَٱلْمَلَـٰٓئِكَةُ وَأُو۟لُوا۟ ٱلْعِلْمِ قَآئِمًۢا بِٱلْقِسْطِ ۚ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ` | ✅ deck renders exactly the four words `قَآئِمًۢا بِٱلْقِسْطِ` = "maintaining [creation] in justice," matches Saheeh, ellipsis both sides, no splice |
| Corpus sweep `Hkm` | `corpus.quran.com/qurandictionary.jsp?q=Hkm` | "occurs 210 times... in 13 derived forms" | ✅ confirmed, 210 and 13 forms both match |
| Corpus sweep `Edl` | `.../qurandictionary.jsp?q=Edl` | "occurs 28 times... in two derived forms" — 14 verb, 14 noun | ✅ confirmed; **I independently re-derived "24 distinct āyāt" by counting the listed refs myself and it checks out exactly (13 distinct verb āyāt + 12 distinct noun āyāt − 1 overlap at 6:70 = 24)** |
| Corpus sweep `Hsb` (Al-Haseeb's actual root, ح-س-ب) | `.../qurandictionary.jsp?q=Hsb` | "occurs 109 times... in eight derived forms" | ✅ confirmed, matches claim exactly |
| Corpus sweep `qsT` | `.../qurandictionary.jsp?q=qsT` | "occurs 25 times... in five derived forms" | ✅ confirmed |
| 6:114, the Name-form `حَكَمًا` | `.../6:114` | `[Say], "Then is it other than Allāh I should seek as judge..."` — Quran.com's own bracketed `[Say]` marks this as continued Qul-instructed speech | ✅ confirmed, `قُلْ`-ladder classification is correct |
| **New fetch, not in any draft — 16:124 (Hkm candidate)** | `.../16:124` | `وَإِنَّ رَبَّكَ لَيَحْكُمُ بَيْنَهُمْ يَوْمَ ٱلْقِيَـٰمَةِ فِيمَا كَانُوا۟ فِيهِ يَخْتَلِفُونَ` — "your Lord will judge between them on the Day of Resurrection concerning that over which they used to differ" | see §3 below — **finding** |
| n−1: 16:123 | `.../16:123` | following Abraham's religion, no punishment | ✅ clean |
| n+1: 16:125 | `.../16:125` | "Invite to the way of your Lord with wisdom and good instruction... argue with them in the best way" | ✅ clean — **no punishment on either side** |
| **New fetch — 22:69 (Hkm candidate, same sūrah as the chosen carrier)** | `.../22:69` | `ٱللَّهُ يَحْكُمُ بَيْنَكُمْ يَوْمَ ٱلْقِيَـٰمَةِ فِيمَا كُنتُمْ فِيهِ تَخْتَلِفُونَ` | see §3 below — **finding** |
| n−1: 22:68 | `.../22:68` | "if they dispute with you, say Allah is most knowing of what you do" | ✅ clean |
| n+1: 22:70 | `.../22:70` | "Do you not know that Allah knows what is in the heaven and earth..." | ✅ clean — **no punishment on either side** |
| checked and rejected as worse: 2:113 | `.../2:113`, `.../2:114` | n+1 (2:114) closes `...عَذَابٌ عَظِيمٌ` | confirmed weaker than 16:124/22:69 |
| checked and rejected as worse: 4:141 | `.../4:140`, `.../4:142` | n−1 references gathering hypocrites/disbelievers in Hell; n+1 accuses hypocrites of trying to deceive Allah | confirmed weaker |
| al-wakeel@1 (shipped) actually cites 65:3 and 3:173 | `assets/content/name_stories.json` | verse beat source `Qur'an 65:3`; dua beat source `Qur'an 3:173` | ✅ confirms Al-Haseeb's "already spent" claim |
| al-qabid@1 (shipped) dua beat `source` | `assets/content/name_stories.json` | `"source": ""` | ✅ confirms the empty-source precedent cited by all four decks |
| 45-deck count | `assets/content/name_stories.json` | `len() == 45` | ✅ confirmed exactly |
| Collectible-names fields for ids 47/48/55/90 | `assets/content/collectible_names.json` | `english`, `arabic`, `lesson`, `dua_arabic`, `dua_translation` | ✅ all four decks render `english` (not `meaning`) byte-for-byte in `name_intro`; the duʿā string is byte-identical across all four; `lesson` quotes match the group doc verbatim |

**No ḥadīth beats exist in any of the four decks; `sunnah.com` was correctly never queried by the drafters, and I did not query it either — there is nothing to grade a printed grade line against in this batch.**

---

## 2 · The group-wide bar-5 ruling — **I accept it**, and here is the beat-by-beat check that earns that acceptance

The ruling: *"Judgment as the reader's vindication is in register; Judgment as the reader's peril is not,"* enforced by (1) no beat renders punishment/`عَذَاب`/Fire/`ٱلَّذِينَ كَفَرُوا۟`, (2) the reader is never the defendant, (3) where a neighbour turns to punishment the beat stops at the āyah boundary and discloses it.

I read every rendered beat of all four decks against these three tests myself (not the drafters' tables):

- **Al-Hakam** — bridge/story/verse/duʿā/takeaway/reflection: no punishment word anywhere; reader is "the ones who waited without ever being heard," positioned as the wronged party awaiting vindication, never as the accused.
- **Al-Adl** — no punishment word; the reader's own "ledger against yourself" (bridge) is self-directed anxiety, not an external accusation, and the takeaway explicitly reassures ("the slope runs toward you").
- **Al-Haseeb** — no punishment word; the reader is relieved of the burden of proof ("no case for you to build"), which is the opposite of defendant framing.
- **Al-Muqsit** — no punishment word; the reader is reassured the scale is set before they are judged, positioned as beneficiary of structural fairness, not as someone facing a case.

**I verified this claim myself rather than trusting the drafters' tables, and it holds on all four decks.** The ruling is a genuine, defensible reading of the bar's stated purpose ("do not frighten, do not accuse") rather than a mechanical application of its wording, and — this matters — it was tested against the *actual rendered English*, not against the underlying āyāt's wider context (which the bar was never asking to be clean; the bar asks about what reaches the reader).

**I accept the ruling for the group as a whole.** I am not rejecting all four. But acceptance of the ruling is not the same as accepting every individual carrier choice — see Al-Hakam specifically in §3, where I find that the ruling was used to *tolerate* a bar-5 weakness that a more thorough sweep would have made unnecessary to tolerate at all.

---

## 3 · The finding that matters most: a better carrier for Al-Hakam exists in the un-enumerated part of `Hkm`

The group file states, honestly, that the 210-occurrence `Hkm` root "was not exhaustively enumerated" and names this "the likeliest place a better carrier was missed." **I spent real effort here, and the risk they flagged materialised.**

Reading further into the `corpus.quran.com` form-I verb list (45 occurrences), two other āyāt place Allah (or "your Lord") as the explicit subject of a future/narrated judging act, in the identical Judgment-Day register as 22:56, and I fetched both their successor pairs:

- **16:124** — `وَإِنَّ رَبَّكَ لَيَحْكُمُ بَيْنَهُمْ يَوْمَ ٱلْقِيَـٰمَةِ فِيمَا كَانُوا۟ فِيهِ يَخْتَلِفُونَ` ("your Lord will judge between them..."). **n−1 (16:123) and n+1 (16:125) are both clean — no punishment on either side.** 16:125 is in fact "Invite to the way of your Lord with wisdom and good instruction," which is about as gentle a neighbour as this project has anywhere.
- **22:69** — `ٱللَّهُ يَحْكُمُ بَيْنَكُمْ يَوْمَ ٱلْقِيَـٰمَةِ فِيمَا كُنتُمْ فِيهِ تَخْتَلِفُونَ` — near-identical wording to 22:56, **thirteen āyāt later in the very same sūrah**, and both its neighbours (22:68, 22:70) are clean.

Both candidates would have eliminated Al-Hakam's "worst bar-5 in the group" status entirely — not through the vindication/peril carve-out in §2, but by simply not having punishment adjacent at all.

**This is not a free win, and I want to be precise about the trade-off rather than just declare a fix.** 22:56's strength on bar 2 ("shown, not stated") comes specifically from its second clause — `فَٱلَّذِينَ ءَامَنُوا۟ وَعَمِلُوا۟ ٱلصَّـٰلِحَـٰتِ فِى جَنَّـٰتِ ٱلنَّعِيمِ`, a narrated consequence. Neither 16:124 nor 22:69 has that; both are bare declarative promises ("your Lord will judge... concerning what they differed over") with no attached outcome clause in the same āyah. So the honest framing is: **the current carrier trades bar-5 cleanliness for bar-2 strength, and the trade was never examined because the sweep that would have surfaced it was explicitly skipped.** That is a real gap, not a hypothetical one — I found the candidates by reading maybe a third of the 45-occurrence verb-form list.

**Verdict on this point: I do not accept "22:56, disclosed" as good enough as currently argued.** The drafters' own bar-5 defense rests entirely on the group ruling in §2 tolerating adjacency — but that defense was never tested against the alternative of simply not needing to invoke the ruling at all. A subsequent drafter should be required to weigh 16:124/22:69 against 22:56 explicitly (bar 2 vs. bar 5) before this deck ships, not have that comparison skipped because the root was too large to enumerate.

---

## 4 · Al-Adl's bar-4 trade — verified forced, with two disclosure gaps

I fetched the full `Edl` occurrence list (28 entries) and independently classified every one by subject and sense, rather than checking the drafters' summary against itself.

**The trade holds.** Across all 14 noun occurrences of `ʿadl`, only 6:115 (`صِدْقًا وَعَدْلًا`, "the Word of your Lord has been fulfilled... in justice") attaches the noun to Allah's own decree in a positive sense; the rest are either compensation/ransom language, instructions to humans, or descriptions of human witnesses' character. Across the 14 verb occurrences, none has Allah as the subject of `ʿadala` in the "act justly" sense — the closest, 6:1/6:150/27:60 (`يَعْدِلُونَ بِرَبِّهِمْ`), are the disbelievers ascribing equals *to* their Lord, not Allah acting. **6:115 is genuinely the only place `ٱلْعَدْل` describes something Allah does, and the trade to a separate verse beat is forced, not preferred**, exactly as claimed.

**Two things I found that the draft did not disclose, neither of which changes the verdict:**

1. **The draft's own phrasing is imprecise.** It describes 6:1/6:150/27:60 as "the occurrences with Allah as subject" that "carry the negative sense." Grammatically this is backwards — the disbelievers (`ٱلَّذِينَ كَفَرُوا۟`) are the subject of `يَعْدِلُونَ`; "their Lord" is the object of comparison, not the actor. The conclusion the sentence is used for (these are not usable, positive, Allah-as-agent occurrences) is still correct, but the grammar description is wrong. Cosmetic, but worth fixing before this ships, because it is exactly the kind of small mischaracterization the standing failure catalogue warns about.
2. **82:7 was never mentioned.** `فَعَدَلَكَ` ("and proportioned/balanced you," from `خَلَقَكَ فَسَوَّاكَ فَعَدَلَكَ`) has Allah as the explicit grammatical subject of the verb `ʿadala`, in a positive sense — the one true omission from the draft's binary "negative sense / command to humans" framing of the 14 verb occurrences. It does not change the trade's outcome: 82:7's `ʿadala` means "to make symmetrical/proportion a body in creation," a different semantic domain from judicial justice, and it would be a weaker, more confusing carrier for "The Just" than 6:115. But it should be added to the rejected-candidates table for completeness, since the draft's claim of having swept "the ones with Allah as subject" is not, in fact, complete.

**Both are minor and do not block shipping**, but both should be corrected in a revision pass.

---

## 5 · The 21:47 split (Al-Muqsit/Al-Haseeb) and the Al-Haseeb/al-muhsi@1 separation

**21:47 split:** confirmed clean at the source. The āyah's own `ۖ` sits exactly between `فَلَا تُظْلَمُ نَفْسٌ شَيْـًٔا` (end of Al-Muqsit's clause) and `وَإِن كَانَ مِثْقَالَ حَبَّةٍ...` (start of Al-Haseeb's clause). I read both drafts' rendered beat text directly, not just the boundary claim, and neither deck's English or Arabic beats contain any word from the other's clause. **Verified, no finding.**

**Al-Haseeb / al-muhsi@1 (id 66) separation:** I read the full `al-muhsi@1` draft as instructed. Its own bar 3(c) section identifies its nearest dangerous neighbour as `al-ghafur@1` and does not even mention Al-Haseeb by name in its "watching family" comparison table, despite both being drafted in the same session — a real omission on `al-muhsi@1`'s side, though not one that changes my ruling here. The distinction Al-Haseeb's own draft argues — *Al-Muhsi is about the record's granularity (nothing rounded off, in either direction); Al-Haseeb is about the reader's burden of proof (`كَفَىٰ`, "sufficient," so nothing more is needed from the reader)* — is a real, textually grounded distinction and not a synonym pair. `أَحْصَيْنَـٰهُ فِى إِمَامٍ مُّبِينٍ` ("enumerated in a clear register") and `وَكَفَىٰ بِنَا حَـٰسِبِينَ` ("sufficient are We as accountant") are doing different work: one is a claim about the record's completeness, the other about who has to produce evidence. **I rule this CONTESTED-BUT-ACCEPTABLE** — it is thin, exactly as both drafts admit, and it deserves a second independent re-argument before the wave ships (both flagged it themselves as "re-argue from scratch, don't check the paragraph"), but on my own re-argument, the distinction holds. It is not a mechanical measurement failure — max shared word-run of 3 is correctly reported as *not* dispositive here, per §9cd, and I found no shared rendered text or engine collapse when I read both decks side by side.

---

## 6 · Per-deck five-bars verdict

### 47 Al-Hakam

| bar | verdict | evidence |
|---|---|---|
| 1 · demonstrated in Allah's words | ✅ PASS | 22:56 `يَحْكُمُ بَيْنَهُمْ`, confirmed finite verb, Allah the narrated subject |
| 2 · shown not stated | ✅ PASS | narrated outcome clause present, confirmed |
| 3 · no sibling collapse | ✅ PASS | (a) confirmed disjoint from siblings; (b) 45-deck count confirmed, max run 3; (c) engine is genuinely distinct — "whether a verdict is delivered at all," confirmed by my own read |
| 4 · root in quoted text | ✅ PASS, no trade | `يَحْكُمُ` and `بِأَحْكَمِ ٱلْحَـٰكِمِينَ`, both confirmed |
| 5 · register and reverence | ⚠️ **CONTESTED** | 22:56 confirmed sandwiched by punishment on both sides (22:55, 22:57); group ruling in §2 is accepted as a general matter, but **a cleaner carrier (16:124 or 22:69) exists and was not properly weighed against the current one — see §3** |

**Ship/no-ship: NO-SHIP AS DRAFTED.** Not because the group's bar-5 doctrine is wrong, but because this specific deck's justification for needing that doctrine at all has not been shown to be necessary. **Fix:** before shipping, explicitly evaluate 16:124 and 22:69 as replacement or co-carriers for beats 3–5, weighing their bar-2 weakness (no narrated outcome clause) against their bar-5 strength (zero punishment adjacency, either side). If 22:56 is kept after that comparison, say so and say why bar 2 was judged to outweigh bar 5 — that argument does not currently exist in the draft.

### 48 Al-Adl

| bar | verdict | evidence |
|---|---|---|
| 1 | ✅ PASS | 4:40 `لَا يَظْلِمُ`, confirmed |
| 2 | ✅ PASS | atom's-weight vs. multiplier asymmetry, confirmed in the fetched text |
| 3 | ✅ PASS | (b) 45-deck count confirmed; (c) "asymmetric accounting" engine confirmed distinct |
| 4 | ✅ PASS by forced trade | independently re-derived from the full 28-entry sweep; trade confirmed forced (§4 above), two minor disclosure gaps found (grammar description, 82:7) |
| 5 | ✅ PASS | 4:39/4:41 both confirmed clean |

**Ship/no-ship: SHIP**, with a minor, non-blocking revision requested: fix the "Allah as subject" grammar mischaracterization for 6:1/6:150/27:60, and add 82:7 to the rejected-candidates table.

### 55 Al-Haseeb

| bar | verdict | evidence |
|---|---|---|
| 1 | ✅ PASS | 21:47c `أَتَيْنَا بِهَا`, confirmed first-person-plural narrated act |
| 2 | ✅ PASS | counterfactual with stated magnitude, confirmed |
| 3 | ⚠️ CONTESTED-BUT-ACCEPTABLE | (a)/(b) confirmed clean; (c) al-muhsi@1 separation thin but holds on independent re-argument — §5 above |
| 4 | ✅ PASS, no trade | `حَـٰسِبِينَ` and `حَسِيبًا`, both confirmed |
| 5 | ⚠️ CONTESTED | n−1 (21:46) confirmed punishment; n+1 clean. Single-sided, milder than Al-Hakam's; covered by the accepted group ruling |

**Ship/no-ship: SHIP.** The al-muhsi separation and the single-sided bar-5 exposure are both disclosed honestly and both survive independent re-testing, even though both are correctly flagged as the deck's soft points.

### 90 Al-Muqsit

| bar | verdict | evidence |
|---|---|---|
| 1 | ✅ PASS | 21:47a `نَضَعُ`, confirmed |
| 2 | ✅ PASS | order-of-operations narration (scale placed before Day arrives), confirmed |
| 3 | ✅ PASS | (a)/(b) confirmed; (c) "instrument set before the case is called" is a genuinely distinct engine |
| 4 | ✅ PASS, no trade | `ٱلْقِسْطَ` and `بِٱلْقِسْطِ`, confirmed |
| 5 | ⚠️ CONTESTED | same 21:46/21:48 pattern as Al-Haseeb — single-sided, covered by the accepted group ruling |

**Ship/no-ship: SHIP.** 3:18's four-word truncation (`قَآئِمًۢا بِٱلْقِسْطِ`) reads as a complete, grammatically self-sufficient clause and matches Saheeh exactly; I do not find it too thin to stand as a verse beat.

---

## 7 · What I could not verify

1. **I did not re-run the full pending-drafts n-gram sweep** claimed in each deck's bar 3(b) section (checked against "all 26 pending drafts"). I spot-checked two specific claims (65:3/3:173 already spent by shipped `al-wakeel@1`) and both confirmed, but I did not independently grep the other ~25 pending draft files for the āyāt this batch uses. This is the same standing gap the drafters themselves flag.
2. **I did not exhaustively enumerate all 210 `Hkm` occurrences.** I read roughly the first third of the form-I verb list (through occurrence ~45 of 210) and found two strong candidates within it. I have not checked the noun forms (`ḥukm`, 30×; `ḥikmah`, 20×; `ḥakīm`, 97×) for any additional Allah-as-subject candidates beyond what the group already used. Given `ḥakīm` is overwhelmingly the adjectival "Wise" (a different Name's ground, Al-Hakeem, id 26), I judge this a low-yield area, but I have not fetched it to confirm that judgment.
3. **I did not independently verify the `.context/claims/47-48-55-90.md` file** — the brief's hard constraints do not forbid reading it, but I did not locate or open it, since none of the four verdicts here turn on what it says versus what I could verify directly from scripture and the shipped/pending assets.
4. **I could not confirm "17 pending drafts" cite 65:3** (Al-Haseeb's rejected-candidates claim) — I confirmed the shipped-asset half (al-wakeel@1) but did not grep all pending drafts for the other 17.
5. **No ḥadīth grading applies to this batch** — there are no ḥadīth beats in any of the four decks, so this is a true absence, not an unchecked one.

---

## 8 · Reconciliation with `2026-08-04-R2-VERIFICATION.md`

R2 covers all 54 pending drafts, not just this batch, and is explicit about its own limits: it treats source fidelity and ḥadīth grading as reliable (re-fetched, re-read) but says outright that "bar-1 ladder judgements, bar-3(c) engine arguments, and the bar-5 register calls" are *not* reliable there, because the same author wrote most of the wave — and that "a blind Sonnet verifier is still owed." That is the role this document fills for this batch.

**Where I agree with R2:**

- **R2's §4 names exactly the two things I was sent here to press on**: *"al-hakam@1's 22:56 has punishment on both sides"* and *"the judgment four's group-wide bar-5 ruling, which a verifier rejects all at once or not at all."* Both are correctly identified as the batch's central open questions, and I did rule on both explicitly — the ruling is accepted (§2), and 22:56's bar-5 problem is real and confirmed (§1, §3).
- **None of the eight defects R2 found and fixed (§2.1–2.9) touch this batch.** My own word-for-word check of every quoted span in all four decks against Saheeh confirms this independently — I found zero misquotations, zero splices, zero mid-sentence-omission-behind-an-edge-ellipsis in the judgment four. R2's source-fidelity claim for this batch holds up under my own re-fetch.
- **No ḥadīth beats in this batch, and R2's §3 table has none for these four either.** Consistent.

**Where I go further than R2, and this is the part worth flagging as disagreement rather than confirmation:**

- **R2 states the 22:56 double-punishment problem as a fact to hand to a verifier; it does not investigate whether a better carrier exists.** I did, because the task specifically asked me to spend real effort in the un-enumerated part of `Hkm`, and I found two candidates (16:124, 22:69) with clean bar-5 neighbourhoods on both sides — one of them thirteen āyāt away from 22:56 in the *same sūrah*. R2's framing implicitly treats 22:56's exposure as something the group ruling simply absorbs. **I think that is premature.** The group ruling is a fallback for when no cleaner text exists; it should not be reached for without first checking whether a cleaner text exists, and here one does. This is my one substantive disagreement with the posture (not the content) of R2's §4 note.
- **R2's binary framing — "a verifier rejects all four at once or not at all" — describes whether the *ruling* is sound, not whether every individual carrier choice under an accepted ruling is optimal.** I accept the ruling for the group. I still send Al-Hakam back, for a reason that has nothing to do with whether the ruling is correct: a specific, better carrier for that specific deck was available and wasn't checked. Those are two different axes and R2's phrasing risks collapsing them — a future reader could take "reject all four or none" to mean "if you have any objection to any of the four, you must reject all four," which is not what I am doing and I don't think it's what the ruling was meant to require either.
- **R2 does not check Al-Adl's bar-4 trade or the `Edl` sweep at all** — it is out of R2's scope (R2 is source-fidelity + ḥadīth-authenticity across 54 drafts, not a bar-by-bar audit). I did check it independently and found it holds, with two small, previously undisclosed gaps (§4 above: the 6:1/6:150/27:60 grammar mischaracterization, and the missing 82:7 disclosure). Neither is in R2 because R2 was never asked that question for this batch.
- **R2 does not mention the al-muhsi@1/al-haseeb separation at all**, despite both being drafted in the same session — consistent with my own finding that `al-muhsi@1`'s draft doesn't mention Al-Haseeb either. This is a real blind spot shared by both documents, not a disagreement between them, and it's why I re-argued it from scratch in §5 rather than treating either draft's silence as confirmation.

**Net:** I agree with R2 on everything it actually checked for this batch. Where I differ is that R2 correctly located the batch's two hardest questions but declined to resolve either — appropriately, given its stated scope — and left them exactly where the brief said a blind verifier should look first. On the bar-5 ruling, my independent check affirms it. On the 22:56 carrier, my independent check does not let it stand as currently argued.

