import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';

/// ʿazm — the one line of forward resolve the night ends on (Wave C, C4).
///
/// Classically the last step of muḥāsabah: the accounting ends in a resolve.
/// One line, never a plan: a box that invites a list invites abandonment, and
/// the thing that has to survive to tomorrow night is a sentence.
///
/// **A pure text write, like the thread.** The host's `setTonightAzm` edits a
/// row that already exists; nothing here touches the economy.
class AzmField extends StatefulWidget {
  const AzmField({
    required this.initialValue,
    required this.onSave,
    this.maxChars = 500,
    super.key,
  });

  /// What is already stored on tonight's row, or ''.
  final String initialValue;

  /// Persists the resolve. Returns false when the write did not land.
  final Future<bool> Function(String azm) onSave;

  /// The server's `user_reflections_azm_length_cap`, mirrored so the field
  /// cannot compose a value the row will refuse.
  final int maxChars;

  @override
  State<AzmField> createState() => _AzmFieldState();
}

class _AzmFieldState extends State<AzmField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  bool _writing = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (_writing || text.isEmpty) return;
    setState(() {
      _writing = true;
      _message = null;
    });
    try {
      final ok = await widget.onSave(text);
      if (!mounted) return;
      // The text stays in the field either way: this is an editable resolve, not
      // a submission that clears itself.
      setState(() => _message = ok
          ? MuhasabahCompletionCopy.azmSaved
          : MuhasabahCompletionCopy.azmFailed);
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MuhasabahCompletionCopy.azmPrompt,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiaryLight,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Semantics(
                label: MuhasabahCompletionCopy.azmFieldLabel,
                textField: true,
                child: TextField(
                  controller: _controller,
                  enabled: !_writing,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: widget.maxChars,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: MuhasabahCompletionCopy.azmHint,
                    hintStyle: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiaryLight),
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(
                          color: AppColors.borderLight, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(
                          color: AppColors.borderLight, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1),
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: _writing
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _save();
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
              ),
              child: Text(
                MuhasabahCompletionCopy.azmAction,
                style: AppTypography.labelLarge.copyWith(
                  color:
                      _writing ? AppColors.textTertiaryLight : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _message!,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ],
    );
  }
}
