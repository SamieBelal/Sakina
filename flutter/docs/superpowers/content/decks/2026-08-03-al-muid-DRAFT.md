# Deck Draft — Al-Muid (hardship pack, Wave G batch 2, 5 of 5)

**Status: DRAFT — awaiting founder review.** Not approved. Do not transcribe into `assets/content/name_stories.json` until `review_verdict: "good"` is recorded here.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Pipeline: plan-of-record Wave G, §G2b. Author: Claude, 2026-08-03. Batch theme: **hardship — the situation that has not lifted.**

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com`; ḥadīth via Wayback archive of the exact `sunnah.com` URL. Story beats paraphrase only what the cited source carries, and every paraphrase is labelled.

**Translation standard:** Saheeh International (`20`) for Qur'ān, Abdel Haleem (`85`) fetched and compared per row and adopted nowhere. Khattab (`131`) remains unfetchable.

**Implementation note (binding):** Arabic / transliteration / translation are **separate fields** on every beat.

---

## Deck `al-muid@1` — Al-Muid

**Why this deck exists, in one line:** it is the only story in the sources where **a person says the duʿā while on the record as not believing it**, and the narration keeps the objection and the sentence in that order. That is the deck's whole payload and it lands on plan §STEP-3 criterion 2 — it reframes the reader's own situation without moralising at them.

**Proposed metadata**

```json
{
  "deck_id": "al-muid@1",
  "name_id": 68,
  "transliteration": "Al-Muid",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> There is one sentence for the moment something is taken. It asks for a replacement, and almost nobody can say it and mean it.

**Beat 2 · name_intro** *(from `collectible_names.json` id 68, verbatim)*:
> الْمُعِيدُ — Al-Muid — The Restorer

**Beats 3–5 · story — "Umm Salama":**
> 1. He taught one sentence for the moment something is taken: **"O Allah, reward me for my affliction and give me something better than it in exchange for it."**
> 2. When Abu Salama died she thought: **"What Muslim is better than Abu Salama whose family was the first to emigrate to the Messenger of Allah…"**
> 3. Then she said the words anyway — and in her own account, Allah gave her the Messenger of Allah ﷺ in exchange.

**Beat 6 · verse** *(excerpt, marked — the Name's own root is the operative verb)*:
> "And it is He who begins creation; then He repeats it, and that is [even] easier for Him." — Qur'ān 30:27

**Beat 7 · duʿā** *(catalog id 68, verbatim in full)*:
> يَا مُعِيدُ أَعِدْ إِلَيَّ مَا أَخَذْتَهُ مِنِّي أَوْ أَبْدِلْنِي خَيْرًا مِنْهُ
> *Ya Mu'id, a'id ilayya ma akhadhtahu minni aw abdilni khayran minh*
> "O Restorer, return to me what was taken or replace it with something better."

**Beat 8 · takeaway:**
> She said it after saying it could not be true. The narration keeps both, in that order — the objection first, and then the sentence anyway.

---

### The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | 30:27 — `وَهُوَ ٱلَّذِى يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ`, Allah as subject, the Name's own verb, in the Qur'ān's own words. On the ḥadīth side the acting verb is also Allah's: `إِلاَّ أَخْلَفَ اللَّهُ لَهُ خَيْرًا مِنْهَا` — *"Allah will give him something better than it in exchange."* **Neither is the deck asserting the attribute; both are the sources stating it.** | **yes — beats 3, 5 and 6** |
| 2 | **the distinguishing quality is shown, not stated** | ⚠️ **This is the deck's honest weakness and it has its own section below.** What 30:27 demonstrates is *re-creation* — Allah begins creation and repeats it. What the story demonstrates is *replacement after loss*. Both are "bringing back", and the app's own catalogue already joins them (id 68's `hadith` field cites 30:27 for exactly this reading), **but the two are not the same act and the deck says so rather than letting the founder discover it.** | **partly — see §"The honest weakness"** |
| 3 | **does not collapse into a sibling Name** | No form of `r-ḥ-m`, `gh-f-r`, `ʿ-f-w`, `ḥ-l-m`, `sh-f-y` or `j-b-r` appears on any beat. **The one Name this could collapse into is `al-jabbar@1` (shipped, "Restorer of the Broken") and it does not — see the collision table, where the distinction is argued rather than asserted.** **One disclosure:** 30:27's un-quoted tail ends `وَهُوَ ٱلْعَزِيزُ ٱلْحَكِيمُ` — Al-Azeez (8) and Al-Hakeem (26), **neither shipped nor in this batch**. | **yes, with one argued distinction** |
| 4 | **the Name's own root appears in the source text** | **Yes in the Qur'ān, no in the ḥadīth, and the deck states both.** 30:27 carries `يُعِيدُهُۥ` (`ʿ-w-d`), which is the Name. **Ṣaḥīḥ Muslim 918a does not** — its verb is `أَخْلَفَ` (`kh-l-f`, to give in exchange). So the story teaches the *sense* of the Name and the verse carries the *word*. Saheeh International renders `يُعِيدُهُۥ` as *"repeats it"*, not *"restores"*, so the catalogue's English *"The Restorer"* is **not** the word printed on beat 6. **Partial criterion-(2) hit, disclosed.** | **yes — beat 6, in a different English word** |
| 5 | **the arc must not terminate in punishment just outside the excerpt** | 30:28 is a parable about partners; 30:26 is *"All are to Him devoutly obedient."* On the ḥadīth side the narration continues into the marriage proposal and a domestic exchange — **not punishment, but it does continue, and the deck stops before it.** Full table below. | **yes — verified** |

### ⚠️ The honest weakness the founder must weigh: the āyah and the story are doing two different jobs

Ṣaḥīḥ Muslim 918a is about **a life being replaced after a loss**. Qur'ān 30:27 is about **creation being re-originated**. They are joined by a single idea — *bringing back is not harder than making in the first place* — and that join is real, but it is an inference, not a quotation.

**Three things bear on it:**

1. **The app's own catalogue already makes exactly this join, and cites exactly this āyah.** Catalog id 68's `hadith` field reads: *"Allah says: 'He begins creation, then He will repeat it — and that is easier for Him.' Al-Muid restores what was taken, and can replace it with better. (Quran 30:27)"*. **A user who meets this deck and then the Name card meets the same āyah twice, with the same reading, and has no contradiction to resolve.** Only `al-haleem@1` in batch 1 could say that; the other four batch-1 decks had to flag a contradiction with their own card. **That is the single strongest argument for signing this deck**, and it is an argument from the app's existing content rather than from my judgement.
2. **The bridge from `يُعِيدُهُۥ` to "what you lost can come back" is the classical reading of the Name**, not an invention — but this deck does not cite a scholar for it, because the tiering rule in §G2 makes Yaqeen-class writing a framing authority only, and framing is precisely what is at issue here. **So the deck asserts the join in no beat.** Beat 6 quotes the āyah and stops; beat 8 talks only about the narration.
3. **If the founder's bar is that the verse beat must demonstrate the same act the story demonstrates**, this deck fails and should be cut. That is a clean outcome. **Al-Muhyi (catalog id 69) is the ready replacement** — its root is in 30:50 and 75:40, its catalogue duʿā (*"revive the hopes that this world has killed"*) is the most ICP-resonant string in the whole catalogue, and this batch deliberately left both āyāt free for it (see `al-qadir@1`'s authoring notes).

### What comes immediately after (and before) each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **Ṣaḥīḥ Muslim 918a** (continuation) | The narration runs on past beat 5: *"The Messenger of Allah ﷺ sent Hatib b. Abu Balta'a to deliver me the message of marriage with him. I said to him: I have a daughter (as my dependant) and I am of jealous temperament. He said: So far as her daughter is concerned, we would supplicate Allah, that He may free her (of her responsibility) and I would also supplicate Allah to do away with (her) jealous (temperament)."* | **clean — no punishment, no reversal, nothing that changes the meaning of the quoted part.** It is domestic detail that cannot fit three beats. **Disclosed rather than left for the founder to find**, because §G2b's rule is about what sits just outside the excerpt, and a ḥadīth's continuation counts. |
| **30:27** (n−1) | 30:26 *"And to Him belongs whoever is in the heavens and earth. All are to Him devoutly obedient."* | **clean.** |
| **30:27** (n+1) | 30:28 *"He presents to you an example from yourselves. Do you have among those whom your right hands possess [i.e., slaves] any partners in what We have provided for you…? Thus do We detail the verses for a people who use reason."* | **clean** — a parable about partnership, no warning, no punishment. |
| **30:27** (the excerpt's own tail) | The quotation stops after *"…easier for Him."* The remaining clauses are *"To Him belongs the highest description [i.e., attribute] in the heavens and earth. And He is the Exalted in Might, the Wise."* | **clean — nothing withheld is a warning.** The cut is for one breath. **Disclosed:** the omitted tail names Al-Azeez and Al-Hakeem, neither of which is shipped or in this batch. |
| **30:27**, looking further out | 30:50 — twenty-three āyāt later — is `إِنَّ ذَٰلِكَ لَمُحْىِ ٱلْمَوْتَىٰ ۖ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ`, carrying **Al-Muhyi** and **Al-Qadir** (a batch-2 sibling). | **disclosed, off-screen.** Neither Name reaches a beat here; recorded because §G2b asks for sibling-root adjacency to be scanned, and because 30:50 is the āyah `al-qadir@1` deliberately left free. |

### Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 5.1 | Beat 3 quotation, verbatim: "O Allah, reward me for my affliction and give me something better than it in exchange for it." | sunnah.com's published English (Siddiqui for the Muslim corpus), quoted as printed. **NOT re-rendered** — it resolves no contested reading, and readability alone is not a licence under the batch rule inherited from `al-haleem@1`. | [Sahih Muslim 918a](https://sunnah.com/muslim:918) | **ṣaḥīḥ** — Ṣaḥīḥ Muslim (the collection's own condition; sunnah.com prints no separate grade line for the two Ṣaḥīḥs, re-confirmed on this page) | ✅ **verified** via Wayback capture `20260311125945` of the exact URL, fetched 2026-08-03. Reference line: *"Sahih Muslim 918a"*, in-book Book 11 Hadith 4, chapter *"What should be said at times of calamity?"*. Narrator: **Umm Salama**. Isnād on the page: Yaḥyā b. Ayyūb / Qutayba / Ibn Ḥujr ← Ismāʿīl b. Jaʿfar ← Saʿd b. Saʿīd ← ʿUmar b. Kathīr b. Aflaḥ ← Ibn Safīna ← Umm Salama. **Substring test run programmatically: byte-exact substring** of the archived page English after whitespace normalisation. Page Arabic: `اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا`. **One disclosure:** the beat's framing *"He taught one sentence for the moment something is taken"* is the deck's, replacing the conditional clause *"If any Muslim who suffers some calamity says, what Allah has commanded him"*; the quoted sentence itself is untouched. |
| 5.2 | Beat 4 quotation, verbatim excerpt: "What Muslim is better than Abu Salama whose family was the first to emigrate to the Messenger of Allah…" | sunnah.com's published English, quoted as printed, **cut before the honorific parenthesis** | [Sahih Muslim 918a](https://sunnah.com/muslim:918) | ṣaḥīḥ | ✅ **verified — byte-exact substring** of the archived page English after whitespace normalisation. **Two disclosures:** (a) the quotation is **cut with a marked ellipsis** immediately before the published text's *"(ﷺ)."* — done so the beat does not have to reproduce or reposition a parenthesised honorific, and nothing after the cut is withheld except that honorific and a full stop; (b) the beat renders *"she thought:"* where the page reads *"she said:"* — **that is a change and it is named here.** The Arabic is `قُلْتُ أَىُّ الْمُسْلِمِينَ خَيْرٌ مِنْ أَبِي سَلَمَةَ` (*"I said…"*), i.e. interior speech reported in the first person. **If the founder wants zero drift, the beat should read "she said:" and the deck will read very slightly less clearly. One word either way.** |
| 5.3 | Beat 5: she then said the words, and Allah gave her the Messenger of Allah ﷺ in exchange | **paraphrase, deliberately.** The published English reads *"I then said the words, and Allah gave me God's Messenger (ﷺ) in exchange."* — **it renders the same title as "God's Messenger" here and "Allah's Messenger" elsewhere on the same page.** Quoting it verbatim would put **"God"** on a reveal beat, which is the exact vocabulary break this batch refuses Abdel Haleem for. **Paraphrased rather than silently corrected**, since correcting a published translation is an edit to a quotation. | [Sahih Muslim 918a](https://sunnah.com/muslim:918) | ṣaḥīḥ | ✅ **verified — labelled paraphrase.** The source sentence is a byte-exact substring of the archived page (checked programmatically) and is reproduced in full in this row so the founder can compare it to the beat. Arabic: `ثُمَّ إِنِّي قُلْتُهَا فَأَخْلَفَ اللَّهُ لِي رَسُولَ اللَّهِ صلى الله عليه وسلم`. The beat adds *"anyway"* and *"in her own account"*; both report the narration's own order and its first-person voice and assert nothing further. |
| 5.4 | Beat 6, verse anchor, verbatim excerpt: "And it is He who begins creation; then He repeats it, and that is [even] easier for Him." | **Saheeh International.** Abdel Haleem fetched and compared: *"He is the One who originates creation and will do it again- this is even easier for Him."* — reads well and does **not** say "God" in this clause, but it uses a **hyphen as a dash** (`again- this`), the same typographic defect `al-kareem@1` had to disclose a normalisation for on 27:40, and *"will do it again"* pushes the verb into the future where the Arabic is not tensed that way. Not used. | [Qur'ān 30:27](https://quran.com/30/27) | Qur'ān | ✅ **verified** — live fetch `api.quran.com/api/v4/verses/by_key/30:27?translations=20,85`, 2026-08-03. **Byte-exact substring**; the fetched string carries **no footnote marker**, so nothing was stripped. The bracket `[even]` is the translator's own and is retained. Arabic: `وَهُوَ ٱلَّذِى يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ وَهُوَ أَهْوَنُ عَلَيْهِ`. Excerpt marked as such on the beat. |
| 5.5 | Duʿā text | catalog id 68 — **no scripture citation claimed, and this row is the one to read twice** | catalog only | n/a | ⚠️ **verified byte-identical to catalog** across `dua_arabic` / `dua_transliteration` / `dua_translation` (checked programmatically 2026-08-03) — **but it is NOT the narrated wording, and the deck must never imply that it is.** Ṣaḥīḥ Muslim 918a's taught sentence is `اللَّهُمَّ أْجُرْنِي فِي مُصِيبَتِي وَأَخْلِفْ لِي خَيْرًا مِنْهَا`. The catalogue's duʿā is `يَا مُعِيدُ أَعِدْ إِلَيَّ مَا أَخَذْتَهُ مِنِّي أَوْ أَبْدِلْنِي خَيْرًا مِنْهُ` — an **authored invocation that restates the narration's request in different words** (`أَبْدِلْنِي` for `أَخْلِفْ`, and an added first clause asking for return). **This deck therefore does NOT get plan §STEP-3 property 1**, unlike `al-mujeeb@1` and `al-waliyy@1`, and it must ship **unpinned**. Beat 3 quotes the narrated sentence; beat 7 shows the catalogue's; **no beat says they are the same.** |
| 5.6 | Beat 2 `name_intro` | catalog id 68 | catalog only | n/a | ✅ **verified byte-identical to catalog** across `arabic` / `transliteration` / `english`. |
| 5.7 | Beat 8 | — | authored | n/a | ✅ **honest label — authored copy.** It reports the order of the narration (objection at `قُلْتُ أَىُّ الْمُسْلِمِينَ…`, then `ثُمَّ إِنِّي قُلْتُهَا`) and nothing else. **It deliberately makes no promise to the reader** — see the reverence note below. |

### ⚠️ Reverence risk, faced — the promise this deck must not make

**Umm Salama's replacement was the Prophet ﷺ.** A deck that ends on *"and look what she got"* is telling the reader that a better thing is coming, which is (a) not a claim any source makes about the reader and (b) exactly the kind of Name-action attribution the format spec's reverence rule exists to stop.

**So beat 8 does not go near it.** It stays on what the narration records about **her**, not about what will happen to **the user**: the objection was voiced, and the sentence was said anyway. The catalogue's own `lesson` line for id 68 — *"What was taken from you — Al-Muid can restore it, or replace it with better"* — is a promise-shaped sentence about the reader, and it was deliberately **not** used as the takeaway, on the same reasoning `al-haleem@1` used for id 29's `lesson`.

**Beat 5 still reports the outcome**, because it is what the narration says and cutting it would leave the story without an ending. The load-bearing distinction: **beat 5 reports history; beat 8 refuses to generalise it.** If the founder reads beat 5 and hears a promise anyway, the fix is to end the story at *"Then she said the words anyway"* and lose the resolution — **one clause either way.**

### ⚠️ Catalog-level flag (not fixable by a deck)

**Catalog id 68's `hadith` field is not a ḥadīth.** It reads *"Allah says: 'He begins creation, then He will repeat it — and that is easier for Him.' … (Quran 30:27)"* — i.e. the field holds a **Qur'ān** citation under a column the app renders as ḥadīth. The citation itself is **correct and verified** (row 5.4), and the reading it gives is this deck's reading, which is why it is the strongest thing going for the deck. **Flagged only because the column is mislabelled for this Name, which is a rendering question the founder may want to look at across the catalogue.** This is the **last of four** catalogue flags raised across the five batch-2 decks (only `al-mujeeb@1`'s card came through clean) — see the review packet's summary, where that pattern is the recommendation.

### Ship-gate note — **this deck must carry NO duʿā `source`**

`renderedDuaSources` is asserted **in both directions** (commit `a12f1db`), and this deck is precisely the shape the new assertion exists to catch: it has a **real, ṣaḥīḥ, verified narration on its story beats** and a **catalogue duʿā that is not that narration's wording**. Putting `Sahih Muslim 918a` on the duʿā beat would render a provenance claim that row 5.5 explicitly refutes.

**The duʿā beat's `source` field must be empty, and `al-muid@1` must NOT be added to `renderedDuaSources`.** Verified: the full gate passes over `existing ∪ batch 2` with this deck unpinned.

### Review

`reviewed_by: null · reviewed_at: null · review_verdict: null` — **awaiting founder review**

### Collision check against all 19 existing decks

| existing deck | its inventory | collides? |
|---|---|---|
| **`al-jabbar@1`** (shipped) | 12:84/86/87/18/94/96, Yaqeen (framing) | ⚠️ **the closest semantic neighbour in the pack, and the distinction is argued rather than asserted.** Al-Jabbar is *"The Compeller — Restorer of the Broken"*; Al-Muid is *"The Restorer"*. **No shared citation** (Sūrat Yūsuf vs Sūrat ar-Rūm and Ṣaḥīḥ Muslim). **The engines differ, and the difference is on screen:** `al-jabbar@1` is about a **thing that broke and was mended** — Yaʿqūb's sight returns, his son returns, *"Sight restored. Son restored. Whole again."* This deck is about a **thing that is gone and is not coming back**, and a sentence said into that. **⚠️ But note where they touch:** `al-jabbar@1`'s arc is *a parent's lost child returned*, and if a founder reads both decks back to back he may hear "the thing came back" twice. **This is the deck's second-largest risk after the §"honest weakness", and it is the reason a Mūsā's-mother story for Al-Hafeez was rejected outright from this batch** — that one *is* a parent's lost child returned, and it would have made three. |
| `ash-shafi@1` (shipped) | 21:83–84, 26:80, Bukhārī 5743 | ⚠️ **worth naming.** Its insight is *"The answer to Ayyūb was not repair. It was more than there was before the breaking."* — i.e. **replacement with better**, which is this deck's ḥadīth in one line. **No shared citation and different subjects** (health and family restored to a prophet, vs a widow saying a sentence), but this is the second real adjacency and it is disclosed. See the insight table for how beat 8 steers off it. |
| `as-salam@1` · `al-wakeel@1` · `al-wadud@1` · `al-hadi@1` · `al-ghaffar@1` · `at-tawwab@1` · `al-lateef@1` · `ar-razzaq@1` · `al-fattah@1` · `ar-rahman@1` · `al-baseer@1` · `as-samad@1` | 13:28, 9:40, 59:23, Bukhārī 3653, Muslim 591 · 3:172–174, 65:3, Bukhārī 4563 · 11:90, Muslim 2747a, Bukhārī 6309 · 28:22 etc. · Bukhārī 7507, 39:53 · Bukhārī 3470, 2:37 · 12:100 etc., 42:19, 67:13 · 65:2–3, Tirmidhī 2344 · 48:1, 35:2, Bukhārī 4172/4833/2731 · 2:286, 7:156, 55:1, Bukhārī 5999 · 58:1, Bukhārī 3364, Ibn Mājah 188 · 19:2–7, 112:2 | ✖ none. **`as-salam@1` cites Muslim 591**, a different narration. |
| **batch-1 drafts** | `al-afuw@1` · `al-ghafur@1` · `al-kareem@1` · `al-haleem@1` · `ar-raheem@1` | ✖ none — no shared citation, and no batch-1 deck uses Sūrat ar-Rūm or Ṣaḥīḥ Muslim. |
| **batch-2 siblings** | `al-mujeeb@1` (21:87–88, 2:186, Tirmidhī 3505) · `al-qayyum@1` (93:1–3, 2:255, Bukhārī 4950) · `al-waliyy@1` (42:28, Muslim 1342 / Tirmidhī 3438) · **`al-qadir@1`** (2:260, 75:40) | ⚠️ **`al-qadir@1` is the one to watch, and the batch separated them on purpose.** Both decks stand on *bringing back what is finished*. **`al-qadir@1`'s demonstration is dead birds returning at a call and its insight is about being allowed to ask; this deck's is a widow saying a sentence and its insight is about saying it before you believe it.** No shared citation. Disclosed, because §G2b's insight axis is the one batch 1 nearly missed twice. |

**Verified negative, run programmatically:** **30:27 and Ṣaḥīḥ Muslim 918a** appear in **no** shipped deck and **no** batch-1 draft.

**Insight-level check.** Beat 8 — *"She said it after saying it could not be true. The narration keeps both, in that order — the objection first, and then the sentence anyway."*

| checked against | its insight | verdict |
|---|---|---|
| `ash-shafi@1` (shipped) | *"The answer to Ayyūb was not repair. It was more than there was before the breaking."* | ✖ **none, and it is the reason beat 8 is not about the replacement.** An earlier beat 8 ended on *"doing it again is the easier half"* — which is 30:27 mapped onto her life, i.e. **this deck's own semantic stretch turned into its punchline**, and it drifted straight into `ash-shafi@1`'s territory. Cut for both reasons. |
| `at-tawwab@1` (shipped) | *"In every one of these stories, the acceptance met the person mid-road. The turning is enough to begin."* | ⚠️ **adjacent in shape** — both say *the incomplete version counts*. **Different subjects:** that deck is about **repentance being accepted before it is finished**; this one is about **a sentence being said before it is believed**. And this batch's whole premise is that its reader is enduring, not repenting, which is the distinction the two decks turn on. Disclosed. |
| `al-jabbar@1` (shipped) | *"Al-Jabbar is the Name for what broke. Ash-Shafi… is the Name for what still hurts."* (pair synergy) | ✖ none |
| `al-lateef@1`, `as-samad@1`, `al-hadi@1`, `al-kareem@1`, `al-haleem@1`, `ar-raheem@1` | visible only from the far side · leaning is not weakness · needing guidance is not falling behind · the supply does not run down · the distance between earned and done · the sentence was theirs first | ✖ none |

### Authoring notes (candidates considered)

- **Selected: Umm Salama and Abū Salama (Ṣaḥīḥ Muslim 918a), anchored on 30:27.** The properties: **the objection is on the record**, which is the rarest thing in this whole sweep and the reason the deck exists; the ḥadīth is **ṣaḥīḥ in Muslim** with a clean isnād printed on the page; the verse anchor carries the Name's own root with Allah as subject and a clean neighbourhood in both directions; and **the app's own Name card already cites that exact āyah for that exact reading.**
- **Rejected as the verse anchor — [Qur'ān 85:13](https://quran.com/85/13)** (`إِنَّهُۥ هُوَ يُبْدِئُ وَيُعِيدُ`, the Name's own verb, unmistakable). **Rejected on bar 3 and bar 5 together:** 85:14 — the very next āyah — is `وَهُوَ ٱلْغَفُورُ ٱلْوَدُودُ`, i.e. **Al-Ghafur (a batch-1 draft) and Al-Wadud (a shipped deck), both Name-nouns, one āyah away**; and the passage's context is the People of the Ditch. Exactly the shape `al-haleem@1` was rejected for on 35:41.
- **Rejected as the verse anchor — [Qur'ān 10:4](https://quran.com/10/4)** and **[30:11](https://quran.com/30/11)**, both carrying `يَبْدَؤُا۟ ٱلْخَلْقَ ثُمَّ يُعِيدُهُۥ`. Both fetched, 2026-08-03. **10:4 fails inside its own āyah** — it ends *"But those who disbelieved will have a drink of scalding water and a painful punishment for what they used to deny."*, so no honest excerpt is available. **30:11 fails on bar 5** — it is a clean two-clause āyah, but `verses/by_key/30:12` is *"And the Day the Hour appears the criminals will be in despair."*, i.e. the successor turns straight to punishment. **30:27 is the one occurrence of this phrase whose own āyah and whose neighbourhood are both clean**, which is why it is the anchor. *(Neither rejected āyah is quoted anywhere in the deck.)*
- **Rejected as the Name for this material — Al-Muhyi (catalog id 69).** Considered and held back for batch 3 — see `al-qadir@1`'s authoring notes. It has a stronger root claim than Al-Muʿīd does on almost every candidate āyah, and three Names from one semantic field in one batch is the bar-3 failure mode.
- **Rejected outright from this batch — Al-Hafeez (catalog id 39) on Mūsā's mother (28:7–13).** Recorded here because it is the closest thing to a sixth deck and because its rejection is what protects this one. The story is Allah's action, the register is exact (*"everything you love is in the hands of Al-Hafeez — even when you cannot hold it"* is the card's own line), and it fails anyway: **`فَرَدَدْنَاهُ إِلَىٰ أُمِّهِ` — "So We restored him to his mother" — is `al-jabbar@1`'s arc, a parent's lost child returned**, and shipping it alongside this deck would put that arc on screen three times across the pack. The root `ḥ-f-ẓ` also does not appear in the passage. **Cut before drafting, on the insight axis, which is the axis batch 1 kept missing.**
- **Register check:** no beat attributes waiting, wanting or withholding to the Name. Beat 8 makes **no promise to the reader** — see the reverence section, which is the most important paragraph on this page.
