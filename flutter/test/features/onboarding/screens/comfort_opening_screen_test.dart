import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/screens/comfort_opening_screen.dart';
import 'package:sakina/widgets/beat_reveal/mihrab_arch_frame.dart';

import '_test_utils.dart';

/// Wave H §6 — the comfort opening, which REPLACED the welcome screen.
///
/// What these pin is the contract the wave was written for: a Reel-2 arrival is
/// promised 2:286, so 2:286 is what the app opens with; the two scripts never
/// share a widget; the sign-in link survives the replacement; nothing on the
/// app's first frame is fetched over the network; and reduced motion costs
/// travel, never content.
void main() {
  final arabicScript = RegExp(r'[؀-ۿ]');
  final latinScript = RegExp('[A-Za-z]');

  Future<int> pumpScreen(
    WidgetTester tester, {
    Future<void> Function()? onNext,
    VoidCallback? onSignIn,
    bool reduceMotion = false,
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
    await pumpScreen(tester, reduceMotion: true);

    expect(find.text(ComfortOpeningScreen.ayahArabic), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ayahEnglish), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ayahReference), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.acknowledgement), findsOneWidget);
    expect(find.text(ComfortOpeningScreen.ctaLabel), findsOneWidget);
    expect(find.text(AppStrings.hookLoginLink), findsOneWidget);

    // The arch appears rather than drawing itself on.
    expect(
      tester.widget<MihrabArchFrame>(find.byType(MihrabArchFrame)).animate,
      isFalse,
    );
  });
}
