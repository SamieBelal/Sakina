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
import '../widgets/onboarding_page_wrapper.dart';
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
///
/// **Where the other intake answers went (founder, 2026-07-29).** This screen
/// used to carry a consequence line each for H2 (heaviest hour), H3 (told
/// anyone) and H6 (daily time), on Wave H's rule that an answer which never
/// surfaces makes the question extractive. Read on a device, five stacked grey
/// paragraphs buried the one thing the screen exists to show — the queue — so
/// they were cut to the single H1 subline plus H4's projection.
///
/// The rule is not repealed, it is unpaid: **H2, H3 and H6 now surface nowhere
/// in the product.** All three are persisted, and W3 already plans to read
/// `heaviestTime` and `dailyTime` as AI context (see the note at
/// `onboarding_provider.dart:318`) — that is where the debt should be settled,
/// not by putting the paragraphs back.
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

    return OnboardingPageWrapper(
      // The plan is a STEP, not a standalone artifact (founder, 2026-07-29).
      // It previously built its own bare `Scaffold`, so it was the only page in
      // the flow with no progress bar, a naked chevron instead of the back
      // circle, and its own padding — which is precisely why it "didn't look
      // like the rest of them". Everything below is now the wrapper's.
      progressSegment: onboardingReelPlanSegment,
      totalSegments: onboardingReelTotalSegments,
      showBack: onBack != null,
      onBack: onBack ?? () {},
      // Matches every question screen (`ReelContinueQuestion` /
      // `ReelSingleTapQuestion` pass the same), so the headline lands on the
      // identical baseline as the page before it. The wrapper's xxl default put
      // this one 16pt lower than its neighbours.
      contentTopPadding: AppSpacing.xl,
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
                    // The carrying-duration answer's visible consequence (§G4),
                    // and the screen's ONLY subline (founder, 2026-07-29).
                    pacingLine: carryingPacingLine(state.carryingDuration),
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
                        // 88, not 104: the lamp sits between the headline and
                        // the projection, and at 104 its halo crowded both.
                        size: 88,
                        ambient: false,
                        skin: ref.watch(renderableLanternSkinProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // H4's consequence — THE PROJECTION, and the one claim on
                  // this screen that earns emphasis. It is the Cal AI shape
                  // ("in X time you will be Y") kept the safe side of the
                  // reverence line by promising the USER's own knowledge
                  // rather than anything about Allah's response. Null when
                  // H4 was unanswered: a baseline we did not ask for would
                  // be invented, and this screen's whole value is that
                  // every line on it is verifiable tomorrow.
                  //
                  // Left-aligned and stepped up to headlineSmall: it is the one
                  // thing on the page that should out-weigh the queue, and
                  // centring it was half of why the screen read as ransom-note
                  // typography — headline left, this centred, the rows left.
                  if (projection != null) ...[
                    Text(
                      projection,
                      // headlineMedium (20/w600), between the 24/w700 headline
                      // and 15pt body: emphasised enough to be the thing the
                      // eye lands on, not so large it argues with the title.
                      style: AppTypography.headlineMedium.copyWith(
                        height: 1.35,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  // No caption: "2 of 8 steps" sits directly under the bar and
                  // says in four words what the old caption ("Two already:
                  // arriving, and the Name you met.") spent a full line on.
                  JourneyStampTrack(
                    totalStamps: totalStamps,
                    earnedStamps: earnedStamps,
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
    );
  }

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

