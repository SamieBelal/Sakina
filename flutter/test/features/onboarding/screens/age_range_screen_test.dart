import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/age_range_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

void main() {
  testWidgets('continue enabled after picking an age range', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: AgeRangeScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.ensureVisible(find.text('25-34'));
    await tester.tap(find.text('25-34'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
  });

  testWidgets('fires onboarding_answer_captured when continue is tapped',
      (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: AgeRangeScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.ensureVisible(find.text('25-34'));
    await tester.tap(find.text('25-34'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();

    final events = spy.tracked
        .where((e) => e.$1 == AnalyticsEvents.onboardingAnswerCaptured)
        .toList();
    expect(events.length, 1);
    expect(events.first.$2, {'key': 'age_range', 'value': '25_34'});
  });
}
