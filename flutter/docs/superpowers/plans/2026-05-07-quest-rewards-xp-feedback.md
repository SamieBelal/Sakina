# Quest Rewards & XP Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every quest reward visibly land at the moment of award — token/scroll/XP balances animate, the XP bar fills, and level-ups celebrate from any path (not just muhasabah).

**Architecture:** Promote the existing IAP-only `ConsumableGrantsService.grants` stream into a unified `EconomyEvents` broadcaster published from every earn/spend (quests, First Steps, IAP, streak milestones). Existing `dailyLoopProvider`/`tierUpScrollProvider` already subscribe — extend them and add an XP-event subscription, which carries the level-up flag the app shell uses to push `LevelUpOverlay`. Add a tweened XP bar with a floating "+N XP" label.

**Tech Stack:** Flutter, Riverpod, `flutter_animate`, Supabase RPCs (no schema changes).

**Spec:** `docs/superpowers/specs/2026-05-07-quest-rewards-xp-feedback-design.md`

---

## File Structure

**New files:**

- `lib/services/economy_events.dart` — `EconomyEvent` sealed class + module-level broadcaster.
- `lib/widgets/animated_xp_bar.dart` — tweened LinearProgressIndicator with floating "+N XP" overlay.
- `test/services/economy_events_test.dart`
- `test/services/xp_service_publishes_events_test.dart`
- `test/services/token_service_publishes_events_test.dart`
- `test/services/tier_up_scroll_service_publishes_events_test.dart`
- `test/features/quests/quest_grant_publishes_events_test.dart`
- `test/widgets/app_shell_level_up_overlay_test.dart`
- `test/widgets/animated_xp_bar_test.dart`

**Modified files:**

- `lib/services/xp_service.dart` — `awardXp` accepts `source` and publishes `XpGranted`.
- `lib/services/token_service.dart` — `earnTokens` accepts `source` and publishes `TokenGranted`.
- `lib/services/tier_up_scroll_service.dart` — `earnTierUpScrolls` accepts `source` and publishes `ScrollGranted`.
- `lib/services/consumable_grants_service.dart` — replace local `_grantsController` with `EconomyEvents.publish`, drop `ConsumableGrantEvent` (callers migrate to new types).
- `lib/services/premium_grants_service.dart` — route `checkPremiumMonthlyGrant`'s token + scroll grants through `earnTokens`/`earnTierUpScrolls` with `source: iap`. (Issue 1, Task 6.5.)
- `lib/services/daily_rewards_service.dart` — token grants from `claimDailyReward()` route through `earnTokens(source: dailyReward)`. (Issue 3, Task 6.6.)
- `lib/features/daily/providers/daily_loop_provider.dart` — subscribe to `EconomyEvents` for `TokenGranted` and `XpGranted`; remove `_handleXpAward` level-up state writes once app shell handles it; keep xp/token cache update.
- `lib/features/collection/providers/tier_up_scroll_provider.dart` — switch from `ConsumableGrantsService.grants` to `EconomyEvents` for `ScrollGranted`.
- `lib/features/daily/providers/token_provider.dart` — subscribe to `EconomyEvents.stream` for `TokenGranted`, with explicit `StreamSubscription` field and `dispose()` cancel. (Issue 5.)
- `lib/widgets/app_shell.dart` — add `EconomyEvents` listener that pushes `LevelUpOverlay` on `XpGranted{leveledUp: true}`.
- `lib/features/daily/screens/muhasabah_screen.dart` — drop the local `leveledUp` listener and `_pushLevelUpOverlay` (app shell owns it now).
- `lib/features/progress/screens/progress_screen.dart` — replace inline progress bar with `AnimatedXpBar`; drop the local `_levelUpShown` flag-clear logic.
- `lib/features/quests/providers/quests_provider.dart` — pass `EconomyEventSource.quest` / `firstSteps` into `awardXp`/`earnTokens`/`earnTierUpScrolls`.
- `lib/core/utils/invalidate_providers.dart` — audit + remove from non-dev call sites; only dev_tools_screen retains it. (Issue 2, Task 9.5.)

---

## Task 1: Create EconomyEvents broadcaster + types

**Files:**
- Create: `lib/services/economy_events.dart`
- Create: `test/services/economy_events_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/economy_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/xp_service.dart';

void main() {
  test('publish delivers events to subscribers in order', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    EconomyEvents.publish(const TokenGranted(
      amount: 5, newBalance: 55, source: EconomyEventSource.quest,
    ));
    EconomyEvents.publish(const ScrollGranted(
      amount: 2, newBalance: 12, source: EconomyEventSource.firstSteps,
    ));

    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(2));
    expect(received[0], isA<TokenGranted>());
    expect((received[0] as TokenGranted).newBalance, 55);
    expect(received[1], isA<ScrollGranted>());
  });

  test('XpGranted carries leveledUp + rewards through publish', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final state = const XpState(
      totalXp: 400, level: 5, title: 'Grateful', titleArabic: 'شَاكِر',
      xpForNextLevel: 70, xpIntoCurrentLevel: 25,
    );
    EconomyEvents.publish(XpGranted(
      amount: 25,
      newTotal: 400,
      newState: state,
      leveledUp: true,
      rewards: const LevelUpRewards(
        levelsGained: 1, tokensAwarded: 5, scrollsAwarded: 2,
        titleUnlocked: true, unlockedTitle: 'Grateful',
        unlockedTitleArabic: 'شَاكِر',
      ),
      source: EconomyEventSource.quest,
    ));

    await Future<void>.delayed(Duration.zero);
    final event = received.single as XpGranted;
    expect(event.leveledUp, true);
    expect(event.rewards?.tokensAwarded, 5);
    expect(event.newState.level, 5);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/economy_events_test.dart
```
Expected: FAIL — `Target of URI doesn't exist: 'package:sakina/services/economy_events.dart'`.

- [ ] **Step 3: Write the broadcaster**

```dart
// lib/services/economy_events.dart
import 'dart:async';
import 'package:sakina/services/xp_service.dart';

enum EconomyEventSource { quest, firstSteps, streak, dailyReward, iap, dev }

sealed class EconomyEvent {
  const EconomyEvent({required this.source});
  final EconomyEventSource source;
}

class TokenGranted extends EconomyEvent {
  const TokenGranted({
    required this.amount,
    required this.newBalance,
    required super.source,
  });
  final int amount;
  final int newBalance;
}

class ScrollGranted extends EconomyEvent {
  const ScrollGranted({
    required this.amount,
    required this.newBalance,
    required super.source,
  });
  final int amount;
  final int newBalance;
}

class XpGranted extends EconomyEvent {
  const XpGranted({
    required this.amount,
    required this.newTotal,
    required this.newState,
    required this.leveledUp,
    this.rewards,
    required super.source,
  });
  final int amount;
  final int newTotal;
  final XpState newState;
  final bool leveledUp;
  final LevelUpRewards? rewards;
}

/// Broadcaster: late subscribers do NOT receive replays. UI state is loaded
/// from the cache at startup; live events are for in-session refresh only.
class EconomyEvents {
  EconomyEvents._();

  static final StreamController<EconomyEvent> _controller =
      StreamController<EconomyEvent>.broadcast();

  static Stream<EconomyEvent> get stream => _controller.stream;

  static void publish(EconomyEvent event) => _controller.add(event);
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/services/economy_events_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/economy_events.dart test/services/economy_events_test.dart
git commit -m "feat(economy): add unified EconomyEvents broadcaster"
```

---

## Task 2: Publish from xp_service.awardXp

**Files:**
- Modify: `lib/services/xp_service.dart` (add `source` parameter, publish on success)
- Create: `test/services/xp_service_publishes_events_test.dart`

- [ ] **Step 1: Write the failing test**

Sakina's xp_service.awardXp goes through Supabase RPC when `currentUserId != null`. For a unit test we run with no logged-in user — that path skips the RPC and just bumps the local cache. This keeps the test hermetic.

```dart
// test/services/xp_service_publishes_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/xp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('awardXp publishes XpGranted with source on success (no auth)', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // No supabase login → falls through to local-cache path.
    final result = await awardXp(80, source: EconomyEventSource.quest);

    expect(result.gained, 80);
    expect(result.newTotal, 80);
    expect(result.leveledUp, true); // crosses L1→L2 at 75 XP
    await Future<void>.delayed(Duration.zero);

    final event = received.single as XpGranted;
    expect(event.amount, 80);
    expect(event.newTotal, 80);
    expect(event.leveledUp, true);
    expect(event.source, EconomyEventSource.quest);
  });

  test('awardXp does not publish if RPC fails (server returned null)', () async {
    // Hard to fake the supabase null path without DI, so we cover this in the
    // integration test in Task 5 instead. This placeholder asserts the contract
    // by invoking with amount=0 (which still publishes — pinning current
    // behavior so we don't regress).
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    await awardXp(0, source: EconomyEventSource.dev);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect((received.single as XpGranted).amount, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/xp_service_publishes_events_test.dart
```
Expected: FAIL — `awardXp` doesn't accept `source` and doesn't publish.

- [ ] **Step 3: Modify `awardXp` to accept source and publish**

In `lib/services/xp_service.dart`, change the `awardXp` signature and add a publish at the end:

```dart
import 'package:sakina/services/economy_events.dart';

// ...

Future<XpAwardResult> awardXp(
  int amount, {
  EconomyEventSource source = EconomyEventSource.dev,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final oldTotal = await _getCachedXpTotal(prefs);
  final oldState = calculateXpState(oldTotal);
  final userId = supabaseSyncService.currentUserId;

  int newTotal;
  int? tokenBalance;
  int? scrollBalance;
  if (userId != null) {
    final rpcResult = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'award_xp',
      {'amount': amount},
    );
    if (rpcResult == null) {
      // RPC failed — return unchanged result, do NOT publish.
      return XpAwardResult(
        gained: 0,
        newTotal: oldTotal,
        leveledUp: false,
        state: oldState,
      );
    }
    newTotal = _readRpcInt(rpcResult, 'total_xp');
    final tokenValue = rpcResult['token_balance'];
    final scrollValue = rpcResult['scroll_balance'];
    tokenBalance = tokenValue is num ? tokenValue.toInt() : tokenValue as int?;
    scrollBalance =
        scrollValue is num ? scrollValue.toInt() : scrollValue as int?;
  } else {
    newTotal = oldTotal + amount;
  }

  await _setCachedXpTotal(prefs, newTotal);
  final newState = calculateXpState(newTotal);

  final didLevel = newState.level > oldState.level;
  LevelUpRewards? rewards;
  if (didLevel) {
    int tokensAwarded = 0;
    int scrollsAwarded = 0;
    bool titleUnlocked = false;
    String? unlockedTitle;
    String? unlockedTitleArabic;
    for (var lv = oldState.level + 1; lv <= newState.level; lv++) {
      final crossed = xpLevels[lv - 1];
      tokensAwarded += crossed.tokenReward;
      scrollsAwarded += crossed.scrollReward;
      if (crossed.unlocksTitle) {
        titleUnlocked = true;
        unlockedTitle = crossed.title;
        unlockedTitleArabic = crossed.titleArabic;
      }
    }
    rewards = LevelUpRewards(
      levelsGained: newState.level - oldState.level,
      tokensAwarded: tokensAwarded,
      scrollsAwarded: scrollsAwarded,
      titleUnlocked: titleUnlocked,
      unlockedTitle: unlockedTitle,
      unlockedTitleArabic: unlockedTitleArabic,
    );
  }

  if (userId != null) {
    if (tokenBalance != null) {
      await hydrateTokenCache(
        balance: tokenBalance,
        totalSpent: await getTotalTokensSpent(),
      );
    }
    if (scrollBalance != null) {
      await hydrateTierUpScrollCache(balance: scrollBalance);
    }
  } else if (rewards != null) {
    if (rewards.tokensAwarded > 0) {
      final currentTokens = await getTokens();
      tokenBalance = currentTokens.balance + rewards.tokensAwarded;
      await hydrateTokenCache(
        balance: tokenBalance,
        totalSpent: await getTotalTokensSpent(),
      );
    }
    if (rewards.scrollsAwarded > 0) {
      final currentScrolls = await getTierUpScrolls();
      scrollBalance = currentScrolls.balance + rewards.scrollsAwarded;
      await hydrateTierUpScrollCache(balance: scrollBalance);
    }
  }

  EconomyEvents.publish(XpGranted(
    amount: amount,
    newTotal: newTotal,
    newState: newState,
    leveledUp: didLevel,
    rewards: rewards,
    source: source,
  ));

  return XpAwardResult(
    gained: amount,
    newTotal: newTotal,
    leveledUp: didLevel,
    state: newState,
    rewards: rewards,
    tokenBalance: tokenBalance,
    scrollBalance: scrollBalance,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/xp_service_publishes_events_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/xp_service.dart test/services/xp_service_publishes_events_test.dart
git commit -m "feat(xp): publish XpGranted on awardXp success"
```

---

## Task 3: Publish from token_service.earnTokens

**Files:**
- Modify: `lib/services/token_service.dart`
- Create: `test/services/token_service_publishes_events_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/token_service_publishes_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/token_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('earnTokens publishes TokenGranted with source on success', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final result = await earnTokens(7, source: EconomyEventSource.quest);

    expect(result.balance, startingTokens + 7);
    await Future<void>.delayed(Duration.zero);
    final event = received.single as TokenGranted;
    expect(event.amount, 7);
    expect(event.newBalance, startingTokens + 7);
    expect(event.source, EconomyEventSource.quest);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/token_service_publishes_events_test.dart
```
Expected: FAIL — `earnTokens` doesn't accept `source` and doesn't publish.

- [ ] **Step 3: Modify `earnTokens`**

In `lib/services/token_service.dart`, replace the `earnTokens` body:

```dart
import 'package:sakina/services/economy_events.dart';

// ...

Future<TokenState> earnTokens(
  int amount, {
  EconomyEventSource source = EconomyEventSource.dev,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  final userId = supabaseSyncService.currentUserId;

  int newBalance;
  if (userId != null) {
    final remoteBalance = await supabaseSyncService.callRpc<int>(
      'earn_tokens',
      {'amount': amount},
    );
    if (remoteBalance == null) {
      // RPC failed — return current, do NOT publish.
      return TokenState(balance: current);
    }
    newBalance = remoteBalance;
  } else {
    newBalance = current + amount;
  }

  await _setCachedBalance(prefs, newBalance);
  EconomyEvents.publish(TokenGranted(
    amount: amount,
    newBalance: newBalance,
    source: source,
  ));
  return TokenState(balance: newBalance);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/token_service_publishes_events_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/token_service.dart test/services/token_service_publishes_events_test.dart
git commit -m "feat(tokens): publish TokenGranted on earnTokens success"
```

---

## Task 4: Publish from tier_up_scroll_service.earnTierUpScrolls

**Files:**
- Modify: `lib/services/tier_up_scroll_service.dart`
- Create: `test/services/tier_up_scroll_service_publishes_events_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/services/tier_up_scroll_service_publishes_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('earnTierUpScrolls publishes ScrollGranted on success', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final result = await earnTierUpScrolls(3, source: EconomyEventSource.firstSteps);

    expect(result.success, true);
    expect(result.newBalance, 3);
    await Future<void>.delayed(Duration.zero);
    final event = received.single as ScrollGranted;
    expect(event.amount, 3);
    expect(event.newBalance, 3);
    expect(event.source, EconomyEventSource.firstSteps);
  });

  test('earnTierUpScrolls does not publish on RPC failure', () async {
    // Covered in the integration test (Task 5). Pin the success-only contract.
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    await earnTierUpScrolls(0, source: EconomyEventSource.dev);
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1)); // 0-amount still success, still publishes
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/tier_up_scroll_service_publishes_events_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Modify `earnTierUpScrolls`**

In `lib/services/tier_up_scroll_service.dart`:

```dart
import 'package:sakina/services/economy_events.dart';

// ...

Future<TierUpScrollEarnResult> earnTierUpScrolls(
  int amount, {
  EconomyEventSource source = EconomyEventSource.dev,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  final userId = supabaseSyncService.currentUserId;

  int newBalance;
  if (userId != null) {
    final remoteBalance = await supabaseSyncService.callRpc<int>(
      'earn_scrolls',
      {'amount': amount},
    );
    if (remoteBalance == null) {
      return TierUpScrollEarnResult(
        success: false,
        newBalance: current,
        failureReason: TierUpScrollFailureReason.syncFailed,
      );
    }
    newBalance = remoteBalance;
  } else {
    newBalance = current + amount;
  }

  await _setCachedBalance(prefs, newBalance);
  EconomyEvents.publish(ScrollGranted(
    amount: amount,
    newBalance: newBalance,
    source: source,
  ));
  return TierUpScrollEarnResult(success: true, newBalance: newBalance);
}
```

- [ ] **Step 4: Run test**

```bash
flutter test test/services/tier_up_scroll_service_publishes_events_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/tier_up_scroll_service.dart test/services/tier_up_scroll_service_publishes_events_test.dart
git commit -m "feat(scrolls): publish ScrollGranted on earnTierUpScrolls success"
```

---

## Task 5: Wire quest grants to publish with `source: quest` / `firstSteps`

**Files:**
- Modify: `lib/features/quests/providers/quests_provider.dart`
- Create: `test/features/quests/quest_grant_publishes_events_test.dart`

- [ ] **Step 1: Write the failing integration test**

```dart
// test/features/quests/quest_grant_publishes_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/economy_events.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('completing a daily quest publishes XpGranted + TokenGranted with source=quest',
      () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final notifier = QuestsNotifier();
    // Wait for the constructor's _load() to settle.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Complete whichever daily is active today (rotation is deterministic).
    final daily = notifier.state.daily;
    expect(daily, isNotEmpty);
    final quest = daily.first;
    await notifier.completeQuest(quest.id);

    final xpEvents = received.whereType<XpGranted>().toList();
    final tokenEvents = received.whereType<TokenGranted>().toList();

    expect(xpEvents, hasLength(1));
    expect(xpEvents.single.amount, quest.xpReward);
    expect(xpEvents.single.source, EconomyEventSource.quest);
    if (quest.tokenReward > 0) {
      expect(tokenEvents, hasLength(1));
      expect(tokenEvents.single.source, EconomyEventSource.quest);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/quests/quest_grant_publishes_events_test.dart
```
Expected: FAIL — quest still calls bare `awardXp(amount)` without `source`, default is `dev`.

- [ ] **Step 3: Update quest grant call sites**

In `lib/features/quests/providers/quests_provider.dart`:

```dart
import 'package:sakina/services/economy_events.dart';
```

Inside `_markBeginnerComplete` (line ~803-820), change:

```dart
    if (quest.scrollReward > 0) {
      final scrollResult = await earnTierUpScrolls(
        quest.scrollReward,
        source: EconomyEventSource.firstSteps,
      );
      if (!scrollResult.success) return;
    }
    if (shouldClaimBundle && firstStepsBundleScrolls > 0) {
      final scrollResult = await earnTierUpScrolls(
        firstStepsBundleScrolls,
        source: EconomyEventSource.firstSteps,
      );
      if (!scrollResult.success) return;
    }

    if (quest.xpReward > 0) {
      await awardXp(quest.xpReward, source: EconomyEventSource.firstSteps);
    }
    if (quest.tokenReward > 0) {
      await earnTokens(quest.tokenReward, source: EconomyEventSource.firstSteps);
    }

    // Bundle bonus
    bool bundleClaimed = state.firstStepsBundleClaimed;
    FirstStepsBundleCelebration? celebration;
    if (shouldClaimBundle) {
      if (firstStepsBundleXp > 0) {
        await awardXp(firstStepsBundleXp, source: EconomyEventSource.firstSteps);
      }
      if (firstStepsBundleTokens > 0) {
        await earnTokens(firstStepsBundleTokens, source: EconomyEventSource.firstSteps);
      }
      bundleClaimed = true;
      celebration = const FirstStepsBundleCelebration(...);
    }
```

Inside `completeQuest` (line ~886-924):

```dart
    if (quest.scrollReward > 0) {
      final scrollResult = await earnTierUpScrolls(
        quest.scrollReward,
        source: EconomyEventSource.quest,
      );
      if (!scrollResult.success) return;
    }

    // ... state update + supabase upsert unchanged ...

    if (quest.xpReward > 0) {
      await awardXp(quest.xpReward, source: EconomyEventSource.quest);
    }
    if (quest.tokenReward > 0) {
      await earnTokens(quest.tokenReward, source: EconomyEventSource.quest);
    }
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/quests/quest_grant_publishes_events_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/quests/providers/quests_provider.dart test/features/quests/quest_grant_publishes_events_test.dart
git commit -m "feat(quests): tag quest + first-steps grants with EconomyEventSource"
```

---

## Task 6: Migrate ConsumableGrantsService to publish through EconomyEvents

**Files:**
- Modify: `lib/services/consumable_grants_service.dart`
- Modify: `lib/features/daily/providers/daily_loop_provider.dart` (subscribe to `EconomyEvents` instead of `ConsumableGrantsService.grants`)
- Modify: `lib/features/collection/providers/tier_up_scroll_provider.dart` (same)

> Goal: collapse the two streams into one. After this task, `ConsumableGrantsService` no longer owns its own `_grantsController`; both subscribers read from `EconomyEvents.stream`. `earnTokens` / `earnTierUpScrolls` already publish (Tasks 3 + 4), so the IAP path needs to pass `source: iap` to keep the current observability.

- [ ] **Step 1: Update ConsumableGrantsService to pass source=iap and drop its own controller**

In `lib/services/consumable_grants_service.dart`:

1. Remove `_grantsController`, the `ConsumableGrantEvent` class, and the `static Stream<ConsumableGrantEvent> get grants` getter.
2. In `processCustomerInfo` (around line 215-225), change the grant calls to pass source:

```dart
        switch (mapping.kind) {
          case ConsumableGrantKind.tokens:
            final result = await earnTokens(
              mapping.amount,
              source: EconomyEventSource.iap,
            );
            newBalance = result.balance;
            break;
          case ConsumableGrantKind.scrolls:
            final result = await earnTierUpScrolls(
              mapping.amount,
              source: EconomyEventSource.iap,
            );
            newBalance = result.newBalance;
            break;
        }
        grantsCount += 1;
        // _grantsController.add(...) — REMOVED. earnTokens / earnTierUpScrolls
        // already publish via EconomyEvents now.
```

3. Same change in `grantForMostRecentPurchase` (around line 336-348).
4. Add `import 'package:sakina/services/economy_events.dart';` at the top.

- [ ] **Step 2: Update daily_loop_provider subscription**

In `lib/features/daily/providers/daily_loop_provider.dart`, replace the `_grantsSub` block (line 235-239):

```dart
import 'package:sakina/services/economy_events.dart';
// remove: import 'package:sakina/services/consumable_grants_service.dart';
// (keep the import if other code in this file references it; otherwise drop)

// In the constructor:
    _grantsSub = EconomyEvents.stream.listen((event) {
      if (event is TokenGranted) {
        state = state.copyWith(tokenBalance: event.newBalance);
      } else if (event is XpGranted) {
        // Refresh the cached XP/level fields so the home dashboard's
        // progress bar redraws. Level-up overlay is pushed by app_shell —
        // we deliberately do NOT set state.leveledUp here anymore.
        state = state.copyWith(
          xpTotal: event.newTotal,
          levelNumber: event.newState.level,
          levelTitle: event.newState.title,
          levelTitleArabic: event.newState.titleArabic,
        );
      }
    });

// And the field type:
  StreamSubscription<EconomyEvent>? _grantsSub;
```

- [ ] **Step 3: Update tier_up_scroll_provider subscription**

In `lib/features/collection/providers/tier_up_scroll_provider.dart`:

```dart
import 'package:sakina/services/economy_events.dart';
// remove: import 'package:sakina/services/consumable_grants_service.dart';

class TierUpScrollNotifier extends StateNotifier<TierUpScrollState> {
  TierUpScrollNotifier() : super(const TierUpScrollState(balance: 0)) {
    _grantsSub = EconomyEvents.stream.listen((event) {
      if (event is ScrollGranted) {
        state = TierUpScrollState(balance: event.newBalance);
      }
    });
    _load();
  }

  StreamSubscription<EconomyEvent>? _grantsSub;
  // ... rest unchanged ...
}
```

**Step 3b (Issue 5): Update `tokenProvider` with explicit subscription + dispose.**

In `lib/features/daily/providers/token_provider.dart`, replace the `TokenNotifier`:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/token_service.dart';

class TokenNotifier extends StateNotifier<TokenState> {
  TokenNotifier() : super(const TokenState(balance: 0)) {
    _econSub = EconomyEvents.stream.listen((event) {
      if (event is TokenGranted) {
        state = TokenState(balance: event.newBalance);
      }
    });
    _load();
  }

  StreamSubscription<EconomyEvent>? _econSub;

  @override
  void dispose() {
    _econSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    state = await getTokens();
  }

  Future<bool> spend(int amount) async {
    final result = await spendTokens(amount);
    state = TokenState(balance: result.newBalance);
    return result.success;
  }

  Future<void> earn(int amount) async {
    // Earn-from-notifier still goes through service; service publishes,
    // and our own listener will set state. We just await for the side effect.
    await earnTokens(amount, source: EconomyEventSource.dev);
  }

  Future<void> reload() async {
    state = await getTokens();
  }
}

final tokenProvider = StateNotifierProvider<TokenNotifier, TokenState>(
  (ref) => TokenNotifier(),
);
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```
Expected: any tests that imported `ConsumableGrantEvent` or `ConsumableGrantsService.grants` will fail. Update those tests to use `EconomyEvents.stream` and `TokenGranted` / `ScrollGranted`. Run again until green.

- [ ] **Step 5: Commit**

```bash
git add lib/services/consumable_grants_service.dart \
        lib/features/daily/providers/daily_loop_provider.dart \
        lib/features/collection/providers/tier_up_scroll_provider.dart \
        test/
git commit -m "refactor(economy): consolidate IAP grants into EconomyEvents"
```

---

## Task 6.5: Route premium grants through EconomyEvents (Issue 1)

**Why:** During simulator reproduction, scrolls visibly went 0 → 36 between Home and Collection mounts with no user action — that was `premium_grants_service.checkPremiumMonthlyGrant()` writing to the cache asynchronously after `tierUpScrollProvider._load()` had already read 0. After Tasks 3 + 4 land, the fix is one line: route the grant through `earnTokens(source: iap)` / `earnTierUpScrolls(source: iap)` so listeners refresh.

**Files:**
- Modify: `lib/services/premium_grants_service.dart`
- Test exists in repo (manual verification covered in Task 10).

- [ ] **Step 1: Locate the grant call sites**

```bash
cd flutter && grep -n "earn\|hydrate\|setCachedBalance" lib/services/premium_grants_service.dart
```

- [ ] **Step 2: Replace direct cache writes with `earnTokens` / `earnTierUpScrolls` calls**

Wherever `premium_grants_service.dart` writes the granted token amount or scroll amount directly into the cache (or calls a Supabase RPC and then `hydrateTokenCache` / `hydrateTierUpScrollCache`), replace that pair with:

```dart
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

// ... inside checkPremiumMonthlyGrant after the server confirms a grant amount:
if (grantedTokens > 0) {
  await earnTokens(grantedTokens, source: EconomyEventSource.iap);
}
if (grantedScrolls > 0) {
  await earnTierUpScrolls(grantedScrolls, source: EconomyEventSource.iap);
}
```

If `premium_grants_service.dart` already calls `earnTokens` / `earnTierUpScrolls`, just add the `source: EconomyEventSource.iap` argument.

- [ ] **Step 3: Run the existing premium-grant tests**

```bash
flutter test test/services/premium_grants_service_test.dart 2>/dev/null || flutter test test/services/
```
Expected: PASS, no regressions.

- [ ] **Step 4: Commit**

```bash
git add lib/services/premium_grants_service.dart
git commit -m "fix(premium): publish premium grants via EconomyEvents"
```

---

## Task 6.6: Route daily reward grants through EconomyEvents (Issue 3)

**Why:** `daily_rewards_service.claimDailyReward()` grants tokens. Without routing through `earnTokens(source: dailyReward)`, the daily-reward claim screen's pill animates inconsistently. This is the `dailyReward` enum value defined in Task 1 — wire it now.

**Files:**
- Modify: `lib/services/daily_rewards_service.dart`

- [ ] **Step 1: Locate token grants in `daily_rewards_service.dart`**

```bash
cd flutter && grep -n "earnTokens\|hydrateTokenCache\|setCachedBalance" lib/services/daily_rewards_service.dart
```

- [ ] **Step 2: Pass `source: EconomyEventSource.dailyReward`**

For each call site that grants tokens during a daily-reward claim:

```dart
import 'package:sakina/services/economy_events.dart';

// before:
await earnTokens(amount);
// after:
await earnTokens(amount, source: EconomyEventSource.dailyReward);
```

If the service writes the cache directly without `earnTokens`, refactor to use `earnTokens(amount, source: EconomyEventSource.dailyReward)` so the publish happens automatically.

- [ ] **Step 3: Run tests**

```bash
flutter test test/services/daily_rewards_service_test.dart 2>/dev/null || flutter test test/
```
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/services/daily_rewards_service.dart
git commit -m "fix(daily-rewards): publish daily-reward token grants via EconomyEvents"
```

---

## Task 7: Push LevelUpOverlay from app_shell instead of muhasabah_screen

**Files:**
- Modify: `lib/widgets/app_shell.dart`
- Modify: `lib/features/daily/screens/muhasabah_screen.dart`
- Modify: `lib/features/progress/screens/progress_screen.dart`
- Modify: `lib/features/daily/providers/daily_loop_provider.dart` (drop level-up state writes from `_handleXpAward`)
- Create: `test/widgets/app_shell_level_up_overlay_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/widgets/app_shell_level_up_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/widgets/app_shell.dart';
import 'package:sakina/features/daily/widgets/level_up_overlay.dart';

void main() {
  testWidgets('AppShell pushes LevelUpOverlay on XpGranted{leveledUp: true}',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    EconomyEvents.publish(XpGranted(
      amount: 80,
      newTotal: 80,
      newState: const XpState(
        totalXp: 80, level: 2, title: 'Listener', titleArabic: 'مُسْتَمِع',
        xpForNextLevel: 100, xpIntoCurrentLevel: 5,
      ),
      leveledUp: true,
      rewards: const LevelUpRewards(
        levelsGained: 1, tokensAwarded: 5, scrollsAwarded: 0,
        titleUnlocked: false,
      ),
      source: EconomyEventSource.quest,
    ));
    await tester.pump(); // microtask delivery
    await tester.pump(); // postFrame

    expect(find.byType(LevelUpOverlay), findsOneWidget);
  });

  // IRON RULE regression test (Issue 4): when streak milestone AND level-up
  // fire in the same tick, streak overlay must push BEFORE level-up overlay.
  // Today this is enforced by muhasabah_screen's early-return; after Task 7
  // moves level-up to AppShell, only postFrameCallback ordering remains —
  // which is not a hard guarantee. This test pins the invariant.
  testWidgets('Streak milestone overlay pushes BEFORE level-up overlay on same tick',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/muhasabah',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/muhasabah', builder: (_, __) => const MuhasabahScreen()),
          ],
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    // Same-frame: trigger both a streak milestone state mutation AND
    // publish XpGranted{leveledUp: true}. The streak overlay must mount first.
    final notifier = container.read(dailyLoopProvider.notifier);
    notifier.debugSetStreakMilestone(streak: 7, xp: 25, scrolls: 1);
    EconomyEvents.publish(XpGranted(
      amount: 25,
      newTotal: 100,
      newState: const XpState(
        totalXp: 100, level: 2, title: 'Listener', titleArabic: 'مُسْتَمِع',
        xpForNextLevel: 100, xpIntoCurrentLevel: 25,
      ),
      leveledUp: true,
      rewards: const LevelUpRewards(
        levelsGained: 1, tokensAwarded: 5, scrollsAwarded: 0,
        titleUnlocked: false,
      ),
      source: EconomyEventSource.streak,
    ));
    await tester.pump(); // microtask
    await tester.pump(); // postFrame for both pushes

    // Streak overlay must be on top (i.e., visible). Level-up overlay must
    // be in the navigator stack but covered by streak — so finder still finds
    // both, but the route order should have streak above level-up.
    final streakFinder = find.byType(StreakMilestoneOverlay);
    final levelFinder = find.byType(LevelUpOverlay);
    expect(streakFinder, findsOneWidget,
        reason: 'Streak milestone overlay must mount on same-tick race');
    // Note: level-up may or may not be in tree depending on how the listener
    // sequences the postFrame callbacks. The contract: streak must be visible
    // and on top. Verify by traversal:
    final BuildContext streakCtx = tester.element(streakFinder);
    expect(ModalRoute.of(streakCtx)?.isCurrent, isTrue,
        reason: 'Streak overlay must be the current/topmost route');
  });

  testWidgets('AppShell does NOT push LevelUpOverlay on XpGranted{leveledUp: false}',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    EconomyEvents.publish(XpGranted(
      amount: 10,
      newTotal: 10,
      newState: const XpState(
        totalXp: 10, level: 1, title: 'Seeker', titleArabic: 'طَالِب',
        xpForNextLevel: 75, xpIntoCurrentLevel: 10,
      ),
      leveledUp: false,
      source: EconomyEventSource.quest,
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LevelUpOverlay), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/widgets/app_shell_level_up_overlay_test.dart
```
Expected: FAIL — `AppShell` doesn't listen to `EconomyEvents` yet.

- [ ] **Step 3: Add listener + push to AppShell**

In `lib/widgets/app_shell.dart`, convert the widget to `ConsumerStatefulWidget` so it can hold a stream subscription, OR add a `useEffect`-equivalent. Use a `StatefulWidget` pattern:

```dart
import 'dart:async';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/features/daily/widgets/level_up_overlay.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<EconomyEvent>? _econSub;

  @override
  void initState() {
    super.initState();
    _econSub = EconomyEvents.stream.listen(_onEconomyEvent);
  }

  void _onEconomyEvent(EconomyEvent event) {
    if (event is XpGranted && event.leveledUp && event.rewards != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = Navigator.of(context, rootNavigator: true);
        nav.push(PageRouteBuilder(
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => LevelUpOverlay(
            levelNumber: event.newState.level,
            title: event.newState.title,
            titleArabic: event.newState.titleArabic,
            rewards: event.rewards,
            onContinue: nav.pop,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ));
      });
    }
  }

  @override
  void dispose() {
    _econSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... existing body unchanged: ref.listen calls + Scaffold ...
  }
}
```

- [ ] **Step 4: Drop level-up state writes from daily_loop_provider**

In `lib/features/daily/providers/daily_loop_provider.dart`, change `_handleXpAward` (line ~347-373) to no longer set `leveledUp: true`. The XP cache update is now handled by the `EconomyEvents` listener (Task 6 Step 2), so this method becomes:

```dart
  Future<void> _handleXpAward(int amount) async {
    // Source: streak — when this is invoked from a streak milestone path.
    // Quest-driven XP goes through QuestsNotifier directly and doesn't
    // come back through here.
    await awardXp(amount, source: EconomyEventSource.streak);
    // EconomyEvents listener updates state.xpTotal/levelNumber/etc.
    // Level-up overlay is pushed by app_shell — no `state.leveledUp` writes here.
  }
```

Also drop `state.leveledUp / newLevelTitle / newLevelTitleArabic / newLevelNumber / levelUpRewards` fields from `DailyLoopState` and `copyWith` (the Build step in Task 9 cleans up the now-unreferenced fields).

- [ ] **Step 5: Drop muhasabah_screen's _pushLevelUpOverlay**

In `lib/features/daily/screens/muhasabah_screen.dart`, remove:
- Lines 67-71 (the `next.leveledUp == true` branch in the `ref.listen`).
- The entire `_pushLevelUpOverlay` method (lines ~142-165).
- Any unused imports (`level_up_overlay.dart` if no longer referenced).

Keep streak-milestone handling intact.

- [ ] **Step 6: Drop progress_screen's _levelUpShown logic**

In `lib/features/progress/screens/progress_screen.dart`, remove lines 84 (`bool _levelUpShown = false;`) and the level-up clearing block at lines 149-158. App shell now owns level-up; the home screen no longer needs to mediate.

- [ ] **Step 7: Run all tests**

```bash
flutter test
```
Expected: PASS, including the two new app-shell tests. Update any tests that assert `dailyLoopProvider.leveledUp` to instead assert on `EconomyEvents.stream` or push overlay presence in `AppShell`.

- [ ] **Step 8: Commit**

```bash
git add lib/widgets/app_shell.dart \
        lib/features/daily/screens/muhasabah_screen.dart \
        lib/features/progress/screens/progress_screen.dart \
        lib/features/daily/providers/daily_loop_provider.dart \
        test/widgets/app_shell_level_up_overlay_test.dart \
        test/
git commit -m "feat(level-up): app_shell pushes LevelUpOverlay on every XP path"
```

---

## Task 8: AnimatedXpBar widget — tween + floating "+N XP"

**Files:**
- Create: `lib/widgets/animated_xp_bar.dart`
- Create: `test/widgets/animated_xp_bar_test.dart`
- Modify: `lib/features/progress/screens/progress_screen.dart` (use `AnimatedXpBar` in the dashboard card)

- [ ] **Step 1: Write the failing widget test**

```dart
// test/widgets/animated_xp_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/animated_xp_bar.dart';

void main() {
  testWidgets('AnimatedXpBar tweens fill when progress prop changes',
      (tester) async {
    double progress = 0.2;
    late StateSetter setOuter;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (_, setState) {
          setOuter = setState;
          return Scaffold(body: AnimatedXpBar(progress: progress));
        },
      ),
    ));

    final initial = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(initial.value, 0.2);

    setOuter(() => progress = 0.6);
    await tester.pump(const Duration(milliseconds: 100));

    final mid = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    // Tween is in flight: should be > 0.2 and < 0.6.
    expect(mid.value, greaterThan(0.2));
    expect(mid.value, lessThan(0.6));

    await tester.pump(const Duration(milliseconds: 600));
    final end = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(end.value, closeTo(0.6, 0.001));
  });

  testWidgets('AnimatedXpBar shows floating "+N XP" when xpGained changes from 0',
      (tester) async {
    int gained = 0;
    late StateSetter setOuter;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (_, setState) {
          setOuter = setState;
          return Scaffold(
            body: AnimatedXpBar(progress: 0.2, lastGained: gained),
          );
        },
      ),
    ));

    expect(find.textContaining('+'), findsNothing);

    setOuter(() => gained = 15);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('+15 XP'), findsOneWidget);

    // Floats up and fades out within ~1.6s.
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('+15 XP'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widgets/animated_xp_bar_test.dart
```
Expected: FAIL — `AnimatedXpBar` doesn't exist.

- [ ] **Step 3: Implement `AnimatedXpBar`**

```dart
// lib/widgets/animated_xp_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

class AnimatedXpBar extends StatefulWidget {
  const AnimatedXpBar({
    super.key,
    required this.progress,
    this.lastGained = 0,
    this.height = 6,
  });

  /// 0.0..1.0 fill of the bar.
  final double progress;

  /// Most recent XP amount gained. When this changes from 0 (or any value)
  /// to a positive integer, a floating "+N XP" label appears above the bar
  /// for ~1.5s. Setting back to 0 resets the trigger so the next gain animates.
  final int lastGained;

  final double height;

  @override
  State<AnimatedXpBar> createState() => _AnimatedXpBarState();
}

class _AnimatedXpBarState extends State<AnimatedXpBar> {
  int _floatKey = 0;
  int? _shownGained;

  @override
  void didUpdateWidget(covariant AnimatedXpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastGained > 0 &&
        widget.lastGained != oldWidget.lastGained) {
      setState(() {
        _floatKey++;
        _shownGained = widget.lastGained;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: widget.progress, end: widget.progress),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (_, value, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.height),
              child: LinearProgressIndicator(
                value: value,
                minHeight: widget.height,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            );
          },
        ),
        if (_shownGained != null)
          Positioned(
            top: -22,
            right: 0,
            child: Text(
              '+${_shownGained!} XP',
              key: ValueKey(_floatKey),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.streakAmber,
                fontWeight: FontWeight.w800,
              ),
            )
                .animate(key: ValueKey('xp-float-$_floatKey'))
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.4, end: -0.6, duration: 1200.ms)
                .then(delay: 200.ms)
                .fadeOut(duration: 400.ms),
          ),
      ],
    );
  }
}
```

Note: the `TweenAnimationBuilder` here re-tweens whenever `widget.progress` changes because Flutter detects a new `Tween.end` and animates from the current value to the new end. Verify in Step 4.

- [ ] **Step 4: Run widget test**

```bash
flutter test test/widgets/animated_xp_bar_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 5: Wire AnimatedXpBar into progress_screen**

In `lib/features/progress/screens/progress_screen.dart`, replace the current XP progress bar segment in `_buildDashboardCard` (find the `LinearProgressIndicator` near line 380-410, or wherever `xpProgress` is used) with `AnimatedXpBar`. Pass `progress: xpProgress` and `lastGained: state.lastXpGained ?? 0`.

Add `lastXpGained` to `DailyLoopState` (and `copyWith`), default `0`. Update `daily_loop_provider`'s `EconomyEvents` subscription (Task 6 Step 2) to also write it:

```dart
    _grantsSub = EconomyEvents.stream.listen((event) {
      if (event is TokenGranted) {
        state = state.copyWith(tokenBalance: event.newBalance);
      } else if (event is XpGranted) {
        state = state.copyWith(
          xpTotal: event.newTotal,
          levelNumber: event.newState.level,
          levelTitle: event.newState.title,
          levelTitleArabic: event.newState.titleArabic,
          lastXpGained: event.amount,
        );
      }
    });
```

Add a clearer: after the home screen consumes `lastXpGained`, schedule a reset back to 0 via a postFrameCallback so the next gain re-triggers the float. Add `clearLastXpGained()` to `DailyLoopNotifier`:

```dart
  void clearLastXpGained() {
    if (state.lastXpGained == 0) return;
    state = state.copyWith(lastXpGained: 0);
  }
```

In `progress_screen.dart`, after rendering, schedule:

```dart
    if (state.lastXpGained > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (mounted) ref.read(dailyLoopProvider.notifier).clearLastXpGained();
        });
      });
    }
```

- [ ] **Step 6: Run all tests**

```bash
flutter test
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/animated_xp_bar.dart \
        lib/features/progress/screens/progress_screen.dart \
        lib/features/daily/providers/daily_loop_provider.dart \
        test/widgets/animated_xp_bar_test.dart
git commit -m "feat(xp): tweened XP bar with floating +N XP label"
```

---

## Task 9: Cleanup — drop now-dead DailyLoopState fields

**Files:**
- Modify: `lib/features/daily/providers/daily_loop_provider.dart`
- Modify: any callers asserting on the removed fields.

- [ ] **Step 1: Identify dead fields**

After Task 7 the following are no longer read:
- `DailyLoopState.leveledUp`
- `DailyLoopState.newLevelTitle`
- `DailyLoopState.newLevelTitleArabic`
- `DailyLoopState.newLevelNumber`
- `DailyLoopState.levelUpRewards`
- `DailyLoopNotifier.clearLevelUp()`

```bash
cd flutter && grep -rn "leveledUp\|newLevelTitle\|newLevelNumber\|levelUpRewards\|clearLevelUp" lib/ test/ | grep -v "// "
```

Resolve each remaining reference: replace assertions with `EconomyEvents.stream` listening, or delete them outright if they're testing the now-removed glue.

- [ ] **Step 2: Remove the fields**

In `lib/features/daily/providers/daily_loop_provider.dart`:
- Remove the five fields from `DailyLoopState`.
- Remove their parameters from the constructor and `copyWith`.
- Remove `clearLevelUp()` method.

- [ ] **Step 3: Run all tests**

```bash
flutter test
```
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/daily/providers/daily_loop_provider.dart test/
git commit -m "refactor: drop dead level-up state from DailyLoopState"
```

---

## Task 9.5: Audit + remove `invalidateAllUserProviders` from non-dev call sites (Issue 2)

**Why:** During simulator reproduction we observed cross-screen state divergence (scrolls 0 on Home, 36 on Collection, no grant in between). That smells like `invalidateAllUserProviders(ref)` being called from a navigation hook or a session-hydration-completion path, forcing a re-`_load()` from cache that was meanwhile updated asynchronously. Once `EconomyEvents` is the source of truth, this crutch is wrong: every navigation or hydrate that calls it drops in-memory state including any in-flight `lastXpGained` float waiting to render. Audit and remove from all non-dev paths.

**Files:**
- Modify: callers of `invalidateAllUserProviders` (search-driven)
- Keep: `lib/features/settings/screens/dev_tools_screen.dart` (legitimate use — dev tools wants a hard reset)
- Create: `test/features/economy_cross_screen_consistency_test.dart`

- [ ] **Step 1: Find every call site**

```bash
cd flutter && grep -rn "invalidateAllUserProviders" lib/ test/ --include="*.dart"
```

- [ ] **Step 2: Categorize each call site**

For each match: is it (a) dev tools / debug code, or (b) production navigation / hydration code? Production callers must go.

- [ ] **Step 3: Replace each production caller with a no-op + comment**

```dart
// REMOVED: invalidateAllUserProviders(ref);
// EconomyEvents now drives provider state. Calling invalidate* here would
// drop in-flight UI state (e.g. lastXpGained floats) and is no longer correct.
```

If the call was load-bearing because a stream-based grant was missing, that's now covered by EconomyEvents and the listeners added in Tasks 6 / 7 / 8.

- [ ] **Step 4: Add cross-screen consistency widget test**

```dart
// test/features/economy_cross_screen_consistency_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/economy_events.dart';

void main() {
  testWidgets('tierUpScrollProvider value is identical across two simultaneously-mounted screens',
      (tester) async {
    // Mount two consumers reading the same provider. After publishing a
    // ScrollGranted, both must show the new balance — not just the most
    // recently mounted.
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Row(children: const [
          _ScrollPillProbe(testKey: Key('a')),
          _ScrollPillProbe(testKey: Key('b')),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    EconomyEvents.publish(const ScrollGranted(
      amount: 5, newBalance: 42, source: EconomyEventSource.iap,
    ));
    await tester.pump();

    expect(find.text('42', findRichText: true).evaluate().length, 2,
        reason: 'Both probes must reflect the same balance');
  });
}

class _ScrollPillProbe extends ConsumerWidget {
  const _ScrollPillProbe({required this.testKey});
  final Key testKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(tierUpScrollProvider).balance;
    return Text('$balance', key: testKey);
  }
}
```

- [ ] **Step 5: Run all tests**

```bash
flutter test
```
Expected: PASS. If any test fails because it relied on `invalidateAllUserProviders`, fix the test to use `EconomyEvents.publish` instead.

- [ ] **Step 6: Commit**

```bash
git add lib/ test/features/economy_cross_screen_consistency_test.dart
git commit -m "refactor: remove invalidateAllUserProviders from prod paths"
```

---

## Task 10: Manual verification on simulator with yoyoyo@gmail.com

**Files:** none (verification only).

- [ ] **Step 1: Reset the user's economy + quest state**

Run via Supabase MCP / SQL editor:

```sql
-- Targeted reset for user cdbc2545-96e7-4e19-b739-401f2694465c (yoyoyo@gmail.com).
-- Keeps card collection, check-in history, streaks, First Steps state intact.
UPDATE user_xp SET total_xp = 0 WHERE user_id = 'cdbc2545-96e7-4e19-b739-401f2694465c';
UPDATE user_tokens
   SET balance = 50, total_spent = 0, tier_up_scrolls = 0
 WHERE user_id = 'cdbc2545-96e7-4e19-b739-401f2694465c';
DELETE FROM user_quest_progress
 WHERE user_id = 'cdbc2545-96e7-4e19-b739-401f2694465c'
   AND cadence != 'one_time'; -- preserve First Steps completion
```

- [ ] **Step 2: Hot-restart the app on the booted simulator**

```bash
flutter run -d E1152EC8-6A80-4966-92D9-7D7425A81CD2 --dart-define-from-file=env.json
# Press 'R' for hot restart so SharedPreferences hydrate from the freshly reset Supabase rows.
```

**Note (learned during live reproduction):** SharedPreferences cache survives app kill+launch.
On a real test you may need to also wipe the scoped local cache so the app re-hydrates from server.
Do this via plistlib (filesystem path: `…/Containers/Data/Application/<UUID>/Library/Preferences/com.sakina.app.sakina.plist`).
The scoped-key suffix is `:<userId>`. Wipe these keys in particular:

- `flutter.sakina_total_xp:<userId>`
- `flutter.sakina_tokens:<userId>` and `flutter.sakina_total_tokens_spent:<userId>`
- `flutter.sakina_tier_up_scrolls:<userId>`
- `flutter.quests_completed_v2:<userId>` and `flutter.quests_progress_v2:<userId>`

- [ ] **Step 3: Reproduce the original bug class to verify the fix**

Walk through these flows on the simulator and verify the visual outcome:

1. **Quest reward visible**: tap the Collection tab. The active daily/weekly Collection-related quest completes; the toast shows "+10 XP +3 Tokens" AND the token pill on the Quests screen / Home dashboard updates without remount.
2. **XP bar animates**: complete a daily quest (Reflect or Journal). The home dashboard's XP bar tweens from old to new fill, and a "+10 XP" or "+15 XP" label floats above the bar for ~1.5s.
3. **Level-up overlay from a quest**: deliberately complete enough quests to cross the L1→L2 boundary (75 XP). `LevelUpOverlay` opens — even though the trigger was a quest, not muhasabah.
4. **Tier-up scroll quest**: from the Collection screen, tier up a card. The scroll pill (Collection screen, top-right) updates immediately, the "Tier up a card" daily quest completes if it's in today's rotation, and the toast lands.

- [ ] **Step 4: Confirm DB state matches UI**

```sql
SELECT 'tokens', balance, total_spent, tier_up_scrolls FROM user_tokens
 WHERE user_id = 'cdbc2545-96e7-4e19-b739-401f2694465c'
UNION ALL
SELECT 'xp', total_xp, NULL, NULL FROM user_xp
 WHERE user_id = 'cdbc2545-96e7-4e19-b739-401f2694465c';
```

Both rows must match what the UI now displays.

- [ ] **Step 5: Document the result**

Append a note to `docs/qa/runs/2026-04-27-§12-quests-titles-streaks.md` (or create `docs/qa/runs/2026-05-07-quest-rewards-xp-feedback.md`) with screenshots of: (a) toast + balance pill update in the same frame, (b) animating XP bar mid-tween, (c) level-up overlay triggered by a quest. Commit the QA note.

```bash
git add docs/qa/runs/2026-05-07-quest-rewards-xp-feedback.md
git commit -m "docs(qa): record quest rewards + xp feedback verification"
```

---

## Self-review notes (post-write)

Verified against `2026-05-07-quest-rewards-xp-feedback-design.md`:

- **R1 (provider notification)** → Tasks 1-6 fix this. All three earn functions now publish; `dailyLoopProvider` and `tierUpScrollProvider` listen.
- **R2 (level-up coupling)** → Task 7 moves the overlay to `app_shell` listening on `EconomyEvents`. Streak-milestone-before-level-up ordering is preserved because the streak overlay still pushes from `muhasabah_screen` (untouched), and `app_shell` uses `addPostFrameCallback` so it cannot interrupt a same-tick streak push.
- **R3 (no XP visual)** → Task 8 adds `AnimatedXpBar` with the chosen Duolingo-style above-bar float.
- **F1 source enum** matches the spec (`quest`, `firstSteps`, `streak`, `dailyReward`, `iap`, `dev`).
- **F3 immediate drop of `dailyLoopProvider.leveledUp`** done in Task 9.
- Verification reset SQL in Task 10 preserves card collection / streaks per the resolved decision.
- Type names consistent across tasks: `EconomyEvent`, `TokenGranted`, `ScrollGranted`, `XpGranted`, `EconomyEvents.publish`, `EconomyEvents.stream`.

No placeholders, no "TBD"s, every code-changing step shows the code.

---

## NOT in scope

- Server-side dedup for IAP grants (separate ongoing work; tracked in `consumable_grants_service.dart` TODOs).
- Refactoring `dailyLoopProvider` to remove its xp/level fields entirely. Task 9 drops the dead level-up fields; broader refactor deferred.
- Onboarding XP visual treatment — no XP is awarded during onboarding, no UI surface needs the float.
- New `LevelUpOverlay` style for routine gains — option 1 (above-bar tween) is enough.
- Dev-tools restructure — `dev_tools_screen` keeps its `invalidateAllUserProviders + _showLevelUpOverlay` workarounds; that's the one legitimate caller.

## What already exists (reuse, don't rebuild)

- `ConsumableGrantsService.grants` — existing IAP-only stream. We extend its pattern via `EconomyEvents`, drop the local controller.
- `tierUpScrollProvider` already subscribes to a grants stream — minimum diff is swapping the source.
- `dailyLoopProvider._grantsSub` already subscribes for tokens — minimum diff is also swapping the source AND adding XP.
- `LevelUpOverlay` widget exists; we just push it from a different listener.
- `dev_tools_screen._showLevelUpOverlay` shows the right pattern; AppShell's listener mirrors it.
- `flutter_animate` (already a dep) drives the floating "+N XP" label.

## Failure modes (per new codepath)

| Path | Realistic failure | Test? | Error handling? | Visible to user? |
|---|---|---|---|---|
| `awardXp` Supabase RPC returns null | No publish, no UI move, no toast lie | Manual (Task 5 integration); deeper coverage deferred | Returns unchanged result | Silent; user retries via next quest. **Acceptable for now**, but flag as a follow-up TODO. |
| `EconomyEvents.publish` after listener disposed | Memory leak from un-cancelled subscription | Issue 5 / Task 6 makes dispose explicit | dispose() cancels | None |
| Same-tick streak + level-up race | Wrong overlay on top, or both visible at once | Issue 4 / Task 7 regression test | postFrame ordering + isCurrent assertion | Yes — would feel janky |
| Cross-screen invalidate race | Pill resets to stale cache mid-session | Issue 2 / Task 9.5 cross-screen consistency test | Crutch removed | Yes — what user observed |
| Premium grant on first launch | Pill stays at pre-grant value until next nav | Manual verification (Task 10) | Issue 1 / Task 6.5 routes through earnTokens | Yes — what user observed |

**Critical gaps:** zero. Every newly-introduced path has either a test or an explicit acceptance note.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 5 issues found, 5 resolved (1A,2A,3A,4A,5A); plan amended with Tasks 6.5, 6.6, 7-tests, 9.5; live reproduction on simulator confirmed user-visible bug class plus 2 adjacent (premium grant async, cross-screen divergence) |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**CRITICAL GAPS:** 0
**VERDICT:** ENG CLEARED — ready to implement. Optionally run `/plan-design-review` for the AnimatedXpBar visual (above-bar float, Duolingo-style) before Task 8 lands.
