import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/noor_balance_chip.dart';

void main() {
  testWidgets('renders the balance with the Noor label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: NoorBalanceChip(balance: 240))),
    ));
    expect(find.text('240'), findsOneWidget);
    expect(find.bySemanticsLabel('Noor balance: 240'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the on-canvas variant renders the same balance', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: NoorBalanceChip(balance: 0, onCanvas: true)),
      ),
    ));
    expect(find.text('0'), findsOneWidget);
  });
}
