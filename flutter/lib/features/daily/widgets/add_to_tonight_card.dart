import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/daily/widgets/tonight_thread_line.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// "Add to tonight" — the thread affordance (Wave C, C1).
///
/// **It appends text and nothing else.** No reveal, no streak, no reward, no
/// allowance: the host's `appendToTonight` is a pure text write against a row
/// that already exists, and this widget must never be given a second job. If a
/// future change wants an "add" to also start something, that is a second night
/// and belongs on the submit path, behind the `!checkinDone` gate.
///
/// Pure UI: it owns no provider and does its own I/O through [onAppend], which
/// returns whether the write landed.
class AddToTonightCard extends StatefulWidget {
  const AddToTonightCard({
    required this.thread,
    required this.onAppend,
    this.maxEntries = 20,
    super.key,
  });

  /// The appends already made tonight, oldest first.
  final List<ReflectionThreadEntry> thread;

  /// Writes the append. Returns false when nothing was written — the entry was
  /// full, the day rolled over, or the server refused.
  final Future<bool> Function(String text) onAppend;

  /// The server's element cap, mirrored so the field can close itself instead of
  /// letting the user type into a write that will be refused.
  final int maxEntries;

  @override
  State<AddToTonightCard> createState() => _AddToTonightCardState();
}

class _AddToTonightCardState extends State<AddToTonightCard> {
  final TextEditingController _controller = TextEditingController();

  /// One append in flight at a time. Set BEFORE the await and cleared in a
  /// `finally`, so a double-tap cannot write the same line twice — the same
  /// shape the discover CTA uses, for the same reason.
  bool _writing = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _full => widget.thread.length >= widget.maxEntries;

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (_writing || text.isEmpty) return;
    setState(() {
      _writing = true;
      _message = null;
    });
    try {
      final ok = await widget.onAppend(text);
      if (!mounted) return;
      setState(() {
        if (ok) {
          // Cleared only on a confirmed write. On a refusal the user's words
          // stay in the field — losing them to a failed round-trip is the one
          // outcome a journaling affordance cannot have.
          _controller.clear();
        } else {
          _message = _full
              ? MuhasabahCompletionCopy.addFull
              : MuhasabahCompletionCopy.addFailed;
        }
      });
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.thread.isNotEmpty) ...[
          Text(
            MuhasabahCompletionCopy.threadLabel,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiaryLight,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in widget.thread)
            TonightThreadLine(text: entry.text),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_full)
          Text(
            MuhasabahCompletionCopy.addFull,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          )
        else
          _field(),
        if (_message != null && !_full) ...[
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

  Widget _field() => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              label: MuhasabahCompletionCopy.addFieldLabel,
              textField: true,
              child: TextField(
                controller: _controller,
                enabled: !_writing,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: MuhasabahCompletionCopy.addFieldHint,
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
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: _writing
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
              MuhasabahCompletionCopy.addAction,
              style: AppTypography.labelLarge.copyWith(
                color: _writing ? AppColors.textTertiaryLight : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}
