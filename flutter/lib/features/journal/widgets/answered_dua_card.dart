import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';

/// E3 — *"You asked for this four months ago."*
///
/// Design §7 calls this the single highest-emotion mechanic available to a
/// Muslim app, and the brief that came with it was that it must not feel like a
/// task. Everything about this widget is that constraint made concrete:
///
///   * **two actions of equal weight.** *"Not yet"* is a plain word next to the
///     primary, not a greyed-out escape. A card with one button is a chore, and
///     a card that makes the negative answer hard to give is worse than one that
///     never asked;
///   * **the footer says nothing is owed**, in those words, so the card cannot
///     be read as an item to clear;
///   * **no counter, no badge, no progress.** The host shows one of these at a
///     time or none, and there is nowhere in the app that says how many are
///     waiting — because none of them are waiting;
///   * **it never says the duʿā *was* answered.** It asks. The claim, when it is
///     made, is the user's.
class AnsweredDuaCard extends StatelessWidget {
  const AnsweredDuaCard({
    required this.prompt,
    required this.onAnswered,
    required this.onNotYet,
    super.key,
  });

  final AnsweredDuaPrompt prompt;

  /// The user marks it answered.
  final VoidCallback onAnswered;

  /// The user says not yet — a local snooze, nothing more.
  final VoidCallback onNotYet;

  @override
  Widget build(BuildContext context) {
    final need = prompt.dua.need.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_3_outlined,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  JournalResurfacingCopy.askedAgo(prompt.elapsedLabel),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (need.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              '"$need"',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Wrap, not Row: the primary label is a full sentence and the two
          // actions must never be allowed to squeeze each other into ellipses —
          // "Not yet" reading as "Not y…" is exactly the kind of pressure this
          // card is not allowed to apply.
          Wrap(
            spacing: AppSpacing.sm + 4,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Action(
                label: JournalResurfacingCopy.answeredAction,
                primary: true,
                onTap: onAnswered,
              ),
              _Action(
                label: JournalResurfacingCopy.notYetAction,
                primary: false,
                onTap: onNotYet,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            JournalResurfacingCopy.answeredFooter,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: primary ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: primary
                ? null
                : Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: primary ? Colors.white : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
