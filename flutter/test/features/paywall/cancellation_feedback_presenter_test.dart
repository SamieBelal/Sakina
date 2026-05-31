import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/cancellation_feedback_presenter.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/cancellation_feedback_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Captures submit/dismiss calls without touching Supabase.
class _SpyService extends CancellationFeedbackService {
  _SpyService() : super(sync: FakeSupabaseSyncService(userId: 'u1'));

  int submits = 0;
  int dismisses = 0;

  @override
  Future<void> submit(CancellationContext context,
      {CancellationReason? reason, String? reasonText}) async {
    submits++;
  }

  @override
  Future<void> dismiss(CancellationContext context) async {
    dismisses++;
  }
}

void main() {
  late _SpyService service;

  CancellationContext ctx() => CancellationContext(
        expiresAt: DateTime.utc(2026, 6, 15, 10),
        source: CancellationSource.inAppReactive,
        periodType: 'normal',
      );

  Widget host() => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => presentCancellationFeedback(
                context,
                cancellation: ctx(),
                service: service,
                analytics: AnalyticsService(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  setUp(() => service = _SpyService());

  testWidgets('Submit records a submission, not a dismissal', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Too expensive'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(service.submits, 1);
    expect(service.dismisses, 0);
  });

  testWidgets('Skip records a dismissal', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(service.dismisses, 1);
    expect(service.submits, 0);
  });

  testWidgets('tap-outside (no choice) is recorded as an implicit dismissal',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sorry to see you go'), findsOneWidget);

    // Tap the scrim above the sheet — closes it with no Submit/Skip.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Sorry to see you go'), findsNothing); // closed
    expect(service.dismisses, 1); // implicit skip recorded → no re-nag
    expect(service.submits, 0);
  });
}
