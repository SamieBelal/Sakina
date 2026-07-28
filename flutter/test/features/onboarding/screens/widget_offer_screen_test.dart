import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/onboarding_widgets.dart';
import 'package:sakina/features/onboarding/screens/widget_offer_screen.dart';
import 'package:sakina/features/onboarding/widgets/widget_preview_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '_test_utils.dart';

/// The onboarding widget carousel (Wave G, spec §7).
///
/// The founder chose three browsable options over one dominant one, so the
/// thing worth pinning is that all three stay reachable and in the order the
/// beat before them sets up — the lantern first, because the user has just
/// watched it light.
void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onNext,
  }) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            // The lantern preview card breathes forever otherwise.
            data: const MediaQueryData(disableAnimations: true),
            child: WidgetOfferScreen(
              onNext: onNext ?? () {},
              onBack: () {},
              progressSegment: 5,
              totalSegments: 10,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('offers all three widgets, lantern first', (tester) async {
    await pump(tester);

    expect(onboardingWidgetOptions, hasLength(3));
    expect(onboardingWidgetOptions.first.kind, 'lantern',
        reason: 'the carousel continues the beat where the lamp was lit');
    expect(onboardingWidgetOptions.map((o) => o.kind),
        ['lantern', 'daily_name', 'dua_times']);

    // Only the focused card is built by a PageView at rest, so the pin is on
    // the data plus the first card actually rendering.
    expect(find.byType(WidgetPreviewCard), findsWidgets);
    expect(find.text('Your Lantern'), findsOneWidget);
  });

  testWidgets('the gallery names match the shipped widget bundle exactly',
      (tester) async {
    // These strings are instructions: the how-to sheet tells the user to search
    // the iOS widget gallery for them. They must equal the
    // `configurationDisplayName` values in SakinaWidgetBundle.swift — a rename
    // on either side breaks the instruction silently.
    expect(
      onboardingWidgetOptions.map((o) => o.galleryName),
      ['Your Lantern', "A Name for What You're Carrying", 'Duʿā Times'],
    );
  });

  testWidgets('"Not now" is always reachable and advances the flow',
      (tester) async {
    var advanced = 0;
    await pump(tester, onNext: () => advanced++);

    expect(find.text(WidgetOfferScreen.skipLabel), findsOneWidget);
    await tester.tap(find.text(WidgetOfferScreen.skipLabel));
    await tester.pump();
    expect(advanced, 1);
  });

  testWidgets('the CTA opens instructions and installs nothing',
      (tester) async {
    // iOS has no API to add a widget — Duolingo's equivalent button is
    // instructional too. If this ever appears to "add" one, the copy is lying.
    var advanced = 0;
    await pump(tester, onNext: () => advanced++);

    await tester.tap(find.text(WidgetOfferScreen.ctaLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Touch and hold'), findsOneWidget);
    expect(find.textContaining('Search for "Sakina"'), findsOneWidget);
    expect(advanced, 0,
        reason: 'the how-to is a sheet over the page, not a step forward');
  });
}
