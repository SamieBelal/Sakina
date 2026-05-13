import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/purchase_service.dart';

/// Unit-test for the combined `premiumStateProvider`. Covers the four paths
/// resolved by /plan-eng-review:
///   1. SDK reports not premium → `(false, null)`, billing fetch skipped.
///   2. SDK reports premium, no billing issue → `(true, null)`.
///   3. SDK reports premium with billing issue → `(true, <iso>)`.
///   4. The short-circuit on path 1 actually does not call
///      `getBillingIssueDetectedAt`, asserted via the spy counter.
class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService({
    required this.premium,
    this.billingIssueAt,
  }) : super.test();

  final bool premium;
  final String? billingIssueAt;

  int isPremiumCalls = 0;
  int billingIssueCalls = 0;

  @override
  Future<bool> isPremium() async {
    isPremiumCalls += 1;
    return premium;
  }

  @override
  Future<String?> getBillingIssueDetectedAt() async {
    billingIssueCalls += 1;
    return billingIssueAt;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(PurchaseService.debugClearOverride);

  test('returns (false, null) when the SDK reports not premium', () async {
    final fake = _FakePurchaseService(premium: false);
    PurchaseService.debugSetOverride(fake);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(premiumStateProvider.future);

    expect(state.isPremium, isFalse);
    expect(state.billingIssueAt, isNull);
  });

  test('returns (true, null) when premium with no billing issue', () async {
    final fake = _FakePurchaseService(premium: true, billingIssueAt: null);
    PurchaseService.debugSetOverride(fake);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(premiumStateProvider.future);

    expect(state.isPremium, isTrue);
    expect(state.billingIssueAt, isNull);
  });

  test('returns (true, <iso>) when premium with a billing issue', () async {
    final fake = _FakePurchaseService(
      premium: true,
      billingIssueAt: '2026-05-13T12:00:00.000Z',
    );
    PurchaseService.debugSetOverride(fake);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(premiumStateProvider.future);

    expect(state.isPremium, isTrue);
    expect(state.billingIssueAt, '2026-05-13T12:00:00.000Z');
  });

  test(
      'short-circuits the billing-issue fetch when isPremium == false '
      '(spec: no point asking RC for billing on a non-subscriber)', () async {
    final fake = _FakePurchaseService(premium: false);
    PurchaseService.debugSetOverride(fake);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(premiumStateProvider.future);

    expect(fake.isPremiumCalls, 1);
    expect(
      fake.billingIssueCalls,
      0,
      reason: 'getBillingIssueDetectedAt must NOT be invoked on free users',
    );
  });

  test('still calls billing-issue when premium == true', () async {
    final fake = _FakePurchaseService(premium: true, billingIssueAt: null);
    PurchaseService.debugSetOverride(fake);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(premiumStateProvider.future);

    expect(fake.isPremiumCalls, 1);
    expect(fake.billingIssueCalls, 1);
  });
}
