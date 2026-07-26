// Pins LanternSkin + LanternForm value equality — the perf/API contract for
// Lane D, mirroring backdrop_equality_test.dart. When wardrobe/server data
// reconstructs a skin (a separate instance from the static const singletons),
// it must still compare == to its value-twin so LanternPainter.shouldRepaint
// keeps the raster cache instead of repainting on every rebuild.
//
// Deliberately builds NON-const instances so the two are genuinely distinct
// (const literals would be canonicalized to one object, making `identical`
// trivially true and defeating the value-equality check).
// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';

void main() {
  group('LanternForm value equality', () {
    test('two value-equal forms are == and share hashCode', () {
      final a = LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.crescentStar,
        archedWindow: true,
        lattice: true,
      );
      final b = LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.crescentStar,
        archedWindow: true,
        lattice: true,
      );
      expect(identical(a, b), isFalse); // distinct instances
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a server-shaped form equals its static-const twin', () {
      final fromServer = LanternForm(
        dome: DomeShape.tiered,
        finial: FinialType.crescent,
        archedWindow: true,
        lattice: true,
        tassel: true,
      );
      expect(identical(fromServer, LanternSkin.ramadanRoyal.form), isFalse);
      expect(fromServer, equals(LanternSkin.ramadanRoyal.form));
      expect(fromServer.hashCode, equals(LanternSkin.ramadanRoyal.form.hashCode));
    });

    test('forms differing in any single field are not equal', () {
      final base = LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.star,
        archedWindow: true,
        lattice: true,
        tassel: false,
      );
      expect(base, isNot(equals(LanternForm(
        dome: DomeShape.onion, // dome differs
        finial: FinialType.star,
        archedWindow: true,
        lattice: true,
      ))));
      expect(base, isNot(equals(LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.ring, // finial differs
        archedWindow: true,
        lattice: true,
      ))));
      expect(base, isNot(equals(LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.star,
        archedWindow: false, // archedWindow differs
        lattice: true,
      ))));
      expect(base, isNot(equals(LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.star,
        archedWindow: true,
        lattice: false, // lattice differs
      ))));
      expect(base, isNot(equals(LanternForm(
        dome: DomeShape.ogee,
        finial: FinialType.star,
        archedWindow: true,
        lattice: true,
        tassel: true, // tassel differs
      ))));
    });
  });

  group('LanternSkin value equality', () {
    LanternSkin twin() => LanternSkin(
          id: 'masjid_brass',
          name: 'Masjid Lantern',
          blurb: 'Ogee dome, crescent-and-star, a mashrabiya screen.',
          metalTop: Color(0xFFF3DCA2),
          metalMid: Color(0xFFD8A55E),
          metalBot: Color(0xFFA9762F),
          metalDark: Color(0xFF5F4118),
          highlight: Color(0xFFFDEFC6),
          glow: Color(0xFFEEB65C),
          ember: Color(0xFFFFDD97),
          glass: Color(0xFF0A2A1B),
          dustyTop: Color(0xFFB0A078),
          dustyBot: Color(0xFF6A5A3A),
          form: LanternForm(
            dome: DomeShape.ogee,
            finial: FinialType.crescentStar,
            archedWindow: true,
            lattice: true,
          ),
        );

    test('two value-equal skins are == and share hashCode', () {
      final a = twin();
      final b = twin();
      expect(identical(a, b), isFalse); // distinct instances
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a server-shaped skin equals its static-const twin', () {
      final fromServer = twin();
      expect(identical(fromServer, LanternSkin.masjidBrass), isFalse);
      expect(fromServer, equals(LanternSkin.masjidBrass));
      expect(fromServer.hashCode, equals(LanternSkin.masjidBrass.hashCode));
    });

    test('skins with different ids are not equal', () {
      expect(LanternSkin.masjidBrass, isNot(equals(LanternSkin.ramadanRoyal)));
      expect(LanternSkin.classicGold, isNot(equals(LanternSkin.moonlitSilver)));
    });

    test('skins differing only in a render-affecting field are not equal', () {
      // Same id but a different palette color → must still be unequal so a stale
      // recolor forces a repaint.
      final recolored = LanternSkin(
        id: 'masjid_brass',
        name: 'Masjid Lantern',
        blurb: 'Ogee dome, crescent-and-star, a mashrabiya screen.',
        metalTop: Color(0xFFFFFFFF), // differs
        metalMid: Color(0xFFD8A55E),
        metalBot: Color(0xFFA9762F),
        metalDark: Color(0xFF5F4118),
        highlight: Color(0xFFFDEFC6),
        glow: Color(0xFFEEB65C),
        ember: Color(0xFFFFDD97),
        glass: Color(0xFF0A2A1B),
        dustyTop: Color(0xFFB0A078),
        dustyBot: Color(0xFF6A5A3A),
        form: LanternForm(
          dome: DomeShape.ogee,
          finial: FinialType.crescentStar,
          archedWindow: true,
          lattice: true,
        ),
      );
      expect(recolored, isNot(equals(LanternSkin.masjidBrass)));
    });

    test('skins differing only in form are not equal', () {
      final differentForm = LanternSkin(
        id: 'masjid_brass',
        name: 'Masjid Lantern',
        blurb: 'Ogee dome, crescent-and-star, a mashrabiya screen.',
        metalTop: Color(0xFFF3DCA2),
        metalMid: Color(0xFFD8A55E),
        metalBot: Color(0xFFA9762F),
        metalDark: Color(0xFF5F4118),
        highlight: Color(0xFFFDEFC6),
        glow: Color(0xFFEEB65C),
        ember: Color(0xFFFFDD97),
        glass: Color(0xFF0A2A1B),
        dustyTop: Color(0xFFB0A078),
        dustyBot: Color(0xFF6A5A3A),
        form: LanternForm(dome: DomeShape.onion), // classic form, arched=false
      );
      expect(differentForm, isNot(equals(LanternSkin.masjidBrass)));
    });
  });
}
