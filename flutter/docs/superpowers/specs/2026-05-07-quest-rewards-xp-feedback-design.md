# Quest rewards & XP visual feedback — design

Status: draft, awaiting user review
Owner: Ibrahim
Date: 2026-05-07

## Problem

Quest rewards land server-side (Supabase RPC) but the UI does not move at the moment they're awarded. As a result the user perceives that "quests aren't rewarding stuff" even though `user_tokens`, `user_xp`, and `tier_up_scrolls` columns are all correct on next mount. There is also no XP-gain visual at all, and the level-up celebration only fires from the muhasabah flow — quest XP that crosses a level boundary silently rolls past without celebration.

DB verification for `yoyoyo@gmail.com` (`cdbc2545-…465c`) on 2026-05-07: balance=252, total_xp=390, tier_up_scrolls=36. Updated_at on `user_xp` and `user_tokens` matches the timestamp of the last quest completion (`daily_3_2026-05-07` at 11:23:50Z). Backend is correct; the gap is presentational.

## Root causes

### R1. Quest reward path bypasses Riverpod providers

`QuestsNotifier.completeQuest` (`lib/features/quests/providers/quests_provider.dart:878`) calls the bare service-level functions:

- `earnTokens(quest.tokenReward)` (`token_service.dart:84`)
- `awardXp(quest.xpReward)` (`xp_service.dart:365`)
- `earnTierUpScrolls(quest.scrollReward)` (`tier_up_scroll_service.dart:110`)

Each of these updates the scoped SharedPreferences cache and the relevant Supabase RPC, then returns. **None of them notify the corresponding StateNotifier.** Concretely:

- `tokenProvider` (`lib/features/daily/providers/token_provider.dart`) only ever updates its `state` via its own `earn()` / `spend()` / `reload()` methods. The bare `earnTokens` writes the cache underneath the provider but the in-memory `state.balance` stays stale.
- `tierUpScrollProvider` (`lib/features/collection/providers/tier_up_scroll_provider.dart`) subscribes to `ConsumableGrantsService.grants`, but that broadcaster is fired only from IAP code paths (`consumable_grants_service.dart:225`, `:348`). Quest grants don't publish.
- There is no `xpProvider` at all. The Home/Progress screen reads XP via `dailyLoopProvider.xpTotal` / `levelNumber`, which `_handleXpAward` updates only when the muhasabah flow itself awards XP.

### R2. Level-up overlay coupled to muhasabah flow

`muhasabah_screen.dart:67` is the only place that pushes `LevelUpOverlay`, and it listens to `dailyLoopProvider.leveledUp`. That flag is only set inside `DailyLoopNotifier._handleXpAward` (`daily_loop_provider.dart:354`). Quest completions and First Steps grants call the bare `awardXp` and throw away the `XpAwardResult.leveledUp` / `rewards` they get back. So a level boundary crossed by a quest never celebrates.

### R3. No XP-gain visual

The quest completion toast (`quest_completion_toast.dart`) shows "+10 XP +3 Tokens" as static text. There is no XP gain toast/overlay outside the toast text, no number-counter animation on the XP bar, no fill animation on the progress bar. Streak milestones get a dedicated overlay; quest XP gets a 14pt subtitle.

## Approach

Fix the three causes at the **producer** side (quest completion) rather than at every UI consumer, because the producers are few and the consumers are many. Three coordinated changes:

### F1. Single grant broadcaster

Promote `ConsumableGrantsService.grants` from "IAP only" to "every consumable grant in the app." Rename it to a more accurate name (e.g. `EconomyEvents` in a new `lib/services/economy_events.dart`) and broadcast on **every** earn/spend, regardless of source — quests, First Steps, IAP, streak milestones, daily rewards. Existing listeners (`tierUpScrollProvider`) keep working; we add a `tokenProvider` listener and a new `xpProvider` listener.

Rationale: the bug pattern recurs anywhere quests-style grants happen outside the dailyLoopProvider. Centralizing the producer-side notification fixes this class of bug for good. Same shape as how you already handle scrolls today; we extend the pattern instead of inventing a new one.

Event shape:

```dart
sealed class EconomyEvent {}
class TokenGranted extends EconomyEvent { int amount; int newBalance; EconomyEventSource source; }
class XpGranted extends EconomyEvent {
  int amount;
  int newTotal;
  XpState newState;       // level, title, etc.
  bool leveledUp;
  LevelUpRewards? rewards;
  EconomyEventSource source;
}
class ScrollGranted extends EconomyEvent { int amount; int newBalance; EconomyEventSource source; }

enum EconomyEventSource { quest, firstSteps, streak, dailyReward, iap, dev }
```

Wire-up:

- `earnTokens`, `earnTierUpScrolls`, `awardXp` get a new optional `source: EconomyEventSource` parameter, default `dev`. They publish to `EconomyEvents` after the RPC succeeds.
- `QuestsNotifier.completeQuest` and `_markBeginnerComplete` pass `source: quest` / `source: firstSteps`.
- IAP path passes `source: iap` (replaces today's bespoke `_grantsController`).
- Streak milestone path passes `source: streak`.

### F2. New `xpProvider` and listener-based provider refresh

Add `lib/features/progress/providers/xp_provider.dart`:

```dart
class XpNotifier extends StateNotifier<XpState> {
  XpNotifier(): super(...) { _load(); _sub = EconomyEvents.stream.listen(_onEvent); }
  void _onEvent(EconomyEvent e) {
    if (e is XpGranted) state = e.newState;
  }
}
final xpProvider = StateNotifierProvider<XpNotifier, XpState>(...);
```

Update `tokenProvider` to subscribe to `EconomyEvents` for `TokenGranted` (mirrors how `tierUpScrollProvider` already handles `ConsumableGrantEvent`).

The Home screen's progress card and the Quests screen's token pill both switch to reading `xpProvider` / `tokenProvider`. Today they read partly from `dailyLoopProvider` — keep that working but the source of truth becomes the listener-driven providers.

### F3. Decouple level-up overlay from muhasabah flow

Move the level-up overlay trigger out of `muhasabah_screen.dart` and into `app_shell.dart`. The shell already mediates quest toasts and First Steps bundle celebration; level-up is the same kind of cross-cutting UI event. App shell listens to `EconomyEvents` for `XpGranted` events with `leveledUp == true` and pushes `LevelUpOverlay` regardless of which flow caused the level.

Edge case: when a quest completion AND a streak milestone fire in the same tick, preserve the existing ordering — streak milestone first, level-up second. Currently the muhasabah screen handles this with `streakMilestoneReached` early-return; replicate the same gate at the app-shell level.

Drop `dailyLoopProvider.leveledUp` / `levelUpRewards` once the new path is proven, or keep them as legacy for the muhasabah-side fallback. Recommend dropping after one release cycle to avoid double-fire.

### F4. XP gain visual — choose one

The minimum is "the XP bar visibly moves." Three options, in increasing weight:

1. **(recommended) Tween the XP progress bar.** When `xpProvider` state changes, the bar animates from old-fill to new-fill over 600ms ease-out. A small "+15 XP" floats up from the bar (200ms fade-in, slide -8px, fade-out at 1500ms). Sub-300ms haptic on tween start. No new overlay; lives on the dashboard card. **This is the right default — Duolingo-pattern, low chrome, doesn't compete with the quest toast.**
2. **Dedicated XP toast.** A second toast queue alongside the quest toast. Heavier. Skip — the quest toast already names the XP amount; doubling is noise.
3. **Burst overlay (Cal AI-style).** Full-screen sparkle. Skip for routine XP; reserve overlays for level-ups and bundle completions.

Option 1 only.

## Components

```
lib/services/economy_events.dart            (new)  — EconomyEvent + broadcaster
lib/services/xp_service.dart                (mod)  — awardXp publishes XpGranted
lib/services/token_service.dart             (mod)  — earnTokens publishes TokenGranted
lib/services/tier_up_scroll_service.dart    (mod)  — earnTierUpScrolls publishes ScrollGranted
lib/services/consumable_grants_service.dart (mod)  — replace _grantsController with EconomyEvents.publish
lib/features/progress/providers/xp_provider.dart       (new)  — listener-driven XpState provider
lib/features/daily/providers/token_provider.dart       (mod)  — listen to EconomyEvents
lib/features/collection/providers/tier_up_scroll_provider.dart (mod) — switch from ConsumableGrantEvent to EconomyEvents
lib/widgets/app_shell.dart                  (mod)  — listen for level-up events, push LevelUpOverlay
lib/features/daily/screens/muhasabah_screen.dart (mod) — drop level-up listener (or keep guarded)
lib/features/progress/screens/progress_screen.dart (mod) — XP bar reads xpProvider, animates on change
lib/widgets/animated_xp_bar.dart            (new)  — tweened progress bar + floating "+N XP" label
```

## Data flow (after fix)

1. User taps the Collection tab → `onCollectionVisited()` → `completeQuest('daily_2_…')`.
2. `completeQuest` calls `earnTierUpScrolls(0)` (no-op), then sets `pendingCompletions` (toast fires), then `awardXp(10, source: quest)` and `earnTokens(3, source: quest)`.
3. `awardXp` hits the Supabase RPC, gets back `total_xp / token_balance / scroll_balance`, writes the local cache, then publishes `XpGranted(amount: 10, newTotal: 400, leveledUp: true, rewards: …, source: quest)`.
4. `xpProvider` receives the event, updates `state` to the new `XpState`. Home dashboard's `AnimatedXpBar` rebuilds and tweens fill 385→400. Floating "+10 XP" appears for 1.5s.
5. `app_shell` receives the same event, sees `leveledUp == true`, pushes `LevelUpOverlay`.
6. `earnTokens` publishes `TokenGranted(amount: 3, newBalance: 255)`. `tokenProvider` updates. Token pill on Quests/Home/Store rebuilds. Mini "+3" haptic-tap chip on the pill (optional polish — gate this).

## Error handling

- If the RPC silently fails (returns `null`), do **not** publish the event — the cached balance was not advanced. Surface a snackbar: "Couldn't bank your reward. Tap to retry." (deferred — file as a follow-up; today the toast already lies in this case, fix that separately).
- Out-of-order events: the broadcaster is a single-threaded `StreamController.broadcast()`. Listeners see events in publish order. Fine.
- Multiple level-ups in one grant (a big XP bundle): existing `awardXp` already aggregates rewards across crossed levels into one `LevelUpRewards`. The overlay shows the highest title. No change needed.

## Testing

- Unit: `awardXp` + `earnTokens` + `earnTierUpScrolls` publish exactly one event per successful call (none on failure).
- Unit: `tokenProvider` / `xpProvider` / `tierUpScrollProvider` update `state` from received events, drop unrelated event types.
- Widget: `AnimatedXpBar` tweens on state change.
- Widget: `app_shell` pushes `LevelUpOverlay` on `XpGranted{leveledUp: true}`, exactly once per event.
- Widget: streak-milestone-then-level-up in the same tick → milestone first (preserve current ordering).
- Integration / golden: complete a daily quest from the Collection tab; assert token pill rebuilt within one frame after the toast.

## Out of scope

- Server-side dedup for IAP grants (separate ongoing work).
- New XP overlay style for routine gains (rejected — option 1 is enough).
- Refactoring `dailyLoopProvider` to remove its xp/level fields entirely. Defer until F3 has one release cycle of bake-in.
- Onboarding XP bar treatment (no XP is awarded during onboarding).

## Resolved decisions

1. **Drop `dailyLoopProvider.leveledUp` immediately** when F1+F3 land. After F1 every `awardXp` publishes through `EconomyEvents`; `app_shell` handles all overlay triggers uniformly. Keeping a parallel listener invites double-fire and adds dead state. The integration test pinning streak-milestone-before-level-up ordering covers the regression risk.
2. **Verification reset for `yoyoyo@gmail.com`**: targeted reset of `user_quest_progress`, `user_xp`, `user_tokens.balance`, `user_tokens.tier_up_scrolls` only. Keep `user_card_collection`, `user_checkin_history`, `user_streaks`, and First Steps state intact so we can hit a real level boundary by completing one daily quest, not by replaying the whole onboarding. Reset SQL goes in the implementation plan's verification step, not now.
3. **Floating "+N XP" placement**: above the XP bar with a slide-up + fade-out motion (200ms in, hold 1s, 400ms out). The dashboard card has empty space above the bar; the right side is already occupied by the streak / token / scroll pills, and a horizontal slide there would conflict. Duolingo pattern, fits the existing layout.
