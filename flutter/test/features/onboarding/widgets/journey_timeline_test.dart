import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/journey_timeline.dart';

void main() {
  testWidgets('renders 3 milestone cards in order', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyTimeline(
            milestones: [
              JourneyMilestone(heading: 'Day 1', lines: ['First line']),
              JourneyMilestone(heading: 'Day 7', lines: ['Second line']),
              JourneyMilestone(heading: 'Day 30', lines: ['Third line']),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 7'), findsOneWidget);
    expect(find.text('Day 30'), findsOneWidget);
    expect(find.text('First line'), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);
    expect(find.text('Third line'), findsOneWidget);
  });

  testWidgets('renders multi-line milestones', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyTimeline(
            milestones: [
              JourneyMilestone(
                heading: 'Day 30',
                lines: ['Line A', 'Line B', 'Line C'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Line A'), findsOneWidget);
    expect(find.text('Line B'), findsOneWidget);
    expect(find.text('Line C'), findsOneWidget);
  });
}
