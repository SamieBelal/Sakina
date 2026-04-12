import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/collection/screens/collection_screen.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

void main() {
  test(
      'collection tier-up failure presentation covers success and both failures',
      () {
    expect(
      collectionTierUpFailurePresentation(
        spendResult: const TierUpScrollSpendResult(
          success: true,
          newBalance: 4,
        ),
        scrollCost: 5,
        scrollBalance: 4,
        nextTier: 'Silver',
      ),
      isNull,
    );

    final insufficient = collectionTierUpFailurePresentation(
      spendResult: const TierUpScrollSpendResult(
        success: false,
        newBalance: 2,
        failureReason: TierUpScrollFailureReason.insufficientBalance,
      ),
      scrollCost: 5,
      scrollBalance: 2,
      nextTier: 'Silver',
    );
    expect(insufficient, isNotNull);
    expect(insufficient!.title, 'Not Enough Scrolls');
    expect(insufficient.primaryAction, CollectionTierUpFailureAction.goToStore);
    expect(
      insufficient.message,
      'You need 5 scrolls to upgrade to Silver. You have 2.',
    );

    final syncFailed = collectionTierUpFailurePresentation(
      spendResult: const TierUpScrollSpendResult(
        success: false,
        newBalance: 5,
        failureReason: TierUpScrollFailureReason.syncFailed,
      ),
      scrollCost: 5,
      scrollBalance: 5,
      nextTier: 'Gold',
    );
    expect(syncFailed, isNotNull);
    expect(syncFailed!.title, 'Couldn\'t Spend Scrolls');
    expect(syncFailed.primaryAction, CollectionTierUpFailureAction.retry);
    expect(syncFailed.primaryActionLabel, 'Try Again');
  });
}
