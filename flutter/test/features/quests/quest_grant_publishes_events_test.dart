// Pins that `completeQuest` publishes XpGranted and TokenGranted events with
// source == EconomyEventSource.quest (not the default `dev`).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-test');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['award_xp'] = (params) async =>
        <String, dynamic>{'total_xp': 100, 'token_balance': 0};
    fakeSync.rpcHandlers['earn_tokens'] = (_) async => 10;
    fakeSync.rpcHandlers['earn_scrolls'] = (_) async => 1;
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    await EconomyEvents.resetForTest();
  });

  test(
      'completing a daily quest publishes XpGranted + TokenGranted with source=quest',
      () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final notifier = QuestsNotifier();
    addTearDown(notifier.dispose);

    // Await reload() so _load() is fully settled and daily quests populated.
    await notifier.reload();

    final daily = notifier.state.daily;
    expect(daily, isNotEmpty);
    final quest = daily.first;

    await notifier.completeQuest(quest.id);
    // Flush any microtasks so stream events land in `received`.
    await Future<void>.delayed(Duration.zero);

    final xpEvents = received.whereType<XpGranted>().toList();
    final tokenEvents = received.whereType<TokenGranted>().toList();

    expect(xpEvents, hasLength(1));
    expect(xpEvents.single.amount, quest.xpReward);
    expect(xpEvents.single.source, EconomyEventSource.quest);

    if (quest.tokenReward > 0) {
      expect(tokenEvents, hasLength(1));
      expect(tokenEvents.single.source, EconomyEventSource.quest);
    }
  });
}
