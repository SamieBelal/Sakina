// The reward ceremony, celebrated after the work (W4 Wave 4 — spec M1/§6).
//
// This file exists because the wave that introduced `DailyRewardCeremony`
// shipped it with **zero** coverage while deleting
// `daily_launch_overlay_loading_gate_test.dart` in the same commit. That
// deletion was justified — it pinned a loader guarding a *predicted* reward day
// that no longer exists, and the ceremony renders `result.day` from the actual
// claim result, which is the structural version of the same fix. But the
// surface that replaced it got nothing, so the reward path came out of the wave
// net-down one test file.
//
// What is pinned here is the thing that is easy to get wrong and impossible to
// see in review: **this widget renders what already happened.** The grant fires
// at answer-submit (Wave 3), not here. So the one behaviour it absolutely must
// have is refusing to celebrate a grant that did not occur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/widgets/daily_reward_ceremony.dart';
import 'package:sakina/services/daily_rewards_service.dart';

void main() {
  Future<void> pump(WidgetTester t, DailyRewardClaimResult? result) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: DailyRewardCeremony(result: result)),
    ));
    // The entry animation is delayed; settle so the copy is actually rendered.
    await t.pump(const Duration(seconds: 1));
  }

  group('it refuses to celebrate a grant that did not happen', () {
    testWidgets('a replayed claim renders nothing at all', (t) async {
      // `claim_daily_reward` is idempotent, so a replay comes back
      // `alreadyClaimed` with the awards still populated from the original
      // grant. Celebrating that would teach the user the ceremony is
      // decorative — the second time they see confetti for nothing, the first
      // time stops meaning anything either.
      await pump(
        t,
        const DailyRewardClaimResult(
          day: 4,
          tokensAwarded: 25,
          scrollsAwarded: 1,
          alreadyClaimed: true,
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.textContaining('You earned'), findsNothing);
      expect(find.text('Day 4'), findsNothing,
          reason: 'a replay is not an event — nothing about it is news');
    });

    testWidgets('no result at all renders nothing', (t) async {
      // The state field is null before a claim, and after a cold restart that
      // loses it. Neither is a moment to celebrate.
      await pump(t, null);
      expect(find.textContaining('You earned'), findsNothing);
      expect(find.textContaining('Day '), findsNothing);
    });

    testWidgets('a claim that awarded nothing renders nothing', (t) async {
      await pump(t, const DailyRewardClaimResult(day: 2));
      expect(find.textContaining('You earned'), findsNothing);
      expect(find.text('Day 2'), findsNothing,
          reason: 'an empty ceremony is worse than no ceremony — it is a '
              'celebration with no referent');
    });

    testWidgets('a tier-up scroll alone is NOT enough to celebrate', (t) async {
      // Deliberate asymmetry worth pinning: `earnedTierUpScroll` is in
      // `_hasSomethingToSay`, but the sentence is built only from tokens,
      // scrolls and the streak freeze — so a result carrying nothing else
      // would render the fallback line. Today the flag never arrives alone;
      // if that changes, this test is where it surfaces rather than on a
      // device showing "Your daily reward is yours." over an empty grant.
      await pump(
        t,
        const DailyRewardClaimResult(day: 3, earnedTierUpScroll: true),
      );
      expect(find.text('Your daily reward is yours.'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
    });
  });

  group('it names what actually landed', () {
    testWidgets('one award reads as a single clause', (t) async {
      await pump(
        t,
        const DailyRewardClaimResult(day: 1, tokensAwarded: 10),
      );
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('You earned 10 tokens.'), findsOneWidget);
    });

    testWidgets('two awards are joined with "and", no comma', (t) async {
      await pump(
        t,
        const DailyRewardClaimResult(
          day: 5,
          tokensAwarded: 25,
          scrollsAwarded: 1,
        ),
      );
      expect(find.text('You earned 25 tokens and 1 scroll.'), findsOneWidget,
          reason: 'singular "scroll" for one, and no serial comma at two');
    });

    testWidgets('three awards get the comma AND the "and"', (t) async {
      await pump(
        t,
        const DailyRewardClaimResult(
          day: 7,
          tokensAwarded: 50,
          scrollsAwarded: 2,
          earnedStreakFreeze: true,
        ),
      );
      expect(
        find.text('You earned 50 tokens, 2 scrolls and a streak freeze.'),
        findsOneWidget,
        reason: 'plural "scrolls" at two, and the list only grows a comma '
            'once there are three things in it',
      );
    });

    testWidgets('the day comes from the claim result, not a prediction',
        (t) async {
      // The whole reason the old loading-gate test could be deleted. The
      // superseded design rendered a day predicted from cache and then
      // corrected it when the RPC answered; this renders the server's number
      // or nothing.
      await pump(
        t,
        const DailyRewardClaimResult(day: 6, tokensAwarded: 30),
      );
      expect(find.text('Day 6'), findsOneWidget);
    });
  });

  group('the formatter does not consume its input', () {
    testWidgets('rebuilding with the same result renders the same sentence',
        (t) async {
      // Regression pin for `_sentenceFor`, which used to `removeLast()` off the
      // list handed to it. That was survivable only because `build()` happens
      // to rebuild the list every time; the moment anything hoisted it, the
      // sentence would shed one award per frame. A formatter must be a pure
      // function of its argument.
      const result = DailyRewardClaimResult(
        day: 7,
        tokensAwarded: 50,
        scrollsAwarded: 2,
        earnedStreakFreeze: true,
      );
      await pump(t, result);
      const expected = 'You earned 50 tokens, 2 scrolls and a streak freeze.';
      expect(find.text(expected), findsOneWidget);

      // Force several more builds of the same widget with the same result.
      for (var i = 0; i < 3; i++) {
        await t.pumpWidget(MaterialApp(
          home: Scaffold(body: DailyRewardCeremony(result: result)),
        ));
        await t.pump(const Duration(seconds: 1));
      }

      expect(find.text(expected), findsOneWidget,
          reason: 'the sentence must not erode across rebuilds');
    });
  });
}
