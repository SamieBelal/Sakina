import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/features/duas/screens/duas_screen.dart';

/// Isolated coverage of the extracted save-heart. The save→fill feedback is a
/// self-contained AnimatedSwitcher pop, so we can verify the icon states, the
/// color, the transition, and the tap without driving the whole build pipeline.
void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('renders the outline heart (tertiary) when not saved',
      (tester) async {
    await tester.pumpWidget(
      host(RelatedDuaHeart(isSaved: false, onTap: () {})),
    );

    expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.favorite_outline)).color,
      AppColors.textTertiaryLight,
    );
  });

  testWidgets('renders the filled heart (primary) when saved', (tester) async {
    await tester.pumpWidget(
      host(RelatedDuaHeart(isSaved: true, onTap: () {})),
    );
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.favorite)).color,
      AppColors.primary,
    );
  });

  testWidgets('tapping fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(RelatedDuaHeart(isSaved: false, onTap: () => taps++)),
    );

    await tester.tap(find.byType(RelatedDuaHeart));
    expect(taps, 1);
  });

  testWidgets('flipping isSaved animates outline → filled (the pop)',
      (tester) async {
    var saved = false;
    late StateSetter setOuter;
    await tester.pumpWidget(host(
      StatefulBuilder(builder: (_, setState) {
        setOuter = setState;
        return RelatedDuaHeart(isSaved: saved, onTap: () {});
      }),
    ));

    expect(find.byIcon(Icons.favorite_outline), findsOneWidget);

    setOuter(() => saved = true);
    await tester.pump(); // kick off the AnimatedSwitcher transition
    // A ScaleTransition drives the pop while switching.
    expect(find.byType(ScaleTransition), findsWidgets);

    await tester.pump(const Duration(milliseconds: 300)); // settle
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline), findsNothing);
  });
}
