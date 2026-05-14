import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/screens/refer_unlock_screen.dart';
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
  testWidgets('refer_unlock_shown fires on mount with paywall_dwell_seconds',
      (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: ReferUnlockScreen(
          paywallDwellSeconds: 42,
          onStartTrial: () {},
          onClose: () {},
          shareOverride: (text) async {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final shown = spy.tracked
        .where((e) => e.$1 == AnalyticsEvents.referUnlockShown)
        .toList();
    expect(shown.length, 1);
    expect(shown.first.$2, containsPair('paywall_dwell_seconds', 42));
  });

  testWidgets('Start free trial CTA fires refer_unlock_start_trial_tapped',
      (tester) async {
    final spy = _TrackingSpy();
    var trialTapped = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: ReferUnlockScreen(
          onStartTrial: () => trialTapped++,
          onClose: () {},
          shareOverride: (text) async {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Verify the trial button label is rendered (the body copy "Start your
    // 7-day free trial" is the headline; the CTA label is "Start free trial").
    await tester.tap(find.text('Start free trial'));
    await tester.pumpAndSettle();

    expect(trialTapped, 1);
    expect(
      spy.tracked.where((e) => e.$1 == AnalyticsEvents.referUnlockStartTrialTapped),
      isNotEmpty,
    );
  });

  testWidgets('spiritual-native copy is rendered, not generic "invite" copy',
      (tester) async {
    final spy = _TrackingSpy();
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: ReferUnlockScreen(
          onStartTrial: () {},
          onClose: () {},
          shareOverride: (text) async {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The brand moat is the spiritual reframe — pin the headline so a
    // future "make it sound more like Dropbox" change is caught.
    expect(find.text('Send a dua to 3 friends'), findsOneWidget);
    // Negative pin: Dropbox-style copy must not appear.
    expect(find.text('Invite 3 friends'), findsNothing);
    expect(find.text('Get a free month'), findsNothing);
  });

  testWidgets('Back gesture invokes onClose and refer_unlock_back_to_paywall',
      (tester) async {
    final spy = _TrackingSpy();
    var closed = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: ReferUnlockScreen(
          onStartTrial: () {},
          onClose: () => closed++,
          shareOverride: (text) async {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // Tap the back arrow.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(
      spy.tracked.where((e) => e.$1 == AnalyticsEvents.referUnlockBackToPaywall),
      isNotEmpty,
    );
  });
}
