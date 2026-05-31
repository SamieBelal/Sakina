import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/cancellation_feedback_sheet.dart';
import 'package:sakina/services/cancellation_feedback_service.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('trial copy when isTrial = true', (tester) async {
    await tester.pumpWidget(host(CancellationFeedbackSheet(
      isTrial: true,
      onSubmit: (_, __) {},
      onSkip: () {},
    )));
    expect(find.text('Before your trial ends'), findsOneWidget);
    expect(find.text('Sorry to see you go'), findsNothing);
  });

  testWidgets('paid copy when isTrial = false', (tester) async {
    await tester.pumpWidget(host(CancellationFeedbackSheet(
      isTrial: false,
      onSubmit: (_, __) {},
      onSkip: () {},
    )));
    expect(find.text('Sorry to see you go'), findsOneWidget);
  });

  testWidgets('submitting with a selected reason + text reports both',
      (tester) async {
    CancellationReason? reason;
    String? text;
    await tester.pumpWidget(host(CancellationFeedbackSheet(
      isTrial: false,
      onSubmit: (r, t) {
        reason = r;
        text = t;
      },
      onSkip: () {},
    )));

    await tester.tap(find.text('Too expensive'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'way too pricey');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(reason, CancellationReason.tooExpensive);
    expect(text, 'way too pricey');
  });

  testWidgets('submitting with nothing reports null reason and empty text',
      (tester) async {
    CancellationReason? reason = CancellationReason.other;
    String? text = 'sentinel';
    await tester.pumpWidget(host(CancellationFeedbackSheet(
      isTrial: false,
      onSubmit: (r, t) {
        reason = r;
        text = t;
      },
      onSkip: () {},
    )));

    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(reason, isNull);
    expect(text, '');
  });

  testWidgets('tapping a selected chip again deselects it', (tester) async {
    CancellationReason? reason = CancellationReason.other;
    await tester.pumpWidget(host(CancellationFeedbackSheet(
      isTrial: false,
      onSubmit: (r, _) => reason = r,
      onSkip: () {},
    )));

    await tester.tap(find.text('Not using it enough'));
    await tester.pump();
    await tester.tap(find.text('Not using it enough'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(reason, isNull);
  });

  testWidgets('Skip invokes onSkip', (tester) async {
    var skipped = false;
    await tester.pumpWidget(host(CancellationFeedbackSheet(
      isTrial: false,
      onSubmit: (_, __) {},
      onSkip: () => skipped = true,
    )));

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(skipped, isTrue);
  });

  testWidgets('show() pops the sheet then forwards the submit callback',
      (tester) async {
    CancellationReason? reason;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => CancellationFeedbackSheet.show(
              context,
              isTrial: false,
              onSubmit: (r, _) => reason = r,
              onSkip: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sorry to see you go'), findsOneWidget);

    await tester.tap(find.text('Too expensive'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(reason, CancellationReason.tooExpensive);
    expect(find.text('Sorry to see you go'), findsNothing); // popped
  });
}
