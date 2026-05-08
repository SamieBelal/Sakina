// test/services/economy_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/xp_service.dart';

void main() {
  tearDown(() async {
    await EconomyEvents.resetForTest();
  });

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

  test(
      'resetForTest closes the stream and prevents pre-reset subscribers '
      'from receiving subsequent events', () async {
    // 1. Subscribe to the live stream and capture both data + done signals.
    final received = <EconomyEvent>[];
    var doneFired = false;
    final sub = EconomyEvents.stream.listen(
      received.add,
      onDone: () => doneFired = true,
    );

    // Sanity: a publish before reset reaches the subscriber.
    EconomyEvents.publish(const TokenGranted(
      amount: 1, newBalance: 1, source: EconomyEventSource.dev,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(received, hasLength(1));

    // 2. Reset — this must close the underlying controller, sending a `done`
    //    event to the existing subscriber.
    await EconomyEvents.resetForTest();
    // Allow the done signal to propagate.
    await Future<void>.delayed(Duration.zero);
    expect(doneFired, isTrue,
        reason: 'resetForTest must close the controller, surfacing onDone '
            'to all live subscribers from the previous test.');

    // 3. Publishing after reset goes to the NEW controller. The old
    //    subscription must NOT receive it.
    EconomyEvents.publish(const TokenGranted(
      amount: 999, newBalance: 999, source: EconomyEventSource.dev,
    ));
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1),
        reason: 'old subscriber must not see events published after reset — '
            'this is the cross-test isolation guarantee.');

    // Cancel the old (closed) subscription cleanly.
    await sub.cancel();

    // 4. Fresh subscribers on the new controller work as expected.
    final freshReceived = <EconomyEvent>[];
    final freshSub = EconomyEvents.stream.listen(freshReceived.add);
    addTearDown(freshSub.cancel);

    EconomyEvents.publish(const TokenGranted(
      amount: 7, newBalance: 7, source: EconomyEventSource.dev,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(freshReceived, hasLength(1),
        reason: 'fresh subscriber on the rebuilt controller must receive '
            'events normally.');
  });
}
