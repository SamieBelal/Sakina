# Deck Draft — Al-Hafeez (catalogue id 39) — **R0, awaiting independent blind verification**

> **Id 39 was previously quarantined for fabricated content** — the quarantined report graded a trailing epithet (`وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ`) as *"finite verb `يَحْفَظُهُمْ`, believers as object"* (ledger §9bv). That draft was not reused and not read as precedent.
>
> **One of a four-way watching/protecting family** with shipped `ar-raqeeb@1` and `al-mumin@1`, and unstarted **18 Al-Muhaymin**. The separation argument has to cover all four; it is on the takeaway.

Protocol: [`../../specs/2026-07-25-name-stories-deck-format.md`](../../specs/2026-07-25-name-stories-deck-format.md). Binding rules: [`COLLISION-LEDGER.md`](./COLLISION-LEDGER.md) §9a–§9cg, and [`DRAFTING-BRIEF.md`](./DRAFTING-BRIEF.md). Claim: `.context/claims/39.md`, filed **before drafting**.

All scripture live-fetched 2026-08-03 from `api.quran.com/api/v4` (`text_uthmani` + translation 20, Saheeh International) and `corpus.quran.com`. **Nothing here was recalled, reconstructed or composed.**

---

## Deck `al-hafeez@1` — Al-Hafeez

**Why this deck exists, in one line:** the user holding something they cannot protect — a person, a marriage, a child, a faith — and who has understood that their grip is the only thing between it and loss.

**The reader's position:** **responsible for keeping something they cannot keep.**

**Proposed metadata**

```json
{
  "deck_id": "al-hafeez@1",
  "name_id": 39,
  "transliteration": "Al-Hafeez",
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
> Everything you have loved, you have also at some point failed to hold.

**Beat 2 · name_intro** *(catalogue id 39 `english` verbatim — **`english`, not `meaning`**, §9bz)*:
> الْحَفِيظُ — Al-Hafeez — The Preserver

**Beats 3–5 · story — "The Thing Most Exposed to Loss"** *(Qur'an 15:9)*:
> 3. Allah says: "Indeed, it is We who sent down the message…"
> 4. "…and indeed, We will be its guardian." Not: We will appoint someone to guard it. Not: it will survive if people are careful enough.
> 5. The most exposed thing in the world — a text, held in the memories of a few people, in a desert — and the keeping of it is taken over by the One who sent it down.

**Beat 6 · verse** *(partial quotation — visible ellipsis both sides)*:
> …Allah is Guardian over them… — Qur'an 42:6

**Beat 7 · duʿā** *(catalogue id 39, **byte-for-byte**, asserted programmatically (§9cb))*:
> يَا حَفِيظُ احْفَظْنِي وَاحْفَظْ لِي مَنْ أُحِبُّ
> *Ya Hafeedh, ihfadhni wa-ihfadh li man uhibb*
> "O Preserver, preserve me and preserve those I love."

**Beat 8 · takeaway** *(fixed, **not** personalised — bar 3(c) lands here)*:
> Ar-Raqeeb watches what happens. Al-Hafeez keeps what would otherwise be lost. The promise in that verse is not about your capacity to protect anything. It is about what happens to a thing after your hands come off it.

**Beat 9 · reflection** *(AI-personalisation slot — offline/fallback floor; no `source`, no `arabic`)*:
> Name the one you cannot keep safe. Whose keeping did you think it depended on?

---

## Sources — everything fetched, with what the text actually says

| # | Claim | Source | Status |
|---|---|---|---|
| 1 | *"Indeed, it is We who sent down the message… and indeed, We will be its guardian."* (beats 3–5, **bar-1 and bar-4 carrier**) | `.../15:9` | ✅ `إِنَّا نَحْنُ نَزَّلْنَا ٱلذِّكْرَ وَإِنَّا لَهُۥ لَحَـٰفِظُونَ` — **whole āyah**, split at the `وَ` |
| 2 | *"…Allah is Guardian over them…"* (beat 6) | `.../42:6` | ✅ `ٱللَّهُ حَفِيظٌ عَلَيْهِمْ` — the clause only, ellipsis both sides; `وَمَآ أَنتَ عَلَيْهِم بِوَكِيلٍ` **not rendered** (`al-wakeel@1`'s Name) |
| 3 | Successor sweep n−1: 15:8 | `.../15:8` | ⚠️ carries *"they would not then be reprieved"*. **No punishment, not rendered** |
| 4 | Successor sweep n+1: 15:10 | `.../15:10` | ✅ clean — messengers sent among former peoples |
| 5 | Root sweep | `corpus…?q=HfZ` | ✅ **44 occurrences, 8 forms**, 42 distinct āyāt; `ḥafīẓ` 12× |

---

### The five bars

| # | bar | where it is met | verdict |
|---|---|---|---|
| 1 | Name demonstrated in Allah's own words | **15:9** `إِنَّا نَحْنُ نَزَّلْنَا … وَإِنَّا لَهُۥ لَحَـٰفِظُونَ` — first-person plural twice over, Allah as subject, and the guarding stated as **His own undertaking** | ✅ **PASS** |
| 2 | Shown, not stated | the āyah **names an object, states who sent it, and then transfers the guarding** — a commitment with a subject and a thing, not an attribute | ✅ **PASS** |
| 3 | No sibling-Name collapse | measured below | ✅ **PASS** |
| 4 | Root in the quoted text | `ح-ف-ظ` as `لَحَـٰفِظُونَ` (15:9) and `حَفِيظٌ` (42:6) | ✅ **PASS, no trade** |
| 5 | Register and reverence | ⚠️ n−1 (15:8) mentions that disbelievers *would not then be reprieved*; n+1 (15:10) is clean | ⚠️ **PASS — predecessor not rendered** |

**Bar 5, fetched.** **15:8** — `مَا نُنَزِّلُ ٱلْمَلَـٰٓئِكَةَ إِلَّا بِٱلْحَقِّ وَمَا كَانُوٓا۟ إِذًا مُّنظَرِينَ` — carries a clause about disbelievers not being reprieved. **Not punishment, not the Fire, and not rendered.** **15:10** is clean (messengers sent among former peoples).

**Why the Name-form was not used for bar 1.** `ح-ف-ظ` has **44 occurrences in eight forms**; `حَفِيظ` accounts for **12**, and almost every one is a **trailing epithet** — `وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ` (34:21), `وَمَآ أَنَا۠ عَلَيْكُم بِحَفِيظٍ` (6:104, and that one is the **Prophet** disclaiming the role). **11:57 is Hūd's reported speech.** 15:9's `لَحَـٰفِظُونَ` is the participle *in a first-person divine commitment*, which is why it carries bar 1 where the epithets do not — and it is exactly the distinction the quarantined draft got backwards.

---

### Bar 3(b) — token frequency, **45 decks swept**

Deck count read from `assets/content/name_stories.json` **at draft time** (§9bi): **45**. Every beat against every `primary` and `translation`, max shared word-run by dynamic programming.

**Maximum shared word-run: 4.** the only hit is *"about what happens"* (vs `al-wadud@1`'s bridge), a function-word run. **No finding.**

**Every āyah checked against the shipped asset *and* all 38 pending drafts**, two-sided boundary match: **15:9 free · 42:6 free.** Checked and left: **13:11** (`يَحْفَظُونَهُۥ`) cited in three drafts; **50:4** and **34:21** free but trailing epithets.

### Bar 3(c) — the move

**Al-Hafeez's move is that the keeping does not depend on the keeper you can see.**

15:9 is chosen because of **what it picks as the object**: not a mountain, not a nation — **a text**, at the moment in history when it existed in nothing but the memories of a few people in a desert. **The most losable thing available**, and the guarding of it is announced as Allah's own undertaking, in the first person, twice.

**The four-way family, separated on one axis each:**

| deck | the move |
|---|---|
| `ar-raqeeb@1` (shipped) | **observation** — the watchers went up and gave their report |
| `al-mumin@1` (shipped) | **security given** — the granting of safety |
| **`al-hafeez@1`** | **custody** — the thing does not depend on your grip |
| 18 Al-Muhaymin (unstarted) | oversight/`مُهَيْمِن` — **that drafter owes the diff against this deck** |

**The one to press is `al-mumin@1`**, since *security* and *custody* are close. The split: Al-Mumin gives safety **to a person**; Al-Hafeez keeps **a thing**, whether or not anyone feels safer. This deck never claims the reader will stop being afraid.

---

## Rejected — fetched, evaluated, recorded so nobody re-derives it

| candidate | why not |
|---|---|
| **34:21** `وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ` | trailing epithet — labels, does not demonstrate. **This is the exact text a quarantined Haiku draft mis-parsed as a finite verb** (§9bv) |
| **11:57** `إِنَّ رَبِّى عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ` | **Hūd's reported speech**, bottom rung of §9bk |
| **6:104 · 42:48** `وَمَآ أَنَا۠ عَلَيْكُم بِحَفِيظٍ` | the **Prophet disclaiming** the role. The root, pointed the wrong way |
| **13:11** `لَهُۥ مُعَقِّبَـٰتٌ … يَحْفَظُونَهُۥ مِنْ أَمْرِ ٱللَّهِ` | the guardian-angels āyah — **the subject is the angels**, and it is cited in three pending drafts |
| **2:255's `وَلَا يَـُٔودُهُۥ حِفْظُهُمَا`** | **SPENT** — Āyat al-Kursī, `al-qayyum@1`'s verse beat |
| **50:4** `وَعِندَنَا كِتَـٰبٌ حَفِيظٌ` | free — but the *record* is the ḥafīẓ, not Allah. **Left available** |

---

## Catalogue findings — reported, **NO change recommended**

1. **Nothing.** Id 39's `english` (*"The Preserver"*), `meaning`, `lesson` (*Everything you love is in the hands of Al-Hafeez — even when you cannot hold it*) and duʿā are mutually consistent, and the `lesson` is this deck's engine. **The first Name in this wave with no catalogue finding at all.**

---

## What I could not determine — attack these first

1. **`ح-ف-ظ`'s 44 occurrences were not exhaustively fetched** (§9cc) — the form breakdown was read and the `ḥafīẓ` predications enumerated.
2. **The `al-mumin@1` separation is argued, not measured** (§9cd).
3. **18 Al-Muhaymin is unstarted**, so a quarter of the family argument is made against a deck that does not exist. **That drafter owes the diff, not this one.**
4. **No ḥadīth fetched** (§9bc).

---

## Pairing verdict

**Ships independently.**
