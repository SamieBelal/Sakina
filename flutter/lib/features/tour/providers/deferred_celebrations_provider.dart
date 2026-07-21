import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/achievements_service.dart' show Achievement;
import '../../../services/xp_service.dart' show XpState, LevelUpRewards;
import '../../quests/providers/quests_provider.dart' show Quest;
import 'onboarding_tour_controller.dart';

/// A celebration that was withheld while the guided tour was running, to be
/// replayed sequentially once the user lands back on a normal app screen.
///
/// During the forced onboarding tour, gamification celebrations (rank-ups,
/// achievement + quest toasts, the First Steps bundle) would otherwise pop on
/// top of the tour and interrupt the coachmark flow — the tour route observer
/// treats the modal ones as blocking, so the next coachmark can't reveal until
/// the user dismisses them. We enqueue them here instead and drain the queue on
/// the first home arrival after the tour (and its trailing paywall) clears.
sealed class DeferredCelebration {
  const DeferredCelebration();
}

/// Rank-up modal ([LevelUpOverlay]). Carries the snapshot needed to render it.
class LevelUpCelebration extends DeferredCelebration {
  const LevelUpCelebration(this.xpState, this.rewards);
  final XpState xpState;
  final LevelUpRewards rewards;
}

/// First Steps bundle completion modal ([FirstStepsOverlay]).
class FirstStepsCelebration extends DeferredCelebration {
  const FirstStepsCelebration({required this.tokens, required this.scrolls});
  final int tokens;
  final int scrolls;
}

/// A quest-completion toast (standard or beginner).
class QuestToastCelebration extends DeferredCelebration {
  const QuestToastCelebration(this.quest);
  final Quest quest;
}

/// An achievement-unlock toast.
class AchievementToastCelebration extends DeferredCelebration {
  const AchievementToastCelebration(this.achievement);
  final Achievement achievement;
}

/// A streak-milestone celebration ([StreakMilestoneOverlay]) that was withheld
/// because the user backed out of BeatRevealFlow (tapped the left zone at beat 0
/// → onReturnHome) before tapping "Ameen" / calling completeDeeper(). The
/// `ref.listen` in muhasabah_screen only fires the overlay on the
/// `deeper → completed` transition, which never happens on back-out. We enqueue
/// here instead so the Home screen drains and shows it as the next flourish.
class StreakMilestoneCelebration extends DeferredCelebration {
  const StreakMilestoneCelebration({
    required this.streak,
    required this.xp,
    required this.scrolls,
  });
  final int streak;
  final int xp;
  final int scrolls;
}

/// FIFO queue of celebrations withheld during the tour. Order is preserved so
/// the drain can replay chronologically; the drainer separates modals (shown
/// one-at-a-time, awaited) from ambient toasts.
class DeferredCelebrationsNotifier
    extends StateNotifier<List<DeferredCelebration>> {
  DeferredCelebrationsNotifier() : super(const []);

  void enqueue(DeferredCelebration celebration) {
    state = [...state, celebration];
  }

  /// Returns everything queued and clears the queue atomically, so a drain
  /// can't double-present if it's triggered again mid-flight.
  List<DeferredCelebration> takeAll() {
    if (state.isEmpty) return const [];
    final items = state;
    state = const [];
    return items;
  }
}

final deferredCelebrationsProvider = StateNotifierProvider<
    DeferredCelebrationsNotifier,
    List<DeferredCelebration>>((ref) => DeferredCelebrationsNotifier());

/// True while celebrations must be withheld — i.e. the guided tour is actively
/// running. Read at every celebration push site; when false the celebration
/// shows immediately, exactly as before.
bool shouldDeferCelebrations(WidgetRef ref) =>
    ref.read(onboardingTourControllerProvider).isActive;
