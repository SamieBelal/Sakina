import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/streaks/companion_state_mapper.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/services/streak_service.dart';

/// One atomic snapshot of the three companion inputs, read together so the
/// resolved [state] can never mix a stale freeze with a post-consume streak
/// (finding #8). Also carries [hydrated] so surfaces can show a neutral
/// placeholder until the streak cache has hydrated (avoids a returning user
/// flashing `endowedDim` on cold launch, when `lastActive` is transiently null).
class CompanionInputs {
  const CompanionInputs({
    required this.streak,
    required this.freezeOwned,
    required this.now,
    required this.hydrated,
  });

  final StreakState streak;
  final bool freezeOwned;
  final DateTime now;
  final bool hydrated;

  /// The resolved companion state for this snapshot, or `null` until the
  /// streak cache is hydrated (caller renders a placeholder).
  CompanionState? get state => hydrated
      ? resolveCompanionState(
          streak: streak, freezeOwned: freezeOwned, now: now)
      : null;
}

/// Composes the three inputs — `getStreak()`, the freeze bool, and `now` — into
/// a single consistent read. Rebuilds when the daily-rewards state changes (the
/// freeze source), which also fires post-hydration when the batch sync reloads
/// rewards.
final companionInputsProvider = FutureProvider<CompanionInputs>((ref) async {
  // Watch the freeze source so the shield overlay updates when a freeze is
  // bought/consumed. This is also the natural post-hydration rebuild trigger.
  final freezeOwned =
      ref.watch(dailyRewardsProvider.select((r) => r.streakFreezeOwned));
  final hydrated = ref.read(appSessionProvider).economyHydrated;

  final streak = await getStreak();
  return CompanionInputs(
    streak: streak,
    freezeOwned: freezeOwned,
    now: DateTime.now(),
    hydrated: hydrated,
  );
});

/// Convenience: just the resolved [CompanionState] (null while loading or
/// pre-hydration). Surfaces that only need the state watch this.
final companionStateProvider = Provider<CompanionState?>((ref) {
  return ref.watch(companionInputsProvider).maybeWhen(
        data: (inputs) => inputs.state,
        orElse: () => null,
      );
});
