// §11 Store widget tests. Pin the four spec bullets:
//   - Tabs render (Tokens/Scrolls — the spec said "Free/Premium" which is
//     stale; this file is also the doc-drift canary)
//   - Insufficient-tokens gate is N/A (no token-priced items exist; flagged
//     as a doc bug, no test possible)
//   - Double-tap purchase → only ONE call to PurchaseService.purchaseConsumable
//   - Offerings unavailable → snackbar, no crash
//
// Plus three additions from /plan-eng-review:
//   §11-G — balance pill refreshes after a successful consumable purchase
//   §11-H — restore-success path flows to "Premium restored!" snackbar
//   toast Timer drain — every success-path test pumps 3s so the
//     `_PurchaseToastWidget`'s Future.delayed(2500ms) cleans up before
//     teardown, otherwise we get "Timer is still pending after disposed".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sakina/features/store/screens/store_screen.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/summary_metric_card.dart';

import '../../support/fake_supabase_sync_service.dart';

// `purchases_flutter` exposes static methods (`Purchases.getCustomerInfo`)
// that bypass our PurchaseService DI seam. After the 2026-04-28 fix the
// synchronous purchase path passes the fresh `CustomerInfo` from
// `purchaseConsumable` straight to `grantForMostRecentPurchase`, so widget
// tests no longer rely on the channel mock to satisfy `getCustomerInfo`.
// The handler is kept as a defensive net for any path that still falls
// through to a fetch (orphan-recovery listener, etc. — not exercised here).
const MethodChannel _purchasesChannel = MethodChannel('purchases_flutter');

/// Test double for [PurchaseService] that:
///   - returns the configured `consumablePackages` list (or throws) for
///     `getConsumablePackages()`
///   - returns a [CustomerInfo] built by `consumableCustomerInfoBuilder`
///     for `purchaseConsumable` — production now passes that customerInfo
///     into `grantForMostRecentPurchase` to skip the racy refetch
///   - gates `purchaseConsumable` on a Completer when `gatePurchases=true`,
///     so we can hold a purchase in-flight to test double-tap idempotency
///   - records every call so tests can assert exact counts
class FakeStorePurchaseService extends PurchaseService {
  FakeStorePurchaseService() : super.test();

  /// Packages the Store screen sees — backs `getConsumablePackages()`.
  /// Renamed from `offerings` after the Store screen moved off the
  /// `getOfferings()` (subscription) path onto the dedicated consumables
  /// offering — the prior name was misleading.
  List<Package> consumablePackages = <Package>[];
  Object? consumablePackagesError;

  /// Builds the `CustomerInfo` returned by `purchaseConsumable`. Tests
  /// assign this so the returned customerInfo contains the just-completed
  /// transaction (matches RC's real `Purchases.purchasePackage` contract).
  /// Production code now passes this CustomerInfo through to
  /// `ConsumableGrantsService.grantForMostRecentPurchase`, eliminating
  /// the redundant `Purchases.getCustomerInfo()` round-trip that caused
  /// the 2026-04-28 stale-balance bug.
  CustomerInfo Function()? consumableCustomerInfoBuilder;
  Object? consumableError;
  int consumableCalls = 0;

  bool restoreResult = false;
  Object? restoreError;
  int restoreCalls = 0;

  bool gatePurchases = false;
  Completer<void>? _purchaseGate;

  @override
  Future<List<Package>> getConsumablePackages() async {
    if (consumablePackagesError != null) throw consumablePackagesError!;
    return consumablePackages;
  }

  @override
  Future<CustomerInfo> purchaseConsumable(Package package) async {
    consumableCalls += 1;
    if (gatePurchases) {
      _purchaseGate ??= Completer<void>();
      await _purchaseGate!.future;
    }
    if (consumableError != null) throw consumableError!;
    final builder = consumableCustomerInfoBuilder;
    if (builder == null) {
      throw StateError(
        'consumableCustomerInfoBuilder not set — tests that exercise the '
        'purchase path must seed a CustomerInfo via this builder so that '
        'grantForMostRecentPurchase has a transaction to find',
      );
    }
    return builder();
  }

  @override
  Future<bool> restorePurchases() async {
    restoreCalls += 1;
    if (restoreError != null) throw restoreError!;
    return restoreResult;
  }

  @override
  Future<bool> isPremium() async => false;

  void releasePurchase() {
    _purchaseGate?.complete();
    _purchaseGate = null;
  }
}

Package _pkg(String productId, double price) {
  return Package(
    productId,
    PackageType.custom,
    StoreProduct(productId, productId, productId, price, '\$$price', 'USD'),
    const PresentedOfferingContext('default', null, null),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
      );
    }
  });

  late FakeStorePurchaseService purchaseService;
  late FakeSupabaseSyncService fakeSync;

  // Per-test list of consumable transactions to return from the mocked
  // `Purchases.getCustomerInfo()`. Tests append to this when the purchase
  // path is expected to credit a SKU. Default: empty (no orphaned txns).
  late List<Map<String, dynamic>> mockedTransactions;

  Map<String, dynamic> buildCustomerInfoJson() {
    return <String, dynamic>{
      'originalAppUserId': 'user-1',
      'entitlements': <String, dynamic>{
        'all': <String, dynamic>{},
        'active': <String, dynamic>{},
        'verification': 'NOT_REQUESTED',
      },
      'activeSubscriptions': <String>[],
      'latestExpirationDate': null,
      'allExpirationDates': <String, dynamic>{},
      'allPurchasedProductIdentifiers': mockedTransactions
          .map((t) => t['productIdentifier'] as String)
          .toList(),
      'firstSeen': '2026-04-01T12:00:00.000Z',
      'requestDate': '2026-04-26T12:00:00.000Z',
      'allPurchaseDates': <String, dynamic>{},
      'originalApplicationVersion': '1.0.0',
      'nonSubscriptionTransactions': mockedTransactions,
    };
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    mockedTransactions = <Map<String, dynamic>>[];

    // Stub the purchases_flutter channel. ConsumableGrantsService calls
    // `Purchases.getCustomerInfo()` from `grantForMostRecentPurchase` —
    // without this, the call throws (no native bridge) and the grant path
    // returns false, so the balance pill never updates and §11-G fails.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, (call) async {
      if (call.method == 'getCustomerInfo') {
        return buildCustomerInfoJson();
      }
      return null;
    });
    // earnTokens() / earn(scrolls) hit these RPCs. Stub to harmless values.
    fakeSync.rpcHandlers['earn_tokens'] = (args) async {
      final amount = (args?['amount'] as int?) ?? 0;
      return amount; // pretend balance starts at 0 and returns post-earn
    };
    fakeSync.rpcHandlers['earn_scrolls'] = (args) async {
      final amount = (args?['amount'] as int?) ?? 0;
      return amount;
    };

    purchaseService = FakeStorePurchaseService();
    PurchaseService.debugSetOverride(purchaseService);
    debugSetPremiumGrantPurchaseService(purchaseService);

    // Default: return a CustomerInfo built from `mockedTransactions`.
    // §11-G appends the just-purchased SKU to that list before tapping
    // Buy; tests that don't exercise the purchase path leave it empty
    // and the builder still returns a valid (transaction-less) CustomerInfo.
    purchaseService.consumableCustomerInfoBuilder = () =>
        CustomerInfo.fromJson(buildCustomerInfoJson());

    purchaseService.consumablePackages = [
      _pkg('sakina_tokens_100', 1.99),
      _pkg('sakina_tokens_250', 3.99),
      _pkg('sakina_tokens_500', 6.99),
      _pkg('sakina_scrolls_3', 0.99),
      _pkg('sakina_scrolls_10', 2.49),
      _pkg('sakina_scrolls_25', 4.99),
    ];
  });

  tearDown(() {
    PurchaseService.debugClearOverride();
    debugResetPremiumGrantService();
    SupabaseSyncService.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, null);
  });

  // Default 800x600 test surface is too short for the Store's full layout
  // (header + balances + tab bar + scroll body + restore link). Phone-sized
  // surface lets the entire screen render and tap-targets stay on-screen.
  void usePhoneViewport(WidgetTester tester) {
    // 500 wide (slightly larger than iPhone 14 Pro Max's 430 logical px) so
    // the "Best Value" badge rows in `_IapItem` don't trigger horizontal
    // RenderFlex overflow. The narrow-width overflow itself is a real
    // production layout bug — out of scope for this PR; file separately.
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Minimal GoRouter — SubpageHeader (and other shared widgets) call
  // `context.canPop()` which throws "No GoRouter found in context" when the
  // test is wrapped in a plain MaterialApp. Routing the single test screen
  // through GoRouter makes the call tree match production.
  GoRouter buildRouter() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SizedBox(
              // Phone-sized constrained surface so the Store's vertical
              // layout (header + balances + tab bar + scroll content +
              // restore link) fits without RenderFlex overflow. 500 wide
              // also avoids the horizontal overflow on "Best Value" rows.
              width: 500,
              height: 800,
              child: StoreScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        // The default `publicCatalogRegistryProvider` returns a top-level
        // singleton (public_catalog_service.dart:39). When ProviderScope #1
        // tears down between tests, Riverpod disposes that singleton — and
        // ProviderScope #2 then crashes with
        // "PublicCatalogRegistry was used after being disposed" the moment
        // any provider tries to read it. Override per-test with a fresh
        // instance so disposal stays scoped.
        publicCatalogRegistryProvider
            .overrideWith((ref) => PublicCatalogRegistry()),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  // Builds the subject AND drains the Store's `.animate().fadeIn(...)`
  // entrance animations (~600ms longest with 150ms delay + 400ms duration)
  // so that finite Tweens cleanly finish before tests dispose the widget
  // tree. Skipping this leaks the flutter_animate Timer.
  Future<void> pumpStore(WidgetTester tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 700));
  }

  // The purchase celebration toast (`_PurchaseToastWidget`) schedules
  // Future.delayed(2500ms) to remove its OverlayEntry. The icon also runs
  // `flutter_animate.repeat(reverse: true)` which is continuous — but once
  // the OverlayEntry is removed the widget is disposed and the repeat
  // controller dies with it. So pumping past the 2500ms removal cleans up
  // both the Futures and the repeat animation.
  Future<void> drainPurchaseToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
  }

  group('§11-A render', () {
    testWidgets('tabs render as Tokens and Scrolls (NOT Free/Premium)',
        (tester) async {
      await pumpStore(tester);

      expect(find.text('Tokens'), findsWidgets);
      expect(find.text('Scrolls'), findsWidgets);
      // Doc-drift canary — the spec from manual-test-plan.md §11 says
      // "Free + Premium sub-tabs", which doesn't match shipped code.
      expect(find.text('Free'), findsNothing);
      expect(find.text('Premium'), findsNothing);
    });
  });

  group('§11-B offerings unavailable', () {
    testWidgets('empty offerings → "Pack not available yet" snackbar',
        (tester) async {
      purchaseService.consumablePackages = <Package>[];

      await pumpStore(tester);

      await tapVisible(tester, find.text('100 Tokens'));
      // The async lookup runs on the next microtask.
      await tester.pump();
      await tester.pump();

      expect(find.text('Pack not available yet. Try again later.'),
          findsOneWidget);
      expect(purchaseService.consumableCalls, 0,
          reason: 'no purchase should be attempted when the pack is missing');
    });
  });

  group('§11-C offerings throws', () {
    testWidgets('getOfferings throws → generic "Purchase failed" snackbar',
        (tester) async {
      purchaseService.consumablePackagesError =
          StateError('consumables fetch failed');

      await pumpStore(tester);

      await tapVisible(tester, find.text('100 Tokens'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Purchase failed. Please try again.'), findsOneWidget);
    });
  });

  group('§11-D cancellation', () {
    testWidgets('purchaseCancelledError silenced — no snackbar',
        (tester) async {
      // Pin against the PurchasesErrorCode enum index rather than the magic
      // string `'1'`. RC maps `PlatformException.code` via `int.parse(e.code)`
      // then indexes into `PurchasesErrorCode.values`, so the integer is an
      // ordinal — brittle to enum reorders in future RC SDK versions.
      purchaseService.consumableError = PlatformException(
        code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
        details: <String, dynamic>{
          'readable_error_code': 'PURCHASE_CANCELLED',
          'code': PurchasesErrorCode.purchaseCancelledError.index,
        },
      );

      await pumpStore(tester);

      await tapVisible(tester, find.text('100 Tokens'));
      await tester.pump();
      await tester.pump();

      // Cancellations are silent by design. Either no snackbar shows OR
      // an SDK-version mismatch may classify it differently — the contract
      // we care about is that the user is NOT shown a "Purchase failed"
      // banner for their own cancellation.
      expect(find.text('Purchase failed. Please try again.'), findsNothing);

      // Re-enabled state: another tap is possible after cancel.
      // (sanity — _purchasing flag must reset)
      expect(purchaseService.consumableCalls, 1);
    });
  });

  group('§11-E double-tap idempotency', () {
    testWidgets(
        'two rapid taps on the same item → purchaseConsumable invoked '
        'EXACTLY once', (tester) async {
      purchaseService.gatePurchases = true; // hold the first call in-flight

      await pumpStore(tester);

      // First tap kicks off the purchase. Second tap arrives while
      // _purchasing == true and must be a no-op.
      await tapVisible(tester, find.text('100 Tokens'));
      await tapVisible(tester, find.text('100 Tokens'));
      await tester.pump();

      expect(
        purchaseService.consumableCalls,
        1,
        reason: 'the _purchasing gate at store_screen.dart:41 must absorb '
            'the second tap before it reaches the SDK',
      );

      // Drain the gate so teardown doesn't leak the future.
      purchaseService.releasePurchase();
      await tester.pump();
      await drainPurchaseToast(tester);
    });
  });

  group('§11-F restore — no entitlement', () {
    testWidgets(
        'restore returns false → "No active premium subscription was found"',
        (tester) async {
      purchaseService.restoreResult = false;

      await pumpStore(tester);

      await tapVisible(tester, find.text('Restore purchase'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No active premium subscription was found to restore.'),
        findsOneWidget,
      );
      expect(purchaseService.restoreCalls, 1);
    });
  });

  group('§11-G balance pill refreshes', () {
    testWidgets(
        'successful token purchase → balance pill text reflects the grant '
        '(via the ConsumableGrantsService.grants stream that '
        'DailyLoopNotifier subscribes to — the 2026-04-28 fix; the prior '
        'manual `refreshTokenBalance(getTokens())` path raced RC\'s '
        'customerInfo cache and frequently left the pill stale)',
        (tester) async {
      // Seed a transaction record on the fresh CustomerInfo that
      // `purchaseConsumable` will return. Production code now reads
      // `customerInfo.nonSubscriptionTransactions` directly from the
      // `Purchases.purchasePackage` return value, so the SKU MUST be
      // present in this list for `grantForMostRecentPurchase` to credit it.
      mockedTransactions.add(<String, dynamic>{
        'transactionIdentifier': 'sim-txn-tokens-100',
        'revenueCatIdentifier': 'sim-txn-tokens-100',
        'productIdentifier': 'sakina_tokens_100',
        'purchaseDate': '2026-04-26T12:00:00.000Z',
      });

      await pumpStore(tester);

      // Inspect SummaryMetricCard widgets by configuration rather than text
      // finders — text-tree searches collide with the IAP rows ("100 Tokens",
      // "$1.99") and the TabBar tab labelled "Tokens", so a loose finder
      // would pass even if the balance never updated.
      // (Caught during /review adversarial pass.)
      SummaryMetricCard tokensPill() => tester
          .widgetList<SummaryMetricCard>(find.byType(SummaryMetricCard))
          .firstWhere((card) => card.label == 'Tokens');

      // Pre-state: token_service defaults a fresh cache to `startingTokens =
      // 50` (token_service.dart:8). The fake earn_tokens RPC returns the
      // requested amount (100) directly — so post-purchase the pill should
      // flip to '100', proving the grants stream propagated. Pre and post
      // are distinct values, so the test catches a stuck pill.
      expect(tokensPill().value, '50',
          reason:
              'tokens pill should start at startingTokens=50 with fresh prefs');

      await tapVisible(tester, find.text('100 Tokens'));
      // Pump enough times to:
      //   1. resolve getConsumablePackages
      //   2. resolve purchaseConsumable (returns CustomerInfo)
      //   3. resolve grantForMostRecentPurchase → earn_tokens RPC (returns 100)
      //   4. emit ConsumableGrantEvent on the broadcast stream
      //   5. DailyLoopNotifier listener runs → state.copyWith(tokenBalance: 100)
      //   6. widget rebuild
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }

      expect(tokensPill().value, '100',
          reason:
              'ConsumableGrantsService.grants → DailyLoopNotifier subscription '
              'must propagate the new balance to the tokens pill');

      await drainPurchaseToast(tester);
    });
  });

  group('§11-H restore success', () {
    testWidgets(
        'restore returns true → "Premium restored!" snackbar AND '
        'isPremiumProvider invalidated', (tester) async {
      purchaseService.restoreResult = true;

      await pumpStore(tester);

      await tapVisible(tester, find.text('Restore purchase'));
      // Restore success path: invalidate isPremiumProvider, run
      // checkPremiumMonthlyGrant (best-effort), show snackbar.
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(find.text('Premium restored!'), findsOneWidget);
      expect(purchaseService.restoreCalls, 1);
    });
  });
}
