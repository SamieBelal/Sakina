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
import '../../../core/theme/app_typography.dart';
import '../content/help_chips.dart';
import '../content/intake_questions.dart';
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

  /// The queue as rendered: the hook's pair, then the five the user's
  /// "what would help most" selections blend into (Wave H — this replaced the
  /// single aspiration answer).
  ///
  /// The pair is passed as `exclude` rather than trusted to be disjoint: the
  /// chip sequences are disjoint from every APPROVED deck pair, but a
  /// `sakina://reel/?name_ids=` deep link can supply an arbitrary pair, and a
  /// duplicate id would make `seed_name_queue` raise a check violation on a
  /// user we cannot reproduce.
  ///
  /// An unresolved pair yields the blended rows alone — the plan screen
  /// promises exactly what it can name, and the seed path (which can await the
  /// comfort-pair fallback) is what makes the queue whole.
  static List<int> plannedQueueNameIds({
    required List<int> pairNameIds,
    required List<String> helpWith,
  }) =>
      [
        if (pairNameIds.length == 2) ...pairNameIds,
        ...helpChipsQueueNameIds(
          helpWith,
          exclude: pairNameIds.length == 2 ? pairNameIds.toSet() : const {},
        ),
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
      helpWith: state.helpWith,
    );
    // One stamp for arriving, one per queued Name — 8 in the whole path, and
    // the two already earned are both things the user actually did.
    final totalStamps = queue.length + 1;
    final earnedStamps = hasPair ? 2 : 1;
    final projection = namesKnownProjectionLine(state.namesKnown);

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
                      // H3's consequence. Deliberately quiet and high: it is a
                      // reassurance, not a claim, and it answers the question
                      // the user was actually asked ("have you told anyone?")
                      // before the screen starts promising things.
                      const SizedBox(height: AppSpacing.sm),
                      _ConsequenceLine(toldAnyonePlanLine(state.toldAnyone)),
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
                      // H4's consequence — THE PROJECTION, and the one claim on
                      // this screen that earns emphasis. It is the Cal AI shape
                      // ("in X time you will be Y") kept the safe side of the
                      // reverence line by promising the USER's own knowledge
                      // rather than anything about Allah's response. Null when
                      // H4 was unanswered: a baseline we did not ask for would
                      // be invented, and this screen's whole value is that
                      // every line on it is verifiable tomorrow.
                      if (projection != null) ...[
                        Text(
                          projection,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      JourneyStampTrack(
                        totalStamps: totalStamps,
                        earnedStamps: earnedStamps,
                        caption: _stampCaption(earnedStamps),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // H6 then H2: how each day will feel, and when it will
                      // arrive. Grouped because they answer one question
                      // together, and kept quiet so the projection above stays
                      // the thing the eye lands on.
                      _ConsequenceLine(dailyTimePacingLine(state.dailyTime)),
                      const SizedBox(height: AppSpacing.xs),
                      _ConsequenceLine(heaviestPlanLine(state.heaviestTime)),
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

/// One quiet consequence line on the plan screen.
///
/// Wave H's governing constraint is that every intake answer surfaces
/// somewhere — a question whose answer never appears is extractive, and a
/// longer extractive form is worse than the three questions we had before. This
/// is the shared treatment for the three supporting ones (H2, H3, H6); H4's
/// projection is deliberately NOT one of these, because it is the screen's
/// single emphasised claim.
class _ConsequenceLine extends StatelessWidget {
  const _ConsequenceLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.bodyMedium.copyWith(
        height: 1.45,
        color: AppColors.textSecondaryLight,
      ),
    );
  }
}
