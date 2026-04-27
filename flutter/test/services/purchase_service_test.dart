import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/services/purchase_service.dart';

// The purchases_flutter plugin uses a MethodChannel named 'purchases_flutter'.
// We mock that channel per-test to exercise PurchaseService's behavior without
// spinning up the real SDK.
const MethodChannel _channel = MethodChannel('purchases_flutter');

Map<String, dynamic> _premiumEntitlement({String? billingIssueDetectedAt}) {
  return <String, dynamic>{
    'identifier': 'premium',
    'isActive': true,
    'willRenew': true,
    'periodType': 'normal',
    'latestPurchaseDate': '2026-04-13T12:00:00.000Z',
    'latestPurchaseDateMillis': 1776384000000,
    'originalPurchaseDate': '2026-04-13T12:00:00.000Z',
    'originalPurchaseDateMillis': 1776384000000,
    'productIdentifier': 'sakina_sub_annual',
    'isSandbox': true,
    'store': 'APP_STORE',
    'expirationDate': '2026-05-13T12:00:00.000Z',
    'expirationDateMillis': 1778976000000,
    'ownershipType': 'PURCHASED',
    'verification': 'NOT_REQUESTED',
    if (billingIssueDetectedAt != null)
      'billingIssueDetectedAt': billingIssueDetectedAt,
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
        'returns true on a non-throwing SDK return — premium is NOT active '
        '(regression: pre-fix `purchase()` returned the premium entitlement '
        'check, which was `false` for consumables, so `_buyTokensIAP` skipped '
        '`earnTokens()` and users lost paid-for tokens silently)', () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      // Premium is NOT active — consumable purchases never flip an entitlement.
      // The new contract: a non-throwing `purchasePackage` means StoreKit
      // recorded the transaction, so the local grant must run. We do NOT
      // gate on `allPurchasedProductIdentifiers` (which would have been
      // empty for a first-time consumable buyer pre-fix).
      methodResponses['purchasePackage'] = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(
          premiumActive: false,
          allPurchasedProductIdentifiersOverride: const <String>[],
        ),
      };

      expect(
        await service.purchaseConsumable(_fakeConsumablePackage()),
        isTrue,
        reason: 'no-throw = success per RC contract; local grant must run',
      );
      expect(methodLog.single.method, 'purchasePackage');
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
}
