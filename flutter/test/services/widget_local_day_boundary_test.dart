import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/widget_sync.dart';

/// The widget's day boundary is the USER's, not UTC (W4 Wave 6 review, F1).
///
/// **What went wrong, and why every existing test missed it.** The check-in row
/// is dated from `debugDailyLoopClock()`, which is `.toUtc()`. The widget asked
/// `r.date == _ymd(now)` with a LOCAL `now`. Those disagree for hours every
/// single day, and the previous fixtures never saw it because they built both
/// sides by hand from the same literal — constructing an agreement production
/// does not have.
///
/// So this file never hand-writes a matching pair of date strings. Each
/// scenario is one moment described as a user experiences it — a wall clock and
/// a UTC offset — and the two sides are derived from it the way production
/// derives them: the check-in row from the UTC instant, the reflected-day
/// marker from the wall clock. They disagree on their own, and the assertions
/// state which day each side lands on before testing what the widget does with
/// them.
void main() {
  final alMalik = allahNames.firstWhere((n) => n.transliteration == 'Al-Malik');

  /// Both sides format a `DateTime`'s fields the same way — `_ymd` in
  /// `widget_sync`, the `dateStr` builder in `daily_loop_provider`, and
  /// `_todayLocalString` in `streak_service` are the same six lines.
  ///
  /// **The bug was never the formatting. It was which clock got formatted.** So
  /// these tests keep one formatter and hand it two different clocks, exactly
  /// as production does.
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// A moment described the way a user experiences it: the wall clock they see,
  /// and how far their zone sits from UTC. `wall` carries the wall-clock fields
  /// (`DateTime.utc` only so those fields are read back unchanged by the test
  /// machine's own zone); `utcInstant` is the same moment at Greenwich.
  ({DateTime wall, DateTime utcInstant}) moment(
    DateTime wall,
    Duration utcOffset,
  ) =>
      (wall: wall, utcInstant: wall.subtract(utcOffset));

  CheckInRecord rowAt(DateTime utcInstant, String name) => CheckInRecord(
        // `daily_loop_provider` dates the row off `debugDailyLoopClock()`, UTC.
        date: fmt(utcInstant),
        q1: 'discover',
        q2: '',
        q3: '',
        q4: '',
        nameReturned: name,
        nameArabic: '',
      );

  group('Americas evening — local day behind UTC', () {
    // 20:00 Monday 2026-08-03 at UTC-7 is 03:00 Tuesday in UTC.
    final reveal =
        moment(DateTime.utc(2026, 8, 3, 20), const Duration(hours: -7));

    test('the two clocks really do disagree at this instant', () {
      expect(fmt(reveal.utcInstant), '2026-08-04',
          reason: 'the row the writer stores is dated TOMORROW');
      expect(fmt(reveal.wall), '2026-08-03',
          reason: 'while the user is still in Monday evening');
    });

    test('the widget shows the Name they just received, not the invitation',
        () {
      final s = composeWidgetSyncState(
        history: [rowAt(reveal.utcInstant, 'Al-Wadud')],
        todaysName: alMalik,
        now: reveal.wall.add(const Duration(hours: 1)),
        lastReflectedLocalDay: fmt(reveal.wall),
      );

      expect(s.awaitingReveal, isFalse,
          reason: 'this is the bug: the row is dated tomorrow in UTC, so the '
              'old string match failed and the widget asked "What\'s on your '
              'heart today?" of someone who had just answered it');
      expect(s.name?.transliteration, 'Al-Wadud');
      expect(s.checkedInToday, isTrue);
    });

    test('and the next local morning invites them again', () {
      // 08:00 Tuesday local — a genuinely new local day, nothing revealed yet.
      final nextMorning = DateTime.utc(2026, 8, 4, 8);

      final s = composeWidgetSyncState(
        history: [rowAt(reveal.utcInstant, 'Al-Wadud')],
        todaysName: alMalik,
        now: nextMorning,
        lastReflectedLocalDay: fmt(reveal.wall),
      );

      expect(s.awaitingReveal, isTrue,
          reason: 'the row is still dated 2026-08-04 in UTC, so simply '
              'matching on UTC would show last night\'s Name as today\'s — a '
              'lie about the user\'s own day, and it hides that a new Name is '
              'waiting');
      expect(s.name, isNull);
    });
  });

  group('east of UTC morning — local day ahead of UTC', () {
    // 06:00 Tuesday 2026-08-04 at UTC+9 is 21:00 Monday in UTC. Prime
    // muḥāsabah time, and the server is still on yesterday.
    final reveal =
        moment(DateTime.utc(2026, 8, 4, 6), const Duration(hours: 9));

    test('the two clocks really do disagree at this instant', () {
      expect(fmt(reveal.utcInstant), '2026-08-03');
      expect(fmt(reveal.wall), '2026-08-04');
    });

    test('the widget shows the Name they just received', () {
      final s = composeWidgetSyncState(
        history: [rowAt(reveal.utcInstant, 'Al-Wadud')],
        todaysName: alMalik,
        now: reveal.wall.add(const Duration(minutes: 30)),
        lastReflectedLocalDay: fmt(reveal.wall),
      );

      expect(s.awaitingReveal, isFalse);
      expect(s.name?.transliteration, 'Al-Wadud');
    });

    test('and yesterday\'s reveal does not carry into the new local day', () {
      final s = composeWidgetSyncState(
        history: [rowAt(reveal.utcInstant, 'Al-Wadud')],
        todaysName: alMalik,
        now: reveal.wall.add(const Duration(days: 1)),
        lastReflectedLocalDay: fmt(reveal.wall),
      );

      expect(s.awaitingReveal, isTrue);
      expect(s.name, isNull);
    });
  });

  group('degradation', () {
    final at = moment(DateTime.utc(2026, 8, 3, 20), const Duration(hours: -7));

    test('a user who has never reflected sees the invitation', () {
      final s = composeWidgetSyncState(
        history: const [],
        todaysName: alMalik,
        now: at.wall,
        lastReflectedLocalDay: null,
      );
      expect(s.awaitingReveal, isTrue);
    });

    test('reflected today but no history row → withhold rather than guess', () {
      // Reachable when the history cache is cleared independently of the streak
      // cache. The invitation is wrong here, but naming a Name we cannot source
      // would be worse — that is the failure this whole wave exists to remove.
      final s = composeWidgetSyncState(
        history: const [],
        todaysName: alMalik,
        now: at.wall,
        lastReflectedLocalDay: fmt(at.wall),
      );
      expect(s.awaitingReveal, isTrue);
      expect(s.name, isNull);
    });

    test('the newest row wins when several are cached', () {
      final older = at.utcInstant.subtract(const Duration(days: 2));
      final s = composeWidgetSyncState(
        // `saveCheckinRecord` prepends, so index 0 is the newest.
        history: [rowAt(at.utcInstant, 'Al-Wadud'), rowAt(older, 'Al-Malik')],
        todaysName: alMalik,
        now: at.wall,
        lastReflectedLocalDay: fmt(at.wall),
      );
      expect(s.name?.transliteration, 'Al-Wadud');
    });
  });
}
