// I2: which equipped skin actually gets RENDERED.
//
// Premium-exclusive skins are never written to the owned cache — the perk lasts
// while the subscription is active and never converts to permanent ownership.
// So `owned` alone is the WRONG render gate: it fired the "premium lapsed →
// classic gold" fallback for active subscribers too, and a paying user who
// equipped Ramadan Royal saw a Classic Brass lantern.
//
// The rule is the same one `CosmeticsService.canEquip` applies, minus the async
// premium read: owned || (premium-exclusive && premium). Both the Companion
// stage and the Wardrobe preview stage go through this one function so they
// cannot drift apart.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/services/cosmetics_service.dart';

CosmeticsState _state(String equipped, {Set<String> owned = const {}}) =>
    CosmeticsState(
      noorBalance: 0,
      equippedLanternSkin: equipped,
      equippedBackdrop: 'default',
      ownedLanternSkins: owned,
      ownedBackdrops: const {},
    );

void main() {
  test('an owned skin renders regardless of premium', () {
    expect(
      renderableSkinId(_state('emerald_jade', owned: {'emerald_jade'}),
          isPremium: false),
      'emerald_jade',
    );
  });

  test('the always-owned default renders', () {
    expect(renderableSkinId(_state(defaultLanternSkin), isPremium: false),
        defaultLanternSkin);
  });

  test('a premium-exclusive skin renders while premium is ACTIVE', () {
    // Deliberately NOT in the owned set — that is the correct cache state.
    expect(renderableSkinId(_state('ramadan_royal'), isPremium: true),
        'ramadan_royal');
  });

  test('a premium-exclusive skin falls back to classic once premium lapses',
      () {
    expect(renderableSkinId(_state('ramadan_royal'), isPremium: false),
        defaultLanternSkin);
  });

  test('premium does not render an ordinary unowned skin', () {
    expect(renderableSkinId(_state('emerald_jade'), isPremium: true),
        defaultLanternSkin);
  });

  test('an unknown equipped id falls back to classic', () {
    expect(renderableSkinId(_state('not_a_skin'), isPremium: true),
        defaultLanternSkin);
  });
}
