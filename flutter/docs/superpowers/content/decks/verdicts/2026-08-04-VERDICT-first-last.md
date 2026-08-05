# Blind adversarial verdict — batch `first-last`

**Decks:** `2026-08-03-al-awwal-DRAFT.md` (id 79) · `2026-08-03-al-akhir-DRAFT.md` (id 80) ·
`2026-08-03-az-zahir-DRAFT.md` (id 81) · `2026-08-03-al-batin-DRAFT.md` (id 82) ·
`2026-08-03-al-musawwir-DRAFT.md` (id 21).

**Method.** Every scriptural and hadith claim below was fetched live in this session — Qur'an via
`api.quran.com/api/v4`, hadith via `web.archive.org` raw captures of the exact URLs the drafts cite,
root sweeps via `corpus.quran.com/qurandictionary.jsp`. Catalogue fields checked directly against
`assets/content/collectible_names.json` and `assets/content/name_stories.json` (45 decks currently
shipped — verified by reading the file, not by trusting the drafts' stated count). Nothing below is
copied from a draft's table without an independent fetch beside it.

---

## 1 · Citation table — every fetch, what it actually returned

### Qur'an — 57:3 (the four-way split ayah)

| claim | fetched key | text returned | ✅/⚠️/❌ |
|---|---|---|---|
| "He is the First and the Last, the Ascendant and the Intimate…" (SI) | `57:3`, translations=20 | `هُوَ ٱلْأَوَّلُ وَٱلْـَٔاخِرُ وَٱلظَّـٰهِرُ وَٱلْبَاطِنُ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ` / "He is the First and the Last, the Ascendant and the Intimate, and He is, of all things, Knowing." | ✅ |
| Usmani renders ẓāhir/bāṭin as "Manifest"/"Hidden" | `57:3`, translations=84 | "He is the First and the Last, and the Manifest and the Hidden, and He is All-Knowing about every thing." | ✅ — confirms the az-zahir/al-batin translation-choice claim exactly |

**Four-way split, checked by reading each beat 6 against this fetch:** id 79 renders only `هُوَ ٱلْأَوَّلُ` ("He is the First…"); id 80 renders only `وَٱلْـَٔاخِرُ` ("…and the Last…"); id 81 renders only `وَٱلظَّـٰهِرُ` ("…and the Manifest…"); id 82 renders only `وَٱلْبَاطِنُ` ("…and the Hidden…"). **None renders `وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`** (shipped `al-aleem@1`'s word, on a different ayah). ✅ clean four-way split, confirmed by fetch, not by table.

### Qur'an — surrounding successor/predecessor verses used by az-zahir/al-batin/al-awwal/al-akhir

| verse | fetched text (SI) | draft's claim | ✅/⚠️/❌ |
|---|---|---|---|
| 41:53 | "We will show them Our signs in the horizons and within themselves until it becomes clear to them that it is the truth…" | matches beats 3–4 exactly | ✅ |
| 41:52 | disbelievers in "extreme dissension" | "no punishment" | ✅ |
| 41:54 | "Unquestionably, they are in doubt about the meeting with their Lord…" | sūrah-final, no punishment | ✅ |
| 41:55 | HTTP 404 | sūrah-final, confirmed | ✅ |
| 50:16 | "And We have already created man and know what his soul whispers to him, and We are closer to him than [his] jugular vein." | matches beats 3–5 exactly | ✅ |
| 50:15 | disbelievers "in confusion over a new creation" | no punishment | ✅ |
| 50:17 | the two recording angels | no punishment | ✅ |
| 57:2, 57:4 | dominion/life-death; "He is with you wherever you are" | fetched, disclosed, not rendered | ✅ |

### Al-Musawwir's three primary beats

| verse | fetched text (SI) | ✅/⚠️/❌ |
|---|---|---|
| 3:6 | `هُوَ ٱلَّذِى يُصَوِّرُكُمْ فِى ٱلْأَرْحَامِ كَيْفَ يَشَآءُ ۚ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ` / "It is He who forms you in the wombs however He wills. There is no deity except Him, the Exalted in Might, the Wise." | ✅ beat quote accurate; R1's truncation before `لَآ إِلَـٰهَ` confirmed real and confirmed to leave `ٱلْعَزِيزُ ٱلْحَكِيمُ` unrendered |
| 40:64 | "...and formed you and perfected your forms and provided you with good things..." | ✅ matches beat 4 |
| 82:8 | "In whatever form He willed has He assembled you." | ✅ matches beat 5 exactly |

### Al-Musawwir's bar-5 successor sweep — **four of six citations do not say what the deck claims**

This is the single most important row in this report. I fetched every verse the deck's "Successor sweep" table cites for bar 5, independently:

| draft's claimed key | draft's quoted text | **what the verse actually says (fetched)** | ✅/⚠️/❌ |
|---|---|---|---|
| "3:5 (predecessor)" | *"Indeed, the creation of you and all the earth will not be but as [the creation of] a single soul. Indeed, Allah is Hearing and Seeing."* | **3:5 actually says:** "Indeed, from Allāh nothing is hidden in the earth nor in the heaven." The quoted text is **31:28** verbatim (SI: "Your creation and your resurrection will not be but as that of a single soul. Indeed, Allāh is Hearing and Seeing.") | ❌ **mislabeled/wrong verse** |
| "40:63 (predecessor)" | *"Those who deny the signs of Allah — their description with Him is like that of cattle; and worse are they in [their] return [to Allah]."* | **40:63 actually says:** "Thus were those [before you] deluded who were rejecting the signs of Allāh." Checked against five translations (SI, Usmani, Abdel Haleem, Pickthall, Yusuf Ali) — **none contains a cattle simile.** The closest real "cattle" verses are 7:179, 25:44, 47:12, 8:22 — none is an exact match for the deck's wording either. **This appears to be a fabricated quotation, not a mislabeled real one.** | ❌ **fabricated** |
| "82:6 (predecessor)" | *"What has created you and proportioned you?"* | **82:6 actually says:** "O mankind, what has deceived you concerning your Lord, the Generous," — the deck's wording is **82:7**'s content ("Who created you, proportioned you, and balanced you?"), spliced onto 82:6's opening "What has…" | ❌ **conflates two verses** |
| "82:9 (successor)" | *"It is We who know best what they say, and you are not over them a compeller."* | **82:9 actually says:** "No! But you deny the Recompense." The quoted text is **50:45** (SI: "We are most knowing of what they say, and you are not over them a tyrant.") | ❌ **mislabeled/wrong verse — and the real 82:9 is arguably more judgment-adjacent than the fabricated substitute, undisclosed** |
| "3:7 (successor)" | verses precise/unspecific discourse quote | matches fetched 3:7 exactly | ✅ |
| "40:65 (successor)" | "Exalted is Allah, the King, the Truth…" | matches fetched 40:65 exactly | ✅ |

**This directly matches the VERIFIER-BRIEF's failure catalogue** ("declared unreachable, then quoted from memory"; "attributed invented counts... by name and date"). None of these four fabricated/mislabeled verses render on a beat — they exist only to justify the bar-5 "PASS"/"clean" verdict — but that means **the bar-5 verdict for al-musawwir is not actually verified**, despite three separate stamps on the file (R0, R1, R2, "blind Sonnet verifier") all claiming it was. The blind-verifier claim on the file's own header is scoped to "3:6, 40:64 and 82:8" (the three rendered beats) — accurate as far as it goes — but the successor sweep was never independently checked by anyone before this pass, and it fails 4/6.

### Al-Musawwir's root sweep — corpus.quran.com, independently re-fetched

| root | draft's claim | my fetch | ✅/⚠️/❌ |
|---|---|---|---|
| `ص و ر` (Swr) | "occurs 19 times... five derived forms... 1+4+10+3+1" | Confirmed verbatim: 1 (form I, incline, 2:260) + 4 (form II verb, 3:6/7:11/40:64/64:3) + 10 (noun ṣūr, Trumpet) + 3 (noun ṣūrat) + 1 (active participle muṣawwir, 59:24) = 19 | ✅ |
| 2:260 `فَصُرْهُنَّ` | "to incline," homonym, Ibrahim/birds | fetched, confirmed: "Take four birds and commit [incline] them to yourself" | ✅ |
| 64:3 | rejected on bar 5, closes `وَإِلَيْهِ ٱلْمَصِيرُ` | fetched, confirmed: "...and to Him is the [final] destination" | ✅ |
| 7:11 | rejected on bar 5, sets up Iblis's refusal | fetched, confirmed | ✅ |
| 59:24 | "the only occurrence of the Name as a Name," three-epithet chain | fetched, confirmed: "He is Allāh, the Creator, the Producer, the Fashioner…" | ✅ |

### Az-Zahir / Al-Batin — root sweeps, independently re-fetched

| root | draft's claim | my fetch | ✅/⚠️/❌ |
|---|---|---|---|
| `ظ ه ر` (Zhr) | "occurs 59 times" | Confirmed: "occurs 59 times in the Quran, in 10 derived forms" | ✅ |
| `ب ط ن` (bTn) | "occurs 25 times" | Confirmed: "occurs 25 times in the Quran, in five derived forms" | ✅ |
| **Load-bearing bar-4 claim: only 57:3 predicates ẓāhir/bāṭin of Allah directly** | stated in both az-zahir and al-batin drafts, and in R1's note that a blind verifier "independently confirmed" it | **Independently re-derived, not trusted from the table.** ẓāhir active-participle occurs 8 times (6:120 "open sin," 13:33 "apparent word," 18:22 "obvious dispute," 30:7 "apparent life," 40:29 "dominant," **57:3 Allah**) + ẓāhirat 2× (31:20 "apparent favors," 34:18 "visible towns") — only 57:3 predicates it of Allah. bāṭin active-participle occurs 3 times (6:120 "secret sin," **57:3 Allah**, 57:13 "wall's interior") + bāṭinat 1× (31:20 "hidden favors") — only 57:3 predicates it of Allah. | ✅ **confirmed true by independent fetch** |

### Hadith — all four decks' primary carriers, plus the shared duʿā

| claim | source fetched | printed grade | Arabic returned | ✅/⚠️/❌ |
|---|---|---|---|---|
| **Sahih Muslim 2713a**, the shared bedtime duʿā (both pairs) | Wayback `20250811110019` of `sunnah.com/muslim:2713` (redirects to `:2713a`) | No separate grade line printed (Sahih Muslim collection-level convention, same as Bukhari) | `اللَّهُمَّ رَبَّ السَّمَوَاتِ...اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَىْءٌ وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَىْءٌ وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَىْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَىْءٌ...` — **matches, word for word (orthographic variants only), both duʿā-pair excerpts.** Genuine, not reconstructed. | ✅ |
| Abu Dawud 4700, "the Pen" (al-awwal beats 3–5) | Wayback `20240408121904` | **Sahih (Al-Albani)**, printed on page | `إِنَّ أَوَّلَ مَا خَلَقَ اللَّهُ الْقَلَمَ فَقَالَ لَهُ اكْتُبْ...` — matches beats 4–5 verbatim; **the disownment clause "مَنْ مَاتَ عَلَى غَيْرِ هَذَا فَلَيْسَ مِنِّي" ("he who dies on other than this does not belong to me") is present in the fetched page and confirmed rendered on no beat** | ✅ |
| Tirmidhi 2155, corroborating route | Wayback `20250905223959` | **Sahih (Darussalam)** | Confirmed: page's own closing note reads `قَالَ أَبُو عِيسَى وَهَذَا حَدِيثٌ غَرِيبٌ مِنْ هَذَا الْوَجْهِ` — exactly as disclosed | ✅ |
| Abu Dawud 4699 (n−1) | Wayback `20220908200024` | Not separately re-printed on the fetched excerpt, deck cites Sahih (Al-Albani) | Confirmed: `وَلَوْ مُتَّ عَلَى غَيْرِ هَذَا لَدَخَلْتَ النَّارَ` — "were you to die on other than this you would enter the Fire" — matches deck's conditional-punishment disclosure | ✅ |
| Abu Dawud 4701 (n+1) | Wayback `20220127212650` | **Sahih (Al-Albani)** | Confirmed: Adam/Musa dispute, `قَدَّرَهُ عَلَىَّ قَبْلَ أَنْ يَخْلُقَنِي بِأَرْبَعِينَ سَنَةً` matches | ✅ |
| Bukhari 6571, "the last man out" (al-akhir beats 3–5) | Wayback `20250420215228` | No separate grade line (collection-level Sahih) | `إِنِّي لأَعْلَمُ آخِرَ أَهْلِ النَّارِ خُرُوجًا مِنْهَا...فَيَقُولُ تَسْخَرُ مِنِّي، أَوْ تَضْحَكُ مِنِّي وَأَنْتَ الْمَلِكُ` — matches beats 3–5 verbatim, **including the elided `وَأَنْتَ الْمَلِكُ` clause**, confirmed present in source and confirmed absent from the beat | ✅ |
| Bukhari 6570 (n−1) | Wayback `20250207230627` | Sahih | Confirmed: intercession/shahada, no punishment | ✅ |
| Bukhari 6572 (n+1) | Wayback `20231211183016` | Sahih | Confirmed: `هَلْ نَفَعْتَ أَبَا طَالِبٍ بِشَىْءٍ` — page stops there, matches deck's disclosed-adjacency-risk framing exactly | ✅ |

### Catalogue fields — `collectible_names.json`, read directly

| claim | fetched field | ✅/⚠️/❌ |
|---|---|---|
| id 79/80 `dua_arabic` byte-shared, `اللَّهُمَّ أَنتَ الْأَوَّلُ...` | confirmed present, byte-identical to both decks' beat 7 | ✅ |
| id 81/82 `dua_arabic` byte-shared, `أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ...` (no `اللَّهُمَّ`) | confirmed present, byte-identical to both R1 decks' beat 7 — the R1 fix is real and correct | ✅ |
| id 21 `english`="The Fashioner", `dua_arabic`="يَا مُصَوِّرُ جَمِّلْ..." | confirmed byte-identical to beat 2 / beat 7 | ✅ |
| **al-akhir's catalogue finding: id 80 `meaning` (9 words) is a near-total subsequence of id 98 `meaning` (10 words)** | id 80: "The One who remains after all creation has perished." (9 words) · id 98: "The One who remains **forever** after all creation has perished." (10 words) — `difflib` match ratio 0.947, matching blocks cover 9/9 words of id 80 | ✅ **confirmed accurate** |
| **al-batin's catalogue finding: id 82 `meaning` (claimed "9 words") overlaps id 98 `meaning` (10 words)** | id 82 actual `meaning`: "The One who is hidden from human perception yet closer than all." — **this is 12 words, not 9**, and `difflib` against id 98 gives a match ratio of **0.27** with only a 3-word shared block ("The One who") — **no meaningful overlap exists.** | ❌ **fabricated/copy-paste finding.** This claim was almost certainly carried over from al-akhir's (correct) finding about id 80 without being re-checked against id 82's actual catalogue text — the exact "table, not source" failure the brief warns about, occurring inside a deck's own self-audit section. Non-blocking (not used on any beat), but it is a genuine finding: a "measured" claim in a verification table that a live check disproves. |

### Deck-count integer, verified

`assets/content/name_stories.json` currently holds **45** decks (`allah@1` through `al-baqi@1`) — read directly, matching every "swept 45 decks" claim in az-zahir, al-batin, and al-musawwir's bar-3(b) sections.

---

## 2 · Per-deck five-bars verdict

### `al-awwal@1` (id 79)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | Abu Dawud 4700's `فَقَالَ لَهُ اكْتُبْ` / `قَالَ اكْتُبْ مَقَادِيرَ...` is Allah's own recorded direct speech inside a Prophetic narration — fetched and confirmed above. Beat 6 (57:3) correctly disclosed as NOT carrying bar 1. |
| 2 | **PASS** | Shown (a specific first object, a specific first instruction), never stated as an abstract "Allah has always existed." |
| 3 | **PASS, disclosed** | Twin-diff computed against al-akhir; both decks' own numbers hold up (I did not independently re-run the full 34/45-deck token sweep — see limits). |
| 4 | **PASS** | `أَوَّلَ` present in the fetched Arabic of beat 4's own quotation — confirmed. |
| 5 | **PASS** | n−1 (4699) carries a real conditional-punishment clause in an **adjacent but distinct narration**, correctly disclosed and not quoted; n+1 (4701) and the hadith's own continuation (the disownment clause) are both clean and both confirmed not quoted. |

**Ship: YES.**

### `al-akhir@1` (id 80)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | `فَيَقُولُ اللَّهُ اذْهَبْ فَادْخُلِ الْجَنَّةَ` confirmed Allah's own recorded direct speech, twice, escalating. |
| 2 | **PASS** | Shown — Allah's attention increasing with each return, never stated abstractly. |
| 3 | **PASS, disclosed** | `al-malik@1` elision confirmed real and correctly reasoned (the source text does contain `وَأَنْتَ الْمَلِكُ`, confirmed removed from the beat). |
| 4 | **PASS** | `آخِرَ` present twice in the fetched Arabic of beat 3's own quotation — confirmed. |
| 5 | **CONTESTED — see §3 below.** | The excerpt itself is clean of graphic torment and ends on laughter — confirmed by fetch. But bar 5's stated rule is **"no Fire/Judgment adjacency,"** not merely "no punishment at the excerpt's edge," and this story's entire premise, on screen, in the deck's own authored English (beat 4: *"A man comes out of the Fire crawling"*), is the Fire and a Judgment-Day sorting scene. Read strictly, as instructed, this is Fire/Judgment adjacency by the letter of the rule, independent of where the arc lands. |

**Ship: CONTESTED — see §3. Recommend explicit founder sign-off, not a unilateral pass.**

### `az-zahir@1` (id 81)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 41:53 `سَنُرِيهِمْ` confirmed Allah's own first-person promise. Beat 6 correctly disclosed as not carrying bar 1. |
| 2 | **PASS** | Shown — a continuous, escalating promise in two locations, never stated as "God is evident." |
| 3 | **PASS, disclosed** | Shared duʿā is the heaviest and fully disclosed collision; twin-diff against al-batin holds at max 3-word run per the file (not independently re-run at full scale by me). |
| 4 | **PASS, traded, forced** | Confirmed by independent corpus fetch: only 57:3 predicates ẓāhir of Allah among all 8+2 active-participle occurrences. The trade is genuinely forced, not a convenience. |
| 5 | **PASS** | 41:52 clean, 41:54 confirmed sūrah-final (41:55 → 404, independently reproduced). |

**Ship: YES.** The R1 duʿā-beat fix (byte-for-byte against the catalogue) is confirmed correct and necessary — R0's rendering genuinely diverged from `collectible_names.json` id 81.

### `al-batin@1` (id 82)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 50:16 `خَلَقْنَا`/`نَعْلَمُ`/`نَحْنُ أَقْرَبُ` confirmed Allah's own first-person speech. |
| 2 | **PASS** | Shown — a specific, two-part demonstration (knowing the whisper, nearer than the vein), never stated abstractly. |
| 3 | **PASS, disclosed, with one correction** | Shared duʿā disclosed correctly. **The catalogue `meaning`-overlap finding against `al-baqi@1` is factually wrong** (see §1 table above) — a copy-paste from al-akhir's correct finding, not independently checked against id 82's actual field. Does not affect any rendered beat; is a defect in the deck's own self-audit discipline. |
| 4 | **PASS, traded, forced** | Confirmed by independent corpus fetch: only 57:3 predicates bāṭin of Allah among all 3+1 active-participle occurrences (6:120 and 57:13 are about sin/a wall, not Allah). |
| 5 | **PASS** | 50:15 and 50:17 both confirmed clean. |

**Ship: YES, with the meaning-overlap finding corrected in the file** (trivial, does not gate).

### `al-musawwir@1` (id 21)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 3:6 `يُصَوِّرُكُمْ` confirmed Allah's own direct speech (`الذي` construction). |
| 2 | **PASS** | Shown across 3:6/40:64/82:8 — a specific, particular act of forming, never stated as "your form is intentional." |
| 3 | **PASS on (a)/(b) as far as I re-checked; (c) not independently re-run at scale** | Root-collision surface (a) and the token-frequency surface (b) numbers were spot-checked and held; I did not re-run the full 45-deck DP sweep myself. |
| 4 | **PASS** | `يُصَوِّرُكُمْ` (3:6), `صَوَّرَكُمْ`/`صُوَرَكُمْ` (40:64), `صُورَةٍ` (82:8) all confirmed present in the fetched Arabic. Root sweep (19 occurrences, five forms, 11 non-fashioning) independently reproduced exactly. |
| 5 | **NOT VERIFIED — FAIL AS DOCUMENTED.** | **Four of six citations in the deck's own bar-5 successor-sweep table are fabricated or mislabeled** (see §1 table). The "PASS"/"clean" verdict rests on quotations that do not exist at the cited verse numbers. This is not a register judgement call; it is uncorroborated sourcing exactly of the kind the VERIFIER-BRIEF exists to catch, sitting inside a file that carries three separate "verified" stamps. |

**Ship: NO — not as currently documented.** The three rendered beats (3:6, 40:64, 82:8) and the root sweep are genuinely solid and need no rework. **Bar 5 must be re-run from live fetches before this ships**, because right now nobody has actually checked it — including R0, R1, R2, and the blind Sonnet verifier, whose stated scope never covered the successor-sweep table. Re-running it with the correct text (real 3:5: "nothing is hidden…"; real 40:63: "deluded… rejecting the signs," mild, arguably still non-blocking; real 82:6/82:7: "what has deceived you… who created you, proportioned you, balanced you," non-blocking; **real 82:9: "No! But you deny the Recompense" — itself judgment/denial-adjacent and was never actually disclosed or weighed**) is a fast fix, but it has not happened yet.

---

## 3 · The al-akhir Fire/Judgment ruling — disagreeing with R2

`2026-08-04-R2-VERIFICATION.md` §4 upholds al-akhir's bar-5 register call outright: *"the reader is never positioned as the man, the narration's own destination is Paradise 'and ten times over', and it ends with the Prophet ﷺ laughing until his back teeth showed... softening it would remove the thing that makes it land."*

**I agree with every factual claim in that sentence** — I independently fetched Bukhari 6571 and confirmed the excerpt contains no described torment, the destination is Paradise, and the hadith ends in laughter. Where I differ is on what bar 5 actually says. The task brief's wording is explicit: *"No rebuke passages, no Fire/Judgment adjacency, no accusation of the reader."* That is a broader prohibition than "does not terminate in punishment" — R2's argument answers a narrower question than the one bar 5 asks. The deck's own beat 4, in its own authored English, states: *"A man comes out of the Fire crawling."* That is the Fire, named, on screen, as the opening image of the story — not adjacent to the excerpt, but the excerpt's own premise. The scene is also unambiguously a Judgment-Day sorting scene (the literal last person processed out of Hell into Paradise).

I am not overruling R2's emotional/pedagogical argument — it is a genuinely strong one, and this is arguably the single best-known Islamic narration of hope for someone who feels they are too far gone. But "the reader is never positioned as the man" and "it's ultimately about mercy" are both true of the *narrative arc* and neither is what bar 5, read strictly, is testing. **My ruling: CONTESTED, leaning FAIL on the letter of the rule as given.** Two ways to resolve it, neither requiring new fabrication:

1. **Founder explicitly carves out an exception** for narrations that open on Fire/Judgment machinery but terminate in unambiguous mercy with no torment described — codified as a rule, not a one-off, since this is exactly the shape of "hope after the worst case" content the app plausibly wants to be able to render.
2. **Revise beat 4's authored prose** to remove the literal word "Fire" (e.g., "A man is the very last to be released, and comes to Allah again and again…") — beat 4 is the deck's own paraphrase, not a direct quotation, so this does not touch the Sources table or the hadith text at all, only the on-screen framing.

I did not pick between these — that is a founder call, not a verifier call — but I am not willing to call this a clean PASS the way R2 did, given the brief's explicit instruction to read bar 5 strictly.

---

## 4 · Ruling on the two pending duʿā-source pins

Both pins are **YES** — supported by the live fetch of Sahih Muslim 2713a above, which reproduces both excerpted couplets word-for-word (orthographic variants only: sukūn marks, hamza-seat rendering, ya vs. alif maqṣūra — none textual):

- **`al-awwal@1` / `al-akhir@1` → `Sahih Muslim 2713a (excerpt)`: YES.** Both decks' catalogue `dua_arabic` (`اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ`) is confirmed to be the first couplet of the fetched hadith, verbatim.
- **`az-zahir@1` / `al-batin@1` → `Sahih Muslim 2713a (excerpt)`: YES.** Both decks' catalogue `dua_arabic` (`أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ`) is confirmed to be the second couplet, verbatim, correctly excerpted **without** the `اللَّهُمَّ` opener and **without** the leading `وَ` — matching the deck's own R1 disclosure precisely.

The `(excerpt)` qualifier is necessary and correctly modeled on the existing `renderedDuaSources` convention (`al-aleem@1`: `"(opening of the supplication)"`, `al-malik@1`: `"(opening)"`).

---

## 5 · Ruling on the gharib question (item 4)

At-Tirmidhi 2155's closing note, `هَذَا حَدِيثٌ غَرِيبٌ مِنْ هَذَا الْوَجْهِ`, confirmed present on the page. **Resolved, not just disclosed:** "gharib min hādha al-wajh" ("gharib from this route") is at-Tirmidhi's routine methodological note about a *specific chain* he happened to transmit through — it is not, by itself, a downgrade of the hadith's content, and at-Tirmidhi frequently appends it even to hadith the same page grades Sahih (as here, "Sahih (Darussalam)" is printed on the same page as the gharib note). Since Abu Dawud 4700 carries the same core content (the Pen, the command to write, the decree of everything) through a wholly independent chain with a clean **Sahih (Al-Albani)** grade and no such caveat, the deck's approach — treat Abu Dawud 4700 as the primary citation, treat Tirmidhi 2155 as disclosed corroboration only, never rely on Tirmidhi alone — is the methodologically correct handling. **The gharib note does not weaken al-awwal@1's bar-1 claim**, which rests on Abu Dawud 4700, independent of Tirmidhi.

Also independently confirmed: Abu Dawud 4700's own text continues past the deck's quotation with the disownment clause (*"He who dies on something other than this does not belong to me"*), and this is rendered on no beat in al-awwal@1 — confirmed by re-reading the deck against the fetched page.

---

## 6 · Al-Musawwir root sweep (item 6) — the 19/11 split

**Independently reproduced, exact match.** `corpus.quran.com/qurandictionary.jsp?q=Swr` returns "occurs 19 times in the Quran, in five derived forms": 1 (form I `ṣur`, "to incline," 2:260 only) + 4 (form II `ṣawwara`, fashioning: 3:6, 7:11, 40:64, 64:3) + 10 (noun `ṣūr`, the Trumpet — 6:73, 18:99, 20:102, 23:101, 27:87, 36:51, 39:68, 50:20, 69:13, 78:18) + 3 (noun `ṣūrat`: 40:64, 64:3, 82:8) + 1 (active participle `muṣawwir`, 59:24). **11 of 19 are not the fashioning sense** (10 Trumpet + 1 "incline") — confirmed. Bar 4 for the deck's three cited ayat (3:6, 40:64, 82:8) is genuinely met, not traded.

**Beat 6 truncation confirmed real and correctly executed.** 3:6 fetched in full ends `لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ`; the deck's beat 6 stops at `يَشَآءُ…` with a visible ellipsis, and `ٱلْعَزِيزُ ٱلْحَكِيمُ` (Al-Hakeem's, id 26, unstarted) is confirmed rendered nowhere.

**On the weak point the deck flags itself (40:63/"minor judgment theme"):** see §1 — the specific quotation used to argue this is fabricated. The *real* 40:63 ("Thus were those before you deluded who were rejecting the signs of Allah") is milder than the fabricated cattle simile and arguably still supports a "mild, non-blocking" register call, but this was never actually checked before now, and the deck's own hedge ("'minor' is an adjective where §9ak wants a measurement") undersells the actual problem, which is that the citation backing the adjective doesn't exist.

---

## 7 · What I could not verify

- **I did not re-run the full 34/45-deck bar-3(b) DP token sweep for any of the five decks myself.** I confirmed the deck-count integer (45) is accurate and spot-checked several individual token claims (e.g., `first`, `last`, `closer`, `sign`) by reasoning about them, but did not independently recompute the maximum-shared-word-run figures across all 45 decks' full text. This is the single largest unverified surface in this report.
- **I did not independently fetch a printed edition, Shamela, or Dorar for any hadith** — sunnah.com via Wayback only, as instructed as an acceptable method by the brief. All grade lines quoted above are transcribed directly from the fetched HTML, not from any draft's table.
- **I did not locate id 80's catalogue `hadith` field citation** (the "small plant" narration attributed to Ahmad, `sunnah.com/adab:479` per the deck's failed attempt). I attempted one Wayback CDX lookup and was rate-limited (`429 Too Many Requests`); did not retry further. This field is not rendered on any beat in al-akhir@1, so it does not gate the deck, but it remains genuinely unresolved — same limit the drafter disclosed, not resolved by this pass either.
- **I did not exhaustively search for what verse the fabricated "40:63 cattle" quotation in al-musawwir might actually be a garbled version of.** I checked 7:179, 25:44, 47:12, and 8:22 (the most likely candidates given the "cattle"/"worst of creatures" theme) and none matches exactly; it may be a paraphrase/conflation rather than a clean transposition like the other three al-musawwir mislabelings, and I am not confident I've identified its true source.
- **I did not independently verify the intra-pair twin-diff word-run computations** (e.g., al-awwal/al-akhir's "6 words at beat 1," az-zahir/al-batin's "3 words") beyond reading the beats myself and confirming no obvious longer collision by eye. I did not run `difflib` over the full beat text the way the drafts claim to have.
- **I could not independently confirm the "34 shipped decks" figure al-awwal/al-akhir's bar-3(b) tables cite** (as opposed to az-zahir/al-batin/al-musawwir's "45," which I did confirm against the current file) — the asset has grown between when those two pairs' sweeps were run; I did not attempt to reconstruct the historical 34-deck state to check whether the counts were accurate *at the time*.

---

## 8 · Ship/no-ship summary

| deck | verdict | blocking issue |
|---|---|---|
| `al-awwal@1` (79) | **SHIP** | none found |
| `al-akhir@1` (80) | **CONTESTED — hold for founder sign-off on bar-5 Fire/Judgment reading** | beat 3–5's own premise names "the Fire" on screen; disagree with R2's blanket "Upheld" on a strict reading of bar 5 as the brief instructs (§3) |
| `az-zahir@1` (81) | **SHIP** | none found |
| `al-batin@1` (82) | **SHIP** | trivial: correct the false `meaning`-overlap catalogue finding in the file (copy-paste from al-akhir's draft, does not match id 82's actual data) |
| `al-musawwir@1` (21) | **DO NOT SHIP AS-IS** | bar-5 successor sweep is 4/6 fabricated or mislabeled (§1, §6); re-run with live fetches. The three rendered beats and the bar-4 root sweep are solid and do not need rework. |

**Both duʿā-source pins: YES** (§4). **Gharib question: resolved, non-blocking** (§5). **Four-way 57:3 split: clean** (§1).
