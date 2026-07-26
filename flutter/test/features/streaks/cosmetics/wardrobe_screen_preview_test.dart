// Wardrobe screen: two axes, a live preview stage, and the preview analytics.
//
// DB-free: cosmeticsStateProvider is overridden, the sync service is the fake,
// and PurchaseService is stubbed — nothing reaches Supabase or RevenueCat.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_preview_stage.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:sakina/services/analytics_event_names.dart';
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

void main() {
  final events = <String>[];

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    PurchaseService.debugSetOverride(_StubPurchaseService(false));
    events.clear();
    CosmeticsAnalytics.onAnalyticsEvent = (e, _) => events.add(e);
  });

  tearDown(() {
    CosmeticsAnalytics.onAnalyticsEvent = null;
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
  });

  Widget harness({String equippedSkin = 'classic_gold'}) => ProviderScope(
        overrides: [
          cosmeticsStateProvider.overrideWith((ref) async => CosmeticsState(
                noorBalance: 130,
                equippedLanternSkin: equippedSkin,
                equippedBackdrop: 'default',
                ownedLanternSkins: const {},
                ownedBackdrops: const {},
              )),
        ],
        child: const MaterialApp(home: WardrobeScreen()),
      );

  /// A phone-shaped surface so the second grid row is actually laid out (the
  /// 800x600 default fits barely one row of 2-up tiles).
  Future<void> phoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  /// Tall enough that the last grid row (Ramadan Royal, sort 7) is laid out.
  Future<void> tallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('opens on the lantern tab and emits wardrobe_opened',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CompanionStage), findsOneWidget); // live preview
    expect(find.text('Lanterns'), findsOneWidget);
    expect(find.text('Backdrops'), findsOneWidget);
    expect(events, contains(AnalyticsEvents.wardrobeOpened));
  });

  testWidgets('tapping a tile previews it and emits cosmetic_previewed',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(WardrobeTile, 'Emerald Jade'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(events, contains(AnalyticsEvents.cosmeticPreviewed));
    final tile = tester.widget<WardrobeTile>(
        find.widgetWithText(WardrobeTile, 'Emerald Jade'));
    expect(tile.selected, isTrue);
  });

  testWidgets('an affordable unowned skin offers Unlock at its Noor price',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(WardrobeTile, 'Emerald Jade'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Unlock · 120 Noor'), findsOneWidget);
  });

  // I2: the preview stage and the tile badge must agree with each other AND
  // with entitlement — a premium-exclusive skin is never in the owned set, so
  // ownership alone is the wrong render gate.
  group('an equipped premium-exclusive skin', () {
    testWidgets('renders on the stage and reads equipped for an ACTIVE sub',
        (tester) async {
      PurchaseService.debugSetOverride(_StubPurchaseService(true));
      await tallSurface(tester);
      await tester.pumpWidget(harness(equippedSkin: 'ramadan_royal'));
      await tester.pump(const Duration(milliseconds: 100));

      final stage = tester.widget<WardrobePreviewStage>(
          find.byType(WardrobePreviewStage));
      expect(stage.skinId, 'ramadan_royal');

      final tile = find.widgetWithText(WardrobeTile, 'Ramadan Royal');
      expect(
          find.descendant(of: tile, matching: find.text('Equipped')),
          findsOneWidget);
    });

    testWidgets('falls back to classic and drops the badge once premium lapses',
        (tester) async {
      PurchaseService.debugSetOverride(_StubPurchaseService(false));
      await tallSurface(tester);
      await tester.pumpWidget(harness(equippedSkin: 'ramadan_royal'));
      await tester.pump(const Duration(milliseconds: 100));

      final stage = tester.widget<WardrobePreviewStage>(
          find.byType(WardrobePreviewStage));
      expect(stage.skinId, defaultLanternSkin);

      final tile = find.widgetWithText(WardrobeTile, 'Ramadan Royal');
      expect(find.descendant(of: tile, matching: find.text('Equipped')),
          findsNothing);
      expect(find.descendant(of: tile, matching: find.text('Premium')),
          findsOneWidget);
    });
  });
}
