import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

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

  test('earnTierUpScrolls publishes ScrollGranted with source on success',
      () async {
    final received = <EconomyEvent>[];
    final sub = EconomyEvents.stream.listen(received.add);
    addTearDown(sub.cancel);

    final result = await earnTierUpScrolls(3,
        source: EconomyEventSource.firstSteps);

    expect(result.success, true);
    expect(result.newBalance, 3); // initial cache is 0
    await Future<void>.delayed(Duration.zero);

    final event = received.single as ScrollGranted;
    expect(event.amount, 3);
    expect(event.newBalance, 3);
    expect(event.source, EconomyEventSource.firstSteps);
  });
}
