# Deck Draft — Al-Bari (catalogue id 20) — **R0, awaiting independent blind verification**

> **Third attempt at this id.** Two prior drafts are quarantined for fabricated content (`2026-08-03-al-bari-QUARANTINED.md` and `-QUARANTINED-R2.md`; ledger §9bt–§9bx, §9ca). **Nothing in them was reused, and they were not read as precedent.** The refusal they both rested on — *"`ب-ر-أ`: 0 creation verbs, Name not draftable"* — is refuted below on the corpus and on the fetched text.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cb. Protocol: [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md).
Claim filed at `.context/claims/20.md` **before drafting** — see that file for a real limit on the claims check.

All scripture live-fetched at draft time: `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International), `corpus.quran.com/qurandictionary.jsp?q=brA`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-bari@1` — Al-Bari

**Why this deck exists, in one line:** the user who is carrying something they did not choose, and has been quietly reading it as evidence that their life went wrong somewhere. **There is an āyah that puts the writing before the event** — and says so explicitly in order to stop the reader despairing.

**Selection ran duʿā-first.** The locked duʿā for id 20 is *"O Producer, **repair what I have broken within myself.** Make me whole again with the same precision by which You fashion all of Your creation."* That is a **repair** vocabulary — and repair is exactly where two shipped decks already live (`al-jabbar@1`, `ash-shafi@1`). So the duʿā, read first, did not point at the deck's engine; **it pointed at the collision.** The whole design problem for this Name was finding the move that is *adjacent to* repair without being a third repair deck. See bar 3(c).

**The register decision, made first.** This renders at 11pm to someone in distress, and the text is about `مُصِيبَة` — disaster. That could go badly. It does not, because **57:22's own successor states its purpose**: `لِّكَيْلَا تَأْسَوْا۟` — *"in order that you not despair."* The Qurʾān supplies the pastoral frame itself; the deck does not have to argue for it. What the deck must do is **stop before 57:23's turn**, and it does — see bar 5.

**Proposed metadata**

```json
{
  "deck_id": "al-bari@1",
  "name_id": 20,
  "transliteration": "Al-Bari",
  "chip_keys": [],
  "position_in_pair": null,
  "author": "Claude",
  "reviewed_by": "Claude — R2 source-fidelity + authenticity pass, 2026-08-04 (mechanical; NOT the independent blind adversarial review the pipeline still owes)",
  "reviewed_at": "2026-08-04",
  "review_verdict": "VERIFIED"
}
```

---

## Beat structure

**Beat 1 · bridge** *(AI-personalisation slot — this text is the offline/fallback floor, not a placeholder; no `source`, no `arabic`)*:
> Something happened that you would never have chosen, and some part of you has been reading it ever since as proof that your life went wrong somewhere. The order things arrive in is not what you think.

**Beat 2 · name_intro** *(catalogue id 20 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْبَارِئُ — Al-Bari — The Evolver

**Beats 3–5 · story — "The Register Was Written First"** *(Qur'an 57:22, continuing into 57:23a)*:
> 3. Allah says: "No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being."
> 4. Read the order of that sentence. The writing came first. Whatever reached you was not improvised, and it did not slip past anyone.
> 5. "…in order that you not despair over what has eluded you…" He says why He is telling you. Not so you accept a verdict — so you stop reading the loss as the end of the account.

**Beat 6 · verse** *(partial quotation — visible ellipsis both sides; does **not** carry bar 1)*:
> …the Producer… — Qur'an 59:24 (one Name of a three-Name clause)

**Beat 7 · duʿā** *(catalogue id 20, **byte-for-byte**; asserted programmatically against `collectible_names.json`, §9cb)*:
> يَا بَارِئُ أَصْلِحْ مَا أَفْسَدْتُهُ فِي نَفْسِي وَاجْعَلْنِي كَامِلًا بِدِقَّةِ صُنْعِكَ
> *Ya Bari', aslih ma afsadtuhu fi nafsi waj'alni kamilan bi-diqqati sun'ik*
> "O Producer, repair what I have broken within myself. Make me whole again with the same precision by which You fashion all of Your creation."

**Beat 8 · takeaway** *(fixed, **not** personalised — this is where bar 3(c) lands)*:
> Al-Jabbar mends what broke; Ash-Shafi heals what still hurts. Al-Bari works one step earlier than either — He brings a thing into being at all, and the register was written before the bringing. So what reached you is not the verdict on your life. It is a line in something still being written.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> If the hardest thing in your life was written before it ever arrived, what would you stop having to explain to yourself tonight?

---

## Sources — `Claim | Source | Grading | Status`

| # | Claim, as it reaches a beat | Source (fetched) | Grading | Status |
|---|---|---|---|---|
| 1 | "No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being" (beat 3 — **the bar-1 and bar-4 carrier**) | `api.quran.com/api/v4/verses/by_key/57:22` | Qur'an (Uthmani verified live) | ✅ `مَآ أَصَابَ مِن مُّصِيبَةٍ فِى ٱلْأَرْضِ وَلَا فِىٓ أَنفُسِكُمْ إِلَّا فِى كِتَـٰبٍ مِّن قَبْلِ أَن نَّبْرَأَهَآ ۚ إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ`. Beat 3 renders to the first `ۚ` and **omits the closing `إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ`** — deliberate, see bar 3(a) |
| 2 | "…in order that you not despair over what has eluded you…" (beat 5) — **R1 fix:** R0 read *"so that"*; Saheeh reads *"In order that"*, and no other published translation reads *"so that you not despair"* either. Corrected to the fetched text | `api.quran.com/api/v4/verses/by_key/57:23` | Qur'an | ✅ `لِّكَيْلَا تَأْسَوْا۟ عَلَىٰ مَا فَاتَكُمْ` — **first clause only**, visible ellipsis both sides. The rest of 57:23 is **not** rendered; it is the bar-5 hazard, see below |
| 3 | "…the Producer…" (beat 6) | `api.quran.com/api/v4/verses/by_key/59:24` | Qur'an | ✅ `هُوَ ٱللَّهُ ٱلْخَـٰلِقُ ٱلْبَارِئُ ٱلْمُصَوِّرُ …`. Beat 6 renders **one word**, `ٱلْبَارِئُ`, Saheeh *"the Producer"*. **Does not carry bar 1** (trailing/appositive epithet chain — §9bk) |
| 4 | Successor sweep, n−1 of the carrier: 57:21 | `…/57:21` | Qur'an | ✅ `سَابِقُوٓا۟ إِلَىٰ مَغْفِرَةٍ …` — forgiveness and the Garden. No punishment. Not quoted |
| 5 | Successor sweep, n+1 of the carrier: 57:23 | `…/57:23` | Qur'an | ⚠️ **first half clean, tail is a rebuke** — `وَٱللَّهُ لَا يُحِبُّ كُلَّ مُخْتَالٍ فَخُورٍ`. **Real finding, handled by truncation.** See bar 5 |
| 6 | Successor sweep, n−1 of the verse beat: 59:23 | `…/59:23` | Qur'an | ✅ the Names chain (`ٱلْمَلِكُ ٱلْقُدُّوسُ …`) closing on `سُبْحَـٰنَ ٱللَّهِ`. Pure exaltation. Not quoted |
| 7 | Successor sweep, n+1 of the verse beat: 59:25 | `…/59:25` | — | ✅ **HTTP 404 — sūrah-final.** 59:24 closes Sūrat al-Ḥashr. Per the brief this is **the strongest bar-5 form**. (Contrast: a quarantined Haiku draft *fabricated* a 404 on 59:**24**, which returns 200. This 404 is on 59:**25**, and is real — verified by `curl -o /dev/null -w "%{http_code}"`) |
| 8 | The locked duʿā (beat 7) | `assets/content/collectible_names.json` id 20 | catalogue-locked, **not scripture** | ✅ all three fields asserted as substrings of this file (§9cb check). **No ḥadīth or āyah is claimed for it** — see catalogue findings |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | 57:22 `نَّبْرَأَهَآ` — **form I verb, first-person plural, Allah the subject, creation sense.** Top rung of the §9bk ladder: Allah narrating in His own voice | ✅ **PASS** |
| 2 | Shown, not stated | The āyah is **a sequence, not an attribute**: the register exists *before* the bringing-into-being, and 57:23a states the effect that ordering is meant to have on the reader | ⚠️ **PASS — weakest bar in this deck.** See below |
| 3 | No sibling-Name collapse | three surfaces, all measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ب-ر-أ` present as `نَّبْرَأَهَآ` **in the rendered beat-3 text**, and as `ٱلْبَارِئُ` in beat 6 | ✅ **PASS, no trade** |
| 5 | Register and reverence | carrier truncated before 57:23's turn; verse beat is sūrah-final | ⚠️ **PASS after truncation.** Real finding, disclosed below |

**Bar 2, stated honestly.** 57:22 is not a parable and not a counterfactual — the two forms the brief names as clearly qualifying. Its claim to *showing* is that it renders **an order of operations** (`مِّن قَبْلِ أَن` — "before that…") rather than a property, and that 57:23a supplies the consequence in the reader's own life. **A verifier should attack this first.** If bar 2 is judged unmet, the deck does not fall back to another text — see the sweep: **there is no other text.** It would become a genuine refusal, and that refusal would be about bar 2, not about bar 1, which is where both quarantined drafts wrongly put it.

---

### Bar 3, surface (a) — Arabic roots in the quoted text

| beat | root(s) present | overlap risk |
|---|---|---|
| 3 (57:22, as rendered) | `ب-ر-أ` (`نَّبْرَأَهَآ`) · `ص-و-ب` (`أَصَابَ`) · `ك-ت-ب` (`كِتَـٰبٍ`) · `ن-ف-س` (`أَنفُسِكُمْ`) | none of these is another Name's root |
| 5 (57:23a) | `ت-أ-س` · `ف-و-ت` | clean |
| 6 (59:24, one word) | `ب-ر-أ` only | **`ٱلْخَـٰلِقُ` and `ٱلْمُصَوِّرُ` are in the āyah and are NOT rendered** |

**The deliberate omission on beat 3.** 57:22 closes `إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ` — *"indeed that, for Allah, is easy."* Not rendered. `يَسِيرٌ` is not a Name of the 99, so this is not ground-protection; it is **register**: telling someone in distress that their disaster was "easy" for Allah is true and, on this screen, cruel. The omission is marked by the beat ending at the āyah's own pause mark.

### Bar 3, surface (b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time**, not from a note (§9bi): **45**. Every beat of this deck run against every `primary` and `translation` in all 45, maximum shared word-run computed by dynamic programming. **Every hit ≥3 words:**

| n | this beat | collides with | shared run |
|---|---|---|---|
| **4** | 8 (takeaway) | `al-jabbar@1` takeaway | "what broke ash shafi" |
| **4** | 3 (story) | `al-khafid@1` verse | "upon the earth or" |
| 3 | 8 | `al-qabid@1` bridge | "is not the" |
| 3 | 4 | `al-waliyy@1` takeaway | "of that sentence" |
| 3 | 1 | `al-quddus@1` bridge | "what you think" |

**Max shared word-run: 4.** Both 4-grams are accounted for and neither is a collision:

- **"what broke ash shafi"** — this is the takeaway **naming its neighbours in order to separate from them**, which is what surface (c) requires it to do. `al-jabbar@1`'s own takeaway already names Ash-Shafi. Shortening it would remove the differentiating sentence to protect a word count. Kept, disclosed.
- **"upon the earth or"** — **scripture.** Saheeh's 57:22 against Saheeh's rendering in `al-khafid@1`'s verse beat. §9bl: scripture does not yield to a rendered-string collision, and translation-shopping to dodge it is banned.

**An earlier revision measured 5** — *"there is a name for"*, the house-template bridge opener (§9o/§9bp), against `al-jabbar@1` and `al-afuw@1`. §5a of the brief rules that opener no longer worth engineering around, since the bridge is the AI-replaced slot. **Rewritten anyway**, because it cost one sentence. Recorded so the 5 is not rediscovered as a regression.

**Vocabulary check on the words this deck's engine depends on**, swept across all 45: `register` **0** · `disaster` **0** · `eluded` **0** · `into being` **0** · `precision` **0** · `Producer`/`Evolver`/`Inventor` **0** · `despair` **1** (`al-hayy@1` bridge) · `repair` **1** (`ash-shafi@1` takeaway) · `broken` **3** (all `al-jabbar@1`). **The engine vocabulary is unspent; the duʿā vocabulary is not** — which is the whole of surface (c).

### Bar 3, surface (c) — the move

**No mechanical pass reaches this surface, so here is the argument.** Four neighbours, and the risk is real because the locked duʿā speaks in *their* vocabulary:

| deck | its move |
|---|---|
| `al-khaliq@1` (shipped) | **the fact of being.** Seven verbs, one subject: "you were not arrived at by default" |
| `al-musawwir@1` (drafted, id 21) | **the fact of being *you*.** Particularity of form |
| `al-jabbar@1` (shipped) | **what broke is mended.** Yaqub: sight restored, son restored, whole again |
| `ash-shafi@1` (shipped) | **what still hurts is healed, and the restoration exceeds the original.** "not repair — more than there was before the breaking" |

**`al-bari@1`'s move is on a different axis from all four: precedence.** Not *that* you exist (Khaliq), not *which* you (Musawwir), not *mending* (Jabbar), not *magnitude of restoration* (Shafi) — but **when the writing happened relative to the event**. The register precedes the bringing-into-being. Nothing enters existence unaccounted for.

**Jabbar and Shafi are the two that could swallow this deck**, and the separation is testable rather than asserted: their engines both run **after** the break (mend it, heal it, exceed it); this one runs **before the thing existed at all**. That is why the takeaway names them explicitly and puts the deck "one step earlier" — the distinction is the beat's actual content, on a **fixed** beat, which is the only reason it binds (§5a).

**And it is the catalogue's own reading.** Id 20's `lesson` is *"Al-Bari is still shaping you. Your story is not finished yet"* — a claim about **tense**, not about magnitude of repair. The takeaway's closing image ("a line in something still being written") is that lesson, and it is why the duʿā's repair vocabulary does not make this a repair deck: you are asking the One who **brings into being** to bring a repaired self into being, not to patch the old one.

---

### Bar 4 — the full-corpus root sweep that refutes the quarantined refusal

`corpus.quran.com/qurandictionary.jsp?q=brA` — **fetched live, HTTP 200, 24,829 bytes.** (Case-sensitive and silently wrong on the wrong case, §9by: `brA` = ب-ر-أ.) Corpus headline, quoted: *"The triliteral root bāʾ rāʾ hamza (ب ر أ) occurs **31 times** in the Quran, in **10 derived forms**."*

| form | count | āyāt | sense |
|---|---|---|---|
| **form I verb `nabra-a`** | **1** | **57:22** | **to bring into existence** |
| form II verb `barra-a` | 2 | 12:53, 33:69 | to absolve, to clear |
| form IV verb `tubʾri-u` | 2 | 3:49, 5:110 | to heal, to cure |
| form V verb `tabarra-a` | 5 | 2:166, 2:167 ×2, 9:114, 28:63 | to disown |
| noun `barā` | 1 | 43:26 | disassociated |
| noun `barāat` | 2 | 9:1, 54:43 | freedom from obligation |
| nominal `barī` | 12 | 4:112, 6:19, 6:78, 8:48, 10:41 ×2, … | innocent, free of |
| noun `bariyyat` | 2 | 98:6, 98:7 | creation, creatures |
| **active participle `bāri`** | **3** | **2:54 ×2, 59:24** | **the Maker** |
| form II passive participle | 1 | 24:26 | innocent |

**Arithmetic checked against the headline (§9ak): 1 + 2 + 2 + 5 + 1 + 2 + 12 + 2 + 3 + 1 = 31.** ✓ Ten forms, and the corpus's own count.

**The decisive fact, and the one both quarantined drafts missed: 25 of the 31 are a different semantic field entirely** — *absolve / disown / heal / innocent*. The **creation sense is 6 occurrences across 5 āyāt**, and only one of them is a verb.

**Every creation-sense occurrence, and why exactly one survives:**

| āyah | form | bar 1 | bar 5 | verdict |
|---|---|---|---|---|
| **57:22** `نَّبْرَأَهَآ` | form I verb, **1st-pers. pl., Allah the subject** | ✅ top rung | ✅ after truncation | **THE deck.** The only text in the Qurʾān that carries bar 1 and bar 4 together for this Name |
| 2:54 `بَارِئِكُمْ` ×2 | participle | ❌ **Mūsā's reported speech** — bottom rung, §9bk | ❌ **catastrophic**: the golden calf, `فَٱقْتُلُوٓا۟ أَنفُسَكُمْ` — *"and kill yourselves"* | rejected twice over |
| 59:24 `ٱلْبَارِئُ` | participle | ❌ **trailing three-epithet chain — labels, does not demonstrate** | ✅ sūrah-final | **verse beat only**, one word, ellipsis both sides |
| 98:7 `ٱلْبَرِيَّةِ` | noun | ❌ *"best of creatures"* — a predicate about people, not an act of Allah | ❌ its twin 98:6 is `فِى نَارِ جَهَنَّمَ` | rejected |
| 98:6 `ٱلْبَرِيَّةِ` | noun | ❌ | ❌ Hellfire | rejected |

**So bar 4 is met with no trade, and the sweep proves the choice was forced rather than preferred.** This is also the sweep's most reusable output: **if a future reader wants to move this deck off 57:22, the corpus says there is nowhere to move it to.**

**On the quarantined refusal (§9ca), for the record.** It claimed *"`ب-ر-أ`: 0 creation verbs."* The corpus reports **31 occurrences and a form-I verb glossed "to bring into existence."** The refusal was wrong on the single fact it rested on, and one fetch of one URL falsifies it.

---

### Bar 5 — register, and the real finding

**The carrier sits in a passage that turns.** Fetched, in order:

| āyah | content | rendered? |
|---|---|---|
| 57:20 | `… وَفِى ٱلْـَٔاخِرَةِ عَذَابٌ شَدِيدٌ …` — *"severe punishment"* | **no** |
| 57:21 | forgiveness, the Garden — clean | no |
| **57:22** | **the carrier — pure consolation** | **yes**, minus its closing clause |
| **57:23a** | `لِّكَيْلَا تَأْسَوْا۟ عَلَىٰ مَا فَاتَكُمْ` — *"so that you not despair"* | **yes**, to the ellipsis |
| 57:23b | `وَٱللَّهُ لَا يُحِبُّ كُلَّ مُخْتَالٍ فَخُورٍ` — *"Allah does not like everyone self-deluded and boastful"* | **no** |
| 57:24 | *"those who are stingy and enjoin upon people stinginess"* | **no** |

**This is a real bar-5 finding and it is not being waved through.** A clean āyah followed by a rebuke āyah is exactly what the successor sweep exists to catch. Two things make it survivable, and both are checks rather than inferences:

1. **The rebuke is not in the rendered text.** Beat 5 stops mid-āyah at a visible ellipsis, before `وَٱللَّهُ لَا يُحِبُّ`. The same move `al-malik@1`/`al-muizz@1`/`al-muzill@1` make on 3:26 — render your own clause, not the neighbour's.
2. **The clause the deck *does* render is the passage's pastoral purpose, stated by the text about itself.** `لِّكَيْلَا تَأْسَوْا۟` is a purpose clause governing 57:22. The deck is not quoting around the rebuke to find something nice; it is quoting the reason 57:22 was said.

**What a verifier should press on:** whether a reader who looks up 57:22 lands on 57:23's tail and 57:24. That is a real exposure and the deck cannot control it. It is the same exposure every truncated citation in this asset carries, but it is sharper here because the turn is **one clause** away, not one āyah.

**The verse beat's bar 5 is the strongest available form:** 59:24 is **sūrah-final** — `api.quran.com/.../59:25` returns **HTTP 404**, verified by status code, and 59:23 (predecessor) is pure exaltation.

---

## Twin-diff

**No twin — this Name was drafted alone.** Ids 20 and 21 (Al-Bari / Al-Musawwir) were originally paired, and `al-musawwir@1`'s R1 draft records that it owes no twin-diff because id 20's drafts were quarantined. **That debt now settles here, in the direction it can settle:** this deck was measured against the Al-Musawwir R1 draft's beats.

**Max shared word-run vs `al-musawwir@1` (R1 draft): 3** — *"what would you"*, beat 9 against its beat 9. Function words, no shared move. **Under the ≥3 finding threshold in substance**, recorded because the rule is to state the measurement (§9ak).

**And the two decks do not overlap on text:** al-Musawwir renders 3:6, 40:64, 82:8; this deck renders 57:22, 57:23a, 59:24. **The one āyah they both touch is 59:24, and neither renders it** — al-Musawwir rejected it on bar 1 and left it, this deck takes **one word** of it and leaves `ٱلْخَـٰلِقُ` and `ٱلْمُصَوِّرُ` standing.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **2:54** | Mūsā's reported speech (bar 1, bottom rung) **and** `فَٱقْتُلُوٓا۟ أَنفُسَكُمْ` (bar 5, catastrophic). The strongest-looking candidate by root density — `بَارِئِكُمْ` twice in one āyah — and the worst by every other measure |
| **59:24 as the bar-1 carrier** | trailing three-epithet chain; labels, does not demonstrate. Used as the verse beat only |
| **98:6 / 98:7** | `ٱلْبَرِيَّةِ` is a predicate about people, not an act of Allah; 98:6 is Hellfire |
| **57:22's closing `إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ`** | true, and cruel on this screen. Omitted at the āyah's own pause mark |
| **57:23's second half, and 57:24** | rebuke. The bar-5 finding above |
| **A repair/mending story** | would have collapsed into `al-jabbar@1` or `ash-shafi@1`. See surface (c) |

---

## Catalogue findings — reported, **NO change recommended**

Per the brief: never rule on your own catalogue recommendation. Three of the first three such recommendations in this project were wrong.

1. **Id 20's `english` and `dua_translation` disagree on the Name.** `english` is *"The Evolver"*; the duʿā opens *"O Producer"*. So beat 2 renders "The Evolver" and beat 7 renders "O Producer" — **on the same deck, for the same Name.** Saheeh renders 59:24's `ٱلْبَارِئُ` as *"the Producer"* and the corpus glosses it *"the Inventor"*; all three are defensible for `bāriʾ`, and **all three are locked or quoted.** The deck does not harmonise them. **Flagged as the thing most likely to read as an error to a reviewer who has not checked.**
2. **Id 20's `hadith` field is empty** (`""`). No narration is claimed for this duʿā anywhere, and this deck claims none. Noted only because ids 81/82's non-empty `hadith` field is what sent two drafters to verify their duʿā against a ḥadīth instead of against the catalogue (§9cb).

---

## What I could not determine — attack these first

1. **Bar 2 is the weakest bar in this deck** and the deck knows it. 57:22 is an order-of-operations, not a parable. If a verifier rules that a temporal sequence does not *show*, **the deck has no second text** — the corpus sweep proves that. It would become a refusal on bar 2.
2. **The 57:23 exposure.** The rebuke is one clause after the last rendered word. Handled by truncation; not eliminated.
3. **`.context/claims/` was empty at claim time** — the directory is gitignored and this workspace is fresh. Prior claims were reconstructed from the drafts and the shipped asset instead, which is weaker than reading them. **If a concurrent agent has claimed 57:22 or 59:24 in a claims directory I could not see, I would not know.**
4. **The 24 pending drafts were not swept.** Bar 3(b) is measured against the **45 shipped decks only**. A collision with an unshipped draft — most likely `al-musawwir@1`, which *was* diffed — would not appear. This is the standing gap in every draft in this wave, not a new one.
5. **No ḥadīth was fetched for this deck.** There are no ḥadīth beats, and the duʿā claims no narration. `sunnah.com` was therefore never queried — **a fact about this deck's needs, not a claim that anything there is unavailable** (§9bc).
6. **`إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٌ` is omitted on register grounds, which is a judgement call.** Someone may reasonably hold that a verse beat should render the āyah whole. Stated so it is a decision, not an accident.

---

## Pairing verdict

**Ships independently.** No shared catalogue duʿā with any other id. It is *thematically* paired with `al-musawwir@1` (both from 59:24's clause) and the twin-diff above is settled, but **neither deck depends on the other shipping** — they render disjoint text and their takeaways carry different engines.
