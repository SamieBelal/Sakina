# Name-story decks — plan of record

**Status:** PLAN OF RECORD. Split out of the journaling plan on 2026-08-02 at the founder's direction, because this is a **content track with no engineering dependency on anything**.
**Reviewer for all deck content:** the founder, matching the precedent of the seven approved decks of 2026-07-25/26.
**Parent:** [`2026-08-02-journaling-and-name-mastery-plan.md`](./2026-08-02-journaling-and-name-mastery-plan.md) — where this work started, and where the pack surface that will later consume these decks still lives.

---

## 1. Why this is its own plan

**A deck is not pack content. It is daily-loop content, today.**

`discoverName()` calls `deckForName()` (`daily_loop_provider.dart:1410`), and when an approved deck exists for the revealed Name it **short-circuits the AI reflection entirely** — `startDeeper()` becomes a pure state flip and the authored beats *are* the reveal (`:1410-1412`). So a transcribed deck ships value into the nightly muhasabah the moment it lands, with no packs, no journaling waves and no flag.

That has three consequences worth stating plainly:

1. **Nothing here blocks or is blocked by the journaling waves.** It never was; it ran in parallel from the start.
2. **Decks pay for themselves before packs exist.** Every deck replaces an AI round-trip with authored, reviewed, offline content on the app's most-used surface — which is also the only reveal path that cannot fail on an OpenAI outage.
3. **The pack surface is a second consumer, not the reason for the work.** If packs were cancelled tomorrow, this plan would be unaffected.

## 2. Scale and the long pole

**14 of 99 Names have decks.** Batch 1 (five drafts, mercy/forgiveness) is founder-approved pending transcription; batch 2 (hardship register) is drafting.

The long pole is **content and review**, not engineering — and the review is a human's, so it does not parallelise the way drafting does. Plan around the reviewer, not the drafter.

---

**Scale the existing pipeline; do not invent one.** Protocol: `docs/superpowers/specs/2026-07-25-name-stories-deck-format.md`. Precedent: the seven approved drafts in `docs/superpowers/content/decks/`. Gate: `test/content/name_stories_ship_gate_test.dart` (a bad deck is a **build failure**).

**Decks ship in app releases, batched.** `name_stories_service.dart:14` — *"Asset-only by design: there is no `name_stories` table."* Moving decks to `PublicCatalogKeys` would take them out from behind the build-time ship gate, on the highest-risk content in the product. Not without a server-side equivalent of that gate first.

## 3. The pilot — five decks, then stop
Run five end-to-end and have the founder sign them before committing to 85. If the packets are wrong, five is a cheap way to find out.

## 4. The per-deck pipeline
1. **Draft agent** — finds candidate stories from tiered sources, proposes 2–3, selects the most affecting, writes the deck in the approved beat format with a `Claim | Source | Grading | Status` table.
2. **Mechanical verification — not judgement.** Every scripture claim resolves to a live fetch of the exact canonical URL (quran.com / sunnah.com) and matches by text. **No match → automatic fail.** This is the safeguard; an agent's opinion is not.
3. **Adversarial blind review** — a second agent told to *refute*, not shown the prior verdict.
4. **Review packet** → founder signs.
5. Transcribe verbatim into `assets/content/name_stories.json`; CI ship gate enforces structure and safety.

## 5. Binding source rules
- **Agents retrieve and cite; they never compose scripture.** Standing `CLAUDE.md` rule.
- **Two LLMs agreeing is not verification** — it is the same prior twice. Fabricated hadith with plausible isnād and a plausible Bukhari number is a known model failure, and an LLM reviewer will often accept one.
- **Tier the sources.** Qur'an and canonical collections are authorities for *text*. Yaqeen and similar are authorities for *framing only* — never the citation for a hadith; cite the collection.
- **Grading is a required column.** Ṣaḥīḥ/ḥasan only for anything presented as prophetic narration.
- `./scripts/check_no_fake_strings.sh` before any release carrying new decks.

## 6. What the pilot proved (2026-08-02)

**The pipeline works, and the adversarial step is the load-bearing part.** Five decks drafted; blind adversarial verification returned: 1 reject, 3 fix-then-sign, 1 sign.

**The good news is the thing we most feared did not happen.** Scripture authenticity was clean across all five — every āyah and ḥadīth real, correctly numbered, correctly attributed to collection *and* narrator, correctly graded, quoted verbatim. No fabrication. Even the two grade claims most likely to be an LLM over-claim (Ibn Mājah 3850 "ṣaḥīḥ (Darussalam)", Tirmidhī 3540 "ḥasan (Darussalam)") checked out against the archived pages. **Fetch-first-write-second holds.**

**The bad news, and the reason the adversarial step is mandatory rather than optional: the drafter's own ✅ marks contained two demonstrably false claims.**
- It flagged catalog id 51's duʿā to the founder as "one word away from a narrated supplication", claiming no provenance and asking for a migration decision. **Abū Dāwūd 1516 (ṣaḥīḥ) is that exact wording** — id 11 carries the Tirmidhī 3434 route, id 51 carries the Abū Dāwūd route. Both are narrated. The correct action was the opposite of what was proposed.
- It recorded a ✅ for "letter-for-letter identical to quran.com `text_imlaei`" on 18:10 when the strings differ (`مِن لَّدُنكَ` vs `مِنْ لَدُنْكَ`; immaterial religiously, but the check did not pass).

Neither error is dangerous on its own. The pattern is: **a founder signing against a ✅ table is signing against claims that are sometimes wrong.** Hence — an independent verifier who does not read the drafter's packet is a hard requirement, not a nicety.

**Three process rules earned by the pilot:**
1. **Start each batch from a story inventory of every already-shipped deck.** The expensive step is not drafting, it is collision-checking. The pilot's own collision check caught `ar-rahman@1` and missed `ash-shafi@1`, which already tells the same Ayyūb story from the same two āyāt with the same takeaway — and already contains "You are the Most Merciful of the merciful", i.e. Ar-Raḥīm's own hook.
2. **Quoted translations are part of the theological surface.** `al-kareem@1` pasted a published English of Bukhārī 1145 verbatim and correctly — but that English interpolates "to us" (absent from `إِلَى السَّمَاءِ الدُّنْيَا`) and renders `تَعَالَى` as "the Superior" rather than "the Exalted", flattening the one word that negates spatiality. A deck can adjudicate a contested attribute *by choice of translation* while believing it has adjudicated nothing. **Re-render contested passages from the Arabic; do not paste a published translation unchecked.**
3. **`renderedDuaSources` does not forbid unpinned sources.** A deck citing a duʿā source not in that map will not fail CI, so the citation can be silently dropped later — the exact regression the map exists to prevent. Add every citing deck to it at transcription time, and consider making the gate reject unpinned citations.

**Known limits of the verification, recorded because the founder signs against it:** ḥadīth checking is not independent of sunnah.com *as a corpus* — sunnah.com 403s automated fetching, so both the drafter and the verifier used Wayback archives of the exact URLs (and a mirror), all deriving from the same digitisation. No printed edition or Arabic-primary database (Shamela, Dorar) was consulted, and **no isnād was audited** — published grade lines were accepted.

## 7. The two checks the pilot invented — apply both to every deck

These are the pilot's real output — worth more than the five decks themselves, because they are what the remaining ~85 reuse.

#### The five bars (generalised from Al-Ḥalīm's three attempts)

Al-Ḥalīm failed twice and each failure produced a rule that caught the next one. Stated generally, a story may only teach a Name if:

1. **The thing the Name does is demonstrated in the cited text, in Allah's words** — not asserted by the deck's own prose, and not carried by a trailing epithet.
2. **The distinguishing quality is shown, not stated.** Rev 1 died here: its climax verses used `ʿ-f-w`, so it demonstrated *pardon* while claiming to teach *forbearance*.
3. **It does not collapse into a sibling Name.** Check the Arabic roots of every quotation against the Names already shipped and the Names in the same batch. `ʿ-f-w`, `gh-f-r`, `r-ḥ-m` are dense and overlap constantly.
4. **The Name's own root ideally appears in the source text** — but not at the cost of bar 3. Al-Ḥalīm gave this up deliberately: no āyah exists that carries `ḥalīm` in-text, demonstrates forbearance in its own passage, *and* avoids both sibling roots. Recording the sweep that proves it is what makes the trade legitimate.
5. **The arc must not terminate in punishment just outside the excerpt** — see the successor sweep below. This is what killed rev 2, and it killed it via a rule the deck had itself written down and then not applied to its own selection.

#### The successor sweep (mandatory per quotation)

For **every** Qur'anic quotation, fetch the neighbouring āyāt and answer three questions in order:

1. Does the successor (n+1) **contradict** what the beat asserts?
2. Does it **complete a thought** the excerpt leaves misleadingly open?
3. Does the excerpt **stop short of the passage's own ending** in a way that changes its meaning?

Also fetch **n−1** wherever the quotation opens mid-sentence. A reliable tell: if Abdel Haleem renders the opening word lower-case, the āyah grammatically continues the previous one.

Mechanics worth keeping: **a 404 from `verses/by_key/{s}:{n+1}` is the sūrah-final signal** — that is how 35:45 was proven to have no successor at all, which is the strongest possible form of bar 5. And scan the neighbours for sibling-root adjacency: a Name one āyah away from your verse beat is one tap from the citation even when it never reaches a screen.

**The sweep is not optional and not merit-based.** Its first run found that `al-afuw@1` — the deck the pipeline called its cleanest — has 42:26 ending on *"the disbelievers will have a severe punishment"*, structurally the same shape that disqualified Al-Ḥalīm rev 2. It is not blocking there, because it contradicts no beat. But a batch cannot enforce a rule against one deck and leave it unexamined on another.

#### One schema fact that bar 3 depends on

`story` and `verse` beats carry `arabic: ""` in **all 14 shipped decks** — only `name_intro` and `dua` beats render Arabic. So a sibling root inside a story quotation's *Arabic* never reaches a screen, while one in a `name_intro` or duʿā always does. Bar 3 should be judged against what renders, and the check must be run over the Arabic strings that actually ship.

## 8. Batches
Five at a time, adversarially reviewed, founder-signed. ~85 decks remain (14 of 99 exist). Then the pack question bank under the same discipline.

---

