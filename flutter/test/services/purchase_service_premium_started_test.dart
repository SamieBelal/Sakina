import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/purchase_service.dart';

/// Covers the RC-free branch of [PurchaseService.getActivePremiumStartedAt].
/// The entitlement-read branch needs a live RevenueCat SDK (can't be faked in
/// a Dart unit test) and is covered by the widget test's PurchaseService
/// override plus the simulator run.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns null when RevenueCat is not initialized (no RC round-trip)',
      () async {
    final service = PurchaseService.test(); // _initialized defaults to false
    expect(await service.getActivePremiumStartedAt(), isNull);
  });
}
