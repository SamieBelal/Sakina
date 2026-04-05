import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
}

// ---------------------------------------------------------------------------
// Read / write
// ---------------------------------------------------------------------------

Future<List<CheckInRecord>> getCheckinHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_historyKey);
  if (raw == null) return [];
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => CheckInRecord.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> saveCheckinRecord(CheckInRecord record) async {
  final prefs = await SharedPreferences.getInstance();
  final history = await getCheckinHistory();

  // Remove any existing entry for today so we don't duplicate
  history.removeWhere((r) => r.date == record.date);

  // Prepend newest first, cap at max
  history.insert(0, record);
  final capped = history.take(_maxHistory).toList();

  await prefs.setString(_historyKey, jsonEncode(capped.map((r) => r.toJson()).toList()));
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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.day}';
  } catch (_) {
    return iso;
  }
}
