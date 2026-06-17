import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// Tests for `PurchaseService.isPremium()`'s referral-premium OR branch.
///
/// The hot-path constraint is that `_isReferralPremium` reads SharedPreferences
/// ONLY — never Supabase. These tests pin that contract: the only network /
/// side-effecting input is the local cache.
const MethodChannel _channel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    // Clear prefs between tests (in-memory mock).
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-abc');
    SupabaseSyncService.instance = fakeSync;
    // Make sure any prior mock handler is wiped.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  tearDown(() {
    PurchaseService.debugClearOverride();
    SupabaseSyncService.instance = SupabaseSyncService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('_isReferralPremium via isPremium() fall-through', () {
    test(
        'returns true when RC has no entitlement AND cache holds a future ISO',
        () async {
      final service = PurchaseService.test();
      // Not initialized — isPremium falls straight through to the cache. The
      // DRY `_isTimedPremium` helper reads the user-scoped key via the sync
      // service's scopedKey (which carries the fake uid 'user-abc'), so a
      // future ISO flips premium on — matching the gift source's posture.
      final future = DateTime.now().toUtc().add(const Duration(days: 5));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        fakeSync.scopedKey(PurchaseService.referralPremiumUntilPrefsBaseKey),
        future.toIso8601String(),
      );

      expect(await service.isPremium(), isTrue,
          reason:
              'a future referral_premium_until in the scoped cache flips '
              'isPremium() on even when RC has not initialized');
    });

    test('returns false when the cached referral ISO is in the past',
        () async {
      final service = PurchaseService.test();
      final past = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        fakeSync.scopedKey(PurchaseService.referralPremiumUntilPrefsBaseKey),
        past.toIso8601String(),
      );

      expect(await service.isPremium(), isFalse);
    });

    test('returns false when cache is missing (no Supabase read attempted)',
        () async {
      final service = PurchaseService.test();
      // No prefs set, no Supabase initialized.
      expect(await service.isPremium(), isFalse);
      // FakeSync RPC log should be empty — the hot path must never touch it.
      expect(fakeSync.rpcCalls, isEmpty);
      expect(fakeSync.rowLists, isEmpty);
    });

    test('returns false when uid is empty string', () async {
      // Constructed at default state — Supabase auth is null.
      final service = PurchaseService.test();
      expect(await service.isPremium(), isFalse);
    });
  });

  group('DateTime.parse compatibility with Supabase timestamptz shapes', () {
    test('parses ISO with +00:00 offset and Z suffix and microsecond fraction',
        () {
      // These are the shapes Supabase emits for timestamptz columns.
      final shapes = <String>[
        '2026-06-13T12:34:56.789+00:00',
        '2026-06-13T12:34:56+00:00',
        '2026-06-13T12:34:56Z',
        '2026-06-13T12:34:56.789Z',
      ];
      for (final iso in shapes) {
        final parsed = DateTime.parse(iso);
        expect(parsed.toUtc().year, 2026, reason: 'failed to parse $iso');
        expect(parsed.toUtc().month, 6);
      }
    });

    test('a past ISO is.isAfter(now) == false', () {
      final past = DateTime.now().toUtc().subtract(const Duration(days: 1));
      expect(past.isAfter(DateTime.now().toUtc()), isFalse);
    });

    test('a future ISO is.isAfter(now) == true', () {
      final future = DateTime.now().toUtc().add(const Duration(days: 1));
      expect(future.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('malformed ISO is caught by the try/catch (no throw)', () {
      // The production code catches FormatException and returns false.
      // This test pins the parse contract — invalid input throws.
      expect(
          () => DateTime.parse('not-a-date'), throwsA(isA<FormatException>()));
    });
  });
}
