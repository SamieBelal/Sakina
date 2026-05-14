import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/services/purchase_service.dart';

/// Pins that `PurchaseService.getOfferings()` strips monthly /
/// twoMonth / threeMonth / sixMonth packages at the service boundary.
///
/// The paywall screen already picks packages by `PackageType.annual` /
/// `PackageType.weekly`, so a monthly package would never get rendered
/// today — but defending at the service boundary protects every consumer
/// (winback sheets, debug surfaces, future A/B variants) from ever
/// surfacing a monthly SKU.
const MethodChannel _channel = MethodChannel('purchases_flutter');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final methodLog = <MethodCall>[];
  dynamic mockResponse;

  setUp(() {
    methodLog.clear();
    mockResponse = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      methodLog.add(call);
      return mockResponse;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    PurchaseService.debugClearOverride();
  });

  /// Builds an Offerings response payload whose `current` offering contains
  /// weekly + monthly + annual packages, plus a sprinkling of the longer
  /// multi-month variants — so the filter must trip on every one.
  Map<String, dynamic> buildOfferingsResponse() {
    Map<String, dynamic> packageJson(
      String id,
      String packageType,
      String productId,
    ) {
      return <String, dynamic>{
        'identifier': id,
        'packageType': packageType,
        'product': <String, dynamic>{
          'identifier': productId,
          'description': productId,
          'title': productId,
          'price': 9.99,
          'priceString': '\$9.99',
          'currencyCode': 'USD',
        },
        'offeringIdentifier': 'default',
        'presentedOfferingContext': <String, dynamic>{
          'offeringIdentifier': 'default',
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
        packageJson('weekly', 'WEEKLY', 'sakina_weekly'),
        packageJson('monthly', 'MONTHLY', 'sakina_monthly'),
        packageJson('two_month', 'TWO_MONTH', 'sakina_2mo'),
        packageJson('three_month', 'THREE_MONTH', 'sakina_3mo'),
        packageJson('six_month', 'SIX_MONTH', 'sakina_6mo'),
        packageJson('annual', 'ANNUAL', 'sakina_annual'),
      ],
    };
    return <String, dynamic>{
      'current': defaultOffering,
      'all': <String, dynamic>{
        'default': defaultOffering,
      },
    };
  }

  test(
      'getOfferings() returns weekly + annual only — monthly and longer '
      'multi-month variants are filtered at the service boundary so no '
      'downstream consumer can surface them', () async {
    final service = PurchaseService.test();
    service.debugMarkInitialized();
    mockResponse = buildOfferingsResponse();

    final packages = await service.getOfferings();

    final types = packages.map((p) => p.packageType).toList();
    expect(types, contains(PackageType.weekly));
    expect(types, contains(PackageType.annual));
    expect(types, isNot(contains(PackageType.monthly)));
    expect(types, isNot(contains(PackageType.twoMonth)));
    expect(types, isNot(contains(PackageType.threeMonth)));
    expect(types, isNot(contains(PackageType.sixMonth)));
    // Exactly two packages survive — guards against future regressions
    // that accidentally let through a new long-term tier.
    expect(packages.length, 2);
  });
}
