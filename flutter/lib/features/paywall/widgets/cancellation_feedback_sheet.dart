import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/cancellation_feedback_service.dart';

/// Optional, everything-skippable "why are you leaving?" survey shown after a
/// subscription cancellation. Single-select reason chips + an optional
/// free-text note. Both Skip and Submit are always enabled (nothing is
/// required). Copy adapts to trial vs paid via [isTrial].
///
/// The sheet is intentionally dumb: it owns no detection or persistence. It
/// reports the user's choice through [onSubmit] / [onSkip] so it can be widget
/// tested in isolation.
class CancellationFeedbackSheet extends StatefulWidget {
  const CancellationFeedbackSheet({
    super.key,
    required this.isTrial,
    required this.onSubmit,
    required this.onSkip,
  });

  final bool isTrial;
  final void Function(CancellationReason? reason, String? text) onSubmit;
  final VoidCallback onSkip;

  /// Human-readable label for each reason. Lives in the UI layer; the enum
  /// [CancellationReason.code] remains the stable storage/analytics key.
  static const Map<CancellationReason, String> reasonLabels = {
    CancellationReason.tooExpensive: 'Too expensive',
    CancellationReason.notUsing: 'Not using it enough',
    CancellationReason.missingFeature: 'Missing something I need',
    CancellationReason.foundAlternative: 'Found a better app',
    CancellationReason.technicalIssues: 'Bugs or technical problems',
    CancellationReason.justBreak: 'Just taking a break',
    CancellationReason.other: 'Other',
  };

  static Future<void> show(
    BuildContext context, {
    required bool isTrial,
    required void Function(CancellationReason? reason, String? text) onSubmit,
    required VoidCallback onSkip,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return CancellationFeedbackSheet(
          isTrial: isTrial,
          onSubmit: (reason, text) {
            Navigator.of(sheetContext).pop();
            onSubmit(reason, text);
          },
          onSkip: () {
            Navigator.of(sheetContext).pop();
            onSkip();
          },
        );
      },
    );
  }

  @override
  State<CancellationFeedbackSheet> createState() =>
      _CancellationFeedbackSheetState();
}

class _CancellationFeedbackSheetState extends State<CancellationFeedbackSheet> {
  CancellationReason? _selected;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headline =
        widget.isTrial ? 'Before your trial ends' : 'Sorry to see you go';
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  headline,
                  style: AppTypography.displaySmall.copyWith(
                    fontSize: 22,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your feedback is optional, but it helps us make Sakina '
                  'better. Why are you leaving?',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final reason in CancellationReason.values)
                      _ReasonChip(
                        label:
                            CancellationFeedbackSheet.reasonLabels[reason] ??
                                reason.code,
                        selected: _selected == reason,
                        onTap: () => setState(
                          () => _selected = _selected == reason ? null : reason,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _textController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Anything else? (optional)',
                    hintStyle: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiaryLight),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide:
                          const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                  ),
                  onPressed: () => widget.onSubmit(
                    _selected,
                    _textController.text,
                  ),
                  child: const Text('Submit'),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    'Skip',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: selected
                  ? AppColors.primary
                  : AppColors.textPrimaryLight,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
