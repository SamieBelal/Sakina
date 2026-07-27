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
