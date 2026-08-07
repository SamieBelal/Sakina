# `as-sami@1` — As-Sami (The All-Hearing), catalogue id 45 — DRAFT

**Drafted 2026-08-03.** Wave 4. Claim file: [`.context/claims/45.md`](../../../../.context/claims/45.md).
Sibling draft in the same batch: `al-azeez@1` (id 8).

**Selection ran duʿā-first, and the duʿā turned out to be scripture.** Catalogue id 45's
`dua_arabic` `إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ` is **the closing four words of Qurʾān 11:61** —
**rasm-identical to quran.com's `text_imlaei`.** Pin proposal in §7; it is a founder call.

> **CORRECTION (post-verification, 2026-08-03).** This draft originally claimed the tail was
> **"byte-identical… exact string equality"** to `text_imlaei`. That is **false**, caught by the
> wave-2 adversarial verifier's codepoint-level diff: the catalogue's `مُجِيبٌ` and `text_imlaei`'s
> `مُّجِيبٌ` differ by **one shadda (U+0651, idghām)**. The correct description is **rasm-identical**
> — corrected throughout §4 and §7 below. The difference is religiously immaterial and changes
> nothing about the deck (it ships **unpinned** either way), but it is the **second** time this
> project has recorded an inflated equality claim on this exact axis — the pilot wrote
> *"letter-for-letter identical"* for 18:10 when the strings differed. **Six Names now have their
> duʿā identified as scripture on this axis, so the vocabulary is load-bearing: `byte-identical`,
> `exact string equality`, and `letter-for-letter` are codepoint claims and must be backed by an
> actual codepoint diff. Use `rasm-identical` (or `skeleton-identical after fold X`, naming the
> fold) unless that diff has been run.**

> **Two things that must not be reintroduced, and are not:**
> 1. The fabricated line removed from this card this week — *Allah said: "I heard you — and here is
>    the child, already named Yahya"* — **is not in 19:7 or anywhere.** No beat of this deck contains
>    it, any paraphrase of it, or the Zakariyyā narrative it was attached to.
> 2. **This Name is about being heard.** Not being seen (`al-baseer@1`), not being known
>    (`al-lateef@1`, `al-aleem@1`), not being answered (`al-mujeeb@1`). §5's rejection table is
>    mostly that discipline being applied.

---

## 1 · The binding constraint — As-Sami is NOT "clear", and the ledger's §7 understates it

Read from `assets/content/name_stories.json` programmatically, then quoted byte-for-byte:

**Shipped `al-baseer@1` already renders this Name's own gloss and this Name's own āyah.**

- `al-baseer@1` **verse beat `primary`** = `…Surely Allah is All-Hearing, All-Seeing.`
  → ***"All-Hearing" is catalogue id 45's `english`***, already on a shipped screen.
- `al-baseer@1` **verse beat `source`** = `Qur'an 58:1 (revealed for a woman whose complaint the
  person in the same room could not hear)`
  → **58:1 is spent, and the Khawla bint Thaʿlaba narrative is spent inside a rendered string.**

**58:1 is the strongest As-Sami āyah in the Qurʾān** — it carries **two** finite `s-m-ʿ` verbs with
Allah as subject (`قَدْ سَمِعَ ٱللَّهُ` and `وَٱللَّهُ يَسْمَعُ تَحَاوُرَكُمَآ`). Taking a
*different clause* of it would be the **65:3 defect a third time** — the ledger's own worst named
finding. It is not available.

Independently corroborated by two concurrent wave claims: `.context/claims/17.md` (An-Nur) records
*"`al-baseer@1` [S] verse beat renders 'All-Hearing, All-Seeing'"*, and `.context/claims/40.md`
(Ar-Raqeeb) fetched **20:46**, released it, and wrote *"`أَسْمَعُ` is As-Sami (45)"*.

---

## 2 · The enumeration this deck rests on

Run over the **full 6,236-āyah Uthmānī text**, mark-folded, **enumerated by form** (§9ac / §9af).

**The root `s-m-ʿ` has 40 distinct orthographic forms / 167 occurrences**, after excluding
`إسماعيل` (2 forms, 12 occurrences).

> ⚠️ **A miss in my own first pass, recorded rather than smoothed over (§9r).** My first sweep
> searched for the consecutive substring `سمع` and returned 35 root forms. **It missed the entire
> `سَمِيع` family — 5 forms, 47 occurrences (`سميع` 21, `السميع` 19, `سميعا` 4, `لسميع` 2,
> `والسميع` 1) — because `سميع` has a yāʾ between the mīm and the ʿayn.** A second pass on the
> `سمي…ع` pattern caught it. The conclusion is unchanged (every one is an epithet), **but "35 forms"
> would have been a false absolute in a packet, which is exactly the §9ak failure.**

**Finite `s-m-ʿ` verbs where Allah is the one HEARING — four āyāt, five verb tokens:**

| citation | form | verdict |
|---|---|---|
| **58:1** `قَدْ سَمِعَ ٱللَّهُ` **and** `وَٱللَّهُ يَسْمَعُ تَحَاوُرَكُمَآ` (two verbs in one āyah) | I, 3rd person | **SPENT** — shipped `al-baseer@1` verse beat (§1) |
| **3:181** `لَّقَدْ سَمِعَ ٱللَّهُ قَوْلَ ٱلَّذِينَ قَالُوٓا۟…` | I, 3rd person | **bar 5 fatal — the āyah itself ends `وَنَقُولُ ذُوقُوا۟ عَذَابَ ٱلْحَرِيقِ`.** Also: Āl ʿImrān already carries three decks. |
| **43:80** `أَنَّا لَا نَسْمَعُ سِرَّهُمْ وَنَجْوَىٰهُم` | I, 1st person plural, negated-rhetorical | rebuke register; and its second clause `وَرُسُلُنَا لَدَيْهِمْ يَكْتُبُونَ` is shipped `ar-raqeeb@1`'s whole deck |
| **20:46** `أَسْمَعُ` | I, **1st person singular, present** | **CLAIMED — the verse beat** |

**Three further verbs have Allah as subject and are deliberately excluded, with the reason stated so
the enumeration cannot be overturned by them:** **35:22** `إِنَّ ٱللَّهَ يُسْمِعُ مَن يَشَآءُ` and
**8:23** `لَّأَسْمَعَهُمْ` / `أَسْمَعَهُمْ` are **Form IV causatives — Allah *making others hear***,
not Allah hearing. They are about the addressee's faculty, not about this Name.

Every remaining occurrence is: a **human** subject (`يَسْمَعُونَ` 20 occurrences, `سَمِعْنَا` 16,
`تَسْمَعُ` 12, …), the **deaf** (21:45), an exclamative about people on the Day (19:38
`أَسْمِعْ بِهِمْ وَأَبْصِرْ`), a **negative** construction (35:22 `وَمَآ أَنتَ بِمُسْمِعٍ`), the
epithet `سَمِيع` in a **trailing/predicate** position that bar 1 forbids — including every
`سَمِيعٌ عَلِيمٌ` and `سَمِيعٌ بَصِيرٌ` pair (47 occurrences across the five forms) — or **human
speech about Allah** (3:38, 14:39, 2:127, 21:4), the already-rejected 7:196 / 12:101 / 10:62 /
10:82 class.

**Limit stated:** this enumerates the **root** across the Uthmānī rasm. It does not enumerate
near-synonyms (`n-d-y`, `d-ʿ-w`, `j-w-b`, `q-r-b`), which belong to other Names — three of them
decked.

---

## 3 · The beats

| # | `beat_kind` | rendered content |
|---|---|---|
| 1 | `bridge` | You said it and it may as well not have been said. There is a narration of what is said back to Al-Fatihah — line by line, every time. |
| 2 | `name_intro` | **primary:** The All-Hearing · **arabic:** `السَّمِيعُ` · **transliteration:** As-Sami · *(catalogue id 45, verbatim)* |
| 3 | `story` | Abu Hurayra narrated it as something the Prophet ﷺ reported from Allah: "I have divided the prayer between Me and My servant into two halves…" · **source:** `rendered from the Arabic of Sahih Muslim 395a` |
| 4 | `story` | "When the servant says: All praise is for Allah, Lord of the worlds — Allah says: My servant has praised Me." Not "a servant." My servant. · **source:** `rendered from the Arabic of Sahih Muslim 395a` |
| 5 | `story` | "…And when he says: It is You we worship, and You we ask for help — He says: This is between Me and My servant, and My servant shall have what he asked for." · **source:** `rendered from the Arabic of Sahih Muslim 395a` |
| 6 | `verse` | …Indeed, I am with you both; I hear and I see. · **source:** `Qur'an 20:46 (excerpt) — spoken to Musa and Harun` |
| 7 | `dua` | **primary:** Indeed my Lord is close and responsive. · **arabic:** `إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ` · **transliteration:** Inna Rabbi qaribun mujib · **source:** *founder call — see §7* · *(catalogue id 45, verbatim)* |
| 8 | `takeaway` | Al-Fatihah is not one voice. The narration carries the second one, and every line of it begins the same way: "My servant." |

Verse beat is **English-only** (no `arabic` field), per plan §7's convention for new decks.
`source` strings use ASCII `Qur'an`. **Visible ellipsis on every partial quotation:** beat 3 ends
`…`, beat 5 opens `…`, beat 6 opens `…`.

---

## 4 · Verification table

| Claim | Source | Grading | Status |
|---|---|---|---|
| Ṣaḥīḥ Muslim 395a exists and is the ḥadīth qudsī of al-Fātiḥa, narrated by Abū Hurayra | Wayback capture `20260306031510` of `https://sunnah.com/muslim:395`, CDX-located, `zstd -d` decoded | **ṣaḥīḥ (Ṣaḥīḥ Muslim)** — ⚠️ **the page prints no grade line**; "ṣaḥīḥ" here is a collection-level inference, exactly as recorded for Bukhārī 6227 in §9ag | ✅ fetched. `sunnah.com/muslim:395` **resolves to "Sahih Muslim 395 a"** (same shape as `al-mumin@1`'s Muslim 843a). In-book: Book 4, Ḥadīth 41. |
| Its Arabic contains `قَالَ اللَّهُ تَعَالَى قَسَمْتُ الصَّلاَةَ بَيْنِي وَبَيْنَ عَبْدِي نِصْفَيْنِ وَلِعَبْدِي مَا سَأَلَ` | same capture | ṣaḥīḥ | ✅ read off the fetched Arabic |
| Its Arabic contains `فَإِذَا قَالَ الْعَبْدُ {الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ} قَالَ اللَّهُ تَعَالَى حَمِدَنِي عَبْدِي` | same | ṣaḥīḥ | ✅ read off the fetched Arabic |
| Its Arabic contains `فَإِذَا قَالَ {إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ} قَالَ هَذَا بَيْنِي وَبَيْنَ عَبْدِي وَلِعَبْدِي مَا سَأَلَ` | same | ṣaḥīḥ | ✅ read off the fetched Arabic |
| Beats 3–5 are **re-rendered from the page's Arabic, not pasted from its English** | plan §6 rule 2 | — | ✅ **and it was necessary.** The page's published English is the archaic USC-MSA text (*"Praise be to Allah, the Lord of the universe"*, *"Thee do we worship and of Thee do we ask help"*). Pasting it would have failed the "20-something scrolling from a reel" bar of the format spec. |
| **`قَالَ اللَّهُ تَعَالَى` is rendered *"Allah says"*, present tense** | — | — | ✅ deliberate, disclosed. Past tense *"Allah said:"* is `al-qadir@1`'s distinctive rendered string (ledger §4b). The present tense is also the truer reading here — the exchange is habitual, not a single past event. **The doxological `تَعَالَى` is dropped** rather than rendered *"Exalted is He"*, which would have added the §9o doxological hit `al-khaliq@1` and `al-kareem@1` already carry. |
| **What beats 3–5 elide, and why** | same capture | — | ✅ **three exchanges omitted, marked with a visible `…` on beat 5.** Listed in full in §6. |
| 20:46 reads `قَالَ لَا تَخَافَآ ۖ إِنَّنِى مَعَكُمَآ أَسْمَعُ وَأَرَىٰ` | `api.quran.com/v4/verses/by_key/20:46?fields=text_uthmani,text_imlaei&translations=20` | Qurʾān | ✅ fetched |
| Beat 6's English is Saheeh International (translation id 20) verbatim from `Indeed,` onward | `?translations=20` — *"[Allāh] said, 'Fear not. Indeed, I am with you both; I hear and I see.'"* | — | ✅ diffed |
| Abdel Haleem (id 85) renders 20:46 *"Do not be afraid, I am with you both, hearing and seeing everything"* | `?translations=85` | — | ✅ fetched and **rejected with a reason.** It converts the two **finite first-person verbs** `أَسْمَعُ`/`وَأَرَىٰ` into participles, which is precisely what bar 1 and bar 4 rest on. Same shape as §9i's 106:4 decision. Mawdudi (id 95) does the same (*"hearing and seeing all"*) and is also not taken. |
| **The omitted opening of 20:46 is `قَالَ لَا تَخَافَآ` — *"[Allah] said, 'Fear not.'"*** | same fetch | — | ✅ **cut deliberately and disclosed.** Shipped `al-haqq@1` beat 4 renders *"Mūsā felt fear rise in him. Allah answered him: 'Fear not…'"* — **same sūrah, same prophet, Allah answering a stated fear in the first person.** Rendering 20:45–46 would have repeated that staging across three consecutive beats — the `al-mumin@1` class §9ab ruled **blocking**. The cut removes a **collision**, not the Name's own word; contrast §9af, where cutting the deck's own epithet would have hidden its own defect. |
| Successor sweep, 20:46 | 20:44, 20:45, 20:47, 20:48 fetched | Qurʾān | ✅ **n−1 = 20:45** — Mūsā and Hārūn's *"we are afraid that he will hasten against us"*. **n+1 = 20:47** — Mūsā's instructed speech, ending `وَٱلسَّلَـٰمُ عَلَىٰ مَنِ ٱتَّبَعَ ٱلْهُدَىٰ` / *"And peace will be upon he who follows the guidance."* **No punishment at n+1; the successor ends on peace.** ⚠️ **n+2 = 20:48** carries *"the punishment will be upon whoever denies and turns away"* — **inside the words Mūsā is told to say**, not a narrated outcome. Disclosed. 20:47 also carries `h-d-y` (shipped `al-hadi@1`'s root), off-screen. |
| **20:42–48 is on ledger §2d's "rejected on bar 5" list** (by `al-haleem@1`) | COLLISION-LEDGER §2d | — | ⚠️ **RE-PROPOSED, deliberately, on a narrower excerpt.** Argument in §8. **A verifier should treat this as a live objection, not a resolved one.** |
| Sūrah bounds | `20:135` → **200**, `20:136` → **404** | — | ✅ Ṭā Hā is **exactly 135** āyāt — bounded from both sides. 20:46 is not sūrah-final. **No 404 bar-5 claim is made.** |
| **Catalogue id 45's `dua_arabic` is the closing four words of 11:61** | `api.quran.com/v4/verses/by_key/11:61?fields=text_uthmani,text_imlaei` | Qurʾān | ⚠️ **CORRECTED post-verification.** Catalogue: `إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ`. quran.com `text_imlaei` tail: `إِنَّ رَبِّي قَرِيبٌ مُّجِيبٌ`. **Originally claimed "byte-identical, exact string equality" — FALSE**, per the wave-2 verifier's codepoint diff: `text_imlaei`'s `مُّجِيبٌ` carries a shadda (U+0651, idghām) the catalogue's `مُجِيبٌ` lacks. **Correct description: rasm-identical, one diacritic differs (the shadda).** Against `text_uthmani` (`إِنَّ رَبِّى قَرِيبٌ مُّجِيبٌ`): **rasm-identical, 2 of 4 tokens differ orthographically** — `رَبِّي`/`رَبِّى` (final yāʾ) and `مُجِيبٌ`/`مُّجِيبٌ` (shadda of idghām). |
| The words are **Ṣāliḥ's speech to Thamūd**, not Allah's | same fetch — Saheeh: *"And to Thamūd [We sent] their brother Ṣāliḥ. He said, 'O my people, worship Allāh… Indeed, my Lord is near and responsive.'"* | Qurʾān | ✅ fetched. Stated plainly because it decides §7. |
| Successor sweep, 11:61 | 11:60, 11:62 fetched | Qurʾān | ✅ **n−1 = 11:60** ends `أَلَا بُعْدًا لِّعَادٍ قَوْمِ هُودٍ` — a curse on ʿĀd. **n+1 = 11:62** — Thamūd's doubt, no punishment. **11:61 itself contains no punishment**: it is entirely an invitation to worship, seek forgiveness and repent. Relevant only to §7's pin question; **no beat quotes 11:61.** |
| Catalogue id 45's `hadith` field is **Ṣaḥīḥ al-Bukhārī 2992** and resolves | Wayback capture `20250312100442` of `https://sunnah.com/bukhari:2992` | **ṣaḥīḥ** (Ṣaḥīḥ al-Bukhārī; page prints no grade line) | ✅ fetched. Arabic: `فَإِنَّكُمْ لاَ تَدْعُونَ أَصَمَّ وَلاَ غَائِبًا، إِنَّهُ مَعَكُمْ، إِنَّهُ سَمِيعٌ قَرِيبٌ` (Abū Mūsā al-Ashʿarī). **Quoted on no beat.** Note the card's replacement citation is correct; note also that the Bukhārī 2992 wording is `لاَ تَدْعُونَ أَصَمَّ وَلاَ غَائِبًا` — the variant `لَيْسَ بِأَصَمَّ وَلَا غَائِبٍ` is a **different route**, not this page. |
| **The card's ḥadīth and the deck's verse beat carry the same clause** | above | — | ✅ **the reason 20:46 is the right verse beat for this Name and I am stating it as a finding:** Bukhārī 2992 says `إِنَّهُ مَعَكُمْ` — *"He is with you"*; 20:46 says `إِنَّنِى مَعَكُمَآ` — *"I am with you both."* The card negates deafness and absence; the āyah asserts presence and hearing in Allah's own voice. |
| Beats 2 and 7 are catalogue id 45's fields, verbatim | `collectible_names.json` id 45 | — | ✅ read programmatically; the ship gate locks both to the catalogue by `name_id` |

---

## 5 · The five bars

**Bar 1 — demonstrated in the cited text, in Allah's words, not a trailing epithet. MET twice.**

- **The story is Allah's own first-person speech** (a ḥadīth qudsī — the shipped shape of
  `al-haleem@1`'s Bukhārī 7378 and `al-kareem@1`'s Bukhārī 1145). And it does not *assert* hearing:
  it **performs** it. `حَمِدَنِي عَبْدِي` is Allah **quoting back what was just said, and naming who
  said it.** That is hearing, done, in Allah's words.
- **The verse beat is `أَسْمَعُ`** — a finite, first-person, present-tense verb of the Name's own
  root, spoken by Allah. **Of the four āyāt in the Qurʾān where Allah is the one hearing, this is
  the only one that is unspent and survives bar 5** (§2).

**Bar 2 — shown, not stated. MET, and this is the deck's strongest bar.** The qudsī never says *"I
hear."* It shows a reply arriving for each line. Compare §9j ground 1, which killed 24:35 for
An-Nur: `ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ` **states**. Nothing here states. The verse beat does say
*"I hear"* — but by then the demonstration has already happened on three beats.

**Bar 3 — no sibling collapse. Run on all three surfaces (§9an).**

*Surface 1 — Arabic roots in the quoted source texts.*

| root | where | note |
|---|---|---|
| `s-m-ʿ` | 20:46 `أَسْمَعُ` | the Name's own |
| `r-ʾ-y` | 20:46 `وَأَرَىٰ` | ⚠️ **rendered *"I see"*.** Not `b-ṣ-r`, so it is not Al-Baseer's root — but it **is** Al-Baseer's rendered English axis. Disclosed below; quoted in full rather than cut, because cutting a clause to hide a collision is §9af's failure. |
| `q-s-m` · `ṣ-l-w` · `ʿ-b-d` · `s-ʾ-l` · `ḥ-m-d` | Muslim 395a | `ḥ-m-d` is **id 65 Al-Hameed's** root — undecked, off-screen (rendered as *"praise"*, ordinary English) |
| `q-r-b` · `j-w-b` | duʿā (catalogue-locked) | ⚠️ **`مُجِيبٌ` is Al-Mujeeb's Name-word, rendering in Arabic on this deck's duʿā screen.** Catalogue-locked. See below. |
| **excluded by construction** | `n-w-r`, `l-ṭ-f`, `ʿ-l-m`, `r-ḥ-m`, `gh-f-r`, `h-d-y`, `m-l-k`, `ṣ-b-r` — **all cut out of the quoted qudsī by the elision in §6** | |

*Surface 2 — token frequency over **every rendered string of all 34 shipped decks** (595 strings).*

- Cross-deck **≥4-word runs: exactly one**, and it is **gate-locked** — see the catalogue table below.
- **`hear` n=1 in the whole shipped corpus** — it occurs once, inside `al-baseer@1`'s 58:1 `source`
  string (*"…could not hear"*). My verse beat makes it 2. **Reported at full volume because the
  precedent cuts against me:** `afraid` at n=1 was ruled **blocking** in §9ab on exactly this
  evidence. **My argument that this one is different:** `afraid` was a *shared incidental word doing
  the same job in two decks*; `hear` is **this Name's own verb**, unavoidable, and in `al-baseer@1`
  it appears in a subordinate clause describing a bystander's failure, not Allah's act.
  **A verifier should test that distinction rather than accept it.**
- Tokens my beats introduce at n=0: `fatihah`, `praised`, `worlds`, `recited`, `voice`.
- `praise` n=1 (`al-haqq@1`'s duʿā, *"to You belongs all praise"*), `halves` n=1 (`al-waliyy@1`),
  `worship` n=1 (`al-wasi@1`'s verse beat). All ordinary register.
- Two strings I revised **because** the sweep caught them, recorded rather than silently fixed:
  a beat-8 draft contained *"the part you already knew — and"*, a 3-gram with shipped
  `al-ghafur@1`'s beat 8 (*"…to the One who already knew, and no one else is ever told"*) — the
  ledger's §4b string. Cut. A beat-8 draft used *"the other half is…"*, matching shipped
  `al-waliyy@1`'s **takeaway** construction. Cut.

*Surface 3 — the move.* Engine, three words: **the reply names you.** Read against the decks it
could collapse into:

| shipped deck | its move | why mine is not it |
|---|---|---|
| `al-baseer@1` — *"Al-Baseer sees what you carry"* | the unseen is seen | **the closest, and it is catalogue-locked at the gloss level** (below). At the beat level: nothing in my deck is unobserved or private. The servant is standing in a mosque saying words out loud. |
| `al-lateef@1` — *"What you couldn't say was never unsaid to Him"* | **the unspoken is known** | **the exact inverse.** My whole deck is about words the user **did** say, out loud, thousands of times. Not one beat concerns anything unspoken. |
| `al-aleem@1` — *"He already knew what she had delivered"* | knowing precedes telling | ⚠️ **live adjacency, disclosed.** An early beat-4 draft read *"Not afterwards. In the gap between that line and the next one"* — the same **move** as al-aleem@1's *"answered inside her own sentence"*. **Cut for that reason**, and the beat now lands on the possessive `عَبْدِي`, not on timing. §9aq is why. |
| `al-mujeeb@1` — *"the āyah does not stop with him"* | a call gets an answer | ⚠️ **catalogue-locked adjacency** (below). At the beat level: nothing is asked for and nothing is rescued in my story; the servant is praising, not petitioning. |
| `ar-raqeeb@1` — *"the people it was about were not there for it"* | spoken of, kindly, in your absence | ⚠️ **disclosed, and it is the one I would attack.** Both decks turn on being **referred to** in speech. **Differences:** ar-Raqīb's speakers are third parties reporting **about** an absent person; mine is Allah naming a person **who is standing right there, mid-sentence**, in the second half of the person's own prayer. Measured: **zero shared ≥3-grams.** Per §9ab I do not get to rule on this. |
| `ar-raheem@1` — *"answered while unaware"* | answered across centuries, unconscious of it | **explicitly avoided.** My engine is *whose the words are*, not *whether you noticed*. No beat says the user was unaware; beat 8 says the narration carries a second voice — a fact about the text, not about the user's attention. |

**Bar 4 — the Name's root in the source text. MET, no trade.** `أَسْمَعُ` on the verse beat, and
`ٱلسَّمِيعُ` on the `name_intro` in Arabic. **Caveat:** the root does **not** appear in the story
(Muslim 395a contains no `s-m-ʿ` except Abū Hurayra's own `سَمِعْتُ`, which is a human hearing a
human and is quoted on no beat).

**Bar 5 — MET on the sweep, with the §2d objection answered in §8, not waved away.** 20:47 is clean
and ends on peace; the qudsī of al-Fātiḥa contains no punishment anywhere.

---

## 6 · Every elision, and exactly what it hides

| beat | omitted text | why |
|---|---|---|
| 3 | `وَلِعَبْدِي مَا سَأَلَ` — *"and My servant shall have what he asked for"* | it renders **in full on beat 5**; keeping it in both would have made an **8-word verbatim repeat across two beats of one deck** (§9v). Trimming beat 3 reduces the deck-internal overlap to **5 words** — `between Me and My servant` — which is the narration's **own refrain** and is the deck's spine. **Kept and disclosed**, on the `al-malik@1` §9al precedent. |
| 5 (leading `…`) | **three exchanges of the qudsī**, in the narration's order: ① `{ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ}` → `أَثْنَى عَلَىَّ عَبْدِي`; ② `{مَالِكِ يَوْمِ ٱلدِّينِ}` → `مَجَّدَنِي عَبْدِي` (with the narration's own variant `فَوَّضَ إِلَىَّ عَبْدِي`); ③ `{ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ …}` → `هَذَا لِعَبْدِي وَلِعَبْدِي مَا سَأَلَ` | **all three are bar 3, and each names a Name already on a screen.** ① renders **shipped `ar-rahman@1` ("The Most Gracious") and `ar-raheem@1` ("The Most Merciful")** in one clause. ② renders **shipped `al-malik@1`**'s root and gloss (*"Master/Sovereign of the Day of Judgment"*). ③ is **shipped `al-hadi@1`**'s ground twice over: 1:6 is its takeaway basis and its beat 8 reads *"Even the strongest believers ask 'guide us' in every prayer, every day."* **Four sibling Names removed by construction, and this is the disclosure rather than a claim of coincidence.** |
| 6 (leading `…`) | `قَالَ لَا تَخَافَآ` — *"[Allah] said, 'Fear not.'"* | the `al-haqq@1` staging collision — see the verification table |

**The deck does not claim the qudsī is short.** Beat 5's `…` is on the beat, where the user sees it,
per the batch-2 rule.

---

## 7 · The duʿā — a founder call, costed both ways. **I recommend nothing be actioned without
independent re-verification.**

**The finding, at its measured strength, CORRECTED post-verification:** catalogue id 45's
`dua_arabic` is **rasm-identical to quran.com's `text_imlaei` for the closing four words of Qurʾān
11:61 — one diacritic differs (a shadda on `مُجِيبٌ`/`مُّجِيبٌ`, U+0651, idghām), confirmed by
codepoint-level diff.** This draft originally asserted *"byte-identical… exact string equality…
Not 'close', not 'to within one word' — string equality."* **That was false**, caught on
independent re-verification. The correct, weaker claim is `rasm-identical`. This is the **second**
time this project has recorded this exact overclaim (the pilot's *"letter-for-letter identical"*
for 18:10, which also turned out to differ) — see the boxed correction at the top of this file.
**This is the sixth Name in this project whose duʿā turns out to be scripture rather than an
authored invocation** (ids 4, 10, 14, 37, 64).

**Option A — PIN: `'as-sami@1': "Qur'an 11:61 (closing words)"`.**
- *For:* the user learns the sentence they are reciting is Qurʾān. Truncation is **front-only**, and
  `(closing words)` discloses it in the only rendered field where truncation can be disclosed — the
  mirror image of `al-malik@1`'s approved `"Qur'an 3:26 (opening)"` and `al-aleem@1`'s
  `"(opening words)"`.
- *For:* **the words being a prophet's rather than Allah's is not a bar.** Shipped `al-mujeeb@1` is
  pinned to `Qur'an 21:87`, which is **Yūnus's speech**. Direct precedent.
- *Against:* the āyah's frame is Thamūd. **11:60 (n−1) ends on a curse against ʿĀd** and Thamūd is
  destroyed at 11:67. Nothing dark is *inside* 11:61 — it is entirely an invitation — so this is
  **not** the `al-khaliq@1` decline, where the āyah's own hidden tail was the Fire. But a user who
  opens the citation lands in a destruction narrative.
- *Against:* the sentence is a **declaration**, not a petition, so a `source` may read as though a
  supplication were being prescribed.

**Option B — UNPINNED.** Costs the deck nothing; bar 4 is already met on the verse beat.

**My weak recommendation is A**, because a duʿā screen that is verbatim Qurʾān and says so is worth
more than one that does not. **But this is exactly the artifact the ledger says has been wrong
three of three times, and the instruction is explicit: never action a drafter's recommendation
about pinned data without independent re-verification.** Treat the measurement as verified and the
recommendation as unverified.

**NO catalogue change is recommended for id 45.**

---

## 8 · The §2d objection, answered rather than avoided

**Ledger §2d lists `20:42–48` under "rejected on bar 5", and says do not re-derive.** I am
re-proposing part of it. The honest version:

1. **The rejection was `al-haleem@1`'s, and it was about a different arc.** For a forbearance deck
   the passage's subject is **Pharaoh**, and Pharaoh's respite terminates in his drowning — a real
   bar-5 failure for that deck.
2. **This deck's subject is not Pharaoh.** It is two men who said they were afraid, and the sentence
   spoken to them. **Pharaoh is not named on any beat**, and the deck renders no threat, no
   confrontation, no plague and no sea. Measurement: `pharaoh`, `drown*`, `punish*`, `plague`,
   `sea`, `staff` appear in **zero** of this deck's eight rendered strings.
3. **The excerpt is one clause of one āyah**, and its own successor **ends on peace**
   (20:47, `وَٱلسَّلَـٰمُ عَلَىٰ مَنِ ٱتَّبَعَ ٱلْهُدَىٰ`).
4. **§9r's rule cuts my way here:** *"a verse examined as a neighbour has not been examined as a
   candidate."* 20:46 was examined by `al-haleem@1` as part of a **range** and by `ar-raqeeb@1` as a
   **rejected candidate for a different Name** (`.context/claims/40.md`, which released it and named
   it As-Sami's). **Neither examined it as a candidate for this Name.**

**What a verifier should press on:** 20:48 — *"the punishment will be upon whoever denies and turns
away"* — sits at **n+2**, inside instructed human speech. That is closer than I would like. It is
softer than shipped `al-afuw@1`'s 42:26 (*divine, eschatological, at n+1*), which the ledger records
non-blocking, and §9aa's calibration says a rule cannot forbid the softer case while shipping the
harder one. **That is an argument, not a 404. Rule against it if you disagree.**

---

## 9 · Catalogue-locked collisions this deck cannot fix — escalate, do not paper over

All measured, none estimated. **Every one is in `collectible_names.json` or in a shipped deck; no
change to either is recommended here.**

| # | collision | measurement |
|---|---|---|
| 1 | **This Name's own gloss already renders on a shipped deck.** `al-baseer@1`'s verse beat says *"…Surely Allah is **All-Hearing**, All-Seeing."* | *"All-Hearing"* = catalogue id 45's `english`, byte-exact. ***Restorer* class**, and worse than *Restorer* because the shipped deck reached it first and the gloss is gate-locked on both sides. |
| 2 | **This Name's strongest āyah is spent by that same shipped deck**, together with its narrative, inside a rendered `source` string | 58:1; the Khawla narrative named in `al-baseer@1`'s verse-beat `source` |
| 3 | **This deck's duʿā screen renders Al-Mujeeb, in Arabic and in English** | Arabic `مُجِيبٌ` against shipped `al-mujeeb@1`'s `name_intro` Arabic `الْمُجِيبُ`; English *"responsive"* against its `name_intro` *"The Responsive"*. Ledger §4c names this; ledger §7 nonetheless rates id 45 **"clear"**. |
| 4 | **The duʿā's *"close"* faces `al-mujeeb@1`'s verse beat *"…indeed I am near."*** | 1-token synonym pair on two duʿā/verse beats. `near` n=2 (`al-ghafur@1`, `al-mujeeb@1`); `close` n=1 (`as-salam@1`). |
| 5 | **The one cross-deck ≥4-word run in this deck is on the gate-locked duʿā beat** | ***"Indeed my Lord is"*** — 4 words — against shipped **`al-lateef@1` beat 3** (*"Indeed my Lord is subtle in fulfilling what He wills"*, 12:100) and **`al-kareem@1` beat 5** (*"…indeed, my Lord is Free of need and Generous"*, 27:40). **Three decks now open a rendered sentence with the same four words.** Not in any prior report. Unfixable inside a deck — beat 7's `primary` is locked to `dua_translation`. |
| 6 | **The duʿā beat swept from its FIRST character (§9as)** | id 45's duʿā **does not open with a vocative** — it is a declaration — so it does **not** add a second rendering of this Name's gloss. It is one of the minority of decks where §9as finds nothing. |

**Consequence for the ledger's own worklist:** §7b lists **45** under *"clear but carries one flag"*.
That is **four flags, three of them against decks that are already shipped**, plus a spent āyah.
Id 45 belongs closer to §6e's list than to "clear".

---

## 10 · Candidates fetched or enumerated and rejected — do not re-derive

| candidate | why it died |
|---|---|
| **58:1** — the Name's strongest āyah, two Allah-subject `s-m-ʿ` verbs | **spent by shipped `al-baseer@1`** (verse beat + narrative in a rendered string). A second clause of it would be the 65:3 defect a third time. |
| **3:181** `لَّقَدْ سَمِعَ ٱللَّهُ` | the āyah itself ends `ذُوقُوا۟ عَذَابَ ٱلْحَرِيقِ`. Bar 5, intra-āyah. |
| **43:80** `أَنَّا لَا نَسْمَعُ سِرَّهُمْ` | rebuke register; and `وَرُسُلُنَا لَدَيْهِمْ يَكْتُبُونَ` is shipped `ar-raqeeb@1`'s deck in one clause |
| **all `سَمِيعٌ عَلِيمٌ` / `سَمِيعٌ بَصِيرٌ` epithets** (incl. 42:11, 17:1, 31:28) | trailing/predicate epithet — bar 1's named failure. 42:11 additionally names **shipped** Al-Baseer. `.context/claims/5.md` rejects 42:11 on the same ground independently. |
| **3:38 · 14:39 · 2:127 · 21:4** (`سَمِيعُ ٱلدُّعَآءِ` etc.) | **human speech about Allah** — the already-rejected 7:196 / 12:101 / 10:62 / 10:82 class. 3:35–38 is also shipped `al-aleem@1`'s. |
| **50:16** (`نَعْلَمُ مَا تُوَسْوِسُ بِهِۦ نَفْسُهُۥ`) and **20:7** (`يَعْلَمُ ٱلسِّرَّ وَأَخْفَى`) | they render **knowing**, which is shipped `al-lateef@1`'s beat 8 and `al-aleem@1`'s entire deck. **This Name is not about being known.** |
| **50:17–18** (`مَّا يَلْفِظُ مِن قَوْلٍ إِلَّا لَدَيْهِ رَقِيبٌ عَتِيدٌ`) | already rejected by `ar-raqeeb@1` (the watcher is an angel, not Allah); surveillance register |
| **19:3** (`نَادَىٰ رَبَّهُۥ نِدَآءً خَفِيًّا`) — the hidden call | **spent by shipped `as-samad@1`** (19:2–7), and it is the site of the fabrication removed from this card |
| **2:186** (`إِنِّى قَرِيبٌ`) · **40:60** (`ٱدْعُونِىٓ أَسْتَجِبْ لَكُمْ`) | 2:186 is shipped `al-mujeeb@1`'s verse beat; 40:60 is on §2d's bar-5 rejection list and is Al-Mujeeb's ground either way |
| **17:110** (*"be neither loud nor silent in your prayer"*) | its axis is **loud/quiet**, which is shipped `al-lateef@1`'s beat 8 (*"Whether you speak secretly or openly"*). Also its first half is the 99-Names āyah and renders **Ar-Rahman**. **Left free but flagged** — a strong text for a future Name. |
| **Bukhārī 799** (Rifāʿa — *"more than thirty angels rushing to write it down first"*) | superb and **not mine**: the words being recorded are **catalogue id 65 Al-Hameed's entire duʿā** (`حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ`), and the angels-ascending frame is `ar-raqeeb@1`'s. **HELD FREE FOR AL-HAMEED (65).** |
| **Bukhārī 2992** (*"you are not calling one deaf or absent"*) | fetched, verified, **quoted on no beat** — it is the card's own `hadith` field, and rendering it on the deck would repeat the card the user has just read. **Used as corroboration only.** |
| **`سَمِعَ ٱللَّهُ لِمَنْ حَمِدَهُ`** (Bukhārī 796 / Muslim 409) | the ṣalāh formula. Its narrations tie to forgiveness or to the angels' saying — `gh-f-r` (4 decks) and `ar-raqeeb@1`. **Left free.** |
| **27:18–19** (the ant's warning recorded verbatim) | the demonstration would be the deck's own inference from the fact of the text, not something in Allah's words. Bar 1. Sūrat an-Naml also carries `al-kareem@1` (27:40). **Left free.** |

---

## 11 · What I could not verify — limits of this method

1. **No corpus independent of sunnah.com.** sunnah.com 403s automated fetching; Muslim 395a and
   Bukhārī 2992 were read from **Wayback captures of the exact bare cited numbers**, located via the
   CDX API and decoded through `zstd -d`. Both derive from the same digitisation. **No printed
   edition, Shamela or Dorar was consulted.**
2. **No isnād was audited.** Neither page prints a grade line; **"ṣaḥīḥ" for both is a
   collection-level inference from Bukhārī and Muslim**, not a fetched grade. That is a weaker claim
   than `al-baqi@1`'s Tirmidhī 2470 (where a Darussalam grade line exists on the page), and it is
   stated at that strength deliberately.
3. **No corpus independent of quran.com.** The āyāt and the full Uthmānī text used for §2's
   enumeration came from the **same API**, so the enumeration and the citations are **not
   independent of each other**. A muṣḥaf-independent re-run of §2 is the strongest single check
   available on this deck.
4. **Beats 3–5 are my own rendering of the Arabic**, not a published translation. That is required
   by plan §6 rule 2 for this page (the published English is archaic), but it means **no third party
   has checked my English against the Arabic.** It should be checked clause by clause.
5. **`قَالَ اللَّهُ تَعَالَى` rendered as "Allah says" drops `تَعَالَى`.** Disclosed above; it is a
   deliberate omission of a doxological term, not an oversight.
6. **The duʿā's pin is a recommendation, not a verified decision** — see §7.
7. **Morphology is author-assigned.** `أَسْمَعُ` as Form I first-person imperfect, and the
   classification of all **40** root forms, were read by eye off fetched Arabic. **No morphological
   database was consulted.** The mechanical screen also produced false positives that had to be
   removed by hand — `مُسَمًّى`, `سَمَّيْتُمُوهَا`, `لِّلْمُتَوَسِّمِينَ`, `ٱلْمُقْتَسِمِينَ`,
   `سَمِينٍ` — and, more dangerously, it **under-**generated on the first pass (see §2's box).
   The under-generation is the one an isnād-style audit would not catch.
8. **I did not audit `dua_translation` against `dua_arabic` for id 45 beyond checking
   correspondence** — and it **does** correspond (`إِنَّ رَبِّي` → *"Indeed my Lord"*; `قَرِيبٌ` →
   *"close"*; `مُجِيبٌ` → *"responsive"*), with **no English clause lacking an Arabic counterpart**.
   Reported as a check that was run, given the §9m/§9t defect rate in that column.
