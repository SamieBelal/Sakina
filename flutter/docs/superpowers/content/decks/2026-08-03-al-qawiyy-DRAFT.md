# Deck Draft — Al-Qawiyy (catalogue id 62) — **R0, awaiting independent blind verification**

**Read with [`2026-08-03-al-mateen-DRAFT.md`](./2026-08-03-al-mateen-DRAFT.md).** Ids 62 and 63 were
assigned and drafted together, deliberately, because they share catalogue `dua_arabic`
byte-identically (ledger §6a group 10, ledger §7 row 62/63 — **BLOCKED** on the duʿā-dedup axis until
the catalogue moves; this draft does not attempt to unblock it, only to build honestly inside it).

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), read in full through §9be.
Claim filed at `.context/claims/62.md` **before** drafting; re-read immediately before the tables below
(see "Re-read at report time").

**Every citation below was fetched live 2026-08-03**, not recalled: Qur'an via
`api.quran.com/api/v4/verses/by_key/{s}:{a}?fields=text_uthmani&translations=20`, over the **full
6,236-āyah Uthmānī text** (`by_chapter/{1..114}`, verse count asserted = 6236) for both root sweeps;
ḥadīth via Wayback CDX captures of the exact bare `sunnah.com` number, fetched and read in both
languages. **Nothing here was composed, reconstructed or recalled.**

---

## ⚠️ Why this Name was rejected before, read first

The project's own record: *"every live anchor is a battle or punishment passage — 22:40 is
permission-to-fight; 33:26 reads 'a party you killed, and you took captive a party.'"* **Both of
those citations are confirmed again in this pass** (fetched fresh, see the enumeration below) — the
earlier reading was correct, not merely asserted. **What is different this time is not a better
verse. It is that this deck does not use a verse for bar 1 at all.**

---

## Deck `al-qawiyy@1` — Al-Qawiyy

**Why this deck exists, in one line:** the user with nothing left to push with, who has been taught —
by every gym poster and every "you are stronger than you know" — that strength is something you
generate. **There is a ṣaḥīḥ narration in which the Prophet ﷺ stopped a group of straining, shouting
companions and taught them nine quiet words that say the opposite.**

**Selection ran duʿā-first.** Catalogue id 62's duʿā is the *ḥawqala* —
`لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ ٱلْعَلِيِّ ٱلْعَظِيمِ` — and its only imperative content is a
negation: **no power and no strength except through Allah.** That sentence, not a definition, is what
the deck is built to demonstrate.

**Proposed metadata**

```json
{
  "deck_id": "al-qawiyy@1",
  "name_id": 62,
  "transliteration": "Al-Qawiyy",
  "chip_keys": [],
  "position_in_pair": 1,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED — content; spine incomplete (no reflection beat)"
}
```

> ⚠️ **`position_in_pair: 1` is a recommendation, not a fact the gate enforces.** Ids 62/63 are not
> one of the 7 `chip_keys` pairs, so — exactly as `al-khafid@1`/`ar-rafi@1` found — the ship gate's
> pair-synergy assertion (`name_stories_ship_gate_test.dart:272–289`) never evaluates a
> `chip_keys: []` deck. Beat 8 is written as pair-synergy language regardless, because the duʿā
> already ties the two Names together on screen; nothing stops either deck being met alone. Recorded,
> not solved — this is now a fourth pair in the same position (Aḍ-Ḍārr/An-Nāfiʿ, Al-Qābiḍ/Al-Bāsiṭ,
> Al-Khāfiḍ/Ar-Rāfiʿ, now Al-Qawiyy/Al-Mateen).

**Beat 1 · bridge:**
> Their voices were giving out on the climb, and the Prophet ﷺ stopped them — not to make them louder. To hand them nine quieter words.

**Beat 2 · name_intro** *(catalogue id 62 `english` verbatim)*:
> الْقَوِيُّ — Al-Qawiyy — The Strong

**Beats 3–5 · story — "Nine words, said quietly":**
> 3. The Prophet ﷺ and his companions were on a journey. Every rise they climbed and every valley they dropped into, they raised their voices with the takbir.
> 4. He came close and said: "Go easy on yourselves — you are not calling on one who is deaf or absent…"
> 5. Then he heard one companion, 'Abdullah ibn Qais, saying it under his breath, and said: "Shall I not teach you a sentence which is from the treasures of Paradise? *There is no power and no strength except through Allah.*"

**Beat 6 · verse:**
> "Allah is the One who created you in a state of weakness, then He created strength after weakness, then created weakness and old age after strength…" — Qur'an 30:54 (excerpt)

**Beat 7 · duʿā** *(catalog id 62, verbatim in full)*:
> لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ
> *La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem*
> "There is no power and no strength except through Allah, the Most High, the Most Magnificent."
> **NO source. UNPINNED** — see "The shared duʿā screen."

**Beat 8 · takeaway (pair-synergy):**
> He wasn't taught to shout louder. He was taught nine quiet words that put all of it back where it already belonged. The strength was never yours on loan, which is why volume added nothing to it. Al-Mateen — the second Name of your answer — is what it is anchored in.

---

## Why this story, duʿā-first

Read first, the duʿā settles the deck: its only content is a negation, not a definition — *no power
except through Allah* — spoken as something a person says, not something asserted about them.
**Then the enumeration confirmed the duʿā's own shape is the only shape this Name can be told in.**

### The `q-w-y` enumeration — full 6,236-āyah Uthmānī text, cross-checked against corpus.quran.com

Corpus built from `api.quran.com/api/v4/verses/by_chapter/{1..114}?fields=text_uthmani` (6,236 āyāt
verified), combining marks folded, alif/yāʾ/tāʾ-marbūṭa variants normalised, matched on the
consonant skeleton, then hand-classified. **42 occurrences — matching corpus.quran.com's root ق-و-ي
page exactly** (the one construct-state instance, `قُوَّتِكُمْ` at 11:52, is undercounted by a naive
skeleton regex and was confirmed by direct verse fetch; final count 42, not 41).

| category | count | detail |
|---|---|---|
| Nominal `qawiyy`, divine | **9** | 8:52, 11:66, 22:40, 22:74, 33:25, 40:22, 42:19, 57:25, 58:21 |
| Nominal `qawiyy`, human | 2 | 27:39 (a jinn), 28:26 (Mūsā, described by Shuʿayb's daughter) |
| Noun `quwwah` | 30 (incl. 11:52's second instance) | see rejection table |
| Active participle | 1 | 56:73, `لِّلْمُقْوِينَ` — "wayfarers" |

**The 9 divine occurrences, read in full and enumerated — the count the earlier rejection predicts:**

| citation | text (trailing clause) | register |
|---|---|---|
| 8:52 | `إِنَّ ٱللَّهَ قَوِىٌّ شَدِيدُ ٱلْعِقَابِ` | Pharaoh's people seized for their sins — **punishment** |
| 11:66 | `إِنَّ رَبَّكَ هُوَ ٱلْقَوِىُّ ٱلْعَزِيزُ` | Ṣāliḥ's people saved — milder, but **trailing `ٱلْعَزِيزُ`** |
| 22:40 | `إِنَّ ٱللَّهَ لَقَوِىٌّ عَزِيزٌ` | permission granted to fight — **the earlier rejection's own citation** |
| 22:74 | `إِنَّ ٱللَّهَ لَقَوِىٌّ عَزِيزٌ` | idols' powerlessness — **trailing `عَزِيزٌ`** |
| 33:25 | `وَكَانَ ٱللَّهُ قَوِيًّا عَزِيزًا` | battle (al-Aḥzāb); **33:26, next āyah, is killing and captivity — the earlier rejection's other citation, reconfirmed** |
| 40:22 | `إِنَّهُۥ قَوِىٌّ شَدِيدُ ٱلْعِقَابِ` | earlier nations seized for disbelief — **punishment** |
| 42:19 | `وَهُوَ ٱلْقَوِىُّ ٱلْعَزِيزُ` | gentle provision — **spent by shipped `al-lateef@1`** |
| 57:25 | `إِنَّ ٱللَّهَ قَوِىٌّ عَزِيزٌ` | iron sent down, "great military might" | 
| 58:21 | `إِنَّ ٱللَّهَ قَوِىٌّ عَزِيزٌ` | "I will overcome" — 58:20/22 frame opponents of Allah as "the most humbled" |

**All 9 of 9 trail immediately with `ٱلْعَزِيزُ`/`عَزِيزٌ`** — bar 1 forbids a trailing epithet, and
this wave's `al-azeez@1` (id 8, **shipped**) has already spent that exact pair as ground (bar 3).
**At least 5 of 9 sit in explicit battle, punishment or rebuke passages.** 42:19 is separately spent.
**Zero of 9 survive.** This is not a near-miss pattern like `ar-rauf@1`'s 9-of-11 attachment
(§9ba) — it is a uniform, unanimous failure, and it is why bar 1 moved to ḥadīth rather than being
traded on a weaker verse.

---

## The five bars

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words — not a trailing epithet** | **Met in ḥadīth, not Qur'an — the enumeration above proves the Qur'an route is exhausted.** Bukhārī 6610: `يَا عَبْدَ اللَّهِ بْنَ قَيْسٍ، أَلاَ أُعَلِّمُكَ كَلِمَةً هِيَ مِنْ كُنُوزِ الْجَنَّةِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ` — the Prophet ﷺ's own direct speech, undoubted (`قَالَ`, not `أَوْ قَالَ`), naming the Name's own root (`قُوَّةَ`) as the content of the taught sentence. | yes — beat 5 |
| 2 | **shown, not stated** | The deck never asserts "Allah is strong." It narrates a specific correction of a specific group's specific behaviour (straining their voices, as if effort were what reached Him), followed by a private moment in which one companion is taught nine words that relocate power entirely. The demonstration is in the sequence, not a claim. | yes — beats 3–5 |
| 3 | **no sibling collapse, incl. against its twin and shipped `ar-razzaq@1`** | Three surfaces run below, plus the twin-diff against `al-mateen@1`. **The largest disclosure is the shared theme with `ar-rauf@1`'s verse beat (root `ḍ-ʿ-f`) — flagged, not hidden.** | see below |
| 4 | **the Name's own root in the source text** | **Met three times over: the ḥadīth's own matn (`قُوَّةَ`), the verse beat (`قُوَّةً` ×2 at 30:54), and the duʿā beat (`قُوَّةَ`, rendered in Arabic on screen).** No trade needed — this Name's difficulty was never bar 4, it was bar 1 + bar 3 together (every Qur'anic occurrence of the epithet fails one or both). | yes — beats 5, 6, 7 |
| 5 | **register — no punishment, no arc terminating in punishment just outside the excerpt** | **This is the bar the earlier rejection failed, and it is where this deck was built most carefully.** No beat renders fighting, killing, captivity, permission-to-fight, or a threat. The ḥadīth's own setting is a journey during a military expedition (disclosed below); nothing martial is quoted, paraphrased or alluded to. | see below |

---

## Register — how this clears the earlier rejection, stated explicitly

**What changed is not the verse. It is the source class.** The earlier draft's every citation was a
Qur'anic occurrence of the epithet itself, and — as the enumeration above reconfirms — every one of
those trails into either the Azeez pair, a punishment clause, or both. **This draft does not use any
of the 9.** Its bar-1 carrier is a ḥadīth whose *content* is: lower your voice, and here is a quiet
phrase. Its verse beat is a life-cycle description (weakness→strength→weakness), not a warfare
context.

**The one honest carry-over: the ḥadīth's setting.** Bukhārī 6610 opens `كُنَّا مَعَ رَسُولِ اللَّهِ
صلى الله عليه وسلم فِي غَزَاةٍ` — "we were with the Messenger of Allah ﷺ **on a military expedition**."
**Disclosed, not concealed, and distinguished from the earlier rejection on the axis that matters:**
33:26's killing-and-captivity is *content on the beat*; 6610's expedition is *setting, never
narrated*. The precedent for this exact distinction is already shipped: `al-wakeel@1` sits
immediately after Uḥud, `al-fattah@1` at Ḥudaybiyyah, and `al-khafid@1`'s own chapter heading is *the
Book of Jihād* — in every case, no fighting, enemy, weapon or gain reaches a beat. **Measured here
too: zero of `fight*`/`battle*`/`enemy*`/`kill*`/`captiv*`/`sword*` renders on any of this deck's
eight strings.**

---

## Successor sweep — every neighbour fetched

`api.quran.com/api/v4/verses/by_key/{k}`, live 2026-08-03.

| excerpt | direction | neighbour | reading |
|---|---|---|---|
| 30:54 | n−1 | **30:53** — "And you cannot guide the blind away from their error…" | clean; 30:54 opens on its own paragraph marker (۞), a fresh unit, not a continuation |
| 30:54 | n+1 | **30:55** — the Hour; criminals swearing they stayed only an hour | not punishment itself; scene-setting for judgement, three āyāt before the first explicit "no benefit" clause (30:57). Disclosed, not quoted or alluded to |
| 30:54 | n+2 | **30:56** — "those given knowledge and faith" correcting the criminals | clean |
| 30:54 | n+3 | **30:57** — "their excuse will not benefit those who wronged" | **the row to attack first.** Not adjacent, not quoted; disclosed at full strength rather than left for a reviewer to find |
| 30:54 | its own tail | `يَخْلُقُ مَا يَشَآءُ ۖ وَهُوَ ٱلْعَلِيمُ ٱلْقَدِيرُ` | **elided, visibly, on the beat** — avoids rendering Al-Aleem (shipped) and Al-Qadeer (undecked) in the trailing pair |
| Bukhārī 6610 | what follows the matn | nothing but the isnād chain reference | clean — the strongest bar-5 form a ḥadīth can offer |
| Bukhārī 6610 | book heading | ⚠️ **R3 correction — this was wrong.** R0 said `كتاب الأدب` (*Book of Manners*); the fetched page shows **`كتاب القدر`, Book 82 (*Divine Will / al-Qadar*)**. **No rendered beat depends on it** — it was supporting colour for the bar-5 argument — but it is a stated fact that was not fetched | disclosed above |

**No 404 / sūrah-final result available** — Sūrat ar-Rūm is 60 āyāt; 30:54 sits well before its end.

---

## Bar 3, all three surfaces (§9an) — plus the twin-diff

### Surface 1 — Arabic roots

| root | where | renders in Arabic? | collision check |
|---|---|---|---|
| `q-w-y` (this Name) | duʿā `قُوَّةَ`; hadith matn (story beat, English-only per convention) | **yes, beat 7 only** | spent by no other deck; its 9 divine Qur'anic occurrences (above) are all unusable, so nothing to collide with |
| `ḍ-ʿ-f` | 30:54 `ضَعْفٍ` ×2 (verse beat, English-only) | no | **⚠️ see the dedicated disclosure below — `ar-rauf@1`'s verse beat (4:28)** |
| `ʿ-l-w` / `ʿ-ẓ-m` | duʿā `الْعَلِيِّ الْعَظِيمِ` | **yes, beat 7** | catalogue-locked (shared with id 63); Al-Ali (52) and Al-Mutaali (84) are both **BLOCKED** on the duʿā axis (§6e) and will not be drafted soon |
| `ʿ-l-m` / `q-d-r` | 30:54 trailing clause | **no — elided** | precisely why it was trimmed |

### Surface 2 — token frequency, current 45-deck asset

**Re-run against the file as it stands now — checked against 45 decks, not "all shipped decks."**
Method: `primary`/`label`/`source`/`translation` extracted programmatically from
`assets/content/name_stories.json`, lower-cased, beat 7 swept from its first character (§9as).

| token | n before this deck | where | ruling |
|---|---|---|---|
| `strong` | 1 | `ar-rauf@1` takeaway ("grew strong enough") | different sense — a capacity threshold vs. this deck's ownership claim. Zero shared 2-grams |
| `power` | 5 | `al-malik@1`, `al-azeez@1`, `al-lateef@1`, `al-haqq@1`, `al-qadir@1` (`dua`) | **none render "no power except through Allah."** `al-lateef@1`'s and `al-malik@1`'s explicitly differentiate FROM power; this deck's is the only one asserting where power belongs. Disclosed, not blocking |
| `weak`/`weakness` | 1 / 1 | `ar-rauf@1` verse (4:28, `weak`); `as-samad@1` takeaway (`weakness`, unrelated sense — "leaning is not weakness") | ⚠️ **the row to read carefully — see below** |
| `treasure`, `paradise`, `valley` (as a takbir-climb image), `abdullah`, `qais`, `quiet`, `climb`, `voices` | 0 each, except `valley` n=6 (`al-mumin@1`, `al-baseer@1`, `ar-rafi@1`) | — | clean, except `valley` — different narratives in every case (a rest-stop, Hājar's search, a road outside Makkah), no shared clause |
| `created` | 3 | `al-khaliq@1` (×2, shipped), `ar-rauf@1` | ordinary Qur'anic register; no shared 3-gram |

**`ḍ-ʿ-f`/"weak(ness)" — full disclosure, not papered over.** Shipped `ar-rauf@1` renders
*"…mankind was created weak"* (4:28, `وَخُلِقَ ٱلْإِنسَـٰنُ ضَعِيفًا`) as its verse beat. This deck's
verse beat renders 30:54's `خَلَقَكُم مِّن ضَعْفٍ` (created you **from** weakness) two clauses into a
weakness→strength→weakness cycle. **Same root, different verse, different grammatical shape** (a
static adjective vs. a dynamic three-stage clause), **and a different move**: Ar-Rauf's engine is
*the demand was reduced, not because anyone got stronger* (mercy through a lowered bar); this deck's
is *the strength itself was never a possession — it was issued and will be reissued* (ownership,
not volume). Zero shared 3-gram between the two rendered clauses. **Offered for a verifier to
overturn rather than ruled clean by the drafter alone (§9ab, §9bd) — this is exactly the class of
finding a drafter must disclose and not adjudicate.**

### Surface 3 — the move

| shipped/drafted deck | its move | this deck's move | separated? |
|---|---|---|---|
| `ar-rauf@1` | the demand was lightened, not the person's capacity raised | the strength was never the person's to hold — it is lent and returned across a life | **flagged above, not silently ruled clean** |
| `al-qayyum@1` | what holds you up never needed a night off (sleep/vigilance register) | what you call your own strength was never continuously yours (ownership, not vigilance) | yes — different axis entirely (staying awake vs. possessing power) |
| `al-azeez@1` | the town added a third messenger; reinforcement, not vindication | a person adds nothing; the phrase relocates what was never theirs | yes |
| `al-haqq@1` | *"some of what has power over you tonight is not solid"* (bridge only) | this deck never characterises what has power over the reader — it names where power itself resides | yes, and the only shared word is `power`, in different grammatical roles |

**Engine, three words:** *quiet, not louder.* Checked against §3a's spent list (`answered while
unaware` · `known without words` · `the un-ended interval` · `allowed to ask` · `handing over is not
quitting` · the rest) — no match.

### The twin-diff — against `al-mateen@1`, beat by beat

| axis | `al-qawiyy@1` | `al-mateen@1` | same deck flipped? |
|---|---|---|---|
| genre | ḥadīth-led (story), Qur'an-reinforced (verse) | ḥadīth-led (story), Qur'an-reinforced (verse) | **structurally parallel by design — see below for why that is disclosed, not hidden** |
| root demonstrated | `q-w-y`, present on 3 beats (story matn, verse, duʿā Arabic) | `m-t-n` present on **zero** beats — full trade, disclosed | **no** — this is the measured asymmetry the brief predicted |
| story | a group straining their voices; a private correction | one woman praying without rest; a private correction | **surface-similar (a corrective moment), engine different** — see below |
| story's citation | Bukhārī 6610 | Bukhārī 43 | different collection, different companion (Abū Mūsā vs. ʿĀʾisha), different narrator gender and setting |
| verse | 30:54 — human strength cycling, weakness→strength→weakness | 50:38 — Allah's own act (creation) meeting no fatigue | **different subject of the demonstration** — a human life-cycle vs. an act of Allah's |
| the move | *quiet, not louder* — power was never generated by effort | *never depleted by you* — capacity that does not reduce | **no** |
| beat-8 shape | pair-synergy, names Al-Mateen | pair-synergy, names Al-Qawiyy | template, not collision (§4b precedent: "the second Name of your answer" is deliberate scaffolding) |

**Programmatic diff, every beat against every beat, excluding beat 7 (byte-identical by
construction):** **n ≥ 4: zero hits.** n = 3: none. **Honest statement of the residual, matching the
`al-qabid@1`/`al-basit@1` precedent:** both decks are built the same *way* (a corrective-moment
ḥadīth + a reinforcing verse) because that is the shape the ḥadīth-forced route produces for both
Names, not because either copies the other. What they share on screen is one duʿā, and it is the
catalogue's screen, not either deck's.

---

## The shared duʿā screen

*(Present verbatim in both drafts, per the brief.)*

**Catalogue ids 62 and 63 carry byte-identical `dua_arabic`, `dua_transliteration` AND
`dua_translation`.** Verified programmatically against `assets/content/collectible_names.json`,
exact string equality:

```
arabic:          لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ
transliteration: La hawla wa la quwwata illa billahil 'Aliyyil 'Azeem
translation:     There is no power and no strength except through Allah, the Most High, the Most Magnificent.
```

Both rows are the same string; the ship gate asserts each deck's `dua` beat byte-identical to its own
catalogue row by `name_id`. **Both decks render a pixel-identical duʿā screen.** This is forced by
the gate and is not a drafting choice.

**Four further facts, measured rather than asserted:**

1. **The phrase is a splice, not a single narration.** The core (`لَا حَوْلَ وَلَا قُوَّةَ إِلَّا
   بِٱللَّهِ`) is attested in multiple ṣaḥīḥ routes — Bukhārī 6610, 4205, 6384 (the treasure-of-Paradise
   ḥadīth) and Ṣaḥīḥ Muslim 385 (the adhān-response ḥadīth) — **fetched directly, and NONE of the four
   carries `ٱلْعَلِيِّ ٱلْعَظِيمِ`.** That pair matches the closing words of Qur'an 2:255, fetched and
   confirmed live: `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ`. **UNPINNED remains correct — this is a report on
   provenance, same class as ids 17/61's splices (ledger §9k), not a recommendation to change the
   catalogue.** Three-for-three prior recommendations were wrong; none is made here.
2. **Its only demonstrable content is a negation of self-generated power** — no imperative, no
   petition beyond the negation itself. That is exactly what forced this Name off the Qur'an's
   trailing-epithet occurrences and onto a ḥadīth whose whole point is the same negation.
3. **The vocative pair `ٱلْعَلِيِّ ٱلْعَظِيمِ` is unrelated to either Name's own root** — it renders no
   sibling-Name gloss (Al-Ali id 52 and Al-Azeem id 50 are both catalogue `english` = "The Most High"
   / "The Magnificent", neither decked, both **BLOCKED** on the duʿā axis).
4. **A user who meets both decks in one session sees the same Arabic, transliteration and English
   twice**, with nothing on the screen telling them which deck they are in — the same shape recorded
   for ids 24/25.

**No catalogue change recommended.** This is a report.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | what it is | why refused |
|---|---|---|
| all 9 divine `qawiyy` occurrences (8:52, 11:66, 22:40, 22:74, 33:25, 40:22, 42:19, 57:25, 58:21) | the epithet itself | bar 1 (trailing `ٱلْعَزِيزُ`) and/or bar 5 (battle/punishment) and/or bar 3 (42:19 spent). Full table above |
| 2:165 — `أَنَّ ٱلْقُوَّةَ لِلَّهِ جَمِيعًا` | "that power belongs to Allah entirely" | a subordinate noun-clause inside "if only the wrongdoers could see, when they see the punishment…" — cannot be excerpted without either keeping the punishment frame or leaving a fragment that is not a sentence. Punishment-embedded either way |
| 18:39 — `لَا قُوَّةَ إِلَّا بِٱللَّهِ` | the Qur'anic root of the ḥawqala's own phrase, in the two-gardens parable | **fails bar 5 at n+1.** 18:40, the very next āyah, is the threatened destruction of the garden — the arc terminates in punishment just outside the excerpt, the exact `al-haleem@1` rev-2 shape. Confirmed live; not re-derived from `al-khafid@1`'s independent rejection of the same passage |
| 11:52 — `وَيَزِدْكُمْ قُوَّةً إِلَىٰ قُوَّتِكُمْ` | Hūd's promise to his people | human speech about what Allah will do — the rejected class (7:196, 12:101, 10:62) |
| 94:5–6 — `فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا` | "with hardship comes ease" | **already fetched and rejected by `ar-rauf@1`'s own claim file** — "no divine-subject verb" (bar 1). Not re-derived; cited from `.context/claims/87.md` |
| 8:60 — `وَأَعِدُّوا۟ لَهُم مَّا ٱسْتَطَعْتُم مِّن قُوَّةٍ` | "prepare against them whatever you are able of power" | military-preparation command, human strength commanded. Battle register |
| Bukhārī 6384 | the same treasure-hadith | **carries the clause under `أَوْ قَالَ`** — the exact trap named in the brief. Not used for any beat |
| Muslim 385 (adhān response) | `لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّهِ` said on hearing "come to prayer" | authentic and on-theme, but adds nothing bar 1 doesn't already have from 6610, and would make the deck a two-collection splice. Cited only for the duʿā-provenance report above |

---

## Claim | Source | Grading | Status

| # | claim | source | grading | status |
|---|---|---|---|---|
| 1 | Story beats 3–5, verbatim/paraphrase of: companions straining voices on a journey; "go easy on yourselves…"; "shall I teach you… a treasure… there is no power and no strength except through Allah" | Wayback capture of `sunnah.com/bukhari:6610`, ts `20260315043934` | **Ṣaḥīḥ al-Bukhārī** — no printed grade line (collection-level inference, §9ag) | ✅ Arabic verified: `فَجَعَلْنَا لاَ نَصْعَدُ شَرَفًا وَلاَ نَعْلُو شَرَفًا وَلاَ نَهْبِطُ فِي وَادٍ إِلاَّ رَفَعْنَا أَصْوَاتَنَا بِالتَّكْبِيرِ`; `يَا أَيُّهَا النَّاسُ ارْبَعُوا عَلَى أَنْفُسِكُمْ فَإِنَّكُمْ لاَ تَدْعُونَ أَصَمَّ وَلاَ غَائِبًا` (**visible ellipsis on the beat — the clause continues `إِنَّمَا تَدْعُونَ سَمِيعًا بَصِيرًا`, dropped to avoid rendering Al-Baseer's gloss, shipped**); `يَا عَبْدَ اللَّهِ بْنَ قَيْسٍ، أَلاَ أُعَلِّمُكَ كَلِمَةً هِيَ مِنْ كُنُوزِ الْجَنَّةِ، لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ` — quoted in full |
| 2 | Corroborating, undoubted route, quoted on no beat | Wayback capture of `sunnah.com/bukhari:4205`, ts `20260308160402` | Ṣaḥīḥ al-Bukhārī | ✅ `أَلاَ أَدُلُّكَ عَلَى كَلِمَةٍ مِنْ كَنْزٍ مِنْ كُنُوزِ الْجَنَّةِ… لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ` — **no shakk on this clause.** Its own shakk (`أَوْ قَالَ لَمَّا تَوَجَّهَ`) concerns whether the occasion was the Khaybar campaign specifically — a different clause, disclosed, not used on any beat |
| 3 | Bukhārī 6384 fetched and **excluded** | Wayback capture, ts `20240617221329` | Ṣaḥīḥ al-Bukhārī | ⚠️ **CONFIRMED CARRIES THE SHAKK** on the exact clause: `فَقَالَ … أَوْ قَالَ ‏"‏ أَلاَ أَدُلُّكَ عَلَى كَلِمَةٍ …`. Recorded so no future drafter reaches for it |
| 4 | Beat 6, excerpt: "Allah is the One who created you in a state of weakness, then He created strength after weakness, then created weakness and old age after strength…" — **Mufti Taqi Usmani (`translations=84`), verbatim, named.** ⚠️ **R1 fix:** R0 kept Saheeh's syntax but swapped in *"old age"* for Saheeh's *"white hair"* (`شَيْبَة`) — a **splice of two translations**, which §9bh bans outright, and it was presented as the `translations=20` fetch. *"Old age"* is attested (Usmani), so the phrasing survives; it now comes from one translation, whole | `api.quran.com/api/v4/verses/by_key/30:54?translations=20,84` | Qur'an | ✅ `ٱللَّهُ ٱلَّذِى خَلَقَكُم مِّن ضَعْفٍ ثُمَّ جَعَلَ مِنۢ بَعْدِ ضَعْفٍ قُوَّةً ثُمَّ جَعَلَ مِنۢ بَعْدِ قُوَّةٍ ضَعْفًا وَشَيْبَةً…` — **visible ellipsis; trailing `يَخْلُقُ مَا يَشَآءُ ۖ وَهُوَ ٱلْعَلِيمُ ٱلْقَدِيرُ` dropped** to avoid rendering Al-Aleem (shipped)/Al-Qadeer |
| 5 | Successor sweep: 30:53, 30:55, 30:56, 30:57 fetched and read | `api.quran.com/api/v4/verses/by_key/{k}` | Qur'an | ✅ all live 2026-08-03; findings in the sweep table above |
| 6 | The `q-w-y` enumeration: 42 occurrences, 9 divine `qawiyy`, all trailing `ʿazeez` | full 6,236-āyah Uthmānī corpus, `api.quran.com/api/v4/verses/by_chapter/{1..114}` | — | ✅ run against the full text, not a search API (§9ac); cross-checked against corpus.quran.com's own root ق-و-ي listing (42, matching); construct-state instance at 11:52 confirmed by direct fetch |
| 7 | 18:39 rejected on bar 5 (18:40 destroys the garden) | `api.quran.com/api/v4/verses/by_key/18:39`, `18:40` | Qur'an | ✅ fetched live; `فَعَسَىٰ رَبِّىٓ أَن يُؤْتِيَنِ خَيْرًا مِّن جَنَّتِكَ وَيُرْسِلَ عَلَيْهَا حُسْبَانًا مِّنَ ٱلسَّمَآءِ فَتُصْبِحَ صَعِيدًا زَلَقًا` confirms the threat |
| 8 | 2:165 rejected on grammar + register | `api.quran.com/api/v4/verses/by_key/2:165` | Qur'an | ✅ fetched; subordinate clause confirmed unexcerptable without the punishment frame |
| 9 | Duʿā splice report — 6610/4205/6384/Muslim 385 all lack `ٱلْعَلِيِّ ٱلْعَظِيمِ`; 2:255 carries it | Wayback captures as above + `api.quran.com/api/v4/verses/by_key/2:255` | mixed | ✅ all four ḥadīth pages checked directly for the phrase (absent in all four); 2:255's `وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ` confirmed live |
| 10 | Beat 2 (`name_intro`) and beat 7 (`dua`) fields | `collectible_names.json` id 62 | — | ✅ byte-identical, read programmatically |
| 11 | `.context/claims/` read at claim time and re-read at report time | `.context/claims/*.md` | project artifact | ✅ 38 files at claim time; re-read immediately before this table — no new file touches 62/63, `q-w-y`, `m-t-n`, 30:54, or Bukhārī 43/6610/4205 |

---

## Read as a user at 11pm

You did not have anything left to add to it tonight. The story is not about someone getting stronger.
It is about a group of people making themselves louder because they thought that was what reaching
Him took, and being stopped — not corrected for trying, told to go easy on themselves — and then one
of them, quietly, already had the right words. Nobody praised him for finding extra strength. He was
handed a treasure for saying nine words that gave the strength away. **The duʿā you are about to say
is the same nine words.** Nothing on this deck tells you to push harder. Every beat says the opposite:
put it down; it was never running on what you had left.

---

## What I could not determine, and what a verifier should attack first

1. **The `ḍ-ʿ-f` disclosure against `ar-rauf@1`'s verse beat is offered, not ruled.** Per §9ab/§9bd, a
   drafter may not adjudicate its own move-collision. This is the row to attack first.
2. **The ḥadīth's `فِي غَزَاةٍ` setting.** Judged non-blocking against shipped precedent (Uḥud,
   Ḥudaybiyyah, the Book of Jihād heading); a founder should read beats 3–5 once with that context in
   mind before signing.
3. **No isnād was audited.** Published grade absence on Bukhārī pages is a collection-level inference,
   per standing project limit. Ḥadīth checking is not independent of sunnah.com as a corpus.
4. **The duʿā's "unpinned" status is a negative I could not fully close** — I checked four specific
   routes and found none carrying the full phrase; I did not run an exhaustive search of every
   duʿā/adhkār compilation.
5. **`position_in_pair: 1`/synergy-beat labelling is a recommendation the gate does not enforce**, the
   same open engineering gap recorded for `al-khafid@1`/`ar-rafi@1`.
6. **Bar-3 surface 2 was run against 45 decks, checked as a number, per the coordinator's mid-run
   correction.** If the asset grows again before transcription, re-run it — a smaller corpus can only
   under-report collisions, never over-report them.
