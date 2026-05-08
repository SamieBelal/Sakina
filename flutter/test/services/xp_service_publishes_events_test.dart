import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // userId: null → no supabase login → local-cache path
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: null));
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    await EconomyEvents.resetForTest();
  });

  test('awardXp publishes XpGranted with source on success (no auth)', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    // No supabase login → falls through to local-cache path.
    final result = await awardXp(80, source: EconomyEventSource.quest);

    expect(result.gained, 80);
    expect(result.newTotal, 80);
    expect(result.leveledUp, true); // crosses L1→L2 at 75 XP
    await Future<void>.delayed(Duration.zero);

    final event = received.single as XpGranted;
    expect(event.amount, 80);
    expect(event.newTotal, 80);
    expect(event.leveledUp, true);
    expect(event.source, EconomyEventSource.quest);
  });

  test('awardXp with amount=0 still publishes (pin behavior)', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    await awardXp(0, source: EconomyEventSource.dev);
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect((received.single as XpGranted).amount, 0);
  });
}
