import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The single resolved primary action for the previewed item.
///
/// The wardrobe screen resolves exactly one of these per item and passes it
/// down; the bar itself renders and dispatches, it never re-derives gating.
/// The gating contract the resolver must honour:
///
/// - [equip] only when `await CosmeticsService.canEquip(...)` returned true
///   (async — it resolves premium-exclusive rows against live premium).
/// - [unlock] only when the item is NOT owned and Noor covers the price.
///   Offering unlock for an already-owned item would double-debit the local
///   cache (`unlock_cosmetic` returns true without charging when already
///   owned), so an owned item must never resolve to [unlock].
/// - [unlockUnaffordable] — not owned, priced, but the balance falls short:
///   the price stays visible, the button is inert.
/// - [buy] only for à-la-carte skins (`iapProductId != null`) that are not
///   owned, AND only while `kSkinIapEnabled` is true — the caller must have a
///   real RevenueCat purchase behind `onBuy`.
/// - [premiumTeaser] / [milestoneTeaser] / [comingSoonTeaser] —
///   visible-but-locked. No action; the item reads as reachable later, not
///   purchasable now.
enum WardrobeAction {
  equip,
  unlock,
  unlockUnaffordable,
  buy,
  premiumTeaser,
  milestoneTeaser,

  /// À-la-carte, unowned, and the skin IAP is not live yet
  /// (`kSkinIapEnabled == false`). Same inert teaser shape as the other two —
  /// deliberately NOT a button, and it asserts no price, because there is no
  /// localized `StoreProduct.priceString` to quote until the SKUs exist.
  comingSoonTeaser,
}

/// The wardrobe's bottom action bar. Pure and callback-driven: the *screen*
/// owns the service calls, so this stays unit-testable and free of Supabase.
class WardrobeActionBar extends StatelessWidget {
  const WardrobeActionBar({
    super.key,
    required this.action,
    required this.priceLabel,
    required this.onEquip,
    required this.onUnlock,
    required this.onBuy,
    this.teaser,
    this.busy = false,
  });

  final WardrobeAction action;

  /// '120 Noor' or a store-formatted price like r'$2.99'.
  final String? priceLabel;

  /// Copy for the premium/milestone locked states, e.g.
  /// 'Unlock at a 30-day streak'.
  final String? teaser;

  final VoidCallback onEquip;
  final VoidCallback onUnlock;
  final VoidCallback onBuy;

  /// A mutation is in flight — the CTA renders disabled. Unlock is the reason
  /// this exists: the server is idempotent, but the client mirrors the Noor
  /// debit locally on every `true`, so a second tap before the first resolves
  /// would debit the displayed balance twice (I6). The screen ALSO refuses
  /// re-entry; this is the half the user can see.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    switch (action) {
      case WardrobeAction.premiumTeaser:
      case WardrobeAction.milestoneTeaser:
      case WardrobeAction.comingSoonTeaser:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            teaser ?? 'Locked',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        );
      case WardrobeAction.equip:
        return _button(context, 'Equip', AppColors.primary, _live(onEquip));
      case WardrobeAction.unlock:
        return _button(context, 'Unlock · ${priceLabel ?? ''}',
            AppColors.secondary, _live(onUnlock));
      case WardrobeAction.unlockUnaffordable:
        return _button(
            context, 'Unlock · ${priceLabel ?? ''}', AppColors.secondary, null);
      case WardrobeAction.buy:
        return _button(
            context, 'Get · ${priceLabel ?? ''}', AppColors.primary, _live(onBuy));
    }
  }

  /// The handler, or null while [busy] — a disabled `FilledButton`.
  VoidCallback? _live(VoidCallback onTap) => busy ? null : onTap;

  Widget _button(
      BuildContext context, String label, Color color, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            textStyle: AppTypography.labelLarge,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
