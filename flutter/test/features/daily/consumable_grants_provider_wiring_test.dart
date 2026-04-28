// Pins the wiring between ConsumableGrantsService.grants and the two
// notifiers that subscribe to it — DailyLoopNotifier (tokens) and
// TierUpScrollNotifier (scrolls). This is Fix B for the 2026-04-28
// stale-balance bug: the synchronous purchase path AND the orphan-
// recovery customerInfo listener both publish on this stream, and these
// notifiers refresh their state from it without callers having to know
// which path produced the grant.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/consumable_grants_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Builds a fresh container with `publicCatalogRegistryProvider` overridden
/// per-test. Without the override, Riverpod returns the top-level singleton
/// (public_catalog_service.dart:39); when the first container in a test
/// run disposes, the singleton is disposed too, and any later container
/// crashes with "PublicCatalogRegistry was used after being disposed."
/// Same workaround the Store widget tests use.
ProviderContainer _makeContainer() {
  return ProviderContainer(
    overrides: [
      publicCatalogRegistryProvider
          .overrideWith((ref) => PublicCatalogRegistry()),
    ],
  );
}

CustomerInfo _customerInfoWith({
  required String txnId,
  required String productId,
}) {
  return CustomerInfo.fromJson(<String, dynamic>{
    'originalAppUserId': 'user-1',
    'entitlements': <String, dynamic>{
      'all': <String, dynamic>{},
      'active': <String, dynamic>{},
      'verification': 'NOT_REQUESTED',
    },
    'activeSubscriptions': <String>[],
    'latestExpirationDate': null,
    'allExpirationDates': <String, dynamic>{},
    'allPurchasedProductIdentifiers': <String>[productId],
    'firstSeen': '2026-04-01T12:00:00.000Z',
    'requestDate': '2026-04-28T19:42:00.000Z',
    'allPurchaseDates': <String, dynamic>{},
    'originalApplicationVersion': '1.0.0',
    'nonSubscriptionTransactions': <Map<String, dynamic>>[
      {
        'transactionIdentifier': txnId,
        'revenueCatIdentifier': txnId,
        'productIdentifier': productId,
        'purchaseDate': '2026-04-28T19:42:00.000Z',
      },
    ],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late ConsumableGrantsService grantsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['earn_tokens'] = (args) async {
      // Return the requested amount as the new balance — the wiring test
      // doesn't care about absolute math, just that the new balance flows
      // through the stream into the notifier state.
      return (args?['amount'] as int?) ?? 0;
    };
    fakeSync.rpcHandlers['earn_scrolls'] = (args) async {
      return (args?['amount'] as int?) ?? 0;
    };
    grantsService = ConsumableGrantsService();
    // Baseline so subsequent grants run instead of being mark-only.
    await grantsService.initializeForUser(CustomerInfo.fromJson(<String, dynamic>{
      'originalAppUserId': 'user-1',
      'entitlements': <String, dynamic>{
        'all': <String, dynamic>{},
        'active': <String, dynamic>{},
        'verification': 'NOT_REQUESTED',
      },
      'activeSubscriptions': <String>[],
      'latestExpirationDate': null,
      'allExpirationDates': <String, dynamic>{},
      'allPurchasedProductIdentifiers': <String>[],
      'firstSeen': '2026-04-01T12:00:00.000Z',
      'requestDate': '2026-04-28T19:42:00.000Z',
      'allPurchaseDates': <String, dynamic>{},
      'originalApplicationVersion': '1.0.0',
      'nonSubscriptionTransactions': <Map<String, dynamic>>[],
    }));
  });

  tearDown(SupabaseSyncService.debugReset);

  test('DailyLoopNotifier picks up tokens grants from the broadcast stream — '
      'no manual refreshTokenBalance call needed', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    // Read the provider so the notifier is constructed and subscribes to
    // the grants stream. (Reading is what triggers Riverpod to build it.)
    container.read(dailyLoopProvider.notifier);
    // Let _initialize complete enough for state to settle. token_service
    // defaults a fresh cache to startingTokens=50, so the post-init balance
    // is 50 (NOT 0); this test asserts the delta from baseline, so any
    // future change to startingTokens stays robust.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final beforeBalance = container.read(dailyLoopProvider).tokenBalance;

    final granted = await grantsService.grantForMostRecentPurchase(
      'sakina_tokens_500',
      customerInfo: _customerInfoWith(
        txnId: 'wiring-tokens',
        productId: 'sakina_tokens_500',
      ),
    );
    expect(granted, isTrue);

    // The grants event is delivered on a microtask after _grantsController.add.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final afterBalance = container.read(dailyLoopProvider).tokenBalance;
    expect(afterBalance, 500,
        reason: 'tokens event must flow into DailyLoopState.tokenBalance — '
            'fake earn_tokens RPC returns the requested amount as the new '
            'balance, so a 500-token grant lands as balance=500');
    expect(afterBalance, isNot(beforeBalance),
        reason: 'pre/post balance must differ — otherwise the assertion '
            'above could pass even if the stream wiring is dead');
  });

  test('DailyLoopNotifier ignores scrolls grants — those belong to '
      'TierUpScrollNotifier, must not corrupt the token balance', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    container.read(dailyLoopProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final before = container.read(dailyLoopProvider).tokenBalance;

    await grantsService.grantForMostRecentPurchase(
      'sakina_scrolls_10',
      customerInfo: _customerInfoWith(
        txnId: 'wiring-scrolls-no-token-bleed',
        productId: 'sakina_scrolls_10',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(dailyLoopProvider).tokenBalance, before,
        reason: 'a scrolls event must not move the token balance');
  });

  test('TierUpScrollNotifier picks up scrolls grants from the broadcast '
      'stream — no manual reload() call needed', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    container.read(tierUpScrollProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(tierUpScrollProvider).balance, 0,
        reason: 'fresh prefs default scroll balance is 0');

    final granted = await grantsService.grantForMostRecentPurchase(
      'sakina_scrolls_25',
      customerInfo: _customerInfoWith(
        txnId: 'wiring-scrolls',
        productId: 'sakina_scrolls_25',
      ),
    );
    expect(granted, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(tierUpScrollProvider).balance, 25,
        reason: 'scrolls event must flow into TierUpScrollState.balance');
  });

  test('TierUpScrollNotifier ignores tokens grants — symmetric to the '
      'DailyLoopNotifier guard', () async {
    final container = _makeContainer();
    addTearDown(container.dispose);

    container.read(tierUpScrollProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final before = container.read(tierUpScrollProvider).balance;

    await grantsService.grantForMostRecentPurchase(
      'sakina_tokens_100',
      customerInfo: _customerInfoWith(
        txnId: 'wiring-tokens-no-scroll-bleed',
        productId: 'sakina_tokens_100',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(tierUpScrollProvider).balance, before,
        reason: 'a tokens event must not move the scroll balance');
  });
}
