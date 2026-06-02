# Engagement & Economy Analytics Instrumentation (2026-06-01)

Closes the three highest-value **dark** surfaces from the retention audit
(`docs/qa/runs/2026-06-01-full-regression/retention-audit/RETENTION-COVERAGE-SUMMARY.md`,
backlog items #6 Store, #7 Streaks, #10 Collection/gacha, #11 Quest/XP/level):

> "The features shipped in the last 60 commits are well-instrumented. The core
> retention engine is not." — you can't see the monetized Store, the
> collection/gacha progression loop, or the streak/quest/XP economy.

**Scope:** client-side analytics only. **No DB migrations. No server changes.**
All emits are additive and best-effort (`?.call` / `track`), so there is **zero
behavior change for current users** — static hooks default to `null` until wired
in `main.dart`, and a `track()` failure can never break a flow.

## Events

### Store (real-money consumable packs) — `lib/features/store/screens/store_screen.dart`
`StoreScreen` is a `ConsumerStatefulWidget` → direct `ref.read(analyticsProvider).track(...)`. No static hook.
- `store_viewed` — `initState`.
- `pack_selected {pack_id, amount, kind}` — top of `_buyTokensIAP` / `_buyScrollsIAP` (`kind` = `tokens`|`scrolls`).
- `store_purchase_succeeded {pack_id, amount, kind, price, currency}` — after `grantForMostRecentPurchase` (resolved `package.storeProduct` in scope → real price/currency).
- `store_purchase_failed {pack_id, amount, kind, reason}` — `unavailable` (package null), `platform`, `unknown`.
- `store_purchase_cancelled {pack_id, amount, kind}` — `purchaseCancelledError` branch.
- Refactor: thread `productId`/`amount`/`kind` into `_handlePurchaseException` so cancel/fail carry pack identity.
- **Purchase outcomes can't be sim-verified** (StoreKit needs a device → Lane P). `store_viewed`/`pack_selected` are sim-verifiable.

### Collection / cards / gacha — static hook in `lib/services/card_collection_service.dart`
`engageCard()` is the single grant chokepoint (no Riverpod). Add `class CardCollectionAnalytics { static onAnalyticsEvent }`.
- `card_revealed {name_id, tier, is_new:true}` — when `isNew` (first discovery, lands Bronze).
- `tier_up {name_id, from_tier, to_tier}` — when `tierChanged && !isNew` (`from_tier`/`to_tier` are `tierToEnum(currentTier→newTier)`). Note: `engageCard` caps at Gold; Emerald is never produced, so `to_tier` tops out at `gold` today.
- `collection_completed {total}` — fired in the `isNew` branch when `ids.length == currentCollectibleNames().length` (the discovery that completes the 99-name set). Once-only by construction; no dedup flag needed.
- Mutually exclusive per call → clean Mixpanel counts (each `engageCard` emits at most one of card_revealed / tier_up).

### Streak — static hook in `lib/services/streak_service.dart`
Add `class StreakAnalytics { static onAnalyticsEvent }`. Emit from the **committed** path (after persist, before the final `return`), so a failed server upsert that early-returns never emits a phantom event.
- `streak_extended {streak_day}` — `markActiveToday()` increment path (the already-active-today early return at L254 never reaches here → no double-fire).
- `streak_freeze_consumed {streak_day}` — same site, gated on `freezeConsumed`.
- `streak_milestone {streak_day}` — inside `checkStreakMilestones()` per newly-crossed threshold (7/14/30/60/90/180/365).

### XP / Level / Quest — `lib/widgets/app_shell.dart` (has `ref`)
- `xp_awarded {amount, source, new_total}` — every `XpGranted` on `EconomyEvents.stream` (drop the existing `leveledUp` guard; keep overlay logic intact).
- `level_up {from_level, to_level}` — when `event.leveledUp` (`to = newState.level`, `from = to - rewards.levelsGained`).
- `quest_completed {quest_id, quest_type, xp_reward, token_reward}` — the quest-completion toast loop (`quest_type: standard`) + the beginner First-Steps toast (`quest_type: beginner`).

## Wiring (`lib/main.dart`, next to the existing GatingService/DailyCapSheet hooks)
```dart
CardCollectionAnalytics.onAnalyticsEvent = (e, p) => analytics.track(e, properties: p);
StreakAnalytics.onAnalyticsEvent = (e, p) => analytics.track(e, properties: p);
```

## Constants
All 14 event names added to `AnalyticsEvents` (`lib/services/analytics_events.dart`); services import the class (hygiene item #14 — no raw strings). Pinned by `analytics_events_test`.

## Tests (TDD)
1. `analytics_events_test` — assert the 14 new constant values.
2. `card_collection_analytics_test` — set the hook, call `engageCard`: new→`card_revealed`, re-engage→`tier_up{bronze→silver}`, completion edge→`collection_completed`.
3. `streak_analytics_test` — set the hook: `markActiveToday` fresh→`streak_extended`; already-active→no emit; `checkStreakMilestones(7)`→`streak_milestone`.
4. `app_shell` widget test — push `XpGranted` (no-level / level-up) → `xp_awarded` (+`level_up`); quest completion → `quest_completed`.
5. Store: constants only (purchase outcomes are device-gated).

## Verification
- `flutter test` + `flutter analyze` green.
- iOS sim + Mixpanel `Run-Query`: reproduce `card_revealed`/`tier_up` (gacha pull), `streak_extended` (check-in), `xp_awarded`/`level_up` (earn XP), `quest_completed`, `store_viewed`/`pack_selected`.
- Lane P (device): `store_purchase_*` outcomes.

## Delivery
One branch `engagement-economy-analytics`, commits separated by surface (store / collection / streak-economy / wiring+tests). Client-only, no migration ledger impact.
