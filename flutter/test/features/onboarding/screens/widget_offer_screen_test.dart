import 'dart:io';
import 'dart:typed_data';

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

  testWidgets('offers all three widgets, in gallery order', (tester) async {
    await pump(tester);

    expect(onboardingWidgetOptions, hasLength(3));
    // Founder decision 2026-07-29: match the iOS gallery exactly, so the
    // how-to sheet's "search for Sakina, then choose X" reads against the same
    // list the user is looking at.
    expect(onboardingWidgetOptions.map((o) => o.kind),
        ['dua_times', 'daily_name', 'lantern']);

    // Only the focused card is built by a PageView at rest, so the pin is on
    // the data plus the first card actually rendering.
    expect(find.byType(WidgetPreviewCard), findsWidgets);
    expect(find.text('Duʿā Times'), findsOneWidget);
  });

  test('every preview asset exists, is registered, and shares one crop', () {
    // These are real screenshots, so nothing about a widget redesign makes them
    // fail — but a renamed/missing file or an unregistered asset dir fails at
    // RUNTIME on a screen 12 pages into onboarding, which is the worst place to
    // find out. Regeneration recipe: docs/qa/widget-preview-screenshots.md
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('assets/images/widget_previews/'),
      reason: 'Flutter asset dirs are not recursive — the subdirectory needs '
          'its own pubspec entry or Image.asset throws at runtime',
    );

    final sizes = <String>{};
    for (final option in onboardingWidgetOptions) {
      final file = File(option.previewAsset);
      expect(file.existsSync(), isTrue,
          reason: '${option.kind}: ${option.previewAsset} is missing');

      // Decode just the IHDR — PNG width/height live at bytes 16-23, so this
      // needs no image package.
      final bytes = file.readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      sizes.add('${data.getUint32(16)}x${data.getUint32(20)}');
    }
    expect(
      sizes,
      hasLength(1),
      reason: 'all three crops must be identical in size — the carousel pins '
          'one aspect ratio, so a differing asset makes the page jump height '
          'mid-swipe. Got: $sizes',
    );

    final dims = sizes.single.split('x').map(int.parse).toList();
    expect(
      dims[0] / dims[1],
      closeTo(WidgetPreviewCard.previewAspectRatio, 0.01),
      reason: 'the assets were re-cropped to a different box — update '
          'WidgetPreviewCard.previewAspectRatio to match',
    );
  });

  testWidgets('the gallery names match the shipped widget bundle exactly',
      (tester) async {
    // These strings are instructions: the how-to sheet tells the user to search
    // the iOS widget gallery for them. They must equal the
    // `configurationDisplayName` values in SakinaWidgetBundle.swift — a rename
    // on either side breaks the instruction silently.
    expect(
      onboardingWidgetOptions.map((o) => o.galleryName),
      ['Duʿā Times', "A Name for What You're Carrying", 'Your Lantern'],
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

    // Card 0 is Duʿā Times, so the location primer comes first (below); swipe
    // to a card that has no location dependency to pin the how-to on its own.
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text(WidgetOfferScreen.ctaLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Touch and hold'), findsOneWidget);
    expect(find.textContaining('Search for "Sakina"'), findsOneWidget);
    expect(advanced, 0,
        reason: 'the how-to is a sheet over the page, not a step forward');
  });

  // ── The location ask (2026-08) ────────────────────────────────────────────

  testWidgets('the Duʿā Times CTA primes the location ask first',
      (tester) async {
    await pump(tester);

    // Card 0 is Duʿā Times — the one widget that cannot work without location,
    // and a widget extension can never ask for it itself.
    await tester.tap(find.text(WidgetOfferScreen.ctaLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('needs your location'), findsOneWidget);
    // The diagram names the durable choice. "Allow Once" reverting on the next
    // cold launch is what put the reporting tester in a re-prompt loop.
    expect(find.text('Allow While Using App'), findsOneWidget);
    expect(find.textContaining('Allow Once'), findsWidgets);
  });

  testWidgets('the location primer has exactly one button and no way past it',
      (tester) async {
    // Apple's pre-alert rules name location explicitly: "include only one
    // button… don't include an option to cancel… don't include an option to
    // close the view." Notifications are NOT on that list, which is why the
    // notification screen's "Not now" is not safe to copy here.
    await pump(tester);

    await tester.tap(find.text(WidgetOfferScreen.ctaLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // One button in the sheet, and no cancel/close of its own. ("Not now" still
    // exists on the page BEHIND the scrim — that is the widget offer, not the
    // location pre-alert, and it is not reachable while the sheet is up.)
    final sheet = find.ancestor(
      of: find.textContaining('needs your location'),
      matching: find.byType(SingleChildScrollView),
    );
    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Continue')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Cancel')),
        findsNothing);
    expect(
        find.descendant(
            of: sheet, matching: find.text(WidgetOfferScreen.skipLabel)),
        findsNothing);

    // And it cannot be dismissed by tapping the scrim — the one button is the
    // only way forward.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('needs your location'), findsOneWidget,
        reason: 'a location pre-alert must not be dismissible');
  });

  testWidgets('a non-location widget never sees the location primer',
      (tester) async {
    await pump(tester);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text(WidgetOfferScreen.ctaLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('needs your location'), findsNothing,
        reason: 'only Duʿā Times depends on location');
  });
}
