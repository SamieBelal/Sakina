import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/reverse_trial_expired_sheet.dart';
import 'package:sakina/services/analytics_event_names.dart';

void main() {
  late List<({String event, Map<String, dynamic> props})> emitted;

  setUp(() => emitted = []);

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the Day-3 soft-gate copy and CTAs', (tester) async {
    await tester.pumpWidget(host(
      ReverseTrialExpiredSheet(
        onUpgrade: () {},
        onDismiss: () {},
        onAnalyticsEvent: (e, p) => emitted.add((event: e, props: p)),
      ),
    ));
    await tester.pump();

    // Dismissible soft gate → has a "maybe later" style secondary.
    expect(find.text('Unlock unlimited'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
  });

  testWidgets('fires trial_paywall_surfaced on show with the soft placement',
      (tester) async {
    await tester.pumpWidget(host(
      ReverseTrialExpiredSheet(
        onUpgrade: () {},
        onDismiss: () {},
        onAnalyticsEvent: (e, p) => emitted.add((event: e, props: p)),
      ),
    ));
    await tester.pump();

    final surfaced = emitted
        .where((e) => e.event == AnalyticsEvents.trialPaywallSurfaced)
        .toList();
    expect(surfaced, hasLength(1),
        reason: 'the Day-3 gate view fires trial_paywall_surfaced once');
    expect(surfaced.single.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementPostTourSoft);
    expect(surfaced.single.props[AnalyticsEvents.propHardGate], false);
  });

  testWidgets('fires soft_gate_dismissed when the secondary CTA is tapped',
      (tester) async {
    var dismissed = false;
    await tester.pumpWidget(host(
      ReverseTrialExpiredSheet(
        onUpgrade: () {},
        onDismiss: () => dismissed = true,
        onAnalyticsEvent: (e, p) => emitted.add((event: e, props: p)),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Maybe later'));
    await tester.pump();

    expect(dismissed, isTrue);
    final dismiss = emitted
        .where((e) => e.event == AnalyticsEvents.softGateDismissed)
        .toList();
    expect(dismiss, hasLength(1));
    expect(dismiss.single.props[AnalyticsEvents.propPlacement],
        AnalyticsEvents.placementPostTourSoft);
  });

  testWidgets('invokes onUpgrade when the primary CTA is tapped',
      (tester) async {
    var upgraded = false;
    await tester.pumpWidget(host(
      ReverseTrialExpiredSheet(
        onUpgrade: () => upgraded = true,
        onDismiss: () {},
        onAnalyticsEvent: (e, p) => emitted.add((event: e, props: p)),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Unlock unlimited'));
    await tester.pump();
    expect(upgraded, isTrue);
  });
}
