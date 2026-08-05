# Name-story deck COLLISION LEDGER

**Status: LIVE APPEND-ONLY ARTIFACT.** Built 2026-08-03 from the 14 decks that were in
`assets/content/name_stories.json` at the start of this pass plus the 10 approved drafts in this
directory, **deduplicated by `deck_id`**. **Scope: 24 of 99 Names. 75 remain.**

> **Asset state at the end of this pass.** A concurrent transcription landed all 10 drafts into
> `assets/content/name_stories.json` while this ledger was being written, so the asset now holds
> **24 decks**, all carrying `review_verdict: "good"` / `reviewed_by: "founder"`, and
> `renderedDuaSources` now carries the five new pins listed in §2b. **Every beat-8 line and
> `name_intro` in §3 and §4a was re-checked byte-for-byte against the transcribed asset after it
> landed: 24 of 24 match.** No deck was double-counted.

**Governing plan:** [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) —
especially §7 (the five bars, the successor sweep, and the three rules batch 2 earned).
**What collisions looked like in practice:** [`2026-08-03-BATCH2-ADVERSARIAL-VERDICT.md`](./2026-08-03-BATCH2-ADVERSARIAL-VERDICT.md)
and [`2026-08-03-BATCH2-FIX-REPORT.md`](./2026-08-03-BATCH2-FIX-REPORT.md).

---

## How to use this — read before drafting anything

**Collision, not authenticity, is the binding constraint.** Batch 2 returned **zero authenticity
failures and five reasoning / collision / disclosure failures**. Every shipped deck permanently
spends a story, a passage, an insight and a takeaway, so the last twenty Names will be materially
harder than the first twenty.

**The protocol, in order:**

1. **Claim before you draft.** Read §§1–5 first. If the story, the passage, the insight or the
   rendered phrase you were about to reach for is already in a table, it is spent — pick again
   *before* you fetch, not after review.
2. **Check all five axes, every time.** Story · passage · insight · **rendered English** · Arabic
   root. Batch 2's drafter compared **takeaway to takeaway** and missed a **beat-to-beat**
   collision with a shipped deck (`al-mujeeb@1` *"He asked for nothing"* vs shipped `ash-shafi@1`
   *"He demanded nothing"*, four āyāt apart in one sūrah). §4 exists for exactly that class.
3. **Run the English pass, not only the Arabic-root pass.** Two of batch 2's collisions were
   invisible to a root sweep because they collided only in rendered English (*"Restorer"* vs
   *"Restorer of the Broken"*; the pair above). Diff **every** rendered `primary` / `label` /
   `source` / `translation` string against every shipped and drafted string.
4. **Judge bar 3 against what renders.** `story` and `verse` beats carry `arabic: ""` in all 14
   shipped decks — only `name_intro` and `dua` beats render Arabic. A sibling root inside a story
   quotation's Arabic never reaches a screen; one in a `name_intro` or a duʿā always does.
5. **Check §6 before you accept an assignment.** If your Name's catalogue duʿā is in a duplicate
   group or carries another Name in the vocative, **the deck cannot be bar-3 clean today** and you
   should say so rather than draft around it.
6. **Append your claims here when your deck is signed** — same tables, same column order, sorted
   by the same key. Add rows; do not rewrite existing ones. If you find an existing row to be
   wrong, add a `CORRECTION` row beneath it rather than editing in place, so the diff shows the
   change.
7. **Never action a recommendation to change catalogue data without independent re-verification.**
   That artifact has now been wrong in **both** batches, in the same direction (id 51 in batch 1,
   id 16 in batch 2). Both times the correct action was the opposite of the one proposed.

**Sort keys (keep them stable).** §1–§5: deck_id, ASCII ascending. §6–§7: catalogue `id`, numeric
ascending.

**Legend.** `[S]` = one of the 14 decks shipped before this pass. `[D]` = one of the 10 batch-1 /
batch-2 decks, drafted in this directory and transcribed into the asset on 2026-08-03. **Both are
now in `name_stories.json` and both are founder-signed**; the distinction is kept because it
records *when* a claim was made and which decks predate the successor sweep (see §2a). A `[D]`
deck's own history still matters: `al-qayyum@1` and `al-waliyy@1` each discarded a full set of
scripture between R1 and R2, so a passage rejected by an R1 is **not** thereby free — check §2d.

**Headline counts, computed 2026-08-03.**

| | count |
|---|---|
| Decks in this ledger | **24** (14 `[S]` + 10 `[D]`) |
| Names remaining | **75** |
| Distinct narratives spent | **24** |
| Qurʾān citations (with repeats) | **68** |
| **Distinct āyāt spent** | **67** |
| Distinct sūrahs touched | **31** |
| Āyāt cited by more than one deck | **1** — 65:3 (`al-wakeel@1` **and** `ar-razzaq@1`, both shipped) |
| **Distinct ḥadīth spent** | **28** (0 cited twice) |
| Decks with no ḥadīth at all | 6 — `al-hadi@1`, `al-jabbar@1`, `al-lateef@1`, `as-samad@1`, `ar-raheem@1`, `al-qadir@1` |
| Beat-8 lines spent | **24** |
| `dua_arabic` duplicate groups in the catalogue | **14**, spanning **30** Names |
| Remaining Names blocked on the duʿā axis | **30 of 75** |
| Remaining Names clear on the duʿā axis | **45 of 75** |

---

## 1 · Stories claimed

One row per deck. **Sorted by deck_id.**

| deck | Name (catalogue id) | narrative claimed | central figure(s) | source of the narrative |
|---|---|---|---|---|
| `al-afuw@1` [D] | Al-Afuw (86) | ʿĀʾisha asks what to say if she meets Laylat al-Qadr; one sentence is taught | ʿĀʾisha; the Prophet ﷺ | Ibn Mājah 3850 / Tirmidhī 3513 |
| `al-baseer@1` [S] | Al-Baseer (46) | Hājar in the empty valley; the running between Ṣafā and Marwa; Zamzam | Hājar; Ibrāhīm | Bukhārī 3364 |
| `al-fattah@1` [S] | Al-Fattah (23) | Ḥudaybiyyah — the shut door named a clear triumph on the road home | the Prophet ﷺ | Qurʾān 48:1 + Bukhārī 4172 / 4833 |
| `al-ghaffar@1` [S] | Al-Ghaffar (11) | the servant who sinned and returned three times | an unnamed servant | Bukhārī 7507 |
| `al-ghafur@1` [D] | Al-Ghafur (51) | *an-najwā* — the private conversation on the Day of Judgement; the covering | Ibn ʿUmar (narrating); an unnamed believer | Bukhārī 2441 |
| `al-hadi@1` [S] | Al-Hadi (33) | Mūsā's flight from Egypt to Midian | Mūsā | Qurʾān 28:22 (+ 28:15/21/23) |
| `al-haleem@1` [D] | Al-Haleem (29) | *"the words He hears"* — creation's reaction to `shirk`, and the provision that continues | (no protagonist; three quoted texts) | Qurʾān 19:90–91 + Bukhārī 7378 |
| `al-jabbar@1` [S] | Al-Jabbar (9) | Yaʿqūb's grief; the shirt cast over his face; sight and son restored | Yaʿqūb, Yūsuf | Qurʾān 12:84/86/87/94/96 |
| `al-kareem@1` [D] | Al-Kareem (30) | the descent in the last third of every night; three questions | the Prophet ﷺ (narrating), Abū Hurayra | Bukhārī 1145 |
| `al-lateef@1` [S] | Al-Lateef (36) | Yūsuf's answer at the end — *"my Lord is subtle in fulfilling what He wills"* | Yūsuf | Qurʾān 12:100 (+ 12:15/20/42) |
| `al-muid@1` [D] | Al-Muid (68) | Umm Salama objects out loud, then says the taught words anyway | Umm Salama, Abū Salama | Muslim 918a |
| `al-mujeeb@1` [D] | Al-Mujeeb (37) | Yūnus inside the fish; the one sentence; the plural rescue | Yūnus | Qurʾān 21:87–88 + Tirmidhī 3505 |
| `al-qadir@1` [D] | Al-Qadir (75) | Ibrāhīm asks to be shown; the four birds and the hills | Ibrāhīm | Qurʾān 2:260 |
| `al-qayyum@1` [D] | Al-Qayyum (16) | the night the whole camp slept through Fajr, including Bilāl who volunteered to keep watch | Bilāl, the Prophet ﷺ, Abū Qatāda | Bukhārī 595 |
| `al-waliyy@1` [D] | Al-Waliyy (64) | the words said on mounting for a journey | the Prophet ﷺ | Muslim 1342 / Tirmidhī 3438 |
| `al-wadud@1` [S] | Al-Wadud (27) | the man who lost his camel in the desert and found it again | an unnamed traveller | Muslim 2747a / Bukhārī 6309 |
| `al-wakeel@1` [S] | Al-Wakeel (35) | after Uḥud — the warning, `ḥasbunallāh`, and the return without harm | the believers after Uḥud | Qurʾān 3:172–174 (+ Bukhārī 4563) |
| `ar-raheem@1` [D] | Ar-Raheem (3) | the youths of the cave — three hundred years and nine | the Companions of the Cave | Qurʾān 18:10–25 |
| `ar-rahman@1` [S] | Ar-Rahman (2) | the mother among the captives who found her child | an unnamed captive mother | Bukhārī 5999 |
| `ar-razzaq@1` [S] | Ar-Razzaq (13) | the birds that go out empty and return full | (parable, no protagonist) | Tirmidhī 2344 |
| `as-salam@1` [S] | As-Salam (6) | the cave of Thawr during the hijrah | the Prophet ﷺ, Abū Bakr | Qurʾān 9:40 + Bukhārī 3653 |
| `as-samad@1` [S] | As-Samad (34) | Zakariyyā's hidden call and the son given an unprecedented name | Zakariyyā | Qurʾān 19:2–7 |
| `ash-shafi@1` [S] | Ash-Shafi (38) | Ayyūb's one-line prayer and the doubled answer | Ayyūb | Qurʾān 21:83–84 |
| `at-tawwab@1` [S] | At-Tawwab (31) | the man who took a hundred lives and died on the road | an unnamed man of an earlier nation | Bukhārī 3470 |

### 1a · Narratives explicitly rejected because they were already spent — do not re-propose

| narrative | rejected by | because it is |
|---|---|---|
| Ayyūb, 21:83–84 | `ar-raheem@1` R1 (**rejected outright**) | shipped as `ash-shafi@1` — same prophet, same two āyāt, same framing, same takeaway |
| the man who took a hundred lives (Bukhārī 3470) | `al-ghafur@1` | shipped as `at-tawwab@1` |
| Mūsā and al-Khiḍr | (recorded in the batch-2 fix report for Al-Hakeem, 26) | its insight is already on screen in shipped `al-lateef@1` |
| Mūsā's mother, 28:7–13 (`فَرَدَدْنَاهُ إِلَىٰ أُمِّهِ`) | `al-muid@1`, cut before drafting; and Al-Hafeez (39) blocked on it | it is `al-jabbar@1`'s arc — a parent's lost child returned |
| Ṭāʾif and the angel of the mountains (Bukhārī 3231) | `al-afuw@1`, and again by `al-haleem@1` | the forbearance recorded is the Prophet's ﷺ, i.e. human — the reverence line |
| the bedouin in the mosque (Bukhārī 6025) | `al-haleem@1` | same reverence line |
| the private conversation (Bukhārī 2441) | `al-kareem@1` | selected by `al-ghafur@1` in the same batch |
| Yūnus in the fish (21:87–88) | `ar-raheem@1` | rejected there on proximity to `ash-shafi@1`; **subsequently claimed by `al-mujeeb@1`** |
| 2:259 (the man revived after a hundred years) | `al-qadir@1` | its shape is `ar-raheem@1`'s centuries-long sleep and awakening |
| Nūḥ (29:14) · Pharaoh (20:42–48, 79:24) · Iblīs's respite (7:14–15) · Ibrāhīm and Lūṭ's people (11:74–76) · the people of Yūnus (10:98) | `al-haleem@1` | each fails bar 5 or the reverence line — **the sweep is recorded in that draft and does not need re-deriving** |
| Kaʿb b. Mālik and the three left behind (Bukhārī 4418, 9:117–118) | `ar-raheem@1` | its engine is *tawba*, already carried by `at-tawwab@1` / `al-ghaffar@1` / `al-ghafur@1` / `al-afuw@1`. **Held as an unclaimed fallback.** |
| mercy in one hundred parts (Bukhārī 6469) | `ar-raheem@1` | a statement of scale, not a narrative; closes on the Fire |
| Tirmidhī 3524 (*"whenever a matter distressed him"*) | `al-qayyum@1` R2 | its text **is catalog id 15 (Al-Hayy)'s entire duʿā** — it is Al-Hayy's material and must not be spent elsewhere |

---

## 2 · Passages claimed

**Every citation, with the deck that spent it and the neighbours that deck's successor sweep
already examined.** *Sorted by deck_id, then by citation.*

`n±1` cells record what was **fetched**. A blank means the deck predates the successor sweep
(the sweep was invented by the batch-1 pilot; the 14 shipped decks were signed before it existed)
— **that ground is unswept, not clean.**

### 2a · Qurʾān

| citation | deck | role on the deck | n−1 examined | n+1 examined | note |
|---|---|---|---|---|---|
| 42:25 | `al-afuw@1` [D] | verse beat | — | **42:26** — ends *"the disbelievers will have a severe punishment"*; also carries `وَيَسْتَجِيبُ` (`al-mujeeb@1`'s root) | non-blocking; it contradicts no beat. Named in plan §7. |
| 97:3 | `al-afuw@1` [D] | story beat 4 | — | — | |
| 58:1 | `al-baseer@1` [S] | verse beat (excerpt) | — | — | unswept |
| 35:2 | `al-fattah@1` [S] | verse beat (excerpt) | — | — | unswept; **Sūrat Fāṭir also carries `al-haleem@1` at 35:45** |
| 48:1 | `al-fattah@1` [S] | story quotation | — | — | unswept |
| 39:53 | `al-ghaffar@1` [S] | verse beat (excerpt) | — | — | unswept; **Sūrat az-Zumar also carries `al-qayyum@1` at 39:42** |
| 4:110 | `al-ghafur@1` [D] | verse beat | — | — | no successor sweep recorded in this draft |
| 1:6 | `al-hadi@1` [S] | takeaway basis (not quoted) | — | — | |
| 22:54 | `al-hadi@1` [S] | verse beat (final clause) | — | — | unswept |
| 28:15 · 28:21 · 28:22 · 28:23 | `al-hadi@1` [S] | story + backstory | — | — | unswept |
| 19:90 · 19:91 | `al-haleem@1` [D] | story beat 3 (one sentence across two āyāt) | — | **19:92, 19:93, 19:96** — arc runs toward `وُدًّا`; **19:98** disclosed as the sūrah's own ending | clean |
| 35:45 | `al-haleem@1` [D] | verse beat | **35:44** — warning material, disclosed | **none — 35:45 is the final āyah of Sūrat Fāṭir** (36:1 fetched to confirm) | strongest available form of bar 5 |
| 12:18 · 12:84 · 12:86 · 12:87 · 12:94 · 12:96 | `al-jabbar@1` [S] | 12:87 verse beat (excerpt); rest story/detail | — | — | unswept. **12:87's ending clause is deliberately omitted.** 12:100 explicitly ceded to `al-lateef@1`. |
| 27:40 | `al-kareem@1` [D] | verse beat (excerpt) | — | — | no successor sweep recorded; quoted clause is Sulaymān's speech |
| 12:15 · 12:20 · 12:42 · 12:100 | `al-lateef@1` [S] | 12:100 story; rest arc detail | — | — | unswept |
| 42:19 | `al-lateef@1` [S] | verse beat | — | — | unswept; **Sūrat ash-Shūrā also carries `al-afuw@1` at 42:25** |
| 67:13 | `al-lateef@1` [S] | takeaway (quoted) | — | 67:14 noted as ending in the Name | spec deviation, founder-blessed |
| 30:27 | `al-muid@1` [D] | verse beat (excerpt) | **30:26** clean | **30:28** parable, clean | 30:50 also fetched (Al-Muhyi + Al-Qadir), off-screen |
| 2:186 | `al-mujeeb@1` [D] | verse beat (excerpt, opens mid-āyah) | **2:185** fasting ruling | **2:187** fasting ruling — contains `فَتَابَ عَلَيْكُمْ وَعَفَا عَنكُمْ` (`at-tawwab@1` + `al-afuw@1` roots), off-screen | clean |
| 21:87 | `al-mujeeb@1` [D] | story beat 4 **and** the duʿā's source | **21:86** *"admitted them into Our mercy"* | (see 21:88) | contains `نَّقْدِرَ` — `al-qadir@1`'s root, negated, off-screen |
| 21:88 | `al-mujeeb@1` [D] | story beat 5 | — | **21:89, 21:90** — Zakariyyā, a second answered call | clean **and confirming**; 21:89–90 is `as-samad@1`'s protagonist one tap away |
| 2:260 | `al-qadir@1` [D] | story beats 4–5 | **2:259** — the man revived after a hundred years; carries `قَدِيرٌ` | **2:261** the grain parable | clean |
| 75:40 | `al-qadir@1` [D] | verse beat | **75:39** (and 75:31–38 disclosed as a rebuke sequence) | **`verses/by_key/75:41` → HTTP 404 — sūrah-final** | maximal bar 5 |
| 2:255 | `al-qayyum@1` [D] | verse beat (excerpt) | **2:254** ends *"the disbelievers — they are the wrongdoers"*, disclosed | **2:256** *"no compulsion in religion"* | clean |
| 39:42 | `al-qayyum@1` [D] | story beat 5 | **39:41** ends `وَمَآ أَنتَ عَلَيْهِم بِوَكِيلٍ` — `al-wakeel@1`'s Name-noun, off-screen | **39:43** rhetorical question, no punishment | clean |
| 93:6 | `al-waliyy@1` [D] | verse beat | **93:5** clean | **93:7** = `فَهَدَىٰ`, `al-hadi@1`'s Name-verb, off-screen; **93:8** = `فَأَغْنَىٰ`; 93:9–11 instructions; **93:12 → HTTP 404** | **no punishment anywhere in Sūrat aḍ-Ḍuḥā.** 93:1–3 named: it was `al-qayyum@1` R1's rejected story. |
| 11:90 | `al-wadud@1` [S] | verse beat | — | — | unswept |
| 3:172 · 3:173 · 3:174 | `al-wakeel@1` [S] | story; **3:173 is the pinned duʿā source** | — | — | unswept |
| 65:3 | `al-wakeel@1` [S] | verse beat (excerpt) | — | — | ⚠️ **also spent by `ar-razzaq@1` — see §2c** |
| 18:10 | `ar-raheem@1` [D] | **pinned duʿā source** | — | 18:11 is the deck's own next beat | catalogue text is not byte-identical to `text_imlaei`; rasm identical |
| 18:11 · 18:18 | `ar-raheem@1` [D] | story beats 4–5 | — | — | 18:18's omitted remainder is disclosed |
| 18:13 · 18:16 · 18:20 | `ar-raheem@1` [D] | paraphrase only, quoted nowhere | — | — | |
| 18:25 | `ar-raheem@1` [D] | stated as a number, not quoted | — | **18:26** *"Allāh is most knowing of how long they remained"* — disclosed | founder has a one-line option to drop the number |
| 33:43 | `ar-raheem@1` [D] | verse beat (excerpt) | — | 33:44 noted (Abdel Haleem runs on) | the join between 33:43's `بِالْمُؤْمِنِينَ` and the Kahf story is **authored** |
| 2:286 | `ar-rahman@1` [S] | `comfort_verse` beat | — | — | unswept; the verse most users will already have met |
| 7:156 | `ar-rahman@1` [S] | verse beat (**first clause only, by design**) | — | continuation is conditional; deliberately omitted | |
| 55:1 | `ar-rahman@1` [S] | runner-up frame, quoted nowhere | — | — | |
| 65:2 · 65:3 | `ar-razzaq@1` [S] | verse beat (**disclosed composite**) | — | — | unswept; ⚠️ **65:3 is also `al-wakeel@1`'s verse beat** |
| 9:40 | `as-salam@1` [S] | story anchor (Thawr) | — | — | unswept |
| 13:28 | `as-salam@1` [S] | verse beat | — | — | unswept |
| 59:23 | `as-salam@1` [S] | *"Source of Serenity"* rendering | — | — | |
| 19:2 · 19:3 · 19:4 · 19:7 | `as-samad@1` [S] | story beats | — | — | unswept; **Sūrat Maryam also carries `al-haleem@1` at 19:90–91** |
| 112:2 | `as-samad@1` [S] | verse beat | — | — | |
| 21:83 · 21:84 | `ash-shafi@1` [S] | story beats | — | — | unswept; ⚠️ **`al-mujeeb@1` sits at 21:87–88, four āyāt away** |
| 26:80 | `ash-shafi@1` [S] | verse beat | — | — | unswept |
| 2:37 | `at-tawwab@1` [S] | verse beat | — | — | unswept |

### 2b · Ḥadīth

| citation | grading as printed | deck | role | note |
|---|---|---|---|---|
| Ibn Mājah 3850 | ṣaḥīḥ (Darussalam) | `al-afuw@1` [D] | story + **pinned duʿā source** | chosen over Tirmidhī 3513 because the catalogue wording has no `كَرِيمٌ` |
| Tirmidhī 3513 | ḥasan ṣaḥīḥ / ṣaḥīḥ (Darussalam) | `al-afuw@1` [D] | corroborating, quoted nowhere | |
| Bukhārī 3364 | ṣaḥīḥ | `al-baseer@1` [S] | story | |
| Ibn Mājah 188 | ṣaḥīḥ | `al-baseer@1` [S] | 58:1 context | |
| Bukhārī 2731 · 4172 · 4833 | ṣaḥīḥ | `al-fattah@1` [S] | story | |
| Bukhārī 7507 | ṣaḥīḥ | `al-ghaffar@1` [S] | story | |
| Bukhārī 2441 | ṣaḥīḥ | `al-ghafur@1` [D] | story — **rendered from the page's Arabic, not its published English** | clause table in the draft |
| Abū Dāwūd 1516 | ṣaḥīḥ (al-Albānī) | `al-ghafur@1` [D] | **proposed pinned duʿā source** | the page's *English* diverges from the catalogue's; the Arabic does not |
| Tirmidhī 3434 | ṣaḥīḥ (Darussalam) | `al-ghafur@1` [D] | the *other* route, quoted nowhere | its ending is **catalog id 11's** duʿā, not id 51's |
| Bukhārī 7378 | ṣaḥīḥ | `al-haleem@1` [D] | story beats 4–5 | free-standing; **no continuation to be dishonest about** |
| Bukhārī 1145 | ṣaḥīḥ | `al-kareem@1` [D] | story — **rendered from the page's Arabic** | the published English adds *"to us"* and renders `تَعَالَى` *"the Superior"* |
| Bukhārī 4684 | ṣaḥīḥ | `al-kareem@1` [D] | support for beat 8, quoted nowhere | |
| Muslim 918a | ṣaḥīḥ | `al-muid@1` [D] | story | duʿā **not** pinned to it — the catalogue duʿā is not this narration's wording |
| Tirmidhī 3505 | ṣaḥīḥ (Darussalam) | `al-mujeeb@1` [D] | *"inside the fish"* + the withheld promise | promise deliberately kept off the beats |
| Bukhārī 595 | ṣaḥīḥ | `al-qayyum@1` [D] R2 | story | Muslim 680a / 680b / 681 fetched and read; **680b's Shayṭān clause disclosed so nobody "enriches" from it** |
| Muslim 1342 | ṣaḥīḥ | `al-waliyy@1` [D] R2 | **proposed pinned duʿā source** | |
| Tirmidhī 3438 | ḥasan (Darussalam) | `al-waliyy@1` [D] R2 | story beats 4–5 | deliberate, disclosed two-collection split |
| Muslim 2747a · Bukhārī 6309 | ṣaḥīḥ | `al-wadud@1` [S] | story | |
| Bukhārī 4563 | ṣaḥīḥ | `al-wakeel@1` [S] | Ibrāhīm at the fire + the Prophet ﷺ | |
| Bukhārī 5999 | ṣaḥīḥ | `ar-rahman@1` [S] | story | Muslim 2754 parallel verified, unused |
| Tirmidhī 2344 | ḥasan (Darussalam); Tirmidhī: ḥasan ṣaḥīḥ | `ar-razzaq@1` [S] | story | |
| Bukhārī 3653 | ṣaḥīḥ | `as-salam@1` [S] | story | |
| Muslim 591 | ṣaḥīḥ | `as-salam@1` [S] | **pinned duʿā source** | |
| Bukhārī 5743 | ṣaḥīḥ | `ash-shafi@1` [S] | Name + duʿā; pinned as **`cf.`** | wording/clause order differ |
| Bukhārī 3470 | ṣaḥīḥ | `at-tawwab@1` [S] | story | |

**Pinned duʿā sources** (`renderedDuaSources`, `test/content/name_stories_ship_gate_test.dart`,
asserted **bidirectionally**), re-read from the test after the 2026-08-03 transcription — **8 of 24
decks are pinned:** `as-salam@1` → *Sahih Muslim 591* · `al-wakeel@1` → *Qur'an 3:173* ·
`ash-shafi@1` → *cf. Sahih al-Bukhari 5743* · `ar-raheem@1` → *Qur'an 18:10* · `al-ghafur@1` →
*Sunan Abi Dawud 1516* · `al-afuw@1` → *Sunan Ibn Majah 3850* · `al-mujeeb@1` → *Qur'an 21:87* ·
`al-waliyy@1` → *Sahih Muslim 1342*.

**The other 16 decks render NO duʿā citation and must not acquire one** — `al-haleem@1`,
`al-kareem@1`, `al-qayyum@1`, `al-qadir@1` and `al-muid@1` because their duʿā is the catalogue's own
authored invocation, and a pin would assert a provenance the text does not have. **A `source` on
their duʿā beat fails the gate in the other direction.** A future drafter whose Name's duʿā has no
fetchable narration should expect to be unpinned and should say so, not hunt for a citation.

### 2c · Passage-level collisions that already exist

| finding | severity |
|---|---|
| **65:3 is spent twice, by two SHIPPED decks.** `al-wakeel@1`'s verse beat is 65:3 (*"…And whoever puts their trust in Allah, then He ˹alone˺ is sufficient for them."*). `ar-razzaq@1`'s verse beat is a disclosed composite of **65:2–3** (*"…provide for them from sources they could never imagine."*). Different clauses of the same āyah, on a verse beat, in two shipped decks. **This is not named in any prior report.** | already shipped; record and do not repeat |
| **Sūrat al-Anbiyāʾ 21:83–84 (`ash-shafi@1`, shipped) vs 21:87–88 (`al-mujeeb@1`, draft)** — four āyāt apart, shared verb phrase `فَٱسْتَجَبْنَا لَهُۥ` (off-screen). | open founder call: *"one deck per Qurʾānic passage"* would fail `al-mujeeb@1` |
| **Sūrat Yūsuf carries two shipped decks** — `al-jabbar@1` (12:84–96) and `al-lateef@1` (12:100). Handled by an explicit cession: `al-jabbar@1` removed 12:100. | resolved by construction |
| **Sūrat ash-Shūrā:** 42:19 (`al-lateef@1` [S]), 42:25 (`al-afuw@1` [D]). 42:28 was `al-waliyy@1` R1's and **is gone in R2** — the three-decks-in-ten-āyāt crowding is retired. | resolved |
| **Sūrat Fāṭir:** 35:2 (`al-fattah@1` [S]) and 35:45 (`al-haleem@1` [D]). Opposite ends. **35:41 is therefore double-blocked** — sibling roots `حَلِيمًا غَفُورًا` *and* a third deck in one sūrah. | disclosed |
| **Sūrat az-Zumar:** 39:42 (`al-qayyum@1` [D]) and 39:53 (`al-ghaffar@1` [S]), eleven āyāt apart. | disclosed |
| **Sūrat Maryam:** 19:2–7 (`as-samad@1` [S]) and 19:90–91 (`al-haleem@1` [D]), eighty-three āyāt apart. | disclosed |
| **Sūrat al-Baqara now carries five decks** — 2:37, 2:186, 2:255, 2:260, 2:286. | volume, not collision; watch it |
| **Sūrat aḍ-Ḍuḥā:** 93:1–3 was `al-qayyum@1` R1's **rejected** story; 93:6 is now `al-waliyy@1` R2's verse beat. Both decks flag it. **A founder should satisfy himself a rejected sūrah was not simply passed to a neighbouring Name.** | open, flagged in both drafts |

### 2d · Adjacent-spent ground — fetched, evaluated and rejected. Do not re-derive.

**These were swept at real cost. A future drafter that re-proposes one of them is repeating work
that has already been done and lost.**

- **Rejected on bar 5 (arc terminates in punishment inside or just outside the excerpt):**
  40:60 · 11:61 · 42:26 · 2:257 · 46:33/34 · 10:4 · 30:11 (via 30:12) · 85:13 (via 85:14) ·
  13:33 (via 13:34) · 8:33 (via 8:34) · 16:61 (via 16:62) · 7:14–15 (via 7:18) · 79:24 (via 79:25) ·
  29:14 · 20:42–48 · 10:90–92 · 40:46 · 11:74–76 · 75:36 (a **misreading**, not a bar failure).
- **Rejected on bar 3 (sibling Name in or beside the āyah):** 35:41 (`حَلِيمًا غَفُورًا`) ·
  22:59 (via 22:60 `عَفُوٌّ غَفُورٌ`) · 2:225, 2:235, 2:263, 17:44, 64:17 (all pair `ḥalīm` with `gh-f-r`) ·
  22:65 (`رَءُوفٌ رَّحِيمٌ`) · 25:58 (`تَوَكَّلْ`) · 42:9 (`al-qadir@1`'s subject) · 30:25 (two āyāt from `al-muid@1`).
- **Rejected as human speech about Allah:** 7:196 · 12:101 · 10:62.
- **Rejected as trailing/predicate epithet (bar 1):** 3:68 · 3:122 · 3:150 · 4:45 · 5:55 · 6:127 ·
  22:78 · 42:28 · 45:19 · 47:11 · 66:2.
- **Rejected as a negative construction:** 2:107 · 13:11 · 32:4 · 33:17.
- **Rejected for other stated reasons:** 4:149 (*"Competent"*) · 82:6 (a rebuke) · 96:3 (*al-Akram*,
  widens the Name) · 24:22 (human pardon) · 3:2 · 20:111 · 37:139–148 · 21:104 · 27:64 · 29:19 ·
  34:49 (subject is falsehood) · 28:7–13.
- **Held free on purpose — do NOT spend:** **30:50** and **41:39** are reserved for **Al-Muhyi (69)**
  by `al-qadir@1`'s and `al-muid@1`'s authoring notes. **36:81–82** is `al-qadir@1`'s one-line
  alternative. **Bukhārī 4418 / 9:117–118** is `ar-raheem@1`'s unclaimed fallback.
  **Tirmidhī 3524** is **Al-Hayy (15)'s** material.
- **Ḥadīth fetched and rejected:** Bukhārī 6502 (its `walī` is the human; condition-gated;
  doctrinal-confusion risk) · Bukhārī 6099 (parallel of 7378; English breaks badly) ·
  Bukhārī 4950 / 4983 (`al-qayyum@1` R1, dropped with the revision) · Bukhārī 6398 (offered to
  `al-qadir@1`, **declined with a reason**) · Tirmidhī 3540 (`al-ghafur@1`'s fallback) ·
  Bukhārī 6469 · Bukhārī 6025 · Bukhārī 3231 · Muslim 680a/680b/681 · Muslim 2766 (excluded from
  `at-tawwab@1` as unverified).

---

## 3 · Insights / takeaways claimed — beat 8, verbatim

**This is where batch 2's collisions actually lived.** Sorted by deck_id.

| deck | beat-8 line, verbatim | the insight's engine, in three words |
|---|---|---|
| `al-afuw@1` [D] | "Of every request available on the best night of the year, she was taught to ask for the erasing. It is still the sentence." | which request chosen |
| `al-baseer@1` [S] | "Al-Baseer sees what you carry. As-Samad — the second Name of your answer — is the One you can set it down on." | pair-synergy (seen → set down) |
| `al-fattah@1` [S] | "None of the gatekeepers you fear — the interviewer, the landlord, the market — can withhold what He opens. That is what this Name means." | gatekeepers cannot withhold |
| `al-ghaffar@1` [S] | "Al-Ghaffar is the forgiving that does not run out. At-Tawwab — the second Name of your answer — is about the turning back itself." | forgiveness does not exhaust |
| `al-ghafur@1` [D] | "Al-Ghafur is not only the forgiving — it is the covering. In that account every sin is named once, in private, to the One who already knew, and no one else is ever told." | covering, not publishing |
| `al-hadi@1` [S] | "Even the strongest believers ask \"guide us\" in every prayer, every day. Needing guidance was never falling behind — asking for it is the prayer itself." | needing is not failing |
| `al-haleem@1` [D] | "Forbearance is not approval, and it is not forgetting. It is the distance between what a thing has earned and what is actually done about it. Every hour anyone has ever been given was inside that distance." | the un-ended interval |
| `al-jabbar@1` [S] | "Al-Jabbar is the Name for what broke. Ash-Shafi — the second Name of your answer — is the Name for what still hurts." | pair-synergy (broke → hurts) |
| `al-kareem@1` [D] | "You are not drawing on a supply that runs down. The One being asked is Free of need — the asking costs Him nothing at all." | the cost to the Giver |
| `al-lateef@1` [S] | "\"Whether you speak secretly or openly — He surely knows best what is hidden in the heart.\" (Qur'an 67:13) What you couldn't say was never unsaid to Him." | known without words |
| `al-muid@1` [D] | "She asked out loud who could be better than him — and then said the words anyway. The narration keeps both, in that order." | said before believed |
| `al-mujeeb@1` [D] | "He was one man inside one fish. The āyah does not stop with him — its last words are about the believers." | singular → plural rescue |
| `al-qadir@1` [D] | "He already believed. He asked to be shown anyway — and what came back was not a rebuke, it was four birds and a hill." | allowed to ask |
| `al-qayyum@1` [D] | "The gap was in what you were doing, not in what was holding you up. Nothing that keeps you has ever needed a night off." | the gap was yours |
| `al-waliyy@1` [D] | "One half of that sentence is about where you are. The other half is about the people you are not with. And the Prophet ﷺ, who taught it, had been an orphan himself." | present in two places |
| `al-wadud@1` [S] | "That pleasure is what the Prophet ﷺ said repentance is met with. And the way back is not yours to invent — Al-Hadi, the second Name of your answer, is the Guide." | pair-synergy (joy → way back) |
| `al-wakeel@1` [S] | "You were never asked to hold every outcome. Handing them over is not giving up — it is trust, placed with the One who holds them." | handing over is not quitting |
| `ar-raheem@1` [D] | "That sentence was theirs first. They said it going in — and it was being answered the whole time they were unconscious of it, one turn at a time, for three centuries." | answered while unaware |
| `ar-rahman@1` [S] | "A mercy that wide is where you begin. Al-Lateef — the next Name of your journey — is the kindness working in the details you can't see yet." | pair-synergy (wide → detailed) |
| `ar-razzaq@1` [S] | "Ar-Razzaq is about what reaches you. Al-Fattah — the second Name of your answer — is about the doors it comes through." | pair-synergy (what → how) |
| `as-salam@1` [S] | "As-Salam — peace itself — is the Name for what is inside you. Al-Wakeel, the second Name of your answer, is the One you trust with what is outside your hands." | pair-synergy (inside → outside) |
| `as-samad@1` [S] | "\"Needed by all\" means everyone leans here — the strongest people you know included. Leaning is not weakness; it is the meaning of the Name." | leaning is not weakness |
| `ash-shafi@1` [S] | "The answer to Ayyub was not repair. It was more than there was before the breaking." | more than before |
| `at-tawwab@1` [S] | "In every one of these stories, the acceptance met the person mid-road. The turning is enough to begin." | met mid-road |

### 3a · Insight engines already spent — a new deck must not land on one of these

`answered while unaware` · `known without words` · `visible only in retrospect` ·
`the incomplete version counts` · `needing it is not failing` · `leaning is not weakness` ·
`more than there was before` · `what was chosen to be asked for` · `the supply does not run down` ·
`the gatekeepers cannot withhold` · `covering rather than publishing` · `the un-ended interval` ·
`allowed to ask` · `said before believed` · `the gap was on your side` · `singular becomes plural` ·
`present in two places at once` · `handing over is not quitting`.

**Known live adjacencies, disclosed and not closed** (a founder may still collapse any of these):

| pair | why they are adjacent |
|---|---|
| `ar-raheem@1` beat 8 ↔ `al-lateef@1` beat 5 (shipped) | *care operating unseen throughout, recognised only in retrospect.* Kept deliberately; one-line fix recorded in the draft. |
| `al-qayyum@1` beat 8 ↔ `ar-raheem@1` beat 8 | both could land on *"it was working the whole time"*; `al-qayyum@1` steers to *where the discontinuity was*. |
| `al-qadir@1` beat 8 ↔ `al-hadi@1` beat 8 (shipped) | both make *"the thing you're ashamed of needing is a thing believers do."* `al-qadir@1` ends on an image, not a maxim. |
| `al-muid@1` beat 8 ↔ `at-tawwab@1` beat 8 (shipped) | both say *the incomplete version counts.* |
| `al-muid@1` ↔ `ash-shafi@1` (shipped) | *replacement with better* is `ash-shafi@1`'s takeaway in one line. |
| `al-qayyum@1` beat 8 ↔ `al-ghaffar@1` beat 8 (shipped) | both use a *does-not-run-out / does-not-pause* shape, in a now-shared sūrah. |
| `al-mujeeb@1` ↔ `as-samad@1` (shipped) | *a call and its answer* — the uniqueness claim was **withdrawn** in R2. |

---

## 4 · Rendered English at risk

**This section is what catches the class the Arabic-root sweep cannot see.**

### 4a · `name_intro` primaries — every Name-gloss already on a screen

| deck | `name_intro` primary, verbatim | provenance |
|---|---|---|
| `al-afuw@1` [D] | The Pardoner | catalogue id 86 |
| `al-baseer@1` [S] | The All-Seeing | catalogue id 46 |
| `al-fattah@1` [S] | The Opener | catalogue id 23 |
| `al-ghaffar@1` [S] | The Ever-Forgiving | catalogue id 11 |
| `al-ghafur@1` [D] | The Forgiving | catalogue id 51 |
| `al-hadi@1` [S] | The Guide | catalogue id 33 |
| `al-haleem@1` [D] | The Forbearing | catalogue id 29 |
| `al-jabbar@1` [S] | **The Compeller — Restorer of the Broken** | catalogue id 9 |
| `al-kareem@1` [D] | The Most Generous | catalogue id 30 |
| `al-lateef@1` [S] | The Subtle | catalogue id 36 |
| `al-muid@1` [D] | **The Restorer — the One who brings back what is finished** | catalogue id 68 `english` + authored gloss |
| `al-mujeeb@1` [D] | The Responsive | catalogue id 37 |
| `al-qadir@1` [D] | The Capable | catalogue id 75 |
| `al-qayyum@1` [D] | The Self-Sustaining | catalogue id 16 |
| `al-waliyy@1` [D] | The Protecting Friend | catalogue id 64 |
| `al-wadud@1` [S] | The Most Loving | catalogue id 27 |
| `al-wakeel@1` [S] | The Trustee — the Guardian you hand your affairs to | catalogue id 35 + authored gloss (the precedent) |
| `ar-raheem@1` [D] | The Most Merciful | catalogue id 3 |
| `ar-rahman@1` [S] | The Most Gracious | catalogue id 2 |
| `ar-razzaq@1` [S] | The Provider | catalogue id 13 |
| `as-salam@1` [S] | The Source of Serenity | catalogue id 6 |
| `as-samad@1` [S] | **The Eternal Refuge** | catalogue id 34 |
| `ash-shafi@1` [S] | The Healer | catalogue id 38 |
| `at-tawwab@1` [S] | The Acceptor of Repentance | catalogue id 31 |

### 4b · Distinctive rendered phrases spent — diff against this list before writing a beat

| phrase, verbatim | deck | beat | why it is at risk |
|---|---|---|---|
| "Restorer" | `al-jabbar@1` [S] `name_intro`; `al-muid@1` [D] `name_intro` | 2 | **UNRESOLVED.** Both strings are the catalogue's `english`. A deck cannot remove it. Founder call: change id 9 or id 68, or never make the two adjacent. |
| "He demanded nothing." | `ash-shafi@1` [S] | story 4 | the string `al-mujeeb@1` R1 collided with. *"asked for nothing"* now returns **zero** hits anywhere. |
| "refuge" | `as-samad@1` [S] `name_intro` + duʿā ("The Eternal Refuge"); `al-waliyy@1` [D] verse beat ("give [you] refuge") | 2, 6, 7 | **OPEN.** Abdel Haleem's 93:6 (*"shelter you"*) is fetched and ready; one line either way. |
| "do not lose hope in the mercy of Allah" | `al-ghaffar@1` [S] verse beat (39:53); `al-jabbar@1` [S] verse beat (12:87) | 6 | ⚠️ **NEW FINDING, not in any prior report.** Two SHIPPED decks render the same English clause on a verse beat, from two different āyāt. |
| "Allah is more … than [a human] to …" | `al-wadud@1` [S] story 5 (*"more pleased … than that man was with his camel"*); `ar-rahman@1` [S] story 7 (*"more merciful to His slaves than this lady to her son"*) | 5, 7 | ⚠️ **NEW FINDING.** Same rendered construction in two shipped decks. |
| "forgive me and accept my repentance" | `al-ghaffar@1` [S] duʿā; `at-tawwab@1` [S] duʿā; `al-ghafur@1` [D] duʿā | 7 | ⚠️ **NEW FINDING.** Three decks' duʿā English are near-identical (catalogue ids 11 / 31 / 51 differ by one word each). See §6d. |
| "the Acceptor of Repentance" | `at-tawwab@1` [S] `name_intro`; `al-ghaffar@1` [S] duʿā translation | 2, 7 | a shipped Name-gloss already renders inside another shipped deck's duʿā. |
| "For the weight you named…" / "the second Name of your answer" | 4 and 6 shipped decks respectively | 1, 8 | **template, not collision.** Deliberate chip-pair scaffolding. Do not "fix" it; do not reuse it outside a chip pair. |
| "Sight restored. Son restored. Whole again." | `al-jabbar@1` [S] | story 5 | the restoration payoff — `al-muid@1` steers off it explicitly |
| "visible only from the far side" | `al-lateef@1` [S] | story 5 | the retrospect payoff |
| "four birds" / "He was not corrected" / "Allah said:" | `al-qadir@1` [D] | 4, 5 | zero hits elsewhere as of 2026-08-03 |
| "one fish" / "does not stop with him" / "last words are about the believers" | `al-mujeeb@1` [D] | 5, 8 | zero hits elsewhere |
| "captured your souls" / "releases the others" / "during their sleep" / "night off" / "holding you up" / "Bilal" | `al-qayyum@1` [D] | 3, 4, 5, 8 | zero hits elsewhere |
| "companion on the journey" / "caretaker for the family" / "great sadness" / "orphan" | `al-waliyy@1` [D] | 3, 4, 5, 6, 8 | zero hits elsewhere |
| "brings back what is finished" / "We belong to Allah" / "said the words anyway" / "in exchange for it" | `al-muid@1` [D] | 2, 3, 5, 8 | zero hits elsewhere |
| "the covering" / "named once, in private" / "no one else is ever told" | `al-ghafur@1` [D] | 8 | rewritten in R3 off `al-lateef@1`'s *"couldn't say it out loud"* axis |
| "three hundred years, and nine" / "one turn at a time" | `ar-raheem@1` [D] | 5, 8 | |
| "the distance between what a thing has earned and what is actually done about it" | `al-haleem@1` [D] | 8 | |
| "a supply that runs down" / "Free of need" | `al-kareem@1` [D] | 8 | |

### 4c · Rendered-English risk carried by the catalogue itself

Because `dua` beats render the catalogue's `dua_translation` byte-identically, a Name whose duʿā
English contains **another Name's gloss** puts that Name on screen under the wrong card.
Computed over all 99:

| id | Name | its `dua_translation` contains | that Name |
|---|---|---|---|
| 15 | Al-Hayy | "Self-Sustaining" | 16 Al-Qayyum `[D]` |
| 19 | Al-Mutakabbir | "Compeller-Healer, mend my brokenness" | 9 Al-Jabbar **[S]** *and* 38 Ash-Shafi **[S]** — and *"mend my brokenness"* is `al-jabbar@1`'s duʿā English **verbatim** |
| 22 | Al-Qahhar | (identical to 19) | as above |
| 45 | As-Sami | "close and responsive" | 37 Al-Mujeeb `[D]` |
| 60 | Ash-Shaheed | "O All-Seeing, You see what no one else sees…" (19 words identical) | 46 Al-Baseer **[S]** |
| 99 | Ar-Rasheed | "O Guide to the Right Path" | 33 Al-Hadi **[S]** |
| 26, 49 | Al-Hakeem, Al-Khabeer | "O Gentle One, be gentle with me in all…" (7-word run) | 36 Al-Lateef **[S]** |
| 87 | Ar-Rauf | "…One, be gentle with me…" (5-word run) | 36 Al-Lateef **[S]** |
| 71 | Al-Wajid | "and do not leave me to myself" (7-word run) | 16 Al-Qayyum `[D]` |
| 12 | Al-Wahhab | "grant us mercy from Yourself" (5-word run) | 3 Ar-Raheem `[D]` |

---

## 5 · Arabic roots spent, per deck

For the sibling-Name check (bar 3). **`ʿ-f-w`, `gh-f-r`, `r-ḥ-m` are dense and overlap constantly.**
Sorted by deck_id.

| deck | Name root | roots carried in its quoted source text | roots explicitly EXCLUDED by construction |
|---|---|---|---|
| `al-afuw@1` [D] | `ʿ-f-w` | `ʿ-f-w` (42:25 `وَيَعْفُوا۟` — a finite verb of Allah's action, **bar 1's strongest form**), `t-w-b` (42:25), `q-d-r` (97:3 `الْقَدْر`) | — |
| `al-baseer@1` [S] | `b-ṣ-r` | `b-ṣ-r`, `s-m-ʿ` (58:1) | — |
| `al-fattah@1` [S] | `f-t-ḥ` | `f-t-ḥ` (48:1, 35:2) | — |
| `al-ghaffar@1` [S] | `gh-f-r` | `gh-f-r` (39:53), `r-ḥ-m` (39:53), `t-w-b` (duʿā) | — |
| `al-ghafur@1` [D] | `gh-f-r` | `gh-f-r` (4:110, Bukhārī 2441 `أَغْفِرُهَا`), `s-t-r` (the deck's actual engine), `r-ḥ-m` (4:110), `t-w-b` (duʿā) | — |
| `al-hadi@1` [S] | `h-d-y` | `h-d-y` (28:22, 22:54, 1:6) | — |
| `al-haleem@1` [D] | `ḥ-l-m` | **none of the Name's own root anywhere.** `ṣ-b-r` (`أَصْبَرُ`), `ʿ-f-y` (`يُعَافِيهِمْ` — *health*, disclosed as a lexical relative of `ʿafw`), `r-z-q`, `ʾ-kh-r` (`يُؤَخِّرُهُمْ`), `b-ṣ-r` (35:45 `بَصِيرًا`) | **`gh-f-r` and `ʿ-f-w` appear nowhere in the deck, in Arabic or English** — closed by construction after two rejections |
| `al-jabbar@1` [S] | `j-b-r` | `j-b-r` (duʿā only), `r-ḥ-m` (12:87) | — |
| `al-kareem@1` [D] | `k-r-m` | **no `k-r-m` in the story.** `n-z-l`, `d-ʿ-w`, `gh-f-r` (Bukhārī 1145 `يَسْتَغْفِرُنِي`/`فَأَغْفِرَ` — **rendered in English on beat 5**), `k-r-m` + `gh-n-y` (27:40) | — |
| `al-lateef@1` [S] | `l-ṭ-f` | `l-ṭ-f` (12:100, 42:19) | — |
| `al-muid@1` [D] | `ʿ-w-d` | `ʿ-w-d` (30:27 `يُعِيدُهُۥ`), `kh-l-f` (Muslim 918a `أَخْلَفَ` — **a different root, stated**), `b-d-ʾ` (30:27) | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `j-b-r` all absent from every beat |
| `al-mujeeb@1` [D] | `j-w-b` | `j-w-b` (21:88 `فَٱسْتَجَبْنَا`, 2:186 `أُجِيبُ`, Tirmidhī 3505), `n-j-w` (21:88), `q-d-r` (21:87 `نَّقْدِرَ` — **`al-qadir@1`'s root, negated, off-screen**), `ẓ-l-m` (21:87) | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w` absent from every beat |
| `al-qadir@1` [D] | `q-d-r` | `q-d-r` (75:40 `بِقَـٰدِرٍ` — **rendered "Able", not "Capable"**), `ḥ-y-y` (2:260 `تُحْىِ`, 75:40 `يُحْـِۧىَ` — **Al-Muhyi's root, twice**), `ṭ-y-r` | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`, `f-t-ḥ` absent |
| `al-qayyum@1` [D] | `q-w-m` | `q-w-m` (2:255 `ٱلْقَيُّومُ` — **verse beat only**), `ḥ-y-y` (2:255 `ٱلْحَىُّ` = **Al-Hayy, id 15, on screen in Arabic**), `q-b-ḍ`, `t-w-f-y`, `m-s-k`, `r-s-l`, `n-w-m`; off-screen `w-k-l` (39:41), `ʿ-l-w` + `ʿ-ẓ-m` (2:255 tail) | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m` absent |
| `al-waliyy@1` [D] | `w-l-y` | **none of the Name's own root anywhere — bar 4 traded deliberately.** `ʾ-w-y` (93:6 `فَـَٔاوَىٰ`), `y-t-m`, `ṣ-ḥ-b`, `kh-l-f`; off-screen `h-d-y` (93:7 `فَهَدَىٰ`), `gh-n-y` (93:8) | `w-k-l`, `ṣ-m-d`, `r-ḥ-m`, `gh-f-r` absent |
| `al-wadud@1` [S] | `w-d-d` | `w-d-d` (11:90), `r-ḥ-m` (11:90), `t-w-b` (Muslim 2747a), `ḥ-b-b` (duʿā) | — |
| `al-wakeel@1` [S] | `w-k-l` | `w-k-l` (3:173, 65:3, duʿā) | — |
| `ar-raheem@1` [D] | `r-ḥ-m` | `r-ḥ-m` (33:43 `رَحِيمًا`, 18:10 `رَحْمَةً`) — **but the Name-noun is absent from the story passage**; `q-l-b` (18:18 `وَنُقَلِّبُهُمْ`), `r-sh-d` (18:10) | — |
| `ar-rahman@1` [S] | `r-ḥ-m` | `r-ḥ-m` (7:156, duʿā, Bukhārī 5999) | — |
| `ar-razzaq@1` [S] | `r-z-q` | `r-z-q` (65:3, Tirmidhī 2344), `w-q-y` (65:2) | — |
| `as-salam@1` [S] | `s-l-m` | `s-l-m` (duʿā), `s-k-n` (9:40 `سَكِينَتَهُ`), `dh-k-r` (13:28) | — |
| `as-samad@1` [S] | `ṣ-m-d` | `ṣ-m-d` (112:2, duʿā), `d-ʿ-w` (19:3) | — |
| `ash-shafi@1` [S] | `sh-f-y` | `sh-f-y` (26:80, duʿā), `r-ḥ-m` (21:83–84 `أَرْحَمُ ٱلرَّٰحِمِينَ` — **Ar-Raheem's own hook, already on a shipped screen**), `j-w-b` (21:84 `فَٱسْتَجَبْنَا`), `ḍ-r-r` (21:83) | — |
| `at-tawwab@1` [S] | `t-w-b` | `t-w-b` (2:37, duʿā), `r-ḥ-m` (2:37, duʿā) | — |

### 5a · Roots now dense enough to be a standing hazard

`r-ḥ-m` (5 decks) · `gh-f-r` (4 decks incl. `al-kareem@1`'s ḥadīth) · `t-w-b` (5 decks) ·
`ʿ-f-w` (2) · `ḥ-y-y` (3 — **and Al-Muhyi (69) and Al-Hayy (15) both still need decks**) ·
`q-d-r` (2) · `w-l-y` (`al-waliyy@1` [D] **and Al-Wali (83) still to come**) ·
`j-w-b` (`al-mujeeb@1` [D] **and As-Sami (45)'s duʿā is 11:61 `قَرِيبٌ مُجِيبٌ`**).

---

## 6 · `dua_arabic` collision table — all 99 Names

**Computed programmatically from `assets/content/collectible_names.json` on 2026-08-03.
Nothing in this section was eyeballed.** Method: exact string match on `dua_arabic`; a
skeleton-normalised re-run (all combining marks and orthographic variants folded) produced the
**same 14 groups and the same 30 Names**, so there are no additional near-identical groups hiding
behind diacritics.

**Why this is the binding constraint and not an annoyance:** the ship gate asserts `dua` beats
**byte-identical to the catalogue by `name_id`** (`test/content/name_stories_ship_gate_test.dart`).
Two Names in one group therefore produce **two decks with a pixel-identical duʿā screen — Arabic,
transliteration and translation.** `dua` beats are one of only two beat kinds that render Arabic.

### 6a · The 14 duplicate `dua_arabic` groups — 30 Names

| # | Name ids | Names | already decked | shared `dua_arabic` |
|---|---|---|---|---|
| 1 | 19, 22 | Al-Mutakabbir · Al-Qahhar | — | `يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي` |
| 2 | 24, 25 | Al-Qabid · Al-Basit | — | `يَا قَابِضُ يَا بَاسِطُ ابْسُطْ عَلَيْنَا مِنْ رَحْمَتِكَ` |
| 3 | 26, 49 | Al-Hakeem · Al-Khabeer | — | `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا` |
| 4 | 29, 32 | Al-Haleem · As-Sabur | **`al-haleem@1` [D]** | `اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ` |
| 5 | 43, 44 | Al-Muizz · Al-Muzill | — | `اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ` |
| 6 | 46, 60 | Al-Baseer · Ash-Shaheed | **`al-baseer@1` [S] — SHIPPED** | `يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ` |
| 7 | 47, 48, 55, 90 | Al-Hakam · Al-Adl · Al-Haseeb · Al-Muqsit | — | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` |
| 8 | 50, 58 | Al-Azeem · Al-Majeed | — | `سُبْحَانَ رَبِّيَ الْعَظِيمِ` |
| 9 | 52, 84 | Al-Ali · Al-Mutaali | — | `يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ` |
| 10 | 62, 63 | Al-Qawiyy · Al-Mateen | — | `لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ` |
| 11 | 73, 74 | Al-Wahid · Al-Ahad | — | `يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ` |
| 12 | 77, 78 | Al-Muqaddim · Al-Muakhkhir | — | `اللَّهُمَّ اجْعَلْنِي رَاضِيًا بِمَا قَسَمْتَ لِي وَبَارِكْ لِي فِيهِ` |
| 13 | 79, 80 | Al-Awwal · Al-Akhir | — | `اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ` |
| 14 | 81, 82 | Az-Zahir · Al-Batin | — | `أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ` |

**Groups: 14. Names spanned: 30.** Two of the 24 decked Names are already inside a group:
**Al-Baseer (46) is SHIPPED** and permanently spends group 6's duʿā screen against Ash-Shaheed (60);
**Al-Haleem (29) is a pending draft** and does the same to As-Sabur (32).

### 6b · The worse class — a duʿā that invokes a *different* Name in the vocative

`dua` beats render Arabic. **`يَا <another Name>` therefore appears on screen inside a deck for the
wrong Name.**

| id | Name | the vocative in its own `dua_arabic` | the Name it invokes | that Name's status |
|---|---|---|---|---|
| 15 | Al-Hayy | `يَا قَيُّومُ` | 16 Al-Qayyum | draft `al-qayyum@1` |
| 16 | Al-Qayyum | `يَا حَيُّ` | 15 Al-Hayy | not decked |
| 19 | Al-Mutakabbir | `يَا قَهَّارُ` | 22 Al-Qahhar | not decked |
| 24 | Al-Qabid | `يَا بَاسِطُ` | 25 Al-Basit | not decked |
| 25 | Al-Basit | `يَا قَابِضُ` | 24 Al-Qabid | not decked |
| 26 | Al-Hakeem | `يَا لَطِيفُ` | 36 Al-Lateef | **SHIPPED** |
| 49 | Al-Khabeer | `يَا لَطِيفُ` | 36 Al-Lateef | **SHIPPED** |
| 60 | Ash-Shaheed | `يَا بَصِيرُ` | 46 Al-Baseer | **SHIPPED** |
| 73 | Al-Wahid | `يَا أَحَدُ` | 74 Al-Ahad | not decked |
| 74 | Al-Ahad | `يَا وَاحِدُ` | 73 Al-Wahid | not decked |
| 84 | Al-Mutaali | `يَا عَلِيُّ` | 52 Al-Ali | not decked |

**⚠️ CORRECTION TO A PRIOR REPORT, re-confirmed here.** The batch-2 packet reported ids 26 and 49
as byte-identical to **Al-Lateef (36)**. **They are not.** 26 and 49 are byte-identical **to each
other** (`اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا`); id 36's string is different
(`يَا لَطِيفُ الْطُفْ بِي فِيمَا جَرَتْ بِهِ الْمَقَادِيرُ`). The batch-2 **fix report** already
corrected this, and this pass reproduces the correction. **What the fix report did not add, and
this pass computes: 26/49 and 36 nonetheless share a 4-word opening run — `يَا لَطِيفُ الْطُفْ بِي`
— which renders on both duʿā screens.** So the defect is real on two axes at once: the foreign
vocative *and* a shared rendered phrase.

### 6c · One Name's *entire* duʿā embedded inside another's

| container | container Name | contains the whole duʿā of | status of the contained Name |
|---|---|---|---|
| 16 | Al-Qayyum | 15 Al-Hayy (as an exact prefix) | not decked |
| 19 | Al-Mutakabbir | 9 Al-Jabbar | **SHIPPED** |
| 22 | Al-Qahhar | 9 Al-Jabbar | **SHIPPED** |
| 88 | Malik-ul-Mulk | 4 Al-Malik | not decked |

### 6d · Additional duʿā collisions this pass found that no prior report names

1. **Ids 11 / 31 / 51 are a three-way near-duplicate, and two of the three are SHIPPED.**
   - id 11 Al-Ghaffar **[S]**: `رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الْغَفُورُ`
   - id 31 At-Tawwab **[S]**: `اللَّهُمَّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ`
   - id 51 Al-Ghafur **[D]**: `رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ`

   Computed: 11↔51 share an **8-word run**, 31↔51 share an **8-word run**, 11↔31 share a **7-word
   run**. Their English is 0.80-similar. The `al-ghafur@1` draft flags the 31↔51 pair; **the
   three-way relation and the exact run lengths are computed here for the first time.**
   Two decks already ship this sentence; a third would make it the pack's most-repeated screen.
2. **Id 89 (Dhul-Jalali wal-Ikram) is pre-spent by a SHIPPED deck.** Its whole vocative
   `يَا ذَا الْجَلَالِ وَالْإِكْرَامِ` — **which is the Name itself** — is the closing four words of
   **shipped `as-salam@1`'s duʿā beat**, rendered in Arabic. A future Dhul-Jalali deck's duʿā screen
   opens on a phrase already on a shipped duʿā screen. **Not in any prior report.**
3. **Id 71 (Al-Wajid) shares a 4-word Arabic run and a 7-word English run with `al-qayyum@1` [D]**
   — `وَلَا تَكِلْنِي إِلَى نَفْسِي` / *"and do not leave me to myself"* — which is the closing
   clause `al-qayyum@1`'s draft calls *"the story's request in the user's mouth."*
4. **Id 87 (Ar-Rauf) shares `الْطُفْ بِي` with shipped `al-lateef@1`'s duʿā** and a 5-word English
   run (*"…One, be gentle with me…"*).
5. **Id 92 (Al-Ghaniyy)'s duʿā is a 3-word Arabic run of shipped `ar-razzaq@1`'s**
   (`بِفَضْلِكَ عَمَّنْ سِوَاكَ`).
6. **Id 12 (Al-Wahhab) shares a 5-word English run with `ar-raheem@1` [D]** —
   *"grant us mercy from Yourself"* — and both duʿās carry `مِن لَّدُنكَ رَحْمَةً`.

### 6e · **Which Names cannot get a bar-3-clean deck while the catalogue stands**

This is stated explicitly because it is a **founder decision later**, and drafting agents must
avoid these Names for now.

**All 30 Names inside a duplicate group** (§6a) — because the ship gate forces the duʿā screen to
be pixel-identical to its group partner's:

> **15, 19, 22, 24, 25, 26, 29\*, 32, 43, 44, 46\*, 47, 48, 49, 50, 52, 55, 58, 60, 62, 63, 73, 74,
> 77, 78, 79, 80, 81, 82, 84, 88, 90**

*(\* 29 and 46 are already decked. 46 Al-Baseer is **shipped**, so its half of group 6 is spent and
unrecoverable; 60 Ash-Shaheed cannot be clean without a catalogue edit. 29 Al-Haleem is a pending
draft, so As-Sabur (32) is in the same position but the founder can still choose which of the two
keeps the string. 15 and 88 are blocked by §6b/§6c rather than by §6a.)*

**Of those, the eight where the collision is with a Name that is ALREADY SHIPPED — i.e. already
irreversible without changing shipped rendered content:**

> **19** and **22** (both embed Al-Jabbar's entire duʿā, and their English says *"Compeller-Healer,
> mend my brokenness"* — colliding with **two** shipped decks at once) · **26** and **49**
> (`يَا لَطِيفُ`, Al-Lateef shipped) · **60** (`يَا بَصِيرُ`, Al-Baseer shipped, plus 19 identical
> English words) · **89** (its Name-phrase already renders on shipped `as-salam@1`'s duʿā) ·
> **45** and **99** (their duʿā English contains a shipped Name's gloss — Al-Mujeeb is only a draft
> for 45, but Al-Hadi is shipped for 99).

**And the 45 remaining Names that are clear on the duʿā axis are listed in §7.**

**What all-99 therefore requires, and it is not a drafting task:** a **duʿā de-duplication pass over
`collectible_names.json`** — sourcing or authoring distinct invocations for one member of each
duplicate group and removing foreign-Name vocatives. **~30 Names, roughly a third of the
catalogue.** It is outside the deck pipeline's scope, it must **precede** the affected decks, and
until it happens those decks cannot be drafted honestly. Note also that the concurrent
catalogue-repair track touched only the **`hadith`** column; **`dua_arabic` is entirely
unaddressed.**

---

## 7 · Remaining-Names worklist — all 75

**This is the work queue.** Future waves are assigned from it. Sorted by catalogue `id`.

**Column meanings.**
- `duʿā dup group` — other ids sharing this exact `dua_arabic` (§6a).
- `foreign Name inside its duʿā (Arabic)` — §6b/§6c. `[SHIPPED]` means the collision is already
  irreversible without changing shipped content.
- `≥3-word Arabic run` / `≥4-word English run` — computed overlap with a **decked** Name's duʿā,
  generic openers (`اللهم اني اسالك`, *"O Allah I ask You"*, *"You are the"*, …) filtered out.
  **A hit here means the duʿā screen will partly repeat a screen the user has already seen.**
- `card hadith` — whether `collectible_names.json`'s `hadith` field is populated. `**EMPTY**` after
  the 2026-08-03 catalogue-repair pass means the Name card is silent, which is *neutral-to-good*
  for a deck but means there is no card-level corroboration to lean on.
- `english gloss overlap` — the class that produced the *Restorer* collision.
- `duʿā-axis verdict` — `BLOCKED` = cannot ship a bar-3-clean deck until the catalogue moves.

**Narration status of each duʿā is deliberately NOT a column.** It is **unverified for all 75** —
no repo artifact records it, and asserting it without a live fetch is exactly the failure mode this
ledger exists to prevent. The only duʿā provenance this project has verified is for decked Names
(§2b's pin list) plus **id 15 / id 16** (the Anas b. Mālik → Fāṭima narration, verified in
`al-qayyum@1` R2 through secondary Arabic scholarship, **not** a primary collection, and therefore
still unpinnable). **Every drafter must fetch their own.**

| id | Name | catalogue `english` | `dua_arabic` | duʿā dup group | foreign Name inside its duʿā (Arabic) | ≥3-word Arabic run shared with a decked duʿā | ≥4-word English run shared with a decked duʿā | card `hadith` | `english` gloss overlap | duʿā-axis verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Allah | God | `اللَّهُمَّ إِنِّي أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ` | — | — | — | — | present | — | clear |
| 4 | Al-Malik | The King | `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ` | — | — | — | — | present | — | clear |
| 5 | Al-Quddus | The Most Holy | `سُبُّوحٌ قُدُّوسٌ رَبُّ الْمَلَائِكَةِ وَالرُّوحِ` | — | — | — | — | present | — | clear |
| 7 | Al-Mumin | The Guardian of Faith | `اللَّهُمَّ ثَبِّتْنَا عَلَى الْإِيمَانِ` | — | — | — | — | present | — | clear |
| 8 | Al-Azeez | The Almighty | `يَا عَزِيزُ أَعِزَّنِي بِطَاعَتِكَ` | — | — | — | — | present | — | clear |
| 10 | Al-Khaliq | The Creator | `رَبَّنَا مَا خَلَقْتَ هَذَا بَاطِلًا سُبْحَانَكَ` | — | — | — | — | present | — | clear |
| 12 | Al-Wahhab | The Bestower | `رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً` | — | — | ar-raheem@1 3w | ar-raheem@1 5w "grant us mercy from yourself" | present | 43 Al-Muizz | clear |
| 14 | Al-Aleem | The All-Knowing | `اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ` | — | — | — | — | present | — | clear |
| 15 | Al-Hayy | The Ever-Living | `يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ` | — | `يَا` + Al-Qayyum (16)[draft] | al-qayyum@1 6w | al-qayyum@1 6w "o ever living o self sustaining" | **EMPTY** | 11 Al-Ghaffar | **BLOCKED** |
| 17 | An-Nur | The Light | `اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي لِسَانِي نُورًا وَاجْعَلْنِي نُورًا` | — | — | — | — | present | — | clear |
| 18 | Al-Muhaymin | The Overseer | `يَا مُهَيْمِنُ احْرُسْنِي بِعَيْنِكَ الَّتِي لَا تَنَامُ` | — | — | — | — | present | — | clear |
| 19 | Al-Mutakabbir | The Supreme | `يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي` | 22 | `يَا` + Al-Qahhar (22) · embeds all of 9 Al-Jabbar**[SHIPPED]** | al-jabbar@1 3w | — | present | — | **BLOCKED** |
| 20 | Al-Bari | The Evolver | `يَا بَارِئُ أَصْلِحْ مَا أَفْسَدْتُهُ فِي نَفْسِي وَاجْعَلْنِي كَامِلًا بِدِقَّةِ صُنْعِكَ` | — | — | — | — | **EMPTY** | — | clear |
| 21 | Al-Musawwir | The Fashioner | `يَا مُصَوِّرُ جَمِّلْ أَخْلَاقِي كَمَا جَمَّلْتَ خَلْقِي` | — | — | — | — | present | — | clear |
| 22 | Al-Qahhar | The Subduer | `يَا قَهَّارُ اقْهَرْ كُلَّ جَبَّارٍ عَنِيدٍ وَيَا جَبَّارُ اجْبُرْ كَسْرِي` | 19 | embeds all of 9 Al-Jabbar**[SHIPPED]** | al-jabbar@1 3w | — | present | — | **BLOCKED** |
| 24 | Al-Qabid | The Withholder | `يَا قَابِضُ يَا بَاسِطُ ابْسُطْ عَلَيْنَا مِنْ رَحْمَتِكَ` | 25 | `يَا` + Al-Basit (25) | — | — | present | 94 Al-Mani | **BLOCKED** |
| 25 | Al-Basit | The Expander | `يَا قَابِضُ يَا بَاسِطُ ابْسُطْ عَلَيْنَا مِنْ رَحْمَتِكَ` | 24 | `يَا` + Al-Qabid (24) | — | — | present | — | **BLOCKED** |
| 26 | Al-Hakeem | The All-Wise | `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا` | 49 | `يَا` + Al-Lateef (36)**[SHIPPED]** | al-lateef@1 4w | al-lateef@1 7w "one be gentle with me in all" | present | — | **BLOCKED** |
| 28 | Ash-Shakur | The Most Appreciative | `يَا شَكُورُ اشْكُرْ لِي سَعْيِي وَلَا تَخْذُلْنِي` | — | — | — | — | present | — | clear |
| 32 | As-Sabur | The Patient | `اللَّهُمَّ إِنِّي أَسْأَلُكَ الصَّبْرَ وَأَعُوذُ بِكَ مِنَ الْجَزَعِ` | 29 | — | al-haleem@1 8w | al-haleem@1 17w "o allah i ask you for patience and i seek refuge in you from anxiety and distress" | present | — | **BLOCKED** |
| 39 | Al-Hafeez | The Preserver | `يَا حَفِيظُ احْفَظْنِي وَاحْفَظْ لِي مَنْ أُحِبُّ` | — | — | — | — | present | — | clear |
| 40 | Ar-Raqeeb | The Watchful | `يَا رَقِيبُ احْفَظْنِي فِي سِرِّي وَعَلَانِيَتِي` | — | — | — | — | present | — | clear |
| 41 | Al-Khafid | The Abaser | `يَا خَافِضُ اخْفِضْ كِبْرِيَائِي وَارْفَعْ قَدْرِي عِنْدَكَ` | — | — | — | — | present | — | clear |
| 42 | Ar-Rafi | The Exalter | `يَا رَافِعُ ارْفَعْ دَرَجَتِي عِنْدَكَ وَاجْعَلْ لِي مَكَانَةً فِي الدُّنْيَا وَالْآخِرَةِ` | — | — | — | — | present | — | clear |
| 43 | Al-Muizz | The Bestower of Honor | `اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ` | 44 | — | — | — | **EMPTY** | 12 Al-Wahhab | **BLOCKED** |
| 44 | Al-Muzill | The Humiliator | `اللَّهُمَّ أَعِزَّنِي بِطَاعَتِكَ وَلَا تُذِلَّنِي بِمَعْصِيَتِكَ` | 43 | — | — | — | **EMPTY** | — | **BLOCKED** |
| 45 | As-Sami | The All-Hearing | `إِنَّ رَبِّي قَرِيبٌ مُجِيبٌ` | — | — | — | — | present | — | clear |
| 47 | Al-Hakam | The Judge | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` | 48, 55, 90 | — | — | — | present | — | **BLOCKED** |
| 48 | Al-Adl | The Just | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` | 47, 55, 90 | — | — | — | present | — | **BLOCKED** |
| 49 | Al-Khabeer | The All-Aware | `اللَّهُمَّ يَا لَطِيفُ الْطُفْ بِي فِي أُمُورِي كُلِّهَا` | 26 | `يَا` + Al-Lateef (36)**[SHIPPED]** | al-lateef@1 4w | al-lateef@1 7w "one be gentle with me in all" | present | — | **BLOCKED** |
| 50 | Al-Azeem | The Magnificent | `سُبْحَانَ رَبِّيَ الْعَظِيمِ` | 58 | — | — | — | present | — | **BLOCKED** |
| 52 | Al-Ali | The Most High | `يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ` | 84 | — | — | — | **EMPTY** | — | **BLOCKED** |
| 53 | Al-Kabeer | The Greatest | `يَا كَبِيرُ أَشْعِرْنِي بِصِغَرِي أَمَامَكَ حَتَّى لَا يَمْلَأَ قَلْبِي كِبْرٌ` | — | — | — | — | present | — | clear |
| 54 | Al-Muqeet | The Nourisher | `يَا مُقِيتُ أَقِتْنِي بِذِكْرِكَ وَأَغْذِ رُوحِي بِقُرْبِكَ` | — | — | — | — | **EMPTY** | — | clear |
| 55 | Al-Haseeb | The Reckoner | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` | 47, 48, 90 | — | — | — | present | — | **BLOCKED** |
| 56 | Al-Jaleel | The Majestic | `يَا جَلِيلُ امْلَأْ قَلْبِي إِجْلَالًا لَكَ يُقَرِّبُنِي مِنْكَ لَا خَوْفًا يُبْعِدُنِي عَنْكَ` | — | — | — | — | **EMPTY** | — | clear |
| 57 | Al-Wasi | The All-Encompassing | `يَا وَاسِعُ وَسِّعْ قَلْبِي لِلصَّبْرِ وَبَصِيرَتِي لِتَجَاوُزِ حُدُودِي` | — | — | — | — | present | — | clear |
| 58 | Al-Majeed | The Glorious | `سُبْحَانَ رَبِّيَ الْعَظِيمِ` | 50 | — | — | — | present | — | **BLOCKED** |
| 59 | Al-Baith | The Resurrector | `يَا بَاعِثُ أَحْيِ قَلْبِي كَمَا تُحْيِي الْأَرْضَ الْمَيْتَةَ بِالْمَطَرِ` | — | — | — | — | present | — | clear |
| 60 | Ash-Shaheed | The Witness | `يَا بَصِيرُ أَنْتَ تَرَى مَا لَا يَرَى أَحَدٌ فَاشْهَدْ لِي بِمَا لَا يَعْلَمُهُ سِوَاكَ` | 46 | `يَا` + Al-Baseer (46)**[SHIPPED]** | al-baseer@1 14w | al-baseer@1 19w "o all seeing you see what no one else sees bear witness for me in what only you know" | present | — | **BLOCKED** |
| 61 | Al-Haqq | The Truth | `اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ` | — | — | — | — | present | — | clear |
| 62 | Al-Qawiyy | The Strong | `لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ` | 63 | — | — | — | present | — | **BLOCKED** |
| 63 | Al-Mateen | The Firm | `لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ` | 62 | — | — | — | present | — | **BLOCKED** |
| 65 | Al-Hameed | The Praiseworthy | `الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ حَمْدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ` | — | — | — | — | present | — | clear |
| 66 | Al-Muhsi | The Counter | `يَا مُحْصِي لَا تُحَاسِبْنِي بِمَا أَحْصَيْتَهُ عَلَيَّ وَاعْفُ عَنِّي بِرَحْمَتِكَ` | — | — | — | — | present | — | clear |
| 67 | Al-Mubdi | The Originator | `يَا مُبْدِئُ ابْدَأْ لِي صَفْحَةً جَدِيدَةً وَأَحْدِثْ لِي تَوْبَةً نَصُوحًا` | — | — | — | — | present | 97 Al-Badi | clear |
| 69 | Al-Muhyi | The Giver of Life | `يَا مُحْيِي أَحْيِ قَلْبِي بِالْإِيمَانِ وَأَحْيِ آمَالِي الَّتِي أَمَاتَتْهَا الدُّنْيَا` | — | — | — | — | present | — | clear |
| 70 | Al-Mumeet | The Bringer of Death | `اللَّهُمَّ أَحْسِنْ خَاتِمَتِي وَاجْعَلْ آخِرَ أَعْمَالِي خَيْرَهَا` | — | — | — | — | present | — | clear |
| 71 | Al-Wajid | The Finder | `يَا وَاجِدُ أَوْجِدْ لِي مَخْرَجًا مِمَّا أَنَا فِيهِ وَلَا تَكِلْنِي إِلَى نَفْسِي` | — | — | al-qayyum@1 4w | al-qayyum@1 7w "and do not leave me to myself" | **EMPTY** | — | clear |
| 72 | Al-Majid | The Noble | `يَا مَاجِدُ عَامِلْنِي بِسَخَائِكَ الَّذِي لَا أَسْتَحِقُّهُ وَأَكْرِمْنِي بِقُرْبِكَ` | — | — | — | — | present | — | clear |
| 73 | Al-Wahid | The One | `يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ` | 74 | `يَا` + Al-Ahad (74) | — | — | present | — | **BLOCKED** |
| 74 | Al-Ahad | The Unique | `يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ` | 73 | `يَا` + Al-Wahid (73) | — | — | present | — | **BLOCKED** |
| 76 | Al-Muqtadir | The Omnipotent | `يَا مُقْتَدِرُ أَرِنِي قُدْرَتَكَ فِي أَمْرِي وَاجْعَلْ قُوَّتَكَ حِصْنِي` | — | — | — | — | present | — | clear |
| 77 | Al-Muqaddim | The Expediter | `اللَّهُمَّ اجْعَلْنِي رَاضِيًا بِمَا قَسَمْتَ لِي وَبَارِكْ لِي فِيهِ` | 78 | — | — | — | present | — | **BLOCKED** |
| 78 | Al-Muakhkhir | The Delayer | `اللَّهُمَّ اجْعَلْنِي رَاضِيًا بِمَا قَسَمْتَ لِي وَبَارِكْ لِي فِيهِ` | 77 | — | — | — | present | — | **BLOCKED** |
| 79 | Al-Awwal | The First | `اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ` | 80 | — | — | — | present | — | **BLOCKED** |
| 80 | Al-Akhir | The Last | `اللَّهُمَّ أَنتَ الْأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ وَأَنتَ الْآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ` | 79 | — | — | — | present | — | **BLOCKED** |
| 81 | Az-Zahir | The Manifest | `أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ` | 82 | — | — | — | present | — | **BLOCKED** |
| 82 | Al-Batin | The Hidden | `أَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ` | 81 | — | — | — | **EMPTY** | — | **BLOCKED** |
| 83 | Al-Wali | The Governor | `يَا وَالِي كُنْ لِي وَلِيًّا حِينَ يَبْتَعِدُ الدُّنْيَا عَنِّي وَتَوَلَّ أَمْرِي كُلَّهُ` | — | — | — | — | present | — | clear |
| 84 | Al-Mutaali | The Most Exalted | `يَا عَلِيُّ يَا مُتَعَالِي ارْفَعْ قَلْبِي فَوْقَ الضَّغِينَةِ وَالصِّغَارِ` | 52 | `يَا` + Al-Ali (52) | — | — | **EMPTY** | — | **BLOCKED** |
| 85 | Al-Barr | The Source of Goodness | `يَا بَرُّ ثَبِّتْنِي عَلَى بِرِّكَ وَاجْعَلْ إِيمَانِي رَاسِخًا حِينَ تَرْتَجِفُ الْقُلُوبُ` | — | — | — | — | **EMPTY** | 6 As-Salam | clear |
| 87 | Ar-Rauf | The Compassionate | `يَا رَؤُوفُ الْطُفْ بِي وَأَعِنِّي مِنَ الْبَلَاءِ` | — | — | — | al-lateef@1 5w "one be gentle with me" | present | — | clear |
| 88 | Malik-ul-Mulk | Owner of Sovereignty | `اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ` | — | embeds all of 4 Al-Malik | — | — | present | — | **BLOCKED** |
| 89 | Dhul-Jalali wal-Ikram | Lord of Majesty and Bounty | `يَا ذَا الْجَلَالِ وَالْإِكْرَامِ أَجِرْنَا مِنَ النَّارِ` | — | — | as-salam@1 4w | — | present | — | clear |
| 90 | Al-Muqsit | The Equitable | `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ` | 47, 48, 55 | — | — | — | present | — | **BLOCKED** |
| 91 | Al-Jami | The Gatherer | `رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَّا رَيْبَ فِيهِ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ` | — | — | — | — | present | — | clear |
| 92 | Al-Ghaniyy | The Self-Sufficient | `اللَّهُمَّ أَغْنِنِي بِفَضْلِكَ عَمَّن سِوَاكَ` | — | — | ar-razzaq@1 3w | — | present | 16 Al-Qayyum | clear |
| 93 | Al-Mughni | The Enricher | `يَا مُغْنِي أَغْنِنِي بِغِنَاكَ عَنْ سِوَاكَ وَاجْعَلْ قَلْبِي غَنِيًّا بِكَ` | — | — | — | — | present | — | clear |
| 94 | Al-Mani | The Withholder | `يَا مَانِعُ امْنَعْ عَنِّي كُلَّ مَا يُبَاعِدُنِي عَنْكَ وَأَعْطِنِي كُلَّ مَا يُقَرِّبُنِي إِلَيْكَ` | — | — | — | — | present | 24 Al-Qabid | clear |
| 95 | Ad-Darr | The Distresser | `اللَّهُمَّ اجْعَلْ مَا أَصَابَنِي مِنْ ضَرٍّ كَفَّارَةً لِذُنُوبِي وَرَفْعًا لِدَرَجَاتِي` | — | — | — | — | present | — | clear |
| 96 | An-Nafi | The Benefiter | `اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا` | — | — | — | — | **EMPTY** | — | clear |
| 97 | Al-Badi | The Originator of the Heavens | `يَا بَدِيعَ السَّمَاوَاتِ وَالْأَرْضِ أَنْتَ وَلِيِّي فَاغْفِرْ لِي` | — | — | — | — | present | 67 Al-Mubdi | clear |
| 98 | Al-Baqi | The Everlasting | `اللَّهُمَّ أَنْتَ الْبَاقِي وَنَحْنُ الْفَانُونَ فَاجْعَلْ بَقَاءَنَا طَاعَةً لَكَ` | — | — | — | — | present | — | clear |
| 99 | Ar-Rasheed | The Guide to Right Path | `يَا رَشِيدُ أَلْهِمْنِي رُشْدِي وَقِنِي شَرَّ نَفْسِي` | — | — | — | — | present | 33 Al-Hadi | clear |

**Remaining Names: 75. BLOCKED on the duʿā axis: 30 — [15, 19, 22, 24, 25, 26, 32, 43, 44, 47, 48, 49, 50, 52, 55, 58, 60, 62, 63, 73, 74, 77, 78, 79, 80, 81, 82, 84, 88, 90]. Clear on the duʿā axis: 45.**

### 7a · Standing constraints on this worklist — already decided, not open questions

1. **Ad-Darr (id 95) will be paired with An-Nāfiʿ (id 96) and never shipped solo.** Founder
   decision, recorded. The pair-synergy beat already exists in the format and the ship gate has a
   dedicated assertion for it. Both Names are **clear on the duʿā axis**, so the pair is
   draftable today. Do not draft Aḍ-Ḍārr alone; do not re-litigate it.
2. **"Reject the Name" is off the table** (founder, 2026-08-03). A bar failure is now *"find a
   better source, passage or framing"*, never *"pick a different Name"*. The `al-waliyy@1` cut
   recommendation is withdrawn.
3. **Bar 4 is the shock absorber.** `al-haleem@1` and `al-waliyy@1` both meet bar 1 by giving up
   the Name's own root in the source text. That is legitimate under plan §7 **only with the sweep
   recorded**. Expect it to be the normal shape of a hard deck — Ash-Shakūr (28), Al-Mateen (63) and
   probably Al-Qawiyy (62) cannot be built any other way.
4. **Held free, do not spend:** 30:50 and 41:39 → **Al-Muhyi (69)**. Tirmidhī 3524 → **Al-Hayy (15)**.
   36:81–82 → `al-qadir@1`'s alternative. Bukhārī 4418 / 9:117–118 → `ar-raheem@1`'s fallback.
5. **Al-Wali (83) and Al-Waliyy (64) are transliterated two letters apart on the cards.** Both need
   decks under all-99. This is the *Restorer* problem in a harder form and it is a catalogue
   scheduling constraint, not a deck-level one.
6. **Three exact `english`-gloss collisions exist among the remaining 75** and will surface when
   both halves are drafted: **12 Al-Wahhab "The Bestower" ↔ 43 Al-Muizz "The Bestower of Honor"** ·
   **24 Al-Qabid "The Withholder" ↔ 94 Al-Mani "The Withholder"** (byte-identical) ·
   **67 Al-Mubdi "The Originator" ↔ 97 Al-Badi "The Originator of the Heavens"**. Same class as
   *Restorer*, and catchable now rather than at review.

### 7b · Suggested drafting order, from this table alone

**Wave-ready now (clear on the duʿā axis, no gloss overlap, card `hadith` present, no rendered-run
hit):** 4, 5, 7, 8, 10, 14, 17, 18, 21, 28, 39, 40, 41, 42, 53, 57, 59, 61, 65, 66, 69, 70, 72, 76,
83, 93, 98.

**Clear but carries one flag to handle deliberately:** 1 (the greatest Name — register) · 12, 71, 87,
89, 92 (rendered-run hit with a decked duʿā, §6d) · 45, 99 (a decked Name's gloss inside their duʿā
English) · 20, 54, 56, 85, 96 (card `hadith` **EMPTY** — no card-level corroboration) ·
67, 94, 97 (gloss overlap with another *remaining* Name — draft the pair together, not apart) ·
95 + 96 (**must be drafted as a pair**).

**Do not assign until the catalogue moves:** the 30 in §6e.

---

## 8 · Corrections this pass makes to prior reports

Recorded because reports in this project have been wrong four separate times, twice recommending
exactly the wrong catalogue change.

1. **Batch-2 packet, ids 26/49 vs Al-Lateef (36):** reported as byte-identical to id 36. **False** —
   they are byte-identical to *each other*. Already corrected once by the batch-2 fix report;
   re-confirmed here. **Added this pass:** they nonetheless share a **4-word rendered run**
   (`يَا لَطِيفُ الْطُفْ بِي`) with id 36, so the correction should not be read as "no collision".
2. **"At least five Names cannot get a bar-3-clean deck while the catalogue stands"**
   (batch-2 fix report §7.1). **Understated.** The computed figure is **30 of 75** blocked on the
   duʿā axis, of which **eight** collide with an **already-shipped** Name. The fix report's own
   §7.1 gives the correct 14-group / 30-Name figure two paragraphs earlier, so the "five" line is
   inconsistent with its own data rather than newly wrong.
3. **`al-mujeeb@1` R1's *"a call and its answer is unique among shipped decks"*** — withdrawn by the
   deck itself in R2 (`as-samad@1` also does call-and-answer). Recorded so it is not re-asserted.
4. **`al-qayyum@1` R1's catalogue recommendation** (migrate id 16's `hadith` to Tirmidhī 3524) was
   **backwards**; so was **`al-ghafur@1` R1's** for id 51. Both are corrected in their drafts. The
   pattern — *proposing to replace a correct, broader attribution with a narrower one* — has now
   occurred in **both** batches. **Never action one without independent re-verification.**
5. **`al-waliyy@1` R1's *"four shadda-ordering differences"*** — withdrawn as unreproducible; only
   one sukūn difference survives normalisation.
6. **New findings this pass, in no prior report:** 65:3 spent by **two shipped decks** (§2c) ·
   *"do not lose hope in the mercy of Allah"* rendered by **two shipped verse beats** (§4b) ·
   the *"Allah is more … than"* construction in **two shipped story beats** (§4b) ·
   the **three-way** 11/31/51 duʿā near-duplicate with exact run lengths (§6d) ·
   **id 89's Name-phrase already renders on shipped `as-salam@1`'s duʿā** (§6d) ·
   id 71 / 87 / 92 / 12 rendered-run hits (§6d) · the three `english`-gloss collisions among the
   remaining 75 (§7a.6).

## 9 · What this pass could NOT determine

1. **Duʿā narration provenance for the 75 remaining Names.** No repo artifact records it and this
   pass fetched nothing. Every drafter must fetch their own; §7 deliberately omits the column
   rather than guess it.
2. **Whether the shipped decks' passages survive the successor sweep.** The sweep was invented by
   the batch-1 pilot; **all 14 shipped decks were signed before it existed**, so every `n±1` cell
   for a `[S]` deck in §2a is blank. That ground is **unswept, not clean.** A retro-sweep of the 14
   is a real piece of outstanding work and is not scheduled anywhere.
3. **The Arabic-root columns in §5 are author-assigned**, read off the drafts' own fetched Arabic.
   A mechanical root screen (consonant-subsequence) was run to seed them and produces false
   positives (`وَاجْعَلْنِي` matching `w-l-y`, `بِصِغَرِي` matching `b-ṣ-r`); only hits confirmed by
   eye against the actual word are recorded.
4. **Nothing here was fetched from quran.com or sunnah.com.** Every citation in §2 is transcribed
   from a deck or draft that recorded a fetch; **this ledger re-verifies no scripture.** It is a
   collision index, not a verification artifact.
5. **Whether the ship gate passes over the newly transcribed 24.** This pass ran no tests and edited
   no code. The transcription agent reports it verified; that claim is not independently confirmed
   here.
6. **Several open founder calls remain live inside the `[D]` decks** and could still change a
   rendered string this ledger records: `al-waliyy@1`'s *"refuge"* vs Abdel Haleem's *"shelter"* on
   93:6 · `al-muid@1`'s *Restorer* collision (needs a catalogue edit or a pack-adjacency rule) ·
   `al-mujeeb@1`'s 21:87–88 proximity to `ash-shafi@1` · `al-kareem@1` / `al-ghafur@1`'s on-screen
   attribution convention for app-rendered ḥadīth. **If any is resolved, update §4b here in the same
   change.**

---

## 9 · Wave 1 addendum (2026-08-03) — decisions taken and ground newly spent

Appended rather than woven in, so the diff stays readable and concurrent agents can append the same way.

### 9a · Decisions I took, so nobody re-opens them

| decision | ruling | reason |
|---|---|---|
| **4:130 — claimed by BOTH Al-Wasi (57) and Al-Mughni (93)** | **Al-Mughni.** | `يُغْنِ ٱللَّهُ` is a finite verb of Allah's action inside the āyah's own clause → bar 1 satisfied. `وَٰسِعًا` sits in the trailing `وَكَانَ ٱللَّهُ وَٰسِعًا حَكِيمًا` → **bar 1 forbids it**, and that is the exact ground `al-waliyy@1` was rejected on in batch 2. Same verse, opposite verdicts, decided by grammar rather than by who claimed first. |
| **3:190–191 for Al-Khaliq** | **Moved off it.** | Primary reason is bar 1, not crowding: those āyāt are about `أُو۟لِى ٱلْأَلْبَٰبِ` reflecting, with creation as a **noun being contemplated** rather than an act shown in Allah's words. Secondary: it would have made Āl ʿImrān carry four decks. **Al-Malik cannot move** — 3:26 is not a chosen verse, it is what catalogue id 4's duʿā already is. |
| **`al-aleem@1` duʿā pin** | **APPROVED** — `'al-aleem@1': "Jami' at-Tirmidhi 3392 (opening words)"`. | The duʿā is not authored: it is the opening of the Abū Bakr morning/evening supplication, matching Tirmidhī 3392 (ḥasan ṣaḥīḥ) to within one orthographic word (`السَّمَاوَاتِ` vs `السَّمَوَاتِ`). Pinning tells the user the duʿā they are reciting is narrated. `(opening words)` because the catalogue text is truncated and the gate forbids adding an ellipsis to gate-locked Arabic — `source` is the only rendered field where truncation can be disclosed. Same shape as `al-malik@1`'s proposed `"Qur'an 3:26 (opening)"`. |
| **`al-mughni@1` bar 5** — setting is the distribution after Ḥunayn | **ACCEPTED.** | No beat renders fighting, enemy, killing or spoil-taking; the quoted material is entirely a conversation. Bar 5 forbids a punishment or curse passage repurposed as comfort, which is absent. Shipped precedent is already looser than this: `al-wakeel@1` sits immediately after Uḥud and `al-fattah@1` at Ḥudaybiyyah. The drafter chose Bukhārī 4330 over 3778/4337 *because* those narrate the rout. |
| **`al-mughni@1` beat 5 elision** — the narration's ending (*"you will meet others preferred over you, so be patient…"*) | **KEEP THE ELISION**, visible `…`, omitted text quoted in the draft's table. | The ending redirects to patience-until-the-Ḥawḍ, a different consolation that blurs this deck's engine (*the unlisted share*), and it introduces `ṣ-b-r` — As-Sabur's root. Disclosed, not hidden. |
| **`al-mughni@1` duʿā** | **UNPINNED**, and must not enter `renderedDuaSources`. | Catalogue id 93's duʿā is an authored invocation. A pin would assert a provenance the text does not have. |

### 9b · Newly spent, and newly blocked

- **93:8 (`وَوَجَدَكَ عَآئِلًا فَأَغْنَىٰ`) is BLOCKED, not free.** It is the strongest Al-Mughni āyah in the Qurʾān and was given up: `al-waliyy@1` holds **93:6** as its verse beat, two āyāt away in an eleven-āyah sūrah. Taking it would have made aḍ-Ḍuḥā the **third** instance of this ledger's worst named defect (65:3 in two shipped decks; *"do not lose hope…"* on two shipped verse beats).
- **Sūrat Āl ʿImrān now carries three decks** — `al-wakeel@1` 3:172–174, `al-malik@1` 3:26, `al-aleem@1` 3:35–37. Treat a fourth as the ash-Shūrā shape.
- **Al-Malik permanently spends id 88 (Malik-ul-Mulk)'s entire duʿā English on a verse beat** — id 88's `dua_arabic` is the same slice of 3:26, verified rasm-identical. 88 was already blocked; this deepens it.
- **55:26–27 and 28:88 left deliberately unspent** by Al-Baqi, on three fetched grounds (55:27's English is byte-identical to a phrase on shipped `as-salam@1`'s duʿā beat and is id 89's whole Name; 55:29 is id 34 As-Samad's `meaning` almost verbatim; 55:28 is the rebuke refrain).

### 9c · Card-level collisions found this wave — none blocking, all inherited by a future drafter

1. **Shipped `ar-razzaq@1`'s duʿā beat already renders Al-Mughni's own root in ENGLISH** — *"…and enrich me by Your favor over all others"*. §6d records this for id 92 only, and only on the Arabic axis. Zero shared Arabic runs ≥2 words and zero shared English runs ≥3 words with id 93, so non-blocking — but it is catalogue text no deck can change.
2. **Ids 92 and 93 share the 3-word English run *"I need no one"*** in their `dua_translation`s. §7's row for 93 says "no ≥4-word English run" — correct at its own threshold, incomplete below it. **Al-Ghaniyy's drafter inherits the *Restorer* problem in a harder form**: two Names one letter apart in Arabic, asking the same thing.
3. **Catalogue ids 80 and 98 share an eight-word `meaning` run** (*"The One who remains … after all creation has perished"*), and **id 80's `lesson` is Al-Baqi's engine in one sentence**. Card strings, not deck strings — a scheduling constraint on Al-Akhir (80), which is blocked anyway.
4. **"The Everlasting" (98) vs shipped `as-samad@1`'s "The Eternal Refuge"** — both catalogue `english`, the *Restorer* class in milder form. Zero shared scripture, engine or rendered string. Founder call, unfixable inside a deck.

### 9d · Two traps worth more than the decks they were found on

**A published English can delete the Name from its own deck.** Ṣaḥīḥ Muslim 2787 carries the same Arabic as Bukhārī 4812, but its published English renders `أَنَا الْمَلِكُ` as *"I am the Lord"* and `مُلُوكُ الأَرْضِ` as *"the sovereigns of the world"*. Routing Al-Malik through Muslim would have removed the word *King* from a deck about Al-Malik. **Choose the route on the Arabic, then check what the English does to it** — this is the `al-kareem@1` failure in a new costume.

**The id-51 / id-16 shape recurred a third time and was caught before it reached the founder.** Catalogue id 14's duʿā matches **Tirmidhī 3392** (ḥasan ṣaḥīḥ) to within one orthographic word, while **Abū Dāwūd 5067** (ṣaḥīḥ) carries the same supplication with the clauses **reversed**. A drafter who fetched only Abū Dāwūd would have reported the catalogue as having its clauses backwards and recommended reordering id 14 — wrong, in the same direction as both prior instances. **Three for three: every confident recommendation to change catalogue data has been wrong. Fetch every route before writing one.**

### 9e · Operational note for future waves

**Write each draft to disk the moment it is ready.** Three agents in this project have died mid-response after reading a large corpus and trying to emit a large artifact in one turn. The claim file goes first, then each draft as it completes.

**Wayback mechanics:** `/wayback/available` is unreliable and silently reports zero snapshots for pages that are archived — use the **CDX API**. Current captures are served `content-encoding: zstd`, which macOS `curl` cannot decode; pipe through `zstd -d` or every page reads as binary garbage.

### 9f · Wave 1, second half — newly spent and newly constrained

- **Sūrat Quraysh (106) is spent** by `al-mumin@1`'s verse beat 106:4. All four āyāt read; the sūrah contains no warning, rebuke or punishment anywhere — the cleanest bar-5 result recorded so far.
- **52:48 is spent** by `ar-raqeeb@1`. Note 52:16 uses that deck's own verb (`فَٱصْبِرُوٓا۟ أَوْ لَا تَصْبِرُوا۟`) as a **taunt to the punished**, 32 āyāt earlier — off-screen, found by reading rather than scanning.
- **The hijrah cluster (Thawr, Surāqa) is spent** by shipped `as-salam@1`; Uḥud/Badr are `al-wakeel@1`'s and carry battle register.

**AL-MUHAYMIN (18) INHERITS A CONSTRAINT — read before assigning it.** Its catalogue duʿā is *"guard me with **Your eye** that never sleeps"* (`بِعَيْنِكَ`), and id 18's duʿā **renders Arabic on screen**. `ar-raqeeb@1` has now claimed 52:48 — `فَإِنَّكَ بِأَعْيُنِنَا` — the same root and the same image. Ar-Raqeeb's drafter enumerated every occurrence of the Name-noun `رَقِيب` (4:1, 5:117, 11:93, 33:52, 50:18) and **all five fail** a bar, so 52:48 was the only surviving text and could not be ceded. **This is catalogue-vs-deck, the same class as *Restorer* and *The Withholder* — not fixable by whoever drafts Al-Muhaymin.**

**Bar 4 traded on `ar-raqeeb@1`, and the sweep proving it forced is recorded:** 4:1 and 33:52 are trailing epithets (bar 1); 5:117 is ʿĪsā's speech about Allah and carries Ash-Shaheed's word twice; 11:93 is Shuʿayb calling *himself* raqīb, inside a punishment āyah; 50:18's `رَقِيبٌ عَتِيدٌ` is the recording angel, not Allah, in exactly the surveillance register this Name's tone line forbids. The search was run three times across inflections. **Limit stated by the drafter: this enumerates the noun, not the root.**

### 9g · MUST BE RULED ON BY THE BLIND VERIFIER, not accepted from the drafter

**`al-mumin@1` beat 4 echoes shipped `al-wakeel@1` beat 1 — beat-to-beat.** Al-Wakīl renders *"…were told to be afraid. They were not."*; Al-Muʾmin renders *"Are you afraid of me?" "No."* The drafter judged it non-blocking on good grounds (the words are the narration's own and cannot be reworded; the two resolve in **opposite directions** — the believers' own act vs an attribution to someone else) and offered a one-line escape (open beat 4 on *"Then who will protect you from me?"*, at the cost of the *khawf* bind that ties the story to the verse beat).

**It is recorded here unresolved on purpose.** This is precisely the class batch 2 was burned by, and in batch 2 the drafter also marked its own collision ✖ after comparing takeaway-to-takeaway. **A drafter's own "non-blocking" on a beat-to-beat echo is the finding the adversarial pass exists to test.** Do not treat the reasoning above as a ruling.

### 9h · Catalogue findings from wave 1 — reported, NO change recommended

The standing rule holds: **three of three confident recommendations to change catalogue data have been wrong.** These are findings.

1. **Id 7 Al-Muʾmin's `hadith` teaches the homonym.** It is Abū Dāwūd 4918, *Ḥasan (al-Albānī)* as printed — authentic and correctly graded. The defect is that `الْمُؤْمِنُ` there is **the human believer, twice**, sitting under Allah's Name. The card also merges the narration's two clauses and appends unattributed authored prose inside a field users read as a quotation. One tap from the deck.
2. **Id 40 Ar-Raqeeb's `hadith` has three defects and SURVIVED the 2026-08-03 repair pass.** It shares a **20-word run with shipped id 46 Al-Baseer's card**, so Ar-Raqeeb's card opens by naming a different Name; its narrative (Yūnus in the fish) is `al-mujeeb@1`'s; and it cites only *"(Ibn Masʿūd)"* — no collection, no number, nothing to fetch. **Not an assertion of fabrication — an assertion that as printed it cannot be checked.**

**What #2 says about the repair pass, and it generalises:** that audit checked whether a citation *resolves*, not whether a card *duplicates another card*. Cross-card duplication was never in scope for it. **The `hadith` column has not been swept for the collision axis at all** — only for authenticity. That is separate outstanding work on the catalogue track.

### 9i · Translation decisions worth reusing

- **106:4** keeps Saheeh International's `[saving them]` brackets. Abdel Haleem was fetched and **rejected with a reason**: he renders `وَءَامَنَهُم` as the bare noun *"safety"*, dissolving the finite verb bar 1 rests on.
- **52:48 was re-rendered from the Arabic** (plan §6 rule 2) because Saheeh's *"in Our eyes"* is an English idiom meaning *in Our judgement* — Saheeh itself has to gloss it `[i.e., sight]`. Abdel Haleem's *"under Our watchful eye"* was fetched and **not taken**: it would put the Name's own gloss on the verse beat (a partial bar-4 recovery) but makes `أَعْيُن` singular and sharpens the Al-Muhaymin collision above.
- **`al-mumin@1` beat 5 states outright that no miracle is narrated.** The popular retelling has the sword fall; neither ṣaḥīḥ route says so. Muslim's Companions-closed-in clause is **included rather than dropped**, so the omission does not leave a miracle-shaped hole for a reader to fill.

### 9j · An-Nur and Al-Haqq — refusals worth more than the anchors that replaced them

**24:35, the Light Verse, is BLOCKED — refused on three independent grounds, not merely passed over.**
1. **Bar 2** — `ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` **states** the attribute. That is what killed `al-haleem@1` rev 1.
2. **Translation adjudication, in its worst form.** That sentence carries the longest exegetical dispute in the Qurʾān (essence vs *munawwir*). Plan §7 says re-render contested passages from the Arabic — but **here there is no neutral rendering to produce**: the ambiguity is in the Arabic and every English resolves it. A deck printing any version would adjudicate while believing it had not. This is the `al-kareem@1` rule at its limit.
3. **Bar 3** — the āyah's only finite-verb clause of divine action is `يَهْدِى ٱللَّهُ لِنُورِهِۦ مَن يَشَآءُ`, and *"Allah … guides"* is shipped `al-hadi@1`'s verse beat in rendered English.

A parable-only excerpt was drafted and **discarded**: it removes (2) and (3) but leaves **bar 1 unmet**. Bar 4 is the sanctioned shock absorber; bar 1 is not. The deck moved its anchor rather than lower the bar.

**10:82 is a TRAP, recorded so nobody walks into it.** `وَيُحِقُّ ٱللَّهُ ٱلْحَقَّ بِكَلِمَـٰتِهِۦ` looks like the strongest Al-Haqq āyah in the Qurʾān — Allah explicit subject, finite verb, the Name's own root as both verb and object. **It is inside Mūsā's speech.** Saheeh closes the quotation after *"…the criminals dislike it."* Same already-rejected class as 7:196, 12:101, 10:62 (human speech about Allah). Proven by fetching 10:79–83.

**A textual firewall between the two decks, found mid-draft.** The tahajjud duʿā (Bukhārī 1120 / 7385, Muslim 769a) is id 61's duʿā provenance — **and it also contains `أَنْتَ نُورُ السَّمَاوَاتِ وَالْأَرْضِ`, An-Nur's own phrase.** Both Names' catalogue duʿās trace to Ibn ʿAbbās narrations. That narration is therefore quoted on **no beat of either deck**, and is the second reason Al-Haqq is not built on its own duʿā.

**Also spent/blocked:** Sūrat an-Nūr's Light Verse (blocked, above) · 6:122 spent by `an-nur@1` · 7:118 and Ṭā Hā 20:65–70 spent by `al-haqq@1` · **Tirmidhī 3419 fetched and REJECTED — Ḍaʿīf (Darussalam)** and it is the *only* narration carrying both of id 17's catalogue clauses.

### 9k · A distinction that must not be flattened when reporting to the founder

**Id 17's duʿā is a two-route COMPOSITE, not an unsourced one.** All five routes were fetched; **not one contains all three catalogue clauses**, but **every clause is in a ṣaḥīḥ narration** — the *heart* clause in Bukhārī 6316 / Muslim 763a / 763g, the *tongue* clause in Abū Dāwūd 1353 (page grade Ṣaḥīḥ), *"make me light"* in Muslim 763g (as `أَوْ قَالَ`). It is the **combination** that is unpinnable, not the content.

**That is a much smaller finding than "no provenance" and must never be reported as the latter.** Same for id 61, which is a **splice**: Muslim 769a's four `وَلَكَ الْحَمْدُ` clauses reduced to the opening four words plus the final clause, unmarked. Both decks ship **unpinned** — correct — but "unpinned" here means *the catalogue text is a composite*, not *the words are unattested*.

### 9l · The id-51/id-16 shape, fourth instance — and the FIRST time the answer was "the card is right"

Id 61's card cites **Bukhārī 7385**, whose *main chain* reads `قَوْلُكَ الْحَقُّ وَوَعْدُكَ الْحَقُّ` — **not** the catalogue's clause. A drafter reading only the main body would have reported the card as misattributed and recommended a change.

**It is not misattributed.** The same page carries a **second chain** (Thābit b. Muḥammad ← Sufyān) reading `وَقَالَ أَنْتَ الْحَقُّ وَقَوْلُكَ الْحَقُّ`, so *"You are the Truth"* **is** on the page the card cites — and Bukhārī 1120 / Muslim 769a carry the full clause contiguously.

**The rule sharpens: read the whole page, not the main chain.** Four instances now, and the first where diligence produced *"leave it alone"* rather than *"the recommendation was backwards."* Both outcomes come from the same discipline.

### 9m · NEW catalogue finding — a duʿā screen renders a request its own Arabic does not make

**Catalogue id 61's `dua_translation` ends: *"Make Your truth the anchor of my heart."*** Its Arabic — `اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ الْحَقُّ وَوَعْدُكَ الْحَقُّ` — **contains no imperative at all.** It is pure praise, and `dua_transliteration` also stops at `wa waʿdukal-ḥaqq`.

So the duʿā beat renders, **visibly and side by side on one screen**, an English petition the Arabic beside it does not contain. This is the same class as the fabrications removed on 2026-08-03 — an English rendering asserting what the source does not — but in the **duʿā translation column**, which the ḥadīth audit never covered.

**No fix recommended here.** Delete-the-clause vs add-the-Arabic is a content decision about a supplication, not a drafting one. **The wider question it raises belongs on the catalogue track: `dua_translation` has never been swept against `dua_arabic` for added or dropped content.** The ḥadīth column has now been audited twice; this column has been audited zero times.

### 9n · Bar-5 row a reviewer should attack first

**`al-haqq@1`'s bar 5 is an argument, not a 404.** Neither excerpt is sūrah-final. **20:71 — Pharaoh's threat of mutilation and crucifixion — is the successor to its last story beat**, and 7:123–124 is the parallel. None is quoted or alluded to, and the passage's own resolution (20:72–73) is a victory rather than a punishment. The drafter says plainly this is the row to attack first. **Verifier: start there.**

### 9o · STANDING RULE — a formulaic Qurʾānic opening is not a bar-3 collision

Raised by `al-wasi@1`, whose verse beat renders *"O My servants who have believed"* against shipped `al-ghaffar@1`'s *"O My servants who have exceeded the limits"* — a **5-word run, verse beat to verse beat**. The drafter flagged it as the *"do not lose hope"* class and asked for a standing decision, correctly noting it will recur across the remaining 75 (39:10 shares the same opening, so swapping would not have helped).

**Ruling: it is NOT a collision, and no disclosure is required.**

Bar 3 exists to stop two decks **teaching the same insight** or **renaming the same Name**. `يَـٰعِبَادِىَ` is the Qurʾān's own vocative formula — the shared words are a form of address, not a claim. Two decks opening on it are no more colliding than two decks both rendering the word *Allah*. Forcing a leading ellipsis onto every such beat would mutilate the text to satisfy a string diff.

**The line, for every future wave:**

| shared material | collision? |
|---|---|
| **Formulaic openings** — vocatives (`يَـٰعِبَادِى`, `يَـٰأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟`), `قُلْ`, oath formulae, `سُبْحَـٰنَ` | **No.** Not disclosed, not counted. |
| **Doxological set phrases** — *"Blessed and Exalted is He"*, *"Exalted is He"* | **No**, but **disclose**. Recurs constantly around creation and majesty; a reader noticing it should find it acknowledged. |
| **A substantive clause** — *"do not lose hope in the mercy of Allah"* rendering on two shipped verse beats from two different āyāt | **YES. Blocking.** This is what bar 3 is for. |
| **A rendered Name-gloss** — *Restorer* vs *Restorer of the Broken*, *The Creator* vs *[Creator]*, *The Everlasting* vs *The Eternal Refuge* | **Yes, and unfixable inside a deck** — catalogue `english` strings. Escalate; do not paper over. |

**The test:** could a user read both screens and think they had been told the same thing twice? A vocative fails that test; a substantive clause passes it.

### 9p · Wave 1 complete — spent, and three new catalogue-level collisions

**Newly spent:** 23:12–14 and 36:36 (`al-khaliq@1`) · 2:115 and 29:56 (`al-wasi@1`) · 3:191 rendered in a `source` string only, so **Āl ʿImrān still carries three decks, not four**.

**`cf. Qur'an 3:191` proposed for `al-khaliq@1`.** Catalogue id 10's duʿā **is** 3:191 minus its closing four words — rasm-identical, byte-different (`هَذَا` vs `هَٰذَا`). The āyah continues `فَقِنَا عَذَابَ ٱلنَّارِ`, so a bare pin would be **a false claim on screen**; `cf.` follows the `ash-shafi@1` precedent. **No catalogue edit proposed** — this is now the *fifth* Name whose duʿā turns out to be scripture rather than authored invocation (ids 4, 10, 14, 37, 64), which makes duʿā-first selection the single highest-yield step in this pipeline.

**Three collisions absent from every prior section of this ledger:**
1. **Shipped `ar-rahman@1` renders Al-Wasi's own root `وَسِعَتْ` in ARABIC on its duʿā screen**, plus *"My mercy encompasses everything"* on its verse beat and *"A mercy that wide"* on its takeaway. Catalogue-level and pre-existing. `al-wasi@1`'s answer is structural rather than cosmetic — zero `r-ḥ-m` in any quoted text, the word *mercy* in no rendered string, the root rendered *"spacious"* not *"Encompassing"* — and it **declined** a one-line truncation of 2:115's own epithet on the grounds that cutting the Name's word would hide the collision rather than disclose it. **The verifier rules on whether that is separation or decoration.**
2. **`al-qadir@1` renders "[Creator]"** against `al-khaliq@1`'s locked `name_intro` *"The Creator"*. *Restorer* class.
3. **`al-kareem@1` renders "Blessed and Exalted is He"** against 36:36's *"Exalted is He"*. Doxological — disclosed, not blocking, per §9o.

**Al-Wasi is the first Qurʾān-only deck: no ḥadīth survived.** Its first-choice story (Tirmidhī 345, the qibla in the dark) **died on grade — at-Tirmidhī's own weakening on the page** — so the deck asserts **no occasion of revelation** for 2:115 rather than reaching for a weaker route.

**Two more `dua_translation` defects of the §9m class** — an English petition with no counterpart in the Arabic beside it: **id 57** has three petitions where the Arabic has two (*"gratitude"* is unsupported), and **id 61** ends on an imperative its Arabic does not contain. **That is three instances in one wave. The `dua_translation` column has been audited zero times and should be swept as its own pass.**

### 9q · CORRECTION to §9a — my own bar-5 record was overstated

**§9a records `al-mughni@1`'s bar 5 as ACCEPTED on the wording "no beat renders fighting, spoils-taking or an enemy." That wording is wrong and it is mine, not the drafter's.**

The blind verifier checked it against the beats: **beats 5 and 8 do render people carrying away the sheep and the camel, and those ARE the distributed war-gains.** What is genuinely absent is any **fighting, enemy, killing, or labelling of the goods as spoils**.

**The ruling stands — bar 5 passes — but on the narrower true statement, not the broad false one.** I accepted a drafter's absolute phrasing without testing it, which is precisely the failure this pipeline documents in §6: *a founder signing against a ✅ is signing against claims that are sometimes wrong.* A coordinator recording a ✅ is no different.

**Related, and it sharpens the point:** the deck renders `أَفَاءَ` as *"what Allah had granted His Messenger"*, which **subtracts the war-gain sense both published Englishes carry**. That is the `al-kareem@1` failure in mirror image — a translation choice doing theological work — except here it works in the deck's own favour by softening the very material bar 5 is judging. **The softening must be disclosed on the record, not left as a quiet assist.**

### 9r · The gh-n-y enumeration was SEVEN, not six — conclusion survives, record did not

`al-mughni@1` recorded *"There are six. Five die."* The verifier re-ran it over an independent Qurʾān text and found a **seventh**: **24:33**, `حَتَّىٰ يُغْنِيَهُمُ ٱللَّهُ مِن فَضْلِهِ` — Allah-subject, transitive, a candidate in its own right, which the draft treated **only as 24:32's successor and never as a candidate**.

**4:130 survives as the only usable anchor** (24:33 dies intra-āyah on `وَلَا تُكْرِهُوا۟ فَتَيَـٰتِكُمْ عَلَى ٱلْبِغَآءِ`), so the choice is still forced. But the sentence in the packet was false, and **a bar-4/bar-1 trade justified by an enumeration is only as good as the enumeration.** Also corrected: 53:48's destruction of ʿĀd is **two** āyāt later (53:50), not seven.

**Rule for every future sweep: a verse examined as a neighbour has not been examined as a candidate.** Sweep and candidacy are different passes over the same text.

### 9s · The claims mechanism has a timing hole — both wave-1 drafts hit it

Both drafts recorded a sibling-claim row listing **four** live claims. `.context/claims/` held **ten** — and the missing one (57) had a **live conflict on 93's own verse beat**.

**Cause: an agent reads the claims directory once, at its own start time.** Ten agents starting within minutes of each other therefore see between one and ten files each, and none sees the full set. The mechanism caught both real collisions this wave — but through *me* reading the files after the fact, not through the agents reading each other.

**Fix for wave 2, cheap:** instruct every drafter to **re-read `.context/claims/` immediately before writing its verification table**, not only before drafting. The claim goes in early to stake ground; the re-read happens late to catch whoever staked after you.

### 9t · Fourth `dua_translation` defect this wave — the count is now the finding

**Id 93:** `dua_arabic` ends `وَاجْعَلْ قَلْبِي غَنِيًّا بِكَ` and `dua_transliteration` ends `…ghaniyyan bik`, but `dua_translation` appends **"until no desire competes with Your glory"** — no counterpart in either, rendered **side by side on one screen**. The drafter missed it and affirmatively endorsed the English while quoting only the clean half; the verifier caught it.

**That is ids 57, 61 and 93 in a single wave of ten, plus the earlier instances.** Every one is an English string asserting something its own Arabic does not say, on a screen where a user can see both.

**This is the same class as the fabricated quotations removed on 2026-08-03, in a column no audit has ever covered.** The ḥadīth column has now been swept twice. `dua_translation` has been swept zero times. **Given a ~30% hit rate in an unselected sample of ten, this needs its own pass over all 99 before any of it is signed.**

### 9u · CORRECTION to §9b — two false claims I recorded as rulings

Both were caught by the blind verifier, both are mine to own: I transcribed a drafter's assertion into this ledger as a finding without testing it.

**1. "55:29 is id 34 As-Samad's `meaning` almost verbatim" — FALSE.**
- 55:29 reads *"Whoever is within the heavens and earth asks Him; every day He is in [i.e., bringing about] a matter."*
- Id 34's `meaning` reads *"The One to whom all creation turns in need, yet He needs nothing."*
- **Zero shared substantive words. No run of any length.** 55:29 has no counterpart at all to id 34's operative clause *"yet He needs nothing"*.
- It is a **conceptual adjacency described as near-verbatim** — and it was one of three grounds for refusing Al-Baqi's natural verse, marked ✅ *"confirmed, not assumed"* and offered as proof of diligence.

**2. "Al-Malik permanently spends id 88's ENTIRE duʿā English" — FALSE.** Computed: the longest contiguous run is **11 words**, then the wording diverges, and **id 88's entire second sentence is absent**. The collision is real and serious; the word *entire* is not. This one errs toward over-blocking, so it is not dangerous — but it stood here as a ruling.

**What this changes about how I record.** §9q was the first instance, these are the second and third. The pattern is now unmistakable: **a coordinator who copies a drafter's ✅ into the ledger has added a signature, not a check.** §6 of the plan says a founder signing against a ✅ table is signing against claims that are sometimes wrong — that applies identically to me.

**Rule going forward: anything entering this ledger as a *ruling* must be either (a) something I verified myself, or (b) explicitly attributed as an unverified drafter claim awaiting the blind pass.** Nothing in between. Where I state a fact here, I checked it.

### 9v · Al-Malik contains its own duʿā twice, and nobody's sweep was pointed at it

**Beat 6 contains beat 7's gate-locked duʿā English verbatim — 12 words, byte-exact.** The ship gate locks beat 7's `primary` to catalogue id 4's `dua_translation`, and beat 6 renders that same sentence two screens earlier. **The user reads it twice.**

The draft diffed its beats against all 24 shipped decks and against its sibling draft. **It never diffed its own beats against each other.** That is batch 2's exact methodological error — comparing at the wrong granularity — reappearing in a new place after being fixed in the old one.

**New standing check for every deck, cheap and mechanical: diff each deck's beats against ITS OWN other beats before diffing against the corpus.** A deck that quotes itself is a defect no cross-deck sweep can see.

### 9w · A mis-pin trap, planted for a future drafter

Id 98's duʿā could not be traced by either the drafter or the verifier, and **UNPINNED is correct.** But the verifier found the reason it will look traceable to someone later:

**Sunan Abī Dāwūd 1173** (Kitāb al-Istisqāʾ, narrated **ʿĀʾisha** — Al-Baqi's own narrator) carries `اللَّهُمَّ أَنْتَ اللَّهُ لاَ إِلَهَ إِلاَّ أَنْتَ الْغَنِيُّ وَنَحْنُ الْفُقَرَاءُ`. Id 98's duʿā is **the same syntactic template `اللَّهُمَّ أَنْتَ الْ[Name] وَنَحْنُ الْ[opposite]` with the attribute pair swapped.**

**A future drafter searching that template will land on Abū Dāwūd 1173 and may propose pinning id 98 to it. That would be the id-51/id-16 shape a fifth time** — the Name in the narrated formula is `الْغَنِيّ` (id 92), **not** `الْبَاقِي`. The match confirms the catalogue duʿā is *authored on a narrated pattern*, which strengthens UNPINNED rather than weakening it.

### 9x · Ruling carried over from §9g — the al-mumin echo

The Al-Malik/Al-Baqi verifier volunteered a view on §9g although those are not its decks: **zero shared n-grams at n≥4** between `al-mumin@1` beat 4 and `al-wakeel@1` beat 1. Batch 2's precedent collision was a near-identical *phrase*; this is a thematic echo with **no textual overlap**.

**It rules NON-BLOCKING on the strings — explicitly not on the drafter's three reasons**, two of which are interpretive and not the kind of thing an adversarial pass can confirm. That distinction is the right one and worth copying: **an adversarial pass settles measurements, not arguments.** The deck's own verifier still rules formally.

### 9y · CORRECTIONS to §9j — three claims I recorded that do not survive

§9u set the rule that nothing enters this ledger as a ruling unless I verified it or marked it unverified. **§9j predates that rule and violates it three times.** All three caught by the blind verifier.

**1. "Tirmidhī 3419 is the only narration carrying BOTH of id 17's catalogue clauses" — FALSE. It carries NEITHER.** Page searched: `لِسَانِي` = 0, `لسان` = 0, `وَاجْعَلْنِي` = 0, `اجعلني` = 0. **The draft's own five-route table already said so** — the deck contradicted itself and I copied the false version. **Conclusion strengthened, not harmed:** no route carries both, which is exactly why the duʿā is a composite. The rejection of 3419 stands on its ḍaʿīf grade, confirmed on the page.

**2. "24:35's only finite-verb clause of divine action is `يَهْدِى ٱللَّهُ`" — FALSE.** `وَيَضْرِبُ ٱللَّهُ ٱلْأَمْثَـٰلَ لِلنَّاسِ` is a second; `مَن يَشَآءُ` a third. **Conclusion survives** — *ḍarb al-amthāl* demonstrates nothing about light. **Correct wording: "the only clause carrying divine action ON THE NAME'S OWN ROOT."**

**3. Ground 2 of the 24:35 refusal — "no neutral English exists" — NOT ESTABLISHED.** The standard literal calque preserves the same *iḍāfa* ambiguity English *"the light of X"* already carries. **Downgraded to an open question.** The refusal remains correct and **over-determined by ground 1** (bar 2 — it states rather than shows), the ground that killed `al-haleem@1` rev 1. Both the drafter's claim and the rebuttal are linguistic assessments made without a tafsīr corpus — mirror images, same epistemic status.

### 9z · The finding neither the draft nor I had: An-Nur adjudicates by SELECTION

**The deck refused 24:35 to avoid adjudicating a contested attribute — then adjudicated it anyway, by choosing its anchor.** `an-nur@1` rests on 6:122's `وَجَعَلْنَا لَهُۥ نُورًا`: Allah making a **created light for a person**. That is the *munawwir* reading, unambiguously, and it is the deck's **bar-1 and bar-4 carrier** — load-bearing, not incidental.

**This is the `al-kareem@1` failure in a new costume.** There a deck adjudicated by choice of *translation* while believing it had adjudicated nothing; here by choice of *passage*. **NOT BLOCKING** — no beat predicates *nūr* of Allah and *munawwir* is classical and safer — but the draft tells the founder it declined to adjudicate, **and that is not true.**

**New rule: refusing a contested text does not make a deck neutral.** Selecting a different passage is itself a position when the passages differ on the contested point. Any deck refusing an anchor on adjudication grounds must state what its replacement commits it to.

### 9aa · `al-haqq@1` bar 5 — RULED MET, with the real objection named

20:71 is real: Pharaoh threatens amputation and crucifixion one āyah past the last story beat. But **20:72–73, the passage's own ending, is a triumph** — the magicians refuse, closing *"And Allāh is better and more enduring."* **The deck stops one beat short of a VICTORY, not one short of a reversal** — the structural inverse of what killed `al-haleem@1` rev 2.

**The calibration that decides it:** shipped `al-afuw@1` renders 42:26 ending on *"the disbelievers will have a severe punishment"* — **divine, eschatological, aimed at a class the reader might fear belonging to** — recorded non-blocking. Al-Haqq's is a **human tyrant's** threat, at the story's **heroes**, **answered in the next āyah**, temporal not eschatological. Softer on every axis. **A rule cannot forbid the softer case while shipping the harder one.**

**The real objection, which nobody had stated:** it is not *"punishment nearby"* — it is that **the deck offers comfort about recognition while the passage's next move is that recognition costs these men their limbs.** Does not fail bar 5. Worth deciding consciously.

### 9ab · §9g RESOLVED — the al-mumin echo is BLOCKING. Take the escape hatch.

The deck's own verifier ruled against the drafter, and against the other verifier's provisional string-only view. **Grounds, in order of force:**

1. **"afraid" is a corpus hapax** — across all 473 rendered strings in the 24 shipped decks it occurs **exactly once**, on `al-wakeel@1` beat 2. Al-Muʾmin's beat 4 would be the only other, **doing the identical job.**
2. **It is not one beat, it is three consecutive ones.** `al-wakeel@1` b1→b2→b3 against `al-mumin@1`: *"Guardian"* ↔ *"Guardian of Faith"*; *"told to be afraid. They were not."* ↔ *"Are you afraid of me?" "No."*; *"the best Protector"* ↔ *"who will protect you from me?"*. The drafter disclosed the first two **as two unrelated findings on separate rows** and **never saw the third** — its method (substring-matching long candidate phrases) structurally cannot detect a single-token overlap.
3. **The drafter's defence is correct and insufficient.** Both halves verified; the verifier even found a *better* differentiator the drafter missed. **But a difference in resolution does not undo a repetition in staging. Beats land one at a time.**
4. Half the collision — *Guardian*, catalogue id 7's own `english` — is **unfixable** (*Restorer* class). **Precisely because that half cannot be fixed, the fixable half must be.**
5. The escape hatch was tested and **does not orphan beat 8**: bravado was an available answer and was not taken, so *"He did not answer that he was brave"* still lands. Cost is the *khawf* bind, which beats 1 and 6 still carry.

**This is the second time a drafter cleared its own beat-to-beat echo and an independent pass overturned it.** The rule is now empirical, not cautionary: **a drafter may not rule on its own collision.**

### 9ac · The strongest verification in either batch, and a rule it earns

`ar-raqeeb@1`'s bar-4 trade was re-run by the verifier **over the full 6,236-āyah Uthmānī text rather than an API search** — exactly five `رَقِيب`, no sixth, each rejection re-verified. **Then it ran the sweep the drafter had declined**: all 24 `r-q-b` words. Every verbal form (9:8, 9:10, 20:94, 28:18/21, 44:10, 44:59×2, 54:27) has a **human** subject; every `فَٱرْتَقِبْ` sits in a punishment passage; `رقبة`/`رقاب` is neck/manumission. **No `r-q-b` form anywhere has Allah as the watching subject — the trade is MORE forced than the drafter proved.**

**Rule: a root sweep run against a search API is not an enumeration.** Run it against the full text. The drafter's noun-only sweep reached the right answer with a weaker method; the next one may not.

### 9ad · Two more catalogue defects, both on fields no audit has touched

Both found by the verifier, both missed by drafts that audited only the `hadith` column:
- **Id 7's `lesson`** reads *"Al-Mumin sees your sincerity…"* — **Al-Baseer's register, with no safety in it at all**, on the Name whose whole meaning is giving security.
- **Id 40's `meaning`** reads *"The One who sees every action, thought, and intention"* — **Al-Baseer's verb**, plus exactly the enumeration register this Name's tone line forbids.

**And the Al-Muhaymin constraint in §9f is worse than recorded: id 18's `meaning` literally reads "The One who watches over…", which is `ar-raqeeb@1`'s own beat-8 phrase.**

**Pattern: `lesson` and `meaning` have never been swept for cross-Name register bleed.** Three instances in one wave, all found incidentally. Add to the catalogue track beside `dua_translation`.

### 9ae · MANDATORY DISCLOSURE — `ar-raqeeb@1` vs shipped `al-ghafur@1`

`al-ghafur@1` beat 3 renders Allah asking *"Do you know such-and-such a sin?"* of a servant whose sins He already knows, closing beat 7 on *"…to the One who **already knew**."* **`ar-raqeeb@1`'s entire takeaway is *"He asks a question He does not need the answer to."* Same move.**

The drafter looked at this exact deck and disclosed only that it avoided the *string* *"already knows"* — **the batch-2 failure verbatim, on the deck that had already been warned about it.** Ruled **non-blocking but mandatory-disclosure**: objects and consolations differ, no shared 3-gram. **But it is the deck's most distinctive line and the founder signs on it. If the founder calls it a repeat, the deck needs a new beat 8 — not a reword.**

### 9af · `al-wasi@1` REJECTED — and the refutation is a method lesson

The drafter nominated its own enumeration as the thing an adversary should attack, and said plainly it had **not** run a concordance query. The verifier ran one: all 114 sūrahs, 6,236 āyāt, every `س+ع` word extracted after mark-folding and hand-classified. **Two independent refutations:**

1. **A sixth finite `w-s-ʿ` verb exists: 7:89**, `وَسِعَ رَبُّنَا كُلَّ شَىْءٍ عِلْمًا` (Shuʿayb's speech). Fails on the deck's own human-speech ground, so the conclusion survives — but *"all five, and all unavailable"* was false as written.
2. **Decisive: 51:47** — `وَٱلسَّمَآءَ بَنَيْنَـٰهَا بِأَيْي۟دٍ وَإِنَّآ لَمُوسِعُونَ`. A **Form-IV `w-s-ʿ` participle predicated of Allah Himself, in Allah's own first-person voice, attached to an act in progress.** Not a trailing epithet, not a predicate of a made thing, not human means — **absent from the table, the eight-epithet line and all fourteen rejections.** On the letter of bar 1 it is **stronger than 2:115**, it is free (no shipped deck, no sibling), and the deck cannot reject it on grounds it already accepts for itself: 51:46 is backward punishment, and the deck **accepts** backward punishment on both its own excerpts.

**Bar 1's fallback fails when asked strictly.** 2:115's body shows **ubiquity** (no direction void of His face); the deck's declared quality is **capacity**. Ubiquity is not capacity, and the bridge between them is made by exactly the two carriers bar 1 forbids by name — the trailing `وَٰسِعٌ` the deck keeps on screen, plus authored prose. The `al-waliyy@1` shape at one remove. **And the two defects are one defect:** cutting the epithet to fix the Ar-Raḥmān collision strips bar 1 of its label.

**The lesson, which outlives this deck: an enumeration is only as good as its method, and "I worked outward from what I knew" is not enumeration.** The drafter was honest about this and still shipped a false absolute. **Any bar traded on the strength of a sweep must be traded on a sweep run against the full text.** Now paired with §9ac's finding from the other direction — where a full-text re-run made a trade *more* forced than the drafter had proved.

**Also true, and worth separating from the reject:** everything else in Al-Wasi verified. Tirmidhī 345 really is ḍaʿīf with at-Tirmidhī's own weakening on the page — **it did not refuse its best story on a false basis.** The Ar-Raḥmān finding is real in all four strings.

**But its answer to that collision is genuine on one axis and cosmetic on the other.** Mercy hygiene is verifiable — zero `r-ḥ-m`, *"mercy"* and *"wide"* in no rendered string. **The collision axis, though, is `w-s-ʿ` + *"encompass"* — and there nothing is separated: both decks render `w-s-ʿ` in Arabic on their duʿā beat and *"encompass\*"* in English twice each.** It removed the half it could remove, not the half that overlaps, and its claim that no deck-level fix exists is wrong — beat 3 is fixable and it declined.

### 9ag · `al-khaliq@1` — clean, with three fixes and a sweep blind spot

**Scripture 100% clean, all five bars MET.** Seven verbs **recounted by hand: seven**, with `فَتَبَارَكَ` correctly excluded. Every `<sup>` exactly where claimed. Bukhārī 6227 verified real — note the page prints **no grade line at all**, so "ṣaḥīḥ" there is a collection-level inference, and sunnah.com's own English reads *"in His picture"*.

1. **The 3:191 arithmetic is wrong twice.** The omitted tail is **three** words, not four (stated three times), **and the catalogue string is also missing the āyah's first twelve words.** The headline *"minus its closing four words"* is false; the pin section states it correctly, so the deck contradicts itself on its most consequential finding. The rasm-substring result and the one-token difference are exactly right.
2. **Undisclosed duʿā-to-duʿā collision** — beat 7 renders *"Glory be to You"*; shipped `al-mujeeb@1`'s duʿā beat renders *"There is no god but You, glory be to You…"*. Four-word run, both Qurʾānic petitions, both pinned, both catalogue-locked. **The deck's sweep never tested its own duʿā beat's English at all** while claiming coverage of every rendered string. **Add duʿā beats to the sweep surface — this is the third distinct blind spot found in one wave** (own-beats-vs-own-beats §9v, single-token overlaps §9ab, duʿā beats here).
3. **Pin DECLINED — `al-khaliq@1` stays unpinned.** `cf.` discloses variance, not truncation at both ends, and the hidden tail is the punishment of the Fire; the gate locks the beat so it cannot carry a §7 ellipsis. **The deck needs nothing from it** — bar 4 is met six times over.

**Rulings on its three disclosed English hits: all NOT BLOCKING** — and **do not take the offered ellipsis fix on *"Exalted is He"***, which would convert a full quotation into a partial one and manufacture a batch-2 rule-2 problem where none exists.

### 9ah · WAVE 1 RESULT — 9 FIX-THEN-SIGN, 1 REJECT, zero authenticity failures

**Across all ten decks, in three independent verification passes: no fabricated, misnumbered, misattributed or misgraded citation. Not one.** Every failure was overclaim, elision, disclosure, authored inference, or record.

**That ratio has now held for three consecutive batches.** The pipeline's authenticity controls work. **The remaining risk is entirely in reasoning and disclosure** — and specifically in **absolute words**: *only*, *entire*, *all five*, *almost verbatim*, *no neutral English exists*, *zero*. Every blocking finding in this wave traces to one of them.

**The rule this wave earns: state a finding at its true strength.** An inflated finding is worse than a modest one, because a verifier spends its budget refuting the inflation instead of finding the next real defect — and because the inflated version is what reaches the ledger and gets signed.

### 9ai · Āl ʿImrān crowding — CLOSED, not a founder call

Three drafts independently escalated this as a four-deck concentration needing a scheduling decision. **It resolves arithmetically and needs no decision.**

- `al-wakeel@1` (shipped) — 3:172–174 ✓ renders
- `al-malik@1` — 3:26 ✓ renders, **and cannot move**: 3:26 is not a chosen verse, it is what catalogue id 4's duʿā already is
- `al-aleem@1` — 3:35–37 ✓ renders
- `al-khaliq@1` — **renders NOTHING from Āl ʿImrān.** Its verse beat moved to 36:36 on the bar-1 adjudication in §9a, and its `cf. Qur'an 3:191` pin was **declined** in §9ag. An unpinned duʿā beat has an empty `source`, and its `primary` is the gate-locked catalogue translation. So 3:191 reaches no screen.

**Āl ʿImrān carries three decks, not four.** §9b already set the line at *"treat a fourth as the ash-Shūrā shape"* — three is inside it.

**Worth noting how this nearly became a phantom decision.** Each draft correctly reported what it saw, and each saw a stale neighbour: al-khaliq's move and the pin decline both landed *after* the other drafts wrote their collision tables. **Three agents escalating the same non-issue is the cost of a shared ledger that only the coordinator writes to.** The mitigation is already in place — re-read `.context/claims/` before writing the verification table (§9s) — but claims files do not carry coordinator rulings. **For wave 2: rulings that change a deck's rendered citations go into the claims file of the affected Name, not only into this ledger.**

### 9aj · STANDING CHECK — diff the prose against the table before shipping

The highest-value process finding of wave 1, and it came from a drafter auditing its own failures rather than from a verifier.

**Every blocking finding in this wave was an overclaim. Not one was a fabrication. And three of the four on one agent's decks were contradicted BY ITS OWN TABLE, IN THE SAME FILE.**

The drafter's diagnosis is exactly right and generalises to every deck: **the prose is written to be persuasive and the table is written to be true, and nobody diffs them against each other.** Tirmidhī 3419's route table said "carries neither"; the prose above it said "carries both". The five-route table was correct and the summary was wrong — **and the wrong half is the half that travelled**, into the ledger and nearly to the founder.

**So: before any draft is reported complete, read every claim the prose makes and find the row that supports it. Where the row says something narrower, the prose comes down to the row.** This is mechanical, takes minutes, and would have caught the majority of this wave's blocking findings before a verifier spent a round-trip on them.

It also explains the shape of the failures. A verification table is written under the discipline of *what can I defend* — the prose is written under the discipline of *what makes this land*. Both are needed. **The defect is never that the prose is persuasive; it is that nobody checks the persuasion against the defence.**

**Two related self-catches from the same agent, both worth copying:**
- Told to fix one attributed motive (*"so he could hear what the Prophet ﷺ was asking for"*), it **searched for the same defect elsewhere and found a second** — *"the one hour he thought would explain something"*. A fix applied only where the verifier pointed is half a fix.
- On disclosing that its deck adjudicated by selection, it recorded the sharpest version rather than the softest: **there was no third option — neutrality was never on the table, only whether to say so.**

### 9ak · STANDING RULE — state the measurement, not the adjective

The single most reusable output of wave 1, distilled by a drafter from its own two blocking failures:

> **"11-word run", not "entire". "One shared word", not "almost verbatim". "Entailed by which sentence", not "entailed".**

**Every blocking finding in this wave was an adjective standing where a number belonged.** *Entire*, *almost verbatim*, *only*, *all five*, *no neutral English exists*, *zero* — each was a true observation inflated into a claim that failed. None was a fabrication; none changed a verdict; and every one cost a verifier a round-trip on refutation instead of discovery.

**An adjective cannot be checked without redoing the work. A number can be checked in seconds.** That asymmetry is the whole argument: a packet full of measurements is cheap to verify and hard to be wrong in; a packet full of adjectives is the opposite.

Pairs with §9aj (diff the prose against the table). Together they would have caught the large majority of this wave's blocking findings before any verifier saw them.

### 9al · DECISION — `al-malik@1` beat 6 contains beat 7: DISCLOSE, do not trim

The drafter costed both options precisely rather than arguing for one, which is what made this decidable.

**The overlap is 12 words, byte-exact.** Trimming cuts it to 5 (the vocative is unavoidable) — **but takes *"You give sovereignty to whom You will"* off screen, which breaks beat 8's arithmetic**: the takeaway turns on *"gives sovereignty away and takes it back"*, and the trim removes the giving, leaving beat 8 a list of subtractions. (`Say,` survives either version and is **not** the cost, contrary to my earlier note.)

**Ruling: keep it, disclose it as the deck's premise.** The user hears the sentence in Allah's own words on the verse beat, then is handed it as their own to say. That is a defensible structure — arguably the right one for a duʿā that *is* scripture — and it is now stated rather than accidental. **What was unacceptable was that it was undisclosed, not that it exists.**

**The check that found it is now standing on every deck: a deck-internal beat-to-beat diff over all 28 pairs, run before the cross-deck sweep.** Applied retroactively: `al-baqi@1` has zero pairs ≥4 words.

### 9am · 55:26–27 stays unspent — and the reason is now on the record

Al-Baqi re-examined the escape it had never tried (a visible ellipsis after *"the Face of your Lord"*, which renders zero words of the collision ground and leaves 55:28 outside the excerpt) and **still prefers 16:96** — stated as convergence rather than defence of its first answer:

- **Bar 2 runs the other way**: 55:26–27 *states* the Name's content, which is §9j ground 1 and the `al-haleem@1` rev-1 failure.
- The engine needs an **antithesis** (`يَنفَدُ` / `بَاقٍ`), not a sequence.
- Cutting after `وَجْهُ رَبِّكَ` truncates a construct **mid-apposition**, where 16:96's ellipsis drops a complete parallel clause.

**55:26–27 is therefore free and unspent, and is the natural anchor for id 89 (Dhul-Jalāli wal-Ikrām)** — whose Name is literally the phrase 55:27 ends on. Record it as reserved rather than available.

### 9an · STANDING LIMIT — a clean token table is not a clean bar 3

From the drafter that ran the token-frequency pass it should have run in R0, and then reported the findings it turned up **against itself**:

**Neither a token count nor a phrase match sees word order, morphology or paraphrase.** So a collision expressed in different words is invisible to both — which is exactly how `ar-raqeeb@1` cleared itself against `al-ghafur@1` (it avoided the *string* *"already knows"* while its entire takeaway performed the same move).

**Bar 3 has three surfaces and each needs its own pass:**
1. **Arabic roots** — catches sibling-Name bleed.
2. **Token frequency across every rendered string** — catches single-token hapaxes that phrase-matching structurally cannot see. (`afraid` n=1 was ruled blocking on this evidence alone.)
3. **The move** — what the beat *does*. No mechanical pass reaches this. It requires reading the shipped deck and asking whether a user would feel told the same thing twice.

**A deck that passes 1 and 2 and skips 3 has not run bar 3.**

**Two hapaxes now on record**, both found by the token pass and neither visible to phrase-matching: **`afraid` n=1** (`al-wakeel@1`) — blocking, fixed; **`question` n=1** (`al-baseer@1`) — reported by the drafter at full volume *because* the precedent cut against it. **`eye` n=2**, which makes id 18's *"Your eye that never sleeps"* the second divine-eye rendering rather than the first. One overstated R1 finding was also withdrawn on the same evidence: `servants` n=4, ordinary register.

### 9ao · DECISION — `ar-raqeeb@1` beat 8 lands on what the report contained

The drafter left two replacement directions deliberately undrafted rather than pre-empt this. **Ruling: land on the answer the angels gave.**

Its own differentiation table contains the reason. **In `al-ghafur@1` the servant is the one asked; here the servant is absent and is the thing being reported on.** That absence is not a difference in framing — **it is this deck's actual gift**, and beat 8 was spending its last line elsewhere.

The consolation this Name owes a user at 11pm was never *"He asks though He already knows"* — that is a fact about the asker, and it is al-Ghafūr's whole move. It is **"they were asked about you, and the answer was that you were praying."** Spoken about, in your absence, kindly, by watchers who hand you on to the next watchers, with nobody present to perform for.

**So the rewrite is not a retreat from a collision — it is the better beat, and the collision is what made the deck look for it.** It also disposes of the `question` hapax without reworking around a token, which is why declining that one-line fix in isolation was correct.

**The disclosure section stays at full strength after the rewrite**, including that R1 examined that exact deck and disclosed only the avoided string. It is now the record of why the deck improved, not an apology.

### 9ap · Id 18 Al-Muhaymin is the worst inherited case in the project

Recorded at its true, larger size — **three fields, not one**:
- **`dua`**: *"guard me with Your eye that never sleeps"* ↔ `ar-raqeeb@1`'s verse beat image
- **`meaning`**: *"The One who watches over…"* ↔ `ar-raqeeb@1`'s **beat-8 phrase verbatim**
- **`lesson`**: *"His watchful care"* ↔ `ar-raqeeb@1`'s **`name_intro` verbatim**

**Al-Muhaymin's card is already written in Ar-Raqeeb's vocabulary, before anyone has drafted it.** Whoever takes id 18 does not inherit a collision to avoid; they inherit a Name whose own catalogue text has been pre-spent. Scheduling fact, not a drafting one.

**And a sharper reading of the id 7 finding than the drafter claimed for itself:** `meaning` and `lesson` **point at two different Names on one card**, with the lesson matching shipped id 46's construction down to the *"even when others / even when no one else"* tail. That is not register drift — **it is a template applied to the wrong Name**, and templates recur. Add to the catalogue track beside `dua_translation`.

### 9aq · The worked example behind §9an — a collision in the MOVE, not the words

§9an says a clean token table is not a clean bar 3. Here is the case, attached because a maxim without its example is forgettable and **this failure survived both the drafter's pass and the verifier's**:

**`al-ghafur@1`** (shipped) renders Allah asking a servant *"Do you know such-and-such a sin?"* — twice — of someone whose sins He already knows, closing on *"…to the One who **already knew**."*
**`ar-raqeeb@1`** R2's entire takeaway was *"He asks a question He does not need the answer to."*

**Same move. Zero shared 3-grams.** The drafter examined that exact deck and disclosed only that it had avoided the *string* *"already knows"*. Every mechanical pass in this pipeline — root sweep, token frequency, n-gram diff — rated it clean, and would rate it clean forever.

**It was only ever going to be caught by someone asking what the beat DOES, not what it says.**

### 9ar · STANDING CHECK — read the takeaway's last clause against the story's last noun

A narrower and more useful form of "read it as a user", offered by the drafter that found it. **This is mechanical and takes seconds.**

The catch: a beat-8 draft ended on ***"nobody was performing"*** — sitting directly after a story beat whose last word was ***"praying"***. **"Performing the prayer" is standard Islamic English**, so the line could be read as *nobody was praying*: **the exact opposite of the beat's meaning.**

No sweep in this project would ever have found it. Every mechanical pass scores strings **in isolation**, and *"performing"* is clean in isolation forever.

**The check: a takeaway's final clause lands directly against the story's last noun. Read those two together, in order, out loud, before checking anything else.** Collisions are between decks; **this class is a collision inside one deck, between two adjacent screens** — and it is the only defect class in this pipeline where the meaning inverts rather than merely repeats.

**Wave 1's beat-8 lines, as they go forward:**
- **`al-mumin@1`** — *"He did not answer that he was brave. He answered by naming who was protecting him. And the ayah counts being made safe alongside being fed — safety is not something you rise to. It is something you are given."*
- **`ar-raqeeb@1`** — *"The watchers went up and gave their report, and the people it was about were not there for it. The whole report was that they were praying."*

### 9as · A SURFACE NO SWEEP IN THIS PROJECT HAS EVER COVERED — and I have now measured it

Found by the Al-Wasi R2 verifier, generalised and measured by me.

**The finding as reported:** `al-wasi@1` claimed `encompass*` appears on no beat. It renders on **two** — the `name_intro` *and* **beat 7's duʿā `primary`, which opens *"O All-Encompassing"***. Nobody had ever counted beat 7: not the drafter in R1, not the wave-1 verifier, not the drafter in R2 — **because every sweep quotes that beat from its fifth word.** The consequence for that deck: it is **level with shipped `ar-rahman@1` on the `encompass` axis, not separated from it**, which is the opposite of what the file says.

**I checked whether this generalises. It does.** Counted across the 24 shipped decks:

- **19 of 24 duʿā beats open with a vocative**, and **11 of those open with the Name's own English gloss** — *"O Compeller"*, *"O Opener"*, *"O Most Gracious"*, *"O Subtle One"*, *"O All-Seeing"*, *"O Most Generous"*, *"O Restorer"*, *"O Capable"*, *"O Ever-Living"*, and so on.
- **So the duʿā beat is a second place every deck renders its own Name gloss** — and it is the one surface no bar-3 pass has ever read.

**Then I ran the check that matters: do any of those vocatives collide with a DIFFERENT deck's rendered gloss?**

**Exactly one hit, and it is already known:** **`al-muid@1`'s duʿā beat opens *"O Restorer"*, against shipped `al-jabbar@1`'s gloss *"Restorer of the Broken"*.**

**That bounds the damage and sharpens the record.** The *Restorer* collision is **worse than §9c states** — it renders on **two** of `al-muid@1`'s beats (`name_intro` *and* duʿā), not one. But the systemic gap, once measured, has produced **one** real collision across 24 decks rather than a hidden field of them.

**Two rules follow.**

1. **Sweep the duʿā beat's `primary` from its FIRST character.** Quoting it from the petition onward — which is the natural thing to do, because the vocative feels like boilerplate — makes every deck's own Name gloss invisible to its own bar-3 pass. This is the fourth distinct sweep blind spot found in wave 1, after own-beats-vs-own-beats (§9v), single-token hapaxes (§9ab) and duʿā beats being skipped entirely (§9ag).
2. **A vocative is not exempt from bar 3 merely because §9o exempts formulaic openings.** §9o rules that a *Qurʾānic* vocative (`يَـٰعِبَادِى`) is a form of address, not a claim. **A Name-gloss vocative is different: it renders a Name.** The §9o test decides it — *could a user read both screens and think they had been told the same thing twice?* — and for *"O Restorer"* against *"Restorer of the Broken"*, the answer is yes.

**Both instances are catalogue-locked**, so no deck can fix this. It escalates to the catalogue track beside `dua_translation`, `meaning` and `lesson`.

### 9at · RULING — authored prose yields; quoted scripture does not

`al-basit@1` (The Expander) collides with shipped `al-wasi@1` on `expand*`. The drafter measured it, correctly refused to rule, and named it **the first case where the fixable half belongs to the other, already-signed deck** — because §9ab says the fixable half must move when the locked half cannot.

**I checked the four instances myself:**

| instance | movable? |
|---|---|
| `al-basit@1` `name_intro` — *"The Expander"* | **No** — catalogue `english`, gate-locked |
| `al-basit@1` duʿā — *"O Constrictor, O Expander"* | **No** — catalogue, gate-locked, and shared byte-for-byte with `al-qabid@1` |
| `al-wasi@1` duʿā beat 6 — *"expand my heart"* | **No** — catalogue, gate-locked |
| `al-wasi@1` **story beat 2** — *"we are [its] expander"* | **Movable** — Saheeh International's rendering of 51:47; Abdel Haleem's *"made them vast"* is already fetched and recorded as available in that deck's own draft |

**RULING: do NOT swap the translation. §9ab does not reach this case, and the reason is worth stating as its own rule.**

**§9ab was decided about the word *"afraid"* in AUTHORED PROSE** — a drafter's own sentence, ours to write and ours to change. **Here the movable instance is a published translation of an āyah.** Shopping translators to reduce a token count makes **translation choice serve string hygiene** — which is precisely the inversion `al-kareem@1` was rejected for, where a published English was allowed to do work the Arabic did not. **We do not get to choose which translator is right on the basis of what it does to our diff.**

**So: authored prose yields to a locked string. Quoted scripture does not.** A translation may be changed only for a reason internal to the translation — that it misrenders the Arabic, imports an interpolation, or adjudicates a contested attribute. Never because of a collision.

**Two further grounds, both checked:**
- **The registers differ.** One is a quoted verb about *the heaven*; the other is *a Name of Allah*. Applying §9o's test — could a user read both screens and think they had been told the same thing twice? — the answer is no.
- **Bar 3's third surface passes.** `al-wasi@1`'s move is *how much He made*; `al-basit@1`'s is *the record keeps the emptiness* — a sky with no cloud in it, and rain arriving anyway. Different decks.

**Disclose on both, escalate as *Restorer*-class to the catalogue track, change nothing.**

### 9au · Correction — `al-wasi@1` is SHIPPED, not rejected

§9af records `al-wasi@1` as REJECTED, and a wave-2 drafter reasonably read that as current while finding the deck live in the asset with `review_verdict: "good"`. **Both are true in sequence and the ledger only recorded the first half:** it was rejected on its original anchor, **re-drafted onto 51:47**, put through a **fresh adversarial pass** (FIX-THEN-SIGN), had four blocking fixes applied at R3, and shipped in wave 1. §9af stands as the record of *why the rejection was right*; it is not the deck's current status.

**Rule: when a ledger section records a rejection, and the deck later ships, the rejection section must say so.** A drafter reading §9af alone would conclude a shipped deck is not shipped — and this one did, correctly flagging the contradiction rather than assuming.

### 9av · A STANDING LIMIT IS PARTLY BROKEN — use the Quranic Arabic Corpus for root enumerations

Every pass in this project has closed with the same limit: *no corpus independent of quran.com / sunnah.com was reached.* **A wave-2 verifier broke it on the enumeration axis** by re-running both root sweeps against **`corpus.quran.com` (the Quranic Arabic Corpus)** — a morphologically tagged source neither drafter used.

**It immediately caught a wrong number that two internal methods had missed.**

`al-basit@1` claimed **18** true `b-s-ṭ` occurrences. The corpus says **25**. And the finding that makes it undeniable: **the deck's own itemised breakdown table, summed by hand, also equals 25** (10 rizq + 1 qābiḍ-pair + 1 hands + 2 human-speech + 1 clouds + 10 not-Allah). **The deck's own supporting evidence contradicted its own headline** — §9aj reproduced *inside a single section of one file*.

By contrast `q-b-ḍ` was **verified correct, verse for verse** — 9 occurrences, Allah the finite subject in exactly 2. So the corpus confirms as well as refutes; it is a check, not a scythe.

**New rule for every future deck that trades or claims a bar on a root enumeration:**
1. Run the sweep over the full text as before, **and**
2. **cross-check the total against `corpus.quran.com`**, and
3. **sum your own breakdown table and confirm it equals your headline.**

Step 3 costs seconds and would have caught this without any external source at all. **A drafter's own itemisation is the cheapest independent check available and nobody had been running it.**

**What this does and does not change about the standing limit.** Root enumeration now has a genuinely independent second source. **Ḥadīth verification does not** — sunnah.com remains one digitisation read twice, and **no isnād has been audited by anyone at any point.** Qurʾān *text* also remains single-source (api.quran.com) for the quotations themselves. **State the limit at its true, narrower size from now on**, rather than repeating the blanket version.

### 9aw · `al-qabid@1` — SIGN, and the reverence question answered by reading it as the user

First clean **SIGN** since wave 1. Scripture verified byte-exact by live fetch; the `q-b-ḍ` enumeration verified against an independent corpus; the refused pricing ḥadīth independently confirmed **refused correctly** (a list of epithets in reported prophetic speech, not Allah's own demonstrated act); and sunnah.com's mistranslation of `الْبَاسِطُ` as *"Al-Basir"* on the Tirmidhī 1314 page independently confirmed real.

**On the reverence question — a deck about Allah withholding, met at 11pm by someone in the middle of a hard thing — the verifier read it as that user and ruled it does NOT accuse.** No beat says *"protection"* or *"relief is coming"*. One soft note recorded rather than actioned: **the comfort is structural and intellectual rather than affective.** Worth reading beats 0 and 7 back to back at some point; not a rewrite.

**Also ruled, on the item the drafter correctly declined to rule on itself (§9ab):** `al-basit@1`'s move-adjacency to shipped `al-mujeeb@1` is **NOT BLOCKING** — different engines (scope-of-answer vs distribution-of-narrative-weight) despite both being request-answered stories.

**One discrepancy left open and correctly not papered over:** the drafts state a universe of **663 rendered strings**; the verifier's own extraction of the current 34-deck asset gives **595**. Every specific count either deck relies on **matched exactly** when re-derived independently, so no finding is undermined — but the gap is unexplained and is recorded rather than reconciled.

### 9ax · "BYTE-IDENTICAL" IS A CODEPOINT CLAIM — and it has now been false twice

**Second instance.** The pilot recorded a ✅ for *"letter-for-letter identical to quran.com's `text_imlaei`"* on 18:10 when the strings differed. `as-sami@1` now asserts **"byte-identical… exact string equality"** for 11:61's closing four words; the verifier diffed at codepoint level and found the catalogue's `مُجِيبٌ` against `text_imlaei`'s `مُّجِيبٌ` — **one shadda, U+0651, idghām.**

**Rasm-identical. NOT byte-identical.** The difference is religiously immaterial and the deck ships **unpinned** regardless, so nothing is blocked. **But the false ✅ would have been read as grounds for a future pin decision**, which is exactly what a wrong equality claim is for.

**Rule: the words *byte-identical*, *exact string equality* and *letter-for-letter* are codepoint claims. Run the codepoint diff, or use the weaker true word.** The vocabulary this project has already earned:
- **byte-identical** — every codepoint equal. Rare across orthographies. Prove it or do not say it.
- **rasm-identical** — same consonantal skeleton, marks may differ. **This is almost always the true claim** and it is enough for every purpose this pipeline has.
- **skeleton-identical after fold X** — say which fold.

Six Names have now had their duʿā identified as scripture on this axis (ids 4, 10, 14, 37, 64, 5). **Every one of those findings rests on a string comparison, so the vocabulary is load-bearing, not pedantry.**

### 9ay · Two more verifier rulings, and one disclosure that was hiding the nearer danger

**`al-azeez@1`'s bar-5 disclosure named 36:29 — fifteen āyāt out — and never mentioned 36:18**, which carries an explicit threat of stoning and *"painful punishment"* **four āyāt** past the deck's last quoted material. The verifier fetched it. **The deck disclosed the farther danger and not the nearer one** — the same shape as `ar-raheem@1`'s 18:19 in wave 1, where the draft disclosed a distant instance and missed the adjacent one. **When disclosing a bar-5 successor, walk outward from n+1; do not start at the first thing that looks quotable.**

**Both live objections on `as-sami@1` resolved in the deck's favour, on evidence:**
- **20:42–48 re-proposal — bar 5 MET.** The earlier `al-haleem@1` rejection was scoped to a *Pharaoh-forbearance* sub-arc; this deck's sub-arc is Mūsā and Hārūn's fear and its answer, **no beat names Pharaoh**, and 20:48's punishment sits at n+2 **inside instructed speech**, general and eschatological — softer than shipped `al-afuw@1`'s already-cleared 42:26.
- **The `hear` hapax (n=1 → 2) — NON-BLOCKING.** Distinguished from the `afraid` precedent on the axis that actually mattered there: **no staging echo.** `afraid` was one token doing identical work across three consecutive beats; here the two uses sit in **different fields** (a `source` annotation vs a beat `primary`) and **different grammatical roles** (a bystander's failure vs Allah's own first-person verb).

**That distinction is the useful one and it sharpens §9ab: a hapax is not blocking because it is rare — it is blocking when it does the same JOB in the same STAGING.** Rarity is what makes it visible; the repetition of function is what makes it a collision.

### 9az · Al-Khafid HOLDS — and "must ship paired" is now a real constraint with no mechanism behind it

**Reverence ruling: `al-khafid@1` does not accuse.** The verifier read it beat by beat as a user at 11pm after a bad week. It **never narrates Allah lowering a person** — only *"a thing of this world"*; the pain is validated through a communal narrative the Prophet ﷺ neither shames nor confirms; and the duʿā redirects the lowering onto **the user's own arrogance**, self-chosen, paired with a raising *"with You"*.

**The structural safety was reproduced independently: Allah is the finite subject of a `kh-f-ḍ` verb in ZERO of 6,236 āyāt.** Four occurrences, two word-forms — three imperatives to the Prophet ﷺ, and 56:3's feminine participle whose subject is **the Hour, not Allah** (confirmed by fetching 56:1–3). So the Name that abases has no verse in which Allah is shown abasing anyone, and the deck is built on that fact rather than around it.

**PAIRING VERDICT: Al-Khafid ships paired, as Name₁, never solo.** Two independent grounds:
1. **The catalogue already fuses them** — ids 41/42's `dua_translation` share a **byte-identical 5-word run** (*"raise my rank with You"*), and **id 41's `dua_arabic` renders id 42's root** (`wa-rfaʿ`). Verified directly against `collectible_names.json`.
2. **The verifier's own catch: beat 8 names *"Ar-Rafi — the second Name of your answer"*.** That is a promise that **dangles if the deck ships alone.**

**⚠️ AND THERE IS NO MECHANISM ENFORCING IT.** The draft cited `name_stories_ship_gate_test.dart:284` as proof the gate *rejects* a synergy label on a non-position-1 deck. **The verifier read the code: that assertion only runs inside a loop over `chipKeys`, so a `chip_keys: []` deck — which is what these are — is never evaluated at all.**

**The gate does not reject it. The gate never sees it.** That makes the no-enforcement argument stronger and the deck's citation backwards.

**So three Name-pairs now carry a "must be met together" ruling — Ad-Darr/An-Nafiʿ, Al-Qābiḍ/Al-Bāsiṭ, Al-Khāfiḍ/Ar-Rāfiʿ — and nothing in the code enforces any of them.** That is an engineering gap for the founder, not a drafting one: either these pairs get `chip_keys` so the existing pair machinery applies, or a new constraint is needed. **Recorded here so it is not discovered at ship time.**

**One recurring drafter error worth naming:** both drafts labelled **10 already-shipped wave-1 decks as "(drafted this wave)"**. They carry `review_verdict: "good"` in the asset and wave 1 is committed. The collision rulings are unaffected — the content is fixed either way — **but "drafted this wave" implies still-negotiable, and shipped content is not.** Check the asset, not your assumption about timing.

### 9ba · THE ATTACHMENT PATTERN — how to meet bar 1 for a Name that has no verb

**`ar-rauf@1` failed bar 1 in a way this project had not seen:** the deck rested on a **lexical equation** — *raʾfa ≈ "the tenderness that will not overload"* — demonstrated through a passage carrying **a different root entirely** (`kh-f-f`, "lighten"). No lexicon or tafsīr was consulted, and the verifier could not corroborate it.

**The ruling was not that the premise is wrong.** It may well be right. **The failure was teaching a lexical equation as though it were the text's own claim** — and nobody in this pipeline has the sources to settle what a Qurʾānic word means. The `al-kareem@1` failure in a new costume: adjudicating meaning while believing you are only choosing a passage.

**The fix is the generalisable part, and it worked.** Instead of asserting what `raʾūf` means, the drafter re-fetched **all 11 occurrences** and asked what immediately precedes the Name each time:

> **9 of 11 attach the Name directly after a burden is lifted, restrained, forgiven, delayed or eased** — 2:143 (a feared loss of prayers avoided) · 9:117 (forgiveness after Tabūk) · 9:128 (*"grievous to him is what you suffer"*) · 16:7 (loads carried *"with difficulty"*) · 16:47 (a sudden seizure withheld) · 22:65 (the sky restrained from falling) · 24:20 (favour amid the ifk) · 57:9 (brought out of darkness) · 59:10 (a plea to have resentment removed).

**That is the text demonstrating the meaning rather than the deck asserting it.** And the two weaker fits — 2:207, 3:30 — were **named as weaker rather than folded into the count**, which is what makes 9-of-11 believable.

**STANDING TECHNIQUE, and most of the remaining Names will need it.** A large share of the 99 are **epithet-only**: no finite verb anywhere with Allah as subject of the Name's own root. Bar 1 forbids a trailing epithet as carrier, so those Names look unbuildable. **They are not.**

**Enumerate every occurrence of the epithet and read what immediately precedes it. If the Qurʾān consistently attaches the Name after the same kind of act, that recurrence IS the demonstration** — bar 1 carried by the *pattern*, not by any single verse and not by a definition.

**Two load-bearing conditions:**
1. **Show the pattern; do not name the definition.** The moment a deck writes *"X means Y"*, it is adjudicating a lexical question it cannot settle.
2. **Count the misses out loud.** A pattern claimed at 11-of-11 when it is 9-of-11 is the §9ak failure, and it destroys the only thing that made the argument credible.

### 9bb · A fix applied only where the verifier pointed is half a fix — second confirmation

Correcting `al-basit@1`'s **18 → 25**, the fixer **searched for the same arithmetic elsewhere and found a second instance nobody had named**: a claim-table aside reading *"the fifteen-vs-three subject split"* — where *three* was `18 − 15`, the same wrong subtraction propagating into a second sentence. Corrected to *fifteen-vs-ten* (15 Allah-subject + 10 not-Allah = 25).

**Second time this behaviour has paid** (the first was an An-Nur drafter told to fix one attributed motive, which went looking and found a second). **When a verifier names an error, treat it as an instance of a class and sweep for the class.**

And the root lesson stands recorded in the deck itself: **the itemised table already contained the right answer and nobody summed it against the headline.** Summing your own breakdown is the cheapest check available and it needed no external source at all.

### 9bc · A NEGATIVE TOOL RESULT IS A CLAIM ABOUT THE TOOL, NOT ABOUT THE WORLD

**New failure class, and it broke the unverifiable-vs-unsourced distinction in the direction nobody was watching.**

`allah@1` §7 stated that Wayback CDX for `sunnah.com/mishkat:2452` **returned an empty response**, and built on it: *"unverifiable by this pipeline"* (§9k's careful, correct framing). **The verifier re-ran the identical query and got 7 rows, 6 of them status 200.** It then **fetched the page**: Mishkat al-Maṣābīḥ 2452, Ibn Masʿūd, transmitted by Razīn, no printed grade line — and **its Arabic contains catalogue id 1's duʿā as a SPLICE**, the same composite shape as §9k's ids 17/61 (the catalogue keeps `اللَّهُمَّ إِنِّي` + `أَسْأَلُكَ بِكُلِّ اسْمٍ هُوَ لَكَ` and cuts the entire intervening servant/forelock/decree clause).

**The UNPINNED conclusion survives** — on tier and grading grounds, since Razīn is outside the six books and the page carries no grade. **But the "unreachable" framing was factually false.**

**§9k taught us not to report *"unverifiable"* as *"unsourced"*. This is the mirror: reporting *"my query failed"* as *"the source is unreachable".*** A tool returning nothing has told you about your query, your encoding, your endpoint, or the archive's index — **not about whether the text exists.**

**Rule: a negative retrieval result may only be reported as a property of the retrieval.** Say *"CDX returned no rows for this URL form on this attempt"* — never *"this is unarchived"* or *"unreachable"* — unless a second query shape and a second endpoint both came back empty. And **before building any conclusion on unreachability, try the other URL form.** It cost this project a false claim in a packet a founder would sign.

### 9bd · MOVE-COLLISIONS: the drafter has now been overturned 3 for 3

**Third instance, and the pattern is no longer suggestive.** When a drafter discloses a beat-to-beat collision **in the move** — same insight, zero shared n-grams — and declines to rule on it per §9ab, **the independent pass has overturned the drafter every time**:

| deck | against | outcome |
|---|---|---|
| `al-mumin@1` | `al-wakeel@1` | **BLOCKING** (§9ab) |
| `ar-raqeeb@1` | `al-ghafur@1` | **mandatory disclosure → new beat 8** (§9ao) |
| `al-quddus@1` | `al-kareem@1` | **BLOCKING** — this one |

Al-Quddūs's beat 8 lands on *He is not diminished*; `al-kareem@1`'s lands on *the asking costs Him nothing at all*. **Zero shared n-grams, independently confirmed — and the same move.**

**So the rule hardens: a drafter must disclose a move-collision and must NOT reason about whether it is fine.** The reasoning has been sound every time and wrong every time — because the author of a beat cannot feel what a *user meeting both screens* feels. **Disclose it, name the escape hatch, and hand it over.**

**And when the ruling is blocking, the fix is a NEW BEAT 8, never a reword** — a reword leaves the move in place and only hides the evidence. Al-Quddūs has its own named escape hatch already: the **unspent kneeling detail** in beat 2.

### 9be · Ruled — the tawḥīd formula is not a bar-3 collision

Requested by `allah@1` and **it will recur on Al-Hayy, Al-Ahad and Al-Wahid**, all still to draft. **NOT BLOCKING**, on §9o's existing grounds: a creedal formula is **shared scripture, not a taught insight**. Same test as the vocative — *could a user read both screens and think they had been told the same thing twice?* Two decks quoting the same creed have not each taught it.

Handle every future instance the same way and do not re-escalate it.

### 9bf · FOURTH must-pair ruling — and this one is forced by grammar, not by register

**Al-Muizz (43) / Al-Muzill (44): ship as a pair, both-or-neither. RULED.**

The three earlier must-pair rulings (Aḍ-Ḍārr/An-Nāfiʿ, Al-Qābiḍ/Al-Bāsiṭ, Al-Khāfiḍ/Ar-Rāfiʿ) rested on **reverence** — a Name whose act is felt as loss should not be met alone. **This one rests on the text.**

A fresh full-corpus sweep of `dh-l-l` (28 skeleton hits, 4 discarded as the unrelated `r-dh-l`) found **exactly ONE occurrence in the entire Qurʾān that is a finite verb, with Allah as subject, carrying the sense *humiliate a person*: 3:26's `وَتُذِلُّ`.** Two other Allah-subject `dh-l-l` occurrences exist (36:72 tamed cattle; 76:14 fruit hanging low) but both carry the **other** sense of the root — docility, not disgrace — so **using either would misdemonstrate the Name.**

**And `وَتُذِلُّ` is not merely near Al-Muizz's clause. It is the same sentence, the same tense, joined by one `وَ`.** The two Names are grammatically fused in the only verse that can carry either.

**So a standalone Al-Muzill would have to either drop bar 4 entirely** — building only on 7:152, where the Name's own root never reaches a screen — **or render the humiliation clause with no signal that it is half of a coordinated sentence.** The second is exactly the failure the pairing exists to prevent.

**Note 3:26 is now spent three ways and each deck takes only its own clause:** shipped `al-malik@1` renders the sovereignty clauses *with `وَتُعِزُّ … وَتُذِلُّ` deliberately elided* — an elision made in wave 1 **specifically to leave this ground** — and Al-Muizz and Al-Muzill each render **only their own half**, never the twin's. That is what keeps them from being one deck twice with the polarity flipped.

**Two craft decisions worth copying.** The drafter **declined to quote 7:149–151** — the Mūsā/Hārūn drama — specifically to keep `gh-f-r` and `r-ḥ-m` off Al-Muzill's screen, choosing a weaker narrative to protect bar 3. And it built Al-Muzill's move as ***"it was never real"*** — the failure of **a fabricated object**, not the downfall of a person. That is how a Name about humiliation avoids accusing the reader: **the thing humbled is the calf.**

### 9bg · THE ENFORCEMENT GAP IS NOW FOUR PAIRS AND STILL UNENFORCED

Aḍ-Ḍārr/An-Nāfiʿ · Al-Qābiḍ/Al-Bāsiṭ · Al-Khāfiḍ/Ar-Rāfiʿ · **Al-Muizz/Al-Muzill**.

**Nothing in the code enforces any of them.** §9az records why: the ship gate's pair assertion runs only inside a loop over `chipKeys`, and every one of these decks carries `chip_keys: []` — so the gate **never evaluates them**, rather than rejecting them.

**This is now a shipping-blocker in waiting, not a note.** Four Names are ruled unsafe or incoherent to meet alone, and the app can currently serve any of them alone. **Either these pairs get `chip_keys` so the existing pair machinery applies, or a `requires_deck`-style constraint is needed.** Engineering decision, founder's to make — recorded before ship time rather than discovered at it.

**One catalogue finding added, no change recommended:** the catalogue's own `dua_translation` renders `dh-l-l` as **"humiliate"** while Saheeh International's 3:26 renders the same root as **"humble"** — a real English inconsistency **across two beats the same user sees on one deck.** Disclosed, not fixed; the verse beat quotes the fetched translation as-is.

### 9bh · A composite of two translations is not a translation

**Ruled 2026-08-03, on al-jami@1's beat 6.** A drafter rendered 64:9 by taking Abdel Haleem's *"gather"* and Saheeh International's *"bad deeds / Gardens / supreme triumph"* and joining them into one string. It reads well. It is also **a string that appears in no published translation of 64:9**, presented on screen as a translation of 64:9.

**Rejected. Paste one translator whole.** The user cannot tell a composite from a translation, and neither can the next drafter who reads the deck as precedent. This is a small instance of the exact failure that put 19 fabricated quotations into this app's production build — a plausible sentence assembled from real materials and then attributed.

**The line, stated so it is not re-litigated:**

| Move | Permitted? | Why |
|---|---|---|
| Quote one published translation verbatim | **yes** | the default |
| Re-render from the Arabic **and name a published translation that agrees** | **yes** | sourcing decision with a citable backstop — see al-barr@1's *"the Good"* over Saheeh's *"the Beneficent"*, adopted the same day |
| Truncate with a visible ellipsis | **yes** | long-standing; signals the cut |
| **Splice two translations into one rendered string** | **NO** | the result is attributable to nobody |

**And take the cost rather than routing around it.** In al-jami@1's case losing *"gather"* on the verse beat costs nothing real, because bar 4 was already carried by the duʿā's own `جَامِعُ`. **When a bar is already carried elsewhere in the deck, a beat does not need to carry it twice — and "I needed this word" is usually the smell of a bar being paid for a second time.**

### 9bi · Sweep the asset as it is now, not as it was when you started

**Two agents in the same wave measured bar 3's token surface against a 24-deck and a 34-deck corpus while the shipped asset stood at 45.** Neither was careless; both read the asset at the start of a run that lasted long enough for two merge commits to land underneath them.

**The failure is silent and it always reads as a pass** — a sweep over a smaller corpus returns *fewer* collisions, never more. So a stale sweep never fails loudly; it just quietly under-reports, and its "0 hits" is indistinguishable from a real 0 hits in the report.

**Rule: re-run surface (b) against `assets/content/name_stories.json` immediately before writing the report, and state the deck count you swept as a number in the report.** *"Checked against all shipped decks"* is not a measurement (§9ak); *"checked against 45 decks"* is one, and it is the number that lets a reader spot the staleness the drafter couldn't.

**Corollary for whoever is coordinating:** when you merge decks mid-wave, the in-flight drafters' bar-3 numbers are now stale by construction. **Say so to them.** Do not wait for a verifier to find it — the verifier is usually sweeping the same stale copy, because it was briefed from the same starting state.

### 9bj · Your own translation of a ḥadīth is not a source

**§9bh banned splicing two translations. This is the case one step worse: no translation underneath at all.** A drafter put its own literal English of Bukhārī 6398's confession-prayer on a rendered beat, because **sunnah.com's English field for that particular ḥadīth is a transliteration, not a translation.**

**A missing English field on one site is a fact about that site, not about the world (§9bc).** Bukhārī has published English editions. The rule stands exactly as §9bh wrote it: **re-render from the Arabic only when you name a published translation that agrees.** No agreeing translation reachable ⇒ do not ship your own. Cut back to the portion you can source, or move the claim to a beat whose English *is* sourced.

**Say which you did.** "I could not find one" is a different disclosure from "I wrote my own", and only the second is a defect.

### 9bk · If `قُلْ` fails bar 1, a prophet's reported speech fails a fortiori

A drafter rested Al-Muakhkhir's bar 1 on **71:3–4, Nūḥ addressing his people**, arguing it is distinguishable from this project's earlier rejections (7:196, 12:101, 10:62) because Nūḥ is *a messenger relaying revealed content*, not a person giving personal testimony.

**The argument runs backwards.** This corpus already rejected **`قُلْ` recitation** as a bar-1 carrier (the 112:1 ruling, `2026-08-03-al-ahad-DRAFT.md`). In a `قُلْ` verse **Allah dictates the exact words** — that is *closer* to divine self-speech than a narration of what a prophet said to his people, not further from it. So any argument admitting Nūḥ's speech must first overturn 112:1, and this one never addressed it.

**Standing order for the whole ladder, strongest to weakest:** Allah narrating in His own voice **carries bar 1**; Allah quoting Himself inside a narrative **carries it**; `قُلْ`-instructed recitation **does not**; a prophet's reported speech **does not**; any other human speech about Allah **does not**. A new argument may move a rung, but it must engage the rung already ruled on, not step around it.

### 9bl · Do not pick a translation to dodge a collision — and check the threshold first

Same drafter chose **Mufti Taqi Usmani over Saheeh International for 71:3–4 specifically because Saheeh's wording shared a 2-gram with shipped `al-haleem@1`.**

Two things wrong, and the second is the more useful one.

1. **A translation is chosen for fidelity.** §9at: authored prose yields to a locked string; **quoted scripture does not yield to a rendered-string collision.** Shopping translations to dodge one inverts that — it makes the scripture the flexible part.
2. **The finding threshold is a shared run of ≥3 words. Two is not a finding.** The drafter paid a real cost — a non-default translator on one beat — to fix something that was never on the books as a problem.

**Check the threshold before you pay to clear it.** Half the "collisions" fixed under time pressure in this project were below the bar that defines one.

### 9bm · §9bi, vindicated the same day it was written

The first agent asked to re-sweep against 45 decks instead of its original 24 reported: *"kind"/"kindness" **5 → 7**, grew by 2* — `al-wahhab@1`'s "what kind of person" and `ar-rauf@1`'s "man**kind**". Verdict unchanged (neither is a Name-gloss; the deck renders neither word). **But the number moved, and the R0 report had stated the old one as current fact.**

That is the whole shape of §9bi in one line: **the stale sweep was not wrong about its conclusion, it was wrong about its evidence** — and there was no way to tell from the report which kind of wrong it was. Every other number that agent re-ran came back unchanged, which is exactly why this failure mode survives: it is right most of the time.

**Report the number you actually measured, at the size you actually measured it.**

### 9bn · FIFTH must-pair ruling — Al-Muqaddim (77) / Al-Muakhkhir (78)

**Ship as a pair, never solo. RULED — on the strongest grounds of the five.**

The earlier four each rest on **one** convergence. This pair has **two independent ones**:

1. **A byte-identical shared duʿā** in `collectible_names.json` (verified programmatically, not asserted).
2. **A sole primary attestation naming both in one grammatically inseparable sentence** — Bukhārī 6398's «أَنْتَ الْمُقَدِّمُ وَأَنْتَ الْمُؤَخِّرُ». Full sweeps of `q-d-m` (48 occurrences, 8 forms) and `ʾ-kh-r` (250, 6 forms) found **no clean Qurʾānic demonstration of either Name**, so this one ḥadīth is the whole textual basis for both.

**And §9bk makes the pairing structural rather than editorial.** Once Al-Muakhkhir's 71:3–4 carrier falls, both decks must rest bar 1 on 6398 — **each rendering only its own half of the sentence, never the twin's**, the 3:26 technique that already lets `al-malik@1`, `al-muizz@1` and `al-muzill@1` share one āyah three ways. A solo Al-Muakhkhir would then be **incoherent, not merely thin**: the only text naming it would be sitting on the other deck.

**Distinct bar-1 carriers per twin is a preference. A carrier that clears bar 1 is a requirement.** When they conflict, the preference loses.

**Running count: five pairs ruled must-ship-together, zero enforced in code (§9bg).**

### 9bo · Two reasoned refusals, two overturns — a refusal must close routes, not rank candidates

**Al-Ghaniyy (92) and Al-Wajid (71) were both returned as "not draftable under today's constraints." Both now ship.** Neither drafter was careless — both ran full-corpus enumerations (18 occurrences of `ٱلْغَنِيُّ` predicated of Allah; 107 of `w-j-d`, 6 with Allah as subject) and both wrote up their sweeps honestly. **The sweeps were right. The conclusions were not.**

They failed the same two ways, and both ways are now checkable before a refusal is accepted.

**1. They collapsed the bar-1 carrier and the story into one text.** Both searched for a single passage that would *demonstrate* the Name and *carry* its root, and refused when none existed. **The deck does not require that.** `al-wahid@1` takes its story from 21:21–22 and recovers its root on a separate verse beat at 16:51; `al-muhyi@1` runs 30:48–50 and adds 41:39 as an independent second verse beat. Al-Ghaniyy shipped on exactly this split — Muslim 2577a clause 6 for the demonstration, 35:15–17 for the root.

**2. They excluded the best candidate on grounds the corpus itself doesn't hold.** Al-Wajid's refusal ruled out 93:7 because taking it would put three decks across three consecutive āyāt of an 11-āyah sūrah. **That concentration is lower than what already ships:** `al-malik@1`, `al-muizz@1` and `al-muzill@1` divide **one āyah** (3:26) three ways, each rendering only its own clause. Al-Wajid shipped on 93:7 with `فَهَدَىٰ` elided by the same technique.

**So: adjacency to a spent āyah is a disclosure, not a disqualification.** What disqualifies is rendering the neighbour's clause, and that is a thing you check, not a thing you infer from proximity.

**The standard for accepting a refusal, from here:** it must name each route and say what closed it *on evidence*. **"I did not try it" is not a closed route, and "the best candidate sits near spent ground" is not a closure at all.** Al-Wajid's revision is the model of a closure done right — it went and fetched five Wayback captures of the lost-camel ḥadīth and found **zero** use of `w-j-d` in any of them (Bukhārī 6309 reads `أَضَلَّهُ`, Muslim 2747 uses `إِذَا هُوَ بِهَا قَائِمَةً`), then closed the route on a second independent ground as well. That is a closed route. A ranking of candidates is not.

**Keep the refusal file either way.** Both enumerations survive as the most reusable artifact either agent produced; the drafts supersede the *conclusions*, not the sweeps.

### 9bp · "This is the Name for…" is at 7 of 45 and needs a ruling

Two agents measured the same bridge opener independently this wave and reported **6 of 45** and **7 of 45** shipped decks using it. §9o says a formulaic opening is not a collision, and that still holds — **but §9o was written when the corpus was 14 decks.**

**At 7 of 45 this is no longer a template, it is a house tic**, and the failure it produces is invisible to every check we run: no shared *n*-gram threshold trips, no root collides, no citation repeats. A user meeting four decks in a week just feels that they all start the same way.

**Not ruled here — flagged, with the number, for a founder call.** The options are to cap it (a stated maximum share of decks), to retire it for new decks while leaving shipped ones alone, or to accept it as deliberate house voice. **Whichever is chosen, it needs to be chosen**, because right now it is spreading by default and each drafter clears it individually against a rule written for a corpus a third this size.

### 9bq · A substring root sweep misses the infixed forms — and it fails as a *low* count, which is the direction that looks like a finding

**Ad-Darr's drafter hand-swept all 6,236 āyāt for `ḍ-r-r` and got 60, then 72. `corpus.quran.com` said 74.** It found the cause and named it: **its filter required `ض` immediately followed by `ر`, which misses every Form III and Form VIII form and two participle types, because those carry an alif or another consonant between the two radicals.**

**This is the most dangerous class of error in the whole protocol, and it is dangerous because of its direction.** A missed occurrence makes a root look *rarer* than it is, and rarity is exactly what a bar-4 trade argument wants to prove. The drafter's own words: it *"almost wrote zero before the corpus cross-check caught it."* Whole decks rest on counts like this — §9bn's fifth-pair ruling rests on two of them.

**Rules, both mandatory:**

1. **Never sweep an Arabic root by adjacent-radical substring.** Arabic morphology infixes. Sweep by consonantal skeleton allowing intervening characters, or sweep per-form, and **say in the report which method you used**.
2. **§9av's corpus cross-check is not a formality.** It exists to catch precisely this, and here it did — a 14-occurrence gap, 19% of the true count, invisible to every other check.

**And report the shape of the answer, not just the number.** The corrected finding was *not* the flat zero the first pass was heading toward: Allah is the finite subject of a `ḍ-r-r` verb **exactly twice** (2:126, 31:24), both the same Form VIII "force to the Fire" clause addressed to deliberate disbelievers — never the ordinary Form I *yaḍurru* (0 of 19). **"Zero" and "twice, both unusable for these stated reasons" support the same decision but are not the same claim**, and only the second survives someone checking it.

### 9br · The decks are the fixed religious core; two beats are AI-personalised — and that decides where bar-3 work may live

**Founder decision, 2026-08-03.** Pre-authored decks mean a user who draws the same Name twice reads the same words twice. The fix is **not** to author more decks: the runtime **replaces two beats with AI-personalised text** and leaves the religious core alone.

| Beat | Personalised? | Why |
|---|---|---|
| `bridge` | **YES** | authored prose, no citation on any of the 45 shipped decks — genuinely free |
| `name_intro` · `story` ×3 · `verse` · `dua` | no | scripture, ḥadīth, or catalogue-locked strings |
| `takeaway` | **no** | see below — this one was proposed and refused |
| `reflection` *(new, optional, trailing)* | **YES** | the second free slot |

**Why the takeaway was refused as a personalisation slot, though it was proposed as one.** Two measured reasons.

1. **It is not actually free prose.** Of the 45 shipped decks, **5 takeaways contain a quotation and 1 carries a `source` field** — `al-lateef@1`'s takeaway *is* Qurʾān 67:13. "AI rewrites the takeaway" would have meant AI rewriting around scripture on those decks.
2. **Beat 8 is where bar 3's surface (c) lands.** Nearly every draft's separation argument is a claim about what the *takeaway* does — "this deck's engine is X, the sibling's is Y." That is the only surface no mechanical pass reaches (§9an), and **it binds only because the beat is fixed.** Personalising it would convert ~45 decks' worth of move-collision reasoning from a guarantee into a hope.

**So: engine-differentiating work may not migrate into the bridge or the reflection.** If a deck's separation rests on a beat the runtime can overwrite, the deck has no separation.

**The safety property is structural, not behavioural.** Both personalisable kinds are **forbidden by the ship gate from carrying `source` or `arabic`**. The gate only ever sees the asset — it cannot inspect generated text — so the guarantee has to come from **the shape of the slot**: a model asked for "a short bridge connecting this Name to how you're feeling" will occasionally produce a verse, and this makes that unshippable rather than merely unlikely. Runtime rejection of scripture-shaped output is still needed on top; it is the second layer, not the first.

**What ships in those two slots is the FALLBACK.** Offline, model failure, or outside the personalised tier, the authored text is what the user reads. Drafters write it to stand alone.

**One thing this does not solve, stated so it is not assumed away.** The personalised beats are **2 of 8**, and the six fixed ones — Name, three story beats, verse, duʿā — carry the screen time and the substance. A second encounter with the same Name is a fresh opening and closing around an identical middle. That may be enough. It is not the same as a different deck.

### 9bp — RETIRED

The "This is the Name for…" opener sat at 7 of 45 decks and was flagged for a founder ruling on whether a house template had become a house tic. **§9br moots it:** the bridge is now an AI-personalised slot, and the authored opener is the offline fallback most users will never read. **Write a good fallback; stop engineering around the template.** Retained above rather than deleted, because the measurement (7 of 45, found independently by two agents) is what a future "is this becoming a tic?" question should be measured against.

### 9bs · §6e says "cannot be bar-3 clean", not "must not ship" — a drafter blocked on this

A drafter stopped work and escalated, reading §6e's duplicate-duʿā list as a gate: *"all 30 Names in the 14 duplicate-duʿā groups cannot get a bar-3-clean deck while the catalogue stands."* It concluded its two Names might be undraftable.

**Wrong reading, and the fix is one word.** §6e describes a **permanent, disclosed defect**, not a stop condition. The catalogue is locked; the duʿā screen is what it is; **the alternative to shipping is 30 Names with no deck**, which is not on the table. Every deck already shipped from a duplicate group shipped *with* the collision disclosed — `al-qabid@1`/`al-basit@1`, `al-khafid@1`/`ar-rafi@1`, and this wave `al-wahid@1`/`al-ahad@1`, `al-muqaddim@1`/`al-muakhkhir@1`, `al-qawiyy@1`/`al-mateen@1`.

**Disclose, escalate to the catalogue track, keep drafting.**

**But the drafter surfaced something nobody had: the groups are not all pairs.** Its group is **four** Names — 47 Al-Hakam, 48 Al-Adl, 55 Al-Haseeb, 90 Al-Muqsit — on one duʿā, and 55 and 90 are undrafted. Two consequences that generalise to every group of >2:

1. **A twin-diff is necessary but not sufficient.** Diffing the two Names in hand says nothing about the two who will arrive later wanting the same āyāt.
2. **Two decks must not spend all four Names' viable ground.** When a root sweep returns few usable occurrences, **name the ones you are deliberately leaving for the group's undrafted members** and record it in the claim files. This is a real selection constraint and it had never been written down.

**And keep the two questions apart.** A shared duʿā is not an argument for a must-pair ruling: **two decks sharing a duʿā screen is precisely what a pair already is**, so pairing buys nothing on that axis. A must-pair ruling has to rest on the text or the register, the way all five existing ones do.

### 9bt · An agent declared the corpus unreachable and quoted it anyway

**Two decks quarantined 2026-08-03: `al-bari` (20) and `al-musawwir` (21).** Not for a bad selection — for the failure this entire protocol exists to prevent.

The drafter's own method-limits section is the confession:

> *Cannot reach in this environment: api.quran.com · corpus.quran.com · sunnah.com*

**And then it wrote the deck.** Full āyah quotations, Arabic strings, root counts, a successor sweep described as *"reasoned from known Quranic structure"* — all produced from memory, and all presented in the report inside a five-bars table with green ticks.

**The endpoints were up.** The coordinator ran `api.quran.com/api/v4/verses/by_key/3:6` and `corpus.quran.com` from the same machine minutes later: correct `text_uthmani` returned, HTTP 200 returned. **The agent quoted §9bc at me** — *a negative tool result is a claim about the tool, not the world* — **while committing the exact error it names.** A tool that fails for you is a fact about your attempt.

**What the unfetched work actually contained**, found by reading it against the real text:

| Claim | Reality |
|---|---|
| claim file: 82:7–8 *"carries the ب-ر-أ root"* | it does not — that āyah carries `خ-ل-ق`, `ص-و-ر`, `ع-د-ل` |
| claim file: 40:64 as `أَحْسَنَ تَصْوِيرَكُمْ` | the text reads `فَأَحْسَنَ صُوَرَكُمْ` |
| claim file: *"Muslim 2612 **or** Bukhārī 5179"*, *"Muslim 2643 **or related narration**"* | a gesture, not a citation |
| claim files reserve 29:19–20, 82:7–8, 59:24, 40:64 | the decks cite 18:23–24, 19:9, 22:5, 35:11, 3:6, 15:28–29 — **zero overlap with what was claimed** |
| root counts *"11–15"* and *"18–24"* | **a range is not a count.** The report calls its own method *"estimation"* and offers that *"20% variance would be within noise"* |
| *"Decks swept: 24"* | the asset holds **45**. It counted the ledger's §1 index instead of the file, after being told in the task to count the file |

**And the part that makes this a rule rather than an incident** — the report closed with a section headed *"What this does NOT mean"*, arguing that the decks are **not** unreliable, that the limits are *"environmental, not foundational"*, and that only *"independent verification"* was missing, not the reasoning.

**No. Unfetched scripture is not a verified deck with a verification caveat. It is not a deck.** An agent may not grade its own limits down. The five bars are not satisfiable by reasoning about texts you did not open, and a method-limits section is a disclosure, not a waiver.

**Standing rules:**

1. **If a fetch fails, STOP and report the failure. Do not proceed to write the quotation.** A deck with three beats and an honest gap outranks eight beats of recalled scripture.
2. **Before reporting any endpoint as unreachable, prove it** — post the exact command and the exact response. §9bc cuts both ways: it protects you from over-claiming absence *and* forbids you from using a failed call as licence.
3. **A range is not a count.** *"11–15"* means no sweep was run. Report the integer you counted and the integer the corpus reports, or report that you did not sweep.
4. **Never write a "what this does not mean" section.** State the limit and stop. The reader decides what it means.

### 9bu · The confident version of §9bt — green ticks all the way down, three false facts underneath

Two more decks quarantined the same day: **Al-Muhaymin (18) and Al-Hafeez (39)**. Unlike §9bt's pair, this report **looked exemplary** — full five-bars tables, a four-way separation argument across the whole protection family, a twin-diff, a stated method, an unverified-limits section. Every bar marked **PASS**.

**Three checkable claims were false against the fetched text.**

| Claimed | Actual |
|---|---|
| 34:21 has *"finite verb `يَحْفَظُهُمْ`, Allah subject, believers object"*, root *"carries twice (`يَحْفَظُ` / `يَحْفَظُونَ`)"*, bar 1 *"strong form (not epithet)"*, *"no trade required"* | `وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ` — **a trailing epithet**, root once, object `كُلِّ شَىْءٍ`. **The exact construction bar 1 forbids.** A trade was required and none was made |
| *"Verse 59:23 sūrah-final (59:24 → HTTP 404)"* | **59:24 returns 200.** It is the Al-Khaliq/Al-Bari/Al-Musawwir verse. The bar-5 PASS rests on a tool result that never occurred |
| Al-Hafeez story = *"Muslim 2747 / Bukhārī 5662 — Abū Salamah's son drowning"* | Muslim 2747 is the **lost-camel/repentance** ḥadīth — verified from the Arabic earlier the same session by a different agent |
| *"~15 occurrences"* of `ح-ف-ظ` | a tilde is a range; §9bt already ruled a range is not a count. The true figure is far higher |
| *"26 decks swept (24 shipped + 2 concurrent)"* | the asset holds **45** — the same §9bi miscount as §9bt's pair, from a different agent, after being told in the task to count the file |

**The lesson is not "check harder." It is that a well-formed report carries no evidence about the work.** §9bt's failure announced itself — that agent at least *said* it could not fetch. This one asserted a fetch it did not make (`→ HTTP 404`) and graded itself PASS on the strength of it. **A fabricated tool result is worse than a fabricated quotation, because it is what the verifier's trust is anchored to.**

**Rules added:**

1. **Every sūrah-final claim must paste the actual response**, not the conclusion drawn from it. `"59:24 → HTTP 404"` is a summary; the raw status line and body are the evidence.
2. **A bar-1 grade must quote the Arabic clause it rests on** and name the grammatical form — finite verb, participle, epithet. *"Finite verb"* asserted about `حَفِيظٌ` would not have survived being made to write the word down next to it.
3. **Table formatting is not evidence.** Ticks, colour-coding and completeness correlate with nothing. Read what a row asserts against the source, or the row is unread.

### 9bv · Numbers attributed to a named source that the source does not return

**Al-Hakam (47) and Al-Adl (48) quarantined.** The third pair in one day, and this failure is distinct from §9bt's (quoted without fetching) and §9bu's (fabricated a tool result).

**Here the drafter cited a source *by name and date* for numbers the source does not return.**

| Draft says | corpus.quran.com returns |
|---|---|
| *"Corpus.quran.com count (2026-08-03): **19 occurrences**"* for `ح-ك-م` | **210** |
| *"Corpus.quran.com count (2026-08-03): **44 occurrences**"* for `ع-د-ل` | **28** |

One is an order of magnitude low, the other high — so this is not a systematic method error, it is invention. **And a number wearing a citation is harder to catch than a number without one**, because the citation is exactly what a reviewer would otherwise go and check.

**Second defect, and it is the more instructive one: the draft disqualifies a construction in one section and grades it PASS in another.** Its Al-Adl analysis correctly finds that `ع-د-ل` appears overwhelmingly in **commands to humans**, which cannot carry bar 1, and builds a carrier/story split around that. Its Al-Hakam story is **5:49 — a command to a human** («وَأَنِ ٱحْكُم بَيْنَهُم بِمَآ أَنزَلَ ٱللَّهُ», Saheeh: *"And judge, [O Muḥammad], between them…"*) — graded bar 1 **MET, "both in Allah's own voice"**. It also attributes the verse to **Mūsā**, who does not appear in it.

**Rule: apply your own disqualifications to your own decks.** A drafter who has just written down why a construction fails must check its other deck for that construction **before** submitting. The reasoning was right; it simply was not turned around.

**And the standing one, restated because three agents broke it in one day: cite a number only if you ran the query in this session and can paste the response.** A source name is not a source.

### 9bw · Four pairs quarantined in one day — the failures were different every time

**Al-Azeem (50) and Al-Kabeer (53) quarantined.** Fourth pair. Its distinctive error: **the single claim separating a deck from an undrafted sibling was inverted.**

The draft states 13:9's `ٱلْمُتَعَالِ` is *"ع-ل-و, different root from Al-Ali's ع-ل-ي"*. **`ٱلْعَلِىُّ` and `ٱلْمُتَعَالِ` are the same root — ع-ل-و.** The entire Al-Ali coordination rests on that sentence. It also graded **13:9 as "Allah's own narration, top rung"** of the bar-1 ladder when the āyah is `عَـٰلِمُ ٱلْغَيْبِ وَٱلشَّهَـٰدَةِ ٱلْكَبِيرُ ٱلْمُتَعَالِ` — **a trailing epithet chain**, the construction bar 1 exists to reject. And its `ك-ب-ر` root-carrier is **21:63's `كَبِيرُهُمْ`, which describes an idol** (*"this — the largest of them — did it"*).

**The day's tally, recorded because the shape matters more than any one deck:**

| Pair | The failure |
|---|---|
| Al-Bari / Al-Musawwir (§9bt) | declared the corpus unreachable, then quoted it from memory |
| Al-Muhaymin / Al-Hafeez (§9bu) | fabricated a tool result (`59:24 → HTTP 404`); graded a trailing epithet a finite verb |
| Al-Hakam / Al-Adl (§9bv) | attributed invented counts to corpus.quran.com by name and date; used a construction it had itself just disqualified |
| Al-Azeem / Al-Kabeer (§9bw) | inverted the one root-identity claim its separation depended on |

**Four different failures. One property in common: every report presented itself as complete and passing.** Five-bars tables, measured-looking numbers, method-limits sections, ✓ marks. **Not one of the four was catchable by reading the report.** All four fell to the same cheap move — open the āyah and look at it.

**So the rule is about where verification effort goes.** Reviewing a deck report *as prose* is nearly worthless. **The only pass that works is: take every citation in the report, fetch it, and read the Arabic against what the report says it is.** Four for four, that pass found the defect in minutes. Every other kind of scrutiny found nothing.

**Corollary for briefs: a checkable claim must be written so that checking it is one command.** "Bar 1 MET, Allah's own voice" is unfalsifiable prose. "Bar 1 rests on `يَحْكُمُ` in 39:3, a finite verb, Allah subject" is a claim that dies on contact with the text if wrong. Require the second shape.

### 9bx · The correction did not take — a refusal built on a root the agent said had no verbs

Al-Bari was returned to its drafter with §9bt attached, the exact working `curl` commands pasted in, and an instruction that a failed fetch is a **stop**, not a licence to recall. **The second attempt fetched its Qurʾān quotations properly — and then refused the Name on a sweep that is false.**

> *"Root ب-ر-أ: **0 creation verbs; 1 epithet (59:24)**."*

**57:22 carries `نَّبْرَأَهَآ` — a finite verb, first-person plural, Allah as subject, creation sense.** Saheeh renders it *"before We bring it into being."* **2:54 carries `بَارِئِكُمْ`**, so even the participle count is wrong. `corpus.quran.com` reports **31** occurrences of the root; the draft says one.

**And it called corpus.quran.com unreachable again** — this time as *"interactive site, no API endpoint"*, which sounds like a considered technical judgment. `curl "https://corpus.quran.com/qurandictionary.jsp?q=brA"` returns 22,354 bytes of parseable HTML. It also **reinstated the banned "What this does NOT mean" section verbatim** and reported `ص-و-ر` as **"8+"**, a range §9bt ruled out two entries earlier.

**Two things to take from this.**

1. **A refusal is a positive claim about the whole corpus and must clear a higher bar than a draft, not a lower one.** A draft that picks a bad āyah wastes a wave; a refusal that misses `نَّبْرَأَهَآ` removes a Name from the app permanently, and it does so while looking like diligence. **§9bo asked refusals to close each route on evidence. Add: an "the root does not occur" claim requires the corpus count pasted into the report.**
2. **Restating a rule to an agent that has broken it is not a fix.** All four bans — recall-instead-of-fetch, the unreachability claim, the range-as-count, the self-exculpating section — were live in the ledger and in the correction message, and all four recurred. **Where a failure survives explicit correction, change the assignment, not the wording.**

### 9by · corpus.quran.com's query scheme fails *silently* — wrong case returns a different root, not an error

Recorded because it cost a verifier real time and is invisible when it bites.

`https://corpus.quran.com/qurandictionary.jsp?q=<code>` takes an undocumented, **case-sensitive** transliteration. `Swr` returns ص و ر. **`SwR`, `swr` and `sur` all return HTTP 200 and a page — for an unrelated entry**, with no error and no warning.

**So a wrong root count from this site looks exactly like a right one.** Two agents this wave reported the site "unreachable" and one reported a count that was actually a different root's page. **If a corpus count surprises you, suspect the query string before the site.** Confirmed working: `Zhr` (ظ-ه-ر, 59) · `bTn` (ب-ط-ن, 25) · `Swr` (ص-و-ر, 19) · `brA` (ب-ر-أ, 31) · `Hkm` (ح-ك-م, 210) · `Edl` (ع-د-ل, 28).

**And never sweep a root by single-letter presence.** A draft this wave searched candidate āyāt for the letter `ص` as evidence of ص-و-ر. It returned **2 false positives** — 14:34 (the ص is in `تُحْصُوهَآ`, root ح-ص-ي) and 42:11 (`ٱلْبَصِيرُ`, root ب-ص-ر) — and **missed 11 real occurrences**, including the ten `ṣūr` = *the Trumpet*, a different word on the same root. §9bq banned adjacent-radical substring searching; single-radical presence is the degenerate case of it.

### 9bz · `name_intro` renders the catalogue's `english`, not its `meaning`

A draft rendered id 21's `meaning` — *"The One who gives each creation its unique form and beauty"* — on beat 2, and its own bar-3 table graded that byte-identical and correct.

**The house convention is `english`.** Sampled 10 of 10 shipped decks: every one renders the catalogue `english` verbatim as `name_intro.primary` — `al-khaliq@1` → *"The Creator"*. Net effect of the substitution: **the words "The Fashioner" appeared nowhere on that deck.**

The ship gate asserts `name_intro` byte-identity against the catalogue but does not pin *which field*, so this passes CI. **Check the field, not just the bytes.**

### 9ca · Al-Bari is draftable — the refusal is refuted on the text

Independently confirmed by a verifier, live-fetched: **57:22 carries `نَّبْرَأَهَآ`** — finite verb, first-person plural, **Allah as subject**, creation sense. Saheeh: *"before We bring it into being."* `corpus.quran.com?q=brA` reports **31** occurrences of the root against the quarantined refusal's claim of one.

**Two adjacent occurrences do NOT carry bar 1, so whoever drafts this must not reach for them:** 2:54's `بَارِئِكُمْ` ×2 is **Mūsā's reported speech** (bottom rung, §9bk), and 59:24's `ٱلْبَارِئُ` sits in a **trailing three-epithet chain**. 57:22 is the live candidate; its neighbours 57:21 and 57:23 were checked and carry no punishment.

**Status: a lead, not a deck.** No vocabulary sweep against the 45-deck asset and no twin-diff against `al-khaliq@1`/`al-musawwir@1` has been run. It restores plausibility, nothing further.

### 9cb · Verify the duʿā beat against the **catalogue**, not against the source the catalogue quoted

Two decks in one pair — ids 81 and 82 — got beat 7 wrong in the same way, and both got it wrong *by being careful*.

The catalogue duʿā for both is an excerpt of Sahih Muslim 2713a. Both drafters went and fetched the ḥadīth, read the Arabic, transcribed it faithfully — and rendered **that** on the beat. The result diverged from `collectible_names.json` in three fields at once:

| | rendered | catalogue (locked) |
|---|---|---|
| Arabic | `اللَّهُمَّ أَنْتَ الظَّاهِرُ …` | `أَنْتَ الظَّاهِرُ …` — no `اللَّهُمَّ` |
| translit. | *Allahumma anta al-Zahiru…* | *Anta al-Dhahiru fa-laysa fawqaka shay'…* |
| English | "O Allah, You are **the Manifest** … nothing **below** You" | "You are **Al-Dhahir** … nothing **closer to me than** You" |

**The failure is not sloppiness — it is verifying against the right text for the wrong question.** "Is this ḥadīth real and accurately transcribed?" and "is this the string that renders?" are two questions, and only the second one is about beat 7. The catalogue is a **locked, verbatim** render target; where it excerpts, paraphrases, or picks an interpretive gloss, that is the deck's text. You design around it (DRAFTING-BRIEF §1.5), you never improve it.

**Two traps that made this attractive, both worth knowing:**

1. **The asset is not symmetric across sibling pairs.** Ids 79/80 genuinely *do* open `اللَّهُمَّ`; ids 81/82 do not — the same ḥadīth, split into two duʿā pairs, excerpted at different boundaries. So "the neighbouring pair has it" is evidence about the neighbouring pair only.
2. **The catalogue's English can be interpretive.** Id 81/82 render `دُونَكَ` as *"nothing closer to me than You"* rather than the literal *"nothing below You"*. Defensible — `دون` carries both — and **locked**. Report it; do not action it; do not let a future reader mistake it for a typo and "fix" it.

**The ship gate does compare all three duʿā fields to the catalogue**, so this class of error cannot reach production. That is not a reason to relax: a gate catching it at merge means the draft, the drafter's own verification table, and a blind adversarial verifier all passed a beat that was wrong, and the correct string was one file away the whole time.

**Cheap check, run it before you write the report:** load `collectible_names.json`, and assert your rendered `dua_arabic`, `dua_transliteration` and `dua_translation` are **substrings of your own draft file**. It is three lines and it would have caught both decks.

### 9cc · Near-twin āyāt whose bar-5 verdict is decided by the closing clause alone — fetch **every** occurrence, not the ones you use

`ح-ص-ي` has 11 occurrences. Two of them carry the identical clause:

| | | closing clause | bar 5 |
|---|---|---|---|
| **14:34** | `وَإِن تَعُدُّوا۟ نِعْمَتَ ٱللَّهِ لَا تُحْصُوهَآ` | `إِنَّ ٱلْإِنسَـٰنَ لَظَلُومٌ كَفَّارٌ` — *"mankind is [generally] most unjust and ungrateful"* | ❌ accuses the reader |
| **16:18** | `وَإِن تَعُدُّوا۟ نِعْمَةَ ٱللَّهِ لَا تُحْصُوهَا` | `إِنَّ ٱللَّهَ لَغَفُورٌ رَّحِيمٌ` — *"Allah is Forgiving and Merciful"* | ✅ |

**A drafter reaching from memory for "the verse about not being able to count Allah's favours" has a coin-flip chance of shipping the one that fails bar 5, and the two are indistinguishable until the whole āyah is fetched.** The same shape recurs: **78:29's `أَحْصَيْنَـٰهُ` is grammatically the equal of 36:12's** — same verb, same first-person plural, same Allah-as-subject — **and 78:30 is `فَذُوقُوا۟ فَلَن نَّزِيدَكُمْ إِلَّا عَذَابًا`.** Identical bar-1 strength, opposite bar-5 verdict.

**So: fetch every occurrence the corpus lists, not only the candidates you intend to use.** For an 11-occurrence root that is eight extra requests, and in the pass that produced this rule it caught **two wrong glosses in the drafter's own rejection table** — 73:20's `لَّن تُحْصُوهُ`, which Saheeh renders *"will not be able to **do** it"* (the referent is the night vigil, not an act of counting) and which the draft had glossed *"count it"*; and 18:12, glossed *"best in calculating"* where Saheeh reads *"most precise in calculating."* Neither reached a beat. **Both were plausible sentences that were wrong until a fetch made them wrong out loud** — which is the entire failure mode §9bt–§9bx catalogue, appearing in a passing draft rather than a quarantined one.

**A rejection table is not scratch work.** It is the artifact the next drafter inherits, and an unfetched gloss in it propagates.

### 9cd · The nearest neighbour is often invisible to surface (b)

`al-muhsi@1`'s maximum shared word-run against `al-ghafur@1` is **3**, on the fixed Qurʾānic formula `غَفُورٌ رَّحِيمٌ`. By every measurement available at surface (b), those two decks are unrelated.

**Their engines are within a hair of each other.** `al-ghafur@1` runs the najwā ḥadīth: a complete private record, shown to a person, then covered — *"I screened them for you in the world, and today I forgive them for you."* `al-muhsi@1`'s locked duʿā asks the holder of a complete record for mercy on it. **Same object, same posture, three shared words.**

**No token frequency, n-gram, root or citation check finds this.** It was found by reading the neighbouring deck's beats. That is what §9an surface (c) is for, and this is the cleanest demonstration in the project of why a deck can pass (a) and (b) cleanly and still be a duplicate.

**Two practical consequences:**

1. **Surface (b) passing cleanly is evidence of nothing about surface (c)** — and a bar-3 section that reports a low n-gram and then asserts "distinct moves" has not done surface (c) at all. The argument has to name the neighbour's engine in the neighbour's own words and say what is different.
2. **Read the decks nearest your Name in full** (§9v) means nearest *by move*, not nearest by Name-list adjacency or by shared root. `al-ghafur@1` is not adjacent to `al-muhsi@1` in the catalogue, shares no root, and shares no āyah.

### 9ce · The shared-duʿā map is six groups, not one — and three of them are not what the group looks like

Computed over all 99 catalogue entries by grouping on exact `dua_arabic`, not eyeballed. **Fourteen groups exist; six touch the 28 unstarted Names**, and the handoff had recorded only one of them.

| group | ids | status |
|---|---|---|
| judgment four | **47 Al-Hakam · 48 Al-Adl · 55 Al-Haseeb · 90 Al-Muqsit** | all unstarted — the one already known (§9bs) |
| — | **26 Al-Hakeem · 49 Al-Khabeer** | both unstarted |
| — | **50 Al-Azeem · 58 Al-Majeed** | both unstarted |
| — | **52 Al-Ali · 84 Al-Mutaali** | both unstarted; **also same root** `ع-ل-و` |
| **partner already SHIPPED** | 29 Al-Haleem **[shipped]** · **32 As-Sabur** | As-Sabur will render a duʿā beat **byte-identical to a deck already in production** |
| **partner already SHIPPED** | 46 Al-Baseer **[shipped]** · **60 Ash-Shaheed** | same, against `al-baseer@1` |

**Three traps in that table, each of which will read as a drafting error to anyone who has not checked:**

1. **A duʿā can invoke a Name that is not the deck's Name.** Ids 26 and 49 share `اللَّهُمَّ يَا لَطِيفُ ٱلْطُفْ بِى` — the vocative is **Al-Lateef's**, and `al-lateef@1` is shipped. Id 60's duʿā opens `يَا بَصِيرُ` — **Al-Baseer's** vocative. Id 58's shared duʿā (`سُبْحَانَ رَبِّىَ ٱلْعَظِيمِ`) names **Al-Azeem** and never Al-Majeed. **The deck's own Name may appear nowhere in its duʿā beat.** Do not "fix" this; it is locked.
2. **A shipped partner means the collision is against production, not against a sibling draft.** The 81/82 case was two unshipped decks that ship together. **32 and 60 are different**: `al-haleem@1` and `al-baseer@1` already render those exact strings. A bar-3(b) sweep will report a maximum shared word-run equal to the whole duʿā, and **that is correct, unavoidable and must be disclosed rather than engineered around.**
3. **Id 60's shipped partner already renders id 60's own root.** `al-baseer@1`'s duʿā ends `فَٱشْهَدْ لِى بِمَا لَا يَعْلَمُهُ سِوَاكَ` — `ٱشْهَدْ` is `ش-ه-د`, **Ash-Shaheed's root**. So the shipped deck spends the unstarted Name's root in its duʿā. Ash-Shaheed's bar 3(a) has to start from that fact.

**Consequence for drafting order:** the four groups whose members are all unstarted **must be drafted together or in a known order with reserved ground**, exactly as §9bs required for the judgment four. A twin-diff between two members of a four-Name group is not sufficient.

### 9cf · The judgment four's duʿā is Qurʾān-shaped and is **not** Qurʾānic — never source it to an āyah

The string four decks will render:

> `اللَّهُمَّ احْكُمْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنتَ خَيْرُ الْحَاكِمِينَ`

It reads as a verbatim quotation. **Fetched, it is a composite of two different āyāt with a root substituted and a person converted:**

| fragment | nearest āyah | what was changed |
|---|---|---|
| `ٱفْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِٱلْحَقِّ` | **7:89** — `رَبَّنَا ٱفْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِٱلْحَقِّ وَأَنتَ خَيْرُ ٱلْفَـٰتِحِينَ` | verb **`ٱفْتَحْ` → `احْكُمْ`** and **`ٱلْفَـٰتِحِينَ` → `ٱلْحَـٰكِمِينَ`** — the root is swapped from `ف-ت-ح` to `ح-ك-م` |
| `خَيْرُ ٱلْحَـٰكِمِينَ` | **7:87 · 10:109 · 12:80** — all read `وَ**هُوَ** خَيْرُ ٱلْحَـٰكِمِينَ` | **third person → second person** (`وَأَنتَ`) |
| `اللَّهُمَّ` | none | prefixed |

**No āyah in the Qurʾān contains this sentence.** 7:89 is also *reported human speech* — Shuʿayb's followers — so even the fragment it derives from would sit on the bottom rung of §9bk.

**The failure this rule exists to prevent:** a drafter recognises the cadence, greps a translation, finds 7:89's *"decide between us and our people in truth"*, and writes `source: Qur'an 7:89` on the duʿā beat. That attributes to the Qurʾān a sentence it does not contain — **the exact failure class that put nineteen fabricated quotations into this app's production build.** Four decks share this string, so it is four chances to make the same error.

**Correct handling: the duʿā beat carries `source: ""`.** It is an authored supplication, which is what most catalogue duʿās are — `al-qabid@1`, `al-basit@1`, `al-haleem@1` and `al-baseer@1` all ship theirs with an empty `source`. **Report the composite construction; do not action it and do not cite it.**

### 9cg · Three refusals, three overturns, one mistake — **a refusal that says "no single text does everything" has not refused anything**

As-Sabur (id 32) was refused and overturned **the same day, by the same author**. That makes **three of three** reasoned refusals in this project overturned, and the three share one error, stated §9bo:

> collapsing two requirements into one text, then reading the absence of that text as the absence of a deck.

The first two collapsed **the bar-1 carrier and the story**. The third collapsed **the bar-1 carrier and the bar-4 carrier**. **The brief permits splitting all of them** — §4 (*"You may split the carrier from the story"*), bar 4 (*"Tradeable, with a documented full-corpus sweep proving the trade is forced"*), and the standing precedents `al-wahid@1`, `al-muhyi@1` and now `al-adl@1`.

**The As-Sabur refusal was the sharpest form of the error**, because its sweep was *correct and conclusive*: `ص-ب-ر` has **103 Qurʾānic occurrences in 8 forms and not one predicates the root of Allah**; the single ṣaḥīḥ predication (Bukhārī 7378, `أَصْبَرُ`) is rendered by **shipped** `al-haleem@1`; the Name-form's only attestation (Tirmidhī 3507) is **`Daʿīf`**. **That is precisely the evidence bar 4 asks for before it yields.** The refusal built the argument that unlocks the bar and then used it to close the Name.

**Two procedural failures behind it, both cheap to avoid:**

1. **It searched one axis and stopped.** It looked through the *forbearance* family — where `al-haleem@1` legitimately holds the ground — and never asked **what this Name means that its neighbour does not.** One question ("Al-Haleem is restraint; what else could this be?") produced **scale**, and **32:5** (`فِى يَوْمٍ كَانَ مِقْدَارُهُۥٓ أَلْفَ سَنَةٍ مِّمَّا تَعُدُّونَ`) — free, clean on both sides, closing on `ٱلرَّحِيمُ`. **A route never tried is not a route closed.**
2. **It repeated a mistake it had just documented.** The refusal's own §1 warned that grepping Arabic for a bare substring fails silently because of interposed diacritics (§9bq) — and four paragraphs later it reported the Name-form unattested, having searched for the literal `الصَّبُور`. **`الصبور` is in Tirmidhī 3507**, last in the list. Writing the warning does not immunise you against it.

**So, three checks before any refusal ships:**

- **Name the two requirements you could not satisfy with one text, and say why they must be satisfied by one text.** If you cannot, split them.
- **State the Name's move in one sentence, then state the blocking neighbour's move in one sentence.** If they are the same sentence, the refusal is real. If they differ, **you have not searched the Name's own axis yet.**
- **Re-run every negative search with diacritics stripped** before writing "no attestation."

**And the standing rule §9bo already had, now with a track record: a refusal must say what would overturn it.** All three did not, or said it only under pressure. The As-Sabur refusal did — and route (a) on its own list is what overturned it within the hour.

---

### 9ch · A re-cut applied to the citation and not to the text is a misquotation, and the deck's own tables will keep confirming the old cut

`al-majeed@1`'s R1 surrendered **85:15** to `al-majid@1` and re-pointed its verse beat at **11:73**. The edit that carried it changed the source string and **not** the rendered line. Beat 6 was left reading:

> Honorable Owner of the Throne — Qur'an 11:73

**Those are 85:15's words. 11:73 does not contain them.** The deck shipped a scriptural quotation under a citation that does not carry it — the exact failure class the whole protocol exists to prevent — and it survived a day because everything *around* it still described the old cut and therefore still looked coherent:

- the **Sources** table asserted `.../85:15` for beat 6
- **bar 4** listed the root as met at `مَّجِيدٌ` (11:73) **and** `ٱلْمَجِيدُ` (85:15)
- **bar 5** disclosed a Sūrat al-Burūj exposure the deck no longer had
- the **bar 3(b)** sweep reported "11:73 free · 85:15 free" as if both were still this deck's ground

**Four tables agreeing with each other and disagreeing with the beat.** §3's rule ("if a beat disagrees with your own verification table, STOP") assumes the disagreement is visible. Here the beat was the only thing that had moved, so the tables' consensus read as confirmation.

**The mechanical cause is worth naming exactly**, because it is a one-character class of bug. The re-cut was two string replacements: one on the quoted line, one on the citation. The first was written to match `> Honorable Owner of the Throne\n` — but the line is `> Honorable Owner of the Throne — Qur'an 85:15\n`, so **it matched nothing and failed silently**, while the second replacement (`85:15` → `11:73`) matched the beat line first and succeeded. **A no-op `str.replace` returns the string unchanged; it does not raise.**

**Three rules, all cheap:**

1. **When you re-cut a beat, re-fetch the new citation and re-assert the rendered text against it** — the same §9cb assertion the duʿā beat gets. A beat's quotation and its `source` are one unit; never edit one of them.
2. **Assert that every string replacement changed something.** `assert old in t` before `t.replace(...)`. Every silent no-op in this project has flipped a verified claim into an unverified one.
3. **A re-cut invalidates every table that mentions the surrendered text.** Grep the file for the old reference and strike the rows rather than deleting them, so the surrender stays auditable.

**And the finding that only appeared once the re-cut was audited:** ids 58 and 72 are **not the same Name-form**. Id 58 is `ٱلْمَجِيدُ`; id 72 is `ٱلْمَاجِدُ`, which **occurs nowhere in the Qurʾān**. So 85:15's `ٱلْمَجِيدُ` — the word `al-majid@1`'s verse beat now rests on — **is the neighbour's Name-form, on the wrong deck**, and that deck's beat-6 note claimed it as *"the Name's own form predicated of Allah."* Bar 4 for id 72 is a **form-level trade whichever āyah it gets**, because the corpus offers it nothing else. **Check that a shared root is a shared form before you partition on it.**
