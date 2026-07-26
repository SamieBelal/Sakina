// I1: the à-la-carte skin IAP is NOT wired yet, so the wardrobe must not offer
// a Buy CTA.
//
// `completeSkinIapPurchase` deliberately only RE-SYNCS — the RevenueCat webhook
// is the sole server-side granter (`grant_cosmetic_iap` is revoked from
// `authenticated`). Calling it from a Buy button WITHOUT first running the real
// RevenueCat purchase opens no App Store sheet, moves no money, grants nothing,
// and still reports success. This file pins the safe shape while
// [kSkinIapEnabled] is false:
//
//   • an unowned à-la-carte skin resolves to a non-actionable teaser, NOT buy;
//   • the teaser asserts no price (the hardcoded r'$2.99' was wrong in every
//     non-USD storefront — the real label must come from
//     StoreProduct.priceString);
//   • the tile badge does not say "Buy" for something that cannot be bought;
//   • no code path can display "Purchased".
//
// DB-free: cosmeticsStateProvider is overridden, the sync service is the fake,
// and PurchaseService is stubbed.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_action_bar.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../support/fake_supabase_sync_service.dart';

class _StubPurchaseService extends PurchaseService {
  _StubPurchaseService(this.premium) : super.test();
  final bool premium;
  @override
  Future<bool> isPremium() async => premium;
}

CosmeticsState _state({int noor = 0, Set<String> ownedSkins = const {}}) =>
    CosmeticsState(
      noorBalance: noor,
      equippedLanternSkin: 'classic_gold',
      equippedBackdrop: 'default',
      ownedLanternSkins: ownedSkins,
      ownedBackdrops: const {},
    );

void main() {
  final obsidian = catalogEntryFor(itemTypeLanternSkin, 'obsidian_gold')!;

  test('the à-la-carte skin IAP stays disabled until the SKUs are live', () {
    // The premise of this whole file. Flipping this to true is a deliberate act
    // that must come WITH the RevenueCat purchase wiring (see _buy's TODO).
    expect(kSkinIapEnabled, isFalse);
  });

  test('an unowned à-la-carte skin resolves to a teaser, never buy', () {
    expect(
      resolveWardrobeAction(
          state: _state(noor: 10), entry: obsidian, equippable: false),
      WardrobeAction.comingSoonTeaser,
    );
  });

  test('the Noor path and ownership are untouched by the disabled IAP', () {
    // Noor still unlocks an à-la-carte skin — the SKUs being absent from the
    // App Store says nothing about the in-app currency price.
    expect(
      resolveWardrobeAction(
          state: _state(noor: 200), entry: obsidian, equippable: false),
      WardrobeAction.unlock,
    );
    expect(
      resolveWardrobeAction(
        state: _state(ownedSkins: {'obsidian_gold'}),
        entry: obsidian,
        equippable: true,
      ),
      WardrobeAction.equip,
    );
  });

  group('wardrobe screen', () {
    setUp(() {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      SharedPreferences.setMockInitialValues({});
      SupabaseSyncService.debugSetInstance(
          FakeSupabaseSyncService(userId: 'u1'));
      PurchaseService.debugSetOverride(_StubPurchaseService(false));
    });

    tearDown(() {
      PurchaseService.debugClearOverride();
      SupabaseSyncService.debugReset();
    });

    Widget harness() => ProviderScope(
          overrides: [
            cosmeticsStateProvider.overrideWith((ref) async => _state(noor: 10)),
          ],
          child: const MaterialApp(home: WardrobeScreen()),
        );

    /// Tall enough that the third grid row (obsidian) is actually laid out.
    Future<void> tallSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    testWidgets('previewing an à-la-carte skin shows Coming soon and no price',
        (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(WardrobeTile, 'Obsidian & Gold'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.textContaining(r'$2.99'), findsNothing);
      expect(find.textContaining('Get'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('the à-la-carte tile is not badged Buy while the IAP is off',
        (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 100));

      final tile = find.widgetWithText(WardrobeTile, 'Obsidian & Gold');
      expect(tile, findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('Buy')), findsNothing);
      expect(find.descendant(of: tile, matching: find.text('Soon')),
          findsOneWidget);
    });

    testWidgets('no interaction with an à-la-carte skin can say "Purchased"',
        (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(WardrobeTile, 'Obsidian & Gold'));
      await tester.pump(const Duration(milliseconds: 100));
      // Tap the teaser copy itself — the only thing the bar renders.
      await tester.tap(find.text('Coming soon'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Purchased'), findsNothing);
    });
  });

  test('the screen source carries no purchase-success claim', () {
    // Belt-and-braces on the invariant above: the deceptive message and the
    // re-sync-as-purchase call are both gone from the UI. If the real RC
    // purchase is ever wired, this test SHOULD fail and be rewritten to assert
    // that purchasePackage runs first.
    // Comments are stripped: the TODO deliberately NAMES the call that has to
    // be wired, and that mention must not read as the call itself.
    final code = File('lib/features/streaks/screens/wardrobe_screen.dart')
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(code, isNot(contains("'Purchased'")));
    expect(code, isNot(contains('completeSkinIapPurchase(')));
    expect(code, isNot(contains(r'$2.99')));
  });
}
