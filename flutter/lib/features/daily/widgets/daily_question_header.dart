import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The daily question's title.
///
/// Marked `header: true` so VoiceOver announces the question first and a rotor
/// jump lands on it. Latin script throughout, so no `Text` here mixes
/// directions.
///
/// **The taught gloss is gone** (density pass, founder 2026-07-30). This used
/// to render `DailyQuestionCopy.gloss` under the title — teaching muḥāsabah one
/// line beneath the question. The home CTA the user tapped a second earlier
/// already teaches the same word (`DailyLoopCtaCopy.notStartedGloss`), so the
/// definition appeared on two consecutive screens, and this was the copy the
/// user had least earned: it arrives before they have done anything at all.
///
/// The rule it was built to satisfy has not changed and still holds — the word
/// is taught as a gloss and is never a button label (plan §4, Hallow's
/// treatment of Lectio Divina and the Examen). It is simply taught once, on the
/// surface that earned it, rather than twice in four seconds.
class DailyQuestionHeader extends StatelessWidget {
  const DailyQuestionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: AppTypography.headlineMedium.copyWith(
          color: AppColors.sacredInk,
          height: 1.25,
        ),
      ),
    );
  }
}
