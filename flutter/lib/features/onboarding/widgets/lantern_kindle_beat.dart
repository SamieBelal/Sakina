import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../streaks/models/lantern_skin.dart';
import 'lantern_kindle.dart';

/// The kindling beat (One Ship W2 Wave G, spec §5) — the body of the reveal's
/// loading phase.
///
/// **This is not a loader.** It occupies the loading slot because that is where
/// the existing dissolve-into-beat-1 lives, but nothing here is telling the
/// user to wait. The hook screen asked what they are carrying; this is the
/// answer arriving as light before it arrives as words.
///
/// The lamp is dark, catches, and settles at `endowedDim` — the true state of
/// someone who has just arrived. Both copy lines are claims the product keeps.
///
/// The subline says "the longer you keep coming back", NOT "each day". Glow
/// moves in three steps, not daily: `dim` 0.44 covers streak 1–3, `glowing`
/// 0.72 covers 4–29, `fullyLit` 1.0 is 30+. A user returning on day two sees no
/// change at all, so a daily promise would be false on its second test — and
/// this flow cannot afford to be caught overclaiming in its opening beat. Neither line attributes a stance to Allah or to a Name,
/// neither uses "sign" or "meant for you", and the lantern itself never speaks
/// — it is a mirror, not a guide (Wave G decision 1).
class LanternKindleBeat extends StatelessWidget {
  const LanternKindleBeat({
    this.skin = LanternSkin.classicGold,
    this.size = 160,
    this.onKindled,
    super.key,
  });

  static const String headline = 'Your lantern is lit.';
  static const String subline = 'It brightens the longer you keep coming back.';

  final LanternSkin skin;
  final double size;

  /// Fires once, when the flame has settled.
  final VoidCallback? onKindled;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      // One announcement for the whole beat: a screen reader should hear what
      // happened, not two orphaned fragments around an unlabelled painting.
      label: '$headline $subline',
      excludeSemantics: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LanternKindle(size: size, skin: skin, onKindled: onKindled),
              const SizedBox(height: AppSpacing.lg),
              // Copy arrives AFTER the flame — the light is the event, the
              // words only name it. Both lines overlap rather than queue, per
              // the AppMotion vocabulary.
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: -0.4,
                  color: AppColors.sacredInk,
                ),
              )
                  .animate(delay: _headlineDelay)
                  .fadeIn(
                    duration: AppMotion.entrance,
                    curve: AppMotion.enter,
                  )
                  .moveY(
                    begin: reduceMotion ? 0 : AppMotion.riseLarge,
                    end: 0,
                    duration: AppMotion.entrance,
                    curve: AppMotion.enter,
                  ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subline,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.45,
                  // The canvas's own supporting-text token, not a hand-rolled
                  // alpha — every other sacred-canvas surface uses it.
                  color: AppColors.sacredInkSoft,
                ),
              )
                  .animate(delay: _headlineDelay + AppMotion.beat)
                  .fadeIn(duration: AppMotion.layer, curve: AppMotion.enter)
                  .moveY(
                    begin: reduceMotion ? 0 : AppMotion.riseMedium,
                    end: 0,
                    duration: AppMotion.layer,
                    curve: AppMotion.enter,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// The headline lands as the flare is settling, not after the ramp finishes —
  /// waiting for the full 900ms would leave a dead frame between the light and
  /// the words.
  static const Duration _headlineDelay = Duration(milliseconds: 520);
}
