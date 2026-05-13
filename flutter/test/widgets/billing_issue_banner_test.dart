import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/widgets/billing_issue_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders nothing when billing issue is null',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStateProvider.overrideWith(
            (ref) async => (isPremium: true, billingIssueAt: null),
          ),
        ],
        child: const MaterialApp(home: BillingIssueBanner()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(
      find.text("We couldn't process your last payment"),
      findsNothing,
    );
  });

  testWidgets('renders the banner when billing issue timestamp is present',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStateProvider.overrideWith(
            (ref) async => (
              isPremium: true,
              billingIssueAt: '2026-04-17T12:00:00.000Z',
            ),
          ),
        ],
        child: const MaterialApp(home: BillingIssueBanner()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.text("We couldn't process your last payment"),
      findsOneWidget,
    );
  });

  testWidgets('renders nothing while the provider is still loading',
      (tester) async {
    final completer = Completer<PremiumState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumStateProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: BillingIssueBanner()),
      ),
    );
    // Pump one frame, no settle — provider still loading.
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsNothing);

    // Resolve so the widget tree can tear down cleanly.
    completer.complete((isPremium: false, billingIssueAt: null));
    await tester.pumpAndSettle();
  });
}
