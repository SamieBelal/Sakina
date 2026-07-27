// Guard: every widget-eligible skin must have a COMPLETE set of exported frames
// committed under ios/SakinaWidget/. This is what stops kWidgetBundledSkinIds
// from outrunning the PNGs on disk (which would show a fallback lantern, or on
// a broken fallback chain, nothing at all).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/widget_data_service.dart';

void main() {
  test('every bundled skin has a complete widget frame set on disk', () {
    final dir = Directory('ios/SakinaWidget');
    expect(dir.existsSync(), isTrue,
        reason: 'run from the flutter/ project root');

    final missing = <String>[];
    for (final skinId in kWidgetBundledSkinIds) {
      for (final brightness in kWidgetCompanionBrightnesses) {
        final file =
            File('${dir.path}/${companionWidgetFrameAsset(skinId, brightness)}');
        if (!file.existsSync() || file.lengthSync() == 0) {
          missing.add(file.path);
        }
      }
    }

    expect(missing, isEmpty,
        reason: 'regenerate with: GEN_WIDGET_FRAMES=1 flutter test '
            'test/widgets/gen_companion_skin_frames_test.dart');
  });
}
