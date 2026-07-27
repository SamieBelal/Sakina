// I8 — the resolved CosmeticsState must not outlive the user it belongs to.
//
// `cosmeticsStateProvider` was app-scoped and non-autoDispose, and only the
// wardrobe's own mutations ever invalidated it. After a same-session sign-out →
// sign-in, opening /companion served the PREVIOUS user's cached resolution:
// their Noor balance and their equipped lantern.
//
// The underlying prefs ARE user-scoped (`SupabaseSyncService.scopedKey`), so
// this is display staleness rather than a data leak — but a returning user
// seeing someone else's balance is indistinguishable from one, and equipping
// from that screen acts on the wrong assumptions.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'sakina_noor_balance:u1': 500,
      'sakina_equipped_lantern_skin:u1': 'emerald_jade',
      'sakina_noor_balance:u2': 20,
      'sakina_equipped_lantern_skin:u2': 'moonlit_silver',
    });
    fakeSync = FakeSupabaseSyncService(userId: 'u1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('a same-session user switch is not served the previous resolution',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = await container.read(cosmeticsStateProvider.future);
    expect(first.noorBalance, 500);
    expect(first.equippedLanternSkin, 'emerald_jade');

    // Sign out, sign in as someone else. Nothing in the wardrobe ran, so
    // nothing invalidated the provider.
    fakeSync.userId = 'u2';
    await Future<void>.delayed(Duration.zero);

    final second = await container.read(cosmeticsStateProvider.future);
    expect(second.noorBalance, 20);
    expect(second.equippedLanternSkin, 'moonlit_silver');
  });

  test('a live listener still gets a stable value within one visit', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(cosmeticsStateProvider, (_, __) {});
    addTearDown(sub.close);

    final a = await container.read(cosmeticsStateProvider.future);
    final b = await container.read(cosmeticsStateProvider.future);
    expect(identical(a, b), isTrue);
  });
}
