import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';

/// Convenience wrapper with sensible defaults so each test only states the
/// fields it cares about. Defaults = a brand-new authenticated user who has
/// finished onboarding, not done the tour, not cleared the wall, not premium,
/// with the flow ENABLED → the most "gated" baseline.
OnboardingStage stage({
  bool isAuthenticated = true,
  bool hasOnboarded = true,
  bool tourCompleted = false,
  bool paywallCleared = false,
  bool isPremium = false,
  bool hardPaywallFlowEnabled = true,
}) {
  return resolveOnboardingStage(
    isAuthenticated: isAuthenticated,
    hasOnboarded: hasOnboarded,
    tourCompleted: tourCompleted,
    paywallCleared: paywallCleared,
    isPremium: isPremium,
    hardPaywallFlowEnabled: hardPaywallFlowEnabled,
  );
}

void main() {
  group('resolveOnboardingStage', () {
    group('welcome gate (auth + onboarding)', () {
      test('unauthenticated → welcome', () {
        expect(stage(isAuthenticated: false), OnboardingStage.welcome);
      });

      test('authenticated but not onboarded → welcome', () {
        expect(stage(hasOnboarded: false), OnboardingStage.welcome);
      });

      test('welcome wins even if other flags are set', () {
        expect(
          stage(
            isAuthenticated: false,
            tourCompleted: true,
            paywallCleared: true,
            isPremium: true,
          ),
          OnboardingStage.welcome,
        );
      });
    });

    group('kill switch', () {
      test('flow disabled → app (legacy behaviour), regardless of gate flags',
          () {
        expect(
          stage(
            hardPaywallFlowEnabled: false,
            tourCompleted: false,
            paywallCleared: false,
          ),
          OnboardingStage.app,
        );
      });

      test('flow disabled does NOT override the welcome gate', () {
        expect(
          stage(hardPaywallFlowEnabled: false, isAuthenticated: false),
          OnboardingStage.welcome,
        );
      });
    });

    group('grandfathering (latch short-circuits tour)', () {
      test('paywallCleared → app even when tour not completed', () {
        expect(
          stage(paywallCleared: true, tourCompleted: false),
          OnboardingStage.app,
        );
      });

      test('premium → app even when tour not completed', () {
        expect(
          stage(isPremium: true, tourCompleted: false),
          OnboardingStage.app,
        );
      });
    });

    group('forced tour', () {
      test('new user, tour incomplete → tour', () {
        expect(stage(tourCompleted: false), OnboardingStage.tour);
      });

      test('tour incomplete but not yet cleared/premium → tour', () {
        expect(
          stage(tourCompleted: false, paywallCleared: false, isPremium: false),
          OnboardingStage.tour,
        );
      });
    });

    group('hard paywall', () {
      test('tour done, not cleared, not premium → hardPaywall', () {
        expect(
          stage(tourCompleted: true, paywallCleared: false, isPremium: false),
          OnboardingStage.hardPaywall,
        );
      });

      test('tour done then clears latch → app', () {
        expect(
          stage(tourCompleted: true, paywallCleared: true),
          OnboardingStage.app,
        );
      });

      test('tour done then becomes premium → app', () {
        expect(
          stage(tourCompleted: true, isPremium: true),
          OnboardingStage.app,
        );
      });
    });

    group('full truth table (flow enabled, authed, onboarded)', () {
      // tour × cleared × premium → expected
      final cases = <(bool, bool, bool), OnboardingStage>{
        (false, false, false): OnboardingStage.tour,
        (false, false, true): OnboardingStage.app, // premium short-circuit
        (false, true, false): OnboardingStage.app, // latch short-circuit
        (false, true, true): OnboardingStage.app,
        (true, false, false): OnboardingStage.hardPaywall,
        (true, false, true): OnboardingStage.app,
        (true, true, false): OnboardingStage.app,
        (true, true, true): OnboardingStage.app,
      };

      cases.forEach((key, expected) {
        final (tour, cleared, premium) = key;
        test('tour=$tour cleared=$cleared premium=$premium → $expected', () {
          expect(
            stage(
              tourCompleted: tour,
              paywallCleared: cleared,
              isPremium: premium,
            ),
            expected,
          );
        });
      });
    });

    // ---------------------------------------------------------------------
    // Post-tour paywall MODE (reverse-trial Phase A). When `paywallMode` is
    // supplied it drives the post-tour branch directly; the legacy
    // `hardPaywallFlowEnabled` bool is only consulted when no mode is given.
    // ---------------------------------------------------------------------
    group('post-tour paywall mode', () {
      OnboardingStage modeStage({
        required PostTourPaywallMode paywallMode,
        bool tourCompleted = true,
        bool paywallCleared = false,
        bool isPremium = false,
      }) =>
          resolveOnboardingStage(
            isAuthenticated: true,
            hasOnboarded: true,
            tourCompleted: tourCompleted,
            paywallCleared: paywallCleared,
            isPremium: isPremium,
            paywallMode: paywallMode,
          );

      test('premium short-circuits to app regardless of mode', () {
        for (final m in PostTourPaywallMode.values) {
          expect(
            modeStage(paywallMode: m, isPremium: true, tourCompleted: true),
            OnboardingStage.app,
            reason: 'mode=$m',
          );
        }
      });

      test('paywallCleared short-circuits to app regardless of mode', () {
        for (final m in PostTourPaywallMode.values) {
          expect(
            modeStage(paywallMode: m, paywallCleared: true, tourCompleted: true),
            OnboardingStage.app,
            reason: 'mode=$m',
          );
        }
      });

      test('tour incomplete → tour for gated modes (soft, hard)', () {
        for (final m in [PostTourPaywallMode.soft, PostTourPaywallMode.hard]) {
          expect(
            modeStage(paywallMode: m, tourCompleted: false),
            OnboardingStage.tour,
            reason: 'mode=$m',
          );
        }
      });

      test('mode off bypasses the whole gate (incl. tour) → app', () {
        // `off` is the full kill switch — like the legacy `!flowEnabled` it
        // short-circuits to app BEFORE the tour check.
        expect(
          modeStage(paywallMode: PostTourPaywallMode.off, tourCompleted: false),
          OnboardingStage.app,
        );
      });

      test('mode soft, tour done, not cleared → softPaywall', () {
        expect(
          modeStage(paywallMode: PostTourPaywallMode.soft),
          OnboardingStage.softPaywall,
        );
      });

      test('mode hard, tour done, not cleared → hardPaywall', () {
        expect(
          modeStage(paywallMode: PostTourPaywallMode.hard),
          OnboardingStage.hardPaywall,
        );
      });

      test('mode off, tour done, not cleared → app', () {
        expect(
          modeStage(paywallMode: PostTourPaywallMode.off),
          OnboardingStage.app,
        );
      });
    });

    // ---------------------------------------------------------------------
    // Legacy fallback: when NO `paywallMode` is supplied the function derives
    // the post-tour branch from `hardPaywallFlowEnabled` (preserves today's
    // behaviour for the live binary and the existing progress_screen caller).
    // ---------------------------------------------------------------------
    group('legacy bool fallback (no mode supplied)', () {
      test('hardPaywallFlowEnabled true, tour done, uncleared → hardPaywall',
          () {
        expect(
          stage(hardPaywallFlowEnabled: true, tourCompleted: true),
          OnboardingStage.hardPaywall,
        );
      });

      test('hardPaywallFlowEnabled false, tour done, uncleared → app', () {
        expect(
          stage(hardPaywallFlowEnabled: false, tourCompleted: true),
          OnboardingStage.app,
        );
      });
    });
  });
}
