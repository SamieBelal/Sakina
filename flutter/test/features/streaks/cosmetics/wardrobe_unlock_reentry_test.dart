// I6 — a second Unlock tap while the first is in flight must do nothing.
//
// The SERVER is idempotent (a replayed `unlock_cosmetic` charges nothing), but
// `unlockCosmetic` mirrors the debit into the local cache unconditionally on
// `true`. Two in-flight unlocks therefore debited the displayed balance twice
// and stacked two reveal overlays, leaving the user N Noor "poorer" than they
// are until the next full sync — enough to make an affordable item read as
// unaffordable. The build-time `state.owns(...)` guard cannot catch this: the
// in-flight `ref.invalidate` has not refreshed it yet.
//
// DB-free: the RPC is parked on a completer inside the fake sync service, so
// the test controls exactly how long "in flight" lasts.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/wardrobe_screen.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_unlock_reveal.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
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
  late FakeSupabaseSyncService fakeSync;
  late Completer<bool> rpcGate;
  late List<String> reveals;
  final defaultReveal = showCosmeticUnlockReveal;

  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({'sakina_noor_balance:u1': 130});
    // Warm the singleton HERE, in real async: inside a pumped widget test the
    // first `getInstance()` never resolves, and the unlock chain hangs on it.
    await SharedPreferences.getInstance();
    fakeSync = FakeSupabaseSyncService(userId: 'u1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_StubPurchaseService());
    CosmeticsAnalytics.onAnalyticsEvent = (_, __) {};

    fakeSync.rpcHandlers['unlock_cosmetic'] = (_) => rpcGate.future;

    reveals = [];
    showCosmeticUnlockReveal = (context, itemType, itemId) async {
      reveals.add('$itemType/$itemId');
    };
  });

  tearDown(() {
    showCosmeticUnlockReveal = defaultReveal;
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

  int unlockRpcCount() =>
      fakeSync.rpcCalls.where((c) => c['fn'] == 'unlock_cosmetic').length;

  testWidgets('a second Unlock tap in flight neither re-charges nor re-reveals',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Created INSIDE the test body: a Completer captures the zone it is built
    // in, and one built in setUp resolves on the real event loop, which
    // `tester.pump` (fake async) never turns.
    rpcGate = Completer<bool>();

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(WardrobeTile, 'Emerald Jade'));
    await tester.pump(const Duration(milliseconds: 100));

    final unlockButton = find.widgetWithText(FilledButton, 'Unlock · 120 Noor');
    expect(unlockButton, findsOneWidget);

    await tester.tap(unlockButton);
    await tester.pump();

    // While the RPC is in flight the CTA must be inert — both by being disabled
    // and by refusing re-entry if it is somehow tapped anyway.
    expect(tester.widget<FilledButton>(unlockButton).onPressed, isNull);
    await tester.tap(unlockButton, warnIfMissed: false);
    await tester.pump();

    rpcGate.complete(true);
    // Several frames: the unlock chain hops through SharedPreferences and the
    // provider invalidation before the reveal is presented.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(unlockRpcCount(), 1);
    expect(reveals, ['$itemTypeLanternSkin/emerald_jade']);

    // The mirrored debit landed exactly once: 130 − 120.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('sakina_noor_balance:u1'), 10);
  });
}
