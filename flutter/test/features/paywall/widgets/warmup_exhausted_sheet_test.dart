import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('WarmupExhaustedSheet', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.byType(WarmupExhaustedSheet), findsOneWidget);
    });

    final cases = <GatedFeature, String>{
      GatedFeature.reflect: "You've completed your free reflections",
      GatedFeature.builtDua: "You've built your free duas",
      GatedFeature.discoverName: "You've discovered your free Names",
    };

    for (final entry in cases.entries) {
      testWidgets('renders correct headline for ${entry.key}', (tester) async {
        await tester.pumpWidget(
          _wrap(
            WarmupExhaustedSheet(
              feature: entry.key,
              onUpgrade: () {},
              onDismiss: () {},
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
        expect(
          find.text("From tomorrow you'll get one a day. Or unlock unlimited now."),
          findsOneWidget,
        );
      });
    }

    testWidgets('renders primary and secondary CTAs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text('Unlock unlimited'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('tapping primary invokes onUpgrade', (tester) async {
      var upgraded = 0;
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.builtDua,
            onUpgrade: () => upgraded++,
            onDismiss: () {},
          ),
        ),
      );
      await tester.tap(find.text('Unlock unlimited'));
      await tester.pump();
      expect(upgraded, 1);
    });

    testWidgets('tapping secondary invokes onDismiss', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.discoverName,
            onUpgrade: () {},
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.text('Maybe later'));
      await tester.pump();
      expect(dismissed, 1);
    });
  });
}
