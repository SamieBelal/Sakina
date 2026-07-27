// Pins Backdrop value equality — the perf contract for Lane D. When wardrobe/
// server data constructs a Backdrop (a separate instance from the static const
// singletons), it must still compare == to its value-twin so BackdropPainter's
// shouldRepaint keeps the static layer's raster cache instead of repainting it
// on every rebuild.
//
// These tests deliberately build NON-const Backdrops so the instances are
// genuinely distinct (const literals would be canonicalized to one object,
// making `identical` trivially true and defeating the value-equality check).
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/backdrop.dart';

void main() {
  test('two value-equal Backdrops (same id+theme) are == and share hashCode', () {
    // Non-const so the two are genuinely distinct instances (the Lane D path —
    // server/wardrobe data is not const-canonicalized).
    final a = Backdrop(
      id: 'laylat_night',
      name: 'Laylat Night',
      blurb: 'A mosque skyline beneath a crescent moon.',
      theme: BackdropTheme.laylatNight,
    );
    final b = Backdrop(
      id: 'laylat_night',
      name: 'Laylat Night',
      blurb: 'A mosque skyline beneath a crescent moon.',
      theme: BackdropTheme.laylatNight,
    );
    expect(identical(a, b), isFalse); // distinct instances
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('a server-shaped Backdrop equals its static-const twin', () {
    // Same id+theme as Backdrop.laylatNight but built fresh (Lane D path) —
    // non-const so it is a distinct instance, not the canonicalized singleton.
    final fromServer = Backdrop(
      id: 'laylat_night',
      name: 'Laylat Night',
      blurb: 'A mosque skyline beneath a crescent moon.',
      theme: BackdropTheme.laylatNight,
    );
    expect(identical(fromServer, Backdrop.laylatNight), isFalse);
    expect(fromServer, equals(Backdrop.laylatNight));
    expect(fromServer.hashCode, equals(Backdrop.laylatNight.hashCode));
  });

  test('backdrops with different ids are not equal', () {
    expect(Backdrop.laylatNight, isNot(equals(Backdrop.emeraldSanctuary)));
    expect(Backdrop.none, isNot(equals(Backdrop.laylatNight)));
  });
}
