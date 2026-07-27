import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/beat_reveal/beat_progress_bar.dart';

/// The horizontal scale the entrance is currently applying to the bar.
/// `storage[0]` is the x scale of the diagonal matrix the widget builds.
double _sweep(WidgetTester t) {
  final transform = t.widget<Transform>(
    find.descendant(
      of: find.byType(BeatProgressBar),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.storage[0];
}

Widget _host({required int currentIndex, bool reduceMotion = false}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: Scaffold(
            body: BeatProgressBar(count: 5, currentIndex: currentIndex),
          ),
        ),
      ),
    );

void main() {
  testWidgets('sweeps open on first mount and is static afterwards', (t) async {
    await t.pumpWidget(_host(currentIndex: 0));

    // First frame: the hairline has no width yet.
    await t.pump();
    expect(_sweep(t), lessThan(0.5));

    await t.pumpAndSettle();
    expect(_sweep(t), 1.0);

    // Advancing a beat must not replay the sweep.
    await t.pumpWidget(_host(currentIndex: 1));
    await t.pump();
    expect(_sweep(t), 1.0);
  });

  testWidgets('reduced motion mounts the bar fully open', (t) async {
    await t.pumpWidget(_host(currentIndex: 0, reduceMotion: true));
    await t.pump();

    expect(_sweep(t), 1.0,
        reason: 'no sweep to watch when the platform asks for reduced motion');
  });
}
