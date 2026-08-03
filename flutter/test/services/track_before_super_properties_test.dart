// W6 Wave 0 / D3 — the ordering failure class, guarded once instead of per-event.
//
// Mixpanel super properties are stamped at SEND time and never backfilled. An
// event tracked before `registerBootstrapAnalytics` has run ships permanently
// unlabelled — no `app_version`, no `onboarding_flow`, no `free_tier_cohort`.
//
// The damage is that it does not look like damage. An unlabelled slice of the
// funnel renders as a large "unknown" bucket, which reads as organic traffic
// rather than as a bug, and the keep decision gets made on it.
//
// The plan's original answer was one ordering test in Wave A plus a manual
// T0+24h coverage check. That covers the events this plan enumerates and
// nothing anyone adds afterwards. D3 chose a debug assert in `track()` so the
// whole class is guarded, present and future.
//
// **Why the predicate is a separate pure function.** `track()` is called by 27
// test spies that override it, and by every screen in the app; an assert that
// can only be exercised through a live Mixpanel channel is an assert nobody
// tests. Same shape as `shouldEmitAbandonment` in onboarding_screen.dart — the
// shipping predicate and the tested one are the same code.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_service.dart';

void main() {
  group('shouldWarnEarlyEvent — the ordering predicate', () {
    test('live analytics + no boot properties = the bug', () {
      expect(
        AnalyticsService.shouldWarnEarlyEvent(
          initialized: true,
          bootPropertiesRegistered: false,
        ),
        isTrue,
      );
    });

    test('once boot properties are registered, every event is fine', () {
      expect(
        AnalyticsService.shouldWarnEarlyEvent(
          initialized: true,
          bootPropertiesRegistered: true,
        ),
        isFalse,
      );
    });

    test('an UNINITIALIZED client never warns', () {
      // Scoping that matters: under flutter_test `Mixpanel.init` always fails,
      // so `initialized` is false for the entire suite. Without this branch the
      // assert would fire in every test that touches a real AnalyticsService —
      // and an assert that cries wolf gets deleted within a week.
      expect(
        AnalyticsService.shouldWarnEarlyEvent(
          initialized: false,
          bootPropertiesRegistered: false,
        ),
        isFalse,
      );
      expect(
        AnalyticsService.shouldWarnEarlyEvent(
          initialized: false,
          bootPropertiesRegistered: true,
        ),
        isFalse,
      );
    });
  });

  group('the service tracks its own boot state', () {
    test('a fresh service has not registered boot properties', () {
      expect(AnalyticsService().bootPropertiesRegistered, isFalse);
    });

    test('cacheDeviceSuperProperties is what flips it', () {
      // Deliberately this method and not `setSuperProperties`: the durable
      // device/build set is what `registerBootstrapAnalytics` writes, and it is
      // the set that must precede the first event. A user-scoped
      // `setSuperProperties` call later in the session is not boot.
      final service = AnalyticsService();
      service.cacheDeviceSuperProperties({'app_version': '1.3.0+1'});

      expect(service.bootPropertiesRegistered, isTrue);
    });

    test('a plain setSuperProperties does NOT count as boot', () {
      final service = AnalyticsService();
      service.setSuperProperties({'is_premium': true});

      expect(service.bootPropertiesRegistered, isFalse,
          reason: 'otherwise any user-scoped registration would satisfy the '
              'guard and the boot set could still be missing');
    });

    test('a sign-out reset does not un-register boot properties', () {
      // resetForSignOut re-applies the durable set by design; the guard must
      // agree with that, or every post-sign-out event would trip the assert.
      final service = AnalyticsService();
      service.cacheDeviceSuperProperties({'app_version': '1.3.0+1'});
      service.resetForSignOut();

      expect(service.bootPropertiesRegistered, isTrue);
    });
  });

  group('the durable device set MERGES across callers (Wave 0/A review, P0)',
      () {
    // `cacheDeviceSuperProperties` was written assuming ONE caller — boot. Wave
    // A added a second, with a ONE-KEY map: the `onboarding_flow` hook, which
    // fires from `setOnboardingFlow` the moment reel onboarding completes (the
    // majority path) or on a returning user's first sync.
    //
    // Replacing rather than merging meant that second call wiped `platform`,
    // `app_version`, `install_id` and all three `flag_*` from the durable set
    // that `resetForSignOut` re-applies. Nothing breaks in the current session
    // — Mixpanel's own registerSuperProperties merges — so it is invisible
    // until the next sign-out on that device, after which EVERY event for the
    // next user ships with no version or flag segmentation until a cold start.
    //
    // A shared QA device cycling test accounts hits this immediately, and it is
    // precisely the corruption this wave exists to prevent.
    //
    // MUTATION: change the merge back to `_deviceSuperProperties = Map.from(props)`
    // → the re-apply case below loses everything except onboarding_flow.
    test('a later one-key call does not evict the boot set', () {
      final service = _RecordingAnalytics();
      service.cacheDeviceSuperProperties({
        'platform': 'ios',
        'app_version': '1.3.0+1',
        'flag_hard_paywall': true,
        'install_id': 'install-abc',
      });
      service.cacheDeviceSuperProperties({'onboarding_flow': 'reel_v1'});

      service.registered.clear();
      service.resetForSignOut();

      final reapplied = service.registered.single;
      expect(reapplied['platform'], 'ios');
      expect(reapplied['app_version'], '1.3.0+1');
      expect(reapplied['flag_hard_paywall'], true);
      expect(reapplied['install_id'], 'install-abc');
      expect(reapplied['onboarding_flow'], 'reel_v1',
          reason: 'the late arrival must join the durable set, not replace it');
    });

    // Wave H (2026-08-02) — the plan asks for the durable set to be
    // RE-VERIFIED against each new wave's callers, because the failure above
    // was found by a caller nobody re-checked. Doing it by hand once is worth
    // nothing to the next wave; this is the same audit, run by CI.
    //
    // The census, at the time of writing: exactly ONE call site
    // (`registerBootstrapAnalytics`). Waves A–E of the journaling plan added
    // none — the `onboarding_flow` hook that caused the P0 was moved OFF this
    // method entirely (it is user-scoped, so it is a plain
    // `setSuperProperties` and is correctly wiped on sign-out).
    //
    // A new call site is not forbidden. It has to be a deliberate decision:
    // does this property belong to the DEVICE (survives a user switch) or to
    // the USER (must not)? Getting that wrong is the other half of the same
    // bug, and it is why this fails on an unexpected caller rather than
    // counting them.
    test('the durable-set call sites are the audited ones', () {
      final callers = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = file.readAsStringSync();
        // The declaration itself lives in analytics_service.dart; a CALL has a
        // receiver in front of it.
        if (RegExp(r'\w\.cacheDeviceSuperProperties\s*\(').hasMatch(src)) {
          callers.add(file.path.replaceAll(r'\', '/'));
        }
      }

      expect(callers, ['lib/services/analytics_events.dart'],
          reason: 'a new caller of the DURABLE device set changes what every '
              'event carries for the NEXT user on a shared device. If this is '
              'intentional, decide device-scoped vs user-scoped first (see '
              'onboarding_flow, which had to move OFF this method), then add '
              'the file here.');
    });

    test('a later call OVERWRITES its own key rather than duplicating', () {
      final service = _RecordingAnalytics();
      service.cacheDeviceSuperProperties({'app_version': '1.3.0+1'});
      service.cacheDeviceSuperProperties({'app_version': '1.3.0+2'});

      service.registered.clear();
      service.resetForSignOut();

      expect(service.registered.single['app_version'], '1.3.0+2');
    });
  });

}

/// Captures what actually reaches Mixpanel's `registerSuperProperties`, which
/// is the only thing that matters after a sign-out reset.
class _RecordingAnalytics extends AnalyticsService {
  final registered = <Map<String, dynamic>>[];

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      registered.add(Map<String, dynamic>.from(props));
}
