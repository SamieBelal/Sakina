import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/env.dart';
import 'package:sakina/services/ai_service.dart';

/// Mechanical beat-shape eval for the bite-sized reflection prompt (decision 7A).
///
/// Runs the live reflect prompt over a set of canned feelings and asserts the
/// STRUCTURE of the response — not its Name-pick (that's reflect_name_pick_eval).
/// Guards the mechanical failure modes of the new beat contract: markers must
/// parse, word caps must roughly hold, and the story citation must look like a
/// real reference. Content FIDELITY (does the story match its source?) is NOT
/// checked here — that is the pre-ship human source review (decision 16A).
///
/// Run pre-ship, and baseline-first (record the run BEFORE the prompt change so
/// the known-flaky find_duas failure isn't blamed on this):
///   RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json \
///     test/evals/reflect_beat_shape_eval.dart
///
/// Word caps WARN (print) between the target and +20%, and FAIL only past +20%,
/// so honest slightly-long output doesn't break the gate.

const _feelings = <String>[
  'I feel completely overwhelmed and I can\'t catch my breath',
  'I am so grateful today, everything feels like a gift',
  'I feel abandoned, like no one sees how hard I am trying',
  'I am terrified about my future and what comes next',
  'I keep failing and I feel worthless',
  'I am grieving someone I love and the ache won\'t stop',
  'I feel anxious about money and providing for my family',
  'I am angry at someone who wronged me and can\'t let go',
  'I feel lonely even when I am surrounded by people',
  'I am ashamed of a sin I keep returning to',
];

int _words(String s) =>
    s.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

/// A story source should read like a citation: "Qur'an 20:25", "Quran 2:255",
/// or a named hadith collection (Bukhari / Muslim / Tirmidhi / …) with a number.
final _citation = RegExp(
  r"(qur'?an|quran)\s*\d+\s*[:.]\s*\d+"
  r'|(bukhari|muslim|tirmidhi|abu dawud|nasa|ibn majah|ahmad|malik)',
  caseSensitive: false,
);

void main() {
  if (Platform.environment['RUN_LIVE_EVALS'] == '1' && Env.openAiApiKey.isEmpty) {
    test('eval requested but OPENAI_API_KEY missing', () {
      fail('RUN_LIVE_EVALS=1 set but Env.openAiApiKey is empty. Run with '
          '--dart-define-from-file=env.json');
    });
    return;
  }
  if (Env.openAiApiKey.isEmpty ||
      Platform.environment['RUN_LIVE_EVALS'] != '1') {
    test('reflect beat-shape eval (skipped; set RUN_LIVE_EVALS=1 + env.json)',
        () {});
    return;
  }

  group('reflect beat-shape eval', () {
    test('every response parses into structured beats with valid shape',
        () async {
      final failures = <String>[];
      final warnings = <String>[];

      for (final feeling in _feelings) {
        final r = await reflectWithOpenAI(feeling);

        // (a) beat markers parsed.
        if (!r.hasBeats) {
          failures.add('"$feeling": no structured beats parsed');
          continue;
        }
        // Name canonical (findCanonicalName-backed; parser already maps it).
        if (r.name.trim().isEmpty) {
          failures.add('"$feeling": empty Name');
        }

        // (b) word caps: warn past target, fail past +20%.
        void cap(String label, String text, int target) {
          if (text.isEmpty) return;
          final n = _words(text);
          final hardMax = (target * 1.2).ceil();
          if (n > hardMax) {
            failures.add('"$feeling": $label $n words > hard max $hardMax');
          } else if (n > target) {
            warnings.add('"$feeling": $label $n words > target $target');
          }
        }

        cap('reframeKey', r.reframeKey, 12);
        for (final b in r.storyBeats) {
          cap('storyBeat', b, 20);
        }
        cap('takeaway', r.takeaway, 14);

        // (c) citation pattern — only when a story (hence a source) is present.
        if (r.storyBeats.isNotEmpty && r.storySource.trim().isNotEmpty) {
          if (!_citation.hasMatch(r.storySource)) {
            failures.add(
                '"$feeling": storySource "${r.storySource}" is not a citation');
          }
        }
      }

      // ignore: avoid_print
      if (warnings.isNotEmpty) print('BEAT EVAL WARNINGS:\n${warnings.join('\n')}');
      expect(failures, isEmpty,
          reason: 'beat-shape failures:\n${failures.join('\n')}');
    });
  });
}
