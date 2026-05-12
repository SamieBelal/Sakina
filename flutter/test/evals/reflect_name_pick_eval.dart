import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/core/env.dart';

/// Detect when reflectWithOpenAI fell back to the hardcoded demo response.
/// The demo is always Al-Lateef with a fixed reframe; if the API errors mid-run,
/// every row returns demo Al-Lateef, silently passing rows whose expected_names
/// include Al-Lateef and failing others. Treating demo as data poisons the baseline.
bool _isDemoFallback(ReflectResponse r) =>
    r.name == 'Al-Lateef' &&
    r.reframe.contains('Al-Lateef is The Subtle One');

void main() {
  // Hard-fail if eval is requested but the API key is missing — silent skips
  // led to empty baselines in past runs.
  if (Platform.environment['RUN_LIVE_EVALS'] == '1' && Env.openAiApiKey.isEmpty) {
    test('eval requested but OPENAI_API_KEY missing', () {
      fail('RUN_LIVE_EVALS=1 set but Env.openAiApiKey is empty. '
          'Run with: RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json test/evals/reflect_name_pick_eval.dart');
    });
    return;
  }

  // Default: skip cleanly when no live-eval flag set.
  if (Env.openAiApiKey.isEmpty ||
      Platform.environment['RUN_LIVE_EVALS'] != '1') {
    test('reflect eval (skipped, set RUN_LIVE_EVALS=1 + env.json)', () {});
    return;
  }

  group('reflect Name-pick eval', () {
    final fixture =
        jsonDecode(File('test/evals/reflect_name_pick_fixture.json').readAsStringSync())
            as List;
    final baselineFile = File('test/evals/reflect_name_pick_baseline.json');
    final baseline = baselineFile.existsSync()
        ? jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>
        : {'pass_rate': 0.0, 'per_row_status': []};

    test('pass rate >= baseline', () async {
      var passes = 0;
      final perRow = <Map<String, dynamic>>[];
      final demoRows = <String>[];
      for (final row in fixture.cast<Map<String, dynamic>>()) {
        final phrase = row['phrase'] as String;
        final expected = (row['expected_names'] as List).cast<String>().toSet();
        final response = await reflectWithOpenAI(phrase);

        // Hard fail if the live API fell back to demo — protects baseline integrity.
        if (_isDemoFallback(response)) {
          demoRows.add(phrase);
          continue;
        }

        final pass = expected.contains(response.name);
        if (pass) passes++;
        perRow.add({
          'phrase': phrase,
          'last_returned_name': response.name,
          'pass': pass,
        });
      }

      if (demoRows.isNotEmpty) {
        fail('reflectWithOpenAI fell back to demo response for ${demoRows.length} '
            'rows (e.g. "${demoRows.first}"). API likely errored mid-run. '
            'Baseline aborted to prevent corruption.');
      }

      final rate = passes / fixture.length;
      final baselineRate = (baseline['pass_rate'] as num).toDouble();

      // Write the updated row status for diffing — never auto-overwrite pass_rate.
      File('test/evals/reflect_name_pick_last_run.json').writeAsStringSync(
          jsonEncode({'pass_rate': rate, 'per_row_status': perRow}));

      expect(rate, greaterThanOrEqualTo(baselineRate),
          reason:
              'pass rate $rate < baseline $baselineRate. Inspect test/evals/reflect_name_pick_last_run.json.');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
