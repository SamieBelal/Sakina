// Regression test suite for DailyLoopNotifier's bypass + freebie lifecycle
// after the BypassFlowMixin adoption (Task 2.2 of plan
// 2026-05-24-pr26-deferred-followups).
//
// Pins the same dispose-chain + re-entry contracts that
// `test/features/reflect/reflect_dispose_cancel_test.dart` pins for the
// reflect surface — extended for discover-name with:
//
//   1. Happy commit regression — reservation_id is committed when the
//      discover work succeeds (no phantom cancel).
//   2. Cancel-on-state.error regression — when discover work writes
//      state.error, the wrapper cancels the reservation rather than
//      committing it.
//   3. Dispose AFTER reserve resolves (P0-4 for discover-name) — the
//      assigned reservation is cancelled from the dispose chain.
//   4. Dispose BEFORE reserve resolves (P1-B for discover-name) — the
//      late-resolving reservation is cancelled via the chained then().
//   5. Dispose BEFORE reserve resolves with rejection — no phantom cancel.
//   6. Rapid bypass taps — re-entry flag debounces concurrent invocations
//      so only one reserve RPC fires.
//   7. Rapid freebie taps — same debounce for the Day-1 freebie path so
//      `claim_first_bypass` doesn't fire twice on a double-tap.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

/// Returns a never-completing override for `discoverName`. Models the AI
/// path "user backgrounds the app mid-call".
Future<void> _neverCompletes(DailyLoopNotifier _) =>
    Completer<void>().future;

/// Returns an override that resolves immediately as a successful discover
/// (no state.error written → triggers the commit branch).
Future<void> Function(DailyLoopNotifier) _succeedsImmediately() {
  return (_) async {};
}

/// Returns an override that resolves immediately writing state.error
/// (→ triggers the cancel branch in `discoverNameWithBypass`). Uses the
/// `debugSetError` test seam to mirror the production body's
/// `state.copyWith(error: ...)` write without poking protected StateNotifier
/// internals from outside the class.
Future<void> Function(DailyLoopNotifier) _failsWithStateError() {
  return (self) async {
    self.debugSetError('discover failed');
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    await hydrateTokenCache(balance: 100, totalSpent: 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  ProviderContainer makeContainer({
    required Future<void> Function(DailyLoopNotifier) discoverNameOverride,
  }) {
    return ProviderContainer(overrides: [
      dailyLoopProvider.overrideWith(
        (ref) => DailyLoopNotifier(
          discoverNameOverride: discoverNameOverride,
        ),
      ),
    ]);
  }

  test(
      'REGRESSION 1 — happy commit: reserve → success → commit fires, no cancel',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-commit-1',
          'balance': 75,
          'bypasses_used': 1,
        };
    final committedIds = <String>[];
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['commit_ai_bypass'] = (params) async {
      committedIds.add(params!['p_reservation_id'] as String);
      return {'ok': true};
    };
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final container = makeContainer(
      discoverNameOverride: _succeedsImmediately(),
    );
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);

    await notifier.discoverNameWithBypass();
    // Yield once for any chained microtasks.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(committedIds, ['r-commit-1'],
        reason: 'happy-path: commit RPC must fire with the reservation id');
    expect(cancelledIds, isEmpty,
        reason: 'no cancel should fire on success path');
  });

  test(
      'REGRESSION 2 — cancel-on-state.error: discover fails → cancel fires, no commit',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-cancel-1',
          'balance': 75,
          'bypasses_used': 1,
        };
    final committedIds = <String>[];
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['commit_ai_bypass'] = (params) async {
      committedIds.add(params!['p_reservation_id'] as String);
      return {'ok': true};
    };
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final container = makeContainer(
      discoverNameOverride: _failsWithStateError(),
    );
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);

    await notifier.discoverNameWithBypass();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cancelledIds, ['r-cancel-1'],
        reason: 'state.error written by discoverName → cancel branch must fire');
    expect(committedIds, isEmpty,
        reason: 'commit must NOT fire when discover surfaced an error');
  });

  test(
      'REGRESSION P0-4 (discover-name) — dispose AFTER reserve resolves cancels reservation',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-late-2',
          'balance': 75,
          'bypasses_used': 1,
        };
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final container = makeContainer(discoverNameOverride: _neverCompletes);
    final notifier = container.read(dailyLoopProvider.notifier);

    unawaited(notifier.discoverNameWithBypass());
    // Let reserve resolve and trackActiveBypassReservation fire.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final reserveCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'reserve_ai_bypass');
    expect(reserveCalls, hasLength(1),
        reason: 'reserve should have fired before dispose');
    expect(cancelledIds, isEmpty, reason: 'no cancel yet — AI work in flight');

    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cancelledIds, ['r-late-2'],
        reason: 'dispose() must cancel the assigned reservation');
  });

  test(
      'REGRESSION P1-B (discover-name) — dispose BEFORE reserve resolves chains cancel',
      () async {
    final reserveCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['reserve_ai_bypass'] =
        (_) async => reserveCompleter.future;
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final container = makeContainer(discoverNameOverride: _neverCompletes);
    final notifier = container.read(dailyLoopProvider.notifier);

    unawaited(notifier.discoverNameWithBypass());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cancelledIds, isEmpty,
        reason: 'no cancel yet — reserve still in flight');

    container.dispose();

    reserveCompleter.complete({
      'ok': true,
      'reservation_id': 'r-very-late',
      'balance': 75,
      'bypasses_used': 1,
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cancelledIds, ['r-very-late'],
        reason: 'P1-B: late-resolving reservation must be cancelled via the '
            'chained then() set up in dispose()');
  });

  test(
      'REGRESSION P1-B (discover-name) — dispose BEFORE reserve resolves with null does NOT cancel',
      () async {
    final reserveCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['reserve_ai_bypass'] =
        (_) async => reserveCompleter.future;
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 0, 'balance': 100};
    };

    final container = makeContainer(discoverNameOverride: _neverCompletes);
    final notifier = container.read(dailyLoopProvider.notifier);

    unawaited(notifier.discoverNameWithBypass());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    container.dispose();

    reserveCompleter
        .complete({'ok': false, 'reason': 'no_tokens', 'balance': 5});
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cancelledIds, isEmpty,
        reason: 'P1-B: no phantom cancel when reserve was rejected');
  });

  test(
      'REGRESSION 6 — rapid bypass taps: re-entry flag debounces to ONE reserve RPC',
      () async {
    final reserveCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['reserve_ai_bypass'] =
        (_) async => reserveCompleter.future;
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (_) async =>
        {'ok': true, 'refunded_tokens': 25, 'balance': 100};

    final container = makeContainer(discoverNameOverride: _neverCompletes);
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);

    // Two rapid taps before reserve resolves.
    unawaited(notifier.discoverNameWithBypass());
    unawaited(notifier.discoverNameWithBypass());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final reserveCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'reserve_ai_bypass').toList();
    expect(reserveCalls, hasLength(1),
        reason: 're-entry guard must collapse concurrent taps to one reserve');

    // Let the in-flight reserve resolve so test teardown is clean.
    reserveCompleter.complete(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  test(
      'REGRESSION 7 — rapid freebie taps: re-entry flag debounces to ONE claim_first_bypass RPC',
      () async {
    final claimCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['claim_first_bypass'] =
        (_) async => claimCompleter.future;

    final container = makeContainer(discoverNameOverride: _neverCompletes);
    addTearDown(container.dispose);
    final notifier = container.read(dailyLoopProvider.notifier);

    // Two rapid taps before claim resolves.
    unawaited(notifier.discoverNameWithFirstBypass());
    unawaited(notifier.discoverNameWithFirstBypass());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final claimCalls = fakeSync.rpcCalls
        .where((c) => c['fn'] == 'claim_first_bypass')
        .toList();
    expect(claimCalls, hasLength(1),
        reason: 'Issue 7 pin: re-entry guard must collapse concurrent freebie '
            'taps to one claim_first_bypass RPC');

    // Let the in-flight claim resolve so test teardown is clean.
    claimCompleter.complete({'ok': false, 'reason': 'consumed'});
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}
