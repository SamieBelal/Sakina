// Pins the wardrobe's primary-action gating (pure logic — no widgets, no I/O).
//
// The rules being held:
//   • Unlock is offered iff NOT owned AND affordable in Noor.
//   • An owned item is always Equip, never Unlock (the recorded P2 double-debit).
//   • Premium-exclusive is a teaser unless it is currently equippable; it is
//     never offered as a Noor unlock or a purchase.
//   • Buy is the à-la-carte fallback only — Noor first when affordable — and
//     only while the skin IAP is actually live (kSkinIapEnabled).

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_action_bar.dart';
import 'package:sakina/services/cosmetics_service.dart';

CosmeticsState _state({
  int noor = 0,
  Set<String> ownedSkins = const {},
  Set<String> ownedBackdrops = const {},
}) =>
    CosmeticsState(
      noorBalance: noor,
      equippedLanternSkin: 'classic_gold',
      equippedBackdrop: 'default',
      ownedLanternSkins: ownedSkins,
      ownedBackdrops: ownedBackdrops,
    );

void main() {
  final jade = catalogEntryFor(itemTypeLanternSkin, 'emerald_jade')!; // 120
  final royal = catalogEntryFor(itemTypeLanternSkin, 'ramadan_royal')!; // premium
  final obsidian =
      catalogEntryFor(itemTypeLanternSkin, 'obsidian_gold')!; // 200 + IAP
  final laylat = catalogEntryFor(itemTypeBackdrop, 'laylat_night')!; // 150

  test('unlock offered only when affordable and not owned', () {
    expect(
      resolveWardrobeAction(
          state: _state(noor: 120), entry: jade, equippable: false),
      WardrobeAction.unlock,
    );
    expect(
      resolveWardrobeAction(
          state: _state(noor: 119), entry: jade, equippable: false),
      WardrobeAction.unlockUnaffordable,
    );
    expect(
      resolveWardrobeAction(
          state: _state(noor: 50), entry: jade, equippable: false),
      WardrobeAction.unlockUnaffordable,
    );
  });

  test('the backdrop axis gates on the same rule', () {
    expect(
      resolveWardrobeAction(
          state: _state(noor: 150), entry: laylat, equippable: false),
      WardrobeAction.unlock,
    );
    expect(
      resolveWardrobeAction(
          state: _state(noor: 149), entry: laylat, equippable: false),
      WardrobeAction.unlockUnaffordable,
    );
    expect(
      resolveWardrobeAction(
        state: _state(noor: 999, ownedBackdrops: {'laylat_night'}),
        entry: laylat,
        equippable: true,
      ),
      WardrobeAction.equip,
    );
  });

  test('owned item is Equip, never Unlock (P2 double-debit guard)', () {
    expect(
      resolveWardrobeAction(
        state: _state(noor: 999, ownedSkins: {'emerald_jade'}),
        entry: jade,
        equippable: true,
      ),
      WardrobeAction.equip,
    );
    // Even if canEquip has not resolved yet, ownership alone forbids Unlock.
    expect(
      resolveWardrobeAction(
        state: _state(noor: 999, ownedSkins: {'emerald_jade'}),
        entry: jade,
        equippable: false,
      ),
      WardrobeAction.equip,
    );
  });

  test('the always-owned defaults are Equip, never a purchase', () {
    final classic = catalogEntryFor(itemTypeLanternSkin, defaultLanternSkin)!;
    final none = catalogEntryFor(itemTypeBackdrop, defaultBackdrop)!;
    expect(
      resolveWardrobeAction(
          state: _state(), entry: classic, equippable: false),
      WardrobeAction.equip,
    );
    expect(
      resolveWardrobeAction(state: _state(), entry: none, equippable: false),
      WardrobeAction.equip,
    );
  });

  test('premium-exclusive shows a teaser when not premium/owned', () {
    expect(
      resolveWardrobeAction(
          state: _state(noor: 999), entry: royal, equippable: false),
      WardrobeAction.premiumTeaser,
    );
  });

  test('premium-exclusive becomes Equip when canEquip resolves true (premium)',
      () {
    expect(
      resolveWardrobeAction(state: _state(), entry: royal, equippable: true),
      WardrobeAction.equip,
    );
  });

  test('à-la-carte prefers Noor when affordable, Buy only as the fallback', () {
    expect(
      resolveWardrobeAction(
          state: _state(noor: 200), entry: obsidian, equippable: false),
      WardrobeAction.unlock,
    );
    // The real-money fallback is gated on kSkinIapEnabled: while the SKUs are
    // not live it degrades to an inert teaser rather than a CTA that cannot
    // charge (see wardrobe_iap_disabled_test.dart).
    expect(
      resolveWardrobeAction(
          state: _state(noor: 10), entry: obsidian, equippable: false),
      kSkinIapEnabled
          ? WardrobeAction.buy
          : WardrobeAction.comingSoonTeaser,
    );
    // Owned still wins over both.
    expect(
      resolveWardrobeAction(
        state: _state(noor: 0, ownedSkins: {'obsidian_gold'}),
        entry: obsidian,
        equippable: true,
      ),
      WardrobeAction.equip,
    );
  });
}
