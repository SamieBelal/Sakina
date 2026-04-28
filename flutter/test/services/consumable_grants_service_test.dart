// Pins ConsumableGrantsService — the orphan-recovery layer that catches
// consumable purchases that completed at OS level but never reached
// `earnTokens()` (e.g., app killed mid-flow).
//
// Coverage:
//   - markCredited dedup (atomic compare-and-set)
//   - processCustomerInfo grants tokens / scrolls for known SKUs and skips
//     already-credited transactions
//   - Unknown SKUs are logged but not granted (no crash, no false credit)
//   - initializeForUser baselines existing transactions WITHOUT granting,
//     and is a no-op on second call (one baseline per user/device)
//   - 200-entry credited-set cap drops oldest entries
//   - Concurrency: markCredited lock guards the credited-set read-write
//   - Pre-baseline race: listener-only path marks but does not grant
//   - Grant-failure rollback: failed earn_tokens RPC un-marks the txn so
//     the next listener fire retries
//   - 2026-04-28 stale-balance fix:
//       * grantForMostRecentPurchase accepts an explicit CustomerInfo and
//         skips the racy `Purchases.getCustomerInfo()` round-trip
//       * Successful grants emit ConsumableGrantEvent on the broadcast
//         `grants` stream — both processCustomerInfo and the synchronous
//         purchase path publish there
//       * Pre-baseline marks and failed RPCs do NOT emit (UI must not
//         flicker to a phantom balance)

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/consumable_grants_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

CustomerInfo _customerInfoWithTransactions(
  List<({String txnId, String productId, String purchaseDate})> transactions,
) {
  final txnsList = [
    for (final t in transactions)
      <String, dynamic>{
        'transactionIdentifier': t.txnId,
        'revenueCatIdentifier': t.txnId,
        'productIdentifier': t.productId,
        'purchaseDate': t.purchaseDate,
      },
  ];
  // CustomerInfo.fromJson — wrap in the JSON shape RC's SDK expects.
  return CustomerInfo.fromJson(<String, dynamic>{
    'originalAppUserId': 'test-user',
    'entitlements': <String, dynamic>{
      'all': <String, dynamic>{},
      'active': <String, dynamic>{},
      'verification': 'NOT_REQUESTED',
    },
    'activeSubscriptions': <String>[],
    'latestExpirationDate': null,
    'allExpirationDates': <String, dynamic>{},
    'allPurchasedProductIdentifiers':
        transactions.map((t) => t.productId).toList(),
    'firstSeen': '2026-04-01T12:00:00.000Z',
    'requestDate': '2026-04-26T12:00:00.000Z',
    'allPurchaseDates': <String, dynamic>{},
    'originalApplicationVersion': '1.0.0',
    'nonSubscriptionTransactions': txnsList,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late ConsumableGrantsService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    // earnTokens / earnTierUpScrolls hit RPCs that we stub to harmless values.
    fakeSync.rpcHandlers['earn_tokens'] = (args) async {
      final amount = (args?['amount'] as int?) ?? 0;
      return amount; // pretend balance starts at 0
    };
    fakeSync.rpcHandlers['earn_scrolls'] = (args) async {
      final amount = (args?['amount'] as int?) ?? 0;
      return amount;
    };
    service = ConsumableGrantsService();
  });

  tearDown(SupabaseSyncService.debugReset);

  group('markCredited', () {
    test('returns true on first call, false on duplicate', () async {
      expect(await service.markCredited('txn-A'), isTrue);
      expect(await service.markCredited('txn-A'), isFalse);
    });

    test('different transactionIds are tracked independently', () async {
      expect(await service.markCredited('txn-A'), isTrue);
      expect(await service.markCredited('txn-B'), isTrue);
      expect(await service.markCredited('txn-A'), isFalse);
      expect(await service.markCredited('txn-B'), isFalse);
    });

    test('is scoped per user via supabaseSyncService.scopedKey', () async {
      await service.markCredited('txn-A');
      // Switch users — the credited set should NOT carry over.
      SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-2'),
      );
      expect(
        await service.markCredited('txn-A'),
        isTrue,
        reason: 'a different user must NOT see user-1\'s credited entries',
      );
    });

    test('caps at 200 entries (oldest dropped from front)', () async {
      // Pre-seed 200 entries directly via the underlying SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final scopedKey =
          fakeSync.scopedKey('credited_consumable_txn_ids_v1');
      final stale = List<String>.generate(200, (i) => 'old-txn-$i');
      await prefs.setString(scopedKey, jsonEncode(stale));

      // Add one more — should drop 'old-txn-0' and keep the rest.
      expect(await service.markCredited('fresh-txn'), isTrue);

      final ids = await service.debugGetCreditedIds();
      expect(ids.length, 200, reason: 'cap must hold');
      expect(ids.contains('old-txn-0'), isFalse,
          reason: 'oldest entry must have been removed');
      expect(ids.contains('old-txn-1'), isTrue,
          reason: 'second-oldest must still be present');
      expect(ids.last, 'fresh-txn',
          reason: 'newly-marked id must be at the end');
    });
  });

  group('processCustomerInfo', () {
    // The grant path is gated on `initializeForUser` having flipped the
    // baselined flag — this prevents the "listener fires on setUserId
    // before baseline runs" race from re-granting lifetime history. Each
    // test in this group baselines with empty history first to enter the
    // post-baseline state, mirroring how production calls
    // `initializeForUser` once on first signin.
    setUp(() async {
      await service.initializeForUser(_customerInfoWithTransactions([]));
    });

    test('grants tokens for a known token SKU and marks as credited',
        () async {
      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-tokens-100',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]);

      final granted = await service.processCustomerInfo(customerInfo);

      expect(granted, 1);
      expect(
        fakeSync.rpcCalls.any((c) =>
            c['fn'] == 'earn_tokens' &&
            (c['params'] as Map?)?['amount'] == 100),
        isTrue,
      );
      expect(await service.debugGetCreditedIds(),
          contains('txn-tokens-100'));
    });

    test('grants scrolls for a known scroll SKU', () async {
      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-scrolls-25',
          productId: 'sakina_scrolls_25',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]);

      final granted = await service.processCustomerInfo(customerInfo);

      expect(granted, 1);
      expect(
        fakeSync.rpcCalls.any((c) =>
            c['fn'] == 'earn_scrolls' &&
            (c['params'] as Map?)?['amount'] == 25),
        isTrue,
      );
    });

    test('skips transactions that are already credited (idempotent across '
        'repeated listener fires)', () async {
      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-tokens-100',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]);

      final firstGranted = await service.processCustomerInfo(customerInfo);
      expect(firstGranted, 1);

      // Second call with the same customerInfo — RC fires the listener
      // again on next refresh, but our credited set blocks the grant.
      final secondGranted = await service.processCustomerInfo(customerInfo);
      expect(secondGranted, 0,
          reason: 'already-credited txn must not be granted twice');

      final tokenCalls =
          fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_tokens').length;
      expect(tokenCalls, 1,
          reason: 'earn_tokens RPC must fire exactly once per real txn');
    });

    test('grants for multiple new transactions in the same customerInfo '
        'update', () async {
      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-A',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
        (
          txnId: 'txn-B',
          productId: 'sakina_scrolls_3',
          purchaseDate: '2026-04-26T12:01:00.000Z',
        ),
      ]);

      final granted = await service.processCustomerInfo(customerInfo);
      expect(granted, 2);
    });

    test('skips unknown SKUs without crashing or marking credited',
        () async {
      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-mystery',
          productId: 'sakina_unknown_sku',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]);

      final granted = await service.processCustomerInfo(customerInfo);

      expect(granted, 0);
      expect(await service.debugGetCreditedIds(),
          isNot(contains('txn-mystery')),
          reason: 'unknown SKUs must NOT be marked credited — if a future '
              'release adds the SKU mapping, the txn should still be '
              'recoverable');
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('grants only the new transaction when one is pre-credited and one '
        'is fresh (mixed sync-then-listener scenario)', () async {
      // Synchronous purchase path already credited txn-A. Listener fires
      // later with both A (already credited) and B (orphan from prior run).
      await service.markCredited('txn-A');

      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-A',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-25T12:00:00.000Z',
        ),
        (
          txnId: 'txn-B',
          productId: 'sakina_tokens_500',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]);

      final granted = await service.processCustomerInfo(customerInfo);

      expect(granted, 1, reason: 'only the orphan should grant');
      expect(
        fakeSync.rpcCalls.any((c) =>
            c['fn'] == 'earn_tokens' &&
            (c['params'] as Map?)?['amount'] == 500),
        isTrue,
        reason: 'the orphaned 500-token purchase must land',
      );
      expect(
        fakeSync.rpcCalls.any((c) =>
            c['fn'] == 'earn_tokens' &&
            (c['params'] as Map?)?['amount'] == 100),
        isFalse,
        reason: 'the already-credited 100-token purchase must NOT re-grant',
      );
    });
  });

  group('initializeForUser', () {
    test('on first signin: marks all existing transactions as credited '
        'WITHOUT granting (high-water mark)', () async {
      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-history-1',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-03-01T12:00:00.000Z',
        ),
        (
          txnId: 'txn-history-2',
          productId: 'sakina_tokens_500',
          purchaseDate: '2026-04-01T12:00:00.000Z',
        ),
      ]);

      await service.initializeForUser(customerInfo);

      expect(await service.debugIsBaselined(), isTrue);
      expect(
        await service.debugGetCreditedIds(),
        containsAll(['txn-history-1', 'txn-history-2']),
        reason: 'historical txns must be in the credited set',
      );
      expect(fakeSync.rpcCalls, isEmpty,
          reason: 'baseline must NOT call earn_tokens');
    });

    test('on second call: is a no-op (idempotent per user/device)',
        () async {
      // First baseline.
      await service.initializeForUser(_customerInfoWithTransactions([
        (
          txnId: 'txn-1',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-01T12:00:00.000Z',
        ),
      ]));

      // RC's customerInfo refreshes with a new transaction the user just
      // made. Calling initializeForUser AGAIN must NOT mark this one — the
      // listener path must process it and grant.
      await service.initializeForUser(_customerInfoWithTransactions([
        (
          txnId: 'txn-1',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-01T12:00:00.000Z',
        ),
        (
          txnId: 'txn-2-fresh',
          productId: 'sakina_tokens_500',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]));

      expect(
        await service.debugGetCreditedIds(),
        isNot(contains('txn-2-fresh')),
        reason: 'second baseline must be no-op so fresh txn flows through '
            'processCustomerInfo and gets granted',
      );
    });

    test('after baseline: subsequent processCustomerInfo grants only the '
        'NEW transaction (orphan recovery)', () async {
      // Baseline with one historical txn.
      await service.initializeForUser(_customerInfoWithTransactions([
        (
          txnId: 'txn-baseline',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-03-01T12:00:00.000Z',
        ),
      ]));

      // Listener fires with baseline + new orphan. New one grants; the
      // baseline does not.
      final granted =
          await service.processCustomerInfo(_customerInfoWithTransactions([
        (
          txnId: 'txn-baseline',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-03-01T12:00:00.000Z',
        ),
        (
          txnId: 'txn-orphan',
          productId: 'sakina_tokens_250',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]));

      expect(granted, 1);
      expect(
        fakeSync.rpcCalls.any((c) =>
            c['fn'] == 'earn_tokens' &&
            (c['params'] as Map?)?['amount'] == 250),
        isTrue,
      );
    });
  });

  // ── /review post-fix coverage ──────────────────────────────────────────

  group('concurrency: markCredited lock', () {
    test('concurrent markCredited calls do not lose entries (race fix)',
        () async {
      // Without the module-level _markCreditedLock, two concurrent calls
      // would interleave their read-modify-write on SharedPreferences and
      // one entry would overwrite the other. Fire 50 concurrent calls and
      // assert all 50 ids land in the credited set.
      final futures = <Future<bool>>[];
      for (var i = 0; i < 50; i++) {
        futures.add(service.markCredited('concurrent-txn-$i'));
      }
      final results = await Future.wait(futures);

      expect(results.every((r) => r == true), isTrue,
          reason: 'every distinct id should report as newly added');

      final stored = await service.debugGetCreditedIds();
      expect(stored.length, 50,
          reason: 'all 50 ids must persist — race would lose some');
      for (var i = 0; i < 50; i++) {
        expect(stored, contains('concurrent-txn-$i'),
            reason: 'id concurrent-txn-$i must be in the persisted set');
      }
    });
  });

  group('baseline race: pre-baseline listener fires only mark, do not grant',
      () {
    test('processCustomerInfo before baseline marks transactions but does '
        'NOT grant (fixes setUserId → listener race that would re-credit '
        "user's lifetime history on first signin)", () async {
      // Simulate the race: the customerInfoUpdateListener fires on
      // setUserId BEFORE app_session.dart calls initializeForUser.
      // baselined = false at this point.
      expect(await service.debugIsBaselined(), isFalse);

      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-historical-1',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-01-01T12:00:00.000Z',
        ),
        (
          txnId: 'txn-historical-2',
          productId: 'sakina_tokens_500',
          purchaseDate: '2026-02-01T12:00:00.000Z',
        ),
      ]);

      final granted = await service.processCustomerInfo(customerInfo);

      expect(granted, 0,
          reason: 'pre-baseline must NOT call earnTokens — these are '
              "the user's lifetime transactions, not new purchases");
      expect(fakeSync.rpcCalls, isEmpty,
          reason: 'no earn_tokens RPC must fire pre-baseline');

      // Both transactions are now in the credited set, so a subsequent
      // initializeForUser is a no-op and a real new purchase will grant.
      expect(
        await service.debugGetCreditedIds(),
        containsAll(['txn-historical-1', 'txn-historical-2']),
        reason: 'transactions must be marked so they are not re-granted '
            'after baseline flips',
      );
    });

    test('after pre-baseline mark, a subsequent NEW txn (post-baseline) '
        'grants normally', () async {
      // Step 1: pre-baseline listener fire marks history.
      await service.processCustomerInfo(_customerInfoWithTransactions([
        (
          txnId: 'txn-historical',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-01-01T12:00:00.000Z',
        ),
      ]));
      expect(fakeSync.rpcCalls, isEmpty);

      // Step 2: app_session calls initializeForUser. The same customerInfo
      // is used (real RC.getCustomerInfo would return the same state).
      // initializeForUser flips the baseline flag and marks (no-op since
      // already in set).
      await service.initializeForUser(_customerInfoWithTransactions([
        (
          txnId: 'txn-historical',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-01-01T12:00:00.000Z',
        ),
      ]));
      expect(await service.debugIsBaselined(), isTrue);

      // Step 3: user makes a new purchase. RC fires listener with the new
      // txn. baselined=true, so processCustomerInfo grants.
      final granted =
          await service.processCustomerInfo(_customerInfoWithTransactions([
        (
          txnId: 'txn-historical',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-01-01T12:00:00.000Z',
        ),
        (
          txnId: 'txn-new-purchase',
          productId: 'sakina_tokens_250',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]));

      expect(granted, 1);
      expect(
        fakeSync.rpcCalls.any((c) =>
            c['fn'] == 'earn_tokens' &&
            (c['params'] as Map?)?['amount'] == 250),
        isTrue,
        reason: 'the new purchase must grant via the listener path',
      );
    });
  });

  group('grant-failure rollback: failed grant un-marks the txn so the next '
      'listener fire retries', () {
    test('processCustomerInfo: when earn_tokens RPC fails, the txn is '
        'removed from the credited set so the next fire can retry',
        () async {
      // Baseline first so we are post-baseline.
      await service.initializeForUser(_customerInfoWithTransactions([]));

      // Make the earn_tokens RPC throw on the first call only.
      var earnCalls = 0;
      fakeSync.rpcHandlers['earn_tokens'] = (args) async {
        earnCalls += 1;
        if (earnCalls == 1) {
          throw StateError('simulated transient earn_tokens failure');
        }
        return (args?['amount'] as int?) ?? 0;
      };

      final customerInfo = _customerInfoWithTransactions([
        (
          txnId: 'txn-flaky',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-26T12:00:00.000Z',
        ),
      ]);

      // First call: grant fails, mark is rolled back.
      final firstGranted = await service.processCustomerInfo(customerInfo);
      expect(firstGranted, 0);
      expect(
        await service.debugGetCreditedIds(),
        isNot(contains('txn-flaky')),
        reason: 'failed grant must roll back the credited mark — '
            'otherwise the user is paid-but-not-credited with no recovery',
      );

      // Second call: grant succeeds. earn_tokens fires once more (the
      // rollback let the retry happen).
      final secondGranted = await service.processCustomerInfo(customerInfo);
      expect(secondGranted, 1);
      expect(earnCalls, 2,
          reason: 'second call must re-attempt earn_tokens');
      expect(
        await service.debugGetCreditedIds(),
        contains('txn-flaky'),
        reason: 'successful retry leaves the txn credited',
      );
    });
  });

  // 2026-04-28: the synchronous purchase path used to call this method
  // without `customerInfo`, which forced a `Purchases.getCustomerInfo()`
  // round-trip. RC's customerInfo cache is updated AFTER the
  // `purchasePackage` future resolves on the JS side, so that fetch
  // commonly returned a stale customerInfo missing the just-completed
  // transaction → "no transaction found" → no local grant → balance pill
  // stale until the listener fired several seconds later (and the
  // listener didn't notify the UI either). Both bugs are fixed by
  // passing the fresh customerInfo through and by emitting on the
  // [grants] stream.
  group('grantForMostRecentPurchase with explicit customerInfo: skips the '
      'redundant getCustomerInfo round-trip and grants from the passed-in '
      'CustomerInfo (2026-04-28 stale-balance fix)', () {
    test('with explicit customerInfo: grants tokens AND emits on the '
        'grants stream with the new server-confirmed balance', () async {
      // Post-baseline.
      await service.initializeForUser(_customerInfoWithTransactions([]));
      // Server returns 100 from earn_tokens (mocked above) — that's what
      // the grants event must surface as `newBalance`.

      final fresh = _customerInfoWithTransactions([
        (
          txnId: 'txn-fresh',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-28T19:42:00.000Z',
        ),
      ]);

      final eventsFuture = ConsumableGrantsService.grants
          .where((e) => e.transactionId == 'txn-fresh')
          .first;

      final granted = await service.grantForMostRecentPurchase(
        'sakina_tokens_100',
        customerInfo: fresh,
      );

      expect(granted, isTrue);
      final event = await eventsFuture.timeout(const Duration(seconds: 1));
      expect(event.kind, ConsumableGrantKind.tokens);
      expect(event.amount, 100);
      expect(event.newBalance, 100,
          reason: 'newBalance is the post-RPC server-confirmed balance');
    });

    test('with explicit customerInfo: scrolls SKU emits scrolls event',
        () async {
      await service.initializeForUser(_customerInfoWithTransactions([]));

      final fresh = _customerInfoWithTransactions([
        (
          txnId: 'txn-scrolls',
          productId: 'sakina_scrolls_3',
          purchaseDate: '2026-04-28T19:42:00.000Z',
        ),
      ]);

      final eventsFuture = ConsumableGrantsService.grants
          .where((e) => e.transactionId == 'txn-scrolls')
          .first;

      final granted = await service.grantForMostRecentPurchase(
        'sakina_scrolls_3',
        customerInfo: fresh,
      );

      expect(granted, isTrue);
      final event = await eventsFuture.timeout(const Duration(seconds: 1));
      expect(event.kind, ConsumableGrantKind.scrolls);
      expect(event.amount, 3);
      expect(event.newBalance, 3);
    });

    test('with explicit customerInfo: second call for the same txn is a '
        'no-op (dedup primitive) and emits NO event', () async {
      await service.initializeForUser(_customerInfoWithTransactions([]));

      final fresh = _customerInfoWithTransactions([
        (
          txnId: 'txn-dup',
          productId: 'sakina_tokens_100',
          purchaseDate: '2026-04-28T19:42:00.000Z',
        ),
      ]);

      // First grant — emits.
      final firstEventF = ConsumableGrantsService.grants
          .where((e) => e.transactionId == 'txn-dup')
          .first;
      expect(
        await service.grantForMostRecentPurchase(
          'sakina_tokens_100',
          customerInfo: fresh,
        ),
        isTrue,
      );
      await firstEventF.timeout(const Duration(seconds: 1));

      // Second grant for the same txn — must be a no-op AND emit nothing.
      var sawSecondEvent = false;
      final sub = ConsumableGrantsService.grants
          .where((e) => e.transactionId == 'txn-dup')
          .listen((_) => sawSecondEvent = true);
      try {
        expect(
          await service.grantForMostRecentPurchase(
            'sakina_tokens_100',
            customerInfo: fresh,
          ),
          isFalse,
          reason: 'duplicate grant returns false',
        );
        // Drain any in-flight microtasks.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(sawSecondEvent, isFalse,
            reason: 'no event for an already-credited txn — '
                'subscribers must not double-update the balance');
      } finally {
        await sub.cancel();
      }
    });
  });

  group('processCustomerInfo emits on the grants stream — orphan-recovery '
      'path also notifies the UI (Fix B for 2026-04-28 stale-balance bug)',
      () {
    test('emits a tokens event with the post-RPC balance after a successful '
        'orphan-recovery grant', () async {
      await service.initializeForUser(_customerInfoWithTransactions([]));

      final eventF = ConsumableGrantsService.grants
          .where((e) => e.transactionId == 'txn-orphan-tokens')
          .first;

      final granted =
          await service.processCustomerInfo(_customerInfoWithTransactions([
        (
          txnId: 'txn-orphan-tokens',
          productId: 'sakina_tokens_250',
          purchaseDate: '2026-04-28T19:00:00.000Z',
        ),
      ]));

      expect(granted, 1);
      final event = await eventF.timeout(const Duration(seconds: 1));
      expect(event.kind, ConsumableGrantKind.tokens);
      expect(event.amount, 250);
      expect(event.newBalance, 250);
    });

    test('does NOT emit when grants are skipped pre-baseline — UI must not '
        'flicker from a baseline-only mark', () async {
      // Skip initializeForUser → not baselined.
      var sawAnyEvent = false;
      final sub = ConsumableGrantsService.grants.listen((_) {
        sawAnyEvent = true;
      });
      try {
        final granted =
            await service.processCustomerInfo(_customerInfoWithTransactions([
          (
            txnId: 'txn-baseline',
            productId: 'sakina_tokens_100',
            purchaseDate: '2026-04-28T19:00:00.000Z',
          ),
        ]));
        expect(granted, 0,
            reason: 'pre-baseline path marks but does not grant');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(sawAnyEvent, isFalse,
            reason: 'no grant happened, so no event');
      } finally {
        await sub.cancel();
      }
    });

    test('does NOT emit when the grant RPC fails — failed grants must '
        'leave subscribers untouched (rollback restores credited-set, '
        'next fire retries)', () async {
      await service.initializeForUser(_customerInfoWithTransactions([]));
      fakeSync.rpcHandlers['earn_tokens'] = (args) async {
        throw StateError('simulated earn_tokens failure');
      };

      var sawAnyEvent = false;
      final sub = ConsumableGrantsService.grants.listen((_) {
        sawAnyEvent = true;
      });
      try {
        final granted =
            await service.processCustomerInfo(_customerInfoWithTransactions([
          (
            txnId: 'txn-fails',
            productId: 'sakina_tokens_100',
            purchaseDate: '2026-04-28T19:00:00.000Z',
          ),
        ]));
        expect(granted, 0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(sawAnyEvent, isFalse,
            reason: 'a failed RPC must not bump the UI to a phantom balance');
      } finally {
        await sub.cancel();
      }
    });
  });
}
