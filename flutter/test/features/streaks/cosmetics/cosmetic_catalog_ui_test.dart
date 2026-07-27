import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/services/cosmetics_service.dart';

void main() {
  test('resolveSkin returns the value-equal LanternSkin for an id', () {
    expect(resolveSkin('emerald_jade'), LanternSkin.emeraldJade);
    expect(resolveSkin('masjid_brass'), LanternSkin.masjidBrass);
    expect(resolveSkin('classic_gold'), LanternSkin.classicGold);
  });

  test('resolveSkin falls back to classicGold for an unknown id', () {
    expect(resolveSkin('does_not_exist'), LanternSkin.classicGold);
  });

  test('resolveBackdrop maps default to Backdrop.none, else the value twin', () {
    expect(resolveBackdrop('default'), Backdrop.none);
    expect(resolveBackdrop('laylat_night'), Backdrop.laylatNight);
    expect(resolveBackdrop('unknown'), Backdrop.none);
  });

  test('catalog entries mirror the seed pricing/gating', () {
    final jade = catalogEntryFor(itemTypeLanternSkin, 'emerald_jade')!;
    expect(jade.noorPrice, 120);
    expect(jade.iapProductId, isNull);
    expect(jade.isPremiumExclusive, isFalse);

    final obsidian = catalogEntryFor(itemTypeLanternSkin, 'obsidian_gold')!;
    expect(obsidian.iapProductId, 'sakina.skin.obsidian');

    final royal = catalogEntryFor(itemTypeLanternSkin, 'ramadan_royal')!;
    expect(royal.isPremiumExclusive, isTrue);
    expect(royal.noorPrice, isNull);

    final laylat = catalogEntryFor(itemTypeBackdrop, 'laylat_night')!;
    expect(laylat.noorPrice, 150);
  });

  test('displayCatalog lists lantern and backdrop items in sort order', () {
    final skins = displayCatalog(itemTypeLanternSkin);
    expect(skins.first.itemId, 'classic_gold'); // sort 0
    expect(skins.map((e) => e.itemId), contains('ramadan_royal'));
    final backs = displayCatalog(itemTypeBackdrop);
    expect(backs.first.itemId, 'default');
  });
}
