# Catalogue `hadith` audit — all 99 Names

**Date:** 2026-08-03
**Scope:** the `hadith` field of every entry in the 99-Name catalogue.
**Status:** REPORT ONLY. Nothing in this pass was edited, staged, or applied. No content file
and no database row was touched.

---

## 1. Headline

**99 of 99 Names reached. 56 carry a defect.**

| Verdict | Count | What it means |
|---|---|---|
| **CLEAN** | 43 | It is a hadith, the citation resolves, and the quoted text matches within normal paraphrase. |
| **NOT-A-HADITH** | 33 | The field holds a Qur'an ayah, an athar, a scholar's saying, or app-authored prose. |
| **WRONG-CITATION** | 13 | The citation resolves to a different text, a different collection, or the wrong half of the right hadith. |
| **UNLOCATABLE** | 8 | Text in quotation marks, attributed to the Prophet ﷺ, that cannot be found anywhere. |
| **NOT-VERIFIED** | 2 | I could not reach an independent copy. Not a pass and not a fail. |

The spot check during deck batch 2 found 4 defects in 5 Names. The full sweep does not
reproduce that rate — but it is still bad. **Only 43 of 99 entries are a sound hadith with a
citation that resolves.** The most serious class — a sentence in quotation marks, attributed
to the Prophet ﷺ, that exists in no collection — occurs **8 times**, and two of those carry
the citation "(Derived from Names teachings)", meaning the field itself admits the words were
authored while the sentence still says the Prophet said them.

The single biggest structural finding: **`hadith` is not a hadith field.** A third of the
catalogue uses it as a general "source text" slot for Qur'an, athar and scholars' quotes. Most
of those are honestly labelled and are only miscategorised. But the same loose slot is what
lets a Yaqeen article, a tafsir, and the bare word "(Hadith)" sit in a field a user reads as
prophetic narration.

---

## 2. Every mirror (fix one, you must fix all of these)

The Al-Barr du'a repair found the same content in four places. `hadith` is in **five**, plus
tooling and a contract that pins it:

| # | Location | Role |
|---|---|---|
| 1 | `assets/content/collectible_names.json` | Bundled asset. Seeds the runtime cache at boot via `bootstrapPublicCatalogs()` → `ensurePublicCatalogCache(assetPath:)` (`lib/services/public_catalog_service.dart:93`). This is the snapshot of record. |
| 2 | `lib/services/card_collection_service.dart` — `allCollectibleNames`, lines 184–1754 | Compiled-in const fallback used when the cache misses (`currentCollectibleNames()`, line 1756). **Byte-identical to the asset for all 99 `hadith` values — verified, 0 diffs.** |
| 3 | Supabase table `public.collectible_names`, column `hadith` | Column declared in `supabase/migrations/20260407000000_initial_schema.sql:137`. `refreshPublicCatalogsFromSupabase()` overwrites the cache from the server, so **the server row is what users actually read**. Asset and const are only the cold-start and fallback paths. |
| 4 | `lib/core/constants/knowledge_base.dart` | **12 of the same hadith strings recur verbatim** at lines 222 (id 51), 312 (id 65), 345 (id 26), 404 (ids 47 + 90), 435 (id 38), 466 (id 32), 860 (ids 52 + 84), 969 (ids 43 + 44), 1328 (id 23). Note that ids 65, 52 and 84 are all **defective**, so a partial fix leaves the bad text live here. |
| 5 | `tool/export_public_catalog_snapshots.dart` / `tool/import_public_catalog_snapshots.dart` | Round-trip the table and the JSON asset. A server-only fix will be silently reverted by the next export; an asset-only fix never reaches users. |

Also: `lib/services/public_catalog_contracts.dart:96` pins `hadith` as a required key with
`expectedCount: 99`, so any fix must keep all 99 rows non-null.
`supabase/staged/fix_catalog_duas_51_85.sql` mentions hadith only in comments; it does not
write the column.

**Answer to "asset, server, or both": both, and the server wins.** A correct fix is
(a) the Supabase table, (b) the JSON asset, (c) the Dart const list, and (d) the 12 lines in
`knowledge_base.dart` — in that order of user impact.

---

## 3. Method, and its limits

Stated plainly, because a shallow pass here would look like assurance.

**What I did.**
- **Qur'an:** every Qur'an citation was fetched live from `api.quran.com/api/v4` (Sahih
  International, translation id 20). 23 verses fetched. No verse was recalled.
- **Hadith:** I did not compose or reconstruct any narration or isnad. Every hadith claim was
  checked against a full-text searchable copy of nine English collections — Sahih al-Bukhari,
  Sahih Muslim, Jami' at-Tirmidhi, Sunan Abi Dawud, Sunan Ibn Majah, Sunan an-Nasa'i, Muwatta
  Malik, the Forty of an-Nawawi, and the Forty Hadith Qudsi — pulled from the
  `fawazahmed0/hadith-api` edition set, which carries the published grade lines (al-Albani,
  Shakir, Zubair Ali Zai, Shu'ayb al-Arna'ut) alongside each text.
- **Independent corroboration:** where a verdict turned on exact wording, I additionally read
  the **Wayback capture of the exact sunnah.com URL** (sunnah.com 403s automated fetching).
  Done for Bukhari 7392, Bukhari 6425, Bukhari 7378, Muslim 2620, Muslim 1342, Abu Dawud 4090,
  and Al-Adab Al-Mufrad book 27.

**Limits — read these before treating any CLEAN as a clearance.**
1. **I did not reach a corpus independent of sunnah.com.** The hadith-api editions are derived
   from the same underlying sunnah.com data, and the Wayback captures are literally sunnah.com.
   Everything here is one corpus checked twice, not two corpora agreeing.
2. **Published grade lines are read, not audited.** Where I say "Hasan" or "Da'if" I am
   reporting al-Albani's or another muhaqqiq's published ruling as it appears in that edition.
   I did not examine a single isnad.
3. **Three sources were out of reach entirely.** al-Hakim's *al-Mustadrak* (ids 16, 43, 44),
   *Musnad Ahmad* (ids 80, 82 — id 80 was rescued via Al-Adab Al-Mufrad instead), and
   dorar.net (Cloudflare-blocked). Those entries are marked **NOT-VERIFIED**, which is not a
   pass.
4. **"Zero hits" is a strong signal, not a proof of non-existence.** When I say a phrase
   returns zero hits, it means zero across those nine collections in English translation. A
   narration living only in al-Bayhaqi, al-Tabarani, Ahmad or a tafsir would not surface. That
   is exactly why those eight entries are flagged for a scholar rather than deleted by me.
5. **English translations differ.** Paraphrase judgements ("close enough") are mine and are
   noted in the evidence column so a reviewer can disagree with any of them.

---

## 4. Prioritised defect list — worst first

### TIER 1 — Unlocatable text in quotation marks attributed to the Prophet ﷺ (8)

This is the class that matters most. Each of these puts words in the Prophet's mouth that I
could not find in any of the nine collections. Two of them carry a citation that openly says
the text was authored.

| id | Name | The quoted sentence | Citation given | Proposed correction |
|---|---|---|---|---|
| **75** | Al-Qadir | "Nothing is beyond the power of Allah." | **(Muslim)** | **No correct citation found.** Zero hits in Muslim or anywhere. Remove, or replace with a real Qur'anic statement of divine power and relabel the field — e.g. Qur'an 2:20 or 46:33, both fetched-verifiable. Do not keep a Sahih Muslim tag on it. |
| **77** | Al-Muqaddim | "Your rizq chases you the way death chases you." | **(Hadith)** — the bare word | **No correct citation found.** Zero hits. The citation is not a citation. Remove, or replace with Tirmidhi 2344 (Hasan Sahih, verified this pass) — "if you relied on Allah as He should be relied upon, He would provide for you as He provides for the birds" — which is already used verbatim at id 13. |
| **71** | Al-Wajid | "Allah is never at a loss for what you need." | **(Derived from Names teachings)** | **No correct citation found.** The field admits the text is derived while the sentence says the Prophet said it. Either strip the "The Prophet ﷺ said" framing and the quotation marks and keep it as authored reflection, or remove. |
| **94** | Al-Mani | "What Allah withholds is also His mercy." | **(Derived from Names teachings)** | **No correct citation found.** Same shape as id 71. A real substitute exists and is already in this repo: `knowledge_base.dart:2819` cites **Sahih al-Bukhari 6615** — *"Allahumma la mani'a lima a'tayt, wa la mu'tiya lima mana't"* — which is the actual hadith of Al-Mani. Use it. |
| **54** | Al-Muqeet | "Allah provides for every creature — He is Al-Muqeet, the Nourisher of all things." | **(Ibn Kathir, Tafsir of Quran 4:85)** | **No correct citation found as a narration.** A tafsir is not a narration source, and zero hits in the nine collections. If the intent is the tafsir's gloss on 4:85, drop "The Prophet ﷺ said" and the quotation marks and attribute it to Ibn Kathir as commentary. |
| **56** | Al-Jaleel | "Fill your heart with reverence of Allah that draws you near, not fear that drives you away." | **(Yaqeen, The Name I Need Day 06)** | **No correct citation found.** Zero hits. This is a modern content series being quoted as prophetic speech. Remove the prophetic framing entirely. |
| **20** | Al-Bari | "You brought me out of nothingness into being." | **(Yaqeen, The Name I Need)** | **No correct citation found.** Zero hits. Same shape as id 56. Remove the prophetic framing. |
| **45** | As-Sami | "I heard you — and here is the child, already named Yahya." — attributed to **Allah** | **(Quran 19:3-7)** | **The quoted words are not in the cited verses.** Fetched 19:7 reads: *"O Zechariah, indeed We give you good tidings of a boy whose name will be John. We have not assigned to any before [this] name."* Quote the ayah verbatim or drop the quotation marks. The "corner of the masjid" detail is from 3:39, not Surah Maryam. |

### TIER 2 — Wrong citation: the reference resolves, but to something else (13)

| id | Name | What is wrong | Proposed correction |
|---|---|---|---|
| **85** | Al-Barr | Cites **Muslim 1342** for *"Our Lord is Al-Barr, Al-Ghafur"* said "upon completing Hajj". Muslim 1342, read in full via Wayback, is the **du'a on mounting for a journey** (Ibn 'Umar), whose return addition is *"We are returning, repentant, worshipping our Lord and praising Him."* The quoted phrase is not in it and returns zero hits anywhere. | **No correct citation found.** Note this Name already had its du'a repaired on 2026-08-02; its hadith field is independently wrong. Needs a scholar. |
| **63** | Al-Mateen | Cites **(Bukhari & Muslim)** for *"a treasure from beneath the throne"*. Bukhari 4205/6384/7386 and Muslim 2704 all read *"a treasure from the **treasures of Paradise**"*. "Beneath the throne" returns **zero hits** in all nine collections. | Change the quoted wording to "one of the treasures of Paradise" and cite **Sahih al-Bukhari 6384** (or Muslim 2704). The du'a stays. |
| **50** | Al-Azeem | Cites Abu Dawud for the **wrong half of the right hadith**. Abu Dawud 869 pairs *fa-sabbih bismi Rabbika al-'Azim* (56:74) → "use it when **bowing**", and *Sabbih isma Rabbika al-A'la* (87:1) → "use it when **prostrating**". The card gave Al-**Azeem** the al-A'la/sujud half, then glossed it "we declare His highest" — which is Al-A'la's meaning. Worse, Abu Dawud 869 is graded **Da'if by al-Albani**. | Use the **ruku'** half and cite **Sunan Abi Dawud 869** *with its Da'if grade stated* — or drop it and use a Sahih locus for *Subhana Rabbiya al-'Azim* in ruku' instead. Card id 53 already gets this pairing right; id 50 contradicts it. |
| **19** | Al-Mutakabbir | Cites **(Muslim)** but the quoted ending — "I will throw into the Fire" — is **Abu Dawud 4090**'s wording. Muslim 2620 (Wayback) reads *"…he who contends with Me in regard to them **I shall torment him**."* Also frames first-person divine speech as "The Prophet ﷺ said" with no hadith-qudsi marker. | Either quote Muslim 2620 accurately, or keep the current wording and cite **Sunan Abi Dawud 4090 (Sahih)**. Add "In a hadith qudsi" to the frame. |
| **65** | Al-Hameed | Cites **(Muslim)** for the qudsi *"devote yourself to My worship…"*. It is **not in Sahih Muslim** — zero occurrences. It is **Tirmidhi 2466 (Sahih)** and **Ibn Majah 4107**. The card's gloss is also about praise while the narration is about worship and sufficiency. | Change the citation to **Jami' at-Tirmidhi 2466 (Sahih)**. Reconsider the gloss, or move this hadith to a Name it actually fits. |
| **96** | An-Nafi | Cites **Ibn Majah 3846** for *"Ask Allah for benefit (naf') in this world and the next."* Ibn Majah 3846, verified, is **'A'isha's du'a asking for all *khayr* (good)**, in this world and the next. The quoted sentence is not in it. | **No correct citation found for the quoted sentence.** Either quote Ibn Majah 3846 accurately (it asks for *khayr*, not *naf'*), or remove. A numbered citation on an invented paraphrase is the most misleading form this defect takes. |
| **64** | Al-Waliyy | Cites **Bukhari** for "Be in this world as if you are a stranger or a wayfarer" (Bukhari 6416 — real). But the hadith is about **detachment from the world**; it says nothing about *wilaya*, and it is not the hadith behind this card's du'a. Confirms the spot check. | Replace with a hadith or ayah on divine *wilaya*. Qur'an 2:257 (*"Allah is the wali of those who believe"*) is fetch-verifiable and on-topic. |
| **35** | Al-Wakeel | Cites **(Quran 3:173)** for two claims it does not support. Verified 3:173: it is **the believers at Hamra' al-Asad** who said *Hasbunallahu wa ni'mal-Wakil* — not Ibrahim. And "Be cool and safe" is **Qur'an 21:69**, not 3:173. | Split into two correct citations: the Ibrahim attribution is an athar of Ibn 'Abbas in **Sahih al-Bukhari 4563** (verified this pass); the fire command is **Qur'an 21:69**. |
| **15** | Al-Hayy | Turns **Tirmidhi 3524 (Hasan)** into a direct imperative in quotes — *"Call upon Allah using…"*. The narration is Anas describing the Prophet's **own practice** when distressed. | Reframe to match the narration: *"Whenever a matter distressed him, the Prophet ﷺ would say: 'Ya Hayyu ya Qayyum, bi-rahmatika astaghith.'" (Jami' at-Tirmidhi 3524 — Hasan)*. Card id 89 already frames this correctly. |
| **52** | Al-Ali | Presents two clauses as one Muslim quotation. Only the first — "whoever humbles himself for Allah, Allah raises him" — is in **Muslim 2588**. The second, "Whoever exalts himself, Allah lowers him", is **Ibn Majah 4176**. | Either drop the second clause and keep **Sahih Muslim 2588**, or cite both: Muslim 2588 + **Sunan Ibn Majah 4176**. |
| **84** | Al-Mutaali | Identical text and identical defect to id 52. | Same fix as id 52. |
| **5** | Al-Quddus | Attributes *Subbuhun Quddusun, Rabbu-l-mala'ikati wa-r-ruh* to **the angels**. Muslim 487 (verified) is **the Prophet ﷺ** saying it in ruku' and sujud. The rendering "Holy, Holy, Holy" is also a triple repetition that is in Isaiah 6:3, not in the narration — the Arabic is two distinct words, *Subbuh* and *Quddus*. | Rewrite: *"The Prophet ﷺ used to say in his bowing and prostration: 'Subbuhun Quddusun, Rabbu-l-mala'ikati wa-r-ruh — All-Glorious, All-Holy, Lord of the angels and the Spirit.'" (Sahih Muslim 487)*. |
| **14** | Al-Aleem | The clause "Allah knew what His servants would do, and He wrote it all" sits **inside the quotation marks** but is not in the narration. Muslim 2653 reads *"Allah ordained the measures of creation fifty thousand years before He created the heavens and the earth."* | Quote Muslim 2653 verbatim and move the interpretive clause outside the quotation marks. Cite **Sahih Muslim 2653**. |

### TIER 3 — Not a hadith at all (33)

Two very different severities are collapsed into this verdict, so they are separated here.

**3a. Qur'an presented as prophetic speech (2) — this belongs near Tier 1.**

| id | Name | Problem | Correction |
|---|---|---|---|
| **8** | Al-Azeez | *"The Prophet ﷺ said: 'Might belongs to Allah, His Messenger, and the believers.' (Quran 63:8)"* — verified as Qur'an 63:8. Divine speech attributed to the Prophet. | Change the frame to "Allah says" and cite **Qur'an 63:8**. |
| **66** | Al-Muhsi | *"The Prophet ﷺ said: 'Not a leaf falls but that He knows it…' (Quran 6:59)"* — verified as Qur'an 6:59. Same defect. | Change the frame to "Allah says" and cite **Qur'an 6:59**. |

**3b. Correctly labelled Qur'an in a field named `hadith` (20).**
ids **21, 22, 23, 26, 30, 34, 36, 57, 59, 67, 68, 69, 76, 83, 87, 88, 97, 98** — plus 8 and 66
above. **Every one of these 20 verses was fetched and its text confirmed accurate.** Nothing is
misquoted. The only defect is categorical: a Qur'an ayah sits in a field a user reads as
prophetic narration (id 68, flagged in the spot check, is this and only this). Minor framing
slip at **id 83**: introduced as "Allah says" though 7:196 is the Prophet's speech (*"Say:
Indeed my protector is Allah…"*). **Recommendation: rename or split the field** rather than
rewrite 20 accurate entries.

**3c. Scholars, athar, seerah and app prose with citations that do not resolve (11).**

| id | Name | Problem |
|---|---|---|
| **43, 44** | Al-Muizz, Al-Muzill | An **athar of 'Umar (RA)** in the hadith field, cited "Al-Hakim" with no volume, no number and no grade. Not in the nine collections; al-Mustadrak unreachable. **Verbatim duplicates of each other.** |
| **40, 46** | Ar-Raqeeb, Al-Baseer | Cited "**(Ibn Mas'ud)**" — a narrator's name used as a citation. No collection, no work, no number; nothing to resolve. Id 40 also opens by describing **Al-Basir** inside the **Ar-Raqeeb** card. Near-duplicates. |
| **73, 74** | Al-Wahid, Al-Ahad | Cited "**(Seerah)**" — a genre, not a source. **Verbatim duplicates of each other.** |
| **91** | Al-Jami | Cited "**(Seerah)**". The Salman al-Farsi narration exists in Musnad Ahmad, but nothing here resolves to it. |
| **48** | Al-Adl | **Ibn Taymiyyah** quoted with no work and no page. |
| **49** | Al-Khabeer | **al-Ghazali** quoted with no source — and the quote is a definition of **Al-Latif**, sitting in the **Al-Khabeer** card. Wrong Name and wrong genre. |
| **53, 58** | Al-Kabeer, Al-Majeed | **al-Ghazali** / "The scholars say", uncited. |
| **60, 78** | Ash-Shaheed, Al-Muakhkhir | **No citation of any kind.** App-authored prose in a sourced field. |

### TIER 4 — Not verified (2)

| id | Name | Why | What is needed |
|---|---|---|---|
| **16** | Al-Qayyum | Not in any of the nine collections. Cited "**Al-Hakim**" with no number and no grade, and presented as a direct prophetic instruction to Fatima. al-Mustadrak was not reachable. al-Hakim's *Mustadrak* is the classic locus of over-lenient authentication, so an untiered, unnumbered, ungraded citation from it does not meet "must be sahih or hasan". Confirms the spot check's concern. | A scholar must locate the narration, name the muhaqqiq, and state the grade — or it should be replaced with **Tirmidhi 3524 (Hasan)**, which carries the same du'a and is verified. |
| **82** | Al-Batin | Cited "**(Ahmad)**" with no number and no grade. Musnad Ahmad is not available in English in any corpus I could open. | Needs a number and a grade from Musnad Ahmad (or Adab al-Mufrad, which is reachable — that is how id 80 was rescued). |

---

## 5. Cross-cutting problems not captured by the per-entry verdict

1. **Nine hadith texts are shared verbatim by two or more Names.** 24=25, 26=36, 40≈46, 41≈42,
   43=44, 52=84, 73=74, 92≈93, and Muslim 2577 is reused at 33, 47, 55 and 90. That is
   ~19 of 99 cards carrying borrowed text. It reads as filler and it means one bad string
   ships twice (52/84 and 43/44 are both defective **and** duplicated).
2. **Topical inversion.** Id 41 (**Al-Khafid**, the Abaser) carries a hadith about *raising*.
   Id 49 (**Al-Khabeer**) carries a definition of **Al-Latif**. Id 40 (**Ar-Raqeeb**) opens by
   describing **Al-Basir**. Id 18 (**Al-Muhaymin**, the Guardian) carries a dhikr hadith.
   Id 50 (**Al-Azeem**) carries Al-A'la's half of a hadith. These would fail a reviewer who
   only read the Name and the text, with no citation checking at all.
3. **Grades are stated nowhere.** Not one of the 99 entries carries a grade. Six entries rest
   on narrations whose grade is contested or weak: id 50 (Abu Dawud 869 — **Da'if** per
   al-Albani), id 95 (Tirmidhi 2396 — Hasan Sahih per al-Albani, **Da'if** per Zubair Ali Zai),
   ids 16, 82, 43, 44 (ungraded, unnumbered, unreachable).
4. **Numbers are usually absent.** Only 12 of 99 entries carry a hadith number. "(Bukhari)"
   with no number is not falsifiable by a user and it is what let ids 63 and 19 attach
   Sahihayn authority to non-Sahihayn wording.
5. **`(Yaqeen, …)` and `(Derived from Names teachings)` are in the shipped citation string.**
   Four entries (20, 56, 71, 94) show a user a content-series name or an admission of authorship
   where a hadith reference should be. These are visible in the product.

---

## 6. Plain summary — how bad is this?

Bad, but not catastrophic, and the shape matters more than the count.

- **43 entries are genuinely fine.** The core Sahihayn material — the ninety-nine Names hadith,
  the hundred parts of mercy, the Jibril hadith of love, the thorny branch, "be mindful of
  Allah", the tahajjud du'a, the treasures-of-Paradise word — is real, correctly attributed,
  and matches the source. Someone did real work here.
- **20 more are accurate Qur'an in the wrong field.** Every one of those verses was fetched and
  is quoted correctly. That is a schema problem, not a truth problem, and it is cheap to fix.
- **The genuinely serious problem is small and sharp: 8 unlocatable prophetic quotations and
  13 wrong citations — 21 entries, about one in five.** Of those, the eight in Tier 1 are the
  ones that would embarrass the product if a scholar read the app, because each one puts a
  sentence in the Prophet's mouth that no one can find. Two of them (71, 94) say so in their
  own citation string.
- **11 more entries cite "(Seerah)", "(Ibn Mas'ud)", "(Hadith)", a tafsir, or nothing at all.**
  These are not false so much as unfalsifiable, which in a religious-content product is its own
  failure.

The field has never been through the pipeline and it shows exactly where you would expect:
the further an entry gets from Bukhari and Muslim, the worse it gets. Everything sourced to a
named, numbered Sahihayn hadith checks out. Everything sourced to a genre, an institute, a
narrator's name, or "derived" does not.

**Recommended order of work:** (1) the 8 Tier-1 entries — these should not ship as they stand;
(2) the 13 Tier-2 wrong citations, most of which have a concrete correction listed above;
(3) ids 8 and 66, which are one-word frame changes; (4) the field-naming/schema question for
the 20 accurate Qur'an entries; (5) numbers and grades across all 99 as a standing rule.

Nothing above was applied. Every correction is a proposal for the founder to accept, reject,
or send to a scholar.

---

## 7. Full table — all 99

Verdicts: **CLEAN** / **WRONG-CITATION** / **NOT-A-HADITH** / **UNLOCATABLE** /
**NOT-VERIFIED**. (No entry earned a standalone **UNGRADED** verdict — grading is absent
across all 99, so it is reported as a cross-cutting problem in §5.3 and inside the evidence
column where a specific grade is contested.)

| id | Name | Verdict | Evidence |
|---|---|---|---|
| 1 | Allah | **CLEAN** | Bukhari 7392 verified (Wayback, sunnah.com/bukhari:7392). Text reads "memorized them all by heart"; the app's "and acts upon them" is an added gloss. No number cited. |
| 2 | Ar-Rahman | **CLEAN** | Sahih Muslim 2752 verified — "created mercy in one hundred parts… retained ninety-nine". No number cited. |
| 3 | Ar-Raheem | **CLEAN** | Bukhari 5999 — "Allah is more merciful to His slaves than this lady to her son". App generalises to "a mother"; acceptable paraphrase. |
| 4 | Al-Malik | **CLEAN** | Bukhari 7382 (also 4812, 6519) — "I am the King; where are the kings of the earth?" verified. |
| 5 | Al-Quddus | **WRONG-CITATION** | Muslim 487 (corpus muslim:1091) is **the Prophet ﷺ** saying *Subbuhun Quddusun, Rabbu-l-mala'ikati wa-r-ruh* in ruku' and sujud. The app attributes it to **the angels** and renders it "Holy, Holy, Holy" — a triple repetition that exists in Isaiah 6:3, not in the narration. |
| 6 | As-Salam | **CLEAN** | Tirmidhi 2485 (graded Sahih) verified; also Ibn Majah 1334. App's "feed the hungry" for the text's "feed (others)". |
| 7 | Al-Mumin | **CLEAN** | Abu Dawud 4918 — "The believer is the believer's mirror". Unnumbered and ungraded in the app. |
| 8 | Al-Azeez | **NOT-A-HADITH** | Text is **Qur'an 63:8**, verified via quran.com, but framed "The Prophet ﷺ said:" — divine speech presented as prophetic speech. |
| 9 | Al-Jabbar | **CLEAN** | The sujud wording is verbatim in Nasa'i 1129 and in Muslim 771; Tirmidhi 3421/3423 carry the same long du'a. Citation "(Tirmidhi)" is defensible but imprecise; Muslim 771 is the stronger locus. |
| 10 | Al-Khaliq | **CLEAN** | Bukhari 6227 and Muslim 2612/2841 — "Allah created Adam in His picture/image". Citation resolves. |
| 11 | Al-Ghaffar | **CLEAN** | Bukhari 6307 — "more than seventy times a day" verified. |
| 12 | Al-Wahhab | **CLEAN** | Bukhari 7419 (also 4684) — "Allah's Hand is full… not affected by the continuous spending night and day". |
| 13 | Ar-Razzaq | **CLEAN** | Tirmidhi 2344 (Hasan Sahih) — "provide for you just as a bird… goes out empty and returns full". The "in the evening" clause follows Ibn Majah 4164. |
| 14 | Al-Aleem | **WRONG-CITATION** | Muslim 2653 (corpus muslim:6749) reads "Allah ordained the measures of creation fifty thousand years before He created the heavens and the earth". The app's opening clause "Allah knew what His servants would do, and He wrote it all" sits **inside the quotation marks** but is not in the narration. |
| 15 | Al-Hayy | **WRONG-CITATION** | Tirmidhi 3524 (Hasan) is Anas describing the Prophet's **own practice** when distressed. The app converts it into a direct imperative in quotes — "Call upon Allah using…" — which the narration does not contain. |
| 16 | Al-Qayyum | **NOT-VERIFIED** | Not present in any of the nine English collections searched (Bukhari, Muslim, Tirmidhi, Abu Dawud, Ibn Majah, Nasa'i, Malik, Nawawi 40, Qudsi 40). Cited to "Al-Hakim" with **no volume, no number, no grade**; al-Mustadrak was not reachable. Presented as a direct prophetic instruction. |
| 17 | An-Nur | **CLEAN** | Muslim 763 (corpus muslim:1788) — the light du'a on the way to prayer, verified. |
| 18 | Al-Muhaymin | **CLEAN** | Bukhari 7405 verified — "I am with him when he remembers Me". Note: a dhikr hadith used for **Al-Muhaymin** (the Guardian); topical fit is weak. |
| 19 | Al-Mutakabbir | **WRONG-CITATION** | Muslim 2620 (Wayback) reads "Glory is His lower garment and Majesty is His cloak … **he who contends with Me… I shall torment him**". The app's ending "I will throw into the Fire" is **Abu Dawud 4090**'s wording, attributed to Muslim. Also renders first-person divine speech as "The Prophet ﷺ said" with no hadith-qudsi marker. |
| 20 | Al-Bari | **UNLOCATABLE** | "You brought me out of nothingness into being" is in quotation marks and attributed to the Prophet ﷺ. **Zero hits** across all nine collections. The citation given is a Yaqeen Institute content series — not a narration source. |
| 21 | Al-Musawwir | **NOT-A-HADITH** | Qur'an 3:6 verified via quran.com. Correctly labelled; wrong field. |
| 22 | Al-Qahhar | **NOT-A-HADITH** | Qur'an 12:39 verified (speech of Yusuf AS). Correctly labelled; wrong field. |
| 23 | Al-Fattah | **NOT-A-HADITH** | Qur'an 35:2 verified. Correctly labelled; wrong field. |
| 24 | Al-Qabid | **CLEAN** | Bukhari 6425 (also 3158, 4015; Muslim 2961) verified via Wayback — "I am not afraid that you will become poor, but I am afraid that worldly wealth will be given to you in abundance". Unnumbered. **Verbatim duplicate of id 25.** |
| 25 | Al-Basit | **CLEAN** | Same as id 24 — Bukhari 6425 / Muslim 2961. **Verbatim duplicate of id 24**; two different Names carry one identical hadith. |
| 26 | Al-Hakeem | **NOT-A-HADITH** | Qur'an 12:100 verified. **Verbatim duplicate of id 36.** |
| 27 | Al-Wadud | **CLEAN** | Bukhari 3209 / Muslim 2637 verified — the Jibril hadith of divine love. |
| 28 | Ash-Shakur | **CLEAN** | Bukhari 652 / Muslim 1914 verified. "Allah thanked him" is a defensible rendering of *fa-shakara Allahu lahu*. |
| 29 | Al-Haleem | **CLEAN** | Bukhari 7378 verified via Wayback — "None is more patient than Allah against the harmful and annoying words He hears: they ascribe children to Him, yet He bestows upon them health and provision". |
| 30 | Al-Kareem | **NOT-A-HADITH** | Qur'an 96:3 verified. Note the verse says *Al-Akram*, which the app itself flags. Correctly labelled; wrong field. |
| 31 | At-Tawwab | **CLEAN** | Tirmidhi 3540 (Sahih) hadith qudsi verified — matches closely. |
| 32 | As-Sabur | **CLEAN** | Bukhari 6470 — "no gift better and vaster than patience" verified. |
| 33 | Al-Hadi | **CLEAN** | Muslim 2577 verified (corpus muslim:6572, Nawawi 24, Qudsi 17). |
| 34 | As-Samad | **NOT-A-HADITH** | Qur'an 28:24 verified (speech of Musa AS). Correctly labelled; wrong field. |
| 35 | Al-Wakeel | **WRONG-CITATION** | **Qur'an 3:173 is not about Ibrahim.** Verified text: it is the believers at Hamra' al-Asad who said *Hasbunallahu wa ni'mal-Wakil*. The Ibrahim attribution is an athar of Ibn 'Abbas in **Bukhari 4563**; "Be cool and safe" is **Qur'an 21:69**. One citation is given, and it supports neither quoted claim. |
| 36 | Al-Lateef | **NOT-A-HADITH** | Qur'an 12:100 verified. **Verbatim duplicate of id 26.** |
| 37 | Al-Mujeeb | **CLEAN** | Tirmidhi 3505 (Sahih) — "no Muslim man supplicates with it… except Allah responds to him". Verified. |
| 38 | Ash-Shafi | **CLEAN** | Bukhari 5675 / Muslim 2191 verified. |
| 39 | Al-Hafeez | **CLEAN** | Tirmidhi 2516 (Hasan Sahih) verified. Grade not stated in app. |
| 40 | Ar-Raqeeb | **NOT-A-HADITH** | "(Ibn Mas'ud)" is a narrator's name used as a citation — no collection, no work, no number; nothing to resolve. The entry also opens by describing **Al-Basir** inside the **Ar-Raqeeb** card. Near-duplicate of id 46. |
| 41 | Al-Khafid | **CLEAN** | Muslim 2588 (corpus muslim:6592) supports "none humbles himself for Allah but Allah raises him". But the Name is **Al-Khafid (the Abaser)** and the hadith is about *raising*; topical inversion. Unnumbered. |
| 42 | Ar-Rafi | **CLEAN** | Muslim 2588. **Duplicate of id 41** — same hadith across two Names. |
| 43 | Al-Muizz | **NOT-A-HADITH** | An **athar of 'Umar (RA)**, not a prophetic narration, sitting in the hadith field. Cited "Al-Hakim" with no number and no grade; not present in the nine collections searched and al-Mustadrak was not reachable. **Verbatim duplicate of id 44.** |
| 44 | Al-Muzill | **NOT-A-HADITH** | Same athar of 'Umar as id 43, **verbatim duplicate**, same unverifiable Al-Hakim citation. |
| 45 | As-Sami | **UNLOCATABLE** | "I heard you — and here is the child, already named Yahya" is in quotation marks and attributed to **Allah**. Qur'an 19:3–7 verified via quran.com: 19:7 reads "O Zechariah, indeed We give you good tidings of a boy whose name will be John." The quoted sentence is invented. The "corner of the masjid" detail belongs to 3:39, not 19. |
| 46 | Al-Baseer | **NOT-A-HADITH** | "(Ibn Mas'ud)" again — a name, not a citation. Nothing to resolve. Near-duplicate of id 40. |
| 47 | Al-Hakam | **CLEAN** | Muslim 2577 verified. Correctly framed as divine speech. (Shared with ids 55 and 90.) |
| 48 | Al-Adl | **NOT-A-HADITH** | A saying of **Ibn Taymiyyah**, with no work and no page. Not a narration; nothing to grade. |
| 49 | Al-Khabeer | **NOT-A-HADITH** | A saying of **al-Ghazali**, uncited — and it is a definition of **Al-Latif**, sitting in the **Al-Khabeer** card. Wrong Name and wrong genre. |
| 50 | Al-Azeem | **WRONG-CITATION** | Abu Dawud 869 has **two halves**: *fa-sabbih bismi Rabbika al-'Azim* (56:74) → "use it when **bowing**"; *Sabbih isma Rabbika al-A'la* (87:1) → "use it when **prostrating**". The app gave **Al-Azeem** the al-A'la/sujud half and glossed it "we declare His highest" — that is Al-A'la's meaning, not Al-Azeem's. Compounding this, Abu Dawud 869 is graded **Da'if by al-Albani**. |
| 51 | Al-Ghafur | **CLEAN** | Tirmidhi 3540 (Sahih) hadith qudsi verified. |
| 52 | Al-Ali | **WRONG-CITATION** | Muslim 2588 contains only "whoever humbles himself for Allah, Allah raises him". The second clause — "Whoever exalts himself, Allah lowers him" — is **not in Muslim**; it is Ibn Majah 4176. Cited to Muslim as one quotation. **Duplicate of id 84.** |
| 53 | Al-Kabeer | **NOT-A-HADITH** | A saying of **al-Ghazali** plus app-authored salah commentary. Not a narration. |
| 54 | Al-Muqeet | **UNLOCATABLE** | "Allah provides for every creature — He is Al-Muqeet, the Nourisher of all things" is in quotation marks and attributed to the Prophet ﷺ, then sourced to **Ibn Kathir's tafsir** — a commentary, not a narration source. **Zero hits** across all nine collections. |
| 55 | Al-Haseeb | **CLEAN** | Muslim 2577 verified. Third reuse of the same hadith (see 47, 90). |
| 56 | Al-Jaleel | **UNLOCATABLE** | "Fill your heart with reverence of Allah that draws you near, not fear that drives you away" is in quotation marks and attributed to the Prophet ﷺ. **Zero hits** across all nine collections. The source given is a Yaqeen Institute daily-content series. |
| 57 | Al-Wasi | **NOT-A-HADITH** | Qur'an 2:115 verified. Correctly labelled; wrong field. |
| 58 | Al-Majeed | **NOT-A-HADITH** | "The scholars say…" attributed to al-Ghazali, uncited. Not a narration. |
| 59 | Al-Baith | **NOT-A-HADITH** | Qur'an 36:77–79 verified. Correctly labelled; wrong field. |
| 60 | Ash-Shaheed | **NOT-A-HADITH** | **No citation of any kind.** App-authored etymological/theological claim about why the martyr is called *shahid*, presented in the hadith field. |
| 61 | Al-Haqq | **CLEAN** | Bukhari 7385 verified — including the Sufyan addition "You are the Truth". One slip: the narration is his invocation **at night (tahajjud)**, not "when waking". |
| 62 | Al-Qawiyy | **CLEAN** | Bukhari 6114 / Muslim 2609 verified. |
| 63 | Al-Mateen | **WRONG-CITATION** | Bukhari 4205/6384/7386 and Muslim 2704 all read "a treasure from the **treasures of Paradise**". The phrase "**from beneath the throne**" returns **zero hits** across all nine collections. A Sahihayn citation is attached to wording that is not in either Sahih. |
| 64 | Al-Waliyy | **WRONG-CITATION** | Bukhari 6416 ("Be in this world as if you were a stranger or a traveler") is real, but it is a hadith about **detachment from the world** — it says nothing about *wilaya*, protection, or friendship with Allah, and it is not the hadith behind this card's du'a. Confirms the spot-check finding. |
| 65 | Al-Hameed | **WRONG-CITATION** | The hadith qudsi "O son of Adam, devote yourself to My worship…" is **Tirmidhi 2466 (Sahih)** and **Ibn Majah 4107** — **not Muslim**. Zero occurrences in Sahih Muslim. The card's gloss is about praise; the narration is about worship and sufficiency. |
| 66 | Al-Muhsi | **NOT-A-HADITH** | Text is **Qur'an 6:59**, verified via quran.com, framed "The Prophet ﷺ said:" — divine speech presented as prophetic speech. |
| 67 | Al-Mubdi | **NOT-A-HADITH** | Qur'an 10:34 verified. Correctly labelled; wrong field. |
| 68 | Al-Muid | **NOT-A-HADITH** | Qur'an 30:27 verified — the text is accurate. It is a Qur'an ayah in a hadith field, as flagged in the spot check. |
| 69 | Al-Muhyi | **NOT-A-HADITH** | Qur'an 57:17 verified. Correctly labelled; wrong field. |
| 70 | Al-Mumeet | **CLEAN** | Tirmidhi 2307 (Hasan Sahih) verified. |
| 71 | Al-Wajid | **UNLOCATABLE** | "Allah is never at a loss for what you need" is in quotation marks and attributed to the Prophet ﷺ; the citation reads literally **"(Derived from Names teachings)"** — the field admits the text is authored, while the sentence still says the Prophet said it. **Zero hits** across all nine collections. |
| 72 | Al-Majid | **CLEAN** | Bukhari 3370 verified — the salawat Ibrahimiyya, ending *innaka Hamidun Majid*. |
| 73 | Al-Wahid | **NOT-A-HADITH** | Bilal's story cited to "**(Seerah)**" — a genre, not a source. Nothing to resolve. **Verbatim duplicate of id 74.** |
| 74 | Al-Ahad | **NOT-A-HADITH** | Same as id 73, **verbatim duplicate**, same "(Seerah)" non-citation. |
| 75 | Al-Qadir | **UNLOCATABLE** | "Nothing is beyond the power of Allah" is in quotation marks, attributed to the Prophet ﷺ, and cited to **(Muslim)**. **Zero hits** in Sahih Muslim or in any of the nine collections, under this or any near phrasing. Confirms the spot-check finding. |
| 76 | Al-Muqtadir | **NOT-A-HADITH** | Qur'an 54:55 verified. Correctly labelled; wrong field. |
| 77 | Al-Muqaddim | **UNLOCATABLE** | "Your rizq chases you the way death chases you" is in quotation marks and attributed to the Prophet ﷺ. The citation is the bare word **"(Hadith)"** — no collection, no number. **Zero hits** across all nine collections. |
| 78 | Al-Muakhkhir | **NOT-A-HADITH** | Narrative prose about Yusuf (AS) in prison. **No citation of any kind.** |
| 79 | Al-Awwal | **CLEAN** | Muslim 2713 (corpus muslim:6889) verified — "Thou art the First, there is naught before Thee…". |
| 80 | Al-Akhir | **CLEAN** | Verified independently of the corpus: **Al-Adab Al-Mufrad 479** (Wayback of sunnah.com/adab/27) — Anas: "If the Final Hour comes while you have a shoot of a plant in your hands… you should plant it." Also Musnad Ahmad. "(Ahmad)" is unnumbered and ungraded. |
| 81 | Az-Zahir | **CLEAN** | Muslim 2713 verified. "Nothing closer to me than You" follows the Ibn Majah rendering of *laysa dunaka shay'*; Muslim's Siddiqui rendering is "nothing beyond Thee". Acceptable. |
| 82 | Al-Batin | **NOT-VERIFIED** | Cited to "**(Ahmad)**" with no number and no grade. Musnad Ahmad is not available in English in any corpus I could reach, and the narration is not in the nine collections searched. Content plausible but unconfirmed. |
| 83 | Al-Wali | **NOT-A-HADITH** | Qur'an 7:196 verified. Minor framing slip: introduced as "Allah says", but the verse is the Prophet's speech (*"Say: Indeed my protector is Allah…"*). |
| 84 | Al-Mutaali | **WRONG-CITATION** | Identical to id 52 — the clause "Whoever exalts himself, Allah lowers him" is not in Muslim 2588. **Duplicate of id 52.** |
| 85 | Al-Barr | **WRONG-CITATION** | **Muslim 1342 verified via Wayback: it is the du'a on mounting for a journey** (Ibn 'Umar), ending with the return addition *"We are returning, repentant, worshipping our Lord and praising Him"*. It contains **no** "Our Lord is Al-Barr, Al-Ghafur", and it is not framed as "upon completing Hajj". The quoted phrase returns zero hits across all nine collections. |
| 86 | Al-Afuw | **CLEAN** | Tirmidhi 3513 (also Ibn Majah 3850) verified — the Laylat al-Qadr du'a taught to 'A'isha. |
| 87 | Ar-Rauf | **NOT-A-HADITH** | Qur'an 9:128 verified. Correctly labelled; wrong field. |
| 88 | Malik-ul-Mulk | **NOT-A-HADITH** | Qur'an 3:26 verified. Correctly labelled; wrong field. |
| 89 | Dhul-Jalali wal-Ikram | **CLEAN** | Tirmidhi 3524 (Hasan, per al-Albani and Zubair Ali Zai) verified — "Be constant with: O Possessor of Majesty and Honor". Grade not stated in app. |
| 90 | Al-Muqsit | **CLEAN** | Muslim 2577 verified. Fourth reuse of the same hadith (see 47, 55, and 33's overlapping text). |
| 91 | Al-Jami | **NOT-A-HADITH** | Salman al-Farsi's story cited to "**(Seerah)**" — a genre, not a source. The story is narrated in Musnad Ahmad, but nothing here resolves. |
| 92 | Al-Ghaniyy | **CLEAN** | Bukhari 6446 / Muslim 1051 verified — "true wealth is feeling sufficiency in the soul". Near-duplicate of id 93. |
| 93 | Al-Mughni | **CLEAN** | Bukhari 6446 verified — correctly numbered. Near-duplicate of id 92. |
| 94 | Al-Mani | **UNLOCATABLE** | "What Allah withholds is also His mercy" is in quotation marks and attributed to the Prophet ﷺ; the citation reads literally **"(Derived from Names teachings)"**. **Zero hits** across all nine collections. |
| 95 | Ad-Darr | **CLEAN** | Tirmidhi 2396 verified — "greater reward comes with greater trial… when Allah loves a people He subjects them to trials". Graded Hasan Sahih (al-Albani, Shakir); Zubair Ali Zai grades it Da'if — the app states no grade. |
| 96 | An-Nafi | **WRONG-CITATION** | **Ibn Majah 3846 verified: it is 'A'isha's du'a asking Allah for all *khayr* (good)**, in this world and the next. The quoted sentence "Ask Allah for benefit (naf') in this world and the next" does not occur in it. A numbered citation attached to an invented paraphrase. |
| 97 | Al-Badi | **NOT-A-HADITH** | Qur'an 2:117 verified. Correctly labelled; wrong field. |
| 98 | Al-Baqi | **NOT-A-HADITH** | Qur'an 16:96 verified. Correctly labelled; wrong field. |
| 99 | Ar-Rasheed | **CLEAN** | Bukhari 71 verified — "If Allah wants to do good to a person, He makes him comprehend the religion". |

---

*Audit performed 2026-08-03. Report only — no content file, migration, or database row was modified.*
