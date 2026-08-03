# DRAFT — `al-mumeet@1` — Al-Mumeet (70), The Bringer of Death

**Status: DRAFT, awaiting adversarial review + founder sign-off.** Drafted 2026-08-03 as a
deliberate pair with `al-muhyi@1` (id 69) — see the pairing verdict in §9.

**Method note, read first:** same as the Al-Muhyi draft — one drafting pass with mechanical
verification (live fetch, a full-Qur'an-text root sweep, cross-check against `.context/claims/`
and `COLLISION-LEDGER.md`), not the multi-round adversarial pipeline. Limits stated in §8.

**This is the task's named bar-5-of-its-own-kind case:** a Name about Allah causing death, reaching
a user at night who may be grieving or afraid. Nothing below reassures beyond what the text itself
earns — see §7 for how that was handled, beat by beat.

---

## 1 · Selection — duʿā-first, per the binding method

Catalogue id 70's `dua_arabic` (`اللَّهُمَّ أَحْسِنْ خَاتِمَتِي وَاجْعَلْ آخِرَ أَعْمَالِي
خَيْرَهَا` — "O Allah, make my ending good and make the last of my deeds the best of them") was
read first. Searched (`WebSearch`, targeted on the distinctive `أَحْسِنْ خَاتِمَتِي` clause) —
**no exact narrated match found**; the closest hits were unrelated hadith sharing the verb `أَحْسِنْ`
in other contexts (Muwaṭṭaʾ Mālik on good character, unrelated). **Verdict: unpinned, authored-style
catalogue invocation**, matching the husn al-khātima (good-ending) theme that is well attested as a
*concept* across many narrations but not, on this search, as this exact wording. No `source` field
on the `dua` beat; not added to `renderedDuaSources`.

Catalogue id 70's own `hadith` field cites **Tirmidhī 2307**. Independently re-fetched and
re-verified (§7) — the card is accurate: *"Increase in remembrance of the severer of pleasures."
Meaning death.* Ḥasan (Darussalam). **Verified, not placed on any beat** (the selected story does
more narrative work); recorded so nobody re-verifies it as if it were in doubt.

## 2 · Candidates considered (3, per the sourcing protocol)

| candidate | why considered | why not selected / status |
|---|---|---|
| **The angel of death and Mūsā** (Bukhārī 1339) | narrative, demonstrates the decree in action, includes Allah's own reported action (restoring the eye, setting the terms) and a dignified, freely-chosen ending | **Selected.** |
| Tirmidhī 2307 alone (*"remember the severer of pleasures"*) | short, well-graded, matches the catalogue's own `hadith` field | no narrative to *show* the attribute (bar 2) if used as the sole anchor — kept as verified background, not the deck's spine |
| 39:42 (souls taken in sleep) + Bukhārī 595 | thematically adjacent (death/sleep), well attested | **explicitly off-limits** — this is `al-qayyum@1`'s spent ground, named so in the task brief and independently re-confirmed against COLLISION-LEDGER §2a/§7a.4 before this draft touched anything |

## 3 · Sibling-collapse check — three surfaces, plus the twin-deck diff

### 3a · Arabic roots

| root | where it appears in this deck's source text | note |
|---|---|---|
| `m-w-t` | Bukhārī 1339, `ٱلْمَوْتِ`/`ٱلْمَوْتَ`/`ٱلْمَوْتُ` ×3, re-counted directly against the Arabic (*"the angel of **death**"*; *"a servant who does not want **death**"*; *"then, **death**"*) — the Name's own root, in a reported exchange where **Allah is the one deciding and naming the term** | this deck's bar-1/bar-4 carrier — as a **noun**, not the causative finite verb (see §5 for why) |
| `ʾ-j-l` | 63:11, `أَجَلُهَا` ("its appointed term") | not a sibling Name's root in this catalogue (no decked or drafted Name carries `ʾ-j-l` as its own root) |
| `ḥ-y-y` | **absent everywhere in this deck** — checked beat-by-beat, zero occurrences in Arabic or English (no "life", "living", "revive" in any beat, including the duʿā, which asks for a good *ending*, not life) | **the deliberate separation from Al-Muhyi** — see §5 |
| — | no `gh-f-r`, `ʿ-f-w`, `r-ḥ-m`, `ḥ-l-m`, `q-d-r`, `w-l-y`, `j-w-b` | clear of every dense root flagged in COLLISION-LEDGER §5a |

### 3b · Token frequency against all 34 shipped/drafted decks' rendered strings

Distinctive phrases this deck introduces — *"the angel of death"*, *"place his hand on the back of
an ox"*, *"then, now"*, *"not more time, better ground"* — checked against COLLISION-LEDGER §4b/§4c
and §3's beat-8 table: **zero hits.** The one word worth flagging at the token level: *"afraid"*
does not appear anywhere in this deck (COLLISION-LEDGER §9ac/§9ab record it as a corpus hapax on
`al-wakeel@1` and blocking when repeated — this deck never reaches for it, so the question does not
arise here).

### 3c · The move (what the beat *does*) — including the required twin-deck diff

**Diff against `al-qayyum@1`** (Bukhārī 595 + 39:42, souls taken in sleep): different narration,
different Name-noun, different register (sleep/waking vs. a Prophet's own death), and this deck
does not touch 39:42 or any sleep image anywhere. **Diff against `al-baqi@1`** (shipped, "what
outlasts" — *impermanence of everything but Allah*): that deck's engine is contrast between the
transient and the Everlasting; this deck's engine is about the **appointment and its timing**, never
invoking "what remains" language. No shared beat-8 phrase, no shared verse.

**The twin-deck diff against `al-muhyi@1`, beat by beat, run explicitly because this is the named
failure mode ("one deck twice with the polarity flipped"):**

| beat | al-muhyi@1 | al-mumeet@1 | same move? |
|---|---|---|---|
| bridge | a hope you've stopped expecting back | an ending you can't see or move | different subject (an inner feeling vs. an external, fixed event) |
| name_intro | "The Giver of Life" | "The Bringer of Death" | catalogue-locked opposites; not a collision, the Names' own glosses |
| story engine | an impersonal, repeatable natural process (rain/earth), no protagonist, no negotiation | a personal, one-time negotiation between a named Prophet and an appointed angel, with dialogue | **structurally different narrative types** — parable vs. named-character story. This is the check the failure mode is about: a mirrored engine would have made Al-Mumeet a second parable (e.g. drought killing a field) built to invert Al-Muhyi's. It is not that. |
| verse engine | "observe the evidence, extend it" (an argument from nature) | "it will not be delayed" (a statement about sovereignty over timing) | different logical shape — inductive argument vs. flat assertion |
| takeaway engine | ordinary proof extends to personal hope | a choice that was offered and declined, in favor of nearness over duration | one is about **evidence**, the other is about **acceptance** — not mirror images |
| dua | asks to revive heart/hope | asks for a good ending | opposite direction, not restated |

**Result, computed programmatically (longest-common-substring across all 16 beats, 8+8, both
directions), not eyeballed:** the actual maximum cross-deck run is **2 words**
(`"of life"` — Al-Mumeet's incidental "a year **of life**" against Al-Muhyi's Name-gloss and verse
beat; `"you that"`/`"what he"` — function-word fragments). **No run of 3 or more words exists
anywhere across the two decks' rendered content.** An earlier version of both bridges *did* share a
4-word run — `"there is a Name"` — before revision; both bridges were rewritten specifically to
remove it (see each deck's own bridge beat), which is why this is reported as a measured result
rather than an assumed one.

## 4 · Successor sweep — every quotation, n±1 fetched and read

| citation | n−1 fetched | n+1 fetched | verdict |
|---|---|---|---|
| Bukhārī 1339 | n/a (ḥadīth; adjacent hadith numbers in the same chapter carry no bearing — checked the chapter title, "Whoever desired to be buried in the Sacred Land," which is this narration's own point, not a different topic) | n/a | clean |
| 63:11 | **63:10 fetched and read** — the plea for delay ("My Lord, if only You would delay me for a brief term, so I would give charity and be of the righteous"). **Disclosed as context, not quoted**: 63:11 is a direct answer to this plea, and presenting 63:11 alone without disclosing that it answers a specific request would understate what it is doing. Also read 63:9 (n−2, not mandatory): a warning against wealth/children distracting from remembrance of Allah — sets up 63:10's plea, not independently used. | **`verses/by_key/63:12` → HTTP 404 — sūrah-final.** Maximal form of bar 5, same class as `al-haleem@1`'s 35:45. | clean, and the strongest available bar-5 result in either of this wave's two decks |

## 5 · Bar-4 trade — full-text sweep run, forced by the Qur'an's own diction

**Claim, stated at its measured strength (corrected once during this draft — see below):** the
Qur'an's one **fixed doublet formula** for this attribute — `يُحْىِ`/`نُحْىِ` **immediately
conjoined by `وَ` (or `ثُمَّ`) with** `يُمِيتُ`/`نُمِيتُ` in the same verse — is paired **16 times
out of 16**, with zero exceptions. Verified by fetching all 114 chapters (6,236 āyāt) via the
quran.com API, regex-matching `يميت`/`تميت`/`نميت` after diacritic-stripping: **2:28, 2:258 (Ibrāhīm's
half only — see below), 3:156, 7:158, 9:116, 10:56, 15:23, 22:66, 23:80, 26:81, 30:40, 40:68, 44:8,
45:26, 50:43, 57:2** — 16 verses, 16 pairings, all within one verse (mostly one clause).

**Self-correction, run before this table was finalized, not after (§9aj discipline):** a first pass
claimed this covered *every* finite verb of Allah causing death. Checking the past-tense (`أَمَاتَ`)
forms separately (a second regex pass for the hamza-alif spellings the first pass's pattern list
missed) found **two genuine exceptions to the broader claim**, so the broader claim is withdrawn and
replaced with the narrower, true one above:

- **2:258, second half** — the arrogant king's reply `أَنَا۠ أُحْىِۦ وَأُمِيتُ` ("I give life and
  cause death") **is** WA-paired, but it is a disbeliever's false boast, refuted in the same āyah
  (`فَبُهِتَ ٱلَّذِى كَفَرَ`) — excluded from the count above as human speech misattributing the
  power to himself, not a case of Allah's own action.
- **2:259** — `فَأَمَاتَهُ ٱللَّهُ مِا۟ئَةَ عَامٍ ثُمَّ بَعَثَهُۥ` ("So Allah caused him to die a
  hundred years; then He raised him"): Allah as explicit subject, finite verb, **but paired with**
  `بَعَثَ` (root `b-ʿ-th`, Al-Baith's root — catalogue id 59, not yet decked) **rather than a
  `ḥ-y-y` form**, two clauses later, not in the same breath. **Already spent/rejected territory**:
  COLLISION-LEDGER §2d records it as rejected by `al-qadir@1` for reduplicating `ar-raheem@1`'s
  "centuries-long sleep and awakening" shape — not usable here regardless of the grammar.
- **80:21** — `ثُمَّ أَمَاتَهُۥ فَأَقْبَرَهُۥ` ("Then He causes him to die and provides a grave for
  him"), followed one sentence later by `ثُمَّ إِذَا شَآءَ أَنشَرَهُۥ` ("then when He wills, He
  will resurrect him," root `n-sh-r`, not `ḥ-y-y`) — the clearest true exception: Allah's
  death-verb here is paired with *burial*, not life, in its own clause. Not selected: the passage
  opens `قُتِلَ ٱلْإِنسَـٰنُ مَآ أَكْفَرَهُۥ` ("Cursed is man; how disbelieving is he!") — a rebuke
  frame at the top of the same passage, the wrong register for this deck (§6).

**What survives, and what this deck actually rests on:** the *doublet formula* (16/16) is real and
is what would have put Al-Muhyi's root on this deck's verse beat had it been used — that risk is
what §5's trade avoids. The two exceptions above are not a route around the trade (both are
independently unusable for other reasons), so **the trade stands**: this deck's root evidence comes
from Bukhārī 1339's `ٱلْمَوْتِ`/`ٱلْمَوْتَ`/`ٱلْمَوْتُ` (a **noun**, three times, in a reported exchange with Allah as the one who
names and decides the term) rather than a Qur'anic finite verb, and the verse beat (63:11) carries
`ʾ-j-l` (appointed term) rather than `m-w-t` at all — sovereignty-over-timing demonstrated without
needing "death" or "life" in that beat's Arabic.

**Method limit on the sweep itself, stated per §9af/§9ac's precedent:** this is a local-regex
full-text pass in two rounds (the second round catching what the first missed), not a published
concordance or an independently-run second method. Reported as what this method found, not as an
infallible enumeration — and the correction above is the demonstration of why that caveat is not
boilerplate.

## 6 · Register — how "must hold without reassurance" was applied

- **No beat states death is not frightening, easy, or "just a transition."** The story's dramatic
  beat (Mūsā's strike) is kept, not softened into euphemism — the ḥadīth is presented as it happened.
- **The comfort in this deck is entirely textual, not invented:** Mūsā's own choice ("then, now")
  is the ḥadīth's own turn, not an authored gloss on it; the duʿā's request (a good ending) is the
  catalogue's own, not this deck's addition.
- **The takeaway does not promise an outcome** ("you will die well") — it names what was *asked
  for* (nearness, not duration), leaving the reader's own request open rather than resolving it for
  them.
- **No language of fear, punishment, or urgency-as-threat.** The deck never says or implies "you
  could die tonight, so—"; the register is closer to *matter-of-fact dignity* than to warning.

## 7 · Deck (beats, matching the shipped schema)

```json
{
  "deck_id": "al-mumeet@1",
  "name_id": 70,
  "transliteration": "Al-Mumeet",
  "chip_keys": [],
  "position_in_pair": 0,
  "beats": [
    {
      "kind": "bridge",
      "primary": "There is a day already fixed for you that you cannot see and cannot move. What you do with the time before it is still yours.",
      "source": ""
    },
    {
      "kind": "name_intro",
      "label": "catalog id 70, verbatim",
      "primary": "The Bringer of Death",
      "arabic": "الْمُمِيتُ",
      "transliteration": "Al-Mumeet",
      "source": ""
    },
    {
      "kind": "story",
      "label": "The angel and Musa",
      "primary": "The angel of death was sent to Musa. When he came, Musa struck him, and did not go. The angel returned to his Lord and said: \"You sent me to a servant who does not want to die.\"",
      "source": "Sahih al-Bukhari 1339 (paraphrase)"
    },
    {
      "kind": "story",
      "label": "The angel and Musa",
      "primary": "Allah restored his eye, and sent him back with an offer: place your hand on the back of an ox — for every hair beneath it, a year of life. Musa asked, \"My Lord, then what?\" He said: \"Then, death.\"",
      "source": "Sahih al-Bukhari 1339 (paraphrase)"
    },
    {
      "kind": "story",
      "label": "The angel and Musa",
      "primary": "Musa said: \"Then, now.\" He did not take the years. He asked only to be brought near the sacred land — a stone's throw away — and there, close to it, he died.",
      "source": "Sahih al-Bukhari 1339 (paraphrase)"
    },
    {
      "kind": "verse",
      "label": "full ayah, sūrah-final",
      "primary": "But never will Allāh delay a soul when its time has come. And Allāh is Aware of what you do.",
      "source": "Qur'an 63:11"
    },
    {
      "kind": "dua",
      "label": "catalog id 70, verbatim",
      "primary": "O Allah, make my ending good and make the last of my deeds the best of them.",
      "arabic": "اللَّهُمَّ أَحْسِنْ خَاتِمَتِي وَاجْعَلْ آخِرَ أَعْمَالِي خَيْرَهَا",
      "transliteration": "Allahumma ahsin khatimati waj'al akhira a'mali khayriha",
      "source": ""
    },
    {
      "kind": "takeaway",
      "primary": "Musa was offered more time, counted out in strands of hair, and he did not take it. What he asked for instead was to be near what was sacred when it came. Not more time. Just better ground to meet it on.",
      "source": ""
    }
  ]
}
```

**Self-diff (§9v discipline), computed programmatically:** one pair shares a ≥4-word run, by design:
story beat 5 (*"He did not take the years"*) and the takeaway (*"he did not take it"*) share
*"he did not take"* — the takeaway explicitly recalls the story's turn, which is what a takeaway is
for. One further pair shares 3 words coincidentally rather than by design: bridge (*"...is still
yours"*) and the verse beat (*"...Aware of **what you do**"*) share *"what you do"* — thematically
consonant (both beats are about action/agency against a fixed timeline) rather than confusing, and
not a repeated claim (§9o's test: a user would not read these as saying the same thing). Left as
is rather than reworded to avoid a 3-word function-heavy phrase.

Checked specifically for the §9ar failure class (a takeaway's last clause read against the story's
last noun, in case of accidental inversion): beat 5 ends on *"he died"*; beat 8 ends on *"better
ground to meet it on"* — no ambiguity of the kind that inverted a prior deck's meaning.

## 8 · Verification table

| Claim | Source | Grading | Status |
|---|---|---|---|
| The angel of death, Musa, the struck eye, the offer of years, "then, now", burial near the Sacred Land — full narration | Wayback capture of `https://sunnah.com/bukhari:1339`, CDX-located, fetched 2026-08-03 (`https://web.archive.org/web/20230131204345/https://sunnah.com/bukhari:1339`) | **Ṣaḥīḥ al-Bukhārī 1339** — no separate grade line printed on the page (standard for Bukhārī; collection-level inference, same convention COLLISION-LEDGER §9ag records for Bukhārī 6227) | ✅ fetched and read in full, both Arabic and English; beats are disclosed paraphrase, checked against the Arabic (`أُرْسِلَ مَلَكُ الْمَوْتِ`, `صَكَّهُ`, `فَرَدَّ اللَّهُ عَلَيْهِ عَيْنَهُ`, `ثُمَّ الْمَوْتُ`, `فَالآنَ`, `الأَرْضِ الْمُقَدَّسَةِ`) rather than copied from the page's published English. **One disclosed inferential step:** the hadith's own text narrates the *request* ("he asked Allah to bring him near the sacred land") and then jumps to the Prophet's ﷺ closing remark about knowing his grave "by the road, near the red sand hill" — it does not narrate "and he died there" as a separate clause. Beat 5's "there, close to it, he died" is the standard, uncontested reading (the grave-remark presupposes it), but it is a one-step inference from the text, not a directly narrated sentence, and is named here rather than left silent. |
| 63:11, full āyah, and its sūrah-final position | `https://api.quran.com/api/v4/verses/by_key/63:11` (fetched); `.../63:12` (fetched, HTTP 404) | Qur'an | ✅ both fetched live 2026-08-03; 404 confirms sūrah-final |
| 63:10 (n−1) read as context | `https://api.quran.com/api/v4/verses/by_key/63:10` | Qur'an | ✅ fetched, disclosed in §4, not quoted on any beat |
| Catalogue id 70's `hadith` field (Tirmidhī 2307) independently re-verified, accurate as printed | Wayback capture, `https://web.archive.org/web/20231205184808/https://sunnah.com/tirmidhi:2307` | **Ḥasan (Darussalam)** | ✅ fetched, text and grade match the catalogue card; not placed on a beat (§1) |
| 39:42 / Bukhārī 595 not used anywhere in this deck | this draft's own beats + COLLISION-LEDGER §2a cross-check | — | ✅ confirmed by re-reading every beat above and the ledger's own row for `al-qayyum@1` |
| **Full-text sweep: the Qur'an's fixed doublet formula (`يُحْىِ`/`نُحْىِ` + `يُمِيتُ`/`نُمِيتُ`) is paired 16/16, zero exceptions; two exceptions found and disclosed among the broader, narrower-claimed `أَمَاتَ`-form set (2:259, 80:21), both independently unusable** | fetched all 114 chapters, 6,236 verses, local regex after diacritic-stripping, two passes | Qur'an, full-corpus grep, reproducible | ✅ run and counted; enumerated in §5, shared method with `al-muhyi@1`'s draft; claim narrowed mid-draft after self-check (§9aj discipline) |
| `dua_arabic`/`dua_transliteration`/`dua_translation` on the `dua` beat byte-identical to catalogue id 70 | `assets/content/collectible_names.json`, id 70 | catalogue | ✅ diffed programmatically, byte-identical |
| `name_intro` primary/arabic/transliteration byte-identical to catalogue id 70 | same file | catalogue | ✅ diffed, byte-identical |
| Catalogue id 70's duʿā has no locatable narrated source | `WebSearch`, 1 targeted query | — | ✅ stated at true strength: one search run, no exact match; not exhaustive (method limit, §8) |
| Bar-3 clearance against `al-qayyum@1`, `al-baqi@1`, and the twin-deck diff against `al-muhyi@1` | COLLISION-LEDGER §1/§2a/§3, this draft's own §3c table | project artifacts | ✅ read in full; beat-by-beat table in §3c |
| `.context/claims/` directory re-read immediately before finalizing this table, and again immediately before reporting | `.context/claims/*.md` — 21 files at the first re-read, **38 files at the final re-read** (2026-08-03) — specifically checked `.context/claims/43.md`, which independently fetched and swept 63:5–11 for its own (rejected) candidate and confirms the same sūrah-final result at 63:11/63:12, without claiming 63:11 itself; and grepped every file added after the first re-read (74, 79, 80, 85, 91, 92, 94, 95, 96) for `63:1[01]`, `1339`, `3407`, `angel of death`, `al-mumeet` | project artifact | ✅ re-read twice; no other agent's claim touches Bukhārī 1339, 63:10, or 63:11 at either re-read |

## 9 · Pairing verdict — ship independently, argued in full

**Verdict: Al-Muhyi and Al-Mumeet can ship independently. Recommended to review together; not
required to ship together.**

**Case for independence:**
1. **No catalogue-level constraint links them.** Al-Qabid/Al-Basit's "pair only" ruling came from
   the text itself — their `dua_arabic` is one shared string (COLLISION-LEDGER §6a group 2), so a
   solo deck for either would render the other Name's vocative on screen regardless of any drafting
   choice. **Ids 69 and 70 have fully distinct `dua_arabic`** (confirmed against §6a/§6b/§6c — neither
   appears in any duplicate group, and neither invokes the other by name), and both are marked
   `clear` on the duʿā axis in §7 of the ledger. There is no data-level force here.
2. **Ad-Darr's must-pair ruling rests on a different defect this Name doesn't share.** The task
   brief itself distinguishes them: Al-Mumeet is "not an accusation like Al-Muzill." Death is a
   basic, undisputed creedal fact every Muslim already affirms; it does not carry the implication of
   blame that made Ad-Darr read as needing an immediate structural answer. What this Name needs is
   **register care within its own deck** (§6), not a rescuing counterpart.
3. **No chip-pair mechanism exists for either Name today** (`chip_keys: []` on both, matching the
   non-chip batch-2/wave-1 precedent, e.g. `al-haleem@1`). `discoverName()` draws one undiscovered
   or lowest-tier Name per session with no designed sequencing between arbitrary Names — enforcing a
   hard pairing would require new product work, which the parent plan explicitly scopes this track
   to avoid ("a content track with no engineering dependency on anything").
4. **This deck is complete and dignified on its own terms** (§6) — it does not lean on Al-Muhyi to
   supply comfort it hasn't earned itself. A user who never sees `al-muhyi@1` is not left with an
   unanswered accusation; they are left with a Prophet's own example of what accepting an
   appointment with grace looks like, and a duʿā asking for a good one.

**Case for pairing, stated fairly, since a reasoned verdict requires naming the counter-case:**
1. The Qur'an's *fixed doublet formula* for this attribute pairs the causative death-verb with the
   life-verb 16 out of 16 times, with no exception (§5) — the Qur'an's own diction treats them as a
   set phrase more insistently than it treats almost any other pair of the 99 Names.
2. They are catalogue ids 69/70, adjacent, and thematically the clearest opposite-pair in the whole
   list — closer to a natural doublet than most of the founder-approved pairs.
3. A founder reading Al-Mumeet in isolation, at night, might reasonably want Al-Muhyi one tap away
   — an experience decision, not a content-correctness one.

**Why the first case wins:** points 1–2 above are about the *Qur'an's* rhetorical habits, not about
what either *deck* needs to be correct or complete — and §5's sweep is precisely what let this deck
avoid inheriting that pairing into its own text. Point 3 is a real UX preference but is achievable
by **review/ship sequencing** (signing and releasing both in the same batch) without a hard
mechanism, which gets the same practical outcome the founder likely wants at zero engineering cost.
**If the founder wants a hard pairing mechanism instead, that is a legitimate call — but it is a
product decision belonging to the chip/pairing system, not a finding this draft can settle, and it
should be made explicitly rather than defaulted into.**
