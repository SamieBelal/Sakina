import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/card_collection_service.dart' show CollectibleName;

/// One row of the queue on the plan screen (One Ship W2-D2).
///
/// Three states, three amounts of disclosure:
///   * [QueueNameRow.met] — the Name from the reveal, with the tier of the card
///     it awarded;
///   * [QueueNameRow.next] — Name₂, named but not opened, "opens tomorrow" and
///     nothing more precise (a clock turns a promise into a deadline);
///   * [QueueNameRow.veiled] — a real queued Name whose identity is withheld.
///     The row is a silhouette on purpose: the queue is already chosen and
///     server-seeded, so showing the Names here would spend every unseal at
///     once.
///
/// Arabic never shares a `Text` with Latin — the Name renders in its own RTL
/// widget above the transliteration.
class QueueNameRow extends StatelessWidget {
  const QueueNameRow.met({
    required CollectibleName name,
    required String tierLabel,
    super.key,
  })  : _name = name,
        _tierLabel = tierLabel,
        _statusLabel = metLabel;

  const QueueNameRow.next({required CollectibleName name, super.key})
      : _name = name,
        _tierLabel = null,
        _statusLabel = nextLabel;

  const QueueNameRow.veiled({super.key})
      : _name = null,
        _tierLabel = null,
        _statusLabel = veiledLabel;

  static const String metLabel = 'Met';
  static const String nextLabel = 'Opens tomorrow';
  static const String veiledLabel = 'Sealed';

  final CollectibleName? _name;
  final String? _tierLabel;
  final String _statusLabel;

  bool get _isMet => _statusLabel == metLabel;

  @override
  Widget build(BuildContext context) {
    final name = _name;
    final tierLabel = _tierLabel;
    return Semantics(
      label:
          name == null ? veiledLabel : '${name.transliteration}, $_statusLabel',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: _isMet ? AppColors.surfaceLight : AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: _isMet ? AppColors.primary : AppColors.borderLight,
            width: _isMet ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _leading(),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: name == null ? _veil() : _identity(name)),
            if (tierLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _tierChip(tierLabel),
            ],
          ],
        ),
      ),
    );
  }

  Widget _leading() {
    if (_isMet) {
      return _bullet(
        AppColors.primaryLight,
        const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
      );
    }
    if (_name != null) {
      return _bullet(
        AppColors.secondaryLight,
        const Icon(Icons.nightlight_round, size: 15, color: AppColors.goldInk),
      );
    }
    return _bullet(AppColors.dividerLight);
  }

  Widget _bullet(Color background, [Widget? child]) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: child,
      );

  Widget _identity(CollectibleName name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name.arabic,
          textDirection: TextDirection.rtl,
          style: AppTypography.arabicClassical.copyWith(
            fontSize: 20,
            height: 1.5,
            color: _isMet
                ? AppColors.textPrimaryLight
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          name.transliteration,
          textDirection: TextDirection.ltr,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _statusLabel,
          textDirection: TextDirection.ltr,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  /// The silhouette: a veiled line where a Name will be, and the one word that
  /// says why it is not there yet.
  Widget _veil() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 104,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _statusLabel,
          textDirection: TextDirection.ltr,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  Widget _tierChip(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.goldInk,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
