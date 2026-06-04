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
  });
}
