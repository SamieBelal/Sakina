import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Copy for the edit sheet, in one place so the sheet and its tests agree.
abstract final class JournalEditCopy {
  static const String title = 'Edit your words';

  /// Says plainly what an edit does NOT touch.
  ///
  /// The reframe, the Name and the verses were the response to what was
  /// originally written, and they stay that way — see `editReflectionText`.
  /// Someone who rewrites their answer and then finds the reflection unchanged
  /// should have been told first, not left to wonder whether the save worked.
  static const String subtitle =
      'The Name and the reflection stay as they were.';

  static const String hint = 'What you wrote';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String failed = "Couldn't save your changes. Please try again.";
  static const String fieldLabel = 'Edit the words you wrote on this entry';
}

/// The edit sheet. Returns true when a change was saved.
///
/// Modelled on the "add to tonight" sheet — same surface, same radius, same
/// padding, same keyboard inset handling — so the two ways of putting words into
/// the journal do not look like controls from different apps.
Future<bool?> showEditEntrySheet(
  BuildContext context, {
  required String initialText,
  required Future<bool> Function(String text) onSave,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surfaceLight,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 4,
        bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: EditEntrySheet(initialText: initialText, onSave: onSave),
    ),
  );
}

/// Pure UI: it owns no provider and does its I/O through [onSave].
class EditEntrySheet extends StatefulWidget {
  const EditEntrySheet({
    required this.initialText,
    required this.onSave,
    super.key,
  });

  final String initialText;

  /// Writes the edit. Returns false when nothing was written.
  final Future<bool> Function(String text) onSave;

  @override
  State<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<EditEntrySheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  /// One save in flight at a time — set BEFORE the await and cleared in a
  /// `finally`, the same shape [AddToTonightCard] uses so a double-tap cannot
  /// write twice.
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    // An entry cannot be edited into having no words. That is what delete is
    // for, and it asks for confirmation first — this button does not, so it must
    // not be able to do the same thing quietly.
    if (_saving || text.isEmpty) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final ok = await widget.onSave(text);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        return;
      }
      // The words stay in the field on a refusal. Losing them to a failed
      // round-trip is the one outcome a journaling affordance cannot have.
      setState(() => _message = JournalEditCopy.failed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          JournalEditCopy.title,
          style: AppTypography.headlineMedium
              .copyWith(color: AppColors.textPrimaryLight),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          JournalEditCopy.subtitle,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: JournalEditCopy.fieldLabel,
          textField: true,
          child: TextField(
            controller: _controller,
            enabled: !_saving,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimaryLight, height: 1.5),
            decoration: InputDecoration(
              hintText: JournalEditCopy.hint,
              hintStyle: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textTertiaryLight),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide:
                    const BorderSide(color: AppColors.borderLight, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide:
                    const BorderSide(color: AppColors.borderLight, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _message!,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondaryLight,
              ),
              child: Text(
                JournalEditCopy.cancel,
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _submit();
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
              ),
              child: Text(
                JournalEditCopy.save,
                style: AppTypography.labelLarge.copyWith(
                  color:
                      _saving ? AppColors.textTertiaryLight : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
