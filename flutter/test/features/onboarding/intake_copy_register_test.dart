import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/help_chips.dart';
import 'package:sakina/features/onboarding/content/intake_questions.dart';

/// The Wave H copy rules as a test (spec §8, §10).
///
/// Wave H triples the number of questions the app asks about the user, and every
/// one of them is a new place a growth-product or a lapse-presupposing register
/// could creep in. This walks the user-facing string literals in the new intake
/// files and fails on the registers the spec bans:
///
///   * **"again" / "slip"** — the corrected ICP is a Muslim at ANY level of
///     practice in a period of real difficulty. A devout user having the worst
///     month of their life must not be told they drifted. This is what retires
///     the old aspiration wording ("To feel close to Allah again", "even when I
///     slip"), and it is one innocent copy edit from reverting, which is exactly
///     why it is pinned.
///   * **prescription** — "just pray more" is the advice this user has already
///     failed at, and the top-ranked bounce trigger.
///   * **claims about Allah** — no stance, intent or outcome may be attributed
///     to Him. Safe promises are about the user's own knowledge, words or
///     practice.
///   * **streak / habit / goal framing** and **Arabic inside a Latin literal**,
///     carried over from `reel_copy_register_test.dart` because the same bans
///     apply to every screen between the reveal and signup.
///
/// Comment lines are stripped before scanning, so this file's own vocabulary and
/// the sources' explanatory prose are not the thing under test — the strings the
/// user actually reads are.
void main() {
  const files = [
    'lib/features/onboarding/content/help_chips.dart',
    'lib/features/onboarding/content/intake_questions.dart',
    'lib/features/onboarding/screens/daily_time_screen.dart',
    'lib/features/onboarding/screens/heaviest_time_screen.dart',
    'lib/features/onboarding/screens/help_chips_screen.dart',
    'lib/features/onboarding/screens/intake_note_screen.dart',
    'lib/features/onboarding/screens/names_known_screen.dart',
    'lib/features/onboarding/screens/told_anyone_screen.dart',
    'lib/features/onboarding/widgets/intake_chip.dart',
    'lib/features/onboarding/widgets/intake_chip_cloud.dart',
    'lib/features/onboarding/widgets/reel_continue_question.dart',
  ];

  final singleQuoted = RegExp(r"'(?:[^'\\\n]|\\.)*'");
  final doubleQuoted = RegExp(r'"(?:[^"\\\n]|\\.)*"');

  /// Every string literal in [path], minus comments and directive lines.
  List<String> literalsIn(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '$path is missing');
    final literals = <String>[];
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('import ') ||
          trimmed.startsWith('export ') ||
          trimmed.startsWith('library')) {
        continue;
      }
      for (final match in singleQuoted.allMatches(line)) {
        literals.add(match.group(0)!);
      }
      for (final match in doubleQuoted.allMatches(line)) {
        literals.add(match.group(0)!);
      }
    }
    return literals;
  }

  void expectNoMatch(RegExp banned, String reason) {
    for (final path in files) {
      for (final literal in literalsIn(path)) {
        expect(
          banned.hasMatch(literal.toLowerCase()),
          isFalse,
          reason: '$path — $literal: $reason',
        );
      }
    }
  }

  /// Every option label and question stem the user reads, gathered from the
  /// data rather than the source — so a copy edit that moves a string out of a
  /// literal and into a builder is still covered.
  List<String> optionCopy() => [
        heaviestQuestionLabel,
        heaviestSublineLabel,
        toldAnyoneQuestionLabel,
        toldAnyoneSublineLabel,
        namesKnownQuestionLabel,
        namesKnownSublineLabel,
        dailyTimeQuestionLabel,
        dailyTimeSublineLabel,
        helpChipsQuestionLabel,
        helpChipsSublineLabel,
        intakeNoteQuestionLabel,
        intakeNoteSublineLabel,
        intakeNoteHintLabel,
        intakeNoteSkipLabel,
        for (final o in heaviestTimes) o.label,
        for (final o in toldAnyoneOptions) o.label,
        for (final o in namesKnownOptions) o.label,
        for (final o in dailyTimeOptions) o.label,
        for (final c in helpChips) c.label,
        for (final key in [
          null,
          ...heaviestTimes.map((o) => o.key),
        ])
          heaviestPlanLine(key),
        for (final key in [null, ...toldAnyoneOptions.map((o) => o.key)])
          toldAnyonePlanLine(key),
        for (final key in [null, ...dailyTimeOptions.map((o) => o.key)])
          dailyTimePacingLine(key),
        for (final o in namesKnownOptions) namesKnownProjectionLine(o.key)!,
        for (final o in toldAnyoneOptions)
          toldAnyoneFirstNotificationBody(o.key),
      ];

  test('the scan actually reads the copy it claims to', () {
    // A guard on the guard: if the literal extractor ever silently stops
    // matching, every ban below would pass vacuously.
    final chipCopy = literalsIn('lib/features/onboarding/content/help_chips.dart');
    expect(chipCopy, contains("'Strength to keep going'"));
    final intakeCopy =
        literalsIn('lib/features/onboarding/content/intake_questions.dart');
    expect(intakeCopy, contains("'When is it heaviest?'"));
    expect(optionCopy().length, greaterThan(40));
  });

  test('the lapse ban matches what it claims to', () {
    // The exact phrases being retired, spelled the way a copy edit would
    // reintroduce them.
    for (final phrase in const [
      'To feel close to Allah again',
      'To keep turning back, even when I slip',
      'when you slip up',
    ]) {
      expect(
        phrase.toLowerCase().contains('again') ||
            phrase.toLowerCase().contains('slip'),
        isTrue,
        reason: phrase,
      );
    }
  });

  test('no lapse presupposition anywhere in the intake set', () {
    const reason = 'the corrected ICP is a Muslim at any level of practice in a '
        'period of real difficulty — a devout user having the worst month of '
        'their life must not be told they drifted';
    for (final copy in optionCopy()) {
      final lower = copy.toLowerCase();
      expect(lower.contains('again'), isFalse, reason: '$copy: $reason');
      expect(lower.contains('slip'), isFalse, reason: '$copy: $reason');
    }
    expectNoMatch(RegExp(r'\bagain\b|\bslip'), reason);
  });

  test('no prescriptive tone', () {
    expectNoMatch(
      RegExp(
        r'\b(you should|you must|you need to|make sure you|try to pray'
        r'|pray more|be better|do better)\b',
      ),
      'the top-ranked bounce trigger is being told to just pray more',
    );
  });

  test('nothing attributes a stance, intent or outcome to Allah', () {
    // Safe promises are about the USER's knowledge, words or practice — which
    // is why "Learning His Names" and the projection sentence are fine and
    // "what Allah is teaching you" is not.
    expectNoMatch(
      RegExp(
        r'\ballah (will|wants|is teaching|has chosen|sent|intends|means)\b'
        r'|\bhe (will lift|wants you|is teaching|has chosen|sent you)\b',
      ),
      'no stance, intent or outcome may be attributed to Allah',
    );
  });

  test('the system never calls anything a sign', () {
    expectNoMatch(
      RegExp(r'\bsigns?\b'),
      "the sign contract is the user's claim to make, not ours",
    );
  });

  test('no streak, habit or goal framing', () {
    expectNoMatch(
      RegExp(
        r'\b(streaks?|habits?|goals?|on track|keep it up|every day'
        r'|dont miss|keep the)\b',
      ),
      'the reel flow counts Names met, never days chained',
    );
  });

  test('no countdowns, deadlines or urgency', () {
    expectNoMatch(
      RegExp(
        r'\b(countdown|hurry|expires?|expiring|deadline|act now|limited time'
        r'|\d+\s*(seconds?|minutes?|hours?|days?)\s*(left|remaining)|ends in)\b',
      ),
      'a promise with a clock on it is a threat',
    );
  });

  test('no Arabic glyphs in copy literals', () {
    expectNoMatch(
      RegExp('[؀-ۿ]'),
      'Arabic comes from the catalog and renders in its own RTL widget',
    );
  });

  test('no option reads as a commitment device', () {
    // H6 is explicitly NOT one: the streak, lantern and widget own commitment,
    // and Duolingo's "I'M COMMITTED" CTA is not imported.
    expectNoMatch(
      RegExp(r'\b(commit|committed|commitment|promise me|i will show up)\b'),
      'the streak, lantern and widget stack owns commitment — this set does not',
    );
  });
}
