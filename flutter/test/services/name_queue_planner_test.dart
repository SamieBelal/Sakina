import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/name_queue_planner.dart';
import 'package:sakina/services/name_queue_service.dart';

/// Table-driven pin of the five [QueueRevealPlan] outcomes (W3 plan §3a/§12).
///
/// Pure function, so there is no binding, no prefs and no clock — every instant
/// below is a **literal pinned UTC value**, not one computed from `DateTime.now()`.
/// (A W1 review lesson: a computed-clock day-boundary test was vacuous and had
/// to be replaced with literal pins.)
void main() {
  // Reference "now": 2026-08-04T03:00Z. For America/Los_Angeles (UTC-7 in
  // August) that is 2026-08-03 20:00 local, so the user's local day is Aug 3.
  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);
  final localToday = DateTime.utc(2026, 8, 3);
  const laOffset = Duration(hours: -7);

  NameQueueRow row(int position, int nameId, [DateTime? unsealedAt]) =>
      NameQueueRow(position: position, nameId: nameId, unsealedAt: unsealedAt);

  QueueRevealPlan plan(
    List<NameQueueRow> queue, {
    Set<int> discovered = const {},
    DateTime? now,
    DateTime? today,
    Duration offset = laOffset,
  }) =>
      planQueueReveal(
        queue: queue,
        discoveredIds: discovered,
        nowUtc: now ?? nowUtc,
        localToday: today ?? localToday,
        localUtcOffset: offset,
      );

  group('rule 1 — no rows', () {
    test('empty queue is QueueAbsent (the legacy / reverted gate)', () {
      expect(plan(const []), isA<QueueAbsent>());
    });
  });

  group('rule 2 — resume an abandoned unseal', () {
    test('unsealed on the local day but Name unmet → QueueResume(row)', () {
      // Unsealed 2026-08-04T01:00Z = 2026-08-03 18:00 LA — the user's today.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 1, 15)),
        row(2, 22, DateTime.utc(2026, 8, 4, 1)),
        row(3, 33),
      ], discovered: {11});
      expect(p, isA<QueueResume>());
      expect((p as QueueResume).row.nameId, 22);
      expect(p.row.position, 2);
    });

    test('unsealed on the local day and ALREADY MET → not QueueResume', () {
      // The case that matters most: a user who completes their reveal and
      // reopens the app must not be handed the same Name again. Falls through
      // to rule 3, because a same-day unseal is inside the 20h floor.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 1, 15)),
        row(2, 22, DateTime.utc(2026, 8, 4, 1)),
        row(3, 33),
      ], discovered: {11, 22});
      expect(p, isNot(isA<QueueResume>()));
      expect(p, isA<QueueHold>());
    });

    test('unmet but unsealed on a PREVIOUS local day → not QueueResume', () {
      // Unsealed 2026-08-02T10:00Z = Aug 2 03:00 LA. Unmet, but yesterday's
      // business; rule 2 is scoped to today so the queue keeps moving.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 1, 15)),
        row(2, 22, DateTime.utc(2026, 8, 2, 10)),
        row(3, 33),
      ]);
      expect(p, isNot(isA<QueueResume>()));
      expect(p, isA<QueueUnseal>());
    });

    test('resume wins over the 20h floor', () {
      // Same row, unsealed 2 hours ago — squarely inside the floor. Rule 2
      // running BEFORE rule 3 is what makes the abandoned case recoverable.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 4, 1)),
        row(2, 22),
      ]);
      expect(p, isA<QueueResume>());
      expect((p as QueueResume).row.position, 1);
    });

    test('lowest position wins when two rows are unmet today', () {
      final p = plan([
        row(2, 22, DateTime.utc(2026, 8, 4, 2)),
        row(1, 11, DateTime.utc(2026, 8, 4, 1)),
      ]);
      expect((p as QueueResume).row.position, 1);
    });

    test('the local offset actually moves the day comparison', () {
      // Unsealed 2026-08-04T01:00Z. In UTC that is Aug 4, NOT the pinned
      // localToday of Aug 3 — so with a zero offset rule 2 must not fire.
      final rows = [row(1, 11, DateTime.utc(2026, 8, 4, 1)), row(2, 22)];
      expect(plan(rows, offset: laOffset), isA<QueueResume>());
      expect(plan(rows, offset: Duration.zero), isA<QueueHold>());
    });
  });

  group('rule 3 — the 20h server floor', () {
    test('last unseal 19h59m ago → QueueHold', () {
      // 2026-08-03T07:01Z is 19h59m before 2026-08-04T03:00Z.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 3, 7, 1)),
        row(2, 22),
      ], discovered: {11});
      expect(p, isA<QueueHold>());
    });

    test('last unseal 20h01m ago → QueueUnseal', () {
      // 2026-08-03T06:59Z is 20h01m before 2026-08-04T03:00Z.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 3, 6, 59)),
        row(2, 22),
      ], discovered: {11});
      expect(p, isA<QueueUnseal>());
    });

    test('exactly 20h ago is NOT inside the floor', () {
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 3, 7)),
        row(2, 22),
      ], discovered: {11});
      expect(p, isA<QueueUnseal>());
    });

    test('the MOST RECENT unseal decides, not the earliest', () {
      final p = plan([
        row(1, 11, DateTime.utc(2026, 7, 20, 5)),
        row(2, 22, DateTime.utc(2026, 8, 3, 20)),
        row(3, 33),
      ], discovered: {11, 22});
      expect(p, isA<QueueHold>());
    });
  });

  group('rule 4 — exhausted', () {
    test('all seven unsealed and outside the floor → QueueExhausted', () {
      final p = plan([
        for (var i = 1; i <= 7; i++)
          row(i, i * 10, DateTime.utc(2026, 7, 20 + i, 5)),
      ], discovered: {10, 20, 30, 40, 50, 60, 70});
      expect(p, isA<QueueExhausted>());
    });

    test('exhausted but inside the floor is QueueHold (rule 3 first)', () {
      final p = plan([
        for (var i = 1; i <= 7; i++) row(i, i * 10, DateTime.utc(2026, 8, 4, 1)),
      ], discovered: {10, 20, 30, 40, 50, 60, 70});
      expect(p, isA<QueueHold>());
    });
  });

  group('rule 5 — unseal', () {
    test('sealed positions remain and the floor is clear → QueueUnseal', () {
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 1, 15)),
        row(2, 22),
        row(3, 33),
      ], discovered: {11});
      expect(p, isA<QueueUnseal>());
    });

    test('a fully sealed queue with no unseal history → QueueUnseal', () {
      expect(plan([row(1, 11), row(2, 22)]), isA<QueueUnseal>());
    });
  });

  group('sealedQueueNameIds', () {
    test('returns only sealed name_ids', () {
      final ids = sealedQueueNameIds([
        row(1, 11, DateTime.utc(2026, 8, 1)),
        row(2, 22),
        row(3, 33),
      ]);
      expect(ids, {22, 33});
    });

    test('is empty for a legacy user, which keeps their pull bit-identical', () {
      expect(sealedQueueNameIds(const []), isEmpty);
    });

    test('is empty once every position is unsealed', () {
      final ids = sealedQueueNameIds([
        row(1, 11, DateTime.utc(2026, 8, 1)),
        row(2, 22, DateTime.utc(2026, 8, 2)),
      ]);
      expect(ids, isEmpty);
    });
  });

  test('the floor constant matches the server-side 20 hours', () {
    expect(nameQueueUnsealFloor, const Duration(hours: 20));
  });
}
