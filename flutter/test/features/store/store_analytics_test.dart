// §11-ANALYTICS — Store purchase-funnel analytics.
//
// Covers the NON-StoreKit-gated Store analytics events (those that don't need a
// real StoreKit transaction to fire). The full success path is exercised here
// by reusing the same PurchaseService fake the main store_screen_test.dart uses
// (FakeStorePurchaseService) — the `purchaseConsumable` seam returns a
// CustomerInfo carrying the just-purchased SKU so `grantForMostRecentPurchase`
// credits it and `store_purchase_succeeded` fires with price/currency.
//
// Events asserted:
//   - store_viewed            — fires exactly once on mount (initState)
//   - pack_selected           — top of _buyTokensIAP {pack_id, amount, kind}
//   - store_purchase_succeeded — after grant {+price, +currency}
//   - store_purchase_failed   — reason == unavailable when getConsumablePackages
//                               returns no matching package
//
// The analytics seam is a recording spy injected via analyticsProvider — the
// Store screen captures `ref.read(analyticsProvider)` in initState, so the
// override must be in place before the widget mounts (it is — ProviderScope
// overrides resolve at first read).
//
// Toast Timer drain: the success path schedules `_PurchaseToastWidget`'s
// Future.delayed(2500ms) to remove its OverlayEntry. Every success test pumps
// 3s so that future (and the repeat() icon animation it owns) cleans up before
// teardown, otherwise the binding reports "Timer is still pending after
// disposed".

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sakina/features/store/screens/store_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/public_catalog_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

const MethodChannel _purchasesChannel = MethodChannel('purchases_flutter');

/// Recording spy — captures every `track(event, properties)` call so tests can
/// assert exact event names, ordering, and property payloads. Mirrors the spy
/// shape used elsewhere in the analytics suite.
class _Spy extends AnalyticsService {
  final tracked = <(String, Map<String, dynamic>?)>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      tracked.add((event, properties));

  /// All recorded event names, in fire order.
  List<String> get events => tracked.map((e) => e.$1).toList();

  /// Properties for the first occurrence of [event], or null if never fired.
  Map<String, dynamic>? propsFor(String event) =>
      tracked.where((e) => e.$1 == event).map((e) => e.$2).firstOrNull;
}

/// Same PurchaseService double as store_screen_test.dart — returns the
/// configured consumable packages (or throws), and returns a seeded
/// CustomerInfo from `purchaseConsumable` so the grant path can find the
/// just-completed transaction.
class FakeStorePurchaseService extends PurchaseService {
  FakeStorePurchaseService() : super.test();

  List<Package> consumablePackages = <Package>[];
  Object? consumablePackagesError;

  CustomerInfo Function()? consumableCustomerInfoBuilder;
  Object? consumableError;
  int consumableCalls = 0;

  @override
  Future<List<Package>> getConsumablePackages() async {
    if (consumablePackagesError != null) throw consumablePackagesError!;
    return consumablePackages;
  }

  @override
  Future<CustomerInfo> purchaseConsumable(Package package) async {
    consumableCalls += 1;
    if (consumableError != null) throw consumableError!;
    final builder = consumableCustomerInfoBuilder;
    if (builder == null) {
      throw StateError('consumableCustomerInfoBuilder not set');
    }
    return builder();
  }

  @override
  Future<bool> restorePurchases() async => false;

  @override
  Future<bool> isPremium() async => false;
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
  late _Spy spy;
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
    spy = _Spy();
    mockedTransactions = <Map<String, dynamic>>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_purchasesChannel, (call) async {
      if (call.method == 'getCustomerInfo') {
        return buildCustomerInfoJson();
      }
      return null;
    });
    fakeSync.rpcHandlers['earn_tokens'] = (args) async {
      final amount = (args?['amount'] as int?) ?? 0;
      return amount;
    };
    fakeSync.rpcHandlers['earn_scrolls'] = (args) async {
      final amount = (args?['amount'] as int?) ?? 0;
      return amount;
    };

    purchaseService = FakeStorePurchaseService();
    PurchaseService.debugSetOverride(purchaseService);
    debugSetPremiumGrantPurchaseService(purchaseService);

    purchaseService.consumableCustomerInfoBuilder =
        () => CustomerInfo.fromJson(buildCustomerInfoJson());

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

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  GoRouter buildRouter() {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SizedBox(
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
        analyticsProvider.overrideWithValue(spy),
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

  Future<void> pumpStore(WidgetTester tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> drainPurchaseToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
  }

  group('store_viewed', () {
    testWidgets('fires exactly once on mount', (tester) async {
      await pumpStore(tester);

      final views =
          spy.events.where((e) => e == AnalyticsEvents.storeViewed).toList();
      expect(views, hasLength(1),
          reason: 'store_viewed is emitted once from initState — re-mounts or '
              'rebuilds must not double-count it');
    });
  });

  group('pack_selected → store_purchase_succeeded (token pack)', () {
    testWidgets(
        'tapping a token pack fires pack_selected{pack_id, amount, kind:tokens} '
        'then store_purchase_succeeded{price, currency}', (tester) async {
      // Seed the purchased SKU onto the CustomerInfo `purchaseConsumable`
      // returns so grantForMostRecentPurchase credits it and the success
      // event fires (rather than the grant path no-op'ing).
      mockedTransactions.add(<String, dynamic>{
        'transactionIdentifier': 'sim-txn-tokens-100',
        'revenueCatIdentifier': 'sim-txn-tokens-100',
        'productIdentifier': 'sakina_tokens_100',
        'purchaseDate': '2026-04-26T12:00:00.000Z',
      });

      await pumpStore(tester);

      await tapVisible(tester, find.text('100 Tokens'));
      // Resolve: getConsumablePackages → purchaseConsumable → grant → emit.
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }

      // pack_selected payload.
      final selectedProps = spy.propsFor(AnalyticsEvents.packSelected);
      expect(selectedProps, isNotNull,
          reason: 'pack_selected must fire at the top of _buyTokensIAP');
      expect(selectedProps!['pack_id'], 'sakina_tokens_100');
      expect(selectedProps['amount'], 100);
      expect(selectedProps['kind'], 'tokens');

      // store_purchase_succeeded payload.
      final succeededProps =
          spy.propsFor(AnalyticsEvents.storePurchaseSucceeded);
      expect(succeededProps, isNotNull,
          reason: 'store_purchase_succeeded must fire after the grant');
      expect(succeededProps!['pack_id'], 'sakina_tokens_100');
      expect(succeededProps['amount'], 100);
      expect(succeededProps['kind'], 'tokens');
      expect(succeededProps['price'], 1.99);
      expect(succeededProps['currency'], 'USD');

      // Ordering: pack_selected precedes store_purchase_succeeded; no failure.
      final selectedIdx = spy.events.indexOf(AnalyticsEvents.packSelected);
      final succeededIdx =
          spy.events.indexOf(AnalyticsEvents.storePurchaseSucceeded);
      expect(selectedIdx, lessThan(succeededIdx));
      expect(spy.events, isNot(contains(AnalyticsEvents.storePurchaseFailed)));
      expect(purchaseService.consumableCalls, 1);

      await drainPurchaseToast(tester);
    });
  });

  group('store_purchase_failed — unavailable', () {
    testWidgets(
        'no matching package → store_purchase_failed{reason: unavailable}',
        (tester) async {
      // Packages present but NONE match the tapped SKU — drives the
      // `package == null` branch (reason: unavailable), distinct from an empty
      // list or a thrown fetch.
      purchaseService.consumablePackages = [
        _pkg('sakina_scrolls_3', 0.99),
      ];

      await pumpStore(tester);

      await tapVisible(tester, find.text('100 Tokens'));
      await tester.pump();
      await tester.pump();

      // pack_selected still fires (it's emitted before the lookup).
      expect(spy.events, contains(AnalyticsEvents.packSelected));

      final failedProps = spy.propsFor(AnalyticsEvents.storePurchaseFailed);
      expect(failedProps, isNotNull,
          reason: 'store_purchase_failed must fire when no package matches');
      expect(failedProps!['pack_id'], 'sakina_tokens_100');
      expect(failedProps['amount'], 100);
      expect(failedProps['kind'], 'tokens');
      expect(failedProps['reason'],
          AnalyticsEvents.storePurchaseFailedReasonUnavailable);

      // No charge was attempted and no success event fired.
      expect(purchaseService.consumableCalls, 0);
      expect(
          spy.events, isNot(contains(AnalyticsEvents.storePurchaseSucceeded)));
    });
  });
}
