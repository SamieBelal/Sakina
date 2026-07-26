import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_action_bar.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('equippable → Equip button fires onEquip', (tester) async {
    var equipped = false;
    await tester.pumpWidget(host(WardrobeActionBar(
      action: WardrobeAction.equip,
      priceLabel: null,
      onEquip: () => equipped = true,
      onUnlock: () {},
      onBuy: () {},
    )));
    expect(find.text('Equip'), findsOneWidget);
    await tester.tap(find.text('Equip'));
    expect(equipped, isTrue);
  });

  testWidgets('unlockable shows the Noor price and fires onUnlock',
      (tester) async {
    var unlocked = false;
    await tester.pumpWidget(host(WardrobeActionBar(
      action: WardrobeAction.unlock,
      priceLabel: '120 Noor',
      onEquip: () {},
      onUnlock: () => unlocked = true,
      onBuy: () {},
    )));
    expect(find.text('Unlock · 120 Noor'), findsOneWidget);
    await tester.tap(find.textContaining('Unlock'));
    expect(unlocked, isTrue);
  });

  testWidgets('unaffordable unlock is disabled', (tester) async {
    await tester.pumpWidget(host(WardrobeActionBar(
      action: WardrobeAction.unlockUnaffordable,
      priceLabel: '300 Noor',
      onEquip: () {},
      onUnlock: () {},
      onBuy: () {},
    )));
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('à-la-carte shows Get and fires onBuy', (tester) async {
    var bought = false;
    await tester.pumpWidget(host(WardrobeActionBar(
      action: WardrobeAction.buy,
      priceLabel: r'$2.99',
      onEquip: () {},
      onUnlock: () {},
      onBuy: () => bought = true,
    )));
    expect(find.text(r'Get · $2.99'), findsOneWidget);
    await tester.tap(find.textContaining('Get'));
    expect(bought, isTrue);
  });

  testWidgets('premium-locked shows a teaser and no button', (tester) async {
    await tester.pumpWidget(host(WardrobeActionBar(
      action: WardrobeAction.premiumTeaser,
      priceLabel: null,
      teaser: 'Premium · this month',
      onEquip: () {},
      onUnlock: () {},
      onBuy: () {},
    )));
    expect(find.text('Premium · this month'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  // Milestone-gated items read as visible-but-locked with the streak hint —
  // never as a purchasable action.
  testWidgets('milestone-locked shows the streak hint and no button',
      (tester) async {
    await tester.pumpWidget(host(WardrobeActionBar(
      action: WardrobeAction.milestoneTeaser,
      priceLabel: null,
      teaser: 'Unlock at a 30-day streak',
      onEquip: () {},
      onUnlock: () {},
      onBuy: () {},
    )));
    expect(find.text('Unlock at a 30-day streak'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
