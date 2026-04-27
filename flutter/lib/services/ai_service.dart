/// OpenAI Chat Completions integration for the Sakina app.
///
/// Maps user emotions to Names of Allah via the configured chat model,
/// parses structured responses, and provides follow-up question generation.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/core/constants/dua_knowledge.dart';
import 'package:sakina/core/constants/duas.dart';
import 'package:sakina/core/constants/knowledge_base.dart';
import 'package:sakina/core/env.dart';
import 'package:sakina/features/reflect/data/reflection_verse_catalog.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/validate_names.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class RelatedName {
  final String name;
  final String nameArabic;

  const RelatedName({required this.name, required this.nameArabic});
}

class ReflectResponse {
  final String name;
  final String nameArabic;
  final String reframe;
  final String story;
  final List<ReflectVerse> verses;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;
  final String duaSource;
  final List<RelatedName> relatedNames;
  final bool offTopic;

  const ReflectResponse({
    required this.name,
    required this.nameArabic,
    required this.reframe,
    required this.story,
    this.verses = const [],
    required this.duaArabic,
    required this.duaTransliteration,
    required this.duaTranslation,
    required this.duaSource,
    required this.relatedNames,
    required this.offTopic,
  });
}

class ReflectContextEntry {
  final String userText;
  final String name;

  const ReflectContextEntry({required this.userText, required this.name});
}

class ReflectContext {
  final List<String> recentNames;
  final List<ReflectContextEntry> recentEntries;
  final List<String>? anchorNames;

  const ReflectContext({
    required this.recentNames,
    required this.recentEntries,
    this.anchorNames,
  });
}

enum FollowUpQuestionType { scale, choice }

class FollowUpQuestion {
  final FollowUpQuestionType type;
  final String question;
  final List<String>? options;

  const FollowUpQuestion({
    required this.type,
    required this.question,
    this.options,
  });
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Web builds use `proxy.js` (localhost:8787) to avoid browser CORS to the API.
const String _openAiChatUrl = kIsWeb
    ? 'http://localhost:8787/v1/chat/completions'
    : 'https://api.openai.com/v1/chat/completions';

/// Single model for all AI calls (follow-ups, reflect, find names, build dua, daily).
const _chatModel = 'gpt-4o-mini';

// ---------------------------------------------------------------------------
// System prompt
// ---------------------------------------------------------------------------

String buildSystemPrompt({
  List<String>? avoidNames,
  List<String>? anchorNames,
  List<ReflectContextEntry>? recentEntries,
  String? teachingContext,
  String? forceName,
}) {
  final avoidClause = (avoidNames != null && avoidNames.isNotEmpty)
      ? '\n\nIMPORTANT: The user has recently been shown these Names: ${avoidNames.join(", ")}. '
          'Do NOT repeat any of them. Pick a DIFFERENT Name that still fits their feeling.'
      : '';

  final forceClause = forceName != null
      ? '\n\nCRITICAL: You MUST use "$forceName" as the Name of Allah in your response. '
          'Do not pick a different Name. The user was already shown this Name — now write the '
          'reframe, story, and dua specifically for "$forceName".'
      : '';

  final anchorClause = (anchorNames != null &&
          anchorNames.isNotEmpty &&
          forceName == null)
      ? '\n\nThe user has marked these Names as personal anchors: ${anchorNames.join(", ")}. '
          'When relevant, prefer returning one of these anchor Names — but only if it genuinely '
          'fits the feeling. Do not force an anchor Name when a different Name is clearly more appropriate.'
      : '';

  final historyClause = (recentEntries != null && recentEntries.isNotEmpty)
      ? '\n\nRecent conversation history (for continuity):\n'
          '${recentEntries.map((e) => '- User said: "${e.userText}" → You responded with: ${e.name}').join('\n')}'
      : '';

  final teachingClause = (teachingContext != null && teachingContext.isNotEmpty)
      ? '\n\n## Teaching Reference\n'
          'Use the following teachings from Sheikh Omar Suleiman\'s series as your PRIMARY source. '
          'When a teaching below matches the user\'s feeling, use its story, dua, and framing:\n\n'
          '$teachingContext'
      : '';

  final canonicalList = buildCanonicalNamesPromptList();
  final approvedVerseClause = buildApprovedVersePrompt();

  return '''You are an Islamic learning tool drawing on Sheikh Omar Suleiman's "The Dua I Need" series and "The Name I Need" series by Sheikh Mikaeel Smith. A user will share how they feel, and you will respond with ONE Name of Allah that speaks to that emotion.

## Canonical Names of Allah
You MUST pick from this exact list. Do NOT invent or modify Names.
$canonicalList
$approvedVerseClause
$avoidClause$forceClause$anchorClause$historyClause$teachingClause

## Response Format
Respond with EXACTLY these markers, each on its own line, followed by the content:

##NAME## (the transliterated Name, e.g. Al-Lateef)
##NAME_AR## (the Arabic Name, e.g. اللطيف)
##REFRAME## (2-3 sentences reframing the user's feeling through the lens of this Name)
##STORY## (a prophetic story or Quranic narrative illustrating this Name — 3-5 sentences)
##VERSE_1_AR## (Arabic text for the first approved verse)
##VERSE_1_EN## (English translation for the first approved verse)
##VERSE_1_REF## (reference for the first approved verse)
##VERSE_2_AR## (Arabic text for the optional second approved verse)
##VERSE_2_EN## (English translation for the optional second approved verse)
##VERSE_2_REF## (reference for the optional second approved verse)
##DUA_AR## (the Arabic dua text)
##DUA_TR## (transliteration of the dua)
##DUA_EN## (English translation of the dua)
##DUA_SOURCE## (hadith/Quran source reference)
##RELATED## (2-3 other Names that also relate, format: Name (Arabic) | Name (Arabic) | ...)

Rules:
- Keep the reframe warm, empathetic, and grounded in Islamic theology. No fluff.
- The story must be authentic — from Quran or sahih hadith. NEVER fabricate.
- The verses must come ONLY from the approved list for the chosen Name. Do not quote any verse outside that list.
- The dua must be real — from Quran or authenticated hadith collections. NEVER fabricate.
- Related names must come from the canonical list above.
- If the user's input is clearly off-topic (not about feelings, emotions, or spiritual state), still respond with your best match but keep the reframe brief.''';
}

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

String? _parseSection(String text, String marker) {
  final idx = text.indexOf(marker);
  if (idx == -1) return null;

  final start = idx + marker.length;
  // Find next marker or end of string
  final nextMarker = RegExp(r'##[A-Z0-9_]+##');
  final remaining = text.substring(start);
  final match = nextMarker.firstMatch(remaining);
  final end = match?.start ?? remaining.length;

  return remaining.substring(0, end).trim();
}

List<RelatedName> _parseRelatedNames(String? raw) {
  if (raw == null || raw.isEmpty) return [];

  final parts = raw.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);
  final parsed = <Map<String, dynamic>>[];

  for (final part in parts) {
    // Expected format: "Name (Arabic)" or just "Name"
    final parenMatch = RegExp(r'^(.+?)\s*\((.+?)\)\s*$').firstMatch(part);
    if (parenMatch != null) {
      parsed.add({
        'name': parenMatch.group(1)!.trim(),
        'nameArabic': parenMatch.group(2)!.trim(),
      });
    } else {
      parsed.add({
        'name': part.trim(),
        'nameArabic': '',
      });
    }
  }

  // Validate against canonical names
  final validated = filterValidNames(parsed);

  return validated
      .map((m) => RelatedName(
            name: m['name'] as String,
            nameArabic: m['nameArabic'] as String,
          ))
      .toList();
}

List<ReflectVerse> _parseReflectVerses(String text) {
  final verses = <ReflectVerse>[];

  for (var index = 1; index <= 2; index++) {
    final verse = ReflectVerse(
      arabic: (_parseSection(text, '##VERSE_${index}_AR##') ?? '').trim(),
      translation: (_parseSection(text, '##VERSE_${index}_EN##') ?? '').trim(),
      reference: (_parseSection(text, '##VERSE_${index}_REF##') ?? '').trim(),
    );

    if (verse.isComplete) {
      verses.add(verse);
    }
  }

  return verses;
}

ReflectResponse? parseReflectResponse(String text) {
  final rawName = _parseSection(text, '##NAME##');
  final rawNameArabic = _parseSection(text, '##NAME_AR##');
  // Strip parentheses that the AI sometimes adds
  final name = rawName?.replaceAll(RegExp(r'[()]'), '').trim();
  final nameArabic = rawNameArabic?.replaceAll(RegExp(r'[()]'), '').trim();
  final reframe = _parseSection(text, '##REFRAME##');
  final story = _parseSection(text, '##STORY##');
  final duaArabic = _parseSection(text, '##DUA_AR##');
  final duaTransliteration = _parseSection(text, '##DUA_TR##');
  final duaTranslation = _parseSection(text, '##DUA_EN##');
  final duaSource = _parseSection(text, '##DUA_SOURCE##');
  final relatedRaw = _parseSection(text, '##RELATED##');
  final parsedVerses = _parseReflectVerses(text);

  if (name == null || reframe == null) return null;

  // Validate primary name against canonical list
  final canonical = findCanonicalName(name);
  final canonicalName = canonical?.name ?? name;

  return ReflectResponse(
    name: canonicalName,
    nameArabic: canonical?.nameArabic ?? nameArabic ?? '',
    reframe: reframe,
    story: story ?? '',
    verses: normalizeApprovedVerses(canonicalName, parsedVerses),
    duaArabic: duaArabic ?? '',
    duaTransliteration: duaTransliteration ?? '',
    duaTranslation: duaTranslation ?? '',
    duaSource: duaSource ?? '',
    relatedNames: _parseRelatedNames(relatedRaw),
    offTopic: false,
  );
}

// ---------------------------------------------------------------------------
// Off-topic detection
// ---------------------------------------------------------------------------

bool isOffTopic(String text) {
  return classifyOffTopic(text).isOffTopic;
}

/// Result of off-topic classification — exposes which pattern (if any) matched
/// so callers can log the decision for tuning the regex over time.
class OffTopicResult {
  final bool isOffTopic;
  final String? matchedPattern;
  const OffTopicResult({required this.isOffTopic, this.matchedPattern});
}

/// Same logic as [isOffTopic] but returns the matching pattern label so we
/// can log it to `reflect_classifier_log` for review. Pure function — does
/// no IO. Caller is responsible for fire-and-forget logging.
OffTopicResult classifyOffTopic(String text) {
  final lower = text.toLowerCase().trim();

  // Too short to be meaningful
  if (lower.length < 3) {
    return const OffTopicResult(isOffTopic: true, matchedPattern: 'too_short');
  }

  // Patterns that indicate non-emotional input.
  // Be conservative — it's better to let a borderline input through to the model
  // than to block a genuine emotional expression. These patterns target clear
  // practical / task / entertainment requests with no emotional content.
  final offTopicPatterns = <(String, RegExp)>[
    ('greeting', RegExp(r'^(hi|hello|hey|salam|assalam|salaam)\s*[!.?]*\s*$',
        caseSensitive: false)),
    ('placeholder',
        RegExp(r'^(test|testing|asdf|aaa|123)\s*$', caseSensitive: false)),
    ('factual_lookup',
        RegExp(r'^(what is|who is|where is|when is|how do i|how to)\s+\w',
            caseSensitive: false)),
    ('entertainment_request',
        RegExp(r'^(tell me a joke|sing|write a poem|make me laugh)',
            caseSensitive: false)),
    // Recipe / cooking / food prep — emotion-free practical content.
    ('recipe',
        RegExp(r'\b(recipe|cook|bake|ingredient|marinate|saute|simmer)\b',
            caseSensitive: false)),
    // Weather queries.
    ('weather',
        RegExp(
            r'\b(weather|forecast|temperature|rain|snow)\b\s+(today|tomorrow|this|in)\b',
            caseSensitive: false)),
    // Code / software help.
    ('code',
        RegExp(
            r'\b(python|javascript|typescript|java|rust|code|function|bug|compile|stack trace|git commit)\b',
            caseSensitive: false)),
    // Entertainment suggestions.
    ('entertainment_picks',
        RegExp(
            r'\b(movie|netflix|show|series|song|playlist|game)\s+(recommend|to watch|to play|suggestion)\b',
            caseSensitive: false)),
    // Shopping / travel planning.
    ('shopping',
        RegExp(r'\b(flight|hotel|book|order|buy|cheap|discount)\s+\w+',
            caseSensitive: false)),
    // Academic / factual lookup: explain X, define X, summarize X, calculate X.
    ('academic_command',
        RegExp(
            r'^(explain|define|summarize|calculate|solve|compute|translate)\s+\w',
            caseSensitive: false)),
    // Math problems: digits with operators, variables.
    ('math_expression',
        RegExp(r'^\s*[\d().+\-*/=x ]+\s*[=?]\s*$', caseSensitive: false)),
    // Hard-science / academic topic words used as a query.
    ('academic_topic',
        RegExp(
            r'\b(quantum|calculus|algebra|physics|chemistry|biology|history of)\b',
            caseSensitive: false)),
    // Itineraries / event planning.
    ('event_planning',
        RegExp(r'\b(itinerary|plan a|plan my|agenda for|schedule for)\b',
            caseSensitive: false)),
    // Direct AI-as-search queries.
    ('search_command',
        RegExp(r'^(google|search|look up|find me)\s+\w',
            caseSensitive: false)),
  ];

  for (final pattern in offTopicPatterns) {
    if (pattern.$2.hasMatch(lower)) {
      return OffTopicResult(isOffTopic: true, matchedPattern: pattern.$1);
    }
  }
  return const OffTopicResult(isOffTopic: false);
}

Future<void> _logClassifierDecision(
  String rawUserText,
  OffTopicResult classification,
) async {
  try {
    await supabaseSyncService.insertRow('reflect_classifier_log', {
      'user_id': supabaseSyncService.currentUserId,
      'user_text': rawUserText,
      'off_topic': classification.isOffTopic,
      'matched_pattern': classification.matchedPattern,
    });
  } catch (e) {
    // Swallow — logging must never block reflect. Surface in debug builds
    // so a misconfigured table / RLS rule is at least visible locally.
    debugPrint('reflect_classifier_log insert failed: $e');
  }
}

// ---------------------------------------------------------------------------
// OpenAI Chat Completions (POST /v1/chat/completions)
//
// See: https://platform.openai.com/docs/api-reference/chat/create
// - Auth: `Authorization: Bearer <OPENAI_API_KEY>`
// - Prefer `max_completion_tokens` over deprecated `max_tokens`
// - Assistant `message.content` may be a string or a list of content parts
// ---------------------------------------------------------------------------

/// Extracts visible assistant text per ChatCompletionMessage schema.
String? _assistantMessageText(Map<String, dynamic>? message) {
  if (message == null) return null;

  final refusal = message['refusal'];
  if (refusal is String && refusal.isNotEmpty) {
    return null;
  }

  final content = message['content'];
  if (content == null) return null;

  if (content is String) {
    return content.isEmpty ? null : content;
  }

  if (content is List<dynamic>) {
    final buf = StringBuffer();
    for (final part in content) {
      if (part is! Map<String, dynamic>) continue;
      if (part['type'] == 'text' && part['text'] is String) {
        buf.write(part['text'] as String);
      }
    }
    final s = buf.toString();
    return s.isEmpty ? null : s;
  }

  return null;
}

Future<Map<String, dynamic>?> _callOpenAiChat({
  required String systemPrompt,
  required String userMessage,
  required int maxCompletionTokens,
}) async {
  const apiKey = Env.openAiApiKey;
  if (apiKey.isEmpty) return null;

  final response = await http.post(
    Uri.parse(_openAiChatUrl),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': _chatModel,
      'max_completion_tokens': maxCompletionTokens,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    }),
  );

  if (response.statusCode != 200) {
    return null;
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

String? _extractTextFromResponse(Map<String, dynamic> response) {
  final choices = response['choices'] as List<dynamic>?;
  if (choices == null || choices.isEmpty) return null;
  final first = choices[0] as Map<String, dynamic>;
  final message = first['message'] as Map<String, dynamic>?;
  return _assistantMessageText(message);
}

// ---------------------------------------------------------------------------
// Teaching context builder
// ---------------------------------------------------------------------------

String _buildTeachingContext(String userText) {
  final teachings = getRelevantTeachings(userText);
  if (teachings.isEmpty) return '';

  return teachings.map((t) {
    return '''### ${t.name} (${t.arabic})
Emotional context: ${t.emotionalContext.join(', ')}
Core teaching: ${t.coreTeaching}
Prophetic story: ${t.propheticStory}
Dua: ${t.dua.transliteration} — "${t.dua.translation}" (${t.dua.source})''';
  }).join('\n\n');
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Get follow-up questions to help the user articulate their feelings.
/// Skips if text is already detailed (>150 chars).
Future<List<FollowUpQuestion>> getFollowUpQuestions(String userText) async {
  if (userText.length > 150) return [];

  const systemPrompt =
      '''You help users explore their feelings more deeply before we match them with a Name of Allah.

Rules:
- Ask about the CONTENT of their feelings, not meta-questions about the app
- Never ask yes/no questions
- Ask questions that help clarify the emotional state
- Return exactly 2 questions in JSON format

Return a JSON array of objects, each with:
- "type": either "scale" or "choice"
- "question": the question text
- For "choice" type, include "options": array of 3-4 short options

Example:
[
  {"type": "scale", "question": "How intense is this feeling right now, from gentle to overwhelming?"},
  {"type": "choice", "question": "What triggered this feeling?", "options": ["A specific event", "It built up over time", "I woke up with it", "I'm not sure"]}
]''';

  final response = await _callOpenAiChat(
    systemPrompt: systemPrompt,
    userMessage: 'The user said: "$userText"',
    maxCompletionTokens: 300,
  );

  if (response == null) return [];

  final text = _extractTextFromResponse(response);
  if (text == null) return [];

  try {
    // Extract JSON from the response (may be wrapped in markdown code fences)
    final jsonStr = text
        .replaceAll(RegExp(r'```json?\s*'), '')
        .replaceAll('```', '')
        .trim();
    final parsed = jsonDecode(jsonStr) as List<dynamic>;

    return parsed.map((item) {
      final map = item as Map<String, dynamic>;
      final typeStr = map['type'] as String;
      final type = typeStr == 'scale'
          ? FollowUpQuestionType.scale
          : FollowUpQuestionType.choice;
      final options = map['options'] as List<dynamic>?;
      return FollowUpQuestion(
        type: type,
        question: map['question'] as String,
        options: options?.cast<String>(),
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

/// Main reflect endpoint: maps a user's feelings to a Name of Allah.
Future<ReflectResponse> reflectWithOpenAI(
  String userText, {
  ReflectContext? context,
  String? forceName,
}) async {
  // Off-topic detection — only check the raw user text (first line),
  // not the combined text which includes AI-generated follow-up questions.
  final rawUserText = userText.split('\n').first.trim();
  final classification = classifyOffTopic(rawUserText);

  // Fire-and-forget log of classifier decisions for tuning. We only log
  // the cases worth reviewing — every off-topic block (so we can audit
  // false positives) and on-topic decisions in debug builds (so devs can
  // sanity-check locally). Skipping on-topic in release keeps the table
  // from ballooning with rows nobody reads.
  // Failures here must never block the user-facing flow.
  if (classification.isOffTopic || kDebugMode) {
    unawaited(_logClassifierDecision(rawUserText, classification));
  }

  if (classification.isOffTopic) {
    final demo = getDemoResponse();
    return ReflectResponse(
      name: demo.name,
      nameArabic: demo.nameArabic,
      reframe: demo.reframe,
      story: demo.story,
      verses: demo.verses,
      duaArabic: demo.duaArabic,
      duaTransliteration: demo.duaTransliteration,
      duaTranslation: demo.duaTranslation,
      duaSource: demo.duaSource,
      relatedNames: demo.relatedNames,
      offTopic: true,
    );
  }

  // Check for API key — fallback to demo if missing
  const apiKey = Env.openAiApiKey;
  if (apiKey.isEmpty) {
    return getDemoResponse();
  }

  // Build teaching context from knowledge base
  final teachingContext = _buildTeachingContext(userText);

  // Build system prompt
  final systemPrompt = buildSystemPrompt(
    avoidNames: context?.recentNames,
    anchorNames: context?.anchorNames,
    recentEntries: context?.recentEntries,
    teachingContext: teachingContext,
    forceName: forceName,
  );

  final response = await _callOpenAiChat(
    systemPrompt: systemPrompt,
    userMessage: userText,
    maxCompletionTokens: 1500,
  );

  if (response == null) {
    return getDemoResponse();
  }

  final text = _extractTextFromResponse(response);
  if (text == null) {
    return getDemoResponse();
  }

  final parsed = parseReflectResponse(text);
  if (parsed == null) {
    return getDemoResponse();
  }

  return parsed;
}

/// Hardcoded demo response about Al-Lateef for when there is no API key
/// or as a fallback.
ReflectResponse getDemoResponse() {
  return const ReflectResponse(
    name: 'Al-Lateef',
    nameArabic: 'اللطيف',
    reframe:
        'What you\'re feeling right now — that quiet ache, that sense that things aren\'t quite '
        'right — Allah sees it, even the parts you can\'t put into words. Al-Lateef is The Subtle '
        'One, The Most Gentle. He works in ways so fine, so precise, that you may not see His plan '
        'unfolding until you look back and realize every piece was placed with care.',
    story:
        'Think of Yusuf (AS). Thrown into a well by his own brothers, sold into slavery, '
        'falsely imprisoned for years. At every stage, it looked like his life was falling apart. '
        'But Allah was Al-Lateef — gently, invisibly arranging every hardship into a path that '
        'would lead Yusuf to become the most powerful man in Egypt and reunite with his family. '
        'Yusuf himself recognized this when he said: "Indeed, my Lord is Lateef to whom He wills." (12:100)',
    verses: [
      ReflectVerse(
        arabic: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
        translation: 'Allah does not burden a soul beyond that it can bear.',
        reference: 'Al-Baqarah 2:286',
      ),
      ReflectVerse(
        arabic:
            'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ﴿٥﴾ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
        translation:
            'For indeed, with hardship comes ease. Indeed, with hardship comes ease.',
        reference: 'Ash-Sharh 94:5-6',
      ),
    ],
    duaArabic: 'اللَّهُمَّ الْطُفْ بِي فِي تَيْسِيرِ كُلِّ عَسِيرٍ',
    duaTransliteration: 'Allahumma-ltuf bi fi taysiri kulli \'aseer',
    duaTranslation:
        'O Allah, be gentle with me in making every difficulty easy.',
    duaSource: 'Common supplication based on the Name Al-Lateef',
    relatedNames: [
      RelatedName(name: 'Al-Khabir', nameArabic: 'الخبير'),
      RelatedName(name: 'Al-Hakim', nameArabic: 'الحكيم'),
    ],
    offTopic: false,
  );
}

// ---------------------------------------------------------------------------
// Find Duas
// ---------------------------------------------------------------------------

class FindDuasNameEntry {
  final String name;
  final String nameArabic;
  final String why;

  const FindDuasNameEntry({
    required this.name,
    required this.nameArabic,
    required this.why,
  });
}

class FindDuasDuaEntry {
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;

  const FindDuasDuaEntry({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
  });
}

class FindDuasResponse {
  final List<FindDuasNameEntry> names;
  final List<FindDuasDuaEntry> duas;

  const FindDuasResponse({required this.names, required this.duas});
}

// Semantic intent → category/tag mappings so natural language queries work
const _semanticMap = <String, List<String>>{
  // Family / marriage
  'wife': ['family', 'marriage'],
  'husband': ['family', 'marriage'],
  'spouse': ['family', 'marriage'],
  'marry': ['family', 'marriage'],
  'marriage': ['family', 'marriage'],
  'nikah': ['family', 'marriage'],
  'children': ['family', 'children'],
  'child': ['family', 'children'],
  'kids': ['family', 'children'],
  'baby': ['family', 'children'],
  'pregnant': ['family', 'children'],
  'parents': ['family', 'parents'],
  'mother': ['family', 'parents'],
  'father': ['family', 'parents'],
  // Wealth / provision
  'money': ['wealth', 'provision'],
  'rich': ['wealth', 'provision'],
  'debt': ['wealth', 'debt'],
  'poor': ['wealth', 'poverty'],
  'job': ['wealth', 'provision'],
  'work': ['wealth', 'provision'],
  'income': ['wealth', 'provision'],
  'rizq': ['wealth', 'provision'],
  'halal': ['wealth', 'halal'],
  // Anxiety / stress
  'anxious': ['anxiety', 'worry'],
  'anxiety': ['anxiety'],
  'stress': ['anxiety', 'worry'],
  'worried': ['anxiety', 'worry'],
  'fear': ['anxiety', 'protection'],
  'scared': ['anxiety', 'protection'],
  'overwhelmed': ['anxiety'],
  'depressed': ['anxiety', 'grief'],
  'sad': ['grief'],
  'grief': ['grief'],
  'loss': ['grief'],
  // Forgiveness
  'forgive': ['forgiveness', 'repentance'],
  'sin': ['forgiveness', 'repentance'],
  'repent': ['forgiveness', 'repentance'],
  'guilt': ['forgiveness'],
  'tawbah': ['forgiveness'],
  // Guidance
  'guidance': ['guidance'],
  'decision': ['guidance', 'istikhara'],
  'istikhara': ['guidance', 'istikhara'],
  'confused': ['guidance'],
  'lost': ['guidance'],
  'direction': ['guidance'],
  // Gratitude / morning / evening
  'grateful': ['gratitude'],
  'thankful': ['gratitude'],
  'morning': ['morning'],
  'waking': ['morning'],
  'evening': ['evening'],
  'night': ['evening', 'sleep'],
  'sleep': ['sleep'],
  // Protection
  'protect': ['protection'],
  'evil': ['protection'],
  'safe': ['protection'],
  // Hope
  'hope': ['hope'],
  'trust': ['hope', 'tawakkul'],
  'patience': ['hope', 'grief'],
  // Travel
  'travel': ['travel'],
  'journey': ['travel'],
  'trip': ['travel'],
};

/// Search the local browse duas catalog for duas matching the user's need.
/// Uses semantic intent mapping + keyword + emotion tag matching.
/// Returns up to 5 best matches sorted by relevance score.
List<FindDuasDuaEntry> _searchLocalDuas(String need) {
  final query = need.toLowerCase();
  final queryWords =
      query.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
  final duas = browseDuasCatalog;

  // Expand query words to inferred categories/tags via semantic map
  final inferredTags = <String>{};
  for (final word in queryWords) {
    for (final key in _semanticMap.keys) {
      if (word.contains(key) || key.contains(word)) {
        inferredTags.addAll(_semanticMap[key]!);
      }
    }
  }

  final scored = <(int, BrowseDua)>[];
  for (final dua in duas) {
    int score = 0;
    final searchable = [
      dua.title,
      dua.translation,
      dua.transliteration,
      dua.category,
      dua.whenToRecite ?? '',
      ...(dua.emotionTags ?? []),
    ].join(' ').toLowerCase();

    // Direct keyword match in dua text
    for (final word in queryWords) {
      if (word.length > 2 && searchable.contains(word)) score += 2;
    }

    // Inferred tag matches category
    if (inferredTags.contains(dua.category)) score += 6;

    // Inferred tag matches emotion tags
    for (final tag in (dua.emotionTags ?? [])) {
      if (inferredTags.contains(tag)) score += 4;
    }

    // Exact category match from query word
    for (final word in queryWords) {
      if (dua.category == word) score += 8;
    }

    if (score > 0) scored.add((score, dua));
  }

  scored.sort((a, b) => b.$1.compareTo(a.$1));

  return scored.take(5).map((pair) {
    final d = pair.$2;
    return FindDuasDuaEntry(
      title: d.title,
      arabic: d.arabic,
      transliteration: d.transliteration,
      translation: d.translation,
      source: d.source,
    );
  }).toList();
}

Future<FindDuasResponse> findDuas(String need) async {
  // 1. Search local duas — always fast, free, verified
  final localDuas = _searchLocalDuas(need);
  final fallbackCatalog = browseDuasCatalog;

  // 2. Get Names of Allah via model (lightweight call, names only)
  final names = await _findNamesForNeed(need);

  // 3. If no local results found, fall back to a general set
  final duas = localDuas.isNotEmpty
      ? localDuas
      : fallbackCatalog
          .take(3)
          .map((d) => FindDuasDuaEntry(
                title: d.title,
                arabic: d.arabic,
                transliteration: d.transliteration,
                translation: d.translation,
                source: d.source,
              ))
          .toList();

  return FindDuasResponse(names: names, duas: duas);
}

Future<List<FindDuasNameEntry>> _findNamesForNeed(String need) async {
  const apiKey = Env.openAiApiKey;
  if (apiKey.isEmpty) {
    return const [
      FindDuasNameEntry(
        name: 'Al-Mujeeb',
        nameArabic: 'الْمُجِيبُ',
        why: 'The One who responds to every call — call on Him by this Name.',
      ),
    ];
  }

  try {
    final teachings = getRelevantTeachings(need);
    final teachingContext = teachings
        .take(5)
        .map((t) =>
            '${t.name} (${t.arabic}): ${t.emotionalContext.take(3).join(', ')} — ${t.coreTeaching}')
        .join('\n');

    final canonicalList = buildCanonicalNamesPromptList();

    final response = await _callOpenAiChat(
      systemPrompt:
          'You are an Islamic learning tool. A person has described what they want to make dua for. '
          'Identify the 2-3 most fitting Names of Allah to call upon for this need.\n\n'
          'Available Names and context:\n$teachingContext\n\n'
          'IMPORTANT — only use Names from this canonical list (exact spelling):\n$canonicalList\n\n'
          'Respond with EXACTLY this format (one name per line):\n'
          'English · Arabic · [one sentence why this Name fits their specific need]',
      userMessage: need,
      maxCompletionTokens: 300,
    );

    if (response == null) return [];

    final text = _extractTextFromResponse(response);
    if (text == null) return [];

    final parsedNameMaps = text
        .split('\n')
        .where((l) => l.trim().isNotEmpty && l.contains('·'))
        .map((line) {
          final parts = line.split('·').map((s) => s.trim()).toList();
          final whyMatch =
              RegExp(r'\[(.+)\]').firstMatch(parts.length > 2 ? parts[2] : '');
          return {
            'name': (parts.isNotEmpty ? parts[0] : '')
                .replaceAll(RegExp(r'^[-\d.)\s]+'), '')
                .trim(),
            'nameArabic': parts.length > 1 ? parts[1].trim() : '',
            'why': whyMatch != null
                ? whyMatch.group(1)!
                : (parts.length > 2 ? parts[2].trim() : ''),
          };
        })
        .where((n) => (n['name'] as String).isNotEmpty)
        .toList();

    final validatedNames = filterValidNames(parsedNameMaps);
    return validatedNames
        .map((m) => FindDuasNameEntry(
              name: m['name'] as String,
              nameArabic: m['nameArabic'] as String,
              why: m['why'] as String? ?? '',
            ))
        .toList();
  } catch (_) {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Build Dua
// ---------------------------------------------------------------------------

class BuiltDuaSection {
  final String label;
  final String arabic;
  final String transliteration;
  final String translation;

  const BuiltDuaSection({
    required this.label,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

class BuiltDuaNameUsed {
  final String name;
  final String nameArabic;
  final String why;

  const BuiltDuaNameUsed({
    required this.name,
    required this.nameArabic,
    required this.why,
  });
}

class BuiltDuaResponse {
  final String arabic;
  final String transliteration;
  final String translation;
  final List<BuiltDuaSection> breakdown;
  final List<BuiltDuaNameUsed> namesUsed;
  final List<FindDuasDuaEntry> relatedDuas;

  const BuiltDuaResponse({
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.breakdown,
    required this.namesUsed,
    required this.relatedDuas,
  });
}

Future<BuiltDuaResponse> buildDua(String need) async {
  const apiKey = Env.openAiApiKey;
  if (apiKey.isEmpty) {
    return const BuiltDuaResponse(
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      transliteration: 'Bismillahi r-rahmani r-rahim',
      translation:
          'In the name of Allah, the Most Gracious, the Most Merciful.',
      breakdown: [
        BuiltDuaSection(
          label: 'Opening',
          arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
          transliteration: 'Bismillahi r-rahmani r-rahim',
          translation:
              'In the name of Allah, the Most Gracious, the Most Merciful.',
        ),
      ],
      namesUsed: [],
      relatedDuas: [],
    );
  }

  // Get relevant Names from both knowledge bases
  final nameGuidanceResults = getNameGuidanceForNeed(need);
  final knowledgeBaseTeachings = nameGuidanceResults.length < 2
      ? getRelevantTeachings(need)
      : <NameTeaching>[];

  // Build name context: prioritise duaKnowledge guidance, supplement with knowledgeBase
  String nameContext;
  if (nameGuidanceResults.take(3).isNotEmpty) {
    nameContext = nameGuidanceResults
        .take(3)
        .map((n) =>
            '- ${n.name} (${n.arabic}): Call upon for ${n.callFor.take(3).join(', ')}\n'
            '  Invocation: ${n.invocationStyle}\n'
            '  Sample phrase: ${n.samplePhrase}')
        .join('\n');
  } else {
    nameContext = knowledgeBaseTeachings
        .take(3)
        .map((t) =>
            '- ${t.name} (${t.arabic}): Call upon for ${t.emotionalContext.take(3).join(', ')}\n'
            '  Invocation: ${t.dua.transliteration}\n'
            '  Sample phrase: ${t.dua.arabic}')
        .join('\n');
  }

  // Pick the most thematically fitting hamd opening
  final needLower = need.toLowerCase();
  final hamdOpening = hamdOpenings.cast<HamdOpening?>().firstWhere(
        (h) =>
            needLower.contains(h!.theme) ||
            (h.theme == 'provision' &&
                RegExp(r'money|job|debt|rizq|sustain|provide')
                    .hasMatch(needLower)) ||
            (h.theme == 'healing' &&
                RegExp(r'sick|health|ill|pain|hurt|heal')
                    .hasMatch(needLower)) ||
            (h.theme == 'guidance' &&
                RegExp(r'guide|lost|direction|confus|decision')
                    .hasMatch(needLower)) ||
            (h.theme == 'mercy' &&
                RegExp(r'sin|forgiv|guilt|shame|return').hasMatch(needLower)),
        orElse: () => hamdOpenings[0],
      )!;

  final canonicalNamesList = buildCanonicalNamesPromptList();

  final response = await _callOpenAiChat(
    systemPrompt:
        'You are an Islamic scholar constructing a personal dua in classical Arabic following authentic prophetic etiquette (adab al-du\'a).\n\n'
        'CRITICAL — You MUST only invoke Names of Allah from this canonical list. Do not invent or use any Name not on this list:\n'
        '$canonicalNamesList\n\n\n'
        '$duaEtiquettes\n\n'
        '---\n\n'
        'NAMES OF ALLAH MOST RELEVANT TO THIS NEED:\n'
        '$nameContext\n\n'
        '---\n\n'
        'STRUCTURE — follow this EXACTLY, four sections, no exceptions:\n\n'
        'SECTION 1 — OPENING PRAISE (Hamd and Thana)\n'
        '- Begin with hamd of Allah. You may use this authentic opening as your base, then expand with the relevant Names above:\n'
        '  Arabic: ${hamdOpening.arabic}\n'
        '  Meaning: ${hamdOpening.translation}\n'
        '- Praise Allah using the Names most relevant to this specific need. Address Him directly.\n'
        '- Do NOT make any request yet — this section is praise only.\n\n'
        'SECTION 2 — SALAWAT ON THE PROPHET \uFDFA\n'
        '- Use this authentic salawat:\n'
        '  Arabic: ${SalawatFormulas.standard.arabic}\n'
        '  Transliteration: ${SalawatFormulas.standard.transliteration}\n'
        '- You may expand it slightly but must include the core formula.\n\n'
        'SECTION 3 — THE ASK\n'
        '- Now make the specific request, addressing Allah directly with "Ya [Name]..." or "Allahumma..."\n'
        '- Be specific and personal to the need — not generic.\n'
        '- Invoke the relevant Names of Allah within the ask itself.\n'
        '- Express humility: acknowledge weakness, Allah\'s power, and trust in His wisdom.\n'
        '- Use phrases like: "inni as\'aluka...", "ya [Name], urzuqni...", "ya [Name], ihdini..."\n\n'
        'SECTION 4 — CLOSING\n'
        '- Send salawat on the Prophet \uFDFA again.\n'
        '- Close with hamd: ${SalawatFormulas.closing.arabic}\n\n'
        'RULES:\n'
        '- Classical Arabic with full harakat (vowel marks) throughout\n'
        '- Every phrase grammatically sound\n'
        '- The Ask must feel personal to this specific need — not boilerplate\n'
        '- This is a constructed personal dua, not from hadith — do not claim otherwise\n\n'
        'Respond with EXACTLY these 12 markers in order — no extra text outside them:\n\n'
        '##S1_ARABIC##\n(Arabic of Opening Praise only)\n'
        '##S1_TRANSLIT##\n(transliteration of Opening Praise)\n'
        '##S1_TRANSLATION##\n(English translation of Opening Praise)\n'
        '##S2_ARABIC##\n(Arabic of Salawat only)\n'
        '##S2_TRANSLIT##\n(transliteration of Salawat)\n'
        '##S2_TRANSLATION##\n(English translation of Salawat)\n'
        '##S3_ARABIC##\n(Arabic of The Ask only)\n'
        '##S3_TRANSLIT##\n(transliteration of The Ask)\n'
        '##S3_TRANSLATION##\n(English translation of The Ask)\n'
        '##S4_ARABIC##\n(Arabic of Closing only)\n'
        '##S4_TRANSLIT##\n(transliteration of Closing)\n'
        '##S4_TRANSLATION##\n(English translation of Closing)\n'
        '##NAMES_USED##\n'
        'List each Name of Allah you invoked, one per line as: English · Arabic · one sentence on why this Name fits this need\n'
        '##RELATED_DUAS##\n'
        '3 authentic duas from Quran or hadith related to this need, each on one line as:\n'
        'Title | Arabic | Transliteration | Translation | Source\n'
        'IMPORTANT: Include the COMPLETE dua text — do NOT truncate or abbreviate. Give the full Arabic, full transliteration, and full translation for each dua.',
    userMessage: 'I want to make dua for: $need',
    maxCompletionTokens: 3500,
  );

  if (response == null) {
    return const BuiltDuaResponse(
      arabic: '',
      transliteration: '',
      translation: '',
      breakdown: [],
      namesUsed: [],
      relatedDuas: [],
    );
  }

  final text = _extractTextFromResponse(response);
  if (text == null) {
    return const BuiltDuaResponse(
      arabic: '',
      transliteration: '',
      translation: '',
      breakdown: [],
      namesUsed: [],
      relatedDuas: [],
    );
  }

  // Parse the 4 sections from 12 markers
  const sectionDefs = [
    (
      'Opening Praise',
      '##S1_ARABIC##',
      '##S1_TRANSLIT##',
      '##S1_TRANSLATION##'
    ),
    ('Salawat', '##S2_ARABIC##', '##S2_TRANSLIT##', '##S2_TRANSLATION##'),
    ('The Ask', '##S3_ARABIC##', '##S3_TRANSLIT##', '##S3_TRANSLATION##'),
    ('Closing', '##S4_ARABIC##', '##S4_TRANSLIT##', '##S4_TRANSLATION##'),
  ];

  final nextArabicMarkers = [
    '##S2_ARABIC##',
    '##S3_ARABIC##',
    '##S4_ARABIC##',
    '##NAMES_USED##'
  ];

  final breakdown = <BuiltDuaSection>[];
  for (var i = 0; i < sectionDefs.length; i++) {
    final (label, aMarker, tMarker, trMarker) = sectionDefs[i];
    final rawArabic = _parseSection(text, aMarker) ?? '';
    final rawTranslit = _parseSection(text, tMarker) ?? '';
    final rawTranslation = _parseSection(text, trMarker) ?? '';

    // Trim content that may bleed past the intended next marker
    String trimTo(String content, String marker) {
      final idx = content.indexOf(marker);
      return idx != -1 ? content.substring(0, idx).trim() : content;
    }

    final sArabic = trimTo(rawArabic, tMarker);
    final sTranslit = trimTo(rawTranslit, trMarker);
    final sTranslation = trimTo(rawTranslation, nextArabicMarkers[i]);

    if (sArabic.trim().isNotEmpty) {
      breakdown.add(BuiltDuaSection(
        label: label,
        arabic: sArabic,
        transliteration: sTranslit,
        translation: sTranslation,
      ));
    }
  }

  // Full dua = join all sections
  final arabic = breakdown.map((s) => s.arabic).join('\n\n');
  final transliteration = breakdown.map((s) => s.transliteration).join('\n\n');
  final translation = breakdown.map((s) => s.translation).join('\n\n');

  // Parse names used — validate against canonical list
  final namesRaw = _parseSection(text, '##NAMES_USED##') ?? '';
  final namesBlock = namesRaw.contains('##RELATED_DUAS##')
      ? namesRaw.substring(0, namesRaw.indexOf('##RELATED_DUAS##'))
      : namesRaw;
  // Try multiple separators that the AI might use
  final separatorPattern = RegExp(r'\s*[·\|\-—–:]\s*');
  final parsedNameMaps = namesBlock
      .split('\n')
      .where((l) {
        final trimmed = l.trim();
        if (trimmed.isEmpty) return false;
        // Must have at least 2 parts when split by separator
        return trimmed.split(separatorPattern).length >= 2;
      })
      .map((line) {
        final parts =
            line.split(separatorPattern).map((s) => s.trim()).toList();
        return {
          'name': (parts.isNotEmpty ? parts[0] : '')
              .replaceAll(RegExp(r'^[-\d.)\s]+'), '')
              .trim(),
          'nameArabic': parts.length > 1 ? parts[1].trim() : '',
          'why': parts.length > 2 ? parts.sublist(2).join(' — ').trim() : '',
        };
      })
      .where((n) => (n['name'] as String).isNotEmpty)
      .toList();

  // Don't filter — keep all names the AI returned, even if not in canonical 99
  final namesUsed = parsedNameMaps
      .map((m) => BuiltDuaNameUsed(
            name: m['name'] as String,
            nameArabic: m['nameArabic'] as String,
            why: m['why'] ?? '',
          ))
      .toList();

  // Parse related duas
  final relatedRaw = _parseSection(text, '##RELATED_DUAS##') ?? '';
  final relatedDuas = relatedRaw
      .split('\n')
      .where((l) => l.trim().isNotEmpty && l.contains('|'))
      .map((line) {
        final parts = line.split('|').map((s) => s.trim()).toList();
        return FindDuasDuaEntry(
          title: (parts.isNotEmpty ? parts[0] : '')
              .replaceAll(RegExp(r'^[-\d.)\s]+'), '')
              .trim(),
          arabic: parts.length > 1 ? parts[1] : '',
          transliteration: parts.length > 2 ? parts[2] : '',
          translation: parts.length > 3 ? parts[3] : '',
          source: parts.length > 4 ? parts[4] : '',
        );
      })
      .where((d) => d.title.isNotEmpty && d.arabic.isNotEmpty)
      .toList();

  // Fallback: if AI didn't list names used, scan the Arabic text for known Names
  final finalNamesUsed =
      namesUsed.isNotEmpty ? namesUsed : _detectNamesInArabic(arabic);

  return BuiltDuaResponse(
    arabic: arabic,
    transliteration: transliteration,
    translation: translation,
    breakdown: breakdown,
    namesUsed: finalNamesUsed,
    relatedDuas: relatedDuas,
  );
}

/// Scan Arabic dua text for Names of Allah by matching against the canonical list.
List<BuiltDuaNameUsed> _detectNamesInArabic(String arabicText) {
  if (arabicText.isEmpty) return [];
  // Strip diacritics for matching
  final stripped = arabicText.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  final found = <BuiltDuaNameUsed>[];
  for (final name in allahNames) {
    // Skip "Allah" (too common — it's in every dua)
    if (name.id == 1) continue;
    final nameStripped =
        name.arabic.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    if (stripped.contains(nameStripped)) {
      found.add(BuiltDuaNameUsed(
        name: '${name.transliteration} (${name.english})',
        nameArabic: name.arabic,
        why: name.meaning,
      ));
    }
  }
  return found;
}

// ---------------------------------------------------------------------------
// Daily question response
// ---------------------------------------------------------------------------

class DailyReflectResponse {
  final String name;
  final String nameArabic;

  const DailyReflectResponse({
    required this.name,
    required this.nameArabic,
  });
}

/// [answers] — list of 4 answers: [q1, q2, q3, q4]
/// [historyContext] — optional string from buildHistoryContext(), may be empty
/// [recentNames] — names shown in the last N sessions to avoid repeating
Future<DailyReflectResponse> getDailyResponse(
  List<String> answers, {
  String historyContext = '',
  List<String> recentNames = const [],
  List<String> discoveredNames = const [],
}) async {
  const apiKey = Env.openAiApiKey;
  if (apiKey.isEmpty) {
    return const DailyReflectResponse(
      name: 'Al-Wakeel',
      nameArabic: 'الْوَكِيلُ',
    );
  }

  final dailyCanonicalList = buildCanonicalNamesPromptList();

  final avoidClause = recentNames.isNotEmpty
      ? 'IMPORTANT — Do NOT return any of these Names shown recently: ${recentNames.join(", ")}. '
          'The user needs variety. Pick a genuinely different Name that still fits their answers.\n\n'
      : '';

  final discoveryClause = discoveredNames.isNotEmpty
      ? 'The user has already discovered these Names: ${discoveredNames.join(", ")}. '
          'STRONGLY PREFER a Name they have NOT yet discovered, as long as it still fits their emotional state. '
          'Only return an already-discovered Name if no undiscovered Name is a good fit.\n\n'
      : '';

  final historySection = historyContext.isNotEmpty
      ? 'PAST CHECK-INS (most recent first):\n$historyContext\n\n'
          'Use this history to avoid repeating the same Name.\n\n'
      : '';

  final answersFormatted = [
    'How they feel: ${answers.isNotEmpty ? answers[0] : ""}',
    'Where it is coming from: ${answers.length > 1 ? answers[1] : ""}',
    'How it feels deeper down: ${answers.length > 2 ? answers[2] : ""}',
    'What they need from Allah: ${answers.length > 3 ? answers[3] : ""}',
  ].join('\n');

  final response = await _callOpenAiChat(
    systemPrompt:
        'You are an Islamic learning tool. A person has completed a 4-question daily check-in. '
        'Based on their answers, identify the single most fitting Name of Allah.\n\n'
        '$avoidClause'
        '$discoveryClause'
        '$historySection'
        'IMPORTANT — You MUST only use a Name from this canonical list of the 99 Names:\n'
        '$dailyCanonicalList\n\n'
        '---\n\n'
        'Respond with EXACTLY this marker, nothing else:\n'
        '##NAME## (English · Arabic)\n\n'
        'Example: ##NAME## As-Saboor · ٱلصَّبُورُ',
    userMessage: answersFormatted,
    maxCompletionTokens: 100,
  );

  if (response == null) {
    return const DailyReflectResponse(
      name: 'Al-Wakeel',
      nameArabic: 'الْوَكِيلُ',
    );
  }

  final text = _extractTextFromResponse(response);
  if (text == null) {
    return const DailyReflectResponse(
      name: 'Al-Wakeel',
      nameArabic: 'الْوَكِيلُ',
    );
  }

  // Parse name
  final nameRaw = _parseSection(text, '##NAME##') ?? 'Al-Wakeel';
  final nameParts = nameRaw.split('·').map((s) => s.trim()).toList();
  final parsedName = (nameParts.isNotEmpty ? nameParts[0] : 'Al-Wakeel')
      .replaceAll(RegExp(r'[()]'), '')
      .trim();
  final parsedNameArabic = (nameParts.length > 1 ? nameParts[1] : '')
      .replaceAll(RegExp(r'[()]'), '')
      .trim();

  // Validate against canonical list
  final canonical = findCanonicalName(parsedName);

  return DailyReflectResponse(
    name: canonical?.name ?? parsedName,
    nameArabic: canonical?.nameArabic ?? parsedNameArabic,
  );
}
