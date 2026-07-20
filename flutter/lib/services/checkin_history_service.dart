import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakina/services/supabase_sync_service.dart';

const String _historyKey = 'sakina_checkin_history';
const int _maxHistory = 14;

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class CheckInRecord {
  final String date; // YYYY-MM-DD
  final String q1;
  final String q2;
  final String q3;
  final String q4;
  final String nameReturned;
  final String nameArabic;

  const CheckInRecord({
    required this.date,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.nameReturned,
    required this.nameArabic,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'q1': q1,
        'q2': q2,
        'q3': q3,
        'q4': q4,
        'nameReturned': nameReturned,
        'nameArabic': nameArabic,
      };

  factory CheckInRecord.fromJson(Map<String, dynamic> j) => CheckInRecord(
        date: j['date'] as String? ?? '',
        q1: j['q1'] as String? ?? '',
        q2: j['q2'] as String? ?? '',
        q3: j['q3'] as String? ?? '',
        q4: j['q4'] as String? ?? '',
        nameReturned: j['nameReturned'] as String? ?? '',
        nameArabic: j['nameArabic'] as String? ?? '',
      );

  /// Convert to Supabase row format.
  Map<String, dynamic> toSupabaseRow(String userId) => {
        'user_id': userId,
        'checked_in_at': date,
        'q1': q1,
        'q2': q2,
        'q3': q3,
        'q4': q4.isEmpty ? null : q4,
        'name_returned': nameReturned,
        'name_arabic': nameArabic,
      };

  /// Create from a Supabase row.
  factory CheckInRecord.fromSupabaseRow(Map<String, dynamic> row) {
    final checkedInAt = row['checked_in_at'] as String? ?? '';
    // checked_in_at may be a full timestamp or just a date — extract date part
    final date =
        checkedInAt.length >= 10 ? checkedInAt.substring(0, 10) : checkedInAt;
    return CheckInRecord(
      date: date,
      q1: row['q1'] as String? ?? '',
      q2: row['q2'] as String? ?? '',
      q3: row['q3'] as String? ?? '',
      q4: row['q4'] as String? ?? '',
      nameReturned: row['name_returned'] as String? ?? '',
      nameArabic: row['name_arabic'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Read / write
// ---------------------------------------------------------------------------

Future<List<CheckInRecord>> getCheckinHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw =
      await supabaseSyncService.migrateLegacyStringCache(prefs, _historyKey);
  if (raw == null) return [];
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => CheckInRecord.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Fetch the set of LOCAL calendar days (YYYY-MM-DD) the user reflected on
/// during the current month, for the "month of light" calendar (T3 / S3 / D13).
///
/// The local 14-record checkin cache can't feed a 31-day grid, so this reads
/// `user_checkin_history` directly, scoped to rows on/after the first day of
/// the current month. `checked_in_at` is a `timestamptz`; each is normalized to
/// the user's LOCAL calendar day (`.toLocal()` then YYYY-MM-DD) — NOT the UTC
/// substring `CheckInRecord.fromSupabaseRow` uses — so a late-night reflection
/// lands on the correct cell. Read-only; never writes. Returns an empty set when
/// signed out or on any error (the summary degrades to "begins today").
Future<Set<String>> fetchLitLocalDatesThisMonth() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return <String>{};

  // First day of the current month, at 00:00 UTC, as the lower bound. Using the
  // UTC month start is a safe (slightly-wide) floor — any row that could map to
  // a local day in this month is included, and the local-day normalization below
  // is what actually decides membership.
  final nowUtc = DateTime.now().toUtc();
  final monthStartUtc = DateTime.utc(nowUtc.year, nowUtc.month, 1);

  try {
    final rows = await Supabase.instance.client
        .from('user_checkin_history')
        .select('checked_in_at')
        .eq('user_id', userId)
        .gte('checked_in_at', monthStartUtc.toIso8601String());
    final list = List<Map<String, dynamic>>.from(rows);
    final result = <String>{};
    for (final row in list) {
      final raw = row['checked_in_at'] as String?;
      final local = _localDayFromTimestamptz(raw);
      if (local != null) result.add(local);
    }
    return result;
  } catch (e) {
    debugPrint('[checkin_history] fetchLitLocalDatesThisMonth failed: $e');
    return <String>{};
  }
}

/// Normalize a `timestamptz` string to the user's LOCAL calendar day
/// (YYYY-MM-DD), or null if unparseable. `DateTime.parse` respects the offset in
/// the string (or treats naked values as UTC via `.toLocal()`), so this is the
/// local-day the reflection actually happened on for the user.
String? _localDayFromTimestamptz(String? checkedInAt) {
  if (checkedInAt == null || checkedInAt.isEmpty) return null;
  try {
    final local = DateTime.parse(checkedInAt).toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  } catch (_) {
    return null;
  }
}

Future<void> saveCheckinRecord(CheckInRecord record) async {
  final prefs = await SharedPreferences.getInstance();
  final history = await getCheckinHistory();

  // Remove any existing entry for today so we don't duplicate
  history.removeWhere((r) => r.date == record.date);

  // Prepend newest first, cap at max
  history.insert(0, record);
  final capped = history.take(_maxHistory).toList();

  await prefs.setString(
    supabaseSyncService.scopedKey(_historyKey),
    jsonEncode(capped.map((r) => r.toJson()).toList()),
  );

  // Write to Supabase
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    final existingRows = await supabaseSyncService.fetchRows(
      'user_checkin_history',
      userId,
      orderBy: 'checked_in_at',
    );
    for (final row in existingRows) {
      final checkedInAt = row['checked_in_at']?.toString() ?? '';
      final rowDate =
          checkedInAt.length >= 10 ? checkedInAt.substring(0, 10) : checkedInAt;
      if (rowDate == record.date && row['id'] != null) {
        await supabaseSyncService.deleteRow(
          'user_checkin_history',
          'id',
          row['id'],
        );
      }
    }
    await supabaseSyncService.insertRow(
      'user_checkin_history',
      record.toSupabaseRow(userId),
    );
  }
}

Future<void> migrateCheckinHistoryCache() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _historyKey);
}

Future<void> seedCheckinHistoryToSupabaseFromLocalCache() async {
  await supabaseSyncService.seedListFromLocalCache(
    table: 'user_checkin_history',
    cacheKey: _historyKey,
    toRows: (localItems, userId) => localItems
        .map((e) => CheckInRecord.fromJson(e as Map<String, dynamic>)
            .toSupabaseRow(userId))
        .toList(),
  );
}

Future<void> hydrateCheckinHistoryCacheFromRows(
  List<Map<String, dynamic>> remoteRows,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_historyKey),
    jsonEncode(
      remoteRows.map((r) => CheckInRecord.fromSupabaseRow(r).toJson()).toList(),
    ),
  );
}

/// Returns the last [n] records as a concise prompt-ready string.
/// Example line: "Apr 2 — felt heavy from grief → Al-Wadud"
String buildHistoryContext(List<CheckInRecord> history, {int n = 5}) {
  if (history.isEmpty) return '';
  final recent = history.take(n).toList();
  final lines = recent.map((r) {
    final date = _formatDate(r.date);
    return '$date — "${r.q1}" / "${r.q2}" → ${r.nameReturned}';
  });
  return lines.join('\n');
}

String _formatDate(String iso) {
  try {
    final d = DateTime.parse(iso);
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month]} ${d.day}';
  } catch (_) {
    return iso;
  }
}
