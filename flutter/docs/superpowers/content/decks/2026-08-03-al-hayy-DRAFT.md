# Deck Draft — Al-Hayy (catalogue id 15)

**Status: DRAFT, RULED — coordinator decision 2026-08-03: ship with beat 7 disclosed (option a).**
Story, verse, name_intro and takeaway are bar-3 clean. The duʿā beat (beat 7) carries a disclosed,
catalogue-locked overlap with shipped `al-qayyum@1` — ruled **not a collision but one supplication
in its short and long forms** (§9be/§9o), same class as the already-accepted *Restorer* /
*"The Everlasting"* open calls. See "§Duʿā beat — DISCLOSED" below for the full argument. Ready
for transcription into `assets/content/name_stories.json` pending the founder's `review_verdict`.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Governing plan: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Author: Claude, 2026-08-03.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com`; ḥadīth via Wayback
archive of the exact `sunnah.com` URL (sunnah.com 403s automated fetching). Scripture is quoted
exactly from the fetched pages; story beats paraphrase only what the cited source carries, and
every paraphrase is labelled. Translation standard: Saheeh International (`translations=20`)
throughout.

**Implementation note (binding):** Arabic / transliteration / translation are separate fields on
every beat, per the app's mixed-direction rule.

---

## Why Al-Hayy was held back, and what changes here

The COLLISION-LEDGER's §7 worklist marks catalogue id 15 **BLOCKED** on the duʿā axis, and its §1a
records that `al-qayyum@1`'s own R2 authoring notes claim Tirmidhī 3524 as "Al-Hayy (15)'s
material" and refuse to spend it. I re-verified every part of that independently, before reading
any conclusion as settled — and reported it to the coordinator, who **ruled the deck ships**: the
duʿā-beat overlap is a fact about one supplication existing in a short form (id 15) and a long form
(id 16), not two decks teaching the same thing. See "§Duʿā beat — DISCLOSED" for the ruling and its
reasoning in full.

1. **Fetched Tirmidhī 3524 myself** (Wayback capture `20220125134156`, archived 2022, matching the
   text `al-qayyum@1` R2 separately fetched from capture `20260309115006` — two different
   snapshots, same text). **Confirmed: `Grade: Hasan (Darussalam)`**, printed on the page, not
   inferred. Abū ʿĪsā (at-Tirmidhī)'s own note on the same page calls it `حَدِيثٌ غَرِيبٌ`
   ("gharīb") — both grade lines are reported below rather than only the more favourable one.
2. **Diffed the catalogue's `dua_arabic` against the fetched hadith text at the codepoint level**
   (Python, not by eye): 47 codepoints each, **one difference** — position 6, `ي` (U+064A) in the
   catalogue vs `ى` (U+0649) on the Tirmidhī page, both spelling the same word `حَيّ`. **Rasm-
   identical, not byte-identical** (vocabulary per the ledger's §9ax ruling). This is a stronger,
   independently-fetched confirmation of the ledger's own claim.
3. **Confirmed the story is genuinely available and distinct from `al-qayyum@1`'s** — a different
   collection, different narrator, different century, different scene (see below). Bar-3 on the
   *narrative* axis is achievable; the finding below is specific to the *duʿā beat*, which is fixed
   catalogue content this deck cannot change.

**So the deck below is a full draft with a genuine, load-bearing story — but it cannot ship as
"good" on beat 7 without a founder decision, because that beat's problem is not a drafting choice.**
The prose in this file makes that argument once, here; every ✅ elsewhere refers only to what it
actually checked, per the standing rule in the ledger's §9aj ("diff the prose against the table
before shipping").

---

## Deck `al-hayy@1` — Al-Hayy

**Why this deck exists, in one line:** on the morning the Prophet ﷺ died, the man who loved him
most stood up and, before he did anything else, drew the one line that does not move: *everyone
who was ever alive will die; the One who is Ever-Living does not.*

**Proposed metadata**

```json
{
  "deck_id": "al-hayy@1",
  "name_id": 15,
  "transliteration": "Al-Hayy",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> Everyone you have ever loved will one day be gone — and so, eventually, will you. That is not
> despair. It is the one fact that makes what comes next worth saying.

**Beat 2 · name_intro** *(from `collectible_names.json` id 15, verbatim)*:
> الْحَيُّ — Al-Hayy — The Ever-Living

**Beats 3–5 · story — "The morning no one wanted to believe":**
> 1. When the Prophet ﷺ died, ʿUmar could not accept it and stood before the people insisting he
>    was not dead. Abū Bakr came, uncovered his face, kissed him, and said: **"You are good in
>    life and in death."**
> 2. Then he turned to the people and said: **"Whoever worshipped Muhammad — Muhammad has died.
>    Whoever worshipped Allah — Allah is Ever-Living; He does not die."**
> 3. Then he recited what Allah had revealed: **"Muhammad is only a messenger. Messengers have
>    passed away before him. If he dies, will you turn back?…"** The people wept.

**Beat 6 · verse:**
> "He is the Ever-Living; there is no deity except Him — so call upon Him, sincere to Him in
> religion…" — Qur'ān 40:65

**Beat 7 · duʿā** *(catalog id 15, verbatim in full — DISCLOSED, see the dedicated section below)*:
> يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ
> *Ya Hayyu Ya Qayyum bi rahmatika astaghith*
> "O Ever-Living, O Self-Sustaining, by Your mercy I seek relief."

**Beat 8 · takeaway:**
> Muhammad ﷺ was the most beloved human being who ever lived, and even he did not get to stay.
> Al-Hayy is the one name in that sentence that was true before that morning and is still true
> after it.

---

## The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words** | **Qur'ān 40:65, beat 6.** `هُوَ ٱلْحَىُّ لَآ إِلَـٰهَ إِلَّا هُوَ` — Allah is the grammatical subject of a nominal sentence declaring His own life, in the Qur'ān's own voice, with no narrator between the reader and the claim. **Not the epithet pair.** `ٱلْحَىُّ` here stands alone, paired with the tawḥīd formula (`لَآ إِلَـٰهَ إِلَّا هُوَ`), not with `ٱلْقَيُّومُ` — the pairing the task explicitly warned fails bar 1 and bar 3 at once. **Story beat 4's central line ("Allah is Ever-Living; He does not die") is Abū Bakr's own speech, not Allah's** — disclosed rather than counted toward this bar; it carries bar 2, not bar 1. | **yes — beat 6** |
| 2 | **shown, not stated** | **Beats 3–5 show it rather than assert it.** The demonstration is an event in which the human side of the sentence provably ends — the most beloved man alive dies, and the community's first instinct (ʿUmar's) is to deny it — **and Abū Bakr's answer draws the line between what ended and what did not**, in the same breath. 40:65 then states the same fact in Allah's own words, which is what a `verse` beat is for and must not be the only evidence for. | **yes — beats 3–5** |
| 3 | **no sibling collapse** | See the dedicated three-surface sweep below — **clean on the story/verse axis. Duʿā axis: disclosed overlap with `al-qayyum@1`, ruled non-blocking by the coordinator** (one narrated supplication in its short and long forms, not two decks teaching the same thing — §9be/§9o). | **yes — with a disclosed, ruled-non-blocking duʿā overlap** |
| 4 | **the Name's own root appears in the source text** | **Yes, twice over.** `ٱلْحَىُّ` is the grammatical subject of beat 6's own sentence (40:65) — the strongest form this bar can take, not a trailing epithet. It also appears in the story's own Arabic: `طِبْتَ حَيًّا وَمَيِّتًا` (beat 3, "you are good in life and in death" — literally "alive and dead") and `فَإِنَّ اللَّهَ حَىٌّ لاَ يَمُوتُ` (beat 4). Neither story occurrence renders as Arabic on screen (story beats never carry the `arabic` field, per the schema fact in plan §7), but both are the underlying text the English paraphrases, so the root is doing real work, not decorative work. | **yes — beat 6, and underlying beats 3–4** |
| 5 | **arc must not terminate in punishment just outside the excerpt** | **Full successor sweep below — clean on every quotation.** | **yes — verified** |

---

## Successor sweep (mandatory per quotation) — fetched 2026-08-03

| excerpt | n−1 | n+1 | verdict |
|---|---|---|---|
| **Qur'ān 40:65** (verse beat) | **40:64**: "It is Allāh who made for you the earth a place of settlement... then blessed is Allāh, Lord of the worlds." Positive creation statement, no warning. Minor off-screen root: `رَزَقَكُم` (Ar-Razzaq's root, shipped `ar-razzaq@1` uses different āyāt — 65:2–3 — disclosed, not blocking). | **40:66**: "Say, I have been forbidden to worship those you call upon besides Allāh... and I have been commanded to submit to the Lord of the worlds." Continues the tawḥīd theme, no punishment. | **clean.** No punishment at n−1 or n+1. Sūrat Ghāfir (40) is touched by no other shipped or drafted deck — verified by grep of the full ledger, zero hits for "40:6" citations. |
| **Qur'ān 3:144** (story beat 5) | **3:143**: "And you had certainly wished for death before you encountered it, and you have now seen it while you were looking on." No punishment; addressed to the believers about Uḥud. | **3:145**: "And it is not possible for one to die except by permission of Allāh at a decree determined... We will reward the grateful." No punishment. | **clean.** Qur'ān 3:144 is cited by no other deck (Āl ʿImrān's other decked verses are 3:172–174 `al-wakeel@1`, 3:26 `al-malik@1`, 3:35–37 `al-aleem@1` per the ledger — none overlaps 3:144). |
| **Ṣaḥīḥ al-Bukhārī 3667/3668** (story beats 3–4) | Not applicable in the Qur'ānic sense (ḥadīth, not sūrah-sequential); the same narration continues past what is quoted (into the Ṣaqīfa succession dispute) — **none of that continuation is quoted or alluded to on any beat.** The narration's own next line after the Al-Hayy clause is Abū Bakr reciting 3:144 (beat 5) then 39:30 (`إِنَّكَ مَيِّتٌ وَإِنَّهُم مَّيِّتُونَ`, "you will die, and they will die") — **not quoted on this deck**, checked and found clean of punishment (39:31 continues to "you will dispute before your Lord," no threat). | | **clean.** |
| **Jami' at-Tirmidhī 3524** (duʿā beat's underlying hadith) | N/A — a standalone report, not sūrah-sequential. The same Tirmidhī entry continues with a second, separately-chained saying about `يَا ذَا ٱلْجَلَالِ وَٱلْإِكْرَامِ` (Dhūl-Jalāli wal-Ikrām, catalogue id 89) — **not quoted here**, and the catalogue's `dua_arabic` for id 15 stops before it, matching the deck. | | **clean, and no over-quotation.** |

---

## Bar 3, three surfaces — story/verse axis clean, duʿā axis DISCLOSED and ruled

### Surface 1 — Arabic roots

| deck | Name root | roots in quoted/underlying source text | roots explicitly absent |
|---|---|---|---|
| `al-hayy@1` (this deck, story + verse beats only) | `ḥ-y-y` | `ḥ-y-y` (40:65 `ٱلْحَىُّ`; underlying 3667/3668 `حَيًّا`, `حَىٌّ`) | `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `q-w-m`, `sh-f-y`, `w-k-l`, `t-w-b` — **none appears on beats 1–6 or 8**, verified by reading every quoted clause. `مَاتَ`/`يَمُوتُ` (root `m-w-t`, "to die") is the deck's own second engine and is not any shipped Name's root. |
| `al-hayy@1`, **duʿā beat only** | `ḥ-y-y` + `q-w-m` | Catalogue id 15's own text opens `يَا حَيُّ` then, in the same breath, `يَا قَيُّومُ` — **Al-Qayyum's root, in the vocative, addressing Allah by a second Name inside id 15's own duʿā.** This is catalogue-locked, not a drafting choice. | — |

**Al-Qayyum-adjacent verses explicitly rejected, and why (not re-derived — matches and extends the
ledger's own §2d / al-qayyum@1's authoring notes, independently re-confirmed):**

- **2:255 and 3:2** (`ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ`) — the exact epithet
  pair the task named as failing bar 1 and bar 3 at once. 2:255 is also `al-qayyum@1`'s shipped
  verse beat; using either would put `ٱلْحَىُّ ٱلْقَيُّومُ` on two screens from the same āyah.
- **25:58** (`وَتَوَكَّلْ عَلَى ٱلْحَىِّ ٱلَّذِى لَا يَمُوتُ`) — fetched, and it is the single
  strongest bar-1/bar-2 sentence in the Qur'ān for this Name (`الْحَيِّ الَّذِي لَا يَمُوتُ`,
  "the Ever-Living who does not die," almost the exact English of this deck's own beat 4). **Rejected
  on bar 3**: its governing imperative is `تَوَكَّلْ` — Al-Wakeel's own Name-verb, and shipped
  `al-wakeel@1`'s entire engine is trust/reliance. Quoting the full āyah would open the verse beat
  on a command to trust, risking a user reading it as Al-Wakeel's lesson repeated. `al-qayyum@1`'s
  own R2 notes reject the same āyah for the same reason; this is an independent re-confirmation
  for a different Name, not an inherited assumption.

### Surface 2 — token frequency over every rendered string of all 34 shipped/drafted decks (duʿā beats swept from character one, per the ledger's §9as standing rule)

Computed programmatically against `assets/content/name_stories.json` (595 rendered strings,
matching the count independently derived elsewhere in the ledger's §9aw):

| term | hits in the 34-deck asset | where |
|---|---|---|
| "Ever-Living" | 2 | both inside shipped `al-qayyum@1` — its **verse beat** ("the Ever-Living, the Self-Sustaining," 2:255) and its **duʿā beat's `primary`** ("O Ever-Living, O Self-Sustaining...") |
| "Self-Sustaining" | 3 | all three inside shipped `al-qayyum@1` — `name_intro`, verse beat, duʿā beat |
| "does not die" | 0 | — (this deck's own phrase, zero prior hits) |
| "worshipped Allah" | 0 | — |
| "40:65" / any Sūrat Ghāfir citation | 0 | — |
| "3:144" | 0 | — |

**Reading these numbers rather than an adjective (per the ledger's §9ak):** my own `name_intro`
("The Ever-Living") and duʿā vocative both put the string "Ever-Living" on screen. Two prior hits
exist, and **both belong to the same already-shipped deck, `al-qayyum@1`**, both from Ayat al-Kursi
(2:255), where the Qur'ān itself pairs the two Names. Applying the ledger's §9o test — *could a
user read both screens and think they had been told the same thing twice?* — 2:255 is one of the
most widely known āyāt in the tradition; a reader meeting "the Ever-Living, the Self-Sustaining" on
`al-qayyum@1`'s verse beat has met a **formulaic Qurʾānic epithet pair**, ruled non-blocking for
exactly this class in §9be ("the tawḥīd formula is not a bar-3 collision... it will recur on
Al-Hayy"). **This finding is disclosed, not treated as blocking, on that standing ruling — my
`name_intro` is catalogue-locked and cannot be reworded regardless.**

**The duʿā beat looked like a different, harder case and got its own dedicated ruling** — see the
section below. It is resolved the same direction, for a related but distinct reason (prefix/
extension of one narration, rather than a shared formulaic epithet).

### Surface 3 — the move

`al-qayyum@1`'s move is: *the gap was in what you were doing, not in what was holding you up —
nothing that keeps you has ever needed a night off.* Its engine is continuity of **support** through
an interruption (sleep) the human side caused. `al-hayy@1`'s move is: *everyone and everything you
have ever measured your safety against will end — including the most beloved human who ever
lived — and Allah's own life is not on that list.* Its engine is **non-termination of the Namer
Himself**, not continuity of support given to someone else. A user reading both would be told two
different things: one about being held while unconscious, one about the difference between every
created life and the Uncreated one. **No shared narrative, no shared narrator, no shared
century, no shared collection.**

Checked against `al-baqi@1` (id 98, "The Everlasting" — flagged by name in the task): its
claimed engine, read from `.context/claims/98.md`, is *"the inventory inverts — what left is the
part that stayed,"* built on a household scene about a slaughtered sheep and what a family gives
away (Tirmidhī 2470, Qur'ān 16:96). That is about what a **person** spends outlasting what they
keep — a different axis from this deck's claim about Allah's own life not ending. **Zero shared
citation, zero shared rendered string** (checked: "outlast", "remains", "shoulder", "inventory" —
none of these appear in this deck's beats). **Disclosed, not blocking**, and named because the task
asked for it specifically: `al-baqi@1`'s catalogue `english` is "The Everlasting" against this
deck's "The Ever-Living" — one word apart, both catalogue-locked, unfixable inside either deck,
same *Restorer*-class risk the ledger already tracks for id 98 vs `as-samad@1`. **Escalate to the
catalogue track; do not paper over.**

Checked against `as-samad@1` (id 34, "The Eternal Refuge" — flagged by name in the task): its
engine is *"leaning is not weakness"* — the legitimacy of needing support. This deck's beat 8
deliberately avoids the word "lean" (present in id 15's own catalogue `lesson` field, *"Everything
you lean on will pass away — except Al-Hayy"*, which I did not use verbatim for this reason) and
centres instead on **duration** — what ends vs what doesn't — rather than on the psychology of
needing. **Related, not identical; disclosed as a live adjacency rather than closed, matching the
ledger's own practice for close-but-not-collapsed pairs (§3a).**

---

## Duʿā beat — DISCLOSED and RULED (this is the section to read before signing)

**Ruling (coordinator, 2026-08-03): ship with beat 7 as-is, disclosed.** The four measurements
below are facts about one narrated supplication existing at two lengths — id 15 carries the eight
Arabic words of Tirmidhī 3524 in full; id 16 carries the same eight words plus a longer,
additional petition. Applying the ledger's own §9o test — *could a user read both screens and
think they had been told the same thing twice?* — the honest answer is that a user who meets both
decks recognises **one invocation they now know in a short and a long form**, not two decks each
claiming to teach it as their own insight. §9be already settled the formulaic half of this
("`يَا حَيُّ يَا قَيُّومُ` is shared scripture, not a taught insight," naming Al-Hayy as the Name
this would recur on); this section extends that ruling to the prefix relationship specifically.
**This is the same class as the already-accepted *Restorer* (`al-jabbar@1`/`al-muid@1`) and
*"The Everlasting"* (id 98 vs `as-samad@1`) findings — disclosed, catalogue-locked, unfixable
inside either deck, and shipped anyway.** It is escalated to the duʿā de-duplication track
(COLLISION-LEDGER §6e, ~30 Names) as a scheduling fact, not held here as a blocker.

**Measurement, not adjective, per §9ak — the facts the ruling above is decided against:**

1. **Codepoint diff, catalogue `dua_arabic` (id 15) vs Jami' at-Tirmidhī 3524's fetched Arabic:**
   47 characters each side, **1 difference** (`ي` vs `ى`, same word). Rasm-identical.
2. **Codepoint diff, catalogue `dua_arabic` (id 15) vs catalogue `dua_arabic` (id 16, Al-Qayyum,
   read directly from `assets/content/name_stories.json`'s shipped `al-qayyum@1` entry):** id 15's
   47-character string is an **exact prefix** of id 16's 108-character string — every one of id
   15's 47 characters matches the first 47 characters of id 16's, position for position.
3. **The rendered English `primary` on the two decks' duʿā beats:** id 15's catalogue
   `dua_translation` is *"O Ever-Living, O Self-Sustaining, by Your mercy I seek relief."* Shipped
   `al-qayyum@1`'s duʿā beat `primary` (already on screen) is *"O Ever-Living, O Self-Sustaining,
   in Your mercy I seek help. Rectify all my affairs and do not leave me to myself even for the
   blink of an eye."* **The first five words are identical**, and the sixth word differs by one
   preposition (*by/in*) before diverging.
4. **The `dua_translation` gloss-containment finding already on record in the ledger's §6d/§7**
   (id 15's own English contains "Self-Sustaining," Al-Qayyum's catalogue `english`) —
   independently re-confirmed by reading `collectible_names.json` directly.

**All four are properties of the fixed catalogue strings, not of any drafting choice.** This deck
does not touch `collectible_names.json` (forbidden by task rules), and the `dua` beat renders the
catalogue verbatim (spec requirement, ship-gate enforced) — as it must, and as the ruling accepts.

**What I recommended, and what was decided.** Per the ledger's rule 7 ("never action a
recommendation to change catalogue data without independent re-verification" — wrong in both prior
batches) **I did not propose a catalogue edit.** I disclosed the structural fact and named three
options for the founder/coordinator to choose from — (a) ship disclosed, (b) hold for the
catalogue-level duʿā de-duplication pass already scoped in §6e, or (c) treat as a reasoned refusal.
**The coordinator ruled (a).** The reasoning is recorded above and is now the deck's status, not an
open question: beat 7 ships as `DISCLOSED`, escalated to the de-dup track, not marked as a
blocker and not reworded — there is nothing in the beat to reword, since it is catalogue-verbatim.

---

## Sources

| # | Claim | Source (URL) | Grading | Status |
|---|---|---|---|---|
| 1 | Beat 3: ʿUmar's denial; Abū Bakr uncovers the Prophet's ﷺ face and says "You are good in life and in death" | [Sahih al-Bukhari 3667, 3668](https://sunnah.com/bukhari:3667) | ṣaḥīḥ (Ṣaḥīḥ al-Bukhārī, no separate grade line printed — the collection's own standing) | ✅ **verified** via Wayback captures `20220130215814` (bukhari:3667) and `20260129050939` (bukhari:3668) — both resolve to the same combined narration. Arabic: `فَجَاءَ أَبُو بَكْرٍ فَكَشَفَ عَنْ رَسُولِ اللَّهِ صلى الله عليه وسلم فَقَبَّلَهُ قَالَ بِأَبِي أَنْتَ وَأُمِّي طِبْتَ حَيًّا وَمَيِّتًا`. Narrator: ʿĀʾisha. In-book reference: Book 62, Hadith 19. Beat quotes the published English ("you are good in life and in death") as printed — no contested attribute at stake, so not re-rendered. |
| 2 | Beat 4, verbatim: "Whoever worshipped Muhammad — Muhammad has died. Whoever worshipped Allah — Allah is Ever-Living; He does not die." | [Sahih al-Bukhari 3667, 3668](https://sunnah.com/bukhari:3667) | ṣaḥīḥ | ✅ **verified — re-rendered from the Arabic myself, not pasted from the published English** (plan §7 rule 2). Arabic: `أَلاَ مَنْ كَانَ يَعْبُدُ مُحَمَّدًا صلى الله عليه وسلم فَإِنَّ مُحَمَّدًا قَدْ مَاتَ، وَمَنْ كَانَ يَعْبُدُ اللَّهَ فَإِنَّ اللَّهَ حَىٌّ لاَ يَمُوتُ`. The archived page's own English ("No doubt! Whoever worshipped Muhammad, then Muhammad is dead, but whoever worshipped Allah, then Allah is Alive and shall never die") is close; I chose "Ever-Living" over "Alive" to match the catalogue's own gloss for id 15, disclosed as a translation choice, not a doctrinal one. **Disclosed: this is human speech (Abū Bakr's) about Allah, not Allah's own words — it carries bar 2 (shown), and bar 1 is carried separately by beat 6 (40:65).** |
| 3 | Beat 5, near-verbatim, **ellipsis now on the beat**: "Muhammad is only a messenger. Messengers have passed away before him. If he dies, will you turn back?…" | [Qur'ān 3:144](https://quran.com/3/144) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/3:144`, 2026-08-03. Arabic: `وَمَا مُحَمَّدٌ إِلَّا رَسُولٌ قَدْ خَلَتْ مِن قَبْلِهِ ٱلرُّسُلُ ۚ أَفَإِى۟ن مَّاتَ أَوْ قُتِلَ ٱنقَلَبْتُمْ عَلَىٰٓ أَعْقَـٰبِكُمْ`. Beat compresses to one breath; the un-quoted tail ("...will never harm Allāh at all; but Allāh will reward the grateful") is a reward clause, not a warning. **Visible `…` now added to the beat string itself (plan §7's rule), not left in this table only.** |
| 4 | Beat 5's closing: "The people wept." | [Sahih al-Bukhari 3667, 3668](https://sunnah.com/bukhari:3667) | ṣaḥīḥ | ✅ **verified — labelled compression of `فَنَشَجَ النَّاسُ يَبْكُونَ`** ("the people burst into weeping"), same page, immediately following the 3:144 recitation. |
| 5 | Beat 6, verbatim, **ellipsis now on the beat**: "He is the Ever-Living; there is no deity except Him — so call upon Him, sincere to Him in religion…" | [Qur'ān 40:65](https://quran.com/40/65) | Qur'ān | ✅ **verified** — live fetch, 2026-08-03. Arabic: `هُوَ ٱلْحَىُّ لَآ إِلَـٰهَ إِلَّا هُوَ فَٱدْعُوهُ مُخْلِصِينَ لَهُ ٱلدِّينَ ۗ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ`. Beat quotes the first clause only (up to `ٱلدِّينَ`); the doxology tail ("Praise be to Allāh, Lord of the worlds") is omitted for length, not for content. **Visible `…` now added to the beat string itself, not left in this table only.** |
| 6 | Beat 7, duʿā text | catalog id 15 — `dua_arabic` / `dua_transliteration` / `dua_translation` | — | ✅ **verified byte-identical to catalog**, checked programmatically 2026-08-03. **RULED — ships DISCLOSED, not blocking (coordinator, 2026-08-03). See dedicated section above.** `source` field left empty per existing convention for this class of duʿā (catalogue-authored/narrated but not independently pinned in `renderedDuaSources` by this pass) — Tirmidhī 3524 (`Grade: Hasan (Darussalam)`) is recorded above as the underlying narration, rasm-identical to id 15's text, for the founder's transcription-time pin decision. |
| 7 | Beat 2 `name_intro` | catalog id 15 | catalog only | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`. |
| 8 | Not on any beat, fetched for the successor sweep only | [Qur'ān 39:30](https://quran.com/39/30), [39:31](https://quran.com/39/31), [3:143](https://quran.com/3/143), [3:145](https://quran.com/3/145), [40:64](https://quran.com/40/64), [40:66](https://quran.com/40/66) | Qur'ān | ✅ **all fetched 2026-08-03, read in full — see successor sweep table above.** |

---

## Collision check against all 34 decks

Rebuilt from `assets/content/name_stories.json` (34 decks currently transcribed, per the
COLLISION-LEDGER's own header note) plus this file's own citations, 2026-08-03.

| existing deck(s) | citations | collides? |
|---|---|---|
| `al-qayyum@1` (shipped) | Bukhārī 595, Qur'ān 39:42, 2:255 | ✖ **no shared citation on the story/verse axis.** ⚠️ **Duʿā beat — DISCLOSED, ruled non-blocking (coordinator, 2026-08-03): id 15's duʿā is the short form, id 16's the long form, of one narrated invocation — see dedicated section.** ⚠️ Both name_intro-adjacent strings share "Ever-Living" per the token sweep above, separately ruled non-blocking under §9be/§9o (tawḥīd-formula class). |
| `al-wakeel@1` (shipped) | 3:172–174, 65:3, Bukhārī 4563 | ✖ no shared citation. **Considered and rejected as bar-3 ground for using 25:58** (see Surface 1 above) — not because Al-Wakeel touches Sūrat al-Furqān, but because 25:58's own imperative is Al-Wakeel's root. |
| `at-tawwab@1`, `al-muid@1` (shipped/drafted) | Bukhārī 3470 ("died on the road"); Muslim 918a ("When Abū Salama died...") | ✖ no shared citation, no shared phrase. Both use the word "died" in an unrelated narrative context — checked, no phrase overlap with this deck's "does not die" (0 hits, per token sweep). |
| `al-baqi@1` (drafted, id 98) | Tirmidhī 2470, Qur'ān 16:96 | ✖ no shared citation. ⚠️ **name_intro adjacency disclosed above** ("The Everlasting" vs "The Ever-Living") — catalogue-locked on both sides, escalate to catalogue track. |
| `as-samad@1` (shipped) | 19:2–7, 112:2 | ✖ no shared citation. ⚠️ **engine adjacency disclosed above** (leaning vs duration) — not closed, matching the ledger's own §3a practice. |
| all other 29 decks | — | ✖ **verified negative, checked programmatically:** Bukhārī 3667/3668, Qur'ān 40:65, 40:64, 40:66, 3:144, 3:143, 3:145 appear in **zero** other citations across the ledger (grepped in full) and **zero** other decks' `sources[].url` in the transcribed asset. |

**Insight-level check, beat 8** — *"Muhammad ﷺ was the most beloved human being who ever lived, and
even he did not get to stay. Al-Hayy is the one name in that sentence that was true before that
morning and is still true after it."*

| checked against | its insight | verdict |
|---|---|---|
| `al-qayyum@1` (shipped) | "The gap was in what you were doing, not in what was holding you up. Nothing that keeps you has ever needed a night off." | ✖ different claim (continuity of support vs non-termination of the Namer). |
| `as-samad@1` (shipped) | "Leaning is not weakness; it is the meaning of the Name." | ⚠️ adjacent (both about permanence/support), disclosed above, not identical. |
| `al-baqi@1` (drafted) | "She counted what they still had. He counted what was with Allah. The only part of that sheep that did not last is the part they kept." | ✖ different axis (what a person gives away outlasting what they keep, vs Allah's own life not ending). |
| all other insight engines in §3a of the ledger | — | ✖ none match; this beat does not land on "answered while unaware," "known without words," "the un-ended interval," or any of the other listed spent engines. |

---

## Authoring notes (candidates considered and rejected)

- **Selected: Ṣaḥīḥ al-Bukhārī 3667/3668 + Qur'ān 3:144, anchored on 40:65.** Properties no other
  candidate had together: (a) an event with maximal ICP resonance — the death of the single most
  beloved human being in the tradition, processed by the person closest to him; (b) a direct,
  quotable line drawing exactly the distinction this Name teaches, days before the fact could have
  been forgotten; (c) a clean, unpaired Qur'ānic anchor (40:65) carrying the Name as grammatical
  subject with no sibling epithet.
- **Rejected as the verse anchor — 2:255 and 3:2.** The `ٱلْحَىُّ ٱلْقَيُّومُ` epithet pair the
  task named explicitly. 2:255 is also `al-qayyum@1`'s shipped verse beat.
- **Rejected as the verse anchor — 25:58.** Strongest available bar-1/bar-2 sentence, rejected on
  bar 3 (its imperative `تَوَكَّلْ` is Al-Wakeel's own root). See Surface 1 above for the full
  argument — this is an independent re-derivation for Al-Hayy specifically, not an inherited
  assumption from `al-qayyum@1`'s rejection of the same āyah for its own (different) reasons.
- **Rejected as the story — the People of the Cave, Yūnus in the fish, the man who passed a ruined
  town (2:259).** All already spent (`ar-raheem@1`, `al-mujeeb@1`) or explicitly rejected in the
  ledger's §1a/§2d for shape reasons unrelated to this Name (2:259 "its shape is `ar-raheem@1`'s
  centuries-long sleep and awakening," and its engine — a corpse revived — sits closer to
  Al-Muhyi's territory than Al-Hayy's).
- **Deliberately not touched — Qur'ān 30:50 and 41:39.** Reserved for Al-Muhyi (69) per two other
  decks' authoring notes recorded in the ledger's §2d; Al-Muhyi is Al-Hayy's nearer sibling
  (shared root `ḥ-y-y`, "Giver of Life" vs "Ever-Living") and both attributes risk collapsing into
  each other if either deck reaches for a life-giving verb rather than a not-dying declaration.
  This deck contains no `y-ḥ-y`/`aḥyā` verb form anywhere, checked directly against beats 1–8 and
  their underlying source text.

---

## What this method could not determine (state the limits)

1. **Ḥadīth verification is not independent of sunnah.com as a corpus.** Both citations were
   checked via Wayback captures of that one digitisation; no printed edition or Arabic-primary
   database (Shamela, Dorar) was consulted, and **no isnād was audited** — printed grade lines were
   read, not assessed.
2. **The successor sweep on Bukhārī 3667/3668 is qualitative, not exhaustive.** The narration is
   long (it continues into the Ṣaqīfa succession dispute); I read the full page and confirmed no
   quoted or alluded-to material appears there, but I did not attempt a systematic sweep of every
   clause the way the Qur'ānic n±1 sweep works, because ḥadīth narrations are not sequential in
   the way sūrahs are.
3. **Two visible ellipses were owed on the beat text and are now baked into the beat strings
   themselves** — 3:144's un-quoted reward clause and 40:65's un-quoted doxology tail, both marked
   `…` on beats 5 and 6 above, not left only in the Sources table (#3, #5).
4. **I did not re-verify the al-qayyum@1 R2 authoring notes' claim about secondary Arabic sources**
   for a *different* Fāṭima-attributed duʿā route mentioned in the ledger's §7 preamble (via
   islamqa.info / hadithanswers.com). My own duʿā-provenance finding rests entirely on Tirmidhī
   3524, fetched directly, and does not depend on that secondary-source claim being correct.
5. **The "595 rendered strings" baseline is inherited from the ledger's own independently-derived
   count (§9aw), not re-derived from first principles by me** — I ran my own extraction script and
   it produced the same number, which I treat as a cross-check rather than a from-scratch proof.

## Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **coordinator has ruled on the
duʿā beat (ship, disclosed — see above); still awaiting the founder's formal `review_verdict`
before transcription into `assets/content/name_stories.json`.**
