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
            child: onCanvas ? const _CanvasBody() : const Text('surface'),
          ),
        ),
      ),
    );

void main() {
  setUp(() => _canvasInits = 0);

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
}
