import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/card_collection_service.dart';
import '../../streaks/models/companion_state.dart';
import '../../streaks/providers/cosmetics_ui_providers.dart';
import '../../streaks/widgets/companion_medallion.dart';
import '../content/aspirations.dart';
import '../content/carrying_durations.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/journey_stamp_track.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/queue_name_row.dart';
import '../widgets/queue_plan_header.dart';

/// The reel flow's plan screen (One Ship W2-D2) — the real queue, not a
/// "crafted for you" tile.
///
/// Every row on this screen is a row `seed_name_queue` will write: positions
/// 1-2 are the pair the hook resolved, 3-7 are the aspiration answer's
/// founder-reviewed ordering. That is the whole point of replacing the legacy
/// plan screen — the promise here is verifiable tomorrow.
///
/// The derivation mirrors `OnboardingNotifier.queueNameIdsFor` without its
/// async pair resolution: a screen must not block a frame on an asset read, so
/// this one renders the pair it is given and veils the rest. The two are pinned
/// equal by `queue_plan_screen_test.dart`; if a later wave makes the notifier's
/// version reachable synchronously, delete this copy and call it.
class QueuePlanScreen extends ConsumerWidget {
  const QueuePlanScreen({
    required this.onNext,
    this.onBack,
    this.revealedPairNameIds,
    super.key,
  });

  static const String headlineLabel = 'The Names ahead of you';

  /// The tier the onboarding reveal awards — deterministic Silver (plan review
  /// blocker 1). Shown on the met row so the plan screen and the card the user
  /// just watched land can never disagree.
  static const CardTier revealTier = CardTier.silver;

  final VoidCallback onNext;
  final VoidCallback? onBack;

  /// `[name₁, name₂]` as the reveal actually showed them, when that is not what
  /// the hook resolved.
  ///
  /// The reveal falls back to the comfort pair whenever either half has no
  /// approved deck, and `completeOnboarding` resolves against that same
  /// fallback — so a plan screen reading only `pairNameIds` would name two rows
  /// the queue will not hold (or veil two it will). Wave E passes
  /// `OnboardingState.revealedPairNameIds` straight through: the reveal writes
  /// it via `setRevealedPair` in its `onDone`, so this screen, the card the
  /// user watched land, `starter_name_id` and the seeded queue head all read
  /// one value.
  ///
  /// Anything that is not exactly two ids — null, empty (the reveal has not run
  /// yet, or this is a kill-switch flow) — means the hook's own pair is the
  /// truth.
  final List<int>? revealedPairNameIds;

  /// The queue as rendered: the hook's pair, then the aspiration's five.
  ///
  /// An unresolved pair yields the aspiration rows alone — the plan screen
  /// promises exactly what it can name, and the seed path (which can await the
  /// comfort-pair fallback) is what makes the queue whole.
  static List<int> plannedQueueNameIds({
    required List<int> pairNameIds,
    required String? aspiration,
  }) =>
      [
        if (pairNameIds.length == 2) ...pairNameIds,
        ...aspirationQueueNameIds(aspiration),
      ];

  /// The catalog entry for [id], or null when the id is not in the catalog.
  static CollectibleName? collectibleNameById(int id) {
    for (final name in allCollectibleNames) {
      if (name.id == id) return name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final revealed = revealedPairNameIds;
    final pairNameIds =
        revealed != null && revealed.length == 2 ? revealed : state.pairNameIds;
    final hasPair = pairNameIds.length == 2;
    final queue = plannedQueueNameIds(
      pairNameIds: pairNameIds,
      aspiration: state.aspiration,
    );
    // One stamp for arriving, one per queued Name — 8 in the whole path, and
    // the two already earned are both things the user actually did.
    final totalStamps = queue.length + 1;
    final earnedStamps = hasPair ? 2 : 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header and track scroll WITH the rows. Pinned above a scrolling
              // list they cost fixed vertical space that grows with the text
              // scale, and at the accessibility sizes (2x-3x) that left the
              // rows nothing to render into. Only the continue button stays
              // pinned — an action the user must always be able to reach.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QueuePlanHeader(
                        headline: headlineLabel,
                        // The carrying-duration answer's visible consequence
                        // (§G4).
                        pacingLine: carryingPacingLine(state.carryingDuration),
                        onBack: onBack,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // The lantern heads the track it is already bound to
                      // (Wave G): the stamps ARE the streak, and the streak is
                      // what drives its brightness. `endowedDim` is the honest
                      // state here — arrived, nothing acted on yet — and it is
                      // the same state the home screen will show them in a
                      // moment, so the hand-off has no discontinuity.
                      // ambient:false: cream surface.
                      Center(
                        child: Consumer(
                          builder: (_, ref, __) => CompanionMedallion(
                            state: const CompanionState(
                              brightness: CompanionBrightness.endowedDim,
                              protected: false,
                            ),
                            size: 104,
                            ambient: false,
                            skin: ref.watch(renderableLanternSkinProvider),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      JourneyStampTrack(
                        totalStamps: totalStamps,
                        earnedStamps: earnedStamps,
                        caption: _stampCaption(earnedStamps),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ..._rows(queue, hasPair),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OnboardingContinueButton(
                label: AppStrings.continueButton,
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stampCaption(int earnedStamps) => earnedStamps >= 2
      ? 'Two already: arriving, and the Name you met.'
      : 'One already: arriving.';

  List<Widget> _rows(List<int> queue, bool hasPair) {
    final rows = <Widget>[];
    for (var i = 0; i < queue.length; i++) {
      final name = collectibleNameById(queue[i]);
      // Positions 1-2 are the pair, and only they are named here. A pair id
      // that is not in the catalog falls through to a veiled row rather than
      // rendering an empty one.
      final Widget row;
      if (name != null && hasPair && i == 0) {
        row = QueueNameRow.met(name: name, tierLabel: revealTier.label);
      } else if (name != null && hasPair && i == 1) {
        row = QueueNameRow.next(name: name);
      } else {
        // A veiled row has no Name to announce, so its position in the queue is
        // the only thing a screen reader can say about it.
        row = QueueNameRow.veiled(position: i + 1, total: queue.length);
      }
      if (i > 0) rows.add(const SizedBox(height: AppSpacing.sm + 2));
      rows.add(
        row
            .animate()
            .fadeIn(duration: 350.ms, delay: (90 * i).ms)
            .slideY(begin: 0.04, end: 0, duration: 350.ms),
      );
    }
    return rows;
  }
}
