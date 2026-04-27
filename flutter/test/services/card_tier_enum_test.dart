import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/card_collection_service.dart';

void main() {
  group('Tier string ↔ int parser (F1 follow-up)', () {
    test('enumToTier maps emerald to 4', () {
      expect(enumToTier('emerald'), 4);
    });

    test('tierToEnum maps 4 to emerald', () {
      expect(tierToEnum(4), 'emerald');
    });

    test('all 4 tiers round-trip', () {
      for (final t in ['bronze', 'silver', 'gold', 'emerald']) {
        expect(tierToEnum(enumToTier(t)), t,
            reason: 'tier "$t" round-trip failed');
      }
    });
  });

  group('CardTier emerald (F1)', () {
    test('emerald is exposed as a tier value', () {
      expect(CardTier.values, contains(CardTier.emerald));
    });

    test('label/number/colorValue map for emerald', () {
      expect(CardTier.emerald.label, 'Emerald');
      expect(CardTier.emerald.number, 4);
      expect(CardTier.emerald.colorValue, 0xFF50C878);
    });

    test('fromNumber(4) resolves emerald', () {
      expect(CardTierX.fromNumber(4), CardTier.emerald);
    });

    test('all tier numbers round-trip through fromNumber', () {
      for (final t in CardTier.values) {
        expect(CardTierX.fromNumber(t.number), t,
            reason: 'tier ${t.label} round-trip failed');
      }
    });
  });
}
