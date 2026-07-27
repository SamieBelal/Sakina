import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:sakina/services/widget_sync.dart';

CosmeticsState _state(String skinId, {Set<String>? owned}) => CosmeticsState(
      noorBalance: 0,
      equippedLanternSkin: skinId,
      equippedBackdrop: 'default',
      ownedLanternSkins: owned ?? <String>{skinId},
      ownedBackdrops: <String>{},
    );

void main() {
  test('returns the equipped skin from the cosmetics cache', () async {
    final skin = await resolveWidgetLanternSkin(
      readCosmetics: () async => _state('emerald_jade'),
      readPremium: () async => false,
    );
    expect(skin, 'emerald_jade');
  });

  test('an unreadable cosmetics cache falls back to the widget default',
      () async {
    final skin = await resolveWidgetLanternSkin(
      readCosmetics: () async => throw StateError('prefs unavailable'),
      readPremium: () async => false,
    );
    expect(skin, kDefaultWidgetLanternSkinId);
  });

  // The widget is a THIRD render surface for the equipped lantern, next to the
  // Companion stage and the Wardrobe preview. Both of those resolve through
  // `renderableSkinId` (`owned || (premium-exclusive && premium)`); the widget
  // used to read `equippedLanternSkin` raw, with `widgetEligibleSkinId` — a
  // BUNDLED-FRAMES budget filter, not an entitlement filter — as the only thing
  // downstream of it. That only failed to be exploitable because no
  // premium-exclusive skin happens to be bundled today.
  group('entitlement (same rule as the Companion stage and the Wardrobe)', () {
    test('lapsed subscriber with a premium-exclusive equipped → classic_gold',
        () async {
      // A premium-exclusive skin is never written to the owned cache — the
      // perk lasts while the subscription does and never converts to
      // ownership. So the lapse is exactly "equipped, not owned, not premium".
      final skin = await resolveWidgetLanternSkin(
        readCosmetics: () async => _state('ramadan_royal', owned: <String>{}),
        readPremium: () async => false,
      );
      expect(skin, defaultLanternSkin,
          reason: 'a lapsed subscriber must not keep a premium-exclusive '
              'lantern on their home screen indefinitely');
    });

    test('active subscriber with a premium-exclusive equipped → the real skin',
        () async {
      final skin = await resolveWidgetLanternSkin(
        readCosmetics: () async => _state('ramadan_royal', owned: <String>{}),
        readPremium: () async => true,
      );
      expect(skin, 'ramadan_royal',
          reason: 'entitlement is honored while premium is active — the '
              'bundled-frames budget is a separate, later filter');
    });

    test('an owned skin needs no premium', () async {
      final skin = await resolveWidgetLanternSkin(
        readCosmetics: () async =>
            _state('emerald_jade', owned: <String>{'emerald_jade'}),
        readPremium: () async => false,
      );
      expect(skin, 'emerald_jade');
    });

    test('a failed premium read falls back to the widget default', () async {
      final skin = await resolveWidgetLanternSkin(
        readCosmetics: () async => _state('emerald_jade'),
        readPremium: () async => throw StateError('RC unreachable'),
      );
      expect(skin, kDefaultWidgetLanternSkinId);
    });

    test('widgetEligibleSkinId still runs AFTER entitlement', () async {
      // The two filters compose in this order: entitlement decides WHAT the
      // user may see, the bundled set decides what this build can DRAW.
      //
      // Uses ramadan_gold, which is absent from cosmetic_catalog and therefore
      // ships no widget frames. This assertion previously used ramadan_royal,
      // but that skin is now bundled (every catalog skin is), so it no longer
      // demonstrates the bundling filter — the premise, not the rule, changed.
      final entitled = await resolveWidgetLanternSkin(
        readCosmetics: () async => _state('ramadan_gold', owned: <String>{}),
        readPremium: () async => true,
      );
      expect(widgetEligibleSkinId(entitled), kDefaultWidgetLanternSkinId,
          reason: 'ramadan_gold ships no widget frames in this build');
      expect(
        renderableSkinId(_state('ramadan_gold', owned: <String>{}),
            isPremium: true),
        entitled,
        reason: 'the widget must agree with the in-app resolver',
      );
    });

    test('the premium-exclusive now survives BOTH filters for a subscriber',
        () async {
      // ramadan_royal is bundled, so an ACTIVE subscriber sees the real perk on
      // the home screen instead of a classic_gold stand-in. Safe only because
      // resolveWidgetLanternSkin routes through renderableSkinId.
      final entitled = await resolveWidgetLanternSkin(
        readCosmetics: () async => _state('ramadan_royal', owned: <String>{}),
        readPremium: () async => true,
      );
      expect(widgetEligibleSkinId(entitled), 'ramadan_royal');
    });

    test('a LAPSED subscriber still falls back despite the skin being bundled',
        () async {
      // The entitlement filter, not the bundled set, is what protects this now.
      final lapsed = await resolveWidgetLanternSkin(
        readCosmetics: () async => _state('ramadan_royal', owned: <String>{}),
        readPremium: () async => false,
      );
      expect(widgetEligibleSkinId(lapsed), kDefaultWidgetLanternSkinId);
    });
  });
}
