# Deck Draft — Ad-Darr (catalogue id 95) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-an-nafi-DRAFT.md`](./2026-08-03-an-nafi-DRAFT.md).** Ids 95 and 96 were
assigned as a **standing ruling**, not a drafting choice: plan §7a.1 — *"Ad-Darr (95) will be paired
with An-Nāfiʿ (96) and never shipped solo"* — and the task brief repeats it as founder-decided.
**This is the single most delicate Name in the catalogue**, deferred through three earlier batches
on reverence grounds and never attempted before this draft.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9bd, plus the
coordinator's live note about the asset moving from 34 to 45 decks (commit `1bca4ae`) mid-draft.
Claim filed at `.context/claims/95.md` **before** drafting; re-read immediately before writing the
verification tables below (§9s) — no new claim on 95 or 96 had landed from another agent.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com/api/v4`; ḥadīth via
Wayback captures of the exact bare `sunnah.com` number (`id_` raw). **Root enumeration cross-checked
against `corpus.quran.com`**, per the standing rule earned at ledger §9av. **Nothing here was
recalled, reconstructed or composed.**

**Bar-3 surface (b), token frequency, was swept against the CURRENT asset and the count is stated as
a number: checked against 45 decks / 861 rendered beat strings** (`assets/content/name_stories.json`
at commit `1bca4ae`), not "all shipped decks" — per the coordinator's live note and new ledger rule
§9bi.

---

## Deck `ad-darr@1` — Ad-Darr

**Why this deck exists, and why it is hard, in one line:** a user meets this Name in the middle of a
bad night, and the English gloss alone — *The Distresser* — reads as an accusation before a single
beat has rendered. **The whole task is proving whether that first impression survives contact with
the actual text, and building the deck so it does not.**

### Selection ran duʿā-first, and the flagged claim was checked

Catalogue id 95's duʿā: `اللَّهُمَّ اجْعَلْ مَا أَصَابَنِي مِنْ ضَرٍّ كَفَّارَةً لِذُنُوبِي وَرَفْعًا
لِدَرَجَاتِي` — *"O Allah, make whatever harm has befallen me an expiation for my sins and a raising
of my ranks."* **Grammatically, this is retrospective.** The verb governing the harm is `أَصَابَنِي`
(*has befallen me*, root `ṣ-w-b`, not `ḍ-r-r`'s own verb), and the petition does not ask Allah to
send or withhold anything — it asks Him to **transform something that has already happened.** That
shape turns out to matter more than any single verse: see "the register decision" below.

**The brief flagged this duʿā as "recorded in an earlier sweep as authored, not narrated" and told
me to verify rather than assume. I ran two checks, not one:**

1. **Web search for the exact string** (`"اجعل ما أصابني من ضر كفارة لذنوبي"`) and for the
   component phrases *kaffāratan li-dhunūbī* / *rafʿan li-darajātī* together. **No hadith page
   returned the combined wording.**
2. **Fetched the nearest well-known candidate**, Ṣaḥīḥ al-Bukhārī 5641/5642 (Abū Saʿīd al-Khudrī and
   Abū Hurayra): *"No fatigue, nor disease, nor sorrow, nor sadness, nor hurt, nor distress befalls a
   Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his
   sins for that."* — `مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ وَلاَ وَصَبٍ ... إِلاَّ كَفَّرَ اللَّهُ بِهَا
   مِنْ خَطَايَاهُ`. **This carries the *kaffāra* (expiation) half of the catalogue duʿā closely — it
   is very likely what that half draws on — but it contains no "raising of ranks" clause at all**,
   and it is a third-person statement about what happens, not a first-person petition.

**Conclusion: AUTHORED, not narrated — consistent with the flag, and I did not find a single
narration containing both clauses.** Stated at its true strength, per the method's limit below: this
is a negative result from a web search and one targeted primary-source fetch, not a full ḥadīth
concordance. Per COLLISION-LEDGER §9bc, *"a negative retrieval result is a claim about the retrieval,
not about the world"* — I am reporting what I could not find, not asserting the combination does not
exist anywhere in the corpus. **UNPINNED. No catalogue change recommended** (per the standing rule
that every confident catalogue-change recommendation in this project has been wrong).

### The root sweep — the deck's actual foundation

**Run before any verse was chosen**, because the brief asked directly: is Allah ever the finite
subject of a `ḍ-r-r` verb, the way `al-khafid@1` found zero for `kh-f-ḍ`?

**Method:** the complete 6,236-āyah Uthmānī text (`api.quran.com/api/v4/quran/verses/uthmani`),
diacritics stripped, hand-classified by word-form and verse; **then cross-checked against
`corpus.quran.com`'s Quran Dictionary** (an independent morphological tagging, per ledger §9av).
The cross-check caught a real gap in my own hand sweep — recorded, not hidden.

| | my hand sweep (first pass) | `corpus.quran.com` | reconciled |
|---|---|---|---|
| Total `ḍ-r-r` occurrences | 60 | **74**, in **11** derived forms | **74** |

**The 14-occurrence gap was a single mechanical cause, found and named:** my substring filter
required `ض` immediately followed by `ر`. Every Form III (`يُضَآرَّ`), Form VIII (`ٱضْطُرَّ`), and the
participles `ضَآرّ`/`مُضَآرّ`/`مُضْطَرّ` carry a long alif or another consonant **between** those two
letters (`ض` + alif/ṭāʾ + `ر`), which is invisible to a plain substring match. That is exactly the
class of error `corpus.quran.com` exists to catch (§9av). Corrected sweep, itemised:

**Note on "11": `corpus.quran.com` counts 11 distinct morphological categories for the whole root**
(Form I verb, Form III verb, Form VIII verb, five noun types, two participle types). Separately, my
own hand sweep found Form I's 19 occurrences spread across 11 distinct surface word-forms (different
pronoun suffixes: `yaḍurru`, `yaḍurruka`, `yaḍurrukum`, …) — **the same number, 11, by coincidence,
counting two different things.** Stated explicitly so the two "11"s in this table are not conflated.

| form | count | Allah ever the finite subject? |
|---|---|---|
| Form I verb `yaḍurru` ("directly harms") — 19 occurrences across 11 surface word-forms | 19 | **0 of 19.** Every subject is a human, an idol, a plot, or "the entire creation" — never Allah. Full list checked: 2:102, 3:111, 3:120, 3:144, 3:176, 3:177, 4:113, 5:42, 5:105, 6:71, 9:39, 10:18, 10:106, 11:57, 21:66, 22:12, 25:55, 26:73, 47:32. In 4 of these (3:144, 3:176, 3:177, 47:32) **Allah is the grammatical OBJECT** — *"they will never harm Allah at all"* — confirming He cannot be harmed, not that He harms |
| Form III `yuḍārra` ("to be made to suffer") — 3 occurrences | 3 | **0 of 3.** 2:233 (no mother shall be made to suffer through her child), 2:282 (no scribe or witness shall be harmed), 65:6 (do not harm them [divorced wives]) — all human subjects, family/business law |
| Form VIII `uḍṭurra` ("to be compelled by necessity") — 7 occurrences | 7 | **2 of 7 — and these are the exception, disclosed at full strength.** 2:126 and 31:24 both read `ثُمَّ أَ/نَضْطَرُّهُ إِلَىٰ عَذَابِ ٱلنَّارِ` — **"then I/We will force him/them to the punishment of the Fire."** Allah is explicit first-person subject **in both**. The other 5 (2:173, 5:3, 6:119, 6:145, 16:115) are passive — "whoever is compelled by necessity" — with no agent named |
| Noun forms (`ḍurr`, `ḍarr`, `ḍarrāʾ`, `ḍarar`, `muḍṭarr`) — 43 occurrences | 43 | not applicable (nouns have no grammatical subject); several are complements of `massa`/`arāda` with Allah as the *verb's* subject — see below |

**Sum check against the headline (§9ak/§9av discipline): 19 + 3 + 7 + 43 = 72. That is 2 short of
`corpus.quran.com`'s 74.** Rechecked: the corpus page also lists the active participle `ḍārr`
(2 occurrences: 2:102 `بِضَآرِّينَ`, 58:10 `بِضَآرِّهِ`) as a separate 11th form, which my table above
folded into "noun forms" without counting explicitly. **74 = 19 + 3 + 7 + 2 (active participle) + 43
(other nouns)** — corrected arithmetic, stated so a verifier does not have to redo it. Neither
participle has Allah as its referent (both are Satan/magicians "not harming anyone except by Allah's
permission").

**The honest, corrected finding — stronger than "zero" because it is precise:** across all 74
occurrences of `ḍ-r-r` in the Qur'ān, **Allah is the finite grammatical subject of a `ḍ-r-r` verb
exactly twice, and both instances are the identical formulaic clause — "then I/We will force him to
the punishment of the Fire" — addressed to those who have chosen disbelief (2:126, 31:24).** Allah is
**never** the subject of the ordinary, direct-harm verb form (`yaḍurru`, "He harms [someone]") that
the English gloss *The Distresser* suggests to a modern reader. **The one place He genuinely is
grammatical agent of this root is the narrowest, most eschatological possible use of it — finalising
a chosen outcome, not inflicting an arbitrary hardship — and that is the opposite of what a reader at
11pm is afraid this Name means.**

### The register decision, made from that finding, not around it

**This deck never puts Allah as the grammatical subject of directly harming a person.** Every beat
that touches ḍurr does so the way the Qur'ān itself overwhelmingly does: through `massa` ("touch,"
Allah as subject, `ḍurr` as complement) or through the duʿā's own `aṣābanī` ("has befallen me,"
agentless). **The two Form-VIII exceptions (2:126, 31:24) are disclosed in this table and used
nowhere on a beat** — they are Hellfire clauses for deliberate disbelief, and rendering either would
be the exact accusation the reverence bar exists to prevent.

## Beats

**Beat 1 · bridge:**
> Something happened, and it is still happening. You did not imagine the weight of it, and you are not the first person to lie awake wondering whether it means something about you.

**Beat 2 · name_intro** *(catalogue id 95 `english`, verbatim, no added gloss)*:
> الضَّارُّ — Ad-Darr — The Distresser

*No authored gloss was added here, deliberately.* Every other paired/delicate deck this wave
(`al-khafid@1`) added an interpretive gloss at beat 2. For this Name, adding one before the story has
been told would be the deck's own prose making a claim it has not yet earned — bar 2's exact failure
mode. The Name is left to stand until beat 8 answers it.

**Beats 3–5 · story — "Which people are tested most":**
> 3. Saʿd ibn Abī Waqqāṣ said: "I asked, 'O Messenger of Allah, which people are most severely tested?'"
> 4. He ﷺ said: "The Prophets, then the next best, then the next best. A person is tested according to his religious commitment — if he is firm in his religion, his test is more severe, and if his religion is frail, he is tested according to it."
> 5. "Trials continue to afflict a person until they leave him walking on the earth with no sin on him." And of the same theme, in the Prophet's ﷺ own words elsewhere: "The greatest reward comes with the greatest trial. And indeed, when Allah loves a people He tests them."

**Beat 6 · verse** *(visible partial quotation, ellipsis shown)*:
> "And if Allah should touch you with adversity, there is no remover of it except Him…" — Qur'an 6:17

**Beat 7 · duʿā** *(catalog id 95, verbatim in full)*:
> اللَّهُمَّ اجْعَلْ مَا أَصَابَنِي مِنْ ضَرٍّ كَفَّارَةً لِذُنُوبِي وَرَفْعًا لِدَرَجَاتِي
> *Allahumma ij'al ma asabani min dharrin kaffaratan lidhunubi wa-raf'an lidarajati*
> "O Allah, make whatever harm has befallen me an expiation for my sins and a raising of my ranks."
> **NO source. Deliberately unpinned** — see the duʿā-provenance check above.

**Beat 8 · takeaway (pair-synergy):**
> Saʿd asked which people are tested most, and the answer started with the Prophets — not with him, not to make him feel singled out. What is happening to you tonight has a category, and the category is not punishment. Ad-Darr is the Name for what a hard thing can become. An-Nafi — the second Name of your answer — is the Name for what it becomes.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched) | Grading | Status |
|---|---|---|---|---|
| 1 | Saʿd b. Abī Waqqāṣ asked which people are most severely tested; the Prophet ﷺ answered about the Prophets, then those nearest in excellence, testing according to religious commitment, continuing "until they leave him walking on the earth with no sin on him" (beats 3–5) | `sunnah.com/ibnmajah:4023` — Wayback `20210207170756`, `id_` raw | **Hasan (Darussalab)** — printed grade line | ✅ `قُلْتُ يَا رَسُولَ اللَّهِ أَىُّ النَّاسِ أَشَدُّ بَلاَءً قَالَ الأَنْبِيَاءُ ثُمَّ الأَمْثَلُ فَالأَمْثَلُ يُبْتَلَى الْعَبْدُ عَلَى حَسَبِ دِينِهِ ... فَمَا يَبْرَحُ الْبَلاَءُ بِالْعَبْدِ حَتَّى يَتْرُكَهُ يَمْشِي عَلَى الأَرْضِ وَمَا عَلَيْهِ مِنْ خَطِيئَةٍ`. Quoted whole, no elision |
| 2 | "The greatest reward comes with the greatest trial. And indeed, when Allah loves a people He tests them." (beat 5, closing clause — **this matches catalogue id 95's own `hadith` card field**) | `sunnah.com/tirmidhi:2396` — Wayback `20260214170558`, `id_` raw | **Hasan (Darussalab)**; Tirmidhī's own classification on the page: *ḥasan gharīb min hādhā al-wajh* | ✅ `إِنَّ عِظَمَ الْجَزَاءِ مَعَ عِظَمِ الْبَلاَءِ وَإِنَّ اللَّهَ إِذَا أَحَبَّ قَوْمًا ابْتَلاَهُمْ`. Narrated Anas b. Mālik. **Note: this page carries a SECOND, separate hadith on the same isnād** — "when Allah wants good for His slave, He hastens his punishment in this world…" — **fetched, read, and deliberately not used**: `khayr`/`sharr` framing plus "hastens punishment" risks being misread as "your suffering proves He does not love you," the opposite of the register this deck needs |
| 3 | "And if Allah should touch you with adversity, there is no remover of it except Him." (beat 6) | `api.quran.com/api/v4/verses/by_key/6:17?fields=text_uthmani,text_imlaei&translations=20` | Qur'ān, Saheeh International | ✅ `وَإِن يَمْسَسْكَ ٱللَّهُ بِضُرٍّ فَلَا كَاشِفَ لَهُۥٓ إِلَّا هُوَ` — **quoted as far as the ellipsis, visible `…` on the beat.** The dropped second clause is itemised below |
| 4 | Successor sweep n−1 | `verses/by_key/6:16` | Qur'ān | ✅ fetched, quoted nowhere: *"He from whom it is averted that Day — [Allāh] has granted him mercy. And that is the clear attainment."* Judgment-Day mercy, positive, no punishment |
| 5 | Successor sweep n+1 | `verses/by_key/6:18` | Qur'ān | ✅ fetched, quoted nowhere: *"And He is the subjugator over His servants. And He is the Wise, the Aware."* No punishment; disclosed for sibling-root risk below |
| 6 | Full-text `ḍ-r-r` enumeration (this deck's actual foundation) | full 6,236-āyah Uthmānī text, `api.quran.com/api/v4/quran/verses/uthmani`, hand-classified; cross-checked against `corpus.quran.com/qurandictionary.jsp?q=Drr` | — | ✅ **74 occurrences, 11 derived forms** (corpus figure, reconciled against my own 72-then-74 table above). Allah finite-subject in exactly 2, both Form VIII, both a Hellfire clause for chosen disbelief (2:126, 31:24) |
| 7 | 2:126 and 31:24, fetched and read, **used on no beat** | `verses/by_key/2:126`, `verses/by_key/31:24` | Qur'ān | ✅ `فَأُمَتِّعُهُۥ قَلِيلًا ثُمَّ أَضْطَرُّهُۥٓ إِلَىٰ عَذَابِ ٱلنَّارِ وَبِئْسَ ٱلْمَصِيرُ` (2:126) · `نُمَتِّعُهُمْ قَلِيلًا ثُمَّ نَضْطَرُّهُمْ إِلَىٰ عَذَابٍ غَلِيظٍ` (31:24) — both explicit divine punishment of disbelievers; **the reason this deck disclosed rather than hid the "Allah is subject twice" finding** |
| 8 | Card corroboration cross-check: catalogue id 95's own `hadith` field | `assets/content/collectible_names.json` id 95 | — | ✅ matches source #2 exactly (the second, "greatest reward" clause of Tirmidhi 2396). The card's citation is accurate |
| 9 | Duʿā provenance search | web search (two queries, itemised above) + Bukhārī 5641/5642 fetch | — | ⚠️ **No single narration located with both clauses. UNPINNED.** Stated as a retrieval limit, not a proof of absence (§9bc) |
| 10 | Sickness-expiates-sin theme, thematically adjacent, **quoted on no beat** | `sunnah.com/bukhari:5641` — Wayback `20210127115502`, `id_` raw | ṣaḥīḥ (Ṣaḥīḥ al-Bukhārī; no per-page grade line, collection-level) | ✅ `مَا يُصِيبُ الْمُسْلِمَ مِنْ نَصَبٍ ... إِلاَّ كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ`. Narrated Abū Saʿīd al-Khudrī and Abū Hurayra |
| 11 | 48:11 fetched, evaluated, **rejected** | `verses/by_key/48:9` through `48:14` | Qur'ān | ✅ fetched in full; rejection reasoning below |
| 12 | 39:38 fetched, evaluated, **not selected** (held as an alternative) | `verses/by_key/39:36` through `39:40` | Qur'ān | ✅ fetched in full; reasoning below |

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met on beat 6.** Allah is the explicit named subject of `يَمْسَسْكَ` ("touches you"), with `بِضُرٍّ` as the complement — the Name's own root, in Allah's own revealed words (not a narrative character's speech; not a "Qul" command reporting a human declaration). Not a trailing epithet: it is the entire clause the beat quotes. **Bar 4 is a partial trade** — the verb is `massa`, not a `ḍ-r-r` verb itself, because the full-text sweep (row 6) shows Allah is never the subject of the ordinary Form-I `ḍ-r-r` verb anywhere in the Qur'ān. The Name's own root reaches the beat as a noun, governed by Allah's verb of touching — the same class of trade as `al-khafid@1`'s `w-ḍ-ʿ` for `kh-f-ḍ` | **yes — beat 6, traded per bar 4** |
| 2 | **shown, not stated** | No beat asserts *"Ad-Darr uses hardship to bring you back"* — that is catalogue id 95's own `lesson`, deliberately not used. Beats 3–5 **show** it: a specific companion asking a direct, unflinching question, and an answer that scales trial to the strength of faith rather than to guilt. The duʿā (beat 7) shows the same shape from the other side — a person asking that what already happened be turned into something | **yes — beats 3–5 and 7** |
| 3 | **no sibling collapse, including against the twin** | Three surfaces below, plus the twin-diff (held in `an-nafi-DRAFT.md`, per precedent) | **yes, with disclosures itemised** |
| 4 | **the Name's own root appears in the source text** | **Traded on the verse beat** (root is a noun, not the finite verb) and **recovered in full on the duʿā beat**, which renders `ضَرٍّ` in Arabic on screen, gate-eligible. Same partial-recovery shape as `al-khafid@1` | **yes — beat 7, in Arabic; beat 6, as a noun object** |
| 5 | **register — the bar the whole deck lives or dies on** | See "Read as a user at 11pm," below. Beat 6 trimmed with a visible ellipsis specifically to avoid rendering the trailing `قَدِيرٌ`/"competent" (bar-3 risk against decked `al-qadir@1`) — a secondary gain, not the reason for the trim. **The two places Allah IS grammatical subject of this root (2:126, 31:24) are Hellfire clauses for chosen disbelief and are used nowhere** — the deck's single hardest register decision, made explicitly | **the deck's central finding; see below** |

### The successor sweep

| excerpt | n−1 | n+1 | verdict |
|---|---|---|---|
| **6:17** | **6:16** — *"He from whom it is averted that Day — [Allāh] has granted him mercy. And that is the clear attainment."* Judgment-Day, positive | **6:18** — *"And He is the subjugator over His servants. And He is the Wise, the Aware."* No punishment anywhere in either neighbour | **Cleanest bar-5 result available for this Name** — no warning, rebuke or punishment in either direction |
| **6:17's own second clause** (dropped by the ellipsis) | — | — | `وَإِن يَمْسَسْكَ بِخَيْرٍ فَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ` — *"And if He touches you with good — then He is over all things competent."* **Trimmed for two reasons**: (a) it is not needed to make Ad-Darr's point, and quoting only the ḍurr-half keeps the beat focused; (b) *"competent"* is the fetched Saheeh rendering of `قَدِيرٌ`, which risks a bar-3 hit against decked `al-qadir@1`'s Name-gloss family. **Visible ellipsis shown on the beat** per format §7 |
| **48:11** (evaluated, rejected) | **48:9–10** — pledge of allegiance, "the Hand of Allah is over their hands" | **48:12** — *"…and you assumed an assumption of evil and became a people ruined."* **48:13** — *"…then indeed, We have prepared for the disbelievers a Blaze."* | **REJECTED, not merely passed over.** 48:11 is textually the single strongest pairing of `ḍ-r-r` and `n-f-ʿ` with Allah as subject of *irāda* in the whole Qur'ān (`إِنْ أَرَادَ بِكُمْ ضَرًّا أَوْ أَرَادَ بِكُمْ نَفْعًۢا`). **It is refused because of what surrounds it, not what it says.** It is addressed, in continuous second person, to hypocrite Bedouins making excuses for skipping Ḥudaybiyyah; the very next āyah calls that same "you" *"a people ruined"*; the āyah after that promises the disbelievers the Blaze. Excerpting 48:11 in isolation does not remove the rhetorical force of the passage it sits inside — a night reader who is already doubting themselves could hear *"who could stop Allah if He wanted to harm you"* as confirmation that they are being interrogated, not comforted. **This is worse than the 42:26 precedent** (disclosed non-blocking in `al-afuw@1`): there the addressee shifts to a third-person class ("the disbelievers"); here the second person never lets go |
| **39:38** (evaluated, held) | **39:37** — *"...Is not Allāh Exalted in Might and Owner of Retribution?"* trailing epithet, not quoted | **39:39–40** — *"Say, 'O my people, work according to your position...'"* addressee shifts away from "me" to a general warning; **39:40** — *"To whom will come a torment disgracing him and on whom will descend an enduring punishment."* Two verses out, addressee-shifted | **Not selected, but not disqualified.** `إِنْ أَرَادَنِىَ ٱللَّهُ بِضُرٍّ` is the Prophet's own first-person declaration ("if Allah intended **me** harm..."), ending "Say: Sufficient for me is Allah" — a genuinely warm, tawakkul-forward shape. Held back only because (a) it pairs `ḍurr` with `raḥma`, not `nafʿ`, risking the dense `r-ḥ-m` sibling root if quoted whole; (b) 6:17's neighbours are cleaner on bar 5 by a wider margin. **Recorded as a real, available alternative for a founder who prefers its first-person warmth to 6:17's third-person address** |

### Bar 3, surface 1 — Arabic roots

| root | where | renders in Arabic? | collision check |
|---|---|---|---|
| `ḍ-r-r` — the Name's own | duʿā only (`ضَرٍّ`) | **yes, beat 7** | Not spent by any decked Name. Full enumeration above |
| `k-sh-f` | 6:17 `كَاشِفَ` | no — verse beats are English-only in this deck (matching the 11/14 shipped majority per plan §7) | no deck |
| `m-s-s` | 6:17 `يَمْسَسْكَ` | no | no deck |
| `b-l-w` | Ibn Mājah 4023 `بَلاَءً`/`يُبْتَلَى` | no (story beats never render Arabic in any of the 45 shipped/drafted decks) | no deck |
| `j-z-y` | Tirmidhī 2396 `الْجَزَاءِ` | no | no deck |
| `k-f-r` | duʿā `كَفَّارَةً` | **yes, beat 7** | `k-f-r` in the sense of *kaffāra* (expiation) is distinct from `k-f-r` (disbelief) as a root but shares consonants; checked against `al-ghaffar@1`/`al-ghafur@1`/`at-tawwab@1` (`gh-f-r` root, different) — no collision; `kaffāratan` renders on no other decked duʿā |
| `r-f-ʿ` | duʿā `رَفْعًا` | **yes, beat 7** | ⚠️ **This is `ar-rafi@1`'s own root, in Arabic, on a different Name's duʿā screen.** Catalogue-locked (id 95's `dua_arabic` is fixed). Disclosed as the same class of defect already logged for id 41/42 (§9as, §9c) — a fourth instance across the catalogue of a Name's own root surfacing on an unrelated duʿā screen. No catalogue change recommended |

### Bar 3, surface 2 — token frequency, 45 decks / 861 rendered strings

| token this deck renders | n across 45 decks | decks | verdict |
|---|---|---|---|
| `distress` / `distresser` | 2 / 0 | `al-haleem@1` ("anxiety and distress," duʿā translation) | different sense (emotional unease vs the Name's own gloss); zero shared 3-gram; disclosed |
| `harm` | 2 | `al-haleem@1` (a hadith about "harmful and annoying words"), `al-wakeel@1` ("suffering no harm") | different move in both — neither is about hardship-as-transformation; disclosed |
| `trial` / `trials` | 0 / 1 | `ar-rauf@1` ("protect me from trials," duʿā translation) | different register (a request to be spared vs this deck's request to transform what already happened); zero shared run |
| `test` / `tested` | 0 / 0 | — | clean |
| `expiat*` / `kaffara` | 0 | — | clean — first occurrence in the corpus |
| `written` / `decree` / `decreed` | 0 / 0 / 2 | `al-qayyum@1` (death decreed during sleep), `al-lateef@1` ("destiny has decreed") | this deck does not render "written"/"decreed" on any beat (the "already-decreed" framing lives in An-Nafi's story, not here) — recorded for the pair as a whole, not a same-deck collision |
| `Sa'd` / `severely tested` / `walking on the earth with no sin` | 0 each | — | clean, first occurrence |
| `category` / `singled out` | 0 each | — | clean |

**Move-level check (§9an surface 3), run against the nearest thematic neighbours:**

| shipped/drafted deck | shared theme | measured difference |
|---|---|---|
| `al-haleem@1` — forbearance, the gap between what is earned and what is done | Both are about hardship's meaning | Al-Ḥalīm's engine is *the interval before a reckoning*; Ad-Darr's is *what a thing that already happened can become*. No shared scripture, no shared rendered string, opposite direction of attention (forward-waiting vs backward-transforming) |
| `al-qayyum@1` — "the gap was on your side, not His" | Both touch on trial/testing indirectly | Al-Qayyūm's move is about **sustaining attention never lapsing**; Ad-Darr's is about **a specific hardship's category**. Zero shared 3-gram |
| `al-jabbar@1` [S] — "what broke," restoration | Both are about pain | Al-Jabbār's arc is loss-then-repair (Yaʿqūb/Yūsuf); Ad-Darr's is a companion's direct question about testing, with no loss-and-return shape. Different narrative genre entirely (dialogue vs multi-decade family story) |

### Translation decisions, itemised

| rendered on a beat | published English on the fetched page | what I did, and why |
|---|---|---|
| "And if Allah should touch you with adversity, there is no remover of it except Him…" | Saheeh International, byte-close as fetched | Quoted verbatim as far as the ellipsis; no re-rendering needed — the clause is not theologically contested |
| "The greatest reward comes with the greatest trial. And indeed, when Allah loves a people He tests them." | sunnah.com's own published English on the Tirmidhī 2396 page: *"Indeed greater reward comes with greater trial. And indeed, when Allah loves a people He subjects them to trials..."* | Lightly smoothed for the beat's one-breath rule (spec §criterion 4) — *"subjects them to trials"* → *"tests them"* — without changing the claim. The clause about "whoever is content/discontent" that follows is **not quoted**, because it risks reading as a demand for a specific emotional performance under hardship, which this deck does not want to ask of a reader at 11pm |
| "Trials continue to afflict a person until they leave him walking on the earth with no sin on him." | Ibn Mājah 4023 page: *"Trials will continue to afflict a person until they leave him walking on the earth with no sin on him."* | Quoted near-verbatim; tense smoothed for beat flow |

### Rejected — fetched, evaluated, and recorded

| candidate | what it is | why refused |
|---|---|---|
| **Qur'an 48:11** | The strongest textual pairing of `ḍ-r-r` + `n-f-ʿ`, Allah subject of *irāda* | **Rejected on bar 5.** See the successor sweep above — the surrounding rebuke of the Bedouins is not removable by excerpting one verse |
| **Qur'an 39:38** | Prophet's first-person "if Allah intended me harm..." | **Held, not rejected** — see successor sweep. Recorded as an available alternative anchor |
| **Ayyūb, 21:83–84** | The Qur'ān's most vivid `ḍ-r-r` narrative (`مَسَّنِيَ ٱلضُّرُّ`) | **Already spent — shipped `ash-shafi@1`.** Explicitly listed in COLLISION-LEDGER §1a as rejected ground; not re-derived here |
| **10:12, 16:53–54, 39:8, 39:49, 30:33, 23:75** (the "man calls when touched by ḍurr, forgets when relieved" refrain) | A recurring six-verse pattern across the Qur'ān | **Rejected as a class.** Every instance ends within one verse on a rebuke of ingratitude or shirk (e.g. 39:8's *"then indeed, you are of the companions of the Fire"*), which is precisely the arc-terminates-in-punishment shape bar 5 forbids. None was close enough to isolate cleanly |
| **17:56, 17:67** | Idols' inability to remove `ḍurr`; storm-at-sea distress | 17:67 ends *"…and man is ever ungrateful"* (rebuke). Storm/sea-distress imagery is separately flagged in this project as a rejected illustration class (COLLISION-LEDGER §37, the anxiety pair's "storm sleep" precedent) |
| **10:106–107 composite** | 10:106 pairs `n-f-ʿ`/`ḍ-r-r` in one breath (negating idols); 10:107 repeats 6:17's structure with `khayr`/`faḍl` instead of `nafʿ` | Considered as a two-āyah unit for the pair's shared ground; **not taken** because 10:106's move is *idols cannot X*, a negative frame, and 6:17 alone is cleaner and shorter for a single-verse beat |
| **Tirmidhī 2516 (Ibn ʿAbbās)** | Pairs `yanfaʿūka`/`yaḍurrūka` explicitly, "Allah has already written for/against you" | **Reserved for An-Nafi's deck** (its own story), to avoid narrative collapse between the paired decks — see the twin-diff |
| **2:126, 31:24** | The only two places Allah is finite subject of a `ḍ-r-r` verb | **Fetched, read, disclosed at length above, used on no beat.** Both are Hellfire clauses for deliberate disbelief |

---

## Read as a user at 11pm

**Instruction from the brief: describe, do not defend.**

**Beat 1** reads as recognition, not accusation — it names the weight without naming a cause.
**Neutral to comforting.**

**Beat 2** — the Name itself, `الضَّارُّ` / *The Distresser*, with no gloss. **This is the one beat
where the risk is real and undefended.** A reader who stops here, on the bare English word, before
the story runs, could plausibly think: *this app just told me Allah is what is hurting me.* The deck
is betting that beats 3–7 recontextualise it before the user closes the app — that bet is not free,
and it is named as a bet, not a certainty.

**Beats 3–5** (Saʿd's question and the Prophet's answer) read as **being taken seriously.** A
companion asks the blunt question a hurting person actually asks — *why does this happen, and does
it happen worse to some people?* — and gets a real answer, not a platitude: testing scales to the
person, ending in "no sin on him." **A reader could still hear "the greatest reward comes with the
greatest trial" as a demand to be grateful for pain**, if read as an instruction rather than a
description. The deck does not add "so be thankful" anywhere — that reading is available but not
authored into the text.

**Beat 6** (6:17, trimmed) reads as the deck's clearest structural safety, and also its most literal
brush with the accusation risk: **"if Allah should touch you with adversity"** puts Allah and
*adversity* in the same sentence, on Allah's own authority, addressed to "you." A reader in a hard
place, reading this cold, could take it as confirmation: *yes, this is Him, touching me with this.*
**What the beat does NOT say is who removes it, why, or that it is deserved** — the clause is
entirely about exclusivity of relief ("there is no remover of it except Him"), not about causation
or blame. Whether that distinction lands for a tired reader at 11pm is a genuine open question, not
a settled one.

**Beat 7** (the duʿā) is where the deck's register decision pays off most directly: the grammar is
retrospective (*"whatever has befallen me"*) and the request is entirely forward-facing
(*"make it… an expiation… a raising"*). **This beat asks nothing of Allah except transformation of
something already past** — it is the beat least likely to be misread as accusation, because it does
not narrate Him doing anything; it narrates the reader asking.

**Beat 8** hands the user to An-Nafi before the deck ends. **This is load-bearing, not decorative** —
see "what the pairing carries," below.

**My own read on whether this deck accuses:** no beat states or implies that Allah inflicted the
reader's specific hardship, and the one verse that puts Allah and *ḍurr* in the same clause (beat 6)
is trimmed to its most exclusivity-of-relief form, with the harshest textual instances of Allah's
actual agency over this root (2:126, 31:24) kept off every beat. **The genuine, un-removable risk is
beat 2 standing alone for however many seconds it takes to reach beat 3** — a bare Name with no
softening, by design (see the name_intro note above). Whether that gap is acceptable is the
judgement call a verifier should make explicitly, not one this deck can rule on for itself.

---

## What the pairing carries — stated explicitly

**Ad-Darr's own material cannot resolve into relief. It structurally cannot** — every text in this
deck either withholds Allah's stated reason (beat 6), asks for future transformation without
promising it (beat 7), or describes a category of trial without describing its end (beats 3–5). **An
answer that this suffering *becomes* something does not exist on Ad-Darr's own beats.**

**What An-Nafi supplies, specifically:** the completion of the sentence Ad-Darr's duʿā starts.
Ad-Darr's own duʿā asks for hardship to become *kaffāra* and *rafʿ* — expiation and raising. An-Nafi
is the Name for the state that request describes: something turned toward good. Ad-Darr names the
weight; An-Nafi is the only member of the pair that can name the turn. Beat 8 makes this explicit
rather than leaving it implied, matching the `al-khafid@1`/`ar-rafi@1` precedent of putting the
harder Name first so the deck-experience does not end on hardship.

**Note for the founder, mirroring the al-khafid@1/ar-rafi@1 finding: nothing in the code currently
enforces this pairing.** `NameStoriesService.deckForName(nameId)` serves any deck standalone, and the
ship gate's pair-synergy assertion runs only over `chip_keys`, which this deck carries as `[]`. **Four
pairs now carry a "must ship together" ruling** — Ad-Darr/An-Nāfiʿ (this pair, plan §7a.1),
Al-Qābiḍ/Al-Bāsiṭ, Al-Khāfiḍ/Ar-Rāfiʿ, and (per the coordinator's live note) Al-Muizz/Al-Muzill — **and
none is enforced.** Recorded, not recommended; this is an engineering decision, not a drafting one.

---

## Ship-gate notes

- **`ad-darr@1` must NOT enter `renderedDuaSources`.**
- **Beat 7 is byte-identical to catalogue id 95** — Arabic, transliteration, translation, unmodified.
- **Beat 6 renders no Arabic** (matching the 11/14 shipped majority); `source` uses ASCII `Qur'an`.
- **Beat 6 carries a visible ellipsis** on the rendered string, per format §7's mandatory-disclosure rule for partial quotations.
- **Deck-internal beat-to-beat diff (§9v):** longest shared run between any two beats on this deck is 2 words (*"the greatest"* appears once, inside beat 5 only). Zero pairs at n≥3.
- **§9ar check:** beat 8's final clause ("An-Nafi… is the Name for what it becomes") read directly against beat 7's last words ("a raising of my ranks") — reinforcing, not inverting; no ambiguous standard-Islamic-English phrase that could flip meaning in isolation.
- **Proposed metadata:**

```json
{
  "deck_id": "ad-darr@1",
  "name_id": 95,
  "transliteration": "Ad-Darr",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

> ⚠️ `position_in_pair: 0` is what the asset supports today, not what this deck asks for — it asks
> for **Name₁** (per "what the pairing carries," above), matching the `al-khafid@1` precedent.

## What I could not determine, and the rows a verifier should attack first

1. **The duʿā's provenance negative is unclosed.** I did not find a matching narration; I cannot
   prove none exists. Method limit stated above (§9bc discipline).
2. **Ḥadīth checking is not independent of sunnah.com as a corpus.** No isnād audited; no printed
   edition, Shamela, or Dorar consulted for any citation in this deck.
3. **Beat 2's bare-Name exposure is a judgement call, not a measurement.** I have described it in
   "Read as a user at 11pm" and declined to rule on whether it is acceptable.
4. **The `ḍ-r-r` full-text sweep is mine, cross-checked once against `corpus.quran.com`.** No second
   independent corpus (e.g. a printed concordance) was consulted.
5. **The rows to attack first, in order:** (a) whether trimming 6:17's second clause is honest
   disclosure or a convenient dodge of the `qadir` collision — both reasons are stated, and a
   verifier should decide whether the bar-5 reason alone would have justified the trim; (b) whether
   Ibn Mājah 4023's "tested according to religious commitment" line risks implying that *more*
   suffering signals *more* faith, which this deck does not intend and does not state, but does not
   explicitly guard against either; (c) whether the deck's decision not to gloss beat 2 is the right
   call or whether it leaves too much weight on an un-softened Name for too long.

---

## If bar 5 cannot be cleared even paired — the reasoned-refusal test, applied

The brief asked for this explicitly: **if my honest conclusion were that Ad-Darr cannot clear bar 5
even paired, I should say so with the sweep proving it, rather than ship a deck I do not believe in.**

**My conclusion is that it clears, on the strength of the corrected root sweep** — Allah is never the
grammatical subject of the ordinary "harms" verb anywhere in the Qur'ān, and the two places He is
agent of this root at all are the narrowest possible eschatological use, kept off every beat. That
finding, not reassurance, is what the deck is built on — matching the brief's instruction that the
register be answered structurally, never with a sentence like "He does it to protect you." No beat
in this draft contains that sentence or its equivalent. **This is offered as this drafter's
conclusion, to be overturned by the independent adversarial pass, not as a settled verdict.**
