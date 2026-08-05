# Verdict — batch `traded-bar4` — 2026-08-04

Blind adversarial verification of five decks: As-Sabur (32), Al-Jaleel (56), Dhul-Jalali wal-Ikram (89), Al-Kabeer (53), Al-Muqtadir (76). Every citation below was fetched in this session — `api.quran.com/api/v4`, `corpus.quran.com/qurandictionary.jsp`, `sunnah.com` via Wayback, and the repo's own `assets/content/name_stories.json` / `collectible_names.json`. Nothing here was recalled from training.

---

## 1 · Citation table — everything fetched, what it actually says

| # | Claim (as it reaches a beat / a bar argument) | Source fetched | What came back | Verdict |
|---|---|---|---|---|
| 1 | 32:5 — "He arranges [each] matter... a thousand years of those which you count" (As-Sabur story+carrier) | `api.quran.com/.../32:5` | `يُدَبِّرُ ٱلْأَمْرَ مِنَ ٱلسَّمَآءِ إِلَى ٱلْأَرْضِ ثُمَّ يَعْرُجُ إِلَيْهِ فِى يَوْمٍ كَانَ مِقْدَارُهُۥٓ أَلْفَ سَنَةٍ مِّمَّا تَعُدُّونَ` — whole āyah, translation matches deck verbatim | ✅ |
| 2 | 22:47 closing clause — "a day with your Lord is like a thousand years..." | `.../22:47` | `وَإِنَّ يَوْمًا عِندَ رَبِّكَ كَأَلْفِ سَنَةٍ مِّمَّا تَعُدُّونَ`. Opening clause `وَيَسْتَعْجِلُونَكَ بِٱلْعَذَابِ` ("they urge you to hasten the punishment") genuinely **not rendered**, ellipsis correctly placed | ✅ |
| 3 | 32:4 (n−1), clean, no punishment | `.../32:4` | Six-days creation, Throne — no punishment content | ✅ |
| 4 | 32:6 (n+1), closes `ٱلرَّحِيمُ` | `.../32:6` | `...ٱلْعَزِيزُ ٱلرَّحِيمُ` confirmed | ✅ |
| 5 | `ص-ب-ر` root sweep: 103 occurrences, 8 forms | `corpus.quran.com/qurandictionary.jsp?q=Sbr` | Headline exact match: "occurs 103 times... in eight derived forms" with the same per-form breakdown (58/1/3/4/15/20/1/1). **I additionally counted 103 individual verse-word citations in the page and 93 unique āyāt** — matches the deck's "93 distinct āyāt" claim exactly | ✅ |
| 5a | "Every one of the 103 takes a human subject" | Same page, **every individual entry read** (not just the category summary) | Read all ~103 glossed entries end-to-end: commands to be patient (2nd person imperative), descriptions of patient people, Yūsuf/Yaʿqūb's "beautiful patience," the Mūsā–Khiḍr exchange, `li-kulli ṣabbārin shakūr` (a human quality). **Zero entries predicate the root of Allah.** This is the one counterexample search the drafter admitted not doing (§ "what I could not determine" #3) — I did it. **No counterexample found; claim (a) holds**, now on individually-read text, not just the corpus's category label | ✅ **independently confirmed** |
| 6 | Bukhārī 7378 — the one ṣaḥīḥ predication, `أَصْبَرُ`, an elative | `web.archive.org/.../sunnah.com/bukhari:7378` | Arabic and English match the deck byte-for-byte: `مَا أَحَدٌ أَصْبَرُ عَلَى أَذًى سَمِعَهُ مِنَ اللَّهِ، يَدَّعُونَ لَهُ الْوَلَدَ، ثُمَّ يُعَافِيهِمْ وَيَرْزُقُهُمْ` / "None is more patient than Allah..." **No printed "Grade:" line exists on this page at all** — see §4 below | ✅ text confirmed; grade-line nuance noted |
| 7 | Tirmidhī 3507 — الصَّبُور last in the 99-Names list, graded Ḍaʿīf | `web.archive.org/.../sunnah.com/tirmidhi:3507` | Full Arabic list read; ends `...الْبَاقِي الْوَارِثُ الرَّشِيدُ الصَّبُورُ`. **الصَّبُورُ is confirmed the very last Name.** Printed grade: `Grade : Da'if (Darussalam)`. At-Tirmidhī's own comment `هَذَا حَدِيثٌ غَرِيبٌ` confirmed verbatim | ✅ |
| 7a | Tirmidhī 3507 also contains الْجَلِيلُ (Al-Jaleel's Name-form) | Same fetch | List contains `...الْحَفِيظُ الْمُقِيتُ الْحَسِيبُ الْجَلِيلُ الْكَرِيمُ الرَّقِيبُ...` — **الْجَلِيلُ present**, and `...مَالِكُ الْمُلْكِ ذُو الْجَلاَلِ وَالإِكْرَامِ...` (Dhul-Jalali wal-Ikram) also present | ✅ confirms al-jaleel@1's disclosure that its Name-form's only attestation is this same Ḍaʿīf ḥadīth |
| 8 | `al-haleem@1` renders Bukhārī 7378 in full, both clauses | `assets/content/name_stories.json`, `deck_id: al-haleem@1` | Story beats 4–5 render both halves in the exact same English printed by sunnah.com. **Confirmed: the sole ṣaḥīḥ carrier is already spent by a shipped deck** | ✅ |
| 9 | `al-haleem@1`'s dua is byte-identical to As-Sabur's catalogue dua | Same JSON | `dua_arabic` = `اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ` in both `al-haleem@1` and `collectible_names.json` id 32 | ✅ |
| 10 | `al-haleem@1`'s verse beat is 35:45, not 32:5 or 35:45≠As-Sabur's carrier | Same JSON | `source: "Qur'an 35:45"`, text is the deferred-punishment āyah — confirmed disjoint from As-Sabur's 32:5/22:47 | ✅ |
| 11 | `ج-ل-ل` root sweep: exactly 2 occurrences, both `jalāl`, at 55:27 and 55:78 | `corpus.quran.com/qurandictionary.jsp?q=jll` | "occurs twice in the Quran as the noun jalāl," entries listed are exactly `(55:27:5)` and `(55:78:5)`, both glossed "of Majesty" | ✅ |
| 12 | 55:26 — "Everyone upon it will perish" | `.../55:26` | `كُلُّ مَنْ عَلَيْهَا فَانٍ` — confirmed, no punishment | ✅ |
| 13 | 55:27 — "the Face of your Lord, Owner of Majesty and Honor" (Al-Jaleel carrier) | `.../55:27` | `وَيَبْقَىٰ وَجْهُ رَبِّكَ ذُو ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` — whole āyah, matches | ✅ |
| 14 | 55:28 — refrain, no punishment | `.../55:28` | `فَبِأَىِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ` confirmed | ✅ |
| 15 | 55:77 — refrain, predecessor of Dhul-Jalali carrier | `.../55:77` | Identical refrain confirmed | ✅ |
| 16 | 55:78 — "Blessed is the name of your Lord, Owner of Majesty and Honor" (Dhul-Jalali carrier) | `.../55:78` | `تَبَـٰرَكَ ٱسْمُ رَبِّكَ ذِى ٱلْجَلَـٰلِ وَٱلْإِكْرَامِ` — whole āyah, matches | ✅ |
| 17 | 55:79 → 404, sūrah-final | `.../55:79` | **HTTP 404, `{"status":404,"error":"Ayah not found"}`** — genuine, re-verified independently by status code, not fabricated | ✅ |
| 18 | `as-salam@1`'s dua renders `تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ` in full | `assets/content/name_stories.json`, `deck_id: as-salam@1` | `dua_arabic`: `اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ`, translation "...Blessed are You, O Owner of Majesty and Honor." **Confirmed: a shipped deck already renders id 89's compound Name in full**, exactly as both id-56 and id-89 drafts claim | ✅ **critical cross-deck check confirmed** |
| 19 | 9:72 — "gardens... but approval from Allah is greater" (Al-Kabeer carrier) | `.../9:72` | `وَعَدَ ٱللَّهُ ٱلْمُؤْمِنِينَ... وَرِضْوَٰنٌ مِّنَ ٱللَّهِ أَكْبَرُ` — whole āyah, translation matches | ✅ |
| 20 | 9:71 (n−1), clean, closes "Allāh will have mercy" | `.../9:71` | Confirmed, no punishment | ✅ |
| 21 | 9:73 (n+1) — Hell | `.../9:73` | `وَمَأْوَىٰهُمْ جَهَنَّمُ` — "their refuge is Hell" — confirmed exposure is real, not softened | ✅ |
| 22 | 13:9 — four-epithet chain, `ٱلْكَبِيرُ` one word | `.../13:9` | `عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ ٱلْكَبِيرُ ٱلْمُتَعَالِ` confirmed — four distinct epithets in one clause | ✅ |
| 23 | `al-mutaali@1` renders a *different* word of 13:9 (`ٱلْمُتَعَالِ`, not `ٱلْكَبِيرُ`) | `2026-08-03-al-mutaali-DRAFT.md`, beat 6 | Verse beat: "…the Exalted. — Qur'an 13:9", sources table explicitly reserves `ٱلْكَبِيرُ` "for id 53 Al-Kabeer" | ✅ no word-level collision |
| 24 | `ك-ب-ر` root: 161 occurrences, 18 forms | `corpus.quran.com/qurandictionary.jsp?q=kbr` | Headline exact match | ✅ |
| 25 | 22:62 / 31:30 / 34:23 — all `ٱلْعَلِىُّ ٱلْكَبِيرُ` trailing pairs | `.../22:62`, `.../31:30`, `.../34:23` | All three confirmed, identical trailing-epithet structure | ✅ |
| 26 | 40:12 — the root inside a rebuke to the damned | `.../40:10`, `.../40:11`, `.../40:12`, `.../40:13` | **40:10**: "those who disbelieve will be addressed [in Hell]..."; **40:11**: the damned confess sin and beg for an exit; **40:12**: "...the judgement is with Allāh, the Most High, the Grand [`ٱلْعَلِىِّ ٱلْكَبِيرِ`]." Confirmed genuinely spoken to the damned in Hell — the deck's rejection is correct, not overstated | ✅ |
| 27 | 29:45 — `أَكْبَرُ`'s subject is "the remembrance," not Allah | `.../29:45` | `وَلَذِكْرُ ٱللَّهِ أَكْبَرُ` — subject is `ذِكْرُ` (the remembrance), confirmed | ✅ |
| 28 | 54:54 — "the righteous... gardens and rivers" | `.../54:54` | `إِنَّ ٱلْمُتَّقِينَ فِى جَنَّـٰتٍ وَنَهَرٍ` confirmed | ✅ |
| 29 | 54:55 — "a seat of honor near a Sovereign, Perfect in Ability" (Al-Muqtadir carrier) | `.../54:55` | `فِى مَقْعَدِ صِدْقٍ عِندَ مَلِيكٍ مُّقْتَدِرٍۭ` confirmed | ✅ |
| 30 | 54:56 → 404, sūrah-final | `.../54:56` | **HTTP 404, `{"status":404,"error":"Ayah not found"}`** — independently re-verified per the brief's explicit warning about a prior fabricated 404. **This one is real** | ✅ |
| 31 | 54:53 — deck's own text does not fetch/discuss this predecessor | `.../54:53` (fetched by verifier, not by the deck) | `وَكُلُّ صَغِيرٍ وَكَبِيرٍ مُّسْتَطَرٌ` — "every small and great [thing] is inscribed." Deeds-recorded, sits between the Fire scene (54:47–48) and the gardens (54:54). **Deck never fetched or disclosed this āyah** — see §6 | ⚠️ gap, not a fabrication |
| 32 | 54:47–52 — the sūrah "spends itself listing destroyed nations," incl. explicit Fire | `.../54:47`–`.../54:52` (fetched by verifier) | 54:47–48: criminals "dragged into the Fire on their faces... Taste the touch of Saqar." 54:51: "We have already destroyed your kinds." **The deck's framing claim is accurate and, if anything, understated** | ✅ |
| 33 | 43:42 — "We are Perfect in Ability" (Al-Muqtadir verse beat) | `.../43:42` | `فَإِنَّا عَلَيْهِم مُّقْتَدِرُونَ` — closing clause, ellipsis correctly placed | ✅ |
| 34 | `ق-د-ر` root: 132 occurrences, 11 forms; `muqtadir` exactly 4× (18:45, 43:42, 54:42, 54:55) | `corpus.quran.com/qurandictionary.jsp?q=qdr` | Headline matches exactly. Individually located all four `muqtadir` entries by verse key: 18:45, 43:42, 54:42, 54:55 — **exact match, no fifth occurrence found** | ✅ |
| 35 | `al-qadir@1` (shipped neighbour) uses 2:260 and 75:40, no overlap with Al-Muqtadir | `assets/content/name_stories.json`, `deck_id: al-qadir@1` | Confirmed: Ibrāhīm/four-birds story (2:260) and 75:40 — entirely disjoint scripture from 54:54–55/43:42 | ✅ |
| 36 | Deck count swept = 45 | `assets/content/name_stories.json` | `len(json)` = **45** (Python, counted directly) | ✅ measured, not trusted |
| 37 | Catalogue fields (`english`, `dua_*`) render byte-for-byte for ids 32, 53, 56, 76, 89 | `assets/content/collectible_names.json` | All five entries pulled and diffed against each deck's beats 2 and 7 — **byte-exact in every case**, including id 89's dua naming "the Fire" (`أَجِرْنَا مِنَ النَّارِ`) as disclosed | ✅ |

---

## 2 · Five-bars verdicts

### As-Sabur (`as-sabur@1`, id 32)

| bar | verdict | evidence |
|---|---|---|
| 1 | PASS | 32:5, Allah's own narration, confirmed verbatim |
| 2 | PASS | genuine enacted process (descend/arrange/ascend), not a static claim |
| 3 | CONTESTED, disclosed | duʿā is byte-identical to shipped `al-haleem@1` — confirmed above; unavoidable given catalogue lock. Beats themselves free of collision |
| 4 | **TRADED — this is the real question** | Confirmed: 103/93-āyah sweep, individually read, no counterexample; the sole ṣaḥīḥ predication (Bukhārī 7378, an elative) is spent by `al-haleem@1`; the Name-form's sole attestation is Ḍaʿīf. **All three legs verified true.** See §5 for the ruling |
| 5 | PASS | 32:4/32:6 clean, 22:47's punishment clause correctly excised |

### Al-Jaleel (`al-jaleel@1`, id 56)

| bar | verdict | evidence |
|---|---|---|
| 1 | PASS | 55:27, Allah's own voice |
| 2 | PASS | contrast-in-sequence (perish/remain) |
| 3 | CONTESTED, disclosed | 5-word run ("Owner of Majesty and Honor") against shipped `as-salam@1`'s duʿā — confirmed real, confirmed unavoidable (fixed liturgy, §9bl) |
| 4 | PASS, no trade | root literally in the rendered text |
| 5 | PASS | 55:26/55:28 clean |

### Dhul-Jalali wal-Ikram (`dhul-jalali-wal-ikram@1`, id 89)

| bar | verdict | evidence |
|---|---|---|
| 1 | PASS | 55:78, Allah's own voice |
| 2 | CONTESTED — weakest bar in the batch | "placement" (the sūrah stops asking) is a structural argument, not a narrated act. Real but thin |
| 3 | CONTESTED, disclosed | shipped `as-salam@1` renders this Name's full compound in its duʿā — confirmed above, at full strength, not softened by the deck |
| 4 | PASS, no trade | both halves of the compound present |
| 5 | PASS (scripture) / flagged (own duʿā) | 55:79 genuinely 404 (sūrah-final); but the deck's own locked duʿā names the Fire — correctly disclosed, not smoothed |

### Al-Kabeer (`al-kabeer@1`, id 53)

| bar | verdict | evidence |
|---|---|---|
| 1 | PASS | 9:72, Allah's own narration and ranking |
| 2 | PASS | comparison performed, not asserted — confirmed against fetched 9:72 |
| 3 | PASS | measured max run 4, function-word only; 13:9 word-split against `al-mutaali@1` confirmed non-colliding |
| 4 | PASS, no trade | `أَكْبَرُ` (9:72) and `ٱلْكَبِيرُ` (13:9) both present, though see §5 discussion of elative vs Name-form |
| 5 | PASS with disclosed successor exposure | 9:73's Hell content confirmed real and undisguised; 9:71 clean |

### Al-Muqtadir (`al-muqtadir@1`, id 76)

| bar | verdict | evidence |
|---|---|---|
| 1 | PASS | 54:55, the Name-form itself, Allah's own narration |
| 2 | PASS | "placed at a seat," an enacted scene, not an assertion |
| 3 | PASS | measured max run 4; `al-qadir@1` disjoint, confirmed |
| 4 | PASS, no trade | Name-form itself present in both 54:55 and 43:42 |
| 5 | PASS, with one gap | 54:56 genuinely 404 (re-verified, not fabricated); 54:47–52 confirmed to be Fire/destruction as claimed. **But the deck never fetched 54:53**, the immediate predecessor — see §6 |

---

## 3 · Bar 3(b), measured

`len(json.load(open('assets/content/name_stories.json')))` = **45**. All five decks' "45 decks swept" claim is correct as measured, not merely trusted.

---

## 4 · Every rendered ḥadīth: the printed grade line

- **Bukhārī 7378** (spent by `al-haleem@1`, rejected-and-disclosed by `as-sabur@1`): **no printed "Grade:" line exists on the sunnah.com page at all.** The page offers a "Grade" filter checkbox but renders nothing under it for this hadith. This is standard sunnah.com behaviour for the two Ṣaḥīḥayn — Bukhārī and Muslim carry no per-hadith Darussalam grade because the collections themselves are treated as canonically ṣaḥīḥ by scholarly consensus, unlike Tirmidhī/Abū Dāwūd/etc. which do get an explicit per-hadith grade. **The deck's "✅ Ṣaḥīḥ" label is the correct convention, but it is not literally a printed grade line** — worth stating precisely rather than taking the deck's "✅ Ṣaḥīḥ (collection-level)" at face value without checking whether a line actually printed. It did not.
- **Tirmidhī 3507** (As-Sabur's and Al-Jaleel's Name-form attestation): **`Grade : Da'if (Darussalam)`**, quoted verbatim from the fetched page. At-Tirmidhī's own annotation, quoted verbatim: `قَالَ أَبُو عِيسَى هَذَا حَدِيثٌ غَرِيبٌ`.

No other ḥadīth is rendered on any beat in this batch (id 89's catalogue `hadith` field, Tirmidhī 3524, and id 32's/id 76's catalogue `hadith` fields are non-beat catalogue metadata, not rendered by any deck's beat structure, and were not independently fetched since nothing in these five decks cites them as a source).

---

## 5 · The As-Sabur re-litigation (task item 1) — ruling

All three facts the overturned refusal (and the surviving draft) rest on are **independently verified true**, not merely re-read:

(a) **103 occurrences, 8 forms, 93 āyāt, zero predicating Allah** — confirmed via the corpus's category summary *and*, going further than the drafter did, by reading all ~103 individually glossed entries myself. I looked for the one counterexample the brief demanded. **I did not find one.** Every occurrence is a command to a human, a description of human patience, or a human's own declaration of intent to be patient (Yaʿqūb, Mūsā/Khiḍr). This is the strongest form of verification available short of pulling all 93 full āyāt individually, which I did not do — see §6.

(b) **Bukhārī 7378 is the sole ṣaḥīḥ predication and it is spent** — confirmed both directions: the Wayback capture matches the deck's Arabic/English exactly, and `al-haleem@1`'s JSON renders both halves across story beats 4–5 in the identical published English. Not a paraphrase, not a coincidence — the same string.

(c) **Tirmidhī 3507 is Ḍaʿīf and is the Name-form's only attestation** — confirmed with the printed grade line quoted above.

**Ruling on the turning question ("is bar 4 tradeable when the Name-form has no ṣaḥīḥ attestation at all?"):** Yes, on the brief's own terms, and this is the cleanest possible test case for what "documented full-corpus sweep proving the trade is forced" is supposed to mean. Bar 4 does not require the Name's *own form* to be ṣaḥīḥ-attested — it requires the *root* to appear in the quoted text, tradeable with proof the trade is forced. As-Sabur's root does not appear in either rendered text (32:5, 22:47) at all — this is not even a trade, it is an **absence**, disclosed as such by the deck itself ("❌ `ص-ب-ر` appears nowhere in either rendered text... TRADED"). That is a more honest and more exposed position than a typical bar-4 trade (which usually still has the root sitting in the text, just not as the Name-form). I find this acceptable **only** because the deck discloses it this starkly rather than dressing it up, and because 32:5's bar-1/bar-2/bar-5 case stands on its own without needing the root. A verifier who holds the harder line — that bar 4 requires *some* occurrence of the root, full stop, even in a non-Name form, even elsewhere in the deck's argumentative footprint (e.g. the duʿā, where `ٱلصَّبْر` does appear, spoken by the human petitioner) — would refuse this Name outright. **I do not take that harder line**, because the duʿā's own `ٱلصَّبْر` is real rendered text carrying the root, even though it's a human petition rather than a divine predication, and the deck's own §"The shared duʿā" section argues this explicitly ("even the catalogue's own supplication uses `ص-ب-ر` of the worshipper"). Bar 4 says root-in-text, not root-predicated-of-Allah — that stronger reading is bar 1's job, and bar 1 is separately satisfied by 32:5. On that reading, **the duʿā beat itself is a legitimate (if weak) bar-4 anchor**, and the deck under-sells its own case by not naming it as such in the bars table.

**Task item 2 — attacking "restraint vs scale":** This is the sharpest edge in the batch. 32:5 does not contain any vocabulary of waiting, patience, or delay — no `ص-ب-ر` root, no explicit reference to the reader's unanswered prayer. It is a general statement about a repeating administrative cycle (day = 1000 years) inside the created order. The deck's rhetorical move — "the silence you have been reading as refusal is a matter still ascending" — is an *application* of the verse to the reader's specific situation, not something the āyah itself states. That is a real interpretive extension, and I flag it as such rather than pass it silently: bar 2's "shown, not stated" is satisfied for the *general claim* (a process shown in motion), but the *personalized* claim in beat 8 ("your matter is still ascending") is authored inference layered on top, standard practice for a takeaway beat but worth being explicit about. On the restraint-vs-scale distinction itself: I find it genuinely defensible, not a collapse. Al-Haleem's 35:45 is specifically about *deferred sanction* — the gap between deserved punishment and its execution. As-Sabur's argument is about *tempo of process*, unconnected to sin or judgment. These answer different fears (dread of a bill vs. frustration at silence), and I confirmed 35:45 is not reused anywhere in the As-Sabur deck. The distinction survives the attack, but only as *argued*, exactly as the deck itself says (measured against al-baqi@1: 3 words, confirmed low).

Verified: the deck does **not** use 35:45 anywhere — confirmed disjoint from `al-haleem@1`'s carrier.

---

## 6 · The 54:53 gap (task item 6)

The brief specifically asked me to fetch 54:53 and 54:56, "expect a 404 on 54:56... verify, do not assume." I did both. **54:56 is a genuine 404** — re-confirmed by status code, not fabricated, in a batch where the brief explicitly warns a prior agent fabricated exactly this kind of result elsewhere. This one is real.

**54:53** (`وَكُلُّ صَغِيرٍ وَكَبِيرٍ مُّسْتَطَرٌ`, "every small and great [thing] is inscribed") is never fetched or mentioned anywhere in the Al-Muqtadir draft — not in the Sources table, not in the successor sweep (which only runs forward to 54:56), not in the bar-5 discussion. This is a genuine gap in the deck's own verification, not a fabrication: the deck's successor sweep only ran n+1, never n−1. Reading it myself: it sits between the explicit Fire scene (54:47–48, "dragged into the Fire on their faces... Taste the touch of Saqar") and the gardens (54:54). It is deeds-recorded language, not itself a punishment āyah, and it does not overturn the deck's framing — if anything it strengthens the "the sūrah spends itself on destruction, then stops" argument, since 54:53 is the last beat of judgment-adjacent material before the turn. But the deck should have fetched and disclosed it under its own stated protocol ("successor sweep: fetch n−1 and n+1"), and did not.

**Ruling on the destruction-sūrah question:** A sūrah of destruction is survivable as bar-5 register here because the *specific rendered text* (54:54–55) and its *immediate neighbours on both sides* (54:53, now checked; 54:56, confirmed 404) are clean — the destruction material is real but is neither quoted nor adjacent to what is quoted. This is the same logic that clears any deck quoting a sūrah-final āyah in a sūrah with earlier harsh material, and I accept it, with the correction that the deck's own n−1 sweep was incomplete and should be fixed before ship (cheap fix: add 54:53 to the sources table, note it as I have here).

---

## 7 · Ship / no-ship verdicts

- **As-Sabur (`as-sabur@1`)** — **SHIP, with the bar-4 trade explicitly ratified rather than silently accepted.** All three legs of the trade argument verified true, including the one the drafter admitted not fully checking (the 103-occurrence sweep, now individually read with no counterexample found). Fix before ship: add the duʿā's own `ٱلصَّبْر` to the bar-4 table as the (weak) anchor it is, rather than reporting bar 4 as a bare "no root anywhere" trade — the deck currently under-states its own strongest fallback.
- **Al-Jaleel (`al-jaleel@1`)** — **SHIP.** Root-count, partition, and the `as-salam@1` collision all confirmed exactly as claimed. No fix required beyond what's already disclosed.
- **Dhul-Jalali wal-Ikram (`dhul-jalali-wal-ikram@1`)** — **SHIP, but this is the weakest deck in the batch.** Bar 2 is thin (placement-as-demonstration) and bar 3 carries a full-strength collision against a shipped deck's rendering of the *entire Name*, not just a shared word-run. I would not refuse it — the partition with `al-jaleel@1` is the only structure available given a 2-occurrence root, and the deck discloses everything at full strength rather than softening it — but a reviewer with a lower tolerance for bar-2 thinness should flag this one first if only one of the pair is cut.
- **Al-Kabeer (`al-kabeer@1`)** — **SHIP.** Every fetched citation matches; the 13:9 word-split with `al-mutaali@1` is real and non-colliding; the 9:73 Hell-adjacency is disclosed accurately; the rejected-candidate list (40:12, 22:62, 31:30, 34:23, 29:45) all checked out exactly as characterized.
- **Al-Muqtadir (`al-muqtadir@1`)** — **SHIP, with one cheap fix.** Add 54:53 to the Sources table and successor-sweep section — it was never fetched despite being the deck's own stated protocol, though reading it does not change the verdict.

---

## 8 · What I could not verify — do not read as a claim

1. **I did not individually fetch all 93 distinct āyāt for the `ص-ب-ر` sweep.** I read all ~103 corpus-page entries (Arabic word + English gloss + full-āyah Arabic snippet shown inline on the dictionary page), which is a real, independent check beyond what the drafter did, but it is not the same as opening each of the 93 āyāt at `api.quran.com` individually. If the corpus's own inline Arabic snippets are wrong for some entry, I would not have caught it. I judge this an acceptably strong check given the volume, but it is not the strongest possible one.
2. **I did not run a systematic `sunnah.com` search for other narrations predicating `ص-ب-ر` of Allah beyond Bukhārī 7378 and Tirmidhī 3507.** Both the refusal and the draft flag this as open. I did not close it either — `sunnah.com`'s search endpoint is reported elsewhere in this project to 403 automation, and I did not attempt to route around that in this session.
3. **I did not exhaustively fetch all 161 `ك-ب-ر` or 132 `ق-د-ر` occurrences.** I spot-checked the specific verses the decks name (22:62, 31:30, 34:23, 40:10–13, 29:45 for kbr; all four muqtadir occurrences for qdr) and all matched. I did not check the remaining ~150 and ~128 occurrences respectively.
4. **I did not fetch any ḥadīth beyond Bukhārī 7378 and Tirmidhī 3507.** The catalogue `hadith` fields for ids 32, 76, and 89 reference other narrations (a different Bukhārī/Muslim patience ḥadīth, and Tirmidhī 3524) that are not rendered by any beat in these five decks, so I did not chase them — flagging their existence only so nobody assumes they were checked.
5. **I did not independently re-derive the bar-3(c) "the move" arguments from first principles** for every cross-deck comparison named (al-azeem@1, al-mutakabbir@1, al-baqi@1, al-ali@1) — I read the shipped/drafted decks that exist in-repo (`al-baqi@1`, `al-qadir@1`, `al-mutaali@1`) and confirmed no scriptural or word-run collision, but I did not re-argue "is this really a different move" for decks I did not have in front of me (`al-azeem@1`, `al-mutakabbir@1` full text not read).
6. **I did not verify the Al-Jaleel/Dhul-Jalali "5-word run" quote precisely** — both decks describe the shared run as *"of majesty and honor"* (4 words as quoted) while claiming a count of 5. My own diff of the two English strings finds the actual shared run is "Owner of Majesty and Honor" (5 words), which matches the claimed count but not the drafter's own quoted excerpt. Minor transcription slip in the deck's prose, not a defect in the underlying finding — noted so it isn't silently "confirmed" without qualification.

---

## 9 · Reconciliation with R2-VERIFICATION.md

R2 explicitly disclaims itself as *not* the independent blind review ("bar-1 ladder judgements, bar-3(c) engine arguments, and bar-5 register calls... not reliable," §0) and names exactly two of my five decks — `as-sabur@1` and `ar-rasheed@1` — as where "a blind verifier should go first" for the traded bar 4 (§4). This review is that pass for As-Sabur, and I reach the same place R2 leaves it: the trade is real, both facts underneath it check out, and the ruling is a judgment call the brief leaves to the verifier rather than something R2's fidelity method could settle.

**Where I agree:**

- R2's §3 finding that Tirmidhī 3507 is the sole attestation of both `ٱلصَّبُور` and `ٱلْجَلِيل`, correctly cited in reasoning and on no beat by both decks — confirmed independently, including the grade line and both Names' presence in the list.
- R2's §4 praise of `al-kabeer@1` for "performs the comparison once and uses Paradise as the smaller term" — matches my own bar-2 finding after fetching 9:72 myself.
- R2's §4 characterization of `al-muqtadir@1`'s move ("the last sentence of a sūrah about destroyed nations — beside a seat, not over a ruin") — confirmed accurate against 54:47–56, fetched in full including the 404 boundary.
- R2's general finding (§6) that nothing rendered in this wave was fabricated or weak — my batch adds no counterexample.

**Where I disagree or extend:**

1. **R2's ḥadīth-authenticity table (§3) never lists Bukhārī 7378**, despite it being the single most load-bearing narration in this batch — it is the fact that makes As-Sabur's bar-4 trade "forced" rather than optional, since it's the one ṣaḥīḥ text a Qurʾān-only sweep can't produce. I fetched it and found **no printed grade line at all** on the page, unlike Tirmidhī 3507's explicit `Grade : Da'if (Darussalam)`. That's the correct convention for the Ṣaḥīḥayn (collection-level authority, no per-hadith Darussalam grade), and it doesn't change the outcome — but R2's table gives the impression every rendered/load-bearing ḥadīth got an explicit read-the-page grade check, and this one, arguably the most consequential in the batch, is absent from the table even though R2 discusses it in prose one paragraph later. Worth closing the gap in the table, not the conclusion.
2. **R2's method (§1) checks "159 rendered quoted segments" for fidelity but does not describe checking successor-sweep *completeness*** — whether n−1 and n+1 were actually fetched, versus whether what *was* fetched is accurate. That gap is exactly why R2 didn't catch that `al-muqtadir@1` never fetched 54:53 (its own immediate predecessor) despite the deck's own stated protocol requiring it. This is a disclosure-completeness defect, not a fidelity defect, and it sits outside what R2's method was built to catch. I'd flag this as a category of check R2's method structurally cannot perform, not an error R2 made.
3. **R2 does not attack the "restraint vs scale" separation between `as-sabur@1` and `al-haleem@1`**, or any bar-3(c) argument in this batch — which R2 itself says is expected, since it explicitly disclaims engine arguments as unreliable in its own hands. I did attack it (§5 above) and it survives, but only as *argued*, which is the same qualifier the draft itself uses. This isn't a disagreement so much as R2 correctly deferring a question it says it can't answer, and my review being the first pass to actually answer it.
4. **R2 does not mention that Al-Jaleel and Dhul-Jalali wal-Ikram's shared 5-word run is quoted inconsistently in both drafts' own prose** (both write "of majesty and honor," 4 words, while claiming a 5-word count). Minor, and my own diff confirms the underlying 5-word count is correct even though the drafter's excerpt undercounts it — not something R2's automated fidelity pass would have been built to catch either, since it's a defect in the drafter's *description* of a finding, not in a rendered beat.

**Net:** R2 and this review agree on every fact both checked. The disagreements are entirely about *coverage* — R2's method (automated fidelity + printed grade-line reads) is strong exactly where it says it is and silent exactly where it says it is, and this pass fills two of the specific gaps R2 named (the As-Sabur bar-4 trade, and by extension the same reasoning-layer scrutiny for its neighbours) plus one it didn't name (the 54:53 successor-sweep gap, and the Bukhārī 7378 grade-line omission from its own table).
