import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-1'),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test('hydrateCosmeticsFromBatchPayload writes all three sections', () async {
    final payload = UserDataBatchPayload.fromRpc({
      'noor': {'balance': 320, 'total_earned': 500, 'total_spent': 180},
      'equipped': {'lantern_skin': 'emerald_jade', 'backdrop': 'laylat_night'},
      'cosmetics': [
        {
          'item_type': 'lantern_skin',
          'item_id': 'emerald_jade',
          'acquired_via': 'milestone'
        },
        {
          'item_type': 'backdrop',
          'item_id': 'laylat_night',
          'acquired_via': 'noor'
        },
      ],
    });

    await hydrateCosmeticsFromBatchPayload(payload);

    final state = await getCosmeticsState();
    expect(state.noorBalance, 320);
    expect(state.equippedLanternSkin, 'emerald_jade');
    expect(state.equippedBackdrop, 'laylat_night');
    expect(state.owns('lantern_skin', 'emerald_jade'), isTrue);
    expect(state.owns('backdrop', 'laylat_night'), isTrue);
  });

  test('missing cosmetics sections (pre-cosmetics server) leave defaults',
      () async {
    final payload = UserDataBatchPayload.fromRpc({
      'xp': {'total_xp': 0},
    });

    await hydrateCosmeticsFromBatchPayload(payload);

    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.equippedBackdrop, 'default');
    expect(state.ownedLanternSkins, isEmpty);
  });

  test('present-but-null column values coalesce to defaults', () async {
    // A server that ships the sections but with SQL-NULL columns (e.g. the
    // user_profiles row exists but noor_balance / equipped_* are NULL) must
    // coalesce to 0 / classic_gold / default rather than crashing on the
    // non-nullable hydrateCosmeticsFromSync signature.
    final payload = UserDataBatchPayload.fromRpc({
      'noor': {'balance': null},
      'equipped': {'lantern_skin': null, 'backdrop': null},
      'cosmetics': null,
    });

    await hydrateCosmeticsFromBatchPayload(payload);

    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.equippedBackdrop, 'default');
    expect(state.ownedLanternSkins, isEmpty);
    expect(state.ownedBackdrops, isEmpty);
  });
}
