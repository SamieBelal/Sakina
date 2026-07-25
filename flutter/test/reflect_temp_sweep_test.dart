// Temperature sweep for the reflect call. For each candidate temperature it
// fires the production first-call system prompt (empty context) directly at
// OpenAI several times and measures the tradeoff:
//   * gloss rate  — how often the MODEL emits parenthetical glosses in a
//                   narrative field ("Ayoub (Job)…"). Lower is better. Measured
//                   on RAW output, BEFORE the parser strip, so it reflects the
//                   prompt+temperature effect at the source.
//   * variety     — distinct Names returned per feeling across passes. Higher
//                   means less repetitive first-call output.
//   * parse fails — responses the parser would reject (=> demo fallback).
//
// Run:
//   OPENAI_API_KEY=$(python3 -c "import json;print(json.load(open('env.json'))['OPENAI_API_KEY'])") \
//     flutter test test/reflect_temp_sweep_test.dart --reporter expanded
//
// Tunables: REPRO_PASSES (passes per feeling per temp, default 4),
//           REPRO_TEMPS  (comma list, default "0.2,0.4,0.6,0.8,1.0").
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sakina/services/ai_service.dart';

const _endpoint = 'https://api.openai.com/v1/chat/completions';
const _model = 'gpt-4o-mini';

const _feelings = <String>[
  'I feel anxious and overwhelmed about the future',
  'I feel so alone right now',
  'I keep messing up and I feel like a failure',
  'I am grieving and everything feels heavy',
];

// Narrative markers a user reads as flowing prose. Citation markers
// (STORY_SOURCE, DUA_SOURCE, VERSE_*_REF) are excluded — they use parens
// legitimately.
const _narrativeMarkers = <String>[
  '##REFRAME_KEY##',
  '##REFRAME_BODY##',
  '##STORY_TITLE##',
  '##STORY_BEAT_1##',
  '##STORY_BEAT_2##',
  '##STORY_BEAT_3##',
  '##TAKEAWAY##',
  '##REFRAME##',
  '##STORY##',
];

// Local copy of the parser's section extractor (the lib's is private).
String? _section(String text, String marker) {
  final idx = text.indexOf(marker);
  if (idx == -1) return null;
  final rest = text.substring(idx + marker.length);
  final next = RegExp(r'##[A-Z0-9_]+##').firstMatch(rest);
  final end = next?.start ?? rest.length;
  return rest.substring(0, end).trim();
}

final _gloss = RegExp(r'\(\s*[A-Za-z]'); // "(Job", "(peace…" — letter-led paren

// Returns the narrative fields (marker + content) that contain a gloss.
List<String> _rawGlossFields(String raw) {
  final hits = <String>[];
  for (final m in _narrativeMarkers) {
    final content = _section(raw, m);
    if (content != null && _gloss.hasMatch(content)) hits.add('$m $content');
  }
  return hits;
}

Future<String?> _rawReflect(String apiKey, String feeling, double temperature) async {
  final resp = await http.post(
    Uri.parse(_endpoint),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': _model,
      'max_completion_tokens': 1500,
      'temperature': temperature,
      'messages': [
        {'role': 'system', 'content': buildSystemPrompt()},
        {'role': 'user', 'content': feeling},
      ],
    }),
  );
  if (resp.statusCode != 200) {
    // ignore: avoid_print
    print('  !! HTTP ${resp.statusCode}: ${resp.body}');
    return null;
  }
  final json = jsonDecode(resp.body) as Map<String, dynamic>;
  return (json['choices'] as List).first['message']['content'] as String?;
}

int _words(String s) => s.trim().isEmpty
    ? 0
    : s.trim().split(RegExp(r'\s+')).length;

// Count fields that exceed the prompt's hard word caps — a proxy for run-on /
// "disjointed" lines that grow with temperature.
int _capViolations(ReflectResponse r) {
  var n = 0;
  if (_words(r.reframeKey) > 12) n++;
  if (_words(r.reframeBody) > 30) n++;
  if (_words(r.storyTitle) > 6) n++;
  for (final b in r.storyBeats) {
    if (_words(b) > 20) n++;
  }
  if (_words(r.takeaway) > 14) n++;
  return n;
}

class _TempResult {
  final double temp;
  int runs = 0;
  int glossRuns = 0; // runs with >=1 narrative gloss
  int glossFields = 0; // total glossy fields
  int parseFails = 0;
  int capViolationRuns = 0; // runs with >=1 over-cap field
  int capViolationFields = 0; // total over-cap fields
  final Map<String, Set<String>> namesByFeeling = {};
  _TempResult(this.temp);

  double get glossRate => runs == 0 ? 0 : glossRuns / runs;
  double get capRate => runs == 0 ? 0 : capViolationRuns / runs;
  // Avg distinct names per feeling across its passes (variety proxy).
  double get variety {
    if (namesByFeeling.isEmpty) return 0;
    final total = namesByFeeling.values.map((s) => s.length).reduce((a, b) => a + b);
    return total / namesByFeeling.length;
  }
}

void main() {
  // Read ONLY from the runtime environment (see reflect_repro_test.dart) so a
  // `--dart-define-from-file=env.json` suite run can never fire live calls.
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? '';
  final passes = int.tryParse(Platform.environment['REPRO_PASSES'] ?? '4') ?? 4;
  final temps = (Platform.environment['REPRO_TEMPS'] ?? '0.2,0.4,0.6,0.8,1.0')
      .split(',')
      .map((s) => double.parse(s.trim()))
      .toList();

  test('reflect temperature sweep: gloss rate vs variety', () async {
    final results = <_TempResult>[];
    for (final temp in temps) {
      final r = _TempResult(temp);
      // ignore: avoid_print
      print('\n=== temp=$temp ===');
      for (var pass = 0; pass < passes; pass++) {
        for (final feeling in _feelings) {
          r.runs++;
          final raw = await _rawReflect(apiKey, feeling, temp);
          if (raw == null) {
            r.parseFails++;
            continue;
          }
          final glossFields = _rawGlossFields(raw);
          if (glossFields.isNotEmpty) {
            r.glossRuns++;
            r.glossFields += glossFields.length;
            // ignore: avoid_print
            print('  gloss @ "$feeling": ${glossFields.first}');
          }
          final parsed = parseReflectResponse(raw);
          if (parsed == null) {
            r.parseFails++;
          } else {
            (r.namesByFeeling[feeling] ??= <String>{}).add(parsed.name);
            final caps = _capViolations(parsed);
            if (caps > 0) {
              r.capViolationRuns++;
              r.capViolationFields += caps;
            }
          }
        }
      }
      results.add(r);
    }

    // ignore: avoid_print
    print('\n==================== SWEEP SUMMARY ====================');
    // ignore: avoid_print
    print('temp | runs | glossRate | variety | capViolRate | capFields | parseFails');
    for (final r in results) {
      // ignore: avoid_print
      print('${r.temp.toStringAsFixed(1)}  |  ${r.runs}  |   '
          '${(r.glossRate * 100).toStringAsFixed(0).padLeft(3)}%    |  '
          '${r.variety.toStringAsFixed(2)}   |   '
          '${(r.capRate * 100).toStringAsFixed(0).padLeft(3)}%     |    '
          '${r.capViolationFields}      |    ${r.parseFails}');
    }
    // ignore: avoid_print
    print('======================================================');
    // ignore: avoid_print
    print('BEST = highest temp whose glossRate stays ~0 (max variety w/o disjointedness).\n');
  },
      timeout: const Timeout(Duration(minutes: 20)),
      skip: apiKey.isEmpty ? 'set OPENAI_API_KEY to run the sweep' : false);
}
