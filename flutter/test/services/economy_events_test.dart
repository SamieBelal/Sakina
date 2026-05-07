// test/services/economy_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/xp_service.dart';

void main() {
  test('publish delivers events to subscribers in order', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    EconomyEvents.publish(const TokenGranted(
      amount: 5, newBalance: 55, source: EconomyEventSource.quest,
    ));
    EconomyEvents.publish(const ScrollGranted(
      amount: 2, newBalance: 12, source: EconomyEventSource.firstSteps,
    ));

    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(2));
    expect(received[0], isA<TokenGranted>());
    expect((received[0] as TokenGranted).newBalance, 55);
    expect(received[1], isA<ScrollGranted>());
    expect((received[1] as ScrollGranted).newBalance, 12);
  });

  test('XpGranted carries leveledUp + rewards through publish', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    const state = XpState(
      totalXp: 400, level: 5, title: 'Grateful', titleArabic: 'شَاكِر',
      xpForNextLevel: 70, xpIntoCurrentLevel: 25,
    );
    EconomyEvents.publish(const XpGranted(
      amount: 25,
      newTotal: 400,
      newState: state,
      leveledUp: true,
      rewards: LevelUpRewards(
        levelsGained: 1, tokensAwarded: 5, scrollsAwarded: 2,
        titleUnlocked: true, unlockedTitle: 'Grateful',
        unlockedTitleArabic: 'شَاكِر',
      ),
      source: EconomyEventSource.quest,
    ));

    await Future<void>.delayed(Duration.zero);
    final event = received.single as XpGranted;
    expect(event.leveledUp, true);
    expect(event.rewards?.tokensAwarded, 5);
    expect(event.newState.level, 5);
  });
}
