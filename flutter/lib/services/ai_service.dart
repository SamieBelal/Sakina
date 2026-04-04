/// Claude API integration for the Sakina app.
///
/// Ports the logic from the original TypeScript claude.ts.
/// Maps user emotions to Names of Allah via Claude, parses structured
/// responses, and provides follow-up question generation.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sakina/core/constants/dua_knowledge.dart';
import 'package:sakina/core/constants/knowledge_base.dart';
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

const String _claudeApiUrl = kIsWeb
    ? 'http://localhost:8787/v1/messages'
    : 'https://api.anthropic.com/v1/messages';
const _reflectModel = 'claude-sonnet-4-20250514';
const _followUpModel = 'claude-haiku-4-5-20251001';
const _anthropicVersion = '2023-06-01';

// ---------------------------------------------------------------------------
// System prompt
// ---------------------------------------------------------------------------

String buildSystemPrompt({
  List<String>? avoidNames,
  List<String>? anchorNames,
  List<ReflectContextEntry>? recentEntries,
  String? teachingContext,
}) {
  final avoidClause = (avoidNames != null && avoidNames.isNotEmpty)
      ? '\n\nIMPORTANT: The user has recently been shown these Names: ${avoidNames.join(", ")}. '
          'Do NOT repeat any of them. Pick a DIFFERENT Name that still fits their feeling.'
      : '';

  final anchorClause = (anchorNames != null && anchorNames.isNotEmpty)
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

  return '''You are an Islamic learning tool drawing on Sheikh Omar Suleiman's "The Dua I Need" series and "The Name I Need" series by Sheikh Mikaeel Smith. A user will share how they feel, and you will respond with ONE Name of Allah that speaks to that emotion.

## Canonical Names of Allah
You MUST pick from this exact list. Do NOT invent or modify Names.
$canonicalList
$avoidClause$anchorClause$historyClause$teachingClause

## Response Format
Respond with EXACTLY these markers, each on its own line, followed by the content:

##NAME## (the transliterated Name, e.g. Al-Lateef)
##NAME_AR## (the Arabic Name, e.g. اللطيف)
##REFRAME## (2-3 sentences reframing the user's feeling through the lens of this Name)
##STORY## (a prophetic story or Quranic narrative illustrating this Name — 3-5 sentences)
##DUA_AR## (the Arabic dua text)
##DUA_TR## (transliteration of the dua)
##DUA_EN## (English translation of the dua)
##DUA_SOURCE## (hadith/Quran source reference)
##RELATED## (2-3 other Names that also relate, format: Name (Arabic) | Name (Arabic) | ...)

Rules:
- Keep the reframe warm, empathetic, and grounded in Islamic theology. No fluff.
- The story must be authentic — from Quran or sahih hadith. NEVER fabricate.
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
  final nextMarker = RegExp(r'##[A-Z_]+##');
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

ReflectResponse? parseClaudeResponse(String text) {
  final name = _parseSection(text, '##NAME##');
  final nameArabic = _parseSection(text, '##NAME_AR##');
  final reframe = _parseSection(text, '##REFRAME##');
  final story = _parseSection(text, '##STORY##');
  final duaArabic = _parseSection(text, '##DUA_AR##');
  final duaTransliteration = _parseSection(text, '##DUA_TR##');
  final duaTranslation = _parseSection(text, '##DUA_EN##');
  final duaSource = _parseSection(text, '##DUA_SOURCE##');
  final relatedRaw = _parseSection(text, '##RELATED##');

  if (name == null || reframe == null) return null;

  // Validate primary name against canonical list
  final canonical = findCanonicalName(name);

  return ReflectResponse(
    name: canonical?.name ?? name,
    nameArabic: canonical?.nameArabic ?? nameArabic ?? '',
    reframe: reframe,
    story: story ?? '',
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
  final lower = text.toLowerCase().trim();

  // Too short to be meaningful
  if (lower.length < 3) return true;

  // Patterns that indicate non-emotional input
  final offTopicPatterns = [
    RegExp(r'^(hi|hello|hey|salam|assalam|salaam)\s*$', caseSensitive: false),
    RegExp(r'^(test|testing|asdf|aaa|123)\s*$', caseSensitive: false),
    RegExp(r'^(what|who|where|when|how|why)\s+(is|are|was|were|do|does|did|can|could|will|would|should)\b',
        caseSensitive: false),
    RegExp(r'(weather|stock|price|score|recipe|code|program|translate)', caseSensitive: false),
    RegExp(r'^(tell me a joke|sing|write a poem|make me laugh)', caseSensitive: false),
  ];

  return offTopicPatterns.any((p) => p.hasMatch(lower));
}

// ---------------------------------------------------------------------------
// Claude API calls
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>?> _callClaude({
  required String model,
  required String systemPrompt,
  required String userMessage,
  required int maxTokens,
}) async {
  final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) return null;

  final response = await http.post(
    Uri.parse(_claudeApiUrl),
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': _anthropicVersion,
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'messages': [
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
  final content = response['content'] as List<dynamic>?;
  if (content == null || content.isEmpty) return null;
  final first = content[0] as Map<String, dynamic>;
  return first['text'] as String?;
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
/// Uses Claude Haiku for speed. Skips if text is already detailed (>150 chars).
Future<List<FollowUpQuestion>> getFollowUpQuestions(String userText) async {
  if (userText.length > 150) return [];

  const systemPrompt = '''You help users explore their feelings more deeply before we match them with a Name of Allah.

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

  final response = await _callClaude(
    model: _followUpModel,
    systemPrompt: systemPrompt,
    userMessage: 'The user said: "$userText"',
    maxTokens: 300,
  );

  if (response == null) return [];

  final text = _extractTextFromResponse(response);
  if (text == null) return [];

  try {
    // Extract JSON from the response (may be wrapped in markdown code fences)
    final jsonStr = text.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
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

/// Main reflect endpoint: maps a user's feelings to a Name of Allah via Claude Sonnet.
Future<ReflectResponse> reflectWithClaude(
  String userText, {
  ReflectContext? context,
}) async {
  // Off-topic detection
  if (isOffTopic(userText)) {
    final demo = getDemoResponse();
    return ReflectResponse(
      name: demo.name,
      nameArabic: demo.nameArabic,
      reframe: demo.reframe,
      story: demo.story,
      duaArabic: demo.duaArabic,
      duaTransliteration: demo.duaTransliteration,
      duaTranslation: demo.duaTranslation,
      duaSource: demo.duaSource,
      relatedNames: demo.relatedNames,
      offTopic: true,
    );
  }

  // Check for API key — fallback to demo if missing
  final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
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
  );

  final response = await _callClaude(
    model: _reflectModel,
    systemPrompt: systemPrompt,
    userMessage: userText,
    maxTokens: 1500,
  );

  if (response == null) {
    return getDemoResponse();
  }

  final text = _extractTextFromResponse(response);
  if (text == null) {
    return getDemoResponse();
  }

  final parsed = parseClaudeResponse(text);
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

Future<FindDuasResponse> findDuas(String need) async {
  final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    return const FindDuasResponse(
      names: [
        FindDuasNameEntry(
          name: 'Al-Mujeeb',
          nameArabic: 'الْمُجِيبُ',
          why: 'The One who responds to every call — call on Him by this Name.',
        ),
      ],
      duas: [
        FindDuasDuaEntry(
          title: 'The Dua of Need',
          arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ',
          transliteration: "Allahumma inni as'aluk",
          translation: 'O Allah, I ask You.',
          source: 'General',
        ),
      ],
    );
  }

  final teachings = getRelevantTeachings(need);
  final teachingContext = teachings.take(5).map((t) =>
    '${t.name} (${t.arabic}): ${t.emotionalContext.take(3).join(', ')} — ${t.coreTeaching}\n'
    'Dua: ${t.dua.arabic} | ${t.dua.transliteration} | ${t.dua.translation} | ${t.dua.source}'
  ).join('\n\n');

  final canonicalList = buildCanonicalNamesPromptList();

  final response = await _callClaude(
    model: _followUpModel,
    systemPrompt: 'You are an Islamic learning tool. A person has described what they want to make dua for. Based on the Names of Allah below, identify the 2-3 most fitting Names to call upon for this need, and provide 3-4 relevant duas they can recite.\n\n'
        'Available Names and their duas:\n$teachingContext\n\n'
        'IMPORTANT — Canonical Names of Allah (you MUST only use Names from this list, exact spelling):\n$canonicalList\n\n'
        'Instructions:\n'
        '- Choose 2-3 Names most relevant to their need — only from the canonical list above\n'
        '- For each Name, write one sentence explaining why this Name is appropriate to call upon (specific to their need, not generic)\n'
        '- Provide 3-4 duas — use the exact duas from the Names above where appropriate, and supplement with authentic Quranic/hadith duas if needed\n'
        '- All duas must be authentic — from Quran or hadith only\n\n'
        'Respond with EXACTLY:\n'
        '##NAMES##\n'
        'Each name on its own line as: English · Arabic · [one sentence why]\n'
        '##DUAS##\n'
        'Each dua as: Title | Arabic | Transliteration | Translation | Source\n'
        '(one dua per line)',
    userMessage: need,
    maxTokens: 800,
  );

  if (response == null) {
    return const FindDuasResponse(names: [], duas: []);
  }

  final text = _extractTextFromResponse(response);
  if (text == null) {
    return const FindDuasResponse(names: [], duas: []);
  }

  // Parse names
  final namesRaw = _parseSection(text, '##NAMES##') ?? '';
  final duasMarkerIdx = namesRaw.indexOf('##DUAS##');
  final namesBlock = duasMarkerIdx != -1 ? namesRaw.substring(0, duasMarkerIdx) : namesRaw;
  final parsedNameMaps = namesBlock
      .split('\n')
      .where((l) => l.trim().isNotEmpty && l.contains('·'))
      .map((line) {
        final parts = line.split('·').map((s) => s.trim()).toList();
        final whyMatch = RegExp(r'\[(.+)\]').firstMatch(parts.length > 2 ? parts[2] : '');
        return {
          'name': (parts.isNotEmpty ? parts[0] : '').replaceAll(RegExp(r'^[-\d.)\s]+'), '').trim(),
          'nameArabic': parts.length > 1 ? parts[1].trim() : '',
          'why': whyMatch != null ? whyMatch.group(1)! : (parts.length > 2 ? parts[2].trim() : ''),
        };
      })
      .where((n) => (n['name'] as String).isNotEmpty)
      .toList();

  final validatedNames = filterValidNames(parsedNameMaps);
  final names = validatedNames
      .map((m) => FindDuasNameEntry(
            name: m['name'] as String,
            nameArabic: m['nameArabic'] as String,
            why: m['why'] as String? ?? '',
          ))
      .toList();

  // Parse duas
  final duasRaw = _parseSection(text, '##DUAS##') ?? '';
  final duas = duasRaw
      .split('\n')
      .where((l) => l.trim().isNotEmpty && l.contains('|'))
      .map((line) {
        final parts = line.split('|').map((s) => s.trim()).toList();
        return FindDuasDuaEntry(
          title: (parts.isNotEmpty ? parts[0] : '').replaceAll(RegExp(r'^[-\d.)\s]+'), '').trim(),
          arabic: parts.length > 1 ? parts[1] : '',
          transliteration: parts.length > 2 ? parts[2] : '',
          translation: parts.length > 3 ? parts[3] : '',
          source: parts.length > 4 ? parts[4] : '',
        );
      })
      .where((d) => d.title.isNotEmpty && d.arabic.isNotEmpty)
      .toList();

  return FindDuasResponse(names: names, duas: duas);
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
  final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    return const BuiltDuaResponse(
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      transliteration: 'Bismillahi r-rahmani r-rahim',
      translation: 'In the name of Allah, the Most Gracious, the Most Merciful.',
      breakdown: [
        BuiltDuaSection(
          label: 'Opening',
          arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
          transliteration: 'Bismillahi r-rahmani r-rahim',
          translation: 'In the name of Allah, the Most Gracious, the Most Merciful.',
        ),
      ],
      namesUsed: [],
      relatedDuas: [],
    );
  }

  // Get relevant Names from both knowledge bases
  final nameGuidanceResults = getNameGuidanceForNeed(need);
  final knowledgeBaseTeachings =
      nameGuidanceResults.length < 2 ? getRelevantTeachings(need) : <NameTeaching>[];

  // Build name context: prioritise duaKnowledge guidance, supplement with knowledgeBase
  String nameContext;
  if (nameGuidanceResults.take(3).isNotEmpty) {
    nameContext = nameGuidanceResults.take(3).map((n) =>
      '- ${n.name} (${n.arabic}): Call upon for ${n.callFor.take(3).join(', ')}\n'
      '  Invocation: ${n.invocationStyle}\n'
      '  Sample phrase: ${n.samplePhrase}'
    ).join('\n');
  } else {
    nameContext = knowledgeBaseTeachings.take(3).map((t) =>
      '- ${t.name} (${t.arabic}): Call upon for ${t.emotionalContext.take(3).join(', ')}\n'
      '  Invocation: ${t.dua.transliteration}\n'
      '  Sample phrase: ${t.dua.arabic}'
    ).join('\n');
  }

  // Pick the most thematically fitting hamd opening
  final needLower = need.toLowerCase();
  final hamdOpening = hamdOpenings.cast<HamdOpening?>().firstWhere(
    (h) =>
        needLower.contains(h!.theme) ||
        (h.theme == 'provision' && RegExp(r'money|job|debt|rizq|sustain|provide').hasMatch(needLower)) ||
        (h.theme == 'healing' && RegExp(r'sick|health|ill|pain|hurt|heal').hasMatch(needLower)) ||
        (h.theme == 'guidance' && RegExp(r'guide|lost|direction|confus|decision').hasMatch(needLower)) ||
        (h.theme == 'mercy' && RegExp(r'sin|forgiv|guilt|shame|return').hasMatch(needLower)),
    orElse: () => hamdOpenings[0],
  )!;

  final canonicalNamesList = buildCanonicalNamesPromptList();

  final response = await _callClaude(
    model: _reflectModel,
    systemPrompt: 'You are an Islamic scholar constructing a personal dua in classical Arabic following authentic prophetic etiquette (adab al-du\'a).\n\n'
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
        'Title | Arabic | Transliteration | Translation | Source',
    userMessage: 'I want to make dua for: $need',
    maxTokens: 2500,
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
    ('Opening Praise', '##S1_ARABIC##', '##S1_TRANSLIT##', '##S1_TRANSLATION##'),
    ('Salawat', '##S2_ARABIC##', '##S2_TRANSLIT##', '##S2_TRANSLATION##'),
    ('The Ask', '##S3_ARABIC##', '##S3_TRANSLIT##', '##S3_TRANSLATION##'),
    ('Closing', '##S4_ARABIC##', '##S4_TRANSLIT##', '##S4_TRANSLATION##'),
  ];

  final nextArabicMarkers = ['##S2_ARABIC##', '##S3_ARABIC##', '##S4_ARABIC##', '##NAMES_USED##'];

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
  final parsedNameMaps = namesBlock
      .split('\n')
      .where((l) => l.trim().isNotEmpty && l.contains('·'))
      .map((line) {
        final parts = line.split('·').map((s) => s.trim()).toList();
        return {
          'name': (parts.isNotEmpty ? parts[0] : '').replaceAll(RegExp(r'^[-\d.)\s]+'), '').trim(),
          'nameArabic': parts.length > 1 ? parts[1].trim() : '',
          'why': parts.length > 2 ? parts[2].trim() : '',
        };
      })
      .where((n) => (n['name'] as String).isNotEmpty)
      .toList();

  final validatedNames = filterValidNames(parsedNameMaps);
  final namesUsed = validatedNames
      .map((m) => BuiltDuaNameUsed(
            name: m['name'] as String,
            nameArabic: m['nameArabic'] as String,
            why: m['why'] as String? ?? '',
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
          title: (parts.isNotEmpty ? parts[0] : '').replaceAll(RegExp(r'^[-\d.)\s]+'), '').trim(),
          arabic: parts.length > 1 ? parts[1] : '',
          transliteration: parts.length > 2 ? parts[2] : '',
          translation: parts.length > 3 ? parts[3] : '',
          source: parts.length > 4 ? parts[4] : '',
        );
      })
      .where((d) => d.title.isNotEmpty && d.arabic.isNotEmpty)
      .toList();

  return BuiltDuaResponse(
    arabic: arabic,
    transliteration: transliteration,
    translation: translation,
    breakdown: breakdown,
    namesUsed: namesUsed,
    relatedDuas: relatedDuas,
  );
}

// ---------------------------------------------------------------------------
// Daily question response
// ---------------------------------------------------------------------------

class DailyReflectResponse {
  final String name;
  final String nameArabic;
  final String teaching;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;

  const DailyReflectResponse({
    required this.name,
    required this.nameArabic,
    required this.teaching,
    required this.duaArabic,
    required this.duaTransliteration,
    required this.duaTranslation,
  });
}

Future<DailyReflectResponse> getDailyResponse(String question, String answer) async {
  final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    return const DailyReflectResponse(
      name: 'Al-Wakeel',
      nameArabic: 'الْوَكِيلُ',
      teaching:
          'Allah, Al-Wakeel — the Disposer of Affairs, the Ultimate Trustee — '
          'holds what you cannot hold. When you entrust a matter to Him, it is '
          'not neglected; it is handled by the One whose planning never fails. '
          'Tawakkul is not passivity — it is acting with your hands while '
          'anchoring your heart in the only One who controls outcomes.',
      duaArabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      duaTransliteration: 'Hasbunallahu wa ni\'mal-Wakeel',
      duaTranslation:
          'Sufficient for us is Allah, and He is the best Disposer of affairs.',
    );
  }

  final teachings = getRelevantTeachings('$question $answer');
  final teachingContext = teachings
      .take(4)
      .map((t) =>
          '**${t.name} (${t.arabic})**\n'
          'Core teaching: ${t.coreTeaching}\n'
          'Dua: ${t.dua.arabic}\n'
          'Transliteration: ${t.dua.transliteration}\n'
          'Translation: ${t.dua.translation}')
      .join('\n\n---\n\n');

  final dailyCanonicalList = buildCanonicalNamesPromptList();

  final response = await _callClaude(
    model: _followUpModel,
    systemPrompt:
        'You are an Islamic learning tool. A person has answered a daily orientation question. '
        'Based on their answer, identify the single most fitting Name of Allah from the list below '
        'and write a short, grounded teaching.\n\n'
        '$teachingContext\n\n'
        'IMPORTANT — You MUST only use a Name from this canonical list of the 99 Names:\n'
        '$dailyCanonicalList\n\n'
        '---\n\n'
        'Instructions:\n'
        '1. Choose the single most relevant Name — it MUST be from the canonical list above.\n'
        '2. Write ONE paragraph (3-5 sentences) explaining what this Name means and how it speaks '
        'directly to what they have shared. Be direct and substantive — teach, not comfort. '
        'No terms of endearment.\n'
        '3. Use the exact dua provided for that Name.\n\n'
        'Respond with EXACTLY these markers:\n'
        '##NAME## (English · Arabic)\n'
        '##TEACHING## (one paragraph)\n'
        '##DUA_ARABIC##\n'
        '##DUA_TRANSLITERATION##\n'
        '##DUA_TRANSLATION##',
    userMessage: 'Question: $question\nAnswer: $answer',
    maxTokens: 600,
  );

  if (response == null) {
    return const DailyReflectResponse(
      name: 'Al-Wakeel',
      nameArabic: 'الْوَكِيلُ',
      teaching:
          'Allah, Al-Wakeel — the Disposer of Affairs, the Ultimate Trustee — '
          'holds what you cannot hold. When you entrust a matter to Him, it is '
          'not neglected; it is handled by the One whose planning never fails. '
          'Tawakkul is not passivity — it is acting with your hands while '
          'anchoring your heart in the only One who controls outcomes.',
      duaArabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      duaTransliteration: 'Hasbunallahu wa ni\'mal-Wakeel',
      duaTranslation:
          'Sufficient for us is Allah, and He is the best Disposer of affairs.',
    );
  }

  final text = _extractTextFromResponse(response);
  if (text == null) {
    return const DailyReflectResponse(
      name: 'Al-Wakeel',
      nameArabic: 'الْوَكِيلُ',
      teaching:
          'Allah, Al-Wakeel — the Disposer of Affairs, the Ultimate Trustee — '
          'holds what you cannot hold.',
      duaArabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      duaTransliteration: 'Hasbunallahu wa ni\'mal-Wakeel',
      duaTranslation:
          'Sufficient for us is Allah, and He is the best Disposer of affairs.',
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
    teaching: _parseSection(text, '##TEACHING##') ?? '',
    duaArabic: _parseSection(text, '##DUA_ARABIC##') ?? '',
    duaTransliteration: _parseSection(text, '##DUA_TRANSLITERATION##') ?? '',
    duaTranslation: _parseSection(text, '##DUA_TRANSLATION##') ?? '',
  );
}
