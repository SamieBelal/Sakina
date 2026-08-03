# Deck Draft — Al-Wahhab (wave 4, id 12)

**Status: DRAFT — awaiting independent blind adversarial verification.** Not signed. Nothing in this
file has been through a second pass.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5, §6, §7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md), including §9 in full.
Author: Claude, 2026-08-03. Claim filed **before** drafting at `.context/claims/12.md`; the claims
directory was **re-read immediately before the verification tables below** (ledger §9s).

All scripture verified at draft time by live fetch: `api.quran.com/api/v4/verses/by_key` and the
whole-muṣḥaf endpoint `api.quran.com/api/v4/quran/verses/uthmani`. **This deck cites no ḥadīth** —
see §"Why there is no ḥadīth". **Nothing here is recalled, reconstructed or composed.**

**Translation standard:** Saheeh International (`20`). Five further published renderings of the
verse beat were fetched and compared; see §"The one word this deck does not adjudicate".

---

## The refusal that defines this deck, stated first

**Catalogue id 12's own `hadith` field is Ṣaḥīḥ al-Bukhārī 4684** — *"the hand of Allah is full,
and spending does not diminish it. He gives abundantly day and night."* It is the obvious anchor for
a Name meaning *The Bestower*, and it is **refused**, for two reasons that are both already in the
ledger:

1. **Bukhārī 4684 is already spent** — §2b lists it as `al-kareem@1`'s supporting source.
2. **Its insight is `al-kareem@1`'s beat-8 engine verbatim in substance** — §3a's spent engine
   *the supply does not run down*, rendered on a shipped screen as *"You are not drawing on a supply
   that runs down."*

**Al-Wahhab therefore cannot be a deck about inexhaustible giving. That Name is taken.** It also
cannot be a deck about provision arriving (`ar-razzaq@1`) or need being removed (`al-mughni@1`,
wave 1). What is left, and what the Qurʾān's own vocabulary supplies, is **giving that was not
asked for** — and the Qurʾān has a word for exactly that: **`نَافِلَة`.**

---

## Deck `al-wahhab@1` — Al-Wahhab

**Why this deck exists, in one line:** the user has asked for one specific thing, in specific words,
and is measuring the answer against those words — and the passage is the one where a prophet's
request names **no person, only a quality**, and the āyah gives the quality back on **people he
never named**.

**Proposed metadata**

```json
{
  "deck_id": "al-wahhab@1",
  "name_id": 12,
  "transliteration": "Al-Wahhab",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> You know exactly what you asked for, and in what words. What turns up that you never asked for is another matter, and it has a Name.

**Beat 2 · name_intro** *(catalogue id 12, verbatim, no authored gloss)*:
> الْوَهَّابُ — Al-Wahhab — The Bestower

**Beats 3–5 · story — "The word he asked with":**

> **3.** Ibrahim had left his people and his country behind him, and had been brought to another land.
> *(source line: Qur'an 21:71 — paraphrase)*

> **4.** What he asked for is recorded in one line, and it names nobody. It names a quality: "My Lord, grant me [a child] from among the righteous."
> *(source line: Qur'an 37:100)*

> **5.** What the Qur'an records him being given is Ishaq — and Yaqub, who was Ishaq's son. The asking had reached one generation. What is named reaches two.
> *(source line: Qur'an 21:72; the relation at Qur'an 11:71)*

**Beat 6 · verse** *(quoted in full — no ellipsis, because none is needed)*:
> "And We gave him Isaac and Jacob in addition, and all [of them] We made righteous." — Qur'an 21:72

**Beat 7 · duʿā** *(catalogue id 12, verbatim in full — **`source` PROPOSED**, see the pin section)*:
> رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً
> *Rabbana la tuzigh qulubana ba'da idh hadaytana wa hab lana min ladunka rahmah*
> "Our Lord, do not let our hearts deviate after You have guided us, and grant us mercy from Yourself."
> *(proposed `source`: **Qur'an 3:8 (opening)**)*

**Beat 8 · takeaway:**
> The only thing he specified was what kind of person it should be. That is the word the ayah ends on, and it is on two people he had not named.

---

## The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **demonstrated in the cited text, in Allah's words — not a trailing epithet** | **21:72: `وَوَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ نَافِلَةً`** — a **finite perfect verb, first person plural, Allah the subject, from the Name's own root**, with the giving as the whole content of the clause. There is no epithet in the āyah at all. The second clause `وَكُلًّا جَعَلْنَا صَـٰلِحِينَ` is a second finite verb of Allah's act. **This is the strongest bar-1 form available to this Name, and it is the only one that survives bar 3** — see the enumeration. | **yes — beat 6, and beat 5 by paraphrase** |
| 2 | **shown, not stated** | The deck never says Allah gives generously. It sets **what was asked** (37:100, quoted) beside **what is recorded as given** (21:72, quoted) and lets the reader do the subtraction. The distinguishing quality — *giving past the terms of the request* — is carried by the āyah's own word `نَافِلَةً` (*in addition*) and by the return of `صَـٰلِحِين`, not by the deck's prose. | **yes — beats 4, 5, 6, 8** |
| 3 | **does not collapse into a sibling Name** | Run on all three surfaces (§9an). **Arabic:** 21:72 is the **only** Allah-subject `wahaba` in the Qurʾān with no sibling root anywhere in the āyah. **Token frequency** over every rendered string of all 34 shipped decks: table below. **The move:** differentiated against `al-kareem@1`, `ar-razzaq@1`, `al-mughni@1`, `ash-shafi@1` and `al-qadir@1` below. Three catalogue-locked duʿā collisions are disclosed and escalated. | **yes, with three unfixable disclosures** |
| 4 | **the Name's own root in the source text** | **MET, no trade.** `وَوَهَبْنَا` in the verse beat's cited scripture (21:72), and **`وَهَبْ` in the duʿā beat's Arabic** — the Name's own root is present in both cited passages. ⚠️ **Corrected: this conflated root-present-in-scripture with root-visible-on-screen.** Beat 6 (verse) has **no populated `arabic` field** — it ships English-only, matching the shipped majority — so `وَوَهَبْنَا` does **not** visibly render there; only the English *"gave"* does. **The Arabic root renders on screen exactly once, at beat 7.** **The Name-noun `ٱلْوَهَّاب` is nonetheless unusable** and the deck does not reach for it: all three occurrences fail (below). | **root present in the cited scripture at beats 6 and 7; visibly renders on screen only at beat 7** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | **n+1 (21:73) is clean and confirming** — leaders guiding by Our command, good deeds, prayer, zakāh, *"and they were worshippers of Us."* **n+2 (21:74) carries a Lūṭ clause and is disclosed.** The **backward** direction carries 21:70 and is disclosed. **37:100's own n+1 is disclosed and deliberately unquoted.** | **argued, with three disclosures — see the sweep** |

---

## Bar 4 is MET. Here is the enumeration behind that claim — full text, by form.

**Method.** `api.quran.com/api/v4/quran/verses/uthmani` fetched once (all **6,236** āyāt); marks
stripped, `ٱ أ إ آ`→`ا`, `ة`→`ه`, `ى`→`ي`; consonant-subsequence match on the `هب` skeleton; then
hand-classified against the homographic roots `ذهب`, `رهب`, `شهب`, `هبط`, `لهب`, `هباء`.
**Not a search API** (§9ac).

### `wahaba` with ALLAH as the acting subject — exactly ten occurrences

| citation | text | verdict |
|---|---|---|
| **6:84** | `وَوَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ ۚ كُلًّا هَدَيْنَا` | **Refused, bar 3.** `هَدَيْنَا` renders as *"all of them We guided"* — shipped `al-hadi@1`'s Name-verb in English. |
| **19:49** | `وَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ ۖ وَكُلًّا جَعَلْنَا نَبِيًّا` | **Refused, crowding.** Sūrat Maryam already carries **two** decks (`as-samad@1` 19:2–7; `al-haleem@1` 19:90–91). Otherwise the closest rival to 21:72. |
| **19:50** | `وَوَهَبْنَا لَهُم مِّن رَّحْمَتِنَا` | **Refused, bar 3.** `رَّحْمَتِنَا` → *"mercy"*, `r-ḥ-m`, five decks (`mercy` n=13). |
| **19:53** | `وَوَهَبْنَا لَهُۥ مِن رَّحْمَتِنَآ أَخَاهُ هَـٰرُونَ نَبِيًّا` | **Refused**, same `r-ḥ-m`; and Hārūn **was** asked for (20:29–32), so it is not unasked giving; and `قَدْ أُوتِيتَ سُؤْلَكَ` (20:36) is `al-mujeeb@1`'s move. |
| **21:72** | `وَوَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ نَافِلَةً ۖ وَكُلًّا جَعَلْنَا صَـٰلِحِينَ` | **CLAIMED.** **The only one of the ten with no sibling root anywhere in the āyah** — no `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `h-d-y`, `r-z-q`, `q-d-r`, `ʿ-l-m`. And the only one carrying `نَافِلَةً`. |
| **21:90** | `فَٱسْتَجَبْنَا لَهُۥ وَوَهَبْنَا لَهُۥ يَحْيَىٰ` | **Refused twice over.** Zakariyyā is **spent** by `as-samad@1`; and `فَٱسْتَجَبْنَا` is `al-mujeeb@1`'s own verb, two āyāt from its 21:88, which that deck already fetched as a successor. |
| **29:27** | `وَوَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ وَجَعَلْنَا فِى ذُرِّيَّتِهِ ٱلنُّبُوَّةَ …` | **Refused, bar 5.** Its successors 29:28–35 are Lūṭ's people and their destruction, and **29:14 is already on the ledger's §2d bar-5 rejection list in the same sūrah.** |
| **38:30** | `وَوَهَبْنَا لِدَاوُۥدَ سُلَيْمَـٰنَ` | **Left free, with its problems named.** The only genuinely *unrequested* `wahaba` in the Qurʾān and in a sūrah no deck touches — but n+1 (38:31–33) is the exegetically contested horses episode, 38:24 carries `فَٱسْتَغْفَرَ` (`gh-f-r`, four decks), and it is a single clause with no narrative. **Free for a drafter who can hold those.** |
| **38:43** | `وَوَهَبْنَا لَهُۥٓ أَهْلَهُۥ وَمِثْلَهُم مَّعَهُمْ` | **Refused — Ayyūb is explicitly ledger-rejected** (§1a: shipped `ash-shafi@1`, same doubling, same takeaway). |
| **42:49** | `يَهَبُ لِمَن يَشَآءُ إِنَـٰثًا وَيَهَبُ لِمَن يَشَآءُ ٱلذُّكُورَ` | **Refused, and this is the important one.** Grammatically it is the **strongest** bar-1 form for this Name — present-tense, Allah explicit subject, the Name's root **twice**. It is refused on **register**: **42:50 ends `وَيَجْعَلُ مَن يَشَآءُ عَقِيمًا`** — *"He renders whom He wills barren"* — which is the last sentence anyone struggling with this should meet at 11pm on a reveal screen. Plus the trailing `عَلِيمٌ قَدِيرٌ` = **Al-Aleem (14, drafted this batch)** and **Al-Qadir (75, shipped)**; plus Sūrat ash-Shūrā already carries two decks. **Blocked, not free.** |

### The Name-noun `ٱلْوَهَّاب` — three occurrences, all unusable

| citation | why |
|---|---|
| **3:8** | **Human speech about Allah** — the ledger's rejected class (7:196, 12:101, 10:62, 10:82). It is the speech of `ٱلرَّٰسِخُونَ فِى ٱلْعِلْمِ`. **It is legitimate as the duʿā beat** — a duʿā *is* human speech — but it cannot carry bar 1 on a verse beat, and this deck does not ask it to. |
| **38:9** | `أَمْ عِندَهُمْ خَزَآئِنُ رَحْمَةِ رَبِّكَ ٱلْعَزِيزِ ٱلْوَهَّابِ` — a **rhetorical polemic** (`أَمْ عِندَهُمْ`), with `رَحْمَة` in the construct, and a **trailing epithet pair** whose first member is **Al-Azeez (id 8, being drafted this same wave)**. |
| **38:35** | Sulaymān's speech — **human speech about Allah**, and its petition (`مُلْكًا لَّا يَنۢبَغِى لِأَحَدٍ مِّنۢ بَعْدِى`) is delicate on a reveal surface. |

**Conclusion: bar 4 is met by the verb, never by the noun.** That is worth recording because a
future reader will assume the reverse.

---

## Successor sweep — every quotation, n−1 and n+1, fetched

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **21:72** (n−1) | **21:71** — *"And We delivered him and Lot to the land which We had blessed for the worlds."* | **Clean, and it is beat 3's own source.** It contains no warning and no punishment. |
| **21:72** (n+1) | **21:73** — *"And We made them leaders guiding by Our command. And We inspired to them the doing of good deeds, establishment of prayer, and giving of zakāh; and they were worshippers of Us."* | **Clean and confirming.** It extends the same giving. It contradicts nothing, completes nothing misleadingly, and contains no punishment. ⚠️ **Disclosed:** it carries `يَهْدُونَ` (`h-d-y`, shipped `al-hadi@1`) — **off-screen, quoted nowhere.** |
| **21:72** (n+2) | **21:74** — *"And to Lot We gave judgement and knowledge, and We saved him from the city that was committing wicked deeds. Indeed, they were a people of evil, defiantly disobedient."* | **⚠️ disclosed.** A rebuke clause two āyāt after the verse beat. **My argument:** the subject switches to Lūṭ and a **different city**; nothing in any beat alludes to it; the clause is a **description of a people**, not a threatened punishment; and the intervening 21:73 is entirely positive, so the arc between the excerpt and the rebuke **rises before it turns**. Compare shipped `al-afuw@1`, whose **n+1** ends on *"the disbelievers will have a severe punishment"* and is recorded non-blocking. **This is an argument, not a 404.** |
| **21:72** (backward, n−2 … n−4) | **21:70** — *"And they intended for him a plan, but We made them the greatest losers."* · **21:69** — *"O fire, be coolness and safety upon Abraham."* · **21:68** — *"Burn him and support your gods."* | **⚠️ the sharper backward disclosure.** The fire episode sits three āyāt above the verse beat and its 21:70 ends on the plotters being made losers. **No beat renders any of it.** It is also **adjacent to spent ground**: `al-wakeel@1`'s source table carries Bukhārī 4563, *Ibrāhīm at the fire*. **Deliberately untouched, and a founder who opens `quran.com/21/72` and scrolls up will meet it, so it is named here rather than at review.** |
| **37:100** (n−1) | **37:99** — *"And [then] he said, 'Indeed, I will go to [where I am ordered by] my Lord; He will guide me.'"* | **Fetched because 37:100 opens mid-speech.** ⚠️ **Disclosed:** it ends `سَيَهْدِينِ` (`h-d-y`, shipped `al-hadi@1`). Beat 3 **paraphrases the leaving from 21:71 instead**, so 37:99 reaches no screen and the `h-d-y` clause is never rendered. |
| **37:100** (n+1) | **37:101** — *"So We gave him good tidings of a forbearing boy."* | **⚠️ DELIBERATELY UNQUOTED, and this is a bar-3 decision, not a bar-5 one.** SI renders `حَلِيمٍ` as ***"a forbearing boy"*** — and ***"The Forbearing"* is shipped `al-haleem@1`'s `name_intro` verbatim.** Rendering the passage's own immediate answer would put another Name's gloss on this deck's story beat. **The cost is stated in the next section.** |
| **11:71** | *"And his wife was standing, and she smiled. Then We gave her good tidings of Isaac and after Isaac, Jacob."* | Fetched **solely** to source the Isḥāq→Yaʿqūb relation on beat 5. **Quoted on no beat.** Refused as a story in its own right on bar 5: its successors 11:74–76 are already on the ledger's §2d bar-5 list and 11:77+ is the destruction of Lūṭ's people. |
| **37:112** | *"And We gave him good tidings of Isaac, a prophet **from among the righteous**."* | Fetched as **corroboration only, quoted on no beat** — see the next section. |
| **3:8** (n−1, n+1) | **3:7** (muḥkam / mutashābih; `ٱلرَّٰسِخُونَ فِى ٱلْعِلْمِ`) · **3:9** (*"Our Lord, surely You will gather the people for a Day about which there is no doubt…"*) | Fetched for the duʿā pin. Neither reaches a screen; neither contains punishment. 3:9 is the same speakers continuing. |

---

## ⚠️ The join between 37:100 and 21:72 is AUTHORED. Stated, not buried.

**The deck does not claim 21:72 is the answer to 37:100.** They are in different sūrahs. The passage's
own immediate answer to 37:100 is 37:101, which this deck does not quote (above).

**What the deck does claim, and it is checkable:**

1. 37:100 is a request that **names no person and names one quality**: `مِنَ ٱلصَّـٰلِحِينَ`.
2. 21:72 is a record of what was given, and it **ends on that same word**: `صَـٰلِحِينَ`.
3. Yaʿqūb is Isḥāq's son (11:71).

**And the strongest available answer to the objection that the join is mine:** the Qurʾān runs the
same return **inside aṣ-Ṣāffāt itself** — **37:112** gives him tidings of Isḥāq
`نَبِيًّا مِّنَ ٱلصَّـٰلِحِينَ`, twelve āyāt after `هَبْ لِى مِنَ ٱلصَّـٰلِحِينَ`. **So the pattern of
returning his word to him is the Qurʾān's, not the deck's** — the deck merely takes the version of
it that also carries `وَهَبْنَا` and `نَافِلَةً`. 37:112 is **cited and quoted nowhere**, so nothing
of the sacrifice narrative reaches a screen.

**Beat 5 is worded to state a sequence, not a causation:** *"What the Qur'an records him being
given is…"* — not *"the answer was…"*.

---

## The one word this deck does not adjudicate — `نَافِلَةً`

Six published renderings of 21:72 were fetched:

| translator | rendering |
|---|---|
| Saheeh International (20) | *"And We gave him Isaac and Jacob **in addition**, and all [of them] We made righteous."* |
| Abdel Haleem (85) | *"as an **additional gift**"* |
| The Clear Qur'an (95) | *"as an **additional gift**"* |
| Mufti Taqi Usmani (84) | *"as **gift**"* |
| Yusuf Ali (22) | *"and, as an **additional gift**, (a grandson), Jacob"* |
| Pickthall (19) | *"and Jacob **as a grandson**"* |

**All six carry *addition / gift*. Two of the six (Pickthall, Yusuf Ali) attach it specifically to
Yaʿqūb as a grandson; four read it adverbially over the whole gift.**

**The deck renders SI's *"in addition"* and says nothing about which reading is right.** Beat 5
states Yaʿqūb's relation to Isḥāq as a **fact from 11:71**, not as a gloss on `نَافِلَةً`. This is
the `al-kareem@1` trap (§6.2) and the `an-nur@1` trap (§9z) both named in advance: **a deck can
adjudicate a contested word by choice of translation while believing it has adjudicated nothing.**
Under SI's reading the deck still works — *"in addition"* to what was asked — so the engine does not
depend on the disputed attachment.

---

## Bar 3, surface 1 — Arabic roots in every quoted text

| text | roots it carries | sibling roots present |
|---|---|---|
| **21:72** (verse beat) | **`w-h-b` (`وَوَهَبْنَا`)**, `n-f-l` (`نَافِلَةً`), `j-ʿ-l`, `ṣ-l-ḥ` (`صَـٰلِحِينَ`) | **none** |
| **37:100** (story beat 4) | **`w-h-b` (`هَبْ`)**, `r-b-b`, `ṣ-l-ḥ` | **none** |
| **21:71** (story beat 3, paraphrased) | `n-j-w`, `b-r-k`, `ʿ-l-m` (`لِلْعَـٰلَمِينَ` — *worlds*, not knowledge) | **none** |
| **catalogue duʿā (beat 7)** | **`w-h-b` (`وَهَبْ`)**, `z-y-gh`, `q-l-b`, **`h-d-y` (`هَدَيْتَنَا`)**, **`r-ḥ-m` (`رَحْمَةً`)** | **`h-d-y` — Al-Hadi (33), SHIPPED. `r-ḥ-m` — Ar-Raheem (3) and Ar-Rahman (2), SHIPPED. Catalogue-locked.** |

**Roots absent from every beat except the catalogue-locked duʿā:** `gh-f-r` · `ʿ-f-w` · `ḥ-l-m` ·
`t-w-b` · `r-z-q` · `k-r-m` · `sh-f-y` · `j-b-r` · `q-d-r` · `l-ṭ-f`. **The words *mercy*,
*generous*, *provide*, *forgive*, *heal* and *enrich* appear in no authored string of this deck.**

## Bar 3, surface 2 — token frequency across every rendered string of all 34 shipped decks

Run over `primary`, `translation`, `source` **and `transliteration`**, **from each string's first
character** (§9as).

| token | n before this deck | note |
|---|---|---|
| `bestow` / `bestower` | **0** / **0** | new. ⚠️ but see the `name_intro` note |
| `isaac` · `ishaq` · `quality` · `generation` · `addition` | **0** each | new |
| `jacob` | **0** — but **`jacob's` is n=1**, a hapax at `al-jabbar@1` b3 (inside its SI quotation) | ⚠️ see the move table |
| `yaqub` | **1** — hapax, `al-jabbar@1` b2 | ⚠️ same row |
| `ibrahim` | **1** — `al-baseer@1` b2; plus `ibrāhīm` on `al-qadir@1` b2/b3 | ⚠️ third deck rendering him |
| `righteous` | **1** — hapax, `at-tawwab@1` b3 (*"a righteous town"* — a place) | this deck renders it twice, of persons; **zero shared bigrams** |
| `grant` | **1** — hapax, `ar-raheem@1` **b7 (duʿā)** | ⚠️ **catalogue-locked collision, see below** |
| `guide` / `guided` / `guides` / `guidance` | **6 / 1 / 1 / 2** | the duʿā renders `guided`; catalogue-locked |
| `mercy` / `merciful` | **13** / **9** | the duʿā renders `mercy`; catalogue-locked; volume, not hapax |
| `named` | **10** · `name` **37** | ordinary register (the bridge template uses *Name*) |
| `prayed` / `heir` | `heir` **1** — `as-samad@1` b2. `prayed` **2** — **1** at `as-samad@1` b2, **1** at `an-nur@1` b1 bridge ("to watch how the Prophet ﷺ prayed"). ⚠️ **Corrected**: previously stated both `prayed` hits were at `as-samad@1` b2 — false. | **this deck uses neither, deliberately** — see the move table |

**Cross-corpus n-gram diff of every beat of this deck against every rendered string of all 34
shipped decks, at N=5 and N=4.** Exactly **three hits, all the same one**:

```
b7  "grant us mercy from yourself"  <- ar-raheem@1 b7 dua.primary   (5-gram)
b7  "grant us mercy from"           <- ar-raheem@1 b7 dua.primary   (4-gram)
b7  "us mercy from yourself"        <- ar-raheem@1 b7 dua.primary   (4-gram)
```

**Deck-internal beat-to-beat diff over all 28 pairs (§9al/§9v): zero pairs share a 4-gram.**

## Bar 3, surface 3 — the move (§9an)

| shipped deck | its move | this deck's move | why a user would not feel told the same thing twice |
|---|---|---|---|
| **`al-kareem@1`** [S] — *the supply does not run down*, and its supporting source **is id 12's own card ḥadīth** | *the Giver is not diminished* | *the answer exceeded the terms of the request* | This deck contains no claim about supply, abundance, cost or inexhaustibility, and it **refused Bukhārī 4684 outright** rather than route around it. |
| **`ar-razzaq@1`** [S] — *"provide for them from sources they could never imagine"* | *provision arrives by unseen routes* | as above | Nothing here arrives from an unseen route; the giving is named, listed and public. **This is also why 32:17 / Bukhārī 3244 (*"no eye has seen… nor conceived"*) was fetched and refused** — its move is `ar-razzaq@1`'s verse beat. |
| **`al-mughni@1`** [S] beat 8 — *"He told them what they were already taking home."* (`the unlisted share`) | *what you have that was never distributed to you* | *what was given past what you asked for* | ⚠️ **The nearest engine adjacency.** Al-Mughni's people **asked for nothing and were left out**; this deck's man **asked for something specific and was exceeded**. Zero shared 4-grams. **Disclosed, not ruled.** |
| **`ash-shafi@1`** [S] beat 8 — *"more than there was before the breaking."* | *restoration exceeding the prior state* | as above | ⚠️ **Second-nearest.** Ash-Shafi's excess **repairs a loss**; there is no loss anywhere in this deck. **Disclosed, not ruled.** |
| **`as-samad@1`** [S] beats 2–4 — *an old man with no heir prays for a child and is given one* | *leaning is not weakness* | *his word, extended* | ⚠️ **The staging risk, and it is the one §9ab ruled blocking in another deck.** **What this deck did about it:** it renders **no old age, no childlessness, and never the words *prayer* or *prayed*.** (`heir` n=1 at `as-samad@1` b2; `prayed` n=2 — **1** at `as-samad@1` b2, **1** at `an-nur@1` b1 bridge ("to watch how the Prophet ﷺ prayed"); ⚠️ **corrected** — previously stated both `prayed` hits were at `as-samad@1` b2, which was false; neither token is used here, unaffected by the correction.) Beat 3 is a **migration**, not a lament. **The residual — a prophet asks, offspring are given — is real, and it is for the verifier to rule on, not me.** |
| **`al-qadir@1`** [S] beats 2–3 — *Ibrāhīm asks Allah for something and is answered* | *allowed to ask* | *his word, extended* | ⚠️ Its beat 3 opens `He said: "My Lord, show me…"`. **This deck uses no `He said: "My Lord…"` frame** — the 4-gram `he said my lord` does not occur; the only shared words are `my lord`, which §9o rules a formulaic vocative. Al-Qadir is about **permission to ask**; this is about **what exceeds the asking**. |
| **`al-jabbar@1`** [S] — Yaʿqūb the grieving father | *what broke is mended* | — | ⚠️ **Same person, opposite role.** `yaqub` (n=1) and `jacob's` (n=1) are both hapaxes there; this deck renders **Yaqub** and **Jacob** as *the gift*, never as a father, never grieving. **Zero shared bigrams.** Flagged at full strength because §9ab ruled on exactly this evidence class. |
| **`al-baseer@1`** [S] — Ibrahim leaves Hājar in the valley | *seen when no one sees* | — | Same prophet, different episode, different family member, zero shared strings. **Ibrāhīm now renders on three decks.** |

---

## THE THREE UNFIXABLE COLLISIONS — measured, escalated, not papered over

**All three are on beat 7, which the ship gate locks byte-identical to `collectible_names.json` id 12.
No deck can change any of them.** *Restorer* class (§4b / §9o row 4).

| # | collision | measurement |
|---|---|---|
| 1 | **`ar-raheem@1` [S] duʿā beat** — *"Our Lord, **grant us mercy from Yourself** and guide us rightly…"* (pinned to Qur'an 18:10) | **English: 5-word contiguous run.** **Arabic: 3 words byte-identical** (`مِنْ لَدُنْكَ رَحْمَةً`), plus the shared opening `رَبَّنَا`. **Transliteration: 2 words** (`min ladunka`), plus `Rabbana`. **`grant` was a hapax at n=1**, on that exact beat. **And if the pin below is taken, both decks' duʿā beats will carry a `Qur'an …` source.** §6d.6 records the English and the Arabic; it does not record the hapax, the transliteration axis, or the double-pin. |
| 2 | **`al-hadi@1` [S]** — this deck's duʿā renders `هَدَيْتَنَا` / *"after You have **guided** us"* | Al-Hadi's `name_intro` is *"The Guide"*; its verse beat renders *"Allah surely guides"*. `guide*` is already n=9 corpus-wide. **Not named anywhere in §6d for id 12.** New here. |
| 3 | **id 43 Al-Muizz, *"The Bestower of Honor"*** vs this deck's `name_intro` *"The Bestower"* | §7a.6 already names this as one of three exact-gloss collisions among the remaining 75. 43 is `BLOCKED` on the duʿā axis so it cannot be drafted yet — **but half of it is now spent.** |

**What this deck did with the half it could control:** the words *mercy*, *merciful*, *guide*,
*guidance*, *generous*, *provide* and *enrich* appear in **no authored string** of this deck, and no
quoted scripture carries `r-ḥ-m` or `h-d-y`. That is separation by construction, not decoration —
but it does **not** remove the collision, which is entirely on the locked beat.

**I am recommending no catalogue change.** Three of three such recommendations in this project have
been wrong (§9d, §8.4, §9l).

---

## ⚠️ PIN PROPOSED — `'al-wahhab@1': "Qur'an 3:8 (opening)"`, with its cost

**The measurement.** Catalogue id 12's `dua_arabic` is **the first 12 words of Qurʾān 3:8**,
rasm-identical, differing in **exactly two orthographic words**:

| | catalogue id 12 | Qurʾān 3:8 |
|---|---|---|
| word 10 | `مِنْ` | `مِن` |
| word 11 | `لَدُنْكَ` | `لَّدُنكَ` |

Same rasm (`من` / `لدنك`); the difference is mark placement only. **The omitted tail is three words:
`إِنَّكَ أَنتَ ٱلْوَهَّابُ`** — *"Indeed, You are the Bestower"*, **which is this deck's own Name**.
Nothing is omitted from the front.

**For the pin:** the string is scripture and the truncation is at **one end only**, which
`(opening)` discloses exactly — the same form approved for `al-aleem@1` (§9a) and `al-malik@1`.
The hidden tail is **not** a punishment clause, which is the ground on which `al-khaliq@1`'s pin was
**declined** (§9ag). Pinning tells the user the duʿā they are reciting is the Qurʾān's own.

**Against the pin, and this is the whole cost:** the `source` string puts **Sūrat Āl ʿImrān on a
fourth deck.** §9ai closed that question at **three** — `al-wakeel@1` (3:172–174), `al-malik@1`
(3:26, immovable), `al-aleem@1` (3:35–37) — precisely because `al-khaliq@1`'s 3:191 pin was declined
and it therefore renders nothing from the sūrah. §9b's standing line is *"treat a fourth as the
ash-Shūrā shape."*

**Measured, so the trade is visible:** 3:8 sits **18 āyāt** from 3:26, **27** from 3:35, **164** from
3:172, in a **200-āyah** sūrah. It reaches a **`source` string on a duʿā beat only** — no quotation,
no verse beat. The ash-Shūrā shape §9b names was *three decks in ten āyāt*.

**My recommendation: pin.** **I am not ruling on it** — §9ai's arithmetic is a coordinator's, and
this reopens it.

---

## Why there is no ḥadīth

Six of the 34 shipped decks carry none (`al-hadi@1`, `al-jabbar@1`, `al-lateef@1`, `as-samad@1`,
`ar-raheem@1`, `al-qadir@1`), and `al-wasi@1` shipped as the first deliberately Qurʾān-only deck.
Here the reason is specific: **the Name's own card ḥadīth is `al-kareem@1`'s spent ground** (above),
and the Qurʾānic passage carries bars 1, 2 and 4 by itself. **No ḥadīth was searched for and then
concealed; none was needed, and reaching for one would have been reaching for Al-Kareem's.**

---

## `Claim | Source | Grading | Status`

**Every ✅ below describes a check I ran, with what it measured.**

| # | claim | source (fetched) | grading | status |
|---|---|---|---|---|
| 1.1 | 21:72 reads `وَوَهَبْنَا لَهُۥٓ إِسْحَـٰقَ وَيَعْقُوبَ نَافِلَةً ۖ وَكُلًّا جَعَلْنَا صَـٰلِحِينَ` | `api.quran.com/api/v4/verses/by_key/21:72?fields=text_uthmani&translations=20` | Qurʾān | ✅ fetched; beat 6 is SI's rendering **unaltered**, quoted in full |
| 1.2 | `وَهَبْنَا` is a first-person-plural perfect of the Name's own root, with Allah as subject | fetched Arabic | — | ✅ read off the text |
| 1.3 | 21:72 carries **no** `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `h-d-y`, `r-z-q`, `q-d-r` or `ʿ-l-m` | fetched Arabic | — | ✅ checked word by word — the āyah has 8 words |
| 1.4 | **21:72 is the only one of the ten Allah-subject `wahaba` āyāt with no sibling root in the āyah** | whole-muṣḥaf sweep + all ten fetched individually | — | ✅ **measured**; the enumeration table above records each rejection |
| 2.1 | 37:100 reads `رَبِّ هَبْ لِى مِنَ ٱلصَّـٰلِحِينَ` and names no person | fetched | Qurʾān | ✅ fetched; **SI's bracket `[a child]` is SI's own and is kept visible on the beat** — the Arabic has an elided object |
| 2.2 | 21:72's `صَـٰلِحِينَ` and 37:100's `ٱلصَّـٰلِحِينَ` are the same word, `ṣ-l-ḥ` | both fetched | — | ✅ compared in Arabic |
| 2.3 | **37:112 runs the same return inside aṣ-Ṣāffāt** (`نَبِيًّا مِّنَ ٱلصَّـٰلِحِينَ`) | fetched | Qurʾān | ✅ fetched; **quoted on no beat** |
| 2.4 | **The 37:100 ↔ 21:72 join is authored** | — | — | ⚠️ **stated, not hidden.** Beat 5 is worded as a sequence, never as causation. See the dedicated section. |
| 2.5 | 37:101 renders `al-haleem@1`'s `name_intro` gloss in SI | fetched 37:101 + shipped asset | — | ✅ **measured**: SI = *"a forbearing boy"*; `al-haleem@1` `name_intro` = *"The Forbearing"*. **Quoted on no beat, and the reason is recorded rather than the āyah quietly skipped.** |
| 3.1 | Yaʿqūb is Isḥāq's son | 11:71 fetched — *"tidings of Isaac and after Isaac, Jacob"* | Qurʾān | ✅ fetched; **quoted on no beat**, cited on beat 5's source line |
| 4.1 | Successor sweep: 21:68, 21:69, 21:70, 21:71, 21:73, 21:74 fetched | same endpoint | Qurʾān | ✅ all six fetched; results in the sweep table |
| 4.2 | **n+1 (21:73) contains no punishment** | fetched | — | ✅ read in full |
| 4.3 | **n+2 (21:74) ends on a rebuke** | fetched | — | ⚠️ **disclosed and argued, not ruled** |
| 4.4 | **21:70 (backward, n−2) ends on the plotters being made losers** | fetched | — | ⚠️ **disclosed**; and it is adjacent to `al-wakeel@1`'s Bukhārī 4563 ground. No beat renders any of 21:68–70 |
| 5.1 | **The `w-h-b` root sweep was run over the full 6,236-āyah Uthmānī text, by form** | `api.quran.com/api/v4/quran/verses/uthmani` | — | ✅ **measured, not a search API** (§9ac). Homographs `ذهب / رهب / شهب / هبط / لهب / هباء` hand-filtered |
| 5.2 | `ٱلْوَهَّاب` occurs exactly 3× and all three fail | 3:8, 38:9, 38:35 fetched | — | ✅ fetched and classified |
| 5.3 | 42:49 is the strongest bar-1 form and is refused on 42:50's register | both fetched | — | ✅ fetched. **`وَيَجْعَلُ مَن يَشَآءُ عَقِيمًا` read in the Arabic and in SI.** Refused |
| 6.1 | **Catalogue id 12's `dua_arabic` is the first 12 words of 3:8, rasm-identical, differing in exactly 2 orthographic words** | catalogue file + fetched 3:8 | — | ✅ **computed programmatically**, word-by-word diff; the rasm string of the catalogue is a **prefix** of the rasm string of the āyah |
| 6.2 | The omitted tail is exactly 3 words, `إِنَّكَ أَنتَ ٱلْوَهَّابُ` | same | — | ✅ **computed** |
| 6.3 | Pin `Qur'an 3:8 (opening)` proposed | — | — | ⚠️ **RECOMMENDED, NOT RULED.** Cost measured: Āl ʿImrān on a fourth deck, source string only. **This is a `renderedDuaSources` recommendation, not a catalogue change.** |
| 7.1 | Beat 7 is byte-identical to catalogue id 12's three duʿā fields | catalogue file | — | ✅ copied from the file, not typed |
| 7.2 | **Beat 7 shares a 5-word English run, a 3-word Arabic run and a 2-word transliteration run with shipped `ar-raheem@1` beat 7; `grant` was a hapax** | shipped asset + token pass | — | ⚠️ **measured and escalated. Unfixable inside a deck.** |
| 7.3 | **Beat 7 renders `هَدَيْتَنَا` / *"guided us"*, i.e. shipped Al-Hadi's verb** | shipped asset | — | ⚠️ **measured. New — not in §6d.** Unfixable |
| 8.1 | Cross-corpus n-gram diff of all 8 beats vs all 34 shipped decks at N=5 and N=4 | shipped asset, all four rendered fields, **from character 1** (§9as) | — | ✅ **measured: exactly one collision, beat 7.** Bridge-template runs (*"this Name is about what"*, *"is the Name for"*) were removed by rewriting beat 1 |
| 8.2 | Deck-internal beat-to-beat diff, all 28 pairs (§9al) | this draft | — | ✅ **measured: zero pairs share a 4-gram** |
| 8.3 | `bestow` / `bestower` / `isaac` / `ishaq` / `quality` / `generation` / `addition` are all n=0 corpus-wide | token pass | — | ✅ **measured** |
| 8.4 | `yaqub` (n=1) and `jacob's` (n=1) are hapaxes at `al-jabbar@1` | token pass | — | ⚠️ **measured and disclosed. Not ruled on.** |
| 9.1 | Bukhārī 4684 — id 12's own card ḥadīth — is `al-kareem@1`'s ground | §2b + §3a | — | ✅ read in the ledger; **refused, and the refusal is the deck's premise** |
| 9.2 | Catalogue id 12's `meaning` (*"gives endlessly without expecting anything in return"*) and `lesson` are also in `al-kareem@1`'s register | catalogue id 12 | — | ✅ read. **Card strings, not deck strings. Reported; no change recommended.** Same class as §9ad |

---

## What I could NOT determine, and what a verifier should attack first

1. **Whether the `as-samad@1` staging overlap survives.** *A prophet asks; offspring are given.*
   I removed old age, heirlessness and the word *prayer*, and the beats share zero 4-grams — but
   §9ab ruled a staging repeat blocking on weaker string evidence than this. **Start here.**
2. **Whether the authored 37:100 ↔ 21:72 join is acceptable.** 37:112 is my answer to it. It may not
   be enough.
3. **Whether Sūrat al-Anbiyāʾ can carry a third deck** at 11 and 15 āyāt from two that are already
   an **open founder call** (§2c). I do not resolve that call and I add to it.
4. **The `Qur'an 3:8 (opening)` pin.** Recommended, costed, not ruled — it reopens §9ai.
5. **Whether the duʿā beat's three catalogue-locked collisions are tolerable.** Measured, unfixable
   inside a deck; a "reject" here means a catalogue change or a pack adjacency rule.
6. **`نَافِلَةً`'s attachment.** Six renderings fetched, 4–2 against the *grandson* reading; the
   deck takes neither side, but **whether taking neither side is possible while rendering
   *"in addition"* is itself a judgement** (§9z: refusing to adjudicate does not make a deck
   neutral).
7. **No tafsīr or lexicon corpus was consulted.** The reading of `نَافِلَة` as *a bonus not owed* is
   standard as I understand it, and it is an **unverified premise** of the whole deck.
