import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/services/economy_events.dart';

void main() {
  tearDown(() async {
    await EconomyEvents.resetForTest();
  });

  testWidgets(
      'tierUpScrollProvider value is identical across two simultaneously-mounted screens',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: const Row(children: [
          _ScrollPillProbe(testKey: Key('a')),
          _ScrollPillProbe(testKey: Key('b')),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    EconomyEvents.publish(const ScrollGranted(
      amount: 5,
      newBalance: 42,
      source: EconomyEventSource.iap,
    ));
    // Broadcast streams deliver on the next microtask/event-loop turn.
    await tester.pump(Duration.zero);
    await tester.pump();

    expect(find.text('42').evaluate().length, 2,
        reason: 'Both probes must reflect the same balance');
  });
}

class _ScrollPillProbe extends ConsumerWidget {
  const _ScrollPillProbe({required this.testKey});
  final Key testKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(tierUpScrollProvider).balance;
    return Text('$balance', key: testKey);
  }
}
