// Regression test for P0-4: when the user backgrounds the app or pops the
// build-a-dua route mid-AI-call, `DuasNotifier.dispose()` must cancel the
// in-flight bypass reservation so the user's tokens are refunded
// immediately rather than waiting up to 15 min for the server-side
// orphan-cleanup cron.
//
// Before the fix: `_activeBypassReservationId` was set by
// `submitBuildWithBypass`, the AI call awaited indefinitely (user
// backgrounded or popped), and the existing `dispose()` override only
// cancelled the progress timer — no cancel RPC. Tokens stayed locked
// until the cron rescued them.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/gating_service.dart';
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
  final fixedNow = DateTime.parse('2026-04-26T12:00:00Z');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-dua');
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
          'reservation_id': 'r-dua-xyz',
          'balance': 75,
          'bypasses_used': 1,
        };
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (params) async {
      cancelledIds.add(params!['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    // Stub the buildDua dependency with a Future that never completes —
    // simulates an in-flight network call that the user pops away from.
    final neverCompletes = Completer<BuiltDuaResponse>();

    final container = ProviderContainer(overrides: [
      duasProvider.overrideWith((ref) => DuasNotifier(
            loadOnInit: false,
            dependencies: DuasDependencies(
              findDuas: (_) async => throw UnimplementedError(),
              buildDua: (_) => neverCompletes.future,
              now: () => fixedNow,
              createId: () => 'dua-1',
            ),
            resultRevealDelay: Duration.zero,
          )),
    ]);

    final notifier = container.read(duasProvider.notifier);
    notifier.setBuildNeed('Help me find patience with my family today.');

    // Kick off submitBuildWithBypass but don't await — the AI never completes.
    unawaited(notifier.submitBuildWithBypass());

    // Yield enough for reserveBypass to return and _activeBypassReservationId
    // to be set, plus for the AI call to be in flight.
    await Future<void>.delayed(const Duration(milliseconds: 50));

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

    expect(cancelledIds, ['r-dua-xyz'],
        reason: 'dispose() must cancel the in-flight reservation');
  });
}
