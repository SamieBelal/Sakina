import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/rating_gate_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'CTA starts as "Send a sign", flips to "I rated" after tap, headline personalizes from signUpName',
      (tester) async {
    final spy = _TrackingSpy();
    var nextCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
          onboardingProvider.overrideWith(
            (ref) => OnboardingNotifier(
              restored: const OnboardingState(
                signUpName: 'Aisha',
                intention: 'Spiritual Growth',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () => nextCalled = true,
            onBack: () {},
            // Test seam: skip the real platform call.
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Headline should contain the user's name (personalized).
    expect(find.textContaining('Aisha'), findsOneWidget);

    expect(find.text('Send a sign'), findsOneWidget);
    expect(find.text('I rated'), findsNothing);
    expect(nextCalled, isFalse);

    await tester.tap(find.text('Send a sign'));
    await tester.pumpAndSettle();

    expect(find.text('Send a sign'), findsNothing);
    expect(find.text('I rated'), findsOneWidget);
    expect(nextCalled, isFalse,
        reason: 'First tap triggers the OS prompt only, does not advance');

    await tester.tap(find.text('I rated'));
    await tester.pumpAndSettle();

    expect(nextCalled, isTrue);

    // Verify the three rating-gate events fired in order with the
    // os_prompt_available property on the prompt-triggered event.
    final ratingEvents = spy.tracked
        .where((e) => e.$1.startsWith('rating_gate_'))
        .toList();
    expect(ratingEvents.length, 3);
    expect(ratingEvents[0].$1, AnalyticsEvents.ratingGateShown);
    expect(ratingEvents[1].$1, AnalyticsEvents.ratingGatePromptTriggered);
    expect(ratingEvents[1].$2?['os_prompt_available'], isTrue);
    expect(ratingEvents[2].$1, AnalyticsEvents.ratingGateContinueTapped);
  });

  testWidgets('headline falls back to "Friend" when signUpName is null',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(_TrackingSpy()),
          // onboardingProvider default state has signUpName == null.
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () {},
            onBack: () {},
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Friend'), findsOneWidget);
  });

  testWidgets(
      'persisted "rated" state rehydrates and CTA shows "I rated" directly',
      (tester) async {
    SharedPreferences.setMockInitialValues({'rating_gate_completed': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(_TrackingSpy()),
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () {},
            onBack: () {},
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('I rated'), findsOneWidget);
    expect(find.text('Send a sign'), findsNothing);
  });

  // ----------------------------------------------------------------
  // P1-4 fix (2026-05-24): "Maybe later" tertiary skip button.
  // The rating gate must offer a no-rating path forward so users
  // are not forced into invoking the OS rating prompt to advance
  // onboarding (Apple guideline 4.5.4 + dark-pattern hygiene).
  // ----------------------------------------------------------------

  testWidgets(
      'Maybe later button renders alongside Send a sign on initial state',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(_TrackingSpy()),
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () {},
            onBack: () {},
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Send a sign'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
  });

  testWidgets('Tapping Maybe later fires ratingGateSkipped analytics',
      (tester) async {
    final spy = _TrackingSpy();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () {},
            onBack: () {},
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    final skipEvents = spy.tracked
        .where((e) => e.$1 == AnalyticsEvents.ratingGateSkipped)
        .toList();
    expect(skipEvents.length, 1);
  });

  testWidgets('Tapping Maybe later calls onNext()', (tester) async {
    var nextCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(_TrackingSpy()),
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () => nextCount++,
            onBack: () {},
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(nextCount, 0);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    expect(nextCount, 1);
  });
}
