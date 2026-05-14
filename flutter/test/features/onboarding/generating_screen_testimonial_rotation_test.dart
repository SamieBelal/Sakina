import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/screens/generating_screen.dart';

/// Pins testimonial rotation on the GeneratingScreen loader for both flag
/// states. The compile-time `Env.paywallTestimonialsEnabled` flag defaults
/// to `false` in v1; the screen's `@visibleForTesting`
/// `testimonialsEnabledOverride` constructor parameter lets tests exercise
/// the rotation path or the loader-only path without rebuilding.
///
/// Three placeholders rotate at ~1100ms intervals — three steps comfortably
/// fits the existing 3500ms loader window with ~200ms of outro headroom.
/// Substring matching (city name) keeps the test stable when the
/// placeholder copy changes (e.g. when real reviews replace the
/// `FAKE_DO_NOT_SHIP_` prefixed strings in Phase 2).
void main() {
  Widget buildSubject({required bool testimonialsEnabled}) {
    return ProviderScope(
      child: MaterialApp(
        home: GeneratingScreen(
          onNext: () {},
          testimonialsEnabledOverride: testimonialsEnabled,
        ),
      ),
    );
  }

  testWidgets(
      'Flag ON: 3 testimonials rotate in order during the loader window — '
      'pumping past each 1.1s interval surfaces the next testimonial; the '
      'rotation wraps modulo 3 so the loader window never runs out of copy',
      (tester) async {
    await tester.pumpWidget(buildSubject(testimonialsEnabled: true));
    await tester.pump();

    // Sanity-check the placeholder substrings stay decoupled from the
    // FAKE_DO_NOT_SHIP_ prefix — that prefix is grep-gated separately
    // and is expected to disappear when real testimonials land. Match
    // on city/name substrings instead.
    expect(find.textContaining('Layla'), findsOneWidget);
    expect(find.textContaining('Yusuf'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.textContaining('Yusuf'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.textContaining('Aaliyah'), findsOneWidget);

    // Rotation wraps — fourth tick lands back on Layla.
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.textContaining('Layla'), findsOneWidget);

    // Allow the rotation timer + theater timer to wind down before the
    // test exits so no Timer leaks into the next test.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'Flag OFF: no testimonial widget renders at all — not even a hidden '
      'SizedBox, so a layout shift never appears the moment the flag flips on',
      (tester) async {
    await tester.pumpWidget(buildSubject(testimonialsEnabled: false));
    await tester.pump();

    expect(find.textContaining('Layla'), findsNothing);
    expect(find.textContaining('Yusuf'), findsNothing);
    expect(find.textContaining('Aaliyah'), findsNothing);

    // Advancing past the rotation interval must still surface no
    // testimonial — the Timer.periodic must not have started at all.
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.textContaining('Yusuf'), findsNothing);

    // Wind the screen down before the test exits.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('All placeholders ship with the FAKE_DO_NOT_SHIP_ tripwire prefix — '
      'a static guard that the strings have not been silently replaced with '
      'real reviews without updating the CI grep gate in Task 6', () {
    for (final t in AppStrings.generatingTestimonials) {
      expect(
        t.startsWith('FAKE_DO_NOT_SHIP_'),
        isTrue,
        reason:
            'Testimonial "$t" must keep the FAKE_DO_NOT_SHIP_ prefix until '
            'replaced with a real attributable review. Removing the prefix '
            'without flipping PAYWALL_TESTIMONIALS_ENABLED is a mistake; '
            'see Task 4 of docs/superpowers/plans/2026-05-14-paywall-rebuild.md.',
      );
    }
  });
}
