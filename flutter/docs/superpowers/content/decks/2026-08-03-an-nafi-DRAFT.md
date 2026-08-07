# Deck Draft — An-Nafi (catalogue id 96) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-ad-darr-DRAFT.md`](./2026-08-03-ad-darr-DRAFT.md) first.** Ids 95 and 96
are a standing-ruling pair (plan §7a.1); this file assumes that file's root sweep and register
decision and does not repeat the full method discussion.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9bd.
Claim filed at `.context/claims/96.md` before drafting; re-read immediately before writing this
table (§9s). All scripture verified by live fetch at draft time; ḥadīth via Wayback captures of the
exact bare `sunnah.com` number, `id_` raw. **Bar-3 surface (b) checked against 45 decks / 861
rendered strings** (`name_stories.json` at commit `1bca4ae`), stated as a number per the
coordinator's live note (ledger §9bi).

---

## Deck `an-nafi@1` — An-Nafi

**Why this deck is easier than its twin, and why that is worth naming:** nothing about *benefiting*
someone risks reading as an accusation. The difficulty here is not reverence — it is that the
Qur'ān, like its twin's root, almost never makes Allah the **direct grammatical subject** of "He
benefits [someone]." The deck has to be built the same structural way as Ad-Darr's: on Allah's
**will and decree** governing the outcome, not on a raw transitive verb.

### Selection ran duʿā-first

Catalogue id 96's duʿā: `اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا
مُتَقَبَّلًا` — *"O Allah, I ask You for beneficial knowledge, pure provision, and accepted deeds."*
Card `hadith` field is **empty** (COLLISION-LEDGER §7) — no card-level corroboration to lean on, so
every citation here had to be found independently.

**The duʿā is narrated, not authored — checked, not assumed.** It matches **Sunan Ibn Mājah 925**
(Umm Salama; the Prophet ﷺ said this upon completing the Fajr prayer's salām), **Sahih (Darussalam)**.
Codepoint diff run (not eyeballed): catalogue `وَعَمَلًا مُتَقَبَّلًا` vs the fetched page's `وَعَمَلاً
مُتَقَبَّلاً` — same letters, **the tanwīn-fatḥ mark sits before the alif in the catalogue and after
it on the fetched page**, twice. **Rasm-identical, not byte-identical**, per the project's own
vocabulary (COLLISION-LEDGER §9ax). Commas in the page's punctuation are not in the catalogue string;
immaterial. **PROPOSED PIN: `'an-nafi@1': "Sunan Ibn Majah 925"`.**

### The root sweep — shared foundation with Ad-Darr, run and reconciled the same way

**Method:** full 6,236-āyah Uthmānī text, hand-classified; cross-checked against
`corpus.quran.com/qurandictionary.jsp?q=nfE`.

| | my hand sweep | `corpus.quran.com` | reconciled |
|---|---|---|---|
| Total `n-f-ʿ` occurrences | 42 | **50**, in **3** derived forms | **50** |

**The 8-occurrence gap has the same mechanical cause as the twin's sweep:** the plural noun
`مَنَافِعُ` (*manāfiʿ*, "benefits") carries an alif between `ن` and `ف`, invisible to a plain
substring filter. All 8 are noun-only (livestock, iron, Ḥajj — "benefits for people," Allah as
subject of *creating* or *sending down* the thing, not of "benefiting" as a verb) and do not change
the verb-subject question.

| form | count | Allah ever the finite subject? |
|---|---|---|
| Form I verb `yanfaʿu` ("to benefit/profit") — **31 occurrences**, cross-checked verse-for-verse against `corpus.quran.com`'s own list | 31 | **0 of 31.** Every subject is: an idol (negated, ~13×), intercession (`shafāʿa`, permission-gated), a person's own faith/truthfulness/excuse (belated, at Judgment), the Prophet Nūḥ's own counsel, wealth or children (negated), fleeing (negated), a reminder (`dhikrā`), kinship, or "the boy" in the Yūsuf/Mūsā narratives. **Never Allah.** Full list: 2:102, 2:123, 2:164, 5:119, 6:71, 6:158, 10:18, 10:98, 10:106, 11:34, 12:21, 13:17, 20:109, 21:66, 22:12, 25:55, 26:73, 26:88, 28:9, 30:57, 32:29, 33:16, 34:23, 40:52, 40:85, 43:39, 51:55, 60:3, 74:48, 80:4, 87:9 |
| Noun `nafʿ` — 11 occurrences | 11 | not applicable (noun); every instance is the negated idol-power formula (*"…holds for you no power to cause harm or benefit"*) or a comparative ("nearer to you in benefit") |
| Noun `manāfiʿ` — 8 occurrences | 8 | not applicable (noun); all are "benefits" in livestock/Ḥajj/iron, Allah as subject of *creating*/*sending down* the thing that carries the benefit, never of "benefiting" itself |

**Sum check: 31 + 11 + 8 = 50.** Matches the corpus headline exactly on the first pass — no
correction needed here (unlike the twin's sweep, where the cross-check found a real gap).

**The finding, stated at its true size, and it is the mirror image of Ad-Darr's:** Allah is **never**
the finite grammatical subject of "benefits" (`yanfaʿu`) anywhere in the Qur'ān — not once, in 31
occurrences, verified against an independent morphological corpus. **Where the Qur'ān does put Allah
in charge of benefit, it is through creation** (`khalaqa`, `anzala` — He creates or sends down the
thing that benefits) **or through decree** (`kataba` — He has already written it), never through a
raw "He benefits you" clause. This deck is built on the second of those two patterns; its twin is
built on the analogous pattern for harm.

## Beats

**Beat 1 · bridge:**
> Something is already working in your favour tonight, in a place you have not thought to look. That is not a guess about your circumstances — it is the shape of a sentence the Prophet ﷺ taught a young companion, word for word.

**Beat 2 · name_intro** *(catalogue id 96 `english`, verbatim)*:
> النَّافِعُ — An-Nafi — The Benefiter

**Beats 3–5 · story — "What the whole creation could not do":**
> 3. Ibn ʿAbbās, a young companion, was riding behind the Prophet ﷺ one day. The Prophet ﷺ said: "Young man, I will teach you some words: be mindful of Allah, and He will protect you. Be mindful of Allah, and you will find Him in front of you."
> 4. "When you ask, ask Allah. And when you seek help, seek help from Allah."
> 5. "And know: if the whole creation gathered together to benefit you with something, they could not benefit you except with something Allah had already written for you. And if they gathered to harm you with something, they could not harm you except with something Allah had already written against you. The pens are lifted, and the pages are dry."

**Beat 6 · verse** *(visible partial quotation, ellipsis shown)*:
> "…and the [great] ships which sail through the sea with that which benefits people, and what Allah has sent down from the heavens of rain, giving life thereby to the earth after its lifelessness…" — Qur'an 2:164

**Beat 7 · duʿā** *(catalog id 96, verbatim in full)*:
> اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا
> *Allahumma inni as'aluka 'ilman nafi'an wa rizqan tayyiban wa 'amalan mutaqabbalan*
> "O Allah, I ask You for beneficial knowledge, pure provision, and accepted deeds."
> *Sunan Ibn Majah 925*

**Beat 8 · takeaway:**
> Every person who has ever wanted to help you was still limited to what was already written for you to receive. That is not a small circle of people. It is the entire creation, and it was never enough on its own — and it was never the whole story either.

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched) | Grading | Status |
|---|---|---|---|---|
| 1 | Ibn ʿAbbās riding behind the Prophet ﷺ; "be mindful of Allah and He will protect you… find Him in front of you" (beats 3–4) | `sunnah.com/tirmidhi:2516` — Wayback `20241014011600`, `id_` raw | **Hasan (Darussalam)**; Tirmidhī's own classification on the page: *ḥasan ṣaḥīḥ* | ✅ `يَا غُلاَمُ إِنِّي أُعَلِّمُكَ كَلِمَاتٍ احْفَظِ اللَّهَ يَحْفَظْكَ احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ`. Narrated ʿAbdullāh b. ʿAbbās, via Ḥanash aṣ-Ṣanʿānī |
| 2 | "When you ask, ask Allah… seek help from Allah" (beat 4) | same page | Hasan (Darussalam) | ✅ `إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ` |
| 3 | "…if the whole creation gathered to benefit you… except with something Allah had already written for you. And if they gathered to harm you… except with something Allah had already written against you. The pens are lifted, and the pages are dry." (beat 5 — **bar 1's carrier**) | same page | Hasan (Darussalam) | ✅ `وَاعْلَمْ أَنَّ الأُمَّةَ لَوِ اجْتَمَعَتْ عَلَى أَنْ يَنْفَعُوكَ بِشَيْءٍ لَمْ يَنْفَعُوكَ إِلاَّ بِشَيْءٍ قَدْ كَتَبَهُ اللَّهُ لَكَ وَلَوِ اجْتَمَعُوا عَلَى أَنْ يَضُرُّوكَ بِشَيْءٍ لَمْ يَضُرُّوكَ إِلاَّ بِشَيْءٍ قَدْ كَتَبَهُ اللَّهُ عَلَيْكَ رُفِعَتِ الأَقْلاَمُ وَجَفَّتِ الصُّحُفُ` — **quoted whole, no elision.** Re-rendered from the Arabic (see translation table) |
| 4 | "…the [great] ships which sail through the sea with that which benefits people, and what Allah has sent down from the heavens of rain, giving life thereby to the earth after its lifelessness…" (beat 6) | `api.quran.com/api/v4/verses/by_key/2:164?fields=text_uthmani,text_imlaei&translations=20` | Qur'ān, Saheeh International | ✅ `وَٱلْفُلْكِ ٱلَّتِى تَجْرِى فِى ٱلْبَحْرِ بِمَا يَنفَعُ ٱلنَّاسَ وَمَآ أَنزَلَ ٱللَّهُ مِنَ ٱلسَّمَآءِ مِن مَّآءٍ فَأَحْيَا بِهِ ٱلْأَرْضَ بَعْدَ مَوْتِهَا` — **partial quotation, visible `…` at both ends** (the full āyah also lists the heavens, earth, day/night, animals, wind and clouds, itemised as fetched, not quoted) |
| 5 | Successor sweep n−1 | `verses/by_key/2:163` | Qur'ān | ✅ fetched, quoted nowhere: *"And your god is one God. There is no deity except Him, the Entirely Merciful, the Especially Merciful."* Positive; `r-ḥ-m` sibling root, off-screen |
| 6 | Successor sweep n+1 | `verses/by_key/2:165` | Qur'ān | ✅ fetched, quoted nowhere: *"...and Allāh is severe in punishment."* Addressee shifts to *"those who have wronged"* (third person, idolaters), not the reader; disclosed below |
| 7 | Full-text `n-f-ʿ` enumeration | full Uthmānī text + `corpus.quran.com/qurandictionary.jsp?q=nfE` | — | ✅ **50 occurrences, 3 forms. Allah finite-subject of `yanfaʿu`: 0 of 31**, verse-for-verse cross-checked, exact match on first pass |
| 8 | Duʿā provenance | `sunnah.com/ibnmajah:925` — Wayback `20250417150324`, `id_` raw | **Sahih (Darussalam)** | ✅ `اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلاً مُتَقَبَّلاً`. Narrated Umm Salama; said by the Prophet ﷺ on completing the Fajr salām. Codepoint diff run — rasm-identical, not byte-identical (tanwīn-mark ordering, ×2). **PIN proposed** |
| 9 | 5:119 fetched, evaluated, **rejected** | `verses/by_key/5:116` through `5:120` | Qur'ān | ✅ fetched in full; rejection reasoning below |
| 10 | 12:21, 28:9 fetched, evaluated, **rejected** | `verses/by_key/12:21`, `verses/by_key/28:7` through `28:13` | Qur'ān | ✅ fetched; rejection reasoning below |

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met on beat 5.** Allah is the explicit named subject of `كَتَبَهُ` ("[He] had written it") — twice, symmetrically, for both the benefit-clause and the harm-clause — inside the Prophet's ﷺ own reported teaching. **Traded per bar 4**: the root's own verb `يَنْفَعُوكَ` has *"the whole creation"* (`al-ummah`) as subject, not Allah; Allah's agency is carried by `kataba` (has written/decreed), governing the outcome. Same trade-class as `al-mughni@1`'s `فَأَغْنَاكُمُ ٱللَّهُ` and the twin's beat 6 | **yes — beat 5, traded per bar 4** |
| 2 | **shown, not stated** | No beat asserts *"An-Nafi has placed benefit in places you have not looked"* — catalogue id 96's own `lesson`, deliberately not used verbatim. Beat 5 **shows** it through the Prophet's own teaching to a specific named companion; beat 6 shows it through a concrete list (ships, rain, revived earth) rather than an abstract claim | **yes — beats 3–6** |
| 3 | **no sibling collapse, including against the twin** | See surfaces below and the twin-diff, this file | **yes, disclosed** |
| 4 | **the Name's own root appears in the source text** | Appears as the finite verb `يَنْفَعُوكَ` (beat 5, hadith, subject = the creation, not Allah — bar 1 traded onto `kataba`) and as the noun-governed clause `بِمَا يَنفَعُ ٱلنَّاسَ` (beat 6). **Recovered in full in Arabic on the duʿā beat** (`عِلْمًا نَافِعًا`) | **yes — beats 5, 6 (English), 7 (Arabic)** |
| 5 | **register** | No reverence risk of the twin's kind exists for this Name; the standard bars still apply. 2:165's "severe in punishment" is one verse past the excerpt, addressee-shifted (idolaters, third person) — disclosed, precedent-consistent (`al-afuw@1`'s 42:26) | **clean, one disclosure** |

### The successor sweep

| excerpt | n−1 | n+1 | verdict |
|---|---|---|---|
| **2:164** | **2:163** — *"And your god is one God… the Entirely Merciful, the Especially Merciful."* Positive | **2:165** — *"…and if only they who have wronged would consider… that Allāh is severe in punishment."* Addressee = *"those who have wronged"* (idolaters, third person); does not touch the reader directly | Clean, one disclosure — same class as `al-afuw@1`'s accepted 42:26 |
| **Tirmidhī 2516** (Ibn ʿAbbās) | — | The hadith's own next clause (immediately following, quoted in full on beat 5): *"The pens are lifted, and the pages are dry."* — closes the narration; nothing follows on the page but the isnād note | Strongest possible bar-5 form for a ḥadīth: the excerpt runs to the narration's own end |
| **5:119** (evaluated, rejected) | **5:116–118** — Allah asks ʿĪsā if he told people to worship him and his mother; ʿĪsā denies it, defers judgement ("if You punish them… if You forgive them") | **5:120** — "To Allāh belongs the dominion…" no punishment | **Rejected on proximity to a polemicised passage, not on its own content.** 5:119 itself (*"this is the Day when the truthful will benefit from their truthfulness… gardens… Allah pleased with them"*) is warm and clean. But its immediate predecessor is the Qur'ān's central refutation of the Trinity/divinisation of ʿĪsā — the same class of material `ar-rafi@1`'s claim file separately refused (3:55, 4:158) as "the single most polemicised passage between two faiths, a deck cannot render it without adjudicating." Even unquoted, sitting one verse downstream of it risks the same adjudication-by-selection failure (ledger §9z) |
| **12:21, 28:9** (evaluated, rejected) | — | — | **Rejected on bar 1 and on crowding.** Both are human hope, not divine act (*"la'alla yanfaʿunā"* — "perhaps he will benefit us," spoken by the Egyptian official's wife about the boy Yūsuf, and by Pharaoh's wife about the infant Mūsā) — the grammatical subject is uncertain human speech, not Allah at all. 12:21 also sits inside Sūrat Yūsuf, which already carries two shipped decks (`al-jabbar@1`, `al-lateef@1`); 28:7–13 is explicitly flagged in COLLISION-LEDGER §1a as `al-jabbar@1`'s arc ("a parent's lost child returned") and already blocked Al-Hafeez (39) on that ground |

### Bar 3, surface 1 — Arabic roots

| root | where | renders in Arabic? | collision check |
|---|---|---|---|
| `n-f-ʿ` — the Name's own | duʿā (`نَافِعًا`) | **yes, beat 7** | Not spent by any decked Name. Full enumeration above |
| `ḥ-f-ẓ` | Tirmidhī 2516 `احْفَظِ`/`يَحْفَظْكَ` | no (story beats render no Arabic) | shares consonants with Al-Ḥafeeẓ (39, not yet decked) and shipped `ar-raqeeb@1`'s duʿā (`احْفَظْنِي`); off-screen, no rendered collision |
| `k-t-b` | Tirmidhī 2516 `كَتَبَهُ` | no | no decked Name |
| `ḍ-r-r` | Tirmidhī 2516 `يَضُرُّوكَ` | no | **the twin's own root, quoted on this deck's story beat 5** — see twin-diff below |
| `r-z-q` | duʿā `رِزْقًا` | **yes, beat 7** | ⚠️ shares the provision theme with shipped `ar-razzaq@1`; checked for rendered-string overlap in surface 2 below |
| `q-b-l` | duʿā `مُتَقَبَّلًا` | **yes, beat 7** | no decked Name |

### Bar 3, surface 2 — token frequency, 45 decks / 861 rendered strings

| token this deck renders | n across 45 decks | decks | verdict |
|---|---|---|---|
| `benefit*` / `nafi` | 1 / 1 | `al-kareem@1` ("his gratitude is only for [the benefit of] himself") | different sense (a translator's bracketed gloss on gratitude vs this deck's central theme); zero shared 3-gram |
| `written` | 0 | — | clean — first occurrence in the corpus |
| `pens` / `pages` / `dry` / `lifted` | 0 each | — | clean |
| `provision` / `beneficial knowledge` / `accepted deeds` | 0 each | — | clean |
| `rizq`/`provide`/`provision` (thematic, not string) | — | `ar-razzaq@1` (shipped, "the birds that go out empty and return full") | **Move-level check, not string-level**: Ar-Razzāq's engine is *what reaches you materially, daily*; An-Nāfiʿ's duʿā-clause is one of three petitions (knowledge, provision, deeds) inside a request for **quality/blessedness**, not quantity. No shared rendered string ≥3 words; disclosed |
| `already written for you` / `whole creation` / `entire circle` | 0 each | — | clean, first occurrence |

**Move-level check (§9an surface 3):**

| shipped/drafted deck | shared theme | measured difference |
|---|---|---|
| `ar-razzaq@1` [S] — "what reaches you," the birds parable | Both are about provision reaching a person | Ar-Razzāq's move is **material sufficiency, replenished daily**; An-Nāfiʿ's is **the limit of what any created thing, gathered in total, could ever do for you**. Different scale entirely (a bird's daily flight vs "the whole creation combined") and different grammatical anchor (rizq arriving vs benefit being capped by decree) |
| `al-mughni@1` [S] — "the unlisted share" | Both touch on what a person receives vs. what others control | Al-Mughni's beat is about **what you already have that was never itemised**; An-Nāfiʿ's is about **what an unlimited number of well-wishers still could not add**. No shared scripture, no shared rendered string |
| `al-wakeel@1` [S] — "handing over is not quitting," trust placed with Him | Both are about limits of human agency | Al-Wakīl's move is **releasing the outcome you were never asked to hold**; An-Nāfiʿ's is **naming the ceiling on what other people's help was ever going to be worth**. Related register (tawakkul-adjacent) but a different question answered — disclosed, not blocking |

### Translation decisions, itemised

| rendered on a beat | published English on the fetched page | what I did, and why |
|---|---|---|
| "…if the whole creation gathered together to benefit you… Allah had already written for you… had already written against you…" | sunnah.com's own published English renders **both** clauses as *"…except that Allah had written for you"* — flattening the Arabic's own distinction between `كَتَبَهُ اللَّهُ لَكَ` (written **for** you, the benefit clause) and `كَتَبَهُ اللَّهُ عَلَيْكَ` (written **against**/upon you, the harm clause) | **Re-rendered from the Arabic** to preserve that distinction (`li-ka` vs `ʿalay-ka`), per plan §6 rule 2 — re-render contested-nuance passages rather than paste a published translation that has silently merged two different prepositions into one English phrase. Not a theological dispute, but a real loss of precision the published page makes |
| "…the ships which sail through the sea with that which benefits people…" | Saheeh International, as fetched | Quoted verbatim within the trimmed excerpt; no re-rendering needed |
| "The pens are lifted, and the pages are dry." | sunnah.com: *"The pens are lifted and the pages are dried"* | Tense smoothed ("are dried" → "are dry") for the beat's one-breath rule; no change to meaning |

### Rejected — fetched, evaluated, and recorded

| candidate | what it is | why refused |
|---|---|---|
| **Qur'an 5:119** | "This is the Day when the truthful will benefit from their truthfulness… gardens…" | Rejected on proximity to the ʿĪsā-divinity dialogue immediately preceding it (5:116–118) — see successor sweep |
| **Qur'an 12:21, 28:9** | "Perhaps he will benefit us" — human hope about a child (Yūsuf, Mūsā) | Bar 1 fails (human speech, uncertain hope, not Allah's act); 12:21 crowds Sūrat Yūsuf; 28:7–13 is explicitly `al-jabbar@1`'s reserved arc (COLLISION-LEDGER §1a) |
| **Qur'an 48:11** | `أَرَادَ بِكُمْ نَفْعًا` — Allah subject of *irāda*, paired with `ḍ-r-r` | Rejected for the same reason as the twin's deck — see `ad-darr-DRAFT.md`'s successor sweep. Not re-derived here to avoid the twin's deck and this one disagreeing on a shared finding |
| **Qur'an 10:106** | `مَا لَا يَنفَعُكَ وَلَا يَضُرُّكَ` — idols negated, pairs both roots | Considered as shared ground with the twin's deck; not taken here because the move is a **negative** (idols cannot X), and 2:164 gives an affirmative list instead. Reserved as a fallback if a founder prefers the literal `n-f-ʿ`+`ḍ-r-r` pairing over 2:164's "signs" framing |
| **A weakly-attested "the best of people are those most beneficial to people" saying** | Circulated widely as a hadith (`khayru al-nās anfaʿuhum li-l-nās`) | **Not used.** No ṣaḥīḥ/ḥasan route located; commonly cited without a strong chain (reported with a weak isnād in al-Muʿjam al-Awsaṭ-class sources). Excluded per the standing rule: ṣaḥīḥ or ḥasan only, grade required, and I could not establish one |

---

## The twin-diff — Ad-Darr vs An-Nafi, beat by beat

**Both decks share one narrative universe (companions being taught directly by the Prophet ﷺ about
what is and is not in human control) but use two different narrations, two different companions,
and two different scenes — avoiding the narrative-collapse class named in COLLISION-LEDGER §1a.**

| beat | Ad-Darr | An-Nafi | shared? |
|---|---|---|---|
| 1 · bridge | Names the weight of something already happening | Names something already working in the reader's favour | Structurally parallel (both open on "something is already true"), rendered English shares **zero** run ≥3 words |
| 2 · name_intro | `الضَّارُّ` / The Distresser, no gloss | `النَّافِعُ` / The Benefiter, catalogue verbatim | Different Arabic, different English, no shared string |
| 3–5 · story | Saʿd b. Abī Waqqāṣ asks a direct question; the Prophet ﷺ answers about trial scaling to faith (Ibn Mājah 4023 + Tirmidhī 2396) | Ibn ʿAbbās, riding behind the Prophet ﷺ, is taught a teaching about the limits of the whole creation's help or harm (Tirmidhī 2516) | **Different narrator, different scene, different narration.** Tirmidhī 2516's own text contains **both** `يَنْفَعُوكَ` and `يَضُرُّوكَ` — An-Nafi's deck quotes it in full (both clauses, for the "known translation flattens a distinction" finding above); **Ad-Darr's deck does not quote this hadith at all**, reserving it explicitly (see Ad-Darr's rejected-candidates table) to avoid both decks resting on the same page |
| 6 · verse | Qur'an 6:17, trimmed — Allah touches with `ḍurr`, exclusivity of relief | Qur'an 2:164, trimmed — ships/rain benefiting people, part of a "signs" list | Different sūrahs, no shared āyah, no shared rendered clause |
| 7 · duʿā | Catalogue id 95, unpinned (authored) | Catalogue id 96, pinned to Ibn Mājah 925 | No shared Arabic run ≥2 words. Ad-Darr's duʿā renders `رَفْعًا` (An-Nafi's twin `ar-rafi@1` root, disclosed in Ad-Darr's file); An-Nafi's duʿā renders none of Ad-Darr's root |
| 8 · takeaway | Pair-synergy, points forward to An-Nafi by name | Independent takeaway, does not name Ad-Darr | Matches the `al-khafid@1`/`ar-rafi@1` precedent: only Name₁ carries the explicit forward pointer |

**Deck-internal beat-to-beat diff, run on each deck separately before this cross-deck diff (§9v):**
Ad-Darr's longest internal run is 2 words (see its own file). **An-Nafi's own internal check:**
longest shared run between any two of its own beats is 2 words (*"beneficial knowledge"* appears once,
inside beat 7 only, and *"you already"*/"already written" inside beat 5 does not recur elsewhere).
Zero pairs at n≥3 on either deck, and zero pairs at n≥3 **between** the two decks' full beat sets
(computed over all 16 beats, both files).

**The one real overlap, disclosed rather than hidden: both decks quote a hadith carrying the OTHER
Name's root.** An-Nafi's beat 5 (Tirmidhī 2516) contains `يَضُرُّوكَ` — Ad-Darr's own root — because
the narration itself pairs the two clauses and splitting it would have broken *"The pens are lifted
and the pages are dry"* away from its own antecedent. **This is disclosed, not hidden**, and it
renders in Arabic on no beat (story beats carry no Arabic in either deck). Ad-Darr's own deck does
not reciprocate — it holds Tirmidhī 2516 in reserve and never quotes it, precisely so the pairing's
one shared textual root does not appear on both decks' own selected narrations.

---

## Ship-gate notes

- **`an-nafi@1` PROPOSES entering `renderedDuaSources`: `'an-nafi@1': "Sunan Ibn Majah 925"`.**
  Bidirectional assertion required by the gate — flagged for the transcribing agent.
- **Beat 7 is byte-identical to catalogue id 96** — Arabic, transliteration, translation, unmodified.
- **Beat 6 renders no Arabic**; `source` uses ASCII `Qur'an`, visible ellipsis at both ends of the quotation.
- **Deck-internal beat-to-beat diff:** zero pairs at n≥3 (above).
- **§9ar check:** beat 8's final clause ("it was never the whole story either") read against beat 7's
  last words ("accepted deeds") and beat 5's close ("the pages are dry") — no standard-Islamic-English
  phrase at risk of inverting in isolation.
- **Proposed metadata:**

```json
{
  "deck_id": "an-nafi@1",
  "name_id": 96,
  "transliteration": "An-Nafi",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED — content; spine incomplete (no reflection beat)"
}
```

> ⚠️ Asks for **Name₂**, paired with `ad-darr@1` as Name₁ — see that file's "what the pairing
> carries" section for why the order is not arbitrary.

## What I could not determine

1. **Ḥadīth checking is not independent of sunnah.com as a corpus.** No isnād audited for either
   citation in this deck.
2. **The "best of people" saying's absence from ṣaḥīḥ/ḥasan collections is a search-based negative**,
   not a concordance-based proof of non-existence — same limit class as the twin's duʿā-provenance
   check.
3. **The rows to attack first:** (a) whether 2:164's long "signs" list, trimmed to two clauses,
   still fairly represents the āyah or over-selects the benefit-relevant parts; (b) whether the
   twin-diff's disclosed one-hadith overlap (Tirmidhī 2516 containing `يَضُرُّوكَ`) is genuinely
   non-blocking given it is a story-beat quotation rather than an incidental mention; (c) whether the
   `ar-razzaq@1` move-adjacency (provision theme) needs a sharper differentiator than offered above.
