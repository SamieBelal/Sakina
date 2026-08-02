# One Ship 03 — W3 Daily-Loop Seam (D1-D7)

**Status: DRAFT (plan only — no code written). Five open items for the founder at the end.**
**Date:** 2026-07-29
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first` (W1 merged + applied to prod; W2 Waves A-H built)
**Parents:** distilled doc Phase 1 → **W3** (`2026-07-23-conversion-refactor-changes-and-implementation.md:166-168`, plus the binding divergence log D1-D8) · plan of record `2026-07-03-reel-first-conversion-refactor.md` §V6.8.A5/.A9/.A10/.D4, §V6.8.E · `2026-07-26-one-ship-01-data-layer.md` (Migration B + its binding notes) · `2026-07-26-one-ship-02-onboarding.md` (the reveal spine, the deck pipeline, the queue seed)

W3 is the smallest change that makes the plan screen's promise true on Day 1. The server half already shipped in W1 and is live on prod; the client half of the *data access* shipped early in `NameQueueService`. What is missing is a **decision layer**: which Name today's reveal opens, what it renders, and what happens when the queue can't answer.

**Scope:** the `discoverName()` seam · the D1 deck reveal · the stated-feeling override · empty/exhausted/offline/legacy degradation · the day-boundary collision between the UTC usage cap and the user-local unseal · the dignity floor on the first seven reveals · the second-Name lifecycle events.
**Non-goals:** the feeling-first core-loop rewire (**no longer post-keep — it became W4 on 2026-07-30, master-plan D9; still not W3's job**) · the paywall and free-tier limits (W5) · the funnel super-properties and `reel_hook` (W6, divergence D5) · Phase B notifications reading the queue (post-ship) · the rating gate (see §11, D2).

---

## 1. Verified baseline (every reference read on 2026-07-29)

- **Server, live on prod:** `supabase/migrations/20260727100100_user_name_queue.sql`. `user_name_queue(user_id, position 1-7, name_id → collectible_names, unsealed_at)`, PK `(user_id, position)`, unique `(user_id, name_id)`, RLS **select-only** — no write policies, deliberately. `seed_name_queue(int[])` refuses a reseed; `unseal_next_name()` returns `(position, name_id, unsealed_at)`, is idempotent per **user-local day** via `safe_user_tz`, and carries a **20-hour wall-clock floor**. Empty result = exhausted. Grants revoked from `public, anon`.
- **Client data access, already landed:** `lib/services/name_queue_service.dart` — `queue()` (RLS select, position-ordered, empty when unauthenticated), `seedIfEmpty`, `unsealNext()`. It deliberately does **not** go through `SupabaseSyncService.callRpc` (which returns null on failure) and swallows nothing. Its dartdoc says "W3 owns the caller". **Verdict: the read API is sufficient. W3 adds no method to it** — the missing piece is a planner above it, not a client below it (§3).
- **The seam:** `DailyLoopNotifier.discoverName()` at `lib/features/daily/providers/daily_loop_provider.dart:486-559`. Today: `getCardCollection()` → `premiumTierCeiling()` → `pickNextCard(collection, maxTier:)` → `engageCard(card.id, maxTier:)` → state → `_prefetchDeeperReflection()` → `saveCheckinRecord(q1:'discover')` → streak → `check_in_completed{path:'discover'}`.
- **Structure around it that must survive untouched:** `discoverNameWithBypass` / `discoverNameWithFirstBypass` read `state.error` to decide commit-vs-refund, which is why every telemetry and history write inside `discoverName` is wrapped in a bare `catch (_)`; the `_discoverNameOverride` test seam funnels through `_runDiscoverName()`; `saveCheckinRecord` writes `q1:'discover'` with empty q2-q4 (intentional).
- **Card layer:** `pickNextCard` (`card_collection_service.dart:1819`) picks undiscovered-at-random → lowest tier → gold (premium) → duplicate. `engageCard(cardId, {maxTier})` (`:2021`) already engages **a specific card id**, which is exactly the shape the queue needs. Its tier logic is deterministic: first discovery = **Bronze**, re-encounter = `currentTier + 1` up to `maxTier` (`premiumTierCeiling()` = 4 premium / 3 free). `engageCard` also owns the `card_revealed` / `tier_up` / `collection_completed` emissions and the Supabase upsert.
- **Reveal machinery available for reuse:** `buildBeatScreensFromDeck(NameStoryDeck)` → `List<BeatScreen>`, consumed by `BeatRevealFlow(screens: ...)` (`beat_reveal_flow.dart:31-35`) — the deck path added in W2-A3. `NameStoriesService.deckForName(int)` / `comfortPair()` read the bundled `assets/content/name_stories.json`; a deck whose `review_verdict != 'good'` is dropped at parse. `CardRevealOverlay` + `revealSpecFor(CardTier)` render the card; W2 wrapped that as `pushOnboardingCardReveal`.
- **Muḥāsabah host:** `muhasabah_screen.dart` fires `discoverName()` once from an `initState` post-frame callback (`:90-96`), pushes `CardRevealOverlay` from a `ref.listen` rising edge on a fresh `cardEngageResult.tierChanged` (`:134-149`), and renders `BeatRevealFlow` for `DailyLoopStep.deeper` inside `SacredCanvasThreshold`. `_buildBeatFlow` currently passes `response:` only.
- **Deeper reflection:** `_deeperContextText` (`:1000`) already builds its context from `state.engagedCard` and `_startDeeperReflectionRequest` passes `forceName:` — so a queue-chosen Name flows into the AI path with **no change**.
- **Entry gating:** the 1/day free cap is consumed at the **CTA**, not in the notifier — `progress_screen.dart:989-1010` (`canUse` → `push('/muhasabah')` → `markUsed`) and the same pattern at `muhasabah_screen.dart:621-644`. `GatedFeature.discoverName`, free 1/day, premium 30/day fair-use.
- **Day boundaries:** `daily_usage_service.dart:_today()` is **UTC** (`debugDailyUsageClock`, comment at `:33-44` explains it was moved from local to UTC to match `user_daily_usage.usage_date`); `debugDailyLoopClock` is UTC; the sync payload's `daily_usage` section returns a UTC ±1-day window (`20260727100300_sync_one_ship_profile_keys.sql:167-176`) and the client filters it by `_today()`. The **weekly pool is already user-local** (`consume_weekly_allowance`, W1 Migration C). The unseal is **user-local**. The discover cap is not.
- **Per-user flow value:** `AppSession.onboardingFlow` + `AppSessionNotifier.onboardingFlowReelV1` (`app_session.dart:136-156`), hydrated from `sync_all_user_data` via `user_data_batch_sync_service.dart:183`.
- **Attribution hooks that already exist:** `WidgetDeepLinkHandler` (`lib/core/widget_deep_link.dart`) maps the daily-Name widget tap to `/muhasabah` and emits `widget_opened{target, launch, source}`; `notification_service.dart:514` emits `notification_opened`.
- **Analytics constants present:** `surfaceOnboardingReveal`, `revealDeckCompleted/Abandoned`, `nameQueueSeedFailed`, `reelSourceSelected`, `lanternKindled`, `checkInCompleted`, `reflectBeatAdvanced`, `propSurface/propBeatIndex/propBeatKind/propSource`, `cardRevealed`, `tierUp`. **Grep-confirmed absent: any occurrence of `second_name` anywhere in `lib/`.**
- **Suite:** green on this branch as of the master rebase — 2337 passed / 4 skipped / 0 failed. Master fixed the two long-standing flakies (`purchase_service_premium_started`, the `find_duas` eval) and gated the widget-frame generator behind `REGEN_WIDGET_FRAMES=1`. **A red baseline is therefore now a real signal, not the historical caveat** — but if either of those two reappears, they are pre-existing and never attributed to W3.

## 2. Binding rules carried in

1. **Unsealing a Name NEVER directly grants tokens, XP, or tier** (W1 review F4, restated in the migration header). The queue decides only *which* Name. Every award still flows through `engageCard` → `sync_all_user_data`. §8's tier floor obeys this: the floor is a client-side argument to the existing economy path, not a value the RPC returns.
2. **Never write to economy tables from Flutter.** `user_card_collection` keeps its existing upsert-inside-`engageCard` path; nothing new touches tokens/XP/streaks directly.
3. **Never fabricate Quran verses, hadith, or scholarly content.** Every beat W3 renders comes from the founder-approved `assets/content/name_stories.json` (CI ship-gate) or the verified Supabase catalog. Positions with no approved deck fall back to the existing AI reflection, which selects from the catalog — it never authors scripture.
4. **Arabic and English never share a `Text`.** The deck JSON already keeps `arabic` / `transliteration` / `translation` separate end-to-end; W3 adds no new mixed surface.
5. **Copy firewall.** No countdown UI. No copy attributing waiting or a stance to Allah or a Name — *including* the plan-of-record's own suggested string (§10, OQ-5). Card-tier vocabulary attaches to the card, never the Name. No "sign"/"meant for you" language, and none of W3's surfaces sit near a price.
6. **Riverpod for state, service layer for all Supabase, Freezed for models, widgets under 200 lines, one widget per file.** Services emit analytics through the static `onAnalyticsEvent` hook — never Riverpod.

## 3. Queue-driven Name selection — the seam

The whole change is: **`pickNextCard` stops deciding *who*, and starts being the fallback.** Nothing else about `discoverName` moves.

### 3a. A pure planner, not logic inside the notifier

New `lib/services/name_queue_planner.dart` — a pure function over already-fetched inputs, the idiom the repo already uses for `composeWidgetSyncState` and `resolveReferralNudge`:

```dart
sealed class QueueRevealPlan {}
class QueueUnseal      extends QueueRevealPlan {}            // call unsealNext()
class QueueResume      extends QueueRevealPlan { NameQueueRow row; }
class QueueHold        extends QueueRevealPlan { }            // 20h floor not yet cleared
class QueueExhausted   extends QueueRevealPlan { }
class QueueAbsent      extends QueueRevealPlan { }            // no rows: legacy / reverted user

QueueRevealPlan planQueueReveal({
  required List<NameQueueRow> queue,
  required Set<int> discoveredIds,   // from CardCollectionState
  required DateTime nowUtc,
  required DateTime localToday,      // §7
});
```

Why a planner rather than "just call `unsealNext()`": the RPC's contract is *not* "always advances". Inside the 20-hour floor it returns the **most recently unsealed row**, i.e. yesterday's Name (`20260727100100:...` step 4). A client that treats every non-empty result as "today's new Name" will present the same Name twice on consecutive mornings and call it a reveal. The planner is where that is decided, and being pure it is exhaustively unit-testable without a network or a clock.

Rules, in order:

1. `queue` empty → `QueueAbsent`. Legacy and kill-switch-reverted users land here (§6).
2. A row unsealed on `localToday` whose `name_id` is **not** in `discoveredIds` → `QueueResume(row)`. This is the abandoned-unseal case: the RPC consumed the position, the user closed the app before the card landed, and tomorrow the RPC would silently skip past that Name forever. Resuming re-presents it and self-heals with no server change.
3. `max(unsealedAt) > nowUtc - 20h` → `QueueHold`. Do not call the RPC; it cannot advance.
4. All positions unsealed → `QueueExhausted`.
5. Otherwise → `QueueUnseal`.

### 3b. What `discoverName()` becomes

```
resolve plan  (cached queue rows + collection + local day)
  QueueUnseal   → row = await _nameQueue.unsealNext()      // server is the authority
                  row == null → treat as QueueExhausted (a race: another device drained it)
  QueueResume   → row (no RPC call at all)
  QueueHold / QueueExhausted / QueueAbsent → card = pickNextCard(collection, maxTier:,
                                                exclude: sealedQueueNameIds)
then, identically for both paths:
  card = collectible for row.name_id  (or the picked card)
  engageResult = await engageCard(card.id, maxTier: maxTier,
                                  floorTier: queueDriven ? 2 : 1)     // §8
  state = ...  + revealSource, revealQueuePosition, revealDeck        // §4
  deck == null ? _prefetchDeeperReflection() : (skip the AI call)
  saveCheckinRecord(q1:'discover', ...)   — unchanged
  streak + check_in_completed             — unchanged, gains two props (§9)
```

Three ordering constraints, all load-bearing:

- **The unseal RPC runs before `engageCard`.** Nothing may be granted for a reveal that then fails to resolve a Name.
- **The RPC call is the only new `await` that may throw out of the try.** It stays inside `discoverName`'s existing `try`, so a failure lands in `state.error` and the bypass wrappers refund correctly — the reveal genuinely did not happen. `unsealNext()` deliberately lets errors propagate (its dartdoc), and this is the single place that catches them. §5 covers what the user sees.
- **`_prefetchDeeperReflection()` must NOT fire on a deck-backed reveal.** It is currently unconditional at `:517`. Leaving it would spend an OpenAI call whose result is thrown away and (post-W5) could count against an allowance.

### 3c. Tier still comes from the existing path, and there is no gacha to consult

The plan-of-record's phrasing — "the queue selects the Name, the gacha selects only the tier" — describes a mechanic that **does not exist in the code**. There is no weighted tier roll anywhere; `engageCard` is deterministic (new → Bronze, re-encounter → +1, ceiling from `premiumTierCeiling()`). The W2 review found the same thing and shipped a deterministic Silver instead of "clamping a roll". W3 inherits that: **the queue changes only the Name; the tier ladder is untouched except for the §8 floor.** Recorded as divergence D-W3-1 rather than quietly implemented as if a roll existed.

### 3d. Sealed Names must be excluded from every non-queue pull

`pickNextCard` picks an undiscovered Name **at random from all 99**, which includes the user's own still-sealed positions 3-7. That leaks the queue: a premium reel user has a 30/day fair-use ceiling, so their second, third and fourth reveal of the day are all fallback pulls, and any of them can hand over a Name the plan screen says they will meet on day 5 — after which "unsealing" it is a tier-upgrade of a card they already own and the promise reads as a bug.

Fix: `pickNextCard(collection, {int maxTier = 3, Set<int> exclude = const {}})`, applied to the undiscovered bucket (and only there — the tier-up buckets are legitimate, and a Store-owned queue Name is fine, see §11). `exclude` is empty for every legacy caller, so behaviour is bit-identical for them. The plan-of-record never mentions this; recorded as D-W3-7.

### 3e. State shape

`DailyLoopState` gains four fields, all in-memory (the class is not persisted; only a `daily_loop_$date` prefs flag is):

- `revealSource` — `'queue' | 'gacha'`, drives copy and analytics props.
- `revealQueuePosition` — `int?`, 1-7.
- `revealDeck` — `NameStoryDeck?`, non-null only when the revealed Name has an approved deck (§4).
- `queueSealedRemaining` — `int`, for the home CTA subtitle (§6c) without a second fetch.

A cold restart mid-reveal re-resolves from the cache plus the RPC; because the RPC is idempotent per local day and rule 2 resumes an unmet row, the user comes back to **the same Name**. That property is worth a test of its own.

## 4. The D1 reveal is Name #2's unseal deck

"Same surface" (§V6.8.A5) means the same **beat spine**, not a second copy of the onboarding reveal screen. Concretely, the deck replaces the *deeper reflection* content, not the card reveal:

```
CTA → discoverName() → queue row = position 2
    → CardRevealOverlay (existing ref.listen path, tier per §8)
    → "Go Deeper" → DailyLoopStep.deeper
    → BeatRevealFlow(screens: buildBeatScreensFromDeck(deck), response: null)
    → Ameen → completeDeeper()  (quest hooks, XP, streak — all unchanged)
```

`BeatRevealFlow` already accepts `screens:` instead of `response:`; `muhasabah_screen._buildBeatFlow` currently hardcodes `response:` and gains one branch. `includeVerses`/`includeName` do not apply to the deck path — the deck's own beat list is the final order, and it already carries its verse and dua beats.

Where the content comes from: `NameStoriesService.deckForName(row.name_id)`, resolved in the notifier during `discoverName` (asset read, ~a frame, already cached process-wide after the first call) and parked in `state.revealDeck`. Same service, same asset, same CI ship-gate as onboarding — nothing new is authored and nothing is generated.

**Only positions 1-2 have decks.** The 14 approved decks cover the seven chip pairs. Positions 3-7 come from `lib/features/onboarding/content/aspirations.dart`, whose Names carry approved *anchors* (`name_anchors.json`) but no story decks — the file says so itself. So:

| position | reveal content |
|---|---|
| 1 | met during onboarding (W2), never revealed again by the daily loop |
| 2 (D1) | **pre-authored deck** — no AI call, cannot fail on an OpenAI outage |
| 3-7 | today's AI deeper reflection with `forceName` = the queue's Name (existing path, unchanged) |

The plan-of-record reads as though all seven unseal a deck; they do not. Recorded as D-W3-4. It is also a quiet win: the single most important comeback moment in the funnel is the one reveal that has no network dependency on OpenAI.

The rule in code is content-driven, not position-driven — *deck if one exists for the revealed Name, else the AI reflection* — so the day a founder approves a deck for an aspiration Name, D4 becomes a deck reveal with no code change. It is gated on `revealSource == 'queue'` so a legacy user who happens to gacha into Al-Ghaffar still gets exactly today's experience (§6).

**Analytics surface.** The deck emits the same `reflect_beat_advanced` / `reveal_deck_completed` / `reveal_deck_abandoned` spine, but with a **new surface value `daily_unseal`**, not `onboarding_reveal`. Reusing `onboarding_reveal` would fold D1 completions into the onboarding deck-completion rate, which is a named T0+2wk health metric — the two must stay separable. This is a measurement-hygiene call, not a deviation from "same surface" (which is about the rendering spine); flagged as OQ-3 so it is a decision on the record.

## 5. Empty result, exhausted queue, and failure

**Exhausted (all 7 unsealed).** `QueueExhausted` → ordinary `pickNextCard` with the sealed-exclusion set empty by definition. No copy change, no "you finished your plan" ceremony — the 99-Name arc is the retention spine and the seventh day is not an ending. (A day-7 "Seeker of the Names" title exists in the plan-of-record §V6.8.A8; it is a W2 journey-track concern and W3 does not build it.)

**Empty RPC result on a `QueueUnseal` plan.** Means another device drained the queue between the cached read and the call. Treat as `QueueExhausted` and pull normally — the user sees a reveal, not an error.

**RPC failure (offline, 500, timeout).** `unsealNext()` propagates; `discoverName`'s existing `catch` sets `state.error` and the muḥāsabah screen shows its standard retry. Deliberately **no automatic degrade to an off-queue pull**: the day's cap was already consumed at the CTA (`markUsed` fires there, before the notifier runs), so silently substituting a random Name spends the D1 promise on a transient network blip and there is no second chance that day. A retry re-enters `discoverName` without a second `markUsed`; the RPC is idempotent, so a retry after a *partial* success returns the same row rather than burning a position. Whether a genuinely offline user should be offered "reveal another Name instead" as a secondary action is OQ-4; the recommendation is retry-only.

**`QueueHold` (inside the 20h floor).** The honest case: a user who revealed at 22:00 local and returns at 08:00. The floor is the anti-abuse mechanism W1 deliberately accepted (review F3 — no timezone walk can beat a monotonic server clock), so this is its declared UX cost. Behaviour: an ordinary pull, the queue untouched, the sealed Name still sealed and still promised. The user's queue can therefore drift by a day; it self-corrects the next time their first reveal of a local day lands more than 20h after the previous one. Nothing in the UI names a time, so nothing is falsified. This is also why the planner computes `QueueHold` from the cached rows instead of asking the RPC: asking costs a round trip and gets back a stale row that would have to be discarded anyway.

**Offline with a cached queue.** The cache (§7b) can tell us a sealed row exists but can never authorise an unseal — the server is the timing authority. So offline is the RPC-failure path above, by construction.

## 6. Legacy users, and the kill switch

Every existing user and every kill-switch-reverted user has **zero** queue rows. The requirement is no visible change and no error.

**a. The gate is the presence of rows, not a flag.** `QueueAbsent` → the exact code path that runs today, with an empty `exclude` set. This satisfies the plan's rule (§V6.9: suppression keys on the per-user value, never a global flip) more strongly than reading `onboarding_flow` would: it is local truth, it needs no hydration to have completed, and a reverted user is correct *by construction* rather than by remembering to check a flag. `AppSession.onboardingFlow` is still read, but only for analytics segmentation and copy register — never to decide behaviour.

**b. Unauthenticated / unhydrated.** `NameQueueService.queue()` returns `const []` when there is no user, so a pre-auth or signed-out state is `QueueAbsent` — today's behaviour, no throw.

**c. Copy divergence is narrow and queue-gated.** Two strings change, both only when `queueSealedRemaining > 0`:
- the home muḥāsabah CTA (`progress_screen.dart:1095` `_buildMuhasabahPromptLabel`, currently "Today: {daily question}"),
- the Reflect epilogue offer (§7c).

Legacy users keep the existing daily-question subtitle. Exact strings need a copy pass against the firewall before build; the register is app-artifact-factual ("Second of your seven"), never "{Name} is waiting" (§10, OQ-5).

## 7. The day boundary — the one place W3 has to fix something W1 left open

This is the sharpest finding in the plan and it is not in the spec.

`unseal_next_name` is **user-local-day** + a 20h floor. The `discoverName` 1/day free cap is **UTC** (`daily_usage_service._today()`), deliberately so — it was moved from local to UTC to match `user_daily_usage.usage_date`. W1's decision-0.1.4 audit pinned "muhasabah/rewards/usage are uniform UTC", fixed *quests* by unifying them on UTC, and left the muḥāsabah gap open. §V6.8.A10 names muhasabah explicitly as a One Ship prerequisite. So the gap lands here (D-W3-3).

It is not a corner case. For UTC-7, the UTC day rolls at **17:00 local**. A user who reveals at 20:00 Monday local has consumed "Tuesday UTC", so their Tuesday reveal is blocked until 17:00 Tuesday — while the server would have unsealed their Tuesday Name at 00:00. Today that is an invisible annoyance on a generic daily reveal. After W2 it is a written promise on the plan screen, broken for most of the Americas.

**Recommendation (OQ-1): make the `discover_name` day key user-local, for queue-cohort users only.**

- New `lib/services/user_local_day.dart`: `Future<DateTime> userLocalDay({DateTime Function()? clock})` resolving the user's IANA zone from the same source the server uses (`user_notification_preferences.timezone`, already client-written and now validated by W1 Migration A), cached in scoped prefs, falling back to the device zone and then UTC. One helper, one fallback ladder, injectable clock — mirroring `debugDailyUsageClock`.
- `daily_usage_service._today()` becomes local-dated **only** when the user has queue rows; legacy users keep the UTC key byte-for-byte, so there is no re-key blip for anyone already installed and a kill-switch revert restores the old key exactly.
- Safe because: the client is the writer of `usage_date` for these counters, `_findTodayUsageRow` compares against the same `_today()`, and the sync payload's `daily_usage` section already returns a **UTC ±1-day** window (`20260727100300:175`) which contains any local date. The `reflect`/`built_dua` counters are untouched (they move to the server-side, already-local `consume_weekly_allowance` in W5). The one genuine cross-writer is the bypass counter, owned server-side by `reserve_ai_bypass` in UTC — and W5 removes the bypass for exactly this cohort in the same release, which is why the two changes must not be separated.
- The alternative, if review rejects it: keep UTC and soften the plan-screen and CTA copy so no surface implies a calendar day. That is cheaper and worse — it makes the artifact vaguer to protect an implementation detail.

**b. Queue cache.** New `lib/services/name_queue_cache.dart` — scoped-prefs JSON mirror of the rows, written after every successful `queue()` / `unsealNext()`, read by the planner so the reveal never blocks a frame on a round trip. Same idiom as `starter_name_cache.dart`. The cache is advisory: it may say "sealed row exists" but only the RPC may move a position.

**c. Stated feeling overrides the Name.** The subtlest line in the spec, and it has to be read against the entry points that actually exist. There is no feeling input on the muḥāsabah path — `discoverName` skips questions by design, and the rewire that would change that is explicitly post-keep. The one live stated-feeling surface is **Reflect** (`/reflect` → `reflectWithOpenAI`), which selects its own Name from the catalog, awards no card and does not touch the daily reveal.

So, concretely: **nothing overrides anything, because the two paths were never competing — what W3 owes the user is the "immediately after".** When a queue user completes a Reflect session and their sealed Name for today is still unopened, the Reflect epilogue carries one quiet card that routes to `/muhasabah`. New `lib/features/reflect/widgets/sealed_name_offer.dart` (well under 200 lines, stateless, deck-sourced identity, no clock). It is an offer, never a redirect: the AI's Name is the answer to what the user just said, and the queue's Name is a second thing they were promised. If the user does the daily reveal first, no offer appears.

Copy: the plan-of-record's own suggested line — "The Name we promised you is also waiting" — **trips the copy firewall** (§V6.8.D2: no copy may attribute waiting to a Name; the Phase-A notification review allowed "Today's Name is waiting" precisely because it names no Name, and here the user knows Name #2's identity from Day 0). Re-voice to an app-artifact statement: "Your second Name is still sealed." + "Open it". OQ-5.

## 8. The dignity floor on the first seven reveals

§V6.8.A9 ships "guaranteed Silver+ first reveal with a dignity floor across the first 7 reveals" **in the One Ship**. W2 delivered position 1 only: `OnboardingRevealScreen.awardTier = CardTier.silver`, persisted by `seedStarterCard(tier: silver)` with a clamp. Without W3 doing the same for positions 2-7, D1 lands **Bronze** immediately after D0 landed Silver — a visible downgrade at the single most important comeback moment, and the exact defect §V6.8.A9 exists to fix.

Implementation: `engageCard(cardId, {int maxTier = 3, int floorTier = 1})`. On first discovery the new tier is `max(floorTier, 1)` clamped to `maxTier`; re-encounter and duplicate logic are untouched, and the tier can never step down. `discoverName` passes `floorTier: 2` only when `revealSource == 'queue'`. Every other caller keeps the default and is bit-identical.

Two things to say plainly rather than bury:
- **This is a real economy change.** Seven cards per reel user start at Silver instead of Bronze, i.e. seven fewer Bronze→Silver rungs on the ladder. Nothing else in the economy depends on the count of Bronze cards (tier-ups are not rationed; scrolls come from streak milestones), so the effect is confined to how fast those seven cards reach Gold. It still deserves an explicit founder yes — OQ-2.
- **It does not breach the W1 binding rule.** The tier is chosen client-side and written through `engageCard`'s existing economy path, exactly as today's Bronze is. `unseal_next_name` returns no tier and grants nothing. The W3 review should re-check this specific claim.

## 9. Second-Name lifecycle analytics

Grep confirms `second_name` appears nowhere in `lib/`. Three constants go into `lib/services/analytics_event_names.dart` (append-only — the One Ship's W6 also appends there; conflicts are trivial but the two workstreams should not edit the same block):

| event | fires | props |
|---|---|---|
| `second_name_teased` | Day 0, when `SealedNameTease` is shown (a W2 surface, latched in `OnboardingRevealLatch` alongside `kindledFired`) | `name_id`, `deck_id`, `contract` |
| `second_name_unseal_available` | first time in a local day that the home CTA renders with position 2 still sealed and the plan resolving to `QueueUnseal` | `name_id`, `days_since_tease` |
| `second_name_unsealed` | a successful unseal of **position 2 only** | `source`, `name_id`, `days_since_tease` |

Emit sites: the tease from the onboarding reveal screen's existing static hook; the other two from `DailyLoopNotifier` via `onAnalyticsEvent` (services never touch Riverpod), each wrapped in the same bare `catch (_)` as the surrounding emissions — a throwing hook must not flip a completed reveal into `state.error` and refund a bypass. `second_name_unseal_available` needs a dedup latch keyed on the local date so a user who opens the app four times before revealing emits once.

Positions 3-7 mint **no new event**. They ride the existing `check_in_completed{path:'discover'}`, which gains `name_source:'queue'|'gacha'` and `queue_position`. That keeps one funnel (the house rule) and makes "did the seven-day plan actually run" answerable from the DAU event we already trust. `q1` in `user_checkin_history` stays `'discover'` — a new value would fork the historical funnel and CLAUDE.md documents `'discover'` as the only live value.

**`source` attribution is achievable now.** §V6.8.E warns it may trail the ship, but the hooks already exist: `WidgetDeepLinkHandler` maps the daily-Name widget straight to `/muhasabah` and `notification_service.dart:514` emits `notification_opened`. A small `lib/services/reveal_entry_source.dart` — a process-global `(source, timestamp)` stamp with a ~10-minute TTL, set by those two handlers, read once by the unseal emit and cleared — yields `'widget' | 'push' | 'organic'` honestly. Declared caveat: cold-launch races and a user who wanders before revealing degrade to `'organic'`, so the split is directional. That is strictly better than no attribution, and it is what the guardrail queries need. Recorded as D-W3-5 (the plan-of-record is more pessimistic than the code warrants). If it slips, it slips alone — the two other events do not depend on it.

## 10. Waves

Five independently-committable slices; the tree is green after each. Each wave lists the files it owns.

**Wave 1 — Substrate (no behaviour change).** `lib/services/name_queue_planner.dart` (new, pure) · `lib/services/name_queue_cache.dart` (new) · `lib/services/user_local_day.dart` (new) · `daily_usage_service.dart` (cohort-scoped local key, §7a). Nothing calls the planner yet, so the wave is provably invisible: the only user-visible line is the day key, pinned by both the new local-day test and the existing `daily_usage_service_utc_test.dart` staying green for legacy.
Tests: `test/services/name_queue_planner_test.dart`, `name_queue_cache_test.dart`, `user_local_day_test.dart`, `daily_usage_service_local_day_test.dart`.

**Wave 2 — The seam.** `daily_loop_provider.dart` (`discoverName` consults the planner; the four new state fields) · `card_collection_service.dart` (`exclude` on `pickNextCard`, `floorTier` on `engageCard`).
Tests: `test/features/daily/discover_name_queue_test.dart`, `discover_name_queue_fallback_test.dart`, `queue_reveal_tier_floor_test.dart`, `test/services/card_collection_pick_exclusion_test.dart`.

**Wave 3 — The deck reveal.** `daily_loop_provider.dart` (deck resolution + skipping the AI prefetch) · `muhasabah_screen.dart` (`_buildBeatFlow` screens branch, `daily_unseal` surface).
Tests: `test/features/daily/queue_deck_reveal_test.dart` (+ the existing `muhasabah_canvas_threshold_test.dart` / `muhasabah_screen_source_test.dart` stay green).

**Wave 4 — Surfaces.** `progress_screen.dart` (queue-aware CTA subtitle) · `reflect_screen.dart` + `lib/features/reflect/widgets/sealed_name_offer.dart` (new).
Tests: `test/features/reflect/sealed_name_offer_test.dart`, `test/features/daily/home_cta_queue_label_test.dart`.

**Wave 5 — Analytics + attribution.** `analytics_event_names.dart` · `daily_loop_provider.dart` (three emits) · `onboarding_reveal_screen.dart` / `sealed_name_tease.dart` (the tease emit) · `lib/services/reveal_entry_source.dart` (new) · `widget_deep_link.dart` + `notification_service.dart` (stamp only) · `main.dart` (hook wiring).
Tests: `test/features/daily/second_name_analytics_test.dart`, `test/features/onboarding/second_name_teased_test.dart`, `test/services/reveal_entry_source_test.dart`.

**Parallelism.** Wave 1 must land first — everything reads the planner. After it: **Waves 4 and 5 can run in parallel with each other**, and Wave 4 can start as soon as Wave 2 has landed the state fields it reads. **Waves 2, 3 and 5 cannot be parallelised with each other**: all three edit `daily_loop_provider.dart`, and Wave 3's deck branch depends on Wave 2's `revealSource`. Practically: agent A takes 1 → 2 → 3 serially; agent B takes 4 after 2 lands; agent C takes 5 last (it touches the provider again and needs Wave 3's surface value). `analytics_event_names.dart` is also appended to by the One Ship's W6 — coordinate, or accept a trivial merge.

## 11. Deliberately out of scope

- **The rating gate does NOT move.** Founder call 2026-07-28 (D2) supersedes the plan-of-record's "relocate to post-D1-unseal" (§V6.8.A8). It stays in onboarding after the plan screen. W3 builds no rating surface, and `rating_gate_screen.dart` is not touched. Note for anyone tempted to revisit: despite its name it calls `InAppReview.requestReview()` directly, and iOS rate-limits to 3 prompts/365 days.
- **The feeling-first core-loop rewire** (Begin Muḥāsabah → problem input → `reflectWithOpenAI`). ~~§V6.8.A5 makes it the first item *after* the keep decision.~~ **[AMENDED 2026-07-30 — master-plan D9: it now rides the ship as W4, immediately after this wave. Still out of scope *here*, and W4 depends on this wave's queue seam.]** §7c delivers the "offered immediately after" half only.
- **Phase B notifications** reading `user_name_queue` for today's Name. Templates are frozen (`reel_v1`) until the keep read; the freeze clock started 2026-07-25.
- **`reel_hook` super property and `reel_source_captured`** — divergence D5, W6's problem.
- **The `names_met` people property and the server-side "met" definition** (§V6.8.D4). W6/post-ship. W3 does not introduce a competing definition — it writes the same `user_checkin_history` row it writes today.
- **Store exclusion of sealed queue Names.** A Store purchase can pre-own a queued Name's card; the plan already permits already-owned Names to become tier-upgrade pulls, so the unseal still happens and reads correctly. Excluding them from the Store is a separate product call.
- **`sync_all_user_data` returning queue rows.** The RLS select plus the §7b cache covers W3; adding a sync section is a migration and a prod pre-flight for no gain.
- **Any new migration at all.** W3 is client-only. If a wave finds it needs SQL, that is a signal the design drifted — stop and re-review.

## 12. Test plan

Beyond the per-wave lists above, the following must be true at the end.

**Pure planner** (`name_queue_planner_test.dart`) — table-driven over the five outcomes: empty rows → `QueueAbsent`; unsealed-today-but-unmet → `QueueResume`; last unseal 19h59m ago → `QueueHold`, 20h01m → `QueueUnseal`; all seven unsealed → `QueueExhausted`; and the case that matters most, **unsealed-today-and-already-met → not `QueueResume`** (otherwise a user who completes their reveal and reopens the app gets it again).

**The seam** — a queue user's reveal engages the queue's `name_id` and not `pickNextCard`'s; a legacy user's reveal is byte-identical to today (assert `pickNextCard` is called with an empty `exclude`); a `QueueHold` reveal never calls `unsealNext()`; an RPC throw leaves `state.error` set, no card engaged, and — critically — `discoverNameWithBypass` **cancels** the reservation (the refund path must still work through the new failure mode; extend rather than duplicate `discover_name_dispose_cancel_test.dart`).

**Exclusion** — with positions 3-7 sealed, 200 successive fallback pulls never return a sealed `name_id`; with no queue, the distribution is unchanged.

**Tier floor** — a queue-driven first discovery persists Silver; a legacy first discovery persists Bronze; a re-encounter of an already-Gold queue Name does not step down; a free user's queue reveal never exceeds Gold.

**Deck reveal** — position 2 renders `BeatRevealFlow(screens: ...)` with no `reflectWithOpenAI` call at all (assert the AI seam is untouched); position 4 renders the AI path with `forceName` = the queue's Name; a deck whose `review_verdict != 'good'` is unreachable (already covered by `test/content/name_stories_ship_gate_test.dart`); beat events carry `surface:'daily_unseal'`.

**Day boundary** — pinned literal clocks, not computed ones (a W1 review lesson: a vacuous clock test had to be replaced with literal pins). At `2026-08-04T03:00Z` with tz `America/Los_Angeles`, the local day is 2026-08-03 and the queue user's cap key is `..._2026-08-03` while a legacy user's is `..._2026-08-04`; the sync `daily_usage` ±1-day window still contains the local row.

**Analytics** — `second_name_unsealed` fires exactly once for position 2 and never for 3-7; `second_name_unseal_available` dedups within a local day; `check_in_completed` carries `name_source` and `queue_position`; a throwing analytics hook does not set `state.error` (the bypass-refund invariant).

**Unchanged and must stay green:** `test/services/name_queue_service_test.dart`, `test/features/onboarding/complete_onboarding_queue_seed_test.dart`, `reveal_pair_agreement_test.dart`, `test/features/daily/check_in_completed_analytics_test.dart`, `daily_loop_utc_test.dart`, `daily_usage_service_utc_test.dart`, the gating suite, and `supabase/tests/user_name_queue_test.sql` (untouched — W3 adds no SQL).

**Full suite + `flutter analyze` green.** The baseline is genuinely green on this branch (2337/0), so a failure is a real failure. The two historically flaky tests (`purchase_service_premium_started`, the `find_duas` eval) were fixed on master; if either resurfaces it is pre-existing and not W3's.

**Device pass (rolls into W7):** onboarding → next local day → open the app → D1 deck lands, card is Silver, "Ameen" completes; a reel user who dismisses every offer receives both promised Names with full decks within 48h (the plan's acceptance test); airplane mode at the daily reveal shows retry, not a wrong Name; RTL isolation on the deck beats and the Reflect offer card.

## 13. Review & security notes

- **No new server surface.** W3 adds no migration, no RPC, no RLS policy. The only privileged operation it performs is one call to an already-shipped SECURITY DEFINER function that takes no arguments and derives its user from `auth.uid()`.
- **The accepted residual risk is unchanged, not widened.** W1 review F4 accepted that the client chooses *which* Names at seed time, on the grounds that Name choice carries no economy value and matches the shipped `discoverName` posture. W3 does not touch seeding and adds no new client-asserted input to any economy path. The §8 floor is the one place a tier value is chosen client-side, and it is chosen in the same function that already chooses Bronze today.
- **Re-attack list for the adversarial pass:** (1) can a client force a second unseal in a day by manipulating the device clock or timezone? — the planner is advisory, the RPC re-derives both the local day and the 20h floor server-side; (2) can the `QueueResume` rule be used to re-award a card? — `engageCard` is idempotent on `(user_id, name_id)` and re-encounters clamp/tier-up rather than re-grant; (3) can `floorTier` be reached from a non-queue caller? — every other call site keeps the default, assert it in the test; (4) does the local-day cap key let a user mint an extra daily reveal by changing timezone? — worst case one extra reveal on the day the zone changes, the same bound W1 accepted for the weekly pool ("once-ever init hop"), and `discoverName` grants no tokens.
- **Copy review is a gate, not a nicety.** Every new string goes through the firewall grep that W7 extends: no Name adjacent to "waiting", no clock or countdown anywhere near the unseal, no tier word adjacent to a Name, and none of these surfaces sit near a price.
- **Founder eyeball after Wave 3**, on device, on a real second day (or with the clock seams driven): the D1 deck is the moment the whole ship is selling, and it cannot be judged from a widget test.

## 14. Divergences found while writing this plan

| id | divergence |
|---|---|
| D-W3-1 | "The gacha selects only the tier" describes a mechanic that does not exist — there is no tier roll anywhere; `engageCard` is deterministic. W3 changes only the Name; §8's floor is deterministic too. (Same finding as the W2 review's blocker 1.) |
| D-W3-2 | `unseal_next_name` does **not** always advance: inside the 20h floor it returns the most recently unsealed row. A client that assumes otherwise shows the same Name on two consecutive days. Hence the planner (§3a). |
| D-W3-3 | §V6.8.A10's muḥāsabah local-day gap is **still open**. W1 audited it, fixed quests by unifying on UTC, and left the discover cap UTC while the unseal is user-local. For UTC-7 this blocks the D1 reveal until 17:00 local. W3 has to close it (§7a). |
| D-W3-4 | Queue positions 3-7 have **no approved story decks** — only positions 1-2 do. Only D1 is a deck reveal; D2-D7 are the existing AI reflection with the Name forced. |
| D-W3-5 | `source:'widget'` attribution need not trail the ship (§V6.8.E): `WidgetDeepLinkHandler` and `notification_service.dart:514` already provide the hooks (§9). |
| D-W3-6 | The rating gate stays in onboarding (D2, founder 2026-07-28); "relocate to post-D1-unseal" is superseded and W3 builds no rating surface. |
| D-W3-7 | Sealed queue Names leak through extra same-day fallback pulls (premium 30/day, bypass) — the plan-of-record never specifies an exclusion set. `pickNextCard` needs one (§3d). |
| D-W3-8 | The plan-of-record's own suggested string, "The Name we promised you is also waiting", violates the copy firewall it also sets (§V6.8.D2). Re-voiced in §7c. |

## 15. Open questions (founder / eng)

1. **Local-day cap.** Make the `discover_name` day key user-local for queue-cohort users only (recommended — it is the difference between the D1 promise holding and not holding in the Americas), or keep UTC and soften the plan-screen and CTA copy so no surface implies a calendar day? Note the recommended option is only coherent alongside W5's bypass removal; the two must ship together.
2. **Silver floor on positions 2-7.** §V6.8.A9 requires it in the One Ship and D0-Silver→D1-Bronze is a visible regression without it — but it is a real economy change (seven cards skip the Bronze rung). Confirm.
3. **Analytics surface for the D1 deck:** mint `daily_unseal` (recommended — keeps the onboarding deck-completion health metric clean) or reuse `onboarding_reveal`?
4. **Failed unseal while offline:** retry-only (recommended), or also offer "reveal another Name instead" as a secondary action after a failed retry?
5. **Copy sign-off** on the two queue-gated strings — the home CTA subtitle and the Reflect epilogue offer — in the app-artifact register ("Your second Name is still sealed"), replacing the plan-of-record's firewall-tripping line.
