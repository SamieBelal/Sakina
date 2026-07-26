import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/services/cosmetics_service.dart';

void main() {
  test('preview provider starts empty and updates per axis', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(wardrobePreviewProvider).previewedSkinId, isNull);
    expect(container.read(wardrobePreviewProvider).tab, itemTypeLanternSkin);

    container
        .read(wardrobePreviewProvider.notifier)
        .preview(itemTypeLanternSkin, 'emerald_jade');
    expect(
        container.read(wardrobePreviewProvider).previewedSkinId, 'emerald_jade');

    container
        .read(wardrobePreviewProvider.notifier)
        .preview(itemTypeBackdrop, 'laylat_night');
    expect(container.read(wardrobePreviewProvider).previewedBackdropId,
        'laylat_night');

    container.read(wardrobePreviewProvider.notifier).setTab(itemTypeBackdrop);
    expect(container.read(wardrobePreviewProvider).tab, itemTypeBackdrop);
  });

  test('cosmeticsStateProvider is overridable for tests', () async {
    final container = ProviderContainer(overrides: [
      cosmeticsStateProvider.overrideWith((ref) async => const CosmeticsState(
            noorBalance: 500,
            equippedLanternSkin: 'classic_gold',
            equippedBackdrop: 'default',
            ownedLanternSkins: {},
            ownedBackdrops: {},
          )),
    ]);
    addTearDown(container.dispose);
    final state = await container.read(cosmeticsStateProvider.future);
    expect(state.noorBalance, 500);
  });
}
