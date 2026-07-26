// Riverpod UI-layer state for the wardrobe (this is the UI layer — Riverpod is
// allowed here, unlike the service layer). Reads flow through Lane B's
// getCosmeticsState(); mutations are done by the screen calling the service and
// then invalidating cosmeticsStateProvider to re-read the mirrored cache.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/features/streaks/providers/companion_inputs_provider.dart';
import 'package:sakina/services/cosmetics_service.dart';

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
