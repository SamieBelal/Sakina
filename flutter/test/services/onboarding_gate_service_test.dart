import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/onboarding_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  final gate = OnboardingGateService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  group('paywall-cleared latch', () {
    test('defaults to TRUE when absent (grandfather guard)', () async {
      expect(await gate.isPaywallCleared(), true);
    });

    test('setPaywallCleared(false) puts user INTO the gate', () async {
      await gate.setPaywallCleared(false);
      expect(await gate.isPaywallCleared(), false);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(fakeSync.scopedKey(
            OnboardingGateService.paywallClearedBaseKey)),
        false,
      );
    });

    test('setPaywallCleared(true) clears the gate', () async {
      await gate.setPaywallCleared(false);
      await gate.setPaywallCleared(true);
      expect(await gate.isPaywallCleared(), true);
    });

    test('mirrors the latch to user_profiles via upsertRawRow on id', () async {
      await gate.setPaywallCleared(false);

      expect(fakeSync.rawUpsertCalls, isNotEmpty);
      final call = fakeSync.rawUpsertCalls.last;
      expect(call['table'], 'user_profiles');
      expect(call['onConflict'], 'id');
      expect((call['data'] as Map)['id'], 'user-1');
      expect((call['data'] as Map)['onboarding_paywall_cleared'], false);
    });

    test('does not write to server when unauthenticated', () async {
      fakeSync.userId = null;
      await gate.setPaywallCleared(false);
      expect(fakeSync.rawUpsertCalls, isEmpty);
    });
  });

  // The `tour resume cursor` group went with the cursor itself (§F1a): the
  // guided tour was deleted, so nothing resumes at a persisted step and
  // `tourStepIndex` / `setTourStepIndex` no longer exist.

  group('hydrateFromProfile', () {
    test('writes the latch from a server payload', () async {
      await gate.hydrateFromProfile({'onboarding_paywall_cleared': false});
      expect(await gate.isPaywallCleared(), false);
    });

    test('tolerates a pre-migration payload (absent keys leave cache)',
        () async {
      await gate.setPaywallCleared(false);
      await gate.hydrateFromProfile({'unrelated': 1});
      expect(await gate.isPaywallCleared(), false);
    });

    test('ignores the retired tour_step_index without throwing', () async {
      // The RPC still returns the column; hydrate must simply not read it.
      await gate.setPaywallCleared(false);
      await gate.hydrateFromProfile({
        'onboarding_paywall_cleared': true,
        'tour_step_index': 4,
      });
      expect(await gate.isPaywallCleared(), true);
    });
  });
}
