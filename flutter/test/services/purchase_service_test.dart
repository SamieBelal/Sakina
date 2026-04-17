import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/services/purchase_service.dart';

// The purchases_flutter plugin uses a MethodChannel named 'purchases_flutter'.
// We mock that channel per-test to exercise PurchaseService's behavior without
// spinning up the real SDK.
const MethodChannel _channel = MethodChannel('purchases_flutter');

Map<String, dynamic> _buildCustomerInfo({required bool premiumActive}) {
  return <String, dynamic>{
    'originalAppUserId': 'test-user',
    'entitlements': <String, dynamic>{
      'all': premiumActive
          ? <String, dynamic>{
              'premium': <String, dynamic>{
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
              },
            }
          : <String, dynamic>{},
      'active': premiumActive
          ? <String, dynamic>{
              'premium': <String, dynamic>{
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
              },
            }
          : <String, dynamic>{},
      'verification': 'NOT_REQUESTED',
    },
    'activeSubscriptions': premiumActive ? <String>['sakina_sub_annual'] : <String>[],
    'latestExpirationDate':
        premiumActive ? '2026-05-13T12:00:00.000Z' : '2026-04-10T12:00:00.000Z',
    'allExpirationDates': <String, dynamic>{},
    'allPurchasedProductIdentifiers':
        premiumActive ? <String>['sakina_sub_annual'] : <String>[],
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final methodLog = <MethodCall>[];
  dynamic mockResponse;
  Object? mockError;

  setUp(() {
    methodLog.clear();
    mockResponse = null;
    mockError = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      methodLog.add(call);
      if (mockError != null) throw mockError!;
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

  group('purchase()', () {
    test('throws StateError when not initialized', () async {
      final service = PurchaseService.test();
      await expectLater(
        () => service.purchase(_fakePackage()),
        throwsA(isA<StateError>()),
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

    test('calls Purchases.logIn when initialized with a non-empty id',
        () async {
      final service = PurchaseService.test();
      service.debugMarkInitialized();
      mockResponse = <String, dynamic>{
        'customerInfo': _buildCustomerInfo(premiumActive: false),
        'created': false,
      };

      await service.setUserId('user-1');

      expect(methodLog.single.method, 'logIn');
      expect(methodLog.single.arguments, containsPair('appUserID', 'user-1'));
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
