import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/trial_expiry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

const MethodChannel _channel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-trial');
    SupabaseSyncService.debugSetInstance(fakeSync);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async => null);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  String trialKey() =>
      fakeSync.scopedKey(PurchaseService.trialPremiumUntilPrefsBaseKey);

  test('returns justExpired=true exactly once when a trial just lapsed',
      () async {
    // A cached trial timestamp in the past = the trial has lapsed.
    final past = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    SharedPreferences.setMockInitialValues({trialKey(): past.toIso8601String()});

    final first = await resolveTrialExpiry();
    expect(first.justExpired, isTrue,
        reason: 'first detection of a lapsed cached trial fires trial_expired');

    // The emit is one-shot: a second resume in the same lapsed state must NOT
    // re-fire (matches the lapsed-trial-sheet one-shot flag posture).
    final second = await resolveTrialExpiry();
    expect(second.justExpired, isFalse,
        reason: 'trial_expired emits at most once per trial');
  });

  test('returns justExpired=false while the trial is still active', () async {
    final future = DateTime.now().toUtc().add(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      trialKey(): future.toIso8601String(),
    });
    final decision = await resolveTrialExpiry();
    expect(decision.justExpired, isFalse);
  });

  test('returns justExpired=false when the user never had a trial', () async {
    // No cached trial timestamp at all.
    final decision = await resolveTrialExpiry();
    expect(decision.justExpired, isFalse);
  });

  test('still active then later expired → fires once on the transition',
      () async {
    final future = DateTime.now().toUtc().add(const Duration(seconds: 1));
    SharedPreferences.setMockInitialValues({
      trialKey(): future.toIso8601String(),
    });
    // Active: no emit.
    expect((await resolveTrialExpiry()).justExpired, isFalse);

    // Trial timestamp moves into the past (the Day-3 boundary crossed).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      trialKey(),
      DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String(),
    );

    expect((await resolveTrialExpiry()).justExpired, isTrue);
    expect((await resolveTrialExpiry()).justExpired, isFalse);
  });
}
