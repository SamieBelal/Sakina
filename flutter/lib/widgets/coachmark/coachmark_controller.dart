import 'package:flutter/widgets.dart';

import 'coachmark_overlay.dart';
import 'coachmark_step.dart';

/// Sequences a list of [CoachmarkStep]s using a single [OverlayEntry] in the
/// root overlay (so the overlay survives route pushes during the E6
/// sequenced replay walk). Holds no global state; caller owns lifecycle.
class CoachmarkController {
  CoachmarkController({
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  final List<CoachmarkStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  int _index = 0;
  OverlayEntry? _entry;
  BuildContext? _ctx;
  bool _started = false;

  /// Call from a post-first-frame callback after the target widgets are laid
  /// out. No-op if [steps] is empty OR if [start] has already been called
  /// (double-start protection — hot reload + parent rebuilds could otherwise
  /// re-enter mid-sequence).
  void start(BuildContext context) {
    if (_started) return;
    _started = true;
    if (steps.isEmpty) {
      onComplete();
      return;
    }
    _ctx = context;
    _show();
  }

  void _show() {
    final overlay = Overlay.of(_ctx!, rootOverlay: true);
    _entry?.remove();
    _entry = null;
    _entry = OverlayEntry(
      builder: (_) => CoachmarkOverlay(
        step: steps[_index],
        stepIndex: _index,
        totalSteps: steps.length,
        onNext: _next,
        onSkip: _skip,
      ),
    );
    overlay.insert(_entry!);
  }

  void _next() {
    if (_index >= steps.length - 1) {
      _dismiss();
      onComplete();
      return;
    }
    _index++;
    _show();
  }

  void _skip() {
    _dismiss();
    onSkip();
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  /// Call from owner's State.dispose to drop any in-flight overlay.
  void dispose() => _dismiss();
}
