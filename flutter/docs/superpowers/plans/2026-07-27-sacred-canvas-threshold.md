# Sacred Canvas Threshold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-frame hard cut into and out of the emerald sacred canvas with a shared 700ms bloom in / 400ms dissolve out, on all three surfaces that use the canvas.

**Architecture:** One new widget, `SacredCanvasThreshold`, wraps each surface's top-level `build()` and animates between the cream tree and the canvas tree. It holds both trees mounted for the duration of a transition and drops the stale one on completion; two `GlobalKey`s keep each tree's element identity stable across the slot/depth changes so neither loses state mid-transition. Two smaller fixes close the remaining pops inside the flow: a fade between `BeatRevealFlow`'s loading and ready states, and a one-shot hairline sweep on the first mount of each segmented progress bar.

**Tech Stack:** Flutter, `flutter_animate` (already a dependency, used by the existing canvas motion), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-07-27-sacred-canvas-threshold-design.md`

**Worktree:** `/Users/appleuser/CS Work/Repos/sakina/.worktrees/sacred-canvas-threshold` on `feat/sacred-canvas-threshold`. `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` have already been run; baseline is 86 tests passing across `test/widgets/beat_reveal_flow_test.dart test/features/reflect test/features/duas`.

---

## File Structure

**Created:**
- `lib/widgets/beat_reveal/sacred_canvas_threshold.dart` — the threshold widget and its bloom clipper. Single responsibility: animate between two full-screen trees. Knows nothing about muḥāsabah, reflect, duas, or the AI lifecycle.
- `test/widgets/sacred_canvas_threshold_test.dart` — threshold behaviour in isolation.

**Modified:**
- `lib/features/daily/screens/muhasabah_screen.dart` — wrap `build()`; capture the *Go Deeper* pill's centre as the bloom origin.
- `lib/features/reflect/screens/reflect_screen.dart` — wrap `build()`, centre origin.
- `lib/features/duas/screens/duas_screen.dart` — wrap `build()`, centre origin.
- `lib/widgets/beat_reveal/beat_reveal_flow.dart` — fade `_body()` between statuses.
- `lib/widgets/beat_reveal/beat_progress_bar.dart` — one-shot hairline sweep.
- `lib/features/duas/widgets/built_dua_section_controls.dart` — same sweep for `DuaSegmentedProgress`.
- `test/widgets/beat_reveal_flow_test.dart` — status-fade test.
- `DESIGN.md` — §5 threshold timings.

---

### Task 1: The `SacredCanvasThreshold` widget

This is the whole of the new behaviour. Everything after this task is wiring.

**Files:**
- Create: `lib/widgets/beat_reveal/sacred_canvas_threshold.dart`
- Test: `test/widgets/sacred_canvas_threshold_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/widgets/sacred_canvas_threshold_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widgets/sacred_canvas_threshold_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'sakina' ... sacred_canvas_threshold.dart` / "Target of URI doesn't exist". The file does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/widgets/beat_reveal/sacred_canvas_threshold.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motion timings for crossing into and out of the emerald sacred canvas.
/// See docs/superpowers/specs/2026-07-27-sacred-canvas-threshold-design.md and
/// DESIGN.md §5.
abstract final class SacredCanvasThresholdDurations {
  /// Emerald bloom in. Long enough to read as a doorway; it plays over the AI
  /// wait on the muḥāsabah path, so it costs no perceived latency.
  static const enter = Duration(milliseconds: 700);

  /// Dissolve out. Deliberately not a contracting bloom — rewinding the
  /// entrance reads as an undo, which is wrong straight after "Ameen".
  static const exit = Duration(milliseconds: 400);

  /// Both directions when the platform asks for reduced motion.
  static const reduced = Duration(milliseconds: 150);
}

/// Animates between a surface tree (warm cream) and the emerald sacred canvas.
///
/// Entering, the canvas is revealed by a circle growing from [origin] while the
/// surface fades and settles beneath it. Leaving, the canvas simply dissolves
/// over the surface. Both trees stay mounted for the duration; the stale one is
/// dropped on completion.
///
/// [origin] is in **global** coordinates, so this widget must be the full-screen
/// root of its surface for them to coincide with its own local space — which is
/// how all three hosts use it (it wraps the whole `build()` return). Null means
/// "grow from the centre of the screen", which is correct for every entry that
/// isn't driven by a tap.
class SacredCanvasThreshold extends StatefulWidget {
  const SacredCanvasThreshold({
    super.key,
    required this.onCanvas,
    required this.child,
    this.origin,
  });

  /// Whether [child] is currently the sacred canvas. Flipping this drives the
  /// transition; the host keeps owning what [child] actually is.
  final bool onCanvas;

  /// Global centre of the bloom. Null → the centre of the screen.
  final Offset? origin;

  final Widget child;

  @override
  State<SacredCanvasThreshold> createState() => _SacredCanvasThresholdState();
}

class _SacredCanvasThresholdState extends State<SacredCanvasThreshold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// The tree being replaced — a frozen snapshot of the previous [widget.child],
  /// deliberately not rebuilt while it departs. Null whenever we're idle.
  Widget? _outgoing;

  /// Direction of the in-flight transition.
  bool _entering = false;

  /// Stable identities for the two trees. Each tree keeps its own key for its
  /// whole life, so moving between stack slots (and between the wrapped
  /// transition shape and the bare idle shape) preserves its element and state
  /// instead of remounting it.
  final GlobalKey _canvasKey = GlobalKey(debugLabel: 'sacredCanvas');
  final GlobalKey _surfaceKey = GlobalKey(debugLabel: 'sacredSurface');

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _outgoing = null);
        }
      });
  }

  @override
  void didUpdateWidget(SacredCanvasThreshold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onCanvas == widget.onCanvas) return;

    _entering = widget.onCanvas;
    _outgoing = oldWidget.child;
    _controller
      ..duration = _reducedMotion
          ? SacredCanvasThresholdDurations.reduced
          : (_entering
              ? SacredCanvasThresholdDurations.enter
              : SacredCanvasThresholdDurations.exit)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The key belonging to a tree, by what that tree *is* rather than where it
  /// currently sits.
  GlobalKey _keyFor({required bool isCanvas}) =>
      isCanvas ? _canvasKey : _surfaceKey;

  @override
  Widget build(BuildContext context) {
    final outgoing = _outgoing;

    // Idle: the child, bare. No clip, no opacity, no stack — an animation that
    // has finished must cost nothing.
    if (outgoing == null) {
      return KeyedSubtree(
        key: _keyFor(isCanvas: widget.onCanvas),
        child: widget.child,
      );
    }

    final incoming = KeyedSubtree(
      key: _keyFor(isCanvas: widget.onCanvas),
      child: widget.child,
    );
    final departing = KeyedSubtree(
      key: _keyFor(isCanvas: !widget.onCanvas),
      child: outgoing,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return _entering
            ? _enterStack(departing, incoming, t)
            : _exitStack(incoming, departing, t);
      },
    );
  }

  /// Surface beneath, fading and settling; canvas above, revealed by the bloom.
  Widget _enterStack(Widget surface, Widget canvas, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 1 - t,
          child: Transform.scale(scale: 1 - (0.02 * t), child: surface),
        ),
        if (_reducedMotion)
          Opacity(opacity: t, child: canvas)
        else
          ClipPath(
            clipper: _BloomClipper(origin: widget.origin, fraction: t),
            child: canvas,
          ),
      ],
    );
  }

  /// Surface beneath, already in place; canvas above, dissolving off it.
  Widget _exitStack(Widget surface, Widget canvas, double t) {
    return Stack(
      fit: StackFit.expand,
      children: [
        surface,
        Opacity(opacity: 1 - t, child: canvas),
      ],
    );
  }
}

/// Circular reveal: a disc centred on [origin] whose radius grows with
/// [fraction], reaching the farthest corner — and so covering every pixel — at 1.
class _BloomClipper extends CustomClipper<Path> {
  const _BloomClipper({required this.origin, required this.fraction});

  final Offset? origin;
  final double fraction;

  @override
  Path getClip(Size size) {
    final centre = origin ?? Offset(size.width / 2, size.height / 2);
    return Path()
      ..addOval(
        Rect.fromCircle(center: centre, radius: _coveringRadius(centre, size) * fraction),
      );
  }

  static double _coveringRadius(Offset centre, Size size) {
    final dx = math.max(centre.dx, size.width - centre.dx);
    final dy = math.max(centre.dy, size.height - centre.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldReclip(_BloomClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.origin != origin;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/widgets/sacred_canvas_threshold_test.dart`
Expected: PASS — 5 tests, 0 failures.

- [ ] **Step 5: Run the analyzer**

Run: `flutter analyze lib/widgets/beat_reveal/sacred_canvas_threshold.dart`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/beat_reveal/sacred_canvas_threshold.dart test/widgets/sacred_canvas_threshold_test.dart
git commit -m "feat(canvas): add SacredCanvasThreshold entrance/exit motion"
```

---

### Task 2: Wire muḥāsabah (the one anchored path)

Muḥāsabah is the only surface that enters the canvas on a tap, so it is the only one that passes a real `origin`. `startDeeper()` sets `currentStep: DailyLoopStep.deeper` synchronously before its first `await` (`daily_loop_provider.dart:1097`), so the step flips on the tap frame and the bloom plays over the AI wait rather than delaying it.

**Files:**
- Modify: `lib/features/daily/screens/muhasabah_screen.dart:47-60` (state fields), `:132-146` (build), `:479-511` (the pill)
- Test: `test/features/daily/muhasabah_canvas_threshold_test.dart`

- [ ] **Step 1: Add the origin capture to the state class**

In `lib/features/daily/screens/muhasabah_screen.dart`, inside `_MuhasabahScreenState`, directly after the `_hintAdvancesKey` line (currently line 60), add:

```dart
  /// Global centre of the *Go Deeper* pill, captured on tap so the canvas
  /// blooms out of the button the user actually pressed. Stays null on every
  /// other entry path (error retry, restored state), which the threshold reads
  /// as "grow from the centre of the screen".
  final GlobalKey _goDeeperKey = GlobalKey();
  Offset? _canvasOrigin;

  void _captureGoDeeperOrigin() {
    final box = _goDeeperKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() {
      _canvasOrigin = box.localToGlobal(box.size.center(Offset.zero));
    });
  }
```

- [ ] **Step 2: Attach the key and capture on tap**

In `_buildCheckinResult`, the `TourAnchor` at line 479 currently wraps a `GestureDetector` whose `onTap` is:

```dart
              onTap: () {
                HapticFeedback.mediumImpact();
                notifier.startDeeper();
              },
```

Replace that `GestureDetector` opening so it carries the key and captures the origin before starting:

```dart
            child: GestureDetector(
              key: _goDeeperKey,
              onTap: () {
                HapticFeedback.mediumImpact();
                _captureGoDeeperOrigin();
                notifier.startDeeper();
              },
```

- [ ] **Step 3: Wrap `build()` in the threshold**

Replace lines 128-145 (the `if (state.currentStep == DailyLoopStep.deeper)` early return and the `Scaffold` that follows) with:

```dart
    // The deeper reflection runs full-screen on the emerald sacred canvas
    // (BeatRevealFlow brings its own Scaffold + chrome + back handling). The
    // canvas is entered the moment the user leaves the gacha, so the wait is
    // part of the ritual — hence we branch on `deeper` even while loading.
    // SacredCanvasThreshold animates the crossing in both directions; it must
    // stay the outermost widget so its bloom origin is in screen coordinates.
    final onCanvas = state.currentStep == DailyLoopStep.deeper;

    return SacredCanvasThreshold(
      onCanvas: onCanvas,
      origin: _canvasOrigin,
      child: onCanvas
          ? _buildBeatFlow(state, notifier)
          : Scaffold(
              backgroundColor: AppColors.backgroundLight,
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildContent(state, notifier),
                  ),
                ),
              ),
            ),
    );
```

- [ ] **Step 4: Add the import**

Add to the import block at the top of the file, keeping alphabetical order among the `package:sakina/widgets/` imports:

```dart
import 'package:sakina/widgets/beat_reveal/sacred_canvas_threshold.dart';
```

- [ ] **Step 5: Write the failing test**

Create `test/features/daily/muhasabah_canvas_threshold_test.dart`. This pins the contract that matters most — the transition must not defer the work — without standing up the whole provider graph:

```dart
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
}
```

- [ ] **Step 6: Run the test**

Run: `flutter test test/features/daily/muhasabah_canvas_threshold_test.dart`
Expected: PASS — 1 test. (It exercises `SacredCanvasThreshold` from Task 1, so it passes once the wiring compiles.)

- [ ] **Step 7: Verify the screen still analyzes and its existing tests pass**

Run: `flutter analyze lib/features/daily/screens/muhasabah_screen.dart`
Expected: "No issues found!"

Run: `flutter test test/features/daily`
Expected: PASS, no new failures versus the baseline.

- [ ] **Step 8: Commit**

```bash
git add lib/features/daily/screens/muhasabah_screen.dart test/features/daily/muhasabah_canvas_threshold_test.dart
git commit -m "feat(muhasabah): bloom into the sacred canvas from the Go Deeper pill"
```

---

### Task 3: Wire Reflect

Reflect transitions when the AI result lands, not on a tap, so it passes no origin and blooms from the centre — where its ripple loader already sits.

**Files:**
- Modify: `lib/features/reflect/screens/reflect_screen.dart:178-205`

- [ ] **Step 1: Wrap `build()` in the threshold**

Replace the block from `if (inFlow) {` through the closing `);` of the returned `GestureDetector` (currently lines 193-204) with:

```dart
    // SacredCanvasThreshold animates the crossing in both directions. No origin:
    // Reflect enters the canvas when the result lands rather than on a tap, so a
    // stored button position would be stale — the centre, where the ripple
    // loader sits, is the honest origin.
    return SacredCanvasThreshold(
      onCanvas: inFlow,
      child: inFlow
          ? _buildReflectBeatFlow(state, notifier)
          : GestureDetector(
              onTap: () => dismissKeyboard(context),
              behavior: HitTestBehavior.translucent,
              child: Scaffold(
                backgroundColor: AppColors.backgroundLight,
                body: _buildBody(state, notifier),
              ),
            ),
    );
```

- [ ] **Step 2: Add the import**

```dart
import 'package:sakina/widgets/beat_reveal/sacred_canvas_threshold.dart';
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/reflect/screens/reflect_screen.dart`
Expected: "No issues found!"

Run: `flutter test test/features/reflect`
Expected: PASS, no new failures versus the baseline.

- [ ] **Step 4: Commit**

```bash
git add lib/features/reflect/screens/reflect_screen.dart
git commit -m "feat(reflect): bloom into the sacred canvas instead of cutting"
```

---

### Task 4: Wire Build-a-Dua

`duas_screen.dart` already computes `inCanvas` at line 215 for immersive mode. Reuse it rather than deriving a second boolean — one source of truth for "is the canvas up".

Note the shape here differs from the other two: the `Scaffold` is the same in both states and the canvas lives *inside* its body, so the threshold's frozen outgoing tree is a stale `Scaffold` still describing the input screen. That works as-is; no restructuring needed.

**Files:**
- Modify: `lib/features/duas/screens/duas_screen.dart:222-229`

- [ ] **Step 1: Wrap `build()` in the threshold**

Replace the returned `GestureDetector` (currently lines 222-229) with:

```dart
    return SacredCanvasThreshold(
      onCanvas: inCanvas,
      child: GestureDetector(
        onTap: () => dismissKeyboard(context),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: _buildBuildTab(state, notifier),
        ),
      ),
    );
```

- [ ] **Step 2: Add the import**

```dart
import 'package:sakina/widgets/beat_reveal/sacred_canvas_threshold.dart';
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/duas/screens/duas_screen.dart`
Expected: "No issues found!"

Run: `flutter test test/features/duas`
Expected: PASS, no new failures versus the baseline.

- [ ] **Step 4: Commit**

```bash
git add lib/features/duas/screens/duas_screen.dart
git commit -m "feat(duas): bloom into the sacred canvas instead of cutting"
```

---

### Task 5: Dissolve `BeatRevealFlow`'s loading → ready swap

Without this the muḥāsabah entrance still ends on a hard cut: the bloom lands on `_LoadingView`, and when the AI returns, `_body()` pops straight to beat 1.

**Files:**
- Modify: `lib/widgets/beat_reveal/beat_reveal_flow.dart:186` (the `SafeArea` in `build`)
- Test: `test/widgets/beat_reveal_flow_test.dart` (add to the existing `BeatRevealFlow widget` group)

- [ ] **Step 1: Write the failing test**

Add inside the `group('BeatRevealFlow widget', ...)` block in `test/widgets/beat_reveal_flow_test.dart`:

```dart
    testWidgets('loading dissolves into the first beat rather than popping',
        (t) async {
      await t.pumpWidget(const MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.loading,
          response: null,
          onAmeen: _noop,
        ),
      ));
      await t.pump();
      expect(find.text('Preparing your reflection…'), findsOneWidget);

      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: _response(),
          onAmeen: () {},
        ),
      ));
      await t.pump(const Duration(milliseconds: 120));

      // Mid-fade both are on screen; a hard swap would have dropped the loader
      // on the first frame.
      expect(find.text('Preparing your reflection…'), findsOneWidget);

      await t.pumpAndSettle();
      expect(find.text('Preparing your reflection…'), findsNothing);
      expect(find.text('Al-Lateef'), findsOneWidget);
    });
```

Add this top-level helper next to `_response` at the bottom of the file's helper section (a `const` constructor needs a `const` callback):

```dart
void _noop() {}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/widgets/beat_reveal_flow_test.dart -n "loading dissolves"`
Expected: FAIL — `Expected: exactly one matching candidate / Actual: _TextFinder:<zero widgets>` at the mid-fade assertion, because the loader is dropped on the first frame.

- [ ] **Step 3: Implement the fade**

In `lib/widgets/beat_reveal/beat_reveal_flow.dart`, replace the `SafeArea` line inside `build` (currently line 186):

```dart
          child: SafeArea(child: _body()),
```

with:

```dart
          child: SafeArea(
            // The loading → ready swap used to pop. Fading it keeps the whole
            // entrance continuous: bloom lands on the loader, the loader
            // dissolves into beat 1.
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: _reducedMotion ? 1 : 350),
              child: KeyedSubtree(
                key: ValueKey<BeatFlowStatus>(widget.status),
                child: _body(),
              ),
            ),
          ),
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/widgets/beat_reveal_flow_test.dart`
Expected: PASS — all tests in the file, including the four pre-existing widget tests.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/beat_reveal/beat_reveal_flow.dart test/widgets/beat_reveal_flow_test.dart
git commit -m "feat(canvas): dissolve the beat flow's loading state into beat 1"
```

---

### Task 6: The gold hairline on first mount

Anchored to the progress bar's own first frame rather than to the bloom landing, because those are different moments on different paths: Reflect and Build-a-Dua enter with their bar already present, muḥāsabah enters on `loading` and has no bar yet.

**Files:**
- Modify: `lib/widgets/beat_reveal/beat_progress_bar.dart`
- Modify: `lib/features/duas/widgets/built_dua_section_controls.dart:9-37`
- Test: `test/widgets/beat_progress_bar_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widgets/beat_progress_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/beat_reveal/beat_progress_bar.dart';

/// The horizontal scale the entrance is currently applying to the bar.
/// `storage[0]` is the x scale of the diagonal matrix built in the widget.
double _sweep(WidgetTester t) {
  final transform = t.widget<Transform>(
    find.descendant(
      of: find.byType(BeatProgressBar),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.storage[0];
}

void main() {
  testWidgets('sweeps open on first mount and is static afterwards', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: BeatProgressBar(count: 5, currentIndex: 0)),
    ));

    // First frame: the hairline has no width yet.
    await t.pump();
    expect(_sweep(t), lessThan(0.5));

    await t.pumpAndSettle();
    expect(_sweep(t), 1.0);

    // Advancing a beat must not replay the sweep.
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: BeatProgressBar(count: 5, currentIndex: 1)),
    ));
    await t.pump();
    expect(_sweep(t), 1.0);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/widgets/beat_progress_bar_test.dart`
Expected: FAIL — "Found 0 widgets with type Transform" — the bar has no entrance yet.

- [ ] **Step 3: Add the sweep to `BeatProgressBar`**

`BeatProgressBar` is currently a `StatelessWidget`. Convert it so the sweep fires once per mount. Replace the whole class body in `lib/widgets/beat_reveal/beat_progress_bar.dart` (keeping the existing doc comment above it):

```dart
class BeatProgressBar extends StatefulWidget {
  final int count;
  final int currentIndex;

  const BeatProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  State<BeatProgressBar> createState() => _BeatProgressBarState();
}

class _BeatProgressBarState extends State<BeatProgressBar>
    with SingleTickerProviderStateMixin {
  /// One-shot: the bar arrives as a gold hairline that widens into the
  /// segmented track. Advancing a beat must not replay it, so this lives on the
  /// state and simply runs to completion on mount.
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    final reduce =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: reduce ? 1 : 0,
    );
    if (!reduce) _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = Row(
      children: List.generate(widget.count, (i) {
        final filled = i <= widget.currentIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == widget.count - 1 ? 0 : 5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              decoration: BoxDecoration(
                color: filled ? AppColors.secondary : AppColors.sacredTrack,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_entrance.value);
          return Opacity(
            opacity: t,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(t, 1, 1),
              child: child,
            ),
          );
        },
        child: track,
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/widgets/beat_progress_bar_test.dart`
Expected: PASS — 1 test.

- [ ] **Step 5: Give `DuaSegmentedProgress` the same treatment**

Build-a-Dua's bar is the same gold-on-`sacredTrack` idea pinned to the bottom next to the CTA. In `lib/features/duas/widgets/built_dua_section_controls.dart`, replace the `DuaSegmentedProgress` class (lines 9-37) with:

```dart
class DuaSegmentedProgress extends StatefulWidget {
  const DuaSegmentedProgress({
    super.key,
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  State<DuaSegmentedProgress> createState() => _DuaSegmentedProgressState();
}

class _DuaSegmentedProgressState extends State<DuaSegmentedProgress>
    with SingleTickerProviderStateMixin {
  /// One-shot hairline sweep on first mount, matching BeatProgressBar.
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    final reduce =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: reduce ? 1 : 0,
    );
    if (!reduce) _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (i) {
        final filled = i <= widget.current;
        return Container(
          width: 22,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: filled ? AppColors.secondary : AppColors.sacredTrack,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_entrance.value);
        return Opacity(
          opacity: t,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(t, 1, 1),
            child: child,
          ),
        );
      },
      child: track,
    );
  }
}
```

- [ ] **Step 6: Verify both**

Run: `flutter analyze lib/widgets/beat_reveal/beat_progress_bar.dart lib/features/duas/widgets/built_dua_section_controls.dart`
Expected: "No issues found!"

Run: `flutter test test/widgets/beat_reveal_flow_test.dart test/widgets/beat_progress_bar_test.dart test/features/duas`
Expected: PASS, no new failures versus the baseline.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/beat_reveal/beat_progress_bar.dart lib/features/duas/widgets/built_dua_section_controls.dart test/widgets/beat_progress_bar_test.dart
git commit -m "feat(canvas): sweep the segmented progress bars open on first mount"
```

---

### Task 7: Documentation and device QA

The clip plus two mounted trees is the only real performance risk in this change, and the simulator will not tell you the truth about it.

**Files:**
- Modify: `DESIGN.md` §5

- [ ] **Step 1: Record the timings in DESIGN.md**

In `DESIGN.md` §5, immediately after the "Other canvas timings (same file)" list, add:

```markdown
**Canvas threshold (`sacred_canvas_threshold.dart`):**
- **Enter** 700ms `easeOutCubic` — the sacred gradient blooms as a circle from the
  tapped CTA (muḥāsabah) or from screen centre (Reflect, Build-a-Dua) while the cream
  tree fades and settles `1.0 → 0.98` beneath it. The origin rule is **anchored when
  tap-driven, centre when result-driven**.
- **Exit** 400ms — the canvas dissolves over the incoming cream tree. Deliberately not
  a contracting bloom: rewinding the entrance reads as an undo, which is wrong
  straight after "Ameen".
- **Status fade** 350ms — `BeatRevealFlow`'s loading view dissolving into beat 1.
- **Progress bar** 320ms `easeOutCubic` hairline sweep on first mount, one-shot.
- **Reduced motion** collapses the threshold to a 150ms fade with no bloom geometry,
  and mounts both progress bars static.
```

- [ ] **Step 2: Run the full affected test set**

Run: `flutter test test/widgets test/features/daily test/features/reflect test/features/duas`
Expected: PASS, no new failures. Note this set is wider than the 86-test baseline taken at worktree setup (that covered `test/widgets/beat_reveal_flow_test.dart test/features/reflect test/features/duas`), so re-run it on `git stash` if you need a like-for-like comparison. Two suites fail on a clean checkout regardless of this branch — `purchase_service_premium_started` and the `find_duas` eval — so do not treat those as regressions.

- [ ] **Step 3: Run the analyzer over everything touched**

Run: `flutter analyze lib/widgets/beat_reveal lib/features/daily/screens/muhasabah_screen.dart lib/features/reflect/screens/reflect_screen.dart lib/features/duas/screens/duas_screen.dart lib/features/duas/widgets/built_dua_section_controls.dart`
Expected: "No issues found!"

- [ ] **Step 4: Commit the docs**

```bash
git add DESIGN.md
git commit -m "docs(design): record the sacred canvas threshold timings"
```

- [ ] **Step 5: Device QA (physical device required)**

Run: `flutter run --dart-define-from-file=env.json`

Walk each item and note anything that reads wrong:

1. **Muḥāsabah enter** — Home → *Begin Muḥāsabah* → through the gacha → tap *Go Deeper*. The emerald must grow from under your thumb, not from the centre. Watch for jank on the first two frames; the outgoing tree here is the heaviest (Name card with shadow + sparkle row) and it is being composited through an `Opacity`.
2. **Muḥāsabah loader → beat 1** — the loader should dissolve, not pop.
3. **Muḥāsabah exit** — tap through to the duʿā, tap *Ameen*. Total closing ceremony is ~1.5s (1100ms completion beat + 400ms dissolve). If it drags, the knob is the completion delay at `beat_reveal_flow.dart:157`, not the fade.
4. **Reflect** — type a feeling, submit; the bloom should open from the centre where the ripple loader was.
5. **Build-a-Dua** — build a duʿā and watch both the entrance and the return to the input screen.
6. **Bottom nav timing** — Reflect and Build-a-Dua flip `immersiveModeProvider` on the same frame the transition starts, so the nav bar disappears instantly while the emerald is still growing. If that reads badly, the fix is to defer the immersive flip until the threshold completes; log it rather than fixing it inline.
7. **Reduced motion** — Settings → Accessibility → Reduce Motion on, then repeat items 1 and 4. Both should be plain short fades with no circular geometry.

If item 1 janks, the fallback stated in the spec is a `ShaderMask` radial alpha ramp in place of `ClipPath` — same visual, no clip.

- [ ] **Step 6: Record findings**

Write anything QA surfaced to `docs/qa/findings/2026-07-27-sacred-canvas-threshold.md` following the existing findings format, and commit.

---

## Done when

- All three surfaces bloom in and dissolve out instead of cutting.
- `BeatRevealFlow` no longer pops between loading and beat 1.
- Both segmented progress bars sweep open once on mount.
- Reduced motion collapses every one of those to a short fade or a static mount.
- `flutter analyze` clean on all touched files; no new test failures against the 86-test baseline.
- Device QA walked, findings recorded.
