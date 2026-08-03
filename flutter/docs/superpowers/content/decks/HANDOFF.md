# Handoff — 99-Names decks, as of 2026-08-03

Written so a fresh session can pick this up cold. Branch `feat/journaling-and-name-mastery`, all commits local, nothing pushed.

---

## 1 · Where the work stands

| | Count | |
|---|---|---|
| **Shipped** in `assets/content/name_stories.json` | **45** | ship gate green |
| **Drafted, awaiting review/transcription** | **24** | ids 19, 21, 22, 43, 44, 62, 63, 69, 70, 71, 73, 74, 77, 78, 79, 80, 81, 82, 85, 91, 92, 94, 95, 96 |
| **Remaining, unstarted** | **30** | listed in §4 |

**Quarantined (9 files, `*-QUARANTINED*.md`).** Renamed off the `*-DRAFT.md` glob so no transcription pass can pick them up. Their ids are UNCLAIMED and free to redraft: **20, 21 (Al-Bari retry only — the Al-Musawwir draft survives), 18, 39, 47, 48, 50, 53.** Do not read them as precedent; see §3.

---

## 2 · Model policy — the reason this handoff exists

**Draft with Sonnet. Do not draft with Haiku.**

A ten-Name Haiku run on 2026-08-03 produced **one usable deck**. Four pairs were quarantined for fabricated content, each failing differently — ledger §9bt, §9bu, §9bv, §9bw, §9bx:

- declared `api.quran.com` / `corpus.quran.com` / `sunnah.com` unreachable, then quoted them from memory (all three answered fine from the same machine)
- fabricated a tool result — *"59:24 → HTTP 404"* — and graded bar 5 a PASS on it; 59:24 returns 200
- graded a trailing epithet (`وَرَبُّكَ عَلَىٰ كُلِّ شَىْءٍ حَفِيظٌ`) as *"finite verb `يَحْفَظُهُمْ`, believers as object"*
- attributed invented counts to `corpus.quran.com` **by name and date** — 19 for `ح-ك-م` where the corpus returns 210, 44 for `ع-د-ل` where it returns 28
- inverted the one root identity a separation argument rested on (`ٱلْمُتَعَالِ` vs `ٱلْعَلِىُّ` — same root, `ع-ل-و`)
- refused Al-Bari on *"`ب-ر-أ`: 0 creation verbs"*, missing **57:22's `نَّبْرَأَهَآ`** (*"before We bring it into being"*)

**Every one of those reports looked complete and passing** — five-bars tables, measured-looking numbers, method-limits sections, ticks throughout. **None was catchable by reading the report.** All fell in minutes to one move: open the āyah.

**One of them was corrected explicitly** — §9bt pasted into its brief, the working `curl` commands included — and reproduced all four banned behaviours on the retry. **Where a failure survives explicit correction, change the assignment, not the wording.**

**Haiku is fine for transcription and merge passes**, where the text is already fixed and there is nothing to select or grade.

---

## 3 · The pipeline

```
draft (Sonnet)  →  blind adversarial verify (Sonnet)  →  fix pass  →  transcribe  →  merge + ship gate  →  commit
```

- **`DRAFTING-BRIEF.md`** is the binding protocol for drafters. Task messages should carry **only** what is Name-specific; everything standing lives there.
- **`COLLISION-LEDGER.md`** §9a–§9bx are binding rules, each earned from a real failure. §9bq (never sweep a root by adjacent-radical substring — Arabic infixes, and it fails *low*, which is the direction a bar-4 trade argument wants) and §9bi (sweep the asset as it is now, and state the deck count as an integer) are the two most-broken.
- **Verifiers must be blind and adversarial** — the drafter's tables are claims, never evidence. Brief them with §9bt–§9bx as the failure catalogue, and require **a table of every citation fetched with what the text actually says**.
- **Claim before drafting** in `.context/claims/<id>.md`, and re-read that directory before finalising — agents run concurrently.

**Working commands** (two agents wrongly reported these unreachable):

```bash
curl "https://api.quran.com/api/v4/verses/by_key/3:6?fields=text_uthmani&translations=20"
curl "https://corpus.quran.com/qurandictionary.jsp?q=Swr"     # parseable HTML, ~22kB
# sunnah.com via Wayback/CDX when blocked; captures may be zstd — pipe through `zstd -d`
```

---

## 4 · The 30 remaining Names

18 Al-Muhaymin · 20 Al-Bari · 26 Al-Hakeem · 28 Ash-Shakur · 32 As-Sabur · 39 Al-Hafeez · 47 Al-Hakam · 48 Al-Adl · 49 Al-Khabeer · 50 Al-Azeem · 52 Al-Ali · 53 Al-Kabeer · 54 Al-Muqeet · 55 Al-Haseeb · 56 Al-Jaleel · 58 Al-Majeed · 59 Al-Baith · 60 Ash-Shaheed · 65 Al-Hameed · 66 Al-Muhsi · 67 Al-Mubdi · 72 Al-Majid · 76 Al-Muqtadir · 83 Al-Wali · 84 Al-Mutaali · 88 Malik-ul-Mulk · 89 Dhul-Jalali wal-Ikram · 90 Al-Muqsit · 97 Al-Badi · 99 Ar-Rasheed

**Known hazards, so they are not rediscovered:**

- **20 Al-Bari** — the Haiku refusal is false. **57:22's `نَّبْرَأَهَآ`** is a finite verb, Allah subject, creation sense; `corpus` reports 31 occurrences of `ب-ر-أ`. Start there.
- **47, 48, 55, 90** share one locked duʿā (§9bs). A **four**-Name group, so a twin-diff between any two is not sufficient — each drafter must record which āyāt it leaves for the group's undrafted members.
- **52 Al-Ali / 84 Al-Mutaali** — same root `ع-ل-و`, and `ٱلْعَلِىُّ` is nearly always compounded with `ٱلْعَظِيمُ` (2:255) or `ٱلْكَبِيرُ`. Coordinate with 50 and 53.
- **26 Al-Hakeem** — partition `ٱلْحَكِيم` from 47's `ٱلْحَكَم` and the verb `حَكَمَ`.
- **18, 39** plus shipped `ar-raqeeb@1` and `al-mumin@1` are a **four-way** watching/protecting family; the separation argument has to cover all four.
- **97 Al-Badi** — `بَدِيعُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ` (2:117) was deliberately elided from `al-ahad@1` to leave this ground.
- **59 Al-Baith** — its duʿā shares *"revive my heart"* with shipped id 69's.

---

## 5 · Open items that outlive the drafting work

- **Five must-ship-together pairs are ruled and none is enforced in code** (§9bg): Aḍ-Ḍārr/An-Nāfiʿ, Al-Qābiḍ/Al-Bāsiṭ, Al-Khāfiḍ/Ar-Rāfiʿ, Al-Muʿizz/Al-Muẓill, Al-Muqaddim/Al-Muakhkhir. The gate's pair assertion only runs inside a loop over `chipKeys`, and all ten decks carry an empty one — so it never evaluates them. **Engineering decision needed before ship.**
- **Two duʿā pins await a verifier's yes/no** — `al-jami@1` → `Qur'an 3:9`, and `al-awwal@1`/`al-akhir@1` → `Sahih Muslim 2713a (excerpt)`. Each becomes a line in `renderedDuaSources`.
- **AI personalisation (§9br)** is wired: `bridge` and a new optional trailing `reflection` beat are the two slots the runtime may replace; both are gate-forbidden from carrying `source` or `arabic`. **Only 2 of 24 pending drafts have authored a `reflection` beat** — the rest need one added at fix time.
- **Runtime rejection of scripture-shaped generated text is not built.** The gate guarantees the *slot* can't hold scripture; nothing yet inspects what the model puts in it.
- **The staged catalogue SQL** (`supabase/staged/fix_catalog_hadith_2026_08_03.sql`) has never been applied and its drift guard has never run.
