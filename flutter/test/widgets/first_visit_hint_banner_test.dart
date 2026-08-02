import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/services/first_visit_hint_service.dart';
import 'package:sakina/widgets/first_visit_hint/first_visit_hint_banner.dart';

/// F3 — the banner half. The load-bearing property is what it does NOT do: it
/// dims nothing, absorbs nothing, and leaves no way to get stuck. The
/// "non-blocking" tests below are the ones that stop this drifting back into a
/// coachmark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hint = FirstVisitHintId.reflect;

  /// Past guardrail 3, so the banner's own behaviour is what is under test.
  void seedEligible() {
    SharedPreferences.setMockInitialValues({
      firstVisitHintSessionOrdinalBaseKey: 4,
    });
  }

  setUp(() {
    FirstVisitHintService.debugResetSession();
    FirstVisitHintService.debugUserIdResolver = () => null;
    seedEligible();
  });

  /// A screen with a live control sitting directly beneath the banner, so
  /// "the tap still reached the app" is observable rather than asserted.
  Widget harness({
    required VoidCallback onTapUnderneath,
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const FirstVisitHintBanner(hint: hint),
              ElevatedButton(
                onPressed: onTapUnderneath,
                child: const Text('Underneath'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('appears on a first visit and reads its own copy',
      (tester) async {
    await tester.pumpWidget(harness(onTapUnderneath: () {}));
    await tester.pumpAndSettle();

    expect(find.text(hint.message), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('takes no space at all when it is not eligible', (tester) async {
    SharedPreferences.setMockInitialValues({}); // first session → suppressed

    await tester.pumpWidget(harness(onTapUnderneath: () {}));
    await tester.pumpAndSettle();

    expect(find.text(hint.message), findsNothing);
    expect(
      tester.getSize(find.byType(FirstVisitHintBanner)),
      Size.zero,
    );
  });

  testWidgets('never comes back on a second visit', (tester) async {
    await tester.pumpWidget(harness(onTapUnderneath: () {}));
    await tester.pumpAndSettle();
    expect(find.text(hint.message), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    FirstVisitHintService.debugResetSession(); // a later session

    await tester.pumpWidget(harness(onTapUnderneath: () {}));
    await tester.pumpAndSettle();
    expect(find.text(hint.message), findsNothing);
  });

  group('non-blocking', () {
    testWidgets('a tap on the control beneath it still reaches that control',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(harness(onTapUnderneath: () => taps++));
      await tester.pumpAndSettle();
      expect(find.text(hint.message), findsOneWidget);

      await tester.tap(find.text('Underneath'));
      await tester.pumpAndSettle();

      // The tap did its real job *and* dismissed the hint. Both, not either.
      expect(taps, 1);
      expect(find.text(hint.message), findsNothing);
    });

    testWidgets('the control keeps working after the hint is gone',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(harness(onTapUnderneath: () => taps++));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Underneath'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Underneath'));
      await tester.pumpAndSettle();

      expect(taps, 2);
    });

    testWidgets('installs no barrier, absorber or scrim anywhere in the tree',
        (tester) async {
      // Counted against a baseline rather than expected to be zero: a
      // MaterialApp route ships its own ModalBarrier. What must not change is
      // the count — including via an overlay entry, which would never show up
      // as a descendant of the banner itself.
      int countBlockers() =>
          tester.widgetList(find.byType(ModalBarrier)).length +
          tester.widgetList(find.byType(AbsorbPointer)).length +
          tester.widgetList(find.byType(IgnorePointer)).length +
          tester.widgetList(find.byType(BackdropFilter)).length;

      SharedPreferences.setMockInitialValues({}); // suppressed → baseline
      await tester.pumpWidget(harness(onTapUnderneath: () {}));
      await tester.pumpAndSettle();
      expect(find.text(hint.message), findsNothing);
      final baseline = countBlockers();

      await tester.pumpWidget(const SizedBox.shrink());
      FirstVisitHintService.debugResetSession();
      seedEligible();

      await tester.pumpWidget(harness(onTapUnderneath: () {}));
      await tester.pumpAndSettle();
      expect(find.text(hint.message), findsOneWidget);
      expect(countBlockers(), baseline);

      // Nothing about it is bigger than the column it was dropped into.
      final banner = tester.getSize(find.byType(FirstVisitHintBanner));
      final screen = tester.getSize(find.byType(Scaffold));
      expect(banner.height, lessThan(screen.height));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('offers no skip, no step counter and no next control',
        (tester) async {
      await tester.pumpWidget(harness(onTapUnderneath: () {}));
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsNothing);
      expect(find.textContaining('Skip'), findsNothing);
      expect(find.textContaining('Next'), findsNothing);
      expect(find.textContaining(RegExp(r'\d\s*of\s*\d')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('dismissal', () {
    testWidgets('fades itself out if the user never touches it',
        (tester) async {
      await tester.pumpWidget(harness(onTapUnderneath: () {}));
      await tester.pumpAndSettle();
      expect(find.text(hint.message), findsOneWidget);

      // Still there a moment before the deadline...
      await tester.pump(firstVisitHintAutoFade - const Duration(seconds: 1));
      expect(find.text(hint.message), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(hint.message), findsNothing);
    });

    testWidgets('a tap anywhere on screen dismisses it', (tester) async {
      await tester.pumpWidget(harness(onTapUnderneath: () {}));
      await tester.pumpAndSettle();

      // Empty space, far from both the banner and the button.
      await tester.tapAt(const Offset(200, 600));
      await tester.pumpAndSettle();

      expect(find.text(hint.message), findsNothing);
    });

    testWidgets('collapses to nothing rather than leaving a gap',
        (tester) async {
      await tester.pumpWidget(harness(onTapUnderneath: () {}));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 600));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(FirstVisitHintBanner)), Size.zero);
    });
  });

  group('reduce motion', () {
    testWidgets('shows without animating, and still dismisses itself',
        (tester) async {
      await tester
          .pumpWidget(harness(onTapUnderneath: () {}, disableAnimations: true));
      await tester.pump(); // claim resolves
      await tester.pump();

      expect(find.text(hint.message), findsOneWidget);

      await tester.pump(firstVisitHintAutoFade);
      await tester.pump();
      expect(find.text(hint.message), findsNothing);
    });
  });

  testWidgets('is a cream card with a hairline border and no shadow',
      (tester) async {
    await tester.pumpWidget(harness(onTapUnderneath: () {}));
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FirstVisitHintBanner),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.color, AppColors.surfaceLight);
    expect(decoration.boxShadow, anyOf(isNull, isEmpty));
    expect(decoration.border, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaves no pending timer behind when it is torn down early',
      (tester) async {
    await tester.pumpWidget(harness(onTapUnderneath: () {}));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(firstVisitHintAutoFade * 2);
    // Reaching here without the binding reporting a pending timer or a
    // setState-after-dispose is the assertion.
  });
}
