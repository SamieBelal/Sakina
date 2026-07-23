// test/features/daily/reveal_spec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/models/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';

void main() {
  test('every tier has a spec and escalates', () {
    final b = revealSpecFor(CardTier.bronze);
    final s = revealSpecFor(CardTier.silver);
    final g = revealSpecFor(CardTier.gold);
    final e = revealSpecFor(CardTier.emerald);

    // Duration escalates strictly.
    expect(b.duration < s.duration, isTrue);
    expect(s.duration < g.duration, isTrue);
    expect(g.duration < e.duration, isTrue);

    // Spin escalates; Bronze does not spin.
    expect(b.spinTurns, 0);
    expect([s.spinTurns, g.spinTurns, e.spinTurns], [1, 2, 3]);

    // Emerald exclusives.
    expect(e.halo, isTrue);
    expect(b.halo || s.halo || g.halo, isFalse);
    expect(e.foil, 1.0);

    // Tier colour matches the card system.
    expect(e.tierColor.toARGB32(), CardTier.emerald.colorValue);
  });
}
