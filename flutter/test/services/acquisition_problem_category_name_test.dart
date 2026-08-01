// W6 Wave A / D4 — the acquisition category ships as
// `acquisition_problem_category`, NEVER `problem_category`.
//
// `problem_category` (`AnalyticsEvents.propProblemCategory`) is already a
// live EVENT property meaning "today's answer" (`check_in_completed`,
// `daily_question_answered`). A super property of the same name meaning "what
// they arrived with" would put two meanings behind one key — event-level
// properties win where both exist, so some events would report today's
// answer and others the acquisition one, under the same name, with nothing to
// signal the switch. See plan §3 D4.
//
// This is a SOURCE-LEVEL grep, not a behavioural test, because the defect it
// guards against is a naming choice at a call site, not a runtime path.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// True if [callBody] (the text between `setSuperProperties(`'s opening paren
/// and its matching close) registers a key literally named `problem_category`
/// — either the raw string or the `propProblemCategory` identifier, which
/// resolves to the same string. Deliberately does NOT flag
/// `propAcquisitionProblemCategory` / `'acquisition_problem_category'`: a
/// naive substring check on `problem_category` alone would, since that text
/// is a substring of the longer name.
bool _registersProblemCategory(String callBody) {
  if (RegExp(r"""['"]problem_category['"]""").hasMatch(callBody)) return true;
  if (RegExp(r'\bpropProblemCategory\b').hasMatch(callBody)) return true;
  return false;
}

/// Every `setSuperProperties(...)` call body in [source], paren-balanced so a
/// nested map literal doesn't truncate early.
List<String> _superPropertyCallBodies(String source) {
  final bodies = <String>[];
  final calls = RegExp(r'setSuperProperties\(').allMatches(source);
  for (final match in calls) {
    var depth = 1;
    var i = match.end;
    final start = i;
    while (i < source.length && depth > 0) {
      if (source[i] == '(') depth++;
      if (source[i] == ')') depth--;
      i++;
    }
    bodies.add(source.substring(start, i));
  }
  return bodies;
}

void main() {
  test(
      'no setSuperProperties call anywhere in lib/ registers the literal '
      "'problem_category'", () {
    // MUTATION THAT MUST FAIL THIS TEST: rename
    // AnalyticsEvents.propAcquisitionProblemCategory back to
    // 'problem_category' (D4's collision) — or use
    // AnalyticsEvents.propProblemCategory as a setSuperProperties key
    // anywhere. Verified by hand: temporarily renaming the constant's value
    // in analytics_event_names.dart to 'problem_category' and re-running made
    // this test fail on onboarding_screen.dart's hook-selection call site.
    final violations = <String>[];
    final libDir = Directory('lib');
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final body in _superPropertyCallBodies(source)) {
        if (_registersProblemCategory(body)) {
          violations.add(entity.path);
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'these setSuperProperties calls register a key literally '
            "named 'problem_category', colliding with the live EVENT "
            'property of the same name (D4): ${violations.join(', ')}');
  });

  test('the helper itself does not false-positive on the acquisition name',
      () {
    // Pins the regex against the exact collision it must NOT flag — a naive
    // `.contains('problem_category')` substring check would also match
    // `acquisition_problem_category` and make the test above unpassable by
    // the correct implementation.
    expect(
      _registersProblemCategory(
        "{AnalyticsEvents.propAcquisitionProblemCategory: selection.problemCategory}",
      ),
      isFalse,
    );
    expect(
      _registersProblemCategory("{'acquisition_problem_category': 'x'}"),
      isFalse,
    );
    expect(
      _registersProblemCategory("{'problem_category': 'x'}"),
      isTrue,
    );
    expect(
      _registersProblemCategory('{AnalyticsEvents.propProblemCategory: x}'),
      isTrue,
    );
  });
}
