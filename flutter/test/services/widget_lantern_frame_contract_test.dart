import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/services/widget_data_service.dart';

void main() {
  final catalogIds = <String>{
    for (final s in [...LanternSkin.all, ...LanternSkin.sculpted]) s.id,
  };

  test('every bundled skin id exists in the code catalog', () {
    expect(kWidgetBundledSkinIds.difference(catalogIds), isEmpty,
        reason: 'kWidgetBundledSkinIds names a skin LanternSkin does not define');
  });

  test('the widget default skin is itself bundled', () {
    expect(kWidgetBundledSkinIds, contains(kDefaultWidgetLanternSkinId));
    expect(kDefaultWidgetLanternSkinId, LanternSkin.classicGold.id);
  });

  test('widget brightnesses cover every reachable state and exclude dormant',
      () {
    expect(kWidgetCompanionBrightnesses,
        isNot(contains(CompanionBrightness.dormant)),
        reason: 'the Swift resolveCompanion never emits dormant — do not export it');
    final expected = CompanionBrightness.values.toSet()
      ..remove(CompanionBrightness.dormant);
    expect(kWidgetCompanionBrightnesses.toSet(), expected);
  });

  test('frame asset name is <skinId>_<brightness>', () {
    expect(
      companionWidgetFrameAsset('obsidian_gold', CompanionBrightness.fullyLit),
      'companion_obsidian_gold_fullyLit.png',
    );
  });

  test('a bundled skin id passes the eligibility filter unchanged', () {
    expect(widgetEligibleSkinId('obsidian_gold'), 'obsidian_gold');
  });

  test('an unbundled or malformed skin id falls back to the default', () {
    expect(widgetEligibleSkinId('not_a_skin'), kDefaultWidgetLanternSkinId);
    expect(widgetEligibleSkinId(''), kDefaultWidgetLanternSkinId);
    expect(widgetEligibleSkinId('../../etc/passwd'), kDefaultWidgetLanternSkinId);
  });
}
