// W4 Wave 7 — `entry_source` is only trustworthy if nothing forgets to tag.
//
// `daily_question_shown{entry_source}` has to keep three paths apart, and the
// widget path in particular must stay separable from day-open (plan §9). The
// scheme is: every in-app navigation to `/muhasabah` tags itself with
// `?entry=`, and an UNTAGGED navigation means the app brought the user here on
// open, so it reads as `day_open`.
//
// That default is what makes the day-open path free of ceremony — it routes
// with a bare `go('/muhasabah')` and is correct by construction. It is also the
// scheme's one weakness: a new in-app push added later would silently inflate
// day-open instead of showing up as an obviously wrong value. Since a
// misattributed entry source is invisible in a dashboard and permanent in the
// data, the guard belongs here rather than in a review checklist.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files allowed to name `/muhasabah` without an `?entry=` tag, and why.
const Map<String, String> _untaggedByDesign = {
  // The route definition itself, which is what READS the tag.
  'lib/core/router.dart': 'the GoRoute path + the query-param reader',
  // The day-open path (Wave 4). Untagged on purpose: absence IS `day_open`.
  'lib/features/daily/screens/daily_launch_overlay.dart':
      'the day-open route, whose untagged navigation is the day_open default',
};

void main() {
  test('every in-app navigation to /muhasabah declares its entry_source', () {
    final offenders = <String>[];

    for (final entity
        in Directory('lib').listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = entity.path;
      if (_untaggedByDesign.containsKey(relative)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains("'/muhasabah")) continue;
        // The tag may sit on this line or, when the string is split to fit the
        // line length, on the next one.
        final window =
            (i + 1 < lines.length ? '$line${lines[i + 1]}' : line).toLowerCase();
        // Case-insensitively, because the tag is normally written through the
        // `questionEntryQueryParam` / `questionEntryHomeCta` constants rather
        // than as the literal `entry=`.
        if (window.contains('entry')) continue;
        offenders.add('$relative:${i + 1}  ${line.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These navigate to /muhasabah without `?entry=`, so every user '
          'who arrives through them is counted as `day_open` — which is the '
          'one entry source the app is supposed to initiate on its own, and '
          'the denominator of the same-day-return metric the whole defer '
          'design is judged on.\n'
          'Fix: append '
          "'?\$questionEntryQueryParam=\$questionEntryHomeCta' (or "
          '`\$questionEntryWidget`), or add the file to `_untaggedByDesign` '
          'with a reason.\n'
          'Offenders:\n  ${offenders.join('\n  ')}',
    );
  });

  test('the untagged-by-design list stays honest', () {
    // A stale allowlist is worse than no allowlist: it silently exempts a file
    // that may have moved on.
    for (final path in _untaggedByDesign.keys) {
      expect(File(path).existsSync(), isTrue,
          reason: '$path is exempted from the entry_source guard but no '
              'longer exists — re-check where /muhasabah is navigated to now.');
    }
  });
}
