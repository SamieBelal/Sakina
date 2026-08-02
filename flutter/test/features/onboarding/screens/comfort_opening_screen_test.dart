import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/screens/comfort_opening_screen.dart';
import 'package:sakina/widgets/beat_reveal/mihrab_arch_frame.dart';
import 'package:sakina/widgets/scribe_reveal.dart';

import '_test_utils.dart';

/// Wave H §6 — the comfort opening, which REPLACED the welcome screen.
///
/// What these pin is the contract the wave was written for: a Reel-2 arrival is
/// promised 2:286, so 2:286 is what the app opens with; the two scripts never
/// share a widget; the sign-in link survives the replacement; nothing on the
/// app's first frame is fetched over the network; and reduced motion costs
/// travel, never content.
///
/// The cold open (2026-07-29) adds a second contract: an ~8s staged entrance
/// that must never move the layout, never leave an invisible control tappable,
/// and always be escapable by a tap.
void main() {
  final arabicScript = RegExp(r'[؀-ۿ]');
  final latinScript = RegExp('[A-Za-z]');

  setUp(ComfortOpeningScreen.debugResetColdOpen);

  Future<int> pumpScreen(
    WidgetTester tester, {
    Future<void> Function()? onNext,
    VoidCallback? onSignIn,
    bool reduceMotion = false,
    bool? playColdOpen = false,
    bool settle = true,
  }) async {
    useOnboardingViewport(tester);
    var nextCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: ComfortOpeningScreen(
            onNext: onNext ??
                () async {
                  nextCalls++;
                },
            onSignIn: onSignIn,
            departureLead: Duration.zero,
            playColdOpen: playColdOpen,
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    return nextCalls;
  }

  /// Every `Text` currently on screen that actually carries characters.
  List<Text> visibleTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => (t.data ?? '').trim().isNotEmpty)
      .toList();

  testWidgets('opens on 2:286 — the ayah the reel promised', (tester) async {
    await pumpScreen(tester);

    expect(find.text(ComfortOpeningScreen.ayahArabic), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ayahEnglish), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ayahReference), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.acknowledgement), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ctaLabel), findsOneWidget);

    // The old screen's ayah and feature-list tagline are gone, not merely
    // demoted — they are what broke ad-scent for a Reel-2 arrival.
    expect(find.text(AppStrings.hookAyahEnglish), findsNothing);
    expect(find.textContaining('Reflect'), findsNothing);
  });

  testWidgets('Arabic and Latin never share a Text widget', (tester) async {
    await pumpScreen(tester);

    for (final text in visibleTexts(tester)) {
      final data = text.data!;
      expect(
        arabicScript.hasMatch(data) && latinScript.hasMatch(data),
        isFalse,
        reason: 'mixed-direction string on the first screen: $data',
      );
    }

    // The ayah's own two widgets, each with its direction stated outright.
    final arabic = tester.widget<Text>(
      find.text(ComfortOpeningScreen.ayahArabic),
    );
    final english = tester.widget<Text>(
      find.text(ComfortOpeningScreen.ayahEnglish),
    );
    expect(arabic.textDirection, TextDirection.rtl);
    expect(english.textDirection, TextDirection.ltr);
  });

  testWidgets('nothing on the first frame comes off the network',
      (tester) async {
    await pumpScreen(tester);

    // The arch is code-drawn now (MihrabArchFrame), not an image fetched from
    // a googleusercontent.com URL.
    expect(find.byType(MihrabArchFrame), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the sign-in link survives the replacement', (tester) async {
    var signInCalls = 0;
    await pumpScreen(tester, onSignIn: () => signInCalls++);

    expect(find.text(AppStrings.hookLoginLink), findsOneWidget);
    await tester.tap(find.text(AppStrings.hookLoginLink));
    await tester.pump();
    expect(signInCalls, 1);
  });

  testWidgets('Begin dissolves the canvas and hands over to the flow',
      (tester) async {
    // Never completes: the future completing is what brings the canvas BACK,
    // so holding it open is how the departed state stays observable.
    final handedOver = Completer<void>();
    var nextCalls = 0;
    await pumpScreen(
      tester,
      onNext: () {
        nextCalls++;
        return handedOver.future;
      },
    );

    await tester.tap(find.text(ComfortOpeningScreen.ctaLabel));
    await tester.pump();
    expect(nextCalls, 1);

    await tester.pumpAndSettle();
    // The emerald has dissolved off, so the (cream) hook screen is pushed onto
    // cream rather than over a full-luminance inversion.
    expect(find.text(ComfortOpeningScreen.acknowledgement), findsNothing);
  });

  testWidgets('lays out on a short screen without overflowing', (tester) async {
    // iPhone SE — the compact rhythm. An overflow here would fail the test on
    // its own; the assertions are that the beat still holds every part.
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ComfortOpeningScreen(
          onNext: () async {},
          departureLead: Duration.zero,
          playColdOpen: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ComfortOpeningScreen.ayahArabic), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.acknowledgement), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ctaLabel), findsOneWidget);
    expect(find.text(AppStrings.hookLoginLink), findsOneWidget);
  });

  testWidgets('reduced motion drops the travel, never the content',
      (tester) async {
    // Asks for the cold open AND for reduced motion: the whole sequence has to
    // be skipped, on the very first frame, not merely played without travel.
    await pumpScreen(
      tester,
      reduceMotion: true,
      playColdOpen: true,
      settle: false,
    );
    await tester.pump();

    expect(find.text(ComfortOpeningScreen.ayahArabic), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ayahEnglish), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ayahReference), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.acknowledgement), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ctaLabel), findsOneWidget);
    expect(find.text(AppStrings.hookLoginLink), findsOneWidget);

    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 1.0);
    // Movement I is skipped outright, not played without travel — a greeting
    // that lingered here would sit on top of the settled screen.
    expect(opacityOf(tester, ComfortOpeningScreen.greetingArabic), 0.0);
    // The arch appears rather than drawing itself on.
    expect(
      tester.widget<MihrabArchFrame>(find.byType(MihrabArchFrame)).progress,
      1.0,
    );
    // And the ayah is finished ink, not a half-written stroke. (ScribeReveal
    // stays in the tree at 1 — it drops its own mask, not itself.)
    expect(scribeProgress(tester), 1.0);
  });

  // ── The cold open ────────────────────────────────────────────────────────

  testWidgets('movement I: the greeting arrives alone, and then leaves',
      (tester) async {
    await pumpScreen(tester, playColdOpen: true, settle: false);
    await tester.pump();

    // The first frame is bare emerald — the greeting fades up ONTO it rather
    // than already being there when the app opens.
    expect(opacityOf(tester, ComfortOpeningScreen.greetingArabic), 0.0);

    // Held, with nothing else on the canvas competing for the eye. Not even the
    // first stroke of the ayah.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(opacityOf(tester, ComfortOpeningScreen.greetingArabic), 1.0);
    // Arabic only, direction stated outright — same contract as the ayah. The
    // app's first painted glyphs are the easiest place for an RTL bleed to
    // reach adjacent UI.
    expect(
      tester
          .widget<Text>(find.text(ComfortOpeningScreen.greetingArabic))
          .textDirection,
      TextDirection.rtl,
    );
    expect(scribeProgress(tester), 0.0);
    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 0.0);
    expect(archProgress(tester), 0.0);

    // THE thing that makes it a title card rather than content: it goes. If
    // this ever stops being true the greeting would sit behind the verse for
    // the rest of the opening.
    await tester.pump(const Duration(milliseconds: 2200));
    expect(opacityOf(tester, ComfortOpeningScreen.greetingArabic), 0.0);
    expect(
      scribeProgress(tester),
      0.0,
      reason: 'the canvas must be empty again before the ayah starts — the two '
          'movements never share the screen',
    );

    await tester.pumpAndSettle();
    expect(opacityOf(tester, ComfortOpeningScreen.greetingArabic), 0.0);
  });

  testWidgets('movement II: stages the ayah before the chrome', (tester) async {
    await pumpScreen(tester, playColdOpen: true, settle: false);
    await tester.pump();

    // Everything is laid out from frame one; nothing is painted.
    expect(find.text(ComfortOpeningScreen.ayahArabic), findsOneWidget);
    expect(opacityOf(tester, ComfortOpeningScreen.acknowledgement), 0.0);
    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 0.0);

    // The ayah is being written and owns the screen alone.
    await tester.pump(const Duration(milliseconds: 6000));
    expect(scribeProgress(tester), greaterThan(0.0));
    expect(scribeProgress(tester), lessThan(1.0));
    expect(opacityOf(tester, ComfortOpeningScreen.ayahEnglish), 0.0);
    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 0.0);

    // Translation and reference have landed; the chrome has not.
    await tester.pump(const Duration(milliseconds: 4000));
    expect(opacityOf(tester, ComfortOpeningScreen.ayahEnglish), 1.0);
    expect(opacityOf(tester, ComfortOpeningScreen.ayahReference), 1.0);
    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 0.0);
    expect(archProgress(tester), 0.0);

    // The niche is drawn around a verse that was already there, and the screen
    // has become a screen.
    await tester.pumpAndSettle();
    expect(archProgress(tester), 1.0);
    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 1.0);
    expect(opacityOf(tester, AppStrings.hookLoginLink), 1.0);
  });

  testWidgets('neither movement ever moves the ayah', (tester) async {
    // THE regression this ordering can produce, and the reason the greeting is a
    // Stack overlay rather than a row in the column. The greeting, arch,
    // wordmark and CTA all come and go around the verse, so if any of them took
    // layout as it appeared the scripture would shift under someone in the
    // middle of reading it.
    await pumpScreen(tester, playColdOpen: true, settle: false);
    await tester.pump();

    final arabic = find.text(ComfortOpeningScreen.ayahArabic);
    final atRest = tester.getRect(arabic);

    // Sampled across both movements: greeting held, greeting leaving, ayah
    // being written, translation, the app's line, the arch drawing.
    var elapsed = 0;
    for (final step in const [2000, 1500, 1500, 3000, 2500, 2000, 1500]) {
      await tester.pump(Duration(milliseconds: step));
      elapsed += step;
      expect(
        tester.getRect(arabic),
        atRest,
        reason: 'the ayah moved ${elapsed}ms into the opening',
      );
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(arabic), atRest);
  });

  testWidgets('a tap anywhere catches the sequence up, from either movement',
      (tester) async {
    await pumpScreen(tester, playColdOpen: true, settle: false);
    await tester.pump();
    // Mid-greeting — the earliest and least forgiving place to escape from.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 0.0);

    // Empty canvas, well above the CTA. Someone who arrived from the reel and is
    // already sold must not be made to sit through fourteen seconds.
    await tester.tapAt(const Offset(200, 120));
    await tester.pumpAndSettle();

    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 1.0);
    expect(archProgress(tester), 1.0);
    // The greeting is gone rather than stranded mid-fade over the verse.
    expect(opacityOf(tester, ComfortOpeningScreen.greetingArabic), 0.0);
  });

  testWidgets('an unarrived Begin cannot be tapped', (tester) async {
    // Opacity alone does not stop hit-testing, so without the IgnorePointer a
    // tap meant to skip the opening would start the flow instead.
    var nextCalls = 0;
    await pumpScreen(
      tester,
      playColdOpen: true,
      settle: false,
      onNext: () async => nextCalls++,
    );
    await tester.pump();

    await tester.tap(find.text(ComfortOpeningScreen.ctaLabel), warnIfMissed: false);
    await tester.pump();
    expect(nextCalls, 0);

    // ...and it works once it has arrived.
    await tester.pumpAndSettle();
    await tester.tap(find.text(ComfortOpeningScreen.ctaLabel));
    await tester.pump();
    expect(nextCalls, 1);
  });

  testWidgets('the opening is spent once — a second visit is already assembled',
      (tester) async {
    await pumpScreen(tester, playColdOpen: true, settle: false);
    await tester.pumpAndSettle();

    // Same session, screen rebuilt from scratch (back-nav from sign-in, or a
    // route rebuild). `playColdOpen: null` = decide from persistence.
    await pumpScreen(tester, playColdOpen: null, settle: false);
    await tester.pump();

    expect(opacityOf(tester, ComfortOpeningScreen.ctaLabel), 1.0);
    expect(archProgress(tester), 1.0);
  });
}

/// Opacity actually applied to the text, as composed by every [Opacity] the
/// beat wrappers put above it.
///
/// Absent from the tree counts as 0: the greeting layer drops its subtree
/// entirely once it has faded out, rather than paying for a transparent
/// `Opacity` for the remaining ten seconds.
double opacityOf(WidgetTester tester, String text) {
  final target = find.text(text);
  if (target.evaluate().isEmpty) return 0;
  final opacities = tester.widgetList<Opacity>(
    find.ancestor(of: target, matching: find.byType(Opacity)),
  );
  return opacities.fold<double>(1, (acc, o) => acc * o.opacity);
}

double archProgress(WidgetTester tester) =>
    tester.widget<MihrabArchFrame>(find.byType(MihrabArchFrame)).progress!;

double scribeProgress(WidgetTester tester) =>
    tester.widget<ScribeReveal>(find.byType(ScribeReveal)).progress;
