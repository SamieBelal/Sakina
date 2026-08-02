import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/widget_sync.dart';

CheckInRecord _record(String date, String nameReturned) => CheckInRecord(
      date: date,
      q1: '',
      q2: '',
      q3: '',
      q4: '',
      nameReturned: nameReturned,
      nameArabic: '',
    );

void main() {
  final today = allahNames.firstWhere((n) => n.transliteration == 'Al-Malik');
  final checkinName = allahNames.firstWhere((n) => n.transliteration == 'Al-Wakeel');
  final now = DateTime(2026, 7, 14, 10);

  test('checked in today → personalized with the received Name', () {
    final s = composeWidgetSyncState(
      history: [_record('2026-07-14', 'Al-Wakeel')],
      todaysName: today,
      now: now,
      lastReflectedLocalDay: '2026-07-14',
    );
    expect(s.personalized, isTrue);
    expect(s.checkedInToday, isTrue);
    expect(s.name?.transliteration, checkinName.transliteration);
  });

  // UPDATED by W4 Wave 6: pre-check-in the widget no longer advertises the
  // day-of-year rotation, because that Name has never been the one the reveal
  // delivers. See widget_awaiting_reveal_test.dart for the full contract.
  test('no check-in today → NO Name (awaiting), not the daily rotation', () {
    final s = composeWidgetSyncState(
      history: [_record('2026-07-13', 'Al-Wakeel')],
      todaysName: today,
      now: now,
      lastReflectedLocalDay: '2026-07-13',
    );
    expect(s.personalized, isFalse);
    expect(s.checkedInToday, isFalse);
    expect(s.name, isNull);
    expect(s.awaitingReveal, isTrue);
  });

  test('unknown returned Name falls back to today', () {
    final s = composeWidgetSyncState(
      history: [_record('2026-07-14', 'Not-A-Real-Name')],
      todaysName: today,
      now: now,
      lastReflectedLocalDay: '2026-07-14',
    );
    expect(s.checkedInToday, isTrue);
    expect(s.name?.transliteration, today.transliteration);
  });
}
