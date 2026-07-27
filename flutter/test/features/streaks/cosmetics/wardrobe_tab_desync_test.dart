// I4 — the wardrobe's transient preview state must not outlive the screen.
//
// The bug: `wardrobePreviewProvider` was app-scoped, so leaving the wardrobe on
// the Backdrops tab and reopening it produced a VISIBLE desync — a fresh
// TabController starts at index 0 (TabBar underlines "Lanterns") while the body
// read `preview.tab == 'backdrop'` and rendered the backdrop grid. Tapping
// "Lanterns" changed nothing (the index was already 0), so the user was stuck.
// A stale `previewedSkinId` leaked the same way: a previously-previewed LOCKED
// skin came back on the stage as if it were equipped.
//
// The invariant pinned here: the TabBar's selected index and the grid the body
// renders are sourced from the SAME state, and that state does not survive the
// screen.
//
// DB-free: cosmeticsStateProvider is overridden, the sync service is the fake,
// and PurchaseService is stubbed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_preview_stage.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tab_pills.dart';
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
  /// Drives the screen in and out of the tree WITHOUT replacing the
  /// ProviderScope — otherwise the scope teardown would mask the leak the test
  /// exists to catch.
  final mounted = ValueNotifier<bool>(true);

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    PurchaseService.debugSetOverride(_StubPurchaseService(false));
    CosmeticsAnalytics.onAnalyticsEvent = (_, __) {};
    mounted.value = true;
  });

  tearDown(() {
    CosmeticsAnalytics.onAnalyticsEvent = null;
    PurchaseService.debugClearOverride();
    SupabaseSyncService.debugReset();
  });

  Widget harness() => ProviderScope(
        overrides: [
          cosmeticsStateProvider.overrideWith((ref) async => const CosmeticsState(
                noorBalance: 130,
                equippedLanternSkin: defaultLanternSkin,
                equippedBackdrop: defaultBackdrop,
                ownedLanternSkins: {},
                ownedBackdrops: {},
              )),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: mounted,
            builder: (_, show, __) =>
                show ? const WardrobeScreen() : const SizedBox.shrink(),
          ),
        ),
      );

  Future<void> phoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> reopen(WidgetTester tester) async {
    mounted.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    mounted.value = true;
    // Two frames: cosmeticsStateProvider is autoDispose too, so a reopened
    // screen genuinely re-resolves rather than replaying a cached value.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // Reads the SELECTOR's own idea of the current tab. The wardrobe swapped its
  // Material `TabBar` for `WardrobeTabPills` (the rule across the screen was a
  // hard dark line, and the tab underline read as utilitarian on this surface).
  // The invariant this file pins is unchanged — the selector and the grid must
  // never disagree — only the widget it is read from moved.
  int selectedTabIndex(WidgetTester tester) =>
      tester.widget<WardrobeTabPills>(find.byType(WardrobeTabPills)).index;

  testWidgets('reopening cannot leave the selector and the grid disagreeing',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Backdrops'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Laylat Night'), findsOneWidget); // backdrop grid is up
    expect(selectedTabIndex(tester), 1);

    await reopen(tester);

    // Whatever the tab resolves to, the underline and the body must agree.
    if (selectedTabIndex(tester) == 0) {
      expect(find.text('Emerald Jade'), findsOneWidget);
      expect(find.text('Laylat Night'), findsNothing);
    } else {
      expect(find.text('Laylat Night'), findsOneWidget);
      expect(find.text('Emerald Jade'), findsNothing);
    }
  });

  testWidgets('a previewed locked skin does not come back on the stage',
      (tester) async {
    await phoneSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Rose Quartz'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<WardrobePreviewStage>(find.byType(WardrobePreviewStage))
          .skinId,
      'rose_quartz',
    );

    await reopen(tester);

    // Unowned and unequipped — the stage must be back to the equipped skin.
    expect(
      tester.widget<WardrobePreviewStage>(find.byType(WardrobePreviewStage))
          .skinId,
      defaultLanternSkin,
    );
  });
}
