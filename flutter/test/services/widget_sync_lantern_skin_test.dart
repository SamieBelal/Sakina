import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:sakina/services/widget_sync.dart';

CosmeticsState _state(String skinId) => CosmeticsState(
      noorBalance: 0,
      equippedLanternSkin: skinId,
      equippedBackdrop: 'default',
      ownedLanternSkins: <String>{skinId},
      ownedBackdrops: <String>{},
    );

void main() {
  test('returns the equipped skin from the cosmetics cache', () async {
    final skin = await resolveWidgetLanternSkin(
      readCosmetics: () async => _state('emerald_jade'),
    );
    expect(skin, 'emerald_jade');
  });

  test('an unreadable cosmetics cache falls back to the widget default',
      () async {
    final skin = await resolveWidgetLanternSkin(
      readCosmetics: () async => throw StateError('prefs unavailable'),
    );
    expect(skin, kDefaultWidgetLanternSkinId);
  });
}
