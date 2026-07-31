// W5 Wave C.1 — every route into the paywall must name its placement.
//
// The compile-time half of the contract is `PaywallScreen.placement` being a
// required parameter with no default: a new construction site that forgets it
// does not build. The `/paywall` ROUTE is the half the compiler cannot cover —
// `context.push('/paywall')` is just a string, so a call site can navigate
// there with no placement and the screen would silently attribute itself to
// whatever the route builder guessed.
//
// So the route gets a typed front door (`pushPaywall` / `pushPaywallOn`, which
// carry a `PaywallPlacement` as the route's `extra`) and this file pins the
// negative: no bare `push('/paywall')` anywhere in `lib/`, and every known
// entry point still names a placement. If a future surface needs a different
// placement, change it here — do not reach for the raw string.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/paywall_navigation.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/services/analytics_event_names.dart';

/// Every `lib/**.dart` file, as (path, source) pairs.
List<({String path, String source})> _libSources() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files) (path: f.path, source: f.readAsStringSync()),
  ];
}

/// Strips `//` line comments so a doc comment mentioning the old call shape
/// (several of them do, deliberately) doesn't trip the scan.
String _withoutLineComments(String source) => source
    .split('\n')
    .map((l) {
      final i = l.indexOf('//');
      return i == -1 ? l : l.substring(0, i);
    })
    .join('\n');

void main() {
  group('paywall placement — entry points', () {
    test('no bare push to the paywall route anywhere in lib/', () {
      // `push('/paywall')`, `push("/paywall")`, `pushReplacement`, `go`, …
      // and the same thing spelled with the route constant — `push(
      // paywallRoutePath)` reaches the route just as bare, and a scan that
      // only knew the string literal let it through.
      final bare = RegExp(
        r'''\.(push|pushReplacement|pushNamed|go|replace)\s*\(\s*(['"]/paywall['"]|paywallRoutePath)''',
      );
      final offenders = <String>[];
      for (final entry in _libSources()) {
        if (entry.path.endsWith('paywall_navigation.dart')) continue;
        if (bare.hasMatch(_withoutLineComments(entry.source))) {
          offenders.add(entry.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'These files navigate to the paywall without a placement. Use '
            '`pushPaywall(context, placement: ...)` (or `pushPaywallOn` when '
            'the router was captured before a pop) so the surface is named: '
            '${offenders.join(', ')}',
      );
    });

    test('the route path constant is the only literal the router registers',
        () {
      final router =
          File('lib/core/router.dart').readAsStringSync();
      expect(
        router.contains('path: paywallRoutePath'),
        isTrue,
        reason: 'router.dart must register the in-app paywall via '
            '`paywallRoutePath` so the constant and the helper cannot drift.',
      );
      expect(
        router.contains('placementFromRouteExtra(state.extra)'),
        isTrue,
        reason: 'The /paywall builder must resolve its placement from the '
            "route's extra, not hardcode one.",
      );
    });

    test('every in-app entry point names PaywallPlacement.softInApp', () {
      // The cap sheets, the settings card, the home premium strip, the
      // collection teaser, the IAP→sub banner and the save-limit sheet are all
      // mid-app upsells — none of them is the onboarding ceremony.
      const softInAppEntryPoints = <String>[
        'lib/features/home/widgets/home_premium_strip.dart',
        'lib/features/settings/widgets/settings_premium_card.dart',
        'lib/features/collection/screens/collection_screen.dart',
        'lib/features/progress/screens/progress_screen.dart',
        'lib/features/duas/screens/duas_screen.dart',
        'lib/features/reflect/screens/reflect_screen.dart',
        'lib/features/daily/screens/muhasabah_screen.dart',
        'lib/widgets/iap_to_sub_upsell_banner.dart',
        'lib/widgets/upgrade_required_sheet.dart',
      ];
      for (final path in softInAppEntryPoints) {
        final source = File(path).readAsStringSync();
        expect(
          RegExp(r'pushPaywall(On)?\s*\(').hasMatch(source),
          isTrue,
          reason: '$path lost its typed paywall navigation.',
        );
        expect(
          source.contains('PaywallPlacement.softInApp'),
          isTrue,
          reason: '$path must open the paywall at '
              'PaywallPlacement.softInApp.',
        );
      }
    });

    test('the onboarding ceremony names PaywallPlacement.onboarding', () {
      final source =
          File('lib/features/onboarding/screens/onboarding_screen.dart')
              .readAsStringSync();
      expect(source.contains('PaywallPlacement.onboarding'), isTrue);
    });

    test('the two post-tour walls keep their own placements', () {
      final router = File('lib/core/router.dart').readAsStringSync();
      expect(router.contains('PaywallPlacement.hardWall'), isTrue,
          reason: 'kOnboardingPaywallPath is the hard entry wall.');
      expect(router.contains('appSession.softPaywallPlacement'), isTrue,
          reason: 'kOnboardingSoftPaywallPath resolves post_tour_soft vs '
              'post_trial_soft off the session.');
    });
  });

  group('paywall placement — wire values', () {
    test('analytics strings are exactly the shipped ones', () {
      // These are live in Mixpanel. Renaming one silently splits a funnel.
      expect(PaywallPlacement.onboarding.analyticsValue, 'onboarding');
      expect(PaywallPlacement.hardWall.analyticsValue, 'hard_wall');
      expect(PaywallPlacement.softInApp.analyticsValue, 'soft_inapp');
      expect(PaywallPlacement.postTourSoft.analyticsValue, 'post_tour_soft');
      expect(PaywallPlacement.postTrialSoft.analyticsValue, 'post_trial_soft');
    });

    test('they stay in lockstep with the AnalyticsEvents constants', () {
      expect(PaywallPlacement.onboarding.analyticsValue,
          AnalyticsEvents.placementOnboarding);
      expect(PaywallPlacement.hardWall.analyticsValue,
          AnalyticsEvents.placementHardWall);
      expect(PaywallPlacement.softInApp.analyticsValue,
          AnalyticsEvents.placementSoftInApp);
      expect(PaywallPlacement.postTourSoft.analyticsValue,
          AnalyticsEvents.placementPostTourSoft);
      expect(PaywallPlacement.postTrialSoft.analyticsValue,
          AnalyticsEvents.placementPostTrialSoft);
    });

    test('only the two post-tour gates are soft gates', () {
      expect(PaywallPlacement.postTourSoft.isPostTourSoftGate, isTrue);
      expect(PaywallPlacement.postTrialSoft.isPostTourSoftGate, isTrue);
      expect(PaywallPlacement.onboarding.isPostTourSoftGate, isFalse);
      expect(PaywallPlacement.hardWall.isPostTourSoftGate, isFalse);
      expect(PaywallPlacement.softInApp.isPostTourSoftGate, isFalse);
    });
  });

  group('placementFromRouteExtra', () {
    test('returns the placement the route was pushed with', () {
      expect(placementFromRouteExtra(PaywallPlacement.hardWall),
          PaywallPlacement.hardWall);
      expect(placementFromRouteExtra(PaywallPlacement.softInApp),
          PaywallPlacement.softInApp);
    });

    test('a missing placement is loud, not a silent default', () {
      // Asserts are enabled under `flutter test`, so a placement-less
      // navigation blows up in dev/CI instead of quietly reporting itself as
      // an in-app upsell in production.
      expect(() => placementFromRouteExtra(null), throwsAssertionError);
      expect(() => placementFromRouteExtra('soft_inapp'), throwsAssertionError);
    });
  });
}
