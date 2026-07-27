// Riverpod UI-layer state for the wardrobe (this is the UI layer — Riverpod is
// allowed here, unlike the service layer). Reads flow through Lane B's
// getCosmeticsState(); mutations are done by the screen calling the service and
// then invalidating cosmeticsStateProvider to re-read the mirrored cache.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/features/streaks/providers/companion_inputs_provider.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';

/// The user's cosmetics economy state (Noor + owned + equipped). Re-read after
/// every successful equip/unlock/buy via `ref.invalidate(cosmeticsStateProvider)`.
///
/// AutoDispose because the resolution is USER-scoped and nothing outside the
/// wardrobe ever invalidated it (I8). App-scoped, a same-session sign-out →
/// sign-in served the PREVIOUS user's resolved state on the next /companion
/// open — their Noor balance, their equipped lantern. (The underlying prefs are
/// user-scoped via `SupabaseSyncService.scopedKey`, so this was display
/// staleness, not a data leak — but it is indistinguishable from one on
/// screen.) Both consumers are screens, so the state dies with the last one
/// and the next open re-reads under whoever is signed in now.
final cosmeticsStateProvider =
    FutureProvider.autoDispose<CosmeticsState>((ref) async {
  return getCosmeticsState();
});

/// Premium, for the cosmetics render gate ONLY. Unresolvable reads as NOT
/// premium — the conservative default (it can only cost an active subscriber one
/// frame of classic gold, never the reverse).
///
/// autoDispose so it re-resolves for a new set of consumers rather than pinning
/// one answer for the process lifetime; a subscription that starts or lapses
/// mid-session is picked up the next time a lantern surface mounts.
final cosmeticsPremiumProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await PurchaseService().isPremium();
  } catch (_) {
    return false;
  }
});

/// THE lantern skin every surface renders — Home, the launch overlay, the card
/// reveal, the milestone overlay, the rescue sheet, and the Companion stage.
///
/// Exists because `CompanionMedallion.skin` defaults to classic gold so that
/// pre-cosmetics call sites kept compiling, which quietly left every surface
/// except the Companion stage and the wardrobe rendering brass no matter what
/// the user equipped. Making each one resolve its own premium snapshot would
/// reintroduce, five times over, exactly the drift `renderableSkinId` was
/// written to prevent — so they all read this instead.
///
/// Routes through `renderableSkinId`, NOT `equippedLanternSkin` directly: that
/// is what makes a lapsed subscriber's premium-exclusive skin fall back to
/// classic gold instead of showing the perk indefinitely.
///
/// Falls back to classic gold while either input is loading, so a surface never
/// blocks on a spinner — a cold start may show one brass frame before resolving.
///
/// autoDispose is inherited deliberately: it keeps [cosmeticsStateProvider]'s
/// user-scoped lifetime intact (see its doc). An app-scoped derived provider
/// here would hold that state alive forever and bring back the sign-out →
/// sign-in staleness it was made autoDispose to fix.
final renderableLanternSkinProvider =
    Provider.autoDispose<LanternSkin>((ref) {
  final isPremium = ref.watch(cosmeticsPremiumProvider).maybeWhen(
        data: (p) => p,
        orElse: () => false,
      );
  return ref.watch(cosmeticsStateProvider).maybeWhen(
        data: (cs) => resolveSkin(renderableSkinId(cs, isPremium: isPremium)),
        orElse: () => LanternSkin.classicGold,
      );
});

/// The streak count the Companion stage and the E1 share card display. Derived
/// from the same atomic companion snapshot the medallion renders from, so the
/// shared card can never show a streak that disagrees with the lantern beside
/// it. Reads 0 until the snapshot hydrates.
final companionStreakProvider = Provider<int>((ref) {
  return ref.watch(companionInputsProvider).maybeWhen(
        data: (inputs) => inputs.streak.currentStreak,
        orElse: () => 0,
      );
});

/// Transient wardrobe UI state: which axis is showing + which item is previewed
/// on the stage (not yet equipped). Never persisted.
@immutable
class WardrobePreview {
  const WardrobePreview({
    this.tab = itemTypeLanternSkin,
    this.previewedSkinId,
    this.previewedBackdropId,
  });

  final String tab;
  final String? previewedSkinId;
  final String? previewedBackdropId;

  WardrobePreview copyWith({
    String? tab,
    String? previewedSkinId,
    String? previewedBackdropId,
  }) =>
      WardrobePreview(
        tab: tab ?? this.tab,
        previewedSkinId: previewedSkinId ?? this.previewedSkinId,
        previewedBackdropId: previewedBackdropId ?? this.previewedBackdropId,
      );
}

class WardrobePreviewNotifier extends AutoDisposeNotifier<WardrobePreview> {
  @override
  WardrobePreview build() => const WardrobePreview();

  void setTab(String tab) => state = state.copyWith(tab: tab);

  /// Preview [itemId] on [itemType]'s axis (also selects that tab).
  void preview(String itemType, String itemId) {
    if (itemType == itemTypeBackdrop) {
      state = state.copyWith(tab: itemType, previewedBackdropId: itemId);
    } else {
      state = state.copyWith(tab: itemType, previewedSkinId: itemId);
    }
  }
}

/// AutoDispose is load-bearing, not an optimization. This state is transient
/// per-visit UI state, and [WardrobePreview.copyWith] treats `null` as "keep",
/// so there is no way to CLEAR a preview once set. App-scoped, it leaked across
/// visits two visible ways (I4):
///   • the tab: a reopened screen builds a fresh TabController, so the TabBar
///     underlined "Lanterns" while the body still read `tab == 'backdrop'` and
///     rendered the backdrop grid — and tapping "Lanterns" fired no change
///     event (index already 0), stranding the user.
///   • the previewed item: a previously-previewed LOCKED skin came back on the
///     stage as if it were equipped.
/// Disposing with the screen resets both. The screen watches this in `build`
/// (not only in the loaded branch) so it lives exactly as long as the screen,
/// and sources the TabController's initial index from the SAME state.
final wardrobePreviewProvider =
    NotifierProvider.autoDispose<WardrobePreviewNotifier, WardrobePreview>(
        WardrobePreviewNotifier.new);
