import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

/// Scoped-prefs JSON mirror of the user's `user_name_queue` rows.
///
/// Same idiom as `starter_name_cache.dart`: a local mirror so a surface can make
/// a decision without waiting on a Supabase round trip, written whenever the
/// authoritative read succeeds.
///
/// **The cache is ADVISORY.** It may report that a sealed row exists; it may
/// never authorise an unseal. Only `unseal_next_name` moves a position, and it
/// re-derives the user-local day and the 20-hour floor server-side, so a user who
/// edits prefs or walks their clock gains nothing. Treat every value here as
/// possibly stale.
///
/// It is also the **cohort probe**: the presence of cached rows is what
/// `daily_usage_service` uses to decide whether the discover cap key is
/// user-local or UTC (§6a — the gate is rows, not a flag).
const String nameQueuePrefBaseKey = 'name_queue_rows';

/// Reads the mirrored rows, position-ordered. Empty when no user is signed in,
/// nothing was cached, or the cached blob is corrupt.
///
/// Captures the uid before awaiting `getInstance()` and re-checks after, so a
/// sign-out racing this read can't return another user's queue.
Future<List<NameQueueRow>> readCachedNameQueue() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return const [];
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return const [];
  final raw = prefs.getString('$nameQueuePrefBaseKey:$userId');
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final rows = decoded
        .whereType<Map>()
        .map((row) => NameQueueRow.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false)
      ..sort((a, b) => a.position.compareTo(b.position));
    return rows;
  } catch (e) {
    // Visible in dev so a shape change surfaces, but never fatal — a corrupt
    // mirror degrades to "no cached queue", which is the legacy path.
    debugPrint('[name_queue_cache] corrupt cache dropped: $e');
    return const [];
  }
}

/// True when the signed-in user has at least one mirrored queue row — i.e. they
/// are in the reel cohort. Cheap (one prefs read) and safe to call on any path.
Future<bool> hasCachedNameQueue() async =>
    (await readCachedNameQueue()).isNotEmpty;

/// Mirrors [rows] to scoped prefs. Called after a successful authoritative read
/// (`NameQueueService.queue()`) or a successful `unsealNext()`.
///
/// Writes the **same key names** `NameQueueRow.fromJson` reads (`position`,
/// `name_id`, `unsealed_at`), so the encode and decode sides stay
/// type-symmetric — the failure mode a cosmetics cache regression already paid
/// for once.
Future<void> writeCachedNameQueue(List<NameQueueRow> rows) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return;
  final encoded = jsonEncode([
    for (final row in rows)
      <String, dynamic>{
        'position': row.position,
        'name_id': row.nameId,
        'unsealed_at': row.unsealedAt?.toUtc().toIso8601String(),
      },
  ]);
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return;
  await prefs.setString('$nameQueuePrefBaseKey:$userId', encoded);
}

/// Merges a single freshly-unsealed row into the mirror, leaving every other
/// position as cached. Used after `unsealNext()`, which returns one row rather
/// than the whole queue.
///
/// A row the mirror has never seen is appended, so a user whose first
/// authoritative read has not landed yet still ends up in the cohort.
Future<void> mergeCachedNameQueueRow(NameQueueRow row) async {
  final existing = await readCachedNameQueue();
  final merged = <int, NameQueueRow>{
    for (final cached in existing) cached.position: cached,
  };
  merged[row.position] = row;
  final rows = merged.values.toList(growable: false)
    ..sort((a, b) => a.position.compareTo(b.position));
  await writeCachedNameQueue(rows);
}

/// Drops the mirror. Sign-out / account-reset hygiene; also used by tests.
Future<void> clearCachedNameQueue() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return;
  await prefs.remove('$nameQueuePrefBaseKey:$userId');
}
