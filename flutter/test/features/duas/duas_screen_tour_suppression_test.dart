import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/duas/screens/duas_screen.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';

/// Regression for the guided-tour `duas.buildCta` coachmark never appearing.
///
/// `tourSuppressedProvider` is a latch that DuasScreen sets `true` only while
/// its multi-screen Build-a-Dua flow is on screen, and clears via an
/// edge-triggered `ref.listen` (duasProvider changes) + `dispose()`. A stale
/// `true` left over from a previous Duas visit (e.g. a replayed tour) would
/// survive a fresh mount with no provider change to clear it, and the overlay
/// host hides the (anchored) buildCta coachmark forever while the flag is true
/// — the user only recovered it by leaving and re-entering the tab (dispose
/// reset). The mount-time reconcile must force the flag back to its real value.
///
/// Same stale-suppression bug class as F-06 (fixed centered steps only). See
/// docs/qa/findings/2026-06-04-tour-buildcta-stale-suppression.md
void main() {
  testWidgets(
      'reconciles a stale tourSuppressed=true to false on mount '
      '(build-input state)', (tester) async {
    final container = ProviderContainer(
      overrides: [
        // loadOnInit:false → state stays the default DuasState (build INPUT
        // showing, buildResult == null) so the `buildCta` anchor is mounted —
        // exactly the state the tour arrives in.
        duasProvider.overrideWith((ref) => DuasNotifier(loadOnInit: false)),
        // Stale leftover from a prior Duas visit.
        tourSuppressedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(tourSuppressedProvider), isTrue,
        reason: 'precondition: the stale flag is set before mount');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DuasScreen()),
      ),
    );
    // Let the mount post-frame reconcile run.
    await tester.pump();

    expect(container.read(tourSuppressedProvider), isFalse,
        reason: 'stale suppression must be cleared on mount so the guided '
            'tour coachmark can reveal over the build input');

    // Drain the build-input entry animations (flutter_animate delayed fades)
    // so no Timer is left pending at teardown.
    await tester.pumpAndSettle();
  });
}
