# Deck Draft — Al-Muqtadir (catalogue id 76) — **R0, awaiting independent blind verification**

**No shared duʿā, no quarantine history.** An independent single. Its nearest neighbour is shipped `al-qadir@1`, from the **same root** `ق-د-ر` — the separation argument is on the takeaway.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/76.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-muqtadir@1` — Al-Muqtadir

**Why this deck exists, in one line:** the user who is currently outmatched — by an illness, an institution, a person, a debt — and has begun to organise their life around that fact.

**The reader's position:** **overpowered.**

**Proposed metadata**

```json
{
  "deck_id": "al-muqtadir@1",
  "name_id": 76,
  "transliteration": "Al-Muqtadir",
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

**Beat 1 · bridge** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Whatever has power over you right now is real. It is not the last word on you.

**Beat 2 · name_intro** *(catalogue id 76 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْمُقْتَدِرُ — Al-Muqtadir — The Omnipotent

**Beats 3–5 · story — "The Last Sentence of the Sūrah"** *(Qur'an 54:54–55)*:
> 3. A sūrah that has spent itself listing destroyed nations ends somewhere nobody expects. "Indeed, the righteous will be among gardens and rivers…"
> 4. "…in a seat of honor near a Sovereign, Perfect in Ability."
> 5. That is the last sentence of the sūrah. Not the power that ended those nations. The power that seats someone.

**Beat 6 · verse** *(partial quotation — visible ellipsis; a second attestation of the Name-form)*:
> …indeed, We are Perfect in Ability. — Qur'an 43:42

**Beat 7 · duʿā** *(catalogue id 76, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا مُقْتَدِرُ أَرِنِي قُدْرَتَكَ فِي أَمْرِي وَاجْعَلْ قُوَّتَكَ حِصْنِي
> *Ya Muqtadir, arini qudrataka fi amri waj'al quwwataka hisni*
> "O Omnipotent, show Your power in my affairs and make Your strength my fortress."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Al-Qadir is that He can. Al-Muqtadir is that He prevails — and the last place the Qur'an sets that word down is not over a ruin. It is beside a seat.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> If the power over you is not the final power, what changes about tonight?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Indeed, the righteous will be among gardens and rivers…"* (beat 3) | `.../54:54` | ✅ `إِنَّ ٱلْمُتَّقِينَ فِى جَنَّـٰتٍ وَنَهَرٍ` — whole āyah |
| 2 | *"…in a seat of honor near a Sovereign, Perfect in Ability."* (beats 4–5, **bar-1 and bar-4 carrier**) | `.../54:55` | ✅ `فِى مَقْعَدِ صِدْقٍ عِندَ مَلِيكٍ مُّقْتَدِرٍۭ` — whole āyah |
| 3 | *"…indeed, We are Perfect in Ability."* (beat 6) | `.../43:42` | ✅ `فَإِنَّا عَلَيْهِم مُّقْتَدِرُونَ` — closing clause only, visible ellipsis |
| 4 | Successor sweep n+1: 54:56 | `.../54:56` | ✅ **HTTP 404 — sūrah-final.** Verified by status code, and **independently re-verified as a genuine 404** at R3 (a fabricated 404 is in this project's failure catalogue) |
| 4b | Successor sweep n−1: **54:53** ⚠️ **R3 — R0 never fetched its own stated predecessor**, though the bar-5 argument depends on framing the whole sūrah | `.../54:53` | ✅ `وَكُلُّ صَغِيرٍ وَكَبِيرٍ مُّسْتَطَرٌ` — *"And every small and great [thing] is inscribed."* **Clean, no punishment** — it strengthens the deck rather than threatening it. **Not rendered** |
| 5 | Root sweep on the Name-form | `corpus…?q=qdr` | ✅ **132 occurrences, 11 forms**; **`muqtadir` exactly 4** — 18:45, 43:42, 54:42, 54:55, **all four fetched and dispositioned** |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **54:55** `فِى مَقْعَدِ صِدْقٍ عِندَ مَلِيكٍ مُّقْتَدِرٍۭ` — Allah's own narration, the Name-form applied to Himself as the one beside whom the righteous are seated | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **places a person somewhere** — a seat, a proximity — rather than asserting a capacity. The power is shown by what it is doing at the end of a sūrah about power destroying nations | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ق-د-ر` as `مُّقْتَدِرٍ` (54:55) and `مُّقْتَدِرُونَ` (43:42) — **the Name's own form in both rendered texts** | ✅ **PASS, no trade** |
| 5 | Register and reverence | ✅ **the strongest available form** — 54:54 is *gardens and rivers*, and **54:56 returns HTTP 404: sūrah-final** | ✅ **PASS** |

**Bar 5 is as good as this project's sweep can report.** **54:54** — `إِنَّ ٱلْمُتَّقِينَ فِى جَنَّـٰتٍ وَنَهَرٍ` — is the immediate predecessor and it is Paradise. **54:56 returns HTTP 404**, verified by status code: **54:55 closes Sūrat al-Qamar.**

**That placement is the whole argument for this deck.** Sūrat al-Qamar is a catalogue of annihilated peoples — ʿĀd, Thamūd, the people of Lūṭ, Firʿawn — each episode punctuated by `فَكَيْفَ كَانَ عَذَابِى وَنُذُرِ`. **None of that is rendered.** What is rendered is where the sūrah *stops*: the Name `مُّقْتَدِر` appears in the final clause, and its object is a seat of honour rather than a ruin.

**And the deck says so explicitly on beat 5**, which is the only reason the selection is honest: a deck that quoted 54:55 without acknowledging what the sūrah spends its length doing would be concealing its own bar-5 context.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is a function-word run. An earlier revision measured **5** — *"over you tonight is"* against `al-haqq@1`'s bridge — and beat 1 was rewritten.

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **54:54 free · 54:55 free · 43:42 free.** Checked and left: **18:45** (`وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ مُّقْتَدِرًا`) free but a trailing epithet on the withering-vegetation parable; **54:42** free.

### Bar 3(c) — the move

**Al-Muqtadir's move is that the power which overwhelms is not the power that has the last word — demonstrated by where the Qurʾān puts the word.**

**Against `al-qadir@1` (shipped), same root:** Al-Qadir is **capacity** — He *can*. `مُقْتَدِر` is form VIII, and the added sense is **prevailing**, power that carries through against resistance. The reader's problem is not that Allah lacks ability; it is that something else currently has the upper hand. **This Name answers the second thing.**

**Against `al-qawiyy@1` and `al-mateen@1` (both drafted):** strength and firmness are properties. **This is a property in use, at a specific moment, with an outcome attached** — and the outcome, in the one place the sūrah puts it, is somebody being seated rather than something being flattened.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **18:45** `وَكَانَ ٱللَّهُ عَلَىٰ كُلِّ شَىْءٍ مُّقْتَدِرًا` | the Name-form and free — but a **trailing epithet** on the parable of vegetation turning to dry remnants. It labels, and its register is desolation. **Left available** |
| **54:42** `فَأَخَذْنَـٰهُمْ أَخْذَ عَزِيزٍ مُّقْتَدِرٍ` | the Name-form **inside the seizure of Firʿawn's people**. Bar 5, absolutely |
| **The rest of Sūrat al-Qamar** | a catalogue of destroyed nations. **Not rendered**; disclosed on beat 5 |
| **The 132 `ق-د-ر` occurrences generally** | overwhelmingly `qadara`/`qaddara` (decreeing, measuring) — **`al-qadir@1`'s and `al-muqaddim@1`'s ground**. The Name-form `مُقْتَدِر` is only **4** occurrences: 18:45, 43:42, 54:42, 54:55 |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing.** Id 76's `english` (*"The Omnipotent"*), `meaning`, `lesson` (*Al-Muqtadir has power even over the things that overpower you*) and duʿā are consistent, and the `lesson` is this deck's engine almost verbatim.

---

## What I could not determine — attack these first

1. **The `مُقْتَدِر` sweep is complete — 4 occurrences, all four fetched and dispositioned.** The wider `ق-د-ر` root (132 occurrences) was not, and belongs to `al-qadir@1` and `al-muqaddim@1` anyway.
2. **The `al-qadir@1` separation (capacity vs prevailing) is a claim about form VIII's added sense.** It is standard, but it is a grammatical argument and a verifier should test it rather than accept it.
3. **The sūrah's register is the deck's real exposure.** A reader who opens Sūrat al-Qamar lands on annihilation. Disclosed on beat 5 rather than hidden.
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.**
