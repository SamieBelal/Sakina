import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/animated_xp_bar.dart';

void main() {
  testWidgets('AnimatedXpBar tweens fill when progress prop changes',
      (tester) async {
    double progress = 0.2;
    late StateSetter setOuter;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (_, setState) {
          setOuter = setState;
          return Scaffold(body: AnimatedXpBar(progress: progress));
        },
      ),
    ));

    final initial = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(initial.value, 0.2);

    setOuter(() => progress = 0.6);
    // First pump triggers rebuild → didUpdateWidget → controller.forward().
    await tester.pump();
    // Second pump advances the clock by 100ms so the animation is in flight.
    await tester.pump(const Duration(milliseconds: 100));

    final mid = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    // Tween in flight: > 0.2, < 0.6.
    expect(mid.value, greaterThan(0.2));
    expect(mid.value, lessThan(0.6));

    await tester.pump(const Duration(milliseconds: 600));
    final end = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(end.value, closeTo(0.6, 0.001));
  });

  testWidgets('AnimatedXpBar shows floating "+N XP" when lastGained changes from 0',
      (tester) async {
    int gained = 0;
    late StateSetter setOuter;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (_, setState) {
          setOuter = setState;
          return Scaffold(
            body: AnimatedXpBar(progress: 0.2, lastGained: gained),
          );
        },
      ),
    ));

    expect(find.textContaining('+'), findsNothing);

    setOuter(() => gained = 15);
    // First pump triggers rebuild → didUpdateWidget → starts Timer.
    await tester.pump();
    // Second pump advances clock so animation is running.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('+15 XP'), findsOneWidget);

    // Advance past the 2050ms hide-timer so the widget is removed from tree.
    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('+15 XP'), findsNothing);
  });
}
