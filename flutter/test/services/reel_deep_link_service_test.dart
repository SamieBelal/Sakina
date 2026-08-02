import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/services/card_collection_service.dart'
    show allCollectibleNames;
import 'package:sakina/services/reel_deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One Ship W2-E4 — the `sakina://reel/<id>` and `sakina://feel/<emotion>`
/// parsers, cloned from the `pending_referral` pattern.
///
/// Everything here is best-effort by design: a malformed link is silently
/// ignored. There is no user to tell — they tapped a link and expect the app,
/// not an error — so the only defence against a bad link is that the parser
/// refuses to invent anything from it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Two ids that really are in the catalog (the pair a reel could name).
  final validPair = allCollectibleNames.take(2).map((n) => n.id).toList();

  group('extractReelArrival', () {
    test('accepts a plain reel link', () {
      final arrival = extractReelArrival(Uri.parse('sakina://reel/spring24'));
      expect(arrival, isNotNull);
      expect(arrival!.reelId, 'spring24');
      expect(arrival.nameIds, isEmpty);
    });

    test('accepts slug punctuation the campaign tooling emits', () {
      expect(extractReelArrival(Uri.parse('sakina://reel/tt_anx-01'))?.reelId,
          'tt_anx-01');
    });

    test('rejects a non-reel URI', () {
      for (final uri in [
        'sakina://r/ABCD2345',
        'sakina://feel/anxiety',
        'https://sakina.app/reel/spring24',
        'sakina://reel',
        'sakina://reel/',
      ]) {
        expect(extractReelArrival(Uri.parse(uri)), isNull, reason: uri);
      }
    });

    test('rejects an over-long id rather than bloating prefs', () {
      final huge = 'a' * (reelIdMaxLength + 1);
      expect(extractReelArrival(Uri.parse('sakina://reel/$huge')), isNull);
      final atLimit = 'a' * reelIdMaxLength;
      expect(
        extractReelArrival(Uri.parse('sakina://reel/$atLimit'))?.reelId,
        atLimit,
      );
    });

    test('rejects an id outside the slug charset', () {
      // The id ends up in `acquisition_promise.reel_id` and on analytics
      // events, so junk is refused at the door.
      for (final id in ['a b', r'a$b', 'a/b/c', 'a.b']) {
        final uri = Uri.parse('sakina://reel/${Uri.encodeComponent(id)}');
        expect(extractReelArrival(uri), isNull, reason: id);
      }
    });

    group('name_ids pair override', () {
      test('accepts two ids that exist in the catalog', () {
        final arrival = extractReelArrival(
          Uri.parse('sakina://reel/x?name_ids=${validPair[0]},${validPair[1]}'),
        );
        expect(arrival!.nameIds, validPair);
      });

      test('tolerates whitespace around the ids', () {
        final arrival = extractReelArrival(
          Uri.parse(
              'sakina://reel/x?name_ids=${validPair[0]}%20,%20${validPair[1]}'),
        );
        expect(arrival!.nameIds, validPair);
      });

      test('drops the override but KEEPS the reel id when it is junk', () {
        // The reel id is the arrival record; losing it because a query
        // parameter was malformed would erase the only evidence the reel sent
        // this user.
        for (final raw in [
          'abc,def',
          '${validPair[0]},notanint',
          '99999,${validPair[1]}',
          '-1,${validPair[1]}',
        ]) {
          final arrival =
              extractReelArrival(Uri.parse('sakina://reel/x?name_ids=$raw'));
          expect(arrival, isNotNull, reason: raw);
          expect(arrival!.reelId, 'x');
          expect(arrival.nameIds, isEmpty, reason: raw);
        }
      });

      test('rejects anything that is not exactly two ids', () {
        // Half a pair is not a pair: the reveal shows Name₁ and teases Name₂.
        expect(parseReelNameIdsOverride('${validPair[0]}'), isEmpty);
        expect(
          parseReelNameIdsOverride('${validPair[0]},${validPair[1]},7'),
          isEmpty,
        );
        expect(parseReelNameIdsOverride(''), isEmpty);
        expect(parseReelNameIdsOverride(null), isEmpty);
      });

      test('rejects an oversize list WITHOUT walking it', () {
        final huge = List.filled(10000, '1').join(',');
        expect(parseReelNameIdsOverride(huge), isEmpty);
      });

      test('rejects the same Name twice', () {
        // Name₂ would already be revealed, so there would be nothing to seal.
        expect(
          parseReelNameIdsOverride('${validPair[0]},${validPair[0]}'),
          isEmpty,
        );
      });

      test('rejects an id that is not in the catalog', () {
        expect(
          parseReelNameIdsOverride('${validPair[0]},424242'),
          isEmpty,
        );
      });
    });
  });

  group('extractFeelChip', () {
    test('accepts a taxonomy key verbatim', () {
      for (final chip in problemChips) {
        expect(
          extractFeelChip(Uri.parse('sakina://feel/${chip.chipKey}')),
          chip.chipKey,
        );
      }
    });

    test('falls back to the free-text keyword map for a loose emotion', () {
      // So a reel can link `sakina://feel/stressed` without knowing the
      // taxonomy. WHICH key it lands on is problem_chips_test's business; that
      // it lands on a real one at all is this test's.
      for (final emotion in ['stressed', 'exhausted', 'lonely']) {
        final matched = extractFeelChip(Uri.parse('sakina://feel/$emotion'));
        expect(matched, isNotNull, reason: emotion);
        expect(problemChipsByKey.containsKey(matched), isTrue, reason: emotion);
      }
    });

    test('an unmatched emotion yields null, never the comfort chip', () {
      // Pre-selecting a card would claim an answer on the user's behalf.
      expect(extractFeelChip(Uri.parse('sakina://feel/zzzzqqq')), isNull);
    });

    test('rejects a non-feel URI', () {
      for (final uri in [
        'sakina://reel/spring24',
        'sakina://r/ABCD2345',
        'https://sakina.app/feel/anxiety',
        'sakina://feel',
        'sakina://feel/',
      ]) {
        expect(extractFeelChip(Uri.parse(uri)), isNull, reason: uri);
      }
    });

    test('rejects an over-long emotion', () {
      final huge = 'a' * (feelEmotionMaxLength + 1);
      expect(extractFeelChip(Uri.parse('sakina://feel/$huge')), isNull);
    });
  });

  group('capture → drain round trip', () {
    test('a reel link survives to the onboarding entry, override included',
        () async {
      await captureReelDeepLink(
        Uri.parse('sakina://reel/x?name_ids=${validPair[0]},${validPair[1]}'),
      );

      final drained = await consumePendingReelArrival();
      expect(drained!.reelId, 'x');
      expect(drained.nameIds, validPair);
    });

    test('a feel link survives to the hook screen', () async {
      await captureReelDeepLink(Uri.parse('sakina://feel/anxiety'));
      expect(await consumePendingFeelChip(), 'anxiety');
    });

    test('draining clears the key, so a second onboarding run is not '
        're-attributed to an old reel', () async {
      await captureReelDeepLink(Uri.parse('sakina://reel/x'));
      expect(await consumePendingReelArrival(), isNotNull);
      expect(await consumePendingReelArrival(), isNull);

      await captureReelDeepLink(Uri.parse('sakina://feel/anxiety'));
      expect(await consumePendingFeelChip(), isNotNull);
      expect(await consumePendingFeelChip(), isNull);
    });

    test('nothing captured → nothing drained', () async {
      expect(await consumePendingReelArrival(), isNull);
      expect(await consumePendingFeelChip(), isNull);
    });

    test('a malformed link writes nothing at all', () async {
      await captureReelDeepLink(Uri.parse('sakina://reel/'));
      await captureReelDeepLink(Uri.parse('https://example.com/reel/x'));
      await captureReelDeepLink(Uri.parse('sakina://feel/zzzzqqq'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingReelArrivalPrefsKey), isNull);
      expect(prefs.getString(pendingFeelChipPrefsKey), isNull);
    });

    test('a corrupt stored blob drains as null instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        pendingReelArrivalPrefsKey: 'not json',
      });
      expect(await consumePendingReelArrival(), isNull);

      SharedPreferences.setMockInitialValues({
        pendingReelArrivalPrefsKey: '{"reel_id": 42}',
      });
      expect(await consumePendingReelArrival(), isNull);
    });

    test('a stored override is RE-validated on the way out', () async {
      // The blob is only as trustworthy as the build that wrote it; an id that
      // has since left the catalog must not reveal a Name that no longer
      // exists.
      SharedPreferences.setMockInitialValues({
        pendingReelArrivalPrefsKey: '{"reel_id":"x","name_ids":[424242,7]}',
      });
      final drained = await consumePendingReelArrival();
      expect(drained!.reelId, 'x');
      expect(drained.nameIds, isEmpty);
    });

    test('a stored chip that has left the taxonomy drains as null', () async {
      SharedPreferences.setMockInitialValues({
        pendingFeelChipPrefsKey: 'retired-chip',
      });
      expect(await consumePendingFeelChip(), isNull);
    });

    test('the prefs keys are UNSCOPED — the link fires before there is a user',
        () {
      expect(pendingReelArrivalPrefsKey, 'pending_reel_arrival');
      expect(pendingFeelChipPrefsKey, 'pending_feel_chip');
    });
  });

  group('ChipSelection.withPairNameIds (how the override lands)', () {
    test('swaps only the Names, never what the user said', () {
      const original = ChipSelection(
        contract: HookContract.sign,
        problemCategory: 'seeking_sign',
        hookType: HookType.chip,
        pairNameIds: [1, 2],
        chipKey: 'sign',
        problemTextRaw: 'typed words',
      );

      final overridden = original.withPairNameIds(validPair);

      expect(overridden.pairNameIds, validPair);
      expect(overridden.contract, original.contract);
      expect(overridden.problemCategory, original.problemCategory);
      expect(overridden.hookType, original.hookType);
      expect(overridden.chipKey, original.chipKey);
      expect(overridden.problemTextRaw, original.problemTextRaw);
    });
  });
}
