import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/lapsed_trial_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  bool premium = false;
  bool trial = false;

  @override
  Future<bool> isPremium() async => premium;

  @override
  Future<bool> hadTrial() async => trial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePurchaseService purchase;
  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    purchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(purchase);
  });

  tearDown(() {
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
  });

  test('returns null when user is currently premium (still subscribed)',
      () async {
    purchase.premium = true;
    purchase.trial = true;
    expect(await resolveLapsedTrialDecision(), isNull);
  });

  test('returns null when user never had a trial', () async {
    purchase.premium = false;
    purchase.trial = false;
    expect(await resolveLapsedTrialDecision(), isNull);
  });

  test('returns a decision when had_trial=true AND not premium AND not yet shown',
      () async {
    purchase.premium = false;
    purchase.trial = true;

    final decision = await resolveLapsedTrialDecision();
    expect(decision, isNotNull);
    expect(decision!.activity.momentsDuringTrial, 0,
        reason: 'no usage today, fallback copy will render');
    expect(decision.activity.daysActiveDuringTrial, 0);
  });

  test('returns null on subsequent calls after markShown — one-shot latch',
      () async {
    purchase.premium = false;
    purchase.trial = true;

    final first = await resolveLapsedTrialDecision();
    expect(first, isNotNull);
    await first!.markShown();

    final second = await resolveLapsedTrialDecision();
    expect(second, isNull,
        reason:
            'one-shot: must not re-show after the user has seen it once');
  });

  test('activity stats sum reflect + builtDua + discoverName usage today',
      () async {
    purchase.premium = false;
    purchase.trial = true;

    await incrementReflectUsage();
    await incrementReflectUsage();
    await incrementBuiltDuaUsage();
    await incrementDiscoverNameUsage();

    final decision = await resolveLapsedTrialDecision();
    expect(decision!.activity.momentsDuringTrial, 4);
    expect(decision.activity.daysActiveDuringTrial, 1);
  });

  test('shown flag is per-user (scoped) — User A flag does not block User B',
      () async {
    purchase.premium = false;
    purchase.trial = true;

    final firstUser = await resolveLapsedTrialDecision();
    expect(firstUser, isNotNull);
    await firstUser!.markShown();

    // Switch to a different user via the fake sync service.
    fakeSync.userId = 'user-2';
    final secondUser = await resolveLapsedTrialDecision();
    expect(secondUser, isNotNull,
        reason:
            'sheet-shown flag must be scoped per user; new user gets a fresh chance');
  });
}
