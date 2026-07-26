import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('fresh user reads defaults: 0 noor, classic_gold + default equipped, '
      'no owned', () async {
    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.equippedBackdrop, 'default');
    expect(state.ownedLanternSkins, isEmpty);
    expect(state.ownedBackdrops, isEmpty);
    expect(state.owns('lantern_skin', 'moonlit_silver'), isFalse);
  });

  test('hydrateCosmeticsFromSync writes balance, equipped, and owned caches',
      () async {
    await hydrateCosmeticsFromSync(
      noorBalance: 240,
      equippedLanternSkin: 'emerald_jade',
      equippedBackdrop: 'laylat_night',
      owned: const [
        {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'},
        {'item_type': 'lantern_skin', 'item_id': 'moonlit_silver'},
        {'item_type': 'backdrop', 'item_id': 'laylat_night'},
      ],
    );

    final state = await getCosmeticsState();
    expect(state.noorBalance, 240);
    expect(state.equippedLanternSkin, 'emerald_jade');
    expect(state.equippedBackdrop, 'laylat_night');
    expect(state.ownedLanternSkins,
        containsAll(<String>['emerald_jade', 'moonlit_silver']));
    expect(state.ownedBackdrops, contains('laylat_night'));
    expect(state.owns('lantern_skin', 'moonlit_silver'), isTrue);
    expect(state.owns('backdrop', 'emerald_sanctuary'), isFalse);
  });

  test('hydration is scoped per user (no cross-account bleed)', () async {
    await hydrateCosmeticsFromSync(
      noorBalance: 500,
      equippedLanternSkin: 'obsidian_gold',
      equippedBackdrop: 'default',
      owned: const [
        {'item_type': 'lantern_skin', 'item_id': 'obsidian_gold'},
      ],
    );

    // Switch to a different user — caches must not carry over.
    fakeSync.userId = 'user-2';
    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.ownedLanternSkins, isEmpty);
  });
}
