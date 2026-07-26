// I5 — the previewed item's equip gate must belong to the item on screen, and
// the grid badges and the action button must read the SAME premium snapshot.
//
// Two defects this pins:
//   1. `_equippable` was one shared bool written by unordered futures. Tapping a
//      premium-exclusive tile (slow premium read) and then a locked Noor tile
//      let the FIRST future resolve last and offer "Equip" for the Noor item.
//   2. `_isPremium` was resolved once in initState and never refreshed, so a
//      mid-session entitlement change left the tile badge and the action button
//      disagreeing about entitlement.
//
// DB-free: cosmeticsStateProvider is overridden, the sync service is the fake,
// and PurchaseService is stubbed with a hand-driven premium read.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../support/fake_supabase_sync_service.dart';

/// Every `isPremium()` read is parked on its own completer, so the test decides
/// the completion ORDER — which is the whole point of case 1.
class _ManualPurchaseService extends PurchaseService {
  _ManualPurchaseService() : super.test();

  final List<Completer<bool>> pending = [];

  @override
  Future<bool> isPremium() {
    final c = Completer<bool>();
    pending.add(c);
    return c.future;
  }
}

/// Resolves immediately with whatever [premium] currently holds — used for the
/// mid-session entitlement flip.
class _FlippablePurchaseService extends PurchaseService {
  _FlippablePurchaseService(this.premium) : super.test();
  bool premium;
  int reads = 0;

  @override
  Future<bool> isPremium() async {
    reads++;
    return premium;
  }
}

void main() {
  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'u1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    CosmeticsAnalytics.onAnalyticsEvent = (_, __) {};
  });

  tearDown(() {
    CosmeticsAnalytics.onAnalyticsEvent = null;
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
  });

  Widget harness() => ProviderScope(
        overrides: [
          cosmeticsStateProvider
              .overrideWith((ref) async => const CosmeticsState(
                    noorBalance: 130,
                    equippedLanternSkin: defaultLanternSkin,
                    equippedBackdrop: defaultBackdrop,
                    ownedLanternSkins: {},
                    ownedBackdrops: {},
                  )),
        ],
        child: const MaterialApp(home: WardrobeScreen()),
      );

  /// Tall enough that Ramadan Royal (sort 7, the premium-exclusive row) lays out.
  Future<void> tallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets(
      'a slow premium read cannot offer Equip for a later-previewed Noor item',
      (tester) async {
    final purchases = _ManualPurchaseService();
    PurchaseService.debugSetOverride(purchases);

    await tallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    // The screen's own premium snapshot: not premium.
    expect(purchases.pending, isNotEmpty);
    purchases.pending.first.complete(false);
    await tester.pump(const Duration(milliseconds: 100));
    final afterOpen = purchases.pending.length;

    // Tap the premium-exclusive tile first — its gate parks on a slow read.
    await tester.tap(find.widgetWithText(WardrobeTile, 'Ramadan Royal'));
    await tester.pump(const Duration(milliseconds: 100));

    // Then immediately a plain locked Noor tile, whose gate resolves at once.
    await tester.tap(find.widgetWithText(WardrobeTile, 'Emerald Jade'));
    await tester.pump(const Duration(milliseconds: 100));

    // The stale premium read lands LAST, carrying the other tile's answer.
    for (final c in purchases.pending.skip(afterOpen)) {
      if (!c.isCompleted) c.complete(true);
    }
    await tester.pump(const Duration(milliseconds: 100));

    // Emerald Jade is unowned and not premium-exclusive: it is a Noor unlock,
    // never an Equip.
    expect(find.text('Unlock · 120 Noor'), findsOneWidget);
    expect(find.text('Equip'), findsNothing);
  });

  testWidgets('a mid-session entitlement change refreshes the tile badges',
      (tester) async {
    final purchases = _FlippablePurchaseService(false);
    PurchaseService.debugSetOverride(purchases);
    // The equip the test performs must succeed so the screen re-reads state.
    fakeSync.rpcHandlers['equip_cosmetic'] = (_) => true;

    await tallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    final royal = find.widgetWithText(WardrobeTile, 'Ramadan Royal');
    expect(find.descendant(of: royal, matching: find.text('Premium')),
        findsOneWidget);

    // The user subscribes elsewhere in the app (or a gift/referral lands).
    purchases.premium = true;

    // Equip the always-owned default — a successful mutation re-reads state.
    await tester.tap(find.widgetWithText(WardrobeTile, 'Classic Brass'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Equip'));
    await tester.pump(const Duration(milliseconds: 200));

    // The badge must track the refreshed snapshot: the skin is equippable now,
    // so the "Premium" lock badge is gone.
    expect(find.descendant(of: royal, matching: find.text('Premium')),
        findsNothing);
  });
}
