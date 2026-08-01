import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/card_collection_service.dart';
import '../../daily/reveal/reveal_card_tile.dart';
import 'paywall_gate_page.dart';

/// Page 1 of the gate — `value_depth`.
///
/// The page echoes the Name the reveal just handed the user and names what
/// premium adds on top of it, keyed to the contract they chose on the hook
/// screen.
///
/// **The card is the real one.** [card] is rendered through
/// [revealCardTile] — the exact widget the reveal drew, at the exact tier it
/// awarded (a deterministic Silver: cool dark slate, silver metallics, gold
/// medallion ring). An approximation redrawn here would mean the screen asking
/// for trust contradicts the screen that earned it thirty seconds earlier.
class PaywallValueDepthPage extends StatelessWidget {
  const PaywallValueDepthPage({
    required this.nameTransliteration,
    required this.isSignContract,
    this.card,
    this.cardTier = CardTier.silver,
    super.key,
  });

  /// The transliteration of Name₁ — English letters only. It is deliberately
  /// NOT the Arabic: the headline is an English sentence, and Arabic inside it
  /// would bleed RTL into the rest of the line (CLAUDE.md critical rule).
  /// The Arabic lives inside [card], which renders it in its own RTL `Text`.
  final String? nameTransliteration;

  /// The `sign` hook contract ("I can't put it into words") gets its own
  /// wording — it must not claim the user named anything.
  final bool isSignContract;

  /// The awarded card. `null` (no resolvable Name) drops the art and the
  /// headline's Name clause rather than drawing a placeholder.
  final CollectibleName? card;
  final CardTier cardTier;

  @override
  Widget build(BuildContext context) {
    final name = nameTransliteration;
    final headline = name == null
        ? AppStrings.paywallPlanSelectHeadline
        : (isSignContract
                ? AppStrings.paywallValueDepthHeadlineSignTemplate
                : AppStrings.paywallValueDepthHeadlineTemplate)
            .replaceAll('{name}', name);
    final subline = isSignContract
        ? AppStrings.paywallValueDepthSublineSign
        : AppStrings.paywallValueDepthSubline;
    final bullets = <String>[
      isSignContract
          ? AppStrings.paywallValueDepthBullet1Sign
          : AppStrings.paywallValueDepthBullet1,
      isSignContract
          ? AppStrings.paywallValueDepthBullet2Sign
          : AppStrings.paywallValueDepthBullet2,
      AppStrings.paywallValueDepthBullet3,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        paywallEntry(
          context,
          0,
          Text(
            headline,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 10),
        paywallEntry(
          context,
          1,
          Text(
            subline,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        if (card != null)
          paywallEntry(
            context,
            2,
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xs,
              ),
              // Clamped small so the page still fits a 375×667 frame with the
              // three gains below it — the card is the proof, not the subject.
              child: Center(
                child: SizedBox(
                  width: 148,
                  child: revealCardTile(card!, cardTier),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < bullets.length; i++)
          paywallEntry(
            context,
            3 + i,
            Padding(
              padding: EdgeInsets.only(
                bottom: i == bullets.length - 1 ? 0 : AppSpacing.md,
              ),
              child: _GainRow(icon: _gainIcons[i], label: bullets[i]),
            ),
          ),
        const Spacer(),
      ],
    );
  }

  /// Decorative only — every row's meaning is carried by its text, and the
  /// glyphs are excluded from the semantics tree below.
  static const _gainIcons = <IconData>[
    Icons.auto_awesome_outlined,
    Icons.volunteer_activism_outlined,
    Icons.menu_book_outlined,
  ];
}

class _GainRow extends StatelessWidget {
  const _GainRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimaryLight,
                fontSize: 16,
                height: 1.42,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
