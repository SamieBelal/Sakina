# Verdict — batch `hadith-story` — Al-Barr (85) · Al-Jami (91) · Al-Ghaniyy (92) · Al-Wajid (71)

**Verifier:** blind adversarial pass, 2026-08-04. Did not write these decks. Verified by fetching
`api.quran.com/api/v4`, `corpus.quran.com`, and Wayback captures of `sunnah.com`, independently of
the drafts' own tables. `assets/content/name_stories.json` and `collectible_names.json` were **read
only**, never modified.

**`name_stories.json` deck count independently confirmed: 45** (`python3 json.load`, matches the
running tally's own confirmed count).

---

## 1 · Citation table — every fetch, what came back, verdict

| # | claim (as it reaches a beat) | URL/key fetched | text returned | ✅/⚠️/❌ |
|---|---|---|---|---|
| 1 | Al-Barr beat 6, "He is truly the Good…" ⟶ Qur'an 52:28 | `verses/by_key/52:28?translations=20,84,85,19,22,203` | Saheeh(20): *"Indeed, we used to supplicate Him before. Indeed, it is He who is the Beneficent, the Merciful."* · Usmani(84): *"We used to pray to Him before. He is surely the Most-Kind, the Very-Merciful."* · **Abdel Haleem(85): "We used to pray to Him: He is the Good, the Merciful One."*** · Pickthall(19): *"Lo! we used to pray unto Him of old. Lo! He is the Benign, the Merciful."* · Yusuf Ali(22): *"Truly, we did call unto Him from of old: truly it is He, the Beneficent, the Merciful!"* · Hilali-Khan(203): *"Verily, We used to invoke Him (Alone and none else) before. Verily, He is Al-Barr… the Most Merciful."* Arabic: `إِنَّا كُنَّا مِن قَبْلُ نَدْعُوهُ ۖ إِنَّهُۥ هُوَ ٱلْبَرُّ ٱلرَّحِيمُ` | ⚠️ **confirmed, no translation reads the rendered opening clause verbatim — see §2** |
| 2 | Al-Barr beats 3–5, 52:25–27 | `52:25`,`52:26`,`52:27` (translations=20) | 52:25 *"And they will approach one another, inquiring of each other."* · 52:26 *"…previously among our people fearful [of displeasing Allāh]"* · 52:27 *"So Allāh conferred favor upon us and protected us from the punishment of the Scorching Fire."* | ✅ matches deck's quotation (beat 4/5 lightly re-cast, disclosed, meaning preserved) |
| 3 | Al-Barr successor sweep, 52:29–30 | `52:29`,`52:30` | 52:29 *"So remind… not a soothsayer or a madman."* · 52:30 *"A poet for whom we await a misfortune of time?"* | ✅ clean, no punishment, matches draft |
| 4 | Al-Barr root sweep, `ب ر ر` = 32 occurrences, exactly 1 divine-attribute use (52:28) | `corpus.quran.com/qurandictionary.jsp?q=brr` | *"The triliteral root bā rā rā occurs 32 times… twice as tabarru, 22 times as barr, 8 times as birr."* Every other `barr` gloss in the page is **"the land"** (geographic, e.g. 17:70, 29:65, 30:41) or **"dutiful"** (19:14, 19:32); **52:28 alone is glossed "(is) the Most Kind"** — the only divine-attribute rendering in the full list. | ✅ **32 confirmed exactly; "exactly one Allah-predicated occurrence" independently corroborated by the corpus's own gloss pattern** |
| 5 | Al-Jami beat 6, 64:9 = Saheeh verbatim, no blending | `verses/by_key/64:9?translations=20` | *"The Day He will assemble you for the Day of Assembly - that is the Day of Deprivation. And whoever believes in Allāh and does righteousness - He will remove from him his misdeeds and admit him to gardens beneath which rivers flow, wherein they will abide forever. That is the great attainment."* | ✅ **byte-exact match to the beat** (`Allāh`→`Allah` only). R1 reversal verified real — no blended string reaches the screen. |
| 6 | Al-Jami successor sweep, 64:8/64:10 | `64:8`,`64:10` | 64:8 clean (belief/light) · 64:10 punishment aimed at *"those who disbelieved and denied Our verses"* — a different, named group, one āyah past a complete, untruncated quotation | ✅ matches draft's non-blocking disclosure |
| 7 | Al-Jami duʿā = Qur'an 3:9, pin proposed | `verses/by_key/3:9?fields=text_uthmani,text_imlaei&translations=20` | `text_imlaei`: `رَبَّنَا إِنَّكَ جَامِعُ ٱلنَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ ۚ إِنَّ ٱللَّهَ لَا يُخْلِفُ ٱلْمِيعَادَ`. Catalogue `dua_arabic` (id 91, read from `collectible_names.json`): `رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ`. Byte diff: catalogue uses plain alif (`ا`) where the fetch uses alif-wasla (`ٱ`) ×3, and the fetch carries one Qur'anic pause mark (`ۚ`) the catalogue string omits. **No lexical difference — same words, same order, complete āyah, nothing truncated at either end.** | ✅ **PIN CONFIRMED YES — see §3** |
| 8 | Al-Jami successor sweep, 3:8/3:10 | `3:8`,`3:10` | 3:8 clean (ends in Al-Wahhab's own Name-noun, not quoted) · 3:10 punishment aimed at *"those who disbelieve"*, a different group, one āyah past the complete, untruncated duʿā | ✅ matches draft |
| 9 | Al-Jami story, Bukhārī 6167 — Arabic and English fidelity | Wayback `20241126200626/https://sunnah.com/bukhari:6167` | Arabic (page): `إِنَّكَ مَعَ مَنْ أَحْبَبْتَ` — matches the deck's rendered Arabic exactly. **Page's own published English: "You will be with those whom you love."** Deck renders: *"You are with whoever you loved."* Prophet's line is an emphatic nominal clause (no future particle) + perfect-tense verb `أَحْبَبْتَ` ("you have loved") — the deck's present-tense "are"/past-tense "loved" is *grammatically more literal* than the page's own future/present rendering. | ⚠️ **re-rendering, disclosed, not verbatim from the page's own English — see §2** |
| 10 | Al-Jami beat 5, "And us too?"/"never been so glad" — same narration? | same fetch as #9 | Same page, immediately following: *"We (the companions…) said, 'And will we too be so?' The Prophet said, 'Yes.' So we became very glad on that day."* | ✅ **confirmed same narration (6167), not stitched** |
| 11 | Al-Jami corroborating chain, Bukhārī 6171 | Wayback `20220628000314/https://sunnah.com/bukhari:6171` | Independent chain (ʿAbdān←father←Shuʿba←ʿAmr b. Murra←Sālim b. Abī al-Jaʿd←Anas), Arabic `أَنْتَ مَعَ مَنْ أَحْبَبْتَ`, English page: *"You will be with those whom you love."* No age/Hour tail. | ✅ matches draft exactly |
| 12 | Bukhārī 6167/6171 printed grade line | same fetches | **No printed "Grade : X" line on either page** — only a UI toggle checkbox labelled "Grade," no value rendered. Contrast-checked against Tirmidhi 3563 (below), which *does* print one, confirming this is a real absence, not a fetch artifact. | ⚠️ **no grade line to quote — collection-level ṣaḥīḥ (Bukhārī) inferred, not printed. Disclosed correctly in the draft.** |
| 13 | Al-Ghaniyy story, Sahih Muslim 2577a | Wayback `20220721184820/https://sunnah.com/muslim:2577a` | Arabic: `يَا عِبَادِي إِنَّكُمْ لَنْ تَبْلُغُوا ضَرِّي فَتَضُرُّونِي وَلَنْ تَبْلُغُوا نَفْعِي فَتَنْفَعُونِي`. English (page, verbatim): *"O My servants, you will not attain harming Me so as to harm Me, and will not attain benefitting Me so as to benefit Me."* Narrator chain confirmed: `عَنِ أَبِي ذَرٍّ` (Abū Dharr), reporting from Allah (`فِيمَا رَوَى عَنِ اللَّهِ`). Kneeling detail (Abū Idrīs) also confirmed on the same page, correctly *not* used by this deck. | ✅ **byte-exact match, both languages, narrator confirmed** |
| 14 | Muslim 2577a printed grade line | same fetch | No printed "Grade : X" line (same pattern as Bukhārī above — Ṣaḥīḥ Muslim collection-level). | ⚠️ **no grade line to quote — collection-level ṣaḥīḥ (Muslim) inferred, consistent with `al-quddus@1`'s own precedent** |
| 15 | Al-Ghaniyy verse, 35:15–17 | `35:15`,`35:16`,`35:17` (translations=20) | 35:15 *"O mankind, you are those in need of Allāh, while Allāh is the Free of need, the Praiseworthy."* · 35:16 *"If He wills, He can do away with you and bring forth a new creation."* · 35:17 *"And that is for Allāh not difficult."* | ✅ byte-exact match to the beat |
| 16 | Al-Ghaniyy successor sweep, 35:14/35:18 | `35:14`,`35:18` | 35:14: idols cannot hear/answer prayer, will disown worshippers — not an accusation of the reader. 35:18: no soul bears another's burden; *"you can only warn those who fear their Lord"*; ends *"to Allāh is the final destination"* — no punishment clause. | ✅ matches draft, register argument holds up textually — **see §4 for the residual concern** |
| 17 | Sūrat Fāṭir — al-fattah@1 (35:2) and al-haleem@1 (35:45) already shipped | `name_stories.json`, programmatic search for `Qur'an 35:` | `al-fattah@1` verse beat source = `"Qur'an 35:2"`; `al-haleem@1` verse beat source = `"Qur'an 35:45"` | ✅ **confirmed, third deck in Fāṭir if this ships — but the precedent cited for it is stale, see §4** |
| 18 | Al-Wajid bar 1, 93:7 | `verses/by_key/93:7?translations=20` | Arabic `وَوَجَدَكَ ضَآلًّا فَهَدَىٰ`. Saheeh: *"And He found you lost and guided [you],"* | ✅ byte-exact substring match to the beat (`"And He found you lost…"`, `فَهَدَىٰ` visibly elided) |
| 19 | Al-Wajid scene-setting, 93:3–5 | `93:3`,`93:4`,`93:5` | 93:3 *"Your Lord has not taken leave of you… nor has He detested [you]."* · 93:4 *"And the Hereafter is better for you than the first [life]."* · 93:5 *"And your Lord is going to give you, and you will be satisfied."* | ✅ byte-exact, matches beats 2–4 exactly |
| 20 | 93:6 / 93:8 never quoted on this deck | `93:6`,`93:8` (read, not rendered) | 93:6 *"Did He not find you an orphan and give [you] refuge?"* (`al-waliyy@1`'s own verse beat, confirmed shipped) · 93:8 *"And He found you poor and made [you] self-sufficient."* (unspent — `al-mughni@1` shipped on 4:130, not 93:8) | ✅ **confirmed absent from every beat, in Arabic and English, by direct read of the draft** |
| 21 | Sūrah-final check, 93:12 | `verses/by_key/93:12` | HTTP 404 | ✅ confirmed — no punishment anywhere in Sūrat aḍ-Ḍuḥā |
| 22 | Al-Wajid Route-3 closure, Bukhārī 6309 (`al-wadud@1`'s own citation) | Wayback `20220626111210/https://sunnah.com/bukhari:6309` | Arabic: `اللَّهُ أَفْرَحُ بِتَوْبَةِ عَبْدِهِ مِنْ أَحَدِكُمْ سَقَطَ عَلَى بَعِيرِهِ، وَقَدْ أَضَلَّهُ فِي أَرْضِ فَلاَةٍ` — uses `سَقَطَ عَلَى` ("fell upon") and `أَضَلَّهُ` (root ض-ل-ل, "lost/strayed"). **No `وَجَدَ` (w-j-d) anywhere.** | ✅ **confirmed exactly — Route-3 closure holds** |
| 23 | Al-Wajid/al-qayyum@1 93:1–3 non-repeat | `name_stories.json`, `al-qayyum@1` beats | Story sources: Bukhārī 595, Bukhārī 595, Qur'an 39:42; verse: Qur'an 2:255. **No 93:x citation anywhere in the current shipped deck.** | ✅ **confirmed the R1 error is not repeated — the shipped deck does not use 93:1–3** |
| 24 | Al-Wajid duʿā, id 71 byte-for-byte | `collectible_names.json` id 71 vs. beat 6 | Programmatic string equality: **`True`**, 83 characters both, no dagger-alif (`U+0670`) in either string | ✅ **re-derived independently — no divergence, confirmed fixed** |
| 25 | All four decks' `name_intro`/`dua` byte-for-byte vs. catalogue | `collectible_names.json` ids 85/91/92/71 | `arabic`/`transliteration`/`english`/`dua_arabic` — programmatic equality **`True` on all 16 checks** | ✅ verified |
| 26 | Al-Jami / Al-Ghaniyy `hadith` catalogue fields | `collectible_names.json` ids 91, 92 | id 91: *"Salman al-Farsi… (Seerah)"* — no collection/number, uncitable as printed, correctly disclosed and unused by the deck. id 92: *"Richness is not having many things… (Bukhari & Muslim)"* — also no collection/number, **not addressed anywhere in the Al-Ghaniyy draft** | ⚠️ **Al-Ghaniyy gap — see §5** |

---

## 2 · Translation-discipline ruling — Al-Barr beat 6 (the assigned open ruling)

**The finding on record is correct and independently reproduced: no published translation among the
six fetched (20/84/85/19/22/203) reads "We used to call on Him before this."** Every one uses
"supplicate"/"pray to"/"invoke"/"call unto," and none says "before this" (all say "before"/"of old").
The beat is a full re-rendering of the whole clause, not a verbatim quote with one substituted word.

**Ruling: do not ship as currently worded.** §9bh permits re-rendering only with **one named
published translation that agrees** — the draft's own disclosure supplies that backstop for the
tail ("the Good," from Abdel Haleem) but not for the opening clause, which is the drafter's own
prose dressed as scripture. This is the same shape of problem the project already reversed once on
this same batch (Al-Jami's 64:9, §1 row 5) — a screen-rendered string in quotation marks, cited to a
verse number, that does not correspond to any translation of that verse.

**Concrete fix, verified compliant:** ship **Abdel Haleem (resource 85) verbatim**, truncated with a
visible ellipsis before the trailing "Merciful One" (which would otherwise render Ar-Raḥīm's own
Name-noun in English, the exact hazard the current beat already disclosed and cut):

> **"We used to pray to Him: He is the Good…"**

This is a single, real, named, verbatim published translation — no re-rendering judgment call
required at all. It keeps "the Good," which is the word the drafter argued for on legibility grounds
against the catalogue gloss ("The Source of Goodness"), so nothing is lost there. It costs nothing
that the current beat has, and it removes the one open compliance question entirely.

**On whether Saheeh verbatim would make the Name "invisible":** tested directly. Saheeh's word is
"the Beneficent." `name_intro` (rendered immediately before, byte-for-byte) already tells the reader
"الْبَرُّ — Al-Barr — **The Source of Goodness**." "Beneficent" and "Goodness" share no lexical root
on screen, so the echo is weaker than "the Good" would give — but the reader has already been told
what the Name means two beats earlier; "Beneficent" is not disconnected in *sense* (it means "doing
good"), just in surface wordform. **Not invisible. A real but modest legibility cost, not an erasure
— and moot, because Abdel Haleem verbatim avoids paying it at all.**

**On the Al-Jami hadith re-rendering (§1 row 9), by the same standard:** the deviation from the
page's own English ("with those whom you love" → "with whoever you loved") is disclosed, and is
independently confirmed *more* grammatically literal to the Arabic (`أَحْبَبْتَ`, perfect tense) than
the page's own future-tense gloss. No alternate published English translation of this ḥadīth was
named as agreeing, because none was fetched or is readily available for cross-check the way multiple
Qur'an translations are — this is a structural gap in how §9bh applies to ḥadīth (one English
rendering per collection, typically), not evidence of fabrication. **Ruled CONTESTED, not FAIL**: the
content is faithful, disclosed, and improves rather than degrades literal accuracy, but it does not
satisfy the letter of "verbatim, or re-rendered with a named agreeing translation," because there is
no second translation to name. Recommend disclosing this structural gap explicitly in the deck rather
than implying the re-rendering is fully backstopped the way the Qur'an cases are.

---

## 3 · Al-Jami duʿā pin — explicit ruling

**YES.** `collectible_names.json` id 91's `dua_arabic` is Qur'an 3:9, the **complete āyah**, not a
truncation. The only differences from the `api.quran.com` fetch are orthographic (alif-wasla vs.
plain alif ×3, one pause mark) — the rasm and the word sequence are identical, start to finish.
**No `(opening)` qualifier is needed** (unlike `al-malik@1`'s 3:26 pin, which genuinely is a partial
āyah). `renderedDuaSources` should carry `'al-jami@1': "Qur'an 3:9"` with no qualifier, exactly as
the draft proposes.

---

## 4 · Al-Ghaniyy register ruling — 35:14–18, and the Sūrat Fāṭir precedent

**On the register argument itself: holds up under independent read.** 35:15's address
(`يَـٰٓأَيُّهَا ٱلنَّاسُ`) is unconditional and universal — it is not preceded by a rebuke of the
reader (35:14 is about idols' incapacity, not the reader's disbelief) and 35:16's "if He wills, He
can do away with you" is **not conditioned on any human failing** — unlike 47:38/57:24/60:6/64:6,
which are all explicitly triggered by turning away or withholding. This is a real, checkable
distinction, not an assertion, and it separates 35:15–17 from the rejected candidates on the text's
own grammar.

**CONTESTED on tone, not on the mechanical rebuke test.** "If He wills, He can do away with you and
bring forth a new creation" is not an *accusation*, but it is a statement of the reader's
expendability, delivered without qualification. Against the deployment context this app itself
names (rendering at night to someone in distress), that is a starker thing to read than "you are in
need of Allah" alone. The deck's own bridge/takeaway do real work softening this (framing it as "He
loses nothing, and still invites you to ask" rather than "He could replace you") — **the mitigation
is in the authored beats, not in the verse itself.** I would not block on this alone, but I would not
call it "swept, clean" either; it is a judgment call the founder should make with the verse's actual
weight in view, not a pre-cleared register the way 52:17–24 (Al-Barr, this same batch) genuinely is.

**The Sūrat Fāṭir "three decks" precedent is confirmed factually but the citation to
`al-wahid@1` is wrong.** `al-fattah@1` (35:2) and `al-haleem@1` (35:45) are both shipped, so
Al-Ghaniyy at 35:15–17 would make three. But the draft cites `"al-wahid@1`'s own third-deck
disclosure"` as the second precedent for "three decks in one sūrah, already accepted." **I read
`al-wahid@1`'s current draft directly and it says the opposite of what is cited**: *"Sūrat
al-Anbiyāʾ carries four decks once this ships, not three… This deck's fourth-in-Anbiyāʾ is chosen,
not forced"* — `ash-shafi@1`, `al-mujeeb@1`, and `al-wahhab@1` are **already shipped** in Sūrat
al-Anbiyāʾ (independently confirmed against `name_stories.json`), and `al-wahid@1` would be the
**fourth**, past its own stated three-deck ceiling, and it says so explicitly. Al-Ghaniyy's draft is
citing a stale or superseded version of that self-disclosure. **This does not, by itself, make
35:15–17 wrong** — three decks in a 114-sūrah book is not inherently a problem — but the precedent
argument as written overstates how settled "stacking a sūrah" is in this project: it has happened
twice now (Āl ʿImrān, four decks counting `al-jami@1`; Anbiyāʾ, four counting `al-wahid@1`), and both
times at least one instance was "chosen, not forced." Al-Ghaniyy's own 35:15–17 is also chosen, not
forced (the draft compares it against 6:133, 31:26, 4:131, 22:64 and picks it on merit) — so if this
ships, it should cite itself accurately as the same *chosen* pattern, not lean on a "three is already
settled" precedent that the sibling deck itself has since corrected.

---

## 5 · Five-bars verdicts

### `al-barr@1` (85)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | 52:26–27 (Allah's own narrating voice, story beats) sets up 52:28's naming clause as its direct conclusion, not a floated epithet. Fetched, confirmed. |
| 2 | **PASS** | Shown (fear → favour → protection), naming arrives only after, in the speakers' own mouths. |
| 3 | **PASS** | Full sweep independently re-run: "kind"/"kindness"=7 (confirmed exact), "merciful"=9 (confirmed exact, both across 45-deck asset), "favour"/"favor"=2 (confirmed, combining both spellings), "firm"=2 (confirmed count, though the draft names only `al-mumin@1` and silently omits `al-khaliq@1`'s unrelated "firm lodging" hit — same count, incomplete itemisation, non-blocking). No blocking collision found independently. |
| 4 | **PASS** | Root sweep independently confirmed 32 total occurrences, and corpus's own glosses confirm 52:28 is the sole Allah-predicated use. |
| 5 | **PASS** | 52:17–24 predecessor and 52:29–30 successor both independently fetched and clean — no warning, no rebuke, no punishment adjacency anywhere in the run. The cleanest of the four decks in this batch on this bar. |

**Ship-blocking issue: translation discipline on beat 6 (§2).** Not a bar-1–5 failure — a §9bh/§9bj
compliance failure with a concrete, verified fix (Abdel Haleem verbatim, ellipsis before "Merciful
One").

### `al-jami@1` (91)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | Duʿā carries `جَامِعُ` (active participle, believers addressing Allah's own act); verse carries `يَجْمَعُكُمْ`, finite verb, Allah subject, confirmed by fetch. Story is a disclosed bar-4 trade, does not need to carry the root. |
| 2 | **PASS** | The man's question, the "nothing prepared but love" admission, and the Companions' reaction are shown, not asserted. |
| 3 | **PASS** | "gather" family independently confirmed at n=3 (exact match: `al-wakeel@1`, `al-lateef@1`, `al-mughni@1`), "assemble" independently confirmed at n=0, "come together" confirmed at n=1 (`ar-raqeeb@1`). No blocking hit found independently. |
| 4 | **PASS** | Confirmed twice over — duʿā and verse both carry the root, by fetch. |
| 5 | **PASS** | 3:8/3:10 and 64:8/64:10 both independently fetched; both n+1 punishment clauses target a different, named group one āyah past a complete, untruncated quotation — the same shape twice, matching the project's own stated precedent. |

**Findings, both non-blocking:** the Bukhārī re-rendering of `مَعَ مَنْ أَحْبَبْتَ` is disclosed and
verified faithful (arguably more literal than the page's own English) but is not backstopped by a
named agreeing translation, because none exists to name (§2). The duʿā pin is confirmed correct with
no qualifier needed (§3).

### `al-ghaniyy@1` (92)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | Story: Muslim 2577a's `يَا عِبَادِي...` is Allah's own first-person reported speech, confirmed by fetch, narrator Abū Dharr. Verse: 35:16's conditional verb, Allah subject, confirmed by fetch, no `قُلْ` in 35:1–14. |
| 2 | **PASS** | Negated capacity (story) and counterfactual replacement (verse) both show rather than assert. |
| 3 | **CONTESTED** | "harm" independently swept at **n=2 before this deck** (`al-wakeel@1` AND `al-haleem@1`'s "harmful" — I found the second hit the draft's own sweep missed), not n=1 as the draft states; this deck would bring it to **n=3**, not n=2. The undercounting does not change the substantive non-collision ruling (`al-haleem@1`'s "harmful words He hears" is a different job — verbal abuse endured, not capacity-to-harm — than either `al-wakeel@1`'s or this deck's usage), but the drafter's own "measured, not stated" claim was itself not fully measured. "benefit," "free of need," and the `al-quddus@1` move-level comparison were all independently re-checked and hold up exactly as claimed. |
| 4 | **PASS** | `ٱلْغَنِىُّ` confirmed at 35:15 by fetch, Allah's own predicate. |
| 5 | **CONTESTED, see §4.** | Register argument holds up on the mechanical "conditioned on disbelief" test but the counterfactual-replacement content itself is starker than the deck's own "swept, clean" framing implies; the Sūrat Fāṭir "three decks, precedented" citation to `al-wahid@1` is factually stale (§4). |

**Additional gap:** catalogue id 92's own `hadith` field ("Richness is not having many things…
(Bukhari & Muslim)") is never audited in this draft, unlike the equivalent fields on Al-Barr and
Al-Jami in the same batch. It is uncitable as printed (no collection/number) and is not used on any
beat, so this is a documentation-completeness gap, not a content defect.

### `al-wajid@1` (71)

| bar | verdict | evidence |
|---|---|---|
| 1 | **PASS** | `وَجَدَكَ` confirmed by fetch — finite verb, Allah the explicit subject, Qur'an, not reported speech. Met without a trade. |
| 2 | **PASS** | 93:7 is a concrete act with a concrete object ("found you lost"), not an assertion. |
| 3 | **PASS** | Every quantitative claim independently re-derived from the 45-deck asset with a stricter word-boundary regex than simple substring matching, and **all matched exactly**: "found"=5 (`ar-rahman@1`×2, `at-tawwab@1`, `al-ghafur@1`, `al-mughni@1`), "find"=5 (`ar-rahman@1`, `as-salam@1`, `al-ghafur@1`, `al-waliyy@1`, `al-mughni@1`), "lost"=8 (`ar-rahman@1`, `al-wadud@1`×3, `ash-shafi@1`, `al-khafid@1`×3). This is the most precisely verified sweep in the batch. |
| 4 | **PASS** | Confirmed directly, no trade needed. |
| 5 | **PASS** | 93:12 independently confirmed HTTP 404; no punishment anywhere in the sūrah. |

**All other load-bearing claims independently re-derived and confirmed exactly:** 93:1–3 is not
reused (the shipped `al-qayyum@1` cites Bukhārī 595 / 39:42 / 2:255, no 93:x at all); 93:6/93:8 are
absent from every beat, confirmed by direct read; the lost-camel Route-3 closure is independently
re-fetched (Bukhārī 6309) and confirmed to contain **no `w-j-d` anywhere**; the duʿā is byte-for-byte
identical to the catalogue, and the previously-reported dagger-alif divergence is confirmed **not
present** on independent re-derivation.

**This is the strongest deck in the batch on measurement discipline** — every claim I checked against
this deck's own tables matched exactly, which is itself worth recording, since the brief's whole
premise is that such tables are usually wrong somewhere.

---

## 6 · Bar 3(b), stated as required

**Deck count swept: 45** (the current `assets/content/name_stories.json`), independently confirmed
by direct `json.load` and cross-checked against the running tally's own count.

---

## 7 · Every rendered ḥadīth — grade line as printed

| ḥadīth | deck | printed grade line |
|---|---|---|
| Bukhārī 6167 | `al-jami@1` | **None printed.** UI toggle labelled "Grade" present; no value rendered on the page. Collection-level Ṣaḥīḥ (Bukhārī) inferred, matching the drafter's own disclosed convention. |
| Bukhārī 6171 | `al-jami@1` (corroborating, not quoted on any beat) | **None printed.** Same pattern. |
| Muslim 2577a | `al-ghaniyy@1` | **None printed.** Same pattern, confirmed against `al-quddus@1`'s own established precedent for this exact ḥadīth. |
| Bukhārī 6309 (checked, not used) | `al-wajid@1` Route-3 | **None printed.** Same pattern. |
| Jamiʿ at-Tirmidhi 3563 (id 92 duʿā provenance, not pinned) | `al-ghaniyy@1` | **"Grade : Hasan (Darussalam)"** — printed and confirmed by fetch, contrasted against the three above to validate that my extraction method genuinely detects a grade line when one exists. At-Tirmidhi's own words on the page: `حَدِيثٌ حَسَنٌ غَرِيبٌ`. |

**No Bukhārī/Muslim ḥadīth cited in this batch carries a separate printed grade line on sunnah.com** —
this is expected (both collections are consensus-ṣaḥīḥ, graded at the collection level, not
per-ḥadīth, the way Tirmidhi/Abū Dāwūd/Ibn Mājah are). All four decks disclose this correctly where
they address it at all.

---

## 8 · Ship / no-ship, per deck

- **`al-barr@1` (85) — SEND BACK, one fix.** Bars 1–5 all independently verified PASS, including the
  cleanest register sweep in the batch. **Do not ship beat 6 as worded.** Replace with Abdel Haleem
  (resource 85) verbatim, truncated at a visible ellipsis: *"We used to pray to Him: He is the
  Good…"* This is a mechanical, low-risk fix — no other beat, table, or ruling changes.

- **`al-jami@1` (91) — SHIP.** All five bars PASS on independent verification. The duʿā pin to
  Qur'an 3:9 is confirmed correct, no qualifier needed. The one open item (the Bukhārī re-rendering
  lacking a named agreeing translation) is a structural gap in how the translation-discipline rule
  applies to single-source ḥadīth English, not a fabrication or a fidelity failure — recommend the
  deck say so explicitly rather than implying full §9bh coverage, but this does not block shipping.

- **`al-ghaniyy@1` (92) — SEND BACK, two items, neither individually blocking but both real.**
  (1) The bar-3(b) "harm" count is off by one (n=2 before this deck, not n=1) — re-run and correct
  the table; the substantive non-collision verdict likely survives re-measurement, but say so with a
  correct number. (2) The Sūrat Fāṭir "three decks, precedented" argument cites `al-wahid@1`'s
  *superseded* self-disclosure; correct the citation or drop the "already accepted" framing and let
  the register argument (§4, which does hold up) stand on its own. Neither defect touches bar 1, 2,
  or 4, which are solid. The register call on 35:16 itself is a founder-level judgment, not something
  I can resolve as CONTESTED — I would not personally block on it, but I would not sign it "swept,
  clean" either.

- **`al-wajid@1` (71) — SHIP.** All five bars PASS, and every quantitative and citation claim I
  independently re-derived matched the draft exactly, including the harder-to-get-right items (the
  Route-3 ḥadīth closure, the dagger-alif re-derivation, the word-boundary token sweep). This is the
  strongest deck in the batch.

**All four decks: no `reflection` beat.** Confirmed as a completion gap, and confirmed **project-wide,
not batch-specific** — an independent sweep of all 45 shipped decks in `name_stories.json` found
**zero** decks anywhere in the current asset using a `reflection` kind (44 decks have exactly 8 beats,
1 has 10 with extra `recognition`/`comfort_verse` beats; none has 9+ with `reflection`). This spine
gap is real per `DRAFTING-BRIEF.md` §5a as cited in the `al-wajid@1` draft's own review stamp, but it
is not something these four decks introduced — it is an unaddressed gap across the entire shipped
asset, and should be tracked and fixed at that scope, not as a per-deck blocker.

---

## 9 · What I could not verify

1. **No isnād audit for any ḥadīth in this batch.** Chains were read off the sunnah.com page text
   and matched narrator-by-narrator against the drafts' own transcriptions, but narrator reliability
   was not independently assessed — same standing limit every prior pass in this project has carried.
2. **Only one Wayback capture per ḥadīth URL was fetched**, not cross-checked against a second
   capture year or a printed edition (Ibn Ḥajar's commentary, Shamela, Dorar) for either the Arabic
   or the English.
3. **The al-wajid `w-j-d` 107-occurrence full-corpus enumeration was not re-run** — I independently
   re-verified the specific claims that touch this batch's bars (93:7's verb form, the absence of
   `w-j-d` in the lost-camel ḥadīth) but did not re-derive the full 107-occurrence count from scratch.
4. **`corpus.quran.com`'s search interface was only queried for `brr` (Al-Barr's root)** — I did not
   independently cross-check the `jmE` (129 occurrences) or `gh-n-y` (18 occurrences) sweeps the
   other two decks claim against the corpus directly; I verified their *downstream uses* (the
   specific āyāt cited, translations, successor sweeps) by direct Qur'an fetch instead, which is a
   narrower check than re-running the full-text sweep.
5. **I did not check every one of the 771/954-string n-gram sweeps claimed in the Al-Ghaniyy and
   Al-Wajid drafts token-by-token** — I spot-checked the highest-stakes tokens (the ones the drafts
   themselves flagged as live hazards) with word-boundary-aware regex against the live asset, and
   found one undercounting error (Al-Ghaniyy's "harm"). I cannot rule out smaller undercounts
   elsewhere in either deck's fuller tables that I did not independently re-run.
6. **No tafsīr was consulted for the 35:14–17 register reading** — same limit the drafter itself
   names; my own reading is grammatical/structural, not exegetical.
7. **I did not run the ship gate test** (`test/content/name_stories_ship_gate_test.dart`) — read-only
   pass, per the hard constraints in the verifier brief.

---

## 10 · Reconciliation against `2026-08-04-R2-VERIFICATION.md`

Read in full after the verdict above was written and locked. R2 states its own limit plainly: it is
reliable on source fidelity (fetched, diffed word-for-word, programmatic) and **not** reliable on
bar-1 ladder judgements, bar-3(c) engine arguments, or bar-5 register calls, because the same author
wrote most of the wave it is checking. That self-assessment matches what I found by doing the
independent pass it says is still owed.

**Where I agree, in full:**

- **Al-Barr beat 6 (R2 §2.9).** R2's fetch and mine are identical down to the translation strings —
  no published translation reads "We used to call on Him before this." R2's own summary is exact:
  *"The Name-word was argued; the opening clause was not."*
- **Al-Jami's dagger-alif fix (R2 §2.8).** Independently re-derived and confirmed present-tense fixed
  — programmatic string equality `True`, no `U+0670` in either string.
- **Al-Jami's Bukhārī re-rendering (R2 §3).** R2's own characterisation — *"closer to the Arabic than
  the page's own 'with those whom you love'"* — is exactly what I found comparing the perfect-tense
  Arabic against both renderings.
- **The 19-deck `reflection` gap (R2 §5), all four of this batch included.** Confirmed independently.

**Where I go further than R2, or disagree:**

1. **R2 leaves Al-Barr's beat 6 "for a ruling" and only widens the disclosure. I make the ruling
   this task assigned me to make: ship Abdel Haleem (85) verbatim, truncated at an ellipsis before
   "Merciful One" — "We used to pray to Him: He is the Good…"** This is a fully compliant, zero-cost
   fix that neither R2 nor the draft itself proposed; both stopped at "disclosed, not fixed."

2. **R2 does not catch the bar-3(b) undercount in `al-ghaniyy@1`.** R2's own method (§1) is a
   Qur'an-fidelity and ḥadīth-grade check, not a re-run of the drafters' token sweeps — so this gap
   is expected given R2's stated scope, but it means R2's blanket "VERIFIED — content" stamp on
   `al-ghaniyy@1` should not be read as having checked this. The "harm" count is off by one (`n=2`
   before this deck, not `n=1`), independently found by re-running the sweep with a corpus-wide
   substring search rather than trusting the draft's own itemised list.

3. **R2 does not catch the stale `al-wahid@1` citation in `al-ghaniyy@1`'s Sūrat Fāṭir precedent
   argument.** This is outside R2's stated method (cross-draft citation accuracy isn't a fidelity or
   grade check), but it is exactly the class of error the top-level brief warns about — a claim
   checked against a sibling table instead of against the sibling's current source. I read
   `al-wahid@1`'s current draft directly; it says the opposite of what is cited.

4. **R2's grade table (§3) reports "Ṣaḥīḥ ✅" for Bukhārī 6171 without distinguishing a printed
   grade line from a collection-level inference.** The underlying finding is the same (no fabrication,
   genuinely Ṣaḥīḥ), but the top-level brief specifically asks verifiers to quote the **printed**
   grade line, and none of Bukhārī 6167/6171, Muslim 2577a, or Bukhārī 6309 has one — the "Ṣaḥīḥ" is
   inferred from the collection, not read off the page the way Tirmidhī 3563's "Hasan (Darussalam)"
   is. Not a disagreement about the content's authenticity — a disagreement about what "read the grade
   line" should mean when a collection prints none, and I'd rather the distinction stay visible than
   collapse into a uniform "✅ Ṣaḥīḥ" the way R2's table presents it.

5. **R2 renders no explicit register verdict on `al-ghaniyy@1`'s 35:14–18**, consistent with its own
   stated limit (bar-5 calls are "not reliable" coming from this author). I render one: CONTESTED, not
   clean-pass. The mechanical "conditioned on disbelief" test genuinely distinguishes 35:15–17 from
   the rejected candidates, but 35:16's counterfactual replacement is still a starker statement than
   the deck's "swept, clean" framing implies, and the mitigation lives in the authored bridge/takeaway
   rather than in the verse itself. This is the founder-level call R2 explicitly says it cannot make
   and this pass was asked to make in its place.

6. **No disagreement found on `al-wajid@1`.** Every claim in that draft that I independently
   re-derived — including the ones R2 does not itemise at all (the Route-3 closure, the 93:1–3
   non-repeat, the word-boundary token sweep) — matched exactly. R2's implicit confidence in this
   deck (it appears only in the completion-gap list, with no defect entry) is, on this pass, earned.
