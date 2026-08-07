import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
// A deck night's content. Model-only (`name_story_deck.dart` imports nothing),
// so this cannot introduce a cycle. See [buildSavedReflection].
import 'package:sakina/models/name_story_deck.dart';
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

/// Byte budget for the WHOLE `thread` payload — the one server cap on this
/// column that counts bytes rather than codepoints.
///
/// The trigger's backstop is `pg_column_size(new.thread) > 49152`. Every other
/// cap (`<= 20` elements, `<= 2048` chars of `text`, `<= 64` chars of `at`)
/// counts codepoints, and the clamps above mirror those exactly. This one did
/// not have a client-side mirror at all, and the gap is not academic: Arabic is
/// two UTF-8 bytes per codepoint, so twenty appends at the client's OWN
/// per-element cap is ~80 KB of text — every per-element clamp reports the row
/// as valid and the server rejects the whole write. (Wave B review, finding 7;
/// inert then because `thread` was always `[]`, live now that Wave C fills it.)
///
/// 40960 rather than 49152 because what is measured here is the JSON **text**
/// encoding while the server measures the jsonb **binary** datum. The two are
/// close but not identical (jsonb adds a 4-byte JEntry per element and per key,
/// and drops the quotes), so the 8 KB gap is the margin that keeps an append the
/// client accepted from being an append the server refuses. It is also exactly
/// the migration's own stated legitimate worst case — *"20 appends x 2048 chars
/// is ~40KB"*.
const int _threadMaxBytes = 40960;

/// How many entries the device keeps — in the prefs blob and in the notifier's
/// in-memory list (Wave D, D5).
///
/// The local cache is **one JSON string** under a single SharedPreferences key:
/// every save re-encodes and rewrites the whole list, and every launch decodes
/// it on the platform thread before the Journal can paint. That was harmless
/// while a free user could hold five entries for life and a premium user rarely
/// passed a few dozen. Wave A removed the cap that kept it small, and Wave B
/// added a row a night — a daily journaler now produces ~365 a year, so an
/// uncapped blob grows without bound and the cost lands on app start.
///
/// 500 ≈ sixteen months of nightly entries. Beyond it the OLDEST entries fall
/// out of the device cache; the server keeps every row and a full sync
/// rehydrates the newest 500 again. The one honest caveat: a user who never
/// signs in has no server copy, so for them this is deletion rather than
/// eviction — which is why the number is generous rather than tight.
const int maxCachedReflections = 500;

/// Newest-first, then truncated to [maxCachedReflections].
///
/// Sorting first is the load-bearing half. Truncating an unsorted list drops
/// whatever happens to sit at the end, which for `hydrateReflectionCacheFromRows`
/// is whatever order PostgREST returned — i.e. it could throw away this week
/// and keep last year.
@visibleForTesting
List<SavedReflection> capReflections(List<SavedReflection> reflections) {
  if (reflections.length <= maxCachedReflections) return reflections;
  final sorted = [...reflections]..sort((a, b) {
      final da = DateTime.tryParse(a.date);
      final db = DateTime.tryParse(b.date);
      // An unparseable date sorts last rather than throwing — a corrupt row
      // must not be able to decide which good ones survive.
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
  return sorted.take(maxCachedReflections).toList();
}

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

typedef ReflectResponseLoader = Future<ai.ReflectResponse> Function(
    String text);
typedef ReflectNow = DateTime Function();
typedef ReflectIdFactory = String Function();

String _defaultReflectIdFactory() => _uuid.v4();

class ReflectDependencies {
  final ReflectResponseLoader reflect;
  final ReflectNow now;
  final ReflectIdFactory createId;

  const ReflectDependencies({
    required this.reflect,
    required this.now,
    required this.createId,
  });
}

const _defaultReflectDependencies = ReflectDependencies(
  reflect: ai.reflectWithOpenAI,
  now: DateTime.now,
  createId: _defaultReflectIdFactory,
);

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// The composer's four states.
///
/// `followup` is gone (2026-08-07). It named an interstitial that asked the
/// user two or three AI-generated questions between their sentence and the
/// reveal — a shape that predates `BeatRevealFlow`, cost an extra OpenAI
/// round-trip on the way in, and had no renderer left once the Reflect tab was
/// folded into the Journal. `ReflectStep` went with it for the same reason: the
/// beat flow owns its own progression now.
enum ReflectScreenState { input, loading, result, offtopic }

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

  /// The one place this object is rebuilt.
  ///
  /// Every named argument merges with `?? this.x`, so a field this method does
  /// not mention survives by construction. That property is the point: the
  /// previous shape ([copyWithBeats]) enumerated all twenty-odd fields
  /// positionally, and forgetting one there silently dropped it on every row
  /// carrying `beat_data` — i.e. on every muḥāsabah row. Wave B caught that by
  /// hand; this makes the class of bug unreachable.
  ///
  /// [entryLocalDay] cannot be set back to null through here. Nothing needs to:
  /// a Reflect entry is created without one and a muḥāsabah entry never loses
  /// the night it belongs to.
  SavedReflection copyWith({
    String? id,
    String? date,
    String? userText,
    String? name,
    String? nameArabic,
    String? reframePreview,
    String? reframe,
    String? story,
    List<SavedVerse>? verses,
    String? duaArabic,
    String? duaTransliteration,
    String? duaTranslation,
    String? duaSource,
    List<Map<String, String>>? relatedNames,
    String? reframeKey,
    String? reframeBody,
    String? storyTitle,
    List<String>? storyBeats,
    String? storySource,
    String? takeaway,
    String? source,
    String? entryLocalDay,
    List<ReflectionThreadEntry>? thread,
    String? azm,
  }) =>
      SavedReflection(
        id: id ?? this.id,
        date: date ?? this.date,
        userText: userText ?? this.userText,
        name: name ?? this.name,
        nameArabic: nameArabic ?? this.nameArabic,
        reframePreview: reframePreview ?? this.reframePreview,
        reframe: reframe ?? this.reframe,
        story: story ?? this.story,
        verses: verses ?? this.verses,
        duaArabic: duaArabic ?? this.duaArabic,
        duaTransliteration: duaTransliteration ?? this.duaTransliteration,
        duaTranslation: duaTranslation ?? this.duaTranslation,
        duaSource: duaSource ?? this.duaSource,
        relatedNames: relatedNames ?? this.relatedNames,
        reframeKey: reframeKey ?? this.reframeKey,
        reframeBody: reframeBody ?? this.reframeBody,
        storyTitle: storyTitle ?? this.storyTitle,
        storyBeats: storyBeats ?? this.storyBeats,
        storySource: storySource ?? this.storySource,
        takeaway: takeaway ?? this.takeaway,
        source: source ?? this.source,
        entryLocalDay: entryLocalDay ?? this.entryLocalDay,
        thread: thread ?? this.thread,
        azm: azm ?? this.azm,
      );

  SavedReflection copyWithBeats({
    required String reframeKey,
    required String reframeBody,
    required String storyTitle,
    required List<String> storyBeats,
    required String storySource,
    required String takeaway,
  }) =>
      copyWith(
        reframeKey: reframeKey,
        reframeBody: reframeBody,
        storyTitle: storyTitle,
        storyBeats: storyBeats,
        storySource: storySource,
        takeaway: takeaway,
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
///
/// [deck] is how that content actually arrives (2026-08-07). Until this
/// parameter existed the sentence above was aspirational: a deck night reached
/// here with `response == null` and nothing else, so every field below
/// collapsed to `''` and the row went out carrying the user's words and the
/// Name and *nothing else* — `beat_data` null, no verses, no duʿā. The night
/// was complete and correct; only its artifact was empty, and the archive
/// re-read it as a two-screen story: a cover and a Name.
///
/// The mapping mirrors `buildBeatScreensFromDeck` so a re-read lands on the
/// same beats the reader was shown live, in the same order. It is deliberately
/// lossy where the row shape cannot hold the deck's structure — a row has one
/// `takeaway` and one reframe pair, a deck may carry several of each — and the
/// flattening below states which one wins in each case.
SavedReflection buildSavedReflection({
  required String userText,
  required ai.ReflectResponse? response,
  NameStoryDeck? deck,
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
  // ── The deck path's content, flattened into the row's shape ──
  //
  // ONLY when there is no response. A response and a deck never coexist on a
  // real night (`startDeeper` short-circuits the AI prefetch the moment it has
  // a deck), and if they ever did, the response is the thing the reader was
  // actually shown. This is also the guard that keeps the older regression
  // fixed: a stale response from a PREVIOUS night must never be written under
  // tonight's Name, and reading the deck instead of the response cannot
  // reintroduce that.
  final List<NameStoryBeat> deckBeats = response == null
      ? (deck?.beats ?? const <NameStoryBeat>[])
      : const <NameStoryBeat>[];

  List<NameStoryBeat> beatsOfKind(Set<String> kinds) =>
      deckBeats.where((b) => kinds.contains(b.kind)).toList();

  String firstPrimaryOf(String kind) {
    for (final b in deckBeats) {
      if (b.kind == kind) return b.primary;
    }
    return '';
  }

  final deckStory = beatsOfKind({'story'});
  final deckVerses = beatsOfKind({'verse', 'comfort_verse'});
  final deckDuas = beatsOfKind({'dua'});
  final deckTakeaways = beatsOfKind({'takeaway'});

  // The pair-synergy beat is a takeaway wearing a `synergy` label, and it is
  // about the OTHER Name of the pair — so a real takeaway outranks it for the
  // single slot the row has. Falls back to it only when it is the only one.
  final deckTakeaway = deckTakeaways
      .where((b) => !b.isPairSynergy)
      .followedBy(deckTakeaways)
      .map((b) => b.primary)
      .firstWhere((p) => p.isNotEmpty, orElse: () => '');

  // `bridge` renders as the key line and `recognition` as the reframe body —
  // the same two slots, in the same order, that the deck flow draws them in.
  final deckKeyLine = firstPrimaryOf('bridge');
  final deckReframeBody = firstPrimaryOf('recognition');

  final reframe = response?.reframe ??
      [deckKeyLine, deckReframeBody].where((s) => s.isNotEmpty).join('\n\n');
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
    // The prose column, for the legacy `splitIntoBeats` fallback and the
    // export. On a deck night the structured `storyBeats` below are what a
    // re-read actually renders; this is the same lines joined.
    story: _clampText(
      response?.story ?? deckStory.map((b) => b.primary).join('\n\n'),
      _storyMaxChars,
    ),
    verses: (response?.verses ??
            deckVerses.map((b) => ReflectVerse(
                  arabic: b.arabic,
                  // A deck verse carries its translation on `primary` and its
                  // citation on `source` — the slots `buildBeatScreensFromDeck`
                  // reads them from.
                  translation: b.primary,
                  reference: b.source,
                )))
        .take(_versesMaxCount)
        .map((v) => ReflectVerse(
              arabic: _clampText(v.arabic, _verseArabicMaxChars),
              translation: _clampText(v.translation, _verseTranslationMaxChars),
              reference: _clampText(v.reference, _verseReferenceMaxChars),
            ))
        .toList(),
    duaArabic: _clampText(
        response?.duaArabic ?? deckDuas.firstOrNull?.arabic,
        _duaArabicMaxChars),
    duaTransliteration: _clampText(
        response?.duaTransliteration ?? deckDuas.firstOrNull?.transliteration,
        _duaTransliterationMaxChars),
    duaTranslation: _clampText(
        response?.duaTranslation ?? deckDuas.firstOrNull?.primary,
        _duaTranslationMaxChars),
    duaSource: _clampText(
        response?.duaSource ?? deckDuas.firstOrNull?.source,
        _duaSourceMaxChars),
    relatedNames: (response?.relatedNames ?? const <ai.RelatedName>[])
        .take(_relatedNamesMaxCount)
        .map((r) => {
              'name': _clampText(r.name, _nameMaxChars),
              'nameArabic': _clampText(r.nameArabic, _nameArabicMaxChars),
            })
        .toList(),
    reframeKey:
        _clampText(response?.reframeKey ?? deckKeyLine, _beatKeyMaxChars),
    reframeBody:
        _clampText(response?.reframeBody ?? deckReframeBody, _beatBodyMaxChars),
    // The title is drawn on the FIRST story screen and the source under the
    // LAST — see `buildBeatScreensFromReflection`. Taking them from the same
    // two beats keeps a re-read identical to the live reading.
    storyTitle: _clampText(
        response?.storyTitle ?? deckStory.firstOrNull?.label,
        _beatTitleMaxChars),
    storyBeats: (response?.storyBeats ?? deckStory.map((b) => b.primary))
        .take(_storyBeatsMaxCount)
        .map((b) => _clampText(b, _beatLineMaxChars))
        .toList(),
    storySource: _clampText(
        response?.storySource ?? deckStory.lastOrNull?.source,
        _beatSourceMaxChars),
    takeaway:
        _clampText(response?.takeaway ?? deckTakeaway, _beatTakeawayMaxChars),
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

  // Wave H — the night is a journal entry, so it emits the journal's event.
  //
  // Here and not in `daily_loop_provider.completeDeeper()` on purpose: this
  // function is the one path that owns the muḥāsabah row, and only it knows
  // that a row was actually WRITTEN. The two silent returns above — the day
  // already had its entry, and the server refused the insert — are exactly the
  // cases an emit at the call site would have counted as journal entries that
  // do not exist.
  //
  // `auto: true`, for the same reason the auto-saved built duʿā is: the user
  // wrote the words, but nothing asked them to save. The deliberate-save slice
  // (`auto: false`) stays what it has always been.
  //
  // Guarded, because a throwing hook here would be indistinguishable from a
  // failed write to the caller — it would return an exception instead of
  // `true`, and `_persistMuhasabahEntry`'s catch would then skip the state
  // write that puts tonight's entry on the completion screen.
  try {
    ReflectNotifier.onAnalyticsEvent?.call(AnalyticsEvents.journalEntryCreated, {
      AnalyticsEvents.propEntryType: AnalyticsEvents.entryTypeReflection,
      AnalyticsEvents.propAuto: true,
      AnalyticsEvents.propSource: AnalyticsEvents.journalSourceMuhasabah,
    });
  } catch (_) {
    // Telemetry never costs the row.
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
    jsonEncode(
      capReflections([reflection, ...current]).map((r) => r.toJson()).toList(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Wave C — the night stays open until the local day rolls over
// ---------------------------------------------------------------------------
//
// Everything below is a PURE TEXT WRITE against a row that already exists. No
// path here reveals a Name, marks a streak, claims the reward ladder, unseals
// the queue, engages a card or consumes an allowance — those fire exactly once
// per night, at first submit, and the `!state.checkinDone` gate in
// `muhasabah_screen._showsQuestion` is what keeps them there. Nothing in this
// section may ever grow a reason to touch the economy; if it does, it belongs
// on the submit path instead.

/// The muḥāsabah entry for [entryLocalDay], or null.
///
/// Reads the local cache rather than the server: it is authoritative for
/// everything written on this device, it is what `sync_all_user_data()`
/// rehydrates into on a fresh install, and it works with no connection — which
/// matters, because "add to tonight" is the one journaling affordance a user is
/// most likely to reach for in bed with the radio off.
Future<SavedReflection?> readMuhasabahEntryForDay(String entryLocalDay) async {
  for (final r in await _readCachedReflections()) {
    if (r.isMuhasabah && r.entryLocalDay == entryLocalDay) return r;
  }
  return null;
}

/// Appends one line to [entryLocalDay]'s entry (C1).
///
/// Returns the updated entry, or null when there is nothing to append to (no
/// entry for that day — including the case where the local day has rolled over
/// and tonight has not started yet), when [text] is blank, when the day's
/// twenty appends are used up, or when the server refuses the write.
///
/// **The day is the caller's, resolved at call time.** An append made after
/// midnight belongs to the new day's row, and if that day has no row yet the
/// append is refused rather than being filed against yesterday.
Future<SavedReflection?> appendToMuhasabahThread({
  required String entryLocalDay,
  required String text,
  DateTime Function()? now,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  final entry = await readMuhasabahEntryForDay(entryLocalDay);
  if (entry == null) return null;

  final fitted = fitThreadAppend(
    entry.thread,
    ReflectionThreadEntry.clamped(
      at: (now ?? DateTime.now)().toUtc().toIso8601String(),
      text: trimmed,
    ),
  );
  if (fitted == null) return null;

  return _persistUpdatedReflection(
    entry.copyWith(thread: [...entry.thread, fitted]),
  );
}

/// Sets the night's one line of forward resolve (C4).
///
/// Returns the updated entry, the unchanged entry when the text is already what
/// is stored, or null when there is no entry for that day or the server refuses.
Future<SavedReflection?> setMuhasabahAzm({
  required String entryLocalDay,
  required String azm,
}) async {
  final entry = await readMuhasabahEntryForDay(entryLocalDay);
  if (entry == null) return null;
  final next = _clampText(azm.trim(), _azmMaxChars);
  if (next == entry.azm) return entry;
  return _persistUpdatedReflection(entry.copyWith(azm: next));
}

/// Rewrites the user's own words on a saved entry (2026-08-06).
///
/// **Only [SavedReflection.userText], and only ever that.** The Name, the
/// reframe, the story, the verses and the duʿā are what the app said back on the
/// night in question, and an edit must not rewrite history it did not author.
/// The reframe therefore stays the response to what was originally written —
/// which is the honest record, even when the two no longer read as a matched
/// pair.
///
/// **It does not re-open the night.** Like every other function in this section
/// it is a pure text write against a row that already exists: no reveal, no
/// streak, no reward ladder, no allowance. That is also why editing is allowed
/// on an entry of ANY age while "add to tonight" stops at the local-day
/// rollover — an append is a new line the night did not have, and a night that
/// has closed does not get new lines; a correction is not a new line.
///
/// Returns the updated entry, the entry unchanged when [text] is already what is
/// stored, or null when the entry is not in the cache, when [text] is blank (an
/// entry cannot be edited into having no words — that is what delete is for), or
/// when the server refuses the write.
Future<SavedReflection?> editReflectionText({
  required String id,
  required String text,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  SavedReflection? entry;
  for (final r in await _readCachedReflections()) {
    if (r.id == id) {
      entry = r;
      break;
    }
  }
  if (entry == null) return null;

  // Clamped here as well as in `toSupabaseRow`, per the P2-5 REVIEW Finding 1
  // doctrine: local state, the prefs blob and the row must all see the same
  // truncated value, so what stays on screen is exactly what was stored.
  final next = _clampText(trimmed, _userTextMaxChars);
  if (next == entry.userText) return entry;
  return _persistUpdatedReflection(entry.copyWith(userText: next));
}

/// The append that will actually fit, or null when the entry has no room left.
///
/// Enforces BOTH caps the server does on a whole `thread`: the element count,
/// and the total byte size. The text is truncated rather than the append
/// refused, because the clamp-at-construction doctrine (P2-5 REVIEW Finding 1)
/// is that the user sees on screen exactly what was stored — a silently dropped
/// append is the one outcome a journaling feature cannot have.
@visibleForTesting
ReflectionThreadEntry? fitThreadAppend(
  List<ReflectionThreadEntry> existing,
  ReflectionThreadEntry candidate,
) {
  if (existing.length >= _threadMaxCount) return null;
  var text = candidate.text;
  while (text.isNotEmpty) {
    final trial = ReflectionThreadEntry(at: candidate.at, text: text);
    final size = threadJsonBytes([...existing, trial]);
    if (size <= _threadMaxBytes) return trial;
    // Every codepoint is at least one UTF-8 byte, so dropping `over` characters
    // always removes at least `over` bytes. That makes the loop monotone and
    // guarantees it terminates.
    final over = size - _threadMaxBytes;
    var cut = text.length - over.clamp(1, text.length);
    // Back off one more code unit when the cut lands between a surrogate pair.
    // `substring` counts UTF-16 code units, so an emoji or any astral character
    // straddling the boundary is severed into a lone surrogate — and `utf8.encode`
    // does NOT throw on that, it silently emits U+FFFD. The user would get their
    // last character replaced by a replacement glyph, saved, with no error
    // anywhere. Splitting a grapheme cluster is merely ugly; splitting a
    // surrogate pair corrupts, so only the second case is corrected here.
    if (cut > 0 && cut < text.length) {
      final lead = text.codeUnitAt(cut - 1);
      final trail = text.codeUnitAt(cut);
      final splitsPair = lead >= 0xD800 &&
          lead <= 0xDBFF &&
          trail >= 0xDC00 &&
          trail <= 0xDFFF;
      if (splitsPair) cut -= 1;
    }
    text = text.substring(0, cut);
  }
  return null;
}

/// The UTF-8 size of the `thread` payload as it goes on the wire.
@visibleForTesting
int threadJsonBytes(List<ReflectionThreadEntry> thread) =>
    utf8.encode(jsonEncode(thread.map((e) => e.toJson()).toList())).length;

/// The user's own entry from 30 / 90 / 365 nights before [entryLocalDay] —
/// nearest available, at most one (C3).
///
/// Exact anchor days, not a window: the pattern's whole force is *this is what
/// you wrote on this same date*, and a fuzzy match turns it into "here is an old
/// entry". Returns null when no anchor exists, which is the correct experience
/// for a new user — it arrives as a surprise on day 31.
Future<SavedReflection?> findMuhasabahTimeMachineAnchor(
  String entryLocalDay, {
  List<int> offsets = muhasabahTimeMachineOffsets,
}) async =>
    selectTimeMachineAnchor(
      await _readCachedReflections(),
      entryLocalDay,
      offsets: offsets,
    );

/// The anchor RULE, over an already-loaded list.
///
/// [findMuhasabahTimeMachineAnchor] is this function plus a read of the prefs
/// cache, and Wave E's journal-side "On This Night" card is this function plus a
/// read of `ReflectState.savedReflections` — which is the same data, hydrated
/// into memory. Splitting the rule out is the whole point: two surfaces now
/// resurface "your entry from a month / a year ago", and a second hand-written
/// lookup would be free to drift on the exact-day question, on the empty-text
/// filter, or on the nearest-first ordering. There is one rule and both callers
/// are it.
SavedReflection? selectTimeMachineAnchor(
  List<SavedReflection> entries,
  String entryLocalDay, {
  List<int> offsets = muhasabahTimeMachineOffsets,
}) {
  final today = parseLocalDayString(entryLocalDay);
  if (today == null) return null;
  for (final offset in offsets) {
    final target = formatLocalDay(today.subtract(Duration(days: offset)));
    for (final r in entries) {
      if (r.isMuhasabah &&
          r.entryLocalDay == target &&
          r.userText.trim().isNotEmpty) {
        return r;
      }
    }
  }
  return null;
}

/// Nearest first. 30 before 90 before 365, so a daily journaler meets the
/// month before the year.
const List<int> muhasabahTimeMachineOffsets = [30, 90, 365];

/// The most recent ʿazm written on a night STRICTLY BEFORE [entryLocalDay] and
/// within [withinDays] (C4's resurfacing half).
///
/// Bounded deliberately. A resolve is a promise about the next day or two; a
/// five-week-old one handed back as tonight's opening line is not a reminder,
/// it is an accusation. Seven days is the widest window in which "last time"
/// still reads as continuity.
Future<String?> readRecentAzmBefore(
  String entryLocalDay, {
  int withinDays = 7,
}) async {
  final today = parseLocalDayString(entryLocalDay);
  if (today == null) return null;
  String? bestDay;
  String? bestAzm;
  for (final r in await _readCachedReflections()) {
    final day = r.entryLocalDay;
    if (!r.isMuhasabah || r.azm.trim().isEmpty || day == null) continue;
    final parsed = parseLocalDayString(day);
    if (parsed == null || !parsed.isBefore(today)) continue;
    if (today.difference(parsed).inDays > withinDays) continue;
    if (bestDay == null || day.compareTo(bestDay) > 0) {
      bestDay = day;
      bestAzm = r.azm.trim();
    }
  }
  return bestAzm;
}

/// `YYYY-MM-DD` → a UTC-midnight [DateTime], or null.
///
/// UTC and hand-parsed rather than `DateTime.parse`, which yields a LOCAL
/// midnight: subtracting 30 days from a local midnight across a DST boundary
/// lands at 23:00 the day before and silently shifts every anchor by one.
DateTime? parseLocalDayString(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime.utc(year, month, day);
}

/// The inverse of [parseLocalDayString].
String formatLocalDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Server first, then cache — the same order [saveMuhasabahReflection] uses and
/// for the same reason: a value the server refuses must never be shown locally
/// and then vanish on the next sync.
///
/// An UPSERT on the row's own primary key, not the blind INSERT the first write
/// uses. The distinction matters: the first write must be refused on a replay
/// (that is what protects tonight's words from being overwritten), while an
/// append is by definition an edit of a row this device already owns.
Future<SavedReflection?> _persistUpdatedReflection(
    SavedReflection updated) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    final ok = await supabaseSyncService.upsertRawRow(
      'user_reflections',
      updated.toSupabaseRow(userId),
      onConflict: 'id',
    );
    if (!ok) {
      debugPrint('[reflect] journal entry update rejected by the server — '
          'nothing cached, the entry stands as it was');
      return null;
    }
  }
  await _replaceInReflectionCache(updated);
  for (final notifier in _liveReflectNotifiers.toList()) {
    notifier.adoptExternalReflection(updated);
  }
  return updated;
}

Future<void> _replaceInReflectionCache(SavedReflection updated) async {
  // Read-modify-write, like [_prependToReflectionCache]: this runs from the
  // daily loop, which has no view of the reflect notifier's in-memory list.
  final current = await _readCachedReflections();
  final next = [
    for (final r in current)
      if (r.id == updated.id) updated else r,
  ];
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_reflectionsKey),
    jsonEncode(next.map((r) => r.toJson()).toList()),
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
      capReflections(
        remoteRows.map(SavedReflection.fromSupabaseRow).toList(),
      ).map((r) => r.toJson()).toList(),
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
    this.savedReflections = const [],
    this.gateResult,
    this.warmupJustExhausted,
  });

  ReflectState copyWith({
    ReflectScreenState? screenState,
    String? userText,
    ai.ReflectResponse? result,
    String? error,
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

      await _reflect(state.userText);
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
    // The local write is a failure mode too, and it used to be the only one
    // here that was silent — see [_tryPersistReflections]. A refused cache
    // write is treated exactly like a refused server delete: roll the list
    // back, say so, and leave the row alone on both sides.
    if (!await _tryPersistReflections(updated)) {
      await _rollBackDelete(
        previous,
        "Couldn't delete the reflection. Please try again.",
      );
      return;
    }

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
      await _rollBackDelete(
        previous,
        "Couldn't delete the reflection. Please try again.",
      );
    }
  }

  /// Destroys every saved reflection — the D2 "delete all" control.
  ///
  /// D2 made server-side storage of confessional text conditional on this
  /// existing (plan §B4: *"the decision was 'store it *with* the controls', not
  /// 'store it'"*). Shipping the storage without it is the half-decision this
  /// method closes.
  ///
  /// Mirrors [deleteReflection]'s shape exactly, and for the same reason:
  /// optimistic local clear, then the server delete, then a **full rollback**
  /// if the server refused. `deleteRow` swallows its exception and returns
  /// false, so a silent failure would otherwise leave the user believing their
  /// journal was destroyed while every row survives and resurrects on the next
  /// `hydrateReflectionCacheFromRows`. On a destroy-everything action that
  /// divergence is the worst possible outcome, so it is handled explicitly.
  ///
  /// One `deleteRow` call, not N: it filters on `user_id`, and RLS scopes the
  /// statement to the caller's own rows.
  Future<bool> deleteAllReflections() async {
    final previous = List<SavedReflection>.from(state.savedReflections);
    if (previous.isEmpty) return true;

    state = state.copyWith(savedReflections: const [], clearError: true);
    // **This guard matters most here.** On a single delete an unreported cache
    // failure loses one row; on delete-all it tells someone their entire
    // journal is gone while every entry is still on disk and on the server,
    // ready to reappear at the next launch. Refusing before the server call
    // means nothing has been destroyed when the message says nothing was.
    if (!await _tryPersistReflections(const [])) {
      await _rollBackDelete(
        previous,
        "Couldn't delete your journal. Please try again.",
      );
      return false;
    }

    final userId = supabaseSyncService.currentUserId;
    // Signed out: the local cache IS the journal, so clearing it is the whole
    // job and there is nothing on a server to refuse.
    if (userId == null) return true;

    try {
      final deleted = await supabaseSyncService.deleteRow(
          'user_reflections', 'user_id', userId);
      if (!deleted) {
        throw Exception('deleteRow(user_reflections by user_id) returned false');
      }
      return true;
    } catch (_) {
      await _rollBackDelete(
        previous,
        "Couldn't delete your journal. Please try again.",
      );
      return false;
    }
  }

  /// Puts [previous] back on screen and on disk, and says why.
  ///
  /// Shared by both delete paths so the two cannot drift on what a failure
  /// looks like. The re-persist is best-effort by design: the in-memory list is
  /// what the user is looking at and it has already been restored, and on the
  /// one path that reaches here because the CACHE refused, disk was never
  /// changed — it still holds [previous], so a second refusal costs nothing.
  Future<void> _rollBackDelete(
    List<SavedReflection> previous,
    String message,
  ) async {
    state = state.copyWith(savedReflections: previous, error: message);
    await _tryPersistReflections(previous);
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
  ///
  /// An id already in the list is REPLACED in place rather than ignored, which
  /// is what makes Wave C's appends and ʿazm visible in an already-open Journal:
  /// those writes edit a row this notifier may already be holding, and the early
  /// return that used to sit here would have left the pre-append copy on screen
  /// until the next full sync.
  void adoptExternalReflection(SavedReflection reflection) {
    final index =
        state.savedReflections.indexWhere((r) => r.id == reflection.id);
    if (index >= 0) {
      final next = List<SavedReflection>.from(state.savedReflections);
      next[index] = reflection;
      state = state.copyWith(savedReflections: next);
      return;
    }
    state = state.copyWith(
      savedReflections:
          capReflections([reflection, ...state.savedReflections]),
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

    final updated = capReflections([reflection, ...state.savedReflections]);
    state = state.copyWith(savedReflections: updated);
    await _persistReflections(updated);

    onAnalyticsEvent?.call(AnalyticsEvents.journalEntryCreated, {
      AnalyticsEvents.propEntryType: AnalyticsEvents.entryTypeReflection,
      AnalyticsEvents.propAuto: false,
      // Wave H. The property, not a second event — see [journalSourceReflect].
      // Hard-coded rather than read off `reflection.source` because this method
      // is the Reflect writer by construction: it passes no `source` to
      // `buildSavedReflection`, so the row is `reflect` or the default changed
      // underneath it, and in the second case the event should be wrong loudly
      // rather than follow it quietly.
      AnalyticsEvents.propSource: AnalyticsEvents.journalSourceReflect,
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
        final list = capReflections((jsonDecode(json) as List)
            .map((e) => SavedReflection.fromJson(e as Map<String, dynamic>))
            .toList());
        state = state.copyWith(savedReflections: list);
      }
    } catch (_) {}
  }

  /// [_persistReflections], with the throw turned into a `false`.
  ///
  /// `SharedPreferences.getInstance()` and `setString` can both fail — a
  /// missing platform channel, a full or read-only disk, a decode error in the
  /// plugin. Every OTHER failure on the delete paths was already handled
  /// explicitly; this one was not, so a cache write that threw left the list
  /// cleared in memory, unchanged on disk, and NO error anywhere. The user saw
  /// their journal vanish, was told nothing, and found it all back at the next
  /// launch.
  ///
  /// Returns true when the blob was written.
  Future<bool> _tryPersistReflections(List<SavedReflection> reflections) async {
    try {
      await _persistReflections(reflections);
      return true;
    } catch (e) {
      debugPrint('[reflect] reflection cache write failed: $e');
      return false;
    }
  }

  Future<void> _persistReflections(List<SavedReflection> reflections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_reflectionsKey),
      jsonEncode(capReflections(reflections).map((r) => r.toJson()).toList()),
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
