import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// W5 Wave D.1 — the lifetime warmup budgets are server dials
/// (`app_config.warmup_*_size`), not hardcoded constants.
///
/// These tests drive `AppConfigService` through its SharedPreferences cache,
/// exactly the way it is reached in production: no Supabase client is
/// initialized under `flutter test`, so every refresh attempt fails silently —
/// which makes "the fetch failed" the DEFAULT condition here, not a mock.
class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();

  bool premium = false;
  int isPremiumCallCount = 0;

  @override
  Future<bool> isPremium() async {
    isPremiumCallCount++;
    return premium;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  /// Writes [value] into the `app_config` cache the way `_refresh` would —
  /// JSON-encoded, with a fresh timestamp so it reads as non-stale.
  Future<void> cacheDial(
    String key,
    String jsonEncodedValue, {
    Duration age = Duration.zero,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_config_cache_v1_$key', jsonEncodedValue);
    await prefs.setInt(
      'app_config_cache_v1_${key}_at',
      DateTime.now().millisecondsSinceEpoch - age.inMilliseconds,
    );
  }

  group('warmupBudgetFor reads the app_config dial', () {
    for (final feature in GatedFeature.values) {
      test('${feature.name}: cached dial wins over the constant', () async {
        await cacheDial(GatingService.warmupSizeConfigKey[feature]!, '3');
        expect(await gating.warmupBudgetFor(feature), 3);
        expect(GatingService.warmupBudget[feature], isNot(3),
            reason:
                'the fallback constant must differ from the dial, otherwise '
                'this test would pass against a service that ignores config');
      });

      test('${feature.name}: no cached dial + unreachable server falls back',
          () async {
        expect(await gating.warmupBudgetFor(feature),
            GatingService.warmupBudget[feature]);
      });
    }

    test('the three dial keys are the ones the server seeds', () {
      expect(GatingService.warmupSizeConfigKey, {
        GatedFeature.reflect: 'warmup_reflect_size',
        GatedFeature.builtDua: 'warmup_built_dua_size',
        GatedFeature.discoverName: 'warmup_discover_name_size',
      });
    });

    test('a STALE cached dial still beats the constant (offline launch sees '
        'last-known config, not a number the server moved off)', () async {
      await cacheDial(
        'warmup_reflect_size',
        '3',
        age: const Duration(hours: 7), // past the 6h TTL
      );
      expect(await gating.warmupBudgetFor(GatedFeature.reflect), 3);
    });

    test('a dial of 0 is honoured — "no warmup" is a legitimate setting',
        () async {
      await cacheDial('warmup_reflect_size', '0');
      expect(await gating.warmupBudgetFor(GatedFeature.reflect), 0);
    });

    test('a NEGATIVE dial falls back rather than inverting the gate',
        () async {
      await cacheDial('warmup_reflect_size', '-4');
      expect(await gating.warmupBudgetFor(GatedFeature.reflect), 10);
    });

    test('a non-numeric dial value falls back', () async {
      await cacheDial('warmup_built_dua_size', '"lots"');
      expect(await gating.warmupBudgetFor(GatedFeature.builtDua), 10);
    });

    test('a bool-valued dial falls back (wrong jsonb type)', () async {
      await cacheDial('warmup_built_dua_size', 'true');
      expect(await gating.warmupBudgetFor(GatedFeature.builtDua), 10);
    });
  });

  group('the gate spends the dial, not the constant', () {
    test('canUse reports the dial as remaining on a first-ever use', () async {
      await cacheDial('warmup_reflect_size', '3');
      final result = await gating.canUse(GatedFeature.reflect);
      expect(result.allowed, isTrue);
      expect(result.reason, GateReason.warmupRemaining);
      expect(result.remaining, 3,
          reason: 'must be the dial (3), not the constant (10)');
    });

    test('warmup exhausts after exactly `dial` uses, then the daily cap bites',
        () async {
      await cacheDial('warmup_reflect_size', '3');

      UsageOutcome? last;
      for (var i = 0; i < 3; i++) {
        final res = await gating.canUse(GatedFeature.reflect);
        expect(res.allowed, isTrue);
        expect(res.reason, GateReason.warmupRemaining);
        expect(res.remaining, 3 - i);
        last = await gating.markUsed(GatedFeature.reflect);
      }
      expect(last, UsageOutcome.warmupJustExhausted,
          reason: 'the 3rd use is the 1 → 0 transition under a dial of 3');

      final blocked = await gating.canUse(GatedFeature.reflect);
      expect(blocked.allowed, isFalse);
      expect(blocked.reason, GateReason.dailyCap);
    });

    test('with no dial reachable the gate still gives the full fallback budget',
        () async {
      for (var i = 0; i < 10; i++) {
        final res = await gating.canUse(GatedFeature.reflect);
        expect(res.allowed, isTrue,
            reason: 'a config read that fails must NEVER harden the gate — '
                'use ${i + 1} of the 10-use fallback budget was denied');
        expect(res.reason, GateReason.warmupRemaining);
        await gating.markUsed(GatedFeature.reflect);
      }
      final blocked = await gating.canUse(GatedFeature.reflect);
      expect(blocked.allowed, isFalse);
    });

    test('discoverName spends its own dial, not reflect\'s', () async {
      await cacheDial('warmup_reflect_size', '9');
      await cacheDial('warmup_discover_name_size', '3');
      final result = await gating.canUse(GatedFeature.discoverName);
      expect(result.remaining, 3);
    });

    test('a user holding more than the dial does NOT get confiscated down to '
        'it — decrement means decrement', () async {
      // The legacy server default is 10; the dial now reads 3. A user mid-way
      // through their old budget must lose exactly one use, not seven.
      await cacheDial('warmup_reflect_size', '3');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 10);

      await gating.markUsed(GatedFeature.reflect);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')), 9);
    });

    test('a counter SYNTHESIZED from the dial is never pushed to the server '
        'as an absolute value', () async {
      // The dial (3) is the reel_v1 number. Every account today is on the
      // `legacy` cohort, whose server truth is the column default 10, and the
      // local counter is absent until `hydrateFromProfile` runs — a reinstall,
      // a second device, an account switch, or a launch whose batch sync timed
      // out. Pushing `dial - 1 = 2` into `user_profiles` would destroy 8 uses
      // that `guard_user_profiles_freemium_fields` (decrement-only) can never
      // restore. The server holds the truth; the client must not overwrite it
      // with a number it guessed.
      await cacheDial('warmup_reflect_size', '3');

      await gating.markUsed(GatedFeature.reflect);

      final profileWrites = fakeSync.rawUpsertCalls
          .where((c) => c['table'] == 'user_profiles')
          .toList();
      expect(profileWrites, isEmpty,
          reason: 'a config-derived budget must not become a server write — '
              'the freemium guard makes a too-low value irreversible');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')), 2,
          reason: 'the local counter still decrements so the gate stays '
              'consistent within the session; the next sync corrects it');
    });

    test('a SECOND use still does not push, because the first use wrote the '
        'guess to prefs and provenance must not be re-derived from that',
        () async {
      // The bug the single-use test above could not see. `fromStore` was
      // computed as "does a local key exist", and `_decrementWarmup` WRITES
      // that key even on the no-push path. So the guess launders itself into
      // server-authored state on the very next call:
      //
      //   use 1 -> read (3, synthesized) -> prefs=2, no push        server=10
      //   use 2 -> read (2, "fromStore") -> prefs=1, PUSH 1         server=1
      //
      // A legacy user with 10 server warmups is cut to 1 after two uses, and
      // the decrement-only guard makes it permanent. The doc comment claimed
      // "the next hydrateFromProfile restores the real number" — but the whole
      // premise of this path is that the sync did NOT land.
      await cacheDial('warmup_reflect_size', '3');

      await gating.markUsed(GatedFeature.reflect);
      await gating.markUsed(GatedFeature.reflect);

      final profileWrites = fakeSync.rawUpsertCalls
          .where((c) => c['table'] == 'user_profiles')
          .toList();
      expect(profileWrites, isEmpty,
          reason: 'provenance must survive being written to prefs — until a '
              'real server value is hydrated, EVERY decrement is still a '
              'guess and must stay local');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')), 1,
          reason: 'the local counter still tracks the session honestly');
    });

    test('hydration clears the provisional mark, so later decrements DO push',
        () async {
      // The taint must not be permanent either: once a real server number
      // lands, writes have to resume or the server drifts stale forever.
      await cacheDial('warmup_reflect_size', '3');
      await gating.markUsed(GatedFeature.reflect); // synthesized, no push

      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 10);
      await gating.markUsed(GatedFeature.reflect);

      final profileWrites = fakeSync.rawUpsertCalls
          .where((c) => c['table'] == 'user_profiles')
          .toList();
      expect(profileWrites, hasLength(1));
      expect((profileWrites.single['data'] as Map)['warmup_reflect_remaining'],
          9);
    });

    test('a counter that came from the server IS still pushed on decrement',
        () async {
      await cacheDial('warmup_reflect_size', '3');
      await gating.debugSetWarmupRemaining(GatedFeature.reflect, 10);

      await gating.markUsed(GatedFeature.reflect);

      final profileWrites = fakeSync.rawUpsertCalls
          .where((c) => c['table'] == 'user_profiles')
          .toList();
      expect(profileWrites, hasLength(1));
      expect((profileWrites.single['data'] as Map)['warmup_reflect_remaining'],
          9);
    });

    test('a stored counter short-circuits the config read entirely (the hot '
        'path stays a single prefs lookup)', () async {
      // No dial cached anywhere; a stored counter must be used verbatim,
      // proving `_readWarmupRemaining` never consults config once the local
      // counter exists.
      await gating.debugSetWarmupRemaining(GatedFeature.builtDua, 4);
      final result = await gating.canUse(GatedFeature.builtDua);
      expect(result.remaining, 4);
    });
  });

  group('premium invariants hold across the dial change', () {
    test('premium never consumes warmup, whatever the dial says', () async {
      await cacheDial('warmup_reflect_size', '3');
      fakePurchase.premium = true;

      final result = await gating.canUse(GatedFeature.reflect);
      expect(result.reason, GateReason.ok,
          reason: 'premium must never land in the warmup phase');

      await gating.markUsed(GatedFeature.reflect);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(fakeSync.scopedKey('warmup_reflect_remaining')),
          isNull,
          reason: 'premium must not touch the warmup counter');
    });

    test('PINNED: premium short-circuits reserveBypass before any RPC fires',
        () async {
      fakePurchase.premium = true;
      fakeSync.rpcHandlers['reserve_ai_bypass'] = (params) async {
        fail('premium user reached the reserve_ai_bypass RPC');
      };

      expect(await gating.reserveBypass(GatedFeature.reflect), isNull);
      expect(fakeSync.rpcCalls, isEmpty,
          reason: 'no RPC may fire for a premium user (CLAUDE.md invariant)');
    });
  });
}
