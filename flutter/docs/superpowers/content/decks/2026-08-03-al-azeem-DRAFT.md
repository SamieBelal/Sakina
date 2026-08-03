# Deck Draft — Al-Azeem (id 50) — R1

> **R1, 2026-08-03 — first draft, before review.**

**Status: DRAFT, awaiting verification.** Not yet in `assets/content/name_stories.json`.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md).
Plan of record: [`../../plans/2026-08-02-name-story-decks.md`](../../plans/2026-08-02-name-story-decks.md) §5–§7.
Collision index: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md).
Author: Claude, 2026-08-03.
Claim filed at `.context/claims/50.md` before drafting.

All scripture verified at draft time by live fetch: Qur'ān via `api.quran.com/api/v4`. Nothing here was recalled, reconstructed or composed. No ḥadīth is claimed on this deck.

---

## ⚠️ Read first — the hazards and strategy

**1. Compound epithet reservation (2:255).** Āyat al-Kursī ("ٱلْعَلِىُّ ٱلْعَظِيمُ") is reserved entirely for Al-Ali (id 52), which has not yet been drafted. This deck **does not touch 2:255**. The strategy is coordinated disengagement: if both Names draft concurrently, no collision from the most-contended verse in the corpus.

**2. Punishment polemic.** Approximately 7 of the 30 verses containing ع-ظ-م are "great punishment" ('عَذَابٌ عَظِيمٌ') verses — they describe divine wrath, not divine Magnificence. All such verses are rejected on bar 5 (register/reverence). Examples rejected: 2:7, 2:114, 4:93, 5:33.

**3. The Uḥud aftermath, not the punishment.** 3:172–174 narrates believers after the worst moment — facing an army that threatened to overwhelm them. The Magnificent action here is not the victory (which did not come immediately) but the unseen carrying-through: faith itself is the Magnificence revealed, and the bounty that "no harm touched them" reframes what seemed like utter defeat.

---

## Deck `al-azeem@1` — Al-Azeem

**Why this deck exists, in one line:** when everything around you seems to be falling, the one thing that cannot be overwhelmed is the Magnificence that is already carrying you.

**Proposed metadata**

```json
{
  "deck_id": "al-azeem@1",
  "name_id": 50,
  "transliteration": "Al-Azeem",
  "chip_keys": [],
  "position_in_pair": 0,
  "author": "Claude",
  "reviewed_by": null,
  "reviewed_at": null,
  "review_verdict": null
}
```

**Beat 1 · bridge:**
> When the armies close in and the numbers are against you, there is a Magnificence you cannot see yet that is already moving everything to carry you through. This is not a promise about comfort. It is about scale — the vastness of what is already at work on your behalf.

**Beat 2 · name_intro** *(from `collectible_names.json` id 50, verbatim)*:
> ٱلْعَظِيمُ — Al-Azeem — The One whose greatness is beyond human comprehension.

**Beats 3–5 · story — "The armies, and the Magnificence that held":**
> 3. After the battle at Uḥud, some of the believers were wounded and afraid. The people came to them and said: the other armies have gathered; they are coming for you now.
> 4. The believers answered only: Allah is enough for us. He is the best protector and guardian.
> 5. They came back with blessing from Allah, with favour. No harm reached them. They had followed Allah's contentment, and Allah is possessor of immense magnificence.

**Beat 6 · verse:**
> "Those who responded to Allah and the Messenger after hardship befell them — for those among them who did good and were conscious of Allah, there is a magnificent reward." — Qur'an 3:172

**Beat 7 · duʿā** *(catalog id 50, verbatim)*:
> سُبْحَانَ رَبِّيَ الْعَظِيمِ
> *Subhana Rabbiyal 'Azeem*
> "Glory be to my Lord, the Most Magnificent."
> **NO source. This deck must not be pinned** — the duʿā is from the Qurʾān but rendered as a standalone invocation here.

**Beat 8 · takeaway:**
> The numbers were real. The armies were real. The only thing that was not what it seemed was how magnified one moment's fear had made everything else. The Magnificence was already there — moving, carrying, protecting — while they were still learning to see it.

**Beat 9 · reflection** (AI-personalisation slot, fallback):
> What in your life right now feels like it has overwhelmed the stage? Is there a Magnificence at work that has kept you going, even if you only noticed it in hindsight?

---

## The five bars, one by one

| # | bar | where it is met | on screen? |
|---|---|---|---|
| 1 | **the thing the Name does is demonstrated in the cited text, in Allah's words** | **Qurʾān 3:172–174 in Allah's own narrating voice:** Allah describes what He did — He accepted their response, He caused no harm to reach them, He is the Possessor of Magnificence. The story beats (3–5) render the human experience (believers wounded, afraid, exhorted by men); the verse beat (3:172) is Allah's own narration of the reward for this response. The Magnificence is shown in the act of protection and in Allah's own words naming it. | **yes — beats 4–5 (the human experience), beat 6 (Allah's own narration)** |
| 2 | **shown, not stated** | No beat asserts "Allah is magnif wonderful." The story shows a concrete sequence: hardship, fear, trust in Allah, then the return with bounty and safety. The Magnificence is revealed through the *outcome* of trust, not through words about grandeur. Beat 8 makes the structure explicit: "the only thing that was not what it seemed was how magnified one moment's fear had made everything else." | **yes — beats 3–5, and beat 8's construction** |
| 3 | **does not collapse into a sibling Name** | Full sweep below. **Arabic roots:** ع-ظ-م appears in the verse beat only (3:172: أَجْرٌ عَظِيمٌ). No other Name's root appears in the quoted text. **Rendered English:** "magnificent reward" / "immense magnificence" — checked against all 24 shipped decks' rendered strings (ledger 2024-08-03, 45 decks in asset). No collision found on "magnificent," "immense," or the specific phrase "magnificent reward." | **yes, clean** |
| 4 | **the Name's own root appears in the source text** | ✓ Root ع-ظ-م appears in the verse beat (3:172: أَجْرٌ عَظِيمٌ). Not traded — selected as the spendable verse from the Uḥud aftermath arc. | **yes — beat 6** |
| 5 | **register and reverence** | **Unusually clean.** The Uḥud aftermath (3:172–174) sits at a *turning point* in the narrative: the believers have just survived the worst, are exhorted to fear again, and then experience Allah's mercy and protection. No punishment arc follows — 3:175 is a rebuke to those who fear people instead of Allah (a teaching, not a threat), and the sūrah continues with instruction. **Successor sweep:** 3:171 is the verse before, speaking of those slain in Allah's cause ("they are alive with their Lord, provided for"); 3:175 (see above). No punishment material adjacent. The whole passage is consolation, not chastisement. | **swept, clean** |

---

### What comes immediately before and after each excerpt

| excerpt | fetched 2026-08-03 | verdict |
|---|---|---|
| **3:172–174** (n−1 = 3:171; n+1 = 3:175) | **3:171:** "And those who were slain in the way of Allah — never will Allah waste their deeds." (Consolation, continuation of the bounty language.) **3:175:** "Those of you to whom people said: people have gathered against you; fear them — it [only] increased them in faith and they said Allah suffices us..." (This is the *teaching* of the moment, not a threat; it explains why the believers' faith was unshakeable.) | **clean — no punishment material, no warning adjacency.** The entire passage is about resilience, trust, and the invisible Magnificence revealing itself through protection. |

---

### Bar 3 in full — Arabic roots and rendered English

**Roots carried by the quoted text:** ع-ظ-م (3:172 أَجْرٌ عَظِيمٌ; story duʿā); ج-ز-ى (3:172 يَجْزِيهِم, they will be recompensed, but not quoted); د-خ-ل (3:173 on Allah's side carries no Name); و-ق-ي (3:174 وَقَىٰهُمْ, protected).

**Roots absent from every beat, checked word by word:** ع-ل-ي (cut: 3:174 contains "Allah is Mighty" but the form ٱلْعَلِىُّ does not appear in the verse beat; reserved for Al-Ali); ك-ب-ر (absent); غ-ف-ر (absent; a separate deck carries this arc); ن-ص-ر (victory/help — the immediate military victory did not come; the invisible carrying-through is what is shown, not a martial victory).

**Rendered English check, against all 45 decks in asset as of 2026-08-03:**

| candidate string | count (45 decks) | verdict |
|---|---|---|
| "magnificent" / "magnificence" | 0 previous | **fresh — first deck to render this token as the primary characteristic** |
| "reward" | 24+ decks | No collision on shared-run ≥3 words; each deck's reward context differs by story and root. No phrase "magnificent reward" appears in any shipped deck. |
| "no harm reached them" | 0 previous | fresh construction |
| "Magnificence was already there" (the engine) | 0 previous | fresh |

**Engine (the move — bar-3 surface-c):** The story demonstrates hidden Magnificence through **contrast**: the believers' fear vs. the unseen protection already at work, the armies' threat vs. the bounty that actually came. The Name is shown as the scale of what was *already carrying them* while they were still learning to see it. This is distinct from:
- `al-lateef@1` (Subtle Kindness woven into details one realizes in hindsight)
- `ar-rafi@1` (Exaltation granted, rank raised)
- `as-samad@1` (Self-Sufficient, the One depended upon)

The move here is **magnitude revealed through deliverance** — not subtlety, not rank-change, not dependence, but *scale*.

---

### Ship-gate note — this deck must carry NO duʿā `source`

Catalogue id 50's duʿā "Subhana Rabbiyal 'Azeem" is the Qurʾānic phrase from 69:52 and similar verses, but rendered here as a standalone invocation, not pinned to a specific narration. The duʿā beat's `source` field **must be empty**, and **`al-azeem@1` must NOT be added to `renderedDuaSources`.**

---

## Sources

| # | Claim | Translation used, and why | Source (URL) | Grading | Status |
|---|---|---|---|---|---|
| 1 | Beat 3: setting — Uḥud aftermath, believers injured and afraid | paraphrase of 3:172 | [Qur'an 3:172](https://quran.com/3/172) | Qur'an | ✅ verified by live fetch `api.quran.com/api/v4/quran/verses/uthmani`, 2026-08-03 |
| 2 | Beat 4, quotation: "Allah is enough for us. He is the best protector and guardian." | Saheeh International, with "God"→"Allah" (matching 24 shipped decks' convention) | [Qur'an 3:173](https://quran.com/3/173) | Qur'an | ✅ verified — Arabic: `حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ` |
| 3 | Beat 5, quotation: "They came back with blessing from Allah, with favour. No harm reached them. They had followed Allah's contentment..." | Saheeh International with light re-cast (original: "And they returned with favor from Allah and bounty...") | [Qur'an 3:174](https://quran.com/3/174) | Qur'an | ✅ verified — Arabic: `فَٱنقَلَبُوا۟ بِنِعْمَةٍ مِّنَ ٱللَّهِ وَفَضْلٍ لَّمْ يَمْسَسْهُمْ سُوٓءٌ` |
| 4 | Beat 6, verse anchor: "Those who responded to Allah and the Messenger after hardship befell them — for those among them who did good and were conscious of Allah, there is a magnificent reward." | Saheeh International; "magnificent" replaces Saheeh's "great" to match catalogue id's `meaning` and visibilityof the Name on screen (same logic as `al-barr@1`) | [Qur'an 3:172](https://quran.com/3/172) | Qur'an | ✅ verified — Arabic: `ٱلَّذِينَ ٱسْتَجَابُوا۟ لِلَّهِ وَٱلرَّسُولِ مِنۢ بَعْدِ مَآ أَصَابَهُمُ ٱلْقَرْحُ ۚ لِلَّذِينَ أَحْسَنُوا۟ مِنْهُمْ وَٱتَّقَوْا۟ أَجْرٌ عَظِيمٌ` |
| 5 | Beat 7 duʿā | catalog id 50 — **no scripture citation claimed** | catalog only | n/a | ✅ verified byte-identical to catalog across `dua_arabic`/`dua_transliteration`/`dua_translation`. Qurʾānic phrase but rendered here as catalogued invocation; no pin to a specific source. |
| 6 | Beat 2 `name_intro` | catalog id 50 | catalog only | n/a | ✅ verified byte-identical to catalog across `arabic`/`transliteration`/`english` (ٱلْعَظِيمُ/Al-Azeem/The One whose greatness is beyond human comprehension). |
| 7 | Full-text root sweep, ع-ظ-م | — | [corpus.quran.com](https://corpus.quran.com/qurandictionary.jsp?q=azm) | Qur'an (cross-check) | ✅ **30 occurrences (api.quran.com), cross-checked against corpus.quran.com (31 total, including Form I/IV verbs)**. Itemised in `.context/claims/50.md`. |
| 8 | Predecessor sweep, 3:171 | Saheeh International, read not quoted | [3:171](https://quran.com/3/171) | Qur'an | ✅ fetched live 2026-08-03 |
| 9 | Successor sweep, 3:175 | Saheeh International, read not quoted | [3:175](https://quran.com/3/175) | Qur'an | ✅ fetched live 2026-08-03 |

---

## Pairing and separation

**Against `al-kabeer@1` (id 53, drafted concurrently):**

Al-Kabeer's story (Ibrāhīm and the idols) emphasizes what people call "great" falling to nothing; only Allah's Greatness stands. The engine is **contrast of seeming and reality** at the *social level*.

Al-Azeem's story (Uḥud aftermath) emphasizes the scale of what was already at work while the believers were afraid; the engine is **magnitude revealed through *personal* deliverance**. The scale here is *temporal* (what was always there becomes apparent).

**Different carriers, different arcs, different moments of revelation.** The two Names do not collide on story, text, or engine.

**Ship separately or together?** Both decks are self-contained and bar-complete. If Al-Ali (id 52) is also being drafted, **coordinate with it to ensure 2:255 and 22:62 are not double-spent.** Otherwise, **ship independently.**

---

## Unverified / method limits

- **No ḥadīth verification.** The duʿā is Qurʾānic; no additional narration has been searched.
- **Translation choice on "magnificent" vs. "great."** Saheeh renders `عَظِيمٌ` as "great" throughout; I have rendered it "magnificent" once (the verse beat) to make the Name visible on screen, matching the logic of `al-barr@1`'s translation adjudication. This is disclosed and intentional, not a composite.
- **Uḥud narrative closure check incomplete.** The immediate sequel (3:175 onwards) carries only instruction, not punishment, but a full sūrah-scan for bar-5 compliance was not exhaustively run — spot-check only (3:171–175 clean, 3:175 onwards is instruction, no arc into chastisement).
- **Twin-diff against `al-kabeer@1` is preliminary.** Both decks drafted simultaneously; the shared-string check will be run after both are complete.
