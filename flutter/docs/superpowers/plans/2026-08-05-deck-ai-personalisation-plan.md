# Deck personalisation — plan of record

**Date:** 2026-08-05 · **Status:** reviewed (`/plan-eng-review`), decisions closed
**Depends on:** the 99-deck backfill (§1, done) · **Blocked on:** `1.3.0` reaching production (§2)

---

## 0 · The one sentence

**Nothing is ever generated.** Each deck carries several authored variants of its
two personalisable beats; the app *selects* one. A model, if it is ever involved
at all, returns an identifier — never prose. If selection fails, the default
authored text renders and nothing about the experience changes.

This replaced a free-generation design during review. The original relied on a
blocklist (Arabic script, `\d+:\d+`, quote marks, attribution words) to catch
model output that strayed into scripture. Blocklists don't catch paraphrase —
*"Allah has said He is with those who are patient"* passes every rule — and this
project has already shipped 19 fabricated quotations to production once.
Selection makes the property structural instead of probabilistic, and it is what
`CLAUDE.md` already mandates: *"The AI selects from existing entries only."*

---

## 1 · What exists today (verified 2026-08-05)

```
docs/…/decks/*-DRAFT.md ──transcribe.py──▶ assets/content/name_stories.json
                                                      │
                                            ship gate (compile-time)
                                                      │
                                                   bundle
                                                      │
              NameStoriesService (parse once, cache for process life,
                                  drop review_verdict != 'good')
                                                      │
                        buildBeatScreensFromDeck  (pure, synchronous)
                                                      │
                                              BeatRevealFlow
```

**Decks stay an asset. They do not move to the database.** The ship gate is a
compile-time test over the asset and is the entire wall between unverified
scripture and a screen. A DB row goes around that wall. The asset also keeps the
onboarding reveal working before the user has an account.

**Spine:** `bridge → name_intro → story ×3 → verse → dua → takeaway → [reflection]`

Only `bridge` and `reflection` are personalisable, and the gate forbids both from
carrying `source` or `arabic`.

**Coverage after the 2026-08-05 backfill:**

| | bridge | reflection |
|---|---|---|
| shipped 45 | 45 | 37 authored + **8 deliberately excluded** |
| staged 54 | 54 | 54 |
| **total** | **99 / 99** | **91 / 99** |

The 8 exclusions (`ar-rahman`, `as-salam`, `al-jabbar`, `al-ghaffar`, `ar-razzaq`,
`al-wadud`, `al-khafid`, `al-baseer`) close on a **pair-synergy handoff** passing
the reader to Name₂. The gate requires `reflection` to be the last beat, so one
there would sit between "here comes Al-Lateef" and Al-Lateef. **They get one
personalisable slot, not two — correct, not a gap** (D1).

**Three call sites** consume decks: `muhasabah_screen.dart:507`,
`onboarding_reveal_screen.dart:218`, and the cold-restart resume in
`daily_loop_provider.dart:2962`.

---

## 2 · ⚠️ The sequencing blocker — found during review

**The daily question is not in production.** Mixpanel, `check_in_completed`:

| app version | events (30d) | | `problem_category` | events (60d) |
|---|---|---|---|---|
| `1.2.0+5` | **4,596** | | `undefined` | **6,380** |
| `1.3.0+6/+8/+9` | 54 | | `unmatched` | 3 |
| `1.0.0` | 45 | | `anxiety` | 2 |
| | | | `unspoken` | 1 |

98% of traffic is on `1.2.0+5`. Every event carrying a real `problem_category` is
on a `1.3.0` dev build — almost certainly the founder's own device.

**Why this matters more than it looks.** §3 of the original plan asserted the
personalisation input was "already in memory" because the check-in step asks what
is on the user's heart. That is true *in the code* and false *in production*.
Every design considered in review — generation and selection alike — assumes real
users are answering that question.

**Consequence:** the choice between a deterministic selector and an LLM
classifier **cannot be made on evidence until `1.3.0` ships.** See §5, D7.

---

## 3 · The requirement

**Free and premium are identical.** Gating happens upstream at the muḥāsabah entry
(`GatingService`); a user who reached a deck already spent their unit. No gate
call on the selection path — a denial and a failure take the same branch anyway.

**Repeat encounters must differ.** Tier upgrades (Bronze → Emerald) and Name-mastery
packs both re-surface a collected Name.

---

## 4 · Architecture

### 4.1 Storage — `variants` on the beat (D3)

```jsonc
{ "kind": "bridge",
  "primary": "Some nights there is no word for it. There is still a Name.",
  "variants": [ { "id": "anxiety-1", "text": "…" }, … ] }
```

`primary` stays the default and the fallback. Chosen over sibling beats (breaks
the exact-spine assertion and the one-reflection-closes-the-deck rule) and over a
separate `variants.json` (a second asset the gate must cross-check, with a
deck_id drift surface).

⚠️ **Stable IDs, not array positions** — an outside-voice finding, unresolved
(§7). An app update that reorders or deletes a variant makes any persisted index
point at different copy.

### 4.2 The gate (D4) — the most important change here

```
non-personalisable kind ──▶ variants MUST BE EMPTY      (illegal state, fails CI)
bridge / reflection     ──▶ every variant checked for source + arabic
```

The current check is `if (!personalisableKinds.contains(kind)) continue;`
(`name_stories_ship_gate_test.dart:260`) — it `continue`s past every other kind.
Add `variants` to the model and nothing stops Arabic or a citation living in
`verse.variants`. The renderer ignores it today, which makes it *dead unguarded
scripture in a shipped asset*, one renderer change from surfacing. Asserting the
field empty makes the shape unrepresentable rather than merely sanitised — the
same exhaustive-not-whitelist principle `renderedDuaSources` already documents.

### 4.3 Selection

```
ONBOARDING            chip (7-item fixed set) ──▶ variant id      NO NETWORK
DAILY        answer ──▶ matchChipKeyForText() ──▶ problem_category ──▶ variant id
                              (on-device, keyword match, today)
             minus variants already seen for this name_id
```

`daily_loop_provider.dart:1033` already does the mapping:
`problemChipsByKey[matchChipKeyForText(answer)]`. Taxonomy: `anxiety`, `heavy`,
`guilt`, `far_from_allah`, `rizq`, `unseen`, `unspoken`, plus unmatched.

⚠️ It is a **keyword** match (`problem_chips.dart:227`:
`if (normalized.contains(' $keyword ')) return entry.key;`), not semantic. How
often it whiffs is the open question §2 blocks.

**Policy lives in a service, not in the builder.** `buildBeatScreensFromDeck`'s
docstring promises *"nothing is reordered, merged or dropped here"*; rotation,
seen-set exclusion and fallback are policy, and `CLAUDE.md` mandates a service
layer. The builder receives an already-resolved id and stays pure.

**Selection latches at flow entry.** `muhasabah_screen.dart:507` runs inside
`build()`, so live provider state would let the bridge text swap while the user is
reading it.

**`variants.isEmpty → primary`** is the migration path and the main path for
weeks, not an edge case.

---

## 5 · Waves

### Wave 1 — Backfill ✅ DONE 2026-08-05
56 reflection beats authored (0 collisions ≥5 shared words vs the existing 91;
58–144 chars). 19 applied to the staged JSON (54/54). 37 held in
`2026-08-05-REFLECTION-BACKFILL-SHIPPED45.json` for the founder merge.
**Remaining:** merge the 37 with the staged 54; tighten the gate to *exactly one
reflection unless the deck closes on a pair-synergy beat*.

### Wave 2 — Variant content (the long pole)
3–5 bridge variants × 99 decks, 3–5 reflection variants × 91. Authored, not
generated. **No verification wave needed** — these slots are gate-forbidden from
carrying scripture, so none of the five bars apply.

**✅ DONE 2026-08-05 — 778 variants: 505 bridge (99/99 decks) + 273 reflection
(91/91).** Coverage per category: `guilt` 154, `heavy` 133, `far_from_allah` 126,
`rizq` 112, `anxiety` 105, `unseen` 98, `unspoken` 43, `default` 7. Uneven by
design: a category with nothing distinctive to say carries **no** variant and
falls through to `primary`, which the gate now enforces (see below).

Three things the content changed about the design:

1. **`default` is not a copy of `primary`.** The seeded proof batch gave each deck
   a `default` variant byte-identical to `primary`, plus an own-chip variant
   identical to both. That contradicts §4.1's own "`primary` stays the default and
   the fallback", puts `primary` into the rotation pool twice (the selector
   believes it rotated; the reader gets the same sentence again), and creates 99
   new copies of a string that drifts the first time one side is edited — the
   failure this repo has already paid for across the Name catalogue's mirrors. The
   gate now **rejects any variant whose text repeats anything else in the same
   deck**, and `default` was re-defined to the one job it can do that `primary`
   cannot: the *no-category* text, for `unmatched`.

   The rule had to be widened once, by content: the first version was
   beat-scoped, and `al-qahhar@1` promptly shipped one sentence as **both** its
   `guilt` bridge and its `guilt` reflection — the line that opens the flow and
   the line that closes it. A variant competes with everything the reader meets
   in the same sitting, so the set is now deck-wide and seeded with every beat's
   `primary` (so a variant cannot restate the takeaway either). It is
   deliberately **not** applied to primaries against each other: decks
   legitimately repeat there — `al-hameed@1`'s third story beat states the āyah
   clause its verse beat then pins.

2. **Seven decks needed that `default` urgently, and it was a live bug.** The
   chip-pair decks echo the chip label back — *"For the weight you named — a mind
   that won't stop racing"*. Onboarding picks those decks BY chip, so `primary` is
   always true there. Daily picks by `deckForName(queueCard.id)` —
   `daily_loop_provider.dart:1423`, the drawn card, **not** the answer. A daily
   user who wrote something with no keyword hit is currently told they named a
   weight they never named. Affected: `as-salam@1`, `al-jabbar@1`, `al-ghaffar@1`,
   `ar-razzaq@1`, `al-fattah@1`, `al-wadud@1`, `al-baseer@1`. Each now carries a
   neutral `default`. **This does not fix itself until Wave 5 ships a selector** —
   the variants are inert until something reads them.

3. **The Wave 3 gate was over-strict and its mutation test missed it.** The
   Arabic-script rule rejected ﷺ (U+FDFA, inside the presentation-forms block),
   which several `primary` texts already carry by design — so the gate banned from
   a variant exactly what it permits one field over. The RTL-bleed rule two tests
   up had always stripped the three composite honorifics; the variant rule now
   does too. Wave 3's mutation test used real Arabic words and never reached the
   case. The first batch of authored content did, immediately.

### Wave 3 — Gate hardening (do before any variant lands)
D4's two assertions. Ordering matters: land the gate first so the first authored
variant is already covered.

### Wave 4 — Swap seam ✅ DONE 2026-08-05
`selection` param on `buildBeatScreensFromDeck`, null-defaulted, shaped
`Map<String, String>?` (deck beat kind → already-resolved variant id) and read
only inside the `bridge` and `reflection` cases. `NameStoryBeat` now parses
`variants` and exposes `textForVariant(String?)` — a total lookup where null,
unknown and no-variants all answer `primary`. The builder stays pure: it
receives resolved ids and does no mapping, rotation or fallback ladder.

**CRITICAL regression test: PASSED over all 99 decks.** Expected screens are
re-derived independently from the raw JSON rather than compared to a golden — a
golden agrees with any bug the builder learns, and a checked-in fixture would
mirror 99 decks of prose, which is the duplicated-content drift this repo has
already paid for. Corroborated out-of-band by a pre/post dump of every screen of
every deck hashing identically (`d889520…`).

⚠️ **§4.3's "`variants.isEmpty → primary` is the main path for weeks" is already
false.** All 99 bridges and all 91 reflections carry variants, so that branch is
unreachable in shipped content and is exercised only by a synthetic deck. Wave 5
must not assume it will ever be hit.

### Wave 5 — Deterministic selector service
Chip/category → id, seen-set rotation, `SharedPreferences` persistence.
No network, no proxy, no LLM.

### Wave 6 — ⏸ Classifier — DEFERRED, gated on §2 (D7)
Revisit only after `1.3.0` is in production and the real `unmatched` rate is
known. If it is low, the taxonomy is doing the job and this wave never happens.
If high, this wave must *first* solve: anonymous rate-limiting, vendor retention
settings, a user-facing disclosure for sending answer text to OpenAI, and a real
kill switch. **None of those are solved today.**

**Deferring this also defers:** the OpenAI proxy dependency, the anonymous abuse
surface, the privacy disclosure, the classifier eval (D5), and the fallback-rate
alarm. Roughly half the original plan.

---

## 6 · Instrumentation

`deck_variant_selected {source: chip|category|rotation|fallback, variant_id, generation}`

**Instrument `problemCategoryUnmatched` rate from day one** — it is the input to
D7 and it costs nothing to collect.

Alarm at **>35% fallback** (D-original-4), onboarding and daily counted
separately. Under the deterministic selector, fallback should be near zero; a
non-zero rate means the seen-set or the category map is broken.

---

## 7 · Decisions

**Closed in review:**

| | decision |
|---|---|
| D1 | 8 synergy-closers get **bridge only**, no reflection |
| D2 | `al-hakeem@1` duʿā → **Ṣaḥīḥ Muslim 2696**; applied, gate green. Al-Khabeer keeps `yā Laṭīf` (nothing authentic exists) |
| D3 | Variants as a **`variants` field** on the existing beat |
| D4 | Gate asserts variants **empty on non-personalisable kinds**, fully checked on the two that allow them |
| D5 | ~20-case classifier eval @ ≥70% — **moved into Wave 6, deferred with it** |
| D6 | Parse off-isolate via `compute()` — ⚠️ see unresolved |
| D7 | **Build the deterministic selector now; revisit the classifier once `1.3.0` ships** |

**Unresolved — outside-voice findings not ruled on:**

- **Variant identity.** Persisting an array index breaks when an update reorders
  variants. Use `{deck_id, variant_id}`, or discard cache on deck revision change.
- **Paired vs independent selection.** Two `variants[]` arrays, one selection —
  is the bridge/reflection pair chosen together or independently?
- **`compute()` (D6) was decided on a 30–60 ms *estimate*, not a measurement.**
  Outside voice argues benchmark first, and notes the onboarding loader already
  holds 2,200 ms (`onboarding_reveal_screen.dart:46`), which may cover it entirely.
- **Kill switch strength.** `app_config_service.dart:60` is
  `_cacheTtl = Duration(hours: 6)`, and default-on-first-install runs the feature
  when config cannot load. Not an emergency stop. Lower stakes now that the
  onboarding path makes no network call, but the copy still can't be pulled fast.
- **Rotation policy is undefined** for decks with one personalisable beat, fewer
  variants than encounters, re-rolls, and restored sessions.
- **Onboarding is contextual copy, not personalisation.** Every user picking a
  chip gets the same line. Measure it as such; if it can't beat the authored
  default, remove it rather than keep AI-shaped plumbing.

**Also open, outside this plan:** ids **62/63** (`al-qawiyy`/`al-mateen`) share a
duʿā invoking Al-ʿAliyy and Al-ʿAẓīm and neither of them — the same defect as
26/49, already shipped.

---

## 8 · NOT in scope

- **LLM classifier** — deferred to Wave 6, gated on production data (§2).
- **OpenAI Edge Function proxy** — only needed by Wave 6. Note `TODO.md:364`
  specifies it as *auth-gated, validates user JWT*, which **cannot serve a
  pre-auth onboarding surface**; that conflict dissolves while Wave 6 is deferred.
- **Moving decks to the database** — breaks the compile-time gate (§1).
- **Personalising any beat other than bridge/reflection** — the other seven carry
  scripture; the gate exists to keep them fixed.
- **Reflection on the 8 synergy-closers** (D1).
- **62/63 duʿā fix** — same class as D2, but shipped content; separate decision.

## 9 · What already exists

| exists | plan reuses it? |
|---|---|
| `matchChipKeyForText()` → `problem_category` (`daily_loop_provider.dart:1032`) | **Yes — this is what replaced the classifier** |
| `_stripInlineGlosses` / `normalizeReflectDua` (`ai_service.dart:322`) | Moot under selection; would have been a DRY violation under generation |
| `BeatFlowStatus.loading` + `loadingView` | Deliberately unused — no spinner is added |
| `GatingService` | Deliberately bypassed |
| `test/evals/reflect_beat_shape_eval.dart` | Wave 6 extends it rather than inventing a second harness |
| `NameStoriesService` cache | Reused; `compute()` change is internal to it |

## 10 · Parallelisation

| Lane | Steps | Modules |
|---|---|---|
| **A** | Wave 3 (gate) → Wave 2 (variant content) | `test/content/`, `assets/content/` |
| **B** | Wave 4 (swap seam) → Wave 5 (selector service) | `lib/widgets/beat_reveal/`, `lib/services/` |

Lane A is content + test; Lane B is code. They touch disjoint directories and can
run in parallel worktrees. **Wave 3 must land before any Wave 2 content merges** —
otherwise the first variants ship unguarded. Wave 6 waits on §2 regardless.

## 11 · Implementation Tasks

- [ ] **T1 (P1, human: ~20min / CC: ~3min)** — ship gate — assert `variants` empty on non-personalisable kinds, checked on bridge/reflection
  - Surfaced by: Section 2 — `name_stories_ship_gate_test.dart:260` `continue`s past every non-personalisable kind
  - Files: `test/content/name_stories_ship_gate_test.dart`
  - Verify: `flutter test test/content/name_stories_ship_gate_test.dart`
- [x] **T2 (P1, human: ~1h / CC: ~10min)** — beat_reveal — CRITICAL regression test: `selection: null` ≡ today's output
  - Surfaced by: Section 3 REGRESSION RULE — 3 live call sites incl. shipped onboarding
  - Files: `test/widgets/beat_reveal_deck_test.dart`
  - Verify: `flutter test test/widgets/beat_reveal_deck_test.dart`
- [ ] **T3 (P1, human: ~2 weeks / CC: ~3h)** — content — 3–5 variants per personalisable beat
  - Surfaced by: D-scope B — selection needs something to select from
  - Files: `docs/superpowers/content/decks/`, `assets/content/name_stories.json`
  - Verify: ship gate green
- [ ] **T4 (P1, human: ~4h / CC: ~30min)** — selector service — chip/category → variant id + seen-set rotation
  - Surfaced by: Section 2 — policy must not live in the pure builder
  - Files: `lib/services/deck_variant_selector.dart` (new)
  - Verify: new unit test covering all 6 branches in the §3 diagram
- [x] **T5 (P2, human: ~2h / CC: ~15min)** — beat_reveal — `selection` param, latched at flow entry
  - Surfaced by: Section 1 — `muhasabah_screen.dart:507` runs inside `build()`
  - Files: `lib/widgets/beat_reveal/beat_reveal_models.dart`, `lib/features/daily/screens/muhasabah_screen.dart`
  - Verify: widget test asserting no mid-flow text swap
- [ ] **T6 (P2, human: ~30min / CC: ~5min)** — analytics — emit `problemCategoryUnmatched` rate
  - Surfaced by: §2 — this is the input to D7 and costs nothing to collect
  - Files: `lib/services/analytics_event_names.dart`, `lib/features/daily/providers/daily_loop_provider.dart`
  - Verify: event appears in Mixpanel on a `1.3.0` build
- [x] **T7 (P2, human: ~1h / CC: ~10min)** — model — `variants` field + doc-table update
  - Surfaced by: Section 2 P3 — the per-kind field table at `name_story_deck.dart:100-107` goes stale
  - Files: `lib/models/name_story_deck.dart`
  - Verify: `flutter analyze`
- [ ] **T8 (P3, human: ~1h / CC: ~10min)** — NameStoriesService — benchmark parse, then `compute()` if warranted
  - Surfaced by: Section 4 + cross-model tension — D6 was decided on an estimate
  - Files: `lib/services/name_stories_service.dart`
  - Verify: frame timing on a cold start, before/after

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | ISSUES OPEN (PLAN) | 12 issues, 1 critical gap |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |
| Outside Voice | `/codex consult` | Cross-model challenge | 1 | ISSUES FOUND | 11 findings, 5 substantive tensions |

**CODEX:** 11 findings on the amended design. Three load-bearing claims verified
against the codebase before acceptance: `matchChipKeyForText` already maps free
text on-device (`daily_loop_provider.dart:1033`), `app_config` TTL is 6 hours
(`app_config_service.dart:60`), onboarding loader holds 2,200 ms
(`onboarding_reveal_screen.dart:46`). All three correct.

**CROSS-MODEL:** 5 substantive tensions; the outside voice was right on 4 the
review missed — variant identity (never persist an array index), kill-switch
strength (6h TTL is not an emergency stop), prefetch timing (the deck isn't
resolved at answer-submit, so the claimed runway was wrong), and `compute()`
recommended off an estimate rather than a measurement. Prompted the Mixpanel check
that produced §2, the largest finding in the review — which neither reviewer had
found unaided.

**VERDICT:** NOT CLEARED — eng review complete, 6 decisions open and 1 critical
gap. Architecture is agreed (selection over generation, variants on the beat,
gate hardened); the open items are implementation-shape questions, not blockers to
starting Waves 1–5. Wave 6 is blocked on production data, not on this review.

**UNRESOLVED DECISIONS — all six CLOSED by the founder 2026-08-05:**

- **D8 · Variant identity → composite key `deck_id + beat_kind + variant_id`.**
  Never an array index. The two-part `{deck_id, variant_id}` the review proposed
  became **wrong during Wave 2**: bridge and reflection now share the same seven
  category ids, so `al-qahhar@1` has a `guilt` variant on each — two different
  sentences behind one key. A two-part key would mark both seen at once.
- **D9 · Selection is PAIRED.** One category id resolves both beats. Both come
  from a single answer; selecting them independently would be two readings of
  one input, not variety. Variety comes from rotation *across* encounters.
  Uneven coverage is fine — a deck with a `guilt` bridge and no `guilt`
  reflection falls the reflection through to `primary`.
  ⚠️ The Wave 4 seam is deliberately **more general than this** (`Map<String,
  String>?`, beat kind → id) so that revisiting D9 is never a signature change.
  The pairing is enforced in the Wave 5 selector, which is where policy belongs.
- **D10 · `compute()` DROPPED.** Benchmarked rather than estimated a second time
  (827 KB asset, 99 decks, 778 variants): **cold parse median 11.2 ms** (min 6.1,
  max 51 on the JIT-warm-up iteration), **warm lookup 27 µs** — 1000 lookups in
  27 ms. Selection is a map lookup over decks `NameStoriesService` already parses
  once and caches for process life. The original 30–60 ms estimate was for
  *generation*, which this architecture no longer does; spawning an isolate and
  serialising the deck list across it would plausibly cost more than the 11 ms it
  saves. Caveat recorded: measured on the dev VM (JIT), not an AOT device build.
- **D11 · NO kill-switch flag.** `primary` fallback is already the safety net,
  and "off" is byte-identical to what ships today (Wave 4 proves this over all 99
  decks). Blast radius is genuinely small: no network, no LLM, every variant is
  founder-reviewed content that cleared the ship gate, and the gate forbids
  scripture in these two slots — so the worst failure is wrong-but-authored
  English, never a fabricated verse.
  ⚠️ **Consequence, accepted knowingly:** unlike `collectible_names`, the decks
  are **bundle-only** — no `refreshPublicCatalogsFromSupabase` path — so with no
  flag there is *no server-side lever at all*. Changing course means an app
  release. This was put to the founder explicitly and chosen over the recommended
  default-on flag.
- **D12 · Rotation: seen on flow COMPLETION, id latched in flow state, cycle when
  exhausted.** Marking on *entry* would burn a variant the user never read and
  swap the text under anyone who backed out and re-entered. Marking on completion
  makes re-rolls and restored sessions stable for free — they re-resolve to the
  same id because the seen-set has not moved. When every variant for a deck has
  been seen, **clear the set and cycle** rather than freezing on `primary`:
  repetition is unavoidable by then, and cycling is the better repetition.
- **D13 · One `deck_variant_selected` event on both surfaces**, with
  `source: chip | category | rotation | fallback`. Onboarding picks the deck BY
  chip, so its variant is contextual copy rather than a selection decision;
  pooling it into one "personalisation worked" metric lets onboarding volume
  swamp the only signal that means anything. One event segmented by property is
  also the house pattern (see `docs/analytics/`), not parallel event names.
