import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One Ship W2-B3 — the v8 state blob.
///
/// Everything the reel flow gathers before signup lives here, so the round-trip
/// is what guarantees an app kill mid-flow resumes with the SAME Names.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const hookSelection = ChipSelection(
    contract: HookContract.problem,
    problemCategory: 'anxiety',
    hookType: HookType.chip,
    chipKey: 'anxiety',
    pairNameIds: [6, 35],
  );

  test('toJson stamps version 8', () {
    expect(const OnboardingState().toJson()['version'], 8);
  });

  test('every v8 field round-trips through prefs', () {
    const state = OnboardingState(
      currentPage: 3,
      contract: HookContract.sign,
      problemCategory: 'unspoken',
      chipKey: 'sign',
      problemTextRaw: 'I cannot say it',
      pairNameIds: [2, 36],
      aspiration: 'closeness',
      carryingDuration: 'months',
      reelSource: 'tiktok',
      reelId: 'r-1234',
      hookType: HookType.reel,
      onboardingFlow: 'reel_v1',
    );

    final restored = OnboardingState.fromJson(state.toJson());

    expect(restored.contract, HookContract.sign);
    expect(restored.problemCategory, 'unspoken');
    expect(restored.chipKey, 'sign');
    expect(restored.problemTextRaw, 'I cannot say it');
    expect(restored.pairNameIds, [2, 36]);
    expect(restored.aspiration, 'closeness');
    expect(restored.carryingDuration, 'months');
    expect(restored.reelSource, 'tiktok');
    expect(restored.reelId, 'r-1234');
    expect(restored.hookType, HookType.reel);
    expect(restored.onboardingFlow, 'reel_v1');
    expect(restored.currentPage, 3);
  });

  group('the reel link\'s name_ids override', () {
    test('round-trips with the rest of the arrival', () {
      const state = OnboardingState(
        reelId: 'r-1234',
        hookType: HookType.reel,
        reelPairOverride: [2, 36],
      );

      final restored = OnboardingState.fromJson(state.toJson());

      expect(restored.reelPairOverride, [2, 36],
          reason: 'the link is drained once at launch; the hook may not be '
              'answered until several app kills later');
    });

    test('setReelArrival persists it alongside the reel id', () {
      final notifier = OnboardingNotifier()
        ..setReelArrival(reelId: 'r-42', nameIds: const [6, 35]);

      expect(notifier.state.reelId, 'r-42');
      expect(notifier.state.reelPairOverride, [6, 35]);
      expect(notifier.state.hookType, HookType.reel);
    });

    test('a link with no name_ids overrides nothing', () {
      final notifier = OnboardingNotifier()..setReelArrival(reelId: 'r-42');

      expect(notifier.state.reelPairOverride, isEmpty);
    });

    test('an older v8 blob without the key reads as no override', () {
      // Additive within v8 — a blob written before this field existed must
      // restore, not be discarded.
      final legacyBlob = const OnboardingState(reelId: 'r-1').toJson()
        ..remove('reelPairOverride');

      final restored = OnboardingState.fromJson(legacyBlob);

      expect(restored.reelId, 'r-1');
      expect(restored.reelPairOverride, isEmpty);
    });
  });

  test('a v7 blob is discarded — its page indices mean a different flow', () {
    final v7 = const OnboardingState(currentPage: 12, intention: 'peace')
        .toJson()
      ..['version'] = 7;

    final restored = OnboardingState.fromJson(v7);

    expect(restored.currentPage, 0);
    expect(restored.intention, isNull);
    expect(restored.contract, isNull);
  });

  group('acquisitionPromise', () {
    test('is null until the hook is answered', () {
      expect(const OnboardingState().acquisitionPromise, isNull);
    });

    test('always carries the contract key the DB check requires', () {
      const state = OnboardingState(
        contract: HookContract.problem,
        hookType: HookType.chip,
        problemCategory: 'rizq',
      );
      expect(state.acquisitionPromise, {
        'hook_type': 'chip',
        'contract': 'problem',
        'problem_category': 'rizq',
      });
    });

    test('includes reel_id only for a reel arrival', () {
      const state = OnboardingState(
        contract: HookContract.problem,
        hookType: HookType.reel,
        problemCategory: 'heavy',
        reelId: 'r-99',
      );
      expect(state.acquisitionPromise!['reel_id'], 'r-99');
    });

    test('emits nothing rather than a half-written promise', () {
      const noHookType = OnboardingState(contract: HookContract.problem);
      expect(noHookType.acquisitionPromise, isNull);
    });
  });

  group('notifier setters', () {
    test('applyHookSelection writes the whole promise in one go', () {
      final notifier = OnboardingNotifier()..applyHookSelection(hookSelection);

      expect(notifier.state.contract, HookContract.problem);
      expect(notifier.state.problemCategory, 'anxiety');
      expect(notifier.state.chipKey, 'anxiety');
      expect(notifier.state.hookType, HookType.chip);
      expect(notifier.state.pairNameIds, [6, 35]);
      expect(notifier.state.acquisitionPromise!['contract'], 'problem');
    });

    test('re-answering with unmatched free text clears the earlier chip', () {
      final notifier = OnboardingNotifier()
        ..applyHookSelection(hookSelection)
        ..applyHookSelection(const ChipSelection(
          contract: HookContract.problem,
          problemCategory: problemCategoryUnmatched,
          hookType: HookType.freeText,
          pairNameIds: [2, 36],
          problemTextRaw: 'qwerty',
        ));

      expect(notifier.state.chipKey, isNull);
      expect(notifier.state.problemCategory, problemCategoryUnmatched);
      expect(notifier.state.problemTextRaw, 'qwerty');
      expect(notifier.state.pairNameIds, [2, 36]);
    });

    test('a reel arrival stays a reel arrival after they answer the hook', () {
      // hook_type is ORIGIN. The reel visitor taps a chip like everyone else;
      // stamping them `chip` would make HookType.reel unreachable in the data
      // and erase the only marker that the reel sent them.
      final notifier = OnboardingNotifier()
        ..setReelArrival(reelId: 'r-42')
        ..applyHookSelection(hookSelection);

      expect(notifier.state.hookType, HookType.reel);
      expect(notifier.state.chipKey, 'anxiety',
          reason: 'what they tapped is still recorded');
      expect(notifier.state.acquisitionPromise, {
        'reel_id': 'r-42',
        'hook_type': 'reel',
        'contract': 'problem',
        'problem_category': 'anxiety',
      });
    });

    test('free text after a reel arrival is still a reel arrival', () {
      final notifier = OnboardingNotifier()
        ..setReelArrival(reelId: 'r-42')
        ..applyHookSelection(const ChipSelection(
          contract: HookContract.problem,
          problemCategory: problemCategoryUnmatched,
          hookType: HookType.freeText,
          pairNameIds: [2, 36],
          problemTextRaw: 'qwerty',
        ));

      expect(notifier.state.hookType, HookType.reel);
      expect(notifier.state.problemTextRaw, 'qwerty');
    });

    test('without a reel arrival the selection still sets hook_type', () {
      final chip = OnboardingNotifier()..applyHookSelection(hookSelection);
      expect(chip.state.hookType, HookType.chip);

      final typed = OnboardingNotifier()
        ..applyHookSelection(const ChipSelection(
          contract: HookContract.problem,
          problemCategory: 'heavy',
          hookType: HookType.freeText,
          pairNameIds: [2, 36],
          problemTextRaw: 'everything hurts',
        ));
      expect(typed.state.hookType, HookType.freeText);
    });

    test('a chip tap can still replace an earlier chip tap', () {
      final notifier = OnboardingNotifier()
        ..applyHookSelection(hookSelection)
        ..applyHookSelection(const ChipSelection(
          contract: HookContract.sign,
          problemCategory: 'unspoken',
          hookType: HookType.chip,
          chipKey: 'sign',
          pairNameIds: [2, 36],
        ));

      expect(notifier.state.hookType, HookType.chip);
      expect(notifier.state.chipKey, 'sign');
    });

    test('setOnboardingFlow rejects anything off the wire vocabulary', () {
      final notifier = OnboardingNotifier();

      expect(() => notifier.setOnboardingFlow('reel'),
          throwsA(isA<ArgumentError>()));
      expect(() => notifier.setOnboardingFlow(''),
          throwsA(isA<ArgumentError>()));
      expect(notifier.state.onboardingFlow, isNull,
          reason: 'a rejected value must not land on state');

      notifier.setOnboardingFlow(OnboardingFlow.legacy);
      expect(notifier.state.onboardingFlow, 'legacy');
    });

    test('the Wave D / E setters land on state', () {
      final notifier = OnboardingNotifier()
        ..setCarryingDuration('years')
        ..setAspiration('peace')
        ..setReelSource('instagram')
        ..setReelArrival(reelId: 'r-7')
        ..setOnboardingFlow('reel_v1');

      expect(notifier.state.carryingDuration, 'years');
      expect(notifier.state.aspiration, 'peace');
      expect(notifier.state.reelSource, 'instagram');
      expect(notifier.state.reelId, 'r-7');
      expect(notifier.state.hookType, HookType.reel);
      expect(notifier.state.onboardingFlow, 'reel_v1');
    });
  });
}
