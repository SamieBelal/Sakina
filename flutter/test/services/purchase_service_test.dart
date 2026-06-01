import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

// The purchases_flutter plugin uses a MethodChannel named 'purchases_flutter'.
// We mock that channel per-test to exercise PurchaseService's behavior without
// spinning up the real SDK.
const MethodChannel _channel = MethodChannel('purchases_flutter');

Map<String, dynamic> _premiumEntitlement({
  String? billingIssueDetectedAt,
  String periodType = 'NORMAL',
  bool willRenew = true,
  String? unsubscribeDetectedAt,
  bool includeExpiration = true,
}) {
  return <String, dynamic>{
    'identifier': 'premium',
    'isActive': true,
    'willRenew': willRenew,
    'periodType': periodType,
    'latestPurchaseDate': '2026-04-13T12:00:00.000Z',
    'latestPurchaseDateMillis': 1776384000000,
    'originalPurchaseDate': '2026-04-13T12:00:00.000Z',
    'originalPurchaseDateMillis': 1776384000000,
    'productIdentifier': 'sakina_sub_annual',
    'isSandbox': true,
    'store': 'APP_STORE',
    if (includeExpiration) 'expirationDate': '2026-05-13T12:00:00.000Z',
    if (includeExpiration) 'expirationDateMillis': 1778976000000,
    'ownershipType': 'PURCHASED',
    'verification': 'NOT_REQUESTED',
    if (billingIssueDetectedAt != null)
      'billingIssueDetectedAt': billingIssueDetectedAt,
    if (unsubscribeDetectedAt != null)
      'unsubscribeDetectedAt': unsubscribeDetectedAt,
  };
}

Map<String, dynamic> _buildCustomerInfo({
  required bool premiumActive,
  Map<String, dynamic>? entitlementsAllOverride,
  Map<String, dynamic>? entitlementsActiveOverride,
  List<String>? allPurchasedProductIdentifiersOverride,
}) {
  final activeEntitlements = entitlementsActiveOverride ??
      (premiumActive
          ? <String, dynamic>{'premium': _premiumEntitlement()}
          : <String, dynamic>{});
  final allEntitlements = entitlementsAllOverride ??
      (premiumActive
          ? <String, dynamic>{'premium': _premiumEntitlement()}
          : <String, dynamic>{});
  final purchasedIds = allPurchasedProductIdentifiersOverride ??
      (premiumActive ? <String>['sakina_sub_annual'] : <String>[]);
  return <String, dynamic>{
    'originalAppUserId': 'test-user',
    'entitlements': <String, dynamic>{
      'all': allEntitlements,
      'active': activeEntitlements,
      'verification': 'NOT_REQUESTED',
    },
    'activeSubscriptions': premiumActive ? <String>['sakina_sub_annual'] : <String>[],
    'latestExpirationDate':
        premiumActive ? '2026-05-13T12:00:00.000Z' : '2026-04-10T12:00:00.000Z',
    'allExpirationDates': <String, dynamic>{},
    'allPurchasedProductIdentifiers': purchasedIds,
    'firstSeen': '2026-04-01T12:00:00.000Z',
    'requestDate': '2026-04-13T12:00:00.000Z',
    'allPurchaseDates': <String, dynamic>{},
    'originalApplicationVersion': '1.0.0',
    'nonSubscriptionTransactions': <dynamic>[],
  };
}

Package _fakePackage() {
  return const Package(
    'annual',
    PackageType.annual,
    StoreProduct(
      'sakina_sub_annual',
      'Annual subscription',
      'Annual',
      49.99,
      '\$49.99',
      'USD',
    ),
    PresentedOfferingContext('default', null, null),
  );
}

Package _fakeConsumablePackage() {
  return const Package(
    'tokens_100',
    PackageType.custom,
    StoreProduct(
      'sakina_tokens_100',
      '100 Tokens',
      '100 Tokens',
      1.99,
      '\$1.99',
      'USD',
    ),
    PresentedOfferingContext('default', null, null),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final methodLog = <MethodCall>[];
  dynamic mockResponse;
  Object? mockError;
  // Optional per-method responses; falls back to [mockResponse] when not set.
  // Used for flows like setUserId where we need distinct replies to
  // `getAppUserID` and `logIn`.
  final methodResponses = <String, dynamic>{};

  setUp(() {
    methodLog.clear();
    mockResponse = null;
    mockError = null;
    methodResponses.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      methodLog.add(call);
      if (mockError != null) throw mockError!;
      if (methodResponses.containsKey(call.method)) {
        return methodResponses[call.method];
      }
      return mockResponse;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    PurchaseService.debugClearOverride();
  });

  group('initialize()', () {
    test('is inert when both api keys are empty', () async {
      final service = PurchaseService.test();
      await service.initialize(appleApiKey: '', googleApiKey: '');

      // Not initialized — downstream calls should be safe no-ops.
      expect(await service.isPremium(), isFalse);
      expect(await service.getOfferings(), isEmpty);
      expect(methodLog, isEmpty);
    });

    test('is inert when the platform-specific key is empty', () async {
      // On the macOS test host, _platformApiKey returns '' regardless of the
      // apple/google keys. Exercising this path verifies we don't attempt to
      // configure the SDK on unsupported platforms.
      final service = PurchaseService.test();
      await service.initialize(
        appleApiKey: 'irrelevant-on-macos',
        googleApiKey: 'irrelevant-on-macos',
      );

      expect(await service.isPremium(), isFalse);
      expect(methodLog, isEmpty);
    });
  });

  group('isPremium()', () {
    test('returns false when not initialized', () async {
      final service = PurchaseService.test();
      expect(await service.isPremium(), isFalse);
      expect(methodLog, isEmpty);
    });

    test('returns true when active entitlement contains "premium"', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: true);

      expect(await service.isPremium(), isTrue);
      expect(methodLog.single.method, 'getCustomerInfo');
    });

    test('returns false when active entitlements do not contain "premium"',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: false);

      expect(await service.isPremium(), isFalse);
    });

    test('returns false (never throws) when the SDK errors', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockError = PlatformException(code: 'UNKNOWN');

      expect(await service.isPremium(), isFalse);
    });
  });

  group('getOfferings()', () {
    test('returns empty list when not initialized', () async {
      final service = PurchaseService.test();
      expect(await service.getOfferings(), isEmpty);
      expect(methodLog, isEmpty);
    });
  });

  group('getConsumablePackages()', () {
    // Minimal Offerings payload the SDK accepts — see
    // purchases_flutter/Offerings.fromJson. `current` references the
    // subscription offering by id; `all` keys are offering identifiers
    // (RC's `lookup_key`), values include `availablePackages`.
    Map<String, dynamic> buildOfferingsResponse({
      required bool includeConsumables,
    }) {
      Map<String, dynamic> packageJson(String id, String productId) {
        return <String, dynamic>{
          'identifier': id,
          'packageType': 'CUSTOM',
          'product': <String, dynamic>{
            'identifier': productId,
            'description': productId,
            'title': productId,
            'price': 1.99,
            'priceString': '\$1.99',
            'currencyCode': 'USD',
          },
          'offeringIdentifier':
              includeConsumables ? 'consumables' : 'default',
          'presentedOfferingContext': <String, dynamic>{
            'offeringIdentifier':
                includeConsumables ? 'consumables' : 'default',
            'placementIdentifier': null,
            'targetingContext': null,
          },
        };
      }

      final defaultOffering = <String, dynamic>{
        'identifier': 'default',
        'serverDescription': 'subs',
        'metadata': <String, dynamic>{},
        'availablePackages': <Map<String, dynamic>>[
          packageJson('annual', 'sakina_sub_annual'),
        ],
      };
      final consumablesOffering = <String, dynamic>{
        'identifier': 'consumables',
        'serverDescription': 'consumables',
        'metadata': <String, dynamic>{},
        'availablePackages': <Map<String, dynamic>>[
          packageJson('tokens_100', 'sakina_tokens_100'),
          packageJson('scrolls_3', 'sakina_scrolls_3'),
        ],
      };
      return <String, dynamic>{
        'current': defaultOffering,
        'all': <String, dynamic>{
          'default': defaultOffering,
          if (includeConsumables) 'consumables': consumablesOffering,
        },
      };
    }

    test('returns empty list when not initialized', () async {
      final service = PurchaseService.test();
      expect(await service.getConsumablePackages(), isEmpty);
      expect(methodLog, isEmpty);
    });

    test('returns the consumables offering packages, NOT the current offering — '
        'subscription packages must never leak into the Store screen list',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = buildOfferingsResponse(includeConsumables: true);

      final packages = await service.getConsumablePackages();

      expect(packages.map((p) => p.storeProduct.identifier).toList(), [
        'sakina_tokens_100',
        'sakina_scrolls_3',
      ]);
      expect(methodLog.single.method, 'getOfferings');
    });

    test(
        'returns empty list when the `consumables` offering is missing — '
        'callers surface "pack not available" rather than crashing',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = buildOfferingsResponse(includeConsumables: false);

      expect(await service.getConsumablePackages(), isEmpty);
    });
  });

  group('purchaseSubscription()', () {
    test('throws StateError when not initialized', () async {
      final service = PurchaseService.test();
      await expectLater(
        () => service.purchaseSubscription(_fakePackage()),
        throwsA(isA<StateError>()),
      );
    });

    test('returns true when premium entitlement is active after purchase',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // purchasePackage wraps customerInfo in {'customerInfo': ...} per the
      // SDK's _invokeReturningCustomerInfo helper, unlike getCustomerInfo /
      // restorePurchases which return it directly.
      methodResponses['purchasePackage'] = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(premiumActive: true),
      };

      expect(await service.purchaseSubscription(_fakePackage()), isTrue);
      expect(methodLog.single.method, 'purchasePackage');
    });

    test(
        'returns true via fallback getCustomerInfo when first purchasePackage '
        'response is stale (Apple S2S validation lag) — retries once before '
        'declaring failure', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // First purchasePackage call returns stale customerInfo (no premium
      // entitlement yet). The fallback getCustomerInfo returns fresh state
      // showing premium IS active. Without the fallback, the user would see
      // "purchase failed" on a successful purchase and retry → double-charge.
      methodResponses['purchasePackage'] = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(premiumActive: false),
      };
      methodResponses['getCustomerInfo'] =
          _buildCustomerInfo(premiumActive: true);

      expect(await service.purchaseSubscription(_fakePackage()), isTrue);
      final methods = methodLog.map((c) => c.method).toList();
      expect(methods, ['purchasePackage', 'getCustomerInfo']);
    });

    test(
        'returns false when both purchasePackage AND fallback getCustomerInfo '
        'show no premium entitlement (genuine failure)', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      methodResponses['purchasePackage'] = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(premiumActive: false),
      };
      methodResponses['getCustomerInfo'] =
          _buildCustomerInfo(premiumActive: false);

      expect(await service.purchaseSubscription(_fakePackage()), isFalse);
      final methods = methodLog.map((c) => c.method).toList();
      expect(methods, ['purchasePackage', 'getCustomerInfo']);
    });

    test(
        'returns false (does not throw) when fallback getCustomerInfo errors '
        '— fallback failure must not corrupt the failure UX', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // First call succeeds with stale state. Fallback throws (network
      // hiccup, etc.). We treat the throw as "still no entitlement" rather
      // than propagating, so the paywall shows the standard failure copy.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        methodLog.add(call);
        if (call.method == 'purchasePackage') {
          return <String, dynamic>{
            'customerInfo': _buildCustomerInfo(premiumActive: false),
          };
        }
        if (call.method == 'getCustomerInfo') {
          throw PlatformException(code: 'NETWORK_ERROR');
        }
        return null;
      });

      expect(await service.purchaseSubscription(_fakePackage()), isFalse);
    });
  });

  group('purchaseConsumable()', () {
    test('throws StateError when not initialized', () async {
      final service = PurchaseService.test();
      await expectLater(
        () => service.purchaseConsumable(_fakeConsumablePackage()),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'returns the fresh CustomerInfo from purchasePackage — callers pass '
        'this through to ConsumableGrantsService so the just-completed '
        'transaction is visible without a second getCustomerInfo round-trip '
        '(2026-04-28 stale-balance fix: the second fetch races RC\'s cache '
        'and frequently misses the new transaction)', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // Premium is NOT active — consumable purchases never flip an entitlement.
      // RC's contract: no-throw = success, so reaching the assertion means
      // the user has been charged.
      methodResponses['purchasePackage'] = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(
          premiumActive: false,
          allPurchasedProductIdentifiersOverride: const <String>['sakina_tokens_100'],
        ),
      };

      final customerInfo =
          await service.purchaseConsumable(_fakeConsumablePackage());

      expect(customerInfo.originalAppUserId, 'test-user');
      expect(
        customerInfo.allPurchasedProductIdentifiers,
        ['sakina_tokens_100'],
        reason: 'returned customerInfo is the one purchasePackage produced',
      );
      // Critically: only purchasePackage is called. A redundant
      // getCustomerInfo here would race with RC's cache update and was
      // the root cause of the 2026-04-28 stale-balance bug.
      expect(methodLog.map((c) => c.method).toList(), ['purchasePackage']);
    });

    test(
        'propagates SDK PlatformException — RC contract is throw-on-failure, '
        'so callers handle cancellation/payment errors via try/catch',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockError = PlatformException(
        code: PurchasesErrorCode.purchaseCancelledError.index.toString(),
      );

      await expectLater(
        () => service.purchaseConsumable(_fakeConsumablePackage()),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('restorePurchases()', () {
    test('throws StateError when not initialized', () async {
      final service = PurchaseService.test();
      await expectLater(
        service.restorePurchases,
        throwsA(isA<StateError>()),
      );
    });

    test('returns true when restored entitlements include "premium"', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: true);

      expect(await service.restorePurchases(), isTrue);
      expect(methodLog.single.method, 'restorePurchases');
    });

    test('returns false when restored entitlements do not include "premium"',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: false);

      expect(await service.restorePurchases(), isFalse);
    });
  });

  group('setUserId()', () {
    test('is a no-op when not initialized', () async {
      final service = PurchaseService.test();
      await service.setUserId('user-1');
      expect(methodLog, isEmpty);
    });

    test('is a no-op when user id is empty even if initialized', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      await service.setUserId('');
      expect(methodLog, isEmpty);
    });

    test('calls Purchases.logIn when appUserID differs from requested id',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      methodResponses['getAppUserID'] = 'anon-previous';
      methodResponses['logIn'] = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(premiumActive: false),
        'created': false,
      };

      await service.setUserId('user-1');

      final methods = methodLog.map((c) => c.method).toList();
      expect(methods, contains('getAppUserID'));
      expect(methods, contains('logIn'));
      final logInCall = methodLog.firstWhere((c) => c.method == 'logIn');
      expect(logInCall.arguments, containsPair('appUserID', 'user-1'));
    });

    test('skips Purchases.logIn when appUserID already matches (B3 regression)',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      methodResponses['getAppUserID'] = 'user-1';
      // If logIn is ever called, the handler will return null — but the
      // assertion below proves it isn't.
      await service.setUserId('user-1');

      final methods = methodLog.map((c) => c.method).toList();
      expect(methods, contains('getAppUserID'));
      expect(methods, isNot(contains('logIn')));
    });

    test('falls through to logIn when appUserID read throws', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // A bare throw from the channel on getAppUserID — our code should
      // still proceed to logIn rather than silently dropping the identify.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        methodLog.add(call);
        if (call.method == 'getAppUserID') {
          throw PlatformException(code: 'CHANNEL_DOWN');
        }
        if (call.method == 'logIn') {
          return <String, dynamic>{
            'customerInfo': _buildCustomerInfo(premiumActive: false),
            'created': false,
          };
        }
        return null;
      });

      await service.setUserId('user-1');

      final methods = methodLog.map((c) => c.method).toList();
      expect(methods, contains('logIn'));
    });
  });

  group('getBillingIssueDetectedAt()', () {
    test('returns null when not initialized', () async {
      final service = PurchaseService.test();
      expect(await service.getBillingIssueDetectedAt(), isNull);
      expect(methodLog, isEmpty);
    });

    test(
        'returns the timestamp when premium is in entitlements.active with a '
        'billing issue (grace period)', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(
        premiumActive: true,
        entitlementsActiveOverride: {
          'premium': _premiumEntitlement(
            billingIssueDetectedAt: '2026-04-17T12:00:00.000Z',
          ),
        },
        entitlementsAllOverride: {
          'premium': _premiumEntitlement(
            billingIssueDetectedAt: '2026-04-17T12:00:00.000Z',
          ),
        },
      );

      expect(
        await service.getBillingIssueDetectedAt(),
        '2026-04-17T12:00:00.000Z',
      );
    });

    test(
        'returns null when premium is only in entitlements.all (expired) — '
        'B1 regression: expired subs must not keep showing the banner',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // Simulate an expired sub: present in .all (with a historical
      // billingIssueDetectedAt) but absent from .active.
      mockResponse = _buildCustomerInfo(
        premiumActive: false,
        entitlementsActiveOverride: const <String, dynamic>{},
        entitlementsAllOverride: {
          'premium': _premiumEntitlement(
            billingIssueDetectedAt: '2026-01-01T12:00:00.000Z',
          ),
        },
      );

      expect(await service.getBillingIssueDetectedAt(), isNull);
    });

    test('returns null when SDK throws', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockError = PlatformException(code: 'UNKNOWN');

      expect(await service.getBillingIssueDetectedAt(), isNull);
    });
  });

  group('getVoluntaryCancellation()', () {
    // A cancelled-but-still-active entitlement: willRenew false with an
    // unsubscribeDetectedAt, no billing issue. This is the instant-path signal
    // read right after the Customer Center sheet closes.
    Map<String, dynamic> cancelledInfo({
      String periodType = 'NORMAL',
      String? billingIssueDetectedAt,
      bool includeExpiration = true,
    }) {
      final ent = _premiumEntitlement(
        periodType: periodType,
        willRenew: false,
        unsubscribeDetectedAt: '2026-05-01T09:00:00.000Z',
        billingIssueDetectedAt: billingIssueDetectedAt,
        includeExpiration: includeExpiration,
      );
      return _buildCustomerInfo(
        premiumActive: true,
        entitlementsAllOverride: {'premium': ent},
        entitlementsActiveOverride: {'premium': ent},
      );
    }

    test('returns null when not initialized', () async {
      final service = PurchaseService.test();
      expect(await service.getVoluntaryCancellation(), isNull);
      expect(methodLog, isEmpty);
    });

    test('returns null when the sub will still renew (not cancelled)', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: true); // willRenew true
      expect(await service.getVoluntaryCancellation(), isNull);
    });

    test('returns null when there is no unsubscribeDetectedAt', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      final ent = _premiumEntitlement(willRenew: false); // no unsubscribe ts
      mockResponse = _buildCustomerInfo(
        premiumActive: true,
        entitlementsAllOverride: {'premium': ent},
        entitlementsActiveOverride: {'premium': ent},
      );
      expect(await service.getVoluntaryCancellation(), isNull);
    });

    test('returns null for involuntary churn (billing issue set)', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = cancelledInfo(
        billingIssueDetectedAt: '2026-04-30T09:00:00.000Z',
      );
      expect(await service.getVoluntaryCancellation(), isNull);
    });

    test('returns null when expirationDate is missing (no dedupe key)',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = cancelledInfo(includeExpiration: false);
      expect(await service.getVoluntaryCancellation(), isNull);
    });

    test('returns a context for a voluntary cancellation', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = cancelledInfo();
      final result = await service.getVoluntaryCancellation();
      expect(result, isNotNull);
      expect(result!.expiresAt,
          DateTime.parse('2026-05-13T12:00:00.000Z'));
      expect(result.canceledAt,
          DateTime.parse('2026-05-01T09:00:00.000Z'));
      expect(result.periodType, 'normal');
    });

    test('maps periodType TRIAL -> trial and INTRO -> intro', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();

      mockResponse = cancelledInfo(periodType: 'TRIAL');
      expect((await service.getVoluntaryCancellation())!.periodType, 'trial');

      mockResponse = cancelledInfo(periodType: 'INTRO');
      expect((await service.getVoluntaryCancellation())!.periodType, 'intro');
    });

    test('forceRefresh invalidates the customerInfo cache before reading',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      methodResponses['getCustomerInfo'] = cancelledInfo();

      await service.getVoluntaryCancellation(forceRefresh: true);

      final methods = methodLog.map((c) => c.method).toList();
      expect(methods, ['invalidateCustomerInfoCache', 'getCustomerInfo']);
    });

    test('returns null (never throws) when the SDK errors', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockError = PlatformException(code: 'UNKNOWN');
      expect(await service.getVoluntaryCancellation(), isNull);
    });
  });

  group('debug override', () {
    test('factory returns the override when set', () {
      final override = PurchaseService.test();
      PurchaseService.debugSetOverride(override);
      expect(identical(PurchaseService(), override), isTrue);
    });

    test('factory returns the singleton after clear', () {
      final override = PurchaseService.test();
      PurchaseService.debugSetOverride(override);
      PurchaseService.debugClearOverride();
      expect(identical(PurchaseService(), override), isFalse);
    });
  });

  group('hadTrial()', () {
    late FakeSupabaseSyncService fakeSync;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
    });

    tearDown(SupabaseSyncService.debugReset);

    test('returns false when not initialized and no cached flag', () async {
      final service = PurchaseService.test();
      expect(await service.hadTrial(), isFalse);
      expect(methodLog, isEmpty);
    });

    test('returns false when premium entitlement absent from .all', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: false);

      expect(await service.hadTrial(), isFalse);
      expect(methodLog.single.method, 'getCustomerInfo');
    });

    test('returns true on active trial periodType', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(
        premiumActive: true,
        entitlementsAllOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
        entitlementsActiveOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
      );

      expect(await service.hadTrial(), isTrue);
    });

    test('returns true on expired trial (still in .all but not .active)',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(
        premiumActive: false,
        entitlementsActiveOverride: const <String, dynamic>{},
        entitlementsAllOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
      );

      expect(await service.hadTrial(), isTrue);
    });

    test(
        'first true detection writes had_trial=true to BOTH SharedPreferences '
        'AND Supabase', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(
        premiumActive: true,
        entitlementsAllOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
        entitlementsActiveOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
      );

      expect(await service.hadTrial(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(fakeSync.scopedKey('had_trial')), isTrue);

      // user_profiles uses upsertRawRow (PK is `id`, not `user_id`).
      // Regression for the 2026-05-10 sim-test bug where `had_trial` writes
      // silently failed because upsertRow injected `user_id`.
      expect(fakeSync.rawUpsertCalls, hasLength(1));
      final call = fakeSync.rawUpsertCalls.single;
      expect(call['table'], 'user_profiles');
      final data = call['data'] as Map;
      expect(data['had_trial'], isTrue);
      expect(data['id'], isNotNull,
          reason: 'must include id so upsert matches the existing row');
    });

    test('subsequent calls short-circuit (no Supabase write, no RC re-read)',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(
        premiumActive: true,
        entitlementsAllOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
        entitlementsActiveOverride: {
          'premium': _premiumEntitlement(periodType: 'TRIAL'),
        },
      );

      // First call: detects trial + writes.
      expect(await service.hadTrial(), isTrue);
      expect(fakeSync.rawUpsertCalls, hasLength(1));
      methodLog.clear();
      fakeSync.rawUpsertCalls.clear();

      // Second call: must short-circuit on cached SharedPrefs flag.
      expect(await service.hadTrial(), isTrue);
      expect(methodLog, isEmpty,
          reason:
              'idempotent latch: subsequent hadTrial() must not re-read RC');
      expect(fakeSync.rawUpsertCalls, isEmpty,
          reason:
              'idempotent latch: subsequent hadTrial() must not re-write Supabase');
    });

    test('non-trial periodType (normal subscription) returns false', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = _buildCustomerInfo(premiumActive: true);
      // Default periodType in helper is 'normal'.

      expect(await service.hadTrial(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(fakeSync.scopedKey('had_trial')), isNull);
    });
  });
}
