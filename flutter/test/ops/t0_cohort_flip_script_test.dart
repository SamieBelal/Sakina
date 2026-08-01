import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D12 (2026-08-01) moved the free-tier tightening from "after a 30-day
/// notice, at the softener wave" to "everyone, at T0". The staged wave was
/// written for the OLD plan and cannot deliver the new one:
///
///  * `softener_2_flip.sql` is gated on `softener_notice_ends_at <= now()`,
///    and under D12 nothing ever stamps that column — so it matches **zero
///    rows**.
///  * It clamps `warmup_reflect_remaining` and `warmup_built_dua_remaining`
///    but **not** `warmup_discover_name_remaining`, which is still on the
///    legacy default of 5.
///
/// And two facts about production make the naive statement wrong in a third
/// way: `free_tier_cohort` is NULL (not `'legacy'`) on 1,262 of 1,365
/// accounts, so any `where free_tier_cohort = 'legacy'` filter silently
/// misses 92% of the base.
///
/// This test pins the T0 script against all three, because the script runs
/// once, by hand, on release day — there is no second chance to notice.
void main() {
  final script = File('supabase/staged/t0_flip_all_to_reel_v1.sql');

  test('the T0 flip script exists', () {
    expect(script.existsSync(), isTrue,
        reason: 'D12 requires a T0 script; the softener wave cannot deliver '
            'it (its notice gate matches nothing under D12)');
  });

  group('the T0 flip script', () {
    late String sql;

    setUp(() {
      // Assert on EXECUTABLE sql only. Leaving the `--` comments in meant the
      // "no 'legacy' filter" check matched the comment explaining why the
      // filter is wrong — a test that fails on its own documentation. And
      // collapsing whitespace keeps the contract about what the statement
      // DOES, not about where the formatter chose to break the line.
      sql = script
          .readAsLinesSync()
          .map((l) {
            final i = l.indexOf('--');
            return i == -1 ? l : l.substring(0, i);
          })
          .join(' ')
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '');
    });

    test('clamps ALL THREE warmup counters, not just reflect and built_dua',
        () {
      for (final column in [
        'warmup_reflect_remaining',
        'warmup_built_dua_remaining',
        'warmup_discover_name_remaining',
      ]) {
        expect(sql, contains(column),
            reason: '$column is left at its legacy default if the script does '
                'not clamp it — the tier would not actually tighten');
        expect(sql, contains('least($column'),
            reason: '$column must be clamped with least(), never assigned: a '
                'bare assignment would REFILL a user who has already spent '
                'their warmup, and the freemium guard is decrement-only');
      }
    });

    test('does not filter the cohort backfill on the string "legacy"', () {
      expect(sql.contains("free_tier_cohort='legacy'"), isFalse,
          reason: 'free_tier_cohort is NULL on 92% of production rows; '
              'filtering on the literal misses them entirely');
    });

    test('refuses to run under a non-exempt role', () {
      expect(sql, contains('current_user'),
          reason: 'the freemium guard exempts only service_role / postgres / '
              'supabase_admin — a half-applied flip under a restricted role '
              'is worse than a loud failure');
    });
  });
}
