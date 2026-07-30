import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/daily_rewards_service.dart';

/// The daily reward, celebrated **after** the work (W4 Wave 4 — spec M1/§6).
///
/// This used to be the second step of the day-open: a strip, a highlight and a
/// "Claim Reward" button the user tapped before doing anything at all. No
/// verified comparable app gates the day's reward before the day's action, and
/// we did. So the ceremony moved here, behind "Ameen".
///
/// **The grant is not here, and must not move here.** `claimDailyReward()` fires
/// at answer-submit (Wave 3), because `claim_daily_reward` is a 7-day escalating
/// ladder that resets to day 0 on a single missed claim — tying the grant to the
/// last tap of the beat flow would cost a day-6 user their ladder for not
/// tapping through every beat. The rule across the wave is **grant at
/// engagement, celebrate at completion**, and this widget is only the second
/// half. It renders what already happened.
///
/// Renders nothing at all when there is no result to show, or when the claim was
/// a replay (`alreadyClaimed`) — celebrating a grant that did not happen would
/// teach the user the ceremony is decorative.
class DailyRewardCeremony extends StatelessWidget {
  const DailyRewardCeremony({required this.result, super.key});

  final DailyRewardClaimResult? result;

  bool get _hasSomethingToSay {
    final r = result;
    if (r == null || r.alreadyClaimed) return false;
    return r.tokensAwarded > 0 ||
        r.scrollsAwarded > 0 ||
        r.earnedStreakFreeze ||
        r.earnedTierUpScroll;
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (!_hasSomethingToSay || r == null) return const SizedBox.shrink();

    final earned = <String>[
      if (r.tokensAwarded > 0) '${r.tokensAwarded} tokens',
      if (r.scrollsAwarded > 0)
        '${r.scrollsAwarded} ${r.scrollsAwarded == 1 ? 'scroll' : 'scrolls'}',
      if (r.earnedStreakFreeze) 'a streak freeze',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Day ${r.day}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // Past tense on purpose: the grant landed when they answered. This
            // is an acknowledgement, not an offer, and nothing here is tappable
            // — there is no second thing to collect.
            _sentenceFor(earned),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 250.ms)
        .scaleXY(begin: 0.94, end: 1.0, duration: 400.ms, delay: 250.ms);
  }

  String _sentenceFor(List<String> earned) {
    if (earned.isEmpty) return 'Your daily reward is yours.';
    if (earned.length == 1) return 'You earned ${earned.first}.';
    final last = earned.removeLast();
    return 'You earned ${earned.join(', ')} and $last.';
  }
}
