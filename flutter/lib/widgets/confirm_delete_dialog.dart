import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Shows a destructive-action confirmation dialog.
///
/// Returns `true` if the user confirmed the destructive action, `false` if
/// they cancelled or dismissed by tapping outside. Use for any irreversible
/// delete (journal entry, reflection, built dua, saved related dua).
///
/// The same shape (Cancel left, destructive Delete right, red emphasis on
/// the destructive option) matches the existing Settings → Sign Out and
/// Settings → Delete Account dialogs so the user gets one consistent
/// pattern across the app.
Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String title,
  String body = "This can't be undone.",
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text(title, style: AppTypography.headlineMedium),
      content: Text(
        body,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
