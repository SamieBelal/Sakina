import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_event_names.dart';

void main() {
  test('cosmetics event-name constants have their pinned dashboard values', () {
    expect(AnalyticsEvents.noorEarned, 'noor_earned');
    expect(AnalyticsEvents.cosmeticUnlocked, 'cosmetic_unlocked');
    expect(AnalyticsEvents.cosmeticEquipped, 'cosmetic_equipped');
    expect(AnalyticsEvents.cosmeticIapPurchased, 'cosmetic_iap_purchased');
    expect(AnalyticsEvents.milestoneSkinUnlocked, 'milestone_skin_unlocked');
    expect(AnalyticsEvents.cosmeticUnlockRejected, 'cosmetic_unlock_rejected');
    expect(AnalyticsEvents.propItemType, 'item_type');
    expect(AnalyticsEvents.propItemId, 'item_id');
    expect(AnalyticsEvents.propAmount, 'amount');
    expect(AnalyticsEvents.propReason, 'reason');
    expect(AnalyticsEvents.cosmeticViaNoor, 'noor');
    expect(AnalyticsEvents.cosmeticViaIap, 'iap');
  });

  test('lane D screen/preview event names match the Mixpanel contract', () {
    expect(AnalyticsEvents.companionScreenOpened, 'companion_screen_opened');
    expect(AnalyticsEvents.wardrobeOpened, 'wardrobe_opened');
    expect(AnalyticsEvents.cosmeticPreviewed, 'cosmetic_previewed');
    expect(AnalyticsEvents.propTab, 'tab');
  });
}
