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
final cosmeticsStateProvider = FutureProvider<CosmeticsState>((ref) async {
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

class WardrobePreviewNotifier extends Notifier<WardrobePreview> {
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

final wardrobePreviewProvider =
    NotifierProvider<WardrobePreviewNotifier, WardrobePreview>(
        WardrobePreviewNotifier.new);
