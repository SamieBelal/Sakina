// Month of Light becomes the Journal's browse surface (Wave D, D4).
//
// The calendar was already right — it derives `lit / todayPending / excused /
// held / missed / future` from check-in history and frames gaps as *"an open
// invitation, not a gap"*. What it had no way to do was go anywhere: it was a
// read-only sheet reachable only from the streak line.
//
// The half of D4 that is easy to get wrong is which cells route. Making every
// cell tappable would turn the gentle framing of a missed night into a prod at
// the user for having missed it, so only `lit` (open that night) and
// `todayPending` (start tonight) do anything at all. That restriction is what
// this file exists to hold.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';
import 'package:sakina/features/streaks/widgets/month_of_light.dart';
import 'package:sakina/features/streaks/widgets/month_of_light_cell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A fixed August 2026 with one lit night (the 1st), today pending (the 2nd)
  // and one genuine gap (the 3rd is future; the 31 cells cover the month).
  final lit = DateTime.utc(2026, 8, 1);
  final today = DateTime.utc(2026, 8, 2);

  MonthOfLight fixture() {
    final cells = <DateTime, MonthCellState>{};
    for (var d = 1; d <= 31; d++) {
      final day = DateTime.utc(2026, 8, d);
      cells[day] = switch (d) {
        1 => MonthCellState.lit,
        2 => MonthCellState.todayPending,
        _ => MonthCellState.future,
      };
    }
    return MonthOfLight(cells: cells, litCount: 1, month: DateTime.utc(2026, 8, 1));
  }

  MonthOfLight withMissed() {
    final base = fixture();
    final cells = Map<DateTime, MonthCellState>.from(base.cells);
    // Rewrite the 1st as a missed night so a "missed cell does nothing" test
    // has something concrete to tap.
    cells[DateTime.utc(2026, 8, 1)] = MonthCellState.missed;
    return MonthOfLight(cells: cells, litCount: 0, month: base.month);
  }

  Future<List<({DateTime day, MonthCellState state})>> openSheet(
    WidgetTester t, {
    required MonthOfLight data,
    bool routable = true,
  }) async {
    final taps = <({DateTime day, MonthCellState state})>[];
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          monthOfLightProvider.overrideWith((_) async => data),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showMonthOfLightSheet(
                    context,
                    onDaySelected: !routable
                        ? null
                        : (day, state) => taps.add((day: day, state: state)),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return taps;
  }

  /// The cell for [day], found by identity rather than by position in the grid
  /// (leading blanks shift every month's layout).
  Finder cellFor(DateTime day) => find.byWidgetPredicate(
        (w) => w is MonthOfLightCell && w.day == day && !w.dense,
      );

  testWidgets('a lit cell routes, carrying its day and state', (t) async {
    final taps = await openSheet(t, data: fixture());

    await t.tap(cellFor(lit));
    await t.pumpAndSettle();

    expect(taps, hasLength(1));
    expect(taps.single.day, lit);
    expect(taps.single.state, MonthCellState.lit);
  });

  testWidgets('todayPending routes as its own state, not as lit', (t) async {
    final taps = await openSheet(t, data: fixture());

    await t.tap(cellFor(today));
    await t.pumpAndSettle();

    expect(taps.single.state, MonthCellState.todayPending,
        reason: 'the two destinations differ — one opens a night, the other '
            'starts one');
  });

  testWidgets('selecting a day dismisses the sheet', (t) async {
    final taps = await openSheet(t, data: fixture());
    expect(find.text('Your month of light'), findsOneWidget);

    await t.tap(cellFor(lit));
    await t.pumpAndSettle();

    expect(taps, hasLength(1));
    expect(
      find.text('Your month of light'),
      findsNothing,
      reason: 'the callback pushes a route, and a route pushed under a live '
          'modal sheet lands behind it — the sheet has to pop on selection',
    );
  });

  testWidgets('a missed cell is inert — the gap stays an invitation',
      (t) async {
    final taps = await openSheet(t, data: withMissed());

    await t.tap(cellFor(DateTime.utc(2026, 8, 1)));
    await t.pumpAndSettle();

    expect(taps, isEmpty);
    // And the sheet is still up: nothing happened at all.
    expect(find.text('Your month of light'), findsOneWidget);
  });

  testWidgets('a future cell is inert', (t) async {
    final taps = await openSheet(t, data: fixture());
    await t.tap(cellFor(DateTime.utc(2026, 8, 20)));
    await t.pumpAndSettle();
    expect(taps, isEmpty);
  });

  testWidgets('with no callback the sheet stays exactly as read-only as it was',
      (t) async {
    // The Progress screen's streak line still opens it this way.
    await openSheet(t, data: fixture(), routable: false);

    final cell = t.widget<MonthOfLightCell>(cellFor(lit));
    expect(cell.onTap, isNull);

    await t.tap(cellFor(lit));
    await t.pumpAndSettle();
    expect(find.text('Your month of light'), findsOneWidget);
  });
}
