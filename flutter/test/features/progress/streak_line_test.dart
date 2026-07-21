import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/progress/screens/progress_screen.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/services/streak_service.dart';

CompanionState _s(CompanionBrightness b) =>
    CompanionState(brightness: b, protected: false);

Future<void> _pump(WidgetTester tester, CompanionState? c, int streak) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(builder: (ctx) => buildStreakLine(ctx, c, streak)),
    ),
  ));
}

void main() {
  group('nextMilestone (single source of truth, C1)', () {
    test('returns first threshold strictly above the streak', () {
      expect(nextMilestone(0)!.days, 7);
      expect(nextMilestone(6)!.days, 7);
      expect(nextMilestone(7)!.days, 14);
      expect(nextMilestone(29)!.days, 30);
      expect(nextMilestone(364)!.days, 365);
    });

    test('returns null once the top milestone (365) is reached (D9)', () {
      expect(nextMilestone(365), isNull);
      expect(nextMilestone(400), isNull);
    });
  });

  group('milestoneProgress', () {
    test('spans from the previous milestone to the next, clamped 0..1', () {
      // streak 7, next 14 → 0 of the 7..14 span.
      expect(milestoneProgress(7, nextMilestone(7)!), 0.0);
      // streak 10, next 14 → (10-7)/(14-7) = 3/7.
      expect(milestoneProgress(10, nextMilestone(10)!), closeTo(3 / 7, 1e-9));
      // just below the next milestone → close to 1.
      expect(milestoneProgress(13, nextMilestone(13)!), closeTo(6 / 7, 1e-9));
    });
  });

  group('buildStreakLine', () {
    testWidgets('loading (null companion) reserves the slot, shows no text',
        (tester) async {
      await _pump(tester, null, 0);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('lit shows "Day N · d to your T-day flame" + a bar',
        (tester) async {
      await _pump(tester, _s(CompanionBrightness.glowing), 12);
      expect(find.text('Day 12 · 2 to your 14-day flame'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('365+ shows the maintained state, no bar (D9)', (tester) async {
      await _pump(tester, _s(CompanionBrightness.fullyLit), 400);
      expect(find.text('Day 400 · every day lit'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('waiting / resting / endowed use the locked vocabulary (D5)',
        (tester) async {
      await _pump(tester, _s(CompanionBrightness.pendingUnlit), 5);
      expect(find.text('Your lantern is waiting'), findsOneWidget);

      await _pump(tester, _s(CompanionBrightness.atRiskUnlit), 5);
      expect(find.text('Your lantern is waiting'), findsOneWidget);

      await _pump(tester, _s(CompanionBrightness.dormant), 0);
      expect(find.text('Your lantern is resting'), findsOneWidget);

      await _pump(tester, _s(CompanionBrightness.endowedDim), 0);
      expect(find.text('Your light is lit'), findsOneWidget);
    });

    testWidgets('never emits a banned word (dark/dies/lost/failed)',
        (tester) async {
      for (final b in CompanionBrightness.values) {
        await _pump(tester, _s(b), 12);
        for (final w in ['dark', 'dies', 'lost', 'failed', 'broken']) {
          expect(find.textContaining(w), findsNothing,
              reason: 'brightness $b must not surface "$w"');
        }
      }
    });
  });
}
