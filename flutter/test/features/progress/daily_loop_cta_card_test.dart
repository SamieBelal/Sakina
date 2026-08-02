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
        ),
      ));

      expect(find.text('Pick up where you left off'), findsOneWidget);
      await tester.tap(find.byType(DailyLoopCtaCard));
      await tester.pump();
      expect(started, 1);
    });
  });

  group('the completed state renders NOTHING (2026-08-01, founder)', () {
    // The card used to swap to a light-green "Today's muḥāsabah is complete"
    // panel that kept the same footprint. It is gone: once the day's work is
    // done the home screen stops reporting on it and the slot closes.
    //
    // What that removed, and why nothing was lost: the completed panel hosted
    // "Meet another Name", the metered re-roll. That same action is the PRIMARY
    // CTA of the muḥāsabah completion screen ("Seek Another Name",
    // muhasabah_screen.dart), which is the screen the user is standing on the
    // instant the loop completes — with the identical `canUse` gate, cap sheet
    // and `rerollPremium` wall. The home copy was the second of two, not the
    // only one, so deleting it costs no path and no upsell.

    testWidgets('the card occupies no space at all', (tester) async {
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          onStart: () {},
        ),
      ));

      // Height, not `Size.zero`: the host pins the width at 390 the way the
      // home Column does, so a collapsed card is 390x0 rather than 0x0.
      expect(tester.getSize(find.byType(DailyLoopCtaCard)).height, 0,
          reason: 'a zero-height card is the whole request — anything else '
              'leaves a gap or a panel where the CTA used to be');
    });

    testWidgets('none of the completed copy survives anywhere', (tester) async {
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          onStart: () {},
        ),
      ));

      expect(find.text('Today\'s muḥāsabah is complete'), findsNothing);
      expect(find.textContaining('You sat with'), findsNothing);
      expect(find.text('Meet another Name'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('and it cannot be tapped into the loop by accident',
        (tester) async {
      // Nothing rendered means nothing to hit — but assert it rather than
      // infer it, because a zero-size widget can still be hit-testable if
      // someone wraps it in a behavior-opaque gesture detector later.
      var started = 0;
      await tester.pumpWidget(host(
        DailyLoopCtaCard(
          state: DailyLoopCtaState.completed,
          onStart: () => started++,
        ),
      ));

      expect(find.byType(InkWell), findsNothing);
      expect(started, 0);
    });

    test('the completed card widget is deleted, not merely unused', () {
      expect(
        File('lib/features/progress/widgets/daily_loop_completed_card.dart')
            .existsSync(),
        isFalse,
        reason: 'leaving the widget behind invites it back onto the screen; '
            'the completion state is the muḥāsabah screen\'s job now',
      );
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
              onStart: () {},
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

    test('the completed slot collapses its SPACER too, not just the card', () {
      // A zero-height card still leaves a hole if the `SizedBox` that used to
      // separate it from the gift card is a sibling in the Column. The builder
      // therefore returns the spacer WITH the card and short-circuits both —
      // the same pattern DuaTimesCard uses ("collapses to SizedBox.shrink()
      // (no spacer wasted)") two entries further down the same list.
      final callSite = source.indexOf('_buildMuhasabahCta(state)');
      expect(callSite, greaterThan(0));
      final after = source.substring(
        callSite + '_buildMuhasabahCta(state)'.length,
        source.indexOf('const RamadanGiftCard()'),
      );
      final code = after
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('//'))
          .join(' ')
          .replaceAll(RegExp(r'[,\s]'), '');

      expect(code, isEmpty,
          reason: 'a sibling spacer after the CTA survives the completed '
              'state and reopens the gap the founder asked to close. Move it '
              'inside _buildMuhasabahCta so both disappear together. Found: '
              '"$code"');
    });

    test('the completed branch renders no card, no anchor, no animation', () {
      // Short-circuiting INSIDE DailyLoopCtaCard alone is not enough: the
      // builder wraps it in a TourAnchor (which would register a 0x0 key for
      // `beginMuhasabahCta`, giving the tour a spotlight over nothing) and a
      // fadeIn. Both must be skipped, so the guard belongs at the top of the
      // builder.
      final start = source.indexOf('Widget _buildMuhasabahCta');
      expect(start, greaterThan(0));
      // The whole builder, not a fixed byte window — a window that stops short
      // of the TourAnchor reports index -1 and the ordering assertion passes
      // for the wrong reason.
      final body = source.substring(start, source.indexOf('\n  }\n', start));
      final anchor = body.indexOf('TourAnchor(');
      final guard = body.indexOf('DailyLoopStep.completed');

      expect(anchor, greaterThan(0),
          reason: 'the builder must still anchor the unfinished faces for the '
              'tour — if this is -1 the ordering check below is vacuous');

      expect(guard, greaterThan(0),
          reason: 'the builder must test for the completed step');
      expect(guard, lessThan(anchor),
          reason: 'the completed check must run BEFORE the TourAnchor is '
              'built, or the tour anchors onto a zero-size box');
      expect(
        RegExp(r'DailyLoopStep\.completed[\s\S]{0,200}?SizedBox\.shrink\(\)')
            .hasMatch(body),
        isTrue,
        reason: 'the completed branch must return SizedBox.shrink()',
      );
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
