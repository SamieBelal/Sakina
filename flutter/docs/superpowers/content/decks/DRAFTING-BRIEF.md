# The standing drafting brief

The protocol every 99-Names deck drafter follows. Your task message names your two Names and the hazards specific to them; **everything else is here**, so this file is the thing to read first and to re-read before you write your report.

This is not advice. Every rule below was written after a real failure in this project, and several were written after the same failure twice.

---

## 0 · The one that matters most

**Never fabricate.** No invented quotations, no paraphrase presented as translation, no grade you did not read with your own eyes. **Nineteen fabricated quotations reached this app's production build** — invented divine speech among them. That is why this protocol is as heavy as it is. A beautiful beat that cannot be sourced is worth less than no beat.

---

## 1 · Read these before you draft, in this order

1. **`COLLISION-LEDGER.md`** — ~45 standing rules (§9a–§9bp). **Binding, not background.** The ones you will use every time: §9an (bar 3's three surfaces), §9as (sweep duʿā beats from character one), §9aj (diff your prose against your own table), §9ak (state the measurement, not the adjective), §9av (cross-check enumerations against corpus.quran.com), §9bc (a negative tool result is a claim about the tool, not the world), §9ba (the attachment pattern), §9bh/§9bj (translation rules), §9bk (the bar-1 ladder), §9bi (sweep the asset as it is now), §9bo (what a refusal has to do).
2. **`assets/content/name_stories.json`** — every shipped deck. This is the corpus you must not collide with. **Read the decks nearest your Names in full**, not just their takeaways (§9v).
3. **Two or three recent `2026-08-03-*-DRAFT.md` files** — copy their structure exactly: § sections, beat table, five-bars table, sweep tables, sources table, method-limits section.
4. **`.context/claims/*.md`** — other agents are drafting concurrently and reserve ground here. **Re-read this directory again just before you finalise**; it grows while you work.
5. **`assets/content/collectible_names.json`** — your two ids. Their `dua_arabic` / `dua_transliteration` / `dua_translation` and `name_arabic` / `transliteration` / `meaning` are **LOCKED strings** that render verbatim. You may not change them. You design around them.

**Then claim before drafting.** Write `.context/claims/<id>.md` for each Name reserving your chosen āyāt and narrations **before** you draft, so concurrent agents don't take them.

---

## 2 · The five bars

**1 · The Name is demonstrated in the cited text, in Allah's words.** Not carried by a trailing epithet. A verse ending "…and Allah is the Fashioner" labels; it does not demonstrate.

> **The bar-1 ladder (§9bk), strongest to weakest.** Allah narrating in His own voice **carries** it · Allah quoting Himself inside a narrative **carries** it · `قُلْ`-instructed recitation **does not** · a prophet's reported speech **does not** · any other human speech about Allah **does not**. An argument may move a rung, but it must engage the rung already ruled on rather than step around it.

**2 · Shown, not stated.** A parable or a counterfactual counts as showing — `al-wahid@1` rests on "had there been gods besides Allah, they both would have been ruined." A static declaration of attribute does not.

**3 · No sibling-Name collapse.** Checked on **all three surfaces** (§9an):
   - **(a) Arabic roots** in your quoted text.
   - **(b) Token frequency** of your rendered English against every rendered string in the **current** asset. Compute it; don't eyeball it. **State the deck count you swept as a number** (§9bi) — a stale sweep under-reports silently and always reads as a pass.
   - **(c) "The move"** — what the beat actually *does*. **No mechanical pass reaches this surface.** You must reason about it and write the argument down. This is where the real collisions live.

**4 · The Name's root appears in the quoted text.** Tradeable — but only with a documented full-corpus sweep proving the trade is forced.

**5 · Register and reverence.** This renders at 11pm to someone in distress. No rebuke passages, no Fire/Judgment adjacency, no accusation of the reader. Run a **successor sweep**: fetch n−1 and n+1 for every quotation; a 404 on n+1 means sūrah-final, the strongest bar-5 form. A clean āyah followed by a punishment āyah is a real finding.

---

## 3 · Method

- **Duʿā-first.** Read both locked duʿās before choosing anything else. That beat constrains the whole deck and collides most often — of 24 audited duʿā beats, 19 opened with a vocative and 11 with the Name's own gloss (§9as).
- **Fetch everything live.** `api.quran.com` for Qurʾān (verify `text_uthmani`). sunnah.com for ḥadīth — via Wayback/CDX if it blocks you; captures may be `content-encoding: zstd`, decompress with `zstd -d`. **For a ḥadīth, read the Arabic**, not the published English. `corpus.quran.com` for root counts as an independent cross-check.
- **Translations (§9bh, §9bj).** Quote **one** published translation verbatim. You may re-render from the Arabic **only if you name a published translation that agrees**. You may **never** splice two translations into one string, and you may **never** ship your own unbacked rendering — a missing English field on one site is a fact about that site, not about the world. Truncate with a **visible ellipsis**.
- **Never translation-shop to dodge a collision (§9bl).** Scripture does not yield to a rendered-string collision the way authored prose does. And check the threshold first: **the finding bar is a shared run of ≥3 words.** Two is not a finding.
- **Full-corpus root sweeps** for both Names. Report the count, **check your own arithmetic against your own headline**, and list what you rejected and why.
- **Twin-diff.** Compute the maximum shared word-run between your two decks' rendered strings **programmatically**. ≥3 words is a finding you must fix or justify. The engines must be genuinely different — not one deck twice with a synonym swapped, and not one deck twice with the polarity flipped.
- **Never rule on your own catalogue recommendation.** Report defects in `collectible_names.json`; do not action them. Three of the first three such recommendations in this project were wrong.
- **State the measurement, not the adjective (§9ak).** "Shares a computed 5-gram with `al-kareem@1`'s rendered verse beat", never "feels close to".
- **A negative tool result is a claim about the tool (§9bc).** "sunnah.com returned nothing" ≠ "the ḥadīth does not exist."
- **If a beat disagrees with your own verification table, STOP and report it.** Do not reconcile it silently.

---

## 4 · If you think the Name is not draftable

Read **§9bo** first. Two reasoned refusals have been returned and overturned, both for the same two errors: collapsing the bar-1 carrier and the story into one text, and excluding the best candidate on grounds the corpus doesn't hold.

- **You may split the carrier from the story.** The story shows the Name; a separate verse beat carries the root. `al-wahid@1` (story 21:21–22, root at 16:51) and `al-muhyi@1` (30:48–50 plus 41:39) are the precedents.
- **Adjacency to spent ground is a disclosure, not a disqualification.** `al-malik@1`, `al-muizz@1` and `al-muzill@1` divide **one āyah** (3:26) three ways, each rendering only its own clause. What disqualifies is rendering the neighbour's clause — something you *check*, not something you infer from proximity.
- **A refusal must close each route on evidence.** "I did not try it" is not a closed route; a ranking of candidates is not a closure. **Keep the sweep either way** — it is the most reusable thing you will produce.

---

## 5 · Output

- `docs/superpowers/content/decks/2026-08-03-<slug>-DRAFT.md` per Name
- `.context/claims/<id>.md` per Name

**Beat spine, exactly:** `bridge → name_intro → story ×3 → verse → dua → takeaway`.

`name_intro` and `dua` render the catalogue strings **byte-for-byte**. Verse beats carry **no `arabic` field** and **no surrounding quote marks** on `primary`. Use a visible ellipsis wherever you truncate.

**DO NOT** touch `assets/content/name_stories.json`, `assets/content/collectible_names.json`, or `test/content/name_stories_ship_gate_test.dart`. **DO NOT** commit.

---

## 6 · Reporting — required

**Your final text does not reach the coordinator.** You **must** call `SendMessage` to `main`. Include:

- story choices, citations, and **grades**
- the five-bars result
- **all three bar-3 surfaces with measurements**, and the deck count you swept
- the twin-diff number
- every trade you made and the sweep that forced it
- your **pairing verdict** — ship independently, or must-ship-together with reasoning
- an explicit **unverified / method limits** section

**Do not soften a limit into a claim.** The most valuable line in most of these reports has been the one admitting what the agent could not check.
