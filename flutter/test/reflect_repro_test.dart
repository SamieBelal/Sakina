// Reproduction harness (NOT a real unit test) for the "reflect first call is
// disjointed / parenthetical" report. Makes DIRECT calls to OpenAI using the
// exact production system prompt under first-call conditions (empty context),
// then inspects the parsed beat fields for template-echo / parenthetical text.
//
// Run:
//   OPENAI_API_KEY=$(python3 -c "import json;print(json.load(open('env.json'))['OPENAI_API_KEY'])") \
//     flutter test test/reflect_repro_test.dart --reporter expanded
//
// Set REPRO_TEMP to override sampling temperature (unset => OpenAI default 1.0,
// which is what production currently does).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sakina/services/ai_service.dart';

const _endpoint = 'https://api.openai.com/v1/chat/completions';
const _model = 'gpt-4o-mini';

// First-call feelings a real user might type. First call => no history/context.
const _feelings = <String>[
  'I feel anxious and overwhelmed about the future',
  'I feel so alone right now',
  'I keep messing up and I feel like a failure',
  'I am grieving and everything feels heavy',
];

// Signals that a narrative beat field is disjointed / parenthetical or is
// echoing the format template rather than content. Intentionally narrow to
// avoid false positives (e.g. the word "words" appearing in real prose).
final _templateTells = <RegExp>[
  RegExp(r'\([A-Za-z]'), // parenthetical gloss: "(Job)", "(peace be upon him)"
  RegExp(r'\bMAX \d'),
  RegExp(r'\be\.g\.,', caseSensitive: false),
  RegExp(r'resonant line', caseSensitive: false),
  RegExp(r'the single thought', caseSensitive: false),
  RegExp(r'citation only', caseSensitive: false),
  RegExp(r'one sentence of the story', caseSensitive: false),
];

// Only the NARRATIVE beat fields the user reads as flowing prose. Citation
// fields (storySource, verse refs, dua source) legitimately contain parens and
// are intentionally excluded.
List<String> _fieldsOf(ReflectResponse r) => <String>[
      'name: ${r.name}',
      'reframeKey: ${r.reframeKey}',
      'reframeBody: ${r.reframeBody}',
      'reframe(legacy): ${r.reframe}',
      'storyTitle: ${r.storyTitle}',
      for (var i = 0; i < r.storyBeats.length; i++)
        'storyBeat[$i]: ${r.storyBeats[i]}',
      'story(legacy): ${r.story}',
      'takeaway: ${r.takeaway}',
    ];

// Returns the list of offending field strings (empty => clean).
List<String> _detect(ReflectResponse r) {
  final offenders = <String>[];
  for (final f in _fieldsOf(r)) {
    final value = f.substring(f.indexOf(':') + 1);
    if (_templateTells.any((re) => re.hasMatch(value))) offenders.add(f);
  }
  return offenders;
}

// Which rung of the parser ladder did this response land on?
String _rung(String raw) {
  final structured = raw.contains('##STORY_BEAT_1##') ||
      raw.contains('##REFRAME_KEY##') ||
      raw.contains('##TAKEAWAY##');
  final legacy = raw.contains('##REFRAME##') || raw.contains('##STORY##');
  if (structured) return 'structured';
  if (legacy) return 'legacy-fallback(splitIntoBeats)';
  return 'no-markers(parse-fail-likely)';
}

Future<String?> _rawReflect(String apiKey, String feeling, {double? temperature}) async {
  final systemPrompt = buildSystemPrompt(); // no context => first-call prompt
  final payload = <String, dynamic>{
    'model': _model,
    'max_completion_tokens': 1500,
    if (temperature != null) 'temperature': temperature,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': feeling},
    ],
  };
  final resp = await http.post(
    Uri.parse(_endpoint),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(payload),
  );
  if (resp.statusCode != 200) {
    // ignore: avoid_print
    print('  !! HTTP ${resp.statusCode}: ${resp.body}');
    return null;
  }
  final json = jsonDecode(resp.body) as Map<String, dynamic>;
  final choices = json['choices'] as List<dynamic>;
  final msg = choices.first['message'] as Map<String, dynamic>;
  return msg['content'] as String?;
}

void main() {
  // Read ONLY from the runtime environment — deliberately NOT from
  // String.fromEnvironment, so that running the suite with
  // `--dart-define-from-file=env.json` can never trigger live/billable calls.
  // This harness runs only when OPENAI_API_KEY is explicitly exported.
  final apiKey = Platform.environment['OPENAI_API_KEY'] ?? '';
  final tempEnv = Platform.environment['REPRO_TEMP'];
  final temperature = tempEnv == null ? null : double.tryParse(tempEnv);

  test('reproduce: direct OpenAI first-call reflect, scan for parenthetical/disjointed beats', () async {
    final passes = int.tryParse(Platform.environment['REPRO_PASSES'] ?? '5') ?? 5;
    final outDir = Directory('test/.repro_out')..createSync(recursive: true);

    // ignore: avoid_print
    print('\n=== REFLECT REPRO — temperature=${temperature ?? "default(1.0)"}, passes=$passes ===');
    var totalRuns = 0;
    var badRuns = 0;
    var rawGlossRuns = 0;
    final rungCounts = <String, int>{};

    for (var pass = 0; pass < passes; pass++) {
      for (final feeling in _feelings) {
        totalRuns++;
        final raw = await _rawReflect(apiKey, feeling, temperature: temperature);
        // ignore: avoid_print
        print('\n--- run $totalRuns  feeling="$feeling" ---');
        if (raw == null) {
          // ignore: avoid_print
          print('  (no response)');
          continue;
        }
        File('${outDir.path}/run_$totalRuns.txt').writeAsStringSync(
            'FEELING: $feeling\nTEMP: ${temperature ?? "default"}\n\n$raw');
        final rung = _rung(raw);
        rungCounts[rung] = (rungCounts[rung] ?? 0) + 1;
        // Model-emitted parenthetical glosses in RAW narrative text:
        // "(Job)", "(peace...)". Strip citation lines first (they legitimately
        // use parens) and Arabic-in-parens won't match [A-Za-z]. This isolates
        // narrative glosses and measures the prompt+temperature effect.
        final rawNarrative = raw
            .replaceAll(RegExp(r'##STORY_SOURCE##[^\n]*'), '')
            .replaceAll(RegExp(r'##DUA_SOURCE##[^\n]*'), '')
            .replaceAll(RegExp(r'##VERSE_\d+_REF##[^\n]*'), '');
        final rawGlosses = RegExp(r'\([A-Za-z]').allMatches(rawNarrative).length;
        if (rawGlosses > 0) rawGlossRuns++;
        final parsed = parseReflectResponse(raw);
        if (parsed == null) {
          badRuns++;
          // ignore: avoid_print
          print('  rung=$rung  PARSE FAILED (would fall back to demo). Raw:\n$raw');
          continue;
        }
        // _detect runs on the PARSED response the UI receives (post gloss-strip).
        final offenders = _detect(parsed);
        if (offenders.isEmpty) {
          // ignore: avoid_print
          print('  clean(parsed). rung=$rung rawModelGlosses=$rawGlosses key="${parsed.reframeKey}"');
        } else {
          badRuns++;
          // ignore: avoid_print
          print('  >>> DISJOINTED/PARENTHETICAL DETECTED  rung=$rung  (${offenders.length} field(s)):');
          for (final o in offenders) {
            // ignore: avoid_print
            print('      $o');
          }
        }
      }
    }

    // ignore: avoid_print
    print('\n=== SUMMARY ===');
    // ignore: avoid_print
    print('  parsed (what UI renders) flagged: $badRuns/$totalRuns runs');
    // ignore: avoid_print
    print('  raw model still emitted glosses:  $rawGlossRuns/$totalRuns runs');
    // ignore: avoid_print
    print('  rungs=$rungCounts');
    // ignore: avoid_print
    print('  Raw responses saved under ${outDir.path}/\n');
  },
      timeout: const Timeout(Duration(minutes: 12)),
      // Live-network repro harness — skipped in the normal suite / CI. To run:
      //   OPENAI_API_KEY=$(python3 -c "import json;print(json.load(open('env.json'))['OPENAI_API_KEY'])") \
      //     flutter test test/reflect_repro_test.dart --reporter expanded
      skip: apiKey.isEmpty ? 'set OPENAI_API_KEY to run the live repro' : false);
}
