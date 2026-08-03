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
