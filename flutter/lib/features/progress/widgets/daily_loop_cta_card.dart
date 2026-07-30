import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/progress/widgets/daily_loop_completed_card.dart';

/// Which face the home CTA is wearing.
enum DailyLoopCtaState {
  /// Nothing done today. Also the state a user lands in after Wave 2's
  /// "Not right now" defer — the loop is still live and this card is the only
  /// way back into it, so it has to read as an invitation, not a leftover.
  notStarted,

  /// Started but not finished (mid-reflection, app backgrounded, etc).
  inProgress,

  /// Today's muḥāsabah is done — see [DailyLoopCompletedCard].
  completed,
}

/// The home screen's primary daily CTA.
///
/// **Why this is a card and not a row (W4 Wave 5).** It used to live inside the
/// dashboard card as one 20px icon + 13px label row between two 1px dividers —
/// the identical rhythm to Quests, Anchor Names and Daily Rewards. Saturation
/// was never the problem: it was already the only filled control on the page.
/// Rhythm was. Sharing a divider stack with three navigation rows makes the
/// purpose of the app read as the fourth item in a settings list, and pushed its
/// top edge ~800px down a ~700-760px viewport. So it leaves the stack entirely,
/// sits directly under the greeting, and is sized by type scale and area rather
/// than by more green.
///
/// **Naming.** "Begin Muḥāsabah" made the user learn a word before they could
/// find the button. The label is now the job; muḥāsabah is taught as a gloss
/// underneath it (Hallow's Examen treatment — jargon names the content, never
/// the primary daily CTA, and every unfamiliar term earns one plain line
/// stating the benefit).
///
/// Pure presentation: gating (`canUse`), the re-entry guard and navigation all
/// stay on the host screen, which is where the `_discoverInFlight` flag and the
/// cap sheet live.
class DailyLoopCtaCard extends StatelessWidget {
  const DailyLoopCtaCard({
    super.key,
    required this.state,
    required this.onStart,
    required this.onReroll,
    this.completedName,
  });

  final DailyLoopCtaState state;

  /// Enter the loop — used by [DailyLoopCtaState.notStarted] and
  /// [DailyLoopCtaState.inProgress].
  final VoidCallback onStart;

  /// Metered re-roll from the completed state. Host-side this is still gated by
  /// `canUse` and debounced by `_discoverInFlight`.
  final VoidCallback onReroll;

  /// Transliteration of the Name met today, shown in the completed state.
  /// Latin script only — never paired with Arabic inside one `Text`.
  final String? completedName;

  @override
  Widget build(BuildContext context) {
    if (state == DailyLoopCtaState.completed) {
      return DailyLoopCompletedCard(name: completedName, onReroll: onReroll);
    }
    final resuming = state == DailyLoopCtaState.inProgress;
    return _Invitation(
      title: resuming
          ? 'Pick up where you left off'
          : 'Name what you\'re carrying',
      gloss: resuming
          ? 'Your muḥāsabah is still open.'
          : 'Your daily muḥāsabah — a moment to check in with your heart.',
      icon: resuming
          ? Icons.play_circle_outline_rounded
          : Icons.favorite_outline_rounded,
      onTap: onStart,
    );
  }
}

/// The unfinished states. Emerald fill, because this is the one thing on the
/// screen the user came to do.
class _Invitation extends StatelessWidget {
  const _Invitation({
    required this.title,
    required this.gloss,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String gloss;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $gloss',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              // Generous by intent (DESIGN.md whitespace bias): the area is
              // half of what separates this from a list row.
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.md + 4,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gloss,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
