import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/bypass_flow_mixin.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const String _reflectionsKey = 'saved_reflections';

// P2-5: Length caps for user_reflections columns. Mirror the server-side
// CHECK constraints in `supabase/migrations/20260526000000_user_reflections_length_caps.sql`
// EXACTLY — both client and server count codepoints (Dart `String.length` /
// Postgres `length()`). The earlier draft used `bytes/2 runes` which
// over-truncated honest Arabic content; ENG-REVIEW Finding 1 corrected this.
// See `docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md` (P2-5).
const int _reframeMaxChars = 4096;
const int _storyMaxChars = 4096;
const int _reframePreviewMaxChars = 300;
const int _nameMaxChars = 200;
const int _nameArabicMaxChars = 200;
const int _duaSourceMaxChars = 200;
const int _duaArabicMaxChars = 1024;
const int _duaTransliterationMaxChars = 1024;
const int _duaTranslationMaxChars = 1024;
const int _userTextMaxChars = 2048;
const int _verseArabicMaxChars = 2048;
const int _verseTranslationMaxChars = 2048;
const int _verseReferenceMaxChars = 200;
const int _versesMaxCount = 8;
const int _relatedNamesMaxCount = 8;

// Beat-data clamps (decision 9A). Persistence keeps display text unclamped;
// these caps only bound what we write so a verbose model response can never make
// the `beat_data` CHECK throw and drop the whole save. Mirror the server CHECK
// in the beat_data migration EXACTLY.
const int _beatKeyMaxChars = 200;
const int _beatBodyMaxChars = 500;
const int _beatTitleMaxChars = 120;
const int _beatLineMaxChars = 500;
const int _beatSourceMaxChars = 200;
const int _beatTakeawayMaxChars = 200;
const int _storyBeatsMaxCount = 3;

// Journal-entry caps (Wave B). Mirror the server CHECK + trigger in
// `supabase/migrations/20260802030000_user_reflections_journal_entries.sql`
// EXACTLY, for the same reason the beat clamps do: a value the server rejects
// drops the WHOLE save, and the night's artifact is the thing we are trying to
// stop losing.
const int _azmMaxChars = 500;
const int _threadMaxCount = 20;
const int _threadTextMaxChars = 2048;
const int _threadAtMaxChars = 64;

/// `user_reflections.source` values — a closed set of two, matching the server
/// CHECK. Wire strings rather than an enum because they are both a column value
/// and a persisted prefs format: a value written by another build has to
/// degrade rather than fail a parse.
const String reflectionSourceReflect = 'reflect';

/// The nightly muḥāsabah. Exactly one row per user per local day, enforced by
/// the `uniq_muhasabah_per_local_day` partial unique index.
const String reflectionSourceMuhasabah = 'muhasabah';

/// Clamp a string to at most [maxChars] codepoints (Dart `String.length`).
/// Matches the server's Postgres `length()` CHECK which also counts codepoints.
/// Returns '' for null so the row always has explicit values (the schema
/// declares every text column NOT NULL).
String _clampText(String? value, int maxChars) {
  if (value == null) return '';
  if (value.length <= maxChars) return value;
  return value.substring(0, maxChars);
}

typedef ReflectFollowUpLoader = Future<List<ai.FollowUpQuestion>> Function(
  String userText,
);
typedef ReflectResponseLoader = Future<ai.ReflectResponse> Function(
    String text);
typedef ReflectNow = DateTime Function();
typedef ReflectIdFactory = String Function();

String _defaultReflectIdFactory() => _uuid.v4();

class ReflectDependencies {
  final ReflectFollowUpLoader getFollowUpQuestions;
  final ReflectResponseLoader reflect;
  final ReflectNow now;
  final ReflectIdFactory createId;

  const ReflectDependencies({
    required this.getFollowUpQuestions,
    required this.reflect,
    required this.now,
    required this.createId,
  });
}

const _defaultReflectDependencies = ReflectDependencies(
  getFollowUpQuestions: ai.getFollowUpQuestions,
  reflect: ai.reflectWithOpenAI,
  now: DateTime.now,
  createId: _defaultReflectIdFactory,
);

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum ReflectScreenState { input, followup, loading, result, offtopic }

enum ReflectStep { name, reflection, story, dua }

// ---------------------------------------------------------------------------
// Saved reflection model
// ---------------------------------------------------------------------------

/// One "add to tonight" append on a journal entry's [SavedReflection.thread].
///
/// Serialised identically into the prefs blob and the `thread` jsonb column —
/// one shape, so the two cannot drift. The server rejects any key outside
/// `{at, text}`, so [toJson] must never grow one silently.
@immutable
class ReflectionThreadEntry {
  const ReflectionThreadEntry({required this.at, required this.text});

  /// ISO-8601 instant the append was made, or `''` when unknown (the server
  /// treats `at` as optional).
  final String at;

  /// What the user added. Capped exactly like `user_text` — an append is the
  /// same kind of writing as the answer.
  final String text;

  /// Clamps at construction, so local state, the prefs blob and the row all
  /// see the same truncated value (the P2-5 REVIEW Finding 1 doctrine).
  factory ReflectionThreadEntry.clamped({
    required String at,
    required String text,
  }) =>
      ReflectionThreadEntry(
        at: _clampText(at, _threadAtMaxChars),
        text: _clampText(text, _threadTextMaxChars),
      );

  Map<String, dynamic> toJson() => {
        if (at.isNotEmpty) 'at': _clampText(at, _threadAtMaxChars),
        'text': _clampText(text, _threadTextMaxChars),
      };

  /// Defensive: one malformed element (a raw string, a null `text`, a number)
  /// from a corrupted cache or a hand-crafted row must not throw and wipe the
  /// whole journal cache. Returns null for anything unusable.
  static ReflectionThreadEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    if (text is! String || text.isEmpty) return null;
    final at = raw['at'];
    return ReflectionThreadEntry(
      at: at is String ? at : '',
      text: text,
    );
  }

  static List<ReflectionThreadEntry> parseList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map(ReflectionThreadEntry.tryParse)
        .whereType<ReflectionThreadEntry>()
        .take(_threadMaxCount)
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is ReflectionThreadEntry && other.at == at && other.text == text;

  @override
  int get hashCode => Object.hash(at, text);
}

class SavedReflection {
  final String id;
  final String date;
  final String userText;
  final String name;
  final String nameArabic;
  final String reframePreview;
  final String reframe;
  final String story;
  final List<SavedVerse> verses;
  final String duaArabic;
  final String duaTransliteration;
  final String duaTranslation;
  final String duaSource;
  final List<Map<String, String>> relatedNames;

  // ── Structured beats (source of truth when present) ──
  // reframe/story above are DERIVED (joined) legacy values kept for old clients
  // and previews; when these beat fields are populated they are authoritative
  // (decision 21A). Persisted as a single `beat_data` jsonb column / map — null
  // for legacy rows, which fall back to splitIntoBeats(reframe/story).
  final String reframeKey;
  final String reframeBody;
  final String storyTitle;
  final List<String> storyBeats;
  final String storySource;
  final String takeaway;

  // ── Journal entry (Wave B) ──
  // What kind of entry this is, which local day it belongs to, and the two
  // places the night can still grow after the reveal (Wave C).

  /// [reflectionSourceReflect] or [reflectionSourceMuhasabah]. Rows written
  /// before this shipped read back as `reflect` via the column default, so
  /// there is no backfill.
  final String source;

  /// The user's LOCAL calendar day (`YYYY-MM-DD`), or null for a Reflect entry.
  ///
  /// **Not derived from [date].** The streak, the launch gate and the reward
  /// ladder all key on a day boundary, and a timestamp disagrees with them near
  /// midnight — the bug class documented at `launch_gate_state.dart:14-22`. It
  /// comes from `resolveUserLocalDay()` and nothing else.
  final String? entryLocalDay;

  /// "Add to tonight" appends. Empty until Wave C writes the first one.
  final List<ReflectionThreadEntry> thread;

  /// One line of forward resolve captured at the end of the night. Empty when
  /// absent — stored as SQL NULL rather than `''`.
  final String azm;

  const SavedReflection({
    required this.id,
    required this.date,
    required this.userText,
    required this.name,
    required this.nameArabic,
    required this.reframePreview,
    this.reframe = '',
    this.story = '',
    this.verses = const [],
    this.duaArabic = '',
    this.duaTransliteration = '',
    this.duaTranslation = '',
    this.duaSource = '',
    this.relatedNames = const [],
    this.reframeKey = '',
    this.reframeBody = '',
    this.storyTitle = '',
    this.storyBeats = const [],
    this.storySource = '',
    this.takeaway = '',
    this.source = reflectionSourceReflect,
    this.entryLocalDay,
    this.thread = const [],
    this.azm = '',
  });

  /// True when this entry is the nightly muḥāsabah rather than a Reflect save.
  bool get isMuhasabah => source == reflectionSourceMuhasabah;

  /// True when this reflection carries structured beat data. When false,
  /// renderers fall back to `splitIntoBeats` over [reframe] / [story].
  bool get hasBeats =>
      reframeKey.isNotEmpty ||
      reframeBody.isNotEmpty ||
      storyBeats.isNotEmpty ||
      takeaway.isNotEmpty;

  /// The `beat_data` payload — `null` when there are no beats (legacy shape),
  /// so old rows stay `NULL` and take the fallback path. Clamped per decision
  /// 9A so a verbose response can never trip the server CHECK.
  Map<String, dynamic>? _beatData() {
    if (!hasBeats) return null;
    return {
      'reframeKey': _clampText(reframeKey, _beatKeyMaxChars),
      'reframeBody': _clampText(reframeBody, _beatBodyMaxChars),
      'storyTitle': _clampText(storyTitle, _beatTitleMaxChars),
      'storyBeats': storyBeats
          .take(_storyBeatsMaxCount)
          .map((b) => _clampText(b, _beatLineMaxChars))
          .toList(),
      'storySource': _clampText(storySource, _beatSourceMaxChars),
      'takeaway': _clampText(takeaway, _beatTakeawayMaxChars),
    };
  }

  static SavedReflection _withBeatData(
    SavedReflection base,
    Object? raw,
  ) {
    if (raw is! Map) return base;
    final m = Map<String, dynamic>.from(raw);
    return base.copyWithBeats(
      reframeKey: m['reframeKey'] as String? ?? '',
      reframeBody: m['reframeBody'] as String? ?? '',
      storyTitle: m['storyTitle'] as String? ?? '',
      // Defensive: one malformed element (null / non-string from a corrupted
      // cache or legacy row) must not throw and wipe the whole journal cache.
      storyBeats: (m['storyBeats'] as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      storySource: m['storySource'] as String? ?? '',
      takeaway: m['takeaway'] as String? ?? '',
    );
  }

  SavedReflection copyWithBeats({
    required String reframeKey,
    required String reframeBody,
    required String storyTitle,
    required List<String> storyBeats,
    required String storySource,
    required String takeaway,
  }) =>
      SavedReflection(
        id: id,
        date: date,
        userText: userText,
        name: name,
        nameArabic: nameArabic,
        reframePreview: reframePreview,
        reframe: reframe,
        story: story,
        verses: verses,
        duaArabic: duaArabic,
        duaTransliteration: duaTransliteration,
        duaTranslation: duaTranslation,
        duaSource: duaSource,
        relatedNames: relatedNames,
        reframeKey: reframeKey,
        reframeBody: reframeBody,
        storyTitle: storyTitle,
        storyBeats: storyBeats,
        storySource: storySource,
        takeaway: takeaway,
        // Carried, not defaulted. This constructor rebuilds the whole object,
        // so omitting a field here silently drops it on EVERY row that has
        // beat_data — which is every muḥāsabah row.
        source: source,
        entryLocalDay: entryLocalDay,
        thread: thread,
        azm: azm,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'userText': userText,
        'name': name,
        'nameArabic': nameArabic,
        'reframePreview': reframePreview,
        'reframe': reframe,
        'story': story,
        'verses': verses.map((v) => v.toJson()).toList(),
        'duaArabic': duaArabic,
        'duaTransliteration': duaTransliteration,
        'duaTranslation': duaTranslation,
        'duaSource': duaSource,
        'relatedNames': relatedNames,
        'beatData': _beatData(),
        // Journal entry (Wave B). Kept in lockstep with `toSupabaseRow` and
        // both parsers below — a field present in one and missing from another
        // is a silent data-loss bug, not a cosmetic inconsistency.
        'source': source,
        'entryLocalDay': entryLocalDay,
        'thread': _threadJson(),
        'azm': azm,
      };

  /// The `thread` payload, count- and length-capped to what the server accepts.
  List<Map<String, dynamic>> _threadJson() =>
      thread.take(_threadMaxCount).map((e) => e.toJson()).toList();

  factory SavedReflection.fromJson(Map<String, dynamic> json) {
    final base = SavedReflection(
      id: json['id'] as String,
      date: json['date'] as String,
      userText: json['userText'] as String,
      name: json['name'] as String,
      nameArabic: json['nameArabic'] as String,
      reframePreview: json['reframePreview'] as String,
      reframe: json['reframe'] as String? ?? '',
      story: json['story'] as String? ?? '',
      verses: (json['verses'] as List<dynamic>?)
              ?.map((e) => ReflectVerse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      duaArabic: json['duaArabic'] as String? ?? '',
      duaTransliteration: json['duaTransliteration'] as String? ?? '',
      duaTranslation: json['duaTranslation'] as String? ?? '',
      duaSource: json['duaSource'] as String? ?? '',
      relatedNames: (json['relatedNames'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      // A cache blob written before Wave B has none of these keys — it reads
      // back as an ordinary Reflect entry, which is exactly what it is.
      source: json['source'] as String? ?? reflectionSourceReflect,
      entryLocalDay: json['entryLocalDay'] as String?,
      thread: ReflectionThreadEntry.parseList(json['thread']),
      azm: json['azm'] as String? ?? '',
    );
    return _withBeatData(base, json['beatData']);
  }

  /// Convert to Supabase row format.
  ///
  /// P2-5: Every text field is clamped via [_clampText] to match the server
  /// CHECKs in `20260526000000_user_reflections_length_caps.sql`. Arrays
  /// (`verses`, `related_names`) are truncated to the server-side cap of 8.
  /// Per-verse fields are also clamped so each element passes the shape
  /// trigger. See `docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md`.
  Map<String, dynamic> toSupabaseRow(String userId) => {
        'id': id,
        'user_id': userId,
        'saved_at': date,
        'user_text': _clampText(userText, _userTextMaxChars),
        'name': _clampText(name, _nameMaxChars),
        'name_arabic': _clampText(nameArabic, _nameArabicMaxChars),
        'reframe_preview':
            _clampText(reframePreview, _reframePreviewMaxChars),
        'reframe': _clampText(reframe, _reframeMaxChars),
        'story': _clampText(story, _storyMaxChars),
        'verses': verses.take(_versesMaxCount).map((v) => {
              'arabic': _clampText(v.arabic, _verseArabicMaxChars),
              'translation':
                  _clampText(v.translation, _verseTranslationMaxChars),
              'reference': _clampText(v.reference, _verseReferenceMaxChars),
            }).toList(),
        'dua_arabic': _clampText(duaArabic, _duaArabicMaxChars),
        'dua_transliteration':
            _clampText(duaTransliteration, _duaTransliterationMaxChars),
        'dua_translation':
            _clampText(duaTranslation, _duaTranslationMaxChars),
        'dua_source': _clampText(duaSource, _duaSourceMaxChars),
        'related_names':
            relatedNames.take(_relatedNamesMaxCount).toList(),
        'beat_data': _beatData(),
        // Journal entry (Wave B). `entry_local_day` is a `date` column, so the
        // wire value is `YYYY-MM-DD` and never a timestamp. `azm` goes as SQL
        // NULL when absent rather than '' — an empty resolve is no resolve.
        'source': source,
        'entry_local_day': entryLocalDay,
        'thread': _threadJson(),
        'azm': azm.isEmpty ? null : _clampText(azm, _azmMaxChars),
      };

  /// Create from a Supabase row.
  factory SavedReflection.fromSupabaseRow(Map<String, dynamic> row) {
    final base = SavedReflection(
      id: row['id'] as String? ?? _uuid.v4(),
      date: row['saved_at'] as String? ?? '',
      userText: row['user_text'] as String? ?? '',
      name: row['name'] as String? ?? '',
      nameArabic: row['name_arabic'] as String? ?? '',
      reframePreview: row['reframe_preview'] as String? ?? '',
      reframe: row['reframe'] as String? ?? '',
      story: row['story'] as String? ?? '',
      verses: (row['verses'] as List<dynamic>?)
              ?.map((e) => ReflectVerse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      duaArabic: row['dua_arabic'] as String? ?? '',
      duaTransliteration: row['dua_transliteration'] as String? ?? '',
      duaTranslation: row['dua_translation'] as String? ?? '',
      duaSource: row['dua_source'] as String? ?? '',
      relatedNames: (row['related_names'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      // Rows that predate the migration come back with `source` populated by
      // the column default, so this coalesce only covers a payload from a
      // server that has not run it yet.
      source: row['source'] as String? ?? reflectionSourceReflect,
      entryLocalDay: _dateOnly(row['entry_local_day']),
      thread: ReflectionThreadEntry.parseList(row['thread']),
      azm: row['azm'] as String? ?? '',
    );
    return _withBeatData(base, row['beat_data']);
  }

  /// `YYYY-MM-DD` from whatever PostgREST hands back for a `date` column —
  /// normally the bare date string, but a timestamp-shaped value is truncated
  /// rather than stored whole, so a round-trip can never widen a day into an
  /// instant.
  static String? _dateOnly(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return raw.length > 10 ? raw.substring(0, 10) : raw;
  }
}

// ---------------------------------------------------------------------------
// Building + persisting a row — the ONE path that owns `user_reflections`
// ---------------------------------------------------------------------------

/// Builds a clamped [SavedReflection] from an AI [response].
///
/// The single place a row's shape is derived from a model response. Both
/// writers come through here — the Reflect save below and the nightly muḥāsabah
/// in `daily_loop_provider.completeDeeper()` — so the clamps (and therefore
/// what the server will accept) cannot drift apart between them.
///
/// [response] is nullable because the deck path has no AI response at all: the
/// pre-authored beats ARE the content, and the night still deserves an entry
/// carrying the user's words, the Name and the duʿā.
SavedReflection buildSavedReflection({
  required String userText,
  required ai.ReflectResponse? response,
  String? id,
  String? date,
  String? name,
  String? nameArabic,
  String source = reflectionSourceReflect,
  String? entryLocalDay,
  List<ReflectionThreadEntry> thread = const [],
  String azm = '',
  DateTime Function()? now,
}) {
  final reframe = response?.reframe ?? '';
  final preview =
      reframe.length > 150 ? '${reframe.substring(0, 150)}...' : reframe;

  // P2-5 (REVIEW Finding 1): clamp at CONSTRUCTION time so local state, the
  // prefs blob and the share-card renderer all see the same truncated values as
  // the server row. Clamping only at `toSupabaseRow` left the share-card
  // surface attackable on the owner's own device.
  return SavedReflection(
    id: id ?? _uuid.v4(),
    date: (date ?? (now ?? DateTime.now)().toIso8601String()),
    userText: _clampText(userText, _userTextMaxChars),
    name: _clampText(name ?? response?.name, _nameMaxChars),
    nameArabic: _clampText(nameArabic ?? response?.nameArabic, _nameArabicMaxChars),
    reframePreview: _clampText(preview, _reframePreviewMaxChars),
    reframe: _clampText(reframe, _reframeMaxChars),
    story: _clampText(response?.story, _storyMaxChars),
    verses: (response?.verses ?? const <ReflectVerse>[])
        .take(_versesMaxCount)
        .map((v) => ReflectVerse(
              arabic: _clampText(v.arabic, _verseArabicMaxChars),
              translation: _clampText(v.translation, _verseTranslationMaxChars),
              reference: _clampText(v.reference, _verseReferenceMaxChars),
            ))
        .toList(),
    duaArabic: _clampText(response?.duaArabic, _duaArabicMaxChars),
    duaTransliteration:
        _clampText(response?.duaTransliteration, _duaTransliterationMaxChars),
    duaTranslation:
        _clampText(response?.duaTranslation, _duaTranslationMaxChars),
    duaSource: _clampText(response?.duaSource, _duaSourceMaxChars),
    relatedNames: (response?.relatedNames ?? const <ai.RelatedName>[])
        .take(_relatedNamesMaxCount)
        .map((r) => {
              'name': _clampText(r.name, _nameMaxChars),
              'nameArabic': _clampText(r.nameArabic, _nameArabicMaxChars),
            })
        .toList(),
    reframeKey: _clampText(response?.reframeKey, _beatKeyMaxChars),
    reframeBody: _clampText(response?.reframeBody, _beatBodyMaxChars),
    storyTitle: _clampText(response?.storyTitle, _beatTitleMaxChars),
    storyBeats: (response?.storyBeats ?? const <String>[])
        .take(_storyBeatsMaxCount)
        .map((b) => _clampText(b, _beatLineMaxChars))
        .toList(),
    storySource: _clampText(response?.storySource, _beatSourceMaxChars),
    takeaway: _clampText(response?.takeaway, _beatTakeawayMaxChars),
    source: source,
    entryLocalDay: entryLocalDay,
    thread: thread.take(_threadMaxCount).toList(),
    azm: _clampText(azm, _azmMaxChars),
  );
}

/// Persists the night's muḥāsabah as a journal entry: one server row, one cache
/// entry, one per local day.
///
/// Returns true when a row was written. Returns false — without throwing — when
/// the entry already exists for [SavedReflection.entryLocalDay] or when the
/// server refuses the write. **Callers must treat false as survivable.** By the
/// time this runs the streak, the quests and the Noor award are already
/// committed; a lost row is recoverable, a lost streak is not.
///
/// Idempotency has two layers, and both are load-bearing:
///   * the local cache check below, which also covers a signed-out user (whose
///     write never reaches a server that could refuse it);
///   * `uniq_muhasabah_per_local_day`, which is the real guarantee — a plain
///     INSERT (never an upsert) means a replay is refused rather than allowed
///     to overwrite what the user already wrote tonight.
Future<bool> saveMuhasabahReflection(SavedReflection reflection) async {
  final cached = await _readCachedReflections();
  final localDay = reflection.entryLocalDay;
  final alreadyWritten = cached.any((r) =>
      r.id == reflection.id ||
      (r.isMuhasabah && localDay != null && r.entryLocalDay == localDay));
  if (alreadyWritten) {
    debugPrint('[reflect] muhasabah entry for $localDay already exists — '
        'skipping (this is a no-op, not an overwrite)');
    return false;
  }

  // Supabase FIRST, exactly like `_saveReflection`: only commit locally on a
  // CONFIRMED server write, so a row rejected by a CHECK, RLS or the unique
  // index never shows up locally and then vanishes on the next sync.
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    final ok = await supabaseSyncService.insertRow(
      'user_reflections',
      reflection.toSupabaseRow(userId),
    );
    if (!ok) {
      debugPrint('[reflect] muhasabah entry rejected by the server — '
          'completion stands, the row is not cached');
      return false;
    }
  }

  await _prependToReflectionCache(reflection);
  for (final notifier in _liveReflectNotifiers.toList()) {
    notifier.adoptExternalReflection(reflection);
  }
  return true;
}

Future<List<SavedReflection>> _readCachedReflections() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(supabaseSyncService.scopedKey(_reflectionsKey));
    if (json == null) return const [];
    return (jsonDecode(json) as List)
        .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}

Future<void> _prependToReflectionCache(SavedReflection reflection) async {
  // Read-modify-write rather than a write from some in-memory list: this runs
  // from the daily loop, which has no view of the reflect notifier's state.
  final current = await _readCachedReflections();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_reflectionsKey),
    jsonEncode([reflection, ...current].map((r) => r.toJson()).toList()),
  );
}

/// Live [ReflectNotifier] instances, so a row written OUT OF BAND (the nightly
/// muḥāsabah, from `daily_loop_provider`) lands in the in-memory list too.
///
/// Without this the notifier's next `_persistReflections` — triggered by any
/// ordinary Reflect save or delete later in the same session — writes its own
/// stale list over the cache and drops tonight's entry from the journal until
/// the next full sync rehydrates it.
final Set<ReflectNotifier> _liveReflectNotifiers = <ReflectNotifier>{};

// ---------------------------------------------------------------------------
// Supabase sync
// ---------------------------------------------------------------------------

Future<void> migrateReflectionCachesForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _reflectionsKey);
}

Future<void> seedReflectionsToSupabaseFromLocalCache() async {
  await supabaseSyncService.seedListFromLocalCache(
    table: 'user_reflections',
    cacheKey: _reflectionsKey,
    toRows: (localItems, userId) => localItems
        .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>)
            .toSupabaseRow(userId))
        .toList(),
  );
}

Future<void> hydrateReflectionCacheFromRows(
  List<Map<String, dynamic>> remoteRows,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_reflectionsKey),
    jsonEncode(
      remoteRows
          .map((r) => SavedReflection.fromSupabaseRow(r).toJson())
          .toList(),
    ),
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ReflectState {
  final ReflectScreenState screenState;
  final String userText;
  final ai.ReflectResponse? result;
  final String? error;
  final ReflectStep currentStep;
  final List<ai.FollowUpQuestion> followUpQuestions;
  final List<String> followUpAnswers;
  final int currentFollowUpIndex;
  final Set<String> selectedEmotions;
  final List<SavedReflection> savedReflections;

  /// Set when the user attempted to reflect but the gating layer blocked the
  /// call. Reason determines which paywall sheet the screen shows
  /// (warmup-exhausted vs daily-cap). Cleared by [ReflectNotifier.dismissGate].
  final GateResult? gateResult;

  /// Non-null on the one-shot transition moment when this reflect call
  /// decremented the warmup counter from 1 to 0. Screen reads this to fire
  /// [WarmupExhaustedSheet] exactly once, then calls
  /// [ReflectNotifier.dismissWarmupExhausted] to clear.
  final GatedFeature? warmupJustExhausted;

  const ReflectState({
    this.screenState = ReflectScreenState.input,
    this.userText = '',
    this.result,
    this.error,
    this.currentStep = ReflectStep.name,
    this.followUpQuestions = const [],
    this.followUpAnswers = const [],
    this.currentFollowUpIndex = 0,
    this.selectedEmotions = const {},
    this.savedReflections = const [],
    this.gateResult,
    this.warmupJustExhausted,
  });

  ReflectState copyWith({
    ReflectScreenState? screenState,
    String? userText,
    ai.ReflectResponse? result,
    String? error,
    ReflectStep? currentStep,
    List<ai.FollowUpQuestion>? followUpQuestions,
    List<String>? followUpAnswers,
    int? currentFollowUpIndex,
    Set<String>? selectedEmotions,
    List<SavedReflection>? savedReflections,
    GateResult? gateResult,
    GatedFeature? warmupJustExhausted,
    bool clearResult = false,
    bool clearError = false,
    bool clearGateResult = false,
    bool clearWarmupJustExhausted = false,
  }) {
    return ReflectState(
      screenState: screenState ?? this.screenState,
      userText: userText ?? this.userText,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      currentStep: currentStep ?? this.currentStep,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
      currentFollowUpIndex: currentFollowUpIndex ?? this.currentFollowUpIndex,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
      savedReflections: savedReflections ?? this.savedReflections,
      gateResult: clearGateResult ? null : (gateResult ?? this.gateResult),
      warmupJustExhausted: clearWarmupJustExhausted
          ? null
          : (warmupJustExhausted ?? this.warmupJustExhausted),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ReflectNotifier extends StateNotifier<ReflectState>
    with BypassFlowMixin<ReflectState> {
  ReflectNotifier({
    ReflectDependencies? dependencies,
    @visibleForTesting bool loadOnInit = true,
  })  : _dependencies = dependencies ?? _defaultReflectDependencies,
        super(const ReflectState()) {
    _liveReflectNotifiers.add(this);
    if (loadOnInit) {
      _loadSavedReflections();
    }
  }

  @override
  GatedFeature get bypassFeature => GatedFeature.reflect;

  /// Static analytics hook (mirrors [DailyLoopNotifier.onAnalyticsEvent]). No
  /// Riverpod access here; main.dart wires this so a saved reflection can emit
  /// `journal_entry_created`. Tests leave it null.
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  final ReflectDependencies _dependencies;
  bool _consumeFreeUsageOnSuccess = false;

  /// Captured during [submit] alongside `_consumeFreeUsageOnSuccess` so the
  /// follow-on [GatingService.markUsed] call can skip a redundant
  /// `PurchaseService().isPremium()` round-trip (RevenueCat method-channel
  /// hop). Cleared in the same paths that clear `_consumeFreeUsageOnSuccess`.
  bool? _premiumAtSubmit;

  /// W6 Wave D: set true only by [submit] (the free/gated path), right after
  /// the gate passes — mirrors `_consumeFreeUsageOnSuccess`'s pattern
  /// exactly, and for the same reason: [submitWithBypass] /
  /// [submitWithFirstBypass] explicitly set it false so a bypassed call can
  /// never emit [AnalyticsEvents.reflectCompleted] without a preceding
  /// [AnalyticsEvents.reflectStarted]. Consumed (reset to false) the moment
  /// `_reflect` gets a response, so the pair is strictly 1:1 per gated
  /// submit — a gated submit fires neither event, and a failed AI call
  /// leaves it armed-but-unconsumed (fires `started` only).
  bool _reflectFunnelArmed = false;

  void setUserText(String text) {
    state = state.copyWith(userText: text);
  }

  void toggleEmotion(String emotion) {
    final updated = Set<String>.from(state.selectedEmotions);
    if (updated.contains(emotion)) {
      updated.remove(emotion);
    } else {
      updated.add(emotion);
    }
    state = state.copyWith(selectedEmotions: updated);
  }

  /// Clears the gate-blocked flag after the paywall sheet is dismissed.
  void dismissGate() {
    state = state.copyWith(clearGateResult: true);
  }

  /// Clears the warmup-just-exhausted signal after the WarmupExhaustedSheet
  /// has been shown and dismissed.
  void dismissWarmupExhausted() {
    state = state.copyWith(clearWarmupJustExhausted: true);
  }

  /// Submit user text. Checks the gating layer first; if blocked, exposes the
  /// [GateResult] on state for the screen to render the right paywall sheet.
  Future<void> submit() async {
    if (bypassInFlight ||
        state.screenState == ReflectScreenState.loading) {
      return;
    }
    markBypassInFlight();
    try {
      // Resolve premium status ONCE for this submit cycle. Both canUse and
      // the follow-on markUsed need it; without the cache each one fires its
      // own RevenueCat method-channel hop.
      final premium = await PurchaseService().isPremium();
      final gate = await GatingService()
          .canUse(GatedFeature.reflect, isPremiumHint: premium);
      if (!gate.allowed) {
        state = state.copyWith(gateResult: gate);
        return;
      }
      _premiumAtSubmit = premium;
      _consumeFreeUsageOnSuccess = true;
      _reflectFunnelArmed = true;
      try {
        onAnalyticsEvent?.call(AnalyticsEvents.reflectStarted, {});
      } catch (_) {}
      await _doSubmit();
    } finally {
      clearBypassInFlight();
    }
  }

  /// Submit user text using an AI bypass: spend tokens to get one extra
  /// reflection past the daily cap. Reserves on the server first (atomic
  /// token debit + bypass-counter increment), then runs the same AI flow
  /// as [submit]. On AI success the reservation is committed; on AI failure
  /// the reservation is cancelled and tokens refunded.
  ///
  /// Returns silently when the reserve RPC rejects (insufficient tokens,
  /// bypass cap reached, premium short-circuit). The screen-level toast
  /// is the caller's responsibility — they already know the local state.
  Future<void> submitWithBypass() async {
    if (bypassInFlight ||
        state.screenState == ReflectScreenState.loading) {
      return;
    }
    try {
      final reservation = await reserveActiveBypass();
      // P1-B: dispose may have fired while we were awaiting. State writes on
      // a disposed notifier throw. Check `mounted` before any state mutation
      // beyond this point. The mixin's dispose path already handles
      // cancelling a reservation that lands after teardown.
      if (!mounted) return;
      if (reservation == null) {
        // Sheet caller stays open / re-renders with stale-state copy.
        state = state.copyWith(error: 'Bypass unavailable. Try again.');
        return;
      }
      trackActiveBypassReservation(reservation.reservationId);
      // The bypass path doesn't count against the warmup/daily counters via
      // markUsed — the reserve RPC already incremented the daily-uses row
      // server-side, and the warmup counter is unrelated (bypass is a
      // post-warmup mechanic). Skip both markers.
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = false;
      // W6 Wave D: bypass reservations are a different gate than `submit`'s
      // GatingService.canUse — reflect_started/_completed track only the
      // free/gated path, so this must stay unarmed (see field docstring).
      _reflectFunnelArmed = false;
      await _doSubmit();
    } finally {
      clearBypassInFlight();
    }
  }

  /// Day-1 freebie variant (PR 4 of plan 2026-05-23, EXP-2). Calls
  /// [GatingService.claimFirstBypass] — atomic on the server with no token
  /// at stake. On success, runs the same AI submit flow as a normal
  /// bypass; on rejection, surfaces an error and lets the sheet re-render.
  ///
  /// Different from [submitWithBypass]: no reservation tracking. The
  /// freebie has no cancel/commit lifecycle — it's a one-shot atomic
  /// counter bump. If the AI call later fails, the user has consumed
  /// their Day-1 freebie and falls back to paid bypass on retry.
  /// (Intentional — see plan §EXP-2 "product discovery, not unlimited
  /// Day-1 access".)
  Future<void> submitWithFirstBypass() async {
    if (bypassInFlight ||
        state.screenState == ReflectScreenState.loading) {
      return;
    }
    markBypassInFlight();
    try {
      final claimed =
          await GatingService().claimFirstBypass(GatedFeature.reflect);
      if (!claimed) {
        state = state.copyWith(
          error: 'Freebie unavailable. Try again.',
        );
        return;
      }
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = false;
      // W6 Wave D: same reasoning as submitWithBypass — the Day-1 freebie
      // claim is not `submit`'s gate, so this must stay unarmed.
      _reflectFunnelArmed = false;
      await _doSubmit();
    } finally {
      clearBypassInFlight();
    }
  }

  Future<void> _doSubmit() async {
    try {
      state = state.copyWith(
          screenState: ReflectScreenState.loading, clearError: true);

      final questions =
          await _dependencies.getFollowUpQuestions(state.userText);

      if (questions.isNotEmpty) {
        state = state.copyWith(
          screenState: ReflectScreenState.followup,
          followUpQuestions: questions,
          followUpAnswers: [],
          currentFollowUpIndex: 0,
        );
      } else {
        await _reflect(_buildCombinedText([]));
      }
    } catch (e) {
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = null;
      await cancelActiveBypassIfAny();
      state = state.copyWith(
        screenState: ReflectScreenState.input,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Record a follow-up answer. If last question, triggers reflect.
  Future<void> answerFollowUp(String answer) async {
    final updatedAnswers = [...state.followUpAnswers, answer];
    final isLast =
        state.currentFollowUpIndex >= state.followUpQuestions.length - 1;

    state = state.copyWith(followUpAnswers: updatedAnswers);

    if (isLast) {
      await _reflect(_buildCombinedText(updatedAnswers));
    } else {
      state =
          state.copyWith(currentFollowUpIndex: state.currentFollowUpIndex + 1);
    }
  }

  /// Skip follow-ups and reflect with just the original text.
  Future<void> skipFollowUps() async {
    await _reflect(_buildCombinedText([]));
  }

  /// Advance result step: name → reflection → story → dua.
  Future<void> continueStep() async {
    const nextStep = {
      ReflectStep.name: ReflectStep.reflection,
      ReflectStep.reflection: ReflectStep.story,
      ReflectStep.story: ReflectStep.dua,
    };
    final next = nextStep[state.currentStep];
    if (next != null) {
      state = state.copyWith(currentStep: next);
    }
  }

  /// Go back one result step: dua → story → reflection → name.
  void previousStep() {
    const prevStep = {
      ReflectStep.reflection: ReflectStep.name,
      ReflectStep.story: ReflectStep.reflection,
      ReflectStep.dua: ReflectStep.story,
    };
    final prev = prevStep[state.currentStep];
    if (prev != null) {
      state = state.copyWith(currentStep: prev);
    }
  }

  /// Delete a saved reflection.
  ///
  /// Optimistic + reconciling: removes locally first, then attempts the server
  /// delete. If the server call throws (airplane / RLS / 5xx), restores the
  /// local list and re-persists, then surfaces an error string the UI can
  /// show as a snackbar. Regression for §9 J-E4 (2026-04-26).
  Future<void> deleteReflection(String id) async {
    final previous = List<SavedReflection>.from(state.savedReflections);
    final updated = previous.where((r) => r.id != id).toList();
    state = state.copyWith(savedReflections: updated, clearError: true);
    await _persistReflections(updated);

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;

    try {
      final deleted =
          await supabaseSyncService.deleteRow('user_reflections', 'id', id);
      // deleteRow swallows exceptions and returns false rather than throwing,
      // so a failed server delete must be handled explicitly. Otherwise the
      // local removal silently diverges from the server and the "deleted" row
      // resurrects on the next batch sync (hydrateReflectionCacheFromRows
      // overwrites the local cache with server rows).
      if (!deleted) {
        throw Exception('deleteRow(user_reflections) returned false');
      }
    } catch (_) {
      state = state.copyWith(
        savedReflections: previous,
        error: "Couldn't delete the reflection. Please try again.",
      );
      await _persistReflections(previous);
    }
  }

  @visibleForTesting
  void debugSeedReflections(List<SavedReflection> reflections) {
    state = state.copyWith(savedReflections: reflections);
  }

  @override
  void dispose() {
    // P0-4 + P1-B: cancel any in-flight bypass reservation (or chain a
    // cancel on the still-pending reserve future) so the user's tokens are
    // refunded immediately instead of waiting up to 15 min for the
    // server-side orphan cron. Mixin handles both the post-assignment
    // (P0-4) and pre-assignment (P1-B) cases.
    disposeBypassFlow();
    _liveReflectNotifiers.remove(this);
    super.dispose();
  }

  /// Adopts a row written OUT OF BAND (the nightly muḥāsabah — see
  /// [saveMuhasabahReflection]). Cache-only writers call this so this
  /// notifier's in-memory list does not go stale and clobber the cache on its
  /// next persist. Deliberately does NOT re-persist: the caller already wrote
  /// the cache, and this must not become a second writer of the same blob.
  void adoptExternalReflection(SavedReflection reflection) {
    if (state.savedReflections.any((r) => r.id == reflection.id)) return;
    state = state.copyWith(
      savedReflections: [reflection, ...state.savedReflections],
    );
  }

  /// Reset to input state (preserves saved reflections).
  void reset() {
    _consumeFreeUsageOnSuccess = false;
    _premiumAtSubmit = null;
    _reflectFunnelArmed = false;
    // If a reset lands while a bypass is mid-flight, fire-and-forget the
    // cancel so the user's tokens don't sit reserved until the orphan cron
    // rescues. We intentionally don't await — reset() is sync-shaped for
    // UI callers.
    cancelActiveBypassIfAny().ignore();
    state = ReflectState(savedReflections: state.savedReflections);
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _reflect(String text) async {
    try {
      state = state.copyWith(
          screenState: ReflectScreenState.loading, clearError: true);

      // TODO: Build ReflectContext from journal/anchors when those are implemented
      final response = await _dependencies.reflect(text);

      // W6 Wave D: fires once per gated submit, off-topic or not — carrying
      // `off_topic` keeps the classifier's cost on Reflect comparable with
      // the daily loop's. An exception from `_dependencies.reflect` above
      // skips this entirely (caught below), which is what makes a failed AI
      // call distinguishable from an abandonment: `started` fired, `completed`
      // did not. Consumed here (armed reset) so a retry needs a fresh submit.
      if (_reflectFunnelArmed) {
        _reflectFunnelArmed = false;
        try {
          onAnalyticsEvent?.call(AnalyticsEvents.reflectCompleted, {
            AnalyticsEvents.propOffTopic: response.offTopic,
          });
        } catch (_) {}
      }

      if (response.offTopic) {
        _consumeFreeUsageOnSuccess = false;
        _premiumAtSubmit = null;
        // Off-topic is treated as "no value delivered" — cancel any active
        // bypass so the user gets their tokens back. Mirrors the existing
        // free-usage no-consume behaviour just above.
        await cancelActiveBypassIfAny();
        state = state.copyWith(
          screenState: ReflectScreenState.offtopic,
          result: response,
        );
      } else {
        state = state.copyWith(
          screenState: ReflectScreenState.result,
          result: response,
          currentStep: ReflectStep.name,
        );
        if (_consumeFreeUsageOnSuccess) {
          final outcome = await GatingService().markUsed(
            GatedFeature.reflect,
            isPremiumHint: _premiumAtSubmit,
          );
          _consumeFreeUsageOnSuccess = false;
          _premiumAtSubmit = null;
          if (outcome == UsageOutcome.warmupJustExhausted) {
            state =
                state.copyWith(warmupJustExhausted: GatedFeature.reflect);
          }
        }
        await commitActiveBypassIfAny();
        // Track streak (XP for Reflect is intentionally zero — only Muhasabah,
        // quests, and streak milestones grant XP).
        await markActiveToday();
        await logActivity();
        // Auto-save the reflection
        await _saveReflection(response);
      }
    } catch (e) {
      _consumeFreeUsageOnSuccess = false;
      _premiumAtSubmit = null;
      await cancelActiveBypassIfAny();
      state = state.copyWith(
        screenState: ReflectScreenState.input,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  String _buildCombinedText(List<String> answers) {
    final buffer = StringBuffer(state.userText);
    if (state.selectedEmotions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Emotions: ${state.selectedEmotions.join(', ')}');
    }
    for (var i = 0; i < answers.length; i++) {
      if (i < state.followUpQuestions.length) {
        buffer
          ..writeln()
          ..writeln('Q: ${state.followUpQuestions[i].question}')
          ..writeln('A: ${answers[i]}');
      }
    }
    return buffer.toString();
  }

  /// Saves the reflection. There is deliberately no free-tier row cap here.
  ///
  /// A 5-entry lifetime save cap lived at the top of this method from May 2026
  /// until 2026-08-02. It was written against the old generation model and was
  /// never revisited when W5 replaced that model with a weekly allowance pool.
  /// Because `markUsed` spends the weekly use *before* this method runs, the
  /// cap only ever destroyed output the user had already paid for. The weekly
  /// pool is now the single gate on this behaviour; keeping what it produces
  /// is unlimited. See design §9A (2026-08-02).
  Future<void> _saveReflection(ai.ReflectResponse response) async {
    // Shape + clamps live in [buildSavedReflection], shared with the nightly
    // muḥāsabah write, so the two writers of this table cannot drift apart.
    // `source` stays [reflectionSourceReflect] and `entryLocalDay` stays null:
    // a Reflect save is not a night, is unlimited per day, and must never be
    // caught by the muḥāsabah unique index.
    final reflection = buildSavedReflection(
      id: _dependencies.createId(),
      date: _dependencies.now().toIso8601String(),
      userText: state.userText,
      response: response,
    );

    // P2-5 (ENG-REVIEW Finding 2): write to Supabase FIRST. With the new
    // length + shape CHECKs from migration 20260526000000, a malformed
    // (or attacker-crafted) AI response can be rejected by the server. If
    // we updated local state first, the UI would render a "saved"
    // reflection that doesn't exist server-side and a future sync would
    // silently drop it. Reordering means a rejected insert throws and the
    // local list stays clean. The reflection is already clamped above
    // (REVIEW Finding 1), so both writes see identical truncated values.
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      // Only commit to local state on a CONFIRMED server write. insertRow
      // swallows errors and returns false; without this guard a server-rejected
      // row (shape/length CHECK, RLS, transient 5xx) would still show as
      // "saved" locally and then be silently dropped by a later sync — the exact
      // phantom-entry the Supabase-first ordering is meant to prevent.
      final ok = await supabaseSyncService.insertRow(
        'user_reflections',
        reflection.toSupabaseRow(userId),
      );
      if (!ok) {
        state = state.copyWith(
          error: "Couldn't save your reflection. Please try again.",
        );
        return;
      }
    }

    final updated = [reflection, ...state.savedReflections];
    state = state.copyWith(savedReflections: updated);
    await _persistReflections(updated);

    onAnalyticsEvent?.call(AnalyticsEvents.journalEntryCreated, {
      AnalyticsEvents.propEntryType: AnalyticsEvents.entryTypeReflection,
      AnalyticsEvents.propAuto: false,
    });
  }

  Future<void> _loadSavedReflections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = await supabaseSyncService.migrateLegacyStringCache(
        prefs,
        _reflectionsKey,
      );
      if (json != null) {
        final list = (jsonDecode(json) as List)
            .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(savedReflections: list);
      }
    } catch (_) {}
  }

  Future<void> _persistReflections(List<SavedReflection> reflections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_reflectionsKey),
      jsonEncode(reflections.map((r) => r.toJson()).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final reflectProvider =
    StateNotifierProvider<ReflectNotifier, ReflectState>((ref) {
  return ReflectNotifier();
});
