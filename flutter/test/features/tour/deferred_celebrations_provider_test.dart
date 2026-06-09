import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/tour/providers/deferred_celebrations_provider.dart';

void main() {
  Quest fakeQuest(String id) => Quest(
        id: id,
        cadence: QuestCadence.daily,
        title: id,
        description: '',
        icon: Icons.star,
        xpReward: 10,
        poolIndex: 0,
      );

  test('enqueue preserves FIFO order', () {
    final n = DeferredCelebrationsNotifier();
    n.enqueue(QuestToastCelebration(fakeQuest('a')));
    n.enqueue(const FirstStepsCelebration(tokens: 1, scrolls: 2));
    n.enqueue(QuestToastCelebration(fakeQuest('b')));

    expect(n.state.length, 3);
    expect((n.state[0] as QuestToastCelebration).quest.id, 'a');
    expect(n.state[1], isA<FirstStepsCelebration>());
    expect((n.state[2] as QuestToastCelebration).quest.id, 'b');
  });

  test('takeAll returns all items and clears the queue', () {
    final n = DeferredCelebrationsNotifier();
    n.enqueue(QuestToastCelebration(fakeQuest('a')));
    n.enqueue(QuestToastCelebration(fakeQuest('b')));

    final taken = n.takeAll();
    expect(taken.length, 2);
    expect(n.state, isEmpty);

    // A second drain finds nothing — no double-presentation.
    expect(n.takeAll(), isEmpty);
  });

  test('takeAll on an empty queue is a no-op', () {
    final n = DeferredCelebrationsNotifier();
    expect(n.takeAll(), isEmpty);
    expect(n.state, isEmpty);
  });
}
