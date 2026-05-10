// Regression test for ReflectNotifier.submit re-entry race.
//
// Same shape as the duas D-E5 bug (see
// `test/features/duas/submit_build_reentry_guard_test.dart`):
//   - `submit()` does an `await GatingService().canUse(...)` BEFORE setting
//     `state.screenState = loading`.
//   - Two rapid taps both pass the loading-state guard (still `input`),
//     both pass `canUse`, both set `_consumeFreeUsageOnSuccess = true`,
//     both fire the AI call → counter increments by 2 instead of 1.
//
// Fix: synchronous `_submitInFlight` flag set BEFORE any await, mirroring
// `DuasNotifier._submitInFlight`.
//
// Pinned via two scenarios:
//   1. Sequential — second tap arrives while the first is in `_doSubmit`
//      (loading flag is set). Existing `state.screenState == loading` guard
//      catches this.
//   2. Pre-loading race — second tap arrives while the first is still inside
//      `canUse` (no loading flag yet). Only the synchronous `_submitInFlight`
//      flag catches this.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.parse('2026-05-10T12:00:00Z');

  ai.ReflectResponse successResponse() => const ai.ReflectResponse(
        name: 'As-Salam',
        nameArabic: 'السلام',
        reframe: 'Steadiness can return.',
        story: 'A story.',
        verses: [
          ReflectVerse(
            arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
            translation: 'In the remembrance of Allah do hearts find rest.',
            reference: "Ar-Ra'd 13:28",
          ),
        ],
        duaArabic: 'دعاء',
        duaTransliteration: 'dua',
        duaTranslation: 'supplication',
        duaSource: 'source',
        relatedNames: [
          ai.RelatedName(name: 'Al-Lateef', nameArabic: 'اللطيف'),
        ],
        offTopic: false,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-reentry'),
    );
    // Capped phase — daily counter is the side-effect probe for double-fire.
    await GatingService().debugSetHadTrial(true);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('submit early-returns when screenState is loading (sequential race)',
      () async {
    var aiCallCount = 0;
    final completer = Completer<ai.ReflectResponse>();

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) {
          aiCallCount++;
          return completer.future;
        },
        now: () => fixedNow,
        createId: () => 'reflection-reentry',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel lost');

    // First tap kicks off submit; do NOT await.
    final firstFuture = notifier.submit();
    // Yield so the first call moves past `canUse` and enters `_reflect`,
    // flipping screenState=loading.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(notifier.state.screenState, ReflectScreenState.loading,
        reason: 'first submit should be in flight');
    expect(aiCallCount, 1);

    // Second tap during loading must early-return — no second AI call.
    await notifier.submit();
    expect(aiCallCount, 1,
        reason: 'guard must prevent a second AI call while loading');

    // Let the first call finish and verify clean end state.
    completer.complete(successResponse());
    await firstFuture;

    expect(notifier.state.screenState, ReflectScreenState.result);
    expect(notifier.state.error, isNull);
    expect(await getReflectUsageToday(), 1,
        reason: 'free counter must increment exactly once');
  });

  test(
      'two synchronous submit calls in the same microtask only run the AI once '
      '(pre-loading race — pinned by _submitInFlight, NOT by screenState guard)',
      () async {
    // Pre-loading race: both taps fire before the first call returns from
    // `GatingService().canUse()`. Without the synchronous `_submitInFlight`
    // flag, both pass the `screenState != loading` check (still `input`),
    // both set `_consumeFreeUsageOnSuccess = true`, both call AI, both call
    // `markUsed` → daily counter advances by 2. Same shape as the duas D-E5
    // bug fixed by `submit_build_reentry_guard_test.dart`.
    var aiCallCount = 0;
    final completer = Completer<ai.ReflectResponse>();

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) {
          aiCallCount++;
          return completer.future;
        },
        now: () => fixedNow,
        createId: () => 'reflection-pre-race',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('Help me find clarity in my decisions today.');

    // Fire BOTH submits without awaiting between them.
    final first = notifier.submit();
    final second = notifier.submit();

    // Let both calls progress through any pending awaits.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(aiCallCount, 1,
        reason:
            'synchronous _submitInFlight guard must reject the second tap '
            'even when the first has not yet entered _reflect');

    completer.complete(successResponse());
    await Future.wait([first, second]);

    expect(notifier.state.result, isNotNull);
    expect(await getReflectUsageToday(), 1,
        reason:
            'free counter must read exactly 1 — proves only one markUsed fired');
  });
}
