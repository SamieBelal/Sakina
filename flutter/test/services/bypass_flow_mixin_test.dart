// Unit tests for BypassFlowMixin — the lifecycle abstraction shared by
// ReflectNotifier, DuasNotifier, and DailyLoopNotifier.
//
// The mixin is exercised here in isolation via a throwaway _TestNotifier.
// The 3 consumer notifiers have their own existing dispose-cancel tests
// (reflect_dispose_cancel_test.dart, build_dua_dispose_cancel_test.dart,
// discover_name_dispose_cancel_test.dart) which serve as the integration-
// level regression pins. The tests here cover the mixin's contract:
//
//   1. reserveActiveBypass returns the RPC result on success
//   2. reserveActiveBypass rethrows on RPC throw + clears _inflightReserveFuture
//   3. commitActiveBypassIfAny is a no-op when no active id
//   4. cancelActiveBypassIfAny is a no-op when no active id
//   5. disposeBypassFlow with active id → cancel RPC fires
//   6. disposeBypassFlow with in-flight future that resolves to reservation
//      → cancel fires on the resolved id (P1-B case)
//   7. disposeBypassFlow with in-flight future that resolves to null
//      → NO cancel fires (no phantom cancel for rejected reserve)
//   8. disposeBypassFlow with in-flight future that throws
//      → no cancel, no crash

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/bypass_flow_mixin.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _TestNotifier extends StateNotifier<int>
    with BypassFlowMixin<int> {
  _TestNotifier() : super(0);

  @override
  GatedFeature get bypassFeature => GatedFeature.reflect;
}

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
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
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  test('1. reserveActiveBypass returns the RPC result on success', () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-1',
          'balance': 75,
          'bypasses_used': 1,
        };
    final notifier = _TestNotifier();
    addTearDown(notifier.dispose);

    final reservation = await notifier.reserveActiveBypass();

    expect(reservation, isNotNull);
    expect(reservation!.reservationId, 'r-1');
    expect(notifier.bypassInFlight, isTrue,
        reason: 'submit-in-flight flag set by reserve');
    expect(notifier.debugInflightReserveFuture, isNull,
        reason: 'ownership transferred — future cleared after await resolves');
  });

  test(
      '2. reserveActiveBypass rethrows on RPC throw and clears _inflightReserveFuture',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async {
      throw Exception('network down');
    };
    final notifier = _TestNotifier();
    addTearDown(notifier.dispose);

    await expectLater(
      notifier.reserveActiveBypass(),
      throwsA(isA<Exception>()),
    );

    expect(notifier.debugInflightReserveFuture, isNull,
        reason: 'in-flight future cleared even on throw');
    expect(notifier.debugActiveBypassReservationId, isNull,
        reason: 'no active id assigned on rejected reserve');
  });

  test('3. commitActiveBypassIfAny is a no-op when no active id', () async {
    final notifier = _TestNotifier();
    addTearDown(notifier.dispose);

    await notifier.commitActiveBypassIfAny();

    final commitCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'commit_ai_bypass');
    expect(commitCalls, isEmpty);
  });

  test('4. cancelActiveBypassIfAny is a no-op when no active id', () async {
    final notifier = _TestNotifier();
    addTearDown(notifier.dispose);

    await notifier.cancelActiveBypassIfAny();

    final cancelCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'cancel_ai_bypass');
    expect(cancelCalls, isEmpty);
  });

  test('5. disposeBypassFlow with active id fires cancel RPC', () async {
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final notifier = _TestNotifier();
    notifier.trackActiveBypassReservation('r-active');

    notifier.disposeBypassFlow();

    // disposeBypassFlow fires-and-forgets via .ignore() — yield for it to land
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cancelledIds, ['r-active']);
    expect(notifier.debugActiveBypassReservationId, isNull);
  });

  test(
      '6. disposeBypassFlow with in-flight future that resolves to reservation '
      'fires chained cancel (P1-B case)', () async {
    final reserveCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['reserve_ai_bypass'] =
        (_) async => reserveCompleter.future;

    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    final notifier = _TestNotifier();
    // Kick off reserve, do NOT await
    final reserveFuture = notifier.reserveActiveBypass();
    // Yield so notifier captures _inflightReserveFuture
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(notifier.debugInflightReserveFuture, isNotNull);
    expect(cancelledIds, isEmpty);

    // Dispose while reserve is still pending
    notifier.disposeBypassFlow();

    // NOW resolve the reserve — should trigger the chained cancel
    reserveCompleter.complete({
      'ok': true,
      'reservation_id': 'late-r-xyz',
      'balance': 75,
      'bypasses_used': 1,
    });

    // Yield for both the reserve future and the chained .then() to land
    await reserveFuture.catchError((_) => null);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cancelledIds, ['late-r-xyz'],
        reason: 'P1-B: late-resolving reserve must be cancelled');
  });

  test(
      '7. disposeBypassFlow with in-flight future that resolves to null '
      'does NOT fire phantom cancel', () async {
    final reserveCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['reserve_ai_bypass'] =
        (_) async => reserveCompleter.future;

    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 0, 'balance': 100};
    };

    final notifier = _TestNotifier();
    final reserveFuture = notifier.reserveActiveBypass();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    notifier.disposeBypassFlow();

    // Reserve resolves to rejection — no server-side reservation exists
    reserveCompleter.complete({'ok': false, 'reason': 'no_tokens', 'balance': 5});
    await reserveFuture.catchError((_) => null);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cancelledIds, isEmpty,
        reason: 'no reservation_id → no cancel to fire');
  });

  test(
      '8. disposeBypassFlow with in-flight future that throws does not crash '
      'and does not call cancel', () async {
    final reserveCompleter = Completer<Map<String, dynamic>?>();
    fakeSync.rpcHandlers['reserve_ai_bypass'] =
        (_) async => reserveCompleter.future;

    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 0, 'balance': 100};
    };

    final notifier = _TestNotifier();
    final reserveFuture = notifier.reserveActiveBypass();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    notifier.disposeBypassFlow();

    // Reserve throws AFTER dispose — chained .catchError must swallow
    reserveCompleter.completeError(Exception('reserve threw'));
    await reserveFuture.catchError((_) => null);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cancelledIds, isEmpty,
        reason: 'reserve threw → no server reservation → nothing to cancel');
    // Test reaches here without unhandled-error crash → pass
  });
}
