// The Companion stage screen: equipped backdrop + live equipped-skin medallion,
// the Noor chip, and the entry points (Customize → wardrobe, share).
//
// DB-free: cosmeticsStateProvider and companionStateProvider are both
// overridden, so nothing touches Supabase / SharedPreferences / RevenueCat.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/providers/companion_inputs_provider.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/screens/companion_screen.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_name_sheet.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_share_card.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/noor_balance_chip.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _StubPurchaseService extends PurchaseService {
  _StubPurchaseService(this.premium) : super.test();
  final bool premium;
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  // CompanionStage / CompanionMedallion both wrap a VisibilityDetector whose
  // default 500ms debounce would outlive the test tree.
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    PurchaseService.debugSetOverride(_StubPurchaseService(false));
  });

  tearDown(PurchaseService.debugClearOverride);

  Widget harness({
    String equippedSkin = 'emerald_jade',
    String equippedBackdrop = 'laylat_night',
    Set<String> ownedSkins = const {'emerald_jade'},
    Set<String> ownedBackdrops = const {'laylat_night'},
  }) =>
      ProviderScope(
        overrides: [
          companionStateProvider.overrideWith((ref) => const CompanionState(
              brightness: CompanionBrightness.glowing, protected: false)),
          companionStreakProvider.overrideWith((ref) => 12),
          cosmeticsStateProvider.overrideWith((ref) async => CosmeticsState(
                noorBalance: 130,
                equippedLanternSkin: equippedSkin,
                equippedBackdrop: equippedBackdrop,
                ownedLanternSkins: ownedSkins,
                ownedBackdrops: ownedBackdrops,
              )),
        ],
        child: const MaterialApp(home: CompanionScreen()),
      );

  testWidgets('renders the stage, Noor chip, and Customize entry',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CompanionStage), findsOneWidget);
    expect(find.byType(NoorBalanceChip), findsOneWidget);
    expect(find.text('130'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
  });

  testWidgets(
      'DEP-D2: an equipped-but-unowned skin falls back to classic gold',
      (tester) async {
    await tester.pumpWidget(harness(
      equippedSkin: 'ramadan_royal', // premium-exclusive, premium lapsed
      ownedSkins: const {},
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, defaultLanternSkin);
  });

  // I2: premium-exclusive skins are NEVER written to the owned set (the perk
  // lasts only while the subscription does), so gating the RENDER on ownership
  // alone fired the lapse fallback for ACTIVE subscribers too — a paying user
  // who equipped Ramadan Royal saw a Classic Brass lantern.
  testWidgets('an ACTIVE subscriber sees their equipped premium-exclusive skin',
      (tester) async {
    PurchaseService.debugSetOverride(_StubPurchaseService(true));

    await tester.pumpWidget(harness(
      equippedSkin: 'ramadan_royal',
      ownedSkins: const {}, // correct: never converts to ownership
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, 'ramadan_royal');
  });

  testWidgets('premium does NOT render an ordinary unowned skin',
      (tester) async {
    PurchaseService.debugSetOverride(_StubPurchaseService(true));

    await tester.pumpWidget(harness(
      equippedSkin: 'emerald_jade', // not premium-exclusive, not owned
      ownedSkins: const {},
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final medallion =
        tester.widget<CompanionMedallion>(find.byType(CompanionMedallion));
    expect(medallion.skin.id, defaultLanternSkin);
  });

  testWidgets('E3: the lantern name defaults and opens the rename sheet',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    // Prefs are unavailable in this harness — the read must degrade to the
    // default rather than take the stage down.
    expect(find.text(defaultLanternName), findsOneWidget);

    // The stage animates forever, so settle explicitly rather than pumpAndSettle.
    await tester.tap(find.text(defaultLanternName));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Name your lantern'), findsOneWidget);
  });

  testWidgets('E1: share hands off the equipped ids, the name, and the streak',
      (tester) async {
    Map<String, Object?>? captured;
    final original = shareLanternCard;
    shareLanternCard = ({
      required BuildContext context,
      required String skinId,
      required String backdropId,
      required String lanternName,
      int streak = 0,
    }) async {
      captured = {
        'skinId': skinId,
        'backdropId': backdropId,
        'lanternName': lanternName,
        'streak': streak,
      };
    };
    addTearDown(() => shareLanternCard = original);

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.share_rounded));
    await tester.pump();

    expect(captured, {
      'skinId': 'emerald_jade',
      'backdropId': 'laylat_night',
      'lanternName': defaultLanternName,
      'streak': 12,
    });
  });
}
