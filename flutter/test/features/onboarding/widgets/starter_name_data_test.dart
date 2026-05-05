import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/demo_result_card.dart';
import 'package:sakina/services/card_collection_service.dart';

void main() {
  group('StarterNameData.catalogId', () {
    test('every entry resolves to a real CollectibleName', () {
      // If the catalog gets renumbered, this test breaks before the new-user
      // flow silently writes a non-existent name_id into user_profiles.
      for (final s in StarterNameData.all) {
        final exists = allCollectibleNames.any((n) => n.id == s.catalogId);
        expect(exists, isTrue,
            reason:
                'StarterNameData ${s.nameTransliteration} (catalogId=${s.catalogId}) is not in allCollectibleNames');
      }
    });
  });

  group('StarterNameData.forEmotion', () {
    void expectsName(String input, int expectedId, String label) {
      expect(StarterNameData.forEmotion(input).catalogId, expectedId,
          reason: '"$input" should map to $label (id=$expectedId)');
    }

    test('anxious-family inputs map to As-Salam (6)', () {
      expectsName('anxious', 6, 'As-Salam');
      expectsName('I feel anxiety today', 6, 'As-Salam');
      expectsName('overwhelmed', 6, 'As-Salam');
      expectsName('panic', 6, 'As-Salam');
      expectsName('worried', 6, 'As-Salam');
      expectsName('I am scared', 6, 'As-Salam');
    });

    test('sad-family inputs map to Al-Jabbar (9)', () {
      expectsName('sad', 9, 'Al-Jabbar');
      expectsName('grief', 9, 'Al-Jabbar');
      expectsName('I feel broken', 9, 'Al-Jabbar');
      expectsName('depressed lately', 9, 'Al-Jabbar');
      expectsName('low', 9, 'Al-Jabbar');
    });

    test('grateful-family inputs map to Ash-Shakur (28)', () {
      expectsName('grateful', 28, 'Ash-Shakur');
      expectsName('feeling thankful', 28, 'Ash-Shakur');
      expectsName('I feel blessed', 28, 'Ash-Shakur');
    });

    test('angry-family inputs map to As-Sabur (32)', () {
      expectsName('angry', 32, 'As-Sabur');
      expectsName('frustrated', 32, 'As-Sabur');
      expectsName('irritated', 32, 'As-Sabur');
    });

    test('lost-family inputs map to Al-Hadi (33)', () {
      expectsName('lost', 33, 'Al-Hadi');
      expectsName('lonely', 33, 'Al-Hadi');
      expectsName('I feel disconnected', 33, 'Al-Hadi');
    });

    test('hopeful-family inputs map to Al-Wakeel (35)', () {
      expectsName('hopeful', 35, 'Al-Wakeel');
      expectsName('optimistic', 35, 'Al-Wakeel');
    });

    test('empty / unmatched inputs fall through to Ar-Rahman (2)', () {
      expectsName('', 2, 'Ar-Rahman');
      expectsName('tired', 2, 'Ar-Rahman');
      expectsName('whatever', 2, 'Ar-Rahman');
    });

    test('case-insensitive matching', () {
      expect(StarterNameData.forEmotion('ANXIOUS').catalogId, 6);
      expect(StarterNameData.forEmotion('Grateful').catalogId, 28);
    });
  });
}
