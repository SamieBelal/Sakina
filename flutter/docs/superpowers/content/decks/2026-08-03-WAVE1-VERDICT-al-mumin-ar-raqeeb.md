# Wave 1 adversarial verdict — `al-mumin@1` (id 7) and `ar-raqeeb@1` (id 40)

**Verifier:** independent blind adversarial pass, 2026-08-03. Instructed to **refute**, and to default to reject where independent confirmation was unavailable.
**Blinding:** the drafts' `Claim | Source | Grading | Status` tables were read only to know *what is asserted*. Every ✅ was treated as an unverified assertion by an interested party. Everything below was re-fetched from scratch.

| deck | verdict |
|---|---|
| **`al-mumin@1`** (id 7) | **FIX-THEN-SIGN** — two blocking findings, one of them the 9g echo |
| **`ar-raqeeb@1`** (id 40) | **FIX-THEN-SIGN** — one mandatory disclosure the drafter argued away on the wrong axis |

**Scripture authenticity is clean on both decks.** Every āyah and every ḥadīth re-fetched independently, every quotation compared byte-for-byte, every grade read off the page. **No fabrication, no misnumbering, no misattribution, no wrong lettered variant.** Both `843a` and `632a` are the correct letters, confirmed by fetching those exact pages and reading their own reference lines. As in both prior batches, the residual risk is not authenticity — it is reasoning, collision and disclosure.

---

## 1 · THE CALL THAT WAS MINE — ledger §9g

### RULING: **BLOCKING.** The `al-mumin@1` beat 4 ↔ `al-wakeel@1` beat 1 echo must be removed. The drafter's escape hatch works; take it.

I did not accept the drafter's reasoning as a ruling. I read both decks' actual beats out of `assets/content/name_stories.json` and out of the draft, and ran a token-level sweep over **all 473 rendered strings** (`primary` + `label` + `source`) of the 24 shipped decks.

**Five grounds, in order of weight.**

**1. "afraid" is a corpus hapax, and both uses do the identical job.**
Across all 473 shipped rendered strings the word **"afraid" occurs exactly once**: `al-wakeel@1` beat 2 — *"…and were told to be afraid. They were not."* `al-mumin@1` beat 4 would be the only other occurrence in the product. Both stage a threat, propose fear, and decline it. This is not a common-word coincidence; it is the rarest possible kind of string collision.

**2. The echo is not one beat. It is three consecutive beats of the same shipped deck.**

| `al-wakeel@1` (shipped) | `al-mumin@1` (draft) |
|---|---|
| b1 `name_intro`: "The Trustee — the **Guardian** you hand your affairs to" | beat 2 `name_intro`: "The **Guardian** of Faith — the One who grants safety" |
| b2 `story`: "…and were told to be **afraid**. They were not." | beat 4 `story`: "Are you **afraid** of me?" "No." |
| b3 `story`: "…and He is the best **Protector**." | beat 4 `story`: "Then who will **protect** you from me?" "Allah will **protect** me from you." |

The drafter disclosed the *Guardian* hit and the *afraid* hit **on two separate rows as two independent findings**, and never disclosed the *protect* overlap at all. Its method — substring-matching long candidate phrases such as *"who will protect you from me"* — **structurally cannot see a single-token overlap**, which is why its own zero-hit list is technically true and materially misleading. The compound is much larger than any of its parts and it points at **one specific shipped deck**.

**3. The drafter's strongest defence is correct and still insufficient.**
I verified both halves of it. The words *are* the narration's own (`أَتَخَافُنِي` / `لاَ`) and rewording them would be misquoting. The two beats *do* resolve in opposite directions: `al-wakeel@1` b3 is the believers' **own act** (`ḥasbunallāh`), `al-mumin@1` beat 4 is an **attribution to someone else**. I also found a differentiator stronger than any the drafter offered and which it missed — `al-wakeel@1` b4 resolves on *"The harm they had been told to fear never came,"* whereas `al-mumin@1` beat 5 **explicitly refuses that resolution** (*"Neither narration reports a miracle"*). But **a difference in resolution does not undo a repetition in staging.** On `BeatRevealFlow` the user meets beats one at a time; the staging is what lands, and the resolution arrives a beat later.

**4. Half this collision is unfixable, and that is the reason to fix the other half.**
*"The Guardian of Faith"* is catalogue id 7's own `english` — the *Restorer* class (ids 9/68), correctly a founder call about catalogue text, not fixable inside a deck. Precisely **because** that half cannot be fixed, the half that can be should be. A deck does not get to carry both an unfixable rendered-English collision **and** an avoidable beat-level echo **with the same neighbour**.

**5. I checked the escape hatch, and — against my first reading — it holds.**
My initial objection was that deleting `"Are you afraid of me?" "No."` orphans beat 8's opening sentence (*"He did not answer that he was brave"*). **I retract that.** With beat 4 opening on *"Then who will protect you from me?"*, bravado ("no one needs to") was an available answer and was not taken, so *"He did not answer that he was brave"* still lands cleanly. The real cost is the one the drafter named and named accurately: the story beats lose the word *fear*, weakening the direct `khawf` bind to 106:4's `خَوْفٍ`. Beat 1 (*"bracing"*) and beat 6 (*"from fear"*) still carry it. **The cost is acceptable. Take the escape.**

---

## 2 · `al-mumin@1` — findings

### Verified TRUE (independently re-fetched, nothing taken from the draft)

| probe | result |
|---|---|
| **Ṣaḥīḥ al-Bukhārī 2910** — Wayback `20260207142723` of the exact bare number, zstd-decoded | Najd, the return, `فَأَدْرَكَتْهُمُ الْقَائِلَةُ فِي وَادٍ كَثِيرِ الْعِضَاهِ`, `وَتَفَرَّقَ النَّاسُ يَسْتَظِلُّونَ بِالشَّجَرِ`, `تَحْتَ سَمُرَةٍ وَعَلَّقَ بِهَا سَيْفَهُ وَنِمْنَا نَوْمَةً`; his own words `وَأَنَا نَائِمٌ`; `فَقُلْتُ "اللَّهُ" ثَلاَثًا`; `وَلَمْ يُعَاقِبْهُ وَجَلَسَ`. Chapter *"Whoever hung his sword on a tree at midday nap"*, Book 56 Hadith 123. **Every element of beat 3 is on the page.** |
| **Ṣaḥīḥ Muslim 843a** — Wayback `20260313044750`, page's own reference line reads *"Sahih Muslim 843a"* | `أَتَخَافُنِي قَالَ "لاَ" . قَالَ فَمَنْ يَمْنَعُكَ مِنِّي قَالَ "اللَّهُ يَمْنَعُنِي مِنْكَ"`, then `فَتَهَدَّدَهُ أَصْحَابُ رَسُولِ اللَّهِ ﷺ فَأَغْمَدَ السَّيْفَ وَعَلَّقَهُ`. Published English capitalises **"Me"** for the attacker exactly as the drafter reports. *"Allah will protect me from you"* is byte-verbatim published English. **The lettered variant is correct.** |
| **Probe 1 — is the *asleep* / *three times* / *did not punish* material Bukhārī-only?** | **CONFIRMED.** Muslim 843a contains **no sleep, no repetition and no "did not punish"**. Its route has the man arrive and take the hanging sword; the answer is given **once**. The drafter's route assignment is exactly right, and no beat is built on a detail from the wrong route — with the one exception at **B1** below. |
| **Probe 2 — is a miracle narrated?** | **CONFIRMED: neither ṣaḥīḥ route contains it.** Bukhārī ends `وَلَمْ يُعَاقِبْهُ وَجَلَسَ`; Muslim has the Companions threaten him and the man sheathe the sword. The popular "the sword fell from his hand" is in neither. Beat 5 is right to say so out loud, and including Muslim's Companions clause rather than dropping it is the correct call — dropping it would leave a miracle-shaped hole. |
| **Probe 3 — 106:4** | `وَءَامَنَهُم مِّنْ خَوْفٍۭ` confirmed in `text_uthmani`. **Finite form-IV verb of Allah's own action, explicit object, explicit thing removed.** Saheeh string carries **no `<sup>`** and the beat is a **byte-exact substring** after the leading ellipsis. `verses/by_key/106:5` → `{"status":404,"error":"Ayah not found"}` — sūrah-final confirmed. All four āyāt read in full: **no warning, no rebuke, no punishment anywhere in Sūrat Quraysh.** |
| **Probe 4 — Abdel Haleem on `وَءَامَنَهُم`** | **CONFIRMED.** `85` renders 106:4 *"who provides them with food to ward off hunger, **safety** to ward off fear."* — the bare noun, dissolving the finite verb bar 1 rests on, **and** opening lower-case, which is the plan's own tell that the āyah continues 106:3. The leading ellipsis on beat 6 is required, not decorative. Rejecting Abdel Haleem here is correct. |
| 105:5 | `فَجَعَلَهُمْ كَعَصْفٍ مَّأْكُولٍۭ` — *"And He made them like eaten straw."* Confirmed; the backward cross-sūrah disclosure is honest. |
| 24:55 (fetched and refused by the drafter) | Confirmed: `وَلَيُبَدِّلَنَّهُم مِّنۢ بَعْدِ خَوْفِهِمْ أَمْنًا` **and**, in the same āyah, *"But whoever disbelieves after that - then those are the defiantly disobedient."* The refusal is correct and the āyah is genuinely blocked, not merely passed over. |
| Catalogue byte-identity | `arabic` `الْمُؤْمِنُ`, `transliteration` `Al-Mumin`, `english` `The Guardian of Faith` — exact. Gloss *"the One who grants safety"* is a **verbatim prefix** of id 7's `meaning`. All three duʿā fields byte-identical. |
| Glossed-`name_intro` precedent | **Verified programmatically against all 24 shipped decks:** exactly two glossed `name_intro`s exist (`al-wakeel@1`, `al-muid@1`); `al-jabbar@1`'s *"— Restorer of the Broken"* and `as-samad@1`'s *"The Eternal Refuge"* are verbatim catalogue `english`. Drafter correct. |
| Abū Dāwūd 4918 (the id-7 catalogue finding) | Real, text matches, **Grade printed: Ḥasan (Al-Albani)**, Book 43 Hadith 146, chapter *"Regarding sincere counsel and protection"*. `الْمُؤْمِنُ` is **the human believer, twice**. **The drafter's catalogue finding is correct and its refusal to recommend a change is correct.** |
| Ship-gate reading | `test/content/name_stories_ship_gate_test.dart` lines 234–243 confirmed: the `renderedDuaSources` assertion is bidirectional, with the comment *"the fabrication this whole gate exists to make impossible."* `source: ""` and no `renderedDuaSources` entry is the right call. |

### Bars, judged by me

- **Bar 1 — PASSES, asked strictly.** 106:4 is Allah's own speech (third-person self-reference / *iltifāt*, **not** the rejected class of reported human speech about Allah — 7:196, 12:101, 10:62, 10:82). Finite verb, explicit object, explicit thing removed, and the āyah's grammatical spine is *the One who fed them … and made them safe*. This is the strongest available form. I confirm the drafter's read after trying to break it.
- **Bar 2 — PASSES.** Nothing on any beat describes a feeling, mood or mindset. The showing is real: he is asleep (contributes nothing), the reason he gives is not about himself, and the āyah puts `ءَامَنَهُم` in grammatical parallel with `أَطْعَمَهُم`.
- **Bar 3 — FAILS as drafted**, on the compound disclosed in §1. Arabic-root side is clean: no `s-l-m`, `w-k-l`, `ḥ-f-ẓ`, `r-ḥ-m`, `gh-f-r`, `ʿ-f-w` anywhere. *"safe"* and *"safety"* return **zero** hits across all 24 shipped decks — verified.
- **Bar 4 — PASSES, no trade needed.** `ءَامَنَهُم` (106:4) and `ٱلْإِيمَانِ` (duʿā beat, renders in Arabic).
- **Bar 5 — PASSES maximally.** 404 + a four-āyah sūrah with no adverse content anywhere.

### BLOCKING — B1. Beat 5's *"He said it three times"* is a cross-route conflation, and the drafter's row 1.4 contains a false statement

Bukhārī's `ثَلاَثًا` attaches to the **one-word answer `اللَّهُ`**, given to `مَنْ يَمْنَعُكَ مِنِّي`. Muslim's route carries the **full sentence** *"Allah will protect me from you"* — said **once**.

Beat 4 ends on Muslim's full sentence. Beat 5 then opens *"He said it three times."* The only available antecedent for *"it"* is the sentence the user just read. **No ṣaḥīḥ route reports that sentence being said three times.**

The drafter's defence in row 1.4 — *"Beat 5 does not attribute it to Muslim"* — is **false as rendered**. Beat 5's own source line is `(source line: Sahih al-Bukhari 2910 · Sahih Muslim 843a)`, and nothing on screen separates which clause belongs to which route. This is a beat saying something the sources do not say, which is founder-checklist item 2.

**Fix, one line:** make the repeated utterance explicit and Bukhārī's, e.g. *"In Bukhārī's telling the answer is one word — Allah — and he says it three times."*

### Non-blocking findings

- **N1 — the successor sweep is incomplete: there is no ḥadīth-continuation row at all.** The `ar-raqeeb@1` draft has one; this one's table covers only Qurʾān. It matters, because **Muslim 843a does continue** — into *ṣalāt al-khawf* (`فَنُودِيَ بِالصَّلاَةِ فَصَلَّى بِطَائِفَةٍ رَكْعَتَيْنِ …`) — and **Muslim files the entire narration under `باب صَلاَةِ الْخَوْفِ`, "The fear prayer."** Nothing in the continuation is adverse and bar 5 still passes on the ḥadīth side. But beat 5's word ***"only"*** claims a completeness the narration does not have, and the founder is nowhere told that the ḥadīth continues or where Muslim files it. **Disclose in the packet.**
- **N2 — two routes' settings are blended into one continuous scene, undisclosed.** Beat 3 is Bukhārī's (Najd, thorn valley, midday, sleep); beat 4 is Muslim's (Dhāt ar-Riqāʿ, a shady tree). Muslim 843a contains **none** of Najd, thorn trees, midday or sleeping. They are the same incident by any standard reckoning — Jābir narrates both and Abū Salama is in both isnāds — and each beat carries its own source line, so the deck is honest at the beat level. But the blend is stated nowhere in the draft.
- **N3 — a catalogue drift on id 7 the draft did not report.** It audited the `hadith` field only. Id 7's **`lesson`** reads *"Al-Mumin sees your sincerity even when others doubt you."* — Al-Baseer / Ar-Raqeeb register on Al-Muʾmin's card, saying nothing about safety, one tap from this deck. **Finding, not instruction.** The standing rule applies: three of three confident recommendations to change catalogue data have been wrong.
- **N4 —** beat 3's *"in a valley"* also opens shipped `al-baseer@1`'s first story beat (*"in a valley with no people and no water"*), at the same beat index. Extremely common setting; noted only because the draft's own authoring notes refuse Ibrāhīm's duʿā partly on the ground that *"the empty valley is shipped `al-baseer@1`'s Hājar."*

### To sign `al-mumin@1`
1. Remove the beat-4 echo per §1 (open beat 4 on *"Then who will protect you from me?"*).
2. Fix B1 so the *three times* attaches to Bukhārī's one-word answer.
3. Add N1 and N2 to the packet as disclosures.
4. *Guardian* remains an open founder call in the *Restorer* class — record, do not fix in the deck.

---

## 3 · `ar-raqeeb@1` — findings

### Verified TRUE (independently re-fetched)

| probe | result |
|---|---|
| **Probe 5 — Ṣaḥīḥ Muslim 632a**, Wayback `20260218094934`; page reference line reads *"Sahih Muslim 632a"*, Book 5 Hadith 265 | **CONFIRMED: nothing is elided.** I matched all six clauses of `يَتَعَاقَبُونَ فِيكُمْ مَلاَئِكَةٌ بِاللَّيْلِ وَمَلاَئِكَةٌ بِالنَّهَارِ وَيَجْتَمِعُونَ فِي صَلاَةِ الْفَجْرِ وَصَلاَةِ الْعَصْرِ ثُمَّ يَعْرُجُ الَّذِينَ بَاتُوا فِيكُمْ فَيَسْأَلُهُمْ رَبُّهُمْ وَهُوَ أَعْلَمُ بِهِمْ كَيْفَ تَرَكْتُمْ عِبَادِي فَيَقُولُونَ تَرَكْنَاهُمْ وَهُمْ يُصَلُّونَ وَأَتَيْنَاهُمْ وَهُمْ يُصَلُّونَ` against beats 3–5. **Every clause is on a beat and the narration ends on the angels' answer.** The drafter's claim holds and the ellipsis discipline genuinely does not bite. **See N6 for the one exception to "verbatim".** |
| **Probe 6 — do Bukhārī 555 and 7429 differ?** | **CONFIRMED, exactly as claimed.** 555 (`20250814023635`): `وَهْوَ أَعْلَمُ بِهِمْ`, order `صَلاَةِ الْفَجْرِ وَصَلاَةِ الْعَصْرِ`, Book 9 Hadith 32, chapter *"Superiority of the ʿAṣr prayer"*. 7429 (`20240815023141`): `وَهْوَ أَعْلَمُ بِكُمْ`, order `صَلاَةِ الْعَصْرِ وَصَلاَةِ الْفَجْرِ`, **plus `فَيَقُولُ`**, Book 97 Hadith 56, Kitāb at-Tawḥīd under `تَعْرُجُ الْمَلاَئِكَةُ وَالرُّوحُ إِلَيْهِ`. 555's published English does read *"though He knows everything about you, well"* against its own `بِهِمْ`. All three share Mālik ← Abū az-Zinād ← al-Aʿraj ← Abū Hurayra. **The deck follows Muslim 632a throughout and mixes no route** — verified clause by clause, including Fajr-before-ʿAṣr on beat 3 and `رَبُّهُمْ` on beat 4. |
| 52:47 · 52:48 · 52:49 · 52:50 · 52:46 · 52:16 · 52:13 | All confirmed verbatim, including `فَٱصْبِرُوٓا۟ أَوْ لَا تَصْبِرُوا۟` at 52:16 as a taunt to the punished. `verses/by_key/52:50` → **404**. |
| Catalogue byte-identity | id 40 `arabic` `الرَّقِيبُ`, `transliteration` `Ar-Raqeeb`, `english` `The Watchful` — exact, unglossed. All three duʿā fields byte-identical. |
| Id 40 catalogue `hadith` finding | **Confirmed.** Id 46 (Al-Baseer, shipped): *"Al-Basir saw Yunus (AS) in three layers of darkness — the night, the sea, and the belly of the whale — and heard his call. (Ibn Mas'ud)"*; id 40 is the same string with the final clause swapped. The 20-word shared run is real; *"(Ibn Mas'ud)"* alone names no collection and no number and cannot be resolved. **Correct finding, correctly not actioned.** |
| Ship-gate reading | Same as above — confirmed. |

### Probe 9 — **BAR 4 RE-RUN INDEPENDENTLY. The trade is forced, the record is true, and I closed the gap the drafter left open.**

I did **not** use `api.quran.com/api/v4/search`. I pulled the **entire Uthmānī text — all 6,236 āyāt** — stripped diacritics, normalised hamza/alif/yāʾ, and scanned every word.

**Name-noun `رَقِيب`: exactly five occurrences. There is no sixth.**

| | verified rejection |
|---|---|
| **4:1** | `إِنَّ ٱللَّهَ كَانَ عَلَيْكُمْ رَقِيبًا` — **sentence-final trailing epithet.** Bar 1. Correct. |
| **5:117** | ʿĪsā's speech (`مَا قُلْتُ لَهُمْ …`), and the same āyah carries `شَهِيدًا` **and** `شَهِيدٌ`. Bar 1 + bar 3. Correct. |
| **11:93** | `إِنِّى مَعَكُمْ رَقِيبٌ` — **Shuʿayb calling himself raqīb**, with `عَذَابٌ يُخْزِيهِ` **inside the same āyah**. Three bars. Correct. |
| **33:52** | `وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ رَّقِيبًا` — trailing epithet on a marital ruling. Correct. |
| **50:18** | `لَدَيْهِ رَقِيبٌ عَتِيدٌ` — **the recording angel**, in exactly the surveillance-of-speech register this deck exists to refuse. Correct. |

**And I ran the sweep the drafter explicitly declined to run.** All 24 r-q-b words in the Qurʾān: `الرقاب` (2:177, 9:60, 47:4), `رقبة` (4:92×3, 5:89, 58:3, 90:13) — *neck / manumission*, a different sense entirely; and the verbal forms `يرقبوا` (9:8), `يرقبون` (9:10), `وارتقبوا` (11:93), `ترقب` (20:94), `يترقب` (28:18, 28:21), `فارتقب` (44:10, 44:59), `مرتقبون` (44:59), `فارتقبهم` (54:27). **Not one has Allah as the watching subject** — every one is human, and every imperative `فَٱرْتَقِبْ` sits in a punishment passage (44:10 the smoke; 44:59 *"await; they are awaiting"*; 54:27 Thamūd's she-camel). **The trade is more forced than the drafter proved it to be.** Bar 4 traded, legitimately, with a complete record.

### Probe 7 — the 52:48 re-rendering. **My judgement: ACCEPTABLE. It does no theological work Saheeh does not, and avoids none that Saheeh does.**

`فَإِنَّكَ بِأَعْيُنِنَا`. Saheeh: *"you are in Our eyes [i.e., sight]"*. Abdel Haleem: *"you are under Our watchful eye"*. Deck: *"you are before Our eyes"*.

The drafter's argument is right, and I tried to break it. **"In Our eyes" is an English idiom meaning *in Our estimation / in Our judgement*** — Saheeh has to bolt on `[i.e., sight]` precisely to stop the reader landing there. *"Before Our eyes"* resolves to **the same reading Saheeh's own bracket resolves to**, so it adjudicates nothing Saheeh leaves open; it removes a trap Saheeh's choice of preposition created. It keeps `أَعْيُن` **plural**, which Abdel Haleem's singular *"eye"* does not. *"Before"* is marginally more locative than `بِ`, but sits inside the classical gloss (`بمرأى منا`) and is **not more anthropomorphic than the Arabic itself**.

It drops Saheeh's `[O Muḥammad]` — but restores it **on screen**, in the beat's own `source` string (*"said to the Prophet ﷺ"*), which is better than a bracket and follows shipped `al-baseer@1`'s 58:1 precedent. **Row 2.7 is the best-reasoned row in either draft.** The trailing ellipsis is present on the beat and the omitted clause is an instruction to praise. One lost nuance, non-blocking: `فَإِنَّكَ` loses the `إِنَّ` emphasis.

### Probe 8 — bar 5 and the tone line

**Bar 5 — PASSES.** 52:47 is a self-contained punishment clause about `ٱلَّذِينَ ظَلَمُوا۟`; **52:48 opens a fresh imperative `وَٱصْبِرْ` with a different addressee and does not continue it.** `52:50` → 404, and 52:49 is night praise. For a Name met at night the forward direction could not be better. Both backward disclosures are honest and I found nothing they conceal.

**Tone — my ruling: WATCHED OVER, not surveilled. But narrowly, and one risk is unnamed.**

It lands on *watched over*, and it lands for two reasons that are genuinely on the beats: `وَهُوَ أَعْلَمُ بِهِمْ` on beat 4 (shown, not asserted), and the fact that the last scripture on screen is protective while the duʿā asks to be guarded. The deck also does what it says it does — no ledger, no record, no reckoning, no count renders anywhere, and 50:18 is correctly refused.

**The unnamed risk: beat 5's answer is a performance report.** Muslim files this narration under `باب فَضْلِ صَلاَتَىِ الصُّبْحِ وَالْعَصْرِ وَالْمُحَافَظَةِ عَلَيْهِمَا` — *"The virtue of the Ṣubḥ and ʿAṣr prayers, and of maintaining them."* Its own purpose is an exhortation to pray Fajr and ʿAṣr. A user awake at 11pm who has **not** been praying reads beat 5 and hears: *a nightly report goes up about whether you prayed.* That is the surveillance reading, and beat 8's reframe **asserts** against it rather than **showing** against it. The drafter's bar-2 argument (b) — *"the report that comes back is of the good"* — is true of the text and does not retire the affective risk. **Non-blocking; the founder should decide with this in front of them, because the deck's own tone line claims this risk was handled.**

### MANDATORY DISCLOSURE — R1. An undisclosed beat-to-beat echo with **shipped `al-ghafur@1`** — the §9g class, on this deck, argued away on the wrong axis

**Shipped `al-ghafur@1` beat 3**, on screen today:
> *"He said: 'Allah will bring the believer near, and place His covering over him, and screen him, and say: **Do you know such-and-such a sin? Do you know such-and-such a sin?** He will say: Yes, my Lord.'"* — and its beat 7 closes *"…named once, in private, to the One who **already knew**."*

**`ar-raqeeb@1` beat 8 — the deck's entire takeaway:**
> *"**He asks a question He does not need the answer to.** That is the difference between being watched and being watched over…"*

**The move is identical: Allah asking a question to which He already has the answer.** It is `al-ghafur@1`'s rendered story beat, and it is `ar-raqeeb@1`'s whole beat 8.

**The drafter looked at this exact deck and disclosed only that it had avoided the *string* "already knows."** That is the batch-2 failure verbatim — comparing at the wrong granularity and declaring the collision handled. It then wrote *"the engines differ: `al-ghafur@1` is covering; this is attention"* — true of the engines, and irrelevant to the move.

**Severity: I rule this NON-BLOCKING but MANDATORY-DISCLOSURE.** The object differs (the servant's own sins vs the angels' report about him), the consolation differs (covering vs interest taken), and the two strings share **no 3-gram** — I checked. But it is this deck's single most distinctive line, its core move is already on screen elsewhere, and it was **argued away rather than raised**. The founder signs on that line and must see this. **If the founder rules it a repeat, the deck needs a new beat 8, not a reword.**

### Non-blocking findings

- **N6 — beat 5 is not byte-verbatim, and row 2.4's word *"verbatim"* is not accurate.** Muslim's published English: *"We left them while they were praying and we came to them while they were praying."* The deck inserts a comma: *"praying, **and** we came"*. Religiously immaterial; the **claim** does not pass. Same class as the pilot's `18:10` `text_imlaei` ✅.
- **N7 — beat 3 renders `وَيَجْتَمِعُونَ` ("they all assemble") as "They overlap twice."** *"Overlap"* is an interpretive gloss and *"twice"* is arithmetic from the two named prayers. Defensible, and beat 3 is honestly framed as reported speech with no quotation marks. **But the deck's bar-2 argument (a) — *"the narration's own structure says there is no unwatched hour"* — rests entirely on that gloss.** The narration says the two groups *assemble* at two prayers; *"no hour is unattended"* is the deck's inference, not the text's statement. Bar 2 still passes, on the strength of (c) `وَهُوَ أَعْلَمُ بِهِمْ`, which is genuinely shown.
- **N8 — the Al-Muhaymin (18) flag is worse than recorded.** The drafter flagged the `ʿ-y-n` / *eyes* image against id 18's duʿā (`بِعَيْنِكَ الَّتِي لَا تَنَامُ`). It missed that **id 18's catalogue `meaning` reads *"The One who **watches over** and protects all things"*** — i.e. this deck's own beat-8 distinguishing phrase, already on another Name's card. Still catalogue-vs-deck, still unfixable inside either deck; the founder should see both halves of it.
- **N9 — a catalogue finding on this deck's own Name that the draft missed.** It audited the `hadith` field only. **Id 40's `meaning` reads *"The One who **sees** every action, thought, and intention."*** — *sees* is Al-Baseer's verb, which this deck spends eight paragraphs avoiding, and the exhaustive enumeration is the register the tone line forbids. It is on the Name card one tap from the deck. Id 40's `lesson` (*"Ar-Raqeeb sees the good you do in secret"*) carries the same verb. **Findings, not instructions.**
- **N10 —** shipped `al-baseer@1` b4 renders *"No human eye saw her"*; this deck's beat 6 renders *"before Our eyes"*. The drafter's "no `b-ṣ-r`" claim is true **in Arabic**; the English token *eye* is shared. Opposite functions, non-blocking.

### Bars, judged by me

- **Bar 1 — PASSES, twice.** `فَإِنَّكَ بِأَعْيُنِنَا` is the `فَ`-clause **giving the reason** for the imperative — it does work in the sentence and is not a trailing epithet. And Allah speaks in the narration (`كَيْفَ تَرَكْتُمْ عِبَادِي`).
- **Bar 2 — PASSES**, with N7 noted.
- **Bar 3 — PASSES with disclosures**, now including R1. Arabic clean: no `b-ṣ-r`, no `sh-h-d`, no `h-y-m-n`, no `ḥ-ṣ-y`. English n-gram sweep against all 24 shipped decks and all 2026-08-0x drafts on disk returned only connective boilerplate (*"the Prophet said"*, *"is the best"*, *"while they were"*).
- **Bar 4 — TRADED, and the trade is FORCED.** Verified above to a higher standard than the drafter's.
- **Bar 5 — PASSES.**

### To sign `ar-raqeeb@1`
1. Put R1 in front of the founder before signing — the `al-ghafur@1` move, not the `al-ghafur@1` string.
2. Correct row 2.4's *"verbatim"* claim (N6) or restore Muslim's punctuation.
3. Add N7, N8, N9 to the packet.
4. Nothing about the scripture, the enumeration, the translation call or bar 5 needs to change. **The bar-4 sweep on this deck is the strongest piece of verification work in either batch.**

---

## 4 · What I could NOT verify — the limits of my own method

Stated because the founder signs against this document too.

1. **My ḥadīth verification is not independent of sunnah.com as a corpus.** sunnah.com 403s automation, so I read **Wayback captures of sunnah.com itself** — the same digitisation the drafter used, not a second witness. I consulted **no printed edition and no Arabic-primary database** (Shamela, Dorar, al-Maktaba al-Shāmila). *This limit has not moved since the pilot and I did not move it.*
2. **I audited no isnād.** Bukhārī and Muslim were accepted as graded by inclusion; Abū Dāwūd 4918's *Ḥasan (Al-Albani)* was accepted as printed on the page.
3. ~~**My `رَقِيب` enumeration is one source, not two.**~~ **CLOSED.** I re-ran it over a **second, orthographically different corpus** — all 6,236 āyāt of `text_imlaei`, with a different normalisation (including tāʾ-marbūṭa folding) — and it returns **the identical five: 4:1, 5:117, 11:93, 33:52, 50:18.** Two independent orthographies of the full Qurʾān agree, and the result matches the classical concordance. The remaining limit is only that both corpora are served by `api.quran.com`; I did not consult a printed muṣḥaf index.
4. **Duʿā provenance for ids 7 and 40 remains unresolved, not disproven.** I searched no Arabic-primary corpus either. Both are correctly **unpinned**, because that is the conservative default the gate enforces — **not** because either was established to be unnarrated. Reporting them as "no provenance" would be the §9k error.
5. **The bare-URL number check is inconclusive in one direction.** CDX returned no captures for `sunnah.com/muslim:632` for me as well as for the drafter — but a CDX miss is not proof the bare URL fails to resolve. What I *did* establish, by fetching those exact pages, is that **`muslim:632a` and `muslim:843a` are the correct lettered variants** and that each page's own reference line agrees. That is the claim that matters.
6. **The rendered-English sweep covers the 24 shipped decks (473 strings) plus every 2026-08-0x draft on disk.** Decks drafted concurrently this wave and not yet written to disk were not compared — including `al-aleem@1` (id 14), whose claimed cession of *watching / seen / recorded* vocabulary I could not independently confirm.
7. **The tone ruling (probe 8b) is a judgement, not a measurement.** I have no user data and no way to test it.
8. **I ran no tests.** Neither deck is in `assets/content/name_stories.json`, so `flutter test` would prove nothing about them. My ship-gate statements are read off `test/content/name_stories_ship_gate_test.dart` and checked by hand.
9. **I edited nothing.** No draft, no `name_stories.json`, no `collectible_names.json`, no test, no commit.
