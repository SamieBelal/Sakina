import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';

/// The 2-up grid of one wardrobe axis. Pure display: statuses and names are
/// resolved by the screen and passed in, so the grid makes no service calls.
class WardrobeGrid extends StatelessWidget {
  const WardrobeGrid({
    super.key,
    required this.entries,
    required this.statusFor,
    required this.nameFor,
    required this.previewedId,
    required this.onPreview,
  });

  final List<CosmeticCatalogEntry> entries;
  final WardrobeTileStatus Function(CosmeticCatalogEntry) statusFor;
  final String Function(CosmeticCatalogEntry) nameFor;
  final String? previewedId;
  final void Function(CosmeticCatalogEntry) onPreview;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(AppSpacing.md),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.82,
      children: [
        for (final e in entries)
          WardrobeTile(
            itemType: e.itemType,
            itemId: e.itemId,
            name: nameFor(e),
            status: statusFor(e),
            selected: e.itemId == previewedId,
            onTap: () => onPreview(e),
          ),
      ],
    );
  }
}
