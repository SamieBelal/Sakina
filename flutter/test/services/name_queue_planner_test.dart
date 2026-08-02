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
      ], discovered: {
        11
      });
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
      ], discovered: {
        11,
        22
      });
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
      // Deliberately a LATER clock than the rest of this group. At the reference
      // now (Aug 4 03:00Z) every instant whose zero-offset day is Aug 4 is also
      // within 20h, so the floor clause of rule 2 subsumes the day clause and the
      // offset cannot be the sole decider. Late in the user's local day it can.
      //
      // now = Aug 4 23:00Z → LA local Aug 4 16:00, so localToday is Aug 4.
      // Floor edge is Aug 4 03:00Z, and the row below sits 21h back — outside it.
      final now = DateTime.utc(2026, 8, 4, 23);
      final today = DateTime.utc(2026, 8, 4);
      final rows = [row(1, 11, DateTime.utc(2026, 8, 4, 2)), row(2, 22)];

      // LA: the row is Aug 3 19:00 local — the user's PREVIOUS day, and outside
      // the floor, so nothing resumes and the queue may advance.
      expect(
        plan(rows, now: now, today: today, offset: laOffset),
        isA<QueueUnseal>(),
      );
      // Zero offset: the same instant is Aug 4 — the user's today — so it
      // resumes. Only the offset changed.
      expect(
        plan(rows, now: now, today: today, offset: Duration.zero),
        isA<QueueResume>(),
      );
    });

    test(
        'an unmet unseal from the PREVIOUS local day still inside the floor '
        'resumes — the lost-response case', () {
      // The abandonment that local-day-only scoping missed, and the reason rule 2
      // now also accepts inside-the-floor rows.
      //
      // The unseal COMMITS server-side at Aug 4 04:00Z — Aug 3 21:00 LA, late on
      // the user's previous local day — and the response is lost (RPC timeout
      // after commit, or the process dies). The user returns at Aug 4 23:00Z
      // (Aug 4 16:00 local): a different local day, but only 19h later, so still
      // inside the 20h floor.
      //
      // Old behaviour: rule 2 missed it (previous local day) and rule 3 fired →
      // QueueHold → an ordinary pull. By the next day the floor had cleared and
      // rule 5 unsealed min(sealed) — position 3 — leaving position 2 spent and
      // its Name never taught. For position 2 that silently drops the D1 deck.
      final p = plan(
        [
          row(1, 11, DateTime.utc(2026, 8, 1, 15)),
          row(2, 22, DateTime.utc(2026, 8, 4, 4)),
          row(3, 33),
        ],
        discovered: {11},
        now: DateTime.utc(2026, 8, 4, 23),
        today: DateTime.utc(2026, 8, 4),
      );
      expect(p, isA<QueueResume>());
      expect((p as QueueResume).row.position, 2);
      expect(p.row.nameId, 22);
    });

    test(
        'a MET Name from the previous local day inside the floor does NOT '
        'resume', () {
      // The widened window must not weaken the "same Name on two consecutive
      // mornings" guard: being met is still disqualifying, which is what makes
      // the resume path close itself after a successful reveal.
      final p = plan(
        [
          row(1, 11, DateTime.utc(2026, 8, 1, 15)),
          row(2, 22, DateTime.utc(2026, 8, 4, 4)),
          row(3, 33),
        ],
        discovered: {11, 22},
        now: DateTime.utc(2026, 8, 4, 23),
        today: DateTime.utc(2026, 8, 4),
      );
      expect(p, isA<QueueHold>());
    });
  });

  group('rule 3 — the 20h server floor', () {
    // **Every case here uses position 2+ as the recent unseal.** These used to
    // put the timestamp on position 1 and assert QueueHold, which pinned a
    // client that disagreed with its own server: `unseal_next_name` scopes the
    // floor to `position > 1`, because position 1's `unsealed_at` is the SEED's
    // `now()` rather than an unseal. See the seed group below for the case that
    // was actually broken.
    test('last unseal 19h59m ago → QueueHold', () {
      // 2026-08-03T07:01Z is 19h59m before 2026-08-04T03:00Z.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 7, 20, 5)),
        row(2, 22, DateTime.utc(2026, 8, 3, 7, 1)),
        row(3, 33),
      ], discovered: {
        11,
        22
      });
      expect(p, isA<QueueHold>());
    });

    test('last unseal 20h01m ago → QueueUnseal', () {
      // 2026-08-03T06:59Z is 20h01m before 2026-08-04T03:00Z.
      final p = plan([
        row(1, 11, DateTime.utc(2026, 7, 20, 5)),
        row(2, 22, DateTime.utc(2026, 8, 3, 6, 59)),
        row(3, 33),
      ], discovered: {
        11,
        22
      });
      expect(p, isA<QueueUnseal>());
    });

    test('exactly 20h ago is NOT inside the floor', () {
      final p = plan([
        row(1, 11, DateTime.utc(2026, 7, 20, 5)),
        row(2, 22, DateTime.utc(2026, 8, 3, 7)),
        row(3, 33),
      ], discovered: {
        11,
        22
      });
      expect(p, isA<QueueUnseal>());
    });

    test('the MOST RECENT unseal decides, not the earliest', () {
      final p = plan([
        row(1, 11, DateTime.utc(2026, 7, 20, 5)),
        row(2, 22, DateTime.utc(2026, 8, 3, 20)),
        row(3, 33),
      ], discovered: {
        11,
        22
      });
      expect(p, isA<QueueHold>());
    });
  });

  group("rule 3 — position 1's seed timestamp is not an unseal", () {
    // The client's floor has to agree with the server's, and the server's
    // (20260727130000_unseal_floor_excludes_seed_position.sql) reads:
    //
    //   select max(q.unsealed_at) ... where q.user_id = v_uid and q.position > 1
    //
    // Position 1 is stamped by `seed_name_queue` at onboarding. Treating that
    // as an unseal put the client in QueueHold for the first 20 hours of every
    // new user's life — silently, without ever asking the server, on the exact
    // path W3 exists to serve.

    test('onboarded 8pm, back at 9am the next morning → asks the server', () {
      // 13 hours after the seed, so inside the floor if position 1 counted.
      // Both the local day AND the calendar day have turned over; the server
      // would unseal position 2 here, and the client must let it.
      final p = plan(
        [
          row(1, 11, DateTime.utc(2026, 8, 3, 20)), // seeded at onboarding
          row(2, 22),
          row(3, 33),
        ],
        discovered: {11}, // Name 1 was met during onboarding
        now: DateTime.utc(2026, 8, 4, 9),
        today: DateTime.utc(2026, 8, 4),
      );
      expect(
        p,
        isA<QueueUnseal>(),
        reason: 'holding here loses the D1 deck for every user who comes back '
            'the next morning — the most valuable returning cohort there is',
      );
    });

    test('a seed only 2h old still asks — the server owns the same-day rule',
        () {
      // Deliberately aggressive: the client does NOT re-implement "one per
      // local day". `unseal_next_name` is idempotent per local day and returns
      // the existing row, so asking early costs a round trip and never a
      // double unseal. Holding, by contrast, costs the deck.
      final p = plan(
        [row(1, 11, DateTime.utc(2026, 8, 4, 7)), row(2, 22)],
        discovered: {11},
        now: DateTime.utc(2026, 8, 4, 9),
        today: DateTime.utc(2026, 8, 4),
      );
      expect(p, isA<QueueUnseal>());
    });

    test('but a real unseal on position 2 still holds', () {
      // The guard the exclusion must not weaken: once a genuine unseal has
      // happened, the floor applies as before.
      final p = plan(
        [
          row(1, 11, DateTime.utc(2026, 8, 3, 20)),
          row(2, 22, DateTime.utc(2026, 8, 4, 7)),
          row(3, 33),
        ],
        discovered: {11, 22},
        now: DateTime.utc(2026, 8, 4, 9),
        today: DateTime.utc(2026, 8, 4),
      );
      expect(p, isA<QueueHold>());
    });

    test('position 1 still counts toward exhaustion', () {
      // The other half of the change: excluded from the FLOOR, not from the
      // queue. All seven spent is still exhausted, and rule 4 must not start
      // reporting a seeded position as available.
      final p = plan(
        [
          row(1, 11, DateTime.utc(2026, 7, 20, 5)),
          for (var i = 2; i <= 7; i++)
            row(i, i * 10, DateTime.utc(2026, 7, 20 + i, 5)),
        ],
        discovered: {11, 20, 30, 40, 50, 60, 70},
        now: DateTime.utc(2026, 8, 4, 9),
        today: DateTime.utc(2026, 8, 4),
      );
      expect(p, isA<QueueExhausted>());
    });
  });

  group('rule 4 — exhausted', () {
    test('all seven unsealed and outside the floor → QueueExhausted', () {
      final p = plan([
        for (var i = 1; i <= 7; i++)
          row(i, i * 10, DateTime.utc(2026, 7, 20 + i, 5)),
      ], discovered: {
        10,
        20,
        30,
        40,
        50,
        60,
        70
      });
      expect(p, isA<QueueExhausted>());
    });

    test('exhausted but inside the floor is QueueHold (rule 3 first)', () {
      final p = plan([
        for (var i = 1; i <= 7; i++)
          row(i, i * 10, DateTime.utc(2026, 8, 4, 1)),
      ], discovered: {
        10,
        20,
        30,
        40,
        50,
        60,
        70
      });
      expect(p, isA<QueueHold>());
    });
  });

  group('rule 5 — unseal', () {
    test('sealed positions remain and the floor is clear → QueueUnseal', () {
      final p = plan([
        row(1, 11, DateTime.utc(2026, 8, 1, 15)),
        row(2, 22),
        row(3, 33),
      ], discovered: {
        11
      });
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

    test('is empty for a legacy user, which keeps their pull bit-identical',
        () {
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
