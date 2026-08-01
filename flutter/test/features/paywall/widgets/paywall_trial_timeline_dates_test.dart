import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/paywall_trial_timeline_page.dart';

/// The timeline names the calendar day the user will be charged. That makes
/// "cancel anytime before" actionable — and makes an off-by-one a false
/// statement about someone's money on the screen that asks for it.
///
/// Two failure modes this pins, both of which W4 hit in other surfaces:
///  * **UTC drift** — reading the day in UTC puts anyone east of the line on
///    tomorrow's date for part of their evening.
///  * **DST drift** — `add(Duration(days: n))` moves by 24h, not by a
///    calendar day, so it lands on the wrong date across a transition.
Widget _subject(DateTime today, {int trialDays = 3}) => MaterialApp(
      home: Scaffold(
        body: PaywallTrialTimelinePage(
          trialLabel: '$trialDays days',
          trialDays: trialDays,
          today: today,
        ),
      ),
    );

void main() {
  testWidgets('Day 1 is today, and the charge day is the last trial day',
      (tester) async {
    // Sat 1 Aug 2026. Trial of 3 => today, reminder on day 2, charge on day 3.
    await tester.pumpWidget(_subject(DateTime(2026, 8, 1)));
    await tester.pumpAndSettle();

    expect(find.text('Sat 1 Aug'), findsOneWidget); // Today
    expect(find.text('Sun 2 Aug'), findsOneWidget); // Day 2 — reminder
    expect(find.text('Mon 3 Aug'), findsOneWidget); // Day 3 — charge
  });

  testWidgets('a 7-day trial recomputes every date from the store, not code',
      (tester) async {
    await tester.pumpWidget(_subject(DateTime(2026, 8, 1), trialDays: 7));
    await tester.pumpAndSettle();

    expect(find.text('Sat 1 Aug'), findsOneWidget); // Today
    expect(find.text('Thu 6 Aug'), findsOneWidget); // Day 6 — reminder
    expect(find.text('Fri 7 Aug'), findsOneWidget); // Day 7 — charge
  });

  testWidgets('crossing a month boundary rolls the month, not the day number',
      (tester) async {
    // Sun 30 Aug + 3-day trial => 30, 31 Aug, 1 Sep.
    await tester.pumpWidget(_subject(DateTime(2026, 8, 30)));
    await tester.pumpAndSettle();

    expect(find.text('Sun 30 Aug'), findsOneWidget);
    expect(find.text('Mon 31 Aug'), findsOneWidget);
    expect(find.text('Tue 1 Sep'), findsOneWidget);
  });

  testWidgets('a late-evening local time still reads as TODAY, not tomorrow',
      (tester) async {
    // 23:30 local. A UTC-based read would show 2 Aug for anyone east of the
    // line — naming a charge date a day early.
    await tester.pumpWidget(_subject(DateTime(2026, 8, 1, 23, 30)));
    await tester.pumpAndSettle();

    expect(find.text('Sat 1 Aug'), findsOneWidget);
    expect(find.text('Sun 2 Aug'), findsOneWidget);
  });

  testWidgets('a US DST spring-forward does not skip a calendar day',
      (tester) async {
    // 8 Mar 2026 is the US spring-forward. Adding Duration(days:1) across it
    // yields 23h of wall clock and can land back on the 8th.
    await tester.pumpWidget(_subject(DateTime(2026, 3, 7)));
    await tester.pumpAndSettle();

    expect(find.text('Sat 7 Mar'), findsOneWidget);
    expect(find.text('Sun 8 Mar'), findsOneWidget);
    expect(find.text('Mon 9 Mar'), findsOneWidget);
  });
}
