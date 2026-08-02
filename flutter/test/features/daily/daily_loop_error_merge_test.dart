// `DailyLoopState.copyWith` must MERGE `error`, not assign it (task #10).
//
// It used to assign, so every state write that did not name `error` silently
// wiped one already set. The visible symptom was a failure view vanishing. The
// expensive one is that `discoverNameWithBypass` reads `state.error` to decide
// commit-versus-cancel — so a cleared error tells it to **commit a bypass for a
// reveal that never happened**, and the user pays 25 tokens for nothing.
//
// Wave 3 patched the single racing write it had found by passing
// `error: state.error` through by hand. That fixed one instance of a class.
// This makes the class impossible: preserving is the default, and the five
// writes that genuinely mean "clear it" say `clearError: true`.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  // ==========================================================================
  // The state class, directly. No provider, no async — just the merge rule.
  // ==========================================================================

  group('copyWith merges error', () {
    const errored = DailyLoopState(error: 'the reveal failed');

    test('a write that does not name error PRESERVES it', () {
      // THE REGRESSION. Under the old assign-semantics this returned null and
      // every caller had to remember `error: state.error` to avoid it.
      expect(errored.copyWith(streakCount: 3).error, 'the reveal failed');
      expect(errored.copyWith(checkinLoading: true).error, 'the reveal failed');
      expect(errored.copyWith(tokenBalance: 115).error, 'the reveal failed');
    });

    test('a write that names error REPLACES it', () {
      expect(errored.copyWith(error: 'something else').error, 'something else');
    });

    test('clearError is how you genuinely clear it', () {
      expect(errored.copyWith(clearError: true).error, isNull);
      // And it does not need any other field to travel with it.
      expect(
        errored.copyWith(clearError: true, checkinLoading: true).error,
        isNull,
      );
    });

    test('clearError wins over a simultaneously-passed error', () {
      // Nonsense to write deliberately, but it must be deterministic rather
      // than depending on argument order — same shape as clearReflectResult.
      expect(
        errored.copyWith(error: 'ignored', clearError: true).error,
        isNull,
      );
    });

    test('a null error stays null without ceremony', () {
      const clean = DailyLoopState();
      expect(clean.copyWith(streakCount: 1).error, isNull);
      expect(clean.copyWith(clearError: true).error, isNull);
    });
  });

  // ==========================================================================
  // The notifier — the property that actually costs money.
  // ==========================================================================

  group('on the live notifier', () {
    final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);
    late FakeSupabaseSyncService fakeSync;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      PurchaseService.debugSetOverride(_FreeUser());
      await hydrateTokenCache(balance: 100, totalSpent: 0);
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = 'UTC';
      debugDailyLoopClock = () => nowUtc;
      fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
            'current_day': 3,
            'last_claim_date': '2026-08-04',
            'token_balance': 115,
          };
    });

    tearDown(() {
      debugDailyLoopClock = () => DateTime.now().toUtc();
      debugResetUserLocalDay();
      SupabaseSyncService.debugReset();
      PurchaseService.debugClearOverride();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    test('an unrelated state write cannot erase a failure', () async {
      // The shape of the money bug, at the notifier level: something set an
      // error, and then an ordinary write that knows nothing about errors lands
      // on top of it.
      final notifier = DailyLoopNotifier(skipInitForTests: true);
      addTearDown(notifier.dispose);

      notifier.debugSetError('Something went wrong. Try again.');
      expect(notifier.state.error, isNotNull);

      notifier.debugSetCheckinLoading(true);

      expect(notifier.state.error, 'Something went wrong. Try again.',
          reason: 'a write that never mentions `error` must not decide the '
              'bypass commit-versus-cancel question');
    });

    test('discoverName still clears a stale error at entry', () async {
      // The other direction, and the reason `clearError` exists at all: a new
      // attempt must not inherit the previous attempt's failure, or the user
      // retries successfully and still sees the error view.
      final notifier = DailyLoopNotifier();
      addTearDown(notifier.dispose);
      await settle();

      notifier.debugSetError('a failure from the previous attempt');
      expect(notifier.state.error, isNotNull);

      await notifier.submitDailyAnswer('everything feels so heavy lately');
      await settle();

      expect(notifier.state.checkinDone, isTrue,
          reason: 'the retry genuinely succeeded');
      expect(notifier.state.error, isNull,
          reason: 'a successful retry must not still be showing the old '
              'failure — this is what the five clearError sites are for');
    });
  });
}
