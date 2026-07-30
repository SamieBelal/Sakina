import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/content/daily_question_copy.dart';
import 'package:sakina/features/progress/widgets/daily_loop_cta_card.dart';

/// The day's question is one sentence, on four surfaces (W4 Wave 6 review, F3).
///
/// Wave 6's claim is that the widget, the home CTA and the question screen say
/// **the same thing** — "so the three surfaces are one sentence rather than
/// three". That is a real product property: a user who reads the widget and
/// then taps into the app should meet the sentence they were just asked, not a
/// paraphrase of it.
///
/// Nothing enforced it. The sentence is written out three times — once as a
/// Swift string literal inside the widget extension, twice as Dart constants —
/// and the first person to reword the Dart copy would have broken the claim
/// silently. The Swift copy is the dangerous one: **no Dart test can see it**,
/// it ships inside a separate target, and it had never been rendered.
///
/// So this reads the Swift source the way `muhasabah_screen_source_test.dart`
/// reads its screen, and `tour_cta_copy_drift_test.dart` reads its tour step —
/// the same guard the team built two hours earlier for the same class of bug,
/// extended to the boundary Dart cannot otherwise reach.
void main() {
  group('the daily question reads identically on every surface', () {
    test('the home CTA and the question screen are the same sentence', () {
      expect(DailyLoopCtaCopy.notStarted, DailyQuestionCopy.header,
          reason: 'the button and the prompt must not drift apart — the CTA '
              'is the promise the question screen has to keep');
    });

    test('the iOS widget carries that exact sentence', () {
      final swift =
          File('ios/SakinaWidget/SakinaWidget.swift').readAsStringSync();

      expect(swift.contains(DailyQuestionCopy.header), isTrue,
          reason: 'SakinaWidget.swift must contain '
              '"${DailyQuestionCopy.header}" verbatim. If this fails you have '
              'almost certainly reworded the Dart copy without touching the '
              'Swift literal in the widget extension — which no other test can '
              'see, and which ships to the Home Screen where it is read more '
              'often than any other copy in the product.');
    });

    test('the widget still withholds any Name in that state', () {
      // The invitation replaced a Name. Guard the pair together: a future edit
      // that reinstates a Name field in the awaiting hero would undo the whole
      // wave, and it would look like a rendering improvement in review.
      final swift =
          File('ios/SakinaWidget/SakinaWidget.swift').readAsStringSync();
      final hero = swift.substring(swift.indexOf('struct AwaitingHero'));
      final heroBody = hero.substring(0, hero.indexOf('\n}'));

      for (final banned in ['display.arabic', 'display.transliteration']) {
        expect(heroBody.contains(banned), isFalse,
            reason: 'AwaitingHero must name no Name — pre-reveal there is no '
                'Name that is true, which is the entire point of W4 Wave 6');
      }
    });
  });
}
