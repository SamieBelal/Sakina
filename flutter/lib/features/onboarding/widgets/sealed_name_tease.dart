import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/name_story_deck.dart';
import '../../../widgets/adjusted_arabic_display.dart';

/// The closing beat of the onboarding reveal (One Ship W2-C1): Name₂'s
/// identity, shown but not opened.
///
/// Everything about the Name itself comes from the deck — the Arabic, the
/// transliteration and the one-line anchor are read off the `name_intro` beat
/// (falling back to the `bridge` line), never written here. Only the framing
/// sentence and the CTA are UI copy.
///
/// **No countdown clock** (approved UX spec): a timer turns a promise into a
/// deadline. The framing says tomorrow and stops there.
///
/// Arabic and Latin never share a `Text` — the Name renders through
/// [AdjustedArabicDisplay], the transliteration and anchor as separate LTR
/// widgets below it.
class SealedNameTease extends StatelessWidget {
  const SealedNameTease({
    required this.deck,
    required this.onContinue,
    super.key,
  });

  static const String sealedLabel = 'Sealed until tomorrow';
  static const String framingLabel =
      'You will meet this Name tomorrow, when it can be its own morning.';
  static const String continueLabel = 'Continue';

  final NameStoryDeck deck;
  final VoidCallback onContinue;

  NameStoryBeat? _beat(String kind) {
    for (final b in deck.beats) {
      if (b.kind == kind) return b;
    }
    return null;
  }

  /// The Name in Arabic, from the deck's `name_intro` beat.
  String get _arabic => _beat('name_intro')?.arabic ?? '';

  /// Latin rendering — the beat's own transliteration, else the deck's.
  String get _transliteration {
    final fromBeat = _beat('name_intro')?.transliteration ?? '';
    return fromBeat.isNotEmpty ? fromBeat : deck.transliteration;
  }

  /// One line of deck copy that says what this Name is. `name_intro.primary`
  /// carries the meaning; the bridge line is the fallback for a deck that
  /// opens differently.
  String get _anchor {
    final meaning = _beat('name_intro')?.primary ?? '';
    if (meaning.isNotEmpty) return meaning;
    return _beat('bridge')?.primary ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration:
            const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Expanded(child: Center(child: _identity())),
                _continueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _identity() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sealedLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.sacredInkFaint,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_arabic.isNotEmpty)
            AdjustedArabicDisplay(
              text: _arabic,
              style: AppTypography.nameOfAllahDisplay.copyWith(
                fontSize: 44,
                color: AppColors.sacredInk,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _transliteration,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.sacredInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_anchor.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _anchor,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: AppTypography.bodyLarge.copyWith(
                height: 1.4,
                color: AppColors.sacredInkSoft,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            framingLabel,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.45,
              color: AppColors.sacredInkFaint,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).moveY(
            begin: 12,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _continueButton() {
    return Semantics(
      button: true,
      label: continueLabel,
      // Without this the child Text re-announces the label, so VoiceOver reads
      // the button twice.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onContinue,
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            continueLabel,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.sacredCanvasTop,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 700.ms);
  }
}
