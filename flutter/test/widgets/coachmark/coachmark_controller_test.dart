import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_controller.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

class _Harness extends StatefulWidget {
  const _Harness({
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });
  final List<CoachmarkStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late final CoachmarkController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = CoachmarkController(
      steps: widget.steps,
      onComplete: widget.onComplete,
      onSkip: widget.onSkip,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.start(context));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widget.steps
          .map((s) => SizedBox(key: s.target, width: 50, height: 50))
          .toList(),
    );
  }
}

void main() {
  testWidgets('T15: 3-step sequence advances on Next', (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    final k3 = GlobalKey();
    var complete = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _Harness(
          steps: [
            CoachmarkStep(target: k1, message: 'one'),
            CoachmarkStep(target: k2, message: 'two'),
            CoachmarkStep(target: k3, message: 'three'),
          ],
          onComplete: () => complete++,
          onSkip: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    expect(find.textContaining('one'), findsOneWidget);

    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    expect(find.textContaining('two'), findsOneWidget);

    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    expect(find.textContaining('three'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(complete, 1);
  });

  testWidgets('T16: Skip dismisses + calls onSkip', (tester) async {
    final k1 = GlobalKey();
    var skip = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _Harness(
          steps: [CoachmarkStep(target: k1, message: 'only')],
          onComplete: () {},
          onSkip: () => skip++,
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    await tester.tap(find.text('Skip tour'));
    await tester.pump();
    expect(skip, 1);
    // The Overlay entry should be gone (no tooltip in tree)
    expect(find.textContaining('only'), findsNothing);
  });

  testWidgets('T17: dispose clears overlay mid-sequence (no crash)',
      (tester) async {
    final k1 = GlobalKey();
    final k2 = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _Harness(
          steps: [
            CoachmarkStep(target: k1, message: 'one'),
            CoachmarkStep(target: k2, message: 'two'),
          ],
          onComplete: () {},
          onSkip: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    // Replace with empty widget — disposes harness which disposes controller
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    // No exception thrown
  });
}
