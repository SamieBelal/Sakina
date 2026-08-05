# Deck Draft — Al-Ahad (id 74), drafted as a deliberate pair with Al-Wahid (id 73)

**Status: DRAFT, awaiting review.** Drafted from fetched sources; not yet through an independent
adversarial pass. Author: Claude, 2026-08-03.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Governing plan: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md). Claim file: `.context/claims/74.md`.
Sibling deck, same agent, same wave: **Al-Wahid (73)** —
[`2026-08-03-al-wahid-DRAFT.md`](./2026-08-03-al-wahid-DRAFT.md). Read that draft's **"The shared
duʿā screen"** and **"Joint separation note"** sections together with this one — both decks render
the identical duʿā beat and the separation argument is written once, covering both.

All scripture verified at draft time by live fetch: Qurʾān via `api.quran.com/api/v4`
(`fields=text_uthmani,text_imlaei&translations=20`, Saheeh International). Root enumeration
cross-checked against `corpus.quran.com`. **No ḥadīth is used in this deck.**

**Implementation note (binding):** Arabic / transliteration / translation are separate fields.
Verse beat is English-only (`arabic: ""`).

**Personalisation note (§9br, founder decision 2026-08-03):** the beat spine is now `bridge →
name_intro → story ×3 → verse → dua → takeaway → reflection`. The `bridge` and the new trailing
`reflection` are AI-personalised at runtime; what is authored below in those two slots is the
FALLBACK a user reads offline, on model failure, or outside the personalised tier — not a
placeholder. Neither slot carries `source` or `arabic`. The `takeaway` stays fixed; this deck's
bar-3 surface-(c) separation argument lands there and on the fixed story beats, never on the
bridge.

---

## Deck `al-ahad@1` — Al-Ahad — The Unique

**Why this deck exists, in one line:** the obvious anchor for this Name — 112:1, `قُلْ هُوَ ٱللَّهُ
أَحَدٌ` — turns out to be unusable on its own terms, and finding that out first is most of this
deck's actual work. **What replaces it shows incomparability by argument, not by declaration**: no
being shares Allah's own nature, because nothing exists that could be His counterpart.

**Selection ran duʿā-first**, exactly as with Al-Wahid — see that draft's shared-duʿā section. The
request (`اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي`, "gather my scattered self and unify my purpose") does
not, on its own, decide which passage carries Al-Ahad's half; that had to be found separately, and
what follows is why it could not be 112:1.

### Why 112:1 was checked, and set aside — the load-bearing finding of this draft

`قُلْ هُوَ ٱللَّهُ أَحَدٌ` is the one āyah every reader reaches for first. Two independent problems,
checked in order:

**Bar 1.** `قُلْ` is Allah commanding the Prophet ﷺ to *recite* the content that follows — the
whole sūrah, 112:1–4, is the content of that one command. This is the same structural shape as the
ledger's already-rejected human-speech-about-Allah class (7:196, 12:101, 10:62, 10:82), which this
project has consistently ruled out as a bar-1 carrier. Checked directly rather than assumed: **7:196
is itself inside the `قُلْ` opened two verses earlier at 7:195** (`قُلِ ٱدْعُوا۟ شُرَكَآءَكُمْ`,
running straight into 196's first-person `إِنَّ وَلِـِّۧىَ ٱللَّهُ`); **12:101 is Yūsuf's own
first-person duʿā** (`رَبِّ قَدْ ءَاتَيْتَنِى...أَنتَ وَلِـِّۧى`), not `قُلْ`-governed at all — so
the rejected class is broader than "has the word Qul in it," it is *any* instructed-or-reported
first-person human declaration about Allah, and 112:1's content is exactly that once recited.
**112:1 fails bar 1 on this reading.**

**Bar 2, even if bar 1 is granted.** The plan's own brief for this pair states it directly:
*"Oneness is the most stated attribute in the Qurʾān and the least shown… A deck that quotes a
declaration of tawḥīd has stated, not shown."* `هُوَ ٱللَّهُ أَحَدٌ` is precisely that declaration.
Nothing in the āyah demonstrates anything; it asserts.

**Root sweep, to check whether Al-Ikhlāṣ has anything else to offer:** root **أ ح د** occurs **85**
times in the Qurʾān (corpus.quran.com, fetched 2026-08-03): 74× `aḥad` + 11× `iḥ'dā` = **85** ✅
matches the page's own headline. Of the 74 `aḥad` occurrences, **exactly one is glossed by the
corpus as the divine attribute — 112:1 itself, "the One."** 112:4's `أَحَدٌ` (closing `وَلَمْ يَكُن
لَّهُۥ كُفُوًا أَحَدٌ`) is glossed in its generic sense, "any [one]" — it still serves the sūrah's
tawḥīd close but is not a second instance of the Name-form. **Every other occurrence of the root in
the Qurʾān (73 of 74, plus all 11 `iḥ'dā`) means "anyone/one person/one of two" with no connection
to the divine attribute at all.**

**Conclusion, stated as a measurement:** Al-Ahad's root, in its divine sense, is confined to **two
āyāt inside a four-āyah sūrah** (112:1, 112:4), both inside the same disqualifying `قُلْ` scope, one
of the remaining two āyāt (112:2) already spent by shipped `as-samad@1`. **There is no unpaired,
non-`قُلْ`, non-reported-speech Qurʾānic occurrence of `أَحَد` as a divine epithet, anywhere.** This
is not a close call resolved by judgment; it is the entire population of candidates, counted.

**Noted, not actioned:** shipped `as-samad@1` already uses 112:2 without this disqualification being
applied. That deck is one of the 14 that predate the ledger's successor-sweep and rejected-class
rules (`[S]` in the ledger's legend); it is not a precedent this draft relies on, and this draft
does not recommend revisiting it.

**Proposed metadata**

```json
{
  "deck_id": "al-ahad@1",
  "name_id": 74,
  "transliteration": "Al-Ahad",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

**Beat 1 · bridge** *(authored, no scripture)*:
> You have compared, and measured, and still come up short of something. This is the Name for the
> one thing that was never in that competition — not the best of a kind, because there is no kind
> it belongs to.

**Beat 2 · name_intro** *(from `collectible_names.json` id 74, verbatim)*:
> الْأَحَدُ — Al-Ahad — The Unique

**Beats 3–5 · story — "No being shares what He is":**

> 3. The claim being answered: **"But they have attributed to Allah partners - the jinn, while He
>    has created them - and have fabricated for Him sons and daughters without knowledge. Exalted
>    is He and high above what they describe."**
>    *(`source`: Qur'an 6:100)*
>
> 4. The argument: **"…How could He have a son when He does not have a companion [i.e., wife],"**
>    *(`source`: Qur'an 6:101)*
>
> 5. **"and He created all things? And He is, of all things, Knowing."**
>    *(`source`: Qur'an 6:101)*

**Beat 6 · verse** *(the declarative anchor, same passage, one āyah on)*:
> "That is Allah, your Lord; there is no deity except Him, the Creator of all things, so worship
> Him…"
>
> `source`: Qur'an 6:102 (partial — ellipsis on the beat, see sources table)

**Beat 7 · duʿā** *(catalog id 74, verbatim in full — **`source` MUST be empty**):*
> يَا وَاحِدُ يَا أَحَدُ اجْمَعْ شَمْلِي وَوَحِّدْ قَصْدِي لَكَ
> *Ya Wahidu Ya Ahad, ijma' shamli wa wahhid qasdi lak*
> "O One, O Uniquely One, gather my scattered self and unify my purpose for You."

**Beat 8 · takeaway** *(authored — Name₂ slot, pair-synergy line)*:
> Nothing shares what He is — not a rival, not a near match, not almost. **Al-Wahid — the first
> Name of your answer — is the reason nothing else has a say over you; this is the reason nothing
> else is even in the running to be compared to Him.**

**Beat 9 · reflection** *(new, optional, trailing — authored, no scripture, no `source`/`arabic`;
AI-personalised at runtime per §9br; the text below is the offline/model-failure fallback, written
to stand alone)*:
> What comparison have you been carrying today — a version of someone else's life, a standard
> nobody actually set for you? If nothing is even in the same category as Him, what happens if you
> let that comparison go?

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words** | **6:100–102 is Allah's own third-person narration**, no `قُلْ` anywhere in 6:99–104 (checked directly). Beat 4's rhetorical question (`أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ...`) is Allah reasoning in His own narrative voice about why the claim in beat 3 is impossible — not a report of what a human said. | **yes — beats 4–5** |
| 2 | **shown, not stated** | No beat asserts "Allah is unique" or "Allah has no equal" as a bare line. Beat 4–5 show the **impossibility argument itself**: a son requires a consort of the same kind; no consort exists; therefore no being shares His nature. Beat 6's declarative (`لَا إِلَٰهَ إِلَّا هُوَ`) comes *after* the argument, same ordering as `al-haqq@1` beat 7 and this pair's sibling deck. | **yes — beats 4–5** |
| 3 | **no sibling collapse — incl. against Al-Wahid** | See the full three-surface pass in Al-Wahid's draft (run once, covering both — beat-by-beat diff table there). Summary here: this deck's engine is **no rival in kind** (a would-be son/consort sharing Allah's nature); Al-Wahid's is **no rival ruler** (a would-be co-governor of the cosmos). Different noun class of "rival" in each. | **yes** |
| 4 | **the Name's own root appears in the source text** | **Traded, totally — disclosed above as the headline finding of this draft.** No Qurʾānic passage exists that carries `أ-ح-د` as a divine epithet, clears bar 1, and clears bar 2 simultaneously; the sweep is exhaustive (85 of 85 occurrences accounted for). The one place the root's Form II *verb* appears anywhere in this deck pair is the catalogue-locked duʿā (`وَحِّدْ`, on `و-ح-د` not `أ-ح-د` — a different but related root; see Al-Wahid's shared-duʿā section), which this deck does not control and does not count as recovering the trade. | **no — traded in full, sweep recorded** |
| 5 | **no punishment just outside the excerpt** | Successor sweep below. Clean in both directions across 6:99–103. | **yes** |

### What comes immediately before and after each excerpt

| excerpt | fetched | verdict |
|---|---|---|
| **6:100 (n−1) = 6:99** | The rain-and-growth signs passage — *"it is He who sends down rain from the sky, and We produce thereby the growth of all things…palm trees, grapevines, olives, pomegranates…Indeed in that are signs for a people who believe."* | clean, no contradiction; a different register (creation's abundance) leading into 100's rebuke of the partners-claim. Not rendered. |
| **6:100 — quoted in full** | `وَجَعَلُوا۟ لِلَّهِ شُرَكَآءَ ٱلْجِنَّ وَخَلَقَهُمْ ۖ وَخَرَقُوا۟ لَهُۥ بَنِينَ وَبَنَـٰتٍۭ بِغَيْرِ عِلْمٍ ۚ سُبْحَـٰنَهُۥ وَتَعَـٰلَىٰ عَمَّا يَصِفُونَ` | no elision, no ellipsis needed. |
| **6:101, opening — cut, disclosed** | `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` — *"[He is] Originator of the heavens and the earth"* | **⚠️ mandatory cut.** This exact phrase is catalogue id 97 (Al-Badi)'s own duʿā vocative (`يَا بَدِيعَ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ`) and its `hadith` field cites the same root at 2:117. Al-Badi is undecked; quoting `بديع` here spends that ground on the wrong screen. Beat 4 opens with a visible ellipsis instead. |
| **6:101 — the argument, quoted from the cut point** | `أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ وَلَمْ تَكُن لَّهُۥ صَـٰحِبَةٌ ۖ وَخَلَقَ كُلَّ شَىْءٍ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ` | split across beats 4–5 at the natural clause boundary; no word inside either clause changed, added, dropped or reordered. |
| **6:101 (n+1) = 6:102, opening portion — quoted** | `ذَٰلِكُمُ ٱللَّهُ رَبُّكُمْ ۖ لَآ إِلَـٰهَ إِلَّا هُوَ ۖ خَـٰلِقُ كُلِّ شَىْءٍ فَٱعْبُدُوهُ` | rendered as beat 6, ellipsis noted below. |
| **6:102 — the excerpt's own tail, cut, disclosed** | `وَهُوَ عَلَىٰ كُلِّ شَىْءٍ وَكِيلٌ` — *"And He is Disposer of all things."* | **⚠️ mandatory cut.** `وَكِيلٌ` is Al-Wakeel's root, shipped `al-wakeel@1`. Cut with a visible trailing ellipsis rather than rendering a second deck's already-shipped Name-word on this screen. |
| **6:102 (n+1) = 6:103** | *"Vision perceives Him not, but He perceives [all] vision; and He is the Subtle, the Aware."* — `ٱللَّطِيفُ ٱلْخَبِيرُ` | **disclosed, not rendered.** `ٱللَّطِيفُ` is shipped Al-Lateef's root; `ٱلْخَبِيرُ` is undecked Al-Khabeer's. Confirms the deck was right to stop at 6:102 rather than reach one āyah further. |
| **6:100 (n−1 further), 6:104** | 6:104: *"There has come to you enlightenment from your Lord. So whoever will see does so for [the benefit of] his soul, and whoever is blind [does harm] against it. And [say], 'I am not a guardian over you.'"* | fetched, not rendered; contains a first-person Prophetic declaration (`قُلْ`-adjacent), consistent with staying inside 100–102 for the quoted material. |
| **Sūrah-level, 6** | **Sūrat al-Anʿām now carries three decks**: `al-aleem@1` (verse beat only, 6:59), `an-nur@1` (verse beat only, 6:122), and this deck (story **and** verse, 6:100–102). Gaps: 6:59→6:100 is 41 āyāt; 6:102→6:122 is 20 āyāt. This deck's own footprint is denser (three consecutive āyāt used for both story and verse) than either of the other two decks' single-āyah touches. | **disclosed.** Three decks matches the density already accepted for Āl ʿImrān; this deck's internal density (multi-beat within one sūrah) is normal — see `al-haqq@1` for precedent of a single deck spanning several āyāt of the same passage across both story and verse roles. |

### Bar 3 — the three surfaces (full pass run once, in Al-Wahid's draft; summary here)

**1. Arabic roots.** Quoted text carries: `sh-r-k` (partners, 6:100), `w-l-d` (son/beget, 6:101 —
**not spent by any other deck's quoted text, checked**), `kh-l-q` (create, 6:100–102, dense across
the corpus but never the sibling-collapse kind — it is the generic creation-verb, not a Name's own
distinguishing root here), `ʿ-l-m` (Knowing, 6:101 — **this is Al-Aleem's own root, id 14, shipped
this project's wave 1**). **Disclosed, not blocking**: `عَلِيمٌ` closes beat 5 as a trailing
descriptor of Allah, the same word `al-aleem@1`'s `name_intro` renders as its gloss. Checked against
that deck's move: `al-aleem@1`'s engine is a *named female child recognised despite an unmet
expectation* (Maryam's birth); this deck's is *no consort exists to have produced a son*. No shared
rendered string, no shared narrative beat — but the word `Knowing` appearing at all is disclosed
rather than silently accepted, because it is the one place this deck's own quoted text names a
different, already-shipped Name's attribute.

**2. Token frequency**, all 34 decks, checked 2026-08-03. "consort," "equal," "equivalent," "son"
(as *this deck's* claim, i.e. the negation-of-son argument) → checked against every rendered string:
"son" appears in four other decks (`al-jabbar@1`, `ar-rahman@1`, `as-samad@1`, `al-haleem@1`) but
always as *a human son in a story* (Yūsuf, the captive mother's child, Zakariyyā's John, "the
heavens almost rupture" over a claim about Allah taking a son) — **never as this deck's own move**,
which is the logical impossibility argument itself, not a human-son narrative. "unique,"
"consort," "equal," "equivalent," "no equal," "no equivalent," "companion" (in the theological
sense) → **zero** hits elsewhere in the 34-deck corpus.

**3. The move.** See Al-Wahid's draft for the full beat-by-beat diff table (run once, covering
both decks). This deck's move — **no rival in kind, established by the impossibility of a
consort** — is not the move of any shipped or drafted deck, including `as-samad@1` (whose move is
universal *need/dependency*, not *incomparability of kind*) and including `al-haleem@1` (whose 19:90
material this deck does not touch — different sūrah, different argument).

**Disclosed, not blocking — a 4-word doxological overlap with Al-Wahid, undisclosed until now.**
This deck's beat 3 renders 6:100's closing clause, *"…Exalted is He and high above what they
describe"*; Al-Wahid's beat 5 renders 21:22's second clause, *"So exalted is Allah, Lord of the
Throne, above what they describe."* Both are Saheeh International's rendering of the recurring
tasbīḥ formula `عَمَّا يَصِفُونَ`, a closing exaltation the Qurʾān repeats at several points rather
than a claim specific to either passage. Per §9o, a doxological set phrase is shared scripture, not
a taught insight, and is **not blocking** — but per the same rule it must be **disclosed**. It is
disclosed here and on Al-Wahid's draft (full discussion there).

**On the bridge and the separation argument (§9br).** The bridge beat is now the AI-personalisation
slot, overwritten per user, so it cannot carry any part of a bar-3 argument. Checked directly: this
deck's separation from Al-Wahid rests on the **story engine** (beats 3–5, fixed — a rival *in
kind*, a would-be consort, vs. Al-Wahid's rival *ruler*) and on **beat 8's takeaway** (fixed —
"nothing shares what He is" vs. Al-Wahid's "not divided between rivals"), both pre-authored and
rendering identically every time. **§9bp is retired**: the shared "This is the Name for…" opener
both bridges currently use is not worth engineering around now that the bridge is a personalised
fallback most users will not read; no further change is made to it here.

### Sources

| # | Claim | Translation used | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1.1 | Beat 1 bridge | — | authored | n/a | ✅ honest label — authored copy |
| 2.1 | Beat 2 `name_intro` | catalog id 74 | catalog only | n/a | ✅ verified byte-identical: `arabic`=`الْأَحَدُ`, `transliteration`=`Al-Ahad`, `english`=`The Unique`, checked via direct Python equality against `collectible_names.json` 2026-08-03 |
| 3.1 | Beat 3, verbatim: *"But they have attributed to Allah partners - the jinn, while He has created them - and have fabricated for Him sons and daughters without knowledge. Exalted is He and high above what they describe."* | Saheeh International | [Qur'an 6:100](https://quran.com/6/100) | Qurʾān | ✅ verified — live fetch `api.quran.com/api/v4/verses/by_key/6:100`, 2026-08-03. `text_uthmani`: `وَجَعَلُوا۟ لِلَّهِ شُرَكَآءَ ٱلْجِنَّ وَخَلَقَهُمْ ۖ وَخَرَقُوا۟ لَهُۥ بَنِينَ وَبَنَـٰتٍۭ بِغَيْرِ عِلْمٍ ۚ سُبْحَـٰنَهُۥ وَتَعَـٰلَىٰ عَمَّا يَصِفُونَ`. Quoted in full. |
| 4.1 | Beat 4, partial, leading ellipsis: *"…How could He have a son when He does not have a companion [i.e., wife],"* | Saheeh International | [Qur'an 6:101](https://quran.com/6/101) | Qurʾān | ✅ verified — live fetch 2026-08-03. `text_uthmani` (full āyah): `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ ۖ أَنَّىٰ يَكُونُ لَهُۥ وَلَدٌ وَلَمْ تَكُن لَّهُۥ صَـٰحِبَةٌ ۖ وَخَلَقَ كُلَّ شَىْءٍ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`. **Quoted region starts at `أَنَّىٰ`; `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` is cut (see the Al-Badi disclosure above), marked with the beat's own leading "…".** Translator's bracket `[i.e., wife]` retained rather than silently dropped, per project precedent (`al-haqq@1` 3.3). |
| 5.1 | Beat 5, verbatim: *"and He created all things? And He is, of all things, Knowing."* | Saheeh International | [Qur'an 6:101](https://quran.com/6/101) | Qurʾān | ✅ verified — same fetch as 4.1. `text_uthmani`: `وَخَلَقَ كُلَّ شَىْءٍ ۖ وَهُوَ بِكُلِّ شَىْءٍ عَلِيمٌ`. Second clause of the same āyah as beat 4, split at the natural clause boundary. |
| 6.1 | Beat 6, partial, trailing ellipsis: *"That is Allah, your Lord; there is no deity except Him, the Creator of all things, so worship Him…"* | Saheeh International | [Qur'an 6:102](https://quran.com/6/102) | Qurʾān | ✅ verified — live fetch 2026-08-03. `text_uthmani` (full āyah): `ذَٰلِكُمُ ٱللَّهُ رَبُّكُمْ ۖ لَآ إِلَـٰهَ إِلَّا هُوَ ۖ خَـٰلِقُ كُلِّ شَىْءٍ فَٱعْبُدُوهُ ۚ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ وَكِيلٌ`. **Quoted region ends at `فَٱعْبُدُوهُ`; `وَهُوَ عَلَىٰ كُلِّ شَىْءٍ وَكِيلٌ` is cut (Al-Wakeel disclosure above), marked with the beat's own trailing "…".** |
| 7.1 | Beat 7 duʿā | catalog id 74 — no scripture citation claimed | catalog only | n/a | ✅ verified byte-identical to catalog across `dua_arabic`/`dua_transliteration`/`dua_translation`, and byte-identical **to id 73's fields**, both via Python string equality, 2026-08-03. **UNPINNED, `source` empty.** |
| 8.1 | Beat 8 takeaway | — | authored | n/a | ✅ honest label — authored copy. "Nothing shares what He is" → beats 4–5's consort/creation argument; "not a rival, not a near match" → the same; the Al-Wahid cross-reference is the format's pair-synergy convention, matching `as-samad@1`/`al-baseer@1`'s existing pattern. |
| 9.1 | Beat 9 reflection | — | authored | n/a | ✅ honest label — authored copy, no scripture claim. No `source`/`arabic` field, per §9br's ship-gate requirement. AI-personalised at runtime; this is the fallback text, written to stand alone. |

### Disclosed adjacencies (recorded, not blocking)

- **Al-Badi (id 97)** — its own duʿā vocative and `hadith` citation (2:117) both use `بديع
  السماوات والأرض`, the exact phrase cut from the front of this deck's beat 4. Reserved, not spent.
- **Al-Wakeel (id 35, shipped)** — its root `وَكِيل` sits one clause past this deck's beat 6 anchor;
  cut, disclosed, not rendered.
- **Al-Lateef (id 36, shipped) / Al-Khabeer (id 49, undecked)** — both roots (`لَطِيف`, `خَبِير`)
  sit at 6:103, one āyah past this deck's last quotation; not rendered, confirms the stopping point.
- **Al-Aleem (id 14)** — `عَلِيمٌ` closes beat 5 as a descriptor, not this deck's engine; see the
  bar-3 pass above for why this is disclosed rather than blocking.
- **Sūrat al-Anʿām now carries three decks** (`al-aleem@1`, `an-nur@1`, this deck) — see the
  sūrah-level row above.
- **`as-samad@1`** (shipped, 112:2) — this deck deliberately does not use Sūrat al-Ikhlāṣ at all,
  so there is no co-tenancy to disclose beyond the reasoning already given for why 112:1/112:4 were
  set aside.

### Method limits

1. Qurʾān text rests on `api.quran.com` alone for the quotations; `corpus.quran.com` is independent
   *tooling* over root counts, not a second source for the running text itself.
2. No ḥadīth is used, so the sunnah.com/Wayback exposure that applies to most other decks does not
   apply here.
3. This has not been through the adversarial blind-review step. The bar-1 ruling on 112:1
   (structurally equivalent to the rejected human-speech class, extended here to instructed
   recitation rather than reported first-person declaration) is a **reasoning extension of
   existing project precedent, not a re-application of an identical prior ruling** — it is the
   single claim in this draft most likely to be challenged, and it should be the first thing an
   adversarial reviewer attacks.
4. The bar-4 trade is total (no root anywhere in this deck). That is disclosed as a measured fact
   (85-occurrence sweep), not softened — this deck does not attempt to recover the root the way
   Al-Wahid's does on its verse beat, because no non-disqualified occurrence exists to recover.
5. I did not consult a tafsīr on whether 6:101's argument is classically read as *tawḥīd al-ulūhiyyah*
   or a different category; the "no rival in kind" framing is my own reading of what the āyah's own
   logic does (son requires consort; no consort; therefore no son; therefore nothing shares His
   nature the way a child shares a parent's), not a claim about how classical exegesis categorises
   it.

---

**See Al-Wahid's draft for "The shared duʿā screen" (full discussion, not duplicated here) and the
"Joint separation note" (the explicit answer to whether these two Names can be told apart).**
