// Regression test for P0-4: when the user backgrounds the app or pops the
// reflect route mid-AI-call, `ReflectNotifier.dispose()` must cancel the
// in-flight bypass reservation so the user's tokens are refunded
// immediately rather than waiting up to 15 min for the server-side
// orphan-cleanup cron.
//
// Before the fix: `_activeBypassReservationId` was set by `submitWithBypass`,
// the AI call awaited indefinitely (user backgrounded or popped), and no
// dispose override fired the cancel RPC. Tokens stayed locked until the
// cron rescued them.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  final fixedNow = DateTime.parse('2026-04-10T12:00:00Z');

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

  test(
      'REGRESSION P0-4: dispose mid-AI-call cancels active bypass reservation',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'r-abc',
          'balance': 75,
          'bypasses_used': 1,
        };
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    // Stub the AI dependency to return a Future that never completes —
    // simulates an in-flight network call that the user pops away from.
    final neverCompletes = Completer<ai.ReflectResponse>();

    final container = ProviderContainer(overrides: [
      reflectProvider.overrideWith((ref) => ReflectNotifier(
            loadOnInit: false,
            dependencies: ReflectDependencies(
              getFollowUpQuestions: (_) async => const [],
              reflect: (_) => neverCompletes.future,
              now: () => fixedNow,
              createId: () => 'r-1',
            ),
          )),
    ]);

    final notifier = container.read(reflectProvider.notifier);
    notifier.setUserText('I feel anxious');

    // Kick off submitWithBypass but don't await — the AI never completes.
    unawaited(notifier.submitWithBypass());

    // Yield enough for reserveBypass to return and _activeBypassReservationId
    // to be set, plus for the AI call to be in flight.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Sanity: reserve fired.
    final reserveCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'reserve_ai_bypass');
    expect(reserveCalls, hasLength(1),
        reason: 'reserve should have fired before dispose');
    expect(cancelledIds, isEmpty,
        reason: 'cancel should not have fired yet');

    // Simulate route pop / app teardown.
    container.dispose();

    // Yield to let the fire-and-forget cancel RPC run.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cancelledIds, ['r-abc'],
        reason: 'dispose() must cancel the in-flight reservation');
  });
}
