// Regression test for §7 D-E5: rapid double-tap during loading.
//
// `DuasNotifier.submitBuild` and `submitBuildWithToken` had no protection
// against concurrent invocation. Two rapid taps would both pass the
// `buildLoading=false` check, both call `_dependencies.buildDua`, both call
// `incrementBuiltDuaUsage` on success → free counter +2 instead of +1, and
// possibly two `buildResult` writes racing.
//
// Fix at top of both submit functions:
//
//     if (state.buildLoading) return;
//
// Same pattern as `daily_loop_provider.answerCheckin` (B1, 2026-04-26). This
// test pins both guards using a `Completer`-controlled fake `buildDua` so we
// can stage the "second tap arrives while first is still in flight" race
// without racing real timers.
//
// `incrementBuiltDuaUsage` reads/writes SharedPreferences scoped to the
// current user, so the daily-usage counter doubles as a side-effect probe:
// after two `submitBuild` calls the counter must read 1, never 2.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedNow = DateTime.parse('2026-04-26T12:00:00Z');

  BuiltDuaResponse buildResponse() => const BuiltDuaResponse(
        arabic: 'اللهم اهدني',
        transliteration: 'Allahumma ihdini',
        translation: 'O Allah, guide me',
        breakdown: [
          BuiltDuaSection(
            label: 'Opening',
            arabic: 'الحمد لله',
            transliteration: 'Alhamdulillah',
            translation: 'All praise is for Allah',
          ),
        ],
        namesUsed: [],
        relatedDuas: [],
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-reentry'),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test('submitBuild early-returns when buildLoading is true', () async {
    var buildCallCount = 0;
    final completer = Completer<BuiltDuaResponse>();

    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) {
          buildCallCount++;
          return completer.future;
        },
        now: () => fixedNow,
        createId: () => 'dua-reentry',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setBuildNeed('I need patience with my family.');

    // First tap: kicks off the build, do NOT await yet.
    final firstFuture = notifier.submitBuild();
    // Yield so the first call enters _doBuild and flips buildLoading=true
    // before the second call lands.
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.buildLoading, isTrue,
        reason: 'first submit should be in flight');
    expect(buildCallCount, 1);

    // Second tap arrives while the first is still loading. Must early-return
    // without a second buildDua call.
    await notifier.submitBuild();

    expect(buildCallCount, 1,
        reason: 'guard must prevent a second AI call while loading');

    // Let the first call finish and confirm we end in a clean state.
    completer.complete(buildResponse());
    await firstFuture;

    expect(notifier.state.buildLoading, isFalse);
    expect(notifier.state.buildResult, isNotNull);
    expect(notifier.state.error, isNull);
    // Counter must read 1, not 2.
    expect(await getBuiltDuaUsageToday(), 1,
        reason: 'free counter must increment exactly once');
  });

  test(
      'two synchronous submitBuild calls in the same microtask only run the AI once',
      () async {
    // Pre-loading race: previously, two taps fired before the first call
    // returned from `canBuildDuaFree()` would BOTH pass the
    // `state.buildLoading` guard (since `_doBuild` only sets that flag after
    // the async free-check). Caught live on sim 2026-04-26 with
    // `built_dua_uses=2` after a single user double-tap. The fix is a
    // synchronous `_submitInFlight` flag set BEFORE any await.
    var buildCallCount = 0;
    final completer = Completer<BuiltDuaResponse>();

    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) {
          buildCallCount++;
          return completer.future;
        },
        now: () => fixedNow,
        createId: () => 'dua-pre-race',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setBuildNeed('Help me find clarity in my decisions today.');

    // Fire BOTH submits without awaiting between them. The second call
    // enters before the first has finished `canBuildDuaFree()`. Without the
    // synchronous guard, both would proceed and call `buildDua` twice.
    final first = notifier.submitBuild();
    final second = notifier.submitBuild();

    // Let both calls progress through any pending awaits.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(buildCallCount, 1,
        reason:
            'synchronous _submitInFlight guard must reject the second tap '
            'even when the first has not yet entered _doBuild');

    completer.complete(buildResponse());
    await Future.wait([first, second]);

    expect(notifier.state.buildResult, isNotNull);
  });

  test('submitBuildWithToken early-returns when buildLoading is true',
      () async {
    var buildCallCount = 0;
    final completer = Completer<BuiltDuaResponse>();

    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) {
          buildCallCount++;
          return completer.future;
        },
        now: () => fixedNow,
        createId: () => 'dua-reentry-token',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setBuildNeed('Help me through this difficulty.');

    final firstFuture = notifier.submitBuildWithToken();
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.buildLoading, isTrue);
    expect(buildCallCount, 1);

    // Second token-spend tap: must early-return.
    await notifier.submitBuildWithToken();

    expect(buildCallCount, 1,
        reason: 'guard must prevent a second AI call on the token-spend path');

    completer.complete(buildResponse());
    await firstFuture;

    expect(notifier.state.buildLoading, isFalse);
    expect(notifier.state.buildResult, isNotNull);
  });
}
