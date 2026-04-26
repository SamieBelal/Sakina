/// Delete-account 2-step confirmation dialogs.
///
/// Extracted from `settings_screen.dart` so the type-DELETE confirmation
/// flow can be widget-tested without instantiating the whole settings
/// surface. The two functions are intentionally separate: the warning
/// must be shown and dismissed before the type-confirm dialog opens, and
/// each gets its own assertions in tests.
///
/// Regression coverage for finding 2026-04-26 Phase 5c (Delete Account
/// UI dialog flow). Captured during the QABot end-to-end run on iPhone 17
/// simulator.
library;

import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Warning step. Returns true on Continue, false on Cancel or barrier
/// dismiss. Calling code must NOT proceed to deletion unless this returns
/// true.
Future<bool> showDeleteAccountWarningDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'This will permanently delete your account and all associated '
        'data — streaks, saved reflections, journal entries, and '
        'preferences. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Continue',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  return result == true;
}

/// Final type-DELETE confirmation step. Returns true ONLY if the user
/// typed exactly `DELETE` (trimmed) in the text field AND tapped the
/// Delete My Account button. Cancel, barrier dismiss, and submitting with
/// an unmatched value all return false. Caller must invoke
/// `authService.deleteAccount()` only on a true return.
Future<bool> showDeleteAccountConfirmDialog(BuildContext context) async {
  // Intentionally NOT disposed: the dialog's dismiss animation may still
  // reference the controller when the caller's signOut() triggers a
  // synchronous GoRouter rebuild after a true return. Letting the
  // controller fall out of scope and be garbage-collected is safer than
  // disposing it here.
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isValid = controller.text.trim() == 'DELETE';
          return AlertDialog(
            title: const Text('Are you sure?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type DELETE to confirm account deletion.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isValid ? () => Navigator.pop(ctx, true) : null,
                child: Text(
                  'Delete My Account',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isValid
                        ? AppColors.error
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
  return result == true;
}
