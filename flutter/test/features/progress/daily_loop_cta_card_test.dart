// W4 Wave 5 — the home CTA.
//
// The CTA stopped being a 13px row between two dividers inside the dashboard
// card and became a card of its own, directly under the greeting. Two things
// are pinned here:
//
//   1. BEHAVIOUR of the card itself, which is pure presentation by design so it
//      can be tested without wiring the whole ProgressScreen (that screen
//      watches six providers and pushes overlays from initState — see the note
//      in discover_name_reentry_guard_test.dart).
//
//   2. POSITION on the screen, at the source level. Prominence is the entire
//      point of the wave, and it is invisible to a widget test of the card in
//      isolation: a card that renders perfectly 800px down the scroll is the
//      bug we just fixed.
//
// The not-started state carries extra weight: it is where Wave 2's "Not right
// now" defer lands. If it ever renders as spent or absent, the defer stops
// being a deferral and becomes a polite exit from the product.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/progress/widgets/daily_loop_cta_card.dart';

void main() {
  Widget host(
    Widget child, {
    double width = 390,
    double textScale = 1.0,
  }) {
    // Mirrors the production composition: the home body is a
    // SingleChildScrollView, so vertical growth at large text scales is
    // absorbed by scrolling — as it should be for Dynamic Type. What that does
    // NOT absorb is horizontal overflow, which is the real risk in a Row that
    // has to fit a 44px glyph, two gaps, a trailing icon and wrapping text into
    // a 320px phone. Testing in a bounded box instead would fail on legitimate
    // vertical growth and hide that.
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }

  group('the unfinished states invite', () {
    testWidgets('not-started names the job, not the jargon', (tester) async {
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.notStarted,
          onStart: () {},
          onReroll: () {},
        ),
      ));

      expect(find.text('What\'s on your heart today?'), findsOneWidget);
      expect(
        find.textContaining('carrying'),
        findsNothing,
        reason: 'the label must stay VALENCE-NEUTRAL (spec M4). A CTA that '
            'presupposes weight — "Name what you\'re carrying" — leaves no '
            'slot for the honest answer on a good day, one tap upstream of a '
            'question that was made neutral on purpose.',
      );
      expect(
        find.text('Begin Muhāsabah'),
        findsNothing,
        reason: 'the CTA label is the job now; muḥāsabah is taught as a gloss '
            'underneath it, never as the button',
      );
      // The gloss teaches the word and states the benefit in one line.
      expect(
        find.textContaining('muḥāsabah'),
        findsOneWidget,
        reason: 'the word must still be taught — dropping it from the label is '
            'not the same as hiding it',
      );
    });

    testWidgets('the not-started face is what a deferred loop shows',
        (tester) async {
      // Wave 2's "Not right now" writes the day marker and returns home with
      // checkinDone false and currentStep still `checkin`, which is exactly
      // this state. It must read as an open invitation.
      var started = 0;
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.notStarted,
          onStart: () => started++,
          onReroll: () {},
        ),
      ));

      await tester.tap(find.byType(DailyLoopCtaCard));
      await tester.pump();

      expect(started, 1,
          reason: 'the CTA is the only way back into a deferred loop — if this '
              'stops being tappable, the defer becomes a dead end');
    });

    testWidgets('in-progress offers to resume', (tester) async {
      var started = 0;
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.inProgress,
          onStart: () => started++,
          onReroll: () {},
        ),
      ));

      expect(find.text('Pick up where you left off'), findsOneWidget);
      await tester.tap(find.byType(DailyLoopCtaCard));
      await tester.pump();
      expect(started, 1);
    });
  });

  group('the completed state is finished, not empty', () {
    testWidgets('renders a dignified done state naming the Name met',
        (tester) async {
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          completedName: 'Al-Wadud',
          onStart: () {},
          onReroll: () {},
        ),
      ));

      expect(find.text('Today\'s muḥāsabah is complete'), findsOneWidget);
      expect(find.text('You sat with Al-Wadud.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('survives a missing Name without an empty sentence',
        (tester) async {
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          onStart: () {},
          onReroll: () {},
        ),
      ));

      expect(find.text('Today\'s muḥāsabah is complete'), findsOneWidget);
      expect(find.textContaining('You sat with'), findsNothing);
    });

    testWidgets('the re-roll is an explicit target, not the whole card',
        (tester) async {
      var rerolled = 0;
      var started = 0;
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          completedName: 'Al-Wadud',
          onStart: () => started++,
          onReroll: () => rerolled++,
        ),
      ));

      // Tapping the headline must NOT re-roll: past the free daily reveal a
      // re-roll meets the cap sheet and can cost 25 tokens, so it has to be
      // deliberate.
      await tester.tap(find.text('Today\'s muḥāsabah is complete'));
      await tester.pump();
      expect(rerolled, 0);
      expect(started, 0);

      await tester.tap(find.text('Meet another Name'));
      await tester.pump();
      expect(rerolled, 1,
          reason: 'the completed state still hosts the metered re-roll — the '
              'host screen gates it with canUse + _discoverInFlight');
    });

    testWidgets('the re-roll can actually show a ripple', (tester) async {
      // Regression: the card was a decorated `Container`, so the InkWell's
      // nearest `Material` ancestor was the Scaffold — and the splash was
      // painted UNDERNEATH the card's opaque `primaryLight` fill. The tap
      // worked; the feedback was invisible.
      //
      // Untestable by tapping: a splash that paints nowhere still fires
      // `onTap`, so the tap test above passed throughout. What is testable is
      // the structural precondition — a `Material` between the card and the
      // InkWell, with the fill on an `Ink` so it lands on that Material's
      // canvas rather than over it.
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          completedName: 'Al-Wadud',
          onStart: () {},
          onReroll: () {},
        ),
      ));

      expect(
        find.descendant(
          of: find.byType(DailyLoopCtaCard),
          matching: find.byType(Material),
        ),
        findsAtLeastNWidgets(1),
        reason: 'the InkWell needs a Material INSIDE the card, or its ripple '
            'is drawn on the Scaffold beneath an opaque fill',
      );
      expect(
        find.descendant(
          of: find.byType(DailyLoopCtaCard),
          matching: find.byType(Ink),
        ),
        findsOneWidget,
        reason: 'the fill must be an Ink decoration so it shares the '
            "Material's canvas with the splash",
      );
    });

    testWidgets('the re-roll target clears 44pt', (tester) async {
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          onStart: () {},
          onReroll: () {},
        ),
      ));

      final box = tester.getRect(find.text('Meet another Name').hitTestable());
      final target = tester.getRect(
        find.ancestor(
          of: find.text('Meet another Name'),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(target.height, greaterThanOrEqualTo(44.0));
      expect(box.height, lessThanOrEqualTo(target.height));
    });
  });

  group('it does not overflow', () {
    // Narrow phone (iPhone SE class) and the accessibility text scales the
    // design system has to survive. An overflow here is a red-and-yellow bar
    // across the most important control on the screen.
    for (final state in DailyLoopCtaState.values) {
      for (final scale in <double>[1.0, 1.5, 2.0]) {
        testWidgets('$state at 320px / ${scale}x text', (tester) async {
          await tester.pumpWidget(host(
            DailyLoopCtaCard(
              state: state,
              completedName: 'Ar-Rahman',
              onStart: () {},
              onReroll: () {},
            ),
            width: 320,
            textScale: scale,
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('and stays compact enough to earn its place above the fold',
        (tester) async {
      // The wave is about prominence, and prominence is bought with position,
      // not size. A CTA that grows to half the viewport at default text has
      // pushed everything else below the fold instead — the same mistake in
      // the opposite direction.
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.notStarted,
          onStart: () {},
          onReroll: () {},
        ),
      ));

      final height = tester.getSize(find.byType(DailyLoopCtaCard)).height;
      // Bounds are deliberately loose. Widget tests substitute the font (Outfit
      // never loads here), so text-driven heights run larger than production
      // and a tight number would pin font metrics rather than design intent.
      // These catch the two regressions that matter: collapsing back into a
      // list row, or ballooning into a hero banner that pushes the lantern and
      // the Name off the fold — the same mistake in the opposite direction.
      expect(height, greaterThan(72),
          reason: 'it must not shrink back into a 13px list row');
      expect(height, lessThan(220),
          reason: 'prominence here is bought with position, not size');
    });
  });

  group('position on the home screen (source pins)', () {
    late String source;

    setUpAll(() {
      source = File('lib/features/progress/screens/progress_screen.dart')
          .readAsStringSync();
    });

    test('the CTA is built above every promo card and the dashboard', () {
      final cta = source.indexOf('_buildMuhasabahCta(state)');
      final gift = source.indexOf('const RamadanGiftCard()');
      final premium = source.indexOf('const HomePremiumStrip()');
      final dashboard = source.indexOf('_buildDashboardCard(state, hero)');

      expect(cta, greaterThan(0));
      expect(cta, lessThan(gift),
          reason: 'nothing may sit between the greeting and the daily CTA');
      expect(cta, lessThan(premium),
          reason: 'HomePremiumStrip was unconditional and ABOVE the core loop '
              'for every free user — an upgrade ad outranking the purpose of '
              'the app');
      expect(cta, lessThan(dashboard),
          reason: 'the CTA must precede the lantern / Name / stats block, not '
              'sit ~800px below it');
    });

    test('the CTA no longer lives in the dashboard divider stack', () {
      // The old row sat between the Quests divider and the Name block, in the
      // identical rhythm to three navigation rows. Rebuilding it there would
      // undo the wave even if the card itself still looked right.
      final dashboardStart = source.indexOf('Widget _buildDashboardCard');
      final dashboardEnd = source.indexOf('Widget _buildMuhasabahCta');
      expect(dashboardStart, greaterThan(0));
      expect(dashboardEnd, greaterThan(dashboardStart));
      final dashboard = source.substring(dashboardStart, dashboardEnd);
      expect(dashboard.contains('_buildMuhasabahCta('), isFalse,
          reason: 'the CTA must not be rendered from inside the dashboard card');
    });

    test('nothing may be inserted between the greeting and the CTA', () {
      // THE PINS ABOVE GUARD REORDERING. THIS ONE GUARDS ACCUMULATION, WHICH IS
      // HOW IT ACTUALLY BROKE.
      //
      // Nobody ever decided to put the daily CTA 800px down the scroll. Things
      // piled up above it — a promo card, a premium strip, a stats block — each
      // addition locally reasonable, none of them "moving the CTA". The
      // `cta < gift`, `cta < premium`, `cta < dashboard` assertions are blind to
      // that: insert a hero banner, or a bare `SizedBox(height: 400)`, between
      // the greeting and the CTA and every one of them still passes while the
      // CTA sits below the fold again.
      //
      // So this asserts what the wave actually promises — *first thing after
      // the greeting* — rather than "before three specific widgets that
      // happened to exist in July 2026".
      //
      // If you are here because this failed: the fix is almost never to relax
      // it. Whatever you are adding belongs BELOW the CTA. The one legitimate
      // change is spacing, which is why a bare SizedBox is allowed through.
      final greeting = source.indexOf('_buildGreetingRow(state)');
      final cta = source.indexOf('_buildMuhasabahCta(state)');
      expect(greeting, greaterThan(0));
      expect(cta, greaterThan(greeting));

      final between = source.substring(greeting + '_buildGreetingRow(state)'.length, cta);
      // Strip comments — the gap is mostly the note explaining why it is a gap.
      final code = between
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('//'))
          .join(' ');

      // The ONE legitimate inhabitant: a spacing box expressed in design-system
      // tokens. Deliberately not `SizedBox(height: <any number>)` — a literal
      // `SizedBox(height: 400)` pushes the CTA off the fold just as effectively
      // as a widget does, and it is the cheaper mistake to make.
      final leftovers = code
          .replaceAll(
              RegExp(r'const SizedBox\(height: AppSpacing\.\w+\),?'), '')
          .replaceAll(RegExp(r'[,\s]'), '');

      expect(leftovers, isEmpty,
          reason: 'Something now renders between the greeting and the daily '
              'CTA: "$code". That is exactly how the CTA ended up ~800px into '
              'a ~700-760px viewport the first time — not by being moved, but '
              'by being buried. Put it below the CTA instead.');
    });

    test('the 11px question subtitle is gone', () {
      expect(
        source.contains('_buildMuhasabahPromptLabel'),
        isFalse,
        reason: 'the loop asks the question now; the home screen must not '
            'whisper it at 11px under the CTA',
      );
    });
  });
}
