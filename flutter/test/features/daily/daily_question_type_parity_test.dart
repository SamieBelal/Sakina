// The daily question and the onboarding hook screen are the SAME ask.
//
// Same sentence, same seven options, same `problem_chips.dart` taxonomy, one on
// cream and one on the sacred canvas. The treatment differs on purpose — the
// canvas needs cream ink and gold accents where the hook screen needs emerald on
// cream — but the TYPE SCALE has no reason to differ, and when it drifted the
// result was reported from device as "the heading looks very small… the entire
// screen just does not have that presence" (founder, 2026-07-31).
//
// What had happened is the kind of thing no single review catches, because each
// file is defensible alone: the daily copy rendered its title at
// `headlineMedium` (20pt — the BOTTOM of the headline range, and 14pt under the
// "all main screen titles use displayLarge" note in `app_typography.dart`) and
// its options at `bodyMedium` (15pt), while the twin used `displayMedium` (28pt,
// `displaySmall` when short) and `bodyLarge` (17pt). Two screens asking one
// question, one of them whispering.
//
// So this test does not check that the daily screen is "big enough" — that is a
// judgement no assertion can hold. It checks the two files agree, which is
// falsifiable, and which is the property that was actually broken.
//
// A source-read test, like `home_card_spacing_test.dart`: the claim is about two
// files' relationship, and no rendering of either one alone can see it. It is
// also the only honest option here — no font is bundled (`google_fonts` fetches
// Outfit at runtime), so a widget test comparing rendered metrics would be
// comparing the framework's fallback font to itself.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final dailyHeader =
      File('lib/features/daily/widgets/daily_question_header.dart')
          .readAsStringSync();
  final hookHeader =
      File('lib/features/onboarding/widgets/hook_screen_header.dart')
          .readAsStringSync();
  final dailyChip =
      File('lib/features/daily/widgets/daily_question_chip.dart')
          .readAsStringSync();
  final hookChip =
      File('lib/features/onboarding/widgets/problem_chip_card.dart')
          .readAsStringSync();
  final dailyPrompt =
      File('lib/features/daily/widgets/daily_question_prompt.dart')
          .readAsStringSync();
  final hookScreen =
      File('lib/features/onboarding/screens/hook_problem_screen.dart')
          .readAsStringSync();

  test('both headers take the same two type steps', () {
    for (final step in ['displayMedium', 'displaySmall']) {
      expect(
        hookHeader.contains('AppTypography.$step'),
        isTrue,
        reason: 'the hook header is the reference for this parity test — if it '
            'no longer uses $step, decide deliberately what the pair should be '
            'and update BOTH, rather than letting them drift',
      );
      expect(
        dailyHeader.contains('AppTypography.$step'),
        isTrue,
        reason: 'the daily question asks the same thing as the hook screen and '
            'must not ask it more quietly. It shipped at headlineMedium (20pt) '
            'against the twin\'s $step, and that is what "the heading looks '
            'very small" was reporting',
      );
    }
  });

  test('both option labels are bodyLarge', () {
    expect(hookChip.contains('AppTypography.bodyLarge'), isTrue);
    expect(
      dailyChip.contains('AppTypography.bodyLarge'),
      isTrue,
      reason: 'the same seven sentences render at 17pt in onboarding. At 15pt '
          'here they read as a caption of the option rather than as the option',
    );
    expect(
      dailyChip.contains('AppTypography.bodyMedium'),
      isFalse,
      reason: 'the label is the only text in this row — a bodyMedium here is '
          'the drift coming back',
    );
  });

  test('both screens compact at the same height', () {
    // 700pt is not arbitrary: below it the seventh option — "I can't put it
    // into words" — falls under the fold at the roomy metrics, and that is the
    // option that must stay on screen, because it is the one chosen by someone
    // who cannot name what they are carrying. The hook screen documents this
    // and is pinned by hook_problem_screen_small_device_test.dart.
    expect(hookScreen.contains('_compactHeightThreshold = 700'), isTrue);
    expect(
      dailyPrompt.contains('_compactHeightThreshold = 700'),
      isTrue,
      reason: 'one breakpoint across both surfaces, or a device lands in the '
          'roomy rhythm on one screen and the compact one on the other',
    );
  });

  test('the daily screen threads one breakpoint rather than reading it twice',
      () {
    // The failure this prevents is subtle and would look fine in review: each
    // widget reads `MediaQuery` for itself, someone later changes one
    // threshold, and the header takes the compact step while the rows keep the
    // roomy padding. Computing it once in the host and passing it down makes
    // that impossible to express.
    for (final widget in [dailyHeader, dailyChip]) {
      expect(
        widget.contains('MediaQuery.sizeOf'),
        isFalse,
        reason: 'the breakpoint is the host\'s to compute and pass as '
            '`compact`, so the whole surface steps together',
      );
    }
    expect(dailyPrompt.contains('MediaQuery.sizeOf(context).height'), isTrue);
  });
}
