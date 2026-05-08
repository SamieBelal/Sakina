import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';

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

  test('earnTokens publishes TokenGranted with source on success', () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final result = await earnTokens(7, source: EconomyEventSource.quest);

    expect(result.balance, startingTokens + 7);
    await Future<void>.delayed(Duration.zero);

    final event = received.single as TokenGranted;
    expect(event.amount, 7);
    expect(event.newBalance, startingTokens + 7);
    expect(event.source, EconomyEventSource.quest);
  });
}
