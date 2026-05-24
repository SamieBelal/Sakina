import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  late GatingService gating;

  // Anchor "now" so the 7-day signup floor + 14-day dismissal window are
  // deterministic. Signup baseline: 10 days before this anchor.
  final fixedNow = DateTime.parse('2026-05-25T12:00:00Z');
  const tenDaysAgoIso = '2026-05-15T12:00:00Z';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    gating = GatingService.test();
    GatingService.debugNowUtc = () => fixedNow;
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    GatingService.debugNowUtc = null;
    GatingService.onProfileHydrated = null;
  });

  group('iapToSubBannerEligible', () {
    test('returns true when all 4 conditions met (6+ bypasses, !premium, '
        'signup>7d, never dismissed)', () async {
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isTrue);
    });

    test('returns false when premium (short-circuits before cache read)',
        () async {
      fakePurchase.premium = true;
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 99,
      });
      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'Premium users are on the destination surface — banner '
              'would be insulting');
    });

    test('returns false when lifetime < 6 (boundary at exactly 5)', () async {
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 5,
      });
      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'Threshold is >=6; 5 is below the IAP-velocity bar');
    });

    test('returns true at the 6-bypass boundary exactly', () async {
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isTrue);
    });

    test('returns false when days_since_signup < 7 (still in honeymoon)',
        () async {
      // 5 days ago — below the 7-day floor.
      await gating.hydrateFromProfile({
        'created_at': '2026-05-20T12:00:00Z',
        'lifetime_bypasses_purchased': 10,
      });
      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'Day-1 freebie + paywall already in the user flow — second '
              'upsell within Week-1 is harassment');
    });

    test('returns false on day 6 (boundary, strict >= 7)', () async {
      await gating.hydrateFromProfile({
        'created_at': '2026-05-19T12:00:00Z', // exactly 6 days ago
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isFalse);
    });

    test('returns true at day 7 boundary exactly', () async {
      await gating.hydrateFromProfile({
        'created_at': '2026-05-18T12:00:00Z', // exactly 7 days ago
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isTrue);
    });

    test('returns false when signup_at missing (defense against corruption)',
        () async {
      await gating.hydrateFromProfile({
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'Absence of created_at must NOT eligibility-leak');
    });

    test('returns false when signup_at is malformed', () async {
      await gating.hydrateFromProfile({
        'created_at': 'not-a-date',
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isFalse);
    });

    test('returns false when dismissed within last 14 days', () async {
      // Dismissed 10 days ago — still inside the suppression window.
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 6,
        'iap_upsell_banner_dismissed_at': '2026-05-15T12:00:00Z',
      });
      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'User said no recently — respect the 14-day cadence');
    });

    test('returns true after dismissal staleness > 14 days', () async {
      // Dismissed 15 days ago — outside the suppression window.
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 6,
        'iap_upsell_banner_dismissed_at': '2026-05-10T12:00:00Z',
      });
      expect(await gating.iapToSubBannerEligible(), isTrue);
    });

    test('returns false on clean install (no hydration)', () async {
      expect(await gating.iapToSubBannerEligible(), isFalse,
          reason: 'Defaults must NOT eligibility-leak — lifetime=0 fails '
              'the threshold check');
    });
  });

  group('dismissIapToSubBanner', () {
    test('happy path: writes dismissed_at to cache from RPC response',
        () async {
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 6,
      });
      expect(await gating.iapToSubBannerEligible(), isTrue);

      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] = (_) async => {
            'ok': true,
            'dismissed_at': '2026-05-25T12:00:00Z',
          };

      final ok = await gating.dismissIapToSubBanner();
      expect(ok, isTrue);
      expect(fakeSync.rpcCalls.last['fn'], 'dismiss_iap_upsell_banner');

      // Cache mirrored — eligibility flips false immediately.
      expect(await gating.iapToSubBannerEligible(), isFalse);
      expect(await gating.iapBannerDismissedAt(),
          DateTime.parse('2026-05-25T12:00:00Z'));
    });

    test('premium short-circuit: NEVER hits the RPC', () async {
      fakePurchase.premium = true;
      var rpcFired = false;
      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] = (_) async {
        rpcFired = true;
        return {'ok': true, 'dismissed_at': '2026-05-25T12:00:00Z'};
      };

      final ok = await gating.dismissIapToSubBanner();
      expect(ok, isTrue,
          reason: 'Premium return is true — banner is already hidden, '
              'nothing to persist');
      expect(rpcFired, isFalse);
    });

    test('RPC null (network) returns false, cache untouched', () async {
      // No handler installed → callRpc returns null.
      final ok = await gating.dismissIapToSubBanner();
      expect(ok, isFalse);
      expect(await gating.iapBannerDismissedAt(), isNull);
    });

    test('RPC returns ok=false → false, cache untouched', () async {
      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] = (_) async => {
            'ok': false,
            'reason': 'something',
          };
      final ok = await gating.dismissIapToSubBanner();
      expect(ok, isFalse);
      expect(await gating.iapBannerDismissedAt(), isNull);
    });

    test('RPC returns ok=true but dismissed_at missing → false (defense)',
        () async {
      fakeSync.rpcHandlers['dismiss_iap_upsell_banner'] =
          (_) async => {'ok': true};
      final ok = await gating.dismissIapToSubBanner();
      expect(ok, isFalse,
          reason: 'Malformed RPC response must not pretend the dismissal '
              'happened — caller should retry on next render');
    });
  });

  group('hydrateFromProfile (PR 5 fields)', () {
    test('writes lifetime_bypasses_purchased + iap_upsell_banner_dismissed_at',
        () async {
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'lifetime_bypasses_purchased': 42,
        'iap_upsell_banner_dismissed_at': '2026-05-20T08:00:00Z',
      });
      expect(await gating.lifetimeBypassesPurchased(), 42);
      expect(await gating.iapBannerDismissedAt(),
          DateTime.parse('2026-05-20T08:00:00Z'));
    });

    test('null iap_upsell_banner_dismissed_at clears stale cache', () async {
      // Prime a stale dismissal then reload from a server payload that
      // says "never dismissed" (admin reset / cleared the column).
      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'iap_upsell_banner_dismissed_at': '2026-05-15T12:00:00Z',
      });
      expect(await gating.iapBannerDismissedAt(), isNotNull);

      await gating.hydrateFromProfile({
        'created_at': tenDaysAgoIso,
        'iap_upsell_banner_dismissed_at': null,
      });
      expect(await gating.iapBannerDismissedAt(), isNull,
          reason: 'Server null must clear local cache so an admin reset '
              'actually re-enables the banner');
    });

    test('absent lifetime_bypasses_purchased leaves cache at 0 (pre-PR5 '
        'backend tolerance)', () async {
      await gating.hydrateFromProfile({'created_at': tenDaysAgoIso});
      expect(await gating.lifetimeBypassesPurchased(), 0);
    });

    test('onProfileHydrated callback fires at the end of hydrateFromProfile',
        () async {
      // Regression-pin: the banner provider relies on this callback to
      // re-evaluate after every sync. If a future contributor moves the
      // call site or wraps it in a conditional, this test fails before
      // the banner silently stops auto-refreshing.
      var fired = 0;
      GatingService.onProfileHydrated = () => fired++;
      await gating.hydrateFromProfile({});
      expect(fired, 1);
      await gating.hydrateFromProfile({'created_at': tenDaysAgoIso});
      expect(fired, 2, reason: 'Each hydration must fire once');
    });
  });
}
