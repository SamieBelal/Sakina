import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/gift_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

// Mirrors the channel-mock pattern used in purchase_service_test.dart so the
// RC SDK doesn't try to initialize during a unit test.
const MethodChannel _channel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 20);

    // Silence the channel — every method returns null.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (_) async => null);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    GiftService.debugGiftClock = () => DateTime.now().toUtc();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    PurchaseService.debugClearOverride();
  });

  test('isPremium() returns false when no cached gift_premium_until + RC not '
      'initialized', () async {
    final service = PurchaseService.test();
    // Not initialized; no cache.
    expect(await service.isPremium(), isFalse);
  });

  test('isPremium() returns true when cached gift_premium_until is in the future',
      () async {
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey):
          '2027-02-27T10:00:00.000Z',
    });
    GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 20);

    final service = PurchaseService.test();
    expect(await service.isPremium(), isTrue,
        reason: 'cached gift window in the future flips isPremium() to true '
            'even when RC has not initialized');
  });

  test('isPremium() returns false when cached gift_premium_until has passed',
      () async {
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey):
          '2027-02-20T10:00:00.000Z',
    });
    // Clock is 1 day past the cached expiry.
    GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 21, 10);

    final service = PurchaseService.test();
    expect(await service.isPremium(), isFalse);
  });

  test('isPremium() returns false when cached value is malformed', () async {
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey): 'not-a-date',
    });

    final service = PurchaseService.test();
    expect(await service.isPremium(), isFalse);
  });

  test('isPremium() uses the debugGiftClock seam deterministically', () async {
    SharedPreferences.setMockInitialValues({
      fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey):
          '2027-03-01T00:00:00.000Z',
    });

    // Clock before expiry → premium active.
    GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 25);
    final service = PurchaseService.test();
    expect(await service.isPremium(), isTrue);

    // Advance the clock past expiry → premium lapses.
    GiftService.debugGiftClock = () => DateTime.utc(2027, 3, 2);
    expect(await service.isPremium(), isFalse);
  });
}
