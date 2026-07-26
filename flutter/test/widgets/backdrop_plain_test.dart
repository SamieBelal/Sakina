// Backdrop.none must be a plain surface, NOT the emerald sanctuary scene.
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';

void main() {
  test('Backdrop.none uses the plain theme (not emeraldSanctuary)', () {
    expect(Backdrop.none.theme, BackdropTheme.plain);
    expect(Backdrop.none.theme, isNot(BackdropTheme.emeraldSanctuary));
  });

  test('Backdrop.all still excludes none', () {
    expect(Backdrop.all, isNot(contains(Backdrop.none)));
  });
}
