import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// Tests for `PurchaseService.isPremium()`'s trial-premium OR branch (the
/// reverse-trial source) and the shared `_isTimedPremium` helper that backs
/// gift / referral / trial.
///
/// Like the gift path, `_isTimedPremium` reads the user-scoped SharedPreferences
/// key ONLY — never Supabase from the hot path. These tests pin that contract
/// and the active/expired transition.
const MethodChannel _channel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-trial');
    SupabaseSyncService.debugSetInstance(fakeSync);
    // Silence the RC channel so the SDK doesn't try to initialize.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async => null);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('isPremium() is true when cached trial_premium_until is in the future',
      () async {
    final future = DateTime.now().toUtc().add(const Duration(days: 2));
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(PurchaseService.trialPremiumUntilPrefsBaseKey):
          future.toIso8601String(),
    });

    final service = PurchaseService.test();
    expect(await service.isPremium(), isTrue,
        reason: 'an active reverse-trial window flips isPremium() to true even '
            'when RC has not initialized');
  });

  test('isPremium() is false when cached trial_premium_until has passed',
      () async {
    final past = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(PurchaseService.trialPremiumUntilPrefsBaseKey):
          past.toIso8601String(),
    });

    final service = PurchaseService.test();
    expect(await service.isPremium(), isFalse);
  });

  test('isPremium() is false when no trial cache + RC not initialized',
      () async {
    final service = PurchaseService.test();
    expect(await service.isPremium(), isFalse);
  });

  test('isPremium() is false when cached trial value is malformed', () async {
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(PurchaseService.trialPremiumUntilPrefsBaseKey):
          'not-a-date',
    });
    final service = PurchaseService.test();
    expect(await service.isPremium(), isFalse);
  });

  group('shared _isTimedPremium helper backs all three timed sources', () {
    test('the gift, referral, and trial base keys are distinct', () {
      // The three timed-premium sources must use distinct scoped keys so they
      // don't clobber each other on a shared device.
      final keys = {
        PurchaseService.referralPremiumUntilPrefsBaseKey,
        PurchaseService.trialPremiumUntilPrefsBaseKey,
      };
      expect(keys.length, 2);
      expect(PurchaseService.trialPremiumUntilPrefsBaseKey,
          'trial_premium_until');
    });

    test('a future timed key flips premium on; an expired one does not',
        () async {
      // Referral source future → premium.
      SharedPreferences.setMockInitialValues({
        fakeSync.scopedKey(PurchaseService.referralPremiumUntilPrefsBaseKey):
            DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
      });
      var service = PurchaseService.test();
      expect(await service.isPremium(), isTrue);

      // Same source expired → not premium.
      SharedPreferences.setMockInitialValues({
        fakeSync.scopedKey(PurchaseService.referralPremiumUntilPrefsBaseKey):
            DateTime.now()
                .toUtc()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
      });
      service = PurchaseService.test();
      expect(await service.isPremium(), isFalse);
    });
  });

  test('refreshTrialPremiumCache is a no-op without an auth user (best-effort)',
      () async {
    final service = PurchaseService.test();
    // No Supabase auth user in unit tests → method returns without throwing
    // and writes nothing.
    await service.refreshTrialPremiumCache();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(
        fakeSync.scopedKey(PurchaseService.trialPremiumUntilPrefsBaseKey),
      ),
      isNull,
    );
  });
}
