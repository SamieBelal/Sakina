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

  testWidgets('Sahih Muslim 2732b hadith block is rendered with citation',
      (tester) async {
    // The Option 2 card cites Sahih Muslim 2732b directly because the
    // hadith literally describes the mutual-reward mechanic of this
    // feature ("Amen, and it is for you also"). Pin both the citation
    // and the closing clause so a future copy edit can't accidentally
    // paraphrase scripture or drop the attribution — both would violate
    // CLAUDE.md's "NEVER fabricate hadith" rule and the sunnah.com
    // verbatim contract.
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

    expect(find.text('\u2014 Sahih Muslim 2732b'), findsOneWidget);
    expect(
      find.textContaining('Amen, and it is for you also'),
      findsOneWidget,
    );
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
    // Tap the back arrow. SubpageHeader renders Icons.arrow_back_ios_new_rounded.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(
      spy.tracked.where((e) => e.$1 == AnalyticsEvents.referUnlockBackToPaywall),
      isNotEmpty,
    );
  });
}
