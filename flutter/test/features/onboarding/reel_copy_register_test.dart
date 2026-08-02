import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The reverence firewall as a test (One Ship W2-D, binding rules).
///
/// Wave D's screens are the ones that talk to the user between the reveal and
/// signup, which is exactly where a growth-product register would creep in.
/// This walks the user-facing string literals in those files and fails on the
/// registers the plan bans:
///
///   * **streak / habit / goal** — the reel flow's promise is a Name a day, not
///     a chain the user can break. Streak framing turns a missed day into a
///     punishment, which is the opposite of what these Names are for.
///   * **"sign"** — the app never tells anyone their arrival was a sign. The
///     user may claim that (the sign chip is their tap); system copy may not
///     claim it for them.
///   * **countdowns and deadlines** — "sealed until tomorrow" is a promise; a
///     clock on it is a threat. No timers, no dates, no "X left".
///   * **Arabic inside a copy literal** — every Arabic glyph on these screens
///     comes from the catalog and renders in its own RTL widget (CLAUDE.md).
///
/// Comment lines are stripped before scanning, so this file's own vocabulary
/// and the source's explanatory prose are not the thing under test — the
/// strings the user actually reads are.
void main() {
  const files = [
    'lib/features/onboarding/content/aspirations.dart',
    'lib/features/onboarding/content/carrying_durations.dart',
    'lib/features/onboarding/screens/aspiration_screen_reel.dart',
    'lib/features/onboarding/screens/carrying_duration_screen.dart',
    'lib/features/onboarding/screens/queue_plan_screen.dart',
    'lib/features/onboarding/screens/source_question_screen.dart',
    'lib/features/onboarding/widgets/journey_stamp_track.dart',
    'lib/features/onboarding/widgets/queue_name_row.dart',
    'lib/features/onboarding/widgets/queue_plan_header.dart',
    'lib/features/onboarding/widgets/reel_option_card.dart',
    'lib/features/onboarding/widgets/reel_question_header.dart',
    'lib/features/onboarding/widgets/reel_single_tap_question.dart',
    'lib/features/onboarding/widgets/reel_skip_link.dart',
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

  /// The habit-nag register, kept in one place so the ban and the self-check
  /// below can never drift apart.
  // `\x27` is the apostrophe in "don't" — a regex-level escape, so the pattern
  // stays a single-quoted raw string like every other ban here.
  final habitFraming = RegExp(
    r'\b(streaks?|habits?|goals?|on track|keep it up|every day'
    r'|don\x27t miss|keep the)\b',
  );

  test('the bans match what they claim to', () {
    // A ban with a typo in it passes vacuously forever. These are the phrases
    // the plan names, spelled the way a copy edit would reintroduce them.
    for (final phrase in const [
      'a 5-day streak',
      'build the habit',
      "don't miss a day",
      'come back every day',
      'keep the chain going',
    ]) {
      expect(habitFraming.hasMatch(phrase), isTrue, reason: phrase);
    }
    expect(habitFraming.hasMatch('to keep turning back'), isFalse,
        reason: 'the aspiration copy is not habit framing');
  });

  test('no streak, habit or goal framing', () {
    expectNoMatch(
      habitFraming,
      'the reel flow counts Names met, never days chained',
    );
  });

  test('the system never calls anything a sign', () {
    expectNoMatch(
      RegExp(r'\bsigns?\b'),
      'the sign contract is the user\'s claim to make, not ours',
    );
  });

  test('no countdowns, deadlines or urgency', () {
    expectNoMatch(
      RegExp(
        r'\b(countdown|hurry|expires?|expiring|deadline|act now|limited time'
        r'|\d+\s*(seconds?|minutes?|hours?|days?)\s*(left|remaining)|ends in)\b',
      ),
      'sealed until tomorrow is a promise; a clock on it is a threat',
    );
  });

  test('no Arabic glyphs in copy literals', () {
    expectNoMatch(
      RegExp('[؀-ۿ]'),
      'Arabic comes from the catalog and renders in its own RTL widget',
    );
  });

  test('the scan actually reads the copy it claims to', () {
    // A guard on the guard: if the literal extractor ever silently stops
    // matching, every ban above would pass vacuously.
    final planCopy =
        literalsIn('lib/features/onboarding/screens/queue_plan_screen.dart');
    expect(planCopy, contains("'The Names ahead of you'"));
    final sourceCopy = literalsIn(
        'lib/features/onboarding/screens/source_question_screen.dart');
    expect(sourceCopy, contains("'Rather not say'"));
    final aspirationCopy =
        literalsIn('lib/features/onboarding/content/aspirations.dart');
    expect(aspirationCopy, contains("'To feel close to Allah again'"));
  });
}
