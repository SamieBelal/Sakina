import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

/// Records every track() call so the test can assert the A2 funnel event.
class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

void main() {
  testWidgets(
      'A2: tapping Continue with a valid email fires signup_email_submitted '
      '(no PII in props)', (tester) async {
    final analytics = _TrackingSpy();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
        child: MaterialApp(
          home: SignUpEmailScreen(onNext: () {}, onBack: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'darkmatter8789@gmail.com');
    await tester.pump();

    // The Continue button advances the flow; finding it by its label keeps the
    // test resilient to the wrapper's structure.
    await tester.tap(find.text('Continue'));
    await tester.pump();

    final emailEvents = analytics.tracked
        .where((e) => e.$1 == AnalyticsEvents.signupEmailSubmitted)
        .toList();
    expect(emailEvents, hasLength(1),
        reason: 'email-screen completion must emit exactly one event');
    // No PII: the address must never appear in the event props.
    final props = emailEvents.single.$2;
    final serialized = props?.values.join(' ') ?? '';
    expect(serialized.contains('@'), isFalse,
        reason: 'event props must not carry the email address');
  });

  testWidgets('A2: an invalid email does NOT fire signup_email_submitted',
      (tester) async {
    final analytics = _TrackingSpy();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
        child: MaterialApp(
          home: SignUpEmailScreen(onNext: () {}, onBack: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pump();

    // Continue is disabled for an invalid email, but tap anyway to prove the
    // guard in _submit also short-circuits the event.
    final continueFinder = find.text('Continue');
    if (continueFinder.evaluate().isNotEmpty) {
      await tester.tap(continueFinder, warnIfMissed: false);
      await tester.pump();
    }

    expect(
      analytics.tracked
          .any((e) => e.$1 == AnalyticsEvents.signupEmailSubmitted),
      isFalse,
    );
  });
}
