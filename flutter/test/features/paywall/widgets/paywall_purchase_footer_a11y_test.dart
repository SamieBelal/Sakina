import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/paywall/widgets/paywall_purchase_footer.dart';

/// Restore / Terms / Privacy are the three controls on this screen that Apple
/// review, the law, and a user trying to undo a charge all depend on. They
/// were the smallest targets on it.
///
/// `minimumSize: Size.zero` + `MaterialTapTargetSize.shrinkWrap` removed the
/// 48dp floor Material gives every button by default, leaving ~28pt of height
/// — and the surrounding `FittedBox(scaleDown)` could shrink even that on a
/// narrow phone, while also scaling accessibility text DOWN instead of
/// letting it grow.
Widget _wrap(Widget child, {double width = 390, double textScale = 1.0}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    ),
  );
}

PaywallPurchaseFooter _footer() => PaywallPurchaseFooter(
      ctaLabel: 'Subscribe',
      termsLine: '\$49.99 a year. Cancel anytime.',
      onPurchase: () {},
      onRestore: () {},
      onOpenTerms: () {},
      onOpenPrivacy: () {},
    );

void main() {
  /// The iOS Human Interface Guidelines minimum. Material's own default is
  /// 48dp; 44 is the weaker of the two bars and this still failed it.
  const minTarget = 44.0;

  final legalLabels = <String>[
    AppStrings.paywallRestore,
    AppStrings.paywallTerms,
    AppStrings.paywallPrivacy,
  ];

  for (final width in <double>[390, 320]) {
    testWidgets('legal links meet the 44pt touch target at ${width}pt wide',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(_footer(), width: width));
      await tester.pumpAndSettle();

      for (final label in legalLabels) {
        final finder = find.widgetWithText(InkWell, label);
        expect(finder, findsWidgets,
            reason: '"$label" must render as a tappable control');

        final size = tester.getSize(finder.first);
        expect(size.height, greaterThanOrEqualTo(minTarget),
            reason: '"$label" is ${size.height}pt tall at ${width}pt wide — '
                'below the $minTarget pt minimum. Restore in particular is an '
                'App Store review item and the only way a user undoes a '
                'mis-charge.');
        expect(size.width, greaterThanOrEqualTo(minTarget),
            reason: '"$label" is ${size.width}pt wide at ${width}pt wide');
      }
    });
  }

  testWidgets('accessibility text scaling grows the legal row, never shrinks it',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(_footer(), textScale: 1.0));
    await tester.pumpAndSettle();
    final baseline =
        tester.getSize(find.widgetWithText(InkWell, AppStrings.paywallTerms).first);

    await tester.pumpWidget(_wrap(_footer(), textScale: 2.0));
    await tester.pumpAndSettle();
    final scaled =
        tester.getSize(find.widgetWithText(InkWell, AppStrings.paywallTerms).first);

    expect(scaled.height, greaterThanOrEqualTo(baseline.height),
        reason: 'a user who doubled their text size must not get a SMALLER '
            'target — that is what FittedBox(scaleDown) around the whole row '
            'produced, and it inverts the accessibility setting');
  });
}
