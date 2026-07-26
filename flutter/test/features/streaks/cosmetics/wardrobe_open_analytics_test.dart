// I9 — `wardrobe_opened` counts OPENS, not tab taps.
//
// `_onTabChanged` re-emitted the same event as `initState`, so every axis
// switch inflated the open count and understated open → preview → unlock — the
// exact funnel this feature would be judged on. Tab switching is now its own
// event, so the open count stays clean and the axis remains queryable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../support/fake_supabase_sync_service.dart';

class _StubPurchaseService extends PurchaseService {
  _StubPurchaseService() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  final events = <(String, Map<String, dynamic>)>[];

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    PurchaseService.debugSetOverride(_StubPurchaseService());
    events.clear();
    CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
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

  Iterable<Map<String, dynamic>> propsFor(String name) =>
      events.where((e) => e.$1 == name).map((e) => e.$2);

  test('the tab-change event name is the pinned Mixpanel string', () {
    expect(AnalyticsEvents.wardrobeTabChanged, 'wardrobe_tab_changed');
  });

  testWidgets('switching axes does not re-count the open', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));
    expect(propsFor(AnalyticsEvents.wardrobeOpened), hasLength(1));

    await tester.tap(find.text('Backdrops'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Lanterns'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Still one open — the two switches are their own event, carrying the axis.
    expect(propsFor(AnalyticsEvents.wardrobeOpened), hasLength(1));
    expect(
      propsFor(AnalyticsEvents.wardrobeTabChanged)
          .map((p) => p[AnalyticsEvents.propTab])
          .toList(),
      [itemTypeBackdrop, itemTypeLanternSkin],
    );
  });
}
