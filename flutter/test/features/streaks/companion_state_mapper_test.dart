import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/companion_state_mapper.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/services/streak_service.dart';

// Every row of the plan §1 table, plus the boundaries (day 3/4, 29/30, the 8pm
// split), endowedDim-vs-dormant derivation, and the `protected` overlay
// orthogonality. Pure function → no widgets, no async.

StreakState _streak({
  required int current,
  required int longest,
  String? lastActive,
  required bool today,
}) =>
    StreakState(
      currentStreak: current,
      longestStreak: longest,
      lastActive: lastActive,
      todayActive: today,
    );

DateTime _at(int hour) => DateTime(2026, 7, 19, hour); // local wall clock

Brightness _resolve(
  StreakState streak, {
  bool freeze = false,
  int hour = 12,
}) =>
    resolveCompanionState(streak: streak, freezeOwned: freeze, now: _at(hour))
        .brightness;

void main() {
  group('brightness derivation (§1 table, in order)', () {
    test('never acted → endowedDim (lastActive null & longest 0)', () {
      final s = _streak(current: 0, longest: 0, lastActive: null, today: false);
      expect(_resolve(s), Brightness.endowedDim);
    });

    test('has history, streak 0 → dormant (lastActive set)', () {
      final s = _streak(
          current: 0, longest: 5, lastActive: '2026-07-10', today: false);
      expect(_resolve(s), Brightness.dormant);
    });

    test('has history via longestStreak alone, streak 0 → dormant (not endowed)',
        () {
      final s = _streak(current: 0, longest: 8, lastActive: null, today: false);
      expect(_resolve(s), Brightness.dormant);
    });

    test('done today, streak 1 → dim', () {
      final s = _streak(
          current: 1, longest: 1, lastActive: '2026-07-19', today: true);
      expect(_resolve(s), Brightness.dim);
    });

    test('done today, streak 3 (upper dim boundary) → dim', () {
      final s = _streak(
          current: 3, longest: 3, lastActive: '2026-07-19', today: true);
      expect(_resolve(s), Brightness.dim);
    });

    test('done today, streak 4 (lower glowing boundary) → glowing', () {
      final s = _streak(
          current: 4, longest: 4, lastActive: '2026-07-19', today: true);
      expect(_resolve(s), Brightness.glowing);
    });

    test('done today, streak 29 (upper glowing boundary) → glowing', () {
      final s = _streak(
          current: 29, longest: 29, lastActive: '2026-07-19', today: true);
      expect(_resolve(s), Brightness.glowing);
    });

    test('done today, streak 30 (lower fullyLit boundary) → fullyLit', () {
      final s = _streak(
          current: 30, longest: 30, lastActive: '2026-07-19', today: true);
      expect(_resolve(s), Brightness.fullyLit);
    });
  });

  group('not-done-today waiting states (8pm split, local)', () {
    final pending = _streak(
        current: 5, longest: 9, lastActive: '2026-07-18', today: false);

    test('before 8pm → pendingUnlit', () {
      expect(_resolve(pending, hour: 19), Brightness.pendingUnlit);
    });

    test('exactly 8pm → atRiskUnlit (>= cutoff)', () {
      expect(_resolve(pending, hour: companionAtRiskHour),
          Brightness.atRiskUnlit);
    });

    test('after 8pm → atRiskUnlit', () {
      expect(_resolve(pending, hour: 22), Brightness.atRiskUnlit);
    });

    test('the 8pm split never changes the LIT brightness (done today stays lit)',
        () {
      final lit = _streak(
          current: 10, longest: 10, lastActive: '2026-07-19', today: true);
      expect(_resolve(lit, hour: 8), Brightness.glowing);
      expect(_resolve(lit, hour: 23), Brightness.glowing);
    });
  });

  group('protected overlay is orthogonal to brightness', () {
    test('freeze owned adds shield without changing brightness', () {
      final s = _streak(
          current: 12, longest: 12, lastActive: '2026-07-19', today: true);
      final unprotected =
          resolveCompanionState(streak: s, freezeOwned: false, now: _at(12));
      final protected =
          resolveCompanionState(streak: s, freezeOwned: true, now: _at(12));
      expect(unprotected.protected, isFalse);
      expect(protected.protected, isTrue);
      expect(protected.brightness, unprotected.brightness);
    });

    test('a dormant lamp can still be protected', () {
      final s = _streak(
          current: 0, longest: 20, lastActive: '2026-07-01', today: false);
      final state =
          resolveCompanionState(streak: s, freezeOwned: true, now: _at(12));
      expect(state.brightness, Brightness.dormant);
      expect(state.protected, isTrue);
    });
  });

  group('params contract', () {
    test('illum is pinned 1.0 for every brightness', () {
      for (final b in Brightness.values) {
        expect(CompanionState(brightness: b, protected: false).params.illum,
            1.0);
      }
    });

    test('only dormant flips the painter dead-styling flag', () {
      for (final b in Brightness.values) {
        final dormant =
            CompanionState(brightness: b, protected: false).params.dormant;
        expect(dormant, b == Brightness.dormant,
            reason: '$b dormant flag');
      }
    });

    test('faint-but-fresh states stay clean (low wear); dim carries wear', () {
      CompanionParams p(Brightness b) =>
          CompanionState(brightness: b, protected: false).params;
      expect(p(Brightness.endowedDim).wear, lessThan(0.05));
      expect(p(Brightness.pendingUnlit).wear, lessThan(0.2));
      expect(p(Brightness.fullyLit).wear, lessThan(0.05));
      expect(p(Brightness.dim).wear, greaterThan(0.5));
      expect(p(Brightness.dormant).wear, 1.0);
    });
  });
}
