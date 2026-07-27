import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/beat_reveal/sacred_canvas_threshold.dart';

/// Counts how many times the canvas tree has been *constructed from scratch*.
/// The threshold must keep one element alive across a whole transition, so a
/// completed enter leaves this at 1. Without stable keys it lands on 2 and the
/// canvas visibly restarts the moment the bloom finishes.
int _canvasInits = 0;

class _CanvasBody extends StatefulWidget {
  const _CanvasBody();

  @override
  State<_CanvasBody> createState() => _CanvasBodyState();
}

class _CanvasBodyState extends State<_CanvasBody> {
  @override
  void initState() {
    super.initState();
    _canvasInits++;
  }

  @override
  Widget build(BuildContext context) => const Text('canvas');
}

/// Same idea as [_CanvasBody], for the surface side: a reversed enter must not
/// remount the cream tree either.
int _surfaceInits = 0;

class _SurfaceBody extends StatefulWidget {
  const _SurfaceBody();

  @override
  State<_SurfaceBody> createState() => _SurfaceBodyState();
}

class _SurfaceBodyState extends State<_SurfaceBody> {
  @override
  void initState() {
    super.initState();
    _surfaceInits++;
  }

  @override
  Widget build(BuildContext context) => const Text('surface');
}

Widget _host({
  required bool onCanvas,
  Offset? origin,
  bool reduceMotion = false,
}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: SacredCanvasThreshold(
            onCanvas: onCanvas,
            origin: origin,
            child: onCanvas ? const _CanvasBody() : const _SurfaceBody(),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    _canvasInits = 0;
    _surfaceInits = 0;
  });

  testWidgets('idle wraps the child in no clip or opacity layer', (t) async {
    await t.pumpWidget(_host(onCanvas: true));
    await t.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SacredCanvasThreshold),
        matching: find.byType(ClipPath),
      ),
      findsNothing,
      reason: 'an idle canvas must not pay for a saveLayer all session',
    );
    expect(
      find.descendant(
        of: find.byType(SacredCanvasThreshold),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('enter holds both trees, then unmounts the surface', (t) async {
    await t.pumpWidget(_host(onCanvas: false));
    expect(find.text('surface'), findsOneWidget);

    await t.pumpWidget(_host(onCanvas: true));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('surface'), findsOneWidget,
        reason: 'the cream tree stays beneath the growing bloom');
    expect(find.text('canvas'), findsOneWidget);

    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('surface'), findsNothing);
    expect(find.text('canvas'), findsOneWidget);
  });

  testWidgets('enter does not rebuild the canvas tree on completion', (t) async {
    await t.pumpWidget(_host(onCanvas: false));
    await t.pumpWidget(_host(onCanvas: true));
    await t.pumpAndSettle();

    expect(_canvasInits, 1);
  });

  testWidgets('exit holds the canvas above the surface, then unmounts it',
      (t) async {
    await t.pumpWidget(_host(onCanvas: true));
    await t.pumpAndSettle();

    await t.pumpWidget(_host(onCanvas: false));
    await t.pump(const Duration(milliseconds: 150));
    expect(find.text('canvas'), findsOneWidget);
    expect(find.text('surface'), findsOneWidget);

    await t.pump(const Duration(milliseconds: 350));
    expect(find.text('canvas'), findsNothing);
    expect(find.text('surface'), findsOneWidget);
  });

  testWidgets('reduced motion never clips and settles inside 150ms', (t) async {
    await t.pumpWidget(_host(onCanvas: false, reduceMotion: true));
    await t.pumpWidget(_host(onCanvas: true, reduceMotion: true));

    await t.pump(const Duration(milliseconds: 40));
    expect(
      find.descendant(
        of: find.byType(SacredCanvasThreshold),
        matching: find.byType(ClipPath),
      ),
      findsNothing,
      reason: 'reduced motion is a plain fade — no bloom geometry',
    );

    await t.pump(const Duration(milliseconds: 160));
    expect(find.text('surface'), findsNothing);
  });

  testWidgets(
      'reversing an enter mid-bloom returns to the surface without a full-screen flash',
      (t) async {
    await t.pumpWidget(_host(onCanvas: false));
    await t.pumpWidget(_host(onCanvas: true));
    await t.pump(const Duration(milliseconds: 250)); // mid-bloom

    await t.pumpWidget(_host(onCanvas: false)); // reverse mid-flight

    // The frame right after the reversal begins must still be shrinking the
    // bloom, not have snapped to the exit stack's bare opacity fade.
    await t.pump(const Duration(milliseconds: 16));
    expect(
      find.descendant(
        of: find.byType(SacredCanvasThreshold),
        matching: find.byType(ClipPath),
      ),
      findsOneWidget,
      reason:
          'a reversed enter keeps shrinking the bloom geometry, it does not '
          'jump to a full-screen opaque canvas that then fades',
    );

    await t.pumpAndSettle();
    expect(find.text('canvas'), findsNothing);
    expect(find.text('surface'), findsOneWidget);
  });

  testWidgets('a reversal that is itself reversed lands on the canvas',
      (t) async {
    // enter → flip back → flip forward again, all mid-flight. The controller
    // changes direction twice without restarting, so the tree that ends up
    // displayed must still match the final flag.
    await t.pumpWidget(_host(onCanvas: false));
    await t.pumpWidget(_host(onCanvas: true));
    await t.pump(const Duration(milliseconds: 250));

    await t.pumpWidget(_host(onCanvas: false));
    await t.pump(const Duration(milliseconds: 80));

    await t.pumpWidget(_host(onCanvas: true));
    await t.pumpAndSettle();

    expect(find.text('canvas'), findsOneWidget);
    expect(find.text('surface'), findsNothing);
    expect(_canvasInits, 1, reason: 'and without remounting the canvas');
  });

  testWidgets('reversing unwinds the bloom in place rather than restarting',
      (t) async {
    await t.pumpWidget(_host(onCanvas: false));
    await t.pumpWidget(_host(onCanvas: true));
    await t.pump(const Duration(milliseconds: 250)); // mid-bloom, ~35% of 700ms

    await t.pumpWidget(_host(onCanvas: false)); // reverse mid-flight

    // A reversal from t≈0.35 unwinds over ≈0.35×700≈245ms (or less, if the
    // fix rides the shorter 400ms exit duration instead) — either way well
    // under a fresh 400ms exit restarted from t=0, which would still have the
    // canvas mounted at the 300ms mark.
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('canvas'), findsNothing,
        reason: 'reversing in place settles faster than restarting a fresh exit would');
    expect(find.text('surface'), findsOneWidget);
  });

  // A GlobalKey-identity invariant, not a reversal regression test: it holds
  // both before and after the reversal fix below, because the surface's
  // element identity was never the broken part — see the fix commit.
  testWidgets('the surface tree keeps its element identity across a reversal',
      (t) async {
    await t.pumpWidget(_host(onCanvas: false));
    await t.pumpWidget(_host(onCanvas: true));
    await t.pump(const Duration(milliseconds: 250)); // mid-bloom

    await t.pumpWidget(_host(onCanvas: false)); // reverse mid-flight
    await t.pumpAndSettle();

    expect(_surfaceInits, 1);
  });
}
