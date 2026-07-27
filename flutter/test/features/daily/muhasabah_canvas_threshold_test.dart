import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/beat_reveal/sacred_canvas_threshold.dart';

/// Stands in for the muḥāsabah screen's shape: a cream tree with a CTA that
/// both fires its work and flips the canvas flag on the same frame.
class _Harness extends StatefulWidget {
  const _Harness({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final GlobalKey _ctaKey = GlobalKey();
  Offset? _origin;
  bool _onCanvas = false;

  void _captureOrigin() {
    final box = _ctaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() => _origin = box.localToGlobal(box.size.center(Offset.zero)));
  }

  @override
  Widget build(BuildContext context) {
    return SacredCanvasThreshold(
      onCanvas: _onCanvas,
      origin: _origin,
      child: _onCanvas
          ? const Scaffold(body: Center(child: Text('canvas')))
          : Scaffold(
              body: Center(
                child: GestureDetector(
                  key: _ctaKey,
                  onTap: () {
                    _captureOrigin();
                    widget.onStart();
                    setState(() => _onCanvas = true);
                  },
                  child: const Text('Go Deeper'),
                ),
              ),
            ),
    );
  }
}

void main() {
  testWidgets('the CTA fires its work on the tap frame, not after the bloom',
      (t) async {
    var starts = 0;
    await t.pumpWidget(MaterialApp(home: _Harness(onStart: () => starts++)));

    await t.tap(find.text('Go Deeper'));
    await t.pump(); // one frame only — the bloom has barely begun

    expect(starts, 1, reason: 'the request must not wait on the animation');
    expect(find.text('Go Deeper'), findsOneWidget,
        reason: 'the cream tree is still beneath the growing bloom');

    await t.pumpAndSettle();
    expect(starts, 1, reason: 'and it must not fire a second time');
    expect(find.text('canvas'), findsOneWidget);
    expect(find.text('Go Deeper'), findsNothing);
  });

  testWidgets('a second tap mid-bloom does not re-fire the work', (t) async {
    // The outgoing cream tree stays mounted beneath the growing bloom, and
    // neither Opacity nor the canvas's ClipPath takes it out of the hit-test
    // path. Without the threshold swallowing input for the transition, the CTA
    // is still tappable and startDeeper() runs twice.
    var starts = 0;
    await t.pumpWidget(MaterialApp(home: _Harness(onStart: () => starts++)));

    await t.tap(find.text('Go Deeper'));
    await t.pump();
    expect(starts, 1);

    // The button is demonstrably still findable mid-bloom — tap it again.
    expect(find.text('Go Deeper'), findsOneWidget);
    await t.tap(find.text('Go Deeper'), warnIfMissed: false);
    await t.pump();

    expect(starts, 1,
        reason: 'a transition must not accept input for the tree it is leaving');

    await t.pumpAndSettle();
    expect(find.text('canvas'), findsOneWidget);
  });
}

// Deliberately not tested here: that muhasabah_screen.dart actually passes the
// pill's centre as the origin. Standing the real screen up needs the whole
// dailyLoopProvider graph (Supabase, gating, quests), and a harness-level test
// of `localToGlobal` would only be exercising Flutter, not the wiring. The
// anchored origin is verified on device — see the QA walkthrough in
// docs/superpowers/plans/2026-07-27-sacred-canvas-threshold.md, item 1.
