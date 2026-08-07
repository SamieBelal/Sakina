/// The allowance copy — what the app is allowed to SAY about a free user's
/// remaining reflections (2026-08-07).
///
/// This file exists because of a specific near-miss. The first draft of
/// `NewReflectionCopy.remainingLine` took a bare `int` and always rendered
/// *"left this week"*. That is true of the `reel_v1` weekly pool and false of
/// the warm-up, which is a LIFETIME per-feature grant that never refills — and
/// since every new account starts in warm-up, the line would have told
/// literally every new user that their three lifetime reflections came back on
/// Monday.
///
/// Nothing caught it on the way in. It surfaced only because an unrelated
/// LAYOUT assertion ("the archive opens in the top quarter") started failing
/// when the longer string wrapped the Journal's stats line to two rows. A
/// promise to a user should not depend on a pixel budget to be found wrong,
/// which is what these tests are for.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/journal/content/new_reflection_copy.dart';
import 'package:sakina/features/journal/journal_compose_action.dart';
import 'package:sakina/services/gating_service.dart';

void main() {
  const warmup3 = AllowanceSnapshot(AllowanceKind.warmup, remaining: 3);
  const warmup1 = AllowanceSnapshot(AllowanceKind.warmup, remaining: 1);
  const pool2 = AllowanceSnapshot(AllowanceKind.weeklyPool, remaining: 2);
  const pool1 = AllowanceSnapshot(AllowanceKind.weeklyPool, remaining: 1);

  group('the warm-up never promises a reset', () {
    test('neither form says "week" for a warm-up grant', () {
      for (final line in [
        NewReflectionCopy.remainingLine(warmup3),
        NewReflectionCopy.remainingShort(warmup3),
      ]) {
        expect(line.toLowerCase(), isNot(contains('week')),
            reason: 'the warm-up is a LIFETIME grant — it does not come back '
                'on Monday, and saying it does is a promise the gate will '
                'break: "$line"');
        expect(line.toLowerCase(), isNot(contains('tomorrow')));
        expect(line.toLowerCase(), isNot(contains('monday')));
      }
    });

    test('the arc subtitle inherits the same rule', () {
      // The arc is where a free user meets this number first, so a wrong
      // sentence here is the one they act on.
      final subtitle = JournalComposeCopy.subtitle(
        JournalComposeAction.newReflection,
        allowance: warmup3,
      );
      expect(subtitle.toLowerCase(), isNot(contains('week')));
      expect(subtitle, contains('3'));
    });
  });

  group('the weekly pool does say when it returns', () {
    test('both forms name the week', () {
      expect(NewReflectionCopy.remainingLine(pool2), contains('week'));
      expect(NewReflectionCopy.remainingShort(pool2), contains('week'));
    });

    test('the arc subtitle names it too', () {
      expect(
        JournalComposeCopy.subtitle(
          JournalComposeAction.newReflection,
          allowance: pool2,
        ),
        contains('week'),
      );
    });
  });

  group('singular', () {
    test('one reflection is not "1 reflections"', () {
      expect(NewReflectionCopy.remainingLine(pool1), '1 reflection left this week');
      expect(NewReflectionCopy.remainingLine(warmup1), contains('1 free reflection '));
      expect(NewReflectionCopy.remainingLine(warmup1),
          isNot(contains('reflections')));
    });

    test('two is plural', () {
      expect(NewReflectionCopy.remainingLine(pool2), contains('2 reflections'));
    });
  });

  group('a subscriber is never quoted a limit', () {
    test('the unlimited kind IS the premium line', () {
      // **One source, and this is the test that pins it.** The subtitle used to
      // take a separate `isPremium` flag which the Journal filled from
      // `premiumStateProvider` — a non-autoDispose FutureProvider that caches
      // for the life of the app. When a gift lapsed, the header (fresh) said
      // "9 free to try" while this line (cached) said "Included with premium",
      // on the same screen. `AllowanceKind.unlimited` comes from the same read
      // as the count, so the two halves cannot disagree.
      expect(
        JournalComposeCopy.subtitle(
          JournalComposeAction.newReflection,
          allowance: const AllowanceSnapshot(AllowanceKind.unlimited),
        ),
        'Included with premium',
      );
    });

    test('and NO other kind produces that line', () {
      // The regression in the other direction: a free user told their metered
      // reflections are included with a subscription they do not have.
      for (final a in <AllowanceSnapshot?>[
        warmup3,
        pool2,
        null,
        const AllowanceSnapshot(AllowanceKind.unmetered),
        const AllowanceSnapshot(AllowanceKind.weeklyPool, remaining: 0),
      ]) {
        expect(
          JournalComposeCopy.subtitle(JournalComposeAction.newReflection,
              allowance: a),
          isNot('Included with premium'),
          reason: '${a?.kind} was told it is included with premium',
        );
      }
    });
  });

  group('no number is better than a wrong one', () {
    test('an unresolved allowance falls back to the number-free sentence', () {
      expect(
        JournalComposeCopy.subtitle(
          JournalComposeAction.newReflection,
          allowance: null,
        ),
        'Uses one reflection',
      );
    });

    test('unmetered falls back too, never to "0"', () {
      // `unlimited` is excluded on purpose — it is no longer a "no number"
      // case, it is the premium case, covered above.
      final line = JournalComposeCopy.subtitle(
        JournalComposeAction.newReflection,
        allowance: const AllowanceSnapshot(AllowanceKind.unmetered),
      );
      expect(line, 'Uses one reflection');
      expect(line, isNot(contains('0')));
    });

    test('a spent pool shows the fallback, not "0 left this week"', () {
      // `hasCount` is false at zero on purpose. "0 left this week" is a wall
      // announced on a screen the user has not been blocked on yet; the sheet
      // is where a block gets explained.
      const spent = AllowanceSnapshot(AllowanceKind.weeklyPool, remaining: 0);
      expect(spent.hasCount, isFalse);
      expect(
        JournalComposeCopy.subtitle(
          JournalComposeAction.newReflection,
          allowance: spent,
        ),
        'Uses one reflection',
      );
    });
  });

  group('the other two rows are unaffected by any of this', () {
    test('the append is free on every tier', () {
      for (final a in <AllowanceSnapshot?>[
        pool2,
        null,
        const AllowanceSnapshot(AllowanceKind.unlimited),
      ]) {
        expect(
          JournalComposeCopy.subtitle(JournalComposeAction.addToTonight,
              allowance: a),
          'Free, any time',
        );
      }
    });

    test('the ritual quotes no allowance, because it spends none', () {
      final line = JournalComposeCopy.subtitle(
          JournalComposeAction.startTonight,
          allowance: pool2);
      expect(line, 'Keeps your streak');
      expect(line, isNot(contains('2')));
    });
  });
}
