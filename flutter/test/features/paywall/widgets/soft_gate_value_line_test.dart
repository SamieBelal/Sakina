import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/services/gating_service.dart'
    show GateReason, GatedFeature;

// The trigger-specific line carried to the condensed `soft_inapp` paywall.
//
// The whole point is that it is derived from the GateReason, not the cohort:
// a "this week" line in front of a legacy daily-cap user would be D.5's bug
// relocated to the surface where we ask for money.

void main() {
  group('softGateValueLine — weekly pool (reel_v1 only)', () {
    test('reflect names the week', () {
      expect(
        softGateValueLine(GatedFeature.reflect, GateReason.weeklyPool),
        'Your reflections for this week are used — Premium is unlimited.',
      );
    });

    test('builtDua names the week', () {
      expect(
        softGateValueLine(GatedFeature.builtDua, GateReason.weeklyPool),
        'Your duʿās for this week are used — Premium is unlimited.',
      );
    });

    test('discoverName + weeklyPool is impossible, so it falls back to the '
        'default rather than inventing copy', () {
      // consume_weekly_allowance rejects discover_name outright.
      expect(
        softGateValueLine(GatedFeature.discoverName, GateReason.weeklyPool),
        isNull,
      );
    });
  });

  group('softGateValueLine — discover re-roll (reel_v1 only)', () {
    test('states the daily-free rule, not a weekly one', () {
      expect(
        softGateValueLine(GatedFeature.discoverName, GateReason.rerollPremium),
        'One Name a day is free — Premium opens as many as you like.',
      );
    });
  });

  group('softGateValueLine — legacy daily cap', () {
    const daily = <GatedFeature, String>{
      GatedFeature.reflect:
          "Today's reflection is used — Premium is unlimited.",
      GatedFeature.builtDua: "Today's duʿā is used — Premium is unlimited.",
      GatedFeature.discoverName:
          "Today's discovery is used — Premium is unlimited.",
    };

    for (final entry in daily.entries) {
      test('${entry.key} on dailyCap says TODAY, never this week', () {
        expect(softGateValueLine(entry.key, GateReason.dailyCap), entry.value);
        expect(entry.value, isNot(contains('this week')));
      });

      test('${entry.key} on hadTrialNoBudget matches dailyCap', () {
        // Both are legacy-path-only reasons and describe the same allowance.
        expect(
          softGateValueLine(entry.key, GateReason.hadTrialNoBudget),
          entry.value,
        );
      });
    }
  });

  group('softGateValueLine — no line at all', () {
    test('premiumFairUse sells nothing to someone already paying', () {
      // buildPaywallUpgradeCallback already no-ops their CTA, so this paywall
      // never opens; returning a line would be dead copy at best.
      for (final feature in GatedFeature.values) {
        expect(
          softGateValueLine(feature, GateReason.premiumFairUse),
          isNull,
          reason: '$feature',
        );
      }
    });

    test('reasons that let the user through never produce a line', () {
      for (final feature in GatedFeature.values) {
        expect(softGateValueLine(feature, GateReason.ok), isNull);
        expect(softGateValueLine(feature, GateReason.warmupRemaining), isNull);
      }
    });
  });

  group('softGateValueLine — spelling matches the surface it renders on', () {
    test('the duʿā lines use the ʿayn, matching the benefits checklist they '
        'sit above', () {
      // PaywallCondensedPage renders this line directly above
      // PaywallBenefitChecklist, whose first item is "Unlimited reflections,
      // duʿās & Name discoveries". Two spellings inches apart on the screen
      // where we ask for money reads as sloppiness. The cap-sheet BODIES
      // deliberately still say "dua" — different surface, no neighbour.
      expect(
        softGateValueLine(GatedFeature.builtDua, GateReason.weeklyPool),
        contains('duʿās'),
      );
      expect(
        softGateValueLine(GatedFeature.builtDua, GateReason.dailyCap),
        contains('duʿā'),
      );
    });

    test('no trigger line contains the bare "dua" spelling', () {
      for (final feature in GatedFeature.values) {
        for (final reason in GateReason.values) {
          final line = softGateValueLine(feature, reason);
          if (line == null) continue;
          expect(RegExp(r'\bduas?\b').hasMatch(line), isFalse,
              reason: '$feature/$reason: "$line"');
        }
      }
    });
  });

  group('softGateValueLine — cross-tier safety', () {
    test('no legacy reason ever produces a weekly claim', () {
      // The D.5 bug, relocated: this is the assertion that stops it.
      for (final feature in GatedFeature.values) {
        for (final reason in [
          GateReason.dailyCap,
          GateReason.hadTrialNoBudget,
        ]) {
          final line = softGateValueLine(feature, reason);
          expect(line, isNotNull);
          expect(line, isNot(contains('this week')));
          expect(line, isNot(contains('Monday')));
        }
      }
    });

    test('no reel_v1 reason ever promises tomorrow', () {
      for (final feature in GatedFeature.values) {
        for (final reason in [
          GateReason.weeklyPool,
          GateReason.rerollPremium,
        ]) {
          final line = softGateValueLine(feature, reason);
          if (line == null) continue;
          expect(line.toLowerCase(), isNot(contains('tomorrow')));
        }
      }
    });

    test('every produced line is a complete sentence naming Premium', () {
      for (final feature in GatedFeature.values) {
        for (final reason in GateReason.values) {
          final line = softGateValueLine(feature, reason);
          if (line == null) continue;
          expect(line, contains('Premium'));
          expect(line, endsWith('.'));
        }
      }
    });
  });
}
