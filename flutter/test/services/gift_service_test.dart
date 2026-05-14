import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/gift_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late GiftService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 20);
    service = GiftService();
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    GiftService.debugGiftClock = () => DateTime.now().toUtc();
  });

  group('claim()', () {
    test('returns granted=true and caches expiresAt verbatim on first claim',
        () async {
      fakeSync.rpcHandlers['claim_sakina_gift'] = (_) async => {
            'granted': true,
            'granted_at': '2027-02-20T10:00:00.000Z',
            'expires_at': '2027-02-27T10:00:00.000Z',
            'reused': false,
          };

      final result = await service.claim('ramadan_2027');

      expect(result.granted, isTrue);
      expect(result.reused, isFalse);
      expect(result.expiresAt, DateTime.utc(2027, 2, 27, 10));

      // Verify scoped SharedPrefs cache.
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey)),
        '2027-02-27T10:00:00.000Z',
      );

      // Verify RPC call shape.
      expect(fakeSync.rpcCalls.single['fn'], 'claim_sakina_gift');
      expect(
        fakeSync.rpcCalls.single['params'],
        {'p_user': 'user-1', 'p_occasion': 'ramadan_2027'},
      );
    });

    test('returns granted=true with reused=true on idempotent re-claim',
        () async {
      fakeSync.rpcHandlers['claim_sakina_gift'] = (_) async => {
            'granted': true,
            'granted_at': '2027-02-18T10:00:00.000Z',
            'expires_at': '2027-02-25T10:00:00.000Z',
            'reused': true,
          };

      final result = await service.claim('ramadan_2027');

      expect(result.granted, isTrue);
      expect(result.reused, isTrue);
      expect(result.expiresAt, DateTime.utc(2027, 2, 25, 10));
    });

    test('returns denied(reason=outside_window) when server says so',
        () async {
      fakeSync.rpcHandlers['claim_sakina_gift'] = (_) async => {
            'granted': false,
            'reason': 'outside_window',
          };

      final result = await service.claim('ramadan_2027');

      expect(result.granted, isFalse);
      expect(result.reason, 'outside_window');
      expect(result.expiresAt, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey)),
        isNull,
        reason: 'denied claims must not populate the cache',
      );
    });

    test('returns denied(reason=unauthorized) on auth mismatch', () async {
      fakeSync.rpcHandlers['claim_sakina_gift'] = (_) async => {
            'granted': false,
            'reason': 'unauthorized',
          };

      final result = await service.claim('ramadan_2027');

      expect(result.granted, isFalse);
      expect(result.reason, 'unauthorized');
    });

    test('returns denied(reason=unknown_occasion) when occasion id is bad',
        () async {
      fakeSync.rpcHandlers['claim_sakina_gift'] = (_) async => {
            'granted': false,
            'reason': 'unknown_occasion',
          };

      final result = await service.claim('not_a_real_occasion');

      expect(result.granted, isFalse);
      expect(result.reason, 'unknown_occasion');
    });

    test('returns denied(reason=unauthorized) when no user is signed in',
        () async {
      fakeSync.userId = null;

      final result = await service.claim('ramadan_2027');

      expect(result.granted, isFalse);
      expect(result.reason, 'unauthorized');
      expect(fakeSync.rpcCalls, isEmpty,
          reason: 'short-circuit before hitting the RPC when no user');
    });

    test('returns denied(reason=unknown) when RPC returns null', () async {
      // No handler registered → fakeSync.callRpc returns null (the swallowed
      // -error path in production).
      final result = await service.claim('ramadan_2027');

      expect(result.granted, isFalse);
      expect(result.reason, 'unknown');
    });
  });

  group('currentOccasion()', () {
    test('returns the bracketing occasion id when clock is inside the window',
        () async {
      fakeSync.publicRows['islamic_occasions'] = [
        {
          'id': 'ramadan_2027',
          'starts_at': '2027-02-17T00:00:00.000Z',
          'ends_at': '2027-03-19T23:59:59.000Z',
        },
        {
          'id': 'eid_fitr_2027',
          'starts_at': '2027-03-20T00:00:00.000Z',
          'ends_at': '2027-03-22T23:59:59.000Z',
        },
      ];
      GiftService.debugGiftClock = () => DateTime.utc(2027, 2, 20);

      expect(await service.currentOccasion(), 'ramadan_2027');
    });

    test('returns the second occasion when the clock is in its window',
        () async {
      fakeSync.publicRows['islamic_occasions'] = [
        {
          'id': 'ramadan_2027',
          'starts_at': '2027-02-17T00:00:00.000Z',
          'ends_at': '2027-03-19T23:59:59.000Z',
        },
        {
          'id': 'eid_fitr_2027',
          'starts_at': '2027-03-20T00:00:00.000Z',
          'ends_at': '2027-03-22T23:59:59.000Z',
        },
      ];
      GiftService.debugGiftClock = () => DateTime.utc(2027, 3, 21);

      expect(await service.currentOccasion(), 'eid_fitr_2027');
    });

    test('returns null when clock is between occasions', () async {
      fakeSync.publicRows['islamic_occasions'] = [
        {
          'id': 'eid_fitr_2027',
          'starts_at': '2027-03-20T00:00:00.000Z',
          'ends_at': '2027-03-22T23:59:59.000Z',
        },
        {
          'id': 'eid_adha_2027',
          'starts_at': '2027-05-27T00:00:00.000Z',
          'ends_at': '2027-06-04T23:59:59.000Z',
        },
      ];
      GiftService.debugGiftClock = () => DateTime.utc(2027, 4, 15);

      expect(await service.currentOccasion(), isNull);
    });

    test('returns null when the table is empty', () async {
      fakeSync.publicRows['islamic_occasions'] = [];
      expect(await service.currentOccasion(), isNull);
    });
  });

  group('cachedExpiresAt()', () {
    test('returns null when no cached value', () async {
      expect(await service.cachedExpiresAt(), isNull);
    });

    test('returns the parsed UTC instant when present', () async {
      SharedPreferences.setMockInitialValues({
        fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey):
            '2027-02-27T10:00:00.000Z',
      });
      expect(
        await service.cachedExpiresAt(),
        DateTime.utc(2027, 2, 27, 10),
      );
    });

    test('returns null when cached value is malformed', () async {
      SharedPreferences.setMockInitialValues({
        fakeSync.scopedKey(giftPremiumUntilPrefsBaseKey): 'not-a-date',
      });
      expect(await service.cachedExpiresAt(), isNull);
    });
  });
}
