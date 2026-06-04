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

  group('tour resume cursor', () {
    test('defaults to 0 when absent', () async {
      expect(await gate.tourStepIndex(), 0);
    });

    test('persists and reads back the step index', () async {
      await gate.setTourStepIndex(7);
      expect(await gate.tourStepIndex(), 7);
    });

    test('clamps negative indices to 0', () async {
      await gate.setTourStepIndex(-5);
      expect(await gate.tourStepIndex(), 0);
    });
  });

  group('hydrateFromProfile', () {
    test('writes both values from a server payload', () async {
      await gate.hydrateFromProfile({
        'onboarding_paywall_cleared': false,
        'onboarding_tour_step_index': 4,
      });
      expect(await gate.isPaywallCleared(), false);
      expect(await gate.tourStepIndex(), 4);
    });

    test('tolerates a pre-migration payload (absent keys leave cache)',
        () async {
      await gate.setPaywallCleared(false);
      await gate.setTourStepIndex(3);
      await gate.hydrateFromProfile({'unrelated': 1});
      expect(await gate.isPaywallCleared(), false);
      expect(await gate.tourStepIndex(), 3);
    });

    test('clamps a negative server step index', () async {
      await gate.hydrateFromProfile({'onboarding_tour_step_index': -2});
      expect(await gate.tourStepIndex(), 0);
    });
  });
}
