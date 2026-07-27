import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/services/cosmetics_service.dart';

// E2 (OQ-D1 option A). CardRevealOverlay renders a Name-of-Allah card face and
// is hard-coupled to CollectibleName + CardTier, so it cannot render a lantern
// skin. This is a self-contained sibling that reuses the SAME ignite→settle
// feel by forging Lane C's CompanionMedallion on the sacred canvas — the
// shipped card reveal is left untouched.
//
// A skin unlock lights the just-earned lantern; a backdrop unlock reveals the
// new canvas behind the always-owned classic lantern.

typedef ShowCosmeticUnlockRevealFn = Future<void> Function(
    BuildContext context, String itemType, String itemId);

/// Presents the unlock reveal for [itemType]/[itemId]. Resolves on dismissal.
/// Overridable so call sites can be pinned without a real route.
ShowCosmeticUnlockRevealFn showCosmeticUnlockReveal =
    defaultShowCosmeticUnlockReveal;

Future<void> defaultShowCosmeticUnlockReveal(
    BuildContext context, String itemType, String itemId) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) =>
          _CosmeticUnlockReveal(itemType: itemType, itemId: itemId),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 260),
    ),
  );
}

class _CosmeticUnlockReveal extends StatefulWidget {
  const _CosmeticUnlockReveal({required this.itemType, required this.itemId});

  final String itemType;
  final String itemId;

  @override
  State<_CosmeticUnlockReveal> createState() => _CosmeticUnlockRevealState();
}

class _CosmeticUnlockRevealState extends State<_CosmeticUnlockReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBackdrop = widget.itemType == itemTypeBackdrop;
    final skin = resolveSkin(isBackdrop ? defaultLanternSkin : widget.itemId);
    final backdrop =
        resolveBackdrop(isBackdrop ? widget.itemId : defaultBackdrop);
    final name = isBackdrop ? backdrop.name : skin.name;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: CompanionStage(
          backdrop: backdrop,
          child: Center(
            child: FadeTransition(
              opacity: _controller,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(
                  CurvedAnimation(
                      parent: _controller, curve: Curves.easeOutBack),
                ),
                child: _body(
                  skin: skin,
                  name: name,
                  onLight: backdrop.isLightSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A SKIN unlock always stages on `Backdrop.none` (see build), which paints
  /// the plain WARM CREAM surface — so the sacredInk ramp, which is cream, was
  /// rendering cream-on-cream at ~1.03:1 and the skin name was invisible for
  /// every one of the nine skins. `Backdrop.isLightSurface` exists precisely to
  /// flag this ("anything drawing chrome over a backdrop must branch on this
  /// rather than assuming a dark canvas"); this widget was not consulting it.
  ///
  /// A BACKDROP unlock stages on the newly-owned scene, which is dark, so it
  /// keeps the cream ramp it was designed for.
  ///
  /// Contrast on the cream stage (#FBF7F2 -> #F3ECE1, measured at the darker
  /// end): name 14.54:1, eyebrow and hint 4.12:1 — against 1.03:1 before.
  /// The gold hairline is untouched: it stays a non-text accent either way.
  Widget _body({
    required LanternSkin skin,
    required String name,
    required bool onLight,
  }) {
    final inkStrong =
        onLight ? AppColors.textPrimaryLight : AppColors.sacredInk;
    // One step down from `inkStrong` on light. `textTertiaryLight` would be the
    // literal analogue of sacredInkFaint but only reaches 2.16:1 here, so the
    // eyebrow and the hint share the secondary tone rather than fading further.
    final inkMuted =
        onLight ? AppColors.textSecondaryLight : AppColors.sacredInkSoft;
    final inkFaint =
        onLight ? AppColors.textSecondaryLight : AppColors.sacredInkFaint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CompanionMedallion(
            state: const CompanionState(
                brightness: CompanionBrightness.fullyLit, protected: false),
            size: 200,
            skin: skin,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Gold stays a non-text accent: the eyebrow reads in cream ink, and the
        // gold appears only as the hairline beneath it.
        Text(
          'Unlocked',
          style: AppTypography.labelLarge
              .copyWith(color: inkMuted, letterSpacing: 3),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(width: 44, height: 1.5, color: AppColors.secondary),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(color: inkStrong),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Tap to continue',
          style: AppTypography.bodySmall.copyWith(color: inkFaint),
        ),
      ],
    );
  }
}
