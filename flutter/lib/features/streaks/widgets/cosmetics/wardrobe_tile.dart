import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/services/cosmetics_service.dart';

/// The display state of one wardrobe tile (computed by the wardrobe from
/// CosmeticsState + canEquip + catalog gating).
///
/// [equippable] is the state a premium-exclusive item takes while premium is
/// ACTIVE: it can be equipped right now but is **not owned**, and must never be
/// badged as owned/equipped — premium-exclusive cosmetics are equippable while
/// active and never convert to permanent ownership.
enum WardrobeTileStatus {
  /// Currently equipped on this axis.
  equipped,

  /// Permanently owned (Noor unlock, milestone grant, or à-la-carte purchase).
  owned,

  /// Not owned, but equippable right now (premium-exclusive + premium active).
  equippable,

  /// Not owned; unlockable with Noor or gated behind a streak milestone.
  locked,

  /// Premium-exclusive, and premium is not active.
  premiumLocked,

  /// À-la-carte real-money skin that has not been purchased.
  alaCarteLocked,
}

/// One wardrobe grid tile: a static (`animate:false`) lantern thumbnail, the
/// item name, and a state badge. Pure display — it makes no service calls and
/// resolves no gating itself; the wardrobe passes a computed [status].
class WardrobeTile extends StatelessWidget {
  const WardrobeTile({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.name,
    required this.status,
    required this.onTap,
    this.selected = false,
  });

  final String itemType;
  final String itemId;
  final String name;
  final WardrobeTileStatus status;
  final VoidCallback onTap;
  final bool selected;

  // `owned` and `equippable` deliberately carry no badge: the first is the
  // quiet default, the second must not read as ownership. `alaCarteLocked`
  // only invites a purchase once the SKUs are live — until then it reads
  // "Soon", matching the action bar's Coming soon teaser.
  String? get _badge => switch (status) {
        WardrobeTileStatus.equipped => 'Equipped',
        WardrobeTileStatus.premiumLocked => 'Premium',
        WardrobeTileStatus.alaCarteLocked => kSkinIapEnabled ? 'Buy' : 'Soon',
        WardrobeTileStatus.locked => 'Locked',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    // Static thumbnail: skins render as a small dormant-lit medallion (animate
    // off); backdrops render a tiny classic medallion so the tile still shows
    // "a lantern" — the backdrop itself is previewed on the stage on tap.
    final thumb = SizedBox(
      width: 92,
      height: 92,
      child: CompanionMedallion(
        state: const CompanionState(
          brightness: CompanionBrightness.glowing,
          protected: false,
        ),
        size: 92,
        animate: false,
        ambient: false,
        skin: itemType == itemTypeLanternSkin
            ? resolveSkin(itemId)
            : resolveSkin(defaultLanternSkin),
      ),
    );

    final dimmed = status == WardrobeTileStatus.locked ||
        status == WardrobeTileStatus.premiumLocked ||
        status == WardrobeTileStatus.alaCarteLocked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          // Warm off-white, a step nearer the beige page than backgroundLight
          // (#FBF7F2). The tile still reads as a raised card, but when the
          // scroll edge slices one the cut is far quieter — a near-white tile
          // cut against beige is what made the grid look torn.
          color: const Color(0xFFFDFAF6),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.secondary.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(opacity: dimmed ? 0.55 : 1.0, child: thumb),
            const SizedBox(height: AppSpacing.xs),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textPrimaryLight),
            ),
            if (_badge != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _StatusBadge(label: _badge!, status: status),
            ],
          ],
        ),
      ),
    );
  }
}

/// The small pill under the tile name. Gold/emerald are FILLS here — the label
/// sits on a tinted background, never gold text on cream.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.status});

  final String label;
  final WardrobeTileStatus status;

  @override
  Widget build(BuildContext context) {
    final isEquipped = status == WardrobeTileStatus.equipped;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEquipped ? AppColors.primaryLight : AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isEquipped ? AppColors.primary : AppColors.goldInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
