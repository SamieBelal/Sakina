// Pins the grid's tile-status mapping (pure logic).
//
// The status resolver is a TOP-LEVEL function so it is testable directly, and
// it takes the ONE premium bool the screen resolves per open — the grid must
// never fan out an async canEquip per tile. The invariant this file protects:
// a premium-exclusive item is `equippable` while premium is active and
// `premiumLocked` otherwise — NEVER `owned`, because the perk lasts only while
// the subscription does.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:sakina/services/cosmetics_service.dart';

CosmeticsState _state({
  String skin = 'classic_gold',
  String backdrop = 'default',
  Set<String> ownedSkins = const {},
  Set<String> ownedBackdrops = const {},
}) =>
    CosmeticsState(
      noorBalance: 0,
      equippedLanternSkin: skin,
      equippedBackdrop: backdrop,
      ownedLanternSkins: ownedSkins,
      ownedBackdrops: ownedBackdrops,
    );

WardrobeTileStatus _status(
  CosmeticCatalogEntry entry, {
  required CosmeticsState state,
  bool isPremium = false,
}) =>
    resolveWardrobeTileStatus(
        entry: entry, state: state, isPremium: isPremium);

void main() {
  final classic = catalogEntryFor(itemTypeLanternSkin, 'classic_gold')!;
  final jade = catalogEntryFor(itemTypeLanternSkin, 'emerald_jade')!;
  final obsidian = catalogEntryFor(itemTypeLanternSkin, 'obsidian_gold')!;
  final royal = catalogEntryFor(itemTypeLanternSkin, 'ramadan_royal')!;
  final laylat = catalogEntryFor(itemTypeBackdrop, 'laylat_night')!;
  final none = catalogEntryFor(itemTypeBackdrop, 'default')!;

  test('the equipped item on each axis reads as equipped', () {
    expect(_status(classic, state: _state()), WardrobeTileStatus.equipped);
    expect(_status(none, state: _state()), WardrobeTileStatus.equipped);
    expect(
      _status(jade,
          state: _state(skin: 'emerald_jade', ownedSkins: {'emerald_jade'})),
      WardrobeTileStatus.equipped,
    );
    expect(
      _status(laylat,
          state: _state(
              backdrop: 'laylat_night', ownedBackdrops: {'laylat_night'})),
      WardrobeTileStatus.equipped,
    );
  });

  test('an owned but not-equipped item reads as owned', () {
    expect(
      _status(jade, state: _state(ownedSkins: {'emerald_jade'})),
      WardrobeTileStatus.owned,
    );
    expect(
      _status(laylat, state: _state(ownedBackdrops: {'laylat_night'})),
      WardrobeTileStatus.owned,
    );
  });

  test('premium-exclusive is equippable while premium, never owned', () {
    expect(
      _status(royal, state: _state(), isPremium: true),
      WardrobeTileStatus.equippable,
    );
  });

  test('premium-exclusive is premiumLocked without premium', () {
    expect(
      _status(royal, state: _state(), isPremium: false),
      WardrobeTileStatus.premiumLocked,
    );
  });

  test('à-la-carte and plain unowned items read as their own locked states',
      () {
    expect(
      _status(obsidian, state: _state()),
      WardrobeTileStatus.alaCarteLocked,
    );
    expect(_status(jade, state: _state()), WardrobeTileStatus.locked);
    expect(_status(laylat, state: _state()), WardrobeTileStatus.locked);
  });

  test('premium does not relabel non-premium-exclusive items', () {
    expect(
      _status(jade, state: _state(), isPremium: true),
      WardrobeTileStatus.locked,
    );
    expect(
      _status(obsidian, state: _state(), isPremium: true),
      WardrobeTileStatus.alaCarteLocked,
    );
  });

  test('an actually-purchased à-la-carte skin reads as owned', () {
    expect(
      _status(obsidian, state: _state(ownedSkins: {'obsidian_gold'})),
      WardrobeTileStatus.owned,
    );
  });
}
