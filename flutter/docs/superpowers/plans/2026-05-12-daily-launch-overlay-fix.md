# Daily Launch Overlay — Date/Cache Bug Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three bugs that cause the daily-reward launch overlay to (a) re-fire after a valid claim across UTC midnight, (b) re-fire on every cold launch following a delete+reinstall, and (c) display a stale "Day N" highlight that doesn't match the day the server actually awards on claim.

**Architecture:** Three small, isolated changes — each guarded by a regression-pinning test:
1. `launch_gate_state.dart` is migrated from `DateTime.now()` (local) to UTC so its date marker agrees with `daily_rewards_service.dart` and the `claim_daily_reward` SQL RPC (both already UTC).
2. `launch_gate_service.dart::shouldShowDailyLaunch()` consults `getDailyRewards()` *after* reconcile and writes the marker + returns `false` when the server says the user already claimed today but no local marker exists (fresh-install path).
3. `daily_launch_overlay.dart` gates the Claim button on a `_rewardsLoaded` flag that flips true only after `reload()` resolves, so the strip+highlight and the RPC always agree on which day is being claimed.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Riverpod, SharedPreferences, `flutter_test` for unit/widget tests, `integration_test` package for iOS simulator end-to-end, `mcp__ios-simulator__*` tools for the manual verification pass.

---

## File Structure

**Modify:**
- `lib/services/launch_gate_state.dart` — UTC date, add `@visibleForTesting` clock seam
- `lib/services/launch_gate_service.dart` — post-reconcile claimedToday check
- `lib/features/daily/screens/daily_launch_overlay.dart` — `_rewardsLoaded` gate on claim CTA
- `test/services/launch_gate_service_test.dart` — update existing tests to compile against new signature (only if needed; should remain passing as-is)
- `pubspec.yaml` — add `integration_test` to dev_dependencies

**Create:**
- `test/services/launch_gate_state_utc_test.dart` — Bug #1 regression test
- `test/services/launch_gate_service_reinstall_test.dart` — Bug #2 regression test
- `test/features/daily/daily_launch_overlay_loading_gate_test.dart` — Bug #3 regression test (incl. post-claim Day assertion)
- `integration_test/daily_launch_overlay_smoke_test.dart` — iOS simulator smoke test (mocked Supabase)
- `integration_test/support/fake_sync_export.dart` — re-export of `FakeSupabaseSyncService` for integration tests
- `integration_test/README.md` — how to run smoke tests on simulator
- `docs/qa/plans/2026-05-12-daily-launch-overlay-manual-qa.md` — manual MCP simulator verification script (real backend)

---

## Task 1: Switch launch-gate marker to UTC (Bug #1)

**Files:**
- Modify: `lib/services/launch_gate_state.dart`
- Create: `test/services/launch_gate_state_utc_test.dart`

- [ ] **Step 1: Write the failing test** — `test/services/launch_gate_state_utc_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-A'),
    );
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugLaunchGateClock = () => DateTime.now().toUtc();
  });

  test(
    'markDailyLaunchShown stores the UTC date even when local time is the previous day',
    () async {
      // Local: 2026-05-12 23:30 EST (UTC-5) — already 2026-05-13 04:30 UTC.
      // launchGateTodayMarker() and the stored marker must agree on the UTC date.
      debugLaunchGateClock = () => DateTime.utc(2026, 5, 13, 4, 30);

      await markDailyLaunchShown();

      final prefs = await SharedPreferences.getInstance();
      final scoped = SupabaseSyncService.instance.scopedKey('sakina_launch_gate');
      expect(prefs.getString(scoped), '2026-05-13');
      expect(launchGateTodayMarker(), '2026-05-13');
    },
  );

  test(
    'shouldShowDailyLaunch returns false when the stored marker matches UTC today',
    () async {
      debugLaunchGateClock = () => DateTime.utc(2026, 5, 13, 4, 30);
      await markDailyLaunchShown();
      resetLaunchGateMemoryGuard();

      // Local rolls past midnight (now 2026-05-13 00:30 local) but UTC is still 2026-05-13.
      // The marker must still match — the overlay must NOT re-fire.
      debugLaunchGateClock = () => DateTime.utc(2026, 5, 13, 5, 30);
      // Note: shouldShowDailyLaunch is in launch_gate_service.dart and reconciles
      // from server. For this UTC-only test we exercise the primitive directly:
      final prefs = await SharedPreferences.getInstance();
      final scoped = SupabaseSyncService.instance.scopedKey('sakina_launch_gate');
      expect(prefs.getString(scoped), launchGateTodayMarker());
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/launch_gate_state_utc_test.dart`
Expected: FAIL — `debugLaunchGateClock` undefined (compile error) OR marker is `'2026-05-12'` (local) instead of `'2026-05-13'` (UTC) once the seam exists but `_today()` still uses local time.

- [ ] **Step 3: Implement the UTC switch + test seam** — `lib/services/launch_gate_state.dart`

Replace the entire file with:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// Internal SharedPref key + in-memory session guard for the daily launch
// overlay. Lives in its own file (no Sakina-internal imports) so both
// `launch_gate_service.dart` and `daily_rewards_service.dart` can depend
// on it without forming an import cycle.

const String _launchGateKey = 'sakina_launch_gate';

bool _overlayPushedThisSession = false;

/// Test seam — replace in tests via `debugLaunchGateClock = ...` to drive
/// the gate at deterministic UTC instants. Production callers always read
/// `DateTime.now().toUtc()`. The gate stores UTC dates so it agrees with
/// `daily_rewards_service._today()` and the `claim_daily_reward` SQL RPC,
/// both of which key off UTC (`timezone('utc', now())::date`). Without
/// this, a claim made near local-but-not-UTC midnight wrote a "today
/// local" marker while the server wrote a "tomorrow UTC" `last_claim_date`
/// — next morning the marker disagreed with the UTC clock and the overlay
/// re-fired despite the user having already claimed.
@visibleForTesting
DateTime Function() debugLaunchGateClock = () => DateTime.now().toUtc();

String _today() {
  final now = debugLaunchGateClock();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

bool get launchGateOverlayPushedThisSession => _overlayPushedThisSession;

Future<String?> readLaunchGateMarker() async {
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  return prefs.getString(scopedKey);
}

String launchGateTodayMarker() => _today();

/// Call this after the overlay has been presented so subsequent opens skip it.
Future<void> markDailyLaunchShown() async {
  _overlayPushedThisSession = true;
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  await prefs.setString(scopedKey, _today());
}

/// Call this when the user resets the daily loop from Settings.
Future<void> resetDailyLaunchGate() async {
  _overlayPushedThisSession = false;
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  await prefs.remove(scopedKey);
}

void resetLaunchGateSessionState() {
  _overlayPushedThisSession = false;
}

@visibleForTesting
void resetLaunchGateMemoryGuard() {
  resetLaunchGateSessionState();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/launch_gate_state_utc_test.dart`
Expected: PASS — marker is `'2026-05-13'`, `launchGateTodayMarker()` returns `'2026-05-13'`.

- [ ] **Step 5: Run the pre-existing launch_gate_service tests to ensure no regression**

Run: `flutter test test/services/launch_gate_service_test.dart`
Expected: PASS — three existing tests (`markDailyLaunchShown writes a user-scoped key`, `shouldShowDailyLaunch reads the user-scoped key`, `clearSession-style cleanup removes the scoped launch gate key`) all still pass. They never asserted the *value* of the date string, only that a marker was written/read/cleared.

- [ ] **Step 6: Commit**

```bash
git add lib/services/launch_gate_state.dart test/services/launch_gate_state_utc_test.dart
git commit -m "fix(daily-launch): key launch gate marker by UTC to match server clock

Previously _today() used DateTime.now() (local) while
daily_rewards_service._today() and the claim_daily_reward RPC both
use UTC. Around local-but-not-UTC midnight the marker disagreed with
the rewards system and the overlay re-fired the morning after a valid
claim. Pinned by launch_gate_state_utc_test."
```

---

## Task 2: Suppress overlay when server says claimed-today on a fresh install (Bug #2)

**Files:**
- Modify: `lib/services/launch_gate_service.dart`
- Create: `test/services/launch_gate_service_reinstall_test.dart`

- [ ] **Step 1: Write the failing test** — `test/services/launch_gate_service_reinstall_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugLaunchGateClock = () => DateTime.utc(2026, 5, 12, 14, 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugLaunchGateClock = () => DateTime.now().toUtc();
  });

  test(
    'fresh install: server says already claimed today => overlay suppressed and marker written',
    () async {
      // Simulate a delete+reinstall: SharedPrefs is empty, but the server
      // already knows the user claimed today.
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 4,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': true,
      };

      final should = await shouldShowDailyLaunch();
      expect(should, isFalse,
          reason: 'overlay must not show on reinstall when server confirms a same-UTC-day claim');

      // The marker must be written so subsequent cold launches today also skip.
      expect(
        await readLaunchGateMarker(),
        launchGateTodayMarker(),
        reason: 'fresh-install suppression must persist the marker, not just return false this call',
      );
    },
  );

  test(
    'fresh install: server says NOT claimed today => overlay still shows',
    () async {
      // Server has a row, but last_claim_date is yesterday — overlay should fire.
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 3,
        'last_claim_date': '2026-05-11',
        'streak_freeze_owned': false,
      };

      final should = await shouldShowDailyLaunch();
      expect(should, isTrue,
          reason: 'overlay must still fire when server says claim is pending');
      expect(await readLaunchGateMarker(), isNull,
          reason: 'we only write the marker when suppressing, not when firing');
    },
  );

  test(
    'fresh install: server has no row at all => overlay shows (new user)',
    () async {
      // No row exists for this user.
      expect(fakeSync.rows.containsKey('user_daily_rewards:user-A'), isFalse);

      final should = await shouldShowDailyLaunch();
      expect(should, isTrue);
      expect(await readLaunchGateMarker(), isNull);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/launch_gate_service_reinstall_test.dart`
Expected: FAIL on the first test — `should` is `true` (current behavior) and the marker is `null` because the current code never consults `getDailyRewards()` after reconcile.

- [ ] **Step 3: Implement the post-reconcile claimedToday check** — `lib/services/launch_gate_service.dart`

Replace the entire file with:

```dart
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_state.dart';

// Re-export the gate primitives so existing callers that import
// `launch_gate_service.dart` keep working unchanged. The underlying state
// lives in `launch_gate_state.dart` to avoid a cycle with
// `daily_rewards_service.dart`.
export 'package:sakina/services/launch_gate_state.dart';

/// Returns true if the daily launch overlay should be shown (first open today).
///
/// Reconciles the local rewards cache with the server FIRST so admin/QA-driven
/// resets to `user_daily_rewards` (or multi-device claims) actually re-trigger
/// the overlay. Without this, the local SharedPref gate could lie about
/// "shown today" even when the server says nothing was claimed.
///
/// After reconcile, also checks whether the server says the user already
/// claimed today. On a fresh install (marker absent) where the server already
/// confirms a same-UTC-day claim — typically a delete+reinstall on the same
/// day — the overlay would otherwise re-fire and walk the user through a
/// "Reward Claimed!" success screen they've already seen. We suppress the
/// overlay and persist the marker so subsequent cold launches today also
/// skip. See docs/qa/findings/2026-05-12-daily-launch-overlay-fix.md.
Future<bool> shouldShowDailyLaunch() async {
  if (launchGateOverlayPushedThisSession) return false;

  // Best-effort server reconcile — if the network is down we fall through
  // to the cached value (better to skip the overlay than to crash).
  try {
    await reconcileDailyRewardsFromServer();
  } catch (_) {}

  final last = await readLaunchGateMarker();
  if (last == launchGateTodayMarker()) return false;

  // Fresh-install / cache-wiped path: the marker is missing but the server
  // already says today's reward is claimed. Don't re-show the post-claim
  // success screen — persist the marker so the rest of today is quiet.
  final rewards = await getDailyRewards();
  if (rewards.claimedToday) {
    await markDailyLaunchShown();
    return false;
  }

  return true;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/launch_gate_service_reinstall_test.dart test/services/launch_gate_service_test.dart`
Expected: PASS — all three new tests AND the three pre-existing `launch_gate_service_test` tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/launch_gate_service.dart test/services/launch_gate_service_reinstall_test.dart
git commit -m "fix(daily-launch): suppress overlay when server confirms same-day claim on fresh install

shouldShowDailyLaunch() now reads getDailyRewards() after reconcile.
When the SharedPref marker is missing but the server already knows the
user claimed today (e.g. delete+reinstall on the same UTC day), we
persist the marker and return false instead of showing a redundant
'Reward Claimed!' success screen on every cold launch.
Pinned by launch_gate_service_reinstall_test."
```

---

## Task 3: Gate the Claim button on rewards-loaded so strip and RPC agree (Bug #3)

**Files:**
- Modify: `lib/features/daily/screens/daily_launch_overlay.dart`
- Create: `test/features/daily/daily_launch_overlay_loading_gate_test.dart`

- [ ] **Step 1: Write the failing widget test** — `test/features/daily/daily_launch_overlay_loading_gate_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/sakina_loader.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugLaunchGateClock = () => DateTime.utc(2026, 5, 12, 14, 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugLaunchGateClock = () => DateTime.now().toUtc();
  });

  testWidgets(
    'reward claim step shows loader (not strip) until reload completes',
    (tester) async {
      // Server has fresh state: current_day=3, last_claim=yesterday — overlay
      // should ultimately highlight Day 4 (nextClaimDay). The local cache is
      // EMPTY, so the provider's initial state is currentDay=0 → nextClaimDay=1
      // → a buggy version would briefly highlight D1 before reload lands.
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 3,
        'last_claim_date': '2026-05-11',
        'streak_freeze_owned': false,
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DailyLaunchOverlay()),
        ),
      );
      // First paint — Step 0 (streak greeting). No strip rendered yet.
      await tester.pump();

      // Advance to Step 1 by tapping Begin.
      await tester.tap(find.text('Begin'));
      await tester.pump();

      // Before reload resolves, Step 1 MUST show the loader, not the strip,
      // and the Claim button MUST be absent. This prevents the user clicking
      // claim while local state is stale and getting a different Day back
      // from the server than the UI showed.
      expect(
        find.byType(SakinaLoader),
        findsWidgets,
        reason: 'loader must render until rewards reload completes',
      );
      expect(
        find.text('Claim Reward'),
        findsNothing,
        reason: 'Claim button must not appear before reload completes',
      );

      // Pump until reload completes + animations settle.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Now the strip + Claim button are visible, and the highlighted day
      // is Day 4 (nextClaimDay for server current_day=3).
      expect(find.text('Claim Reward'), findsOneWidget);
      expect(find.text('Day 4 reward'), findsOneWidget);

      // Wire up the RPC mock so the claim RPC returns Day 4 — pins the
      // invariant that the pre-claim "Day 4 reward" label and the
      // post-claim success Day agree. This is the exact bug reported on
      // 2026-05-12 (yoyoyo@gmail.com saw "Day 2" but received Day 4).
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async {
        return {
          'day': 4,
          'tokens_awarded': 0,
          'scrolls_awarded': 0,
          'earned_streak_freeze': true,
          'earned_tier_up_scroll': false,
          'already_claimed': false,
          'current_day': 4,
          'last_claim_date': '2026-05-12',
          'streak_freeze_owned': true,
          'token_balance': 0,
          'scroll_balance': 0,
          'is_premium': false,
          'multiplier': 1,
        };
      };

      await tester.tap(find.text('Claim Reward'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Reward Claimed!'), findsOneWidget);
      // Post-claim copy must reference Day 5 (next), proving Day 4 was awarded.
      expect(find.textContaining('Day 5'), findsWidgets,
          reason: 'success screen Day must match the Day shown pre-claim');
    },
  );

  testWidgets(
    'reward claim step skips the claim flow when server says claimedToday=true',
    (tester) async {
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 4,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': true,
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DailyLaunchOverlay()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 0 is still the streak greeting. The "Begin" tap should dismiss
      // the overlay because reward is already claimed for today.
      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // No claim CTA should ever have appeared.
      expect(find.text('Claim Reward'), findsNothing);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/daily/daily_launch_overlay_loading_gate_test.dart`
Expected: FAIL on the first test — Claim Reward button appears immediately on Step 1 (before reload), and the highlight is "Day 1 reward" (stale local) rather than "Day 4 reward" (server fresh) until reload lands. The loader assertion fails because the current overlay renders `_RewardHighlight` directly with whatever provider state happens to be in cache.

- [ ] **Step 3: Implement the loaded-gate** — `lib/features/daily/screens/daily_launch_overlay.dart`

Apply these three edits to `daily_launch_overlay.dart`:

(a) Add a `_rewardsLoaded` field and set it after reload completes. Modify lines 31-65 (state class + initState):

```dart
class _DailyLaunchOverlayState extends ConsumerState<DailyLaunchOverlay> {
  // 0 = streak greeting, 1 = reward claim, 2 = check-in
  int _step = 0;
  bool _rewardClaimed = false;
  bool _rewardsLoaded = false;
  DailyRewardClaimResult? _claimResult;
  bool _claimLoading = false;
  AppSessionNotifier?
      _session; // Captured ref so listener cleanup works after dispose

  @override
  void initState() {
    super.initState();
    // Mark as shown so subsequent opens skip it
    markDailyLaunchShown();
    // Ensure rewards provider has fresh data before we check claimedToday
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final session = ref.read(appSessionProvider);
      _session = session;
      if (!session.economyHydrated) {
        session.addListener(_onSessionChange);
      } else {
        // Hydration already complete — refresh economy + scroll state now.
        ref.read(dailyLoopProvider.notifier).refreshEconomyState();
        ref.read(tierUpScrollProvider.notifier).reload();
      }

      await ref.read(dailyRewardsProvider.notifier).reload();
      if (!mounted) return;
      final rewards = ref.read(dailyRewardsProvider);
      setState(() {
        _rewardsLoaded = true;
        if (rewards.claimedToday) _rewardClaimed = true;
      });
    });
  }
```

(b) Pass `rewardsLoaded` into `_RewardClaimStep`. Modify the switch around line 140-152:

```dart
          child: switch (_step) {
            0 =>
              _StreakGreetingStep(key: const ValueKey(0), onContinue: _advance),
            1 => _RewardClaimStep(
                key: const ValueKey(1),
                rewardsLoaded: _rewardsLoaded,
                claimed: _rewardClaimed,
                claimLoading: _claimLoading,
                claimResult: _claimResult,
                onClaim: _claimReward,
                onContinue: _advance,
              ),
            _ => const SizedBox.shrink(key: ValueKey(2)),
          },
```

(c) Make `_RewardClaimStep` short-circuit to a loader until `rewardsLoaded` is true. Modify lines 324-400:

```dart
class _RewardClaimStep extends ConsumerWidget {
  const _RewardClaimStep({
    super.key,
    required this.rewardsLoaded,
    required this.claimed,
    required this.claimLoading,
    required this.claimResult,
    required this.onClaim,
    required this.onContinue,
  });

  final bool rewardsLoaded;
  final bool claimed;
  final bool claimLoading;
  final DailyRewardClaimResult? claimResult;
  final VoidCallback onClaim;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Block the strip+highlight+Claim button until the rewards provider
    // has finished reconciling with the server. Without this, the user
    // can see a stale "Day N" highlight (from cache) and then claim and
    // receive "Day M" from the RPC — a confusing mismatch reported on
    // 2026-05-12 for yoyoyo@gmail.com. See finding
    // 2026-05-12-daily-launch-overlay-fix.md.
    if (!rewardsLoaded) {
      return const Center(child: SakinaLoader());
    }

    final rewards = ref.watch(dailyRewardsProvider);
    final nextDay = rewards.nextClaimDay;
    // Default to free-tier display if premium status hasn't loaded yet so the
    // strip never flashes a premium label for non-premium users.
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    final reward = scaledRewardForDay(nextDay, isPremium: isPremium);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Daily Reward',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiaryLight,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),

          // 7-day strip
          _RewardStrip(rewards: rewards, isPremium: isPremium)
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.06, end: 0),

          const SizedBox(height: 40),

          // Today's reward highlight
          if (!claimed) ...[
            _RewardHighlight(reward: reward)
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .scaleXY(
                    begin: 0.92, end: 1.0, duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 40),
            claimLoading
                ? const SakinaLoader()
                : _PrimaryButton(label: 'Claim Reward', onTap: onClaim)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 350.ms),
          ] else ...[
            // Post-claim celebration
            _ClaimSuccess(
                    result: claimResult, rewards: rewards, isPremium: isPremium)
                .animate()
                .fadeIn(duration: 500.ms)
                .scaleXY(begin: 0.9, end: 1.0, duration: 400.ms),
            const SizedBox(height: 40),
            _PrimaryButton(label: 'Continue', onTap: onContinue)
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/daily/daily_launch_overlay_loading_gate_test.dart`
Expected: PASS — loader shows on Step 1 before reload, "Day 4 reward" shows after reload, claimedToday=true path never exposes the Claim button.

- [ ] **Step 5: Run full daily-feature test suite for regressions**

Run: `flutter test test/features/daily/`
Expected: PASS — all 10 existing tests plus the new test pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/daily/screens/daily_launch_overlay.dart test/features/daily/daily_launch_overlay_loading_gate_test.dart
git commit -m "fix(daily-launch): gate claim CTA on rewards reload to keep UI day == RPC day

Without this, the overlay rendered the day strip + Day-N highlight
from whatever was in local SharedPrefs at first paint, even if the
provider's reload() (which reconciles from server) had not yet
returned. A user reported seeing 'Day 2' highlighted but receiving
the Day 4 streak-freeze reward on claim. The cause is the server's
current_day having advanced ahead of the local cache. We now render
a SakinaLoader on Step 1 until _rewardsLoaded flips true, then show
the strip + Claim button with fresh state.
Pinned by daily_launch_overlay_loading_gate_test."
```

---

## Task 4: iOS simulator smoke test with mocked Supabase

**Why mocked instead of real backend:** The widget tests in Task 3 already exercise the logic. What we still want is proof that the same widget *renders correctly on iOS Metal* and that real device timing (animation frames, scheduler, platform channels for SharedPreferences) doesn't expose a latent bug. We achieve that by running `integration_test` on a booted iOS simulator with `FakeSupabaseSyncService` wired in via `ProviderScope.overrides` — no test account, no flakes, no third-party SDK init.

**Files:**
- Modify: `pubspec.yaml`
- Create: `integration_test/daily_launch_overlay_smoke_test.dart`
- Create: `integration_test/README.md`

- [ ] **Step 1: Add the `integration_test` package** — `pubspec.yaml`

Locate the `dev_dependencies:` block (around line 69) and insert directly after `flutter_test:`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  integration_test:
    sdk: flutter

  flutter_lints: ^5.0.0
```

- [ ] **Step 2: Run `flutter pub get`**

Run: `flutter pub get`
Expected: dependency resolves cleanly. If you see a version conflict against `flutter_localizations`/`intl`, that means the SDK constraint is wrong — confirm `sdk: ^3.6.0` in `environment:` block.

- [ ] **Step 3: Create the simulator smoke test** — `integration_test/daily_launch_overlay_smoke_test.dart`

This test mounts `DailyLaunchOverlay` directly inside a `ProviderScope` on the real iOS simulator, with a `FakeSupabaseSyncService` swapped in via `SupabaseSyncService.debugSetInstance`. It exercises the same two scenarios as the widget tests but runs on iOS, validating that the loader gate, strip rendering, and Claim → success flow all behave correctly with the real Flutter engine and SharedPreferences plugin.

```dart
// iOS simulator smoke test for the daily-launch overlay fixes.
//
// HOW TO RUN:
//   1. Boot an iOS simulator: xcrun simctl boot 'iPhone 16 Pro'
//   2. flutter test integration_test/daily_launch_overlay_smoke_test.dart \
//        -d <booted_simulator_id> \
//        --dart-define-from-file=env.json
//
// This test does NOT hit real Supabase. It uses FakeSupabaseSyncService
// via debugSetInstance to mock all server calls. It runs on iOS to verify
// the widgets render and animate correctly on iOS Metal + the real
// SharedPreferences plugin channel — the host `flutter test` only proves
// the logic, not the platform-channel-level behavior.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/sakina_loader.dart';

// Import the FakeSupabaseSyncService from the test support directory. We
// expose it to integration_test via a tiny re-export to avoid duplicating
// the 200-line fake. See integration_test/support/fake_sync_export.dart.
import 'support/fake_sync_export.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    resetLaunchGateMemoryGuard();
    fakeSync = FakeSupabaseSyncService(userId: 'sim-user');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugLaunchGateClock = () => DateTime.utc(2026, 5, 12, 14, 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugLaunchGateClock = () => DateTime.now().toUtc();
  });

  testWidgets(
    '[iOS] pending claim renders Day 3 highlight and survives a real claim tap',
    (tester) async {
      fakeSync.rows['user_daily_rewards:sim-user'] = {
        'user_id': 'sim-user',
        'current_day': 2,
        'last_claim_date': '2026-05-11',
        'streak_freeze_owned': false,
      };
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
        'day': 3,
        'tokens_awarded': 15,
        'scrolls_awarded': 0,
        'earned_streak_freeze': false,
        'earned_tier_up_scroll': false,
        'already_claimed': false,
        'current_day': 3,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': false,
        'token_balance': 15,
        'scroll_balance': 0,
        'is_premium': false,
        'multiplier': 1,
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DailyLaunchOverlay()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 0 → streak greeting visible on iOS.
      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      // Pump exactly one frame so we can catch the loader before reload resolves.
      await tester.pump();
      expect(find.byType(SakinaLoader), findsWidgets,
          reason: 'loader gate visible on iOS render path');

      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Day 3 reward'), findsOneWidget);
      expect(find.text('Claim Reward'), findsOneWidget);

      await tester.tap(find.text('Claim Reward'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Reward Claimed!'), findsOneWidget);
      // Pre-claim Day 3 → post-claim message must reference Day 4.
      expect(find.textContaining('Day 4'), findsWidgets);
    },
  );

  testWidgets(
    '[iOS] reinstall + server says claimed today => Step 0 dismisses without exposing Claim',
    (tester) async {
      fakeSync.rows['user_daily_rewards:sim-user'] = {
        'user_id': 'sim-user',
        'current_day': 4,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': true,
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: DailyLaunchOverlay()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Begin'), findsOneWidget);
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The overlay must dismiss without ever exposing the Claim CTA.
      expect(find.text('Claim Reward'), findsNothing);
    },
  );
}
```

- [ ] **Step 4: Create the support shim** — `integration_test/support/fake_sync_export.dart`

```dart
// Re-export FakeSupabaseSyncService from test/support so the integration
// test can use the same fake the unit/widget tests use, without duplicating
// the implementation. Dart's package layout disallows importing from
// `test/` into `integration_test/` directly, so we relativize the path.
export '../../test/support/fake_supabase_sync_service.dart';
```

- [ ] **Step 5: Document how to run the smoke test** — `integration_test/README.md`

```markdown
# Integration tests (iOS simulator smoke)

These tests run on a real iOS simulator using `integration_test` + a mocked
Supabase backend (`FakeSupabaseSyncService` via `debugSetInstance`). They
verify the same logic as the host-level widget tests but on the iOS Metal
render path + real platform channels.

## Prerequisites

1. Xcode + an iOS simulator available.
2. `flutter pub get` after adding the `integration_test` dev dependency.

## Running

```bash
# Boot a simulator
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true

# Get its UDID
SIM_ID=$(xcrun simctl list devices booted -j | python3 -c \
  'import json,sys; d=json.load(sys.stdin); print([v[0]["udid"] for v in d["devices"].values() if v][0])')

# Run smoke test
flutter test integration_test/daily_launch_overlay_smoke_test.dart \
  -d "$SIM_ID" \
  --dart-define-from-file=env.json
```

## What's covered here vs. unit/widget tests

| Scenario                                  | Layer                                    |
| ----------------------------------------- | ---------------------------------------- |
| UTC marker correctness                    | unit (`test/services/...utc_test.dart`)  |
| Reinstall suppression logic               | unit (`test/services/...reinstall_test`) |
| Loading-gate widget behavior (host)       | widget (`test/features/daily/...`)       |
| Loading-gate + claim on iOS Metal         | **this directory**                       |
| Real Supabase round-trip + UX             | manual (`docs/qa/plans/...manual-qa.md`) |

The full real-backend end-to-end is intentionally not automated — see
`docs/qa/plans/2026-05-12-daily-launch-overlay-manual-qa.md` for the
MCP-driven manual script that exercises the live stack.
```

- [ ] **Step 6: Run the smoke test on a booted simulator**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
SIM_ID=$(xcrun simctl list devices booted -j | python3 -c \
  'import json,sys; d=json.load(sys.stdin); print([v[0]["udid"] for v in d["devices"].values() if v][0])')
flutter test integration_test/daily_launch_overlay_smoke_test.dart \
  -d "$SIM_ID" \
  --dart-define-from-file=env.json
```

Expected: 2 passing tests on iOS. If the test cannot find a booted simulator, the error is `No supported devices connected.` — boot one and retry.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock integration_test/
git commit -m "test(daily-launch): iOS simulator smoke test with mocked Supabase

Runs the same widget-level scenarios as Task 3 but on a real iOS
simulator via integration_test. Uses FakeSupabaseSyncService through
debugSetInstance so we get iOS render path + real platform channels
without the flakiness of real Supabase auth + RevenueCat/OneSignal/
Mixpanel init. Real-backend end-to-end is covered by the manual MCP
plan, not automated here."
```

---

## Task 5: Manual MCP-driven simulator QA pass

**Files:**
- Create: `docs/qa/plans/2026-05-12-daily-launch-overlay-manual-qa.md`

- [ ] **Step 1: Write the QA script** — `docs/qa/plans/2026-05-12-daily-launch-overlay-manual-qa.md`

```markdown
# Daily Launch Overlay — Manual QA Verification (2026-05-12)

Run this manually against a physical iOS device OR the simulator via
`mcp__ios-simulator__*` tools. Each scenario reproduces a user-reported
symptom and asserts the post-fix behavior.

## Setup

1. Test account: `yoyoyo@gmail.com` (or a fresh disposable account).
2. Reset server state via SQL:
   ```sql
   update public.user_daily_rewards
   set current_day = 0, last_claim_date = null, streak_freeze_owned = false
   where user_id = '<uid>';
   ```
3. Boot iOS simulator: `mcp__ios-simulator__open_simulator`,
   `mcp__ios-simulator__get_booted_sim_id`.

## Scenario A — Same-day reinstall, already claimed

**Repro of:** "It constantly shows up even if I already have claimed the reward
for that day, usually when I delete and then reinstall."

1. Build + install the app: `flutter run --dart-define-from-file=env.json`.
2. Sign in, complete onboarding, claim today's reward (Day 1).
3. `mcp__ios-simulator__ui_tap` Home button, force-close the app.
4. Uninstall: `xcrun simctl uninstall <sim_id> com.sakina.app`.
5. Reinstall + relaunch: `mcp__ios-simulator__install_app` then
   `mcp__ios-simulator__launch_app`.
6. Sign in. Wait for hydration.

**Expected (post-fix):** No "Daily Reward" overlay appears. Home screen renders directly.

**Take screenshot:** `mcp__ios-simulator__screenshot` — attach to QA log.

## Scenario B — Day shown matches day claimed

**Repro of:** "It showed Day 2 but I claimed the reward of Day 4."

1. Reset server: `current_day = 2`, `last_claim_date = <UTC yesterday>`.
2. Wipe local: uninstall + reinstall the app.
3. Sign in. When the overlay appears, tap "Begin".
4. On the rewards screen, **before tapping Claim**, take a screenshot
   showing the highlighted day chip and the "Day N reward" string.
5. Tap Claim. Observe the "Reward Claimed!" success card.

**Expected (post-fix):** Pre-claim screen highlights **Day 3** and reads
"Day 3 reward". Post-claim success card and "Come back tomorrow for Day 4"
both reference Day 3 / Day 4 — never Day 1 / Day 2.

## Scenario C — UTC midnight cross-over

**Repro of:** "Overlay re-fires the morning after I claimed late at night."

1. Set the simulator clock manually to a local time where local date and
   UTC date disagree. Simulator > Features > Time > Custom: set device to
   `2026-05-12 23:30` in a UTC-5 timezone (so UTC is already `2026-05-13`).
2. Open app. Claim today's reward.
3. Force-close.
4. Advance the simulator clock to `2026-05-13 00:15` local (UTC `2026-05-13
   05:15` — same UTC day).
5. Cold-launch the app.

**Expected (post-fix):** No overlay re-fires — marker was stored as UTC
`2026-05-13`, today's marker is still UTC `2026-05-13`, gate skips. Take a
screenshot of the home screen on first paint.

## Sign-off checklist

- [ ] Scenario A — no overlay on same-day reinstall after claim
- [ ] Scenario B — pre-claim Day == post-claim Day == server day
- [ ] Scenario C — no re-fire across local midnight when same UTC day

Attach screenshots and the timestamps of each step to
`docs/qa/runs/2026-05-12-daily-launch-overlay-manual-qa.md`.
```

- [ ] **Step 2: Execute the QA script via MCP**

For each scenario A/B/C in the manual script, drive it with the
`mcp__ios-simulator__*` tools:
- `mcp__ios-simulator__get_booted_sim_id`
- `mcp__ios-simulator__screenshot` after every state transition
- `mcp__ios-simulator__ui_tap` / `mcp__ios-simulator__ui_type` to drive sign-in and overlay interactions
- `mcp__supabase__execute_sql` to reset state between runs

Save artifacts to `docs/qa/runs/2026-05-12-daily-launch-overlay-manual-qa.md`
(create the file as you go — paste each screenshot path, the resulting state
from a SQL select, and a 1-line PASS/FAIL note per scenario).

- [ ] **Step 3: Commit the QA script + run log**

```bash
git add docs/qa/plans/2026-05-12-daily-launch-overlay-manual-qa.md docs/qa/runs/2026-05-12-daily-launch-overlay-manual-qa.md
git commit -m "docs(qa): manual MCP-driven simulator script + run log for daily-launch overlay fix"
```

---

## Final verification

- [ ] **Step 1: Run the full Flutter test suite**

Run: `flutter test`
Expected: All tests pass. Pay attention to any test in `test/features/daily/`,
`test/services/launch_gate*`, and `test/services/daily_rewards*`.

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`
Expected: No new errors or warnings beyond the ~54 pre-existing infos noted
in CLAUDE.md / MEMORY.md.

- [ ] **Step 3: Cross-check against the original report**

For yoyoyo@gmail.com (`cdbc2545-96e7-4e19-b739-401f2694465c`):
- Reset their cache by signing out + back in on simulator.
- Confirm overlay does NOT re-fire after the claim recorded today
  (`current_day = 4`, `last_claim_date = 2026-05-12`).
- Run a fresh delete+reinstall and confirm Scenario A passes.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 2 issues found, both resolved: Task 4 trimmed to mocked-provider iOS smoke test; widget test extended to assert post-claim Day matches |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — ready to implement
