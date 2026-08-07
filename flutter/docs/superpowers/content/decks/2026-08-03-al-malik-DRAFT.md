# Deck Draft — Al-Malik (catalogue id 4)

> ## REVISION 2 — after blind adversarial verification (2026-08-03)
>
> **Verdict returned: FIX-THEN-SIGN. Scripture authenticity 100% clean; no bar fails.** The pin
> `Qur'an 3:26 (opening)` is **APPROVED**. Four of five probes confirmed R1, including the Muslim 2787
> *"I am the Lord"* finding and the one-sukūn rasm claim on id 4's duʿā.
>
> **The fixes applied here, in order of severity:**
> 1. **BLOCKING — beat 6 contains beat 7 verbatim, 12 words byte-exact.** Now disclosed in its own
>    section with the trim alternative costed. **I diffed against 24 shipped decks and a sibling draft
>    and never diffed my own beats against each other** — batch 2's granularity error in a new place.
>    The deck-internal diff is now a standing check (table rows 17 and 15b).
> 2. **Bar 2's *"shown twice and stated nowhere"* withdrawn** — beat 5's *"I am the King"* **is** a bare
>    declaration, the ground §9j blocked 24:35 on. The bar still passes; the §9j tension is reconciled
>    on the record instead of ignored.
> 3. **"Beat 6 renders id 88's ENTIRE duʿā English" was FALSE** — the true figure is an **11-word** run,
>    after which the wording diverges and id 88's whole second sentence is absent. Also corrected: id 88
>    is **one** clause longer than id 4, not two, and differs from the āyah in **three** orthographic
>    words, not one.
> 4. **"59:23 is spent by shipped `as-salam@1`" was FALSE** — 59:23 reaches no beat of any deck. The real
>    grounds for rejecting it are far stronger and are now recorded.
> 5. Beats 4–5 **reverted to Bukhārī 4812's exact page text** — R1 silently lower-cased *"Right Hand"*
>    and changed a comma to a colon.
>
> **The lesson I am carrying forward, because both of my blocking failures were the same shape:** they
> were **overstatements of true findings** — *entire*, *almost verbatim* — not fabrications, and neither
> changed a verdict. But each stood in the ledger as a ruling a founder would sign, and each cost the
> verifier time it should have spent finding the next real thing. **A finding stated at its true
> strength is worth more than the same finding inflated.** Every corrected figure in this revision is
> recomputed and shown.

**Status: APPROVED 2026-08-03 — signed off by Claude under authority explicitly delegated by the founder** (*"You do not need my input for most of these, I want you to use your judgment based off of the approved decks we already have"*). Basis: drafted from fetched sources, put through an independent blind adversarial pass that was instructed to refute, and every blocking finding applied. **The reviewer was not the founder — that is recorded here rather than left to be inferred from a `reviewed_by: "founder"` field kept for schema consistency with the 14 decks shipped before this delegation.**

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md).
Author: Claude, 2026-08-03. Sibling draft in the same pass: [`2026-08-03-al-baqi-DRAFT.md`](./2026-08-03-al-baqi-DRAFT.md).

All scripture verified at draft time by **live fetch**: Qurʾān via `api.quran.com`
(`translations=20`, Saheeh International); ḥadīth via **Wayback captures of the exact bare
`sunnah.com` URL** (sunnah.com 403s automated fetching). Nothing here is composed, reconstructed or
recalled. **Every ✅ in the table below describes a request I actually issued in this session.**

**Selection method: duʿā-first.** Catalogue id 4's `dua_arabic` was read before any story hunting,
and it turned out to be **Qurʾān 3:26 itself** (minus `قُلِ`, truncated). The whole deck was then
built around the āyah the duʿā already belongs to.

---

## Deck `al-malik@1` — Al-Malik

**Why this deck exists, in one line:** the user in the muḥāsabah is carrying a loss that somebody
else decided for them. **3:26 puts the giving and the taking inside one sentence, and then names
what is in the hand that does both — and the word is *good*.**

**Proposed metadata**

```json
{
  "deck_id": "al-malik@1",
  "name_id": 4,
  "transliteration": "Al-Malik",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": "founder",
  "reviewed_at": "2026-08-03",
  "review_verdict": "good"
}
```

### The beats

**Beat 1 · bridge**
> Most of what shapes your week was decided by people who never asked you. This is the Name for who is actually in charge.

**Beat 2 · name_intro** *(catalogue id 4, verbatim — `english` only, no authored gloss)*
> الْمَلِكُ — Al-Malik — The King

**Beats 3–5 · story** *(label on all three: "Where are the kings")*
> 3. Abū Hurayra narrated a scene the Prophet ﷺ described. It is short, and it ends on a question.
> 4. **"Allah will hold the whole earth, and roll all the heavens up in His Right Hand…"**
> 5. **"…and then He will say, 'I am the King; where are the kings of the earth?'"** That is the whole narration. It ends on the question.

*(The quotation is split across two beats and carries a **visible ellipsis at the break in both
directions**, so neither beat claims to be a complete sentence. English is Ṣaḥīḥ al-Bukhārī 4812's
own published rendering, checked clause-by-clause against the page's Arabic — see §"translation
audit". Beat 5's closing two sentences are the deck's, and they assert only that the narration
stops there, which is verifiable on the page.)*

*(**R2, from the blind verification.** Revision 1 rendered `His **right** hand` and `He will say**:**`
where the page prints `His **Right** **Hand**` and `He will say**,**`. Both were **silent editorial
acts** — and the lower-casing was an editorial act on the **attribute term this deck says out loud
that it deliberately does not adjudicate**, which is worse than the punctuation change. **Both are now
reverted to the page's exact text**, so the beats contain zero editorial intervention and there is
nothing left to disclose.)*

**Beat 6 · verse**
> Say, "O Allah, Owner of Sovereignty, You give sovereignty to whom You will and You take sovereignty away from whom You will… In Your hand is [all] good…" — Qur'an 3:26

*(Two visible ellipses. The internal one drops `وَتُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ`; the
trailing one drops `إِنَّكَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ`. Both elisions are **bar-3 avoidance and are
disclosed on the beat itself**, not only in this table — see §"the five bars" row 3.)*

**Beat 7 · duʿā** *(catalogue id 4, verbatim in full — all three scripts)*
> اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ
> *Allahumma Malikal-Mulk tu'til-mulka man tasha'*
> "O Allah, Owner of Sovereignty, You give sovereignty to whom You will."
> **source (proposed): `Qur'an 3:26 (opening)`**

**Beat 8 · takeaway**
> The same sentence gives sovereignty away and takes it back. Then it says what is in the hand that does both — and the word is not "power". It is "good".

---

## ⚠️ Beat 6 contains beat 7 verbatim — 12 words, byte-exact. Disclosed, deliberate, and the founder's to overrule.

**This is the deck's most important disclosure and revision 1 did not make it.** It was found by the
blind verification, not by me, and the reason it was not found is worth recording: **I diffed my
beats against 24 shipped decks and against a sibling draft, and never diffed my own beats against
each other.** That is batch 2's granularity error — *beat-to-beat, not takeaway-to-takeaway* — in a
new place: **deck-internal**. The n-gram diff is now run deck-internally too, and is row 17 of the
verification table.

**The fact, computed:** beat 7's entire rendered English —
`O Allah, Owner of Sovereignty, You give sovereignty to whom You will` — **12 words — is a
byte-exact substring of beat 6.** The user reads the same sentence twice, two screens apart.

**I am keeping it, as the deck's stated premise.** This deck was selected duʿā-first *because* the
catalogue duʿā is 3:26; the repetition is the fact the deck is built on, and with the approved pin
`Qur'an 3:26 (opening)` rendering directly beneath it, beat 7 reads as *"the clause you just read is
your prayer"* rather than as an editing mistake. **But an undisclosed repetition and a disclosed
premise look identical on screen**, so it is named here and belongs in the founder's packet, not in a
footnote.

**The alternative, costed honestly.** Trim beat 6 to open after the shared clause:

> Say, "O Allah, Owner of Sovereignty… You take sovereignty away from whom You will… In Your hand is [all] good…"

This cuts the overlap from 12 words to **5** (`O Allah, Owner of Sovereignty` — unavoidable, it is the
vocative). **Two costs, both real:** (a) *"You give sovereignty to whom You will"* leaves the screen,
so **beat 8's "gives sovereignty away and takes it back" no longer has the giving on screen** and the
takeaway's arithmetic breaks; (b) the beat becomes a list of subtractions, which is precisely the
register bar 5 warns about. **Keeping `Say,` is not the reason** — `Say,` survives either version.

**Founder's call. One of the two must be chosen; it cannot remain undisclosed.**

---

## The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **Strongest available form.** The Name is not asserted by the deck and is not a trailing epithet — it is **Allah's own first-person declaration**: `أَنَا الْمَلِكُ` ("I am the King"), quoted verbatim in Ṣaḥīḥ al-Bukhārī 4812. 3:26 adds four **finite verbs of Allah's action** (`تُؤْتِى`, `وَتَنزِعُ`, `وَتُعِزُّ`, `وَتُذِلُّ`) — the same shape the ledger calls *"bar 1's strongest form"* for `al-afuw@1`'s `وَيَعْفُوا۟`. **Disclosure:** 3:26 is a *taught* prayer (`قُلِ`), i.e. words Allah composes for a human mouth — the deck keeps the word **"Say,"** on the beat rather than presenting the āyah as a bare divine declaration. The ḥadīth carries this bar on its own if the founder discounts taught speech. | **yes — beat 5 carries it in Allah's first person; beat 6 in Allah's finite verbs** |
| 2 | **the distinguishing quality is shown, not stated** | **R2 — the absolute claim is withdrawn.** Revision 1 said the quality was *"shown twice and stated nowhere"*. **That does not survive: beat 5 renders "I am the King", which is a bare declaration**, and ledger §9j blocked 24:35 partly on exactly that ground (`ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` **states** the attribute — the `al-haleem@1` rev-1 failure). The bar is still met, on the corrected reading below, and the §9j tension is reconciled rather than ignored. **The corrected statement:** the Name is **declared once** — and that declaration is doing **bar 1's** work, not bar 2's. Al-Malik's *distinguishing* quality is **that sovereignty is His to hand out and to withdraw** — not that He is powerful (Al-Qadir/Al-Muqtadir), not that He compels (Al-Qahhar/Al-Jabbar), not that He judges (Al-Hakam) — and **that** is stated nowhere and shown twice: the ḥadīth **asks after the other kings**, which enacts the withdrawal rather than describing it, and 3:26 **conjugates the giving and the taking**. **Why 24:35's ground does not transfer:** §9j's ground 1 is that the declaration was the *whole* demonstration there and the parable-only alternative left bar 1 unmet; here the declaration is inert for bar 2 and the demonstration sits elsewhere. §9j's ground 2 — *"there is no neutral rendering to produce"* — **does not apply at all**: `أَنَا الْمَلِكُ` is a Name, not a contested metaphysical predicate, its English is uncontested, and Bukhārī's own published rendering already prints *"the King"*. **A founder who disagrees should attack this row first.** | **yes, on the corrected reading — beats 5, 6** |
| 3 | **does not collapse into a sibling Name** | **Run in Arabic roots AND rendered English against all 24 decks in the ledger.** Result and the two elisions it forced are below in §"bar 3 in full". Headline: zero ≥5-word rendered-English overlap with any shipped or drafted beat except the bridge template; the noun *king* has **zero** occurrences in all 24 decks. | **yes** |
| 4 | **the Name's own root appears in the source text** | **Yes, three times, and one of them is on screen in English as the Name itself.** `أَنَا الْمَلِكُ` (`m-l-k`) — beat 5, rendered *"the King"*, the same word as the `name_intro`. `مُلُوكُ الأَرْضِ` — beat 5. `مَـٰلِكَ ٱلْمُلْكِ … ٱلْمُلْكَ … ٱلْمُلْكَ` — beat 6 and the duʿā. **No trade needed; bar 4 is not spent here.** | **yes — beats 2, 5, 6, 7 all render `m-l-k`** |
| 5 | **register / the arc must not terminate in punishment** | Ḥadīth: Bukhārī 4812 is **free-standing** — the narration is one sentence and ends on the question. No punishment inside it, and there is no continuation to be dishonest about (same posture as `al-haleem@1`'s Bukhārī 7378). Qurʾān: 3:27 is **creation and provision**, not punishment. Full successor sweep below, including the two things it found that I am disclosing rather than burying. | **yes — verified by fetch in both directions** |

### Bar 3 in full — the sweep, and the two elisions it forced

**Arabic-root axis.** Roots reaching a rendered field: `m-l-k` only (beats 2, 5, 6, 7). Roots in
quoted source text that stay off-screen: `q-b-ḍ` (`يَقْبِضُ`, Bukhārī 4812) — **also carried by
`al-qayyum@1` [D]**, and Al-Qabid (24) is undecked and `BLOCKED`; `ṭ-w-y` (`يَطْوِي`), unclaimed.
Absent from every beat of this deck, in both scripts: `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y`,
`j-b-r`, `w-k-l`, `q-d-r`, `ʿ-w-d`, `j-w-b`, `ṣ-m-d`, `b-q-y`.

**Rendered-English axis (the pass batch 2 earned).** Every candidate string was diffed
programmatically against **every `primary`, `label` and `source` field of all 24 decks** in
`assets/content/name_stories.json`, normalised (case, diacritics, punctuation), at n-gram widths
7→4.

| finding | verdict |
|---|---|
| The noun **"king"** returns **zero** hits across all 24 decks (only *thinking / asking / breaking / taking* matched a substring search). | clear |
| **"sovereignty"**, **"kings of the earth"**, **"roll all the heavens"**, **"the hand that does both"** — zero hits. | clear |
| **"This is the Name for…"** (beat 1) matches `al-kareem@1`, `al-mujeeb@1`, `ar-raheem@1` bridges. | **template, not collision** — ledger §4b classes bridge scaffolding as deliberate. Flagged, not changed. |
| **"hand"** appears in `al-wakeel@1` (*"hand your affairs to"*, *"the One who holds them"*), `as-salam@1` (*"outside your hands"*), `ar-razzaq@1` (*"the weight handed over"*). | **adjacency, disclosed.** All three are about **your** hands letting go; beats 6 and 8 are about **His** hand, and beat 6's is a quotation. `al-wakeel@1`'s engine is *handing over is not quitting*; this deck's is *the taking is in the hand called good*. Different engines, and the deck never uses "hand over", "hold" or "trust". A founder may still collapse them. |

**The two elisions bar 3 forced, both visible on the beat:**

1. `وَتُعِزُّ مَن تَشَآءُ وَتُذِلُّ مَن تَشَآءُ` — *"You honor whom You will and You humble whom You
   will."* Dropped. `ʿ-z-z` and `dh-l-l` are **Al-Muizz (43) and Al-Muzill (44)**, whose shared
   catalogue duʿā English is *"O Allah, honor me through obedience to You, and do not humiliate me
   through disobedience to You"* (fetched from the catalogue, both ids, byte-identical to each
   other). Quoting the clause would put both undecked Names' operative English on this deck's verse
   beat. **It also shortens the beat to one breath**, which the format wants anyway.
2. `إِنَّكَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ` — *"Indeed, You are over all things competent."* Dropped.
   `qadīr` is **Al-Qadir (75)**, a `[D]` deck; ledger §2d already records *"4:149 ('Competent')"* as
   rejected for exactly this. It is also a trailing epithet, which bar 1 says carries nothing.

Both elisions are marked with `…` **in the rendered beat string**, not only here.

### The successor sweep — every quotation, fetched

**Qurʾān 3:26** *(`api.quran.com`, `fields=text_uthmani,text_imlaei`, `translations=20`)*

| | text | verdict |
|---|---|---|
| **n−1 · 3:25** | *"So how will it be when We assemble them for a Day about which there is no doubt? And each soul will be compensated [in full for] what it earned, **and they will not be wronged**."* | **Does not contradict; it sets the scene.** It is the Day the ḥadīth describes. It closes on the *absence* of wrong, not on punishment. 3:26 does not open mid-sentence (`قُلِ` starts a new imperative), so n−1 is informational. |
| **n+1 · 3:27** | *"You cause the night to enter the day… and You bring the living out of the dead… **And You give provision to whom You will without account**."* | **Clean — no punishment; the passage runs *toward* provision.** Two off-screen sibling adjacencies disclosed: `وَتَرْزُقُ` is **Ar-Razzaq (13), SHIPPED**, and `تُخْرِجُ ٱلْحَىَّ مِنَ ٱلْمَيِّتِ` is **Al-Muhyi (69)/Al-Hayy (15)** territory. Neither reaches a screen, because 3:27 is not quoted. **Ar-Razzaq's `r-z-q` is one āyah from this deck's verse beat.** |
| **n+2 · 3:28** | *"Let not believers take disbelievers as allies… **And Allah warns you of Himself**, and to Allah is the [final] destination."* | **Two āyāt away, and it is a warning.** Not quoted, not alluded to, and the beat's own sentence closes on `بِيَدِكَ ٱلْخَيْرُ` — so nothing in the excerpt points at it. Disclosed because the sweep is not merit-based (plan §7). |

**Does the excerpt stop short of the passage's own ending in a way that changes its meaning?**
No. It stops before a **trailing epithet** (`قَدِيرٌ`), which the plan's bar 1 says carries no
demonstration, and the ellipsis is visible. The one clause elided *internally* (honour/humble) is a
**parallel** to the clause kept (give/take), so removing it weakens the deck's own case rather than
flattering it — the reader sees two acts where the āyah has four.

**Sahih al-Bukhari 4812** — the ḥadīth is one narrated sentence. Neighbours fetched anyway:

| | text | verdict |
|---|---|---|
| **n−1 · Bukhārī 4811** | A rabbi tells the Prophet ﷺ that Allah *"will put all the heavens on one finger, and the earths on one finger… Then He will say, 'I am the King.'"* The Prophet ﷺ smiles in confirmation and recites 39:67. | **DELIBERATELY UNUSED, and disclosed so that nobody "enriches" the story from it** — the same move `al-qayyum@1` made with Muslim 680b's Shayṭān clause. It is ṣaḥīḥ, but it is an attribute narration whose English rendering is a theological surface this deck has no business adjudicating (plan §6, rule 2). **If a reviewer or a transcriber reaches for the "finger" detail, that is a regression, not an improvement.** |
| **n+1 · Bukhārī 4813** | The Prophet ﷺ will be first to raise his head after the second blowing of the trumpet and will see Mūsā at the Throne. | Different subject, no punishment. Clean. |

### Parallels fetched and rejected — do not re-propose

| parallel | what the fetch showed | why rejected |
|---|---|---|
| **Sahih Muslim 2787** | Arabic **identical in substance** to Bukhārī 4812 (`أَنَا الْمَلِكُ أَيْنَ مُلُوكُ الأَرْضِ`; Muslim has `السَّمَاءَ` singular and adds `يَوْمَ الْقِيَامَةِ`). But its **published English renders `أَنَا الْمَلِكُ` as *"I am the Lord"* and `مُلُوكُ الأَرْضِ` as *"the sovereigns of the world"*.** | **Using Muslim's English would delete the Name from the deck.** This is the `al-kareem@1` failure exactly — a published translation quietly adjudicating the point the deck exists to make. Bukhārī 4812's English says *"I am the King; where are the kings of the earth?"*, which matches the Arabic. **Route chosen on the English, not on the collection.** |
| **Sahih Muslim 2788a** | *"…I am the Lord; where are the haughty and where are the proud?"* — Arabic `أَيْنَ الْجَبَّارُونَ أَيْنَ الْمُتَكَبِّرُونَ`. | **Bar 3 fail and register fail.** `j-b-r` is **shipped `al-jabbar@1`**; `k-b-r` is Al-Mutakabbir (19). And the rendered English is a rebuke, not the open question the deck needs. |
| **Qurʾān 40:16** (`لِمَنِ الْمُلْكُ الْيَوْمَ`) | not selected | `الْقَهَّارِ` in the same clause (Al-Qahhar, 22) and 40:17–18 run into recompense and `مَا لِلظَّالِمِينَ مِنْ حَمِيمٍ`. **Bar 5 + bar 3.** |
| **Qurʾān 20:114, 23:116, 62:1, 114:2** | not selected | all carry `الْمَلِك` as a **trailing/appositive epithet** — bar 1's named failure mode. |
| **Qurʾān 59:23** — **R2, my stated reason was FALSE and the real reasons are stronger** | fetched | R1 said 59:23 is *"spent by shipped `as-salam@1`"*. **It is not spent by any deck.** Read off the asset in this session: `as-salam@1`'s **beat** sources are only `Qur'an 13:28` and `Sahih Muslim 591`; 59:23 appears **only in its `sources` table**, as the provenance of the *"Source of Serenity"* gloss, and reaches **no screen**. (COLLISION-LEDGER §2a lists it as a claimed passage, which is what I over-read.) **The correct grounds, all verified from the fetched āyah, are much stronger:** `ٱلْمَلِكُ` is one of **nine appositive epithets** in a single list — bar 1's named failure mode at its purest — and the list also carries `ٱلسَّلَـٰمُ` (**shipped `as-salam@1`**), `ٱلْجَبَّارُ` (**shipped `al-jabbar@1`**, and Saheeh International renders it *"the Compeller"*, which is `al-jabbar@1`'s `name_intro` **verbatim**), `ٱلْمُتَكَبِّرُ` (19), `ٱلْمُؤْمِنُ` (7 — **being drafted concurrently this wave**), `ٱلْعَزِيزُ` (8), `ٱلْقُدُّوسُ` (5) and `ٱلْمُهَيْمِنُ` (18). **Seven other Names on one verse beat.** Rejected. |
| **Qurʾān 2:246–247** (Ṭālūt) | not selected | `وَٱللَّهُ يُؤْتِى مُلْكَهُۥ مَن يَشَآءُ` is arguably inside the prophet's quoted speech (ledger §2d rejects 7:196 / 12:101 / 10:62 as human speech about Allah), and the passage runs into **Ṭālūt vs Jālūt — a battle**. Bar 5 register. **Left free for a future drafter who can carry it.** |
| **Qurʾān 67:1** (`بِيَدِهِ ٱلْمُلْكُ`) | not selected | noun, not a finite act; closes on `قَدِيرٌ`; 67:2 closes on `ٱلْعَزِيزُ ٱلْغَفُورُ` (**shipped `al-ghafur@1`**); and 67:13 is already **spent by shipped `al-lateef@1`**. |

---

## The duʿā, and the pin I am proposing

Catalogue id 4's `dua_arabic` is
`اللَّهُمَّ مَالِكَ الْمُلْكِ تُؤْتِي الْمُلْكَ مَنْ تَشَاءُ`.

**Computed, not eyeballed** (script run in this session over `collectible_names.json` and the
fetched āyah): with all combining marks, `ـ`, and orthographic alif/yāʾ/tāʾ variants folded, the
catalogue string is **rasm-identical** to Qurʾān 3:26's `text_imlaei` minus the opening `قُلِ`,
truncated after `مَن تَشَاءُ`. It is **not byte-identical**: exactly one word differs —
catalogue `مَنْ` (U+0645 U+064E U+0646 **U+0652**) vs āyah `مَن` (no sukūn). Immaterial religiously;
recorded because `al-ghafur@1`'s pilot marked a comparable check ✅ when it had not passed.

So the duʿā **is** the āyah's own words, and the deck should be **pinned**. Two facts the founder is
signing:

1. **It is a truncation.** The catalogue stops after the first of four parallel clauses, mid-list.
   The duʿā beat's Arabic, transliteration and translation are **catalogue-locked by the ship gate**
   — I cannot put an ellipsis in them. The only rendered field I control on that beat is `source`.
   **I therefore propose the pin string `Qur'an 3:26 (opening)`** so the partiality is visible on
   the beat, per the batch-2 rule that a disclosure in a table is not a disclosure. Plain
   `Qur'an 3:26` is the alternative and is the founder's call; `cf. Qur'an 3:26` is a third option
   with `ash-shafi@1` as precedent.
2. **`قُلِ` is dropped.** The catalogue presents as a prayer what the āyah presents as a *commanded*
   prayer. That is the normal thing to do with a `قُلِ` āyah and I am not flagging it as a defect —
   only recording it, because the verse beat **keeps** the word "Say," and a reviewer will notice the
   two beats differ there.

**Transcription requirement:** add `'al-malik@1': "Qur'an 3:26 (opening)"` to `renderedDuaSources`
in `test/content/name_stories_ship_gate_test.dart` **in the same change** as the deck. The gate
asserts bidirectionally; an unpinned deck that renders a source fails, and a pinned deck that drops
it fails.

---

## Catalogue corroboration — the `hadith` field, checked against my own fetch

> id 4 `hadith`: *"The Prophet ﷺ said: \"Allah will fold the heavens on the Day of Resurrection,
> then He will say: I am the King, where are the kings of the earth?\" (Bukhari)"*

**Verdict: the card is correct and corroborates this deck. No change recommended.** The attribution
(Bukhārī) is right, the quoted saying matches `أَنَا الْمَلِكُ، أَيْنَ مُلُوكُ الأَرْضِ` verbatim in
sense and in the *"King"* rendering, and *"fold the heavens"* is a fair compression of
`وَيَطْوِي السَّمَوَاتِ`. Two immaterial compressions: the card omits `يَقْبِضُ اللَّهُ الأَرْضَ`
("Allah will hold the earth") and adds `يَوْمَ الْقِيَامَةِ` ("on the Day of Resurrection"), which is
in **Muslim 2787's** wording but not in Bukhārī 4812's.

**I am recommending no catalogue change on either of my Names.** Plan §7 records that a drafter's
confident recommendation to change catalogue data is the highest-risk artifact this pipeline
produces and has been wrong in both batches, in the same direction. There is nothing here that
needs one.

---

## Translation audit — clause by clause, from the page's Arabic

Plan §6 rule 2: re-render contested passages from the Arabic; do not paste a published translation
unchecked. Bukhārī 4812's published English is used **because** it survived this check.

| Arabic on the page | Bukhārī 4812's published English | audit |
|---|---|---|
| `يَقْبِضُ اللَّهُ الأَرْضَ` | "Allah will hold the whole earth" | *"the whole"* is an interpolation of `الأَرْضَ`'s definiteness. Acceptable; kept. |
| `وَيَطْوِي السَّمَوَاتِ بِيَمِينِهِ` | "and roll all the heavens up in His Right Hand" | `السَّمَوَاتِ` is plural — *"the heavens"* correct (Muslim's Arabic has singular `السَّمَاءَ` and its English says "the sky"). **`بِيَمِينِهِ` is rendered literally and left entirely alone.** **R2:** revision 1 lower-cased *"Right Hand"* to *"right hand"* and called that "changing no word" — **it is an editorial act on an attribute term, on the one surface this deck says out loud that it does not adjudicate.** Reverted; the beat now prints the page's capitalisation exactly. **The deck adds no gloss, no interpretation and no capitalisation of its own.** The one-line alternative, if the founder prefers, is to cut the clause from beat 4 with a visible ellipsis. |
| `ثُمَّ يَقُولُ أَنَا الْمَلِكُ` | "and then He will say, 'I am the King'" | **The load-bearing clause. Correct.** Muslim's published English says *"I am the Lord"* — see the parallels table. **R2:** revision 1 printed `He will say**:**` where the page prints `He will say**,**`. Undisclosed punctuation change; reverted. |
| `أَيْنَ مُلُوكُ الأَرْضِ` | "where are the kings of the earth?" | correct. |

Qurʾān: Saheeh International (`translations=20`) throughout, including the bracketed `[all]`, which
matches the bracket convention already shipped in `al-qadir@1`.

---

## Claim | Source | Grading | Status

**Every ✅ is a request I issued in this session and read the response of.** Where I did not fetch
something, the row says so.

| # | claim | source | URL fetched | grading | status |
|---|---|---|---|---|---|
| 1 | *"Allah will hold the whole earth, and roll all the heavens up in His Right Hand, and then He will say, 'I am the King; where are the kings of the earth?'"* (beats 4–5, verbatim) | Ṣaḥīḥ al-Bukhārī 4812, narrated Abū Hurayra | `web.archive.org/web/20260217212758id_/https://sunnah.com/bukhari:4812` | **ṣaḥīḥ** (Ṣaḥīḥ al-Bukhārī; no separate grade line — Bukhārī's own collection) | ✅ **verified (archive)** — Arabic and English both read off the capture; in-book ref Book 65, Ḥadīth 334. *(Corrected 2026-08-03 at transcription: this cell still quoted R1's lower-cased "right hand" and "say:", the exact pair R2 reverted — so the row's ✅ attested that the capture printed something the translation-audit table said it did not, on the attribute term this deck states it does not adjudicate. **I re-fetched the capture rather than count which side of the file had more votes.** The page reads `in His Right Hand, and then He will say,` — the beats were right and this cell was stale.)* |
| 2 | The narration ends on the question (beat 5's closing line) | same page | same | — | ✅ **verified** — the capture's `text_details` block terminates at `أَيْنَ مُلُوكُ الأَرْضِ` |
| 3 | *"Say, 'O Allah, Owner of Sovereignty, You give sovereignty to whom You will and You take sovereignty away from whom You will… In Your hand is [all] good…'"* (beat 6) | Qurʾān 3:26 | `api.quran.com/api/v4/verses/by_key/3:26?fields=text_uthmani,text_imlaei&translations=20` | — | ✅ **verified** — Saheeh International, quoted verbatim; both elisions marked with `…` on the beat |
| 4 | 3:26's n−1 (3:25) does not contradict and closes on *"they will not be wronged"* | Qurʾān 3:25 | `…/verses/by_key/3:25?…` | — | ✅ **fetched and read** |
| 5 | 3:26's n+1 (3:27) contains no punishment and closes on provision | Qurʾān 3:27 | `…/verses/by_key/3:27?…` | — | ✅ **fetched and read**; `وَتَرْزُقُ` (Ar-Razzaq, shipped) disclosed as off-screen |
| 6 | 3:28 is a warning two āyāt out | Qurʾān 3:28 | `…/verses/by_key/3:28?…` | — | ✅ **fetched and read**; disclosed, not blocking |
| 7 | Bukhārī 4811 (n−1) is the "one finger" narration and is deliberately unused | Ṣaḥīḥ al-Bukhārī 4811 | `web.archive.org/web/20230327012352id_/https://sunnah.com/bukhari:4811` | ṣaḥīḥ | ✅ **verified (archive)** |
| 8 | Bukhārī 4813 (n+1) is a different subject with no punishment | Ṣaḥīḥ al-Bukhārī 4813 | `web.archive.org/web/20220527194302id_/https://sunnah.com/bukhari:4813` | ṣaḥīḥ | ✅ **verified (archive)** |
| 9 | Muslim 2787 has the same Arabic but renders `أَنَا الْمَلِكُ` as *"I am the Lord"* | Ṣaḥīḥ Muslim 2787 | `web.archive.org/web/20250905190736id_/https://sunnah.com/muslim:2787` | ṣaḥīḥ | ✅ **verified (archive)** — quoted nowhere in the deck |
| 10 | Muslim 2788a says `أَيْنَ الْجَبَّارُونَ أَيْنَ الْمُتَكَبِّرُونَ` and is bar-3 contaminated | Ṣaḥīḥ Muslim 2788a | `web.archive.org/web/20230607232830id_/https://sunnah.com/muslim:2788a` | ṣaḥīḥ | ✅ **verified (archive)** — rejected with reason |
| 11 | Catalogue id 4's `dua_arabic` is rasm-identical to 3:26 (`text_imlaei`) minus `قُلِ`, truncated, differing in exactly one sukūn | `assets/content/collectible_names.json` id 4 + Qurʾān 3:26 | local read + the 3:26 fetch above | — | ✅ **computed in this session** (normalisation script; the surviving diff is `مَنْ` vs `مَن`) |
| 12 | id 4's card `hadith` is a correct rendering of Bukhārī 4812 | `collectible_names.json` id 4 | local read, compared to row 1 | — | ✅ **verified — no catalogue change recommended** |
| 13 | Al-Muizz (43) and Al-Muzill (44) share the duʿā English *"honor me… do not humiliate me"* | `collectible_names.json` ids 43, 44 | local read | — | ✅ **verified** — the reason for the internal elision |
| 14 | Zero ≥5-word rendered-English overlap with any of the 24 decks, except the bridge template | `assets/content/name_stories.json` (24 decks) | local, n-gram diff 7→4 over `primary`/`label`/`source` | — | ✅ **run in this session**; output in §"bar 3 in full" |
| 15 | Al-Malik's beats contain no form of *last / remain / endure / perish*, and Al-Baqi's contain no *king / sovereignty / hand* | both drafts | local regex over both beat sets | — | ✅ **run in this session** — the firewall between the two Names |
| 16 | The `label` field renders **only** on story beats; `source` renders on `verse` and `dua` beats | `lib/widgets/beat_reveal/beat_reveal_models.dart:234`, `beat_screen_view.dart` | local read | — | ✅ **verified** — this is why the duʿā's partiality disclosure has to live in `source` |
| **17** | **DECK-INTERNAL diff: beat 7's full English is a byte-exact 12-word substring of beat 6** | this deck's own beats | local, `SequenceMatcher` + substring test | — | ✅ **run in R2 — THE CHECK REVISION 1 NEVER RAN.** Found by the blind verification first. See the dedicated section above. |
| **18** | Beat 6 ↔ id 88's `dua_translation`: longest run **11 words**, then divergent; id 88's second sentence absent | `collectible_names.json` id 88 | local, `SequenceMatcher` | — | ✅ **recomputed in R2** — R1's *"entire"* was **false**; corrected in §authoring notes |
| **19** | id 88's `dua_arabic` is **one clause (4 words)** longer than id 4's and differs from 3:26 `text_imlaei` in **three** orthographic words | `collectible_names.json` ids 4, 88 | local, normalisation script | — | ✅ **recomputed in R2** — R1 said "two clauses" and "one" difference; **the one-word figure is correct for id 4 only** (row 11), and the verifier independently confirmed row 11 |
| **20** | 59:23 appears on **no beat** of `as-salam@1` and is spent by no deck; it lists **nine** appositive Names incl. four already decked or in-wave | `name_stories.json`, Qurʾān 59:23 | local read + `…/verses/by_key/59:23?…` | — | ✅ **fetched and read in R2** — R1's *"spent by shipped `as-salam@1`"* was **false**; the real grounds are stronger and are now recorded |
| **21** | Beats 4–5 now reproduce Bukhārī 4812's page text with **zero** editorial change (capitalisation and punctuation restored) | the 4812 capture | re-read against the capture | — | ✅ **verified in R2** |
| — | isnād of any narration above | — | — | — | ❌ **NOT audited.** See §limits. |

---

## Authoring notes

**How this deck is kept apart from `al-baqi@1`, drafted in the same pass.** The two Names are
thematically adjacent — a king who remains — so the separation was made explicit and then verified
mechanically rather than asserted:

| | `al-malik@1` | `al-baqi@1` |
|---|---|---|
| what the insight is *about* | **whose hand** — the attribution of a loss you did not choose | **which column** — the inventory of what you did choose to let go |
| beat 8's mechanism | one sentence contains both the giving and the taking, and names the hand *good* | the count inverts: the part that left is the part that stayed |
| emotional address | consolation about **what was done to you** | reframing of **what you did** |
| vocabulary firewall (verified by regex) | never uses *last, remain, endure, perish* | never uses *king, sovereignty, hand* |
| scripture | 3:26 + Bukhārī 4812 | 16:96 + Tirmidhī 2470 |

Neither engine appears in ledger §3a's spent list, and they do not appear in each other's.

**Sūrah volume — and a live cross-draft finding.** Against the shipped 24, Sūrat Āl ʿImrān carries
one deck: `al-wakeel@1` [S] at 3:172–174, **146 āyāt** from this one. Both are additionally **pinned
duʿā sources** (`Qur'an 3:173` and the proposed `Qur'an 3:26 (opening)`) — a new shape for the
ledger: two decks whose duʿā citations name the same sūrah. The two texts share nothing.

**But the claims written by concurrent sibling agents during this same wave change the picture, and
this is the kind of thing that is only visible now:** `.context/claims/14.md` (Al-Aleem) claims
**3:35–37**, and `.context/claims/10.md` (Al-Khaliq) claims **3:190–191**. If all three drafts ship,
**Sūrat Āl ʿImrān will carry four decks — 3:26, 3:35–37, 3:172–174, 3:190–191** — which is the
crowding shape the ledger explicitly *retired* for Sūrat ash-Shūrā (§2c). No two of the four share an
āyah, a protagonist or a rendered string, and 3:26 is nine āyāt from the nearest. **This is a founder
call about concentration, not a bar failure**, and it is raised here rather than at review. If one
must move, **this deck is the one that cannot** — 3:26 is not a chosen verse, it is the āyah the
catalogue's duʿā already is.

**What this deck spends for Malik-ul-Mulk (88) — CORRECTED IN R2, my claim was overstated.**

Revision 1 said beat 6 renders *"id 88's **entire** duʿā English"*. **That is false, and it stood in
the ledger as a ruling until the blind verification caught it.** Recomputed here:

| | true value | R1 said |
|---|---|---|
| longest contiguous shared run, beat 6 ↔ id 88's `dua_translation` | **11 words** — *"Owner of Sovereignty, You give sovereignty to whom You will and"* — then the wording **diverges** (id 88: *"take it from whom You will"*; beat 6: *"You take sovereignty away from whom You will"*) | "entire" |
| id 88's second sentence — *"Teach me that nothing I hold is truly mine."* | **absent from beat 6 entirely** | not mentioned |
| id 88's `dua_arabic` vs id 4's | **one clause / four words longer** (`وَتَنْزِعُ الْمُلْكَ مِمَّنْ تَشَاءُ`) | "two clauses" |
| id 88's orthographic diffs vs 3:26 `text_imlaei` | **three** (`مَنْ`/`مَن`, `وَتَنْزِعُ`/`وَتَنزِعُ`, `مِمَّنْ`/`مِمَّن`) | "one" (that figure is correct for **id 4**, which has exactly one, and the verifier confirmed it) |

**The collision is real and serious at its true strength: an 11-word run of a `BLOCKED` Name's duʿā
English, rendered on this deck's verse beat.** Ledger §6c already marks 88 `BLOCKED`, so this deck
does not *create* the block — it deepens it. Record it in §2c at that strength and no higher.

**One thing I did not do that a reviewer might expect.** I did not build the deck around the
Trench/Ḥudaybiyyah revelation context sometimes attached to 3:26. It is a *battle* setting (plan §7
bar 5, and the task's register instruction), and the chain of attribution runs through tafsīr rather
than through a graded narration I could fetch. **Not used, not cited, not alluded to.**

---

## Limits of this verification — stated because the founder signs against it

1. **No corpus independent of sunnah.com.** Every ḥadīth here was read from a **Wayback capture of a
   sunnah.com page**. No printed edition, no Shamela, no Dorar, no Arabic-primary database. This is
   the same limit the pilot recorded and **no pass in this project has yet escaped it.**
2. **No isnād was audited.** Bukhārī's and Muslim's own placement of these narrations is accepted as
   the grade. For the parallels I rejected, I rejected on wording and register, not on chain.
3. **The Qurʾān side is single-source too** — `api.quran.com` for both Arabic and translation. I did
   not cross-check against a second muṣḥaf or a second translation API. Abdel Haleem was **not**
   fetched for 3:26 (`al-qadir@1` records that it renders the Divine Name as "God", which this deck
   would not adopt anyway).
4. **The Muslim-2787 English finding is about one published translation on one page**, not a claim
   about every edition of Ṣaḥīḥ Muslim.
5. **I did not run `flutter test`.** This is a draft; nothing was written to
   `assets/content/name_stories.json`, `collectible_names.json` or the ship-gate test, per the
   task's read-only constraint.
