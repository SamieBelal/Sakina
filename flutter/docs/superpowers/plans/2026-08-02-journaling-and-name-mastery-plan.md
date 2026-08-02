# Journaling + Name mastery — plan of record

**Status:** PLAN OF RECORD. All product decisions are closed (D1–D7, founder, 2026-08-02). What remains is build-time judgement.
**Date:** 2026-08-02
**Design doc (read first):** [`../specs/2026-08-02-journaling-and-name-mastery-design.md`](../specs/2026-08-02-journaling-and-name-mastery-design.md) — the research, the evidence and the decision rationale live there. This document is only *how and in what order*.
**Reviewer for all deck content:** the founder (D7), matching the precedent set by the seven approved decks of 2026-07-25/26.

**Line numbers are pointers, not contracts.** They are accurate at HEAD `a4e493c` and will drift.

---

## 0. What ships

One release, before T0 (D5). Contents:

| | Ships | Gated by |
|---|---|---|
| The 5-entry save cap | **removed** | nothing |
| Nightly muhasabah persisted as a journal entry | **yes** | nothing |
| Completion screen: thread, time machine, ʿazm | **yes** | dial |
| Journal: muhasabah entries, story format, compose, calendar browse | **yes** | dial |
| In-app resurfacing ("On This Night", recap, answered duʿā) | **yes** | dial |
| Pack surface | **yes, dark** | dial + reviewed content |
| Pack *content* (85 decks + taxonomy) | **when reviewed** | founder sign-off, not the release |
| Push notifications for resurfacing | **NO** | `COPY_VERSION = "reel_v1"` freeze, independent of this plan |

**The load-bearing sequencing fact:** T0 is gated by Waves A–F. It is **not** gated by Wave G (deck content), because the pack surface ships behind a dial and lights up server-side when decks clear review. Do not let content slip the release, and do not let the release date compress the content bar — that pressure is precisely what produces the irreverence failure in design §8.2.

---

## 1. Wave order, dependencies and what may run in parallel

```
A ──▶ B ──┬──▶ C ──┐
          │        ├──▶ E
          └──▶ D ──┘
F  (independent — start any time)
G  (independent content track — start any time, never blocks a wave)
H  (woven into C–F; audited as its own checklist before submission)
I  (last: pre-ship T0 checklist)
```

**Hard serialisation: A → B → C.** All three touch the economy/daily-loop hot path, and `daily_loop_provider.dart` has already been the collision point across W3–W6. Do not parallelise them.

**C ∥ D is safe** — C lives in `lib/features/daily/`, D lives in `lib/features/journal/` + `lib/widgets/beat_reveal/` + `lib/features/streaks/`. No shared file.

**F ∥ everything** — new tables, new screens, no edits to the daily loop.

**G ∥ everything** — content only; touches `docs/superpowers/content/decks/` and `assets/content/name_stories.json`.

---

## Wave A — The cap comes off

**Goal:** stop charging a free user a weekly allowance for output that is then discarded (design §9A).

**Changes**
- `lib/features/reflect/providers/reflect_provider.dart` — delete the `freeJournalLimit` guard in `_saveReflection` (`:884-890`) and the constant (`:877`). `_saveReflection` always saves.
- `lib/features/duas/providers/duas_provider.dart` — same for built duʿās (`:699`, `:707`).
- Remove the now-unreachable journal-limit upsell trigger in `reflect_screen.dart:165-173` and the sibling in `duas_screen.dart:209`. **Verify before deleting** whether `needsUpgrade` / `dismissUpgradePrompt` have any other producer; if not, remove the state field and `UpgradeRequiredSheet` call sites too, otherwise leave the field and only remove the journal-limit producer.

**Tests**
- Invert every existing test asserting the cap. Grep `freeJournalLimit`, `needsUpgrade`, `UpgradeRequiredSheet` across `test/`.
- New: a free non-premium user saves a 6th, 10th and 50th reflection successfully.

**Risk**
- **Copy check, and it resolves favourably:** `app_strings.dart:236-239` already asserts *"the journal is unlimited for everyone"* as the justification for dropping the journal bullet from the paywall. Removing the cap makes that sentence true as written. Confirm no other surface promises a journal limit.

**Done when:** a free `reel_v1` account can accumulate unbounded saved reflections, and no surface offers a journal upgrade.

---

## Wave B — Persist the nightly muhasabah (P0)

**Goal:** the core loop stops leaving no artifact. This is the precondition for C, D, E and the design's §8.5 personalisation.

### B1 — Migration

New migration, timestamped after `20260727100300`:

```sql
alter table public.user_reflections
  add column if not exists source text not null default 'reflect',
  add column if not exists entry_local_day date,
  add column if not exists thread jsonb not null default '[]'::jsonb,
  add column if not exists azm text;

alter table public.user_reflections drop constraint if exists user_reflections_source_check;
alter table public.user_reflections add constraint user_reflections_source_check
  check (source in ('reflect', 'muhasabah'));

-- One muhasabah row per user per local day. Idempotency for retries, and the
-- key the time machine joins on.
create unique index if not exists uniq_muhasabah_per_local_day
  on public.user_reflections (user_id, entry_local_day)
  where source = 'muhasabah';

create index if not exists idx_reflections_user_source_day
  on public.user_reflections (user_id, source, entry_local_day desc);
```

Follow the existing length/shape-cap convention from `20260524164841_user_reflections_length_caps.sql` and `20260714000000_user_reflections_beat_data.sql` — cap `azm`, cap `thread` element count and per-element length. Unbounded user text in a jsonb array is the same class of hole those two migrations exist to close.

**⚠️ `sync_all_user_data()` must be re-emitted as a superset of the latest definition** (`20260727100300_sync_one_ship_profile_keys.sql:47+`, with the noor/equipped/cosmetics unions at `:199/:205/:210`). This has collided once already (`20260726000300` vs `20260727100300`). Add the four new columns to the reflections union; change nothing else.

### B2 — Model + service

- `SavedReflection` (`reflect_provider.dart:106-155`) gains `source`, `entryLocalDay`, `thread`, `azm`; extend `toSupabaseRow` / the row parser / the prefs serialisation together.
- Existing rows read back as `source: 'reflect'` via the column default — no backfill needed.

### B3 — The write

In `daily_loop_provider.dart`, `completeDeeper()` (`:2348-2358`) currently only flips flags. It gains one persistence call building a `SavedReflection` from:
- `user_text` ← the day's answer (`state.checkinAnswers`)
- `name` / `name_arabic` ← `state.checkinName` / `checkinNameArabic`
- `beat_data`, `verses`, `dua_*` ← the deeper `ReflectResponse` already on state
- `entry_local_day` ← `resolveUserLocalDay()`, **not** `saved_at`. The streak, the launch gate and the reward ladder all key on a day boundary; a timestamp will disagree with them near midnight.
- `source` ← `'muhasabah'`

*Implementation detail to confirm at build time: the exact state field holding the prefetched deeper response (`_prefetchDeeperReflection` at `:700` populates it).*

Write through the existing reflect persistence path so one code path owns the table. Failure to persist must **not** fail `completeDeeper()` — the streak, quests and Noor award are already committed by then; a lost row is recoverable, a lost streak is not. Log and move on.

### B4 — Privacy controls (D2, ship in this wave, not later)

Settings gains: **export my journal**, **delete one entry**, **delete all entries**. One plain sentence in the privacy policy covering server-side storage of reflection text. Non-negotiable per D2 — the decision was "store it *with* the controls", not "store it".

**Tests**
- One muhasabah row per local day; a second `completeDeeper()` on the same day is a no-op, not a duplicate and not an overwrite.
- Near-midnight: `entry_local_day` agrees with the streak's day resolution.
- Persistence failure does not break completion.
- The row appears in `sync_all_user_data` output and rehydrates.
- Delete-all removes rows server-side, not just locally.

**Risks**
- Freemium-guard triggers and `cosmetics_guard` both guard `user_profiles` — this migration touches `user_reflections`, so neither should fire, but confirm rather than assume (design §12 R7).
- `pgTAP` coverage for the new constraint + unique index.

**Done when:** every completed muhasabah produces exactly one durable, syncing, re-readable row.

---

## Wave C — The night stops dead-ending (P1)

**Depends on B.** Same file as B — serialise.

### C1 — The thread (the answer to "it won't let me do it again")

New `appendToTonight(String text)` on `DailyLoopNotifier`: appends `{at, text}` to the row's `thread` array for today's entry.

> **The hard architectural line, restated because it is the thing most likely to be got wrong:** an append must **not** call `discoverName()`, must not mark the streak, must not claim the reward ladder, must not unseal the queue, must not engage a card and must not consume an allowance. Those fire exactly once per night, at first submit. **Do not widen the `!state.checkinDone` gate** in `_showsQuestion` (`muhasabah_screen.dart:380-385`) — that gate is the defence against the "phantom second gacha" bug class documented at `daily_loop_provider.dart:85-91`. Add a separate append path that bypasses it.

### C2 — The completion screen

Rework `_buildCompleted` (`muhasabah_screen.dart:948-1120`):
- show what was saved (the words, the Name, the duʿā)
- an "add to tonight" affordance (C1)
- exactly one forward action
- `Seek Another Name` (`:1003-1051`) stays as-is — it is a card re-roll and premium-gated for `reel_v1`; it is not the journaling path and must not be conflated with one.

### C3 — Same-prompt time machine

After completion, reveal the user's own entry from `entry_local_day - 30 / -90 / -365` (nearest available, one only). Cannot be peeked at before completing. Absent for new users — that is correct, it arrives as a surprise on day 31.

### C4 — ʿazm

One short forward-resolve line captured at the end, stored in `azm`, resurfaced as tomorrow night's opening line.

**Tests**
- An append writes no economy event: assert `discoverName` not called, streak unchanged, allowance unchanged, no card engaged.
- Appends after local-day rollover go to the new day, not the old row.
- Time machine picks the nearest available anchor and renders nothing when none exists.
- Existing `test/features/daily/` suite (~52 files) stays green — particularly `muhasabah_question_step_test.dart`, `daily_answer_submit_test.dart`, `off_topic_re_ask_test.dart`.

**Done when:** the day's entry stays open until rollover, and completion resurfaces something.

---

## Wave D — The Journal becomes an archive (P2)

**Depends on B. Runs in parallel with C.**

### D1 — Muhasabah entries appear
Largely free: muhasabah rows land in `user_reflections`, so they hydrate into `reflectProvider.savedReflections` and reach the existing merge at `journal_screen.dart:118-142`. Add `source` to the type chip and the filter tabs.

### D2 — Story-format entries
- New `buildBeatScreensFromReflection(SavedReflection)` — model on `beat_reveal_models.dart:147-212`; `SavedReflection.beat_data` already carries the identical fields.
- `BeatRevealFlow` gains: a `completionLabel` / completion-view prop (the hardcoded "Ameen" pill and 1.1s ceremony at `:503-537`, `:690-729` are wrong for a re-read), and a guard on "Skip to duʿa" when no duʿā beat exists (`duaScreenIndex` currently clamps to 0 and silently jumps backwards).
- One new `BeatKind` for a date/cover card. The `wireName` extension is exhaustive, so the compiler will find every site.
- **Known limit — do not promise past it:** `BeatScreenView` is a closed switch over string slots, not arbitrary widgets. Photos, media and charts are not in scope.
- Paging *between* entries needs the Scaffold hoisted out of `BeatRevealFlow` (`:243`) — 3 lines, 3 call sites. Optional for v1.

### D3 — Compose from the archive
One primary control whose meaning follows the day's state: *start tonight's muhasabah* → *add to tonight* → *free write*. Replaces the absent FAB (`journal_screen.dart:169-198`) and the CTA-less All-tab empty state (`:979-985`).

### D4 — Month of Light becomes the browse surface
Promote `showMonthOfLightSheet` from a read-only sheet reachable only via the streak line to the Journal's browse control. `lit` → open that night; `todayPending` → start tonight. States are already computed (`month_of_light_provider.dart`), and the gentle framing of gaps (*"an open invitation, not a gap"*) is already right.

### D5 — Unbounded lists (surfaced by the Wave A review, 2026-08-02)

Removing the cap removed the only thing that was keeping these lists small. Both are **pre-existing** patterns, neither introduced by Wave A, and both now need an owner:
- `journal_screen.dart` renders every entry in a plain `ListView` with no pagination or windowing.
- The SharedPreferences persistence writes the whole reflection list as **one JSON string**, with no entry-count cap.

A daily journaler produces ~365 entries a year. Add windowing to the list and either a cap or a page-in strategy to the local cache. `sync_all_user_data()` is *not* affected — it does not touch `user_reflections` / `user_built_duas` (they insert per row), so payload growth is not a concern there.

### D6 — Fix the sort bug
`journal_screen.dart:139` stamps `DateTime.now()` on saved related duʿās (which carry no timestamp), pinning them permanently to the top of the All feed.

**Tests:** muhasabah rows render and filter; story flow builds from a legacy null-`beat_data` row via `splitIntoBeats`; skip-to-duʿa guarded; calendar cell routes; sort regression pinned.

---

## Wave E — In-app resurfacing (P3)

**Depends on B and D.**

- **"On This Night"** — a card surfacing `entry_local_day` a month/year ago.
- **Weekly recap** — themes, Names met, one line the user wrote.
- **Answered duʿā** — *"you asked for this four months ago."* Needs a status field on `user_built_duas` (new migration) and a light prompt to mark it.
- **No push.** `send-scheduled-notifications/index.ts:29` freezes `COPY_VERSION` at `reel_v1` until the keep read. In-app only. Do not add a template.

---

## Wave F — The pack surface, shipped dark (P4 engineering)

**Independent of A–E.** Clone the cosmetics stack (~90% reusable in shape) and the discovery-quiz shell.

### F1 — Schema
- `content_pack_catalog` — model on `cosmetic_catalog` (`20260726000000_cosmetics_economy.sql`): id, title, theme, sort, active, availability window, min app version. **No price column. No IAP column.** (D3b: no currency.)
- `content_pack_names` — pack ↔ name_id join, carrying the readiness threshold.
- `content_pack_questions` — the question bank (see F2).
- `user_name_mastery` — the Leitner state: `name_id`, `box`, `last_reviewed_at`, `correct_streak`, `last_result`.
- RLS: catalog public-read; mastery read-own, written only through an RPC. Follow the cosmetics precedent — inventory tables have **no** client write policy.
- Add a `packs` union to `sync_all_user_data` as a superset of whatever B left.

### F2 — The question model (this is where the design lives)
Per design §8.3, a question is **not** one-correct-three-wrong. It is:
- `stem` — a situation, or a Name, or a concept prompt
- `fits` — the Name this pack teaches for this stem
- `also_true[]` — other true Names with a per-Name explanation of *the difference*
- `no_bearing[]` — true Names with no bearing on this stem
- `teaching` — the post-answer explanation, plus the approved verse to display

**No option on screen is ever false about Allah.** Concept/application questions (§8.3, ~20%) are the one category where genuinely wrong options are permitted, because they are claims about human conduct — mark them with a distinct `question_kind`.

Grading: `fits` → advance the box. `also_true` → *"Also true — here's the difference"*, hold the box. `no_bearing` → explain what that Name is for, demote. **No red ✗, no timer, no failure state, no correctness leaderboard.**

### F3 — Gating (D3b)
- **Premium gates access.** `PurchaseService().isPremium()` (`purchase_service.dart:122`). Do **not** add a `GatedFeature` member — this is the cosmetics entitlement model (premium-exclusive, no metering), not the AI-cap model.
- **Collection progress gates readiness inside premium** — a pack opens when enough of its Names are owned.
- **The free taste pack** — "The Names you've met", dynamic, built from the user's own collection. Core situational type + visible mastery. Near-synonym cards, concept layer and full history stay premium.
- **Floor, mandatory:** the onboarding Names plus the first week of reveals must always constitute at least one openable pack, and every locked pack states its own condition in plain words with visible progress.

### F4 — UI
Clone `wardrobe_grid.dart` / `wardrobe_tile.dart` and the two pure resolvers in `wardrobe_screen.dart:34-89`. Clone the discovery-quiz runner (`core/constants/discovery_quiz.dart:10-45` model; paged runner, segmented progress, animated option cards) — it needs a right/less-precise concept and per-pack scoping, which it does not currently have.
**"Report this question" ships in v1**, not v2.

### F5 — Dial
`app_config` key `packs_enabled`, default **false**. Use `hasCachedValue` before reading so a first install does not act on the fallback (`app_config_service.dart:83-88`).

### F6 — Taxonomy
**Does not exist.** Nearest seeds: the 7 problem chips (`problem_chips.dart:85-132`), and three dormant `text[]` columns with zero readers — `names_of_allah.emotions`, `name_teachings.emotional_context`, `name_guidance.call_for`. Anchor the themes in a **citable published classification** (D7 option C) so every grouping carries an attribution and the dispute sits with the source, not with us. Content work, not engineering — Wave G.

---

## Wave G — Deck + question content (parallel track)

**Scale the existing pipeline; do not invent one.** Protocol: `docs/superpowers/specs/2026-07-25-name-stories-deck-format.md`. Precedent: the seven approved drafts in `docs/superpowers/content/decks/`. Gate: `test/content/name_stories_ship_gate_test.dart` (a bad deck is a **build failure**).

**Decks ship in app releases, batched.** `name_stories_service.dart:14` — *"Asset-only by design: there is no `name_stories` table."* Moving decks to `PublicCatalogKeys` would take them out from behind the build-time ship gate, on the highest-risk content in the product. Not without a server-side equivalent of that gate first.

### G0 — Pilot 5 decks, then stop
Run five end-to-end and have the founder sign them before committing to 85. If the packets are wrong, five is a cheap way to find out.

### G1 — Per-deck pipeline
1. **Draft agent** — finds candidate stories from tiered sources, proposes 2–3, selects the most affecting, writes the deck in the approved beat format with a `Claim | Source | Grading | Status` table.
2. **Mechanical verification — not judgement.** Every scripture claim resolves to a live fetch of the exact canonical URL (quran.com / sunnah.com) and matches by text. **No match → automatic fail.** This is the safeguard; an agent's opinion is not.
3. **Adversarial blind review** — a second agent told to *refute*, not shown the prior verdict.
4. **Review packet** → founder signs.
5. Transcribe verbatim into `assets/content/name_stories.json`; CI ship gate enforces structure and safety.

### G2 — Binding source rules
- **Agents retrieve and cite; they never compose scripture.** Standing `CLAUDE.md` rule.
- **Two LLMs agreeing is not verification** — it is the same prior twice. Fabricated hadith with plausible isnād and a plausible Bukhari number is a known model failure, and an LLM reviewer will often accept one.
- **Tier the sources.** Qur'an and canonical collections are authorities for *text*. Yaqeen and similar are authorities for *framing only* — never the citation for a hadith; cite the collection.
- **Grading is a required column.** Ṣaḥīḥ/ḥasan only for anything presented as prophetic narration.
- `./scripts/check_no_fake_strings.sh` before any release carrying new decks.

### G3 — Batches
Five at a time, adversarially reviewed, founder-signed. ~85 decks remain (14 of 99 exist). Then the pack question bank under the same discipline.

---

## Wave H — Instrumentation (woven, audited as a checklist)

- `journal_entry_created` gains `source` (`reflect` | `muhasabah`). **Do not fork the event.**
- `check_in_completed.path` stays `'discover'`. Untouched.
- New pack funnel, **session-aggregated, not per-question**: `pack_opened{pack_id, unlock_state}` → `pack_review_started` → `pack_review_completed{items_seen, items_settled, less_precise_count}`; plus `pack_unlocked{pack_id, names_owned, names_required}`, `mastery_state_changed{name_id, from, to}`, `question_reported{pack_id, question_id}`.
- **Add every new free-text state field name to `freeTextFields` in `test/services/no_free_text_reaches_analytics_test.dart:81`** — currently `['duaTopicsOther', 'intakeNote', 'firstProblemText']`. The `.text` sweep only sees controllers; once free text is on state the guard is blind to it unless named. The thread-append field and any draft field go in the same PR that introduces them.
- Re-verify the durable super-property set against the new callers — it was evicted by its own second caller once (`054e5b5`).
- Extend the T0+24h coverage check to the new events.

---

## Wave I — Pre-ship T0 checklist

Run `TODO.md` buckets 2–4 unchanged. Two that matter more because the ship is bigger:
- **The pre-T0 baseline snapshot is mandatory and unrecoverable.** With this much in one release, the "pre" side is the only clean number left.
- **Screenshots** — onboarding and paywall were rebuilt in W2/W5, and now the Journal changes too.

---

## 2. Migration ordering

Three migrations in this plan touch `sync_all_user_data`: B1 (reflections columns), E (duʿā answered status), F1 (packs union). **Each must re-emit the function as a superset of the previous one.** Author them in wave order and rebase rather than merging them concurrently. The `20260726000300` / `20260727100300` collision is the precedent.

## 3. Dials

| Dial | Default | Covers |
|---|---|---|
| `journaling_v2_enabled` | true | C + D |
| `resurfacing_enabled` | true | E |
| `packs_enabled` | **false** | F (dark until content lands) |

Read through `AppConfigService`, and use `hasCachedValue` before acting on a kill switch at first install.

## 4. Risks carried into the build

1. **The append path re-entering the economy** — the single most likely serious bug. Pin it with a test that asserts no economy write.
2. **`sync_all_user_data` re-emission ordering** — collided once already.
3. **Fabricated hadith surviving an LLM-only review** — mitigated only by mechanical verification (G2).
4. **A premium user opening an empty Packs screen** — mitigated by the F3 floor.
5. **Merge pressure on `daily_loop_provider.dart`** — mitigated by serialising A → B → C.
6. **Free-text reaching analytics through a new state field** — mitigated only by updating the guard list (Wave H).
7. **Content pressure from the release date** — mitigated structurally by shipping F dark.

## 5. Open build-time questions (mine to resolve, not product calls)

- The exact state field carrying the prefetched deeper `ReflectResponse` at `completeDeeper()`.
- Whether `needsUpgrade` survives Wave A or is removed with its last producer.
- Whether `thread` appends belong on the row (proposed) or in a child table — row is simpler and the cap convention already exists; revisit only if entries grow unexpectedly large.
- Whether D2's paging-between-entries is worth the Scaffold hoist in v1.
