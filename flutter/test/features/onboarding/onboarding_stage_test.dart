import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';

/// Convenience wrapper with sensible defaults so each test only states the
/// fields it cares about. Defaults = a brand-new authenticated user who has
/// finished onboarding, not cleared the wall, not premium, with the flow
/// ENABLED → the most "gated" baseline.
OnboardingStage stage({
  bool isAuthenticated = true,
  bool hasOnboarded = true,
  bool paywallCleared = false,
  bool isPremium = false,
  bool hardPaywallFlowEnabled = true,
}) {
  return resolveOnboardingStage(
    isAuthenticated: isAuthenticated,
    hasOnboarded: hasOnboarded,
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
          stage(hardPaywallFlowEnabled: false, paywallCleared: false),
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

    // -----------------------------------------------------------------------
    // §F1a — the tour stage is GONE. These are the release tests: the states
    // that used to resolve to `OnboardingStage.tour` must now resolve to a real
    // gate. Every enum value is reachable and none of them is a dead end.
    // -----------------------------------------------------------------------
    group('the deleted tour stage', () {
      test('OnboardingStage has no `tour` value at all', () {
        // Structural, not behavioural: as long as the enum has no tour member,
        // no amount of state can route a user to a stage with neither a tour
        // nor a paywall surface (plan §F0's stranding bug class).
        expect(
          OnboardingStage.values,
          unorderedEquals(const [
            OnboardingStage.welcome,
            OnboardingStage.hardPaywall,
            OnboardingStage.softPaywall,
            OnboardingStage.app,
          ]),
        );
      });

      test(
          'the previously-stranded state (uncleared, not premium) now resolves '
          'to the hard wall, not a dead stage', () {
        // This is the exact input that used to produce `tour`: an authed,
        // onboarded, uncleared, non-premium user whose tour-seen flag was
        // false. It now lands on a paywall the user can actually act on.
        expect(
          stage(paywallCleared: false, isPremium: false),
          OnboardingStage.hardPaywall,
        );
      });

      test('every reachable state resolves to a stage with a surface', () {
        for (final mode in PostTourPaywallMode.values) {
          for (final cleared in [true, false]) {
            for (final premium in [true, false]) {
              final s = resolveOnboardingStage(
                isAuthenticated: true,
                hasOnboarded: true,
                paywallCleared: cleared,
                isPremium: premium,
                paywallMode: mode,
              );
              expect(
                s,
                anyOf(
                  OnboardingStage.app,
                  OnboardingStage.hardPaywall,
                  OnboardingStage.softPaywall,
                ),
                reason: 'mode=$mode cleared=$cleared premium=$premium',
              );
            }
          }
        }
      });
    });

    group('grandfathering', () {
      test('paywallCleared → app', () {
        // The CLEARED latch grandfathers existing users past the wall.
        expect(stage(paywallCleared: true), OnboardingStage.app);
      });

      test('premium but NOT cleared → app', () {
        // The tour used to be checked FIRST so a reverse-trial treatment user
        // (premium via the granted trial) still saw the same forced tour as
        // control. With no tour to confound, premium short-circuits directly.
        expect(
          stage(isPremium: true, paywallCleared: false),
          OnboardingStage.app,
        );
      });
    });

    group('hard paywall', () {
      test('not cleared, not premium → hardPaywall', () {
        expect(
          stage(paywallCleared: false, isPremium: false),
          OnboardingStage.hardPaywall,
        );
      });

      test('clears latch → app', () {
        expect(stage(paywallCleared: true), OnboardingStage.app);
      });

      test('becomes premium → app', () {
        expect(stage(isPremium: true), OnboardingStage.app);
      });
    });

    group('full truth table (flow enabled, authed, onboarded)', () {
      // cleared × premium → expected
      final cases = <(bool, bool), OnboardingStage>{
        (false, false): OnboardingStage.hardPaywall,
        (false, true): OnboardingStage.app,
        (true, false): OnboardingStage.app, // latch short-circuit
        (true, true): OnboardingStage.app,
      };

      cases.forEach((key, expected) {
        final (cleared, premium) = key;
        test('cleared=$cleared premium=$premium → $expected', () {
          expect(
            stage(paywallCleared: cleared, isPremium: premium),
            expected,
          );
        });
      });
    });

    // ---------------------------------------------------------------------
    // Entry-gate MODE (reverse-trial Phase A). When `paywallMode` is supplied
    // it drives the gate branch directly; the legacy `hardPaywallFlowEnabled`
    // bool is only consulted when no mode is given.
    // ---------------------------------------------------------------------
    group('entry paywall mode', () {
      OnboardingStage modeStage({
        required PostTourPaywallMode paywallMode,
        bool paywallCleared = false,
        bool isPremium = false,
      }) =>
          resolveOnboardingStage(
            isAuthenticated: true,
            hasOnboarded: true,
            paywallCleared: paywallCleared,
            isPremium: isPremium,
            paywallMode: paywallMode,
          );

      test('premium short-circuits to app regardless of mode', () {
        for (final m in PostTourPaywallMode.values) {
          expect(
            modeStage(paywallMode: m, isPremium: true),
            OnboardingStage.app,
            reason: 'mode=$m',
          );
        }
      });

      test('paywallCleared short-circuits to app regardless of mode', () {
        for (final m in PostTourPaywallMode.values) {
          expect(
            modeStage(paywallMode: m, paywallCleared: true),
            OnboardingStage.app,
            reason: 'mode=$m',
          );
        }
      });

      test('mode off bypasses the whole gate → app', () {
        expect(
          modeStage(paywallMode: PostTourPaywallMode.off),
          OnboardingStage.app,
        );
      });

      test('mode soft, not cleared → softPaywall', () {
        expect(
          modeStage(paywallMode: PostTourPaywallMode.soft),
          OnboardingStage.softPaywall,
        );
      });

      test('mode hard, not cleared → hardPaywall', () {
        expect(
          modeStage(paywallMode: PostTourPaywallMode.hard),
          OnboardingStage.hardPaywall,
        );
      });

      // -------------------------------------------------------------------
      // G5 — routing-matrix-WITH-TRIAL. The reverse-trial window manifests in
      // routing ONLY as `isPremium` (PurchaseService.isPremium() OR's the trial
      // window in). resolveOnboardingStage has no trial concept of its own —
      // these pin that an ACTIVE trial (isPremium:true) clears the soft gate to
      // `app`, while an EXPIRED trial (isPremium:false) falls to `softPaywall`.
      // -------------------------------------------------------------------
      group('G5 reverse-trial manifests as isPremium', () {
        test('ACTIVE trial (isPremium:true), soft mode → app '
            '(no wall while the trial window is live)', () {
          expect(
            modeStage(
              paywallMode: PostTourPaywallMode.soft,
              isPremium: true,
              paywallCleared: false,
            ),
            OnboardingStage.app,
          );
        });

        test('EXPIRED trial (isPremium:false), soft mode, uncleared '
            '→ softPaywall (the dismissible reverse-trial-expiry gate)', () {
          expect(
            modeStage(
              paywallMode: PostTourPaywallMode.soft,
              isPremium: false,
              paywallCleared: false,
            ),
            OnboardingStage.softPaywall,
          );
        });

        test('ACTIVE trial clears the HARD gate too → app', () {
          expect(
            modeStage(paywallMode: PostTourPaywallMode.hard, isPremium: true),
            OnboardingStage.app,
          );
        });
      });
    });

    // ---------------------------------------------------------------------
    // Legacy fallback: when NO `paywallMode` is supplied the function derives
    // the gate branch from `hardPaywallFlowEnabled` (preserves today's
    // behaviour for the live binary).
    // ---------------------------------------------------------------------
    group('legacy bool fallback (no mode supplied)', () {
      test('hardPaywallFlowEnabled true, uncleared → hardPaywall', () {
        expect(
          stage(hardPaywallFlowEnabled: true),
          OnboardingStage.hardPaywall,
        );
      });

      test('hardPaywallFlowEnabled false, uncleared → app', () {
        expect(stage(hardPaywallFlowEnabled: false), OnboardingStage.app);
      });
    });
  });
}
