// The async equip gate the wardrobe awaits before offering Equip: Lane B's
// canEquip, with premium injected. Premium-exclusive rows are equippable ONLY
// while premium is active — they never convert to ownership.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';

class _StubPurchaseService extends PurchaseService {
  _StubPurchaseService(this.premium) : super.test();
  final bool premium;
  @override
  Future<bool> isPremium() async => premium;
}

const _state = CosmeticsState(
  noorBalance: 0,
  equippedLanternSkin: 'classic_gold',
  equippedBackdrop: 'default',
  ownedLanternSkins: {},
  ownedBackdrops: {},
);

void main() {
  test('premium-exclusive equippable only while premium', () async {
    expect(
      await canEquip(
        state: _state,
        itemType: itemTypeLanternSkin,
        itemId: 'ramadan_royal',
        isPremiumExclusive: true,
        purchaseService: _StubPurchaseService(true),
      ),
      isTrue,
    );
    expect(
      await canEquip(
        state: _state,
        itemType: itemTypeLanternSkin,
        itemId: 'ramadan_royal',
        isPremiumExclusive: true,
        purchaseService: _StubPurchaseService(false),
      ),
      isFalse,
    );
  });

  test('premium does NOT unlock a plain unowned skin', () async {
    expect(
      await canEquip(
        state: _state,
        itemType: itemTypeLanternSkin,
        itemId: 'emerald_jade',
        isPremiumExclusive: false,
        purchaseService: _StubPurchaseService(true),
      ),
      isFalse,
    );
  });

  test('owned item is always equippable', () async {
    const owned = CosmeticsState(
      noorBalance: 0,
      equippedLanternSkin: 'classic_gold',
      equippedBackdrop: 'default',
      ownedLanternSkins: {'emerald_jade'},
      ownedBackdrops: {},
    );
    expect(
      await canEquip(
        state: owned,
        itemType: itemTypeLanternSkin,
        itemId: 'emerald_jade',
        isPremiumExclusive: false,
        purchaseService: _StubPurchaseService(false),
      ),
      isTrue,
    );
  });

  test('the always-owned defaults are equippable without premium', () async {
    expect(
      await canEquip(
        state: _state,
        itemType: itemTypeLanternSkin,
        itemId: defaultLanternSkin,
        isPremiumExclusive: false,
        purchaseService: _StubPurchaseService(false),
      ),
      isTrue,
    );
    expect(
      await canEquip(
        state: _state,
        itemType: itemTypeBackdrop,
        itemId: defaultBackdrop,
        isPremiumExclusive: false,
        purchaseService: _StubPurchaseService(false),
      ),
      isTrue,
    );
  });
}
